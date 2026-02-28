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
signal item_used_in_combat(user: Node, item: Dictionary, result: Dictionary)
signal active_skill_used(user: Node, skill_data: Dictionary, result: Dictionary)

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

# Loot drop constants
# Maps enemy role -> item types that can drop from that role
const ROLE_LOOT_POOLS: Dictionary = {
	"frontline": ["sword", "axe", "mace", "spear", "shield", "armor", "helmet", "gauntlets", "greaves", "boots", "pants"],
	"ranged": ["bow", "thrown", "dagger", "armor", "boots", "gloves", "ring", "hat"],
	"caster": ["staff", "robe", "hat", "ring", "amulet", "trinket", "charm", "scroll"],
	"support": ["staff", "robe", "ring", "amulet", "trinket", "potion", "scroll", "charm"],
}
# Any enemy has a 30% chance to also drop a consumable
const GLOBAL_CONSUMABLE_TYPES: Array[String] = ["potion", "bomb", "oil"]
const GLOBAL_CONSUMABLE_CHANCE: float = 0.30
# Base rarity weights (higher = more likely to drop)
const RARITY_DROP_WEIGHTS: Dictionary = {
	"common": 100, "uncommon": 50, "rare": 20, "epic": 5, "legendary": 1
}
const MAX_RANDOM_DROPS: int = 5

# Damage type → terrain effect mapping (only elements that leave ground effects)
const DAMAGE_TYPE_TO_TERRAIN_EFFECT: Dictionary = {
	"fire": 1,        # TerrainEffect.FIRE
	"ice": 2,         # TerrainEffect.ICE
	"cold": 2,        # TerrainEffect.ICE
	"poison": 3,      # TerrainEffect.POISON
	"acid": 4,        # TerrainEffect.ACID
	"white": 5,       # TerrainEffect.BLESSED
	"holy": 5,        # TerrainEffect.BLESSED
	"black": 6,       # TerrainEffect.CURSED
}

# Deployment state
var _deployment_phase: bool = false
var _pending_deployment_units: Array[Node] = []
var _can_manually_deploy: bool = false

# Spell database
var _spell_database: Dictionary = {}
var _status_effects: Dictionary = {}

# Combat rewards (filled before combat_ended signal, cleared on next combat start)
var last_combat_rewards: Dictionary = {}

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
	last_combat_rewards = {}

	# Add all units
	for unit in player_units:
		all_units.append(unit)
	for unit in enemy_units:
		all_units.append(unit)

	# Calculate turn order based on initiative
	_calculate_turn_order()

	combat_started.emit()

	# Start first turn
	_start_current_turn()


## End combat
func end_combat(victory: bool) -> void:
	if not combat_active:
		return

	# Calculate rewards BEFORE clearing units (need enemy data)
	if victory:
		last_combat_rewards = _calculate_combat_rewards()
	else:
		last_combat_rewards = {}

	combat_active = false
	_deployment_phase = false
	combat_ended.emit(victory)

	# Cleanup
	all_units.clear()
	turn_order.clear()
	combat_grid = null


# ============================================
# COMBAT REWARDS
# ============================================

## Calculate XP, gold, and item rewards based on enemy difficulty vs party strength.
## Must be called while all_units is still populated.
func _calculate_combat_rewards() -> Dictionary:
	# Count enemies and calculate their total power
	var enemy_count := 0
	var enemy_power_total := 0.0
	for unit in all_units:
		if unit.team == Team.ENEMY:
			enemy_count += 1
			enemy_power_total += _calculate_unit_power(unit)

	# Calculate party power from CharacterSystem
	var party_power := 0.0
	var party_size := 0
	for unit in all_units:
		if unit.team == Team.PLAYER:
			party_size += 1
			party_power += _calculate_unit_power(unit)

	# Difficulty ratio: how tough were the enemies relative to the party?
	var ratio := 1.0
	if party_power > 0:
		ratio = enemy_power_total / party_power

	# --- XP REWARD ---
	# Base: 2 XP per enemy, scaled by difficulty ratio
	# Clamped so trivial fights still give something, hard fights give more
	var base_xp := enemy_count * 2
	var xp_reward := maxi(1, int(base_xp * clampf(ratio, 0.5, 3.0)))

	# --- GOLD REWARD ---
	# Base: 5 + 3 per enemy, scaled by difficulty
	var base_gold := 5 + enemy_count * 3
	var gold_reward := maxi(1, int(base_gold * clampf(ratio, 0.5, 2.0)))

	# Trade skill bonus: best Trade in party adds 10% per level
	var best_trade := 0
	for member in CharacterSystem.get_party():
		var trade_level = member.get("skills", {}).get("trade", 0)
		if trade_level > best_trade:
			best_trade = trade_level
	if best_trade > 0:
		gold_reward = int(gold_reward * (1.0 + best_trade * 0.1))

	# --- LUCK JACKPOT ---
	# Slim chance for a big gold bonus. Luck makes it slightly more likely
	# but the multiplier is always large - unreliable but consequential.
	var best_luck := 10
	for member in CharacterSystem.get_party():
		var luck = member.get("attributes", {}).get("luck", 10)
		if luck > best_luck:
			best_luck = luck

	var jackpot_triggered := false
	var jackpot_amount := 0
	# Base 3% chance, +0.5% per Luck above 10 (capped at 10%)
	var jackpot_chance := clampf(0.03 + (best_luck - 10) * 0.005, 0.03, 0.10)
	if randf() < jackpot_chance:
		jackpot_triggered = true
		# Jackpot: 3x to 5x the normal gold
		jackpot_amount = gold_reward * randi_range(3, 5)
		gold_reward += jackpot_amount

	# --- ITEM DROPS ---
	var item_drops: Array[String] = _generate_loot_drops(enemy_count, ratio, best_luck)

	var rewards := {
		"xp": xp_reward,
		"gold": gold_reward,
		"items": item_drops,
		"enemy_count": enemy_count,
		"difficulty_ratio": ratio,
		"jackpot_triggered": jackpot_triggered,
		"jackpot_amount": jackpot_amount,
		"trade_bonus": best_trade
	}

	return rewards


## Calculate a unit's power level from its attributes and skills.
## Uses the same logic for both players and enemies so the ratio is fair.
func _calculate_unit_power(unit: Node) -> float:
	var power := 0.0
	var data = unit.character_data

	# Attribute contribution: each point above 10
	var attrs = data.get("attributes", {})
	for attr_name in attrs:
		power += float(maxi(attrs[attr_name] - 10, 0))

	# Skill contribution: each skill level * 5 (weighted to matter)
	var skills = data.get("skills", {})
	for skill_name in skills:
		power += float(skills[skill_name]) * 5.0

	return power


