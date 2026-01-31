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

# Combat state
enum ActionMode { NONE, MOVE, ATTACK }
var current_action_mode: ActionMode = ActionMode.NONE
var selected_unit: CombatUnit = null

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

func _ready() -> void:
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
	wait_button.pressed.connect(_on_wait_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

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

	# Create test enemies
	var enemy_start_positions = [Vector2i(10, 2), Vector2i(10, 4), Vector2i(9, 3)]

	for i in range(3):
		var enemy_def = TEST_ENEMY_DEF.duplicate(true)
		enemy_def.name = "Demon " + str(i + 1)

		var unit = CombatUnit.new()
		unit.init_as_enemy(enemy_def)
		combat_grid.place_unit(unit, enemy_start_positions[i])
		enemy_units.append(unit)
		_log_message("Enemy: %s placed at %s" % [unit.unit_name, enemy_start_positions[i]])

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


func _on_tile_hovered(grid_pos: Vector2i) -> void:
	# Show hover highlight
	combat_grid.highlight_tile(grid_pos)

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
	combat_grid.clear_highlights()
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
	wait_button.disabled = not is_player or not can_act
	end_turn_button.disabled = not is_player

	# Highlight active mode
	move_button.button_pressed = (current_action_mode == ActionMode.MOVE)
	attack_button.button_pressed = (current_action_mode == ActionMode.ATTACK)


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
	unit_info_hp.text = "HP: %d / %d" % [unit.current_hp, unit.max_hp]
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

	# AI turn handling (simple for now)
	if unit.team == CombatManager.Team.ENEMY:
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


# ============================================
# ENEMY AI (Simple)
# ============================================

func _do_enemy_turn(unit: CombatUnit) -> void:
	# Simple AI: Move toward nearest player and attack if in range
	await get_tree().create_timer(0.5).timeout

	var player_units = CombatManager.get_team_units(CombatManager.Team.PLAYER)
	if player_units.is_empty():
		CombatManager.end_turn()
		return

	# Find nearest player
	var nearest: CombatUnit = null
	var nearest_dist: int = 999

	for player in player_units:
		if not player.is_alive():
			continue
		var dist = _grid_distance(unit.grid_position, player.grid_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = player

	if nearest == null:
		CombatManager.end_turn()
		return

	# If in attack range, attack
	while CombatManager.can_act(1):
		var dist = _grid_distance(unit.grid_position, nearest.grid_position)

		if dist <= unit.get_attack_range():
			var result = CombatManager.attack_unit(unit, nearest)
			if result.success:
				if result.hit:
					_log_message("%s attacks %s for %d damage!" % [unit.unit_name, nearest.unit_name, result.damage])
				else:
					_log_message("%s attacks %s - MISS!" % [unit.unit_name, nearest.unit_name])
			await get_tree().create_timer(0.3).timeout
		else:
			# Move toward player
			var move_range = CombatManager.get_movement_range(unit)
			var best_tile: Vector2i = unit.grid_position
			var best_dist: int = dist

			for tile in move_range:
				var tile_dist = _grid_distance(tile, nearest.grid_position)
				if tile_dist < best_dist:
					best_dist = tile_dist
					best_tile = tile

			if best_tile != unit.grid_position:
				CombatManager.move_unit(unit, best_tile)
				_log_message("%s moves toward %s" % [unit.unit_name, nearest.unit_name])
				await get_tree().create_timer(0.3).timeout
			else:
				break  # Can't get closer, end actions

	CombatManager.end_turn()


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))
