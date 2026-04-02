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
signal service_requested(shop_id: String)

var current_event: Dictionary = {}
var current_outcome: Dictionary = {}
var _location_mode: bool = false  # True when displaying a location (service tabs) instead of an event

func _ready() -> void:
	# Connect to EventManager
	EventManager.event_started.connect(_on_event_started)
	EventManager.event_completed.connect(_on_event_completed)

	# Hide panels initially
	result_panel.visible = false
	event_panel.visible = false


## Call this to show and start an event (used by overworld overlay).
## object_id and one_time are forwarded to EventManager so it can track
## which choices have been used on persistent map objects (prevents XP farming).
func show_event(event_id: String, object_id: String = "", one_time: bool = false) -> void:
	current_outcome = {}  # Clear stale outcome from any previous event in this chain
	# Set context on EventManager BEFORE start_event so evaluate_choice_availability
	# can immediately check used_event_choices when building the choice list.
	EventManager.current_event_object_id = object_id
	EventManager.current_event_one_time = one_time
	visible = true
	if not EventManager.start_event(event_id):
		# Event not found — close immediately so movement isn't paused forever
		EventManager.current_event_object_id = ""
		EventManager.current_event_one_time = false
		visible = false
		event_display_closed.emit()

func _on_event_started(event_data: Dictionary) -> void:
	current_event = event_data
	if event_data.get("type", "") == "location":
		_location_mode = true
		display_location()
	else:
		_location_mode = false
		display_event()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	# Enter/Space continues from result panel
	if result_panel.visible:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			_on_continue_button_pressed()
		return

	# 1-9 selects buttons from event/location panel; Escape leaves a location
	if event_panel.visible:
		var buttons: Array = []
		for child in choices_container.get_children():
			if child is Button:
				buttons.append(child)
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx = event.keycode - KEY_1
			if idx < buttons.size() and (not buttons[idx].has_method("is_disabled") or not buttons[idx].disabled):
				get_viewport().set_input_as_handled()
				buttons[idx].pressed.emit()
		elif _location_mode and event.keycode == KEY_ESCAPE:
			# Escape leaves the location
			get_viewport().set_input_as_handled()
			# Trigger the Leave button (always the last button)
			if not buttons.is_empty():
				buttons[-1].pressed.emit()


## Called by overworld when a service shop closes — restore the location panel
## without showing a result screen, so the player can browse other services.
func restore_location_panel() -> void:
	event_panel.visible = true
	result_panel.visible = false


## Display a multi-service location (town, camp, etc.).
## Location events have a "services" array instead of "choices".
## Each service is a button that opens a sub-shop; Leave closes the location.
func display_location() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	title_label.text = current_event.get("title", "Location")
	# Show first-visit intro text if available, otherwise normal description
	if current_event.get("is_first_visit", false) and current_event.has("first_visit_text"):
		description_label.text = current_event.get("first_visit_text", "")
	else:
		description_label.text = current_event.get("text", current_event.get("description", ""))

	# Relabel the prompt to show available services
	var choices_label = $EventPanel/MarginContainer/VBoxContainer/ChoicesLabel
	if choices_label:
		choices_label.text = "Services available:"

	var services: Array = current_event.get("services", [])
	for service in services:
		_create_service_button(service)

	_create_location_leave_button()

	event_panel.visible = true
	result_panel.visible = false


## Build a gold-tinted button that opens a sub-shop when clicked.
func _create_service_button(service: Dictionary) -> void:
	var button = Button.new()
	var icon: String = service.get("icon", "🏪")
	var label: String = service.get("tab_name", "Service")
	button.text = icon + "  " + label
	button.custom_minimum_size = Vector2(0, 60)

	UIStyle.apply_button_style(button, Color(0.65, 0.5, 0.12), 4, 8, 12)
	button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)

	var shop_id: String = service.get("shop_id", "")
	button.pressed.connect(func():
		AudioManager.play("ui_click")
		service_requested.emit(shop_id))

	choices_container.add_child(button)


## Leave button for location mode — closes cleanly without a result screen.
func _create_location_leave_button() -> void:
	var button = Button.new()
	button.text = "Leave"
	button.custom_minimum_size = Vector2(0, 50)

	UIStyle.apply_button_style(button, Color(0.4, 0.4, 0.5), 4, 8, 12)
	button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	button.add_theme_color_override("font_hover_color", Color.WHITE)

	button.pressed.connect(func():
		AudioManager.play("ui_click")
		event_panel.visible = false
		result_panel.visible = false
		visible = false
		_location_mode = false
		event_display_closed.emit())

	choices_container.add_child(button)


