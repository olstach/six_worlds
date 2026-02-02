extends Control
## CombatArena - Main combat scene controller
##
## Manages the combat UI, input handling, and coordinates between
## CombatManager, CombatGrid, and CombatUnits.

# Node references
@onready var grid_container: Node2D = $GridContainer
@onready var combat_grid: CombatGrid = $GridContainer/CombatGrid
@onready var camera: Camera2D = $GridContainer/Camera2D
@onready var turn_order_list: VBoxContainer = %TurnOrderList
@onready var action_panel: PanelContainer = %ActionPanel
@onready var move_button: Button = %MoveButton
@onready var attack_button: Button = %AttackButton
@onready var wait_button: Button = %WaitButton
@onready var end_turn_button: Button = %EndTurnButton
@onready var combat_log: RichTextLabel = %CombatLog
@onready var unit_info_panel: PanelContainer = %UnitInfoPanel
@onready var unit_info_name: Label = %UnitInfoName
@onready var unit_info_hp: Label = %UnitInfoHP
@onready var unit_info_actions: Label = %UnitInfoActions
@onready var spell_button: Button = %SpellButton
@onready var spell_panel: PanelContainer = %SpellPanel
@onready var spell_list: VBoxContainer = %SpellList

# Combat state
enum ActionMode { NONE, MOVE, ATTACK, CAST_SPELL }
var current_action_mode: ActionMode = ActionMode.NONE
var selected_unit: CombatUnit = null
var selected_spell: Dictionary = {}

# AI turn timer
var ai_timer: Timer

# Test enemies for debugging
const TEST_ENEMY_DEF = {
	"name": "Demon",
	"max_hp": 40,
	"max_mana": 0,
	"actions": 2,
	"attributes": {
		"strength": 12,
		"finesse": 8,
		"constitution": 10,
		"focus": 6,
		"awareness": 8,
		"charm": 4,
		"luck": 8
	},
	"derived": {
		"initiative": 16,
		"movement": 3,
		"dodge": 8,
		"damage": 8,
		"armor": 2,
		"crit_chance": 5
	},
	"resistances": {
		"physical": 0,
		"fire": 25
	}
}

# Test ranged enemy
const TEST_RANGED_ENEMY_DEF = {
	"name": "Demon Archer",
	"max_hp": 25,
	"max_mana": 0,
	"actions": 2,
	"attributes": {
		"strength": 8,
		"finesse": 14,
		"constitution": 8,
		"focus": 6,
		"awareness": 12,
		"charm": 4,
		"luck": 10
	},
	"skills": {
		"ranged": 2
	},
	"derived": {
		"initiative": 26,
		"movement": 4,
		"dodge": 14,
		"damage": 6,
		"armor": 0,
		"accuracy": 10,
		"crit_chance": 8
	},
	"resistances": {
		"physical": 0,
		"fire": 25
	},
	# Enemy-specific equipped weapon (bypasses ItemSystem)
	"equipped_weapon": {
		"name": "Demon Bow",
		"type": "bow",
		"stats": {"damage": 6, "accuracy": 10, "range": 5}
	}
}

# Test mage enemy
const TEST_MAGE_ENEMY_DEF = {
	"name": "Demon Mage",
	"max_hp": 20,
	"max_mana": 50,
	"actions": 2,
	"attributes": {
		"strength": 6,
		"finesse": 8,
		"constitution": 6,
		"focus": 14,
		"awareness": 12,
		"charm": 6,
		"luck": 8
	},
	"skills": {
		"fire_magic": 2,
		"sorcery": 2,
		"black": 1
	},
	"derived": {
		"initiative": 20,
		"movement": 2,
		"dodge": 8,
		"damage": 3,
		"armor": 0,
		"spellpower": 14,
		"crit_chance": 5
	},
	"resistances": {
		"physical": 0,
		"fire": 50
	},
	# Spells this enemy knows
	"known_spells": ["firebolt", "immolate", "poison_dart"]
}

