extends Node
## Headless verification for subregions — the places inside a region.
##
## Run: godot --headless res://tools/verify_map_regions.tscn
##
## A zone used to fill its whole rectangle from one weight table, so it kept
## the PROPORTIONS of its terrain and threw away the ARRANGEMENT — word for
## word the flaw the terrain audit found in the battlefield generator. These
## checks are the ones that would have caught what that hid:
##
##   * the animal realm generated 26% ROAD and 1% water, because its weights
##     were keyed to a terrain numbering the game no longer uses;
##   * the "fetid swamps" generated NO SWAMP at all, because cellular-automata
##     smoothing erases any terrain under about a tenth of a zone.
##
## So they assert against the realm's own description rather than against the
## generator: an ocean has water in it, a swamp has swamp, and nowhere is a
## road network by accident.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 15

const T_ROAD := 1
const T_FOREST := 2
const T_WATER := 5
const T_SWAMP := 6
const T_LAVA := 9

var _maps: Dictionary = {}     # realm -> generated map data
var _configs: Dictionary = {}  # realm -> config


func _ready() -> void:
	for realm in ["hell", "hungry_ghost", "animal"]:
		var path := "res://resources/data/map_configs/%s.json" % realm
		_configs[realm] = _load_config(path)
		_maps[realm] = MapGenerator.generate_from_config(path, 4242)

	_check_every_zone_with_biomes_is_cut_up()
	_check_every_biome_in_a_palette_appears()
	_check_a_subregion_names_a_biome_its_zone_declares()
	_check_the_lattice_follows_the_zone_shape()
	_check_every_zone_looks_like_what_it_declares()
	_check_every_zone_contains_its_signature()
	_check_a_biome_blends_rather_than_fills()
	_check_every_pool_names_a_biome_the_world_defines()
	_check_a_biome_decides_how_large_its_patches_are()
	_check_a_biome_draws_its_share_of_danger()
	_check_a_subregion_is_not_a_ribbon()
	_check_an_ocean_has_water_in_it()
	_check_a_swamp_has_swamp_in_it()
	_check_nowhere_is_paved_by_accident()
	_check_the_map_manager_can_say_where_you_are()

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


func _fail(msg: String) -> void:
	printerr("  FAIL: %s" % msg)
	failures += 1


func _done() -> void:
	checks_run += 1


## A zone's palette, resolved against the world's biome library — the shape the
## configs use now: the library defines a kind of place once and each zone names
## the ones it may grow.
func _palette(realm: String, zone: Dictionary) -> Array:
	var out: Array = []
	var library: Dictionary = _configs[realm].get("biomes", {})
	for biome_id in zone.get("biome_pool", {}):
		var definition: Dictionary = library.get(biome_id, {})
		if definition.is_empty():
			continue
		var entry: Dictionary = definition.duplicate(true)
		entry["id"] = str(biome_id)
		out.append(entry)
	return out


