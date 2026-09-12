extends Node
## Headless verification for party-wide skill bonuses.
##
## Run: godot --headless res://tools/verify_party_bonuses.tscn
##
## The interesting failures here are not arithmetic. They are "the best member's
## skill never reached anyone else" and "it reached them once and then went
## stale", so every check works through the real party and asserts on the number
## a consumer actually reads.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 9


func _ready() -> void:
	_check_best_member_not_sum()
	_check_no_party_no_bonus()
	_check_unskilled_member_contributes_nothing()
	_check_refresh_on_skill_change()
	_check_refresh_on_party_change()
	_check_party_healing_reaches_heal()
	_check_poison_resistance_reaches_resistances()
	_check_self_stats_are_not_party_wide()
	_check_derived_stats_do_not_accumulate()

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


## Build a party from scratch. CharacterSystem.party is the live array every
## consumer reads, so the tests use it rather than a stand-in.
func _party(members: Array) -> void:
	CharacterSystem.party.clear()
	for skills in members:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["skills"] = skills
		CharacterSystem.party.append(c)
	CharacterSystem.update_party_derived_stats()


func _member(i: int) -> Dictionary:
	return CharacterSystem.party[i]


# ── The rule ─────────────────────────────────────────────────────────────────

## Four medics are not four times one medic. Best member, matching the rule the
## game already uses for party skill checks — and matching
## map_manager._get_best_party_discovery_bonus(), which reached for it first.
func _check_best_member_not_sum() -> void:
	_party([{"medicine": 10}, {"medicine": 10}, {"medicine": 10}])
	var three: float = PartyBonuses.best("party_healing_pct")
	_party([{"medicine": 10}])
	var one: float = PartyBonuses.best("party_healing_pct")
	if absf(three - one) > 0.001:
		_fail("three medics gave %.1f where one gives %.1f — this is summing"
			% [three, one])
	if one <= 0.0:
		_fail("a Medicine-10 party gave no healing bonus at all")
	_done()


func _check_no_party_no_bonus() -> void:
	CharacterSystem.party.clear()
	if PartyBonuses.best("party_healing_pct") != 0.0:
		_fail("an empty party produced a bonus")
	_done()


func _check_unskilled_member_contributes_nothing() -> void:
	_party([{"swords": 10}])
	if PartyBonuses.best("party_healing_pct") != 0.0:
		_fail("a party with no Medicine produced a healing bonus")
	_done()


# ── Staying fresh ────────────────────────────────────────────────────────────

## The failure this guards against is silent: B levels Medicine and A's sheet
## keeps yesterday's number, with nothing anywhere going red.
func _check_refresh_on_skill_change() -> void:
	_party([{"swords": 5}, {"medicine": 1}])
	var before: float = _member(0)["derived"].get("healing_pct", 0.0)

	CharacterSystem.set_skill_level(_member(1), "medicine", 10)
	var after: float = _member(0)["derived"].get("healing_pct", 0.0)

	if after <= before:
		_fail("the other member levelled Medicine 1 -> 10 and the swordsman's "
			+ "healing_pct stayed at %.1f" % after)
	_done()


func _check_refresh_on_party_change() -> void:
	# Leadership buys room for other people now, so a party that intends to
	# recruit needs someone who can lead. A Leadership-0 party travels alone
	# and add_companion() correctly refuses.
	_party([{"swords": 5, "leadership": 3}])
	var alone: float = _member(0)["derived"].get("healing_pct", 0.0)

	var medic: Dictionary = CharacterSystem.create_blank_character()
	medic["skills"] = {"medicine": 10}
	CharacterSystem.add_companion(medic)
	var with_medic: float = _member(0)["derived"].get("healing_pct", 0.0)
	if with_medic <= alone:
		_fail("recruiting a Medicine-10 medic left healing_pct at %.1f" % with_medic)

	CharacterSystem.remove_companion(1)
	var after_leaving: float = _member(0)["derived"].get("healing_pct", 0.0)
	if absf(after_leaving - alone) > 0.001:
		_fail("the medic left and healing_pct stayed at %.1f, expected %.1f"
			% [after_leaving, alone])
	_done()


# ── Reaching the consumer ────────────────────────────────────────────────────

## Landing in `derived` is not the same as being used. This is the distinction
## that let five stats sit dead in this codebase at once.
func _check_party_healing_reaches_heal() -> void:
	_party([{"swords": 5}, {"medicine": 10}])
	var unit := CombatUnit.new()
	unit.character_data = _member(0)
	unit.max_hp = 100
	unit.current_hp = 10
	add_child(unit)
	unit.heal(20)
	var healed: int = unit.current_hp - 10
	unit.free()
	if healed <= 20:
		_fail("a Medicine-10 party healed %d from a 20 heal — the bonus never "
			% healed + "reached CombatUnit.heal()")
	_done()


func _check_poison_resistance_reaches_resistances() -> void:
	_party([{"swords": 5}, {"medicine": 10}])
	var resists: Dictionary = _member(0)["derived"].get("resistances", {})
	for damage_type in ["poison", "disease"]:
		if resists.get(damage_type, 0) <= 0:
			_fail("a Medicine-10 party gave the swordsman no %s resistance"
				% damage_type)
	_done()


## A `party_` prefix is what makes a bonus spread. A self-only stat must not,
## or every skill silently becomes a party aura.
func _check_self_stats_are_not_party_wide() -> void:
	# Compare the same character with and without the yogi. Asserting the
	# swordsman has zero would be wrong: Swords is a Space-element skill, so
	# space affinity already pays him some mental resistance on his own.
	_party([{"swords": 5}])
	var alone: float = _member(0)["derived"].get("mental_resistance_pct", 0.0)

	_party([{"swords": 5}, {"yoga": 10}])
	var with_yogi: float = _member(0)["derived"].get("mental_resistance_pct", 0.0)
	var yogi_own: float = _member(1)["derived"].get("mental_resistance_pct", 0.0)

	if yogi_own <= alone:
		_fail("the yogi's own mental_resistance_pct is %.1f — Yoga pays nothing"
			% yogi_own)
	if absf(with_yogi - alone) > 0.001:
		_fail("the swordsman went from %.1f to %.1f mental_resistance_pct when a "
			% [alone, with_yogi] + "yogi joined — a self stat spread party-wide")
	_done()


## update_derived_stats() must RECOMPUTE, not add to what it computed last time.
##
## Stats assigned fresh (`derived.max_hp = 100 + ...`) were always safe. Stats
## accumulated in place (`derived[k] = derived.get(k, 0) + ...`) were not, and
## nothing reset them: mana_cost_reduction grew by its full value on every call,
## so spells got monotonically cheaper until they were free. The function runs
## on level-up, equip, rest and party change, so this compounded quietly.
func _check_derived_stats_do_not_accumulate() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["skills"] = {"air_magic": 10, "armor": 10, "yoga": 10, "medicine": 10, "grace": 10}

	CharacterSystem.update_derived_stats(c)
	var first: Dictionary = c["derived"].duplicate(true)
	for _i in 4:
		CharacterSystem.update_derived_stats(c)

	for key in first:
		if key in ["current_hp", "current_mana", "current_stamina"]:
			continue  # these track a pool and may legitimately move
		var before = first[key]
		var after = c["derived"][key]
		if typeof(before) == TYPE_DICTIONARY:
			if before.hash() != after.hash():
				_fail("derived.%s changed over repeated recomputes: %s -> %s"
					% [key, before, after])
		elif before != after:
			_fail("derived.%s accumulates: %s after one call, %s after five"
				% [key, before, after])
	_done()
