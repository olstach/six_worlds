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
@onready var unit_info_bars: VBoxContainer = %UnitInfoBars
@onready var unit_info_actions: HBoxContainer = %UnitInfoActions
@onready var spell_button: Button = %SpellButton
@onready var flee_button: Button = %FleeButton
@onready var spell_panel: PanelContainer = %SpellPanel
@onready var spell_list: VBoxContainer = %SpellList
@onready var item_button: Button = %ItemButton
@onready var swap_weapon_button: Button = %SwapWeaponButton
@onready var item_panel: PanelContainer = %ItemPanel
@onready var item_list: VBoxContainer = %ItemList
@onready var skills_button: Button = %SkillsButton
@onready var skills_panel: PanelContainer = %SkillsPanel
@onready var skills_list: VBoxContainer = %SkillsList

# Context menu and examine window (created in code)
var context_menu: PopupMenu = null
var examine_panel: PanelContainer = null
var examine_scroll: ScrollContainer = null
var examine_content: VBoxContainer = null
var _context_menu_unit: CombatUnit = null

# Combat state
enum ActionMode { NONE, MOVE, ATTACK, CAST_SPELL, USE_ITEM, USE_SKILL }
var current_action_mode: ActionMode = ActionMode.NONE
var selected_unit: CombatUnit = null
var selected_spell: Dictionary = {}
var selected_item: Dictionary = {}
var selected_skill: Dictionary = {}
var _last_hovered_tile: Vector2i = Vector2i(-1, -1)  # Track hover to avoid log spam

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
	"known_spells": ["firebolt", "fireball", "poison_sting"]
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
	combat_grid.tile_right_clicked.connect(_on_tile_right_clicked)
	combat_grid.tile_hovered.connect(_on_tile_hovered)

	# Create context menu and examine window
	_create_context_menu()
	_create_examine_panel()

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	spell_button.pressed.connect(_on_spell_pressed)
	item_button.pressed.connect(_on_item_pressed)
	swap_weapon_button.pressed.connect(_on_swap_weapon_pressed)
	skills_button.pressed.connect(_on_skills_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# Connect spell cast and item use signals
	CombatManager.spell_cast.connect(_on_spell_cast)
	CombatManager.item_used_in_combat.connect(_on_item_used_in_combat)

	# Hide item and skills panels initially
	item_panel.hide()
	skills_panel.hide()

	# Connect status effect signals
	CombatManager.status_effect_triggered.connect(_on_status_effect_triggered)
	CombatManager.status_effect_expired.connect(_on_status_effect_expired)

	# Connect terrain effect signals
	CombatManager.terrain_damage.connect(_on_terrain_damage)
	CombatManager.terrain_heal.connect(_on_terrain_heal)

	# Hide spell panel initially
	spell_panel.hide()

	# Center camera on grid
	_center_camera()

	# Check if we were launched from the overworld with mob data
	if not GameState.pending_combat_mob.is_empty():
		_start_overworld_combat(GameState.pending_combat_mob)
		GameState.pending_combat_mob = {}
	else:
		# Standalone testing fallback
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
	var player_start_positions = [Vector2i(1, 3), Vector2i(1, 5), Vector2i(2, 4)]

	for i in range(mini(party.size(), player_start_positions.size())):
		var char_data = party[i]
		var unit = CombatUnit.new()
		unit.init_from_character(char_data, CombatManager.Team.PLAYER)
		combat_grid.place_unit(unit, player_start_positions[i])
		player_units.append(unit)
		_log_message("Player: %s placed at %s" % [unit.unit_name, player_start_positions[i]])

	# Create test enemies (mix of melee, ranged, and mage)
	var enemy_start_positions = [Vector2i(14, 3), Vector2i(14, 5), Vector2i(13, 4)]

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


## Start combat from overworld mob encounter using EnemySystem
func _start_overworld_combat(mob_data: Dictionary) -> void:
	_log_message("=== %s attacks! ===" % mob_data.get("name", "Enemy"))

	# Generate combat terrain from overworld context (before placing units)
	var terrain_context = GameState.combat_terrain_context
	GameState.combat_terrain_context = {}
	if not terrain_context.is_empty():
		var map_data = _generate_combat_terrain(terrain_context)
		combat_grid.setup_from_map(map_data)

	# Get encounter info from mob data
	var mob_inner = mob_data.get("data", {})
	var enemy_group = mob_inner.get("enemy_group", "demon_patrol")
	# Region can be on the mob dict (from MapManager) or in its inner data
	var region = mob_data.get("region", mob_inner.get("region", ""))

	# Generate scaled enemies from EnemySystem
	var enemy_defs = EnemySystem.generate_encounter(enemy_group, region)

	# Create player units from party
	var player_units: Array = []
	var party = CharacterSystem.get_party()
	var player_start_positions = [Vector2i(1, 3), Vector2i(1, 5), Vector2i(2, 4), Vector2i(0, 4), Vector2i(2, 2), Vector2i(2, 6), Vector2i(3, 3), Vector2i(3, 5)]

	for i in range(mini(party.size(), player_start_positions.size())):
		var char_data = party[i]
		var unit = CombatUnit.new()
		unit.init_from_character(char_data, CombatManager.Team.PLAYER)
		combat_grid.place_unit(unit, player_start_positions[i])
		player_units.append(unit)
		_log_message("Player: %s placed at %s" % [unit.unit_name, player_start_positions[i]])

	# Place enemies based on their roles (frontline closer, ranged/caster in back)
	var enemy_units: Array = []
	var frontline_positions = [Vector2i(12, 3), Vector2i(12, 5), Vector2i(12, 4), Vector2i(12, 2), Vector2i(12, 6)]
	var backline_positions = [Vector2i(14, 3), Vector2i(14, 5), Vector2i(14, 4), Vector2i(15, 3), Vector2i(15, 5)]
	var front_idx = 0
	var back_idx = 0

	for enemy_def in enemy_defs:
		var unit = CombatUnit.new()
		unit.init_as_enemy(enemy_def)

		# Pick position based on archetype role
		var archetype_id = enemy_def.get("archetype_id", "")
		var arch = EnemySystem.archetypes.get(archetype_id, {})
		var roles = arch.get("roles", [])
		var is_backline = "ranged" in roles or "caster" in roles or "support" in roles

		var pos: Vector2i
		if is_backline and back_idx < backline_positions.size():
			pos = backline_positions[back_idx]
			back_idx += 1
		elif front_idx < frontline_positions.size():
			pos = frontline_positions[front_idx]
			front_idx += 1
		elif back_idx < backline_positions.size():
			pos = backline_positions[back_idx]
			back_idx += 1
		else:
			# Overflow: place in an available spot
			pos = Vector2i(13, enemy_units.size())

		combat_grid.place_unit(unit, pos)
		enemy_units.append(unit)

		var role_text = "/".join(roles) if not roles.is_empty() else "fighter"
		_log_message("Enemy: %s (%s) placed at %s" % [unit.unit_name, role_text, pos])

	# Start combat
	CombatManager.start_combat(combat_grid, player_units, enemy_units)


## Generate combat grid terrain based on overworld terrain context
## Translates overworld terrain types into combat tile types, effects, and heights
func _generate_combat_terrain(context: Dictionary) -> Dictionary:
	var dominant = int(context.get("dominant", 0))
	var counts = context.get("counts", {})
	var grid_w = combat_grid.grid_size.x  # 16
	var grid_h = combat_grid.grid_size.y  # 10

	var tile_overrides: Dictionary = {}  # "x,y" -> TileType
	var effects: Array[Dictionary] = []
	var heights: Array[Dictionary] = []
	var obstacles: Array[Dictionary] = []

	# Budget obstacles based on overworld terrain counts in the 5x5 sample
	var wall_budget = 0
	var water_budget = 0
	var difficult_budget = 0
	var tree_budget = 0
	var rock_budget = 0
	var pillar_budget = 0

	for terrain_type in counts:
		var count = int(counts[terrain_type])
		match int(terrain_type):
			4:  # MOUNTAINS -> walls + rocks for cover
				wall_budget += count
				rock_budget += count
			5:  # WATER -> water tiles
				water_budget += count
			2:  # FOREST -> difficult terrain + trees for cover
				difficult_budget += count
				tree_budget += count * 2  # Forests generate plenty of trees
			6:  # SWAMP -> difficult terrain + some trees
				difficult_budget += count
				tree_budget += count
			3:  # HILLS -> height variation + occasional rocks
				for i in range(mini(count, 4)):
					var hx = randi_range(4, grid_w - 5)
					var hy = randi_range(1, grid_h - 2)
					heights.append({"pos": Vector2i(hx, hy), "height": 1})
				rock_budget += count / 2
			9:  # LAVA -> fire pits
				for i in range(mini(count / 2, 3)):
					var lx = randi_range(4, grid_w - 5)
					var ly = randi_range(1, grid_h - 2)
					tile_overrides["%d,%d" % [lx, ly]] = CombatGrid.TileType.PIT
					effects.append({"pos": Vector2i(lx, ly),
						"effect": CombatGrid.TerrainEffect.FIRE, "value": 5})
			13:  # RUINS -> difficult terrain + pillars + some walls
				difficult_budget += count / 2
				wall_budget += count / 3
				pillar_budget += count

	# Track occupied positions to avoid overlap
	var occupied: Dictionary = {}

	# Place wall obstacles (from mountains/ruins)
	var walls_to_place = clampi(wall_budget / 4, 0, 6)
	for i in range(walls_to_place):
		var wx = randi_range(4, grid_w - 5)
		var wy = randi_range(1, grid_h - 2)
		var key = "%d,%d" % [wx, wy]
		tile_overrides[key] = CombatGrid.TileType.WALL
		occupied[key] = true

	# Place water tiles
	var water_to_place = clampi(water_budget / 3, 0, 4)
	for i in range(water_to_place):
		var wx = randi_range(4, grid_w - 5)
		var wy = randi_range(1, grid_h - 2)
		var key = "%d,%d" % [wx, wy]
		if not key in occupied:
			tile_overrides[key] = CombatGrid.TileType.WATER
			occupied[key] = true

	# Place difficult terrain (from forest/swamp)
	var diff_to_place = clampi(difficult_budget / 3, 0, 6)
	for i in range(diff_to_place):
		var dx = randi_range(4, grid_w - 5)
		var dy = randi_range(0, grid_h - 1)
		var key = "%d,%d" % [dx, dy]
		if not key in occupied:
			tile_overrides[key] = CombatGrid.TileType.DIFFICULT
			occupied[key] = true

	# Place tree obstacles (from forest/swamp)
	var trees_to_place = clampi(tree_budget / 4, 0, 5)
	for i in range(trees_to_place):
		var tx = randi_range(4, grid_w - 5)
		var ty = randi_range(1, grid_h - 2)
		var key = "%d,%d" % [tx, ty]
		if not key in occupied:
			obstacles.append({"pos": Vector2i(tx, ty), "obstacle": CombatGrid.ObstacleType.TREE})
			occupied[key] = true

	# Place rock obstacles (from mountains/hills)
	var rocks_to_place = clampi(rock_budget / 4, 0, 4)
	for i in range(rocks_to_place):
		var rx = randi_range(4, grid_w - 5)
		var ry = randi_range(1, grid_h - 2)
		var key = "%d,%d" % [rx, ry]
		if not key in occupied:
			obstacles.append({"pos": Vector2i(rx, ry), "obstacle": CombatGrid.ObstacleType.ROCK})
			occupied[key] = true

	# Place pillar obstacles (from ruins)
	var pillars_to_place = clampi(pillar_budget / 4, 0, 3)
	for i in range(pillars_to_place):
		var px = randi_range(4, grid_w - 5)
		var py = randi_range(1, grid_h - 2)
		var key = "%d,%d" % [px, py]
		if not key in occupied:
			obstacles.append({"pos": Vector2i(px, py), "obstacle": CombatGrid.ObstacleType.PILLAR})
			occupied[key] = true

	# Dominant terrain effects (snow/ice -> ice patches, etc.)
	match dominant:
		8, 11:  # SNOW, ICE
			for i in range(randi_range(2, 5)):
				var ix = randi_range(4, grid_w - 5)
				var iy = randi_range(0, grid_h - 1)
				var key = "%d,%d" % [ix, iy]
				if not key in tile_overrides:
					effects.append({"pos": Vector2i(ix, iy),
						"effect": CombatGrid.TerrainEffect.ICE, "value": 0})

	# Safety: never block deployment zones (columns 0-3 for player, last 4 for enemy)
	for key in tile_overrides.keys():
		var parts = key.split(",")
		var kx = int(parts[0])
		if kx < 4 or kx >= grid_w - 4:
			tile_overrides.erase(key)

	# Also clear effects and obstacles from deployment zones
	var safe_effects: Array[Dictionary] = []
	for eff in effects:
		var ex = eff.get("pos", Vector2i(-1, -1)).x
		if ex >= 4 and ex < grid_w - 4:
			safe_effects.append(eff)
	effects = safe_effects

	var safe_obstacles: Array[Dictionary] = []
	for obs in obstacles:
		var ox = obs.get("pos", Vector2i(-1, -1)).x
		if ox >= 4 and ox < grid_w - 4:
			safe_obstacles.append(obs)
	obstacles = safe_obstacles

	return {
		"size": Vector2i(grid_w, grid_h),
		"tiles": tile_overrides,
		"effects": effects,
		"heights": heights,
		"obstacles": obstacles
	}


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

		ActionMode.USE_ITEM:
			# Try to use selected item at tile (scrolls need targeting)
			_try_use_item(grid_pos)

		ActionMode.USE_SKILL:
			# Try to use active skill at tile
			_resolve_active_skill(grid_pos)


func _on_tile_hovered(grid_pos: Vector2i) -> void:
	# Show hover highlight
	combat_grid.highlight_tile(grid_pos)

	# Show AoE preview when targeting AoE spells or AoE scrolls
	if current_action_mode == ActionMode.CAST_SPELL and not selected_spell.is_empty():
		var targeting = selected_spell.get("targeting", "single")
		if targeting == "aoe_circle":
			var radius = selected_spell.get("aoe_radius", 1)
			combat_grid.show_aoe_preview(grid_pos, radius)
		else:
			combat_grid.clear_aoe_preview()
	elif current_action_mode == ActionMode.USE_ITEM and not selected_item.is_empty():
		var sel_type = selected_item.get("type", "")
		if sel_type == "scroll":
			var spell_id = selected_item.get("spell_id", "")
			var spell = CombatManager.get_spell(spell_id)
			if not spell.is_empty() and spell.get("targeting", "") == "aoe_circle":
				var radius = spell.get("aoe_radius", 1)
				combat_grid.show_aoe_preview(grid_pos, radius)
			else:
				combat_grid.clear_aoe_preview()
		elif sel_type == "bomb":
			var radius = selected_item.get("effect", {}).get("aoe_radius", 1)
			combat_grid.show_aoe_preview(grid_pos, radius)
		else:
			combat_grid.clear_aoe_preview()
	elif current_action_mode == ActionMode.USE_SKILL and not selected_skill.is_empty():
		var skill_cd = selected_skill.get("combat_data", {})
		var aoe_r = skill_cd.get("aoe_radius", 0)
		if aoe_r > 0:
			combat_grid.show_aoe_preview(grid_pos, aoe_r)
		else:
			combat_grid.clear_aoe_preview()
	else:
		combat_grid.clear_aoe_preview()

	# Show cover info when hovering movement destinations
	if current_action_mode == ActionMode.MOVE:
		_show_cover_tooltip(grid_pos)
	else:
		_hide_cover_tooltip()

	# Show obstacle/height info in log (only when tile changes to avoid spam)
	if grid_pos != _last_hovered_tile:
		_last_hovered_tile = grid_pos

		# Show obstacle info when hovering over an obstacle tile
		var obs_info = combat_grid.get_obstacle_at(grid_pos)
		if not obs_info.is_empty() and current_action_mode == ActionMode.NONE:
			_log_message("%s (HP: %d, Cover: +%d%% dodge)" % [
				obs_info.name, obs_info.hp, obs_info.cover_bonus])

		# Show height info when hovering elevated tiles
		var tile_height = combat_grid.get_tile_height(grid_pos)
		if tile_height > 0 and current_action_mode == ActionMode.NONE:
			_log_message("Height: %d (+%d%% accuracy, +%d range from above)" % [
				tile_height, tile_height * 5, tile_height])

	# Update unit info if hovering over a unit
	var unit = combat_grid.get_unit_at(grid_pos)
	if unit:
		_show_unit_info(unit)


func _input(event: InputEvent) -> void:
	# Cancel current action mode with escape
	if event.is_action_pressed("ui_cancel"):
		if examine_panel and examine_panel.visible:
			examine_panel.hide()
		else:
			_cancel_action_mode()
	# Right click: if not on a unit tile, cancel action mode
	# (right-click on unit tiles is handled by _on_tile_right_clicked)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# The grid's tile_right_clicked handles unit context menus
		# This catches right-clicks outside the grid
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
	selected_item = {}
	selected_skill = {}
	combat_grid.clear_highlights()
	combat_grid.clear_aoe_preview()
	_hide_cover_tooltip()
	spell_panel.hide()
	item_panel.hide()
	skills_panel.hide()
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

	AudioManager.play("ui_click")
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

	AudioManager.play("ui_click")
	current_action_mode = ActionMode.ATTACK
	var weapon_range = unit.get_attack_range()
	# Use Chebyshev/square distance so diagonals are included (melee can attack diagonally)
	var range_area = combat_grid.get_attack_range_tiles(unit.grid_position, 1, weapon_range)
	# Highlight enemies in range as bright targets, rest of range as dim area
	var valid_targets: Array[Vector2i] = []
	for other in CombatManager.all_units:
		if other.is_alive() and other.team != unit.team and other.grid_position in range_area:
			valid_targets.append(other.grid_position)
	combat_grid.highlight_spell_range_and_area(range_area, valid_targets)

	if weapon_range > 1:
		_log_message("Select target to attack (range: %d)..." % weapon_range)
	else:
		_log_message("Select target to attack...")


func _on_spell_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	AudioManager.play("ui_click")
	# Toggle spell panel
	if spell_panel.visible:
		spell_panel.hide()
		_cancel_action_mode()
	else:
		item_panel.hide()
		skills_panel.hide()
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

			# Color by school (lowercase for comparison, spells.json uses capitalized names)
			var schools_lower: Array[String] = []
			for s in spell.get("schools", []):
				schools_lower.append(s.to_lower())
			if "fire" in schools_lower:
				btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			elif "water" in schools_lower:
				btn.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
			elif "earth" in schools_lower:
				btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
			elif "air" in schools_lower:
				btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			elif "space" in schools_lower:
				btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
			elif "white" in schools_lower:
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
			elif "black" in schools_lower:
				btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.6))

			btn.pressed.connect(_on_spell_selected.bind(spell))
			spell_list.add_child(btn)

	# Hide item panel if open, show spell panel
	item_panel.hide()
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

	# Self-targeting spells cast immediately
	if spell.get("targeting") == "self":
		_try_cast_spell(unit.grid_position)
		return

	# Get the normalized spell data for range info
	var spell_data = CombatManager.get_spell(spell.id)
	var spell_range = spell_data.get("range", 1)

	# Get valid targets and full range area
	var valid_targets = CombatManager.get_spell_targets(unit, spell.id)
	var range_area = combat_grid.get_spell_range_tiles(unit.grid_position, 1, spell_range)

	# Always show range, even if no valid targets
	current_action_mode = ActionMode.CAST_SPELL
	combat_grid.highlight_spell_range_and_area(range_area, valid_targets)

	# Log with range info
	var range_text = "Range: %d" % spell_range
	if spell_data.get("targeting") == "aoe_circle":
		range_text += ", AoE radius: %d" % spell_data.get("aoe_radius", 1)

	if valid_targets.is_empty():
		_log_message("No valid targets in range for %s (%s)" % [spell.name, range_text])
	else:
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


