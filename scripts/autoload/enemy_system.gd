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

# Armor type -> base armor value per power level
const ARMOR_VALUES: Dictionary = {
	"none": 0,
	"light": 2,
	"medium": 4,
	"heavy": 6
}


func _ready() -> void:
	_load_archetypes("res://resources/data/enemies/hell_archetypes.json")
	_load_archetypes("res://resources/data/enemies/hungry_ghost_archetypes.json")
	_load_encounters("res://resources/data/enemies/hell_encounters.json")
	_load_encounters("res://resources/data/enemies/hungry_ghost_encounters.json")
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
		for key in data.encounters:
			if key.begins_with("_"):
				continue
			encounters[key] = data.encounters[key]


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
func generate_encounter(encounter_id: String, region: String = "", realm: String = "hell") -> Array[Dictionary]:
	var template = encounters.get(encounter_id, {})
	if template.is_empty():
		push_warning("EnemySystem: Unknown encounter '%s', generating fallback" % encounter_id)
		return _generate_fallback_encounter(realm)

	var party_power = get_party_power()
	var enemies: Array[Dictionary] = []

	if template.get("fixed", false):
		# Fixed encounter — use exact archetypes
		for entry in template.get("enemies", []):
			var archetype_id = entry.get("archetype", "")
			var count = entry.get("count", 1)
			for i in range(count):
				var enemy = _build_enemy(archetype_id, party_power, realm, region)
				if not enemy.is_empty():
					enemies.append(enemy)

	elif template.get("mixed", false):
		# Mixed encounter — groups of different tiers (e.g. 1 devil + 2 imps)
		var enc_region = template.get("region", "any")
		var effective_region = region if region != "" else enc_region

		for group in template.get("groups", []):
			var group_tier = group.get("tier", "devil")
			var group_region = group.get("region", effective_region)
			var diff_range = group.get("difficulty_range", [0.8, 1.2])
			var diff_min = diff_range[0] if diff_range.size() > 0 else 0.8
			var diff_max = diff_range[1] if diff_range.size() > 1 else 1.2

			var group_roles = group.get("roles", {})
			for role in group_roles:
				var count = int(group_roles[role])
				for i in range(count):
					var archetype_id = _pick_archetype_for_role(role, group_region, group_tier, realm)
					if archetype_id == "":
						push_warning("EnemySystem: No archetype for role '%s' tier '%s' in '%s'" % [role, group_tier, group_region])
						continue
					var difficulty = randf_range(diff_min, diff_max)
					var enemy = _build_enemy(archetype_id, party_power * difficulty, realm, group_region)
					if not enemy.is_empty():
						enemies.append(enemy)

	else:
		# Role-based encounter — pick random archetypes matching roles and tier
		var enc_region = template.get("region", "any")
		# Use mob's region if provided, otherwise encounter's default
		var effective_region = region if region != "" else enc_region
		var enc_tier = template.get("tier", "devil")

		var diff_range = template.get("difficulty_range", [0.8, 1.2])
		var diff_min = diff_range[0] if diff_range.size() > 0 else 0.8
		var diff_max = diff_range[1] if diff_range.size() > 1 else 1.2

		var roles = template.get("roles", {})
		for role in roles:
			var count = int(roles[role])
			for i in range(count):
				var archetype_id = _pick_archetype_for_role(role, effective_region, enc_tier, realm)
				if archetype_id == "":
					push_warning("EnemySystem: No archetype found for role '%s' tier '%s' in region '%s'" % [role, enc_tier, effective_region])
					continue

				# Random difficulty within range
				var difficulty = randf_range(diff_min, diff_max)
				var enemy = _build_enemy(archetype_id, party_power * difficulty, realm, effective_region)
				if not enemy.is_empty():
					enemies.append(enemy)

	if enemies.is_empty():
		push_warning("EnemySystem: Encounter '%s' produced no enemies, using fallback" % encounter_id)
		return _generate_fallback_encounter(realm)

	return enemies


## Calculate party power as a single number representing party strength.
## For each party member: sum of (attribute - 10) for all attributes + skill levels * 20
## Returns the average across the party.
func get_party_power() -> float:
	var party = CharacterSystem.get_party()
	if party.is_empty():
		return 50.0  # Default for empty party

	var total_power: float = 0.0
	for member in party:
		var member_power: float = 0.0

		# Attribute contribution: each point above 10 adds to power
		var attrs = member.get("attributes", {})
		for attr_name in attrs:
			member_power += float(attrs[attr_name] - 10)

		# Skill contribution: each skill level × 8
		# (Skills unlock perks/spells but don't directly add raw combat stats,
		# so the multiplier is kept moderate to avoid over-inflating enemy attributes)
		var skills = member.get("skills", {})
		for skill_name in skills:
			member_power += float(skills[skill_name]) * 8.0

		total_power += member_power

	return total_power / float(party.size())


