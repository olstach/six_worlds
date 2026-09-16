extends Node
## Headless verification for reaction stances.
##
## Run: godot --headless res://tools/verify_reactions.tscn
##
## Six active perks waited on a mechanism that half-existed: movement
## reactions were hardcoded `if has_perk(...)` branches inside
## `_check_zoc_reactions`, and being-hit reactions were `retaliation` blocks
## that could deal damage, reflect a percentage or apply a status — but could
## not swing a weapon, which is what a counterstance is.
##
## Every check drives a real hook: a real attack, or a real move. A stance that
## is applied and never answers anything is the exact failure these replace.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 13
var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	# A real, empty, walkable field: move_unit() asks get_movement_range(),
	# which asks the grid, so a bare CombatGrid refuses every move and the
	# movement checks would pass by never moving anybody.
	grid.setup_from_map({"size": Vector2i(40, 40), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid

	_check_the_vocabulary_is_closed()
	_check_a_counterstance_answers_a_melee_blow()
	_check_a_counterstance_answers_each_attacker_once()
	_check_a_stance_without_the_status_answers_nothing()
	_check_a_brace_hits_harder_than_a_swing_of_opportunity()
	_check_a_kill_zone_reaches_as_far_as_the_weapon()
	_check_a_guard_answers_a_move_against_the_guarded()
	_check_a_reaction_budget_refills_on_your_turn()
	_check_a_counterflow_turns_the_blow_aside()
	_check_a_stance_spends_only_what_it_may()
	_check_an_unreachable_answer_keeps_its_allowance()
	_check_moving_inside_a_threatened_area_provokes_once()
	_check_the_perk_is_what_puts_the_stance_on()

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
	unit.character_data["skills"] = {"swords": 5}
	CharacterSystem.update_derived_stats(unit.character_data)
	# Every attack lands and nothing dodges. These checks are about whether a
	# reaction FIRES; leaving the attack rolls in makes them flaky, which is
	# how the first version passed alone and failed in the suite.
	unit.character_data["derived"]["accuracy"] = 999
	unit.character_data["derived"]["dodge"] = 0
	add_child(unit)
	unit.max_hp = 100000
	unit.current_hp = 100000
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


## Whose turn it is, because can_act() asks the CURRENT unit rather than the
## one being told to act — an attack by anybody else is refused before it
## starts, which is how the first draft of these checks passed nothing.
func _take_turn(unit: CombatUnit) -> void:
	unit.actions_remaining = 9
	CombatManager.turn_order = [unit]
	CombatManager.current_unit_index = 0


## How many times the reaction on `status_name` has fired since its holder's
## last turn. This is the deterministic signal: an attack roll can miss, a
## reaction firing cannot.
func _times_fired(unit: CombatUnit, status_name: String) -> int:
	for entry in unit.status_effects:
		if str(entry.get("status", "")) == status_name:
			return int(entry.get("_reactions_used", 0))
	return 0


## Strike `defender` once with a blow that actually lands, and report how many
## times their stance answered.
##
## Swings until one connects, because hit chance is capped at 95% and a missed
## blow reaches no reaction at all — which is correct, and makes a single swing
## a coin flip rather than a test.
func _strike(attacker: CombatUnit, defender: CombatUnit, status_name: String) -> int:
	_revive(attacker)
	_revive(defender)
	var before: int = _times_fired(defender, status_name)
	for _try in 20:
		_take_turn(attacker)
		var result: Dictionary = CombatManager.attack_unit(attacker, defender)
		if bool(result.get("hit", false)) or bool(result.get("dodged", false)):
			break
	return _times_fired(defender, status_name) - before


## Move `unit` to `to` as though on its own turn.
##
## Fails loudly when the move is refused. A refused move provokes nothing, so a
## check built on one passes whatever the code does — which is how two guard
## mutations survived this file.
func _walk(unit: CombatUnit, to: Vector2i) -> void:
	_take_turn(unit)
	_revive(unit)
	if to == unit.grid_position:
		return
	if not CombatManager.move_unit(unit, to) or unit.grid_position != to:
		var reachable: Array = CombatManager.get_movement_range(unit)
		_fail("a probe could not walk from %s to %s (movement %d, %d tiles "
			% [str(unit.grid_position), str(to), unit.get_movement(), reachable.size()]
			+ "reachable, target in range: %s), so whatever this check was "
			% str(to in reachable) + "about did not happen")


## Put `unit` on `pos` without walking, keeping the grid's own index in step —
## assigning grid_position alone leaves the grid believing the old tile is
## occupied, and the next move is quietly refused.
func _place(unit: CombatUnit, pos: Vector2i) -> void:
	CombatManager.combat_grid.unit_positions.erase(unit.grid_position)
	unit.grid_position = pos
	CombatManager.combat_grid.unit_positions[pos] = unit


## Walk `mover` from `start` to `to` until the stance on `holder` answers with
## a blow that lands, and report what it cost.
func _provoke(holder: CombatUnit, mover: CombatUnit, start: Vector2i,
		to: Vector2i, status_name: String) -> int:
	for _try in 20:
		_revive(mover)
		# None Shall Pass slows what it catches, and a slowed probe cannot walk
		# far enough to provoke the next one.
		mover.status_effects.clear()
		_place(mover, start)
		holder.status_effects.clear()
		CombatManager._apply_status_effect(holder, status_name, 1)
		_walk(mover, to)
		var hurt: int = mover.max_hp - mover.current_hp
		if hurt > 0:
			return hurt
	return 0


## Full HP and upright. A probe that died in an earlier exchange answers
## nothing and fails the next check for the wrong reason.
func _revive(unit: CombatUnit) -> void:
	unit.current_hp = unit.max_hp
	unit.is_dead = false
	unit.is_bleeding_out = false


func _check_the_vocabulary_is_closed() -> void:
	for status_name in CombatManager._status_effects:
		var spec: Dictionary = Reaction.of(CombatManager._status_effects[status_name])
		if spec.is_empty():
			continue
		if not Reaction.is_trigger(str(spec.get("trigger", ""))):
			_fail("status '%s' reacts to '%s', which nothing fires"
				% [status_name, str(spec.get("trigger", ""))])
		for response in spec.get("responses", []):
			if not Reaction.is_response(str(response)):
				_fail("status '%s' responds with '%s', which nothing performs"
					% [status_name, str(response)])
	# And the six stances the perks need all exist.
	for required in ["Counterstance", "Guarding_The_Gap", "Set_For_Charge",
			"Kill_Zone", "Heavenly_Counterflow", "None_Shall_Pass"]:
		if CombatManager.get_status_definition(required).is_empty():
			_fail("stance status '%s' does not exist" % required)
	_done()


func _check_a_counterstance_answers_a_melee_blow() -> void:
	var holder := _make_unit(Vector2i(10, 10), 0)
	var attacker := _make_unit(Vector2i(11, 10), 1)
	var bare := _make_unit(Vector2i(10, 12), 0)
	var other := _make_unit(Vector2i(11, 12), 1)

	CombatManager._apply_status_effect(holder, "Counterstance", 1)
	if _strike(attacker, holder, "Counterstance") != 1:
		_fail("striking a counterstance was not answered")
	if _times_fired(bare, "Counterstance") != 0:
		_fail("a unit with no stance answered a blow")
	_strike(other, bare, "Counterstance")
	if bare.status_effects.size() > 0:
		_fail("striking a bare unit gave it a stance")
	_cleanup([holder, attacker, bare, other])
	_done()


## "Once per attacker per round" — two swings from the same enemy are answered
## once; a second enemy is answered on its own account.
func _check_a_counterstance_answers_each_attacker_once() -> void:
	var holder := _make_unit(Vector2i(10, 10), 0)
	var first := _make_unit(Vector2i(11, 10), 1)
	var second := _make_unit(Vector2i(9, 10), 1)
	CombatManager._apply_status_effect(holder, "Counterstance", 1)

	if _strike(first, holder, "Counterstance") != 1:
		_fail("the first blow was not answered")
	if _strike(first, holder, "Counterstance") != 0:
		_fail("the same attacker was answered twice in one round")
	if _strike(second, holder, "Counterstance") != 1:
		_fail("a second attacker was not answered, though the budget is per "
			+ "attacker")
	_cleanup([holder, first, second])
	_done()


## The stance is the status. Holding the perk without pressing the button
## answers nothing, which is what makes it a decision.
func _check_a_stance_without_the_status_answers_nothing() -> void:
	var holder := _make_unit(Vector2i(10, 10), 0)
	var attacker := _make_unit(Vector2i(11, 10), 1)
	holder.character_data["perks"] = ["counterstrike", "none_shall_pass"]
	var before: int = attacker.current_hp
	_revive(attacker)
	_take_turn(attacker)
	CombatManager.attack_unit(attacker, holder)
	if attacker.current_hp < attacker.max_hp:
		_fail("a unit that merely HAS Counterstrike answered a blow without "
			+ "spending the action to hold the stance")
	if holder.status_effects.size() > 0:
		_fail("a perk applied its stance without being used")
	_cleanup([holder, attacker])
	_done()


func _check_a_brace_hits_harder_than_a_swing_of_opportunity() -> void:
	var braced := _make_unit(Vector2i(10, 10), 0)
	var plain := _make_unit(Vector2i(10, 20), 0)
	CombatManager._apply_status_effect(braced, "Set_For_Charge", 1)
	CombatManager._apply_status_effect(plain, "None_Shall_Pass", 1)

	var charger := _make_unit(Vector2i(14, 10), 1)
	var walker := _make_unit(Vector2i(14, 20), 1)
	# Both stances threaten 2 tiles, but a free attack still has to be able to
	# REACH: these probes carry no spear, so they answer at 1. Walk in to 1,
	# and walk again until the reaction's own attack connects — the damage is
	# the point of this check, so a 95%-capped miss has to be retried rather
	# than counted.
	var braced_hit := 0
	var plain_hit := 0
	for _sample in 8:
		braced_hit += _provoke(braced, charger, Vector2i(14, 10), Vector2i(11, 10),
			"Set_For_Charge")
		plain_hit += _provoke(plain, walker, Vector2i(14, 20), Vector2i(11, 20),
			"None_Shall_Pass")
	if braced_hit <= 0 or plain_hit <= 0:
		_fail("a stance did not answer an enemy stepping into reach "
			+ "(braced %d, plain %d)" % [braced_hit, plain_hit])
	elif braced_hit < plain_hit * 3 / 2:
		_fail("over eight provocations a braced spear dealt %d where an "
			% braced_hit + "ordinary reaction dealt %d — the declared 2x is "
			% plain_hit + "not reaching the damage")
	# And None Shall Pass slows what it catches.
	if not walker.has_status("Slowed"):
		_fail("None Shall Pass let an enemy through without slowing it")

	# A charge that stops outside the threatened area is not answered, and the
	# stance keeps its allowance for whatever comes next.
	var distant := _make_unit(Vector2i(20, 30), 1)
	var sentry := _make_unit(Vector2i(10, 30), 0)
	CombatManager._apply_status_effect(sentry, "None_Shall_Pass", 1)
	_walk(distant, Vector2i(18, 30))
	if distant.current_hp < distant.max_hp:
		_fail("a stance answered an enemy eight tiles away")
	_cleanup([distant, sentry])
	_cleanup([braced, plain, charger, walker])
	_done()


## `reach: "weapon"` means everything you could have shot.
func _check_a_kill_zone_reaches_as_far_as_the_weapon() -> void:
	var archer := _make_unit(Vector2i(10, 10), 0)
	# A weapon that reaches further than a fist, or "reach: weapon" and
	# "reach: 1" are the same number and the check proves nothing.
	archer.character_data["equipped_weapon"] = {
		"name": "Probe Bow", "stats": {"range": 5, "damage": 6}}
	if archer.get_attack_range() != 5:
		_fail("the probe bow did not take: attack range is %d"
			% archer.get_attack_range())
	CombatManager._apply_status_effect(archer, "Kill_Zone", 1)
	var reach: int = Reaction.reach_of(
		Reaction.of(CombatManager.get_status_definition("Kill_Zone")), archer)
	if reach != archer.get_attack_range():
		_fail("a kill zone reached %d where the weapon reaches %d"
			% [reach, archer.get_attack_range()])
	# A literal reach is not the weapon's.
	var braced: int = Reaction.reach_of(
		Reaction.of(CombatManager.get_status_definition("Set_For_Charge")), archer)
	if braced != 2:
		_fail("Set for Charge reached %d, expected its declared 2" % braced)
	_cleanup([archer])
	_done()


## Standing over somebody: the reaction fires on a move against the ALLY, not
## against the guard.
func _check_a_guard_answers_a_move_against_the_guarded() -> void:
	var guard := _make_unit(Vector2i(10, 10), 0)
	var ward := _make_unit(Vector2i(11, 10), 0)
	# The raider ends adjacent to the WARD, and within the guard's own reach —
	# a free sword attack has to be able to land, which is what stops a
	# swordsman from answering across a gap.
	var raider := _make_unit(Vector2i(14, 11), 1)
	CombatManager._apply_status_effect(guard, "Guarding_The_Gap", 1)

	_walk(raider, Vector2i(11, 11))
	if _times_fired(guard, "Guarding_The_Gap") != 1:
		_fail("an enemy walked up to the guarded ally unanswered")

	# Moving somewhere that threatens nobody is not a provocation — even right
	# under the guard's nose. (11,11) is adjacent to the guard and two tiles
	# from the ward, so only a reaction that has stopped asking WHERE the mover
	# ended would fire.
	guard.status_effects.clear()
	CombatManager._apply_status_effect(guard, "Guarding_The_Gap", 5)
	_place(raider, Vector2i(25, 25))           # off the tiles below
	_place(ward, Vector2i(10, 9))
	var stroller := _make_unit(Vector2i(11, 12), 1)
	_walk(stroller, Vector2i(9, 11))
	if _times_fired(guard, "Guarding_The_Gap") != 0:
		_fail("the guard answered a move that came near nobody it guards")

	# And an ally standing outside the guard's reach is not guarded, however
	# close the enemy gets to THEM.
	guard.status_effects.clear()
	CombatManager._apply_status_effect(guard, "Guarding_The_Gap", 5)
	_place(ward, Vector2i(10, 12))             # two tiles from the guard
	_place(stroller, Vector2i(26, 26))
	var raider2 := _make_unit(Vector2i(12, 11), 1)
	_walk(raider2, Vector2i(10, 11))           # beside the far ally, beside the guard
	if _times_fired(guard, "Guarding_The_Gap") != 0:
		_fail("the guard answered for an ally standing outside the reach it "
			+ "guards")
	_cleanup([raider2, stroller])
	_cleanup([guard, ward, raider])
	_done()


## "Until your next turn" — the allowance refills when the reactor's turn comes
## round, not on the round boundary, because initiative makes those different
## moments.
func _check_a_reaction_budget_refills_on_your_turn() -> void:
	var holder := _make_unit(Vector2i(10, 10), 0)
	var attacker := _make_unit(Vector2i(11, 10), 1)
	CombatManager._apply_status_effect(holder, "Counterstance", 5)

	if _strike(attacker, holder, "Counterstance") != 1:
		_fail("the first blow was not answered")
	if _strike(attacker, holder, "Counterstance") != 0:
		_fail("the stance answered the same attacker twice in one round")

	CombatManager.turn_order = [holder]
	CombatManager.current_unit_index = 0
	CombatManager._start_current_turn()
	if _strike(attacker, holder, "Counterstance") != 1:
		_fail("the stance never answered again after the holder's next turn — "
			+ "the per-round budget is not refilling")
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([holder, attacker])
	_done()


## Heavenly Counterflow turns the blow aside before answering it.
func _check_a_counterflow_turns_the_blow_aside() -> void:
	var monk := _make_unit(Vector2i(10, 10), 0)
	var attacker := _make_unit(Vector2i(11, 10), 1)
	CombatManager._apply_status_effect(monk, "Heavenly_Counterflow", 1)

	# Hit chance is capped at 95%, so a blow can always miss — and a missed
	# blow reaches no reaction at all. Swing until one connects; what is being
	# measured is what happens to a blow that WOULD have landed.
	_revive(monk)
	_revive(attacker)
	var result: Dictionary = {}
	for _try in 20:
		_place(monk, Vector2i(10, 10))
		_place(attacker, Vector2i(11, 10))
		_take_turn(attacker)
		result = CombatManager.attack_unit(attacker, monk)
		if bool(result.get("hit", false)) or bool(result.get("dodged", false)):
			break
	if monk.current_hp < monk.max_hp:
		_fail("the blow landed for %d on a counterflow that should have turned "
			% (monk.max_hp - monk.current_hp) + "it aside")
	if not bool(result.get("dodged", false)):
		_fail("the attack result does not report the dodge")
	# Positions reset every exchange: the counterflow's third response is to
	# step two tiles away, so without this the second exchange is already out
	# of melee and nothing fires at all.
	var answered := false
	for _try in 20:
		_revive(monk)
		_revive(attacker)
		_place(monk, Vector2i(10, 10))
		_place(attacker, Vector2i(11, 10))
		monk.status_effects.clear()
		CombatManager._apply_status_effect(monk, "Heavenly_Counterflow", 1)
		_take_turn(attacker)
		CombatManager.attack_unit(attacker, monk)
		if attacker.current_hp < attacker.max_hp:
			answered = true
			break
	if not answered:
		_fail("the counterflow turned the blow aside and never answered it in "
			+ "twenty exchanges")
	_cleanup([monk, attacker])
	_done()


## `max_per_round` is what keeps a stance from ending a fight by itself.
func _check_a_stance_spends_only_what_it_may() -> void:
	var holder := _make_unit(Vector2i(10, 10), 0)
	var a := _make_unit(Vector2i(11, 10), 1)
	var b := _make_unit(Vector2i(9, 10), 1)
	var c := _make_unit(Vector2i(10, 11), 1)
	var d := _make_unit(Vector2i(10, 9), 1)

	# Counterstance allows three answers a round, one per attacker.
	CombatManager._apply_status_effect(holder, "Counterstance", 5)
	for attacker in [a, b, c, d]:
		_strike(attacker, holder, "Counterstance")
	var fired: int = _times_fired(holder, "Counterstance")
	if fired != 3:
		_fail("a stance allowing three answers a round answered %d times "
			% fired + "against four attackers")

	# Set for Charge allows exactly one.
	holder.status_effects.clear()
	CombatManager._apply_status_effect(holder, "Set_For_Charge", 5)
	for attacker in [a, b, c]:
		_revive(attacker)
		_strike(attacker, holder, "Set_For_Charge")
	var braced_fired: int = _times_fired(holder, "Set_For_Charge")
	if braced_fired > 1:
		_fail("a one-answer stance answered %d times" % braced_fired)
	_cleanup([holder, a, b, c, d])
	_done()


## A spear stance threatens two tiles; a swordsman holding a two-tile stance
## cannot answer at two tiles, and must not burn the round's allowance trying.
func _check_an_unreachable_answer_keeps_its_allowance() -> void:
	# Set for Charge, whose only answer is the attack — None Shall Pass also
	# slows what it catches, and a slow lands at two tiles even when a
	# swordsman's blade does not.
	var sentry := _make_unit(Vector2i(10, 10), 0)   # reach 1 weapon
	var runner := _make_unit(Vector2i(14, 10), 1)
	CombatManager._apply_status_effect(sentry, "Set_For_Charge", 5)

	# Into the threatened area (2) but outside the sentry's reach (1).
	_walk(runner, Vector2i(12, 10))
	if _times_fired(sentry, "Set_For_Charge") != 0:
		_fail("a stance spent its answer on an enemy it could not reach")

	# And then into reach, where it does answer — proving the allowance was
	# still there.
	_walk(runner, Vector2i(14, 10))
	_walk(runner, Vector2i(11, 10))
	if _times_fired(sentry, "Set_For_Charge") != 1:
		_fail("the stance did not answer an enemy that walked into reach "
			+ "after one it could not reach")
	_cleanup([sentry, runner])
	_done()


## Crossing IN provokes; walking around inside does not. Otherwise a stance
## answers every step an enemy takes near it.
func _check_moving_inside_a_threatened_area_provokes_once() -> void:
	var sentry := _make_unit(Vector2i(10, 10), 0)
	var runner := _make_unit(Vector2i(14, 10), 1)
	CombatManager._apply_status_effect(sentry, "None_Shall_Pass", 5)

	_walk(runner, Vector2i(11, 10))            # crossing in
	var after_entry: int = _times_fired(sentry, "None_Shall_Pass")
	if after_entry != 1:
		_fail("crossing into a threatened area provoked %d times" % after_entry)

	_walk(runner, Vector2i(11, 11))            # a step, still inside
	_walk(runner, Vector2i(10, 11))            # and another
	if _times_fired(sentry, "None_Shall_Pass") != after_entry:
		_fail("walking about inside the threatened area provoked again — "
			+ "every step near a spear would be a free attack")
	_cleanup([sentry, runner])
	_done()


## The stance the PERK puts on, through the real active-skill path. Every other
## check here applies the status by hand, so the wiring from perk to status is
## exactly what none of them touches.
func _check_the_perk_is_what_puts_the_stance_on() -> void:
	var swordsman := _make_unit(Vector2i(10, 10), 0)
	swordsman.character_data["skills"] = {"swords": 9}
	swordsman.character_data["perks"] = ["counterstrike"]
	swordsman.character_data["equipped_weapon"] = {
		"name": "Probe Sword", "type": "sword", "stats": {"range": 1, "damage": 8}}
	CharacterSystem.update_derived_stats(swordsman.character_data)
	_take_turn(swordsman)
	swordsman.current_stamina = 50

	var perk: Dictionary = PerkSystem.get_perk_data("counterstrike")
	if perk.is_empty():
		_fail("counterstrike is not in perks.json")
		_done()
		return
	var skill_data: Dictionary = perk.duplicate()
	skill_data["id"] = "counterstrike"
	var result: Dictionary = CombatManager.use_active_skill(
		swordsman, skill_data, swordsman.grid_position)
	if not bool(result.get("success", false)):
		_fail("using Counterstrike failed: %s" % str(result.get("reason", "?")))
	elif not swordsman.has_status("Counterstance"):
		_fail("using Counterstrike did not put the Counterstance on: %s"
			% str(swordsman.status_effects))
	# And it does not end the turn, because its own text does not say so.
	if bool(result.get("ends_turn", false)):
		_fail("Counterstrike ended the turn, which its description does not ask for")
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([swordsman])
	_done()