func _ready() -> void:
	# Create AI timer for delayed enemy turns
	ai_timer = Timer.new()
	ai_timer.one_shot = true
	ai_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(ai_timer)

	# Connect CombatManager signals
	CombatManager.combat_started.connect(_on_combat_started)
	CombatManager.combat_ended.connect(_on_combat_ended)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.turn_ended.connect(_on_turn_ended)
	CombatManager.unit_moved.connect(_on_unit_moved)
	CombatManager.unit_attacked.connect(_on_unit_attacked)
	CombatManager.unit_damaged.connect(_on_unit_damaged)
	CombatManager.unit_died.connect(_on_unit_died)
	CombatManager.unit_bleeding_out.connect(_on_unit_bleeding_out)
	CombatManager.action_used.connect(_on_action_used)

	# Connect grid signals
	combat_grid.tile_clicked.connect(_on_tile_clicked)
	combat_grid.tile_hovered.connect(_on_tile_hovered)

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	spell_button.pressed.connect(_on_spell_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect spell cast signal
	CombatManager.spell_cast.connect(_on_spell_cast)

	# Connect status effect signals
	CombatManager.status_effect_triggered.connect(_on_status_effect_triggered)
	CombatManager.status_effect_expired.connect(_on_status_effect_expired)

	# Hide spell panel initially
	spell_panel.hide()

	# Center camera on grid
	_center_camera()

	# Start test combat
	_start_test_combat()


## Center camera on the grid
func _center_camera() -> void:
	var grid_pixel_size = Vector2(
		combat_grid.grid_size.x * combat_grid.tile_size,
		combat_grid.grid_size.y * combat_grid.tile_size
	)
	camera.position = grid_pixel_size / 2


## Start a test combat for debugging
func _start_test_combat() -> void:
	_log_message("=== Combat Test ===")

	var player_units: Array = []
	var enemy_units: Array = []

	# Create player units from party
	var party = CharacterSystem.get_party()
	var player_start_positions = [Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3)]

	for i in range(mini(party.size(), player_start_positions.size())):
		var char_data = party[i]
		var unit = CombatUnit.new()
		unit.init_from_character(char_data, CombatManager.Team.PLAYER)
		combat_grid.place_unit(unit, player_start_positions[i])
		player_units.append(unit)
		_log_message("Player: %s placed at %s" % [unit.unit_name, player_start_positions[i]])

	# Create test enemies (mix of melee, ranged, and mage)
	var enemy_start_positions = [Vector2i(10, 2), Vector2i(10, 4), Vector2i(9, 3)]

	for i in range(3):
		var enemy_def: Dictionary
		var extra_info = ""
		if i == 0:
			# Melee demon
			enemy_def = TEST_ENEMY_DEF.duplicate(true)
			enemy_def.name = "Demon Warrior"
		elif i == 1:
			# Ranged archer
			enemy_def = TEST_RANGED_ENEMY_DEF.duplicate(true)
			extra_info = " (range: %d)" % enemy_def.equipped_weapon.stats.range
		else:
			# Mage with spells
			enemy_def = TEST_MAGE_ENEMY_DEF.duplicate(true)
			extra_info = " (mage)"

		var unit = CombatUnit.new()
		unit.init_as_enemy(enemy_def)
		combat_grid.place_unit(unit, enemy_start_positions[i])
		enemy_units.append(unit)
		_log_message("Enemy: %s placed at %s%s" % [unit.unit_name, enemy_start_positions[i], extra_info])

	# Start combat
	CombatManager.start_combat(combat_grid, player_units, enemy_units)


# ============================================
# INPUT HANDLING
# ============================================

