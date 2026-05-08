extends Node
## BodySystem — character body plan topology and equipment slot management
##
## Each species has a body plan (defined in BODY_PLANS) listing its parts.
## Parts drive: which equipment slots exist, where wounds land, and what
## stat penalties wounds produce (part category + wound severity).
##
## Characters store only runtime state (missing_parts, prosthetics) under
## character["body_plan"]. Old characters without that key default to "human".

# ── Wound penalty table: part category × severity → stat penalties (%) ───────
# Applied multiplicatively in update_derived_stats via WoundSystem.get_stat_penalties().
const WOUND_PENALTIES: Dictionary = {
	"head": {
		"light":    {"spellpower": -10, "initiative": -10},
		"moderate": {"spellpower": -20, "initiative": -15},
		"severe":   {"spellpower": -30, "initiative": -25, "max_hp": -15},
	},
	"face": {
		"light":    {"spellpower": -10, "initiative": -10},
		"moderate": {"spellpower": -20, "initiative": -15},
		"severe":   {"spellpower": -30, "initiative": -25, "max_hp": -10},
	},
	"torso": {
		"light":    {"max_hp": -10, "max_stamina": -10},
		"moderate": {"max_hp": -20, "max_stamina": -20},
		"severe":   {"max_hp": -35, "max_stamina": -25},
	},
	"back": {
		"light":    {"max_stamina": -10},
		"moderate": {"max_hp": -10, "max_stamina": -15},
		"severe":   {"max_hp": -20, "max_stamina": -25},
	},
	"arm": {
		"light":    {"dodge": -15, "max_stamina": -5},
		"moderate": {"dodge": -25, "max_stamina": -10},
		"severe":   {"dodge": -30, "max_stamina": -15, "max_hp": -10},
	},
	"wing": {
		"light":    {"movement": -10, "initiative": -10},
		"moderate": {"movement": -20, "initiative": -15},
		"severe":   {"movement": -35, "initiative": -25, "max_hp": -10},
	},
	"leg": {
		"light":    {"initiative": -10, "movement": -10},
		"moderate": {"initiative": -15, "dodge": -10},
		"severe":   {"initiative": -25, "dodge": -20, "max_hp": -10},
	},
	"foot": {
		"light":    {"movement": -15, "initiative": -5},
		"moderate": {"movement": -25, "initiative": -10},
		"severe":   {"movement": -30, "initiative": -20},
	},
}

# Stat penalties for missing body parts (permanent until regrown/prosthetic).
# Values are flat reductions (not %-based) applied in update_derived_stats.
const MISSING_PART_PENALTIES: Dictionary = {
	"arm":   {"damage": -2, "max_stamina": -5},
	"leg":   {"movement": -1, "dodge": -5},
	"foot":  {"movement": -1},
	"head":  {},   # head/torso loss = death; no partial penalty needed
	"torso": {},
}

# Surface-area weights for random wound location assignment (per part category).
# Multiple parts of the same category each get this weight independently.
const LOCATION_WEIGHTS: Dictionary = {
	"torso": 35,
	"arm":   15,
	"leg":   10,
	"head":  10,
	"back":  10,
	"wing":   8,
	"face":   5,
	"foot":   3,
}

# Accessory slots exist for all species regardless of body plan.
const ACCESSORY_SLOTS: Array[String] = [
	"face", "back", "ring1", "ring2", "amulet", "trinket1", "trinket2"
]

# ── Body plan definitions ─────────────────────────────────────────────────────
# equip_slot: the key in character.equipment this part controls ("" = wounds only, no gear)
# parent: part id this is attached to (for cascading sever)
# children: part ids that are lost when this part is severed

