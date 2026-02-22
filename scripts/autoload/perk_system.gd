extends Node
## PerkSystem - Manages perk data, eligibility checking, and selection
##
## Loads perks.json and provides:
## - Eligibility checking based on character skills and existing perks
## - Random perk selection (pick 4 eligible, player chooses 1)
## - Perk granting and tracking
## - Elemental affinity calculation and bonuses

# Signals
signal perk_selection_ready(character: Dictionary, perks: Array)
signal perk_granted(character: Dictionary, perk_id: String, perk_data: Dictionary)

# Perk databases loaded from JSON
var _skill_perks: Dictionary = {}      # perk_id -> perk data
var _cross_perks: Dictionary = {}      # perk_id -> perk data
var _base_bonuses: Dictionary = {}     # skill_id -> base bonus table

# Skill metadata loaded from skills.json
var _skill_elements: Dictionary = {}   # skill_id -> element name

# Skill categories for special requirement checks
const WEAPON_SKILLS: Array[String] = [
	"swords", "martial_arts", "ranged", "daggers",
	"axes", "unarmed", "spears", "maces"
]

const MAGIC_SCHOOLS: Array[String] = [
	"space_magic", "white_magic", "black_magic", "air_magic",
	"fire_magic", "water_magic", "earth_magic", "sorcery",
	"enchantment", "summoning"
]

const ELEMENTAL_MAGICS: Array[String] = [
	"space_magic", "air_magic", "fire_magic", "water_magic", "earth_magic"
]

# Element -> list of skill IDs (built from skills.json)
var _element_skills: Dictionary = {}

# Number of perks offered per skill level-up
const PERKS_OFFERED: int = 4


func _ready() -> void:
	_load_skills_data()
	_load_perks_data()
	print("PerkSystem initialized: ", _skill_perks.size(), " skill perks, ",
		_cross_perks.size(), " cross perks, ", _base_bonuses.size(), " base bonus tables")


# ============================================
# DATA LOADING
# ============================================

