extends Node
## Headless verification for the damage-type vocabulary and, from step 2, the
## resistance resolver.
##
## Run: godot --headless res://tools/verify_resistance.tscn
##
## The vocabulary exists because a resistance key that does not match a damage
## type reads as ZERO resistance and nothing complains. Five spells dealt
## `ice` while every resistance entry in the game said `cold`; six summons
## resisted `holy`, which nothing has ever dealt. So these checks ask the real
## question — "can this damage type be resisted by anything at all?" — rather
## than whether the file parses.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var checks_run: int = 0
var grid: CombatGrid
const EXPECTED_CHECKS: int = 21


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	# The vocabulary.
	_check_the_vocabulary_loads()
	_check_every_damage_type_has_a_category()
	_check_compounds_split_into_real_types()
	_check_splitting_loses_no_damage()
	_check_a_random_type_resolves_to_one_of_its_choices()
	_check_physical_subtypes_fall_back()
	_check_magic_covers_the_schools()
	_check_specials_answer_to_nothing()

	# The resolver: where a resistance comes from, and what bounds it.
	_check_innate_resistance_reduces_damage()
	_check_a_status_can_grant_and_take_away()
	_check_the_legacy_effect_strings_still_work()
	_check_you_cannot_buff_your_way_into_absorption()
	_check_a_single_declaration_grants_immunity()
	_check_absorption_heals()
	_check_vulnerability_has_a_floor()

	# The claim the whole audit rests on: EVERY source of damage is resisted.
	_check_every_damage_source_respects_resistance()
	_check_a_compound_meets_both_resistances()
	_check_armour_is_physical_and_equanimity_is_magic()
	_check_an_affliction_can_be_shrugged_off()
	_check_a_small_hit_is_not_rounded_away()
	_check_the_ui_number_matches_what_lands()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway, "
			% [checks_run, EXPECTED_CHECKS] + "so its assertions never ran")
		failures += 1

	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _fail(msg: String) -> void:
	printerr("  FAIL: %s" % msg)
	failures += 1


func _done() -> void:
	checks_run += 1


func _check_the_vocabulary_loads() -> void:
	var all: Dictionary = DamageType.all()
	if all.is_empty():
		_fail("DamageType.all() is empty — damage_types.json did not load")
	# The names every other system depends on.
	for required in ["physical", "slashing", "fire", "water", "air", "earth",
			"space", "ice", "white", "black", "poison"]:
		if not DamageType.exists(required):
			_fail("damage type '%s' is missing from the vocabulary" % required)
	# And the two that caused this audit.
	if DamageType.exists("cold"):
		_fail("'cold' is back in the vocabulary — it is `ice`, and having both "
			+ "is how five spells came to deal a type nothing resisted")
	if DamageType.exists("holy"):
		_fail("'holy' is back in the vocabulary — it is `white`")
	_done()


func _check_every_damage_type_has_a_category() -> void:
	for name in DamageType.all():
		var category: String = DamageType.category_of(name)
		if not category in DamageType.CATEGORIES:
			_fail("damage type '%s' has category '%s', which is not in "
				% [name, category] + "DamageType.CATEGORIES")
	_done()


## A compound is dealt as its components, so every component has to be a type
## something can actually resist.
func _check_compounds_split_into_real_types() -> void:
	var compounds := 0
	for name in DamageType.all():
		if not DamageType.is_compound(name):
			continue
		compounds += 1
		var parts: Array[Dictionary] = DamageType.resolve(name)
		if parts.size() < 2:
			_fail("compound '%s' resolved to %d part(s)" % [name, parts.size()])
		var total := 0.0
		for part in parts:
			total += float(part.share)
			if not DamageType.exists(str(part.type)):
				_fail("compound '%s' is made of '%s', which is not a damage type"
					% [name, str(part.type)])
			if DamageType.is_compound(str(part.type)):
				_fail("compound '%s' is made of compound '%s' — a component has "
					% [name, str(part.type)] + "to be something resistance can match")
		if not is_equal_approx(total, 1.0):
			_fail("compound '%s' shares sum to %.2f, not 1.0" % [name, total])
	if compounds == 0:
		_fail("no compound damage types at all — solar, white_fire, fire_black "
			+ "and physical_fire were the reason the vocabulary exists")
	_done()


