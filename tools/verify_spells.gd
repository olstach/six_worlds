extends Node
## Headless verification for spell resolution.
##
## Run: godot --headless res://tools/verify_spells.tscn
##
## Every check drives `_apply_spell_effects` — the function the game calls — and
## asserts on the target's HP afterwards. Asking `SpellDamage.resolve()` what it
## thinks would test the scaffolding this commit added: the seven broken spells
## had a perfectly good number written in their data and a type guard upstream
## that threw it away, and only the real path can see that.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var grid: CombatGrid

var checks_run: int = 0
const EXPECTED_CHECKS: int = 41


func _ready() -> void:
	# Spell damage carries ±15% variance. Unseeded, a comparison between two
	# casts is part signal and part coin flip — which is how three deliberate
	# breakages slipped past the first version of this file. Seeded, the same
	# rolls come up every run, and the margins below are what carry the result.
	seed(20260913)

	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	_check_plain_numeric_damage_still_works()
	_check_spellpower_formula()
	_check_spellpower_formula_rewards_the_caster()
	_check_target_max_hp_formula()
	_check_status_stacks_formula()
	_check_status_stacks_consumes_the_status()
	_check_requires_status_blocks_the_spell()
	_check_unknown_formula_deals_nothing()
	_check_no_spell_deals_nothing_by_accident()
	_check_save_type_is_case_insensitive()

	_check_push_moves_the_target()
	_check_blocked_push_deals_its_damage()
	_check_push_scales_with_spellpower()
	_check_scatter_relocates_the_target()

	_check_push_still_works_through_reposition()
	_check_self_teleport_moves_the_caster()
	_check_teleport_respects_its_range()
	_check_swap_exchanges_two_units()
	_check_anchored_blocks_placement_but_not_a_shove()

	_check_cleanse_removes_everything_not_one_thing()
	_check_named_removal_takes_the_named_status()
	_check_count_caps_a_removal()
	_check_dispel_takes_buffs_too()
	_check_steal_moves_a_buff_to_the_thief()
	_check_transfer_loses_nothing()
	_check_convert_scales_with_what_it_spends()

	_check_raise_dead_returns_a_dead_unit()
	_check_resurrect_returns_more_than_raise_dead()
	_check_destroyed_corpse_refuses_resurrection()
	_check_resurrection_refuses_the_living()
	_check_breath_of_heaven_reaches_the_whole_party()
	_check_a_dead_ally_can_be_targeted()
	_check_the_fallen_are_recorded_and_can_be_raised()
	_check_raise_dead_cast_end_to_end()

	_check_failed_save_kills_and_passed_save_does_not()
	_check_a_kill_can_pay_gold()
	_check_gold_scales_with_what_was_killed()
	_check_save_gate_statuses_still_apply()
	_check_damage_lands_regardless_of_the_save()
	_check_mana_transfer_moves_what_was_there()
	_check_a_transfer_cannot_create_what_is_not_there()

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


func _done() -> void:
	checks_run += 1


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


# ── Fixtures ─────────────────────────────────────────────────────────────────

func _make_unit(at: Vector2i, team: int = 0, spellpower: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	if spellpower > 0:
		unit.character_data["attributes"]["focus"] = spellpower
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 200
	unit.current_hp = 200
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


## Cast `spell_id` from caster at target through the real resolver, and report
## how much HP came off. `bonus` is the spellpower bonus the caller would pass.
func _damage_dealt(spell_id: String, caster: CombatUnit, target: CombatUnit,
		bonus: int = 0) -> int:
	var spell: Dictionary = CombatManager.get_spell(spell_id)
	if spell.is_empty():
		_fail("spell '%s' is not in the database" % spell_id)
		return 0
	var before: int = target.current_hp
	CombatManager._apply_spell_effects(caster, target, spell, bonus)
	return before - target.current_hp


# ── Formulas ─────────────────────────────────────────────────────────────────

## Regression guard. 350-odd spells carry a plain number and must keep working
## while the formula path exists alongside them.
func _check_plain_numeric_damage_still_works() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0)
	var target := _make_unit(Vector2i(6, 5), 1)
	var dealt: int = _damage_dealt("firebolt", caster, target)
	if dealt <= 0:
		_fail("firebolt (a plain 15-damage spell) dealt %d" % dealt)
	_cleanup([caster, target])
	_done()


## Implosion is a 225-mana level 9 capstone that dealt nothing at all, because
## its damage read "spellpower_scaling" and the guard upstream wanted a number.
func _check_spellpower_formula() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 25)
	var target := _make_unit(Vector2i(6, 5), 1)
	var dealt: int = _damage_dealt("implosion", caster, target)
	if dealt <= 0:
		_fail("implosion dealt %d — the spellpower formula resolved to nothing" % dealt)
	_cleanup([caster, target])
	_done()


