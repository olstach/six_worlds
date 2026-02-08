extends Node2D
## MapRenderer - Draws the overworld map using MapManager data
##
## Pure rendering node: reads MapManager state and paints colored rectangles
## for terrain, markers for objects/mobs, and the party indicator.
## Also handles click-to-move input.

# Terrain colors keyed by MapManager.Terrain enum values
const TERRAIN_COLORS: Dictionary = {
	0: Color(0.35, 0.55, 0.25),   # PLAINS - green grass
	1: Color(0.55, 0.45, 0.35),   # ROAD - brown
	2: Color(0.15, 0.35, 0.15),   # FOREST - dark green
	3: Color(0.5, 0.45, 0.3),     # HILLS - tan
	4: Color(0.4, 0.4, 0.45),     # MOUNTAINS - grey
	5: Color(0.2, 0.35, 0.6),     # WATER - blue
	6: Color(0.3, 0.4, 0.25),     # SWAMP - murky green
	7: Color(0.75, 0.65, 0.4),    # DESERT - sandy
	8: Color(0.85, 0.88, 0.92),   # SNOW - white-blue
	9: Color(0.85, 0.25, 0.1),    # LAVA - red-orange
	10: Color(0.5, 0.4, 0.3),     # BRIDGE - dark brown
	11: Color(0.7, 0.85, 0.95),   # ICE - light blue
	12: Color(0.8, 0.7, 0.45),    # SAND - pale yellow
	13: Color(0.45, 0.4, 0.38),   # RUINS - dark grey-brown
}

# Object marker colors
const EVENT_COLOR := Color(0.9, 0.85, 0.2)    # Yellow
const PICKUP_COLOR := Color(0.3, 0.8, 0.3)    # Green
const PORTAL_COLOR := Color(0.3, 0.85, 0.9)   # Cyan

# Mob marker colors
const FRIENDLY_COLOR := Color(0.3, 0.8, 0.4)  # Green
const HOSTILE_COLOR := Color(0.85, 0.2, 0.2)   # Red
const AGGRESSIVE_COLOR := Color(0.9, 0.5, 0.1) # Orange

# Party marker
const PARTY_COLOR := Color(1.0, 0.9, 0.3)      # Gold
const PARTY_OUTLINE := Color(0.2, 0.15, 0.05)  # Dark outline

# Path and hover
const PATH_COLOR := Color(1.0, 1.0, 0.5, 0.25) # Semi-transparent yellow
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent white
const FOG_COLOR := Color(0.05, 0.05, 0.08, 0.7) # Dark semi-transparent

# Grid line
const GRID_COLOR := Color(0.0, 0.0, 0.0, 0.15)

# Current tile the mouse is hovering over (-1,-1 means none)
var hover_tile: Vector2i = Vector2i(-1, -1)

# Pulsing animation for aggressive mobs
var _pulse_time: float = 0.0


func _ready() -> void:
	# Connect to MapManager signals to know when to redraw
	MapManager.party_position_updated.connect(_on_needs_redraw_vec2)
	MapManager.party_moved.connect(_on_needs_redraw_vec2i_vec2i)
	MapManager.party_arrived.connect(_on_needs_redraw_vec2i)
	MapManager.map_loaded.connect(_on_needs_redraw_string)
	MapManager.pickup_collected.connect(_on_needs_redraw_dict_array)
	MapManager.mob_met_player.connect(_on_needs_redraw_dict)
	MapManager.mob_started_pursuit.connect(_on_needs_redraw_dict)
	MapManager.mob_lost_pursuit.connect(_on_needs_redraw_dict)


# Signal callbacks that just trigger redraw (different signatures)
func _on_needs_redraw_vec2(_v: Vector2) -> void:
	queue_redraw()

func _on_needs_redraw_vec2i(_v: Vector2i) -> void:
	queue_redraw()

func _on_needs_redraw_vec2i_vec2i(_a: Vector2i, _b: Vector2i) -> void:
	queue_redraw()

func _on_needs_redraw_string(_s: String) -> void:
	queue_redraw()

func _on_needs_redraw_dict(_d: Dictionary) -> void:
	queue_redraw()

