extends Node
## MapManager - Manages overworld exploration (HoMM/King's Bounty style)
##
## This singleton handles:
## - Tile-based map with terrain types and speed modifiers
## - Real-time party movement with path following
## - Interactive map objects (events, enemies, shops, treasures)
## - Map loading and state persistence
##
## Movement is real-time: click a tile, party follows the shortest path
## at a speed modified by terrain. Swamp = half speed, road = double speed.

# Signals
signal party_moved(from: Vector2i, to: Vector2i)  # Emitted each tile
signal party_arrived(position: Vector2i)  # Emitted when destination reached
signal party_position_updated(world_pos: Vector2)  # Emitted every frame during movement
signal movement_started(path: Array)
signal movement_stopped()
signal object_interacted(object: Dictionary)
signal object_approached(object: Dictionary, distance: int)  # When nearby
signal combat_triggered(enemy_data: Dictionary)
signal event_triggered(event_id: String)
signal shop_triggered(shop_id: String)
signal treasure_collected(loot: Dictionary)
signal map_loaded(map_id: String)
signal map_paused()
signal map_resumed()

# Terrain types - these are broad categories, biome-specific
# variants can map to these for movement purposes
enum Terrain {
	PLAINS = 0,
	ROAD = 1,
	FOREST = 2,
	HILLS = 3,
	MOUNTAINS = 4,
	WATER = 5,
	SWAMP = 6,
	DESERT = 7,
	SNOW = 8,
	LAVA = 9,
	BRIDGE = 10,
	ICE = 11,
	SAND = 12,
	RUINS = 13
}

# Speed multipliers for terrain types
# 0.5 = half speed, 1.0 = normal, 2.0 = double speed, -1 = impassable
const TERRAIN_SPEED: Dictionary = {
	Terrain.PLAINS: 1.0,
	Terrain.ROAD: 2.0,       # Fast travel
	Terrain.FOREST: 0.5,     # Slow - thick undergrowth
	Terrain.HILLS: 0.5,      # Slow - steep inclines
	Terrain.MOUNTAINS: -1.0, # Impassable
	Terrain.WATER: -1.0,     # Impassable (without boat)
	Terrain.SWAMP: 0.5,      # Slow - sticky mud
	Terrain.DESERT: 0.75,    # Somewhat slow - loose sand
	Terrain.SNOW: 0.5,       # Slow - deep drifts
	Terrain.LAVA: -1.0,      # Impassable
	Terrain.BRIDGE: 1.5,     # Slightly fast - constructed path
	Terrain.ICE: 1.25,       # Slightly fast but slippery (future: slide mechanic)
	Terrain.SAND: 0.75,      # Somewhat slow - beach/dunes
	Terrain.RUINS: 0.75      # Somewhat slow - rubble and debris
}

# Terrain display names
const TERRAIN_NAMES: Dictionary = {
	Terrain.PLAINS: "Plains",
	Terrain.ROAD: "Road",
	Terrain.FOREST: "Forest",
	Terrain.HILLS: "Hills",
	Terrain.MOUNTAINS: "Mountains",
	Terrain.WATER: "Water",
	Terrain.SWAMP: "Swamp",
	Terrain.DESERT: "Desert",
	Terrain.SNOW: "Snow",
	Terrain.LAVA: "Lava",
	Terrain.BRIDGE: "Bridge",
	Terrain.ICE: "Ice",
	Terrain.SAND: "Sand",
	Terrain.RUINS: "Ruins"
}

# Short description for UI tooltips
const TERRAIN_DESCRIPTIONS: Dictionary = {
	Terrain.PLAINS: "Open grassland. Normal movement speed.",
	Terrain.ROAD: "Paved path. Double movement speed.",
	Terrain.FOREST: "Dense woodland. Half movement speed.",
	Terrain.HILLS: "Steep terrain. Half movement speed.",
	Terrain.MOUNTAINS: "Impassable mountain peaks.",
	Terrain.WATER: "Deep water. Cannot cross without a boat.",
	Terrain.SWAMP: "Boggy marsh. Half movement speed.",
	Terrain.DESERT: "Arid wasteland. Reduced movement speed.",
	Terrain.SNOW: "Frozen tundra. Half movement speed.",
	Terrain.LAVA: "Molten rock. Impassable.",
	Terrain.BRIDGE: "Constructed crossing. Good movement speed.",
	Terrain.ICE: "Frozen surface. Slightly fast but treacherous.",
	Terrain.SAND: "Loose sand. Reduced movement speed.",
	Terrain.RUINS: "Crumbling structures. Reduced movement speed."
}

