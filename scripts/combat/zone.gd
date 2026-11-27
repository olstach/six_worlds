class_name Zone
## An area that does something to whoever is in it — anchored to the ground
## rather than to a body.
##
## A ZONE IS AN AURA WITH A PLACE INSTEAD OF A BODY. What it does is written
## in the shared effect language (the same as auras, spells and statuses), in
## lists named for when they happen, and CombatManager runs them through
## EffectResolver with the zone's owner as the caster and the zone tile as the
## position. A `modify` in `while_inside` is read-time, exactly like an aura's:
## AuraSystem.contributions() adds it up wherever the number is read.
## EffectVocab.validate_zone checks every definition.
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

## When a zone's effects happen.
const TRIGGERS: Array[String] = [
	"while_inside",       # modifies: read while standing in it; the rest each round
	"on_enter",           # once, to a unit that steps in
	"turn_start_inside",  # at the start of the turn of a unit standing in it
	"turn_end_inside",    # at the end of the turn of a unit standing in it
	"on_death_inside",    # when a unit dies on its ground
]

## Who a zone reaches (its `affects`). An effect's own `to` overrides it — see
## effect_reaches().
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


## The `affects` word a zone effect's `to` stands for.
const _AFFECTS_FOR_TO: Dictionary = {
	"allies_in_area": "allies", "enemies_in_area": "enemies", "all_in_area": "all",
}


## Does this effect reach `unit`, given who placed the zone?
##
## The effect's own `to` wins over the zone's `affects`, because a zone often
## wants both at once — the vajra mandala shelters allies standing in it and
## hurts enemies that step into it, which is one zone with two audiences.
## Allies and enemies are judged by the owner's team; a zone with no owner has
## no allies, so "enemies" reaches everyone.
static func effect_reaches(effect: Dictionary, zone: Dictionary, source: Node,
		unit: Node) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	var who: String = str(_AFFECTS_FOR_TO.get(str(effect.get("to", "")),
		zone.get("affects", "all")))
	if who == "all":
		return true
	var same_team: bool = source != null and is_instance_valid(source) \
		and ("team" in source) and ("team" in unit) and source.team == unit.team
	return same_team if who == "allies" else not same_team
