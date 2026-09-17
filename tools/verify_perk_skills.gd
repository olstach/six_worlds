extends Node
## Headless verification for the last six active perks.
##
## Run: godot --headless res://tools/verify_perk_skills.tscn
##
## These were the remainder after the reaction stances, the terrain placers and
## the five singles: Arcane Archer, Attune Charm, Improvised Masterpiece,
## Magnetism, Smoke and Mirrors and The Invisible Hand. Two of them wanted a
## player CHOICE, which is why `choose_one` exists — a skill that offers three
## things dispatches the chosen one through the same table every other skill
## uses, rather than being wired to its first branch as a stopgap.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 10
var grid: CombatGrid


func _ready() -> void:
	grid = CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(40, 40), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	CombatManager.combat_grid = grid

	_check_choosing_an_option_does_that_option()
	_check_an_option_out_of_range_is_clamped()
	_check_a_masterpiece_can_inspire_or_demoralise()
	_check_attuning_spends_a_charm()
	_check_attuning_without_a_charm_fails()
	_check_images_draw_and_expire()
	_check_a_pocket_can_be_picked()
	_check_an_empty_pocket_yields_nothing()
	_check_an_imbued_arrow_delivers_its_spell()
	_check_talking_somebody_round()

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


func _make_unit(at: Vector2i, team: int = 0) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.unit_name = "Probe%d" % team
	unit.team = team
	unit.character_data = CharacterSystem.create_blank_character()
	unit.character_data["attributes"]["focus"] = 20
	CharacterSystem.update_derived_stats(unit.character_data)
	unit.character_data["derived"]["accuracy"] = 999
	add_child(unit)
	unit.max_hp = 100000
	unit.current_hp = 100000
	unit.current_mana = 500
	unit.grid_position = at
	grid.unit_positions[at] = unit
	CombatManager.all_units.append(unit)
	return unit


func _cleanup(units: Array) -> void:
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()
	CombatManager.turn_order = []
	CombatManager.current_unit_index = 0


## Use `perk_id`, optionally forcing a choice, and return the result.
func _use(user: CombatUnit, perk_id: String, at: Vector2i, chosen: int = -1) -> Dictionary:
	var data: Dictionary = PerkSystem.get_perk_data(perk_id)
	if data.is_empty():
		_fail("%s is not in perks.json" % perk_id)
		return {}
	var skill_data: Dictionary = data.duplicate(true)
	skill_data["id"] = perk_id
	if chosen >= 0:
		skill_data["combat_data"]["chosen_option"] = chosen
	user.actions_remaining = 9
	user.current_stamina = 50
	user.skill_cooldowns.clear()
	CombatManager.turn_order = [user]
	CombatManager.current_unit_index = 0
	return CombatManager.use_active_skill(user, skill_data, at)


## `choose_one` dispatches the option the caller picked, through the same table
## every other skill uses.
func _check_choosing_an_option_does_that_option() -> void:
	var performer := _make_unit(Vector2i(10, 10), 0)
	# Three tiles out: within the SKILL's radius, outside the default an
	# option would fall back to if it did not inherit the skill's own fields.
	var ally := _make_unit(Vector2i(13, 10), 0)
	# And one five tiles out, who is not within earshot of a three-tile
	# performance: the radius has to EXCLUDE somebody or it is decoration.
	var distant_ally := _make_unit(Vector2i(16, 10), 0)
	var foe := _make_unit(Vector2i(12, 10), 1)

	# Option 0 is Inspire: allies gain, enemies are untouched.
	var inspire: Dictionary = _use(performer, "improvised_masterpiece", performer.grid_position, 0)
	if not bool(inspire.get("success", false)):
		_fail("Inspire failed: %s" % str(inspire.get("reason", "?")))
	if int(inspire.get("chosen", -1)) != 0:
		_fail("the result does not report which option was taken")
	var ally_modifiers: int = ally.stat_modifiers.size()
	var foe_modifiers: int = foe.stat_modifiers.size()
	if ally_modifiers == 0:
		_fail("Inspire gave the ally three tiles away nothing — the option is "
			+ "not inheriting the skill's radius")
	if foe_modifiers != 0:
		_fail("Inspire also touched the enemy")
	if distant_ally.stat_modifiers.size() != 0:
		_fail("Inspire reached an ally six tiles away, though the skill names "
			+ "three — the radius is not being read")

	# Option 1 is Demoralize: the other way round. Enemies get a save, so try
	# until one lands — what is under test is which SIDE the option reaches.
	foe.character_data["attributes"]["focus"] = 1
	CharacterSystem.update_derived_stats(foe.character_data)
	var landed := false
	for _try in 12:
		ally.stat_modifiers.clear()
		foe.stat_modifiers.clear()
		var demoralise: Dictionary = _use(performer, "improvised_masterpiece",
			performer.grid_position, 1)
		if not bool(demoralise.get("success", false)):
			_fail("Demoralize failed: %s" % str(demoralise.get("reason", "?")))
			break
		if foe.stat_modifiers.size() > 0:
			landed = true
			break
	if not landed:
		_fail("twelve Demoralizes and the enemy was never touched")
	if ally.stat_modifiers.size() != 0:
		_fail("Demoralize also touched the ally")
	_cleanup([performer, ally, distant_ally, foe])
	_done()