# ============================================
# ITEM ACTIONS
# ============================================

func _on_item_pressed() -> void:
	if not CombatManager.is_player_turn():
		return
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	AudioManager.play("ui_click")
	# Toggle item panel
	if item_panel.visible:
		item_panel.hide()
		_cancel_action_mode()
	else:
		spell_panel.hide()
		skills_panel.hide()
		_show_item_panel(unit)


func _show_item_panel(_unit: CombatUnit) -> void:
	# Clear existing buttons
	for child in item_list.get_children():
		child.queue_free()

	# Get consumable items from party inventory
	var consumables = ItemSystem.get_consumables_in_inventory()

	if consumables.is_empty():
		var label = Label.new()
		label.text = "No items available"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_list.add_child(label)
	else:
		for item in consumables:
			var btn = Button.new()
			var qty = item.get("quantity", 1)
			btn.text = "%s x%d" % [item.get("name", "???"), qty]
			btn.tooltip_text = _build_item_tooltip(item)

			# Color by type
			var item_type = item.get("type", "")
			match item_type:
				"potion":
					btn.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
				"scroll":
					btn.add_theme_color_override("font_color", Color(0.85, 0.75, 0.3))
				"charm":
					btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
				"bomb":
					btn.add_theme_color_override("font_color", Color(0.9, 0.45, 0.3))
				"oil":
					btn.add_theme_color_override("font_color", Color(0.3, 0.8, 0.8))

			btn.pressed.connect(_on_item_selected.bind(item))
			item_list.add_child(btn)

	# Hide spell panel if open, show item panel
	spell_panel.hide()
	item_panel.show()


