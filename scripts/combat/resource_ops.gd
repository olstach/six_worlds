class_name ResourceOps
## Moving health, mana and stamina around — draining, restoring, transferring.
##
## Mana Drain is the spell that wanted this: 135 mana to take a caster's mana
## and keep it. But the operation is not about mana and it is not about spells.
## A vampiric weapon drains health. A restorative meal returns stamina. A
## karmic bond shares healing between two people. An event can leave the party
## exhausted. All of them are "take some quantity of a resource off one person,
## optionally give it to another", and each had been written as its own branch.
##
## So the vocabulary lives here and the three resources are named once, because
## the alternative is what this codebase keeps finding: `healing_bonus_pct`
## written where `healing_pct` was read, and nothing failing.
##
## HOW MUCH is its own small language. A flat number is the common case, but a
## drain that matters against a big target wants a percentage, and a spell that
## rewards a specialist wants a spellpower term. All three compose.

## The three pools a unit carries. Each names the pair of fields that hold it.
const RESOURCES: Dictionary = {
	"hp":      {"current": "current_hp",      "max": "max_hp"},
	"mana":    {"current": "current_mana",    "max": "max_mana"},
	"stamina": {"current": "current_stamina", "max": "max_stamina"},
}

## What can be done with an amount.
const MODES: Array[String] = [
	"drain",     # take it away, and it is gone
	"restore",   # give it, capped at the maximum
	"transfer",  # take it from one and give it to another, nothing lost
]


static func is_resource(resource: String) -> bool:
	return RESOURCES.has(resource)


static func is_mode(mode: String) -> bool:
	return mode in MODES


static func explain_unknown_resource(resource: String) -> String:
	return ("'%s' is not in ResourceOps.RESOURCES, so nothing moves; the effect "
		+ "would report success and change no pool") % resource


static func explain_unknown_mode(mode: String) -> String:
	return "'%s' is not in ResourceOps.MODES, so nothing performs it" % mode


static func current(unit: Node, resource: String) -> int:
	if unit == null or not is_resource(resource):
		return 0
	var field: String = RESOURCES[resource]["current"]
	return int(unit.get(field)) if field in unit else 0


static func maximum(unit: Node, resource: String) -> int:
	if unit == null or not is_resource(resource):
		return 0
	var field: String = RESOURCES[resource]["max"]
	return int(unit.get(field)) if field in unit else 0


## Write a pool back, clamped to [0, max]. Also syncs `derived`, because a
## character's sheet is what survives the fight — a mana drain that only moved
## the combat unit's field would refill for free at the end of combat.
static func set_current(unit: Node, resource: String, value: int) -> void:
	if unit == null or not is_resource(resource):
		return
	var field: String = RESOURCES[resource]["current"]
	if not field in unit:
		return
	var clamped: int = clampi(value, 0, maximum(unit, resource))
	unit.set(field, clamped)
	if "character_data" in unit and unit.character_data is Dictionary:
		var derived: Dictionary = unit.character_data.get("derived", {})
		if not derived.is_empty():
			derived[field] = clamped


## How much this spec moves.
##
##   {"flat": 20}
##   {"pct_of_max": 40}          40% of the SUBJECT's maximum
##   {"pct_of_current": 50}      half of what they have left
##   {"per_spellpower": 1.5}     scaled by the source's spellpower
##
## Terms compose, so a drain can be "20 plus a third of what they are carrying".
## `subject` is whoever the percentage is measured against — the victim for a
## drain, which is what makes draining a full caster worth more than draining a
## spent one.
static func amount_for(spec: Dictionary, resource: String, subject: Node,
		source: Node = null) -> int:
	var total := 0.0
	total += float(spec.get("flat", 0))
	if spec.has("pct_of_max"):
		total += maximum(subject, resource) * float(spec["pct_of_max"]) / 100.0
	if spec.has("pct_of_current"):
		total += current(subject, resource) * float(spec["pct_of_current"]) / 100.0
	if spec.has("per_spellpower") and source != null and source.has_method("get_spellpower"):
		total += source.get_spellpower() * float(spec["per_spellpower"])
	return maxi(0, int(total))


## Take `amount` off a unit and report how much was actually there to take.
##
## The returned figure is what a transfer hands on: draining 80 mana from
## someone carrying 30 moves 30, not 80, or the operation would create mana out
## of an empty pool.
static func drain(unit: Node, resource: String, amount: int) -> int:
	var have: int = current(unit, resource)
	var taken: int = mini(maxi(0, amount), have)
	set_current(unit, resource, have - taken)
	return taken


## Give `amount` to a unit, capped at their maximum, and report how much landed.
static func restore(unit: Node, resource: String, amount: int) -> int:
	var have: int = current(unit, resource)
	var room: int = maxi(0, maximum(unit, resource) - have)
	var given: int = mini(maxi(0, amount), room)
	set_current(unit, resource, have + given)
	return given