## And it must actually scale, or the formula is decoration.
func _check_spellpower_formula_rewards_the_caster() -> void:
	var weak := _make_unit(Vector2i(5, 5), 0, 8)
	var strong := _make_unit(Vector2i(5, 7), 0, 30)
	var t1 := _make_unit(Vector2i(6, 5), 1)
	var t2 := _make_unit(Vector2i(6, 7), 1)

	# Variance is ±15%, so compare totals over several casts rather than one.
	var weak_total := 0
	var strong_total := 0
	for _i in 8:
		t1.current_hp = t1.max_hp
		t2.current_hp = t2.max_hp
		weak_total += _damage_dealt("implosion", weak, t1)
		strong_total += _damage_dealt("implosion", strong, t2)
	# Focus 30 against focus 8 is nearly four times the spellpower, so anything
	# short of double is the formula not reading the caster at all.
	if strong_total < weak_total * 2:
		_fail("implosion: focus 30 dealt %d over 8 casts, focus 8 dealt %d — "
			% [strong_total, weak_total] + "spellpower is barely scaling the damage")
	_cleanup([weak, strong, t1, t2])
	_done()


## Liberate is an execute: its damage is measured against the victim, not the
## caster, so a bigger target takes a bigger hit from the same cast.
func _check_target_max_hp_formula() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 20)
	var small := _make_unit(Vector2i(6, 5), 1)
	small.max_hp = 100
	small.current_hp = 100
	var big := _make_unit(Vector2i(7, 5), 1)
	big.max_hp = 400
	big.current_hp = 400
	# Liberate is an execute: it kills outright on a FAILED save, and a corpse
	# tells us nothing about the damage formula — both targets simply lose
	# every point they had. Let them pass the save so only the base damage
	# lands. (This check silently stopped testing the formula the moment the
	# instant-kill gate was wired, and the mutation sweep is what caught it.)
	small.character_data["attributes"]["focus"] = 99
	big.character_data["attributes"]["focus"] = 99

	var on_small: int = _damage_dealt("liberate", caster, small)
	var on_big: int = _damage_dealt("liberate", caster, big)
	if on_small <= 0:
		_fail("liberate dealt %d to a 100 hp target" % on_small)
	if on_big <= on_small:
		_fail("liberate dealt %d to a 400 hp target and %d to a 100 hp one — "
			% [on_big, on_small] + "it is not scaling off the target's health")
	_cleanup([caster, small, big])
	_done()


func _check_status_stacks_formula() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var one := _make_unit(Vector2i(6, 5), 1)
	var three := _make_unit(Vector2i(7, 5), 1)
	# The status is consumed by the cast, so re-apply between samples — by
	# clearing and applying a fixed count, never by asking stacks_of() how many
	# are there. Using the function under test to set up its own test made a
	# broken stacks_of() spin forever here instead of failing.
	var one_total := 0
	var three_total := 0
	for _i in 6:
		one.current_hp = one.max_hp
		three.current_hp = three.max_hp
		one.status_effects.clear()
		three.status_effects.clear()
		CombatManager._apply_status_effect(one, "Burning", 3)
		for _s in 3:
			CombatManager._apply_status_effect(three, "Burning", 3)
		one_total += _damage_dealt("spontaneous_combustion", caster, one)
		three_total += _damage_dealt("spontaneous_combustion", caster, three)

	if one_total <= 0:
		_fail("spontaneous_combustion dealt %d to a burning target" % one_total)
	# Three stacks against one is triple the fuel; under double means the count
	# is not reaching the formula.
	if three_total < one_total * 2:
		_fail("spontaneous_combustion dealt %d at 3 stacks and %d at 1 over 6 "
			% [three_total, one_total] + "casts each — it is not counting stacks")
	_cleanup([caster, one, three])
	_done()


## The detonation is paid for with the fire it counted.
func _check_status_stacks_consumes_the_status() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 1)
	CombatManager._apply_status_effect(target, "Burning", 3)
	_damage_dealt("spontaneous_combustion", caster, target)
	if target.has_status("Burning"):
		_fail("spontaneous_combustion left the target still Burning — the stacks "
			+ "it spent were not removed")
	_cleanup([caster, target])
	_done()


## And with no fire to spend, there is no explosion.
## And with no fire to spend, there is no explosion.
##
## Asserted on the REPORTED OUTCOME rather than the damage. With no Burning to
## count, the formula yields zero either way, so the damage number cannot tell
## "the spell was blocked" apart from "the spell resolved to nothing" — and the
## arena needs that difference to tell the player why nothing happened.
func _check_requires_status_blocks_the_spell() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 1)
	var spell: Dictionary = CombatManager.get_spell("spontaneous_combustion")
	var before: int = target.current_hp
	var result: Dictionary = CombatManager._apply_spell_effects(caster, target, spell, 0)

	if target.current_hp != before:
		_fail("spontaneous_combustion dealt %d to a target that was not Burning"
			% (before - target.current_hp))

	var reported := false
	for effect in result.get("effects_applied", []):
		if effect.get("type", "") == "no_effect":
			reported = true
	if not reported:
		_fail("spontaneous_combustion on a target with no Burning reported %s — "
			% str(result.get("effects_applied", []))
			+ "nothing says the requirement was unmet")
	_cleanup([caster, target])
	_done()


