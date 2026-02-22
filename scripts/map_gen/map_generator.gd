extends Node
## MapGenerator - Procedural overworld map generation from realm config files
##
## Produces a Dictionary matching MapManager._apply_map_data() format.
## Each realm has a JSON config defining zones, terrain weights, object/mob pools,
## fixed landmarks, and density parameters. The generator uses:
##   - Weighted random terrain + cellular automata smoothing for natural patches
##   - Mountain wall zones with carved passes
##   - Road carving connecting key areas
##   - BFS connectivity validation (guarantees completable maps)
##   - Object/mob placement from weighted pools with guaranteed minimums

# Terrain enum values (mirrors MapManager.Terrain)
const T_PLAINS = 0
const T_ROAD = 1
const T_FOREST = 2
const T_HILLS = 3
const T_MOUNTAINS = 4
const T_WATER = 5
const T_SWAMP = 6
const T_DESERT = 7
const T_SNOW = 8
const T_LAVA = 9
const T_BRIDGE = 10
const T_ICE = 11
const T_SAND = 12
const T_RUINS = 13

# Terrain types that are impassable by default
const IMPASSABLE: Array[int] = [T_MOUNTAINS, T_WATER, T_LAVA]

# Terrain types considered "interesting" for placing objects (prefer these over plains)
const INTERESTING_TERRAIN: Array[int] = [T_FOREST, T_HILLS, T_RUINS, T_SNOW, T_DESERT, T_SAND]

# Generation state
var _width: int = 0
var _height: int = 0
var _terrain: Array[int] = []  # Flat array [y * width + x]
var _occupied: Dictionary = {}  # Vector2i -> true (tiles claimed by objects/mobs/landmarks)
var _pass_positions: Array[Vector2i] = []  # Center of each mountain pass
var _start_pos: Vector2i = Vector2i.ZERO
var _portal_pos: Vector2i = Vector2i.ZERO
var _objects: Array[Dictionary] = []
var _mobs: Array[Dictionary] = []
var _regions: Dictionary = {}
var _obj_counter: int = 0  # For unique IDs


func _ready() -> void:
	print("MapGenerator initialized")


# ============================================
# PUBLIC API
# ============================================

## Generate a map from a config file path. Returns a Dictionary for _apply_map_data().
## Pass an optional seed_value for reproducible generation (0 = random).
func generate_from_config(config_path: String, seed_value: int = 0) -> Dictionary:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("MapGenerator: Failed to open config: " + config_path)
		return {}

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("MapGenerator: Failed to parse config JSON")
		return {}
	file.close()

	var config = json.get_data()
	return generate(config, seed_value)


## Generate a map from an already-parsed config Dictionary.
func generate(config: Dictionary, seed_value: int = 0) -> Dictionary:
	# Set random seed
	if seed_value != 0:
		seed(seed_value)
	else:
		randomize()

	# Reset state
	_width = int(config.get("width", 96))
	_height = int(config.get("height", 72))
	_terrain.clear()
	_terrain.resize(_width * _height)
	_terrain.fill(T_PLAINS)
	_occupied.clear()
	_pass_positions.clear()
	_objects.clear()
	_mobs.clear()
	_regions.clear()
	_obj_counter = 0

	var zones = config.get("zones", [])
	var landmarks = config.get("fixed_landmarks", [])
	var object_pools = config.get("object_pools", {})
	var mob_pools = config.get("mob_pools", {})
	var density = config.get("density", {})

	# Step 1-2: Generate terrain for each zone
	for zone in zones:
		_generate_zone_terrain(zone)
		_build_region(zone)

	# Step 3: Place fixed landmarks (start, portal, boss, pass guardian)
	_place_fixed_landmarks(landmarks, zones)

	# Carve roads connecting start → nearest pass, pass exit → portal
	_carve_connecting_roads(zones)

	# Step 4: Validate connectivity — ensure start can reach portal
	_validate_connectivity()

	# Step 5: Place objects from pools
	for zone in zones:
		var zone_id = zone.get("id", "")
		if zone.get("type", "") == "mountain_wall":
			continue
		if zone_id in object_pools:
			_place_zone_objects(zone, object_pools[zone_id], density)

	# Step 6: Place mobs from pools
	for zone in zones:
		var zone_id = zone.get("id", "")
		if zone.get("type", "") == "mountain_wall":
			continue
		if zone_id in mob_pools:
			_place_zone_mobs(zone, mob_pools[zone_id], density)

	# Step 7-8: Assemble output
	var result = {
		"id": str(config.get("id", "map")) + "_gen_" + str(randi()),
		"name": config.get("name", "Generated Map"),
		"realm": config.get("id", "unknown"),
		"description": config.get("description", ""),
		"width": _width,
		"height": _height,
		"base_speed": config.get("base_speed", 3.0),
		"start_position": {"x": _start_pos.x, "y": _start_pos.y},
		"regions": _regions,
		"terrain": _terrain.duplicate(),
		"objects": _objects.duplicate(true),
		"mobs": _mobs.duplicate(true)
	}

	return result


