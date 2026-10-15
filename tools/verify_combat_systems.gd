extends Node
## Headless verification for forced movement, AoE damage falloff, the
## skeleton_king_duel stop condition, and severing a four-armed body's extra arms.
##
## Run: godot --headless res://tools/verify_combat_systems.tscn
##
## Uses a real CombatGrid and real CombatUnits rather than doubles. Both can be
## built headless, and the things most likely to be wrong here — what counts as
## a blocked tile, which ring a tile falls in — are exactly the things a double
## would have to assume.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var grid: CombatGrid

## A runtime error inside a check — a missing function, a property that is not
## there — aborts that check and returns control to _ready(), which would then
## find no failures and report OK having verified nothing. Every check signs off
## by bumping this, and the count is asserted at the end.
var checks_run: int = 0
const EXPECTED_CHECKS: int = 14


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	_check_falloff_absent_by_default()
	_check_falloff_directional()
	_check_falloff_centred()
	_check_falloff_arc()

	_check_push_clear_path()
	_check_push_into_map_edge()
	_check_push_into_unit()
	_check_pull()
	_check_push_immunity()
	_check_apply_push_blocked_damage()
	_check_skill_aoe_falloff_integration()

	_check_severing_an_extra_arm()
	_check_duel_stop_survives_the_encounter_build()
	# Last, because it really ends a combat — end_combat() clears all_units
	# and the grid reference that the checks above rely on.
	await _check_duel_ends_the_moment_the_boss_yields()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway, "
			% [checks_run, EXPECTED_CHECKS] + "so its assertions never ran")
		failures += 1

	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


## Called as the last line of every check, so an aborted one is visible.
func _done() -> void:
	checks_run += 1


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


func _expect_near(actual: float, expected: float, what: String) -> void:
	if absf(actual - expected) > 0.001:
		_fail("%s: got %.3f, expected %.3f" % [what, actual, expected])


# ── AoE damage falloff ───────────────────────────────────────────────────────

## Falloff is opt-in. An area with no `falloff` key must damage evenly, exactly
## as every area does today — this is the assertion that stops the feature from
## silently becoming a global balance change.
func _check_falloff_absent_by_default() -> void:
	var aoe := {"type": "circle", "size": 3}
	for tile in [Vector2i(10, 10), Vector2i(12, 10), Vector2i(13, 13)]:
		_expect_near(
			AoEResolver.falloff_at(aoe, Vector2i(10, 10), Vector2i(10, 10), tile),
			1.0, "no falloff declared at %s" % tile)
	_done()


## A caster-anchored line puts its first target at distance 1, not 0. Indexing
## by raw distance would hand that target the second ring's multiplier, which is
## the whole reason falloff indexes by ring-within-shape.
func _check_falloff_directional() -> void:
	var aoe := {"type": "line", "size": 3, "width": 1,
		"origin": "caster", "falloff": [100, 60]}
	var caster := Vector2i(10, 10)
	var target := Vector2i(11, 10)  # facing east
	_expect_near(AoEResolver.falloff_at(aoe, caster, target, Vector2i(11, 10)),
		1.0, "line ring 0 (adjacent tile)")
	_expect_near(AoEResolver.falloff_at(aoe, caster, target, Vector2i(12, 10)),
		0.6, "line ring 1")
	# The last entry repeats outward rather than falling to zero.
	_expect_near(AoEResolver.falloff_at(aoe, caster, target, Vector2i(13, 10)),
		0.6, "line ring 2 repeats the last entry")
	_done()


## A centred shape includes its origin tile, so ring 0 is the origin itself.
func _check_falloff_centred() -> void:
	var aoe := {"type": "circle", "size": 3, "falloff": [100, 75, 50]}
	var origin := Vector2i(20, 15)
	_expect_near(AoEResolver.falloff_at(aoe, Vector2i(10, 10), origin, origin),
		1.0, "circle ring 0 (origin tile)")
	_expect_near(AoEResolver.falloff_at(aoe, Vector2i(10, 10), origin, Vector2i(21, 15)),
		0.75, "circle ring 1")
	_expect_near(AoEResolver.falloff_at(aoe, Vector2i(10, 10), origin, Vector2i(22, 15)),
		0.5, "circle ring 2")
	_expect_near(AoEResolver.falloff_at(aoe, Vector2i(10, 10), origin, Vector2i(23, 15)),
		0.5, "circle ring 3 repeats the last entry")
	_done()


