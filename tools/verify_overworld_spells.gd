extends Node
## Headless verification for spells cast outside combat.
##
## Run: godot --headless res://tools/verify_overworld_spells.tscn
##
## The overworld resolves spells through its OWN path, separate from
## CombatManager, and the two had drifted: the map read `statuses_removed`
## correctly while combat counted the list's length, and the map ignored
## `statuses_caused` entirely. These checks drive the real overworld resolver
## against the real party.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 33

var _menu: Node
var _saved_party: Array = []
var _saved_fallen: Array = []


func _ready() -> void:
	seed(20260914)
	_saved_party = CharacterSystem.party.duplicate()
	_saved_fallen = CharacterSystem.fallen.duplicate()

	# The resolver lives on the character sheet; instance it without showing it.
	var scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	if scene == null:
		printerr("  FAIL: cannot load main_menu.tscn")
		failures += 1
		_finish()
		return
	_menu = scene.instantiate()
	add_child(_menu)

	_check_healing_reaches_the_party()
	_check_granted_statuses_land()
	_check_a_granted_buff_does_not_hurt_you()
	_check_cleanse_removes_by_tag()
	_check_named_cleanse_takes_the_named_status()
	_check_dispel_takes_buffs_on_the_map_too()
	_check_stamina_restore_variants()
	_check_resurrection_reaches_the_fallen()
	_check_overworld_statuses_expire()

	_check_water_walking_opens_water()
	_check_sure_footing_removes_the_slowdown()
	_check_an_ability_lapses_when_its_status_does()
	_check_flight_grants_both_of_its_abilities()
	_check_lava_walking_opens_lava()
	_check_per_terrain_footing_is_narrow()
	_check_a_perk_grants_footing_permanently()

	_check_sense_danger_finds_unseen_mobs()
	_check_a_reveal_respects_its_radius()
	_check_survey_shows_places_not_enemies()
	_check_wayfinding_names_the_nearest_shelter()

	_check_peace_puts_the_nearest_creature_to_sleep()
	_check_a_sleeping_creature_stops_and_wakes()
	_check_misdirection_moves_it_a_short_way()
	_check_begone_sends_it_further_than_misdirection()
	_check_targeting_only_offers_legal_targets()
	_check_the_renderer_refuses_illegal_targets()

	_check_teleport_steps_to_the_chosen_tile()
	_check_intervention_finds_the_nearest_refuge()
	_check_a_visited_map_comes_back_as_it_was()
	_check_planar_shift_crosses_without_unlocking()
	_check_planar_gate_unlocks_what_it_opens()
	_check_the_gate_goes_where_it_is_told()
	_check_every_world_is_offered_to_the_gate()

	_finish()


func _finish() -> void:
	CharacterSystem.party.assign(_saved_party)
	CharacterSystem.fallen.assign(_saved_fallen)
	if checks_run != EXPECTED_CHECKS and failures == 0:
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


## A party of `n`, each at half health, with no statuses.
func _party(n: int) -> void:
	CharacterSystem.party.clear()
	for i in n:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["name"] = "Probe%d" % i
		CharacterSystem.update_derived_stats(c)
		c["derived"]["current_hp"] = int(c["derived"].get("max_hp", 100) / 2)
		c["overworld_statuses"] = []
		CharacterSystem.party.append(c)


func _cast(spell_id: String) -> String:
	var spell: Dictionary = CombatManager.get_spell(spell_id)
	return _menu._apply_overworld_spell(spell_id, spell, CharacterSystem.party[0])


## Cast at a chosen tile, the way the targeting UI does.
func _cast_at(spell_id: String, tile: Vector2i) -> String:
	var spell: Dictionary = CombatManager.get_spell(spell_id)
	return _menu._apply_overworld_spell(spell_id, spell, CharacterSystem.party[0], tile)


func _statuses_on(i: int) -> Array:
	return CharacterSystem.party[i].get("overworld_statuses", [])


func _has(i: int, name: String) -> bool:
	for s in _statuses_on(i):
		if s.get("status", "") == name:
			return true
	return false


# ── Checks ───────────────────────────────────────────────────────────────────

func _check_healing_reaches_the_party() -> void:
	_party(1)
	var before: int = CharacterSystem.party[0]["derived"]["current_hp"]
	_cast("lesser_heal")
	if CharacterSystem.party[0]["derived"]["current_hp"] <= before:
		_fail("lesser_heal healed nothing on the map")
	_done()


## Seven overworld spells carry `statuses_caused` and not one landed — the map
## could remove a status it had no way to acquire from a spell.
func _check_granted_statuses_land() -> void:
	_party(1)
	_cast("cooling_mist")
	if not _has(0, "Fire_Resistance_25"):
		_fail("cooling_mist granted no status on the map (has %s)"
			% str(_statuses_on(0)))
	_done()


