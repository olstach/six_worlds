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
const EXPECTED_CHECKS: int = 10


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
