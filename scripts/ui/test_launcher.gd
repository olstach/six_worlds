extends Control
## Test Launcher - Switch between character sheet and event system

@onready var character_sheet_button: Button = $VBoxContainer/CharacterSheetButton
@onready var event_system_button: Button = $VBoxContainer/EventSystemButton

func _ready() -> void:
	pass

func _on_character_sheet_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/test_character_sheet.tscn")

func _on_event_system_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/event_display.tscn")
