extends Node
## CharacterSystem - Manages character attributes, skills, upgrades, and party
##
## This singleton handles:
## - Player character and party members
## - Attribute and skill progression
## - Equipment and inventory
## - Upgrade/perk selection

# Signals for UI updates
signal character_updated(character_data: Dictionary)
signal skill_upgraded(character_data: Dictionary, skill_name: String, new_level: int)
signal attribute_increased(character_data: Dictionary, attribute_name: String, new_value: int)
signal upgrade_gained(character_data: Dictionary, upgrade_data: Dictionary)
signal spell_learned(character_data: Dictionary, spell_id: String)
signal perk_selection_requested(character_data: Dictionary, perks: Array)

# Party data - player is always index 0
var party: Array[Dictionary] = []
var max_party_size: int = 6

# Race and background data loaded from JSON
var _race_data: Dictionary = {}
var _background_data: Dictionary = {}

# Attribute costs - linear scaling
# Each point above 10 costs its rank: 10→11 = 1 XP, 11→12 = 2 XP, etc.

# Skill level costs - triangular numbers
# Level 1 costs 1, level 2 costs 3, level 3 costs 6, level 4 costs 10, level 5 costs 15
const SKILL_COSTS: Array[int] = [0, 1, 3, 6, 10, 15]  # XP cost to reach each level

# Base character template
const BASE_CHARACTER: Dictionary = {
	"name": "Unnamed",
	"race": "human",
	"background": "wanderer",
	"xp": 0,
	
	# Core attributes (start at 10)
	"attributes": {
		"strength": 10,
		"finesse": 10,
		"constitution": 10,
		"focus": 10,
		"awareness": 10,
		"charm": 10,
		"luck": 10
	},
	
	# Derived stats (calculated from attributes and equipment)
	"derived": {
		"max_hp": 100,
		"current_hp": 100,
		"max_mana": 100,
		"current_mana": 100,
		"max_stamina": 50,
		"current_stamina": 50,
		"initiative": 20,
		"movement": 3,
		"dodge": 10,
		"spellpower": 10,
		"crit_chance": 5,
		"weight_limit": 100,
		"damage": 0,
		"armor": 0,
		"accuracy": 0,
		"armor_pierce": 0
	},
	
	# Skills (level 0-5)
	"skills": {},
	
	# Elemental affinities (built up through skill usage)
	"elements": {
		"earth": 0,
		"water": 0,
		"fire": 0,
		"air": 0,
		"space": 0
	},
	
	# Upgrades/perks gained
	"upgrades": [],

	# Perks from skill progression (perk IDs with names)
	"perks": [],

	# Known spells (spell IDs the character has learned)
	"known_spells": [],

	# Equipment slots (12-slot system with weapon sets)
	"equipment": {
		"head": "",
		"chest": "",
		"hand_l": "",
		"hand_r": "",
		"legs": "",
		"feet": "",
		"weapon_set_1": {"main": "", "off": ""},
		"weapon_set_2": {"main": "", "off": ""},
		"ring1": "",
		"ring2": "",
		"amulet": "",
		"trinket": ""
	},

	# Active weapon set (1 or 2)
	"active_weapon_set": 1,
	
	# Persistent progression data
	"affinities": [],  # Skills that have reached max level in previous lives
	"persistent_upgrades": []  # Rare upgrades that survive reincarnation
}

func _ready() -> void:
	_load_race_data()
	print("CharacterSystem initialized with ", _race_data.size(), " races, ", _background_data.size(), " backgrounds")
	# Create a test player character
	create_player_character("Karma Dorje", "human", "wanderer")


## Load race and background definitions from JSON
func _load_race_data() -> void:
	var file_path = "res://resources/data/races.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CharacterSystem: races.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("CharacterSystem: Failed to open races.json")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("CharacterSystem: Failed to parse races.json - ", json.get_error_message())
		return

	var data = json.get_data()
	_race_data = data.get("races", {})
	_background_data = data.get("backgrounds", {})


## Get race data dictionary for a given race ID
func get_race_data(race_id: String) -> Dictionary:
	return _race_data.get(race_id, {})


## Get background data dictionary for a given background ID
func get_background_data(background_id: String) -> Dictionary:
	return _background_data.get(background_id, {})

## Create the player character
func create_player_character(char_name: String, race: String, background: String) -> void:
	var character = BASE_CHARACTER.duplicate(true)
	character.name = char_name
	character.race = race
	character.background = background
	
	# Apply race modifiers (will expand with race data)
	apply_race_modifiers(character, race)
	
	# Apply background starting skills (will expand with background data)
	apply_background_skills(character, background)
	
	# Calculate derived stats
	update_derived_stats(character)
	
	# Add to party at index 0 (player always first)
	if party.is_empty():
		party.append(character)
	else:
		party[0] = character
	
	character_updated.emit(character)


