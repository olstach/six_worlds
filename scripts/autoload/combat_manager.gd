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
signal combat_log(message: String)

# Combat state
var combat_active: bool = false
var combat_grid: Node = null  # Reference to CombatGrid
var arena_scene: Node = null  # Reference to combat arena

# Units in combat
var all_units: Array[Node] = []
var turn_order: Array[Node] = []
# Lord of Death DY: units that have triggered the DY; used for resurrection-on-kill checks
var _lord_of_death_casters: Array = []
var current_unit_index: int = 0
var combat_round: int = 0  # Current round number (1 = first round); used by no_warning and similar perks

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

# Loot system constants
# Budget-based loot: enemy inventories are collected, filtered, and turned into drops.
# Items below the realm's floor value convert to gold — junk in one realm is valuable
# elsewhere, so the floor rises as the player ascends to higher realms.
# Calibrated against value_mult in equipment_tables.json:
#   hell         bone (0.35x) / obsidian (0.90x) — catches bone items (~8–17g)
#   hungry_ghost bone/obsidian/bronze (0.65x) — catches bone, passes bronze
#   animal       bronze/iron (1.00x) — catches bone/poor bronze
#   human        iron/steel (1.50x) — catches bronze, passes good iron and steel
#   demi_god     steel/damascene (2.50x) — catches iron, passes damascene (~125g+)
#   god          damascene/sky_iron (5.00x)/vajra (15x) — catches steel, passes sky_iron+
const LOOT_FLOOR_BY_REALM: Dictionary = {
	"hell":         25,
	"hungry_ghost": 35,
	"animal":       50,
	"human":        80,
	"demi_god":    150,
	"god":         300,
}
# All 8 compass directions — used by projectile deviation and bomb scatter
const DIRS_8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

const LOOT_FLOOR_DEFAULT: int = 20  # Fallback for unknown realms
# Fraction of the above-floor loot value that actually drops as items.
# Remaining value leaks to gold at LOOT_OVERFLOW_GOLD_RATE.
const LOOT_DROP_FRACTION_MIN: float = 0.35
const LOOT_DROP_FRACTION_MAX: float = 0.65
# Below-budget overflow becomes gold at this rate (salvage value)
const LOOT_OVERFLOW_GOLD_RATE: float = 0.20
# Flat drop chance for each consumable from enemy inventory (potions, bombs, oils)
const LOOT_CONSUMABLE_DROP_CHANCE: float = 0.50
# Supplies drop alongside equipment loot — common, regenerates between fights
const SUPPLY_DROP_IDS: Array[String] = ["rations", "herb_bundle", "scrap_metal"]
const SUPPLY_DROP_CHANCE: float = 0.50
# Reagents are rarer — 25% base, 50% when casters/supports present
const REAGENT_DROP_ID: String = "raw_reagents"
const REAGENT_DROP_CHANCE: float = 0.25
const REAGENT_DROP_CHANCE_CASTER: float = 0.50
# Base rarity weights (higher = more likely to drop) — still used by boss table picks
const RARITY_DROP_WEIGHTS: Dictionary = {
	"common": 100, "uncommon": 50, "rare": 20, "epic": 5, "legendary": 1
}
const MAX_RANDOM_DROPS: int = 5

# Spell tier display names (skill level → tier name)
const SPELL_TIER_NAMES: Dictionary = {
	1: "Outermost Circle", 3: "Outer Circle", 5: "Inner Circle",
	7: "Secret Circle", 9: "Unsurpassed Circle"
}

# School name → skill name mapping for display
const SCHOOL_TO_SKILL_NAME: Dictionary = {
	"earth": "Earth Magic", "water": "Water Magic", "fire": "Fire Magic",
	"air": "Air Magic", "space": "Space Magic", "white": "White Magic",
	"black": "Black Magic", "sorcery": "Sorcery", "enchantment": "Enchantment",
	"summoning": "Summoning"
}


## Get the tier display name for a spell (e.g. "Outer Circle of Cloud" or "Inner Circle of Fire")
static func get_spell_tier_display(spell: Dictionary) -> String:
	var level = int(spell.get("level", 1))  # Cast to int: JSON may return float, causing dict miss
	var tier_name = SPELL_TIER_NAMES.get(level, "Circle %d" % level)
	var domain = spell.get("domain", "")
	if domain != "":
		return "%s of %s" % [tier_name, domain.capitalize()]
	# Use first elemental school for the "of X" suffix
	var schools = spell.get("schools", [])
	if not schools.is_empty():
		return "%s of %s" % [tier_name, schools[0]]
	return tier_name


## Build a skill requirements string for a spell (e.g. "Requires Water Magic 3, Air Magic 3 or Sorcery 3")
static func get_spell_skill_reqs(spell: Dictionary) -> String:
	var level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var subschool = spell.get("subschool", "")
	var parts: Array[String] = []
	for school in schools:
		var skill_name = SCHOOL_TO_SKILL_NAME.get(school.to_lower(), school)
		parts.append("%s %d" % [skill_name, level])
	if subschool != "" and not subschool in schools:
		var skill_name = SCHOOL_TO_SKILL_NAME.get(subschool.to_lower(), subschool)
		parts.append("%s %d" % [skill_name, level])
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return "Requires " + parts[0]
	var last = parts.pop_back()
	return "Requires " + ", ".join(parts) + " or " + last


# Damage type → terrain effect mapping (only elements that leave ground effects)
# Physical subtypes (slashing/crushing/piercing/physical) intentionally excluded — no terrain.
const DAMAGE_TYPE_TO_TERRAIN_EFFECT: Dictionary = {
	"fire": 1,        # TerrainEffect.FIRE
	"ice": 2,         # TerrainEffect.ICE
	"cold": 2,        # TerrainEffect.ICE
	"poison": 3,      # TerrainEffect.POISON
	"acid": 4,        # TerrainEffect.ACID
	"white": 5,       # TerrainEffect.BLESSED
	"holy": 5,        # TerrainEffect.BLESSED
	"black": 6,       # TerrainEffect.CURSED
	"water": 7,       # TerrainEffect.WET
	"air": 8,         # TerrainEffect.STORMY
	"space": 9,       # TerrainEffect.VOID
	"solar": 1,       # TerrainEffect.FIRE (solar leaves fire)
}

# Deployment state
var _deployment_phase: bool = false
var _pending_deployment_units: Array[Node] = []
var _can_manually_deploy: bool = false

# Spell database
var _spell_database: Dictionary = {}
var _status_effects: Dictionary = {}

# Summon templates database
var _summon_templates: Dictionary = {}

# Combat rewards (filled before combat_ended signal, cleared on next combat start)
var last_combat_rewards: Dictionary = {}

func _ready() -> void:
	_load_spell_database()
	_load_status_definitions()
	_load_summon_templates()
	print("CombatManager initialized with ", _spell_database.size(), " spells, ",
		_status_effects.size(), " status effects, ",
		_summon_templates.size(), " summon templates")


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


## Load status effect definitions from statuses.json and index by name.
## Also derives blocks_actions / blocks_movement flags from the effects array
## so _process_status_effects() and is_unit_incapacitated() work correctly.
func _load_status_definitions() -> void:
	var file_path = "res://resources/data/statuses.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: statuses.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("CombatManager: Failed to parse statuses.json")
		return

	var data = json.get_data()
	var statuses_array = data.get("statuses", [])

	# Index by name for O(1) lookup
	for status in statuses_array:
		var sname = status.get("name", "")
		if sname == "":
			continue

		var effects = status.get("effects", [])

		# Derive blocks_actions from effects array
		if not status.has("blocks_actions"):
			for fx in effects:
				if fx in ["skip_turn", "cannot_act"]:
					status["blocks_actions"] = true
					break

		# Derive blocks_movement from effects array
		if not status.has("blocks_movement"):
			for fx in effects:
				if fx in ["cannot_move", "immobilized", "rooted"]:
					status["blocks_movement"] = true
					break

		# Derive blocks_casting from effects array
		if not status.has("blocks_casting"):
			for fx in effects:
				if fx in ["cannot_cast", "silenced"]:
					status["blocks_casting"] = true
					break

		# Derive blocks_attacks from effects array
		if not status.has("blocks_attacks"):
			for fx in effects:
				if fx in ["cannot_attack", "will_not_attack"]:
					status["blocks_attacks"] = true
					break

		_status_effects[sname] = status


## Get a status definition by name (for external use by CombatUnit, etc.)
func get_status_definition(status_name: String) -> Dictionary:
	return _status_effects.get(status_name, {})