func _on_tile_clicked(grid_pos: Vector2i) -> void:
	match current_action_mode:
		ActionMode.NONE:
			# Select unit at tile
			var unit = combat_grid.get_unit_at(grid_pos)
			if unit:
				_select_unit(unit)
			else:
				_deselect_unit()

		ActionMode.MOVE:
			# Try to move selected unit
			_try_move_to(grid_pos)

		ActionMode.ATTACK:
			# Try to attack unit at tile
			_try_attack_at(grid_pos)

		ActionMode.CAST_SPELL:
			# Try to cast selected spell at tile
			_try_cast_spell(grid_pos)


func _on_tile_hovered(grid_pos: Vector2i) -> void:
	# Show hover highlight
	combat_grid.highlight_tile(grid_pos)

	# Show AoE preview when targeting AoE spells
	if current_action_mode == ActionMode.CAST_SPELL and not selected_spell.is_empty():
		var targeting = selected_spell.get("targeting", "single")
		if targeting == "aoe_circle":
			var radius = selected_spell.get("aoe_radius", 1)
			combat_grid.show_aoe_preview(grid_pos, radius)
		else:
			combat_grid.clear_aoe_preview()
	else:
		combat_grid.clear_aoe_preview()

	# Update unit info if hovering over a unit
	var unit = combat_grid.get_unit_at(grid_pos)
	if unit:
		_show_unit_info(unit)


func _input(event: InputEvent) -> void:
	# Cancel current action mode with right click or escape
	if event.is_action_pressed("ui_cancel") or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		_cancel_action_mode()


## Select a unit
func _select_unit(unit: CombatUnit) -> void:
	if selected_unit:
		selected_unit.set_selected(false)

	selected_unit = unit
	unit.set_selected(true)
	_show_unit_info(unit)
	_log_message("Selected: " + unit.unit_name)


## Deselect current unit
func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
	selected_unit = null
	unit_info_panel.hide()


## Cancel current action mode
func _cancel_action_mode() -> void:
	current_action_mode = ActionMode.NONE
	selected_spell = {}
	combat_grid.clear_highlights()
	combat_grid.clear_aoe_preview()
	spell_panel.hide()
	_update_action_buttons()


# ============================================
# ACTIONS
# ============================================

func _on_move_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	var unit = CombatManager.get_current_unit()
	if unit == null or not CombatManager.can_act(1):
		return

	current_action_mode = ActionMode.MOVE
	var move_range = CombatManager.get_movement_range(unit)
	combat_grid.highlight_movement_range(move_range)
	_log_message("Select tile to move to...")


func _on_attack_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	var unit = CombatManager.get_current_unit()
	if unit == null or not CombatManager.can_act(1):
		return

	current_action_mode = ActionMode.ATTACK
	var attack_range = combat_grid.get_attack_range_tiles(unit.grid_position, 1, unit.get_attack_range())
	combat_grid.highlight_attack_range(attack_range)
	_log_message("Select target to attack...")


func _on_spell_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	# Toggle spell panel
	if spell_panel.visible:
		spell_panel.hide()
		_cancel_action_mode()
	else:
		_show_spell_panel(unit)


func _show_spell_panel(unit: CombatUnit) -> void:
	# Clear existing
	for child in spell_list.get_children():
		child.queue_free()

	# Get castable spells
	var spells = CombatManager.get_castable_spells(unit)

	if spells.is_empty():
		var label = Label.new()
		label.text = "No spells available"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		spell_list.add_child(label)
	else:
		for spell in spells:
			var btn = Button.new()
			btn.text = "%s (%d MP)" % [spell.name, spell.mana_cost]
			btn.tooltip_text = _build_spell_tooltip(spell)

			# Disable if not enough mana
			if unit.current_mana < spell.mana_cost:
				btn.disabled = true
				btn.text += " [Low Mana]"

			# Color by school
			var schools = spell.get("schools", [])
			if "fire" in schools:
				btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			elif "water" in schools:
				btn.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
			elif "earth" in schools:
				btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
			elif "air" in schools:
				btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			elif "space" in schools:
				btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
			elif "white" in schools:
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
			elif "black" in schools:
				btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.6))

			btn.pressed.connect(_on_spell_selected.bind(spell))
			spell_list.add_child(btn)

	spell_panel.show()


