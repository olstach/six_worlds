extends Node
## Headless verification for the four skill payouts that modify a combat roll
## or magnitude: mace stuns, fire damage-over-time, status landing chance, and
## Comedy's luck — and the four wound/body perks that change what a hit leaves
## behind: Hardened, Stubborn Body, Undead Hunter and Iron Cortex.
##
## Each check drives or inspects the real consumer. An earlier phase of this
## work "verified" bonuses by calling an accessor the same commit added, which
## passed even with every consumer unwired — so these assert the call site where
## the path cannot be driven headlessly.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 8


func _ready() -> void:
	_check_burning_damage_scales_with_fire_magic()
	_check_status_chance_scales_with_ritual()
	_check_mace_stun_chance()
	_check_luck_feeds_crit_and_loot()

	_check_hardened()
	_check_stubborn_body()
	_check_undead_hunter()
	_check_iron_cortex()

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


# ── Wound/body perks ─────────────────────────────────────────────────────────

## A CombatUnit carrying a blank character, for the helpers that take a unit.
## No grid is needed: nothing here moves or targets by position.
func _unit(team: int, tags: Array = []) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe"
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["tags"] = tags
	add_child(unit)
	return unit


## True when `perk_id` is on offer to `character` right now.
func _eligible(character: Dictionary, perk_id: String) -> bool:
	return perk_id in PerkSystem.get_eligible_perks(character)


