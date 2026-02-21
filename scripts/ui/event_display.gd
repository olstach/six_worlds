extends Control
## Event Display - Shows events with Tibetan thangka-inspired aesthetic
##
## Displays:
## - Event title and description
## - Choice buttons (grey/blue/yellow by type)
## - Roll results
## - Outcome text

@onready var event_panel: Panel = $EventPanel
@onready var title_label: Label = $EventPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: RichTextLabel = $EventPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var choices_container: VBoxContainer = $EventPanel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var result_panel: Panel = $ResultPanel
@onready var result_label: RichTextLabel = $ResultPanel/MarginContainer/VBoxContainer/ResultLabel
@onready var continue_button: Button = $ResultPanel/MarginContainer/VBoxContainer/ContinueButton

signal event_display_closed

var current_event: Dictionary = {}
var current_outcome: Dictionary = {}

func _ready() -> void:
	# Connect to EventManager
	EventManager.event_started.connect(_on_event_started)
	EventManager.event_completed.connect(_on_event_completed)

	# Hide panels initially
	result_panel.visible = false
	event_panel.visible = false


## Call this to show and start an event (used by overworld overlay)
func show_event(event_id: String) -> void:
	visible = true
	if not EventManager.start_event(event_id):
		# Event not found — close immediately so movement isn't paused forever
		visible = false
		event_display_closed.emit()

func _on_event_started(event_data: Dictionary) -> void:
	current_event = event_data
	display_event()

func display_event() -> void:
	# Clear previous choices
	for child in choices_container.get_children():
		child.queue_free()
	
	# Set title and description
	title_label.text = current_event.title
	description_label.text = current_event.text
	
	# Create choice buttons
	for choice in current_event.choices:
		var availability = EventManager.evaluate_choice_availability(choice)
		create_choice_button(choice, availability)
	
	# Show event panel, hide result
	event_panel.visible = true
	result_panel.visible = false

func create_choice_button(choice: Dictionary, availability: Dictionary) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 60)
	
	# Set text
	var button_text = choice.text
	if not availability.available:
		button_text += "\n[" + availability.reason + "]"
	elif availability.passing_character:
		button_text += "\n[" + availability.passing_character.name + "]"
	
	button.text = button_text
	
	# Style based on choice type
	var color = EventManager.CHOICE_COLORS[choice.type]
	
	# Create custom style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color.darkened(0.6)
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 4
	style_normal.border_color = color
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.content_margin_left = 16
	style_normal.content_margin_right = 16
	style_normal.content_margin_top = 12
	style_normal.content_margin_bottom = 12
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.darkened(0.4)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.2)
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.2, 0.2, 0.2)
	style_disabled.border_color = Color(0.4, 0.4, 0.4)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	
	# Set font color
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	# Disable if requirements not met
	button.disabled = not availability.available
	
	# Connect to choice handler
	button.pressed.connect(func(): _on_choice_selected(choice))
	
	# Add icon based on type
	match choice.type:
		"requirement":
			button.text = "⚡ " + button.text
		"roll":
			button.text = "🎲 " + button.text
	
	choices_container.add_child(button)

func _on_choice_selected(choice: Dictionary) -> void:
	print("Player selected: ", choice.text)
	
	# Execute the choice
	current_outcome = EventManager.make_choice(choice)

func _on_event_completed(outcome: Dictionary) -> void:
	display_outcome(outcome)

func display_outcome(outcome: Dictionary) -> void:
	var result_text = ""
	
	# Show roll result if applicable
	if "roll_result" in outcome:
		var roll = outcome.roll_result
		result_text += "[center][b]🎲 ROLL: " + str(int(roll.roll)) + " + " + str(int(roll.attribute_value)) + " (" + roll.attribute.capitalize() + ") = " + str(int(roll.total)) + "[/b][/center]\n"
		result_text += "[center]Difficulty: " + str(int(roll.difficulty)) + " - "
		if roll.success:
			result_text += "[color=#4ade80]SUCCESS![/color][/center]\n\n"
		else:
			result_text += "[color=#ef4444]FAILURE![/color][/center]\n\n"
		result_text += "[i]" + roll.roller + " made the attempt[/i]\n\n"
	
	# Show outcome text
	if "text" in outcome:
		result_text += outcome.text + "\n\n"
	
	# Show rewards
	if "rewards" in outcome:
		result_text += "[b]Rewards:[/b]\n"
		if "xp" in outcome.rewards:
			result_text += "• +" + str(outcome.rewards.xp) + " XP\n"
		if "items" in outcome.rewards:
			for item in outcome.rewards.items:
				result_text += "• " + item.replace("_", " ").capitalize() + "\n"
		result_text += "\n"
	
	# Show karma changes (visible for now, can hide later)
	if "karma" in outcome:
		result_text += "[b]Karma shifts:[/b]\n"
		for realm in outcome.karma:
			var amount = outcome.karma[realm]
			var sign = "+" if amount > 0 else ""
			result_text += "• " + realm.capitalize() + ": " + sign + str(amount) + "\n"
	
	# Handle special outcome types
	match outcome.get("type", "text"):
		"combat":
			result_text += "\n[b][color=#ef4444]⚔ COMBAT BEGINS[/color][/b]"
		"shop":
			result_text += "\n[b][color=#4ade80]🏪 SHOP OPENED[/color][/b]"
	
	result_label.text = result_text
	
	# Show result panel
	event_panel.visible = false
	result_panel.visible = true

func _on_continue_button_pressed() -> void:
	# Hide and notify parent (overworld) that the event is done
	event_panel.visible = false
	result_panel.visible = false
	visible = false
	event_display_closed.emit()
