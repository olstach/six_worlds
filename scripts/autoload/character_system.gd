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
var max_party_size: int = 8

# Race and background data loaded from JSON
var _race_data: Dictionary = {}
var _background_data: Dictionary = {}

# Spell database for random starting spell selection
var _spell_database: Dictionary = {}

# Attribute costs - tripled linear scaling (rank * 3 per step)
# 10→11 = 3 XP, 11→12 = 6 XP, ..., 19→20 = 30 XP, 29→30 = 60 XP
# 10→20 total = 165 XP, 10→30 total = 630 XP (endgame godlike, ≈ skill L10)

# Skill level costs — 10-level scale
# Index = level to reach, value = XP cost for that level
# Total to max a skill: 660 XP (vs 35 on the old 1-5 scale)
const SKILL_COSTS: Array[int] = [0, 5, 10, 18, 28, 42, 59, 80, 106, 137, 175]

# Maximum purchasable skill level (items/race can push effective level up to 15)
const SKILL_MAX_LEVEL: int = 10

# Base character template
const BASE_CHARACTER: Dictionary = {
	"name": "Unnamed",
	"race": "human",
	"background": "wanderer",
	"xp": 50,  # Starting XP — enough to pick up two skills at level 2 or dabble in several
	"xp_earned": 50,  # Lifetime total XP earned (never decreases)
	
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
		"max_mana": 50,
		"current_mana": 50,
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
		"armor_pierce": 0,
		"temp_hp": 0,            # Temporary HP from rest overheal; absorbed before real HP
		# Current resistances: racial base + equipment + permanent perk bonuses
		# In-combat spell/status bonuses are applied on top in CombatUnit.get_resistance()
		"resistances": {}
	},
	
	# Skills (level 0-10 purchasable; up to 15 with item/race bonuses)
	"skills": {},

	# Per-skill bonuses from items, race, or other sources
	# Format: {"skill_id": {"source_name": amount, ...}, ...}
	"skill_bonuses": {},

	# Innate elemental affinity from race (independent of skills)
	# Format: {"fire": 5, "water": 3, ...}
	"racial_affinity_bonuses": {},

	# Permanent racial resistances (set once at character creation from races.json)
	# Format: {"physical": 50, "fire": 25, ...}  values are percentages
	"base_resistances": {},
	
	# Elemental affinities (built up through skill usage)
	"elements": {
		"earth": 0,
		"water": 0,
		"fire": 0,
		"air": 0,
		"space": 0
	},

	# Elemental emotional pressure: -100 (deep klesha) to +100 (deep wisdom)
	"emotional_pressure": {
		"space": 0.0,
		"fire":  0.0,
		"water": 0.0,
		"earth": 0.0,
		"air":   0.0,
	},

	# Starting emotional baseline per element — copied from race data at creation.
	# PsychologySystem reads this as the resting point pressure drifts toward.
	# Future: yidam practice and karma will modify this at runtime.
	"emotional_baseline": {
		"space": 0.0,
		"fire":  0.0,
		"water": 0.0,
		"earth": 0.0,
		"air":   0.0,
	},

	# Tracks which elemental crisis events have already fired (prevents re-firing same crossing).
	# Format: {"fire_dark": true, "water_bright": true, ...}
	# Populated lazily by PsychologySystem — initialized here for save/load consistency.
	"emotional_crisis_fired": {},

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
		"trinket1": "",
		"trinket2": ""
	},

	# Active weapon set (1 or 2)
	"active_weapon_set": 1,

	# Character quirks — list of quirk IDs (see quirks.json / QuirkSystem)
	# Inborn quirks are set at character creation or in companion definitions.
	# Acquired quirks are added/removed during the run via QuirkSystem.add_quirk/remove_quirk.
	"quirks": [],

	# Persistent wounds and diseases (survive between combats; healed by Medicine or facilities)
	# Each entry: {id, body_location, rests_untreated, source}
	"wounds": [],

	# Persistent progression data
	"affinities": [],  # Skills that have reached max level in previous lives
	"persistent_upgrades": []  # Rare upgrades that survive reincarnation
}

func _ready() -> void:
	_load_race_data()
	_load_spell_database()
	print("CharacterSystem initialized with ", _race_data.size(), " races, ",
		_background_data.size(), " backgrounds, ", _spell_database.size(), " spells")


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


