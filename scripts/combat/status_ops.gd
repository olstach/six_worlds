class_name StatusOps
## Reaching into a unit's list of statuses and changing what is on it.
##
## Dispel and cleanse are the obvious cases, but they are two points on a wider
## surface: a spell that strips an enemy's blessings and wears them itself, a
## fire mage who lifts the burning off her allies and hands it to the people who
## set it, a flash that spends every debuff on you as a bolt of light. Those are
## all the same operation — SELECT some statuses, then do something with them —
## and each had been written as its own unread `special` key.
##
## THE BUG THIS REPLACES. `statuses_removed` is a list of what to remove, and
## the combat reader used only its LENGTH:
##
##     var cleansed = _cleanse_status_effects(target, statuses_removed.size())
##
## So `cooling_mist: ["Burning"]` removed one arbitrary debuff rather than the
## burning, `freedom: ["Rooted","Slowed","Held",...]` removed four arbitrary
## debuffs, and — worst — `cleanse: ["all_negative"]` removed exactly
## ONE, because the list has one element in it. Four spells promising to remove
## everything removed one thing each.
##
## The overworld path in main_menu.gd read the same field correctly the whole
## time, matching names and honouring `all_negative`. So the same spell behaved
## one way on the map and another in a fight.

## What can be done with a selection.
const OPS: Array[String] = [
	"remove",    # take them off
	"steal",     # take them off one unit and put them on another
	"transfer",  # move them from one unit to another, keeping stack counts
	"convert",   # spend them for something else — damage, healing
]

## Named groups a selector may ask for, alongside or instead of literal names.
const TAGS: Array[String] = [
	"all_negative",     # every dispellable debuff
	"negative",         # the same thing; both spellings appear in the data
	"positive",         # every buff
	"mental_negative",  # the mind-affecting debuffs
	"magical",          # buffs and debuffs alike, which is what a true dispel is
]

## The mind-affecting debuffs. There is no "mental" category in statuses.json —
## they all sit under `cc` — so the group has to be named somewhere, and naming
## it here beats spelling it out in each of the spells that wants it.
const MENTAL_STATUSES: Array[String] = [
	"Confused", "Feared", "Charmed", "Berserk", "Forgetful", "Dominated",
	"Chaotic", "Gloomy", "Terrified", "Despairing",
]


static func is_op(op: String) -> bool:
	return op in OPS


static func is_tag(tag: String) -> bool:
	return tag in TAGS


static func explain_unknown_op(op: String) -> String:
	return ("'%s' is not in StatusOps.OPS, so nothing performs it; the spell "
		+ "would report success and change no statuses") % op


static func explain_unknown_tag(tag: String) -> String:
	return ("'%s' is neither a status name nor a StatusOps.TAGS group, so it "
		+ "selects nothing") % tag


## Does one status entry match this selector?
##
## `defs` is CombatManager's status definition table, which carries the type and
## the dispellable flag. A selector with neither `names` nor `tag` matches
## nothing, deliberately — an empty selector that matched everything would make
## a typo catastrophic rather than inert.
static func matches(entry: Dictionary, selector: Dictionary, defs: Dictionary) -> bool:
	var name: String = entry.get("status", "")
	if name == "":
		return false
	var def: Dictionary = defs.get(name, {})
	var kind: String = def.get("type", "")
	var dispellable: bool = bool(def.get("dispellable", false))

	for wanted in selector.get("names", []):
		if name.to_lower() == str(wanted).to_lower():
			return true

	var tag: String = selector.get("tag", "")
	match tag:
		"all_negative", "negative":
			return kind == "debuff" and dispellable
		"positive":
			return kind == "buff" and dispellable
		"mental_negative":
			return kind == "debuff" and dispellable and name in MENTAL_STATUSES
		"magical":
			# A dispel does not care whose side an effect is on.
			return dispellable
	return false


## Every status entry on `unit` this selector picks, newest first so that
## `count` takes the most recently applied — a shield you just raised goes
## before the one that has been ticking for three turns.
##
## Returns the entries themselves, which are the live dictionaries inside
## `unit.status_effects`, so a caller can read a stolen buff's remaining
## duration before removing it.
static func select(unit: Node, selector: Dictionary, defs: Dictionary) -> Array:
	var picked: Array = []
	if unit == null or not "status_effects" in unit:
		return picked
	for i in range(unit.status_effects.size() - 1, -1, -1):
		var entry: Dictionary = unit.status_effects[i]
		if matches(entry, selector, defs):
			picked.append(entry)
	var cap: int = int(selector.get("count", 0))
	if cap > 0 and picked.size() > cap:
		picked = picked.slice(0, cap)
	return picked


## Resolve the older `statuses_removed` shorthand into a selector.
##
## The field mixes literal status names with group tags in one list, which is
## why it was easy to misread. `["Burning"]` is a name; `["all_negative"]` is a
## group; `["Rooted","Slowed","Held"]` is three names. Crucially the LENGTH
## means nothing — three names is not "remove three things", it is "remove these
## three if present".
static func selector_from_removed_list(removed: Array) -> Dictionary:
	var names: Array[String] = []
	var tag: String = ""
	for entry in removed:
		var text := str(entry)
		if is_tag(text):
			# A group tag wins: "all_negative" alongside names still means all.
			tag = text
		else:
			names.append(text)
	var selector: Dictionary = {}
	if not names.is_empty():
		selector["names"] = names
	if tag != "":
		selector["tag"] = tag
	return selector