## Generate loot drops based on enemy roles, difficulty, and party skills.
## Returns an array of item_id strings.
func _generate_loot_drops(enemy_count: int, difficulty_ratio: float, best_luck: int) -> Array[String]:
	var drops: Array[String] = []

	# Collect enemy roles and boss archetype IDs
	var enemy_roles: Array[String] = []
	var boss_archetype_ids: Array[String] = []
	for unit in all_units:
		if unit.team != Team.ENEMY:
			continue
		var arch_id = unit.character_data.get("archetype_id", "")
		var archetype = EnemySystem.archetypes.get(arch_id, {})
		var roles = archetype.get("roles", [])
		for role in roles:
			if role == "boss":
				boss_archetype_ids.append(arch_id)
			else:
				enemy_roles.append(role)

	# --- Drop count ---
	# Base: ceil(enemy_count / 2), minimum 1
	var drop_count: int = maxi(1, ceili(enemy_count / 2.0))
	# +1 for hard fights
	if difficulty_ratio >= 1.3:
		drop_count += 1
	# Guile bonus: best Guile in party
	var best_guile := 0
	for member in CharacterSystem.get_party():
		var guile_level = member.get("skills", {}).get("guile", 0)
		if guile_level > best_guile:
			best_guile = guile_level
	if best_guile >= 5:
		drop_count += 2
	elif best_guile >= 3:
		drop_count += 1
	# Bosses add +1 each
	drop_count += boss_archetype_ids.size()
	# Cap random drops (boss guaranteed drops added on top)
	drop_count = mini(drop_count, MAX_RANDOM_DROPS)

	# Build modified rarity weights for this fight
	var rarity_weights = _get_modified_rarity_weights(difficulty_ratio, best_luck)

	# --- Generate random role-based drops ---
	for i in range(drop_count):
		# Pick a role from the enemies we fought (cycle through if needed)
		var role: String
		if not enemy_roles.is_empty():
			role = enemy_roles[i % enemy_roles.size()]
		else:
			# Fallback if only bosses (use frontline pool)
			role = "frontline"

		var allowed_types: Array[String] = []
		var pool = ROLE_LOOT_POOLS.get(role, [])
		for t in pool:
			allowed_types.append(t)

		# 30% chance to add a global consumable instead
		if randf() < GLOBAL_CONSUMABLE_CHANCE:
			allowed_types = GLOBAL_CONSUMABLE_TYPES.duplicate()

		var item_id = _pick_item_from_types(allowed_types, rarity_weights)
		if item_id != "":
			drops.append(item_id)

	# --- Boss guaranteed drops ---
	for arch_id in boss_archetype_ids:
		var archetype = EnemySystem.archetypes.get(arch_id, {})
		var guaranteed = archetype.get("guaranteed_drops", [])
		for item_id in guaranteed:
			if ItemSystem.item_exists(item_id) and not item_id in drops:
				drops.append(item_id)

	return drops


## Adjust rarity weights based on difficulty ratio and Luck.
## Higher difficulty shifts weight toward uncommon+.
## Luck above 10 shifts weight toward rare+.
func _get_modified_rarity_weights(difficulty_ratio: float, luck: int) -> Dictionary:
	var weights = RARITY_DROP_WEIGHTS.duplicate()

	# Difficulty bonus: each 0.1 above 1.0 adds 10% to uncommon+ weights
	var diff_bonus = maxf(0.0, difficulty_ratio - 1.0) * 10.0
	if diff_bonus > 0:
		weights["uncommon"] = int(weights["uncommon"] * (1.0 + diff_bonus * 0.10))
		weights["rare"] = int(weights["rare"] * (1.0 + diff_bonus * 0.15))
		weights["epic"] = int(weights["epic"] * (1.0 + diff_bonus * 0.20))
		weights["legendary"] = int(weights["legendary"] * (1.0 + diff_bonus * 0.25))

	# Luck bonus: each point above 10 boosts rare+ weights
	var luck_bonus = maxi(0, luck - 10)
	if luck_bonus > 0:
		weights["rare"] = int(weights["rare"] * (1.0 + luck_bonus * 0.08))
		weights["epic"] = int(weights["epic"] * (1.0 + luck_bonus * 0.12))
		weights["legendary"] = int(weights["legendary"] * (1.0 + luck_bonus * 0.15))

	return weights


## Roll a rarity tier then pick a random item of that rarity from the allowed types.
## Falls back to lower rarities if no items exist at the rolled tier.
func _pick_item_from_types(allowed_types: Array[String], rarity_weights: Dictionary) -> String:
	# Build weighted rarity list in descending order of quality
	var rarity_order: Array[String] = ["legendary", "epic", "rare", "uncommon", "common"]
	var total_weight := 0
	for rarity in rarity_order:
		total_weight += rarity_weights.get(rarity, 0)

	if total_weight <= 0:
		return ""

	# Roll for rarity
	var roll = randi() % total_weight
	var rolled_rarity := "common"
	var cumulative := 0
	for rarity in rarity_order:
		cumulative += rarity_weights.get(rarity, 0)
		if roll < cumulative:
			rolled_rarity = rarity
			break

	# Try to find an item at the rolled rarity, fall back to lower
	var rarity_idx = rarity_order.find(rolled_rarity)
	for check_idx in range(rarity_idx, rarity_order.size()):
		var check_rarity = rarity_order[check_idx]
		var candidates: Array[String] = []

		for item_type in allowed_types:
			var items = ItemSystem.get_items_by_type(item_type)
			for item in items:
				if item.get("rarity", "") == check_rarity:
					candidates.append(item.get("id", ""))

		if not candidates.is_empty():
			return candidates[randi() % candidates.size()]

	return ""


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
	visual.size = Vector2(38, 38)
	visual.position = Vector2(-19, -19)
	visual.color = Color.BLUE if team == Team.PLAYER else Color.RED
	unit.add_child(visual)

	# Add name label
	var label = Label.new()
	label.text = char_data.get("name", "?")
	label.position = Vector2(-19, 22)
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
	if turn_order.is_empty() or current_unit_index >= turn_order.size():
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
		_advance_turn()
		return

	# Reset actions for this turn
	unit.actions_remaining = unit.get_max_actions()

	# Restore stamina each turn (base 5 + Finesse/5, so characters recover ~7-12/turn)
	var finesse = unit.character_data.get("attributes", {}).get("finesse", 10)
	var stamina_regen = 5 + int(finesse / 5)
	unit.restore_stamina(stamina_regen)

	# Tick skill cooldowns
	unit.tick_cooldowns()

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

	# Safety: clamp index if it went negative (e.g., unit died and was removed)
	if current_unit_index < 0:
		current_unit_index = 0

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


