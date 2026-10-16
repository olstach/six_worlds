extends Node
## Headless verification for multi-arm attacks, four-armed bodies, severed
## limbs and the Unbroken perk.
##
## Run: godot --headless res://tools/verify_multi_arm.tscn
##
## The extra arms of a multi-arm attack used to land through their own copy of
## the main hit's on-hit code, and kept falling behind it: no weapon oil, no
## poisoned blood, no weapon procs, no per-turn counters. They now go through
## the same shared functions (_apply_hit_damage, _apply_weapon_oil,
## _resolve_hit_procs, _count_weapon_attack). These checks swing real units
## through CombatManager.attack_unit and look at what each arm did.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 13
var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(30, 30), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid

	_check_arms_spend_weapon_oil()
	_check_arms_fire_weapon_on_crit_procs()
	_check_arms_can_poison_the_blood()
	_check_arms_count_as_attacks()
	_check_each_arm_is_logged_once_with_hp_lost()
	_check_zero_damage_arm_shows_no_popup()
	_check_off_hand_reads_the_active_weapon_set()
	_check_severing_drops_both_weapon_sets()
	_check_severing_with_a_full_pack_keeps_the_item()
	_check_four_armed_bodies_wear_four_gloves()
	_check_equipment_screen_has_second_hands()
	_check_unbroken_downgrades_wounds()
	_check_unbroken_leaves_diseases_alone()

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


## A combat unit. `four_armed` gives it four arms and Finesse 40, which puts
## every extra arm's chance to fire at 100% — the chain always runs its full
## length. Accuracy 999 makes every blow land.
func _make_unit(at: Vector2i, team: int, four_armed: bool) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d_%d" % [team, at.y]
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["name"] = unit.unit_name
	unit.character_data["skills"] = {"unarmed": 5}
	if four_armed:
		unit.character_data["body_plan"] = {"species": "four_armed", "missing_parts": []}
		unit.character_data["attributes"]["finesse"] = 40
	CharacterSystem.update_derived_stats(unit.character_data)
	unit.character_data["derived"]["dodge"] = 0
	unit.character_data["derived"]["accuracy"] = 999
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
func _swing(attacker: CombatUnit, defender: CombatUnit) -> Dictionary:
	defender.current_hp = 100000
	attacker.actions_remaining = 9
	CombatManager.turn_order = [attacker]
	CombatManager.current_unit_index = 0
	return CombatManager.attack_unit(attacker, defender)


## Each arm that lands spends a charge of oil and deals the oil's damage —
## before, only the primary hit touched the oil.
func _check_arms_spend_weapon_oil() -> void:
	var attacker := _make_unit(Vector2i(5, 2), 0, true)
	var defender := _make_unit(Vector2i(6, 2), 1, false)
	attacker.weapon_oil = {"attacks_remaining": 20, "bonus_damage": 3,
		"bonus_damage_type": "fire"}
	var result := _swing(attacker, defender)
	var extras: Array = result.get("extra_arm_results", [])
	if extras.size() != 3:
		_fail("oil: a four-armed Finesse-40 attacker chained %d arms, expected 3" % extras.size())
	var landed: int = 1 if result.get("hit", false) else 0
	for extra in extras:
		if extra.get("hit", false):
			landed += 1
			if int(extra.get("oil_damage", 0)) != 3:
				_fail("oil: arm %d landed without the oil's 3 fire damage"
					% extra.get("arm_number", 0))
	var left: int = int(attacker.weapon_oil.get("attacks_remaining", 0))
	if left != 20 - landed:
		_fail("oil: %d blows landed but the oil has %d of 20 charges left" % [landed, left])
	_cleanup([attacker, defender])
	_done()


## A weapon's on-crit status (the Trishula's) fires on an arm's crit too.
func _check_arms_fire_weapon_on_crit_procs() -> void:
	var attacker := _make_unit(Vector2i(5, 4), 0, true)
	var defender := _make_unit(Vector2i(6, 4), 1, false)
	attacker.character_data["equipped_weapon"] = {"name": "Test Trident", "type": "spear",
		"damage_type": "piercing", "stats": {"damage": 5, "crit_chance": 200},
		"on_crit_status": "Stunned"}
	var result := _swing(attacker, defender)
	var saw: int = 0
	for extra in result.get("extra_arm_results", []):
		if extra.get("crit", false):
			if extra.get("on_crit_status", "") != "Stunned":
				_fail("on-crit proc: arm %d critted without the weapon's on-crit status"
					% extra.get("arm_number", 0))
			saw += 1
	if saw == 0:
		_fail("on-crit proc: no extra arm critted at 200% crit chance")
	_cleanup([attacker, defender])
	_done()


