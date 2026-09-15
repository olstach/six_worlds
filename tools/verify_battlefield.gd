extends Node
## Headless verification for the terrain vocabulary and the battlefield generator.
##
## Run: godot --headless res://tools/verify_battlefield.tscn
##
## The claim under test is contiguity: a battlefield should read as a zoom into
## the ground the party is standing on. That is checkable — the left of the
## field should be made of whatever was on the left of the sample — and it was
## false before, because the old generator kept the proportions of nearby
## terrain and discarded its arrangement.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 18

const SIZE := Vector2i(48, 30)


func _ready() -> void:
	seed(20260915)

	_check_the_vocabulary_is_shared()
	_check_every_terrain_has_battle_traits()
	_check_the_overworld_reads_the_shared_data()

	_check_every_tile_gets_a_ground()
	_check_arrangement_survives_the_zoom()
	_check_blocks_tile_the_grid_exactly()
	_check_seams_are_ragged()
	_check_block_middles_are_not_greebled()
	_check_the_coastline_has_depth()
	_check_blocks_stretch_to_any_grid_size()

	_check_ground_decides_the_tile_type()
	_check_obstacles_come_from_the_ground_under_them()
	_check_deployment_columns_stay_usable()
	_check_the_grid_accepts_what_the_generator_builds()

	_check_mountains_rise_higher_than_hills()
	_check_even_grassland_is_not_perfectly_flat()
	_check_low_ground_stays_low()
	_check_slopes_are_walkable_and_worth_holding()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway"
			% [checks_run, EXPECTED_CHECKS])
		failures += 1
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _done() -> void:
	checks_run += 1


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


## A 5×5 sample: water down the left two columns, plains in the middle, forest
## down the right two. The lakeshore from the audit.
func _lakeshore() -> Array:
	var W := int(MapManager.Terrain.WATER)
	var P := int(MapManager.Terrain.PLAINS)
	var F := int(MapManager.Terrain.FOREST)
	var rows: Array = []
	for _y in 5:
		rows.append([W, W, P, F, F])
	return rows


func _uniform(ground: int) -> Array:
	var rows: Array = []
	for _y in 5:
		rows.append([ground, ground, ground, ground, ground])
	return rows


# ── The vocabulary ───────────────────────────────────────────────────────────

## Fourteen terrains, and the ids are the contract with every saved map.
func _check_the_vocabulary_is_shared() -> void:
	var all: Dictionary = Ground.all()
	if all.size() != 14:
		_fail("Ground knows %d terrains, expected 14" % all.size())

	# Every MapManager.Terrain value must resolve, or a saved map would load
	# ground the shared vocabulary cannot describe.
	for name in MapManager.Terrain:
		var id: int = MapManager.Terrain[name]
		if Ground.by_id(id).is_empty():
			_fail("MapManager.Terrain.%s (%d) has no entry in Ground" % [name, id])
	_done()


func _check_every_terrain_has_battle_traits() -> void:
	for name in MapManager.Terrain:
		var id: int = MapManager.Terrain[name]
		if Ground.battle_of(id).is_empty():
			_fail("terrain %s has no battle traits — a block of it would "
				% name + "generate featureless ground, which is what made a "
				+ "desert fight look like a grassland one")
	_done()


## The overworld must be reading the same rows, not a copy of them.
func _check_the_overworld_reads_the_shared_data() -> void:
	MapManager.tiles.clear()
	MapManager.map_size = Vector2i(10, 10)
	MapManager.clear_movement_abilities()

	var road := Vector2i(2, 2)
	var swamp := Vector2i(3, 2)
	MapManager.tiles[road] = MapManager.Terrain.ROAD
	MapManager.tiles[swamp] = MapManager.Terrain.SWAMP

	if not is_equal_approx(MapManager.get_terrain_speed(road),
			Ground.speed_of(int(MapManager.Terrain.ROAD))):
		_fail("the map reports %.2f for a road; the vocabulary says %.2f"
			% [MapManager.get_terrain_speed(road),
				Ground.speed_of(int(MapManager.Terrain.ROAD))])
	if MapManager.get_terrain_name(swamp) != Ground.name_of(int(MapManager.Terrain.SWAMP)):
		_fail("the map and the vocabulary disagree on what a swamp is called")
	# And the ability that opens water comes from the same row.
	if Ground.ability_for(int(MapManager.Terrain.WATER)) != "water_walking":
		_fail("water is opened by '%s' in the shared data"
			% Ground.ability_for(int(MapManager.Terrain.WATER)))
	_done()