## Check combat end after damage/death — triggers immediately via call_deferred
## so that the current action finishes logging before the end screen appears
func _check_immediate_combat_end() -> void:
	if not combat_active:
		return
	var result = _check_combat_end()
	if result != -1:
		end_combat.call_deferred(result == Team.PLAYER)


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
	var movement_mode = unit.get_movement_mode() if unit.has_method("get_movement_mode") else CombatGrid.MovementMode.NORMAL
	return combat_grid.get_reachable_tiles(unit.grid_position, movement, movement_mode)


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

	# Get weapon damage type (slashing, crushing, piercing)
	var weapon_dmg_type = attacker.get_weapon_damage_type() if attacker.has_method("get_weapon_damage_type") else "crushing"

	var result = {
		"success": true,
		"hit": hit,
		"hit_chance": hit_chance,
		"roll": roll,
		"damage": 0,
		"crit": false,
		"damage_type": weapon_dmg_type,
		"cover": _last_cover_result
	}

	if hit:
		# Calculate damage
		var damage_result = calculate_physical_damage(attacker, defender, weapon_dmg_type)
		result.merge(damage_result, true)

		# Apply damage
		apply_damage(defender, result.damage, result.damage_type)

		# Apply weapon oil effects (bonus damage + status procs)
		if attacker.has_method("consume_oil_charge"):
			var oil = attacker.consume_oil_charge()
			if not oil.is_empty():
				var oil_dmg = oil.get("bonus_damage", 0)
				var oil_dmg_type = oil.get("bonus_damage_type", "fire")
				if oil_dmg > 0:
					var resist = defender.get_resistance(oil_dmg_type)
					var final_oil_dmg = int(oil_dmg * (1.0 - resist / 100.0))
					final_oil_dmg = maxi(1, final_oil_dmg)
					apply_damage(defender, final_oil_dmg, oil_dmg_type)
					result["oil_damage"] = final_oil_dmg
					result["oil_damage_type"] = oil_dmg_type
				# Roll for status proc
				var oil_status = oil.get("status", "")
				var oil_chance = oil.get("status_chance", 0)
				if oil_status != "" and oil_chance > 0:
					if randf() * 100.0 <= oil_chance:
						var oil_duration = oil.get("status_duration", 2)
						_apply_status_effect(defender, oil_status, oil_duration)
						result["oil_status"] = oil_status
				# Track remaining charges (unit's weapon_oil already decremented)
				var remaining = attacker.weapon_oil.get("attacks_remaining", 0) if not attacker.weapon_oil.is_empty() else 0
				result["oil_attacks_left"] = remaining

	use_action(1)
	unit_attacked.emit(attacker, defender, result)
	return result


## Calculate hit chance (percentage)
## Returns the hit chance and stores cover info in _last_cover_result for logging
var _last_cover_result: Dictionary = {}

func calculate_hit_chance(attacker: Node, defender: Node) -> float:
	var base_chance = 80.0
	var accuracy = attacker.get_accuracy()
	var dodge = defender.get_dodge()

	var hit_chance = base_chance + accuracy - dodge

	# Height advantage bonus (+5 per level, -5 penalty when lower)
	if combat_grid:
		hit_chance += combat_grid.get_height_accuracy_bonus(attacker.grid_position, defender.grid_position)

	# Cover penalty for ranged attacks — obstacles between attacker and defender
	_last_cover_result = {}
	var is_ranged = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
	if is_ranged and combat_grid:
		var cover = combat_grid.get_cover_bonus(attacker.grid_position, defender.grid_position)
		if cover.has_cover:
			hit_chance -= cover.dodge_bonus
			_last_cover_result = cover

	# Clamp to 10-95%
	return clampf(hit_chance, 10.0, 95.0)


## Calculate physical damage (slashing, crushing, or piercing)
func calculate_physical_damage(attacker: Node, defender: Node, dmg_type: String = "crushing") -> Dictionary:
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

	# Check for crit (include weapon oil crit bonus if active)
	var crit_chance = attacker.get_crit_chance()
	if not attacker.weapon_oil.is_empty():
		crit_chance += attacker.weapon_oil.get("crit_bonus", 0)
	var crit = randf() * 100.0 <= crit_chance
	var crit_multi = 1.5  # TODO: Can be increased by upgrades

	if crit:
		damage = int(damage * crit_multi)

	# Apply armor (flat reduction)
	var armor = defender.get_armor()
	if crit:
		armor = int(armor * 0.5)  # Crits ignore 50% armor

	damage = maxi(1, damage - armor)

	# Apply physical resistance (checks specific subtype first, then falls back to generic "physical")
	var phys_resist = defender.get_resistance(dmg_type)
	damage = int(damage * (1.0 - phys_resist / 100.0))
	damage = maxi(1, damage)

	return {
		"damage": damage,
		"base_damage": base_damage,
		"crit": crit,
		"armor_reduced": armor,
		"height_bonus": height_bonus,
		"damage_type": dmg_type
	}


## Calculate elemental magic damage
func calculate_magic_damage(caster: Node, target: Node, base_spell_damage: int, element: String) -> Dictionary:
	var spellpower = caster.get_spellpower()
	var skill_bonus = caster.get_magic_skill_bonus(element)

	# Spellpower contributes at half value — prevents it dominating over spell base damage.
	# Formula: spell_base + (spellpower / 2) + skill_bonus
	# Example: Firebolt(15) + spellpower 10 → 15+5+10=30, not 15+10+10=35
	var base_damage = base_spell_damage + (spellpower / 2) + skill_bonus

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
		# Check if combat should end immediately (all enemies or all players down)
		_check_immediate_combat_end()


## Start bleed-out state for a unit
func _start_bleed_out(unit: Node) -> void:
	unit.is_bleeding_out = true
	unit.bleed_out_turns = BLEED_OUT_TURNS
	unit.current_hp = 0
	unit_bleeding_out.emit(unit, BLEED_OUT_TURNS)


## Permanently kill a unit
func _kill_unit(unit: Node) -> void:
	unit.is_dead = true
	unit.is_bleeding_out = false
	unit_died.emit(unit)

	# Remove from turn order and fix the current index
	var idx = turn_order.find(unit)
	if idx != -1:
		turn_order.remove_at(idx)
		# Use >= so that when the current unit dies, the index adjusts correctly:
		# after removal, the next unit slides into idx, and _advance_turn will
		# increment from (idx-1) back to idx, landing on the right unit.
		if current_unit_index >= idx:
			current_unit_index -= 1

	# Check if combat should end immediately
	_check_immediate_combat_end()