func _build_item_tooltip(item: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(item.get("name", "Unknown"))
	lines.append("")

	var item_type = item.get("type", "")
	if item_type == "potion":
		var effect = item.get("effect", {})
		var effect_type = effect.get("type", "")
		match effect_type:
			"heal":
				lines.append("Restores %d HP" % effect.get("value", 0))
			"restore_mana":
				lines.append("Restores %d Mana" % effect.get("value", 0))
			"buff":
				var status = effect.get("status", "")
				var resistance = effect.get("resistance", "")
				if resistance != "":
					lines.append("+%d %s resistance for %d turns" % [
						effect.get("value", 0), resistance.capitalize(), effect.get("duration", 3)
					])
				else:
					lines.append("+%d %s for %d turns" % [
						effect.get("value", 0), effect.get("stat", "").capitalize(),
						effect.get("duration", 3)
					])
			"cleanse":
				lines.append("Removes: %s" % ", ".join(effect.get("statuses_removed", [])))
		lines.append("")
		lines.append("Target: Self")
	elif item_type == "scroll":
		var spell_id = item.get("spell_id", "")
		var spell = CombatManager.get_spell(spell_id)
		if not spell.is_empty():
			lines.append("Casts: %s" % spell.get("name", "?"))
			lines.append("No mana cost, no skill required")
			if spell.get("targeting", "single") != "self":
				lines.append("Range: %d" % spell.get("range", 1))
			else:
				lines.append("Target: Self")

	elif item_type == "charm":
		var effect = item.get("effect", {})
		var school = effect.get("school", "").capitalize()
		var reduction = int(effect.get("mana_reduction", 0) * 100)
		lines.append("School: %s" % school)
		lines.append("-%d%% mana cost on next %s spell" % [reduction, school])
		var sp_bonus = effect.get("spellpower_bonus", 0.0)
		if sp_bonus > 0:
			lines.append("+%d%% spellpower" % int(sp_bonus * 100))
		lines.append("")
		lines.append("Target: Self (lasts until next matching spell)")

	elif item_type == "bomb":
		var effect = item.get("effect", {})
		var damage = effect.get("damage", 0)
		var dmg_type = effect.get("damage_type", "")
		var radius = effect.get("aoe_radius", 1)
		var bomb_range = effect.get("range", 4)
		if damage > 0:
			lines.append("%d %s damage" % [damage, dmg_type.capitalize()])
		lines.append("AoE radius: %d, Range: %d" % [radius, bomb_range])
		var statuses = effect.get("statuses", [])
		for s in statuses:
			var chance = s.get("chance", 100)
			var chance_text = "" if chance >= 100 else " (%d%% chance)" % chance
			lines.append("Applies %s for %d turns%s" % [s.get("name", ""), s.get("duration", 0), chance_text])
		if effect.get("hits_all", false):
			lines.append("(Hits allies too!)")
		lines.append("")
		lines.append("Target: Thrown at tile")

	elif item_type == "oil":
		var effect = item.get("effect", {})
		var bonus_dmg = effect.get("bonus_damage", 0)
		var bonus_type = effect.get("bonus_damage_type", "").capitalize()
		var attacks = effect.get("attacks", 3)
		lines.append("+%d %s damage per attack" % [bonus_dmg, bonus_type])
		lines.append("Lasts %d attacks" % attacks)
		var crit_bonus = effect.get("crit_bonus", 0)
		if crit_bonus > 0:
			lines.append("+%d%% crit chance" % crit_bonus)
		var status = effect.get("status", "")
		if status != "":
			lines.append("%d%% chance to apply %s (%d turns)" % [
				effect.get("status_chance", 0), status, effect.get("status_duration", 0)
			])
		lines.append("")
		lines.append("Target: Self (coats weapon)")

	var desc = item.get("description", "")
	if desc != "":
		lines.append("")
		lines.append(desc)

	lines.append("")
	lines.append("Uses 1 action. Consumed on use.")
	return "\n".join(lines)


func _on_item_selected(item: Dictionary) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	selected_item = item
	item_panel.hide()

	var item_type = item.get("type", "")

	match item_type:
		"potion", "charm", "oil":
			# Self-targeting -- use immediately
			_try_use_item(unit.grid_position)

		"scroll":
			# Check if scroll's spell is self-targeting
			var spell_id = item.get("spell_id", "")
			var spell = CombatManager.get_spell(spell_id)

			if spell.get("targeting", "single") == "self":
				_try_use_item(unit.grid_position)
			else:
				# Enter targeting mode
				var spell_range = spell.get("range", 1)
				var valid_targets = CombatManager.get_scroll_targets(unit, item.get("id", ""))
				var range_area = combat_grid.get_spell_range_tiles(unit.grid_position, 1, spell_range)

				current_action_mode = ActionMode.USE_ITEM
				combat_grid.highlight_spell_range_and_area(range_area, valid_targets)

				var range_text = "Range: %d" % spell_range
				if valid_targets.is_empty():
					_log_message("No valid targets for %s (%s)" % [item.get("name", "?"), range_text])
				else:
					_log_message("Select target for %s (%s)..." % [item.get("name", "?"), range_text])

		"bomb":
			# Enter targeting mode for thrown bomb
			var effect = item.get("effect", {})
			var bomb_range = effect.get("range", 4)
			var range_area = combat_grid.get_spell_range_tiles(unit.grid_position, 1, bomb_range)

			current_action_mode = ActionMode.USE_ITEM
			# Highlight all tiles in range (bombs can target any tile)
			combat_grid.highlight_spell_range_and_area(range_area, range_area)

			_log_message("Select target tile for %s (Range: %d, Radius: %d)..." % [
				item.get("name", "?"), bomb_range, effect.get("aoe_radius", 1)
			])


func _try_use_item(target_pos: Vector2i) -> void:
	var user = CombatManager.get_current_unit()
	if user == null or selected_item.is_empty():
		_cancel_action_mode()
		return

	var result = CombatManager.use_combat_item(user, selected_item.get("id", ""), target_pos)

	if not result.get("success", false):
		_log_message("Failed to use item: " + result.get("reason", "Unknown"))

	# Success logging handled by _on_item_used_in_combat signal
	selected_item = {}
	_cancel_action_mode()


func _on_item_used_in_combat(user: Node, item: Dictionary, result: Dictionary) -> void:
	var item_name = item.get("name", "Unknown Item")
	var item_type = item.get("type", "")

	# Show floating item name above user
	if user.has_method("show_action_name"):
		user.show_action_name(item_name)

	if item_type == "potion":
		_log_message("%s uses %s!" % [user.unit_name, item_name])
		for effect in result.get("effects_applied", []):
			var etype = effect.get("type", "")
			match etype:
				"heal":
					_log_message("  Restored %d HP!" % effect.get("amount", 0))
				"restore_mana":
					_log_message("  Restored %d Mana!" % effect.get("amount", 0))
				"buff":
					var resistance = effect.get("resistance", "")
					if resistance != "":
						_log_message("  Gained +%d %s resistance for %d turns!" % [
							effect.get("value", 0), resistance.capitalize(),
							effect.get("duration", 0)
						])
					else:
						_log_message("  Gained +%d %s for %d turns!" % [
							effect.get("value", 0),
							effect.get("stat", "").capitalize(),
							effect.get("duration", 0)
						])
				"cleanse":
					var count = effect.get("removed", 0)
					if count > 0:
						_log_message("  Cleansed %d effect(s)!" % count)
					else:
						_log_message("  No effects to cleanse.")

	elif item_type == "scroll":
		var spell = result.get("spell", {})
		var spell_name = spell.get("name", "Unknown Spell")
		_log_message("%s uses %s! (casts %s)" % [user.unit_name, item_name, spell_name])
		for res in result.get("results", []):
			var target = res.get("target")
			if target == null:
				continue
			for effect_applied in res.get("effects_applied", []):
				var etype = effect_applied.get("type", "")
				match etype:
					"damage":
						_log_message("  %s takes %d %s damage!" % [
							target.unit_name,
							effect_applied.get("amount", 0),
							effect_applied.get("element", "")
						])
					"heal":
						_log_message("  %s healed for %d!" % [
							target.unit_name, effect_applied.get("amount", 0)
						])

	elif item_type == "charm":
		var school = ""
		for effect in result.get("effects_applied", []):
			school = effect.get("school", "").capitalize()
		_log_message("%s readies a %s!" % [user.unit_name, item_name])
		_log_message("  Next %s spell will cost less mana." % school)

	elif item_type == "bomb":
		_log_message("%s throws %s!" % [user.unit_name, item_name])
		for res in result.get("results", []):
			var target = res.get("target")
			if target == null:
				continue
			for effect_applied in res.get("effects_applied", []):
				var etype = effect_applied.get("type", "")
				match etype:
					"damage":
						_log_message("  %s takes %d %s damage!" % [
							target.unit_name,
							effect_applied.get("amount", 0),
							effect_applied.get("element", "")
						])
					"status":
						_log_message("  %s is %s!" % [
							target.unit_name, effect_applied.get("status", "")
						])

	elif item_type == "oil":
		var oil_type = ""
		var attacks = 0
		for effect in result.get("effects_applied", []):
			oil_type = effect.get("bonus_damage_type", "").capitalize()
			attacks = effect.get("attacks", 0)
		_log_message("%s applies %s to weapon!" % [user.unit_name, item_name])
		_log_message("  +%s damage for %d attacks." % [oil_type, attacks])

	_update_action_buttons()
	if selected_unit:
		_show_unit_info(selected_unit)


# ============================================
# ACTIVE SKILLS
# ============================================

func _on_skills_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	AudioManager.play("ui_click")
	# Toggle skills panel
	if skills_panel.visible:
		skills_panel.hide()
		_cancel_action_mode()
	else:
		_show_skills_panel(unit)


func _show_skills_panel(unit: CombatUnit) -> void:
	# Clear existing
	for child in skills_list.get_children():
		child.queue_free()

	# Get active skills from character perks
	var active_skills = _get_active_skills(unit)

	if active_skills.is_empty():
		var label = Label.new()
		label.text = "No active skills"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		skills_list.add_child(label)
	else:
		for skill_data in active_skills:
			var btn = Button.new()
			var stamina_cost = skill_data.get("stamina_cost", 0)
			var has_combat_data = not skill_data.get("combat_data", {}).is_empty()
			var perk_id = skill_data.get("id", "")

			# Build button text with stamina cost
			if stamina_cost > 0:
				btn.text = "%s (%d ST)" % [skill_data.get("name", "???"), stamina_cost]
			else:
				btn.text = skill_data.get("name", "???")

			# Show cooldown
			if unit.is_skill_on_cooldown(perk_id):
				var cd = unit.skill_cooldowns.get(perk_id, 0)
				if cd >= 999:
					btn.text += " [Used]"
				else:
					btn.text += " [CD: %d]" % cd

			btn.tooltip_text = skill_data.get("description", "")

			var is_mantra = skill_data.get("is_mantra", false)
			var mantra_active = is_mantra and unit.active_mantras.has(perk_id)
			if mantra_active:
				btn.text += " [ACTIVE]"

			# Determine if usable
			var can_use = true
			if not has_combat_data and not is_mantra:
				# Non-mantra with no combat_data = not yet implemented
				can_use = false
			elif stamina_cost > 0 and unit.current_stamina < stamina_cost:
				can_use = false
			elif unit.is_skill_on_cooldown(perk_id):
				can_use = false
			elif not CombatManager.can_act(1):
				can_use = false
			elif not is_mantra and not CombatManager.unit_has_required_weapon(unit, skill_data.get("skill", "")):
				# Mantras are mental/spiritual — skip weapon check
				can_use = false
				btn.text += " [Wrong Weapon]"

			# Color based on type and usability
			if not can_use:
				btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
				btn.disabled = true
			elif mantra_active:
				btn.add_theme_color_override("font_color", Color(0.95, 0.6, 1.0))  # Bright purple = chanting
			elif is_mantra:
				btn.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))  # Dim purple = activatable
			else:
				btn.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))

			btn.pressed.connect(_on_active_skill_selected.bind(skill_data))
			skills_list.add_child(btn)

	# Hide other panels, show skills
	spell_panel.hide()
	item_panel.hide()
	skills_panel.show()


## Get active skills (perks with "Active" in description) for a combat unit
func _get_active_skills(unit: CombatUnit) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var character = unit.character_data
	var perks = PerkSystem.get_character_perks(character)

	for perk_entry in perks:
		var data = perk_entry.get("data", {})
		var desc = data.get("description", "")
		# Active perks start with "Active" in their description
		if desc.begins_with("Active"):
			var skill_info: Dictionary = {
				"id": perk_entry.get("id", ""),
				"name": data.get("name", perk_entry.get("id", "???")),
				"description": desc,
				"is_mantra": data.get("is_mantra", false),
				"stamina_cost": _parse_stamina_cost(desc),
				"skill": data.get("skill", ""),
				"combat_data": data.get("combat_data", {}),
			}
			result.append(skill_info)

	# Also include mantras that are active abilities
	for perk_entry in perks:
		var data = perk_entry.get("data", {})
		if data.get("is_mantra", false):
			var desc = data.get("description", "")
			# Avoid duplicating active mantras already added
			var already_added := false
			for r in result:
				if r.id == perk_entry.get("id", ""):
					already_added = true
					break
			if not already_added:
				# Mantras rarely have explicit combat_data — give them a mantra-type default
				# so the button logic knows they're activatable (not greyed as "unimplemented")
				var cd = data.get("combat_data", {})
				if cd.is_empty():
					cd = {"type": "mantra", "targeting": "self"}
				var skill_info: Dictionary = {
					"id": perk_entry.get("id", ""),
					"name": data.get("name", perk_entry.get("id", "???")),
					"description": desc,
					"is_mantra": true,
					"stamina_cost": _parse_stamina_cost(desc),
					"skill": data.get("skill", ""),
					"combat_data": cd,
				}
				result.append(skill_info)

	return result


## Parse stamina cost from perk description, e.g. "Active (3 Stamina)." -> 3
func _parse_stamina_cost(description: String) -> int:
	# Match pattern like "(X Stamina)" in the description
	var regex = RegEx.new()
	regex.compile("\\((\\d+)\\s*Stamina\\)")
	var match_result = regex.search(description)
	if match_result:
		return int(match_result.get_string(1))
	return 0


func _on_active_skill_selected(skill_data: Dictionary) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	var combat_data = skill_data.get("combat_data", {})

	# Mantra: toggle on/off (uses 1 action to start/stop chanting)
	if skill_data.get("is_mantra", false) or combat_data.get("type", "") == "mantra":
		skills_panel.hide()
		var perk_id = skill_data.get("id", "")
		var mantra_name = skill_data.get("name", "???")
		var now_active = unit.toggle_mantra(perk_id)
		if now_active:
			_log_message("%s begins chanting: %s" % [unit.unit_name, mantra_name])
			unit.show_action_name("Chant Mantra")
		else:
			_log_message("%s stops chanting %s" % [unit.unit_name, mantra_name])
			unit.show_action_name("End Mantra")
		CombatManager.use_action(1)
		return

	# If no combat_data, this skill isn't wired up yet
	if combat_data.is_empty():
		skills_panel.hide()
		_log_message("%s tries to use %s... [Skill not yet implemented]" % [
			unit.unit_name, skill_data.get("name", "???")])
		return

	# Check stamina
	var stamina_cost = combat_data.get("stamina_cost", 0)
	if stamina_cost > 0 and unit.current_stamina < stamina_cost:
		_log_message("Not enough stamina! (%d/%d)" % [unit.current_stamina, stamina_cost])
		return

	# Check cooldown
	var perk_id = skill_data.get("id", "")
	if unit.is_skill_on_cooldown(perk_id):
		_log_message("%s is on cooldown (%d turns)!" % [
			skill_data.get("name", "???"), unit.skill_cooldowns.get(perk_id, 0)])
		return

	# Check weapon requirement
	var perk_skill = skill_data.get("skill", "")
	if not CombatManager.unit_has_required_weapon(unit, perk_skill):
		var required = CombatManager.get_required_weapon_types(perk_skill)
		_log_message("Requires %s weapon equipped!" % "/".join(required))
		return

	selected_skill = skill_data
	skills_panel.hide()

	var targeting = CombatManager.get_skill_targeting(combat_data)

	# Self-targeting and stance skills resolve immediately
	if targeting == "self":
		_resolve_active_skill(unit.grid_position)
	else:
		# Enter targeting mode
		current_action_mode = ActionMode.USE_SKILL
		var valid_targets = CombatManager.get_active_skill_targets(unit, combat_data)
		if valid_targets.is_empty():
			_log_message("No valid targets for %s!" % skill_data.get("name", "???"))
			_cancel_action_mode()
			return
		# Show full range area (dim) plus valid targets (bright), same as spell targeting
		var skill_range = combat_data.get("range", 1)
		var range_area = combat_grid.get_spell_range_tiles(unit.grid_position, 0, skill_range)
		combat_grid.highlight_spell_range_and_area(range_area, valid_targets)
		_log_message("Select target for %s..." % skill_data.get("name", "???"))


