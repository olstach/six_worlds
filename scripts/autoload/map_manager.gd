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
signal event_triggered(event_id: String, object: Dictionary)  # For event objects -> EventManager
signal pickup_collected(object: Dictionary, rewards: Array)   # For pickup objects -> show message
signal portal_entered(destination: Dictionary)                # For portal objects
signal map_loaded(map_id: String)
signal map_paused()
signal map_resumed()
signal mob_met_player(mob: Dictionary)          # Any mob reaches player tile
signal mob_combat_triggered(mob: Dictionary)    # Hostile/aggressive mob forces combat
signal mob_event_triggered(mob: Dictionary)     # Friendly mob opens event dialog
signal mob_started_pursuit(mob: Dictionary)     # Aggressive mob spotted player
signal mob_lost_pursuit(mob: Dictionary)        # Aggressive mob gave up chase
signal discovery_made(pos: Vector2i, discovery: Dictionary)  # Hidden find on terrain

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

# Terrain -> movement ability required to traverse when normally impassable
# If the party has the matching ability, the terrain becomes passable at reduced speed
const TERRAIN_ABILITIES: Dictionary = {
	Terrain.WATER: "water_walking",
	Terrain.MOUNTAINS: "flight",
	Terrain.LAVA: "lava_immunity"   # flight also works (checked separately)
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

# Base discovery chances per terrain type (before skill bonuses)
# When the party enters one of these terrain types for the first time,
# there's a chance of finding hidden items, gold, XP, or healing
const DISCOVERY_CHANCES: Dictionary = {
	Terrain.RUINS: 0.20,    # 20% base — rubble hides many secrets
	Terrain.FOREST: 0.08,   # 8% base — herbs, abandoned camps
	Terrain.SWAMP: 0.06,    # 6% base — things lost in the muck
	Terrain.HILLS: 0.05,    # 5% base — caves, overlooks
	Terrain.DESERT: 0.04,   # 4% base — buried relics
}

# Map object categories
# EVENT: Opens an event dialog (FTL-style). Shops, combats, quests, dungeons,
#        NPCs - all handled through EventManager with branching choices.
# PICKUP: Gives rewards immediately with a message popup. Treasure chests,
#         shrines, fountains, supply caches. May or may not disappear.
# PORTAL: Special - transitions between realm maps.
enum ObjectType {
	EVENT = 0,   # Triggers EventManager dialog (shops, quests, battles, NPCs)
	PICKUP = 1,  # Immediate reward with message (chests, shrines, fountains)
	PORTAL = 2   # Realm/map transition
}

# Mob movement modes
enum MobMode {
	STATIONARY = 0,  # Stays in place, never moves
	PATROL = 1,      # Follows a fixed route back and forth
	ROAMING = 2      # Wanders randomly around home position
}

# Mob attitudes toward the player
enum MobAttitude {
	FRIENDLY = 0,    # Opens an event dialog when met (wandering trader, monk, etc.)
	HOSTILE = 1,     # Triggers combat when player steps on their tile
	AGGRESSIVE = 2   # Actively pursues the player when in detection range
}

# Pickup reward types for the "rewards" array in pickup data
# Each reward is a dict: {"type": "gold", "value": 50}
# Supported types:
#   gold     - value = amount
#   xp       - value = amount
#   item     - value = item_id
#   heal     - value = percent of max HP (e.g., 25 = 25%)
#   mana     - value = percent of max mana restored
#   buff     - value = {stat, amount, duration} dict
#   karma    - value = {realm, amount} dict (hidden from player)

# ============================================
# MAP STATE
# ============================================

var current_map_id: String = ""
var map_size: Vector2i = Vector2i(24, 16)
var tiles: Dictionary = {}         # Vector2i -> Terrain type
var objects: Dictionary = {}       # Vector2i -> MapObject data
var visited_tiles: Dictionary = {} # Vector2i -> bool (fog of war)
var collected_objects: Array[String] = []  # IDs of consumed one-time objects
var defeated_mobs: Array[String] = []     # IDs of mobs that won't respawn

# Region definitions loaded from map JSON
# Each region maps to a rect: {tiles_rect: [x, y, x2, y2]}
var regions: Dictionary = {}  # region_id -> {tiles_rect: Array}

# Active movement abilities (set by buffs, spells, items)
# When active, these allow traversal of normally impassable terrain
var movement_abilities: Dictionary = {}  # ability_name -> bool

# Tiles already searched for discoveries (prevents re-rolling)
var searched_tiles: Dictionary = {}  # Vector2i -> bool

# ============================================
# MOB STATE
# ============================================

## All active mobs on the current map. Each mob is a Dictionary:
## {
##   "id": String,                   # Unique mob identifier
##   "name": String,                 # Display name
##   "icon": String,                 # Icon key for rendering
##   "mode": MobMode,               # STATIONARY, PATROL, or ROAMING
##   "attitude": MobAttitude,        # FRIENDLY, HOSTILE, or AGGRESSIVE
##   "speed": float,                 # Movement speed multiplier (relative to base_speed)
##   "position": Vector2i,           # Current tile position
##   "home_position": Vector2i,      # Starting position (for roaming radius)
##   "world_position": Vector2,      # Smooth world-space position for rendering
##   "data": Dictionary,             # Event/combat data (event_id, enemy_group, etc.)
##
##   -- Patrol mode --
##   "patrol_route": Array[Vector2i],# Waypoints to follow
##   "patrol_index": int,            # Current waypoint index
##   "patrol_forward": bool,         # True = advancing, false = returning
##
##   -- Roaming mode --
##   "roam_radius": int,             # Max tiles from home_position
##   "roam_pause": float,            # Seconds to wait at each tile before moving again
##   "roam_timer": float,            # Countdown timer for current pause
##
##   -- Aggressive attitude --
##   "aggression": float,            # 0-1 scale affecting detection range and patience
##   "detect_range": int,            # Tiles away to notice the player (derived from aggression)
##   "pursuit_patience": float,      # Seconds of pursuit before giving up (derived from aggression)
##   "leash_range": int,             # Max tiles from home before giving up (derived from aggression)
##   "is_pursuing": bool,            # Currently chasing the player
##   "pursuit_timer": float,         # How long this mob has been pursuing
##   "pursuit_path": Array[Vector2i],# Current path toward player
##   "pursuit_path_index": int,      # Progress along pursuit path
##
##   -- Movement interpolation --
##   "move_progress": float,         # 0-1 progress between tiles
##   "move_from": Vector2i,          # Tile moving from
##   "move_target": Vector2i,        # Tile moving toward
##   "is_moving": bool               # Currently in motion
## }
var mobs: Array[Dictionary] = []

## How often aggressive mobs recalculate path to player (seconds)
const PURSUIT_REPATH_INTERVAL: float = 1.0

## How often roaming mobs pick a new direction (seconds, base before randomization)
const ROAM_BASE_PAUSE: float = 2.0

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
	# Always process mobs (they move independently of the player)
	if not _is_paused:
		_process_mobs(delta)

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

		# Reveal area around new position (Manhattan distance 2 = wider diamond)
		visited_tiles[target_tile] = true
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if absi(dx) + absi(dy) <= 2:
					var reveal_pos = target_tile + Vector2i(dx, dy)
					if is_valid_position(reveal_pos):
						visited_tiles[reveal_pos] = true

		party_moved.emit(old_pos, target_tile)

		# Check for hidden discoveries on this terrain
		_check_discovery(target_tile)

		# Check for object interaction on arrival
		var obj = get_object_at(target_tile)
		if not obj.is_empty():
			_interact_with_object(obj)
			# If object blocks movement (enemy), stop here
			if obj.get("blocking", false):
				_finish_movement()
				return

		# Check for mob interaction on arrival
		var mob = get_mob_at(target_tile)
		if not mob.is_empty():
			_handle_mob_encounter(mob)
			# Hostile and aggressive mobs stop the player
			if mob.attitude == MobAttitude.HOSTILE or mob.attitude == MobAttitude.AGGRESSIVE:
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

	# Try static JSON map first
	var file_path = "res://resources/data/maps/%s.json" % map_id
	if FileAccess.file_exists(file_path):
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
		print("Map loaded (static): ", map_id)
		return true

	# Try procedural generation from realm config
	# "hell_01" → realm "hell", "hungry_ghost_01" → realm "hungry_ghost"
	var parts = map_id.rsplit("_", true, 1)
	var realm = parts[0] if parts.size() > 1 else map_id
	var config_path = "res://resources/data/map_configs/%s.json" % realm
	if FileAccess.file_exists(config_path):
		var data = MapGenerator.generate_from_config(config_path)
		if not data.is_empty():
			_apply_map_data(data)
			current_map_id = map_id
			map_loaded.emit(map_id)
			print("Map loaded (generated): ", map_id)
			return true

	# Fallback to default test map
	push_warning("MapManager: No static map or config found for: " + map_id)
	_generate_default_map(map_id)
	return true


## Apply parsed map data
func _apply_map_data(data: Dictionary) -> void:
	map_size = Vector2i(data.get("width", 24), data.get("height", 16))
	base_speed = data.get("base_speed", 3.0)

	tiles.clear()
	objects.clear()
	regions.clear()
	searched_tiles.clear()

	# Load regions (if present)
	var region_data = data.get("regions", {})
	for region_id in region_data:
		regions[region_id] = region_data[region_id]

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
			"name": obj_data.get("name", "Unknown"),
			"icon": obj_data.get("icon", "event")
		}

	# Load mobs
	mobs.clear()
	var mobs_data = data.get("mobs", [])
	for mob_data in mobs_data:
		_spawn_mob_from_data(mob_data)

	# Set party starting position
	var start_pos = data.get("start_position", {"x": 1, "y": 1})
	party_position = Vector2i(start_pos.get("x", 1), start_pos.get("y", 1))
	party_world_position = _tile_to_world(party_position)
	visited_tiles[party_position] = true

	# Reveal area around starting position — scale with map size
	var reveal_radius = 3
	if map_size.x > 48 or map_size.y > 48:
		reveal_radius = 5
	reveal_area(party_position, reveal_radius)


