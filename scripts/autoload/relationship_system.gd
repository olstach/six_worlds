extends Node
## RelationshipSystem — how the party members feel about each other.
##
## Deliberately small. This is not a court simulation: it exists so that
## periodic events have something to fire on, and so that a party assembled
## from clashing people feels different from one that gets along.
##
## An opinion is a single number per unordered pair, roughly -100..100:
##
##   baseline  — derived from traits, recomputed whenever traits change.
##               Shared bond tags pull together, shared vices pull harder,
##               opposed traits push apart.
##   drift     — accumulated from things that happen: fighting side by side,
##               camp activities, event outcomes. Stored; never recomputed.
##
##   opinion = baseline + drift, clamped.
##
## Pairs are keyed by the two character keys sorted and joined, so the
## relationship is symmetric by construction — there is no "A likes B more
## than B likes A", which is the first thing a real simulation would add and
## the first thing that would double the bookkeeping.

## Emitted when an opinion crosses into a new band, in either direction.
## The overworld shows a toast; events can key off the new band.
signal relationship_changed(name_a: String, name_b: String, band: String)

## Opinion bands. Order matters — get_band() walks these from the top down.
const BANDS: Array[Dictionary] = [
	{"min": 60, "id": "sworn", "label": "Sworn"},
	{"min": 25, "id": "warm", "label": "Warm"},
	{"min": -24, "id": "neutral", "label": "Neutral"},
	{"min": -59, "id": "cool", "label": "Cool"},
	{"min": -100, "id": "rival", "label": "Rivals"},
]

## Trait-derived baseline weights.
const SHARED_TAG_BONUS: int = 4          # per bond tag both characters carry
const SHARED_VICE_BONUS: int = 4         # vices bond harder than virtues do
const OPPOSED_TRAIT_PENALTY: int = -9    # per opposed pair between them
const BASELINE_CAP: int = 45             # traits alone never reach "Sworn"

const OPINION_MIN: float = -100.0
const OPINION_MAX: float = 100.0

## pair key -> accumulated drift. Baseline is recomputed on demand, never stored,
## so editing traits.json cannot leave stale numbers in a save file.
var _drift: Dictionary = {}

## pair key -> band id at the last check, so we only emit on an actual crossing.
var _last_band: Dictionary = {}


# ============================================
# IDENTITY
# ============================================

## Stable per-character key. Companions carry companion_id; the player character
## does not, and there is only ever one, so "player" is unambiguous.
func get_character_key(character: Dictionary) -> String:
	var cid: String = str(character.get("companion_id", ""))
	if cid != "":
		return cid
	return "player"


func _pair_key(a: Dictionary, b: Dictionary) -> String:
	var ka := get_character_key(a)
	var kb := get_character_key(b)
	if ka <= kb:
		return ka + "|" + kb
	return kb + "|" + ka


# ============================================
# READING
# ============================================

## Trait-derived component. Recomputed on every call — cheap, and it means a
## character who loses a trait immediately stops being liked for it.
func get_baseline(a: Dictionary, b: Dictionary) -> int:
	if not TraitSystem:
		return 0
	var traits_a: Array = a.get("traits", [])
	var traits_b: Array = b.get("traits", [])
	if traits_a.is_empty() or traits_b.is_empty():
		return 0

	var score: int = 0

	# Shared bond tags. Counted per overlapping pair of traits rather than per
	# distinct tag, so two devout characters with several devotion traits each
	# feel it more than two who share one.
	var tags_a: Array = TraitSystem.get_character_bond_tags(a)
	var tags_b: Array = TraitSystem.get_character_bond_tags(b)
	for tag in tags_a:
		if tag in tags_b:
			score += SHARED_VICE_BONUS if tag == "vice" else SHARED_TAG_BONUS

	# Opposed traits. Symmetric in the data, so checking one direction is enough.
	for trait_id in traits_a:
		for opposed in TraitSystem.get_opposed_traits(trait_id):
			if opposed in traits_b:
				score += OPPOSED_TRAIT_PENALTY

	return clampi(score, -BASELINE_CAP, BASELINE_CAP)


