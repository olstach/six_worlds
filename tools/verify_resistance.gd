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
const EXPECTED_CHECKS: int = 34


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	# The vocabulary.
	_check_the_vocabulary_loads()
	_check_every_damage_type_has_a_category()
	_check_compounds_split_into_real_types()
	_check_a_compound_arrives_as_the_lesser_resisted_half()
	_check_a_random_type_resolves_to_one_of_its_choices()
	_check_physical_subtypes_fall_back()
	_check_magic_covers_the_schools()
	_check_specials_answer_to_nothing()

	# The resolver: where a resistance comes from, and what bounds it.
	_check_innate_resistance_reduces_damage()
	_check_a_status_can_grant_and_take_away()
	_check_statuses_declare_their_resistances()
	_check_silk_turns_arrows()
	_check_you_cannot_buff_your_way_into_absorption()
	_check_a_single_declaration_grants_immunity()
	_check_absorption_heals()
	_check_vulnerability_has_a_floor()

	# The claim the whole audit rests on: EVERY source of damage is resisted.
	_check_every_damage_source_respects_resistance()
	_check_a_compound_meets_both_resistances()
	_check_armour_is_physical_and_equanimity_is_magic()
	_check_an_affliction_can_be_shrugged_off()

	# Poison, and the four features that declared themselves and did nothing.
	_check_an_aura_can_grant_resistance()
	_check_the_ground_can_grant_resistance()
	_check_disease_spreads_to_whoever_is_close()
	_check_spread_honours_the_reach_it_declares()
	_check_alchemy_makes_venom_bite_harder()
	_check_a_poisoner_gets_twice_the_coating()
	_check_a_small_hit_is_not_rounded_away()
	_check_the_ui_number_matches_what_lands()

	# Enemies are built from a birth too, and keep what it resists.
	_check_an_enemy_inherits_its_birth_resistances()
	_check_an_enemy_inherits_its_birth_traits_resistances()

	# The 2026-10-15 sweep: hazards, retaliation and statuses that named the
	# wrong damage type, or no source.
	_check_poison_and_acid_ground_deal_poison()
	_check_retaliation_names_a_real_damage_type()
	_check_wet_ground_soaks_you()
	_check_bombs_auras_and_brands_name_their_source()

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
	for required in ["physical", "slashing", "crushing", "piercing", "fire",
			"ice", "lightning", "space", "white", "black", "poison"]:
		if not DamageType.exists(required):
			_fail("damage type '%s' is missing from the vocabulary" % required)
	# And the two that caused this audit.
	if DamageType.exists("cold"):
		_fail("'cold' is back in the vocabulary — it is `ice`, and having both "
			+ "is how five spells came to deal a type nothing resisted")
	if DamageType.exists("holy"):
		_fail("'holy' is back in the vocabulary — it is `white`")
	# The three that were damage types and should not have been: air damage was
	# lightning every time it was dealt, earth damage was dealt by no spell at
	# all, and water damage was impact, ice and drowning under one name.
	for gone in ["air", "water", "earth"]:
		if DamageType.exists(gone):
			_fail("'%s' is a damage type again — it is a magic SCHOOL, and the "
				% gone + "damage its spells deal is lightning, ice or impact")
	_done()


func _check_every_damage_type_has_a_category() -> void:
	for name in DamageType.all():
		var category: String = DamageType.category_of(name)
		if not category in DamageType.CATEGORIES:
			_fail("damage type '%s' has category '%s', which is not in "
				% [name, category] + "DamageType.CATEGORIES")
	_done()


## A compound arrives as one of its components, so every component has to be a
## type something can actually resist — and never itself a compound.
func _check_compounds_split_into_real_types() -> void:
	var compounds := 0
	for name in DamageType.all():
		var components: Array = DamageType.components_of(name)
		if components.is_empty():
			continue
		compounds += 1
		if components.size() < 2:
			_fail("compound '%s' has one component, so it is a rename" % name)
		for component in components:
			if not DamageType.exists(str(component)):
				_fail("compound '%s' is made of '%s', which is not a damage type"
					% [name, str(component)])
			if not DamageType.components_of(str(component)).is_empty():
				_fail("compound '%s' is made of compound '%s' — a component has "
					% [name, str(component)] + "to be something resistance can match")
	if compounds == 0:
		_fail("no compound damage types at all — solar, white_fire, fire_black "
			+ "and physical_fire were the reason the vocabulary exists")
	_done()


