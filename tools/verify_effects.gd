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
const EXPECTED_CHECKS: int = 66

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
	CombatManager._status_effects["VerifyCurse"] = {"type": "debuff", "dispellable": true,
		"categories": ["curse"]}
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
