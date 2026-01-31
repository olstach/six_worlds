extends Node
## CombatManager - Manages tactical combat state and flow
##
## This singleton handles:
## - Combat initialization and cleanup
## - Turn order based on initiative
## - Action economy (2 actions per turn, up to 4 with buffs)
## - Win/lose condition checking
## - Damage calculation and resolution

# Signals for UI and other systems to react
signal combat_started()
signal combat_ended(victory: bool)
signal turn_started(unit: Node)
signal turn_ended(unit: Node)
signal unit_moved(unit: Node, from: Vector2i, to: Vector2i)
signal unit_attacked(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, damage: int, damage_type: String)
signal unit_died(unit: Node)
signal unit_bleeding_out(unit: Node, turns_remaining: int)
signal action_used(unit: Node, actions_remaining: int)

# Combat state
var combat_active: bool = false
var combat_grid: Node = null  # Reference to CombatGrid
var arena_scene: Node = null  # Reference to combat arena

# Units in combat
var all_units: Array[Node] = []
var turn_order: Array[Node] = []
var current_unit_index: int = 0

# Team constants
enum Team { PLAYER = 0, ENEMY = 1, NEUTRAL = 2 }

# Action constants
const BASE_ACTIONS: int = 2
const MAX_ACTIONS: int = 4

# Bleed-out constants
const BLEED_OUT_TURNS: int = 3

func _ready() -> void:
	print("CombatManager initialized")


## Start a new combat encounter
func start_combat(grid: Node, player_units: Array, enemy_units: Array) -> void:
	if combat_active:
		push_warning("CombatManager: Combat already active")
		return

	combat_active = true
	combat_grid = grid
	all_units.clear()
	turn_order.clear()
	current_unit_index = 0

	# Add all units
	for unit in player_units:
		all_units.append(unit)
	for unit in enemy_units:
		all_units.append(unit)

	# Calculate turn order based on initiative
	_calculate_turn_order()

	print("Combat started with ", all_units.size(), " units")
	combat_started.emit()

	# Start first turn
	_start_current_turn()


## End combat
func end_combat(victory: bool) -> void:
	if not combat_active:
		return

	combat_active = false
	print("Combat ended - Victory: ", victory)
	combat_ended.emit(victory)

	# Cleanup
	all_units.clear()
	turn_order.clear()
	combat_grid = null


## Calculate turn order based on initiative (highest first)
func _calculate_turn_order() -> void:
	turn_order = all_units.filter(func(u): return u.is_alive())
	turn_order.sort_custom(func(a, b): return a.get_initiative() > b.get_initiative())


## Get the current active unit
func get_current_unit() -> Node:
	if turn_order.is_empty():
		return null
	return turn_order[current_unit_index]


## Start the current unit's turn
func _start_current_turn() -> void:
	var unit = get_current_unit()
	if unit == null:
		return

	# Process bleed-out for dying units
	if unit.is_bleeding_out:
		unit.bleed_out_turns -= 1
		unit_bleeding_out.emit(unit, unit.bleed_out_turns)

		if unit.bleed_out_turns <= 0:
			_kill_unit(unit)
			_advance_turn()
			return

		# Bleeding out units skip their turn
		_advance_turn()
		return

	# Reset actions for this turn
	unit.actions_remaining = unit.get_max_actions()

	print("Turn started: ", unit.unit_name, " (", unit.actions_remaining, " actions)")
	turn_started.emit(unit)


## End current unit's turn and advance to next
func end_turn() -> void:
	var unit = get_current_unit()
	if unit:
		turn_ended.emit(unit)

	_advance_turn()


## Advance to the next unit in turn order
func _advance_turn() -> void:
	current_unit_index += 1

	# If we've gone through all units, start new round
	if current_unit_index >= turn_order.size():
		_start_new_round()
	else:
		_start_current_turn()


