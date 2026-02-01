extends Node2D
class_name CombatGrid
## CombatGrid - Manages the tactical combat grid
##
## Handles:
## - Grid rendering and tile display
## - Pathfinding for movement
## - Unit position tracking
## - Tile types (walkable, obstacles, etc.)

signal tile_clicked(grid_pos: Vector2i)
signal tile_hovered(grid_pos: Vector2i)

# Grid configuration
@export var grid_size: Vector2i = Vector2i(12, 8)
@export var tile_size: int = 64  # Pixels per tile

# Tile data: Dictionary of Vector2i -> GridTile
var tiles: Dictionary = {}

# Unit positions: Dictionary of Vector2i -> CombatUnit
var unit_positions: Dictionary = {}

# Visual layers
var tile_layer: Node2D
var highlight_layer: Node2D
var unit_layer: Node2D

# Highlight colors
const COLOR_MOVE_RANGE = Color(0.2, 0.5, 0.8, 0.4)
const COLOR_ATTACK_RANGE = Color(0.8, 0.2, 0.2, 0.4)
const COLOR_SPELL_RANGE = Color(0.6, 0.3, 0.8, 0.4)  # Purple for spell range
const COLOR_AOE_PREVIEW = Color(0.9, 0.5, 0.2, 0.5)  # Orange for AoE preview
const COLOR_SELECTED = Color(0.9, 0.9, 0.3, 0.5)
const COLOR_HOVER = Color(1.0, 1.0, 1.0, 0.3)

# Current highlights
var highlighted_tiles: Array[Vector2i] = []
var current_highlight_color: Color = COLOR_MOVE_RANGE

# Tile types
enum TileType { FLOOR, WALL, PIT, WATER }

# GridTile structure (named to avoid conflict with Godot's TileData)
class GridTile:
	var type: int = TileType.FLOOR
	var walkable: bool = true
	var movement_cost: int = 1
	var height: int = 0  # For future height system

	func _init(tile_type: int = TileType.FLOOR) -> void:
		type = tile_type
		match type:
			TileType.FLOOR:
				walkable = true
				movement_cost = 1
			TileType.WALL:
				walkable = false
				movement_cost = 999
			TileType.PIT:
				walkable = false
				movement_cost = 999
			TileType.WATER:
				walkable = true
				movement_cost = 2


func _ready() -> void:
	# Create visual layers
	tile_layer = Node2D.new()
	tile_layer.name = "TileLayer"
	add_child(tile_layer)

	highlight_layer = Node2D.new()
	highlight_layer.name = "HighlightLayer"
	add_child(highlight_layer)

	unit_layer = Node2D.new()
	unit_layer.name = "UnitLayer"
	add_child(unit_layer)

	# Initialize default grid
	_initialize_grid()
	_draw_grid()


## Initialize grid with default floor tiles
func _initialize_grid() -> void:
	tiles.clear()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			tiles[pos] = GridTile.new(TileType.FLOOR)


## Set up grid from a map definition
func setup_from_map(map_data: Dictionary) -> void:
	grid_size = map_data.get("size", Vector2i(12, 8))
	_initialize_grid()

	# Apply tile overrides from map data
	var tile_overrides = map_data.get("tiles", {})
	for pos_str in tile_overrides:
		var parts = pos_str.split(",")
		if parts.size() == 2:
			var pos = Vector2i(int(parts[0]), int(parts[1]))
			var tile_type = tile_overrides[pos_str]
			if pos in tiles:
				tiles[pos] = GridTile.new(tile_type)

	_draw_grid()


## Draw the grid visuals
func _draw_grid() -> void:
	# Clear existing
	for child in tile_layer.get_children():
		child.queue_free()

	# Draw each tile
	for pos in tiles:
		var tile_data = tiles[pos]
		var tile_visual = _create_tile_visual(pos, tile_data)
		tile_layer.add_child(tile_visual)


