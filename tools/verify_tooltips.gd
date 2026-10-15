extends Node
## Headless verification for the hover-tooltip wording in TooltipText.
##
## Run: godot --headless res://tools/verify_tooltips.tscn
##
## Tooltips are the one part of the UI nobody can check without a screen, so
## this builds the same strings the game builds — from the real item, status
## and terrain tables — and checks they say what the data says. It also prints
## a few samples, so a run of this scene doubles as a look at the wording.
##
## The ritual check is the reason it exists: `ritual_metals` and
## `ritual_implements` were enforced by verify_item_materials.gd but never
## shown to the player. A Copper Phurba's tooltip must now say it serves Fire
## magic and is an instrument of Sorcery.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 7


func _ready() -> void:
	_check_copper_phurba_names_both_codings()
	_check_every_ritual_implement_is_explained()
	_check_non_ritual_items_say_nothing()
	_check_a_status_tooltip_reads_its_definition()
	_check_every_status_builds()
	_check_a_hazard_tile_explains_itself()
	_check_turn_order_names_the_unit()

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


func _sample(title: String, text: String) -> void:
	print("--- sample: %s ---\n%s\n" % [title, text])


func _check_copper_phurba_names_both_codings() -> void:
	var item: Dictionary = ItemSystem.get_item("plain_copper_phurba")
	if item.is_empty():
		_fail("plain_copper_phurba is not in items.json")
		_done()
		return
	var text: String = TooltipText.ritual_coding(item)
	_sample("Plain Copper Phurba (ritual section)", text)
	for want in ["Copper", "Fire magic", "phurba", "Sorcery", "Spells of both", "Consecration: Plain"]:
		if not want in text:
			_fail("the copper phurba's ritual text does not mention '%s'" % want)
	_sample("Blessed Silver Dorje (ritual section)",
		TooltipText.ritual_coding(ItemSystem.get_item("blessed_silver_dorje")))
	_sample("Plain Conch Drilbu (ritual section)",
		TooltipText.ritual_coding(ItemSystem.get_item("plain_conch_drilbu")))
	_sample("Blessed Citrine Mala (ritual section)",
		TooltipText.ritual_coding(ItemSystem.get_item("blessed_citrine_mala")))
	_done()


## Every metal-and-form implement the item verifier knows about must get a
## ritual section naming the skill its metal grants.
func _check_every_ritual_implement_is_explained() -> void:
	var metals: Dictionary = ItemSystem.get_equipment_tables().get("ritual_metals", {})
	var checked: int = 0
	var wrong: Array[String] = []
	for item_id in ItemSystem.get_all_item_ids():
		var item: Dictionary = ItemSystem.get_item(item_id)
		if str(item.get("type", "")) != "focus":
			continue
		var material: String = str(item.get("material", ""))
		if not metals.has(material):
			continue
		var grants: String = str(metals[material].get("grants", ""))
		if not item.get("skill_bonuses", {}).has(grants):
			continue
		checked += 1
		var text: String = TooltipText.ritual_coding(item)
		var skill_words: String = grants.replace("_", " ")
		if not skill_words.to_lower() in text.to_lower():
			wrong.append(item_id)
	if checked < 50:
		_fail("only %d ritual implements were found — expected well over a hundred" % checked)
	if not wrong.is_empty():
		_fail("%d implements' tooltips miss their metal's skill: %s"
			% [wrong.size(), wrong.slice(0, 4)])
	_done()


func _check_non_ritual_items_say_nothing() -> void:
	for item_id in ["plain_bronze_melong"]:
		var text: String = TooltipText.ritual_coding(ItemSystem.get_item(item_id))
		_sample("Plain Bronze Melong (ritual section)", text)
		if "serves" in text:
			_fail("the bronze melong claims a metal coding it does not carry")
	for item_id in ItemSystem.get_all_item_ids():
		var item: Dictionary = ItemSystem.get_item(item_id)
		if str(item.get("type", "")) == "focus":
			continue
		if TooltipText.ritual_coding(item) != "":
			_fail("%s is not a focus but got a ritual section" % item_id)
			break
	_done()