# ── The zoom ─────────────────────────────────────────────────────────────────

func _check_every_tile_gets_a_ground() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 101)
	var grounds: Dictionary = built.get("grounds", {})
	if grounds.size() != SIZE.x * SIZE.y:
		_fail("%d of %d tiles were given a ground" % [grounds.size(), SIZE.x * SIZE.y])
	_done()


## THE CLAIM. The left of the field is water because the left of the sample was
## water. This is what the old generator could not do at all.
func _check_arrangement_survives_the_zoom() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 202)
	var grounds: Dictionary = built["grounds"]
	var W := int(MapManager.Terrain.WATER)
	var F := int(MapManager.Terrain.FOREST)

	# Sample the middle of the outermost blocks, away from any seam.
	var left_water := 0
	var left_total := 0
	var right_forest := 0
	var right_total := 0
	for y in range(6, 24):
		for x in range(0, 6):
			left_total += 1
			if int(grounds["%d,%d" % [x, y]]) == W:
				left_water += 1
		for x in range(42, 48):
			right_total += 1
			if int(grounds["%d,%d" % [x, y]]) == F:
				right_forest += 1

	if left_water < left_total * 0.9:
		_fail("only %d of %d tiles on the far left are water — the lake did "
			% [left_water, left_total] + "not stay on the left")
	if right_forest < right_total * 0.9:
		_fail("only %d of %d tiles on the far right are forest — the trees did "
			% [right_forest, right_total] + "not stay at your back")
	# And the two must not have swapped or mixed.
	if left_water > 0 and right_forest > 0 and left_water + right_forest < left_total:
		_fail("the field is a blend rather than an arrangement")
	_done()


## Blocks are sized by proportional division, so 48 across 5 columns leaves
## nothing over and no seam at the far edge.
func _check_blocks_tile_the_grid_exactly() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_uniform(
		int(MapManager.Terrain.PLAINS)), Vector2i(48, 30), 303)
	var grounds: Dictionary = built["grounds"]
	for y in [0, 29]:
		for x in [0, 47]:
			if not grounds.has("%d,%d" % [x, y]):
				_fail("corner (%d,%d) got no ground — the blocks do not reach "
					% [x, y] + "the edge of the grid")
	# An odd grid size must also divide without a gap.
	var odd: Dictionary = BattlefieldGenerator.generate(_uniform(0), Vector2i(47, 29), 304)
	if odd["grounds"].size() != 47 * 29:
		_fail("a 47×29 grid got %d of %d grounds — the remainder is being lost"
			% [odd["grounds"].size(), 47 * 29])
	_done()


## Without the greeble pass the lake is a rectangle and the field reads as
## graph paper.
func _check_seams_are_ragged() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 404)
	var grounds: Dictionary = built["grounds"]

	# The seam between the water blocks and the plains block sits near x=19.
	# A straight edge means every column left of it is pure water; a coastline
	# means the boundary wanders.
	var boundary_columns: Dictionary = {}
	var W := int(MapManager.Terrain.WATER)
	for y in range(SIZE.y):
		var last_water: int = -1
		for x in range(SIZE.x):
			if int(grounds["%d,%d" % [x, y]]) == W:
				last_water = x
		boundary_columns[last_water] = true
	if boundary_columns.size() < 2:
		_fail("the water's edge is at the same column on all %d rows — the "
			% SIZE.y + "seam was not greebled and the lake is a rectangle")
	_done()


