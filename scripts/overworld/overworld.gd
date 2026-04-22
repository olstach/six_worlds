extends Control
## Overworld - Main game scene that ties together map, events, combat, and character sheet
##
## This is the central hub: the player explores the map, triggers events and combat,
## and can open the character sheet as an overlay.

# Node references
@onready var map_renderer: Node2D = $MapRenderer
@onready var camera: Camera2D = $Camera2D
@onready var realm_label: Label = %RealmLabel
@onready var gold_label: Label = %GoldLabel
@onready var food_label: Label = %FoodLabel
@onready var herbs_label: Label = %HerbsLabel
@onready var scrap_label: Label = %ScrapLabel
@onready var reagents_label: Label = %ReagentsLabel
@onready var terrain_label: Label = %TerrainLabel
@onready var time_label: Label = %TimeLabel
@onready var char_sheet_button: Button = %CharSheetButton
@onready var equipment_button: Button = %EquipmentButton
@onready var party_button: Button = %PartyButton
@onready var spellbook_button: Button = %SpellbookButton
@onready var crafting_button: Button = %CraftingButton
@onready var journal_button: Button = %JournalButton
@onready var rest_button: Button = %RestButton
@onready var toast_label: Label = %ToastLabel

# Event overlay controls (children of EventOverlay CanvasLayer)
@onready var event_dimmer: ColorRect = $EventOverlay/EventDimmer
@onready var event_display: Control = $EventOverlay/EventDisplay

# Character sheet overlay (child of CharSheetOverlay CanvasLayer)
@onready var char_sheet: Control = $CharSheetOverlay/MainMenu

# Shop overlay CanvasLayer (shop_ui instanced dynamically)
@onready var shop_overlay: CanvasLayer = $ShopOverlay

# Toast fade timer
var _toast_timer: float = 0.0
const TOAST_DURATION: float = 3.0

# Cached crafting tiers for alchemy passive step processing
var _alchemy_tiers_cache: Dictionary = {}

# Track overlay state (since CanvasLayer has no .visible)
var _event_open: bool = false
var _char_sheet_open: bool = false
var _shop_open: bool = false
var _main_menu_open: bool = false
var _quest_board_open: bool = false
var _rest_open: bool = false
var _rest_layer: CanvasLayer = null
var _quest_board_instance: Control = null
var _quest_board_layer: CanvasLayer = null

var _log_panel_visible: bool = false
var _log_panel: PanelContainer = null
var _log_list: VBoxContainer = null
var _log_toggle_btn: Button = null

# Main menu overlay (built in code, opened with Esc)
var _main_menu_layer: CanvasLayer = null
var _abandon_btn: Button = null
var _abandon_confirm: bool = false
var _esc_main_panel: PanelContainer = null  # Main panel in the pause menu
var _esc_settings_panel: Control = null     # Settings sub-panel (hidden by default)
var _abandon_timer: float = 0.0

# Track current event object so we can remove it after the event chain completes
var _current_event_object: Dictionary = {}

# Shop instance and pending outcome (for event→shop flow)
var _shop_instance: Control = null
var _pending_shop_outcome: Dictionary = {}
# Set when a location service button is clicked — shop close returns to location panel
# instead of showing a result screen.
var _in_location_mode: bool = false

# Preload shop scene for event→shop flow
var _shop_scene: PackedScene = preload("res://scenes/ui/shop_ui.tscn")


func _ready() -> void:
	# Load the map if not already loaded (first launch or returning from Bardo)
	if MapManager.current_map_id.is_empty():
		# Use current world to determine which map to load
		# Only hell has a map config so far — other realms will fall back to hell_01
		var world = GameState.current_world
		var map_id = world + "_01"
		if not MapManager.load_map(map_id):
			# Fallback to hell if the realm's map doesn't exist yet
			MapManager.load_map("hell_01")

	# Handle return from combat
	if not GameState.pending_event_outcome.is_empty():
		# Returning from event-triggered combat
		var outcome = GameState.pending_event_outcome.duplicate(true)
		GameState.pending_event_outcome = {}

		if not GameState.last_defeated_mob_id.is_empty():
			# Victory — restore event object for cleanup on Continue
			GameState.last_defeated_mob_id = ""
			_current_event_object = GameState.pending_event_object.duplicate(true)
			# If the combat outcome has an on_victory block, use it instead
			# (e.g. smoking_mirror: defeat the mirror → shop opens with domain spells)
			if "on_victory" in outcome:
				var victory_outcome: Dictionary = outcome["on_victory"].duplicate(true)
				victory_outcome["text"] = victory_outcome.get("text", "") + "\n\n[b][color=#4ade80]VICTORY![/color][/b]"
				outcome = victory_outcome
			else:
				outcome["text"] = outcome.get("text", "") + "\n\n[b][color=#4ade80]VICTORY![/color][/b]"
		else:
			# Defeat — don't restore event object (so it stays on map for retry)
			outcome["text"] = outcome.get("text", "") + "\n\n[b][color=#ef4444]DEFEAT![/color][/b]\nYou retreat from the battle..."
		GameState.pending_event_object = {}

		# Show the event result panel
		_set_event_visible(true)
		event_display.display_outcome(outcome)
		_expire_combat_buffs()
	elif not GameState.last_defeated_mob_id.is_empty():
		# Normal mob combat return — victory, remove defeated mob
		MapManager.remove_mob(GameState.last_defeated_mob_id)
		GameState.last_defeated_mob_id = ""
		MapManager.resume_movement()
		_expire_combat_buffs()
	elif GameState.returning_from_combat:
		# Returning from combat without victory (fled or defeated) — just resume movement
		MapManager.resume_movement()
		_expire_combat_buffs()

	# Clear the combat return flag
	GameState.returning_from_combat = false

	# Connect MapManager signals for game loop triggers
	MapManager.event_triggered.connect(_on_event_triggered)
	MapManager.mob_combat_triggered.connect(_on_mob_combat_triggered)
	MapManager.mob_event_triggered.connect(_on_mob_event_triggered)
	MapManager.pickup_collected.connect(_on_pickup_collected)
	MapManager.portal_entered.connect(_on_portal_entered)
	MapManager.party_moved.connect(_on_party_moved)
	MapManager.party_position_updated.connect(_on_party_position_updated)

	# Connect gold and supply changes for HUD updates
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.supply_changed.connect(_on_supply_changed)

	# Connect day change for lunar calendar effects
	GameState.day_changed.connect(_on_day_changed)

	# Connect discovery signal (hidden finds on ruins/forest/etc.)
	MapManager.discovery_made.connect(_on_discovery_made)

	# Connect event display close signal
	event_display.event_display_closed.connect(_on_event_display_closed)
	event_display.service_requested.connect(_on_location_service_requested)

	# Connect EventManager signals for event→combat, event→shop, and event→quest_board
	EventManager.combat_requested.connect(_on_event_combat_requested)
	EventManager.shop_requested.connect(_on_event_shop_requested)
	EventManager.quest_board_requested.connect(_on_event_quest_board_requested)

	# Connect companion overflow signal to show mastery popup
	CompanionSystem.companion_overflow.connect(_on_companion_overflow)

	# Connect char sheet button and visibility sync
	char_sheet_button.pressed.connect(func(): _open_char_sheet_to_tab(0))
	equipment_button.pressed.connect(func(): _open_char_sheet_to_tab(1))
	party_button.pressed.connect(func(): _open_char_sheet_to_tab(2))
	spellbook_button.pressed.connect(func(): _open_char_sheet_to_tab(3))
	crafting_button.pressed.connect(func(): _open_char_sheet_to_tab(4))
