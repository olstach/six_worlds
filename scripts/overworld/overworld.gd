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
@onready var char_sheet_button: Button = %CharSheetButton
@onready var equipment_button: Button = %EquipmentButton
@onready var party_button: Button = %PartyButton
@onready var spellbook_button: Button = %SpellbookButton
@onready var crafting_button: Button = %CraftingButton
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
var _main_menu_open: bool = false

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

	# Connect discovery signal (hidden finds on ruins/forest/etc.)
	MapManager.discovery_made.connect(_on_discovery_made)

	# Connect event display close signal
	event_display.event_display_closed.connect(_on_event_display_closed)

	# Connect EventManager signals for event→combat and event→shop
	EventManager.combat_requested.connect(_on_event_combat_requested)
	EventManager.shop_requested.connect(_on_event_shop_requested)

	# Connect companion overflow signal to show mastery popup
	CompanionSystem.companion_overflow.connect(_on_companion_overflow)

	# Connect char sheet button and visibility sync
	char_sheet_button.pressed.connect(func(): _open_char_sheet_to_tab(0))
	equipment_button.pressed.connect(func(): _open_char_sheet_to_tab(1))
	party_button.pressed.connect(func(): _open_char_sheet_to_tab(2))
	spellbook_button.pressed.connect(func(): _open_char_sheet_to_tab(3))
	crafting_button.pressed.connect(func(): _open_char_sheet_to_tab(4))
	char_sheet.visibility_changed.connect(_on_char_sheet_visibility_changed)

	# Ensure overlays start hidden
	_set_event_visible(false)
	_set_char_sheet_visible(false)

	# Build the Esc main menu overlay
	_build_main_menu_panel()

	# Initialize HUD
	_update_hud()

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
			KEY_ESCAPE:
				if _main_menu_open:
					_close_main_menu()
					get_viewport().set_input_as_handled()
				elif _char_sheet_open:
					_toggle_char_sheet()
					get_viewport().set_input_as_handled()
				elif not _event_open and not _shop_open:
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
	event_display.show_event(event_id, object.get("id", ""), object.get("one_time", false))


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

	# Hide event display (keep it in memory for result after shop closes)
	event_display.visible = false

	# Instance and show shop
	_shop_instance = _shop_scene.instantiate()
	shop_overlay.add_child(_shop_instance)
	_shop_instance.shop_closed.connect(_on_event_shop_closed)
	_shop_open = true

	var loc_data: Dictionary = _current_event_object.get("data", {}).duplicate()
	loc_data["_object_id"] = _current_event_object.get("id", "")
	if not _shop_instance.open_shop_by_id(shop_id, loc_data):
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
				parts.append("+" + str(rval) + " XP")
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
	_update_terrain_label()
	_tick_overworld_statuses()


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
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.05, 0.1)
	panel_style.border_color = Color(0.45, 0.3, 0.55)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(28)
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
	var btn_style_base = StyleBoxFlat.new()
	btn_style_base.bg_color = Color(0.12, 0.08, 0.18)
	btn_style_base.border_color = Color(0.4, 0.28, 0.52)
	btn_style_base.set_border_width_all(1)
	btn_style_base.set_corner_radius_all(5)
	btn_style_base.set_content_margin_all(10)

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
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.05, 0.1)
	panel_style.border_color = Color(0.45, 0.3, 0.55)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(28)
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
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.08, 0.18)
	btn_style.border_color = Color(0.4, 0.28, 0.52)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(5)
	btn_style.set_content_margin_all(10)
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.13, 0.28)
	btn_hover.border_color = Color(0.6, 0.45, 0.75)

	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(0, 44)
	back_btn.add_theme_font_size_override("font_size", 15)
	back_btn.add_theme_stylebox_override("normal", btn_style)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	back_btn.add_theme_color_override("font_hover_color", Color(0.7, 0.9, 0.7))
	back_btn.pressed.connect(_on_settings_back)
	vbox.add_child(back_btn)


func _sfx_db_to_label(db: float) -> String:
	if db <= -24.0:
		return "0%"
	var pct = int(((db + 24.0) / 24.0) * 100.0)
	return str(pct) + "%"
