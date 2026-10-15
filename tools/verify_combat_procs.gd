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
const EXPECTED_CHECKS: int = 7


func _ready() -> void:
	_check_burning_damage_scales_with_fire_magic()
	_check_status_chance_scales_with_ritual()
	_check_mace_stun_chance()
	_check_luck_feeds_crit_and_loot()
	_check_status_chance_reaches_every_roll_site()
	_check_ritual_raises_status_save_dc()
	_check_loot_chance_reaches_the_jackpot()

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

	var base_chance: float = 20.0
	var boosted: float = CombatManager.effective_status_chance(ritualist, base_chance)
	if boosted <= base_chance:
		_fail("Ritual 10 turned a %.1f%% status chance into %.1f%%" % [base_chance, boosted])
	if CombatManager.effective_status_chance(ritualist, 0.0) != 0.0:
		_fail("a zero status chance was raised above zero — an effect with no "
			+ "chance to apply must stay that way")
	if CombatManager.effective_status_chance(ritualist, 100.0) > 100.0:
		_fail("status chance exceeded 100%")
	# Weapon procs carry fractional chances; the helper must not round them
	# away before Ritual has had its say.
	var unskilled: float = CombatManager.effective_status_chance(_char({}), 7.5)
	if not is_equal_approx(unskilled, 7.5):
		_fail("a 7.5%% proc with no Ritual came out as %.2f%%" % unskilled)
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


## The helper existing proves nothing if only one site calls it — which was the
## state of things for a month: oils read Ritual, and spells, bombs and weapon
## procs, the three places statuses mostly come from, did not.
func _check_status_chance_reaches_every_roll_site() -> void:
	var f := FileAccess.open("res://scripts/autoload/combat_manager.gd", FileAccess.READ)
	if f == null:
		_fail("cannot read combat_manager.gd")
		_done()
		return
	var src := f.get_as_text()
	f.close()
	# One definition plus oils, spell `status` effects, bombs and weapon procs.
	var sites: int = src.count("effective_status_chance(") - 1
	if sites < 4:
		_fail("effective_status_chance is called from %d place(s), expected at least "
			% sites + "4 (oils, spell status effects, bombs, weapon procs)")
	if not src.contains("wielder_data, float(passive[key])"):
		_fail("weapon status procs do not go through effective_status_chance")
	_done()


## A status that lands on a failed save has no percentage to multiply. Ritual
## goes onto the DC instead, at SaveSystem's own rate of five percentage points
## per d20 point — the same rate Yoga's mental resistance comes off it at.
## Driven through the real _skill_save and _spell_save so the DC is the one a
## target would actually roll against.
func _check_ritual_raises_status_save_dc() -> void:
	var ritualist := _unit({"ritual": 10})
	var plain := _unit({})
	var target := _unit({})

	var pct: float = ritualist.character_data["derived"].get("status_effect_chance_pct", 0.0)
	var expected: int = int(pct / SaveSystem.PERCENT_PER_ROLL_POINT)
	if expected <= 0:
		_fail("Ritual 10 (%.1f%%) converts to no DC points at all" % pct)
	if CombatManager.status_save_dc_bonus(ritualist) != expected:
		_fail("status_save_dc_bonus = %d, expected %d (%.1f%% / %.0f)"
			% [CombatManager.status_save_dc_bonus(ritualist), expected,
			   pct, SaveSystem.PERCENT_PER_ROLL_POINT])
	if CombatManager.status_save_dc_bonus(plain) != 0:
		_fail("a character with no Ritual raises status DCs")

	# Active skills: every caller gates a status or a debuff, so always.
	var skill_gap: int = int(CombatManager._skill_save(ritualist, target, {}, "focus").dc) \
		- int(CombatManager._skill_save(plain, target, {}, "focus").dc)
	if skill_gap != expected:
		_fail("Ritual moved an active skill's status DC by %d, expected %d"
			% [skill_gap, expected])

	# Spells: only when the save gates a status.
	var spell: Dictionary = {"dc_stat": "focus"}
	var gated_gap: int = int(CombatManager._spell_save(ritualist, target, spell, "focus", true).dc) \
		- int(CombatManager._spell_save(plain, target, spell, "focus", true).dc)
	if gated_gap != expected:
		_fail("Ritual moved a status-gating spell save by %d, expected %d"
			% [gated_gap, expected])
	var plain_gap: int = int(CombatManager._spell_save(ritualist, target, spell, "focus").dc) \
		- int(CombatManager._spell_save(plain, target, spell, "focus").dc)
	if plain_gap != 0:
		_fail("Ritual moved a save with no status riding on it by %d" % plain_gap)

	# And the decision of which spells count.
	if not CombatManager._save_gates_status({"on_failed_save": {"statuses": ["Silenced"]}}):
		_fail("a save that silences on failure is not treated as gating a status")
	if not CombatManager._save_gates_status({"on_failed_save": {"random_one_of": ["Feared"]}}):
		_fail("a save that draws a random status is not treated as gating one")
	if CombatManager._save_gates_status({"on_failed_save": {"instant_kill": true}}):
		_fail("an instant-kill save counts as a status — Ritual would make executions easier")

	for u in [ritualist, plain, target]:
		u.free()
	_done()


## Comedy's other half. loot_chance_pct was written by Comedy and by the
## Shivering Cairn shrine and read by nothing — this asserts the jackpot reads it.
func _check_loot_chance_reaches_the_jackpot() -> void:
	var plain: Dictionary = _char({"swords": 10})
	var lucky: Dictionary = _char({"comedy": 10})
	var base: float = CombatManager.luck_jackpot_chance(10, [plain])
	var boosted: float = CombatManager.luck_jackpot_chance(10, [plain, lucky])
	if boosted <= base:
		_fail("Comedy 10 in the party left the jackpot at %.4f (without: %.4f)"
			% [boosted, base])
	var pct: float = lucky["derived"].get("loot_chance_pct", 0.0)
	if not is_equal_approx(boosted, base * (1.0 + pct / 100.0)):
		_fail("jackpot %.4f is not %.4f boosted by %.1f%%" % [boosted, base, pct])
	# Best member, not the sum.
	if not is_equal_approx(CombatManager.luck_jackpot_chance(10, [lucky, lucky]), boosted):
		_fail("two comedians stacked their loot_chance_pct")
	# The boost lands after the Luck cap, so the luckiest party still gains.
	if CombatManager.luck_jackpot_chance(40, [lucky]) <= CombatManager.luck_jackpot_chance(40, [plain]):
		_fail("the Luck cap swallowed Comedy's boost for a high-Luck party")
	_done()


func _unit(skills: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.unit_name = "Probe"
	u.character_data = _char(skills)
	add_child(u)
	return u