## The rule: a mixed type arrives as whichever component the TARGET resists
## less, so it is a strategic pick rather than a hedge.
func _check_a_compound_arrives_as_the_lesser_resisted_half() -> void:
	var unit := _make_unit()

	unit.resistances = {"fire": 80, "white": 0}
	if Resistance.concrete_type(unit, "solar") != "white":
		_fail("against 80%% fire resistance, solar arrived as '%s'"
			% Resistance.concrete_type(unit, "solar"))
	unit.resistances = {"fire": 0, "white": 80}
	if Resistance.concrete_type(unit, "solar") != "fire":
		_fail("against 80%% white resistance, solar arrived as '%s'"
			% Resistance.concrete_type(unit, "solar"))

	# A vulnerability counts as resisting less, so a mixed type finds the
	# weakness — which is the point of casting one.
	unit.resistances = {"fire": 0, "white": -50}
	if Resistance.concrete_type(unit, "solar") != "white":
		_fail("solar did not find a -50%% white vulnerability")

	# A simple type is unchanged, and an unknown one arrives as itself.
	if Resistance.concrete_type(unit, "fire") != "fire":
		_fail("a simple type was rewritten to '%s'"
			% Resistance.concrete_type(unit, "fire"))
	if Resistance.concrete_type(unit, "no_such_type") != "no_such_type":
		_fail("an unknown type did not arrive as itself")
	_cleanup([unit])
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
	for name in ["black", "white", "fire", "ice", "lightning", "space"]:
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
	var stranger := _make_unit(Vector2i(9, 9))
	if _taken(stranger, 40, "no_such_type") != 40:
		_fail("a hit of an unknown damage type dealt %d of 40 — it should "
			% _taken(stranger, 40, "no_such_type") + "arrive unresisted")
	_cleanup([stranger])
	_done()


# ── enemies ──────────────────────────────────────────────────────────────────

## An enemy rolls a real birth before its archetype is applied, so it must
## carry that birth's racial resistances, ADDED to the archetype's own — the
## same stacking a player character's base_resistances get. Every race ships
## with "resistances": {} today, so this gives each hungry-ghost birth a
## temporary one, builds the skeleton king (physical 20, crushing 20, ice -10),
## and puts the race data back afterwards.
func _check_an_enemy_inherits_its_birth_resistances() -> void:
	var originals: Dictionary = {}  # birth_id -> its resistances before the test
	for birth_id in CharacterSystem._birth_data:
		if String(birth_id).begins_with("_"):
			continue
		var data: Dictionary = CharacterSystem._birth_data[birth_id]
		if data.get("realm", "") != "hungry_ghost":
			continue
		originals[birth_id] = data.get("resistances", {})
		data["resistances"] = {"physical": 15, "poison": 25}

	var enemy: Dictionary = EnemySystem._build_enemy(
		"hg_skeleton_king", 500, "hungry_ghost", "dry_graveyards", true)

	for birth_id in originals:
		CharacterSystem._birth_data[birth_id]["resistances"] = originals[birth_id]

	if originals.is_empty():
		_fail("enemy birth resistance: no hungry_ghost births to test with")
	elif not String(enemy.get("birth", "")) in originals:
		_fail("enemy birth resistance: king rolled birth '%s', not a hungry_ghost one"
			% enemy.get("birth", ""))
	else:
		# Every reader uses derived.resistances, for enemies as for the party.
		var res: Dictionary = enemy.get("derived", {}).get("resistances", {})
		var expected: Dictionary = {
			"physical": 35,   # archetype 20 + birth 15
			"crushing": 20,   # archetype only
			"ice": -10,       # archetype only
			"poison": 25,     # birth only
			"fire": 0,        # neither
		}
		# Plus whatever the birth's TRAITS grant (an undead birth's Undead
		# trait resists poison 25) — enemies have received those since
		# 2026-10-15; the next check tests that on its own.
		# And, since enemies use the party's sheet (2026-11-26), whatever the
		# armour it wears and its perks grant, the same as a party member.
		var from_traits: Dictionary = TraitSystem.get_resistances(enemy)
		var from_gear: Dictionary = ItemSystem.calculate_equipment_stats(enemy).get("resistances", {})
		var from_perks: Dictionary = PerkSystem.get_passive_resistances(enemy)
		for key in expected:
			expected[key] = int(expected[key]) + int(from_traits.get(key, 0)) \
				+ int(from_gear.get(key, 0)) + int(from_perks.get(key, 0))
		for key in expected:
			if int(res.get(key, 0)) != int(expected[key]):
				_fail("enemy birth resistance: %s is %s, expected %d"
					% [key, res.get(key, 0), expected[key]])
	_done()


