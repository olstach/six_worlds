extends Node
## GameState - Manages overall run state, world progression, and game flow
##
## This singleton tracks:
## - Current run state (alive/dead, current world, etc.)
## - Which worlds are unlocked
## - Party gold/currency and supplies (Food, Herbs, Scrap)
## - Save/load functionality
## - Scene transitions

# Signals
signal gold_changed(new_amount: int, change: int)
signal supply_changed(supply_type: String, new_amount: int, change: int)
signal starvation_started()   # Emitted when food runs out and grace period expires
signal starvation_ended()     # Emitted when food is obtained while starving

# Current run data
var current_world: String = "hell"  # Which world the player is currently in
var unlocked_worlds: Array[String] = ["hell"]  # Worlds player can travel to
var is_alive: bool = true
var current_run_number: int = 1  # How many times player has reincarnated

# Party resources
var gold: int = 100  # Starting gold

# Supplies — see resources/data/supplies.json for system config
var food: int = 50    # Consumed per party member per overworld step; Logistics reduces cost
var herbs: int = 20   # Consumed by Medicine passive to boost healing rate
var scrap: int = 15   # Consumed by Smithing passive to repair gear and restore ammo

# Starvation tracking — when food hits 0, a grace period starts before HP drain
var steps_without_food: int = 0  # Counts up while food == 0
var is_starving: bool = false    # True once grace period expires and HP is draining

# Scene transition state (for passing data across scene changes)
var pending_combat_mob: Dictionary = {}  # Mob data passed to combat arena
var last_defeated_mob_id: String = ""    # Mob to remove from map after combat victory
var returning_from_combat: bool = false  # Set true when returning to overworld from any combat
var is_party_wiped: bool = false         # True when all party members died (triggers Bardo)

# Event→combat transition state (persists across scene change to combat_arena)
var pending_event_outcome: Dictionary = {}  # Event outcome to display after combat
var pending_event_object: Dictionary = {}   # Event object for post-combat cleanup

# Overworld terrain context for generating combat battle maps
# Set by overworld.gd before scene change, consumed by combat_arena.gd
var combat_terrain_context: Dictionary = {}  # {dominant, counts, region}

# Active map buffs from simples and shrines.
# Each entry: {"stat": String, "amount": int/float, "combats_remaining": int}
# combats_remaining == -1 means permanent (rare).
var active_map_buffs: Array = []

# World definitions
var WORLDS: Dictionary = {
	"hell": {
		"name": "Hell Realm",
		"description": "A realm of suffering split between freezing cold and scorching heat",
		"boss_defeated": false,
		"next_world": "hungry_ghost"
	},
	"hungry_ghost": {
		"name": "Hungry Ghost Realm", 
		"description": "A realm of endless craving and dissatisfaction",
		"boss_defeated": false,
		"next_world": "animal"
	},
	"animal": {
		"name": "Animal Realm",
		"description": "A realm of instinct and survival",
		"boss_defeated": false,
		"next_world": "human"
	},
	"human": {
		"name": "Human Realm",
		"description": "A realm of potential and choice",
		"boss_defeated": false,
		"next_world": "asura"
	},
	"asura": {
		"name": "Asura Realm",
		"description": "A realm of conflict and jealousy",
		"boss_defeated": false,
		"next_world": "god"
	},
	"god": {
		"name": "God Realm",
		"description": "A realm of bliss and complacency",
		"boss_defeated": false,
		"next_world": null  # Final realm
	}
}

func _ready() -> void:
	print("GameState initialized")

## Defeat a world's boss and unlock the next world
func defeat_boss(world_name: String) -> void:
	if world_name in WORLDS:
		WORLDS[world_name].boss_defeated = true
		var next_world = WORLDS[world_name].next_world
		if next_world and next_world not in unlocked_worlds:
			unlocked_worlds.append(next_world)

## Travel to a different world (if unlocked)
func travel_to_world(world_name: String) -> bool:
	if world_name in unlocked_worlds:
		current_world = world_name
		return true
	else:
		return false