## Build detailed tooltip for a spell
func _build_spell_tooltip(spell: Dictionary) -> String:
	var lines: Array[String] = []

	# Name
	lines.append(spell.get("name", "Unknown Spell"))
	lines.append("")

	# Schools
	var schools = spell.get("schools", [])
	if not schools.is_empty():
		var school_names: Array[String] = []
		for s in schools:
			school_names.append(s.capitalize())
		lines.append("Schools: " + ", ".join(school_names))

	# Stats line
	var stats_parts: Array[String] = []
	stats_parts.append("Level %d" % spell.get("level", 1))
	stats_parts.append("%d MP" % spell.get("mana_cost", 0))
	stats_parts.append("Range %d" % spell.get("range", 1))
	lines.append(" | ".join(stats_parts))

	# Targeting
	var targeting = spell.get("targeting", "single")
	var target_text = ""
	match targeting:
		"self":
			target_text = "Self"
		"single":
			target_text = "Single Enemy"
		"single_ally":
			target_text = "Single Ally"
		"single_corpse":
			target_text = "Downed Ally"
		"aoe_circle":
			var radius = spell.get("aoe_radius", 1)
			var center = spell.get("aoe_center", "target")
			if center == "self":
				target_text = "AoE (Radius %d, centered on self)" % radius
			else:
				target_text = "AoE (Radius %d)" % radius
		"chain":
			var chain_count = spell.get("chain_targets", 3)
			target_text = "Chain (up to %d targets)" % chain_count

	lines.append("Target: " + target_text)
	lines.append("")

	# Effects
	var effects = spell.get("effects", [])
	for effect in effects:
		var effect_type = effect.get("type", "")
		match effect_type:
			"damage":
				var element = effect.get("element", "physical").capitalize()
				var base = effect.get("base_value", 0)
				lines.append("Deals %d %s damage" % [base, element])
			"heal":
				var base = effect.get("base_value", 0)
				lines.append("Heals %d HP" % base)
			"buff":
				var stat = effect.get("stat", "").capitalize()
				var value = effect.get("value", 0)
				var duration = effect.get("duration", 3)
				lines.append("+%d %s for %d turns" % [value, stat, duration])
			"debuff":
				var stat = effect.get("stat", "").capitalize()
				var value = effect.get("value", 0)
				var duration = effect.get("duration", 3)
				lines.append("%d %s for %d turns" % [value, stat, duration])
			"status":
				var status = effect.get("status", "").capitalize()
				var duration = effect.get("duration", 1)
				var chance = effect.get("chance", 100)
				if chance < 100:
					lines.append("%d%% chance: %s for %d turns" % [chance, status, duration])
				else:
					lines.append("Inflicts %s for %d turns" % [status, duration])
			"lifesteal":
				var percent = effect.get("percent", 50)
				lines.append("Restores %d%% of damage as HP" % percent)
			"revive":
				var hp_pct = effect.get("hp_percent", 1)
				lines.append("Revives with %d%% HP" % hp_pct)
			"teleport":
				var dist = effect.get("distance", 4)
				lines.append("Teleport up to %d tiles" % dist)
			"cleanse":
				var count = effect.get("count", 1)
				lines.append("Remove %d negative effect(s)" % count)

	# Description
	var desc = spell.get("description", "")
	if not desc.is_empty():
		lines.append("")
		lines.append(desc)

	return "\n".join(lines)


