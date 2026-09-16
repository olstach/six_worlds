extends Node
## Headless verification for skills that put something on the ground.
##
## Run: godot --headless res://tools/verify_terrain_skills.tscn
##
## Nine active perks wanted this and none could have it. What was missing was
## never the grid — `set_tile_obstacle`, `add_terrain_effect` and zones all
## existed — but a resolver that reads what a perk wants to place, a DURATION
## for the things that should not be permanent, and a way for two zones to know
## about each other.
##
## Every check drives `use_active_skill` with the perk's own data, so what is
## verified is the path the game actually takes.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 16
var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(40, 40), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid

	_check_a_zone_goes_where_it_was_aimed()
	_check_the_ground_underneath_is_marked_too()
	_check_a_wall_blocks_the_line_it_was_raised_across()
	_check_what_was_built_falls_down_again()
	_check_only_your_own_wall_comes_down()
	_check_an_avalanche_hurts_whoever_stood_by_it()
	_check_a_circle_makes_casting_cheaper_where_it_lies()
	_check_a_gate_puts_you_out_of_its_far_end()
	_check_a_gate_with_a_blocked_exit_keeps_you()

	# The small ones, each its own missing resolver.
	_check_a_medic_heals_somebody_else()
	_check_a_trap_waits_for_somebody_to_step_on_it()
	_check_a_mass_teleport_moves_one_side_only()
	_check_a_guard_takes_the_blow_meant_for_another()
	_check_one_spell_can_answer_to_no_resistance()
	_check_a_thief_steps_around_a_trap()
	_check_gear_can_refuse_a_status()

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