func display_event() -> void:
	# Clear previous choices
	for child in choices_container.get_children():
		child.queue_free()

	# Set title and description
	title_label.text = current_event.title
	description_label.text = current_event.text

	# Create choice buttons; track whether any are available
	var any_available = false
	for choice in current_event.choices:
		var availability = EventManager.evaluate_choice_availability(choice)
		if availability.get("hidden", false):
			continue  # Flag prerequisite not met — don't render this choice at all
		if availability.available:
			any_available = true
		create_choice_button(choice, availability)

	# If no choices are selectable, add a Leave button so the player isn't stuck
	if not any_available:
		_create_leave_button()

	# Show event panel, hide result
	event_panel.visible = true
	result_panel.visible = false


func _create_leave_button() -> void:
	var button = Button.new()
	button.text = "Leave"
	button.custom_minimum_size = Vector2(0, 60)

	UIStyle.apply_button_style(button, Color(0.4, 0.4, 0.5), 4, 8, 12)
	button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	button.add_theme_color_override("font_hover_color", Color.WHITE)

	button.pressed.connect(func():
		AudioManager.play("ui_click")
		_on_continue_button_pressed())

	choices_container.add_child(button)

## Returns true if any party member has the karma_sight talisman perk equipped.
func _party_has_karma_sight() -> bool:
	var party = CharacterSystem.get_party()
	for char_data in party:
		for slot in ["trinket1", "trinket2"]:
			var item_id = ItemSystem.get_equipped_item(char_data, slot)
			if item_id == "":
				continue
			var item = ItemSystem.get_item(item_id)
			if "karma_sight" in item.get("perks", []):
				return true
	return false


func create_choice_button(choice: Dictionary, availability: Dictionary) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 60)
	
	# Set text
	var button_text = choice.text
	if not availability.available:
		button_text += "\n[" + availability.reason + "]"
	elif availability.passing_character:
		button_text += "\n[" + availability.passing_character.name + "]"

	# karma_sight talisman: show karma hints on buttons before choosing
	if _party_has_karma_sight():
		var outcome_karma = choice.get("outcome", {}).get("karma", {})
		if outcome_karma.is_empty():
			# Roll choices have success/failure outcomes — show both if different
			var s_karma = choice.get("success", {}).get("karma", {})
			var f_karma = choice.get("failure", {}).get("karma", {})
			outcome_karma = s_karma  # Show success karma as preview for rolls
		if not outcome_karma.is_empty():
			var karma_parts: Array[String] = []
			for realm in outcome_karma:
				var amt = outcome_karma[realm]
				karma_parts.append(realm.capitalize() + (" +" if amt > 0 else " ") + str(amt))
			button_text += "\n☸ " + ", ".join(karma_parts)

	button.text = button_text
	
	# Style based on choice type
	var color = EventManager.CHOICE_COLORS[choice.type]
	UIStyle.apply_button_style(button, color, 4, 8, 12)
	var style_disabled = UIStyle.make_stylebox(Color(0.4, 0.4, 0.4), 4, 8, 12, 0.5)
	style_disabled.bg_color = Color(0.2, 0.2, 0.2)
	button.add_theme_stylebox_override("disabled", style_disabled)
	
	# Set font color
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	# Disable if requirements not met
	button.disabled = not availability.available
	
	# Connect to choice handler
	button.pressed.connect(func():
		AudioManager.play("ui_click")
		_on_choice_selected(choice))
	
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
			result_text += "• +" + str(int(outcome.rewards.xp)) + " XP\n"
		if "items" in outcome.rewards:
			for item in outcome.rewards.items:
				result_text += "• " + item.replace("_", " ").capitalize() + "\n"
		result_text += "\n"
	
	# Show karma changes only if a party member has karma_sight talisman perk
	if "karma" in outcome and _party_has_karma_sight():
		result_text += "[b]☸ Karma shifts:[/b]\n"
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
	AudioManager.play("ui_click")
	var follow_up: String = current_outcome.get("follow_up_event", "")
	if follow_up != "":
		# Chain directly into the next event — start it fresh (no object context inheritance).
		# Pass "", false so the chained event is not treated as one-time or tracked
		# against the triggering map object's used-choices list.
		show_event(follow_up, "", false)
	else:
		event_panel.visible = false
		result_panel.visible = false
		visible = false
		event_display_closed.emit()
