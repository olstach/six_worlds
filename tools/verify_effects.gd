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
const EXPECTED_CHECKS: int = 108

var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	_check_vocab_accepts_valid_effects()
	_check_vocab_rejects_invalid_effects()
	_check_status_valid_minimal()
	_check_status_rejects()
	_check_cleanse_clears_damage()

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

	# Holds are combat-scoped: end_combat must wipe them.
	_check_holds_do_not_survive_end_combat()

	# Persistent `damage` mode and what clears it.
	_check_add_hold_refuses_damage_and_restore()
	_check_damage_mode_persists_past_combat()
	_check_damage_mode_counts_once_after_combat()
	_check_midfight_recompute_does_not_double_count()
	_check_full_rest_clears_but_camp_does_not()
	_check_heal_clear_respects_school_and_level()
	_check_heal_clear_accepts_white_magic_spelling()
	_check_restore_clears_all_or_by_amount()
	_check_damage_mode_on_enemy_is_fight_only()
	_check_damaged_values_survive_save_round_trip()

	# EffectResolver: shared fields and the damage / heal / modify ops.
	_check_resolver_damage_and_split()
	_check_resolver_heal_full()
	_check_resolver_absorb_mana()
	_check_resolver_modify_needs_hold_source()
	_check_save_rolled_once_for_both_branches()
	_check_chance_zero_and_hundred()
	_check_bonus_vs_and_scale()
	_check_if_condition_blocks()
	_check_resolver_refuses_invalid_effect()
	_check_heal_clearing_held_damage_lifts_it_now()
	_check_resolver_restore_by_amount()

	# The delegating ops: status, move, kill, summon, zone, resurrect.
	_check_status_apply_and_remove()
	_check_move_push_one_tile()
	_check_kill_refused_on_boss()
	_check_kill_immune_override()
	_check_summon_count()
	_check_zone_created()
	_check_resurrect_raises_the_dead()
	_check_summon_once_for_area_recipients()
	_check_summon_from_target_pos_only()
	_check_position_op_without_position_refused()

	# Stage 2a: skill bonuses are an uncapped formula.
	_check_curve_climb_swords()
	_check_curve_continues_past_ten()
	_check_curve_limit_holds()
	_check_effective_skill_level_uncapped()
	_check_integer_curve_floors()
	_check_purge_uses_uncapped_effective_level()

	# Stage 2a: attribute holds live on the character; refreshed mid-fight.
	_check_skill_hold_raises_per_level_bonus_midfight()
	_check_attribute_hold_no_current_hp_jump()
	_check_enemy_refresh()

	# Stage 2a: every reader of ability sees the effective value.
	_check_skill_hold_unlocks_casting()
	_check_skill_hold_raises_spell_bonus()
	_check_attribute_hold_reaches_saves()
	_check_skill_hold_reaches_affinity()
	_check_shop_learning_ignores_boost()
	_check_hold_on_unbought_skill_counts_fully()
	_check_party_size_capped_at_deploy_slots()
	_check_unknown_attribute_reads_zero()

	# Stage 2b: enemies use the one character sheet.
	_check_enemy_sheet_matches_party()
	_check_enemy_skill_accuracy()
	_check_enemy_kit_variants()
	_check_map_buff_reaches_off_roster_companion()

	# Stage 2b: the status container (holds, single exit, periodic, immunity).
	_check_status_hold_applies_and_releases()
	_check_status_attribute_hold_refreshes()
	_check_every_exit_releases()
	_check_refresh_does_not_double()
	_check_stack_scales_holds()
	_check_periodic_damage_ticks()
	_check_expire_trigger_fires_on_expiry_only()
	_check_immune_flag_blocks()
	_check_old_save_entries_get_ids()

	# Stage 2b, Task 4: statuses migrated — their numbers are effects now.
	_check_status_numbers_match_baseline()
	_check_status_tags_select_same()

	# Stage 2b, Task 5: the yes/no words are flags now.
	_check_flags_match_old_words()
	_check_concentration_breaks_on_flag()
	_check_mental_immunity_by_flag()

	# Stage 2b, Task 6: behaviour is triggers, periodic effects and intercepts.
	_check_dot_uses_spell_value()
	_check_retaliation_trigger()
	_check_expire_summon()
	_check_intercept_negate()
	_check_borrowed_value()
	_check_no_legacy_status_keys()
	_check_behaviour_numbers_match_today()

	# Stage 2b, Task 7: the stage-1 carry-overs.
	_check_status_op_reports_resisted()
	_check_multi_school_cleared_by()
	_check_breakdown_lists_holds()

	# Stage 2b, Task 8: auras and zones are effect lists; auras are read-time.
	_check_aura_numbers_match_baseline()
	_check_zone_effects_resolve()
	_check_grave_soil_raises()
	_check_aura_breakdown_label()
	_check_aura_affliction_resistance()
	_check_aura_zone_validation()

	# Stage 2b, Task 9: group targets, affinity and pressure as values.
	_check_group_skill_hold()
	_check_group_attributes_all()
	_check_affinity_hold()
	_check_pressure_modify()

	# Stage 2b, Task 10: building states, comedown, upkeep.
	_check_mantra_state_example()
	_check_hp_upkeep_never_kills()
	_check_building_state_validation()

	# Stage 2b final review: the fix wave.
	_check_final_review_validation()
	_check_scatter_reads_tiles_as_range()
	_check_zero_damage_reaches_spells_only()
	_check_dead_source_gets_nothing()
	_check_upkeep_end_is_an_expiry()

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
	# Test-only status definitions live for one check.
	for name in _test_statuses:
		CombatManager._status_effects.erase(name)
	_test_statuses.clear()


## Names registered by _with_test_status(), erased again by _done().
var _test_statuses: Array[String] = []


## Register `def` as a status definition for the current check only, under a
## fresh name beginning `__test_`, and return that name. Real statuses.json
## data gets the new fields in a later task, so the container is tested on
## definitions made here. _done() removes them after the check.
func _with_test_status(def: Dictionary) -> String:
	var name: String = "__test_%d" % (checks_run * 100 + _test_statuses.size())
	CombatManager._status_effects[name] = def
	_test_statuses.append(name)
	return name


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


# ── Status shape (stage 2b) ──────────────────────────────────────────────────

func _minimal_status() -> Dictionary:
	return {"name": "Held", "icon": "x", "polarity": "negative", "categories": ["control"],
		"scope": "combat", "duration": {"kind": "turns", "base": 1}, "stacking": {"mode": "refresh"}}


func _check_status_valid_minimal() -> void:
	var errs := EffectVocab.validate_status(_minimal_status(), "test")
	if not errs.is_empty():
		_fail("minimal status rejected: %s" % [errs])
	var fire := _minimal_status()
	fire["categories"] = ["elemental.fire"]
	fire["flags"] = ["immune:poison"]
	errs = EffectVocab.validate_status(fire, "test")
	if not errs.is_empty():
		_fail("elemental category / immune flag rejected: %s" % [errs])
	_done()


func _check_status_rejects() -> void:
	var cases := {
		"unknown field": {"flavour": "x"},
		"unknown category": {"categories": ["spooky"]},
		"elemental.plasma": {"categories": ["elemental.plasma"]},
		"while_active restore": {"while_active": [{"op": "modify",
			"value": "attribute.focus", "mode": "restore", "amount": 1}]},
		"unknown flag": {"flags": ["flying"]},
		"unknown trigger": {"triggers": [{"on": "tuesday", "effects": []}]},
		"stacking strongest": {"stacking": {"mode": "strongest"}},
	}
	for label in cases:
		var d := _minimal_status()
		d.merge(cases[label], true)
		if EffectVocab.validate_status(d, "test").is_empty():
			_fail("invalid status accepted (%s)" % label)
	_done()


## A curse recorded with source_categories is undone when a status of that
## category is cleansed off the unit, through the real CombatManager path.
func _check_cleanse_clears_damage() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	var ctx := _ctx(caster, u, "black", 1)
	ctx.source_categories = ["curse"]
	EffectResolver.resolve([{"op": "modify", "value": "attribute.focus", "mode": "damage",
		"amount": 2, "cleared_by": [{"cleanse": {"category": "curse"}}]}], ctx)
	if ch.get("damaged_values", []).size() != 1 \
			or ch.damaged_values[0].get("source_categories", []) != ["curse"]:
		_fail("damage entry did not record source_categories: %s" % [ch.get("damaged_values", [])])
	# A different category does not clear it; a rest does not either.
	if ValuePaths.clear_damage(ch, "cleanse", {"category": "poison"}) != 0 \
			or ValuePaths.clear_damage(ch, "rest", {"tier": 3}) != 0:
		_fail("cleanse of another category (or a rest) cleared the curse")
	# Cleanse the status off the unit the way a dispel does.
	CombatManager._status_effects["VerifyCurse"] = {"polarity": "negative", "dispellable": true,
		"categories": ["curse", "magical"]}
	u.status_effects.append({"status": "VerifyCurse", "duration": 3})
	CombatManager._cleanse_status_effects(u, 1)
	CombatManager._status_effects.erase("VerifyCurse")
	if not ch.get("damaged_values", []).is_empty():
		_fail("cleansing a curse-category status left %s" % [ch.damaged_values])
	_end_fight()
	_leave_party(u)
	_cleanup([caster, u])
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
		# Enemy: a sheet built by EnemySystem, stripped to the same bare
		# inputs (no gear, skills, traits or perks), through the same formula.
		# EnemySystem has no formula of its own any more; this checks that an
		# enemy's sheet carries nothing that bends the attribute terms.
		var enemy_sheet: Dictionary = EnemySystem._build_enemy("hell_demon_warrior", 200, "hell")
		enemy_sheet.attributes = attrs.duplicate()
		enemy_sheet.equipment = {}
		enemy_sheet.traits = []
		enemy_sheet.perks = []
		enemy_sheet.skills = {}
		enemy_sheet.skill_bonuses = {}
		enemy_sheet.racial_affinity_bonuses = {}
		CharacterSystem.update_derived_stats(enemy_sheet)
		var enemy: Dictionary = enemy_sheet.derived
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


# ── Holds end with the fight ─────────────────────────────────────────────────

## A fortify/drain applied in combat must be gone from character_data once the
## real end_combat() has run. end_combat() returns early unless combat_active,
## so the flag is set the way verify_combat_systems.gd does it.
func _check_holds_do_not_survive_end_combat() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var ch: Dictionary = u.character_data
	var attrs_before: Dictionary = ch.attributes.duplicate()
	var derived_before: Dictionary = ch.derived.duplicate()
	var skill_before: int = CharacterSystem.get_effective_skill_level(ch, "swords")
	var bonuses_before: Dictionary = ch.get("skill_bonuses", {}).duplicate(true)
	var max_hp_before: int = u.max_hp

	ValuePaths.add_hold(u, "attribute.strength", "fortify", 4, "t1")
	ValuePaths.add_hold(u, "attribute.constitution", "fortify", 3, "t2")
	ValuePaths.add_hold(u, "skill.swords", "fortify", 2, "t3")
	ValuePaths.add_hold(u, "stat.dodge", "fortify", 2, "t4")
	if u.max_hp == max_hp_before:
		_fail("setup: constitution hold did not raise max_hp")

	CombatManager.combat_active = true
	CombatManager.end_combat(true)
	CombatManager.combat_grid = grid   # end_combat nulls it; later checks need it

	if not u.effect_holds.is_empty():
		_fail("holds left after end_combat: %s" % [u.effect_holds])
	if ch.attributes != attrs_before:
		_fail("attributes changed: %s vs %s" % [ch.attributes, attrs_before])
	if CharacterSystem.get_effective_skill_level(ch, "swords") != skill_before:
		_fail("swords level not restored after end_combat")
	if ch.get("skill_bonuses", {}) != bonuses_before:
		_fail("skill_bonuses not restored: %s" % [ch.get("skill_bonuses", {})])
	if u.max_hp != max_hp_before:
		_fail("max_hp after end_combat: %d, wanted %d" % [u.max_hp, max_hp_before])
	# Every derived key must match exactly, except current_hp: end_combat
	# legitimately copies the unit's HP into derived (the unit starts at 100,
	# the blank character's own value may differ), so expect that copy.
	for key in derived_before:
		var want = derived_before[key]
		if key == "current_hp":
			want = u.current_hp
		if ch.derived.get(key) != want:
			_fail("derived.%s: got %s, wanted %s" % [key, ch.derived.get(key), want])
	if u.current_hp > u.max_hp:
		_fail("current_hp %d above max_hp %d" % [u.current_hp, u.max_hp])
	_cleanup([u])
	_done()


# ── Persistent `damage` mode and cleared_by ──────────────────────────────────

## Make `unit`'s character a real party member (ValuePaths treats a team-0 unit
## whose character is in the party as the persistent case). Undo with
## _leave_party().
func _join_party(unit: CombatUnit) -> void:
	CharacterSystem.get_party().append(unit.character_data)


func _leave_party(unit: CombatUnit) -> void:
	CharacterSystem.get_party().erase(unit.character_data)


## Run the real end_combat() on a lost fight (a loss skips the reward maths).
func _end_fight() -> void:
	CombatManager.combat_active = true
	CombatManager.end_combat(false)
	CombatManager.combat_grid = grid   # end_combat nulls it; later checks need it


func _check_add_hold_refuses_damage_and_restore() -> void:
	var u := _make_unit(Vector2i(5, 5))
	ValuePaths.add_hold(u, "attribute.focus", "damage", 2, "t1")
	ValuePaths.add_hold(u, "skill.swords", "restore", 1, "t2")
	if not u.effect_holds.is_empty():
		_fail("add_hold must refuse damage/restore on attribute./skill.: %s" % [u.effect_holds])
	_cleanup([u])
	_done()


func _check_damage_mode_persists_past_combat() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	var before: int = int(ch.derived.spellpower)
	var attrs: Dictionary = ch.attributes.duplicate()
	var hurt: Dictionary = attrs.duplicate()
	hurt["focus"] = int(hurt["focus"]) - 2
	var lost: int = int(CombatStats.attribute_terms(attrs).spellpower) \
		- int(CombatStats.attribute_terms(hurt).spellpower)
	if lost <= 0:
		_fail("setup: 2 focus should cost some spellpower")

	ValuePaths.apply_damage_mode(u, "attribute.focus", 2.0, [{"rest": "full"}], "curse")
	_end_fight()

	if ValuePaths.damaged_total(ch, "attribute.focus") != 2.0:
		_fail("damaged_total after combat: %s" % ValuePaths.damaged_total(ch, "attribute.focus"))
	if int(ch.derived.spellpower) != before - lost:
		_fail("spellpower after combat: %d, wanted %d" % [int(ch.derived.spellpower), before - lost])
	if int(ch.attributes.focus) != int(attrs.focus):
		_fail("base focus must not be edited; the damage is a separate entry")
	_leave_party(u)
	_cleanup([u])
	_done()


## The loss must bite during the fight AND after it, but only once.
func _check_damage_mode_counts_once_after_combat() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	var before: int = u.get_spellpower()
	var attrs: Dictionary = ch.attributes.duplicate()
	var hurt: Dictionary = attrs.duplicate()
	hurt["focus"] = int(hurt["focus"]) - 3
	var lost: int = int(CombatStats.attribute_terms(attrs).spellpower) \
		- int(CombatStats.attribute_terms(hurt).spellpower)

	ValuePaths.apply_damage_mode(u, "attribute.focus", 3.0, [], "curse")
	if u.get_spellpower() != before - lost:
		_fail("during the fight spellpower: %d, wanted %d" % [u.get_spellpower(), before - lost])
	_end_fight()
	if int(ch.derived.spellpower) != before - lost:
		_fail("after the fight spellpower: %d, wanted %d (not %d)"
			% [int(ch.derived.spellpower), before - lost, before - 2 * lost])
	_leave_party(u)
	_cleanup([u])
	_done()


## A wound (or a cure) re-runs update_derived_stats mid-fight. The loss must
## stay N, not 2N, then still be N after the fight.
func _check_midfight_recompute_does_not_double_count() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	var before: int = u.get_spellpower()
	var attrs: Dictionary = ch.attributes.duplicate()
	var hurt: Dictionary = attrs.duplicate()
	hurt["focus"] = int(hurt["focus"]) - 3
	var lost: int = int(CombatStats.attribute_terms(attrs).spellpower) \
		- int(CombatStats.attribute_terms(hurt).spellpower)
	ValuePaths.apply_damage_mode(u, "attribute.focus", 3.0, [], "curse")
	CharacterSystem.update_derived_stats(ch)   # as the wound path does
	if u.get_spellpower() != before - lost:
		_fail("mid-fight recompute: spellpower %d, wanted %d (double would be %d)"
			% [u.get_spellpower(), before - lost, before - 2 * lost])
	_end_fight()
	if int(ch.derived.spellpower) != before - lost:
		_fail("after the fight spellpower: %d, wanted %d" % [int(ch.derived.spellpower), before - lost])
	_leave_party(u)
	_cleanup([u])
	_done()


func _check_full_rest_clears_but_camp_does_not() -> void:
	var ch: Dictionary = CharacterSystem.create_blank_character()
	ch["damaged_values"] = [{"value": "attribute.focus", "amount": 2,
		"cleared_by": [{"rest": "full"}], "source": "curse"}]
	if ValuePaths.clear_damage(ch, "rest", {"tier": 2}) != 0 or ch.damaged_values.size() != 1:
		_fail("a camp rest must not clear a full-rest damage")
	if ValuePaths.clear_damage(ch, "rest", {"tier": 3}) != 1 or not ch.damaged_values.is_empty():
		_fail("a full rest must clear it")
	# A quick rest clears a {"rest": "quick"} entry, and the default is full rest.
	ch["damaged_values"] = [
		{"value": "skill.swords", "amount": 1, "cleared_by": [{"rest": "quick"}], "source": "a"},
		{"value": "skill.axes", "amount": 1, "source": "b"}]
	if ValuePaths.clear_damage(ch, "rest", {"tier": 1}) != 1:
		_fail("a quick rest should clear only the quick-rest entry")
	if ValuePaths.clear_damage(ch, "rest", {"tier": 2}) != 0:
		_fail("default cleared_by is full rest, not camp")
	if ValuePaths.clear_damage(ch, "rest", {"tier": 3}) != 1:
		_fail("default cleared_by should clear on a full rest")
	_done()


func _check_heal_clear_respects_school_and_level() -> void:
	var ch: Dictionary = CharacterSystem.create_blank_character()
	ch["damaged_values"] = [{"value": "attribute.focus", "amount": 2, "source": "curse",
		"cleared_by": [{"heal": {"school": "white", "min_level": 5}}]}]
	if ValuePaths.clear_damage(ch, "heal", {"school": "white", "level": 3}) != 0:
		_fail("a white L3 heal must not clear a min_level 5 damage")
	if ValuePaths.clear_damage(ch, "heal", {"school": "fire", "level": 7}) != 0:
		_fail("a fire L7 heal must not clear a white-only damage")
	if ValuePaths.clear_damage(ch, "heal", {"school": "white", "level": 5}) != 1:
		_fail("a white L5 heal should clear it")
	if not ch.damaged_values.is_empty():
		_fail("the cleared entry is still there")
	_done()


