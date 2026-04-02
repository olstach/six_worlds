extends Control
## TitleScreen - Main menu with Continue, New Game, Load, and Exit
##
## Tibetan thangka aesthetic: deep indigo background, gold accents,
## sacred geometry inspired layout. Built programmatically like bardo_screen.

# State
var _load_panel: PanelContainer  # Slot selection panel (shown on Load Game)
var _slot_buttons: Array[Button] = []
var _continue_btn: Button
var _new_game_btn: Button
var _load_btn: Button
var _delete_mode: bool = false
var _panel_title_label: Label  # Title label inside the load panel
var _delete_btn: Button  # Delete button inside the load panel

# UI colors matching the game's Tibetan aesthetic
const BG_COLOR := Color(0.03, 0.02, 0.07)
const GOLD := Color(0.85, 0.7, 0.25)
const GOLD_DIM := Color(0.6, 0.5, 0.2)
const INDIGO := Color(0.25, 0.15, 0.4)
const PANEL_BG := Color(0.06, 0.04, 0.1)
const PANEL_BORDER := Color(0.4, 0.3, 0.15)
const BTN_BG := Color(0.12, 0.08, 0.18)
const BTN_BORDER := Color(0.5, 0.4, 0.15)
const BTN_HOVER_BG := Color(0.2, 0.14, 0.28)
const BTN_HOVER_BORDER := Color(0.75, 0.6, 0.2)
const TEXT_DIM := Color(0.5, 0.45, 0.4)
const SLOT_EMPTY_COLOR := Color(0.35, 0.3, 0.25)
const DANGER_COLOR := Color(0.8, 0.25, 0.2)


func _ready() -> void:
	_build_ui()


## Build the full title screen UI
func _build_ui() -> void:
	# Main vertical layout
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	# Title section (upper area)
	var title_container = VBoxContainer.new()
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.add_theme_constant_override("separation", 8)
	title_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(title_container)

	# Spacer to push title down a bit
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_container.add_child(top_spacer)

	# Game title
	var title = Label.new()
	title.text = "SIX WORLDS"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Wheel of Rebirth"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", GOLD_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(subtitle)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_container.add_child(bottom_spacer)

	# Button section (lower area)
	var btn_section = VBoxContainer.new()
	btn_section.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_section.add_theme_constant_override("separation", 12)
	btn_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(btn_section)

	# Center the buttons horizontally
	var btn_center = HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_section.add_child(btn_center)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	btn_center.add_child(btn_vbox)

	# Continue button (hidden if no saves exist)
	_continue_btn = _make_button("Continue", Vector2(260, 48))
	_continue_btn.pressed.connect(_on_continue_pressed)
	btn_vbox.add_child(_continue_btn)

	# Show/hide continue based on saves
	var recent = SaveManager.get_most_recent_slot()
	_continue_btn.visible = recent > 0

	# New Game
	_new_game_btn = _make_button("New Game", Vector2(260, 48))
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	btn_vbox.add_child(_new_game_btn)

	# Load Game
	_load_btn = _make_button("Load Game", Vector2(260, 48))
	_load_btn.pressed.connect(_on_load_pressed)
	btn_vbox.add_child(_load_btn)

	# Only show Load if there's at least one save
	_load_btn.visible = recent > 0

	# Exit
	var exit_btn = _make_button("Exit", Vector2(260, 48))
	exit_btn.pressed.connect(_on_exit_pressed)
	btn_vbox.add_child(exit_btn)

	# Bottom padding
	var pad = Control.new()
	pad.custom_minimum_size = Vector2(0, 60)
	btn_section.add_child(pad)

	# Load panel (initially hidden, shown when Load Game is clicked)
	_build_load_panel()


