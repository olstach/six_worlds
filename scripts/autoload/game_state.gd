extends Node
## GameState - Manages overall run state, world progression, and game flow
##
## This singleton tracks:
## - Current run state (alive/dead, current world, etc.)
## - Which worlds are unlocked
## - Party gold/currency
## - Save/load functionality
## - Scene transitions

# Signals
signal gold_changed(new_amount: int, change: int)

# Current run data
var current_world: String = "hell"  # Which world the player is currently in
var unlocked_worlds: Array[String] = ["hell"]  # Worlds player can travel to
var is_alive: bool = true
var current_run_number: int = 1  # How many times player has reincarnated

# Party resources
var gold: int = 100  # Starting gold

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

# World definitions
const WORLDS: Dictionary = {
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