## Revive a bleeding out unit
func revive_unit(unit: Node, hp_amount: int) -> void:
	if not unit.is_bleeding_out:
		return

	unit.is_bleeding_out = false
	unit.bleed_out_turns = 0
	unit.current_hp = hp_amount


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
	# Check mana (account for charm reduction if the unit has a matching one)
	var mana_cost = spell.get("mana_cost", 0)
	if unit.has_method("consume_charm") and not unit.charm_buff.is_empty():
		var buff_school = unit.charm_buff.get("school", "")
		var spell_schools = spell.get("schools", [])
		var subschool = spell.get("subschool", "")
		for school in spell_schools:
			if school.to_lower() == buff_school:
				mana_cost = int(mana_cost * (1.0 - unit.charm_buff.get("mana_reduction", 0.0)))
				break
		if subschool.to_lower() == buff_school:
			mana_cost = int(mana_cost * (1.0 - unit.charm_buff.get("mana_reduction", 0.0)))
	if unit.current_mana < mana_cost:
		return {"success": false, "reason": "Not enough mana"}

	# Check skill requirements - need at least one school at required level
	var required_level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var has_skill = false

	for school in schools:
		# Lowercase school name for comparison (spells.json uses capitalized names)
		var school_lower = school.to_lower()
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
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

	# Calculate base mana cost
	var mana_cost = spell.get("mana_cost", 0)

	# Check for charm buff (reduces mana cost and may boost spellpower)
	var charm_used: Dictionary = {}
	if caster.has_method("consume_charm"):
		var spell_schools = spell.get("schools", [])
		# Also check subschool
		var subschool = spell.get("subschool", "")
		if subschool != "":
			spell_schools = spell_schools + [subschool]
		charm_used = caster.consume_charm(spell_schools)
		if not charm_used.is_empty():
			var reduction = charm_used.get("mana_reduction", 0.0)
			mana_cost = int(mana_cost * (1.0 - reduction))

	# Deduct mana
	caster.current_mana -= mana_cost

	# Calculate spell power bonus from all applicable schools
	var spellpower_bonus = _calculate_spell_bonus(caster, spell)

	# Add charm spellpower bonus (percentage of base spellpower)
	if not charm_used.is_empty():
		var charm_sp_pct = charm_used.get("spellpower_bonus", 0.0)
		if charm_sp_pct > 0:
			spellpower_bonus += int(spellpower_bonus * charm_sp_pct)

	# Apply effects to each target
	var results: Array[Dictionary] = []
	for target in targets:
		var effect_result = _apply_spell_effects(caster, target, spell, spellpower_bonus)
		results.append(effect_result)

	# Create ground effects for AoE spells that deal elemental damage
	if targeting == "aoe_circle":
		var spell_damage_type = spell.get("damage_type", "")
		if spell_damage_type != "":
			var aoe_radius = spell.get("aoe_radius", 1)
			_create_ground_effects_from_damage(target_pos, aoe_radius, spell_damage_type, 2)

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
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
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

	unit.get("stat_modifiers").append({
		"stat": stat,
		"value": value,
		"duration": duration
	})

	# Apply immediate effect to derived stats
	# This is simplified - full implementation would modify get_* functions


## Apply a status effect
func _apply_status_effect(unit: Node, status: String, duration: int, value: int = 0) -> void:
	if not "status_effects" in unit:
		unit.set("status_effects", [])

	unit.get("status_effects").append({
		"status": status,
		"duration": duration,
		"value": value
	})


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

		elif effect_def.get("heal_per_turn", false):
			# Healing over time (regenerating)
			var heal_amount = effect.get("value", 5)  # Default 5 if not specified
			unit.heal(heal_amount)
			unit_healed.emit(unit, heal_amount)
			status_effect_triggered.emit(unit, status_name, heal_amount, "heal")

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

	# Remove expired modifiers
	to_remove.reverse()
	for idx in to_remove:
		unit.stat_modifiers.remove_at(idx)


## Process terrain effects for a unit (fire, poison, blessed ground, etc.)
## Flying units are completely immune. Levitating units are immune to damaging effects
## but still benefit from blessed ground.
func _process_terrain_effects(unit: Node) -> void:
	if combat_grid == null:
		return

	# Check movement mode for terrain immunity
	var movement_mode = unit.get_movement_mode() if unit.has_method("get_movement_mode") else CombatGrid.MovementMode.NORMAL
	if movement_mode == CombatGrid.MovementMode.FLYING:
		return  # Flying units are fully immune to all ground effects

	var grid_pos = unit.grid_position
	var terrain = combat_grid.get_terrain_effect(grid_pos)

	if terrain.is_empty():
		return

	var effect = terrain.effect
	var value = terrain.value
	var effect_name = combat_grid.get_effect_name(effect)

	# Levitating units are immune to damaging ground effects (still get blessed)
	if movement_mode == CombatGrid.MovementMode.LEVITATE:
		if effect != CombatGrid.TerrainEffect.BLESSED:
			return

	# Apply effect based on type
	match effect:
		CombatGrid.TerrainEffect.FIRE:
			apply_damage(unit, value, "fire")
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.POISON:
			apply_damage(unit, value, "physical")
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.ACID:
			apply_damage(unit, value, "physical")
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.CURSED:
			apply_damage(unit, value, "black")
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.BLESSED:
			unit.heal(value)
			unit_healed.emit(unit, value)
			terrain_heal.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.ICE:
			# Ice doesn't deal damage but could apply slowed effect
			pass


## Create ground effects on tiles from AoE damage (fire leaves fire, ice leaves ice, etc.)
## Also damages obstacles caught in the area
func _create_ground_effects_from_damage(center: Vector2i, radius: int, damage_type: String, duration: int = 2) -> void:
	if combat_grid == null:
		return

	var tiles_in_area = combat_grid.get_tiles_in_radius(center, radius)

	# Damage obstacles in the area (AoE hits everything)
	for pos in tiles_in_area:
		var tile = combat_grid.tiles.get(pos)
		if tile != null and tile.obstacle != CombatGrid.ObstacleType.NONE and tile.obstacle_hp > 0:
			# AoE deals roughly 10 damage to obstacles
			combat_grid.damage_obstacle(pos, 10, damage_type)

	var effect_type = DAMAGE_TYPE_TO_TERRAIN_EFFECT.get(damage_type, -1)
	if effect_type < 0:
		return  # No ground effect for this damage type (physical, air, space, etc.)

	for pos in tiles_in_area:
		var tile = combat_grid.tiles.get(pos)
		if tile != null and tile.walkable:
			combat_grid.add_terrain_effect(pos, effect_type, duration)


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
# CONSUMABLE ITEMS
# ============================================

