extends Node
## Headless verification for SaveSystem.
##
## Run: godot --headless res://tools/verify_save_system.tscn
##
## Saves are random, so the odds are asserted two ways: exactly, against
## success_chance(), and by sampling roll() to confirm the dice agree with the
## maths. A distribution test alone would pass a formula that is subtly wrong;
## an exact test alone would pass a formula nothing actually rolls.
##
## Exits non-zero if any assertion fails.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 9


func _ready() -> void:
	_check_dc_construction()
	_check_tier_modifiers()
	_check_exact_odds()
	_check_odds_are_bounded()
	_check_roll_matches_the_maths()
	_check_result_shape()
	_check_save_bonus_converts_from_percent()
	_check_mental_resistance_only_on_focus()
	_check_unknown_attribute_is_loud()

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


func _unit(attrs: Dictionary) -> CombatUnit:
	var u := CombatUnit.new()
	u.unit_name = "Probe"
	u.character_data = CharacterSystem.create_blank_character()
	for k in attrs:
		u.character_data["attributes"][k] = attrs[k]
	add_child(u)
	return u


# ── DC construction ──────────────────────────────────────────────────────────

## DC = 10 + the attacker's attribute + the tier. The attacker's stat is in
## there so a stronger caster is genuinely harder to resist.
func _check_dc_construction() -> void:
	var caster := _unit({"focus": 12})
	if SaveSystem.dc_for(caster, "focus", "normal") != 22:
		_fail("dc_for(focus 12, normal) = %d, expected 22"
			% SaveSystem.dc_for(caster, "focus", "normal"))
	# "Constitution save at -20%" is four points of d20.
	if SaveSystem.dc_for(caster, "focus", "normal", -4) != 18:
		_fail("dc_for with a -4 modifier = %d, expected 18"
			% SaveSystem.dc_for(caster, "focus", "normal", -4))
	caster.free()
	_done()


func _check_tier_modifiers() -> void:
	var caster := _unit({"focus": 10})
	var expected := {"easy": 16, "normal": 20, "hard": 24, "brutal": 28}
	for tier in expected:
		var dc: int = SaveSystem.dc_for(caster, "focus", tier)
		if dc != expected[tier]:
			_fail("tier '%s' gave DC %d, expected %d" % [tier, dc, expected[tier]])
	caster.free()
	_done()


# ── The odds ─────────────────────────────────────────────────────────────────

## The three worked examples from the design document.
func _check_exact_odds() -> void:
	var cases := [
		{"con": 12, "dc": 22, "pct": 55.0, "why": "Con 12 vs an equal caster"},
		{"con": 18, "dc": 22, "pct": 85.0, "why": "Con 18 vs an equal caster"},
		{"con": 12, "dc": 30, "pct": 15.0, "why": "Con 12 vs Focus 20"},
	]
	for c in cases:
		var defender := _unit({"constitution": c["con"]})
		var pct: float = SaveSystem.success_chance(defender, "constitution", c["dc"]) * 100.0
		if absf(pct - c["pct"]) > 0.01:
			_fail("%s: %.1f%%, expected %.1f%%" % [c["why"], pct, c["pct"]])
		defender.free()
	_done()


## A save is never certain and never impossible, matching the event system's
## own "almost_impossible = nat-20 only" floor. Without this an overwhelming DC
## makes an effect literally unresistable, which is not a difficulty setting.
func _check_odds_are_bounded() -> void:
	var weak := _unit({"constitution": 3})
	var strong := _unit({"constitution": 30})
	var floor_pct: float = SaveSystem.success_chance(weak, "constitution", 99)
	var ceil_pct: float = SaveSystem.success_chance(strong, "constitution", 1)
	if absf(floor_pct - 0.05) > 0.001:
		_fail("an impossible DC gave %.3f, expected a 0.05 floor" % floor_pct)
	if absf(ceil_pct - 0.95) > 0.001:
		_fail("a trivial DC gave %.3f, expected a 0.95 ceiling" % ceil_pct)
	weak.free()
	strong.free()
	_done()