## Count how many times `needle` appears in a source file.
func _count_in_source(path: String, needle: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("cannot read %s" % path)
		return 0
	var src := f.get_as_text()
	f.close()
	return src.count(needle)


## Hardened: Armor 5 and Constitution 14; a crit wound is negated half the time.
## The roll is injected so the check is not itself a coin flip. Both crit-wound
## paths (the main attack and each extra arm) must ask the same helper — the arm
## chain used to roll its own wound with no Hardened check at all.
func _check_hardened() -> void:
	var c: Dictionary = _char({"armor": 5})
	c["attributes"]["constitution"] = 13
	if _eligible(c, "hardened"):
		_fail("Hardened offered at Constitution 13")
	c["attributes"]["constitution"] = 14
	if not _eligible(c, "hardened"):
		_fail("Hardened not offered at Armor 5 / Constitution 14")

	var unit := _unit(0)
	if CombatManager._crit_wound_negated(unit, 0.0):
		_fail("a crit wound was negated for a unit without Hardened")
	PerkSystem.grant_perk(unit.character_data, "hardened")
	if not CombatManager._crit_wound_negated(unit, 0.49):
		_fail("Hardened did not negate a crit wound on a roll of 0.49")
	if CombatManager._crit_wound_negated(unit, 0.5):
		_fail("Hardened negated a crit wound on a roll of 0.5 (should be 50%, not more)")
	var sites: int = _count_in_source("res://scripts/autoload/combat_manager.gd",
		"_crit_wound_negated(defender)")
	if sites < 2:
		_fail("only %d crit-wound path(s) ask _crit_wound_negated — expected the main attack and the multi-arm chain" % sites)
	unit.queue_free()
	_done()


## Stubborn Body: +1 to every wound's escalation_rests. Deep Cut escalates after
## 2 untreated rests; with the perk it takes 3. The same delay can also come from
## `wound_escalation_delay` on the character, and a never-escalating wound must
## stay never-escalating however much delay is added.
func _check_stubborn_body() -> void:
	var c: Dictionary = _char({"armor": 8})
	c["attributes"]["constitution"] = 15
	PerkSystem.grant_perk(c, "hardened")
	if not _eligible(c, "stubborn_body"):
		_fail("Stubborn Body not offered at Armor 8 / Constitution 15 / Hardened")
	c["attributes"]["constitution"] = 14
	if _eligible(c, "stubborn_body"):
		_fail("Stubborn Body offered at Constitution 14")

	var plain: Dictionary = _char({})
	WoundSystem.apply_wound(plain, "deep_cut")
	WoundSystem.tick_wounds(plain)
	WoundSystem.tick_wounds(plain)
	if plain["wounds"][0]["id"] == "deep_cut":
		_fail("Deep Cut did not escalate after 2 rests without Stubborn Body — the baseline this check measures against has moved")

	var stubborn: Dictionary = _char({})
	PerkSystem.grant_perk(stubborn, "stubborn_body")
	WoundSystem.apply_wound(stubborn, "deep_cut")
	WoundSystem.tick_wounds(stubborn)
	WoundSystem.tick_wounds(stubborn)
	if stubborn["wounds"][0]["id"] != "deep_cut":
		_fail("Stubborn Body: Deep Cut escalated after 2 rests, should take 3")
	WoundSystem.tick_wounds(stubborn)
	if stubborn["wounds"][0]["id"] == "deep_cut":
		_fail("Stubborn Body: Deep Cut still had not escalated after 3 rests")

	var delayed: Dictionary = _char({})
	delayed["wound_escalation_delay"] = 1
	if WoundSystem.get_escalation_threshold(delayed, "deep_cut") != 3:
		_fail("wound_escalation_delay 1 did not make Deep Cut take 3 rests")
	# Find a wound that never escalates and make sure a delay leaves it alone.
	for wid in WoundSystem.WOUND_TYPES:
		if int(WoundSystem.WOUND_TYPES[wid].get("escalation_rests", 0)) == 0:
			if WoundSystem.get_escalation_threshold(stubborn, wid) != 0:
				_fail("Stubborn Body made never-escalating '%s' escalate" % wid)
			break
	_done()


## Undead Hunter: immune to disease from undead or diseased attackers — and only
## from them. Both the main-attack proc and the arm-chain proc have to pass the
## attacker in, or the check has nobody to compare against.
func _check_undead_hunter() -> void:
	var c: Dictionary = _char({"earth_magic": 3})
	if not _eligible(c, "undead_hunter"):
		_fail("Undead Hunter not offered at Earth Magic 3")

	var hunter := _unit(0)
	var plain := _unit(0)
	PerkSystem.grant_perk(hunter.character_data, "undead_hunter")
	var ghoul := _unit(1, ["undead"])
	var leper := _unit(1, ["diseased"])
	var bandit := _unit(1, ["biological"])

	if not CombatManager._check_perk_status_immunity(hunter, "diseased", ghoul):
		_fail("Undead Hunter caught a disease from an undead attacker")
	if not CombatManager._check_perk_status_immunity(hunter, "diseased", leper):
		_fail("Undead Hunter caught a disease from a diseased attacker")
	if CombatManager._check_perk_status_immunity(hunter, "diseased", bandit):
		_fail("Undead Hunter refused a disease from a living, healthy source — the immunity is only against undead and diseased enemies")
	if CombatManager._check_perk_status_immunity(hunter, "diseased", null):
		_fail("Undead Hunter refused a disease with no source")
	if CombatManager._check_perk_status_immunity(plain, "diseased", ghoul):
		_fail("a unit without Undead Hunter was immune to an undead's disease")

	var sites: int = _count_in_source("res://scripts/autoload/combat_manager.gd",
		'_check_perk_status_immunity(defender, "diseased", attacker)')
	if sites < 2:
		_fail("only %d disease-on-hit path(s) pass the attacker to the immunity check — expected the main attack and the multi-arm chain" % sites)
	for u in [hunter, plain, ghoul, leper, bandit]:
		u.queue_free()
	_done()


## Iron Cortex: arm 2 always fires; arm 3+ keep their Finesse roll. Gated on
## Finesse 12 alone — it was once keyed to a "finesse" skill that does not
## exist, which made it impossible to learn.
func _check_iron_cortex() -> void:
	var c: Dictionary = _char({})
	c["attributes"]["finesse"] = 11
	if _eligible(c, "iron_cortex"):
		_fail("Iron Cortex offered at Finesse 11")
	c["attributes"]["finesse"] = 12
	if not _eligible(c, "iron_cortex"):
		_fail("Iron Cortex not offered at Finesse 12")

	var body: Dictionary = _char({})
	body["attributes"]["finesse"] = 10
	var arm2: float = CombatManager.arm_chain_fire_chance(body, 2)
	var arm3: float = CombatManager.arm_chain_fire_chance(body, 3)
	if arm2 >= 100.0:
		_fail("arm 2 fires at %.0f%% at Finesse 10 without Iron Cortex" % arm2)
	PerkSystem.grant_perk(body, "iron_cortex")
	var cortex_arm2: float = CombatManager.arm_chain_fire_chance(body, 2)
	var cortex_arm3: float = CombatManager.arm_chain_fire_chance(body, 3)
	if cortex_arm2 < 100.0:
		_fail("Iron Cortex: arm 2 fires at %.0f%%, should always fire" % cortex_arm2)
	if cortex_arm3 != arm3:
		_fail("Iron Cortex changed arm 3's chance (%.0f%% to %.0f%%) — arms 3+ still roll" % [arm3, cortex_arm3])
	PerkSystem.grant_perk(body, "akimbo")
	if CombatManager.arm_chain_fire_chance(body, 3) != arm3 + 20.0:
		_fail("Akimbo's +20 no longer reaches arm 3 once Iron Cortex is owned")
	_done()
