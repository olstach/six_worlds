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

# Party data - player is always index 0
var party: Array[Dictionary] = []
var max_party_size: int = 6

# Attribute costs - exponential scaling
const ATTRIBUTE_BASE_COST: int = 100
const ATTRIBUTE_COST_MULTIPLIER: float = 1.5

# Skill level costs
const SKILL_COSTS: Array[int] = [0, 100, 300, 600, 1000, 1500]  # XP cost to reach each level

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
	print("CharacterSystem initialized")
	# Create a test player character
	create_player_character("Karma Dorje", "human", "wanderer")

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
	
	print("Created player: ", character.name, " (", race, " ", background, ")")
	character_updated.emit(character)

## Apply racial attribute modifiers
func apply_race_modifiers(character: Dictionary, race: String) -> void:
	# TODO: Load from race data files
	# For now, simple examples
	match race:
		"red_devil":
			character.attributes.strength += 3
			character.attributes.finesse += 2
			character.attributes.awareness -= 2
			character.attributes.charm -= 2
		"human":
			# Humans are balanced, no modifiers
			pass
		"naga":
			character.attributes.awareness += 2
			character.attributes.charm += 2
			character.attributes.strength -= 1

## Apply background starting skills
func apply_background_skills(character: Dictionary, background: String) -> void:
	# TODO: Load from background data files
	match background:
		"wanderer":
			set_skill_level(character, "swords", 1)
			set_skill_level(character, "lore", 1)
		"scholar":
			set_skill_level(character, "focus", 2)
			set_skill_level(character, "sorcery", 1)
		"merchant":
			set_skill_level(character, "trade", 2)
			set_skill_level(character, "charm", 1)

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
func calculate_attribute_cost(current_value: int, increase_amount: int) -> int:
	var total_cost = 0
	for i in range(increase_amount):
		var level = current_value + i - 9  # Offset since base is 10
		total_cost += int(ATTRIBUTE_BASE_COST * pow(ATTRIBUTE_COST_MULTIPLIER, level))
	return total_cost

## Set skill level directly (for initialization)
func set_skill_level(character: Dictionary, skill: String, level: int) -> void:
	character.skills[skill] = level

## Upgrade a skill (costs XP based on current level)
func upgrade_skill(character: Dictionary, skill: String) -> bool:
	var current_level = character.skills.get(skill, 0)
	
	if current_level >= 5:
		return false  # Max level
	
	var cost = SKILL_COSTS[current_level + 1]
	
	if character.xp >= cost:
		character.xp -= cost
		character.skills[skill] = current_level + 1
		
		# Update elemental affinity if applicable
		# TODO: Load skill->element mappings from data
		
		skill_upgraded.emit(character, skill, current_level + 1)
		
		# Offer upgrade selection if skill reached certain levels
		if (current_level + 1) % 1 == 0:  # Every level for now
			offer_upgrade_selection(character, skill)
		
		character_updated.emit(character)
		return true
	return false

## Offer player choice of upgrades/perks
func offer_upgrade_selection(character: Dictionary, skill: String) -> void:
	# TODO: Generate 4 random upgrades based on requirements
	# For now, just emit signal
	print("Upgrade selection available for ", character.name, " - ", skill)

## Add upgrade/perk to character
func add_upgrade(character: Dictionary, upgrade: Dictionary) -> void:
	character.upgrades.append(upgrade)
	upgrade_gained.emit(character, upgrade)
	character_updated.emit(character)

## Grant XP to character
func grant_xp(character: Dictionary, amount: int) -> void:
	character.xp += amount
	print(character.name, " gained ", amount, " XP (total: ", character.xp, ")")
	character_updated.emit(character)

## Update all derived stats based on attributes and equipment
func update_derived_stats(character: Dictionary) -> void:
	var attrs = character.attributes
	var derived = character.derived

	# Get equipment bonuses from ItemSystem
	var equip_bonus: Dictionary = {}
	if ItemSystem:
		equip_bonus = ItemSystem.calculate_equipment_stats(character)

	# Apply equipment attribute bonuses first
	var effective_attrs = {}
	for attr_key in attrs:
		effective_attrs[attr_key] = attrs[attr_key] + equip_bonus.get(attr_key, 0)

	# HP from Constitution + equipment
	derived.max_hp = 100 + (effective_attrs.constitution - 10) * 10 + equip_bonus.get("max_hp", 0)
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

	# Initiative from Finesse + Awareness + equipment
	derived.initiative = effective_attrs.finesse + effective_attrs.awareness + equip_bonus.get("initiative", 0)

	# Movement from Finesse + equipment
	derived.movement = int(effective_attrs.finesse / 3) + equip_bonus.get("movement", 0)

	# Dodge from Finesse + equipment
	derived.dodge = effective_attrs.finesse + equip_bonus.get("dodge", 0)

	# Spellpower from Focus + equipment
	derived.spellpower = effective_attrs.focus + equip_bonus.get("spellpower", 0)

	# Crit chance from Awareness + Finesse + Luck + equipment
	derived.crit_chance = 5 + int((effective_attrs.awareness + effective_attrs.finesse + effective_attrs.luck) / 6) + equip_bonus.get("crit_chance", 0)

	# Weight limit from Strength
	derived.weight_limit = 100 + (effective_attrs.strength - 10) * 10

	# Combat stats from equipment
	derived.damage = equip_bonus.get("damage", 0)
	derived.armor = equip_bonus.get("armor", 0)
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