func _on_spell_selected(spell: Dictionary) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	selected_spell = spell
	spell_panel.hide()

	# Get valid targets
	var valid_targets = CombatManager.get_spell_targets(unit, spell.id)

	if valid_targets.is_empty():
		_log_message("No valid targets for " + spell.name)
		_cancel_action_mode()
		return

	# Self-targeting spells cast immediately
	if spell.get("targeting") == "self":
		_try_cast_spell(unit.grid_position)
		return

	current_action_mode = ActionMode.CAST_SPELL
	combat_grid.highlight_spell_range(valid_targets)

	# Log with range info
	var range_text = "Range: %d" % spell.get("range", 1)
	if spell.get("targeting") == "aoe_circle":
		range_text += ", AoE radius: %d" % spell.get("aoe_radius", 1)
	_log_message("Select target for %s (%s)..." % [spell.name, range_text])


func _try_cast_spell(target_pos: Vector2i) -> void:
	var caster = CombatManager.get_current_unit()
	if caster == null or selected_spell.is_empty():
		_cancel_action_mode()
		return

	var result = CombatManager.cast_spell(caster, selected_spell.id, target_pos)

	if result.success:
		# Logging is handled by _on_spell_cast signal
		pass
	else:
		_log_message("Failed to cast: " + result.get("reason", "Unknown"))

	selected_spell = {}
	_cancel_action_mode()


func _on_wait_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	# Use one action to wait (skip action but not whole turn)
	CombatManager.use_action(1)
	_log_message("Waiting...")


func _on_end_turn_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	CombatManager.end_turn()


## Try to move to a tile
func _try_move_to(grid_pos: Vector2i) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		_cancel_action_mode()
		return

	if CombatManager.move_unit(unit, grid_pos):
		_log_message("%s moved to %s" % [unit.unit_name, grid_pos])
	else:
		_log_message("Cannot move there!")

	_cancel_action_mode()


## Try to attack at a tile
func _try_attack_at(grid_pos: Vector2i) -> void:
	var attacker = CombatManager.get_current_unit()
	var defender = combat_grid.get_unit_at(grid_pos)

	if attacker == null:
		_cancel_action_mode()
		return

	if defender == null:
		_log_message("No target there!")
		_cancel_action_mode()
		return

	if defender.team == attacker.team:
		_log_message("Cannot attack allies!")
		_cancel_action_mode()
		return

	var result = CombatManager.attack_unit(attacker, defender)

	if result.success:
		if result.hit:
			var crit_text = " CRITICAL!" if result.crit else ""
			_log_message("%s attacks %s for %d damage!%s" % [
				attacker.unit_name, defender.unit_name, result.damage, crit_text
			])
		else:
			_log_message("%s attacks %s - MISS! (rolled %.0f vs %.0f%%)" % [
				attacker.unit_name, defender.unit_name, result.roll, result.hit_chance
			])
	else:
		_log_message("Attack failed: " + result.get("reason", "Unknown"))

	_cancel_action_mode()


# ============================================
# UI UPDATES
# ============================================

## Update action buttons based on current state
func _update_action_buttons() -> void:
	var is_player = CombatManager.is_player_turn()
	var can_act = CombatManager.can_act(1)

	move_button.disabled = not is_player or not can_act
	attack_button.disabled = not is_player or not can_act
	spell_button.disabled = not is_player or not can_act
	wait_button.disabled = not is_player or not can_act
	end_turn_button.disabled = not is_player

	# Highlight active mode
	move_button.button_pressed = (current_action_mode == ActionMode.MOVE)
	attack_button.button_pressed = (current_action_mode == ActionMode.ATTACK)
	spell_button.button_pressed = (current_action_mode == ActionMode.CAST_SPELL)


## Update turn order display
func _update_turn_order_display() -> void:
	# Clear existing
	for child in turn_order_list.get_children():
		child.queue_free()

	# Add current turn order
	for i in range(CombatManager.turn_order.size()):
		var unit = CombatManager.turn_order[i]
		var label = Label.new()
		label.text = unit.unit_name

		if i == CombatManager.current_unit_index:
			label.text = "> " + label.text
			label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		elif unit.team == CombatManager.Team.PLAYER:
			label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))

		if unit.is_bleeding_out:
			label.text += " [!%d]" % unit.bleed_out_turns

		label.add_theme_font_size_override("font_size", 12)
		turn_order_list.add_child(label)


