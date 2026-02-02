extends Control
## Test Launcher - Switch between different UI systems for testing

func _ready() -> void:
	pass

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_character_sheet_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/new_character_sheet.tscn")

func _on_event_system_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/event_display.tscn")

func _on_combat_test_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")
