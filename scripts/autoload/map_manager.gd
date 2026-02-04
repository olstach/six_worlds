extends Node
## MapManager - Manages overworld exploration (HoMM/King's Bounty style)
##
## This singleton handles:
## - Tile-based map with terrain types
## - Party position and movement
## - Interactive map objects (events, enemies, shops, treasures)
## - Map loading and state persistence

# Signals
signal party_moved(from: Vector2i, to: Vector2i)
signal movement_points_changed(current: int, max: int)
signal object_interacted(object: Dictionary)
signal combat_triggered(enemy_data: Dictionary)
signal event_triggered(event_id: String)
signal shop_triggered(shop_id: String)
signal treasure_collected(loot: Dictionary)
signal map_loaded(map_id: String)
signal turn_ended()

# Terrain types with movement costs
enum Terrain {
	PLAINS = 0,     # Cost: 1 - Basic grassland
	ROAD = 1,       # Cost: 0.5 - Faster travel
	FOREST = 2,     # Cost: 2 - Slow, provides cover
	HILLS = 3,      # Cost: 2 - Elevated terrain
	MOUNTAINS = 4,  # Impassable without special ability
	WATER = 5,      # Impassable without boat
	SWAMP = 6,      # Cost: 3 - Very slow, dangerous
	DESERT = 7,     # Cost: 1.5 - Hot, may cause fatigue
	SNOW = 8,       # Cost: 2 - Cold regions
	LAVA = 9        # Impassable, Hell realm specific
}

# Movement costs per terrain type
const TERRAIN_COSTS: Dictionary = {
	Terrain.PLAINS: 1.0,
	Terrain.ROAD: 0.5,
	Terrain.FOREST: 2.0,
	Terrain.HILLS: 2.0,
	Terrain.MOUNTAINS: -1.0,  # -1 = impassable
	Terrain.WATER: -1.0,
	Terrain.SWAMP: 3.0,
	Terrain.DESERT: 1.5,
	Terrain.SNOW: 2.0,
	Terrain.LAVA: -1.0
}

# Terrain names for display
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
	Terrain.LAVA: "Lava"
}

# Map object types
enum ObjectType {
	NONE = 0,
	ENEMY = 1,        # Triggers combat
	EVENT = 2,        # Triggers event/dialogue
	SHOP = 3,         # Opens shop
	TREASURE = 4,     # Collectable loot
	PORTAL = 5,       # Realm transition
	SHRINE = 6,       # Buff/blessing
	REST_SITE = 7,    # Heal party
	QUEST_GIVER = 8,  # Special NPC
	DUNGEON = 9       # Multi-combat area
}

# Current map state
var current_map_id: String = ""
var map_size: Vector2i = Vector2i(20, 15)
var tiles: Dictionary = {}  # Vector2i -> Terrain
var objects: Dictionary = {}  # Vector2i -> MapObject data
var visited_tiles: Dictionary = {}  # Vector2i -> bool (for fog of war)
var collected_objects: Array[String] = []  # IDs of one-time objects already collected

# Party state on map
var party_position: Vector2i = Vector2i.ZERO
var movement_points: float = 0.0
var max_movement_points: float = 10.0
var is_party_turn: bool = true

# Map object data structure
# {
#   "id": "unique_id",
#   "type": ObjectType,
#   "position": Vector2i,
#   "data": { type-specific data },
#   "one_time": bool,  # disappears after interaction
#   "blocking": bool,  # must interact to pass
#   "visible": bool    # for hidden objects
# }


func _ready() -> void:
	print("MapManager initialized")


# ============================================
# MAP LOADING
# ============================================

## Load a map from JSON data
func load_map(map_id: String) -> bool:
	var file_path = "res://resources/data/maps/%s.json" % map_id

	if not FileAccess.file_exists(file_path):
		push_warning("MapManager: Map file not found: " + file_path)
		# Generate a default map for testing
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
	map_size = Vector2i(data.get("width", 20), data.get("height", 15))

	# Clear existing data
	tiles.clear()
	objects.clear()

	# Load terrain
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

		# Skip already collected one-time objects
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

	# Set movement points
	max_movement_points = data.get("movement_points", 10.0)
	movement_points = max_movement_points


