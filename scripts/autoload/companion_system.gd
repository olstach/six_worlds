extends Node
## CompanionSystem — Loads companion definitions and handles recruitment.

signal companion_recruited(companion: Dictionary)
signal companion_overflow(companion: Dictionary)  # All build_weights maxed

const ATTR_NAMES := ["strength", "finesse", "constitution", "focus", "awareness", "charm", "luck"]
const ATTR_HARD_CAP := 30

var _companion_data: Dictionary = {}

func _ready() -> void:
	_load_companion_data()
	print("CompanionSystem: loaded ", _companion_data.size(), " companions")


func _load_companion_data() -> void:
	var path = "res://resources/data/companions.json"
	if not FileAccess.file_exists(path):
		push_warning("CompanionSystem: companions.json not found")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CompanionSystem: Failed to open companions.json")
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("CompanionSystem: Failed to parse companions.json: ", json.get_error_message())
		file.close()
		return
	file.close()
	_companion_data = json.get_data().get("companions", {})


## Returns the raw definition dict for a companion id, or {} if not found.
func get_definition(companion_id: String) -> Dictionary:
	return _companion_data.get(companion_id, {})


## Returns all companion definitions.
func get_all_definitions() -> Dictionary:
	return _companion_data


## Returns total XP already spent by a character on attributes and skills.
func _calculate_spent_xp(character: Dictionary) -> int:
	var total := 0
	for attr in character.get("attributes", {}).keys():
		var val: int = character.attributes[attr]
		for v in range(10, val):
			total += maxi(int((v - 9) * 3), 2)
	for skill in character.get("skills", {}).keys():
		var level: int = character.skills[skill]
		for l in range(1, level + 1):
			if l < CharacterSystem.SKILL_COSTS.size():
				total += CharacterSystem.SKILL_COSTS[l]
	return total


## Try to spend up to `budget` XP on one attribute. Returns XP actually spent.
func _spend_on_attribute(character: Dictionary, attr: String, budget: int) -> int:
	var spent := 0
	while spent < budget:
		var current: int = character.attributes.get(attr, 10)
		if current >= ATTR_HARD_CAP:
			break
		var cost := maxi(int((current - 9) * 3), 2)
		if spent + cost > budget:
			break
		character.attributes[attr] = current + 1
		spent += cost
	return spent


## Try to spend up to `budget` XP on one skill. Returns XP actually spent.
func _spend_on_skill(character: Dictionary, skill: String, budget: int) -> int:
	var spent := 0
	while spent < budget:
		var current: int = character.get("skills", {}).get(skill, 0)
		var next_level := current + 1
		if next_level > CharacterSystem.SKILL_MAX_LEVEL:
			break
		var cost: int = CharacterSystem.SKILL_COSTS[next_level]
		if spent + cost > budget:
			break
		character.skills[skill] = next_level
		spent += cost
	return spent


## Distribute `budget` XP among stats according to weights.
## Weights are any positive numbers — normalised internally.
## Capped stats have their surplus redistributed proportionally.
func _auto_distribute(character: Dictionary, budget: int, weights: Dictionary) -> void:
	if weights.is_empty() or budget <= 0:
		return

	var active: Dictionary = {}
	for key in weights:
		if weights[key] > 0:
			active[key] = float(weights[key])

	var remaining := budget
	var max_passes := 30

	for _pass in range(max_passes):
		if remaining <= 0 or active.is_empty():
			break

		var total_w := 0.0
		for w in active.values():
			total_w += w

		var spent_this_pass := 0
		var capped: Array[String] = []

		for key in active.keys():
			var alloc := int(float(remaining) * active[key] / total_w)
			if alloc <= 0:
				continue
			var actually_spent := 0
			if key in ATTR_NAMES:
				actually_spent = _spend_on_attribute(character, key, alloc)
			else:
				actually_spent = _spend_on_skill(character, key, alloc)
			spent_this_pass += actually_spent
			if actually_spent < alloc:
				capped.append(key)

		for key in capped:
			active.erase(key)

		remaining -= spent_this_pass

		if spent_this_pass == 0:
			break