# Map object types
enum ObjectType {
	NONE = 0,
	ENEMY = 1,
	EVENT = 2,
	SHOP = 3,
	TREASURE = 4,
	PORTAL = 5,
	SHRINE = 6,
	REST_SITE = 7,
	QUEST_GIVER = 8,
	DUNGEON = 9
}

# ============================================
# MAP STATE
# ============================================

var current_map_id: String = ""
var map_size: Vector2i = Vector2i(24, 16)
var tiles: Dictionary = {}         # Vector2i -> Terrain type
var objects: Dictionary = {}       # Vector2i -> MapObject data
var visited_tiles: Dictionary = {} # Vector2i -> bool (fog of war)
var collected_objects: Array[String] = []  # IDs of consumed one-time objects

# ============================================
# REAL-TIME MOVEMENT STATE
# ============================================

## Base speed in tiles per second (before terrain modifier)
var base_speed: float = 3.0

## Current tile the party occupies
var party_position: Vector2i = Vector2i.ZERO

## Smooth world-space position for rendering (interpolated between tiles)
var party_world_position: Vector2 = Vector2.ZERO

## The path the party is currently following (array of Vector2i tile positions)
var current_path: Array[Vector2i] = []

## Index into current_path - which tile we're heading toward
var _path_index: int = 0

## Progress from current tile toward next tile (0.0 to 1.0)
var _move_progress: float = 0.0

## Whether we're actively moving
var _is_moving: bool = false

## Whether movement is paused (e.g. during combat, event, menu)
var _is_paused: bool = false

## Tile size for world position calculation (must match UI)
var tile_size: int = 48


func _ready() -> void:
	set_process(true)
	print("MapManager initialized (real-time movement)")


func _process(delta: float) -> void:
	if not _is_moving or _is_paused:
		return

	if current_path.is_empty() or _path_index >= current_path.size():
		_finish_movement()
		return

	var target_tile = current_path[_path_index]
	var speed_mult = get_terrain_speed(target_tile)

	# Should not happen, but safety check
	if speed_mult <= 0:
		stop_movement()
		return

	# Advance progress based on speed and delta
	var effective_speed = base_speed * speed_mult
	_move_progress += effective_speed * delta

	# Interpolate world position between current tile and target tile
	var from_world = _tile_to_world(party_position)
	var to_world = _tile_to_world(target_tile)
	party_world_position = from_world.lerp(to_world, clampf(_move_progress, 0.0, 1.0))
	party_position_updated.emit(party_world_position)

	# Arrived at next tile
	if _move_progress >= 1.0:
		_move_progress = 0.0
		var old_pos = party_position
		party_position = target_tile

		# Mark visited
		visited_tiles[target_tile] = true

		party_moved.emit(old_pos, target_tile)

		# Check for object interaction on arrival
		var obj = get_object_at(target_tile)
		if not obj.is_empty():
			_interact_with_object(obj)
			# If object blocks movement (enemy), stop here
			if obj.get("blocking", false):
				_finish_movement()
				return

		# Move to next tile in path
		_path_index += 1
		if _path_index >= current_path.size():
			_finish_movement()


## Convert tile position to world pixel position (center of tile)
func _tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * tile_size + tile_size / 2.0,
				   tile_pos.y * tile_size + tile_size / 2.0)


# ============================================
# MOVEMENT COMMANDS
# ============================================

## Set a destination - calculates path and starts moving
func set_destination(target: Vector2i) -> bool:
	if not is_valid_position(target):
		return false

	if not is_passable(target):
		return false

	if target == party_position:
		return false

	var path = find_path(party_position, target)
	if path.is_empty():
		return false

	# Start moving along the path
	current_path = path
	_path_index = 0
	_move_progress = 0.0
	_is_moving = true
	_is_paused = false

	movement_started.emit(path)
	return true


## Stop movement immediately
func stop_movement() -> void:
	if _is_moving:
		_is_moving = false
		current_path.clear()
		_path_index = 0
		_move_progress = 0.0
		# Snap to current tile
		party_world_position = _tile_to_world(party_position)
		party_position_updated.emit(party_world_position)
		movement_stopped.emit()