## Start a new round (recalculate turn order)
func _start_new_round() -> void:
	current_unit_index = 0
	_calculate_turn_order()

	# Check win/lose conditions
	var result = _check_combat_end()
	if result != -1:
		end_combat(result == Team.PLAYER)
		return

	if not turn_order.is_empty():
		_start_current_turn()


## Check if combat should end
## Returns: Team that won, or -1 if combat continues
func _check_combat_end() -> int:
	var player_alive = false
	var enemy_alive = false

	for unit in all_units:
		if unit.is_alive():
			if unit.team == Team.PLAYER:
				player_alive = true
			elif unit.team == Team.ENEMY:
				enemy_alive = true

	if not enemy_alive:
		return Team.PLAYER  # Player victory
	if not player_alive:
		return Team.ENEMY   # Player defeat

	return -1  # Combat continues


## Use an action from the current unit
func use_action(count: int = 1) -> bool:
	var unit = get_current_unit()
	if unit == null:
		return false

	if unit.actions_remaining < count:
		return false

	unit.actions_remaining -= count
	action_used.emit(unit, unit.actions_remaining)

	# Auto-end turn if no actions left
	if unit.actions_remaining <= 0:
		end_turn()

	return true


## Check if current unit can perform an action
func can_act(action_cost: int = 1) -> bool:
	var unit = get_current_unit()
	if unit == null:
		return false
	return unit.actions_remaining >= action_cost


## Check if it's a specific team's turn
func is_player_turn() -> bool:
	var unit = get_current_unit()
	return unit != null and unit.team == Team.PLAYER


# ============================================
# MOVEMENT
# ============================================

## Get valid movement tiles for a unit
func get_movement_range(unit: Node) -> Array[Vector2i]:
	if combat_grid == null:
		return []

	var movement = unit.get_movement()
	return combat_grid.get_reachable_tiles(unit.grid_position, movement)


## Move a unit to a target position
func move_unit(unit: Node, target: Vector2i) -> bool:
	if combat_grid == null:
		return false

	if not can_act(1):
		return false

	var valid_tiles = get_movement_range(unit)
	if not target in valid_tiles:
		push_warning("CombatManager: Invalid move target")
		return false

	var from = unit.grid_position
	combat_grid.move_unit(unit, target)

	use_action(1)
	unit_moved.emit(unit, from, target)
	return true


# ============================================
# COMBAT RESOLUTION
# ============================================

## Perform an attack from one unit to another
func attack_unit(attacker: Node, defender: Node) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	# Check range (adjacent for melee, will expand for ranged later)
	var distance = _grid_distance(attacker.grid_position, defender.grid_position)
	var attack_range = attacker.get_attack_range()

	if distance > attack_range:
		return {"success": false, "reason": "Target out of range"}

	# Calculate hit chance
	var hit_chance = calculate_hit_chance(attacker, defender)
	var roll = randf() * 100.0
	var hit = roll <= hit_chance

	var result = {
		"success": true,
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"damage": 0,
		"crit": false,
		"damage_type": "physical"
	}

	if hit:
		# Calculate damage
		var damage_result = calculate_physical_damage(attacker, defender)
		result.merge(damage_result, true)

		# Apply damage
		apply_damage(defender, result.damage, result.damage_type)

	use_action(1)
	unit_attacked.emit(attacker, defender, result)
	return result


## Calculate hit chance (percentage)
func calculate_hit_chance(attacker: Node, defender: Node) -> float:
	var base_chance = 80.0
	var accuracy = attacker.get_accuracy()
	var dodge = defender.get_dodge()

	var hit_chance = base_chance + accuracy - dodge

	# TODO: Add situational modifiers (flanking, cover, etc.)

	# Clamp to 10-95%
	return clampf(hit_chance, 10.0, 95.0)


