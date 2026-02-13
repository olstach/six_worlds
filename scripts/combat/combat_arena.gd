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
	combat_grid.tile_hovered.connect(_on_tile_hovered)

	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	spell_button.pressed.connect(_on_spell_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
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
	var player_start_positions = [Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3), Vector2i(0, 3), Vector2i(2, 1), Vector2i(2, 5)]

	for i in range(mini(party.size(), player_start_positions.size())):
		var char_data = party[i]
		var unit = CombatUnit.new()
		unit.init_from_character(char_data, CombatManager.Team.PLAYER)
		combat_grid.place_unit(unit, player_start_positions[i])
		player_units.append(unit)
		_log_message("Player: %s placed at %s" % [unit.unit_name, player_start_positions[i]])

	# Place enemies based on their roles (frontline closer, ranged/caster in back)
	var enemy_units: Array = []
	var frontline_positions = [Vector2i(9, 2), Vector2i(9, 4), Vector2i(9, 3)]
	var backline_positions = [Vector2i(11, 2), Vector2i(11, 4), Vector2i(11, 3)]
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
			pos = Vector2i(10, enemy_units.size())

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
	var grid_w = combat_grid.grid_size.x  # 12
	var grid_h = combat_grid.grid_size.y  # 8

	var tile_overrides: Dictionary = {}  # "x,y" -> TileType
	var effects: Array[Dictionary] = []
	var heights: Array[Dictionary] = []

	# Budget obstacles based on overworld terrain counts in the 5x5 sample
	var obstacle_budget = 0
	var water_budget = 0
	var difficult_budget = 0

	for terrain_type in counts:
		var count = int(counts[terrain_type])
		match int(terrain_type):
			4:  # MOUNTAINS -> walls
				obstacle_budget += count
			5:  # WATER -> water tiles
				water_budget += count
			2, 6:  # FOREST, SWAMP -> difficult terrain
				difficult_budget += count
			3:  # HILLS -> height variation
				for i in range(mini(count, 4)):
					var hx = randi_range(3, grid_w - 4)
					var hy = randi_range(1, grid_h - 2)
					heights.append({"pos": Vector2i(hx, hy), "height": 1})
			9:  # LAVA -> fire pits
				for i in range(mini(count / 2, 3)):
					var lx = randi_range(3, grid_w - 4)
					var ly = randi_range(1, grid_h - 2)
					tile_overrides["%d,%d" % [lx, ly]] = CombatGrid.TileType.PIT
					effects.append({"pos": Vector2i(lx, ly),
						"effect": CombatGrid.TerrainEffect.FIRE, "value": 5})
			13:  # RUINS -> difficult terrain with some walls
				difficult_budget += count / 2
				obstacle_budget += count / 3

	# Place wall obstacles (from mountains/ruins)
	var walls_to_place = clampi(obstacle_budget / 4, 0, 6)
	for i in range(walls_to_place):
		var wx = randi_range(3, grid_w - 4)
		var wy = randi_range(1, grid_h - 2)
		tile_overrides["%d,%d" % [wx, wy]] = CombatGrid.TileType.WALL

	# Place water tiles
	var water_to_place = clampi(water_budget / 3, 0, 4)
	for i in range(water_to_place):
		var wx = randi_range(3, grid_w - 4)
		var wy = randi_range(1, grid_h - 2)
		tile_overrides["%d,%d" % [wx, wy]] = CombatGrid.TileType.WATER

	# Place difficult terrain (from forest/swamp)
	var diff_to_place = clampi(difficult_budget / 3, 0, 6)
	for i in range(diff_to_place):
		var dx = randi_range(2, grid_w - 3)
		var dy = randi_range(0, grid_h - 1)
		tile_overrides["%d,%d" % [dx, dy]] = CombatGrid.TileType.DIFFICULT

	# Dominant terrain effects (snow/ice -> ice patches, etc.)
	match dominant:
		8, 11:  # SNOW, ICE
			for i in range(randi_range(2, 5)):
				var ix = randi_range(2, grid_w - 3)
				var iy = randi_range(0, grid_h - 1)
				var key = "%d,%d" % [ix, iy]
				if not key in tile_overrides:
					effects.append({"pos": Vector2i(ix, iy),
						"effect": CombatGrid.TerrainEffect.ICE, "value": 0})

	# Safety: never block deployment zones (columns 0-2 for player, last 3 for enemy)
	for key in tile_overrides.keys():
		var parts = key.split(",")
		var kx = int(parts[0])
		if kx < 3 or kx >= grid_w - 3:
			tile_overrides.erase(key)

	# Also clear effects from deployment zones
	var safe_effects: Array[Dictionary] = []
	for eff in effects:
		var ex = eff.get("pos", Vector2i(-1, -1)).x
		if ex >= 3 and ex < grid_w - 3:
			safe_effects.append(eff)
	effects = safe_effects

	return {
		"size": Vector2i(grid_w, grid_h),
		"tiles": tile_overrides,
		"effects": effects,
		"heights": heights
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
	var weapon_range = unit.get_attack_range()
	var attack_range = combat_grid.get_attack_range_tiles(unit.grid_position, 1, weapon_range)
	combat_grid.highlight_attack_range(attack_range)

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


## Attempt to flee combat
## Roll: d20 + party avg finesse vs 10 + enemy avg finesse
## Success: return to overworld (mob stays on map)
## Failure: costs 1 action
func _on_flee_pressed() -> void:
	if not CombatManager.is_player_turn():
		return

	if not CombatManager.can_act(1):
		return

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
	flee_button.disabled = not is_player or not can_act
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
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")
	else:
		_log_message("=== DEFEAT ===")
		# On defeat, clear the mob id so it stays on the map
		GameState.last_defeated_mob_id = ""
		GameState.returning_from_combat = true
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")


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
# COMBAT REWARDS
# ============================================

## Apply combat rewards: grant XP to all party members, add gold
func _apply_rewards(rewards: Dictionary) -> void:
	var xp = rewards.get("xp", 0)
	var gold = rewards.get("gold", 0)

	# Grant full XP to ALL party members equally
	for member in CharacterSystem.get_party():
		CharacterSystem.grant_xp(member, xp)

	# Add gold
	if gold > 0:
		GameState.add_gold(gold)

	# Add items to inventory (framework for later)
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
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")
	)
	btn_container.add_child(continue_btn)

	# Add overlay to scene
	add_child(overlay)


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