# ============================================
# ENEMY BUILDING
# ============================================

## Build a single enemy dict from an archetype + power budget.
## realm and region are passed through for procedural name generation.
func _build_enemy(archetype_id: String, power_budget: float, realm: String = "hell", region: String = "") -> Dictionary:
	var archetype = archetypes.get(archetype_id, {})
	if archetype.is_empty():
		push_warning("EnemySystem: Unknown archetype '%s'" % archetype_id)
		return {}

	# Apply threat multiplier to budget
	var threat = archetype.get("threat_multiplier", 1.0)
	var effective_budget = power_budget * threat

	# Distribute attribute points (budget split: ~60% attributes, ~40% skills)
	var attr_budget = int(effective_budget * 0.6)
	var skill_budget = int(effective_budget * 0.4 / 20.0)  # Convert to skill "points"
	# Minimum budgets so enemies always have something
	attr_budget = maxi(attr_budget, 4)
	skill_budget = maxi(skill_budget, 1)

	var attributes = _distribute_attributes(archetype.get("attribute_weights", {}), attr_budget)
	var skills = _assign_skills(archetype.get("skill_priorities", []), skill_budget)
	var derived = _calculate_derived_stats(attributes, skills)
	var equipment = _generate_equipment(archetype.get("equipment_template", {}), effective_budget)
	var spells = _pick_spells(skills, archetype.get("guaranteed_spells", []))
	var perks = _build_perks(archetype.get("guaranteed_perks", []))

	# Some enemy types (imps) have a chance to be bare-handed — no equipment at all
	var no_equip_chance = archetype.get("no_equipment_chance", 0.0)
	var bare_handed = randf() < no_equip_chance

	# Apply armor bonus to derived stats. Weapon damage/accuracy are no longer added
	# to derived — they come from the generated weapon's stats dict instead.
	if not bare_handed:
		derived.armor += equipment.get("armor_value", 0)

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
	for item in archetype.get("starting_inventory", []):
		inventory.append(item)

	# Build the weapon for CombatUnit — generated items for armed enemies so they
	# carry real material-tiered weapons with traits and durability.
	var equipped_weapon: Dictionary
	if bare_handed:
		equipped_weapon = {
			"name": archetype.get("name", "Enemy") + "'s Claws",
			"type": "unarmed",
			"damage_type": "crushing",
			"stats": {"damage": 2, "accuracy": 4, "range": 1}
		}
	else:
		var weapon_type = equipment.get("weapon_type", "sword")
		# Map power scale to rarity for weapon quality (realm drives material tier)
		var power_scale = effective_budget / 80.0
		var weapon_rarity: String
		if power_scale < 0.5:
			weapon_rarity = "common"
		elif power_scale < 1.0:
			weapon_rarity = "uncommon"
		elif power_scale < 1.5:
			weapon_rarity = "rare"
		elif power_scale < 2.0:
			weapon_rarity = "epic"
		else:
			weapon_rarity = "legendary"

		var gen_id = ItemSystem.generate_weapon(weapon_type, weapon_rarity, "", "", realm)
		if gen_id != "":
			equipped_weapon = ItemSystem.get_item(gen_id)
			# Add to inventory so the weapon can be looted when this enemy is defeated
			inventory.append({"item_id": gen_id, "quantity": 1})
		else:
			# Fallback to hardcoded dict if ItemSystem unavailable
			equipped_weapon = {
				"name": archetype.get("name", "Enemy") + "'s Weapon",
				"type": weapon_type,
				"damage_type": _get_weapon_damage_type(weapon_type),
				"stats": {
					"damage": equipment.get("weapon_damage", 5),
					"accuracy": equipment.get("weapon_accuracy", 3),
					"range": equipment.get("weapon_range", 1)
				}
			}

	# Generate a procedural name from realm/region/tags, unless this is a named boss.
	# Race is inferred from archetype tags: imps first, then shades (undead+incorporeal),
	# then biological devils, then elementals (no biology).
	var tags = archetype.get("tags", [])
	var is_boss = "boss" in archetype.get("roles", [])
	var race: String
	if "imp" in tags:
		race = "imp"
	elif "undead" in tags and "incorporeal" in tags:
		race = "shade"
	elif "biological" in tags or "devil" in tags:
		race = "devil"
	else:
		race = "elemental"

	var enemy_name: String
	if is_boss or name_parts.is_empty():
		enemy_name = archetype.get("name", "Enemy")
	else:
		enemy_name = generate_enemy_name(realm, tags, region, race)

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
		"inventory": inventory
	}

	return enemy


