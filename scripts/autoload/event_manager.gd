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

# Current event being displayed
var current_event: Dictionary = {}

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
	print("Started event: ", current_event.title)
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
				
				# Check each party member
				for party_member in CharacterSystem.get_party():
					if party_member.attributes[attr_name] >= required_value:
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
		
		# Check skill requirements
		if "skills" in reqs:
			var meets_req = false
			var passing_char = null
			var first_skill_name = ""
			var first_skill_level = 0
			
			for skill_name in reqs.skills:
				var required_level = reqs.skills[skill_name]
				
				# Store first requirement for error message
				if first_skill_name == "":
					first_skill_name = skill_name
					first_skill_level = required_level
				
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
				result.reason = "Requires " + first_skill_name.capitalize().replace("_", " ") + " " + str(int(first_skill_level))
				return result
			else:
				result.passing_character = passing_char
	
	return result

## Execute a choice (with roll if needed)
func make_choice(choice: Dictionary) -> Dictionary:
	print("Choice made: ", choice.text)
	choice_made.emit(choice)
	
	var outcome = {}
	
	# Handle roll-based choices
	if choice.type == "roll" and "requirements" in choice and "roll" in choice.requirements:
		var roll_req = choice.requirements.roll
		var attribute = roll_req.attribute
		var difficulty = roll_req.difficulty
		
		# Find highest attribute value in party
		var best_value = 0
		var roller = null
		for party_member in CharacterSystem.get_party():
			var attr_value = party_member.attributes.get(attribute, 0)
			if attr_value > best_value:
				best_value = attr_value
				roller = party_member
		
		# Roll: d20 + attribute value
		var roll = randi() % 20 + 1
		var total = roll + best_value
		var success = total >= difficulty
		
		print("Roll: ", roll, " + ", best_value, " (", attribute, ") = ", total, " vs DC ", difficulty)
		print("Roller: ", roller.name if roller else "unknown")
		print("Result: ", "SUCCESS" if success else "FAILURE")
		
		# Choose appropriate outcome
		if success and "outcome_success" in choice:
			outcome = choice.outcome_success.duplicate(true)
		elif not success and "outcome_failure" in choice:
			outcome = choice.outcome_failure.duplicate(true)
		else:
			outcome = choice.outcome.duplicate(true) if "outcome" in choice else {}
		
		outcome["roll_result"] = {
			"roll": roll,
			"attribute": attribute,
			"attribute_value": best_value,
			"total": total,
			"difficulty": difficulty,
			"success": success,
			"roller": roller.name if roller else "Unknown"
		}
	else:
		# Non-roll choice, use standard outcome
		outcome = choice.outcome.duplicate(true) if "outcome" in choice else {}
	
	# Apply outcome
	apply_outcome(outcome)
	
	return outcome

## Apply the outcome of a choice
func apply_outcome(outcome: Dictionary) -> void:
	if outcome.is_empty():
		return
	
	# Grant rewards
	if "rewards" in outcome:
		var rewards = outcome.rewards
		
		if "xp" in rewards:
			var player = CharacterSystem.get_player()
			CharacterSystem.grant_xp(player, rewards.xp)
			print("Granted XP: ", rewards.xp)
		
		if "items" in rewards:
			# TODO: Add items to inventory
			print("Granted items: ", rewards.items)
	
	# Apply karma changes
	if "karma" in outcome:
		for realm in outcome.karma:
			KarmaSystem.add_karma(realm, outcome.karma[realm], "Event choice")
	
	# Handle outcome type — combat/shop are routed to overworld via signals
	match outcome.get("type", "text"):
		"text":
			event_completed.emit(outcome)
		"combat":
			# Overworld will handle scene transition to combat_arena
			combat_requested.emit(outcome.get("enemy_group", "unknown"), outcome)
		"shop":
			# Overworld will handle opening shop overlay
			shop_requested.emit(outcome.get("shop_id", "unknown"), outcome)

## Get a random event for a specific realm
func get_random_event_for_realm(realm: String) -> String:
	var realm_events = []
	for event_id in event_database:
		if event_database[event_id].realm == realm:
			realm_events.append(event_id)
	
	if realm_events.is_empty():
		return ""
	
	return realm_events[randi() % realm_events.size()]
