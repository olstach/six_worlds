extends Node
## Headless verification for the passive perk effects engine.
##
## Run: godot --headless res://tools/verify_passive_perks.tscn
##
## Every check here grants a real perk to a real character and asserts a number
## moved. That is the whole point: the failure mode this engine exists to end is
## an effect that is stored, summed, and never read — which looks identical to a
## working effect from anywhere except the number on the other end.
##
## Exits non-zero if any assertion fails.

var failures: int = 0


func _ready() -> void:
	_check_unconditional_stat_bonus()
	_check_resistances()
	_check_stat_conversion()
	_check_conditional_bonus()
	_check_trigger()
	_check_no_double_wiring()
	_check_effect_stats_are_derived()

	# The conditions and triggers added 2026-10-15. No shipped perk uses them
	# yet, so each is driven by a synthetic perk — the path has to be proven
	# before data starts relying on it, same as stat_conversion above.
	_setup_field()
	_check_vocabulary_is_closed()
	_check_armour_conditions()
	_check_first_attack_conditions()
	_check_target_conditions()
	_check_terrain_condition()
	_check_conditional_crit_reaches_the_getter()
	_check_trigger_conditions()
	_check_combat_start_and_turn_start()
	_check_take_damage_and_ally_damaged()
	_check_parry_success()
	_check_reentrancy_guard()
	_check_stat_modifiers_tick_once()
	_check_rousing_display_sorts_round_one()
	_check_downed_and_actionless_units_tick()
	_check_avatar_of_the_wind_reaches_every_ally()
	_check_borrowed_opening_waits_for_the_attack()
	_check_every_opening_wants_a_debuff()
	_teardown_field()

	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK")
		get_tree().quit(0)


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


## A character with nothing on it but the baseline, so any change is the perk's.
func _blank() -> Dictionary:
	var character: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(character)
	return character


func _grant(character: Dictionary, perk_id: String) -> void:
	PerkSystem.grant_perk(character, perk_id)
	CharacterSystem.update_derived_stats(character)


## calm_mind: "+15% to all mental saving throws".
func _check_unconditional_stat_bonus() -> void:
	var character := _blank()
	var before: float = character.derived.get("mental_resistance_pct", 0.0)
	_grant(character, "calm_mind")
	var after: float = character.derived.get("mental_resistance_pct", 0.0)
	if after - before != 15.0:
		_fail("calm_mind: mental_resistance_pct moved %.1f, expected 15" % (after - before))

	# And the stat has to reach the roll, not just the sheet.
	# This used to sample CombatManager._perform_save_roll(), which SaveSystem
	# replaced on 2026-09-12. The call then died with a SCRIPT ERROR that
	# aborted this function only — the verifier still printed VERIFY OK, so the
	# half of the check that mattered had not run for a month. SaveSystem
	# exposes the exact odds, so assert those instead of sampling.
	var unit := CombatUnit.new()
	unit.character_data = _blank()
	var plain: float = SaveSystem.success_chance(unit, "focus", 15)
	unit.character_data = character
	var boosted: float = SaveSystem.success_chance(unit, "focus", 15)
	unit.free()
	if boosted <= plain:
		_fail("calm_mind: Focus save odds %.2f with the perk, %.2f without — the bonus is "
			% [boosted, plain] + "not reaching the roll")


## aegis_of_tranquility and stone_body write into derived.resistances.
func _check_resistances() -> void:
	var character := _blank()
	_grant(character, "aegis_of_tranquility")
	var resists: Dictionary = character.derived.get("resistances", {})
	# The four elemental damage types: `water`, `air` and `earth` were damage
	# types once and are magic SCHOOLS now, their damage arriving as ice,
	# lightning or impact.
	for element in ["fire", "ice", "lightning", "space"]:
		if resists.get(element, 0) != 20:
			_fail("aegis_of_tranquility: %s resistance is %s, expected 20"
				% [element, resists.get(element, 0)])

	var other := _blank()
	_grant(other, "stone_body")
	var other_resists: Dictionary = other.derived.get("resistances", {})
	if other_resists.get("bleed", 0) != 25:
		_fail("stone_body: bleed resistance is %s, expected 25" % other_resists.get("bleed", 0))


## No perk is wired for conversion yet — Parry and Improved Parry, the obvious
## candidates, are both hardcoded. Check the engine arithmetic directly so the
## path is proven before data starts using it.
func _check_stat_conversion() -> void:
	var derived := {"accuracy": 80, "armor": 10}
	var converted: Dictionary = PerkSystem.get_passive_stat_conversions({}, derived)
	if not converted.is_empty():
		_fail("a character with no perks produced conversions: %s" % converted)

	# Feed the resolver a synthetic effect the way a perk would.
	var synthetic := {"perks": [{"id": "__test__", "name": "test"}]}
	PerkSystem._skill_perks["__test__"] = {
		"name": "test",
		"effects": [{"type": "stat_conversion", "source_stat": "accuracy",
			"target_stat": "armor", "pct": 20}],
	}
	converted = PerkSystem.get_passive_stat_conversions(synthetic, derived)
	PerkSystem._skill_perks.erase("__test__")
	if converted.get("armor", 0) != 16:
		_fail("stat_conversion: 20%% of 80 accuracy gave %s armor, expected 16"
			% converted.get("armor", 0))


