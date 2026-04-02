extends Control
## BardoScreen - The intermediate state between death and rebirth
##
## In Tibetan Buddhism, the Bardo is the transitional state between lives.
## This screen reveals hidden karma scores, determines the next realm,
## rolls a new race and background, and starts the next life.

# Realm display names and flavor text
const REALM_INFO: Dictionary = {
	"hell": {
		"name": "Hell Realm",
		"color": Color(0.85, 0.2, 0.15),
		"description": "Suffering forged in fire and ice."
	},
	"hungry_ghost": {
		"name": "Hungry Ghost Realm",
		"color": Color(0.5, 0.7, 0.3),
		"description": "Endless craving, never sated."
	},
	"animal": {
		"name": "Animal Realm",
		"color": Color(0.4, 0.65, 0.3),
		"description": "Instinct and survival, tooth and claw."
	},
	"human": {
		"name": "Human Realm",
		"color": Color(0.7, 0.65, 0.5),
		"description": "Precious birth - the realm of choice."
	},
	"asura": {
		"name": "Asura Realm",
		"color": Color(0.7, 0.3, 0.5),
		"description": "Jealousy and conflict without end."
	},
	"god": {
		"name": "God Realm",
		"color": Color(0.85, 0.8, 0.4),
		"description": "Bliss so deep it blinds to truth."
	}
}

# Reveal order for karma (dramatic pacing)
const REALM_REVEAL_ORDER: Array[String] = [
	"hell", "hungry_ghost", "animal", "human", "asura", "god"
]

# Timing
const REVEAL_DELAY: float = 0.8       # Seconds between each karma reveal
const POST_KARMA_PAUSE: float = 1.2   # Pause after all karma shown
const RESULT_STEP_DELAY: float = 1.5  # Seconds between realm -> race -> background

# State
var _reincarnation_result: Dictionary = {}  # {realm, race, background}
var _karma_lines: Array[Control] = []       # HBoxContainers for each karma row
var _content_vbox: VBoxContainer            # Main content column
var _result_section: VBoxContainer          # Where realm/race/background appear
var _begin_btn: Button                      # "Begin New Life" button


func _ready() -> void:
	_build_ui()
	_run_bardo_sequence()
	_fade_in_from_black()


## Build the full UI layout programmatically
func _build_ui() -> void:
	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 500)
	var panel_style = UIStyle.make_stylebox(Color(0.4, 0.25, 0.5), 2, 10, 30, 0.88)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(_content_vbox)

	# Title
	var title = Label.new()
	title.text = "THE BARDO"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.6, 0.45, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Between death and rebirth, karma is weighed..."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.4, 0.45))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(subtitle)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.4, 0.25, 0.5, 0.5))
	_content_vbox.add_child(sep)

	# Karma section title (starts hidden, fades in)
	var karma_title = Label.new()
	karma_title.text = "Your Karma"
	karma_title.add_theme_font_size_override("font_size", 16)
	karma_title.add_theme_color_override("font_color", Color(0.55, 0.45, 0.6))
	karma_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(karma_title)

	# Create karma lines (hidden initially)
	for realm_id in REALM_REVEAL_ORDER:
		var info = REALM_INFO[realm_id]
		var karma_value = KarmaSystem.karma_scores.get(realm_id, 0)

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 20)
		_content_vbox.add_child(row)

		var realm_label = Label.new()
		realm_label.text = info.name
		realm_label.custom_minimum_size.x = 180
		realm_label.add_theme_font_size_override("font_size", 15)
		realm_label.add_theme_color_override("font_color", info.color)
		realm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(realm_label)

		var value_label = Label.new()
		value_label.text = str(karma_value)
		value_label.custom_minimum_size.x = 60
		value_label.add_theme_font_size_override("font_size", 15)
		value_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(value_label)

		# Start invisible
		row.modulate.a = 0.0
		_karma_lines.append(row)

	# Second separator (hidden until karma reveal done)
	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.4, 0.25, 0.5, 0.5))
	sep2.modulate.a = 0.0
	_content_vbox.add_child(sep2)

	# Result section — realm, race, background appear here one at a time
	_result_section = VBoxContainer.new()
	_result_section.add_theme_constant_override("separation", 12)
	_result_section.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_vbox.add_child(_result_section)

	# Begin New Life button (hidden until everything is revealed)
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_vbox.add_child(btn_container)

	_begin_btn = Button.new()
	_begin_btn.text = "Begin New Life"
	_begin_btn.custom_minimum_size = Vector2(200, 44)
	_begin_btn.add_theme_font_size_override("font_size", 16)
	_begin_btn.visible = false

	UIStyle.apply_button_style(_begin_btn, Color(0.5, 0.35, 0.6), 2, 6, 8)

	_begin_btn.pressed.connect(_on_begin_new_life)
	btn_container.add_child(_begin_btn)