func _check_an_option_out_of_range_is_clamped() -> void:
	var performer := _make_unit(Vector2i(10, 10), 0)
	var ally := _make_unit(Vector2i(11, 10), 0)
	var wild: Dictionary = _use(performer, "improvised_masterpiece",
		performer.grid_position, 99)
	if not bool(wild.get("success", false)):
		_fail("an out-of-range choice failed outright rather than clamping: %s"
			% str(wild.get("reason", "?")))
	elif int(wild.get("chosen", -1)) < 0:
		_fail("an out-of-range choice reported no option at all")
	_cleanup([performer, ally])
	_done()


## The three branches are genuinely different, which is the point of choosing.
func _check_a_masterpiece_can_inspire_or_demoralise() -> void:
	var data: Dictionary = PerkSystem.get_perk_data("improvised_masterpiece")
	var options: Array = data.get("combat_data", {}).get("options", [])
	if options.size() < 3:
		_fail("Improvised Masterpiece offers %d options, not three" % options.size())
	var effects: Dictionary = {}
	for option in options:
		effects[str(option.get("effect", ""))] = true
		if not CombatManager.is_active_skill_effect_implemented(str(option.get("effect", ""))):
			_fail("option '%s' names effect '%s', which has no resolver"
				% [str(option.get("label", "?")), str(option.get("effect", ""))])
	if effects.size() < 2:
		_fail("all three options do the same thing")
	_done()


func _check_attuning_spends_a_charm() -> void:
	var ritualist := _make_unit(Vector2i(10, 10), 0)
	ItemSystem.add_to_inventory("fire_charm_common", 1)
	var before: int = ItemSystem.get_inventory_count("fire_charm_common")

	var result: Dictionary = _use(ritualist, "attune_charm", ritualist.grid_position, 0)
	if not bool(result.get("success", false)):
		_fail("attune_charm failed: %s" % str(result.get("reason", "?")))
	elif ItemSystem.get_inventory_count("fire_charm_common") >= before:
		_fail("attuning did not spend the charm")
	elif ritualist.charm_buff.is_empty():
		_fail("attuning left no charm buff on the ritualist")
	elif str(ritualist.charm_buff.get("school", "")) != "fire":
		_fail("the buff is for '%s', not the charm's own school"
			% str(ritualist.charm_buff.get("school", "")))

	# The Ritual reading adds what the perk names, on top of the charm's own
	# mana discount.
	if float(ritualist.charm_buff.get("spellpower_bonus", 0.0)) <= 0.0:
		_fail("the power option added no spellpower")
	_cleanup([ritualist])
	_done()


func _check_attuning_without_a_charm_fails() -> void:
	var ritualist := _make_unit(Vector2i(10, 10), 0)
	while ItemSystem.get_inventory_count("fire_charm_common") > 0:
		ItemSystem.remove_from_inventory("fire_charm_common", 1)
	# Every charm out of the bag, so there is nothing to attune.
	var held: Array = []
	for entry in ItemSystem.get_inventory():
		var item_id: String = str(entry.get("item_id", ""))
		if str(ItemSystem.get_item(item_id).get("type", "")) == "charm":
			held.append(item_id)
	for item_id in held:
		while ItemSystem.get_inventory_count(item_id) > 0:
			ItemSystem.remove_from_inventory(item_id, 1)

	var result: Dictionary = _use(ritualist, "attune_charm", ritualist.grid_position, 0)
	if bool(result.get("success", false)):
		_fail("attuning succeeded with no charm in the bag")
	if not ritualist.charm_buff.is_empty():
		_fail("a failed attunement still left a buff")
	_cleanup([ritualist])
	_done()