## Pause movement (e.g. during combat or events)
func pause_movement() -> void:
	_is_paused = true
	map_paused.emit()


## Resume movement after pause
func resume_movement() -> void:
	_is_paused = false
	map_resumed.emit()


## Check if party is currently moving
func is_moving() -> bool:
	return _is_moving and not _is_paused


## Check if movement is paused
func is_paused() -> bool:
	return _is_paused


## Finish movement (arrived at destination)
func _finish_movement() -> void:
	_is_moving = false
	var final_pos = party_position
	current_path.clear()
	_path_index = 0
	_move_progress = 0.0
	party_world_position = _tile_to_world(final_pos)
	party_position_updated.emit(party_world_position)
	party_arrived.emit(final_pos)


## Get estimated travel time to target in seconds (for UI display)
func estimate_travel_time(target: Vector2i) -> float:
	var path = find_path(party_position, target)
	if path.is_empty():
		return -1.0

	var total_time = 0.0
	for tile_pos in path:
		var speed = get_terrain_speed(tile_pos)
		if speed <= 0:
			return -1.0
		total_time += 1.0 / (base_speed * speed)

	return total_time


## Get the remaining path the party is following
func get_remaining_path() -> Array[Vector2i]:
	if not _is_moving or current_path.is_empty():
		return []

	var remaining: Array[Vector2i] = []
	for i in range(_path_index, current_path.size()):
		remaining.append(current_path[i])
	return remaining


# ============================================
# MAP LOADING
# ============================================

## Load a map from JSON data
func load_map(map_id: String) -> bool:
	stop_movement()

	var file_path = "res://resources/data/maps/%s.json" % map_id

	if not FileAccess.file_exists(file_path):
		push_warning("MapManager: Map file not found: " + file_path)
		_generate_default_map(map_id)
		return true

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("MapManager: Failed to open map file")
		return false

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("MapManager: Failed to parse map JSON")
		return false

	var data = json.get_data()
	_apply_map_data(data)

	current_map_id = map_id
	map_loaded.emit(map_id)
	print("Map loaded: ", map_id)
	return true


## Apply parsed map data
func _apply_map_data(data: Dictionary) -> void:
	map_size = Vector2i(data.get("width", 24), data.get("height", 16))
	base_speed = data.get("base_speed", 3.0)

	tiles.clear()
	objects.clear()

	# Load terrain from flat array
	var terrain_data = data.get("terrain", [])
	for y in range(map_size.y):
		for x in range(map_size.x):
			var idx = y * map_size.x + x
			var terrain_type = Terrain.PLAINS
			if idx < terrain_data.size():
				terrain_type = terrain_data[idx]
			tiles[Vector2i(x, y)] = terrain_type

	# Load objects
	var objects_data = data.get("objects", [])
	for obj_data in objects_data:
		var pos = Vector2i(obj_data.get("x", 0), obj_data.get("y", 0))
		var obj_id = obj_data.get("id", "obj_%d_%d" % [pos.x, pos.y])

		if obj_id in collected_objects:
			continue

		objects[pos] = {
			"id": obj_id,
			"type": obj_data.get("type", ObjectType.EVENT),
			"position": pos,
			"data": obj_data.get("data", {}),
			"one_time": obj_data.get("one_time", false),
			"blocking": obj_data.get("blocking", false),
			"visible": obj_data.get("visible", true),
			"name": obj_data.get("name", "Unknown")
		}

	# Set party starting position
	var start_pos = data.get("start_position", {"x": 1, "y": 1})
	party_position = Vector2i(start_pos.get("x", 1), start_pos.get("y", 1))
	party_world_position = _tile_to_world(party_position)
	visited_tiles[party_position] = true

	# Reveal area around starting position
	reveal_area(party_position, 3)