## patient_aim only pays out when the conditions hold.
func _check_conditional_bonus() -> void:
	var character := _blank()
	_grant(character, "patient_aim")

	# The bonus is conditional, so it must NOT be baked into the sheet.
	var flat: Dictionary = PerkSystem.get_passive_stat_bonuses(character)
	if flat.has("accuracy"):
		_fail("patient_aim: a conditional bonus leaked into the unconditional totals")

	var unit := CombatUnit.new()
	unit.character_data = character
	unit.moved_this_turn = false
	# No ranged weapon equipped, so wielding_ranged fails and the bonus is off.
	if unit._get_conditional_perk_bonus("accuracy") != 0:
		_fail("patient_aim: paid out with no ranged weapon equipped")
	unit.free()


## borrowed_opening fires on a successful dodge.
func _check_trigger() -> void:
	var character := _blank()
	_grant(character, "borrowed_opening")
	var unit := CombatUnit.new()
	unit.character_data = character
	unit.unit_name = "Probe"
	unit.stat_modifiers = []

	CombatManager._fire_perk_triggers(unit, "dodge_success", {})
	var gained := unit._get_stat_modifier_bonus("crit_chance")

	# A trigger that does not match must do nothing.
	unit.stat_modifiers = []
	CombatManager._fire_perk_triggers(unit, "on_kill", {})
	var spurious := unit._get_stat_modifier_bonus("crit_chance")
	unit.free()

	if gained != 20:
		_fail("borrowed_opening: dodge_success gave %d crit, expected 20" % gained)
	if spurious != 0:
		_fail("borrowed_opening: fired on on_kill, which it does not listen for")


## The rule the whole engine rests on: a perk implemented by hand in scripts/
## must not also carry an effects array, or it resolves twice.
func _check_no_double_wiring() -> void:
	var blob := ""
	for path in _all_script_paths("res://scripts"):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			blob += f.get_as_text()
			f.close()

	for perk_id in PerkSystem.get_all_perk_ids():
		var data: Dictionary = PerkSystem.get_perk_data(perk_id)
		if data.get("effects", []).is_empty():
			continue
		if blob.contains('"%s"' % perk_id):
			_fail(("%s carries an effects array AND is referenced by id in "
				+ "scripts/ — it would fire twice") % perk_id)


## Every stat any effects array names must be one the engine can deliver.
func _check_effect_stats_are_derived() -> void:
	var wired := 0
	for perk_id in PerkSystem.get_all_perk_ids():
		var data: Dictionary = PerkSystem.get_perk_data(perk_id)
		var effects: Array = data.get("effects", [])
		if effects.is_empty():
			continue
		wired += 1
		for effect in effects:
			match effect.get("type", ""):
				"stat_bonus":
					if not CombatStats.is_derived(effect.get("stat", "")):
						_fail("%s: stat_bonus on '%s', not a derived stat"
							% [perk_id, effect.get("stat", "")])
				"stat_conversion":
					for key in ["source_stat", "target_stat"]:
						if not CombatStats.is_derived(effect.get(key, "")):
							_fail("%s: %s '%s' is not a derived stat"
								% [perk_id, key, effect.get(key, "")])
				"on_trigger":
					var payload: Dictionary = effect.get("effect", {})
					if payload.get("type", "") == "buff" \
							and not CombatStats.is_modifiable(payload.get("stat", "")):
						_fail("%s: trigger buffs '%s', which is never read back"
							% [perk_id, payload.get("stat", "")])
	print("Passive perks carrying an effects array: %d" % wired)


