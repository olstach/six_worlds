extends Node
## Headless verification for the shared effect language (EffectVocab and, in
## later tasks, ValuePaths and EffectResolver).
##
## Run: godot --headless res://tools/verify_effects.tscn
##
## Exits non-zero if any assertion fails.

var failures: int = 0

## A runtime error inside a check aborts it and returns control to _ready(),
## which would then find no failures and report OK having verified nothing.
## Each check calls _done() as its last line; _ready() compares the count.
var checks_run: int = 0
const EXPECTED_CHECKS: int = 10

var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	_check_vocab_accepts_valid_effects()
	_check_vocab_rejects_invalid_effects()

	# ValuePaths: stat. and resist. holds, read through the real getters.
	_check_fortify_and_release_dodge()
	_check_same_source_replaces_not_stacks()
	_check_multiply_then_set()
	_check_resist_hold_changes_damage_taken()

	# attribute. and skill. holds, and the one shared attribute formula.
	_check_attribute_terms_match_both_formulas()
	_check_fortify_finesse_moves_dodge_and_initiative()
	_check_fortify_constitution_raises_max_hp_and_clamps_on_release()
	_check_skill_hold_reaches_effective_level()

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


# ── EffectVocab ──────────────────────────────────────────────────────────────

func _check_vocab_accepts_valid_effects() -> void:
	for e in [
		{"op": "damage", "amount": 20, "type": "fire"},
		{"op": "damage", "amount": 30, "type": {"fire": 0.5, "black": 0.5}},
		{"op": "heal", "amount": "full"},
		{"op": "modify", "value": "attribute.strength", "mode": "fortify", "amount": 3},
		{"op": "modify", "value": "resource.mana", "mode": "absorb", "amount": {"base": 10, "per_spellpower": 0.5}},
		{"op": "modify", "value": "stat.movement", "mode": "set", "amount": 0},
		{"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 2,
		 "cleared_by": [{"rest": "full"}, {"heal": {"school": "white", "min_level": 5}}]},
		{"op": "status", "action": "apply", "status": "Burning", "chance": 50},
		{"op": "kill", "save": {"stat": "constitution", "tier": "hard"}, "on_save": "fail"},
	]:
		var errs := EffectVocab.validate(e, "test")
		if not errs.is_empty():
			_fail("valid effect rejected: %s → %s" % [e, errs])
	_done()


