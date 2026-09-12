extends Node
## Headless verification for the four skill payouts that modify a combat roll
## or magnitude: mace stuns, fire damage-over-time, status landing chance, and
## Comedy's luck.
##
## Each check drives or inspects the real consumer. An earlier phase of this
## work "verified" bonuses by calling an accessor the same commit added, which
## passed even with every consumer unwired — so these assert the call site where
## the path cannot be driven headlessly.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 4


func _ready() -> void:
	_check_burning_damage_scales_with_fire_magic()
	_check_status_chance_scales_with_ritual()
	_check_mace_stun_chance()
	_check_luck_feeds_crit_and_loot()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway"
			% [checks_run, EXPECTED_CHECKS])
		failures += 1
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _fail(m: String) -> void:
	printerr("  FAIL: ", m)
	failures += 1


func _done() -> void:
	checks_run += 1


func _char(skills: Dictionary) -> Dictionary:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["skills"] = skills
	CharacterSystem.update_derived_stats(c)
	return c


func _assert_call_site(path: String, needle: String, message: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("cannot read %s" % path)
		return
	var src := f.get_as_text()
	f.close()
	if not src.contains(needle):
		_fail(message)


## Fire magic makes your burns bite harder. The DoT tick already keeps the
## status's source and uses it for Fan_the_Flames, so this hooks the same place.
func _check_burning_damage_scales_with_fire_magic() -> void:
	var pyromancer: Dictionary = _char({"fire_magic": 10})
	if pyromancer["derived"].get("burning_damage_pct", 0.0) <= 0.0:
		_fail("Fire Magic 10 produced no burning_damage_pct")
	if _char({"swords": 10})["derived"].get("burning_damage_pct", 0.0) != 0.0:
		_fail("a swordsman has burning_damage_pct")
	_assert_call_site("res://scripts/autoload/combat_manager.gd",
		'burning_damage_pct', "the fire DoT tick never reads burning_damage_pct")
	_done()


## Ritual makes status effects land more often.
func _check_status_chance_scales_with_ritual() -> void:
	var ritualist: Dictionary = _char({"ritual": 10})
	var pct: float = ritualist["derived"].get("status_effect_chance_pct", 0.0)
	if pct <= 0.0:
		_fail("Ritual 10 produced no status_effect_chance_pct")

	var base_chance: int = 20
	var boosted: int = CombatManager.effective_status_chance(ritualist, base_chance)
	if boosted <= base_chance:
		_fail("Ritual 10 turned a %d%% status chance into %d%%" % [base_chance, boosted])
	if CombatManager.effective_status_chance(ritualist, 0) != 0:
		_fail("a zero status chance was raised above zero — an effect with no "
			+ "chance to apply must stay that way")
	if CombatManager.effective_status_chance(ritualist, 100) > 100:
		_fail("status chance exceeded 100%")
	_done()


## Maces stun. The skill has carried a stun_chance table since before there was
## anywhere to read it.
func _check_mace_stun_chance() -> void:
	var crusher: Dictionary = _char({"maces": 10})
	if crusher["derived"].get("stun_chance_pct", 0.0) <= 0.0:
		_fail("Maces 10 produced no stun_chance_pct")
	_assert_call_site("res://scripts/autoload/combat_manager.gd",
		'stun_chance_pct', "nothing in combat reads stun_chance_pct")
	_done()


## Comedy's luck feeds the two things luck actually drives.
func _check_luck_feeds_crit_and_loot() -> void:
	var plain: Dictionary = _char({"swords": 10})
	var lucky: Dictionary = _char({"comedy": 10})
	if lucky["derived"].get("crit_chance", 0.0) <= plain["derived"].get("crit_chance", 0.0):
		_fail("Comedy 10 gave crit_chance %.1f, a swordsman has %.1f"
			% [lucky["derived"].get("crit_chance", 0.0),
			   plain["derived"].get("crit_chance", 0.0)])
	if lucky["derived"].get("loot_chance_pct", 0.0) <= 0.0:
		_fail("Comedy 10 gave no loot_chance_pct")
	_done()