## Build the save slot selection panel (hidden by default)
func _build_load_panel() -> void:
	# Overlay that dims background and blocks input
	var overlay = ColorRect.new()
	overlay.name = "LoadOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	_load_panel = PanelContainer.new()
	_load_panel.custom_minimum_size = Vector2(480, 350)
	var style = UIStyle.make_stylebox(PANEL_BORDER, 2, 10, 24)
	style.bg_color = PANEL_BG
	_load_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_load_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_load_panel.add_child(vbox)

	# Panel title
	_panel_title_label = Label.new()
	_panel_title_label.text = "Load Game"
	_panel_title_label.add_theme_font_size_override("font_size", 22)
	_panel_title_label.add_theme_color_override("font_color", GOLD)
	_panel_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_panel_title_label)

	# Slot buttons
	_slot_buttons.clear()
	for i in range(1, SaveManager.MAX_SLOTS + 1):
		var slot_btn = _make_slot_button(i)
		vbox.add_child(slot_btn)
		_slot_buttons.append(slot_btn)

	# Bottom row: Delete / Back
	var bottom_row = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 16)
	vbox.add_child(bottom_row)

	_delete_btn = _make_button("Delete Save", Vector2(140, 36), 14)
	_delete_btn.pressed.connect(_on_delete_toggled)
	bottom_row.add_child(_delete_btn)

	var back_btn = _make_button("Back", Vector2(100, 36), 14)
	back_btn.pressed.connect(_on_load_back_pressed)
	bottom_row.add_child(back_btn)


## Create a slot button with save info or "Empty" label
func _make_slot_button(slot: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(420, 56)
	btn.add_theme_font_size_override("font_size", 15)

	var info = SaveManager.get_slot_info(slot)
	if info.is_empty():
		btn.text = "Slot %d — Empty" % slot
		btn.add_theme_color_override("font_color", SLOT_EMPTY_COLOR)
		btn.disabled = true
	else:
		var name = info.get("player_name", "Unknown")
		var world = info.get("world", "hell").replace("_", " ").capitalize()
		var run = info.get("run_number", 1)
		var play_time = SaveManager.format_play_time(info.get("play_time", 0))
		var party_size = info.get("party_size", 1)
		btn.text = "Slot %d — %s | %s (Life %d) | Party: %d | %s" % [slot, name, world, run, party_size, play_time]
		btn.add_theme_color_override("font_color", Color.WHITE)

	# Style
	var normal = UIStyle.make_stylebox(BTN_BORDER, 1, 6, 8)
	normal.bg_color = BTN_BG
	btn.add_theme_stylebox_override("normal", normal)
	var hover = UIStyle.make_stylebox(BTN_HOVER_BORDER, 1, 6, 8)
	hover.bg_color = BTN_HOVER_BG
	btn.add_theme_stylebox_override("hover", hover)
	var disabled_style = UIStyle.make_stylebox(Color(0.2, 0.18, 0.15), 1, 6, 8)
	disabled_style.bg_color = Color(0.06, 0.04, 0.08)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.pressed.connect(_on_slot_pressed.bind(slot))
	return btn


## Create a styled button matching the game's aesthetic
func _make_button(text: String, min_size: Vector2, font_size: int = 18) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)

	var normal = UIStyle.make_stylebox(BTN_BORDER, 2, 6, 8)
	normal.bg_color = BTN_BG
	btn.add_theme_stylebox_override("normal", normal)
	var hover = UIStyle.make_stylebox(BTN_HOVER_BORDER, 2, 6, 8)
	hover.bg_color = BTN_HOVER_BG
	btn.add_theme_stylebox_override("hover", hover)

	return btn


# ============================================
# BUTTON HANDLERS
# ============================================

## Continue: load the most recently saved slot and go to overworld
func _on_continue_pressed() -> void:
	AudioManager.play("ui_click")
	var slot = SaveManager.get_most_recent_slot()
	if slot < 1:
		return
	if SaveManager.load_game(slot):
		_fade_and_goto("res://scenes/overworld/overworld.tscn")


## New Game: find an empty slot (or overwrite oldest), start fresh
func _on_new_game_pressed() -> void:
	AudioManager.play("ui_click")
	var slot = SaveManager.find_empty_slot()
	if slot < 1:
		# All slots full — show load panel in "pick slot to overwrite" mode
		_show_load_panel("New Game — Choose Slot to Overwrite")
		return

	_start_new_game_in_slot(slot)


## Load Game: show slot selection panel
func _on_load_pressed() -> void:
	AudioManager.play("ui_click")
	_delete_mode = false
	_show_load_panel("Load Game")