func _check_vocab_rejects_invalid_effects() -> void:
	var cases := {
		"unknown op": {"op": "explode"},
		"unknown namespace": {"op": "modify", "value": "mood.happy", "mode": "fortify", "amount": 1},
		"unknown attribute": {"op": "modify", "value": "attribute.wisdom", "mode": "fortify", "amount": 1},
		"mode not allowed for namespace": {"op": "modify", "value": "resource.hp", "mode": "fortify", "amount": 5},
		"unknown status": {"op": "status", "action": "apply", "status": "Not_A_Status"},
		"unknown shared field": {"op": "heal", "amount": 5, "chanse": 50},
		"unknown condition": {"op": "heal", "amount": 5, "if": ["on_a_tuesday"]},
		"unknown cleared_by kind": {"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 1, "cleared_by": [{"prayer": true}]},
		"damage-type split not summing to 1": {"op": "damage", "amount": 10, "type": {"fire": 0.5, "black": 0.4}},
	}
	for label in cases:
		if EffectVocab.validate(cases[label], "test").is_empty():
			_fail("invalid effect accepted (%s): %s" % [label, cases[label]])
	_done()


# ── Fixtures ─────────────────────────────────────────────────────────────────

## A bare unit on the grid, copied from verify_auras.gd.
func _make_unit(at: Vector2i, team: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 100
	unit.current_hp = 100
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


# ── ValuePaths: stat. and resist. ────────────────────────────────────────────

func _check_fortify_and_release_dodge() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var base: int = u.get_dodge()
	ValuePaths.add_hold(u, "stat.dodge", "fortify", 7, "t1")
	if u.get_dodge() != base + 7:
		_fail("fortify +7 on stat.dodge: got %d, wanted %d" % [u.get_dodge(), base + 7])
	ValuePaths.release(u, "t1")
	if u.get_dodge() != base:
		_fail("release did not restore dodge: got %d, wanted %d" % [u.get_dodge(), base])
	_cleanup([u])
	_done()


func _check_same_source_replaces_not_stacks() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var base: int = u.get_dodge()
	ValuePaths.add_hold(u, "stat.dodge", "fortify", 5, "t1")
	ValuePaths.add_hold(u, "stat.dodge", "fortify", 9, "t1")
	if u.get_dodge() != base + 9:
		_fail("same (value, source) should replace: got %d, wanted %d" % [u.get_dodge(), base + 9])
	if ValuePaths.holds_on(u, "stat.dodge").size() != 1:
		_fail("holds_on should list exactly one hold after a replace")
	_cleanup([u])
	_done()


func _check_multiply_then_set() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var base: int = u.get_initiative()
	ValuePaths.add_hold(u, "stat.initiative", "fortify", 10, "t1")
	ValuePaths.add_hold(u, "stat.initiative", "multiply", 2.0, "t2")
	if u.get_initiative() != (base + 10) * 2:
		_fail("fortify then multiply: got %d, wanted %d" % [u.get_initiative(), (base + 10) * 2])
	ValuePaths.add_hold(u, "stat.initiative", "set", 0, "t3")
	if u.get_initiative() != 0:
		_fail("set 0 should win: got %d" % u.get_initiative())
	ValuePaths.release(u, "t3")
	if u.get_initiative() != (base + 10) * 2:
		_fail("releasing the set should bring back %d, got %d" % [(base + 10) * 2, u.get_initiative()])
	_cleanup([u])
	_done()


## HP lost to one 100-damage hit of `type` on a fresh unit with the given hold.
func _hp_lost(value: String, amount: float, type: String) -> int:
	var u := _make_unit(Vector2i(5, 5))
	if value != "":
		ValuePaths.add_hold(u, value, "fortify", amount, "t1")
	u.current_hp = 100
	CombatManager.apply_damage(u, 100, type)
	var lost: int = 100 - u.current_hp
	_cleanup([u])
	return lost


func _check_resist_hold_changes_damage_taken() -> void:
	var plain: int = _hp_lost("", 0, "fire")
	var held: int = _hp_lost("resist.fire", 50, "fire")
	if absi(held - plain / 2) > 1:
		_fail("resist.fire +50 should halve fire damage: %d -> %d" % [plain, held])
	var group: int = _hp_lost("resist.all_elemental", 50, "fire")
	if absi(group - plain / 2) > 1:
		_fail("resist.all_elemental +50 should halve fire damage: %d -> %d" % [plain, group])
	# And it must NOT cover a non-elemental type.
	var phys_plain: int = _hp_lost("", 0, "slashing")
	var phys_held: int = _hp_lost("resist.all_elemental", 50, "slashing")
	if phys_held != phys_plain:
		_fail("all_elemental must not touch slashing: %d -> %d" % [phys_plain, phys_held])
	_done()


# ── ValuePaths: attribute. and skill. ────────────────────────────────────────

const _TERM_KEYS: Array[String] = ["max_hp", "max_mana", "max_stamina", "initiative",
	"movement", "dodge", "spellpower", "crit_chance"]


func _check_attribute_terms_match_both_formulas() -> void:
	var sets: Array[Dictionary] = [
		{},
		{"constitution": 16, "finesse": 8, "awareness": 14, "focus": 12, "luck": 9},
		{"finesse": 20, "awareness": 20, "luck": 20},
	]
	for overrides in sets:
		var attrs: Dictionary = {"strength": 10, "constitution": 10, "finesse": 10,
			"focus": 10, "awareness": 10, "charm": 10, "luck": 10}
		attrs.merge(overrides, true)
		var terms: Dictionary = CombatStats.attribute_terms(attrs)
		# Player formula: a blank character with no gear or traits.
		var ch: Dictionary = CharacterSystem.create_blank_character()
		ch.attributes = attrs.duplicate()
		ch.equipment = {}
		ch.traits = []
		CharacterSystem.update_derived_stats(ch)
		var enemy: Dictionary = EnemySystem._calculate_derived_stats(attrs, {})
		for key in _TERM_KEYS:
			if ch.derived.get(key) != terms[key]:
				_fail("player %s %s: derived %s vs terms %s" % [overrides, key, ch.derived.get(key), terms[key]])
			if enemy.get(key) != terms[key]:
				_fail("enemy %s %s: derived %s vs terms %s" % [overrides, key, enemy.get(key), terms[key]])
	_done()


func _check_fortify_finesse_moves_dodge_and_initiative() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var fin: int = u.character_data.attributes.finesse
	var dodge: int = u.get_dodge()
	var init: int = u.get_initiative()
	var move: int = u.get_movement()
	ValuePaths.add_hold(u, "attribute.finesse", "fortify", 6, "t1")
	if u.get_dodge() != dodge + 6:
		_fail("finesse +6 dodge: got %d, wanted %d" % [u.get_dodge(), dodge + 6])
	if u.get_initiative() != init + 6:
		_fail("finesse +6 initiative: got %d, wanted %d" % [u.get_initiative(), init + 6])
	var want_move: int = move + int((fin + 6) / 3) - int(fin / 3)
	if u.get_movement() != want_move:
		_fail("finesse +6 movement: got %d, wanted %d" % [u.get_movement(), want_move])
	ValuePaths.release(u, "t1")
	if u.get_dodge() != dodge or u.get_initiative() != init or u.get_movement() != move:
		_fail("release did not restore dodge/initiative/movement")
	if not u.effect_holds.is_empty():
		_fail("release left holds behind: %s" % [u.effect_holds])
	_cleanup([u])
	_done()


func _check_fortify_constitution_raises_max_hp_and_clamps_on_release() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var old_max: int = u.max_hp
	ValuePaths.add_hold(u, "attribute.constitution", "fortify", 5, "t1")
	if u.max_hp != old_max + 50:
		_fail("con +5 max_hp: got %d, wanted %d" % [u.max_hp, old_max + 50])
	u.current_hp = u.max_hp
	ValuePaths.release(u, "t1")
	if u.max_hp != old_max:
		_fail("release max_hp: got %d, wanted %d" % [u.max_hp, old_max])
	if u.current_hp != u.max_hp:
		_fail("current_hp should clamp to %d, got %d" % [u.max_hp, u.current_hp])
	_cleanup([u])
	_done()


func _check_skill_hold_reaches_effective_level() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var ch: Dictionary = u.character_data
	var base: int = CharacterSystem.get_effective_skill_level(ch, "swords")
	var had_entry: bool = ch.get("skill_bonuses", {}).has("swords")
	ValuePaths.add_hold(u, "skill.swords", "fortify", 2, "t1")
	if CharacterSystem.get_effective_skill_level(ch, "swords") != base + 2:
		_fail("skill.swords +2 not reflected in effective level")
	ValuePaths.add_hold(u, "skill.swords", "drain", 1, "t2")
	if CharacterSystem.get_effective_skill_level(ch, "swords") != base + 1:
		_fail("fortify 2 + drain 1 should be +1")
	ValuePaths.release(u, "t1")
	ValuePaths.release(u, "t2")
	if CharacterSystem.get_effective_skill_level(ch, "swords") != base:
		_fail("release did not restore the skill level")
	if ch.get("skill_bonuses", {}).has("swords") != had_entry:
		_fail("skill_bonuses entry for swords left behind after release")
	_cleanup([u])
	_done()