## Show unit info panel
func _show_unit_info(unit: CombatUnit) -> void:
	unit_info_panel.show()
	unit_info_name.text = unit.unit_name
	unit_info_hp.text = "HP: %d / %d  MP: %d / %d" % [unit.current_hp, unit.max_hp, unit.current_mana, unit.max_mana]
	unit_info_actions.text = "Actions: %d / %d" % [unit.actions_remaining, unit.max_actions]


## Add message to combat log
func _log_message(msg: String) -> void:
	combat_log.append_text(msg + "\n")
	# Auto-scroll to bottom
	combat_log.scroll_to_line(combat_log.get_line_count())


# ============================================
# COMBAT MANAGER SIGNAL HANDLERS
# ============================================

func _on_combat_started() -> void:
	_log_message("Combat started!")
	_update_turn_order_display()
	_update_action_buttons()


func _on_combat_ended(victory: bool) -> void:
	if victory:
		_log_message("=== VICTORY! ===")
	else:
		_log_message("=== DEFEAT ===")
	_update_action_buttons()


func _on_turn_started(unit: Node) -> void:
	_log_message("--- %s's turn (%d actions) ---" % [unit.unit_name, unit.actions_remaining])
	_update_turn_order_display()
	_update_action_buttons()
	_select_unit(unit)

	# AI turn handling - use timer for delay between enemy turns
	if unit.team == CombatManager.Team.ENEMY:
		ai_timer.start(0.4)  # Delay before enemy acts


func _on_ai_timer_timeout() -> void:
	var unit = CombatManager.get_current_unit()
	if unit and unit.team == CombatManager.Team.ENEMY:
		_do_enemy_turn(unit)


func _on_turn_ended(unit: Node) -> void:
	_cancel_action_mode()


func _on_unit_moved(unit: Node, from: Vector2i, to: Vector2i) -> void:
	_update_action_buttons()


func _on_unit_attacked(attacker: Node, defender: Node, result: Dictionary) -> void:
	_update_action_buttons()


func _on_unit_damaged(unit: Node, damage: int, damage_type: String) -> void:
	_update_turn_order_display()
	if selected_unit == unit:
		_show_unit_info(unit)


func _on_unit_died(unit: Node) -> void:
	_log_message("%s has fallen!" % unit.unit_name)
	_update_turn_order_display()


func _on_unit_bleeding_out(unit: Node, turns_remaining: int) -> void:
	_log_message("%s is bleeding out! %d turns remaining!" % [unit.unit_name, turns_remaining])
	_update_turn_order_display()


func _on_action_used(unit: Node, actions_remaining: int) -> void:
	_update_action_buttons()
	if selected_unit == unit:
		_show_unit_info(unit)

	# Auto-end turn for player when out of actions
	if actions_remaining <= 0 and unit.team == CombatManager.Team.PLAYER:
		# Use call_deferred so any pending logs happen first
		CombatManager.end_turn.call_deferred()


