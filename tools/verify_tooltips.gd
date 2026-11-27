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
const EXPECTED_CHECKS: int = 18


func _ready() -> void:
	_check_copper_phurba_names_both_codings()
	_check_every_ritual_implement_is_explained()
	_check_non_ritual_items_say_nothing()
	_check_a_status_tooltip_reads_its_definition()
	_check_every_status_builds()
	_check_a_hazard_tile_explains_itself()
	_check_turn_order_names_the_unit()
	# The 2026-10-15 sweep's "UI and legibility" group (TODO §15).
	_check_move_mode_shows_cover_and_hazard_together()
	_check_hazard_text_and_rule_share_one_table()
	_check_status_tooltip_names_retaliation_aura_spread()
	_check_every_status_has_its_own_icon()
	_check_summon_terrain_bonus_is_shown()
	_check_set_bonus_text_matches_the_stats_added()
	_check_popups_are_centred_over_the_unit()
	_check_a_critical_main_hit_says_crit()
	# Stage 2b Task 7: every status line is worded from the new fields.
	_check_status_tooltip_from_fields()
	_check_every_flag_has_words()
	_check_party_line_lists_lasting_damage()

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
	for want in ["Burning (debuff)", "2 turns remaining", "5 fire damage at the start of each turn", "Cured by:"]:
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


# ============================================
# UI and legibility (TODO §15, 2026-10-15 sweep)
# ============================================

## Move mode used to hide the tile label and show only a cover label, so a
## fire tile said nothing while you were deciding whether to step on it. The
## two are one label now: cover on top, the tile's own facts below.
func _check_move_mode_shows_cover_and_hazard_together() -> void:
	var grid := CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(10, 10), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	grid.add_terrain_effect(Vector2i(4, 4), CombatGrid.TerrainEffect.FIRE, 2)
	var text: String = TooltipText.move_tile(grid, Vector2i(4, 4), [],
		{"has_cover": true, "dodge_bonus": 15, "obstacle_name": "Tree"})
	_sample("Move mode: burning tile behind a tree", text)
	for want in ["+15% dodge", "Tree", "Fire (2 turns)", "5 fire damage"]:
		if not want in text:
			_fail("the move-mode tile label does not say '%s'" % want)
	if TooltipText.move_tile(grid, Vector2i(4, 4)) != TooltipText.tile(grid, Vector2i(4, 4)):
		_fail("with no cover, the move-mode label should be the plain tile label")
	# The arena must not bail out of the tile label in move mode any more.
	var f := FileAccess.open("res://scripts/combat/combat_arena.gd", FileAccess.READ)
	var src: String = f.get_as_text() if f != null else ""
	if src.contains("_cover_tooltip") or not src.contains("TooltipText.move_tile("):
		_fail("combat_arena still keeps a separate cover label instead of TooltipText.move_tile")
	grid.queue_free()
	_done()