## A poison-tagged enemy's extra arms can poison the blood, like its main hit.
## The roll is 15% × the arm's fire chance (100% here), so swing until it
## shows up on an ARM's result — the old arm code had no poison branch at all.
func _check_arms_can_poison_the_blood() -> void:
	var attacker := _make_unit(Vector2i(5, 6), 1, true)
	var defender := _make_unit(Vector2i(6, 6), 0, false)
	attacker.character_data["tags"] = ["poison"]
	var seen := false
	for _try in 200:
		defender.character_data["wounds"] = []
		var result := _swing(attacker, defender)
		for extra in result.get("extra_arm_results", []):
			if extra.get("persistent_disease", "") == "poisoned_blood":
				seen = true
		if seen:
			break
	if not seen:
		_fail("poisoned blood: 200 four-armed swings from a poison-tagged enemy, "
			+ "no extra arm ever poisoned the blood")
	_cleanup([attacker, defender])
	_done()


## Every arm's swing counts on the attack counters, hit or miss.
func _check_arms_count_as_attacks() -> void:
	var attacker := _make_unit(Vector2i(5, 8), 0, true)
	var defender := _make_unit(Vector2i(6, 8), 1, false)
	attacker.attacks_this_combat = 0
	var result := _swing(attacker, defender)
	var expected: int = 1 + result.get("extra_arm_results", []).size()
	if attacker.attacks_this_combat != expected:
		_fail("counters: %d swings made, attacks_this_combat says %d"
			% [expected, attacker.attacks_this_combat])
	_cleanup([attacker, defender])
	_done()


## Each arm reaches the combat log once (the arena's line), not also as a
## CombatManager line in another format; and both the primary hit and the arms
## report the HP actually lost — which, through armour, is less than the blow.
func _check_each_arm_is_logged_once_with_hp_lost() -> void:
	var attacker := _make_unit(Vector2i(5, 10), 0, true)
	var defender := _make_unit(Vector2i(6, 10), 1, false)
	defender.character_data["derived"]["damage_reduction_pct"] = 50.0
	var lines: Array[String] = []
	var catcher := func(msg: String) -> void: lines.append(msg)
	CombatManager.combat_log.connect(catcher)
	var result := _swing(attacker, defender)
	CombatManager.combat_log.disconnect(catcher)
	for line in lines:
		if line.begins_with("Arm "):
			_fail("CombatManager still logs an arm itself: '%s'" % line)
	var lost: int = 100000 - defender.current_hp
	var reported: int = int(result.get("damage_taken", -1))
	for extra in result.get("extra_arm_results", []):
		reported += int(extra.get("damage_taken", 0))
	if not result.has("damage_taken"):
		_fail("the primary hit's result has no damage_taken")
	elif reported != lost:
		_fail("hits report %d HP lost but the defender lost %d" % [reported, lost])
	if result.get("hit", false) and int(result.damage) > 1 \
			and int(result.damage_taken) >= int(result.damage):
		_fail("50%% armour, yet damage_taken %d is not below the blow's %d"
			% [int(result.damage_taken), int(result.damage)])
	var text: String = CombatUnit.hit_damage_text({"damage": 18, "damage_taken": 12})
	if text != "12 (18 before armour)":
		_fail("hit_damage_text reads '%s'" % text)
	if CombatUnit.hit_damage_text({"damage": 7, "damage_taken": 7}) != "7":
		_fail("hit_damage_text adds a before-armour note when nothing was taken off")
	_cleanup([attacker, defender])
	_done()


## An arm that lands for nothing gets no popup — the same as a primary hit
## that costs nothing.
func _check_zero_damage_arm_shows_no_popup() -> void:
	var attacker := _make_unit(Vector2i(5, 12), 0, true)
	var defender := _make_unit(Vector2i(6, 12), 1, false)
	var shown: int = CombatUnit.show_arm_chain_popups(attacker, defender, {"extra_arm_results": [
		{"arm_number": 2, "hit": true, "damage": 9, "damage_taken": 0},
		{"arm_number": 3, "hit": true, "damage": 9, "damage_taken": 4},
	]})
	if shown != 1:
		_fail("a 0-HP arm and a 4-HP arm made %d popups, expected 1" % shown)
	for child in defender.get_children():
		if child is Label and child.text.begins_with("Arm 2"):
			_fail("a 0-HP arm still shows '%s'" % child.text)
	_cleanup([attacker, defender])
	_done()