journal_button.pressed.connect(func(): _open_char_sheet_to_tab(5))
	char_sheet.visibility_changed.connect(_on_char_sheet_visibility_changed)
	char_sheet.overworld_spell_cast.connect(_on_overworld_spell_cast)

	# Ensure overlays start hidden
	_set_event_visible(false)
	_set_char_sheet_visible(false)

	# Build the Esc main menu overlay
	_build_main_menu_panel()
	_build_log_panel()

	# Initialize HUD
	_update_hud()

	# Connect rest button
	rest_button.pressed.connect(_open_rest_panel)

	# Add hover tooltips to supply counter labels
	gold_label.mouse_filter = Control.MOUSE_FILTER_PASS
	gold_label.tooltip_text = "Gold — used for shopping, hiring companions, and bribes"
	food_label.mouse_filter = Control.MOUSE_FILTER_PASS
	food_label.tooltip_text = "Food — consumed when resting. Feeds the party between combats."
	herbs_label.mouse_filter = Control.MOUSE_FILTER_PASS
	herbs_label.tooltip_text = "Herbs — consumed when resting (Camp and Full Rest). Boosts healing recovery."
	scrap_label.mouse_filter = Control.MOUSE_FILTER_PASS
	scrap_label.tooltip_text = "Scrap — raw material for Crafting"
	reagents_label.mouse_filter = Control.MOUSE_FILTER_PASS
	reagents_label.tooltip_text = "Reagents — used for Ritual, Sorcery, and high-level spells"

	# Center camera on party
	_update_camera()

	# Fade in from black when entering this scene
	_fade_in_from_black()


func _process(delta: float) -> void:
	# Update camera to follow party smoothly
	_update_camera()

	# Fade toast
	if _toast_timer > 0:
		_toast_timer -= delta
		if _toast_timer <= 0:
			toast_label.visible = false
		elif _toast_timer < 1.0:
			toast_label.modulate.a = _toast_timer

	# Abandon run confirmation timeout
	if _abandon_confirm and _abandon_timer > 0:
		_abandon_timer -= delta
		if _abandon_timer <= 0:
			_abandon_confirm = false
			if _abandon_btn:
				_abandon_btn.text = "Abandon Run"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				# Character / Stats tab (index 0)
				_open_char_sheet_to_tab(0)
				get_viewport().set_input_as_handled()
			KEY_R:
				# Crafting tab (index 4)
				_open_char_sheet_to_tab(4)
				get_viewport().set_input_as_handled()
			KEY_E:
				# Equipment tab (index 1)
				_open_char_sheet_to_tab(1)
				get_viewport().set_input_as_handled()
			KEY_P:
				# Party tab (index 2)
				_open_char_sheet_to_tab(2)
				get_viewport().set_input_as_handled()
			KEY_S:
				# Spellbook tab (index 3)
				_open_char_sheet_to_tab(3)
				get_viewport().set_input_as_handled()
			KEY_J:
				# Journal tab (index 5)
				_open_char_sheet_to_tab(5)
				get_viewport().set_input_as_handled()
			KEY_L:
				# Message log toggle
				_toggle_log_panel()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				if _event_open or _shop_open or _quest_board_open or _main_menu_open or _char_sheet_open:
					return
				# Wait action: advance time + tick mobs + tick statuses
				GameState.advance_time(GameState.HOURS_PER_STEP)
				MapManager.tick_mobs()
				_tick_overworld_statuses()
				_update_time_label()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if _rest_open:
					_close_rest_panel()
					get_viewport().set_input_as_handled()
				elif _main_menu_open:
					_close_main_menu()
					get_viewport().set_input_as_handled()
				elif _char_sheet_open:
					_toggle_char_sheet()
					get_viewport().set_input_as_handled()
				elif not _event_open and not _shop_open and not _quest_board_open:
					_open_main_menu()
					get_viewport().set_input_as_handled()


func _update_camera() -> void:
	# party_world_position is already tile center (from _tile_to_world), no extra offset
	camera.position = MapManager.party_world_position


func _update_hud() -> void:
	var world_data = GameState.WORLDS.get(GameState.current_world, {})
	var map_name = MapManager.current_map_id.replace("_", " ").capitalize()
	realm_label.text = world_data.get("name", "Unknown") + " - " + map_name
	gold_label.text = "Gold: " + str(GameState.gold)
	food_label.text = "Food: " + str(GameState.food)
	herbs_label.text = "Herbs: " + str(GameState.herbs)
	scrap_label.text = "Scrap: " + str(GameState.scrap)
	reagents_label.text = "Reagents: " + str(GameState.reagents)
	_update_terrain_label()
	_update_time_label()


func _update_terrain_label() -> void:
	var terrain_name = MapManager.get_terrain_name(MapManager.party_position)
	var speed = MapManager.get_terrain_speed(MapManager.party_position)
	var speed_text = ""
	if speed >= 2.0:
		speed_text = " (Fast)"
	elif speed >= 1.25:
		speed_text = " (Quick)"
	elif speed == 1.0:
		speed_text = ""
	elif speed > 0:
		speed_text = " (Slow)"
	else:
		speed_text = " (Blocked)"
	terrain_label.text = terrain_name + speed_text


func _update_time_label() -> void:
	time_label.text = "%s\n%s" % [GameState.get_lunar_day_label(), GameState.get_time_of_day_label()]


# ============================================
# OVERLAY VISIBILITY HELPERS
# ============================================

func _set_event_visible(show: bool) -> void:
	_event_open = show
	event_dimmer.visible = show
	event_display.visible = show


func _set_char_sheet_visible(show: bool) -> void:
	_char_sheet_open = show
	char_sheet.visible = show


# ============================================
# EVENT HANDLING
# ============================================

func _on_event_triggered(event_id: String, object: Dictionary) -> void:
	_current_event_object = object
	MapManager.pause_movement()
	_set_event_visible(true)
	event_display.show_event(event_id, object.get("id", ""), object.get("one_time", false))


func _on_mob_event_triggered(_mob: Dictionary) -> void:
	# Event display is handled by _on_event_triggered (MapManager emits both signals
	# for friendly mobs). This handler exists for future mob-specific logic.
	pass


func _on_event_display_closed() -> void:
	_in_location_mode = false
	_set_event_visible(false)
	# Remove the source of the event after the chain completes
	if not _current_event_object.is_empty():
		var obj_id = _current_event_object.get("id", "")
		if not obj_id.is_empty():
			if _current_event_object.has("attitude"):
				# It's a mob (has attitude field) - remove it from the map
				MapManager.remove_mob(obj_id)
			elif _current_event_object.get("one_time", false):
				# It's a one-time event object - mark as collected
				MapManager.collected_objects.append(obj_id)
				var obj_pos = _current_event_object.get("position", Vector2i(-1, -1))
				if obj_pos in MapManager.objects:
					MapManager.objects.erase(obj_pos)
		_current_event_object = {}
	SaveManager.autosave()
	MapManager.resume_movement()


# ============================================
# COMBAT HANDLING
# ============================================

func _on_mob_combat_triggered(mob: Dictionary) -> void:
	MapManager.pause_movement()
	GameState.pending_combat_mob = mob.duplicate(true)
	GameState.last_defeated_mob_id = mob.get("id", "")
	# Capture overworld terrain context for battle map generation
	GameState.combat_terrain_context = _sample_terrain_context(
		mob.get("position", MapManager.party_position))
	get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")