## Exit the game
func _on_exit_pressed() -> void:
	AudioManager.play("ui_click")
	get_tree().quit()


## Slot clicked in the load/overwrite panel
func _on_slot_pressed(slot: int) -> void:
	AudioManager.play("ui_click")
	if _delete_mode:
		SaveManager.delete_save(slot)
		_delete_mode = false
		# Stay on the panel — just refresh slots and reset the delete button
		_refresh_slot_buttons()
		if _delete_btn:
			_delete_btn.text = "Delete Save"
			_delete_btn.remove_theme_color_override("font_color")
		# Refresh main buttons visibility in case all saves are gone
		var recent = SaveManager.get_most_recent_slot()
		_continue_btn.visible = recent > 0
		_load_btn.visible = recent > 0
		return

	# Check if we're in "overwrite for new game" mode
	var is_new_game_mode = false
	if _panel_title_label:
		is_new_game_mode = "New Game" in _panel_title_label.text

	if is_new_game_mode:
		# Overwrite this slot with a new game
		SaveManager.delete_save(slot)
		_hide_load_panel()
		_start_new_game_in_slot(slot)
	else:
		# Load existing save
		if SaveManager.has_save(slot):
			_hide_load_panel()
			if SaveManager.load_game(slot):
				_fade_and_goto("res://scenes/overworld/overworld.tscn")


## Toggle delete mode (next slot click deletes instead of loading)
func _on_delete_toggled() -> void:
	AudioManager.play("ui_click")
	_delete_mode = not _delete_mode
	if _delete_btn:
		if _delete_mode:
			_delete_btn.text = "Cancel Delete"
			_delete_btn.add_theme_color_override("font_color", DANGER_COLOR)
			# Enable all slot buttons so empty ones can't be clicked but filled can
			for i in range(_slot_buttons.size()):
				_slot_buttons[i].disabled = not SaveManager.has_save(i + 1)
		else:
			_delete_btn.text = "Delete Save"
			_delete_btn.remove_theme_color_override("font_color")
			_refresh_slot_buttons()


## Back button in load panel
func _on_load_back_pressed() -> void:
	AudioManager.play("ui_click")
	_delete_mode = false
	_hide_load_panel()


# ============================================
# HELPERS
# ============================================

## Start a new game in the given slot and transition to overworld
func _start_new_game_in_slot(slot: int) -> void:
	SaveManager.start_new_game(slot)
	SaveManager.autosave()
	_fade_and_goto("res://scenes/overworld/overworld.tscn")


## Fade to black then change scene. Prevents buttons being clicked during fade.
func _fade_and_goto(scene_path: String) -> void:
	# Block further input during transition
	set_process_input(false)
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Eat clicks during fade
	add_child(overlay)
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))


## Show the load panel overlay
func _show_load_panel(title_text: String) -> void:
	_delete_mode = false
	_refresh_slot_buttons()

	# Update title text
	if _panel_title_label:
		_panel_title_label.text = title_text

	# In new-game mode, enable all slot buttons (including empty ones)
	if "New Game" in title_text:
		for i in range(_slot_buttons.size()):
			_slot_buttons[i].disabled = false
			if not SaveManager.has_save(i + 1):
				_slot_buttons[i].add_theme_color_override("font_color", SLOT_EMPTY_COLOR)

	var overlay = get_node_or_null("LoadOverlay")
	if overlay:
		overlay.visible = true


## Hide the load panel overlay
func _hide_load_panel() -> void:
	var overlay = get_node_or_null("LoadOverlay")
	if overlay:
		overlay.visible = false


## Refresh slot button labels from current save metadata
func _refresh_slot_buttons() -> void:
	for i in range(_slot_buttons.size()):
		var slot = i + 1
		var old_btn = _slot_buttons[i]
		var parent = old_btn.get_parent()
		var idx = old_btn.get_index()

		var new_btn = _make_slot_button(slot)
		parent.remove_child(old_btn)
		old_btn.queue_free()
		parent.add_child(new_btn)
		parent.move_child(new_btn, idx)
		_slot_buttons[i] = new_btn