# ============================================
# TERRAIN GENERATION
# ============================================

## Generate terrain for a single zone
func _generate_zone_terrain(zone: Dictionary) -> void:
	var rows = zone.get("rows", [0, 0])
	var row_start = int(rows[0])
	var row_end = int(rows[1])

	if zone.get("type", "") == "mountain_wall":
		_generate_mountain_wall(zone, row_start, row_end)
		return

	# Weighted random terrain fill
	var weights = zone.get("terrain_weights", {"0": 100})
	var weight_table = _build_weight_table(weights)

	for y in range(row_start, row_end + 1):
		for x in range(_width):
			_set_terrain(x, y, _pick_weighted(weight_table))

	# Cellular automata smoothing — 3 passes
	for _pass in range(3):
		var new_terrain: Array[int] = _terrain.duplicate()
		for y in range(row_start, row_end + 1):
			for x in range(_width):
				new_terrain[y * _width + x] = _smooth_cell(x, y, row_start, row_end)
		# Apply smoothed result for this zone's rows only
		for y in range(row_start, row_end + 1):
			for x in range(_width):
				_terrain[y * _width + x] = new_terrain[y * _width + x]


## Fill a zone with mountains and carve passes through it
func _generate_mountain_wall(zone: Dictionary, row_start: int, row_end: int) -> void:
	# Fill with mountains
	for y in range(row_start, row_end + 1):
		for x in range(_width):
			_set_terrain(x, y, T_MOUNTAINS)

	# Carve passes
	var pass_count_range = zone.get("pass_count", [1, 2])
	var num_passes = randi_range(int(pass_count_range[0]), int(pass_count_range[1]))
	var pass_width = int(zone.get("pass_width", 3))

	# Distribute passes across the width
	var segment_width = _width / (num_passes + 1)
	for i in range(num_passes):
		var center_x = int(segment_width * (i + 1)) + randi_range(-5, 5)
		center_x = clampi(center_x, pass_width, _width - pass_width - 1)
		var center_y = (row_start + row_end) / 2

		# Carve the pass (rectangular opening)
		for y in range(row_start, row_end + 1):
			for dx in range(-pass_width / 2, pass_width / 2 + 1):
				var px = center_x + dx
				if px >= 0 and px < _width:
					_set_terrain(px, y, T_PLAINS)

		_pass_positions.append(Vector2i(center_x, center_y))


## Cellular automata: pick the most common terrain among 8 neighbors
func _smooth_cell(x: int, y: int, row_min: int, row_max: int) -> int:
	var counts: Dictionary = {}
	var current = _get_terrain(x, y)
	counts[current] = 1  # Slight bias toward keeping current

	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or nx >= _width or ny < row_min or ny > row_max:
				continue
			var t = _get_terrain(nx, ny)
			counts[t] = counts.get(t, 0) + 1

	# Find most common
	var best = current
	var best_count = 0
	for t in counts:
		if counts[t] > best_count:
			best_count = counts[t]
			best = t
	return best


# ============================================
# ROAD CARVING
# ============================================