## Generate a simple default map for testing
func _generate_default_map(map_id: String) -> void:
	current_map_id = map_id
	map_size = Vector2i(20, 15)
	tiles.clear()
	objects.clear()

	# Fill with plains
	for y in range(map_size.y):
		for x in range(map_size.x):
			tiles[Vector2i(x, y)] = Terrain.PLAINS

	# Add some roads
	for x in range(map_size.x):
		tiles[Vector2i(x, 7)] = Terrain.ROAD
	for y in range(map_size.y):
		tiles[Vector2i(10, y)] = Terrain.ROAD

	# Add terrain variety
	_add_terrain_cluster(Vector2i(3, 3), Terrain.FOREST, 4)
	_add_terrain_cluster(Vector2i(15, 2), Terrain.HILLS, 3)
	_add_terrain_cluster(Vector2i(5, 11), Terrain.WATER, 3)
	_add_terrain_cluster(Vector2i(16, 10), Terrain.MOUNTAINS, 2)

	# Add some objects
	_add_object(Vector2i(5, 5), ObjectType.ENEMY, {
		"name": "Demon Patrol",
		"enemy_group": "demon_patrol_weak",
		"difficulty": "easy"
	}, false, true)

	_add_object(Vector2i(12, 4), ObjectType.EVENT, {
		"name": "Wandering Merchant",
		"event_id": "random_merchant"
	}, false, false)

	_add_object(Vector2i(8, 10), ObjectType.TREASURE, {
		"name": "Abandoned Cache",
		"gold": 50,
		"items": []
	}, true, false)

	_add_object(Vector2i(18, 7), ObjectType.SHOP, {
		"name": "Roadside Trader",
		"shop_id": "roadside_merchant"
	}, false, false)

	_add_object(Vector2i(2, 13), ObjectType.REST_SITE, {
		"name": "Campfire",
		"heal_percent": 25
	}, false, false)

	_add_object(Vector2i(17, 13), ObjectType.PORTAL, {
		"name": "Realm Gate",
		"destination_realm": "hungry_ghost",
		"destination_map": "hungry_ghost_01"
	}, false, false)

	# Set party start
	party_position = Vector2i(1, 7)
	movement_points = max_movement_points

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
# MOVEMENT
# ============================================

## Check if a position is valid on the map
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < map_size.x and pos.y >= 0 and pos.y < map_size.y


## Get terrain at position
func get_terrain(pos: Vector2i) -> int:
	return tiles.get(pos, Terrain.PLAINS)


## Get terrain name
func get_terrain_name(pos: Vector2i) -> String:
	var terrain = get_terrain(pos)
	return TERRAIN_NAMES.get(terrain, "Unknown")


## Get movement cost for terrain
func get_movement_cost(pos: Vector2i) -> float:
	var terrain = get_terrain(pos)
	return TERRAIN_COSTS.get(terrain, 1.0)


## Check if terrain is passable
func is_passable(pos: Vector2i) -> bool:
	var cost = get_movement_cost(pos)
	return cost > 0


