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
		for v in range(val, 10):
			total += 2
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