## Generate a simple default map for testing
func _generate_default_map(map_id: String) -> void:
	current_map_id = map_id
	map_size = Vector2i(24, 16)
	tiles.clear()
	objects.clear()
	mobs.clear()

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

	# Event objects (open FTL-style dialogs via EventManager)
	_add_object(Vector2i(6, 5), ObjectType.EVENT, {
		"name": "Demon Patrol",
		"event_id": "default_demon_patrol",
		"description": "A group of demons blocks the road."
	}, true, true)

	_add_object(Vector2i(15, 4), ObjectType.EVENT, {
		"name": "Wandering Monk",
		"event_id": "default_wandering_monk",
		"description": "A monk sits by the roadside in meditation."
	}, true, false)

	_add_object(Vector2i(20, 8), ObjectType.EVENT, {
		"name": "Roadside Trader",
		"event_id": "default_roadside_trader",
		"description": "A trader has set up a small stall by the road."
	}, false, false)

	# Pickup objects (immediate rewards with message)
	_add_object(Vector2i(9, 11), ObjectType.PICKUP, {
		"name": "Abandoned Cache",
		"message": "You find a stash of supplies hidden under some rocks.",
		"rewards": [
			{"type": "gold", "value": 50},
			{"type": "item", "value": "health_potion"}
		]
	}, true, false)

	_add_object(Vector2i(2, 14), ObjectType.PICKUP, {
		"name": "Campfire",
		"message": "You rest by the warm fire. Your party feels refreshed.",
		"rewards": [
			{"type": "heal", "value": 25}
		]
	}, false, false)

	# Portal objects (realm transitions)
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
## Accounts for movement abilities (water_walking, flight, etc.)
func get_terrain_speed(pos: Vector2i) -> float:
	var terrain = get_terrain(pos)
	var base_speed = TERRAIN_SPEED.get(terrain, 1.0)
	if base_speed > 0:
		return base_speed
	# Check if a movement ability overrides impassability
	var required = TERRAIN_ABILITIES.get(terrain, "")
	if not required.is_empty() and movement_abilities.get(required, false):
		return 0.75  # Ability-enabled traversal is slower than normal
	# Flight overrides mountains and lava
	if movement_abilities.get("flight", false) and terrain in [Terrain.MOUNTAINS, Terrain.LAVA]:
		return 0.5  # Flying over obstacles is slow
	return base_speed  # Still impassable


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


