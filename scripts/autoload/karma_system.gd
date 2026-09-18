extends Node
## KarmaSystem - Tracks karma accumulation and handles reincarnation
##
## This singleton:
## - Tracks hidden karma scores for each realm
## - Determines reincarnation destination based on karma
## - Handles race selection within chosen realm
## - Manages meta-progression (affinities, persistent upgrades)

signal karma_changed(realm: String, new_value: int)
signal reincarnation_determined(target_realm: String, target_birth: String)

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

## How often a birth that HAS backgrounds of its own gets one, rather than a
## background anyone could have had.
##
## Without this the universal pool simply drowns the specific one: it carries 33
## backgrounds and 169 weight against a typical birth's five and 24, so a red
## devil came out devil-flavoured 12% of the time and a yidag — which had none
## of its own at all — never. Births are supposed to read differently from each
## other, and a background is most of how a character introduces itself.
##
## A birth with no backgrounds of its own is unaffected: it draws from the
## universal pool as before.
const BIRTH_SPECIFIC_BACKGROUND_CHANCE: float = 0.5

# Cached background data from races.json (loaded on first use)
var _background_cache: Dictionary = {}

func _ready() -> void:
	for realm in REALM_ORDER:
		assert(realm in karma_scores, "REALM_ORDER contains realm not in karma_scores: " + realm)
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

## Select a random birth from the reincarnation realm.
##
## The pool and the odds both come from races.json, via CharacterSystem, which
## owns the roll so that the player's rebirth and — once enemies are generated
## as characters — enemy births come off the same weights.
##
## A birth's `reincarnation_weight` is how likely someone is to be born as it.
## It does not govern how many of that birth exist in the world: companions
## carry a hand-authored `birth`, and enemies come from archetypes.
func select_birth_from_realm(realm: String) -> String:
	return CharacterSystem.roll_birth_for_realm(realm)


## Handle full reincarnation process
func reincarnate() -> Dictionary:
	var target_realm = determine_reincarnation_realm()
	var target_birth = select_birth_from_realm(target_realm)
	var target_background = select_random_background(target_birth)

	reincarnation_determined.emit(target_realm, target_birth)

	# Reset karma slightly (fresh start, but patterns persist)
	reset_karma_partially()

	return {
		"realm": target_realm,
		"birth": target_birth,
		"background": target_background
	}


## races.json's `backgrounds` block, read once and kept.
func _load_background_cache() -> void:
	if not _background_cache.is_empty():
		return
	var file = FileAccess.open("res://resources/data/races.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_background_cache = json.get_data().get("backgrounds", {})


## Every background this birth may be born into, split by whose it is.
##
## Two declarations decide it, and both count:
##   - `available_races` on the BACKGROUND, naming the births that may take it.
##     An empty list means anyone may.
##   - `typical_backgrounds` on the BIRTH, naming the backgrounds it is known
##     for. This is the field the review documents show and the one that reads
##     as authorial intent; until 2026-09-18 no game script read it, so a birth
##     could be "known for" a background the roll never offered it.
##
## A background the birth names is ITS background even when it is also
## universal — the birth has claimed it, and that claim is the whole point of
## the field. Returns {"specific": [...], "universal": [...]}, each an array of
## {"id": String, "weight": float}.
func get_background_pools(birth: String) -> Dictionary:
	_load_background_cache()

	var typical: Array = []
	if CharacterSystem:
		typical = CharacterSystem.get_birth_data(birth).get("typical_backgrounds", [])

	var specific: Array[Dictionary] = []
	var universal: Array[Dictionary] = []
	for bg_id in _background_cache:
		if bg_id.begins_with("_"):
			continue
		var bg: Dictionary = _background_cache[bg_id]
		var allowed: Array = bg.get("available_races", [])
		var entry := {"id": bg_id, "weight": float(bg.get("weight", 1))}

		if bg_id in typical or (not allowed.is_empty() and birth in allowed):
			specific.append(entry)
		elif allowed.is_empty():
			universal.append(entry)
		# else: whitelisted to other births and not named by this one — not offered.

	return {"specific": specific, "universal": universal}


## Weighted pick from one pool, or "" when it is empty.
func _weighted_pick(pool: Array) -> String:
	var total: float = 0.0
	for entry in pool:
		total += float(entry["weight"])
	if total <= 0.0:
		return ""

	var roll: float = randf() * total
	var cumulative: float = 0.0
	for entry in pool:
		cumulative += float(entry["weight"])
		if roll < cumulative:
			return String(entry["id"])
	return String(pool[pool.size() - 1]["id"])


## Select a random background appropriate for a birth, weighted by the
## background's own `weight`.
##
## The roll is split rather than pooled: a birth with backgrounds of its own
## takes one BIRTH_SPECIFIC_BACKGROUND_CHANCE of the time and a universal one
## otherwise. Pooling the two and letting weight decide is what produced the
## 12% above — the universal pool is five times the size and cannot help but
## win. Splitting first makes the intended frequency a number someone chose.
func select_random_background(birth: String) -> String:
	var pools: Dictionary = get_background_pools(birth)
	var specific: Array = pools["specific"]
	var universal: Array = pools["universal"]

	var picked := ""
	if not specific.is_empty() and randf() < BIRTH_SPECIFIC_BACKGROUND_CHANCE:
		picked = _weighted_pick(specific)
	if picked == "":
		picked = _weighted_pick(universal)
	# A birth whose only backgrounds are its own still gets one, rather than
	# falling through to the generic default because the universal roll lost.
	if picked == "":
		picked = _weighted_pick(specific)

	return picked if picked != "" else "wanderer"

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
## amount_multiplier: >1.0 when practicing at a consecrated site (enhanced camp activity)
func perform_purification(yoga_level: int, ritual_tier: int, amount_multiplier: float = 1.0) -> Dictionary:
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

	# Consecrated site bonus (enhanced camp activity)
	if amount_multiplier != 1.0:
		base_amount = roundi(base_amount * amount_multiplier)

	# Distribute starting from the lowest realm, carrying remainder upward
	var remaining := base_amount
	var realms_affected: Array[Dictionary] = []
	for realm in REALM_ORDER:
		if remaining <= 0:
			break
		var current: int = karma_scores.get(realm, 0)
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