## Event outcome triggered combat — store state and transition to combat_arena
func _on_event_combat_requested(enemy_group: String, outcome: Dictionary) -> void:
	# Store event state to survive scene change
	GameState.pending_event_outcome = outcome.duplicate(true)
	GameState.pending_event_object = _current_event_object.duplicate(true)

	# Build a combat mob dict from the event outcome
	var combat_mob = {
		"id": _current_event_object.get("id", "event_combat"),
		"name": enemy_group.replace("_", " ").capitalize(),
		"data": {"enemy_group": enemy_group, "difficulty": outcome.get("difficulty", "normal")}
	}

	# Use last_defeated_mob_id as victory flag (combat_arena clears it on defeat)
	GameState.pending_combat_mob = combat_mob
	GameState.last_defeated_mob_id = combat_mob.id
	# Capture overworld terrain context for battle map generation
	GameState.combat_terrain_context = _sample_terrain_context(MapManager.party_position)

	# Close event overlay and transition to combat
	_set_event_visible(false)
	_current_event_object = {}
	get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")


## Event outcome triggered shop — open shop as overlay
func _on_event_shop_requested(shop_id: String, outcome: Dictionary) -> void:
	_pending_shop_outcome = outcome.duplicate(true)
	_in_location_mode = false
	_open_shop_overlay(shop_id)


## Location service button clicked — open that service's shop, then return to location panel
func _on_location_service_requested(shop_id: String) -> void:
	_in_location_mode = true
	_pending_shop_outcome = {}
	_open_shop_overlay(shop_id)


## Shared helper: instance the shop_ui scene and open a shop by ID.
## Called from both the event→shop flow and the location service flow.
func _open_shop_overlay(shop_id: String) -> void:
	event_display.visible = false
	_shop_instance = _shop_scene.instantiate()
	shop_overlay.add_child(_shop_instance)
	_shop_instance.shop_closed.connect(_on_event_shop_closed)
	_shop_open = true

	var loc_data: Dictionary = _current_event_object.get("data", {}).duplicate()
	loc_data["_object_id"] = _current_event_object.get("id", "")
	if not _shop_instance.open_shop_by_id(shop_id, loc_data):
		print("Shop '%s' not found, closing shop overlay" % shop_id)
		_on_event_shop_closed()


## Shop closed:
##   - In location mode: restore the location panel so the player can browse other services.
##   - In event mode: show the event result panel with Continue button as usual.
func _on_event_shop_closed() -> void:
	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null
	_shop_open = false

	# Clear any event-set price multiplier so it doesn't bleed into subsequent shops
	GameState.set_flag("event_shop_price_multiplier", 1.0)

	event_display.visible = true
	if _in_location_mode:
		# Return to location panel — player can browse other services or Leave
		event_display.restore_location_panel()
	else:
		# Normal event→shop flow: show result panel with Continue button
		event_display.display_outcome(_pending_shop_outcome)
		_pending_shop_outcome = {}


## Event outcome triggered quest board — open quest board as overlay
func _on_event_quest_board_requested(realm: String, outcome: Dictionary) -> void:
	# Hide event display while board is open
	if is_instance_valid(event_display):
		event_display.visible = false

	if not is_instance_valid(_quest_board_instance):
		var board_script := load("res://scripts/ui/quest_board.gd")
		_quest_board_instance = board_script.new()
		# Add to a CanvasLayer above events (z=25, same as shop)
		var board_layer := CanvasLayer.new()
		board_layer.layer = 25
		board_layer.add_child(_quest_board_instance)
		add_child(board_layer)
		_quest_board_layer = board_layer

	_quest_board_open = true
	# Disconnect before reconnect to avoid duplicate callbacks
	if _quest_board_instance.quest_board_closed.is_connected(_on_quest_board_closed_wrapper):
		_quest_board_instance.quest_board_closed.disconnect(_on_quest_board_closed_wrapper)
	_quest_board_instance.quest_board_closed.connect(_on_quest_board_closed_wrapper.bind(outcome), CONNECT_ONE_SHOT)
	_quest_board_instance.show_board(realm)


func _on_quest_board_closed_wrapper(outcome: Dictionary) -> void:
	_quest_board_open = false
	if is_instance_valid(_quest_board_layer):
		_quest_board_layer.queue_free()
		_quest_board_layer = null
		_quest_board_instance = null
	# Show event result panel (outcome text if any)
	if is_instance_valid(event_display):
		event_display.visible = true
		event_display.display_outcome(outcome)


## Show a popup when a companion's build_weights are all maxed out (overflow mode).
func _on_companion_overflow(companion: Dictionary) -> void:
	var companion_name: String = companion.get("name", "Your companion")
	var dialog := AcceptDialog.new()
	dialog.title = "Mastery Achieved"
	dialog.dialog_text = "%s has mastered their calling.\nYou can direct their growth, or let them find their own way." % companion_name
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


# ============================================
# PICKUP HANDLING
# ============================================

func _on_pickup_collected(obj: Dictionary, rewards: Array) -> void:
	# Flavor text first (if the pickup has a message/description)
	var flavor: String = obj.get("data", {}).get("message", obj.get("message", ""))

	var parts: Array[String] = []
	for reward in rewards:
		var rtype: String = reward.get("type", "")
		var rval = reward.get("value", 0)
		match rtype:
			"gold":
				parts.append("+" + str(rval) + " gold")
			"xp":
				parts.append("+%d XP" % int(rval))
			"heal":
				parts.append("Healed " + str(int(rval)) + "%")
			"mana":
				parts.append("Mana +" + str(int(rval)) + "%")
			"item":
				parts.append(str(rval).replace("_", " ").capitalize())
			"item_random", "item_random_scaled":
				var chosen: String = reward.get("chosen", "")
				if chosen != "":
					parts.append(chosen.replace("_", " ").capitalize())
			"buff":
				if rval is Dictionary:
					var stat: String = rval.get("stat", "")
					var amount = rval.get("amount", 0)
					var combats: int = rval.get("combats_remaining", 1)
					var duration_str: String = "(permanent)" if combats == -1 \
						else ("(%d battle)" % combats if combats == 1 else "(%d battles)" % combats)
					var sign: String = "+" if amount >= 0 else ""
					parts.append("%s%s %s %s" % [sign, str(int(amount)), _buff_stat_label(stat), duration_str])
			"food":
				parts.append("+%d food" % int(rval))
			"damage":
				parts.append("[color=#ef4444]-%d HP (cursed!)[/color]" % int(rval))
			"cleanse":
				parts.append("Statuses cleared")
			"spell":
				var spell_id: String = reward.get("chosen_spell", "")
				if not spell_id.is_empty():
					var spell_data = CharacterSystem.get_spell_database().get(spell_id, {})
					var spell_name: String = spell_data.get("name", spell_id.replace("_", " ").capitalize())
					parts.append("Learned: " + spell_name)
				else:
					parts.append("(spell already known)")
			_:
				pass  # karma and other silent rewards don't show in toast

	# Play a contextual pickup sound based on what was found
	var is_cursed := rewards.any(func(r): return r.get("type", "") == "damage")
	if is_cursed:
		AudioManager.play("pickup_cursed")
	elif rewards.any(func(r): return r.get("type", "") in ["item", "item_random", "item_random_scaled"]):
		AudioManager.play("pickup_item")
	elif rewards.any(func(r): return r.get("type", "") == "gold"):
		AudioManager.play("pickup_gold")
	elif rewards.any(func(r): return r.get("type", "") == "buff"):
		AudioManager.play("pickup_buff")

	var msg: String = obj.get("name", "Pickup")
	if not flavor.is_empty():
		msg += "\n" + flavor
	if parts.size() > 0:
		msg += "\n" + ", ".join(parts)
	_show_toast(msg)
	gold_label.text = "Gold: " + str(GameState.gold)


## Translate a buff stat key to a short human-readable label for the toast.
func _buff_stat_label(stat: String) -> String:
	match stat:
		"strength": return "STR"
		"constitution": return "CON"
		"finesse": return "FIN"
		"focus": return "FOC"
		"awareness": return "AWA"
		"charm": return "CHA"
		"luck": return "LCK"
		"fire_resistance": return "Fire Resist"
		"spellpower_fire": return "Fire Spellpower"
		"initiative": return "Initiative"
		"loot_chance_pct": return "Loot Chance"
		"xp_gain_pct": return "XP Gain"
		_: return stat.replace("_", " ").capitalize()


