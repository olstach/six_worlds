extends Node
## EventManager - Handles event flow, choice evaluation, and outcomes
##
## This singleton manages:
## - Loading and presenting events
## - Evaluating choice requirements (attributes, skills, party checks)
## - Handling dice rolls for yellow choices
## - Applying outcomes (XP, items, karma, combat triggers)

signal event_started(event_data: Dictionary)
signal event_completed(outcomes: Dictionary)
signal choice_made(choice_data: Dictionary)
signal combat_requested(enemy_group: String, outcome: Dictionary)
signal shop_requested(shop_id: String, outcome: Dictionary)
signal quest_board_requested(realm: String, outcome: Dictionary)

# Current event being displayed
var current_event: Dictionary = {}

# Context for the map object that triggered this event.
# Set by overworld before calling show_event so choice-use tracking works.
var current_event_object_id: String = ""
var current_event_one_time: bool = false
var _current_choice_id: String = ""  # Recorded when make_choice is called

# Event database (will load from JSON)
var event_database: Dictionary = {}

# Choice type colors for UI
const CHOICE_COLORS: Dictionary = {
	"default": Color(0.6, 0.6, 0.6),  # Grey
	"requirement": Color(0.3, 0.6, 0.9),  # Blue
	"roll": Color(0.9, 0.75, 0.2)  # Yellow/Gold
}

func _ready() -> void:
	print("EventManager initialized")
	load_event_database()