## And a granted buff must not be treated as a poison. The overworld tick
## damaged every entry in the list unconditionally, so the first buff to land
## would have cost the party health and reported "Blessed −3 HP".
func _check_a_granted_buff_does_not_hurt_you() -> void:
	_party(1)
	_cast("sacred_ground")
	if not _has(0, "Blessed"):
		_fail("sacred_ground granted no Blessed on the map")
		_done()
		return
	# Drive the REAL tick. An earlier version of this check re-derived the
	# tick's rule instead of running it, so breaking the tick left it green —
	# which is the whole reason the rule now lives somewhere callable.
	var hp_before: int = CharacterSystem.party[0]["derived"]["current_hp"]
	StatusOps.tick_overworld(CharacterSystem.party,
		CombatManager.get_all_status_definitions())
	if CharacterSystem.party[0]["derived"]["current_hp"] != hp_before:
		_fail("a step with a blessing cost %d health — the map tick is treating "
			% (hp_before - CharacterSystem.party[0]["derived"]["current_hp"])
			+ "a buff as a poison")

	# A buff carrying a per-step figure must STILL not hurt you. Combat syncs
	# entries onto this list with a damage_per_step attached, so "is it a
	# debuff" has to be asked before "does it carry a number" — testing only
	# with a bare Blessed left that guard unreachable and unverified.
	_party(1)
	_statuses_on(0).append({"status": "Blessed", "duration": 5, "damage_per_step": 7})
	var blessed_before: int = CharacterSystem.party[0]["derived"]["current_hp"]
	StatusOps.tick_overworld(CharacterSystem.party,
		CombatManager.get_all_status_definitions())
	if CharacterSystem.party[0]["derived"]["current_hp"] < blessed_before:
		_fail("a blessing carrying a damage_per_step cost health — the tick "
			+ "checks the number before it checks whose side the status is on")

	# And a real poison must still hurt, or the guard has simply disabled the tick.
	_party(1)
	_statuses_on(0).append({"status": "Poisoned", "duration": 5, "damage_per_step": 4})
	var poisoned_before: int = CharacterSystem.party[0]["derived"]["current_hp"]
	StatusOps.tick_overworld(CharacterSystem.party,
		CombatManager.get_all_status_definitions())
	if CharacterSystem.party[0]["derived"]["current_hp"] >= poisoned_before:
		_fail("a step while poisoned cost nothing")
	_done()


func _check_cleanse_removes_by_tag() -> void:
	_party(1)
	var st: Array = _statuses_on(0)
	st.append({"status": "Poisoned", "duration": 5})
	st.append({"status": "Bleeding", "duration": 5})
	_cast("cleanse")
	if not _statuses_on(0).is_empty():
		_fail("cleanse left %d status(es) on the map" % _statuses_on(0).size())
	_done()


func _check_named_cleanse_takes_the_named_status() -> void:
	_party(1)
	var st: Array = _statuses_on(0)
	st.append({"status": "Poisoned", "duration": 5})
	st.append({"status": "Burning", "duration": 5})
	_cast("cooling_mist")   # names Burning only
	if _has(0, "Burning"):
		_fail("cooling_mist left the Burning it names")
	if not _has(0, "Poisoned"):
		_fail("cooling_mist removed the Poison it does not name")
	_done()


## Dispel takes buffs as well as debuffs, on the map as in combat.
func _check_dispel_takes_buffs_on_the_map_too() -> void:
	_party(1)
	var st: Array = _statuses_on(0)
	st.append({"status": "Blessed", "duration": 5})
	st.append({"status": "Poisoned", "duration": 5})
	_cast("dispel")
	if not _statuses_on(0).is_empty():
		_fail("dispel left %s on the map" % str(_statuses_on(0)))
	_done()


func _check_stamina_restore_variants() -> void:
	_party(1)
	var derived: Dictionary = CharacterSystem.party[0]["derived"]
	derived["current_stamina"] = 1
	_cast("fragrant_sauna")   # declares restore_stamina_full
	if int(derived.get("current_stamina", 0)) <= 1:
		_fail("fragrant_sauna restored no stamina (%s)" % str(derived.get("current_stamina")))

	derived["current_stamina"] = 1
	_cast("healers_touch")    # declares restore_stamina_percent
	if int(derived.get("current_stamina", 0)) <= 1:
		_fail("healers_touch restored no stamina (%s)" % str(derived.get("current_stamina")))
	_done()


## Out of combat, resurrection reaches the record of the dead. This path
## answered "No fallen allies in the party" whether or not there were any.
func _check_resurrection_reaches_the_fallen() -> void:
	_party(2)
	CharacterSystem.fallen.clear()
	CharacterSystem.record_fallen(1, "killed in battle")
	if CharacterSystem.get_fallen().size() != 1:
		_fail("could not stage a fallen companion")
		_done()
		return

	var said: String = _cast("resurrect")
	if CharacterSystem.get_fallen().size() != 0:
		_fail("resurrect on the map left the dead where they were (said: %s)" % said)
	if CharacterSystem.party.size() != 2:
		_fail("the raised companion did not rejoin (party size %d)"
			% CharacterSystem.party.size())
	_done()