## Use a consumable item in combat
## Self-targeting: potions, charms, oils (target_pos ignored)
## Targeted: scrolls, bombs (target_pos = aim position)
func use_combat_item(user: Node, item_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found"}

	if ItemSystem.get_inventory_count(item_id) <= 0:
		return {"success": false, "reason": "None in inventory"}

	var item_type = item.get("type", "")

	# Pre-validate targeting BEFORE consuming the item
	if item_type == "scroll":
		var spell_id = item.get("spell_id", "")
		var spell = get_spell(spell_id)
		if spell.is_empty():
			return {"success": false, "reason": "Unknown spell on scroll"}
		var targeting = spell.get("targeting", "single")
		if targeting != "self":
			var spell_range = spell.get("range", 1)
			var distance = _spell_distance(user.grid_position, target_pos)
			if distance > spell_range:
				return {"success": false, "reason": "Target out of range"}
			var targets = _get_spell_targets(user, spell, target_pos)
			if targets.is_empty():
				return {"success": false, "reason": "No valid targets"}
	elif item_type == "bomb":
		var effect = item.get("effect", {})
		var bomb_range = effect.get("range", 4)
		var distance = _spell_distance(user.grid_position, target_pos)
		if distance > bomb_range:
			return {"success": false, "reason": "Target out of range"}

	# Consume the item from inventory
	var consume_result = ItemSystem.use_consumable(item_id)
	if not consume_result.success:
		return consume_result

	# Apply the effect based on item type
	var result: Dictionary = {}
	match item_type:
		"potion":
			result = _apply_potion_effect(user, item)
		"scroll":
			result = _use_scroll(user, item, target_pos)
		"charm":
			result = _apply_charm(user, item)
		"bomb":
			result = _use_bomb(user, item, target_pos)
		"oil":
			result = _apply_oil(user, item)
		_:
			return {"success": false, "reason": "Unknown consumable type: " + item_type}

	if result.get("success", false):
		use_action(1)
		item_used_in_combat.emit(user, item, result)

	return result


## Apply potion effects to the user (always self-targeted)
func _apply_potion_effect(user: Node, item: Dictionary) -> Dictionary:
	var effect = item.get("effect", {})
	var effect_type = effect.get("type", "")
	var result = {"success": true, "effects_applied": []}

	# Alchemy skill bonus: increases potion effectiveness
	var alchemy_bonus = _get_alchemy_bonus(user)

	match effect_type:
		"heal":
			var base_value = effect.get("value", 0)
			var heal_amount = int(base_value * (1.0 + alchemy_bonus / 100.0))
			user.heal(heal_amount)
			unit_healed.emit(user, heal_amount)
			result.effects_applied.append({"type": "heal", "amount": heal_amount})

		"restore_mana":
			var base_value = effect.get("value", 0)
			var mana_amount = int(base_value * (1.0 + alchemy_bonus / 100.0))
			user.current_mana = mini(user.max_mana, user.current_mana + mana_amount)
			result.effects_applied.append({"type": "restore_mana", "amount": mana_amount})

		"buff":
			var value = effect.get("value", 0)
			var duration = effect.get("duration", 3)
			# Check if it's a resistance buff
			var resistance_type = effect.get("resistance", "")
			if resistance_type != "":
				# Apply as a status effect with resistance boost
				var status_name = effect.get("status", "Buffed")
				_apply_status_effect(user, status_name, duration, value)
				result.effects_applied.append({
					"type": "buff", "status": status_name,
					"resistance": resistance_type, "value": value, "duration": duration
				})
			else:
				var stat = effect.get("stat", "")
				_apply_stat_modifier(user, stat, value, duration)
				result.effects_applied.append({
					"type": "buff", "stat": stat, "value": value, "duration": duration
				})

		"cleanse":
			var statuses_to_remove = effect.get("statuses_removed", [])
			var removed_count = 0
			for i in range(user.status_effects.size() - 1, -1, -1):
				var se = user.status_effects[i]
				if se.get("status", "") in statuses_to_remove:
					var removed_name = se.get("status", "")
					user.status_effects.remove_at(i)
					status_effect_expired.emit(user, removed_name)
					removed_count += 1
			result.effects_applied.append({"type": "cleanse", "removed": removed_count})

		_:
			result.success = false
			result["reason"] = "Unknown potion effect: " + effect_type

	return result


## Use a scroll: cast the referenced spell without mana cost or skill requirement
func _use_scroll(user: Node, item: Dictionary, target_pos: Vector2i) -> Dictionary:
	var spell_id = item.get("spell_id", "")
	var spell = get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "Unknown spell on scroll: " + spell_id}

	# Get targets using existing targeting logic
	var targets = _get_spell_targets(user, spell, target_pos)

	# Self-targeting spells target the caster
	if spell.get("targeting", "single") == "self" and targets.is_empty():
		targets.append(user)

	# Baseline scroll power: equivalent to Focus 16 + max(5, spell level) per school
	# This makes scrolls useful regardless of who casts them
	var baseline_spellpower := 16
	var spell_schools: Array = spell.get("schools", [])
	var baseline_school_bonus := 0
	for school in spell_schools:
		var school_lower: String = str(school).to_lower()
		var skill_name: String = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
		var min_skill_level := maxi(5, spell.get("level", 1))
		baseline_school_bonus += min_skill_level * 2
	var scroll_bonus = baseline_spellpower + baseline_school_bonus + item.get("spell_bonus", 0)

	# Apply effects using existing spell effect system
	var results: Array[Dictionary] = []
	for target in targets:
		var effect_result = _apply_spell_effects(user, target, spell, scroll_bonus)
		results.append(effect_result)

	return {
		"success": true,
		"spell": spell,
		"targets": targets,
		"results": results,
		"is_scroll": true
	}


## Get valid target positions for a scroll item (wraps spell targeting)
func get_scroll_targets(user: Node, item_id: String) -> Array[Vector2i]:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "scroll":
		return []
	var spell_id = item.get("spell_id", "")
	return get_spell_targets(user, spell_id)