## Run the full Bardo reveal sequence
func _run_bardo_sequence() -> void:
	# Determine reincarnation before animating (so we know what to reveal)
	_reincarnation_result = KarmaSystem.reincarnate()

	# Step 1: Reveal karma scores one by one
	for i in range(_karma_lines.size()):
		await get_tree().create_timer(REVEAL_DELAY).timeout
		_fade_in(_karma_lines[i])

	# Step 2: Pause, then highlight the winning realm
	await get_tree().create_timer(POST_KARMA_PAUSE).timeout

	# Highlight the winning karma line
	var winning_realm = _reincarnation_result.get("realm", "hell")
	var winning_index = REALM_REVEAL_ORDER.find(winning_realm)
	if winning_index >= 0 and winning_index < _karma_lines.size():
		var winning_row = _karma_lines[winning_index]
		# Pulse the winning row brighter
		var tween = create_tween()
		tween.tween_property(winning_row, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.3)
		tween.tween_property(winning_row, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

	# Show the second separator
	var children = _content_vbox.get_children()
	for child in children:
		if child is HSeparator and child.modulate.a < 0.5:
			_fade_in(child)
			break

	# Step 3: Show realm
	await get_tree().create_timer(RESULT_STEP_DELAY).timeout
	var realm_info = REALM_INFO.get(winning_realm, REALM_INFO["hell"])
	_add_result_line("Reborn in...", realm_info.name, realm_info.color, realm_info.description)

	# Step 4: Show race
	await get_tree().create_timer(RESULT_STEP_DELAY).timeout
	var race_id = _reincarnation_result.get("race", "human")
	var race_data = CharacterSystem.get_race_data(race_id)
	var race_name = race_data.get("name", race_id.replace("_", " ").capitalize())
	var race_desc = race_data.get("description", "")
	_add_result_line("As a...", race_name, realm_info.color.lightened(0.2), race_desc)

	# Step 5: Show background
	await get_tree().create_timer(RESULT_STEP_DELAY).timeout
	var bg_id = _reincarnation_result.get("background", "wanderer")
	var bg_data = CharacterSystem.get_background_data(bg_id)
	var bg_name = bg_data.get("name", bg_id.replace("_", " ").capitalize())
	var bg_desc = bg_data.get("description", "")
	_add_result_line("Walking the path of the...", bg_name, Color(0.8, 0.75, 0.6), bg_desc)

	# Step 6: Show the Begin button
	await get_tree().create_timer(1.0).timeout
	_begin_btn.visible = true
	_begin_btn.modulate.a = 0.0
	_fade_in(_begin_btn)


## Add a result line to the result section with animation
func _add_result_line(prefix: String, value: String, color: Color, description: String) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	# "Reborn in..." / "As a..." prefix
	var prefix_label = Label.new()
	prefix_label.text = prefix
	prefix_label.add_theme_font_size_override("font_size", 13)
	prefix_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	prefix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(prefix_label)

	# The actual value (realm name, race name, background name)
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)

	# Description / flavor
	if description != "":
		var desc_label = Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		container.add_child(desc_label)

	container.modulate.a = 0.0
	_result_section.add_child(container)
	_fade_in(container)


