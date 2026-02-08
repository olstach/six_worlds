extends Control
## Main Menu - Tabbed interface for character management
##
## Tab structure:
## 1. Stats - Attributes, derived stats, skills grid
## 2. Equipment - Gear slots and inventory (TODO)
## 3. Party - Party member management (TODO)

signal tab_changed(tab_index: int)

# Use unique names (%) for nodes marked with unique_name_in_owner
@onready var tab_container: TabContainer = $MarginContainer/VBoxContainer/TabContainer
@onready var name_value: Label = %NameValue
@onready var race_value: Label = %RaceValue
@onready var background_value: Label = %BackgroundValue
@onready var xp_value: Label = %XPValue
@onready var add_xp_button: Button = %AddXPButton
@onready var attributes_container: VBoxContainer = %AttributesContainer
@onready var derived_container: VBoxContainer = %DerivedContainer
@onready var skills_grid: GridContainer = %SkillsGrid
@onready var party_list: VBoxContainer = %PartyList
@onready var followers_list: VBoxContainer = %FollowersList
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var doll_layout: Control = %DollLayout
@onready var slot_title: Label = %SlotTitle
@onready var equipment_grid: GridContainer = %EquipmentGrid

# Equipment slot definitions
const EQUIPMENT_SLOTS := {
	"head": {"name": "Head", "types": ["helmet", "hat", "circlet"]},
	"chest": {"name": "Chest", "types": ["armor", "robe", "vest"]},
	"hand_l": {"name": "Hands (L)", "types": ["gloves", "gauntlets", "bracers"]},
	"hand_r": {"name": "Hands (R)", "types": ["gloves", "gauntlets", "bracers"]},
	"legs": {"name": "Legs", "types": ["pants", "greaves", "leggings"]},
	"feet": {"name": "Feet", "types": ["boots", "shoes", "sandals"]},
	"weapon_main": {"name": "Main Hand", "types": ["sword", "axe", "mace", "spear", "dagger", "staff", "bow"]},
	"weapon_off": {"name": "Off Hand", "types": ["sword", "dagger", "shield"]},
	"ring1": {"name": "Ring", "types": ["ring"]},
	"ring2": {"name": "Ring", "types": ["ring"]},
	"amulet": {"name": "Amulet", "types": ["amulet", "necklace"]},
	"trinket": {"name": "Trinket", "types": ["trinket", "charm"]}
}

var selected_equipment_slot: String = ""
var equipment_slot_buttons := {}
var current_weapon_set: int = 1  # 1 or 2

# Perk selection popup
var perk_popup: Control = null
var pending_perk_character: Dictionary = {}  # Character waiting for perk selection

# Item tooltip
var item_tooltip: Control = null
const ITEM_TOOLTIP_SCENE = preload("res://scenes/ui/item_tooltip.tscn")

# Attribute display names
const ATTRIBUTE_ABBREVS := {
	"strength": "STR",
	"finesse": "FIN",
	"constitution": "CON",
	"focus": "FOC",
	"awareness": "AWA",
	"charm": "CHA",
	"luck": "LCK"
}

# Skills organized by element (7 per element as per design)
const ELEMENT_SKILLS := {
	"space": ["swords", "martial_arts", "space_magic", "white_magic", "black_magic", "persuasion", "yoga"],
	"air": ["ranged", "daggers", "air_magic", "ritual", "learning", "comedy", "guile"],
	"fire": ["axes", "unarmed", "fire_magic", "sorcery", "might", "leadership", "performance"],
	"water": ["spears", "water_magic", "enchantment", "grace", "medicine", "alchemy", "thievery"],
	"earth": ["maces", "armor", "earth_magic", "summoning", "logistics", "trade", "crafting"]
}

# Element colors for visual distinction
const ELEMENT_COLORS := {
	"space": Color(0.7, 0.5, 0.9),   # Purple
	"air": Color(0.6, 0.85, 0.95),   # Light blue
	"fire": Color(0.95, 0.5, 0.3),   # Orange-red
	"water": Color(0.3, 0.6, 0.9),   # Blue
	"earth": Color(0.7, 0.6, 0.4)    # Brown
}

func _ready() -> void:
	# Connect to CharacterSystem signals
	CharacterSystem.character_updated.connect(_on_character_updated)
	CharacterSystem.attribute_increased.connect(_on_attribute_increased)
	CharacterSystem.skill_upgraded.connect(_on_skill_upgraded)
	CharacterSystem.perk_selection_requested.connect(_on_perk_selection_requested)

	# Connect to ItemSystem signals
	ItemSystem.inventory_changed.connect(_on_inventory_changed)
	ItemSystem.item_equipped.connect(_on_item_equipped)
	ItemSystem.item_unequipped.connect(_on_item_unequipped)

	# Connect tab change signal
	tab_container.tab_changed.connect(_on_tab_changed)

	# Connect debug button
	add_xp_button.pressed.connect(_on_add_xp_pressed)

	# Add starter items if inventory is empty
	if ItemSystem.get_inventory().is_empty():
		ItemSystem.add_starter_items()

	# Create item tooltip on a high CanvasLayer so it renders above all overlays
	var tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 100
	get_tree().root.add_child.call_deferred(tooltip_layer)
	item_tooltip = ITEM_TOOLTIP_SCENE.instantiate()
	tooltip_layer.add_child.call_deferred(item_tooltip)

	# Initial display
	_refresh_display()

