extends Control
## Quest Board — built entirely in code (no .tscn dependency).
## Shows a randomised pool of available quests for the current realm.
## Triggered by "quest_board" event outcome type.

signal quest_board_closed

const MAX_QUESTS_SHOWN := 5

var _realm: String = ""
var _title_label: Label
var _quests_container: VBoxContainer
var _close_button: Button


func _ready() -> void:
	# Full-screen backdrop
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 480)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.07, 0.06)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.55, 0.40, 0.12)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Quest Board"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	vbox.add_child(_title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(scroll)

	_quests_container = VBoxContainer.new()
	_quests_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quests_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_quests_container)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.custom_minimum_size = Vector2(0, 40)
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)


## Show the board for the given realm. Populates the quest list.
func show_board(realm: String) -> void:
	_realm = realm
	_populate()
	visible = true


func _populate() -> void:
	for child in _quests_container.get_children():
		child.queue_free()

	var available: Array[Dictionary] = GameState.get_available_quests_for_realm(_realm)
	available.shuffle()
	var shown: Array[Dictionary] = available.slice(0, MAX_QUESTS_SHOWN)

	if shown.is_empty():
		var lbl := Label.new()
		lbl.text = "No quests available."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_quests_container.add_child(lbl)
		return

	for quest in shown:
		_quests_container.add_child(_create_quest_row(quest))


func _create_quest_row(quest: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.07)
	style.border_width_left = 3
	style.border_color = Color(0.55, 0.40, 0.12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Info column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = quest.get("name", "?")
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = quest.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.55))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)

	# Reward summary
	var reward: Dictionary = quest.get("reward", {})
	var reward_parts: Array[String] = []
	if reward.get("xp", 0) > 0:
		reward_parts.append("+%d XP" % int(reward.get("xp", 0)))
	if reward.get("gold", 0) > 0:
		reward_parts.append("+%d gold" % int(reward.get("gold", 0)))
	if not reward_parts.is_empty():
		var reward_lbl := Label.new()
		reward_lbl.text = "Reward: " + "  ".join(reward_parts)
		reward_lbl.add_theme_color_override("font_color", Color(0.50, 0.65, 0.85))
		reward_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(reward_lbl)

	# Accept button
	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(80, 0)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.30, 0.15)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.3, 0.6, 0.3)
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	accept_btn.add_theme_stylebox_override("normal", btn_style)
	accept_btn.add_theme_color_override("font_color", Color.WHITE)
	var qid: String = quest.get("id", "")
	accept_btn.pressed.connect(func(): _on_accept_pressed(qid))
	hbox.add_child(accept_btn)

	return row


func _on_accept_pressed(quest_id: String) -> void:
	AudioManager.play("ui_click")
	if GameState.accept_quest(quest_id):
		var qname: String = GameState.get_quest_def(quest_id).get("name", quest_id)
		GameState.append_overworld_log("Quest accepted: %s" % qname)
	_populate()  # Refresh list (accepted quest disappears)


func _on_close_pressed() -> void:
	AudioManager.play("ui_click")
	visible = false
	quest_board_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
