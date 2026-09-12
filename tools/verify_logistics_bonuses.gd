extends Node
## Headless verification for the party-wide logistics and learning payouts.
##
## Run: godot --headless res://tools/verify_logistics_bonuses.tscn

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 4


func _ready() -> void:
	_check_skill_check_bonus_reaches_event_rolls()
	_check_supply_lasts_longer()
	_check_party_xp_gain()
	_check_travel_speed()

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


func _party(members: Array) -> void:
	CharacterSystem.party.clear()
	for skills in members:
		var c: Dictionary = CharacterSystem.create_blank_character()
		c["skills"] = skills
		CharacterSystem.party.append(c)
	CharacterSystem.update_party_derived_stats()


## A scholar in the party helps everyone's rolls. Event tier DCs cancel the
## attribute out, so this flat bonus is the only thing that can move an event
## roll's odds at all — which makes it the one payout worth having there.
func _check_skill_check_bonus_reaches_event_rolls() -> void:
	_party([{"swords": 5}])
	var plain: int = EventManager.get_party_roll_bonus()
	_party([{"swords": 5}, {"learning": 10}])
	var scholarly: int = EventManager.get_party_roll_bonus()
	if scholarly <= plain:
		_fail("a Learning-10 scholar added %d to party rolls (was %d)"
			% [scholarly, plain])
	# And the roll must actually use it. Driving make_choice() headlessly needs
	# a whole event, so assert the call site — the value being right is useless
	# if nothing adds it in.
	_assert_call_site("res://scripts/autoload/event_manager.gd",
		"roll + best_value + get_roll_bonus(roll_req)",
		"the event roll does not add the party bonus")
	_done()


## Logistics makes supplies go further, so a fixed cost consumes less.
func _check_supply_lasts_longer() -> void:
	# Drive the real consume_supply() and watch the stock, rather than asking
	# effective_supply_cost() what it thinks. The first version of this test
	# called the helper directly and passed even with the helper unwired.
	_party([{"swords": 5}])
	GameState.food = 100
	GameState.consume_supply("food", 4)
	var plain_spent: int = 100 - GameState.food

	_party([{"logistics": 10}])
	GameState.food = 100
	GameState.consume_supply("food", 4)
	var thrifty_spent: int = 100 - GameState.food

	if thrifty_spent >= plain_spent:
		_fail("Logistics 10 spent %d food where untrained spends %d"
			% [thrifty_spent, plain_spent])
	if thrifty_spent < 1:
		_fail("a supply draw spent %d — it must never be free" % thrifty_spent)
	_done()


func _check_party_xp_gain() -> void:
	_party([{"swords": 5}])
	var before: int = CharacterSystem.party[0].get("xp", 0)
	CompanionSystem.apply_party_xp(100)
	var plain_gain: int = CharacterSystem.party[0].get("xp", 0) - before

	_party([{"swords": 5}, {"learning": 10}])
	var before2: int = CharacterSystem.party[0].get("xp", 0)
	CompanionSystem.apply_party_xp(100)
	var taught_gain: int = CharacterSystem.party[0].get("xp", 0) - before2

	# Two members split the award, so the scholar's bonus has to overcome the
	# halving before it shows — which is the point of checking the real path.
	if taught_gain <= 0:
		_fail("the swordsman gained %d XP alongside a scholar" % taught_gain)
	if PartyBonuses.best("party_xp_gain_pct") <= 0.0:
		_fail("Learning 10 produced no party_xp_gain_pct at all")
	_assert_call_site("res://scripts/autoload/companion_system.gd",
		'xp_pct += PartyBonuses.best("party_xp_gain_pct")',
		"the XP award does not add the party bonus")
	_done()


func _check_travel_speed() -> void:
	_party([{"swords": 5}])
	var plain: float = MapManager.get_party_speed_multiplier()
	_party([{"logistics": 10}])
	var fast: float = MapManager.get_party_speed_multiplier()
	if fast <= plain:
		_fail("Logistics 10 gave a travel multiplier of %.2f, untrained %.2f"
			% [fast, plain])
	_assert_call_site("res://scripts/autoload/map_manager.gd",
		"base_speed * speed_mult * get_party_speed_multiplier()",
		"party movement does not apply the travel multiplier")
	_done()


## Assert a consumer actually calls its accessor.
##
## Every one of these bonuses was first "verified" by calling the accessor the
## same commit added, which passes whether or not anything uses it — proved by
## a negative pass where unwiring all three consumers changed nothing. Where a
## path cannot be driven headlessly, check the call site instead of pretending.
func _assert_call_site(path: String, needle: String, message: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("cannot read %s" % path)
		return
	var src := f.get_as_text()
	f.close()
	if not src.contains(needle):
		_fail(message)