func _on_tab_changed(tab: int) -> void:
	tab_changed.emit(tab)
	# Refresh equipment tab when switching to it (tab index 1)
	if tab == 1:
		_setup_equipment_doll()
		_update_equipment_slots()
		_update_equipment_display()
	# Refresh party tab when switching to it (tab index 2)
	elif tab == 2:
		_update_party_list()
		_update_followers_list()
		_update_inventory()

func _on_character_updated(_character: Dictionary) -> void:
	_refresh_display()

func _on_attribute_increased(_attr_name: String, _new_value: int) -> void:
	_refresh_display()

func _on_skill_upgraded(_skill_name: String, _new_level: int) -> void:
	_refresh_display()

func _on_inventory_changed() -> void:
	# Refresh equipment display if on equipment tab
	if tab_container.current_tab == 1:
		_update_equipment_display()
		_update_equipment_slots()

func _on_item_equipped(_character: Dictionary, _slot: String, _item_id: String) -> void:
	if tab_container.current_tab == 1:
		_update_equipment_display()
		_update_equipment_slots()

func _on_item_unequipped(_character: Dictionary, _slot: String, _item_id: String) -> void:
	if tab_container.current_tab == 1:
		_update_equipment_display()
		_update_equipment_slots()

func _on_add_xp_pressed() -> void:
	var player = CharacterSystem.get_player()
	if not player.is_empty():
		CharacterSystem.grant_xp(player, 500)

func _refresh_display() -> void:
	var character = CharacterSystem.get_player()
	if character.is_empty():
		return

	_update_header(character)
	_update_attributes(character)
	_update_derived_stats(character)
	_update_skills_grid(character)

func _update_header(character: Dictionary) -> void:
	name_value.text = character.get("name", "Unknown")
	race_value.text = character.get("race", "Unknown").capitalize()
	background_value.text = character.get("background", "Unknown").capitalize()
	xp_value.text = str(character.get("xp", 0))

func _update_attributes(character: Dictionary) -> void:
	# Clear existing
	for child in attributes_container.get_children():
		child.queue_free()

	var attributes = character.get("attributes", {})

	for attr_key in ATTRIBUTE_ABBREVS.keys():
		var attr_value = attributes.get(attr_key, 10)
		var row = _create_attribute_row(attr_key, attr_value)
		attributes_container.add_child(row)

func _create_attribute_row(attr_key: String, value: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	# Abbreviation label
	var abbrev_label = Label.new()
	abbrev_label.text = ATTRIBUTE_ABBREVS[attr_key]
	abbrev_label.custom_minimum_size.x = 40
	abbrev_label.add_theme_font_size_override("font_size", 14)
	row.add_child(abbrev_label)

	# Value label
	var value_label = Label.new()
	value_label.text = str(value)
	value_label.custom_minimum_size.x = 30
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	# Upgrade button
	var upgrade_btn = Button.new()
	var cost = CharacterSystem.calculate_attribute_cost(value, 1)
	upgrade_btn.text = "+  (%d XP)" % cost
	upgrade_btn.custom_minimum_size.x = 100
	upgrade_btn.pressed.connect(_on_attribute_upgrade_pressed.bind(attr_key))

	# Disable if can't afford
	var player = CharacterSystem.get_player()
	if player.get("xp", 0) < cost:
		upgrade_btn.disabled = true

	row.add_child(upgrade_btn)

	return row

func _on_attribute_upgrade_pressed(attr_key: String) -> void:
	var player = CharacterSystem.get_player()
	if not player.is_empty():
		CharacterSystem.increase_attribute(player, attr_key)

func _update_derived_stats(character: Dictionary) -> void:
	# Clear existing
	for child in derived_container.get_children():
		child.queue_free()

	# Note: CharacterSystem uses "derived" not "derived_stats"
	var derived = character.get("derived", {})

	var stats_to_show = [
		["HP", derived.get("max_hp", 0)],
		["Mana", derived.get("max_mana", 0)],
		["Stamina", derived.get("max_stamina", 0)],
		["Init", derived.get("initiative", 0)],
		["Dodge", derived.get("dodge", 0)],
		["Crit", str(derived.get("crit_chance", 0)) + "%"],
		["Move", derived.get("movement", 0)],
		["Dmg", derived.get("damage", 0)],
		["Armor", derived.get("armor", 0)],
		["Spell", derived.get("spellpower", 0)]
	]

	for stat_info in stats_to_show:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var name_label = Label.new()
		name_label.text = stat_info[0]
		name_label.custom_minimum_size.x = 70
		name_label.add_theme_font_size_override("font_size", 13)
		row.add_child(name_label)

		var value_label = Label.new()
		value_label.text = str(stat_info[1])
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)

		derived_container.add_child(row)

