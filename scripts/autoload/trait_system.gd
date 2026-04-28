extends Node
## TraitSystem — loads trait definitions and manages adding/removing traits from characters.
##
## Traits are persistent character modifiers from any source: racial (innate to a species),
## habitat (where you're from), role (combat archetype), unique (species ability), physical,
## personality, behavioral, acquired (events, wounds, practice rewards, blessings, curses).
## Stored as a list of IDs in character["traits"].
##
## Stat modifiers   → applied in CharacterSystem.update_derived_stats() via get_attribute_bonus()
## Skill modifiers  → written into character["skill_bonuses"]["traits"] source during update_derived_stats()
## Pressure offsets → applied to emotional_baseline when a trait is added or removed
## Event tags       → referenced by event requirements: {"trait": "curious"}
## Purge            → use remove_trait(); purgeable_by lists which skills can remove it

var _traits: Dictionary = {}


func _ready() -> void:
	_load_traits()
	print("TraitSystem initialized with %d traits" % _traits.size())


func _load_traits() -> void:
	var path := "res://resources/data/traits.json"
	if not FileAccess.file_exists(path):
		push_warning("TraitSystem: traits.json not found")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TraitSystem: failed to open traits.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("TraitSystem: failed to parse traits.json")
		file.close()
		return
	file.close()
	_traits = json.get_data()


# ============================================
# QUERY HELPERS
# ============================================

## Returns the full trait definition dict, or {} if unknown.
func get_trait(trait_id: String) -> Dictionary:
	return _traits.get(trait_id, {})


## Returns the display name for a trait ID.
func get_trait_name(trait_id: String) -> String:
	return _traits.get(trait_id, {}).get("name", trait_id.replace("_", " ").capitalize())


## Returns true if the character has the given trait.
func has_trait(character: Dictionary, trait_id: String) -> bool:
	return trait_id in character.get("traits", [])


## Returns the total attribute bonus dict from all of the character's traits.
## Keys are attribute names ("strength", "charm", etc.), values are summed ints.
func get_attribute_bonus(character: Dictionary) -> Dictionary:
	var bonus: Dictionary = {}
	for trait_id in character.get("traits", []):
		var t := get_trait(trait_id)
		for attr in t.get("stat_modifiers", {}):
			bonus[attr] = bonus.get(attr, 0) + int(t["stat_modifiers"][attr])
	return bonus


# ============================================
# ADD / REMOVE
# ============================================

## Add a trait to a character. Applies pressure baseline offset immediately.
## Calls CharacterSystem.update_derived_stats() to apply attribute/skill modifiers.
func add_trait(character: Dictionary, trait_id: String) -> void:
	if trait_id not in _traits:
		push_warning("TraitSystem.add_trait: unknown trait '%s'" % trait_id)
		return
	if not "traits" in character:
		character["traits"] = []
	if trait_id in character["traits"]:
		return  # Already has it
	character["traits"].append(trait_id)
	_apply_pressure_offset(character, trait_id, 1)
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)


## Remove a trait from a character. Reverses pressure baseline offset.
## Calls CharacterSystem.update_derived_stats() to recompute stats.
func remove_trait(character: Dictionary, trait_id: String) -> void:
	if not "traits" in character or trait_id not in character["traits"]:
		return
	character["traits"].erase(trait_id)
	_apply_pressure_offset(character, trait_id, -1)
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)


## Attempt to purge a trait via a skill-based practice (yoga, ritual).
## difficulty_modifier reduces the effective required level (e.g. Mandala Offering gives -2).
## Returns true if the purge succeeds (character has the required skill at required level).
func try_purge(character: Dictionary, trait_id: String, skill_used: String, difficulty_modifier: int = 0) -> bool:
	var t := get_trait(trait_id)
	if skill_used not in t.get("purgeable_by", []):
		return false
	var required_level: int = maxi(1, t.get("purge_difficulty", 1) - difficulty_modifier)
	# Use effective skill level (base + equipment/race/trait bonuses) for consistency
	var base_skill: int = character.get("skills", {}).get(skill_used, 0)
	var bonus_sources: Dictionary = character.get("skill_bonuses", {}).get(skill_used, {})
	var skill_bonus: int = 0
	for src in bonus_sources:
		skill_bonus += int(bonus_sources[src])
	var skill_level: int = clampi(base_skill + skill_bonus, 0, 15)
	if skill_level < required_level:
		return false
	remove_trait(character, trait_id)
	return true


# ============================================
# INTERNAL
# ============================================

## Apply (sign = +1) or undo (sign = -1) a trait's pressure_modifiers on the character's
## emotional_baseline. The baseline is what all pressure decay moves toward.
func _apply_pressure_offset(character: Dictionary, trait_id: String, sign: int) -> void:
	var t := get_trait(trait_id)
	var baseline: Dictionary = character.get("emotional_baseline", {})
	for element in t.get("pressure_modifiers", {}):
		if element in baseline:
			baseline[element] = clamp(
				baseline[element] + sign * float(t["pressure_modifiers"][element]),
				-100.0, 100.0
			)