## Most racial resistance lives on a birth's TRAITS, not its `resistances`
## block — Undead resists poison and disease, Incorporeal physical. A player
## gets them through TraitSystem.get_resistances() in update_derived_stats();
## EnemySystem never ran that step, so an enemy ghost was as solid as a living
## one. This gives every hungry-ghost birth the Incorporeal trait for the
## length of one build, then puts the births back.
func _check_an_enemy_inherits_its_birth_traits_resistances() -> void:
	var originals: Dictionary = {}  # birth_id -> its starting_traits before the test
	for birth_id in CharacterSystem._birth_data:
		if String(birth_id).begins_with("_"):
			continue
		var data: Dictionary = CharacterSystem._birth_data[birth_id]
		if data.get("realm", "") != "hungry_ghost":
			continue
		originals[birth_id] = data.get("starting_traits", [])
		data["starting_traits"] = ["incorporeal"]

	var enemy: Dictionary = EnemySystem._build_enemy(
		"hg_skeleton_king", 500, "hungry_ghost", "dry_graveyards", true)

	for birth_id in originals:
		CharacterSystem._birth_data[birth_id]["starting_traits"] = originals[birth_id]

	if originals.is_empty():
		_fail("enemy trait resistance: no hungry_ghost births to test with")
	elif not "incorporeal" in enemy.get("traits", []):
		_fail("enemy trait resistance: the king did not get its birth's Incorporeal "
			+ "trait at all, so this check proves nothing")
	else:
		# Archetype physical 20, plus whatever the traits it ended up with grant
		# (Incorporeal's 50 at least).
		var from_traits: int = int(TraitSystem.get_resistances(enemy).get("physical", 0))
		var physical: int = int(enemy.get("derived", {}).get("resistances", {}).get("physical", 0))
		# Armour and perks add theirs on the one sheet too (2026-11-26).
		var from_gear_and_perks: int = \
			int(ItemSystem.calculate_equipment_stats(enemy).get("resistances", {}).get("physical", 0)) \
			+ int(PerkSystem.get_passive_resistances(enemy).get("physical", 0))
		if from_traits < 50:
			_fail("enemy trait resistance: Incorporeal no longer grants physical 50 "
				+ "— update this check")
		if physical != 20 + from_traits + from_gear_and_perks:
			_fail("enemy trait resistance: an Incorporeal skeleton king has physical "
				+ "%d, expected archetype 20 + traits %d + gear/perks %d"
				% [physical, from_traits, from_gear_and_perks])
	_done()


## Poison ground dealt `physical`: armour soaked it and poison resistance did
## nothing, while the Poisoned status it applies ticked as poison. Acid ground
## the same. Both are poison now (acid because the acid bomb and flask already
## dealt poison), so a poison-immune unit stands in either unharmed.
func _check_poison_and_acid_ground_deal_poison() -> void:
	var immune := _make_unit(Vector2i(12, 12))
	var bare := _make_unit(Vector2i(13, 12), 1)
	immune.resistances = {"poison": 100}
	for effect in [CombatGrid.TerrainEffect.POISON, CombatGrid.TerrainEffect.ACID]:
		var label: String = grid.get_effect_name(effect)
		for unit in [immune, bare]:
			_clear_statuses(unit)
			unit.current_hp = unit.max_hp
			grid.add_terrain_effect(unit.grid_position, effect, 3)
			CombatManager._process_terrain_effects(unit)
		if immune.current_hp < immune.max_hp:
			_fail("a poison-immune unit lost %d HP standing in %s — it is not dealing poison"
				% [immune.max_hp - immune.current_hp, label])
		if bare.current_hp >= bare.max_hp:
			_fail("%s did nothing to a bare unit, so the check above proves nothing" % label)
		grid.remove_terrain_effect(immune.grid_position)
		grid.remove_terrain_effect(bare.grid_position)
	_cleanup([immune, bare])
	_done()


## Every retaliation names a real damage type. Storm_Lord and Lightning_Form
## struck back with `air` for months after air stopped being one, so the
## shock landed unresisted and not as magic.
func _check_retaliation_names_a_real_damage_type() -> void:
	for status_name in CombatManager._status_effects:
		var retal: Dictionary = CombatManager._status_effects[status_name].get("retaliation", {})
		if retal.is_empty() or not retal.has("element"):
			continue
		if not DamageType.exists(str(retal["element"])):
			_fail("%s retaliates with '%s', which is not a damage type"
				% [status_name, str(retal["element"])])
	for status_name in ["Storm_Lord", "Lightning_Form"]:
		var retal: Dictionary = CombatManager.get_status_definition(status_name).get("retaliation", {})
		if str(retal.get("element", "")) != "lightning":
			_fail("%s retaliates with '%s', expected lightning"
				% [status_name, str(retal.get("element", ""))])
	_done()


## Wet ground promised a vulnerability in two comments and only slowed. It
## Soaks you now: +25% lightning taken, through the status's
## `drain resist.lightning` hold, and nothing else.
func _check_wet_ground_soaks_you() -> void:
	var unit := _make_unit(Vector2i(14, 14))
	if CombatManager.get_status_definition("Soaked").is_empty():
		_fail("the Soaked status is missing from statuses.json")
		_cleanup([unit])
		_done()
		return
	grid.add_terrain_effect(unit.grid_position, CombatGrid.TerrainEffect.WET, 3)
	CombatManager._process_terrain_effects(unit)
	if not unit.has_status("Soaked"):
		_fail("standing on wet ground did not Soak the unit")
	if not unit.has_status("Slowed"):
		_fail("wet ground no longer slows")
	if not is_equal_approx(Resistance.total(unit, "lightning"), -25.0):
		_fail("a Soaked unit's lightning resistance is %.0f, expected -25"
			% Resistance.total(unit, "lightning"))
	for other in ["ice", "fire", "physical"]:
		if Resistance.total(unit, other) != 0.0:
			_fail("Soaked changed %s resistance to %.0f — it is lightning only"
				% [other, Resistance.total(unit, other)])
	grid.remove_terrain_effect(unit.grid_position)
	_cleanup([unit])
	_done()


