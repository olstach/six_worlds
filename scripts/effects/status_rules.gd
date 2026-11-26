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
static func has_flag(unit: Node, flag: String) -> bool:
	if unit == null or not "status_effects" in unit:
		return false
	for entry in unit.status_effects:
		var def: Dictionary = CombatManager._status_effects.get(str(entry.get("status", "")), {})
		if flag in def.get("flags", []):
			return true
	return false


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