## Everything on the map runs down. A status that never expires is a status the
## party carries for the rest of the run.
func _check_overworld_statuses_expire() -> void:
	_party(1)
	_statuses_on(0).append({"status": "Poisoned", "duration": 2, "damage_per_step": 1})
	_statuses_on(0).append({"status": "Blessed", "duration": 2})
	var defs: Dictionary = CombatManager.get_all_status_definitions()

	for _i in 3:
		StatusOps.tick_overworld(CharacterSystem.party, defs)
	if not _statuses_on(0).is_empty():
		_fail("after 3 steps, %s still stands on a 2-step duration"
			% str(_statuses_on(0)))
	_done()


# ── Movement abilities ───────────────────────────────────────────────────────

func _defs() -> Dictionary:
	return CombatManager.get_all_status_definitions()


## MapManager has read `movement_abilities` in get_terrain_speed all along —
## water, mountains and lava each name the ability that opens them — and
## nothing ever granted one. Three spells existed for exactly this and none was
## castable on the map.
func _check_water_walking_opens_water() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	# Stage a real water tile and ask the real question: can the party cross?
	# Asserting only that the flag is set would pass while terrain ignored it.
	var tile := Vector2i(3, 3)
	MapManager.tiles[tile] = MapManager.Terrain.WATER
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 8),
		maxi(MapManager.map_size.y, 8))

	if MapManager.is_passable(tile):
		_fail("water is passable with no ability, so this check proves nothing")
		_done()
		return

	_cast("water_walking")
	if not MapManager.is_passable(tile):
		_fail("after Water Walking the party still cannot cross water "
			+ "(abilities: %s)" % str(MapManager.movement_abilities))
	MapManager.tiles.erase(tile)
	_done()


## Sure footing answers the other half of terrain — the slowdown — which
## TERRAIN_ABILITIES never spoke about. Levitate claimed "immunity to
## ground/terrain effects" and delivered none.
func _check_sure_footing_removes_the_slowdown() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	var tile := Vector2i(4, 4)
	MapManager.tiles[tile] = MapManager.Terrain.SWAMP
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 8),
		maxi(MapManager.map_size.y, 8))
	var slowed: float = MapManager.get_terrain_speed(tile)
	if slowed >= 1.0:
		_fail("swamp is not slow in this build, so the check proves nothing")
		MapManager.tiles.erase(tile)
		_done()
		return

	_cast("levitate")
	if MapManager.get_terrain_speed(tile) <= slowed:
		_fail("after Levitate a swamp still costs %.2f speed (was %.2f) — sure "
			% [MapManager.get_terrain_speed(tile), slowed]
			+ "footing is set but terrain does not read it")
	MapManager.tiles.erase(tile)
	_done()


## And it lapses. The ability is recomputed from who is still carrying the
## status, so a spell that has worn off simply is not found.
func _check_an_ability_lapses_when_its_status_does() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	_cast("water_walking")
	if not MapManager.has_movement_ability("water_walking"):
		_fail("could not stage the ability")
		_done()
		return

	# Run the status out.
	for s in _statuses_on(0):
		s["duration"] = 1
	StatusOps.tick_overworld(CharacterSystem.party, _defs())
	if MapManager.has_movement_ability("water_walking"):
		_fail("the party still walks on water after the spell expired")
	_done()


## Flying grants two abilities at once — over the mountains, and nothing
## underfoot to slow you. A source may name one ability or several, and only
## casting the one that names several tests that.
func _check_flight_grants_both_of_its_abilities() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	var peak := Vector2i(5, 5)
	var bog := Vector2i(6, 6)
	MapManager.tiles[peak] = MapManager.Terrain.MOUNTAINS
	MapManager.tiles[bog] = MapManager.Terrain.SWAMP
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 9),
		maxi(MapManager.map_size.y, 9))

	_cast("fly")
	if not MapManager.is_passable(peak):
		_fail("after Fly the party still cannot cross a mountain")
	if MapManager.get_terrain_speed(bog) < 1.0:
		_fail("after Fly a swamp still slows the party to %.2f — the second "
			% MapManager.get_terrain_speed(bog) + "ability in the list was dropped")
	MapManager.tiles.erase(peak)
	MapManager.tiles.erase(bog)
	_done()


## Fire had no mobility magic at all, and lava was the one impassable terrain
## with no spell.
func _check_lava_walking_opens_lava() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	var flow := Vector2i(7, 3)
	MapManager.tiles[flow] = MapManager.Terrain.LAVA
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 9),
		maxi(MapManager.map_size.y, 9))
	if MapManager.is_passable(flow):
		_fail("lava is passable with no ability, so this check proves nothing")
		MapManager.tiles.erase(flow)
		_done()
		return

	_cast("lava_walking")
	if not MapManager.is_passable(flow):
		_fail("after Lava Walking the party still cannot cross lava (%s)"
			% str(MapManager.movement_abilities))
	MapManager.tiles.erase(flow)
	_done()


