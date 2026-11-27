extends RefCounted
## Measures what every aura and every zone does to the numbers of the units it
## reaches, for the stage-2b Task 8 migration (auras and zones become effect
## lists, and auras become read-time holds).
##
## Shared by tools/capture_aura_baseline.gd (which ran ONCE, before the
## migration, and wrote tools/fixtures/aura_baseline.json) and by
## verify_effects.gd's `aura_numbers_match_baseline` check, which asks the same
## questions of the migrated data and compares. Both must measure the same way,
## so the way lives here. Loaded with preload(); no class_name, because it is a
## test tool, not part of the game.
##
## WHAT IS MEASURED. Only what an aura or zone gives while a unit stands in it
## (the read-time part): the eight stat getters, every resistance (damage types
## and the three afflictions), max HP after the stored refresh, the damage a
## 100-point fire hit and a 100-point physical hit actually do, and the ground's
## mana-cost percentage. Per-turn effects (heals, damage, statuses) are covered
## by verify_auras / verify_spells, which drive the per-turn processor.
##
## WHERE. An aura is put on an emitter (team 0) as an intrinsic aura, and the
## numbers are read on five units: the emitter itself, an ally and an enemy one
## tile away, and an ally and an enemy far outside the radius. A zone is laid
## under an ally and an enemy of its owner, and the numbers are read on them and
## on an ally and an enemy standing off it. The answer is the CHANGE (with the
## aura or zone, minus without), zero changes left out.

const GETTERS: Array[String] = [
	"initiative", "movement", "accuracy", "dodge",
	"damage", "armor", "crit_chance", "spellpower",
]

## The places an aura is read at, and where each stands (the emitter is at
## EMITTER_AT). A radius-99 aura reaches the "far" units too; that is recorded
## like anything else.
const EMITTER_AT := Vector2i(10, 10)
const PLACES: Dictionary = {
	"self": Vector2i(10, 10),
	"ally_near": Vector2i(11, 10),
	"enemy_near": Vector2i(9, 10),
	"ally_far": Vector2i(30, 20),
	"enemy_far": Vector2i(31, 20),
}
const ENEMY_PLACES: Array[String] = ["enemy_near", "enemy_far"]

## Sheet armour every measured unit carries, so a percentage-of-own-armour aura
## (Shield Wall) has something to be a percentage of.
const SHEET_ARMOR: int = 20

## Item auras that override the aura's number (`aura_value`), measured as their
## own rows because the sign of the override is where the Khatvanga went wrong
## once. Row name "<aura id>@<item id>".
const ITEM_ROWS: Array[String] = ["empowered_copper_khatvanga", "legendary_bone_khatvanga"]


static func _make_unit(host: Node, grid: CombatGrid, at: Vector2i, team: int) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Measure%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["equipped_weapon"] = {
		"name": "Reference Sword", "type": "sword", "stats": {"damage": 6}}
	CharacterSystem.update_derived_stats(unit.character_data)
	unit.character_data["derived"]["armor"] = SHEET_ARMOR
	host.add_child(unit)
	unit.max_hp = 500
	unit.current_hp = 500
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


static func _remove(units: Array, grid: CombatGrid) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.free()


## Every resistance name a measurement asks about: the damage types and the
## afflictions, sorted so the fixture is stable.
static func resist_names() -> Array[String]:
	var out: Array[String] = []
	for t in DamageType.all():
		out.append(str(t))
	for a in Resistance.AFFLICTIONS:
		if not a in out:
			out.append(a)
	out.sort()
	return out


## How much of a 100-point hit of `damage_type` lands. HP is put back after.
static func _taken(unit: CombatUnit, damage_type: String) -> float:
	var before: int = unit.current_hp
	CombatManager.apply_damage(unit, 100, damage_type)
	var taken: int = before - unit.current_hp
	unit.current_hp = before
	return float(taken)


## The ground's mana-cost percentage for `unit`. Before the migration this was
## get_continuous_stat_bonus(unit, "mana_cost_pct"); after it, a stat.mana_cost_pct
## value read through ValuePaths. The measurement asks whichever exists.
static func _mana_cost_pct(unit: CombatUnit) -> float:
	if CombatManager.has_method("mana_cost_pct_of"):
		return float(CombatManager.call("mana_cost_pct_of", unit))
	return float(CombatManager.get_continuous_stat_bonus(unit, "mana_cost_pct"))