func _all_script_paths(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path + "/" + name
		if dir.current_is_dir():
			out.append_array(_all_script_paths(full))
		elif name.ends_with(".gd"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return out


# ── The 2026-10-15 conditions and triggers ──────────────────────────────────

var grid: CombatGrid
var _probe_ids: Array[String] = []
var _units: Array[CombatUnit] = []


## A real, empty field and nobody on it. Conditions like from_behind and
## on_terrain_* ask the grid, and the triggers walk CombatManager.all_units.
func _setup_field() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(12, 12), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid


func _teardown_field() -> void:
	for unit in _units:
		CombatManager.all_units.erase(unit)
		unit.queue_free()
	_units.clear()
	for perk_id in _probe_ids:
		PerkSystem._skill_perks.erase(perk_id)
	CombatManager.combat_grid = null
	CombatManager.turn_order.clear()


## Register a perk that exists only for this run, carrying `effects`.
func _probe_perk(perk_id: String, effects: Array) -> String:
	PerkSystem._skill_perks[perk_id] = {"name": perk_id, "effects": effects}
	_probe_ids.append(perk_id)
	return perk_id


func _make_unit(at: Vector2i, team: int, perk_ids: Array = []) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d_%d" % [team, _units.size()]
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	for perk_id in perk_ids:
		unit.character_data["perks"].append({"id": perk_id})
	CharacterSystem.update_derived_stats(unit.character_data)
	# A melee weapon by default; individual checks swap it out.
	unit.character_data["equipped_weapon"] = {"type": "sword", "name": "Probe sword"}
	add_child(unit)
	unit.max_hp = 1000
	unit.current_hp = 1000
	unit.grid_position = at
	unit.stat_modifiers = []
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	_units.append(unit)
	return unit


## Sum of timed modifiers on `stat` — the trigger payload "buff" lands here.
func _mod(unit: CombatUnit, stat: String) -> int:
	return unit._get_stat_modifier_bonus(stat)


## Every listed condition must have a case in _perk_condition_met, and every
## listed trigger a call site. Read from source, because a missing case only
## shows up as a push_error at the moment a perk asks — which is exactly the
## silent kind of failure this engine exists to prevent.
func _check_vocabulary_is_closed() -> void:
	var unit_src := FileAccess.get_file_as_string("res://scripts/combat/combat_unit.gd")
	var start := unit_src.find("func _perk_condition_met(")
	var stop := unit_src.find("\nfunc ", start + 1)
	var body := unit_src.substr(start, stop - start)
	for condition in CombatStats.PERK_CONDITIONS:
		if not body.contains('"%s"' % condition):
			_fail("condition '%s' is in CombatStats.PERK_CONDITIONS but " % condition
				+ "_perk_condition_met has no case for it")

	var cm_src := FileAccess.get_file_as_string("res://scripts/autoload/combat_manager.gd")
	var call_re := RegEx.new()
	call_re.compile('_fire_perk_triggers\\([^,]+,\\s*"([a-z_]+)"')
	var fired: Array[String] = []
	for m in call_re.search_all(cm_src):
		fired.append(m.get_string(1))
	for trigger in CombatStats.PERK_TRIGGERS:
		if not trigger in fired:
			_fail("trigger '%s' is in CombatStats.PERK_TRIGGERS but nothing fires it" % trigger)
	for trigger in fired:
		if not trigger in CombatStats.PERK_TRIGGERS:
			_fail("combat_manager fires '%s', which is not in CombatStats.PERK_TRIGGERS" % trigger)

	if not CombatStats.is_perk_condition("on_terrain_forest"):
		_fail("on_terrain_forest is not accepted as a condition")
	if CombatStats.is_perk_condition("on_terrain_forrest"):
		_fail("on_terrain_forrest (no such ground) was accepted as a condition")


## wearing_heavy_armor, unarmored_or_light and the strict "unarmored", against
## real items in every armour slot — not just the chest. The old test read a
## `hands` slot that does not exist, so gauntlets never counted and trousers did.
func _check_armour_conditions() -> void:
	var unit := _make_unit(Vector2i(1, 1), 0)
	var equipment: Dictionary = unit.character_data["equipment"]
	# {slot: item} -> [wearing_heavy_armor, unarmored_or_light, strictly unarmored]
	var cases: Array = [
		[{"chest": "chainmail"}, [true, false, false]],     # Strength requirement: heavy
		[{"chest": "leather_vest"}, [false, true, false]],  # armour, but light
		[{"chest": "cloth_robe"}, [false, true, true]],     # clothing
		[{}, [false, true, true]],                          # nothing on at all
		# Clothing in the other slots is still unarmored.
		[{"chest": "cloth_robe", "legs": "leather_pants", "feet": "leather_boots",
			"hand_l": "leather_gloves"}, [false, true, true]],
		# Gauntlets are armour (heavy, they need Strength) — in either hand.
		[{"hand_l": "iron_gauntlets"}, [false, false, false]],
		[{"hand_r": "iron_gauntlets"}, [false, false, false]],
		# A leather cap is light armour: fine for Flowing Footwork, not for
		# Diamond Body.
		[{"head": "leather_cap"}, [false, true, false]],
		[{"legs": "iron_greaves"}, [false, false, false]],
	]
	var armour_slots: Array[String] = ["head", "chest", "legs", "feet", "hand_l", "hand_r"]
	for case in cases:
		for slot in armour_slots:
			equipment[slot] = ""
		var worn: Dictionary = case[0]
		for slot in worn:
			equipment[slot] = worn[slot]
		var want: Array = case[1]
		var got: Array = [
			unit._perk_condition_met("wearing_heavy_armor"),
			unit._perk_condition_met("unarmored_or_light"),
			CombatManager._unit_is_unarmored(unit),
		]
		if got != want:
			_fail("wearing %s: [heavy, unarmored_or_light, unarmored] = %s, expected %s"
				% [worn, got, want])
	for slot in armour_slots:
		equipment[slot] = ""

	# And the perks that read it. Flowing Footwork takes light armour, Diamond
	# Body does not; the movement getter is the consumer for the first.
	var footwork := _make_unit(Vector2i(1, 2), 0, ["flowing_footwork"])
	var bare_move: int = footwork.get_movement()
	footwork.character_data["equipment"]["chest"] = "leather_vest"
	if footwork.get_movement() != bare_move:
		_fail("Flowing Footwork's +1 Movement was lost to a leather vest (light armour)")
	footwork.character_data["equipment"]["hand_r"] = "iron_gauntlets"
	if footwork.get_movement() != bare_move - 1:
		_fail("Flowing Footwork's +1 Movement survived iron gauntlets (heavy armour)")


## first_attack_combat / first_attack_turn, counted by a real attack_unit().
func _check_first_attack_conditions() -> void:
	var attacker := _make_unit(Vector2i(3, 3), 0)
	var target := _make_unit(Vector2i(4, 3), 1)
	if not attacker._perk_condition_met("first_attack_combat") \
			or not attacker._perk_condition_met("first_attack_turn"):
		_fail("a unit that has not attacked does not count as on its first attack")

	CombatManager.turn_order = [attacker]
	CombatManager.current_unit_index = 0
	attacker.actions_remaining = 5
	var result: Dictionary = CombatManager.attack_unit(attacker, target)
	if not result.get("success", false):
		_fail("first_attack: the probe attack was refused (%s), nothing was counted"
			% result.get("reason", "?"))
		return
	if attacker._perk_condition_met("first_attack_combat"):
		_fail("first_attack_combat still true after an attack")
	if attacker._perk_condition_met("first_attack_turn"):
		_fail("first_attack_turn still true after an attack this turn")

	# A new turn resets the turn counter and not the combat one.
	CombatManager._process_turn_start_perks(attacker)
	if not attacker._perk_condition_met("first_attack_turn"):
		_fail("first_attack_turn did not reset at turn start")
	if attacker._perk_condition_met("first_attack_combat"):
		_fail("first_attack_combat reset at turn start — it should last the fight")


## from_behind, target_bleeding, target_debuffed — and false with no target.
func _check_target_conditions() -> void:
	var target := _make_unit(Vector2i(6, 6), 1)
	target.facing = Vector2i(1, 0)                  # looking east
	var behind := _make_unit(Vector2i(5, 6), 0)     # west of it: its back
	var in_front := _make_unit(Vector2i(7, 6), 0)

	for condition in ["from_behind", "target_bleeding", "target_debuffed"]:
		if behind._perk_condition_met(condition):
			_fail("%s was true with no target at all" % condition)

	if not behind._perk_condition_met("from_behind", target):
		_fail("from_behind: an attacker at the target's back is not behind it")
	if in_front._perk_condition_met("from_behind", target):
		_fail("from_behind: an attacker the target is facing counted as behind")

	if behind._perk_condition_met("target_bleeding", target):
		_fail("target_bleeding true on a target with no statuses")
	target.status_effects = [{"status": "Bleeding", "duration": 3}]
	if not behind._perk_condition_met("target_bleeding", target):
		_fail("target_bleeding false on a Bleeding target")

	target.status_effects = [{"status": "Blessed", "duration": 3}]
	if behind._perk_condition_met("target_debuffed", target):
		_fail("target_debuffed true on a target carrying only a buff")
	target.status_effects = [{"status": "Weakened", "duration": 3}]
	if not behind._perk_condition_met("target_debuffed", target):
		_fail("target_debuffed false on a Weakened target")

	# The getter route: no explicit target, perk_attack_target supplies it.
	behind.perk_attack_target = target
	if not behind._perk_condition_met("from_behind"):
		_fail("from_behind did not fall back to perk_attack_target")
	behind.perk_attack_target = null
	target.status_effects = []


## on_terrain_<ground>, read off the battle tile the unit stands on.
func _check_terrain_condition() -> void:
	var unit := _make_unit(Vector2i(9, 9), 0)
	var forest_id: int = int(Ground.by_key("forest").get("id", -1))
	grid.tiles[Vector2i(9, 9)].ground = forest_id
	if not unit._perk_condition_met("on_terrain_forest"):
		_fail("on_terrain_forest false while standing on forest ground")
	if unit._perk_condition_met("on_terrain_swamp"):
		_fail("on_terrain_swamp true while standing on forest ground")
	grid.tiles[Vector2i(9, 9)].ground = 0
	if unit._perk_condition_met("on_terrain_forest"):
		_fail("on_terrain_forest true on plains")


## A conditional crit_chance bonus used to be stored and never read: of the
## MODIFIABLE stats, only accuracy, dodge, damage and armour summed conditional
## perk bonuses. And the attack calculation must aim the perk at its defender
## and put the aim back afterwards.
func _check_conditional_crit_reaches_the_getter() -> void:
	var perk := _probe_perk("__probe_vitals__", [
		{"type": "stat_bonus", "stat": "crit_chance", "value": 10,
		 "conditions": ["target_bleeding"]}])
	var attacker := _make_unit(Vector2i(2, 8), 0, [perk])
	var victim := _make_unit(Vector2i(3, 8), 1)
	var base: float = attacker.get_crit_chance()
	victim.status_effects = [{"status": "Bleeding", "duration": 3}]
	attacker.perk_attack_target = victim
	var aimed: float = attacker.get_crit_chance()
	attacker.perk_attack_target = null
	if aimed - base != 10.0:
		_fail("conditional crit_chance: +%.1f against a bleeding target, expected +10"
			% (aimed - base))

	CombatManager.calculate_physical_damage(attacker, victim, "slashing")
	if attacker.perk_attack_target != null:
		_fail("calculate_physical_damage left perk_attack_target pointing at the defender")
	victim.status_effects = []


## An on_trigger effect with conditions fires only when they hold.
func _check_trigger_conditions() -> void:
	var perk := _probe_perk("__probe_bleed_hit__", [
		{"type": "on_trigger", "trigger": "on_hit", "conditions": ["target_bleeding"],
		 "effect": {"type": "buff", "stat": "damage", "value": 5, "duration": 2}}])
	var unit := _make_unit(Vector2i(1, 10), 0, [perk])
	var victim := _make_unit(Vector2i(2, 10), 1)
	CombatManager._fire_perk_triggers(unit, "on_hit", {"target": victim})
	if _mod(unit, "damage") != 0:
		_fail("an on_hit gated on target_bleeding fired against a clean target")
	victim.status_effects = [{"status": "Bleeding", "duration": 3}]
	CombatManager._fire_perk_triggers(unit, "on_hit", {"target": victim})
	if _mod(unit, "damage") != 5:
		_fail("an on_hit gated on target_bleeding did not fire against a bleeding target")
	victim.status_effects = []


func _check_combat_start_and_turn_start() -> void:
	var perk := _probe_perk("__probe_openers__", [
		{"type": "on_trigger", "trigger": "combat_start",
		 "effect": {"type": "buff", "stat": "initiative", "value": 4, "duration": 2}},
		{"type": "on_trigger", "trigger": "turn_start",
		 "effect": {"type": "buff", "stat": "movement", "value": 1, "duration": 1}}])
	var unit := _make_unit(Vector2i(10, 1), 0, [perk])

	var saved: Array[Node] = CombatManager.all_units.duplicate()
	CombatManager.all_units.assign([unit])
	CombatManager._apply_combat_start_perks()
	CombatManager.all_units.assign(saved)
	if _mod(unit, "initiative") != 4:
		_fail("combat_start: initiative modifier %d, expected 4" % _mod(unit, "initiative"))

	CombatManager.turn_order = [unit]
	CombatManager.current_unit_index = 0
	CombatManager._start_current_turn()
	if _mod(unit, "movement") != 1:
		_fail(("turn_start: movement modifier %d after the unit's turn began, expected 1 "
			+ "(a turn_start buff must survive its own turn's ticks)") % _mod(unit, "movement"))
	# And the combat_start buff, authored at the duration the comment in
	# CombatStats.PERK_TRIGGERS says, is still there for the first turn.
	if _mod(unit, "initiative") != 4:
		_fail("combat_start: a duration-2 buff did not survive the first turn start")


## take_damage on the hurt unit (with the attacker reachable as a payload
## target), ally_damaged on its living teammates and nobody else.
func _check_take_damage_and_ally_damaged() -> void:
	var hurt_perk := _probe_perk("__probe_hurt__", [
		{"type": "on_trigger", "trigger": "take_damage",
		 "effect": {"type": "buff", "stat": "damage", "value": 7, "duration": 2}},
		{"type": "on_trigger", "trigger": "take_damage",
		 "effect": {"type": "buff", "stat": "accuracy", "value": -3, "duration": 2,
			"target": "attacker"}}])
	var ally_perk := _probe_perk("__probe_ally__", [
		{"type": "on_trigger", "trigger": "ally_damaged",
		 "effect": {"type": "buff", "stat": "armor", "value": 6, "duration": 2,
			"target": "ally"}},
		{"type": "on_trigger", "trigger": "ally_damaged",
		 "effect": {"type": "buff", "stat": "dodge", "value": 4, "duration": 2}}])
	var victim := _make_unit(Vector2i(5, 1), 0, [hurt_perk])
	var friend := _make_unit(Vector2i(5, 2), 0, [ally_perk])
	var enemy := _make_unit(Vector2i(6, 1), 1)
	var enemy_friend := _make_unit(Vector2i(7, 1), 1, [ally_perk])

	CombatManager.apply_damage(victim, 20, "slashing", enemy)

	if _mod(victim, "damage") != 7:
		_fail("take_damage: the hurt unit's own buff is %d, expected 7" % _mod(victim, "damage"))
	if _mod(enemy, "accuracy") != -3:
		_fail("take_damage: the attacker-targeted payload gave %d accuracy, expected -3"
			% _mod(enemy, "accuracy"))
	if _mod(friend, "dodge") != 4:
		_fail("ally_damaged: the teammate's own buff is %d, expected 4" % _mod(friend, "dodge"))
	if _mod(victim, "armor") != 6:
		_fail("ally_damaged: the ally-targeted payload gave the hurt unit %d armour, expected 6"
			% _mod(victim, "armor"))
	if _mod(enemy_friend, "dodge") != 0:
		_fail("ally_damaged fired for a unit on the other team")

	# Damage with no named source: take_damage still fires, and the attacker-
	# targeted payload has nobody to land on, so it is dropped — not turned on
	# the unit itself.
	victim.stat_modifiers = []
	CombatManager.apply_damage(victim, 20, "slashing")
	if _mod(victim, "damage") != 7:
		_fail("take_damage did not fire for sourceless damage")
	if _mod(victim, "accuracy") != 0:
		_fail("an attacker-targeted payload with no attacker landed on the unit itself")


## parry_success: a melee miss against someone holding a melee weapon. Not a
## miss against bare hands, which is a dodge and only a dodge.
func _check_parry_success() -> void:
	var perk := _probe_perk("__probe_parry__", [
		{"type": "on_trigger", "trigger": "parry_success",
		 "effect": {"type": "buff", "stat": "crit_chance", "value": 9, "duration": 2}}])
	var defender := _make_unit(Vector2i(8, 4), 0, [perk])
	var attacker := _make_unit(Vector2i(9, 4), 1)

	for probe in [["sword", 9], ["bare hands", 0]]:
		defender.stat_modifiers = []
		if probe[0] == "sword":
			defender.character_data["equipped_weapon"] = {"type": "sword", "name": "Probe sword"}
		else:
			defender.character_data["equipped_weapon"] = {}
		CombatManager.turn_order = [attacker]
		CombatManager.current_unit_index = 0
		attacker.actions_remaining = 5
		attacker.will_miss_next_attack = true   # a guaranteed, deterministic miss
		var result: Dictionary = CombatManager.attack_unit(attacker, defender)
		if not result.get("success", false) or result.get("hit", true):
			_fail("parry probe (%s): the attack did not resolve as a miss (%s)"
				% [probe[0], result])
			continue
		if _mod(defender, "crit_chance") != probe[1]:
			_fail("parry_success with %s gave %d crit, expected %d"
				% [probe[0], _mod(defender, "crit_chance"), probe[1]])


## While a payload resolves, nothing else fires — the loop guard.
func _check_reentrancy_guard() -> void:
	var perk := _probe_perk("__probe_guard__", [
		{"type": "on_trigger", "trigger": "take_damage",
		 "effect": {"type": "buff", "stat": "damage", "value": 2, "duration": 2}}])
	var unit := _make_unit(Vector2i(10, 10), 0, [perk])

	CombatManager._resolving_perk_trigger = true
	CombatManager.apply_damage(unit, 5, "slashing")
	CombatManager._resolving_perk_trigger = false
	if _mod(unit, "damage") != 0:
		_fail("a trigger fired while another trigger's payload was resolving")

	CombatManager.apply_damage(unit, 5, "slashing")
	if _mod(unit, "damage") != 2:
		_fail("take_damage did not fire after the guard was released")
	if CombatManager._resolving_perk_trigger:
		_fail("the re-entrancy guard was left set after a payload resolved")


## A timed stat modifier loses ONE turn of duration per turn of its owner —
## with or without a status on the unit. It used to tick twice whenever the
## unit carried any status (once in _process_status_effects, once in
## _process_turn_start_perks), so every buff and debuff lasted half its
## stated duration — and only sometimes, which is worse.
func _check_stat_modifiers_tick_once() -> void:
	for with_status in [false, true]:
		var unit := _make_unit(Vector2i(9, 9), 0)
		if with_status:
			# Any long-lived status: it is what sent the old code down the
			# second tick.
			unit.status_effects = [{"status": "Blessed", "duration": 10}]
		CombatManager._apply_stat_modifier(unit, "accuracy", 7, 2)

		CombatManager.turn_order = [unit]
		CombatManager.current_unit_index = 0
		CombatManager._start_current_turn()
		if _mod(unit, "accuracy") != 7:
			_fail("a duration-2 modifier was gone after ONE turn start (with a status: %s)"
				% with_status)
		CombatManager.current_unit_index = 0
		CombatManager._start_current_turn()
		if _mod(unit, "accuracy") != 0:
			_fail("a duration-2 modifier outlived its second turn start (with a status: %s)"
				% with_status)
		if with_status and not unit.has_status("Blessed"):
			_fail("the probe status expired early — the tick check proved nothing")


## Rousing Display's round-1 Initiative must be there when round 1 is sorted.
## It was applied after the turn order was built, changed nothing, and had
## ticked away by round 2.
func _check_rousing_display_sorts_round_one() -> void:
	var leader := _make_unit(Vector2i(1, 8), 0, ["rousing_display"])
	var ally := _make_unit(Vector2i(2, 8), 0)
	var enemy := _make_unit(Vector2i(9, 8), 1)
	# Blank characters tie on Initiative. Put the enemy 1 ahead of the ally,
	# so only the +2 arriving before the sort lets the ally go first; and
	# the leader well behind, so the first turn (which ticks) is not theirs.
	CombatManager._apply_stat_modifier(enemy, "initiative", 1, 9)
	CombatManager._apply_stat_modifier(leader, "initiative", -20, 9)

	var saved: Array[Node] = CombatManager.all_units.duplicate()
	CombatManager.all_units.assign([leader, ally, enemy])
	CombatManager._finalize_combat_start()
	var order: Array = CombatManager.turn_order.duplicate()
	CombatManager.all_units.assign(saved)

	if order.find(ally) < 0 or order.find(enemy) < 0:
		_fail("Rousing Display probe: the turn order is missing a unit (%s)" % [order])
	elif order.find(ally) > order.find(enemy):
		_fail("Rousing Display: the inspired ally still acts after an enemy at +1 — "
			+ "the buff arrived after round 1 was sorted")
	# Used, then gone: the ally's own first turn start has ticked it away, so
	# it cannot carry into round 2's sort.
	if _mod(ally, "initiative") != 0:
		_fail("Rousing Display's buff survived the ally's first turn (%d left)"
			% _mod(ally, "initiative"))
	CombatManager.turn_order.clear()


## A unit skipped for actions — bleeding out, or a decoy with none — still has
## its statuses and modifiers count down at the point its turn would come. It
## used to skip straight past, and a bleeding-out unit fell out of the next
## round's order altogether, so a buff on a downed ally rode on for ever (and
## its bleed-out never counted down).
func _check_downed_and_actionless_units_tick() -> void:
	for kind in ["bleeding", "decoy"]:
		var skipped := _make_unit(Vector2i(10, 1), 0)
		var next := _make_unit(Vector2i(10, 3), 0)
		if kind == "bleeding":
			skipped.is_bleeding_out = true
			skipped.bleed_out_turns = 3
		else:
			skipped.max_actions = 0
		skipped.status_effects = [{"status": "Blessed", "duration": 1}]
		CombatManager._apply_stat_modifier(skipped, "accuracy", 7, 1)

		# `next` stands behind it so the skip has somewhere to advance to.
		CombatManager.turn_order.assign([skipped, next])
		CombatManager.current_unit_index = 0
		CombatManager._start_current_turn()
		if _mod(skipped, "accuracy") != 0:
			_fail("a %s unit's stat modifier did not tick when its turn was skipped" % kind)
		if skipped.has_status("Blessed"):
			_fail("a %s unit's status did not tick when its turn was skipped" % kind)
		if kind == "bleeding" and (skipped.bleed_out_turns != 2 or skipped.is_dead):
			_fail("bleed-out did not count down once (%d left, dead=%s)"
				% [skipped.bleed_out_turns, skipped.is_dead])

		# And it keeps its place in the next round's order.
		var saved: Array[Node] = CombatManager.all_units.duplicate()
		CombatManager.all_units.assign([skipped, next])
		CombatManager._calculate_turn_order()
		CombatManager.all_units.assign(saved)
		if not skipped in CombatManager.turn_order:
			_fail("a %s unit fell out of the next round's turn order" % kind)
		CombatManager.turn_order.clear()
		skipped.is_bleeding_out = false


## Avatar of the Wind's buffs, cast at the holder's turn start, must reach
## every ally for one turn of that ally's own — the ones acting after the
## holder this round and the ones acting before it next round — and refresh
## rather than stack.
func _check_avatar_of_the_wind_reaches_every_ally() -> void:
	var before := _make_unit(Vector2i(1, 11), 0)
	var holder := _make_unit(Vector2i(2, 11), 0, ["avatar_of_the_wind"])
	var after := _make_unit(Vector2i(3, 11), 0)
	CombatManager.turn_order.assign([before, holder, after])

	for round_no in [1, 2]:
		for i in range(3):
			CombatManager.current_unit_index = i
			CombatManager._start_current_turn()
			var unit: CombatUnit = CombatManager.turn_order[i]
			# What matters is what the ally ACTS with, i.e. after its own
			# turn start ticked. Round 1's first ally has not been reached yet.
			if unit == holder or (unit == before and round_no == 1):
				continue
			if _mod(unit, "dodge") != 5 or _mod(unit, "movement") != 1:
				_fail("Avatar of the Wind: %s acts in round %d with dodge %+d, move %+d "
					% [unit.unit_name, round_no, _mod(unit, "dodge"), _mod(unit, "movement")]
					+ "(expected +5, +1)")

	# The wind dies with the holder's perk: one more turn, then gone.
	holder.character_data["perks"].clear()
	for i in [0, 0]:
		CombatManager.current_unit_index = i
		CombatManager._start_current_turn()
	if _mod(before, "dodge") != 0:
		_fail("Avatar of the Wind outlived its holder by more than a turn (%+d)"
			% _mod(before, "dodge"))
	CombatManager.turn_order.clear()


## Borrowed Opening: dodge a blow, and your next attack gets +20% CRIT (it gave
## +20 damage) — still there on your own turn, which a duration-1 buff laid on
## the enemy's turn was not, and spent by the attack.
func _check_borrowed_opening_waits_for_the_attack() -> void:
	var monk := _make_unit(Vector2i(6, 11), 0, ["borrowed_opening"])
	var foe := _make_unit(Vector2i(7, 11), 1)
	monk.character_data["equipped_weapon"] = {}   # unarmed
	CombatManager._fire_perk_triggers(monk, "dodge_success", {"attacker": foe})
	if _mod(monk, "damage") != 0 or _mod(monk, "crit_chance") != 20:
		_fail("Borrowed Opening gave damage %+d, crit %+d (expected crit +20 only)"
			% [_mod(monk, "damage"), _mod(monk, "crit_chance")])
	CombatManager.turn_order.assign([monk])
	CombatManager.current_unit_index = 0
	CombatManager._start_current_turn()
	if _mod(monk, "crit_chance") != 20:
		_fail("Borrowed Opening's crit was gone by the monk's own turn")
	CombatManager._spend_next_attack_modifiers(monk)
	if _mod(monk, "crit_chance") != 0:
		_fail("Borrowed Opening's crit was not spent by the attack")
	CombatManager.turn_order.clear()


## Every Opening Is an Invitation: "+15% Attack and +10% crit against enemies
## SUFFERING from any status effect" — a Blessed enemy is not suffering.
func _check_every_opening_wants_a_debuff() -> void:
	var attacker := _make_unit(Vector2i(3, 10), 0)
	var defender := _make_unit(Vector2i(4, 10), 1)
	# Keep the hit chance well inside its 10..95 clamp so +15 shows.
	CombatManager._apply_stat_modifier(defender, "dodge", 40, 9)
	var perks: Array = attacker.character_data["perks"]

	# [status on the defender, accuracy the perk should add, crit test result]
	for case in [["Blessed", 0.0, false], ["Bleeding", 15.0, true], ["", 0.0, false]]:
		defender.status_effects = []
		if case[0] != "":
			defender.status_effects = [{"status": case[0], "duration": 5}]
		perks.clear()
		var without: float = CombatManager.calculate_hit_chance(attacker, defender)
		perks.append({"id": "every_opening_is_an_invitation"})
		var with_perk: float = CombatManager.calculate_hit_chance(attacker, defender)
		if not is_equal_approx(with_perk - without, case[1]):
			_fail("Every Opening vs %s: +%.1f accuracy, expected +%.1f"
				% [case[0] if case[0] != "" else "no status", with_perk - without, case[1]])
		# The crit half asks the same question; it is inline in the damage roll.
		if CombatManager._opening_is_an_invitation(attacker, defender) != case[2]:
			_fail("Every Opening's crit test vs %s gave %s" % [case[0], not case[2]])
	perks.clear()
	defender.status_effects = []
	var cm_src := FileAccess.get_file_as_string("res://scripts/autoload/combat_manager.gd")
	if cm_src.count("_opening_is_an_invitation(attacker, defender)") < 2:
		_fail("the accuracy and crit halves of Every Opening no longer share one test")