## Load spell definitions from spells.json for random starting spell selection
func _load_spell_database() -> void:
	var file_path = "res://resources/data/spells.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CharacterSystem: spells.json not found, random starting spells unavailable")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("CharacterSystem: Failed to parse spells.json: ", json.get_error_message())
		file.close()
		return
	file.close()
	_spell_database = json.get_data().get("spells", {})


## Pick a random spell matching any of the given schools at the given level.
## Excludes spells the character already knows to avoid duplicates.
## schools: Array of school name strings (e.g. ["Fire"] or ["Black", "Space"])
## Returns spell_id string, or "" if none found.
func _pick_random_spell(schools: Array, level: int, already_known: Array) -> String:
	var candidates: Array[String] = []
	for spell_id in _spell_database:
		if spell_id in already_known:
			continue
		var spell = _spell_database[spell_id]
		if int(spell.get("level", 0)) != level:
			continue
		var spell_schools = spell.get("schools", [])
		for required in schools:
			for s in spell_schools:
				if s.to_lower() == required.to_lower():
					candidates.append(spell_id)
					break
	if candidates.is_empty():
		return ""
	candidates.shuffle()
	return candidates[0]


## Public accessor for the spell database (used by shop system and map rewards)
func get_spell_database() -> Dictionary:
	return _spell_database


## Pick a random spell of the given school and spell level for the whole party.
## Excludes spells already known by ALL party members (so there's always someone who benefits).
## Checks both the "schools" array and the "subschool" field, so Sorcery/Enchantment/etc. work.
## Returns spell_id or "" if every matching spell is already universal knowledge.
func pick_random_spell_for_party(school: String, level: int) -> String:
	var party = get_party()
	if party.is_empty():
		return ""

	# Build set of spells known by ALL party members — we won't offer those
	var known_by_all: Array = party[0].get("known_spells", []).duplicate()
	for i in range(1, party.size()):
		var member_spells = party[i].get("known_spells", [])
		known_by_all = known_by_all.filter(func(sid): return sid in member_spells)

	var school_lower = school.to_lower()
	var candidates: Array[String] = []

	for spell_id in _spell_database:
		if spell_id in known_by_all:
			continue
		var spell = _spell_database[spell_id]
		if int(spell.get("level", 0)) != level:
			continue
		# Domain spells are only available through domain-specific trainers
		var tags = spell.get("tags", [])
		if "domain_spell" in tags:
			continue
		# Match against schools array or subschool field
		var matches = false
		for s in spell.get("schools", []):
			if s.to_lower() == school_lower:
				matches = true
				break
		if not matches and spell.get("subschool", "").to_lower() == school_lower:
			matches = true
		if matches:
			candidates.append(spell_id)

	if candidates.is_empty():
		return ""
	candidates.shuffle()
	return candidates[0]


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

	# Apply starting equipment from background (adds to inventory and equips)
	apply_background_equipment(character, background)

	# Calculate derived stats (equipment bonuses are now included)
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

	# Apply attribute modifiers
	var modifiers = data.get("attribute_modifiers", {})
	for attr_name in modifiers:
		if attr_name in character.attributes:
			character.attributes[attr_name] += int(modifiers[attr_name])

	# Apply innate elemental affinity bonuses (stored on character, added to affinity calculation)
	var affinity_bonuses = data.get("elemental_affinity_bonuses", {})
	if not affinity_bonuses.is_empty():
		character["racial_affinity_bonuses"] = affinity_bonuses.duplicate()

	# Store permanent racial resistances (merged into derived.resistances by update_derived_stats)
	var racial_resists = data.get("resistances", {})
	if not racial_resists.is_empty():
		character["base_resistances"] = racial_resists.duplicate()

	# Apply starting skills from race.
	# starting_skills may be a dict {skill_id: level} or legacy array [skill_id, ...].
	# Background skills are applied afterward and may override with higher levels.
	var race_skills = data.get("starting_skills", {})
	if race_skills is Dictionary:
		for skill_id in race_skills:
			var lvl = int(race_skills[skill_id])
			if character.skills.get(skill_id, 0) < lvl:
				set_skill_level(character, skill_id, lvl)
	else:
		# Legacy array format: give level 1 in each listed skill
		for skill_id in race_skills:
			if character.skills.get(skill_id, 0) < 1:
				set_skill_level(character, skill_id, 1)

	# Apply random starting spells from race definition.
	# Each entry: {school: "Fire", level: 1, count: 1}
	#          or {schools: ["Black","Space"], level: 1, count: 1} (picks from either school)
	var starting_spells = data.get("starting_spells", [])
	for spell_spec in starting_spells:
		var schools: Array = []
		if spell_spec.has("school"):
			schools = [spell_spec["school"]]
		elif spell_spec.has("schools"):
			schools = spell_spec["schools"]
		else:
			continue

		var level = int(spell_spec.get("level", 1))
		var count = int(spell_spec.get("count", 1))
		for _i in range(count):
			var spell_id = _pick_random_spell(schools, level, character.get("known_spells", []))
			if spell_id != "":
				learn_spell(character, spell_id)

	# Copy emotional baseline from race data
	if "emotional_baseline" in data:
		for element in data.emotional_baseline:
			if element in character.emotional_baseline:
				character.emotional_baseline[element] = float(data.emotional_baseline[element])