## A status applied with no source cannot be scaled by whoever applied it:
## burning_damage_pct and poison_damage_pct are read off the source entry.
## Bombs, aura grant_status and the poison talisman brand all passed none.
func _check_bombs_auras_and_brands_name_their_source() -> void:
	var thrower := _make_unit(Vector2i(16, 16), 0)
	thrower.character_data["skills"] = {"alchemy": 5}  # 3+ means no scatter
	var victim := _make_unit(Vector2i(17, 16), 1)

	# 1. A bomb, in the long status form and the bare-name form (the flashbang
	#    and acid flask list bare names, and `.get()` on a String was a script
	#    error that stopped the bomb half-way).
	var bomb: Dictionary = {"effect": {"damage": 0, "aoe_radius": 1,
		"statuses": [{"name": "Burning", "duration": 3, "chance": 100}, "Blinded"],
		"status_duration": 2}}
	CombatManager._use_bomb(thrower, bomb, victim.grid_position)
	if _source_of(victim, "Burning") != thrower:
		_fail("a bomb's Burning does not name the thrower as its source")
	if not victim.has_status("Blinded"):
		_fail("a bomb listing a bare status name did not apply it")
	_clear_statuses(victim)

	# 2. An aura's grant_status, from a unit that owns the aura.
	var aura: Dictionary = {"id": "_probe", "name": "Probe Aura",
		"source_kind": "test", "source_id": "probe"}
	CombatManager._apply_aura_payload(thrower, victim, aura,
		{"kind": "grant_status", "status": "Poisoned", "duration": 2}, 1.0)
	if _source_of(victim, "Poisoned") != thrower:
		_fail("an aura's granted Poisoned does not name the aura's owner as source")
	_clear_statuses(victim)

	# 3. The poison talisman brand: 15% a hit, so swing until it lands.
	ItemSystem._runtime_items["_probe_venom_charm"] = {
		"name": "Probe Charm", "passive": {"perk": "poison_brand_greater"}}
	thrower.character_data["equipment"]["trinket1"] = "_probe_venom_charm"
	for _i in 300:
		CombatManager._process_on_hit_perks(thrower, victim, {"hit": true, "damage": 20})
		if victim.has_status("Poisoned"):
			break
	if not victim.has_status("Poisoned"):
		_fail("300 hits with a Greater Venom brand never poisoned anyone")
	elif _source_of(victim, "Poisoned") != thrower:
		_fail("a poison brand's Poisoned does not name the attacker as its source")
	thrower.character_data["equipment"]["trinket1"] = ""
	ItemSystem._runtime_items.erase("_probe_venom_charm")
	_cleanup([thrower, victim])
	_done()


## The `source` on a unit's entry for `status`, or null.
func _source_of(unit: CombatUnit, status: String) -> Variant:
	for effect in unit.status_effects:
		if str(effect.get("status", "")) == status:
			return effect.get("source", null)
	return null


# ── helpers ──────────────────────────────────────────────────────────────────

## End every status on `unit` through the one exit, so the holds its
## `while_active` placed (resistances among them) go with it. Clearing the
## list by hand would leave those holds behind.
func _clear_statuses(unit: CombatUnit) -> void:
	for entry in unit.status_effects.duplicate():
		CombatManager._end_status(unit, entry, "removed")
	unit.status_effects.clear()


## A `while_active` effect that adds `amount` to the resistance to `type`.
func _resist_hold(type: String, amount: float) -> Dictionary:
	return {"op": "modify", "value": "resist." + type, "mode": "fortify", "amount": amount}


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
	_clear_statuses(unit)

	# And the other direction: a drain on resist. subtracts.
	CombatManager._apply_status_effect(unit, "Smoke_Form", 5)
	var vulnerable := false
	for element in ["fire", "ice", "lightning", "space", "physical", "black", "white"]:
		if Resistance.total(unit, element) < 0.0:
			vulnerable = true
	if not vulnerable:
		_fail("Smoke_Form left the unit vulnerable to nothing, though it "
			+ "drains a resistance")
	_cleanup([unit])
	_done()


