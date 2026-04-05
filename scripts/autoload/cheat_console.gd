extends CanvasLayer
## CheatConsole — Toggle with F12. Type commands to manipulate game state for testing.
##
## Commands:
##   addxp <amount>         — Grant XP to current character
##   addgold <amount>       — Grant gold
##   addfood <amount>       — Grant food
##   addherbs <amount>      — Grant herbs
##   addscrap <amount>      — Grant scrap
##   addreagents <amount>   — Grant reagents
##   heal                   — Full heal party (HP, mana, stamina)
##   godmode                — Toggle god mode (party takes no damage)
##   learnspell <id>        — Learn a specific spell
##   allspells              — Learn all spells the current character qualifies for
##   addperk <id>           — Grant a perk to current character
##   addcompanion <id>      — Recruit a companion for free (use 'list companions' to see IDs)
##   additem <id> [count]   — Add item(s) to inventory
##   tactician              — Grant the Tactician upgrade
##   goto <world>           — Travel to a world (hell, hungry_ghost, animal, human, demigod, god)
##   list <type>            — List available IDs (companions, spells, items, perks, worlds)
##   help / cheatlist       — Show this help text

var _panel: PanelContainer
var _input: LineEdit
var _output: RichTextLabel
var _visible: bool = false

# God mode flag — checked by CombatManager.apply_damage
var god_mode: bool = false