## An unknown formula must resolve to nothing and complain, not fall back to a
## number that looks like it worked.
func _check_unknown_formula_deals_nothing() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 20)
	var target := _make_unit(Vector2i(6, 5), 1)
	var fake := {"id": "verify_fake", "damage": {"formula": "no_such_formula"},
		"damage_type": "fire"}
	var before: int = target.current_hp
	CombatManager._apply_spell_effects(caster, target, fake, 0)
	if target.current_hp != before:
		_fail("an unknown damage formula dealt %d" % (before - target.current_hp))
	_cleanup([caster, target])
	_done()


## The sweep that found the original seven: no spell may carry a `damage` value
## the resolver cannot read. Asserted here as well as in validate_data.py
## because this one runs against the parsed database the game actually uses.
func _check_no_spell_deals_nothing_by_accident() -> void:
	var bad: Array[String] = []
	for spell_id in CombatManager.get_all_spell_ids():
		var spell: Dictionary = CombatManager.get_spell(spell_id)
		var dm = spell.get("damage", null)
		if dm == null or dm is int or dm is float:
			continue
		if not (dm is Dictionary) or not SpellDamage.is_formula(dm.get("formula", "")):
			bad.append(spell_id)
	if not bad.is_empty():
		_fail("%d spell(s) have an unreadable `damage` value: %s"
			% [bad.size(), ", ".join(bad)])
	_done()


# ── Saves ────────────────────────────────────────────────────────────────────

## spells.json writes "Focus"; perk data and this file's defaults write "focus".
## SaveSystem normalises at its boundary so neither caller has to remember.
func _check_save_type_is_case_insensitive() -> void:
	if not SaveSystem.is_valid_save_type("Focus"):
		_fail("SaveSystem rejects 'Focus', the spelling every spell in the "
			+ "database uses")
	if not SaveSystem.is_valid_save_type("focus"):
		_fail("SaveSystem rejects 'focus', the spelling perk data uses")

	var defender := _make_unit(Vector2i(5, 5), 0, 20)
	defender.character_data["attributes"]["focus"] = 18
	var upper: float = SaveSystem.success_chance(defender, "Focus", 20)
	var lower: float = SaveSystem.success_chance(defender, "focus", 20)
	if not is_equal_approx(upper, lower):
		_fail("the same save reads %.2f as 'Focus' and %.2f as 'focus' — the "
			% [upper, lower] + "capitalised spelling is losing the attribute")
	_cleanup([defender])
	_done()


# ── Forced movement ──────────────────────────────────────────────────────────

## Surge is a level 1 Water spell dealing 5 damage whose actual point — shove
## the target a tile — sat in an unread `special` key.
func _check_push_moves_the_target() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var target := _make_unit(Vector2i(6, 5), 1)
	_damage_dealt("surge", caster, target)
	if target.grid_position == Vector2i(6, 5):
		_fail("surge left the target standing on %s — the push never happened"
			% str(target.grid_position))
	_cleanup([caster, target])
	_done()


## And when there is nowhere to go, the wall is the weapon. 5 damage becomes 15.
func _check_blocked_push_deals_its_damage() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var target := _make_unit(Vector2i(6, 5), 1)
	var wall := _make_unit(Vector2i(7, 5), 1)   # a body blocks a push as surely as stone

	var open_caster := _make_unit(Vector2i(5, 12), 0, 12)
	var open_target := _make_unit(Vector2i(6, 12), 1)

	var blocked: int = _damage_dealt("surge", caster, target)
	var unblocked: int = _damage_dealt("surge", open_caster, open_target)

	if target.grid_position != Vector2i(6, 5):
		_fail("the blocked target moved to %s" % str(target.grid_position))
	# Surge deals 5 and slams for 10, so a working slam is three times the open
	# figure. Plain ">" let a broken slam pass on ±15% variance alone.
	if blocked < unblocked * 2:
		_fail("surge dealt %d into an obstacle and %d into open ground — "
			% [blocked, unblocked] + "the slam damage is not being applied")
	_cleanup([caster, target, wall, open_caster, open_target])
	_done()


## Wave and Tsunami push further for a stronger caster; Surge never does.
func _check_push_scales_with_spellpower() -> void:
	var weak := _make_unit(Vector2i(2, 2), 0, 5)
	var strong := _make_unit(Vector2i(2, 8), 0, 40)
	var t1 := _make_unit(Vector2i(3, 2), 1)
	var t2 := _make_unit(Vector2i(3, 8), 1)

	_damage_dealt("tsunami", weak, t1)
	_damage_dealt("tsunami", strong, t2)
	var weak_dist: int = absi(t1.grid_position.x - 3)
	var strong_dist: int = absi(t2.grid_position.x - 3)
	if strong_dist <= weak_dist:
		_fail("tsunami pushed %d tiles at focus 40 and %d at focus 5 — "
			% [strong_dist, weak_dist] + "per_spellpower is not being read")
	_cleanup([weak, strong, t1, t2])
	_done()