## The hover text and _process_terrain_effects() both read
## CombatGrid.TERRAIN_HAZARDS. Every hazard must describe itself from the
## table, and the rule must do what the words say — checked on a real unit
## standing on fire and on cursed ground.
func _check_hazard_text_and_rule_share_one_table() -> void:
	for effect in CombatGrid.TERRAIN_HAZARDS:
		var hazard: Dictionary = CombatGrid.TERRAIN_HAZARDS[effect]
		var text: String = TooltipText.terrain_hazard_text(effect, 7)
		if text == "":
			_fail("terrain effect %d has a hazard entry but no tooltip text" % effect)
			continue
		var status_name: String = str(hazard.get("status", "")).replace("_", " ")
		if status_name != "" and not status_name in text:
			_fail("'%s' does not name the %s it applies" % [text, status_name])
		var dtype: String = str(hazard.get("damage_type", ""))
		if dtype != "" and not ("7 %s damage" % DamageType.display_name(dtype).to_lower()) in text:
			_fail("'%s' does not give its 7 %s damage" % [text, dtype])
		if float(hazard.get("status_chance", 1.0)) < 1.0 and not "% chance" in text:
			_fail("'%s' does not give its status chance" % text)
	_sample("Cursed ground, value 2", TooltipText.terrain_hazard_text(CombatGrid.TerrainEffect.CURSED, 2))
	if TooltipText.terrain_hazard_text(CombatGrid.TerrainEffect.CURSED, 2) \
			!= "2 black damage at turn start, 30% chance of Cursed":
		_fail("cursed ground reads '%s'" % TooltipText.terrain_hazard_text(CombatGrid.TerrainEffect.CURSED, 2))

	# The rule: a unit on fire ground takes the tile's damage and Burning.
	var grid := CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(10, 10), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	var old_grid = CombatManager.combat_grid
	CombatManager.combat_grid = grid
	var unit := CombatUnit.new()
	unit.unit_name = "Walker"
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 1000
	unit.current_hp = 1000
	unit.grid_position = Vector2i(2, 2)
	grid.add_terrain_effect(Vector2i(2, 2), CombatGrid.TerrainEffect.FIRE, 3)
	var fire_value: int = int(grid.tiles[Vector2i(2, 2)].effect_value)
	CombatManager._process_terrain_effects(unit)
	if not unit.has_status("Burning"):
		_fail("standing on fire did not apply Burning, though the table says it does")
	if unit.current_hp >= 1000 or fire_value <= 0:
		_fail("standing on fire did no damage (HP %d, tile value %d)" % [unit.current_hp, fire_value])
	# Ice: Slowed, no damage.
	unit.status_effects.clear()
	unit.current_hp = 1000
	grid.remove_terrain_effect(Vector2i(2, 2))
	grid.add_terrain_effect(Vector2i(2, 2), CombatGrid.TerrainEffect.ICE, 3)
	CombatManager._process_terrain_effects(unit)
	if not unit.has_status("Slowed") or unit.current_hp != 1000:
		_fail("ice should slow without damage (Slowed: %s, HP %d)" % [unit.has_status("Slowed"), unit.current_hp])
	CombatManager.combat_grid = old_grid
	unit.queue_free()
	grid.queue_free()
	_done()


## retaliation, aura and spread are structured data on 17 statuses, and the
## tooltip used to say nothing about any of them.
func _check_status_tooltip_names_retaliation_aura_spread() -> void:
	var lightning: String = TooltipText.status("Lightning_Form", {"status": "Lightning_Form", "duration": 2})
	_sample("Lightning Form (retaliation)", lightning)
	for want in ["When struck in melee", "10 lightning damage", "30% chance of Stunned"]:
		if not want in lightning:
			_fail("the Lightning Form tooltip does not say '%s'" % want)
	var mirror: String = TooltipText.status("Pain_Mirror", {"status": "Pain_Mirror", "duration": 2})
	if not "When struck: reflects 50%" in mirror:
		_fail("the Pain Mirror tooltip does not explain its reflection: %s" % mirror)
	var soothing: String = TooltipText.status("Soothing_Presence", {"status": "Soothing_Presence", "duration": 2})
	_sample("Soothing Presence (aura)", soothing)
	for want in ["Aura: Soothing Presence", "allies within 2", "heals 5 each turn"]:
		if not want in soothing:
			_fail("the Soothing Presence tooltip does not say '%s'" % want)
	var burning: String = TooltipText.status("Burning", {"status": "Burning", "duration": 2})
	if not "Can spread to an adjacent unit (15% chance each turn)" in burning:
		_fail("the Burning tooltip does not say it spreads: %s" % burning)
	# Every status that declares one of the three gets a line for it.
	for sname in CombatManager._status_effects:
		var def: Dictionary = CombatManager._status_effects[sname]
		var text: String = TooltipText.status(sname, {"status": sname, "duration": 2}, def)
		if _has_trigger(def, "struck") and not "When struck" in text:
			_fail("%s declares retaliation but its tooltip does not say so" % sname)
		if def.has("aura") and not "Aura:" in text:
			_fail("%s declares an aura but its tooltip does not say so" % sname)
		if def.has("spread") and not "spread" in text:
			_fail("%s declares spread but its tooltip does not say so" % sname)
	_done()


## Icons come from statuses.json's `icon`, not a 25-name match — every status
## brings its own, and an unknown one falls back to "•".
func _check_every_status_has_its_own_icon() -> void:
	var missing: Array[String] = []
	for sname in CombatManager._status_effects:
		var icon: String = CombatUnit.status_icon(sname)
		if icon == "" or icon == CombatUnit.STATUS_ICON_FALLBACK:
			missing.append(sname)
		elif icon.length() > 3:
			_fail("%s's icon '%s' is too long to sit in a row over a head" % [sname, icon])
	if not missing.is_empty():
		_fail("%d statuses show the bare fallback icon: %s" % [missing.size(), missing.slice(0, 5)])
	if CombatUnit.status_icon("Burning") != "🔥":
		_fail("Burning's icon is '%s', expected the flame" % CombatUnit.status_icon("Burning"))
	if CombatUnit.status_icon("__no_such_status__") != CombatUnit.STATUS_ICON_FALLBACK:
		_fail("an unknown status should fall back to '%s'" % CombatUnit.STATUS_ICON_FALLBACK)
	_done()