## Integer division must not eat damage: 25 solar is 12 white and 13 fire, not
## 12 and 12.
func _check_splitting_loses_no_damage() -> void:
	for amount in [1, 2, 3, 7, 25, 100, 999]:
		for name in ["solar", "fire_black", "physical_fire", "prismatic", "fire"]:
			var total := 0
			for part in DamageType.split(name, amount):
				total += int(part.damage)
			if total != amount:
				_fail("splitting %d %s damage produced %d"
					% [amount, name, total])
	# And a single-type hit is one whole share, so callers need no branch.
	var simple: Array[Dictionary] = DamageType.split("fire", 30)
	if simple.size() != 1 or int(simple[0].damage) != 30:
		_fail("a simple type did not split into one whole share")
	_done()


func _check_a_random_type_resolves_to_one_of_its_choices() -> void:
	if not DamageType.is_random("random_elemental"):
		_fail("random_elemental is not a random type")
		_done()
		return
	var seen: Dictionary = {}
	var choices: Array = DamageType.get_type("random_elemental").get("choices", [])
	for _i in 200:
		var rolled: String = DamageType.concrete("random_elemental")
		seen[rolled] = true
		if not rolled in choices:
			_fail("random_elemental rolled '%s', which is not one of its choices"
				% rolled)
	# All five should show up in 200 rolls; one that never does is a fixed pick
	# wearing a random name.
	if seen.size() < choices.size():
		_fail("random_elemental produced only %d of its %d choices in 200 rolls"
			% [seen.size(), choices.size()])
	# A non-random type is unchanged by the roll.
	if DamageType.concrete("fire") != "fire":
		_fail("concrete() changed a non-random type")
	_done()


func _check_physical_subtypes_fall_back() -> void:
	for subtype in ["slashing", "crushing", "piercing"]:
		if DamageType.subtype_of(subtype) != "physical":
			_fail("'%s' falls back to '%s', not to physical"
				% [subtype, DamageType.subtype_of(subtype)])
		if not DamageType.is_physical(subtype):
			_fail("'%s' does not read as physical" % subtype)
		if DamageType.is_magic(subtype):
			_fail("'%s' reads as magic, so the Yoga table would resist it"
				% subtype)
	if DamageType.subtype_of("fire") != "":
		_fail("fire falls back to '%s'" % DamageType.subtype_of("fire"))
	_done()


## The bug the constant had: MAGIC_DAMAGE_TYPES omitted black and white, so
## equanimity did nothing against the two schools most obviously made of magic,
## and listed holy, shadow and arcane, which nothing deals.
func _check_magic_covers_the_schools() -> void:
	for name in ["black", "white", "fire", "water", "air", "earth", "space", "ice"]:
		if not DamageType.is_magic(name):
			_fail("'%s' does not count as magic, so magic_resistance_pct will "
				% name + "not apply to it")
	for name in ["physical", "slashing", "crushing", "piercing", "poison"]:
		if DamageType.is_magic(name):
			_fail("'%s' counts as magic — equanimity is not armour, and it is "
				% name + "no antidote either")
	_done()


func _check_specials_answer_to_nothing() -> void:
	for name in ["true", "sacrifice"]:
		if not DamageType.ignores_resistance(name):
			_fail("'%s' does not ignore resistance" % name)
		if not DamageType.ignores_armour(name):
			_fail("'%s' does not ignore armour — Chöd's call site has claimed "
				% name + "in a comment since it was written that it bypasses it")
	for name in ["fire", "physical", "black"]:
		if DamageType.ignores_resistance(name) or DamageType.ignores_armour(name):
			_fail("'%s' ignores resistance or armour" % name)
	# An unknown type must arrive unresisted and noisy, not silently harmless.
	var parts: Array[Dictionary] = DamageType.resolve("no_such_type")
	if parts.size() != 1 or str(parts[0].type) != "no_such_type":
		_fail("an unknown damage type did not resolve to itself")
	_done()


# ── helpers ──────────────────────────────────────────────────────────────────