## A scatter has no direction: it puts the target down somewhere else entirely.
func _check_scatter_relocates_the_target() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var target := _make_unit(Vector2i(8, 5), 1)
	_damage_dealt("air_bomb", caster, target)
	if target.grid_position == Vector2i(8, 5):
		_fail("air_bomb left the target on %s — the scatter never happened"
			% str(target.grid_position))
	_cleanup([caster, target])
	_done()


# ── Repositioning ────────────────────────────────────────────────────────────

## A push is one mode among several now. The refactor must not have cost the
## thing it generalised — perks and the water ladder both still go through here.
func _check_push_still_works_through_reposition() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var target := _make_unit(Vector2i(6, 5), 1)
	var result: Dictionary = CombatManager.reposition(
		target, {"mode": "push", "tiles": 2}, caster, target.grid_position)
	if target.grid_position != Vector2i(8, 5):
		_fail("a 2-tile push put the target on %s, expected (8, 5)"
			% str(target.grid_position))
	if result.get("moved", 0) != 2:
		_fail("push reported moving %d tiles, expected 2" % result.get("moved", 0))
	_cleanup([caster, target])
	_done()


## Blink, Jump, Get Out and Teleport are one mechanic at four ranges. Each spent
## four months as an unread `special` key.
func _check_self_teleport_moves_the_caster() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	caster.current_mana = 500
	# cast_spell runs the whole turn economy, so the probe has to be the unit
	# whose turn it is and has to have an action to spend.
	caster.actions_remaining = 2
	# Blink is a level 3 Space/Sorcery spell, and cast_spell checks that the
	# caster can actually cast it. Set on this probe alone, so the damage
	# checks above keep their numbers.
	caster.character_data["skills"] = {"space_magic": 9, "sorcery": 9}
	CombatManager.turn_order = [caster]
	CombatManager.current_unit_index = 0
	var dest := Vector2i(9, 5)
	var result: Dictionary = CombatManager.cast_spell(caster, "blink", dest)
	if not result.get("success", false):
		_fail("blink failed: %s" % str(result.get("reason", "?")))
	elif caster.grid_position != dest:
		_fail("blink left the caster on %s, expected %s"
			% [str(caster.grid_position), str(dest)])
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([caster])
	_done()


## Range is what separates them, so it has to bite.
func _check_teleport_respects_its_range() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	caster.current_mana = 500
	var far := Vector2i(5 + 20, 5)
	var result: Dictionary = CombatManager.reposition(
		caster, {"mode": "teleport", "self": true, "range": 3}, caster, far)
	if result.get("ok", false):
		_fail("a range 3 teleport reached %s, 20 tiles away" % str(far))
	if caster.grid_position != Vector2i(5, 5):
		_fail("the caster moved to %s despite the refusal" % str(caster.grid_position))
	_cleanup([caster])
	_done()


## Both units move at once, or the first would be blocked by the second.
func _check_swap_exchanges_two_units() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var other := _make_unit(Vector2i(9, 9), 1)
	CombatManager.reposition(caster, {"mode": "swap"}, caster, Vector2i(9, 9))
	if caster.grid_position != Vector2i(9, 9):
		_fail("after a swap the caster is on %s, expected (9, 9)"
			% str(caster.grid_position))
	if other.grid_position != Vector2i(5, 5):
		_fail("after a swap the other unit is on %s, expected (5, 5)"
			% str(other.grid_position))
	_cleanup([caster, other])
	_done()


## Dimensional Anchor pins someone to the plane. That stops a teleport and not a
## shove — being nailed to the world does not make you heavy.
func _check_anchored_blocks_placement_but_not_a_shove() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 12)
	var victim := _make_unit(Vector2i(6, 5), 1)
	CombatManager._apply_status_effect(victim, "Anchored", 5)

	var teleported: Dictionary = CombatManager.reposition(
		victim, {"mode": "teleport", "range": 5}, caster, Vector2i(6, 9))
	if teleported.get("ok", false):
		_fail("an Anchored unit teleported to %s" % str(victim.grid_position))

	var shoved: Dictionary = CombatManager.reposition(
		victim, {"mode": "push", "tiles": 1}, caster, victim.grid_position)
	if shoved.get("moved", 0) != 1:
		_fail("an Anchored unit resisted a shove (moved %d) — anchoring should "
			% shoved.get("moved", 0) + "stop displacement, not force")
	_cleanup([caster, victim])
	_done()


# ── Status operations ────────────────────────────────────────────────────────