## Apply background starting skills and attribute tweaks from races.json backgrounds data
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

	# Apply small background attribute tweaks on top of race modifiers
	var bg_modifiers = data.get("attribute_modifiers", {})
	for attr_name in bg_modifiers:
		if attr_name in character.attributes:
			character.attributes[attr_name] += int(bg_modifiers[attr_name])

	# Apply starting skills — take the higher of race or background level
	var skills = data.get("starting_skills", {})
	for skill_id in skills:
		var level = int(skills[skill_id])
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

## Apply starting equipment from the background definition to the player character.
## Items are added to the global inventory and immediately equipped.
## Called during create_player_character() before update_derived_stats().
func apply_background_equipment(character: Dictionary, background: String) -> void:
	if not ItemSystem:
		return
	var data = get_background_data(background)
	if data.is_empty():
		return
	var equip_data: Dictionary = data.get("starting_equipment", {})
	if equip_data.is_empty():
		return

	# Main weapon: may upgrade to a better version based on a chance roll
	var main_weapon: String = equip_data.get("base_weapon", "")
	var upgrade_id: String = equip_data.get("weapon_upgrade", "")
	if upgrade_id != "" and randf() < float(equip_data.get("weapon_upgrade_chance", 0.0)):
		main_weapon = upgrade_id
	if main_weapon != "":
		_add_and_equip(character, main_weapon, "weapon_main")

	# Items list: each item goes to its natural equipment slot
	for item_id: String in equip_data.get("items", []):
		if item_id == "":
			continue
		var slot = _find_slot_for_item(character, item_id)
		_add_and_equip(character, item_id, slot)

	# Secondary weapon: equip to weapon set 2 (swap active set temporarily)
	var secondary: String = equip_data.get("secondary_weapon", "")
	if secondary != "":
		character.active_weapon_set = 2
		_add_and_equip(character, secondary, "weapon_main")
		character.active_weapon_set = 1

	# Random bonus: one item drawn from the list at the given probability
	var bonus_list: Array = equip_data.get("random_bonus", [])
	if not bonus_list.is_empty() and randf() < float(equip_data.get("bonus_chance", 0.0)):
		var bonus_id: String = bonus_list[randi() % bonus_list.size()]
		if bonus_id != "":
			var slot = _find_slot_for_item(character, bonus_id)
			_add_and_equip(character, bonus_id, slot)


## Add item_id to the global inventory then equip it to slot on character.
## If slot is empty the item is added to inventory only (player can equip manually).
func _add_and_equip(character: Dictionary, item_id: String, slot: String) -> void:
	if not ItemSystem.item_exists(item_id):
		push_warning("CharacterSystem: Unknown starting item '%s'" % item_id)
		return
	ItemSystem.add_to_inventory(item_id)
	if slot != "":
		ItemSystem.equip_item(character, item_id, slot)