## The validators accept "white_magic" as well as "white"; both must match a
## heal whose school is stored as "white".
func _check_heal_clear_accepts_white_magic_spelling() -> void:
	var ch: Dictionary = CharacterSystem.create_blank_character()
	ch["damaged_values"] = [{"value": "attribute.focus", "amount": 2, "source": "curse",
		"cleared_by": [{"heal": {"school": "white_magic", "min_level": 5}}]}]
	if ValuePaths.clear_damage(ch, "heal", {"school": "white", "level": 5}) != 1:
		_fail("a white L5 heal should clear a white_magic-spelled entry")
	_done()


func _check_restore_clears_all_or_by_amount() -> void:
	var ch: Dictionary = CharacterSystem.create_blank_character()
	ch["damaged_values"] = [
		{"value": "attribute.focus", "amount": 3, "source": "a"},
		{"value": "attribute.focus", "amount": 2, "source": "b"},
		{"value": "attribute.luck", "amount": 1, "source": "c"}]
	# Default cleared_by includes {"restore": <own value>}.
	if ValuePaths.clear_damage(ch, "restore", {"value": "attribute.strength"}) != 0:
		_fail("restoring another value must clear nothing")
	# 4 points, oldest first: the 3 goes, the 2 drops to 1.
	var cleared: int = ValuePaths.clear_damage(ch, "restore",
		{"value": "attribute.focus", "amount": 4})
	if cleared != 1 or ValuePaths.damaged_total(ch, "attribute.focus") != 1.0:
		_fail("restore amount 4: cleared %d, focus left %s" % [cleared,
			ValuePaths.damaged_total(ch, "attribute.focus")])
	if ValuePaths.clear_damage(ch, "restore", {"value": "attribute.focus"}) != 1:
		_fail("restore with no amount should clear what is left")
	if ValuePaths.damaged_total(ch, "attribute.luck") != 1.0:
		_fail("luck damage must be untouched")
	_done()


func _check_damage_mode_on_enemy_is_fight_only() -> void:
	var u := _make_unit(Vector2i(6, 6), CombatManager.Team.ENEMY)
	var ch: Dictionary = u.character_data
	var attrs_before: Dictionary = ch.attributes.duplicate()
	var dodge: int = u.get_dodge()
	ValuePaths.apply_damage_mode(u, "attribute.finesse", 4.0, [], "curse")
	if u.get_dodge() >= dodge:
		_fail("enemy dodge should drop during the fight: %d -> %d" % [dodge, u.get_dodge()])
	if ch.has("damaged_values") and not ch.damaged_values.is_empty():
		_fail("an enemy must not get persistent damaged_values")
	if ch.attributes != attrs_before:
		_fail("enemy base attributes were edited")
	ValuePaths.release_all_combat(u)
	if u.get_dodge() != dodge:
		_fail("enemy dodge after the fight: %d, wanted %d" % [u.get_dodge(), dodge])
	_cleanup([u])
	_done()


## The round trip runs through SaveManager slot 3, but in a scratch folder: the
## verifier points SaveManager.SAVE_DIR at user://verify_scratch_saves/ for the
## duration, so Olaf's real saves are never opened for writing.
func _check_damaged_values_survive_save_round_trip() -> void:
	var real_dir: String = SaveManager.SAVE_DIR
	var scratch: String = "user://verify_scratch_saves/"
	DirAccess.make_dir_recursive_absolute(scratch)
	SaveManager.SAVE_DIR = scratch
	var old_slot: int = SaveManager.current_slot
	# Snapshot every system the save touches, to put the process back after.
	var snap_game: Dictionary = GameState.get_save_data().duplicate(true)
	var snap_chars: Dictionary = CharacterSystem.get_save_data().duplicate(true)
	var snap_items: Dictionary = ItemSystem.get_save_data().duplicate(true)
	var snap_karma: Dictionary = KarmaSystem.get_save_data().duplicate(true)
	var snap_map: Dictionary = MapManager.get_save_data().duplicate(true)

	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	ch["damaged_values"] = [{"value": "attribute.focus", "amount": 2,
		"cleared_by": [{"rest": "full"}, {"heal": {"school": "white", "min_level": 5}}],
		"source": "curse"}]
	CharacterSystem.update_derived_stats(ch)
	var sp: int = int(ch.derived.spellpower)
	var name_: String = str(ch.get("name", ""))

	var saved: bool = SaveManager.save_game(3)
	CharacterSystem.get_party().erase(ch)
	var loaded: bool = SaveManager.load_game(3)
	if not saved or not loaded:
		_fail("save/load of slot 3 failed (saved %s, loaded %s)" % [saved, loaded])
	else:
		var back: Dictionary = {}
		for member in CharacterSystem.get_party():
			if str(member.get("name", "")) == name_ and member.has("damaged_values"):
				back = member
		if back.is_empty():
			_fail("the party member came back without damaged_values")
		else:
			var entry: Dictionary = back.damaged_values[0]
			if entry.get("value") != "attribute.focus" or int(entry.get("amount", 0)) != 2 \
					or entry.get("cleared_by", []).size() != 2 or entry.get("source") != "curse":
				_fail("damaged_values came back as %s" % [back.damaged_values])
			if ValuePaths.damaged_total(back, "attribute.focus") != 2.0:
				_fail("damaged_total after load: %s" % ValuePaths.damaged_total(back, "attribute.focus"))
			if int(back.derived.spellpower) != sp:
				_fail("spellpower after load: %d, wanted %d" % [int(back.derived.spellpower), sp])

	# Put everything back: the save folder first, then the process state.
	SaveManager.SAVE_DIR = real_dir
	for fname in ["slot_3.json", "meta.json"]:
		if FileAccess.file_exists(scratch + fname):
			DirAccess.remove_absolute(scratch + fname)
	DirAccess.remove_absolute(scratch)
	GameState.load_save_data(snap_game)
	CharacterSystem.load_save_data(snap_chars)
	ItemSystem.load_save_data(snap_items)
	KarmaSystem.load_save_data(snap_karma)
	MapManager.load_save_data(snap_map)
	SaveManager.current_slot = old_slot
	_cleanup([u])
	_done()


# ── EffectResolver ───────────────────────────────────────────────────────────

## A context for `caster` acting on `target`, as a spell of `school`/`level`.
## hold_source is left empty unless a check sets it.
func _ctx(caster: CombatUnit, target: CombatUnit, school: String = "fire",
		level: int = 1) -> EffectContext:
	var ctx := EffectContext.new()
	ctx.caster = caster
	ctx.target = target
	ctx.container_kind = "test"
	ctx.container_id = "verify"
	ctx.school = school
	ctx.level = level
	return ctx


## How many entries entries were applied.
func _applied(entries: Array[Dictionary]) -> int:
	var n: int = 0
	for entry in entries:
		if entry.get("applied", false):
			n += 1
	return n


func _check_resolver_damage_and_split() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	EffectResolver.resolve([{"op": "damage", "amount": 40, "type": "fire"}], _ctx(caster, foe))
	if foe.current_hp != 60:
		_fail("40 fire on an unresisted enemy: HP %d, wanted 60" % foe.current_hp)
	foe.current_hp = 100
	# `set`, not `fortify`: Resistance caps buffs below immunity on purpose
	# (REDUCTION_CAP), so only a declared 100 makes black do nothing at all.
	ValuePaths.add_hold(foe, "resist.black", "set", 100, "t1")
	EffectResolver.resolve([{"op": "damage", "amount": 40,
		"type": {"fire": 0.5, "black": 0.5}}], _ctx(caster, foe))
	if foe.current_hp != 80:
		_fail("40 split fire/black vs black 100%%: HP %d, wanted 80" % foe.current_hp)
	_cleanup([caster, foe])
	_done()


func _check_resolver_heal_full() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var friend := _make_unit(Vector2i(3, 3), CombatManager.Team.PLAYER)
	friend.current_hp = 30
	var entries := EffectResolver.resolve([{"op": "heal", "amount": "full"}], _ctx(caster, friend))
	if friend.current_hp != friend.max_hp:
		_fail("heal full: HP %d, wanted %d" % [friend.current_hp, friend.max_hp])
	if _applied(entries) != 1:
		_fail("heal full: entries %s" % [entries])
	_cleanup([caster, friend])
	_done()


func _check_resolver_absorb_mana() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	foe.max_mana = 100
	foe.current_mana = 50
	caster.max_mana = 100
	caster.current_mana = 10
	var absorb := {"op": "modify", "value": "resource.mana", "mode": "absorb", "amount": 20}
	EffectResolver.resolve([absorb], _ctx(caster, foe))
	if foe.current_mana != 30 or caster.current_mana != 30:
		_fail("absorb 20 mana: target %d (want 30), caster %d (want 30)"
			% [foe.current_mana, caster.current_mana])
	# The caster's gain is capped at its maximum.
	caster.current_mana = 95
	EffectResolver.resolve([absorb], _ctx(caster, foe))
	if foe.current_mana != 10 or caster.current_mana != 100:
		_fail("absorb at the cap: target %d (want 10), caster %d (want 100)"
			% [foe.current_mana, caster.current_mana])
	_cleanup([caster, foe])
	_done()


func _check_resolver_modify_needs_hold_source() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var dodge: int = foe.get_dodge()
	var fortify := {"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 5}
	var entries := EffectResolver.resolve([fortify], _ctx(caster, foe))
	if entries.size() != 1 or entries[0].get("applied", true):
		_fail("fortify with no hold_source must be refused: %s" % [entries])
	if foe.get_dodge() != dodge:
		_fail("refused fortify still moved dodge: %d -> %d" % [dodge, foe.get_dodge()])
	# With a hold_source it lands, under that source.
	var ctx := _ctx(caster, foe)
	ctx.hold_source = "status:Haste"
	EffectResolver.resolve([fortify], ctx)
	if foe.get_dodge() != dodge + 5:
		_fail("fortify under a hold_source: dodge %d, wanted %d" % [foe.get_dodge(), dodge + 5])
	ValuePaths.release(foe, "status:Haste")
	_cleanup([caster, foe])
	_done()


func _check_save_rolled_once_for_both_branches() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var save := {"stat": "constitution", "tier": "normal"}
	var effects := [
		{"op": "damage", "amount": 10, "type": "fire", "save": save, "on_save": "fail"},
		{"op": "damage", "amount": 5, "type": "fire", "save": save, "on_save": "pass"},
	]
	var saw_fail: bool = false
	var saw_pass: bool = false
	seed(7001)
	for i in 50:
		foe.current_hp = 100
		var entries := EffectResolver.resolve(effects, _ctx(caster, foe))
		if _applied(entries) != 1:
			_fail("run %d: %d branches applied, wanted exactly 1: %s" % [i, _applied(entries), entries])
			break
		var lost: int = 100 - foe.current_hp
		if lost == 10:
			saw_fail = true
		elif lost == 5:
			saw_pass = true
		else:
			_fail("run %d: lost %d HP, wanted 10 or 5" % [i, lost])
	if not (saw_fail and saw_pass):
		_fail("50 seeded runs should see both branches (fail %s, pass %s)" % [saw_fail, saw_pass])
	_cleanup([caster, foe])
	_done()


func _check_chance_zero_and_hundred() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var friend := _make_unit(Vector2i(3, 3), CombatManager.Team.PLAYER)
	seed(7002)
	var never: int = 0
	var always: int = 0
	for i in 50:
		friend.current_hp = 50
		never += _applied(EffectResolver.resolve(
			[{"op": "heal", "amount": 1, "chance": 0}], _ctx(caster, friend)))
		always += _applied(EffectResolver.resolve(
			[{"op": "heal", "amount": 1, "chance": 100}], _ctx(caster, friend)))
	if never != 0:
		_fail("chance 0 applied %d times in 50" % never)
	if always != 50:
		_fail("chance 100 applied %d times in 50" % always)
	_cleanup([caster, friend])
	_done()


func _check_bonus_vs_and_scale() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	foe.character_data["tags"] = ["undead"]
	EffectResolver.resolve([{"op": "damage", "amount": 10, "type": "fire",
		"bonus_vs": {"undead": 2}}], _ctx(caster, foe))
	if foe.current_hp != 80:
		_fail("bonus_vs undead x2 on 10 fire: HP %d, wanted 80" % foe.current_hp)
	# A tag the target lacks changes nothing.
	foe.current_hp = 100
	EffectResolver.resolve([{"op": "damage", "amount": 10, "type": "fire",
		"bonus_vs": {"boss": 0.5}}], _ctx(caster, foe))
	if foe.current_hp != 90:
		_fail("bonus_vs boss on a non-boss: HP %d, wanted 90" % foe.current_hp)

	# Two debuffs: 10 + 2 x 5 = 20.
	foe.character_data["tags"] = []
	foe.current_hp = 100
	foe.status_effects.append({"status": "Slowed", "duration": 3, "value": 0})
	foe.status_effects.append({"status": "Silenced", "duration": 3, "value": 0})
	EffectResolver.resolve([{"op": "damage", "amount": 10, "type": "fire",
		"scale": {"per": "debuff_on_target", "amount": 5}}], _ctx(caster, foe))
	if foe.current_hp != 80:
		_fail("scale 5 per debuff with 2 debuffs: HP %d, wanted 80" % foe.current_hp)
	# And a cap of 4 holds the growth to 4.
	foe.current_hp = 100
	EffectResolver.resolve([{"op": "damage", "amount": 10, "type": "fire",
		"scale": {"per": "debuff_on_target", "amount": 5, "cap": 4}}], _ctx(caster, foe))
	if foe.current_hp != 86:
		_fail("scale capped at 4: HP %d, wanted 86" % foe.current_hp)
	foe.status_effects.clear()
	_cleanup([caster, foe])
	_done()


func _check_if_condition_blocks() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var effect := {"op": "damage", "amount": 10, "type": "fire",
		"if": [{"target_has": "Burning"}]}
	var entries := EffectResolver.resolve([effect], _ctx(caster, foe))
	if _applied(entries) != 0 or foe.current_hp != 100:
		_fail("target_has Burning on a non-burning target applied: %s, HP %d" % [entries, foe.current_hp])
	foe.status_effects.append({"status": "Burning", "duration": 3, "value": 0})
	entries = EffectResolver.resolve([effect], _ctx(caster, foe))
	if _applied(entries) != 1 or foe.current_hp != 90:
		_fail("target_has Burning on a burning target: %s, HP %d" % [entries, foe.current_hp])
	foe.status_effects.clear()
	_cleanup([caster, foe])
	_done()


func _check_resolver_refuses_invalid_effect() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var entries := EffectResolver.resolve([{"op": "damage", "amount": 10, "type": "not_a_type"}],
		_ctx(caster, foe))
	if entries.size() != 1 or entries[0].get("applied", true) \
			or not str(entries[0].get("reason", "")).begins_with("invalid: "):
		_fail("an invalid effect must be refused with reason 'invalid: ...': %s" % [entries])
	if foe.current_hp != 100:
		_fail("the invalid effect still did damage: HP %d" % foe.current_hp)
	_cleanup([caster, foe])
	_done()


## Ledger ruling: a heal that clears a HELD damage entry lifts the in-fight
## penalty at once, and after the fight the character is back to base.
func _check_heal_clearing_held_damage_lifts_it_now() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	var base_sp: int = u.get_spellpower()
	var derived_sp: int = int(ch.derived.spellpower)
	var curse := {"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 2,
		"cleared_by": [{"heal": {"school": "white", "min_level": 3}}]}
	EffectResolver.resolve([curse], _ctx(caster, u, "black", 5))
	if u.get_spellpower() >= base_sp:
		_fail("setup: 2 focus damage did not lower spellpower (%d)" % u.get_spellpower())
	EffectResolver.resolve([{"op": "heal", "amount": 5}], _ctx(caster, u, "white", 3))
	if u.get_spellpower() != base_sp:
		_fail("after a qualifying heal mid-fight spellpower %d, wanted %d"
			% [u.get_spellpower(), base_sp])
	if not ch.get("damaged_values", []).is_empty():
		_fail("the heal left damaged_values %s" % [ch.damaged_values])
	_end_fight()
	if int(ch.derived.spellpower) != derived_sp:
		_fail("after end_combat derived spellpower %d, wanted %d"
			% [int(ch.derived.spellpower), derived_sp])
	_leave_party(u)
	_cleanup([caster, u])
	_done()


## `restore` on attribute.: a party member's held entry shrinks and so does its
## in-fight hold; an enemy's "__damage:" drain hold shrinks directly.
func _check_resolver_restore_by_amount() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(6, 6), CombatManager.Team.ENEMY)
	_join_party(u)
	var curse := {"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 3}
	var restore := {"op": "modify", "value": "attribute.focus", "mode": "restore", "amount": 2}
	EffectResolver.resolve([curse], _ctx(caster, u))
	EffectResolver.resolve([curse], _ctx(caster, foe))
	EffectResolver.resolve([restore], _ctx(caster, u))
	EffectResolver.resolve([restore], _ctx(caster, foe))
	var left: Array = u.character_data.get("damaged_values", [])
	if left.size() != 1 or float(left[0].amount) != 1.0:
		_fail("party restore 2 of 3: entries %s" % [left])
	for who in [u, foe]:
		var holds := ValuePaths.holds_on(who, "attribute.focus")
		if holds.size() != 1 or float(holds[0].amount) != 1.0:
			_fail("%s focus hold after restore 2 of 3: %s" % [who.unit_name, holds])
	_end_fight()
	_leave_party(u)
	_cleanup([caster, u, foe])
	_done()


# ── Delegating ops ───────────────────────────────────────────────────────────

## apply Burning for 3 turns, then remove it by name.
func _check_status_apply_and_remove() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var log := EffectResolver.resolve(
		[{"op": "status", "action": "apply", "status": "Burning", "duration": 3}], _ctx(caster, u))
	if not u.has_status("Burning"):
		_fail("status apply: Burning not on the target (%s)" % [log])
	for entry in u.status_effects:
		if str(entry.get("status")) == "Burning" and int(entry.get("duration", 0)) != 3:
			_fail("status apply: duration %s, wanted 3" % entry.get("duration"))
	EffectResolver.resolve([{"op": "status", "action": "remove",
		"select": {"names": ["Burning"]}}], _ctx(caster, u))
	if u.has_status("Burning"):
		_fail("status remove: Burning is still on the target")
	_cleanup([caster, u])
	_done()


## Push 1: the target ends one tile further from the caster.
func _check_move_push_one_tile() -> void:
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(6, 5), CombatManager.Team.ENEMY)
	EffectResolver.resolve([{"op": "move", "mode": "push", "tiles": 1}], _ctx(caster, u))
	if u.grid_position != Vector2i(7, 5):
		_fail("push 1: target at %s, wanted (7, 5)" % u.grid_position)
	_cleanup([caster, u])
	_done()


## Make `unit` a boss by pointing it at a real boss archetype.
func _make_boss(unit: CombatUnit) -> void:
	unit.character_data["archetype_id"] = "hell_yama_lieutenant"
	if not "boss" in EffectResolver.unit_tags(unit):
		_fail("fixture: hell_yama_lieutenant is not tagged boss")


