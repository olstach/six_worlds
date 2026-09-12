extends Node
## Headless verification for active-perk combat_data.
##
## Run: godot --headless res://tools/verify_active_perks.tscn
##
## Runs as a scene rather than via --script so the autoloads exist — every check
## here reads PerkSystem and CombatManager at runtime, which is the point: a
## green tools/validate_data.py only proves the JSON parses in Python, not that
## the game's own loaders agree with it.
##
## Exits non-zero if any assertion fails.

var failures: int = 0

## The vocabularies live in CombatStats. Restating them here is what let the
## first round of these bugs through, so this file only ever reads them.


func _ready() -> void:
	var wired := _collect_wired()
	print("Active perks carrying combat_data: %d" % wired.size())
	if wired.is_empty():
		_fail("no perk carries combat_data — the wiring pass did not land")

	for entry in wired:
		_check_effect(entry)
		_check_targeting(entry)
		_check_aoe_shape(entry)
		_check_statuses(entry)
		_check_buff_stats(entry)
		_check_costs(entry)

	_check_non_combat_perks()
	_check_modifiable_stats_are_read()
	_check_no_orphan_actives()

	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK")
		get_tree().quit(0)


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


## Every perk in the game that has a combat_data block, as {id, data, cd}.
func _collect_wired() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for perk_id in PerkSystem.get_all_perk_ids():
		var data: Dictionary = PerkSystem.get_perk_data(perk_id)
		var cd: Dictionary = data.get("combat_data", {})
		if not cd.is_empty():
			out.append({"id": perk_id, "data": data, "cd": cd})
	return out


## The effect string must name a resolver `use_active_skill` dispatches to.
## Checked against the live dispatcher rather than a copied list.
func _check_effect(entry: Dictionary) -> void:
	var effect: String = entry.cd.get("effect", "")
	if effect == "":
		_fail("%s: combat_data has no effect" % entry.id)
	elif not CombatManager.is_active_skill_effect_implemented(effect):
		_fail("%s: effect '%s' has no resolver" % [entry.id, effect])


func _check_targeting(entry: Dictionary) -> void:
	var targeting: String = CombatManager.get_skill_targeting(entry.cd)
	if not CombatStats.is_targeting(targeting):
		_fail("%s: targeting '%s' produces no target tiles" % [entry.id, targeting])
	# Targeted skills need a reach. Melee resolvers default to 1, which silently
	# makes a "visible enemy" skill adjacent-only, so require it to be explicit.
	if targeting != "self" and not entry.cd.has("range") and not entry.cd.has("dash_range") \
			and not entry.cd.has("teleport_range") and not entry.cd.has("aoe_radius"):
		_fail("%s: targeting '%s' but no range declared" % [entry.id, targeting])


## A shaped area must actually produce tiles. AoEResolver falls back to a circle
## on an unknown shape with only a push_warning, which would quietly turn a
## sweep into a burst, so run the real resolver and look at what comes back.
func _check_aoe_shape(entry: Dictionary) -> void:
	var aoe: Dictionary = entry.cd.get("aoe", {})
	if aoe.is_empty():
		return
	if entry.cd.has("aoe_radius"):
		_fail("%s: declares both an aoe block and aoe_radius" % entry.id)
	# A caster at (10,10) aiming one tile east — enough to exercise every shape.
	var tiles: Array[Vector2i] = AoEResolver.get_tiles(
		aoe, Vector2i(10, 10), Vector2i(11, 10), Vector2i(48, 30))
	if tiles.is_empty():
		_fail("%s: aoe shape '%s' covers no tiles" % [entry.id, aoe.get("type", "")])


## Status names must resolve in CombatManager's loaded table, not just exist in
## statuses.json — the two have diverged before.
func _check_statuses(entry: Dictionary) -> void:
	var names: Array[String] = []
	for key in ["statuses"]:
		for se in entry.cd.get(key, []):
			names.append(str(se.get("status", "")))
	if entry.cd.has("alternate_status"):
		names.append(str(entry.cd["alternate_status"].get("status", "")))
	for buff in entry.cd.get("buffs", []):
		if buff.get("stat", "") == "movement_mode":
			names.append(str(buff.get("status", "")))

	for status_name in names:
		if status_name == "":
			_fail("%s: empty status name" % entry.id)
		elif CombatManager.get_status_definition(status_name).is_empty():
			_fail("%s: status '%s' is not loaded at runtime" % [entry.id, status_name])