## Fade in from black on scene enter — covers abrupt pop-in.
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


## Decrement combat-duration map buffs and re-derive party stats.
## Called after every combat resolves (win, loss, or flee).
func _expire_combat_buffs() -> void:
	if GameState.active_map_buffs.is_empty():
		return
	GameState.decrement_combat_buffs()
	for char in CharacterSystem.get_party():
		CharacterSystem.update_derived_stats(char)


# ============================================
# PORTAL HANDLING
# ============================================

func _on_portal_entered(destination: Dictionary) -> void:
	var dest_map = destination.get("destination_map", "")
	if dest_map.is_empty():
		_show_toast("Portal leads nowhere...")
		return
	MapManager.load_map(dest_map)
	_update_hud()


# ============================================
# CHARACTER SHEET
# ============================================

func _toggle_char_sheet() -> void:
	_set_char_sheet_visible(not _char_sheet_open)
	if _char_sheet_open:
		MapManager.pause_movement()
	else:
		if not _event_open:
			MapManager.resume_movement()


## Open the character sheet to a specific tab. If already on that tab, toggle closed.
func _open_char_sheet_to_tab(tab_idx: int) -> void:
	AudioManager.play("ui_click")
	if _char_sheet_open and char_sheet.get_current_tab() == tab_idx:
		# Same tab — toggle closed
		_toggle_char_sheet()
	else:
		char_sheet.open_to_tab(tab_idx)
		if not _char_sheet_open:
			_toggle_char_sheet()


func _on_char_sheet_visibility_changed() -> void:
	# Sync state if main_menu hides itself (e.g. via ESC in its own _input)
	if not char_sheet.visible and _char_sheet_open:
		_char_sheet_open = false
		if not _event_open:
			MapManager.resume_movement()


# ============================================
# HUD UPDATES
# ============================================

func _on_party_moved(_from: Vector2i, _to: Vector2i) -> void:
	GameState.advance_time(GameState.HOURS_PER_STEP)
	_update_terrain_label()
	_tick_overworld_statuses()
	_update_time_label()
	_tick_supply_step()
	_check_party_death()


## Check if all party members have died from status damage or other sources.
## If so, transition to the Bardo death screen.
func _check_party_death() -> void:
	var party := CharacterSystem.get_party()
	if party.is_empty():
		return
	var any_alive := false
	for char in party:
		var hp: int = char.get("derived", {}).get("current_hp", 1)
		if hp > 0:
			any_alive = true
			break
	if not any_alive:
		GameState.is_party_wiped = true
		_show_toast("Your party has perished...")
		await get_tree().create_timer(1.5).timeout
		_fade_and_goto("res://scenes/ui/bardo_screen.tscn")


## Apply one tick of any persisting DoT statuses (Poison, Bleed, Burn, etc.)
## Called once per step. Removes expired statuses. Shows a toast per damage tick.
func _tick_overworld_statuses() -> void:
	var party = CharacterSystem.get_party()
	for char in party:
		var statuses: Array = char.get("overworld_statuses", [])
		if statuses.is_empty():
			continue
		var expired: Array = []
		for i in range(statuses.size()):
			var s = statuses[i]
			var dmg: int = s.get("damage_per_step", 3)
			var derived: Dictionary = char.get("derived", {})
			var hp: int = derived.get("current_hp", derived.get("max_hp", 10))
			hp = max(0, hp - dmg)
			derived["current_hp"] = hp
			_show_toast("%s: %s −%d HP" % [char.get("name", "?"), s.get("status", "?"), dmg])
			s["duration"] -= 1
			if s["duration"] <= 0:
				expired.append(i)
		# Remove expired (reverse to keep indices valid)
		expired.reverse()
		for idx in expired:
			statuses.remove_at(idx)


## Process one step's worth of supply consumption and passive effects.
## Called from _on_party_moved after status ticks.
## Food and herbs are no longer consumed per step — they are consumed only at rest.
func _tick_supply_step() -> void:
	var party := CharacterSystem.get_party()
	if party.is_empty():
		return

	var best_logistics := 0
	var best_smithing  := 0
	var best_alchemy   := 0

	for char in party:
		var skills: Dictionary = char.get("skills", {})
		best_logistics = maxi(best_logistics, int(skills.get("logistics", 0)))
		best_smithing  = maxi(best_smithing,  int(skills.get("smithing",  0)))
		best_alchemy   = maxi(best_alchemy,   int(skills.get("alchemy",   0)))

	# --- Scrap: Smithing passive repair ---
	GameState.process_scrap_step(best_smithing, best_logistics)

	# --- Reagents: Alchemy passive brewing ---
	if best_alchemy > 0:
		var unlocked := _get_unlocked_alchemy_items(party)
		if not unlocked.is_empty():
			var brewed: String = GameState.process_alchemy_step(best_alchemy, best_logistics, unlocked)
			if not brewed.is_empty():
				ItemSystem.add_to_inventory(brewed)
				var item_data := ItemSystem.get_item(brewed)
				_show_toast("Alchemy: brewed %s!" % item_data.get("name", brewed))


## Build the list of item IDs any party member can brew based on their perks.
## Loads and caches the alchemy_crafting_tiers table from supplies.json.
func _get_unlocked_alchemy_items(party: Array) -> Array:
	if _alchemy_tiers_cache.is_empty():
		var path := "res://resources/data/supplies.json"
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_alchemy_tiers_cache = json.get_data().get("alchemy_crafting_tiers", {})
			file.close()

	var unlocked: Array[String] = []
	for category in _alchemy_tiers_cache:
		var cat_data: Dictionary = _alchemy_tiers_cache[category]
		for tier_key in ["tier_1", "tier_2", "tier_3"]:
			var tier: Dictionary = cat_data.get(tier_key, {})
			if tier.is_empty():
				continue
			var required_perk: String = tier.get("perk", "")
			var any_has_perk := false
			for char in party:
				if PerkSystem.has_perk(char, required_perk):
					any_has_perk = true
					break
			if any_has_perk:
				for item_id in tier.get("items", []):
					unlocked.append(str(item_id))
	return unlocked


## Hook for rest perks — called for each character after healing/decay. Empty for now.
func _process_rest_perks(_character: Dictionary, _tier: int) -> void:
	pass


## Restore durability on all equipped items for all party members by the given fraction.
## Only works on runtime items (generated weapons/armor) that track durability.
func _restore_party_durability(restore_pct: float) -> void:
	var party := CharacterSystem.get_party()
	var armor_slots: Array[String] = ["head", "chest", "hand_l", "hand_r", "legs", "feet"]
	for char in party:
		var equipment: Dictionary = char.get("equipment", {})
		# Armor slots
		for slot in armor_slots:
			var item_id: String = equipment.get(slot, "")
			if item_id.is_empty():
				continue
			var item_data: Dictionary = ItemSystem.get_item(item_id)
			var max_dur: int = int(item_data.get("max_durability", 0))
			if max_dur <= 0:
				continue
			var cur_dur: int = int(item_data.get("durability", max_dur))
			var restored: int = mini(max_dur, cur_dur + maxi(1, int(max_dur * restore_pct)))
			ItemSystem.update_item_durability(item_id, restored)
		# Weapon sets
		for set_key in ["weapon_set_1", "weapon_set_2"]:
			var ws: Dictionary = equipment.get(set_key, {})
			for sub in ["main", "off"]:
				var item_id: String = ws.get(sub, "")
				if item_id.is_empty():
					continue
				var item_data: Dictionary = ItemSystem.get_item(item_id)
				var max_dur: int = int(item_data.get("max_durability", 0))
				if max_dur <= 0:
					continue
				var cur_dur: int = int(item_data.get("durability", max_dur))
				var restored: int = mini(max_dur, cur_dur + maxi(1, int(max_dur * restore_pct)))
				ItemSystem.update_item_durability(item_id, restored)


