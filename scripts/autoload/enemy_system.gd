extends Node
## EnemySystem - Generates scaled enemies from archetype definitions
##
## Loads enemy archetypes and encounter templates from JSON, then generates
## enemy dictionaries scaled to party power. Enemies use the same stat system
## as player characters (attributes, derived stats, skills, spells).
##
## Usage:
##   var enemies = EnemySystem.generate_encounter("demon_patrol", "cold_hell")
##   # Returns Array[Dictionary] ready for CombatUnit.init_as_enemy()

# Loaded data from JSON
var archetypes: Dictionary = {}   # archetype_id -> archetype definition
var encounters: Dictionary = {}   # encounter_id -> encounter template
var name_parts: Dictionary = {}   # prefixes, roots, suffixes for procedural naming

## Encounter budget tables: realm bases, rank multipliers, rarity bands, reward
## fraction. An encounter's party XP is realm_median * difficulty * band, where
## difficulty is the ladder step the event, mob or encounter asked for.
var budgets: Dictionary = {}

## Party composition templates: member counts and relative XP shares.
var party_archetypes: Dictionary = {}

# Spell database reference (loaded from spells.json)
var all_spells: Dictionary = {}

# Skill-to-school mapping for finding castable spells
# Maps skill names to the school tag used in spells.json (Capitalized)
const SKILL_TO_SCHOOL: Dictionary = {
	"fire_magic": "Fire",
	"water_magic": "Water",
	"earth_magic": "Earth",
	"air_magic": "Air",
	"space_magic": "Space",
	"sorcery": "Sorcery",
	"enchantment": "Enchantment",
	"summoning": "Summoning",
	"white_magic": "White",
	"black_magic": "Black"
}

# Armor category -> [slot, base_type] pairs to generate.
# "none" intentionally absent — no entry means no armor items.
const ARMOR_LOADOUTS: Dictionary = {
	"light":  [["chest", "armor"], ["head", "hat"],    ["feet", "boots"]],
	"medium": [["chest", "armor"], ["head", "helmet"], ["legs", "pants"],   ["feet", "boots"]],
	"heavy":  [["chest", "armor"], ["head", "helmet"], ["legs", "greaves"], ["feet", "boots"], ["hand_l", "gauntlets"]]
}


## Band names weakest-first, for gating templates by encounter rarity.
const BAND_ORDER: Array[String] = ["common", "uncommon", "rare"]


func _load_party_composition() -> void:
	var path := "res://resources/data/enemies/party_composition.json"
	if not FileAccess.file_exists(path):
		push_error("EnemySystem: party_composition.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("EnemySystem: party_composition.json parse error - " + json.get_error_message())
		return
	f.close()
	for key in json.get_data().get("party_archetypes", {}):
		if key.begins_with("_"):
			continue
		party_archetypes[key] = json.get_data()["party_archetypes"][key]


## Templates available at this band. A gated template is removed from the pool
## entirely and the remaining weights renormalise, rather than being rerolled.
func _eligible_party_archetypes(band: String) -> Array[String]:
	var band_rank: int = BAND_ORDER.find(band)
	var out: Array[String] = []
	for key in party_archetypes:
		var min_band: String = party_archetypes[key].get("min_band", "common")
		if BAND_ORDER.find(min_band) <= band_rank:
			out.append(key)
	out.sort()
	return out


## Choose a party template and expand it into one entry per member.
## Returns [{"share": int, "is_hero": bool}, ...]
func roll_party_composition(band: String) -> Array[Dictionary]:
	var eligible: Array[String] = _eligible_party_archetypes(band)
	if eligible.is_empty():
		return [{"share": 1, "is_hero": true}]

	var total: int = 0
	for key in eligible:
		total += int(party_archetypes[key].get("weight", 0))

	var chosen: String = eligible[0]
	if total > 0:
		var roll: int = randi() % total
		var cumulative: int = 0
		for key in eligible:
			cumulative += int(party_archetypes[key].get("weight", 0))
			if roll < cumulative:
				chosen = key
				break

	var template: Dictionary = party_archetypes[chosen]
	var members: Array[Dictionary] = []
	# `slots` here is the party's share structure — a hero slot worth three
	# shares in front of four mook slots worth one. It was called `tiers`, which
	# had nothing to do with the archetype tier and made both harder to read.
	for slot in template.get("slots", template.get("tiers", [])):
		var span: Array = slot.get("count", [1, 1])
		var lo: int = int(span[0])
		var hi: int = int(span[1]) if span.size() > 1 else lo
		var n: int = lo + (randi() % maxi(1, hi - lo + 1))
		for i in range(n):
			members.append({"share": int(slot.get("share", 1)), "is_hero": false,
				"disposition": String(template.get("disposition", "hostile"))})

	if members.is_empty():
		members.append({"share": 1, "is_hero": true})

	_mark_heroes(members, template)
	return members


## A member is a hero when its template says all members are, when it is the
## sole member, or when it strictly out-shares every other member. Rule three
## alone would give a rival_party no heroes at all, since its members are equal.
func _mark_heroes(members: Array[Dictionary], template: Dictionary) -> void:
	if template.get("all_heroes", false):
		for m in members:
			m["is_hero"] = true
		return
	if members.size() == 1:
		members[0]["is_hero"] = true
		return

	var top: int = 0
	for m in members:
		top = maxi(top, int(m["share"]))
	var at_top: int = 0
	for m in members:
		if int(m["share"]) == top:
			at_top += 1
	if at_top == 1:
		for m in members:
			if int(m["share"]) == top:
				m["is_hero"] = true


func _load_budgets() -> void:
	var path := "res://resources/data/enemies/encounter_budgets.json"
	if not FileAccess.file_exists(path):
		push_error("EnemySystem: encounter_budgets.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("EnemySystem: encounter_budgets.json parse error - " + json.get_error_message())
		return
	f.close()
	budgets = json.get_data()


## How much of a budget is spent outside the archetype's plan.
##
## Zero below the threshold — a small enemy is a specialist — then rising with
## the budget to a cap, so the bigger an enemy is the rounder it becomes.
func breadth_for_budget(budget: int) -> float:
	var cfg: Dictionary = budgets.get("breadth", {})
	var threshold: float = float(cfg.get("xp_threshold", 300))
	var scale: float = float(cfg.get("scale", 10000))
	var cap: float = float(cfg.get("max_fraction", 0.35))
	if budget <= threshold or scale <= 0.0:
		return 0.0
	return clampf((float(budget) - threshold) / scale, 0.0, cap)


## Non-combat skill -> the tool that supports it. A character better at one of
## these than at any weapon carries the tool in the weapon hand instead, the way
## a ritual focus is carried: weak in a fight, strong at what it is for.
const SKILL_TO_TOOL: Dictionary = {
	"medicine": "medicine_bag",
	"performance": "lute",
	"thievery": "thieving_tools",
	"alchemy": "alchemists_kit",
	"trade": "merchants_scales",
	"smithing": "smiths_hammer",
	"logistics": "quartermasters_ledger",
	"leadership": "war_standard",
}

## Tool tiers, cheapest first: prefix and the kit value each needs.
const TOOL_TIERS: Array = [
	{"prefix": "plain", "cost": 35},
	{"prefix": "fine", "cost": 120},
	{"prefix": "masterwork", "cost": 340},
	{"prefix": "storied", "cost": 850},
	{"prefix": "legendary", "cost": 2000},
]

## Skill -> consumables that skill's owner would plausibly be carrying, for
## their own use in a fight and as loot afterwards.
const SKILL_TO_CONSUMABLES: Dictionary = {
	"medicine": ["healing_herb", "health_potion"],
	"alchemy": ["raw_reagents", "health_potion"],
	"white_magic": ["mana_potion"],
	"black_magic": ["mana_potion"],
	"fire_magic": ["mana_potion"],
	"water_magic": ["mana_potion"],
	"earth_magic": ["mana_potion"],
	"air_magic": ["mana_potion"],
	"space_magic": ["mana_potion"],
	"sorcery": ["mana_potion"],
	"trade": ["rations"],
	"logistics": ["rations"],
}


## Gold-equivalent value of the kit a character of this XP should be carrying.
## Gear is not paid for out of the XP budget, but it scales with it.
func equipment_budget_for_xp(xp_budget: int) -> int:
	var cfg: Dictionary = budgets.get("equipment", {})
	return maxi(0, int(round(float(xp_budget) * float(cfg.get("value_per_xp", 0.45)))))


## The best tool skill and its level, when the character is more a practitioner
## than a fighter. Returns {} when a weapon suits them better.
func _tool_for_character(skills: Dictionary) -> Dictionary:
	var best_tool_skill := ""
	var best_tool_level: int = 0
	for skill in SKILL_TO_TOOL:
		var level: int = int(skills.get(skill, 0))
		if level > best_tool_level:
			best_tool_level = level
			best_tool_skill = String(skill)

	var best_weapon_level: int = 0
	for skill in SKILL_TO_WEAPON:
		best_weapon_level = maxi(best_weapon_level, int(skills.get(skill, 0)))

	# Only when the trade genuinely outweighs the weapon. A tie goes to the
	# weapon: this is still a fight, and they know it.
	if best_tool_skill == "" or best_tool_level <= best_weapon_level:
		return {}
	return {"skill": best_tool_skill, "level": best_tool_level}


## The best tool tier this kit budget can afford.
func _affordable_tool_id(tool_base: String, kit_budget: int) -> String:
	var chosen := ""
	for tier in TOOL_TIERS:
		if kit_budget >= int(tier["cost"]):
			chosen = "%s_%s" % [String(tier["prefix"]), tool_base]
	return chosen


## Weapon skill -> the weapon_bases type that skill actually wields.
## Mirrors CombatUnit._get_weapon_skill_name, read the other way round.
const SKILL_TO_WEAPON: Dictionary = {
	"swords": ["sword"],
	"daggers": ["dagger"],
	"axes": ["axe"],
	"maces": ["mace", "club"],
	"spears": ["spear", "javelin"],
	"ranged": ["bow", "crossbow"],
	"martial_arts": ["staff"],
}

## Skills that imply carrying a tool of the trade rather than a weapon.
const SKILL_TO_KIT: Dictionary = {
	"medicine": ["healing_herb", "herb_bundle"],
	"alchemy": ["raw_reagents"],
	"trade": ["rations"],
	"logistics": ["rations"],
}


## The weapon types this character has actually trained for, best skill first.
## An archetype's template is the fallback, not the authority: a build that came
## out with ranged 8 should be holding a bow whatever its template says.
## Returns [{"type": String, "skill": String, "level": int}, ...], best first.
## Empty when the character has trained no weapon skill at all — a caster, say,
## who should keep whatever its archetype hands it.
func _weapon_types_for_skills(skills: Dictionary) -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	for skill in SKILL_TO_WEAPON:
		var level: int = int(skills.get(skill, 0))
		if level > 0:
			var options: Array = SKILL_TO_WEAPON[skill]
			ranked.append({
				"type": String(options[randi() % options.size()]),
				"skill": String(skill),
				"level": level})
	ranked.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]))
	return ranked