func _load_config(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("cannot open %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Terrain counts for one realm, as percentages of the map.
func _mix(realm: String) -> Dictionary:
	var terrain: Array = _maps[realm].get("terrain", [])
	var counts: Dictionary = {}
	for t in terrain:
		counts[int(t)] = int(counts.get(int(t), 0)) + 1
	var out: Dictionary = {}
	var total: int = maxi(1, terrain.size())
	for t in counts:
		out[int(t)] = float(counts[t]) * 100.0 / float(total)
	return out


## The subregions belonging to one zone.
func _subs_of(realm: String, zone_id: String) -> Array:
	var out: Array = []
	for sub in _maps[realm].get("subregions", []):
		if str(sub.get("zone", "")) == zone_id:
			out.append(sub)
	return out


func _check_every_zone_with_biomes_is_cut_up() -> void:
	for realm in _configs:
		for zone in _configs[realm].get("zones", []):
			var biomes: Array = _palette(realm, zone)
			if biomes.is_empty():
				continue
			var subs: Array = _subs_of(realm, str(zone.get("id", "")))
			if subs.size() < biomes.size():
				_fail("%s/%s has %d biomes and only %d subregions — a palette "
					% [realm, str(zone.get("id", "")), biomes.size(), subs.size()]
					+ "larger than the lattice cannot all appear")
			if subs.size() < 4:
				_fail("%s/%s was cut into %d subregions, which is not a place "
					% [realm, str(zone.get("id", "")), subs.size()]
					+ "with places in it")
	_done()


## A zone that rolled none of its wooded subregions reads as a different place
## than it was written to be, so every biome appears at least once.
func _check_every_biome_in_a_palette_appears() -> void:
	# Three seeds, because a weighted draw over a dozen subregions misses a
	# biome often enough that one seed proves nothing.
	for seed_value in [11, 4242, 90210]:
		for realm in _configs:
			var data: Dictionary = MapGenerator.generate_from_config(
				"res://resources/data/map_configs/%s.json" % realm, seed_value)
			for zone in _configs[realm].get("zones", []):
				var palette: Array = _palette(realm, zone)
				if palette.is_empty():
					continue
				var present: Dictionary = {}
				for sub in data.get("subregions", []):
					if str(sub.get("zone", "")) == str(zone.get("id", "")):
						present[str(sub.get("biome", ""))] = true
				for biome in palette:
					if not present.has(str(biome.get("id", ""))):
						_fail("seed %d: %s/%s never generated its '%s' subregion"
							% [seed_value, realm, str(zone.get("id", "")),
								str(biome.get("id", ""))])
	for realm in _configs:
		for zone in _configs[realm].get("zones", []):
			var biomes: Array = zone.get("biomes", [])
			if biomes.is_empty():
				continue
			var seen: Dictionary = {}
			for sub in _subs_of(realm, str(zone.get("id", ""))):
				seen[str(sub.get("biome", ""))] = true
			for biome in biomes:
				if not seen.has(str(biome.get("id", ""))):
					_fail("%s/%s never generated its '%s' subregion"
						% [realm, str(zone.get("id", "")), str(biome.get("id", ""))])
	_done()


func _check_a_subregion_names_a_biome_its_zone_declares() -> void:
	for realm in _configs:
		var palettes: Dictionary = {}
		for zone in _configs[realm].get("zones", []):
			var ids: Dictionary = {}
			for biome in _palette(realm, zone):
				ids[str(biome.get("id", ""))] = true
			palettes[str(zone.get("id", ""))] = ids
		for sub in _maps[realm].get("subregions", []):
			var zone_id: String = str(sub.get("zone", ""))
			var biome: String = str(sub.get("biome", ""))
			if biome == "":
				continue   # a zone with no palette keeps one whole subregion
			if not (palettes.get(zone_id, {}) as Dictionary).has(biome):
				_fail("%s: subregion '%s' claims biome '%s', which its zone "
					% [realm, str(sub.get("id", "")), biome] + "does not declare")
	_done()


## A tall zone wants a tall lattice. Getting this wrong is invisible on the
## map — it just quietly produces too few subregions, which is how the hungry
## ghost swamps came out with eight where they wanted twenty.
func _check_the_lattice_follows_the_zone_shape() -> void:
	for realm in _configs:
		for zone in _configs[realm].get("zones", []):
			if _palette(realm, zone).is_empty():
				continue
			var rows: Array = zone.get("rows", [0, 0])
			var cols: Array = zone.get("cols", [])
			var span_y: int = int(rows[1]) - int(rows[0]) + 1
			# Parenthesised: `a - b + 1 if c else d` binds the ternary to the
			# 1, so a zone with no `cols` came out one tile wide and every
			# subregion looked microscopic.
			var span_x: int = int(_configs[realm].get("width", 192))
			if cols.size() >= 2:
				span_x = int(cols[1]) - int(cols[0]) + 1
			var subs: Array = _subs_of(realm, str(zone.get("id", "")))
			var per_sub: float = float(span_x * span_y) / maxf(1.0, float(subs.size()))
			# Somewhere near the target: small enough to read as one place,
			# large enough to hold a settlement and its fields.
			if per_sub > 2400.0:
				_fail("%s/%s averages %d tiles per subregion — too few cuts for "
					% [realm, str(zone.get("id", "")), int(per_sub)] + "its shape")
			if per_sub < 250.0:
				_fail("%s/%s averages %d tiles per subregion — cut too fine"
					% [realm, str(zone.get("id", "")), int(per_sub)])
	_done()


func _check_an_ocean_has_water_in_it() -> void:
	var mix: Dictionary = _mix("animal")
	var water: float = float(mix.get(T_WATER, 0.0))
	if water < 10.0:
		_fail("the animal realm is %.0f%% water, and a third of it is ocean — "
			% water + "its weights were keyed to a numbering the game no "
			+ "longer uses, which is how this hid")
	if float(mix.get(T_FOREST, 0.0)) < 5.0:
		_fail("the animal realm is %.0f%% forest, and a third of it is forest"
			% float(mix.get(T_FOREST, 0.0)))
	_done()


## Cellular-automata smoothing erases any terrain under about a tenth of a
## zone, which is why the fetid swamps had no swamp. A biome that is locally
## dominant survives it.
func _check_a_swamp_has_swamp_in_it() -> void:
	var mix: Dictionary = _mix("hungry_ghost")
	if float(mix.get(T_SWAMP, 0.0)) < 4.0:
		_fail("the hungry ghost realm is %.1f%% swamp, and one of its three "
			% float(mix.get(T_SWAMP, 0.0)) + "zones is called the fetid swamps")
	var hell_mix: Dictionary = _mix("hell")
	if float(hell_mix.get(T_LAVA, 0.0)) < 3.0:
		_fail("hell is %.1f%% lava" % float(hell_mix.get(T_LAVA, 0.0)))
	_done()


## Roads are carved deliberately, between places. A realm that generates a
## quarter of itself as road has a weights bug, which the animal realm had.
func _check_nowhere_is_paved_by_accident() -> void:
	for realm in _maps:
		var road: float = float(_mix(realm).get(T_ROAD, 0.0))
		if road > 8.0:
			_fail("%s is %.0f%% road, which is a network nobody built" % [realm, road])
	_done()


func _check_the_map_manager_can_say_where_you_are() -> void:
	MapManager._apply_map_data(_maps["animal"])
	if MapManager.subregions.is_empty():
		_fail("MapManager loaded a map and kept no subregions")
		_done()
		return

	var named := 0
	var mismatched := 0
	for sub in MapManager.subregions:
		var seed_pos: Vector2i = sub.get("seed", Vector2i.ZERO)
		var found: Dictionary = MapManager.get_subregion_at(seed_pos)
		# A seed belongs to its own subregion, by construction.
		if str(found.get("id", "")) != str(sub.get("id", "")):
			mismatched += 1
		if MapManager.get_subregion_name_at(seed_pos) != "":
			named += 1
	if mismatched > 0:
		_fail("%d subregion seeds resolve to a different subregion than their "
			% mismatched + "own")

	# And a tile never belongs to a subregion of another zone: the nearest seed
	# across a mountain wall is nearer than any seat on your own side.
	var crossed := 0
	for y in range(0, MapManager.map_size.y, 7):
		for x in range(0, MapManager.map_size.x, 7):
			var at := Vector2i(x, y)
			var zone_here: String = MapManager.get_region_at(at)
			if zone_here == "":
				continue
			var sub: Dictionary = MapManager.get_subregion_at(at)
			if sub.is_empty():
				continue
			if str(sub.get("zone", "")) != zone_here:
				crossed += 1
	if crossed > 0:
		_fail("%d sampled tiles were claimed by a subregion of another zone"
			% crossed)
	if named == 0:
		_fail("no subregion has a name to show the player")
	_done()


## Every zone should look like the thing it says it is. This is the check that
## would have caught the animal realm outright: its "vast open ocean" was 30%
## mountains and 10% water, because the weights were keyed to a terrain
## numbering the game no longer uses, and nobody had played that realm.
##
## The rule is general: the terrain each biome LEADS with has to be findable in
## its own zone, and the zone's commonest terrain has to be one of them.
func _check_every_zone_looks_like_what_it_declares() -> void:
	for realm in _configs:
		var width: int = int(_configs[realm].get("width", 192))
		var terrain: Array = _maps[realm].get("terrain", [])
		for zone in _configs[realm].get("zones", []):
			var palette: Array = _palette(realm, zone)
			if palette.is_empty():
				continue
			var leads: Dictionary = {}
			for biome in palette:
				var top: int = -1
				var top_weight := -1
				for key in biome.get("terrain_weights", {}):
					var w: int = int(biome["terrain_weights"][key])
					if w > top_weight:
						top_weight = w
						top = int(key)
				if top >= 0:
					leads[top] = true

			var mix: Dictionary = _zone_mix(terrain, width, zone)
			var commonest: int = -1
			var most := -1.0
			for t in mix:
				if float(mix[t]) > most:
					most = float(mix[t])
					commonest = int(t)
			for lead in leads:
				if float(mix.get(lead, 0.0)) < 3.0:
					_fail("%s/%s: a biome leads with terrain %d and the zone is "
						% [realm, str(zone.get("id", "")), int(lead)]
						+ "%.1f%% of it" % float(mix.get(lead, 0.0)))
			if commonest >= 0 and not leads.has(commonest):
				_fail("%s/%s is mostly terrain %d, which none of its biomes "
					% [realm, str(zone.get("id", "")), commonest]
					+ "leads with — the weights do not describe the place")
	_done()


## Terrain percentages inside one zone's rectangle.
func _zone_mix(terrain: Array, width: int, zone: Dictionary) -> Dictionary:
	var rows: Array = zone.get("rows", [0, 0])
	var cols: Array = zone.get("cols", [])
	var x0: int = 0
	var x1: int = width - 1
	if cols.size() >= 2:
		x0 = int(cols[0])
		x1 = int(cols[1])
	var counts: Dictionary = {}
	var total := 0
	for y in range(int(rows[0]), int(rows[1]) + 1):
		for x in range(x0, x1 + 1):
			var index: int = y * width + x
			if index < 0 or index >= terrain.size():
				continue
			var t: int = int(terrain[index])
			counts[t] = int(counts.get(t, 0)) + 1
			total += 1
	var out: Dictionary = {}
	for t in counts:
		out[int(t)] = float(counts[t]) * 100.0 / float(maxi(1, total))
	return out


## A subregion should be a patch, not a stripe. The lattice is laid out to
## match the zone's shape for exactly this reason: two columns across a
## 192-wide zone gives ribbons nobody would call a place.
func _check_a_subregion_is_not_a_ribbon() -> void:
	for realm in _maps:
		for sub in _maps[realm].get("subregions", []):
			var rect: Array = sub.get("rect", [])
			if rect.size() < 4:
				continue
			var w: float = float(int(rect[2]) - int(rect[0]) + 1)
			var h: float = float(int(rect[3]) - int(rect[1]) + 1)
			var ratio: float = maxf(w, h) / maxf(1.0, minf(w, h))
			if ratio > 4.0:
				_fail("%s: subregion '%s' is %dx%d — a ribbon, not a patch"
					% [realm, str(sub.get("id", "")), int(w), int(h)])
	_done()


## The one anchor a mis-keyed weight table cannot move: each zone declares the
## terrain it must obviously be made of, and the verifier — not the generator —
## reads it. Every check that reads only the weights moves with them, which is
## how the animal realm's ocean stayed 30% mountains through months of review.
func _check_every_zone_contains_its_signature() -> void:
	for realm in _configs:
		var width: int = int(_configs[realm].get("width", 192))
		var terrain: Array = _maps[realm].get("terrain", [])
		for zone in _configs[realm].get("zones", []):
			var signature: Dictionary = zone.get("signature_terrain", {})
			if signature.is_empty():
				continue
			var mix: Dictionary = _zone_mix(terrain, width, zone)
			var names := ["plains", "road", "forest", "hills", "mountains",
				"water", "swamp", "desert", "snow", "lava", "bridge", "ice",
				"sand", "ruins"]
			for key in signature:
				var wanted: float = float(signature[key])
				var got: float = float(mix.get(int(key), 0.0))
				if got < wanted:
					_fail("%s/%s declares at least %.0f%% %s and generated "
						% [realm, str(zone.get("id", "")), wanted,
							names[int(key)]] + "%.1f%%" % got)
	_done()


## A biome should blend at least two terrains. One terrain at 100% is a solid
## block, not a place — and a biome quietly reduced to that reads as featureless
## ground with an evocative name.
func _check_a_biome_blends_rather_than_fills() -> void:
	for realm in _configs:
		for zone in _configs[realm].get("zones", []):
			for biome in _palette(realm, zone):
				var weights: Dictionary = biome.get("terrain_weights", {})
				if weights.size() < 2:
					_fail("%s/%s: biome '%s' is made of one terrain"
						% [realm, str(zone.get("id", "")), str(biome.get("id", ""))])
					continue
				var total := 0
				var top := 0
				for key in weights:
					total += int(weights[key])
					top = maxi(top, int(weights[key]))
				if total > 0 and float(top) / float(total) > 0.78:
					_fail("%s/%s: biome '%s' is %d%% one terrain, which is a "
						% [realm, str(zone.get("id", "")), str(biome.get("id", "")),
							int(float(top) / float(total) * 100.0)] + "block")
	_done()


## Biomes are the WORLD's library now: defined once, drawn on by any region that
## could hold one. A pool naming something the library does not define is a
## subregion that generates from a fallback and reads as nowhere.
func _check_every_pool_names_a_biome_the_world_defines() -> void:
	for realm in _configs:
		var library: Dictionary = _configs[realm].get("biomes", {})
		if library.is_empty():
			_fail("%s has no biome library" % realm)
			continue
		var used: Dictionary = {}
		for zone in _configs[realm].get("zones", []):
			for biome_id in zone.get("biome_pool", {}):
				used[str(biome_id)] = true
				if not library.has(biome_id):
					_fail("%s/%s draws on biome '%s', which the world does not "
						% [realm, str(zone.get("id", "")), str(biome_id)] + "define")
				if int(zone["biome_pool"][biome_id]) < 1:
					_fail("%s/%s gives biome '%s' weight %s, so it never comes up"
						% [realm, str(zone.get("id", "")), str(biome_id),
							str(zone["biome_pool"][biome_id])])
		# A library entry no zone draws on is a place that cannot happen.
		for biome_id in library:
			if not used.has(str(biome_id)):
				_fail("%s defines biome '%s' and no zone can grow it"
					% [realm, str(biome_id)])
	_done()


## `cluster_min`/`cluster_max` were declared in every map config and read by
## NOTHING until the fill was rewritten to seed patches. They are what makes a
## deep wood one canopy and a reef broken up, so a biome that declares large
## patches must produce measurably larger ones.
func _check_a_biome_decides_how_large_its_patches_are() -> void:
	var data: Dictionary = MapGenerator.generate_from_config(
		"res://resources/data/map_configs/animal.json", 771)
	var terrain: Array = data.get("terrain", [])
	var width: int = 192

	var coarse := 0.0     # average patch size under a large-cluster biome
	var coarse_n := 0
	var fine := 0.0       # and under a small-cluster one
	var fine_n := 0
	for sub in data.get("subregions", []):
		var biome: String = str(sub.get("biome", ""))
		if not biome in ["open_water", "deep_wood", "reef_flats", "rocky_islets"]:
			continue
		var run: float = _average_run_at(terrain, width, sub.get("seed", Vector2i.ZERO))
		if biome in ["open_water", "deep_wood"]:
			coarse += run
			coarse_n += 1
		else:
			fine += run
			fine_n += 1
	if coarse_n == 0 or fine_n == 0:
		_fail("could not sample both a coarse and a fine biome")
	elif coarse / float(coarse_n) <= fine / float(fine_n):
		_fail("large-cluster biomes average %.1f tiles to a run and "
			% (coarse / float(coarse_n))
			+ "small-cluster ones %.1f — cluster_min/max are not being read"
			% (fine / float(fine_n)))
	_done()


## The average length of same-terrain runs through a subregion's middle: a crude
## but honest measure of how chunky the ground is.
func _average_run_at(terrain: Array, width: int, seed_pos: Vector2i) -> float:
	var runs: Array[int] = []
	for dy in range(-4, 5):
		var y: int = seed_pos.y + dy
		var last := -1
		var run := 0
		for dx in range(-10, 11):
			var index: int = y * width + seed_pos.x + dx
			if index < 0 or index >= terrain.size():
				continue
			var t: int = int(terrain[index])
			if t == last:
				run += 1
			else:
				if run > 0:
					runs.append(run)
				last = t
				run = 1
		if run > 0:
			runs.append(run)
	if runs.is_empty():
		return 0.0
	var total := 0
	for r in runs:
		total += r
	return float(total) / float(runs.size())


## `mob_weight` and `event_weight` are the reason to give a biome variables
## beyond its terrain: a deep wood should draw more danger than a clearing, and
## a mausoleum more interest than a dust plain.
##
## Measured where it matters — the tiles mobs were actually placed on, resolved
## to their subregion by the same nearest-seed rule the generator grew them by.
## An earlier version of this check compared the numbers in the records instead
## and passed happily while the bias did nothing.
func _check_a_biome_draws_its_share_of_danger() -> void:
	# Several seeds: one map's placements are few enough to swing either way.
	var appetite_where_placed := 0.0
	var placed := 0
	var appetite_everywhere := 0.0
	var subs_seen := 0

	for seed_value in [5, 88, 404]:
		var data: Dictionary = MapGenerator.generate_from_config(
			"res://resources/data/map_configs/animal.json", seed_value)
		var subs: Array = data.get("subregions", [])
		for sub in subs:
			appetite_everywhere += float(sub.get("mob_weight", 1.0))
			subs_seen += 1
		for mob in data.get("mobs", []):
			var at := Vector2i(int(mob.get("x", 0)), int(mob.get("y", 0)))
			var owner: Dictionary = _nearest_sub(subs, at, str(mob.get("region", "")))
			if owner.is_empty():
				continue
			appetite_where_placed += float(owner.get("mob_weight", 1.0))
			placed += 1

	if placed == 0 or subs_seen == 0:
		_fail("no mobs or no subregions to compare")
		_done()
		return
	var got: float = appetite_where_placed / float(placed)
	var baseline: float = appetite_everywhere / float(subs_seen)
	if got <= baseline:
		_fail("mobs landed in places averaging %.3f appetite where the map "
			% got + "averages %.3f — mob_weight is not biasing placement"
			% baseline)
	_done()


## The subregion nearest `at`, within its own zone where one is named.
func _nearest_sub(subs: Array, at: Vector2i, zone: String) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: int = 1 << 30
	for sub in subs:
		if zone != "" and str(sub.get("zone", "")) != zone:
			continue
		var seed_pos: Vector2i = sub.get("seed", Vector2i.ZERO)
		var dx: int = seed_pos.x - at.x
		var dy: int = seed_pos.y - at.y
		var dist: int = dx * dx + dy * dy
		if dist < best_dist:
			best_dist = dist
			best = sub
	return best