## Each element answers its own ground, and only its own. Marshtread crosses a
## bog at pace and leaves the desert exactly as slow as it was — that
## narrowness is the reason to carry more than one.
func _check_per_terrain_footing_is_narrow() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	var bog := Vector2i(2, 6)
	var dune := Vector2i(3, 6)
	MapManager.tiles[bog] = MapManager.Terrain.SWAMP
	MapManager.tiles[dune] = MapManager.Terrain.DESERT
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 9),
		maxi(MapManager.map_size.y, 9))
	var dune_before: float = MapManager.get_terrain_speed(dune)

	_cast("marshtread")
	if MapManager.get_terrain_speed(bog) < 1.0:
		_fail("Marshtread left a swamp at %.2f speed"
			% MapManager.get_terrain_speed(bog))
	if MapManager.get_terrain_speed(dune) != dune_before:
		_fail("Marshtread also cleared the desert (%.2f -> %.2f) — the "
			% [dune_before, MapManager.get_terrain_speed(dune)]
			+ "per-terrain abilities are not narrow")

	# And the desert spell does the opposite.
	_party(1)
	MapManager.clear_movement_abilities()
	_cast("camels_blessing")
	if MapManager.get_terrain_speed(dune) < 1.0:
		_fail("Camel's Blessing left the desert at %.2f speed"
			% MapManager.get_terrain_speed(dune))
	if MapManager.get_terrain_speed(bog) >= 1.0:
		_fail("Camel's Blessing also cleared the swamp")
	MapManager.tiles.erase(bog)
	MapManager.tiles.erase(dune)
	_done()


## Sure Step is training rather than a spell, so it holds with no status and
## no duration — a quartermaster who cannot cross broken ground is not much
## of one.
func _check_a_perk_grants_footing_permanently() -> void:
	_party(1)
	MapManager.clear_movement_abilities()
	var wood := Vector2i(4, 7)
	MapManager.tiles[wood] = MapManager.Terrain.FOREST
	MapManager.map_size = Vector2i(maxi(MapManager.map_size.x, 9),
		maxi(MapManager.map_size.y, 9))
	var slowed: float = MapManager.get_terrain_speed(wood)
	if slowed >= 1.0:
		_fail("forest is not slow in this build, so the check proves nothing")
		MapManager.tiles.erase(wood)
		_done()
		return

	CharacterSystem.party[0]["perks"] = [{"id": "sure_step"}]
	MapManager.refresh_movement_abilities(CharacterSystem.party, _defs())
	if MapManager.get_terrain_speed(wood) <= slowed:
		_fail("Sure Step left a forest at %.2f speed — a perk grants no "
			% MapManager.get_terrain_speed(wood) + "movement ability")

	# It must also survive a tick, which recomputes from scratch.
	StatusOps.tick_overworld(CharacterSystem.party, _defs())
	if MapManager.get_terrain_speed(wood) <= slowed:
		_fail("Sure Step lapsed after one step — a perk is not a status and "
			+ "does not expire")
	MapManager.tiles.erase(wood)
	_done()


# ── Divination ───────────────────────────────────────────────────────────────

## Stage a mob and an object at known tiles, with the party at the origin.
func _stage_map() -> void:
	MapManager.mobs.clear()
	MapManager.objects.clear()
	MapManager.visited_tiles.clear()
	MapManager.map_size = Vector2i(60, 60)
	MapManager.party_position = Vector2i(10, 10)


## Matches the shape MapManager spawns, not a minimal stub — tick_mobs reads
## `is_moving` unguarded, and a fixture thinner than the real thing fails for
## reasons that have nothing to do with the spell under test.
func _add_mob(id: String, at: Vector2i) -> void:
	MapManager.mobs.append({
		"id": id, "position": at, "name": id, "icon": "enemy",
		"mode": 0, "attitude": 1, "is_moving": false, "is_pursuing": false,
		"roam_timer": 0.0, "roam_radius": 4, "roam_pause": 1.0,
		"home_position": at, "pursuit_path": [] as Array[Vector2i],
		"pursuit_path_index": 0, "pursuit_timer": 0.0,
		"detect_range": 3, "leash_range": 5, "aggression": 0.0,
		"data": {},
	})


func _add_object(at: Vector2i, icon: String, name: String) -> void:
	MapManager.objects[at] = {"id": name, "position": at, "icon": icon,
		"name": name, "visible": false, "type": 0}