func _check_a_status_tooltip_reads_its_definition() -> void:
	var text: String = TooltipText.status("Burning", {"status": "Burning", "duration": 2, "value": 0})
	_sample("Burning, 2 turns left", text)
	for want in ["Burning (debuff)", "2 turns remaining", "5 fire damage each turn", "Cured by:"]:
		if not want in text:
			_fail("the Burning tooltip does not say '%s'" % want)
	var stunned: String = TooltipText.status("Stunned", {"status": "Stunned", "duration": 1})
	_sample("Stunned, 1 turn left", stunned)
	if not "Save: Constitution at end of turn" in stunned:
		_fail("the Stunned tooltip does not give its save")
	var grappled_def: Dictionary = {}
	for sname in CombatManager._status_effects:
		if str(CombatManager._status_effects[sname].get("description", "")) != "":
			grappled_def = CombatManager._status_effects[sname]
			var with_desc: String = TooltipText.status(sname, {"status": sname, "duration": 3})
			_sample("%s (has a description)" % sname, with_desc)
			if not str(grappled_def.description) in with_desc:
				_fail("%s's description is missing from its tooltip" % sname)
			break
	_done()


func _check_every_status_builds() -> void:
	var count: int = 0
	for sname in CombatManager._status_effects:
		var text: String = TooltipText.status(sname, {"status": sname, "duration": 2})
		if not text.begins_with(str(sname).replace("_", " ")):
			_fail("%s's tooltip does not start with its name" % sname)
			break
		count += 1
	if count < 150:
		_fail("only %d statuses were described — expected ~187" % count)
	_done()


func _check_a_hazard_tile_explains_itself() -> void:
	var grid := CombatGrid.new()
	add_child(grid)
	var forest_id: int = int(Ground.by_key("forest").get("id", 2))
	grid.setup_from_map({"size": Vector2i(10, 10),
		"tiles": {"3,3": CombatGrid.TileType.DIFFICULT},
		"grounds": {"3,3": forest_id},
		"obstacles": [], "effects": [], "heights": []})
	grid.add_terrain_effect(Vector2i(3, 3), CombatGrid.TerrainEffect.FIRE, 2)
	grid.tiles[Vector2i(3, 3)].height = 1
	var text: String = TooltipText.tile(grid, Vector2i(3, 3),
		[{"name": "Gravity Well", "turns_left": 3, "def": {}},
		 {"name": "Snare", "turns_left": 3, "def": {"trap": true}}])
	_sample("Burning forest tile, height 1, in a gravity well", text)
	for want in ["Forest", "Difficult ground", "Height 1", "Fire (2 turns)",
			"5 fire damage", "Fire spells cast from here", "Gravity Well (3 turns)"]:
		if not want in text:
			_fail("the hazard tile tooltip does not say '%s'" % want)
	if "Snare" in text:
		_fail("a hidden trap was named in the tile tooltip")
	if TooltipText.tile(grid, Vector2i(0, 0)) != "":
		_fail("a plain empty tile should say nothing, got: %s"
			% TooltipText.tile(grid, Vector2i(0, 0)))
	grid.queue_free()
	_done()


func _check_turn_order_names_the_unit() -> void:
	var unit := CombatUnit.new()
	unit.unit_name = "Tenzin"
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 40
	unit.current_hp = 31
	unit.status_effects.append({"status": "Hasted", "duration": 2, "value": 0})
	var text: String = TooltipText.turn_order_unit(unit)
	_sample("Turn order: Tenzin", text)
	for want in ["Tenzin", "HP: 31/40", "Initiative:", "Hasted (2 turns)"]:
		if not want in text:
			_fail("the turn-order tooltip does not say '%s'" % want)
	unit.queue_free()
	_done()
