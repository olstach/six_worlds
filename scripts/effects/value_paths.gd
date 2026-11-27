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
## stat getters pass their finished number through apply_to(), which is where
## holds take effect (get_attack_damage splits it into flat_sum() and
## apply_scaling() around its damage_pct). With no holds and no aura or zone
## reaching the unit, apply_to() returns its input unchanged. Resistance reads `resist.` holds itself: a fortify or
## drain is one contribution in Resistance._gather(), a set is applied last.
##
## ORDER OF APPLICATION in apply_to():
##   1. base + (sum of fortify) - (sum of drain)
##   2. times the product of every multiply
##   3. the LAST-ADDED `set` replaces the result, if any set exists
##
## GROUP TARGETS (`skills.element.<element>`, `skills.magic|combat|general`,
## `attributes.all`) are not values of their own: add_hold() expands one into a
## hold per member, all under the same source id, so one release() removes the
## lot. expand() lists the members.
##
## `affinity.<element>` is held on the unit like a stat and read by
## PerkSystem.calculate_element_affinity (see there); `pressure.<element>` is
## instant and has no hold at all (EffectResolver pushes it to PsychologySystem).
##
## Stage 1 wires `stat.`, `resist.`, `attribute.` and `skill.`. Holds take
## fortify and drain there; the persistent `damage` mode and its `restore` have
## their own homes, apply_damage_mode() and clear_damage(), further down.
##
## `attribute.` and `skill.` holds live ON THE CHARACTER, so every reader of an
## attribute or skill level sees them, not just the combat getters:
##   attribute. holds are summed into character_data["attribute_bonuses"][attr]["effects"]
##   skill.     holds are summed into character_data["skill_bonuses"][skill]["effects"]
## CharacterSystem.get_effective_attribute / get_effective_skill_level add
## those up. After any such change refresh_character() recomputes the unit's
## derived stats (per-level skill bonuses included) mid-fight.

## Key under skill_bonuses[skill] / attribute_bonuses[attr] holding the summed holds.
const SKILL_EFFECTS_KEY: String = "effects"
## The resource maxima refresh_character() carries from derived to the unit.
const _MAX_TERMS: Array[String] = ["hp", "mana", "stamina"]


## Give `unit` a hold on `value`. A second hold with the same (value, source_id)
## replaces the first rather than stacking, so re-applying a buff refreshes it.
## A bad value path or a mode the namespace does not allow is a loud error.
static func add_hold(unit: Node, value: String, mode: String, amount: float,
		source_id: String) -> void:
	if not EffectVocab.is_value_path(value):
		push_error("ValuePaths.add_hold: unknown value path '%s'" % value)
		return
	var namespace_name: String = value.get_slice(".", 0)
	if namespace_name == "pressure":
		push_error("ValuePaths.add_hold: pressure is instant and keeps no hold")
		return
	var allowed: Array = EffectVocab.MODES_BY_NAMESPACE.get(namespace_name, [])
	if not mode in allowed:
		push_error("ValuePaths.add_hold: mode '%s' is not allowed for '%s' (allowed: %s)"
			% [mode, value, allowed])
		return
	# `damage` and `restore` on attribute./skill. are not holds: they live on the
	# character and are handled by apply_damage_mode() / clear_damage().
	if mode in ["damage", "restore"] and namespace_name in ["attribute", "skill", "skills", "attributes"]:
		push_error("ValuePaths.add_hold: mode '%s' on '%s' is not a hold; use apply_damage_mode() or clear_damage()"
			% [mode, value])
		return
	if not "effect_holds" in unit:
		push_error("ValuePaths.add_hold: %s has no effect_holds" % unit)
		return
	# A group is one hold per member under the one source id.
	var members: Array[String] = expand(value)
	for member in members:
		_remove(unit, member, source_id)
		# Appended last, so a later `set` beats an earlier one.
		unit.effect_holds.append({"value": member, "mode": mode, "amount": amount,
			"source_id": source_id})
	_after_change(unit, members)