## Consumables the character's own skills imply — a medic's herbs, a caster's
## mana. Theirs to use in the fight, and the player's afterwards. Spends up to
## the consumable share of the kit budget.
func _generate_skill_consumables(skills: Dictionary, kit_budget: int) -> Array:
	var cfg: Dictionary = budgets.get("equipment", {})
	var spend: int = int(round(float(kit_budget) * float(cfg.get("consumable_share", 0.25))))
	var out: Array = []
	if spend <= 0:
		return out

	# Rank the skills that imply a consumable, best first.
	var ranked: Array[Dictionary] = []
	for skill in SKILL_TO_CONSUMABLES:
		var level: int = int(skills.get(skill, 0))
		if level > 0:
			ranked.append({"skill": String(skill), "level": level})
	if ranked.is_empty():
		return out
	ranked.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]))

	for entry in ranked:
		var options: Array = SKILL_TO_CONSUMABLES[entry["skill"]]
		var pick: String = String(options[randi() % options.size()])
		var item: Dictionary = ItemSystem.get_item(pick)
		var cost: int = maxi(1, int(item.get("value", 10)))
		# More of it the better they are at the thing, budget permitting.
		var want: int = clampi(int(entry["level"]) / 3, 1, 3)
		var afford: int = mini(want, int(float(spend) / float(cost)))
		if afford > 0:
			out.append({"item_id": pick, "quantity": afford})
			spend -= afford * cost
		if spend <= 0:
			break
	return out


## Everyday things a character of this budget would be carrying: food, and a
## tool for whatever non-combat skill they are best at. Cheap, mostly
## inconsequential, and the reason a corpse reads as someone who lived somewhere.
func _generate_everyday_items(skills: Dictionary, xp_budget: int) -> Array:
	var out: Array = []

	# Food, in rough proportion to how established the character is.
	var rations: int = clampi(int(round(float(xp_budget) / 600.0)), 0, 4)
	if rations > 0:
		out.append({"item_id": "rations", "quantity": rations})

	# The best non-combat skill puts a tool of its trade in their pack.
	var best_skill := ""
	var best_level: int = 0
	for skill in SKILL_TO_KIT:
		var level: int = int(skills.get(skill, 0))
		if level > best_level:
			best_level = level
			best_skill = skill
	if best_skill != "" and best_level >= 2:
		var options: Array = SKILL_TO_KIT[best_skill]
		out.append({"item_id": String(options[randi() % options.size()]), "quantity": 1})

	return out


## Roll a rarity band, returning its id ("common", "uncommon", "rare").
func roll_band() -> String:
	var bands: Array = budgets.get("bands", [])
	if bands.is_empty():
		return "common"
	var total: int = 0
	for band in bands:
		total += int(band.get("weight", 0))
	if total <= 0:
		return "common"
	var roll: int = randi() % total
	var cumulative: int = 0
	for band in bands:
		cumulative += int(band.get("weight", 0))
		if roll < cumulative:
			return String(band.get("id", "common"))
	return String(bands[0].get("id", "common"))


func _band_multiplier(band_id: String) -> float:
	for band in budgets.get("bands", []):
		if String(band.get("id", "")) == band_id:
			return float(band.get("multiplier", 1.0))
	return 1.0