## Create visual representation of a tile
func _create_tile_visual(grid_pos: Vector2i, tile_data: GridTile) -> Control:
	var tile = ColorRect.new()
	tile.size = Vector2(tile_size - 2, tile_size - 2)
	tile.position = grid_to_world(grid_pos) + Vector2(1, 1)

	# Color based on tile type
	match tile_data.type:
		TileType.FLOOR:
			# Checkerboard pattern for visual clarity
			if (grid_pos.x + grid_pos.y) % 2 == 0:
				tile.color = Color(0.25, 0.22, 0.2)
			else:
				tile.color = Color(0.28, 0.25, 0.22)
		TileType.WALL:
			tile.color = Color(0.15, 0.15, 0.15)
		TileType.PIT:
			tile.color = Color(0.05, 0.05, 0.08)
		TileType.WATER:
			tile.color = Color(0.2, 0.3, 0.5)

	# Make clickable
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.gui_input.connect(_on_tile_input.bind(grid_pos))
	tile.mouse_entered.connect(_on_tile_mouse_entered.bind(grid_pos))

	return tile


## Handle tile input
func _on_tile_input(event: InputEvent, grid_pos: Vector2i) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(grid_pos)


## Handle tile hover
func _on_tile_mouse_entered(grid_pos: Vector2i) -> void:
	tile_hovered.emit(grid_pos)


# ============================================
# COORDINATE CONVERSION
# ============================================

## Convert grid position to world (pixel) position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)


## Convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))


## Get center of a tile in world coordinates
func get_tile_center(grid_pos: Vector2i) -> Vector2:
	return grid_to_world(grid_pos) + Vector2(tile_size / 2.0, tile_size / 2.0)


## Check if a grid position is valid
func is_valid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and \
		   grid_pos.y >= 0 and grid_pos.y < grid_size.y


# ============================================
# UNIT MANAGEMENT
# ============================================

## Place a unit on the grid
func place_unit(unit: Node, grid_pos: Vector2i) -> bool:
	if not is_valid_position(grid_pos):
		return false

	if unit_positions.has(grid_pos):
		push_warning("CombatGrid: Position already occupied")
		return false

	unit_positions[grid_pos] = unit
	unit.grid_position = grid_pos
	unit.position = get_tile_center(grid_pos)

	# Reparent to unit layer if not already
	if unit.get_parent() != unit_layer:
		if unit.get_parent():
			unit.get_parent().remove_child(unit)
		unit_layer.add_child(unit)

	return true


## Move a unit to a new position
func move_unit(unit: Node, target: Vector2i) -> bool:
	if not is_valid_position(target):
		return false

	if unit_positions.has(target):
		return false

	# Remove from old position
	var old_pos = unit.grid_position
	if unit_positions.has(old_pos):
		unit_positions.erase(old_pos)

	# Add to new position
	unit_positions[target] = unit
	unit.grid_position = target

	# Animate movement (simple for now)
	var tween = create_tween()
	tween.tween_property(unit, "position", get_tile_center(target), 0.2)

	return true


## Remove a unit from the grid
func remove_unit(unit: Node) -> void:
	var pos = unit.grid_position
	if unit_positions.has(pos) and unit_positions[pos] == unit:
		unit_positions.erase(pos)


## Get unit at a grid position
func get_unit_at(grid_pos: Vector2i) -> Node:
	return unit_positions.get(grid_pos, null)


## Check if a tile is occupied
func is_occupied(grid_pos: Vector2i) -> bool:
	return unit_positions.has(grid_pos)


# ============================================
# PATHFINDING & MOVEMENT RANGE
# ============================================

## Get all tiles reachable within movement range
func get_reachable_tiles(start: Vector2i, movement: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var frontier: Array = [[start, 0]]  # [position, cost]

	visited[start] = 0

	while not frontier.is_empty():
		var current = frontier.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		if cost <= movement and pos != start:
			# Don't include tiles with enemies (can't move through)
			var unit_at = get_unit_at(pos)
			if unit_at == null:
				reachable.append(pos)

		if cost >= movement:
			continue

		# Check neighbors (4-directional for now, can add diagonal later)
		for neighbor in _get_neighbors(pos):
			if not is_valid_position(neighbor):
				continue

			var tile_data = tiles.get(neighbor)
			if tile_data == null or not tile_data.walkable:
				continue

			var new_cost = cost + tile_data.movement_cost

			# Can move through friendly units but not stop on them
			var unit_at = get_unit_at(neighbor)
			if unit_at != null:
				# Can't move through enemies
				# TODO: Check team
				continue

			if not visited.has(neighbor) or visited[neighbor] > new_cost:
				visited[neighbor] = new_cost
				frontier.append([neighbor, new_cost])

		# Sort by cost (simple priority queue)
		frontier.sort_custom(func(a, b): return a[1] < b[1])

	return reachable


## Get neighboring tiles (4-directional)
func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1)
	]


