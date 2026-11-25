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
## Stage 1 wires `stat.`, `resist.`, `attribute.` and `skill.`. Holds take
## fortify and drain there; the persistent `damage` mode and its `restore` have
## their own homes, apply_damage_mode() and clear_damage(), further down.
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
	# `damage` and `restore` on attribute./skill. are not holds: they live on the
	# character and are handled by apply_damage_mode() / clear_damage().
	if mode in ["damage", "restore"] and namespace_name in ["attribute", "skill"]:
		push_error("ValuePaths.add_hold: mode '%s' on '%s' is not a hold; use apply_damage_mode() or clear_damage()"
			% [mode, value])
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


## Drop every hold on `unit` and put everything they touched back: the skill
## "effects" keys, the internal "__attr" stat holds and the max_* changes.
## Called when a fight ends. In stage 1 every hold is combat-scoped; a
## `persistent` scope arrives with statuses in stage 2.
static func release_all_combat(unit: Node) -> void:
	if unit == null or not "effect_holds" in unit:
		return
	# Note which skills had holds so their "effects" keys can be erased.
	var skills: Array[String] = []
	for hold in unit.effect_holds:
		var v: String = str(hold.value)
		if v.begins_with("skill.") and not v.get_slice(".", 1) in skills:
			skills.append(v.get_slice(".", 1))
	unit.effect_holds.clear()   # includes the "__attr" holds
	# The holds that carried persistent damage are gone: let the entries count.
	if "character_data" in unit:
		for entry in unit.character_data.get("damaged_values", []):
			entry.erase("held")
	for skill in skills:
		_refresh_skill(unit, skill)   # no holds left, so the key is erased
	# With no attribute holds left this removes any __attr remnants and
	# returns max_hp / max_mana / max_stamina to base.
	refresh_attribute_deltas(unit)


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


# ── Persistent damage ────────────────────────────────────────────────────────
#
# A `damage`-mode modify lowers an attribute or skill until something heals it.
# On a party member it is an ENTRY in character["damaged_values"]:
#   {value, amount, cleared_by, source}
# CharacterSystem.update_derived_stats subtracts the attribute entries and
# get_effective_skill_level subtracts the skill entries, so the loss survives
# combat and a save. On anyone else it is just a drain hold that ends with the
# fight.

## Highest rest tier each {"rest": ...} word needs (1 Quick, 2 Camp, 3 Full).
const _REST_TIER: Dictionary = {"quick": 1, "camp": 2, "full": 3}


## Lower `value` ("attribute.x" or "skill.x") on `unit` by `amount` until
## `cleared_by` (a list like [{"rest": "full"}]) heals it. An empty list means
## the default, [{rest: full}, {restore: <value>}]. `source` names the cause.
##
## Party unit: writes the entry AND, for attributes, a combat drain hold
## "__damage:<source>" so the loss bites this fight too (derived stats are not
## recomputed mid-fight). End of combat releases the hold and recomputes the
## derived stats from the entry, so the loss is counted once. A skill needs no
## hold: get_effective_skill_level reads the entry at once.
## Anyone else: only the drain hold, which ends with the fight.
static func apply_damage_mode(unit: Node, value: String, amount: float,
		cleared_by: Array, source: String) -> void:
	var namespace_name: String = value.get_slice(".", 0)
	if not EffectVocab.is_value_path(value) or not namespace_name in ["attribute", "skill"]:
		push_error("ValuePaths.apply_damage_mode: '%s' is not an attribute. or skill. path" % value)
		return
	if amount <= 0.0:
		return
	var hold_source: String = "__damage:" + source
	if not _is_party_unit(unit):
		add_hold(unit, value, "drain", amount, hold_source)
		return
	var data: Dictionary = unit.character_data
	if not data.has("damaged_values"):
		data["damaged_values"] = []
	var entry: Dictionary = {"value": value, "amount": amount,
		"cleared_by": cleared_by.duplicate(true), "source": source}
	# An attribute entry is "held" while its combat hold is live: the hold
	# carries the loss, so damaged_total() skips it and update_derived_stats()
	# (which can run mid-fight, e.g. after a wound) does not count it twice.
	# release_all_combat() clears the flag when the hold goes.
	if namespace_name == "attribute":
		entry["held"] = true
	data["damaged_values"].append(entry)
	if namespace_name == "attribute":
		# A second hit from the same source this fight adds to its hold.
		var total: float = amount
		for hold in holds_on(unit, value):
			if str(hold.source_id) == hold_source:
				total += float(hold.amount)
		add_hold(unit, value, "drain", total, hold_source)


## Total persistent damage on `value` ("attribute.focus") in `character`,
## leaving out entries whose combat hold is still carrying the loss ("held").
static func damaged_total(character: Dictionary, value: String) -> float:
	var total: float = 0.0
	for entry in character.get("damaged_values", []):
		if str(entry.get("value", "")) == value and not entry.get("held", false):
			total += float(entry.get("amount", 0))
	return total


