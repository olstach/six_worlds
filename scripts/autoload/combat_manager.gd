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
signal unit_healed(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_bleeding_out(unit: Node, turns_remaining: int)
signal action_used(unit: Node, actions_remaining: int)
signal spell_cast(caster: Node, spell: Dictionary, targets: Array, results: Array)
signal status_effect_triggered(unit: Node, effect_name: String, value: int, effect_type: String)
signal status_effect_expired(unit: Node, effect_name: String)
signal terrain_damage(unit: Node, damage: int, effect_name: String)
signal terrain_heal(unit: Node, amount: int, effect_name: String)
signal deployment_phase_started(can_manually_place: bool)
signal deployment_phase_ended()
signal unit_deployed(unit: Node, position: Vector2i)

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

# Combat role constants (for deployment positioning)
enum CombatRole { MELEE, RANGED, CASTER }

const MELEE_SKILLS: Array[String] = ["swords", "martial_arts", "axes", "unarmed", "maces", "spears", "daggers"]
const RANGED_SKILLS: Array[String] = ["ranged"]
const CASTER_SKILLS: Array[String] = ["fire_magic", "water_magic", "earth_magic", "air_magic", "space_magic",
	"sorcery", "enchantment", "summoning", "white", "black", "ritual"]

# Tactician upgrade ID for manual deployment
const TACTICIAN_UPGRADE_ID: String = "tactician"

# Deployment state
var _deployment_phase: bool = false
var _pending_deployment_units: Array[Node] = []
var _can_manually_deploy: bool = false

# Spell database
var _spell_database: Dictionary = {}
var _status_effects: Dictionary = {}

func _ready() -> void:
	_load_spell_database()
	print("CombatManager initialized with ", _spell_database.size(), " spells")


## Load spell definitions from JSON
func _load_spell_database() -> void:
	var file_path = "res://resources/data/spells.json"

	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: spells.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("CombatManager: Failed to parse spells.json")
		return

	var data = json.get_data()
	_spell_database = data.get("spells", {})
	_status_effects = data.get("status_effects", {})


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
	_deployment_phase = false
	print("Combat ended - Victory: ", victory)
	combat_ended.emit(victory)

	# Cleanup
	all_units.clear()
	turn_order.clear()
	combat_grid = null


# ============================================
# DEPLOYMENT SYSTEM
# ============================================

## Start combat with automatic unit deployment based on roles
## player_characters: Array of character data dictionaries
## enemy_units: Array of enemy unit nodes (already created)
func start_combat_with_deployment(grid: Node, player_characters: Array, enemy_units: Array) -> void:
	if combat_active:
		push_warning("CombatManager: Combat already active")
		return

	combat_active = true
	combat_grid = grid
	all_units.clear()
	turn_order.clear()
	current_unit_index = 0

	# Check if any party member has Tactician upgrade for manual placement
	_can_manually_deploy = _party_has_tactician()

	# Deploy enemy units first (they use AI-controlled random placement)
	_deploy_enemy_units(enemy_units)

	if _can_manually_deploy:
		# Enter deployment phase for manual placement
		_deployment_phase = true
		_pending_deployment_units.clear()
		# Player will manually place units via deploy_unit_at()
		deployment_phase_started.emit(true)
		combat_grid.show_deployment_zones(true, false)
		print("Deployment phase started - Tactician allows manual placement")
	else:
		# Auto-deploy player units based on roles
		_auto_deploy_player_units(player_characters)
		_finalize_combat_start()


## Auto-deploy player units based on their combat roles
func _auto_deploy_player_units(player_characters: Array) -> void:
	if combat_grid == null:
		return

	var zones = combat_grid.get_player_deployment_zones()
	var front_tiles = zones.front.duplicate()
	var back_tiles = zones.back.duplicate()

	# Sort characters by role: casters/ranged first (go to back), melee last (go to front)
	var sorted_chars = player_characters.duplicate()
	sorted_chars.sort_custom(func(a, b):
		var role_a = get_character_combat_role(a)
		var role_b = get_character_combat_role(b)
		# Casters and ranged have lower priority (placed first, in back)
		return role_a > role_b  # MELEE=0, RANGED=1, CASTER=2
	)

	for char_data in sorted_chars:
		var role = get_character_combat_role(char_data)
		var deploy_pos = Vector2i(-1, -1)

		match role:
			CombatRole.MELEE:
				# Melee goes to front, or back if front is full
				deploy_pos = _get_random_from_array(front_tiles)
				if deploy_pos == Vector2i(-1, -1):
					deploy_pos = _get_random_from_array(back_tiles)
			CombatRole.RANGED, CombatRole.CASTER:
				# Ranged/Casters go to back, or front if back is full
				deploy_pos = _get_random_from_array(back_tiles)
				if deploy_pos == Vector2i(-1, -1):
					deploy_pos = _get_random_from_array(front_tiles)

		if deploy_pos != Vector2i(-1, -1):
			var unit = _create_combat_unit(char_data, Team.PLAYER)
			combat_grid.place_unit(unit, deploy_pos)
			all_units.append(unit)
			unit_deployed.emit(unit, deploy_pos)
			print("Deployed ", char_data.name, " (", _role_name(role), ") at ", deploy_pos)


## Deploy enemy units (random placement in enemy zone)
func _deploy_enemy_units(enemy_units: Array) -> void:
	if combat_grid == null:
		return

	var zones = combat_grid.get_enemy_deployment_zones()
	var available_tiles = zones.all.duplicate()

	for unit in enemy_units:
		var deploy_pos = _get_random_from_array(available_tiles)
		if deploy_pos != Vector2i(-1, -1):
			combat_grid.place_unit(unit, deploy_pos)
			all_units.append(unit)
			unit_deployed.emit(unit, deploy_pos)
			print("Enemy deployed at ", deploy_pos)


## Manually deploy a unit at a specific position (used during Tactician deployment phase)
func deploy_unit_manually(char_data: Dictionary, grid_pos: Vector2i) -> bool:
	if not _deployment_phase:
		push_warning("Not in deployment phase")
		return false

	if combat_grid == null:
		return false

	# Check position is in player deployment zone
	if not combat_grid.is_in_player_zone(grid_pos):
		push_warning("Position not in player deployment zone")
		return false

	# Check position is not occupied
	if combat_grid.is_occupied(grid_pos):
		push_warning("Position already occupied")
		return false

	# Create and place unit
	var unit = _create_combat_unit(char_data, Team.PLAYER)
	combat_grid.place_unit(unit, grid_pos)
	all_units.append(unit)
	unit_deployed.emit(unit, grid_pos)

	print("Manually deployed ", char_data.name, " at ", grid_pos)
	return true


## End deployment phase and start combat
func end_deployment_phase() -> void:
	if not _deployment_phase:
		return

	_deployment_phase = false
	combat_grid.clear_highlights()
	deployment_phase_ended.emit()
	_finalize_combat_start()


## Finalize combat start after deployment
func _finalize_combat_start() -> void:
	# Calculate turn order based on initiative
	_calculate_turn_order()

	print("Combat started with ", all_units.size(), " units")
	combat_started.emit()

	# Start first turn
	_start_current_turn()


## Get combat role of a character based on their skills
func get_character_combat_role(char_data: Dictionary) -> int:
	var skills = char_data.get("skills", {})

	# Check for caster skills first (highest priority for back placement)
	var caster_total = 0
	for skill in CASTER_SKILLS:
		caster_total += skills.get(skill, 0)

	# Check for ranged skill
	var ranged_total = 0
	for skill in RANGED_SKILLS:
		ranged_total += skills.get(skill, 0)

	# Check for melee skills
	var melee_total = 0
	for skill in MELEE_SKILLS:
		melee_total += skills.get(skill, 0)

	# Determine primary role based on highest skill investment
	# With bias toward ranged/caster for back row placement
	if caster_total >= 3 or (caster_total > melee_total and caster_total > 0):
		return CombatRole.CASTER
	elif ranged_total >= 2 or (ranged_total > melee_total and ranged_total > 0):
		return CombatRole.RANGED
	else:
		return CombatRole.MELEE


## Check if any party member has the Tactician upgrade
func _party_has_tactician() -> bool:
	if not CharacterSystem:
		return false

	for character in CharacterSystem.get_party():
		var upgrades = character.get("upgrades", [])
		for upgrade in upgrades:
			if upgrade is Dictionary and upgrade.get("id", "") == TACTICIAN_UPGRADE_ID:
				return true
			elif upgrade is String and upgrade == TACTICIAN_UPGRADE_ID:
				return true

	return false


## Create a combat unit node from character data
func _create_combat_unit(char_data: Dictionary, team: int) -> Node:
	# For now, create a basic combat unit node
	# This will be expanded when CombatUnit scene is fully implemented
	var unit = Node2D.new()
	unit.name = char_data.get("name", "Unit")

	# Add required combat properties
	unit.set("character_data", char_data)
	unit.set("team", team)
	unit.set("grid_position", Vector2i.ZERO)
	unit.set("unit_name", char_data.get("name", "Unit"))

	# Set up HP/Mana from derived stats
	var derived = char_data.get("derived", {})
	unit.set("max_hp", derived.get("max_hp", 100))
	unit.set("current_hp", derived.get("current_hp", 100))
	unit.set("max_mana", derived.get("max_mana", 100))
	unit.set("current_mana", derived.get("current_mana", 100))
	unit.set("is_dead", false)
	unit.set("is_bleeding_out", false)
	unit.set("bleed_out_turns", 0)
	unit.set("actions_remaining", BASE_ACTIONS)

	# Add required methods as callables
	unit.set("is_alive", func(): return not unit.is_dead and not unit.is_bleeding_out)
	unit.set("get_initiative", func(): return derived.get("initiative", 10))
	unit.set("get_movement", func(): return derived.get("movement", 3))
	unit.set("get_max_actions", func(): return BASE_ACTIONS)
	unit.set("get_accuracy", func(): return derived.get("accuracy", 0))
	unit.set("get_dodge", func(): return derived.get("dodge", 10))
	unit.set("get_attack_damage", func(): return derived.get("damage", 5))
	unit.set("get_attack_range", func(): return 1)  # Default melee
	unit.set("get_armor", func(): return derived.get("armor", 0))
	unit.set("get_crit_chance", func(): return derived.get("crit_chance", 5))
	unit.set("get_spellpower", func(): return derived.get("spellpower", 10))
	unit.set("get_resistance", func(element): return 0)
	unit.set("get_magic_skill_bonus", func(element): return 0)
	unit.set("take_damage", func(amount): unit.current_hp = maxi(0, unit.current_hp - amount))
	unit.set("heal", func(amount): unit.current_hp = mini(unit.max_hp, unit.current_hp + amount))
	unit.set("is_ranged_weapon", func(): return false)  # Default melee

	# Visual representation (simple colored rect for now)
	var visual = ColorRect.new()
	visual.size = Vector2(48, 48)
	visual.position = Vector2(-24, -24)
	visual.color = Color.BLUE if team == Team.PLAYER else Color.RED
	unit.add_child(visual)

	# Add name label
	var label = Label.new()
	label.text = char_data.get("name", "?")
	label.position = Vector2(-24, 28)
	label.add_theme_font_size_override("font_size", 10)
	unit.add_child(label)

	return unit


## Helper: Get random position from array and remove it
func _get_random_from_array(arr: Array) -> Vector2i:
	if arr.is_empty():
		return Vector2i(-1, -1)
	var idx = randi() % arr.size()
	var pos = arr[idx]
	arr.remove_at(idx)
	return pos


## Helper: Get role name for debugging
func _role_name(role: int) -> String:
	match role:
		CombatRole.MELEE: return "Melee"
		CombatRole.RANGED: return "Ranged"
		CombatRole.CASTER: return "Caster"
		_: return "Unknown"


## Check if currently in deployment phase
func is_deployment_phase() -> bool:
	return _deployment_phase


## Check if manual deployment is allowed (has Tactician)
func can_manually_deploy() -> bool:
	return _can_manually_deploy


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

	# Process status effects at turn start (DoT, healing, duration tick)
	var skip_turn = _process_status_effects(unit)

	# Process terrain effects (standing in fire, poison, etc.)
	_process_terrain_effects(unit)

	# Check if unit died from status effect or terrain damage
	if unit.current_hp <= 0 and not unit.is_bleeding_out:
		_start_bleed_out(unit)
		_advance_turn()
		return

	# Skip turn if incapacitated (frozen, stunned, knocked down)
	if skip_turn:
		print(unit.unit_name, " is incapacitated and cannot act!")
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

	# Tick terrain effect durations
	if combat_grid:
		combat_grid.tick_terrain_effects()

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
## Note: Does NOT auto-end turn. Caller must check can_act() and end_turn() as needed.
func use_action(count: int = 1) -> bool:
	var unit = get_current_unit()
	if unit == null:
		return false

	if unit.actions_remaining < count:
		return false

	unit.actions_remaining -= count
	action_used.emit(unit, unit.actions_remaining)

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
	var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false

	# Add height range bonus for ranged attacks
	if is_ranged and combat_grid:
		attack_range += combat_grid.get_height_range_bonus(attacker.grid_position, defender.grid_position)

	if distance > attack_range:
		return {"success": false, "reason": "Target out of range"}

	# Check line of sight for ranged attacks
	if is_ranged and combat_grid:
		if not combat_grid.has_line_of_sight(attacker.grid_position, defender.grid_position):
			return {"success": false, "reason": "No line of sight"}

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

	# Height advantage bonus (+5 per level, -5 penalty when lower)
	if combat_grid:
		hit_chance += combat_grid.get_height_accuracy_bonus(attacker.grid_position, defender.grid_position)

	# Clamp to 10-95%
	return clampf(hit_chance, 10.0, 95.0)


## Calculate physical damage
func calculate_physical_damage(attacker: Node, defender: Node) -> Dictionary:
	# Base damage from weapon + attribute + skill
	var base_damage = attacker.get_attack_damage()

	# Height damage bonus
	var height_bonus = 0
	if combat_grid:
		var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
		height_bonus = combat_grid.get_height_damage_bonus(attacker.grid_position, defender.grid_position, is_ranged)
		base_damage += height_bonus

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
		"height_bonus": height_bonus,
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
# SPELL CASTING
# ============================================

## Get a spell by ID (normalizes data format)
func get_spell(spell_id: String) -> Dictionary:
	if spell_id in _spell_database:
		var spell = _spell_database[spell_id].duplicate(true)
		spell["id"] = spell_id

		# Normalize targeting format: spell.target.type -> spell.targeting
		if not "targeting" in spell and "target" in spell:
			var target = spell.target
			var target_type = target.get("type", "single")
			var eligible = target.get("eligible", "enemy")

			# Map to expected targeting values
			match target_type:
				"single":
					if eligible == "ally":
						spell["targeting"] = "single_ally"
					elif eligible == "corpse":
						spell["targeting"] = "single_corpse"
					else:
						spell["targeting"] = "single"
				"self":
					spell["targeting"] = "self"
				"aoe", "circle":
					spell["targeting"] = "aoe_circle"
					# AoE radius can be in target.radius or spell.aoe.base_size
					var aoe_data = spell.get("aoe", {})
					spell["aoe_radius"] = target.get("radius", aoe_data.get("base_size", 2))
				"chain":
					spell["targeting"] = "chain"
				_:
					spell["targeting"] = target_type

		# Default targeting if still missing
		if not "targeting" in spell:
			spell["targeting"] = "single"

		# Parse range from target data or default based on level
		var target_data = spell.get("target", {})
		var raw_range = target_data.get("range", spell.get("range", ""))
		if raw_range is String:
			if raw_range == "melee":
				spell["range"] = 1
			else:
				# Default range based on spell level
				var level = spell.get("level", 1)
				spell["range"] = 3 + level  # Range 4-8 based on level
		elif raw_range is int or raw_range is float:
			spell["range"] = int(raw_range)
		else:
			var level = spell.get("level", 1)
			spell["range"] = 3 + level

		return spell
	return {}


## Get all spells a unit can cast (must know spell + meet requirements)
func get_castable_spells(unit: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var skills = unit.character_data.get("skills", {})
	var known_spells = unit.character_data.get("known_spells", [])

	# If no known_spells array, unit can't cast any spells
	if known_spells.is_empty():
		return result

	# Only check spells the unit knows
	for spell_id in known_spells:
		if not spell_id in _spell_database:
			continue
		var spell = _spell_database[spell_id]
		var can_cast = _can_cast_spell(unit, spell, skills)
		if can_cast.success:
			var spell_copy = spell.duplicate(true)
			spell_copy["id"] = spell_id
			result.append(spell_copy)

	return result


## Check if a unit can cast a specific spell
func _can_cast_spell(unit: Node, spell: Dictionary, skills: Dictionary) -> Dictionary:
	# Check mana
	var mana_cost = spell.get("mana_cost", 0)
	if unit.current_mana < mana_cost:
		return {"success": false, "reason": "Not enough mana"}

	# Check skill requirements - need at least one school at required level
	var required_level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var has_skill = false

	for school in schools:
		# Lowercase school name for comparison (spells.json uses capitalized names)
		var school_lower = school.to_lower()
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space"] else school_lower
		var skill_level = skills.get(skill_name, 0)
		if skill_level >= required_level:
			has_skill = true
			break

	if not has_skill:
		return {"success": false, "reason": "Insufficient skill level"}

	return {"success": true}


## Cast a spell
func cast_spell(caster: Node, spell_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var spell = get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "Unknown spell"}

	var skills = caster.character_data.get("skills", {})
	var can_cast = _can_cast_spell(caster, spell, skills)
	if not can_cast.success:
		return can_cast

	# Check range
	var spell_range = spell.get("range", 1)
	var targeting = spell.get("targeting", "single")

	# Self-targeting spells don't need range check
	if targeting != "self":
		var distance = _spell_distance(caster.grid_position, target_pos)
		if distance > spell_range:
			return {"success": false, "reason": "Target out of range"}

	# Get targets based on targeting type
	var targets = _get_spell_targets(caster, spell, target_pos)
	if targets.is_empty() and targeting != "self":
		return {"success": false, "reason": "No valid targets"}

	# Deduct mana
	var mana_cost = spell.get("mana_cost", 0)
	caster.current_mana -= mana_cost

	# Calculate spell power bonus from all applicable schools
	var spellpower_bonus = _calculate_spell_bonus(caster, spell)

	# Apply effects to each target
	var results: Array[Dictionary] = []
	for target in targets:
		var effect_result = _apply_spell_effects(caster, target, spell, spellpower_bonus)
		results.append(effect_result)

	# Use action
	use_action(1)

	var cast_result = {
		"success": true,
		"spell": spell,
		"targets": targets,
		"results": results,
		"mana_cost": mana_cost
	}

	spell_cast.emit(caster, spell, targets, results)
	return cast_result


## Get targets for a spell based on targeting type
func _get_spell_targets(caster: Node, spell: Dictionary, target_pos: Vector2i) -> Array[Node]:
	var targets: Array[Node] = []
	var targeting = spell.get("targeting", "single")

	match targeting:
		"self":
			targets.append(caster)

		"single", "single_ally":
			var unit = get_unit_at(target_pos)
			if unit:
				if targeting == "single_ally":
					if unit.team == caster.team:
						targets.append(unit)
				else:
					targets.append(unit)

		"single_corpse":
			# For revive spells - check bleeding out units
			var unit = get_unit_at(target_pos)
			if unit and unit.is_bleeding_out:
				targets.append(unit)

		"aoe_circle":
			var radius = spell.get("aoe_radius", 1)
			var center = target_pos
			if spell.get("aoe_center", "") == "self":
				center = caster.grid_position

			for unit in all_units:
				if not unit.is_alive() and not unit.is_bleeding_out:
					continue
				var dist = _grid_distance(unit.grid_position, center)
				if dist <= radius:
					# For offensive AoE, only hit enemies (unless friendly fire enabled)
					var is_offensive = _spell_is_offensive(spell)
					if is_offensive and unit.team != caster.team:
						targets.append(unit)
					elif not is_offensive and unit.team == caster.team:
						targets.append(unit)

		"chain":
			# Start with primary target, chain to nearby enemies
			var primary = get_unit_at(target_pos)
			if primary and primary.team != caster.team:
				targets.append(primary)
				var chain_count = spell.get("chain_targets", 3) - 1
				var hit_positions: Array[Vector2i] = [target_pos]

				while chain_count > 0 and targets.size() < spell.get("chain_targets", 3):
					var last_target = targets[-1]
					var nearest: Node = null
					var nearest_dist = 999

					for unit in all_units:
						if not unit.is_alive():
							continue
						if unit.team == caster.team:
							continue
						if unit.grid_position in hit_positions:
							continue
						var dist = _grid_distance(last_target.grid_position, unit.grid_position)
						if dist <= 3 and dist < nearest_dist:  # Chain range of 3
							nearest_dist = dist
							nearest = unit

					if nearest:
						targets.append(nearest)
						hit_positions.append(nearest.grid_position)
					else:
						break
					chain_count -= 1

	return targets


## Check if spell is offensive (deals damage)
func _spell_is_offensive(spell: Dictionary) -> bool:
	var effects = spell.get("effects", [])
	for effect in effects:
		if effect.get("type") == "damage":
			return true
	return false


## Calculate total spell bonus from all applicable schools
func _calculate_spell_bonus(caster: Node, spell: Dictionary) -> int:
	var total_bonus = caster.get_spellpower()
	var skills = caster.character_data.get("skills", {})
	var schools = spell.get("schools", [])

	for school in schools:
		# Lowercase school name for comparison (spells.json uses capitalized names)
		var school_lower = school.to_lower()
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space"] else school_lower
		var skill_level = skills.get(skill_name, 0)
		total_bonus += skill_level * 2  # Each skill level adds 2 to spell power

	return total_bonus


## Apply spell effects to a target
## Reads directly from spells.json format: damage, damage_type, heal, statuses_caused
func _apply_spell_effects(caster: Node, target: Node, spell: Dictionary, bonus: int) -> Dictionary:
	var result = {
		"target": target,
		"effects_applied": []
	}

	# --- Direct damage (from spell.damage and spell.damage_type) ---
	var base_damage = spell.get("damage", null)
	if base_damage != null and (base_damage is int or base_damage is float):
		if int(base_damage) > 0:
			var element = spell.get("damage_type", "physical")
			var total_damage = int(base_damage) + bonus

			# Variance ±15%
			var variance = randf_range(0.85, 1.15)
			total_damage = int(total_damage * variance)

			# Apply resistance
			var resistance = target.get_resistance(element)
			total_damage = int(total_damage * (1.0 - resistance / 100.0))
			total_damage = maxi(1, total_damage)

			apply_damage(target, total_damage, element)
			result.effects_applied.append({"type": "damage", "amount": total_damage, "element": element})

	# --- Direct healing (from spell.heal) ---
	var base_heal = spell.get("heal", null)
	if base_heal != null and (base_heal is int or base_heal is float):
		if int(base_heal) > 0:
			var total_heal = int(base_heal) + int(bonus * 0.5)
			target.heal(total_heal)
			unit_healed.emit(target, total_heal)
			result.effects_applied.append({"type": "heal", "amount": total_heal})

	# --- Status effects (from spell.statuses_caused) ---
	var statuses = spell.get("statuses_caused", [])
	for status_name in statuses:
		var duration = 3  # Default duration
		# Use spellpower-based duration if spell says "spellpower"
		var dur_field = spell.get("duration", null)
		if dur_field is int or dur_field is float:
			duration = int(dur_field)
		elif dur_field == "spellpower":
			duration = maxi(1, 2 + int(bonus * 0.1))

		_apply_status_effect(target, status_name, duration, 0)
		result.effects_applied.append({"type": "status", "status": status_name, "applied": true})

	# --- Status removal (from spell.statuses_removed) ---
	var statuses_removed = spell.get("statuses_removed", [])
	if not statuses_removed.is_empty():
		var cleansed = _cleanse_status_effects(target, statuses_removed.size())
		result.effects_applied.append({"type": "cleanse", "removed": cleansed})

	# --- Legacy effects array support (for future hand-crafted spells) ---
	var effects = spell.get("effects", [])
	for effect in effects:
		var effect_type = effect.get("type", "")
		var effect_result = {}

		match effect_type:
			"damage":
				var element = effect.get("element", "physical")
				var base_value = effect.get("base_value", 10)
				var total_damage = base_value + bonus
				var variance = randf_range(0.85, 1.15)
				total_damage = int(total_damage * variance)
				var resistance = target.get_resistance(element)
				total_damage = int(total_damage * (1.0 - resistance / 100.0))
				total_damage = maxi(1, total_damage)
				apply_damage(target, total_damage, element)
				effect_result = {"type": "damage", "amount": total_damage, "element": element}

			"heal":
				var base_value = effect.get("base_value", 10)
				var total_heal = base_value + int(bonus * 0.5)
				target.heal(total_heal)
				unit_healed.emit(target, total_heal)
				effect_result = {"type": "heal", "amount": total_heal}

			"buff", "debuff":
				var stat = effect.get("stat", "")
				var value = effect.get("value", 0)
				var duration = effect.get("duration", 3)
				_apply_stat_modifier(target, stat, value, duration)
				effect_result = {"type": effect_type, "stat": stat, "value": value, "duration": duration}

			"status":
				var status = effect.get("status", "")
				var duration = effect.get("duration", 1)
				var chance = effect.get("chance", 100)
				if randf() * 100 <= chance:
					_apply_status_effect(target, status, duration, effect.get("value", 0))
					effect_result = {"type": "status", "status": status, "applied": true}
				else:
					effect_result = {"type": "status", "status": status, "applied": false}

			"revive":
				if target.is_bleeding_out:
					var hp_percent = effect.get("hp_percent", 1)
					var revive_hp = maxi(1, int(target.max_hp * hp_percent / 100.0))
					revive_unit(target, revive_hp)
					effect_result = {"type": "revive", "hp": revive_hp}

		if not effect_result.is_empty():
			result.effects_applied.append(effect_result)

	return result


## Apply a temporary stat modifier
func _apply_stat_modifier(unit: Node, stat: String, value: int, duration: int) -> void:
	# Store modifiers on the unit for processing each turn
	if not "stat_modifiers" in unit:
		unit.set("stat_modifiers", [])

	unit.stat_modifiers.append({
		"stat": stat,
		"value": value,
		"duration": duration
	})

	# Apply immediate effect to derived stats
	# This is simplified - full implementation would modify get_* functions
	print("%s: %s %+d for %d turns" % [unit.unit_name, stat, value, duration])


## Apply a status effect
func _apply_status_effect(unit: Node, status: String, duration: int, value: int = 0) -> void:
	if not "status_effects" in unit:
		unit.set("status_effects", [])

	unit.status_effects.append({
		"status": status,
		"duration": duration,
		"value": value
	})

	print("%s is now %s for %d turns" % [unit.unit_name, status, duration])


## Remove status effects
func _cleanse_status_effects(unit: Node, count: int) -> int:
	if not "status_effects" in unit:
		return 0

	var removed = 0
	var to_remove: Array[int] = []

	for i in range(unit.status_effects.size()):
		if removed >= count:
			break
		# Only cleanse negative effects
		var status = unit.status_effects[i].status
		if status in ["poisoned", "burning", "bleeding", "frozen", "stunned", "feared", "cursed"]:
			to_remove.append(i)
			removed += 1

	# Remove in reverse order to maintain indices
	to_remove.reverse()
	for idx in to_remove:
		unit.status_effects.remove_at(idx)

	return removed


## Process status effects at turn start
## Returns true if the unit should skip their turn (incapacitated)
func _process_status_effects(unit: Node) -> bool:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return false

	var skip_turn = false
	var effects_to_remove: Array[int] = []

	for i in range(unit.status_effects.size()):
		var effect = unit.status_effects[i]
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})

		# Process effect based on type
		if effect_def.get("damage_per_turn", 0) > 0:
			# Damage over time (burning, poisoned, bleeding)
			var damage = effect_def.damage_per_turn
			# Use value from effect if present (for variable damage)
			if effect.get("value", 0) > 0:
				damage = effect.value
			var element = effect_def.get("element", "physical")
			apply_damage(unit, damage, element)
			status_effect_triggered.emit(unit, status_name, damage, "damage")
			print("%s takes %d %s damage from %s!" % [unit.unit_name, damage, element, status_name])

		elif effect_def.get("heal_per_turn", false):
			# Healing over time (regenerating)
			var heal_amount = effect.get("value", 5)  # Default 5 if not specified
			unit.heal(heal_amount)
			unit_healed.emit(unit, heal_amount)
			status_effect_triggered.emit(unit, status_name, heal_amount, "heal")
			print("%s regenerates %d HP!" % [unit.unit_name, heal_amount])

		# Check for incapacitating effects
		if effect_def.get("blocks_actions", false):
			skip_turn = true

		# Decrement duration
		effect.duration -= 1

		# Mark for removal if expired
		if effect.duration <= 0:
			effects_to_remove.append(i)

	# Remove expired effects (in reverse order to maintain indices)
	effects_to_remove.reverse()
	for idx in effects_to_remove:
		var expired_effect = unit.status_effects[idx]
		var status_name = expired_effect.get("status", "")
		unit.status_effects.remove_at(idx)
		status_effect_expired.emit(unit, status_name)
		print("%s is no longer %s" % [unit.unit_name, status_name])

	# Also process stat modifiers (buff/debuff duration tick)
	_process_stat_modifiers(unit)

	return skip_turn