func _check_images_draw_and_expire() -> void:
	var trickster := _make_unit(Vector2i(10, 10), 0)
	var before: int = CombatManager.all_units.size()
	var result: Dictionary = _use(trickster, "smoke_and_mirrors", trickster.grid_position)
	if not bool(result.get("success", false)):
		_fail("smoke_and_mirrors failed: %s" % str(result.get("reason", "?")))
	var made: int = CombatManager.all_units.size() - before
	if made < 1:
		_fail("no images appeared")
	if made > 3:
		_fail("%d images appeared, and the perk promises at most three" % made)

	# An image cannot act, and is on the caster's side.
	for unit in CombatManager.all_units:
		if unit.has_meta("decoy_turns_left"):
			if unit.get_max_actions() != 0:
				_fail("an image can act")
			if unit.team != trickster.team:
				_fail("an image stands with the enemy")

	# And they fade.
	var duration: int = int(PerkSystem.get_perk_data("smoke_and_mirrors")
		.get("combat_data", {}).get("duration", 3))
	for _round in duration:
		CombatManager._tick_decoys()
	var left := 0
	for unit in CombatManager.all_units:
		if is_instance_valid(unit) and unit.has_meta("decoy_turns_left"):
			left += 1
	if left > 0:
		_fail("%d images were still standing after %d rounds" % [left, duration])
	_cleanup([trickster])
	_done()


func _check_a_pocket_can_be_picked() -> void:
	var thief := _make_unit(Vector2i(10, 10), 0)
	var mark := _make_unit(Vector2i(11, 10), 1)
	mark.character_data["inventory"] = ["health_potion", "iron_sword"]
	var before: int = ItemSystem.get_inventory_count("health_potion")

	var result: Dictionary = _use(thief, "the_invisible_hand", mark.grid_position)
	if not bool(result.get("success", false)):
		_fail("the_invisible_hand failed: %s" % str(result.get("reason", "?")))
	elif ItemSystem.get_inventory_count("health_potion") <= before:
		_fail("the stolen item did not arrive in the party's bag")
	elif mark.character_data["inventory"].has("health_potion"):
		_fail("the mark still has the potion")
	# Consumables first: the sword is still theirs.
	if not mark.character_data["inventory"].has("iron_sword"):
		_fail("the sword was taken ahead of the potion")
	_cleanup([thief, mark])
	_done()


func _check_an_empty_pocket_yields_nothing() -> void:
	var thief := _make_unit(Vector2i(10, 10), 0)
	var pauper := _make_unit(Vector2i(11, 10), 1)
	pauper.character_data["inventory"] = []
	var result: Dictionary = _use(thief, "the_invisible_hand", pauper.grid_position)
	if bool(result.get("success", false)):
		_fail("something was stolen from an empty inventory")

	# And an ally is not a mark.
	var friend := _make_unit(Vector2i(9, 10), 0)
	friend.character_data["inventory"] = ["health_potion"]
	if bool(_use(thief, "the_invisible_hand", friend.grid_position).get("success", false)):
		_fail("the thief picked an ally's pocket")
	_cleanup([thief, pauper, friend])
	_done()