## Return the first available equipment slot for item_id based on its type.
## Prefers empty slots; returns "" when no suitable slot is available.
func _find_slot_for_item(character: Dictionary, item_id: String) -> String:
	if not ItemSystem.item_exists(item_id):
		return ""
	var item_type: String = ItemSystem.get_item(item_id).get("type", "")
	var eq: Dictionary = character.get("equipment", {})
	match item_type:
		"sword", "dagger", "axe", "mace", "spear", "staff", \
		"bow", "crossbow", "javelin", "thrown", "club":
			return "weapon_main"
		"shield":
			return "weapon_off"
		"armor", "robe":
			return "chest" if eq.get("chest", "") == "" else ""
		"helmet", "hat", "circlet":
			return "head" if eq.get("head", "") == "" else ""
		"boots", "shoes", "sandals":
			return "feet" if eq.get("feet", "") == "" else ""
		"pants", "greaves", "leggings":
			return "legs" if eq.get("legs", "") == "" else ""
		"gloves", "gauntlets", "bracers":
			if eq.get("hand_l", "") == "": return "hand_l"
			if eq.get("hand_r", "") == "": return "hand_r"
			return ""
		"ring":
			if eq.get("ring1", "") == "": return "ring1"
			if eq.get("ring2", "") == "": return "ring2"
			return ""
		"amulet", "necklace", "trinket", "talisman":
			if eq.get("trinket1", "") == "": return "trinket1"
			if eq.get("trinket2", "") == "": return "trinket2"
			return ""
	return ""


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

## Calculate cost to increase attribute.
## Cost per step = rank * 3, where rank = current_value - 9.
## 10→11 costs 3, 11→12 costs 6, 20→21 costs 33, 29→30 costs 60.
## Cumulative from 10: value 20 = 165 XP (≈ skill L6), value 30 = 630 XP (≈ skill L10).
## Floor of 2 ensures attributes below 10 (racial penalties) still cost something.
func calculate_attribute_cost(current_value: int, increase_amount: int) -> int:
	var total_cost = 0
	for i in range(increase_amount):
		# rank * 3, minimum 2 (handles attributes below 10 from racial modifiers)
		total_cost += maxi((current_value + i - 9) * 3, 2)
	return total_cost

## Set skill level directly (for initialization)
func set_skill_level(character: Dictionary, skill: String, level: int) -> void:
	character.skills[skill] = level

## Upgrade a skill (costs XP based on current level)
## Returns true if the skill was upgraded. Emits perk_selection_requested
## with 4 random eligible perks for the UI to display.
func upgrade_skill(character: Dictionary, skill: String) -> bool:
	var current_level = character.skills.get(skill, 0)

	if current_level >= SKILL_MAX_LEVEL:
		return false  # Max level

	var cost = SKILL_COSTS[current_level + 1]

	if character.xp >= cost:
		character.xp -= cost
		character.skills[skill] = current_level + 1

		# Update elemental affinity on the character dict
		_update_element_affinities(character)

		skill_upgraded.emit(character, skill, current_level + 1)

		# Offer perk selection (4 random eligible perks, weighted toward the upgraded skill)
		offer_perk_selection(character, skill)

		update_derived_stats(character)
		character_updated.emit(character)
		return true
	return false

## Get effective skill level including item/race bonuses (capped at 15 for display).
## Returns the effective skill level for a character including all bonuses
## from quirks, equipment, and race. Clamped to [0, 15].
## skill_bonuses format: {"skill_id": {"source_name": amount, ...}, ...}
func get_effective_skill_level(character: Dictionary, skill_id: String) -> int:
	var base = character.get("skills", {}).get(skill_id, 0)
	var bonus_sources = character.get("skill_bonuses", {}).get(skill_id, {})
	var bonus = 0
	for source in bonus_sources:
		bonus += int(bonus_sources[source])
	return clampi(base + bonus, 0, 15)


## Update the character's element affinity totals from their skill levels.
func _update_element_affinities(character: Dictionary) -> void:
	if not PerkSystem:
		return
	var affinities = PerkSystem.calculate_all_affinities(character)
	for element in affinities:
		character.elements[element] = affinities[element]