func _update_skills_grid(character: Dictionary) -> void:
	# Clear existing
	for child in skills_grid.get_children():
		child.queue_free()

	var char_skills = character.get("skills", {})

	# Calculate elemental affinities (sum of skill levels per element)
	var affinities := {}
	for element in ELEMENT_SKILLS.keys():
		var total := 0
		for skill_id in ELEMENT_SKILLS[element]:
			total += char_skills.get(skill_id, 0)
		affinities[element] = total

	# Header row (element names + affinity totals)
	var header_spacer = Label.new()
	header_spacer.text = ""
	skills_grid.add_child(header_spacer)

	for element in ELEMENT_SKILLS.keys():
		var header_container = VBoxContainer.new()
		header_container.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_label = Label.new()
		name_label.text = element.capitalize()
		name_label.add_theme_color_override("font_color", ELEMENT_COLORS[element])
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_container.add_child(name_label)

		var affinity_label = Label.new()
		affinity_label.text = "[" + str(affinities[element]) + "]"
		affinity_label.add_theme_color_override("font_color", ELEMENT_COLORS[element])
		affinity_label.add_theme_font_size_override("font_size", 12)
		affinity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_container.add_child(affinity_label)

		skills_grid.add_child(header_container)

	# Add spacer columns to fill 8 columns
	for i in range(8 - ELEMENT_SKILLS.size() - 1):
		var spacer = Control.new()
		skills_grid.add_child(spacer)

	# Skill rows (7 rows, one for each skill slot per element)
	for skill_index in range(7):
		# Row number label
		var row_label = Label.new()
		row_label.text = str(skill_index + 1) + "."
		row_label.add_theme_font_size_override("font_size", 12)
		skills_grid.add_child(row_label)

		# Skills for each element
		for element in ELEMENT_SKILLS.keys():
			var skill_id = ELEMENT_SKILLS[element][skill_index]
			var skill_level = char_skills.get(skill_id, 0)

			var skill_btn = Button.new()
			skill_btn.text = _format_skill_name(skill_id) + " [" + str(skill_level) + "]"
			skill_btn.custom_minimum_size = Vector2(110, 28)
			skill_btn.add_theme_font_size_override("font_size", 11)

			# Color based on level
			if skill_level > 0:
				skill_btn.add_theme_color_override("font_color", ELEMENT_COLORS[element])

			skill_btn.pressed.connect(_on_skill_pressed.bind(skill_id))
			skills_grid.add_child(skill_btn)

		# Fill remaining columns
		for i in range(8 - ELEMENT_SKILLS.size() - 1):
			var spacer = Control.new()
			skills_grid.add_child(spacer)

func _format_skill_name(skill_id: String) -> String:
	# Convert skill_id like "fire_magic" to "Fire"
	var parts = skill_id.split("_")
	if parts.size() > 0:
		return parts[0].capitalize()
	return skill_id.capitalize()

func _on_skill_pressed(skill_id: String) -> void:
	var player = CharacterSystem.get_player()
	if player.is_empty():
		return

	var current_level = player.get("skills", {}).get(skill_id, 0)
	var cost = CharacterSystem.SKILL_COSTS[current_level + 1] if current_level < 5 else 0

	if current_level >= 5:
		print("Skill already at max level")
		return

	if player.get("xp", 0) < cost:
		print("Not enough XP (need %d)" % cost)
		return

	CharacterSystem.upgrade_skill(player, skill_id)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()

func _exit_tree() -> void:
	# Clean up tooltip CanvasLayer (frees tooltip too since it's a child)
	if item_tooltip and is_instance_valid(item_tooltip):
		var tooltip_parent = item_tooltip.get_parent()
		if tooltip_parent and tooltip_parent is CanvasLayer:
			tooltip_parent.queue_free()
		else:
			item_tooltip.queue_free()
	if perk_popup and is_instance_valid(perk_popup):
		perk_popup.queue_free()


# ============================================
# PERK SELECTION POPUP
# ============================================

## Element color lookup for cross-skill perks (uses the skill's element)
func _get_perk_element_color(perk_entry: Dictionary) -> Color:
	var data = perk_entry.get("data", {})
	if perk_entry.get("source", "") == "skill":
		var skill_id = data.get("skill", "")
		for element in ELEMENT_SKILLS:
			if skill_id in ELEMENT_SKILLS[element]:
				return ELEMENT_COLORS[element]
	# Cross-skill perks: use a gold color
	return Color(0.85, 0.75, 0.4)