## Twenty hand-written effect strings became a table, and then the table
## became data: every status that resists or fears something says so in
## `while_active` modifies of `resist.<type>` (they were
## `grants_resistance` / `grants_vulnerability` until 2026-11-26). These are statuses that
## carried the strings, with the numbers the strings meant.
func _check_statuses_declare_their_resistances() -> void:
	var unit := _make_unit()
	# [status, damage type, expected total]. One row per shape the old table
	# had: physical covering its subtypes, a vulnerability, an element under a
	# school's old name, the magic scope, and `all`.
	for entry in [
			["Frozen", "piercing", -50.0],
			["Petrified", "slashing", 100.0],
			["Armored_Supreme", "crushing", 75.0],
			["Lightning_Form", "lightning", 100.0],
			["Lightning_Form", "slashing", 50.0],
			["Water_Vulnerable_25", "ice", -25.0],
			["Fire_Vulnerable_50", "fire", -50.0],
			["Praying", "white", 15.0],
			["Praying", "piercing", 0.0],
			["Rainbow_Cloak", "poison", 0.0],
			["Rainbow_Cloak", "fire", 15.0],
			["Mantric_Armor", "black", 25.0],
			["Mantric_Armor", "physical", 0.0],
			["Invulnerable", "fire", 100.0],
			["Invulnerable", "crushing", 100.0]]:
		var status: String = str(entry[0])
		if CombatManager.get_status_definition(status).is_empty():
			_fail("status '%s' is gone — update this table" % status)
			continue
		_clear_statuses(unit)
		CombatManager._apply_status_effect(unit, status, 5)
		var value: float = Resistance.total(unit, str(entry[1]))
		if not is_equal_approx(value, float(entry[2])):
			_fail("%s gave %.0f%% against %s, expected %.0f"
				% [status, value, str(entry[1]), float(entry[2])])

	# A key of "physical" covers its subtypes, which is what makes Petrified
	# stop a sword and a mace alike.
	_clear_statuses(unit)
	CombatManager._status_effects["_probe_phys"] = {
		"name": "_probe_phys", "while_active": [_resist_hold("physical", 50)]}
	CombatManager._apply_status_effect(unit, "_probe_phys", 5)
	for subtype in ["slashing", "crushing", "piercing", "physical"]:
		if Resistance.total(unit, subtype) != 50.0:
			_fail("a physical 50 status gave %.0f%% against %s"
				% [Resistance.total(unit, subtype), subtype])
	if Resistance.total(unit, "fire") != 0.0:
		_fail("a physical key reached fire damage")
	CombatManager._status_effects.erase("_probe_phys")
	_clear_statuses(unit)

	# The strings themselves are gone, and must stay gone: a status carrying
	# one now resists nothing, because nothing translates it any more.
	for status_name in CombatManager._status_effects:
		for name in CombatManager._status_effects[status_name].get("effects", []):
			if str(name) in RETIRED_RESISTANCE_STRINGS:
				_fail("status '%s' declares '%s', a retired resistance string — "
					% [status_name, str(name)] + "nothing reads it; write "
					+ "a while_active modify of resist.<type> instead")
	_cleanup([unit])
	_done()


## The effect strings the old Resistance.LEGACY_EFFECTS table translated, kept
## so a status copied from an old draft cannot bring one back silently.
const RETIRED_RESISTANCE_STRINGS: Array[String] = [
	"physical_resist_50", "physical_damage_negation_50_percent",
	"physical_damage_reduction_25", "physical_damage_reduction_50",
	"physical_damage_reduction_75", "physical_resistance_plus_25",
	"physical_resistance_plus_50", "vulnerable_to_physical",
	"physical_immunity", "physical_immune", "fire_resistance_plus_25",
	"fire_resistance_minus_50", "fire_damage_immunity", "fire_vulnerability",
	"water_resistance_minus_25", "water_resistance_minus_50",
	"water_damage_immunity", "air_damage_immunity", "air_immune",
	"elemental_resistance_25", "all_element_resistance",
	"magic_resistance_bonus", "immune_to_all_damage",
]