## Resolve an active skill at a target position
func _resolve_active_skill(target_pos: Vector2i) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null or selected_skill.is_empty():
		_cancel_action_mode()
		return

	var skill_name = selected_skill.get("name", "???")

	# Play attack animation for offensive skills
	var combat_data = selected_skill.get("combat_data", {})
	var effect = combat_data.get("effect", "")
	if effect in ["attack_with_bonus", "dash_attack", "debuff_target", "aoe_attack"]:
		var target_unit = CombatManager.get_unit_at(target_pos)
		if target_unit:
			unit.play_attack_animation(target_unit.global_position)

	# Show action name
	unit.show_action_name(skill_name)

	var result = CombatManager.use_active_skill(unit, selected_skill, target_pos)

	if result.get("success", false):
		var stamina_cost = combat_data.get("stamina_cost", 0)
		var stamina_text = " (%d ST)" % stamina_cost if stamina_cost > 0 else ""
		_log_message("%s uses %s%s!" % [unit.unit_name, skill_name, stamina_text])

		# Log specific effects
		match effect:
			"attack_with_bonus", "dash_attack":
				if result.get("hit", false):
					var damage = result.get("damage", 0)
					var target = result.get("target", null)
					var target_name = target.unit_name if target else "???"
					var crit_text = " CRITICAL!" if result.get("crit", false) else ""
					_log_message("  Hit %s for %d damage!%s" % [target_name, damage, crit_text])
					# Log sub-effects
					for fx in result.get("effects", []):
						if fx.type == "self_buff":
							_log_message("  Gained +%d%% %s for %d turn(s)" % [fx.value, fx.stat, fx.duration])
						elif fx.type == "target_debuff":
							_log_message("  %s: -%d%% %s for %d turn(s)" % [target_name, fx.value, fx.stat, fx.duration])
						elif fx.type == "refund":
							_log_message("  Refunded %d stamina!" % fx.amount)
				elif result.has("hit"):
					_log_message("  Missed! (%.0f vs %.0f%%)" % [result.get("roll", 0), result.get("hit_chance", 0)])
					var target = result.get("target", null)
					if target:
						_show_miss_text(unit, target)

			"buff_self", "stance", "heal_self":
				for fx in result.get("effects", []):
					if fx.type == "buff":
						_log_message("  +%d%% %s for %d turn(s)" % [fx.value, fx.stat, fx.duration])
					elif fx.type == "status":
						_log_message("  Status: %s for %d turn(s)" % [fx.status, fx.duration])
					elif fx.type == "heal":
						_log_message("  Healed for %d HP!" % fx.amount)
					elif fx.type == "stamina_restore":
						_log_message("  Restored %d stamina!" % fx.amount)
				if result.get("ends_turn", false):
					_log_message("  [Stance active until next turn]")

			"debuff_target":
				var target = result.get("target", null)
				var target_name = target.unit_name if target else "???"
				if result.get("hit", true):
					if result.get("damage", 0) > 0:
						_log_message("  Hit %s for %d damage!" % [target_name, result.damage])
					for fx in result.get("effects", []):
						if fx.type == "debuff":
							_log_message("  %s: -%d%% %s for %d turn(s)" % [target_name, fx.value, fx.stat, fx.duration])
						elif fx.type == "status":
							_log_message("  %s: %s for %d turn(s)" % [target_name, fx.status, fx.duration])
				else:
					_log_message("  Missed!")

			"aoe_attack":
				var count = result.get("hit_count", 0)
				_log_message("  Hit %d enemies!" % count)
				for fx in result.get("effects", []):
					if fx.type == "aoe_damage":
						var t = fx.get("target", null)
						_log_message("    %s: %d damage" % [t.unit_name if t else "???", fx.damage])

			"teleport":
				var dest = result.get("teleported_to", Vector2i.ZERO)
				_log_message("  Teleported to %s" % str(dest))
				for fx in result.get("effects", []):
					if fx.type == "buff":
						_log_message("  +%d%% %s for %d turn(s)" % [fx.value, fx.stat, fx.duration])

			"examine":
				var examined = result.get("examine_target", null)
				if examined:
					_log_message("  Examining %s..." % examined.unit_name)
					_show_examine_window(examined)

		# Update UI
		_show_unit_info(unit)
	else:
		_log_message("  Failed: %s" % result.get("reason", "Unknown"))

	_cancel_action_mode()


func _on_wait_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	AudioManager.play("ui_click")
	# Use one action to wait (skip action but not whole turn)
	CombatManager.use_action(1)
	_log_message("Waiting...")


func _on_swap_weapon_pressed() -> void:
	if not CombatManager.is_player_turn() or not CombatManager.can_act(1):
		return
	var unit = CombatManager.get_current_unit()
	if not unit or not "character_data" in unit:
		return
	AudioManager.play("ui_click")
	ItemSystem.swap_weapon_set(unit.character_data)
	CombatManager.use_action(1)
	_add_combat_log("[color=#aaaaff]%s switches weapon sets.[/color]" % unit.unit_name)
	_update_action_buttons()
	_update_unit_info(unit)


func _on_end_turn_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	AudioManager.play("ui_click")
	CombatManager.end_turn()


## Attempt to flee combat
## Roll: d20 + party avg finesse vs 10 + enemy avg finesse
## Success: return to overworld (mob stays on map)
## Failure: costs 1 action
func _on_flee_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	if not CombatManager.can_act(1):
		return

	AudioManager.play("ui_click")
	# Calculate party average finesse
	var player_units = CombatManager.get_team_units(CombatManager.Team.PLAYER)
	var enemy_units = CombatManager.get_team_units(CombatManager.Team.ENEMY)

	var party_finesse_sum := 0.0
	var party_count := 0
	for unit in player_units:
		if unit.is_alive():
			var attrs = unit.character_data.get("attributes", {})
			party_finesse_sum += attrs.get("finesse", 10)
			party_count += 1

	var enemy_finesse_sum := 0.0
	var enemy_count := 0
	for unit in enemy_units:
		if unit.is_alive():
			var attrs = unit.character_data.get("attributes", {})
			enemy_finesse_sum += attrs.get("finesse", 10)
			enemy_count += 1

	var party_avg = party_finesse_sum / maxf(party_count, 1)
	var enemy_avg = enemy_finesse_sum / maxf(enemy_count, 1)

	# Roll: d20 + party avg finesse modifier vs DC 10 + enemy avg finesse modifier
	# Modifier = (attribute - 10) like standard d20 systems
	var party_mod = (party_avg - 10.0) / 2.0
	var enemy_mod = (enemy_avg - 10.0) / 2.0
	var roll = randi_range(1, 20)
	var total = roll + party_mod
	var dc = 12.0 + enemy_mod  # Base DC 12 = "moderately difficult"

	_log_message("Attempting to flee... (rolled %d + %.0f = %.0f vs DC %.0f)" % [roll, party_mod, total, dc])

	# Use 1 action for the attempt
	CombatManager.use_action(1)

	if total >= dc:
		# Success - flee combat
		_log_message("The party escapes!")
		# End combat as defeat (mob stays on map, same as losing)
		CombatManager.end_combat(false)
	else:
		_log_message("Failed to flee! The enemies block your escape.")


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

	# Play attack lunge animation
	attacker.play_attack_animation(defender.global_position)

	var result = CombatManager.attack_unit(attacker, defender)

	if result.success:
		# Log cover info if applicable
		var cover_data = result.get("cover", {})
		if cover_data.get("has_cover", false):
			_log_message("  %s has cover from %s (-%d%% hit)" % [
				defender.unit_name, cover_data.obstacle_name, cover_data.dodge_bonus])

		if result.hit:
			var crit_text = " CRITICAL!" if result.crit else ""
			_log_message("%s attacks %s for %d damage!%s" % [
				attacker.unit_name, defender.unit_name, result.damage, crit_text
			])
			AudioManager.play(_get_attack_sound(attacker))
			if result.crit:
				AudioManager.play("hit_crit", -3.0)
			# Log weapon oil bonus damage
			if result.has("oil_damage"):
				_log_message("  +%d %s damage (oil)!" % [
					result.oil_damage, result.get("oil_damage_type", "").capitalize()
				])
			if result.has("oil_status"):
				_log_message("  %s is %s! (oil)" % [defender.unit_name, result.oil_status])
		else:
			# Show miss/dodge/block floating text on defender
			_show_miss_text(attacker, defender)
			AudioManager.play("hit_miss", -3.0)
			var cover_text = ""
			if cover_data.get("has_cover", false):
				cover_text = " [behind %s]" % cover_data.obstacle_name
			_log_message("%s attacks %s - MISS!%s (rolled %.0f vs %.0f%%)" % [
				attacker.unit_name, defender.unit_name, cover_text, result.roll, result.hit_chance
			])
	else:
		var reason = result.get("reason", "Unknown")
		if reason == "No line of sight":
			_log_message("Attack failed: No line of sight!")
		else:
			_log_message("Attack failed: " + reason)

	_cancel_action_mode()


# ============================================
# UI UPDATES
# ============================================

## Update action buttons based on current state
func _update_action_buttons() -> void:
	var is_player = CombatManager.is_player_turn()
	var can_act = CombatManager.can_act(1)

	# CC'd player units can't use buttons (AI controls them)
	var cc_behavior = ""
	var current_unit = CombatManager.get_current_unit()
	if current_unit:
		cc_behavior = CombatManager.get_cc_behavior(current_unit)

	# Fully CC'd units (feared, confused, berserk, pacified) lose all control
	var cc_locked = cc_behavior != "" and cc_behavior != "charmed"
	# Charmed units can act but can't attack the caster (enforced at attack time)
	# Pacified is handled by cc_locked — they skip combat actions automatically

	move_button.disabled = not is_player or not can_act or cc_locked
	attack_button.disabled = not is_player or not can_act or cc_locked or not CombatManager.can_unit_attack(current_unit) if current_unit else true
	spell_button.disabled = not is_player or not can_act or cc_locked or not CombatManager.can_unit_cast(current_unit) if current_unit else true
	item_button.disabled = not is_player or not can_act or cc_locked
	# Swap Weapons: only useful if the character has a weapon in the other set
	var has_alt_weapon = false
	if current_unit and "character_data" in current_unit:
		var cdata = current_unit.character_data
		var other_set = 2 if cdata.get("active_weapon_set", 1) == 1 else 1
		var alt_weapon = cdata.get("equipment", {}).get("weapon_set_%d" % other_set, {}).get("main", "")
		has_alt_weapon = alt_weapon != ""
	swap_weapon_button.disabled = not is_player or not can_act or cc_locked or not has_alt_weapon
	skills_button.disabled = not is_player or not can_act or cc_locked
	wait_button.disabled = not is_player or not can_act or cc_locked
	flee_button.disabled = not is_player or not can_act or cc_locked
	end_turn_button.disabled = not is_player or cc_locked

	# Highlight active mode
	move_button.button_pressed = (current_action_mode == ActionMode.MOVE)
	attack_button.button_pressed = (current_action_mode == ActionMode.ATTACK)
	spell_button.button_pressed = (current_action_mode == ActionMode.CAST_SPELL)
	item_button.button_pressed = (current_action_mode == ActionMode.USE_ITEM)
	skills_button.button_pressed = (current_action_mode == ActionMode.USE_SKILL)


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


## Show unit info panel with colored bars for HP, mana, stamina
func _show_unit_info(unit: CombatUnit) -> void:
	unit_info_panel.show()
	unit_info_name.text = unit.unit_name

	# Clear old bars
	for child in unit_info_bars.get_children():
		child.queue_free()

	# HP bar (red)
	unit_info_bars.add_child(_create_stat_bar("HP", unit.current_hp, unit.max_hp, Color(0.8, 0.2, 0.2)))

	# Mana bar (blue) - only show if unit has mana
	if unit.max_mana > 0:
		unit_info_bars.add_child(_create_stat_bar("MP", unit.current_mana, unit.max_mana, Color(0.3, 0.4, 0.9)))

	# Stamina bar (gold) - pull from character derived stats if available
	var derived = unit.character_data.get("derived", {})
	var max_stamina = derived.get("max_stamina", 0)
	if max_stamina > 0:
		var current_stamina = derived.get("current_stamina", max_stamina)
		unit_info_bars.add_child(_create_stat_bar("ST", current_stamina, max_stamina, Color(0.9, 0.75, 0.2)))

	# Status effects section — show each active status with name, duration, and color
	if not unit.status_effects.is_empty():
		# Separator
		var sep = HSeparator.new()
		sep.custom_minimum_size.y = 4
		unit_info_bars.add_child(sep)

		for effect in unit.status_effects:
			var status_name = effect.get("status", "")
			var duration = effect.get("duration", 0)
			var def = CombatManager.get_status_definition(status_name)
			var display_name = status_name.replace("_", " ")
			var stype = def.get("type", "debuff")

			var status_row = HBoxContainer.new()
			status_row.add_theme_constant_override("separation", 4)

			# Status name label (colored by buff/debuff)
			var name_lbl = Label.new()
			name_lbl.text = display_name
			name_lbl.add_theme_font_size_override("font_size", 10)
			if stype == "buff":
				name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
			else:
				name_lbl.add_theme_color_override("font_color", Color(0.95, 0.5, 0.3))
			status_row.add_child(name_lbl)

			# Duration label
			var dur_lbl = Label.new()
			var dur_type = def.get("duration_type", "turns")
			if dur_type == "permanent":
				dur_lbl.text = "(permanent)"
			elif dur_type == "until_save":
				dur_lbl.text = "(save to end)"
			else:
				dur_lbl.text = "(%d turns)" % duration
			dur_lbl.add_theme_font_size_override("font_size", 9)
			dur_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			status_row.add_child(dur_lbl)

			unit_info_bars.add_child(status_row)

	# Action circles: green = available, grey = used
	_update_action_circles(unit.actions_remaining, unit.max_actions)


## Create a labeled stat bar (HP/MP/ST) for the unit info panel
func _create_stat_bar(label_text: String, current: int, maximum: int, color: Color) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	# Label (HP/MP/ST)
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.custom_minimum_size.x = 22
	container.add_child(label)

	# Bar background
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.15, 0.15, 0.15)
	bar_bg.custom_minimum_size = Vector2(100, 14)
	container.add_child(bar_bg)

	# Bar fill
	var bar_fill = ColorRect.new()
	bar_fill.color = color
	var fill_ratio = float(current) / float(maximum) if maximum > 0 else 0.0
	bar_fill.custom_minimum_size = Vector2(100 * fill_ratio, 14)
	bar_fill.position = Vector2.ZERO
	bar_bg.add_child(bar_fill)

	# Value text
	var value_label = Label.new()
	value_label.text = "%d/%d" % [current, maximum]
	value_label.add_theme_font_size_override("font_size", 10)
	container.add_child(value_label)

	return container


## Update action circle indicators (green = available, grey = used)
func _update_action_circles(remaining: int, total: int) -> void:
	# Clear old circles
	for child in unit_info_actions.get_children():
		child.queue_free()

	# "Actions" label
	var label = Label.new()
	label.text = "Actions:"
	label.add_theme_font_size_override("font_size", 11)
	unit_info_actions.add_child(label)

	# Create circles for each action slot using Unicode filled circle
	for i in range(total):
		var dot = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 18)
		if i < remaining:
			dot.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))  # Green
		else:
			dot.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))  # Grey
		unit_info_actions.add_child(dot)


# ============================================
# COVER TOOLTIP
# ============================================

## Floating label shown when hovering over movement tiles near cover
var _cover_tooltip: Label = null

