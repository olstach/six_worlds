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
	var unit := CombatUnit.new()
	unit.character_data = character
	var boosted := 0
	for i in 400:
		if CombatManager._perform_save_roll(unit, "focus"):
			boosted += 1
	unit.free()
	# Base Focus 10 gives a 40% save; +15 makes it 55%. Either side of the
	# midpoint over 400 rolls is a safe bound for a 15-point shift.
	if boosted < 180:
		_fail("calm_mind: %d/400 Focus saves passed — the bonus is not reaching the roll"
			% boosted)


## aegis_of_tranquility and stone_body write into derived.resistances.
func _check_resistances() -> void:
	var character := _blank()
	_grant(character, "aegis_of_tranquility")
	var resists: Dictionary = character.derived.get("resistances", {})
	for element in ["fire", "water", "air", "earth", "space"]:
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
	var gained := unit._get_stat_modifier_bonus("damage")

	# A trigger that does not match must do nothing.
	unit.stat_modifiers = []
	CombatManager._fire_perk_triggers(unit, "on_kill", {})
	var spurious := unit._get_stat_modifier_bonus("damage")
	unit.free()

	if gained != 20:
		_fail("borrowed_opening: dodge_success gave %d damage, expected 20" % gained)
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
