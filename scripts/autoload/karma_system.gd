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

# Cached background data from races.json (loaded on first use)
var _background_cache: Dictionary = {}

# Race pools for each realm
const REALM_RACES: Dictionary = {
	"hell": ["red_devil", "blue_devil", "green_devil", "yellow_devil", "white_devil", "black_devil"],
	"hungry_ghost": ["rolang", "skeleton", "skeleton_silver", "skeleton_copper", "skeleton_golden", "skeleton_iron", "skeleton_turquoise", "dralha", "gyelpo", "dre", "vetala", "shaza", "yidag"],
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
	"rolang": 35,
	"skeleton": 30,
	"skeleton_silver": 15,
	"skeleton_copper": 15,
	"skeleton_golden": 15,
	"skeleton_iron": 15,
	"skeleton_turquoise": 15,
	"dralha": 7,
	"gyelpo": 5,
	"dre": 5,
	"vetala": 10,
	"shaza": 10,
	"yidag": 10,
	
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

	# Full moon and new moon amplify all karmic changes by 50% (positive and negative alike)
	if GameState.is_full_moon() or GameState.is_new_moon():
		amount = roundi(amount * 1.5)

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
	var highest_karma = -INF

	# Only consider realms the player has actually visited/unlocked
	var unlocked = GameState.unlocked_worlds if GameState else ["hell"]

	for realm in karma_scores:
		if realm not in unlocked:
			continue  # Can't be reborn somewhere you've never been
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

## Select random background appropriate for race, weighted by background data.
## Loads from races.json — backgrounds with an empty available_races list are universal;
## otherwise the race must be in the whitelist.
func select_random_background(race: String) -> String:
	if _background_cache.is_empty():
		var file = FileAccess.open("res://resources/data/races.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_background_cache = json.get_data().get("backgrounds", {})
	# Build weighted pool of backgrounds available for this race
	var pool: Array[String] = []
	var weights: Array[float] = []
	for bg_id in _background_cache:
		if bg_id.begins_with("_"):
			continue
		var bg: Dictionary = _background_cache[bg_id]
		var allowed: Array = bg.get("available_races", [])
		if allowed.is_empty() or race in allowed:
			pool.append(bg_id)
			weights.append(float(bg.get("weight", 1)))
	if pool.is_empty():
		return "wanderer"
	# Weighted random selection
	var total_weight := 0.0
	for w in weights:
		total_weight += w
	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in range(pool.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return pool[i]
	return pool[0]

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

# Realm hierarchy lowest → highest; purification targets this order
const REALM_ORDER: Array[String] = ["hell", "hungry_ghost", "animal", "human", "asura", "god"]

## Calculate and apply karma purification during a sadhana rest practice.
## yoga_level: best Yoga skill in party. ritual_tier: 0 (none) – 3 (mandala).
## Returns { "success": bool, "total": int, "realms": Array[Dictionary] }
## where realms = [{ "realm": String, "amount": int }].
func perform_purification(yoga_level: int, ritual_tier: int) -> Dictionary:
	var base_amount := 0

	# Yoga determines base amount and whether a roll is required
	if yoga_level >= 7:
		base_amount = 50                              # Reliable — no roll
	elif yoga_level >= 5:
		var roll := randi() % 20 + 1 + yoga_level    # d20 + Yoga vs DC 8
		if roll < 8:
			return { "success": false, "total": 0, "realms": [] }
		base_amount = 35
	elif yoga_level >= 3:
		var roll := randi() % 20 + 1 + yoga_level    # d20 + Yoga vs DC 12
		if roll < 12:
			return { "success": false, "total": 0, "realms": [] }
		base_amount = 20
	else:
		return { "success": false, "total": 0, "realms": [] }

	# Ritual augmentation adds on top of the yoga base
	match ritual_tier:
		1: base_amount += 15
		2: base_amount += 30
		3: base_amount += 50

	# Full moon / new moon amplifies purification (mirrors the karma weight multiplier)
	if GameState.is_full_moon() or GameState.is_new_moon():
		base_amount = roundi(base_amount * 1.5)

	# Distribute starting from the lowest realm, carrying remainder upward
	var remaining := base_amount
	var realms_affected: Array[Dictionary] = []
	for realm in REALM_ORDER:
		if remaining <= 0:
			break
		var current := karma_scores.get(realm, 0)
		if current <= 0:
			continue
		var to_purify := mini(remaining, current)
		_purify_karma_internal(realm, to_purify)
		realms_affected.append({ "realm": realm, "amount": to_purify })
		remaining -= to_purify

	return { "success": true, "total": base_amount - remaining, "realms": realms_affected }


## Internal: reduce karma for one realm and emit the change signal.
func _purify_karma_internal(realm: String, amount: int) -> void:
	if realm in karma_scores:
		karma_scores[realm] = max(0, karma_scores[realm] - amount)
		karma_changed.emit(realm, karma_scores[realm])


## Perform karma purification ritual (direct, legacy call — prefer perform_purification).
func purify_karma(realm: String, amount: int) -> void:
	_purify_karma_internal(realm, amount)


# ============================================
# SAVE / LOAD
# ============================================

## Collect saveable state into a dictionary
func get_save_data() -> Dictionary:
	return {
		"karma_scores": karma_scores.duplicate()
	}


## Restore state from a save dictionary
func load_save_data(data: Dictionary) -> void:
	var saved = data.get("karma_scores", {})
	for realm in karma_scores:
		karma_scores[realm] = int(saved.get(realm, 0))
