class_name ValuePaths
extends RefCounted
## Reads and writes the values an effect can change ("stat.dodge",
## "resist.fire"), through "holds" kept on the unit.
##
## A HOLD is one effect's grip on one value: {value, mode, amount, source_id}.
## It lasts until release() is called for its source, so a status, aura or item
## adds a hold when it begins and releases it when it ends.
##
## Holds live in `unit.effect_holds` (an Array[Dictionary] on CombatUnit). The
## stat getters and Resistance.total() pass their finished number through
## apply_to(), which is where holds take effect. With no holds, apply_to()
## returns its input unchanged.
##
## ORDER OF APPLICATION in apply_to():
##   1. base + (sum of fortify) - (sum of drain)
##   2. times the product of every multiply
##   3. the LAST-ADDED `set` replaces the result, if any set exists
##
## Stage 1 wires the `stat.` and `resist.` namespaces only.


## Give `unit` a hold on `value`. A second hold with the same (value, source_id)
## replaces the first rather than stacking, so re-applying a buff refreshes it.
## A bad value path or a mode the namespace does not allow is a loud error.
static func add_hold(unit: Node, value: String, mode: String, amount: float,
		source_id: String) -> void:
	if not EffectVocab.is_value_path(value):
		push_error("ValuePaths.add_hold: unknown value path '%s'" % value)
		return
	var namespace_name: String = value.get_slice(".", 0)
	var allowed: Array = EffectVocab.MODES_BY_NAMESPACE.get(namespace_name, [])
	if not mode in allowed:
		push_error("ValuePaths.add_hold: mode '%s' is not allowed for '%s' (allowed: %s)"
			% [mode, value, allowed])
		return
	if not "effect_holds" in unit:
		push_error("ValuePaths.add_hold: %s has no effect_holds" % unit)
		return
	_remove(unit, value, source_id)
	# Appended last, so a later `set` beats an earlier one.
	unit.effect_holds.append({"value": value, "mode": mode, "amount": amount,
		"source_id": source_id})


## Remove every hold that `source_id` placed, on any value.
static func release(unit: Node, source_id: String) -> void:
	if not "effect_holds" in unit:
		return
	for i in range(unit.effect_holds.size() - 1, -1, -1):
		if str(unit.effect_holds[i].get("source_id", "")) == source_id:
			unit.effect_holds.remove_at(i)


## `base` after every hold on `value` has been applied (see the order above).
## Called from hot getters, so the no-holds case returns at once.
static func apply_to(unit: Node, value: String, base: float) -> float:
	if unit == null or not "effect_holds" in unit or unit.effect_holds.is_empty():
		return base
	var sum: float = 0.0
	var factor: float = 1.0
	var has_set: bool = false
	var set_to: float = 0.0
	for hold in unit.effect_holds:
		if hold.value != value:
			continue
		var amount: float = float(hold.amount)
		match str(hold.mode):
			"fortify": sum += amount
			"drain": sum -= amount
			"multiply": factor *= amount
			"set":
				has_set = true
				set_to = amount   # later holds overwrite: last-added wins
	if has_set:
		return set_to
	return (base + sum) * factor


## True when `unit` has a `set` hold on `value`. Resistance uses this to know a
## declared number may cross the usual cap.
static func has_set(unit: Node, value: String) -> bool:
	for hold in holds_on(unit, value):
		if hold.mode == "set":
			return true
	return false


## A copy of every hold on `value`, oldest first.
static func holds_on(unit: Node, value: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if unit == null or not "effect_holds" in unit:
		return out
	for hold in unit.effect_holds:
		if hold.value == value:
			out.append(hold.duplicate())
	return out


static func _remove(unit: Node, value: String, source_id: String) -> void:
	for i in range(unit.effect_holds.size() - 1, -1, -1):
		var hold: Dictionary = unit.effect_holds[i]
		if hold.value == value and str(hold.source_id) == source_id:
			unit.effect_holds.remove_at(i)
