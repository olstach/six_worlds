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
	"torso": {
		"light":    {"max_hp": -10, "max_stamina": -10},
		"moderate": {"max_hp": -20, "max_stamina": -20},
		"severe":   {"max_hp": -35, "max_stamina": -25},
	},
	"arm": {
		"light":    {"dodge": -15, "max_stamina": -5},
		"moderate": {"dodge": -25, "max_stamina": -10},
		"severe":   {"dodge": -30, "max_stamina": -15, "max_hp": -10},
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

# Surface-area weights for random wound location assignment (per part category).
# Multiple parts of the same category each get this weight independently.
const LOCATION_WEIGHTS: Dictionary = {
	"torso": 35,
	"arm":   15,
	"leg":   10,
	"head":  10,
	"foot":  3,
}

# Accessory slots exist for all species regardless of body plan.
const ACCESSORY_SLOTS: Array[String] = [
	"ring1", "ring2", "amulet", "trinket1", "trinket2"
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
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r",  "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
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
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r",   "category": "arm",   "equip_slot": "hand_r",  "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_l2",  "category": "arm",   "equip_slot": "hand_l2", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r2",  "category": "arm",   "equip_slot": "hand_r2", "parent": "torso",  "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
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
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			{"id": "arm_r", "category": "arm",   "equip_slot": "hand_r", "parent": "torso", "children": [],
				"natural_weapon": {"locked": false, "name": "Fist", "damage_dice": "1d3", "damage_type": "crushing", "skill_tag": "unarmed"}},
			# Tail: valid wound location, no equip slot, counts as leg category for penalties
			{"id": "tail",  "category": "leg",   "equip_slot": "",       "parent": "torso", "children": []},
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
	slots.append_array(ACCESSORY_SLOTS)
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


## True if the part owning slot_id has a locked natural weapon (cannot equip items over it).
func is_slot_locked(character: Dictionary, slot_id: String) -> bool:
	return get_natural_weapon(character, slot_id).get("locked", false)


## Natural weapon from the first available (non-missing) arm. Used as unarmed fallback in combat.
func get_dominant_natural_weapon(character: Dictionary) -> Dictionary:
	var plan := get_body_plan_def(character)
	var missing: Array = character.get("body_plan", {}).get("missing_parts", [])
	for part in plan.parts:
		if part.get("category") != "arm":
			continue
		if part.id in missing:
			continue
		var nw: Dictionary = part.get("natural_weapon", {})
		if not nw.is_empty():
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
					ItemSystem.unequip_item(character, slot)
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