## Archetype rank: what a creature intrinsically is, 1 (vermin) to 4 (lord).
##
## It replaced `tier`, which did three unrelated jobs at once — it set the
## encounter's XP, it decided which archetypes the encounter could draw from,
## and it was each member's share of the party budget. Welding those together
## meant an encounter pinned to one tier could not use its own family's other
## members: animal_mriga_herd asked for shade and the mriga stag is rank 3, so a
## mriga herd was filled with boars and wolves. Rank is now only "what this
## creature is"; the draw pool is the encounter's `rank_range`, and its strength
## is the top of that range or an explicit `strength` override.
##
## Boss is not a rank. It is a role, and _pick_archetype_for_role already keeps
## bosses out of ordinary slots.
const RANK_MIN: int = 1
const RANK_MAX: int = 4

## Legacy `tier` strings, for any archetype or encounter not yet carrying a rank.
const RANK_FROM_TIER: Dictionary = {
	"imp": 1, "beast": 2, "shade": 2, "devil": 3, "boss": 4,
}

## The ladder step an encounter falls back to when nothing authored one, read
## off what it actually contains. Chosen to land within rounding of the
## multipliers rank used to carry (0.5 / 0.8 / 1.0 / 2.0) so that migrating to
## the ladder did not silently retune 41 encounters, eleven of them bosses.
const RANK_DEFAULT_DIFFICULTY: Dictionary = {
	1: "very_easy", 2: "easy", 3: "medium", 4: "dangerous",
}


## An archetype's rank, falling back to its legacy tier and then to 3.
func archetype_rank(arch: Dictionary) -> int:
	if arch.has("rank"):
		return clampi(int(arch["rank"]), RANK_MIN, RANK_MAX)
	return int(RANK_FROM_TIER.get(String(arch.get("tier", "devil")), 3))


## The rank range an encounter draws from, as [min, max].
##
## Only the plain role encounters carry a `rank_range`; every `fixed` and
## `groups` one has none. Defaulting those to rank 3 would silently flatten every
## boss fight to ordinary difficulty, so the range is derived from the content
## instead — the span of the archetypes or groups actually in it.
func resolve_encounter_rank_range(template: Dictionary) -> Array:
	if template.has("rank_range"):
		var rr: Array = template["rank_range"]
		if rr.size() >= 2:
			return [int(rr[0]), int(rr[1])]
	if template.has("tier"):
		var r: int = int(RANK_FROM_TIER.get(String(template["tier"]), 3))
		return [r, r]

	var lo: int = RANK_MAX + 1
	var hi: int = 0
	if template.get("fixed", false):
		for entry in template.get("enemies", []):
			var r2: int = archetype_rank(archetypes.get(String(entry.get("archetype", "")), {}))
			lo = mini(lo, r2)
			hi = maxi(hi, r2)
	for group in template.get("groups", []):
		var grr: Array = resolve_encounter_rank_range(group)
		lo = mini(lo, int(grr[0]))
		hi = maxi(hi, int(grr[1]))

	if hi == 0:
		push_warning("EnemySystem: cannot derive a rank range for an encounter, using 3")
		return [3, 3]
	return [lo, hi]


## The ladder step an encounter sits on, as a canonical word.
##
## Content was already written in nine synonyms across 363 event and map entries
## — normal, moderate, hard, difficult, very_hard, very_difficult, boss — so they
## are aliased onto the seven steps rather than rewritten.
func canonical_difficulty(word: String) -> String:
	if word == "":
		return ""
	var w: String = word.to_lower()
	var aliases: Dictionary = budgets.get("difficulty_aliases", {})
	if aliases.has(w):
		w = String(aliases[w])
	if budgets.get("difficulty_multipliers", {}).has(w):
		return w
	return ""


## Total XP the enemy party is built from: realm_median * difficulty * band.
##
## The realm's median is a hard anchor, not a reading of the player. Enemies are
## never scaled to the party, so a party outgrows a realm's ordinary encounters
## across a run and still walks into a wall at the next realm — or at anything
## authored above its weight. A hell character in the animal realm is severely
## outmatched, and that is the point.
##
## Difficulty comes from the event or mob that started the fight, else the
## encounter's own `difficulty`, else `medium`. An encounter may instead carry a
## raw numeric `strength`, which bypasses the ladder.
func resolve_party_budget(encounter_id: String, realm: String,
		difficulty: String = "") -> Dictionary:
	var template: Dictionary = encounters.get(encounter_id, {})
	var rank_range: Array = resolve_encounter_rank_range(template)
	var band: String = roll_band()

	var step: String = canonical_difficulty(difficulty)
	if step == "":
		step = canonical_difficulty(String(template.get("difficulty", "")))
	if step == "":
		# Nothing authored a difficulty, so fall back to what the encounter's own
		# content implies. Without this the eleven boss fights — both Kings, Yama's
		# Lieutenant, the Smoking Mirror — would each drop to medium, because rank
		# no longer feeds the budget and only four events name a boss difficulty.
		# A bridge, not the destination: encounters want authored difficulties.
		step = RANK_DEFAULT_DIFFICULTY.get(int(rank_range[1]), "medium")

	var strength: float = float(
		budgets.get("difficulty_multipliers", {}).get(step, 1.0))
	if template.has("strength"):
		strength = float(template["strength"])

	var median: float = float(budgets.get("realm_median",
		budgets.get("realm_base", {})).get(realm, 200))
	var xp: int = maxi(1, int(round(median * strength * _band_multiplier(band))))

	return {"xp": xp, "band": band, "rank_range": rank_range,
		"strength": strength, "difficulty": step}