## Red Harvest's arc is one ring deep and three wide: every tile it covers is
## ring 0, so a falloff list must not taper across the sweep.
func _check_falloff_arc() -> void:
	var aoe := {"type": "arc", "size": 1, "width": 3,
		"origin": "caster", "falloff": [100, 50]}
	var caster := Vector2i(10, 10)
	var target := Vector2i(11, 10)
	for tile in [Vector2i(11, 9), Vector2i(11, 10), Vector2i(11, 11)]:
		_expect_near(AoEResolver.falloff_at(aoe, caster, target, tile),
			1.0, "arc tile %s is ring 0" % tile)
	_done()


# ── Forced movement ──────────────────────────────────────────────────────────

func _make_unit(at: Vector2i, team: int = 1) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe"
	unit.team = team
	unit.current_hp = 100
	unit.max_hp = 100
	unit.character_data = CharacterSystem.create_blank_character()
	add_child(unit)
	unit.grid_position = at
	grid.unit_positions[at] = unit
	# _units_in_skill_aoe scans CombatManager.all_units, not the grid, so a unit
	# that exists only on the grid is invisible to every area effect.
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


func _check_push_clear_path() -> void:
	var unit := _make_unit(Vector2i(20, 15))
	var result: Dictionary = CombatManager._displace_unit(
		unit, Vector2i(1, 0), 2, null)
	if result.get("moved", -1) != 2:
		_fail("clear push: moved %s, expected 2" % result.get("moved"))
	if result.get("lost", -1) != 0:
		_fail("clear push: lost %s, expected 0" % result.get("lost"))
	if unit.grid_position != Vector2i(22, 15):
		_fail("clear push: ended at %s, expected (22, 15)" % unit.grid_position)
	_cleanup([unit])
	_done()


## The map edge stops a push without swallowing the attempt silently — the
## tiles not travelled have to be reported, or callers cannot react to them.
func _check_push_into_map_edge() -> void:
	var unit := _make_unit(Vector2i(grid.grid_size.x - 1, 15))
	var result: Dictionary = CombatManager._displace_unit(
		unit, Vector2i(1, 0), 3, null)
	if result.get("moved", -1) != 0:
		_fail("edge push: moved %s, expected 0" % result.get("moved"))
	if result.get("lost", -1) != 3:
		_fail("edge push: lost %s, expected 3" % result.get("lost"))
	_cleanup([unit])
	_done()


func _check_push_into_unit() -> void:
	var pushed := _make_unit(Vector2i(20, 15))
	var blocker := _make_unit(Vector2i(22, 15))
	var result: Dictionary = CombatManager._displace_unit(
		pushed, Vector2i(1, 0), 3, null)
	if result.get("moved", -1) != 1:
		_fail("blocked push: moved %s, expected 1 (stops before the blocker)"
			% result.get("moved"))
	if result.get("lost", -1) != 2:
		_fail("blocked push: lost %s, expected 2" % result.get("lost"))
	if result.get("blocked_by") != blocker:
		_fail("blocked push: blocked_by was not the blocking unit")
	_cleanup([pushed, blocker])
	_done()


## A negative distance pulls instead of pushing, so one primitive serves both.
func _check_pull() -> void:
	var unit := _make_unit(Vector2i(20, 15))
	var result: Dictionary = CombatManager._displace_unit(
		unit, Vector2i(1, 0), -2, null)
	if unit.grid_position != Vector2i(18, 15):
		_fail("pull: ended at %s, expected (18, 15)" % unit.grid_position)
	if result.get("moved", -1) != 2:
		_fail("pull: moved %s, expected 2" % result.get("moved"))
	_cleanup([unit])
	_done()


## Juggernaut is immune to forced movement at 50%+ HP. The unit must not budge,
## and the attempt must report as fully lost rather than as a success.
func _check_push_immunity() -> void:
	var unit := _make_unit(Vector2i(20, 15))
	PerkSystem.grant_perk(unit.character_data, "juggernaut")
	var result: Dictionary = CombatManager._displace_unit(
		unit, Vector2i(1, 0), 2, null)
	if unit.grid_position != Vector2i(20, 15):
		_fail("immune push: unit moved to %s" % unit.grid_position)
	if result.get("moved", -1) != 0:
		_fail("immune push: moved %s, expected 0" % result.get("moved"))
	if not result.get("immune", false):
		_fail("immune push: result did not report immunity")
	_cleanup([unit])
	_done()