## Opens the rest popup. Computes costs from current party + skills.
func _open_rest_panel() -> void:
	if _rest_open or _event_open or _shop_open or _quest_board_open or _main_menu_open or _char_sheet_open:
		return

	_rest_open = true
	rest_button.disabled = true

	var party := CharacterSystem.get_party()
	var party_size := party.size()

	# Best skills across party (medicine not needed here — _do_rest computes it independently)
	var best_logistics := 0
	var best_smithing  := 0
	var best_yoga      := 0
	var best_ritual    := 0
	for char in party:
		var sk: Dictionary = char.get("skills", {})
		best_logistics = maxi(best_logistics, int(sk.get("logistics", 0)))
		best_smithing  = maxi(best_smithing,  int(sk.get("smithing",  0)))
		best_yoga      = maxi(best_yoga,      int(sk.get("yoga",      0)))
		best_ritual    = maxi(best_ritual,    int(sk.get("ritual",    0)))

	var food_discount: int       = best_logistics / 3
	var herb_scrap_discount: int = best_logistics / 4

	# Costs per tier [1, 2, 3]
	var food_costs: Array[int]  = [
		maxi(1, 2 - food_discount) * party_size,
		maxi(1, 4 - food_discount) * party_size,
		maxi(1, 6 - food_discount) * party_size,
	]
	var herbs_costs: Array[int] = [0, maxi(0, 2 - herb_scrap_discount), maxi(0, 4 - herb_scrap_discount)]
	var scrap_costs: Array[int] = [
		0,
		maxi(0, 2 - herb_scrap_discount) + (best_smithing / 3),
		maxi(0, 4 - herb_scrap_discount) + (best_smithing / 3),
	]
	var tier_names: Array[String]    = ["Quick Rest", "Camp", "Full Rest"]
	var tier_restores: Array[String] = ["40% HP/Mana/Stamina", "70% HP/Mana/Stamina", "Full HP/Mana/Stamina"]
	var tier_pressure: Array[String] = ["+20 pressure decay", "+40 pressure decay", "Full pressure reset"]

	# Build panel on a CanvasLayer above the HUD
	_rest_layer = CanvasLayer.new()
	_rest_layer.layer = 28
	add_child(_rest_layer)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	_rest_layer.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rest_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var panel_style = UIStyle.make_stylebox(Color(0.3, 0.45, 0.35), 2, 10, 28, 0.9)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "REST"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Build three tier buttons
	for i in range(3):
		var tier: int = i + 1
		var can_afford: bool = GameState.food >= food_costs[i]
		if tier >= 2:
			can_afford = can_afford and GameState.herbs >= herbs_costs[i] and GameState.scrap >= scrap_costs[i]

		var tier_btn := Button.new()
		var cost_parts: Array[String] = ["Food: %d" % food_costs[i]]
		if tier >= 2:
			cost_parts.append("Herbs: %d" % herbs_costs[i])
			cost_parts.append("Scrap: %d" % scrap_costs[i])
		var cost_str := " | ".join(cost_parts)
		tier_btn.text = "%s\n%s\n%s  |  %s" % [tier_names[i], cost_str, tier_restores[i], tier_pressure[i]]
		tier_btn.custom_minimum_size = Vector2(0, 64)
		tier_btn.add_theme_font_size_override("font_size", 13)
		tier_btn.disabled = not can_afford
		if can_afford:
			var btn_style = UIStyle.make_stylebox(Color(0.25, 0.5, 0.3), 1, 6, 10)
			tier_btn.add_theme_stylebox_override("normal", btn_style)
			var hover_style = UIStyle.make_stylebox(Color(0.35, 0.65, 0.4), 1, 6, 10)
			tier_btn.add_theme_stylebox_override("hover", hover_style)
			tier_btn.pressed.connect(_confirm_rest.bind(tier))
		else:
			tier_btn.tooltip_text = "Cannot afford this rest tier"
		vbox.add_child(tier_btn)

	# === Sadhana section (Full Rest + practice, 50% recovery) ===
	var sad_sep := HSeparator.new()
	vbox.add_child(sad_sep)

	if best_yoga < 3:
		var no_yoga_lbl := Label.new()
		no_yoga_lbl.text = "Sadhana: requires Yoga 3"
		no_yoga_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		no_yoga_lbl.add_theme_font_size_override("font_size", 12)
		no_yoga_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_yoga_lbl)
	else:
		var sad_hdr := Label.new()
		sad_hdr.text = "Sadhana  (Full Rest • 50% recovery)"
		sad_hdr.add_theme_font_size_override("font_size", 12)
		sad_hdr.add_theme_color_override("font_color", Color(0.75, 0.65, 0.9))
		sad_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sad_hdr)

		# Approximate karma per yoga level (display only — full moon not factored in)
		var base_karma := 20 if best_yoga < 5 else (35 if best_yoga < 7 else 50)
		var roll_note  := " (chance)" if best_yoga < 7 else ""

		# Full-rest base costs shared by all sadhana tiers
		var full_food  := food_costs[2]
		var full_herbs := herbs_costs[2]
		var full_scrap := scrap_costs[2]
		var can_full   := GameState.food >= full_food and GameState.herbs >= full_herbs and GameState.scrap >= full_scrap

		# [extra_herbs, extra_reagents, mana_per_member, karma_bonus, min_ritual_sk, min_yoga_sk]
		var tiers := [
			[0, 0, 0,  0,  0, 3, "Yoga Practice"],
			[2, 0, 0,  15, 2, 3, "Smoke Offering"],
			[0, 2, 10, 30, 4, 3, "Torma Offering"],
			[0, 3, 15, 50, 6, 5, "Mandala Offering"],
		]
		for t in range(tiers.size()):
			var td        := tiers[t]
			var min_rit   := td[4] as int
			var min_yoga  := td[5] as int
			if best_yoga < min_yoga or best_ritual < min_rit:
				continue
			var xherbs    := td[0] as int
			var xreagents := td[1] as int
			var mana_cost := td[2] as int
			var karma_ttl := base_karma + (td[3] as int)
			var tier_name := td[6] as String

			var can_afford := can_full \
				and GameState.herbs    >= full_herbs + xherbs \
				and GameState.reagents >= xreagents

			var cost_parts: Array[String] = ["Food: %d" % full_food]
			var total_herbs := full_herbs + xherbs
			if total_herbs > 0:
				cost_parts.append("Herbs: %d" % total_herbs)
			if full_scrap > 0:
				cost_parts.append("Scrap: %d" % full_scrap)
			if xreagents > 0:
				cost_parts.append("Reagents: %d" % xreagents)
			if mana_cost > 0:
				cost_parts.append("-%d Mana each" % mana_cost)

			var purge_note := ""
			if best_yoga >= 5:
				purge_note = " + quirk purge"
				if t == 3:
					purge_note += " (easier)"

			var sad_btn := Button.new()
			sad_btn.text = "%s\n%s\n~%d karma%s%s" % [
				tier_name, " | ".join(cost_parts), karma_ttl, roll_note, purge_note
			]
			sad_btn.custom_minimum_size = Vector2(0, 64)
			sad_btn.add_theme_font_size_override("font_size", 12)
			sad_btn.disabled = not can_afford
			if can_afford:
				var bs := UIStyle.make_stylebox(Color(0.28, 0.18, 0.42), 1, 6, 10)
				var bh := UIStyle.make_stylebox(Color(0.42, 0.28, 0.62), 1, 6, 10)
				sad_btn.add_theme_stylebox_override("normal", bs)
				sad_btn.add_theme_stylebox_override("hover", bh)
				sad_btn.pressed.connect(_confirm_sadhana.bind(t))
			else:
				sad_btn.tooltip_text = "Cannot afford"
			vbox.add_child(sad_btn)

	var cancel_sep := HSeparator.new()
	vbox.add_child(cancel_sep)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel  [Esc]"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.pressed.connect(_close_rest_panel)
	vbox.add_child(cancel_btn)