## Every measured number of `unit` right now.
static func snapshot(unit: CombatUnit) -> Dictionary:
	CombatManager._refresh_aura_max_hp()
	seed(4242)
	var snap: Dictionary = {
		"initiative": float(unit.get_initiative()),
		"movement": float(unit.get_movement()),
		"accuracy": float(unit.get_accuracy()),
		"dodge": float(unit.get_dodge()),
		"damage": float(unit.get_attack_damage()),
		"armor": float(unit.get_armor()),
		"crit_chance": float(unit.get_crit_chance()),
		"spellpower": float(unit.get_spellpower()),
		"max_hp": float(unit.max_hp),
		"mana_cost_pct": _mana_cost_pct(unit),
		"taken.fire": _taken(unit, "fire"),
		"taken.physical": _taken(unit, "physical"),
	}
	for t in resist_names():
		snap["resist." + t] = float(Resistance.total(unit, t))
	randomize()
	return snap


static func changes(before: Dictionary, after: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in before:
		var d: float = snappedf(float(after.get(key, 0.0)) - float(before[key]), 0.001)
		if d != 0.0:
			out[key] = d
	return out


## What aura `aura_id` changes at each of PLACES. With `item_id`, the aura is
## carried on that item instead of being intrinsic (so its override applies).
static func measure_aura(host: Node, grid: CombatGrid, aura_id: String,
		item_id: String = "") -> Dictionary:
	var units: Dictionary = {}
	for place in PLACES:
		var team: int = 1 if place in ENEMY_PLACES else 0
		units[place] = _make_unit(host, grid, PLACES[place], team)
	var before: Dictionary = {}
	for place in units:
		before[place] = snapshot(units[place])

	var emitter: CombatUnit = units["self"]
	if item_id == "":
		emitter.intrinsic_auras.append(aura_id)
	else:
		emitter.character_data["equipment"]["chest"] = item_id

	var out: Dictionary = {}
	for place in units:
		out[place] = changes(before[place], snapshot(units[place]))

	# Take the aura away again before the units go, so the stored max-HP
	# bonus is unwound rather than left to the next measurement.
	emitter.intrinsic_auras.clear()
	emitter.character_data["equipment"].erase("chest")
	CombatManager._refresh_aura_max_hp()
	_remove(units.values(), grid)
	return out


## What zone `zone_id` changes on an ally and an enemy of its owner standing on
## it, and on an ally and an enemy standing off it.
static func measure_zone(host: Node, grid: CombatGrid, zone_id: String) -> Dictionary:
	var owner: CombatUnit = _make_unit(host, grid, Vector2i(2, 2), 0)
	var places: Dictionary = {
		"ally_inside": [Vector2i(12, 8), 0], "enemy_inside": [Vector2i(13, 8), 1],
		"ally_outside": [Vector2i(30, 20), 0], "enemy_outside": [Vector2i(31, 20), 1],
	}
	var units: Dictionary = {}
	for place in places:
		units[place] = _make_unit(host, grid, places[place][0], places[place][1])
	var before: Dictionary = {}
	for place in units:
		before[place] = snapshot(units[place])

	CombatManager.active_zones.clear()
	CombatManager.place_zone(zone_id, [Vector2i(12, 8), Vector2i(13, 8)], owner, 9)

	var out: Dictionary = {}
	for place in units:
		out[place] = changes(before[place], snapshot(units[place]))

	CombatManager.active_zones.clear()
	CombatManager._refresh_aura_max_hp()
	var all: Array = units.values()
	all.append(owner)
	_remove(all, grid)
	return out


## Every aura id and every zone id, sorted, "_" names left out.
static func aura_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in AuraSystem.definitions():
		ids.append(str(id))
	ids.sort()
	return ids


static func zone_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in Zone.definitions():
		ids.append(str(id))
	ids.sort()
	return ids


## The whole measurement: {auras: {row: {place: changes}}, zones: {...}}.
static func measure_all(host: Node, grid: CombatGrid) -> Dictionary:
	var auras: Dictionary = {}
	for id in aura_ids():
		auras[id] = measure_aura(host, grid, id)
	for item_id in ITEM_ROWS:
		var aura_id: String = str(ItemSystem.get_item(item_id).get("passive_aura", ""))
		auras["%s@%s" % [aura_id, item_id]] = measure_aura(host, grid, aura_id, item_id)
	var zones: Dictionary = {}
	for id in zone_ids():
		zones[id] = measure_zone(host, grid, id)
	return {"auras": auras, "zones": zones}