## The bug that shipped: `statuses_removed` says WHICH statuses to remove, and
## the combat reader used its LENGTH as a count. `cleanse: ["all_negative"]` is
## a one-element list, so the spell that promises to remove everything removed
## exactly one thing.
func _check_cleanse_removes_everything_not_one_thing() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 0)
	for status in ["Poisoned", "Bleeding", "Slowed", "Burning"]:
		CombatManager._apply_status_effect(target, status, 3)
	var before: int = target.status_effects.size()

	var spell: Dictionary = CombatManager.get_spell("cleanse")
	CombatManager._apply_spell_effects(caster, target, spell, 0)

	if target.status_effects.size() >= before:
		_fail("cleanse removed nothing from %d debuffs" % before)
	elif target.status_effects.size() > 0:
		_fail("cleanse left %d of %d debuffs — it is still removing a count "
			% [target.status_effects.size(), before]
			+ "rather than everything the tag names")
	_cleanup([caster, target])
	_done()


## And a named list must take the ones it names, not whatever is nearest.
func _check_named_removal_takes_the_named_status() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 0)
	# Poisoned first, so a reader that takes "the first dispellable debuff"
	# takes the wrong one.
	CombatManager._apply_status_effect(target, "Poisoned", 3)
	CombatManager._apply_status_effect(target, "Burning", 3)

	var spell: Dictionary = CombatManager.get_spell("cooling_mist")
	CombatManager._apply_spell_effects(caster, target, spell, 0)

	if target.has_status("Burning"):
		_fail("cooling_mist left the Burning it names")
	if not target.has_status("Poisoned"):
		_fail("cooling_mist removed the Poison it does not name")
	_cleanup([caster, target])
	_done()


func _check_count_caps_a_removal() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 0)
	for status in ["Poisoned", "Bleeding", "Slowed"]:
		CombatManager._apply_status_effect(target, status, 3)

	# Cure removes exactly one — "reliably", which is its whole level 1 identity.
	var spell: Dictionary = CombatManager.get_spell("cure")
	CombatManager._apply_spell_effects(caster, target, spell, 0)
	if target.status_effects.size() != 2:
		_fail("cure left %d of 3 debuffs, expected 2" % target.status_effects.size())
	_cleanup([caster, target])
	_done()


## A dispel does not care whose side an effect is on — that is what separates
## it from a cleanse.
func _check_dispel_takes_buffs_too() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var target := _make_unit(Vector2i(6, 5), 1)
	CombatManager._apply_status_effect(target, "Blessed", 3)
	CombatManager._apply_status_effect(target, "Poisoned", 3)

	var spell: Dictionary = CombatManager.get_spell("dispel")
	CombatManager._apply_spell_effects(caster, target, spell, 0)
	if target.has_status("Blessed"):
		_fail("dispel left a buff in place — it is only cleansing debuffs")
	if target.has_status("Poisoned"):
		_fail("dispel left a debuff in place")
	_cleanup([caster, target])
	_done()


## Stealing is not deleting: the buff has to arrive on the thief.
func _check_steal_moves_a_buff_to_the_thief() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var victim := _make_unit(Vector2i(6, 5), 1)
	CombatManager._apply_status_effect(victim, "Blessed", 4)
	CombatManager._apply_status_effect(victim, "Poisoned", 4)

	var spell: Dictionary = CombatManager.get_spell("steal_blessings")
	CombatManager._apply_spell_effects(caster, victim, spell, 0)

	if victim.has_status("Blessed"):
		_fail("steal_blessings left the blessing on its victim")
	if not caster.has_status("Blessed"):
		_fail("steal_blessings removed the blessing but the caster did not gain it")
	if not victim.has_status("Poisoned"):
		_fail("steal_blessings took a debuff as well — it selects buffs only")
	_cleanup([caster, victim])
	_done()


## Heat Transfer's own data says no stacks are lost. Every stack lifted off an
## ally has to land on an enemy.
func _check_transfer_loses_nothing() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var ally := _make_unit(Vector2i(6, 5), 0)
	var foe_a := _make_unit(Vector2i(9, 5), 1)
	var foe_b := _make_unit(Vector2i(9, 7), 1)

	for _i in 3:
		CombatManager._apply_status_effect(ally, "Burning", 3)
	CombatManager._apply_status_effect(caster, "Burning", 3)
	var lifted: int = SpellDamage.stacks_of(ally, "Burning") \
		+ SpellDamage.stacks_of(caster, "Burning")

	var spell: Dictionary = CombatManager.get_spell("heat_transfer")
	CombatManager._apply_spell_effects(caster, foe_a, spell, 0)

	var on_allies: int = SpellDamage.stacks_of(ally, "Burning") \
		+ SpellDamage.stacks_of(caster, "Burning")
	var on_foes: int = SpellDamage.stacks_of(foe_a, "Burning") \
		+ SpellDamage.stacks_of(foe_b, "Burning")
	if on_allies != 0:
		_fail("heat_transfer left %d burning stack(s) on the party" % on_allies)
	if on_foes != lifted:
		_fail("heat_transfer lifted %d stack(s) and delivered %d — stacks were lost"
			% [lifted, on_foes])
	_cleanup([caster, ally, foe_a, foe_b])
	_done()