## Check if terrain is passable (accounts for movement abilities)
func is_passable(pos: Vector2i) -> bool:
	return get_terrain_speed(pos) > 0


## Enable or disable a movement ability (e.g. "water_walking", "flight", "lava_immunity")
func set_movement_ability(ability: String, active: bool) -> void:
	movement_abilities[ability] = active


## Check if a movement ability is active
func has_movement_ability(ability: String) -> bool:
	return movement_abilities.get(ability, false)


## Clear all movement abilities (e.g. on map change)
func clear_movement_abilities() -> void:
	movement_abilities.clear()


## Get the region name at a tile position (e.g. "cold_hell", "fire_hell")
## Returns "" if no region is defined for that position
func get_region_at(pos: Vector2i) -> String:
	for region_id in regions:
		var rect = regions[region_id].get("tiles_rect", [])
		if rect.size() >= 4:
			if pos.x >= rect[0] and pos.y >= rect[1] and pos.x <= rect[2] and pos.y <= rect[3]:
				return region_id
	return ""


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


## Update a field in a specific map object's data dict.
## Used by shop_ui to persist veteran's camp claimed training slots.
func update_object_data(obj_id: String, key: String, value) -> void:
	for pos in objects:
		if objects[pos].get("id", "") == obj_id:
			objects[pos]["data"][key] = value
			return
	push_warning("MapManager.update_object_data: object not found: " + obj_id)


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

	# Pause movement for event interactions (they need player attention)
	if obj.type == ObjectType.EVENT or obj.get("blocking", false):
		stop_movement()

	object_interacted.emit(obj)

	match obj.type:
		ObjectType.EVENT:
			_handle_event_object(obj)
		ObjectType.PICKUP:
			_handle_pickup_object(obj)
		ObjectType.PORTAL:
			_handle_portal_object(obj)

	# Remove one-time objects after interaction (except EVENTs - those are
	# removed when the event display closes, so they persist during the event)
	if obj.one_time and obj.type != ObjectType.EVENT:
		collected_objects.append(obj.id)
		objects.erase(obj.position)


# ============================================
# EVENT OBJECTS
# ============================================
# Event objects open FTL-style dialogs through EventManager.
# The event_id points to an event definition that can contain:
# - Dialogue text and choices
# - Combat encounters (player chooses to fight or flee)
# - Shop interfaces (through event outcome)
# - Quest chains (multi-step events)
# - Dungeon entries (series of combat + events)

func _handle_event_object(obj: Dictionary) -> void:
	pause_movement()
	var event_id = obj.data.get("event_id", "")
	if event_id.is_empty():
		push_warning("MapManager: Event object has no event_id: " + obj.get("name", "?"))
		return

	event_triggered.emit(event_id, obj)


# ============================================
# PICKUP OBJECTS
# ============================================
# Pickup objects give rewards immediately and show a brief message.
# They don't open a dialog - just a notification/popup.
#
# Pickup data format:
# {
#   "message": "You found a cache of gold hidden in the snow!",
#   "rewards": [
#     {"type": "gold", "value": 50},
#     {"type": "item", "value": "health_potion"},
#     {"type": "item_random", "value": ["health_potion", "mana_potion"]},
#     {"type": "heal", "value": 25},         # percentage of max HP
#     {"type": "mana", "value": 20},         # percentage of max mana
#     {"type": "damage", "value": 15},       # flat HP damage to all party (cursed simples)
#     {"type": "buff", "value": {"stat": "strength", "amount": 2, "combats_remaining": 1}},
#     {"type": "cleanse", "value": 1},       # future: clear N map statuses from party
#     {"type": "karma", "value": {"realm": "god", "amount": 5}}
#   ]
# }
# buff.stat can be an attribute name (strength/constitution/finesse/focus/awareness/charm/luck)
# or a derived stat name (fire_resistance, spellpower_fire, initiative, loot_chance_pct, xp_gain_pct).
# combats_remaining: 1 = next combat only, 3 = up to 3 combats, -1 = permanent (use sparingly).

func _handle_pickup_object(obj: Dictionary) -> void:
	var data = obj.data
	var message = data.get("message", "You found something.")
	var rewards = data.get("rewards", [])

	# Resolve any array ranges [min, max] → rolled values (e.g. "value": [25, 50])
	# Only treat a 2-element array as a numeric range when both elements are numbers.
	# String arrays (e.g. item_random lists with exactly 2 items) must NOT be resolved.
	var resolved_rewards: Array = []
	for reward in rewards:
		var r = reward.duplicate()
		var v = r.get("value", 0)
		if v is Array and v.size() == 2 and (v[0] is int or v[0] is float):
			r["value"] = randi_range(int(v[0]), int(v[1]))
		resolved_rewards.append(r)

	# Apply each reward
	for reward in resolved_rewards:
		_apply_reward(reward)

	pickup_collected.emit(obj, resolved_rewards)