## Full opinion: trait baseline plus everything that has happened since.
func get_opinion(a: Dictionary, b: Dictionary) -> int:
	if get_character_key(a) == get_character_key(b):
		return 0
	var drift: float = float(_drift.get(_pair_key(a, b), 0.0))
	return int(clampf(float(get_baseline(a, b)) + drift, OPINION_MIN, OPINION_MAX))


func get_band(a: Dictionary, b: Dictionary) -> String:
	return _band_for(get_opinion(a, b))


func get_band_label(a: Dictionary, b: Dictionary) -> String:
	var band := get_band(a, b)
	for entry in BANDS:
		if entry["id"] == band:
			return str(entry["label"])
	return "Neutral"


func _band_for(opinion: int) -> String:
	for entry in BANDS:
		if opinion >= int(entry["min"]):
			return str(entry["id"])
	return "rival"


## Why these two feel the way they do — for the party UI and for event text.
## Returns e.g. ["Both devout", "Both fond of a drink", "Patient vs Hot-tempered"].
func explain(a: Dictionary, b: Dictionary) -> Array[String]:
	var reasons: Array[String] = []
	if not TraitSystem:
		return reasons

	var shared: Array = []
	var tags_b: Array = TraitSystem.get_character_bond_tags(b)
	for tag in TraitSystem.get_character_bond_tags(a):
		if tag in tags_b and not tag in shared:
			shared.append(tag)
	for tag in shared:
		reasons.append("Shared %s" % str(tag))

	for trait_id in a.get("traits", []):
		for opposed in TraitSystem.get_opposed_traits(trait_id):
			if opposed in b.get("traits", []):
				reasons.append("%s vs %s" % [
					TraitSystem.get_trait_name(trait_id),
					TraitSystem.get_trait_name(opposed),
				])
	return reasons


## Every pair in the party at or beyond a band, as {a, b, opinion, band}.
## This is what the periodic relationship events draw from.
func get_pairs_at_band(party: Array, band_ids: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for i in range(party.size()):
		for j in range(i + 1, party.size()):
			var band := get_band(party[i], party[j])
			if band in band_ids:
				found.append({
					"a": party[i], "b": party[j],
					"opinion": get_opinion(party[i], party[j]),
					"band": band,
				})
	return found


# ============================================
# WRITING
# ============================================

## Move a pair's opinion. Emits relationship_changed only when the band changes,
## so callers can nudge freely without spamming the player.
func adjust_opinion(a: Dictionary, b: Dictionary, amount: float, reason: String = "") -> void:
	if get_character_key(a) == get_character_key(b):
		return
	var key := _pair_key(a, b)
	var before := get_band(a, b)
	_drift[key] = clampf(float(_drift.get(key, 0.0)) + amount, OPINION_MIN, OPINION_MAX)
	var after := get_band(a, b)
	if after != before:
		_last_band[key] = after
		relationship_changed.emit(
			a.get("name", "Someone"), b.get("name", "Someone"), after)
		if reason != "":
			print("RelationshipSystem: %s & %s -> %s (%s)" % [
				a.get("name", "?"), b.get("name", "?"), after, reason])


## Nudge every pair in the party at once — shared experiences land on everyone.
## Used for surviving a fight together, a good night's rest, a party-wide loss.
func adjust_party(party: Array, amount: float, reason: String = "") -> void:
	for i in range(party.size()):
		for j in range(i + 1, party.size()):
			adjust_opinion(party[i], party[j], amount, reason)


## Drop everything about a character who has left the party, so a re-recruited
## companion does not carry a stale grudge from a previous run.
func forget_character(character: Dictionary) -> void:
	var key := get_character_key(character)
	for pair_key in _drift.keys():
		if key in str(pair_key).split("|"):
			_drift.erase(pair_key)
			_last_band.erase(pair_key)


func reset() -> void:
	_drift.clear()
	_last_band.clear()


# ============================================
# SAVE / LOAD
# ============================================

func get_save_data() -> Dictionary:
	return {"drift": _drift.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	_drift = data.get("drift", {}).duplicate(true)
	_last_band.clear()
