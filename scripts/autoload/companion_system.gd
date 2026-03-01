extends Node
## CompanionSystem — Loads companion definitions and handles recruitment.

signal companion_recruited(companion: Dictionary)
signal companion_overflow(companion: Dictionary)  # All build_weights maxed

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