func _on_perk_selection_requested(character: Dictionary, perks: Array) -> void:
	## Show the perk selection popup with up to 4 perk cards.
	if perks.is_empty():
		return

	pending_perk_character = character
	_show_perk_popup(perks)

func _show_perk_popup(perks: Array) -> void:
	## Build and display the perk selection popup overlay.
	# Clean up any existing popup
	if perk_popup and is_instance_valid(perk_popup):
		perk_popup.queue_free()

	# Full-screen overlay that blocks input to the rest of the UI
	perk_popup = Control.new()
	perk_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().root.add_child.call_deferred(perk_popup)

	# Semi-transparent dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.02, 0.08, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	perk_popup.add_child(bg)

	# Center container for the popup content
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_popup.add_child(center)

	# Main popup panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 500)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.08, 0.15)
	panel_style.border_color = Color(0.75, 0.6, 0.2)  # Gold border
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Choose a Perk"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select one of the following perks for " + pending_perk_character.get("name", "")
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Perk cards in a horizontal row
	var cards_container = HBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 12)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_container)

	for perk_entry in perks:
		var card = _create_perk_card(perk_entry)
		cards_container.add_child(card)

	# Skip button (in case player doesn't want any)
	var skip_btn = Button.new()
	skip_btn.text = "Skip"
	skip_btn.custom_minimum_size = Vector2(120, 32)
	skip_btn.add_theme_font_size_override("font_size", 13)
	skip_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	skip_btn.pressed.connect(_on_perk_skipped)
	var skip_container = HBoxContainer.new()
	skip_container.alignment = BoxContainer.ALIGNMENT_CENTER
	skip_container.add_child(skip_btn)
	vbox.add_child(skip_container)

func _create_perk_card(perk_entry: Dictionary) -> PanelContainer:
	## Create a single perk card for the selection popup.
	var perk_id = perk_entry.get("id", "")
	var data = perk_entry.get("data", {})
	var source = perk_entry.get("source", "skill")
	var accent_color = _get_perk_element_color(perk_entry)

	# Card panel
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 280)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.11, 0.18)
	card_style.border_color = accent_color.darkened(0.3)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(6)
	card_style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", card_style)

	# Make the card clickable via a transparent button overlay
	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = accent_color * Color(1, 1, 1, 0.1)
	hover_style.border_color = accent_color
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	click_btn.add_theme_stylebox_override("hover", hover_style)
	var normal_style = StyleBoxEmpty.new()
	click_btn.add_theme_stylebox_override("normal", normal_style)
	click_btn.add_theme_stylebox_override("pressed", hover_style)
	click_btn.add_theme_stylebox_override("focus", normal_style)
	click_btn.pressed.connect(_on_perk_selected.bind(perk_id))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)

	# Perk name
	var name_label = Label.new()
	name_label.text = data.get("name", perk_id)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", accent_color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(name_label)

	# Source tag (skill name or "Cross-Skill")
	var source_label = Label.new()
	if source == "skill":
		var skill_name = data.get("skill", "").replace("_", " ").capitalize()
		source_label.text = skill_name + " " + str(data.get("required_level", 1))
	else:
		source_label.text = "Cross-Skill"
	source_label.add_theme_font_size_override("font_size", 11)
	source_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(source_label)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", accent_color.darkened(0.5))
	content.add_child(sep)

	# Description
	var desc_label = RichTextLabel.new()
	desc_label.text = data.get("description", "No description")
	desc_label.fit_content = true
	desc_label.custom_minimum_size = Vector2(176, 120)
	desc_label.add_theme_font_size_override("normal_font_size", 12)
	desc_label.add_theme_color_override("default_color", Color(0.85, 0.82, 0.78))
	desc_label.scroll_active = false
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(desc_label)

	# Flavor text (if any)
	var flavor = data.get("flavor", "")
	if flavor != "":
		var flavor_label = Label.new()
		flavor_label.text = flavor
		flavor_label.add_theme_font_size_override("font_size", 11)
		flavor_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
		flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		content.add_child(flavor_label)

	# Mantra indicator
	if data.get("is_mantra", false):
		var mantra_label = Label.new()
		mantra_label.text = "~ Mantra ~"
		mantra_label.add_theme_font_size_override("font_size", 11)
		mantra_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
		mantra_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(mantra_label)

	# Add the click button on top of everything
	card.add_child(click_btn)

	return card

func _on_perk_selected(perk_id: String) -> void:
	## Handle player selecting a perk from the popup.
	if pending_perk_character.is_empty():
		return

	PerkSystem.grant_perk(pending_perk_character, perk_id)
	pending_perk_character = {}

	# Close popup
	if perk_popup and is_instance_valid(perk_popup):
		perk_popup.queue_free()
		perk_popup = null

	# Refresh display to show updated stats
	_refresh_display()

func _on_perk_skipped() -> void:
	## Handle player skipping the perk selection.
	pending_perk_character = {}
	if perk_popup and is_instance_valid(perk_popup):
		perk_popup.queue_free()
		perk_popup = null