## Process stat modifier durations
func _process_stat_modifiers(unit: Node) -> void:
	if not "stat_modifiers" in unit or unit.stat_modifiers.is_empty():
		return

	var to_remove: Array[int] = []

	for i in range(unit.stat_modifiers.size()):
		var mod = unit.stat_modifiers[i]
		mod.duration -= 1

		if mod.duration <= 0:
			to_remove.append(i)
			print("%s: %s modifier expired" % [unit.unit_name, mod.stat])

	# Remove expired modifiers
	to_remove.reverse()
	for idx in to_remove:
		unit.stat_modifiers.remove_at(idx)


## Process terrain effects for a unit (fire, poison, blessed ground, etc.)
func _process_terrain_effects(unit: Node) -> void:
	if combat_grid == null:
		return

	var grid_pos = unit.grid_position
	var terrain = combat_grid.get_terrain_effect(grid_pos)

	if terrain.is_empty():
		return

	var effect = terrain.effect
	var value = terrain.value
	var effect_name = combat_grid.get_effect_name(effect)

	# Apply effect based on type
	match effect:
		CombatGrid.TerrainEffect.FIRE:
			apply_damage(unit, value, "fire")
			terrain_damage.emit(unit, value, effect_name)
			print("%s takes %d fire damage from standing in fire!" % [unit.unit_name, value])

		CombatGrid.TerrainEffect.POISON:
			apply_damage(unit, value, "physical")
			terrain_damage.emit(unit, value, effect_name)
			print("%s takes %d poison damage from toxic ground!" % [unit.unit_name, value])

		CombatGrid.TerrainEffect.ACID:
			apply_damage(unit, value, "physical")
			terrain_damage.emit(unit, value, effect_name)
			print("%s takes %d acid damage!" % [unit.unit_name, value])

		CombatGrid.TerrainEffect.CURSED:
			apply_damage(unit, value, "black")
			terrain_damage.emit(unit, value, effect_name)
			print("%s takes %d damage from cursed ground!" % [unit.unit_name, value])

		CombatGrid.TerrainEffect.BLESSED:
			unit.heal(value)
			unit_healed.emit(unit, value)
			terrain_heal.emit(unit, value, effect_name)
			print("%s heals %d HP from blessed ground!" % [unit.unit_name, value])

		CombatGrid.TerrainEffect.ICE:
			# Ice doesn't deal damage but could apply slowed effect
			# For now just print a message
			print("%s is on icy ground (movement slowed)" % unit.unit_name)


