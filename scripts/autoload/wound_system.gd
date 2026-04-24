extends Node
## WoundSystem — persistent wounds and diseases between combats
##
## Wounds accumulate on characters from crits, undead attacks, and events.
## They persist through rests and escalate if untreated, requiring Medicine
## skill or a healing facility to cure. Stat penalties are applied in
## CharacterSystem.update_derived_stats().
##
## Body-location field is a thin hook for a future body-parts system (Caves
## of Qud style). For now it's display/flavour only.

# ── Wound/disease definitions ───────────────────────────────────────────────
# stat_penalties_pct: percentage reductions applied multiplicatively to derived stats
# escalates_to: wound id this becomes if untreated
# escalation_rests: how many rests before escalation
# cure_medicine_level: minimum Medicine skill to treat via Field Surgery
# category: "wound" (physical trauma) or "disease" (infectious/necrotic)

const WOUND_TYPES: Dictionary = {

	# ── Physical wounds (from crits) ─────────────────────────────────────
	# stat_penalties_pct values are % reductions applied to the derived stat.
	"deep_cut": {
		"display_name": "Deep Cut",
		"category": "wound",
		"stat_penalties_pct": {"dodge": -15, "max_hp": -10},
		"escalates_to": "infected_wound",
		"escalation_rests": 2,
		"cure_medicine_level": 2,
		"description": "A bleeding cut that needs cleaning and bandaging.",
	},
	"concussion": {
		"display_name": "Concussion",
		"category": "wound",
		"stat_penalties_pct": {"spellpower": -20, "initiative": -15},
		"escalates_to": "brain_fever",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "A blow to the head leaves the mind clouded.",
	},
	"broken_rib": {
		"display_name": "Broken Rib",
		"category": "wound",
		"stat_penalties_pct": {"max_hp": -20, "max_stamina": -20},
		"escalates_to": "internal_bleeding",
		"escalation_rests": 2,
		"cure_medicine_level": 4,
		"description": "Cracked bone makes every breath sharp agony.",
	},

	# ── Diseases (undead/diseased enemy hits, events) ────────────────────
	"rot_sickness": {
		"display_name": "Rot Sickness",
		"category": "disease",
		"stat_penalties_pct": {"max_hp": -15, "dodge": -15},
		"escalates_to": "death_rot",
		"escalation_rests": 3,
		"cure_medicine_level": 4,
		"description": "Undead taint spreads through the blood.",
	},
	"marrow_chill": {
		"display_name": "Marrow Chill",
		"category": "disease",
		"stat_penalties_pct": {"initiative": -20, "spellpower": -15},
		"escalates_to": "bone_fever",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "A spectral cold has settled deep into the bones.",
	},

	# ── Escalated wounds ─────────────────────────────────────────────────
	"infected_wound": {
		"display_name": "Infected Wound",
		"category": "wound",
		"stat_penalties_pct": {"dodge": -25, "max_hp": -20, "max_stamina": -10},
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 5,
		"description": "Infection has set in. Requires urgent treatment.",
	},
	"brain_fever": {
		"display_name": "Brain Fever",
		"category": "disease",
		"stat_penalties_pct": {"spellpower": -30, "initiative": -25, "max_hp": -15},
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "Swollen brain leaves the victim barely conscious.",
	},
	"internal_bleeding": {
		"display_name": "Internal Bleeding",
		"category": "wound",
		"stat_penalties_pct": {"max_hp": -35, "max_stamina": -25},
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "Blood pools internally. Without surgery, death approaches.",
	},
	"death_rot": {
		"display_name": "Death Rot",
		"category": "disease",
		"stat_penalties_pct": {"max_hp": -25, "dodge": -20, "initiative": -10},
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 7,
		"description": "Necromantic corruption is consuming the body.",
	},
	"bone_fever": {
		"display_name": "Bone Fever",
		"category": "disease",
		"stat_penalties_pct": {"initiative": -30, "spellpower": -20, "max_hp": -20},
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "The chill has broken into a raging fever. Bones feel like glass.",
	},
}

# Random wound pool for combat crits (base wounds only)
const CRIT_WOUND_POOL: Array[String] = ["deep_cut", "concussion", "broken_rib"]

# Random disease pool for undead/diseased enemy hits
const DISEASE_POOL: Array[String] = ["rot_sickness", "marrow_chill"]


# ── Public API ───────────────────────────────────────────────────────────────

## Apply a wound/disease to a character. Returns false if already has this wound.
func apply_wound(character: Dictionary, wound_id: String, body_location: String = "", source: String = "") -> bool:
	if not wound_id in WOUND_TYPES:
		push_warning("WoundSystem: unknown wound '%s'" % wound_id)
		return false
	_ensure_wounds_field(character)
	# Don't apply duplicate wound ids
	for existing in character.wounds:
		if existing.get("id") == wound_id:
			return false
	character.wounds.append({
		"id": wound_id,
		"body_location": body_location,
		"rests_untreated": 0,
		"source": source,
	})
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
	print("WoundSystem: %s gained %s%s" % [
		character.get("name", "?"),
		WOUND_TYPES[wound_id].display_name,
		(" [%s]" % body_location if body_location != "" else ""),
	])
	return true


## Apply a random wound appropriate to a crit hit.
func apply_random_crit_wound(character: Dictionary) -> String:
	var id: String = CRIT_WOUND_POOL[randi() % CRIT_WOUND_POOL.size()]
	apply_wound(character, id, "", "combat_crit")
	return id