## Apply a single reward from a pickup object
func _apply_reward(reward: Dictionary) -> void:
	var reward_type = reward.get("type", "")
	var value = reward.get("value", 0)

	match reward_type:
		"gold":
			GameState.add_gold(int(value))

		"xp":
			# Distribute XP to whole party via CompanionSystem (applies party multiplier and updates companion free_xp)
			CompanionSystem.apply_party_xp(int(value))

		"item":
			# Add item to party inventory (resolve template items first)
			var item_id_str := str(value)
			if ItemSystem.is_template_item(item_id_str):
				var gen_id := ItemSystem.resolve_random_generate(item_id_str)
				if gen_id != "":
					item_id_str = gen_id
			ItemSystem.add_to_inventory(item_id_str)

		"heal":
			# Heal all party members by percentage
			for character in CharacterSystem.get_party():
				var derived = character.get("derived", {})
				var max_hp = derived.get("max_hp", 100)
				var heal_amount = int(max_hp * int(value) / 100.0)
				derived["current_hp"] = min(derived.get("current_hp", max_hp) + heal_amount, max_hp)

		"mana":
			# Restore mana to all party members by percentage
			for character in CharacterSystem.get_party():
				var derived = character.get("derived", {})
				var max_mana = derived.get("max_mana", 100)
				var restore = int(max_mana * int(value) / 100.0)
				derived["current_mana"] = min(derived.get("current_mana", max_mana) + restore, max_mana)

		"buff":
			# Temporary stat buff stored in GameState.active_map_buffs.
			# value = {"stat": "strength", "amount": 2, "combats_remaining": 1}
			if value is Dictionary:
				var stat: String = value.get("stat", "")
				var amount = value.get("amount", 0)
				var combats: int = value.get("combats_remaining", 1)
				if GameState and stat != "":
					GameState.active_map_buffs.append({
						"stat": stat, "amount": amount, "combats_remaining": combats
					})
					# Re-derive stats for all party so buff is reflected immediately
					for char in CharacterSystem.get_party():
						CharacterSystem.update_derived_stats(char)

		"damage":
			# Cursed simple: flat HP damage to all party members (minimum 1 HP left)
			for char in CharacterSystem.get_party():
				var derived = char.get("derived", {})
				derived["current_hp"] = max(derived.get("current_hp", 1) - int(value), 1)

		"item_random":
			# Pick a random item from the provided array of item IDs
			if value is Array and value.size() > 0:
				var chosen: String = str(value[randi() % value.size()])
				# Resolve template items (e.g. good_iron_weapon) into real generated items
				if ItemSystem.is_template_item(chosen):
					var gen_id = ItemSystem.resolve_random_generate(chosen)
					if gen_id != "":
						chosen = gen_id
				reward["chosen"] = chosen  # store for toast display
				ItemSystem.add_to_inventory(chosen)

		"item_random_scaled":
			# Pick a random item appropriate to the party's power level.
			# value = {"tiers": {"weak": [...], "medium": [...], "strong": [...]}}
			# Party power ≤ 30 → weak, ≤ 65 → medium, > 65 → strong.
			if value is Dictionary:
				var party_power: float = 0.0
				var party = CharacterSystem.get_party()
				if party.size() > 0:
					var total: float = 0.0
					for member in party:
						var attrs = member.get("attributes", {})
						for attr_val in attrs.values():
							total += maxi(0, int(attr_val) - 10)
						var skills = member.get("skills", {})
						for skill_lvl in skills.values():
							total += int(skill_lvl) * 8
					party_power = total / float(party.size())

				var tiers: Dictionary = value.get("tiers", {})
				var pool: Array
				if party_power <= 30:
					pool = tiers.get("weak", [])
				elif party_power <= 65:
					pool = tiers.get("medium", [])
				else:
					pool = tiers.get("strong", [])
				# Fall back to any non-empty tier if preferred tier is empty
				if pool.is_empty():
					pool = tiers.get("medium", tiers.get("weak", tiers.get("strong", [])))
				if pool.size() > 0:
					var chosen: String = str(pool[randi() % pool.size()])
					# Resolve template items (e.g. good_iron_weapon) into real generated items
					if ItemSystem.is_template_item(chosen):
						var gen_id = ItemSystem.resolve_random_generate(chosen)
						if gen_id != "":
							chosen = gen_id
					reward["chosen"] = chosen
					ItemSystem.add_to_inventory(chosen)

		"cleanse":
			# Clear persisting overworld DoT statuses from all party members
			for char in CharacterSystem.get_party():
				char["overworld_statuses"] = []

		"spell":
			# Spell simple: teach a random spell of the given school+tier to all party members who
			# don't already know it. value = {"school": "Fire", "tier": 1}
			# Tier maps to spell level: 1→1, 2→3, 3→5, 4→7, 5→9
			if value is Dictionary:
				var school: String = value.get("school", "")
				var tier: int = clamp(int(value.get("tier", 1)), 1, 5)
				var tier_to_level: Array = [0, 1, 3, 5, 7, 9]
				var spell_level: int = tier_to_level[tier]
				var spell_id: String = CharacterSystem.pick_random_spell_for_party(school, spell_level)
				if spell_id != "":
					reward["chosen_spell"] = spell_id  # store for toast display
					for character in CharacterSystem.get_party():
						if not CharacterSystem.knows_spell(character, spell_id):
							CharacterSystem.learn_spell(character, spell_id)

		"food":
			# Add directly to food supply
			GameState.add_supply("food", int(value))

		"karma":
			# Hidden karma adjustment
			if value is Dictionary and KarmaSystem:
				var realm = value.get("realm", "")
				var amount = value.get("amount", 0)
				KarmaSystem.add_karma(realm, amount)
				# No print - karma is hidden from player!


# ============================================
# PORTAL OBJECTS
# ============================================

func _handle_portal_object(obj: Dictionary) -> void:
	stop_movement()
	var dest_realm = obj.data.get("destination_realm", "")
	var dest_map = obj.data.get("destination_map", "")
	portal_entered.emit(obj.data)

	if GameState and not dest_realm.is_empty():
		# Unlock the destination realm as a reincarnation option (meta-progression)
		GameState.unlock_world(dest_realm)
		GameState.travel_to_world(dest_realm)

	if not dest_map.is_empty():
		load_map(dest_map)


