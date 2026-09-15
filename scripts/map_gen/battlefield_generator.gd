class_name BattlefieldGenerator
## Turning a patch of the world map into a battlefield you can recognise.
##
## The old generator counted the terrain around the party, turned the counts
## into obstacle budgets, and scattered those obstacles at random across the
## grid. The battlefield therefore kept the PROPORTIONS of nearby terrain and
## threw away its ARRANGEMENT: stand at a lakeshore with forest behind you and
## you got some water somewhere and some trees somewhere, rather than water on
## one side and trees at your back.
##
## THREE PASSES, and the order is the point.
##
##   1. BLOCKS.   Each sampled world tile becomes a rectangle of battle tiles
##                of the same ground. The arrangement survives the zoom, which
##                is the whole of what was missing.
##   2. GREEBLE.  Along the seams between blocks, tiles take their neighbour's
##                ground on a falling chance. Without this the lake is a
##                rectangle and the field reads as graph paper.
##   3. FURNITURE. Obstacles and hazards, seeded per block from what that
##                ground actually grows, rather than from a global budget.
##
## Pure: it takes a sample and a size and returns map data. No grid, no scene,
## no randomness it did not seed itself — so a test can ask what it built.

## How far the greeble reaches in from a seam, and how the chance falls off.
## One tile of certainty would be a jagged line; three is a coastline.
const GREEBLE_DEPTH: int = 3
const GREEBLE_CHANCE: Array[float] = [0.55, 0.30, 0.12]


## Build a battlefield from a square sample of world tiles.
##
## `sample` is a row-major Array of Arrays of Ground ids — sample[y][x] — with
## the party's own tile at the centre. `size` is the battle grid.
##
## Returns the dictionary CombatGrid.setup_from_map() takes.
static func generate(sample: Array, size: Vector2i, rng_seed: int = 0) -> Dictionary:
	if sample.is_empty() or (sample[0] as Array).is_empty():
		return {"size": size}
	if rng_seed != 0:
		seed(rng_seed)

	var rows: int = sample.size()
	var cols: int = (sample[0] as Array).size()

	# ── Pass 1: blocks ──────────────────────────────────────────────────────
	#
	# Block edges are computed by proportional integer division rather than a
	# fixed block size, so 48 across 5 columns comes out 9,10,10,9,10 with
	# nothing left over and no seam at the far edge.
	var ground: Dictionary = {}   # Vector2i -> Ground id
	for by in range(rows):
		var y0: int = by * size.y / rows
		var y1: int = (by + 1) * size.y / rows
		for bx in range(cols):
			var x0: int = bx * size.x / cols
			var x1: int = (bx + 1) * size.x / cols
			var g: int = int((sample[by] as Array)[bx])
			for y in range(y0, y1):
				for x in range(x0, x1):
					ground[Vector2i(x, y)] = g

	# ── Pass 2: greeble the seams ───────────────────────────────────────────
	#
	# A tile near a seam may take the ground of the block ACROSS that seam, on
	# a chance that falls with distance. Borrowing from the neighbouring block
	# rather than from an adjacent tile is what gives the edge real depth: an
	# earlier version read a snapshot of the tiles and required a differing
	# NEIGHBOUR, which meant only the single row beside a seam could ever
	# change — three chance values with two of them unreachable, and a
	# coastline one tile wide.
	for by in range(rows):
		var y0: int = by * size.y / rows
		var y1: int = (by + 1) * size.y / rows
		for bx in range(cols):
			var x0: int = bx * size.x / cols
			var x1: int = (bx + 1) * size.x / cols
			var mine: int = int((sample[by] as Array)[bx])
			for y in range(y0, y1):
				for x in range(x0, x1):
					# Every seam this tile is close to, with the ground waiting
					# on the far side of it.
					var near: Array = []
					var seams := [
						[x - x0,      bx - 1, by],
						[x1 - 1 - x,  bx + 1, by],
						[y - y0,      bx,     by - 1],
						[y1 - 1 - y,  bx,     by + 1],
					]
					for seam in seams:
						var depth: int = int(seam[0])
						if depth < 0 or depth >= GREEBLE_DEPTH:
							continue
						var nx: int = int(seam[1])
						var ny: int = int(seam[2])
						if nx < 0 or nx >= cols or ny < 0 or ny >= rows:
							continue   # the edge of the sample is not a seam
						var theirs: int = int((sample[ny] as Array)[nx])
						if theirs != mine:
							near.append({"depth": depth, "ground": theirs})
					if near.is_empty():
						continue
					# A corner sits near two seams; let either claim the tile,
					# which is what makes corners read as a mixed shoreline.
					var pick: Dictionary = near[randi() % near.size()]
					if randf() < GREEBLE_CHANCE[int(pick.depth)]:
						ground[Vector2i(x, y)] = int(pick.ground)

	# ── Pass 3: furniture ───────────────────────────────────────────────────
	var tiles: Dictionary = {}          # "x,y" -> TileType int
	var grounds: Dictionary = {}        # "x,y" -> Ground id
	var effects: Array[Dictionary] = []
	var heights: Array[Dictionary] = []
	var obstacles: Array[Dictionary] = []

	# Deployment columns must stay walkable, or a fight can begin with nobody
	# able to stand anywhere.
	var deploy_lo: int = size.x / 3
	var deploy_hi: int = size.x * 2 / 3
	var in_deploy := func(x: int) -> bool:
		return (x >= deploy_lo and x < deploy_lo + 4) \
			or (x >= deploy_hi - 4 and x < deploy_hi)

	# Obstacle density is per block, so a field of forest is not thinner per
	# tile than a single stand of trees.
	var block_area: float = maxf(1.0, float(size.x * size.y) / float(rows * cols))
	var placed: Dictionary = {}

	for y in range(size.y):
		for x in range(size.x):
			var here := Vector2i(x, y)
			var g: int = int(ground[here])
			grounds["%d,%d" % [x, y]] = g
			var battle: Dictionary = Ground.battle_of(g)
			if battle.is_empty():
				continue

			var tile_name: String = str(battle.get("tile", "floor"))
			var tile_type: int = _tile_type_from(tile_name)
			# Never wall off or drop a hole under a deployment column.
			if in_deploy.call(x) and tile_type in [
					CombatGrid.TileType.WALL, CombatGrid.TileType.PIT]:
				tile_type = CombatGrid.TileType.DIFFICULT
			if tile_type != CombatGrid.TileType.FLOOR:
				tiles["%d,%d" % [x, y]] = tile_type

			var height: int = int(battle.get("height", 0))
			if height != 0:
				heights.append({"pos": here, "height": height})

			var hazard: Dictionary = battle.get("hazard", {})
			if not hazard.is_empty() and randf() < float(hazard.get("chance", 0.0)):
				effects.append({
					"pos": here,
					"effect": _hazard_from(str(hazard.get("effect", "none"))),
					"value": int(hazard.get("value", 0)),
				})

	# Obstacles, walked block by block so each gets its own ground's furniture.
	for by in range(rows):
		var y0: int = by * size.y / rows
		var y1: int = (by + 1) * size.y / rows
		for bx in range(cols):
			var x0: int = bx * size.x / cols
			var x1: int = (bx + 1) * size.x / cols
			var battle: Dictionary = Ground.battle_of(int((sample[by] as Array)[bx]))
			for obstacle_name in battle.get("obstacles", {}):
				var density: float = float(battle["obstacles"][obstacle_name])
				var want: int = int(density * block_area / 36.0)
				# A fractional density still places sometimes, or a terrain
				# asking for half a rock per block would never get one.
				if want == 0 and density > 0.0 and randf() < density:
					want = 1
				for _i in range(want):
					var spot := _free_spot(x0, x1, y0, y1, placed, tiles, in_deploy)
					if spot.x < 0:
						continue
					placed[spot] = true
					obstacles.append({
						"pos": spot,
						"obstacle": _obstacle_from(str(obstacle_name)),
					})

	return {
		"size": size,
		"tiles": tiles,
		"grounds": grounds,
		"effects": effects,
		"heights": heights,
		"obstacles": obstacles,
	}