## Silk armour's `ranged` resistance: from the material, into the character's
## standing resistances, and read in the attack path beside Air_Shield. It sat
## in equipment_tables.json reaching nothing until 2026-10-15.
func _check_silk_turns_arrows() -> void:
	# 1. The material reaches derived.resistances through the worn item.
	var robed: Dictionary = CharacterSystem.create_blank_character()
	robed["equipment"]["chest"] = "perfected_sages_robe"
	CharacterSystem.update_derived_stats(robed)
	var from_silk: int = int(robed["derived"].get("resistances", {}).get("ranged", 0))
	if from_silk != 10:
		_fail("a silk robe gave %d ranged resistance, expected the material's 10"
			% from_silk)

	# 2. And the attack path reads it: the same arrow, under the same dice,
	#    lands for less on a unit that resists `ranged`.
	var archer := _make_unit(Vector2i(10, 10), 0)
	archer.character_data["equipped_weapon"] = {
		"name": "Probe Bow", "type": "bow", "stats": {"range": 6, "damage": 30}}
	CharacterSystem.update_derived_stats(archer.character_data)
	archer.character_data["derived"]["accuracy"] = 999
	var mark := _make_unit(Vector2i(13, 10), 1)
	mark.character_data["derived"]["dodge"] = 0
	if not archer.is_ranged_weapon():
		_fail("the probe bow does not count as ranged, so this check proves nothing")

	var plain: Dictionary = {}
	var silked: Dictionary = {}
	for attempt in 20:
		mark.resistances.erase("ranged")
		plain = _seeded_attack(archer, mark, 9000 + attempt)
		mark.resistances["ranged"] = 10
		silked = _seeded_attack(archer, mark, 9000 + attempt)
		if bool(plain.get("hit", false)) and bool(silked.get("hit", false)):
			break
	var before: int = int(plain.get("damage", 0))
	var after: int = int(silked.get("damage", 0))
	if before <= 0:
		_fail("the probe arrow never landed (%s)" % str(plain))
	elif after != maxi(1, int(before * 0.9)):
		_fail("10%% ranged resistance turned a %d arrow into %d, expected %d"
			% [before, after, maxi(1, int(before * 0.9))])

	# 3. It is a resistance to arrows, not to swords.
	archer.character_data["equipped_weapon"] = {
		"name": "Probe Sword", "type": "sword", "stats": {"damage": 30}}
	grid.unit_positions.erase(mark.grid_position)
	mark.grid_position = Vector2i(11, 10)
	grid.unit_positions[mark.grid_position] = mark
	for attempt in 20:
		mark.resistances.erase("ranged")
		plain = _seeded_attack(archer, mark, 9100 + attempt)
		mark.resistances["ranged"] = 10
		silked = _seeded_attack(archer, mark, 9100 + attempt)
		if bool(plain.get("hit", false)):
			break
	if int(plain.get("damage", 0)) <= 0:
		_fail("the probe sword never landed (%s)" % str(plain))
	elif int(plain.get("damage", 0)) != int(silked.get("damage", 0)):
		_fail("ranged resistance turned a sword: %d became %d"
			% [int(plain.get("damage", 0)), int(silked.get("damage", 0))])
	_cleanup([archer, mark])
	_done()


## One attack under a fixed seed, so two calls differ only in what the test
## changed between them.
func _seeded_attack(attacker: CombatUnit, defender: CombatUnit, rng_seed: int) -> Dictionary:
	defender.current_hp = defender.max_hp
	attacker.actions_remaining = 9
	CombatManager.turn_order = [attacker]
	CombatManager.current_unit_index = 0
	seed(rng_seed)
	return CombatManager.attack_unit(attacker, defender)


## The rule that makes absorption safe: contributions SUM but the sum is capped
## at 90, so no stack of buffs reaches immunity, let alone absorption.
func _check_you_cannot_buff_your_way_into_absorption() -> void:
	var unit := _make_unit()
	unit.resistances = {"fire": 60}
	CombatManager._status_effects["_probe_a"] = {
		"name": "_probe_a", "while_active": [_resist_hold("fire", 60)]}
	CombatManager._status_effects["_probe_b"] = {
		"name": "_probe_b", "while_active": [_resist_hold("fire", 60)]}
	CombatManager._apply_status_effect(unit, "_probe_a", 5)
	CombatManager._apply_status_effect(unit, "_probe_b", 5)

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

	# And a status may declare it too — Solar Form's fire immunity.
	var burned := _make_unit(Vector2i(7, 5))
	CombatManager._status_effects["_probe_immune"] = {
		"name": "_probe_immune", "while_active": [_resist_hold("fire", 100)]}
	CombatManager._apply_status_effect(burned, "_probe_immune", 5)
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
		_clear_statuses(unit)
		CombatManager._apply_status_effect(unit, "Burning", 5)
		CombatManager._process_status_effects(unit)
	if immune.current_hp < immune.max_hp:
		_fail("a fire-immune unit lost %d HP to Burning"
			% (immune.max_hp - immune.current_hp))
	if bare.current_hp >= bare.max_hp:
		_fail("Burning did nothing to a unit with no fire resistance, so the "
			+ "check above proves nothing")
	_clear_statuses(immune)
	_clear_statuses(bare)

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
	_clear_statuses(immune)
	_clear_statuses(bare)

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


## A whole solar hit arrives as one half or the other, so a unit immune to fire
## alone is not protected from it at all — it comes as white instead.
func _check_a_compound_meets_both_resistances() -> void:
	var fireproof := _make_unit()
	var bare := _make_unit(Vector2i(6, 5))
	fireproof.resistances = {"fire": 100}

	var through: int = _taken(fireproof, 100, "solar")
	var whole: int = _taken(bare, 100, "solar")
	if through != whole:
		_fail("a fire-immune unit took %d of a solar hit where a bare one took "
			% through + "%d — the white half should arrive undiminished" % whole)

	# Resisting the other half instead sends it back through fire.
	fireproof.resistances = {"fire": 100, "white": 50}
	if _taken(fireproof, 100, "solar") != 50:
		_fail("against fire immunity and 50%% white, a 100 solar hit dealt %d, "
			% _taken(fireproof, 100, "solar") + "expected the 50 the white half costs")

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
		_clear_statuses(tough)
		_clear_statuses(bare)
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

	# And a compound whose other half is unresisted lands in full, because it
	# arrives as that half rather than as a share of each.
	immune.resistances = {"fire": 100}
	if _taken(immune, 3, "solar") != 3:
		_fail("a 3-point solar hit on a fire-immune unit dealt %d — it should "
			% _taken(immune, 3, "solar") + "arrive as white and land whole")
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


