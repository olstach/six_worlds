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
signal tile_right_clicked(grid_pos: Vector2i)
signal tile_hovered(grid_pos: Vector2i)
signal terrain_effect_triggered(grid_pos: Vector2i, effect: int, value: int)
signal terrain_effect_expired(grid_pos: Vector2i, effect: int)

# Grid configuration
@export var grid_size: Vector2i = Vector2i(48, 30)
@export var tile_size: int = 48  # Pixels per tile

# Tile data: Dictionary of Vector2i -> GridTile
var tiles: Dictionary = {}

# Unit positions: Dictionary of Vector2i -> CombatUnit
var unit_positions: Dictionary = {}

# Visual layers
var tile_layer: Node2D
var effect_layer: Node2D  # For terrain effects (fire, ice, etc.)
var obstacle_layer: Node2D  # For obstacle visuals (trees, rocks, etc.)
var highlight_layer: Node2D
var unit_layer: Node2D

# Highlight colors
const COLOR_MOVE_RANGE = Color(0.2, 0.5, 0.8, 0.4)
const COLOR_ATTACK_RANGE = Color(0.8, 0.2, 0.2, 0.4)
const COLOR_SPELL_RANGE = Color(0.6, 0.3, 0.8, 0.4)  # Purple for spell range
const COLOR_AOE_PREVIEW = Color(0.9, 0.5, 0.2, 0.5)  # Orange for AoE preview
const COLOR_SELECTED = Color(0.9, 0.9, 0.3, 0.5)
const COLOR_HOVER = Color(1.0, 1.0, 1.0, 0.3)

# Terrain effect colors (overlays)
const COLOR_EFFECT_FIRE = Color(1.0, 0.4, 0.1, 0.5)
const COLOR_EFFECT_ICE = Color(0.4, 0.7, 1.0, 0.5)
const COLOR_EFFECT_POISON = Color(0.4, 0.8, 0.2, 0.5)
const COLOR_EFFECT_ACID = Color(0.7, 0.9, 0.1, 0.5)
const COLOR_EFFECT_BLESSED = Color(1.0, 0.95, 0.6, 0.4)
const COLOR_EFFECT_CURSED = Color(0.3, 0.1, 0.3, 0.5)
const COLOR_EFFECT_WET = Color(0.2, 0.4, 0.85, 0.55)
const COLOR_EFFECT_STORMY = Color(0.55, 0.45, 0.75, 0.6)
const COLOR_EFFECT_VOID = Color(0.12, 0.04, 0.22, 0.72)
const COLOR_EFFECT_SMOKE = Color(0.55, 0.55, 0.55, 0.65)

# Current highlights
var highlighted_tiles: Array[Vector2i] = []
var current_highlight_color: Color = COLOR_MOVE_RANGE

# Deployment zone colors
const COLOR_DEPLOY_FRONT = Color(0.3, 0.6, 0.3, 0.4)  # Green for front line
const COLOR_DEPLOY_BACK = Color(0.3, 0.3, 0.6, 0.4)   # Blue for back line
const COLOR_DEPLOY_ENEMY = Color(0.6, 0.3, 0.3, 0.3)  # Red tint for enemy zone

# Deployment zone configuration
const PLAYER_DEPLOY_COLUMNS: int = 4  # 4 columns wide; start at grid_size.x/3 (centered)
const ENEMY_DEPLOY_COLUMNS: int = 4   # 4 columns wide; start at grid_size.x*2/3 - 4 (centered)

# Tile types (base terrain)
enum TileType { FLOOR, WALL, PIT, WATER, DIFFICULT }

# Terrain effects (hazards that can be on tiles)
enum TerrainEffect { NONE, FIRE, ICE, POISON, ACID, BLESSED, CURSED, WET, STORMY, VOID, SMOKE }

# Obstacle types (objects sitting on tiles that provide cover)
enum ObstacleType { NONE, TREE, ROCK, PILLAR, BARRICADE, FALLEN_TREE }

# Movement modes (affect height traversal rules)
enum MovementMode { NORMAL, LEVITATE, FLYING }

# Max tiles from the defender that an obstacle can be and still grant cover.
# Beyond this, the obstacle is "too far away to meaningfully hide behind".
const MAX_COVER_RADIUS: int = 3

# Cover bonus values per obstacle type (dodge bonus vs ranged attacks)
const OBSTACLE_COVER_BONUS: Dictionary = {
	ObstacleType.TREE: 15,
	ObstacleType.ROCK: 20,
	ObstacleType.PILLAR: 15,
	ObstacleType.BARRICADE: 15,
	ObstacleType.FALLEN_TREE: 10,
}

# Default HP per obstacle type (0 = indestructible)
const OBSTACLE_DEFAULT_HP: Dictionary = {
	ObstacleType.TREE: 20,
	ObstacleType.ROCK: 50,
	ObstacleType.PILLAR: 30,
	ObstacleType.BARRICADE: 16,
	ObstacleType.FALLEN_TREE: 28,
}

# Obstacle visual colors
const COLOR_OBSTACLE_TREE = Color(0.2, 0.55, 0.2)
const COLOR_OBSTACLE_ROCK = Color(0.45, 0.42, 0.38)
const COLOR_OBSTACLE_PILLAR = Color(0.6, 0.55, 0.4)
const COLOR_OBSTACLE_BARRICADE = Color(0.5, 0.35, 0.15)
const COLOR_OBSTACLE_FALLEN_TREE = Color(0.42, 0.28, 0.12)