## Player death - triggers reincarnation
func player_died() -> void:
	is_alive = false
	current_run_number += 1
	# KarmaSystem will handle reincarnation logic

## Start new run after reincarnation
func start_new_run(spawn_world: String) -> void:
	is_alive = true
	current_world = spawn_world

## Get info about current world
func get_current_world_info() -> Dictionary:
	return WORLDS[current_world]

## Check if player has reached the final realm
func has_reached_final_realm() -> bool:
	return current_world == "god" and WORLDS["god"].boss_defeated


# ============================================
# GOLD / CURRENCY MANAGEMENT
# ============================================

## Get current gold amount
func get_gold() -> int:
	return gold


## Add gold to party
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold, amount)


## Decrement combat-duration map buffs after a combat resolves.
## Buffs with combats_remaining == 1 are removed; -1 is permanent and never decrements.
func decrement_combat_buffs() -> void:
	var remaining: Array = []
	for buf in active_map_buffs:
		var count: int = buf.get("combats_remaining", -1)
		if count == -1:
			remaining.append(buf)       # permanent
		elif count > 1:
			var updated: Dictionary = buf.duplicate()
			updated["combats_remaining"] = count - 1
			remaining.append(updated)
		# count == 1: expired, drop it
	active_map_buffs = remaining


## Spend gold (returns true if successful)
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold, -amount)
	return true


## Check if party can afford an amount
func can_afford(amount: int) -> bool:
	return gold >= amount


## Set gold directly (for save/load)
func set_gold(amount: int) -> void:
	var old_gold = gold
	gold = max(0, amount)
	gold_changed.emit(gold, gold - old_gold)


# ============================================
# SUPPLY MANAGEMENT (Food, Herbs, Scrap)
# ============================================

## Get current amount of a supply type
func get_supply(supply_type: String) -> int:
	match supply_type:
		"food": return food
		"herbs": return herbs
		"scrap": return scrap
		_:
			push_warning("Unknown supply type: " + supply_type)
			return 0


## Add supplies (from loot, shops, events)
func add_supply(supply_type: String, amount: int) -> void:
	if amount <= 0:
		return
	match supply_type:
		"food":
			food += amount
			# If we were starving and just got food, reset starvation
			if is_starving:
				is_starving = false
				steps_without_food = 0
				starvation_ended.emit()
		"herbs":
			herbs += amount
		"scrap":
			scrap += amount
		_:
			push_warning("Unknown supply type: " + supply_type)
			return
	supply_changed.emit(supply_type, get_supply(supply_type), amount)