## A walkable, unoccupied tile inside one block, or (-1,-1) after enough tries.
static func _free_spot(x0: int, x1: int, y0: int, y1: int, placed: Dictionary,
		tiles: Dictionary, in_deploy: Callable) -> Vector2i:
	for _try in range(24):
		var x: int = randi_range(x0, maxi(x0, x1 - 1))
		var y: int = randi_range(y0, maxi(y0, y1 - 1))
		if in_deploy.call(x):
			continue
		var at := Vector2i(x, y)
		if placed.has(at):
			continue
		# Nothing stands in a wall, a pit or open water.
		var existing = tiles.get("%d,%d" % [x, y], CombatGrid.TileType.FLOOR)
		if existing in [CombatGrid.TileType.WALL, CombatGrid.TileType.PIT,
				CombatGrid.TileType.WATER]:
			continue
		return at
	return Vector2i(-1, -1)


static func _tile_type_from(name: String) -> int:
	match name:
		"wall":      return CombatGrid.TileType.WALL
		"pit":       return CombatGrid.TileType.PIT
		"water":     return CombatGrid.TileType.WATER
		"difficult": return CombatGrid.TileType.DIFFICULT
	return CombatGrid.TileType.FLOOR


static func _hazard_from(name: String) -> int:
	match name:
		"fire":    return CombatGrid.TerrainEffect.FIRE
		"ice":     return CombatGrid.TerrainEffect.ICE
		"poison":  return CombatGrid.TerrainEffect.POISON
		"acid":    return CombatGrid.TerrainEffect.ACID
		"blessed": return CombatGrid.TerrainEffect.BLESSED
		"cursed":  return CombatGrid.TerrainEffect.CURSED
		"wet":     return CombatGrid.TerrainEffect.WET
		"stormy":  return CombatGrid.TerrainEffect.STORMY
		"void":    return CombatGrid.TerrainEffect.VOID
		"smoke":   return CombatGrid.TerrainEffect.SMOKE
	return CombatGrid.TerrainEffect.NONE


static func _obstacle_from(name: String) -> int:
	match name:
		"tree":        return CombatGrid.ObstacleType.TREE
		"rock":        return CombatGrid.ObstacleType.ROCK
		"pillar":      return CombatGrid.ObstacleType.PILLAR
		"barricade":   return CombatGrid.ObstacleType.BARRICADE
		"fallen_tree": return CombatGrid.ObstacleType.FALLEN_TREE
	return CombatGrid.ObstacleType.NONE