## Each debuff shed becomes a bolt, so a heavily afflicted caster detonates
## harder. If the burst is flat, the spell has no reason to exist.
func _check_convert_scales_with_what_it_spends() -> void:
	var light := _make_unit(Vector2i(2, 2), 0, 15)
	var foe_light := _make_unit(Vector2i(3, 2), 1)
	CombatManager._apply_status_effect(light, "Poisoned", 3)

	var heavy := _make_unit(Vector2i(2, 8), 0, 15)
	var foe_heavy := _make_unit(Vector2i(3, 8), 1)
	for status in ["Poisoned", "Bleeding", "Slowed", "Burning"]:
		CombatManager._apply_status_effect(heavy, status, 3)

	var spell: Dictionary = CombatManager.get_spell("flash_of_radiance")
	var hp_light: int = foe_light.current_hp
	var hp_heavy: int = foe_heavy.current_hp
	CombatManager._apply_spell_effects(light, foe_light, spell, 0)
	CombatManager._apply_spell_effects(heavy, foe_heavy, spell, 0)

	var dealt_light: int = hp_light - foe_light.current_hp
	var dealt_heavy: int = hp_heavy - foe_heavy.current_hp
	if dealt_light <= 0:
		_fail("flash_of_radiance with one debuff dealt %d" % dealt_light)
	if dealt_heavy <= dealt_light:
		_fail("flash_of_radiance dealt %d with four debuffs and %d with one — "
			% [dealt_heavy, dealt_light] + "the burst does not scale with what it spends")
	if light.has_status("Poisoned") or heavy.has_status("Burning"):
		_fail("flash_of_radiance did not shed the debuffs it spent")
	_cleanup([light, foe_light, heavy, foe_heavy])
	_done()


# ── Resurrection ─────────────────────────────────────────────────────────────

func _down(unit: CombatUnit) -> void:
	unit.is_dead = true
	unit.is_bleeding_out = false
	unit.current_hp = 0


## raise_dead is 135 mana and did nothing at all — the game had no working
## resurrection at any tier.
func _check_raise_dead_returns_a_dead_unit() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var corpse := _make_unit(Vector2i(6, 5), 0)
	_down(corpse)

	var spell: Dictionary = CombatManager.get_spell("raise_dead")
	CombatManager._apply_spell_effects(caster, corpse, spell, 0)
	if corpse.is_dead:
		_fail("raise_dead left the target dead")
	elif corpse.current_hp < 1:
		_fail("raise_dead returned the target at %d hp — a resurrection that "
			% corpse.current_hp + "returns someone at zero kills them again")
	_cleanup([caster, corpse])
	_done()


## The 225-mana version returns you whole; the 135-mana one returns you standing.
## If they are the same, the tier does not exist.
func _check_resurrect_returns_more_than_raise_dead() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var a := _make_unit(Vector2i(6, 5), 0)
	var b := _make_unit(Vector2i(7, 5), 0)
	_down(a)
	_down(b)

	CombatManager._apply_spell_effects(caster, a, CombatManager.get_spell("raise_dead"), 0)
	CombatManager._apply_spell_effects(caster, b, CombatManager.get_spell("resurrect"), 0)
	if b.current_hp <= a.current_hp:
		_fail("resurrect returned %d hp and raise_dead %d — the 225-mana spell "
			% [b.current_hp, a.current_hp] + "is no better than the 135-mana one")
	if b.current_hp != b.max_hp:
		_fail("resurrect returned %d of %d hp" % [b.current_hp, b.max_hp])
	_cleanup([caster, a, b])
	_done()


## Balefire and the funeral pyre leave nothing to raise. This is the only hard
## refusal in the system and what makes those spells worth casting.
func _check_destroyed_corpse_refuses_resurrection() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var corpse := _make_unit(Vector2i(6, 5), 0)
	_down(corpse)
	corpse.corpse_destroyed = true

	CombatManager._apply_spell_effects(caster, corpse, CombatManager.get_spell("resurrect"), 0)
	if not corpse.is_dead:
		_fail("resurrect raised someone whose body was destroyed")
	_cleanup([caster, corpse])
	_done()


func _check_resurrection_refuses_the_living() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var alive := _make_unit(Vector2i(6, 5), 0)
	alive.current_hp = 40

	CombatManager._apply_spell_effects(caster, alive, CombatManager.get_spell("resurrect"), 0)
	if alive.current_hp != 40:
		_fail("resurrect healed a living target to %d — it should refuse them"
			% alive.current_hp)
	_cleanup([caster, alive])
	_done()


## Breath of Heaven raises everyone on the caster's side, which is the whole
## point of a 225-mana spell with that name.
func _check_breath_of_heaven_reaches_the_whole_party() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	var a := _make_unit(Vector2i(6, 5), 0)
	var b := _make_unit(Vector2i(7, 5), 0)
	var foe := _make_unit(Vector2i(8, 5), 1)
	_down(a)
	_down(b)
	_down(foe)

	CombatManager._apply_spell_effects(caster, a, CombatManager.get_spell("breath_of_heaven"), 0)
	if a.is_dead or b.is_dead:
		_fail("breath_of_heaven raised %s — it should reach every fallen ally"
			% ("neither" if a.is_dead and b.is_dead else "only one"))
	if not foe.is_dead:
		_fail("breath_of_heaven raised an enemy")
	_cleanup([caster, a, b, foe])
	_done()