## Called when a tier button is pressed. Closes panel then rests.
func _confirm_rest(tier: int) -> void:
	_close_rest_panel()
	_do_rest(tier)


## Close the rest panel.
func _close_rest_panel() -> void:
	_rest_open = false
	rest_button.disabled = false
	if is_instance_valid(_rest_layer):
		_rest_layer.queue_free()
		_rest_layer = null


## Called when a sadhana tier button is pressed.
func _confirm_sadhana(ritual_tier: int) -> void:
	_close_rest_panel()
	_do_sadhana(ritual_tier)


## Perform a sadhana practice during Full Rest.
## Costs Full-Rest resources + ritual materials; restores at 50%; purifies karma.
## ritual_tier: 0 (yoga only), 1 (smoke offering), 2 (torma), 3 (mandala)
func _do_sadhana(ritual_tier: int) -> void:
	var party := CharacterSystem.get_party()
	if party.is_empty():
		return

	# Best skills across party
	var best_yoga      := 0
	var best_ritual    := 0
	var best_logistics := 0
	var best_smithing  := 0
	for char in party:
		var sk: Dictionary = char.get("skills", {})
		best_yoga      = maxi(best_yoga,      int(sk.get("yoga",      0)))
		best_ritual    = maxi(best_ritual,    int(sk.get("ritual",    0)))
		best_logistics = maxi(best_logistics, int(sk.get("logistics", 0)))
		best_smithing  = maxi(best_smithing,  int(sk.get("smithing",  0)))

	if best_yoga < 3:
		return  # Guard — button should never be visible below Yoga 3

	# === Full-Rest base resource costs (same formula as _do_rest tier 3) ===
	var food_discount:      int = best_logistics / 3
	var herb_scrap_discount: int = best_logistics / 4
	var food_cost:  int = maxi(1, 6 - food_discount) * party.size()
	var herbs_cost: int = maxi(0, 4 - herb_scrap_discount)
	var scrap_cost: int = maxi(0, 4 - herb_scrap_discount) + (best_smithing / 3)

	# Ritual extra costs: [extra_herbs, extra_reagents, mana_per_member]
	const RITUAL_EXTRA: Array = [[0,0,0],[2,0,0],[0,2,10],[0,3,15]]
	var extra         := RITUAL_EXTRA[ritual_tier]
	var extra_herbs   := extra[0] as int
	var extra_reagents := extra[1] as int
	var mana_per      := extra[2] as int

	GameState.consume_supply("food",     food_cost)
	GameState.consume_supply("herbs",    herbs_cost + extra_herbs)
	GameState.consume_supply("scrap",    scrap_cost)
	if extra_reagents > 0:
		GameState.consume_supply("reagents", extra_reagents)

	# === Recovery at 50% (meditation cuts into sleep time) ===
	for char in party:
		var derived: Dictionary = char.get("derived", {})
		var max_hp:      int = int(derived.get("max_hp",      100))
		var max_mana:    int = int(derived.get("max_mana",     50))
		var max_stamina: int = int(derived.get("max_stamina",  50))
		derived["current_hp"]      = mini(max_hp,      int(derived.get("current_hp",      max_hp))      + floori(max_hp      * 0.5))
		derived["current_mana"]    = mini(max_mana,    int(derived.get("current_mana",    max_mana))    + floori(max_mana    * 0.5))
		derived["current_stamina"] = mini(max_stamina, int(derived.get("current_stamina", max_stamina)) + floori(max_stamina * 0.5))
		# Mana spent on ritual preparation (deducted after recovery)
		if mana_per > 0:
			derived["current_mana"] = maxi(0, int(derived.get("current_mana", 0)) - mana_per)

	# === Pressure decay at 1.5× full rest ===
	for char in party:
		PsychologySystem.decay_toward_baseline(char, 150.0)

	# === Karma purification ===
	var result: Dictionary = KarmaSystem.perform_purification(best_yoga, ritual_tier)

	# === Quirk purge (Yoga 5+; Mandala offering lowers difficulty by 2) ===
	var purged_quirk := ""
	var purged_char_name := ""
	if best_yoga >= 5:
		var player := CharacterSystem.get_player()
		var diff_mod := 2 if ritual_tier == 3 else 0
		# Yoga-purgeable quirks first
		for quirk_id in player.get("quirks", []).duplicate():
			if QuirkSystem.try_purge(player, quirk_id, "yoga", diff_mod):
				purged_quirk     = QuirkSystem.get_quirk_name(quirk_id)
				purged_char_name = player.get("name", "")
				break
	# Ritual-only quirks (blood_handed, oath_breaker, lapsed…) at any ritual tier
	if purged_quirk.is_empty() and ritual_tier >= 1:
		var player := CharacterSystem.get_player()
		var diff_mod := 2 if ritual_tier == 3 else 0
		for quirk_id in player.get("quirks", []).duplicate():
			var q := QuirkSystem.get_quirk(quirk_id)
			var purgeable: Array = q.get("purgeable_by", [])
			if "ritual" in purgeable and not "yoga" in purgeable:
				if QuirkSystem.try_purge(player, quirk_id, "ritual", diff_mod):
					purged_quirk     = QuirkSystem.get_quirk_name(quirk_id)
					purged_char_name = player.get("name", "")
					break

	# === Durability restore (full smithing scaling — you had downtime) ===
	var smithing_pct: float = best_smithing * 0.05
	if smithing_pct > 0.0:
		_restore_party_durability(smithing_pct)

	# === Advance time ===
	GameState.advance_time(GameState.HOURS_PER_REST)

	# === Toast ===
	var day_str := "%s, %s" % [GameState.get_lunar_day_label(), GameState.get_time_of_day_label()]
	var toast: String
	if not result.success:
		toast = "Sadhana: the practice faltered — no karma purified. %s." % day_str
	elif result.total > 0:
		var realm_names: Array[String] = []
		for r in result.realms:
			realm_names.append((r.realm as String).replace("_", " ").capitalize())
		toast = "Sadhana: purified %d karma (%s). %s." % [result.total, ", ".join(realm_names), day_str]
	else:
		toast = "Sadhana complete — no harmful karma to purify. %s." % day_str
	if not purged_quirk.is_empty():
		toast += "\n%s has shed the '%s' trait." % [purged_char_name, purged_quirk]
	_show_toast(toast)
	_update_time_label()


