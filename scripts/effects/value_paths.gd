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
## Stage 1 wires `stat.`, `resist.`, `attribute.` and `skill.` (fortify and
## drain only; damage/restore on attribute/skill come later).
##
## `attribute.` holds do not change a getter directly. refresh_attribute_deltas()
## re-runs the shared attribute formula (CombatStats.attribute_terms) with and
## without the holds and stores the difference as internal `stat.` holds under
## the source id "__attr". Only that function may release "__attr".
## `skill.` holds are summed into character_data["skill_bonuses"][skill]["effects"],
## which CharacterSystem.get_effective_skill_level already adds up.

## Source id of the internal stat holds derived from attribute holds.
const ATTR_SOURCE: String = "__attr"
## Key under skill_bonuses[skill] that holds the summed skill. holds.
const SKILL_EFFECTS_KEY: String = "effects"
## Stats an attribute change can move through a `stat.` hold.
const _ATTR_STAT_TERMS: Array[String] = ["initiative", "movement", "dodge",
	"spellpower", "crit_chance"]
## Resource maxima an attribute change can move (applied to the unit's max_*).
const _ATTR_MAX_TERMS: Array[String] = ["max_hp", "max_mana", "max_stamina"]


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
	_after_change(unit, [value])


## Remove every hold that `source_id` placed, on any value.
static func release(unit: Node, source_id: String) -> void:
	if not "effect_holds" in unit:
		return
	var touched: Array[String] = []
	for i in range(unit.effect_holds.size() - 1, -1, -1):
		if str(unit.effect_holds[i].get("source_id", "")) == source_id:
			touched.append(str(unit.effect_holds[i].get("value", "")))
			unit.effect_holds.remove_at(i)
	_after_change(unit, touched)


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


## Bring the unit's derived numbers in line with its `attribute.` holds.
## Computes attribute_terms(attrs + holds) - attribute_terms(attrs) and stores
## each stat difference as a "__attr" `stat.` hold; the max_hp / max_mana /
## max_stamina differences are added to the unit's max_* fields (and current_*
## is clamped when a maximum shrinks). Safe to call at any time; it works from
## the holds as they stand, so calling it twice changes nothing.
static func refresh_attribute_deltas(unit: Node) -> void:
	if unit == null or not "effect_holds" in unit:
		return
	# Drop the old internal holds directly (not via release(), which would
	# call back into us).
	for i in range(unit.effect_holds.size() - 1, -1, -1):
		if str(unit.effect_holds[i].get("source_id", "")) == ATTR_SOURCE:
			unit.effect_holds.remove_at(i)

	var base_attrs: Dictionary = _effective_attributes(unit)
	var held_attrs: Dictionary = base_attrs.duplicate()
	for hold in unit.effect_holds:
		var value: String = str(hold.value)
		if not value.begins_with("attribute."):
			continue
		var attr: String = value.get_slice(".", 1)
		var amount: int = int(round(float(hold.amount)))
		match str(hold.mode):
			"fortify": held_attrs[attr] = int(held_attrs.get(attr, 10)) + amount
			"drain": held_attrs[attr] = int(held_attrs.get(attr, 10)) - amount

	var before: Dictionary = CombatStats.attribute_terms(base_attrs)
	var after: Dictionary = CombatStats.attribute_terms(held_attrs)

	for stat in _ATTR_STAT_TERMS:
		var delta: int = int(after[stat]) - int(before[stat])
		if delta != 0:
			unit.effect_holds.append({"value": "stat." + stat, "mode": "fortify",
				"amount": delta, "source_id": ATTR_SOURCE})

	# Resource maxima: remember what we added last time so the change is exact.
	var applied: Dictionary = unit.get_meta("attr_max_applied", {})
	var now: Dictionary = {}
	for term in _ATTR_MAX_TERMS:
		now[term] = int(after[term]) - int(before[term])
		var change: int = int(now[term]) - int(applied.get(term, 0))
		if change == 0:
			continue
		var current_field: String = "current_" + term.trim_prefix("max_")
		unit.set(term, int(unit.get(term)) + change)
		if int(unit.get(current_field)) > int(unit.get(term)):
			unit.set(current_field, int(unit.get(term)))
	if _all_zero(now):
		if unit.has_meta("attr_max_applied"):
			unit.remove_meta("attr_max_applied")
	else:
		unit.set_meta("attr_max_applied", now)


## Rewrite character_data["skill_bonuses"][skill]["effects"] from the unit's
## `skill.` holds. A total of zero erases the key (and the skill's entry if it
## ends up empty), so a released hold leaves the dictionary as it was found.
static func _refresh_skill(unit: Node, skill: String) -> void:
	if not "character_data" in unit:
		return
	var data: Dictionary = unit.character_data
	var total: int = 0
	var value: String = "skill." + skill
	for hold in unit.effect_holds:
		if hold.value != value:
			continue
		var amount: int = int(round(float(hold.amount)))
		match str(hold.mode):
			"fortify": total += amount
			"drain": total -= amount
	if total != 0:
		if not data.has("skill_bonuses"):
			data["skill_bonuses"] = {}
		if not data["skill_bonuses"].has(skill):
			data["skill_bonuses"][skill] = {}
		data["skill_bonuses"][skill][SKILL_EFFECTS_KEY] = total
		return
	if data.has("skill_bonuses") and data["skill_bonuses"].has(skill):
		data["skill_bonuses"][skill].erase(SKILL_EFFECTS_KEY)
		if data["skill_bonuses"][skill].is_empty():
			data["skill_bonuses"].erase(skill)


## After holds on `values` changed, refresh whatever is derived from them.
static func _after_change(unit: Node, values: Array) -> void:
	var attr_changed: bool = false
	var skills: Array[String] = []
	for value in values:
		var v: String = str(value)
		if v.begins_with("attribute."):
			attr_changed = true
		elif v.begins_with("skill."):
			var skill: String = v.get_slice(".", 1)
			if not skill in skills:
				skills.append(skill)
	if attr_changed:
		refresh_attribute_deltas(unit)
	for skill in skills:
		_refresh_skill(unit, skill)


## The unit's attributes as the derived-stat formula sees them: base attributes
## plus gear and trait bonuses, like CharacterSystem.update_derived_stats.
static func _effective_attributes(unit: Node) -> Dictionary:
	var data: Dictionary = unit.character_data if "character_data" in unit else {}
	var out: Dictionary = data.get("attributes", {}).duplicate()
	if ItemSystem and data.has("equipment"):
		var equip: Dictionary = ItemSystem.calculate_equipment_stats(data)
		for key in out:
			out[key] = int(out[key]) + int(equip.get(key, 0))
	if TraitSystem and data.has("traits"):
		var bonus: Dictionary = TraitSystem.get_attribute_bonus(data)
		for key in out:
			out[key] = int(out[key]) + int(bonus.get(key, 0))
	return out


static func _all_zero(d: Dictionary) -> bool:
	for k in d:
		if int(d[k]) != 0:
			return false
	return true
