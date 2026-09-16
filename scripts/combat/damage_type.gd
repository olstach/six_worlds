class_name DamageType
## The one damage-type vocabulary, shared by spells, statuses, zones, auras,
## resistances and every call to CombatManager.apply_damage().
##
## There were three of these and they disagreed. `PHYSICAL_SUBTYPES` in
## CombatUnit knew the three physical subtypes; `MAGIC_DAMAGE_TYPES` in
## CombatManager listed holy, shadow and arcane — dealt by nothing — and
## omitted black and white, which eleven and four spells deal, so the Yoga
## table's magic resistance did not apply to Black or White magic; and the
## `damage_type` field itself was an open string, so five spells dealt `ice`
## while every resistance entry in the game said `cold`. Nothing could notice,
## because a missing resistance key reads as zero resistance.
##
## COMPOUNDS ARE PICKED, NOT SPLIT. A `solar` hit arrives as whichever of
## white and fire the TARGET resists less: as white against something
## fireproof, as fire against something that fears fire. So a mixed type
## cannot be walled off by resisting one half, and choosing one is a decision
## about the target rather than a hedge. Because the answer depends on the
## defender, it is Resistance.concrete_type() that decides and this class only
## says what a compound is made of.

const DATA_PATH := "res://resources/data/damage_types.json"

## Categories a type may belong to. `special` types answer to nothing.
const CATEGORIES: Array[String] = [
	"physical",  # physical and its three subtypes
	"element",   # the five elements, plus ice
	"school",    # white and black
	"bodily",    # poison — not magic, and not force either
	"compound",  # dealt as its components in equal shares
	"random",    # one of `choices`, rolled at the moment of damage
	"special",   # true, sacrifice: resistance and armour do not apply
]

static var _types: Dictionary = {}
static var _other: Dictionary = {}
static var _loaded: bool = false


static func all() -> Dictionary:
	_load()
	return _types


static func get_type(name: String) -> Dictionary:
	_load()
	return _types.get(name, {})


static func exists(name: String) -> bool:
	_load()
	return _types.has(name)


## Resistance keys that are not damage types — `disease`, read by WoundSystem
## as a chance to shrug off an affliction. The validator leaves them alone.
static func is_other_resistance(name: String) -> bool:
	_load()
	return _other.has(name)


static func display_name(name: String) -> String:
	return str(get_type(name).get("name", name.capitalize()))


static func description_of(name: String) -> String:
	return str(get_type(name).get("description", ""))


static func category_of(name: String) -> String:
	return str(get_type(name).get("category", ""))


## Is this type physical — physical itself or one of its subtypes?
static func is_physical(name: String) -> bool:
	return category_of(name) == "physical"


## What the Yoga table's magic resistance applies to.
static func is_magic(name: String) -> bool:
	return bool(get_type(name).get("magic", false))


## The generic type a subtype falls back to when a unit declares no resistance
## of its own — "physical" for slashing, "" for everything else.
static func subtype_of(name: String) -> String:
	return str(get_type(name).get("subtype_of", ""))


static func is_compound(name: String) -> bool:
	return not (get_type(name).get("components", []) as Array).is_empty()


## A type that picks an element each time it lands — the Rainbow spells. Rolled
## here rather than at cast time, so one cast can hit two targets with two
## elements, which is the whole point of the spell.
static func is_random(name: String) -> bool:
	return not (get_type(name).get("choices", []) as Array).is_empty()


## The concrete type a hit of `name` actually arrives as: itself, unless it is
## a random type, in which case one of its choices.
static func concrete(name: String) -> String:
	var choices: Array = get_type(name).get("choices", [])
	if choices.is_empty():
		return name
	return str(choices[randi() % choices.size()])


## Does resistance apply to this type at all?
static func ignores_resistance(name: String) -> bool:
	return bool(get_type(name).get("ignores_resistance", false))


## Does the Armor table's flat reduction apply to this type at all?
static func ignores_armour(name: String) -> bool:
	return bool(get_type(name).get("ignores_armour", false))


## What a compound type is made of, or [] for a simple one.
##
## WHICH component arrives is not decided here: it is whichever the DEFENDER
## resists least, and this class has no defender. See Resistance.concrete_type().
## An earlier version split the damage into equal shares and resisted each
## share separately, which needed no defender and made a compound a hedge
## rather than a choice.
static func components_of(name: String) -> Array:
	return get_type(name).get("components", [])


static func explain_unknown(name: String) -> String:
	return ("'%s' is not in damage_types.json, so no resistance key can match " % name
		+ "it and the damage arrives unresisted")


static func reload() -> void:
	_loaded = false
	_types = {}
	_other = {}


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("DamageType: cannot open %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("DamageType: %s is not a JSON object" % DATA_PATH)
		return
	for key in parsed.get("damage_types", {}):
		if key.begins_with("_"):
			continue   # `_comment_*` keys are documentation, not data
		_types[key] = parsed["damage_types"][key]
	for key in parsed.get("other_resistances", {}):
		if key.begins_with("_"):
			continue
		_other[key] = parsed["other_resistances"][key]