## The values a path stands for: a group path lists its members
## ("attributes.all" -> the seven "attribute.x"; "skills.element.fire" -> the
## fire "skill.x"; "skills.magic" -> every magic-category skill), any other
## path lists itself.
static func expand(value: String) -> Array[String]:
	var out: Array[String] = []
	var parts: PackedStringArray = value.split(".")
	if parts[0] == "attributes" and parts.size() == 2:
		for attr in EffectVocab.ATTRIBUTES:
			out.append("attribute." + attr)
	elif parts[0] == "skills" and parts.size() == 3 and parts[1] == "element":
		for skill_id in PerkSystem.get_skills_in_element(parts[2]):
			out.append("skill." + skill_id)
	elif parts[0] == "skills" and parts.size() == 2:
		for skill_id in PerkSystem.get_skills_in_category(parts[1]):
			out.append("skill." + skill_id)
	else:
		out.append(value)
	return out


## The combat unit whose sheet IS `character` (the very same dictionary), or
## null when it is not in a fight. Holds live on units, so a reader that has
## only a sheet (PerkSystem.calculate_element_affinity) finds its holder here.
static func unit_of(character: Dictionary) -> Node:
	if CombatManager == null:
		return null
	for unit in CombatManager.all_units:
		if is_instance_valid(unit) and "character_data" in unit \
				and is_same(unit.character_data, character):
			return unit
	return null


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


## Drop every hold on `unit` and put everything they touched back: the
## attribute_bonuses / skill_bonuses "effects" keys, the derived stats and the
## unit's max_* fields. Called when a fight ends. In stage 1 every hold is
## combat-scoped; a `persistent` scope arrives with statuses in stage 2.
static func release_all_combat(unit: Node) -> void:
	if unit == null or not "effect_holds" in unit:
		return
	# Note every attribute. / skill. value that had holds, so its "effects"
	# key can be erased below, and stat.max_hp, whose stored bonus must go too.
	var touched: Array[String] = []
	for hold in unit.effect_holds:
		var v: String = str(hold.value)
		if (v.begins_with("attribute.") or v.begins_with("skill.") or v.begins_with("affinity.")
				or v == "stat.max_hp") \
				and not v in touched:
			touched.append(v)
	unit.effect_holds.clear()
	# The holds that carried persistent damage are gone: let the entries count.
	if "character_data" in unit:
		for entry in unit.character_data.get("damaged_values", []):
			entry.erase("held")
	# No holds are left, so this erases each "effects" key and refreshes the
	# character once.
	_after_change(unit, touched)


## `base` after every hold on `value` has been applied (see the order above).
## Called from hot getters, so the no-holds case returns at once.
## Auras and zones count here too, without storing anything: flat_sum() and
## apply_scaling() add what AuraSystem.contributions() finds reaching the unit
## right now (their read-time modifies), so a unit that walks out of an aura
## simply stops finding it.
static func apply_to(unit: Node, value: String, base: float) -> float:
	if unit == null:
		return base
	return apply_scaling(unit, value, base + flat_sum(unit, value))


## Step 1 alone: the sum of the fortify holds on `value` minus the drains.
## For a getter that must add the flat part BEFORE a multiplier of its own —
## get_attack_damage() adds it before the fire-affinity damage_pct, as the
## status damage bonuses always were — and then calls apply_scaling().
## Includes the auras' and zones' fortify / drain on `value` (AuraSystem.flat_total).
static func flat_sum(unit: Node, value: String) -> float:
	if unit == null:
		return 0.0
	var sum: float = AuraSystem.flat_total(unit, value)
	if not "effect_holds" in unit:
		return sum
	for hold in unit.effect_holds:
		if hold.value != value:
			continue
		match str(hold.mode):
			"fortify": sum += float(hold.amount)
			"drain": sum -= float(hold.amount)
	return sum


