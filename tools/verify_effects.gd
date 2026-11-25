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
const EXPECTED_CHECKS: int = 19

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

	# Holds are combat-scoped: end_combat must wipe them.
	_check_holds_do_not_survive_end_combat()

	# Persistent `damage` mode and what clears it.
	_check_add_hold_refuses_damage_and_restore()
	_check_damage_mode_persists_past_combat()
	_check_damage_mode_counts_once_after_combat()
	_check_full_rest_clears_but_camp_does_not()
	_check_heal_clear_respects_school_and_level()
	_check_restore_clears_all_or_by_amount()
	_check_damage_mode_on_enemy_is_fight_only()
	_check_damaged_values_survive_save_round_trip()

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


## Saves go through SaveManager slot 3, which may be Olaf's real save. The slot
## file and meta.json are held in memory first and put back byte for byte (or
## deleted if they did not exist), so this check never costs him a save.
func _check_damaged_values_survive_save_round_trip() -> void:
	var slot_path: String = SaveManager.SAVE_DIR + "slot_3.json"
	var meta_path: String = SaveManager.SAVE_DIR + "meta.json"
	var kept: Dictionary = {}
	for path in [slot_path, meta_path]:
		kept[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
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

	# Put everything back: the process state, then the files.
	GameState.load_save_data(snap_game)
	CharacterSystem.load_save_data(snap_chars)
	ItemSystem.load_save_data(snap_items)
	KarmaSystem.load_save_data(snap_karma)
	MapManager.load_save_data(snap_map)
	SaveManager.current_slot = old_slot
	for path in kept:
		if kept[path] == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		else:
			var f := FileAccess.open(path, FileAccess.WRITE)
			f.store_buffer(kept[path])
			f.close()
	_cleanup([u])
	_done()