# ── poison, and the things that only said they worked ────────────────────────

## A `resistance` aura payload. Immune System promised allies within 2 tiles a
## 15% chance to shrug off poison, bleed and disease, and auras had no way to
## grant resistance at all.
func _check_an_aura_can_grant_resistance() -> void:
	var medic := _make_unit(Vector2i(10, 10), 0)
	var near := _make_unit(Vector2i(11, 10), 0)
	var far := _make_unit(Vector2i(24, 24), 0)
	var foe := _make_unit(Vector2i(12, 10), 1)
	medic.character_data["perks"] = ["immune_system"]

	if Resistance.total(near, "poison") <= 0.0:
		_fail("an ally beside the medic has %.0f%% poison resistance — the "
			% Resistance.total(near, "poison") + "aura is not reaching them")
	if Resistance.total(far, "poison") != 0.0:
		_fail("an ally 14 tiles away picked up %.0f%% poison resistance"
			% Resistance.total(far, "poison"))
	if Resistance.total(foe, "poison") != 0.0:
		_fail("the medic's aura protected an enemy")
	# It guards afflictions, which are not damage types, through the same call.
	if Resistance.total(near, "bleed") <= 0.0:
		_fail("the aura granted no bleed resistance, though it names one")
	# And ONLY what it names: a medic is no help against a fireball.
	for unnamed in ["fire", "ice", "physical", "black"]:
		if Resistance.total(near, unnamed) != 0.0:
			_fail("the aura granted %.0f%% %s resistance, which it never names"
				% [Resistance.total(near, unnamed), unnamed])
	# And it is continuous: it goes when the medic does, with nothing to reset.
	medic.character_data["perks"] = []
	if Resistance.total(near, "poison") != 0.0:
		_fail("poison resistance survived the medic losing the perk — a "
			+ "continuous payload must not be stored")
	_cleanup([medic, near, far, foe])
	_done()


## The same payload kind, anchored to the ground instead of a body — one
## vocabulary, two anchors, as with every other aura payload.
func _check_the_ground_can_grant_resistance() -> void:
	CombatManager.active_zones.clear()
	var unit := _make_unit(Vector2i(14, 9))
	var zone_def: Dictionary = {"name": "Probe Ward", "affects": "all",
		"while_inside": [{"kind": "resistance", "type": "poison", "amount": 40}]}
	CombatManager.active_zones.append({
		"id": "_probe_ward", "name": "Probe Ward", "def": zone_def,
		"tiles": {Vector2i(14, 9): true}, "source": null,
		"turns_left": 5, "entered": {}})

	if Resistance.total(unit, "poison") != 40.0:
		_fail("standing on warded ground gave %.0f%% poison resistance"
			% Resistance.total(unit, "poison"))
	for unnamed in ["fire", "ice", "physical"]:
		if Resistance.total(unit, unnamed) != 0.0:
			_fail("warded ground granted %.0f%% %s resistance, which it never "
				% [Resistance.total(unit, unnamed), unnamed] + "names")
	unit.grid_position = Vector2i(30, 20)
	if Resistance.total(unit, "poison") != 0.0:
		_fail("the ward followed the unit off its own tiles")
	CombatManager.active_zones.clear()
	_cleanup([unit])
	_done()


## Diseased is the one status whose whole idea is catching it from somebody,
## and it did not spread: it declared `spreads_on_contact` in its effects list,
## which nothing reads, while the spread mechanism that has worked for months
## wanted a `spread` block. Two ways to say one thing, and the status picked
## the one with no reader.
func _check_disease_spreads_to_whoever_is_close() -> void:
	var carrier := _make_unit(Vector2i(10, 10), 0)
	var beside := _make_unit(Vector2i(11, 10), 1)
	var away := _make_unit(Vector2i(25, 25), 1)

	var caught := 0
	for _i in 60:
		_clear_statuses(beside)
		_clear_statuses(away)
		_clear_statuses(carrier)
		CombatManager._apply_status_effect(carrier, "Diseased", 5)
		CombatManager._process_status_spread(carrier)
		if beside.has_status("Diseased"):
			caught += 1
		if away.has_status("Diseased"):
			_fail("disease reached a unit fifteen tiles away")
			break
	if caught == 0:
		_fail("sixty rounds beside a plague carrier and nobody caught it")
	if caught == 60:
		_fail("everybody beside a carrier caught it every single round — the "
			+ "chance is not being rolled")
	_cleanup([carrier, beside, away])
	_done()