## Steps 2 and 3 alone: `base` times every multiply on `value`, then the
## last-added `set` if there is one. Fortify and drain are NOT applied here.
## The auras' and zones' multiplies count with the holds' (AuraSystem.factor);
## a `set` hold still replaces everything.
static func apply_scaling(unit: Node, value: String, base: float) -> float:
	if unit == null:
		return base
	var factor: float = AuraSystem.factor(unit, value)
	if not "effect_holds" in unit or unit.effect_holds.is_empty():
		return base * factor
	var has_set: bool = false
	var set_to: float = 0.0
	for hold in unit.effect_holds:
		if hold.value != value:
			continue
		match str(hold.mode):
			"multiply": factor *= float(hold.amount)
			"set":
				has_set = true
				set_to = float(hold.amount)   # later holds overwrite: last-added wins
	if has_set:
		return set_to
	return base * factor


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


## Rewrite character_data["skill_bonuses"][skill]["effects"] from the unit's
## `skill.` holds. A total of zero erases the key (and the skill's entry if it
## ends up empty), so a released hold leaves the dictionary as it was found.
static func _refresh_skill(unit: Node, skill: String) -> void:
	_write_hold_total(unit, "skill_bonuses", "skill.", skill, false)


## The same for `attribute.` holds and character_data["attribute_bonuses"].
## A held `damage` loss ("__damage:<source>" drain) is summed here like any
## drain; its damaged_values entry is marked "held" meanwhile, so
## CharacterSystem counts that loss once, through this key.
static func _refresh_attribute(unit: Node, attr: String) -> void:
	_write_hold_total(unit, "attribute_bonuses", "attribute.", attr, true)


## Sum the fortify/drain holds on `prefix + name` and write the total into
## character_data[bonus_key][name]["effects"], or erase it when the total is 0.
## `drop_empty_dict` also erases character_data[bonus_key] once it is empty
## (attribute_bonuses exists only while something is held; skill_bonuses is a
## standing key of every character and stays).
static func _write_hold_total(unit: Node, bonus_key: String, prefix: String,
		name: String, drop_empty_dict: bool) -> void:
	if not "character_data" in unit:
		return
	var data: Dictionary = unit.character_data
	var total: int = 0
	var value: String = prefix + name
	for hold in unit.effect_holds:
		if hold.value != value:
			continue
		var amount: int = int(round(float(hold.amount)))
		match str(hold.mode):
			"fortify": total += amount
			"drain": total -= amount
	if total != 0:
		if not data.has(bonus_key):
			data[bonus_key] = {}
		if not data[bonus_key].has(name):
			data[bonus_key][name] = {}
		data[bonus_key][name][SKILL_EFFECTS_KEY] = total
		return
	if data.has(bonus_key) and data[bonus_key].has(name):
		data[bonus_key][name].erase(SKILL_EFFECTS_KEY)
		if data[bonus_key][name].is_empty():
			data[bonus_key].erase(name)
	if drop_empty_dict and data.has(bonus_key) and data[bonus_key].is_empty():
		data.erase(bonus_key)


## Recompute `unit`'s derived stats from its character, mid-fight, and carry
## the new maxima onto the unit.
## Every character — party member, companion or enemy — has the same sheet, so
## every one goes through CharacterSystem.update_derived_stats, the one formula
## (per-level skill bonuses, affinity, equipment, perks, wounds...).
## A unit with no sheet at all (no `attributes`: summons and illusions, which
## are not on the sheet yet, see TODO 17) has nothing to derive from and is
## left as it is.
## The unit's max_hp / max_mana / max_stamina move by the CHANGE in the derived
## maxima rather than being overwritten, because auras and statuses also shift
## them in place during a fight. Current HP, mana and stamina are never raised
## (a +Constitution buff gives room to heal, not free HP), only clamped down
## when a maximum shrinks; derived's own current_* values get the same rule,
## since update_derived_stats would otherwise raise them with the maximum.
static func refresh_character(unit: Node) -> void:
	if unit == null or not "character_data" in unit:
		return
	var data: Dictionary = unit.character_data
	if not data.has("attributes"):
		return
	if not data.has("derived"):
		data["derived"] = {}
	var derived: Dictionary = data["derived"]
	var max_before: Dictionary = {}
	var current_before: Dictionary = {}
	for term in _MAX_TERMS:
		if derived.has("max_" + term):
			max_before[term] = int(derived["max_" + term])
		if derived.has("current_" + term):
			current_before[term] = derived["current_" + term]

	CharacterSystem.update_derived_stats(data)

	for term in _MAX_TERMS:
		var max_key: String = "max_" + term
		var current_key: String = "current_" + term
		# derived.current_*: back to what it was, or the new maximum if lower.
		if current_before.has(term):
			derived[current_key] = mini(int(current_before[term]), int(derived.get(max_key, current_before[term])))
		if not max_before.has(term) or not derived.has(max_key):
			continue
		var change: int = int(derived[max_key]) - int(max_before[term])
		if change != 0 and max_key in unit:
			unit.set(max_key, int(unit.get(max_key)) + change)
		# The unit's current value: clamp down only.
		if current_key in unit and max_key in unit \
				and int(unit.get(current_key)) > int(unit.get(max_key)):
			unit.set(current_key, int(unit.get(max_key)))