## The summoning terrain bonus was only ever announced in the log after the
## cast. The spell tooltip now says it first, from the same rule.
func _check_summon_terrain_bonus_is_shown() -> void:
	var water_id: int = int(Ground.by_key("water").get("id", 5))
	var plains_id: int = int(Ground.by_key("plains").get("id", 0))
	var water_summon: Dictionary = {}
	var plain_spell: Dictionary = {}
	var spells: Dictionary = CharacterSystem.get_spell_database()
	for spell_id in spells:
		var spell = spells[spell_id]
		if typeof(spell) != TYPE_DICTIONARY:
			continue
		var schools: Array = spell.get("schools", []).map(func(x): return str(x).to_lower())
		if water_summon.is_empty() and "summoning" in schools and "water" in schools:
			water_summon = spell
		if plain_spell.is_empty() and not "summoning" in schools:
			plain_spell = spell
	if water_summon.is_empty():
		_fail("no Water + Summoning spell found to test the terrain bonus with")
		_done()
		return
	var line: String = TooltipText.summon_terrain_line(water_summon, water_id)
	_sample("%s on water" % water_summon.get("name", "?"), line)
	if not "the living water" in line or not "+25% spellpower" in line:
		_fail("a water summoning on water does not show its bonus: '%s'" % line)
	if TooltipText.summon_terrain_line(water_summon, plains_id) != "":
		_fail("a water summoning on plains claims a terrain bonus")
	if TooltipText.summon_terrain_line(water_summon, -1) != "":
		_fail("a water summoning with no battlefield terrain claims a bonus")
	if TooltipText.summon_terrain_line(plain_spell, water_id) != "":
		_fail("a non-summoning spell claims the summoning terrain bonus")
	var f := FileAccess.open("res://scripts/combat/combat_arena.gd", FileAccess.READ)
	var src: String = f.get_as_text() if f != null else ""
	if not src.contains("TooltipText.summon_terrain_line("):
		_fail("the arena's spell tooltip does not show the summoning terrain bonus")
	_done()


## The Vajra & Bell text was typed into item_tooltip.gd by hand. It is built
## from ItemSystem.SET_BONUSES now, and that same table is what is added.
func _check_set_bonus_text_matches_the_stats_added() -> void:
	var text: String = TooltipText.set_bonus("dorje_drilbu")
	_sample("Dorje + Drilbu set", text)
	for want in ["Vajra & Bell", "+3 Spellpower", "+3 Mana", "+2 Initiative"]:
		if not want in text:
			_fail("the set text does not say '%s'" % want)
	var dorje: String = "plain_copper_dorje"
	var drilbu: String = "plain_copper_drilbu"
	if ItemSystem.get_item(dorje).is_empty() or ItemSystem.get_item(drilbu).is_empty():
		_fail("the copper dorje/drilbu are not in items.json")
		_done()
		return
	var character: Dictionary = CharacterSystem.create_blank_character()
	character["equipment"]["weapon_set_1"] = {"main": dorje, "off": ""}
	var alone: Dictionary = ItemSystem.calculate_equipment_stats(character)
	character["equipment"]["weapon_set_1"] = {"main": dorje, "off": drilbu}
	var paired: Dictionary = ItemSystem.calculate_equipment_stats(character)
	var drilbu_stats: Dictionary = ItemSystem.get_item(drilbu).get("stats", {})
	var set_stats: Dictionary = ItemSystem.SET_BONUSES["dorje_drilbu"]["stats"]
	for key in set_stats:
		var expected: int = int(alone.get(key, 0)) + int(drilbu_stats.get(key, 0)) + int(set_stats[key])
		if int(paired.get(key, 0)) != expected:
			_fail("paired %s is %d, expected %d (dorje + drilbu + set)" % [key, int(paired.get(key, 0)), expected])
	var f := FileAccess.open("res://scripts/ui/item_tooltip.gd", FileAccess.READ)
	var src: String = f.get_as_text() if f != null else ""
	if src.contains("+3 Spellpower"):
		_fail("item_tooltip.gd still hard-codes the set's numbers")
	_done()