## Arcane Archer: the spell is paid for when the arrow is drawn and lands with
## the attack, using the ranged accuracy that already decided the hit.
func _check_an_imbued_arrow_delivers_its_spell() -> void:
	var archer := _make_unit(Vector2i(10, 10), 0)
	archer.character_data["equipped_weapon"] = {
		"name": "Probe Bow", "type": "bow", "stats": {"range": 6, "damage": 6}}
	archer.character_data["skills"] = {"ranged": 9, "fire_magic": 9, "sorcery": 9}
	archer.character_data["known_spells"] = ["firebolt"]
	CharacterSystem.update_derived_stats(archer.character_data)
	archer.character_data["derived"]["accuracy"] = 999
	var mark := _make_unit(Vector2i(13, 10), 1)
	mark.character_data["derived"]["dodge"] = 0

	var mana_before: int = archer.current_mana
	var result: Dictionary = _use(archer, "arcane_archer", archer.grid_position)
	if not bool(result.get("success", false)):
		_fail("arcane_archer failed: %s" % str(result.get("reason", "?")))
	elif archer.current_mana >= mana_before:
		_fail("drawing the imbued arrow cost no mana")
	elif not archer.has_meta("imbued_spell"):
		_fail("nothing was imbued")

	# The arrow carries it home.
	mark.current_hp = mark.max_hp
	var shot: Dictionary = {}
	for _try in 20:
		archer.actions_remaining = 9
		CombatManager.turn_order = [archer]
		CombatManager.current_unit_index = 0
		shot = CombatManager.attack_unit(archer, mark)
		if bool(shot.get("hit", false)):
			break
		# A missed arrow keeps its spell, which is correct — draw again.
	if not shot.has("imbued_spell"):
		_fail("the shot did not deliver the spell (%s)" % str(shot))
	else:
		var delivered: Dictionary = shot.get("imbued_result", {})
		if (delivered.get("effects_applied", []) as Array).is_empty():
			_fail("the arrow reported a spell and the spell did nothing: %s"
				% str(delivered))
	if archer.has_meta("imbued_spell"):
		_fail("the imbued spell survived being delivered")

	# And every arrow after it is an ordinary arrow.
	for _try in 20:
		archer.actions_remaining = 9
		CombatManager.turn_order = [archer]
		CombatManager.current_unit_index = 0
		var second: Dictionary = CombatManager.attack_unit(archer, mark)
		if second.has("imbued_spell"):
			_fail("an arrow after the first carried a spell too")
			break
	_cleanup([archer, mark])
	_done()


## Magnetism: two Charm saves. Fail both and they change sides; fail one and
## they stop fighting.
func _check_talking_somebody_round() -> void:
	var speaker := _make_unit(Vector2i(10, 10), 0)
	var stubborn := _make_unit(Vector2i(12, 10), 1)
	var pliable := _make_unit(Vector2i(13, 10), 1)
	stubborn.character_data["attributes"]["charm"] = 60
	pliable.character_data["attributes"]["charm"] = 1
	CharacterSystem.update_derived_stats(stubborn.character_data)
	CharacterSystem.update_derived_stats(pliable.character_data)

	var recruited := 0
	var pacified := 0
	for _try in 20:
		pliable.team = 1
		pliable.status_effects.clear()
		_use(speaker, "magnetism", pliable.grid_position)
		if pliable.team == speaker.team:
			recruited += 1
		elif pliable.has_status("Pacified"):
			pacified += 1
	if recruited == 0:
		_fail("twenty attempts on somebody with Charm 1 recruited nobody")

	# Somebody with real presence is not talked round easily.
	var stubborn_recruited := 0
	for _try in 20:
		stubborn.team = 1
		stubborn.status_effects.clear()
		_use(speaker, "magnetism", stubborn.grid_position)
		if stubborn.team == speaker.team:
			stubborn_recruited += 1
	if stubborn_recruited >= recruited:
		_fail("Charm 60 was talked round %d times and Charm 1 %d times"
			% [stubborn_recruited, recruited])

	# One failed save of the two is a pause, not a recruitment. Somebody of
	# middling presence produces both outcomes over enough attempts, which is
	# the only way to see that the two branches are different.
	var middling := _make_unit(Vector2i(11, 11), 1)
	middling.character_data["attributes"]["charm"] = 14
	CharacterSystem.update_derived_stats(middling.character_data)
	var mid_recruited := 0
	var mid_pacified := 0
	for _try in 60:
		middling.team = 1
		middling.status_effects.clear()
		_use(speaker, "magnetism", middling.grid_position)
		if middling.team == speaker.team:
			mid_recruited += 1
		elif middling.has_status("Pacified"):
			mid_pacified += 1
	if mid_pacified == 0:
		_fail("sixty attempts and nobody was ever merely given pause — one "
			+ "failed save of the two is not its own outcome")
	_cleanup([middling])

	# Out of earshot is out of earshot.
	var distant := _make_unit(Vector2i(30, 30), 1)
	if bool(_use(speaker, "magnetism", distant.grid_position).get("success", false)):
		_fail("somebody twenty tiles away was talked round")
	_cleanup([speaker, stubborn, pliable, distant])
	_done()