# ============================================
# MOB SYSTEM
# ============================================
# Mobs are mobile entities on the overworld map. Unlike static objects,
# they move around independently in real-time.
#
# Movement modes:
#   STATIONARY - Never moves. Basically a static object with an icon.
#   PATROL     - Walks back and forth along a defined route of waypoints.
#   ROAMING    - Wanders randomly within a radius of its home position.
#
# Attitudes:
#   FRIENDLY   - Opens an event dialog when met (shops, NPCs, quests).
#   HOSTILE    - Triggers combat on contact. Does not pursue.
#   AGGRESSIVE - Pursues the player when in range. Triggers combat on contact.
#                Gives up after running out of patience or straying too far.
#
# Aggression (0.0 to 1.0) governs aggressive mobs:
#   detect_range     = 3 + floor(aggression * 7)    -> 3 to 10 tiles
#   pursuit_patience = 5 + aggression * 25           -> 5 to 30 seconds
#   leash_range      = 5 + floor(aggression * 15)    -> 5 to 20 tiles from home

## Spawn a mob from JSON data
func _spawn_mob_from_data(mob_data: Dictionary) -> void:
	var mob_id = mob_data.get("id", "mob_%d" % mobs.size())

	# Skip defeated mobs
	if mob_id in defeated_mobs:
		return

	var pos = Vector2i(mob_data.get("x", 0), mob_data.get("y", 0))
	var mode = int(mob_data.get("mode", MobMode.STATIONARY))
	var attitude = int(mob_data.get("attitude", MobAttitude.HOSTILE))
	var aggression = clampf(mob_data.get("aggression", 0.5), 0.0, 1.0)

	var mob: Dictionary = {
		"id": mob_id,
		"name": mob_data.get("name", "Unknown Creature"),
		"icon": mob_data.get("icon", "enemy"),
		"mode": mode,
		"attitude": attitude,
		"speed": mob_data.get("speed", 0.6),  # Mobs default to 60% of base_speed
		"position": pos,
		"home_position": pos,
		"world_position": _tile_to_world(pos),
		"data": mob_data.get("data", {}),

		# Patrol
		"patrol_route": [],
		"patrol_index": 0,
		"patrol_forward": true,

		# Roaming
		"roam_radius": mob_data.get("roam_radius", 4),
		"roam_pause": mob_data.get("roam_pause", ROAM_BASE_PAUSE),
		"roam_timer": randf_range(0.5, ROAM_BASE_PAUSE),  # Stagger initial movement

		# Aggression (only matters for AGGRESSIVE attitude)
		"aggression": aggression,
		"detect_range": 3 + int(aggression * 7),
		"pursuit_patience": 5.0 + aggression * 25.0,
		"leash_range": 5 + int(aggression * 15),
		"is_pursuing": false,
		"pursuit_timer": 0.0,
		"pursuit_path": [] as Array[Vector2i],
		"pursuit_path_index": 0,
		"pursuit_repath_timer": 0.0,

		# Movement interpolation
		"move_progress": 0.0,
		"move_from": pos,
		"move_target": pos,
		"is_moving": false
	}

	# Parse patrol route from JSON waypoints
	if mode == MobMode.PATROL:
		var route_data = mob_data.get("patrol_route", [])
		var route: Array[Vector2i] = []
		for wp in route_data:
			if wp is Dictionary:
				route.append(Vector2i(wp.get("x", 0), wp.get("y", 0)))
		# Prepend home position as first waypoint if not already there
		if route.is_empty() or route[0] != pos:
			route.insert(0, pos)
		mob.patrol_route = route

	# Tag mob with its region based on spawn position
	mob["region"] = get_region_at(pos)

	mobs.append(mob)


## Main mob processing - called every frame from _process()
func _process_mobs(delta: float) -> void:
	for mob in mobs:
		# Update movement interpolation (smooth position)
		if mob.is_moving:
			_update_mob_movement(mob, delta)

		# If not currently moving between tiles, decide what to do next
		if not mob.is_moving:
			match mob.mode:
				MobMode.STATIONARY:
					pass  # Never moves
				MobMode.PATROL:
					_process_patrol_mob(mob, delta)
				MobMode.ROAMING:
					_process_roaming_mob(mob, delta)

			# Aggressive mobs check for pursuit regardless of movement mode
			if mob.attitude == MobAttitude.AGGRESSIVE:
				_process_aggressive_mob(mob, delta)


## Update smooth movement interpolation for a mob
func _update_mob_movement(mob: Dictionary, delta: float) -> void:
	var speed_mult = get_terrain_speed(mob.move_target)
	if speed_mult <= 0:
		# Somehow targeting impassable tile, cancel
		mob.is_moving = false
		mob.world_position = _tile_to_world(mob.position)
		return

	var effective_speed = base_speed * mob.speed * speed_mult
	mob.move_progress += effective_speed * delta

	# Interpolate world position
	var from_world = _tile_to_world(mob.move_from)
	var to_world = _tile_to_world(mob.move_target)
	mob.world_position = from_world.lerp(to_world, clampf(mob.move_progress, 0.0, 1.0))

	# Arrived at target tile
	if mob.move_progress >= 1.0:
		mob.move_progress = 0.0
		mob.position = mob.move_target
		mob.is_moving = false
		mob.world_position = _tile_to_world(mob.position)

		# Check if mob landed on the player's tile
		if mob.position == party_position:
			_handle_mob_encounter(mob)


## Start a mob moving to an adjacent tile
func _start_mob_move(mob: Dictionary, target: Vector2i) -> void:
	if not is_valid_position(target) or not is_passable(target):
		return
	mob.move_from = mob.position
	mob.move_target = target
	mob.move_progress = 0.0
	mob.is_moving = true


