## AoEResolver — single source of truth for all AoE tile computations.
##
## Usage (from any script, no autoload needed):
##   var tiles = AoEResolver.get_tiles(spell.aoe, caster.grid_position, target_pos, grid.grid_size)
##   var desc  = AoEResolver.describe(spell.aoe)
##
## ─── Canonical AoE definition (in spell JSON "aoe" block) ───────────────────
##
##   "aoe": {
##     "type":        String  — shape identifier (see supported types below)
##     "size":        int     — primary dimension:
##                               circle/nova/around_caster → radius
##                               line/cone/cone_forward    → length
##                               cross                     → arm length
##                               band/vertical_line        → width
##     "width":       int     — secondary perpendicular dimension (line, band, cone)
##                              defaults to 1 for line, size for cone
##     "origin":      String  — "target" (default) | "caster" | "ground"
##                              where the shape anchors; "ground" = same as "target"
##     "safe_center": bool    — exclude the origin tile (default false)
##                              nova uses this to create a hollow ring
##     "upgradeable":  bool   — can size increase with skill level (data hint)
##     "upgrade_scaling": String — "radius"|"length"|"width"|"tiles" (data hint)
##   }
##
##   Legacy field "base_size" is accepted as an alias for "size".
##   Legacy field "radius" is accepted as an alias for "size".
##
## ─── Supported shape types ──────────────────────────────────────────────────
##
##   circle       — Diamond (Manhattan) circle; the most common AoE type.
##   nova         — Ring: only tiles at exactly radius distance (hollow donut).
##   around_caster— Circle centered on the caster regardless of target tile.
##   line         — Straight line from origin in caster→target direction.
##                  width=1: one tile wide; width=3: one tile each side.
##   cone         — Expands from 1 tile at the tip to `width` at the far end.
##   cone_forward — Same as cone; direction is locked to caster facing (same impl).
##   cross        — Plus-sign (+): center + arm_length tiles in each cardinal direction.
##   band         — Strip spanning the full battlefield row or column.
##                  Direction determines orientation; size = strip thickness.
##   vertical_line— Full column at the origin's x coordinate (entire height).
##   field_of_view— All tiles visible to caster. Currently returns whole grid;
##                  replace _field_of_view() body with raycasting when obstacle
##                  data is available.
##
## ─── Adding a new AoE type ──────────────────────────────────────────────────
##
##   1. Write a private static func _my_shape(...) -> Array[Vector2i]
##   2. Add its "type" string to the match block in get_tiles()
##   3. Add its description string to describe()
##   That's it — all callers (combat_manager, combat_grid, combat_arena) pick it up.

class_name AoEResolver


## Returns all grid tiles covered by this AoE definition.
##
## aoe        — the spell's "aoe" Dictionary
## caster_pos — caster's current grid position
## target_pos — the tile the player/AI aimed at
## grid_size  — combat grid dimensions (from CombatGrid.grid_size)
static func get_tiles(aoe: Dictionary, caster_pos: Vector2i, target_pos: Vector2i,
		grid_size: Vector2i) -> Array[Vector2i]:
	var shape: String = aoe.get("type", "circle")
	var size: int     = _resolve_size(aoe, grid_size)
	var origin: Vector2i = _resolve_origin(aoe, caster_pos, target_pos)

	match shape:
		"circle":
			return _circle(origin, size, grid_size)

		"nova":
			return _nova(origin, size, aoe.get("safe_center", true), grid_size)

		"around_caster":
			# Always centered on the caster; target_pos is ignored
			return _circle(caster_pos, size, grid_size)

		"line":
			var width: int = aoe.get("width", 1)
			return _line(origin, _dir4(caster_pos, target_pos), size, width, grid_size)

		"cone", "cone_forward":
			# cone_forward direction is locked to caster's facing by the caller;
			# the geometry is identical to cone from this resolver's perspective.
			var width: int = aoe.get("width", size)
			return _cone(origin, _dir4(caster_pos, target_pos), size, width, grid_size)

		"cross":
			return _cross(origin, size, grid_size)

		"band":
			# size = strip thickness (width of the band)
			return _band(origin, _dir4(caster_pos, target_pos), size, grid_size)

		"vertical_line":
			# Full column at origin.x — "size" is ignored
			return _vertical_line(origin, grid_size)

		"field_of_view":
			# All tiles the caster can see — full grid until LOS data is available
			return _field_of_view(caster_pos, grid_size)

		_:
			push_warning("AoEResolver: unknown shape '%s', falling back to circle" % shape)
			return _circle(origin, size, grid_size)