## The reach a spreading status declares. Every one of them carried a `range`
## and the spreader ignored it, always reaching exactly one tile.
func _check_spread_honours_the_reach_it_declares() -> void:
	var carrier := _make_unit(Vector2i(10, 10), 0)
	var two_away := _make_unit(Vector2i(12, 10), 1)
	CombatManager._status_effects["_probe_plague"] = {
		"name": "_probe_plague", "polarity": "negative", "duration": {"kind": "turns", "base": 3},
		"spread": {"chance": "high", "range": 3},
	}

	var caught := false
	for _i in 40:
		_clear_statuses(two_away)
		_clear_statuses(carrier)
		CombatManager._apply_status_effect(carrier, "_probe_plague", 5)
		CombatManager._process_status_spread(carrier)
		if two_away.has_status("_probe_plague"):
			caught = true
			break
	if not caught:
		_fail("a status declaring range 3 never reached a unit two tiles away")

	# And a melee one does not.
	CombatManager._status_effects["_probe_touch"] = {
		"name": "_probe_touch", "polarity": "negative", "duration": {"kind": "turns", "base": 3},
		"spread": {"chance": "high", "range": "melee"},
	}
	for _i in 40:
		_clear_statuses(two_away)
		_clear_statuses(carrier)
		CombatManager._apply_status_effect(carrier, "_probe_touch", 5)
		CombatManager._process_status_spread(carrier)
		if two_away.has_status("_probe_touch"):
			_fail("a melee-range status jumped two tiles")
			break
	CombatManager._status_effects.erase("_probe_plague")
	CombatManager._status_effects.erase("_probe_touch")
	_cleanup([carrier, two_away])
	_done()


## Fire Magic has made burns bite harder for months through
## `burning_damage_pct`, read off whoever set the fire. Venom had no such
## thing: an Alchemy 15 master poisoned exactly as hard as a novice.
func _check_alchemy_makes_venom_bite_harder() -> void:
	var master := _make_unit(Vector2i(4, 4), 0)
	var novice := _make_unit(Vector2i(5, 4), 0)
	master.character_data["skills"] = {"alchemy": 10}
	CharacterSystem.update_derived_stats(master.character_data)
	if float(master.character_data.derived.get("poison_damage_pct", 0.0)) <= 0.0:
		_fail("Alchemy 10 produced no poison_damage_pct at all")

	var bitten := _make_unit(Vector2i(20, 20), 1)
	var mildly := _make_unit(Vector2i(21, 20), 1)
	CombatManager._apply_status_effect(bitten, "Poisoned", 5, 0, master)
	CombatManager._apply_status_effect(mildly, "Poisoned", 5, 0, novice)
	bitten.current_hp = bitten.max_hp
	mildly.current_hp = mildly.max_hp
	CombatManager._process_status_effects(bitten)
	CombatManager._process_status_effects(mildly)
	var hard: int = bitten.max_hp - bitten.current_hp
	var soft: int = mildly.max_hp - mildly.current_hp
	if soft <= 0:
		_fail("an unskilled poisoner's venom did nothing at all")
	if hard <= soft:
		_fail("a master alchemist's venom ticked for %d and a novice's for %d"
			% [hard, soft])

	# It is the POISONER's skill, not the victim's.
	var skilled_victim := _make_unit(Vector2i(22, 20), 1)
	skilled_victim.character_data["skills"] = {"alchemy": 10}
	CharacterSystem.update_derived_stats(skilled_victim.character_data)
	CombatManager._apply_status_effect(skilled_victim, "Poisoned", 5, 0, novice)
	skilled_victim.current_hp = skilled_victim.max_hp
	CombatManager._process_status_effects(skilled_victim)
	if skilled_victim.max_hp - skilled_victim.current_hp != soft:
		_fail("the victim's own Alchemy changed how hard they were poisoned")
	_cleanup([master, novice, bitten, mildly, skilled_victim])
	_done()


## "Weapon coatings last twice as long (double applications per dose)" — the
## Poisoner perk said so and nothing read it.
func _check_a_poisoner_gets_twice_the_coating() -> void:
	var plain := _make_unit(Vector2i(3, 3), 0)
	var poisoner := _make_unit(Vector2i(4, 3), 0)
	poisoner.character_data["perks"] = ["poisoner"]
	var oil: Dictionary = ItemSystem.get_item("poison_oil")
	if oil.is_empty():
		_fail("poison_oil is not in items.json")
		_done()
		return

	CombatManager._apply_oil(plain, oil)
	CombatManager._apply_oil(poisoner, oil)
	var plain_attacks: int = int(plain.weapon_oil.get("attacks_remaining", 0))
	var perk_attacks: int = int(poisoner.weapon_oil.get("attacks_remaining", 0))
	if plain_attacks <= 0:
		_fail("applying an oil left no attacks on it at all")
	elif perk_attacks != plain_attacks * 2:
		_fail("a poisoner got %d applications where an ordinary character got "
			% perk_attacks + "%d — the perk promises double" % plain_attacks)
	_cleanup([plain, poisoner])
	_done()
