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
@onready var terrain_label: Label = %TerrainLabel
@onready var char_sheet_button: Button = %CharSheetButton
@onready var toast_label: Label = %ToastLabel

# Event overlay controls (children of EventOverlay CanvasLayer)
@onready var event_dimmer: ColorRect = $EventOverlay/EventDimmer
@onready var event_display: Control = $EventOverlay/EventDisplay

# Character sheet overlay (child of CharSheetOverlay CanvasLayer)
@onready var char_sheet: Control = $CharSheetOverlay/MainMenu

# Toast fade timer
var _toast_timer: float = 0.0
const TOAST_DURATION: float = 3.0

# Track overlay state (since CanvasLayer has no .visible)
var _event_open: bool = false
var _char_sheet_open: bool = false

# Track current event object so we can remove it after the event chain completes
var _current_event_object: Dictionary = {}


func _ready() -> void:
	# Load the map if not already loaded (first launch or returning from combat)
	if MapManager.current_map_id.is_empty():
		MapManager.load_map("hell_01")

	# Handle return from combat - remove defeated mob
	if not GameState.last_defeated_mob_id.is_empty():
		MapManager.remove_mob(GameState.last_defeated_mob_id)
		GameState.last_defeated_mob_id = ""
		MapManager.resume_movement()

	# Connect MapManager signals for game loop triggers
	MapManager.event_triggered.connect(_on_event_triggered)
	MapManager.mob_combat_triggered.connect(_on_mob_combat_triggered)
	MapManager.mob_event_triggered.connect(_on_mob_event_triggered)
	MapManager.pickup_collected.connect(_on_pickup_collected)
	MapManager.portal_entered.connect(_on_portal_entered)
	MapManager.party_moved.connect(_on_party_moved)
	MapManager.party_position_updated.connect(_on_party_position_updated)

	# Connect gold changed for HUD updates
	GameState.gold_changed.connect(_on_gold_changed)

	# Connect event display close signal
	event_display.event_display_closed.connect(_on_event_display_closed)

	# Connect char sheet button and visibility sync
	char_sheet_button.pressed.connect(_toggle_char_sheet)
	char_sheet.visibility_changed.connect(_on_char_sheet_visibility_changed)

	# Ensure overlays start hidden
	_set_event_visible(false)
	_set_char_sheet_visible(false)

	# Initialize HUD
	_update_hud()

	# Center camera on party
	_update_camera()


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


func _unhandled_input(event: InputEvent) -> void:
	# C key toggles character sheet
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_toggle_char_sheet()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if _char_sheet_open:
				_toggle_char_sheet()
				get_viewport().set_input_as_handled()


func _update_camera() -> void:
	# party_world_position is already tile center (from _tile_to_world), no extra offset
	camera.position = MapManager.party_world_position


func _update_hud() -> void:
	var world_data = GameState.WORLDS.get(GameState.current_world, {})
	var map_name = MapManager.current_map_id.replace("_", " ").capitalize()
	realm_label.text = world_data.get("name", "Unknown") + " - " + map_name
	gold_label.text = "Gold: " + str(GameState.gold)
	_update_terrain_label()


func _update_terrain_label() -> void:
	var terrain_type = MapManager.tiles.get(MapManager.party_position, 0)
	var terrain_name = MapManager.TERRAIN_NAMES.get(terrain_type, "Unknown")
	var speed = MapManager.TERRAIN_SPEED.get(terrain_type, 1.0)
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
	event_display.show_event(event_id)


func _on_mob_event_triggered(_mob: Dictionary) -> void:
	# Event display is handled by _on_event_triggered (MapManager emits both signals
	# for friendly mobs). This handler exists for future mob-specific logic.
	pass


func _on_event_display_closed() -> void:
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
	MapManager.resume_movement()


# ============================================
# COMBAT HANDLING
# ============================================

func _on_mob_combat_triggered(mob: Dictionary) -> void:
	MapManager.pause_movement()
	GameState.pending_combat_mob = mob.duplicate(true)
	GameState.last_defeated_mob_id = mob.get("id", "")
	get_tree().change_scene_to_file("res://scenes/combat/combat_arena.tscn")


# ============================================
# PICKUP HANDLING
# ============================================

func _on_pickup_collected(obj: Dictionary, rewards: Array) -> void:
	var parts: Array[String] = []
	for reward in rewards:
		match reward.get("type", ""):
			"gold":
				parts.append("+" + str(reward.value) + " gold")
			"xp":
				parts.append("+" + str(reward.value) + " XP")
			"heal":
				parts.append("Healed " + str(reward.value) + "%")
			"mana":
				parts.append("Mana +" + str(reward.value) + "%")
			"item":
				parts.append(str(reward.value).replace("_", " ").capitalize())
			_:
				parts.append(str(reward.get("type", "?")))

	var msg = obj.get("name", "Pickup")
	if parts.size() > 0:
		msg += ": " + ", ".join(parts)
	_show_toast(msg)
	gold_label.text = "Gold: " + str(GameState.gold)


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
	_update_terrain_label()


func _on_party_position_updated(_world_pos: Vector2) -> void:
	pass  # Camera update happens in _process


func _on_gold_changed(new_amount: int, _change: int) -> void:
	gold_label.text = "Gold: " + str(new_amount)


func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	_toast_timer = TOAST_DURATION