## Carve roads connecting start → pass → portal
func _carve_connecting_roads(zones: Array) -> void:
	if _pass_positions.is_empty():
		return

	# Find nearest pass to start
	var nearest_pass = _pass_positions[0]
	var best_dist = 99999.0
	for pp in _pass_positions:
		var d = Vector2(_start_pos).distance_to(Vector2(pp))
		if d < best_dist:
			best_dist = d
			nearest_pass = pp

	# Carve road: start → nearest pass entrance (top side of divider)
	var pass_top = Vector2i(nearest_pass.x, nearest_pass.y)
	# Find the top row of the divider
	for zone in zones:
		if zone.get("type", "") == "mountain_wall":
			var rows = zone.get("rows", [0, 0])
			pass_top = Vector2i(nearest_pass.x, int(rows[0]))
			break
	_carve_road_between(_start_pos, pass_top)

	# Carve road: pass exit (bottom of divider) → portal
	var pass_bottom = Vector2i(nearest_pass.x, pass_top.y + 5)
	for zone in zones:
		if zone.get("type", "") == "mountain_wall":
			var rows = zone.get("rows", [0, 0])
			pass_bottom = Vector2i(nearest_pass.x, int(rows[1]))
			break
	_carve_road_between(pass_bottom, _portal_pos)


## Carve a meandering road between two points
func _carve_road_between(from: Vector2i, to: Vector2i) -> void:
	var pos = from
	var max_steps = (_width + _height) * 3  # Safety limit
	var steps = 0

	while pos != to and steps < max_steps:
		steps += 1
		# Set current tile to road (unless it's a landmark or already interesting)
		var current = _get_terrain(pos.x, pos.y)
		if current != T_ROAD and not current in IMPASSABLE:
			_set_terrain(pos.x, pos.y, T_ROAD)

		# Move toward target with some randomness
		var dx = signi(to.x - pos.x)
		var dy = signi(to.y - pos.y)

		# 70% move toward target, 30% wander perpendicular
		if randf() < 0.7:
			# Move in the larger delta direction first
			if absi(to.x - pos.x) > absi(to.y - pos.y):
				pos.x += dx
			else:
				pos.y += dy
		else:
			# Random perpendicular step
			if randf() < 0.5 and dx != 0:
				pos.x += dx
			elif dy != 0:
				pos.y += dy
			else:
				pos.x += dx

		pos.x = clampi(pos.x, 0, _width - 1)
		pos.y = clampi(pos.y, 0, _height - 1)

	# Set final tile
	if _get_terrain(to.x, to.y) != T_ROAD:
		var t = _get_terrain(to.x, to.y)
		if not t in IMPASSABLE:
			_set_terrain(to.x, to.y, T_ROAD)


# ============================================
# FIXED LANDMARKS
# ============================================

## Place fixed landmarks (start, portal, boss, pass guardian)
func _place_fixed_landmarks(landmarks: Array, zones: Array) -> void:
	for landmark in landmarks:
		var lm_type = landmark.get("type", "")
		var zone_id = landmark.get("zone", "")
		var zone = _find_zone(zones, zone_id)
		if zone.is_empty():
			push_warning("MapGenerator: Zone not found for landmark: " + zone_id)
			continue

		match lm_type:
			"start":
				_place_start(landmark, zone)
			"portal":
				_place_portal(landmark, zone)
			"boss":
				_place_boss(landmark, zone)
			"pass_guardian":
				_place_pass_guardian(landmark)


func _place_start(landmark: Dictionary, zone: Dictionary) -> void:
	var rows = zone.get("rows", [0, 0])
	var row_start = int(rows[0])
	var clear_radius = int(landmark.get("clear_radius", 3))
	var position = landmark.get("position", "top_left")

	# Pick position based on config
	match position:
		"top_left":
			_start_pos = Vector2i(3, row_start + 3)
		"top_right":
			_start_pos = Vector2i(_width - 4, row_start + 3)
		"bottom_left":
			_start_pos = Vector2i(3, int(rows[1]) - 3)
		"bottom_right":
			_start_pos = Vector2i(_width - 4, int(rows[1]) - 3)
		_:
			_start_pos = Vector2i(3, row_start + 3)

	# Clear area around start
	_clear_area(_start_pos, clear_radius)
	_occupied[_start_pos] = true