## Process patrol mode: follow waypoints back and forth
func _process_patrol_mob(mob: Dictionary, _delta: float) -> void:
	# If pursuing, don't patrol
	if mob.get("is_pursuing", false):
		return

	var route = mob.patrol_route as Array
	if route.size() < 2:
		return  # Need at least 2 waypoints

	var current_wp = route[mob.patrol_index] as Vector2i

	# If we're at the current waypoint, advance to next
	if mob.position == current_wp:
		if mob.patrol_forward:
			mob.patrol_index += 1
			if mob.patrol_index >= route.size():
				mob.patrol_index = route.size() - 2
				mob.patrol_forward = false
		else:
			mob.patrol_index -= 1
			if mob.patrol_index < 0:
				mob.patrol_index = 1
				mob.patrol_forward = true

		# Clamp just in case
		mob.patrol_index = clampi(mob.patrol_index, 0, route.size() - 1)
		current_wp = route[mob.patrol_index]

	# Move one step toward the current waypoint
	var step = _get_step_toward(mob.position, current_wp)
	if step != mob.position:
		_start_mob_move(mob, step)


## Process roaming mode: wander randomly near home
func _process_roaming_mob(mob: Dictionary, delta: float) -> void:
	# If pursuing, don't roam
	if mob.get("is_pursuing", false):
		return

	# Wait before picking a new direction
	mob.roam_timer -= delta
	if mob.roam_timer > 0:
		return

	# Reset timer with some randomness
	mob.roam_timer = mob.roam_pause + randf_range(-0.5, 1.0)

	# Pick a random passable neighbor within roam radius
	var neighbors: Array[Vector2i] = []
	for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var candidate = mob.position + dir
		if not is_valid_position(candidate) or not is_passable(candidate):
			continue
		# Check roam radius from home
		var dist_from_home = absi(candidate.x - mob.home_position.x) + absi(candidate.y - mob.home_position.y)
		if dist_from_home <= mob.roam_radius:
			neighbors.append(candidate)

	if not neighbors.is_empty():
		var chosen = neighbors[randi() % neighbors.size()]
		_start_mob_move(mob, chosen)


## Process aggressive attitude: detect and pursue the player
func _process_aggressive_mob(mob: Dictionary, delta: float) -> void:
	var dist_to_player = absi(mob.position.x - party_position.x) + absi(mob.position.y - party_position.y)

	if mob.is_pursuing:
		# Update pursuit timer
		mob.pursuit_timer += delta

		# Check if we should give up
		var dist_from_home = absi(mob.position.x - mob.home_position.x) + absi(mob.position.y - mob.home_position.y)
		if mob.pursuit_timer >= mob.pursuit_patience or dist_from_home >= mob.leash_range:
			_end_pursuit(mob)
			return

		# Periodically recalculate path to player
		mob.pursuit_repath_timer -= delta
		if mob.pursuit_repath_timer <= 0:
			mob.pursuit_repath_timer = PURSUIT_REPATH_INTERVAL
			mob.pursuit_path = find_path(mob.position, party_position)
			mob.pursuit_path_index = 0

		# Follow pursuit path
		if not mob.pursuit_path.is_empty() and mob.pursuit_path_index < mob.pursuit_path.size():
			var next_tile = mob.pursuit_path[mob.pursuit_path_index]
			_start_mob_move(mob, next_tile)
			mob.pursuit_path_index += 1
	else:
		# Not pursuing yet - check if player is in detection range
		if dist_to_player <= mob.detect_range:
			_start_pursuit(mob)


## Begin pursuit of the player
func _start_pursuit(mob: Dictionary) -> void:
	mob.is_pursuing = true
	mob.pursuit_timer = 0.0
	mob.pursuit_repath_timer = 0.0  # Immediately calculate path
	mob.pursuit_path = find_path(mob.position, party_position)
	mob.pursuit_path_index = 0
	mob_started_pursuit.emit(mob)


## End pursuit and return to normal behavior
func _end_pursuit(mob: Dictionary) -> void:
	mob.is_pursuing = false
	mob.pursuit_timer = 0.0
	mob.pursuit_path.clear()
	mob.pursuit_path_index = 0
	mob_lost_pursuit.emit(mob)


## Handle what happens when a mob and the player are on the same tile
func _handle_mob_encounter(mob: Dictionary) -> void:
	mob_met_player.emit(mob)

	match mob.attitude:
		MobAttitude.FRIENDLY:
			# Open event dialog (same as event objects)
			stop_movement()
			var event_id = mob.data.get("event_id", "")
			if not event_id.is_empty():
				mob_event_triggered.emit(mob)
				event_triggered.emit(event_id, mob)
			else:
				push_warning("Friendly mob has no event_id: " + mob.name)

		MobAttitude.HOSTILE, MobAttitude.AGGRESSIVE:
			# Trigger combat
			stop_movement()
			# End pursuit if aggressive
			if mob.is_pursuing:
				mob.is_pursuing = false
				mob.pursuit_path.clear()
			mob_combat_triggered.emit(mob)


## Get step toward a target position (one tile in the best direction)
func _get_step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var dx = to.x - from.x
	var dy = to.y - from.y

	# Pick the axis with the larger difference
	if absi(dx) >= absi(dy):
		var step = from + Vector2i(signi(dx), 0)
		if is_valid_position(step) and is_passable(step):
			return step
		# Try the other axis
		if dy != 0:
			step = from + Vector2i(0, signi(dy))
			if is_valid_position(step) and is_passable(step):
				return step
	else:
		var step = from + Vector2i(0, signi(dy))
		if is_valid_position(step) and is_passable(step):
			return step
		# Try the other axis
		if dx != 0:
			step = from + Vector2i(signi(dx), 0)
			if is_valid_position(step) and is_passable(step):
				return step

	return from  # Can't move


## Get mob at a tile position (returns empty dict if none)
func get_mob_at(pos: Vector2i) -> Dictionary:
	for mob in mobs:
		if mob.position == pos:
			return mob
	return {}


## Get all mobs on the map
func get_all_mobs() -> Array[Dictionary]:
	return mobs


## Get all visible mobs (for rendering)
func get_visible_mobs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for mob in mobs:
		if is_tile_visited(mob.position):
			result.append(mob)
	return result