## Perform a rest action for the party.
## tier: 1 (Quick Rest), 2 (Camp), 3 (Full Rest)
func _do_rest(tier: int) -> void:
	var party := CharacterSystem.get_party()
	if party.is_empty():
		return

	# Best skill levels in party
	var best_medicine  := 0
	var best_smithing  := 0
	var best_logistics := 0
	for char in party:
		var skills: Dictionary = char.get("skills", {})
		best_medicine  = maxi(best_medicine,  int(skills.get("medicine",  0)))
		best_smithing  = maxi(best_smithing,  int(skills.get("smithing",  0)))
		best_logistics = maxi(best_logistics, int(skills.get("logistics", 0)))

	# === Resource costs ===
	# Food: per-member flat cost, reduced by Logistics
	var food_discount_per_member: int = best_logistics / 3   # Logistics 3→1, 6→2, 9→3
	var herb_scrap_discount: int      = best_logistics / 4   # Logistics 4→1, 8→2
	var base_food_per_member: Array[int]  = [2, 4, 6]         # tier 1/2/3
	var base_herbs:           Array[int]  = [0, 2, 4]
	var base_scrap_camp:      Array[int]  = [0, 2, 4]          # base before smithing add

	var food_per_member: int = maxi(1, base_food_per_member[tier - 1] - food_discount_per_member)
	var food_cost:       int = food_per_member * party.size()
	var herbs_cost:      int = maxi(0, base_herbs[tier - 1] - herb_scrap_discount)
	# Scrap: base after logistics discount + extra for Smithing repairs
	var scrap_cost: int = maxi(0, base_scrap_camp[tier - 1] - herb_scrap_discount) \
	                      + (best_smithing / 3)

	# Consume resources
	GameState.consume_supply("food", food_cost)
	if tier >= 2:
		GameState.consume_supply("herbs", herbs_cost)
		GameState.consume_supply("scrap", scrap_cost)

	# === Healing ===
	# Base restore pct by tier; Medicine adds +2% per level
	var tier_base_pct: float  = [0.4, 0.7, 1.0][tier - 1]
	var medicine_bonus: float = best_medicine * 0.02
	var restore_pct: float    = tier_base_pct + medicine_bonus

	for char in party:
		var derived: Dictionary = char.get("derived", {})
		var max_hp:      int = int(derived.get("max_hp",      100))
		var max_mana:    int = int(derived.get("max_mana",     50))
		var max_stamina: int = int(derived.get("max_stamina",  50))
		# HP: overheal above max becomes temp_hp (absorbed first in combat)
		var new_hp: int = int(derived.get("current_hp", max_hp)) + floori(max_hp * restore_pct)
		if new_hp > max_hp:
			derived["temp_hp"]     = new_hp - max_hp
			derived["current_hp"]  = max_hp
		else:
			derived["current_hp"]  = new_hp
		derived["current_mana"]    = mini(max_mana,    int(derived.get("current_mana",    max_mana))    + floori(max_mana    * restore_pct))
		derived["current_stamina"] = mini(max_stamina, int(derived.get("current_stamina", max_stamina)) + floori(max_stamina * restore_pct))

		# === Pressure decay ===
		var decay_amount: float = [20.0, 40.0, 100.0][tier - 1]
		PsychologySystem.decay_toward_baseline(char, decay_amount)

		# === Perk hook ===
		_process_rest_perks(char, tier)

	# === Durability restore (tier 2+) ===
	if tier >= 2:
		var smithing_restore_pct: float = best_smithing * 0.05     # 5% per Smithing level
		var tier_max_pct: float          = [0.0, 0.2, 1.0][tier - 1]
		var actual_pct: float            = minf(tier_max_pct, smithing_restore_pct)
		if actual_pct > 0.0:
			_restore_party_durability(actual_pct)

	# === Advance time ===
	GameState.advance_time(GameState.HOURS_PER_REST)

	# === Toast ===
	var day_str := "%s, %s" % [GameState.get_lunar_day_label(), GameState.get_time_of_day_label()]
	_show_toast("Party rested. %s." % day_str)
	_update_time_label()


## Show a toast when the player casts a spell from the overworld spellbook.
func _on_overworld_spell_cast(spell_name: String, detail: String) -> void:
	_show_toast("%s: %s" % [spell_name, detail])


func _on_party_position_updated(_world_pos: Vector2) -> void:
	pass  # Camera update happens in _process


func _on_gold_changed(new_amount: int, _change: int) -> void:
	gold_label.text = "Gold: " + str(new_amount)


func _on_supply_changed(supply_type: String, new_amount: int, _change: int) -> void:
	match supply_type:
		"food":     food_label.text = "Food: " + str(new_amount)
		"herbs":    herbs_label.text = "Herbs: " + str(new_amount)
		"scrap":    scrap_label.text = "Scrap: " + str(new_amount)
		"reagents": reagents_label.text = "Reagents: " + str(new_amount)


func _on_discovery_made(_pos: Vector2i, discovery: Dictionary) -> void:
	# Reward is already applied by MapManager._check_discovery()
	_show_toast(discovery.get("message", "You found something!"))
	# Update gold display in case gold was found
	gold_label.text = "Gold: " + str(GameState.gold)


## Sample overworld terrain around a position for combat battle map generation
## Checks a 5x5 area and returns the dominant terrain type and all terrain counts
func _sample_terrain_context(center: Vector2i) -> Dictionary:
	var terrain_counts: Dictionary = {}  # Terrain type int -> count
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var pos = center + Vector2i(dx, dy)
			var t = MapManager.get_terrain(pos)
			terrain_counts[t] = terrain_counts.get(t, 0) + 1

	# Find dominant terrain (most common type in the sample area)
	var dominant = MapManager.Terrain.PLAINS
	var max_count = 0
	for t in terrain_counts:
		if terrain_counts[t] > max_count:
			max_count = terrain_counts[t]
			dominant = t

	return {
		"dominant": dominant,
		"counts": terrain_counts,
		"region": MapManager.get_region_at(center)
	}


func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	_toast_timer = TOAST_DURATION
	GameState.append_overworld_log(msg)


## Fires whenever the calendar day rolls over. Handles full moon and new moon effects.
func _on_day_changed(_new_day: int) -> void:
	_update_time_label()
	if GameState.is_full_moon():
		# Full Moon (15th lunar day): restore 20% mana to all party members
		for char in CharacterSystem.party:
			var derived: Dictionary = char.get("derived", {})
			var max_mana: int = int(derived.get("max_mana", 50))
			derived["current_mana"] = mini(max_mana, int(derived.get("current_mana", max_mana)) + floori(max_mana * 0.2))
		_show_toast("Full moon — the dharma light shines. The party's mana is partially restored.")
	elif GameState.is_new_moon():
		_show_toast("New moon — the realm grows darker. Spirits are restless tonight.")


## Spawn a floating text label above the party (screen-space, camera-independent).
## The party is always at screen center since the camera follows it.
func _spawn_floating_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(140, 0)

	var vp := get_viewport().get_visible_rect().size
	# Centre horizontally over the party; start just above the party icon
	label.position = Vector2(vp.x / 2.0 - 70.0, vp.y / 2.0 - 56.0)

	$HUDLayer.add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 52.0, 1.4)
	tween.tween_property(label, "modulate:a", 0.0, 1.4)
	tween.finished.connect(func(): label.queue_free())


# ============================================
# MAIN MENU OVERLAY (Esc)
# ============================================