func _load_skills_data() -> void:
	## Load skill-to-element mappings from skills.json
	var file_path = "res://resources/data/skills.json"
	if not FileAccess.file_exists(file_path):
		push_error("PerkSystem: skills.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("PerkSystem: Failed to parse skills.json: ", json.get_error_message())
		return

	var data = json.get_data()
	var skills = data.get("skills", {})

	# Build skill -> element mapping and element -> skills mapping
	for skill_id in skills:
		var skill_data = skills[skill_id]
		var element = skill_data.get("element", "")
		_skill_elements[skill_id] = element

		if not _element_skills.has(element):
			_element_skills[element] = []
		_element_skills[element].append(skill_id)


func _load_perks_data() -> void:
	## Load perk definitions from perks.json
	var file_path = "res://resources/data/perks.json"
	if not FileAccess.file_exists(file_path):
		push_error("PerkSystem: perks.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("PerkSystem: Failed to parse perks.json: ", json.get_error_message())
		return

	var data = json.get_data()
	_base_bonuses = data.get("base_bonuses", {})
	_skill_perks = data.get("skill_perks", {})
	_cross_perks = data.get("cross_perks", {})


# ============================================
# PERK ELIGIBILITY
# ============================================

func get_eligible_perks(character: Dictionary) -> Array[String]:
	## Returns all perk IDs the character qualifies for but doesn't have yet.
	var owned := _get_owned_perk_ids(character)
	var eligible: Array[String] = []

	# Check skill perks
	for perk_id in _skill_perks:
		if perk_id in owned:
			continue
		if _is_skill_perk_eligible(character, perk_id, owned):
			eligible.append(perk_id)

	# Check cross-skill perks
	for perk_id in _cross_perks:
		if perk_id in owned:
			continue
		if _is_cross_perk_eligible(character, perk_id, owned):
			eligible.append(perk_id)

	return eligible


func _is_skill_perk_eligible(character: Dictionary, perk_id: String, owned: Array[String]) -> bool:
	## Check if a character meets the requirements for a skill perk.
	var perk = _skill_perks[perk_id]
	var skills = character.get("skills", {})

	# Check primary skill level
	var skill_id = perk.get("skill", "")
	var required_level = perk.get("required_level", 1)
	if skills.get(skill_id, 0) < required_level:
		return false

	# Check secondary skill requirements (also_requires)
	var also_requires = perk.get("also_requires", {})
	for req_skill in also_requires:
		if skills.get(req_skill, 0) < also_requires[req_skill]:
			return false

	# Check prerequisite perks
	if not _check_perk_prerequisites(perk, owned):
		return false

	# Check special requirements
	if perk.has("special_requirement"):
		if not _check_special_requirement(character, perk.special_requirement):
			return false

	return true


func _is_cross_perk_eligible(character: Dictionary, perk_id: String, owned: Array[String]) -> bool:
	## Check if a character meets the requirements for a cross-skill perk.
	var perk = _cross_perks[perk_id]
	var skills = character.get("skills", {})

	# Check all skill requirements
	var requirements = perk.get("requirements", {})
	for req_skill in requirements:
		if skills.get(req_skill, 0) < requirements[req_skill]:
			return false

	# Check OR skill requirements (e.g., Persuasion 2 OR Comedy 2)
	var or_reqs = perk.get("or_skill_requirements", {})
	if not or_reqs.is_empty():
		var any_met := false
		for req_skill in or_reqs:
			if skills.get(req_skill, 0) >= or_reqs[req_skill]:
				any_met = true
				break
		if not any_met:
			return false

	# Check prerequisite perks
	if not _check_perk_prerequisites(perk, owned):
		return false

	# Check special requirements
	if perk.has("special_requirement"):
		if not _check_special_requirement(character, perk.special_requirement):
			return false

	return true


func _check_perk_prerequisites(perk: Dictionary, owned: Array[String]) -> bool:
	## Check if prerequisite perks are met. Supports OR lists.
	var requires_perks = perk.get("requires_perks", [])
	for prereq in requires_perks:
		if prereq is Array:
			# OR requirement: need at least one
			var any_met := false
			for option in prereq:
				if option in owned:
					any_met = true
					break
			if not any_met:
				return false
		else:
			# Single perk requirement
			if prereq not in owned:
				return false
	return true


func _check_special_requirement(character: Dictionary, special: String) -> bool:
	## Check special requirements like "any_3_weapon_skills_at_3" or "fire_affinity_25".
	var skills = character.get("skills", {})

	# Affinity requirements: "space_affinity_40" (threshold raised to 40 for 10-level scale)
	var affinity_match := special.split("_affinity_")
	if affinity_match.size() == 2:
		var element = affinity_match[0]
		var required = int(affinity_match[1])
		var total = calculate_element_affinity(character, element)
		return total >= required

	# "any_X_category_at_Y" patterns
	# Examples: any_3_weapon_skills_at_3, any_weapon_skill_at_3, any_3_elemental_magics_at_2

	# Pattern: any_N_category_at_level
	if special.begins_with("any_"):
		var parts = special.split("_at_")
		if parts.size() == 2:
			var required_level = int(parts[1])
			var category_part = parts[0].substr(4)  # Remove "any_"

			# Check if it starts with a number (count required)
			var count_required := 1
			var category_str: String = category_part
			var first_underscore = category_part.find("_")
			if first_underscore > 0 and category_part.substr(0, first_underscore).is_valid_int():
				count_required = int(category_part.substr(0, first_underscore))
				category_str = category_part.substr(first_underscore + 1)

			# Get the skill list for the category
			var check_skills := _get_skills_for_category(category_str)

			# Count how many meet the level requirement
			var count := 0
			for skill_id in check_skills:
				if skills.get(skill_id, 0) >= required_level:
					count += 1

			return count >= count_required

	return false


func _get_skills_for_category(category: String) -> Array:
	## Map category strings from special requirements to skill lists.
	match category:
		"weapon_skills", "weapon_skill", "different_weapon_skills":
			return WEAPON_SKILLS
		"elemental_magics", "elemental_magic":
			return ELEMENTAL_MAGICS
		"magic_school", "magic_schools":
			return MAGIC_SCHOOLS
		_:
			push_warning("PerkSystem: Unknown skill category: ", category)
			return []


# ============================================
# PERK SELECTION
# ============================================

func get_perk_selection(character: Dictionary, count: int = PERKS_OFFERED, last_skill: String = "") -> Array[Dictionary]:
	## Get a random selection of eligible perks for the character to choose from.
	## Returns an array of {id, data, source} dicts.
	## last_skill: perks belonging to this skill appear 3x in the pool (higher chance).
	var eligible = get_eligible_perks(character)

	# Build weighted pool: perks for last_skill appear 3 times, all others once.
	# After shuffling and deduplicating, this gives last_skill perks ~3x the chance.
	var weighted_pool: Array[String] = []
	for perk_id in eligible:
		weighted_pool.append(perk_id)
		if last_skill != "" and perk_id in _skill_perks:
			if _skill_perks[perk_id].get("skill", "") == last_skill:
				weighted_pool.append(perk_id)
				weighted_pool.append(perk_id)

	weighted_pool.shuffle()

	# Pick up to `count` unique perks from the shuffled weighted pool
	var selected: Array[Dictionary] = []
	var seen: Array[String] = []

	for perk_id in weighted_pool:
		if perk_id in seen:
			continue
		seen.append(perk_id)

		var perk_data: Dictionary
		var source: String

		if perk_id in _skill_perks:
			perk_data = _skill_perks[perk_id]
			source = "skill"
		elif perk_id in _cross_perks:
			perk_data = _cross_perks[perk_id]
			source = "cross"
		else:
			continue

		selected.append({
			"id": perk_id,
			"data": perk_data,
			"source": source
		})

		if selected.size() >= count:
			break

	return selected


# ============================================
# PERK GRANTING
# ============================================

func grant_perk(character: Dictionary, perk_id: String) -> bool:
	## Add a perk to the character. Returns true on success.
	if has_perk(character, perk_id):
		push_warning("PerkSystem: Character already has perk: ", perk_id)
		return false

	# Get perk data
	var perk_data: Dictionary
	if perk_id in _skill_perks:
		perk_data = _skill_perks[perk_id]
	elif perk_id in _cross_perks:
		perk_data = _cross_perks[perk_id]
	else:
		push_error("PerkSystem: Unknown perk: ", perk_id)
		return false

	# Initialize perks array if needed
	if not character.has("perks"):
		character["perks"] = []

	# Store as {id, name} for efficient lookup
	character.perks.append({
		"id": perk_id,
		"name": perk_data.get("name", perk_id)
	})

	perk_granted.emit(character, perk_id, perk_data)
	return true


func has_perk(character: Dictionary, perk_id: String) -> bool:
	## Check if a character has a specific perk.
	if not character.has("perks"):
		return false
	for perk in character.perks:
		if perk is Dictionary and perk.get("id", "") == perk_id:
			return true
		elif perk is String and perk == perk_id:
			return true
	return false


func _get_owned_perk_ids(character: Dictionary) -> Array[String]:
	## Get a list of all perk IDs the character owns.
	var ids: Array[String] = []
	if not character.has("perks"):
		return ids
	for perk in character.perks:
		if perk is Dictionary:
			ids.append(perk.get("id", ""))
		elif perk is String:
			ids.append(perk)
	return ids


func get_character_perks(character: Dictionary) -> Array[Dictionary]:
	## Get full perk data for all perks a character has.
	var result: Array[Dictionary] = []
	for perk_id in _get_owned_perk_ids(character):
		var perk_data = get_perk_data(perk_id)
		if not perk_data.is_empty():
			result.append({"id": perk_id, "data": perk_data})
	return result


func get_perk_data(perk_id: String) -> Dictionary:
	## Look up a perk by ID from either skill or cross databases.
	if perk_id in _skill_perks:
		return _skill_perks[perk_id]
	if perk_id in _cross_perks:
		return _cross_perks[perk_id]
	return {}


# ============================================
# ELEMENTAL AFFINITIES
# ============================================

func calculate_element_affinity(character: Dictionary, element: String) -> int:
	## Calculate total affinity for an element.
	## Includes skill levels in that element plus innate racial affinity bonus.
	var total := 0
	var skills = character.get("skills", {})
	var element_skill_list = _element_skills.get(element, [])

	for skill_id in element_skill_list:
		total += skills.get(skill_id, 0)

	# Add innate racial affinity (e.g. Red Devil has fire: 5 from birth)
	var racial = character.get("racial_affinity_bonuses", {})
	total += racial.get(element, 0)

	return total


func calculate_all_affinities(character: Dictionary) -> Dictionary:
	## Calculate affinities for all 5 elements.
	var affinities := {}
	for element in _element_skills:
		affinities[element] = calculate_element_affinity(character, element)
	return affinities


func get_affinity_bonuses(character: Dictionary) -> Dictionary:
	## Calculate stat bonuses from elemental affinities.
	## Bonuses scale gradually - every 5 points of affinity grants a tier.
	var bonuses := {}
	var affinities = calculate_all_affinities(character)

	# Space: +Spellpower, +Mental Resistance
	var space_aff = affinities.get("space", 0)
	if space_aff > 0:
		bonuses["spellpower"] = bonuses.get("spellpower", 0) + int(space_aff * 0.5)
		bonuses["mental_resistance_pct"] = bonuses.get("mental_resistance_pct", 0) + int(space_aff * 1.0)

	# Air: +Initiative, +Movement (at thresholds)
	var air_aff = affinities.get("air", 0)
	if air_aff > 0:
		bonuses["initiative"] = bonuses.get("initiative", 0) + int(air_aff * 0.5)
		bonuses["movement"] = bonuses.get("movement", 0) + int(air_aff / 10)  # +1 at 10, +2 at 20, etc.

	# Fire: +Damage%, +Crit Chance
	var fire_aff = affinities.get("fire", 0)
	if fire_aff > 0:
		bonuses["damage_pct"] = bonuses.get("damage_pct", 0) + int(fire_aff * 0.5)
		bonuses["crit_chance"] = bonuses.get("crit_chance", 0) + int(fire_aff * 0.3)

	# Water: +Dodge, +Healing Effectiveness%
	var water_aff = affinities.get("water", 0)
	if water_aff > 0:
		bonuses["dodge"] = bonuses.get("dodge", 0) + int(water_aff * 0.5)
		bonuses["healing_pct"] = bonuses.get("healing_pct", 0) + int(water_aff * 1.0)

	# Earth: +Max HP, +Armor
	var earth_aff = affinities.get("earth", 0)
	if earth_aff > 0:
		bonuses["max_hp"] = bonuses.get("max_hp", 0) + earth_aff * 2
		bonuses["armor"] = bonuses.get("armor", 0) + int(earth_aff * 0.5)

	return bonuses


# ============================================
# BASE SKILL BONUSES
# ============================================

func get_base_skill_bonuses(character: Dictionary, skill_id: String) -> Dictionary:
	## Get the base stat bonuses for a skill at the character's current level.
	## Returns a dict like {"attack": 86.0, "damage": 75.0} for Swords level 10.
	var level = character.get("skills", {}).get(skill_id, 0)
	if level == 0:
		return {}
	return get_base_skill_bonuses_at_level(skill_id, level)


func get_base_skill_bonuses_at_level(skill_id: String, level: int) -> Dictionary:
	## Get base stat bonuses for a skill at the specified level (1-15).
	## Level 11-15 is for item/race-enhanced display only.
	## Returns empty dict if no bonus data or level is 0.
	if level <= 0:
		return {}

	var bonus_data = _base_bonuses.get(skill_id, {})
	if bonus_data.is_empty():
		return {}

	var per_level = bonus_data.get("per_level", {})
	var clamped = mini(level, 15)  # cap at 15 (max item-enhanced range)
	return per_level.get(str(clamped), {})