## The targeting filtered on is_bleeding_out alone, so the only people a
## resurrection could reach were the ones not yet dead.
func _check_a_dead_ally_can_be_targeted() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	caster.character_data["skills"] = {"white_magic": 9, "sorcery": 9}
	var corpse := _make_unit(Vector2i(6, 5), 0)
	_down(corpse)

	var tiles: Array[Vector2i] = CombatManager.get_spell_targets(caster, "raise_dead")
	if not corpse.grid_position in tiles:
		_fail("a dead ally's tile is not offered as a target for raise_dead — "
			+ "the spell cannot be aimed at the person it exists for")
	_cleanup([caster, corpse])
	_done()


## Out of combat, resurrection reaches the record of the dead rather than a unit
## on a grid. That record is what lets an event offer it at all.
func _check_the_fallen_are_recorded_and_can_be_raised() -> void:
	var saved_party: Array = CharacterSystem.party.duplicate()
	var saved_fallen: Array = CharacterSystem.fallen.duplicate()
	CharacterSystem.party.clear()
	CharacterSystem.fallen.clear()

	for who in ["Leader", "Doomed"]:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["name"] = who
		CharacterSystem.party.append(c)

	if not CharacterSystem.record_fallen(1, "killed in battle"):
		_fail("record_fallen refused a valid companion")
	if CharacterSystem.party.size() != 1:
		_fail("the fallen companion is still in the party")
	if CharacterSystem.get_fallen().size() != 1:
		_fail("the fallen companion was not recorded — an event has nobody to raise")

	var raised: Dictionary = CharacterSystem.restore_fallen(0, 50)
	if raised.is_empty():
		_fail("restore_fallen returned nobody")
	elif CharacterSystem.party.size() != 2:
		_fail("the raised companion did not rejoin the party")
	elif raised.get("derived", {}).get("current_hp", 0) <= 0:
		_fail("the raised companion came back at %d hp"
			% raised.get("derived", {}).get("current_hp", 0))
	if not CharacterSystem.get_fallen().is_empty():
		_fail("the raised companion is still listed among the dead")

	CharacterSystem.party.assign(saved_party)
	CharacterSystem.fallen.assign(saved_fallen)
	_done()


## The checks above call _apply_spell_effects directly, which skips target
## resolution entirely — so reverting `single_corpse` to bleeding-out-only left
## every one of them green while the spell became uncastable at a corpse. This
## one goes through cast_spell, the way the game does.
func _check_raise_dead_cast_end_to_end() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 15)
	caster.character_data["skills"] = {"white_magic": 9, "sorcery": 9}
	caster.current_mana = 500
	caster.actions_remaining = 2
	CombatManager.turn_order = [caster]
	CombatManager.current_unit_index = 0

	var corpse := _make_unit(Vector2i(6, 5), 0)
	_down(corpse)

	var result: Dictionary = CombatManager.cast_spell(caster, "raise_dead", corpse.grid_position)
	if not result.get("success", false):
		_fail("casting raise_dead at a dead ally failed: %s"
			% str(result.get("reason", "?")))
	elif corpse.is_dead:
		_fail("raise_dead reported success and the ally is still dead — the "
			+ "cast found no targets")

	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([caster, corpse])
	_done()


# ── Save gates, kill rewards, resource operations ────────────────────────────

## Midas Touch is 300 mana — the most expensive spell in the game — and did
## nothing. A hard save resists it entirely; failing it is death.
func _check_failed_save_kills_and_passed_save_does_not() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 40)
	# A feeble victim fails; a formidable one passes. The save is the spell.
	var feeble := _make_unit(Vector2i(6, 5), 1)
	feeble.character_data["attributes"]["constitution"] = 1
	var stout := _make_unit(Vector2i(7, 5), 1)
	stout.character_data["attributes"]["constitution"] = 80

	var spell: Dictionary = CombatManager.get_spell("midas_touch")
	var feeble_deaths := 0
	var stout_deaths := 0
	for _i in 12:
		feeble.is_dead = false
		feeble.current_hp = feeble.max_hp
		stout.is_dead = false
		stout.current_hp = stout.max_hp
		CombatManager._apply_spell_effects(caster, feeble, spell, 0)
		CombatManager._apply_spell_effects(caster, stout, spell, 0)
		if feeble.current_hp <= 0:
			feeble_deaths += 1
		if stout.current_hp <= 0:
			stout_deaths += 1

	if feeble_deaths == 0:
		_fail("midas_touch killed nobody across 12 casts at a constitution-1 target")
	if stout_deaths >= feeble_deaths:
		_fail("midas_touch killed a constitution-80 target %d times and a "
			% stout_deaths + "constitution-1 target %d — the save is not gating it"
			% feeble_deaths)
	_cleanup([caster, feeble, stout])
	_done()