## Check if unit is currently incapacitated by status effects
func is_unit_incapacitated(unit: Node) -> bool:
	if not "status_effects" in unit:
		return false

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if effect_def.get("blocks_actions", false):
			return true

	return false


## Check if unit can move (not blocked by effects)
func can_unit_move(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if effect_def.get("blocks_movement", false):
			return false

	return true


## Get valid target positions for a spell
func get_spell_targets(caster: Node, spell_id: String) -> Array[Vector2i]:
	var spell = get_spell(spell_id)
	if spell.is_empty():
		return []

	var valid_positions: Array[Vector2i] = []
	var targeting = spell.get("targeting", "single")
	var spell_range = spell.get("range", 1)

	match targeting:
		"self":
			valid_positions.append(caster.grid_position)

		"single":
			# Any enemy in range (Manhattan/diamond for spells)
			for unit in all_units:
				if not unit.is_alive():
					continue
				if unit.team == caster.team:
					continue
				var dist = _spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"single_ally":
			# Any ally in range
			for unit in all_units:
				if not unit.is_alive():
					continue
				if unit.team != caster.team:
					continue
				var dist = _spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"single_corpse":
			# Bleeding out allies
			for unit in all_units:
				if not unit.is_bleeding_out:
					continue
				if unit.team != caster.team:
					continue
				var dist = _spell_distance(caster.grid_position, unit.grid_position)
				if dist <= spell_range:
					valid_positions.append(unit.grid_position)

		"aoe_circle", "chain":
			# Any position in range (for AoE center selection)
			if combat_grid:
				for x in range(combat_grid.grid_size.x):
					for y in range(combat_grid.grid_size.y):
						var pos = Vector2i(x, y)
						var dist = _spell_distance(caster.grid_position, pos)
						if dist <= spell_range:
							valid_positions.append(pos)

	return valid_positions


# ============================================
# UTILITY
# ============================================

## Calculate grid distance (Chebyshev - diagonal = 1)
func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Manhattan distance (diamond shape — used for spell ranges)
func _spell_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


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