## After holds on `values` changed, write their totals onto the character and
## refresh the derived stats ONCE, however many values changed together.
static func _after_change(unit: Node, values: Array) -> void:
	var changed: bool = false
	var done: Array[String] = []
	for value in values:
		var v: String = str(value)
		if v in done:
			continue
		done.append(v)
		if v.begins_with("attribute."):
			_refresh_attribute(unit, v.get_slice(".", 1))
			changed = true
		elif v.begins_with("skill."):
			_refresh_skill(unit, v.get_slice(".", 1))
			changed = true
		elif v.begins_with("affinity."):
			# Nothing is written to the sheet: calculate_element_affinity reads
			# the hold. The derived stats the affinity pays out must be redone.
			changed = true
	if changed:
		refresh_character(unit)
	# Max HP is stored on the unit as a delta (CombatManager._refresh_aura_max_hp),
	# so a hold on stat.max_hp has to ask for that refresh to be felt.
	if "stat.max_hp" in done and CombatManager != null:
		CombatManager._refresh_aura_max_hp()


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
## "__damage:<source>" so the loss bites this fight too. While that hold lives
## the entry is marked "held": the loss reaches the character through the
## hold's attribute_bonuses "effects" key, and damaged_total() skips the entry,
## so it is counted once. End of combat releases the hold, clears the mark and
## recomputes the derived stats from the entry, still once. A skill needs no
## hold: get_effective_skill_level reads the entry at once, and the character
## is refreshed so its per-level skill bonuses drop now.
## Anyone else: only the drain hold, which ends with the fight.
static func apply_damage_mode(unit: Node, value: String, amount: float,
		cleared_by: Array, source: String, source_categories: Array = []) -> void:
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
	# What kind of thing caused this harm, so a cleanse of that kind can undo it.
	if not source_categories.is_empty():
		entry["source_categories"] = source_categories.duplicate()
	# An attribute entry is "held" while its combat hold is live: the hold
	# carries the loss, so damaged_total() skips it and update_derived_stats()
	# (which can run mid-fight, e.g. after a wound) does not count it twice.
	# release_all_combat() clears the flag when the hold goes.
	if namespace_name == "attribute":
		entry["held"] = true
	data["damaged_values"].append(entry)
	if namespace_name == "skill":
		refresh_character(unit)
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
				# Validators accept "white_magic" as well as "white"; heal schools
				# are stored bare, so strip the suffix here, the one place.
				var want_school: String = str(rule.get("school", "")).trim_suffix("_magic")
				var school_ok: bool = not rule.has("school") \
					or (schools is Array and want_school in schools) \
					or str(schools) == want_school
				if school_ok and int(detail.get("level", 0)) >= int(rule.get("min_level", 0)):
					return true
			"restore":
				if str(want) == str(detail.get("value", "")):
					return true
			"cleanse":
				# detail.category is the category of a status just removed;
				# the entry remembers its cause's categories when it was made.
				var rule: Dictionary = want if want is Dictionary else {}
				var cats: Array = entry.get("source_categories", [])
				if str(detail.get("category", "")) in cats \
						and str(rule.get("category", "")) == str(detail.get("category", "")):
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
