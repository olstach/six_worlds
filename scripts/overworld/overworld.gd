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

# Shop overlay CanvasLayer (shop_ui instanced dynamically)
@onready var shop_overlay: CanvasLayer = $ShopOverlay

# Toast fade timer
var _toast_timer: float = 0.0
const TOAST_DURATION: float = 3.0

# Track overlay state (since CanvasLayer has no .visible)
var _event_open: bool = false
var _char_sheet_open: bool = false
var _shop_open: bool = false

# Track current event object so we can remove it after the event chain completes
var _current_event_object: Dictionary = {}

# Shop instance and pending outcome (for event→shop flow)
var _shop_instance: Control = null
var _pending_shop_outcome: Dictionary = {}

# Preload shop scene for event→shop flow
var _shop_scene: PackedScene = preload("res://scenes/ui/shop_ui.tscn")


func _ready() -> void:
	# Load the map if not already loaded (first launch or returning from combat)
	if MapManager.current_map_id.is_empty():
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
			outcome["text"] = outcome.get("text", "") + "\n\n[b][color=#4ade80]VICTORY![/color][/b]"
		else:
			# Defeat — don't restore event object (so it stays on map for retry)
			outcome["text"] = outcome.get("text", "") + "\n\n[b][color=#ef4444]DEFEAT![/color][/b]\nYou retreat from the battle..."
		GameState.pending_event_object = {}

		# Show the event result panel
		_set_event_visible(true)
		event_display.display_outcome(outcome)
	elif not GameState.last_defeated_mob_id.is_empty():
		# Normal mob combat return — victory, remove defeated mob
		MapManager.remove_mob(GameState.last_defeated_mob_id)
		GameState.last_defeated_mob_id = ""
		MapManager.resume_movement()
	elif GameState.returning_from_combat:
		# Returning from combat without victory (fled or defeated) — just resume movement
		MapManager.resume_movement()

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

	# Connect gold changed for HUD updates
	GameState.gold_changed.connect(_on_gold_changed)

	# Connect discovery signal (hidden finds on ruins/forest/etc.)
	MapManager.discovery_made.connect(_on_discovery_made)

	# Connect event display close signal
	event_display.event_display_closed.connect(_on_event_display_closed)

	# Connect EventManager signals for event→combat and event→shop
	EventManager.combat_requested.connect(_on_event_combat_requested)
	EventManager.shop_requested.connect(_on_event_shop_requested)

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

	# Hide event display (keep it in memory for result after shop closes)
	event_display.visible = false

	# Instance and show shop
	_shop_instance = _shop_scene.instantiate()
	shop_overlay.add_child(_shop_instance)
	_shop_instance.shop_closed.connect(_on_event_shop_closed)
	_shop_open = true

	if not _shop_instance.open_shop_by_id(shop_id):
		print("Shop '%s' not found, closing shop overlay" % shop_id)
		_on_event_shop_closed()


## Shop closed after event→shop flow — show event result and Continue button
func _on_event_shop_closed() -> void:
	# Remove shop instance
	if _shop_instance:
		_shop_instance.queue_free()
		_shop_instance = null
	_shop_open = false

	# Show event result panel with shop outcome
	event_display.visible = true
	event_display.display_outcome(_pending_shop_outcome)
	_pending_shop_outcome = {}


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
