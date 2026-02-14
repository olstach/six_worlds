extends Node
## KarmaSystem - Tracks karma accumulation and handles reincarnation
##
## This singleton:
## - Tracks hidden karma scores for each realm
## - Determines reincarnation destination based on karma
## - Handles race selection within chosen realm
## - Manages meta-progression (affinities, persistent upgrades)

signal karma_changed(realm: String, new_value: int)
signal reincarnation_determined(target_realm: String, target_race: String)

# Hidden karma scores (player doesn't see exact numbers)
var karma_scores: Dictionary = {
	"hell": 0,
	"hungry_ghost": 0,
	"animal": 0,
	"human": 0,
	"asura": 0,
	"god": 0
}

# Karma thresholds for significant shifts
const KARMA_THRESHOLD: int = 100

# Race pools for each realm
const REALM_RACES: Dictionary = {
	"hell": ["red_devil", "blue_devil", "green_devil", "yellow_devil", "white_devil", "black_devil"],
	"hungry_ghost": ["zombie", "skeleton", "vetala"],
	"animal": ["naga", "bee", "yaksha"],
	"human": ["nomad", "mountain_folk", "trader"],
	"asura": ["tsen", "rudra"],
	"god": ["gandharva", "apsara", "planetary_deity"]
}

# Race rarity weights (higher = more common)
const RACE_WEIGHTS: Dictionary = {
	# Hell realm
	"red_devil": 30,
	"blue_devil": 30,
	"green_devil": 15,
	"yellow_devil": 15,
	"white_devil": 5,
	"black_devil": 5,
	
	# Hungry ghost realm
	"zombie": 40,
	"skeleton": 40,
	"vetala": 20,
	
	# Animal realm
	"naga": 35,
	"bee": 35,
	"yaksha": 30,
	
	# Human realm
	"nomad": 33,
	"mountain_folk": 34,
	"trader": 33,
	
	# Asura realm
	"tsen": 50,
	"rudra": 50,
	
	# God realm
	"gandharva": 40,
	"apsara": 40,
	"planetary_deity": 20
}

func _ready() -> void:
	print("KarmaSystem initialized")

## Add karma to a specific realm based on player actions
func add_karma(realm: String, amount: int, action_description: String = "") -> void:
	if realm not in karma_scores:
		return
	
	karma_scores[realm] += amount
	
	karma_changed.emit(realm, karma_scores[realm])

## Process a choice/action and apply its karma consequences
func process_choice(choice_data: Dictionary) -> void:
	# choice_data contains karma tags for different realms
	# Example: {"hell": -10, "god": 5, "human": 2}
	for realm in choice_data:
		if realm in karma_scores:
			add_karma(realm, choice_data[realm])

## Determine which realm player reincarnates into
func determine_reincarnation_realm() -> String:
	var highest_realm = "hell"  # Default fallback
	var highest_karma = karma_scores["hell"]
	
	# Find realm with highest karma
	for realm in karma_scores:
		if karma_scores[realm] > highest_karma:
			highest_karma = karma_scores[realm]
			highest_realm = realm
	
	return highest_realm

## Select a random race from the reincarnation realm
func select_race_from_realm(realm: String) -> String:
	if realm not in REALM_RACES:
		return "human"
	
	var available_races = REALM_RACES[realm]
	var weights: Array[int] = []
	
	# Build weight array
	for race in available_races:
		weights.append(RACE_WEIGHTS.get(race, 10))
	
	# Weighted random selection
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var roll = randi() % total_weight
	var cumulative = 0
	
	for i in range(available_races.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return available_races[i]
	
	return available_races[0]  # Fallback

## Handle full reincarnation process
func reincarnate() -> Dictionary:
	var target_realm = determine_reincarnation_realm()
	var target_race = select_race_from_realm(target_realm)
	var target_background = select_random_background(target_race)
	
	reincarnation_determined.emit(target_realm, target_race)
	
	# Reset karma slightly (fresh start, but patterns persist)
	reset_karma_partially()
	
	return {
		"realm": target_realm,
		"race": target_race,
		"background": target_background
	}

## Select random background appropriate for race
func select_random_background(race: String) -> String:
	# TODO: Load from background data files
	# For now, simple examples
	var backgrounds = {
		"red_devil": ["warrior", "berserker", "guard"],
		"human": ["wanderer", "scholar", "merchant", "monk", "noble"],
		"naga": ["diplomat", "guardian", "scholar"],
	}
	
	var options = backgrounds.get(race, ["wanderer"])
	return options[randi() % options.size()]

## Reduce karma scores partially (some patterns persist)
func reset_karma_partially() -> void:
	for realm in karma_scores:
		karma_scores[realm] = int(karma_scores[realm] * 0.3)  # Keep 30% of karma

## Get karma report (for debugging/testing - normally hidden from player)
func get_karma_report() -> String:
	var report = "Karma Scores:\n"
	for realm in karma_scores:
		report += "  " + realm + ": " + str(karma_scores[realm]) + "\n"
	return report

## Check if player can perform karma purification ritual
func can_purify_karma(realm: String, required_items: Array) -> bool:
	# TODO: Check if player has required ritual items
	return false

## Perform karma purification ritual
func purify_karma(realm: String, amount: int) -> void:
	if realm in karma_scores:
		karma_scores[realm] = max(0, karma_scores[realm] - amount)
		karma_changed.emit(realm, karma_scores[realm])