## Map a power budget to an item rarity tier.
func _power_to_rarity(power: int) -> String:
	if power < 100: return "common"
	if power < 300: return "uncommon"
	if power < 600: return "rare"
	return "epic"


## Apply a fixed starter block (skills and known_spells) directly onto the character.
## Fixed skills override whatever the auto-distributor already set.
func _apply_fixed_starter(character: Dictionary, starter: Dictionary) -> void:
	for skill in starter.get("skills", {}).keys():
		character.skills[skill] = starter.skills[skill]
	for spell_id in starter.get("known_spells", []):
		if not spell_id in character.known_spells:
			character.known_spells.append(spell_id)


## Pick random spells from schools weighted by the companion's build_weights.
## random_cfg must contain at least {"count": N}.
func _apply_random_spells(character: Dictionary, random_cfg: Dictionary,
		build_weights: Dictionary) -> void:
	var count: int = random_cfg.get("count", 0)
	if count <= 0:
		return

	const SKILL_TO_SCHOOL := {
		"space_magic": "Space", "air_magic": "Air", "fire_magic": "Fire",
		"water_magic": "Water", "earth_magic": "Earth",
		"white_magic": "White", "black_magic": "Black",
		"sorcery": "Sorcery", "enchantment": "Enchantment",
		"summoning": "Summoning"
	}

	# Build a weighted pool of schools based on build weights
	var school_pool: Array[String] = []
	for skill in build_weights.keys():
		if skill in SKILL_TO_SCHOOL:
			var school := SKILL_TO_SCHOOL[skill]
			var weight: int = int(build_weights[skill])
			for _i in range(weight):
				school_pool.append(school)

	if school_pool.is_empty():
		return

	var spell_db: Dictionary = CharacterSystem._spell_database
	var candidates: Array[String] = []

	for spell_id in spell_db.keys():
		var spell: Dictionary = spell_db[spell_id]
		if spell_id in character.known_spells:
			continue
		var schools: Array = spell.get("schools", [])
		# Check if any spell school is in our pool
		var school_match := false
		for s in schools:
			if s in school_pool:
				school_match = true
				break
		if not school_match:
			continue
		# Check that the character can actually cast it (has the required skill level)
		var required_level: int = spell.get("level", 1)
		var can_cast := false
		for s in schools:
			for skill_name in SKILL_TO_SCHOOL.keys():
				if SKILL_TO_SCHOOL[skill_name] == s:
					if character.skills.get(skill_name, 0) >= required_level:
						can_cast = true
						break
		if can_cast:
			candidates.append(spell_id)

	candidates.shuffle()
	var picked := 0
	for spell_id in candidates:
		if picked >= count:
			break
		character.known_spells.append(spell_id)
		picked += 1


## Apply fixed and procedural equipment to the companion.
## fixed_equip slots are always applied as-is.
## starting_equip slots generate items via ItemSystem at the given rarity.
func _apply_starting_equipment(character: Dictionary, fixed_equip: Dictionary,
		starting_equip: Dictionary, rarity: String) -> void:
	const WEAPON_SLOTS := ["weapon_set_1", "weapon_set_2"]
	const ARMOR_SLOTS := ["head", "chest", "legs", "feet", "hand_l", "hand_r"]

	# Fixed equipment — applied as-is
	for slot in fixed_equip.keys():
		var slot_data = fixed_equip[slot]
		if typeof(slot_data) == TYPE_DICTIONARY:
			character.equipment[slot] = slot_data.duplicate()
		elif typeof(slot_data) == TYPE_STRING and slot_data != "":
			character.equipment[slot] = slot_data

	# Procedural equipment — skip if slot already filled by fixed_equip
	for slot in starting_equip.keys():
		if slot in fixed_equip and not (fixed_equip[slot] is Dictionary and fixed_equip[slot].is_empty()):
			continue
		var type_data = starting_equip[slot]
		if slot in WEAPON_SLOTS:
			var main_type: String = type_data.get("main", "")
			var off_type: String = type_data.get("off", "")
			var set_data := {"main": "", "off": ""}
			if main_type != "":
				set_data.main = ItemSystem.generate_weapon(main_type, rarity)
			if off_type != "":
				set_data.off = ItemSystem.generate_weapon(off_type, rarity)
			character.equipment[slot] = set_data
		elif slot in ARMOR_SLOTS:
			var armor_type: String = type_data if typeof(type_data) == TYPE_STRING else ""
			if armor_type != "":
				character.equipment[slot] = ItemSystem.generate_armor(armor_type, rarity)


