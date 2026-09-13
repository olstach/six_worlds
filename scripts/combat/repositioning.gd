class_name Repositioning
## Moving a unit somewhere it did not choose to go.
##
## This started as forced movement — a push, a pull, and the collision rules
## that come with them — because that is what the perk pass needed. But a push
## is one answer to a more general question, and the spell list is full of the
## others: Blink puts you across the room, Behind You puts an assassin at
## someone's back, Burrow surfaces beside a target, Space Swap trades two
## people's places, a dimensional rift throws everyone somewhere random.
##
## Sixteen spells were inert for want of this, and every one of them had been
## written as a one-off in an unread `special` key: `teleport_self`,
## `blink_out_of_melee`, `teleport_behind_target`, `exchange_positions`. They
## are not sixteen mechanics. They are one mechanic with a mode.
##
## THE DISTINCTION THAT MATTERS is not distance, it is whether the unit travels.
##
##   TRAVELLED (push, pull) — crosses each tile in turn, stops at the first wall
##     or body, and can be hurt by being stopped. Where it lands is a
##     consequence of what was in the way.
##   PLACED (teleport, swap, scatter, behind, adjacent) — leaves one tile and
##     arrives at another with nothing in between. Walls do not block it, and
##     there is nothing to collide with.
##
## Everything else — how far, which direction, what happens when it fails — is
## shared. So this file computes WHERE a unit ends up, and CombatManager owns
## actually moving it, the same split AuraSystem uses.

## How a unit may be moved.
const MODES: Array[String] = [
	"push",      # travelled, away from the source
	"pull",      # travelled, toward the source
	"scatter",   # placed, random walkable tile within range
	"teleport",  # placed, to a named tile
	"swap",      # placed, exchanging with the unit at the aim tile
	"behind",    # placed, to the far side of the target from the source
	"adjacent",  # placed, to any free tile beside the target
]

## Modes that cross the ground between origin and destination, and so can be
## stopped part-way. Everything else arrives regardless of what is in between.
const TRAVELLED: Array[String] = ["push", "pull"]


static func is_mode(mode: String) -> bool:
	return mode in MODES


static func is_travelled(mode: String) -> bool:
	return mode in TRAVELLED


static func explain_unknown(mode: String) -> String:
	return ("'%s' is not in Repositioning.MODES, so nothing moves the unit; the "
		+ "effect would resolve as though it had succeeded") % mode


## How far this spec moves a unit, resolving the spellpower term and the spread.
##
## Kept here rather than at the call site because a push, a pull and a scatter
## all want the same three fields and would otherwise each grow their own.
static func distance_for(spec: Dictionary, source: Node) -> int:
	var tiles: int = int(spec.get("tiles", 1))
	var per_sp: float = float(spec.get("per_spellpower", 0.0))
	if per_sp > 0.0 and source != null and source.has_method("get_spellpower"):
		tiles += int(source.get_spellpower() * per_sp)
	var variance: int = int(spec.get("variance", 0))
	if variance > 0:
		tiles += randi() % (variance + 1)
	return tiles


## The direction a travelled mode moves in.
static func direction_for(spec: Dictionary, source: Node, unit: Node) -> Vector2i:
	match spec.get("direction", ""):
		"random":
			var dirs: Array[Vector2i] = [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
			return dirs[randi() % dirs.size()]
		"toward":
			return AoEResolver._dir4(unit.grid_position, source.grid_position)
		_:
			# Away from the source, which is what a push means. `pull` inverts
			# the distance rather than the direction, so it shares this branch.
			return AoEResolver._dir4(source.grid_position, unit.grid_position)


## Where a PLACED mode puts the unit.
##
## Returns {ok, tile, swap_with, reason}. `swap_with` is set only for a swap,
## where two units move and the second one's destination is the first's origin.
## A refusal carries a reason so the log can say why nothing happened, rather
## than the spell reporting success and the unit standing still.
static func destination(mode: String, unit: Node, source: Node, spec: Dictionary,
		aim: Vector2i, grid: CombatGrid) -> Dictionary:
	var fail := func(why: String) -> Dictionary:
		return {"ok": false, "tile": unit.grid_position, "swap_with": null, "reason": why}

	if grid == null:
		return fail.call("no grid")

	match mode:
		"teleport":
			if not grid.is_valid_position(aim) or not grid.is_tile_walkable(aim):
				return fail.call("that tile cannot be stood on")
			if grid.get_unit_at(aim) != null:
				return fail.call("that tile is occupied")
			var reach: int = int(spec.get("range", 0))
			if reach > 0 and _chebyshev(unit.grid_position, aim) > reach:
				return fail.call("out of range")
			return {"ok": true, "tile": aim, "swap_with": null, "reason": ""}

		"swap":
			var other: Node = grid.get_unit_at(aim)
			if other == null or other == unit:
				return fail.call("nobody there to trade places with")
			return {"ok": true, "tile": other.grid_position, "swap_with": other,
				"reason": ""}

		"behind":
			# The tile directly opposite the source, across the target. An
			# assassin steps through to the exposed side.
			var target: Node = grid.get_unit_at(aim)
			if target == null:
				return fail.call("nobody to step behind")
			var step: Vector2i = AoEResolver._dir4(
				source.grid_position, target.grid_position)
			var tile: Vector2i = target.grid_position + step
			if not grid.is_valid_position(tile) or not grid.is_tile_walkable(tile) \
					or grid.get_unit_at(tile) != null:
				return fail.call("there is no room behind them")
			return {"ok": true, "tile": tile, "swap_with": null, "reason": ""}

		"adjacent":
			var neighbour: Node = grid.get_unit_at(aim)
			if neighbour == null:
				return fail.call("nobody to surface beside")
			var free: Array[Vector2i] = _free_ring(neighbour.grid_position, 1, grid, unit)
			if free.is_empty():
				return fail.call("they are hemmed in on every side")
			return {"ok": true, "tile": free[randi() % free.size()], "swap_with": null,
				"reason": ""}

		"scatter":
			var reach: int = maxi(1, int(spec.get("range", 2)))
			var options: Array[Vector2i] = _free_ring(
				unit.grid_position, reach, grid, unit)
			if options.is_empty():
				return fail.call("nowhere to land")
			return {"ok": true, "tile": options[randi() % options.size()],
				"swap_with": null, "reason": ""}

	return fail.call("'%s' is not a placed mode" % mode)


## Every free, walkable tile within `radius` of `centre`, excluding the centre
## itself and any tile the moving unit already stands on.
static func _free_ring(centre: Vector2i, radius: int, grid: CombatGrid,
		mover: Node) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile := centre + Vector2i(dx, dy)
			if tile == centre or (mover != null and tile == mover.grid_position):
				continue
			if not grid.is_valid_position(tile) or not grid.is_tile_walkable(tile):
				continue
			if grid.get_unit_at(tile) != null:
				continue
			out.append(tile)
	return out


static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