## Get the throw range for a bomb item
func get_bomb_range(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "bomb":
		return 0
	return item.get("effect", {}).get("range", 4)


## Get the AoE radius for a bomb item
func get_bomb_aoe_radius(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty() or item.get("type", "") != "bomb":
		return 0
	return item.get("effect", {}).get("aoe_radius", 1)


## Get Alchemy skill consumable_power bonus percentage
## Matches perks.json: 10/20/35/50/75 per skill level
func _get_alchemy_bonus(user: Node) -> float:
	var skills = user.character_data.get("skills", {})
	var alchemy_level = skills.get("alchemy", 0)
	var bonus_table = [0.0, 10.0, 20.0, 35.0, 50.0, 75.0]
	if alchemy_level >= 0 and alchemy_level < bonus_table.size():
		return bonus_table[alchemy_level]
	return 0.0


## Apply a charm: stores a buff on the unit that reduces mana cost of the next matching spell
func _apply_charm(user: Node, item: Dictionary) -> Dictionary:
	var effect = item.get("effect", {})
	var school = effect.get("school", "")
	var mana_reduction = effect.get("mana_reduction", 0.0)
	var spellpower_bonus = effect.get("spellpower_bonus", 0.0)

	# Overwrite any existing charm (only one active at a time)
	user.charm_buff = {
		"school": school,
		"mana_reduction": mana_reduction,
		"spellpower_bonus": spellpower_bonus
	}

	return {
		"success": true,
		"effects_applied": [{
			"type": "charm",
			"school": school,
			"mana_reduction": mana_reduction,
			"spellpower_bonus": spellpower_bonus
		}]
	}


## Use a bomb: deal AoE damage at target position, optionally apply status effects
func _use_bomb(user: Node, item: Dictionary, target_pos: Vector2i) -> Dictionary:
	var effect = item.get("effect", {})
	var base_damage = effect.get("damage", 0)
	var damage_type = effect.get("damage_type", "fire")
	var aoe_radius = effect.get("aoe_radius", 1)
	var statuses = effect.get("statuses", [])
	var hits_all = effect.get("hits_all", false)  # true = hits allies too (smoke bomb)

	# Alchemy bonus increases bomb damage
	var alchemy_bonus = _get_alchemy_bonus(user)
	var total_damage = int(base_damage * (1.0 + alchemy_bonus / 100.0))

	# Find units in AoE
	var hit_units: Array[Node] = []
	for unit in all_units:
		if not unit.is_alive():
			continue
		var dist = _grid_distance(unit.grid_position, target_pos)
		if dist <= aoe_radius:
			if hits_all:
				hit_units.append(unit)
			elif unit.team != user.team:
				hit_units.append(unit)

	var results: Array[Dictionary] = []
	for target in hit_units:
		var unit_result: Dictionary = {"target": target, "effects_applied": []}

		# Apply damage (respects resistance)
		if total_damage > 0:
			var resist = target.get_resistance(damage_type)
			var final_damage = int(total_damage * (1.0 - resist / 100.0))
			final_damage = maxi(1, final_damage)
			apply_damage(target, final_damage, damage_type)
			unit_result.effects_applied.append({
				"type": "damage", "amount": final_damage, "element": damage_type
			})

		# Apply status effects
		for status_entry in statuses:
			var chance = status_entry.get("chance", 100)
			if randf() * 100.0 <= chance:
				var status_name = status_entry.get("name", "")
				var duration = status_entry.get("duration", 2)
				_apply_status_effect(target, status_name, duration)
				unit_result.effects_applied.append({
					"type": "status", "status": status_name, "duration": duration
				})

		results.append(unit_result)

	# Create ground effects from bomb damage type
	_create_ground_effects_from_damage(target_pos, aoe_radius, damage_type, 2)

	return {
		"success": true,
		"is_bomb": true,
		"target_pos": target_pos,
		"aoe_radius": aoe_radius,
		"hit_units": hit_units,
		"results": results
	}


## Apply an oil: coats the user's weapon with bonus effects for N attacks
func _apply_oil(user: Node, item: Dictionary) -> Dictionary:
	var effect = item.get("effect", {})
	var attacks = effect.get("attacks", 3)

	# Alchemy bonus adds extra attacks at level 3+ and 5
	var skills = user.character_data.get("skills", {})
	var alchemy_level = skills.get("alchemy", 0)
	if alchemy_level >= 5:
		attacks += 2
	elif alchemy_level >= 3:
		attacks += 1

	# Overwrite any existing oil (only one active at a time)
	user.weapon_oil = {
		"bonus_damage": effect.get("bonus_damage", 0),
		"bonus_damage_type": effect.get("bonus_damage_type", "fire"),
		"attacks_remaining": attacks,
		"status": effect.get("status", ""),
		"status_chance": effect.get("status_chance", 0),
		"status_duration": effect.get("status_duration", 0),
		"crit_bonus": effect.get("crit_bonus", 0)
	}

	return {
		"success": true,
		"effects_applied": [{
			"type": "oil",
			"bonus_damage_type": effect.get("bonus_damage_type", "fire"),
			"attacks": attacks
		}]
	}


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


# ============================================
# AI CONSUMABLE USAGE
# ============================================

## Use a combat item from an AI unit's own combat_inventory (not the player shared inventory).
## Works like use_combat_item but consumes from the unit's personal stash.
func ai_use_combat_item(user: Node, item_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found: " + item_id}

	# Check the unit's personal inventory
	var inv_index = -1
	for i in range(user.combat_inventory.size()):
		if user.combat_inventory[i].get("item_id", "") == item_id:
			if user.combat_inventory[i].get("quantity", 0) > 0:
				inv_index = i
				break
	if inv_index == -1:
		return {"success": false, "reason": "Not in inventory"}

	var item_type = item.get("type", "")

	# Validate targeting for bombs
	if item_type == "bomb":
		var effect = item.get("effect", {})
		var bomb_range = effect.get("range", 4)
		var distance = _spell_distance(user.grid_position, target_pos)
		if distance > bomb_range:
			return {"success": false, "reason": "Target out of range"}

	# Consume from personal inventory
	user.combat_inventory[inv_index].quantity -= 1
	if user.combat_inventory[inv_index].quantity <= 0:
		user.combat_inventory.remove_at(inv_index)

	# Apply the effect
	var result: Dictionary = {}
	match item_type:
		"potion":
			result = _apply_potion_effect(user, item)
		"bomb":
			result = _use_bomb(user, item, target_pos)
		"oil":
			result = _apply_oil(user, item)
		_:
			return {"success": false, "reason": "AI cannot use item type: " + item_type}

	if result.get("success", false):
		use_action(1)
		item_used_in_combat.emit(user, item, result)

	return result


# ============================================
# ACTIVE SKILLS
# ============================================

## Use an active skill. skill_data comes from perks.json with added combat_data.
## target_pos is used for targeted skills (single_enemy, aoe); ignored for self skills.
func use_active_skill(user: Node, skill_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	var combat_data = skill_data.get("combat_data", {})
	if combat_data.is_empty():
		return {"success": false, "reason": "Skill has no combat data"}

	var perk_id = skill_data.get("id", "")
	var stamina_cost = combat_data.get("stamina_cost", 0)

	# Check cooldown
	if user.is_skill_on_cooldown(perk_id):
		return {"success": false, "reason": "Skill on cooldown (%d turns)" % user.skill_cooldowns.get(perk_id, 0)}

	# Check stamina
	if stamina_cost > 0 and user.current_stamina < stamina_cost:
		return {"success": false, "reason": "Not enough stamina (%d/%d)" % [user.current_stamina, stamina_cost]}

	# Check weapon requirement — weapon skills need the matching weapon equipped
	var perk_skill = skill_data.get("skill", "")
	if not unit_has_required_weapon(user, perk_skill):
		var required = get_required_weapon_types(perk_skill)
		return {"success": false, "reason": "Requires %s weapon equipped" % "/".join(required)}

	var effect_type = combat_data.get("effect", "")
	var targeting = combat_data.get("targeting", "self")

	# Resolve the skill effect
	var result: Dictionary = {"success": true, "effects": []}

	match effect_type:
		"attack_with_bonus":
			result = _resolve_attack_skill(user, combat_data, target_pos)
		"dash_attack":
			result = _resolve_dash_attack(user, combat_data, target_pos)
		"buff_self":
			result = _resolve_buff_self(user, combat_data)
		"debuff_target":
			result = _resolve_debuff_target(user, combat_data, target_pos)
		"aoe_attack":
			result = _resolve_aoe_skill(user, combat_data, target_pos)
		"teleport":
			result = _resolve_teleport(user, combat_data, target_pos)
		"stance":
			result = _resolve_stance(user, combat_data)
		"heal_self":
			result = _resolve_heal_self(user, combat_data)
		_:
			return {"success": false, "reason": "Unknown skill effect: " + effect_type}

	if result.get("success", false):
		# Deduct stamina
		if stamina_cost > 0:
			user.use_stamina(stamina_cost)
		# Use action
		use_action(1)
		# Apply cooldown
		var cooldown = combat_data.get("cooldown", 0)
		if cooldown > 0:
			user.set_skill_cooldown(perk_id, cooldown)
		# Once-per-combat skills get a huge cooldown
		if combat_data.get("once_per_combat", false):
			user.set_skill_cooldown(perk_id, 999)
		# Emit signal
		active_skill_used.emit(user, skill_data, result)

	return result


## Attack with accuracy/damage bonuses (Measured Strike, Aimed Shot, Final Cut, etc.)
func _resolve_attack_skill(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot target allies"}

	var distance = _grid_distance(user.grid_position, target_pos)
	var max_range = combat_data.get("range", user.get_attack_range())
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	# Calculate hit with bonus accuracy
	var accuracy_bonus = combat_data.get("accuracy_bonus", 0)
	var damage_bonus_pct = combat_data.get("damage_bonus_pct", 0)
	var armor_ignore_pct = combat_data.get("armor_ignore_pct", 0)
	var resist_ignore_pct = combat_data.get("resist_ignore_pct", 0)
	var ignore_dodge = combat_data.get("ignore_dodge", false)

	# Roll to hit
	var hit_chance = calculate_hit_chance(user, target) + accuracy_bonus
	if ignore_dodge:
		hit_chance = 95.0  # Near guaranteed but not immune to nat 1
	var roll = randf() * 100.0
	var hit = roll <= hit_chance

	if not hit:
		return {"success": true, "hit": false, "roll": roll, "hit_chance": hit_chance, "target": target, "effects": []}

	# Calculate damage
	var dmg_type = user.get_weapon_damage_type()
	var dmg_result = calculate_physical_damage(user, target, dmg_type)
	var damage = dmg_result.damage

	# Apply damage bonus
	if damage_bonus_pct > 0:
		damage = int(damage * (1.0 + damage_bonus_pct / 100.0))

	# Apply armor/resist ignore
	if armor_ignore_pct > 0:
		# Recalculate without some armor
		var armor = target.get_armor()
		var armor_reduced = int(armor * armor_ignore_pct / 100.0)
		damage += armor_reduced  # Add back the armor that was subtracted

	# Apply damage
	apply_damage(target, damage, dmg_type)
	_check_immediate_combat_end()

	var result = {
		"success": true, "hit": true, "damage": damage, "target": target,
		"roll": roll, "hit_chance": hit_chance, "crit": dmg_result.crit,
		"effects": []
	}

	# Apply on-hit buff to self
	var self_buff = combat_data.get("self_buff", {})
	if not self_buff.is_empty():
		var stat = self_buff.get("stat", "")
		var value = self_buff.get("value", 0)
		var duration = self_buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		result.effects.append({"type": "self_buff", "stat": stat, "value": value, "duration": duration})

	# Apply on-hit debuff to target
	var target_debuff = combat_data.get("target_debuff", {})
	if not target_debuff.is_empty() and target.is_alive():
		var stat = target_debuff.get("stat", "")
		var value = target_debuff.get("value", 0)
		var duration = target_debuff.get("duration", 2)
		_apply_stat_modifier(target, stat, -value, duration)
		result.effects.append({"type": "target_debuff", "stat": stat, "value": value, "duration": duration})

	# Stamina refund on kill
	var refund_on_kill = combat_data.get("refund_on_kill", 0)
	if refund_on_kill > 0 and not target.is_alive():
		user.restore_stamina(refund_on_kill)
		result.effects.append({"type": "refund", "amount": refund_on_kill})

	return result


## Dash + Attack (Lunge, Whirling Advance, etc.)
func _resolve_dash_attack(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot target allies"}

	var dash_range = combat_data.get("dash_range", 2)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > dash_range + user.get_attack_range():
		return {"success": false, "reason": "Target too far to dash-attack"}

	# Move toward target (find closest adjacent tile)
	var best_tile = user.grid_position
	var best_dist = 999
	if combat_grid:
		var movement_mode = user.get_movement_mode() if user.has_method("get_movement_mode") else 0
		var reachable = combat_grid.get_reachable_tiles(user.grid_position, dash_range, movement_mode)
		for tile in reachable:
			var d = _grid_distance(tile, target_pos)
			if d > 0 and d <= user.get_attack_range() and d < best_dist:
				best_dist = d
				best_tile = tile

	# Move without using an action (it's part of the skill)
	if best_tile != user.grid_position and combat_grid:
		var from = user.grid_position
		combat_grid.move_unit(user, best_tile)
		unit_moved.emit(user, from, best_tile)

	# Now attack
	var damage_bonus_pct = combat_data.get("damage_bonus_pct", 0)
	var hit_chance = calculate_hit_chance(user, target)
	var roll = randf() * 100.0
	var hit = roll <= hit_chance

	if not hit:
		return {"success": true, "hit": false, "roll": roll, "hit_chance": hit_chance,
				"target": target, "moved_to": best_tile, "effects": []}

	var dmg_type = user.get_weapon_damage_type()
	var dmg_result = calculate_physical_damage(user, target, dmg_type)
	var damage = int(dmg_result.damage * (1.0 + damage_bonus_pct / 100.0))

	apply_damage(target, damage, dmg_type)
	_check_immediate_combat_end()

	return {
		"success": true, "hit": true, "damage": damage, "target": target,
		"moved_to": best_tile, "roll": roll, "hit_chance": hit_chance,
		"crit": dmg_result.crit, "effects": []
	}


## Buff self (Cloud Step, defensive stances, etc.)
func _resolve_buff_self(user: Node, combat_data: Dictionary) -> Dictionary:
	var buffs = combat_data.get("buffs", [])
	var effects: Array = []

	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)

		if stat == "movement_mode":
			# Special: grant a movement mode status
			var status_name = buff.get("status", "levitating")
			_apply_status_effect(user, status_name, duration)
			effects.append({"type": "status", "status": status_name, "duration": duration})
		elif stat != "":
			_apply_stat_modifier(user, stat, value, duration)
			effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	# Apply status effects from skill
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		var status_name = status_entry.get("status", "")
		var duration = status_entry.get("duration", 2)
		var value = status_entry.get("value", 0)
		_apply_status_effect(user, status_name, duration, value)
		effects.append({"type": "status", "status": status_name, "duration": duration})

	return {"success": true, "effects": effects}


## Debuff a target (Disrupting Palm, etc.)
func _resolve_debuff_target(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}

	var max_range = combat_data.get("range", 1)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	# Some debuff skills still attack first
	var deals_damage = combat_data.get("deals_damage", false)
	var damage = 0
	var hit = true

	if deals_damage:
		var hit_chance = calculate_hit_chance(user, target)
		var roll = randf() * 100.0
		hit = roll <= hit_chance

		if hit:
			var dmg_type = user.get_weapon_damage_type()
			var dmg_result = calculate_physical_damage(user, target, dmg_type)
			damage = dmg_result.damage
			apply_damage(target, damage, dmg_type)
			_check_immediate_combat_end()

	if not hit:
		return {"success": true, "hit": false, "target": target, "effects": []}

	# Apply debuffs
	var debuffs = combat_data.get("debuffs", [])
	var effects: Array = []
	for debuff in debuffs:
		var stat = debuff.get("stat", "")
		var value = debuff.get("value", 0)
		var duration = debuff.get("duration", 2)
		if stat != "" and target.is_alive():
			_apply_stat_modifier(target, stat, -value, duration)
			effects.append({"type": "debuff", "stat": stat, "value": value, "duration": duration})

	# Apply status effects
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		var status_name = status_entry.get("status", "")
		var duration = status_entry.get("duration", 2)
		if target.is_alive():
			_apply_status_effect(target, status_name, duration)
			effects.append({"type": "status", "status": status_name, "duration": duration})

	return {"success": true, "hit": true, "damage": damage, "target": target, "effects": effects}


## AoE skill (Volley, Ground Slam, etc.)
func _resolve_aoe_skill(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}

	var aoe_radius = combat_data.get("aoe_radius", 1)
	var damage_pct = combat_data.get("damage_pct", 60)  # % of normal damage

	# Find all enemy units in AoE
	var hit_targets: Array = []
	for unit in all_units:
		if not unit.is_alive() or unit.team == user.team:
			continue
		var d = _grid_distance(target_pos, unit.grid_position)
		if d <= aoe_radius:
			hit_targets.append(unit)

	var effects: Array = []
	for target in hit_targets:
		var dmg_type = user.get_weapon_damage_type()
		var dmg_result = calculate_physical_damage(user, target, dmg_type)
		var damage = int(dmg_result.damage * damage_pct / 100.0)
		apply_damage(target, damage, dmg_type)
		effects.append({"type": "aoe_damage", "target": target, "damage": damage})

	_check_immediate_combat_end()
	return {"success": true, "hit_count": hit_targets.size(), "effects": effects}


## Teleport (Step Between Moments, etc.)
func _resolve_teleport(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var teleport_range = combat_data.get("teleport_range", 3)
	var distance = _grid_distance(user.grid_position, target_pos)
	if distance > teleport_range:
		return {"success": false, "reason": "Teleport destination too far"}

	# Check tile is walkable and unoccupied
	if combat_grid:
		var unit_there = combat_grid.get_unit_at(target_pos)
		if unit_there != null:
			return {"success": false, "reason": "Tile occupied"}
		if not combat_grid.is_tile_walkable(target_pos):
			return {"success": false, "reason": "Tile not walkable"}

	# Teleport
	var from = user.grid_position
	if combat_grid:
		combat_grid.move_unit(user, target_pos)
	unit_moved.emit(user, from, target_pos)

	# Apply post-teleport buffs
	var effects: Array = []
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	return {"success": true, "teleported_to": target_pos, "effects": effects}


## Stance (Stand in the Gap, Counterstrike — end turn, gain defensive effect)
func _resolve_stance(user: Node, combat_data: Dictionary) -> Dictionary:
	var effects: Array = []

	# Apply stance buffs
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		_apply_stat_modifier(user, stat, value, duration)
		effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	# Apply stance status effects
	var statuses = combat_data.get("statuses", [])
	for status_entry in statuses:
		_apply_status_effect(user, status_entry.get("status", ""), status_entry.get("duration", 1))
		effects.append({"type": "status", "status": status_entry.status, "duration": status_entry.duration})

	# Stances end your turn — use all remaining actions
	var unit = get_current_unit()
	if unit == user:
		while unit.actions_remaining > 1:  # Leave 1 for the use_action call in use_active_skill
			unit.actions_remaining -= 1

	return {"success": true, "ends_turn": true, "effects": effects}


## Heal self (Mantra of Healing, etc.)
func _resolve_heal_self(user: Node, combat_data: Dictionary) -> Dictionary:
	var base_heal = combat_data.get("heal_value", 20)
	# Scale with spellpower or other stat
	var scale_stat = combat_data.get("scale_stat", "")
	var heal_amount = base_heal
	if scale_stat == "spellpower":
		heal_amount += int(user.get_spellpower() * 0.5)
	elif scale_stat == "focus":
		var focus = user.character_data.get("attributes", {}).get("focus", 10)
		heal_amount += (focus - 10) * 2

	var effects: Array = []

	if heal_amount > 0:
		user.heal(heal_amount)
		unit_healed.emit(user, heal_amount)
		effects.append({"type": "heal", "amount": heal_amount})

	# Stamina restore (for skills like Second Wind)
	var stamina_restore_pct = combat_data.get("stamina_restore_pct", 0)
	if stamina_restore_pct > 0:
		var stamina_amount = int(user.max_stamina * stamina_restore_pct / 100.0)
		user.restore_stamina(stamina_amount)
		effects.append({"type": "stamina_restore", "amount": stamina_amount})

	# Apply any buffs from the skill (e.g., damage resistance from Second Wind)
	var buffs = combat_data.get("buffs", [])
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 1)
		if stat != "":
			_apply_stat_modifier(user, stat, value, duration)
			effects.append({"type": "buff", "stat": stat, "value": value, "duration": duration})

	return {"success": true, "heal_amount": heal_amount, "effects": effects}


## Get the targeting type for a skill's combat_data
func get_skill_targeting(combat_data: Dictionary) -> String:
	return combat_data.get("targeting", "self")


## Get valid target tiles for an active skill based on its targeting type
func get_active_skill_targets(user: Node, combat_data: Dictionary) -> Array[Vector2i]:
	var targeting = combat_data.get("targeting", "self")
	var skill_range = combat_data.get("range", 1)
	var result: Array[Vector2i] = []

	match targeting:
		"self":
			result.append(user.grid_position)
		"single_enemy":
			# All enemy tiles within range
			for unit in all_units:
				if not unit.is_alive() or unit.team == user.team:
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= skill_range:
					result.append(unit.grid_position)
		"single_ally":
			for unit in all_units:
				if not unit.is_alive() or unit.team != user.team:
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= skill_range:
					result.append(unit.grid_position)
		"aoe_point":
			# Any tile within range
			if combat_grid:
				for x in range(combat_grid.grid_width):
					for y in range(combat_grid.grid_height):
						var tile = Vector2i(x, y)
						var dist = _grid_distance(user.grid_position, tile)
						if dist <= skill_range:
							result.append(tile)
		"teleport":
			# Any walkable unoccupied tile within range
			if combat_grid:
				for x in range(combat_grid.grid_width):
					for y in range(combat_grid.grid_height):
						var tile = Vector2i(x, y)
						var dist = _grid_distance(user.grid_position, tile)
						if dist <= skill_range and combat_grid.is_tile_walkable(tile):
							var unit_at = combat_grid.get_unit_at(tile)
							if unit_at == null or unit_at == user:
								result.append(tile)
		"dash_attack":
			# All enemy tiles within dash_range + attack_range
			var dash_range = combat_data.get("dash_range", 2)
			var attack_range = user.get_attack_range()
			for unit in all_units:
				if not unit.is_alive() or unit.team == user.team:
					continue
				var dist = _grid_distance(user.grid_position, unit.grid_position)
				if dist <= dash_range + attack_range:
					result.append(unit.grid_position)

	return result


## Map a perk's skill name to the weapon types that satisfy it.
## Returns an empty array if the skill doesn't require a specific weapon.
func get_required_weapon_types(skill_name: String) -> Array:
	match skill_name:
		"swords":
			return ["sword"]
		"axes":
			return ["axe"]
		"maces":
			return ["mace"]
		"spears":
			return ["spear"]
		"daggers":
			return ["dagger"]
		"ranged":
			return ["bow", "thrown"]
		"unarmed":
			return ["unarmed"]  # Special: must have NO weapon equipped
		"martial_arts":
			return ["staff", "unarmed"]  # Staff or bare-handed
		_:
			return []  # Non-weapon skills (might, medicine, etc.) — no requirement


## Check if a unit has the right weapon equipped for a given perk skill.
## Returns true if the weapon requirement is satisfied.
func unit_has_required_weapon(unit: Node, skill_name: String) -> bool:
	var required = get_required_weapon_types(skill_name)
	if required.is_empty():
		return true  # No weapon requirement

	var weapon = unit.get_equipped_weapon()
	var weapon_type = weapon.get("type", "") if not weapon.is_empty() else ""

	# "unarmed" means no weapon equipped
	if "unarmed" in required:
		if weapon.is_empty() or weapon_type == "":
			return true

	# Check if the equipped weapon type is in the required list
	if weapon_type in required:
		return true

	return false