## kill on a boss is refused: alive, log says immune, message in combat_log.
## A non-boss dies.
func _check_kill_refused_on_boss() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var boss := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var mook := _make_unit(Vector2i(6, 5), CombatManager.Team.ENEMY)
	_make_boss(boss)
	var lines: Array[String] = []
	var grab := func(msg: String) -> void: lines.append(msg)
	CombatManager.combat_log.connect(grab)
	var log := EffectResolver.resolve([{"op": "kill"}], _ctx(caster, boss))
	CombatManager.combat_log.disconnect(grab)
	if not boss.is_alive() or boss.current_hp <= 0:
		_fail("kill: boss died")
	if log.size() != 1 or log[0].applied or log[0].reason != "immune":
		_fail("kill boss: log %s" % [log])
	if not "%s cannot be undone outright." % boss.unit_name in lines:
		_fail("kill boss: no refusal in combat_log (%s)" % [lines])
	var log2 := EffectResolver.resolve([{"op": "kill"}], _ctx(caster, mook))
	if mook.is_alive() or not log2[0].applied:
		_fail("kill non-boss: still alive (%s)" % [log2])
	_cleanup([caster, boss, mook])
	_done()


## `immune: []` removes the default protection.
func _check_kill_immune_override() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var boss := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	_make_boss(boss)
	EffectResolver.resolve([{"op": "kill", "immune": []}], _ctx(caster, boss))
	if boss.is_alive():
		_fail("kill immune []: boss survived")
	_cleanup([caster, boss])
	_done()


## summon Imp x2: two new units on the caster's team.
func _check_summon_count() -> void:
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var before: Array = CombatManager.all_units.duplicate()
	EffectResolver.resolve([{"op": "summon", "as": "Imp", "count": 2}], _ctx(caster, caster))
	var made: Array = []
	for unit in CombatManager.all_units:
		if not unit in before:
			made.append(unit)
	if made.size() != 2:
		_fail("summon count 2: %d new units" % made.size())
	for unit in made:
		if unit.team != caster.team:
			_fail("summoned unit is on team %s, caster on %s" % [unit.team, caster.team])
		CombatManager.turn_order.erase(unit)
	_cleanup(made)
	_cleanup([caster])
	_done()


## zone poison_cloud: the combat manager holds a zone with that id.
func _check_zone_created() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(6, 6), CombatManager.Team.ENEMY)
	CombatManager.active_zones.clear()
	EffectResolver.resolve([{"op": "zone", "zone": "poison_cloud"}], _ctx(caster, u))
	var found := false
	for zone in CombatManager.active_zones:
		if zone.id == "poison_cloud" and (zone.tiles as Dictionary).has(Vector2i(6, 6)):
			found = true
	if not found:
		_fail("zone: no poison_cloud over the target (%s)" % [CombatManager.active_zones.size()])
	CombatManager.active_zones.clear()
	_cleanup([caster, u])
	_done()


## resurrect revive at 50%: a dead ally stands up with half its HP.
func _check_resurrect_raises_the_dead() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	u.is_dead = true
	u.current_hp = 0
	var log := EffectResolver.resolve(
		[{"op": "resurrect", "tier": "revive", "hp_pct": 50}], _ctx(caster, u))
	if u.is_dead or u.current_hp != 50 or not log[0].applied:
		_fail("resurrect: dead=%s hp=%d log=%s" % [u.is_dead, u.current_hp, log])
	# A living unit cannot be raised: refused, not applied.
	var again := EffectResolver.resolve(
		[{"op": "resurrect", "tier": "revive", "hp_pct": 50}], _ctx(caster, u))
	if again[0].applied:
		_fail("resurrect: a living unit counted as raised")
	_cleanup([caster, u])
	_done()


## Count units not in `before`, remove them from the fight, and return how many.
func _new_units_since(before: Array) -> Array:
	var made: Array = []
	for unit in CombatManager.all_units:
		if not unit in before:
			made.append(unit)
	for unit in made:
		CombatManager.turn_order.erase(unit)
	return made


## `to: enemies_in_area` with two enemies must still summon exactly `count`.
func _check_summon_once_for_area_recipients() -> void:
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var e1 := _make_unit(Vector2i(8, 8), CombatManager.Team.ENEMY)
	var e2 := _make_unit(Vector2i(9, 8), CombatManager.Team.ENEMY)
	var ctx := _ctx(caster, e1)
	ctx.area_units = [e1, e2]
	var before: Array = CombatManager.all_units.duplicate()
	var log := EffectResolver.resolve(
		[{"op": "summon", "as": "Imp", "count": 2, "to": "enemies_in_area"}], ctx)
	var made := _new_units_since(before)
	if made.size() != 2 or log.size() != 1:
		_fail("area summon: %d units, %d log entries (wanted 2 and 1)" % [made.size(), log.size()])
	if log.size() == 1 and log[0].to != "Imp":
		_fail("summon log names '%s', wanted the template" % log[0].to)
	_cleanup(made)
	_cleanup([caster, e1, e2])
	_done()


## A ground-aimed cast has no target node; target_pos alone must work.
func _check_summon_from_target_pos_only() -> void:
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var ctx := _ctx(caster, null)
	ctx.target_pos = Vector2i(9, 5)
	var before: Array = CombatManager.all_units.duplicate()
	EffectResolver.resolve([{"op": "summon", "as": "Imp"}], ctx)
	var made := _new_units_since(before)
	if made.size() != 1 or made[0].grid_position != Vector2i(9, 5):
		_fail("target_pos summon: %s" % [made])
	_cleanup(made)
	_cleanup([caster])
	_done()


## Neither target nor target_pos: refused with reason "no position".
func _check_position_op_without_position_refused() -> void:
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var log := EffectResolver.resolve([{"op": "zone", "zone": "poison_cloud"}], _ctx(caster, null))
	if log.size() != 1 or log[0].applied or log[0].reason != "no position":
		_fail("no position: %s" % [log])
	_cleanup([caster])
	_done()


# ── Skill bonus curves (stage 2a) ────────────────────────────────────────────

func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.01


## Swords damage follows the climb formula: 5/15/30/50/75 up to level 5, then
## +11 a level to 130 at 10 (the old table said 90/100/110/120 at 6-9).
func _check_curve_climb_swords() -> void:
	var expected: Array = [5, 15, 30, 50, 75, 86, 97, 108, 119, 130]
	for lvl in range(1, 11):
		var got: float = float(PerkSystem.get_base_skill_bonuses_at_level("swords", lvl).get("damage", -999))
		if not _near(got, float(expected[lvl - 1])):
			_fail("swords damage at %d: expected %s, got %s" % [lvl, expected[lvl - 1], got])
	_done()


## The formula does not stop at 10 (or 15): +11 a level continues.
func _check_curve_continues_past_ten() -> void:
	var at_15: float = float(PerkSystem.get_base_skill_bonuses_at_level("swords", 15).get("damage", -999))
	var at_25: float = float(PerkSystem.get_base_skill_bonuses_at_level("swords", 25).get("damage", -999))
	if not _near(at_15, 185.0):
		_fail("swords damage at 15: expected 185, got %s" % at_15)
	if not _near(at_25, 295.0):
		_fail("swords damage at 25: expected 295, got %s" % at_25)
	_done()


## Mana cost reduction has a limit of -100: it holds at 9, 10 and 30. Level 6
## sits on the climb line (-75 at 5, falling 6.25 a step to hit -100 at 9), which proves the
## values come from the formula and not from a leftover table.
func _check_curve_limit_holds() -> void:
	var at_6: float = float(PerkSystem.get_base_skill_bonuses_at_level("space_magic", 6).get("mana_cost_reduction", 0.0))
	if not _near(at_6, -81.25):
		_fail("space_magic mana_cost_reduction at 6: expected -81.25, got %s" % at_6)
	for lvl in [9, 10, 30]:
		var got: float = float(PerkSystem.get_base_skill_bonuses_at_level("space_magic", lvl).get("mana_cost_reduction", 0.0))
		if not _near(got, -100.0):
			_fail("space_magic mana_cost_reduction at %d: expected -100, got %s" % [lvl, got])
	_done()


## Base Swords 10 plus a +12 bonus is effective level 22, not 15.
func _check_effective_skill_level_uncapped() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["skills"] = {"swords": 10}
	c["skill_bonuses"] = {"swords": {"test": 12}}
	var got: int = CharacterSystem.get_effective_skill_level(c, "swords")
	if got != 22:
		_fail("effective Swords level: expected 22, got %d" % got)
	_done()


## Companion count is a count: whole numbers at every level 1..20, and it
## keeps growing past 10 (uncapped).
func _check_integer_curve_floors() -> void:
	var values: Array[float] = []
	for lvl in range(1, 21):
		var b: Dictionary = PerkSystem.get_base_skill_bonuses_at_level("leadership", lvl)
		if not b.has("party_max_companions"):
			_fail("leadership has no party_max_companions at level %d" % lvl)
			continue
		var v: float = float(b["party_max_companions"])
		if v != floorf(v):
			_fail("party_max_companions at level %d is %s, not whole" % [lvl, v])
		values.append(v)
	if values.size() == 20 and not values[19] > values[9]:
		_fail("party_max_companions did not grow past level 10: %s vs %s" % [values[9], values[19]])
	_done()


## Purging a trait asks for the effective skill level, which is not capped at 15:
## Yoga 10 + a +8 bonus is 18, enough for a requirement of 17 (and 16 is not).
func _check_purge_uses_uncapped_effective_level() -> void:
	TraitSystem._traits["_probe_trait"] = {"purgeable_by": ["yoga"], "purge_difficulty": 17}
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["traits"] = ["_probe_trait"]
	c["skills"] = {"yoga": 10}
	c["skill_bonuses"] = {"yoga": {"test": 6}}
	if TraitSystem.try_purge(c, "_probe_trait", "yoga"):
		_fail("a purge needing 17 succeeded at effective level 16")
	c["skill_bonuses"] = {"yoga": {"test": 8}}
	if not TraitSystem.try_purge(c, "_probe_trait", "yoga"):
		_fail("a purge needing 17 failed at effective level 18")
	TraitSystem._traits.erase("_probe_trait")
	_done()


# ── Stage 2a: holds live on the character, refreshed mid-fight ───────────────

## A party unit with Swords 10 gets a +5 skill hold mid-fight: its accuracy
## must rise by exactly what the Swords curve pays between level 10 and 15,
## because refresh_character re-runs the per-level skill bonuses at once.
func _check_skill_hold_raises_per_level_bonus_midfight() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	ch.skills["swords"] = 10
	CharacterSystem.update_derived_stats(ch)
	var spec: Dictionary = PerkSystem._base_bonuses["swords"]["stats"]["accuracy"]
	var want_rise: int = int(PerkSystem.curve_value(spec, 15) - PerkSystem.curve_value(spec, 10))
	var before: int = u.get_accuracy()
	ValuePaths.add_hold(u, "skill.swords", "fortify", 5, "t1")
	if u.get_accuracy() - before != want_rise:
		_fail("swords +5 mid-fight: accuracy rose %d, wanted %d"
			% [u.get_accuracy() - before, want_rise])
	ValuePaths.release(u, "t1")
	if u.get_accuracy() != before:
		_fail("release did not restore accuracy: %d, wanted %d" % [u.get_accuracy(), before])
	_leave_party(u)
	_cleanup([u])
	_done()


## Review Focus 3: a Constitution hold raises the maximum, never the current
## HP, on the unit or in derived. Releasing it clamps current HP to the old max.
func _check_attribute_hold_no_current_hp_jump() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	u.max_hp = int(ch.derived.max_hp)
	u.current_hp = u.max_hp - 20
	var old_max: int = u.max_hp
	var old_current: int = u.current_hp
	var derived_current: int = int(ch.derived.current_hp)
	var con: int = CharacterSystem.get_effective_attribute(ch, "constitution")
	ValuePaths.add_hold(u, "attribute.constitution", "fortify", 5, "t1")
	if int(ch.get("attribute_bonuses", {}).get("constitution", {}).get("effects", 0)) != 5:
		_fail("attribute_bonuses.constitution.effects should be 5: %s" % [ch.get("attribute_bonuses", {})])
	if CharacterSystem.get_effective_attribute(ch, "constitution") != con + 5:
		_fail("effective constitution: %d, wanted %d"
			% [CharacterSystem.get_effective_attribute(ch, "constitution"), con + 5])
	if int(ch.derived.max_hp) != old_max + 50:
		_fail("derived.max_hp: %d, wanted %d" % [int(ch.derived.max_hp), old_max + 50])
	if u.max_hp != old_max + 50:
		_fail("unit max_hp: %d, wanted %d" % [u.max_hp, old_max + 50])
	if u.current_hp != old_current:
		_fail("current_hp jumped: %d, wanted %d" % [u.current_hp, old_current])
	if int(ch.derived.current_hp) > derived_current:
		_fail("derived.current_hp jumped: %d, was %d" % [int(ch.derived.current_hp), derived_current])
	u.current_hp = u.max_hp
	ValuePaths.release(u, "t1")
	if u.max_hp != old_max:
		_fail("release max_hp: %d, wanted %d" % [u.max_hp, old_max])
	if u.current_hp != old_max:
		_fail("release current_hp: %d, wanted the old max %d" % [u.current_hp, old_max])
	if ch.get("attribute_bonuses", {}).has("constitution"):
		_fail("attribute_bonuses entry left behind: %s" % [ch.attribute_bonuses])
	_leave_party(u)
	_cleanup([u])
	_done()


## Review Focus 4: an attribute hold on an enemy changes its stats through
## CharacterSystem.update_derived_stats, leaves the archetype tables alone, and
## release puts every derived number back exactly.
func _check_enemy_refresh() -> void:
	var archetypes_before: Dictionary = EnemySystem.archetypes.duplicate(true)
	var archetype_id: String = str(EnemySystem.archetypes.keys()[0])
	var enemy: Dictionary = EnemySystem._build_enemy(archetype_id, 400, "hell")
	var u := CombatUnit.new()
	add_child(u)
	u.init_as_enemy(enemy)
	u.grid_position = Vector2i(7, 7)
	grid.unit_positions[u.grid_position] = u
	CombatManager.all_units.append(u)
	var ch: Dictionary = u.character_data
	var derived_before: Dictionary = ch.derived.duplicate(true)
	var max_hp: int = u.max_hp
	var dodge: int = u.get_dodge()
	var init: int = u.get_initiative()

	ValuePaths.add_hold(u, "attribute.finesse", "fortify", 4, "t1")
	ValuePaths.add_hold(u, "attribute.constitution", "fortify", 3, "t2")
	if int(ch.get("attribute_bonuses", {}).get("finesse", {}).get("effects", 0)) != 4:
		_fail("enemy attribute_bonuses.finesse.effects should be 4: %s" % [ch.get("attribute_bonuses", {})])
	if int(ch.derived.dodge) != int(derived_before.dodge) + 4:
		_fail("enemy derived.dodge: %s, wanted %d" % [ch.derived.dodge, int(derived_before.dodge) + 4])
	if u.get_dodge() != dodge + 4 or u.get_initiative() != init + 4:
		_fail("enemy finesse +4: dodge %d (want %d), initiative %d (want %d)"
			% [u.get_dodge(), dodge + 4, u.get_initiative(), init + 4])
	if u.max_hp != max_hp + 30:
		_fail("enemy con +3 max_hp: %d, wanted %d" % [u.max_hp, max_hp + 30])
	if EnemySystem.archetypes != archetypes_before:
		_fail("EnemySystem.archetypes changed by a hold")

	ValuePaths.release(u, "t1")
	ValuePaths.release(u, "t2")
	if ch.derived != derived_before:
		_fail("enemy derived not restored: %s vs %s" % [ch.derived, derived_before])
	if u.max_hp != max_hp or u.get_dodge() != dodge or u.get_initiative() != init:
		_fail("enemy unit stats not restored after release")
	if ch.get("attribute_bonuses", {}).has("finesse") or ch.get("attribute_bonuses", {}).has("constitution"):
		_fail("enemy attribute_bonuses left behind: %s" % [ch.get("attribute_bonuses", {})])
	if EnemySystem.archetypes != archetypes_before:
		_fail("EnemySystem.archetypes changed after release")

	# A hold on a skill the enemy never had counts fully. Fire magic +5 raises
	# spellpower.
	ch["skills"].erase("fire_magic")
	ch.get("skill_bonuses", {}).erase("fire_magic")
	# Editing the sheet means re-deriving it, now that an enemy's derived is
	# the full formula (2026-11-26) rather than a hold delta on top of built
	# numbers: if the build rolled any Fire magic, taking it away moves
	# spellpower by itself. The baseline is the sheet without it.
	ValuePaths.refresh_character(u)
	derived_before = ch.derived.duplicate(true)
	var sp_before: int = int(ch.derived.get("spellpower", 0))
	var fire_sp: Dictionary = PerkSystem._base_bonuses["fire_magic"]["stats"]["spellpower"]
	ValuePaths.add_hold(u, "skill.fire_magic", "fortify", 5, "t3")
	var sp_want: int = sp_before + int(PerkSystem.curve_value(fire_sp, 5))
	if int(ch.derived.get("spellpower", 0)) != sp_want:
		_fail("enemy unbought fire_magic +5: spellpower %s, wanted %d" % [ch.derived.get("spellpower", 0), sp_want])
	ValuePaths.release(u, "t3")
	if ch.derived != derived_before:
		_fail("enemy derived not restored after unbought-skill hold")
	_cleanup([u])
	_done()


# ── Stage 2a: boosts count wherever ability is read ─────────────────────────

## Fire magic 3 cannot cast Fireball (a level-5 spell); a +2 Fire magic hold
## lets it. Goes through get_castable_spells, which builds the skills map and
## hands it to _can_cast_spell exactly the way cast_spell does.
func _check_skill_hold_unlocks_casting() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var ch: Dictionary = u.character_data
	ch.skills["fire_magic"] = 3
	ch.skills["sorcery"] = 0
	ch["known_spells"] = ["fireball"]
	u.current_mana = 999   # rule out "not enough mana": only skill decides
	var castable := func() -> bool:
		for s in CombatManager.get_castable_spells(u):
			if str(s.get("id", "")) == "fireball":
				return true
		return false
	if castable.call():
		_fail("Fire magic 3 should not cast fireball (level 5)")
	ValuePaths.add_hold(u, "skill.fire_magic", "fortify", 2, "t1")
	u.current_mana = 999   # the hold's refresh clamps mana to the max; refill
	if not castable.call():
		_fail("Fire magic 3 + hold 2 should cast fireball")
	ValuePaths.release(u, "t1")
	u.current_mana = 999
	if castable.call():
		_fail("fireball still castable after the hold was released")
	_cleanup([u])
	_done()


## _calculate_spell_bonus counts 2 per level of every school skill. A +3 Fire
## magic hold must add those 6, on top of whatever the hold did to spellpower.
func _check_skill_hold_raises_spell_bonus() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var spell: Dictionary = CombatManager.get_spell("firebolt")
	var before: int = CombatManager._calculate_spell_bonus(u, spell)
	var sp_before: int = u.get_spellpower()
	ValuePaths.add_hold(u, "skill.fire_magic", "fortify", 3, "t1")
	var want: int = before + (u.get_spellpower() - sp_before) + 3 * 2
	var after: int = CombatManager._calculate_spell_bonus(u, spell)
	if after != want:
		_fail("firebolt spell bonus with fire_magic +3: %d, wanted %d" % [after, want])
	ValuePaths.release(u, "t1")
	if CombatManager._calculate_spell_bonus(u, spell) != before:
		_fail("spell bonus not restored after release")
	_cleanup([u])
	_done()


