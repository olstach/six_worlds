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
	_load_archetypes()
	_load_encounters()
	_load_spells()
	print("EnemySystem initialized: %d archetypes, %d encounters" % [archetypes.size(), encounters.size()])


# ============================================
# DATA LOADING
# ============================================

func _load_archetypes() -> void:
	var file = FileAccess.open("res://resources/data/enemies/hell_archetypes.json", FileAccess.READ)
	if not file:
		push_error("EnemySystem: Could not load hell_archetypes.json")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("EnemySystem: Failed to parse hell_archetypes.json: " + json.get_error_message())
		return

	var data = json.get_data()
	if data.has("archetypes"):
		for key in data.archetypes:
			# Skip comment entries
			if key.begins_with("_"):
				continue
			archetypes[key] = data.archetypes[key]


func _load_encounters() -> void:
	var file = FileAccess.open("res://resources/data/enemies/hell_encounters.json", FileAccess.READ)
	if not file:
		push_error("EnemySystem: Could not load hell_encounters.json")
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("EnemySystem: Failed to parse hell_encounters.json: " + json.get_error_message())
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


# ============================================
# MAIN API
# ============================================

## Generate an encounter: returns Array of enemy dicts ready for CombatUnit.init_as_enemy()
## encounter_id: matches enemy_group from events/mobs JSON
## region: "cold_hell", "fire_hell", or "" for any
func generate_encounter(encounter_id: String, region: String = "") -> Array[Dictionary]:
	var template = encounters.get(encounter_id, {})
	if template.is_empty():
		push_warning("EnemySystem: Unknown encounter '%s', generating fallback" % encounter_id)
		return _generate_fallback_encounter()

	var party_power = get_party_power()
	var enemies: Array[Dictionary] = []

	if template.get("fixed", false):
		# Fixed encounter — use exact archetypes
		for entry in template.get("enemies", []):
			var archetype_id = entry.get("archetype", "")
			var count = entry.get("count", 1)
			for i in range(count):
				var enemy = _build_enemy(archetype_id, party_power)
				if not enemy.is_empty():
					enemies.append(enemy)
	else:
		# Role-based encounter — pick random archetypes matching roles
		var enc_region = template.get("region", "any")
		# Use mob's region if provided, otherwise encounter's default
		var effective_region = region if region != "" else enc_region

		var diff_range = template.get("difficulty_range", [0.8, 1.2])
		var diff_min = diff_range[0] if diff_range.size() > 0 else 0.8
		var diff_max = diff_range[1] if diff_range.size() > 1 else 1.2

		var roles = template.get("roles", {})
		for role in roles:
			var count = int(roles[role])
			for i in range(count):
				var archetype_id = _pick_archetype_for_role(role, effective_region)
				if archetype_id == "":
					push_warning("EnemySystem: No archetype found for role '%s' in region '%s'" % [role, effective_region])
					continue

				# Random difficulty within range
				var difficulty = randf_range(diff_min, diff_max)
				var enemy = _build_enemy(archetype_id, party_power * difficulty)
				if not enemy.is_empty():
					enemies.append(enemy)

	if enemies.is_empty():
		push_warning("EnemySystem: Encounter '%s' produced no enemies, using fallback" % encounter_id)
		return _generate_fallback_encounter()

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

## Build a single enemy dict from an archetype + power budget
func _build_enemy(archetype_id: String, power_budget: float) -> Dictionary:
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

	# Apply equipment bonuses to derived stats
	derived.damage += equipment.get("weapon_damage", 0)
	derived.accuracy += equipment.get("weapon_accuracy", 0)
	derived.armor += equipment.get("armor_value", 0)

	# Build resistances dict (start with defaults, apply archetype overrides)
	var resistances = {
		"physical": 0, "space": 0, "air": 0,
		"fire": 0, "water": 0, "earth": 0
	}
	var arch_resists = archetype.get("resistances", {})
	for key in arch_resists:
		resistances[key] = arch_resists[key]

	# Build the weapon dict for CombatUnit
	var weapon_type = equipment.get("weapon_type", "sword")
	var equipped_weapon = {
		"name": archetype.get("name", "Enemy") + "'s Weapon",
		"type": weapon_type,
		"damage_type": _get_weapon_damage_type(weapon_type),
		"stats": {
			"damage": equipment.get("weapon_damage", 5),
			"accuracy": equipment.get("weapon_accuracy", 3),
			"range": equipment.get("weapon_range", 1)
		}
	}

	# Generate consumable inventory based on role and power
	var inventory = _generate_enemy_inventory(archetype, effective_budget)

	# Assemble final enemy dict matching CombatUnit.init_as_enemy() expectations
	var enemy: Dictionary = {
		"name": archetype.get("name", "Enemy"),
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
		"max_mana": 100 + (awa - 10) * 10,
		"current_mana": 100 + (awa - 10) * 10,
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
		"dagger", "spear", "bow", "thrown":
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


## Pick a random archetype that matches a given role and region.
## Region "any" archetypes can appear in any region.
func _pick_archetype_for_role(role: String, region: String) -> String:
	var candidates: Array[String] = []

	for arch_id in archetypes:
		var arch = archetypes[arch_id]
		var arch_roles = arch.get("roles", [])
		var arch_region = arch.get("region", "any")

		# Check role match
		if not role in arch_roles:
			continue

		# Check region match: archetype's region must be "any" or match the requested region
		if arch_region != "any" and arch_region != region:
			continue

		# Don't pick bosses for regular role slots
		if "boss" in arch_roles:
			continue

		candidates.append(arch_id)

	if candidates.is_empty():
		return ""

	return candidates[randi() % candidates.size()]


## Fallback encounter when encounter_id is unknown — 2 generic demon warriors
func _generate_fallback_encounter() -> Array[Dictionary]:
	var party_power = get_party_power()
	var enemies: Array[Dictionary] = []

	for i in range(2):
		var enemy = _build_enemy("hell_demon_warrior", party_power * 0.8)
		if not enemy.is_empty():
			enemies.append(enemy)

	return enemies