## The dice have to agree with the formula, or success_chance is documentation
## for something nothing rolls.
func _check_roll_matches_the_maths() -> void:
	var defender := _unit({"constitution": 12})
	var expected: float = SaveSystem.success_chance(defender, "constitution", 22)
	var passed := 0
	const N := 4000
	for i in N:
		if SaveSystem.roll(defender, "constitution", 22).success:
			passed += 1
	var observed := float(passed) / float(N)
	# 4000 samples at p=0.55 has a standard error near 0.008; 0.04 is five of
	# those, so this is loose enough never to flake and tight enough to catch a
	# formula that is off by a single point of d20 (which would be 0.05).
	if absf(observed - expected) > 0.04:
		_fail("rolled %.3f success over %d samples, formula says %.3f"
			% [observed, N, expected])
	defender.free()
	_done()


func _check_result_shape() -> void:
	var defender := _unit({"constitution": 12})
	var r: Dictionary = SaveSystem.roll(defender, "constitution", 22)
	for key in ["success", "roll", "total", "dc", "margin"]:
		if not r.has(key):
			_fail("roll() result is missing '%s'" % key)
	if r.has("roll") and (r.roll < 1 or r.roll > 20):
		_fail("roll() produced a d20 of %d" % r.roll)
	if r.has("total") and r.has("margin") and r.total - r.dc != r.margin:
		_fail("margin %d does not equal total %d - dc %d" % [r.margin, r.total, r.dc])
	defender.free()
	_done()


# ── Bonuses carried over from the percentage era ─────────────────────────────

## One point of d20 is five percentage points, so Booster Shot's "+25%
## resistance" is +5 to the roll. The conversion is exact, which is why no
## existing perk needed retuning.
func _check_save_bonus_converts_from_percent() -> void:
	var defender := _unit({"constitution": 12})
	var before: float = SaveSystem.success_chance(defender, "constitution", 22)
	defender.stat_modifiers = [{"stat": "save_bonus", "value": 25, "duration": 1}]
	var after: float = SaveSystem.success_chance(defender, "constitution", 22)
	if absf((after - before) - 0.25) > 0.001:
		_fail("+25 save_bonus moved the odds %.3f, expected 0.25" % (after - before))
	defender.free()
	_done()


## mental_resistance_pct is mental resistance: it applies to Focus saves and to
## nothing else, exactly as it did before the rework.
func _check_mental_resistance_only_on_focus() -> void:
	var defender := _unit({"focus": 12, "constitution": 12})
	# Measure the baseline rather than hand-computing it — the first version of
	# this test hardcoded 0.50 for what is actually 11/20, and failed a correct
	# implementation.
	var before: float = SaveSystem.success_chance(defender, "focus", 22)
	defender.character_data["derived"]["mental_resistance_pct"] = 15.0

	var focus_gain: float = SaveSystem.success_chance(defender, "focus", 22) - before
	if absf(focus_gain - 0.15) > 0.001:
		_fail("mental_resistance_pct moved a Focus save %.3f, expected 0.15" % focus_gain)

	var con_chance: float = SaveSystem.success_chance(defender, "constitution", 22)
	if absf(con_chance - 0.55) > 0.001:
		_fail("mental_resistance_pct leaked into a Constitution save (%.3f, expected 0.55)"
			% con_chance)
	defender.free()
	_done()


## An attribute nobody has is a data error, and must not silently resolve to a
## default that makes the save look like it worked.
func _check_unknown_attribute_is_loud() -> void:
	if SaveSystem.is_valid_save_type("constitution") != true:
		_fail("'constitution' rejected as a save type")
	if SaveSystem.is_valid_save_type("gumption") != false:
		_fail("'gumption' accepted as a save type")
	_done()