## The off hand is read from the ACTIVE weapon set. Equipment keeps it in
## weapon_set_N.off; the arm chain read a top-level equipment["weapon_off"]
## that does not exist, so a two-armed dual-wielder never chained.
func _check_off_hand_reads_the_active_weapon_set() -> void:
	var attacker := _make_unit(Vector2i(5, 14), 0, false)
	var defender := _make_unit(Vector2i(6, 14), 1, false)
	attacker.character_data["attributes"]["finesse"] = 40  # arm 2 always fires
	var dagger: String = _first_item_of_type("dagger")
	var shield: String = _first_item_of_type("shield")
	attacker.character_data["equipment"]["weapon_set_2"] = {"main": dagger, "off": dagger}
	attacker.character_data["active_weapon_set"] = 2
	var result := _swing(attacker, defender)
	if result.get("extra_arm_results", []).size() != 1:
		_fail("off hand: a dual-wielder (set 2 active) chained %d extra arms, expected 1"
			% result.get("extra_arm_results", []).size())
	# A shield in the active set 2 counts as a shield.
	attacker.character_data["equipment"]["weapon_set_2"]["off"] = shield
	if not attacker._has_shield_equipped():
		_fail("off hand: a shield in active weapon set 2 is not seen")
	attacker.character_data["active_weapon_set"] = 1
	if attacker._has_shield_equipped():
		_fail("off hand: set 1 is active and empty, yet a shield is seen")
	_cleanup([attacker, defender])
	_done()


## A severed sword arm drops the main-hand weapon of BOTH weapon sets.
func _check_severing_drops_both_weapon_sets() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	var a: String = _first_item_of_type("sword")
	var b: String = _first_item_of_type("axe")
	c["equipment"]["weapon_set_1"]["main"] = a
	c["equipment"]["weapon_set_2"]["main"] = b
	var a_before: int = ItemSystem.get_inventory_count(a)
	var b_before: int = ItemSystem.get_inventory_count(b)
	BodySystem.sever_part(c, "arm_r")
	if String(c["equipment"]["weapon_set_1"]["main"]) != "" \
			or String(c["equipment"]["weapon_set_2"]["main"]) != "":
		_fail("sever: a weapon is still held by the lost hand: set1 '%s', set2 '%s'"
			% [c["equipment"]["weapon_set_1"]["main"], c["equipment"]["weapon_set_2"]["main"]])
	if ItemSystem.get_inventory_count(a) != a_before + 1 \
			or ItemSystem.get_inventory_count(b) != b_before + 1:
		_fail("sever: the dropped weapons did not both reach the pack")
	ItemSystem.remove_from_inventory(a, 1)
	ItemSystem.remove_from_inventory(b, 1)
	_done()


## With a full pack the lost hand's glove and weapon still go into the pack —
## they used to be cleared from the slot and lost.
func _check_severing_with_a_full_pack_keeps_the_item() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	var glove: String = _first_item_of_type("gloves")
	var blade: String = _first_item_of_type("sword")
	c["equipment"]["hand_r"] = glove
	c["equipment"]["weapon_set_1"]["main"] = blade
	var saved_cap: int = ItemSystem.max_inventory_size
	ItemSystem.max_inventory_size = ItemSystem._inventory.size()  # full, right now
	var g_before: int = ItemSystem.get_inventory_count(glove)
	var s_before: int = ItemSystem.get_inventory_count(blade)
	BodySystem.sever_part(c, "arm_r")
	ItemSystem.max_inventory_size = saved_cap
	if ItemSystem.get_inventory_count(glove) != g_before + 1:
		_fail("full pack: the glove on the severed hand was destroyed")
	if ItemSystem.get_inventory_count(blade) != s_before + 1:
		_fail("full pack: the sword in the severed hand was destroyed")
	ItemSystem.remove_from_inventory(glove, 1)
	ItemSystem.remove_from_inventory(blade, 1)
	_done()