## Distribute attribute points from budget according to weights.
## All attributes start at 10, then budget points are spread proportionally.
func _distribute_attributes(weights: Dictionary, budget: int) -> Dictionary:
	var attributes = {
		"strength": 10, "finesse": 10, "constitution": 10,
		"focus": 10, "awareness": 10, "charm": 10, "luck": 10
	}

	# Calculate total weight
	var total_weight: float = 0.0
	for attr in weights:
		total_weight += float(weights[attr])

	if total_weight <= 0 or budget <= 0:
		return attributes

	# Distribute proportionally
	var remaining = budget
	var attr_list = weights.keys()
	# Sort by weight descending so highest-priority attributes get remainders
	attr_list.sort_custom(func(a, b): return weights[a] > weights[b])

	for attr in attr_list:
		if not attributes.has(attr):
			continue
		var weight = float(weights[attr])
		var share = int(float(budget) * weight / total_weight)
		share = mini(share, remaining)
		attributes[attr] += share
		remaining -= share

	# Distribute any remainder to the highest-weight attribute
	if remaining > 0 and not attr_list.is_empty():
		var top_attr = attr_list[0]
		if attributes.has(top_attr):
			attributes[top_attr] += remaining

	return attributes


## Assign skill levels from a priority list.
## Each "point" raises a skill by 1 level (simplified from player XP costs).
## Skills cap at 5.
func _assign_skills(priorities: Array, budget: int) -> Dictionary:
	var skills: Dictionary = {}
	if priorities.is_empty() or budget <= 0:
		return skills

	var remaining = budget
	# Spread points across priorities, cycling through them
	var round_index = 0
	while remaining > 0:
		var assigned_any = false
		for skill_name in priorities:
			if remaining <= 0:
				break
			var current = skills.get(skill_name, 0)
			if current < 5:
				skills[skill_name] = current + 1
				remaining -= 1
				assigned_any = true

		if not assigned_any:
			break  # All skills maxed
		round_index += 1

	return skills


## Calculate derived stats using the same formulas as CharacterSystem.
## This ensures enemies feel consistent with player characters.
func _calculate_derived_stats(attributes: Dictionary, skills: Dictionary) -> Dictionary:
	var con = attributes.get("constitution", 10)
	var fin = attributes.get("finesse", 10)
	var foc = attributes.get("focus", 10)
	var awa = attributes.get("awareness", 10)
	var luc = attributes.get("luck", 10)

	return {
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
		"damage": 0,     # Added later from equipment
		"armor": 0,      # Added later from equipment
		"accuracy": 0,   # Added later from equipment
		"armor_pierce": 0
	}


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

	# Armor value from armor type
	var armor_type = template.get("armor_type", "none")
	var base_armor = ARMOR_VALUES.get(armor_type, 0)
	result.armor_value = int(base_armor + power_scale * 1.5)

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
		var spell_schools = spell.get("schools", [])

		# Check if enemy has at least one school at the required level
		var can_cast = false
		for school in spell_schools:
			if castable_schools.has(school) and castable_schools[school] >= spell_level:
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


## Build perks array from guaranteed perk IDs
func _build_perks(guaranteed: Array) -> Array:
	var perks: Array = []
	for perk_id in guaranteed:
		# Try to get perk name from PerkSystem
		var perk_name = perk_id
		if PerkSystem:
			var perk_data = PerkSystem.get_perk(perk_id)
			if not perk_data.is_empty():
				perk_name = perk_data.get("name", perk_id)
		perks.append({"id": perk_id, "name": perk_name})
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

	return inventory


## Pick a random archetype that matches a given role, region, tier, and realm.
## Region "any" archetypes can appear in any region.
## Tier defaults to "devil" — use "shade" or "imp" for lower-power enemies.
## Archetypes without an explicit tier field default to "devil".
## Archetypes without an explicit realm field default to "hell" (backwards compatibility).
func _pick_archetype_for_role(role: String, region: String, tier: String = "devil", realm: String = "hell") -> String:
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

		# Check region match: archetype's region must be "any" or match the requested region
		if arch_region != "any" and arch_region != region:
			continue

		# Don't pick bosses for regular role slots
		if "boss" in arch_roles:
			continue

		# Filter by tier — shades and imps don't appear in devil encounters and vice-versa
		if arch_tier != tier:
			continue

		# Filter by realm — don't mix hell demons into hungry ghost encounters, etc.
		if arch_realm != realm:
			continue

		candidates.append(arch_id)

	if candidates.is_empty():
		return ""

	return candidates[randi() % candidates.size()]


## Fallback encounter when encounter_id is unknown — 2 generic demon warriors
func _generate_fallback_encounter(realm: String = "hell") -> Array[Dictionary]:
	var party_power = get_party_power()
	var enemies: Array[Dictionary] = []

	for i in range(2):
		var enemy = _build_enemy("hell_demon_warrior", party_power * 0.8, realm)
		if not enemy.is_empty():
			enemies.append(enemy)

	return enemies