## And what is left is worth taking.
func _check_a_kill_can_pay_gold() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 40)
	caster.team = 0
	var victim := _make_unit(Vector2i(6, 5), 1)
	victim.character_data["attributes"]["constitution"] = 1
	victim.character_data["xp_earned"] = 2000

	var before: int = GameState.gold
	var spell: Dictionary = CombatManager.get_spell("midas_touch")
	for _i in 12:
		victim.is_dead = false
		victim.current_hp = victim.max_hp
		CombatManager._apply_spell_effects(caster, victim, spell, 0)
	if GameState.gold <= before:
		_fail("midas_touch killed its target repeatedly and paid no gold")
	GameState.gold = before
	_cleanup([caster, victim])
	_done()


## A pauper is not worth as much as a champion.
func _check_gold_scales_with_what_was_killed() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 40)
	var spell: Dictionary = CombatManager.get_spell("midas_touch")

	var earned := []
	for worth in [100, 5000]:
		var victim := _make_unit(Vector2i(6, 5), 1)
		victim.character_data["attributes"]["constitution"] = 1
		victim.character_data["xp_earned"] = worth
		var before: int = GameState.gold
		for _i in 12:
			victim.is_dead = false
			victim.current_hp = victim.max_hp
			CombatManager._apply_spell_effects(caster, victim, spell, 0)
		earned.append(GameState.gold - before)
		GameState.gold = before
		_cleanup([victim])

	# Fifty times the worth should pay far more than fifty times nothing. A
	# plain ">" is not enough: a nat 20 always saves, so the two runs kill
	# slightly different numbers of times and a flat, unscaled reward can come
	# out ahead on kill count alone.
	if earned[1] < earned[0] * 10:
		_fail("killing a 5000-xp enemy paid %d and a 100-xp one paid %d — the "
			% [earned[1], earned[0]] + "reward is not scaling with what died")
	_cleanup([caster])
	_done()


## The gate carries statuses too — this is what metal_to_mud used to do through
## its own separate field, and it must survive the consolidation.
func _check_save_gate_statuses_still_apply() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 40)
	var victim := _make_unit(Vector2i(6, 5), 1)
	victim.character_data["attributes"]["constitution"] = 1

	var spell: Dictionary = CombatManager.get_spell("metal_to_mud")
	var landed := false
	for _i in 12:
		victim.status_effects.clear()
		CombatManager._apply_spell_effects(caster, victim, spell, 0)
		if victim.has_status("Armor_Reduced") or victim.has_status("Damage_Debuff"):
			landed = true
			break
	if not landed:
		_fail("metal_to_mud never applied its statuses across 12 casts at a "
			+ "constitution-1 target")
	_cleanup([caster, victim])
	_done()


## Bitter Word's author note was the specification: the damage always applies
## and the save is only against the silence. So a target who passes every save
## must still be taking damage.
func _check_damage_lands_regardless_of_the_save() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 10)
	var stout := _make_unit(Vector2i(6, 5), 1)
	stout.character_data["attributes"]["focus"] = 80

	var spell: Dictionary = CombatManager.get_spell("bitter_word")
	var before: int = stout.current_hp
	for _i in 6:
		CombatManager._apply_spell_effects(caster, stout, spell, 0)
	if stout.current_hp >= before:
		_fail("bitter_word dealt nothing to a target who resisted the silence — "
			+ "the damage is being gated on the save it should not be")
	_cleanup([caster, stout])
	_done()


## Mana Drain takes what a caster is holding and keeps it.
func _check_mana_transfer_moves_what_was_there() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 20)
	var victim := _make_unit(Vector2i(6, 5), 1)
	caster.max_mana = 300
	caster.current_mana = 50
	victim.max_mana = 200
	victim.current_mana = 200

	var spell: Dictionary = CombatManager.get_spell("mana_drain")
	CombatManager._apply_spell_effects(caster, victim, spell, 0)

	if victim.current_mana >= 200:
		_fail("mana_drain left the victim with %d of 200 mana" % victim.current_mana)
	if caster.current_mana <= 50:
		_fail("mana_drain took the victim's mana and gave the caster none "
			+ "(still %d)" % caster.current_mana)
	_cleanup([caster, victim])
	_done()


## Draining an empty pool must not conjure the resource. A transfer hands on
## only what was actually there.
func _check_a_transfer_cannot_create_what_is_not_there() -> void:
	var caster := _make_unit(Vector2i(5, 5), 0, 20)
	var victim := _make_unit(Vector2i(6, 5), 1)
	caster.max_mana = 300
	caster.current_mana = 10
	victim.max_mana = 200
	victim.current_mana = 0

	var spell: Dictionary = CombatManager.get_spell("mana_drain")
	CombatManager._apply_spell_effects(caster, victim, spell, 0)
	if caster.current_mana != 10:
		_fail("draining an empty caster gave the thief %d mana, up from 10"
			% caster.current_mana)
	if victim.current_mana < 0:
		_fail("the victim's mana went negative: %d" % victim.current_mana)
	_cleanup([caster, victim])
	_done()