## Offer player choice of perks after a skill level-up.
## Gets 4 random eligible perks from PerkSystem and emits a signal for the UI.
## last_skill: the skill just upgraded — perks for it appear with higher weight.
func offer_perk_selection(character: Dictionary, last_skill: String = "") -> void:
	if not PerkSystem:
		push_warning("CharacterSystem: PerkSystem not available")
		return

	var selection = PerkSystem.get_perk_selection(character, PerkSystem.PERKS_OFFERED, last_skill)
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
	character.xp_earned = character.get("xp_earned", 0) + amount
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

	# Collect quirk attribute bonuses
	var quirk_attr_bonus: Dictionary = {}
	if QuirkSystem:
		quirk_attr_bonus = QuirkSystem.get_attribute_bonus(character)

	# Apply equipment + quirk attribute bonuses to get effective attributes
	var effective_attrs = {}
	for attr_key in attrs:
		effective_attrs[attr_key] = attrs[attr_key] + equip_bonus.get(attr_key, 0) + quirk_attr_bonus.get(attr_key, 0)

	# Refresh quirk skill bonuses (clear old pass first, then re-add from current quirks)
	if not "skill_bonuses" in character:
		character["skill_bonuses"] = {}
	for skill_id in character["skill_bonuses"]:
		character["skill_bonuses"][skill_id].erase("quirks")
	if QuirkSystem:
		for quirk_id in character.get("quirks", []):
			var q := QuirkSystem.get_quirk(quirk_id)
			for skill_id in q.get("skill_modifiers", {}):
				if not skill_id in character["skill_bonuses"]:
					character["skill_bonuses"][skill_id] = {}
				var prev: int = character["skill_bonuses"][skill_id].get("quirks", 0)
				character["skill_bonuses"][skill_id]["quirks"] = prev + int(q["skill_modifiers"][skill_id])

	# HP from Constitution + equipment + earth affinity
	var old_max_hp = derived.get("max_hp", 100)
	derived.max_hp = 100 + (effective_attrs.constitution - 10) * 10 + equip_bonus.get("max_hp", 0) + affinity_bonus.get("max_hp", 0)
	# When max HP increases, increase current HP by the same amount
	if derived.max_hp > old_max_hp:
		derived.current_hp = derived.get("current_hp", derived.max_hp) + (derived.max_hp - old_max_hp)
	derived.current_hp = min(derived.get("current_hp", derived.max_hp), derived.max_hp)

	# Mana from Awareness + equipment
	var old_max_mana = derived.get("max_mana", 100)
	derived.max_mana = 50 + (effective_attrs.awareness - 10) * 10 + equip_bonus.get("max_mana", 0)
	if derived.max_mana > old_max_mana:
		derived.current_mana = derived.get("current_mana", derived.max_mana) + (derived.max_mana - old_max_mana)
	derived.current_mana = min(derived.get("current_mana", derived.max_mana), derived.max_mana)

	# Stamina from Constitution + Finesse + equipment
	var old_max_stamina = derived.get("max_stamina", 50)
	derived.max_stamina = 50 + int((effective_attrs.constitution + effective_attrs.finesse - 20) * 2.5) + equip_bonus.get("max_stamina", 0)
	if not "current_stamina" in derived:
		derived.current_stamina = derived.max_stamina
	else:
		if derived.max_stamina > old_max_stamina:
			derived.current_stamina += (derived.max_stamina - old_max_stamina)
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

	# Build current resistances: start from permanent racial base, add equipment bonuses
	var new_resists: Dictionary = character.get("base_resistances", {}).duplicate()
	var equip_resists = equip_bonus.get("resistances", {})
	for r in equip_resists:
		new_resists[r] = new_resists.get(r, 0) + equip_resists[r]
	derived["resistances"] = new_resists

	# Apply base skill bonuses from PerkSystem (data-driven per_level tables)
	# Each skill contributes its cumulative bonuses at the character's effective level.
	if PerkSystem:
		var all_skills = character.get("skills", {})
		for skill_id in all_skills:
			var effective_level = get_effective_skill_level(character, skill_id)
			if effective_level == 0:
				continue
			var bonus = PerkSystem.get_base_skill_bonuses_at_level(skill_id, effective_level)
			if bonus.is_empty():
				continue
			# Combat skill bonuses
			derived["accuracy"] = derived.get("accuracy", 0) + bonus.get("attack", 0)
			derived["damage"] = derived.get("damage", 0) + bonus.get("damage", 0)
			derived["crit_chance"] = derived.get("crit_chance", 0.0) + bonus.get("crit_chance", 0.0)
			derived["armor"] = derived.get("armor", 0) + bonus.get("armor_bonus", 0)
			derived["armor_pierce"] = derived.get("armor_pierce", 0) + bonus.get("armor_penetration", 0)
			# Armor skill: damage reduction
			if bonus.has("damage_reduction_pct"):
				derived["damage_reduction_pct"] = derived.get("damage_reduction_pct", 0.0) + bonus.get("damage_reduction_pct", 0.0)
			# Magic school bonuses
			if bonus.has("spellpower"):
				derived["spellpower"] = derived.get("spellpower", 0) + int(bonus.get("spellpower", 0))
			# General skill bonuses that directly affect derived stats
			if bonus.has("dodge_bonus"):
				derived["dodge"] = derived.get("dodge", 0) + int(bonus.get("dodge_bonus", 0))
			if bonus.has("max_stamina"):
				derived["max_stamina"] = derived.get("max_stamina", 50) + int(bonus.get("max_stamina", 0))
			if bonus.has("initiative_bonus"):
				derived["initiative"] = derived.get("initiative", 0) + int(bonus.get("initiative_bonus", 0))

	# Apply active map buffs from simples/shrines.
	# Attribute-type buffs translate to their most direct derived-stat effects
	# (we don't modify attributes themselves to avoid HP/mana tracking confusion).
	if GameState:
		for buf in GameState.active_map_buffs:
			var stat: String = buf.get("stat", "")
			var amount = buf.get("amount", 0)
			match stat:
				"strength":
					derived["damage"] = derived.get("damage", 0) + amount
					derived["max_stamina"] = derived.get("max_stamina", 50) + amount
				"constitution":
					derived["max_stamina"] = derived.get("max_stamina", 50) + amount * 2
				"finesse":
					derived["dodge"] = derived.get("dodge", 0) + amount
					derived["initiative"] = derived.get("initiative", 0) + amount
				"focus":
					derived["spellpower"] = derived.get("spellpower", 0) + amount
				"awareness":
					derived["initiative"] = derived.get("initiative", 0) + amount
					derived["crit_chance"] = derived.get("crit_chance", 0.0) + amount * 0.5
				"charm":
					pass  # future: social/event roll bonuses
				"luck":
					derived["crit_chance"] = derived.get("crit_chance", 0.0) + amount
				"spellpower_fire":
					derived["spellpower_fire"] = derived.get("spellpower_fire", 0) + amount
				"initiative":
					derived["initiative"] = derived.get("initiative", 0) + amount
				"loot_chance_pct":
					derived["loot_chance_pct"] = derived.get("loot_chance_pct", 0) + amount
				"xp_gain_pct":
					derived["xp_gain_pct"] = derived.get("xp_gain_pct", 0) + amount
				"accuracy":
					derived["accuracy"] = derived.get("accuracy", 0) + amount
			# Handle *_resistance map buffs generically (match doesn't support wildcards)
			if stat.ends_with("_resistance"):
				var element = stat.replace("_resistance", "")
				derived["resistances"][element] = derived["resistances"].get(element, 0) + amount

	# Apply persistent wound/disease stat penalties (percentage-based, multiplicative).
	# get_stat_penalties returns e.g. {"dodge": -25, "max_hp": -20} meaning -25%, -20%.
	if WoundSystem and not character.get("wounds", []).is_empty():
		var wound_penalties := WoundSystem.get_stat_penalties(character)
		for stat in wound_penalties:
			var base_val: float = float(derived.get(stat, 0))
			derived[stat] = int(base_val * (1.0 + float(wound_penalties[stat]) / 100.0))
		# Clamp current values into the (possibly reduced) maxima
		derived.current_hp = min(derived.get("current_hp", derived.max_hp), derived.max_hp)
		derived.current_stamina = min(derived.get("current_stamina", derived.max_stamina), derived.max_stamina)

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