func _place_portal(landmark: Dictionary, zone: Dictionary) -> void:
	var rows = zone.get("rows", [0, 0])
	var row_end = int(rows[1])
	var clear_radius = int(landmark.get("clear_radius", 2))
	var position = landmark.get("position", "bottom_right")

	match position:
		"bottom_right":
			_portal_pos = Vector2i(_width - 5, row_end - 3)
		"bottom_left":
			_portal_pos = Vector2i(4, row_end - 3)
		"top_right":
			_portal_pos = Vector2i(_width - 5, int(rows[0]) + 3)
		"top_left":
			_portal_pos = Vector2i(4, int(rows[0]) + 3)
		_:
			_portal_pos = Vector2i(_width - 5, row_end - 3)

	# Clear area around portal
	_clear_area(_portal_pos, clear_radius)
	_occupied[_portal_pos] = true

	# Create the portal object
	var data = landmark.get("data", {})
	_objects.append({
		"id": "realm_portal",
		"x": _portal_pos.x,
		"y": _portal_pos.y,
		"type": 2,  # PORTAL
		"name": "Realm Gate",
		"icon": "portal",
		"blocking": false,
		"one_time": false,
		"visible": true,
		"data": data
	})


func _place_boss(landmark: Dictionary, zone: Dictionary) -> void:
	var data = landmark.get("data", {})
	# Place 4-6 tiles from portal, on walkable terrain
	var boss_pos = _find_walkable_near(_portal_pos, 4, 6, zone)
	_occupied[boss_pos] = true

	_objects.append({
		"id": "realm_boss",
		"x": boss_pos.x,
		"y": boss_pos.y,
		"type": 0,  # EVENT
		"name": data.get("name", "Boss"),
		"icon": data.get("icon", "boss"),
		"blocking": true,
		"one_time": true,
		"visible": true,
		"data": {
			"event_id": data.get("event_id", ""),
			"region": zone.get("id", ""),
			"description": "A powerful guardian blocks the path."
		}
	})


func _place_pass_guardian(landmark: Dictionary) -> void:
	if _pass_positions.is_empty():
		return

	var data = landmark.get("data", {})
	# Place at the first pass
	var pass_pos = _pass_positions[0]
	_occupied[pass_pos] = true

	_objects.append({
		"id": "pass_guardian",
		"x": pass_pos.x,
		"y": pass_pos.y,
		"type": 0,  # EVENT
		"name": data.get("name", "Pass Guardian"),
		"icon": data.get("icon", "enemy_elite"),
		"blocking": true,
		"one_time": true,
		"visible": true,
		"data": {
			"event_id": data.get("event_id", ""),
			"region": "mountain_pass",
			"description": "A guardian blocks the mountain pass."
		}
	})


# ============================================
# CONNECTIVITY VALIDATION
# ============================================

## BFS flood fill to ensure start can reach portal through passes
func _validate_connectivity() -> void:
	var max_attempts = 5

	for _attempt in range(max_attempts):
		var reachable = _flood_fill(_start_pos)

		# Check if any pass is reachable
		var pass_reachable = false
		for pp in _pass_positions:
			if pp in reachable:
				pass_reachable = true
				break

		# Check if portal is reachable
		var portal_reachable = _portal_pos in reachable

		if pass_reachable and portal_reachable:
			return

		# Carve a path toward the unreachable target
		if not pass_reachable and not _pass_positions.is_empty():
			_carve_path_toward(reachable, _pass_positions[0])
		elif not portal_reachable:
			_carve_path_toward(reachable, _portal_pos)

	# Last resort: brute force a straight-line path
	push_warning("MapGenerator: Forcing connectivity with straight path")
	if not _pass_positions.is_empty():
		_force_path(_start_pos, _pass_positions[0])
		_force_path(_pass_positions[0], _portal_pos)
	else:
		_force_path(_start_pos, _portal_pos)


## BFS flood fill from a position, returns all reachable tiles
func _flood_fill(start: Vector2i) -> Dictionary:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	while not queue.is_empty():
		var pos = queue.pop_front()
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next = pos + dir
			if next in visited:
				continue
			if next.x < 0 or next.x >= _width or next.y < 0 or next.y >= _height:
				continue
			if _get_terrain(next.x, next.y) in IMPASSABLE:
				continue
			visited[next] = true
			queue.append(next)

	return visited