func _ready() -> void:
	layer = 100  # Always on top
	_build_ui()
	_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug_console"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_visible = not _visible
	if _visible:
		_panel.show()
		_input.grab_focus()
		_input.text = ""
	else:
		_panel.hide()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.1
	_panel.anchor_right = 0.9
	_panel.anchor_top = 0.05
	_panel.anchor_bottom = 0.55
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.08, 0.92)
	sb.border_color = Color(0.7, 0.5, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	_panel.add_child(vbox)

	var title = Label.new()
	title.text = "Cheat Console (F12 to close)"
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", Color(0.8, 0.8, 0.75))
	_output.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(_output)

	_input = LineEdit.new()
	_input.placeholder_text = "Type a command... (try 'help')"
	_input.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	_input.add_theme_font_size_override("font_size", 14)
	_input.text_submitted.connect(_on_command_submitted)
	vbox.add_child(_input)

	add_child(_panel)


func _log(text: String) -> void:
	_output.append_text(text + "\n")


func _log_ok(text: String) -> void:
	_log("[color=green]✓[/color] " + text)


func _log_err(text: String) -> void:
	_log("[color=red]✗[/color] " + text)


func _on_command_submitted(text: String) -> void:
	_input.text = ""
	if text.strip_edges().is_empty():
		return
	_log("[color=yellow]> " + text + "[/color]")

	var parts = text.strip_edges().split(" ", false)
	if parts.is_empty():
		return

	var cmd = parts[0].to_lower()
	var args = parts.slice(1)

	match cmd:
		"help", "cheatlist":
			_cmd_help()
		"addxp":
			_cmd_addxp(args)
		"addgold":
			_cmd_addgold(args)
		"addfood":
			_cmd_addfood(args)
		"addherbs":
			_cmd_add_resource("herbs", args)
		"addscrap":
			_cmd_add_resource("scrap", args)
		"addreagents":
			_cmd_add_resource("reagents", args)
		"heal":
			_cmd_heal()
		"godmode":
			_cmd_godmode()
		"learnspell":
			_cmd_learnspell(args)
		"allspells":
			_cmd_allspells()
		"addperk":
			_cmd_addperk(args)
		"addcompanion":
			_cmd_addcompanion(args)
		"additem":
			_cmd_additem(args)
		"tactician":
			_cmd_tactician()
		"goto":
			_cmd_goto(args)
		"list":
			_cmd_list(args)
		_:
			_log_err("Unknown command: " + cmd + ". Type 'help' for commands.")


# ── Command implementations ──────────────────────────────────────────────────

func _cmd_help() -> void:
	_log("[color=gold]── Cheat Console Commands ──[/color]")
	_log("  addxp <n>          Grant XP to current character")
	_log("  addgold <n>        Grant gold")
	_log("  addfood <n>        Grant food")
	_log("  addherbs <n>       Grant herbs")
	_log("  addscrap <n>       Grant scrap")
	_log("  addreagents <n>    Grant reagents")
	_log("  heal               Full heal entire party")
	_log("  godmode            Toggle god mode")
	_log("  learnspell <id>    Learn a spell")
	_log("  allspells          Learn all eligible spells")
	_log("  addperk <id>       Grant a perk")
	_log("  addcompanion <id>  Recruit companion for free")
	_log("  additem <id> [n]   Add item(s) to inventory")
	_log("  tactician          Grant Tactician upgrade")
	_log("  goto <world>       Travel to world (reloads overworld)")
	_log("  list <type>        List IDs (companions/spells/items/perks/worlds)")
	_log("  help / cheatlist   Show this list")


func _cmd_addxp(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: addxp <amount>")
		return
	var amount = int(args[0])
	var char_data = CharacterSystem.get_player()
	if char_data.is_empty():
		_log_err("No active character")
		return
	char_data["xp"] = char_data.get("xp", 0) + amount
	char_data["free_xp"] = char_data.get("free_xp", 0) + amount
	_log_ok("Granted %d XP to %s (total: %d, free: %d)" % [amount, char_data.get("name", "???"), char_data.xp, char_data.free_xp])


func _cmd_addgold(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: addgold <amount>")
		return
	var amount = int(args[0])
	GameState.gold += amount
	_log_ok("Added %d gold (total: %d)" % [amount, GameState.gold])


func _cmd_addfood(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: addfood <amount>")
		return
	var amount = int(args[0])
	GameState.food += amount
	_log_ok("Added %d food (total: %d)" % [amount, GameState.food])


func _cmd_add_resource(resource: String, args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: add%s <amount>" % resource)
		return
	var amount = int(args[0])
	GameState.set(resource, GameState.get(resource) + amount)
	_log_ok("Added %d %s (total: %d)" % [amount, resource, GameState.get(resource)])


func _cmd_heal() -> void:
	var party = CharacterSystem.get_party()
	if party.is_empty():
		_log_err("No party members")
		return
	for char_data in party:
		char_data["current_hp"] = char_data.get("max_hp", char_data.get("derived", {}).get("max_hp", 100))
		char_data["current_mana"] = char_data.get("max_mana", char_data.get("derived", {}).get("max_mana", 50))
		char_data["current_stamina"] = char_data.get("max_stamina", char_data.get("derived", {}).get("max_stamina", 20))
	_log_ok("Healed %d party members to full HP/Mana/Stamina" % party.size())


func _cmd_godmode() -> void:
	god_mode = not god_mode
	if god_mode:
		_log_ok("God mode [color=green]ON[/color] — party takes no damage")
	else:
		_log_ok("God mode [color=red]OFF[/color]")


func _cmd_learnspell(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: learnspell <spell_id>")
		return
	var spell_id = args[0].to_lower()
	var char_data = CharacterSystem.get_player()
	if char_data.is_empty():
		_log_err("No active character")
		return
	if CharacterSystem.learn_spell(char_data, spell_id):
		_log_ok("Learned spell: %s" % spell_id)
	else:
		_log_err("Already known or invalid spell: %s" % spell_id)


func _cmd_allspells() -> void:
	var char_data = CharacterSystem.get_player()
	if char_data.is_empty():
		_log_err("No active character")
		return

	var skills = char_data.get("skills", {})
	var spell_db = CombatManager._spell_database
	var count = 0

	for spell_id in spell_db:
		if spell_id == "notes":
			continue
		var spell = spell_db[spell_id]
		if not spell is Dictionary:
			continue
		var required_level = spell.get("level", 1)
		var schools = spell.get("schools", [])
		var eligible = false

		for school in schools:
			var school_lower = school.to_lower()
			var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
			if skills.get(skill_name, 0) >= required_level:
				eligible = true
				break

		if eligible and CharacterSystem.learn_spell(char_data, spell_id):
			count += 1

	_log_ok("Learned %d new spells for %s" % [count, char_data.get("name", "???")])


func _cmd_addperk(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: addperk <perk_id>")
		return
	var perk_id = args[0].to_lower()
	var char_data = CharacterSystem.get_player()
	if char_data.is_empty():
		_log_err("No active character")
		return
	if not "perks" in char_data:
		char_data["perks"] = []
	if perk_id in char_data.perks:
		_log_err("Already has perk: %s" % perk_id)
		return
	char_data.perks.append(perk_id)
	_log_ok("Granted perk: %s" % perk_id)


func _cmd_addcompanion(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: addcompanion <id> (use 'list companions' to see IDs)")
		return
	var comp_id = args[0].to_lower()
	var result = CompanionSystem.recruit(comp_id, true)
	if result.is_empty():
		_log_err("Failed to recruit '%s' — invalid ID or party full" % comp_id)
	else:
		_log_ok("Recruited %s!" % result.get("name", comp_id))


func _cmd_additem(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: additem <item_id> [count]")
		return
	var item_id = args[0].to_lower()
	var count = int(args[1]) if args.size() > 1 else 1
	if ItemSystem.add_to_inventory(item_id, count):
		_log_ok("Added %dx %s to inventory" % [count, item_id])
	else:
		_log_err("Failed to add item '%s' — invalid ID?" % item_id)


func _cmd_tactician() -> void:
	var char_data = CharacterSystem.get_player()
	if char_data.is_empty():
		_log_err("No active character")
		return
	if not "upgrades" in char_data:
		char_data["upgrades"] = []
	if "tactician" in char_data.upgrades:
		_log_err("Already has Tactician upgrade")
		return
	char_data.upgrades.append("tactician")
	_log_ok("Granted Tactician upgrade to %s" % char_data.get("name", "???"))


func _cmd_goto(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: goto <world> (hell, hungry_ghost, animal, human, demigod, god)")
		return
	var world = args[0].to_lower()
	if not world in GameState.WORLDS:
		_log_err("Unknown world: %s. Valid: %s" % [world, ", ".join(GameState.WORLDS.keys())])
		return
	GameState.current_world = world
	GameState.returning_from_combat = false
	_log_ok("Travelling to %s..." % world)
	_toggle()
	get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")


func _cmd_list(args: Array) -> void:
	if args.is_empty():
		_log_err("Usage: list <companions|spells|items|perks|worlds>")
		return

	match args[0].to_lower():
		"companions":
			var defs = CompanionSystem.get_all_definitions()
			_log("[color=gold]Companions (%d):[/color]" % defs.size())
			for id in defs:
				var name = defs[id].get("name", id)
				_log("  %s — %s" % [id, name])

		"spells":
			var db = CombatManager._spell_database
			var count = 0
			_log("[color=gold]Spells (first 30):[/color]")
			for id in db:
				if id == "notes" or not db[id] is Dictionary:
					continue
				if count >= 30:
					_log("  ... and more. Use 'learnspell <id>' with a specific ID.")
					break
				var spell = db[id]
				_log("  %s — %s (Lv%d)" % [id, spell.get("name", id), spell.get("level", 1)])
				count += 1

		"items":
			_log("[color=gold]Use ItemSystem item IDs from resources/data/items.json[/color]")
			_log("  Common types: health_potion, mana_potion, bomb_fire, rations")

		"perks":
			var perk_db = PerkSystem.get_all_perks() if PerkSystem.has_method("get_all_perks") else {}
			if perk_db.is_empty():
				_log("[color=gold]Perk IDs from resources/data/perks.json[/color]")
				_log("  Examples: blend_in, soft_step, shadow_strike, formation_discipline")
			else:
				_log("[color=gold]Perks (first 30):[/color]")
				var count = 0
				for skill_name in perk_db:
					for perk_id in perk_db[skill_name]:
						if count >= 30:
							break
						_log("  %s (%s)" % [perk_id, skill_name])
						count += 1

		"worlds":
			_log("[color=gold]Worlds:[/color]")
			for world_id in GameState.WORLDS:
				var info = GameState.WORLDS[world_id]
				_log("  %s — %s" % [world_id, info.get("name", world_id)])

		_:
			_log_err("Unknown list type. Use: companions, spells, items, perks, worlds")