## A mob outside the fog is invisible until something shows it.
func _check_sense_danger_finds_unseen_mobs() -> void:
	_party(1)
	_stage_map()
	_add_mob("near_wolf", Vector2i(18, 10))    # 8 tiles — inside 16
	if MapManager.get_visible_mobs().size() != 0:
		_fail("an unvisited mob is already visible, so this proves nothing")
		_done()
		return

	_cast("sense_danger")
	if MapManager.get_visible_mobs().size() != 1:
		_fail("Sense Danger revealed %d mobs, expected 1"
			% MapManager.get_visible_mobs().size())
	_done()


## And one beyond its reach stays hidden — the radius is the spell.
func _check_a_reveal_respects_its_radius() -> void:
	_party(1)
	_stage_map()
	_add_mob("near_wolf", Vector2i(18, 10))    # 8 tiles
	_add_mob("far_wolf", Vector2i(50, 10))     # 40 tiles — outside 16
	_cast("sense_danger")

	var seen: Array = MapManager.get_visible_mobs()
	var names: Array[String] = []
	for m in seen:
		names.append(str(m.get("id", "")))
	if not "near_wolf" in names:
		_fail("Sense Danger missed a mob 8 tiles away")
	if "far_wolf" in names:
		_fail("Sense Danger reached a mob 40 tiles away on a radius of 16")

	# Mirror Scrying has no radius at all and must reach both.
	_cast("mirror_scrying")
	if MapManager.get_visible_mobs().size() != 2:
		_fail("Mirror Scrying showed %d of 2 mobs across the whole map"
			% MapManager.get_visible_mobs().size())
	_done()


## Survey shows places, not creatures. A spell that quietly did both would
## make Sense Danger pointless.
func _check_survey_shows_places_not_enemies() -> void:
	_party(1)
	_stage_map()
	_add_object(Vector2i(14, 10), "shop", "Bone Market")
	_add_mob("lurker", Vector2i(14, 12))
	_cast("survey_the_land")

	var revealed := 0
	for pos in MapManager.objects:
		if MapManager.objects[pos].get("visible", false):
			revealed += 1
	if revealed != 1:
		_fail("Survey the Land revealed %d of 1 place" % revealed)
	if MapManager.get_visible_mobs().size() != 0:
		_fail("Survey the Land also revealed creatures — that is Sense "
			+ "Danger's job and the two would collapse into one spell")
	_done()


## Wayfinding finds the closest shelter at any distance, and says which way.
func _check_wayfinding_names_the_nearest_shelter() -> void:
	_party(1)
	_stage_map()
	_add_object(Vector2i(10, 45), "rest", "Far Teahouse")     # 35 south
	_add_object(Vector2i(28, 10), "shop", "Nearer Market")    # 18 east
	_add_object(Vector2i(12, 10), "enemy", "Ambush")          # close, not shelter

	var said: String = _cast("wayfinding")
	if not "Nearer Market" in said:
		_fail("Wayfinding named '%s' — expected the nearer of two shelters" % said)
	if not "east" in said:
		_fail("Wayfinding gave no direction: '%s'" % said)

	var revealed := 0
	for pos in MapManager.objects:
		if MapManager.objects[pos].get("visible", false):
			revealed += 1
	if revealed != 1:
		_fail("Wayfinding revealed %d places; it should show exactly one" % revealed)
	_done()


# ── Mob handling ─────────────────────────────────────────────────────────────

## The nearest one, because there is no way to point at a creature on the
## overworld — and because you deal with what is bearing down on you.
func _check_peace_puts_the_nearest_creature_to_sleep() -> void:
	_party(1)
	_stage_map()
	_add_mob("close", Vector2i(13, 10))    # 3 tiles
	_add_mob("distant", Vector2i(30, 10))  # 20 tiles, outside radius 6

	_cast_at("peace", Vector2i(13, 10))
	if int(MapManager.mobs[0].get("asleep_steps", 0)) <= 0:
		_fail("Peace left the creature it was aimed at awake")
	if int(MapManager.mobs[1].get("asleep_steps", 0)) > 0:
		_fail("Peace also reached a creature it was not aimed at")

	# The radius only bites when the NEAREST creature is out of reach — with
	# two in play the spell picks the closer one either way, so dropping the
	# check entirely would go unnoticed. One distant creature is the case that
	# tells them apart.
	_party(1)
	_stage_map()
	_add_mob("far_only", Vector2i(30, 10))   # 20 tiles, radius is 6
	var said: String = _cast_at("peace", Vector2i(30, 10))
	if int(MapManager.mobs[0].get("asleep_steps", 0)) > 0:
		_fail("Peace reached a creature 20 tiles away on a radius of 6")
	if not "reach" in said:
		_fail("Peace aimed out of range said '%s'" % said)
	_done()