# ============================================
# SAVE / LOAD
# ============================================

## Collect saveable state into a dictionary
func get_save_data() -> Dictionary:
	# Deep copy party data so we don't reference live objects.
	# duplicate(true) copies the entire character dict, including any fields that
	# are not part of BASE_CHARACTER — companion-specific fields (companion_id,
	# flavor_text, portrait, build_weights, autodevelop, free_xp,
	# overflow_investments, overflow_popup_shown) are therefore preserved
	# automatically with no extra handling needed here.
	var party_copy: Array = []
	for character in party:
		party_copy.append(character.duplicate(true))
	return {
		"party": party_copy
	}


## Restore state from a save dictionary
func load_save_data(data: Dictionary) -> void:
	party.clear()
	var saved_party = data.get("party", [])
	for char_data in saved_party:
		# Ensure it's a proper Dictionary (JSON parse gives untyped).
		# We copy every key rather than reconstructing via create_character(),
		# so companion-specific fields (companion_id, flavor_text, portrait,
		# build_weights, autodevelop, free_xp, overflow_investments,
		# overflow_popup_shown) come back intact.  No whitelist is used.
		var character: Dictionary = {}
		for key in char_data:
			character[key] = char_data[key]
		# Recalculate derived stats to pick up any formula changes
		update_derived_stats(character)
		party.append(character)
