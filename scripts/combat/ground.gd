class_name Ground
## The one terrain vocabulary, shared by the overworld map and the battle grid.
##
## These were two systems that shared no words. The overworld had fourteen
## `Terrain` types carrying a speed and a passability; the battle grid had
## `TileType`, `TerrainEffect`, `ObstacleType` and a height, and nothing was
## named the same thing in either. The two collisions were false friends:
## overworld WATER was impassable ground while battle WATER was a tile you
## wade through, and overworld ICE was fast ground while battle ICE was a
## hazard sitting on top of one.
##
## So a battle tile could not answer "what kind of ground is this" — only
## whether it could be walked, blocked or fallen into, which is a movement
## question rather than a place. That is the gap this closes: a battle tile now
## carries a GROUND drawn from the same fourteen names, and `TileType` goes
## back to being what it actually is.
##
## THE MAPPING LIVES IN DATA. What a block of forest becomes on a battlefield
## used to be a `match` on bare integers with the name in a comment — in two
## separate tables, so reordering the enum would have silently remapped every
## battlefield and every summon bonus with nothing able to notice. It is
## resources/data/terrain.json now, where validate_data.py can check it and
## where adding a terrain means adding a row.

const DATA_PATH := "res://resources/data/terrain.json"

## Battle tile types a terrain may default its tiles to. These are the names
## of CombatGrid.TileType values; the grid owns the enum, this owns the word.
const TILE_TYPES: Array[String] = ["floor", "wall", "pit", "water", "difficult"]

## Hazards a terrain may sprinkle. Names of CombatGrid.TerrainEffect values.
const HAZARDS: Array[String] = [
	"none", "fire", "ice", "poison", "acid", "blessed", "cursed", "wet",
	"stormy", "void", "smoke",
]

## Cover objects a terrain may scatter. Names of CombatGrid.ObstacleType values.
const OBSTACLES: Array[String] = [
	"tree", "rock", "pillar", "barricade", "fallen_tree",
]

static var _by_key: Dictionary = {}
static var _by_id: Dictionary = {}
static var _loaded: bool = false


## Every terrain, keyed by its lower-case name ("forest").
static func all() -> Dictionary:
	_load()
	return _by_key


## One terrain by the numeric id saved maps store, or {} if unknown.
##
## The id is the contract with MapManager.Terrain and with every saved game, so
## it is the id rather than the name that must never be renumbered.
static func by_id(id: int) -> Dictionary:
	_load()
	return _by_id.get(id, {})


static func by_key(key: String) -> Dictionary:
	_load()
	return _by_key.get(key, {})


## Movement speed multiplier. Negative means impassable without an ability.
static func speed_of(id: int) -> float:
	return float(by_id(id).get("speed", 1.0))


## The movement ability that opens this terrain when it is otherwise
## impassable, or "" when none does.
static func ability_for(id: int) -> String:
	return str(by_id(id).get("ability", ""))


static func name_of(id: int) -> String:
	return str(by_id(id).get("name", "Unknown"))


static func description_of(id: int) -> String:
	return str(by_id(id).get("description", ""))


## What a block of this ground becomes on a battlefield: its default tile type,
## its height, the obstacles it scatters and the hazard it carries.
static func battle_of(id: int) -> Dictionary:
	return by_id(id).get("battle", {})


## How high this ground may rise, in height levels. A ceiling, not a value —
## see `_comment_relief` in terrain.json.
static func relief_of(id: int) -> int:
	return int(battle_of(id).get("relief", 0))


## What a Summoning spell draws on when the fight is on this ground:
## {school, label}, or {} where the ground has no spirits of its own.
static func summon_affinity_of(id: int) -> Dictionary:
	return by_id(id).get("summon_affinity", {})


static func is_tile_type(name: String) -> bool:
	return name in TILE_TYPES


static func is_hazard(name: String) -> bool:
	return name in HAZARDS


static func is_obstacle(name: String) -> bool:
	return name in OBSTACLES


## Discard the cache so a test can reload edited data.
static func reload() -> void:
	_loaded = false
	_by_key = {}
	_by_id = {}


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("Ground: cannot open %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Ground: %s is not a JSON object" % DATA_PATH)
		return
	for key in parsed.get("terrain", {}):
		if key.begins_with("_"):
			continue   # `_comment_*` keys are documentation, not data
		var entry: Dictionary = parsed["terrain"][key]
		_by_key[key] = entry
		_by_id[int(entry.get("id", -1))] = entry
