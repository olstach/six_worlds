extends Node
## WoundSystem — persistent wounds and diseases between combats
##
## Wounds accumulate on characters from crits, undead attacks, and events.
## They persist through rests and escalate if untreated, requiring Medicine
## skill or a healing facility to cure. Stat penalties are derived from the
## wound's severity combined with the body_location's part category — see
## BodySystem.WOUND_PENALTIES. Applied in CharacterSystem.update_derived_stats().

# ── Wound/disease definitions ───────────────────────────────────────────────
# severity: "light" | "moderate" | "severe" — determines penalty magnitude
#   via BodySystem.WOUND_PENALTIES[part_category][severity]
# forced_location: part id always assigned to this wound type ("" = random)
# escalates_to: wound id this becomes if untreated
# escalation_rests: how many rests before escalation (0 = never escalates further)
# cure_medicine_level: minimum Medicine skill to treat via Field Surgery
# category: "wound" (physical trauma) | "disease" (infectious/necrotic)

const WOUND_TYPES: Dictionary = {

	# ── Physical wounds (from crits) ─────────────────────────────────────
	"deep_cut": {
		"display_name": "Deep Cut",
		"category": "wound",
		"severity": "light",
		"forced_location": "",       # random arm/leg/torso
		"escalates_to": "infected_wound",
		"escalation_rests": 2,
		"cure_medicine_level": 2,
		"description": "A bleeding cut that needs cleaning and bandaging.",
	},
	"concussion": {
		"display_name": "Concussion",
		"category": "wound",
		"severity": "moderate",
		"forced_location": "head",
		"escalates_to": "brain_fever",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "A blow to the head leaves the mind clouded.",
	},
	"broken_rib": {
		"display_name": "Broken Rib",
		"category": "wound",
		"severity": "moderate",
		"forced_location": "torso",
		"escalates_to": "internal_bleeding",
		"escalation_rests": 2,
		"cure_medicine_level": 4,
		"description": "Cracked bone makes every breath sharp agony.",
	},

	# ── Diseases (undead/diseased enemy hits, events) ────────────────────
	"rot_sickness": {
		"display_name": "Rot Sickness",
		"category": "disease",
		"severity": "light",
		"forced_location": "",       # random
		"escalates_to": "death_rot",
		"escalation_rests": 3,
		"cure_medicine_level": 4,
		"description": "Undead taint spreads through the blood.",
	},
	"marrow_chill": {
		"display_name": "Marrow Chill",
		"category": "disease",
		"severity": "light",
		"forced_location": "",       # random
		"escalates_to": "bone_fever",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "A spectral cold has settled deep into the bones.",
	},

	# ── Escalated wounds ─────────────────────────────────────────────────
	# Location is inherited from the original wound entry — not re-assigned on escalation.
	"infected_wound": {
		"display_name": "Seeping Wound",
		"category": "wound",
		"severity": "severe",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 5,
		"description": "Infection has set in. Requires urgent treatment.",
	},
	"brain_fever": {
		"display_name": "Brain Fever",
		"category": "disease",
		"severity": "severe",
		"forced_location": "head",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "Swollen brain leaves the victim barely conscious.",
	},
	"internal_bleeding": {
		"display_name": "Internal Bleeding",
		"category": "wound",
		"severity": "severe",
		"forced_location": "torso",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "Blood pools internally. Without surgery, death approaches.",
	},
	"death_rot": {
		"display_name": "Death Rot",
		"category": "disease",
		"severity": "severe",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 7,
		"description": "Necromantic corruption is consuming the body.",
	},
	"bone_fever": {
		"display_name": "Bone Fever",
		"category": "disease",
		"severity": "severe",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 6,
		"description": "The chill has broken into a raging fever. Bones feel like glass.",
	},

	# ── New physical wounds ───────────────────────────────────────────────────
	"barbed_wound": {
		"display_name": "Barbed Wound",
		"category": "wound",
		"severity": "light",
		"forced_location": "",
		"escalates_to": "infected_wound",
		"escalation_rests": 2,
		"cure_medicine_level": 2,
		"description": "An arrow or thorn lodged partway — worse to remove quickly than to leave.",
	},
	"sprain": {
		"display_name": "Sprain",
		"category": "wound",
		"severity": "light",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 1,
		"description": "A twisted joint — painful but not dangerous. Movement is compromised.",
	},
	"burn": {
		"display_name": "Burn",
		"category": "wound",
		"severity": "moderate",
		"forced_location": "",
		"escalates_to": "infected_wound",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "Seared skin and scorched tissue — agonising on contact with anything, including armor.",
	},

	# ── New diseases ──────────────────────────────────────────────────────────
	"poisoned_blood": {
		"display_name": "Poisoned Blood",
		"category": "disease",
		"severity": "moderate",
		"forced_location": "",
		"escalates_to": "venom_shock",
		"escalation_rests": 3,
		"cure_medicine_level": 3,
		"description": "A toxin is working through the bloodstream. Strength drains first, then clarity.",
	},
	"psychic_miasma": {
		"display_name": "Psychic Miasma",
		"category": "disease",
		"severity": "moderate",
		"forced_location": "",
		"escalates_to": "spiritual_corruption",
		"escalation_rests": 4,
		"cure_medicine_level": 7,
		"spiritual_cure": {"skill": "ritual", "level": 3},
		"description": "Hell energies have taken root in the subtle channels. Medicine barely reaches this.",
	},

	# ── New escalated forms ───────────────────────────────────────────────────
	"venom_shock": {
		"display_name": "Mortification",  # placeholder — confirm display name
		"category": "disease",
		"severity": "severe",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 7,
		"description": "The poison has reached crisis — organs strain, consciousness flickers.",
	},
	"spiritual_corruption": {
		"display_name": "Spiritual Corruption",
		"category": "disease",
		"severity": "severe",
		"forced_location": "",
		"escalates_to": "",
		"escalation_rests": 0,
		"cure_medicine_level": 8,
		"spiritual_cure": {"skill": "ritual", "level": 5},
		"description": "The subtle body is coming apart. Only deep practice can reverse this.",
	},
}