## Calculate physical damage
func calculate_physical_damage(attacker: Node, defender: Node) -> Dictionary:
	# Base damage from weapon + attribute + skill
	var base_damage = attacker.get_attack_damage()

	# Variance ±15%
	var variance = randf_range(0.85, 1.15)
	var damage = int(base_damage * variance)

	# Check for crit
	var crit_chance = attacker.get_crit_chance()
	var crit = randf() * 100.0 <= crit_chance
	var crit_multi = 1.5  # TODO: Can be increased by upgrades

	if crit:
		damage = int(damage * crit_multi)

	# Apply armor (flat reduction)
	var armor = defender.get_armor()
	if crit:
		armor = int(armor * 0.5)  # Crits ignore 50% armor

	damage = maxi(1, damage - armor)

	# Apply physical resistance (percentage)
	var phys_resist = defender.get_resistance("physical")
	damage = int(damage * (1.0 - phys_resist / 100.0))
	damage = maxi(1, damage)

	return {
		"damage": damage,
		"base_damage": base_damage,
		"crit": crit,
		"armor_reduced": armor,
		"damage_type": "physical"
	}


## Calculate elemental magic damage
func calculate_magic_damage(caster: Node, target: Node, base_spell_damage: int, element: String) -> Dictionary:
	var spellpower = caster.get_spellpower()
	var skill_bonus = caster.get_magic_skill_bonus(element)

	var base_damage = base_spell_damage + spellpower + skill_bonus

	# Variance ±15%
	var variance = randf_range(0.85, 1.15)
	var damage = int(base_damage * variance)

	# Apply elemental resistance
	var resistance = target.get_resistance(element)
	damage = int(damage * (1.0 - resistance / 100.0))
	damage = maxi(0, damage)  # Magic can be fully resisted

	return {
		"damage": damage,
		"base_damage": base_damage,
		"element": element,
		"resistance": resistance,
		"damage_type": element
	}


## Apply damage to a unit
func apply_damage(unit: Node, damage: int, damage_type: String) -> void:
	unit.take_damage(damage)
	unit_damaged.emit(unit, damage, damage_type)

	if unit.current_hp <= 0 and not unit.is_bleeding_out:
		_start_bleed_out(unit)


## Start bleed-out state for a unit
func _start_bleed_out(unit: Node) -> void:
	unit.is_bleeding_out = true
	unit.bleed_out_turns = BLEED_OUT_TURNS
	unit.current_hp = 0
	print(unit.unit_name, " is bleeding out! ", BLEED_OUT_TURNS, " turns to save them.")
	unit_bleeding_out.emit(unit, BLEED_OUT_TURNS)


## Permanently kill a unit
func _kill_unit(unit: Node) -> void:
	unit.is_dead = true
	unit.is_bleeding_out = false
	print(unit.unit_name, " has died!")
	unit_died.emit(unit)

	# Remove from turn order
	var idx = turn_order.find(unit)
	if idx != -1:
		turn_order.remove_at(idx)
		if current_unit_index > idx:
			current_unit_index -= 1


## Revive a bleeding out unit
func revive_unit(unit: Node, hp_amount: int) -> void:
	if not unit.is_bleeding_out:
		return

	unit.is_bleeding_out = false
	unit.bleed_out_turns = 0
	unit.current_hp = hp_amount
	print(unit.unit_name, " has been revived with ", hp_amount, " HP!")


# ============================================
# UTILITY
# ============================================

## Calculate grid distance (Chebyshev - diagonal = 1)
func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Get all units on a specific team
func get_team_units(team: int) -> Array[Node]:
	var result: Array[Node] = []
	for unit in all_units:
		if unit.team == team:
			result.append(unit)
	return result


## Get all alive units
func get_alive_units() -> Array[Node]:
	var result: Array[Node] = []
	for unit in all_units:
		if unit.is_alive():
			result.append(unit)
	return result


## Get unit at grid position
func get_unit_at(pos: Vector2i) -> Node:
	if combat_grid:
		return combat_grid.get_unit_at(pos)
	return null
