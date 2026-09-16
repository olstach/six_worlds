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
const EXPECTED_CHECKS: int = 8


func _ready() -> void:
	_check_the_vocabulary_loads()
	_check_every_damage_type_has_a_category()
	_check_compounds_split_into_real_types()
	_check_splitting_loses_no_damage()
	_check_a_random_type_resolves_to_one_of_its_choices()
	_check_physical_subtypes_fall_back()
	_check_magic_covers_the_schools()
	_check_specials_answer_to_nothing()

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
