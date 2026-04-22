extends Node

## CampSystem — activity registry and execution for the camp rest system.
## Activities are available based on party skills. Camp rest gets 1 slot, Full Rest 2.
## Logistics perks can add +1 slot (future).

const WEAPON_SKILLS: Array[String] = [
	"swords", "axes", "maces", "spears", "daggers", "unarmed", "ranged"
]

## All camp activity definitions.
## skill_req: Dictionary — all entries must be met; checked as best-in-party per skill.
## skill_req_any: Array[Dictionary] — OR list; any one dict fully met by party = available.
## skill_req_any_weapon: int — available if any party member has any weapon skill >= this.
## min_tier: minimum rest tier (1=quick, 2=camp, 3=full). Quick has 0 slots so never shows.
## costs: Dictionary {resource: amount} — consumed on execute beyond base rest costs.
## stub: bool — show in list but greyed out; depends on a future system.
const ACTIVITIES: Array = [
	# ─── SPIRITUAL ───────────────────────────────────────────────────
	{
		"id": "sadhana",
		"name": "Sadhana",
		"category": "Spiritual",
		"skill_req": {"yoga": 3},
		"min_tier": 3,
		"costs": {},
		"description": "Karma purification practice — auto-picks best available ritual tier",
		"effect_desc": "~20–100 karma purified; Yoga 5+ gets quirk purge chance",
	},
	{
		"id": "mantra_recitation",
		"name": "Mantra Recitation",
		"category": "Spiritual",
		"skill_req": {"yoga": 2},
		"min_tier": 2,
		"costs": {},
		"description": "Quiet mantra accumulation toward yidam relationship",
		"effect_desc": "Relationship progress (Yidam system — future)",
		"stub": true,
	},
	# ─── MEDICAL ─────────────────────────────────────────────────────
	{
		"id": "herb_preparation",
		"name": "Herb Preparation",
		"category": "Medical",
		"skill_req": {"medicine": 2},
		"min_tier": 2,
		"costs": {},
		"description": "Process raw herbs into more efficient healing forms",
		"effect_desc": "+15% HP restore bonus on next rest",
	},
	{
		"id": "field_surgery",
		"name": "Field Surgery",
		"category": "Medical",
		"skill_req": {"medicine": 4},
		"min_tier": 2,
		"costs": {"herbs": 2},
		"description": "Treat bleeds, infections, wounds, and diseases",
		"effect_desc": "Cure persistent wounds/diseases (disease system — future)",
		"stub": true,
	},
	# ─── ALCHEMY ─────────────────────────────────────────────────────
	{
		"id": "brew_potions",
		"name": "Brew Potions",
		"category": "Alchemy",
		"skill_req": {"alchemy": 3},
		"min_tier": 2,
		"costs": {"reagents": 2},
		"description": "Convert reagents into healing potions at camp",
		"effect_desc": "Gain 1–3 potions (health/mana) based on Alchemy level",
	},
	{
		"id": "brew_combat",
		"name": "Brew Bombs & Poisons",
		"category": "Alchemy",
		"skill_req": {"alchemy": 4},
		"min_tier": 2,
		"costs": {"reagents": 3},
		"description": "Craft combat consumables from reagents",
		"effect_desc": "Gain 1–2 fire bombs, poison bombs, or acid bombs",
	},
	# ─── MAINTENANCE ─────────────────────────────────────────────────
	{
		"id": "deep_repair",
		"name": "Deep Repair",
		"category": "Maintenance",
		"skill_req": {"smithing": 2},
		"min_tier": 2,
		"costs": {"scrap": 3},
		"description": "Full durability restore on all party equipment",
		"effect_desc": "All equipped items restored to 100% durability",
	},
	{
		"id": "weapon_work",
		"name": "Weapon Work",
		"category": "Maintenance",
		"skill_req": {"smithing": 4},
		"min_tier": 2,
		"costs": {"scrap": 2},
		"description": "Fine-tune weapons for the coming fight",
		"effect_desc": "+4 accuracy for the party next combat",
	},
	# ─── SOCIAL ──────────────────────────────────────────────────────
	{
		"id": "campfire_story",
		"name": "Campfire Story",
		"category": "Social",
		"skill_req_any": [{"performance": 3}, {"comedy": 3}],
		"min_tier": 2,
		"costs": {},
		"description": "Stories and laughter ease the party's burdens",
		"effect_desc": "Party-wide −30 emotional pressure (all elements)",
	},
	{
		"id": "encouraging_words",
		"name": "Encouraging Words",
		"category": "Social",
		"skill_req": {"leadership": 3},
		"min_tier": 2,
		"costs": {},
		"description": "Rally the party for what lies ahead",
		"effect_desc": "+2 Initiative and Finesse for all — next combat",
	},
	# ─── INTELLIGENCE / SURVIVAL ─────────────────────────────────────
	{
		"id": "study",
		"name": "Study Recent Events",
		"category": "Learning",
		"skill_req": {"learning": 2},
		"min_tier": 2,
		"costs": {},
		"description": "Reflect on recent encounters to extract lessons",
		"effect_desc": "Performer gains XP based on Learning level",
	},
	{
		"id": "forage",
		"name": "Forage",
		"category": "Survival",
		"skill_req": {"logistics": 2},
		"min_tier": 2,
		"costs": {},
		"description": "Gather herbs and food from the surrounding terrain",
		"effect_desc": "Gain herbs + food based on Logistics level",
	},
	{
		"id": "scout",
		"name": "Scout Surroundings",
		"category": "Survival",
		"skill_req": {"logistics": 3},
		"min_tier": 2,
		"costs": {},
		"description": "Secure the perimeter before settling in",
		"effect_desc": "No disturbance this rest; reveal nearby tiles",
	},
	# ─── COMBAT PREP ─────────────────────────────────────────────────
	{
		"id": "sharpen",
		"name": "Sharpen Weapons",
		"category": "Combat Prep",
		"skill_req_any_weapon": 3,
		"min_tier": 2,
		"costs": {},
		"description": "Hone edges and re-wrap grips",
		"effect_desc": "+4 accuracy next combat (party-wide)",
	},
	{
		"id": "spar",
		"name": "Spar",
		"category": "Combat Prep",
		"skill_req_any_weapon": 4,
		"min_tier": 2,
		"costs": {},
		"description": "Light sparring session to keep reflexes sharp",
		"effect_desc": "Performer gains 8 XP",
	},
]


