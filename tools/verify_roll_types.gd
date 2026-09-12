extends Node
## Headless verification for event roll categories and the Leadership party cap.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 5


func _ready() -> void:
	_check_category_derived_from_attribute()
	_check_category_derived_from_skill()
	_check_explicit_category_wins()
	_check_social_bonus_applies_only_to_social_rolls()
	_check_leadership_sets_the_party_cap()

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


## Every existing roll names a stat, so the stat is the category. 168 rolls
## across the shipped events needed no data change for this.
func _check_category_derived_from_attribute() -> void:
	var cases := {"charm": "social", "strength": "physical", "constitution": "physical",
		"finesse": "physical", "awareness": "perception", "focus": "mental",
		"luck": "fortune"}
	for attribute in cases:
		var got: String = EventManager.get_roll_category({"attribute": attribute})
		if got != cases[attribute]:
			_fail("a %s roll categorised as '%s', expected '%s'"
				% [attribute, got, cases[attribute]])
	_done()


func _check_category_derived_from_skill() -> void:
	for skill in ["persuasion", "comedy", "performance", "guile"]:
		var got: String = EventManager.get_roll_category({"skill": skill})
		if got != "social":
			_fail("a %s roll categorised as '%s', expected 'social'" % [skill, got])
	_done()


## The derivation is a default, not a rule. An Awareness check that is really
## reading a room should be able to say so.
func _check_explicit_category_wins() -> void:
	var got: String = EventManager.get_roll_category(
		{"attribute": "awareness", "category": "social"})
	if got != "social":
		_fail("an explicit category was ignored: got '%s'" % got)
	_done()


func _check_social_bonus_applies_only_to_social_rolls() -> void:
	_party([{"swords": 10}])
	var plain: int = EventManager.get_roll_bonus({"attribute": "charm"})
	_party([{"persuasion": 10}, {"performance": 10}])
	var social: int = EventManager.get_roll_bonus({"attribute": "charm"})
	if social <= plain:
		_fail("a talker party added %d to a Charm roll (untrained %d)"
			% [social, plain])
	# The same party must not be better at lifting a portcullis.
	var physical: int = EventManager.get_roll_bonus({"attribute": "strength"})
	var physical_plain: int = 0
	_party([{"swords": 10}])
	physical_plain = EventManager.get_roll_bonus({"attribute": "strength"})
	if physical != physical_plain:
		_fail("the social bonus leaked into a Strength roll (%d vs %d)"
			% [physical, physical_plain])
	_done()


## Two companions come free — nobody should have to buy a skill to travel with
## anyone — and Leadership adds one at 3, 6 and 9, topping out at six.
func _check_leadership_sets_the_party_cap() -> void:
	var expected := {0: 3, 1: 3, 2: 3, 3: 4, 5: 4, 6: 5, 8: 5, 9: 6, 10: 6}
	for level in expected:
		_party([{"leadership": level}])
		var cap: int = CharacterSystem.get_max_party_size()
		if cap != expected[level]:
			_fail("Leadership %d allows a party of %d, expected %d"
				% [level, cap, expected[level]])
	_done()