# ============================================
# EQUIPMENT TAB
# ============================================

var _doll_initialized := false

func _setup_equipment_doll() -> void:
	if _doll_initialized:
		return
	_doll_initialized = true

	# Clear any existing children
	for child in doll_layout.get_children():
		child.queue_free()

	# Wait a frame for the layout to have its size
	await get_tree().process_frame

	var doll_size = doll_layout.size
	var center_x = doll_size.x / 2
	var slot_size = Vector2(52, 52)
	var small_slot = Vector2(44, 44)

	# Create the humanoid outline (simple visual)
	var outline = _create_humanoid_outline(doll_size)
	doll_layout.add_child(outline)

	# Position slots on the humanoid figure
	# Head - top center
	_create_equipment_slot("head", Vector2(center_x - slot_size.x/2, 10), slot_size)

	# Chest - upper middle
	_create_equipment_slot("chest", Vector2(center_x - slot_size.x/2, 75), slot_size)

	# Hands - left and right of chest
	_create_equipment_slot("hand_l", Vector2(center_x - slot_size.x/2 - 65, 80), slot_size)
	_create_equipment_slot("hand_r", Vector2(center_x + slot_size.x/2 + 13, 80), slot_size)

	# Legs - below chest
	_create_equipment_slot("legs", Vector2(center_x - slot_size.x/2, 140), slot_size)

	# Feet - bottom center
	_create_equipment_slot("feet", Vector2(center_x - slot_size.x/2, 205), slot_size)

	# Magic item slots - closer to the figure, flanking head/chest area
	_create_equipment_slot("ring1", Vector2(center_x - slot_size.x/2 - 60, 15), small_slot)
	_create_equipment_slot("amulet", Vector2(center_x + slot_size.x/2 + 16, 15), small_slot)
	_create_equipment_slot("ring2", Vector2(center_x - slot_size.x/2 - 60, 145), small_slot)
	_create_equipment_slot("trinket", Vector2(center_x + slot_size.x/2 + 16, 145), small_slot)

	# Weapon slots - below the figure
	_create_equipment_slot("weapon_main", Vector2(center_x - slot_size.x - 10, 270), slot_size)
	_create_equipment_slot("weapon_off", Vector2(center_x + 10, 270), slot_size)

	# Weapon set buttons (I and II)
	var set_btn_size = Vector2(40, 30)
	var set1_btn = Button.new()
	set1_btn.text = "I"
	set1_btn.custom_minimum_size = set_btn_size
	set1_btn.size = set_btn_size
	set1_btn.position = Vector2(center_x - slot_size.x - 10, 330)
	set1_btn.tooltip_text = "Weapon Set 1"
	set1_btn.pressed.connect(_on_weapon_set_pressed.bind(1))
	doll_layout.add_child(set1_btn)

	var set2_btn = Button.new()
	set2_btn.text = "II"
	set2_btn.custom_minimum_size = set_btn_size
	set2_btn.size = set_btn_size
	set2_btn.position = Vector2(center_x + 10 + slot_size.x - set_btn_size.x, 330)
	set2_btn.tooltip_text = "Weapon Set 2"
	set2_btn.pressed.connect(_on_weapon_set_pressed.bind(2))
	doll_layout.add_child(set2_btn)

	# Store references for highlighting
	equipment_slot_buttons["weapon_set_1"] = set1_btn
	equipment_slot_buttons["weapon_set_2"] = set2_btn

	# Highlight current weapon set
	_update_weapon_set_buttons()

func _create_humanoid_outline(size: Vector2) -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Simple humanoid shape using lines/shapes
	var draw_node = Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.set_script(load("res://scripts/ui/humanoid_outline.gd") if ResourceLoader.exists("res://scripts/ui/humanoid_outline.gd") else null)
	container.add_child(draw_node)

	# If no script, just add a label placeholder
	if draw_node.get_script() == null:
		var center_x = size.x / 2
		# Head circle placeholder
		var head_label = Label.new()
		head_label.text = "◯"
		head_label.add_theme_font_size_override("font_size", 40)
		head_label.position = Vector2(center_x - 15, -5)
		head_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		container.add_child(head_label)

		# Body placeholder
		var body_label = Label.new()
		body_label.text = "│\n┼\n│\n╱╲"
		body_label.add_theme_font_size_override("font_size", 30)
		body_label.position = Vector2(center_x - 12, 45)
		body_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		container.add_child(body_label)

	return container