## Show cover tooltip at a tile position when in movement mode
func _show_cover_tooltip(grid_pos: Vector2i) -> void:
	_hide_cover_tooltip()

	# Only show for valid movement destinations
	if not grid_pos in combat_grid.highlighted_tiles:
		return

	var current_unit = CombatManager.get_current_unit()
	if current_unit == null:
		return

	# Check what cover this position would provide
	var cover_info = combat_grid.get_cover_info_at(grid_pos, current_unit.team)
	if not cover_info.has_cover:
		return

	# Also check height advantage at this position
	var height = combat_grid.get_tile_height(grid_pos)

	# Build tooltip text
	var tooltip_text = "+%d%% dodge (cover: %s)" % [cover_info.dodge_bonus, cover_info.obstacle_name]
	if height > 0:
		tooltip_text += "\nHeight %d (+%d%% accuracy)" % [height, height * 5]

	# Create floating label above the tile
	_cover_tooltip = Label.new()
	_cover_tooltip.text = tooltip_text
	_cover_tooltip.add_theme_font_size_override("font_size", 11)
	_cover_tooltip.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	_cover_tooltip.position = combat_grid.grid_to_world(grid_pos) + Vector2(0, -20)
	_cover_tooltip.z_index = 100
	combat_grid.add_child(_cover_tooltip)


## Hide the cover tooltip
func _hide_cover_tooltip() -> void:
	if _cover_tooltip != null:
		_cover_tooltip.queue_free()
		_cover_tooltip = null


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
	_update_action_buttons()

	if victory:
		_log_message("=== VICTORY! ===")
		# Apply and show rewards
		var rewards = CombatManager.last_combat_rewards
		if not rewards.is_empty():
			_apply_rewards(rewards)
			_show_victory_screen(rewards)
			return  # Victory screen handles scene transition
		# Fallback if no rewards calculated (shouldn't happen)
		GameState.returning_from_combat = true
		SaveManager.autosave()
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")
	else:
		# On defeat, clear the mob id so it stays on the map
		GameState.last_defeated_mob_id = ""

		# Check if this is a party wipe (all dead) vs a flee
		var any_alive := false
		for unit in CombatManager.all_units:
			if unit.team == CombatManager.Team.PLAYER and unit.is_alive():
				any_alive = true
				break

		if not any_alive:
			# Party wipe — show defeat screen, then go to Bardo
			_log_message("=== ALL HAVE FALLEN ===")
			_show_defeat_screen()
		else:
			# Fled — return to overworld
			_log_message("=== RETREAT ===")
			GameState.returning_from_combat = true
			SaveManager.autosave()
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")


func _on_turn_started(unit: Node) -> void:
	_log_message("--- %s's turn (%d actions) ---" % [unit.unit_name, unit.actions_remaining])
	# Log any active mantra pulses at the start of each turn
	for mantra_id in unit.active_mantras:
		var turns = unit.active_mantras[mantra_id]
		_log_message("  ✦ %s pulses (turn %d)" % [mantra_id.replace("_", " ").capitalize(), turns])
	_update_turn_order_display()
	_update_action_buttons()
	_select_unit(unit)

	# Check for CC behavior override — affects both player and enemy units
	var cc_behavior = CombatManager.get_cc_behavior(unit)
	if cc_behavior != "" and cc_behavior != "charmed":
		# CC'd units (except Charmed) are fully AI-controlled
		# Charmed units can still act freely, just can't attack the caster
		_log_message("%s is %s!" % [unit.unit_name, cc_behavior.capitalize()])
		ai_timer.start(0.4)
		return

	# AI turn handling - use timer for delay between enemy turns
	if unit.team == CombatManager.Team.ENEMY:
		ai_timer.start(0.4)  # Delay before enemy acts


func _on_ai_timer_timeout() -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return

	# CC behavior overrides take priority over normal AI
	var cc_behavior = CombatManager.get_cc_behavior(unit)
	if cc_behavior != "" and cc_behavior != "charmed":
		_do_cc_turn(unit, cc_behavior)
		return

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

	# Auto-end turn for player when out of actions
	if actions_remaining <= 0 and unit.team == CombatManager.Team.PLAYER:
		# Use call_deferred so any pending logs happen first
		CombatManager.end_turn.call_deferred()


func _on_spell_cast(caster: Node, spell: Dictionary, targets: Array, results: Array) -> void:
	var spell_name = spell.get("name", "Unknown Spell")

	# Show floating spell name above caster
	if caster.has_method("show_action_name"):
		caster.show_action_name(spell_name)

	# Cast sound: fire spells get a richer cast sound, everything else uses generic
	var schools: Array = spell.get("schools", [])
	if "Fire" in schools:
		AudioManager.play("spell_cast_fire", -4.0)
	else:
		AudioManager.play("spell_cast", -4.0)

	if targets.is_empty():
		_log_message("%s casts %s!" % [caster.unit_name, spell_name])
	else:
		var target_names = []
		for target in targets:
			target_names.append(target.unit_name)

		_log_message("%s casts %s on %s!" % [caster.unit_name, spell_name, ", ".join(target_names)])

		# Log individual effects and play impact sounds
		for result in results:
			var target = result.target
			for effect in result.effects_applied:
				match effect.type:
					"damage":
						_log_message("  %s takes %d %s damage!" % [target.unit_name, effect.amount, effect.element])
						AudioManager.play(_get_spell_impact_sound(effect.element), -2.0)
					"heal":
						_log_message("  %s healed for %d!" % [target.unit_name, effect.amount])
						AudioManager.play("heal", -3.0)
					"buff":
						_log_message("  %s gains %+d %s!" % [target.unit_name, effect.value, effect.stat])
						AudioManager.play("buff_apply", -4.0)
					"debuff":
						_log_message("  %s suffers %d %s!" % [target.unit_name, effect.value, effect.stat])
						AudioManager.play("debuff_apply", -4.0)
					"status":
						if effect.applied:
							_log_message("  %s is now %s!" % [target.unit_name, effect.status])
							AudioManager.play("debuff_apply", -4.0)
							# Update target visuals to show status icon
							if target.has_method("_update_visuals"):
								target._update_visuals()
					"revive":
						_log_message("  %s is revived with %d HP!" % [target.unit_name, effect.hp])
						AudioManager.play("heal")
					"lifesteal":
						_log_message("  %s drains %d life!" % [caster.unit_name, effect.amount])

	_update_action_buttons()
	if selected_unit:
		_show_unit_info(selected_unit)


func _on_status_effect_triggered(unit: Node, effect_name: String, value: int, effect_type: String) -> void:
	# Log status effect damage/healing/reactive
	match effect_type:
		"damage":
			_log_message("  %s takes %d damage from %s!" % [unit.unit_name, value, effect_name])
		"heal":
			_log_message("  %s regenerates %d HP!" % [unit.unit_name, value])
		"reactive":
			if value > 0:
				_log_message("  %s's %s deals %d damage!" % [unit.unit_name, effect_name.replace("_", " "), value])
			else:
				_log_message("  %s's %s triggers!" % [unit.unit_name, effect_name.replace("_", " ")])

	# Update unit visuals to show status icons
	if unit.has_method("_update_visuals"):
		unit._update_visuals()

	_update_turn_order_display()
	if selected_unit == unit:
		_show_unit_info(unit)


func _on_status_effect_expired(unit: Node, effect_name: String) -> void:
	_log_message("  %s is no longer %s" % [unit.unit_name, effect_name.replace("_", " ")])

	# Update unit visuals
	if unit.has_method("_update_visuals"):
		unit._update_visuals()

	# Refresh hover panel if this unit is selected
	if selected_unit == unit:
		_show_unit_info(unit)


func _on_terrain_damage(unit: Node, damage: int, effect_name: String) -> void:
	_log_message("  %s takes %d damage from %s!" % [unit.unit_name, damage, effect_name])


func _on_terrain_heal(unit: Node, amount: int, effect_name: String) -> void:
	_log_message("  %s heals %d from %s!" % [unit.unit_name, amount, effect_name])


# ============================================
# COMBAT REWARDS
# ============================================

## Apply combat rewards: grant XP to all party members, add gold
func _apply_rewards(rewards: Dictionary) -> void:
	var xp = rewards.get("xp", 0)
	var gold = rewards.get("gold", 0)

	if xp > 0:
		CompanionSystem.apply_party_xp(xp)

	if gold > 0:
		GameState.add_gold(gold)

	var items = rewards.get("items", [])
	for item_id in items:
		ItemSystem.add_to_inventory(item_id)


## Show the victory reward screen overlay
func _show_victory_screen(rewards: Dictionary) -> void:
	var xp = rewards.get("xp", 0)
	var gold = rewards.get("gold", 0)
	var items = rewards.get("items", [])
	var jackpot = rewards.get("jackpot_triggered", false)
	var jackpot_amount = rewards.get("jackpot_amount", 0)
	var trade_bonus = rewards.get("trade_bonus", 0)
	var enemy_count = rewards.get("enemy_count", 0)
	var ratio = rewards.get("difficulty_ratio", 1.0)

	# Full-screen overlay
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.06, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 400)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.07, 0.13)
	panel_style.border_color = Color(0.75, 0.6, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "VICTORY"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Difficulty description
	var diff_label = Label.new()
	var diff_text = ""
	if ratio < 0.7:
		diff_text = "Easy fight"
	elif ratio < 1.0:
		diff_text = "Fair fight"
	elif ratio < 1.3:
		diff_text = "Challenging fight"
	elif ratio < 2.0:
		diff_text = "Tough fight"
	else:
		diff_text = "Brutal fight!"
	diff_label.text = "%d enemies defeated - %s" % [enemy_count, diff_text]
	diff_label.add_theme_font_size_override("font_size", 13)
	diff_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(diff_label)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.5, 0.4, 0.2))
	vbox.add_child(sep)

	# XP reward
	var xp_row = HBoxContainer.new()
	xp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	xp_row.add_theme_constant_override("separation", 10)
	vbox.add_child(xp_row)

	var xp_icon = Label.new()
	xp_icon.text = "XP"
	xp_icon.add_theme_font_size_override("font_size", 18)
	xp_icon.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	xp_row.add_child(xp_icon)

	var xp_amount = Label.new()
	xp_amount.text = "+%d to each party member" % xp
	xp_amount.add_theme_font_size_override("font_size", 16)
	xp_amount.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	xp_row.add_child(xp_amount)

	# Gold reward
	var gold_row = HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_row.add_theme_constant_override("separation", 10)
	vbox.add_child(gold_row)

	var gold_icon = Label.new()
	gold_icon.text = "Gold"
	gold_icon.add_theme_font_size_override("font_size", 18)
	gold_icon.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	gold_row.add_child(gold_icon)

	var gold_amount = Label.new()
	var gold_text = "+%d" % gold
	if trade_bonus > 0:
		gold_text += " (Trade +%d%%)" % (trade_bonus * 10)
	gold_amount.text = gold_text
	gold_amount.add_theme_font_size_override("font_size", 16)
	gold_amount.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	gold_row.add_child(gold_amount)

	# Luck jackpot!
	if jackpot:
		var jackpot_row = HBoxContainer.new()
		jackpot_row.alignment = BoxContainer.ALIGNMENT_CENTER
		jackpot_row.add_theme_constant_override("separation", 10)
		vbox.add_child(jackpot_row)

		var jackpot_label = Label.new()
		jackpot_label.text = "LUCKY!"
		jackpot_label.add_theme_font_size_override("font_size", 20)
		jackpot_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		jackpot_row.add_child(jackpot_label)

		var jackpot_desc = Label.new()
		jackpot_desc.text = "+%d bonus gold!" % jackpot_amount
		jackpot_desc.add_theme_font_size_override("font_size", 16)
		jackpot_desc.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
		jackpot_row.add_child(jackpot_desc)

	# Item drops section (framework for future use)
	if not items.is_empty():
		var items_sep = HSeparator.new()
		items_sep.add_theme_color_override("separator", Color(0.5, 0.4, 0.2))
		vbox.add_child(items_sep)

		var items_title = Label.new()
		items_title.text = "Items Found"
		items_title.add_theme_font_size_override("font_size", 15)
		items_title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
		items_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(items_title)

		var items_grid = HBoxContainer.new()
		items_grid.alignment = BoxContainer.ALIGNMENT_CENTER
		items_grid.add_theme_constant_override("separation", 8)
		vbox.add_child(items_grid)

		# Create tooltip for this overlay
		var tooltip_layer = CanvasLayer.new()
		tooltip_layer.layer = 110
		overlay.add_child(tooltip_layer)
		var tooltip_scene = load("res://scenes/ui/item_tooltip.tscn")
		var tooltip_inst = tooltip_scene.instantiate()
		tooltip_layer.add_child(tooltip_inst)

		for item_id in items:
			var item = ItemSystem.get_item(item_id)
			if item.is_empty():
				continue

			var item_btn = Button.new()
			item_btn.custom_minimum_size = Vector2(56, 56)
			var item_name = item.get("name", "?")
			item_btn.text = item_name.substr(0, 3).to_upper() if item_name.length() > 3 else item_name.to_upper()
			item_btn.add_theme_font_size_override("font_size", 11)
			item_btn.tooltip_text = ""

			# Style by rarity
			var rarity_color = ItemSystem.get_rarity_color(item_id)
			item_btn.add_theme_color_override("font_color", rarity_color)
			var item_style = StyleBoxFlat.new()
			item_style.bg_color = Color(0.15, 0.15, 0.2)
			item_style.border_color = rarity_color.darkened(0.3)
			item_style.set_border_width_all(2)
			item_style.set_corner_radius_all(4)
			item_btn.add_theme_stylebox_override("normal", item_style)

			var item_hover = StyleBoxFlat.new()
			item_hover.bg_color = Color(0.22, 0.22, 0.28)
			item_hover.border_color = rarity_color
			item_hover.set_border_width_all(2)
			item_hover.set_corner_radius_all(4)
			item_btn.add_theme_stylebox_override("hover", item_hover)

			# Tooltip on hover
			item_btn.mouse_entered.connect(func():
				var pos = item_btn.get_global_mouse_position()
				tooltip_inst.show_item(item, pos)
			)
			item_btn.mouse_exited.connect(func():
				tooltip_inst.hide_tooltip()
			)

			items_grid.add_child(item_btn)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Continue button
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)

	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(160, 40)
	continue_btn.add_theme_font_size_override("font_size", 16)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.2, 0.1)
	btn_style.border_color = Color(0.75, 0.6, 0.2)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn_style.set_content_margin_all(8)
	continue_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.35, 0.28, 0.12)
	btn_hover.border_color = Color(0.9, 0.75, 0.3)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	btn_hover.set_content_margin_all(8)
	continue_btn.add_theme_stylebox_override("hover", btn_hover)

	continue_btn.pressed.connect(func():
		overlay.queue_free()
		GameState.returning_from_combat = true
		SaveManager.autosave()
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")
	)
	btn_container.add_child(continue_btn)

	# Add overlay to UILayer so it renders above all HUD elements
	$UILayer.add_child(overlay)