## Returns a human-readable description of this AoE for UI tooltips and logs.
static func describe(aoe: Dictionary) -> String:
	var shape:  String = aoe.get("type", "circle")
	var size:   int    = aoe.get("size", aoe.get("base_size", aoe.get("radius", 2)))
	var origin: String = aoe.get("origin", "target")
	var width:  int    = aoe.get("width", 1)

	match shape:
		"circle":
			if origin == "caster":
				return "Circle (radius %d, caster-centered)" % size
			return "Circle (radius %d)" % size

		"nova":
			return "Nova ring (radius %d)" % size

		"around_caster":
			return "Circle around caster (radius %d)" % size

		"line":
			if width > 1:
				return "Line (length %d, width %d)" % [size, width]
			return "Line (length %d)" % size

		"cone", "cone_forward":
			return "Cone (length %d)" % size

		"cross":
			return "Cross + (arm length %d)" % size

		"band":
			return "Band (thickness %d, full row/column)" % size

		"vertical_line":
			return "Full column"

		"field_of_view":
			return "All visible tiles"

		_:
			return "AoE (%s, size %d)" % [shape, size]


# ─── Internal helpers ─────────────────────────────────────────────────────────

## Resolve the primary size value, accepting legacy field names.
## Returns grid_size.x if size was "battlefield_width" sentinel (-1).
static func _resolve_size(aoe: Dictionary, grid_size: Vector2i) -> int:
	var raw = aoe.get("size", aoe.get("base_size", aoe.get("radius", 2)))
	if raw is int or raw is float:
		var s: int = int(raw)
		return grid_size.x if s < 0 else s  # -1 sentinel = full width
	return 2  # fallback for unexpected string values


## Determine the AoE's anchor point from the "origin" field.
## "around_caster" type always uses caster_pos regardless of origin field.
static func _resolve_origin(aoe: Dictionary, caster_pos: Vector2i,
		target_pos: Vector2i) -> Vector2i:
	if aoe.get("type", "") == "around_caster":
		return caster_pos
	match aoe.get("origin", "target"):
		"caster":
			return caster_pos
		"target", "ground", _:
			return target_pos


