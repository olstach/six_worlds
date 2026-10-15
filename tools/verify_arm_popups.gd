extends Node
## Headless verification for the multi-arm attack popups.
##
## Run: godot --headless res://tools/verify_arm_popups.tscn
##
## A four-armed attacker's extra arms used to reach only the combat log: each
## arm's hit did raise the plain red damage number, but all of them on the same
## spot at the same moment as the primary hit's, and a missed arm showed
## nothing at all. Each extra arm now gets its own "Arm N: X" popup, staggered.
##
## These checks swing a real four-armed unit through CombatManager.attack_unit
## and then hand the result to the same function the arena calls from its
## unit_attacked handler, and count the labels that land on the defender.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 4
var grid: CombatGrid

# What a popup for an extra arm must look like
var _hit_re := RegEx.create_from_string("^Arm (\\d+): (\\d+)( crit!)?$")
var _miss_re := RegEx.create_from_string("^Arm (\\d+): (miss|dodge|block)$")


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(20, 20), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid

	_check_the_arena_calls_the_popups()
	_check_each_arm_gets_one_popup_when_blows_land()
	_check_each_arm_gets_one_popup_when_blows_miss()
	_check_crits_and_misses_read_like_the_primary_hit()

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


func _fail(msg: String) -> void:
	printerr("  FAIL: %s" % msg)
	failures += 1


func _done() -> void:
	checks_run += 1


## A combat unit. `four_armed` gives the attacker four arms and Finesse 40,
## which puts every extra arm's chance to fire at 100% — the chain always
## runs its full length, so the count of popups is deterministic.
func _make_unit(at: Vector2i, team: int, four_armed: bool) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["skills"] = {"unarmed": 5}
	if four_armed:
		unit.character_data["body_plan"] = {"species": "four_armed", "missing_parts": []}
		unit.character_data["attributes"]["finesse"] = 40
	CharacterSystem.update_derived_stats(unit.character_data)
	unit.character_data["derived"]["dodge"] = 0
	add_child(unit)
	unit.max_hp = 100000
	unit.current_hp = 100000
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()


## can_act() asks the CURRENT unit, so the attacker must be the one whose turn it is.
func _take_turn(unit: CombatUnit) -> void:
	unit.actions_remaining = 9
	CombatManager.turn_order = [unit]
	CombatManager.current_unit_index = 0


## Every floating label currently on `unit`.
func _labels(unit: Node) -> Array[Label]:
	var out: Array[Label] = []
	for child in unit.get_children():
		if child is Label:
			out.append(child)
	return out


## Swing once and return [result, arm_labels, plain_number_labels, hp_lost].
func _swing(attacker: CombatUnit, defender: CombatUnit) -> Array:
	for old in _labels(defender):
		defender.remove_child(old)
		old.queue_free()
	defender.current_hp = 100000
	_take_turn(attacker)
	var result: Dictionary = CombatManager.attack_unit(attacker, defender)
	# The arena's unit_attacked handler makes exactly this call.
	CombatUnit.show_arm_chain_popups(attacker, defender, result)
	var arm_labels: Array[Label] = []
	var numbers: Array[Label] = []
	for l in _labels(defender):
		if l.text.begins_with("Arm "):
			arm_labels.append(l)
		elif l.text.is_valid_int():
			numbers.append(l)
	return [result, arm_labels, numbers, 100000 - defender.current_hp]


## The popups are only seen if the arena actually asks for them.
func _check_the_arena_calls_the_popups() -> void:
	var f := FileAccess.open("res://scripts/combat/combat_arena.gd", FileAccess.READ)
	var src := f.get_as_text() if f != null else ""
	if not src.contains("CombatUnit.show_arm_chain_popups(attacker, defender, result)"):
		_fail("combat_arena's unit_attacked handler never shows the arm popups")
	_done()