## Show defeat screen when all party members have fallen
func _show_defeat_screen() -> void:
	# Full-screen overlay
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark background — deeper/redder than victory
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.02, 0.02, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 300)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.04, 0.06)
	panel_style.border_color = Color(0.6, 0.2, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "ALL HAVE FALLEN"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.8, 0.25, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Flavor text
	var flavor = Label.new()
	flavor.text = "The wheel of existence turns.\nYour karma will determine the next life..."
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override("font_color", Color(0.6, 0.5, 0.45))
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(flavor)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	# Enter the Bardo button
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)

	var bardo_btn = Button.new()
	bardo_btn.text = "Enter the Bardo"
	bardo_btn.custom_minimum_size = Vector2(200, 44)
	bardo_btn.add_theme_font_size_override("font_size", 16)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.08, 0.08)
	btn_style.border_color = Color(0.6, 0.2, 0.2)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn_style.set_content_margin_all(8)
	bardo_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.12, 0.1)
	btn_hover.border_color = Color(0.8, 0.3, 0.25)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	btn_hover.set_content_margin_all(8)
	bardo_btn.add_theme_stylebox_override("hover", btn_hover)

	bardo_btn.pressed.connect(func():
		overlay.queue_free()
		GameState.is_party_wiped = true
		GameState.player_died()
		SaveManager.autosave()
		_fade_and_goto("res://scenes/ui/bardo_screen.tscn")
	)
	btn_container.add_child(bardo_btn)

	# Add overlay to UILayer so it renders above all HUD elements
	$UILayer.add_child(overlay)


# ============================================
# ENEMY AI (Simple)
# ============================================

## Handle a CC-controlled turn. The unit's actions are determined by their CC status.
## Works for both player and enemy units.
func _do_cc_turn(unit: CombatUnit, cc_behavior: String) -> void:
	if CombatManager.get_current_unit() != unit:
		return

	match cc_behavior:
		"feared":
			_do_feared_turn(unit)
		"confused":
			_do_confused_turn(unit)
		"berserk":
			_do_berserk_turn(unit)
		"pacified":
			_do_pacified_turn(unit)
		_:
			# Unknown CC — just end turn
			CombatManager.end_turn()


## Feared: flee away from the source of fear. Move as far as possible from the
## fear source each turn, then end turn (no attacks).
func _do_feared_turn(unit: CombatUnit) -> void:
	var source = CombatManager.get_cc_source(unit, "feared")
	var flee_from = source.grid_position if source != null and is_instance_valid(source) else Vector2i.ZERO

	# Try to move as far from the fear source as possible
	while CombatManager.can_act(1):
		var move_range = CombatManager.get_movement_range(unit)
		if move_range.is_empty():
			break

		var best_tile = unit.grid_position
		var best_dist = _grid_distance(unit.grid_position, flee_from)

		for tile in move_range:
			var dist = _grid_distance(tile, flee_from)
			if dist > best_dist:
				best_dist = dist
				best_tile = tile

		if best_tile != unit.grid_position:
			CombatManager.move_unit(unit, best_tile)
			_log_message("%s flees in terror!" % unit.unit_name)
		else:
			# Can't move further away — cornered
			_log_message("%s cowers in fear!" % unit.unit_name)
			break

	if CombatManager.get_current_unit() == unit:
		CombatManager.end_turn()


## Confused: move to a random valid tile, then attack a random adjacent target
## (ally or enemy). If no adjacent targets, just wander.
func _do_confused_turn(unit: CombatUnit) -> void:
	var _safety = 0
	while CombatManager.can_act(1):
		_safety += 1
		if _safety > 10:
			break

		# Step 1: Move to a random tile
		var move_range = CombatManager.get_movement_range(unit)
		if not move_range.is_empty():
			var random_tile = move_range[randi() % move_range.size()]
			if random_tile != unit.grid_position:
				CombatManager.move_unit(unit, random_tile)
				_log_message("%s stumbles around in confusion!" % unit.unit_name)

		# Step 2: Attack random adjacent unit (ally or enemy)
		if CombatManager.can_act(1):
			var adjacent: Array[Node] = []
			for u in CombatManager.all_units:
				if u == unit or u.is_dead:
					continue
				if _grid_distance(unit.grid_position, u.grid_position) <= unit.get_attack_range():
					adjacent.append(u)

			if not adjacent.is_empty():
				var random_target = adjacent[randi() % adjacent.size()]
				unit.play_attack_animation(random_target.global_position)
				var result = CombatManager.attack_unit(unit, random_target)
				if result.success:
					if result.hit:
						_log_message("%s lashes out at %s for %d damage!" % [
							unit.unit_name, random_target.unit_name, result.damage])
					else:
						_show_miss_text(unit, random_target)
						_log_message("%s swings wildly at %s - MISS!" % [
							unit.unit_name, random_target.unit_name])
			else:
				break  # Nothing to attack, stop

	if CombatManager.get_current_unit() == unit:
		CombatManager.end_turn()