## Sleep has to stop the creature AND let the party past, then run out.
func _check_a_sleeping_creature_stops_and_wakes() -> void:
	_party(1)
	_stage_map()
	_add_mob("sleeper", Vector2i(13, 10))
	MapManager.mobs[0]["is_pursuing"] = true
	MapManager.mobs[0]["mode"] = 2   # ROAMING
	_cast_at("peace", Vector2i(13, 10))

	if MapManager.mobs[0].get("is_pursuing", false):
		_fail("a sleeping creature is still giving chase")

	var stayed: Vector2i = MapManager.mobs[0].position
	MapManager.tick_mobs()
	if MapManager.mobs[0].position != stayed:
		_fail("a sleeping roamer wandered from %s to %s"
			% [str(stayed), str(MapManager.mobs[0].position)])

	# Five steps, then awake.
	for _i in 6:
		MapManager.tick_mobs()
	if int(MapManager.mobs[0].get("asleep_steps", 0)) > 0:
		_fail("the creature is still asleep after 7 steps of a 5-step spell")
	_done()


func _check_misdirection_moves_it_a_short_way() -> void:
	_party(1)
	_stage_map()
	for x in range(60):
		for y in range(60):
			MapManager.tiles[Vector2i(x, y)] = MapManager.Terrain.PLAINS
	_add_mob("shunted", Vector2i(14, 10))
	var was: Vector2i = MapManager.mobs[0].position

	_cast_at("misdirection", Vector2i(14, 10))
	var now: Vector2i = MapManager.mobs[0].position
	if now == was:
		_fail("Misdirection did not move the creature")
	else:
		var moved: int = maxi(absi(now.x - was.x), absi(now.y - was.y))
		if moved < 6 or moved > 8:
			_fail("Misdirection moved the creature %d tiles; 6-8 was intended"
				% moved)
	_done()


## Begone! is the same idea without a leash — anywhere on the map, which will
## usually be much further than Misdirection.
func _check_begone_sends_it_further_than_misdirection() -> void:
	_party(1)
	_stage_map()
	for x in range(60):
		for y in range(60):
			MapManager.tiles[Vector2i(x, y)] = MapManager.Terrain.PLAINS
	_add_mob("banished", Vector2i(14, 10))
	var was: Vector2i = MapManager.mobs[0].position

	# Averaged, because a random tile on a 60x60 map is occasionally nearby.
	var total := 0
	for _i in 8:
		MapManager.mobs[0]["position"] = was
		_cast_at("begone", was)
		total += maxi(absi(MapManager.mobs[0].position.x - was.x),
			absi(MapManager.mobs[0].position.y - was.y))
	var mean: float = float(total) / 8.0
	if mean <= 8.0:
		_fail("Begone! averaged %.1f tiles over 8 casts — no further than "
			% mean + "Misdirection, so the two spells are the same spell")
	_done()


## The renderer decides what may be clicked, and a spell aimed at empty ground
## or at something out of reach must do nothing rather than quietly picking
## whatever was closest — which is what the first version of these spells did.
func _check_targeting_only_offers_legal_targets() -> void:
	_party(1)
	_stage_map()
	_add_mob("in_reach", Vector2i(13, 10))    # 3 tiles
	_add_mob("too_far", Vector2i(40, 10))     # 30 tiles

	var empty: String = _cast_at("peace", Vector2i(12, 12))
	if not "nothing" in empty:
		_fail("Peace aimed at empty ground said '%s'" % empty)
	for mob in MapManager.mobs:
		if int(mob.get("asleep_steps", 0)) > 0:
			_fail("Peace aimed at empty ground still slept %s" % str(mob.id))

	var far: String = _cast_at("peace", Vector2i(40, 10))
	if not "reach" in far:
		_fail("Peace aimed 30 tiles away said '%s'" % far)
	if int(MapManager.mobs[1].get("asleep_steps", 0)) > 0:
		_fail("Peace reached a creature far outside its radius")

	# And the aimed-at one does work.
	_cast_at("peace", Vector2i(13, 10))
	if int(MapManager.mobs[0].get("asleep_steps", 0)) <= 0:
		_fail("Peace aimed at a legal target did nothing")
	_done()