## Apply a random disease appropriate to an undead/diseased attacker.
func apply_random_disease(character: Dictionary, attacker_tag: String = "undead") -> String:
	var id: String = DISEASE_POOL[randi() % DISEASE_POOL.size()]
	apply_wound(character, id, "", attacker_tag)
	return id


## Cure one wound by id. Returns true if the wound was found and removed.
func cure_wound(character: Dictionary, wound_id: String) -> bool:
	_ensure_wounds_field(character)
	for i in range(character.wounds.size()):
		if character.wounds[i].get("id") == wound_id:
			character.wounds.remove_at(i)
			if CharacterSystem:
				CharacterSystem.update_derived_stats(character)
			return true
	return false


## Field Surgery: a Medicine-skilled character treats the whole party.
## Returns a dict: {"cured": [names], "messages": [strings]}
func cure_wounds_field_surgery(performer: Dictionary, party: Array) -> Dictionary:
	var medicine: int = 0
	if CharacterSystem:
		medicine = CharacterSystem.get_effective_skill_level(performer, "medicine")
	var cured_names: Array[String] = []
	var messages: Array[String] = []
	for char in party:
		_ensure_wounds_field(char)
		var to_remove: Array[String] = []
		for wound_entry in char.wounds:
			var wid: String = wound_entry.get("id", "")
			var wdef: Dictionary = WOUND_TYPES.get(wid, {})
			if wdef.is_empty():
				continue
			if medicine >= wdef.get("cure_medicine_level", 99):
				to_remove.append(wid)
		for wid in to_remove:
			cure_wound(char, wid)
			var wdef = WOUND_TYPES.get(wid, {})
			cured_names.append(char.get("name", "?"))
			messages.append("%s's %s treated." % [char.get("name", "?"), wdef.get("display_name", wid)])
	if messages.is_empty():
		messages.append("No treatable wounds found (Medicine %d too low, or no wounds)." % medicine)
	return {"cured": cured_names, "messages": messages}


## Tick all wounds at rest. Increments counters, escalates if threshold reached.
## Returns an array of narrative messages about any escalations.
func tick_wounds(character: Dictionary) -> Array[String]:
	_ensure_wounds_field(character)
	var messages: Array[String] = []
	var i := 0
	while i < character.wounds.size():
		var entry: Dictionary = character.wounds[i]
		var wid: String = entry.get("id", "")
		var wdef: Dictionary = WOUND_TYPES.get(wid, {})
		if wdef.is_empty():
			i += 1
			continue
		var threshold: int = wdef.get("escalation_rests", 0)
		if threshold <= 0:
			i += 1
			continue
		entry["rests_untreated"] = entry.get("rests_untreated", 0) + 1
		if entry["rests_untreated"] >= threshold:
			var escalation_id: String = wdef.get("escalates_to", "")
			if escalation_id != "" and escalation_id in WOUND_TYPES:
				var old_name: String = wdef.get("display_name", wid)
				entry["id"] = escalation_id
				entry["rests_untreated"] = 0
				var new_name: String = WOUND_TYPES[escalation_id].get("display_name", escalation_id)
				var char_name: String = character.get("name", "Unknown")
				messages.append("%s's %s has worsened into %s!" % [char_name, old_name, new_name])
				print("WoundSystem: %s escalated to %s" % [old_name, new_name])
		i += 1
	if not messages.is_empty() and CharacterSystem:
		CharacterSystem.update_derived_stats(character)
	return messages


## Compute total stat penalties from all active wounds. Called by update_derived_stats.
## Returns summed percentage penalties per stat key.
## Keys are plain stat names (e.g. "dodge", "max_hp"); values are summed % integers (e.g. -25).
## Applied multiplicatively in update_derived_stats: derived[stat] *= (1 + pct/100).
func get_stat_penalties(character: Dictionary) -> Dictionary:
	if not "wounds" in character or character.wounds.is_empty():
		return {}
	var totals: Dictionary = {}
	for entry in character.wounds:
		var wid: String = entry.get("id", "")
		var wdef: Dictionary = WOUND_TYPES.get(wid, {})
		if wdef.is_empty():
			continue
		for stat in wdef.get("stat_penalties_pct", {}):
			totals[stat] = totals.get(stat, 0) + wdef.stat_penalties_pct[stat]
	return totals


## Convenience: get the wounds array (empty array if field missing).
func get_wounds(character: Dictionary) -> Array:
	return character.get("wounds", [])


## True if character has at least one wound of the given category.
func has_wound_category(character: Dictionary, category: String) -> bool:
	for entry in character.get("wounds", []):
		var wdef = WOUND_TYPES.get(entry.get("id", ""), {})
		if wdef.get("category", "") == category:
			return true
	return false


## Heal at temple/facility: cure wounds up to the given medicine equivalent level.
## Gold cost is handled by the calling site.
func heal_at_facility(character: Dictionary, medicine_equivalent: int) -> Dictionary:
	_ensure_wounds_field(character)
	var messages: Array[String] = []
	var to_remove: Array[String] = []
	for entry in character.wounds:
		var wid: String = entry.get("id", "")
		var wdef: Dictionary = WOUND_TYPES.get(wid, {})
		if not wdef.is_empty() and medicine_equivalent >= wdef.get("cure_medicine_level", 99):
			to_remove.append(wid)
	for wid in to_remove:
		cure_wound(character, wid)
		messages.append(WOUND_TYPES[wid].get("display_name", wid) + " healed.")
	if messages.is_empty():
		messages.append("No treatable wounds found.")
	return {"messages": messages, "count": to_remove.size()}


# ── Internals ────────────────────────────────────────────────────────────────

func _ensure_wounds_field(character: Dictionary) -> void:
	if not "wounds" in character:
		character["wounds"] = []
