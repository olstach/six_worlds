extends Control
## New Character Sheet - Clean implementation matching design mockup

# Left panel - top left (Name, Race, Background, XP)
@onready var name_label: Label = $HBox/LeftPanel/TopRow/TopLeft/NameLabel
@onready var race_label: Label = $HBox/LeftPanel/TopRow/TopLeft/RaceLabel
@onready var background_label: Label = $HBox/LeftPanel/TopRow/TopLeft/BackgroundLabel
@onready var xp_total_label: Label = $HBox/LeftPanel/TopRow/TopLeft/XPTotalLabel
@onready var xp_free_label: Label = $HBox/LeftPanel/TopRow/TopLeft/XPFreeLabel

# Left panel - top right (Karma)
@onready var karma_list: VBoxContainer = $HBox/LeftPanel/TopRow/TopRight/KarmaList

# Left panel - bottom left (Main Attributes)
@onready var attributes_list: VBoxContainer = $HBox/LeftPanel/BottomRow/BottomLeft/AttributesList

# Left panel - bottom right (Derived Stats)
@onready var derived_list: VBoxContainer = $HBox/LeftPanel/BottomRow/BottomRight/DerivedList

# Right panel - Skills grid (8 columns x 5 rows)
@onready var skills_grid: GridContainer = $HBox/RightPanel/SkillsGrid

var current_character: Dictionary

func _ready() -> void:
	# Connect to signals
	CharacterSystem.character_updated.connect(_on_character_updated)
	
	# Wait one frame for autoloads to initialize
	await get_tree().process_frame
	
	# Display character
	refresh_display()

func refresh_display() -> void:
	current_character = CharacterSystem.get_player()
	
	if current_character.is_empty():
		print("No character yet")
		return
	
	# Update all sections
	update_header()
	update_karma()
	update_attributes()
	update_derived_stats()
	update_skills_grid()

func update_header() -> void:
	name_label.text = current_character.name
	race_label.text = current_character.race.capitalize()
	background_label.text = current_character.background.capitalize()
	xp_total_label.text = "XP Total: " + str(current_character.xp)
	xp_free_label.text = "Free XP: " + str(current_character.xp)  # TODO: track spent vs free

func update_karma() -> void:
	# Clear existing
	for child in karma_list.get_children():
		child.queue_free()
	
	var karma_scores = KarmaSystem.karma_scores
	var realms = ["god", "asura", "human", "animal", "hungry_ghost", "hell"]
	
	for realm in realms:
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = realm.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 100
		hbox.add_child(label)
		
		var value_label = Label.new()
		value_label.text = str(karma_scores[realm])
		hbox.add_child(value_label)
		
		karma_list.add_child(hbox)

func update_attributes() -> void:
	# Clear existing
	for child in attributes_list.get_children():
		child.queue_free()
	
	for attr_name in current_character.attributes:
		var value = current_character.attributes[attr_name]
		var cost = CharacterSystem.calculate_attribute_cost(value, 1)
		
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = attr_name.capitalize()
		label.custom_minimum_size.x = 80
		hbox.add_child(label)
		
		var value_label = Label.new()
		value_label.text = str(value)
		value_label.custom_minimum_size.x = 30
		hbox.add_child(value_label)
		
		var button = Button.new()
		button.text = "+" + str(cost)
		button.custom_minimum_size = Vector2(70, 0)
		button.disabled = current_character.xp < cost
		button.pressed.connect(func(): increase_attribute(attr_name))
		hbox.add_child(button)
		
		attributes_list.add_child(hbox)

func update_derived_stats() -> void:
	# Clear existing
	for child in derived_list.get_children():
		child.queue_free()
	
	var derived = current_character.derived
	var stats = [
		["HP", str(derived.current_hp) + "/" + str(derived.max_hp)],
		["Mana", str(derived.current_mana) + "/" + str(derived.max_mana)],
		["Init", str(derived.initiative)],
		["Dodge", str(derived.dodge)],
		["Crit", str(derived.crit_chance) + "%"],
		["Weight", str(derived.weight_limit)]
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat[0]
		name_label.custom_minimum_size.x = 60
		hbox.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = stat[1]
		hbox.add_child(value_label)
		
		derived_list.add_child(hbox)

func update_skills_grid() -> void:
	# Clear existing
	for child in skills_grid.get_children():
		child.queue_free()
	
	# Element rows: Space, Air, Fire, Water, Earth
	var elements = ["space", "air", "fire", "water", "earth"]
	
	# Load skills data to map skills to elements
	var skills_by_element = get_skills_by_element()
	
	for element in elements:
		# Column 1: Element name and affinity
		var element_label = Label.new()
		element_label.text = element.capitalize() + "\nAff: " + str(current_character.elements[element])
		element_label.custom_minimum_size = Vector2(100, 60)
		skills_grid.add_child(element_label)
		
		# Columns 2-8: Skills for this element
		var element_skills = skills_by_element.get(element, [])
		
		for i in range(7):  # 7 skill slots per row
			if i < element_skills.size():
				var skill_name = element_skills[i]
				var skill_level = current_character.skills.get(skill_name, 0)
				
				var skill_button = Button.new()
				skill_button.text = skill_name.replace("_", " ").capitalize() + "\nLv " + str(skill_level)
				skill_button.custom_minimum_size = Vector2(100, 60)
				
				if skill_level < 5:
					var cost = CharacterSystem.SKILL_COSTS[skill_level + 1] if skill_level < 5 else 0
					skill_button.disabled = current_character.xp < cost
					skill_button.pressed.connect(func(): upgrade_skill(skill_name))
				else:
					skill_button.disabled = true
				
				skills_grid.add_child(skill_button)
			else:
				# Empty slot
				var empty = Control.new()
				empty.custom_minimum_size = Vector2(100, 60)
				skills_grid.add_child(empty)

func get_skills_by_element() -> Dictionary:
	# Map skills to elements based on skills.json data
	# For now, hardcoded mapping - TODO: load from skills.json
	return {
		"space": ["space_magic", "yoga", "sorcery"],
		"air": ["air_magic", "bows"],
		"fire": ["fire_magic", "swords"],
		"water": ["water_magic", "persuasion"],
		"earth": ["earth_magic", "unarmed", "shields"]
	}

func increase_attribute(attr_name: String) -> void:
	CharacterSystem.increase_attribute(current_character, attr_name, 1)

func upgrade_skill(skill_name: String) -> void:
	CharacterSystem.upgrade_skill(current_character, skill_name)

func _on_character_updated(_character: Dictionary) -> void:
	refresh_display()