## Generate a simple default map for testing
func _generate_default_map(map_id: String) -> void:
	current_map_id = map_id
	map_size = Vector2i(24, 16)
	tiles.clear()
	objects.clear()

	# Fill with plains
	for y in range(map_size.y):
		for x in range(map_size.x):
			tiles[Vector2i(x, y)] = Terrain.PLAINS

	# Roads (crossroads)
	for x in range(map_size.x):
		tiles[Vector2i(x, 8)] = Terrain.ROAD
	for y in range(map_size.y):
		tiles[Vector2i(12, y)] = Terrain.ROAD

	# Terrain clusters
	_add_terrain_cluster(Vector2i(4, 3), Terrain.FOREST, 3)
	_add_terrain_cluster(Vector2i(18, 3), Terrain.HILLS, 3)
	_add_terrain_cluster(Vector2i(6, 12), Terrain.WATER, 2)
	_add_terrain_cluster(Vector2i(19, 11), Terrain.MOUNTAINS, 2)
	_add_terrain_cluster(Vector2i(3, 10), Terrain.SWAMP, 2)

	# Objects
	_add_object(Vector2i(6, 5), ObjectType.ENEMY, {
		"name": "Demon Patrol",
		"enemy_group": "demon_patrol_weak",
		"difficulty": "easy"
	}, false, true)

	_add_object(Vector2i(15, 4), ObjectType.EVENT, {
		"name": "Wandering Monk",
		"event_id": "random_monk"
	}, false, false)

	_add_object(Vector2i(9, 11), ObjectType.TREASURE, {
		"name": "Abandoned Cache",
		"gold": 50,
		"items": []
	}, true, false)

	_add_object(Vector2i(20, 8), ObjectType.SHOP, {
		"name": "Roadside Trader",
		"shop_id": "roadside_merchant"
	}, false, false)

	_add_object(Vector2i(2, 14), ObjectType.REST_SITE, {
		"name": "Campfire",
		"heal_percent": 25
	}, false, false)

	_add_object(Vector2i(22, 8), ObjectType.PORTAL, {
		"name": "Realm Gate",
		"destination_realm": "hungry_ghost",
		"destination_map": "hungry_ghost_01"
	}, false, false)

	# Start position
	party_position = Vector2i(2, 8)
	party_world_position = _tile_to_world(party_position)
	visited_tiles[party_position] = true
	reveal_area(party_position, 3)

	print("Generated default map for: ", map_id)