## Get tiles within attack range
func get_attack_range_tiles(start: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var in_range: Array[Vector2i] = []

	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var pos = start + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Chebyshev distance (diagonal = 1)
			var dist = maxi(absi(x), absi(y))
			if dist >= min_range and dist <= max_range:
				in_range.append(pos)

	return in_range


## Find path between two points (A* pathfinding)
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not is_valid_position(start) or not is_valid_position(end):
		return []

	var open_set: Array = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, end)}

	while not open_set.is_empty():
		# Get node with lowest f_score
		var current = open_set[0]
		var lowest_f = f_score.get(current, INF)
		for node in open_set:
			var f = f_score.get(node, INF)
			if f < lowest_f:
				lowest_f = f
				current = node

		if current == end:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in _get_neighbors(current):
			if not is_valid_position(neighbor):
				continue

			var tile_data = tiles.get(neighbor)
			if tile_data == null or not tile_data.walkable:
				continue

			# Can't path through occupied tiles (except destination)
			if neighbor != end and is_occupied(neighbor):
				continue

			var tentative_g = g_score.get(current, INF) + tile_data.movement_cost

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, end)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []  # No path found


## Heuristic for A* (Manhattan distance)
func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Reconstruct path from A* result
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while current in came_from:
		current = came_from[current]
		path.push_front(current)
	return path


# ============================================
# HIGHLIGHTING
# ============================================

## Highlight tiles for movement range
func highlight_movement_range(tiles_to_highlight: Array[Vector2i]) -> void:
	clear_highlights()
	current_highlight_color = COLOR_MOVE_RANGE
	_show_highlights(tiles_to_highlight)


## Highlight tiles for attack range
func highlight_attack_range(tiles_to_highlight: Array[Vector2i]) -> void:
	clear_highlights()
	current_highlight_color = COLOR_ATTACK_RANGE
	_show_highlights(tiles_to_highlight)


## Highlight tiles for spell range
func highlight_spell_range(tiles_to_highlight: Array[Vector2i]) -> void:
	clear_highlights()
	current_highlight_color = COLOR_SPELL_RANGE
	_show_highlights(tiles_to_highlight)


## Show highlights on specified tiles
func _show_highlights(positions: Array[Vector2i]) -> void:
	highlighted_tiles = positions

	for pos in positions:
		var highlight = ColorRect.new()
		highlight.size = Vector2(tile_size - 2, tile_size - 2)
		highlight.position = grid_to_world(pos) + Vector2(1, 1)
		highlight.color = current_highlight_color
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_layer.add_child(highlight)


## Clear all highlights
func clear_highlights() -> void:
	highlighted_tiles.clear()
	for child in highlight_layer.get_children():
		child.queue_free()


## Highlight a single tile (e.g., for hover)
func highlight_tile(grid_pos: Vector2i, color: Color = COLOR_HOVER) -> void:
	# Remove existing hover highlight if any
	for child in highlight_layer.get_children():
		if child.has_meta("hover"):
			child.queue_free()

	if not is_valid_position(grid_pos):
		return

	var highlight = ColorRect.new()
	highlight.size = Vector2(tile_size - 2, tile_size - 2)
	highlight.position = grid_to_world(grid_pos) + Vector2(1, 1)
	highlight.color = color
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.set_meta("hover", true)
	highlight_layer.add_child(highlight)


## Show AoE preview circle around a position
func show_aoe_preview(center: Vector2i, radius: int) -> void:
	# Remove existing AoE preview
	clear_aoe_preview()

	if not is_valid_position(center):
		return

	# Highlight all tiles within radius
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = center + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Chebyshev distance
			var dist = maxi(absi(x), absi(y))
			if dist <= radius:
				var highlight = ColorRect.new()
				highlight.size = Vector2(tile_size - 2, tile_size - 2)
				highlight.position = grid_to_world(pos) + Vector2(1, 1)
				highlight.color = COLOR_AOE_PREVIEW
				highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
				highlight.set_meta("aoe_preview", true)
				highlight_layer.add_child(highlight)


## Clear AoE preview highlights
func clear_aoe_preview() -> void:
	for child in highlight_layer.get_children():
		if child.has_meta("aoe_preview"):
			child.queue_free()


## Get tiles within a radius (for AoE spells)
func get_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = center + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Chebyshev distance
			var dist = maxi(absi(x), absi(y))
			if dist <= radius:
				result.append(pos)

	return result