## Load summon templates from summon_templates.json
func _load_summon_templates() -> void:
	var file_path = "res://resources/data/summon_templates.json"
	if not FileAccess.file_exists(file_path):
		push_warning("CombatManager: summon_templates.json not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		push_error("CombatManager: Failed to parse summon_templates.json")
		return
	var data = json.get_data()
	_summon_templates = data.get("templates", {})


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
	combat_round = 1
	last_combat_rewards = {}

	# Add all units and set initial facing based on team
	for unit in player_units:
		all_units.append(unit)
		if "facing" in unit:
			unit.facing = Vector2i(1, 0)   # Players face right toward enemies
	for unit in enemy_units:
		all_units.append(unit)
		if "facing" in unit:
			unit.facing = Vector2i(-1, 0)  # Enemies face left toward players

	# Calculate turn order based on initiative
	_calculate_turn_order()

	combat_started.emit()

	# Apply combat-start perk effects (auras, first-round buffs)
	_apply_combat_start_perks()

	# Start first turn
	_start_current_turn()


## Apply perks that trigger once at the very start of combat.
func _apply_combat_start_perks() -> void:
	for unit in all_units:
		var char_data = unit.character_data if "character_data" in unit else {}
		# Rousing Display (Performance 1): allies within 3 tiles gain +5 Initiative for round 1
		if PerkSystem.has_perk(char_data, "rousing_display"):
			for ally in get_team_units(unit.team if "team" in unit else 0):
				if ally == unit: continue
				if _grid_distance(unit.grid_position, ally.grid_position) <= 3:
					_apply_stat_modifier(ally, "initiative", 5, 1)


## DoT statuses that can persist from combat into the overworld
const OVERWORLD_DOT_STATUSES: Array = [
	"Poisoned", "Bleeding", "Burning", "Festering", "Diseased"
]

## End combat
func end_combat(victory: bool) -> void:
	if not combat_active:
		return

	# Calculate rewards BEFORE clearing units (need enemy data)
	if victory:
		last_combat_rewards = _calculate_combat_rewards()
	else:
		last_combat_rewards = {}

	# Sync player unit state back to character_data before clearing units
	_sync_combat_state_to_characters()

	# Apply post-combat emotional pressure to all player characters
	_apply_post_combat_pressure(victory)

	combat_active = false
	_deployment_phase = false
	combat_ended.emit(victory)

	# Cleanup
	all_units.clear()
	turn_order.clear()
	combat_grid = null


## Apply emotional pressure to party based on combat outcome.
func _apply_post_combat_pressure(victory: bool) -> void:
	var party = CharacterSystem.get_party()
	if victory:
		for member in party:
			PsychologySystem.apply_pressure(member, "fire", 10.0)
			PsychologySystem.apply_pressure(member, "air", 10.0)
	else:
		for member in party:
			PsychologySystem.apply_pressure(member, "earth", -10.0)
			PsychologySystem.apply_pressure(member, "space", -5.0)


## Write current HP, mana, and persisting DoT statuses back to character_data
func _sync_combat_state_to_characters() -> void:
	for unit in all_units:
		if unit.team != Team.PLAYER:
			continue
		if not "character_data" in unit:
			continue
		var cdata = unit.character_data
		if not "derived" in cdata:
			cdata["derived"] = {}
		# HP / mana — preserve whatever the unit ended combat with
		cdata.derived["current_hp"] = unit.current_hp
		cdata.derived["current_mana"] = unit.current_mana
		# Persisting DoT statuses
		var persisting: Array = []
		for effect in unit.status_effects:
			var sname = effect.get("status", "")
			if sname in OVERWORLD_DOT_STATUSES:
				var def = _status_effects.get(sname, {})
				persisting.append({
					"status": sname,
					"duration": effect.get("duration", 1),
					"damage_per_step": def.get("damage_per_turn", 3)
				})
		cdata["overworld_statuses"] = persisting


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
	# Base: 15 XP per enemy, scaled by difficulty ratio.
	# Party-size multiplier (solo=1.5×, duo=1.25×, etc.) is applied later in CompanionSystem.apply_party_xp.
	var base_xp := enemy_count * 15
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
	# Collect equipment and consumables from enemy inventories (budget-based),
	# then add supply/reagent/boss drops on top.
	var loot_result := _collect_enemy_loot()
	var item_drops: Array[String] = loot_result.get("items", [])
	gold_reward += loot_result.get("bonus_gold", 0)

	var extra_drops: Array[String] = _generate_loot_drops(enemy_count, ratio, best_luck)
	for drop_id in extra_drops:
		item_drops.append(drop_id)

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


## Generate supply, reagent, and boss guaranteed drops.
## Role-based random equipment drops have been removed — enemies now carry real inventories
## that feed the budget-based _collect_enemy_loot() system instead.
func _generate_loot_drops(enemy_count: int, _difficulty_ratio: float, _best_luck: int) -> Array[String]:
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

	# --- Supply drops (rations, herbs, scrap) ---
	# 50% base chance; scale count with fight size.
	if randf() < SUPPLY_DROP_CHANCE:
		var supply_count: int = 1 + (enemy_count / 3)
		for i in range(supply_count):
			drops.append(SUPPLY_DROP_IDS[randi() % SUPPLY_DROP_IDS.size()])

	# --- Reagent drops (rarer; boosted when casters/supports were present) ---
	var has_casters := false
	for role in enemy_roles:
		if role == "caster" or role == "support":
			has_casters = true
			break
	var reagent_chance := REAGENT_DROP_CHANCE_CASTER if has_casters else REAGENT_DROP_CHANCE
	if randf() < reagent_chance:
		drops.append(REAGENT_DROP_ID)

	# --- Boss guaranteed drops ---
	for arch_id in boss_archetype_ids:
		var archetype = EnemySystem.archetypes.get(arch_id, {})
		var guaranteed = archetype.get("guaranteed_drops", [])
		for item_id in guaranteed:
			if ItemSystem.item_exists(item_id) and not item_id in drops:
				drops.append(item_id)

	return drops


## Collect loot from dead enemy inventories using a budget-based system.
##
## How it works (inspired by Diablo 2 treasure classes + Diablo 3 Loot 2.0):
##   - Items below LOOT_FLOOR_VALUE auto-convert to gold (no junk floods).
##   - Remaining equipment is sorted best-first by value.
##   - A randomized drop_fraction of the total value becomes the item budget.
##   - Items are taken greedily from the sorted list until the budget runs out.
##   - Over-budget items are salvaged to gold at LOOT_OVERFLOW_GOLD_RATE.
##   - Consumables (potions, bombs, oils) drop at a flat per-item chance.
##   - Thievery skill widens the drop_fraction toward the maximum.
##
## Returns {"items": Array[String], "bonus_gold": int}
func _collect_enemy_loot() -> Dictionary:
	var equipment_entries: Array = []   # {item_id: String, value: int}
	var consumable_drops: Array[String] = []
	var bonus_gold: int = 0

	# Walk every dead enemy unit's combat_inventory
	for unit in all_units:
		if unit.team != Team.ENEMY:
			continue
		for entry in unit.combat_inventory:
			var item_id: String = entry.get("item_id", "")
			if item_id == "":
				continue
			var qty: int = maxi(1, entry.get("quantity", 1))
			var item: Dictionary = ItemSystem.get_item(item_id)
			if item.is_empty():
				continue

			var item_type: String = item.get("type", "")
			var is_equipment: bool = (
				item_type in ItemSystem.WEAPON_TYPES
				or item_type in ItemSystem.ARMOR_TYPES
				or item_type in ItemSystem.TALISMAN_TYPES
			)

			if is_equipment:
				var item_value: int = item.get("value", 5)
				for _i in range(qty):
					equipment_entries.append({"item_id": item_id, "value": item_value})
			else:
				# Consumables: flat per-item drop chance
				for _i in range(qty):
					if randf() < LOOT_CONSUMABLE_DROP_CHANCE:
						consumable_drops.append(item_id)

	# Value floor — scales with realm so bone knives are junk in Hell but
	# iron swords stop dropping as items once the party reaches the human realm.
	var current_realm: String = GameState.current_world if GameState else ""
	var loot_floor: int = LOOT_FLOOR_BY_REALM.get(current_realm, LOOT_FLOOR_DEFAULT)

	var above_floor: Array = []
	for eq in equipment_entries:
		if eq.value < loot_floor:
			bonus_gold += eq.value  # Auto-coin: not worth the inventory slot here
		else:
			above_floor.append(eq)

	# Sort best items first — ensures the player always gets the most valuable pieces first
	above_floor.sort_custom(func(a, b): return a.value > b.value)

	# Drop fraction boosted by Thievery — skilled thieves know where to look
	var best_thievery := 0
	for member in CharacterSystem.get_party():
		var t: int = member.get("skills", {}).get("thievery", 0)
		if t > best_thievery:
			best_thievery = t
	var thievery_bonus: float = clampf(best_thievery * 0.03, 0.0, 0.30)
	var drop_fraction: float = clampf(
		randf_range(LOOT_DROP_FRACTION_MIN, LOOT_DROP_FRACTION_MAX) + thievery_bonus,
		LOOT_DROP_FRACTION_MIN, LOOT_DROP_FRACTION_MAX
	)

	# Budget = fraction of above-floor equipment value
	var total_value: int = 0
	for eq in above_floor:
		total_value += eq.value
	var budget: int = int(float(total_value) * drop_fraction)

	# Greedy fill: take items from best-first until budget is spent
	var result_items: Array[String] = []
	for eq in above_floor:
		if budget > 0 and eq.value <= budget:
			result_items.append(eq.item_id)
			budget -= eq.value
		else:
			# Over budget: salvage to gold at reduced rate
			bonus_gold += int(eq.value * LOOT_OVERFLOW_GOLD_RATE)

	# Append consumable drops (not subject to budget)
	for item_id in consumable_drops:
		result_items.append(item_id)

	return {"items": result_items, "bonus_gold": bonus_gold}


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
## Uses procedural generation when no static items match or when the rarity roll
## favors a generated item (higher rarities are more likely to be procedural).
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

	# Check if we should generate a procedural item instead of picking static
	# Higher rarities have a higher chance of being procedural
	var proc_chance: float = ItemSystem.PROCEDURAL_CHANCE_BY_RARITY.get(rolled_rarity, 0.15)
	var generatable_types: Array[String] = []
	for item_type in allowed_types:
		if ItemSystem.can_generate_type(item_type):
			generatable_types.append(item_type)

	var current_realm = GameState.current_world if GameState else ""
	if not generatable_types.is_empty() and randf() < proc_chance:
		# Generate a procedural item of a random allowed type
		var gen_type = generatable_types[randi() % generatable_types.size()]
		var gen_id = ItemSystem.generate_item_for_type(gen_type, rolled_rarity, current_realm)
		if gen_id != "":
			return gen_id

	# Try to find a static item at the rolled rarity, fall back to lower
	var rarity_idx = rarity_order.find(rolled_rarity)
	for check_idx in range(rarity_idx, rarity_order.size()):
		var check_rarity = rarity_order[check_idx]
		var candidates: Array[String] = []

		for item_type in allowed_types:
			var items = ItemSystem.get_items_by_type(item_type)
			for item in items:
				# Skip template items — they're blueprints, not real drops
				if ItemSystem.is_template_item(item.get("id", "")):
					continue
				if item.get("rarity", "") == check_rarity:
					candidates.append(item.get("id", ""))

		if not candidates.is_empty():
			return candidates[randi() % candidates.size()]

	# Last resort: if no static items matched at any rarity, try procedural generation
	if not generatable_types.is_empty():
		var gen_type = generatable_types[randi() % generatable_types.size()]
		var gen_id = ItemSystem.generate_item_for_type(gen_type, rolled_rarity, current_realm)
		if gen_id != "":
			return gen_id

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
	# Set initial facing based on team (deployment path)
	for unit in all_units:
		if "facing" in unit:
			unit.facing = Vector2i(1, 0) if unit.team == Team.PLAYER else Vector2i(-1, 0)

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

# Clear mantra stat bonuses every turn so aura/buff effects don't accumulate unboundedly.
	# Other units may write to this dict (e.g. Guardian Kings aura, Jeweled Pagoda summon buffs),
	# so it must be cleared for ALL units, not just active chanters.
	unit.mantra_stat_bonuses = {}

	# Tick active mantras and apply per-turn effects
	if not unit.active_mantras.is_empty():
		unit.tick_mantras()
		_process_mantra_effects_and_auras(unit)

	# Process passive perk turn-start effects
	_process_turn_start_perks(unit)

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
	combat_round += 1
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

	# Duel stop condition — some bosses (e.g. skeleton_king_duel) have a duel_stop_hp_pct
	# field: the fight ends as a player victory when that enemy drops to or below that HP %.
	for unit in all_units:
		if unit.team != Team.ENEMY or not unit.is_alive():
			continue
		var stop_pct: int = unit.character_data.get("duel_stop_hp_pct", 0)
		if stop_pct <= 0:
			continue
		var max_hp: int = unit.max_hp
		var cur_hp: int = unit.current_hp
		if max_hp > 0 and cur_hp * 100 <= max_hp * stop_pct:
			_log_message("%s yields — the duel is over." % unit.character_data.get("name", "Enemy"))
			return Team.PLAYER  # Duel victory

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
	unit.moved_this_turn = true

	# Update facing toward movement direction
	if "facing" in unit and target != from:
		unit.facing = _dir_toward(from, target)

	use_action(1)
	unit_moved.emit(unit, from, target)

	# Zone of Control reactions: check all enemies of this unit for ZoC perks
	_check_zoc_reactions(unit, from, target)

	# Stealth detection: enemies within 5 tiles roll AWR checks per step
	if "is_stealthed" in unit and unit.is_stealthed:
		_run_stealth_detection(unit)

	return true


# ============================================
# COMBAT RESOLUTION
# ============================================

## Perform an attack from one unit to another.
## reaction=true: skips can_act() check and use_action() cost (for free attacks and ZoC reactions).
func attack_unit(attacker: Node, defender: Node, reaction: bool = false) -> Dictionary:
	if not reaction and not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	# Forgetful / Pacified units cannot attack
	if not can_unit_attack(attacker):
		return {"success": false, "reason": "Cannot attack in current state"}

	# Charmed units cannot attack the caster who charmed them
	var charm_source = get_cc_source(attacker, "charmed")
	if charm_source == defender:
		return {"success": false, "reason": "Cannot attack — charmed by this target"}

	# Blinded units cannot use ranged attacks
	var is_ranged_check = attacker.is_ranged_weapon() if attacker.has_method("is_ranged_weapon") else false
	if is_ranged_check:
		for fx in attacker.status_effects:
			var fx_def = _status_effects.get(fx.get("status", ""), {})
			if "cannot_use_ranged" in fx_def.get("effects", []):
				return {"success": false, "reason": "Cannot use ranged attacks while blinded"}

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

	# Update attacker facing toward defender
	if "facing" in attacker:
		attacker.facing = _dir_toward(attacker.grid_position, defender.grid_position)

	# Shadow Strike: first attack from stealth is a guaranteed crit
	var _stealth_attack = "is_stealthed" in attacker and attacker.is_stealthed

	# Calculate hit chance
	var hit_chance = calculate_hit_chance(attacker, defender)
	var roll = randf() * 100.0
	var hit = _stealth_attack or (roll <= hit_chance)  # stealth = auto-hit

	# Force-miss: that_was_supposed_to_miss perk applied this flag to the attacker
	if not _stealth_attack and "will_miss_next_attack" in attacker and attacker.will_miss_next_attack:
		hit = false
		attacker.will_miss_next_attack = false
		combat_log.emit("%s swings wide — it was supposed to miss!" % attacker.unit_name)

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
		# Track last attacker for risen_dead and similar effects
		if "last_attacker" in defender:
			defender.last_attacker = attacker

		# Calculate damage
		var damage_result = calculate_physical_damage(attacker, defender, weapon_dmg_type)
		result.merge(damage_result, true)

		# Shadow Strike: stealth attack is always a crit (apply crit multiplier if not already a crit)
		if _stealth_attack and not result.get("crit", false):
			result["crit"] = true
			result["damage"] = int(result["damage"] * 1.5)
		# Break stealth / invisibility after attacking
		if _stealth_attack:
			var _att_char_sd = attacker.character_data if "character_data" in attacker else {}
			var _is_invisible = attacker.has_status("Invisible") if attacker.has_method("has_status") else false
			if _is_invisible:
				# Invisible: attacking consumes the Invisible status but stealth persists
				_remove_status_by_name(attacker, "Invisible")
				combat_log.emit("%s's invisibility shatters — but remains in the shadows." % attacker.unit_name)
			else:
				# Regular stealth: break rules apply
				var _shady = PerkSystem.has_perk(_att_char_sd, "shady_dealings")
				var _is_melee_sd = not (attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon())
				if _is_melee_sd:
					_leave_stealth(attacker)
					combat_log.emit("%s breaks stealth with a melee attack!" % attacker.unit_name)
				elif not _shady:
					_leave_stealth(attacker)
					combat_log.emit("%s breaks stealth with an attack!" % attacker.unit_name)
				else:
					if _shady_dealings_detected(attacker):
						_leave_stealth(attacker)
						combat_log.emit("An enemy detected %s despite Shady Dealings!" % attacker.unit_name)
					else:
						combat_log.emit("%s stays hidden (Shady Dealings)." % attacker.unit_name)

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

		# --- Reactive status effects on hit ---
		_process_reactive_statuses(attacker, defender, result)

		# --- Damage from caster breaks Charmed ---
		# If the attacker was the one who charmed the defender, break charm
		if "status_effects" in defender:
			var charm_to_remove: Array[int] = []
			for ci in range(defender.status_effects.size()):
				var se = defender.status_effects[ci]
				if se.get("status", "") == "Charmed":
					var src = se.get("source", null)
					if src == attacker:
						charm_to_remove.append(ci)
			charm_to_remove.reverse()
			for cidx in charm_to_remove:
				defender.status_effects.remove_at(cidx)
				if defender.has_method("show_status_expired"):
					defender.show_status_expired("Charmed")
				status_effect_expired.emit(defender, "Charmed")

		# --- Talisman: Thorns — reflect 3 damage to melee attackers ---
		var is_melee_attack = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_attack and _unit_has_talisman_perk(defender, "thorns"):
			apply_damage(attacker, 3, "physical")
			result["thorns_damage"] = 3

		# --- Attacker lifesteal statuses ---
		if attacker.has_status("Lifelink") or attacker.has_status("Blood_Hunger"):
			var steal_pct = 0.5
			if _unit_has_perk(attacker, "blood_pact"):
				steal_pct *= 1.25  # Blood Pact: lifesteal heals 25% more
			var steal = int(result.damage * steal_pct)
			if steal > 0:
				attacker.heal(steal)
				unit_healed.emit(attacker, steal)
				result["lifesteal"] = steal

		# --- Passive perk on-hit effects ---
		_process_on_hit_perks(attacker, defender, result)
		# --- Weapon passive on-hit procs ---
		_process_weapon_on_hit_procs(attacker, defender, result)
		# --- Ammo special effects (fire arrow AoE, status procs) ---
		if "get_selected_ammo" in attacker:
			var ammo = attacker.get_selected_ammo()
			if ammo.has("special_effect"):
				_process_ammo_special_effect(attacker, defender, ammo)
		# --- Weapon durability ---
		_deduct_weapon_durability(attacker)

		# --- Urumi sweep: hit all other adjacent enemies at -15 accuracy ---
		if attacker.has_method("get_equipped_weapon"):
			var sweep_weapon = attacker.get_equipped_weapon()
			if sweep_weapon.get("special_attack", "") == "sweep":
				var sweep_targets = _get_enemies_in_range(attacker, 1)
				sweep_targets.erase(defender)  # primary target already hit
				for sweep_target in sweep_targets:
					if not sweep_target.is_alive():
						continue
					var sweep_hit_chance = calculate_hit_chance(attacker, sweep_target) - 15.0
					if randf() * 100.0 <= sweep_hit_chance:
						var sweep_dmg_result = calculate_physical_damage(attacker, sweep_target, weapon_dmg_type)
						# No crit bonus on sweep hits
						sweep_dmg_result["crit"] = false
						sweep_dmg_result["damage"] = int(sweep_dmg_result.get("damage", 0) * 0.75)
						apply_damage(sweep_target, maxi(1, sweep_dmg_result.get("damage", 0)), weapon_dmg_type)
						combat_log.emit("%s's urumi sweeps %s!" % [attacker.unit_name, sweep_target.unit_name])
						result["sweep_hit"] = true

	else:
		# Attack missed — check dodge/parry perks on defender
		_process_on_dodge_perks(defender, attacker)
		# Reset consecutive hit streaks on miss
		attacker.momentum_stacks = 0
		attacker.unarmed_hit_stacks = 0
		# Ranged misses: projectile deviates and may hit someone else.
		# Clamp to 0 so forced-miss perks (will_miss_next_attack) don't produce negative margin.
		if is_ranged:
			var miss_margin: float = maxf(0.0, result.roll - result.hit_chance)
			var dev = _resolve_projectile_deviation(attacker, defender, miss_margin)
			result.merge(dev, true)

	# Track per-turn attack type counters (after resolving, so 'first attack' checks work)
	if attacker.has_method("get_equipped_weapon"):
		if attacker.get_equipped_weapon().get("type", "") == "dagger":
			attacker.dagger_attacks_this_turn += 1
	if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
		attacker.ranged_attacks_this_turn += 1
		# Consume one ammo; revert to default if depleted
		if "selected_ammo_id" in attacker and attacker.selected_ammo_id != "":
			var still_has_ammo = ItemSystem.consume_ammo(attacker.selected_ammo_id)
			if not still_has_ammo:
				var ammo_name = ItemSystem.get_ammo(attacker.selected_ammo_id).get("name", attacker.selected_ammo_id)
				combat_log.emit("%s's %s ran out — falling back to bone arrows." % [attacker.unit_name, ammo_name])
				attacker.selected_ammo_id = ""

	if not reaction:
		use_action(1)
	unit_attacked.emit(attacker, defender, result)
	return result


## Resolve a ranged projectile miss — calculate deviation and apply damage if it hits someone.
## Returns a dict with deviation_* fields merged into the attack result.
func _resolve_projectile_deviation(attacker: Node, defender: Node, miss_margin: float) -> Dictionary:
	# Deviation distance scales with how badly the shot missed (margin already clamped ≥0 by caller)
	var dev_tiles: int
	if miss_margin <= 15.0:
		dev_tiles = 1
	elif miss_margin <= 35.0:
		dev_tiles = 2
	else:
		dev_tiles = 3

	var intended_pos: Vector2i = defender.grid_position

	# Exclude the direction pointing back toward the attacker so the shot never reverses
	var back_dir := Vector2i(
		signi(attacker.grid_position.x - intended_pos.x),
		signi(attacker.grid_position.y - intended_pos.y)
	)
	var valid_dirs: Array[Vector2i] = []
	for d: Vector2i in DIRS_8:
		if d != back_dir:
			valid_dirs.append(d)

	var dir: Vector2i = valid_dirs[randi() % valid_dirs.size()]
	var landing := intended_pos + dir * dev_tiles

	# Clamp to grid bounds
	if combat_grid != null:
		landing.x = clampi(landing.x, 0, combat_grid.grid_size.x - 1)
		landing.y = clampi(landing.y, 0, combat_grid.grid_size.y - 1)

	var dev_result := {
		"deviation_tiles": dev_tiles,
		"deviation_landing_pos": landing,
		"deviation_hit_unit_name": "",
		"deviation_hit_team": -1,
		"deviation_damage": 0
	}

	# Check if any living unit occupies the landing tile.
	# Explicitly exclude the original defender — a miss should never hit them as a stray.
	var stray_target := get_unit_at(landing)
	if stray_target != null and stray_target != defender and stray_target.is_alive():
		var dmg_type: String = attacker.get_weapon_damage_type() if attacker.has_method("get_weapon_damage_type") else "physical"
		var dmg_result := calculate_physical_damage(attacker, stray_target, dmg_type)
		var dmg: int = dmg_result.get("damage", 0)
		apply_damage(stray_target, dmg, dmg_type)
		dev_result["deviation_hit_unit_name"] = stray_target.unit_name
		dev_result["deviation_hit_team"] = stray_target.team
		dev_result["deviation_damage"] = dmg
		combat_log.emit("  Projectile deviates %d tile(s) — stray hit on %s for %d!" % [
			dev_tiles, stray_target.unit_name, dmg
		])
	else:
		combat_log.emit("  Projectile deviates %d tile(s) — lands wide." % dev_tiles)

	return dev_result


## Calculate hit chance (percentage)
## Returns the hit chance and stores cover info in _last_cover_result for logging
var _last_cover_result: Dictionary = {}

func calculate_hit_chance(attacker: Node, defender: Node) -> float:
	var base_chance = 80.0
	var accuracy = attacker.get_accuracy()
	var dodge = defender.get_dodge()

	var hit_chance = base_chance + accuracy - dodge

	# Every Opening Is an Invitation: +15% accuracy against enemies with any status effect
	var att_char = attacker.character_data if "character_data" in attacker else {}
	if PerkSystem.has_perk(att_char, "every_opening_is_an_invitation"):
		if "status_effects" in defender and defender.status_effects.size() > 0:
			hit_chance += 15.0

	# Close and Personal: +15% accuracy when adjacent to exactly one enemy
	if PerkSystem.has_perk(att_char, "close_and_personal"):
		var adjacent_enemies = _get_enemies_in_range(attacker, 1)
		if adjacent_enemies.size() == 1:
			hit_chance += 15.0

	# Disciplined Formation: +10% accuracy while adjacent to an ally
	if PerkSystem.has_perk(att_char, "disciplined_formation"):
		if _get_allies_in_range(attacker, 1).size() > 0:
			hit_chance += 10.0

	# Water Finds the Gap: spear attacks vs enemies who moved last turn +15% accuracy
	if PerkSystem.has_perk(att_char, "water_finds_the_gap"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "spear":
				if "moved_this_turn" in defender and defender.moved_this_turn:
					hit_chance += 15.0

	# Offhand Jab: +10% accuracy when main weapon is a dagger AND off-hand slot also holds a dagger
	if PerkSystem.has_perk(att_char, "offhand_jab"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				var oh_id = att_char.get("equipment", {}).get("weapon_off", "")
				if oh_id != "" and ItemSystem.get_item(oh_id).get("type", "") == "dagger":
					hit_chance += 10.0

	# Too Fast to Count: first dagger attack each turn is guaranteed to hit
	if PerkSystem.has_perk(att_char, "too_fast_to_count"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				if "dagger_attacks_this_turn" in attacker and attacker.dagger_attacks_this_turn == 0:
					hit_chance = 95.0  # clamp max ensures guaranteed hit

	# One Breath, One Arrow: first ranged attack each turn gains +15% accuracy
	if PerkSystem.has_perk(att_char, "one_breath_one_arrow"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if "ranged_attacks_this_turn" in attacker and attacker.ranged_attacks_this_turn == 0:
				hit_chance += 15.0

	# Crushing Depths (Water 4): +15% accuracy vs enemies on water/ice terrain or with 2+ water debuffs
	if PerkSystem.has_perk(att_char, "crushing_depths"):
		var crushing_bonus = false
		# Check terrain at defender's position
		if combat_grid and "grid_position" in defender:
			var terrain_eff = combat_grid.get_terrain_effect(defender.grid_position)
			if terrain_eff in [2, 7]:  # ICE=2, WET=7
				crushing_bonus = true
		# Or check for 2+ water-type debuffs
		if not crushing_bonus and "status_effects" in defender:
			var water_debuffs = ["Slowed", "Frozen", "Chilled", "Waterlogged", "Rooted"]
			var wdc = 0
			for se in defender.status_effects:
				if se.get("status", "") in water_debuffs:
					wdc += 1
			if wdc >= 2:
				crushing_bonus = true
		if crushing_bonus:
			hit_chance += 15.0

	# Wall of Points: attacker suffers -10% accuracy when within 2 tiles of a spear-wielding defender
	var def_char_wop = defender.character_data if "character_data" in defender else {}
	if PerkSystem.has_perk(def_char_wop, "wall_of_points"):
		if defender.has_method("get_equipped_weapon") and defender.get_equipped_weapon().get("type", "") == "spear":
			if _grid_distance(attacker.grid_position, defender.grid_position) <= 2:
				hit_chance -= 10.0

	# Call the Shot (Leadership 1): marked targets are easier to hit — +15% accuracy
	# The mark is consumed on the first damaging hit (see calculate_physical_damage)
	if "is_marked" in defender and defender.is_marked:
		hit_chance += 15.0

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

	# Call the Shot (Leadership 1): next ally to attack a marked target gets +15% accuracy
	for ally in get_team_units(attacker.team if "team" in attacker else 0):
		if "marked_target" in ally and ally.marked_target == defender:
			hit_chance += 15.0
			break  # only check, don't clear — damage calc clears it

	# Ally flank defense: each adjacent ally standing on the defender's exact flank tile
	# reduces hit chance by 10% (shields the flanks — enables shieldwall tactics)
	if "facing" in defender and "grid_position" in defender and defender.facing != Vector2i.ZERO:
		var df = defender.facing
		var left_flank  = defender.grid_position + Vector2i(-df.y,  df.x)
		var right_flank = defender.grid_position + Vector2i( df.y, -df.x)
		for ally in get_team_units(defender.team if "team" in defender else 0):
			if ally == defender or ally.is_dead or ally.is_bleeding_out:
				continue
			if ally.grid_position == left_flank or ally.grid_position == right_flank:
				hit_chance -= 10.0

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
	# Every Opening Is an Invitation: +10% crit against enemies with any status effect
	var att_char_eoia = attacker.character_data if "character_data" in attacker else {}
	if PerkSystem.has_perk(att_char_eoia, "every_opening_is_an_invitation"):
		if "status_effects" in defender and defender.status_effects.size() > 0:
			crit_chance += 10.0

	# Cheap Shot (Guile 1): +15% crit on the first attack vs each individual enemy
	if PerkSystem.has_perk(att_char_eoia, "cheap_shot"):
		if not ("enemies_hit_this_combat" in attacker and defender in attacker.enemies_hit_this_combat):
			crit_chance += 15.0

	# Offhand Jab: +5% crit when main and off-hand are both daggers
	if PerkSystem.has_perk(att_char_eoia, "offhand_jab"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			var oh_id_oj = att_char_eoia.get("equipment", {}).get("weapon_off", "")
			if oh_id_oj != "" and ItemSystem.get_item(oh_id_oj).get("type", "") == "dagger":
				crit_chance += 5.0

	# Clean Line: +10% crit vs isolated targets (no allies adjacent to defender)
	if PerkSystem.has_perk(att_char_eoia, "clean_line"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			var def_has_adj_ally = false
			for u in get_team_units(defender.team if "team" in defender else 1):
				if u == defender:
					continue
				if _grid_distance(u.grid_position, defender.grid_position) <= 1:
					def_has_adj_ally = true
					break
			if not def_has_adj_ally:
				crit_chance += 10.0

	# Facing zone: positional bonuses based on where attacker stands relative to defender's facing
	# Rear gives +20% crit chance; flank and rear both give +20% damage (applied after armor below)
	var _facing_zone = _get_facing_zone(attacker.grid_position, defender)
	if _facing_zone == "rear":
		crit_chance += 20.0

	# Backstab (Daggers perk): dagger + stealth required for the full perk bonus.
	# Works from flank or rear only — impossible from front.
	var _backstab_triggered = false
	if PerkSystem.has_perk(att_char_eoia, "backstab"):
		var is_dagger_bs = attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger"
		var is_stealthed_bs = "is_stealthed" in attacker and attacker.is_stealthed
		if is_dagger_bs and is_stealthed_bs and _facing_zone in ["flank", "rear"]:
			# Rear gives bigger bonus (+35%) than flank (+25%)
			crit_chance += 35.0 if _facing_zone == "rear" else 25.0
			_backstab_triggered = true
			if defender.has_method("show_combat_text"):
				var bs_crit = 35 if _facing_zone == "rear" else 25
				defender.show_combat_text("Backstab! +%d%% crit" % bs_crit, Color(0.75, 0.1, 0.9))

	var crit = randf() * 100.0 <= crit_chance
	# Backstab crits deal 2x damage (replacing the 1.5x standard multiplier)
	var crit_multi = 2.0 if (_backstab_triggered and crit) else 1.5

	if crit:
		damage = int(damage * crit_multi)

	# Hard Knuckles: unarmed attacks ignore 25% of target's Armor
	var att_char_phys = attacker.character_data if "character_data" in attacker else {}
	var is_unarmed_attack = false
	if attacker.has_method("get_equipped_weapon"):
		var w = attacker.get_equipped_weapon()
		is_unarmed_attack = w.is_empty() or w.get("type", "") in ["", "unarmed"]

	# Anatomy Knowledge: +10% damage vs biological enemies
	if PerkSystem.has_perk(att_char_phys, "anatomy_knowledge") and _unit_is_biological(defender):
		damage = int(damage * 1.10)

	# Close and Personal: +15% damage when adjacent to exactly one enemy
	if PerkSystem.has_perk(att_char_phys, "close_and_personal"):
		var adjacent_enemies = _get_enemies_in_range(attacker, 1)
		if adjacent_enemies.size() == 1:
			damage = int(damage * 1.15)

	# Apply armor (flat reduction)
	var armor = defender.get_armor()
	if crit:
		armor = int(armor * 0.5)  # Crits ignore 50% armor

	# Hard Knuckles reduces effective armor by 25% for unarmed attacks
	if PerkSystem.has_perk(att_char_phys, "hard_knuckles") and is_unarmed_attack:
		armor = int(armor * 0.75)
	# Water Finds the Gap: spear vs target who moved — ignore 15% armor
	if PerkSystem.has_perk(att_char_phys, "water_finds_the_gap"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "spear":
				if "moved_this_turn" in defender and defender.moved_this_turn:
					armor = int(armor * 0.85)

	# Between the Ribs: daggers ignore 25% of the target's armor
	if PerkSystem.has_perk(att_char_phys, "between_the_ribs"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			armor = int(armor * 0.75)

	# One Breath, One Arrow: first ranged attack that crits ignores all armor
	if PerkSystem.has_perk(att_char_phys, "one_breath_one_arrow") and crit:
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if "ranged_attacks_this_turn" in attacker and attacker.ranged_attacks_this_turn == 0:
				armor = 0

	# Weapon armor pierce — flat reduction to effective armor before damage
	if attacker.has_method("get_armor_pierce"):
		var pierce = attacker.get_armor_pierce()
		if pierce > 0:
			armor = maxi(0, armor - pierce)

	damage = maxi(1, damage - armor)

	# Facing zone damage bonus (applied post-armor so it amplifies effective damage)
	if _facing_zone == "flank":
		damage = int(damage * 1.20)
		combat_log.emit("%s attacks from the flank! (+20%% dmg)" % attacker.unit_name)
		if not _backstab_triggered and defender.has_method("show_combat_text"):
			defender.show_combat_text("Flanking! +20%", Color(1.0, 0.65, 0.0))
	elif _facing_zone == "rear":
		damage = int(damage * 1.20)
		combat_log.emit("%s attacks from behind! (+20%% dmg, +20%% crit)" % attacker.unit_name)
		if not _backstab_triggered and defender.has_method("show_combat_text"):
			defender.show_combat_text("From Behind! +20%", Color(1.0, 0.45, 0.0))

	# Hit Back Harder (Might 3): +20% melee damage after taking any damage; consumed on first attack
	if "hit_back_ready" in attacker and attacker.hit_back_ready:
		var is_melee_hbh = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_hbh:
			damage = int(damage * 1.20)
			attacker.hit_back_ready = false

	# Permafrost (Water 5): Frozen enemies take +30% all damage
	if defender.has_status("Frozen"):
		damage = int(damage * 1.30)

	# Steady Aim: +10% damage if didn't move this turn (ranged only)
	if PerkSystem.has_perk(att_char_phys, "steady_aim"):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			if not ("moved_this_turn" in attacker and attacker.moved_this_turn):
				damage = int(damage * 1.10)

	# Sudden End (Daggers 7): first stealth attack deals +100% crit damage vs any target
	# (bleed is applied in _process_on_hit_perks after the hit lands)
	if PerkSystem.has_perk(att_char_phys, "sudden_end"):
		if "is_stealthed" in attacker and attacker.is_stealthed:
			if not crit:
				# Force crit multiplier even if not a crit (stealth backstab)
				damage = int(damage * 2.0)
			else:
				# Already crit — add 100% on top (brutal stealth crit)
				damage = int(damage * 2.0)

	# Skull Crack: +20% damage vs Stunned or Dazed targets (maces only)
	if PerkSystem.has_perk(att_char_phys, "skull_crack"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			if defender.has_status("Stunned") or defender.has_status("Dazed"):
				damage = int(damage * 1.20)

	# Call the Shot (Leadership 1): +15% damage on first ally attack vs marked target; clears mark
	for ally_cts in get_team_units(attacker.team if "team" in attacker else 0):
		if "marked_target" in ally_cts and ally_cts.marked_target == defender:
			damage = int(damage * 1.15)
			ally_cts.marked_target = null  # consume the mark
			if "is_marked" in defender:
				defender.is_marked = false  # sync both mark representations
			combat_log.emit("Called shot lands! +15% damage.")
			break

	# Apply physical resistance (checks specific subtype first, then falls back to generic "physical")
	var phys_resist = defender.get_resistance(dmg_type)
	damage = int(damage * (1.0 - phys_resist / 100.0))
	damage = maxi(1, damage)

	# Lord of Death DY: empowered summons deal 30% bonus damage
	if "lord_of_death_empowered" in attacker and attacker.lord_of_death_empowered:
		damage = int(damage * 1.3)

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

	# Feed the Fire (Fire 3): +20% fire spell damage vs Burning targets
	var caster_char_ff = caster.character_data if "character_data" in caster else {}
	if element == "fire" and PerkSystem.has_perk(caster_char_ff, "feed_the_fire"):
		if target.has_status("Burning"):
			damage = int(damage * 1.20)

	# Permafrost (Water 5): Frozen targets take +30% all damage
	if target.has_status("Frozen"):
		damage = int(damage * 1.30)

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
	# God mode: player units take no damage
	if CheatConsole and CheatConsole.god_mode and "team" in unit and unit.team == Team.PLAYER:
		unit_damaged.emit(unit, 0, damage_type)
		return
	unit.take_damage(damage)
	unit_damaged.emit(unit, damage, damage_type)
	# Hit Back Harder (Might 3): taking damage sets a ready flag for +20% bonus on next melee attack
	if damage > 0 and unit.is_alive() and "hit_back_ready" in unit:
		var char_data = unit.character_data if "character_data" in unit else {}
		if PerkSystem.has_perk(char_data, "hit_back_harder"):
			unit.hit_back_ready = true

	# Taking damage breaks Pacified (dispel_methods includes "taking_damage")
	if damage > 0 and "status_effects" in unit:
		var to_remove: Array[int] = []
		for i in range(unit.status_effects.size()):
			var sname = unit.status_effects[i].get("status", "")
			var sdef = _status_effects.get(sname, {})
			if "taking_damage" in sdef.get("dispel_methods", []):
				to_remove.append(i)
		to_remove.reverse()
		for idx in to_remove:
			var sname = unit.status_effects[idx].get("status", "")
			unit.status_effects.remove_at(idx)
			if unit.has_method("show_status_expired"):
				unit.show_status_expired(sname)
			status_effect_expired.emit(unit, sname)

	# Glass_Globe: shatters on any damage, dealing slashing AoE + guaranteed Bleeding to nearby enemies.
	# Fires even on lethal hits (the globe shatters as the bearer falls).
	if damage > 0 and unit.has_status("Glass_Globe"):
		var globe_def = _status_effects.get("Glass_Globe", {})
		var shatter = globe_def.get("special", {}).get("shatters_on_damage_received", {})
		var shatter_dmg: int = shatter.get("damage", 20)
		var shatter_radius: int = shatter.get("radius", 2)
		# Remove the status first so the shatter itself can't re-trigger
		for i in range(unit.status_effects.size() - 1, -1, -1):
			if unit.status_effects[i].get("status", "") == "Glass_Globe":
				unit.status_effects.remove_at(i)
				if unit.has_method("show_status_expired"):
					unit.show_status_expired("Glass_Globe")
				status_effect_expired.emit(unit, "Glass_Globe")
				break
		combat_log.emit("%s's Glass Globe shatters! Razor shards fly outward!" % unit.unit_name)
		for nearby in _get_enemies_in_range(unit, shatter_radius):
			apply_damage(nearby, shatter_dmg, "slashing")
			_apply_status_effect(nearby, "Bleeding", 3, 0, null)

	# Crystal_Diadem: 50% chance (configurable) to shatter and be lost on any damage received.
	if damage > 0 and unit.has_status("Crystal_Diadem"):
		var diadem_def = _status_effects.get("Crystal_Diadem", {})
		var lose_chance: int = diadem_def.get("special", {}).get("chance_to_lose_on_damage_received", 50)
		if randi() % 100 < lose_chance:
			for i in range(unit.status_effects.size() - 1, -1, -1):
				if unit.status_effects[i].get("status", "") == "Crystal_Diadem":
					unit.status_effects.remove_at(i)
					if unit.has_method("show_status_expired"):
						unit.show_status_expired("Crystal_Diadem")
					status_effect_expired.emit(unit, "Crystal_Diadem")
					break
			combat_log.emit("%s's Crystal Diadem shatters!" % unit.unit_name)

	if unit.current_hp <= 0 and not unit.is_bleeding_out:
		_start_bleed_out(unit)
		# Check if combat should end immediately (all enemies or all players down)
		_check_immediate_combat_end()

	# Heavy hit: ≥15% of max HP breaks concentration
	# Uses post-absorption damage (what was actually received). This is intentional:
	# attacks reduced below 15% effective damage by armor do not disrupt mantras.
	if damage > 0 and unit.is_alive():
		var max_hp = unit.max_hp
		if max_hp > 0 and float(damage) / float(max_hp) >= 0.15:
			_interrupt_mantras(unit, "%s's concentration breaks from the heavy blow!" % unit.unit_name)


## Start bleed-out state for a unit
func _start_bleed_out(unit: Node) -> void:
	unit.is_bleeding_out = true
	unit.bleed_out_turns = BLEED_OUT_TURNS
	unit.current_hp = 0
	AudioManager.play("debuff_apply")
	unit_bleeding_out.emit(unit, BLEED_OUT_TURNS)


## Permanently kill a unit
func _kill_unit(unit: Node) -> void:
	unit.is_dead = true
	unit.is_bleeding_out = false
	AudioManager.play("debuff_apply")

	# Witnessing a party member die affects all other player units emotionally
	if unit.team == Team.PLAYER:
		for other_unit in all_units:
			if other_unit == unit or other_unit.team != Team.PLAYER:
				continue
			if "character_data" in other_unit:
				PsychologySystem.apply_pressure(other_unit.character_data, "water", -15.0)

	unit_died.emit(unit)

	# Shadow Strike (Daggers 3 + Guile 3): killing an enemy enters stealth
	# Ambush Predator: kills from stealth immediately reset stealth (no gap)
	var killer = unit.get("last_attacker")
	if killer != null and not killer.is_dead:
		var killer_char_ss = killer.character_data if "character_data" in killer else {}
		var was_stealthed = "is_stealthed" in killer and killer.is_stealthed
		if PerkSystem.has_perk(killer_char_ss, "shadow_strike"):
			_enter_stealth(killer)
		elif was_stealthed and PerkSystem.has_perk(killer_char_ss, "ambush_predator"):
			_enter_stealth(killer)  # Reset stealth immediately (kill from stealth)
			combat_log.emit("%s remains in shadow (Ambush Predator)!" % killer.unit_name)

		# Gone Before the Body Falls (Daggers 9): dagger kill → restore 1 action
		if PerkSystem.has_perk(killer_char_ss, "gone_before_the_body_falls"):
			if killer.has_method("get_equipped_weapon") and killer.get_equipped_weapon().get("type", "") == "dagger":
				killer.actions_remaining = mini(killer.actions_remaining + 1, killer.max_actions)
				combat_log.emit("%s: Gone Before the Body Falls — free action!" % killer.unit_name)

	# Dharma Warrior (cross-skill): killing an enemy during mantra chanting advances each active mantra by +1
	if killer != null and not killer.is_dead and not killer.active_mantras.is_empty():
		var killer_char_dw = killer.character_data if "character_data" in killer else {}
		if PerkSystem.has_perk(killer_char_dw, "dharma_warrior"):
			for m_id in killer.active_mantras:
				killer.active_mantras[m_id] += 1
			combat_log.emit("%s: Dharma Warrior — kill advances mantra!" % killer.unit_name)

	# Risen Dead talisman perk: 15% chance the slain enemy rises as an allied undead
	if killer != null and not killer.is_dead and _unit_has_talisman_perk(killer, "risen_dead"):
		if randf() < 0.15 and combat_grid != null:
			# Build a simplified undead enemy def from the dead unit's data
			var risen_def: Dictionary = unit.character_data.duplicate(true)
			risen_def["name"] = "Risen " + unit.unit_name
			var risen_derived = risen_def.get("derived", {}).duplicate()
			risen_derived["max_hp"] = maxi(1, risen_derived.get("max_hp", 20) / 2)
			risen_derived["current_hp"] = risen_derived["max_hp"]
			risen_def["derived"] = risen_derived

			# Create a new CombatUnit for the risen undead, on the killer's team
			var risen = CombatUnit.new()
			risen.init_as_enemy(risen_def)
			risen.team = killer.team

			# Find a nearby unoccupied tile to place it
			var spawn_pos = Vector2i(-1, -1)
			var dead_pos = unit.grid_position
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var candidate = dead_pos + Vector2i(dx, dy)
					if combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_pos = candidate
						break
				if spawn_pos != Vector2i(-1, -1):
					break

			if spawn_pos != Vector2i(-1, -1):
				combat_grid.place_unit(risen, spawn_pos)
				all_units.append(risen)
				# Insert into turn order right after current unit so it acts next round
				turn_order.append(risen)
				unit_deployed.emit(risen, spawn_pos)

	# Necromancer (Black 3 + Summoning 3): kill → spend 10 Mana to raise undead at 50% stats, max 2 per combat
	if killer != null and not killer.is_dead and killer.necromancer_raises < 2:
		var killer_char_nc = killer.character_data if "character_data" in killer else {}
		if PerkSystem.has_perk(killer_char_nc, "necromancer") and killer.current_mana >= 10 and combat_grid != null:
			killer.current_mana -= 10
			killer.necromancer_raises += 1
			var nc_def: Dictionary = unit.character_data.duplicate(true)
			nc_def["name"] = "Risen " + unit.unit_name
			var nc_derived = nc_def.get("derived", {}).duplicate()
			nc_derived["max_hp"] = maxi(1, nc_derived.get("max_hp", 20) / 2)
			nc_derived["current_hp"] = nc_derived["max_hp"]
			nc_derived["max_mana"] = 0
			nc_derived["current_mana"] = 0
			nc_def["derived"] = nc_derived
			# Strip spells so the risen just attacks
			nc_def["known_spells"] = []

			var nc_unit = CombatUnit.new()
			nc_unit.init_as_enemy(nc_def)
			nc_unit.team = killer.team

			var nc_pos = Vector2i(-1, -1)
			var nc_dead_pos = unit.grid_position
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var candidate = nc_dead_pos + Vector2i(dx, dy)
					if combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						nc_pos = candidate
						break
				if nc_pos != Vector2i(-1, -1):
					break

			if nc_pos != Vector2i(-1, -1):
				combat_grid.place_unit(nc_unit, nc_pos)
				all_units.append(nc_unit)
				turn_order.append(nc_unit)
				unit_deployed.emit(nc_unit, nc_pos)
				combat_log.emit("%s raises %s! (%d/2 this combat)" % [killer.unit_name, nc_unit.unit_name, killer.necromancer_raises])

	# Cleave (Axes cross): kill → free attack on the nearest adjacent enemy
	_trigger_cleave(killer, unit.grid_position)

	# Lord of Death DY: 40% chance to raise a zombie/skeleton when an enemy dies near a registered caster
	var dead_pos = unit.grid_position
	for lod_caster in _lord_of_death_casters:
		if lod_caster == null or lod_caster.is_dead:
			continue
		# Only trigger if the dead unit was on the opposing team
		if "team" in unit and "team" in lod_caster and unit.team == lod_caster.team:
			continue
		if _grid_distance(dead_pos, lod_caster.grid_position) > 4:
			continue
		if randf() < 0.40:
			var undead_template = ["zombie", "skeleton"][randi() % 2]
			_spawn_summoned_unit(lod_caster, undead_template, dead_pos, 0)
			combat_log.emit("The Lord of Death claims %s's soul!" % unit.unit_name)
			break  # Only one resurrection per death event

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
				# Default range based on spell tier (level 1,3,5,7,9 → tier 1-5)
				var level = spell.get("level", 1)
				var tier = ceili(level / 2.0)  # 1→1, 2→1, 3→2, 4→2, 5→3, 7→4, 9→5
				spell["range"] = 3 + tier  # Range 4-8 based on tier
		elif raw_range is int or raw_range is float:
			spell["range"] = int(raw_range)
		else:
			var level = spell.get("level", 1)
			var tier = ceili(level / 2.0)
			spell["range"] = 3 + tier

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

	# Check skill requirements - need at least one school at required skill level.
	# The spell's "level" field IS the minimum skill level required (1,2,3,4,5,7,9).
	var required_skill_level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var has_skill = false

	for school in schools:
		# Lowercase school name for comparison (spells.json uses capitalized names)
		var school_lower = school.to_lower()
		var skill_name = school_lower + "_magic" if school_lower in ["earth", "water", "fire", "air", "space", "white", "black"] else school_lower
		var skill_level = skills.get(skill_name, 0)
		if skill_level >= required_skill_level:
			has_skill = true
			break

	if not has_skill:
		return {"success": false, "reason": "Insufficient skill level"}

	return {"success": true}


## Cast a spell
func cast_spell(caster: Node, spell_id: String, target_pos: Vector2i) -> Dictionary:
	if not can_act(1):
		return {"success": false, "reason": "No actions remaining"}

	# Silenced / blinded units cannot cast spells
	if not can_unit_cast(caster):
		return {"success": false, "reason": "Cannot cast while silenced"}

	# Stealth: spell casting breaks stealth unless invisible or Shady Dealings
	if "is_stealthed" in caster and caster.is_stealthed:
		var _is_inv = caster.has_status("Invisible") if caster.has_method("has_status") else false
		if _is_inv:
			# Invisible: casting consumes the Invisible status, stealth persists
			_remove_status_by_name(caster, "Invisible")
			combat_log.emit("%s's invisibility shatters from spellcasting — but remains hidden." % caster.unit_name)
		else:
			var caster_char_sd = caster.character_data if "character_data" in caster else {}
			if not PerkSystem.has_perk(caster_char_sd, "shady_dealings"):
				_leave_stealth(caster)
				combat_log.emit("%s breaks stealth by casting a spell!" % caster.unit_name)
			elif _shady_dealings_detected(caster):
				_leave_stealth(caster)
				combat_log.emit("An enemy detected %s casting despite Shady Dealings!" % caster.unit_name)
			else:
				combat_log.emit("%s casts from the shadows (Shady Dealings)." % caster.unit_name)

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

	# Update caster facing toward target (non-self spells)
	if targeting != "self" and "facing" in caster and target_pos != caster.grid_position:
		caster.facing = _dir_toward(caster.grid_position, target_pos)

	# Self-targeting spells don't need range check
	if targeting != "self":
		var distance = _spell_distance(caster.grid_position, target_pos)
		if distance > spell_range:
			return {"success": false, "reason": "Target out of range"}

	# Get targets based on targeting type
	var summon_id = spell.get("summon", "")
	var targets = _get_spell_targets(caster, spell, target_pos)
	# Ground-targeting (summoning) spells don't need a unit target — just a valid tile
	if targets.is_empty() and targeting != "self" and targeting != "ground":
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

	# Perk-based mana cost reductions (multiplicative with charm reduction)
	var caster_char_perks = caster.character_data if "character_data" in caster else {}
	# Clean Cast (Sorcery 1): Sorcery spells cost 10% less mana
	if PerkSystem.has_perk(caster_char_perks, "clean_cast"):
		if spell.get("schools", []).any(func(s): return s.to_lower() == "sorcery"):
			mana_cost = int(mana_cost * 0.90)
	# Efficient Enchanting (Enchantment 1): Enchantment spells cost 10% less mana
	if PerkSystem.has_perk(caster_char_perks, "efficient_enchanting"):
		if spell.get("schools", []).any(func(s): return s.to_lower() == "enchantment"):
			mana_cost = int(mana_cost * 0.90)

	# Overcast bonus: push_the_words, burn_the_breath, one_perfect_sentence, grand_working
	# Consume the queued bonus and apply mana cost multiplier
	var _overcast: Dictionary = {}
	if "pending_overcast_bonus" in caster and not caster.pending_overcast_bonus.is_empty():
		_overcast = caster.pending_overcast_bonus
		caster.pending_overcast_bonus = {}
		var mana_mult = _overcast.get("mana_cost_multiplier", 1.0)
		mana_cost = int(mana_cost * mana_mult)
		combat_log.emit("%s casts with overcast power!" % caster.unit_name)

	# Damaru rhythm charge discount: at 3 charges → 40% off mana cost, then reset
	if "damaru_charges" in caster and caster.damaru_charges >= 3:
		mana_cost = int(mana_cost * 0.60)
		caster.damaru_charges = 0
		combat_log.emit("%s's Damaru rhythm peaks — spell costs 40%% less mana!" % caster.unit_name)

	# Deduct mana (sync to character_data so it persists after combat)
	caster.current_mana -= mana_cost
	var caster_derived = caster.character_data.get("derived", {})
	caster_derived["current_mana"] = caster.current_mana

	# Overcast self-damage (burn_the_breath: caster takes damage equal to % of mana spent)
	if not _overcast.is_empty():
		var self_dmg_pct = _overcast.get("self_damage_pct_of_mana", 0)
		if self_dmg_pct > 0:
			var self_dmg = ceili(mana_cost * self_dmg_pct / 100.0)
			apply_damage(caster, self_dmg, "fire")
			combat_log.emit("%s burns from the overcast! (%d self-damage)" % [caster.unit_name, self_dmg])

	# Calculate spell power bonus from all applicable schools
	var spellpower_bonus = _calculate_spell_bonus(caster, spell)

	# Apply overcast spellpower multiplier
	if not _overcast.is_empty():
		var sp_pct = _overcast.get("spellpower_bonus_pct", 0)
		if sp_pct > 0:
			spellpower_bonus = int(spellpower_bonus * (1.0 + sp_pct / 100.0))

	# Spell Like a Knife (Sorcery 5): killing with Sorcery grants +50% Spellpower on next spell
	if "sorcery_kill_bonus_ready" in caster and caster.sorcery_kill_bonus_ready:
		spellpower_bonus = int(spellpower_bonus * 1.50)
		caster.sorcery_kill_bonus_ready = false

	# Add charm spellpower bonus (percentage of base spellpower)
	if not charm_used.is_empty():
		var charm_sp_pct = charm_used.get("spellpower_bonus", 0.0)
		if charm_sp_pct > 0:
			spellpower_bonus += int(spellpower_bonus * charm_sp_pct)

	# Terrain affinity: caster standing on matching elemental terrain gets +25% spellpower;
	# opposed terrain (blessed vs black, cursed vs white) gives -15%.
	if combat_grid != null:
		var caster_tile = combat_grid.tiles.get(caster.grid_position)
		if caster_tile != null and caster_tile.has_effect():
			var spell_schools_lower = spell.get("schools", []).map(func(s): return s.to_lower())
			var terrain_sp_pct := 0.0
			var terrain_label := ""
			match caster_tile.effect:
				CombatGrid.TerrainEffect.FIRE:
					if "fire" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "fire"
				CombatGrid.TerrainEffect.ICE, CombatGrid.TerrainEffect.WET:
					if "water" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "water"
				CombatGrid.TerrainEffect.STORMY:
					if "air" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "air"
				CombatGrid.TerrainEffect.POISON, CombatGrid.TerrainEffect.ACID:
					if "earth" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "earth"
				CombatGrid.TerrainEffect.VOID:
					if "space" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "void"
				CombatGrid.TerrainEffect.BLESSED:
					if "white" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "blessed"
					elif "black" in spell_schools_lower:
						terrain_sp_pct = -0.15
						terrain_label = "blessed (opposed)"
				CombatGrid.TerrainEffect.CURSED:
					if "black" in spell_schools_lower:
						terrain_sp_pct = 0.25
						terrain_label = "cursed"
					elif "white" in spell_schools_lower:
						terrain_sp_pct = -0.15
						terrain_label = "cursed (opposed)"
			if terrain_sp_pct != 0.0:
				var delta = int(spellpower_bonus * terrain_sp_pct)
				spellpower_bonus += delta
				if delta > 0:
					combat_log.emit("%s draws power from the %s terrain! (+%d spellpower)" % [caster.unit_name, terrain_label, delta])
				else:
					combat_log.emit("%s is weakened by the %s terrain! (%d spellpower)" % [caster.unit_name, terrain_label, delta])

	# --- Summoning spells: spawn a unit instead of applying effects to targets ---
	if summon_id != "" and targeting == "ground":
		use_action(1)
		var summon_result = _spawn_summoned_unit(caster, summon_id, target_pos, spellpower_bonus)
		spell_cast.emit(caster, spell, [], [summon_result])
		return {"success": true, "spell": spell, "targets": [], "results": [summon_result], "mana_cost": mana_cost}

	# --- Ground-effect spells: place terrain effects at target location ---
	# e.g. smoke_cloud — blocks_line_of_sight in spell.special means SMOKE terrain
	if targeting == "ground" and spell.get("special", {}).get("blocks_line_of_sight", false):
		use_action(1)
		var aoe_radius = spell.get("aoe", {}).get("base_size", 1)
		var duration = spellpower_bonus if spell.get("duration", 0) == "spellpower" else int(spell.get("duration", 3))
		if duration <= 0:
			duration = 3
		var tiles_in_area = combat_grid.get_tiles_in_radius(target_pos, aoe_radius)
		for pos in tiles_in_area:
			var tile = combat_grid.tiles.get(pos)
			if tile != null and tile.walkable:
				combat_grid.add_terrain_effect(pos, CombatGrid.TerrainEffect.SMOKE, duration)
		combat_log.emit("%s casts Smoke Cloud — sight blocked for %d turns!" % [caster.unit_name, duration])
		var ground_result = {"effect": "smoke", "tiles_affected": tiles_in_area.size(), "duration": duration}
		spell_cast.emit(caster, spell, [], [ground_result])
		_process_spell_cast_perks(caster, null, spell, ground_result)
		return {"success": true, "spell": spell, "targets": [], "results": [ground_result], "mana_cost": mana_cost}

	# Apply effects to each target
	var results: Array[Dictionary] = []
	var is_offensive = _spell_is_offensive(spell)
	for target in targets:
		# Talisman: Magic Mirror — 10% chance to reflect hostile spells back at caster
		if is_offensive and target != caster and _unit_has_talisman_perk(target, "magic_mirror"):
			if randf() < 0.10:
				# Reflect! Apply spell to caster instead
				var reflect_result = _apply_spell_effects(caster, caster, spell, spellpower_bonus)
				reflect_result["reflected"] = true
				results.append(reflect_result)
				if target.has_method("show_combat_text"):
					target.show_combat_text("Reflected!", Color(0.6, 0.3, 1.0))
				continue

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


## Unified status effect duration calculation.
## Spellpower sets the baseline (1 extra turn per 10 points).
## Enchantment skill adds on top for all status-causing spells (1 extra turn per 2 levels),
## making it the natural "duration" school regardless of the spell's elemental tag.
##
## Fixed integer durations in spells.json are intentional balance decisions and pass through
## unchanged (e.g. Stun for 1 turn, Entangle for 4 turns).
## Special strings ("permanent", "combat", "until_save", etc.) return the safe fallback
## of 3 turns — those spells rely on their status definition's own duration_type logic.
func _calculate_status_duration(caster: Node, spell: Dictionary, bonus: int) -> int:
	var dur_field = spell.get("duration", null)

	# Numeric: hard-coded duration — intentional balance decision, pass through unchanged
	if dur_field is int or dur_field is float:
		return int(dur_field)

	# "spellpower" or absent: apply unified formula
	if dur_field == "spellpower" or dur_field == null:
		var sp_contribution: int = int(bonus / 10)
		var enchantment_level: int = 0
		if "character_data" in caster:
			enchantment_level = caster.character_data.get("skills", {}).get("enchantment", 0)
		# Enchantment: +1 turn per 2 skill levels (Enc 2=+1 … Enc 10=+5)
		var enc_contribution: int = int(enchantment_level / 2)
		return maxi(1, 2 + sp_contribution + enc_contribution)

	# Special strings ("permanent", "combat", "until_save", "fixed", "until_destroyed"):
	# the status definition's duration_type field handles the real logic; return safe fallback
	return 3


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

			# Chains of Suffering: +15% Black spell damage vs targets with any debuff
			var caster_char = caster.character_data if "character_data" in caster else {}
			if element == "black" and PerkSystem.has_perk(caster_char, "chains_of_suffering"):
				if target.status_effects.size() > 0:
					total_damage = int(total_damage * 1.15)

			# Elementalist: +25% damage when targeting an elemental weakness (negative resistance)
			if PerkSystem.has_perk(caster_char, "elementalist"):
				if target.get_resistance(element) < 0:
					total_damage = int(total_damage * 1.25)

			# Variance ±15%
			var variance = randf_range(0.85, 1.15)
			total_damage = int(total_damage * variance)

			# Apply resistance
			var resistance = target.get_resistance(element)
			total_damage = int(total_damage * (1.0 - resistance / 100.0))
			total_damage = maxi(1, total_damage)

			# Lord of Death DY: empowered summons deal 30% bonus spell damage
			if "lord_of_death_empowered" in caster and caster.lord_of_death_empowered:
				total_damage = int(total_damage * 1.3)

			apply_damage(target, total_damage, element)
			result.effects_applied.append({"type": "damage", "amount": total_damage, "element": element})

	# --- Direct healing (from spell.heal) ---
	var base_heal = spell.get("heal", null)
	if base_heal != null and (base_heal is int or base_heal is float):
		if int(base_heal) > 0:
			var total_heal = int(base_heal) + int(bonus * 0.5)
			# Healing Waters (Water 1): Water healing spells are 15% more effective
			var caster_char_hw = caster.character_data if "character_data" in caster else {}
			var is_water_heal = spell.get("schools", []).any(func(s): return s.to_lower() == "water")
			if is_water_heal and PerkSystem.has_perk(caster_char_hw, "healing_waters"):
				total_heal = int(total_heal * 1.15)
			target.heal(total_heal)
			unit_healed.emit(target, total_heal)
			result.effects_applied.append({"type": "heal", "amount": total_heal})
			# Lingering Warmth (White 3): healing spells also apply regeneration (15% of heal over 3 turns)
			var is_white_heal = spell.get("schools", []).any(func(s): return s.to_lower() == "white")
			if is_white_heal and PerkSystem.has_perk(caster_char_hw, "lingering_warmth"):
				var regen_per_turn = maxi(1, int(total_heal * 0.15 / 3))
				_apply_status_effect(target, "Regenerating", 3, regen_per_turn, caster)
			# Purifying Stream (Water 2): Water healing spells also remove 1 negative status effect
			if is_water_heal and PerkSystem.has_perk(caster_char_hw, "purifying_stream"):
				_cleanse_status_effects(target, 1)

	# --- Status effects (from spell.statuses_caused) ---
	var statuses = spell.get("statuses_caused", [])
	if not statuses.is_empty():
		var duration: int = _calculate_status_duration(caster, spell, bonus)
		for status_name in statuses:
			_apply_status_effect(target, status_name, duration, 0, caster)
			result.effects_applied.append({"type": "status", "status": status_name, "applied": true})

	# --- Status effects on failed save (from spell.statuses_caused_on_failed_save) ---
	# Used by spells like metal_to_mud: all listed statuses are applied only if the target fails
	# a saving throw. save_type names an attribute ("constitution", "finesse", etc.)
	var save_statuses = spell.get("statuses_caused_on_failed_save", [])
	if not save_statuses.is_empty():
		var save_attr = spell.get("save_type", "constitution").to_lower()
		var save_duration: int = _calculate_status_duration(caster, spell, bonus)
		if not _perform_save_roll(target, save_attr):  # false = failed save = effect applies
			for status_name in save_statuses:
				_apply_status_effect(target, status_name, save_duration, 0, caster)
				result.effects_applied.append({"type": "status", "status": status_name, "applied": true})

	# --- Random status on failed save (from spell.on_failed_save_random_one_of) ---
	# Used by spells like rain_of_mud: one random status from the list is applied on failed save.
	var random_statuses = spell.get("on_failed_save_random_one_of", [])
	if not random_statuses.is_empty():
		var rand_save_attr = spell.get("save_type", "finesse").to_lower()
		var rand_duration: int = _calculate_status_duration(caster, spell, bonus)
		if not _perform_save_roll(target, rand_save_attr):
			var chosen_status = random_statuses[randi() % random_statuses.size()]
			_apply_status_effect(target, chosen_status, rand_duration, 0, caster)
			result.effects_applied.append({"type": "status", "status": chosen_status, "applied": true})

	# --- Status removal (from spell.statuses_removed) ---
	var statuses_removed = spell.get("statuses_removed", [])
	if not statuses_removed.is_empty():
		var cleansed = _cleanse_status_effects(target, statuses_removed.size())
		result.effects_applied.append({"type": "cleanse", "removed": cleansed})
		# Gentle Removal (White 1): cleansing spells also heal target for 20% of caster Spellpower
		var caster_char_gr = caster.character_data if "character_data" in caster else {}
		var is_white_cleanse = spell.get("schools", []).any(func(s): return s.to_lower() == "white")
		if is_white_cleanse and PerkSystem.has_perk(caster_char_gr, "gentle_removal") and cleansed > 0:
			var cleanse_heal = maxi(1, int(caster.get_spellpower() * 0.20))
			target.heal(cleanse_heal)
			unit_healed.emit(target, cleanse_heal)

	# --- Special effects (from spell.special) ---
	var special = spell.get("special", {})
	if not special.is_empty():
		_apply_spell_special(caster, target, spell, special, result)

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
					_apply_status_effect(target, status, duration, effect.get("value", 0), caster)
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

	# --- Post-effects: perk triggers on spell cast ---
	_process_spell_cast_perks(caster, target, spell, result)

	return result


## Spawn a summoned unit at or near target_pos on the caster's team.
## Called by cast_spell() when the spell has a "summon" key and "ground" targeting.
## Stats scale with the caster's Summoning skill level and spellpower bonus.
## Template data lives in resources/data/summon_templates.json (75 templates).
func _spawn_summoned_unit(caster: Node, summon_id: String, target_pos: Vector2i, spellpower_bonus: int) -> Dictionary:
	var template = _summon_templates.get(summon_id, {})
	if template.is_empty():
		push_warning("CombatManager: No summon template for: " + summon_id)
		# Fall back to a generic weak unit so the spell isn't a total no-op
		template = {
			"display_name": summon_id.replace("_", " "),
			"base_hp": 30, "base_mana": 0, "base_stamina": 40, "actions": 2,
			"base_damage": 8, "damage_type": "physical",
			"base_initiative": 10, "base_movement": 3,
			"base_dodge": 10, "base_armor": 0, "base_crit": 5, "base_accuracy": 0,
			"resistances": {}
		}

	# Scale factor based on caster's Summoning skill (0.5x at skill 0, 1.0x at skill 5, 1.5x at skill 10)
	var summoning_level: int = 0
	if "character_data" in caster:
		summoning_level = caster.character_data.get("skills", {}).get("summoning", 0)
	var scale: float = 0.5 + summoning_level / 10.0

	# Calculate scaled stats
	var scaled_hp = maxi(1, int(template.get("base_hp", 30) * scale) + spellpower_bonus * 2)
	var scaled_mana = int(template.get("base_mana", 0) * scale)
	var scaled_stamina = maxi(10, int(template.get("base_stamina", 40) * scale))
	var scaled_damage = maxi(1, int(template.get("base_damage", 5) * scale) + int(spellpower_bonus * 0.3))
	var scaled_initiative = template.get("base_initiative", 10)
	var scaled_movement = template.get("base_movement", 3)
	var scaled_dodge = template.get("base_dodge", 10)
	var scaled_armor = template.get("base_armor", 0)
	var scaled_crit = float(template.get("base_crit", 5))
	var scaled_accuracy = template.get("base_accuracy", 0)

	# Build character_data dict matching what init_as_enemy() and CombatUnit getters expect
	var summon_data: Dictionary = {
		"name": template.get("display_name", summon_id.replace("_", " ")),
		"archetype_name": "Summon",
		"max_hp": scaled_hp,
		"max_mana": scaled_mana,
		"actions": template.get("actions", 2),
		"resistances": template.get("resistances", {}).duplicate(),
		"inventory": [],
		"skills": {},
		"known_spells": [],
		"perks": [],
		"tags": template.get("tags", []),
		"derived": {
			"max_hp": scaled_hp,
			"current_hp": scaled_hp,
			"max_mana": scaled_mana,
			"current_mana": scaled_mana,
			"max_stamina": scaled_stamina,
			"current_stamina": scaled_stamina,
			"initiative": scaled_initiative,
			"movement": scaled_movement,
			"dodge": scaled_dodge,
			"armor": scaled_armor,
			"crit_chance": scaled_crit,
			"accuracy": scaled_accuracy,
			"damage": scaled_damage,
			"damage_type": template.get("damage_type", "physical"),
		},
		"equipped_weapon": {
			"name": "Natural Attack",
			"damage": scaled_damage,
			"damage_type": template.get("damage_type", "physical"),
			"range": 1
		}
	}

	# Create the CombatUnit node
	var summon_unit = CombatUnit.new()
	summon_unit.summoner_id = caster.get_instance_id()  # Track ownership for mantra effects
	summon_unit.init_as_enemy(summon_data)
	summon_unit.team = caster.team  # Summon fights on the caster's side
	# Jeweled Pagoda DY: if caster.next_summon_empowered is set, consume it and apply buffs
	if "next_summon_empowered" in caster and caster.next_summon_empowered:
		caster.next_summon_empowered = false
		# HP × 3, damage × 2
		var emp_hp = summon_unit.max_hp * 3
		summon_unit.max_hp = emp_hp
		summon_unit.current_hp = emp_hp
		var d = summon_unit.character_data.get("derived", {})
		d["max_hp"] = emp_hp
		d["current_hp"] = emp_hp
		d["damage"] = d.get("damage", 0) * 2  # derived.damage is read by get_attack_damage()
		summon_unit.has_summon_aura = true
		combat_log.emit("%s: Empowered summon — %s is supercharged!" % [caster.unit_name, summon_unit.unit_name])

	# Apply flying status if template specifies it
	if template.get("movement_mode", "") == "flying":
		summon_unit.status_effects.append({
			"status": "Flying", "duration": 999, "value": 0,
			"source": caster.unit_name
		})

	# Find a valid spawn position at or near target_pos
	var spawn_pos = Vector2i(-1, -1)
	if combat_grid != null and not combat_grid.is_occupied(target_pos) and combat_grid.is_valid_position(target_pos):
		spawn_pos = target_pos
	else:
		# Search outward in a 3-tile radius
		for radius in range(1, 4):
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					if abs(dx) != radius and abs(dy) != radius:
						continue
					var candidate = target_pos + Vector2i(dx, dy)
					if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_pos = candidate
						break
				if spawn_pos != Vector2i(-1, -1):
					break
			if spawn_pos != Vector2i(-1, -1):
				break

	if spawn_pos == Vector2i(-1, -1):
		push_warning("CombatManager: No space to spawn summon " + summon_id)
		return {"success": false, "reason": "No space for summon"}

	# Place the unit on the grid and register it
	combat_grid.place_unit(summon_unit, spawn_pos)
	all_units.append(summon_unit)
	turn_order.append(summon_unit)
	unit_deployed.emit(summon_unit, spawn_pos)
	combat_log.emit("%s summons %s!" % [caster.unit_name, summon_unit.unit_name])

	return {"success": true, "type": "summon", "unit": summon_unit, "position": spawn_pos}


## Process spell.special fields: battlefield dispels, see-through-stealth, etc.
func _apply_spell_special(caster: Node, target: Node, spell: Dictionary, special: Dictionary, result: Dictionary) -> void:
	# Crystal Light: dispels_all_battlefield — strip listed statuses from ALL units
	var bf_dispel = special.get("dispels_all_battlefield", [])
	if not bf_dispel.is_empty():
		var stripped_count: int = 0
		for unit in all_units:
			if unit.is_dead:
				continue
			for status_name in bf_dispel:
				if unit.has_status(status_name):
					_remove_status_by_name(unit, status_name)
					stripped_count += 1
			# Also break stealth on all units (Crystal Light reveals everything)
			if "is_stealthed" in unit and unit.is_stealthed:
				_leave_stealth(unit)
				combat_log.emit("%s is revealed by the blinding light!" % unit.unit_name)
				stripped_count += 1
		combat_log.emit("Crystal Light strips %d concealment effects!" % stripped_count)
		result.effects_applied.append({"type": "battlefield_dispel", "count": stripped_count})

	# Divine Eye: see_through_stealth — grant the target permanent stealth vision
	var see_through = special.get("see_through_stealth", [])
	if not see_through.is_empty():
		if "see_through_stealth" in target:
			target.see_through_stealth = true
		else:
			target.set("see_through_stealth", true)
		combat_log.emit("%s gains true sight — stealth and illusions cannot fool them!" % target.unit_name)
		result.effects_applied.append({"type": "true_sight"})

	# stealth_bonus: mark that this spell grants stealth advantage (for detection DC)
	if special.get("stealth_bonus", false):
		if "is_stealthed" in target:
			target.is_stealthed = true
			combat_log.emit("%s is cloaked in shadow." % target.unit_name)


## Process passive perks that trigger when a spell hits a target.
## Called from _apply_spell_effects() after all effects are applied.
func _process_spell_cast_perks(caster: Node, target: Node, spell: Dictionary, result: Dictionary) -> void:
	var caster_char = caster.character_data if "character_data" in caster else {}
	var element = spell.get("damage_type", "")
	var schools = spell.get("schools", [])
	var has_damage = result.effects_applied.any(func(e): return e.get("type") == "damage")
	var has_debuff = result.effects_applied.any(func(e): return e.get("type") == "status")

	# Touch of Gloom: debuff spells also apply -1 Movement and -3 Initiative for 2 turns
	if PerkSystem.has_perk(caster_char, "touch_of_gloom") and has_debuff:
		var black_schools = ["Black", "black"]
		var is_black_spell = schools.any(func(s): return s.to_lower() == "black")
		if is_black_spell:
			_apply_stat_modifier(target, "movement", -1, 2)
			_apply_stat_modifier(target, "initiative", -3, 2)

	# Measured Radiance: white damage spells have 25% chance to blind for 1 turn
	if PerkSystem.has_perk(caster_char, "measured_radiance") and has_damage:
		var is_white = element in ["white", "holy"] or schools.any(func(s): return s.to_lower() in ["white", "holy"])
		if is_white and randf() < 0.25:
			_apply_status_effect(target, "Blinded", 1, 0, caster)

	# Mental Aftershock: space damage spells apply -10% Focus and -3 Initiative for 2 turns
	if PerkSystem.has_perk(caster_char, "mental_aftershock") and has_damage:
		var is_space = element == "space" or schools.any(func(s): return s.to_lower() == "space")
		if is_space:
			# -3 initiative as stat modifier; -10% focus as a flat -1 (focus is usually ~10)
			_apply_stat_modifier(target, "initiative", -3, 2)
			_apply_stat_modifier(target, "focus", -1, 2)

	# Creeping Cold: ice/cold spells that deal damage also apply -1 Movement for 2 turns
	if PerkSystem.has_perk(caster_char, "creeping_cold") and has_damage:
		var is_cold = element in ["ice", "cold", "water"] or schools.any(func(s): return s.to_lower() in ["water"])
		if is_cold:
			_apply_stat_modifier(target, "movement", -1, 2)

	# No Warning (Sorcery 3): first combat round only, Sorcery spells deal +30% bonus damage
	if PerkSystem.has_perk(caster_char, "no_warning") and has_damage and combat_round == 1:
		var is_sorcery_nw = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_nw:
			var nw_bonus = int(result.get("damage", 0) * 0.30)
			if nw_bonus > 0:
				apply_damage(target, nw_bonus, element)
				result["no_warning_bonus"] = nw_bonus

	# Spell Like a Knife (Sorcery 5): single-target Sorcery kill → set bonus ready flag for next spell
	if PerkSystem.has_perk(caster_char, "spell_like_a_knife") and has_damage:
		var is_sorcery_slk = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_slk and not target.is_alive() and "sorcery_kill_bonus_ready" in caster:
			caster.sorcery_kill_bonus_ready = true

	# Nothing Burns Alone (Fire 4): when a burning enemy dies, spread Burning (2 turns) to enemies within 1 tile
	if PerkSystem.has_perk(caster_char, "nothing_burns_alone"):
		var is_fire_nba = element == "fire" or schools.any(func(s): return s.to_lower() == "fire")
		if is_fire_nba and not target.is_alive() and target.has_status("Burning"):
			for adj in _get_enemies_in_range(target, 1):
				if adj != target and adj.is_alive():
					_apply_status_effect(adj, "Burning", 2, 0, caster)

	# Tremor (Earth 2): Earth AoE spells have 25% chance to knock all targets prone
	if PerkSystem.has_perk(caster_char, "tremor") and has_damage:
		var is_earth_tr = element == "earth" or schools.any(func(s): return s.to_lower() == "earth")
		var is_aoe_tr = spell.get("targeting", "").begins_with("aoe")
		if is_earth_tr and is_aoe_tr and randf() < 0.25:
			_apply_status_effect(target, "Knocked_Down", 1, 0, caster)

	# Ashes Remember Heat (Fire 5): killing a burning enemy leaves burning terrain for 3 turns
	if PerkSystem.has_perk(caster_char, "ashes_remember_heat") and has_damage:
		var is_fire_arh = element == "fire" or schools.any(func(s): return s.to_lower() == "fire")
		if is_fire_arh and not target.is_alive() and target.has_status("Burning"):
			if combat_grid and "grid_position" in target:
				combat_grid.add_terrain_effect(target.grid_position, "fire", 3)

	# Scattering Gust (Air 1): push/knockback spells have 25% chance to also Knockdown
	var has_push = result.effects_applied.any(func(e): return e.get("status", "") in ["Pushed", "Knocked_Back", "Pulled"])
	if PerkSystem.has_perk(caster_char, "scattering_gust") and has_push:
		var is_air_sg = schools.any(func(s): return s.to_lower() == "air")
		if is_air_sg and randf() < 0.25:
			_apply_status_effect(target, "Knocked_Down", 1, 0, caster)

	# Riptide (Water 3): push/pull spells gain +1 tile displacement (applied to stat mod) + save vs knockdown
	# The extra displacement is handled by adding a brief Move debuff to simulate root
	if PerkSystem.has_perk(caster_char, "riptide") and has_push:
		var is_water_r = schools.any(func(s): return s.to_lower() == "water")
		if is_water_r:
			# Chance for knockdown in addition to the push
			if randf() < 0.40:
				_apply_status_effect(target, "Knocked_Down", 1, 0, caster)

	# Mystic Healer (White 3 + Enchantment 2): single-target healing also applies a random minor buff (2 turns)
	var has_heal = result.effects_applied.any(func(e): return e.get("type") == "heal")
	if PerkSystem.has_perk(caster_char, "mystic_healer") and has_heal:
		var is_white_mh = schools.any(func(s): return s.to_lower() == "white")
		if is_white_mh:
			var buffs = ["Strengthened", "Hastened", "Shielded", "Inspired"]
			_apply_status_effect(target, buffs[randi() % buffs.size()], 2, 0, caster)

	# Crystalline Edge (Earth 2): Earth damage spells have 20% chance to apply Brittle (-15% Armor, 2 turns)
	if PerkSystem.has_perk(caster_char, "crystalline_edge") and has_damage:
		var is_earth = element == "earth" or schools.any(func(s): return s.to_lower() == "earth")
		if is_earth and randf() < 0.20:
			var brittle_amt = int(target.get_armor() * 0.15)
			if brittle_amt > 0:
				_apply_stat_modifier(target, "armor", -brittle_amt, 2)

	# Weight of the Mountain (Earth 3): Earth damage spells apply -1 Movement for 2 turns
	if PerkSystem.has_perk(caster_char, "weight_of_the_mountain") and has_damage:
		var is_earth_wm = element == "earth" or schools.any(func(s): return s.to_lower() == "earth")
		if is_earth_wm:
			_apply_stat_modifier(target, "movement", -1, 2)

	# Tidal Surge (Water 2): after casting a Water spell, caster gains +1 Movement for 1 turn
	if PerkSystem.has_perk(caster_char, "tidal_surge"):
		var is_water_ts = element in ["water", "ice", "cold"] or schools.any(func(s): return s.to_lower() == "water")
		if is_water_ts:
			_apply_stat_modifier(caster, "movement", 1, 1)

	# Static Edge (Air 1): all attacks deal +10% weapon damage as Air damage
	# Wired in get_passive_perk_stat_bonus; here we add it as a bonus damage proc on spell hits
	# Chain Spark (Air 3): Lightning spells have 30% chance to chain to 1 adjacent target
	if PerkSystem.has_perk(caster_char, "chain_spark") and has_damage:
		var is_lightning = element in ["air", "lightning"] or schools.any(func(s): return s.to_lower() == "air")
		if is_lightning and randf() < 0.30:
			var chain_targets = _get_enemies_in_range(target, 2)
			chain_targets.erase(target)
			chain_targets.erase(caster)
			if not chain_targets.is_empty():
				var chain_target = chain_targets[randi() % chain_targets.size()]
				var chain_dmg = int(result.get("damage", 0) * 0.60)
				chain_dmg = maxi(1, chain_dmg)
				apply_damage(chain_target, chain_dmg, "air")
				result["chain_spark_damage"] = chain_dmg

	# Weakening Gaze (Enchantment 1): Enchantment debuff spells last extra turns,
	# scaling with Enchantment skill (1 extra turn per 3 levels, minimum 1).
	if PerkSystem.has_perk(caster_char, "weakening_gaze") and has_debuff:
		var is_enchant = schools.any(func(s): return s.to_lower() == "enchantment")
		if is_enchant:
			if not target.status_effects.is_empty():
				var last_effect = target.status_effects[-1]
				if last_effect.get("status", "") != "":
					var enc_lv: int = caster_char.get("skills", {}).get("enchantment", 0)
					last_effect["duration"] = last_effect.get("duration", 1) + maxi(1, int(enc_lv / 3))

	# Sudden Silence (Sorcery 3): Sorcery damage spells reduce target Spellpower by 25% for 1 turn
	if PerkSystem.has_perk(caster_char, "sudden_silence") and has_damage:
		var is_sorcery = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery:
			var sp_pen = int(target.get_spellpower() * 0.25) if target.has_method("get_spellpower") else 3
			if sp_pen > 0:
				_apply_stat_modifier(target, "spellpower", -sp_pen, 1)

	# Snap Decision (Sorcery 4): Sorcery spells reduce target Initiative by 25% for 1 turn
	if PerkSystem.has_perk(caster_char, "snap_decision") and has_damage:
		var is_sorcery_sd = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_sd:
			var init_pen = int(target.get_initiative() * 0.25) if target.has_method("get_initiative") else 3
			if init_pen > 0:
				_apply_stat_modifier(target, "initiative", -init_pen, 1)

	# No Follow-Up Needed (Sorcery 4): Killing with a Sorcery spell refunds 50% of its mana cost
	if PerkSystem.has_perk(caster_char, "no_follow_up_needed") and has_damage:
		var is_sorcery_nfun = schools.any(func(s): return s.to_lower() == "sorcery")
		if is_sorcery_nfun and not target.is_alive():
			var refund = int(spell.get("mana_cost", 0) * 0.50)
			if refund > 0:
				caster.current_mana = mini(caster.current_mana + refund, caster.max_mana)
				unit_healed.emit(caster, 0)  # triggers mana display refresh

	# Fear Is the Mindkiller (Black 4): enemies with 2+ Black debuffs must save or become Feared (once per enemy per combat)
	if PerkSystem.has_perk(caster_char, "fear_is_the_mindkiller") and has_debuff:
		var is_black_fitm = schools.any(func(s): return s.to_lower() == "black")
		if is_black_fitm:
			# Count Black-type debuffs on target (check known Black statuses as proxy)
			var black_debuff_names = ["Weakened", "Blinded", "Slowed", "Silenced", "Cursed", "Doomed",
				"Damage_Debuff", "Dodge_Debuff", "Feared", "Demoralized"]
			var black_debuff_count = 0
			for se in target.status_effects:
				if se.get("status", "") in black_debuff_names:
					black_debuff_count += 1
			if black_debuff_count >= 2 and not target.has_status("Feared"):
				# Focus save vs DC 12 (simplified as 40% resist chance)
				if randf() > 0.40:
					_apply_status_effect(target, "Feared", 2, 0, caster)

	# Amplified Misfortune: black debuff spells also spread status effects to 1 adjacent enemy
	if PerkSystem.has_perk(caster_char, "amplified_misfortune") and has_debuff:
		var is_black = schools.any(func(s): return s.to_lower() == "black")
		if is_black:
			var nearby = _get_enemies_in_range(target, 1)
			nearby.erase(caster)
			if not nearby.is_empty():
				var splash = nearby[randi() % nearby.size()]
				for applied in result.effects_applied:
					if applied.get("type") == "status":
						var sname = applied.get("status", "")
						if sname != "":
							_apply_status_effect(splash, sname, 2, 0, caster)

	# Damaru rhythm charge: increment when caster has Damaru in off-hand (charges max at 3, discount fires in cast_spell)
	if "damaru_charges" in caster and caster.damaru_charges < 3:
		var caster_char_data = caster.character_data if "character_data" in caster else {}
		var damaru_id = ItemSystem.get_equipped_item(caster_char_data, "weapon_off")
		if damaru_id != "":
			var damaru_item = ItemSystem.get_item(damaru_id)
			if damaru_item.get("special_mechanic", "") == "damaru_charges":
				caster.damaru_charges += 1
				combat_log.emit("%s's Damaru builds rhythm (%d/3)." % [caster.unit_name, caster.damaru_charges])


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


## Check if a unit's talisman perks grant immunity or resistance to a status.
## Returns true if the status should be blocked entirely.
func _check_talisman_status_immunity(unit: Node, status: String) -> bool:
	var perks = _get_talisman_perks(unit)
	if perks.is_empty():
		return false

	var status_lower = status.to_lower()

	# Full immunity perks
	var immunity_map = {
		"bleed_immune": ["bleeding"],
		"poison_immune": ["poisoned"],
		"fear_immune": ["feared"],
		"charm_immune": ["charmed"],
		"stun_immune": ["stunned"],
		"mental_immune": ["feared", "charmed", "confused", "berserk"],
	}

	for perk_id in perks:
		if perk_id in immunity_map:
			if status_lower in immunity_map[perk_id]:
				return true

	# 50% resistance perks
	var resist_map = {
		"bleed_resist": ["bleeding"],
		"poison_resist": ["poisoned"],
		"fear_resist": ["feared"],
		"charm_resist": ["charmed"],
		"stun_resist": ["stunned"],
	}

	for perk_id in perks:
		if perk_id in resist_map:
			if status_lower in resist_map[perk_id]:
				if randf() < 0.5:
					return true

	return false


## Apply a status effect.
## Non-stackable statuses refresh duration instead of stacking.
## Stackable statuses (e.g. Burning) add additional instances.
func _apply_status_effect(unit: Node, status: String, duration: int, value: int = 0, source: Node = null) -> void:
	if not "status_effects" in unit:
		unit.set("status_effects", [])

	var def = _status_effects.get(status, {})

	# --- Talisman perk immunity/resistance checks ---
	if _check_talisman_status_immunity(unit, status):
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return

	# --- Character perk immunity/resistance checks ---
	if _check_perk_status_immunity(unit, status):
		if unit.has_method("show_resisted_text"):
			unit.show_resisted_text()
		return

	# Kindled (Fire 1): Burning effects applied by the caster last 1 extra turn
	if status == "Burning" and source != null and "character_data" in source:
		if PerkSystem.has_perk(source.character_data, "kindled"):
			duration += 1

	# Lingering Touch (Enchantment 1): buff statuses last extra turns, scaling with
	# Enchantment skill (1 extra turn per 3 levels, minimum 1).
	if def.get("type", "") == "buff" and source != null and "character_data" in source:
		if PerkSystem.has_perk(source.character_data, "lingering_touch"):
			var enc_lv: int = source.character_data.get("skills", {}).get("enchantment", 0)
			duration += maxi(1, int(enc_lv / 3))

	# Check if already present and handle stacking
	if unit.has_status(status):
		if not def.get("stackable", false):
			# Non-stackable: refresh to the longer duration
			for existing in unit.status_effects:
				if existing.get("status", "").to_lower() == status.to_lower():
					existing.duration = maxi(existing.duration, duration)
					if value > 0:
						existing.value = value
					if source != null:
						existing["source"] = source
					# Hard CC breaks concentration even on a refresh
					if status in ["Stun", "Stunned", "Fear", "Feared", "Charm", "Charmed", "Confused", "Berserk",
							"Frozen", "Petrified", "Held", "Paralyzed", "Immobilized", "Dominated", "Chaotic"]:
						_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])
					return

	var effect_entry = {
		"status": status,
		"duration": duration,
		"value": value
	}
	if source != null:
		effect_entry["source"] = source
	unit.get("status_effects").append(effect_entry)

	# Hard CC breaks concentration on the affected unit
	if status in ["Stun", "Stunned", "Fear", "Feared", "Charm", "Charmed", "Confused", "Berserk",
			"Frozen", "Petrified", "Held", "Paralyzed", "Immobilized", "Dominated", "Chaotic"]:
		_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])

	# Invisible status grants stealth automatically
	if status == "Invisible" and "is_stealthed" in unit:
		unit.is_stealthed = true
		combat_log.emit("%s fades from sight." % unit.unit_name)

	# Show floating status applied text on the unit
	if unit.has_method("show_status_applied"):
		unit.show_status_applied(status)

	# Update visuals to show new status icon
	if unit.has_method("_update_visuals"):
		unit._update_visuals()


## Remove a specific status effect by name from a unit. Returns true if found and removed.
func _remove_status_by_name(unit: Node, status_name: String) -> bool:
	if not "status_effects" in unit:
		return false
	for i in range(unit.status_effects.size() - 1, -1, -1):
		if unit.status_effects[i].get("status", "") == status_name:
			var def = _status_effects.get(status_name, {})
			_on_status_expired(unit, status_name, def)
			unit.status_effects.remove_at(i)
			status_effect_expired.emit(unit, status_name)
			if unit.has_method("show_status_expired"):
				unit.show_status_expired(status_name)
			return true
	return false


## Remove negative status effects using the dispellable flag from status definitions.
## Only removes debuffs that are marked dispellable. Returns the count removed.
func _cleanse_status_effects(unit: Node, count: int) -> int:
	if not "status_effects" in unit:
		return 0

	var removed = 0
	var to_remove: Array[int] = []

	for i in range(unit.status_effects.size()):
		if removed >= count:
			break
		var status_name = unit.status_effects[i].get("status", "")
		var def = _status_effects.get(status_name, {})
		# Only cleanse debuffs that are marked as dispellable
		if def.get("type", "") == "debuff" and def.get("dispellable", false):
			to_remove.append(i)
			removed += 1

	# Remove in reverse order to maintain indices
	to_remove.reverse()
	for idx in to_remove:
		var expired = unit.status_effects[idx]
		var sname = expired.get("status", "")
		unit.status_effects.remove_at(idx)
		# Show expired visual
		if unit.has_method("show_status_expired"):
			unit.show_status_expired(sname)
		status_effect_expired.emit(unit, sname)

	return removed


## Process status effects at turn start.
## Handles DoT, HoT, incapacitation, saving throws, escalating damage,
## expiry callbacks, and status spread.
## Returns true if the unit should skip their turn (incapacitated).
func _process_status_effects(unit: Node) -> bool:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return false

	var skip_turn = false
	var effects_to_remove: Array[int] = []

	for i in range(unit.status_effects.size()):
		var effect = unit.status_effects[i]
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})

		# --- Damage over time ---
		var dot = effect_def.get("damage_per_turn", 0)
		if dot > 0:
			var damage = dot
			# Use per-instance value if present (for variable damage)
			if effect.get("value", 0) > 0:
				damage = effect.value
			# Escalating DoT (Festering: damage increases each turn)
			var escalation = effect_def.get("damage_increase_per_turn", 0)
			if escalation > 0:
				# Store accumulated escalation on the effect instance
				var extra = effect.get("_escalation_ticks", 0) * escalation
				damage += extra
				effect["_escalation_ticks"] = effect.get("_escalation_ticks", 0) + 1
			var element = effect_def.get("element", "physical")
			apply_damage(unit, damage, element)
			status_effect_triggered.emit(unit, status_name, damage, "damage")

		# --- Heal over time ---
		var hot_val = effect_def.get("heal_per_turn", 0)
		if hot_val is bool:
			hot_val = 0  # Legacy: some entries used true/false
		if hot_val > 0 or "heal_per_turn" in effect_def:
			var heal_amount = hot_val if hot_val > 0 else effect.get("value", 5)
			if heal_amount > 0:
				unit.heal(heal_amount)
				unit_healed.emit(unit, heal_amount)
				status_effect_triggered.emit(unit, status_name, heal_amount, "heal")

		# --- Incapacitation check ---
		if effect_def.get("blocks_actions", false):
			skip_turn = true

		# --- Saving throw (end-of-turn save to shake off CC) ---
		var saved = false
		if effect_def.get("save_at_end_of_turn", false) or "save_at_end_of_turn" in effect_def.get("effects", []):
			var save_type = effect_def.get("save_type", "Constitution")
			var attrs = unit.character_data.get("attributes", {})
			var save_attr = attrs.get(save_type.to_lower(), 10)
			var roll = randi_range(1, 20) + save_attr
			if roll >= 15:  # DC 15 base save
				saved = true
				effect.duration = 0  # Will be removed below
				# Show "Resisted!" floating text
				if unit.has_method("show_resisted_text"):
					unit.show_resisted_text()

		# --- Duration: "until_save" statuses only expire on save ---
		if effect_def.get("duration_type", "") == "until_save":
			if not saved:
				# Don't decrement — only saves can remove this
				pass
			# If saved, duration is already 0 from above
		else:
			# Normal duration decrement
			effect.duration -= 1

		# Mark for removal if expired
		if effect.duration <= 0:
			effects_to_remove.append(i)

	# Remove expired effects (in reverse order to maintain indices)
	effects_to_remove.reverse()
	for idx in effects_to_remove:
		var expired_effect = unit.status_effects[idx]
		var status_name = expired_effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		# Process expiry callbacks before removing
		_on_status_expired(unit, status_name, effect_def)
		unit.status_effects.remove_at(idx)
		# Show expired visual (grey strikethrough)
		if unit.has_method("show_status_expired"):
			unit.show_status_expired(status_name)
		status_effect_expired.emit(unit, status_name)

	# Process status spread (e.g. Burning can spread to adjacent units)
	_process_status_spread(unit)

	# Process aura effects (buff nearby allies each turn)
	_process_aura_effects(unit)

	# Also process stat modifiers (buff/debuff duration tick)
	_process_stat_modifiers(unit)

	return skip_turn


## Handle special effects that trigger when a status expires.
## E.g. Doomed kills the unit, Infected spawns a fungal creature and applies Bleeding.
func _on_status_expired(unit: Node, status_name: String, def: Dictionary) -> void:
	var effects = def.get("effects", [])
	if effects.is_empty():
		return

	if "death_on_expire" in effects:
		# Doomed — instant kill
		apply_damage(unit, unit.max_hp * 10, "black")

	if "damage_on_expire" in effects:
		var expire_dmg = def.get("expire_damage", 20)
		apply_damage(unit, expire_dmg, "physical")

	if "bleed_on_expire" in effects:
		_apply_status_effect(unit, "Bleeding", 3)

	# Invisible expiry: drop stealth unless unit has Blend In (own stealth ability)
	if "cannot_be_targeted" in effects and status_name == "Invisible":
		if "is_stealthed" in unit and unit.is_stealthed:
			var char_data = unit.character_data if "character_data" in unit else {}
			if not PerkSystem.has_perk(char_data, "blend_in"):
				_leave_stealth(unit)
				combat_log.emit("%s becomes visible as the spell fades." % unit.unit_name)
			else:
				combat_log.emit("%s's invisibility fades but stays hidden (Blend In)." % unit.unit_name)

	# Spawn-on-expire effects (Infected spawns fungal creature) — emit signal for
	# encounter system to handle, since we don't create units directly here
	if "spawn_fungal_spawn_on_expire" in effects:
		# TODO: Wire to encounter spawn system
		push_warning("Status expired with spawn effect: ", status_name, " on ", unit.unit_name)


## Process status spread — statuses with "spread" data can jump to adjacent units.
## Called once per unit per turn, after normal status processing.
func _process_status_spread(unit: Node) -> void:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var def = _status_effects.get(status_name, {})
		var spread = def.get("spread", {})
		if spread.is_empty():
			continue

		var chance = _spread_chance_to_float(spread.get("chance", "none"))
		if chance <= 0.0 or randf() > chance:
			continue

		# Find adjacent units to spread to
		var adjacent = _get_units_in_range(unit, 1)
		for adj in adjacent:
			if adj.is_dead or adj.is_bleeding_out:
				continue
			if not adj.has_status(status_name):
				var spread_duration = def.get("default_duration", 2)
				_apply_status_effect(adj, status_name, spread_duration)
				break  # Spread to one unit per tick


## Convert spread chance string to float probability
func _spread_chance_to_float(chance_str: String) -> float:
	match chance_str:
		"low":
			return 0.15
		"medium":
			return 0.30
		"high":
			return 0.50
		_:
			return 0.0


## Process aura status effects — statuses that buff/heal nearby allies each turn.
## Called once per unit per turn during status processing.
## Aura effects:
##   - Favorable_Wind: grants Hasted + Precision to allies within 2 tiles
##   - Aura_of_Blessing: grants Blessed to allies within 2 tiles
##   - Soothing_Presence: heals allies within 2 tiles for heal_per_turn
##   - Magnetizing_Aura: chance to charm enemies who end turn adjacent (handled separately)
##   - Storm_Lord / Lightning_Form: lightning aura damages melee attackers (handled in reactive)
func _process_aura_effects(unit: Node) -> void:
	if not "status_effects" in unit or unit.status_effects.is_empty():
		return

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var def = _status_effects.get(status_name, {})
		var effects = def.get("effects", [])

		# Favorable Wind — grant Hasted and Precision to nearby allies
		if "aura_grants_haste" in effects or "aura_grants_precision" in effects:
			var allies = _get_allies_in_range(unit, 2)
			for ally in allies:
				if "aura_grants_haste" in effects and not ally.has_status("Hasted"):
					_apply_status_effect(ally, "Hasted", 2)
					status_effect_triggered.emit(unit, "Favorable_Wind", 0, "aura")
				if "aura_grants_precision" in effects and not ally.has_status("Precision"):
					_apply_status_effect(ally, "Precision", 2)

		# Aura of Blessing — grant Blessed to nearby allies
		if "grants_blessed_to_nearby_allies" in effects:
			var allies = _get_allies_in_range(unit, 2)
			for ally in allies:
				if not ally.has_status("Blessed"):
					_apply_status_effect(ally, "Blessed", 2)
					status_effect_triggered.emit(unit, "Aura_of_Blessing", 0, "aura")

		# Soothing Presence — heal nearby allies each turn
		if "heal_allies_per_turn_in_aura" in effects:
			var heal_amount = def.get("heal_per_turn", 5)
			var allies = _get_allies_in_range(unit, 2)
			for ally in allies:
				if ally.current_hp < ally.max_hp:
					ally.heal(heal_amount)
					unit_healed.emit(ally, heal_amount)
					status_effect_triggered.emit(unit, "Soothing_Presence", heal_amount, "aura")

		# Magnetizing Aura — charm chance when enemy moves adjacent
		# This is handled reactively in movement processing, not per-turn
		# (charm_chance_on_enemy_melee_approach)

		# Lightning auras (Storm_Lord, Lightning_Form) are reactive,
		# handled in _process_reactive_statuses


## Get all alive allied units within range of source (same team, excludes self)
func _get_allies_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if u.team == source.team and _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## Get all alive enemy units within range of source (different team)
func _get_enemies_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if u.team != source.team and _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## Get all alive units within a given range of a source unit
func _get_units_in_range(source: Node, radius: int) -> Array[Node]:
	var result: Array[Node] = []
	for u in all_units:
		if u == source or u.is_dead:
			continue
		if _grid_distance(source.grid_position, u.grid_position) <= radius:
			result.append(u)
	return result


## Process reactive status effects when a unit is hit by a melee/ranged attack.
## Handles Fireshield, Poison_Skin, Pain_Mirror, and similar "on-hit" effects.
func _process_reactive_statuses(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not "status_effects" in defender:
		return

	var is_melee = _grid_distance(attacker.grid_position, defender.grid_position) <= 1

	for effect in defender.status_effects:
		var status_name = effect.get("status", "")
		var def = _status_effects.get(status_name, {})
		var effects = def.get("effects", [])

		# Elemental damage to melee attackers (Fireshield, Tongues of Fire, etc.)
		# Supports any "X_damage_to_melee_attackers" pattern
		if is_melee:
			var reactive_dmg_map = {
				"fire_damage_to_melee_attackers": "fire",
				"air_damage_to_melee_attackers": "air",
				"water_damage_to_melee_attackers": "water",
				"earth_damage_to_melee_attackers": "earth",
				"space_damage_to_melee_attackers": "space",
				"poison_damage_to_melee_attackers": "poison",
				"black_damage_to_melee_attackers": "black",
				"white_damage_to_melee_attackers": "white",
			}
			for reactive_effect in reactive_dmg_map:
				if reactive_effect in effects:
					var element = reactive_dmg_map[reactive_effect]
					var reactive_dmg = 5 + effect.get("value", 0)
					apply_damage(attacker, reactive_dmg, element)
					status_effect_triggered.emit(defender, status_name, reactive_dmg, "reactive")

		# Poison Skin — poison melee attackers
		if "poisons_melee_attackers" in effects and is_melee:
			if not attacker.has_status("Poisoned"):
				_apply_status_effect(attacker, "Poisoned", 3)
				status_effect_triggered.emit(defender, status_name, 0, "reactive")

		# Pain Mirror — reflect 50% damage to attacker
		if "deal_50_percent_damage_taken_to_attacker" in effects:
			var reflect = int(result.damage * 0.5)
			if reflect > 0:
				apply_damage(attacker, reflect, "physical")
				status_effect_triggered.emit(defender, status_name, reflect, "reactive")

		# Lightning aura — damages (and optionally stuns) melee attackers
		if "lightning_aura_damages_attackers" in effects and is_melee:
			var lightning_dmg = 8 + effect.get("value", 0)
			apply_damage(attacker, lightning_dmg, "air")
			status_effect_triggered.emit(defender, status_name, lightning_dmg, "reactive")

		if "lightning_aura_damages_and_stuns" in effects and is_melee:
			var lightning_dmg = 10 + effect.get("value", 0)
			apply_damage(attacker, lightning_dmg, "air")
			# 30% chance to stun
			if randf() < 0.3:
				_apply_status_effect(attacker, "Stunned", 1)
			status_effect_triggered.emit(defender, status_name, lightning_dmg, "reactive")

		# Magnetizing Aura — chance to charm melee attackers
		if "charm_chance_on_enemy_melee_approach" in effects and is_melee:
			# 25% chance to charm the attacker for 1 turn
			if randf() < 0.25:
				_apply_status_effect(attacker, "Charmed", 1)
				status_effect_triggered.emit(defender, status_name, 0, "reactive")


## Process status-based weapon enchant effects when a unit lands an attack.
## Checks for any "adds_X_damage_to_attacks" effect and applies bonus elemental damage.
func _process_status_weapon_enchants(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not "status_effects" in attacker:
		return
	# Map effect strings to their damage element
	var enchant_map = {
		"adds_fire_damage_to_attacks": "fire",
		"adds_air_damage_to_attacks": "air",
		"adds_water_damage_to_attacks": "water",
		"adds_earth_damage_to_attacks": "earth",
		"adds_space_damage_to_attacks": "space",
		"adds_poison_damage_to_attacks": "poison",
		"adds_black_damage_to_attacks": "black",
		"adds_white_damage_to_attacks": "white",
	}
	var enchant_base = result.get("damage", 0)
	for effect in attacker.status_effects:
		var sname = effect.get("status", "")
		var sdef = get_status_definition(sname)
		var seffects = sdef.get("effects", [])
		for enchant_effect in enchant_map:
			if enchant_effect in seffects:
				var element = enchant_map[enchant_effect]
				var bonus_dmg = maxi(1, ceili(enchant_base * 0.20))  # +20% as elemental damage
				var resist = defender.get_resistance(element)
				bonus_dmg = maxi(1, int(bonus_dmg * (1.0 - resist / 100.0)))
				apply_damage(defender, bonus_dmg, element)
				var key = "enchant_%s_damage" % element
				result[key] = result.get(key, 0) + bonus_dmg


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

	# Apply effect based on type — terrain now also applies matching status effects
	match effect:
		CombatGrid.TerrainEffect.FIRE:
			apply_damage(unit, value, "fire")
			if not unit.has_status("Burning"):
				_apply_status_effect(unit, "Burning", 2)
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.POISON:
			apply_damage(unit, value, "physical")
			if not unit.has_status("Poisoned"):
				_apply_status_effect(unit, "Poisoned", 3)
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.ACID:
			apply_damage(unit, value, "physical")
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.CURSED:
			apply_damage(unit, value, "black")
			# 30% chance to apply Cursed debuff
			if randf() < 0.3 and not unit.has_status("Cursed"):
				_apply_status_effect(unit, "Cursed", 2)
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.BLESSED:
			unit.heal(value)
			unit_healed.emit(unit, value)
			terrain_heal.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.ICE:
			# Ice applies Slowed (no damage)
			if not unit.has_status("Slowed") and not unit.has_status("Frozen"):
				_apply_status_effect(unit, "Slowed", 1)

		CombatGrid.TerrainEffect.WET:
			# Wet ground slows and makes units vulnerable to ice/air damage
			if not unit.has_status("Slowed"):
				_apply_status_effect(unit, "Slowed", 1)
			terrain_damage.emit(unit, 0, effect_name)

		CombatGrid.TerrainEffect.STORMY:
			# Storm terrain deals air damage and has a chance to stun
			apply_damage(unit, value, "air")
			if randf() < 0.2 and not unit.has_status("Stunned"):
				_apply_status_effect(unit, "Stunned", 1)
			terrain_damage.emit(unit, value, effect_name)

		CombatGrid.TerrainEffect.VOID:
			# Void terrain deals space damage
			apply_damage(unit, value, "space")
			terrain_damage.emit(unit, value, effect_name)


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
	# Handle composite damage types (e.g., "fire_black" → fire terrain, "physical_fire" → fire)
	if effect_type < 0 and "_" in damage_type:
		for part in damage_type.split("_"):
			effect_type = DAMAGE_TYPE_TO_TERRAIN_EFFECT.get(part, -1)
			if effect_type >= 0:
				break  # Use the first element that maps to a terrain effect
	if effect_type < 0:
		return  # No ground effect for this damage type (physical, etc.)

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


## Check if unit can cast spells (not silenced/blinded)
func can_unit_cast(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if effect_def.get("blocks_casting", false):
			return false

	return true


## Check if unit can make weapon attacks (not Forgetful/Pacified)
func can_unit_attack(unit: Node) -> bool:
	if not "status_effects" in unit:
		return true

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		if effect_def.get("blocks_attacks", false):
			return false

	return true


## Get the CC behavior override for a unit, if any.
## Returns a string indicating forced behavior, or "" for no CC override.
## CC behaviors (checked in priority order):
##   "stunned"  — skip turn (already handled by blocks_actions)
##   "feared"   — flee away from fear source each turn
##   "confused" — move randomly, attack random adjacent target
##   "berserk"  — attack nearest creature regardless of team
##   "charmed"  — won't attack the caster, treats them as ally
##   "pacified" — won't attack anyone, can only move or end turn
func get_cc_behavior(unit: Node) -> String:
	if not "status_effects" in unit:
		return ""

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		var effects = effect_def.get("effects", [])

		# Feared — flee from source (highest priority after stun)
		if "flee_from_source" in effects:
			return "feared"

		# Confused — random movement and targeting
		if "random_movement" in effects or "random_target" in effects:
			return "confused"

		# Berserk — attack nearest regardless of allegiance
		if "attacks_closest_creature" in effects or "ignores_allegiance" in effects:
			return "berserk"

		# Charmed — won't attack caster
		if "will_not_attack_caster" in effects or "treats_caster_as_ally" in effects:
			return "charmed"

		# Pacified — won't fight
		if "will_not_attack" in effects or "disengaged_from_combat" in effects:
			return "pacified"

	return ""


## Get the source unit of a CC effect (the caster who applied it).
## Used for Feared (flee from source) and Charmed (won't attack caster).
func get_cc_source(unit: Node, cc_type: String) -> Node:
	if not "status_effects" in unit:
		return null

	var target_effects: Array[String] = []
	match cc_type:
		"feared":
			target_effects = ["flee_from_source"]
		"charmed":
			target_effects = ["will_not_attack_caster", "treats_caster_as_ally"]

	for effect in unit.status_effects:
		var status_name = effect.get("status", "")
		var effect_def = _status_effects.get(status_name, {})
		var effects = effect_def.get("effects", [])

		for te in target_effects:
			if te in effects:
				# The source is stored on the effect instance when applied
				var source_ref = effect.get("source", null)
				if source_ref is Node and is_instance_valid(source_ref):
					return source_ref

	return null


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
			var caster_true_sight = "see_through_stealth" in caster and caster.see_through_stealth
			for unit in all_units:
				if not unit.is_alive():
					continue
				if unit.team == caster.team:
					continue
				# Stealthed/invisible units cannot be targeted unless caster has true sight
				if not unit.is_targetable() and not caster_true_sight:
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

		"ground":
			# Summoning spells: any unoccupied, walkable tile in range
			if combat_grid:
				for x in range(combat_grid.grid_size.x):
					for y in range(combat_grid.grid_size.y):
						var pos = Vector2i(x, y)
						var dist = _spell_distance(caster.grid_position, pos)
						if dist <= spell_range and combat_grid.is_valid_position(pos) and not combat_grid.is_occupied(pos):
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

	# Bomb scatter: low Alchemy skill means the throw can land off-target by 1 tile.
	# Alchemy 0 → 50% scatter chance; Alchemy 3+ → no scatter.
	var actual_target_pos := target_pos
	var bomb_scattered := false
	var alchemy_level: int = 0
	if "character_data" in user:
		alchemy_level = user.character_data.get("skills", {}).get("alchemy", 0)
	var scatter_chance := maxf(0.0, 50.0 - alchemy_level * 17.0)
	if scatter_chance > 0.0 and randf() * 100.0 < scatter_chance:
		var scatter_dir: Vector2i = DIRS_8[randi() % DIRS_8.size()]
		actual_target_pos = target_pos + scatter_dir
		if combat_grid != null:
			actual_target_pos.x = clampi(actual_target_pos.x, 0, combat_grid.grid_size.x - 1)
			actual_target_pos.y = clampi(actual_target_pos.y, 0, combat_grid.grid_size.y - 1)
		bomb_scattered = true
		combat_log.emit("  Bomb lands off-target — scattered 1 tile!")

	# Find units in AoE
	var hit_units: Array[Node] = []
	for unit in all_units:
		if not unit.is_alive():
			continue
		var dist = _grid_distance(unit.grid_position, actual_target_pos)
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

	# Create ground effects from bomb damage type at actual landing position
	_create_ground_effects_from_damage(actual_target_pos, aoe_radius, damage_type, 2)

	return {
		"success": true,
		"is_bomb": true,
		"target_pos": actual_target_pos,
		"aimed_pos": target_pos,
		"bomb_scattered": bomb_scattered,
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


## Return an 8-directional unit step vector from `from` toward `to`.
func _dir_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var diff = to - from
	return Vector2i(sign(diff.x), sign(diff.y))


## Return the facing zone of `target_unit` as seen from `from_pos`.
## "front"  — attacker is within ±45° of target's facing (target can see them)
## "flank"  — attacker is roughly 90° to target's side
## "rear"   — attacker is within ±45° of target's back
## Uses dot-product with threshold ±0.5 (cos 60°) so the three arcs are symmetric.
func _get_facing_zone(from_pos: Vector2i, target_unit: Node) -> String:
	if not ("facing" in target_unit and "grid_position" in target_unit):
		return "front"
	var facing: Vector2i = target_unit.facing
	if facing == Vector2i.ZERO:
		return "front"
	# Vector from target to attacker
	var to_attacker = from_pos - target_unit.grid_position
	if to_attacker == Vector2i.ZERO:
		return "front"
	var facing_f   = Vector2(facing.x, facing.y).normalized()
	var to_att_f   = Vector2(to_attacker.x, to_attacker.y).normalized()
	var dot        = facing_f.dot(to_att_f)
	if dot > 0.5:
		return "front"
	elif dot < -0.5:
		return "rear"
	else:
		return "flank"


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

	# Check once-per-turn restriction (free-action skills like call_the_shot)
	if combat_data.get("once_per_turn", false):
		var used_flag = perk_id + "_used_this_turn"
		if used_flag in user and user.get(used_flag):
			return {"success": false, "reason": "Already used this turn"}

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
		"enter_stealth":
			result = _resolve_enter_stealth(user)
		"mark_target":
			result = _resolve_mark_target(user, combat_data, target_pos)
		"examine":
			# Reveal enemy info via examine window — handled by combat_arena via signal
			var target = get_unit_at(target_pos)
			if target == null or not target.is_alive():
				return {"success": false, "reason": "No target"}
			result = {"success": true, "examine_target": target, "effects": []}
		# --- Batch 2 resolvers ---
		"bonus_movement":
			result = _resolve_bonus_movement(user, combat_data)
		"restore_stamina":
			result = _resolve_restore_stamina(user, combat_data)
		"restore_armor":
			result = _resolve_restore_armor(user, combat_data, target_pos)
		"revive":
			result = _resolve_revive_ally(user, combat_data, target_pos)
		"debuff_enemies":
			result = _resolve_debuff_enemies_aoe(user, combat_data, target_pos)
		"buff_allies":
			result = _resolve_buff_allies_all(user, combat_data)
		"buff_ally":
			result = _resolve_buff_ally_single(user, combat_data, target_pos)
		"destroy_obstacle":
			result = _resolve_destroy_obstacle(user, combat_data, target_pos)
		"cleanse_and_buff":
			result = _resolve_cleanse_and_buff(user, combat_data)
		"grant_extra_action":
			result = _resolve_grant_extra_action(user, combat_data, target_pos)
		"force_miss":
			result = _resolve_force_miss(user, combat_data, target_pos)
		"grapple":
			result = _resolve_grapple(user, combat_data, target_pos)
		"overcast":
			result = _resolve_overcast(user, combat_data)
		"retreat":
			result = _resolve_retreat(user, combat_data)
		"aoe_damage_and_status":
			result = _resolve_aoe_damage_and_status(user, combat_data, target_pos)
		"buff_allies_debuff_enemies":
			result = _resolve_buff_allies_debuff_enemies(user, combat_data)
		"dispel_and_invert":
			result = _resolve_dispel_and_invert(user, combat_data, target_pos)
		"aggro_aura":
			result = _resolve_aggro_aura(user, combat_data)
		"share_buffs":
			result = _resolve_share_buffs(user, combat_data)
		"double_buffs":
			result = _resolve_double_buffs(user, combat_data, target_pos)
		"chod_offering":
			result = _resolve_chod_offering(user, combat_data)
		"throw_phurba":
			result = _resolve_throw_phurba(user, combat_data, target_pos)
		# --- Deferred (complex UI/system needed) ---
		"create_images", "imbued_attack", "mass_teleport", "recruit_or_pacify", \
		"place_trap", "consume_charm", "steal_item", "choose_one", "guard_ally", \
		"summon_aura", "create_terrain":
			return {"success": false, "reason": "Skill not yet implemented: " + effect_type}
		_:
			return {"success": false, "reason": "Unknown skill effect: " + effect_type}

	if result.get("success", false):
		# Play sound based on effect type
		match effect_type:
			"buff_self", "stance", "buff_allies", "buff_ally", "share_buffs", "double_buffs":
				AudioManager.play("buff_apply")
			"debuff_target", "debuff_enemies", "mark_target", "aggro_aura":
				AudioManager.play("debuff_apply")
			"heal_self", "revive", "cleanse_and_buff":
				AudioManager.play("heal")
			"teleport", "enter_stealth", "retreat", "bonus_movement":
				AudioManager.play("hit_miss")
			"overcast", "dispel_and_invert":
				AudioManager.play("spell_cast")
			"restore_stamina", "restore_armor", "grant_extra_action":
				AudioManager.play("buff_apply")
			# attack_with_bonus, dash_attack, aoe_attack, etc. already play attack sounds internally
		# Deduct stamina
		if stamina_cost > 0:
			user.use_stamina(stamina_cost)
		# Use action — free_action skills cost nothing
		if not combat_data.get("free_action", false):
			use_action(1)
		# Apply cooldown
		var cooldown = combat_data.get("cooldown", 0)
		if cooldown > 0:
			user.set_skill_cooldown(perk_id, cooldown)
		# Once-per-combat skills get a huge cooldown; once-per-turn skills cool down in 1 turn
		if combat_data.get("once_per_combat", false):
			user.set_skill_cooldown(perk_id, 999)
		# Mark once-per-turn skills as used (reset at turn start)
		if combat_data.get("once_per_turn", false):
			var used_flag = perk_id + "_used_this_turn"
			if used_flag in user:
				user.set(used_flag, true)
		# Emit signal
		active_skill_used.emit(user, skill_data, result)

	return result


## ── Stealth Detection System ─────────────────────────────────────────────────
## 5-tile detection radius.  Each enemy within range rolls:
##     d20 + Awareness  vs  DC
## DC scales with distance, Guile skill, Soft Step perk, and Invisibility.
##
## Distance → base DC:  5→10, 4→14, 3→18, 2→22, 1→26
## Guile level:   +2 DC per level
## Soft Step:     +4 DC
## Invisibility:  +10 DC  (nearly undetectable)
##
## Called after each movement step and by Shady Dealings on non-melee actions.

const _STEALTH_BASE_DC: Dictionary = {5: 10, 4: 14, 3: 18, 2: 22, 1: 26}

## Run detection checks for all enemies within 5 tiles of a stealthed unit.
## Returns true if detected (stealth broken).
func _run_stealth_detection(unit: Node) -> bool:
	if not ("is_stealthed" in unit and unit.is_stealthed):
		return false

	var char_data = unit.character_data if "character_data" in unit else {}
	var guile_level: int = char_data.get("skills", {}).get("guile", 0)
	var has_soft_step: bool = PerkSystem.has_perk(char_data, "soft_step")
	var is_invisible: bool = unit.has_status("Invisible") if unit.has_method("has_status") else false

	for enemy in all_units:
		if enemy.is_dead or enemy.team == unit.team:
			continue
		var dist = _grid_distance(unit.grid_position, enemy.grid_position)
		if dist < 1 or dist > 5:
			continue

		var base_dc: int = _STEALTH_BASE_DC.get(dist, 10)

		# Facing zone modifier: sneaking up behind someone is easier;
		# sneaking into their front arc is much harder (they can see you coming)
		var facing_dc_mod := 0
		var facing_roll_mod := 0
		if "facing" in enemy:
			match _get_facing_zone(unit.grid_position, enemy):
				"front":
					facing_roll_mod = enemy.attributes.get("awareness", 8) / 2 if "attributes" in enemy else 4
				"rear":
					facing_dc_mod = 6

		var dc: int = base_dc + (guile_level * 2) + facing_dc_mod
		if has_soft_step:
			dc += 4
		if is_invisible:
			dc += 10

		var awareness: int = 8
		if "attributes" in enemy:
			awareness = enemy.attributes.get("awareness", 8)
		var roll: int = randi_range(1, 20) + awareness + facing_roll_mod

		if roll >= dc:
			combat_log.emit("%s (AWR %d, rolled %d vs DC %d) spots %s at range %d!" % [
				enemy.unit_name, awareness, roll, dc, unit.unit_name, dist])
			_leave_stealth(unit)
			return true

	return false


## Enter stealth (blend_in active skill).
func _resolve_enter_stealth(user: Node) -> Dictionary:
	if "is_stealthed" in user and user.is_stealthed:
		return {"success": false, "reason": "Already stealthed"}
	_enter_stealth(user)
	return {"success": true, "effects": [{"type": "enter_stealth"}]}


## Central helper: enter stealth for a unit and apply all enter-stealth perk effects.
func _enter_stealth(unit: Node) -> void:
	unit.is_stealthed = true
	combat_log.emit("%s blends into the shadows." % unit.unit_name)

	var char_data = unit.character_data if "character_data" in unit else {}

	# Now You See Me (Guile 3): entering stealth removes all 1-turn duration debuffs
	# and breaks enemy targeting (clears marks, taunts pointed at this unit)
	if PerkSystem.has_perk(char_data, "now_you_see_me"):
		for i in range(unit.status_effects.size() - 1, -1, -1):
			var se = unit.status_effects[i]
			var sdef = get_status_definition(se.get("status", ""))
			if sdef.get("type", "") == "debuff" and se.get("duration", 0) <= 1:
				var sname = se.get("status", "")
				unit.status_effects.remove_at(i)
				status_effect_expired.emit(unit, sname)
		# Break enemy targeting: clear marks and taunt locks aimed at this unit
		if "is_marked" in unit:
			unit.is_marked = false
		for other in all_units:
			if "marked_target" in other and other.marked_target == unit:
				other.marked_target = null
		combat_log.emit("Now You See Me — debuffs cleared, enemy targeting broken!")


## Central helper: leave stealth for a unit and apply all leave-stealth perk effects.
func _leave_stealth(unit: Node) -> void:
	unit.is_stealthed = false
	var char_data = unit.character_data if "character_data" in unit else {}

	# Where I Meant to Be (Guile 5): leaving stealth → +15% Attack and +15% Dodge for 1 turn
	if PerkSystem.has_perk(char_data, "where_i_meant_to_be"):
		_apply_status_effect(unit, "Inspired", 1, 0, unit)   # +accuracy proxy
		_apply_status_effect(unit, "Dodge_Buff", 1, 0, unit) # +dodge proxy
		combat_log.emit("Where I Meant to Be — +15%% Attack and Dodge for 1 turn!")


## Shady Dealings (Guile 7): when a stealthed unit performs a non-melee action,
## use the standard detection system (enemies within 5 tiles get AWR checks).
func _shady_dealings_detected(unit: Node) -> bool:
	return _run_stealth_detection(unit)


## Mark an enemy (call_the_shot). The marking unit's field marks the target node.
## Any ally who attacks that target gets the accuracy+damage bonus, then the mark clears.
func _resolve_mark_target(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No valid target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot mark allies"}
	var distance = _grid_distance(user.grid_position, target_pos)
	var max_range = combat_data.get("range", 6)
	if distance > max_range:
		return {"success": false, "reason": "Out of range"}
	# Place the mark on both the marking unit (for team-wide queries) and the target (for quick checks)
	user.marked_target = target
	if "is_marked" in target:
		target.is_marked = true
	combat_log.emit("%s calls the shot on %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "effects": [{"type": "mark_target", "target": target}]}


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


# ============================================
# ACTIVE SKILL RESOLVER — BATCH 2
# (bonus_movement, restore_stamina, revive, debuff_enemies, buff_allies, buff_ally,
#  destroy_obstacle, cleanse_and_buff, grant_extra_action, force_miss, grapple,
#  overcast, retreat, aoe_damage_and_status, buff_allies_debuff_enemies,
#  dispel_and_invert, aggro_aura, share_buffs, double_buffs, restore_armor)
# ============================================

## Attribute-based saving throw. Returns true if the unit SAVES (resists the effect).
## save_type is an attribute name ("strength", "focus", "finesse", etc.)
func _perform_save_roll(unit: Node, save_type: String) -> bool:
	var attrs = unit.character_data.get("attributes", {}) if "character_data" in unit else {}
	var stat_val = attrs.get(save_type, 10)
	# Each point above 10 adds 2% to the save chance; base 40%
	var save_chance = clampf(40.0 + (stat_val - 10) * 2.0, 10.0, 90.0)
	return randf() * 100.0 <= save_chance


## Bonus movement (spring_step, quick_escape): add movement tiles for rest of this turn.
func _resolve_bonus_movement(user: Node, combat_data: Dictionary) -> Dictionary:
	var bonus = combat_data.get("bonus_movement", 2)
	_apply_stat_modifier(user, "movement", bonus, 1)  # Expires at next turn start
	combat_log.emit("%s gains +%d movement this turn!" % [user.unit_name, bonus])
	return {"success": true, "effects": [{"type": "buff", "stat": "movement", "value": bonus}]}


## Restore stamina to all allies (comic_relief).
func _resolve_restore_stamina(user: Node, combat_data: Dictionary) -> Dictionary:
	var pct = combat_data.get("stamina_restore_pct", 15)
	var effects: Array = []
	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		var amount = maxi(1, int(ally.max_stamina * pct / 100.0))
		ally.restore_stamina(amount)
		effects.append({"type": "stamina_restore", "target": ally, "amount": amount})
	combat_log.emit("%s rallies the party — all allies restore %d%% stamina!" % [user.unit_name, pct])
	return {"success": true, "effects": effects}


## Restore armor as a temporary buff (field_repair).
func _resolve_restore_armor(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 2)
	var target: Node
	var dist = _grid_distance(user.grid_position, target_pos)
	if dist == 0:
		target = user
	else:
		target = get_unit_at(target_pos)
		if target == null or not target.is_alive():
			return {"success": false, "reason": "No target"}
		if dist > max_range:
			return {"success": false, "reason": "Out of range"}
		if target.team != user.team:
			return {"success": false, "reason": "Can only repair allies"}

	var pct = combat_data.get("armor_restore_pct", 25)
	var base_armor = target.character_data.get("derived", {}).get("armor", 0) if "character_data" in target else 0
	var armor_amount = maxi(2, int(base_armor * pct / 100.0))
	_apply_stat_modifier(target, "armor", armor_amount, 3)
	combat_log.emit("%s repairs %s's armor (+%d for 3 turns)." % [user.unit_name, target.unit_name, armor_amount])
	return {"success": true, "effects": [{"type": "buff", "stat": "armor", "value": armor_amount}]}


## Revive a bleeding-out or downed ally (miraculous_recovery).
func _resolve_revive_ally(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 2)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null:
		return {"success": false, "reason": "No target"}
	if not (target.is_bleeding_out or target.is_dead):
		return {"success": false, "reason": "Target is not downed"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only revive allies"}

	var heal_pct = combat_data.get("heal_pct", 30)
	var heal_amount = maxi(1, int(target.max_hp * heal_pct / 100.0))

	target.is_bleeding_out = false
	target.is_dead = false
	target.bleed_out_turns = 0
	target.current_hp = mini(heal_amount, target.max_hp)

	if combat_data.get("cleanse_all_debuffs", false):
		target.status_effects.clear()

	unit_healed.emit(target, heal_amount)
	if target.has_method("_update_visuals"):
		target._update_visuals()
	combat_log.emit("%s miraculously revives %s with %d HP!" % [user.unit_name, target.unit_name, heal_amount])
	return {"success": true, "effects": [{"type": "revive", "target": target, "hp": heal_amount}]}


## Debuff enemies in an AoE with a saving throw (intimidating_stance, the_laughter_turns).
func _resolve_debuff_enemies_aoe(user: Node, combat_data: Dictionary, _target_pos: Vector2i) -> Dictionary:
	var aoe_radius = combat_data.get("aoe_radius", 2)
	var targeting = combat_data.get("targeting", "aoe_self")
	var save_type = combat_data.get("save_type", "focus")
	var requires_demoralized = combat_data.get("requires_demoralized", false)
	var statuses_to_apply = combat_data.get("statuses", [])
	var alt_status = combat_data.get("alternate_status", {})
	var effects: Array = []

	var enemy_team = 1 - (user.team if "team" in user else 0)
	var candidates: Array = []
	for enemy in get_team_units(enemy_team):
		if not enemy.is_alive():
			continue
		if targeting != "all_enemies" and _grid_distance(user.grid_position, enemy.grid_position) > aoe_radius:
			continue
		candidates.append(enemy)

	for enemy in candidates:
		# the_laughter_turns: only targets demoralised enemies; uses alternate status otherwise
		if requires_demoralized:
			var is_demoralised = enemy.has_status("Demoralized") or enemy.has_status("Feared") or enemy.has_status("Gloomy")
			if not is_demoralised:
				if not alt_status.is_empty() and not _perform_save_roll(enemy, save_type):
					_apply_status_effect(enemy, alt_status.get("status", "Confused"), alt_status.get("duration", 2), 0, user)
					effects.append({"type": "status", "target": enemy, "status": alt_status.get("status", "")})
				continue

		if _perform_save_roll(enemy, save_type):
			continue  # Resisted

		for se in statuses_to_apply:
			_apply_status_effect(enemy, se.get("status", ""), se.get("duration", 2), 0, user)
			effects.append({"type": "status", "target": enemy, "status": se.get("status", "")})

	combat_log.emit("%s uses an intimidating action on nearby enemies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff all allies with stat modifiers and/or status effects (breath_easy, perfect_volley, roots_of_the_world).
func _resolve_buff_allies_all(user: Node, combat_data: Dictionary) -> Dictionary:
	var buffs = combat_data.get("buffs", [])
	var statuses = combat_data.get("statuses", [])
	var effects: Array = []

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		for buff in buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 2)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})
		for se in statuses:
			_apply_status_effect(ally, se.get("status", ""), se.get("duration", 2), 0, user)
			effects.append({"type": "status", "target": ally, "status": se.get("status", "")})

	combat_log.emit("%s buffs all allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff a single ally (bark_orders, booster_shot, crossdisciplinary_insight).
func _resolve_buff_ally_single(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only buff allies"}

	var buffs = combat_data.get("buffs", [])
	var effects: Array = []
	for buff in buffs:
		var stat = buff.get("stat", "")
		var value = buff.get("value", 0)
		var duration = buff.get("duration", 2)
		if stat == "skill_bonus":
			# crossdisciplinary_insight: generic skill bonus; proxy as accuracy + spellpower bump
			_apply_stat_modifier(target, "accuracy", value * 5, duration)
			_apply_stat_modifier(target, "spellpower", value * 2, duration)
			effects.append({"type": "buff", "target": target, "stat": "skill_bonus", "value": value})
		elif stat == "status_resistance":
			# booster_shot: +25% status resistance — apply as save bonus proxy via stat modifier
			_apply_stat_modifier(target, "save_bonus", value, duration)
			effects.append({"type": "buff", "target": target, "stat": "status_resistance", "value": value})
		elif stat != "":
			_apply_stat_modifier(target, stat, value, duration)
			effects.append({"type": "buff", "target": target, "stat": stat, "value": value})

	var statuses = combat_data.get("statuses", [])
	for se in statuses:
		_apply_status_effect(target, se.get("status", ""), se.get("duration", 2), 0, user)

	combat_log.emit("%s buffs %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Destroy an obstacle at the target tile (universal_solvent).
func _resolve_destroy_obstacle(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 3)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	if combat_grid == null:
		return {"success": false, "reason": "No combat grid"}

	var obs = combat_grid.get_obstacle_at(target_pos)
	if obs.is_empty() or obs.get("type", 0) == 0:
		return {"success": false, "reason": "No obstacle at target"}

	combat_grid.remove_obstacle(target_pos)
	combat_log.emit("%s dissolves the obstacle!" % user.unit_name)
	return {"success": true, "effects": [{"type": "destroy_obstacle", "pos": target_pos}]}


## Cleanse specific statuses then buff all allies in AoE (rally_the_banner).
func _resolve_cleanse_and_buff(user: Node, combat_data: Dictionary) -> Dictionary:
	var cleanse_list = combat_data.get("cleanses", [])  # Status names or categories to remove
	var buffs = combat_data.get("buffs", [])
	var aoe_radius = combat_data.get("aoe_radius", 3)
	var effects: Array = []

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		if _grid_distance(user.grid_position, ally.grid_position) > aoe_radius:
			continue

		# Cleanse matching statuses or categories
		var to_remove: Array[int] = []
		for i in range(ally.status_effects.size()):
			var se_name = ally.status_effects[i].get("status", "")
			if se_name in cleanse_list:
				to_remove.append(i)
			elif "mental" in cleanse_list:
				var def = _status_effects.get(se_name, {})
				if def.get("category", "") == "mental":
					to_remove.append(i)
		to_remove.reverse()
		for idx in to_remove:
			var removed = ally.status_effects[idx].get("status", "")
			ally.status_effects.remove_at(idx)
			effects.append({"type": "cleanse", "target": ally, "status": removed})

		# Apply buffs
		for buff in buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 2)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})

	combat_log.emit("%s rallies nearby allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Grant an extra action to allies in range (this_is_the_moment, summoners_command).
func _resolve_grant_extra_action(user: Node, combat_data: Dictionary, _target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 6)
	var max_targets = combat_data.get("max_targets", 4)
	var summon_only = combat_data.get("summon_only", false)
	var effects: Array = []

	var eligible: Array = []
	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive() or ally == user:
			continue
		if _grid_distance(user.grid_position, ally.grid_position) > max_range:
			continue
		if summon_only and not ("is_summoned" in ally and ally.is_summoned):
			continue
		eligible.append(ally)

	# Sort by proximity, take the closest max_targets
	eligible.sort_custom(func(a, b):
		return _grid_distance(user.grid_position, a.grid_position) < _grid_distance(user.grid_position, b.grid_position))

	var given = 0
	for target in eligible:
		if given >= max_targets:
			break
		target.actions_remaining = mini(target.actions_remaining + 1, target.max_actions + 1)
		effects.append({"type": "extra_action", "target": target})
		combat_log.emit("%s grants %s an extra action!" % [user.unit_name, target.unit_name])
		given += 1

	return {"success": true, "effects": effects}


## Force an enemy's next attack to miss (that_was_supposed_to_miss).
func _resolve_force_miss(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 6)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot jinx allies"}

	if "will_miss_next_attack" in target:
		target.will_miss_next_attack = true
	else:
		target.set("will_miss_next_attack", true)

	combat_log.emit("%s jinxes %s — their next attack will miss!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": [{"type": "force_miss", "target": target}]}


## Grapple a melee target (brawlers_grapple): hit roll then apply Grappled status.
func _resolve_grapple(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 1)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range (grapple is melee only)"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot grapple allies"}

	# Accuracy roll (uses normal melee hit chance)
	var hit_chance = calculate_hit_chance(user, target)
	if randf() * 100.0 > hit_chance:
		combat_log.emit("%s fails to grapple %s!" % [user.unit_name, target.unit_name])
		return {"success": true, "hit": false, "effects": []}

	# Apply statuses from combat_data (Grappled with duration 99 = until escaped)
	var statuses = combat_data.get("statuses", [{"status": "Immobilized", "duration": 2}])
	for se in statuses:
		_apply_status_effect(target, se.get("status", "Immobilized"), se.get("duration", 2), 0, user)

	combat_log.emit("%s grapples %s!" % [user.unit_name, target.unit_name])
	return {"success": true, "hit": true, "target": target, "effects": [{"type": "grapple", "target": target}]}


## Queue an overcast bonus for the caster's next spell (push_the_words, burn_the_breath, etc.).
func _resolve_overcast(user: Node, combat_data: Dictionary) -> Dictionary:
	var next_spell_bonus = combat_data.get("next_spell_bonus", {})
	if next_spell_bonus.is_empty():
		return {"success": false, "reason": "No overcast bonus defined"}

	# requires="ritual_circle": check if standing on one (simplified: log a note if missing)
	if combat_data.get("requires", "") == "ritual_circle":
		# Future: check combat_grid tile effect at user position
		# For now, allow it and log
		combat_log.emit("%s channels power through a ritual circle!" % user.unit_name)
	else:
		combat_log.emit("%s focuses power for an empowered spell!" % user.unit_name)

	if "pending_overcast_bonus" in user:
		user.pending_overcast_bonus = next_spell_bonus
	else:
		user.set("pending_overcast_bonus", next_spell_bonus)

	return {"success": true, "effects": [{"type": "overcast_ready", "bonus": next_spell_bonus}]}


## Teleport the unit to their deployment zone back row (strategic_withdrawal).
func _resolve_retreat(user: Node, _combat_data: Dictionary) -> Dictionary:
	if combat_grid == null:
		return {"success": false, "reason": "No combat grid"}

	var zones: Dictionary
	if ("team" in user) and user.team == 0:
		zones = combat_grid.get_player_deployment_zones()
	else:
		zones = combat_grid.get_enemy_deployment_zones()

	var retreat_tiles: Array = zones.get("back", [])
	if retreat_tiles.is_empty():
		retreat_tiles = zones.get("all", [])

	var dest = Vector2i(-1, -1)
	for tile in retreat_tiles:
		if combat_grid.get_unit_at(tile) == null and combat_grid.is_tile_walkable(tile):
			dest = tile
			break

	if dest == Vector2i(-1, -1):
		return {"success": false, "reason": "No safe position to retreat to"}

	var from = user.grid_position
	combat_grid.move_unit(user, dest)
	unit_moved.emit(user, from, dest)
	combat_log.emit("%s makes a strategic withdrawal!" % user.unit_name)
	return {"success": true, "effects": [{"type": "retreat", "destination": dest}]}


## AoE spell-like damage + status with save (drowning_pressure).
func _resolve_aoe_damage_and_status(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 5)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var aoe_radius = combat_data.get("aoe_radius", 3)
	var damage_pct = combat_data.get("damage_pct", 75)
	var damage_element = combat_data.get("damage_element", "physical")
	var save_type = combat_data.get("save_type", "focus")
	var statuses = combat_data.get("statuses", [])
	var effects: Array = []

	for enemy in get_team_units(1 - (user.team if "team" in user else 0)):
		if not enemy.is_alive():
			continue
		if _grid_distance(target_pos, enemy.grid_position) > aoe_radius:
			continue

		# Spellpower-scaled damage
		var base_dmg = int(user.get_spellpower() * damage_pct / 100.0)
		var resist = enemy.get_resistance(damage_element) if enemy.has_method("get_resistance") else 0.0
		var actual_dmg = maxi(1, int(base_dmg * (1.0 - resist / 100.0)))
		apply_damage(enemy, actual_dmg, damage_element)
		effects.append({"type": "damage", "target": enemy, "damage": actual_dmg})

		# Status on failed save
		if not _perform_save_roll(enemy, save_type) and enemy.is_alive():
			for se in statuses:
				_apply_status_effect(enemy, se.get("status", ""), se.get("duration", 2), 0, user)
				effects.append({"type": "status", "target": enemy, "status": se.get("status", "")})

	_check_immediate_combat_end()
	combat_log.emit("%s unleashes a devastating wave!" % user.unit_name)
	return {"success": true, "effects": effects}


## Buff all allies AND debuff all enemies (crowd_influence).
## Enemy debuff values in combat_data are already negative.
func _resolve_buff_allies_debuff_enemies(user: Node, combat_data: Dictionary) -> Dictionary:
	var ally_buffs = combat_data.get("ally_buffs", [])
	var enemy_debuffs = combat_data.get("enemy_debuffs", [])
	var enemy_save_type = combat_data.get("enemy_save_type", "focus")
	var effects: Array = []

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive():
			continue
		for buff in ally_buffs:
			var stat = buff.get("stat", "")
			var value = buff.get("value", 0)
			var duration = buff.get("duration", 3)
			if stat != "":
				_apply_stat_modifier(ally, stat, value, duration)
				effects.append({"type": "buff", "target": ally, "stat": stat, "value": value})

	for enemy in get_team_units(1 - (user.team if "team" in user else 0)):
		if not enemy.is_alive():
			continue
		if _perform_save_roll(enemy, enemy_save_type):
			continue
		for debuff in enemy_debuffs:
			var stat = debuff.get("stat", "")
			var value = debuff.get("value", 0)  # Already negative in combat_data
			var duration = debuff.get("duration", 3)
			if stat != "":
				_apply_stat_modifier(enemy, stat, value, duration)
				effects.append({"type": "debuff", "target": enemy, "stat": stat, "value": value})

	combat_log.emit("%s shifts the tide of battle!" % user.unit_name)
	return {"success": true, "effects": effects}


## Remove buffs from target and apply them inverted as debuffs (unraveling).
func _resolve_dispel_and_invert(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 5)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}

	var duration = combat_data.get("duration", 2)
	var effects: Array = []

	# Remove all buff statuses from target
	var to_remove: Array[int] = []
	for i in range(target.status_effects.size()):
		var se_name = target.status_effects[i].get("status", "")
		var def = _status_effects.get(se_name, {})
		if def.get("type", "") == "buff":
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		var removed = target.status_effects[idx].get("status", "")
		target.status_effects.remove_at(idx)
		effects.append({"type": "dispelled", "status": removed})

	# Invert positive stat_modifiers into negatives
	var inverted_count = 0
	if "stat_modifiers" in target:
		for mod in target.stat_modifiers:
			if mod.get("value", 0) > 0:
				_apply_stat_modifier(target, mod.get("stat", ""), -mod.get("value", 0), duration)
				inverted_count += 1

	# Apply Cursed as a general debuff token representing the inversion
	if to_remove.size() > 0 or inverted_count > 0:
		_apply_status_effect(target, "Cursed", duration, 0, user)
		effects.append({"type": "inverted", "count": to_remove.size() + inverted_count})

	combat_log.emit("%s unravels %s's buffs!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Taunt: set aggro aura so enemies prefer to attack this unit (look_at_me).
func _resolve_aggro_aura(user: Node, combat_data: Dictionary) -> Dictionary:
	var duration = combat_data.get("duration", 2)
	if "taunt_active" in user:
		user.taunt_active = true
		user.taunt_duration = duration
	else:
		user.set("taunt_active", true)
		user.set("taunt_duration", duration)
	combat_log.emit("%s draws all nearby attention!" % user.unit_name)
	return {"success": true, "effects": [{"type": "aggro_aura", "duration": duration}]}


## Share active buffs from caster to all allies (absolute_presence).
func _resolve_share_buffs(user: Node, combat_data: Dictionary) -> Dictionary:
	var cap_duration = combat_data.get("duration", 2)
	var effects: Array = []

	# Collect caster's positive stat modifiers and buff statuses
	var user_mods: Array = user.stat_modifiers if "stat_modifiers" in user else []
	var user_buff_statuses: Array = []
	for se in user.status_effects:
		var def = _status_effects.get(se.get("status", ""), {})
		if def.get("type", "") == "buff":
			user_buff_statuses.append(se)

	for ally in get_team_units(user.team if "team" in user else 0):
		if not ally.is_alive() or ally == user:
			continue
		for mod in user_mods:
			if mod.get("value", 0) > 0:
				_apply_stat_modifier(ally, mod.get("stat", ""), mod.get("value", 0),
					mini(mod.get("duration", 1), cap_duration))
				effects.append({"type": "shared_buff", "target": ally, "stat": mod.get("stat", "")})
		for buff_se in user_buff_statuses:
			_apply_status_effect(ally, buff_se.get("status", ""),
				mini(buff_se.get("duration", 1), cap_duration), 0, user)
			effects.append({"type": "shared_status", "target": ally, "status": buff_se.get("status", "")})

	combat_log.emit("%s shares their power with all allies!" % user.unit_name)
	return {"success": true, "effects": effects}


## Double all active buff modifiers on a single ally (masterwork).
func _resolve_double_buffs(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var max_range = combat_data.get("range", 4)
	if _grid_distance(user.grid_position, target_pos) > max_range:
		return {"success": false, "reason": "Out of range"}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team != user.team:
		return {"success": false, "reason": "Can only use on allies"}

	var effects: Array = []
	if "stat_modifiers" in target:
		for mod in target.stat_modifiers:
			if mod.get("value", 0) > 0:
				mod.value *= 2
				effects.append({"type": "doubled", "stat": mod.get("stat", ""), "new_value": mod.value})

	combat_log.emit("%s's masterwork doubles %s's active buffs!" % [user.unit_name, target.unit_name])
	return {"success": true, "target": target, "effects": effects}


## Chöd Offering (Kangling): sacrifice 25% of max mana, or HP if mana insufficient.
## Gain ceil(cost/2) Spellpower stacking until end of combat.
func _resolve_chod_offering(user: Node, _combat_data: Dictionary) -> Dictionary:
	var cost = int(floor(user.max_mana * 0.25))
	if cost <= 0:
		cost = 1  # minimum sacrifice

	# Deduct from mana first, remainder from HP
	var mana_used = mini(cost, user.current_mana)
	var hp_used = cost - mana_used
	user.current_mana -= mana_used
	if "character_data" in user:
		user.character_data.get("derived", {})["current_mana"] = user.current_mana

	if hp_used > 0:
		apply_damage(user, hp_used, "sacrifice")  # bypass armor — it's a ritual sacrifice
		combat_log.emit("%s's Chöd cuts into flesh — mana depleted, spending %d HP!" % [user.unit_name, hp_used])
	else:
		combat_log.emit("%s performs Chöd Offering — sacrifices %d mana!" % [user.unit_name, mana_used])

	# Gain accumulated Spellpower
	var sp_gain = ceili(cost / 2.0)
	user.chod_spellpower_bonus += sp_gain
	combat_log.emit("%s gains +%d Spellpower from the offering (total +%d)." % [user.unit_name, sp_gain, user.chod_spellpower_bonus])

	return {
		"success": true,
		"mana_sacrificed": mana_used,
		"hp_sacrificed": hp_used,
		"spellpower_gained": sp_gain,
		"effects": [{"type": "chod_spellpower", "amount": sp_gain}]
	}


## Throw Phurba: ranged attack (any range), Sorcery-scaled damage.
## Target makes DC 16 Focus save; failure = Subjugated 3 turns.
func _resolve_throw_phurba(user: Node, combat_data: Dictionary, target_pos: Vector2i) -> Dictionary:
	var item_id = combat_data.get("item_id", "")
	var item = ItemSystem.get_item(item_id) if item_id != "" else {}
	var mana_cost = item.get("throw_mana_cost", 15)
	var base_damage = item.get("throw_base_damage", 8)
	var save_dc = item.get("throw_save_dc", 16)

	if user.current_mana < mana_cost:
		return {"success": false, "reason": "Not enough mana (%d/%d)" % [user.current_mana, mana_cost]}

	var target = get_unit_at(target_pos)
	if target == null or not target.is_alive():
		return {"success": false, "reason": "No target"}
	if target.team == user.team:
		return {"success": false, "reason": "Cannot throw at allies"}

	# Deduct mana
	user.current_mana -= mana_cost
	if "character_data" in user:
		user.character_data.get("derived", {})["current_mana"] = user.current_mana

	# Calculate damage: base + sorcery_skill_level * 2
	var user_char = user.character_data if "character_data" in user else {}
	var sorcery_level = user_char.get("skills", {}).get("sorcery", 0)
	var total_damage = base_damage + sorcery_level * 2
	apply_damage(target, total_damage, "physical")
	combat_log.emit("%s hurls a Phurba at %s for %d damage!" % [user.unit_name, target.unit_name, total_damage])

	# Focus save vs DC — defender's Focus attribute vs DC
	var defender_focus = target.character_data.get("attributes", {}).get("focus", 10) if "character_data" in target else 10
	var save_roll = randi() % 20 + 1 + defender_focus  # d20 + Focus
	var subjugated = false
	if save_roll < save_dc:
		_apply_status_effect(target, "Subjugated", 3, 0, user)
		subjugated = true
		combat_log.emit("%s fails the Focus save — Subjugated for 3 turns!" % target.unit_name)
	else:
		combat_log.emit("%s resists the Phurba's binding (save %d vs DC %d)." % [target.unit_name, save_roll, save_dc])

	return {
		"success": true,
		"hit": true,
		"damage": total_damage,
		"target": target,
		"subjugated": subjugated,
		"effects": [{"type": "aoe_damage", "target": target, "damage": total_damage}]
	}


## Get valid target tiles for an active skill based on its targeting type
func get_active_skill_targets(user: Node, combat_data: Dictionary) -> Array[Vector2i]:
	var targeting = combat_data.get("targeting", "self")
	var skill_range = combat_data.get("range", 1)
	var result: Array[Vector2i] = []

	match targeting:
		"self":
			result.append(user.grid_position)
		"single_enemy":
			# All enemy tiles within range (hidden enemies excluded)
			for unit in all_units:
				if not unit.is_alive() or unit.team == user.team:
					continue
				if not unit.is_targetable():
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
				if not unit.is_targetable():
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


# ============================================
# PASSIVE PERK COMBAT INTEGRATION
# ============================================
# Framework for checking passive perks during combat events.
# Passive perks (no combat_data) describe effects in text; this section
# implements the mechanical effects for the most impactful ones.
#
# Perk checking helpers:
# - _unit_has_perk(unit, perk_id) -> bool
# - _get_passive_stat_bonus(unit, stat) -> int/float
# - _process_on_hit_perks(attacker, defender, result) -> void
# - _process_on_dodge_perks(unit, attacker) -> void
# - _process_turn_start_perks(unit) -> void


## Check if a combat unit has a specific perk.
## Works for both CombatUnit nodes and basic unit nodes with character_data.
func _unit_has_perk(unit: Node, perk_id: String) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	return PerkSystem.has_perk(char_data, perk_id)


## Get all talisman perk IDs for a unit (from trinket1 and trinket2 slots)
func _get_talisman_perks(unit: Node) -> Array[String]:
	var perks: Array[String] = []
	var char_data = unit.character_data if "character_data" in unit else {}
	var equipment = char_data.get("equipment", {})
	for slot in ["trinket1", "trinket2"]:
		var item_id = equipment.get(slot, "")
		if item_id == "":
			continue
		var item = ItemSystem.get_item(item_id)
		var perk_id = item.get("passive", {}).get("perk", "")
		if perk_id != "":
			perks.append(perk_id)
	return perks


## Check if a unit has a specific talisman perk
func _unit_has_talisman_perk(unit: Node, perk_id: String) -> bool:
	return perk_id in _get_talisman_perks(unit)


## Check if a character perk grants immunity or resistance to a status effect.
## Returns true if the status should be blocked.
func _check_perk_status_immunity(unit: Node, status: String) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	var status_lower = status.to_lower()

	# Diamond Body: immune to poison and disease while unarmored
	if PerkSystem.has_perk(char_data, "diamond_body") and _unit_is_unarmored(unit):
		if status_lower in ["poisoned", "diseased"]:
			return true

	# Empty Center: +20% resistance to mental effects
	# Centered Stance: +15% resistance to mental effects while wielding a sword
	var mental_statuses = ["feared", "charmed", "confused", "berserk", "mind_controlled"]
	if status_lower in mental_statuses:
		var mental_resist_pct = 0.0
		if PerkSystem.has_perk(char_data, "empty_center"):
			mental_resist_pct += 0.20
		if PerkSystem.has_perk(char_data, "centered_stance"):
			if unit.has_method("get_equipped_weapon"):
				if unit.get_equipped_weapon().get("type", "") == "sword":
					mental_resist_pct += 0.15
		if mental_resist_pct > 0.0 and randf() < mental_resist_pct:
			return true

	# Empty Center: +25% save vs forced movement, stuns, knockdowns
	var physical_cc = ["stunned", "knocked_down", "pushed", "pulled"]
	if status_lower in physical_cc:
		if PerkSystem.has_perk(char_data, "empty_center"):
			if randf() < 0.25:
				return true

	# Diamond Body while unarmored: +25% general status resistance
	if PerkSystem.has_perk(char_data, "diamond_body") and _unit_is_unarmored(unit):
		if randf() < 0.25:
			return true

	# Laughing at the Abyss: immune to fear, despair, intimidation
	var comedy_immune = ["feared", "intimidated", "demoralized", "despair"]
	if status_lower in comedy_immune:
		if PerkSystem.has_perk(char_data, "laughing_at_the_abyss"):
			return true

	# Bare Chest: +25% resistance to fear and pain effects while unarmored
	var fear_pain = ["feared", "agonized", "pain"]
	if status_lower in fear_pain:
		if PerkSystem.has_perk(char_data, "bare_chest") and _unit_is_unarmored(unit):
			if randf() < 0.25:
				return true

	# Juggernaut: at 50%+ HP, immune to Slow, knockback, and forced movement
	var juggernaut_immune = ["slowed", "pushed", "pulled", "knocked_back", "rooted"]
	if status_lower in juggernaut_immune:
		if PerkSystem.has_perk(char_data, "juggernaut"):
			if "current_hp" in unit and "max_hp" in unit:
				if unit.current_hp >= unit.max_hp * 0.5:
					return true

	# Pain Is Just Information (Might 4): +25% resistance to Stun, Knockdown, and Exhaustion
	var pain_immune = ["stunned", "knocked_down", "exhausted"]
	if status_lower in pain_immune:
		if PerkSystem.has_perk(char_data, "pain_is_just_information"):
			if randf() < 0.25:
				return true

	# Unbroken Circle (Leadership 4): +15% mental status resistance with 2+ allies standing
	var mental_cc = ["feared", "charmed", "confused", "berserk", "mind_controlled", "intimidated", "demoralized"]
	if status_lower in mental_cc:
		var ub_ally_count = get_team_units(unit.team if "team" in unit else 0).size() - 1
		if ub_ally_count >= 2:
			var ub_resist = 0.15 + 0.03 * (ub_ally_count - 2)  # +3% per additional ally
			# Also check if any ally has the perk (aura) or if the unit itself has it
			var has_leader = PerkSystem.has_perk(char_data, "unbroken_circle")
			if not has_leader:
				for ally in get_team_units(unit.team if "team" in unit else 0):
					if ally == unit: continue
					var ally_char = ally.character_data if "character_data" in ally else {}
					if PerkSystem.has_perk(ally_char, "unbroken_circle"):
						has_leader = true
						break
			if has_leader and randf() < ub_resist:
				return true

	return false


## Check if a unit is unarmored or wearing only light armor (robe/hat/cloth).
## Used by unarmored perks like Flowing Footwork and Diamond Body.
## Returns true if the unit is tagged as biological (affected by anatomy_knowledge, pressure_points).
## Non-biological: constructs, elementals, undead, ethereals.
func _unit_is_biological(unit: Node) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	return "biological" in char_data.get("tags", [])


func _unit_is_unarmored(unit: Node) -> bool:
	var char_data = unit.character_data if "character_data" in unit else {}
	var equipment = char_data.get("equipment", {})
	for slot in ["chest", "head", "hands", "legs"]:
		var item_id = equipment.get(slot, "")
		if item_id == "":
			continue
		var item = ItemSystem.get_item(item_id)
		var item_type = item.get("type", "")
		if not item_type in ["robe", "hat", "cloth", ""]:
			return false
	return true


## Get passive perk stat bonuses for a unit.
## Called by CombatUnit stat getters to include perk effects.
## Returns the total bonus/penalty for the given stat.
func get_passive_perk_stat_bonus(unit: Node, stat: String) -> int:
	var total := 0
	var char_data = unit.character_data if "character_data" in unit else {}

	# --- Equipment-based bonuses (apply regardless of whether the unit has perks) ---
	match stat:
		"armor":
			# Bichawa parry: off-hand Bichawa adds (accuracy × parry_effectiveness / 100) to armor
			var bichawa_id = ItemSystem.get_equipped_item(char_data, "weapon_off")
			if bichawa_id != "":
				var bichawa_item = ItemSystem.get_item(bichawa_id)
				var parry_eff = bichawa_item.get("stats", {}).get("parry_effectiveness", 0)
				if parry_eff > 0:
					var acc = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
					total += int(acc * parry_eff / 100.0)
		"initiative":
			# Khatvanga aura: any adjacent enemy wielding a Khatvanga reduces this unit's initiative
			if "grid_position" in unit and "team" in unit:
				var enemy_team = 1 - unit.team
				for enemy in get_team_units(enemy_team):
					if not "grid_position" in enemy:
						continue
					if _grid_distance(unit.grid_position, enemy.grid_position) > 1:
						continue
					var enemy_char = enemy.character_data if "character_data" in enemy else {}
					var khata_id = ItemSystem.get_equipped_item(enemy_char, "weapon_main")
					if khata_id != "":
						var khata_item = ItemSystem.get_item(khata_id)
						if khata_item.get("passive_aura", "") == "initiative_debuff":
							total -= khata_item.get("aura_value", 3)

	if not char_data.has("perks"):
		return total  # No perks — return equipment-only bonuses

	match stat:
		"armor":
			# Parry: 20% of Attack added to Armor while wielding a sword
			if PerkSystem.has_perk(char_data, "parry"):
				if unit.has_method("get_equipped_weapon"):
					var weapon = unit.get_equipped_weapon()
					if weapon.get("type", "") == "sword":
						var attack = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
						total += int(attack * 0.2)
			# Improved Parry: 40% of Attack added to Armor
			if PerkSystem.has_perk(char_data, "improved_parry"):
				if unit.has_method("get_equipped_weapon"):
					var weapon = unit.get_equipped_weapon()
					if weapon.get("type", "") == "sword":
						var attack = unit.get_accuracy() if unit.has_method("get_accuracy") else 0
						# Improved replaces base parry bonus (not additive)
						total += int(attack * 0.2)  # Extra 20% on top of parry's 20%
			# Stone Adept: +10% Armor (use base derived armor to avoid recursion)
			if PerkSystem.has_perk(char_data, "stone_adept"):
				var derived = char_data.get("derived", {})
				total += int(derived.get("armor", 0) * 0.1)
			# Iron Shirt Technique: 30% of unarmed Attack added to Armor while unarmored
			if PerkSystem.has_perk(char_data, "iron_shirt_technique"):
				if _unit_is_unarmored(unit):
					var unarmed_attack = unit.get_attack_damage() if unit.has_method("get_attack_damage") else 0
					total += int(unarmed_attack * 0.3)
			# Tidal Patience: +5% Armor per stationary stack (up to +15%)
			if PerkSystem.has_perk(char_data, "tidal_patience"):
				if "stationary_stacks" in unit and unit.stationary_stacks > 0:
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.05 * unit.stationary_stacks)
			# Disciplined Formation: +10% Armor while adjacent to an ally
			if PerkSystem.has_perk(char_data, "disciplined_formation"):
				var allies = _get_allies_in_range(unit, 1)
				if allies.size() > 0:
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.1)
			# Grounded (Might 2): +15% Armor when you haven't moved this turn
			if PerkSystem.has_perk(char_data, "grounded"):
				if not ("moved_this_turn" in unit and unit.moved_this_turn):
					var derived_armor = char_data.get("derived", {}).get("armor", 0)
					total += int(derived_armor * 0.15)
			# No One Left Behind (Leadership 3): when below 30% HP, gain +20% Armor if any ally has this perk
			if "current_hp" in unit and "max_hp" in unit:
				if unit.current_hp < unit.max_hp * 0.30:
					var leader_present = PerkSystem.has_perk(char_data, "no_one_left_behind")
					if not leader_present:
						for ally in get_team_units(unit.team if "team" in unit else 0):
							if ally == unit: continue
							var ally_char = ally.character_data if "character_data" in ally else {}
							if PerkSystem.has_perk(ally_char, "no_one_left_behind"):
								leader_present = true
								break
					if leader_present:
						var derived_armor = char_data.get("derived", {}).get("armor", 0)
						total += int(derived_armor * 0.20)

		"damage":
			# Use base derived damage to avoid recursion (get_attack_damage calls us)
			var derived_dmg = char_data.get("derived", {}).get("damage", 0)
			# All In: +25% axe damage below 50% HP
			if PerkSystem.has_perk(char_data, "all_in"):
				if "current_hp" in unit and "max_hp" in unit:
					if unit.current_hp < unit.max_hp / 2:
						if unit.has_method("get_equipped_weapon"):
							if unit.get_equipped_weapon().get("type", "") == "axe":
								total += int(derived_dmg * 0.25)
			# Weapon Master: +10% all weapon damage
			if PerkSystem.has_perk(char_data, "weapon_master"):
				total += int(derived_dmg * 0.1)
			# Commitment: +20% damage if you did not move before attacking
			if PerkSystem.has_perk(char_data, "commitment"):
				if not ("moved_this_turn" in unit and unit.moved_this_turn):
					if unit.has_method("get_equipped_weapon"):
						if unit.get_equipped_weapon().get("type", "") == "axe":
							total += int(derived_dmg * 0.2)
			# Momentum: +10% damage per consecutive axe hit stack
			if PerkSystem.has_perk(char_data, "momentum"):
				if "momentum_stacks" in unit and unit.momentum_stacks > 0:
					if unit.has_method("get_equipped_weapon"):
						if unit.get_equipped_weapon().get("type", "") == "axe":
							total += int(derived_dmg * 0.1 * unit.momentum_stacks)
			# Keep Hitting: +10% damage per consecutive unarmed hit stack
			if PerkSystem.has_perk(char_data, "keep_hitting"):
				if "unarmed_hit_stacks" in unit and unit.unarmed_hit_stacks > 0:
					if unit.has_method("get_equipped_weapon"):
						var w = unit.get_equipped_weapon()
						if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
							total += int(derived_dmg * 0.1 * unit.unarmed_hit_stacks)
			# Tidal Patience: +5% Damage per stationary stack (up to +15%)
			if PerkSystem.has_perk(char_data, "tidal_patience"):
				if "stationary_stacks" in unit and unit.stationary_stacks > 0:
					total += int(derived_dmg * 0.05 * unit.stationary_stacks)
			# Disciplined Formation: +10% damage (accuracy) while adjacent to an ally
			if PerkSystem.has_perk(char_data, "disciplined_formation"):
				if _get_allies_in_range(unit, 1).size() > 0:
					total += int(derived_dmg * 0.1)

		"max_hp":
			# Stone Adept: +10% max HP
			if PerkSystem.has_perk(char_data, "stone_adept"):
				total += int(unit.max_hp * 0.1) if "max_hp" in unit else 0

		"initiative":
			# Centered Stance: +10% Initiative while wielding a sword
			if PerkSystem.has_perk(char_data, "centered_stance"):
				if unit.has_method("get_equipped_weapon"):
					if unit.get_equipped_weapon().get("type", "") == "sword":
						var derived_init = char_data.get("derived", {}).get("initiative", 0)
						total += int(derived_init * 0.1)

		"movement":
			# Wind Adept: +1 permanent Movement
			if PerkSystem.has_perk(char_data, "wind_adept"):
				total += 1
			# Flowing Footwork: +1 Movement while unarmored or in light armor
			if PerkSystem.has_perk(char_data, "flowing_footwork"):
				if _unit_is_unarmored(unit):
					total += 1

		"crit_chance":
			# Open the Gate: +15% crit chance after moving at least 1 tile this turn
			if PerkSystem.has_perk(char_data, "open_the_gate"):
				if "moved_this_turn" in unit and unit.moved_this_turn:
					total += 15
			# Short Range Violence: +10% crit with unarmed attacks
			if PerkSystem.has_perk(char_data, "short_range_violence"):
				if unit.has_method("get_equipped_weapon"):
					var w = unit.get_equipped_weapon()
					if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
						total += 10

		"dodge":
			# Flowing Footwork: +10% Dodge while unarmored or in light armor
			if PerkSystem.has_perk(char_data, "flowing_footwork"):
				if _unit_is_unarmored(unit):
					total += 10
			# Summoner's Bond: +5% Dodge/saves while 1+ summon is active
			# (Summons are units with the 'summoned' tag on their character_data)
			if PerkSystem.has_perk(char_data, "summoners_bond"):
				for ally in get_team_units(unit.team if "team" in unit else 0):
					var ally_char = ally.character_data if "character_data" in ally else {}
					if "summoned" in ally_char.get("tags", []):
						total += 5
						break
			# Talisman: Blur — +10% dodge chance
			if _unit_has_talisman_perk(unit, "blur"):
				total += 10
			# Talisman: Lucky Escape — +15% dodge below 25% HP
			if _unit_has_talisman_perk(unit, "lucky_escape"):
				if "current_hp" in unit and "max_hp" in unit:
					if unit.current_hp < unit.max_hp * 0.25:
						total += 15

	return total


## Process on-hit procs from weapon passive dict.
## Called from attack_unit() after damage lands, alongside _process_on_hit_perks.
func _process_weapon_on_hit_procs(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not attacker.has_method("get_equipped_weapon"):
		return
	var weapon = attacker.get_equipped_weapon()

	# Trishula on_crit_status: apply a status when this attack was a crit
	if result.get("crit", false):
		var on_crit_status = weapon.get("on_crit_status", "")
		if on_crit_status != "":
			_apply_status_effect(defender, on_crit_status, 1)
			result["on_crit_status"] = on_crit_status

	# Chakram pass_through: hit the next unit in the attack line beyond the defender
	var pass_count = weapon.get("pass_through", 0)
	if pass_count > 0 and "grid_position" in attacker and "grid_position" in defender:
		var dir = (defender.grid_position - attacker.grid_position)
		var step_x = 0 if dir.x == 0 else (1 if dir.x > 0 else -1)
		var step_y = 0 if dir.y == 0 else (1 if dir.y > 0 else -1)
		var step := Vector2i(step_x, step_y)
		var check_pos := defender.grid_position + step
		var passed := 0
		for _i in range(10):  # sanity cap — walk forward through the grid
			if passed >= pass_count:
				break
			var through_target: Node = null
			for u in all_units:
				if u == attacker or u == defender:
					continue
				if "grid_position" in u and u.grid_position == check_pos and u.is_alive():
					through_target = u
					break
			if through_target != null:
				var pass_dmg = int(result.get("damage", 0) * 0.75)
				pass_dmg = maxi(1, pass_dmg)
				apply_damage(through_target, pass_dmg, result.get("damage_type", "physical"))
				combat_log.emit("%s's chakram passes through to %s!" % [attacker.unit_name, through_target.unit_name])
				result["pass_through_hit"] = true
				passed += 1
			check_pos += step

	var passive = weapon.get("passive", {})
	if passive.is_empty():
		return

	# Status procs — roll each chance independently
	var status_procs = {
		"poison_chance":  "Poisoned",
		"bleed_chance":   "Bleeding",
		"stun_chance":    "Stunned",
		"burn_chance":    "Burning",
		"freeze_chance":  "Chilled",
		"silence_chance": "Silenced",
	}
	for key in status_procs:
		if key in passive and randf() * 100.0 <= passive[key]:
			_apply_status_effect(defender, status_procs[key], 3)

	# Dispel: remove one random buff from the defender
	# status_effects is an Array of {status, duration} dicts — NOT a Dictionary
	if "dispel_chance" in passive and randf() * 100.0 <= passive["dispel_chance"]:
		if "status_effects" in defender:
			var buff_indices: Array = []
			for i in range(defender.status_effects.size()):
				var effect = defender.status_effects[i]
				var sdef = get_status_definition(effect.get("status", ""))
				if sdef.get("type", "debuff") == "buff":
					buff_indices.append(i)
			if buff_indices.size() > 0:
				defender.status_effects.remove_at(buff_indices[randi() % buff_indices.size()])

	# Lifesteal
	if "lifesteal" in passive:
		var steal = int(result.get("damage", 0) * passive["lifesteal"] / 100.0)
		if steal > 0:
			attacker.heal(steal)
			unit_healed.emit(attacker, steal)
			result["weapon_lifesteal"] = steal

	# Manasteal
	if "manasteal" in passive:
		var steal_mana = int(result.get("damage", 0) * passive["manasteal"] / 100.0)
		if steal_mana > 0 and "current_mana" in defender:
			var actual = mini(steal_mana, defender.current_mana)
			defender.current_mana = defender.current_mana - actual
			attacker.restore_mana(actual)
			result["weapon_manasteal"] = actual

	# Elemental damage bonus attacks
	if "elemental_damage" in passive:
		for element in passive["elemental_damage"]:
			var dmg = passive["elemental_damage"][element]
			if dmg > 0:
				apply_damage(defender, dmg, element)
				if not "elemental_procs" in result:
					result["elemental_procs"] = {}
				result["elemental_procs"][element] = dmg


## Process special effects from ammo: fire arrow AoE or status proc arrows.
## Called on hit only — a missed shot produces no explosion or status.
## apply_damage() is used for AoE hits (handles death, bleed-out, mantra interruption).
func _process_ammo_special_effect(attacker: Node, defender: Node, ammo: Dictionary) -> void:
	var effect = ammo.get("special_effect", {})
	match effect.get("type", ""):

		"aoe_fire":
			var radius = effect.get("radius", 1)
			var aoe_damage = effect.get("damage", 10)
			var element = effect.get("element", "fire")
			combat_log.emit("%s's %s explodes!" % [attacker.unit_name, ammo.get("name", "arrow")])
			for unit in all_units:
				if not unit.is_alive():
					continue
				var dist = abs(unit.grid_position.x - defender.grid_position.x) \
						 + abs(unit.grid_position.y - defender.grid_position.y)
				if dist > 0 and dist <= radius:
					var resistance = unit.get_resistance(element) if unit.has_method("get_resistance") else 0.0
					var final_dmg = maxi(1, int(aoe_damage * (1.0 - resistance / 100.0)))
					apply_damage(unit, final_dmg, element)
					combat_log.emit("%s takes %d %s damage from the explosion." % [unit.unit_name, final_dmg, element])

		"status":
			var chance = effect.get("chance", 100)
			if randi() % 100 < chance:
				var status = effect.get("status", "")
				var duration = effect.get("duration", 2)
				if status != "":
					_apply_status_effect(defender, status, duration, 0, attacker)
					combat_log.emit("%s is afflicted with %s from the arrow." % [defender.unit_name, status])


## Deduct durability from the attacker's equipped weapon after use.
## fragility in item.generated.fragility = durability cost per attack.
## Vajra (fragility 0.0) and static items never degrade.
func _deduct_weapon_durability(unit: Node) -> void:
	if not unit.has_method("get_equipped_weapon"):
		return
	var weapon = unit.get_equipped_weapon()
	if weapon.is_empty():
		return
	var fragility: float = weapon.get("generated", {}).get("fragility", 0.0)
	if fragility <= 0.0:
		return  # Indestructible or not a generated item
	if not "character_data" in unit:
		return
	var item_id = ItemSystem.get_equipped_item(unit.character_data, "weapon_main")
	if item_id == "" or not item_id.begins_with("gen_"):
		return  # Static items don't track wear
	var current_dur: int = weapon.get("durability", 1)
	var new_dur: int = maxi(0, current_dur - int(ceil(fragility)))
	ItemSystem.update_item_durability(item_id, new_dur)
	if new_dur == 0:
		combat_log.emit("%s's %s has broken!" % [unit.unit_name, weapon.get("name", "weapon")])


## Process passive perks that trigger when a unit hits an enemy.
## Called from attack_unit() after damage is applied.
func _process_on_hit_perks(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not result.get("hit", false):
		return

	# Flame Fist: crits cause 3-turn burn on unarmed attacks
	if _unit_has_perk(attacker, "flame_fist") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			var weapon = attacker.get_equipped_weapon()
			if weapon.is_empty() or weapon.get("type", "") in ["", "unarmed"]:
				_apply_status_effect(defender, "Burning", 3)

	# Sudden End (Daggers 7): stealth first attack applies severe bleed (10% max HP/turn, 3t)
	if _unit_has_perk(attacker, "sudden_end") and "is_stealthed" in attacker and attacker.is_stealthed:
		var bleed_val = ceili(defender.max_hp * 0.10)
		_apply_status_effect(defender, "Bleeding", 3, bleed_val, attacker)

	# Relentless (Unarmed cross): crit with unarmed → free unarmed attack on the same target
	if _unit_has_perk(attacker, "relentless") and result.get("crit", false) and not attacker.in_free_attack:
		if attacker.has_method("get_equipped_weapon"):
			var rel_w = attacker.get_equipped_weapon()
			if rel_w.is_empty() or rel_w.get("type", "") in ["", "unarmed"]:
				_trigger_free_attack(attacker, defender)

	# Thunder Breaker: stuns also silence
	if _unit_has_perk(attacker, "thunder_breaker"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "mace":
				if defender.has_status("Stunned"):
					_apply_status_effect(defender, "Silenced", 1)

	# Curseblade: dagger crits have 30% chance to apply Weakness, Blind, or Slow for 2 turns
	if _unit_has_perk(attacker, "curseblade") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "dagger":
				if randf() < 0.30:
					var curses = ["Weakened", "Blinded", "Slowed"]
					var chosen = curses[randi() % curses.size()]
					_apply_status_effect(defender, chosen, 2, 0, attacker)
					result["curseblade_curse"] = chosen

	# Rattle the Cage: unarmed crits apply Stun for 1 turn
	if _unit_has_perk(attacker, "rattle_the_cage") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				_apply_status_effect(defender, "Stunned", 1, 0, attacker)

	# See Stars: unarmed hit vs statused target → 25% chance Stun/Knockdown/Blind (1 turn)
	if _unit_has_perk(attacker, "see_stars"):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				if "status_effects" in defender and defender.status_effects.size() > 0:
					if randf() < 0.25:
						var cc = ["Stunned", "Knocked_Down", "Blinded"]
						_apply_status_effect(defender, cc[randi() % cc.size()], 1, 0, attacker)

	# No Time to Breathe: unarmed hit → -5% dodge, -2 initiative on target (stackable, 2 turns)
	if _unit_has_perk(attacker, "no_time_to_breathe"):
		if attacker.has_method("get_equipped_weapon"):
			var w = attacker.get_equipped_weapon()
			if w.is_empty() or w.get("type", "") in ["", "unarmed"]:
				_apply_stat_modifier(defender, "dodge", -5, 2)
				_apply_stat_modifier(defender, "initiative", -2, 2)

	# Heavy Swing: axe hits reduce target Armor by 5% for 1 turn (stacking)
	if _unit_has_perk(attacker, "heavy_swing"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "axe":
				var armor_pen = int(defender.get_armor() * 0.05)
				if armor_pen > 0:
					_apply_stat_modifier(defender, "armor", -armor_pen, 1)

	# Wide Arc: axe attack deals 50% splash damage to one random adjacent enemy
	if _unit_has_perk(attacker, "wide_arc"):
		if attacker.has_method("get_equipped_weapon"):
			if attacker.get_equipped_weapon().get("type", "") == "axe":
				var splash_targets = _get_enemies_in_range(attacker, 1)
				splash_targets.erase(defender)  # don't double-hit primary target
				if not splash_targets.is_empty():
					var splash_target = splash_targets[randi() % splash_targets.size()]
					var splash_dmg = maxi(1, result.get("damage", 0) / 2)
					apply_damage(splash_target, splash_dmg, result.get("damage_type", "slashing"))
					result["splash_damage"] = splash_dmg

	# Concussive Force: 20% chance to Daze target for 1 turn on any mace hit
	if _unit_has_perk(attacker, "concussive_force"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			if randf() < 0.20:
				_apply_status_effect(defender, "Dazed", 1, 0, attacker)

	# Shieldbreaker: mace hits reduce target Armor by 10% for 3 turns (stacking debuff)
	if _unit_has_perk(attacker, "shieldbreaker"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			var shatter_amt = int(defender.get_armor() * 0.10)
			if shatter_amt > 0:
				_apply_stat_modifier(defender, "armor", -shatter_amt, 3)

	# Thunderous Impact: mace crits knock defender prone (Knocked_Down) and Daze for 2 turns
	if _unit_has_perk(attacker, "thunderous_impact") and result.get("crit", false):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			_apply_status_effect(defender, "Knocked_Down", 1, 0, attacker)
			_apply_status_effect(defender, "Dazed", 2, 0, attacker)

	# Relentless Advance: mace hit grants +1 Move for 1 turn
	if _unit_has_perk(attacker, "relentless_advance"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "mace":
			_apply_stat_modifier(attacker, "movement", 1, 1)

	# Exposed Target: ranged crits apply -15% Dodge debuff for 2 turns
	if _unit_has_perk(attacker, "exposed_target") and result.get("crit", false):
		if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
			var dodge_pen = int(defender.get_dodge() * 0.15)
			if dodge_pen > 0:
				_apply_stat_modifier(defender, "dodge", -dodge_pen, 2)

	# Knife Storm: 25% chance of a free bonus dagger attack on hit (max 1 per turn)
	if _unit_has_perk(attacker, "knife_storm"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "dagger":
			if not attacker.knife_storm_proc_this_turn and randf() < 0.25:
				attacker.knife_storm_proc_this_turn = true
				# Execute a bonus attack at 75% damage (simplified — apply damage directly)
				var bonus_dmg_result = calculate_physical_damage(attacker, defender, "piercing")
				var bonus_dmg = int(bonus_dmg_result.damage * 0.75)
				bonus_dmg = maxi(1, bonus_dmg)
				apply_damage(defender, bonus_dmg, "piercing")
				result["knife_storm_damage"] = bonus_dmg

	# Flowing Tide: spear kill grants +2 Move for 1 turn
	if _unit_has_perk(attacker, "flowing_tide"):
		if attacker.has_method("get_equipped_weapon") and attacker.get_equipped_weapon().get("type", "") == "spear":
			if not defender.is_alive():
				_apply_stat_modifier(attacker, "movement", 2, 1)

	# Put Your Weight Into It (Might 1): 15% chance to knockback 1 tile OR stun 1 turn on melee hit
	if _unit_has_perk(attacker, "put_your_weight_into_it"):
		var is_melee_hit = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee_hit and randf() < 0.15:
			if randf() < 0.5:
				_apply_status_effect(defender, "Knocked_Down", 1, 0, attacker)
			else:
				_apply_status_effect(defender, "Stunned", 1, 0, attacker)

	# Play Dirty (Guile 2): 20% chance to apply a random minor debuff on any hit
	if _unit_has_perk(attacker, "play_dirty") and randf() < 0.20:
		var dirty_debuffs = ["Weakened", "Slowed", "Blinded", "Dodge_Debuff", "Damage_Debuff"]
		_apply_status_effect(defender, dirty_debuffs[randi() % dirty_debuffs.size()], 1, 0, attacker)

	# Nothing Wasted (Might 4): overkill — when killing a target, deal 50% of the kill-blow damage to 1 adjacent enemy
	if _unit_has_perk(attacker, "nothing_wasted") and not defender.is_alive():
		var splash_targets = _get_enemies_in_range(attacker, 1)
		splash_targets.erase(defender)
		if not splash_targets.is_empty():
			var splash_target = splash_targets[randi() % splash_targets.size()]
			var splash_dmg = maxi(1, result.get("damage", 0) / 2)
			apply_damage(splash_target, splash_dmg, result.get("damage_type", "crushing"))
			result["nothing_wasted_damage"] = splash_dmg

	# Press the Advantage (Leadership 4): killing an enemy grants nearby allies +3 Initiative & +10% Attack (2 turns)
	if _unit_has_perk(attacker, "press_the_advantage") and not defender.is_alive():
		var press_allies = _get_allies_in_range(attacker, 3)
		press_allies.erase(attacker)
		for ally in press_allies:
			_apply_stat_modifier(ally, "initiative", 3, 2)
			var ally_dmg = int(ally.get_attack_damage() * 0.10) if ally.has_method("get_attack_damage") else 2
			if ally_dmg > 0:
				_apply_stat_modifier(ally, "damage", ally_dmg, 2)

	# Avatar of the Storm (Air 5): all allies gain +5% Air bonus damage and 10% stun chance on attacks
	# Applied as an aura: if any ally of the attacker has this perk, the bonus applies
	var _aots_active = _unit_has_perk(attacker, "avatar_of_the_storm")
	if not _aots_active:
		for ally in get_team_units(attacker.team if "team" in attacker else 0):
			if ally != attacker and _unit_has_perk(ally, "avatar_of_the_storm"):
				_aots_active = true
				break
	if _aots_active:
		var aots_air_dmg = maxi(1, int(result.get("damage", 0) * 0.05))
		var aots_resist = defender.get_resistance("air")
		var final_aots_dmg = maxi(1, int(aots_air_dmg * (1.0 - aots_resist / 100.0)))
		apply_damage(defender, final_aots_dmg, "air")
		result["aots_air_damage"] = final_aots_dmg
		if randf() < 0.10:
			_apply_status_effect(defender, "Stunned", 1, 0, attacker)

	# Static Edge (Air 1): attacks deal +10% weapon damage as bonus Air damage
	if _unit_has_perk(attacker, "static_edge"):
		var air_dmg = maxi(1, int(result.get("damage", 0) * 0.10))
		var air_resist = defender.get_resistance("air")
		var final_air_dmg = maxi(1, int(air_dmg * (1.0 - air_resist / 100.0)))
		apply_damage(defender, final_air_dmg, "air")
		result["static_edge_damage"] = final_air_dmg

	# Cheap Shot: record that this enemy has now been attacked (removes the crit bonus on future attacks)
	if "enemies_hit_this_combat" in attacker and not defender in attacker.enemies_hit_this_combat:
		attacker.enemies_hit_this_combat.append(defender)

	# --- Update consecutive hit streaks ---
	if attacker.has_method("get_equipped_weapon"):
		var w = attacker.get_equipped_weapon()
		var weapon_type = w.get("type", "")
		if weapon_type == "axe":
			attacker.momentum_stacks += 1
		else:
			attacker.momentum_stacks = 0
		if w.is_empty() or weapon_type in ["", "unarmed"]:
			attacker.unarmed_hit_stacks += 1
			# One Mind, One Fist (cross-skill): unarmed hits during active mantras advance each mantra by +1
			if not attacker.active_mantras.is_empty():
				var att_char_omomof = attacker.character_data if "character_data" in attacker else {}
				if PerkSystem.has_perk(att_char_omomof, "one_mind_one_fist"):
					for m_id in attacker.active_mantras:
						attacker.active_mantras[m_id] += 1  # Extra progress point
		else:
			attacker.unarmed_hit_stacks = 0

	# Every Opening Is an Invitation: +10% crit vs statused — applied via get_passive_perk_stat_bonus
	# Anatomy Knowledge: +10% damage vs biological enemies — applied in calculate_physical_damage
	# Shadow Strike: stealth attacks auto-hit + crit (implemented in attack_unit)
	# Blood in the Wind: +movement when enemies bleeding (checked in stat getter)

	# Pressure Points (Medicine 7): melee hits vs biological → 15% chance for random debuff
	var att_char_pp = attacker.character_data if "character_data" in attacker else {}
	if PerkSystem.has_perk(att_char_pp, "pressure_points"):
		var is_melee = _grid_distance(attacker.grid_position, defender.grid_position) <= 1
		if is_melee and _unit_is_biological(defender) and randf() < 0.15:
			# -10% Attack (Damage_Debuff), -10% Dodge (Dodge_Debuff), or -1 Movement (Slowed)
			var debuffs = ["Damage_Debuff", "Dodge_Debuff", "Slowed"]
			var chosen = debuffs[randi() % debuffs.size()]
			_apply_status_effect(defender, chosen, 2)

	# --- Talisman perk on-hit effects ---
	var talisman_perks = _get_talisman_perks(attacker)
	if not talisman_perks.is_empty():
		var base_damage = result.get("damage", 0)

		# Elemental brands: +X% of base damage as bonus elemental damage
		var brand_map = {
			"fire_brand_minor": ["fire", 0.05], "fire_brand": ["fire", 0.10], "fire_brand_greater": ["fire", 0.15],
			"water_brand_minor": ["water", 0.05], "water_brand": ["water", 0.10], "water_brand_greater": ["water", 0.15],
			"earth_brand_minor": ["earth", 0.05], "earth_brand": ["earth", 0.10], "earth_brand_greater": ["earth", 0.15],
			"air_brand_minor": ["air", 0.05], "air_brand": ["air", 0.10], "air_brand_greater": ["air", 0.15],
			"space_brand_minor": ["space", 0.05], "space_brand": ["space", 0.10], "space_brand_greater": ["space", 0.15],
			"phys_brand_minor": ["physical", 0.05], "phys_brand": ["physical", 0.10], "phys_brand_greater": ["physical", 0.15],
			"poison_brand_minor": ["poison", 0.05], "poison_brand": ["poison", 0.10], "poison_brand_greater": ["poison", 0.15],
		}

		for perk_id in talisman_perks:
			if perk_id in brand_map:
				var element = brand_map[perk_id][0]
				var pct = brand_map[perk_id][1]
				var bonus_dmg = ceili(base_damage * pct)
				if bonus_dmg > 0:
					# Apply resistance to bonus damage
					var resist = defender.get_resistance(element)
					bonus_dmg = maxi(1, int(bonus_dmg * (1.0 - resist / 100.0)))
					apply_damage(defender, bonus_dmg, element)
					result["brand_damage"] = result.get("brand_damage", 0) + bonus_dmg
					result["brand_element"] = element

				# Poison brands also have a chance to inflict Poisoned
				if element == "poison":
					var poison_chance = pct  # 5/10/15%
					if randf() < poison_chance:
						_apply_status_effect(defender, "Poisoned", 3)

		# Lifesteal: heal 15% of attack damage dealt (Blood Pact boosts all lifesteal by 25%)
		if "lifesteal" in talisman_perks:
			var steal_pct = 0.15
			if _unit_has_perk(attacker, "blood_pact"):
				steal_pct *= 1.25
			var steal = int(base_damage * steal_pct)
			if steal > 0:
				attacker.heal(steal)
				unit_healed.emit(attacker, steal)
				result["talisman_lifesteal"] = steal

	# --- Status-based weapon enchant on-hit effects ---
	# Handles any "adds_X_damage_to_attacks" effect (fire, air, etc.)
	_process_status_weapon_enchants(attacker, defender, result)


## Process passive perks that trigger when a unit dodges an attack.
## Called from attack_unit() when the attack misses.
func _process_on_dodge_perks(unit: Node, attacker: Node) -> void:
	# Riposte: When you dodge or parry, next sword attack costs -2 Stamina and +25% damage
	if _unit_has_perk(unit, "riposte"):
		if unit.has_method("get_equipped_weapon"):
			if unit.get_equipped_weapon().get("type", "") == "sword":
				# Apply a temporary riposte buff (stored as status effect for tracking)
				_apply_status_effect(unit, "Riposte_Ready", 1, 25)  # value = damage bonus %

	# Borrowed Force: +30% damage bonus on next attack after dodging a melee attack
	if _unit_has_perk(unit, "borrowed_force"):
		var is_melee = _grid_distance(unit.grid_position, attacker.grid_position) <= 1
		if is_melee:
			var bonus = int(unit.get_attack_damage() * 0.3) if unit.has_method("get_attack_damage") else 5
			_apply_stat_modifier(unit, "damage", bonus, 1)

	# Opportunist: when a melee attack misses you and you're holding a dagger, make a free counterattack
	if _unit_has_perk(unit, "opportunist"):
		var is_melee_miss = _grid_distance(unit.grid_position, attacker.grid_position) <= 1
		if is_melee_miss and unit.has_method("get_equipped_weapon"):
			if unit.get_equipped_weapon().get("type", "") == "dagger":
				# Free counter — apply 75% damage directly without consuming an action
				var counter_result = calculate_physical_damage(unit, attacker, "piercing")
				var counter_dmg = int(counter_result.damage * 0.75)
				counter_dmg = maxi(1, counter_dmg)
				apply_damage(attacker, counter_dmg, "piercing")
				unit_attacked.emit(unit, attacker, {"success": true, "hit": true, "damage": counter_dmg, "crit": false, "opportunist": true})


## Process passive perks at the start of a unit's turn.
## Called from _start_current_turn().
func _process_turn_start_perks(unit: Node) -> void:
	# Tick active-skill stat modifiers (set by buff_self, buff_ally, buff_allies, etc.)
	if "stat_modifiers" in unit and unit.stat_modifiers.size() > 0:
		var expired_mods: Array[int] = []
		for i in range(unit.stat_modifiers.size()):
			unit.stat_modifiers[i].duration -= 1
			if unit.stat_modifiers[i].duration <= 0:
				expired_mods.append(i)
		expired_mods.reverse()
		for idx in expired_mods:
			unit.stat_modifiers.remove_at(idx)

	# Tick aggro-aura duration (look_at_me perk)
	if "taunt_active" in unit and unit.taunt_active:
		unit.taunt_duration -= 1
		if unit.taunt_duration <= 0:
			unit.taunt_active = false

	# Reset per-turn flags
	if unit.moved_this_turn:
		unit.stationary_stacks = 0  # Tidal Patience: reset if moved last turn
	else:
		unit.stationary_stacks = mini(unit.stationary_stacks + 1, 3)  # max 3 stacks
	unit.moved_this_turn = false
	unit.momentum_stacks = 0
	unit.unarmed_hit_stacks = 0
	unit.dagger_attacks_this_turn = 0
	unit.ranged_attacks_this_turn = 0
	unit.knife_storm_proc_this_turn = false
	unit.call_the_shot_used_this_turn = false
	# Call the Shot: mark on defender expires at the start of their own turn
	if "is_marked" in unit and unit.is_marked:
		unit.is_marked = false
		combat_log.emit("%s shakes off the mark." % unit.unit_name)

	# Diamond Body: +25% status resist (handled via saving throw bonuses)
	# Field Commander: companions reposition — only applies round 1 (handled in deployment)

	# Deep Freeze (Water 3): if a unit's effective movement has been reduced to 0 by ice/water debuffs, freeze it
	# Check at turn start — if movement stat is 0 and unit has a water debuff, apply Frozen
	if not unit.has_status("Frozen"):
		var cur_move = unit.get_movement() if unit.has_method("get_movement") else 99
		if cur_move <= 0:
			# Check if any caster with deep_freeze caused the movement penalty
			for caster_u in get_team_units(1 - unit.team if "team" in unit else 1):
				var caster_char_df = caster_u.character_data if "character_data" in caster_u else {}
				if PerkSystem.has_perk(caster_char_df, "deep_freeze"):
					_apply_status_effect(unit, "Frozen", 1, 0, caster_u)
					break

	# Avatar of the Wind (Air 5): all allies gain +1 Move, +2 Initiative, +5% Dodge each round
	if _unit_has_perk(unit, "avatar_of_the_wind"):
		for ally in get_team_units(unit.team if "team" in unit else 0):
			if ally == unit: continue
			_apply_stat_modifier(ally, "movement", 1, 1)
			_apply_stat_modifier(ally, "initiative", 2, 1)
			_apply_stat_modifier(ally, "dodge", 5, 1)

	# Hungry Flames (Fire 2): Burning enemies have 25% chance/turn to spread to 1 adjacent enemy
	# Processed on the perk-holder's turn rather than each burning enemy's turn
	if _unit_has_perk(unit, "hungry_flames"):
		var enemies = get_team_units(1 - unit.team if "team" in unit else 1)
		for enemy in enemies:
			if enemy.has_status("Burning") and randf() < 0.25:
				var adj_enemies = _get_enemies_in_range(enemy, 1)
				adj_enemies.erase(enemy)  # don't spread to self
				for adj in adj_enemies:
					if not adj.has_status("Burning") and adj.is_alive():
						_apply_status_effect(adj, "Burning", 2, 0, unit)
						break

	# Blood in the Wind: +movement when enemies are bleeding
	if _unit_has_perk(unit, "blood_in_the_wind"):
		var any_bleeding = false
		for enemy in get_team_units(1 - unit.team if "team" in unit else 1):
			if enemy.has_status("Bleeding"):
				any_bleeding = true
				break
		if any_bleeding:
			_apply_stat_modifier(unit, "movement", 1, 1)

	# Soothing Presence aura (perk-granted, not status-granted)
	# Handled via status effect system — the status applies the aura

	# --- Talisman perk turn-start effects ---
	var talisman_perks = _get_talisman_perks(unit)

	# HP regeneration: regen_minor (+2%), regen_moderate (+4%), regen_greater (+7%)
	var regen_pct = 0.0
	if "regen_greater" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.07)
	if "regen_moderate" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.04)
	if "regen_minor" in talisman_perks:
		regen_pct = maxf(regen_pct, 0.02)
	# If unit has two trinkets with regen, use the better one (already maxf'd)
	# but also add the lesser one at half value for stacking
	if talisman_perks.count("regen_greater") + talisman_perks.count("regen_moderate") + talisman_perks.count("regen_minor") > 1:
		var second_pct = 0.0
		for tp in talisman_perks:
			var val = 0.0
			match tp:
				"regen_greater": val = 0.07
				"regen_moderate": val = 0.04
				"regen_minor": val = 0.02
			if val > 0.0 and val < regen_pct:
				second_pct = maxf(second_pct, val * 0.5)
		regen_pct += second_pct

	if regen_pct > 0.0 and unit.current_hp < unit.max_hp:
		var heal_amount = ceili(unit.max_hp * regen_pct)
		unit.heal(heal_amount)
		unit_healed.emit(unit, heal_amount)

	# Mana regeneration: mana_trickle (+2%), mana_stream (+4%), mana_cascade (+7%)
	var mana_pct = 0.0
	if "mana_cascade" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.07)
	if "mana_stream" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.04)
	if "mana_trickle" in talisman_perks:
		mana_pct = maxf(mana_pct, 0.02)
	if talisman_perks.count("mana_cascade") + talisman_perks.count("mana_stream") + talisman_perks.count("mana_trickle") > 1:
		var second_pct = 0.0
		for tp in talisman_perks:
			var val = 0.0
			match tp:
				"mana_cascade": val = 0.07
				"mana_stream": val = 0.04
				"mana_trickle": val = 0.02
			if val > 0.0 and val < mana_pct:
				second_pct = maxf(second_pct, val * 0.5)
		mana_pct += second_pct

	if mana_pct > 0.0 and unit.current_mana < unit.max_mana:
		var mana_amount = ceili(unit.max_mana * mana_pct)
		unit.restore_mana(mana_amount)

# ============================================
# ZONE OF CONTROL REACTIONS
# ============================================

## Check and fire ZoC reaction attacks after a unit moves.
## mover: the unit that just moved; old_pos/new_pos: previous and current grid positions.
func _check_zoc_reactions(mover: Node, old_pos: Vector2i, new_pos: Vector2i) -> void:
	# Skirmisher (Ranged 3 + Grace 3): free disengage — immune to ZoC reactions on all moves
	var mover_char = mover.character_data if "character_data" in mover else {}
	if PerkSystem.has_perk(mover_char, "skirmisher"):
		return

	# Scan all enemies of the mover (i.e., potential reactors on the other team)
	for reactor in all_units:
		if reactor.is_dead or reactor.team == mover.team:
			continue
		if not reactor.has_method("get_equipped_weapon"):
			continue

		var reactor_char = reactor.character_data if "character_data" in reactor else {}
		var weapon_type = reactor.get_equipped_weapon().get("type", "")
		var is_spear = weapon_type == "spear"
		var reactor_pos = reactor.grid_position
		var dist_old = _grid_distance(reactor_pos, old_pos)
		var dist_new = _grid_distance(reactor_pos, new_pos)
		var reach = 2 if is_spear else 1

		# Frost Warden: +1 reach while stationary
		if is_spear and PerkSystem.has_perk(reactor_char, "frost_warden") and not reactor.moved_this_turn:
			reach += 1

		# First to Strike (Spears 1): reaction attack when enemy enters 2-tile spear range
		if is_spear and PerkSystem.has_perk(reactor_char, "first_to_strike"):
			if dist_new <= reach and dist_old > reach:
				combat_log.emit("%s: First to Strike reaction!" % reactor.unit_name)
				attack_unit(reactor, mover, true)

		# Frost Warden: reaction Slow when enemy enters reach
		if is_spear and PerkSystem.has_perk(reactor_char, "frost_warden"):
			if dist_new <= reach and dist_old > reach:
				_apply_status_effect(mover, "Slowed", 2, 0, reactor)

		# None Shall Pass (Spears 9): reaction attack against ALL enemies entering reach
		if is_spear and PerkSystem.has_perk(reactor_char, "none_shall_pass"):
			if dist_new <= reach and dist_old > reach:
				combat_log.emit("%s: None Shall Pass reaction!" % reactor.unit_name)
				attack_unit(reactor, mover, true)

		# Sentinel (Swords/MA cross): reaction attack when enemy LEAVES melee range (1 tile)
		if PerkSystem.has_perk(reactor_char, "sentinel"):
			var sentinel_weapon = weapon_type in ["sword", ""] or weapon_type.is_empty()
			if sentinel_weapon and dist_old <= 1 and dist_new > 1:
				combat_log.emit("%s: Sentinel reaction!" % reactor.unit_name)
				attack_unit(reactor, mover, true)


# ============================================
# FREE ATTACK SYSTEM (cleave, relentless)
# ============================================

## Perform one free attack from attacker against target, with a recursion guard
## so free attacks can never chain into further free attacks.
func _trigger_free_attack(attacker: Node, target: Node) -> void:
	if attacker == null or attacker.is_dead or target == null or not target.is_alive():
		return
	if attacker.in_free_attack:
		return  # Prevent chaining
	attacker.in_free_attack = true
	combat_log.emit("%s makes a free attack on %s!" % [attacker.unit_name, target.unit_name])
	attack_unit(attacker, target, true)  # reaction=true: no action cost
	attacker.in_free_attack = false


## Check and trigger Cleave (Axes cross) after a kill.
## dead_pos: grid position where the killed unit was standing.
func _trigger_cleave(killer: Node, dead_pos: Vector2i) -> void:
	if killer == null or killer.is_dead or killer.in_free_attack:
		return
	var killer_char = killer.character_data if "character_data" in killer else {}
	if not PerkSystem.has_perk(killer_char, "cleave"):
		return
	# Must be wielding an axe
	if not killer.has_method("get_equipped_weapon"):
		return
	if killer.get_equipped_weapon().get("type", "") != "axe":
		return
	# Find the nearest enemy adjacent to the dead unit's tile
	var nearest: Node = null
	var best_dist = 9999
	for u in all_units:
		if u.is_dead or u.team == killer.team:
			continue
		var d = _grid_distance(dead_pos, u.grid_position)
		if d <= 1 and d < best_dist:
			best_dist = d
			nearest = u
	_trigger_free_attack(killer, nearest)


## Apply the aura effect for an empowered summon at the start of its turn.
## Adds ±10 to mantra_stat_bonuses["armor"], ["dodge"], ["crit_chance"] for
## all units within 2 tiles — positive for allies, negative for enemies.
## The negative values are clamped to 0 in the getter (floor applied there).
func _process_summon_aura(unit: Node) -> void:
	for u in all_units:
		if u.is_dead:
			continue
		var dist = _grid_distance(unit.grid_position, u.grid_position)
		if dist > 2:
			continue
		var bonus = 10 if u.team == unit.team else -10
		u.mantra_stat_bonuses["armor"] = u.mantra_stat_bonuses.get("armor", 0) + bonus
		u.mantra_stat_bonuses["dodge"] = u.mantra_stat_bonuses.get("dodge", 0) + bonus
		u.mantra_stat_bonuses["crit_chance"] = u.mantra_stat_bonuses.get("crit_chance", 0.0) + float(bonus)


## Return all live units whose summoner_id matches caster.get_instance_id()
func _get_owned_summons(caster: Node) -> Array:
	var caster_id = caster.get_instance_id()
	var result: Array = []
	for u in all_units:
		if not u.is_dead and "summoner_id" in u and u.summoner_id == caster_id:
			result.append(u)
	return result


# ============================================
# MANTRA SYSTEM
# ============================================

## Interrupt all active mantras on a unit (heavy hit, hard CC, or spell cast).
## Returns immediately if there are no active mantras (cheap guard).
func _interrupt_mantras(unit: Node, reason: String) -> void:
	if not ("active_mantras" in unit) or unit.active_mantras.is_empty():
		return
	unit.active_mantras = {}
	unit.mantra_stat_bonuses = {}
	_lord_of_death_casters.erase(unit)
	combat_log.emit(reason)


## Process all active mantras for a unit at the start of their turn.
## Rebuilds mantra_stat_bonuses and applies per-turn aura/damage/heal effects.
## Triggers Deity Yoga automatically when the mantra reaches 5 stacks.
func _process_mantra_effects_and_auras(unit: Node) -> void:
	# Lord of Death cleanup: if DY was triggered but mantra is no longer active, remove from list
	if not "mantra_of_the_lord_of_death" in unit.active_mantras:
		_lord_of_death_casters.erase(unit)

	var char_data = unit.character_data if "character_data" in unit else {}
	var spellpower = unit.get_spellpower()

	# Rebuild stat bonuses from scratch (so they don't accumulate unboundedly)
	unit.mantra_stat_bonuses = {}

	# Walking Meditation (cross-skill perk): +2 Move while any mantra is active
	if PerkSystem.has_perk(char_data, "walking_meditation"):
		unit.mantra_stat_bonuses["movement"] = unit.mantra_stat_bonuses.get("movement", 0) + 2

	for perk_id in unit.active_mantras:
		var stacks = mini(unit.active_mantras[perk_id], 5)
		if stacks == 0:
			continue  # Just started chanting this turn — no effect yet

		_apply_mantra_tick(unit, perk_id, stacks, spellpower, char_data)

		# Trigger Deity Yoga once when stacks reach 5
		if unit.active_mantras[perk_id] >= 5 and not unit.deity_yoga_triggered.get(perk_id, false):
			unit.deity_yoga_triggered[perk_id] = true
			_trigger_deity_yoga(unit, perk_id, spellpower)

	# Process summon aura if this unit has one
	if "has_summon_aura" in unit and unit.has_summon_aura:
		_process_summon_aura(unit)


## Apply the per-turn aura effect for a specific mantra at the given stack level.
## stacks: 1-5; spellpower: caster's current spellpower.
func _apply_mantra_tick(unit: Node, perk_id: String, stacks: int, spellpower: int, char_data: Dictionary) -> void:
	var allies = _get_allies_in_range(unit, 3)  # Most mantras have 3-tile radius
	var allies_with_self: Array = [unit] + allies
	var enemies_3 = _get_enemies_in_range(unit, 3)
	var enemies_4 = _get_enemies_in_range(unit, 4)
	var all_enemies = _get_enemies_in_range(unit, 99)  # line-of-sight mantras use all visible enemies

	match perk_id:

		# ---- SPACE MAGIC ----
		"lady_of_the_turquoise_mirror_mantra":
			# Caster gains stacking +5% Dodge and +5% magic resist per stack
			unit.mantra_stat_bonuses["dodge"] = unit.mantra_stat_bonuses.get("dodge", 0) + stacks * 5

		"diamond_nail_mantra":
			# Enemies in 3 tiles suffer -1 Move per stack (up to -5)
			for e in enemies_3:
				_apply_status_effect(e, "Slowed", 2, 0, unit)  # 1 Slowed per turn; stacks via the status system

		# ---- WHITE MAGIC ----
		"lotus_refuge_mantra":
			# Allies in 3 tiles regen 3% max HP × stacks each turn
			var heal_pct = stacks * 3
			for a in allies_with_self:
				var heal_amt = ceili(a.max_hp * heal_pct / 100.0)
				a.heal(heal_amt)
				unit_healed.emit(a, heal_amt)

		"golden_wheel_mantra":
			# Enemies in LOS suffer -5% Accuracy per stack (applied as Weakened each turn)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 2, 0, unit)

		"immovable_light_mantra":
			# Caster gains +5% Armor and immunity to forced movement per stack
			unit.mantra_stat_bonuses["armor"] = unit.mantra_stat_bonuses.get("armor", 0) + stacks * 5

		# ---- BLACK MAGIC ----
		"mantra_of_the_great_black_one":
			# Enemies in 3 tiles: -5% Armor per stack + drain 3% Stamina/Mana per stack
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)  # simulates armor/resist reduction
				var drain = ceili(e.max_stamina * 0.03 * stacks)
				e.current_stamina = maxi(0, e.current_stamina - drain)
				var mana_drain = ceili(e.max_mana * 0.03 * stacks)
				e.current_mana = maxi(0, e.current_mana - mana_drain)

		"mantra_of_the_blood_drinkers":
			# Enemies in LOS take Black damage 5% Spellpower × stacks; heal caster + nearby allies
			var dmg_per_enemy = ceili(spellpower * 0.05 * stacks)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, dmg_per_enemy, "black")
					# Lifesteal: heal caster and allies within 2 tiles
					var healers = [unit] + _get_allies_in_range(unit, 2)
					for h in healers:
						var h_amt = ceili(dmg_per_enemy * 0.5)
						h.heal(h_amt)
						unit_healed.emit(h, h_amt)

		"mantra_of_the_lord_of_death":
			# 1. Heal black-tagged owned summons within 4 tiles (10% of their max HP)
			for s in _get_owned_summons(unit):
				if "character_data" in s and "tags" in s.character_data and "black" in s.character_data["tags"]:
					if _grid_distance(unit.grid_position, s.grid_position) <= 4:
						var heal_amt = ceili(s.max_hp * 0.10)
						s.heal(heal_amt)
						unit_healed.emit(s, heal_amt)
			# 2. Stacking black damage to enemies in 4 tiles (3% spellpower × stacks)
			var lod_dmg = ceili(spellpower * 0.03 * stacks)
			for e in enemies_4:
				apply_damage(e, lod_dmg, "black")

		# ---- YOGA ----
		"mantra_of_the_white_saviouress":
			# Caster + allies in 3 tiles regain 2%+stacks% max HP, Mana, Stamina
			var pct = (1 + stacks) / 100.0
			for a in allies_with_self:
				var hp_amt = ceili(a.max_hp * pct)
				a.heal(hp_amt)
				unit_healed.emit(a, hp_amt)
				a.current_mana = mini(a.max_mana, a.current_mana + ceili(a.max_mana * pct))
				a.current_stamina = mini(a.max_stamina, a.current_stamina + ceili(a.max_stamina * pct))

		"mantra_of_the_lotus_pinnacle":
			# Allies in 3 tiles gain +3% all resist per stack (applied as armor bonus proxy)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 3

		# ---- AIR MAGIC ----
		"mantra_of_the_green_saviouress":
			# Allies in 3 tiles gain +1 to all d20 rolls per stack → +5% accuracy per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + stacks * 5

		"mantra_of_the_roaring_one":
			# Allies in 3 tiles gain +1 Move, +3% crit per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + stacks
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + stacks * 3.0

		# ---- RITUAL ----
		"mantra_of_interdependent_arising":
			# Caster + allies in 3 tiles regain 2% Mana per stack
			var mana_pct = stacks * 2 / 100.0
			for a in allies_with_self:
				var mana_amt = ceili(a.max_mana * mana_pct)
				a.current_mana = mini(a.max_mana, a.current_mana + mana_amt)

		"mantra_of_multiplying":
			# Caster gains +5% Spellpower per stack (up to +25%)
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * (spellpower / 20)

		# ---- FIRE MAGIC ----
		"mantra_of_the_lotus_blaze":
			# Enemies in LOS: CON save (DC 10 + 2×stacks) or gain Burning
			var dc = 10 + stacks * 2
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					var con = e.character_data.get("attributes", {}).get("constitution", 10) if "character_data" in e else 10
					var roll = randi() % 20 + 1 + con - 10
					if roll < dc:
						_apply_status_effect(e, "Burning", 2, 0, unit)

		"mantra_of_the_red_lotus_lady":
			# Enemies in 3 tiles: Focus save (DC 10 + 2×stacks) or get Charmed 2t
			var dc_r = 10 + stacks * 2
			for e in enemies_3:
				var foc = e.character_data.get("attributes", {}).get("focus", 10) if "character_data" in e else 10
				var roll = randi() % 20 + 1 + foc - 10
				if roll < dc_r:
					_apply_status_effect(e, "Charmed", 2, 0, unit)

		"mantra_of_the_horse_lord":
			# Allies in 3 tiles gain +2 Initiative, +1 Move per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + stacks * 2
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + stacks

		# ---- SORCERY ----
		"mantra_of_the_lionheaded_curse_devourer":
			# Allies in 3 tiles gain +5% magic resist per stack → armor proxy
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5

		# ---- WATER MAGIC ----
		"mantra_of_the_medicine_buddha":
			# Ally with lowest HP% in 3 tiles heals 5% Spellpower per stack
			var heal_amt = ceili(spellpower * 0.05 * stacks)
			var lowest: Node = null
			var lowest_pct = 1.0
			for a in allies_with_self:
				var pct_hp = float(a.current_hp) / float(a.max_hp)
				if pct_hp < lowest_pct:
					lowest_pct = pct_hp
					lowest = a
			if lowest != null:
				lowest.heal(heal_amt)
				unit_healed.emit(lowest, heal_amt)

		"mantra_of_the_unshakeable_one":
			# Enemies in 3 tiles take Cold damage 3% Spellpower × stacks; allies +3% resist per stack
			var cold_dmg = ceili(spellpower * 0.03 * stacks)
			for e in enemies_3:
				apply_damage(e, cold_dmg, "cold")
				_apply_status_effect(e, "Slowed", 2, 0, unit)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 3

		# ---- ENCHANTMENT ----
		"mantra_of_the_wishfulfilling_jewel":
			# Allies in 3 tiles get a random +5% buff to one stat each turn
			var buff_options = ["dodge", "armor", "initiative", "crit_chance", "spellpower"]
			for a in allies_with_self:
				var chosen = buff_options[randi() % buff_options.size()]
				a.mantra_stat_bonuses[chosen] = a.mantra_stat_bonuses.get(chosen, 0) + 5

		"mantra_of_the_binding_word":
			# Enemies in LOS get a random -5% debuff each turn
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 2, 0, unit)

		# ---- EARTH MAGIC ----
		"mantra_of_the_earth_store_bodhisattva":
			# Allies in 3 tiles +5% Armor per stack; enemies in 3 tiles -5% Attack per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)

		"mantra_of_the_jeweled_mountain":
			# Enemies -5% Attack per stack; allies +5% Armor per stack
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5
			for e in enemies_3:
				_apply_status_effect(e, "Weakened", 2, 0, unit)

		# ---- SUMMONING ----
		"mantra_of_the_four_guardian_kings":
			# 1. Maintain up to 4 spirit guardians around the caster
			var owned = _get_owned_summons(unit)
			var guardian_count = 0
			for s in owned:
				if "character_data" in s and "tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]:
					guardian_count += 1
			if guardian_count < 4:
				# Find first free tile within 2 of caster
				var found_tile = Vector2i(-1, -1)
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						if found_tile != Vector2i(-1, -1):
							break
						var candidate = unit.grid_position + Vector2i(dx, dy)
						if candidate == unit.grid_position:
							continue
						if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
							found_tile = candidate
					if found_tile != Vector2i(-1, -1):
						break
				if found_tile != Vector2i(-1, -1):
					_spawn_summoned_unit(unit, "spirit_guardian", found_tile, 0)
					# Refresh owned list after spawn
					owned = _get_owned_summons(unit)

			# 2. Each spirit guardian gives +3 armor to the nearest ally within 3 tiles
			for s in owned:
				if not ("character_data" in s and "tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]):
					continue
				var nearest_ally: Node = null
				var nearest_ally_dist = 999
				for a in allies_with_self:
					var d = _grid_distance(s.grid_position, a.grid_position)
					if d <= 3 and d < nearest_ally_dist:
						nearest_ally_dist = d
						nearest_ally = a
				if nearest_ally != null:
					nearest_ally.mantra_stat_bonuses["armor"] = nearest_ally.mantra_stat_bonuses.get("armor", 0) + 3

		"mantra_of_the_jeweled_pagoda":
			# 1. Caster gains +5 * stacks flat spellpower bonus
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * 5
			# 2. Each owned summon gains stacks*3 to damage, armor, dodge
			for s in _get_owned_summons(unit):
				s.mantra_stat_bonuses["damage"] = s.mantra_stat_bonuses.get("damage", 0) + stacks * 3
				s.mantra_stat_bonuses["armor"] = s.mantra_stat_bonuses.get("armor", 0) + stacks * 3
				s.mantra_stat_bonuses["dodge"] = s.mantra_stat_bonuses.get("dodge", 0) + stacks * 3


## Trigger the Deity Yoga burst for a mantra at stack 5.
## Called once per mantra activation when active_mantras[perk_id] first reaches 5.
func _trigger_deity_yoga(unit: Node, perk_id: String, spellpower: int) -> void:
	var allies = _get_allies_in_range(unit, 3)
	var allies_with_self: Array = [unit] + allies
	var enemies_3 = _get_enemies_in_range(unit, 3)
	var enemies_4 = _get_enemies_in_range(unit, 4)
	var all_enemies = _get_enemies_in_range(unit, 99)
	var mantra_name = perk_id.replace("_", " ").capitalize()
	combat_log.emit("DEITY YOGA — %s!" % mantra_name)

	match perk_id:

		# SPACE
		"lady_of_the_turquoise_mirror_mantra":
			# All attacks targeting caster have 60% reflect chance for 3 turns
			_apply_status_effect(unit, "Reflect", 3, 0, unit)
			# Share dodge bonus with allies in 3 tiles
			for a in allies:
				a.mantra_stat_bonuses["dodge"] = a.mantra_stat_bonuses.get("dodge", 0) + 25

		"diamond_nail_mantra":
			# Enemies in 4 tiles take Space damage 50% Spellpower/turn — apply big Slow + damage burst
			var dmg = ceili(spellpower * 0.50)
			for e in enemies_4:
				apply_damage(e, dmg, "space")
				_apply_status_effect(e, "Rooted", 2, 0, unit)

		# WHITE
		"lotus_refuge_mantra":
			# All allies heal 20% max HP; all healing maximized for 2 turns
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.20)
				a.heal(heal)
				unit_healed.emit(a, heal)
				_apply_status_effect(a, "Fortified", 2, 0, unit)

		"golden_wheel_mantra":
			# Enemies who attack take 30% of dealt damage as White; allies +20% attack for 3 turns
			for a in allies_with_self:
				_apply_status_effect(a, "Inspired", 3, 0, unit)
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		"immovable_light_mantra":
			# Caster cannot drop below 1 HP; allies within 3 tiles +30% all resist for 3 turns
			_apply_status_effect(unit, "Invincible", 3, 0, unit)
			for a in allies:
				_apply_status_effect(a, "Fortified", 3, 0, unit)

		# BLACK
		"mantra_of_the_great_black_one":
			# All enemies in LOS: -20% Attack, -20% Armor, -5 Init, drain 8% Stamina/Mana
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 3, 0, unit)
					_apply_status_effect(e, "Slowed", 3, 0, unit)
					e.current_stamina = maxi(0, e.current_stamina - ceili(e.max_stamina * 0.08))
					e.current_mana = maxi(0, e.current_mana - ceili(e.max_mana * 0.08))

		"mantra_of_the_blood_drinkers":
			# Massive drain: 25% Spellpower Black to all LOS enemies; heal allies 50% dealt
			var dmg = ceili(spellpower * 0.25)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, dmg, "black")
					for a in allies_with_self:
						var h = ceili(dmg * 0.5)
						a.heal(h)
						unit_healed.emit(a, h)

		"mantra_of_the_lord_of_death":
			# Existing burst: black damage + Fear to all enemies in 4 tiles
			var lod_dy_dmg = ceili(spellpower * 0.20)
			for e in enemies_4:
				apply_damage(e, lod_dy_dmg, "black")
				_apply_status_effect(e, "Feared", 3, 0, unit)
			# 1. Bonus turns for all owned summons + empower them
			var owned_summons = _get_owned_summons(unit)
			for s in owned_summons:
				s.lord_of_death_empowered = true
				combat_log.emit("%s acts under the Lord of Death's command!" % s.unit_name)
				if get_tree() != null:
					var arena = get_tree().get_first_node_in_group("combat_arena")
					if arena != null and arena.has_method("_run_bonus_turn"):
						arena._run_bonus_turn(s)
			# 2. Register this caster for resurrection-on-kill tracking
			if not unit in _lord_of_death_casters:
				_lord_of_death_casters.append(unit)

		# YOGA
		"mantra_of_the_white_saviouress":
			# All allies: immunity to mental effects + 50% debuff resist for 3 turns
			for a in allies_with_self:
				_apply_status_effect(a, "Resolute", 3, 0, unit)

		"mantra_of_the_lotus_pinnacle":
			# All enemies in LOS: Focus save vs Pacified; else -50% Attack/Damage
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					var foc = e.character_data.get("attributes", {}).get("focus", 10) if "character_data" in e else 10
					var roll = randi() % 20 + 1 + foc - 10
					if roll < 15:
						_apply_status_effect(e, "Pacified", 2, 0, unit)
					else:
						_apply_status_effect(e, "Weakened", 2, 0, unit)

		# AIR
		"mantra_of_the_green_saviouress":
			# Caster's rolls gain +10 and can't critically fail; allies +5 accuracy for 3 turns
			unit.mantra_stat_bonuses["accuracy"] = unit.mantra_stat_bonuses.get("accuracy", 0) + 20
			for a in allies:
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 10

		"mantra_of_the_roaring_one":
			# Stat burst for all allies (+5 movement, +15% crit)
			for a in allies_with_self:
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 15.0
			# Spawn 1–3 Rudras near the caster (try adjacent tiles in order)
			var rudra_count = 1 + randi() % 3
			var spawned = 0
			var offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0),
						   Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]
			for offset in offsets:
				if spawned >= rudra_count:
					break
				var candidate = unit.grid_position + offset
				if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
					_spawn_summoned_unit(unit, "rudra", candidate, spellpower)
					spawned += 1

		# RITUAL
		"mantra_of_interdependent_arising":
			# All allies: 50% mana refund on next spell + +50% Spellpower for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["spellpower"] = a.mantra_stat_bonuses.get("spellpower", 0) + spellpower / 2

		"mantra_of_multiplying":
			# +50% Spellpower burst for caster
			unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + spellpower / 2

		# FIRE
		"mantra_of_the_lotus_blaze":
			# All burning enemies explode: 10% max HP × Burning stacks AoE fire damage
			for e in all_enemies:
				if e.has_status("Burning"):
					var burst_stacks = 0
					for se in e.status_effects:
						if se.get("status", "") == "Burning":
							burst_stacks += 1
					var burst_dmg = ceili(e.max_hp * 0.10 * burst_stacks)
					apply_damage(e, burst_dmg, "fire")
					# AoE splash to adjacent enemies
					for nearby in _get_enemies_in_range(e, 1):
						apply_damage(nearby, ceili(burst_dmg * 0.5), "fire")

		"mantra_of_the_red_lotus_lady":
			# All enemies must Focus save vs Charmed; crit fails → Dominated (here: Confused)
			for e in all_enemies:
				var foc_r = e.character_data.get("attributes", {}).get("focus", 10) if "character_data" in e else 10
				var roll_r = randi() % 20 + 1 + foc_r - 10
				if roll_r < 8:
					_apply_status_effect(e, "Confused", 3, 0, unit)  # Dominated approximation
				elif roll_r < 15:
					_apply_status_effect(e, "Charmed", 3, 0, unit)

		"mantra_of_the_horse_lord":
			# All allies: full Move/Init burst + +20% Atk/Dmg + Burning on melee for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + 10
				a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 20
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		# SORCERY
		"mantra_of_the_lionheaded_curse_devourer":
			# Transfer all debuffs from allies to enemies; big Spellpower/resist burst
			for a in allies_with_self:
				# Cleanse one debuff per ally
				for i in range(a.status_effects.size() - 1, -1, -1):
					var sname = a.status_effects[i].get("status", "")
					var sdef = get_status_definition(sname)
					if sdef.get("type", "") == "debuff":
						a.status_effects.remove_at(i)
						status_effect_expired.emit(a, sname)
						break
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 20
			for e in all_enemies:
				_apply_status_effect(e, "Weakened", 3, 0, unit)

		# WATER
		"mantra_of_the_medicine_buddha":
			# All allies heal 50% max HP and are cleansed of all debuffs
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.50)
				a.heal(heal)
				unit_healed.emit(a, heal)
				# Cleanse all debuffs
				for i in range(a.status_effects.size() - 1, -1, -1):
					var sname = a.status_effects[i].get("status", "")
					var sdef = get_status_definition(sname)
					if sdef.get("type", "") == "debuff":
						a.status_effects.remove_at(i)
						status_effect_expired.emit(a, sname)

		"mantra_of_the_unshakeable_one":
			# All enemies in LOS: Frozen; big cold damage burst; allies +30% resist
			var cold_burst = ceili(spellpower * 0.30)
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					apply_damage(e, cold_burst, "cold")
					_apply_status_effect(e, "Frozen", 2, 0, unit)
			for a in allies_with_self:
				_apply_status_effect(a, "Fortified", 3, 0, unit)

		# ENCHANTMENT
		"mantra_of_the_wishfulfilling_jewel":
			# All allies +25% to all stats for 3 turns
			for a in allies_with_self:
				a.mantra_stat_bonuses["dodge"] = a.mantra_stat_bonuses.get("dodge", 0) + 25
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
				a.mantra_stat_bonuses["initiative"] = a.mantra_stat_bonuses.get("initiative", 0) + 10
				a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 10.0
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25

		"mantra_of_the_binding_word":
			# All enemies in LOS: heavy multi-debuff
			for e in all_enemies:
				if combat_grid and combat_grid.has_line_of_sight(unit.grid_position, e.grid_position):
					_apply_status_effect(e, "Weakened", 3, 0, unit)
					_apply_status_effect(e, "Slowed", 3, 0, unit)
					_apply_status_effect(e, "Dazed", 3, 0, unit)

		# EARTH
		"mantra_of_the_earth_store_bodhisattva":
			# Heal all allies 20% HP; big armor burst
			for a in allies_with_self:
				var heal = ceili(a.max_hp * 0.20)
				a.heal(heal)
				unit_healed.emit(a, heal)
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25

		"mantra_of_the_jeweled_mountain":
			# Earth damage burst (25% Spellpower) to all enemies in 4 tiles; allies +30% armor
			var dmg = ceili(spellpower * 0.25)
			for e in enemies_4:
				apply_damage(e, dmg, "earth")
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 30

		# SUMMONING
		"mantra_of_the_four_guardian_kings":
			# Stat burst for all allies (+25 armor, +25 accuracy)
			for a in allies_with_self:
				a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
				a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25
			# Spawn a Guardian King in each of 4 cardinal directions (search outward up to radius 3)
			var cardinal_offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]
			for base_offset in cardinal_offsets:
				var spawn_tile = Vector2i(-1, -1)
				# Try exact cardinal tile, then 1 further, then 2 further (along the same axis)
				for r in range(0, 3):
					if spawn_tile != Vector2i(-1, -1):
						break
					var candidate = unit.grid_position + base_offset * (1 + r)
					if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
						spawn_tile = candidate
				if spawn_tile != Vector2i(-1, -1):
					_spawn_summoned_unit(unit, "stone_guardian", spawn_tile, 0)

		"mantra_of_the_jeweled_pagoda":
			# Set the empowered flag — consumed by _spawn_summoned_unit() on next summon cast
			unit.next_summon_empowered = true
			combat_log.emit("%s's next summon will be empowered!" % unit.unit_name)