func _make_unit(at: Vector2i = Vector2i(5, 5), team: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 1000
	unit.current_hp = 1000
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


## How much HP a hit of `damage_type` actually costs this unit.
func _taken(unit: CombatUnit, damage: int, damage_type: String) -> int:
	unit.current_hp = unit.max_hp
	CombatManager.apply_damage(unit, damage, damage_type)
	return unit.max_hp - unit.current_hp


# ── the resolver ─────────────────────────────────────────────────────────────

func _check_innate_resistance_reduces_damage() -> void:
	var unit := _make_unit()
	var bare := _make_unit(Vector2i(6, 5))
	unit.resistances = {"fire": 50}
	if Resistance.total(unit, "fire") != 50.0:
		_fail("innate fire 50 resolved to %.0f" % Resistance.total(unit, "fire"))
	var hurt: int = _taken(unit, 100, "fire")
	var bare_hurt: int = _taken(bare, 100, "fire")
	if hurt >= bare_hurt:
		_fail("a unit with 50%% fire resistance took %d where a bare one took %d"
			% [hurt, bare_hurt])

	# A physical subtype falls back to generic physical — and a specific entry
	# wins over the generic one, which is how a skeleton is weak to maces in
	# particular rather than to being hit in general.
	unit.resistances = {"physical": 40, "crushing": -50}
	if Resistance.total(unit, "slashing") != 40.0:
		_fail("slashing did not fall back to physical 40 (got %.0f)"
			% Resistance.total(unit, "slashing"))
	if Resistance.total(unit, "crushing") != -50.0:
		_fail("crushing read %.0f, not its own -50"
			% Resistance.total(unit, "crushing"))
	_cleanup([unit, bare])
	_done()


func _check_a_status_can_grant_and_take_away() -> void:
	var unit := _make_unit()
	# Inner_Flame grants fire and water resistance in data. It resolved to zero
	# for a while because the gather used a lambda, and GDScript lambdas capture
	# by value — `sum += amount` updated a copy.
	CombatManager._apply_status_effect(unit, "Inner_Flame", 5)
	if Resistance.total(unit, "fire") <= 0.0:
		_fail("Inner_Flame granted no fire resistance")
	unit.status_effects.clear()

	# And the other direction: grants_vulnerability subtracts.
	CombatManager._apply_status_effect(unit, "Smoke_Form", 5)
	var vulnerable := false
	for element in ["fire", "water", "air", "earth", "space", "physical"]:
		if Resistance.total(unit, element) < 0.0:
			vulnerable = true
	if not vulnerable:
		_fail("Smoke_Form left the unit vulnerable to nothing, though it "
			+ "declares grants_vulnerability")
	_cleanup([unit])
	_done()


## The twenty hand-written strings became one table. Each one still has to
## reach the number.
func _check_the_legacy_effect_strings_still_work() -> void:
	var unit := _make_unit()
	for entry in [["Stone_Skin", "physical", true], ["Bark_Skin", "physical", true],
			["Frozen", "physical", false]]:
		var status: String = str(entry[0])
		if CombatManager.get_status_definition(status).is_empty():
			continue   # the status was renamed; the table check below still holds
		unit.status_effects.clear()
		CombatManager._apply_status_effect(unit, status, 5)
		var value: float = Resistance.total(unit, str(entry[1]))
		if bool(entry[2]) and value <= 0.0:
			_fail("%s gave %.0f%% %s resistance" % [status, value, str(entry[1])])
		if not bool(entry[2]) and value >= 0.0:
			_fail("%s left %s resistance at %.0f, expected a vulnerability"
				% [status, str(entry[1]), value])
	# A rule about "physical" covers its subtypes, which is what makes Stone
	# Skin stop a sword and a mace alike.
	unit.status_effects.clear()
	unit.status_effects.append({"status": "_probe_phys", "duration": 5})
	CombatManager._status_effects["_probe_phys"] = {
		"name": "_probe_phys", "effects": ["physical_damage_reduction_50"]}
	for subtype in ["slashing", "crushing", "piercing", "physical"]:
		if Resistance.total(unit, subtype) != 50.0:
			_fail("a physical_damage_reduction_50 status gave %.0f%% against %s"
				% [Resistance.total(unit, subtype), subtype])
	if Resistance.total(unit, "fire") != 0.0:
		_fail("a physical rule reached fire damage")
	CombatManager._status_effects.erase("_probe_phys")
	unit.status_effects.clear()

	# Every string in the table has to be one some status actually declares,
	# or it is a branch for a status that does not exist.
	var declared: Dictionary = {}
	for status_name in CombatManager._status_effects:
		for name in CombatManager._status_effects[status_name].get("effects", []):
			declared[str(name)] = true
	for name in Resistance.LEGACY_EFFECTS:
		if not declared.has(str(name)):
			_fail("Resistance.LEGACY_EFFECTS handles '%s', which no status "
				% str(name) + "declares — a branch for nothing")
	_cleanup([unit])
	_done()


## The rule that makes absorption safe: contributions SUM but the sum is capped
## at 90, so no stack of buffs reaches immunity, let alone absorption.
func _check_you_cannot_buff_your_way_into_absorption() -> void:
	var unit := _make_unit()
	unit.resistances = {"fire": 60}
	unit.status_effects.append({"status": "_probe_a", "duration": 5})
	unit.status_effects.append({"status": "_probe_b", "duration": 5})
	CombatManager._status_effects["_probe_a"] = {
		"name": "_probe_a", "grants_resistance": {"fire": 60}}
	CombatManager._status_effects["_probe_b"] = {
		"name": "_probe_b", "grants_resistance": {"fire": 60}}

	var total: float = Resistance.total(unit, "fire")
	# Exactly the cap: 180 summed, clamped. Anything else means either the cap
	# is not biting or the sum crossed into the declared-immunity branch, where
	# it would report the largest single source instead.
	if not is_equal_approx(total, Resistance.REDUCTION_CAP):
		_fail("60 innate plus two 60%% buffs resolved to %.0f%%, expected the "
			% total + "cap of %.0f" % Resistance.REDUCTION_CAP)
	var hurt: int = _taken(unit, 100, "fire")
	if hurt <= 0:
		_fail("a stack of buffs made the unit untouchable: %d damage from 100"
			% hurt)
	CombatManager._status_effects.erase("_probe_a")
	CombatManager._status_effects.erase("_probe_b")
	_cleanup([unit])
	_done()


func _check_a_single_declaration_grants_immunity() -> void:
	var unit := _make_unit()
	unit.resistances = {"ice": 100}
	if Resistance.total(unit, "ice") != Resistance.DECLARED_IMMUNITY:
		_fail("a declared 100 resolved to %.0f" % Resistance.total(unit, "ice"))
	if _taken(unit, 250, "ice") != 0:
		_fail("an ice-immune unit took %d from a 250 hit"
			% _taken(unit, 250, "ice"))
	# Immunity is to the type it names, not to everything.
	if _taken(unit, 100, "fire") <= 0:
		_fail("ice immunity also stopped fire")

	# And a status may declare it too — Solar Form's fire immunity, through the
	# legacy table.
	var burned := _make_unit(Vector2i(7, 5))
	burned.status_effects.append({"status": "_probe_immune", "duration": 5})
	CombatManager._status_effects["_probe_immune"] = {
		"name": "_probe_immune", "effects": ["fire_damage_immunity"]}
	if _taken(burned, 200, "fire") != 0:
		_fail("a fire-immune status let %d damage through"
			% _taken(burned, 200, "fire"))
	CombatManager._status_effects.erase("_probe_immune")
	_cleanup([unit, burned])
	_done()


## Above 100, the excess is healed: a fire elemental drinks fire.
func _check_absorption_heals() -> void:
	var unit := _make_unit()
	unit.resistances = {"fire": 150}
	unit.current_hp = 500
	CombatManager.apply_damage(unit, 100, "fire")
	if unit.current_hp <= 500:
		_fail("a unit declaring 150%% fire resistance took the hit instead of "
			+ "drinking it (%d HP, was 500)" % unit.current_hp)
	elif unit.current_hp != 550:
		_fail("absorbing a 100 fire hit at 150%% healed %d, expected 50"
			% (unit.current_hp - 500))

	# Absorption is capped, so nothing heals for more than the hit.
	unit.resistances = {"fire": 500}
	unit.current_hp = 500
	CombatManager.apply_damage(unit, 100, "fire")
	if unit.current_hp - 500 > 100:
		_fail("absorbing a 100 hit healed %d — more than the hit"
			% (unit.current_hp - 500))
	_cleanup([unit])
	_done()


func _check_vulnerability_has_a_floor() -> void:
	var unit := _make_unit()
	unit.resistances = {"fire": -400}
	if Resistance.total(unit, "fire") != Resistance.VULNERABILITY_FLOOR:
		_fail("-400%% resistance resolved to %.0f, not the floor of %.0f"
			% [Resistance.total(unit, "fire"), Resistance.VULNERABILITY_FLOOR])
	var hurt: int = _taken(unit, 100, "fire")
	if hurt > 200:
		_fail("a 100 hit on a maximally vulnerable unit dealt %d — more than "
			% hurt + "double")
	if hurt <= 100:
		_fail("vulnerability did not increase the damage at all: %d from 100" % hurt)
	_cleanup([unit])
	_done()


# ── the claim the audit rests on ─────────────────────────────────────────────

## Resistance used to be applied by the CALLER, and 9 of 61 call sites did it.
## A fire-immune unit took full damage from a burning tile, a fire DoT, a fire
## zone and a fire aura. Every one of those paths is checked here.
func _check_every_damage_source_respects_resistance() -> void:
	var immune := _make_unit(Vector2i(10, 10))
	var bare := _make_unit(Vector2i(11, 10), 1)
	immune.resistances = {"fire": 100}

	# 1. A damage-over-time tick.
	for unit in [immune, bare]:
		unit.current_hp = unit.max_hp
		unit.status_effects.clear()
		CombatManager._apply_status_effect(unit, "Burning", 5)
		CombatManager._process_status_effects(unit)
	if immune.current_hp < immune.max_hp:
		_fail("a fire-immune unit lost %d HP to Burning"
			% (immune.max_hp - immune.current_hp))
	if bare.current_hp >= bare.max_hp:
		_fail("Burning did nothing to a unit with no fire resistance, so the "
			+ "check above proves nothing")
	immune.status_effects.clear()
	bare.status_effects.clear()

	# 2. A burning tile.
	grid.add_terrain_effect(immune.grid_position, CombatGrid.TerrainEffect.FIRE, 3)
	grid.add_terrain_effect(bare.grid_position, CombatGrid.TerrainEffect.FIRE, 3)
	immune.current_hp = immune.max_hp
	bare.current_hp = bare.max_hp
	CombatManager._process_terrain_effects(immune)
	CombatManager._process_terrain_effects(bare)
	if immune.current_hp < immune.max_hp:
		_fail("a fire-immune unit took %d damage standing in fire — Solar Form "
			% (immune.max_hp - immune.current_hp) + "burned for months")
	if bare.current_hp >= bare.max_hp:
		_fail("a fire tile did nothing to a bare unit")
	immune.status_effects.clear()
	bare.status_effects.clear()

	# 3. A zone payload.
	CombatManager.active_zones.clear()
	CombatManager._status_effects["_probe_fire_zone"] = {}
	var zone_def: Dictionary = {"name": "Probe Fire", "affects": "all",
		"while_inside": [{"kind": "damage", "amount": 40, "element": "fire"}]}
	CombatManager.active_zones.append({
		"id": "_probe_fire", "name": "Probe Fire", "def": zone_def,
		"tiles": {immune.grid_position: true, bare.grid_position: true},
		"source": null, "turns_left": 5, "entered": {}})
	immune.current_hp = immune.max_hp
	bare.current_hp = bare.max_hp
	CombatManager._tick_zones()
	if immune.current_hp < immune.max_hp:
		_fail("a fire-immune unit took %d from a fire zone"
			% (immune.max_hp - immune.current_hp))
	if bare.current_hp >= bare.max_hp:
		_fail("a fire zone did nothing to a bare unit")
	CombatManager.active_zones.clear()
	CombatManager._status_effects.erase("_probe_fire_zone")

	# 4. An aura payload, through the same applier.
	immune.current_hp = immune.max_hp
	bare.current_hp = bare.max_hp
	var aura: Dictionary = {"id": "_probe", "name": "Probe Aura",
		"source_kind": "test", "source_id": "probe"}
	var payload: Dictionary = {"kind": "damage", "amount": 40, "element": "fire"}
	CombatManager._apply_aura_payload(null, immune, aura, payload, 1.0)
	CombatManager._apply_aura_payload(null, bare, aura, payload, 1.0)
	if immune.current_hp < immune.max_hp:
		_fail("a fire-immune unit took %d from a fire aura"
			% (immune.max_hp - immune.current_hp))
	if bare.current_hp >= bare.max_hp:
		_fail("a fire aura did nothing to a bare unit")
	_cleanup([immune, bare])
	_done()


## Half a solar hit is white and half is fire, each resisted on its own. So a
## fire-immune unit takes half of it, not none and not all.
func _check_a_compound_meets_both_resistances() -> void:
	var fireproof := _make_unit()
	var bare := _make_unit(Vector2i(6, 5))
	fireproof.resistances = {"fire": 100}

	var half: int = _taken(fireproof, 100, "solar")
	var whole: int = _taken(bare, 100, "solar")
	if half == 0:
		_fail("fire immunity stopped a whole solar hit — half of it is white")
	if half >= whole:
		_fail("a fire-immune unit took %d of a solar hit where a bare one took "
			% half + "%d" % whole)
	if absi(half - whole / 2) > 2:
		_fail("a fire-immune unit took %d of a 100 solar hit, expected about "
			% half + "half of %d" % whole)

	# Immune to both halves is immune to the compound.
	fireproof.resistances = {"fire": 100, "white": 100}
	if _taken(fireproof, 100, "solar") != 0:
		_fail("a unit immune to white AND fire took %d of a solar hit"
			% _taken(fireproof, 100, "solar"))
	_cleanup([fireproof, bare])
	_done()


## Armour stops blades; equanimity stops magic. The Armor table's flat
## reduction used to apply to every type, magic included, which made the two
## tables stack instead of complement.
func _check_armour_is_physical_and_equanimity_is_magic() -> void:
	var armoured := _make_unit()
	var bare := _make_unit(Vector2i(6, 5))
	armoured.character_data["derived"]["damage_reduction_pct"] = 50.0

	if _taken(armoured, 100, "slashing") >= _taken(bare, 100, "slashing"):
		_fail("armour did not reduce physical damage")
	if _taken(armoured, 100, "fire") != _taken(bare, 100, "fire"):
		_fail("armour reduced fire damage (%d vs %d) — a breastplate is no "
			% [_taken(armoured, 100, "fire"), _taken(bare, 100, "fire")]
			+ "help against a fireball")

	var calm := _make_unit(Vector2i(7, 5))
	calm.character_data["derived"]["magic_resistance_pct"] = 50.0
	if _taken(calm, 100, "fire") >= _taken(bare, 100, "fire"):
		_fail("equanimity did not reduce fire damage")
	if _taken(calm, 100, "slashing") != _taken(bare, 100, "slashing"):
		_fail("equanimity reduced a sword blow (%d vs %d)"
			% [_taken(calm, 100, "slashing"), _taken(bare, 100, "slashing")])
	if _taken(calm, 100, "black") >= _taken(bare, 100, "black"):
		_fail("equanimity did nothing against Black magic — the constant it "
			+ "replaced omitted black and white")

	# And the specials answer to neither.
	if _taken(armoured, 100, "sacrifice") != 100:
		_fail("a ritual sacrifice of 100 cost %d — armour is not supposed to "
			% _taken(armoured, 100, "sacrifice") + "stop your own knife")
	_cleanup([armoured, bare, calm])
	_done()


## Some resistances are to a thing that HAPPENS to you. Stone Body's +25%
## bleed was written into derived.resistances and read by nothing.
func _check_an_affliction_can_be_shrugged_off() -> void:
	var tough := _make_unit()
	var bare := _make_unit(Vector2i(6, 5))
	tough.resistances = {"bleed": 90}

	var tough_bled := 0
	var bare_bled := 0
	for _i in 60:
		tough.status_effects.clear()
		bare.status_effects.clear()
		CombatManager._apply_status_effect(tough, "Bleeding", 3)
		CombatManager._apply_status_effect(bare, "Bleeding", 3)
		if tough.has_status("Bleeding"):
			tough_bled += 1
		if bare.has_status("Bleeding"):
			bare_bled += 1
	if bare_bled != 60:
		_fail("a unit with no bleed resistance shrugged off %d of 60 bleeds"
			% (60 - bare_bled))
	if tough_bled > 25:
		_fail("90%% bleed resistance still started bleeding %d times in 60"
			% tough_bled)
	if tough_bled == 0:
		_fail("90%% bleed resistance never bled at all in 60 tries — something "
			+ "must always be able to go wrong")

	# The damage once bleeding is NOT discounted by it: an affliction
	# resistance is a chance, not a multiplier.
	if Resistance.total(tough, "bleed") > Resistance.REDUCTION_CAP:
		_fail("bleed resolved as a damage resistance of %.0f"
			% Resistance.total(tough, "bleed"))
	_cleanup([tough, bare])
	_done()


## A hit that was not fully resisted lands for something. The 90% cap can round
## a 1-point hit to nothing, and a real hit must not vanish — but immunity
## takes nothing at all, and for a compound that means immunity to every half.
func _check_a_small_hit_is_not_rounded_away() -> void:
	var capped := _make_unit()
	capped.resistances = {"fire": 90}
	if _taken(capped, 1, "fire") != 1:
		_fail("a 1-point fire hit on a 90%%-resistant unit dealt %d — rounding "
			% _taken(capped, 1, "fire") + "made a real hit disappear")

	var immune := _make_unit(Vector2i(6, 5))
	immune.resistances = {"fire": 100}
	if _taken(immune, 1, "fire") != 0:
		_fail("a fire-immune unit took %d from a 1-point fire hit"
			% _taken(immune, 1, "fire"))

	# And a compound where only one half is stopped still lands for its other
	# half. Three points, not one: splitting 1 point two ways gives one half
	# nothing at all, so a single point of a compound CAN be fully stopped by
	# immunity to whichever half the remainder went to. That is noise, not a
	# rule worth bending the split for.
	immune.resistances = {"fire": 100}
	if _taken(immune, 3, "solar") < 1:
		_fail("a 3-point solar hit on a fire-immune unit dealt nothing — the "
			+ "white half is not immune")
	immune.resistances = {"fire": 100, "white": 100}
	if _taken(immune, 3, "solar") != 0:
		_fail("a unit immune to both halves took %d from a solar hit"
			% _taken(immune, 3, "solar"))
	_cleanup([capped, immune])
	_done()


## The number a character sheet can show has to be the number that lands. The
## examine panel read the static `resistances` dict, so nothing a status, perk,
## aura or zone contributed ever showed.
func _check_the_ui_number_matches_what_lands() -> void:
	var unit := _make_unit()

	# Plain resistance.
	unit.resistances = {"fire": 40}
	if not is_equal_approx(Resistance.damage_taken_pct(unit, "fire"), 60.0):
		_fail("40%% fire resistance reports %.0f%% taken, expected 60"
			% Resistance.damage_taken_pct(unit, "fire"))

	# Immunity reports zero rather than a negative multiplier.
	unit.resistances = {"fire": 100}
	if Resistance.damage_taken_pct(unit, "fire") != 0.0:
		_fail("a fire-immune unit reports taking %.0f%%"
			% Resistance.damage_taken_pct(unit, "fire"))

	# Absorption is not a damage figure either.
	unit.resistances = {"fire": 200}
	if Resistance.damage_taken_pct(unit, "fire") != 0.0:
		_fail("an absorbing unit reports taking %.0f%%"
			% Resistance.damage_taken_pct(unit, "fire"))

	# Armour and equanimity are in the figure, each against its own half of the
	# vocabulary.
	unit.resistances = {"physical": 50}
	unit.character_data["derived"]["damage_reduction_pct"] = 50.0
	unit.character_data["derived"]["magic_resistance_pct"] = 50.0
	var phys: float = Resistance.damage_taken_pct(unit, "physical")
	if not is_equal_approx(phys, 25.0):
		_fail("50%% resistance and 50%% armour report %.0f%% taken, expected 25"
			% phys)
	unit.resistances = {"fire": 0}
	var magic: float = Resistance.damage_taken_pct(unit, "fire")
	if not is_equal_approx(magic, 50.0):
		_fail("50%% equanimity reports %.0f%% of a fire hit taken, expected 50"
			% magic)

	# And the figure agrees with what apply_damage actually does.
	unit.resistances = {"physical": 50}
	var predicted: int = int(round(200.0 * phys / 100.0))
	var actual: int = _taken(unit, 200, "physical")
	if absi(predicted - actual) > 2:
		_fail("the sheet predicts %d of a 200 physical hit and %d lands"
			% [predicted, actual])
	_cleanup([unit])
	_done()