# Random wound pool for combat crits (base wounds only)
const CRIT_WOUND_POOL: Array[String] = ["deep_cut", "concussion", "broken_rib"]

# Random wound pool for ranged weapon crits
const RANGED_CRIT_WOUND_POOL: Array[String] = ["barbed_wound", "deep_cut", "concussion"]

# Random disease pool for undead/diseased enemy hits
const DISEASE_POOL: Array[String] = ["rot_sickness", "marrow_chill"]

# Random disease pool for poison-type enemy hits
const POISON_DISEASE_POOL: Array[String] = ["poisoned_blood"]


# ── Public API ───────────────────────────────────────────────────────────────

## Apply a wound/disease to a character. Returns false if already has this wound.
## body_location: specific part id; if "" uses forced_location from wound type,
## then falls back to BodySystem.assign_random_wound_location().
func apply_wound(character: Dictionary, wound_id: String, body_location: String = "", source: String = "") -> bool:
	if not wound_id in WOUND_TYPES:
		push_warning("WoundSystem: unknown wound '%s'" % wound_id)
		return false
	_ensure_wounds_field(character)
	for existing in character.wounds:
		if existing.get("id") == wound_id:
			return false
	# Resolve location: explicit → forced_location on wound type → random
	var location := body_location
	if location == "":
		location = WOUND_TYPES[wound_id].get("forced_location", "")
	if location == "" and BodySystem:
		location = BodySystem.assign_random_wound_location(character)
	character.wounds.append({
		"id": wound_id,
		"body_location": location,
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


## Apply a random wound appropriate to a melee crit hit.
func apply_random_crit_wound(character: Dictionary) -> String:
	var id: String = CRIT_WOUND_POOL[randi() % CRIT_WOUND_POOL.size()]
	apply_wound(character, id, "", "combat_crit")
	return id


## Apply a random wound appropriate to a ranged weapon crit hit.
func apply_random_ranged_crit_wound(character: Dictionary) -> String:
	var id: String = RANGED_CRIT_WOUND_POOL[randi() % RANGED_CRIT_WOUND_POOL.size()]
	apply_wound(character, id, "", "ranged_crit")
	return id


## Apply a random disease appropriate to an undead/diseased attacker.
func apply_random_disease(character: Dictionary, attacker_tag: String = "undead") -> String:
	if _resisted(character, "disease"):
		return ""
	var id: String = DISEASE_POOL[randi() % DISEASE_POOL.size()]
	apply_wound(character, id, "", attacker_tag)
	return id


## Apply a random disease appropriate to a poison-type attacker.
func apply_random_poison_disease(character: Dictionary) -> String:
	if _resisted(character, "poison"):
		return ""
	var id: String = POISON_DISEASE_POOL[randi() % POISON_DISEASE_POOL.size()]
	apply_wound(character, id, "", "poison")
	return id


## Roll a character's resistance against being afflicted at all.
##
## Diseases are not damage, so a "disease: 50" resistance cannot be applied as a
## damage reduction — it has to be a chance to shrug the affliction off. Sitting
## here rather than at the combat call site means every source is covered:
## enemy attacks, event outcomes, and anything added later.
##
## The same resistance value still reduces damage of that type through
## derived.resistances, so venom_ward both blunts poison damage and halves the
## chance of catching something from a poisoned blade.
func _resisted(character: Dictionary, resist_type: String) -> bool:
	if not TraitSystem:
		return false
	var pct: float = float(TraitSystem.get_resistances(character).get(resist_type, 0))
	if pct <= 0.0:
		return false
	return randf() < clampf(pct / 100.0, 0.0, 0.95)


## Cure one wound by id. Returns true if the wound was found and removed.
## Pass _update_stats=false when calling from a loop to batch the stat recalc.
func cure_wound(character: Dictionary, wound_id: String, _update_stats: bool = true) -> bool:
	_ensure_wounds_field(character)
	for i in range(character.wounds.size()):
		if character.wounds[i].get("id") == wound_id:
			character.wounds.remove_at(i)
			# A severe wound that closes leaves the Scarred trait behind. The
			# wound is gone; what it did to them is not.
			if TraitSystem and WOUND_TYPES.get(wound_id, {}).get("severity", "") == "severe":
				TraitSystem.grant_trait(character, "scarred")
			if _update_stats and CharacterSystem:
				CharacterSystem.update_derived_stats(character)
			return true
	return false


## Field Surgery: a Medicine-skilled character treats the whole party.
## Returns a dict: {"cured": [names], "messages": [strings]}
## Pass override_all=true (from the wound_specialist perk) to bypass per-wound medicine level gates.
func cure_wounds_field_surgery(performer: Dictionary, party: Array, override_all: bool = false) -> Dictionary:
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
			if override_all or medicine >= wdef.get("cure_medicine_level", 99):
				to_remove.append(wid)
		for wid in to_remove:
			cure_wound(char, wid, false)  # skip per-cure stat recalc; do once below
			var wdef = WOUND_TYPES.get(wid, {})
			cured_names.append(char.get("name", "?"))
			messages.append("%s's %s treated." % [char.get("name", "?"), wdef.get("display_name", wid)])
		if not to_remove.is_empty() and CharacterSystem:
			CharacterSystem.update_derived_stats(char)
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
## Penalties are ADDITIVE across wounds (two arm wounds sum their percentages before the
## single multiplicative application). This is intentional — chained multiplication would
## be too punishing early when wound accumulation is still rare.
## Each wound's penalties are derived from its body_location's part category
## and the wound type's severity, via BodySystem.WOUND_PENALTIES.
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
		var location: String = entry.get("body_location", "torso")
		var part_cat: String = BodySystem.get_part_category(character, location) if BodySystem else "torso"
		var severity: String = wdef.get("severity", "light")
		var penalties: Dictionary = BodySystem.get_wound_penalties(part_cat, severity) if BodySystem else {}
		for stat in penalties:
			totals[stat] = totals.get(stat, 0) + penalties[stat]
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


## Cure wounds/diseases that require a spiritual skill (Ritual or Yoga) rather than medicine.
## Checks each wound's "spiritual_cure" field: {skill: "ritual", level: 3}.
## Returns {"cured": [display_names], "messages": [strings]}.
func try_spiritual_cure(character: Dictionary, skill_used: String, skill_level: int) -> Dictionary:
	_ensure_wounds_field(character)
	var to_remove: Array[String] = []
	var messages: Array[String] = []
	for entry in character.wounds:
		var wid: String = entry.get("id", "")
		var wdef: Dictionary = WOUND_TYPES.get(wid, {})
		if wdef.is_empty():
			continue
		var sc: Dictionary = wdef.get("spiritual_cure", {})
		if sc.is_empty():
			continue
		if skill_used == sc.get("skill", "") and skill_level >= sc.get("level", 99):
			to_remove.append(wid)
	for wid in to_remove:
		cure_wound(character, wid, false)
		messages.append("%s's %s has been purified." % [character.get("name", "?"), WOUND_TYPES[wid].get("display_name", wid)])
	if not to_remove.is_empty() and CharacterSystem:
		CharacterSystem.update_derived_stats(character)
	return {"cured": to_remove, "messages": messages}


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
		cure_wound(character, wid, false)  # skip per-cure stat recalc; do once below
		messages.append(WOUND_TYPES[wid].get("display_name", wid) + " healed.")
	# A well-equipped house of healing can also break a dependency — the one
	# acquired trait that a facility, rather than practice, is able to remove.
	if TraitSystem and medicine_equivalent >= 5:
		if TraitSystem.lose_trait(character, "addiction"):
			messages.append("The dependency was treated. It will not be easy, but it is broken.")
	if not to_remove.is_empty() and CharacterSystem:
		CharacterSystem.update_derived_stats(character)
	if messages.is_empty():
		messages.append("No treatable wounds found.")
	return {"messages": messages, "count": to_remove.size()}


# ── Internals ────────────────────────────────────────────────────────────────

func _ensure_wounds_field(character: Dictionary) -> void:
	if not "wounds" in character:
		character["wounds"] = []
