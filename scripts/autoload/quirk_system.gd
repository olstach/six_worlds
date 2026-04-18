extends Node
## QuirkSystem — loads quirk definitions and manages adding/removing quirks from characters.
##
## Quirks are persistent character traits (physical, personality, behavioral, acquired)
## that add texture, modify attributes/skills, shift emotional baselines, and unlock
## event options. They are stored as a list of IDs in character["quirks"].
##
## Stat modifiers   → applied in CharacterSystem.update_derived_stats() via get_attribute_bonus()
## Skill modifiers  → written into character["skill_bonuses"]["quirks"] source during update_derived_stats()
## Pressure offsets → applied to emotional_baseline when a quirk is added or removed
## Event tags       → referenced by event requirements: {"quirk": "curious"}
## Purge            → use remove_quirk(); purgeable_by lists which skills can remove it

var _quirks: Dictionary = {}


func _ready() -> void:
	_load_quirks()
	print("QuirkSystem initialized with %d quirks" % _quirks.size())


func _load_quirks() -> void:
	var path := "res://resources/data/quirks.json"
	if not FileAccess.file_exists(path):
		push_warning("QuirkSystem: quirks.json not found")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("QuirkSystem: failed to open quirks.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("QuirkSystem: failed to parse quirks.json")
		file.close()
		return
	file.close()
	_quirks = json.get_data()


# ============================================
# QUERY HELPERS
# ============================================

## Returns the full quirk definition dict, or {} if unknown.
func get_quirk(quirk_id: String) -> Dictionary:
	return _quirks.get(quirk_id, {})


## Returns the display name for a quirk ID.
func get_quirk_name(quirk_id: String) -> String:
	return _quirks.get(quirk_id, {}).get("name", quirk_id.replace("_", " ").capitalize())


## Returns true if the character has the given quirk.
func has_quirk(character: Dictionary, quirk_id: String) -> bool:
	return quirk_id in character.get("quirks", [])


## Returns the total attribute bonus dict from all of the character's quirks.
## Keys are attribute names ("strength", "charm", etc.), values are summed ints.
func get_attribute_bonus(character: Dictionary) -> Dictionary:
	var bonus: Dictionary = {}
	for quirk_id in character.get("quirks", []):
		var q := get_quirk(quirk_id)
		for attr in q.get("stat_modifiers", {}):
			bonus[attr] = bonus.get(attr, 0) + int(q["stat_modifiers"][attr])
	return bonus


# ============================================
# ADD / REMOVE
# ============================================

## Add a quirk to a character. Applies pressure baseline offset immediately.
## Calls CharacterSystem.update_derived_stats() to apply attribute/skill modifiers.
func add_quirk(character: Dictionary, quirk_id: String) -> void:
	if quirk_id not in _quirks:
		push_warning("QuirkSystem.add_quirk: unknown quirk '%s'" % quirk_id)
		return
	if not "quirks" in character:
		character["quirks"] = []
	if quirk_id in character["quirks"]:
		return  # Already has it
	character["quirks"].append(quirk_id)
	_apply_pressure_offset(character, quirk_id, 1)
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)


## Remove a quirk from a character. Reverses pressure baseline offset.
## Calls CharacterSystem.update_derived_stats() to recompute stats.
func remove_quirk(character: Dictionary, quirk_id: String) -> void:
	if not "quirks" in character or quirk_id not in character["quirks"]:
		return
	character["quirks"].erase(quirk_id)
	_apply_pressure_offset(character, quirk_id, -1)
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)


## Attempt to purge a quirk via a skill-based practice (yoga, ritual).
## Returns true if the purge succeeds (character has the required skill at required level).
func try_purge(character: Dictionary, quirk_id: String, skill_used: String) -> bool:
	var q := get_quirk(quirk_id)
	if skill_used not in q.get("purgeable_by", []):
		return false
	var required_level: int = q.get("purge_difficulty", 1)
	# Use effective skill level (base + equipment/race/quirk bonuses) for consistency
	var base_skill: int = character.get("skills", {}).get(skill_used, 0)
	var bonus_sources: Dictionary = character.get("skill_bonuses", {}).get(skill_used, {})
	var skill_bonus: int = 0
	for src in bonus_sources:
		skill_bonus += int(bonus_sources[src])
	var skill_level: int = clampi(base_skill + skill_bonus, 0, 15)
	if skill_level < required_level:
		return false
	remove_quirk(character, quirk_id)
	return true


# ============================================
# INTERNAL
# ============================================

## Apply (sign = +1) or undo (sign = -1) a quirk's pressure_modifiers on the character's
## emotional_baseline. The baseline is what all pressure decay moves toward.
func _apply_pressure_offset(character: Dictionary, quirk_id: String, sign: int) -> void:
	var q := get_quirk(quirk_id)
	var baseline: Dictionary = character.get("emotional_baseline", {})
	for element in q.get("pressure_modifiers", {}):
		if element in baseline:
			baseline[element] = clamp(
				baseline[element] + sign * float(q["pressure_modifiers"][element]),
				-100.0, 100.0
			)