## Helper to add terrain clusters
func _add_terrain_cluster(center: Vector2i, terrain: int, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if is_valid_position(pos):
				var dist = absf(dx) + absf(dy)
				if dist <= radius:
					tiles[pos] = terrain


## Helper to add a map object
func _add_object(pos: Vector2i, type: int, data: Dictionary, one_time: bool, blocking: bool) -> void:
	var obj_id = "obj_%d_%d" % [pos.x, pos.y]
	if obj_id in collected_objects:
		return

	objects[pos] = {
		"id": obj_id,
		"type": type,
		"position": pos,
		"data": data,
		"one_time": one_time,
		"blocking": blocking,
		"visible": true,
		"name": data.get("name", "Unknown")
	}


# ============================================
# TERRAIN QUERIES
# ============================================

## Check if a position is valid on the map
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_size.x and pos.y >= 0 and pos.y < map_size.y


## Get terrain type at position
func get_terrain(pos: Vector2i) -> int:
	return tiles.get(pos, Terrain.PLAINS)


## Get terrain name for display
func get_terrain_name(pos: Vector2i) -> String:
	var terrain = get_terrain(pos)
	return TERRAIN_NAMES.get(terrain, "Unknown")


## Get terrain description for tooltips
func get_terrain_description(pos: Vector2i) -> String:
	var terrain = get_terrain(pos)
	return TERRAIN_DESCRIPTIONS.get(terrain, "")


## Get speed multiplier for terrain at position
## Returns: 2.0 = double speed, 1.0 = normal, 0.5 = half, -1.0 = impassable
func get_terrain_speed(pos: Vector2i) -> float:
	var terrain = get_terrain(pos)
	return TERRAIN_SPEED.get(terrain, 1.0)


## Get a human-readable speed label for UI
func get_speed_label(pos: Vector2i) -> String:
	var speed = get_terrain_speed(pos)
	if speed <= 0:
		return "Impassable"
	elif speed >= 2.0:
		return "Very Fast"
	elif speed >= 1.5:
		return "Fast"
	elif speed >= 1.0:
		return "Normal"
	elif speed >= 0.75:
		return "Slow"
	else:
		return "Very Slow"


## Check if terrain is passable
func is_passable(pos: Vector2i) -> bool:
	return get_terrain_speed(pos) > 0


# ============================================
# PATHFINDING
# ============================================

## A* pathfinding that accounts for terrain speed
## Slower terrain = higher cost = path prefers faster routes
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if from == to:
		return []

	if not is_valid_position(to) or not is_passable(to):
		return []

	# A* with terrain-weighted costs
	# Cost = 1.0 / speed_multiplier (so road = 0.5, swamp = 2.0)
	var open_set: Array[Dictionary] = [{"pos": from, "g": 0.0, "f": 0.0, "parent": Vector2i(-1, -1)}]
	var closed_set: Dictionary = {}  # Vector2i -> true
	var came_from: Dictionary = {}   # Vector2i -> Vector2i
	var g_scores: Dictionary = {from: 0.0}

	while not open_set.is_empty():
		# Find lowest f-score in open set
		var best_idx = 0
		for i in range(1, open_set.size()):
			if open_set[i].f < open_set[best_idx].f:
				best_idx = i

		var current = open_set[best_idx]
		var current_pos = current.pos
		open_set.remove_at(best_idx)

		if current_pos == to:
			# Reconstruct path (exclude starting position)
			return _reconstruct_path(came_from, to)

		closed_set[current_pos] = true

		# Check 4 neighbors (no diagonal movement)
		for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var neighbor = current_pos + dir

			if not is_valid_position(neighbor):
				continue
			if neighbor in closed_set:
				continue
			if not is_passable(neighbor):
				continue

			# Cost to enter this tile = inverse of speed
			var speed = get_terrain_speed(neighbor)
			var step_cost = 1.0 / speed
			var tentative_g = g_scores[current_pos] + step_cost

			if neighbor in g_scores and tentative_g >= g_scores[neighbor]:
				continue

			came_from[neighbor] = current_pos
			g_scores[neighbor] = tentative_g
			var h = _heuristic(neighbor, to)
			var f_score = tentative_g + h

			# Add to open set (or update)
			var found = false
			for entry in open_set:
				if entry.pos == neighbor:
					entry.g = tentative_g
					entry.f = f_score
					found = true
					break

			if not found:
				open_set.append({"pos": neighbor, "g": tentative_g, "f": f_score})

	return []  # No path found


## A* heuristic: Manhattan distance (admissible for 4-directional movement)
func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(absi(a.x - b.x) + absi(a.y - b.y))


## Reconstruct path from came_from dictionary
func _reconstruct_path(came_from: Dictionary, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = to

	while current in came_from:
		path.push_front(current)
		current = came_from[current]

	# path[0] is the first tile to move to (not the starting tile)
	return path


# ============================================
# OBJECTS & INTERACTIONS
# ============================================

## Get object at position (returns empty dict if none)
func get_object_at(pos: Vector2i) -> Dictionary:
	return objects.get(pos, {})


## Get all objects on map
func get_all_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for obj in objects.values():
		result.append(obj)
	return result


## Get all visible objects
func get_visible_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for obj in objects.values():
		if obj.get("visible", true):
			result.append(obj)
	return result


## Remove an object from the map (e.g., after defeating enemy)
func remove_object(obj_id: String) -> void:
	for pos in objects.keys():
		if objects[pos].get("id", "") == obj_id:
			if objects[pos].get("one_time", false):
				collected_objects.append(obj_id)
			objects.erase(pos)
			return


## Interact with an object
func _interact_with_object(obj: Dictionary) -> void:
	if obj.is_empty():
		return

	# Pause movement for blocking interactions
	if obj.get("blocking", false):
		stop_movement()

	object_interacted.emit(obj)

	match obj.type:
		ObjectType.ENEMY:
			_trigger_combat(obj)
		ObjectType.EVENT:
			_trigger_event(obj)
		ObjectType.SHOP:
			_trigger_shop(obj)
		ObjectType.TREASURE:
			_collect_treasure(obj)
		ObjectType.PORTAL:
			_use_portal(obj)
		ObjectType.REST_SITE:
			_rest_at_site(obj)
		ObjectType.SHRINE:
			_use_shrine(obj)

	# Remove one-time objects after interaction
	if obj.one_time:
		collected_objects.append(obj.id)
		objects.erase(obj.position)


func _trigger_combat(obj: Dictionary) -> void:
	pause_movement()
	var enemy_data = obj.data
	print("Combat triggered: ", enemy_data.get("name", "Unknown"))
	combat_triggered.emit(enemy_data)


func _trigger_event(obj: Dictionary) -> void:
	pause_movement()
	var event_id = obj.data.get("event_id", "")
	print("Event triggered: ", event_id)
	event_triggered.emit(event_id)


func _trigger_shop(obj: Dictionary) -> void:
	pause_movement()
	var shop_id = obj.data.get("shop_id", "")
	print("Shop opened: ", shop_id)
	shop_triggered.emit(shop_id)


func _collect_treasure(obj: Dictionary) -> void:
	var loot = obj.data
	print("Treasure collected: ", loot)

	var gold_amount = loot.get("gold", 0)
	if gold_amount > 0 and GameState:
		GameState.add_gold(gold_amount)

	treasure_collected.emit(loot)


func _use_portal(obj: Dictionary) -> void:
	stop_movement()
	var dest_realm = obj.data.get("destination_realm", "")
	var dest_map = obj.data.get("destination_map", "")
	print("Portal to: ", dest_realm, " / ", dest_map)

	if GameState and not dest_realm.is_empty():
		GameState.travel_to_world(dest_realm)

	if not dest_map.is_empty():
		load_map(dest_map)


func _rest_at_site(obj: Dictionary) -> void:
	pause_movement()
	var heal_percent = obj.data.get("heal_percent", 25)
	print("Resting... healing ", heal_percent, "%")

	if CharacterSystem:
		for character in CharacterSystem.get_party():
			var max_hp = character.get("derived", {}).get("max_hp", 100)
			var heal_amount = int(max_hp * heal_percent / 100.0)
			CharacterSystem.heal_character(character.get("id", ""), heal_amount)


func _use_shrine(obj: Dictionary) -> void:
	pause_movement()
	var buff_type = obj.data.get("buff_type", "")
	var buff_value = obj.data.get("buff_value", 0)
	print("Shrine blessing: ", buff_type, " +", buff_value)


# ============================================
# UTILITY
# ============================================

## Get object type name for display
func get_object_type_name(type: int) -> String:
	match type:
		ObjectType.ENEMY: return "Enemy"
		ObjectType.EVENT: return "Event"
		ObjectType.SHOP: return "Shop"
		ObjectType.TREASURE: return "Treasure"
		ObjectType.PORTAL: return "Portal"
		ObjectType.SHRINE: return "Shrine"
		ObjectType.REST_SITE: return "Rest Site"
		ObjectType.QUEST_GIVER: return "Quest"
		ObjectType.DUNGEON: return "Dungeon"
		_: return "Unknown"


## Get party grid position
func get_party_position() -> Vector2i:
	return party_position


## Get party smooth world position (for rendering)
func get_party_world_position() -> Vector2:
	return party_world_position


## Check if tile has been visited (for fog of war)
func is_tile_visited(pos: Vector2i) -> bool:
	return visited_tiles.get(pos, false)


## Reveal tiles around a position
func reveal_area(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if is_valid_position(pos):
				# Use true distance for circular reveal
				var dist = sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					visited_tiles[pos] = true


## Get save data for persistence
func get_save_data() -> Dictionary:
	return {
		"current_map_id": current_map_id,
		"party_position": {"x": party_position.x, "y": party_position.y},
		"visited_tiles": _serialize_positions(visited_tiles.keys()),
		"collected_objects": collected_objects.duplicate()
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	current_map_id = data.get("current_map_id", "")
	var pos_data = data.get("party_position", {"x": 1, "y": 1})
	party_position = Vector2i(pos_data.x, pos_data.y)
	party_world_position = _tile_to_world(party_position)

	collected_objects.clear()
	for obj_id in data.get("collected_objects", []):
		collected_objects.append(obj_id)

	visited_tiles.clear()
	for pos_str in data.get("visited_tiles", []):
		var parts = pos_str.split(",")
		if parts.size() == 2:
			visited_tiles[Vector2i(int(parts[0]), int(parts[1]))] = true

	if not current_map_id.is_empty():
		load_map(current_map_id)


## Serialize positions for saving
func _serialize_positions(positions: Array) -> Array[String]:
	var result: Array[String] = []
	for pos in positions:
		result.append("%d,%d" % [pos.x, pos.y])
	return result
