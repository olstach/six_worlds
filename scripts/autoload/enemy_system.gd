extends Node
## EnemySystem - Generates enemies from archetype definitions
##
## Loads enemy archetypes and encounter templates from JSON, then builds each
## enemy as a character from an XP budget. The budget is absolute per realm —
## it does NOT follow the player's strength — and is set by
## resources/data/enemies/encounter_budgets.json:
##     realm_base * encounter tier * rolled band * fight difficulty
## Enemies use the same stat system as player characters (attributes,
## derived stats, skills, spells).
##
## Usage:
##   var enemies = EnemySystem.generate_encounter("demon_patrol", "cold_hell", "hell", "hard")
##   # Returns Array[Dictionary] ready for CombatUnit.init_as_enemy()

# Loaded data from JSON
var archetypes: Dictionary = {}   # archetype_id -> archetype definition
var encounters: Dictionary = {}   # encounter_id -> encounter template
var name_parts: Dictionary = {}   # prefixes, roots, suffixes for procedural naming

## Encounter budget tables: realm bases, tier multipliers, rarity bands, reward
## fraction. An encounter's party XP is realm_base * tier * band.
var budgets: Dictionary = {}

## Party composition templates: member counts and relative XP shares.
var party_archetypes: Dictionary = {}

## Enemy AI templates (ai_templates.json): template_id -> knobs. "default" is
## both the fallback and the schema every other template is laid over.
var ai_templates: Dictionary = {}

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
	for tier in template.get("tiers", []):
		var span: Array = tier.get("count", [1, 1])
		var lo: int = int(span[0])
		var hi: int = int(span[1]) if span.size() > 1 else lo
		var n: int = lo + (randi() % maxi(1, hi - lo + 1))
		for i in range(n):
			members.append({"share": int(tier.get("share", 1)), "is_hero": false,
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

## Realm-like labels that name a kind of encounter rather than a rebirth realm.
const NON_BIRTH_REALMS: Array[String] = ["domain"]

## Skill -> consumables that skill's owner would plausibly be carrying, for
## their own use in a fight and as loot afterwards.
## Most items an archetype's own `consumables` list can buy, however rich it is.
const MAX_OWN_CONSUMABLES: int = 6

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


## Consumables an enemy carries — the ONE place they come from. Theirs to use
## in the fight, and the player's afterwards. Everything here is bought out of
## the consumable share of the kit budget, so a poorly kitted enemy carries
## little and a rich one carries more.
##
## What the money buys is decided in two passes, so flavour survives:
##   1. the character's own SKILLS (a medic's herbs, a caster's mana);
##   2. the archetype's ROLE wishlist (_role_consumable_wants: frontline
##      fighters like bombs, archers oils, healers herb bundles...), each item
##      only if it is still affordable and not already bought in pass 1.
## (This replaces a separate free-of-charge role pass that also handed out
## potions, so enemies were paid twice.)
func _generate_skill_consumables(skills: Dictionary, kit_budget: int,
		archetype: Dictionary = {}, power_scale: float = 1.0, reserve: int = 0) -> Array:
	var cfg: Dictionary = budgets.get("equipment", {})
	# `reserve` is money an archetype set aside for consumables before it
	# bought any gear (its own `consumable_share`, see generate_enemy); the
	# default share of whatever the gear left over is added on top.
	var spend: int = reserve + int(round(float(kit_budget) * float(cfg.get("consumable_share", 0.25))))
	var out: Array = []
	if spend <= 0:
		return out

	# Pass 0: an archetype's own `consumables` list — what a grenadier,
	# alchemist or tinkerer is FOR. Bought round-robin, one at a time, so a
	# list of three bombs comes out as a mix rather than six of the first.
	var own: Array = archetype.get("consumables", [])
	var bought: Dictionary = {}   # item_id -> quantity
	var own_count: int = 0
	var progress: bool = not own.is_empty()
	while progress and own_count < MAX_OWN_CONSUMABLES:
		progress = false
		for own_id in own:
			var own_cost: int = maxi(1, int(ItemSystem.get_item(String(own_id)).get("value", 10)))
			if own_cost > spend or own_count >= MAX_OWN_CONSUMABLES:
				continue
			bought[String(own_id)] = int(bought.get(String(own_id), 0)) + 1
			spend -= own_cost
			own_count += 1
			progress = true
	for own_id in bought:
		out.append({"item_id": own_id, "quantity": bought[own_id]})

	# Rank the skills that imply a consumable, best first.
	var ranked: Array[Dictionary] = []
	for skill in SKILL_TO_CONSUMABLES:
		var level: int = int(skills.get(skill, 0))
		if level > 0:
			ranked.append({"skill": String(skill), "level": level})
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

	# Pass 2: the role wishlist, one of each, whatever the money still covers.
	var already: Array[String] = []
	for entry in out:
		already.append(String(entry["item_id"]))
	for want_entry in _role_consumable_wants(archetype, power_scale):
		var want_id: String = String(want_entry["item_id"])
		if want_id in already or randf() >= float(want_entry["chance"]):
			continue
		var want_cost: int = maxi(1, int(ItemSystem.get_item(want_id).get("value", 10)))
		if want_cost > spend:
			continue
		out.append({"item_id": want_id, "quantity": 1})
		already.append(want_id)
		spend -= want_cost
	return out


## What an archetype's ROLES would like to carry, in priority order, as
## [{"item_id", "chance"}]. Pure flavour: it only says what the budget buys
## first; _generate_skill_consumables decides what is affordable. Better-kitted
## enemies (power_scale above 0.75) ask for the greater potions.
func _role_consumable_wants(archetype: Dictionary, power_scale: float) -> Array:
	var wants: Array = []
	var roles: Array = archetype.get("roles", [])
	var strong: bool = power_scale > 0.75

	# Everybody: a health potion.
	wants.append({"item_id": "greater_health_potion" if strong else "health_potion",
		"chance": 0.6})

	var has_magic := false
	var is_melee := false
	var is_ranged := false
	var is_healer := false
	for role in roles:
		if role in ["caster", "support"]:
			has_magic = true
		if role in ["frontline", "melee", "brute"]:
			is_melee = true
		if role in ["ranged", "assassin", "skirmisher"]:
			is_ranged = true
		if role in ["support", "healer"]:
			is_healer = true

	if has_magic:
		wants.append({"item_id": "greater_mana_potion" if strong else "mana_potion",
			"chance": 0.5})
		wants.append({"item_id": "raw_reagents", "chance": 0.3})
	if is_melee:
		var bombs: Array = ["fire_bomb", "smoke_bomb", "acid_flask"]
		wants.append({"item_id": String(bombs[randi() % bombs.size()]), "chance": 0.3})
	if is_ranged:
		var oils: Array = ["flame_oil", "frost_oil", "poison_oil"]
		wants.append({"item_id": String(oils[randi() % oils.size()]), "chance": 0.25})
	if is_healer:
		wants.append({"item_id": "herb_bundle", "chance": 0.45})
	# Heavy armour: scrap to repair it in the field.
	if archetype.get("equipment_template", {}).get("armor_type", "none") == "heavy":
		wants.append({"item_id": "scrap_metal", "chance": 0.35})
	return wants


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


## Tier order, weakest first. Used to derive a tier for encounters that carry none.
const TIER_ORDER: Array[String] = ["imp", "beast", "shade", "devil", "boss"]


## The tier an encounter counts as.
##
## Only 48 of 117 encounters carry a top-level `tier`; every `fixed` and
## `groups` one has none. Defaulting those to devil would silently flatten
## every boss fight to ordinary difficulty, so the tier is derived from the
## content instead — the strongest archetype or group in the encounter.
func resolve_encounter_tier(template: Dictionary) -> String:
	if template.has("tier"):
		return String(template["tier"])

	var best: int = -1
	if template.get("fixed", false):
		for entry in template.get("enemies", []):
			var aid: String = entry.get("archetype", "")
			var t: String = archetypes.get(aid, {}).get("tier", "devil")
			best = maxi(best, TIER_ORDER.find(t))
	for group in template.get("groups", []):
		best = maxi(best, TIER_ORDER.find(String(group.get("tier", "devil"))))

	if best < 0:
		push_warning("EnemySystem: cannot derive a tier for an encounter, using devil")
		return "devil"
	return TIER_ORDER[best]


## Turn whatever `difficulty` word a fight was written with into one of the
## tiers in encounter_budgets.json's `difficulty` table.
##
## - "" (no difficulty given) is "normal", silently.
## - A known tier is returned as it is.
## - An alias (a skill-roll word like "difficult", see `difficulty_aliases`) is
##   mapped onto its combat tier, with a warning so the data gets fixed.
## - Anything else is "normal", with a warning.
## tools/validate_data.py rejects the last two in data, so the warnings are for
## old saves and hand-built calls.
func normalize_difficulty(difficulty: String) -> String:
	var table: Dictionary = budgets.get("difficulty", {})
	var key: String = difficulty.strip_edges().to_lower()
	if key == "":
		return "normal"
	if table.has(key) and not key.begins_with("_"):
		return key
	var aliases: Dictionary = budgets.get("difficulty_aliases", {})
	if aliases.has(key) and table.has(String(aliases[key])):
		push_warning("EnemySystem: fight difficulty '%s' is a skill-roll word, using '%s'"
			% [difficulty, aliases[key]])
		return String(aliases[key])
	push_warning("EnemySystem: unknown fight difficulty '%s', using 'normal'" % difficulty)
	return "normal"


## The knobs for one difficulty tier, from encounter_budgets.json. Always
## returns a dictionary with an `xp_multiplier`, so a tier missing from the
## file behaves like normal instead of crashing.
func difficulty_settings(difficulty: String) -> Dictionary:
	var tier: String = normalize_difficulty(difficulty)
	var settings: Dictionary = budgets.get("difficulty", {}).get(tier, {}).duplicate()
	if not settings.has("xp_multiplier"):
		settings["xp_multiplier"] = 1.0
	return settings


## Total XP the enemy party is built from:
##     realm_base * tier * band * difficulty
## Absolute per realm — it does not track the player's own XP.
##
## Difficulty works through this one number on purpose. Everything else about
## an enemy — attributes, skills, breadth, gear rarity, consumables, spells —
## already follows its share of the budget, and so does what the party earns
## for winning (CombatManager pays a fraction of the enemy party's XP). One
## multiplier here therefore makes a "hard" fight harder in every way a
## stronger character is stronger, AND pays more for it. Multiplying HP after
## the build would do neither, and would quietly break the "XP is the only
## currency" rule the enemy builder rests on.
func resolve_party_budget(encounter_id: String, realm: String, difficulty: String = "normal") -> Dictionary:
	var template: Dictionary = encounters.get(encounter_id, {})
	var tier: String = resolve_encounter_tier(template)
	var diff_tier: String = normalize_difficulty(difficulty)
	var settings: Dictionary = difficulty_settings(diff_tier)

	# min_tier: a fight marked "boss" is priced as a boss even when its enemy
	# list is ordinary. It never lowers a tier that is already higher.
	var min_tier: String = String(settings.get("min_tier", ""))
	if min_tier != "" and TIER_ORDER.find(min_tier) > TIER_ORDER.find(tier):
		tier = min_tier

	# band: a fixed band instead of the common/uncommon/rare roll.
	var band: String = String(settings["band"]) if settings.has("band") else roll_band()

	var base: float = float(budgets.get("realm_base", {}).get(realm, 200))
	var tier_mult: float = float(budgets.get("tier_multipliers", {}).get(tier, 1.0))
	var diff_mult: float = float(settings["xp_multiplier"])
	var xp: int = maxi(1, int(round(base * tier_mult * _band_multiplier(band) * diff_mult)))

	return {"xp": xp, "band": band, "tier": tier, "difficulty": diff_tier}


func _ready() -> void:
	_load_budgets()
	_load_party_composition()
	_load_ai_templates()
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
# AI TEMPLATES
# ============================================

## Load resources/data/enemies/ai_templates.json. Its name doesn't end in
## _archetypes/_encounters, so the directory scan in _ready() skips it.
func _load_ai_templates() -> void:
	var file = FileAccess.open("res://resources/data/enemies/ai_templates.json", FileAccess.READ)
	if not file:
		push_error("EnemySystem: Could not load ai_templates.json")
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("EnemySystem: Failed to parse ai_templates.json: " + json.get_error_message())
		return
	var templates: Dictionary = json.get_data().get("templates", {})
	for key in templates:
		# Skip comment entries
		if key.begins_with("_"):
			continue
		ai_templates[key] = templates[key]
	if not ai_templates.has("default"):
		push_error("EnemySystem: ai_templates.json has no \"default\" template")


## Lay `overlay` over `base` and return a new dictionary. Nested dictionaries
## merge key by key; any other value (number, list, string) replaces outright.
## Keys starting with "_" are comments and are dropped.
static func _deep_merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in overlay:
		if str(key).begins_with("_"):
			continue
		var value = overlay[key]
		if value is Dictionary and result.get(key) is Dictionary:
			result[key] = _deep_merge(result[key], value)
		else:
			result[key] = value.duplicate(true) if (value is Dictionary or value is Array) else value
	# Comments copied from `base` aren't knobs either
	for key in result.keys():
		if str(key).begins_with("_"):
			result.erase(key)
	return result


## The AI knobs for one archetype: "default", then its ai_template, then its
## own "ai" overrides. An unknown template name warns and falls back to default.
## The result also records which template it came from, as "template".
func resolve_ai(archetype: Dictionary) -> Dictionary:
	var template_id: String = str(archetype.get("ai_template", "default"))
	if not ai_templates.has(template_id):
		push_warning("EnemySystem: unknown ai_template '%s' — using default" % template_id)
		template_id = "default"
	var knobs: Dictionary = _deep_merge(ai_templates.get("default", {}), ai_templates.get(template_id, {}))
	knobs = _deep_merge(knobs, archetype.get("ai", {}))
	knobs["template"] = template_id
	return knobs


## The AI knobs a unit's character_data carries. Enemies get theirs when they
## are built (_build_enemy); anything else the AI drives — summons, charmed or
## berserk party members — has none and gets the default template.
func get_ai(character_data: Dictionary) -> Dictionary:
	var ai = character_data.get("ai", {})
	if ai is Dictionary and not ai.is_empty():
		return ai
	return resolve_ai({})


# ============================================
# MAIN API
# ============================================

## Generate an encounter: returns Array of enemy dicts ready for CombatUnit.init_as_enemy()
## encounter_id: matches enemy_group from events/mobs JSON
## region: "cold_hell", "fire_hell", or "" for any
## realm: which of the six worlds this encounter is in — used for name generation
## difficulty: the fight's difficulty word from the event/mob ("easy", "normal",
##   "hard", "very_hard", "boss"). What each one does lives in the `difficulty`
##   table of encounter_budgets.json — see resolve_party_budget().
func generate_encounter(encounter_id: String, region: String = "", realm: String = "hell", difficulty: String = "normal") -> Array[Dictionary]:
	var template = encounters.get(encounter_id, {})
	if template.is_empty():
		push_warning("EnemySystem: Unknown encounter '%s', generating fallback" % encounter_id)
		return _generate_fallback_encounter(realm, difficulty)

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
		# from each archetype's own tier, so a boss is worth more than the
		# honour guard standing beside it rather than an equal quarter.
		for entry in template.get("enemies", []):
			var aid: String = String(entry.get("archetype", ""))
			var a_tier: String = String(archetypes.get(aid, {}).get("tier", "devil"))
			var a_share: int = maxi(1, TIER_ORDER.find(a_tier) + 1)
			for i in range(int(entry.get("count", 1))):
				slots.append({"archetype": aid, "share": a_share})

	elif template.has("groups"):
		# Authored shape: each group is a share tier, so a screen of chaff in
		# front of heavies stays a screen of chaff in front of heavies. The
		# group's tier rank is its share, which is what made the heavies heavy.
		for group in template.get("groups", []):
			var share: int = maxi(1, TIER_ORDER.find(String(group.get("tier", "devil"))) + 1)
			var group_region: String = String(group.get("region", effective_region))
			for role in group.get("roles", {}):
				for i in range(int(group["roles"][role])):
					slots.append({"role": String(role), "share": share,
						"tier": String(group.get("tier", "devil")), "region": group_region})

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
		return _generate_fallback_encounter(realm, difficulty)

	# Resolve each slot to an archetype before splitting the budget, so the
	# hero can be chosen by threat where the composition was authored.
	if template.has("disposition"):
		party_disposition = String(template["disposition"])

	var family: Array[String] = _encounter_family_tokens(encounter_id)
	for slot in slots:
		if not slot.has("archetype"):
			slot["archetype"] = _pick_archetype_for_role(
				String(slot["role"]), String(slot.get("region", effective_region)),
				String(slot.get("tier", budget["tier"])), realm, family)

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
			# A duel threshold written on the ENCOUNTER overrides the
			# archetype's (which _build_enemy already copied): the same boss
			# can fight to the death in one place and yield in another.
			if template.has("duel_stop_hp_pct"):
				enemy["duel_stop_hp_pct"] = int(template["duel_stop_hp_pct"])
			enemies.append(enemy)

	if enemies.is_empty():
		return _generate_fallback_encounter(realm, difficulty)
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

	# How well-equipped this character is, on one scale shared by everything
	# kit-related below: rarity, the role-based potions and bombs, and the
	# consumables bought from what the gear left over. 1.0 is a mid-game
	# character. It comes from the kit budget, which is itself a function of
	# XP — so a harder fight (more XP, see resolve_party_budget) is also a
	# better-equipped one, with no separate rule.
	#
	# Before 2026-10-15 the potion/bomb roll and the fallback weapon read the
	# raw XP budget against thresholds tuned for the OLD party-power number
	# (where ~80 was mid-game). XP runs from ~25 to several thousand, so every
	# animal-realm enemy saturated them and the crude weapon gained +2 damage
	# per 80 XP. They now read this scale instead.
	var kit_budget: int = equipment_budget_for_xp(xp_budget)
	var power_scale: float = float(kit_budget) / 180.0
	# An archetype with its own `consumable_share` (0.0-1.0) sets that part of
	# its kit aside for consumables BEFORE buying gear — a grenadier, alchemist
	# or tinkerer carries bombs and flasks instead of the best armour it could
	# afford. Without the key, consumables get the default share of what the
	# gear leaves over, as before.
	var consumable_reserve: int = 0
	if archetype.has("consumable_share"):
		consumable_reserve = int(round(float(kit_budget)
			* clampf(float(archetype["consumable_share"]), 0.0, 1.0)))
		kit_budget -= consumable_reserve

	# Birth and background first — the same two steps a player character takes.
	# "domain" is a content bucket (realm-agnostic guardian encounters), not a
	# place anyone is reborn into, so it has no births to roll. In play the
	# arena passes the party's real realm; only callers that hand over an
	# encounter's own stamped realm (the verifiers) arrive here with "domain".
	# They get the plain human the roll used to fall back to, without the
	# "no births defined" warning, which stays for genuine realm gaps.
	var birth: String = "human"
	if not realm in NON_BIRTH_REALMS:
		birth = CharacterSystem.roll_birth_for_realm(realm)
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

	var skills: Dictionary = built["skills"]
	var equipment_plan: Dictionary = _generate_equipment(archetype.get("equipment_template", {}))
	var spells = _pick_spells(skills, archetype.get("guaranteed_spells", []))
	var perks = _build_perks(archetype.get("guaranteed_perks", []), skills)

	# Some enemy types (imps) have a chance to be bare-handed — no equipment at all
	var no_equip_chance = archetype.get("no_equipment_chance", 0.0)
	var bare_handed = randf() < no_equip_chance

	# Resistances go on the sheet the way a player's do. base_resistances
	# already holds the birth's racial ones (apply_birth_modifiers put them
	# there); the archetype's own are ADDED to them — a skeleton archetype with
	# physical 30 born with physical 20 ends up at 50. Trait, equipment and
	# perk resistances are not added here: CharacterSystem.update_derived_stats
	# adds them into derived.resistances, the one place anyone reads.
	var base_resists: Dictionary = built.get("base_resistances", {})
	var arch_resists: Dictionary = archetype.get("resistances", {})
	for key in arch_resists:
		base_resists[key] = base_resists.get(key, 0) + arch_resists[key]
	built["base_resistances"] = base_resists

	# Everyday items and archetype-guaranteed items first (consumables are bought
	# later, from what the kit budget has left)
	var inventory: Array = []
	for everyday in _generate_everyday_items(skills, xp_budget):
		inventory.append(everyday)
	for item in archetype.get("starting_inventory", []):
		inventory.append(item)

	# Map power_scale to item rarity — shared by weapon and armor generation.
	# Realm drives the material tier (e.g. hell → bone/obsidian/bronze); rarity drives quality.
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

	# What it wears goes in its equipment slots, exactly like a party member's
	# (built["equipment"] is the blank character's slot layout). Everything
	# worn is ALSO in inventory, so it drops when the enemy dies.
	var equipment: Dictionary = built["equipment"]

	# The weapon or tool it fights with goes in the main hand. A bare-handed
	# enemy holds nothing and fights with its body's natural weapon (see
	# BodySystem.get_dominant_natural_weapon), as does one whose weapon could
	# not be generated.
	if not bare_handed:
		# A character better at a trade than at any weapon carries its tool
		# instead — a doctor with a bag, not a doctor with a borrowed spear.
		# A tool in the hand is not something you hit with, so it fights with
		# its fists, the same rule a party member follows.
		var tool: Dictionary = _tool_for_character(skills)
		var tool_id: String = ""
		if not tool.is_empty():
			tool_id = _affordable_tool_id(
				String(SKILL_TO_TOOL[tool["skill"]]), kit_budget)

		# What the character trained for wins over what the archetype template
		# says. A build that came out with ranged 8 carries a bow.
		var trained: Array[Dictionary] = _weapon_types_for_skills(skills)
		var weapon_type: String = String(trained[0]["type"]) if not trained.is_empty() \
			else String(equipment_plan.get("weapon_type", "sword"))

		var main_id: String = ""
		if tool_id != "" and ItemSystem.get_item(tool_id).size() > 0:
			main_id = tool_id
		else:
			main_id = ItemSystem.generate_weapon(weapon_type, item_rarity, "", "", realm)
			# A second set, when a second weapon skill is genuinely trained and
			# the character is worth enough to have afforded it. Carried rather
			# than wielded — it is a spare, and it drops.
			if main_id != "" and trained.size() > 1 and xp_budget >= 600 \
					and int(trained[1]["level"]) >= 3:
				var spare_id = ItemSystem.generate_weapon(
					String(trained[1]["type"]), item_rarity, "", "", realm)
				if spare_id != "":
					inventory.append({"item_id": spare_id, "quantity": 1})
		if main_id != "":
			equipment["weapon_set_1"]["main"] = main_id
			inventory.append({"item_id": main_id, "quantity": 1})
			kit_budget -= int(ItemSystem.get_item(main_id).get("value", 0))

	# Armour — same material-tiered system as the player. Each piece goes in
	# its slot; its stats reach derived through ItemSystem.calculate_equipment_stats,
	# the same as a party member's. Armour spends what the weapon left. A
	# character whose budget ran out on a good blade goes into the fight in
	# fewer pieces, which is how kit works.
	var armor_category: String = equipment_plan.get("armor_type", "none")
	for slot_entry in ARMOR_LOADOUTS.get(armor_category, []):
		if kit_budget <= 0:
			break
		var armor_gen_id = ItemSystem.generate_armor(slot_entry[1], item_rarity, "", "", realm)
		if armor_gen_id == "":
			continue
		var piece_value: int = int(ItemSystem.get_item(armor_gen_id).get("value", 0))
		if piece_value > kit_budget:
			continue  # cannot afford this piece; try the next, cheaper slot
		kit_budget -= piece_value
		equipment[String(slot_entry[0])] = armor_gen_id
		inventory.append({"item_id": armor_gen_id, "quantity": 1})
	# Gauntlets are one item for both hands: the left slot holds the pair and
	# the right mirrors it, as for a party member (counted once in the stats).
	ItemSystem.settle_glove_pairs(built)

	# Anything left buys a talisman, worn in the talisman slot.
	# 30 is the cheapest talisman in the game; anything above that is worth trying.
	if kit_budget >= 30:
		var tali_id = ItemSystem.generate_talisman(item_rarity)
		if tali_id != "":
			var tali = ItemSystem.get_item(tali_id)
			if int(tali.get("value", 0)) <= kit_budget:
				kit_budget -= int(tali.get("value", 0))
				equipment[String(tali.get("slot", "trinket1"))] = tali_id
				inventory.append({"item_id": tali_id, "quantity": 1})

	# Consumables come last, out of whatever the kit did not spend on gear.
	for consumable in _generate_skill_consumables(skills, kit_budget, archetype,
			power_scale, consumable_reserve):
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

	# The body it fights with. A bare-handed enemy's natural weapon is named
	# after it ("Tsa-krul-pa's Claws"); BodySystem applies the name to whatever
	# natural weapon the body reports. Generated weapons keep their own names.
	var body_plan: Dictionary = {
		"species": archetype.get("species", "human"),
		"missing_parts": [],
		"prosthetics": {}
	}
	if bare_handed:
		body_plan["natural_weapon_name"] = enemy_name + "'s Claws"

	# The enemy IS the sheet `built`: the same dictionary shape a party
	# character has (attributes, skills, equipment, base_resistances, traits,
	# derived...), plus the few keys only combat AI and loot read.
	var enemy: Dictionary = built
	enemy.merge({
		"name": enemy_name,
		"archetype_name": archetype.get("name", ""),  # Human-readable archetype, shown as subtitle in combat
		"archetype_id": archetype_id,
		# Whose side the sheet is on. Keeps the party's map buffs and
		# party-wide payouts off it (CharacterSystem.receives_party_effects).
		"allegiance": "enemy",
		"tags": archetype.get("tags", []),
		"actions": 2,
		"known_spells": spells,
		"perks": perks,
		"inventory": inventory,
		"body_plan": body_plan,
		"wounds": [],
		"birth": birth,
		"background": background,
		"xp_earned": spent,
		"is_hero": is_hero,
		"hero_id": ("hero_%s_%d" % [archetype_id, randi()]) if is_hero else ""
	}, true)

	# Derived stats come from the one formula every character uses: attributes,
	# per-level skill bonuses, elemental affinity, equipment, traits, perks.
	# EnemySystem has no formula of its own.
	CharacterSystem.update_derived_stats(enemy)
	# An enemy enters a fight fresh.
	var derived: Dictionary = enemy["derived"]
	derived["current_hp"] = derived["max_hp"]
	derived["current_mana"] = derived["max_mana"]
	derived["current_stamina"] = derived["max_stamina"]
	# CombatUnit.init_as_enemy reads these two from the top level.
	enemy["max_hp"] = derived["max_hp"]
	enemy["max_mana"] = derived["max_mana"]

	# Copy duel_stop_hp_pct if the archetype has one — read by combat_manager to end
	# the fight early when this enemy drops to that percentage of their maximum HP.
	if archetype.has("duel_stop_hp_pct"):
		enemy["duel_stop_hp_pct"] = archetype["duel_stop_hp_pct"]

	# Optional AI behavior mode — read by combat_arena during the enemy turn.
	# Supported: erratic_movement, pack_bonus, burrow_emerge. (Who to attack
	# is the AI template's targeting.prefer — the old "priority_target" is
	# targeting.prefer "weakest" now.)
	if archetype.has("ai_behavior"):
		enemy["ai_behavior"] = archetype["ai_behavior"]

	# AI template knobs (ai_templates.json + the archetype's "ai" overrides),
	# resolved once here so the combat AI reads a single dictionary.
	enemy["ai"] = resolve_ai(archetype)

	return enemy


## Read the archetype's equipment template: the weapon type it prefers (when
## its skills do not pick one) and its armour category. The real weapon and
## armour come from ItemSystem at a rarity set by the kit budget.
## (The template's base_damage / base_accuracy / range fed a crude weapon used
## when ItemSystem could not generate one. That weapon is gone: an enemy with
## nothing in hand fights with its body's natural weapon, like anyone else.)
func _generate_equipment(template: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	result.weapon_type = template.get("weapon", {}).get("type", "sword")
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


## Pick a random archetype that matches a given role, region, tier, and realm.
## Region "any" archetypes can appear in any region.
## Tier defaults to "devil" — use "shade" or "imp" for lower-power enemies.
## Archetypes without an explicit tier field default to "devil".
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


func _pick_archetype_for_role(role: String, region: String, tier: String = "devil",
		realm: String = "hell", family: Array[String] = []) -> String:
	var candidates: Array[String] = []

	for arch_id in archetypes:
		var arch = archetypes[arch_id]
		var arch_roles = arch.get("roles", [])
		var arch_region = arch.get("region", "any")
		var arch_tier = arch.get("tier", "devil")
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

		# Filter by tier — shades and imps don't appear in devil encounters and vice-versa
		if arch_tier != tier:
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


## Fallback when an encounter cannot be resolved. Picks an archetype belonging
## to the realm rather than a hell demon, which used to be hardcoded here and
## put demons in the animal realm's forest whenever a lookup failed.
## The fight's difficulty still applies, so a broken "easy" stays easier.
func _generate_fallback_encounter(realm: String = "hell", difficulty: String = "normal") -> Array[Dictionary]:
	var base: float = float(budgets.get("realm_base", {}).get(realm, 200)) \
		* float(difficulty_settings(difficulty)["xp_multiplier"])

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