func _on_needs_redraw_dict_array(_d: Dictionary, _a: Array) -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	# Redraw every frame during movement for smooth animation
	if MapManager._is_moving or not MapManager.mobs.is_empty():
		queue_redraw()

	# Continuous arrow key movement: queue next tile when party stops moving
	if not MapManager._is_moving and not MapManager._is_paused:
		var dir := Vector2i.ZERO
		if Input.is_key_pressed(KEY_UP):
			dir = Vector2i(0, -1)
		elif Input.is_key_pressed(KEY_DOWN):
			dir = Vector2i(0, 1)
		elif Input.is_key_pressed(KEY_LEFT):
			dir = Vector2i(-1, 0)
		elif Input.is_key_pressed(KEY_RIGHT):
			dir = Vector2i(1, 0)
		if dir != Vector2i.ZERO:
			var target = MapManager.party_position + dir
			if _is_valid_tile(target):
				MapManager.set_destination(target)


func _unhandled_input(event: InputEvent) -> void:
	# Mouse click to set destination
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tile = _mouse_to_tile()
		if _is_valid_tile(tile):
			MapManager.set_destination(tile)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var new_hover = _mouse_to_tile()
		if new_hover != hover_tile:
			hover_tile = new_hover
			queue_redraw()


func _is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < MapManager.map_size.x and tile.y >= 0 and tile.y < MapManager.map_size.y


func _mouse_to_tile() -> Vector2i:
	# Convert screen mouse position to world coordinates accounting for Camera2D
	var canvas_transform = get_viewport().get_canvas_transform()
	var screen_pos = get_viewport().get_mouse_position()
	var world_pos = canvas_transform.affine_inverse() * screen_pos
	var ts = MapManager.tile_size
	return Vector2i(int(world_pos.x / ts), int(world_pos.y / ts))


func _draw() -> void:
	var ts = MapManager.tile_size
	var map_w = MapManager.map_size.x
	var map_h = MapManager.map_size.y

	if MapManager.tiles.is_empty():
		return

	# --- Layer 1: Terrain tiles ---
	for y in range(map_h):
		for x in range(map_w):
			var pos = Vector2i(x, y)
			var terrain_type = MapManager.tiles.get(pos, 0)
			var color = TERRAIN_COLORS.get(terrain_type, TERRAIN_COLORS[0])
			var rect = Rect2(x * ts, y * ts, ts, ts)
			draw_rect(rect, color)
			# Grid lines
			draw_rect(rect, GRID_COLOR, false)
			# Terrain speed/passability overlay
			_draw_terrain_overlay(x, y, ts, MapManager.get_terrain_speed(pos))

	# --- Layer 2: Fog of war ---
	for y in range(map_h):
		for x in range(map_w):
			var pos = Vector2i(x, y)
			if not MapManager.is_tile_visited(pos):
				draw_rect(Rect2(x * ts, y * ts, ts, ts), FOG_COLOR)

	# --- Layer 3: Path highlight ---
	var remaining = MapManager.get_remaining_path()
	for tile_pos in remaining:
		draw_rect(Rect2(tile_pos.x * ts, tile_pos.y * ts, ts, ts), PATH_COLOR)

	# --- Layer 4: Map objects ---
	for obj_pos in MapManager.objects:
		var obj = MapManager.objects[obj_pos]
		# Skip if it's been collected already
		if obj.get("one_time", false) and obj.get("id", "") in MapManager.collected_objects:
			continue
		# Only draw if tile is visited (or near party)
		if not MapManager.is_tile_visited(obj_pos):
			continue
		var center = Vector2(obj_pos.x * ts + ts * 0.5, obj_pos.y * ts + ts * 0.5)
		var obj_type = obj.get("type", 0)
		_draw_object_marker(center, obj_type, ts)

	# --- Layer 5: Mobs ---
	for mob in MapManager.mobs:
		# Only draw if their tile is visited
		if not MapManager.is_tile_visited(mob.position):
			continue
		# world_position is already tile center (from _tile_to_world), no extra offset needed
		var center: Vector2 = mob.get("world_position", Vector2(mob.position.x * ts + ts * 0.5, mob.position.y * ts + ts * 0.5))
		var attitude = mob.get("attitude", 1)
		_draw_mob_marker(center, attitude, mob.get("is_pursuing", false), ts)

	# --- Layer 6: Party marker ---
	# party_world_position is already tile center (from _tile_to_world), no extra offset
	var party_center = MapManager.party_world_position
	# Outline
	draw_circle(party_center, ts * 0.35, PARTY_OUTLINE)
	# Fill
	draw_circle(party_center, ts * 0.3, PARTY_COLOR)

	# --- Layer 7: Hover highlight ---
	if hover_tile.x >= 0 and hover_tile.x < map_w and hover_tile.y >= 0 and hover_tile.y < map_h:
		draw_rect(Rect2(hover_tile.x * ts, hover_tile.y * ts, ts, ts), HOVER_COLOR, false, 2.0)