## The renderer decides what may be CLICKED, which is a separate guard from the
## one MapManager applies when the spell resolves. Both must hold: the first
## stops you aiming at nothing, the second stops a bad aim landing anyway.
## Testing only through the resolver left the click guard unverified.
func _check_the_renderer_refuses_illegal_targets() -> void:
	_party(1)
	_stage_map()
	for x in range(60):
		for y in range(60):
			MapManager.tiles[Vector2i(x, y)] = MapManager.Terrain.PLAINS
	_add_mob("in_reach", Vector2i(13, 10))    # 3 tiles
	_add_mob("too_far", Vector2i(40, 10))     # 30 tiles
	# Both must be visible, or "cannot click it" would be true for the wrong reason.
	for mob in MapManager.mobs:
		mob["revealed"] = true

	var renderer: Node2D = load("res://scripts/overworld/map_renderer.gd").new()
	add_child(renderer)
	renderer.begin_targeting("mob", 6, "Peace")

	if not renderer._is_legal_target(Vector2i(13, 10)):
		_fail("the renderer refuses a visible creature 3 tiles away, inside a "
			+ "radius of 6")
	if renderer._is_legal_target(Vector2i(40, 10)):
		_fail("the renderer offers a creature 30 tiles away on a radius of 6")
	if renderer._is_legal_target(Vector2i(12, 12)):
		_fail("the renderer offers empty ground as a creature")

	# A tile-targeted spell wants passable ground, not a creature.
	renderer.begin_targeting("tile", 5, "Blink")
	if not renderer._is_legal_target(Vector2i(12, 10)):
		_fail("the renderer refuses passable ground 2 tiles away")
	MapManager.tiles[Vector2i(12, 10)] = MapManager.Terrain.MOUNTAINS
	MapManager.clear_movement_abilities()
	if renderer._is_legal_target(Vector2i(12, 10)):
		_fail("the renderer offers an impassable tile as a destination")

	renderer.cancel_targeting()
	if renderer.is_targeting():
		_fail("cancelling left the renderer in targeting mode")
	renderer.queue_free()
	_done()


# ── Teleportation ────────────────────────────────────────────────────────────

func _open_ground() -> void:
	for x in range(60):
		for y in range(60):
			MapManager.tiles[Vector2i(x, y)] = MapManager.Terrain.PLAINS


func _check_teleport_steps_to_the_chosen_tile() -> void:
	_party(1)
	_stage_map()
	_open_ground()
	var dest := Vector2i(20, 14)
	_cast_at("teleport", dest)
	if MapManager.get_party_position() != dest:
		_fail("Teleport left the party at %s, aimed at %s"
			% [str(MapManager.get_party_position()), str(dest)])
	_done()


## The last-ditch button, so it must find a refuge and not a shrine or a chest.
func _check_intervention_finds_the_nearest_refuge() -> void:
	_party(1)
	_stage_map()
	_open_ground()
	_add_object(Vector2i(12, 10), "shrine", "Roadside Shrine")   # 2 tiles, not a refuge
	_add_object(Vector2i(25, 10), "rest", "Near Teahouse")       # 15 tiles
	_add_object(Vector2i(50, 10), "shop", "Far Market")          # 40 tiles

	var said: String = _cast("intervention")
	if MapManager.get_party_position() != Vector2i(25, 10):
		_fail("Intervention put the party at %s; the nearest refuge is (25, 10) — %s"
			% [str(MapManager.get_party_position()), said])
	_done()


## Generated maps are rolled fresh every load, and nothing kept the old one —
## so leaving a world and returning handed you a different version of it.
func _check_a_visited_map_comes_back_as_it_was() -> void:
	_party(1)
	_stage_map()
	_open_ground()
	MapManager.current_map_id = "probe_a"
	MapManager.tiles[Vector2i(5, 5)] = MapManager.Terrain.LAVA
	MapManager.visited_tiles[Vector2i(7, 7)] = true
	var fingerprint: int = MapManager.tiles[Vector2i(5, 5)]

	MapManager.stash_current_map()
	if not MapManager.visited_maps.has("probe_a"):
		_fail("leaving a map did not stash it")
		_done()
		return

	# Somewhere else, then back.
	MapManager.current_map_id = "probe_b"
	MapManager.tiles.clear()
	MapManager.visited_tiles.clear()
	MapManager.load_map("probe_a")

	if MapManager.current_map_id != "probe_a":
		_fail("returning loaded '%s'" % MapManager.current_map_id)
	elif MapManager.tiles.get(Vector2i(5, 5), -1) != fingerprint:
		_fail("the lava at (5,5) is gone — the map was regenerated rather "
			+ "than restored")
	elif not MapManager.is_tile_visited(Vector2i(7, 7)):
		_fail("the fog came back — what the party had explored was lost")
	_done()


## Planar Shift reaches a plane the party has no right to be in, and does not
## give them a way back to it.
func _check_planar_shift_crosses_without_unlocking() -> void:
	var saved_world: String = GameState.current_world
	var saved_unlocked: Array = GameState.unlocked_worlds.duplicate()
	var saved_return: Dictionary = GameState.planar_return.duplicate()

	GameState.current_world = "hell"
	GameState.unlocked_worlds = ["hell"]
	GameState.planar_return = {}

	var ok: bool = GameState.begin_planar_excursion("god", 3, "hell_01", Vector2i(4, 4))
	if not ok:
		_fail("begin_planar_excursion refused a locked world — bypassing the "
			+ "lock is the point of the spell")
	elif GameState.current_world != "god":
		_fail("the party is in '%s', expected god" % GameState.current_world)
	elif "god" in GameState.unlocked_worlds:
		_fail("Planar Shift unlocked the world it visited; only the Gate does that")

	# And the pull home comes on schedule.
	var home := false
	for _i in 3:
		home = GameState.tick_planar_excursion()
	if not home:
		_fail("the excursion did not end after its 3 steps")
	elif GameState.current_world != "hell":
		_fail("the party came home to '%s'" % GameState.current_world)

	GameState.current_world = saved_world
	GameState.unlocked_worlds.assign(saved_unlocked)
	GameState.planar_return = saved_return
	_done()


