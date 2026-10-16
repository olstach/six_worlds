extends Node
## Headless verification for the five skill payouts that modify a combat roll
## or magnitude: mace stuns, fire damage-over-time, status landing chance,
## Enchantment's status duration and Comedy's luck — and the four wound/body
## perks that change what a hit leaves behind: Hardened, Stubborn Body, Undead
## Hunter and Iron Cortex.
##
## Each check drives or inspects the real consumer. An earlier phase of this
## work "verified" bonuses by calling an accessor the same commit added, which
## passed even with every consumer unwired — so these assert the call site where
## the path cannot be driven headlessly.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 16


func _ready() -> void:
	_check_burning_damage_scales_with_fire_magic()
	_check_status_chance_scales_with_ritual()
	_check_mace_stun_chance()
	_check_luck_feeds_crit_and_loot()
	_check_status_chance_reaches_every_roll_site()
	_check_ritual_raises_status_save_dc()
	_check_ritual_reaches_auras_retaliation_and_perk_procs()
	_check_loot_chance_reaches_the_jackpot()
	_check_effective_luck_reaches_the_loot()
	_check_luck_weights_a_lucky_find()
	_check_on_hit_procs_spare_the_fallen()
	_check_enchantment_duration_counts_once()

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


## Auras, retaliation and the hard-coded perk procs (Magnetizing Aura, Play
## Dirty, Put Your Weight Into It) roll on a 0.0-1.0 scale and used to skip
## Ritual entirely. They go through ritual_chance now; a ground zone, which
## has no owner, passes null and keeps its chance as written.
func _check_ritual_reaches_auras_retaliation_and_perk_procs() -> void:
	var ritualist := _unit({"ritual": 10})
	var plain := _unit({})
	if CombatManager.ritual_chance(ritualist, 0.25) <= 0.25:
		_fail("Ritual 10 left a 25%% aura/perk chance at %.3f"
			% CombatManager.ritual_chance(ritualist, 0.25))
	if not is_equal_approx(CombatManager.ritual_chance(plain, 0.25), 0.25):
		_fail("no Ritual changed a 25% chance")
	if not is_equal_approx(CombatManager.ritual_chance(null, 0.3), 0.3):
		_fail("an ownerless ground zone's chance was changed")
	if CombatManager.ritual_chance(ritualist, 1.0) != 1.0:
		_fail("a certain effect stopped being certain")
	var f := FileAccess.open("res://scripts/autoload/combat_manager.gd", FileAccess.READ)
	var src := f.get_as_text() if f != null else ""
	for needle in ["ritual_chance(source, chance)", "status_save_dc_bonus(source)",
			'ritual_chance(defender, float(retal.get("status_chance"',
			"ritual_chance(defender, 0.25)", "ritual_chance(attacker, 0.15)",
			"ritual_chance(attacker, 0.20)"]:
		if not src.contains(needle):
			_fail("combat_manager.gd no longer contains '%s' — a status roll "
				% needle + "has slipped out from under Ritual")
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


## The jackpot read attributes.luck, so Luck from gear, traits and shrines
## counted for nothing. It reads the effective number in derived now.
func _check_effective_luck_reaches_the_loot() -> void:
	var c: Dictionary = _char({})
	c["attributes"]["luck"] = 10
	var saved_buffs: Array = GameState.active_map_buffs.duplicate(true)
	GameState.active_map_buffs = [{"stat": "luck", "amount": 6, "combats_remaining": 1}]
	CharacterSystem.update_derived_stats(c)
	GameState.active_map_buffs = saved_buffs
	if int(c["derived"].get("luck", 0)) != 16:
		_fail("a +6 Luck shrine left derived luck at %s, expected 16"
			% str(c["derived"].get("luck", "missing")))
	var best: int = CombatManager.best_party_luck([c])
	if best != 16:
		_fail("best_party_luck read %d — the shrine's Luck never reached the loot" % best)
	elif CombatManager.luck_jackpot_chance(best, [c]) <= CombatManager.luck_jackpot_chance(10, [c]):
		_fail("sixteen effective Luck did not raise the jackpot chance")
	CharacterSystem.update_derived_stats(c)
	_done()