## Returns activities available to this party for the given rest tier.
## Each result dict gets a "performer" key set to the best party member for it.
func get_available_activities(party: Array, rest_tier: int, _is_safe_camp: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for activity in ACTIVITIES:
		if activity.get("min_tier", 1) > rest_tier:
			continue
		if not _party_meets_req(party, activity):
			continue
		var out: Dictionary = activity.duplicate()
		out["performer"] = _best_performer(party, activity)
		out["can_afford"] = _can_afford_costs(activity.get("costs", {}))
		result.append(out)
	return result


## Returns true if the party can currently pay the extra activity costs.
func _can_afford_costs(costs: Dictionary) -> bool:
	for resource in costs:
		var needed: int = costs[resource]
		match resource:
			"herbs":    if GameState.herbs    < needed: return false
			"reagents": if GameState.reagents < needed: return false
			"scrap":    if GameState.scrap    < needed: return false
			"food":     if GameState.food     < needed: return false
	return true


## Roll for disturbance at rest start. Returns true if rest is disturbed.
func roll_disturbance(rest_tier: int, realm: String, hour_of_day: int) -> bool:
	var base_chance: float = [0.10, 0.15, 0.20][clampi(rest_tier - 1, 0, 2)]
	if realm in ["hell", "hungry_ghost"]:
		base_chance += 0.15
	if hour_of_day >= 20 or hour_of_day < 5:
		base_chance += 0.10
	return randf() < base_chance


## Execute a selected activity. Consumes additional resources and applies effects.
## Returns {message: String, ok: bool}.
func execute_activity(activity_id: String, performer: Dictionary, party: Array) -> Dictionary:
	match activity_id:
		"sadhana":           return _exec_sadhana(performer, party)
		"herb_preparation":  return _exec_herb_preparation(performer)
		"brew_potions":      return _exec_brew_potions(performer)
		"brew_combat":       return _exec_brew_combat(performer)
		"deep_repair":       return _exec_deep_repair(party)
		"weapon_work":       return _exec_weapon_work(party)
		"campfire_story":    return _exec_campfire_story(performer, party)
		"encouraging_words": return _exec_encouraging_words(party)
		"study":             return _exec_study(performer)
		"forage":            return _exec_forage(performer, party)
		"scout":             return _exec_scout()
		"sharpen":           return _exec_sharpen(performer)
		"spar":              return _exec_spar(performer)
	return {"message": "Activity '%s' not implemented." % activity_id, "ok": false}


# ─── Requirement checking ────────────────────────────────────────────────────

func _party_meets_req(party: Array, activity: Dictionary) -> bool:
	if activity.has("skill_req"):
		for skill_id: String in activity.skill_req:
			var min_level: int = activity.skill_req[skill_id]
			var best := 0
			for char in party:
				best = maxi(best, CharacterSystem.get_effective_skill_level(char, skill_id))
			if best < min_level:
				return false
		return true
	if activity.has("skill_req_any"):
		for req_dict in activity.skill_req_any:
			var met := true
			for skill_id: String in req_dict:
				var min_level: int = req_dict[skill_id]
				var best := 0
				for char in party:
					best = maxi(best, CharacterSystem.get_effective_skill_level(char, skill_id))
				if best < min_level:
					met = false
					break
			if met:
				return true
		return false
	if activity.has("skill_req_any_weapon"):
		var threshold: int = activity.skill_req_any_weapon
		for char in party:
			for ws: String in WEAPON_SKILLS:
				if CharacterSystem.get_effective_skill_level(char, ws) >= threshold:
					return true
		return false
	return true


func _best_performer(party: Array, activity: Dictionary) -> Dictionary:
	if party.is_empty():
		return {}
	var best_char: Dictionary = party[0]
	var best_score := -1
	for char in party:
		var score := _performer_score(char, activity)
		if score > best_score:
			best_score = score
			best_char = char
	return best_char


func _performer_score(char: Dictionary, activity: Dictionary) -> int:
	if activity.has("skill_req"):
		var total := 0
		for skill_id: String in activity.skill_req:
			total += CharacterSystem.get_effective_skill_level(char, skill_id)
		return total
	if activity.has("skill_req_any"):
		var best := 0
		for req_dict in activity.skill_req_any:
			var total := 0
			for skill_id: String in req_dict:
				total += CharacterSystem.get_effective_skill_level(char, skill_id)
			best = maxi(best, total)
		return best
	if activity.has("skill_req_any_weapon"):
		var best := 0
		for ws: String in WEAPON_SKILLS:
			best = maxi(best, CharacterSystem.get_effective_skill_level(char, ws))
		return best
	return 0


# ─── Activity execution ──────────────────────────────────────────────────────

func _exec_sadhana(performer: Dictionary, party: Array) -> Dictionary:
	var yoga_level   := CharacterSystem.get_effective_skill_level(performer, "yoga")
	var ritual_level := CharacterSystem.get_effective_skill_level(performer, "ritual")

	# Pick best ritual tier the performer can afford right now
	# 0=yoga only, 1=smoke(+herbs), 2=torma(+reagents), 3=mandala(+reagents, Yoga5+)
	var ritual_tier := 0
	if ritual_level >= 2 and GameState.herbs >= 2:
		ritual_tier = 1
	if ritual_level >= 4 and GameState.reagents >= 2:
		ritual_tier = 2
	if ritual_level >= 6 and yoga_level >= 5 and GameState.reagents >= 3:
		ritual_tier = 3

	match ritual_tier:
		1: GameState.consume_supply("herbs",    2)
		2: GameState.consume_supply("reagents", 2)
		3: GameState.consume_supply("reagents", 3)

	# Karma purification — returns {success, total, realms}
	var purif_result: Dictionary = KarmaSystem.perform_purification(yoga_level, ritual_tier)
	var purified: int = purif_result.get("total", 0)

	# Pressure decay at 1.5× full-rest rate
	for char in party:
		PsychologySystem.decay_toward_baseline(char, 150.0)

	# Quirk purge: Yoga 5+ tries yoga-purgeable quirks on the best yoga char.
	# Mandala (tier 3) lowers purge difficulty by 2.
	var purge_msg := ""
	var diff_mod  := 2 if ritual_tier == 3 else 0
	if yoga_level >= 5:
		var target_char: Dictionary = _highest_skill_char(party, "yoga")
		if not target_char.is_empty():
			for quirk_id in target_char.get("quirks", []).duplicate():
				if QuirkSystem.try_purge(target_char, quirk_id, "yoga", diff_mod):
					var qname: String = QuirkSystem.get_quirk_name(quirk_id)
					purge_msg = " %s has shed the '%s' trait." % [target_char.get("name", "Performer"), qname]
					break
	# Ritual-only quirks (if no yoga purge happened): best ritual char
	if purge_msg.is_empty() and ritual_tier >= 1:
		var target_char: Dictionary = _highest_skill_char(party, "ritual")
		if not target_char.is_empty():
			for quirk_id in target_char.get("quirks", []).duplicate():
				var q := QuirkSystem.get_quirk(quirk_id)
				var purgeable: Array = q.get("purgeable_by", [])
				if "ritual" in purgeable and not "yoga" in purgeable:
					if QuirkSystem.try_purge(target_char, quirk_id, "ritual", diff_mod):
						var qname: String = QuirkSystem.get_quirk_name(quirk_id)
						purge_msg = " %s shed '%s' through ritual." % [target_char.get("name", "Performer"), qname]
						break

	var tier_names := ["Yoga Practice", "Smoke Offering", "Torma Offering", "Mandala Offering"]
	var success_str := "~%d karma purified" % purified if purif_result.get("success", false) else "practice faltered — no karma purified"
	var msg := "%s: %s. %s.%s" % [
		performer.get("name", "Performer"), tier_names[ritual_tier], success_str, purge_msg
	]
	return {"message": msg, "ok": true}


func _exec_herb_preparation(performer: Dictionary) -> Dictionary:
	GameState.set_flag("herb_prep_bonus", true)
	return {
		"message": "%s prepares the herbs carefully. Next rest heals +15%% more HP." % performer.get("name", "Performer"),
		"ok": true,
	}


func _exec_brew_potions(performer: Dictionary) -> Dictionary:
	if not GameState.consume_supply("reagents", 2):
		return {"message": "Not enough reagents to brew potions.", "ok": false}
	var alchemy := CharacterSystem.get_effective_skill_level(performer, "alchemy")
	var count := clampi(1 + alchemy / 3, 1, 3)
	var item_pool := ["health_potion", "greater_health_potion", "mana_potion"]
	var brewed: Array[String] = []
	for _i in range(count):
		var item_id: String = item_pool[randi() % item_pool.size()]
		ItemSystem.add_to_inventory(item_id, 1)
		brewed.append(ItemSystem.get_item(item_id).get("name", item_id))
	return {
		"message": "%s brews at camp: %s." % [performer.get("name", "Performer"), ", ".join(brewed)],
		"ok": true,
	}


func _exec_brew_combat(performer: Dictionary) -> Dictionary:
	if not GameState.consume_supply("reagents", 3):
		return {"message": "Not enough reagents to brew combat supplies.", "ok": false}
	var alchemy := CharacterSystem.get_effective_skill_level(performer, "alchemy")
	var count := 1 + int(alchemy >= 6)
	var item_pool := ["fire_bomb", "poison_bomb", "acid_bomb"]
	var brewed: Array[String] = []
	for _i in range(count):
		var item_id: String = item_pool[randi() % item_pool.size()]
		ItemSystem.add_to_inventory(item_id, 1)
		brewed.append(ItemSystem.get_item(item_id).get("name", item_id))
	return {
		"message": "%s brews combat supplies: %s." % [performer.get("name", "Performer"), ", ".join(brewed)],
		"ok": true,
	}


func _exec_deep_repair(party: Array) -> Dictionary:
	if not GameState.consume_supply("scrap", 3):
		return {"message": "Not enough scrap for deep repair.", "ok": false}
	var armor_slots: Array[String] = ["head", "chest", "hand_l", "hand_r", "legs", "feet"]
	for char in party:
		var equipment: Dictionary = char.get("equipment", {})
		for slot in armor_slots:
			var item_id: String = equipment.get(slot, "")
			if not item_id.is_empty():
				var item_data := ItemSystem.get_item(item_id)
				var max_dur: int = int(item_data.get("max_durability", 0))
				if max_dur > 0:
					ItemSystem.update_item_durability(item_id, max_dur)
		for set_key in ["weapon_set_1", "weapon_set_2"]:
			var ws: Dictionary = equipment.get(set_key, {})
			for sub in ["main", "off"]:
				var item_id: String = ws.get(sub, "")
				if not item_id.is_empty():
					var item_data := ItemSystem.get_item(item_id)
					var max_dur: int = int(item_data.get("max_durability", 0))
					if max_dur > 0:
						ItemSystem.update_item_durability(item_id, max_dur)
	return {"message": "All equipped items restored to full durability.", "ok": true}


func _exec_weapon_work(party: Array) -> Dictionary:
	if not GameState.consume_supply("scrap", 2):
		return {"message": "Not enough scrap for weapon work.", "ok": false}
	# One buff appended once — active_map_buffs applies globally to all characters.
	GameState.active_map_buffs.append({"stat": "accuracy", "amount": 4, "combats_remaining": 1})
	for char in party:
		CharacterSystem.update_derived_stats(char)
	return {"message": "Weapons honed. Party gains +4 accuracy next combat.", "ok": true}


func _exec_campfire_story(performer: Dictionary, party: Array) -> Dictionary:
	for char in party:
		PsychologySystem.decay_toward_baseline(char, 30.0)
	return {
		"message": "%s tells stories around the fire. Tension fades from the party." % performer.get("name", "Performer"),
		"ok": true,
	}


func _exec_encouraging_words(party: Array) -> Dictionary:
	# One buff entry each — active_map_buffs applies globally to all characters.
	GameState.active_map_buffs.append({"stat": "initiative", "amount": 2, "combats_remaining": 1})
	GameState.active_map_buffs.append({"stat": "finesse",    "amount": 2, "combats_remaining": 1})
	for char in party:
		CharacterSystem.update_derived_stats(char)
	return {"message": "The party rallies. +2 Initiative and Finesse next combat.", "ok": true}


func _exec_study(performer: Dictionary) -> Dictionary:
	var learning := CharacterSystem.get_effective_skill_level(performer, "learning")
	var xp_amount := 10 + learning * 5
	CharacterSystem.grant_xp(performer, xp_amount)
	return {
		"message": "%s reflects on recent events and gains %d XP." % [performer.get("name", "Performer"), xp_amount],
		"ok": true,
	}


func _exec_forage(performer: Dictionary, party: Array) -> Dictionary:
	var logistics := CharacterSystem.get_effective_skill_level(performer, "logistics")
	var herbs_found := 1 + logistics / 3
	var food_found  := party.size() + logistics
	GameState.add_supply("herbs", herbs_found)
	GameState.add_supply("food",  food_found)
	return {
		"message": "%s forages: +%d herbs, +%d food." % [performer.get("name", "Performer"), herbs_found, food_found],
		"ok": true,
	}


func _exec_scout() -> Dictionary:
	MapManager.reveal_area(MapManager.party_position, 4)
	return {"message": "Scout secures the perimeter. No disturbance this rest. Nearby area revealed.", "ok": true}


func _exec_sharpen(performer: Dictionary) -> Dictionary:
	GameState.active_map_buffs.append({"stat": "accuracy", "amount": 4, "combats_remaining": 1})
	CharacterSystem.update_derived_stats(performer)
	return {
		"message": "%s sharpens their weapons. +4 accuracy next combat." % performer.get("name", "Performer"),
		"ok": true,
	}


func _exec_spar(performer: Dictionary) -> Dictionary:
	CharacterSystem.grant_xp(performer, 8)
	return {"message": "%s spars in the firelight and gains 8 XP." % performer.get("name", "Performer"), "ok": true}


# ─── Helpers ─────────────────────────────────────────────────────────────────

func _highest_skill_char(party: Array, skill_id: String) -> Dictionary:
	var best_char: Dictionary = {}
	var best := -1
	for char in party:
		var lv := CharacterSystem.get_effective_skill_level(char, skill_id)
		if lv > best:
			best = lv
			best_char = char
	return best_char