## Cardinal direction (4-way) from from_pos toward to_pos.
## Snaps to the dominant axis. Returns Vector2i(1,0) if positions are equal.
static func _dir4(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	var delta = to_pos - from_pos
	if delta == Vector2i.ZERO:
		return Vector2i(1, 0)
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


## Bounds check: is this position within the grid?
static func _in_bounds(pos: Vector2i, grid_size: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x \
		and pos.y >= 0 and pos.y < grid_size.y


# ─── Shape implementations ────────────────────────────────────────────────────

## CIRCLE — Manhattan distance diamond centered on `center`.
## radius=1 → 5 tiles, radius=2 → 13 tiles, radius=3 → 25 tiles.
static func _circle(center: Vector2i, radius: int, grid_size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if absi(x) + absi(y) <= radius:
				var pos = center + Vector2i(x, y)
				if _in_bounds(pos, grid_size):
					tiles.append(pos)
	return tiles


## NOVA — hollow ring: only tiles at distance == radius.
## safe_center=true (default): donut ring, center excluded.
## safe_center=false: filled circle minus center tile.
static func _nova(center: Vector2i, radius: int, safe_center: bool,
		grid_size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var dist = absi(x) + absi(y)
			var include: bool = (dist == radius) if safe_center else (dist > 0 and dist <= radius)
			if include:
				var pos = center + Vector2i(x, y)
				if _in_bounds(pos, grid_size):
					tiles.append(pos)
	return tiles


## LINE — straight path of `length` tiles from `origin` in `direction`.
## width=1: single-tile line. width=3: 1 tile on each perpendicular side.
static func _line(origin: Vector2i, direction: Vector2i, length: int, width: int,
		grid_size: Vector2i) -> Array[Vector2i]:
	var perp     = Vector2i(-direction.y, direction.x)  # 90° rotation
	var half_w   = width / 2
	var tiles: Array[Vector2i] = []
	for step in range(1, length + 1):
		for w in range(-half_w, half_w + 1):
			var pos = origin + direction * step + perp * w
			if _in_bounds(pos, grid_size):
				tiles.append(pos)
	return tiles


## CONE — expands outward from origin toward target.
## Tip (step 1) is 1 tile wide; widens by 2 each step up to base_width.
## Example: length=3, base_width=5 → widths [1, 3, 5] at steps 1-3.
static func _cone(origin: Vector2i, direction: Vector2i, length: int, base_width: int,
		grid_size: Vector2i) -> Array[Vector2i]:
	var perp      = Vector2i(-direction.y, direction.x)
	var max_half  = (base_width - 1) / 2
	var tiles: Array[Vector2i] = []
	for step in range(1, length + 1):
		var half_w = min(step - 1, max_half)
		for w in range(-half_w, half_w + 1):
			var pos = origin + direction * step + perp * w
			if _in_bounds(pos, grid_size):
				tiles.append(pos)
	return tiles


## CROSS — plus-sign: center tile + `arm_length` tiles in each of the 4 cardinal directions.
static func _cross(center: Vector2i, arm_length: int, grid_size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if _in_bounds(center, grid_size):
		tiles.append(center)
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for step in range(1, arm_length + 1):
			var pos = center + dir * step
			if _in_bounds(pos, grid_size):
				tiles.append(pos)
	return tiles


## BAND — strip of `thickness` tiles spanning the full row or column.
## If the caster→target direction is horizontal, the band is a vertical column strip.
## If vertical, the band is a horizontal row strip.
## thickness=1: one row/column; thickness=3: one row/column plus one on each side.
static func _band(origin: Vector2i, direction: Vector2i, thickness: int,
		grid_size: Vector2i) -> Array[Vector2i]:
	var half_t = thickness / 2
	var tiles: Array[Vector2i] = []
	if direction.x != 0:
		# Moving left/right → band is vertical columns centered at origin.x
		for offset in range(-half_t, half_t + 1):
			for y in range(grid_size.y):
				var pos = Vector2i(origin.x + offset, y)
				if _in_bounds(pos, grid_size):
					tiles.append(pos)
	else:
		# Moving up/down → band is horizontal rows centered at origin.y
		for offset in range(-half_t, half_t + 1):
			for x in range(grid_size.x):
				var pos = Vector2i(x, origin.y + offset)
				if _in_bounds(pos, grid_size):
					tiles.append(pos)
	return tiles


## VERTICAL_LINE — entire column at origin.x (full grid height).
## The "size" field is ignored; the column always spans the whole battlefield.
static func _vertical_line(origin: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(grid_size.y):
		var pos = Vector2i(origin.x, y)
		if _in_bounds(pos, grid_size):
			tiles.append(pos)
	return tiles


## FIELD_OF_VIEW — all tiles visible to the caster.
## Currently returns the whole grid. Replace with a proper LOS raycast once
## obstacle / elevation data is available in CombatGrid.
static func _field_of_view(_caster_pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			tiles.append(Vector2i(x, y))
	return tiles