## But only the seams. The middle of a block must stay what it is, or the
## greeble is just noise over the whole field.
func _check_block_middles_are_not_greebled() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 505)
	var grounds: Dictionary = built["grounds"]
	var W := int(MapManager.Terrain.WATER)
	# Column 0-4 is the middle of the first water block, nowhere near a seam.
	for y in range(SIZE.y):
		for x in range(0, 5):
			if int(grounds["%d,%d" % [x, y]]) != W:
				_fail("tile (%d,%d) in the middle of a water block is ground %s"
					% [x, y, str(grounds["%d,%d" % [x, y]])])
				_done()
				return
	_done()


# ── Furniture ────────────────────────────────────────────────────────────────

## Water becomes water tiles, lava becomes pits, forest becomes difficult
## ground — because the ground says so in data.
func _check_ground_decides_the_tile_type() -> void:
	var lava: Dictionary = BattlefieldGenerator.generate(
		_uniform(int(MapManager.Terrain.LAVA)), SIZE, 606)
	var pits := 0
	for key in lava.get("tiles", {}):
		if int(lava["tiles"][key]) == CombatGrid.TileType.PIT:
			pits += 1
	if pits == 0:
		_fail("a field of lava produced no pits")

	var water: Dictionary = BattlefieldGenerator.generate(
		_uniform(int(MapManager.Terrain.WATER)), SIZE, 607)
	var wet := 0
	for key in water.get("tiles", {}):
		if int(water["tiles"][key]) == CombatGrid.TileType.WATER:
			wet += 1
	if wet == 0:
		_fail("a field of water produced no water tiles")

	var road: Dictionary = BattlefieldGenerator.generate(
		_uniform(int(MapManager.Terrain.ROAD)), SIZE, 608)
	if not road.get("tiles", {}).is_empty():
		_fail("a paved road produced %d non-floor tiles"
			% road["tiles"].size())
	_done()


## An obstacle stands on the ground that grows it. Trees in the forest half,
## not scattered across the lake.
func _check_obstacles_come_from_the_ground_under_them() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 707)
	var grounds: Dictionary = built["grounds"]
	var F := int(MapManager.Terrain.FOREST)

	var trees := 0
	var trees_on_forest := 0
	for obs in built.get("obstacles", []):
		if int(obs["obstacle"]) != CombatGrid.ObstacleType.TREE:
			continue
		trees += 1
		var at: Vector2i = obs["pos"]
		if int(grounds["%d,%d" % [at.x, at.y]]) == F:
			trees_on_forest += 1

	if trees == 0:
		_fail("a forest half produced no trees at all")
	elif trees_on_forest < trees * 0.8:
		_fail("%d of %d trees stand on something other than forest — obstacles "
			% [trees_on_forest, trees] + "are not being seeded from the ground "
			+ "beneath them")
	_done()


## A fight that begins with nobody able to stand anywhere is not a fight.
func _check_deployment_columns_stay_usable() -> void:
	# Mountains default their tiles to walls; a field of them would otherwise
	# brick up both deployment zones.
	var built: Dictionary = BattlefieldGenerator.generate(
		_uniform(int(MapManager.Terrain.MOUNTAINS)), SIZE, 808)
	var tiles: Dictionary = built.get("tiles", {})
	var blocked := 0
	for x in [16, 17, 18, 19, 28, 29, 30, 31]:
		for y in range(SIZE.y):
			var t = tiles.get("%d,%d" % [x, y], CombatGrid.TileType.FLOOR)
			if t in [CombatGrid.TileType.WALL, CombatGrid.TileType.PIT]:
				blocked += 1
	if blocked > 0:
		_fail("%d deployment tiles are walled or pitted on a mountain field"
			% blocked)

	for obs in built.get("obstacles", []):
		var at: Vector2i = obs["pos"]
		if (at.x >= 16 and at.x <= 19) or (at.x >= 28 and at.x <= 31):
			_fail("an obstacle was placed in a deployment column at %s" % str(at))
			break
	_done()