func _create_equipment_slot(slot_id: String, pos: Vector2, size: Vector2) -> void:
	var slot_info = EQUIPMENT_SLOTS.get(slot_id, {"name": slot_id.capitalize(), "types": []})

	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.size = size
	btn.position = pos
	btn.tooltip_text = slot_info.name

	# Style the button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.18)
	style_normal.border_color = Color(0.35, 0.35, 0.4)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.2, 0.25)
	style_hover.border_color = Color(0.5, 0.5, 0.55)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.25, 0.25, 0.3)
	style_pressed.border_color = Color(0.6, 0.5, 0.3)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	# Short label for the slot
	var short_labels := {
		"head": "HEAD",
		"chest": "BODY",
		"hand_l": "L",
		"hand_r": "R",
		"legs": "LEGS",
		"feet": "FEET",
		"weapon_main": "MAIN",
		"weapon_off": "OFF",
		"ring1": "R1",
		"ring2": "R2",
		"amulet": "AMU",
		"trinket": "TRI"
	}
	btn.text = short_labels.get(slot_id, "?")
	btn.add_theme_font_size_override("font_size", 10)

	btn.pressed.connect(_on_equipment_slot_pressed.bind(slot_id))

	equipment_slot_buttons[slot_id] = btn
	doll_layout.add_child(btn)

func _on_equipment_slot_pressed(slot_id: String) -> void:
	var player = CharacterSystem.get_player()

	# If slot has an item equipped, offer to unequip on double-click or show items
	var equipped_item_id = ""
	if not player.is_empty():
		equipped_item_id = ItemSystem.get_equipped_item(player, slot_id)

	# If clicking already selected slot with equipped item, unequip it
	if selected_equipment_slot == slot_id and equipped_item_id != "":
		ItemSystem.unequip_item(player, slot_id)
		_update_equipment_slots()
		_update_equipment_display()
		return

	selected_equipment_slot = slot_id
	var slot_info = EQUIPMENT_SLOTS.get(slot_id, {"name": slot_id.capitalize()})
	slot_title.text = slot_info.name.to_upper() + " ITEMS"
	_update_equipment_display()

	# Highlight the selected slot
	for sid in equipment_slot_buttons:
		if sid.begins_with("weapon_set_"):
			continue  # Skip weapon set buttons
		var btn = equipment_slot_buttons[sid]
		if sid == slot_id:
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		else:
			btn.remove_theme_color_override("font_color")

## Update equipment slot buttons to show equipped items
func _update_equipment_slots() -> void:
	var player = CharacterSystem.get_player()
	if player.is_empty():
		return

	# Short labels for empty slots
	var short_labels := {
		"head": "HEAD",
		"chest": "BODY",
		"hand_l": "L",
		"hand_r": "R",
		"legs": "LEGS",
		"feet": "FEET",
		"weapon_main": "MAIN",
		"weapon_off": "OFF",
		"ring1": "R1",
		"ring2": "R2",
		"amulet": "AMU",
		"trinket": "TRI"
	}

	for slot_id in equipment_slot_buttons:
		if slot_id.begins_with("weapon_set_"):
			continue

		var btn = equipment_slot_buttons[slot_id]
		var equipped_item_id = ItemSystem.get_equipped_item(player, slot_id)

		# Disconnect old hover signals if any
		if btn.mouse_entered.is_connected(_on_equipped_slot_hover):
			btn.mouse_entered.disconnect(_on_equipped_slot_hover)
		if btn.mouse_exited.is_connected(_on_item_hover_end):
			btn.mouse_exited.disconnect(_on_item_hover_end)

		if equipped_item_id != "":
			var item = ItemSystem.get_item(equipped_item_id)
			var name = item.get("name", "?")
			var abbrev = name.substr(0, 4).to_upper() if name.length() > 4 else name.to_upper()
			btn.text = abbrev
			btn.tooltip_text = ""  # Use custom tooltip instead

			# Color by rarity
			var rarity_color = ItemSystem.get_rarity_color(equipped_item_id)
			btn.add_theme_color_override("font_color", rarity_color)

			# Update style to show item equipped — brighter bg + colored border
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.22, 0.22, 0.28)
			style.border_color = rarity_color.darkened(0.1)
			style.set_border_width_all(3)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)

			var hover_style = StyleBoxFlat.new()
			hover_style.bg_color = Color(0.28, 0.28, 0.35)
			hover_style.border_color = rarity_color
			hover_style.set_border_width_all(3)
			hover_style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("hover", hover_style)

			# Connect hover for tooltip
			btn.mouse_entered.connect(_on_equipped_slot_hover.bind(slot_id, btn))
			btn.mouse_exited.connect(_on_item_hover_end)
		else:
			btn.text = short_labels.get(slot_id, "?")
			btn.tooltip_text = EQUIPMENT_SLOTS.get(slot_id, {}).get("name", slot_id)
			btn.remove_theme_color_override("font_color")

			# Reset to default style
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.18)
			style.border_color = Color(0.35, 0.35, 0.4)
			style.set_border_width_all(2)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)

## Show tooltip for equipped item in slot
func _on_equipped_slot_hover(slot_id: String, control: Control) -> void:
	var player = CharacterSystem.get_player()
	if player.is_empty():
		return

	var equipped_item_id = ItemSystem.get_equipped_item(player, slot_id)
	if equipped_item_id != "":
		var item = ItemSystem.get_item(equipped_item_id)
		if item_tooltip and not item.is_empty():
			var mouse_pos = get_global_mouse_position()
			item_tooltip.show_item(item, mouse_pos)