func _ready() -> void:
	_load_budgets()
	_load_party_composition()
	# Scan the enemies directory so every realm's data loads automatically
	# (hell, hungry_ghost, animal, domain, and any future realm files).
	var enemies_dir = "res://resources/data/enemies/"
	var dir = DirAccess.open(enemies_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("_archetypes.json"):
				_load_archetypes(enemies_dir + file_name)
			elif file_name.ends_with("_encounters.json"):
				_load_encounters(enemies_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("EnemySystem: Could not open " + enemies_dir)
	_load_spells()
	_load_name_parts()
	print("EnemySystem initialized: %d archetypes, %d encounters" % [archetypes.size(), encounters.size()])


# ============================================
# DATA LOADING
# ============================================

func _load_archetypes(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("EnemySystem: Could not load " + path)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("EnemySystem: Failed to parse " + path + ": " + json.get_error_message())
		return

	var data = json.get_data()
	if data.has("archetypes"):
		for key in data.archetypes:
			# Skip comment entries
			if key.begins_with("_"):
				continue
			archetypes[key] = data.archetypes[key]


func _load_encounters(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		# Encounters file may not exist yet for a new realm — warn but don't error
		push_warning("EnemySystem: Could not load " + path)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("EnemySystem: Failed to parse " + path + ": " + json.get_error_message())
		return

	var data = json.get_data()
	if data.has("encounters"):
		# The file an encounter came from is the only record of its realm —
		# nothing in the encounter data itself says which world it belongs to.
		var realm_name: String = path.get_file().replace("_encounters.json", "")
		for key in data.encounters:
			if key.begins_with("_"):
				continue
			encounters[key] = data.encounters[key]
			encounters[key]["realm"] = realm_name


func _load_spells() -> void:
	var file = FileAccess.open("res://resources/data/spells.json", FileAccess.READ)
	if not file:
		push_warning("EnemySystem: Could not load spells.json — enemies won't get spells")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("EnemySystem: Failed to parse spells.json: " + json.get_error_message())
		return

	var data = json.get_data()
	if data.has("spells"):
		all_spells = data.spells


func _load_name_parts() -> void:
	var file = FileAccess.open("res://resources/data/enemies/name_parts.json", FileAccess.READ)
	if not file:
		push_warning("EnemySystem: Could not load name_parts.json — enemies will use archetype names")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("EnemySystem: Failed to parse name_parts.json: " + json.get_error_message())
		return

	name_parts = json.get_data()


# ============================================
# MAIN API
# ============================================

## Generate an encounter: returns Array of enemy dicts ready for CombatUnit.init_as_enemy()
## encounter_id: matches enemy_group from events/mobs JSON
## region: "cold_hell", "fire_hell", or "" for any
## realm: which of the six worlds this encounter is in — used for name generation
## difficulty: ladder step from the event or mob ("trivial".."lethal", plus the
##   nine legacy synonyms). Empty falls through to the encounter's own, then medium.
func generate_encounter(encounter_id: String, region: String = "", realm: String = "hell", difficulty: String = "") -> Array[Dictionary]:
	var template = encounters.get(encounter_id, {})
	if template.is_empty():
		push_warning("EnemySystem: Unknown encounter '%s', generating fallback" % encounter_id)
		return _generate_fallback_encounter(realm)

	var budget: Dictionary = resolve_party_budget(encounter_id, realm, difficulty)
	var party_xp: int = int(budget["xp"])

	# Whether meeting this party opens a fight or a conversation. The encounter
	# has the final word; otherwise the party archetype decides.
	var party_disposition: String = String(template.get("disposition", "hostile"))
	var enc_region: String = template.get("region", "any")
	var effective_region: String = region if region != "" else enc_region

	# Slots: {archetype | role, share}. Fixed and grouped encounters keep the
	# composition they were authored with; only plain role encounters roll one.
	var slots: Array[Dictionary] = []

	if template.get("fixed", false):
		# Authored exactly: the archetype list is the composition. Shares come
		# from each archetype's own rank, so a boss is worth more than the
		# honour guard standing beside it rather than an equal quarter.
		for entry in template.get("enemies", []):
			var aid: String = String(entry.get("archetype", ""))
			var a_share: int = archetype_rank(archetypes.get(aid, {}))
			for i in range(int(entry.get("count", 1))):
				slots.append({"archetype": aid, "share": a_share})

	elif template.has("groups"):
		# Authored shape: each group is a share band, so a screen of chaff in
		# front of heavies stays a screen of chaff in front of heavies. The top
		# of the group's rank range is its share, which is what made them heavy.
		for group in template.get("groups", []):
			var g_range: Array = resolve_encounter_rank_range(group)
			var share: int = maxi(1, int(g_range[1]))
			var group_region: String = String(group.get("region", effective_region))
			for role in group.get("roles", {}):
				for i in range(int(group["roles"][role])):
					slots.append({"role": String(role), "share": share,
						"rank_range": g_range, "region": group_region})

	else:
		# Plain role encounter: the party archetype decides size and shares.
		var members: Array[Dictionary] = roll_party_composition(String(budget["band"]))
		if not members.is_empty():
			party_disposition = String(members[0].get("disposition", party_disposition))
		var role_pool: Array[String] = []
		for role in template.get("roles", {}):
			for i in range(int(template["roles"][role])):
				role_pool.append(String(role))
		if role_pool.is_empty():
			role_pool.append("frontline")
		for i in range(members.size()):
			slots.append({"role": role_pool[i % role_pool.size()],
				"share": int(members[i]["share"]),
				"is_hero": bool(members[i].get("is_hero", false))})

	if slots.is_empty():
		return _generate_fallback_encounter(realm)

	# Resolve each slot to an archetype before splitting the budget, so the
	# hero can be chosen by threat where the composition was authored.
	if template.has("disposition"):
		party_disposition = String(template["disposition"])

	var family: Array[String] = _encounter_family_tokens(encounter_id)
	for slot in slots:
		if not slot.has("archetype"):
			var slot_range: Array = slot.get("rank_range", budget["rank_range"])
			slot["archetype"] = _pick_archetype_for_role(
				String(slot["role"]), String(slot.get("region", effective_region)),
				slot_range, realm, family)

	_mark_authored_hero(slots, template)

	var total_shares: int = 0
	for slot in slots:
		total_shares += int(slot["share"])

	var enemies: Array[Dictionary] = []
	for slot in slots:
		if String(slot["archetype"]) == "":
			continue
		var member_xp: int = maxi(1, int(round(
			float(party_xp) * float(slot["share"]) / float(maxi(total_shares, 1)))))
		var enemy = _build_enemy(String(slot["archetype"]), member_xp, realm,
			String(slot.get("region", effective_region)), bool(slot.get("is_hero", false)))
		if not enemy.is_empty():
			enemy["disposition"] = party_disposition
			enemies.append(enemy)

	if enemies.is_empty():
		return _generate_fallback_encounter(realm)
	return enemies


## For authored compositions, the hero is the slot with the highest share, ties
## broken by the archetype's threat_multiplier. Rolled compositions already
## carry their own is_hero from the party template.
func _mark_authored_hero(slots: Array[Dictionary], template: Dictionary) -> void:
	for slot in slots:
		if slot.has("is_hero"):
			return  # rolled composition: already decided
	if slots.size() == 1:
		slots[0]["is_hero"] = true
		return

	var top_share: int = 0
	for slot in slots:
		top_share = maxi(top_share, int(slot["share"]))

	var top_index: int = -1
	var contenders: int = 0
	for i in range(slots.size()):
		if int(slots[i]["share"]) == top_share:
			contenders += 1
			top_index = i

	for slot in slots:
		slot["is_hero"] = false
	# Only one member can be the hero, and only by strictly out-sharing every
	# other. Two equal heavies are two heavies, not a hero and a subordinate —
	# they would be indistinguishable in play, and their XP differs only by the
	# rounding of what each happened to spend.
	if contenders == 1 and top_index >= 0:
		slots[top_index]["is_hero"] = true


## Build one enemy as a character: roll a birth and a background, apply their
## modifiers, then spend the XP budget the way the archetype directs.
## realm and region are passed through for procedural name generation.
func _build_enemy(archetype_id: String, xp_budget: int, realm: String = "hell",
		region: String = "", is_hero: bool = false) -> Dictionary:
	var archetype = archetypes.get(archetype_id, {})
	if archetype.is_empty():
		push_warning("EnemySystem: Unknown archetype '%s'" % archetype_id)
		return {}

	var effective_budget: float = float(xp_budget)

	# Birth and background first — the same two steps a player character takes.
	var birth: String = CharacterSystem.roll_birth_for_realm(realm)
	var background: String = KarmaSystem.select_random_background(birth)

	var built: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.apply_birth_modifiers(built, birth)
	if background != "":
		CharacterSystem.apply_background_skills(built, background)

	# Then the archetype, as a spending plan for the budget.
	var spent: int = CharacterSystem.spend_xp_budget(
		built, xp_budget,
		archetype.get("attribute_weights", {}),
		archetype.get("skill_priorities", []),
		0.6, breadth_for_budget(xp_budget))

	var attributes = built["attributes"]
	var skills = built["skills"]
	var derived = _calculate_derived_stats(attributes, skills)
	var equipment = _generate_equipment(archetype.get("equipment_template", {}), effective_budget)
	var spells = _pick_spells(skills, archetype.get("guaranteed_spells", []))
	var perks = _build_perks(archetype.get("guaranteed_perks", []), skills)

	# Some enemy types (imps) have a chance to be bare-handed — no equipment at all
	var no_equip_chance = archetype.get("no_equipment_chance", 0.0)
	var bare_handed = randf() < no_equip_chance

	# Build resistances dict (start with defaults, apply archetype overrides).
	# Includes "black" as a damage type used by Black magic spells.
	var resistances = {
		"physical": 0, "space": 0, "air": 0,
		"fire": 0, "water": 0, "earth": 0, "black": 0
	}
	var arch_resists = archetype.get("resistances", {})
	for key in arch_resists:
		resistances[key] = arch_resists[key]

	# Generate consumable inventory, then merge any archetype-guaranteed items
	var inventory = _generate_enemy_inventory(archetype, effective_budget)
	for everyday in _generate_everyday_items(skills, xp_budget):
		inventory.append(everyday)
	for item in archetype.get("starting_inventory", []):
		inventory.append(item)

	# Map power budget to item rarity — shared by weapon and armor generation.
	# Realm drives the material tier (e.g. hell → bone/obsidian/bronze); rarity drives quality.
	# Rarity derives from the kit budget, which is itself a function of XP.
	var kit_budget: int = equipment_budget_for_xp(xp_budget)
	var power_scale = float(kit_budget) / 180.0
	var item_rarity: String
	if power_scale < 0.5:
		item_rarity = "common"
	elif power_scale < 1.0:
		item_rarity = "uncommon"
	elif power_scale < 1.5:
		item_rarity = "rare"
	elif power_scale < 2.0:
		item_rarity = "epic"
	else:
		item_rarity = "legendary"

	# Build the weapon for CombatUnit — generated items carry real material tiers,
	# traits, and durability; added to inventory so they drop on death.
	var equipped_weapon: Dictionary
	if bare_handed:
		equipped_weapon = {
			"name": "Natural Claws",
			"type": "unarmed",
			"damage_type": "crushing",
			"stats": {"damage": 2, "accuracy": 4, "range": 1}
		}
	else:
		# A character better at a trade than at any weapon carries its tool
		# instead — a doctor with a bag, not a doctor with a borrowed spear.
		var tool: Dictionary = _tool_for_character(skills)
		var tool_id: String = ""
		if not tool.is_empty():
			tool_id = _affordable_tool_id(
				String(SKILL_TO_TOOL[tool["skill"]]), kit_budget)

		# What the character trained for wins over what the archetype template
		# says. A build that came out with ranged 8 carries a bow.
		var trained: Array[Dictionary] = _weapon_types_for_skills(skills)
		var weapon_type: String = String(trained[0]["type"]) if not trained.is_empty() \
			else String(equipment.get("weapon_type", "sword"))

		var gen_id: String = ""
		var carrying_tool := false
		if tool_id != "" and ItemSystem.get_item(tool_id).size() > 0:
			equipped_weapon = ItemSystem.get_item(tool_id)
			inventory.append({"item_id": tool_id, "quantity": 1})
			kit_budget -= int(equipped_weapon.get("value", 0))
			carrying_tool = true
		else:
			gen_id = ItemSystem.generate_weapon(weapon_type, item_rarity, "", "", realm)

		if carrying_tool:
			pass  # already equipped; the branches below must not overwrite it
		elif gen_id != "":
			equipped_weapon = ItemSystem.get_item(gen_id)
			inventory.append({"item_id": gen_id, "quantity": 1})
			kit_budget -= int(equipped_weapon.get("value", 0))

			# A second set, when a second weapon skill is genuinely trained and
			# the character is worth enough to have afforded it. Carried rather
			# than wielded — it is a spare, and it drops.
			if trained.size() > 1 and xp_budget >= 600 and int(trained[1]["level"]) >= 3:
				var spare_id = ItemSystem.generate_weapon(
					String(trained[1]["type"]), item_rarity, "", "", realm)
				if spare_id != "":
					inventory.append({"item_id": spare_id, "quantity": 1})
		else:
			# Fallback if ItemSystem unavailable
			equipped_weapon = {
				"name": "Crude " + weapon_type.capitalize(),
				"type": weapon_type,
				"damage_type": _get_weapon_damage_type(weapon_type),
				"stats": {
					"damage": equipment.get("weapon_damage", 5),
					"accuracy": equipment.get("weapon_accuracy", 3),
					"range": equipment.get("weapon_range", 1)
				}
			}

	# Generate armor items — same material-tiered system as the player.
	# Each piece's stats contribute to derived (armor, dodge, hp, etc.) and the
	# item goes into inventory so it can be looted on death.
	# Armour spends what the weapon left. A character whose budget ran out on a
	# good blade goes into the fight in fewer pieces, which is how kit works.
	var armor_category: String = equipment.get("armor_type", "none")
	for slot_entry in ARMOR_LOADOUTS.get(armor_category, []):
		if kit_budget <= 0:
			break
		var armor_gen_id = ItemSystem.generate_armor(slot_entry[1], item_rarity, "", "", realm)
		if armor_gen_id == "":
			continue
		var armor_item = ItemSystem.get_item(armor_gen_id)
		var piece_value: int = int(armor_item.get("value", 0))
		if piece_value > kit_budget:
			continue  # cannot afford this piece; try the next, cheaper slot
		kit_budget -= piece_value
		var piece_stats = armor_item.get("stats", {})
		derived["armor"]       += piece_stats.get("armor", 0)
		derived["dodge"]       += piece_stats.get("dodge", 0)
		derived["max_hp"]      += piece_stats.get("max_hp", 0)
		derived["current_hp"]  += piece_stats.get("max_hp", 0)
		derived["max_stamina"] += piece_stats.get("max_stamina", 0)
		derived["current_stamina"] += piece_stats.get("max_stamina", 0)
		inventory.append({"item_id": armor_gen_id, "quantity": 1})

	# Anything left buys an accessory. Enemies never carried one before, so a
	# well-funded enemy had nowhere for its surplus to go.
	# 30 is the cheapest talisman in the game; anything above that is worth trying.
	if kit_budget >= 30:
		var tali_id = ItemSystem.generate_talisman(item_rarity)
		if tali_id != "":
			var tali = ItemSystem.get_item(tali_id)
			if int(tali.get("value", 0)) <= kit_budget:
				kit_budget -= int(tali.get("value", 0))
				inventory.append({"item_id": tali_id, "quantity": 1})

	# Consumables come last, out of whatever the kit did not spend on gear.
	for consumable in _generate_skill_consumables(skills, kit_budget):
		inventory.append(consumable)

	# Generate a procedural name from realm/region/tags, unless this is a named boss.
	# Race is inferred from archetype tags: imps first, then shades (undead+incorporeal),
	# then biological devils, then elementals (no biology).
	var tags = archetype.get("tags", [])
	var is_boss = "boss" in archetype.get("roles", [])
	var enemy_type: String
	if "imp" in tags:
		enemy_type = "imp"
	elif "undead" in tags and "incorporeal" in tags:
		enemy_type = "shade"
	elif "biological" in tags or "devil" in tags:
		enemy_type = "devil"
	else:
		enemy_type = "elemental"

	var enemy_name: String
	if is_boss or name_parts.is_empty():
		enemy_name = archetype.get("name", "Enemy")
	else:
		enemy_name = generate_enemy_name(realm, tags, region, enemy_type)

	# For bare-handed enemies, name the claws after the enemy.
	# Generated weapons already have proper names (e.g. "Fine Obsidian Sword") — keep them.
	if bare_handed:
		equipped_weapon["name"] = enemy_name + "'s Claws"

	# Assemble final enemy dict matching CombatUnit.init_as_enemy() expectations
	var enemy: Dictionary = {
		"name": enemy_name,
		"archetype_name": archetype.get("name", ""),  # Human-readable archetype, shown as subtitle in combat
		"archetype_id": archetype_id,
		"tags": archetype.get("tags", []),
		"max_hp": derived.max_hp,
		"max_mana": derived.max_mana,
		"actions": 2,
		"attributes": attributes,
		"derived": derived,
		"skills": skills,
		"resistances": resistances,
		"equipped_weapon": equipped_weapon,
		"known_spells": spells,
		"perks": perks,
		"inventory": inventory,
		"body_plan": {
			"species": archetype.get("species", "human"),
			"missing_parts": [],
			"prosthetics": {}
		},
		"wounds": [],
		"traits": built.get("traits", []),
		"birth": birth,
		"background": background,
		"xp_earned": spent,
		"is_hero": is_hero,
		"hero_id": ("hero_%s_%d" % [archetype_id, randi()]) if is_hero else ""
	}

	# Copy duel_stop_hp_pct if the archetype has one — read by combat_manager to end
	# the fight early when this enemy drops to that percentage of their maximum HP.
	if archetype.has("duel_stop_hp_pct"):
		enemy["duel_stop_hp_pct"] = archetype["duel_stop_hp_pct"]

	# Optional AI behavior mode — read by combat_arena during the enemy turn.
	# Supported: erratic_movement, priority_target, pack_bonus, burrow_emerge
	if archetype.has("ai_behavior"):
		enemy["ai_behavior"] = archetype["ai_behavior"]

	return enemy
## Calculate derived stats using the same formulas as CharacterSystem.
## This ensures enemies feel consistent with player characters.
func _calculate_derived_stats(attributes: Dictionary, skills: Dictionary) -> Dictionary:
	var con = attributes.get("constitution", 10)
	var fin = attributes.get("finesse", 10)
	var foc = attributes.get("focus", 10)
	var awa = attributes.get("awareness", 10)
	var luc = attributes.get("luck", 10)

	var derived = {
		"max_hp": 100 + (con - 10) * 10,
		"current_hp": 100 + (con - 10) * 10,
		"max_mana": 50 + (awa - 10) * 10,
		"current_mana": 50 + (awa - 10) * 10,
		"max_stamina": 50 + int((con + fin - 20) * 2.5),
		"current_stamina": 50 + int((con + fin - 20) * 2.5),
		"initiative": fin + awa,
		"movement": int(fin / 3),
		"dodge": fin,
		"spellpower": foc,
		"crit_chance": 5 + int((awa + fin + luc) / 6),
		"damage": 0,
		"armor": 0,
		"accuracy": 0,
		"armor_pierce": 0
	}

	# Apply the per-skill base bonus tables through the same code the player uses,
	# so the two cannot drift apart. This block used to be a hand-copied
	# translation of CharacterSystem's, and inherited the same bug: the tables
	# hold percentages and were being added as flat points.
	if CharacterSystem:
		var mods: Dictionary = CharacterSystem.collect_skill_stat_modifiers(skills)
		var before: Dictionary = {
			"max_hp": int(derived.get("max_hp", 0)),
			"max_mana": int(derived.get("max_mana", 0)),
			"max_stamina": int(derived.get("max_stamina", 0)),
		}
		CharacterSystem.apply_stat_modifiers(derived, mods)
		# Enemies are generated at full health, so carry any change to the pools
		# straight over to the current values.
		for pool in ["hp", "mana", "stamina"]:
			var max_key := "max_" + pool
			var cur_key := "current_" + pool
			derived[cur_key] = int(derived.get(cur_key, before[max_key])) \
				+ (int(derived.get(max_key, 0)) - before[max_key])

	return derived


## Map weapon type to physical damage subtype
func _get_weapon_damage_type(weapon_type: String) -> String:
	match weapon_type:
		"sword", "axe":
			return "slashing"
		"dagger", "spear", "bow", "crossbow", "thrown":
			return "piercing"
		"mace", "staff":
			return "crushing"
		_:
			return "crushing"


## Generate equipment stats based on archetype template + power level
func _generate_equipment(template: Dictionary, power_level: float) -> Dictionary:
	var result: Dictionary = {}

	# Weapon stats
	var weapon = template.get("weapon", {})
	var power_scale = power_level / 80.0  # Normalize around expected mid-game power

	result.weapon_type = weapon.get("type", "sword")
	result.weapon_damage = int(weapon.get("base_damage", 5) + power_scale * 2)
	result.weapon_accuracy = int(weapon.get("base_accuracy", 3) + power_scale * 1)
	result.weapon_range = weapon.get("range", 1)

	# Pass through armor category for item generation in _build_enemy
	result.armor_type = template.get("armor_type", "none")

	return result


## Pick spells the enemy can cast based on their skills.
## Starts with guaranteed spells, then picks from spells.json.
func _pick_spells(skills: Dictionary, guaranteed: Array) -> Array:
	var spell_list: Array = []

	# Add guaranteed spells first
	for spell_id in guaranteed:
		if all_spells.has(spell_id) and not spell_id in spell_list:
			spell_list.append(spell_id)

	# Find which schools the enemy can cast from
	var castable_schools: Dictionary = {}  # school_name (Capitalized) -> max skill level
	for skill_name in skills:
		if SKILL_TO_SCHOOL.has(skill_name):
			var school = SKILL_TO_SCHOOL[skill_name]
			var level = skills[skill_name]
			castable_schools[school] = level

	if castable_schools.is_empty():
		return spell_list

	# Scan all spells and find ones this enemy can cast
	var candidates: Array = []
	for spell_id in all_spells:
		if spell_id in spell_list:
			continue  # Already guaranteed

		var spell = all_spells[spell_id]
		var spell_level = spell.get("level", 1)
		# The spell's "level" field IS the minimum skill level required.
		var required_skill_level = spell_level
		var spell_schools = spell.get("schools", [])

		# Check if enemy has at least one school at the required skill level
		var can_cast = false
		for school in spell_schools:
			if castable_schools.has(school) and castable_schools[school] >= required_skill_level:
				can_cast = true
				break

		if can_cast:
			candidates.append({"id": spell_id, "level": spell_level})

	# Sort by level (prefer lower-level spells — more reliable)
	candidates.sort_custom(func(a, b): return a.level < b.level)

	# Pick up to 4 additional spells (beyond guaranteed)
	var max_extra = 4
	var added = 0
	# Shuffle within same level for variety
	candidates.shuffle()
	candidates.sort_custom(func(a, b): return a.level < b.level)

	for candidate in candidates:
		if added >= max_extra:
			break
		spell_list.append(candidate.id)
		added += 1

	return spell_list


## Build perks array from guaranteed perk IDs plus skill-appropriate entry-level perks.
## guaranteed: perk IDs forced onto this enemy from the archetype definition.
## skills: enemy skill dict — used to find additional qualifying perks via PerkSystem.
## Only perks with no requires_perks chain are eligible (enemies have no perk history),
## capped per skill to avoid over-loading: 1 perk at L1-2, 2 at L3-5, 3 at L6-8, 4 at L9-10.
func _build_perks(guaranteed: Array, skills: Dictionary = {}) -> Array:
	var perks: Array = []
	var owned_ids: Array[String] = []

	# Guaranteed perks first
	for perk_id in guaranteed:
		if perk_id in owned_ids:
			continue
		var perk_name = perk_id
		if PerkSystem:
			var perk_data = PerkSystem.get_perk_data(perk_id)
			if not perk_data.is_empty():
				perk_name = perk_data.get("name", perk_id)
		perks.append({"id": perk_id, "name": perk_name})
		owned_ids.append(perk_id)

	# Skill-based perks via a mock character (no owned perks = only entry-level qualify)
	if PerkSystem and not skills.is_empty():
		var mock_char = {"skills": skills, "perks": []}
		var eligible = PerkSystem.get_eligible_perks(mock_char)
		eligible.shuffle()  # Randomise within each skill's budget for variety

		var skill_perk_count: Dictionary = {}
		for perk_id in eligible:
			if perk_id in owned_ids:
				continue
			var perk_data = PerkSystem.get_perk_data(perk_id)
			if perk_data.is_empty():
				continue
			# Only skill perks (cross-perks are more exotic; leave those to guaranteed list)
			var skill_id: String = perk_data.get("skill", "")
			if skill_id == "":
				continue
			var skill_level: int = skills.get(skill_id, 0)
			# Cap perks per skill proportional to skill investment
			var cap: int = 1 + int(skill_level / 3)
			if skill_perk_count.get(skill_id, 0) >= cap:
				continue
			perks.append({"id": perk_id, "name": perk_data.get("name", perk_id)})
			owned_ids.append(perk_id)
			skill_perk_count[skill_id] = skill_perk_count.get(skill_id, 0) + 1

	return perks


## Generate a procedural personal name from name_parts.json.
##
## Language consistency: picks ONE language (tibetan/sanskrit/english) and uses all three
## parts from that language, so you never get mixed results like "Moha-crawl-born".
##
## Tibetan/Sanskrit format:  "Prefix-root-suffix"   (e.g. "Tsa-krul-pa", "Agni-ghora-kara")
## English format:           "Prefix Rootsuffix"    (e.g. "Delusion Born", "Blood Gnasher")
##
## realm:  "hell", "hungry_ghost", etc.     — filters which parts are valid
## tags:   archetype tags ["biological", …] — bias prefix affinity selection
## region: "cold_hell", "fire_hell", etc.   — extra tag for affinity matching
## race:   "devil", "shade", "imp", etc.    — restricts to race-appropriate parts
##
## Affinity-matched prefixes are preferred 70% of the time when available.
func generate_enemy_name(realm: String, tags: Array = [], region: String = "", race: String = "") -> String:
	var all_prefixes: Dictionary = name_parts.get("prefixes", {})
	var all_roots: Dictionary    = name_parts.get("roots",    {})
	var all_suffixes: Dictionary = name_parts.get("suffixes", {})

	# Build the tag set for affinity matching (archetype tags + region as pseudo-tag)
	var match_tags: Array = tags.duplicate()
	if region != "" and region != "any":
		match_tags.append(region)

	# Collect valid parts grouped by language.
	# Each language dict holds { "parts": [...], "affinity": [...] } for prefixes,
	# and plain arrays for roots/suffixes.
	var lang_prefixes:  Dictionary = {}  # lang -> Array[String] (all valid)
	var lang_affinity:  Dictionary = {}  # lang -> Array[String] (affinity-matched)
	var lang_roots:     Dictionary = {}  # lang -> Array[String]
	var lang_suffixes:  Dictionary = {}  # lang -> Array[String]

	for key in all_prefixes:
		if key.begins_with("_"):
			continue
		var entry: Dictionary = all_prefixes[key]
		if not realm in entry.get("realms", []):
			continue
		if race != "" and entry.has("races") and not race in entry.get("races", []):
			continue
		var lang: String = entry.get("lang", "tibetan")
		if not lang in lang_prefixes:
			lang_prefixes[lang] = []
			lang_affinity[lang]  = []
		lang_prefixes[lang].append(key)
		# Affinity check — any overlap with match_tags marks this prefix as preferred
		var affinity: Array = entry.get("affinity_tags", [])
		for tag in match_tags:
			if tag in affinity:
				lang_affinity[lang].append(key)
				break

	for key in all_roots:
		if key.begins_with("_"):
			continue
		var entry: Dictionary = all_roots[key]
		if not realm in entry.get("realms", []):
			continue
		if race != "" and entry.has("races") and not race in entry.get("races", []):
			continue
		var lang: String = entry.get("lang", "tibetan")
		if not lang in lang_roots:
			lang_roots[lang] = []
		lang_roots[lang].append(key)

	for key in all_suffixes:
		if key.begins_with("_"):
			continue
		var entry: Dictionary = all_suffixes[key]
		if not realm in entry.get("realms", []):
			continue
		if race != "" and entry.has("races") and not race in entry.get("races", []):
			continue
		var lang: String = entry.get("lang", "tibetan")
		if not lang in lang_suffixes:
			lang_suffixes[lang] = []
		lang_suffixes[lang].append(key)

	# Find languages that have at least one valid part in ALL three categories
	var complete_langs: Array[String] = []
	for lang in lang_prefixes:
		if lang in lang_roots and lang in lang_suffixes:
			complete_langs.append(lang)

	if complete_langs.is_empty():
		push_warning("EnemySystem: No complete language set for realm '%s', race '%s' — using fallback" % [realm, race])
		return "Unknown"

	# Pick one language for the whole name
	var chosen_lang: String = complete_langs[randi() % complete_langs.size()]

	# Pick prefix (prefer affinity match 70% of the time)
	var prefix: String
	var aff_list: Array = lang_affinity.get(chosen_lang, [])
	if not aff_list.is_empty() and randf() < 0.7:
		prefix = aff_list[randi() % aff_list.size()]
	else:
		prefix = lang_prefixes[chosen_lang][randi() % lang_prefixes[chosen_lang].size()]

	var root:   String = lang_roots[chosen_lang][randi() % lang_roots[chosen_lang].size()]
	var suffix: String = lang_suffixes[chosen_lang][randi() % lang_suffixes[chosen_lang].size()]

	# Format based on language:
	#   English → "Prefix Rootsuffix"  (e.g. "Blood Gnasher", "Delusion Born")
	#   Other   → "Prefix-root-suffix" (e.g. "Tsa-krul-pa",  "Agni-ghora-kara")
	if chosen_lang == "english":
		return prefix + " " + root.capitalize() + suffix
	else:
		return prefix + "-" + root + "-" + suffix


## Generate consumable inventory for an enemy based on archetype and power level.
## Higher power enemies get more/better items. Roles determine item types.
func _generate_enemy_inventory(archetype: Dictionary, power_level: float) -> Array:
	var inventory: Array = []
	var roles = archetype.get("roles", [])

	# Chance to have items at all increases with power
	var item_chance = clampf(power_level / 100.0, 0.2, 0.9)
	if randf() > item_chance:
		return inventory  # No items this enemy

	# All enemies: chance for a health potion
	if randf() < 0.6:
		if power_level > 60:
			inventory.append({"item_id": "greater_health_potion", "quantity": 1})
		else:
			inventory.append({"item_id": "health_potion", "quantity": 1})

	# Casters get mana potions
	var has_magic = false
	for role in roles:
		if role in ["caster", "support"]:
			has_magic = true
			break
	if has_magic and randf() < 0.5:
		if power_level > 60:
			inventory.append({"item_id": "greater_mana_potion", "quantity": 1})
		else:
			inventory.append({"item_id": "mana_potion", "quantity": 1})

	# Frontline/melee enemies may have bombs or oils
	var is_melee = false
	for role in roles:
		if role in ["frontline", "melee", "brute"]:
			is_melee = true
			break

	if is_melee and randf() < 0.3:
		# Pick a random bomb
		var bombs = ["fire_bomb", "smoke_bomb", "acid_flask"]
		inventory.append({"item_id": bombs[randi() % bombs.size()], "quantity": 1})

	# Ranged/assassin enemies may have oils
	var is_ranged_type = false
	for role in roles:
		if role in ["ranged", "assassin", "skirmisher"]:
			is_ranged_type = true
			break

	if is_ranged_type and randf() < 0.25:
		var oils = ["flame_oil", "frost_oil", "poison_oil"]
		inventory.append({"item_id": oils[randi() % oils.size()], "quantity": 1})

	# Higher power enemies get an extra potion
	if power_level > 80 and randf() < 0.4:
		inventory.append({"item_id": "health_potion", "quantity": 1})

	# Healer/support types carry herb bundles (useful in combat; also lootable)
	var is_healer = false
	for role in roles:
		if role in ["support", "healer"]:
			is_healer = true
			break
	if is_healer and randf() < 0.45:
		inventory.append({"item_id": "herb_bundle", "quantity": 1})

	# Heavily armored fighters accumulate scrap — they repair equipment in the field
	var armor_cat = archetype.get("equipment_template", {}).get("armor_type", "none")
	if armor_cat == "heavy" and randf() < 0.35:
		inventory.append({"item_id": "scrap_metal", "quantity": 1})

	# Casters and supports carry raw reagents for their rituals
	if has_magic and randf() < 0.30:
		inventory.append({"item_id": "raw_reagents", "quantity": 1})

	return inventory


## Pick a random archetype matching a role, region, rank range and realm.
## Region "any" archetypes can appear in any region.
## rank_range is inclusive on both ends; [1, 4] accepts anything below boss.
## Archetypes without an explicit rank fall back to their legacy tier, then 3.
## Archetypes without an explicit realm field default to "hell" (backwards compatibility).
## Words in an encounter id that name what the encounter is about.
##
## An encounter called animal_mriga_herd should contain mriga. Without this it
## drew any animal archetype matching the role, so a "mriga herd" came out as
## varaha chargers and a gana runner.
const ID_NOISE: Array[String] = [
	"hell", "hungry", "ghost", "animal", "domain", "human", "asura", "god",
	"lone", "pack", "patrol", "band", "group", "swarm", "herd", "flock",
	"ambush", "elite", "weakened", "boss", "any", "with", "and", "the",
]


func _encounter_family_tokens(encounter_id: String) -> Array[String]:
	var out: Array[String] = []
	for part in encounter_id.split("_", false):
		var token: String = String(part)
		if token.length() >= 3 and not token in ID_NOISE:
			out.append(token)
	return out


func _pick_archetype_for_role(role: String, region: String, rank_range: Array = [3, 3],
		realm: String = "hell", family: Array[String] = []) -> String:
	var candidates: Array[String] = []

	for arch_id in archetypes:
		var arch = archetypes[arch_id]
		var arch_roles = arch.get("roles", [])
		var arch_region = arch.get("region", "any")
		var arch_rank: int = archetype_rank(arch)
		var arch_realm = arch.get("realm", "hell")

		# Check role match
		if not role in arch_roles:
			continue

		# Region match. A requested region of "any" or "" means the encounter did
		# not care — do not filter. Treating "any" as a literal region to match
		# found nothing at all in the animal realm, where every archetype is
		# forest, meadow, ocean or sky and none is "any".
		if region != "" and region != "any":
			if arch_region != "any" and arch_region != region:
				continue

		# Don't pick bosses for regular role slots
		if "boss" in arch_roles:
			continue

		# Filter by rank. A range rather than an equality, so an encounter can
		# field its own family across the ranks its members actually occupy —
		# the mriga herd taking both the rank-3 stag and the rank-2 sentinel.
		if arch_rank < int(rank_range[0]) or arch_rank > int(rank_range[1]):
			continue

		# Filter by realm — don't mix hell demons into hungry ghost encounters, etc.
		# Archetypes with realm "any" (e.g. domain guardians) can appear in every realm.
		if arch_realm != "any" and arch_realm != realm:
			continue

		candidates.append(arch_id)

	if candidates.is_empty():
		return ""

	# Prefer an archetype the encounter is actually named after. Falls back to
	# the whole pool when the family cannot fill this role, so a mriga encounter
	# needing a caster still gets one rather than nothing.
	if not family.is_empty():
		var preferred: Array[String] = []
		for arch_id in candidates:
			for token in family:
				if token in arch_id:
					preferred.append(arch_id)
					break
		if not preferred.is_empty():
			return preferred[randi() % preferred.size()]

	return candidates[randi() % candidates.size()]


## Fallback encounter when encounter_id is unknown — 2 generic demon warriors
## Fallback when an encounter cannot be resolved. Picks an archetype belonging
## to the realm rather than a hell demon, which used to be hardcoded here and
## put demons in the animal realm's forest whenever a lookup failed.
func _generate_fallback_encounter(realm: String = "hell") -> Array[Dictionary]:
	var base: float = float(budgets.get("realm_median",
		budgets.get("realm_base", {})).get(realm, 200))

	var candidates: Array[String] = []
	for arch_id in archetypes:
		var a = archetypes[arch_id]
		if a.get("realm", "") == realm and not "boss" in a.get("roles", []):
			candidates.append(String(arch_id))
	candidates.sort()
	if candidates.is_empty():
		push_warning("EnemySystem: no fallback archetype for realm '%s'" % realm)
		return []

	push_warning("EnemySystem: falling back to a generic %s encounter" % realm)
	var enemies: Array[Dictionary] = []
	for i in range(2):
		var pick: String = candidates[randi() % candidates.size()]
		var enemy = _build_enemy(pick, int(base * 0.4), realm)
		if not enemy.is_empty():
			enemy["disposition"] = "hostile"
			enemies.append(enemy)
	return enemies