## Remove the damage entries `kind` heals and return how many entries were
## removed. `kind` is one of EffectVocab.CLEARED_BY; `detail` says what
## happened:
##   rest:    {tier}              1 Quick, 2 Camp, 3 Full
##   heal:    {school, level}     school may be a String or an Array of them
##   restore: {value, amount?}    no amount clears every entry for that value;
##            with an amount it takes off that many points in total, oldest
##            entry first, and removes the entries that reach 0 (a partly
##            reduced entry is kept and does not count).
## `unit` is the combat unit carrying `character`, when this happens mid-fight.
## Pass it so that clearing a HELD attribute entry (one whose combat drain hold
## "__damage:<source>" is carrying the loss this fight) also lowers or releases
## that hold, and the heal is felt at once rather than only after the fight.
## The caller refreshes derived stats afterwards (update_derived_stats).
static func clear_damage(character: Dictionary, kind: String, detail: Dictionary,
		unit: Node = null) -> int:
	if not kind in EffectVocab.CLEARED_BY:
		push_error("ValuePaths.clear_damage: unknown kind '%s'" % kind)
		return 0
	var entries: Array = character.get("damaged_values", [])
	var removed: int = 0
	var budget: float = float(detail.get("amount", INF)) if kind == "restore" else INF
	# Entries are stored oldest first, so a limited restore heals the oldest first.
	var keep: Array = []
	# How much was taken off held entries, so their holds can follow: a list of
	# {value, source, amount}.
	var held_cleared: Array[Dictionary] = []
	for entry in entries:
		if not _entry_cleared_by(entry, kind, detail) or budget <= 0.0:
			keep.append(entry)
			continue
		var amount: float = float(entry.get("amount", 0))
		var taken: float = minf(amount, budget)
		if amount <= budget:
			budget -= amount
			removed += 1
		else:
			entry["amount"] = amount - budget
			budget = 0.0
			keep.append(entry)
		if entry.get("held", false):
			held_cleared.append({"value": str(entry.get("value", "")),
				"source": str(entry.get("source", "")), "amount": taken})
	if character.has("damaged_values"):
		character["damaged_values"] = keep
	if unit != null:
		for cleared in held_cleared:
			_reduce_hold(unit, cleared.value, "__damage:" + cleared.source, cleared.amount)
	return removed


## Lower the hold (value, source_id) on `unit` by `by`, removing it when it
## reaches 0, then refresh whatever is derived from `value`.
static func _reduce_hold(unit: Node, value: String, source_id: String, by: float) -> void:
	if unit == null or not "effect_holds" in unit or by <= 0.0:
		return
	for i in range(unit.effect_holds.size() - 1, -1, -1):
		var hold: Dictionary = unit.effect_holds[i]
		if hold.value != value or str(hold.source_id) != source_id:
			continue
		var left: float = float(hold.amount) - by
		if left <= 0.0:
			unit.effect_holds.remove_at(i)
		else:
			hold["amount"] = left
	_after_change(unit, [value])


## A `restore` on a unit that keeps no damaged_values (an enemy): its
## `damage`-mode losses are only "__damage:<source>" drain holds, so lower
## those on `value` by up to `amount` in total, oldest first. Returns how much
## was restored.
static func reduce_damage_holds(unit: Node, value: String, amount: float) -> float:
	if unit == null or not "effect_holds" in unit or amount <= 0.0:
		return 0.0
	var budget: float = amount
	for hold in holds_on(unit, value):
		if budget <= 0.0:
			break
		var source_id: String = str(hold.source_id)
		if not source_id.begins_with("__damage:") or hold.mode != "drain":
			continue
		var taken: float = minf(float(hold.amount), budget)
		budget -= taken
		_reduce_hold(unit, value, source_id, taken)
	return amount - budget


## True for a player-team unit whose character is in the party: the case where
## `damage` mode writes a persistent entry and a heal may clear one.
static func is_party_unit(unit: Node) -> bool:
	return _is_party_unit(unit)


## Does `entry` say that `kind` with `detail` heals it?
static func _entry_cleared_by(entry: Dictionary, kind: String, detail: Dictionary) -> bool:
	var clauses: Array = entry.get("cleared_by", [])
	if clauses.is_empty():
		clauses = [{"rest": "full"}, {"restore": str(entry.get("value", ""))}]
	for clause in clauses:
		if not clause.has(kind):
			continue
		var want = clause[kind]
		match kind:
			"rest":
				if int(detail.get("tier", 0)) >= int(_REST_TIER.get(str(want), 99)):
					return true
			"heal":
				var rule: Dictionary = want if want is Dictionary else {}
				var schools = detail.get("school", "")
				var school_ok: bool = not rule.has("school") \
					or (schools is Array and rule["school"] in schools) \
					or str(schools) == str(rule["school"])
				if school_ok and int(detail.get("level", 0)) >= int(rule.get("min_level", 0)):
					return true
			"restore":
				if str(want) == str(detail.get("value", "")):
					return true
	return false


## True for a player-team unit whose character is in the party.
static func _is_party_unit(unit: Node) -> bool:
	if unit == null or not "character_data" in unit or unit.team != CombatManager.Team.PLAYER:
		return false
	for member in CharacterSystem.get_party():
		if is_same(member, unit.character_data):
			return true
	return false