# GridTile structure (named to avoid conflict with Godot's TileData)
class GridTile:
	var type: int = TileType.FLOOR
	var walkable: bool = true
	var movement_cost: int = 1
	var height: int = 0  # For height system (0 = ground level)
	var effect: int = TerrainEffect.NONE
	var effect_duration: int = 0  # Turns remaining, -1 = permanent
	var effect_value: int = 0  # Damage/heal amount
	var obstacle: int = 0  # ObstacleType enum - object on this tile
	var obstacle_hp: int = 0  # 0 = indestructible, >0 = destructible

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
			TileType.DIFFICULT:
				walkable = true
				movement_cost = 2

	func set_effect(new_effect: int, duration: int = -1, value: int = 0) -> void:
		effect = new_effect
		effect_duration = duration
		effect_value = value

	func clear_effect() -> void:
		effect = TerrainEffect.NONE
		effect_duration = 0
		effect_value = 0

	func has_effect() -> bool:
		return effect != TerrainEffect.NONE


func _ready() -> void:
	# Create visual layers
	tile_layer = Node2D.new()
	tile_layer.name = "TileLayer"
	add_child(tile_layer)

	effect_layer = Node2D.new()
	effect_layer.name = "EffectLayer"
	add_child(effect_layer)

	obstacle_layer = Node2D.new()
	obstacle_layer.name = "ObstacleLayer"
	add_child(obstacle_layer)

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
## Supports: "size" (Vector2i), "tiles" (dict of "x,y" -> TileType),
##           "effects" (array of {pos, effect, value}), "heights" (array of {pos, height})
func setup_from_map(map_data: Dictionary) -> void:
	grid_size = map_data.get("size", Vector2i(16, 10))
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

	# Apply terrain effects (fire, ice, poison, etc.)
	var effect_list = map_data.get("effects", [])
	for eff in effect_list:
		var pos = eff.get("pos", Vector2i(-1, -1))
		if is_valid_position(pos):
			add_terrain_effect(pos, eff.get("effect", TerrainEffect.NONE),
				-1, eff.get("value", 0))

	# Apply height overrides
	var height_list = map_data.get("heights", [])
	for h in height_list:
		var pos = h.get("pos", Vector2i(-1, -1))
		if is_valid_position(pos):
			set_tile_height(pos, h.get("height", 0))

	# Apply obstacles (trees, rocks, pillars, barricades)
	var obstacle_list = map_data.get("obstacles", [])
	for obs in obstacle_list:
		var pos = obs.get("pos", Vector2i(-1, -1))
		if is_valid_position(pos):
			set_tile_obstacle(pos, obs.get("obstacle", ObstacleType.NONE),
				obs.get("hp", -1))  # -1 means use default HP

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

	# Also refresh obstacle visuals
	_update_obstacle_visuals()


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

	# Height shading: lighter tiles for higher ground (+0.12 per height level)
	if tile_data.height > 0:
		tile.color = tile.color.lightened(tile_data.height * 0.12)
		# Subtle warm tint at height 2+ to make elevation pop visually
		if tile_data.height >= 2:
			tile.color = tile.color.lerp(Color(0.9, 0.85, 0.6), 0.1)

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
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			tile_right_clicked.emit(grid_pos)


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


## Check if a tile is walkable (valid, passable terrain, no blocking obstacle)
func is_tile_walkable(grid_pos: Vector2i) -> bool:
	if not is_valid_position(grid_pos):
		return false
	var tile = tiles.get(grid_pos, null)
	if tile == null:
		return false
	if not tile.walkable:
		return false
	if has_blocking_obstacle(grid_pos):
		return false
	return true


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
## movement_mode: MovementMode enum - affects height traversal and cost
func get_reachable_tiles(start: Vector2i, movement: int, movement_mode: int = MovementMode.NORMAL) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var frontier: Array = [[start, 0]]  # [position, cost]

	visited[start] = 0

	while not frontier.is_empty():
		var current = frontier.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		if cost <= movement and pos != start:
			# Don't include tiles with enemies or obstacles (can't move through)
			var unit_at = get_unit_at(pos)
			var tile_data = tiles.get(pos)
			var has_blocking_obstacle = tile_data != null and tile_data.obstacle != ObstacleType.NONE and tile_data.obstacle != ObstacleType.BARRICADE
			if unit_at == null and not has_blocking_obstacle:
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

			# Check height traversal (movement mode affects max climb)
			if not can_traverse_height(pos, neighbor, movement_mode):
				continue

			# Can't walk through obstacles (except barricades, and flyers/levitators ignore)
			if tile_data.obstacle != ObstacleType.NONE and tile_data.obstacle != ObstacleType.BARRICADE:
				if movement_mode == MovementMode.NORMAL:
					continue
				# Levitate and flying can pass over obstacles

			var new_cost = cost + tile_data.movement_cost

			# Add climbing cost: going UP costs +1 per height level
			# Going DOWN is free for normal and levitate; flying pays +1 for any height change
			var height_diff = get_tile_height(neighbor) - get_tile_height(pos)
			if height_diff > 0:
				# Climbing up — everyone pays +1 per level
				new_cost += height_diff
			elif height_diff < 0 and movement_mode == MovementMode.FLYING:
				# Flying pays +1 even going down (maintaining altitude control)
				new_cost += absi(height_diff)

			# All units block movement — formations matter
			if get_unit_at(neighbor) != null:
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