const BODY_PLANS: Dictionary = {

	"human": {
		"parts": [
			{"id": "head",   "category": "head",  "equip_slot": "head",   "parent": "torso",  "children": []},
			{"id": "torso",  "category": "torso", "equip_slot": "chest",  "parent": "",       "children": ["head", "arm_l", "arm_r", "leg_l", "leg_r"]},
			{"id": "arm_l",  "category": "arm",   "equip_slot": "hand_l", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r",  "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "leg_l",  "category": "leg",   "equip_slot": "legs",   "parent": "torso",  "children": ["foot_l"]},
			{"id": "leg_r",  "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["foot_r"]},
			{"id": "foot_l", "category": "foot",  "equip_slot": "feet",   "parent": "leg_l",  "children": []},
			{"id": "foot_r", "category": "foot",  "equip_slot": "",       "parent": "leg_r",  "children": []},
		]
	},

	"four_armed": {
		"parts": [
			{"id": "head",    "category": "head",  "equip_slot": "head",    "parent": "torso",  "children": []},
			{"id": "torso",   "category": "torso", "equip_slot": "chest",   "parent": "",       "children": ["head", "arm_l", "arm_r", "arm_l2", "arm_r2", "leg_l", "leg_r"]},
			{"id": "arm_l",   "category": "arm",   "equip_slot": "hand_l",  "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r",   "category": "arm",   "equip_slot": "hand_r",  "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_l2",  "category": "arm",   "equip_slot": "hand_l2", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r2",  "category": "arm",   "equip_slot": "hand_r2", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "leg_l",   "category": "leg",   "equip_slot": "legs",    "parent": "torso",  "children": ["foot_l"]},
			{"id": "leg_r",   "category": "leg",   "equip_slot": "",        "parent": "torso",  "children": ["foot_r"]},
			{"id": "foot_l",  "category": "foot",  "equip_slot": "feet",    "parent": "leg_l",  "children": []},
			{"id": "foot_r",  "category": "foot",  "equip_slot": "",        "parent": "leg_r",  "children": []},
		]
	},

	# Naga / serpent form — arms present, no legs, tail replaces lower body
	"serpentine": {
		"parts": [
			{"id": "head",  "category": "head",  "equip_slot": "head",   "parent": "torso", "children": []},
			{"id": "torso", "category": "torso", "equip_slot": "chest",  "parent": "",      "children": ["head", "arm_l", "arm_r", "tail"]},
			{"id": "arm_l", "category": "arm",   "equip_slot": "hand_l", "parent": "torso", "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r", "category": "arm",   "equip_slot": "hand_r", "parent": "torso", "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			# Tail: valid wound location, no equip slot, counts as leg category for penalties
			{"id": "tail",  "category": "leg",   "equip_slot": "",       "parent": "torso", "children": []},
		]
	},

	# Snow lion — big cat; locked claws on arms, locked bite on head (no helmet slot)
	"snow_lion": {
		"parts": [
			{"id": "head",   "category": "head",  "equip_slot": "head",   "parent": "torso",  "children": [],
				"natural_weapon": {"locked": true, "name": "Bite", "damage_min": 3, "damage_max": 8, "damage_type": "piercing", "skill_tag": "unarmed"}},
			{"id": "torso",  "category": "torso", "equip_slot": "chest",  "parent": "",       "children": ["head", "arm_l", "arm_r", "leg_l", "leg_r"]},
			{"id": "arm_l",  "category": "arm",   "equip_slot": "hand_l", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": true, "name": "Claw", "damage_min": 2, "damage_max": 6, "damage_type": "slashing", "skill_tag": "unarmed"}},
			{"id": "arm_r",  "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": true, "name": "Claw", "damage_min": 2, "damage_max": 6, "damage_type": "slashing", "skill_tag": "unarmed"}},
			{"id": "leg_l",  "category": "leg",   "equip_slot": "legs",   "parent": "torso",  "children": ["foot_l"]},
			{"id": "leg_r",  "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["foot_r"]},
			{"id": "foot_l", "category": "foot",  "equip_slot": "feet",   "parent": "leg_l",  "children": []},
			{"id": "foot_r", "category": "foot",  "equip_slot": "",       "parent": "leg_r",  "children": []},
		]
	},

	# Mantis — raptorial forelegs are locked blades (no weapons equippable);
	# 4 walking legs give +1 movement, +5 dodge via get_extra_leg_pairs()
	"mantis": {
		"parts": [
			{"id": "head",   "category": "head",  "equip_slot": "head",   "parent": "torso",  "children": []},
			{"id": "torso",  "category": "torso", "equip_slot": "chest",  "parent": "",       "children": ["head", "arm_l", "arm_r", "leg_l", "leg_r", "leg_l2", "leg_r2"]},
			# Raptorial forelegs: locked blades — can wear bracers but cannot equip weapons.
			# skill_tags picks the better of unarmed or swords for attack rolls.
			{"id": "arm_l",  "category": "arm",   "equip_slot": "hand_l", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": true, "name": "Mantis Blade", "damage_min": 5, "damage_max": 11, "damage_type": "slashing", "skill_tags": ["unarmed", "swords"], "crit_bonus": 10}},
			{"id": "arm_r",  "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": true, "name": "Mantis Blade", "damage_min": 5, "damage_max": 11, "damage_type": "slashing", "skill_tags": ["unarmed", "swords"], "crit_bonus": 10}},
			# Four walking legs — extra pair gives movement/dodge bonus
			{"id": "leg_l",  "category": "leg",   "equip_slot": "legs",   "parent": "torso",  "children": ["foot_l"]},
			{"id": "leg_r",  "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["foot_r"]},
			{"id": "leg_l2", "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": []},
			{"id": "leg_r2", "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": []},
			{"id": "foot_l", "category": "foot",  "equip_slot": "feet",   "parent": "leg_l",  "children": []},
			{"id": "foot_r", "category": "foot",  "equip_slot": "",       "parent": "leg_r",  "children": []},
		]
	},

	# Avian — garuda/tengu form: proper arms (can wield weapons), wings on back,
	# locked beak on face slot, locked talons on feet.
	"avian": {
		"parts": [
			{"id": "head",    "category": "head",  "equip_slot": "head",   "parent": "torso",  "children": ["face"]},
			# Beak on face slot — locked, no helmet displaced; head slot free for hoods/crowns
			{"id": "face",    "category": "face",  "equip_slot": "face",   "parent": "head",   "children": [],
				"natural_weapon": {"locked": true, "name": "Beak", "damage_min": 1, "damage_max": 5, "damage_type": "piercing", "skill_tag": "unarmed"}},
			{"id": "torso",   "category": "torso", "equip_slot": "chest",  "parent": "",       "children": ["head", "back", "arm_l", "arm_r", "leg_l", "leg_r"]},
			# Wings: back-mounted, wound category "wing"; locked slot (not a weapon, just flight)
			{"id": "back",    "category": "wing",  "equip_slot": "back",   "parent": "torso",  "children": [], "locked": true},
			# Arms: birds have proper arms (garuda/tengu style) — can equip weapons
			{"id": "arm_l",   "category": "arm",   "equip_slot": "hand_l", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r",   "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_min": 1, "damage_max": 3, "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "leg_l",   "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["talon_l"]},
			{"id": "leg_r",   "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["talon_r"]},
			# Talons: locked natural weapons; no boot slot (feet are talons)
			{"id": "talon_l", "category": "foot",  "equip_slot": "",       "parent": "leg_l",  "children": [],
				"natural_weapon": {"locked": true, "name": "Talon", "damage_min": 2, "damage_max": 5, "damage_type": "slashing", "skill_tag": "unarmed"}},
			{"id": "talon_r", "category": "foot",  "equip_slot": "",       "parent": "leg_r",  "children": [],
				"natural_weapon": {"locked": true, "name": "Talon", "damage_min": 2, "damage_max": 5, "damage_type": "slashing", "skill_tag": "unarmed"}},
		]
	},
}


# ── Public API ────────────────────────────────────────────────────────────────

## Resolved body plan definition for a character. Defaults to "human".
func get_body_plan_def(character: Dictionary) -> Dictionary:
	var species: String = character.get("body_plan", {}).get("species", "human")
	return BODY_PLANS.get(species, BODY_PLANS["human"])


## All active equipment slots for this character.
## Excludes slots on missing parts. Always includes ACCESSORY_SLOTS.
## Does NOT include weapon_set_1/2 — those are handled separately by ItemSystem.
func get_equipment_slots(character: Dictionary) -> Array[String]:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	var slots: Array[String] = []
	for part in plan.parts:
		var s: String = part.get("equip_slot", "")
		if s == "" or part.id in missing:
			continue
		slots.append(s)
	# Add universal accessory slots, skipping any already provided by the body plan
	# (avian back/face slots come from the body plan; humans get them from here)
	for s in ACCESSORY_SLOTS:
		if not s in slots:
			slots.append(s)
	return slots


## All arm equip slots for this character (used by _find_slot_for_item and UI).
func get_arm_slots(character: Dictionary) -> Array[String]:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	var slots: Array[String] = []
	for part in plan.parts:
		if part.get("category") == "arm" and not part.id in missing:
			var s: String = part.get("equip_slot", "")
			if s != "":
				slots.append(s)
	return slots


## The category of a body part by its id. Returns "torso" as a safe fallback.
func get_part_category(character: Dictionary, part_id: String) -> String:
	var plan := get_body_plan_def(character)
	for part in plan.parts:
		if part.id == part_id:
			return part.get("category", "torso")
	return "torso"


## Wound penalty dict for a given part category and wound severity.
func get_wound_penalties(part_category: String, severity: String) -> Dictionary:
	var table: Dictionary = WOUND_PENALTIES.get(part_category, WOUND_PENALTIES["torso"])
	return table.get(severity, {}).duplicate()


## Flat stat penalties from all missing body parts. Called by update_derived_stats.
## Returns a dict of stat → total reduction (additive, not percentage).
func get_missing_part_penalties(character: Dictionary) -> Dictionary:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	var totals: Dictionary = {}
	for part in plan.parts:
		if not part.id in missing:
			continue
		var cat: String = part.get("category", "")
		for stat in MISSING_PART_PENALTIES.get(cat, {}):
			totals[stat] = totals.get(stat, 0) + MISSING_PART_PENALTIES[cat][stat]
	return totals


## Reverse lookup: which part owns a given equip slot.
func get_part_for_slot(character: Dictionary, slot_id: String) -> Dictionary:
	var plan := get_body_plan_def(character)
	for part in plan.parts:
		if part.get("equip_slot", "") == slot_id:
			return part
	return {}


## Pick a random body part weighted by surface area. Excludes missing parts.
## Used when a wound arrives without an explicit body_location.
func assign_random_wound_location(character: Dictionary) -> String:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])

	var pool: Array[Dictionary] = []
	var total_weight := 0
	for part in plan.parts:
		if part.id in missing:
			continue
		var w: int = LOCATION_WEIGHTS.get(part.get("category", ""), 0)
		if w == 0:
			continue
		pool.append({"id": part.id, "weight": w})
		total_weight += w

	if pool.is_empty():
		return "torso"

	var roll := randi() % total_weight
	var cum := 0
	for entry in pool:
		cum += entry.weight
		if roll < cum:
			return entry.id
	return pool[-1].id


## True if this character's species has any arm slots beyond the standard two.
func is_multi_armed(character: Dictionary) -> bool:
	return get_arm_slots(character).size() > 2


## Natural weapon data for the part that owns the given equip slot. Returns {} if none.
func get_natural_weapon(character: Dictionary, slot_id: String) -> Dictionary:
	var plan := get_body_plan_def(character)
	for part in plan.parts:
		if part.get("equip_slot", "") == slot_id:
			return part.get("natural_weapon", {}).duplicate()
	return {}


## True if the part owning slot_id is locked (cannot equip items).
## Checks natural_weapon.locked first; falls back to part-level "locked" flag
## (used for wing/back slots that block items but have no natural weapon).
func is_slot_locked(character: Dictionary, slot_id: String) -> bool:
	if get_natural_weapon(character, slot_id).get("locked", false):
		return true
	var plan := get_body_plan_def(character)
	for part in plan.parts:
		if part.get("equip_slot", "") == slot_id:
			return part.get("locked", false)
	return false


## Natural weapon from the first available arm. Falls back to head/tail if all arms are gone.
## Used as unarmed fallback in combat when no weapon is equipped.
func get_dominant_natural_weapon(character: Dictionary) -> Dictionary:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	# Primary: first available arm-category part
	for part in plan.parts:
		if part.get("category") != "arm":
			continue
		if part.id in missing:
			continue
		var nw: Dictionary = part.get("natural_weapon", {})
		if not nw.is_empty():
			return nw.duplicate()
	# Fallback: head/face/tail natural weapons when all arms are severed
	for part in plan.parts:
		if not part.get("category") in ["head", "face", "leg"]:
			continue
		if part.id in missing:
			continue
		var nw: Dictionary = part.get("natural_weapon", {})
		if not nw.is_empty() and nw.get("locked", false):
			return nw.duplicate()
	return {}


## Severs a body part and all its descendants.
## Unequips items from affected slots. Returns the list of severed part ids.
func sever_part(character: Dictionary, part_id: String) -> Array[String]:
	var plan := get_body_plan_def(character)
	if not "body_plan" in character:
		character["body_plan"] = {"species": "human", "missing_parts": [], "prosthetics": {}}
	var bp: Dictionary = character["body_plan"]
	if not "missing_parts" in bp:
		bp["missing_parts"] = []

	var to_sever: Array[String] = _collect_parts_to_sever(plan, part_id)
	for pid in to_sever:
		if not pid in bp["missing_parts"]:
			bp["missing_parts"].append(pid)
		for part in plan.parts:
			if part.id == pid:
				var slot: String = part.get("equip_slot", "")
				if slot != "" and ItemSystem:
					# If inventory is full, unequip_item returns false and warns.
					# Force-clear the slot anyway so the item isn't stuck in limbo.
					if not ItemSystem.unequip_item(character, slot):
						character.get("equipment", {})[slot] = ""
				# Arms also unequip their corresponding weapon slot.
				# Convention: arm_r = main hand (weapon_main), arm_l = off-hand (weapon_off).
				if part.get("category") == "arm" and ItemSystem:
					match pid:
						"arm_r":
							if not ItemSystem.unequip_item(character, "weapon_main"):
								character.get("equipment", {})["weapon_main"] = ""
						"arm_l":
							if not ItemSystem.unequip_item(character, "weapon_off"):
								character.get("equipment", {})["weapon_off"] = ""
				break

	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
	return to_sever


## Restores a severed part and all its descendants (removes the whole subtree from missing_parts).
func regrow_part(character: Dictionary, part_id: String) -> void:
	var plan := get_body_plan_def(character)
	var bp: Dictionary = character.get("body_plan", {})
	if not "missing_parts" in bp:
		return
	var to_restore: Array[String] = _collect_parts_to_sever(plan, part_id)
	for pid in to_restore:
		bp["missing_parts"].erase(pid)
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)


# Recursive helper — collects part_id and all parts in its children arrays.
func _collect_parts_to_sever(plan: Dictionary, part_id: String) -> Array[String]:
	var result: Array[String] = [part_id]
	for part in plan.parts:
		if part.id == part_id:
			for child_id in part.get("children", []):
				result.append_array(_collect_parts_to_sever(plan, child_id))
			break
	return result


## Count of all non-missing arm-category parts (includes armless wings, etc.).
## Used by the multi-arm attack chain to determine how many arm attacks to attempt.
func get_attack_arm_count(character: Dictionary) -> int:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	var count := 0
	for part in plan.parts:
		if part.get("category") == "arm" and not part.id in missing:
			count += 1
	return count


## Extra leg pairs beyond the first, accounting for missing legs.
## Humans/serpentines return 0. A 6-legged creature returns 2.
func get_extra_leg_pairs(character: Dictionary) -> int:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	var leg_count := 0
	for part in plan.parts:
		if part.get("category") == "leg" and not part.id in missing:
			leg_count += 1
	return maxi(0, leg_count / 2 - 1)


## Probability (0–100) that arm arm_number fires during a multi-arm attack chain.
## arm_number 1 = primary arm (always 100%); 2–6 use the Finesse probability formula.
## Formula: chance[n] = base[n] + (Finesse - 10) * scale[n], clamped 0–100%.
func get_arm_attack_chance(finesse: int, arm_number: int) -> float:
	if arm_number <= 1:
		return 100.0
	var bases:  Array[float] = [50.0, 25.0, 10.0,  5.0, 0.0]
	var scales: Array[float] = [ 5.0,  4.0,  3.0,  2.0, 2.0]
	var i: int = mini(arm_number - 2, bases.size() - 1)
	return clampf(bases[i] + float(finesse - 10) * scales[i], 0.0, 100.0)