## Carve a path from the frontier of reachable tiles toward a target
func _carve_path_toward(reachable: Dictionary, target: Vector2i) -> void:
	# Find the reachable tile closest to target
	var best_pos = _start_pos
	var best_dist = 99999.0
	for pos in reachable:
		var d = Vector2(pos).distance_to(Vector2(target))
		if d < best_dist:
			best_dist = d
			best_pos = pos

	# Carve from closest reachable tile to target
	_force_path(best_pos, target)


## Force a straight-ish path between two points (converts impassable to plains)
func _force_path(from: Vector2i, to: Vector2i) -> void:
	var pos = from
	var max_steps = _width + _height
	var steps = 0

	while pos != to and steps < max_steps:
		steps += 1
		if _get_terrain(pos.x, pos.y) in IMPASSABLE:
			_set_terrain(pos.x, pos.y, T_PLAINS)

		# Move toward target
		var dx = signi(to.x - pos.x)
		var dy = signi(to.y - pos.y)
		if absi(to.x - pos.x) > absi(to.y - pos.y):
			pos.x += dx
		else:
			pos.y += dy
		pos.x = clampi(pos.x, 0, _width - 1)
		pos.y = clampi(pos.y, 0, _height - 1)

	# Final tile
	if _get_terrain(to.x, to.y) in IMPASSABLE:
		_set_terrain(to.x, to.y, T_PLAINS)


# ============================================
# OBJECT PLACEMENT
# ============================================

## Place events and pickups from a zone's object pool
func _place_zone_objects(zone: Dictionary, pool: Dictionary, density: Dictionary) -> void:
	var zone_id = zone.get("id", "")
	var rows = zone.get("rows", [0, 0])
	var row_start = int(rows[0])
	var row_end = int(rows[1])
	var min_spacing = int(density.get("min_spacing", 3))

	var event_pool = pool.get("events", [])
	var pickup_pool = pool.get("pickups", [])
	var event_range = density.get("events_per_zone", [6, 10])
	var pickup_range = density.get("pickups_per_zone", [8, 14])
	var shop_range = density.get("guaranteed_shops", [1, 2])
	var rest_range = density.get("guaranteed_rest", [1, 2])

	var num_events = randi_range(int(event_range[0]), int(event_range[1]))
	var num_pickups = randi_range(int(pickup_range[0]), int(pickup_range[1]))
	var guaranteed_shops = randi_range(int(shop_range[0]), int(shop_range[1]))
	var guaranteed_rest = randi_range(int(rest_range[0]), int(rest_range[1]))

	# Collect all placed objects for spacing checks
	var placed_positions: Array[Vector2i] = []

	# Place guaranteed shops first (from events tagged "shop")
	var shop_events: Array = []
	for e in event_pool:
		if e.get("tag", "") == "shop":
			shop_events.append(e)
	for i in range(guaranteed_shops):
		if shop_events.is_empty():
			break
		var template = shop_events[randi() % shop_events.size()]
		var pos = _find_placement_tile(row_start, row_end, min_spacing, placed_positions)
		if pos != Vector2i(-1, -1):
			_place_event_object(zone_id, template, pos)
			placed_positions.append(pos)
			num_events -= 1  # Counts toward event budget

	# Place guaranteed rest stops (from pickups tagged "rest")
	var rest_pickups: Array = []
	for p in pickup_pool:
		if p.get("tag", "") == "rest":
			rest_pickups.append(p)
	for i in range(guaranteed_rest):
		if rest_pickups.is_empty():
			break
		var template = rest_pickups[randi() % rest_pickups.size()]
		var pos = _find_placement_tile(row_start, row_end, min_spacing, placed_positions)
		if pos != Vector2i(-1, -1):
			_place_pickup_object(zone_id, template, pos)
			placed_positions.append(pos)
			num_pickups -= 1  # Counts toward pickup budget

	# Fill remaining events from weighted pool
	var event_weights = _build_pool_weight_table(event_pool)
	for i in range(maxi(num_events, 0)):
		if event_pool.is_empty():
			break
		var template = _pick_from_pool(event_pool, event_weights)
		var pos = _find_placement_tile(row_start, row_end, min_spacing, placed_positions)
		if pos != Vector2i(-1, -1):
			_place_event_object(zone_id, template, pos)
			placed_positions.append(pos)

	# Fill remaining pickups from weighted pool
	var pickup_weights = _build_pool_weight_table(pickup_pool)
	for i in range(maxi(num_pickups, 0)):
		if pickup_pool.is_empty():
			break
		var template = _pick_from_pool(pickup_pool, pickup_weights)
		var pos = _find_placement_tile(row_start, row_end, min_spacing, placed_positions)
		if pos != Vector2i(-1, -1):
			_place_pickup_object(zone_id, template, pos)
			placed_positions.append(pos)