## A Constitution save reads the effective attribute: +6 Constitution is +6 on
## the roll, which is 30 percentage points at a DC that is not clamped.
func _check_attribute_hold_reaches_saves() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var con: int = CharacterSystem.get_effective_attribute(u.character_data, "constitution")
	# A DC the defender needs an 18 on the die for: 15% to save.
	var dc: int = 18 + con + SaveSystem._bonus_for(u, "constitution")
	var before: float = SaveSystem.success_chance(u, "constitution", dc)
	ValuePaths.add_hold(u, "attribute.constitution", "fortify", 6, "t1")
	var after: float = SaveSystem.success_chance(u, "constitution", dc)
	if not _near(before, 0.15) or not _near(after, 0.45):
		_fail("con save with +6 hold: %.2f -> %.2f, wanted 0.15 -> 0.45" % [before, after])
	ValuePaths.release(u, "t1")
	_cleanup([u])
	_done()


## Elemental affinity totals the effective level of each element skill.
func _check_skill_hold_reaches_affinity() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var ch: Dictionary = u.character_data
	var before: int = PerkSystem.calculate_element_affinity(ch, "fire")
	ValuePaths.add_hold(u, "skill.fire_magic", "fortify", 4, "t1")
	var after: int = PerkSystem.calculate_element_affinity(ch, "fire")
	if after != before + 4:
		_fail("fire affinity with fire_magic +4: %d, wanted %d" % [after, before + 4])
	ValuePaths.release(u, "t1")
	_cleanup([u])
	_done()


## Review Focus 5: learning a spell in a shop uses the bought level, so a boost
## lets you cast above your level but never buy above it.
func _check_shop_learning_ignores_boost() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c.skills["fire_magic"] = 3
	c.skills["sorcery"] = 0
	c["skill_bonuses"] = {"fire_magic": {"effects": 5}}
	var fireball: Dictionary = CharacterSystem.get_spell_database().get("fireball", {})
	if fireball.is_empty():
		_fail("fireball missing from the spell database")
	elif CharacterSystem.meets_spell_skill(c, fireball):
		_fail("meets_spell_skill counted a temporary boost: shop learning must use the bought level")
	_done()


## Fix round 1: a hold on a skill the character never bought (no key in
## `skills` at all) must count everywhere a bought level does, mid-fight:
##   (b) the per-level bonuses — Fire magic +5 pays Fire magic's level-5
##       spellpower;
##   (a) the school-matched mana-cost reduction — Water magic +5 pays its
##       level-5 reduction AND that reduction applies to a Water spell.
## Fire magic's table has no mana_cost_reduction row, so (a) uses Water magic.
func _check_hold_on_unbought_skill_counts_fully() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var ch: Dictionary = u.character_data
	ch["skills"] = {}   # nothing bought, not even a 0 entry
	CharacterSystem.update_derived_stats(ch)

	# (b) per-level bonuses from a bonus-only skill
	var fire_sp: Dictionary = PerkSystem._base_bonuses["fire_magic"]["stats"]["spellpower"]
	var sp_before: int = int(ch.derived.spellpower)
	ValuePaths.add_hold(u, "skill.fire_magic", "fortify", 5, "t1")
	var sp_want: int = sp_before + int(PerkSystem.curve_value(fire_sp, 5))
	if int(ch.derived.spellpower) != sp_want:
		_fail("unbought fire_magic +5: derived.spellpower %d, wanted %d"
			% [int(ch.derived.spellpower), sp_want])
	ValuePaths.release(u, "t1")

	# (a) school-matched mana reduction from a bonus-only skill
	var mud: Dictionary = CombatManager.get_spell("mud")   # Water + Enchantment
	var cost: int = int(mud.get("mana_cost", 0))
	if CombatManager.apply_skill_mana_reduction(u, mud, cost) != cost:
		_fail("no magic skills: mud should cost its full %d" % cost)
	var water_mcr: Dictionary = PerkSystem._base_bonuses["water_magic"]["stats"]["mana_cost_reduction"]
	var mcr_before: int = int(ch.derived.get("mana_cost_reduction", 0))
	ValuePaths.add_hold(u, "skill.water_magic", "fortify", 5, "t2")
	var mcr_want: int = mcr_before + int(PerkSystem.curve_value(water_mcr, 5))
	if int(ch.derived.get("mana_cost_reduction", 0)) != mcr_want:
		_fail("unbought water_magic +5: mana_cost_reduction %d, wanted %d"
			% [int(ch.derived.get("mana_cost_reduction", 0)), mcr_want])
	# The reduction is capped: never below 10% of base, never more than 90% off.
	var cost_want: int = maxi(maxi(int(cost * 0.10), cost + mcr_want), cost - int(cost * 0.90))
	var got: int = CombatManager.apply_skill_mana_reduction(u, mud, cost)
	if got != cost_want:
		_fail("unbought water_magic +5: mud costs %d, wanted %d" % [got, cost_want])
	ValuePaths.release(u, "t2")
	if CombatManager.apply_skill_mana_reduction(u, mud, cost) != cost:
		_fail("mud cost not restored after release")
	_leave_party(u)
	_cleanup([u])
	_done()


## Party size can never pass the combat arena's deploy slots, however high
## Leadership gets (here 40, far past anything the curve reaches the cap at).
func _check_party_size_capped_at_deploy_slots() -> void:
	var leader: Dictionary = CharacterSystem.create_blank_character()
	leader["skills"] = {"leadership": 40}
	CharacterSystem.get_party().append(leader)
	var got: int = CharacterSystem.get_max_party_size()
	CharacterSystem.get_party().erase(leader)
	if got != CombatGrid.PLAYER_DEPLOY_SLOTS:
		_fail("max party size at Leadership 40: %d, wanted %d" % [got, CombatGrid.PLAYER_DEPLOY_SLOTS])
	# The data limit alone reaches the cap too (the clamp is the second guard).
	var comp: float = float(PerkSystem.get_base_skill_bonuses_at_level("leadership", 40).get("party_max_companions", 0))
	if int(comp) != CombatGrid.PLAYER_DEPLOY_SLOTS - 1:
		_fail("party_max_companions at 40: %s, wanted %d" % [comp, CombatGrid.PLAYER_DEPLOY_SLOTS - 1])
	_done()


## A name that is not one of the 7 attributes reads 0, as it did before
## stage 2a, not 10 (push_error also logs it).
func _check_unknown_attribute_reads_zero() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	var got: int = CharacterSystem.get_effective_attribute(c, "wisdom")
	if got != 0:
		_fail("unknown attribute 'wisdom' read as %d, wanted 0" % got)
	_done()


# ── Stage 2b: enemies use the one character sheet ───────────────────────────

## The derived stats compared between an enemy and a party character.
const _SHEET_KEYS: Array[String] = ["max_hp", "max_mana", "max_stamina",
	"initiative", "movement", "dodge", "spellpower", "crit_chance", "damage",
	"armor", "accuracy", "armor_pierce", "mana_cost_reduction", "resistances"]


## An enemy and a party character with the same sheet come out the same.
## The enemy is built from an archetype; the party character is a blank
## character handed the enemy's attributes, skills, traits and equipment (and
## the other sheet inputs, so nothing but the code path differs: perks, body,
## racial resistances and affinities). The enemy's derived stats AS BUILT must
## equal what CharacterSystem.update_derived_stats gives the party copy, and
## running the enemy through update_derived_stats again must change nothing.
func _check_enemy_sheet_matches_party() -> void:
	seed(2611)
	var enemy: Dictionary = EnemySystem._build_enemy("hell_demon_warrior", 900, "hell")
	var built: Dictionary = enemy.get("derived", {}).duplicate(true)
	var party: Dictionary = CharacterSystem.create_blank_character()
	for key in ["attributes", "skills", "traits", "equipment", "perks",
			"body_plan", "base_resistances", "racial_affinity_bonuses"]:
		if enemy.has(key):
			party[key] = enemy[key].duplicate(true)
	CharacterSystem.update_derived_stats(party)
	for key in _SHEET_KEYS:
		if str(built.get(key, "missing")) != str(party.derived.get(key, "missing")):
			_fail("enemy sheet %s as built: %s, party formula gives %s"
				% [key, built.get(key, "missing"), party.derived.get(key, "missing")])
	CharacterSystem.update_derived_stats(enemy)
	for key in _SHEET_KEYS:
		if str(enemy.derived.get(key, "missing")) != str(party.derived.get(key, "missing")):
			_fail("enemy sheet %s re-derived: %s, party formula gives %s"
				% [key, enemy.derived.get(key, "missing"), party.derived.get(key, "missing")])
	# What belongs to the party as a group stays with it: a shrine's map buff
	# must not reach an enemy now that it runs through the party's formula.
	var acc: float = float(enemy.derived.get("accuracy", 0))
	var saved_buffs: Array = GameState.active_map_buffs.duplicate(true)
	GameState.active_map_buffs = [{"stat": "accuracy", "amount": 9, "combats_remaining": 1}]
	CharacterSystem.update_derived_stats(enemy)
	GameState.active_map_buffs = saved_buffs
	if float(enemy.derived.get("accuracy", 0)) != acc:
		_fail("the party's +9 accuracy map buff reached an enemy: %s -> %s"
			% [acc, enemy.derived.get("accuracy", 0)])
	CharacterSystem.update_derived_stats(enemy)
	_done()


## An enemy with Swords 5 gets Swords' per-level accuracy. It used to get none,
## because EnemySystem's own formula read the stale key `attack`.
## The tormented shade wears no armour, so nothing on it can lower accuracy.
func _check_enemy_skill_accuracy() -> void:
	seed(2612)
	var enemy: Dictionary = EnemySystem._build_enemy("hell_tormented_shade", 400, "hell")
	enemy["skills"] = {"swords": 5}
	var u := CombatUnit.new()
	add_child(u)
	u.init_as_enemy(enemy)
	ValuePaths.refresh_character(u)
	var acc_spec: Dictionary = PerkSystem._base_bonuses["swords"]["stats"]["accuracy"]
	var want: float = PerkSystem.curve_value(acc_spec, 5)
	if float(enemy.derived.get("accuracy", 0)) < want:
		_fail("enemy swords 5: derived.accuracy %s, wanted at least %s"
			% [enemy.derived.get("accuracy", 0), want])
	u.queue_free()
	_done()


## One enemy of each kind of kit: bare-handed, carrying a trade tool, a boss,
## and one with armour type "none". Each must have a weapon to fight with, a
## positive max_hp, and its archetype's resistances in derived.resistances.
func _check_enemy_kit_variants() -> void:
	var cases: Array[Dictionary] = [
		{"label": "bare-handed", "id": "hell_flame_imp", "realm": "hell",
			"override": {"no_equipment_chance": 1.0}},
		# A medic: Medicine is all it buys, so it carries the medicine bag.
		{"label": "tool-carrier", "id": "hell_demon_warrior", "realm": "hell",
			"override": {"skill_priorities": ["medicine"]}},
		{"label": "boss", "id": "hg_skeleton_king", "realm": "hungry_ghost", "override": {}},
		{"label": "armour none", "id": "hg_rolang_shambler", "realm": "hungry_ghost", "override": {}},
	]
	for case in cases:
		var archetype: Dictionary = EnemySystem.archetypes[case.id]
		var saved: Dictionary = archetype.duplicate(true)
		for key in case.override:
			archetype[key] = case.override[key]
		seed(2613)
		var enemy: Dictionary = EnemySystem._build_enemy(case.id, 1500, case.realm)
		for key in case.override:
			archetype.erase(key)
		archetype.merge(saved, true)

		var u := CombatUnit.new()
		add_child(u)
		u.init_as_enemy(enemy)
		var weapon: Dictionary = u.get_equipped_weapon()
		if weapon.is_empty():
			_fail("%s enemy has no weapon at all" % case.label)
		if int(enemy.get("derived", {}).get("max_hp", 0)) <= 0:
			_fail("%s enemy max_hp %s" % [case.label, enemy.get("derived", {}).get("max_hp", 0)])
		if case.label == "bare-handed" and str(weapon.get("name", "")) != str(enemy.name) + "'s Claws":
			_fail("bare-handed enemy fights with '%s', wanted \"%s's Claws\""
				% [weapon.get("name", ""), enemy.name])
		if case.label == "tool-carrier":
			var held: Dictionary = ItemSystem.get_item(ItemSystem.get_equipped_item(enemy, "weapon_main"))
			if str(held.get("type", "")) != "tool":
				_fail("tool-carrier holds '%s', not a tool" % held.get("name", ""))
		# Archetype resistances: what derived.resistances holds, minus every
		# other source the party formula adds, is the archetype's own number.
		var resists: Dictionary = enemy.get("derived", {}).get("resistances", {})
		if resists.is_empty():
			_fail("%s enemy has no derived.resistances" % case.label)
		var birth_res: Dictionary = CharacterSystem.get_birth_data(str(enemy.get("birth", ""))).get("resistances", {})
		var trait_res: Dictionary = TraitSystem.get_resistances(enemy)
		var gear_res: Dictionary = ItemSystem.calculate_equipment_stats(enemy).get("resistances", {})
		var perk_res: Dictionary = PerkSystem.get_passive_resistances(enemy)
		var arch_res: Dictionary = archetype.get("resistances", {})
		for key in arch_res:
			var others: int = int(birth_res.get(key, 0)) + int(trait_res.get(key, 0)) \
				+ int(gear_res.get(key, 0)) + int(perk_res.get(key, 0))
			if int(resists.get(key, 0)) - others != int(arch_res[key]):
				_fail("%s enemy %s resistance: %s, of which archetype %d (wanted %d)"
					% [case.label, key, resists.get(key, 0),
					int(resists.get(key, 0)) - others, int(arch_res[key])])
		u.queue_free()
	_done()


## The interim party-effects guard (CharacterSystem.receives_party_effects)
## must leave every character the player owns exactly as before: a companion
## who is not on the active roster, and one among the fallen, still receive an
## active map buff. (_check_enemy_sheet_matches_party checks an enemy does not.)
func _check_map_buff_reaches_off_roster_companion() -> void:
	var benched: Dictionary = CharacterSystem.create_blank_character()
	var fallen: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(benched)
	var acc: float = float(benched.derived.get("accuracy", 0))
	CharacterSystem.get_fallen().append(fallen)
	var saved_buffs: Array = GameState.active_map_buffs.duplicate(true)
	GameState.active_map_buffs = [{"stat": "accuracy", "amount": 9, "combats_remaining": 1}]
	CharacterSystem.update_derived_stats(benched)
	CharacterSystem.update_derived_stats(fallen)
	GameState.active_map_buffs = saved_buffs
	CharacterSystem.get_fallen().erase(fallen)
	for who in [["off-roster companion", benched], ["fallen companion", fallen]]:
		var got: float = float(who[1].derived.get("accuracy", 0))
		if got != acc + 9:
			_fail("a +9 accuracy map buff left the %s at %s, wanted %s" % [who[0], got, acc + 9])
	_done()


# ── Stage 2b: the status container ───────────────────────────────────────────

## The status entry for `status_name` on `unit`, or {} if it has none.
func _entry_of(unit: CombatUnit, status_name: String) -> Dictionary:
	for entry in unit.status_effects:
		if str(entry.get("status", "")) == status_name:
			return entry
	return {}


## The eight stat getters a `stat.` hold reaches, plus two resistances, so one
## comparison says "this unit is exactly as it was".
## get_attack_damage() rolls the weapon's damage range, so the roll is seeded
## the same each time to make two snapshots comparable.
func _stat_snapshot(u: CombatUnit) -> Dictionary:
	seed(4242)
	var snap := {
		"initiative": u.get_initiative(), "movement": u.get_movement(),
		"accuracy": u.get_accuracy(), "dodge": u.get_dodge(),
		"damage": u.get_attack_damage(), "armor": u.get_armor(),
		"crit_chance": u.get_crit_chance(), "spellpower": u.get_spellpower(),
		"resist.fire": Resistance.total(u, "fire"),
		"resist.slashing": Resistance.total(u, "slashing"),
		"max_hp": u.max_hp,
	}
	randomize()
	return snap


## A status that holds every stat, two resistances and an attribute.
func _everything_status() -> Dictionary:
	var held: Array = []
	for stat in EffectVocab.STATS:
		held.append({"op": "modify", "value": "stat." + stat, "mode": "fortify", "amount": 3})
	held.append({"op": "modify", "value": "resist.fire", "mode": "fortify", "amount": 20})
	held.append({"op": "modify", "value": "resist.slashing", "mode": "drain", "amount": 10})
	held.append({"op": "modify", "value": "attribute.constitution", "mode": "fortify", "amount": 2})
	# Negative, magical and dispellable, so the real cleanse / dispel / steal
	# selectors pick it (they read polarity and categories since Task 4; the
	# cleanse still asks `dispellable`).
	return {"polarity": "negative", "categories": ["magical"], "dispellable": true,
		"while_active": held}


func _check_status_hold_applies_and_releases() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var name := _with_test_status({"polarity": "positive", "while_active": [
		{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 15}]})
	var base: int = u.get_dodge()
	CombatManager._apply_status_effect(u, name, 3)
	var entry := _entry_of(u, name)
	if not str(entry.get("id", "")).begins_with("status:"):
		_fail("status entry has no status:<n> id: %s" % [entry])
	if u.get_dodge() != base + 15:
		_fail("while_active fortify dodge 15: got %d, wanted %d" % [u.get_dodge(), base + 15])
	CombatManager._end_status(u, entry, "removed")
	if u.get_dodge() != base:
		_fail("dodge after _end_status: got %d, wanted %d" % [u.get_dodge(), base])
	if u.has_status(name) or not u.effect_holds.is_empty():
		_fail("_end_status left the entry or holds: %s / %s" % [u.status_effects, u.effect_holds])
	_cleanup([u])
	_done()


func _check_status_attribute_hold_refreshes() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var name := _with_test_status({"polarity": "positive", "while_active": [
		{"op": "modify", "value": "attribute.constitution", "mode": "fortify", "amount": 4}]})
	var base: int = u.max_hp
	CombatManager._apply_status_effect(u, name, 3)
	if u.max_hp != base + 40:
		_fail("constitution +4 status: max_hp %d, wanted %d" % [u.max_hp, base + 40])
	CombatManager._end_status(u, _entry_of(u, name), "expired")
	if u.max_hp != base:
		_fail("max_hp after the status ended: %d, wanted %d" % [u.max_hp, base])
	_cleanup([u])
	_done()