## Remove a mob from the map (e.g., after defeating it)
func remove_mob(mob_id: String) -> void:
	for i in range(mobs.size() - 1, -1, -1):
		if mobs[i].id == mob_id:
			defeated_mobs.append(mob_id)
			mobs.remove_at(i)
			return


## Pause all mob movement (e.g., during combat or events)
func pause_mobs() -> void:
	# Mobs are paused via _is_paused already (checked in _process)
	pass


## Resume mob movement
func resume_mobs() -> void:
	pass


## Advance all mobs by one patrol/roam step — called by the overworld Wait action.
## Unlike _process_mobs(), this is step-based (not frame-based) and has no delta.
func tick_mobs() -> void:
	for mob in mobs:
		if mob.is_moving:
			continue  # Already mid-move, skip this tick
		match mob.get("mode", MobMode.STATIONARY):
			MobMode.PATROL:
				_process_patrol_mob(mob, 0.0)
			MobMode.ROAMING:
				# Force the roam timer to expire so the mob actually moves
				mob.roam_timer = 0.0
				_process_roaming_mob(mob, 100.0)  # large delta to bypass the timer


# ============================================
# EXPLORATION DISCOVERY
# ============================================
# Certain terrain types (ruins, forests, etc.) can yield hidden discoveries
# when the party walks on them for the first time. Discovery chance is
# modified by party skills (Learning, Guile) and Awareness attribute.

## Check for a hidden discovery when entering a tile
func _check_discovery(pos: Vector2i) -> void:
	if pos in searched_tiles:
		return
	searched_tiles[pos] = true

	var terrain = get_terrain(pos)
	var base_chance = DISCOVERY_CHANCES.get(terrain, 0.0)
	if base_chance <= 0:
		return

	# Skill bonus from best party member
	var skill_bonus = _get_best_party_discovery_bonus()
	var final_chance = base_chance + skill_bonus

	if randf() < final_chance:
		var discovery = _generate_discovery(terrain, pos)
		_apply_reward(discovery)
		discovery_made.emit(pos, discovery)


## Calculate the best discovery bonus from any party member
## Learning adds 2% per level, Guile adds 1.5% per level
## Awareness attribute adds 0.5% per point above 10
func _get_best_party_discovery_bonus() -> float:
	var best = 0.0
	for character in CharacterSystem.get_party():
		var skills = character.get("skills", {})
		var attrs = character.get("attributes", {})
		var bonus = skills.get("learning", 0) * 0.02 + skills.get("guile", 0) * 0.015
		bonus += max(0, (attrs.get("awareness", 10) - 10)) * 0.005
		best = max(best, bonus)
	return best


## Generate a discovery reward based on terrain type and region
func _generate_discovery(terrain: int, pos: Vector2i) -> Dictionary:
	var _region = get_region_at(pos)
	var roll = randf()

	match terrain:
		Terrain.RUINS:
			if roll < 0.3:
				return {"type": "gold", "value": randi_range(15, 50),
					"message": "You find coins among the rubble."}
			elif roll < 0.6:
				return {"type": "item", "value": _pick_discovery_item(_region),
					"message": "Something glints in the ruins!"}
			else:
				return {"type": "xp", "value": randi_range(5, 20),
					"message": "Studying the ruins yields insight."}
		Terrain.FOREST:
			if roll < 0.4:
				return {"type": "item", "value": "health_potion",
					"message": "You find herbs growing in the shade."}
			elif roll < 0.7:
				return {"type": "heal", "value": 10,
					"message": "A peaceful glade restores your spirit."}
			else:
				return {"type": "gold", "value": randi_range(5, 25),
					"message": "An abandoned camp has useful supplies."}
		Terrain.SWAMP:
			if roll < 0.5:
				return {"type": "gold", "value": randi_range(10, 35),
					"message": "Something valuable is stuck in the mud."}
			else:
				return {"type": "item", "value": _pick_discovery_item(_region),
					"message": "You pull an object from the mire."}
		Terrain.HILLS:
			if roll < 0.4:
				return {"type": "xp", "value": randi_range(5, 15),
					"message": "The high ground reveals strategic insight."}
			else:
				return {"type": "gold", "value": randi_range(8, 30),
					"message": "You spot a hidden cave with supplies."}
		_:
			return {"type": "gold", "value": randi_range(5, 30),
				"message": "You find something hidden here."}


## Pick a discovery item appropriate to the region
func _pick_discovery_item(region: String) -> String:
	var cold_items = ["health_potion", "leather_gloves", "leather_boots", "copper_ring"]
	var fire_items = ["health_potion", "bone_dagger", "leather_vest", "copper_ring"]
	var default_items = ["health_potion", "copper_ring", "bone_dagger"]

	var pool: Array
	if region == "cold_hell":
		pool = cold_items
	elif region == "fire_hell":
		pool = fire_items
	else:
		pool = default_items
	return pool[randi() % pool.size()]


# ============================================
# UTILITY
# ============================================

## Get object type name for display
func get_object_type_name(type: int) -> String:
	match type:
		ObjectType.EVENT: return "Event"
		ObjectType.PICKUP: return "Pickup"
		ObjectType.PORTAL: return "Portal"
		_: return "Unknown"


## Build a human-readable summary of pickup rewards (for UI)
func get_reward_summary(rewards: Array) -> String:
	var parts: Array[String] = []
	for reward in rewards:
		var rtype = reward.get("type", "")
		var value = reward.get("value", 0)
		match rtype:
			"gold": parts.append("+%d gold" % int(value))
			"xp": parts.append("+%d XP" % int(value))
			"item": parts.append("+%s" % str(value))
			"heal": parts.append("Heal %d%%" % int(value))
			"mana": parts.append("Restore %d%% mana" % int(value))
			"buff":
				if value is Dictionary:
					parts.append("+%d %s" % [value.get("amount", 0), value.get("stat", "")])
			"spell":
				if value is Dictionary:
					var tier_names = ["", "Trace", "Mark", "Locus", "Nexus", "Throne"]
					var tier = clamp(int(value.get("tier", 1)), 1, 5)
					parts.append("%s of %s" % [tier_names[tier], value.get("school", "?")])
	return ", ".join(parts) if not parts.is_empty() else ""