## Luck's rarity weighting was dead code — nothing called it. A won fight now
## rolls a lucky find at the jackpot's odds, its rarity tilted by Luck.
func _check_luck_weights_a_lucky_find() -> void:
	# More Luck, a larger share of rare-and-better.
	var base: Dictionary = CombatManager._get_modified_rarity_weights(1.0, 10)
	var lucky: Dictionary = CombatManager._get_modified_rarity_weights(1.0, 25)
	var share := func(w: Dictionary) -> float:
		var total: float = 0.0
		for r in w:
			total += float(w[r])
		return float(w["rare"] + w["epic"] + w["legendary"]) / total
	if share.call(lucky) <= share.call(base):
		_fail("Luck 25 gave rare+ share %.3f, Luck 10 gives %.3f"
			% [share.call(lucky), share.call(base)])

	# And the roll is actually made: with the chance pushed past 1 the fight
	# must turn up a piece of equipment nobody was carrying.
	var saved_party: Array[Dictionary] = CharacterSystem.party.duplicate()
	var saved_units: Array[Node] = CombatManager.all_units.duplicate()
	CombatManager.all_units.clear()
	var c: Dictionary = _char({})
	c["derived"]["loot_chance_pct"] = 100000.0
	CharacterSystem.party.clear()
	CharacterSystem.party.append(c)
	var drops: Array[String] = CombatManager._generate_loot_drops(1, 1.0, 10)
	CharacterSystem.party.clear()
	CharacterSystem.party.append_array(saved_party)
	CombatManager.all_units.append_array(saved_units)
	var equipment_types: Array[String] = CombatManager._lucky_find_types()
	var found := false
	for id in drops:
		if str(ItemSystem.get_item(id).get("type", "")) in equipment_types:
			found = true
	if not found:
		_fail("a certain lucky find produced no equipment: %s" % str(drops))
	_done()


## Enchantment lengthens spell statuses exactly once.
##
## The duration bonus used to be stated twice — `int(level / 2)` inside
## _calculate_status_duration, and a parallel table key nothing read. Now the
## table (`effect_duration_turns`) is the only statement and the function reads
## it. Wiring the table without deleting the formula (or restoring the formula
## beside the table) would double it; this pins the curve so either shows.
## Spellpower is held at 0 so only Enchantment moves the number.
func _check_enchantment_duration_counts_once() -> void:
	var spell: Dictionary = {"duration": "spellpower"}
	for level in range(0, 11):
		var u: CombatUnit = _unit({"enchantment": level} if level > 0 else {})
		var table_turns: int = int(u.character_data["derived"].get("effect_duration_turns", 0))
		var expected: int = 2 + int(level / 2)
		var got: int = CombatManager._calculate_status_duration(u, spell, 0)
		if table_turns != int(level / 2):
			_fail("Enchantment %d: effect_duration_turns is %d, expected %d"
				% [level, table_turns, int(level / 2)])
		if got != expected:
			_fail("Enchantment %d: a spellpower-duration status lasts %d turns, "
				% [level, got] + "expected %d (base 2 + table %d) — counted twice?"
				% [expected, table_turns])
		u.queue_free()
	_done()