## Every reason a status can end for puts the unit back exactly as it was. Each
## reason is ended directly through _end_status; the real paths that use the
## reasons (expiry at turn start, the duration-only tick, cleanse, removal by
## name, steal, end of combat) are walked as well.
func _check_every_exit_releases() -> void:
	var name := _with_test_status(_everything_status())
	for reason in ["expired", "dispelled", "cleansed", "removed", "stolen", "consumed",
			"death", "combat_end", "upkeep"]:
		var u := _make_unit(Vector2i(5, 5))
		var before := _stat_snapshot(u)
		CombatManager._apply_status_effect(u, name, 3)
		if _stat_snapshot(u) == before:
			_fail("%s: setup — the status changed nothing" % reason)
		CombatManager._end_status(u, _entry_of(u, name), reason)
		var after := _stat_snapshot(u)
		if after != before:
			_fail("%s: unit not restored: %s vs %s" % [reason, after, before])
		if u.has_status(name) or not u.effect_holds.is_empty():
			_fail("%s: entry or holds left behind" % reason)
		_cleanup([u])

	var paths: Dictionary = {
		"turn-start expiry": func(u: CombatUnit) -> void:
			_entry_of(u, name)["duration"] = 1
			CombatManager._process_status_effects(u),
		"duration-only tick": func(u: CombatUnit) -> void:
			_entry_of(u, name)["duration"] = 1
			CombatManager._tick_durations_only(u),
		"cleanse": func(u: CombatUnit) -> void:
			CombatManager._cleanse_status_effects(u, 1),
		"remove by name": func(u: CombatUnit) -> void:
			CombatManager._remove_status_by_name(u, name),
		"remove op": func(u: CombatUnit) -> void:
			CombatManager._remove_selected_statuses(u, {"names": [name]}),
		"end of combat": func(_u: CombatUnit) -> void:
			_end_fight(),
	}
	for label in paths:
		var u := _make_unit(Vector2i(5, 5))
		var before := _stat_snapshot(u)
		CombatManager._apply_status_effect(u, name, 3)
		paths[label].call(u)
		if _stat_snapshot(u) != before or u.has_status(name) or not u.effect_holds.is_empty():
			_fail("%s: unit not restored (%s vs %s, statuses %s)"
				% [label, _stat_snapshot(u), before, u.status_effects])
		_cleanup([u])

	# Steal: the victim is restored, the thief gains it under a NEW id.
	var thief := _make_unit(Vector2i(2, 2))
	var victim := _make_unit(Vector2i(5, 5))
	var victim_before := _stat_snapshot(victim)
	var thief_before := _stat_snapshot(thief)
	CombatManager._apply_status_effect(victim, name, 3)
	var old_id: String = str(_entry_of(victim, name).get("id", ""))
	CombatManager._apply_status_op(thief, victim, {"op": "steal",
		"select": {"names": [name]}, "from": "target", "to": "caster"}, {"effects_applied": []})
	if _stat_snapshot(victim) != victim_before or not victim.effect_holds.is_empty():
		_fail("steal: victim not restored")
	var stolen := _entry_of(thief, name)
	if stolen.is_empty() or str(stolen.get("id", "")) == old_id:
		_fail("steal: the thief's entry should be new, got %s (old id %s)" % [stolen, old_id])
	if thief.get_dodge() != thief_before.dodge + 3:
		_fail("steal: the thief does not hold the stolen dodge")
	CombatManager._end_status(thief, stolen, "removed")
	if _stat_snapshot(thief) != thief_before:
		_fail("steal: the thief not restored after its copy ended")
	_cleanup([thief, victim])
	_done()


func _check_refresh_does_not_double() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var name := _with_test_status({"polarity": "positive", "stacking": {"mode": "refresh"},
		"while_active": [{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 15}]})
	var base: int = u.get_dodge()
	CombatManager._apply_status_effect(u, name, 2)
	CombatManager._apply_status_effect(u, name, 4)
	if u.get_dodge() != base + 15:
		_fail("refresh twice: dodge %d, wanted %d" % [u.get_dodge(), base + 15])
	if u.status_effects.size() != 1 or int(_entry_of(u, name).get("duration", 0)) != 4:
		_fail("refresh should keep one entry with the longer duration: %s" % [u.status_effects])
	_cleanup([u])
	_done()


func _check_stack_scales_holds() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var name := _with_test_status({"polarity": "positive", "stacking": {"mode": "stack", "max": 5},
		"while_active": [{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 15}]})
	var base: int = u.get_dodge()
	for _i in 3:
		CombatManager._apply_status_effect(u, name, 3)
	var entry := _entry_of(u, name)
	if u.status_effects.size() != 1 or int(entry.get("stacks", 0)) != 3:
		_fail("three stacking applications: %s" % [u.status_effects])
	if u.get_dodge() != base + 45:
		_fail("3 stacks: dodge %d, wanted %d" % [u.get_dodge(), base + 45])
	CombatManager._remove_stacks(u, entry, 1, "consumed")
	if u.get_dodge() != base + 30:
		_fail("2 stacks after consuming one: dodge %d, wanted %d" % [u.get_dodge(), base + 30])
	# The cap holds.
	for _i in 6:
		CombatManager._apply_status_effect(u, name, 3)
	if int(entry.get("stacks", 0)) != 5 or u.get_dodge() != base + 75:
		_fail("max 5 stacks: %s stacks, dodge %d" % [entry.get("stacks"), u.get_dodge()])
	CombatManager._remove_stacks(u, entry, 5, "consumed")
	if u.has_status(name) or u.get_dodge() != base:
		_fail("consuming every stack should end the status")
	_cleanup([u])
	_done()


func _check_periodic_damage_ticks() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var name := _with_test_status({"polarity": "negative",
		"periodic": {"when": "turn_start", "effects": [{"op": "damage", "amount": 5, "type": "fire"}]}})
	var later := _with_test_status({"polarity": "negative",
		"periodic": {"when": "turn_end", "effects": [{"op": "damage", "amount": 4, "type": "fire"}]}})
	var resist: float = Resistance.total(u, "fire")
	CombatManager._apply_status_effect(u, name, 3)
	for tick in 2:
		var hp: int = u.current_hp
		CombatManager._process_status_effects(u)
		if hp - u.current_hp != 5:
			_fail("periodic turn_start tick %d: lost %d HP, wanted 5 (fire resist %s)"
				% [tick, hp - u.current_hp, resist])
	if int(_entry_of(u, name).get("turns_active", -1)) != 2:
		_fail("turns_active after two turn starts: %s" % [_entry_of(u, name)])
	CombatManager._end_status(u, _entry_of(u, name), "removed")
	CombatManager._apply_status_effect(u, later, 3)
	var hp2: int = u.current_hp
	CombatManager._process_status_effects(u)
	if u.current_hp != hp2:
		_fail("a turn_end periodic ticked at turn start")
	CombatManager._process_status_turn_end(u)
	if hp2 - u.current_hp != 4:
		_fail("periodic turn_end: lost %d HP, wanted 4" % (hp2 - u.current_hp))
	_cleanup([u])
	_done()


## An `expire` trigger runs when the status runs out, not when it is removed.
func _check_expire_trigger_fires_on_expiry_only() -> void:
	var name := _with_test_status({"polarity": "negative", "triggers": [
		{"on": "expire", "effects": [{"op": "damage", "amount": 7, "type": "fire"}]}]})
	var u := _make_unit(Vector2i(5, 5))
	CombatManager._apply_status_effect(u, name, 1)
	var hp: int = u.current_hp
	CombatManager._process_status_effects(u)
	if hp - u.current_hp != 7 or u.has_status(name):
		_fail("expire trigger on expiry: lost %d HP, wanted 7" % (hp - u.current_hp))
	CombatManager._apply_status_effect(u, name, 3)
	hp = u.current_hp
	CombatManager._remove_status_by_name(u, name)
	if u.current_hp != hp:
		_fail("expire trigger fired on removal")
	_cleanup([u])
	_done()


func _check_immune_flag_blocks() -> void:
	var ward := _with_test_status({"polarity": "positive", "flags": ["immune:control"]})
	var shield := _with_test_status({"polarity": "positive", "flags": ["immune:negative"]})
	var hold := _with_test_status({"polarity": "negative", "categories": ["control"]})
	var hex := _with_test_status({"polarity": "negative", "categories": ["curse"]})
	var boon := _with_test_status({"polarity": "positive", "categories": ["blessing"]})
	var u := _make_unit(Vector2i(5, 5))
	CombatManager._apply_status_effect(u, ward, 3)
	if not StatusRules.has_flag(u, "immune:control"):
		_fail("has_flag does not see immune:control")
	CombatManager._apply_status_effect(u, hold, 3)
	if u.has_status(hold):
		_fail("immune:control let a control status on")
	CombatManager._apply_status_effect(u, hex, 3)
	if not u.has_status(hex):
		_fail("immune:control blocked a curse")
	var v := _make_unit(Vector2i(6, 6))
	CombatManager._apply_status_effect(v, shield, 3)
	CombatManager._apply_status_effect(v, hex, 3)
	CombatManager._apply_status_effect(v, boon, 3)
	if v.has_status(hex):
		_fail("immune:negative let a negative status on")
	if not v.has_status(boon):
		_fail("immune:negative blocked a positive status")
	_cleanup([u, v])
	_done()


## A save written before status entries had ids still loads, gets ids, and its
## statuses end cleanly. Uses the scratch save folder only.
func _check_old_save_entries_get_ids() -> void:
	var real_dir: String = SaveManager.SAVE_DIR
	var scratch: String = "user://verify_scratch_saves/"
	DirAccess.make_dir_recursive_absolute(scratch)
	SaveManager.SAVE_DIR = scratch
	var old_slot: int = SaveManager.current_slot
	var snap_game: Dictionary = GameState.get_save_data().duplicate(true)
	var snap_chars: Dictionary = CharacterSystem.get_save_data().duplicate(true)
	var snap_items: Dictionary = ItemSystem.get_save_data().duplicate(true)
	var snap_karma: Dictionary = KarmaSystem.get_save_data().duplicate(true)
	var snap_map: Dictionary = MapManager.get_save_data().duplicate(true)

	var ch: Dictionary = CharacterSystem.create_blank_character()
	ch["name"] = "Old Save Probe"
	ch["overworld_statuses"] = [
		{"status": "Poisoned", "duration": 3, "damage_per_step": 3},
		{"status": "Bleeding", "duration": 2, "damage_per_step": 2}]
	CharacterSystem.get_party().append(ch)
	var saved: bool = SaveManager.save_game(3)
	CharacterSystem.get_party().erase(ch)
	var loaded: bool = SaveManager.load_game(3)
	if not saved or not loaded:
		_fail("save/load of slot 3 failed (saved %s, loaded %s)" % [saved, loaded])
	else:
		var back: Dictionary = {}
		for member in CharacterSystem.get_party():
			if str(member.get("name", "")) == "Old Save Probe":
				back = member
		var entries: Array = back.get("overworld_statuses", [])
		var ids: Array[String] = []
		for entry in entries:
			var id: String = str(entry.get("id", ""))
			if not id.begins_with("status:") or id in ids:
				_fail("loaded legacy entry without a unique id: %s" % [entry])
			ids.append(id)
		if entries.size() != 2:
			_fail("legacy entries came back as %s" % [entries])
		# End them cleanly on a unit, the single exit, as a fight would.
		var u := _make_unit(Vector2i(5, 5))
		var before := _stat_snapshot(u)
		for entry in entries:
			u.status_effects.append(entry.duplicate())
		u.status_effects.append({"status": "Bleeding", "duration": 2})   # no id at all
		for entry in u.status_effects.duplicate():
			CombatManager._end_status(u, entry, "removed")
		if not u.status_effects.is_empty() or _stat_snapshot(u) != before:
			_fail("legacy entries did not end cleanly: %s" % [u.status_effects])
		_cleanup([u])

	SaveManager.SAVE_DIR = real_dir
	for fname in ["slot_3.json", "meta.json"]:
		if FileAccess.file_exists(scratch + fname):
			DirAccess.remove_absolute(scratch + fname)
	DirAccess.remove_absolute(scratch)
	GameState.load_save_data(snap_game)
	CharacterSystem.load_save_data(snap_chars)
	ItemSystem.load_save_data(snap_items)
	KarmaSystem.load_save_data(snap_karma)
	MapManager.load_save_data(snap_map)
	SaveManager.current_slot = old_slot
	_done()


# ── Stage 2b, Task 4: the statuses' numbers, migrated ───────────────────────

const StatusMeasure = preload("res://tools/status_measure.gd")
const STATUS_BASELINE_PATH: String = "res://tools/fixtures/status_baseline.json"
const STATUS_TAGS_PATH: String = "res://tools/fixtures/status_tags.json"

## The statuses whose numbers changed ON PURPOSE in the migration, with what
## they change now, on the two reference units (tools/status_measure.gd).
## Every other status must change exactly what the baseline says it did.
##
## Spec section 7, statuses named for a number do what the name says: a hold
## on that attribute, and the derived stats follow it (CombatStats.attribute_terms:
## dodge = Finesse, initiative = Finesse + Awareness, movement = Finesse / 3,
## spellpower = Focus, crit = 5 + (Awareness + Finesse + Luck) / 6; melee
## damage adds Strength). The old table gave +5 dodge / +3 initiative for
## Finesse_Plus_2 and +3 or -3 spellpower or damage for the rest.
## Where a row differs between the two units it is a step in a divided term:
## the party unit (all 10s) gains a movement point from Finesse 12 (12 / 3),
## while the reference enemy's Awareness + Finesse + Luck crosses a multiple
## of 6 and gains a crit point.
##
## movement_reduced_50 (Slowed, Movement_Debuff, Slowed_After_Escape) halves
## the movement TOTAL now instead of subtracting half the base. On a unit with
## no other movement bonus that is the same number, so these rows equal the
## baseline; they are listed so the rule they follow is stated here.
const STATUS_CHANGED_NUMBERS: Dictionary = {
	"Strength_Plus_2": {"party": {"damage": 2.0}, "enemy": {"damage": 2.0}},
	"Finesse_Plus_2": {"party": {"dodge": 2.0, "initiative": 2.0, "movement": 1.0},
		"enemy": {"dodge": 2.0, "initiative": 2.0, "crit_chance": 1.0}},
	"Focus_Plus_3": {"party": {"spellpower": 3.0}, "enemy": {"spellpower": 3.0}},
	"Focus_Minus_2": {"party": {"spellpower": -2.0}, "enemy": {"spellpower": -2.0}},
	"Awareness_Plus_3": {"party": {"initiative": 3.0},
		"enemy": {"initiative": 3.0, "crit_chance": 1.0}},
	"Constitution_Minus_2": {"party": {}, "enemy": {}},
	"Slowed": {"party": {"movement": -1.0}, "enemy": {"movement": -3.0}},
	"Movement_Debuff": {"party": {"movement": -1.0}, "enemy": {"movement": -3.0}},
	"Slowed_After_Escape": {"party": {"movement": -1.0}, "enemy": {"movement": -3.0}},
	# Owner ruling 2026-11-27: the _50 in the name was right and the 40 wrong.
	"Ranged_Attack_Debuff_50": {"party": {"accuracy": -50.0}, "enemy": {"accuracy": -50.0}},
}

## The words CombatUnit._get_status_stat_bonus turned into numbers. That table
## is gone, so a status still carrying one of these would do nothing; each
## must have become a `while_active` modify. (range_bonus / range_penalty were
## in the table too but no getter ever read them; they are left alone.)
const RETIRED_STAT_WORDS: Array[String] = [
	"accuracy_bonus", "all_stats_penalty", "armor_bonus_minor", "armor_reduced",
	"armor_reduced_50", "attack_bonus", "attack_penalty", "awareness_bonus",
	"awareness_bonus_major", "awareness_penalty_major", "buffs_all_stats_considerably",
	"buffs_two_highest_stats", "critical_bonus_ranged", "critical_boost",
	"damage_bonus", "damage_boost", "damage_reduction", "defense_bonus",
	"defense_penalty", "dodge_bonus", "dodge_penalty", "evasion_bonus",
	"finesse_bonus", "focus_bonus", "focus_bonus_major", "focus_penalty",
	"focus_penalty_major", "initiative_bonus", "initiative_penalty", "luck_bonus",
	"major_dodge_bonus", "major_speed_boost", "melee_damage_bonus",
	"melee_hit_chance_halved", "minor_all_stats_bonus", "minor_dodge_bonus",
	"movement_reduced_50", "ranged_damage_halved", "ranged_hit_chance_halved",
	"speed_bonus", "speed_penalty", "strength_bonus", "strength_bonus_major",
	"constitution_bonus", "constitution_penalty",
]


