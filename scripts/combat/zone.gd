class_name Zone
## An area that does something to whoever is in it — anchored to the ground
## rather than to a body.
##
## A ZONE IS AN AURA WITH A PLACE INSTEAD OF A BODY. That is the whole design,
## and it is why this file is short. `AuraSystem` already answers "what does an
## area do to whoever is inside it": grant a status, heal, damage, shift a stat,
## change damage taken, on a chance or behind a saving throw. Every one of those
## payloads is equally meaningful attached to a set of tiles, so zones reuse the
## same vocabulary and CombatManager applies them through the same function.
##
## Growing a second payload list would have been the mistake. This codebase has
## spent weeks finding places where one idea was written twice and the copies
## drifted — `statuses_removed` read by length in combat and by name on the map,
## five separate aura implementations, two tables of terrain keyed on bare
## integers. One payload vocabulary with two anchors is the alternative.
##
## WHAT A ZONE HAS THAT AN AURA DOES NOT.
##
##   * Tiles, rather than a centre and a radius. The footprint comes from the
##     spell's own `aoe` block, so every shape AoEResolver knows is available.
##   * A duration of its own, ticking down whether or not anyone is standing
##     in it.
##   * Triggers. An aura only ever asks "who is near me now"; a zone can also
##     answer "who just walked in" and "who died here".
##   * Drift. A tornado is a zone that will not stay put.

## When a zone's payloads fire.
const TRIGGERS: Array[String] = [
	"while_inside",     # each round, to everyone standing in it
	"on_enter",         # once, to a unit that steps in
	"on_death_inside",  # when a unit dies on its ground
]

## Who a zone or one of its payloads reaches. Same words as an aura's, because
## it is the same question.
const AFFECTS: Array[String] = ["allies", "enemies", "all"]

## How a zone moves, if it moves.
const DRIFTS: Array[String] = ["", "random"]

## A zone may be one end of a pair. Stepping into one end puts you out of the
## other, which is the whole of what a gate is — and the reason zones needed a
## way to know about each other at all. `vajra_gate` wanted this and was
## deferred when zones were built; The Door Stands Open wants the same thing.
const PAIR_ROLES: Array[String] = ["", "gate"]

## A zone may be a TRAP: something hidden, which somebody with the training may
## notice and step around. Thievery's `trap_detection_pct` had been written into
## derived stats for months and read by nothing, because until Trap Maker there
## were no traps to detect.
const TRAP_FIELD := "trap"

const DATA_PATH := "res://resources/data/zones.json"

static var _definitions: Dictionary = {}
static var _loaded: bool = false


static func definitions() -> Dictionary:
	if _loaded:
		return _definitions
	_loaded = true
	_definitions = {}
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("Zone: cannot open %s" % DATA_PATH)
		return _definitions
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Zone: %s is not a JSON object" % DATA_PATH)
		return _definitions
	for id in parsed.get("zones", {}):
		if id.begins_with("_"):
			continue
		_definitions[id] = parsed["zones"][id]
	return _definitions


static func get_definition(zone_id: String) -> Dictionary:
	return definitions().get(zone_id, {})


static func exists(zone_id: String) -> bool:
	return definitions().has(zone_id)


static func reload() -> void:
	_loaded = false
	_definitions = {}


static func is_trigger(name: String) -> bool:
	return name in TRIGGERS


static func is_affects(name: String) -> bool:
	return name in AFFECTS


static func explain_unknown_trigger(name: String) -> String:
	return ("'%s' is not in Zone.TRIGGERS, so nothing fires it; the zone would "
		+ "sit on the ground doing nothing") % name


## Does this payload reach `unit`, given who placed the zone?
##
## The `affects` on a payload wins over the zone's, because a zone often wants
## both at once — the vajra mandala shelters allies standing in it and hurts
## enemies that step into it, which is one zone with two audiences.
static func reaches(payload: Dictionary, zone: Dictionary, source: Node,
		unit: Node) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	var who: String = str(payload.get("affects", zone.get("affects", "all")))
	if who == "all":
		return true
	var same_team: bool = source != null and ("team" in source) and ("team" in unit) \
		and source.team == unit.team
	return same_team if who == "allies" else not same_team