## Create an event object dict from a pool template
func _place_event_object(zone_id: String, template: Dictionary, pos: Vector2i) -> void:
	_obj_counter += 1
	var obj_id = "%s_evt_%d" % [zone_id, _obj_counter]

	_objects.append({
		"id": obj_id,
		"x": pos.x,
		"y": pos.y,
		"type": 0,  # EVENT
		"name": template.get("name", "Event"),
		"icon": template.get("icon", "event"),
		"blocking": template.get("blocking", false),
		"one_time": template.get("one_time", true),
		"visible": true,
		"data": {
			"event_id": template.get("event_id", ""),
			"region": zone_id,
			"description": template.get("description", "Something catches your attention.")
		}
	})
	_occupied[pos] = true


## Create a pickup object dict from a pool template
func _place_pickup_object(zone_id: String, template: Dictionary, pos: Vector2i) -> void:
	_obj_counter += 1
	var obj_id = "%s_pkp_%d" % [zone_id, _obj_counter]

	# Resolve random reward values
	var rewards = _resolve_rewards(template.get("rewards", []))

	_objects.append({
		"id": obj_id,
		"x": pos.x,
		"y": pos.y,
		"type": 1,  # PICKUP
		"name": template.get("name", "Pickup"),
		"icon": template.get("icon", "treasure"),
		"blocking": false,
		"one_time": template.get("one_time", true),
		"visible": true,
		"data": {
			"message": template.get("message", "You found something useful."),
			"rewards": rewards
		}
	})
	_occupied[pos] = true


## Resolve reward values at placement time.
## - Numeric array [min, max]: roll a random int in range.
## - For "buff" rewards: if stat is an array of strings, pick one at random.
## - For "item_random": value array stays as-is (chosen at activation time in map_manager).
func _resolve_rewards(rewards_template: Array) -> Array:
	var resolved: Array = []
	for reward in rewards_template:
		var r = reward.duplicate(true)
		if r.has("value") and r["value"] is Array and r.get("type", "") != "item_random":
			var arr = r["value"]
			if arr.size() >= 2 and (arr[0] is int or arr[0] is float):
				# Numeric range [min, max] — roll at placement time
				r["value"] = randi_range(int(arr[0]), int(arr[1]))
		elif r.get("type", "") == "buff" and r.get("value", null) is Dictionary:
			# Buff with random stat pool: if stat is an array, pick one now
			var bval: Dictionary = r["value"].duplicate(true)
			if bval.get("stat") is Array:
				var pool: Array = bval["stat"]
				bval["stat"] = pool[randi() % pool.size()]
				r["value"] = bval
		resolved.append(r)
	return resolved


# ============================================
# MOB PLACEMENT
# ============================================