## Build the Esc-activated pause/menu panel entirely in code
func _build_main_menu_panel() -> void:
	_main_menu_layer = CanvasLayer.new()
	_main_menu_layer.layer = 30  # Above everything else
	add_child(_main_menu_layer)

	# Dim background
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.65)
	_main_menu_layer.add_child(dimmer)

	# Center the panel
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_menu_layer.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var panel_style = UIStyle.make_stylebox(Color(0.45, 0.3, 0.55), 2, 10, 28, 0.85)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	_esc_main_panel = panel

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PAUSE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.45, 0.3, 0.55, 0.5))
	vbox.add_child(sep)

	# Helper to build styled buttons
	var btn_style_base = UIStyle.make_stylebox(Color(0.4, 0.28, 0.52), 1, 5, 10)
	btn_style_base.bg_color = Color(0.12, 0.08, 0.18)
	var btn_hover_style = btn_style_base.duplicate()
	btn_hover_style.bg_color = Color(0.2, 0.13, 0.28)
	btn_hover_style.border_color = Color(0.6, 0.45, 0.75)

	for btn_def in [
		["Save & Return to Title", "_on_main_menu_return_title"],
		["Save & Exit to Desktop", "_on_main_menu_exit_desktop"],
		["Abandon Run", "_on_main_menu_abandon"],
		["Settings", "_on_main_menu_settings"],
	]:
		var btn = Button.new()
		btn.text = btn_def[0]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 15)
		var ns = btn_style_base.duplicate()
		btn.add_theme_stylebox_override("normal", ns)
		btn.add_theme_stylebox_override("hover", btn_hover_style.duplicate())
		btn.add_theme_stylebox_override("pressed", btn_hover_style.duplicate())
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		if btn_def[1] == "":
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
		else:
			btn.pressed.connect(Callable(self, btn_def[1]))
		vbox.add_child(btn)
		# Keep a reference to the abandon button for two-click confirm
		if btn_def[0] == "Abandon Run":
			_abandon_btn = btn

	# Resume button
	var resume_sep = HSeparator.new()
	resume_sep.add_theme_color_override("separator", Color(0.45, 0.3, 0.55, 0.5))
	vbox.add_child(resume_sep)

	var resume_btn = Button.new()
	resume_btn.text = "Resume  [Esc]"
	resume_btn.custom_minimum_size = Vector2(0, 44)
	resume_btn.add_theme_font_size_override("font_size", 15)
	resume_btn.add_theme_stylebox_override("normal", btn_style_base.duplicate())
	resume_btn.add_theme_stylebox_override("hover", btn_hover_style.duplicate())
	resume_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	resume_btn.add_theme_color_override("font_hover_color", Color(0.7, 0.9, 0.7))
	resume_btn.pressed.connect(func():
		AudioManager.play("ui_click")
		_close_main_menu())
	vbox.add_child(resume_btn)

	# Start hidden
	_main_menu_layer.visible = false
	# Build the settings sub-panel (hidden until opened)
	_build_settings_panel()


func _build_log_panel() -> void:
	# Create a CanvasLayer so it floats above the map (layer 11 = above event overlay at 10)
	var log_layer := CanvasLayer.new()
	log_layer.layer = 11
	add_child(log_layer)

	# Intermediate full-rect Control required so that child anchor presets work correctly
	# (Control nodes cannot anchor relative to a CanvasLayer directly in Godot 4)
	# Must be MOUSE_FILTER_IGNORE — default STOP would block all clicks on the entire screen.
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_layer.add_child(root_ctrl)

	# Toggle button — bottom-right corner
	_log_toggle_btn = Button.new()
	_log_toggle_btn.text = "💬"
	_log_toggle_btn.tooltip_text = "Toggle message log"
	_log_toggle_btn.custom_minimum_size = Vector2(36, 36)
	_log_toggle_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_log_toggle_btn.position = Vector2(-44, -44)
	_log_toggle_btn.pressed.connect(_toggle_log_panel)
	root_ctrl.add_child(_log_toggle_btn)

	# Log panel — above the toggle button
	_log_panel = PanelContainer.new()
	_log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_log_panel.custom_minimum_size = Vector2(320, 240)
	_log_panel.position = Vector2(-328, -292)
	_log_panel.visible = false
	var lp_style := UIStyle.make_stylebox(Color(0.30, 0.25, 0.15), 2, 0, 8)
	lp_style.bg_color = Color(0.05, 0.04, 0.04, 0.90)
	lp_style.content_margin_top = 6
	lp_style.content_margin_bottom = 6
	_log_panel.add_theme_stylebox_override("panel", lp_style)
	root_ctrl.add_child(_log_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_child(scroll)

	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_log_list)

	# Connect to future log entries
	GameState.overworld_log_updated.connect(_on_overworld_log_updated)

	# Populate with any existing entries (e.g. after scene reload)
	for msg in GameState.overworld_log:
		_append_log_entry(msg)


func _toggle_log_panel() -> void:
	_log_panel_visible = not _log_panel_visible
	_log_panel.visible = _log_panel_visible


func _on_overworld_log_updated(msg: String) -> void:
	_append_log_entry(msg)


func _append_log_entry(msg: String) -> void:
	if not is_instance_valid(_log_list):
		return
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	_log_list.add_child(lbl)
	# Auto-scroll to bottom on next frame
	await get_tree().process_frame
	if not is_instance_valid(_log_list):
		return
	var scroll := _log_list.get_parent() as ScrollContainer
	if is_instance_valid(scroll):
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value


func _open_main_menu() -> void:
	_main_menu_open = true
	_main_menu_layer.visible = true
	MapManager.pause_movement()


func _close_main_menu() -> void:
	_main_menu_open = false
	_main_menu_layer.visible = false
	if not _event_open and not _char_sheet_open and not _shop_open:
		MapManager.resume_movement()


func _on_main_menu_return_title() -> void:
	AudioManager.play("ui_click")
	SaveManager.autosave()
	_close_main_menu()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _on_main_menu_exit_desktop() -> void:
	AudioManager.play("ui_click")
	SaveManager.autosave()
	get_tree().quit()


func _on_main_menu_abandon() -> void:
	AudioManager.play("ui_click")
	if not _abandon_confirm:
		# First click — ask for confirmation
		_abandon_confirm = true
		_abandon_timer = 3.0
		if _abandon_btn:
			_abandon_btn.text = "Abandon? Click again to confirm"
	else:
		# Second click — do it
		_abandon_confirm = false
		# Delete the current save slot and return to title
		SaveManager.delete_save(SaveManager.current_slot)
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _on_main_menu_settings() -> void:
	AudioManager.play("ui_click")
	if _esc_main_panel:
		_esc_main_panel.hide()
	if _esc_settings_panel:
		_esc_settings_panel.show()


func _on_settings_back() -> void:
	AudioManager.play("ui_click")
	if _esc_settings_panel:
		_esc_settings_panel.hide()
	if _esc_main_panel:
		_esc_main_panel.show()


## Build the settings sub-panel (SFX volume, etc.) inside the pause menu layer.
func _build_settings_panel() -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.visible = false
	_main_menu_layer.add_child(center)
	_esc_settings_panel = center

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
	var panel_style = UIStyle.make_stylebox(Color(0.45, 0.3, 0.55), 2, 10, 28, 0.85)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.85))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.45, 0.3, 0.55, 0.5))
	vbox.add_child(sep)

	# SFX Volume section
	var sfx_section = VBoxContainer.new()
	sfx_section.add_theme_constant_override("separation", 8)
	vbox.add_child(sfx_section)

	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume"
	sfx_label.add_theme_font_size_override("font_size", 15)
	sfx_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	sfx_section.add_child(sfx_label)

	var slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 10)
	sfx_section.add_child(slider_row)

	var slider = HSlider.new()
	slider.min_value = -24.0
	slider.max_value = 0.0
	slider.step = 1.0
	slider.value = AudioManager.sfx_volume_db
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_child(slider)

	var val_label = Label.new()
	val_label.text = _sfx_db_to_label(AudioManager.sfx_volume_db)
	val_label.add_theme_font_size_override("font_size", 13)
	val_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	val_label.custom_minimum_size.x = 44
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider_row.add_child(val_label)

	slider.value_changed.connect(func(v: float):
		AudioManager.sfx_volume_db = v
		val_label.text = _sfx_db_to_label(v))

	vbox.add_child(HSeparator.new())

	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(0, 44)
	back_btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_button_style(back_btn, Color(0.4, 0.28, 0.52), 1, 5, 10)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	back_btn.add_theme_color_override("font_hover_color", Color(0.7, 0.9, 0.7))
	back_btn.pressed.connect(_on_settings_back)
	vbox.add_child(back_btn)


func _sfx_db_to_label(db: float) -> String:
	if db <= -24.0:
		return "0%"
	var pct = int(((db + 24.0) / 24.0) * 100.0)
	return str(pct) + "%"