## A four-armed body can glove all four hands — one pair per pair of hands,
## the left slot holding it and the right mirroring — and a two-armed one
## cannot reach for a third.
func _check_four_armed_bodies_wear_four_gloves() -> void:
	var glove: String = _first_item_of_type("gloves")
	var four: Dictionary = CharacterSystem.create_blank_character()
	four["body_plan"] = {"species": "four_armed", "missing_parts": [], "prosthetics": {}}
	if not four["equipment"].has("hand_l2") or not four["equipment"].has("hand_r2"):
		_fail("four arms: the default equipment has no hand_l2/hand_r2")
	var before: int = ItemSystem.get_inventory_count(glove)
	for slot in ["hand_l", "hand_l2"]:
		ItemSystem.add_to_inventory(glove, 1)
		if not ItemSystem.equip_item(four, glove, slot):
			_fail("four arms: gloves cannot be equipped to %s" % slot)
			ItemSystem.remove_from_inventory(glove, 1)
	for slot in ["hand_l", "hand_r", "hand_l2", "hand_r2"]:
		if String(four["equipment"].get(slot, "")) != glove:
			_fail("four arms: %s is not gloved after equipping two pairs" % slot)
	if ItemSystem.get_inventory_count(glove) != before:
		_fail("four arms: two pairs on four hands did not take exactly two from the pack")
	for slot in ["hand_l", "hand_l2"]:
		ItemSystem.unequip_item(four, slot)
	if ItemSystem.get_inventory_count(glove) != before + 2:
		_fail("four arms: taking off two pairs did not return exactly two")
	ItemSystem.remove_from_inventory(glove, 2)
	var two: Dictionary = CharacterSystem.create_blank_character()
	ItemSystem.add_to_inventory(glove, 1)
	if ItemSystem.equip_item(two, glove, "hand_l2"):
		_fail("two arms: a human put gloves on a third hand")
	ItemSystem.remove_from_inventory(glove, 1)
	_done()


## One pair of gloves is one item on two hands, and ItemSystem keeps it so:
## equipping from either hand gloves both; unequipping from either hand
## returns the one pair; a separate glove already on the other hand goes back
## to the pack (never overwritten); a right hand that wears a DIFFERENT glove
## of its own comes off with the pair; and a companion's starting kit naming a
## glove for each hand is settled into one pair — unequipping it used to
## return only one of the two. The equipment screen's boxes include the
## second pair of hands.
func _check_equipment_screen_has_second_hands() -> void:
	var menu_script: GDScript = load("res://scripts/ui/main_menu.gd")
	var slots: Dictionary = menu_script.EQUIPMENT_SLOTS
	if not slots.has("hand_l2") or not slots.has("hand_r2"):
		_fail("equipment screen: no hand_l2/hand_r2 in EQUIPMENT_SLOTS")
	var glove: String = _first_item_of_type("gloves")
	var stray := "__verify_stray_glove__"
	ItemSystem._item_database[stray] = {"name": "Stray glove", "type": "gloves",
		"slot": "hand_l"}
	var g0: int = ItemSystem.get_inventory_count(glove)

	# Equip on the second hands while hand_r2 wears a stray glove of its own.
	var four: Dictionary = CharacterSystem.create_blank_character()
	four["body_plan"] = {"species": "four_armed", "missing_parts": [], "prosthetics": {}}
	four["equipment"]["hand_r2"] = stray
	ItemSystem.add_to_inventory(glove, 1)
	ItemSystem.equip_item(four, glove, "hand_l2")
	if String(four["equipment"]["hand_r2"]) != glove:
		_fail("pairs: hand_r2 does not mirror the gloves on hand_l2")
	if ItemSystem.get_inventory_count(stray) != 1:
		_fail("pairs: the glove already on hand_r2 was overwritten, not returned")
	ItemSystem.remove_from_inventory(stray, 1)
	# Unequip from the MIRROR hand: the pair comes off both, once.
	ItemSystem.unequip_item(four, "hand_r2")
	if String(four["equipment"]["hand_l2"]) != "" or String(four["equipment"]["hand_r2"]) != "":
		_fail("pairs: unequipping from the right hand left a glove on")
	if ItemSystem.get_inventory_count(glove) != g0 + 1:
		_fail("pairs: unequipping a pair left %d in the pack, expected %d"
			% [ItemSystem.get_inventory_count(glove), g0 + 1])

	# Equip from the right hand: it lands on the left, mirrored.
	var two: Dictionary = CharacterSystem.create_blank_character()
	ItemSystem.equip_item(two, glove, "hand_r")
	if String(two["equipment"]["hand_l"]) != glove or String(two["equipment"]["hand_r"]) != glove:
		_fail("pairs: equipping gloves to hand_r did not glove both hands")
	if ItemSystem.get_inventory_count(glove) != g0:
		_fail("pairs: one pair on two hands did not take exactly one from the pack")
	ItemSystem.unequip_item(two, "hand_l")
	# A different glove of its own on the right hand comes off with the pair.
	two["equipment"]["hand_l"] = glove
	two["equipment"]["hand_r"] = stray
	ItemSystem.remove_from_inventory(glove, 1)
	ItemSystem.unequip_item(two, "hand_l")
	if ItemSystem.get_inventory_count(stray) != 1 or ItemSystem.get_inventory_count(glove) != g0 + 1:
		_fail("pairs: unequipping did not return every distinct glove held")
	ItemSystem.remove_from_inventory(stray, 1)

	# Companion starting kit: a glove named for each hand settles into one pair.
	var companion: Dictionary = CharacterSystem.create_blank_character()
	CompanionSystem._apply_starting_equipment(companion, {},
		{"hand_l": glove, "hand_r": glove}, "common")
	if String(companion["equipment"]["hand_l"]) != glove \
			or String(companion["equipment"]["hand_r"]) != glove:
		_fail("pairs: a starting kit's gloves are not on both hands")
	ItemSystem.unequip_item(companion, "hand_l")
	if String(companion["equipment"]["hand_r"]) != "":
		_fail("pairs: a starting kit's right glove stayed on after the pair came off")
	if ItemSystem.get_inventory_count(glove) != g0 + 2:
		_fail("pairs: unequipping a starting kit's pair returned %d, expected 1"
			% (ItemSystem.get_inventory_count(glove) - g0 - 1))
	# Only the right hand named: the pair moves to the left and mirrors.
	var righty: Dictionary = CharacterSystem.create_blank_character()
	CompanionSystem._apply_starting_equipment(righty, {}, {"hand_r": glove}, "common")
	if String(righty["equipment"]["hand_l"]) != glove:
		_fail("pairs: a kit glove named only for hand_r was not settled onto hand_l")

	ItemSystem.remove_from_inventory(glove, ItemSystem.get_inventory_count(glove) - g0)
	ItemSystem._item_database.erase(stray)
	_done()