## Place mobs from a zone's mob pool
func _place_zone_mobs(zone: Dictionary, pool: Array, density: Dictionary) -> void:
	var zone_id = zone.get("id", "")
	var rows = zone.get("rows", [0, 0])
	var row_start = int(rows[0])
	var row_end = int(rows[1])
	var min_spacing = int(density.get("min_spacing", 3))

	var mob_range = density.get("mobs_per_zone", [8, 14])
	var num_mobs = randi_range(int(mob_range[0]), int(mob_range[1]))
	var mob_weights = _build_pool_weight_table(pool)
	var placed_positions: Array[Vector2i] = []

	var placement_failures = 0
	for i in range(num_mobs):
		var template = _pick_from_pool(pool, mob_weights)
		var pos = _find_placement_tile(row_start, row_end, min_spacing, placed_positions)
		if pos == Vector2i(-1, -1):
			placement_failures += 1
			if placement_failures >= 5:
				break  # Truly no more valid positions
			continue

		_obj_counter += 1
		var mob_id = "%s_mob_%d" % [zone_id, _obj_counter]
		var mode = int(template.get("mode", 0))
		var attitude = int(template.get("attitude", 1))

		var mob_dict: Dictionary = {
			"id": mob_id,
			"name": template.get("name", "Enemy"),
			"icon": template.get("icon", "enemy"),
			"x": pos.x,
			"y": pos.y,
			"mode": mode,
			"attitude": attitude,
			"speed": float(template.get("speed", 0.5)),
			"data": {}
		}

		# Build data based on hostile vs friendly
		if template.has("enemy_group") and template.get("enemy_group") != null:
			mob_dict["data"] = {
				"enemy_group": template.get("enemy_group", ""),
				"region": zone_id,
				"difficulty": template.get("difficulty", "normal"),
				"description": template.get("description", "A creature blocks your path.")
			}
		elif template.has("event_id"):
			mob_dict["data"] = {
				"event_id": template.get("event_id", ""),
				"region": zone_id,
				"description": template.get("description", "Someone approaches.")
			}

		# Aggression for aggressive mobs
		if template.has("aggression"):
			mob_dict["aggression"] = float(template["aggression"])

		# Generate patrol route for patrol mobs
		if mode == 1:  # PATROL
			mob_dict["patrol_route"] = _generate_patrol_route(pos, row_start, row_end)

		# Set roam parameters for roaming mobs
		if mode == 2:  # ROAMING
			mob_dict["roam_radius"] = randi_range(3, 5)
			mob_dict["roam_pause"] = randf_range(2.0, 4.0)

		_mobs.append(mob_dict)
		_occupied[pos] = true
		placed_positions.append(pos)


## Generate a patrol route near a position (2-4 waypoints within 4 tiles)
func _generate_patrol_route(start: Vector2i, row_min: int, row_max: int) -> Array:
	var route: Array = [{"x": start.x, "y": start.y}]
	var num_waypoints = randi_range(2, 4)
	var current = start

	for i in range(num_waypoints - 1):
		# Pick a nearby walkable tile
		var best = current
		for _try in range(20):
			var candidate = current + Vector2i(randi_range(-4, 4), randi_range(-4, 4))
			candidate.x = clampi(candidate.x, 0, _width - 1)
			candidate.y = clampi(candidate.y, row_min, row_max)
			if not _get_terrain(candidate.x, candidate.y) in IMPASSABLE:
				best = candidate
				break

		if best != current:
			route.append({"x": best.x, "y": best.y})
			current = best

	return route


# ============================================
# PLACEMENT HELPERS
# ============================================

## Find a valid tile for placing an object/mob in a zone row range.
## Must be walkable, not occupied, and min_spacing from existing placements.
## Uses reservoir sampling so all valid tiles have equal probability (no terrain bias).
func _find_placement_tile(row_start: int, row_end: int, min_spacing: int,
		placed: Array[Vector2i]) -> Vector2i:
	var best_pos = Vector2i(-1, -1)
	var valid_count = 0  # How many valid candidates seen so far (for reservoir sampling)

	for _try in range(100):
		var x = randi_range(1, _width - 2)
		var y = randi_range(row_start + 1, row_end - 1)
		var pos = Vector2i(x, y)

		# Must be walkable and not occupied
		var terrain = _get_terrain(x, y)
		if terrain in IMPASSABLE:
			continue
		if pos in _occupied:
			continue

		# Check spacing from other placed objects
		var too_close = false
		for other in placed:
			if _manhattan_dist(pos, other) < min_spacing:
				too_close = true
				break
		if too_close:
			continue

		# Also check spacing from fixed landmarks
		if _manhattan_dist(pos, _start_pos) < min_spacing:
			continue
		if _manhattan_dist(pos, _portal_pos) < min_spacing:
			continue

		# Reservoir sampling: replace current selection with probability 1/n
		# This gives uniform distribution across all valid tiles, spreading mobs evenly
		valid_count += 1
		if randi() % valid_count == 0:
			best_pos = pos

	return best_pos