## Get party grid position
func get_party_position() -> Vector2i:
	return party_position


## Get party smooth world position (for rendering)
func get_party_world_position() -> Vector2:
	return party_world_position


## Check if tile has been visited (for fog of war)
func is_tile_visited(pos: Vector2i) -> bool:
	return visited_tiles.get(pos, false)


## Reveal tiles around a position (Manhattan distance = diamond shape)
func reveal_area(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if is_valid_position(pos):
				var dist = absi(dx) + absi(dy)
				if dist <= radius:
					visited_tiles[pos] = true


## Get save data for persistence.
## Saves FULL map state including terrain, objects, and mobs so procedural
## maps can be restored exactly as they were (they're non-deterministic).
func get_save_data() -> Dictionary:
	return {
		"current_map_id": current_map_id,
		"map_size": {"x": map_size.x, "y": map_size.y},
		"base_speed": base_speed,
		"party_position": {"x": party_position.x, "y": party_position.y},
		"visited_tiles": _serialize_positions(visited_tiles.keys()),
		"collected_objects": collected_objects.duplicate(),
		"defeated_mobs": defeated_mobs.duplicate(),
		"terrain": _serialize_terrain(),
		"objects": _serialize_objects(),
		"mobs": _serialize_mobs(),
		"regions": regions.duplicate(true),
		"movement_abilities": movement_abilities.duplicate(),
		"searched_tiles": _serialize_positions(searched_tiles.keys())
	}


## Load save data — restores full map state directly (no regeneration).
func load_save_data(data: Dictionary) -> void:
	stop_movement()

	current_map_id = data.get("current_map_id", "")

	# Restore lists that _apply_map_data checks
	collected_objects.clear()
	for obj_id in data.get("collected_objects", []):
		collected_objects.append(obj_id)

	defeated_mobs.clear()
	for mob_id in data.get("defeated_mobs", []):
		defeated_mobs.append(mob_id)

	# Rebuild the map from saved terrain, objects, and mobs.
	# We construct a data dict matching the format _apply_map_data expects.
	var size_data = data.get("map_size", {"x": 24, "y": 16})
	var map_data: Dictionary = {
		"width": int(size_data.get("x", 24)),
		"height": int(size_data.get("y", 16)),
		"base_speed": data.get("base_speed", 3.0),
		"terrain": data.get("terrain", []),
		"objects": data.get("objects", []),
		"mobs": data.get("mobs", []),
		"regions": data.get("regions", {}),
		# Use saved party position as start so _apply_map_data sets it
		"start_position": data.get("party_position", {"x": 1, "y": 1})
	}

	_apply_map_data(map_data)

	# Now restore state that _apply_map_data doesn't handle:
	# visited tiles (fog of war)
	visited_tiles.clear()
	for pos_str in data.get("visited_tiles", []):
		var parts = pos_str.split(",")
		if parts.size() == 2:
			visited_tiles[Vector2i(int(parts[0]), int(parts[1]))] = true

	# Movement abilities
	movement_abilities.clear()
	var saved_abilities = data.get("movement_abilities", {})
	for ability in saved_abilities:
		movement_abilities[ability] = saved_abilities[ability]

	# Searched tiles
	searched_tiles.clear()
	for pos_str in data.get("searched_tiles", []):
		var parts = pos_str.split(",")
		if parts.size() == 2:
			searched_tiles[Vector2i(int(parts[0]), int(parts[1]))] = true

	# Notify renderer and other listeners that the map is ready
	map_loaded.emit(current_map_id)


## Serialize terrain as a flat int array matching the load format
func _serialize_terrain() -> Array:
	var result: Array = []
	for y in range(map_size.y):
		for x in range(map_size.x):
			result.append(tiles.get(Vector2i(x, y), Terrain.PLAINS))
	return result


## Serialize objects to an array of dicts matching the load format
func _serialize_objects() -> Array:
	var result: Array = []
	for pos in objects:
		var obj = objects[pos]
		result.append({
			"id": obj.get("id", ""),
			"x": pos.x,
			"y": pos.y,
			"type": obj.get("type", ObjectType.EVENT),
			"data": obj.get("data", {}),
			"one_time": obj.get("one_time", false),
			"blocking": obj.get("blocking", false),
			"visible": obj.get("visible", true),
			"name": obj.get("name", "Unknown"),
			"icon": obj.get("icon", "event")
		})
	return result


## Serialize mobs to an array of dicts matching the load format
func _serialize_mobs() -> Array:
	var result: Array = []
	for mob in mobs:
		var mob_data: Dictionary = {
			"id": mob.get("id", ""),
			"x": mob.position.x,
			"y": mob.position.y,
			"name": mob.get("name", ""),
			"icon": mob.get("icon", "enemy"),
			"mode": mob.get("mode", MobMode.STATIONARY),
			"attitude": mob.get("attitude", MobAttitude.HOSTILE),
			"speed": mob.get("speed", 0.6),
			"aggression": mob.get("aggression", 0.5),
			"roam_radius": mob.get("roam_radius", 4),
			"roam_pause": mob.get("roam_pause", ROAM_BASE_PAUSE),
			"data": mob.get("data", {}),
			"region": mob.get("region", "")
		}
		# Serialize patrol route
		if mob.get("mode") == MobMode.PATROL:
			var route: Array = []
			for wp in mob.get("patrol_route", []):
				route.append({"x": wp.x, "y": wp.y})
			mob_data["patrol_route"] = route
		result.append(mob_data)
	return result


## Serialize positions for saving
func _serialize_positions(positions: Array) -> Array[String]:
	var result: Array[String] = []
	for pos in positions:
		result.append("%d,%d" % [pos.x, pos.y])
	return result