## Unbroken: severe → moderate, moderate → light, light → nothing.
func _check_unbroken_downgrades_wounds() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["perks"] = ["unbroken"]
	c["wounds"] = []
	WoundSystem.apply_wound(c, "infected_wound")   # severe
	WoundSystem.apply_wound(c, "concussion")       # moderate
	var took_light: bool = WoundSystem.apply_wound(c, "deep_cut")  # light
	var sev: Dictionary = {}
	for entry in c["wounds"]:
		sev[entry.id] = WoundSystem.get_entry_severity(entry)
	if sev.get("infected_wound", "") != "moderate":
		_fail("unbroken: a severe wound counts as '%s', expected moderate" % sev.get("infected_wound", "absent"))
	if sev.get("concussion", "") != "light":
		_fail("unbroken: a moderate wound counts as '%s', expected light" % sev.get("concussion", "absent"))
	if took_light or sev.has("deep_cut"):
		_fail("unbroken: a light wound still took hold")
	# Without the perk nothing changes.
	var plain: Dictionary = CharacterSystem.create_blank_character()
	plain["wounds"] = []
	WoundSystem.apply_wound(plain, "infected_wound")
	if WoundSystem.get_entry_severity(plain["wounds"][0]) != "severe":
		_fail("unbroken: a character without the perk had a wound downgraded")
	# The downgrade reaches the stat penalties: an Unbroken torso wound costs
	# less max HP than the same wound on anyone else.
	var hurt: Dictionary = CharacterSystem.create_blank_character()
	hurt["wounds"] = [{"id": "infected_wound", "body_location": "torso", "rests_untreated": 0}]
	var full: int = int(WoundSystem.get_stat_penalties(hurt).get("max_hp", 0))
	hurt["wounds"][0]["downgraded"] = true
	var eased: int = int(WoundSystem.get_stat_penalties(hurt).get("max_hp", 0))
	if not eased > full:
		_fail("unbroken: a downgraded wound costs %d max HP, the full one %d" % [eased, full])
	_done()


## Unbroken is armour: a disease is not a wound and is not downgraded.
func _check_unbroken_leaves_diseases_alone() -> void:
	var c: Dictionary = CharacterSystem.create_blank_character()
	c["perks"] = ["unbroken"]
	c["wounds"] = []
	WoundSystem.apply_wound(c, "rot_sickness")
	if c["wounds"].is_empty():
		_fail("unbroken: a light disease was shrugged off as if it were a wound")
	elif c["wounds"][0].get("downgraded", false):
		_fail("unbroken: a disease was downgraded")
	_done()


func _first_item_of_type(item_type: String) -> String:
	for item_id in ItemSystem._item_database:
		if String(item_id).begins_with("_"):
			continue
		if ItemSystem._item_database[item_id].get("type", "") == item_type:
			return String(item_id)
	_fail("items.json has no '%s' to test with" % item_type)
	return ""