## Fade a node from invisible to visible over 0.4 seconds (used for bardo reveal steps)
func _fade_in(node: Control) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.4)


## Full-screen fade-in from black when entering this scene
func _fade_in_from_black() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(overlay.queue_free)


## Fade to black then change scene
func _fade_and_goto(scene_path: String) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	add_child(overlay)
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))


## Player clicks "Begin New Life" — create new character and start new run
func _on_begin_new_life() -> void:
	var realm = _reincarnation_result.get("realm", "hell")
	var race = _reincarnation_result.get("race", "human")
	var background = _reincarnation_result.get("background", "wanderer")

	# Generate a name for the new character
	var new_name = _generate_name(race, realm)

	# Create the new character, preserving persistent progression
	CharacterSystem.start_new_life(new_name, race, background)

	# Reset game state for new run
	GameState.is_party_wiped = false
	GameState.gold = 50  # Starting gold for new life (less than first run)
	GameState.start_new_run(realm)

	# Clear map so overworld generates a fresh one for the new realm
	MapManager.current_map_id = ""
	# Reset fog of war so the new run starts unexplored
	MapManager.visited_tiles.clear()

	# Save progress after reincarnation
	SaveManager.autosave()

	# Transition to overworld in the new realm (fade out first)
	_fade_and_goto("res://scenes/overworld/overworld.tscn")


## Generate a thematic name based on race/realm
## These are simple placeholders — can be expanded with name lists later
func _generate_name(race: String, realm: String) -> String:
	var hell_names = ["Mara", "Yama", "Rahu", "Kali", "Rudra", "Agni", "Vetala"]
	# Hungry ghost names draw from Tibetan preta lore and Sanskrit sources.
	# Sub-races covered: yidag (pretas proper), rolang (reanimated corpses),
	# skeleton variants, vetala (possession spirits), dralha (corrupted war-spirits),
	# gyelpo (gyalpo demons), dré (obstacle spirits), shaza (flesh-eaters).
	var ghost_names = [
		# Tibetan-rooted — evoke craving, hollowness, wandering
		"Nyönpa", "Khanag", "Drekpa", "Zhöchen", "Rolma", "Migme",
		"Gongchen", "Dukpa", "Kyangbu", "Bayang", "Shangku", "Thamchen",
		"Lungwa", "Trungkar", "Bardowa", "Dregchen", "Sogme", "Rimchen",
		"Kyiduk", "Khyimdag", "Dokma", "Zangkar", "Phagchen", "Chöbar",
		# Sanskrit-rooted — preta tradition
		"Preta", "Vetali", "Pishacha", "Bhutika", "Apasmara", "Skandha",
		"Jivaka", "Nirjhara", "Kshudha", "Trishna", "Abhava", "Pretaraja",
		# Names evoking specific races
		"Rolang", "Keting", "Gyelchen", "Drelwa",   # rolang / skeleton / gyelpo
		"Tsenkar", "Dralkar", "Dralnak", "Tsensen", # dralha / tsen-adjacent
		"Yidag", "Shazama", "Drema", "Nyönchen",    # yidag / shaza / dré
	]
	var animal_names = ["Naga", "Garuda", "Makara", "Simha", "Kinnara", "Vyala"]
	var human_names = ["Tenzin", "Dorje", "Pema", "Karma", "Lobsang", "Drolma", "Sonam", "Jigme"]
	var asura_names = ["Vemacitrin", "Rahu", "Svarbhanu", "Pahari", "Danava", "Daitya"]
	var god_names = ["Deva", "Brahma", "Indra", "Surya", "Chandra", "Vayu", "Varuna"]

	var name_pool: Array
	match realm:
		"hell": name_pool = hell_names
		"hungry_ghost": name_pool = ghost_names
		"animal": name_pool = animal_names
		"human": name_pool = human_names
		"asura": name_pool = asura_names
		"god": name_pool = god_names
		_: name_pool = human_names

	return name_pool[randi() % name_pool.size()]