## The unit's origin is its centre. A popup Label with no width started there
## and ran right, so "centred" text sat to the right of the unit. Each popup
## must now be a box whose middle is the unit's middle.
func _check_popups_are_centred_over_the_unit() -> void:
	var unit := CombatUnit.new()
	unit.unit_name = "Centre"
	unit.character_data = CharacterSystem.create_blank_character()
	CharacterSystem.update_derived_stats(unit.character_data)
	add_child(unit)
	unit.max_hp = 1000
	unit.current_hp = 1000
	var before: Array = unit.get_children()
	unit.take_damage(12)
	unit.heal(3)
	unit.show_action_name("A Rather Long Spell Name Indeed")
	unit.show_combat_text("Miss!")
	unit.show_status_applied("Burning")
	unit.show_status_expired("Burning")
	var popups: int = 0
	for child in unit.get_children():
		if child in before or not child is Control:
			continue
		popups += 1
		var c: Control = child
		var middle: float = c.position.x + c.size.x / 2.0
		if absf(middle) > 1.0 or c.size.x < 20.0:
			_fail("popup '%s' is centred at x=%.1f (width %.0f), not over the unit"
				% [c.get("text"), middle, c.size.x])
	if popups != 6:
		_fail("expected 6 popups, found %d" % popups)
	unit.queue_free()
	_done()


## Extra arms said "crit!"; the main hit said nothing. A crit through
## CombatManager.attack_unit now reads "N crit!" too.
func _check_a_critical_main_hit_says_crit() -> void:
	var grid := CombatGrid.new()
	add_child(grid)
	grid.setup_from_map({"size": Vector2i(10, 10), "tiles": {}, "obstacles": [],
		"effects": [], "heights": []})
	var old_grid = CombatManager.combat_grid
	CombatManager.combat_grid = grid
	var units: Array[CombatUnit] = []
	for team in 2:
		var u := CombatUnit.new()
		u.unit_name = "Crit%d" % team
		u.team = team
		u.character_data = CharacterSystem.create_blank_character()
		u.character_data["skills"] = {"unarmed": 5}
		CharacterSystem.update_derived_stats(u.character_data)
		u.character_data["derived"]["dodge"] = 0
		u.character_data["derived"]["accuracy"] = 999
		u.character_data["derived"]["crit_chance"] = 100
		add_child(u)
		u.max_hp = 100000
		u.current_hp = 100000
		u.grid_position = Vector2i(4 + team, 4)
		grid.unit_positions[u.grid_position] = u
		CombatManager.all_units.append(u)
		units.append(u)
	var attacker: CombatUnit = units[0]
	var defender: CombatUnit = units[1]
	var saw_crit := false
	for _try in 10:
		attacker.actions_remaining = 9
		CombatManager.turn_order = [attacker]
		CombatManager.current_unit_index = 0
		var before: Array = defender.get_children()
		var result: Dictionary = CombatManager.attack_unit(attacker, defender)
		if not (result.get("hit", false) and result.get("crit", false)):
			continue
		saw_crit = true
		var found := false
		for child in defender.get_children():
			if child is Label and not child in before and child.text.ends_with(" crit!") \
					and child.text.trim_suffix(" crit!").is_valid_int():
				found = true
		if not found:
			_fail("a critical main hit's damage number does not say 'crit!'")
		if defender.next_damage_is_crit:
			_fail("the crit flag was left set after the hit — the next damage would say crit")
		break
	if not saw_crit:
		_fail("ten swings at 100% crit and 999 accuracy, and no critical hit landed")
	# A plain hit stays a plain number.
	var plain := CombatUnit.new()
	add_child(plain)
	plain.max_hp = 100
	plain.current_hp = 100
	var kids: Array = plain.get_children()
	plain.take_damage(4)
	for child in plain.get_children():
		if child is Label and not child in kids and child.text != "4":
			_fail("a plain hit reads '%s', expected '4'" % child.text)
	plain.queue_free()
	for u in units:
		grid.remove_unit(u)
		CombatManager.all_units.erase(u)
		u.queue_free()
	CombatManager.turn_order = []
	CombatManager.combat_grid = old_grid
	grid.queue_free()
	_done()


