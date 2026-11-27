class_name StatusRules
extends RefCounted
## Small questions about the statuses a unit carries, asked from many places:
## "does anything on this unit say it can't be stunned?", "which categories is
## this status?", "give me a fresh id for a new status entry".
##
## A status ENTRY is one dictionary in `unit.status_effects`:
##   {"id": "status:12", "status": "Frozen", "duration": 2, "value": 0, ...}
## Its DEFINITION is the statuses.json entry of that name, which
## CombatManager keeps in `_status_effects`. These functions read both.
##
## The id names the entry everywhere it leaves a mark: the stat holds its
## `while_active` effects place (ValuePaths) carry it as their source, so
## ending the entry can release exactly what it gave and nothing else.


## The counter behind new_instance_id(). It only ever goes up, so an id is
## never handed out twice while the game runs (unique within any one combat,
## as the plan requires, and across combats too).
static var _next_id: int = 0


## A fresh status instance id, "status:<n>".
static func new_instance_id() -> String:
	_next_id += 1
	return "status:%d" % _next_id


## Give every entry in `entries` that has no id one. Used on load: a save made
## before entries had ids still works. Returns how many ids were handed out.
static func ensure_ids(entries: Array) -> int:
	var given: int = 0
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == "":
			entry["id"] = new_instance_id()
			given += 1
	return given


## The status's `categories` as a typed list ("control", "curse",
## "elemental.water" ...). A definition still in the old shape has none.
static func categories_of(def: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for c in def.get("categories", []):
		out.append(str(c))
	return out


## True when any status active on `unit` lists `flag` in its `flags`.
## A flag is a yes/no rule a status switches on ("cannot_move",
## "breaks_concentration"); the code that enforces the rule asks this.
static func has_flag(unit: Node, flag: String) -> bool:
	return not entry_with_flag(unit, flag).is_empty()


## True when any status active on `unit` lists at least one of `flags`.
static func has_any_flag(unit: Node, flags: Array) -> bool:
	for flag in flags:
		if has_flag(unit, str(flag)):
			return true
	return false


## True when the status DEFINITION `def` lists `flag`. For code that walks a
## unit's statuses itself (it needs the entry too) or has just a definition.
static func def_has_flag(def: Dictionary, flag: String) -> bool:
	return flag in def.get("flags", [])


## True when the definition `def` lists at least one of `flags`.
static func def_has_any_flag(def: Dictionary, flags: Array) -> bool:
	for flag in flags:
		if def_has_flag(def, str(flag)):
			return true
	return false


## The first entry in `unit.status_effects` whose status lists `flag`, or an
## empty dictionary. For rules that need the entry as well as the answer: who
## cast it (`source`), or its `value` (a shield's pool, a copy count).
static func entry_with_flag(unit: Node, flag: String) -> Dictionary:
	if unit == null or not "status_effects" in unit:
		return {}
	for entry in unit.status_effects:
		var def: Dictionary = CombatManager._status_effects.get(str(entry.get("status", "")), {})
		if def_has_flag(def, flag):
			return entry
	return {}


## Every entry whose status lists `flag` (a copy of the list, so removing
## them while walking it is safe).
static func entries_with_flag(unit: Node, flag: String) -> Array:
	var found: Array = []
	if unit == null or not "status_effects" in unit:
		return found
	for entry in unit.status_effects:
		var def: Dictionary = CombatManager._status_effects.get(str(entry.get("status", "")), {})
		if def_has_flag(def, flag):
			found.append(entry)
	return found


## True when something active on `unit` makes it immune to the status
## `status_name` (whose definition is `def`). An `immune:<word>` flag matches
## when the word is the status's name (any letter case), one of its
## categories, or its polarity:
##   immune:Frozen     only Frozen
##   immune:control    every status in the control category
##   immune:negative   every negative status
static func immune_to(unit: Node, status_name: String, def: Dictionary) -> bool:
	if unit == null or not "status_effects" in unit:
		return false
	var cats: Array[String] = categories_of(def)
	var polarity: String = str(def.get("polarity", ""))
	for entry in unit.status_effects:
		var carried: Dictionary = CombatManager._status_effects.get(str(entry.get("status", "")), {})
		for f in carried.get("flags", []):
			var flag: String = str(f)
			if not flag.begins_with(EffectVocab.IMMUNE_FLAG_PREFIX):
				continue
			var word: String = flag.trim_prefix(EffectVocab.IMMUNE_FLAG_PREFIX)
			if word.to_lower() == status_name.to_lower() or word in cats \
					or (polarity != "" and word == polarity):
				return true
	return false


## The first `damage` effect of the status's `periodic` list (its damage over
## time), or {} when it deals none.
static func periodic_damage(def: Dictionary) -> Dictionary:
	for effect in def.get("periodic", {}).get("effects", []):
		if typeof(effect) == TYPE_DICTIONARY and str(effect.get("op", "")) == "damage":
			return effect
	return {}


## How much a status's damage over time ticks for when nothing else says:
## its plain `amount`, or the `default` of a borrowed one
## ({"from": "status.value", "default": 5} ticks 5 unless the spell gave it a
## value). `fallback` when it deals none. The overworld, which has no spell
## value to borrow, ticks this.
static func periodic_damage_base(def: Dictionary, fallback: int) -> int:
	var dot: Dictionary = periodic_damage(def)
	if dot.is_empty():
		return fallback
	var amount = dot.get("amount", fallback)
	if typeof(amount) == TYPE_DICTIONARY:
		return int(amount.get("default", amount.get("base", fallback)))
	return int(amount)
