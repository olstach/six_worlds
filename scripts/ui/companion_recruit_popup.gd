extends Control
## Companion recruitment popup — shows name, race/background, flavor text.
## Emits `confirmed` when the player clicks Continue.

signal confirmed

@onready var name_label: Label = %CompanionName
@onready var identity_label: Label = %IdentityLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var continue_btn: Button = %ContinueButton


func show_companion(companion: Dictionary) -> void:
	name_label.text = companion.get("name", "Companion")
	var race_display: String = companion.get("race", "")
	race_display = race_display.replace("_", " ").capitalize()
	var bg_display: String = companion.get("background", "")
	bg_display = bg_display.replace("_", " ").capitalize()
	identity_label.text = race_display + " · " + bg_display
	flavor_label.text = companion.get("flavor_text", "")
	show()


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	hide()


func _on_continue_pressed() -> void:
	confirmed.emit()
	queue_free()