func _on_spell_cast(caster: Node, spell: Dictionary, targets: Array, results: Array) -> void:
	var spell_name = spell.get("name", "Unknown Spell")

	if targets.is_empty():
		_log_message("%s casts %s!" % [caster.unit_name, spell_name])
	else:
		var target_names = []
		for target in targets:
			target_names.append(target.unit_name)

		_log_message("%s casts %s on %s!" % [caster.unit_name, spell_name, ", ".join(target_names)])

		# Log individual effects
		for result in results:
			var target = result.target
			for effect in result.effects_applied:
				match effect.type:
					"damage":
						_log_message("  %s takes %d %s damage!" % [target.unit_name, effect.amount, effect.element])
					"heal":
						_log_message("  %s healed for %d!" % [target.unit_name, effect.amount])
					"buff":
						_log_message("  %s gains %+d %s!" % [target.unit_name, effect.value, effect.stat])
					"debuff":
						_log_message("  %s suffers %d %s!" % [target.unit_name, effect.value, effect.stat])
					"status":
						if effect.applied:
							_log_message("  %s is now %s!" % [target.unit_name, effect.status])
							# Update target visuals to show status icon
							if target.has_method("_update_visuals"):
								target._update_visuals()
					"revive":
						_log_message("  %s is revived with %d HP!" % [target.unit_name, effect.hp])
					"lifesteal":
						_log_message("  %s drains %d life!" % [caster.unit_name, effect.amount])

	_update_action_buttons()
	if selected_unit:
		_show_unit_info(selected_unit)


func _on_status_effect_triggered(unit: Node, effect_name: String, value: int, effect_type: String) -> void:
	# Log status effect damage/healing
	match effect_type:
		"damage":
			_log_message("  %s takes %d damage from %s!" % [unit.unit_name, value, effect_name])
		"heal":
			_log_message("  %s regenerates %d HP!" % [unit.unit_name, value])

	# Update unit visuals to show status icons
	if unit.has_method("_update_visuals"):
		unit._update_visuals()

	_update_turn_order_display()
	if selected_unit == unit:
		_show_unit_info(unit)


func _on_status_effect_expired(unit: Node, effect_name: String) -> void:
	_log_message("  %s is no longer %s" % [unit.unit_name, effect_name])

	# Update unit visuals
	if unit.has_method("_update_visuals"):
		unit._update_visuals()


# ============================================
# ENEMY AI (Simple)
# ============================================

func _do_enemy_turn(unit: CombatUnit) -> void:
	# Safety check - make sure it's still this unit's turn
	if CombatManager.get_current_unit() != unit:
		return

	var player_units = CombatManager.get_team_units(CombatManager.Team.PLAYER)
	if player_units.is_empty():
		CombatManager.end_turn()
		return

	# Check if unit has castable spells
	var castable_spells = CombatManager.get_castable_spells(unit)
	var is_caster = not castable_spells.is_empty()

	# Find best target based on range
	var attack_range = unit.get_attack_range()
	var is_ranged = attack_range > 1
	var nearest: CombatUnit = _find_nearest_enemy(unit, player_units)

	if nearest == null:
		CombatManager.end_turn()
		return

	# Use all actions
	while CombatManager.can_act(1) and CombatManager.get_current_unit() == unit:
		var dist = _grid_distance(unit.grid_position, nearest.grid_position)

		# Refresh castable spells (mana may have changed)
		castable_spells = CombatManager.get_castable_spells(unit)

		# Casters prefer spells over physical attacks
		if is_caster and not castable_spells.is_empty():
			var spell_cast = _ai_try_cast_spell(unit, castable_spells, player_units, nearest)
			if spell_cast:
				# Check if target died, find new target
				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break
				continue

		# Fall back to physical attack
		if dist <= attack_range:
			# In range - attack!
			var result = CombatManager.attack_unit(unit, nearest)
			if result.success:
				if result.hit:
					var ranged_text = " from range" if dist > 1 else ""
					_log_message("%s attacks %s%s for %d damage!" % [unit.unit_name, nearest.unit_name, ranged_text, result.damage])
				else:
					_log_message("%s attacks %s - MISS!" % [unit.unit_name, nearest.unit_name])

				# Check if target died, find new target
				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break  # No more targets
		else:
			# Out of range - need to reposition
			var move_range = CombatManager.get_movement_range(unit)
			var best_tile: Vector2i = unit.grid_position
			var best_score: int = -999

			# Determine optimal range (casters/ranged stay back, melee gets close)
			var optimal_range = 1
			if is_caster:
				optimal_range = 4  # Casters prefer mid-range
			elif is_ranged:
				optimal_range = attack_range

			for tile in move_range:
				var tile_dist = _grid_distance(tile, nearest.grid_position)

				if is_caster or is_ranged:
					# Prefer staying at optimal range
					var score = 0
					if tile_dist <= optimal_range and tile_dist >= 2:
						score = 100  # Good casting/shooting position
						score += tile_dist  # Prefer staying back
					elif tile_dist <= optimal_range:
						score = 50  # Can act from here
					else:
						score = -tile_dist  # Get closer if out of range
					if score > best_score:
						best_score = score
						best_tile = tile
				else:
					# Melee units just want to get close
					if tile_dist < _grid_distance(best_tile, nearest.grid_position):
						best_tile = tile

			if best_tile != unit.grid_position:
				CombatManager.move_unit(unit, best_tile)
				if is_caster:
					_log_message("%s positions for casting" % unit.unit_name)
				elif is_ranged:
					_log_message("%s repositions" % unit.unit_name)
				else:
					_log_message("%s moves toward %s" % [unit.unit_name, nearest.unit_name])
			else:
				# Can't improve position, skip remaining actions
				break

	# End turn if we still have control
	if CombatManager.get_current_unit() == unit:
		CombatManager.end_turn()