## Load all events from JSON files in resources/data/events/
func load_event_database() -> void:
	var events_dir = "res://resources/data/events/"
	var dir = DirAccess.open(events_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("_events.json"):
				_load_event_file(events_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Fallback to test events if nothing loaded
	if event_database.is_empty():
		print("No event JSON files found, using test events")
		create_test_events()
	else:
		print("Loaded %d events from JSON files" % event_database.size())


## Load a single event JSON file and merge into the database
func _load_event_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open event file: ", path)
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		print("JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or "events" not in data:
		print("Invalid event file format (missing 'events' key): ", path)
		return

	var count = 0
	for event_id in data.events:
		var event = data.events[event_id]
		event["id"] = event_id  # Ensure id matches key
		event_database[event_id] = event
		count += 1

	print("Loaded %d events from %s" % [count, path.get_file()])

## Create some test events for development
func create_test_events() -> void:
	event_database = {
		"test_encounter_1": {
			"id": "test_encounter_1",
			"title": "Wandering Devil",
			"realm": "hell",
			"text": "A red devil blocks your path, flames dancing around its fists. It eyes you with a mix of curiosity and hunger.\n\n'You smell of the upper realms,' it growls. 'What brings you to this place of suffering?'",
			"image": null,  # Future: path to image
			"choices": [
				{
					"id": "choice_fight",
					"type": "default",
					"text": "Attack without hesitation",
					"outcome": {
						"type": "combat",
						"enemy_group": "single_red_devil",
						"karma": {"hell": 5, "asura": 3}
					}
				},
				{
					"id": "choice_talk",
					"type": "default",
					"text": "Attempt to reason with it",
					"outcome": {
						"type": "text",
						"text": "The devil laughs, a sound like crackling fire. 'Reason? Here?' It considers for a moment, then steps aside. 'You amuse me. Pass, but remember - compassion is weakness in this realm.'",
						"rewards": {"xp": 50},
						"karma": {"human": 5, "god": 2}
					}
				},
				{
					"id": "choice_charm",
					"type": "requirement",
					"text": "Compliment its fierce appearance",
					"requirements": {
						"attributes": {"charm": 15}
					},
					"outcome": {
						"type": "text",
						"text": "The devil's expression softens slightly. 'Finally, someone who appreciates true power!' it booms. It offers you a charred trinket. 'Take this. May it serve you as it served me.'",
						"rewards": {"xp": 75, "items": ["devils_charm"]},
						"karma": {"animal": 3, "human": 2}
					}
				},
				{
					"id": "choice_fire_magic",
					"type": "requirement",
					"text": "Match its flames with your own fire magic",
					"requirements": {
						"skills": {"fire_magic": 2}
					},
					"outcome": {
						"type": "text",
						"text": "You summon flames to dance around your hands, matching the devil's display. It grins widely. 'A practitioner! We should not fight, you and I.' It bows slightly and departs, leaving you with a scroll of flame.",
						"rewards": {"xp": 100, "items": ["fire_scroll"]},
						"karma": {"hell": -5, "human": 5}
					}
				},
				{
					"id": "choice_run",
					"type": "roll",
					"text": "Attempt to flee",
					"requirements": {
						"roll": {
							"attribute": "finesse",
							"difficulty": 12
						}
					},
					"outcome_success": {
						"type": "text",
						"text": "You dart away with surprising speed, disappearing into the smoky landscape before the devil can react. Your heart pounds as you find safety.",
						"rewards": {"xp": 25},
						"karma": {"animal": 5}
					},
					"outcome_failure": {
						"type": "combat",
						"enemy_group": "angry_red_devil",
						"text": "The devil catches you easily, laughing. 'Running? How pathetic!' It attacks with renewed fury.",
						"karma": {"hell": 10}
					}
				}
			]
		},
		
		"test_encounter_2": {
			"id": "test_encounter_2",
			"title": "Mysterious Trader",
			"realm": "human",
			"text": "An old woman sits by the roadside, her wares spread on a colorful cloth. Strange trinkets gleam in the light - some mundane, others clearly magical.\n\n'Traveler,' she calls, 'care to see what fate has brought to my collection today?'",
			"choices": [
				{
					"id": "choice_browse",
					"type": "default",
					"text": "Browse her wares",
					"outcome": {
						"type": "shop",
						"shop_id": "roadside_trader",
						"karma": {"human": 2}
					}
				},
				{
					"id": "choice_ask_advice",
					"type": "requirement",
					"text": "Ask for wisdom about your journey",
					"requirements": {
						"attributes": {"awareness": 14}
					},
					"outcome": {
						"type": "text",
						"text": "She looks at you with ancient eyes. 'You seek knowledge, not just things. Rare.' She tells you secrets about the path ahead, knowledge that will serve you well.",
						"rewards": {"xp": 150},
						"karma": {"human": 5, "god": 3}
					}
				},
				{
					"id": "choice_ignore",
					"type": "default",
					"text": "Politely decline and continue on",
					"outcome": {
						"type": "text",
						"text": "She nods knowingly. 'Not all who wander are lost, and not all who seek must buy. Safe travels.'",
						"rewards": {"xp": 10},
						"karma": {"human": 1}
					}
				}
			]
		}
	}
	print("Loaded ", event_database.size(), " test events")

## Start an event by ID
func start_event(event_id: String) -> bool:
	if event_id not in event_database:
		# Alpha fallback: use test event for unknown event IDs
		if "test_encounter_1" in event_database:
			print("Event '%s' not found, falling back to test_encounter_1" % event_id)
			event_id = "test_encounter_1"
		else:
			print("Event not found: ", event_id)
			return false
	
	current_event = event_database[event_id].duplicate(true)

	# Track first visits for location events — sets a flag other events can check
	var event_type = current_event.get("type", "")
	if event_type == "location":
		current_event["is_first_visit"] = GameState.is_first_visit(event_id)
		GameState.mark_location_visited(event_id)

	event_started.emit(current_event)
	return true

## Evaluate if a choice is available to the party
func evaluate_choice_availability(choice: Dictionary) -> Dictionary:
	var result = {
		"available": true,
		"type": choice.type,
		"reason": "",
		"passing_character": null  # Which party member meets requirements
	}

	# Flag prerequisite: if present and not satisfied, hide this choice entirely.
	# Unlike "requirements" (which shows a disabled button), a hidden choice is not rendered.
	if "prerequisite" in choice:
		var prereq: Dictionary = choice.prerequisite
		var flag_key: String = prereq.get("flag", "")
		var expected = prereq.get("value", true)
		if flag_key != "" and GameState.get_flag(flag_key, false) != expected:
			result.available = false
			result["hidden"] = true
			return result

	# For persistent (non-one_time) event objects, block choices that have
	# already been used (non-shop outcomes only) to prevent XP farming.
	if not current_event_one_time and not current_event_object_id.is_empty():
		var choice_id = choice.get("id", "")
		var used = GameState.used_event_choices.get(current_event_object_id, [])
		if choice_id in used:
			result.available = false
			result.reason = "Already done"
			return result

	# Default and roll choices are always visible
	if choice.type == "default" or choice.type == "roll":
		return result
	
	# Requirement choices need checking
	if choice.type == "requirement":
		if "requirements" not in choice:
			return result
		
		var reqs = choice.requirements
		
		# Check attribute requirements
		if "attributes" in reqs:
			var meets_req = false
			var passing_char = null
			var first_attr_name = ""
			var first_attr_value = 0
			
			for attr_name in reqs.attributes:
				var required_value = reqs.attributes[attr_name]
				
				# Store first requirement for error message
				if first_attr_name == "":
					first_attr_name = attr_name
					first_attr_value = required_value
				
				# Check each party member — use effective attribute (base + quirk modifiers)
				for party_member in CharacterSystem.get_party():
					var base_val: int = party_member.attributes.get(attr_name, 0)
					var quirk_bonus: int = 0
					if QuirkSystem:
						quirk_bonus = QuirkSystem.get_attribute_bonus(party_member).get(attr_name, 0)
					if base_val + quirk_bonus >= required_value:
						meets_req = true
						passing_char = party_member
						break
				
				if meets_req:
					break
			
			if not meets_req:
				result.available = false
				result.reason = "Requires " + first_attr_name.capitalize() + " " + str(int(first_attr_value))
				return result
			else:
				result.passing_character = passing_char
		
		# Check skill requirements — multiple skills in the dict are treated as OR
		# (any one skill meeting its level is sufficient to unlock the choice)
		if "skills" in reqs:
			var meets_req = false
			var passing_char = null
			var skill_labels: Array[String] = []

			for skill_name in reqs.skills:
				var required_level = reqs.skills[skill_name]
				skill_labels.append(skill_name.replace("_", " ").capitalize() + " " + str(int(required_level)))

				# Check each party member
				for party_member in CharacterSystem.get_party():
					var char_skill_level = party_member.skills.get(skill_name, 0)
					if char_skill_level >= required_level:
						meets_req = true
						passing_char = party_member
						break

				if meets_req:
					break

			if not meets_req:
				result.available = false
				result.reason = "Requires " + " / ".join(skill_labels)
				return result
			else:
				result.passing_character = passing_char

		# Check quirk requirement — any party member with the quirk enables the option
		if "quirk" in reqs:
			var required_quirk: String = reqs["quirk"]
			var meets_req := false
			var passing_char = null
			for party_member in CharacterSystem.get_party():
				if required_quirk in party_member.get("quirks", []):
					meets_req = true
					passing_char = party_member
					break
			if not meets_req:
				result.available = false
				result.reason = "Requires: " + QuirkSystem.get_quirk_name(required_quirk)
				return result
			else:
				result.passing_character = passing_char

	return result

## Execute a choice (with roll if needed)
func make_choice(choice: Dictionary) -> Dictionary:
	choice_made.emit(choice)
	
	var outcome = {}
	
	# Handle roll-based choices
	if choice.type == "roll" and "requirements" in choice and "roll" in choice.requirements:
		var roll_req = choice.requirements.roll
		var difficulty = roll_req.difficulty

		# Determine whether this is an attribute roll or a skill roll
		var roll_label: String  # used in roll_result for display
		var best_value = 0
		var roller = null

		if "skill" in roll_req:
			# Skill-based roll: find best skill level in party
			var skill_id = roll_req.skill
			roll_label = skill_id
			for party_member in CharacterSystem.get_party():
				var skill_val = party_member.get("skills", {}).get(skill_id, 0)
				if skill_val > best_value:
					best_value = skill_val
					roller = party_member
		else:
			# Attribute-based roll (original behaviour)
			var attribute = roll_req.attribute
			roll_label = attribute
			for party_member in CharacterSystem.get_party():
				var attr_value = party_member.attributes.get(attribute, 0)
				if attr_value > best_value:
					best_value = attr_value
					roller = party_member

		# Roll: d20 + attribute/skill value
		var roll = randi() % 20 + 1
		var total = roll + best_value
		var success = total >= difficulty

		# Choose appropriate outcome
		if success and "outcome_success" in choice:
			outcome = choice.outcome_success.duplicate(true)
		elif not success and "outcome_failure" in choice:
			outcome = choice.outcome_failure.duplicate(true)
		else:
			outcome = choice.outcome.duplicate(true) if "outcome" in choice else {}

		outcome["roll_result"] = {
			"roll": roll,
			"attribute": roll_label,
			"attribute_value": best_value,
			"total": total,
			"difficulty": difficulty,
			"success": success,
			"roller": roller.name if roller else "Unknown"
		}
	else:
		# Non-roll choice, use standard outcome
		outcome = choice.outcome.duplicate(true) if "outcome" in choice else {}
	
	# Carry the choice's cost into the outcome so apply_outcome can deduct it
	if "cost" in choice:
		outcome["cost"] = choice.cost

	# Apply outcome
	apply_outcome(outcome)

	# Record this choice as used for persistent (non-one_time) objects so the
	# player can't farm XP by repeatedly visiting the same shrine/merchant.
	# Shop outcomes stay available (handled by the shop flow, not re-selectable here).
	var outcome_type = outcome.get("type", "text")
	if outcome_type != "shop" and not current_event_one_time and not current_event_object_id.is_empty():
		var choice_id = choice.get("id", "")
		if not choice_id.is_empty():
			if not current_event_object_id in GameState.used_event_choices:
				GameState.used_event_choices[current_event_object_id] = []
			var used: Array = GameState.used_event_choices[current_event_object_id]
			if not choice_id in used:
				used.append(choice_id)

	return outcome

## Apply the outcome of a choice
func apply_outcome(outcome: Dictionary) -> void:
	if outcome.is_empty():
		return

	# Grant rewards
	if "rewards" in outcome:
		var rewards = outcome.rewards

		if "xp" in rewards:
			CompanionSystem.apply_party_xp(int(rewards.xp))

		if "gold" in rewards:
			GameState.add_gold(int(rewards.gold))

		if "items" in rewards:
			for item_id in rewards.items:
				# Spell reward tokens — pick a random spell and teach it to the party
				if item_id in ["spell_random", "spell_random_white", "spell_random_black"]:
					var school: String
					match item_id:
						"spell_random_white": school = "White"
						"spell_random_black": school = "Black"
						_: school = ""  # any school
					_give_random_spell_reward(school)
					continue

				var resolved_id: String = item_id
				if ItemSystem.is_template_item(item_id):
					var gen_id := ItemSystem.resolve_random_generate(item_id)
					if gen_id != "":
						resolved_id = gen_id
				if ItemSystem.item_exists(resolved_id):
					ItemSystem.add_to_inventory(resolved_id)
				else:
					print("EventManager: Unknown item '%s', skipping" % item_id)

		# HP loss — e.g. {"amount": "moderate", "target": "all"} to deal out-of-combat damage.
		# amount: "light" (10%), "moderate" (25%), "heavy" (40%). target: "all" or "random".
		# HP is floored at 1 — events cannot kill party members.
		if "hp_loss" in rewards:
			var loss = rewards.hp_loss
			var amount_key: String = str(loss.get("amount", "moderate"))
			var target_mode: String = str(loss.get("target", "all"))
			var pct: float
			match amount_key:
				"light":    pct = 10.0
				"moderate": pct = 25.0
				"heavy":    pct = 40.0
				_:          pct = 20.0
			var party = CharacterSystem.get_party()
			var targets = []
			if target_mode == "random" and not party.is_empty():
				targets = [party[randi() % party.size()]]
			else:
				targets = party
			for char in targets:
				if "derived" in char:
					var dmg = maxi(1, int(char.derived.max_hp * pct / 100.0))
					char.derived.current_hp = maxi(1, char.derived.current_hp - dmg)
					print("EventManager: %s took %d HP damage from event" % [char.name, dmg])

		# Attribute loss — e.g. {"which": "random", "amount": 1} to lose a point
		# Used by events like the_smoking_mirror (look into the mirror).
		# "which" can be "random" or a specific attribute name.
		if "attribute_loss" in rewards:
			var loss = rewards.attribute_loss
			var amount: int = int(loss.get("amount", 1))
			var which: String = loss.get("which", "random")
			var player = CharacterSystem.get_player()
			if player and "attributes" in player:
				var all_attrs = ["strength", "constitution", "finesse", "focus", "awareness", "charm", "luck"]
				var chosen_attr: String
				if which == "random":
					chosen_attr = all_attrs[randi() % all_attrs.size()]
				elif which in all_attrs:
					chosen_attr = which
				if not chosen_attr.is_empty():
					player.attributes[chosen_attr] = max(1, int(player.attributes[chosen_attr]) - amount)
					CharacterSystem.update_derived_stats(player)
					print("EventManager: %s lost %d %s (attribute_loss)" % [player.name, amount, chosen_attr])

		# Skill gain — e.g. {"skill": "water_magic", "amount": 1, "cap": 6}
		if "skill_up" in rewards:
			var su = rewards.skill_up
			var skill_name: String = su.get("skill", "")
			var amount: int = int(su.get("amount", 1))
			var cap: int = int(su.get("cap", 10))
			if skill_name != "":
				# Apply to the party member who enabled the choice (or player)
				var target = CharacterSystem.get_player()
				var current_level: int = target.skills.get(skill_name, 0)
				if current_level < cap:
					CharacterSystem.set_skill_level(target, skill_name, min(current_level + amount, cap))
					print("EventManager: %s gained +%d %s (now %d)" % [target.name, amount, skill_name, target.skills[skill_name]])

		# Temporary combat buffs — e.g. [{"stat": "constitution", "amount": 2, "combats_remaining": 1}]
		if "buffs" in rewards:
			for buff in rewards.buffs:
				var stat: String = buff.get("stat", "")
				var amount = buff.get("amount", 0)
				var combats: int = int(buff.get("combats_remaining", 1))
				if stat != "":
					GameState.active_map_buffs.append({
						"stat": stat, "amount": amount, "combats_remaining": combats
					})
					# Re-derive stats so buff is reflected immediately
					for char in CharacterSystem.get_party():
						CharacterSystem.update_derived_stats(char)
					print("EventManager: Applied buff +%d %s for %d combat(s)" % [amount, stat, combats])

		# HP/Mana/Stamina restore — e.g. {"hp_percent": 50, "mana_percent": 50, "stamina_percent": 100}
		if "restore" in rewards:
			var restore = rewards.restore
			for char in CharacterSystem.get_party():
				if "hp_percent" in restore:
					var heal_amount = int(char.derived.max_hp * restore.hp_percent / 100.0)
					char.derived.current_hp = min(char.derived.current_hp + heal_amount, char.derived.max_hp)
				if "mana_percent" in restore:
					var mana_amount = int(char.derived.max_mana * restore.mana_percent / 100.0)
					char.derived.current_mana = min(char.derived.current_mana + mana_amount, char.derived.max_mana)
				if "stamina_percent" in restore:
					var stam_amount = int(char.derived.max_stamina * restore.stamina_percent / 100.0)
					char.derived.current_stamina = min(char.derived.current_stamina + stam_amount, char.derived.max_stamina)
			print("EventManager: Restored party HP/mana/stamina")

		# Learn a random spell — e.g. {"school": "white_magic", "level_range": [1, 2]}
		if "learn_spell" in rewards:
			var ls = rewards.learn_spell
			_give_random_spell_reward(ls.get("school", ""))

		# Gamble — e.g. {"type": "gold", "win_chance": 0.5, "win_multiplier": 2}
		# The cost is handled by the choice's "cost" field; this handles the payout.
		if "gamble" in rewards:
			var gamble = rewards.gamble
			var win_chance: float = gamble.get("win_chance", 0.5)
			if randf() <= win_chance:
				# Won — cost was already deducted, return double
				var payout_str: String = str(gamble.get("win_multiplier", 2)) + "x"
				print("EventManager: Gamble won! (%s payout)" % payout_str)
				# Actual gold amounts need the cost system to be fleshed out
			else:
				print("EventManager: Gamble lost.")

		# Emotional pressure — e.g. [{"element": "water", "amount": -20}, ...]
		# Applied to all party members. Each entry shifts one element.
		if "pressure" in rewards:
			var pressure_list = rewards.pressure
			if pressure_list is Dictionary:
				pressure_list = [pressure_list]  # allow single dict or array
			for party_member in CharacterSystem.get_party():
				for entry in pressure_list:
					var element: String = str(entry.get("element", ""))
					var amount: float = float(entry.get("amount", 0.0))
					if not element in PsychologySystem.ELEMENTS:
						continue
					if amount == 0.0:
						continue
					PsychologySystem.apply_pressure(party_member, element, amount)

		# gold_returned: the NPC refuses the money and gives it back (e.g. dark cave yogini)
		if "gold_returned" in rewards and rewards.gold_returned:
			# Cost was deducted when the choice cost was applied; refund the gold cost here.
			# We look for the gold cost on the original choice's cost field via current_choice_cost.
			if "cost" in outcome and "gold" in outcome.cost:
				var refund: int = _resolve_gold_cost(outcome.cost.gold)
				if refund > 0:
					GameState.add_gold(refund)
					print("EventManager: Gold returned (%d)" % refund)
			else:
				print("EventManager: gold_returned set but no gold cost found to refund")

	# Write world-state flags declared by this outcome
	if "set_flags" in outcome:
		if outcome.set_flags is Dictionary:
			for flag_key in outcome.set_flags:
				GameState.set_flag(flag_key, outcome.set_flags[flag_key])
		else:
			push_error("EventManager: 'set_flags' must be a Dictionary, got: %s" % type_string(typeof(outcome.set_flags)))

	# Register a new quest if the outcome defines one
	if "register_quest" in outcome:
		if outcome.register_quest is Dictionary:
			GameState.register_quest(outcome.register_quest)
		else:
			push_error("EventManager: 'register_quest' must be a Dictionary, got: %s" % type_string(typeof(outcome.register_quest)))

	# Apply gold/resource costs from the choice
	# Cost amounts are descriptive strings for now ("small", "moderate", etc.)
	# that will map to concrete values when the economy is tuned.
	# For now, use rough defaults so the system is functional.
	if "cost" in outcome:
		var cost = outcome.cost
		if "gold" in cost:
			var gold_amount = _resolve_gold_cost(cost.gold)
			if gold_amount > 0:
				GameState.spend_gold(gold_amount)
				print("EventManager: Spent %d gold" % gold_amount)
		if "food" in cost:
			var food_amount = _resolve_food_cost(cost.food)
			if food_amount > 0:
				GameState.consume_supply("food", food_amount)
				print("EventManager: Consumed %d food" % food_amount)
		# food_percent: spend a percentage of current food stores (e.g. the_pit bribe)
		if "food_percent" in cost:
			var pct: float = float(cost.food_percent)
			var current_food: int = GameState.get_supplies("food")
			var food_amount: int = max(1, int(current_food * pct / 100.0))
			GameState.consume_supply("food", food_amount)
			print("EventManager: Consumed %d food (%d%% of stores)" % [food_amount, int(pct)])
		if "herbs" in cost:
			var herbs_amount = _resolve_supply_cost(cost.herbs)
			if herbs_amount > 0:
				GameState.consume_supply("herbs", herbs_amount)
				print("EventManager: Consumed %d herbs" % herbs_amount)
		if "reagents" in cost:
			var reagents_amount = _resolve_supply_cost(cost.reagents)
			if reagents_amount > 0:
				GameState.consume_supply("reagents", reagents_amount)
				print("EventManager: Consumed %d reagents" % reagents_amount)

	# Apply karma changes
	if "karma" in outcome:
		for realm in outcome.karma:
			KarmaSystem.add_karma(realm, outcome.karma[realm], "Event choice")

	# Apply event-level shop price modifier (e.g. arrogant challenge — shop opens at +50% prices)
	if "shop_modifier" in outcome:
		var modifier = outcome.shop_modifier
		if "price_multiplier" in modifier:
			GameState.set_flag("event_shop_price_multiplier", modifier.price_multiplier)

	# Handle outcome type — combat/shop are routed to overworld via signals
	match outcome.get("type", "text"):
		"text":
			event_completed.emit(outcome)
		"combat":
			# Overworld will handle scene transition to combat_arena.
			# on_victory: if present, open a shop or run a follow-up after winning.
			combat_requested.emit(outcome.get("enemy_group", "unknown"), outcome)
		"shop":
			# Overworld will handle opening shop overlay
			shop_requested.emit(outcome.get("shop_id", "unknown"), outcome)
		"quest_board":
			# Overworld will handle opening quest board overlay
			quest_board_requested.emit(outcome.get("realm", "hell"), outcome)
			# Do NOT emit event_completed — overworld handles showing result panel
			return
		"recruit_companion":
			# Recruit a companion into the party.
			# companion_id: "random" picks a random companion not already in the party.
			# companion_pool: optional array of companion IDs to restrict the random pick.
			# Set "free": true to skip the gold cost (event-granted companions).
			var companion_id: String = outcome.get("companion_id", "")
			if companion_id == "random":
				var party_names: Array = CharacterSystem.get_party().map(func(c): return c.get("name", ""))
				var pool: Array = outcome.get("companion_pool", [])
				var all_ids: Array = pool if not pool.is_empty() else CompanionSystem.get_all_definitions().keys()
				var available: Array = all_ids.filter(func(cid):
					var def = CompanionSystem.get_definition(cid)
					return not def.get("name", cid) in party_names
				)
				if available.is_empty():
					push_warning("EventManager: recruit_companion random — all companions already in party")
					event_completed.emit(outcome)
					return
				companion_id = available[randi() % available.size()]
			if companion_id == "":
				push_error("EventManager: recruit_companion outcome missing 'companion_id' field")
			else:
				var free: bool = outcome.get("free", false)
				var recruited: Dictionary = CompanionSystem.recruit(companion_id, free)
				if recruited.is_empty():
					push_warning("EventManager: CompanionSystem.recruit() failed for id: %s" % companion_id)
			event_completed.emit(outcome)
		"follow_up":
			# Chain to another event. event_display reads follow_up_event from the outcome
			# to decide whether to close or start the next event when Continue is pressed.
			event_completed.emit(outcome)

## Convert descriptive gold cost strings to concrete amounts.
## These can be retuned as the economy matures.
func _resolve_gold_cost(amount) -> int:
	if amount is int or amount is float:
		return int(amount)
	match str(amount):
		"small":
			return 10
		"small_moderate":
			return 20
		"moderate":
			return 35
		"large":
			return 60
		"some":
			return 15  # "some gold and food"
		_:
			return 0

## Convert descriptive food cost strings to concrete amounts.
func _resolve_food_cost(amount) -> int:
	if amount is int or amount is float:
		return int(amount)
	match str(amount):
		"small":    return 5
		"moderate": return 15
		"large":    return 30
		_:          return 0

## Convert descriptive supply cost strings (herbs, reagents) to concrete amounts.
func _resolve_supply_cost(amount) -> int:
	if amount is int or amount is float:
		return int(amount)
	match str(amount):
		"small":    return 3
		"moderate": return 8
		"large":    return 18
		_:          return 0

## Get a random event for a specific realm
func get_random_event_for_realm(realm: String) -> String:
	var realm_events = []
	for event_id in event_database:
		if event_database[event_id].realm == realm:
			realm_events.append(event_id)

	if realm_events.is_empty():
		return ""

	return realm_events[randi() % realm_events.size()]


## Returns a random camp-trigger event ID for the given realm, or "" if none available.
## Camp events have "trigger": "camp" and realm matching "any" or the current realm.
func get_random_camp_event(realm: String) -> String:
	var camp_events: Array[String] = []
	for event_id in event_database:
		var ev: Dictionary = event_database[event_id]
		if ev.get("trigger", "") != "camp":
			continue
		var ev_realm: String = ev.get("realm", "any")
		if ev_realm == "any" or ev_realm == realm:
			camp_events.append(event_id)
	if camp_events.is_empty():
		return ""
	return camp_events[randi() % camp_events.size()]


## Teach a random spell to every party member who doesn't already know it.
## school: a spell school name like "White", "Black", or "" for any school.
## Picks one spell across all levels (excluding domain spells), then teaches it to all.
func _give_random_spell_reward(school: String) -> void:
	var party = CharacterSystem.get_party()
	if party.is_empty():
		return

	# Build list of spells known by ALL party members — skip those
	var known_by_all: Array = party[0].get("known_spells", []).duplicate()
	for i in range(1, party.size()):
		var member_spells = party[i].get("known_spells", [])
		known_by_all = known_by_all.filter(func(sid): return sid in member_spells)

	var school_lower = school.to_lower()
	var candidates: Array[String] = []
	var spell_db = CharacterSystem.get_spell_database()

	for spell_id in spell_db:
		if spell_id in known_by_all:
			continue
		var spell = spell_db[spell_id]
		# Skip domain spells — those are trainer-exclusive
		if "domain_spell" in spell.get("tags", []):
			continue
		if school_lower == "":
			candidates.append(spell_id)
		else:
			var matches = false
			for s in spell.get("schools", []):
				if s.to_lower() == school_lower:
					matches = true
					break
			if not matches and spell.get("subschool", "").to_lower() == school_lower:
				matches = true
			if matches:
				candidates.append(spell_id)

	if candidates.is_empty():
		print("EventManager: _give_random_spell_reward — no candidates for school='%s'" % school)
		return

	candidates.shuffle()
	var chosen_spell: String = candidates[0]
	var spell_name: String = spell_db[chosen_spell].get("name", chosen_spell)

	for member in party:
		if not CharacterSystem.knows_spell(member, chosen_spell):
			CharacterSystem.learn_spell(member, chosen_spell)

	print("EventManager: Party learned spell '%s' (%s)" % [spell_name, chosen_spell])