## Start a new life after reincarnation.
## Preserves persistent data (affinities, upgrades) from the old character.
## Clears party, inventory, gold and creates a fresh character.
func start_new_life(char_name: String, race: String, background: String) -> void:
	# Save persistent data from old player before wiping
	var old_player = get_player()
	var old_affinities: Array = []
	var old_upgrades: Array = []
	if not old_player.is_empty():
		old_affinities = old_player.get("affinities", []).duplicate()
		old_upgrades = old_player.get("persistent_upgrades", []).duplicate()

	# Clear party and inventory
	party.clear()
	ItemSystem.clear_inventory()

	# Create the new character
	create_player_character(char_name, race, background)

	# Restore persistent progression
	var new_player = get_player()
	new_player["affinities"] = old_affinities
	new_player["persistent_upgrades"] = old_upgrades



## Apply racial attribute modifiers from races.json data
func apply_race_modifiers(character: Dictionary, race: String) -> void:
	var data = get_race_data(race)
	if data.is_empty():
		return

	var modifiers = data.get("attribute_modifiers", {})
	for attr_name in modifiers:
		if attr_name in character.attributes:
			character.attributes[attr_name] += int(modifiers[attr_name])

	# Apply starting skills from race (level 1 each, unless background overrides)
	var race_skills = data.get("starting_skills", [])
	for skill_id in race_skills:
		if character.skills.get(skill_id, 0) < 1:
			set_skill_level(character, skill_id, 1)


## Apply background starting skills from races.json backgrounds data
func apply_background_skills(character: Dictionary, background: String) -> void:
	var data = get_background_data(background)
	if data.is_empty():
		# No background data in JSON yet — use fallback starting skills/spells
		# TODO: Replace with proper background data files per background
		set_skill_level(character, "swords", 1)
		set_skill_level(character, "learning", 1)
		set_skill_level(character, "fire_magic", 2)
		set_skill_level(character, "sorcery", 2)
		set_skill_level(character, "white_magic", 1)
		set_skill_level(character, "black_magic", 1)
		learn_spell(character, "firebolt")
		learn_spell(character, "lesser_heal")
		return

	var skills = data.get("starting_skills", {})
	for skill_id in skills:
		var level = int(skills[skill_id])
		# Set to whichever is higher: race skill or background skill
		if level > character.skills.get(skill_id, 0):
			set_skill_level(character, skill_id, level)

	# Learn starting spells from background data, or defaults if none specified
	var starting_spells = data.get("starting_spells", [])
	if starting_spells.is_empty():
		learn_spell(character, "firebolt")
		learn_spell(character, "lesser_heal")
	else:
		for spell_id in starting_spells:
			learn_spell(character, spell_id)

## Increase an attribute (costs XP, exponential scaling)
func increase_attribute(character: Dictionary, attribute: String, amount: int = 1) -> bool:
	if attribute not in character.attributes:
		return false
	
	var current_value = character.attributes[attribute]
	var cost = calculate_attribute_cost(current_value, amount)
	
	if character.xp >= cost:
		character.xp -= cost
		character.attributes[attribute] += amount
		update_derived_stats(character)
		attribute_increased.emit(character, attribute, character.attributes[attribute])
		character_updated.emit(character)
		return true
	return false

## Calculate cost to increase attribute
## Each point above 10 costs its rank: 10→11 = 1, 11→12 = 2, 12→13 = 3, etc.
func calculate_attribute_cost(current_value: int, increase_amount: int) -> int:
	var total_cost = 0
	for i in range(increase_amount):
		# Cost = current_value + i - 9 (so value 10→11 costs 1, 11→12 costs 2, etc.)
		total_cost += maxi(current_value + i - 9, 1)
	return total_cost

## Set skill level directly (for initialization)
func set_skill_level(character: Dictionary, skill: String, level: int) -> void:
	character.skills[skill] = level

## Upgrade a skill (costs XP based on current level)
## Returns true if the skill was upgraded. Emits perk_selection_requested
## with 4 random eligible perks for the UI to display.
func upgrade_skill(character: Dictionary, skill: String) -> bool:
	var current_level = character.skills.get(skill, 0)

	if current_level >= 5:
		return false  # Max level

	var cost = SKILL_COSTS[current_level + 1]

	if character.xp >= cost:
		character.xp -= cost
		character.skills[skill] = current_level + 1

		# Update elemental affinity on the character dict
		_update_element_affinities(character)

		skill_upgraded.emit(character, skill, current_level + 1)

		# Offer perk selection (4 random eligible perks)
		offer_perk_selection(character)

		update_derived_stats(character)
		character_updated.emit(character)
		return true
	return false

## Update the character's element affinity totals from their skill levels.
func _update_element_affinities(character: Dictionary) -> void:
	if not PerkSystem:
		return
	var affinities = PerkSystem.calculate_all_affinities(character)
	for element in affinities:
		character.elements[element] = affinities[element]

## Offer player choice of perks after a skill level-up.
## Gets 4 random eligible perks from PerkSystem and emits a signal for the UI.
func offer_perk_selection(character: Dictionary) -> void:
	if not PerkSystem:
		push_warning("CharacterSystem: PerkSystem not available")
		return

	var selection = PerkSystem.get_perk_selection(character)
	if selection.is_empty():
		return

	perk_selection_requested.emit(character, selection)

## Add upgrade/perk to character
func add_upgrade(character: Dictionary, upgrade: Dictionary) -> void:
	character.upgrades.append(upgrade)
	upgrade_gained.emit(character, upgrade)
	character_updated.emit(character)