func _read_fixture(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("cannot open %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## "a +2, b -1" for a failure message.
func _changes_text(d: Dictionary) -> String:
	var keys: Array = d.keys()
	keys.sort()
	var parts: Array[String] = []
	for k in keys:
		parts.append("%s %s%s" % [k, "+" if float(d[k]) > 0 else "", str(float(d[k]))])
	return "{" + ", ".join(parts) + "}" if not parts.is_empty() else "{}"


func _same_changes(a: Dictionary, b: Dictionary) -> bool:
	for k in a:
		if not is_equal_approx(float(a[k]), float(b.get(k, 0.0))):
			return false
	for k in b:
		if not a.has(k) and not is_zero_approx(float(b[k])):
			return false
	return true


## Every status changes the eight getters and every resistance exactly as it
## did before the migration (tools/fixtures/status_baseline.json), apart from
## the listed deliberate changes. Real data, real _apply_status_effect.
func _check_status_numbers_match_baseline() -> void:
	var baseline: Dictionary = _read_fixture(STATUS_BASELINE_PATH).get("statuses", {})
	var defs: Dictionary = CombatManager.get_all_status_definitions()
	var shown: int = 0
	for name in defs:
		if not str(name).begins_with("_") and not baseline.has(name):
			_fail("status %s is not in the baseline (added after it was captured?)" % name)
	for name in baseline:
		if not defs.has(name):
			_fail("baseline status %s is gone from statuses.json" % name)
			continue
		for word in defs[name].get("effects", []):
			if str(word) in RETIRED_STAT_WORDS:
				_fail("%s still carries the stat word '%s', which nothing reads now"
					% [name, word])
		for kind in StatusMeasure.KINDS:
			var want: Dictionary = baseline[name].get(kind, {})
			if STATUS_CHANGED_NUMBERS.has(name):
				want = STATUS_CHANGED_NUMBERS[name][kind]
			var got: Dictionary = StatusMeasure.measure_one(self, grid, name, kind)
			if not _same_changes(got, want):
				shown += 1
				if shown <= 25:
					_fail("%s on the %s unit changes %s, wanted %s"
						% [name, kind, _changes_text(got), _changes_text(want)])
	if shown > 25:
		_fail("... and %d more status numbers differ" % (shown - 25))
	_done()


## Each StatusOps.TAGS selector picks exactly the statuses it picked before
## the migration, now reading polarity and categories instead of type.
func _check_status_tags_select_same() -> void:
	var before: Dictionary = _read_fixture(STATUS_TAGS_PATH).get("tags", {})
	var now: Dictionary = StatusMeasure.tag_selections(CombatManager.get_all_status_definitions())
	for tag in StatusOps.TAGS:
		var a: Array = before.get(tag, [])
		var b: Array = now.get(tag, [])
		if a != b:
			var lost: Array = a.filter(func(n): return not n in b)
			var gained: Array = b.filter(func(n): return not n in a)
			_fail("tag %s: lost %s, gained %s" % [tag, lost, gained])
	_done()


# ── Stage 2b, Task 5: yes/no words became flags ──────────────────────────────

const STATUS_WORDS_PATH: String = "res://tools/fixtures/status_words.json"

## word -> flag(s), the yes/no words of statuses.json. Written out by hand here, on
## purpose: it is the check's own copy of the migration's mapping.
const FLAG_FOR_WORD: Dictionary = {
	"attack_breaks_invisibility": ["attack_breaks_invisibility"],
	"attack_damage_buff_when_ally_dies": ["attack_damage_buff_when_ally_dies"],
	# Task 6 turned these two into intercepting triggers (on: incoming_attack /
	# incoming_spell with reflect); they are flags no more.
	"attack_reflect_chance": [],
	"attacks_closest_creature": ["attacks_closest_creature"],
	"attacks_have_miss_chance": ["attacks_have_miss_chance"],
	"breaks_on_offensive_action": ["breaks_on_offensive_action"],
	"can_move_through_enemies": ["can_move_through_enemies"],
	"cannot_act": ["cannot_act"],
	"cannot_attack": ["cannot_attack"],
	"cannot_be_targeted": ["cannot_be_targeted"],
	"cannot_cast": ["cannot_cast"],
	"cannot_deal_physical": ["cannot_deal_physical"],
	"cannot_die": ["cannot_die"],
	"cannot_make_weapon_attacks": ["cannot_make_weapon_attacks"],
	"cannot_move": ["cannot_move"],
	"cannot_target_enemies": ["cannot_target_enemies"],
	"cannot_use_ranged": ["cannot_use_ranged"],
	"charm_chance_on_enemy_melee_approach": ["charm_chance_on_enemy_melee_approach"],
	"controlled_by_caster": ["controlled_by_caster"],
	"copies_absorb_attacks": ["copies_absorb_attacks"],
	"crit_vulnerability": ["crit_vulnerability"],
	"damage_on_move_attempt": ["damage_on_move_attempt"],
	"damage_taken_increase": ["damage_taken_increase"],
	"death_resistance": ["death_resistance"],
	"disengaged_from_combat": ["disengaged_from_combat"],
	"flee_from_source": ["flee_from_source"],
	"focus_save_on_damage": ["focus_save_on_damage"],
	"forced_movement_toward_target": ["forced_movement_toward_target"],
	"grants_extra_action": ["grants_extra_action"],
	"grants_flight": ["grants_flight"],
	"hp_cannot_drop_below_1": ["hp_cannot_drop_below_1"],
	"hp_shield": ["hp_shield"],
	"ignores_allegiance": ["ignores_allegiance"],
	"immune_to_ground_effects": ["immune_to_ground_effects"],
	"immune_to_melee_unless_flyer": ["immune_to_melee_unless_flyer"],
	"immune_to_ranged": ["immune_to_ranged"],
	"immune_to_terrain_hazards": ["immune_to_terrain_hazards"],
	"immune_to_water_terrain": ["immune_to_water_terrain"],
	"increase_burning_damage_dealt": ["increase_burning_damage_dealt"],
	"loses_flight": ["loses_flight"],
	"must_attack_taunter": ["must_attack_taunter"],
	"next_attack_misses": ["next_attack_misses"],
	"next_ranged_guaranteed_hit": ["next_ranged_guaranteed_hit"],
	"prevents_teleportation": ["prevents_teleportation"],
	"prone_chance_on_movement": ["prone_chance_on_movement"],
	"random_movement": ["random_movement"],
	"random_target": ["random_target"],
	"ranged_damage_reduction": ["ranged_damage_reduction"],
	"remove_all_debuffs": ["remove_all_debuffs"],
	"return_on_death_next_turn": ["return_on_death_next_turn"],
	"riposte_next_sword_attack": ["riposte_next_sword_attack"],
	"rooted": ["rooted"],
	"share_healing_75_percent": ["share_healing_75_percent"],
	"skip_next_action": ["skip_next_action"],
	"skip_turn": ["skip_turn"],
	"spell_damage_reduction": ["spell_damage_reduction"],
	"spell_reflect_chance": [],
	"stealth_bonus": ["stealth_bonus"],
	"stun_chance_on_hit": ["stun_chance_on_hit"],
	"treats_caster_as_ally": ["treats_caster_as_ally"],
	"will_not_attack": ["will_not_attack"],
	"will_not_attack_caster": ["will_not_attack_caster"],
	"immobilized": ["cannot_move"],
	"silenced": ["cannot_cast"],
	"immune_to_charm": ["immune:Charmed", "immune:Dominated"],
	"immune_to_fear": ["immune:Feared"],
	"immune_to_confusion": ["immune:Confused", "immune:Chaotic"],
	"debuff_immunity": ["immune:negative"],
	# Each named the lifesteal Lifelink and Blood_Hunger always had (it was
	# read by status name), so the flag is what the word meant.
	"heal_50_percent_of_damage_dealt": ["lifesteals_on_hit"],
	"lifesteal_on_attacks": ["lifesteals_on_hit"],
}

## Statuses a hard-coded name list used to pick out, now carrying a flag.
const FLAG_FOR_NAME: Dictionary = {
	"Stunned": ["breaks_concentration"], "Feared": ["breaks_concentration", "counts_as_demoralized"],
	"Charmed": ["breaks_concentration", "breaks_on_damage_from_source"],
	"Confused": ["breaks_concentration"], "Berserk": ["breaks_concentration"],
	"Frozen": ["breaks_concentration"], "Petrified": ["breaks_concentration"],
	"Held": ["breaks_concentration"], "Paralyzed": ["breaks_concentration"],
	"Immobilized": ["breaks_concentration"], "Dominated": ["breaks_concentration"],
	"Chaotic": ["breaks_concentration"], "Invisible": ["grants_stealth"],
	"Lifelink": ["lifesteals_on_hit"], "Blood_Hunger": ["lifesteals_on_hit"],
	"Demoralized": ["counts_as_demoralized"], "Gloomy": ["counts_as_demoralized"],
}

## Words Task 5 left in `effects` for Task 6, because something read them as
## more than a yes/no (a damage type, a tick, an expiry hook, a save, an
## enchant table). Task 6 made each a periodic effect, a trigger or a save, so
## no status keeps them (_check_no_legacy_status_keys checks the shapes).
const WORDS_LEFT_FOR_TASK_6: Array[String] = [
	"fire_damage_per_turn", "poison_damage_per_turn", "physical_damage_per_turn",
	"black_damage_per_turn", "space_damage_per_turn", "heal_per_turn",
	"death_on_expire", "damage_on_expire", "bleed_on_expire", "save_at_end_of_turn",
	"adds_fire_damage_to_attacks", "adds_air_damage_to_attacks",
]

## Words nothing ever read. They are gone from the data, and the status says so
## in its `notes`.
const UNBUILT_WORDS: Array[String] = [
	"can_move", "cannot_target_spells", "fire_damage_per_turn_internal",
	"joins_party_permanently", "damage_increases_each_turn", "stat_penalties",
	"illusory_copies", "cannot_teleport", "cannot_flee", "random_attacks",
	"random_spellcasting", "relationship_bonus",
	"linked_to_ally", "return_with_20_percent_hp",
	"cannot_fly", "knockback", "can_walk_on_water", "range_bonus", "range_penalty",
]


## For every status, `flags` is exactly what its old yes/no words (plus the
## hard-coded name lists) say, `effects` is gone (Task 6), and a
## status that had a word nothing read says so in `notes`.
func _check_flags_match_old_words() -> void:
	var old: Dictionary = _read_fixture(STATUS_WORDS_PATH).get("statuses", {})
	var defs: Dictionary = CombatManager.get_all_status_definitions()
	if old.size() < 150:
		_fail("status_words.json has only %d statuses" % old.size())
	var shown: int = 0
	for name in old:
		if not defs.has(name):
			_fail("%s is in status_words.json but not in statuses.json" % name)
			continue
		var want_flags: Array = []
		var want_effects: Array = []
		var unbuilt: Array = []
		for word in old[name].get("effects", []):
			if FLAG_FOR_WORD.has(word):
				for f in FLAG_FOR_WORD[word]:
					if not f in want_flags:
						want_flags.append(f)
			elif word in WORDS_LEFT_FOR_TASK_6:
				pass   # Task 6 made each a periodic effect, trigger or save: `effects` is gone
			elif word in UNBUILT_WORDS:
				unbuilt.append(word)
		for f in FLAG_FOR_NAME.get(name, []):
			if not f in want_flags:
				want_flags.append(f)
		var got_flags: Array = defs[name].get("flags", [])
		var got_effects: Array = defs[name].get("effects", [])
		var a: Array = want_flags.duplicate()
		var b: Array = got_flags.duplicate()
		a.sort()
		b.sort()
		if a != b or got_effects != want_effects:
			shown += 1
			if shown <= 20:
				_fail("%s: flags %s effects %s, wanted flags %s effects %s"
					% [name, got_flags, got_effects, want_flags, want_effects])
		var notes: String = str(defs[name].get("notes", ""))
		for word in unbuilt:
			if not str(word) in notes:
				_fail("%s lost the unbuilt word '%s' without saying so in notes" % [name, word])
		if unbuilt.is_empty() and notes.begins_with("Unbuilt:"):
			_fail("%s says Unbuilt in notes but had no such word" % name)
	if shown > 20:
		_fail("... and %d more statuses differ" % (shown - 20))
	_done()


## A status carrying the `breaks_concentration` flag interrupts a mantra when
## it lands (and one without the flag does not), whatever it is called.
func _check_concentration_breaks_on_flag() -> void:
	var rattling := _with_test_status({"polarity": "negative", "flags": ["breaks_concentration"]})
	var gentle := _with_test_status({"polarity": "negative"})
	var u := _make_unit(Vector2i(5, 5))
	u.active_mantras = {"some_mantra": 2}
	CombatManager._apply_status_effect(u, gentle, 2)
	if u.active_mantras.is_empty():
		_fail("a status without the flag broke concentration")
	CombatManager._apply_status_effect(u, rattling, 2)
	if not u.active_mantras.is_empty():
		_fail("a status with breaks_concentration did not interrupt the mantra")
	# A refresh counts too.
	u.active_mantras = {"some_mantra": 2}
	CombatManager._apply_status_effect(u, rattling, 3)
	if not u.active_mantras.is_empty():
		_fail("refreshing a breaks_concentration status did not interrupt the mantra")
	# The real hard-control statuses carry it.
	for real in ["Stunned", "Frozen", "Held", "Feared", "Chaotic"]:
		if not "breaks_concentration" in CombatManager.get_status_definition(real).get("flags", []):
			_fail("%s does not carry breaks_concentration" % real)
	_cleanup([u])
	_done()


## Mental_Immunity says what it blocks as `immune:` flags, and the one shared
## immunity rule (StatusRules.immune_to) is what keeps the statuses off.
func _check_mental_immunity_by_flag() -> void:
	var flags: Array = CombatManager.get_status_definition("Mental_Immunity").get("flags", [])
	for want in ["immune:Charmed", "immune:Dominated", "immune:Feared",
			"immune:Confused", "immune:Chaotic"]:
		if not want in flags:
			_fail("Mental_Immunity has no %s flag (has %s)" % [want, flags])
	if not "immune:negative" in CombatManager.get_status_definition("Cleansed").get("flags", []):
		_fail("Cleansed has no immune:negative flag")
	var u := _make_unit(Vector2i(5, 5))
	CombatManager._apply_status_effect(u, "Mental_Immunity", 3)
	for blocked in ["Charmed", "Feared", "Dominated", "Confused", "Chaotic"]:
		CombatManager._apply_status_effect(u, blocked, 2)
		if u.has_status(blocked):
			_fail("Mental_Immunity let %s on" % blocked)
	CombatManager._apply_status_effect(u, "Burning", 2)
	if not u.has_status("Burning"):
		_fail("Mental_Immunity blocked Burning, which it never did")
	_cleanup([u])
	_done()


# ── Stage 2b, Task 6: triggers, periodic effects, intercepts ────────────────

## The status a definition's first trigger with `on` belongs to, or {}.
func _trigger_on(def: Dictionary, on: String) -> Dictionary:
	for t in def.get("triggers", []):
		if typeof(t) == TYPE_DICTIONARY and str(t.get("on", "")) == on:
			return t
	return {}


## Burning ticks the value the spell gave it ({from: status.value}), and its
## own 5 when the spell gave none ({default: 5}), at the start of the turn.
func _check_dot_uses_spell_value() -> void:
	var def: Dictionary = CombatManager.get_status_definition("Burning")
	var per: Dictionary = def.get("periodic", {})
	if per.is_empty() or def.has("damage_per_turn") or def.has("effects"):
		_fail("Burning is not a periodic effect yet: %s" % [def])
	var u := _make_unit(Vector2i(5, 5))
	for pair in [[9, 9], [0, 5]]:
		for entry in u.status_effects.duplicate():
			CombatManager._end_status(u, entry, "removed")
		CombatManager._apply_status_effect(u, "Burning", 3, int(pair[0]))
		var hp: int = u.current_hp
		CombatManager._process_status_effects(u)
		if hp - u.current_hp != int(pair[1]):
			_fail("Burning with value %d ticked %d, wanted %d"
				% [pair[0], hp - u.current_hp, pair[1]])
	_cleanup([u])
	_done()


## Fireshield hits a melee attacker back for its 5 fire, as a `struck` trigger.
func _check_retaliation_trigger() -> void:
	var def: Dictionary = CombatManager.get_status_definition("Fireshield")
	if def.has("retaliation") or _trigger_on(def, "struck").is_empty():
		_fail("Fireshield still has no struck trigger: %s" % [def])
	var defender := _make_unit(Vector2i(5, 5), 0)
	var attacker := _make_unit(Vector2i(6, 5), 1)
	CombatManager._apply_status_effect(defender, "Fireshield", 3)
	var hp: int = attacker.current_hp
	CombatManager._process_reactive_statuses(attacker, defender, {"damage": 10})
	if hp - attacker.current_hp != 5:
		_fail("Fireshield struck back for %d, wanted 5" % (hp - attacker.current_hp))
	_cleanup([defender, attacker])
	_done()


## Infected hatches its Fungal Spawn when it runs out, and not when dispelled.
func _check_expire_summon() -> void:
	var def: Dictionary = CombatManager.get_status_definition("Infected")
	var t: Dictionary = _trigger_on(def, "expire")
	var summons: bool = false
	for e in t.get("effects", []):
		if str(e.get("op", "")) == "summon" and str(e.get("as", "")) == "Fungal_Spawn":
			summons = true
	if def.has("summon_on_expire") or not summons:
		_fail("Infected has no expire trigger that summons Fungal_Spawn: %s" % [def])
	var victim := _make_unit(Vector2i(8, 8), 1)
	# Whoever infected the victim owns what hatches (owner ruling 2026-11-27):
	# the spawn fights for the caster, not for the body it burst from.
	var infector := _make_unit(Vector2i(2, 2), 0)
	var before_units: Array = CombatManager.all_units.duplicate()
	var before: int = before_units.size()
	CombatManager._apply_status_effect(victim, "Infected", 1, 0, infector)
	CombatManager._process_status_effects(victim)
	var after_expiry: int = CombatManager.all_units.size()
	if after_expiry != before + 1:
		_fail("Infected expired and %d units appeared, wanted 1" % (after_expiry - before))
	for unit in CombatManager.all_units:
		if not unit in before_units and unit.team != infector.team:
			_fail("the Fungal Spawn fights for team %d; the infector is team %d"
				% [unit.team, infector.team])
	victim.current_hp = victim.max_hp
	CombatManager._apply_status_effect(victim, "Infected", 3)
	CombatManager._end_status(victim, _entry_of(victim, "Infected"), "dispelled")
	if CombatManager.all_units.size() != after_expiry:
		_fail("dispelling Infected hatched something")
	for unit in CombatManager.all_units.duplicate():
		if unit != victim and is_instance_valid(unit) and unit.unit_name != "Probe0" \
				and unit.unit_name != "Probe1":
			_cleanup([unit])
	_cleanup([victim, infector])
	_done()


## Heavenly Counterflow's `negate` turns aside one melee blow before it lands,
## then its limit (1 a turn) lets the next one through.
func _check_intercept_negate() -> void:
	var def: Dictionary = CombatManager.get_status_definition("Heavenly_Counterflow")
	var t: Dictionary = _trigger_on(def, "attacked_in_melee")
	var negates: bool = false
	for e in t.get("effects", []):
		if str(e.get("op", "")) == "negate":
			negates = true
	if def.has("reaction") or not negates:
		_fail("Heavenly_Counterflow has no attacked_in_melee trigger with negate: %s" % [def])
	var monk := _make_unit(Vector2i(10, 10), 0)
	var foe := _make_unit(Vector2i(11, 10), 1)
	for u in [monk, foe]:
		u.character_data["derived"]["accuracy"] = 999
		u.character_data["derived"]["dodge"] = 0
		u.max_hp = 100000
		u.current_hp = 100000
	CombatManager._apply_status_effect(monk, "Heavenly_Counterflow", 2)
	var landed: Array[int] = []
	for blow in 2:
		# Back into melee every time: the counterflow steps away.
		grid.unit_positions.erase(monk.grid_position)
		monk.grid_position = Vector2i(10, 10)
		grid.unit_positions[monk.grid_position] = monk
		var hp: int = monk.current_hp
		var result: Dictionary = {}
		for _try in 20:
			foe.actions_remaining = 9
			CombatManager.turn_order = [foe]
			CombatManager.current_unit_index = 0
			result = CombatManager.attack_unit(foe, monk)
			if bool(result.get("hit", false)) or bool(result.get("dodged", false)):
				break
		landed.append(hp - monk.current_hp)
	if landed[0] != 0:
		_fail("the first blow landed for %d through the counterflow" % landed[0])
	if landed[1] <= 0:
		_fail("the second blow was negated too; the limit is 1 a turn")
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([monk, foe])
	_done()


## {"from": "caster.skill.leadership", "pct": 50}: half the caster's
## EFFECTIVE Leadership (a hold on the skill counts).
func _check_borrowed_value() -> void:
	var leader := _make_unit(Vector2i(5, 5), 0)
	var ally := _make_unit(Vector2i(6, 5), 0)
	leader.character_data["skills"]["leadership"] = 6
	ValuePaths.add_hold(leader, "skill.leadership", "fortify", 2, "t6")
	var name := _with_test_status({"polarity": "positive", "while_active": [
		{"op": "modify", "value": "stat.accuracy", "mode": "fortify",
		 "amount": {"from": "caster.skill.leadership", "pct": 50}}]})
	var errs := EffectVocab.validate_status(CombatManager.get_status_definition(name), "borrowed")
	if not errs.is_empty():
		_fail("a borrowed amount was refused: %s" % [errs])
	var base: int = ally.get_accuracy()
	CombatManager._apply_status_effect(ally, name, 3, 0, leader)
	if ally.get_accuracy() != base + 4:
		_fail("half of Leadership 6+2 gave %+d accuracy, wanted +4" % (ally.get_accuracy() - base))
	ValuePaths.release(leader, "t6")
	_cleanup([leader, ally])
	_done()


## The removed keys are gone from every status, every status has a polarity,
## and the validator runs on all of them and refuses a legacy key.
const REMOVED_STATUS_KEYS: Array[String] = [
	"effects", "type", "category", "duration_type", "default_duration", "stackable",
	"bonus_amount", "penalty_amount", "damage_per_turn", "heal_per_turn", "retaliation",
	"reaction", "save_type", "summon_on_expire", "death_on_expire", "damage_on_expire",
	"bleed_on_expire", "damage_increase_per_turn",
]

func _check_no_legacy_status_keys() -> void:
	var defs: Dictionary = CombatManager.get_all_status_definitions()
	for name in defs:
		if str(name).begins_with("_"):
			continue
		var def: Dictionary = defs[name]
		for key in REMOVED_STATUS_KEYS:
			if def.has(key):
				_fail("%s still has the removed key '%s'" % [name, key])
		if not def.has("polarity"):
			_fail("%s has no polarity" % name)
		var errs := EffectVocab.validate_status(def, str(name))
		if not errs.is_empty():
			_fail("%s does not validate: %s" % [name, errs[0]])
	for key in ["retaliation", "reaction", "damage_per_turn", "effects", "save_type"]:
		var bad: Dictionary = {"name": "X", "polarity": "negative", key: {}}
		if EffectVocab.validate_status(bad, "legacy").is_empty():
			_fail("validate_status accepted the legacy key '%s'" % key)
	_done()


## The numbers the deleted code worked out, from the migrated data:
## Festering grows 5 a tick (5, 10), an enchant adds a fifth of the hit
## rounded up (12 -> 3), Pain Mirror reflects half (40 -> 20), Doomed's expiry
## kills, Regenerating heals 10, Stunned saves on Constitution at DC 15.
func _check_behaviour_numbers_match_today() -> void:
	var u := _make_unit(Vector2i(5, 5), 1)
	u.max_hp = 1000
	u.current_hp = 1000
	CombatManager._apply_status_effect(u, "Festering", 5)
	var ticks: Array[int] = []
	for _i in 2:
		var hp: int = u.current_hp
		CombatManager._process_status_effects(u)
		ticks.append(hp - u.current_hp)
	if ticks != [5, 10]:
		_fail("Festering ticked %s, wanted [5, 10]" % [ticks])
	for entry in u.status_effects.duplicate():
		CombatManager._end_status(u, entry, "removed")

	var smith := _make_unit(Vector2i(6, 5), 0)
	CombatManager._apply_status_effect(smith, "Burning_Weapon", 3)
	var hp2: int = u.current_hp
	CombatManager._process_status_weapon_enchants(smith, u, {"damage": 12})
	if hp2 - u.current_hp != 3:
		_fail("Burning_Weapon on a 12 hit added %d, wanted 3" % (hp2 - u.current_hp))

	var mirror := _make_unit(Vector2i(9, 9), 0)
	CombatManager._apply_status_effect(mirror, "Pain_Mirror", 3)
	var hp3: int = u.current_hp
	CombatManager._process_reactive_statuses(u, mirror, {"damage": 40})
	if hp3 - u.current_hp != 20:
		_fail("Pain_Mirror reflected %d of 40, wanted 20" % (hp3 - u.current_hp))

	var healer := _make_unit(Vector2i(12, 12), 0)
	healer.current_hp = 50
	CombatManager._apply_status_effect(healer, "Regenerating", 3)
	CombatManager._process_status_effects(healer)
	if healer.current_hp != 60:
		_fail("Regenerating healed %d, wanted 10" % (healer.current_hp - 50))

	var doomed := _make_unit(Vector2i(14, 14), 1)
	CombatManager._apply_status_effect(doomed, "Doomed", 1)
	CombatManager._process_status_effects(doomed)
	if doomed.current_hp > 0:
		_fail("Doomed ran out and %s lived (%d HP)" % [doomed.unit_name, doomed.current_hp])

	var save: Dictionary = CombatManager.get_status_definition("Stunned").get("save", {})
	if str(save.get("stat", "")) != "constitution" or int(save.get("dc", 0)) != 15 \
			or str(save.get("when", "")) != "turn_start":
		_fail("Stunned's save is %s" % [save])
	_cleanup([u, smith, mirror, healer, doomed])
	_done()


# ── Stage 2b Task 7: carry-overs from stage 1 ────────────────────────────────

## The `status` op says applied:false, with a reason, when the status was
## resisted or there was nothing to remove (it used to say true either way).
func _check_status_op_reports_resisted() -> void:
	var ward := _with_test_status({"polarity": "positive", "flags": ["immune:control"]})
	var hold := _with_test_status({"polarity": "negative", "categories": ["control"]})
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5))
	var apply: Array = [{"op": "status", "action": "apply", "status": hold, "duration": 2}]
	var landed: Array[Dictionary] = EffectResolver.resolve(apply, _ctx(caster, u))
	if landed.size() != 1 or not landed[0].applied or not u.has_status(hold):
		_fail("an unresisted status should log applied:true, got %s" % [landed])
	u.status_effects.clear()
	CombatManager._apply_status_effect(u, ward, 3)
	var blocked: Array[Dictionary] = EffectResolver.resolve(apply, _ctx(caster, u))
	if blocked.size() != 1 or blocked[0].applied or str(blocked[0].reason) != "resisted":
		_fail("a resisted status should log applied:false 'resisted', got %s" % [blocked])
	if u.has_status(hold):
		_fail("the status was supposed to be resisted")
	var removed: Array[Dictionary] = EffectResolver.resolve([{"op": "status", "action": "remove",
		"select": {"names": ["__no_such_status__"]}}], _ctx(caster, u))
	if removed.size() != 1 or removed[0].applied or str(removed[0].reason) == "":
		_fail("removing nothing should log applied:false with a reason, got %s" % [removed])
	_cleanup([caster, u])
	_done()