## Check if party can move to a position
func can_move_to(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false

	if not is_passable(pos):
		return false

	var cost = get_movement_cost(pos)
	if movement_points < cost:
		return false

	# Check for blocking objects (must interact first)
	var obj = get_object_at(pos)
	if obj and obj.blocking and obj.type == ObjectType.ENEMY:
		# Can move to enemy tile to initiate combat
		return true

	return true


## Get tiles the party can reach with current movement points
func get_reachable_tiles() -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var to_check: Array[Dictionary] = [{"pos": party_position, "cost": 0.0}]
	var checked: Dictionary = {}

	while not to_check.is_empty():
		var current = to_check.pop_front()
		var pos = current.pos
		var spent = current.cost

		if pos in checked:
			continue
		checked[pos] = spent

		if pos != party_position:
			reachable.append(pos)

		# Check adjacent tiles
		for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var next_pos = pos + dir
			if not is_valid_position(next_pos):
				continue
			if next_pos in checked:
				continue
			if not is_passable(next_pos):
				continue

			var move_cost = get_movement_cost(next_pos)
			var total_cost = spent + move_cost

			if total_cost <= movement_points:
				to_check.append({"pos": next_pos, "cost": total_cost})

	return reachable


## Move party to a new position
func move_party_to(target: Vector2i) -> bool:
	if not can_move_to(target):
		return false

	# Calculate path and total cost
	var path = _find_path(party_position, target)
	if path.is_empty():
		return false

	var total_cost = _calculate_path_cost(path)
	if total_cost > movement_points:
		return false

	var old_pos = party_position
	party_position = target
	movement_points -= total_cost

	# Mark tile as visited
	visited_tiles[target] = true

	party_moved.emit(old_pos, target)
	movement_points_changed.emit(int(movement_points), int(max_movement_points))

	# Check for object interaction
	var obj = get_object_at(target)
	if obj:
		_interact_with_object(obj)

	return true


## Simple pathfinding (A* would be better but this works for short distances)
func _find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# Simple BFS pathfinding
	var queue: Array[Dictionary] = [{"pos": from, "path": []}]
	var visited: Dictionary = {from: true}

	while not queue.is_empty():
		var current = queue.pop_front()
		var pos = current.pos
		var path: Array = current.path.duplicate()

		if pos == to:
			var result: Array[Vector2i] = []
			for p in path:
				result.append(p)
			result.append(to)
			return result

		for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var next_pos = pos + dir
			if not is_valid_position(next_pos):
				continue
			if next_pos in visited:
				continue
			if not is_passable(next_pos):
				continue

			visited[next_pos] = true
			var new_path = path.duplicate()
			new_path.append(pos)
			queue.append({"pos": next_pos, "path": new_path})

	return []  # No path found


## Calculate total movement cost for a path
func _calculate_path_cost(path: Array[Vector2i]) -> float:
	var total = 0.0
	for pos in path:
		if pos != party_position:  # Don't count starting position
			total += get_movement_cost(pos)
	return total


# ============================================
# OBJECTS & INTERACTIONS
# ============================================

## Get object at position
func get_object_at(pos: Vector2i) -> Dictionary:
	return objects.get(pos, {})


## Get all objects on map
func get_all_objects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for obj in objects.values():
		result.append(obj)
	return result


## Interact with an object
func _interact_with_object(obj: Dictionary) -> void:
	if obj.is_empty():
		return

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

	# Remove one-time objects
	if obj.one_time:
		collected_objects.append(obj.id)
		objects.erase(obj.position)


## Trigger combat encounter
func _trigger_combat(obj: Dictionary) -> void:
	var enemy_data = obj.data
	print("Combat triggered: ", enemy_data.get("name", "Unknown"))
	combat_triggered.emit(enemy_data)


## Trigger event
func _trigger_event(obj: Dictionary) -> void:
	var event_id = obj.data.get("event_id", "")
	print("Event triggered: ", event_id)
	event_triggered.emit(event_id)


## Trigger shop
func _trigger_shop(obj: Dictionary) -> void:
	var shop_id = obj.data.get("shop_id", "")
	print("Shop opened: ", shop_id)
	shop_triggered.emit(shop_id)


## Collect treasure
func _collect_treasure(obj: Dictionary) -> void:
	var loot = obj.data
	print("Treasure collected: ", loot)

	# Add gold
	var gold_amount = loot.get("gold", 0)
	if gold_amount > 0 and GameState:
		GameState.add_gold(gold_amount)

	# Add items would go here
	treasure_collected.emit(loot)


## Use portal to travel between realms
func _use_portal(obj: Dictionary) -> void:
	var dest_realm = obj.data.get("destination_realm", "")
	var dest_map = obj.data.get("destination_map", "")
	print("Portal to: ", dest_realm, " / ", dest_map)

	if GameState and not dest_realm.is_empty():
		GameState.travel_to_world(dest_realm)

	if not dest_map.is_empty():
		load_map(dest_map)


## Rest at a site to heal
func _rest_at_site(obj: Dictionary) -> void:
	var heal_percent = obj.data.get("heal_percent", 25)
	print("Resting... healing ", heal_percent, "%")

	# Heal party members
	if CharacterSystem:
		for character in CharacterSystem.get_party():
			var max_hp = character.get("derived", {}).get("max_hp", 100)
			var heal_amount = int(max_hp * heal_percent / 100.0)
			CharacterSystem.heal_character(character.get("id", ""), heal_amount)


## Use shrine for buff
func _use_shrine(obj: Dictionary) -> void:
	var buff_type = obj.data.get("buff_type", "")
	var buff_value = obj.data.get("buff_value", 0)
	print("Shrine blessing: ", buff_type, " +", buff_value)
	# Would apply temporary buff to party


# ============================================
# TURN MANAGEMENT
# ============================================

## End the current turn and refresh movement
func end_turn() -> void:
	movement_points = max_movement_points
	movement_points_changed.emit(int(movement_points), int(max_movement_points))
	turn_ended.emit()
	print("Turn ended. Movement restored to ", max_movement_points)

	# Future: Process enemy movements here


## Get current movement points
func get_movement_points() -> float:
	return movement_points


## Get max movement points
func get_max_movement_points() -> float:
	return max_movement_points


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


## Get party position
func get_party_position() -> Vector2i:
	return party_position


## Check if tile has been visited (for fog of war)
func is_tile_visited(pos: Vector2i) -> bool:
	return visited_tiles.get(pos, false)


## Reveal tiles around a position (for exploration)
func reveal_area(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if is_valid_position(pos):
				visited_tiles[pos] = true


## Get save data for persistence
func get_save_data() -> Dictionary:
	return {
		"current_map_id": current_map_id,
		"party_position": {"x": party_position.x, "y": party_position.y},
		"movement_points": movement_points,
		"visited_tiles": _serialize_positions(visited_tiles.keys()),
		"collected_objects": collected_objects.duplicate()
	}


## Load save data
func load_save_data(data: Dictionary) -> void:
	current_map_id = data.get("current_map_id", "")
	var pos_data = data.get("party_position", {"x": 1, "y": 1})
	party_position = Vector2i(pos_data.x, pos_data.y)
	movement_points = data.get("movement_points", max_movement_points)

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
