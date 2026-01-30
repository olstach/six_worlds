extends Control
## Character Sheet UI - Displays and allows interaction with character stats
##
## This scene shows:
## - Character portrait and basic info
## - All attributes with increase buttons
## - Skills list with upgrade buttons
## - Equipment and inventory
## - Debug controls for testing

@onready var character_name_label: Label = $VBoxContainer/Header/NameLabel
@onready var race_label: Label = $VBoxContainer/Header/RaceLabel
@onready var level_label: Label = $VBoxContainer/Header/LevelLabel
@onready var xp_label: Label = $VBoxContainer/Header/XPLabel

var attributes_container: VBoxContainer
var skills_container: VBoxContainer
var derived_stats_container: VBoxContainer
var karma_debug: Label

var current_character: Dictionary

func _ready() -> void:
	# Get node references
	attributes_container = $VBoxContainer/HBoxContainer/LeftPanel/AttributesContainer
	skills_container = $VBoxContainer/HBoxContainer/MiddlePanel/SkillsContainer
	derived_stats_container = $VBoxContainer/HBoxContainer/RightPanel/DerivedStatsContainer
	karma_debug = $VBoxContainer/DebugPanel/KarmaDebug
	
	# Verify nodes exist
	if not attributes_container:
		print("ERROR: attributes_container not found!")
		return
	if not skills_container:
		print("ERROR: skills_container not found!")
		return
	if not derived_stats_container:
		print("ERROR: derived_stats_container not found!")
		return
	
	# Connect to character system signals
	CharacterSystem.character_updated.connect(_on_character_updated)
	CharacterSystem.attribute_increased.connect(_on_attribute_increased)
	CharacterSystem.skill_upgraded.connect(_on_skill_upgraded)
	
	# Display player character
	refresh_display()

func refresh_display() -> void:
	current_character = CharacterSystem.get_player()
	print("Refresh display called. Character empty? ", current_character.is_empty())
	if current_character.is_empty():
		print("No character found! Party size: ", CharacterSystem.get_party().size())
		return
	
	# Update header
	character_name_label.text = current_character.name
	race_label.text = current_character.race.capitalize() + " " + current_character.background.capitalize()
	level_label.text = ""  # No longer using levels
	xp_label.text = "XP: " + str(current_character.xp)
	
	# Update attributes
	update_attributes_display()
	
	# Update skills
	update_skills_display()
	
	# Update derived stats
	update_derived_stats_display()
	
	# Update karma debug
	karma_debug.text = KarmaSystem.get_karma_report()

func update_attributes_display() -> void:
	# Clear existing
	for child in attributes_container.get_children():
		if child.name != "Title":
			child.queue_free()
	
	# Add each attribute
	for attr_name in current_character.attributes:
		var attr_value = current_character.attributes[attr_name]
		var cost = CharacterSystem.calculate_attribute_cost(attr_value, 1)
		
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = attr_name.capitalize() + ":"
		name_label.custom_minimum_size.x = 120
		hbox.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = str(attr_value)
		value_label.custom_minimum_size.x = 40
		hbox.add_child(value_label)
		
		var button = Button.new()
		button.text = "+" + str(cost) + " XP"
		button.disabled = current_character.xp < cost
		button.pressed.connect(func(): increase_attribute(attr_name))
		hbox.add_child(button)
		
		attributes_container.add_child(hbox)

func update_skills_display() -> void:
	# Clear existing
	for child in skills_container.get_children():
		if child.name != "Title":
			child.queue_free()
	
	# Show skills the character has
	for skill_name in current_character.skills:
		var skill_level = current_character.skills[skill_name]
		
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = skill_name.capitalize().replace("_", " ") + ":"
		name_label.custom_minimum_size.x = 150
		hbox.add_child(name_label)
		
		var level_label = Label.new()
		level_label.text = str(skill_level) + " / 5"
		level_label.custom_minimum_size.x = 50
		hbox.add_child(level_label)
		
		if skill_level < 5:
			var cost = CharacterSystem.SKILL_COSTS[skill_level + 1]
			var button = Button.new()
			button.text = "Upgrade (" + str(cost) + " XP)"
			button.disabled = current_character.xp < cost
			button.pressed.connect(func(): upgrade_skill(skill_name))
			hbox.add_child(button)
		
		skills_container.add_child(hbox)
	
	# Add a "Learn New Skill" button
	var learn_button = Button.new()
	learn_button.text = "+ Learn New Skill"
	learn_button.pressed.connect(_on_learn_new_skill_pressed)
	skills_container.add_child(learn_button)

func update_derived_stats_display() -> void:
	# Clear existing
	for child in derived_stats_container.get_children():
		if child.name != "Title":
			child.queue_free()
	
	var derived = current_character.derived
	
	var stats = [
		["HP", str(derived.current_hp) + " / " + str(derived.max_hp)],
		["Mana", str(derived.current_mana) + " / " + str(derived.max_mana)],
		["Initiative", str(derived.initiative)],
		["Dodge", str(derived.dodge)],
		["Crit Chance", str(derived.crit_chance) + "%"],
		["Weight Limit", str(derived.weight_limit)]
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat[0] + ":"
		name_label.custom_minimum_size.x = 120
		hbox.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = stat[1]
		hbox.add_child(value_label)
		
		derived_stats_container.add_child(hbox)

func increase_attribute(attr_name: String) -> void:
	CharacterSystem.increase_attribute(current_character, attr_name, 1)

func upgrade_skill(skill_name: String) -> void:
	CharacterSystem.upgrade_skill(current_character, skill_name)

func _on_character_updated(character: Dictionary) -> void:
	if character == current_character:
		refresh_display()

func _on_attribute_increased(character: Dictionary, attr_name: String, new_value: int) -> void:
	print("Attribute increased: ", attr_name, " -> ", new_value)

func _on_skill_upgraded(character: Dictionary, skill_name: String, new_level: int) -> void:
	print("Skill upgraded: ", skill_name, " -> ", new_level)

# Debug controls
func _on_grant_xp_button_pressed() -> void:
	CharacterSystem.grant_xp(current_character, 500)

func _on_learn_new_skill_pressed() -> void:
	# Simple popup to learn a new skill
	print("Learn new skill UI would go here")
	# For now, just learn a random skill at level 1
	var test_skills = ["swords", "fire_magic", "persuasion", "trade", "lore"]
	for skill in test_skills:
		if skill not in current_character.skills:
			CharacterSystem.set_skill_level(current_character, skill, 1)
			refresh_display()
			return

func _on_add_karma_button_pressed(realm: String, amount: int) -> void:
	KarmaSystem.add_karma(realm, amount, "Debug test")
	karma_debug.text = KarmaSystem.get_karma_report()

func _on_test_reincarnation_button_pressed() -> void:
	var reincarnation_data = KarmaSystem.reincarnate()
	print("Reincarnation: ", reincarnation_data)
	
	# Create new character
	CharacterSystem.create_player_character(
		"Reborn Soul",
		reincarnation_data.race,
		reincarnation_data.background
	)
	
	GameState.start_new_run(reincarnation_data.realm)
	refresh_display()