func _on_weapon_set_pressed(set_num: int) -> void:
	current_weapon_set = set_num
	_update_weapon_set_buttons()

	# Update character's active weapon set
	var player = CharacterSystem.get_player()
	if not player.is_empty():
		ItemSystem.set_weapon_set(player, set_num)
		_update_equipment_slots()

func _update_weapon_set_buttons() -> void:
	var set1_btn = equipment_slot_buttons.get("weapon_set_1")
	var set2_btn = equipment_slot_buttons.get("weapon_set_2")

	if set1_btn:
		if current_weapon_set == 1:
			set1_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.22, 0.15)
			style.border_color = Color(0.8, 0.7, 0.3)
			style.set_border_width_all(2)
			style.set_corner_radius_all(3)
			set1_btn.add_theme_stylebox_override("normal", style)
		else:
			set1_btn.remove_theme_color_override("font_color")
			set1_btn.remove_theme_stylebox_override("normal")

	if set2_btn:
		if current_weapon_set == 2:
			set2_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.22, 0.15)
			style.border_color = Color(0.8, 0.7, 0.3)
			style.set_border_width_all(2)
			style.set_corner_radius_all(3)
			set2_btn.add_theme_stylebox_override("normal", style)
		else:
			set2_btn.remove_theme_color_override("font_color")
			set2_btn.remove_theme_stylebox_override("normal")

func _update_equipment_display() -> void:
	# Clear existing items
	for child in equipment_grid.get_children():
		child.queue_free()

	if selected_equipment_slot == "":
		# Show hint to select a slot
		var hint = Label.new()
		hint.text = "Click an equipment slot\nto see available items"
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipment_grid.add_child(hint)
		return

	# Get items from inventory that can be equipped to this slot
	var matching_items = ItemSystem.get_inventory_items_for_slot(selected_equipment_slot)

	if matching_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No items available\nfor this slot"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipment_grid.add_child(empty_label)
	else:
		for item in matching_items:
			var item_btn = _create_equipment_item_button(item)
			equipment_grid.add_child(item_btn)

func _create_equipment_item_button(item: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(60, 60)

	# Show abbreviated name
	var name = item.get("name", "?")
	var abbrev = name.substr(0, 3).to_upper() if name.length() > 3 else name.to_upper()
	btn.text = abbrev
	btn.add_theme_font_size_override("font_size", 10)

	# Disable default tooltip (we use custom tooltip)
	btn.tooltip_text = ""

	# Style based on rarity
	var rarity_color = ItemSystem.get_rarity_color(item.get("id", ""))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_color = rarity_color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.25)
	hover_style.border_color = rarity_color
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)

	# Text color matches rarity
	btn.add_theme_color_override("font_color", rarity_color)

	btn.pressed.connect(_on_equipment_item_pressed.bind(item))

	# Connect hover signals for tooltip
	btn.mouse_entered.connect(_on_item_hover.bind(item, btn))
	btn.mouse_exited.connect(_on_item_hover_end)

	return btn

func _on_equipment_item_pressed(item: Dictionary) -> void:
	var player = CharacterSystem.get_player()
	if player.is_empty():
		return

	var item_id = item.get("id", "")
	if item_id == "":
		return

	# Check if player can equip
	var can_result = ItemSystem.can_equip(player, item_id)
	if not can_result.can_equip:
		print("Cannot equip: ", can_result.reason)
		return

	# Equip the item
	if ItemSystem.equip_item(player, item_id, selected_equipment_slot):
		print("Equipped ", item.get("name", ""), " to ", selected_equipment_slot)
		_update_equipment_slots()
		_update_equipment_display()

	# Hide tooltip after equipping
	_on_item_hover_end()

## Show item tooltip on hover
func _on_item_hover(item: Dictionary, control: Control) -> void:
	if item_tooltip and not item.is_empty():
		var mouse_pos = get_global_mouse_position()
		item_tooltip.show_item(item, mouse_pos)

## Hide item tooltip
func _on_item_hover_end() -> void:
	if item_tooltip:
		item_tooltip.hide_tooltip()

# ============================================
# PARTY TAB
# ============================================

func _update_party_list() -> void:
	# Clear existing
	for child in party_list.get_children():
		child.queue_free()

	var party = CharacterSystem.get_party()

	for character in party:
		var card = _create_party_card(character)
		party_list.add_child(card)

	# If party is empty, show placeholder
	if party.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No party members"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		party_list.add_child(empty_label)