## Recruit a companion by id. Deducts gold, builds and stats the character,
## and adds them to the party. Returns the new companion dict, or {} on failure.
func recruit(companion_id: String) -> Dictionary:
	var def: Dictionary = get_definition(companion_id)
	if def.is_empty():
		push_error("CompanionSystem: Unknown companion id: ", companion_id)
		return {}

	var cost: int = def.get("recruitment_cost", 0)
	if GameState.party_gold < cost:
		push_warning("CompanionSystem: Cannot afford companion ", companion_id)
		return {}

	# 1. Fresh character — deep copy BASE_CHARACTER
	var companion: Dictionary = CharacterSystem.BASE_CHARACTER.duplicate(true)
	companion.attributes = companion.attributes.duplicate()
	companion.derived = companion.derived.duplicate()
	companion.equipment = companion.equipment.duplicate(true)
	companion.skills = {}
	companion.known_spells = []
	companion.perks = []
	companion.upgrades = []

	# 2. Identity
	companion.name = def.get("name", "Companion")
	companion.race = def.get("race", "human")
	companion.background = def.get("background", "wanderer")

	# 3. Race and background
	CharacterSystem.apply_race_modifiers(companion, companion.race)
	CharacterSystem.apply_background_skills(companion, companion.background)

	# 4. Companion-specific fields
	companion["companion_id"] = companion_id
	companion["flavor_text"] = def.get("flavor_text", "")
	companion["portrait"] = def.get("portrait", "")
	companion["build_weights"] = def.get("build_weights", {}).duplicate()
	companion["autodevelop"] = false
	companion["free_xp"] = 0
	companion["overflow_investments"] = {}

	# 5. Fixed starter skills/spells
	_apply_fixed_starter(companion, def.get("fixed_starter", {}))

	# 6. Auto-distribute XP budget matching the player's power level
	var player := CharacterSystem.get_player()
	if player.is_empty():
		push_error("CompanionSystem: recruit() called with no player character")
		return {}
	var budget := _calculate_spent_xp(player)
	_auto_distribute(companion, budget, def.get("build_weights", {}))

	# 7. Fixed spells (guaranteed, regardless of skill level)
	for spell_id in def.get("fixed_spells", []):
		if not spell_id in companion.known_spells:
			companion.known_spells.append(spell_id)

	# 8. Random spells weighted by build
	_apply_random_spells(companion, def.get("random_spells", {}), def.get("build_weights", {}))

	# 9. Equipment — fixed first, then procedural
	var rarity := _power_to_rarity(budget)
	_apply_starting_equipment(companion, def.get("fixed_equipment", {}),
		def.get("starting_equipment", {}), rarity)

	# 10. Fixed items — add to shared party inventory
	for item_id in def.get("fixed_items", []):
		ItemSystem.add_to_inventory(item_id)

	# 11. Recalculate all derived stats
	CharacterSystem.update_derived_stats(companion)

	# 12. Deduct gold and register in party
	GameState.add_gold(-cost)
	CharacterSystem.add_companion(companion)

	companion_recruited.emit(companion)
	show_recruit_popup(companion)
	return companion


const RECRUIT_POPUP_SCENE = preload("res://scenes/ui/companion_recruit_popup.tscn")

## Show the recruitment introduction popup for a companion.
func show_recruit_popup(companion: Dictionary) -> void:
	var popup = RECRUIT_POPUP_SCENE.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show_companion(companion)