## Grant XP to character
func grant_xp(character: Dictionary, amount: int) -> void:
	character.xp += amount
	character_updated.emit(character)


# ============================================
# SPELLBOOK MANAGEMENT
# ============================================

## Learn a spell (add to known_spells)
func learn_spell(character: Dictionary, spell_id: String) -> bool:
	if not "known_spells" in character:
		character["known_spells"] = []

	# Check if already known
	if spell_id in character.known_spells:
		return false

	character.known_spells.append(spell_id)
	spell_learned.emit(character, spell_id)
	character_updated.emit(character)
	return true


## Forget a spell (remove from known_spells)
func forget_spell(character: Dictionary, spell_id: String) -> bool:
	if not "known_spells" in character:
		return false

	var idx = character.known_spells.find(spell_id)
	if idx == -1:
		return false

	character.known_spells.remove_at(idx)
	character_updated.emit(character)
	return true


## Check if character knows a spell
func knows_spell(character: Dictionary, spell_id: String) -> bool:
	if not "known_spells" in character:
		return false
	return spell_id in character.known_spells


## Get all known spells for a character
func get_known_spells(character: Dictionary) -> Array:
	if not "known_spells" in character:
		return []
	return character.known_spells


## Update all derived stats based on attributes, equipment, and affinity bonuses
func update_derived_stats(character: Dictionary) -> void:
	var attrs = character.attributes
	var derived = character.derived

	# Get equipment bonuses from ItemSystem
	var equip_bonus: Dictionary = {}
	if ItemSystem:
		equip_bonus = ItemSystem.calculate_equipment_stats(character)

	# Get elemental affinity bonuses from PerkSystem
	var affinity_bonus: Dictionary = {}
	if PerkSystem:
		affinity_bonus = PerkSystem.get_affinity_bonuses(character)

	# Apply equipment attribute bonuses first
	var effective_attrs = {}
	for attr_key in attrs:
		effective_attrs[attr_key] = attrs[attr_key] + equip_bonus.get(attr_key, 0)

	# HP from Constitution + equipment + earth affinity
	derived.max_hp = 100 + (effective_attrs.constitution - 10) * 10 + equip_bonus.get("max_hp", 0) + affinity_bonus.get("max_hp", 0)
	derived.current_hp = min(derived.current_hp, derived.max_hp)

	# Mana from Awareness + equipment
	derived.max_mana = 100 + (effective_attrs.awareness - 10) * 10 + equip_bonus.get("max_mana", 0)
	derived.current_mana = min(derived.current_mana, derived.max_mana)

	# Stamina from Constitution + Finesse + equipment
	derived.max_stamina = 50 + int((effective_attrs.constitution + effective_attrs.finesse - 20) * 2.5) + equip_bonus.get("max_stamina", 0)
	if not "current_stamina" in derived:
		derived.current_stamina = derived.max_stamina
	else:
		derived.current_stamina = min(derived.current_stamina, derived.max_stamina)

	# Initiative from Finesse + Awareness + equipment + air affinity
	derived.initiative = effective_attrs.finesse + effective_attrs.awareness + equip_bonus.get("initiative", 0) + affinity_bonus.get("initiative", 0)

	# Movement from Finesse + equipment + air affinity
	derived.movement = int(effective_attrs.finesse / 3) + equip_bonus.get("movement", 0) + affinity_bonus.get("movement", 0)

	# Dodge from Finesse + equipment + water affinity
	derived.dodge = effective_attrs.finesse + equip_bonus.get("dodge", 0) + affinity_bonus.get("dodge", 0)

	# Spellpower from Focus + equipment + space affinity
	derived.spellpower = effective_attrs.focus + equip_bonus.get("spellpower", 0) + affinity_bonus.get("spellpower", 0)

	# Crit chance from Awareness + Finesse + Luck + equipment + fire affinity
	derived.crit_chance = 5 + int((effective_attrs.awareness + effective_attrs.finesse + effective_attrs.luck) / 6) + equip_bonus.get("crit_chance", 0) + affinity_bonus.get("crit_chance", 0)

	# Weight limit from Strength
	derived.weight_limit = 100 + (effective_attrs.strength - 10) * 10

	# Combat stats from equipment + earth affinity
	derived.damage = equip_bonus.get("damage", 0)
	derived.armor = equip_bonus.get("armor", 0) + affinity_bonus.get("armor", 0)
	derived.accuracy = equip_bonus.get("accuracy", 0)
	derived.armor_pierce = equip_bonus.get("armor_pierce", 0)

## Get player character
func get_player() -> Dictionary:
	if party.is_empty():
		return {}
	return party[0]

## Add companion to party
func add_companion(character: Dictionary) -> bool:
	if party.size() >= max_party_size:
		return false
	party.append(character)
	print("Added companion: ", character.name)
	return true

## Remove companion from party
func remove_companion(index: int) -> bool:
	if index <= 0 or index >= party.size():
		return false
	party.remove_at(index)
	return true

## Get all party members
func get_party() -> Array[Dictionary]:
	return party