## Overwhelming Blow: "pushes the enemy 1 tile. If they can't be pushed (wall,
## another unit), they take +25% damage instead." The primitive reports lost
## tiles; _apply_push turns the effect's own declaration into a damage bonus.
func _check_apply_push_blocked_damage() -> void:
	var source := _make_unit(Vector2i(19, 15), 0)
	var clear_target := _make_unit(Vector2i(20, 15))
	var push := {"tiles": 1, "blocked_damage_bonus_pct": 25}

	var moved_result: Dictionary = CombatManager._apply_push(source, clear_target, push)
	if moved_result.get("damage_bonus_pct", -1) != 0:
		_fail("unblocked push granted damage bonus %s, expected 0"
			% moved_result.get("damage_bonus_pct"))

	var blocked_target := _make_unit(Vector2i(30, 15))
	var wall := _make_unit(Vector2i(31, 15))
	var blocked_result: Dictionary = CombatManager._apply_push(
		source, blocked_target, push)
	if blocked_result.get("damage_bonus_pct", -1) != 25:
		_fail("blocked push granted damage bonus %s, expected 25"
			% blocked_result.get("damage_bonus_pct"))

	_cleanup([source, clear_target, blocked_target, wall])
	_done()


## The falloff function and the tile lookup have to agree on which `aoe` block
## they are talking about, or a skill highlights one shape and damages another.
## Both read it through _skill_aoe_block(), so this checks the pair together
## rather than either alone.
func _check_skill_aoe_falloff_integration() -> void:
	var attacker := _make_unit(Vector2i(5, 5), 0)
	var near := _make_unit(Vector2i(6, 5))
	var far := _make_unit(Vector2i(7, 5))

	var combat_data := {
		"effect": "aoe_attack", "targeting": "aoe_point", "range": 2,
		"aoe": {"type": "line", "size": 2, "width": 1,
			"origin": "caster", "falloff": [100, 60]},
	}
	var aoe: Dictionary = CombatManager._skill_aoe_block(combat_data)
	var hit: Array = CombatManager._units_in_skill_aoe(
		attacker, combat_data, Vector2i(6, 5), 1)

	if hit.size() != 2:
		_fail("line aoe covered %d units, expected 2" % hit.size())
	for unit in hit:
		var mult: float = AoEResolver.falloff_at(
			aoe, attacker.grid_position, Vector2i(6, 5), unit.grid_position)
		var expected: float = 1.0 if unit == near else 0.6
		_expect_near(mult, expected, "falloff for unit at %s" % unit.grid_position)

	_cleanup([attacker, near, far])
	_done()


# ── Body plans ───────────────────────────────────────────────────────────────

## A four-armed body's extra arms hold only what is in hand_l2/hand_r2 — there
## is no weapon slot for a third or fourth hand. Severing arm_l2 must clear that
## slot (the item goes back to the inventory, not into the void), and must not
## touch the weapon the primary arm is holding.
func _check_severing_an_extra_arm() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["body_plan"] = {"species": "four_armed", "missing_parts": [], "prosthetics": {}}
	var glove_id: String = _first_item_of_type("gloves")
	var blade_id: String = _first_item_of_type("sword")
	if glove_id == "" or blade_id == "":
		_fail("sever: items.json has no gloves or sword to test with")
		_done()
		return
	# Equip directly: equip_item() only offers hand_l/hand_r for gloves, so
	# the extra hand slots are written the way a save or cheat would.
	c["equipment"]["hand_l2"] = glove_id
	c["equipment"]["weapon_set_1"]["main"] = blade_id
	var gloves_before: int = ItemSystem.get_inventory_count(glove_id)

	var severed: Array[String] = BodySystem.sever_part(c, "arm_l2")

	if severed != ["arm_l2"]:
		_fail("sever arm_l2: severed %s, expected only arm_l2" % [severed])
	if String(c["equipment"].get("hand_l2", "")) != "":
		_fail("sever arm_l2: hand_l2 still holds '%s'" % c["equipment"]["hand_l2"])
	if ItemSystem.get_inventory_count(glove_id) != gloves_before + 1:
		_fail("sever arm_l2: the glove did not go back to the inventory")
	if String(c["equipment"]["weapon_set_1"]["main"]) != blade_id:
		_fail("sever arm_l2: the main-hand weapon was dropped too")
	if BodySystem.get_attack_arm_count(c) != 3:
		_fail("sever arm_l2: %d arms still attack, expected 3"
			% BodySystem.get_attack_arm_count(c))

	# And the primary arm still drops its weapon, from inside the weapon set.
	BodySystem.sever_part(c, "arm_r")
	if String(c["equipment"]["weapon_set_1"]["main"]) != "":
		_fail("sever arm_r: weapon_set_1.main still holds '%s'"
			% c["equipment"]["weapon_set_1"]["main"])
	if c["equipment"].has("weapon_main"):
		_fail("sever arm_r: wrote a stray top-level weapon_main key")

	# Put the shared inventory back the way we found it.
	ItemSystem.remove_from_inventory(glove_id, 1)
	ItemSystem.remove_from_inventory(blade_id, 1)
	_done()