## A spell with several schools keeps all of them, and a heal clears damage
## whose `cleared_by` names ANY of them (it used to test only the first).
func _check_multi_school_cleared_by() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	_join_party(u)
	var spell := {"level": 3, "schools": ["White", "Water"]}
	var ctx := EffectContext.for_spell(caster, u, "test_heal", spell)
	if ctx.school != "white" or ",".join(ctx.schools) != "white,water":
		_fail("for_spell kept schools %s (first %s), wanted white and water" % [ctx.schools, ctx.school])
	u.character_data["damaged_values"] = [
		{"value": "skill.swords", "amount": 1, "source": "a",
			"cleared_by": [{"heal": {"school": "water", "min_level": 2}}]},
		{"value": "skill.maces", "amount": 1, "source": "b",
			"cleared_by": [{"heal": {"school": "fire", "min_level": 1}}]}]
	EffectResolver.resolve([{"op": "heal", "amount": 5}], ctx)
	var left: Array = u.character_data.get("damaged_values", [])
	if left.size() != 1 or str(left[0].source) != "b":
		_fail("a White+Water heal should clear the water entry only, left %s" % [left])
	_leave_party(u)
	_cleanup([caster, u])
	_done()


## Resistance.breakdown() lists the holds a status places, by the status's name.
func _check_breakdown_lists_holds() -> void:
	var warded := _with_test_status({"polarity": "positive", "while_active": [
		{"op": "modify", "value": "resist.fire", "mode": "fortify", "amount": 25}]})
	var u := _make_unit(Vector2i(5, 5))
	CombatManager._apply_status_effect(u, warded, 3)
	var found: bool = false
	for part in Resistance.breakdown(u, "fire"):
		if str(part.source) == warded and is_equal_approx(float(part.amount), 25.0):
			found = true
	if not found:
		_fail("breakdown does not list the hold by status name: %s" % [Resistance.breakdown(u, "fire")])
	_cleanup([u])
	_done()


# ── Stage 2b, Task 8: auras and zones as effects ────────────────────────────

const AuraMeasure = preload("res://tools/aura_measure.gd")
const AURA_BASELINE_PATH: String = "res://tools/fixtures/aura_baseline.json"


## Every aura and zone changes exactly what it did before the migration
## (tools/fixtures/aura_baseline.json): the stat getters, every resistance,
## max HP, damage taken and the mana-cost percentage, on the units it reaches
## and on the ones it does not. Real data, measured the same way (aura_measure.gd).
func _check_aura_numbers_match_baseline() -> void:
	var baseline: Dictionary = _read_fixture(AURA_BASELINE_PATH)
	var now: Dictionary = AuraMeasure.measure_all(self, grid)
	for section in ["auras", "zones"]:
		var was: Dictionary = baseline.get(section, {})
		var is_now: Dictionary = now.get(section, {})
		for row in is_now:
			if not was.has(row):
				_fail("%s %s is not in the aura baseline (added after it was captured?)" % [section, row])
		for row in was:
			if not is_now.has(row):
				_fail("%s %s was in the baseline and is gone" % [section, row])
				continue
			for place in was[row]:
				var a: Dictionary = was[row][place]
				var b: Dictionary = is_now[row].get(place, {})
				if not _same_changes(a, b):
					_fail("%s %s at %s: was %s, now %s" % [section, row, place,
						_changes_text(a), _changes_text(b)])
	_done()


## A zone written only in effects, by hand: it damages whoever starts a turn
## in it (turn_start_inside) and slows whoever steps in (on_enter), through
## EffectResolver with the zone's owner as caster.
func _check_zone_effects_resolve() -> void:
	CombatManager.active_zones.clear()
	var owner := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(9, 9), CombatManager.Team.ENEMY)
	var def: Dictionary = {"name": "Probe Brambles", "affects": "enemies",
		"turn_start_inside": [{"op": "damage", "amount": 7, "type": "piercing"}],
		"on_enter": [{"op": "status", "action": "apply", "status": "Slowed", "duration": 2}]}
	var errs: Array[String] = EffectVocab.validate_zone(def, "probe")
	if not errs.is_empty():
		_fail("a hand-written effect zone does not validate: %s" % [errs])
	CombatManager.active_zones.append({"id": "_probe_brambles", "name": "Probe Brambles",
		"def": def, "tiles": {Vector2i(10, 9): true}, "source": owner,
		"turns_left": 5, "entered": {}})

	# Not inside yet: its turn start does nothing.
	CombatManager._zones_turn_trigger(foe, "turn_start_inside")
	if foe.current_hp != 100:
		_fail("a zone hurt someone standing off it (hp %d)" % foe.current_hp)

	# Step in: on_enter slows, once.
	grid.unit_positions.erase(foe.grid_position)
	foe.grid_position = Vector2i(10, 9)
	grid.unit_positions[foe.grid_position] = foe
	CombatManager._zones_check_entry(foe)
	if not foe.has_status("Slowed"):
		_fail("on_enter did not apply Slowed to the unit stepping in")

	# Start a turn inside: turn_start_inside damages.
	var before: int = foe.current_hp
	CombatManager._zones_turn_trigger(foe, "turn_start_inside")
	if foe.current_hp >= before:
		_fail("turn_start_inside did no damage (hp %d -> %d)" % [before, foe.current_hp])
	# And the owner's ally is not who `affects: enemies` reaches.
	var friend := _make_unit(Vector2i(10, 9), CombatManager.Team.PLAYER)
	CombatManager._zones_turn_trigger(friend, "turn_start_inside")
	if friend.current_hp != 100:
		_fail("an enemies-only zone hurt the owner's ally")
	CombatManager.active_zones.clear()
	_cleanup([owner, foe, friend])
	_done()


## Grave Soil still raises a zombie for the caster from an enemy that dies on
## it — through `summon from: corpse` — and not from the caster's own side.
func _check_grave_soil_raises() -> void:
	CombatManager.active_zones.clear()
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(12, 8), CombatManager.Team.ENEMY)
	var friend := _make_unit(Vector2i(13, 8), CombatManager.Team.PLAYER)
	CombatManager.place_zone("grave_soil", [Vector2i(12, 8), Vector2i(13, 8)], caster, 9)

	var count: int = CombatManager.all_units.size()
	foe.is_dead = true
	CombatManager._zones_on_death(foe)
	if CombatManager.all_units.size() != count + 1:
		_fail("an enemy died on grave soil and %d rose" % (CombatManager.all_units.size() - count))
	else:
		var risen: Node = CombatManager.all_units[CombatManager.all_units.size() - 1]
		if risen.team != caster.team:
			_fail("the zombie fights for the wrong side")
		if risen.grid_position.distance_to(Vector2(12, 8)) > 2.0:
			_fail("the zombie rose at %s, not at the corpse" % [risen.grid_position])
		_cleanup([risen])

	count = CombatManager.all_units.size()
	friend.is_dead = true
	CombatManager._zones_on_death(friend)
	if CombatManager.all_units.size() != count:
		_fail("the caster's own ally rose from grave soil")
		_cleanup([CombatManager.all_units[CombatManager.all_units.size() - 1]])

	# A living unit is no corpse: the op refuses it.
	var ctx := EffectContext.new()
	ctx.caster = caster
	ctx.target = caster
	var log := EffectResolver.resolve([{"op": "summon", "as": "Zombie", "from": "corpse"}], ctx)
	if log[0].applied:
		_fail("summon from corpse raised something from a living unit")
	CombatManager.active_zones.clear()
	_cleanup([caster, foe, friend])
	_done()


## Resistance.breakdown() lists an aura's part under
## "aura:<emitter instance id>:<aura id>".
func _check_aura_breakdown_label() -> void:
	var medic := _make_unit(Vector2i(5, 5))
	var near := _make_unit(Vector2i(6, 5))
	medic.character_data["perks"] = ["immune_system"]
	var want: String = "aura:%d:immune_system" % medic.get_instance_id()
	var found: bool = false
	for part in Resistance.breakdown(near, "poison"):
		if str(part.source) == want and is_equal_approx(float(part.amount), 15.0):
			found = true
	if not found:
		_fail("breakdown does not list %s +15: %s" % [want, Resistance.breakdown(near, "poison")])
	_cleanup([medic, near])
	_done()


## Immune System's 15 is a 15% chance not to catch an affliction, read by
## Resistance.resists_affliction from the aura (and from holds).
func _check_aura_affliction_resistance() -> void:
	var medic := _make_unit(Vector2i(5, 5))
	var near := _make_unit(Vector2i(6, 5))
	var far := _make_unit(Vector2i(30, 20))
	medic.character_data["perks"] = ["immune_system"]
	seed(811)
	var near_hits: int = 0
	var far_hits: int = 0
	for i in 2000:
		if Resistance.resists_affliction(near, "bleed"):
			near_hits += 1
		if Resistance.resists_affliction(far, "bleed"):
			far_hits += 1
	randomize()
	if near_hits < 200 or near_hits > 400:
		_fail("Immune System resisted bleed %d times in 2000 (wanted about 300)" % near_hits)
	if far_hits != 0:
		_fail("a unit outside Immune System resisted bleed %d times" % far_hits)
	# A status hold on resist.bleed counts the same way.
	ValuePaths.add_hold(far, "resist.bleed", "set", 100, "t_bleed")
	var hits: int = 0
	for i in 200:
		if Resistance.resists_affliction(far, "bleed"):
			hits += 1
	if hits < 170:
		_fail("a resist.bleed set 100 hold resisted only %d of 200" % hits)
	_cleanup([medic, near, far])
	_done()


