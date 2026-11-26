extends RefCounted
## Measures what one status does to the numbers of a unit that carries it.
##
## Shared by tools/capture_status_baseline.gd (which ran ONCE, before the
## statuses were migrated to the effect shape, and wrote the answers to
## tools/fixtures/status_baseline.json) and by verify_effects.gd's
## `status_numbers_match_baseline` check, which asks the same questions of the
## migrated data and compares. Both must measure the same way, so the way lives
## here, in one place. Loaded with preload(); it has no class_name on purpose,
## because it is a test tool, not part of the game.
##
## What is measured, for each status, on two reference units:
##   the eight stat getters a `stat.` hold reaches (EffectVocab.STATS), and
##   Resistance.total() for every damage type in damage_types.json.
## The answer is the CHANGE the status causes (after minus before), with zero
## changes left out, so the fixture lists only what a status really does.
##
## The status is applied the real way, through CombatManager._apply_status_effect
## at duration 3, value 0, no source, one application (default stacks).

## The numbers looked at. The keys of a snapshot are these, then "resist.<type>".
const GETTERS: Array[String] = [
	"initiative", "movement", "accuracy", "dodge",
	"damage", "armor", "crit_chance", "spellpower",
]

## The two reference units. Both are rebuilt fresh for every status, so one
## status can never leak into the next one's measurement.
const KINDS: Array[String] = ["party", "enemy"]

## The archetype the reference enemy is built from, its XP budget and the seed
## its build rolls under (the same one verify_effects' enemy-sheet check uses).
const ENEMY_ARCHETYPE: String = "hell_demon_warrior"
const ENEMY_XP: int = 900
const ENEMY_SEED: int = 2611


## A party unit: a blank character holding a plain sword, so its attack damage
## is a fixed number rather than a fist's roll.
static func make_party_unit(host: Node, grid: CombatGrid, at: Vector2i) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "RefParty"
	unit.team = CombatManager.Team.PLAYER
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["equipped_weapon"] = {
		"name": "Reference Sword", "type": "sword", "stats": {"damage": 6}}
	CharacterSystem.update_derived_stats(unit.character_data)
	host.add_child(unit)
	unit.max_hp = int(unit.character_data.derived.get("max_hp", 100))
	unit.current_hp = unit.max_hp
	_place(unit, grid, at)
	return unit


## An enemy unit, built from its archetype the way an encounter builds one.
static func make_enemy_unit(host: Node, grid: CombatGrid, at: Vector2i) -> CombatUnit:
	seed(ENEMY_SEED)
	var enemy: Dictionary = EnemySystem._build_enemy(ENEMY_ARCHETYPE, ENEMY_XP, "hell")
	randomize()
	var unit := CombatUnit.new()
	host.add_child(unit)
	unit.init_as_enemy(enemy)
	_place(unit, grid, at)
	return unit


static func _place(unit: CombatUnit, grid: CombatGrid, at: Vector2i) -> void:
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)


static func remove_unit(unit: CombatUnit, grid: CombatGrid) -> void:
	grid.remove_unit(unit)
	CombatManager.all_units.erase(unit)
	unit.queue_free()


## Every damage type a resistance can be asked about, sorted so the fixture
## is stable.
static func damage_types() -> Array[String]:
	var out: Array[String] = []
	for t in DamageType.all():
		out.append(str(t))
	out.sort()
	return out


## The numbers of `unit` right now. get_attack_damage() may roll a range, so
## the roll is seeded the same way every time.
static func snapshot(unit: CombatUnit) -> Dictionary:
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
	}
	for t in damage_types():
		snap["resist." + t] = float(Resistance.total(unit, t))
	randomize()
	return snap


## after - before, keeping only the keys that moved.
static func changes(before: Dictionary, after: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in before:
		var d: float = snappedf(float(after.get(key, 0.0)) - float(before[key]), 0.001)
		if d != 0.0:
			out[key] = d
	return out


## What `status_name` changes on a fresh unit of `kind` ("party" / "enemy").
static func measure_one(host: Node, grid: CombatGrid, status_name: String, kind: String) -> Dictionary:
	var at := Vector2i(4, 4)
	var unit: CombatUnit = make_party_unit(host, grid, at) if kind == "party" \
		else make_enemy_unit(host, grid, at)
	var before: Dictionary = snapshot(unit)
	CombatManager._apply_status_effect(unit, status_name, 3, 0, null)
	var after: Dictionary = snapshot(unit)
	remove_unit(unit, grid)
	return changes(before, after)


## The reference units' own numbers with no status, for the record (and so a
## reader of the fixture can see what "halved" was halving).
static func reference_numbers(host: Node, grid: CombatGrid) -> Dictionary:
	var out: Dictionary = {}
	for kind in KINDS:
		var unit: CombatUnit = make_party_unit(host, grid, Vector2i(4, 4)) if kind == "party" \
			else make_enemy_unit(host, grid, Vector2i(4, 4))
		var snap: Dictionary = snapshot(unit)
		snap["damage_pct"] = float(unit.character_data.get("derived", {}).get("damage_pct", 0.0))
		out[kind] = snap
		remove_unit(unit, grid)
	return out


## Which statuses each StatusOps.TAGS selector picks, given one entry per
## status definition. Sorted names per tag. Names beginning with "_" are a
## verifier's own probe statuses and are left out.
static func tag_selections(defs: Dictionary) -> Dictionary:
	var entries: Array = []
	for name in defs:
		if not str(name).begins_with("_"):
			entries.append({"status": str(name)})
	var out: Dictionary = {}
	for tag in StatusOps.TAGS:
		var names: Array[String] = []
		for entry in StatusOps.select_from(entries, {"tag": tag}, defs):
			names.append(str(entry.status))
		names.sort()
		out[tag] = names
	return out