func _check_buff_stats(entry: Dictionary) -> void:
	for key in ["buffs", "ally_buffs", "debuffs", "enemy_debuffs"]:
		for buff in entry.cd.get(key, []):
			var stat: String = str(buff.get("stat", ""))
			if not CombatStats.is_authorable(stat):
				_fail("%s: %s stat '%s' is never read back" % [entry.id, key, stat])
	for key in ["self_buff", "target_debuff"]:
		var buff: Dictionary = entry.cd.get(key, {})
		if buff.is_empty():
			continue
		if not CombatStats.is_modifiable(str(buff.get("stat", ""))):
			_fail("%s: %s stat '%s' is never read back" % [entry.id, key, buff.get("stat", "")])


## The cost the button advertises and the cost use_active_skill charges must be
## the same number, or a skill looks free and then drains stamina.
func _check_costs(entry: Dictionary) -> void:
	var declared: int = int(entry.cd.get("stamina_cost", 0))
	var desc: String = entry.data.get("description", "")
	# The cost can sit anywhere in the opening parenthetical: "(3 Stamina)",
	# "(10 Stamina, once per combat)", "(4 Stamina + 8 Mana)". Match the first
	# "<number> Stamina" in the text — a later "restore 30% of max Stamina" has
	# no digits directly in front of the word, so it cannot be picked up.
	var regex := RegEx.new()
	regex.compile("(\\d+)\\s*Stamina")
	var found := regex.search(desc)
	if found:
		var stated := int(found.get_string(1))
		if stated != declared:
			_fail("%s: description says %d Stamina, combat_data charges %d"
				% [entry.id, stated, declared])
	elif declared > 0:
		_fail("%s: combat_data charges %d Stamina the description never mentions"
			% [entry.id, declared])


## Every stat in CombatStats.MODIFIABLE must have a consumer — some getter that
## calls _get_stat_modifier_bonus("<stat>") and folds the result into a number
## the game uses. This is the pairing that kept breaking: save_bonus was written
## by Booster Shot from the day it shipped and nothing on the other end read it.
##
## Calling _get_stat_modifier_bonus() directly would prove nothing — it sums by
## name for any string at all, so it answers for a stat with no consumer exactly
## as it does for a real one. The consumer is what must be checked, so this
## greps the sources for the call.
func _check_modifiable_stats_are_read() -> void:
	var sources := ""
	for path in ["res://scripts/combat/combat_unit.gd",
			"res://scripts/autoload/combat_manager.gd",
			"res://scripts/combat/save_system.gd"]:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			_fail("cannot read %s to check stat consumers" % path)
			return
		sources += f.get_as_text()
		f.close()

	for stat in CombatStats.MODIFIABLE:
		if not sources.contains('_get_stat_modifier_bonus("%s")' % stat):
			_fail(("%s is in CombatStats.MODIFIABLE but nothing calls "
				+ "_get_stat_modifier_bonus(\"%s\") — a modifier on it would be "
				+ "stored and never applied") % [stat, stat])


## Overworld and out-of-combat abilities must not also carry combat_data.
func _check_non_combat_perks() -> void:
	for perk_id in PerkSystem.get_all_perk_ids():
		var data: Dictionary = PerkSystem.get_perk_data(perk_id)
		if data.get("non_combat", false) and not data.get("combat_data", {}).is_empty():
			_fail("%s: flagged non_combat but carries combat_data" % perk_id)


## Report — but do not fail on — active perks still waiting for a resolver.
## These stay correctly greyed out in the skill panel; the count is the backlog.
func _check_no_orphan_actives() -> void:
	var orphans: Array[String] = []
	for perk_id in PerkSystem.get_all_perk_ids():
		var data: Dictionary = PerkSystem.get_perk_data(perk_id)
		if not str(data.get("description", "")).begins_with("Active"):
			continue
		if data.get("non_combat", false) or data.get("is_mantra", false):
			continue
		if data.get("combat_data", {}).is_empty():
			orphans.append(perk_id)
	orphans.sort()
	print("Active perks still awaiting a resolver: %d" % orphans.size())
	for perk_id in orphans:
		print("  - ", perk_id)