func _draw_object_marker(center: Vector2, obj_type: int, ts: int) -> void:
	var size = ts * 0.25
	match obj_type:
		0:  # EVENT - diamond
			var points = PackedVector2Array([
				center + Vector2(0, -size),
				center + Vector2(size, 0),
				center + Vector2(0, size),
				center + Vector2(-size, 0)
			])
			draw_colored_polygon(points, EVENT_COLOR)
		1:  # PICKUP - square
			draw_rect(Rect2(center.x - size * 0.7, center.y - size * 0.7, size * 1.4, size * 1.4), PICKUP_COLOR)
		2:  # PORTAL - circle
			draw_circle(center, size, PORTAL_COLOR)


func _draw_mob_marker(center: Vector2, attitude: int, is_pursuing: bool, ts: int) -> void:
	var radius = ts * 0.28
	var color: Color
	match attitude:
		0:  # FRIENDLY
			color = FRIENDLY_COLOR
		1:  # HOSTILE
			color = HOSTILE_COLOR
		2:  # AGGRESSIVE
			color = AGGRESSIVE_COLOR
			# Pulse effect when pursuing
			if is_pursuing:
				var pulse = (sin(_pulse_time * 4.0) + 1.0) * 0.5  # 0-1 oscillation
				radius *= 1.0 + pulse * 0.3
				color = color.lightened(pulse * 0.3)
		_:
			color = HOSTILE_COLOR

	# Draw mob as a circle with a dark outline
	draw_circle(center, radius + 1.5, Color(0.1, 0.1, 0.1))
	draw_circle(center, radius, color)


## Draw terrain overlay indicating passability/speed
## Called per-tile after the base terrain color is drawn
func _draw_terrain_overlay(x: int, y: int, ts: int, speed: float) -> void:
	if speed <= 0:
		# Impassable: X pattern (dark semi-transparent diagonal lines)
		var x0 = float(x * ts)
		var y0 = float(y * ts)
		var x1 = x0 + ts
		var y1 = y0 + ts
		var impass_color = Color(0, 0, 0, 0.3)
		draw_line(Vector2(x0, y0), Vector2(x1, y1), impass_color, 1.5)
		draw_line(Vector2(x1, y0), Vector2(x0, y1), impass_color, 1.5)
	elif speed < 1.0:
		# Slow/difficult: subtle dots pattern
		var base = Vector2(x * ts, y * ts)
		var dot_color = Color(0, 0, 0, 0.15)
		var dot_size = 2.0
		draw_circle(base + Vector2(ts * 0.25, ts * 0.25), dot_size, dot_color)
		draw_circle(base + Vector2(ts * 0.75, ts * 0.25), dot_size, dot_color)
		draw_circle(base + Vector2(ts * 0.25, ts * 0.75), dot_size, dot_color)
		draw_circle(base + Vector2(ts * 0.75, ts * 0.75), dot_size, dot_color)
	elif speed >= 1.25:
		# Fast: subtle center line (road/bridge/ice indicator)
		var mid_x = float(x * ts) + ts * 0.5
		var top_y = float(y * ts) + 4.0
		var bot_y = float(y * ts) + ts - 4.0
		draw_line(Vector2(mid_x, top_y), Vector2(mid_x, bot_y), Color(1, 1, 1, 0.2), 2.0)