## Arms that land: one "Arm N: X" per extra arm, numbered 2, 3, 4, the numbers
## adding up with the primary hit's to the HP actually lost, and no second
## bare red number stacked on the primary hit's.
func _check_each_arm_gets_one_popup_when_blows_land() -> void:
	var attacker := _make_unit(Vector2i(5, 5), 0, true)
	var defender := _make_unit(Vector2i(6, 5), 1, false)
	attacker.character_data["derived"]["accuracy"] = 999
	var saw_a_hit := false
	for _try in 10:
		var s: Array = _swing(attacker, defender)
		var result: Dictionary = s[0]
		var arms: Array[Label] = s[1]
		var numbers: Array[Label] = s[2]
		var extras: Array = result.get("extra_arm_results", [])
		if extras.size() != 3:
			_fail("a four-armed Finesse-40 attacker chained %d extra arms, expected 3" % extras.size())
			break
		if arms.size() != extras.size():
			_fail("%d extra arms produced %d popups" % [extras.size(), arms.size()])
			break
		if numbers.size() > 1:
			_fail("%d bare damage numbers on one defender — the extra arms' "
				% numbers.size() + "numbers were not held back")
		var shown_total: int = 0
		for n in numbers:
			shown_total += n.text.to_int()
		var positions: Dictionary = {}
		for i in arms.size():
			var text: String = arms[i].text
			var extra: Dictionary = extras[i]
			if not text.begins_with("Arm %d:" % (i + 2)):
				_fail("popup %d reads '%s', expected it to be arm %d" % [i, text, i + 2])
			if extra.get("hit", false):
				saw_a_hit = true
				var m := _hit_re.search(text)
				if m == null:
					_fail("a landed arm's popup reads '%s'" % text)
				else:
					shown_total += m.get_string(2).to_int()
					if m.get_string(2).to_int() != int(extra.get("damage_taken", -1)):
						_fail("'%s' does not show the %d HP that arm took"
							% [text, int(extra.get("damage_taken", -1))])
			elif _miss_re.search(text) == null:
				_fail("a missed arm's popup reads '%s'" % text)
			# Staggered: hidden until its moment, and not on top of another
			if arms[i].visible:
				_fail("'%s' appears at once instead of after its stagger" % text)
			if positions.has(arms[i].position):
				_fail("two arm popups start on the same spot")
			positions[arms[i].position] = true
		if shown_total != s[3]:
			_fail("popups show %d damage in total but the defender lost %d HP"
				% [shown_total, s[3]])
	if not saw_a_hit:
		_fail("ten swings at 999 accuracy and no extra arm ever landed")
	_cleanup([attacker, defender])
	_done()


## Arms that miss still get a popup — before this, a missed arm showed nothing.
func _check_each_arm_gets_one_popup_when_blows_miss() -> void:
	var attacker := _make_unit(Vector2i(5, 8), 0, true)
	var defender := _make_unit(Vector2i(6, 8), 1, false)
	attacker.character_data["derived"]["accuracy"] = -999
	var saw_a_miss := false
	for _try in 5:
		var s: Array = _swing(attacker, defender)
		var extras: Array = s[0].get("extra_arm_results", [])
		var arms: Array[Label] = s[1]
		if arms.size() != extras.size() or extras.size() != 3:
			_fail("%d extra arms produced %d popups (expected 3 of each)"
				% [extras.size(), arms.size()])
			break
		for i in arms.size():
			if not extras[i].get("hit", false):
				saw_a_miss = true
				if _miss_re.search(arms[i].text) == null:
					_fail("a missed arm's popup reads '%s'" % arms[i].text)
	if not saw_a_miss:
		_fail("five swings at -999 accuracy and no extra arm ever missed")
	_cleanup([attacker, defender])
	_done()


## The text itself: a crit says so, a miss uses the same Block/Dodge/Miss word
## the primary hit's popup would.
func _check_crits_and_misses_read_like_the_primary_hit() -> void:
	var attacker := _make_unit(Vector2i(5, 11), 0, true)
	var defender := _make_unit(Vector2i(6, 11), 1, false)
	var miss_word: String = str(defender.miss_text_against(attacker)[0]).trim_suffix("!").to_lower()
	var cases: Array = [
		[{"arm_number": 2, "hit": true, "crit": false, "damage_taken": 12}, "Arm 2: 12"],
		[{"arm_number": 3, "hit": true, "crit": true, "damage_taken": 30}, "Arm 3: 30 crit!"],
		[{"arm_number": 4, "hit": false}, "Arm 4: %s" % miss_word],
	]
	var extras: Array = []
	for c in cases:
		extras.append(c[0])
	var shown: int = CombatUnit.show_arm_chain_popups(attacker, defender,
		{"extra_arm_results": extras})
	if shown != cases.size():
		_fail("%d results produced %d popups" % [cases.size(), shown])
	# A unit carries labels of its own (its name, HP) — only the popups count.
	var arms: Array[Label] = []
	for l in _labels(defender):
		if l.text.begins_with("Arm "):
			arms.append(l)
	if arms.size() != cases.size():
		_fail("%d results left %d labels on the defender" % [cases.size(), arms.size()])
	for i in mini(arms.size(), cases.size()):
		if arms[i].text != cases[i][1]:
			_fail("popup reads '%s', expected '%s'" % [arms[i].text, cases[i][1]])
	_cleanup([attacker, defender])
	_done()