func _make_unit(at: Vector2i, team: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["attributes"]["focus"] = 20
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 100000
	unit.current_hp = 100000
	unit.current_mana = 500
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()
	CombatManager.active_zones.clear()
	CombatManager._timed_obstacles.clear()
	CombatManager._guarded.clear()
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	# A fresh field between checks. These skills leave things ON THE GROUND —
	# smoke, walls, ice — and the fog laid down by one check blocked the line
	# of sight another one needed, which read as "nobody to move".
	grid.setup_from_map({"size": Vector2i(40, 40), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})


## Use `perk_id` as its own data says to, from `user`, aimed at `at`.
func _use(user: CombatUnit, perk_id: String, at: Vector2i) -> Dictionary:
	var data: Dictionary = PerkSystem.get_perk_data(perk_id)
	if data.is_empty():
		_fail("%s is not in perks.json" % perk_id)
		return {}
	var skill_data: Dictionary = data.duplicate(true)
	skill_data["id"] = perk_id
	user.actions_remaining = 9
	user.current_stamina = 50
	user.current_mana = 500
	CombatManager.turn_order = [user]
	CombatManager.current_unit_index = 0
	return CombatManager.use_active_skill(user, skill_data, at)


func _check_a_zone_goes_where_it_was_aimed() -> void:
	var mage := _make_unit(Vector2i(10, 10), 0)
	var at := Vector2i(13, 10)
	var result: Dictionary = _use(mage, "gravity_well", at)
	if not bool(result.get("success", false)):
		_fail("gravity_well failed: %s" % str(result.get("reason", "?")))
	elif CombatManager.zones_at(at).is_empty():
		_fail("gravity_well left no zone where it was aimed")
	elif not CombatManager.zones_at(Vector2i(30, 30)).is_empty():
		_fail("the well covers ground twenty tiles from where it was aimed")

	# And it does what it says to whoever stands in it.
	var caught := _make_unit(at, 1)
	var free := _make_unit(Vector2i(30, 30), 1)
	if caught.get_movement() >= free.get_movement():
		_fail("a unit in the gravity well moves %d where a free one moves %d"
			% [caught.get_movement(), free.get_movement()])
	if caught.get_dodge() >= free.get_dodge():
		_fail("the well did not cost the unit in it any dodge")
	# The caster's own side is not slowed by their own well.
	var ally := _make_unit(Vector2i(13, 11), 0)
	if ally.get_movement() != free.get_movement():
		_fail("the well slowed the caster's own ally")
	_cleanup([mage, caught, free, ally])
	_done()


## Fog is two things: a zone that blinds and a terrain effect that blocks
## sight. Line of sight is the grid's business, not a payload's.
func _check_the_ground_underneath_is_marked_too() -> void:
	var mage := _make_unit(Vector2i(10, 10), 0)
	var at := Vector2i(13, 10)
	_use(mage, "fog_of_war", at)
	var terrain: Dictionary = grid.get_terrain_effect(at)
	if terrain.is_empty():
		_fail("fog_of_war left no terrain effect on the tile it covered")
	elif int(terrain.get("effect", -1)) != CombatGrid.TerrainEffect.SMOKE:
		_fail("fog_of_war laid down effect %s, not smoke" % str(terrain.get("effect")))
	# And the zone above it blinds the enemy standing there.
	var blinded := _make_unit(at, 1)
	var clear := _make_unit(Vector2i(30, 30), 1)
	if blinded.get_accuracy() >= clear.get_accuracy():
		_fail("a unit in the fog aims as well as one outside it (%d vs %d)"
			% [blinded.get_accuracy(), clear.get_accuracy()])
	_cleanup([mage, blinded, clear])
	_done()


func _check_a_wall_blocks_the_line_it_was_raised_across() -> void:
	var mage := _make_unit(Vector2i(10, 10), 0)
	var at := Vector2i(14, 10)
	var result: Dictionary = _use(mage, "raise_wall", at)
	if not bool(result.get("success", false)):
		_fail("raise_wall failed: %s" % str(result.get("reason", "?")))

	var built := 0
	for entry in CombatManager._timed_obstacles:
		if grid.has_blocking_obstacle(entry.pos):
			built += 1
	if built < 3:
		_fail("a three-tile wall went up as %d blocking tiles" % built)
	# Across the line of approach, not along it: the tile aimed at and its
	# neighbours perpendicular to the caster.
	if not grid.has_blocking_obstacle(at):
		_fail("the wall does not cover the tile it was aimed at")
	if not (grid.has_blocking_obstacle(at + Vector2i(0, 1))
			or grid.has_blocking_obstacle(at + Vector2i(0, -1))):
		_fail("the wall runs along the caster's line rather than across it")
	_cleanup([mage])
	_done()


## The grid's own obstacles are permanent, and should be. These are the ones
## somebody built during a fight, and they come down again.
func _check_what_was_built_falls_down_again() -> void:
	var smith := _make_unit(Vector2i(10, 10), 0)
	var at := Vector2i(11, 10)
	_use(smith, "improvised_barricade", at)
	if grid.get_obstacle_at(at).is_empty():
		_fail("improvised_barricade built nothing")
	var duration: int = int(PerkSystem.get_perk_data("improvised_barricade")
		.get("combat_data", {}).get("places", [{}])[0].get("duration", 3))
	for _round in duration:
		if grid.get_obstacle_at(at).is_empty():
			_fail("the barricade fell down before its %d rounds were up" % duration)
			break
		CombatManager._tick_placed_obstacles()
	if not grid.get_obstacle_at(at).is_empty():
		_fail("the barricade was still standing after %d rounds" % duration)
	_cleanup([smith])
	_done()


func _check_only_your_own_wall_comes_down() -> void:
	var earth_mage := _make_unit(Vector2i(10, 10), 0)
	var stranger := _make_unit(Vector2i(20, 20), 1)

	# A tree that was always there, right beside the caster.
	grid.set_tile_obstacle(Vector2i(11, 10), CombatGrid.ObstacleType.TREE, 30)
	var result: Dictionary = _use(earth_mage, "crumbling_avalanche", Vector2i(11, 10))
	if bool(result.get("success", false)):
		_fail("Crumbling Avalanche brought down a tree the caster never raised")
	if grid.get_obstacle_at(Vector2i(11, 10)).is_empty():
		_fail("the tree came down anyway")

	# Somebody else's wall is not yours either.
	_use(stranger, "raise_wall", Vector2i(20, 18))
	var before: int = CombatManager._timed_obstacles.size()
	var second: Dictionary = _use(earth_mage, "crumbling_avalanche", Vector2i(20, 18))
	if bool(second.get("success", false)):
		_fail("Crumbling Avalanche brought down a wall somebody else raised")
	if CombatManager._timed_obstacles.size() != before:
		_fail("somebody else's wall came down anyway")
	grid.remove_obstacle(Vector2i(11, 10))
	_cleanup([earth_mage, stranger])
	_done()


func _check_an_avalanche_hurts_whoever_stood_by_it() -> void:
	var earth_mage := _make_unit(Vector2i(10, 10), 0)
	_use(earth_mage, "raise_wall", Vector2i(13, 10))
	var wall_at: Vector2i = CombatManager._timed_obstacles[0].pos

	var near := _make_unit(wall_at + Vector2i(1, 0), 1)
	var far := _make_unit(Vector2i(30, 30), 1)
	var ally := _make_unit(wall_at + Vector2i(-1, 0), 0)
	near.current_hp = near.max_hp
	far.current_hp = far.max_hp
	ally.current_hp = ally.max_hp

	var walls_before: int = CombatManager._timed_obstacles.size()
	var result: Dictionary = _use(earth_mage, "crumbling_avalanche", wall_at)
	if not bool(result.get("success", false)):
		_fail("Crumbling Avalanche failed on the caster's own wall: %s"
			% str(result.get("reason", "?")))
	if CombatManager._timed_obstacles.size() >= walls_before:
		_fail("the avalanche did not bring the wall down")
	if near.current_hp >= near.max_hp:
		_fail("an enemy beside the collapsing wall took nothing")
	if far.current_hp < far.max_hp:
		_fail("an enemy thirty tiles away was caught in the avalanche")
	if ally.current_hp < ally.max_hp:
		_fail("the caster's own ally was caught in it")
	_cleanup([earth_mage, near, far, ally])
	_done()


## The circle discounts whoever STANDS in it, not whoever drew it.
func _check_a_circle_makes_casting_cheaper_where_it_lies() -> void:
	var ritualist := _make_unit(Vector2i(10, 10), 0)
	ritualist.character_data["skills"] = {"ritual": 9, "fire_magic": 9, "sorcery": 9}
	CharacterSystem.update_derived_stats(ritualist.character_data)
	var outsider := _make_unit(Vector2i(30, 30), 0)
	outsider.character_data["skills"] = {"ritual": 9, "fire_magic": 9, "sorcery": 9}
	CharacterSystem.update_derived_stats(outsider.character_data)

	_use(ritualist, "inscribed_circle", ritualist.grid_position)
	if CombatManager.zones_at(ritualist.grid_position).is_empty():
		_fail("inscribed_circle drew no circle on the caster's own tile")

	var spell_id := "firebolt"
	var target := _make_unit(Vector2i(11, 10), 1)
	var far_target := _make_unit(Vector2i(31, 30), 1)

	var inside_cost: int = _cast_cost(ritualist, spell_id, target.grid_position)
	var outside_cost: int = _cast_cost(outsider, spell_id, far_target.grid_position)
	if inside_cost <= 0 or outside_cost <= 0:
		_fail("could not measure a cast cost (inside %d, outside %d)"
			% [inside_cost, outside_cost])
	elif inside_cost >= outside_cost:
		_fail("casting inside the circle cost %d and outside cost %d"
			% [inside_cost, outside_cost])
	_cleanup([ritualist, outsider, target, far_target])
	_done()


## The mana a cast actually took.
func _cast_cost(caster: CombatUnit, spell_id: String, at: Vector2i) -> int:
	caster.current_mana = 500
	caster.actions_remaining = 9
	CombatManager.turn_order = [caster]
	CombatManager.current_unit_index = 0
	var before: int = caster.current_mana
	var result: Dictionary = CombatManager.cast_spell(caster, spell_id, at)
	if not bool(result.get("success", false)):
		return -1
	return before - caster.current_mana


func _check_a_gate_puts_you_out_of_its_far_end() -> void:
	var mage := _make_unit(Vector2i(10, 10), 0)
	var far := Vector2i(20, 10)
	var result: Dictionary = _use(mage, "the_door_stands_open", far)
	if not bool(result.get("success", false)):
		_fail("the_door_stands_open failed: %s" % str(result.get("reason", "?")))
	if CombatManager.zones_at(Vector2i(10, 10)).is_empty() \
			or CombatManager.zones_at(far).is_empty():
		_fail("a gate went down with fewer than two ends")

	# Somebody else steps onto the near end and comes out of the far one.
	var traveller := _make_unit(Vector2i(9, 10), 1)
	traveller.grid_position = Vector2i(10, 11)
	CombatManager._zones_check_entry(traveller)   # not on the gate: nothing
	if traveller.grid_position != Vector2i(10, 11):
		_fail("a unit was moved by a gate it never stepped on")
	# The caster stands on the near end; step the traveller onto the far end's
	# twin by walking onto the tile the gate occupies.
	grid.remove_unit(mage)
	mage.grid_position = Vector2i(9, 9)
	traveller.grid_position = Vector2i(10, 10)
	CombatManager._zones_check_entry(traveller)
	if traveller.grid_position != far:
		_fail("stepping onto one end of the gate left the traveller at %s, "
			% str(traveller.grid_position) + "not at the far end %s" % str(far))
	_cleanup([mage, traveller])
	_done()


## A gate whose far end is occupied puts you on a free tile of it, and keeps
## you where you are when it has none.
func _check_a_gate_with_a_blocked_exit_keeps_you() -> void:
	# A two-tile far end, one tile of it taken. The traveller should come out
	# on the other one rather than bouncing: CombatGrid refuses a move onto an
	# occupied tile, so a gate that did not look would simply fail.
	var mage := _make_unit(Vector2i(10, 10), 0)
	var blocked := Vector2i(20, 10)
	var free := Vector2i(20, 11)
	CombatManager.place_gate("open_door", [Vector2i(10, 10)], [blocked, free], mage, 3)
	var blocker := _make_unit(blocked, 1)
	var traveller := _make_unit(Vector2i(9, 10), 1)

	grid.remove_unit(mage)
	mage.grid_position = Vector2i(9, 9)
	traveller.grid_position = Vector2i(10, 10)
	CombatManager._zones_check_entry(traveller)
	if traveller.grid_position == blocked:
		_fail("the traveller came out on top of the unit standing there")
	elif traveller.grid_position != free:
		_fail("the traveller ended at %s, not on the free tile of the far end"
			% str(traveller.grid_position))
	if blocker.grid_position != blocked:
		_fail("the blocker was pushed off the far end")

	# And a far end with no room at all keeps the traveller where they are.
	CombatManager.active_zones.clear()
	var walled := _make_unit(Vector2i(25, 25), 1)
	CombatManager.place_gate("open_door", [Vector2i(15, 15)], [Vector2i(25, 25)], mage, 3)
	var second := _make_unit(Vector2i(14, 15), 1)
	second.grid_position = Vector2i(15, 15)
	CombatManager._zones_check_entry(second)
	if second.grid_position != Vector2i(15, 15):
		_fail("a gate with nowhere to put anybody moved the traveller to %s"
			% str(second.grid_position))
	_cleanup([mage, blocker, traveller, walled, second])
	_done()


## `_resolve_heal_self` ignored its own `targeting` and always healed the user,
## so Field Medic — "heal an ADJACENT ALLY" — healed the medic.
func _check_a_medic_heals_somebody_else() -> void:
	var medic := _make_unit(Vector2i(10, 10), 0)
	var hurt := _make_unit(Vector2i(11, 10), 0)
	var distant := _make_unit(Vector2i(20, 20), 0)
	medic.current_hp = medic.max_hp - 400
	hurt.current_hp = hurt.max_hp - 400
	distant.current_hp = distant.max_hp - 400

	var result: Dictionary = _use(medic, "field_medic", hurt.grid_position)
	if not bool(result.get("success", false)):
		_fail("field_medic failed: %s" % str(result.get("reason", "?")))
	elif hurt.current_hp <= hurt.max_hp - 400:
		_fail("the ally the medic was aimed at was not healed")
	if medic.current_hp != medic.max_hp - 400:
		_fail("the medic healed themselves instead of the ally beside them")

	# Out of reach is out of reach.
	var far_result: Dictionary = _use(medic, "field_medic", distant.grid_position)
	if bool(far_result.get("success", false)):
		_fail("field_medic reached an ally ten tiles away")
	# And it is for allies.
	var foe := _make_unit(Vector2i(9, 10), 1)
	foe.current_hp = foe.max_hp - 400
	if bool(_use(medic, "field_medic", foe.grid_position).get("success", false)):
		_fail("field_medic patched up an enemy")
	_cleanup([medic, hurt, distant, foe])
	_done()


## A trap is a zone that waits: nothing happens until somebody steps on it,
## which is the one thing an aura could never do.
func _check_a_trap_waits_for_somebody_to_step_on_it() -> void:
	var trapper := _make_unit(Vector2i(10, 10), 0)
	var at := Vector2i(11, 10)
	var result: Dictionary = _use(trapper, "trap_maker", at)
	if not bool(result.get("success", false)):
		_fail("trap_maker failed: %s" % str(result.get("reason", "?")))
	elif CombatManager.zones_at(at).is_empty():
		_fail("trap_maker left nothing on the tile")

	# Nothing happens to the trapper standing beside it.
	CombatManager._tick_zones()
	if trapper.current_hp < trapper.max_hp:
		_fail("the trap went off on its own")

	# It goes off when somebody arrives.
	var victim := _make_unit(Vector2i(12, 10), 1)
	victim.current_hp = victim.max_hp
	victim.grid_position = at
	CombatManager._zones_check_entry(victim)
	if victim.current_hp >= victim.max_hp:
		_fail("an enemy stepped onto the trap and nothing happened")
	if not victim.has_status("Immobilized"):
		_fail("the trap hurt the enemy but did not hold them")

	# And not on your own people.
	var ally := _make_unit(Vector2i(9, 9), 0)
	ally.current_hp = ally.max_hp
	ally.grid_position = at
	CombatManager._zones_check_entry(ally)
	if ally.current_hp < ally.max_hp:
		_fail("the trapper's own trap caught their ally — you know where you "
			+ "put it")
	_cleanup([trapper, victim, ally])
	_done()


func _check_a_mass_teleport_moves_one_side_only() -> void:
	var mage := _make_unit(Vector2i(10, 10), 0)
	var foe_a := _make_unit(Vector2i(13, 10), 1)
	var foe_b := _make_unit(Vector2i(14, 11), 1)
	var ally := _make_unit(Vector2i(11, 11), 0)
	var before := {foe_a: foe_a.grid_position, foe_b: foe_b.grid_position,
		ally: ally.grid_position}

	var result: Dictionary = _use(mage, "everyone_is_somewhere_else_now", Vector2i(20, 20))
	if not bool(result.get("success", false)):
		_fail("everyone_is_somewhere_else_now failed: %s" % str(result.get("reason", "?")))
	var moved := 0
	for unit in [foe_a, foe_b]:
		if unit.grid_position != before[unit]:
			moved += 1
	if moved == 0:
		_fail("nobody moved")
	if ally.grid_position != before[ally]:
		_fail("the caster's own ally was scattered by a spell aimed at enemies")
	if mage.grid_position != Vector2i(10, 10):
		_fail("the caster moved themselves")
	_cleanup([mage, foe_a, foe_b, ally])
	_done()


## Standing in front of somebody: the blow is aimed at the ward and lands on
## the guard.
func _check_a_guard_takes_the_blow_meant_for_another() -> void:
	# The guard stands where the blow could have found them anyway — beside
	# both the ward and the attacker. Stepping in front of somebody from across
	# the field is not stepping in front of them.
	var guard := _make_unit(Vector2i(11, 11), 0)
	var ward := _make_unit(Vector2i(11, 10), 0)
	var attacker := _make_unit(Vector2i(12, 10), 1)
	guard.character_data["derived"]["accuracy"] = 999
	attacker.character_data["derived"]["accuracy"] = 999
	ward.character_data["derived"]["dodge"] = 0

	var result: Dictionary = _use(guard, "stalwart_guardian", ward.grid_position)
	if not bool(result.get("success", false)):
		_fail("stalwart_guardian failed: %s" % str(result.get("reason", "?")))
	if not guard.has_status("Guarding"):
		_fail("the guard did not take up the stance's own status")

	# Over enough swings, some land on the guard instead of the ward.
	var took_it := 0
	for _swing in 40:
		guard.current_hp = guard.max_hp
		ward.current_hp = ward.max_hp
		attacker.actions_remaining = 9
		CombatManager.turn_order = [attacker]
		CombatManager.current_unit_index = 0
		CombatManager.attack_unit(attacker, ward)
		if guard.current_hp < guard.max_hp:
			took_it += 1
	if took_it == 0:
		_fail("forty blows aimed at the ward and the guard took none of them")
	# A 50% redirect against 95%-capped hits lands about nineteen of forty on
	# the guard; an always-redirect lands about thirty-eight. Thirty is a wide
	# gap between those two, and the point is that the roll is a roll.
	if took_it >= 30:
		_fail("the guard took %d of forty blows — a 50%% redirect is not being "
			% took_it + "rolled")

	# And a guard who is nowhere near the attacker cannot step in front of
	# anything: standing over somebody means standing where the blow was going.
	# Beside the ward — so the guarding itself is legal — but two tiles from
	# the attacker, which is further than the blow can reach.
	var distant := _make_unit(Vector2i(10, 10), 0)
	distant.character_data["derived"]["accuracy"] = 999
	var took_up: Dictionary = _use(distant, "stalwart_guardian", ward.grid_position)
	if not bool(took_up.get("success", false)):
		_fail("the second guard could not take up the watch: %s"
			% str(took_up.get("reason", "?")))
	var distant_took := 0
	var ward_took := 0
	for _swing in 20:
		distant.current_hp = distant.max_hp
		ward.current_hp = ward.max_hp
		attacker.actions_remaining = 9
		CombatManager.turn_order = [attacker]
		CombatManager.current_unit_index = 0
		CombatManager.attack_unit(attacker, ward)
		if distant.current_hp < distant.max_hp:
			distant_took += 1
		if ward.current_hp < ward.max_hp:
			ward_took += 1
	if distant_took > 0:
		_fail("a guard three tiles from the attacker took %d blows meant for "
			% distant_took + "somebody standing next to them")
	# And the blow still lands on the ward. A redirect to somebody the attacker
	# cannot reach would have the attack refused outright, so the ward would be
	# protected by a guard who never arrived.
	# Nearly all of them land on the ward: 95%-capped hits, and no redirect.
	# A redirect to somebody the attacker cannot reach has the attack refused
	# outright, so half the swings would land on nobody at all and the ward
	# would be protected by a guard who never arrived.
	if ward_took < 15:
		_fail("only %d of twenty blows at the ward landed — the rest were " % ward_took
			+ "redirected to a guard who could not be reached, and hit nobody")
	_cleanup([guard, ward, attacker, distant])
	_done()


## Too Fast to React: one spell that answers to nothing, and only one.
func _check_one_spell_can_answer_to_no_resistance() -> void:
	var sorcerer := _make_unit(Vector2i(10, 10), 0)
	sorcerer.character_data["skills"] = {"sorcery": 9, "fire_magic": 9}
	CharacterSystem.update_derived_stats(sorcerer.character_data)
	var fireproof := _make_unit(Vector2i(11, 10), 1)
	fireproof.resistances = {"fire": 100}

	# Ordinarily, immune is immune.
	fireproof.current_hp = fireproof.max_hp
	_cast(sorcerer, "firebolt", fireproof.grid_position)
	if fireproof.current_hp < fireproof.max_hp:
		_fail("a fire-immune unit took fire damage with no perk in play")

	_use(sorcerer, "too_fast_to_react", sorcerer.grid_position)
	fireproof.current_hp = fireproof.max_hp
	_cast(sorcerer, "firebolt", fireproof.grid_position)
	if fireproof.current_hp >= fireproof.max_hp:
		_fail("the spell that answers to nothing was still turned by immunity")

	# And only the one.
	fireproof.current_hp = fireproof.max_hp
	_cast(sorcerer, "firebolt", fireproof.grid_position)
	if fireproof.current_hp < fireproof.max_hp:
		_fail("the next spell ignored resistance too — the flag is not being "
			+ "spent")
	_cleanup([sorcerer, fireproof])
	_done()


func _cast(caster: CombatUnit, spell_id: String, at: Vector2i) -> void:
	caster.current_mana = 500
	caster.actions_remaining = 9
	CombatManager.turn_order = [caster]
	CombatManager.current_unit_index = 0
	CombatManager.cast_spell(caster, spell_id, at)


## Thievery's `trap_detection_pct` was written into derived stats for months
## and read by nothing, because until Trap Maker there were no traps.
func _check_a_thief_steps_around_a_trap() -> void:
	var trapper := _make_unit(Vector2i(10, 10), 0)
	var thief := _make_unit(Vector2i(20, 20), 1)
	var oaf := _make_unit(Vector2i(22, 22), 1)
	thief.character_data["skills"] = {"thievery": 10}
	CharacterSystem.update_derived_stats(thief.character_data)
	if float(thief.character_data.derived.get("trap_detection_pct", 0.0)) <= 0.0:
		_fail("Thievery 10 produced no trap_detection_pct")

	var at := Vector2i(11, 10)
	var thief_caught := 0
	var oaf_caught := 0
	for _try in 30:
		for probe in [thief, oaf]:
			CombatManager.active_zones.clear()
			_use(trapper, "trap_maker", at)
			probe.current_hp = probe.max_hp
			probe.status_effects.clear()
			probe.grid_position = Vector2i(12, 12)
			probe.grid_position = at
			CombatManager._zones_check_entry(probe)
			if probe.current_hp < probe.max_hp:
				if probe == thief:
					thief_caught += 1
				else:
					oaf_caught += 1
	if oaf_caught == 0:
		_fail("thirty traps and the untrained probe walked into none of them")
	if thief_caught >= oaf_caught:
		_fail("a master thief triggered %d traps where an untrained unit "
			% thief_caught + "triggered %d" % oaf_caught)

	# And it is a roll, not a rule: over two hundred snares a master thief
	# walks into some of them, and an untrained one into all.
	var spotted := 0
	for _roll in 200:
		if CombatManager._steps_around_trap(thief):
			spotted += 1
	if spotted == 200:
		_fail("a master thief spotted all two hundred traps — detection is not "
			+ "being rolled")
	if spotted < 100:
		_fail("a master thief spotted only %d of two hundred traps" % spotted)
	for _roll in 50:
		if CombatManager._steps_around_trap(oaf):
			_fail("an untrained unit spotted a trap")
			break
	_cleanup([trapper, thief, oaf])
	_done()


## An item may declare `passive.status_immunity`, and the ITEM names the status
## rather than the code naming the item. Smoked Glass Lenses promised this in a
## `todo` key for months.
func _check_gear_can_refuse_a_status() -> void:
	var bare := _make_unit(Vector2i(10, 10), 0)
	var shaded := _make_unit(Vector2i(11, 10), 0)
	# Straight into the slot: equip_item() wants the thing in the inventory
	# first, and what is under test is the reader, not the shop.
	shaded.character_data["equipment"]["face"] = "smoked_lenses"

	CombatManager._apply_status_effect(bare, "Blinded", 3)
	CombatManager._apply_status_effect(shaded, "Blinded", 3)
	if not bare.has_status("Blinded"):
		_fail("a bare-eyed probe was not blinded, so the check below proves "
			+ "nothing")
	if shaded.has_status("Blinded"):
		_fail("the lenses did not stop the Blinded they name")

	# And only what they name.
	CombatManager._apply_status_effect(shaded, "Slowed", 3)
	if not shaded.has_status("Slowed"):
		_fail("the lenses stopped a status they never mention")
	_cleanup([bare, shaded])
	_done()