## Consume supplies (returns true if enough were available)
func consume_supply(supply_type: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var current := get_supply(supply_type)
	if current < amount:
		return false
	match supply_type:
		"food": food -= amount
		"herbs": herbs -= amount
		"scrap": scrap -= amount
	supply_changed.emit(supply_type, get_supply(supply_type), -amount)
	return true


## Called each overworld step — handles food consumption and starvation tracking.
## party_size: number of members in party
## logistics_level: best Logistics skill in party (reduces food cost)
## lowest_con: lowest Constitution in party (determines starvation grace period)
## Returns a dictionary describing what happened this step:
##   {food_consumed, is_starving, starvation_damage_pct, healing_active}
func process_food_step(party_size: int, logistics_level: int, lowest_con: int) -> Dictionary:
	# Calculate food cost: 1 per member, reduced by Logistics (3% per level)
	var reduction_pct: float = logistics_level * 3.0  # from supplies.json
	var raw_cost: float = party_size * 1.0
	var reduced_cost: float = raw_cost * (1.0 - reduction_pct / 100.0)
	var actual_cost: int = max(1, ceili(reduced_cost))  # Always costs at least 1

	var result := {
		"food_consumed": 0,
		"is_starving": false,
		"starvation_damage_pct": 0.0,
		"healing_active": true
	}

	if food >= actual_cost:
		food -= actual_cost
		result.food_consumed = actual_cost
		steps_without_food = 0
		if is_starving:
			is_starving = false
			starvation_ended.emit()
		supply_changed.emit("food", food, -actual_cost)
	else:
		# Eat whatever's left, then go hungry
		var eaten := food
		food = 0
		if eaten > 0:
			supply_changed.emit("food", 0, -eaten)
		result.food_consumed = eaten
		result.healing_active = false  # No food = no passive healing

		# Track starvation
		steps_without_food += 1
		# Grace period: base 10 + 2 per lowest CON in party
		var grace: int = 10 + (lowest_con * 2)
		if steps_without_food > grace:
			is_starving = true
			result.is_starving = true
			result.starvation_damage_pct = 2.0  # 2% max HP per step
			if steps_without_food == grace + 1:
				starvation_started.emit()

	return result


## Process herb consumption for Medicine passive healing.
## medicine_level: best Medicine skill in party
## Returns bonus heal percentage (0.0 if no herbs or no Medicine skill)
func process_herbs_step(medicine_level: int) -> float:
	if medicine_level <= 0 or herbs <= 0:
		return 0.0
	# Consume 1 herb per step when Medicine is active
	herbs -= 1
	supply_changed.emit("herbs", herbs, -1)
	# Bonus healing: 0.5% per Medicine level (on top of base 1% from food)
	return medicine_level * 0.5


## Process scrap consumption for Smithing passive repair/ammo restore.
## smithing_level: best Smithing skill in party
## Returns dictionary with repair and ammo restore rates (0 if no scrap or no Smithing)
func process_scrap_step(smithing_level: int) -> Dictionary:
	if smithing_level <= 0 or scrap <= 0:
		return {"repair_pct": 0.0, "ammo_restore": 0}
	# Consume 1 scrap per step when Smithing is active
	scrap -= 1
	supply_changed.emit("scrap", scrap, -1)
	# Repair: 1% durability per Smithing level
	var repair_pct: float = smithing_level * 1.0
	# Ammo restore: 1 base + 1 per 3 Smithing levels
	var ammo_restore: int = 1 + (smithing_level / 3)
	return {"repair_pct": repair_pct, "ammo_restore": ammo_restore}


# ============================================
# SAVE / LOAD
# ============================================

## Collect saveable state into a dictionary
func get_save_data() -> Dictionary:
	var boss_states: Dictionary = {}
	for world_key in WORLDS:
		boss_states[world_key] = WORLDS[world_key].boss_defeated

	return {
		"current_world": current_world,
		"unlocked_worlds": unlocked_worlds.duplicate(),
		"is_alive": is_alive,
		"current_run_number": current_run_number,
		"gold": gold,
		"food": food,
		"herbs": herbs,
		"scrap": scrap,
		"steps_without_food": steps_without_food,
		"is_starving": is_starving,
		"boss_defeated": boss_states
	}


## Restore state from a save dictionary
func load_save_data(data: Dictionary) -> void:
	current_world = data.get("current_world", "hell")
	is_alive = data.get("is_alive", true)
	current_run_number = data.get("current_run_number", 1)
	gold = data.get("gold", 100)
	food = data.get("food", 50)
	herbs = data.get("herbs", 20)
	scrap = data.get("scrap", 15)
	steps_without_food = data.get("steps_without_food", 0)
	is_starving = data.get("is_starving", false)

	# Restore unlocked worlds
	unlocked_worlds.clear()
	for w in data.get("unlocked_worlds", ["hell"]):
		unlocked_worlds.append(w)

	# Restore boss states
	var boss_states = data.get("boss_defeated", {})
	for world_key in WORLDS:
		WORLDS[world_key].boss_defeated = boss_states.get(world_key, false)

	# Clear transient scene-transition state
	pending_combat_mob = {}
	last_defeated_mob_id = ""
	returning_from_combat = false
	is_party_wiped = false
	pending_event_outcome = {}
	pending_event_object = {}
	combat_terrain_context = {}