func _unit(skills: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.unit_name = "Probe"
	u.character_data = _char(skills)
	add_child(u)
	return u

# ── Wound/body perks ─────────────────────────────────────────────────────────

## A CombatUnit carrying a blank character, for the helpers that take a unit.
## No grid is needed: nothing here moves or targets by position.
func _team_unit(team: int, tags: Array = []) -> CombatUnit:
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


## Both the primary hit and the extra arms must land through _resolve_hit_procs
## — that is what makes the single crit-wound and disease paths cover both.
func _expect_shared_hit_path() -> void:
	var calls: int = _count_in_source("res://scripts/autoload/combat_manager.gd",
		"_resolve_hit_procs(attacker, defender, result")
	if calls < 2:
		_fail("only %d call(s) to _resolve_hit_procs — the main hit and the arm chain should both use it" % calls)


## Hardened: Armor 5 and Constitution 14; a crit wound is negated half the time.
## The roll is injected so the check is not itself a coin flip. The main attack
## and each extra arm must both reach the same helper — the arm chain used to
## roll its own wound with no Hardened check at all. Since 2026-10-15 there is
## ONE crit-wound path, in _process_weapon_on_hit_procs, which both reach
## through _resolve_hit_procs; a second copy appearing is the drift coming back.
func _check_hardened() -> void:
	var c: Dictionary = _char({"armor": 5})
	c["attributes"]["constitution"] = 13
	if _eligible(c, "hardened"):
		_fail("Hardened offered at Constitution 13")
	c["attributes"]["constitution"] = 14
	if not _eligible(c, "hardened"):
		_fail("Hardened not offered at Armor 5 / Constitution 14")

	var unit := _team_unit(0)
	if CombatManager._crit_wound_negated(unit, 0.0):
		_fail("a crit wound was negated for a unit without Hardened")
	PerkSystem.grant_perk(unit.character_data, "hardened")
	if not CombatManager._crit_wound_negated(unit, 0.49):
		_fail("Hardened did not negate a crit wound on a roll of 0.49")
	if CombatManager._crit_wound_negated(unit, 0.5):
		_fail("Hardened negated a crit wound on a roll of 0.5 (should be 50%, not more)")
	var sites: int = _count_in_source("res://scripts/autoload/combat_manager.gd",
		"_crit_wound_negated(defender)")
	if sites != 1:
		_fail("%d crit-wound path(s) ask _crit_wound_negated — expected exactly one, shared by the main attack and the arm chain" % sites)
	_expect_shared_hit_path()
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
## from them. The one disease-on-hit proc (shared by the main attack and the
## arm chain) has to pass the attacker in, or the check has nobody to compare
## against.
func _check_undead_hunter() -> void:
	var c: Dictionary = _char({"earth_magic": 3})
	if not _eligible(c, "undead_hunter"):
		_fail("Undead Hunter not offered at Earth Magic 3")

	var hunter := _team_unit(0)
	var plain := _team_unit(0)
	PerkSystem.grant_perk(hunter.character_data, "undead_hunter")
	var ghoul := _team_unit(1, ["undead"])
	var leper := _team_unit(1, ["diseased"])
	var bandit := _team_unit(1, ["biological"])

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
	if sites != 1:
		_fail("%d disease-on-hit path(s) pass the attacker to the immunity check — expected exactly one, shared by the main attack and the arm chain" % sites)
	_expect_shared_hit_path()
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


## The blow that drops a unit must not go on to stun or bleed the body. Every
## on-hit proc runs after the damage lands, and a bleeding-out unit keeps its
## statuses through a revive — so the stun used to wait for whoever picked them
## back up. Drives the real weapon-proc path (Trishula-style on_crit_status and
## a 100% bleed passive) against a fallen and a standing defender, then checks
## no on-hit function still applies a status to `defender` unguarded.
func _check_on_hit_procs_spare_the_fallen() -> void:
	var attacker := _team_unit(0)
	attacker.character_data["equipped_weapon"] = {"type": "mace", "name": "Probe mace",
		"on_crit_status": "Stunned", "passive": {"bleed_chance": 100}}
	var crit_hit := {"success": true, "hit": true, "crit": true, "damage": 5}

	var fallen := _team_unit(1)
	fallen.is_bleeding_out = true
	CombatManager._process_weapon_on_hit_procs(attacker, fallen, crit_hit.duplicate())
	if not fallen.status_effects.is_empty():
		_fail("on-hit procs landed on a bleeding-out defender: %s" % [fallen.status_effects])

	# The control: the same procs on someone still standing do land, so the
	# check above is not passing because nothing fires at all.
	var standing := _team_unit(1)
	CombatManager._process_weapon_on_hit_procs(attacker, standing, crit_hit.duplicate())
	if not standing.has_status("Stunned") or not standing.has_status("Bleeding"):
		_fail("weapon on-hit procs did not land on a living defender (%s)"
			% [standing.status_effects])

	# Every on-hit function goes through the guarded helper.
	var src := FileAccess.get_file_as_string("res://scripts/autoload/combat_manager.gd")
	for fn in ["func _process_on_hit_perks(", "func _process_weapon_on_hit_procs(",
			"func _process_ammo_special_effect("]:
		var start := src.find(fn)
		var stop := src.find("\nfunc ", start + 1)
		if start < 0:
			_fail("%s not found" % fn)
			continue
		if src.substr(start, stop - start).contains("_apply_status_effect(defender,"):
			_fail("%s) applies a status to the defender without the is_alive() guard "
				% fn.trim_suffix("(") + "— use _apply_on_hit_status()")

	for unit in [attacker, fallen, standing]:
		unit.queue_free()
	_done()