## True when the status has a trigger on `on` (retaliation is `struck`).
func _has_trigger(def: Dictionary, on: String) -> bool:
	for t in def.get("triggers", []):
		if str(t.get("on", "")) == on:
			return true
	return false


## Stage 2b Task 7: the status tooltip is built from the status's fields
## (describe_effects / describe_flags / describe_periodic / describe_triggers),
## one example of each kind, and every status builds a non-empty tooltip.
func _check_status_tooltip_from_fields() -> void:
	var cases: Dictionary = {
		# a stat buff
		"Hasted": ["+5 initiative", "+2 movement"],
		# a control with flags
		"Stunned": ["Cannot act", "Skips next turn", "Save: Constitution"],
		# damage over time
		"Burning": ["5 fire damage at the start of each turn"],
		# a retaliation
		"Lightning_Form": ["When struck in melee", "10 lightning damage to the attacker",
			"30% chance of Stunned (1 turn) on the attacker", "Immune to lightning",
			"Physical resistance +50%"],
		# statuses named for a number (spec section 7)
		"Finesse_Plus_2": ["+2 Finesse"],
		"Fire_Resistance_25": ["Fire resistance +25%"],
	}
	for sname in cases:
		var text: String = TooltipText.status(sname, {"status": sname, "duration": 2})
		_sample("%s (from fields)" % sname, text)
		for want in cases[sname]:
			if not want in text:
				_fail("the %s tooltip does not say '%s'" % [sname, want])
	# In the abstract (no live entry) a borrowed number says where it comes from.
	var abstract: String = TooltipText.status("Burning")
	if not "5 fire damage (or the spell's value) at the start of each turn" in abstract:
		_fail("an abstract Burning should say its 5 is a default: %s" % abstract)
	for sname in CombatManager._status_effects:
		if TooltipText.status(sname, {"status": sname, "duration": 2}).strip_edges() == "":
			_fail("%s has an empty tooltip" % sname)
	# The helpers are reusable on their own, for spells in stage 3.
	var lines: PackedStringArray = TooltipText.describe_effects([
		{"op": "damage", "amount": 3, "type": "piercing", "to": "source"}], {}, "struck")
	if lines.size() != 1 or lines[0] != "3 piercing damage to the attacker":
		_fail("describe_effects words a struck retaliation as %s" % [lines])
	var flags: PackedStringArray = TooltipText.describe_flags(["cannot_move", "immune:Charmed"])
	if flags != PackedStringArray(["Cannot move", "Immune to Charmed"]):
		_fail("describe_flags gave %s" % [flags])
	_done()


## Every name in EffectVocab.FLAGS has its own words in TooltipText.FLAG_LABELS,
## and the words are not empty.
func _check_every_flag_has_words() -> void:
	for flag in EffectVocab.FLAGS:
		if not TooltipText.FLAG_LABELS.has(flag):
			_fail("flag '%s' has no words in TooltipText.FLAG_LABELS" % flag)
		elif str(TooltipText.FLAG_LABELS[flag]).strip_edges() == "":
			_fail("flag '%s' has empty words" % flag)
	for flag in TooltipText.FLAG_LABELS:
		if not flag in EffectVocab.FLAGS:
			_fail("FLAG_LABELS has '%s', which is not a flag" % flag)
	_done()


## The party screen's line for lasting damage, from a scratch character (never
## a save): what was lost and what clears it, and no line when nothing is lost.
func _check_party_line_lists_lasting_damage() -> void:
	var scratch: Dictionary = CharacterSystem.create_blank_character()
	if TooltipText.lasting_damage_line(scratch) != "":
		_fail("a character with no lasting damage should get no line")
	scratch["damaged_values"] = [
		{"value": "attribute.focus", "amount": 2, "source": "curse",
			"cleared_by": [{"rest": "full"}, {"heal": {"school": "white", "min_level": 5}}]},
		{"value": "skill.swords", "amount": 1, "source": "wound", "cleared_by": []}]
	var line: String = TooltipText.lasting_damage_line(scratch)
	_sample("party screen line", line)
	for want in ["Focus \u22122 (until full rest or White magic 5)", "Swords \u22121 (until full rest or a restore)"]:
		if not want in line:
			_fail("the party line '%s' does not say '%s'" % [line, want])
	_done()