## Berserk: attack the nearest creature regardless of team. Move toward them
## if not in range.
func _do_berserk_turn(unit: CombatUnit) -> void:
	# Find nearest living unit regardless of team
	var nearest: CombatUnit = null
	var nearest_dist: int = 999
	for u in CombatManager.all_units:
		if u == unit or u.is_dead:
			continue
		var dist = _grid_distance(unit.grid_position, u.grid_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = u

	if nearest == null:
		CombatManager.end_turn()
		return

	var _safety = 0
	while CombatManager.can_act(1) and CombatManager.get_current_unit() == unit:
		_safety += 1
		if _safety > 20:
			break

		var dist = _grid_distance(unit.grid_position, nearest.grid_position)

		if dist <= unit.get_attack_range():
			# Attack!
			unit.play_attack_animation(nearest.global_position)
			var result = CombatManager.attack_unit(unit, nearest)
			if result.success:
				var ally_text = " (ally!)" if nearest.team == unit.team else ""
				if result.hit:
					_log_message("%s attacks %s%s in a blind rage for %d damage!" % [
						unit.unit_name, nearest.unit_name, ally_text, result.damage])
				else:
					_show_miss_text(unit, nearest)
					_log_message("%s rages at %s%s - MISS!" % [
						unit.unit_name, nearest.unit_name, ally_text])

			# Re-find nearest if target died
			if not nearest.is_alive():
				nearest = null
				nearest_dist = 999
				for u in CombatManager.all_units:
					if u == unit or u.is_dead:
						continue
					var d = _grid_distance(unit.grid_position, u.grid_position)
					if d < nearest_dist:
						nearest_dist = d
						nearest = u
				if nearest == null:
					break
		else:
			# Move toward nearest
			var move_range = CombatManager.get_movement_range(unit)
			var best_tile = unit.grid_position
			for tile in move_range:
				if _grid_distance(tile, nearest.grid_position) < _grid_distance(best_tile, nearest.grid_position):
					best_tile = tile
			if best_tile != unit.grid_position:
				CombatManager.move_unit(unit, best_tile)
				_log_message("%s charges toward %s!" % [unit.unit_name, nearest.unit_name])
			else:
				break

	if CombatManager.get_current_unit() == unit:
		CombatManager.end_turn()


## Pacified: won't attack. Can only stand idle. Damage breaks the effect
## (handled in status processing via dispel_methods: taking_damage).
func _do_pacified_turn(unit: CombatUnit) -> void:
	_log_message("%s stands peacefully, unwilling to fight." % unit.unit_name)
	CombatManager.end_turn()


func _do_enemy_turn(unit: CombatUnit) -> void:
	# Safety check - make sure it's still this unit's turn
	if CombatManager.get_current_unit() != unit:
		return

	var player_units = CombatManager.get_team_units(CombatManager.Team.PLAYER)
	if player_units.is_empty():
		CombatManager.end_turn()
		return

	# Charmed enemies exclude the charm caster from valid targets
	var charm_source = CombatManager.get_cc_source(unit, "charmed")
	if charm_source != null:
		var filtered: Array[Node] = []
		for pu in player_units:
			if pu != charm_source:
				filtered.append(pu)
		player_units = filtered
		if player_units.is_empty():
			_log_message("%s is charmed and has no valid targets." % unit.unit_name)
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

	# Track flags to avoid repeating certain actions in a turn
	var used_consumable_this_turn = false
	var used_active_skill_this_turn = false

	# Use all actions (safety counter prevents infinite loops if an action path
	# fails to consume an action — max 20 iterations before forcing turn end)
	var _safety = 0
	while CombatManager.can_act(1) and CombatManager.get_current_unit() == unit:
		_safety += 1
		if _safety > 20:
			push_warning("AI safety limit hit for %s — ending turn" % unit.unit_name)
			break
		var dist = _grid_distance(unit.grid_position, nearest.grid_position)

		# --- PRIORITY 1: Emergency consumable (health potion at low HP) ---
		if not used_consumable_this_turn:
			var hp_pct = float(unit.current_hp) / float(unit.max_hp)
			if hp_pct < 0.35:
				if _ai_try_use_potion(unit, "heal"):
					used_consumable_this_turn = true
					continue

		# --- PRIORITY 2: Mana potion if caster is low on mana ---
		if not used_consumable_this_turn and is_caster:
			var mana_pct = float(unit.current_mana) / float(unit.max_mana) if unit.max_mana > 0 else 1.0
			if mana_pct < 0.3:
				if _ai_try_use_potion(unit, "restore_mana"):
					used_consumable_this_turn = true
					continue

		# --- PRIORITY 3: Active skills ---
		if not used_active_skill_this_turn:
			if _ai_try_use_active_skill(unit, player_units, nearest):
				used_active_skill_this_turn = true
				# Check if target died
				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break
				continue

		# --- PRIORITY 4: Spells ---
		# Refresh castable spells (mana may have changed)
		castable_spells = CombatManager.get_castable_spells(unit)
		if is_caster and not castable_spells.is_empty():
			var spell_cast = _ai_try_cast_spell(unit, castable_spells, player_units, nearest)
			if spell_cast:
				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break
				continue

		# --- PRIORITY 5: Bomb if multiple enemies clustered ---
		if not used_consumable_this_turn:
			if _ai_try_use_bomb(unit, player_units):
				used_consumable_this_turn = true
				# Refresh nearest after potential kills
				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break
				continue

		# --- PRIORITY 6: Oil before attacking (if in range and no oil active) ---
		if not used_consumable_this_turn and unit.weapon_oil.is_empty() and dist <= attack_range:
			if _ai_try_use_oil(unit):
				used_consumable_this_turn = true
				continue

		# --- PRIORITY 7: Physical attack ---
		if dist <= attack_range:
			unit.play_attack_animation(nearest.global_position)
			var result = CombatManager.attack_unit(unit, nearest)
			if result.success:
				if result.hit:
					var ranged_text = " from range" if dist > 1 else ""
					_log_message("%s attacks %s%s for %d damage!" % [unit.unit_name, nearest.unit_name, ranged_text, result.damage])
					AudioManager.play(_get_attack_sound(unit))
					if result.crit:
						AudioManager.play("hit_crit", -3.0)
					if result.has("oil_damage"):
						_log_message("  +%d %s damage (oil)!" % [
							result.oil_damage, result.get("oil_damage_type", "").capitalize()])
				else:
					_show_miss_text(unit, nearest)
					AudioManager.play("hit_miss", -3.0)
					_log_message("%s attacks %s - MISS!" % [unit.unit_name, nearest.unit_name])

				if not nearest.is_alive():
					nearest = _find_nearest_enemy(unit, player_units)
					if nearest == null:
						break
		else:
			# --- PRIORITY 8: Reposition if out of range ---
			var move_range = CombatManager.get_movement_range(unit)
			var best_tile: Vector2i = unit.grid_position
			var best_score: int = -999

			# Find max effective range across all castable spells (handles melee vs ranged spells)
			var max_spell_range := 0
			for sp in castable_spells:
				max_spell_range = max(max_spell_range, _get_spell_ai_range(sp))

			var optimal_range = 1
			if max_spell_range > 1:
				# Has ranged spells — stay at range to use them
				optimal_range = max_spell_range
			elif is_ranged:
				optimal_range = attack_range

			# Whether to use range-keeping movement (spells or ranged weapon) vs just close in
			var wants_range = max_spell_range > 1 or is_ranged

			for tile in move_range:
				var tile_dist = _grid_distance(tile, nearest.grid_position)

				if wants_range:
					var score = 0
					if tile_dist <= optimal_range and tile_dist >= 2:
						score = 100
						score += tile_dist
					elif tile_dist <= optimal_range:
						score = 50
					else:
						score = -tile_dist
					if score > best_score:
						best_score = score
						best_tile = tile
				else:
					if tile_dist < _grid_distance(best_tile, nearest.grid_position):
						best_tile = tile

			if best_tile != unit.grid_position:
				CombatManager.move_unit(unit, best_tile)
				if not castable_spells.is_empty():
					_log_message("%s positions for casting" % unit.unit_name)
				elif is_ranged:
					_log_message("%s repositions" % unit.unit_name)
				else:
					_log_message("%s moves toward %s" % [unit.unit_name, nearest.unit_name])
			else:
				break

	# End turn if we still have control
	if CombatManager.get_current_unit() == unit:
		CombatManager.end_turn()


## Get effective range for a spell for AI use.
## Mirrors CombatManager.get_spell() range normalization so both movement and
## casting use the same numbers (raw spell data stores range inside target.range).
func _get_spell_ai_range(spell: Dictionary) -> int:
	var target_data = spell.get("target", {})
	var raw_range = target_data.get("range", spell.get("range", ""))
	if raw_range == "melee":
		return 1
	elif raw_range is int or raw_range is float:
		return int(raw_range)
	else:
		# No range specified — default by level (level 1 = range 4, level 3 = range 6, etc.)
		var level = spell.get("level", 1)
		return 3 + level


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
		var spell_range = _get_spell_ai_range(spell)
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
## AI: Try to use a potion of a given effect type from combat_inventory.
## Returns true if a potion was used.
func _ai_try_use_potion(unit: CombatUnit, effect_type: String) -> bool:
	for inv_entry in unit.combat_inventory:
		var item_id = inv_entry.get("item_id", "")
		var qty = inv_entry.get("quantity", 0)
		if qty <= 0:
			continue

		var item = ItemSystem.get_item(item_id)
		if item.is_empty() or item.get("type", "") != "potion":
			continue

		var effect = item.get("effect", {})
		if effect.get("type", "") == effect_type:
			var result = CombatManager.ai_use_combat_item(unit, item_id, unit.grid_position)
			if result.get("success", false):
				var item_name = item.get("name", item_id)
				_log_message("%s uses %s!" % [unit.unit_name, item_name])
				for fx in result.get("effects_applied", []):
					if fx.get("type", "") == "heal":
						_log_message("  Healed for %d HP" % fx.amount)
					elif fx.get("type", "") == "restore_mana":
						_log_message("  Restored %d mana" % fx.amount)
				return true
	return false


## AI: Try to use a bomb on clustered player units. Uses if 2+ enemies in blast radius.
func _ai_try_use_bomb(unit: CombatUnit, player_units: Array[Node]) -> bool:
	for inv_entry in unit.combat_inventory:
		var item_id = inv_entry.get("item_id", "")
		var qty = inv_entry.get("quantity", 0)
		if qty <= 0:
			continue

		var item = ItemSystem.get_item(item_id)
		if item.is_empty() or item.get("type", "") != "bomb":
			continue

		var effect = item.get("effect", {})
		var bomb_range = effect.get("range", 4)
		var aoe_radius = effect.get("aoe_radius", 1)

		# Find best bomb target (position that hits the most enemies)
		var best_pos = Vector2i(-1, -1)
		var best_count = 0

		for target in player_units:
			if not target.is_alive():
				continue
			var dist = _grid_distance(unit.grid_position, target.grid_position)
			if dist > bomb_range:
				continue
			# Count enemies in AoE
			var count = 0
			for other in player_units:
				if other.is_alive() and _grid_distance(target.grid_position, other.grid_position) <= aoe_radius:
					count += 1
			if count > best_count:
				best_count = count
				best_pos = target.grid_position

		# Only use bomb if hitting 2+ enemies
		if best_count >= 2 and best_pos != Vector2i(-1, -1):
			var result = CombatManager.ai_use_combat_item(unit, item_id, best_pos)
			if result.get("success", false):
				var item_name = item.get("name", item_id)
				_log_message("%s throws %s!" % [unit.unit_name, item_name])
				var total_damage = result.get("total_damage", 0)
				var hit_count = result.get("hit_count", 0)
				if hit_count > 0:
					_log_message("  Hit %d targets for %d total damage!" % [hit_count, total_damage])
				return true
	return false


## AI: Try to apply a weapon oil from combat_inventory.
func _ai_try_use_oil(unit: CombatUnit) -> bool:
	for inv_entry in unit.combat_inventory:
		var item_id = inv_entry.get("item_id", "")
		var qty = inv_entry.get("quantity", 0)
		if qty <= 0:
			continue

		var item = ItemSystem.get_item(item_id)
		if item.is_empty() or item.get("type", "") != "oil":
			continue

		var result = CombatManager.ai_use_combat_item(unit, item_id, unit.grid_position)
		if result.get("success", false):
			_log_message("%s coats weapon with %s!" % [unit.unit_name, item.get("name", item_id)])
			return true
	return false


## AI: Try to use an active skill. Evaluates available perks and picks the best one.
## Returns true if a skill was used.
func _ai_try_use_active_skill(unit: CombatUnit, player_units: Array[Node], nearest: CombatUnit) -> bool:
	var perks = unit.character_data.get("perks", [])
	if perks.is_empty():
		return false

	var dist = _grid_distance(unit.grid_position, nearest.grid_position)
	var hp_pct = float(unit.current_hp) / float(unit.max_hp)
	var best_skill: Dictionary = {}
	var best_score: float = 0.0
	var best_target_pos: Vector2i = unit.grid_position

	for perk_entry in perks:
		var perk_id = perk_entry.get("id", "")
		var perk_data = PerkSystem.get_perk_data(perk_id)
		if perk_data.is_empty():
			continue

		var combat_data = perk_data.get("combat_data", {})
		if combat_data.is_empty():
			continue

		# Check cooldown
		if unit.is_skill_on_cooldown(perk_id):
			continue

		# Check stamina
		var stamina_cost = combat_data.get("stamina_cost", 0)
		if stamina_cost > 0 and unit.current_stamina < stamina_cost:
			continue

		# Check weapon requirement
		var perk_skill = perk_data.get("skill", "")
		if not CombatManager.unit_has_required_weapon(unit, perk_skill):
			continue

		var effect = combat_data.get("effect", "")
		var targeting = combat_data.get("targeting", "self")
		var skill_range = combat_data.get("range", 1)
		var score: float = 0.0
		var target_pos: Vector2i = unit.grid_position

		# Score each skill type based on situation
		match effect:
			"attack_with_bonus":
				# Good when in melee range and want to deal extra damage
				if dist <= skill_range:
					var dmg_bonus = combat_data.get("damage_bonus_pct", 0)
					var acc_bonus = combat_data.get("accuracy_bonus", 0)
					score = 30.0 + dmg_bonus * 0.3 + acc_bonus * 0.2
					# Extra value for armor-piercing against armored targets
					if combat_data.get("armor_ignore_pct", 0) > 0:
						score += 15.0
					# Extra value for finishers (refund_on_kill) when target is low HP
					if combat_data.get("refund_on_kill", 0) > 0:
						var target_hp_pct = float(nearest.current_hp) / float(nearest.max_hp)
						if target_hp_pct < 0.3:
							score += 20.0
					target_pos = nearest.grid_position

			"dash_attack":
				# Good when out of melee range but within dash range
				var dash_range = combat_data.get("dash_range", 2) + unit.get_attack_range()
				if dist > unit.get_attack_range() and dist <= dash_range:
					score = 45.0  # High value for closing distance + attacking
					target_pos = nearest.grid_position
				elif dist <= unit.get_attack_range():
					score = 20.0  # Still usable in melee, but less value
					target_pos = nearest.grid_position

			"buff_self":
				# Use buffs when about to engage (within 3 tiles of enemy)
				if dist <= 3:
					score = 20.0
				# Higher score at start of combat (no enemies attacked yet)
				if dist > 4:
					score = 5.0  # Less valuable when far away

			"debuff_target":
				# Good against strong enemies when in range
				if dist <= skill_range:
					score = 25.0
					target_pos = nearest.grid_position

			"aoe_attack":
				# Count enemies in AoE range
				var aoe_r = combat_data.get("aoe_radius", 1)
				# For self-centered AoE (range 0), use own position
				var center = unit.grid_position if skill_range == 0 else nearest.grid_position
				if skill_range > 0 and dist > skill_range:
					continue  # Out of range
				var hit_count = 0
				for target in player_units:
					if target.is_alive() and _grid_distance(center, target.grid_position) <= aoe_r:
						hit_count += 1
				if hit_count >= 2:
					score = 35.0 + hit_count * 10.0  # Very good if hitting multiple
					target_pos = center
				elif hit_count == 1 and skill_range == 0:
					score = 15.0  # Still okay for self-centered AoE
					target_pos = center

			"stance":
				# Stances end your turn — use when already in position to defend
				if dist <= 2 and hp_pct < 0.6:
					score = 25.0  # Defensive when hurt and enemies close
				elif dist <= 1:
					score = 15.0

			"teleport":
				# Use when surrounded or need to reposition badly
				if dist <= 1 and hp_pct < 0.4:
					score = 35.0  # Escape when hurt in melee

			"heal_self":
				# Use when hurt
				if hp_pct < 0.5:
					score = 30.0 + (1.0 - hp_pct) * 20.0
				if combat_data.get("stamina_restore_pct", 0) > 0 and unit.current_stamina < unit.max_stamina * 0.3:
					score = 25.0  # Stamina recovery

		if score > best_score:
			best_score = score
			best_skill = {"id": perk_id, "name": perk_data.get("name", perk_id), "skill": perk_data.get("skill", ""), "combat_data": combat_data}
			best_target_pos = target_pos

	# Only use if score is meaningful (avoid wasting skills)
	if best_score >= 15.0 and not best_skill.is_empty():
		var skill_name = best_skill.get("name", "???")
		var result = CombatManager.use_active_skill(unit, best_skill, best_target_pos)

		if result.get("success", false):
			var stamina_cost = best_skill.combat_data.get("stamina_cost", 0)
			var stamina_text = " (%d ST)" % stamina_cost if stamina_cost > 0 else ""
			_log_message("%s uses %s%s!" % [unit.unit_name, skill_name, stamina_text])

			var effect = best_skill.combat_data.get("effect", "")
			match effect:
				"attack_with_bonus", "dash_attack":
					if result.get("hit", false):
						var target = result.get("target", null)
						var target_name = target.unit_name if target else "???"
						_log_message("  Hit %s for %d damage!" % [target_name, result.get("damage", 0)])
					elif result.has("hit"):
						_log_message("  Missed!")
				"buff_self", "stance", "heal_self":
					for fx in result.get("effects", []):
						if fx.type == "buff":
							_log_message("  +%d%% %s" % [fx.value, fx.stat])
						elif fx.type == "heal":
							_log_message("  Healed %d HP" % fx.amount)
						elif fx.type == "stamina_restore":
							_log_message("  Restored %d stamina" % fx.amount)
				"debuff_target":
					var target = result.get("target", null)
					if target and result.get("hit", true):
						_log_message("  Debuffed %s" % target.unit_name)
				"aoe_attack":
					_log_message("  Hit %d enemies!" % result.get("hit_count", 0))
				"teleport":
					_log_message("  Teleported!")
			return true

	return false


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


## Show appropriate miss text based on what caused the miss
## Block = defender has a shield, Dodge = dodge stat high, Miss = generic
func _show_miss_text(attacker: Node, defender: Node) -> void:
	if _has_shield_equipped(defender):
		defender.show_combat_text("Block!", Color(0.9, 0.75, 0.3))
	elif defender.get_dodge() > attacker.get_accuracy():
		defender.show_combat_text("Dodge!", Color(0.6, 0.85, 1.0))
	else:
		defender.show_combat_text("Miss!", Color(0.8, 0.8, 0.8))


## Return the AudioManager sound name for a unit's equipped weapon.
## Used for both player and AI attack sounds.
func _get_attack_sound(unit: Node) -> String:
	var weapon: Dictionary = unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else {}
	match weapon.get("type", "unarmed"):
		"sword":   return "attack_sword"
		"spear":   return "attack_sword"    # spears share the slashing sound
		"dagger":  return "attack_dagger"
		"axe":     return "attack_axe"
		"mace":    return "attack_mace"
		"bow", "crossbow": return "attack_ranged"
		"unarmed": return "attack_unarmed"
		"fist":    return "attack_martial_arts"
		_:         return "attack_generic"


## Return the AudioManager impact sound for a spell damage element.
func _get_spell_impact_sound(element: String) -> String:
	match element:
		"fire":                          return "spell_impact_fire"
		"lightning", "electric", "air":  return "spell_impact_electric"
		"piercing":                      return "spell_impact_pierce"
		_:                               return "spell_impact_generic"


## Fade to black then change scene. Used for death → bardo transition.
func _fade_and_goto(scene_path: String) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$UILayer.add_child(overlay)
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))


## Check if a unit has a shield equipped in the off-hand slot
func _has_shield_equipped(unit: Node) -> bool:
	var char_data = unit.character_data
	if not ItemSystem:
		return false
	if not char_data.has("equipment"):
		return false
	var off_hand_id = ItemSystem.get_equipped_item(char_data, "weapon_off")
	if off_hand_id == "":
		return false
	var item = ItemSystem.get_item(off_hand_id)
	return item.get("type", "") == "shield"