## validate_aura / validate_zone refuse what could not work.
func _check_aura_zone_validation() -> void:
	var ok_aura: Dictionary = {"name": "A", "radius": 1, "affects": "allies", "while_inside": [
		{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 3}]}
	if not EffectVocab.validate_aura(ok_aura, "a").is_empty():
		_fail("a plain aura is refused: %s" % [EffectVocab.validate_aura(ok_aura, "a")])
	var bad_auras: Dictionary = {
		"to on an aura effect": [{"op": "heal", "amount": 3, "to": "caster"}],
		"chance on a read-time modify": [{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 3, "chance": 50}],
		"set on a read-time modify": [{"op": "modify", "value": "stat.dodge", "mode": "set", "amount": 3}],
		"attribute read-time modify": [{"op": "modify", "value": "attribute.focus", "mode": "fortify", "amount": 3}],
		"borrow from a getter": [{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": {"from": "target.stat.dodge"}}],
		"move each turn": [{"op": "move", "mode": "push"}],
		"multiply max_hp": [{"op": "modify", "value": "stat.max_hp", "mode": "multiply", "amount": 2}],
	}
	for label in bad_auras:
		var d: Dictionary = ok_aura.duplicate(true)
		d["while_inside"] = bad_auras[label]
		if EffectVocab.validate_aura(d, "a").is_empty():
			_fail("validate_aura accepted %s" % label)
	var unknown: Dictionary = ok_aura.duplicate(true)
	unknown["payloads"] = []
	if EffectVocab.validate_aura(unknown, "a").is_empty():
		_fail("validate_aura accepted the old `payloads` key")
	var bad_zones: Dictionary = {
		"lasting modify on enter": {"on_enter": [{"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 3}]},
		"summon with to": {"on_death_inside": [{"op": "summon", "as": "Zombie", "from": "corpse", "to": "enemies_in_area"}]},
		"corpse outside death": {"on_enter": [{"op": "summon", "as": "Zombie", "from": "corpse"}]},
		"no effects": {},
		"old payload": {"on_enter": [{"kind": "damage", "amount": 3, "element": "fire"}]},
		"bad to": {"on_enter": [{"op": "damage", "amount": 3, "type": "fire", "to": "party"}]},
	}
	for label in bad_zones:
		var z: Dictionary = {"name": "Z", "affects": "all"}
		z.merge(bad_zones[label])
		if EffectVocab.validate_zone(z, "z").is_empty():
			_fail("validate_zone accepted %s" % label)
	# The fixed-DC save: valid with dc, refused with dc and tier both.
	if not EffectVocab.validate({"op": "status", "action": "apply", "status": "Confused",
			"save": {"stat": "focus", "dc": 14, "dc_drop_per_pass": 2}}, "s").is_empty():
		_fail("a fixed-dc save is refused")
	if EffectVocab.validate({"op": "status", "action": "apply", "status": "Confused",
			"save": {"stat": "focus", "dc": 14, "tier": "hard"}}, "s").is_empty():
		_fail("a save with both dc and tier is accepted")
	_done()


# ── Stage 2b, Task 9: group targets, affinity and pressure as values ─────────

## fortify skills.element.fire 2 lifts each of the seven fire skills by 2, and
## one release (one source id) lets them all go.
func _check_group_skill_hold() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var ch: Dictionary = u.character_data
	var fire: Array = PerkSystem.get_skills_in_element("fire")
	if fire.size() != 7:
		_fail("expected 7 fire skills, found %d" % fire.size())
	var before: Dictionary = {}
	for skill_id in fire:
		before[skill_id] = CharacterSystem.get_effective_skill_level(ch, skill_id)
	ValuePaths.add_hold(u, "skills.element.fire", "fortify", 2, "grp")
	for skill_id in fire:
		if CharacterSystem.get_effective_skill_level(ch, skill_id) != before[skill_id] + 2:
			_fail("skills.element.fire +2 missed %s" % skill_id)
	if CharacterSystem.get_effective_skill_level(ch, "swords") != 0:
		_fail("a fire group hold leaked onto swords")
	ValuePaths.release(u, "grp")
	for skill_id in fire:
		if CharacterSystem.get_effective_skill_level(ch, skill_id) != before[skill_id]:
			_fail("one release did not remove the hold on %s" % skill_id)
	if not u.effect_holds.is_empty():
		_fail("holds left after releasing a group: %s" % [u.effect_holds])
	# A category group reaches every skill of the category, and only those.
	ValuePaths.add_hold(u, "skills.combat", "fortify", 1, "grp2")
	if CharacterSystem.get_effective_skill_level(ch, "swords") != 1 \
			or CharacterSystem.get_effective_skill_level(ch, "fire_magic") != 0:
		_fail("skills.combat should lift swords and leave fire magic alone")
	ValuePaths.release(u, "grp2")
	_cleanup([u])
	_done()


## attributes.all moves all seven attributes together and releases together.
func _check_group_attributes_all() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var ch: Dictionary = u.character_data
	var before: Dictionary = {}
	for attr in EffectVocab.ATTRIBUTES:
		before[attr] = CharacterSystem.get_effective_attribute(ch, attr)
	ValuePaths.add_hold(u, "attributes.all", "fortify", 3, "all")
	for attr in EffectVocab.ATTRIBUTES:
		if CharacterSystem.get_effective_attribute(ch, attr) != before[attr] + 3:
			_fail("attributes.all +3 missed %s" % attr)
	ValuePaths.release(u, "all")
	for attr in EffectVocab.ATTRIBUTES:
		if CharacterSystem.get_effective_attribute(ch, attr) != before[attr]:
			_fail("release left %s changed" % attr)
	if ch.has("attribute_bonuses"):
		_fail("attribute_bonuses left behind after releasing attributes.all")
	_cleanup([u])
	_done()


## affinity.earth +3 raises the earth total by 3 and touches no skill; set and
## multiply work; the bought-level read (perk eligibility) ignores it.
func _check_affinity_hold() -> void:
	var u := _make_unit(Vector2i(5, 5))
	var ch: Dictionary = u.character_data
	var base: int = PerkSystem.calculate_element_affinity(ch, "earth")
	var skills_before: Dictionary = ch["skills"].duplicate(true)
	var other: int = PerkSystem.calculate_element_affinity(ch, "fire")
	ValuePaths.add_hold(u, "affinity.earth", "fortify", 3, "aff")
	if PerkSystem.calculate_element_affinity(ch, "earth") != base + 3:
		_fail("affinity.earth +3: got %d, wanted %d"
			% [PerkSystem.calculate_element_affinity(ch, "earth"), base + 3])
	if PerkSystem.calculate_element_affinity(ch, "fire") != other:
		_fail("an earth hold moved fire affinity")
	if str(ch["skills"]) != str(skills_before):
		_fail("affinity hold touched the skills")
	for skill_id in PerkSystem.get_skills_in_element("earth"):
		if ch.get("skill_bonuses", {}).get(skill_id, {}).has("effects"):
			_fail("affinity hold wrote a skill bonus on %s" % skill_id)
	if PerkSystem.calculate_element_affinity(ch, "earth", false) != base:
		_fail("perk eligibility (bought levels) must ignore a temporary affinity hold")
	ValuePaths.add_hold(u, "affinity.earth", "set", 12, "aff_set")
	if PerkSystem.calculate_element_affinity(ch, "earth") != 12:
		_fail("affinity.earth set 12 not applied")
	ValuePaths.release(u, "aff_set")
	ValuePaths.release(u, "aff")
	if PerkSystem.calculate_element_affinity(ch, "earth") != base:
		_fail("release did not restore earth affinity")
	_cleanup([u])
	_done()


## pressure.fire fortify 5 raises a party unit's fire pressure; drain relieves
## it; a character with no psychology state is refused without an error.
func _check_pressure_modify() -> void:
	var party := _make_unit(Vector2i(5, 5))
	var foe := _make_unit(Vector2i(6, 5), CombatManager.Team.ENEMY)
	foe.character_data["allegiance"] = "enemy"
	var ctx := _ctx(party, party)
	var mult: float = PsychologySystem._intensity_multiplier(party.character_data, "fire")
	var before: float = float(party.character_data["emotional_pressure"]["fire"])
	var up := {"op": "modify", "value": "pressure.fire", "mode": "fortify", "amount": 5}
	var entries := EffectResolver.resolve([up], ctx)
	if _applied(entries) != 1:
		_fail("pressure fortify on a party unit was refused: %s" % [entries])
	var after: float = float(party.character_data["emotional_pressure"]["fire"])
	if absf((after - before) - 5.0 * mult) > 0.001:
		_fail("fire pressure moved %s, wanted %s" % [after - before, 5.0 * mult])
	var down := {"op": "modify", "value": "pressure.fire", "mode": "drain", "amount": 5}
	EffectResolver.resolve([down], ctx)
	if absf(float(party.character_data["emotional_pressure"]["fire"]) - before) > 0.001:
		_fail("drain did not undo the fortify")
	# No hold is kept, so no hold_source is needed (ctx has none).
	if not party.effect_holds.is_empty():
		_fail("pressure is instant but left a hold")
	# An enemy sheet is refused with a reason.
	var foe_before: float = float(foe.character_data["emotional_pressure"]["fire"])
	var refused := EffectResolver.resolve([up], _ctx(party, foe))
	if _applied(refused) != 0 or str(refused[0].get("reason", "")).is_empty():
		_fail("pressure on an enemy must be refused with a reason: %s" % [refused])
	if float(foe.character_data["emotional_pressure"]["fire"]) != foe_before:
		_fail("a refused pressure effect still moved the enemy")
	# A sheet with no psychology state at all is refused too.
	foe.character_data.erase("emotional_pressure")
	foe.character_data.erase("allegiance")
	var bare := EffectResolver.resolve([up], _ctx(party, foe))
	if _applied(bare) != 0:
		_fail("pressure on a sheet with no psychology state must be refused")
	_cleanup([party, foe])
	_done()


# ── Stage 2b, Task 10: building states, comedown, upkeep ────────────────────

## A state that builds as its owner casts fire spells, costs mana to keep up,
## and leaves a drain behind when it runs out of that mana.
func _mantra_defs() -> Dictionary:
	var comedown := _with_test_status({"polarity": "negative",
		"while_active": [{"op": "modify", "value": "attribute.focus", "mode": "drain", "amount": 2}]})
	var state := _with_test_status({"polarity": "positive",
		"stacking": {"mode": "stack", "max": 5,
			"grow": {"on": "casts", "by": 1, "if": [{"spell_school": "fire"}]}},
		"upkeep": {"mana": 10, "per": "turn"},
		"while_active": [{"op": "modify", "value": "skill.fire_magic", "mode": "fortify", "amount": 1}],
		"triggers": [{"on": "expire", "effects": [
			{"op": "status", "action": "apply", "status": comedown, "duration": 2}]}]})
	return {"state": state, "comedown": comedown}


func _check_mantra_state_example() -> void:
	var defs := _mantra_defs()
	var state: String = defs.state
	var comedown: String = defs.comedown
	var caster := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(7, 5), CombatManager.Team.ENEMY)
	foe.max_hp = 5000
	foe.current_hp = 5000
	caster.character_data["skills"] = {"fire_magic": 3, "sorcery": 3}
	CharacterSystem.update_derived_stats(caster.character_data)
	caster.max_mana = 500
	caster.current_mana = 500
	caster.actions_remaining = 9
	CombatManager.turn_order = [caster]
	CombatManager.current_unit_index = 0
	var sp_plain: int = caster.get_spellpower()
	CombatManager._apply_status_effect(caster, state, 9)
	var entry := _entry_of(caster, state)
	if int(entry.get("stacks", 0)) != 1:
		_fail("a fresh state starts at 1 stack: %s" % [entry])
	# Three fire spells: +3 stacks. The base stack counts too, so 4 stacks and
	# +4 effective Fire magic in all.
	for i in 3:
		var cast: Dictionary = CombatManager.cast_spell(caster, "firebolt", foe.grid_position)
		if not bool(cast.get("success", false)):
			_fail("firebolt %d failed: %s" % [i, cast.get("reason", "?")])
	if int(entry.get("stacks", 0)) != 4:
		_fail("three fire casts should make 4 stacks, got %s" % entry.get("stacks"))
	# An air spell must not grow it (the condition names the school).
	CombatManager._fire_status_event(caster, "casts", {"schools": ["air", "sorcery"]})
	if int(entry.get("stacks", 0)) != 4:
		_fail("an air spell grew a state that wants fire")
	# The spellpower is what the per-level formula says for +4 Fire magic.
	var sp_state: int = caster.get_spellpower()
	var held_skill: int = CharacterSystem.get_effective_skill_level(caster.character_data, "fire_magic")
	if held_skill != 3 + 4:
		_fail("effective Fire magic with 4 stacks: %d, wanted 7" % held_skill)
	CombatManager._end_status(caster, entry, "removed")
	if caster.get_spellpower() != sp_plain:
		_fail("releasing the state should restore spellpower")
	caster.character_data["skills"]["fire_magic"] = 7
	CharacterSystem.update_derived_stats(caster.character_data)
	if caster.get_spellpower() != sp_state:
		_fail("spellpower via holds %d differs from the formula at Fire magic 7: %d"
			% [sp_state, caster.get_spellpower()])
	if sp_state <= sp_plain:
		_fail("+4 Fire magic did not raise spellpower (%d -> %d)" % [sp_plain, sp_state])
	caster.character_data["skills"]["fire_magic"] = 3
	CharacterSystem.update_derived_stats(caster.character_data)

	# Upkeep is paid at turn start, and the state stays while it can be.
	CombatManager._apply_status_effect(caster, state, 9)
	caster.current_mana = 100
	CombatManager._process_status_effects(caster)
	if caster.current_mana != 90 or not caster.has_status(state):
		_fail("upkeep paid: mana %d (wanted 90), state on: %s" % [caster.current_mana, caster.has_status(state)])
	# Short of mana, the state ends and its comedown follows.
	caster.current_mana = 5
	var focus: int = CharacterSystem.get_effective_attribute(caster.character_data, "focus")
	CombatManager._process_status_effects(caster)
	if caster.has_status(state):
		_fail("a state that cannot pay its upkeep should end")
	if not caster.has_status(comedown):
		_fail("the comedown was not applied when upkeep failed")
	elif CharacterSystem.get_effective_attribute(caster.character_data, "focus") != focus - 2:
		_fail("the comedown should drain 2 Focus")
	if caster.current_mana != 5:
		_fail("an unpaid upkeep must take nothing, mana is %d" % caster.current_mana)
	# Dispelling the state is not running out: no comedown.
	CombatManager._end_status(caster, _entry_of(caster, comedown), "removed")
	CombatManager._apply_status_effect(caster, state, 9)
	CombatManager._end_status(caster, _entry_of(caster, state), "dispelled")
	if caster.has_status(comedown):
		_fail("dispelling the state applied its comedown")
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0
	_cleanup([caster, foe])
	_done()


## HP upkeep never takes a unit below 1: the status ends instead.
func _check_hp_upkeep_never_kills() -> void:
	var name := _with_test_status({"polarity": "positive", "upkeep": {"hp": 10, "per": "turn"}})
	var u := _make_unit(Vector2i(5, 5))
	CombatManager._apply_status_effect(u, name, 9)
	u.current_hp = 50
	CombatManager._process_status_effects(u)
	if u.current_hp != 40 or not u.has_status(name):
		_fail("hp upkeep paid: hp %d state on %s" % [u.current_hp, u.has_status(name)])
	u.current_hp = 10
	CombatManager._process_status_effects(u)
	if u.current_hp != 10 or u.has_status(name) or u.is_dead:
		_fail("hp upkeep at 10 hp must end the status, not kill: hp %d" % u.current_hp)
	_cleanup([u])
	_done()


func _check_building_state_validation() -> void:
	var base := {"name": "S", "icon": "x", "polarity": "positive", "categories": ["blessing"],
		"scope": "combat", "duration": {"kind": "turns", "base": 3},
		"stacking": {"mode": "stack", "max": 5, "grow": {"on": "casts", "by": 1,
			"if": [{"spell_school": "fire"}]}},
		"upkeep": {"mana": 10, "per": "turn"}}
	var errs := EffectVocab.validate_status(base, "t")
	if not errs.is_empty():
		_fail("a building state with upkeep should validate: %s" % [errs])
	var bad := {
		"grow on a refresh status": {"stacking": {"mode": "refresh", "grow": {"on": "casts", "by": 1}}},
		"grow on unknown trigger": {"stacking": {"mode": "stack", "grow": {"on": "tuesday", "by": 1}}},
		"grow by zero": {"stacking": {"mode": "stack", "grow": {"on": "casts", "by": 0}}},
		"unknown school": {"stacking": {"mode": "stack", "grow": {"on": "casts", "by": 1,
			"if": [{"spell_school": "plasma"}]}}},
		"upkeep without a cost": {"upkeep": {"per": "turn"}},
		"upkeep of luck": {"upkeep": {"luck": 1, "per": "turn"}},
		"upkeep per fortnight": {"upkeep": {"mana": 1, "per": "fortnight"}},
	}
	for label in bad:
		var d: Dictionary = base.duplicate(true)
		d.merge(bad[label], true)
		if label.begins_with("upkeep"):
			d["stacking"] = {"mode": "refresh"}
		if EffectVocab.validate_status(d, "t").is_empty():
			_fail("validate_status accepted: %s" % label)
	_done()



# ── Stage 2b final review: the fix wave ──────────────────────────────────────

## What the validator now refuses: a while_active effect the container could
## not release from the carrier (a `to` elsewhere, a resource or pressure, a
## non-modify op), two holds of one status on one value, a fortify on a
## multiplier stat, a zone's max HP, and an affinity that reads itself.
func _check_final_review_validation() -> void:
	var dodge := {"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 2}
	var ok := _minimal_status()
	ok["while_active"] = [dodge, {"op": "modify", "value": "stat.damage", "mode": "fortify",
		"amount": 1, "to": "target"}]
	if not EffectVocab.validate_status(ok, "t").is_empty():
		_fail("a plain while_active was refused: %s" % [EffectVocab.validate_status(ok, "t")])
	var party_dodge: Dictionary = dodge.duplicate()
	party_dodge["to"] = "party"
	var bad := {
		"to party": [party_dodge],
		"resource drain": [{"op": "modify", "value": "resource.mana", "mode": "drain", "amount": 5}],
		"pressure fortify": [{"op": "modify", "value": "pressure.fire", "mode": "fortify", "amount": 5}],
		"non-modify op": [{"op": "damage", "amount": 5, "type": "fire"}],
		"fortify and multiply on stat.damage": [
			{"op": "modify", "value": "stat.damage", "mode": "fortify", "amount": 5},
			{"op": "modify", "value": "stat.damage", "mode": "multiply", "amount": 1.2}],
		"attributes.all and attribute.strength": [
			{"op": "modify", "value": "attributes.all", "mode": "fortify", "amount": 2},
			{"op": "modify", "value": "attribute.strength", "mode": "fortify", "amount": 3}],
		"skills.magic and skills.element.fire": [
			{"op": "modify", "value": "skills.magic", "mode": "fortify", "amount": 1},
			{"op": "modify", "value": "skills.element.fire", "mode": "fortify", "amount": 1}],
	}
	for label in bad:
		var d := _minimal_status()
		d["while_active"] = bad[label]
		if EffectVocab.validate_status(d, "t").is_empty():
			_fail("validate_status accepted while_active %s" % label)
	for mode in ["fortify", "drain", "set"]:
		if EffectVocab.validate({"op": "modify", "value": "stat.magic_damage_taken", "mode": mode,
				"amount": 0.2}, "t").is_empty():
			_fail("a %s on stat.magic_damage_taken was accepted" % mode)
	if not EffectVocab.validate({"op": "modify", "value": "stat.physical_damage_taken",
			"mode": "multiply", "amount": 1.2}, "t").is_empty():
		_fail("a multiply on stat.physical_damage_taken was refused")
	if EffectVocab.validate_zone({"name": "Z", "affects": "allies", "while_inside": [
			{"op": "modify", "value": "stat.max_hp", "mode": "fortify", "amount": 10}]}, "z").is_empty():
		_fail("validate_zone accepted a stat.max_hp")
	if EffectVocab.validate({"op": "modify", "value": "affinity.fire", "mode": "fortify",
			"amount": {"from": "caster.affinity.fire"}}, "t").is_empty():
		_fail("an affinity.fire that borrows affinity.fire was accepted")
	_done()


## A scatter's `tiles` is how far it may land (Heavenly Counterflow writes
## tiles 2). With every tile at distance 1 taken, a 1-tile scatter has nowhere
## to go; before the fix it ignored tiles and used the 2-tile default.
func _check_scatter_reads_tiles_as_range() -> void:
	var u := _make_unit(Vector2i(5, 5), CombatManager.Team.PLAYER)
	var walls: Array = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				walls.append(_make_unit(Vector2i(5 + dx, 5 + dy), CombatManager.Team.ENEMY))
	var log := EffectResolver.resolve([{"op": "move", "mode": "scatter", "tiles": 1}], _ctx(u, u))
	if u.grid_position != Vector2i(5, 5) or _applied(log) != 0:
		_fail("a 1-tile scatter, hemmed in, moved to %s (%s)" % [u.grid_position, log])
	_cleanup(walls + [u])
	_done()


## Stage 1 sent every spell's damage to apply_damage, even 0. Only a status's,
## aura's or zone's damage (a reflection of a blow that did nothing) is dropped
## below 1.
func _check_zero_damage_reaches_spells_only() -> void:
	var caster := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(5, 5), CombatManager.Team.ENEMY)
	var spell_log := EffectResolver.resolve([{"op": "damage", "amount": 0, "type": "fire"}],
		_ctx(caster, foe))
	if _applied(spell_log) != 1:
		_fail("a spell's 0 damage should reach apply_damage as in stage 1: %s" % [spell_log])
	var ctx := _ctx(caster, foe)
	ctx.container_kind = "status"
	var status_log := EffectResolver.resolve([{"op": "damage", "amount": 0, "type": "fire"}], ctx)
	if _applied(status_log) != 0:
		_fail("a status's 0 damage should do nothing: %s" % [status_log])
	if foe.current_hp != 100:
		_fail("0 damage changed HP to %d" % foe.current_hp)
	_cleanup([caster, foe])
	_done()


## `to: "source"` names nobody once the source is dead: None Shall Pass does
## not slow a corpse, Fireshield does not burn one.
func _check_dead_source_gets_nothing() -> void:
	var carrier := _make_unit(Vector2i(2, 2), CombatManager.Team.PLAYER)
	var foe := _make_unit(Vector2i(3, 2), CombatManager.Team.ENEMY)
	foe.is_dead = true
	var ctx := _ctx(carrier, carrier)
	ctx.source = foe
	EffectResolver.resolve([{"op": "status", "action": "apply", "status": "Slowed",
		"duration": 2, "to": "source"}], ctx)
	if foe.has_status("Slowed"):
		_fail("a dead source was slowed")
	foe.is_dead = false
	EffectResolver.resolve([{"op": "status", "action": "apply", "status": "Slowed",
		"duration": 2, "to": "source"}], ctx)
	if not foe.has_status("Slowed"):
		_fail("a living source was not slowed")
	_cleanup([carrier, foe])
	_done()


## A state that ends because its upkeep cannot be paid ends as if it ran out:
## the Invisible rule (stealth goes with it) runs, and its comedown lasts as
## long as the comedown of a state whose duration ran out.
func _check_upkeep_end_is_an_expiry() -> void:
	var comedown := _with_test_status({"polarity": "negative"})
	var trig := [{"on": "expire", "effects": [
		{"op": "status", "action": "apply", "status": comedown, "duration": 2}]}]
	var paid := _with_test_status({"polarity": "positive", "flags": ["grants_stealth"],
		"upkeep": {"mana": 10, "per": "turn"}, "triggers": trig})
	var timed := _with_test_status({"polarity": "positive", "triggers": trig})
	var a := _make_unit(Vector2i(5, 5))
	var b := _make_unit(Vector2i(7, 5))
	# a: the state cannot be paid for.
	a.max_mana = 100
	a.current_mana = 5
	CombatManager._apply_status_effect(a, paid, 9)
	a.is_stealthed = true
	CombatManager._process_status_effects(a)
	if a.has_status(paid):
		_fail("an unpaid upkeep should end the state")
	if a.is_stealthed:
		_fail("a grants_stealth state ended by upkeep left its carrier stealthed")
	# b: the state runs out.
	CombatManager._apply_status_effect(b, timed, 1)
	CombatManager._process_status_effects(b)
	if b.has_status(timed):
		_fail("a 1-turn state should have run out")
	var by_upkeep: int = int(_entry_of(a, comedown).get("duration", -1))
	var by_expiry: int = int(_entry_of(b, comedown).get("duration", -1))
	if by_upkeep != 2 or by_expiry != 2:
		_fail("comedown duration: %d after upkeep, %d after expiry; wanted 2 both"
			% [by_upkeep, by_expiry])
	_cleanup([a, b])
	_done()