## Find a walkable tile near a position, within a distance range
func _find_walkable_near(center: Vector2i, min_dist: int, max_dist: int,
		zone: Dictionary) -> Vector2i:
	var rows = zone.get("rows", [0, 0])
	var row_start = int(rows[0])
	var row_end = int(rows[1])

	for _try in range(50):
		var dx = randi_range(-max_dist, max_dist)
		var dy = randi_range(-max_dist, max_dist)
		var pos = center + Vector2i(dx, dy)

		if absi(dx) + absi(dy) < min_dist:
			continue
		pos.x = clampi(pos.x, 1, _width - 2)
		pos.y = clampi(pos.y, row_start + 1, row_end - 1)

		if not _get_terrain(pos.x, pos.y) in IMPASSABLE and not pos in _occupied:
			return pos

	# Fallback: just offset from center
	var fallback = center + Vector2i(min_dist, 0)
	fallback.x = clampi(fallback.x, 1, _width - 2)
	fallback.y = clampi(fallback.y, row_start + 1, row_end - 1)
	return fallback


# ============================================
# REGION BUILDING
# ============================================

## Build region entry for the output regions dict
func _build_region(zone: Dictionary) -> void:
	var zone_id = zone.get("id", "")
	var rows = zone.get("rows", [0, 0])

	# Use "mountain_pass" for divider zones
	var region_id = zone_id
	if zone.get("type", "") == "mountain_wall":
		region_id = "mountain_pass"

	_regions[region_id] = {
		"tiles_rect": [0, int(rows[0]), _width - 1, int(rows[1])]
	}


# ============================================
# UTILITY
# ============================================

func _get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= _width or y < 0 or y >= _height:
		return T_MOUNTAINS  # Out of bounds = impassable
	return _terrain[y * _width + x]


func _set_terrain(x: int, y: int, terrain: int) -> void:
	if x >= 0 and x < _width and y >= 0 and y < _height:
		_terrain[y * _width + x] = terrain


## Clear an area to plains around a position
func _clear_area(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var px = center.x + dx
			var py = center.y + dy
			if px >= 0 and px < _width and py >= 0 and py < _height:
				_set_terrain(px, py, T_PLAINS)


## Build a weight table from terrain_weights dict (string keys → int terrain types)
## Returns Array of [terrain_type, cumulative_weight] pairs
func _build_weight_table(weights: Dictionary) -> Array:
	var table: Array = []
	var cumulative = 0
	for key in weights:
		cumulative += int(weights[key])
		table.append([int(key), cumulative])
	return table


## Pick a terrain type from a cumulative weight table
func _pick_weighted(table: Array) -> int:
	if table.is_empty():
		return T_PLAINS
	var total = int(table[table.size() - 1][1])
	var roll = randi_range(1, total)
	for entry in table:
		if roll <= int(entry[1]):
			return int(entry[0])
	return int(table[0][0])


## Build a weight table from pool entries (each has a "weight" field)
func _build_pool_weight_table(pool: Array) -> Array:
	var table: Array = []
	var cumulative = 0
	for i in range(pool.size()):
		cumulative += int(pool[i].get("weight", 1))
		table.append([i, cumulative])
	return table


## Pick an entry from a pool using a weight table (returns the pool entry dict)
func _pick_from_pool(pool: Array, weight_table: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var total = int(weight_table[weight_table.size() - 1][1])
	var roll = randi_range(1, total)
	for entry in weight_table:
		if roll <= int(entry[1]):
			return pool[int(entry[0])]
	return pool[0]


## Manhattan distance between two positions
func _manhattan_dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Find a zone dict by ID from the zones array
func _find_zone(zones: Array, zone_id: String) -> Dictionary:
	for zone in zones:
		if zone.get("id", "") == zone_id:
			return zone
	return {}