func _first_item_of_type(item_type: String) -> String:
	for item_id in ItemSystem._item_database:
		if String(item_id).begins_with("_"):
			continue
		if ItemSystem._item_database[item_id].get("type", "") == item_type:
			return String(item_id)
	return ""


# ── The skeleton king's duel ─────────────────────────────────────────────────

## Build the king exactly the way the event does — event outcome →
## combat_requested → combat_arena → EnemySystem.generate_encounter with
## difficulty "boss" → CombatUnit.init_as_enemy — and return the unit.
func _make_duel_king() -> CombatUnit:
	var defs: Array[Dictionary] = EnemySystem.generate_encounter(
		"skeleton_king_duel", "", "hungry_ghost", "boss")
	if defs.size() != 1:
		_fail("duel: encounter built %d enemies, expected 1" % defs.size())
		return null
	var king := CombatUnit.new()
	add_child(king)
	king.init_as_enemy(defs[0])
	king.grid_position = Vector2i(25, 20)
	grid.unit_positions[king.grid_position] = king
	CombatManager.all_units.append(king)
	return king


## The threshold travels from the archetype onto the built enemy, and is
## measured against the HP the unit actually has. "difficulty: boss" scales the
## XP budget the king is BUILT from (encounter_budgets.json), never HP after the
## build, so the unit's max_hp must be the built max_hp — if a multiplier ever
## lands after the build, this catches the threshold reading the wrong maximum.
func _check_duel_stop_survives_the_encounter_build() -> void:
	var king := _make_duel_king()
	if king == null:
		_done()
		return
	var hero := _make_unit(Vector2i(24, 20), CombatManager.Team.PLAYER)

	if int(king.character_data.get("duel_stop_hp_pct", 0)) != 10:
		_fail("duel: built king carries duel_stop_hp_pct %s, expected 10"
			% king.character_data.get("duel_stop_hp_pct"))
	if king.max_hp != int(king.character_data.get("max_hp", -1)):
		_fail("duel: unit max_hp %d differs from the built max_hp %s"
			% [king.max_hp, king.character_data.get("max_hp")])

	# Just above 10%: the fight goes on.
	king.current_hp = king.max_hp / 10 + 1
	if CombatManager._check_combat_end() != -1:
		_fail("duel: combat ended with the king at %d/%d (above 10%%)"
			% [king.current_hp, king.max_hp])
	# At 10%: he yields, and it counts as the party's victory.
	king.current_hp = king.max_hp / 10
	if CombatManager._check_combat_end() != CombatManager.Team.PLAYER:
		_fail("duel: king at %d/%d did not yield as a player victory"
			% [king.current_hp, king.max_hp])

	_cleanup([king, hero])
	_done()


## The yield happens on the blow that crosses the threshold. Before this was
## checked, _check_combat_end ran only on a death or at the start of a round,
## so the king fought on below 10% and could simply be killed.
func _check_duel_ends_the_moment_the_boss_yields() -> void:
	var king := _make_duel_king()
	if king == null:
		_done()
		return
	var hero := _make_unit(Vector2i(24, 20), CombatManager.Team.PLAYER)
	king.resistances = {}  # so the blow lands at exactly the size we ask for

	var outcome: Array[bool] = []
	var on_end := func(victory: bool) -> void: outcome.append(victory)
	CombatManager.combat_ended.connect(on_end)
	CombatManager.combat_active = true

	# Take him from full to 5% in one blow, well short of killing him.
	var blow: int = king.max_hp - king.max_hp / 20
	CombatManager.apply_damage(king, blow, "fire")
	if not king.is_alive():
		_fail("duel: the test blow killed the king outright (hp %d/%d)"
			% [king.current_hp, king.max_hp])
	# end_combat is deferred so the current action can finish logging.
	await get_tree().process_frame

	if outcome.is_empty():
		_fail("duel: dropping the king to %d/%d did not end the combat"
			% [king.current_hp, king.max_hp])
	elif not outcome[0]:
		_fail("duel: the king yielding ended the combat as a defeat")

	CombatManager.combat_ended.disconnect(on_end)
	CombatManager.combat_active = false
	CombatManager.combat_grid = grid
	_cleanup([king, hero])
	_done()