func _create_party_card(character: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Name and XP row
	var header_row = HBoxContainer.new()
	vbox.add_child(header_row)

	var name_label = Label.new()
	name_label.text = character.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_label)

	var xp_label = Label.new()
	xp_label.text = "XP: " + str(character.get("xp", 0))
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header_row.add_child(xp_label)

	# Stats bars row
	var bars_row = HBoxContainer.new()
	bars_row.add_theme_constant_override("separation", 15)
	vbox.add_child(bars_row)

	var derived = character.get("derived_stats", {})
	var attrs = character.get("attributes", {})

	# HP bar (red) - use Constitution * 10 as fallback if derived not set
	var max_hp = derived.get("max_hp", attrs.get("constitution", 10) * 10)
	var current_hp = character.get("current_hp", max_hp)
	bars_row.add_child(_create_stat_bar("HP", current_hp, max_hp, Color(0.8, 0.2, 0.2)))

	# Mana bar (blue) - use Awareness * 5 as fallback
	var max_mana = derived.get("max_mana", attrs.get("awareness", 10) * 5)
	var current_mana = character.get("current_mana", max_mana)
	bars_row.add_child(_create_stat_bar("MP", current_mana, max_mana, Color(0.2, 0.4, 0.9)))

	# Stamina bar (yellow) - use (Con + Fin) / 2 * 5 as fallback
	var max_stamina = derived.get("max_stamina", ((attrs.get("constitution", 10) + attrs.get("finesse", 10)) / 2) * 5)
	var current_stamina = character.get("current_stamina", max_stamina)
	bars_row.add_child(_create_stat_bar("ST", current_stamina, max_stamina, Color(0.9, 0.75, 0.2)))

	return card

func _create_stat_bar(label_text: String, current: int, maximum: int, color: Color) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.custom_minimum_size.x = 20
	container.add_child(label)

	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.15, 0.15, 0.15)
	bar_bg.custom_minimum_size = Vector2(80, 14)
	container.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.color = color
	var fill_ratio = float(current) / float(maximum) if maximum > 0 else 0.0
	bar_fill.custom_minimum_size = Vector2(80 * fill_ratio, 14)
	bar_fill.position = Vector2.ZERO
	bar_bg.add_child(bar_fill)

	var value_label = Label.new()
	value_label.text = "%d/%d" % [current, maximum]
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.custom_minimum_size.x = 50
	container.add_child(value_label)

	return container

func _update_followers_list() -> void:
	# Clear existing
	for child in followers_list.get_children():
		child.queue_free()

	# TODO: Get actual followers from a system (e.g., GameState.get_followers())
	# For now, show empty placeholder
	var followers: Array = []  # Will be populated from game system

	for follower in followers:
		var card = _create_follower_card(follower)
		followers_list.add_child(card)

	# If no followers, show placeholder
	if followers.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No camp followers"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		followers_list.add_child(empty_label)

func _create_follower_card(follower: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 50)

	# Slightly different style for followers (less prominent)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15)
	style.border_color = Color(0.25, 0.25, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	# Name row
	var name_label = Label.new()
	name_label.text = follower.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# Role/bonus description
	var role_label = Label.new()
	role_label.text = follower.get("role", "Follower")
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(role_label)

	# Passive bonus
	var bonus = follower.get("bonus_description", "")
	if bonus != "":
		var bonus_label = Label.new()
		bonus_label.text = bonus
		bonus_label.add_theme_font_size_override("font_size", 10)
		bonus_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
		vbox.add_child(bonus_label)

	return card

func _update_inventory() -> void:
	# Clear existing
	for child in inventory_grid.get_children():
		child.queue_free()

	# Get actual inventory items
	var inventory = ItemSystem.get_inventory_with_details()

	# Add item slots
	for item in inventory:
		var slot = _create_inventory_slot(item)
		inventory_grid.add_child(slot)

	# Fill remaining slots with empty placeholders (up to 24 visible)
	var empty_slots = max(0, 24 - inventory.size())
	for i in range(empty_slots):
		var slot = _create_inventory_slot(null)
		inventory_grid.add_child(slot)

func _create_inventory_slot(item: Variant) -> Control:
	if item != null and item is Dictionary:
		# Use a button for items so we get proper hover detection
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(50, 50)

		var item_id = item.get("id", "")
		var rarity_color = ItemSystem.get_rarity_color(item_id) if item_id != "" else Color.WHITE

		# Show abbreviated name
		var name = item.get("name", "?")
		btn.text = name.substr(0, 3).to_upper() if name.length() > 3 else name.to_upper()
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", rarity_color)

		# Disable default tooltip
		btn.tooltip_text = ""

		# Style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.18)
		style.border_color = rarity_color.darkened(0.3)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.2, 0.25)
		hover_style.border_color = rarity_color
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover_style)

		# Connect hover signals for tooltip
		btn.mouse_entered.connect(_on_item_hover.bind(item, btn))
		btn.mouse_exited.connect(_on_item_hover_end)

		return btn
	else:
		# Empty slot - just a panel
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(50, 50)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.15)
		style.border_color = Color(0.3, 0.3, 0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)

		return slot
