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
## Bond tags        → the vocabulary RelationshipSystem scores party rapport on
## Opposed traits   → symmetric pairs that grate; also scored by RelationshipSystem

## Emitted when an acquisition hook grants a trait for the first time. The
## overworld shows a toast; the combat arena appends to the log.
signal trait_gained(character_name: String, trait_id: String)

## Emitted when a trait is dropped by a hook (a limb regrown, an addiction cured).
signal trait_lost(character_name: String, trait_id: String)

## Emitted when one trait settles into another — grief becoming observance.
signal trait_replaced(character_name: String, old_id: String, new_id: String)

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


## Returns all trait IDs of a given category that are marked inborn: true.
## Used by character creation to assign random starting traits.
func get_inborn_traits(category: String) -> Array[String]:
	var result: Array[String] = []
	for trait_id in _traits:
		var t: Dictionary = _traits[trait_id]
		if t.get("inborn", false) and t.get("category", "") == category:
			result.append(trait_id)
	return result


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


## Grant a trait once, announcing it, and report whether it was actually new.
## This is what the acquisition hooks (wounds, limb loss, practice, combat) call:
## they fire on events that can recur, and should stay silent after the first time.
func grant_trait(character: Dictionary, trait_id: String) -> bool:
	if trait_id not in _traits:
		push_warning("TraitSystem.grant_trait: unknown trait '%s'" % trait_id)
		return false
	if trait_id in character.get("traits", []):
		return false
	add_trait(character, trait_id)
	trait_gained.emit(character.get("name", "Someone"), trait_id)
	return true


## Swap one trait for another in a single step — grief settling into observance,
## devotion lapsing. Silent if the character never had the old trait.
func replace_trait(character: Dictionary, old_id: String, new_id: String) -> bool:
	if old_id not in character.get("traits", []):
		return false
	remove_trait(character, old_id)
	add_trait(character, new_id)
	trait_replaced.emit(character.get("name", "Someone"), old_id, new_id)
	return true


## Drop a trait and say so. Mirrors grant_trait for the losing side.
func lose_trait(character: Dictionary, trait_id: String) -> bool:
	if trait_id not in character.get("traits", []):
		return false
	remove_trait(character, trait_id)
	trait_lost.emit(character.get("name", "Someone"), trait_id)
	return true


## The bonding vocabulary this trait belongs to (shared tags draw characters
## together, see RelationshipSystem).
func get_bond_tags(trait_id: String) -> Array:
	return get_trait(trait_id).get("bond_tags", [])


## Traits that grate against this one. Always symmetric in the data.
func get_opposed_traits(trait_id: String) -> Array:
	return get_trait(trait_id).get("opposed_traits", [])


## Every bond tag carried by a character, with duplicates — two devotion traits
## should count for more than one.
func get_character_bond_tags(character: Dictionary) -> Array:
	var tags: Array = []
	for trait_id in character.get("traits", []):
		tags.append_array(get_bond_tags(trait_id))
	return tags


## Does the character have any of these traits?
func has_any_trait(character: Dictionary, trait_ids: Array) -> bool:
	for trait_id in trait_ids:
		if trait_id in character.get("traits", []):
			return true
	return false


## All trait ids on a character that carry the given bond tag.
func traits_with_bond_tag(character: Dictionary, bond_tag: String) -> Array:
	var found: Array = []
	for trait_id in character.get("traits", []):
		if bond_tag in get_bond_tags(trait_id):
			found.append(trait_id)
	return found


## Total resistances a character's traits confer, as {damage_type: percent}.
## Summed across traits, so two sources of poison resistance stack the way
## racial and equipment resistances already do.
##
## Read by CharacterSystem.update_derived_stats() into derived.resistances,
## which is what CombatUnit.get_resistance() consults — so this is the only
## place trait resistances need to exist.
func get_resistances(character: Dictionary) -> Dictionary:
	var total: Dictionary = {}
	for trait_id in character.get("traits", []):
		var t := get_trait(trait_id)
		for damage_type in t.get("resistances", {}):
			total[damage_type] = total.get(damage_type, 0) + int(t["resistances"][damage_type])
	return total


## Plain-language lines describing everything a trait actually does.
##
## The flavour text is not meant to restate the mechanics — the tooltip shows
## these first, then a rule, then the flavour — so a description that says
## "+1 Finesse" is duplicating this and should be rewritten.
func describe_effects(trait_id: String) -> Array[String]:
	var t := get_trait(trait_id)
	var lines: Array[String] = []
	if t.is_empty():
		return lines

	for attr in t.get("stat_modifiers", {}):
		lines.append("%+d %s" % [int(t["stat_modifiers"][attr]), attr.capitalize()])
	for skill in t.get("skill_modifiers", {}):
		lines.append("%+d %s" % [int(t["skill_modifiers"][skill]),
				skill.replace("_", " ").capitalize()])

	# Pressure shifts the baseline that emotional decay pulls toward, which is
	# opaque as a bare number — name the pole it leans to instead.
	for element in t.get("pressure_modifiers", {}):
		var amount: float = float(t["pressure_modifiers"][element])
		if is_zero_approx(amount):
			continue
		lines.append("Rests nearer %s (%s %+d)" % [
			_pole_name(element, amount > 0.0), element.capitalize(), int(amount)])

	var bonds: Array = t.get("bond_tags", [])
	if not bonds.is_empty():
		lines.append("Bonds over: " + ", ".join(bonds))

	var opposed: Array = t.get("opposed_traits", [])
	if not opposed.is_empty():
		var names: Array[String] = []
		for other in opposed:
			names.append(get_trait_name(other))
		lines.append("Grates against: " + ", ".join(names))

	var purge: Array = t.get("purgeable_by", [])
	if not purge.is_empty():
		var ways: Array[String] = []
		for skill in purge:
			ways.append("%s %d" % [str(skill).capitalize(), int(t.get("purge_difficulty", 1))])
		lines.append("Can be shed through " + " or ".join(ways))

	return lines


## The five poisons and their answering wisdoms, for readable pressure lines.
func _pole_name(element: String, bright: bool) -> String:
	match element:
		"space": return "clarity" if bright else "delusion"
		"fire":  return "warmth" if bright else "craving"
		"water": return "compassion" if bright else "aversion"
		"earth": return "equanimity" if bright else "pride"
		"air":   return "appreciation" if bright else "envy"
	return "balance" if bright else "affliction"


## Full tooltip body: what it does, a rule, then what it is.
func get_tooltip(trait_id: String) -> String:
	var t := get_trait(trait_id)
	if t.is_empty():
		return ""
	var effects := describe_effects(trait_id)
	var flavour: String = str(t.get("description", "")).strip_edges()
	if effects.is_empty():
		return flavour
	if flavour.is_empty():
		return "\n".join(effects)
	return "\n".join(effects) + "\n──────────\n" + flavour


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