## Get tiles within attack range (Chebyshev distance = square shape, diagonals count as 1)
func get_attack_range_tiles(start: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var in_range: Array[Vector2i] = []

	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var pos = start + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Chebyshev distance (square shape — diagonals count as 1 step)
			var dist = maxi(absi(x), absi(y))
			if dist >= min_range and dist <= max_range:
				in_range.append(pos)

	return in_range


## Get tiles in spell range (Manhattan/diamond distance — traditional for spells)
func get_spell_range_tiles(start: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var in_range: Array[Vector2i] = []

	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var pos = start + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Manhattan distance (diamond shape)
			var dist = absi(x) + absi(y)
			if dist >= min_range and dist <= max_range:
				in_range.append(pos)

	return in_range


## Find path between two points (A* pathfinding)
## movement_mode: MovementMode enum - affects height traversal and cost
func find_path(start: Vector2i, end: Vector2i, movement_mode: int = MovementMode.NORMAL) -> Array[Vector2i]:
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

			# Check height traversal (movement mode affects max climb)
			if not can_traverse_height(current, neighbor, movement_mode):
				continue

			# Can't path through obstacles (except barricades, flyers/levitators can pass)
			if tile_data.obstacle != ObstacleType.NONE and tile_data.obstacle != ObstacleType.BARRICADE:
				if movement_mode == MovementMode.NORMAL:
					if neighbor != end:
						continue
				# Levitate/flying can path over obstacles

			# Can't path through occupied tiles (except destination)
			if neighbor != end and is_occupied(neighbor):
				continue

			var tentative_g = g_score.get(current, INF) + tile_data.movement_cost

			# Add climbing cost
			var height_diff = get_tile_height(neighbor) - get_tile_height(current)
			if height_diff > 0:
				tentative_g += height_diff
			elif height_diff < 0 and movement_mode == MovementMode.FLYING:
				tentative_g += absi(height_diff)

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


## Highlight full range area (dim) plus valid targets (bright)
func highlight_spell_range_and_area(range_tiles: Array[Vector2i], target_tiles: Array[Vector2i]) -> void:
	clear_highlights()
	# Dim highlight for the full range area
	var dim_color = Color(COLOR_SPELL_RANGE.r, COLOR_SPELL_RANGE.g, COLOR_SPELL_RANGE.b, 0.15)
	for pos in range_tiles:
		var highlight = ColorRect.new()
		highlight.size = Vector2(tile_size - 2, tile_size - 2)
		highlight.position = grid_to_world(pos) + Vector2(1, 1)
		highlight.color = dim_color
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_layer.add_child(highlight)
	# Bright highlight for actual targets
	current_highlight_color = COLOR_SPELL_RANGE
	for pos in target_tiles:
		var highlight = ColorRect.new()
		highlight.size = Vector2(tile_size - 2, tile_size - 2)
		highlight.position = grid_to_world(pos) + Vector2(1, 1)
		highlight.color = COLOR_SPELL_RANGE
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_layer.add_child(highlight)
	highlighted_tiles = target_tiles


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

	# Highlight all tiles within radius (Manhattan distance = diamond)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = center + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Manhattan distance (diamond shape)
			var dist = absi(x) + absi(y)
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


## Get tiles within a radius (for AoE spells, Manhattan distance = diamond)
func get_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = center + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Manhattan distance (diamond shape)
			var dist = absi(x) + absi(y)
			if dist <= radius:
				result.append(pos)

	return result


# ============================================
# TERRAIN EFFECTS
# ============================================

## Add a terrain effect to a tile
func add_terrain_effect(grid_pos: Vector2i, effect: int, duration: int = 3, value: int = 0) -> void:
	if not is_valid_position(grid_pos):
		return

	var tile = tiles.get(grid_pos)
	if tile == null:
		return

	# Set default values based on effect type
	if value == 0:
		match effect:
			TerrainEffect.FIRE:
				value = 5  # Fire damage per turn
			TerrainEffect.ICE:
				value = 0  # Ice slows movement
			TerrainEffect.POISON:
				value = 3  # Poison damage per turn
			TerrainEffect.ACID:
				value = 4  # Acid damage per turn
			TerrainEffect.BLESSED:
				value = 3  # Healing per turn
			TerrainEffect.CURSED:
				value = 2  # Damage per turn
			TerrainEffect.WET:
				value = 0  # No damage, slows and grants water vulnerability
			TerrainEffect.STORMY:
				value = 3  # Air damage per turn, stun chance
			TerrainEffect.VOID:
				value = 5  # Space damage per turn

	tile.set_effect(effect, duration, value)

	# Update movement cost for ice/wet terrain
	if effect == TerrainEffect.ICE or effect == TerrainEffect.WET:
		tile.movement_cost = 2

	_update_effect_visuals()


## Remove terrain effect from a tile
func remove_terrain_effect(grid_pos: Vector2i) -> void:
	if not is_valid_position(grid_pos):
		return

	var tile = tiles.get(grid_pos)
	if tile == null:
		return

	var old_effect = tile.effect
	tile.clear_effect()

	# Restore movement cost
	match tile.type:
		TileType.FLOOR:
			tile.movement_cost = 1
		TileType.WATER, TileType.DIFFICULT:
			tile.movement_cost = 2

	terrain_effect_expired.emit(grid_pos, old_effect)
	_update_effect_visuals()


## Process terrain effects at start of a turn (tick durations, return affected tiles)
func tick_terrain_effects() -> Array[Vector2i]:
	var expired_tiles: Array[Vector2i] = []

	for pos in tiles:
		var tile = tiles[pos]
		if not tile.has_effect():
			continue

		# Check if permanent (-1 duration)
		if tile.effect_duration == -1:
			continue

		# Decrement duration
		tile.effect_duration -= 1

		if tile.effect_duration <= 0:
			expired_tiles.append(pos)

	# Remove expired effects
	for pos in expired_tiles:
		remove_terrain_effect(pos)

	_update_effect_visuals()
	return expired_tiles


## Get terrain effect at position
func get_terrain_effect(grid_pos: Vector2i) -> Dictionary:
	if not is_valid_position(grid_pos):
		return {}

	var tile = tiles.get(grid_pos)
	if tile == null or not tile.has_effect():
		return {}

	return {
		"effect": tile.effect,
		"duration": tile.effect_duration,
		"value": tile.effect_value
	}


## Check if a tile has a damaging effect
func has_damaging_effect(grid_pos: Vector2i) -> bool:
	var tile = tiles.get(grid_pos)
	if tile == null:
		return false

	return tile.effect in [TerrainEffect.FIRE, TerrainEffect.POISON, TerrainEffect.ACID, TerrainEffect.CURSED, TerrainEffect.STORMY, TerrainEffect.VOID]


## Check if a tile has a beneficial effect
func has_beneficial_effect(grid_pos: Vector2i) -> bool:
	var tile = tiles.get(grid_pos)
	if tile == null:
		return false

	return tile.effect == TerrainEffect.BLESSED


## Get effect name for display
func get_effect_name(effect: int) -> String:
	match effect:
		TerrainEffect.FIRE: return "Fire"
		TerrainEffect.ICE: return "Ice"
		TerrainEffect.POISON: return "Poison"
		TerrainEffect.ACID: return "Acid"
		TerrainEffect.BLESSED: return "Blessed Ground"
		TerrainEffect.CURSED: return "Cursed Ground"
		TerrainEffect.WET: return "Wet Ground"
		TerrainEffect.STORMY: return "Storm"
		TerrainEffect.VOID: return "Void Rift"
		TerrainEffect.SMOKE: return "Smoke"
		_: return ""


## Update visual display of terrain effects
func _update_effect_visuals() -> void:
	# Clear existing effect visuals
	for child in effect_layer.get_children():
		child.queue_free()

	# Draw effect overlays
	for pos in tiles:
		var tile = tiles[pos]
		if not tile.has_effect():
			continue

		var effect_visual = _create_effect_visual(pos, tile.effect)
		effect_layer.add_child(effect_visual)


## Create visual for a terrain effect — rotated diamond with pulsing alpha
func _create_effect_visual(grid_pos: Vector2i, effect: int) -> Control:
	# Container centered on the tile (holds the rotated diamond)
	var container = Control.new()
	container.size = Vector2(tile_size, tile_size)
	container.position = grid_to_world(grid_pos)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Diamond shape: a ColorRect rotated 45 degrees, ~45% of tile size
	var diamond_size = tile_size * 0.45
	var diamond = ColorRect.new()
	diamond.size = Vector2(diamond_size, diamond_size)
	# Center the diamond in the tile, accounting for rotation pivot
	diamond.position = Vector2(tile_size / 2.0, tile_size / 2.0)
	diamond.pivot_offset = Vector2(diamond_size / 2.0, diamond_size / 2.0)
	diamond.position -= diamond.pivot_offset
	diamond.rotation_degrees = 45
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var color: Color
	match effect:
		TerrainEffect.FIRE:
			color = COLOR_EFFECT_FIRE
		TerrainEffect.ICE:
			color = COLOR_EFFECT_ICE
		TerrainEffect.POISON:
			color = COLOR_EFFECT_POISON
		TerrainEffect.ACID:
			color = COLOR_EFFECT_ACID
		TerrainEffect.BLESSED:
			color = COLOR_EFFECT_BLESSED
		TerrainEffect.CURSED:
			color = COLOR_EFFECT_CURSED
		TerrainEffect.WET:
			color = COLOR_EFFECT_WET
		TerrainEffect.STORMY:
			color = COLOR_EFFECT_STORMY
		TerrainEffect.VOID:
			color = COLOR_EFFECT_VOID
		TerrainEffect.SMOKE:
			color = COLOR_EFFECT_SMOKE
		_:
			color = Color(0, 0, 0, 0)

	diamond.color = color
	container.add_child(diamond)

	# Pulsing alpha animation (looping between 0.3 and full alpha)
	var tween = container.create_tween()
	tween.set_loops()
	var base_alpha = color.a
	var low_alpha = base_alpha * 0.4
	tween.tween_property(diamond, "modulate:a", low_alpha, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(diamond, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	return container


## Add fire tiles in an area (e.g., from fireball)
func create_fire_area(center: Vector2i, radius: int, duration: int = 2) -> void:
	for pos in get_tiles_in_radius(center, radius):
		var tile = tiles.get(pos)
		if tile != null and tile.walkable:
			add_terrain_effect(pos, TerrainEffect.FIRE, duration, 5)


## Add ice tiles in an area (e.g., from blizzard)
func create_ice_area(center: Vector2i, radius: int, duration: int = 3) -> void:
	for pos in get_tiles_in_radius(center, radius):
		var tile = tiles.get(pos)
		if tile != null and tile.walkable:
			add_terrain_effect(pos, TerrainEffect.ICE, duration, 0)


## Add poison tiles in an area
func create_poison_area(center: Vector2i, radius: int, duration: int = 3) -> void:
	for pos in get_tiles_in_radius(center, radius):
		var tile = tiles.get(pos)
		if tile != null and tile.walkable:
			add_terrain_effect(pos, TerrainEffect.POISON, duration, 3)


# ============================================
# LINE OF SIGHT
# ============================================

## Check if there's clear line of sight between two positions
## Walls block LoS, pits don't (can shoot over them)
func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if from_pos == to_pos:
		return true

	# Use Bresenham's line algorithm to check tiles along the path
	var tiles_in_line = _get_line_tiles(from_pos, to_pos)

	# Check each tile (excluding start and end)
	for i in range(1, tiles_in_line.size() - 1):
		var pos = tiles_in_line[i]
		if _blocks_line_of_sight(pos):
			return false

	return true


## Get all tiles along a line (Bresenham's algorithm)
func _get_line_tiles(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var x0 = from_pos.x
	var y0 = from_pos.y
	var x1 = to_pos.x
	var y1 = to_pos.y

	var dx = absi(x1 - x0)
	var dy = absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy

	while true:
		result.append(Vector2i(x0, y0))

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return result


## Check if a tile blocks line of sight
func _blocks_line_of_sight(grid_pos: Vector2i) -> bool:
	if not is_valid_position(grid_pos):
		return true  # Off-grid blocks LoS

	var tile = tiles.get(grid_pos)
	if tile == null:
		return true

	# Walls block LoS, pits and water don't; smoke also blocks LoS
	return tile.type == TileType.WALL or tile.effect == TerrainEffect.SMOKE


## Get valid ranged attack targets (within range AND has line of sight)
func get_ranged_attack_tiles(start: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var in_range: Array[Vector2i] = []

	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var pos = start + Vector2i(x, y)
			if not is_valid_position(pos):
				continue

			# Chebyshev distance (square shape — diagonals count as 1 step)
			var dist = maxi(absi(x), absi(y))
			if dist >= min_range and dist <= max_range:
				# Check line of sight
				if has_line_of_sight(start, pos):
					in_range.append(pos)

	return in_range


# ============================================
# HEIGHT SYSTEM
# ============================================

## Set tile height
func set_tile_height(grid_pos: Vector2i, height: int) -> void:
	if not is_valid_position(grid_pos):
		return

	var tile = tiles.get(grid_pos)
	if tile:
		tile.height = height


## Get tile height
func get_tile_height(grid_pos: Vector2i) -> int:
	if not is_valid_position(grid_pos):
		return 0

	var tile = tiles.get(grid_pos)
	return tile.height if tile else 0


## Check if unit can move between heights based on movement mode
## NORMAL: max 1 height difference
## LEVITATE: max 2 height difference (can also cross water/pits)
## FLYING: unlimited height difference
func can_traverse_height(from_pos: Vector2i, to_pos: Vector2i, movement_mode: int = MovementMode.NORMAL) -> bool:
	var from_height = get_tile_height(from_pos)
	var to_height = get_tile_height(to_pos)
	var diff = absi(to_height - from_height)

	match movement_mode:
		MovementMode.FLYING:
			return true  # Flying units can traverse any height
		MovementMode.LEVITATE:
			return diff <= 2  # Levitating units can climb up to 2 levels
		_:
			return diff <= 1  # Normal units max 1 level


## Get height advantage bonus (higher ground = +accuracy, +damage)
func get_height_advantage(attacker_pos: Vector2i, target_pos: Vector2i) -> int:
	var attacker_height = get_tile_height(attacker_pos)
	var target_height = get_tile_height(target_pos)
	return attacker_height - target_height  # Positive = advantage, negative = disadvantage


## Get ranged attack range bonus from height (each height level = +1 range)
func get_height_range_bonus(attacker_pos: Vector2i, target_pos: Vector2i) -> int:
	var height_diff = get_height_advantage(attacker_pos, target_pos)
	# Only positive height difference gives range bonus
	return maxi(0, height_diff)


## Get accuracy bonus from height advantage (+5 per level above, -5 per level below)
func get_height_accuracy_bonus(attacker_pos: Vector2i, target_pos: Vector2i) -> int:
	return get_height_advantage(attacker_pos, target_pos) * 5


## Get damage bonus from height advantage (+1 per level above for ranged, +2 for melee)
func get_height_damage_bonus(attacker_pos: Vector2i, target_pos: Vector2i, is_ranged: bool) -> int:
	var advantage = get_height_advantage(attacker_pos, target_pos)
	if advantage <= 0:
		return 0
	return advantage * (1 if is_ranged else 2)


# ============================================
# OBSTACLE SYSTEM
# ============================================

## Place an obstacle on a tile
## hp: pass -1 to use default HP for the obstacle type
func set_tile_obstacle(grid_pos: Vector2i, obstacle_type: int, hp: int = -1) -> void:
	if not is_valid_position(grid_pos):
		return

	var tile = tiles.get(grid_pos)
	if tile == null:
		return

	tile.obstacle = obstacle_type
	if hp == -1:
		tile.obstacle_hp = OBSTACLE_DEFAULT_HP.get(obstacle_type, 0)
	else:
		tile.obstacle_hp = hp

	_update_obstacle_visuals()


## Remove an obstacle from a tile
func remove_obstacle(grid_pos: Vector2i) -> void:
	if not is_valid_position(grid_pos):
		return

	var tile = tiles.get(grid_pos)
	if tile == null:
		return

	tile.obstacle = ObstacleType.NONE
	tile.obstacle_hp = 0
	_update_obstacle_visuals()


## Get obstacle info at a position
func get_obstacle_at(grid_pos: Vector2i) -> Dictionary:
	if not is_valid_position(grid_pos):
		return {}

	var tile = tiles.get(grid_pos)
	if tile == null or tile.obstacle == ObstacleType.NONE:
		return {}

	return {
		"type": tile.obstacle,
		"name": get_obstacle_name(tile.obstacle),
		"hp": tile.obstacle_hp,
		"cover_bonus": OBSTACLE_COVER_BONUS.get(tile.obstacle, 0)
	}


## Check if a tile has an obstacle that blocks movement
func has_blocking_obstacle(grid_pos: Vector2i) -> bool:
	var tile = tiles.get(grid_pos)
	if tile == null:
		return false
	# Barricades don't block movement (units can stand on them)
	return tile.obstacle != ObstacleType.NONE and tile.obstacle != ObstacleType.BARRICADE


## Damage an obstacle. Returns true if destroyed.
## When destroyed, applies aftermath effects (tree -> fire terrain, rock -> difficult terrain)
signal obstacle_destroyed(grid_pos: Vector2i, obstacle_type: int)

func damage_obstacle(grid_pos: Vector2i, damage: int, damage_type: String = "physical") -> bool:
	var tile = tiles.get(grid_pos)
	if tile == null or tile.obstacle == ObstacleType.NONE:
		return false

	if tile.obstacle_hp <= 0:
		return false  # Indestructible

	tile.obstacle_hp -= damage
	if tile.obstacle_hp <= 0:
		var destroyed_type = tile.obstacle
		_on_obstacle_destroyed(grid_pos, destroyed_type, damage_type)
		return true

	return false


## Handle aftermath when an obstacle is destroyed
func _on_obstacle_destroyed(grid_pos: Vector2i, obstacle_type: int, damage_type: String) -> void:
	# Remove the obstacle first
	var tile = tiles.get(grid_pos)
	if tile:
		tile.obstacle = ObstacleType.NONE
		tile.obstacle_hp = 0

	# Apply aftermath based on obstacle type
	match obstacle_type:
		ObstacleType.TREE:
			# Trees destroyed by fire leave fire terrain
			if damage_type == "fire":
				add_terrain_effect(grid_pos, TerrainEffect.FIRE, 3, 5)
			# Otherwise just becomes difficult terrain (fallen branches)
			elif tile:
				tile.type = TileType.DIFFICULT
				tile.movement_cost = 2
		ObstacleType.ROCK:
			# Rocks become difficult terrain (rubble)
			if tile:
				tile.type = TileType.DIFFICULT
				tile.movement_cost = 2
		ObstacleType.PILLAR:
			# Pillars become difficult terrain (debris)
			if tile:
				tile.type = TileType.DIFFICULT
				tile.movement_cost = 2
		ObstacleType.BARRICADE:
			pass  # Barricades just disappear

	obstacle_destroyed.emit(grid_pos, obstacle_type)
	_update_obstacle_visuals()
	_draw_grid()


## Get obstacle name for display
func get_obstacle_name(obstacle_type: int) -> String:
	match obstacle_type:
		ObstacleType.TREE: return "Tree"
		ObstacleType.ROCK: return "Rock"
		ObstacleType.PILLAR: return "Pillar"
		ObstacleType.BARRICADE: return "Barricade"
		ObstacleType.FALLEN_TREE: return "Fallen Tree"
		_: return ""


# ============================================
# COVER SYSTEM
# ============================================

## Check if a defender has cover from an attacker (obstacle between them)
## Returns: {"has_cover": bool, "dodge_bonus": int, "obstacle_pos": Vector2i, "obstacle_name": String}
func get_cover_bonus(attacker_pos: Vector2i, defender_pos: Vector2i) -> Dictionary:
	var result = {
		"has_cover": false,
		"dodge_bonus": 0,
		"obstacle_pos": Vector2i(-1, -1),
		"obstacle_name": ""
	}

	if attacker_pos == defender_pos:
		return result

	# Trace the line between attacker and defender
	var tiles_in_line = _get_line_tiles(attacker_pos, defender_pos)

	# Check tiles between them (skip endpoints)
	var best_cover = 0
	for i in range(1, tiles_in_line.size() - 1):
		var pos = tiles_in_line[i]
		var tile = tiles.get(pos)
		if tile == null:
			continue

		if tile.obstacle != ObstacleType.NONE:
			# Obstacle must be close to the defender to provide meaningful cover
			var dist_to_defender = (defender_pos - pos).length()
			if dist_to_defender > MAX_COVER_RADIUS:
				continue
			var bonus = OBSTACLE_COVER_BONUS.get(tile.obstacle, 0)
			if bonus > best_cover:
				best_cover = bonus
				result.obstacle_pos = pos
				result.obstacle_name = get_obstacle_name(tile.obstacle)

	if best_cover > 0:
		result.has_cover = true
		result.dodge_bonus = best_cover

	return result


## Check what cover a unit would have at a given position from all enemy positions
## Useful for showing cover info when hovering over movement destinations
func get_cover_info_at(grid_pos: Vector2i, team: int) -> Dictionary:
	# Find the best cover this position provides against any enemy
	var best_cover = 0
	var best_obstacle_name = ""

	for pos in unit_positions:
		var unit = unit_positions[pos]
		if unit.team != team:
			# This is an enemy — check if we'd have cover from them
			var cover = get_cover_bonus(pos, grid_pos)
			if cover.has_cover and cover.dodge_bonus > best_cover:
				best_cover = cover.dodge_bonus
				best_obstacle_name = cover.obstacle_name

	return {
		"has_cover": best_cover > 0,
		"dodge_bonus": best_cover,
		"obstacle_name": best_obstacle_name
	}


# ============================================
# OBSTACLE VISUALS
# ============================================

## Update visual display of obstacles
func _update_obstacle_visuals() -> void:
	# Clear existing obstacle visuals
	for child in obstacle_layer.get_children():
		child.queue_free()

	# Draw obstacle shapes
	for pos in tiles:
		var tile = tiles[pos]
		if tile.obstacle == ObstacleType.NONE:
			continue

		var obs_visual = _create_obstacle_visual(pos, tile.obstacle)
		obstacle_layer.add_child(obs_visual)


## Create visual for an obstacle
## TREE = triangle (top), ROCK = square, PILLAR = circle, BARRICADE = horizontal bar
func _create_obstacle_visual(grid_pos: Vector2i, obstacle_type: int) -> Control:
	var container = Control.new()
	container.size = Vector2(tile_size, tile_size)
	container.position = grid_to_world(grid_pos)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var color: Color
	match obstacle_type:
		ObstacleType.TREE:
			color = COLOR_OBSTACLE_TREE
		ObstacleType.ROCK:
			color = COLOR_OBSTACLE_ROCK
		ObstacleType.PILLAR:
			color = COLOR_OBSTACLE_PILLAR
		ObstacleType.BARRICADE:
			color = COLOR_OBSTACLE_BARRICADE
		ObstacleType.FALLEN_TREE:
			color = COLOR_OBSTACLE_FALLEN_TREE
		_:
			color = Color.WHITE

	match obstacle_type:
		ObstacleType.TREE:
			# Triangle shape (represented as a small colored rect with distinct shape)
			# Top portion = foliage (green diamond rotated)
			var foliage = ColorRect.new()
			var foliage_size = tile_size * 0.5
			foliage.size = Vector2(foliage_size, foliage_size)
			foliage.position = Vector2(tile_size / 2.0, tile_size * 0.3)
			foliage.pivot_offset = Vector2(foliage_size / 2.0, foliage_size / 2.0)
			foliage.position -= foliage.pivot_offset
			foliage.rotation_degrees = 45
			foliage.color = color
			foliage.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(foliage)
			# Trunk (small brown rect)
			var trunk = ColorRect.new()
			trunk.size = Vector2(4, 8)
			trunk.position = Vector2(tile_size / 2.0 - 2, tile_size * 0.65)
			trunk.color = Color(0.35, 0.22, 0.1)
			trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(trunk)

		ObstacleType.ROCK:
			# Solid square, slightly smaller and centered
			var rock = ColorRect.new()
			var rock_size = tile_size * 0.55
			rock.size = Vector2(rock_size, rock_size)
			rock.position = Vector2((tile_size - rock_size) / 2.0, (tile_size - rock_size) / 2.0)
			rock.color = color
			rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(rock)

		ObstacleType.PILLAR:
			# Tall narrow rect (pillar shape)
			var pillar = ColorRect.new()
			var pw = tile_size * 0.3
			var ph = tile_size * 0.7
			pillar.size = Vector2(pw, ph)
			pillar.position = Vector2((tile_size - pw) / 2.0, (tile_size - ph) / 2.0)
			pillar.color = color
			pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(pillar)

		ObstacleType.BARRICADE:
			# Low horizontal bar
			var bar = ColorRect.new()
			var bw = tile_size * 0.7
			var bh = tile_size * 0.2
			bar.size = Vector2(bw, bh)
			bar.position = Vector2((tile_size - bw) / 2.0, tile_size * 0.55)
			bar.color = color
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(bar)

		ObstacleType.FALLEN_TREE:
			# Horizontal log spanning most of tile width (fallen trunk)
			var log = ColorRect.new()
			var lw = tile_size * 0.82
			var lh = tile_size * 0.22
			log.size = Vector2(lw, lh)
			log.position = Vector2((tile_size - lw) / 2.0, tile_size * 0.52)
			log.color = color
			log.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(log)
			# Dead foliage cluster at one end
			var leaves = ColorRect.new()
			var ls = tile_size * 0.28
			leaves.size = Vector2(ls, ls)
			leaves.pivot_offset = Vector2(ls / 2.0, ls / 2.0)
			leaves.position = Vector2((tile_size - lw) / 2.0 + ls * 0.1, tile_size * 0.38)
			leaves.rotation_degrees = 45
			leaves.color = Color(0.22, 0.42, 0.14)
			leaves.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(leaves)

	return container


# ============================================
# MAP GENERATION HELPERS
# ============================================

## Add a wall at position
func add_wall(grid_pos: Vector2i) -> void:
	if is_valid_position(grid_pos):
		tiles[grid_pos] = GridTile.new(TileType.WALL)
		_draw_grid()


## Add a pit at position
func add_pit(grid_pos: Vector2i) -> void:
	if is_valid_position(grid_pos):
		tiles[grid_pos] = GridTile.new(TileType.PIT)
		_draw_grid()


## Add water at position
func add_water(grid_pos: Vector2i) -> void:
	if is_valid_position(grid_pos):
		tiles[grid_pos] = GridTile.new(TileType.WATER)
		_draw_grid()


## Create a simple arena with some obstacles
func create_test_arena() -> void:
	_initialize_grid()

	# Add some walls
	add_wall(Vector2i(5, 3))
	add_wall(Vector2i(5, 4))
	add_wall(Vector2i(6, 3))

	# Add a pit
	add_pit(Vector2i(8, 5))

	# Add some water
	add_water(Vector2i(3, 6))
	add_water(Vector2i(4, 6))

	# Add a fire hazard
	add_terrain_effect(Vector2i(7, 2), TerrainEffect.FIRE, -1, 5)

	# Add cover obstacles
	set_tile_obstacle(Vector2i(7, 4), ObstacleType.TREE)
	set_tile_obstacle(Vector2i(9, 3), ObstacleType.ROCK)
	set_tile_obstacle(Vector2i(6, 7), ObstacleType.PILLAR)

	# Add height variation
	set_tile_height(Vector2i(10, 2), 1)
	set_tile_height(Vector2i(10, 3), 1)
	set_tile_height(Vector2i(11, 2), 1)
	set_tile_height(Vector2i(11, 3), 2)

	_draw_grid()


# ============================================
# DEPLOYMENT ZONES
# ============================================

## Get player deployment zone tiles
## For the larger arena, zones are in the CENTER THIRD of the grid so there's
## flanking room on all sides. Player deploys at grid_size.x/3 .. +PLAYER_DEPLOY_COLUMNS-1.
func get_player_deployment_zones() -> Dictionary:
	var front_tiles: Array[Vector2i] = []
	var back_tiles: Array[Vector2i] = []

	var start_x = grid_size.x / 3  # e.g. 16 for a 48-wide grid
	# Front column = rightmost of deploy zone (closest to enemy)
	var front_col = start_x + PLAYER_DEPLOY_COLUMNS - 1  # e.g. 19

	for y in range(grid_size.y):
		var front_pos = Vector2i(front_col, y)
		if _is_valid_deployment_tile(front_pos):
			front_tiles.append(front_pos)
		for x in range(start_x, front_col):
			var back_pos = Vector2i(x, y)
			if _is_valid_deployment_tile(back_pos):
				back_tiles.append(back_pos)

	return {
		"front": front_tiles,
		"back": back_tiles,
		"all": front_tiles + back_tiles
	}


## Get enemy deployment zone tiles
## Enemy deploys at (grid_size.x*2/3 - ENEMY_DEPLOY_COLUMNS) .. grid_size.x*2/3 - 1.
func get_enemy_deployment_zones() -> Dictionary:
	var front_tiles: Array[Vector2i] = []
	var back_tiles: Array[Vector2i] = []

	var start_x = grid_size.x * 2 / 3 - ENEMY_DEPLOY_COLUMNS  # e.g. 28 for a 48-wide grid
	# Front column = leftmost of enemy zone (closest to player)
	var front_col = start_x  # e.g. 28

	for y in range(grid_size.y):
		var front_pos = Vector2i(front_col, y)
		if _is_valid_deployment_tile(front_pos):
			front_tiles.append(front_pos)
		for x in range(front_col + 1, start_x + ENEMY_DEPLOY_COLUMNS):
			var back_pos = Vector2i(x, y)
			if _is_valid_deployment_tile(back_pos):
				back_tiles.append(back_pos)

	return {
		"front": front_tiles,
		"back": back_tiles,
		"all": front_tiles + back_tiles
	}


## Check if a tile is valid for unit deployment (walkable, not a hazard, no obstacle)
func _is_valid_deployment_tile(grid_pos: Vector2i) -> bool:
	if not is_valid_position(grid_pos):
		return false

	var tile = tiles.get(grid_pos)
	if tile == null:
		return false

	# Must be walkable
	if not tile.walkable:
		return false

	# Can't deploy on blocking obstacles
	if tile.obstacle != ObstacleType.NONE and tile.obstacle != ObstacleType.BARRICADE:
		return false

	# Avoid tiles with damaging effects
	if tile.effect in [TerrainEffect.FIRE, TerrainEffect.POISON, TerrainEffect.ACID, TerrainEffect.CURSED]:
		return false

	return true


## Highlight deployment zones for visual feedback
func show_deployment_zones(show_player: bool = true, show_enemy: bool = false) -> void:
	clear_highlights()

	if show_player:
		var zones = get_player_deployment_zones()
		for pos in zones.front:
			_add_highlight_at(pos, COLOR_DEPLOY_FRONT)
		for pos in zones.back:
			_add_highlight_at(pos, COLOR_DEPLOY_BACK)

	if show_enemy:
		var zones = get_enemy_deployment_zones()
		for pos in zones.all:
			_add_highlight_at(pos, COLOR_DEPLOY_ENEMY)


## Add a single highlight at position (used by deployment zones)
func _add_highlight_at(grid_pos: Vector2i, color: Color) -> void:
	var highlight = ColorRect.new()
	highlight.size = Vector2(tile_size - 2, tile_size - 2)
	highlight.position = grid_to_world(grid_pos) + Vector2(1, 1)
	highlight.color = color
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_layer.add_child(highlight)


## Get a random unoccupied position from a list of positions
func get_random_unoccupied(positions: Array) -> Vector2i:
	var available: Array[Vector2i] = []
	for pos in positions:
		if not is_occupied(pos):
			available.append(pos)

	if available.is_empty():
		return Vector2i(-1, -1)  # Invalid position signals no space

	return available[randi() % available.size()]


## Check if a position is in player deployment zone
func is_in_player_zone(grid_pos: Vector2i) -> bool:
	return grid_pos.x < PLAYER_DEPLOY_COLUMNS


## Check if a position is in enemy deployment zone
func is_in_enemy_zone(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= grid_size.x - ENEMY_DEPLOY_COLUMNS