# ============================================
# RIGHT-CLICK CONTEXT MENU & EXAMINE WINDOW
# ============================================

## Handle right-click on a grid tile
func _on_tile_right_clicked(grid_pos: Vector2i) -> void:
	var unit = combat_grid.get_unit_at(grid_pos)
	if unit:
		_context_menu_unit = unit
		context_menu.clear()
		context_menu.add_item("Examine", 0)
		# Position near the mouse
		context_menu.position = Vector2i(get_viewport().get_mouse_position())
		context_menu.popup()
	else:
		_cancel_action_mode()


## Create the right-click context popup menu
func _create_context_menu() -> void:
	context_menu = PopupMenu.new()
	context_menu.id_pressed.connect(_on_context_menu_pressed)
	add_child(context_menu)


## Handle context menu selection
func _on_context_menu_pressed(id: int) -> void:
	match id:
		0:  # Examine
			if _context_menu_unit:
				_show_examine_window(_context_menu_unit)


## Create the examine window (built once, populated on demand)
func _create_examine_panel() -> void:
	# Semi-transparent background overlay that closes on click
	var overlay = ColorRect.new()
	overlay.name = "ExamineOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			examine_panel.hide()
			overlay.hide()
	)
	overlay.hide()
	$UILayer.add_child(overlay)

	# Main panel — centered, sized to content
	examine_panel = PanelContainer.new()
	examine_panel.name = "ExaminePanel"
	examine_panel.custom_minimum_size = Vector2(400, 300)
	examine_panel.set_anchors_preset(Control.PRESET_CENTER)
	examine_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	examine_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	examine_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Tibetan-style panel styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	panel_style.border_color = Color(0.75, 0.55, 0.2)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(16)
	examine_panel.add_theme_stylebox_override("panel", panel_style)
	examine_panel.hide()

	# Inner margin container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	examine_panel.add_child(margin)

	# Scroll container for long content
	examine_scroll = ScrollContainer.new()
	examine_scroll.custom_minimum_size = Vector2(380, 280)
	examine_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(examine_scroll)

	# VBox for all content
	examine_content = VBoxContainer.new()
	examine_content.add_theme_constant_override("separation", 6)
	examine_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	examine_scroll.add_child(examine_content)

	$UILayer.add_child(examine_panel)


## Show the examine window for a unit
func _show_examine_window(unit: CombatUnit) -> void:
	# Clear previous content
	for child in examine_content.get_children():
		child.queue_free()

	var char_data = unit.character_data
	var is_enemy = unit.team == CombatManager.Team.ENEMY
	var is_player = not is_enemy

	# Determine what the player can see based on Learning/Medicine perks
	var player_party = CombatManager.get_team_units(CombatManager.Team.PLAYER)
	var can_see_stats = is_player  # Always see your own stats
	var can_see_skills = is_player
	var can_see_resistances = false
	var can_see_statuses = true  # Always visible (player should know what's happening)

	# Check if any player party member has relevant perks
	for pu in player_party:
		var pchar = pu.character_data if "character_data" in pu else {}
		# observe_carefully (Learning 1): reveals HP, armor, resistances, weakness
		if PerkSystem.has_perk(pchar, "observe_carefully"):
			can_see_resistances = true
		# diagnosis (Medicine 1): reveals status effects, durations, HP, vulnerabilities
		# (statuses already visible, but this adds detail)

	# --- HEADER: Name ---
	var name_label = Label.new()
	name_label.text = unit.unit_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	examine_content.add_child(name_label)

	# --- FLAVOR TEXT ---
	var flavor = ""
	if is_player:
		# Player: show race description
		var race_id = char_data.get("race", "")
		if race_id != "":
			var races_data = _get_races_data()
			var race_def = races_data.get(race_id, {})
			flavor = race_def.get("description", "")
		var bg_id = char_data.get("background", "")
		if bg_id != "" and flavor == "":
			flavor = bg_id.replace("_", " ").capitalize()
	else:
		# Enemy: show archetype if available
		var archetype_id = char_data.get("archetype_id", "")
		if archetype_id != "":
			flavor = archetype_id.replace("_", " ").capitalize()

	if flavor != "":
		var flavor_label = Label.new()
		flavor_label.text = flavor
		flavor_label.add_theme_font_size_override("font_size", 11)
		flavor_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
		flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		examine_content.add_child(flavor_label)

	_add_examine_separator()

	# --- HP / MANA / STAMINA BARS ---
	var hp_row = _create_examine_stat_row("HP", "%d / %d" % [unit.current_hp, unit.max_hp], Color(0.8, 0.2, 0.2))
	examine_content.add_child(hp_row)

	if unit.max_mana > 0:
		var mp_row = _create_examine_stat_row("Mana", "%d / %d" % [unit.current_mana, unit.max_mana], Color(0.3, 0.4, 0.9))
		examine_content.add_child(mp_row)

	var derived = char_data.get("derived", {})
	var max_st = derived.get("max_stamina", 0)
	if max_st > 0:
		var cur_st = derived.get("current_stamina", max_st)
		var st_row = _create_examine_stat_row("Stamina", "%d / %d" % [cur_st, max_st], Color(0.9, 0.75, 0.2))
		examine_content.add_child(st_row)

	# --- COMBAT STATS (always visible — armor, dodge, accuracy, damage, crit, movement) ---
	_add_examine_separator()
	var combat_header = _create_examine_section_header("Combat Stats")
	examine_content.add_child(combat_header)

	var combat_stats = [
		["Armor", str(unit.get_armor())],
		["Dodge", str(unit.get_dodge())],
		["Accuracy", str(unit.get_accuracy())],
		["Damage", str(unit.get_attack_damage())],
		["Crit", "%d%%" % unit.get_crit_chance()],
		["Movement", str(unit.get_movement())],
		["Initiative", str(derived.get("initiative", 10))],
	]
	if unit.max_mana > 0:
		combat_stats.append(["Spellpower", str(unit.get_spellpower())])

	var stats_grid = _create_examine_stats_grid(combat_stats)
	examine_content.add_child(stats_grid)

	# --- ATTRIBUTES (controlled by perks for enemies) ---
	if can_see_stats:
		var attributes = char_data.get("attributes", {})
		if not attributes.is_empty():
			_add_examine_separator()
			var attr_header = _create_examine_section_header("Attributes")
			examine_content.add_child(attr_header)

			var attr_pairs: Array = []
			var attr_order = ["strength", "constitution", "finesse", "focus", "awareness", "charm", "luck"]
			for attr in attr_order:
				if attr in attributes:
					attr_pairs.append([attr.capitalize(), str(attributes[attr])])
			var attr_grid = _create_examine_stats_grid(attr_pairs)
			examine_content.add_child(attr_grid)

	# --- SKILLS (controlled by perks for enemies) ---
	if can_see_skills:
		var skills = char_data.get("skills", {})
		# Filter to non-zero skills
		var trained: Array = []
		for skill_id in skills:
			var level = skills[skill_id]
			if level > 0:
				trained.append([skill_id.replace("_", " ").capitalize(), str(int(level))])
		if not trained.is_empty():
			_add_examine_separator()
			var skill_header = _create_examine_section_header("Skills")
			examine_content.add_child(skill_header)
			var skill_grid = _create_examine_stats_grid(trained)
			examine_content.add_child(skill_grid)

	# --- RESISTANCES (requires observe_carefully perk for enemies) ---
	if can_see_resistances or is_player:
		var resistances = unit.resistances if "resistances" in unit else {}
		# Filter non-zero
		var res_pairs: Array = []
		for element in resistances:
			var val = resistances[element]
			if val != 0:
				var prefix = "+" if val > 0 else ""
				res_pairs.append([element.capitalize(), prefix + str(val) + "%"])
		if not res_pairs.is_empty():
			_add_examine_separator()
			var res_header = _create_examine_section_header("Resistances")
			examine_content.add_child(res_header)
			var res_grid = _create_examine_stats_grid(res_pairs)
			examine_content.add_child(res_grid)

	# --- STATUS EFFECTS (always visible) ---
	var all_statuses = _gather_all_statuses(unit)
	if not all_statuses.is_empty():
		_add_examine_separator()
		var status_header = _create_examine_section_header("Status Effects")
		examine_content.add_child(status_header)

		for status_info in all_statuses:
			var status_row = _create_examine_status_row(status_info)
			examine_content.add_child(status_row)

	# --- CLOSE HINT ---
	_add_examine_separator()
	var close_hint = Label.new()
	close_hint.text = "Click outside or press Esc to close"
	close_hint.add_theme_font_size_override("font_size", 9)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	examine_content.add_child(close_hint)

	# Show overlay and panel
	$UILayer.get_node("ExamineOverlay").show()
	examine_panel.show()

	# Resize panel to fit content (capped)
	await get_tree().process_frame
	var content_height = examine_content.get_combined_minimum_size().y + 48
	examine_panel.custom_minimum_size.y = minf(content_height, 500)
	examine_panel.size = Vector2(420, minf(content_height, 500))
	# Re-center after resize
	examine_panel.position = (get_viewport_rect().size - examine_panel.size) / 2


## Gather all status effects for a unit, including equipment-granted persistent effects
func _gather_all_statuses(unit: CombatUnit) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	# Active status effects from combat
	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var duration = effect.get("duration", 0)
		var def = CombatManager.get_status_definition(status_name)
		var stype = def.get("type", "debuff")
		var dur_type = def.get("duration_type", "turns")

		var dur_text = ""
		if dur_type == "permanent":
			dur_text = "Permanent"
		elif dur_type == "until_save":
			dur_text = "Until save"
		else:
			dur_text = "%d turns" % duration

		result.append({
			"name": status_name.replace("_", " "),
			"type": stype,
			"duration": dur_text,
			"source": "status"
		})

	# Equipment-granted persistent effects (talisman perks)
	var char_data = unit.character_data if "character_data" in unit else {}
	var equipment = char_data.get("equipment", {})
	for slot in ["trinket1", "trinket2"]:
		var item_id = equipment.get(slot, "")
		if item_id == "":
			continue
		var item = ItemSystem.get_item(item_id)
		var perk_id = item.get("passive", {}).get("perk", "")
		if perk_id != "":
			var perk_name = perk_id.replace("_", " ").capitalize()
			var item_name = item.get("name", slot)
			result.append({
				"name": perk_name,
				"type": "equipment",
				"duration": item_name,
				"source": "equipment"
			})

		# Also show resistance bonuses from equipment
		var passive = item.get("passive", {})
		for key in passive:
			if key.ends_with("_resistance") and passive[key] != 0:
				var element = key.replace("_resistance", "").capitalize()
				var val = passive[key]
				var prefix = "+" if val > 0 else ""
				result.append({
					"name": "%s Res %s%d%%" % [element, prefix, val],
					"type": "equipment",
					"duration": item.get("name", slot),
					"source": "equipment"
				})

	# Stat modifiers (temporary buffs/debuffs from spells etc.)
	if "stat_modifiers" in unit:
		for mod in unit.stat_modifiers:
			var stat = mod.get("stat", "")
			var value = mod.get("value", 0)
			var duration = mod.get("duration", 0)
			if stat != "" and value != 0:
				var prefix = "+" if value > 0 else ""
				var mod_type = "buff" if value > 0 else "debuff"
				result.append({
					"name": "%s%d %s" % [prefix, value, stat.capitalize()],
					"type": mod_type,
					"duration": "%d turns" % duration,
					"source": "modifier"
				})

	return result


## Create a status row for the examine window (name left, duration right)
func _create_examine_status_row(status_info: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()

	var name_lbl = Label.new()
	name_lbl.text = status_info.name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Color by type
	match status_info.type:
		"buff":
			name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		"debuff":
			name_lbl.add_theme_color_override("font_color", Color(0.95, 0.5, 0.3))
		"equipment":
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		_:
			name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	row.add_child(name_lbl)

	var dur_lbl = Label.new()
	dur_lbl.text = status_info.duration
	dur_lbl.add_theme_font_size_override("font_size", 10)
	dur_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	dur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(dur_lbl)

	return row


## Create a stat row for the examine window (label left, value right)
func _create_examine_stat_row(label: String, value: String, color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()

	var name_lbl = Label.new()
	name_lbl.text = label
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	return row


## Create a section header label
func _create_examine_section_header(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.4))
	return label


## Create a grid of stat name-value pairs (two columns per row)
func _create_examine_stats_grid(pairs: Array) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = 4  # name1, val1, name2, val2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)

	for i in range(pairs.size()):
		var pair = pairs[i]
		var name_lbl = Label.new()
		name_lbl.text = pair[0]
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		name_lbl.custom_minimum_size.x = 80
		grid.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = pair[1]
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		val_lbl.custom_minimum_size.x = 40
		grid.add_child(val_lbl)

	# If odd number of pairs, add empty cells to fill last row
	if pairs.size() % 2 == 1:
		var empty1 = Control.new()
		empty1.custom_minimum_size.x = 80
		grid.add_child(empty1)
		var empty2 = Control.new()
		empty2.custom_minimum_size.x = 40
		grid.add_child(empty2)

	return grid


## Add a separator line to the examine content
func _add_examine_separator() -> void:
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 4
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	examine_content.add_child(sep)


## Cache for races data (loaded once)
var _cached_races_data: Dictionary = {}

## Load races data for flavor text lookup
func _get_races_data() -> Dictionary:
	if not _cached_races_data.is_empty():
		return _cached_races_data
	var file = FileAccess.open("res://resources/data/races.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_cached_races_data = json.data.get("races", {})
		file.close()
	return _cached_races_data