## And the grid actually accepts it — the generator's output is only useful if
## setup_from_map() reads every key it writes.
func _check_the_grid_accepts_what_the_generator_builds() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, 909)
	var grid := CombatGrid.new()
	add_child(grid)
	grid.setup_from_map(built)

	if grid.grid_size != SIZE:
		_fail("the grid came up %s, expected %s" % [str(grid.grid_size), str(SIZE)])
	# Ground must survive the handover, including on tiles the overrides rebuilt.
	var W := int(MapManager.Terrain.WATER)
	if grid.get_ground(Vector2i(2, 15)) != W:
		_fail("the grid reports ground %d on the lake side; the generator said %d"
			% [grid.get_ground(Vector2i(2, 15)), W])
	var F := int(MapManager.Terrain.FOREST)
	if grid.get_ground(Vector2i(45, 15)) != F:
		_fail("the grid reports ground %d on the forest side; expected %d"
			% [grid.get_ground(Vector2i(45, 15)), F])
	grid.queue_free()
	_done()


## The edge should wander a few tiles in, not one. An earlier greeble read a
## snapshot of the tiles and required a differing NEIGHBOUR, so only the single
## row beside a seam could ever change — two of its three chance values were
## unreachable and the shoreline was one tile wide.
func _check_the_coastline_has_depth() -> void:
	var W := int(MapManager.Terrain.WATER)
	var reached: Dictionary = {}
	# Several seeds, because any one field may happen to be tidy.
	for s in [11, 22, 33, 44, 55]:
		var grounds: Dictionary = BattlefieldGenerator.generate(_lakeshore(), SIZE, s)["grounds"]
		for y in range(SIZE.y):
			for x in range(19, 19 + BattlefieldGenerator.GREEBLE_DEPTH):
				if int(grounds["%d,%d" % [x, y]]) == W:
					reached[x - 19] = true
	if not reached.has(0):
		_fail("water never crossed the seam at all")
	if reached.size() < 2:
		_fail("water only ever reached %s tiles past the seam — the shoreline "
			% str(reached.keys()) + "has no depth, so the deeper chance values "
			+ "are unreachable")
	_done()


## Blocks are sized by proportional division, so any grid divides without a
## gap — a fixed block size leaves the bottom of a taller grid unassigned.
func _check_blocks_stretch_to_any_grid_size() -> void:
	var W := int(MapManager.Terrain.WATER)
	var F := int(MapManager.Terrain.FOREST)
	for size in [Vector2i(48, 40), Vector2i(60, 24), Vector2i(33, 17)]:
		var built: Dictionary = BattlefieldGenerator.generate(_lakeshore(), size, 606)
		var grounds: Dictionary = built["grounds"]
		if grounds.size() != size.x * size.y:
			_fail("a %s grid got %d of %d grounds"
				% [str(size), grounds.size(), size.x * size.y])
			continue
		# The far corners must belong to the far corners of the sample, or the
		# blocks are not reaching the edges.
		if int(grounds["0,%d" % (size.y - 1)]) != W:
			_fail("the bottom-left of a %s grid is ground %s, not the water the "
				% [str(size), str(grounds["0,%d" % (size.y - 1)])]
				+ "sample has there")
		if int(grounds["%d,%d" % [size.x - 1, size.y - 1]]) != F:
			_fail("the bottom-right of a %s grid is not the forest the sample "
				% str(size) + "has there")
	_done()


# ── Relief ───────────────────────────────────────────────────────────────────

## Tallest height anywhere on a field of one ground, averaged over seeds so a
## single quiet field cannot carry the result.
func _peak_of(ground: int, seeds: Array) -> float:
	var total := 0
	for s in seeds:
		var built: Dictionary = BattlefieldGenerator.generate(_uniform(ground), SIZE, s)
		var highest := 0
		for h in built.get("heights", []):
			highest = maxi(highest, int(h["height"]))
		total += highest
	return float(total) / float(seeds.size())