## AI: Try to cast a spell, returns true if spell was cast
func _ai_try_cast_spell(unit: CombatUnit, spells: Array[Dictionary], enemies: Array[Node], primary_target: CombatUnit) -> bool:
	# Sort spells by damage potential (prefer higher damage spells)
	spells.sort_custom(func(a, b):
		var a_dmg = 0
		var b_dmg = 0
		for effect in a.get("effects", []):
			if effect.type == "damage":
				a_dmg += effect.base_value
		for effect in b.get("effects", []):
			if effect.type == "damage":
				b_dmg += effect.base_value
		return a_dmg > b_dmg
	)

	# Try each spell
	for spell in spells:
		var spell_id = spell.get("id", "")
		var spell_range = spell.get("range", 1)
		var targeting = spell.get("targeting", "single")

		# Find valid target position
		var target_pos: Vector2i = Vector2i(-1, -1)

		match targeting:
			"single":
				# Target nearest enemy in range
				for enemy in enemies:
					if not enemy.is_alive():
						continue
					var dist = _grid_distance(unit.grid_position, enemy.grid_position)
					if dist <= spell_range:
						target_pos = enemy.grid_position
						break

			"aoe_circle":
				# Target position with most enemies
				var aoe_radius = spell.get("aoe_radius", 1)
				var best_pos = Vector2i(-1, -1)
				var best_count = 0

				# Check each enemy position as potential center
				for enemy in enemies:
					if not enemy.is_alive():
						continue
					var dist = _grid_distance(unit.grid_position, enemy.grid_position)
					if dist > spell_range:
						continue

					# Count enemies in AoE
					var count = 0
					for other in enemies:
						if not other.is_alive():
							continue
						var aoe_dist = _grid_distance(enemy.grid_position, other.grid_position)
						if aoe_dist <= aoe_radius:
							count += 1

					if count > best_count:
						best_count = count
						best_pos = enemy.grid_position

				if best_count > 0:
					target_pos = best_pos

			"self":
				target_pos = unit.grid_position

		# If valid target found, cast the spell
		if target_pos != Vector2i(-1, -1):
			var result = CombatManager.cast_spell(unit, spell_id, target_pos)
			if result.success:
				return true

	return false


## Find nearest alive enemy unit
func _find_nearest_enemy(unit: CombatUnit, enemies: Array[Node]) -> CombatUnit:
	var nearest: CombatUnit = null
	var nearest_dist: int = 999

	for enemy in enemies:
		if not enemy.is_alive():
			continue
		var dist = _grid_distance(unit.grid_position, enemy.grid_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