## The Gate is the opposite bargain: it keeps what it opens.
func _check_planar_gate_unlocks_what_it_opens() -> void:
	var saved_world: String = GameState.current_world
	var saved_unlocked: Array = GameState.unlocked_worlds.duplicate()
	GameState.current_world = "hell"
	GameState.unlocked_worlds = ["hell"]

	_party(1)
	_stage_map()
	_cast("portal")

	if GameState.current_world == "hell":
		_fail("Planar Gate did not move the party")
	elif not GameState.current_world in GameState.unlocked_worlds:
		_fail("Planar Gate opened onto '%s' and did not unlock it"
			% GameState.current_world)
	if not GameState.planar_return.is_empty():
		_fail("Planar Gate left a return pending; it is permanent")

	GameState.current_world = saved_world
	GameState.unlocked_worlds.assign(saved_unlocked)
	_done()


## The Gate is the spell that decides where it goes. Choosing for the caster
## would miss the whole point of it.
func _check_the_gate_goes_where_it_is_told() -> void:
	var saved_world: String = GameState.current_world
	var saved_unlocked: Array = GameState.unlocked_worlds.duplicate()
	GameState.current_world = "hell"
	GameState.unlocked_worlds = ["hell", "hungry_ghost", "animal"]

	_party(1)
	_stage_map()
	var spell: Dictionary = CombatManager.get_spell("portal").duplicate(true)
	spell["translocate"] = (spell["translocate"] as Dictionary).duplicate()

	# An ALREADY-UNLOCKED world, which the automatic pick would never choose —
	# it prefers unreached ones. Only an explicit choice lands here.
	spell["translocate"]["world"] = "animal"
	_menu._apply_overworld_spell("portal", spell, CharacterSystem.party[0])
	if GameState.current_world != "animal":
		_fail("the Gate was told 'animal' and opened onto '%s'"
			% GameState.current_world)

	# And somewhere never reached.
	GameState.current_world = "hell"
	spell["translocate"]["world"] = "god"
	_menu._apply_overworld_spell("portal", spell, CharacterSystem.party[0])
	if GameState.current_world != "god":
		_fail("the Gate was told 'god' and opened onto '%s'"
			% GameState.current_world)
	elif not "god" in GameState.unlocked_worlds:
		_fail("the Gate reached an unvisited plane and did not keep it")

	GameState.current_world = saved_world
	GameState.unlocked_worlds.assign(saved_unlocked)
	_done()


## Every realm is offered, including the ones never reached — reaching them is
## what the spell is for. Only the one underfoot is refused.
func _check_every_world_is_offered_to_the_gate() -> void:
	var offered := 0
	var refused := 0
	for world_id in GameState.WORLDS:
		if world_id == GameState.current_world:
			refused += 1
		else:
			offered += 1
	if GameState.WORLDS.size() != 6:
		_fail("expected six realms, found %d" % GameState.WORLDS.size())
	if offered != 5 or refused != 1:
		_fail("the picker would offer %d realms and refuse %d; expected 5 and 1"
			% [offered, refused])

	# And the Cast button would raise the picker for it. The button cannot be
	# pressed headless, so the rule it applies lives in a function both it and
	# this check call — a branch nothing can reach is a branch nothing checks.
	if _menu.spell_prompt_kind(CombatManager.get_spell("portal")) != "world":
		_fail("Planar Gate would not raise the world picker")
	if _menu.spell_prompt_kind(CombatManager.get_spell("peace")) != "mob":
		_fail("Peace would not raise the creature picker")
	if _menu.spell_prompt_kind(CombatManager.get_spell("teleport")) != "tile":
		_fail("Teleport would not raise the tile picker")
	if _menu.spell_prompt_kind(CombatManager.get_spell("lesser_heal")) != "":
		_fail("Lesser Heal would stop to ask something")

	# The whole pending-cast path, the way the picker drives it.
	var saved_world2: String = GameState.current_world
	GameState.current_world = "hell"
	_menu._pending_map_cast = {"spell_id": "portal",
		"spell_data": CombatManager.get_spell("portal"),
		"caster": CharacterSystem.party[0]}
	CharacterSystem.party[0]["derived"]["current_mana"] = 400
	_menu.resolve_pending_world_cast("asura")
	if GameState.current_world != "asura":
		_fail("resolving a pending world cast for 'asura' landed on '%s'"
			% GameState.current_world)
	GameState.current_world = saved_world2
	_done()