## Hills should have height differences; mountains more so. That was the ask,
## and before this both produced rocks and walls and no elevation at all.
func _check_mountains_rise_higher_than_hills() -> void:
	var seeds := [1, 2, 3, 4, 5, 6]
	var hills: float = _peak_of(int(MapManager.Terrain.HILLS), seeds)
	var mountains: float = _peak_of(int(MapManager.Terrain.MOUNTAINS), seeds)
	var plains: float = _peak_of(int(MapManager.Terrain.PLAINS), seeds)

	if hills <= plains:
		_fail("hills peak at %.1f and plains at %.1f — hills are not hilly"
			% [hills, plains])
	if mountains <= hills:
		_fail("mountains peak at %.1f and hills at %.1f — mountains should "
			% [mountains, hills] + "rise higher")
	_done()


## "Not much land is completely flat, and it adds to the variety."
func _check_even_grassland_is_not_perfectly_flat() -> void:
	var raised := 0
	for s in [7, 8, 9, 10, 11, 12]:
		var built: Dictionary = BattlefieldGenerator.generate(
			_uniform(int(MapManager.Terrain.PLAINS)), SIZE, s)
		raised += built.get("heights", []).size()
	if raised == 0:
		_fail("six fields of grassland were perfectly flat across all of them")

	# But gently: a road is graded, and should stay level.
	var road_raised := 0
	for s in [7, 8, 9, 10, 11, 12]:
		road_raised += BattlefieldGenerator.generate(
			_uniform(int(MapManager.Terrain.ROAD)), SIZE, s).get("heights", []).size()
	if road_raised > 0:
		_fail("a paved road rose %d tiles; it is graded and should be level"
			% road_raised)
	_done()


## A slope runs down into a lake and stops there. Water, swamp and lava sit in
## the low ground whatever is raised beside them.
func _check_low_ground_stays_low() -> void:
	# A field that is half hills and half water: mounds seeded in the hills
	# must not climb out onto the lake.
	var H := int(MapManager.Terrain.HILLS)
	var W := int(MapManager.Terrain.WATER)
	var sample: Array = []
	for _y in 5:
		sample.append([H, H, H, W, W])

	for s in [21, 22, 23, 24]:
		var built: Dictionary = BattlefieldGenerator.generate(sample, SIZE, s)
		var grounds: Dictionary = built["grounds"]
		for h in built.get("heights", []):
			var at: Vector2i = h["pos"]
			var g: int = int(grounds["%d,%d" % [at.x, at.y]])
			if Ground.relief_of(g) < int(h["height"]):
				_fail("tile %s is ground %s (relief %d) and stands at height %d"
					% [str(at), Ground.name_of(g), Ground.relief_of(g), int(h["height"])])
				_done()
				return
	_done()


## Relief must be a slope rather than a pillar: climbable, and worth climbing.
## Height costs one extra movement a level and pays 5 accuracy and 2 melee
## damage, so a cliff nobody can reach is a dead mechanic.
func _check_slopes_are_walkable_and_worth_holding() -> void:
	var built: Dictionary = BattlefieldGenerator.generate(
		_uniform(int(MapManager.Terrain.MOUNTAINS)), SIZE, 31)
	var height_at: Dictionary = {}
	for h in built.get("heights", []):
		height_at[h["pos"]] = int(h["height"])
	if height_at.is_empty():
		_fail("a mountain field produced no height at all")
		_done()
		return

	# No INTERIOR tile may sit more than one level above its gentlest
	# neighbour, or the ground is a set of towers rather than hills. The border
	# is excluded on purpose: a mound cut off by the edge of the map is a cliff
	# at the edge of the world, and nobody can walk off it anyway.
	for at in height_at:
		var mine: int = int(height_at[at])
		if mine <= 1:
			continue
		if at.x <= 0 or at.y <= 0 or at.x >= SIZE.x - 1 or at.y >= SIZE.y - 1:
			continue
		var lowest := 99
		for step in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			lowest = mini(lowest, int(height_at.get(at + step, 0)))
		if mine - lowest > 1:
			_fail("tile %s stands %d above its lowest neighbour — that is a "
				% [str(at), mine - lowest] + "pillar, not a slope")
			_done()
			return
	_done()
