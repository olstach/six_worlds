extends Control
## Main Menu - Tabbed interface for character management
##
## Tab structure:
## 1. Stats - Attributes, derived stats, skills grid, perks list
## 2. Equipment - Gear slots and inventory
## 3. Party - Party member management
## 4. Spellbook - Known spells grouped by level

signal tab_changed(tab_index: int)
signal overworld_spell_cast(spell_name: String, detail: String)

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
@onready var perks_container: VBoxContainer = %PerksContainer
@onready var spellbook_list: VBoxContainer = %SpellbookList
@onready var spell_filter_bar: HBoxContainer = %SpellFilterBar
@onready var crafter_panel: HBoxContainer = %CrafterPanel
@onready var craft_filter_bar: HBoxContainer = %CraftFilterBar
@onready var crafting_list: VBoxContainer = %CraftingList
@onready var party_list: VBoxContainer = %PartyList
@onready var followers_list: VBoxContainer = %FollowersList
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var doll_layout: Control = %DollLayout
@onready var slot_title: Label = %SlotTitle
@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var character_selector_panel: HBoxContainer = %CharacterSelectorPanel
@onready var free_xp_row: HBoxContainer = %FreeXPRow
@onready var free_xp_value: Label = %FreeXPValue
@onready var autodevelop_toggle: CheckButton = %AutodevelopToggle

# Currently displayed character (player or companion)
var _current_character: Dictionary = {}
var _selector_group: ButtonGroup = null

var _journal_list: VBoxContainer = null     # Left-panel quest title buttons
var _journal_detail: RichTextLabel = null   # Right-panel quest details
var _journal_selected_id: String = ""       # Currently selected quest id

# Equipment slot definitions
const EQUIPMENT_SLOTS := {
	"head": {"name": "Head", "types": ["helmet", "hat", "circlet"]},
	"chest": {"name": "Chest", "types": ["armor", "robe", "vest"]},
	"hand_l": {"name": "Hands", "types": ["gloves", "gauntlets", "bracers"]},
	"hand_r": {"name": "Hands", "types": ["gloves", "gauntlets", "bracers"]},
	"legs": {"name": "Legs", "types": ["pants", "greaves", "leggings"]},
	"feet": {"name": "Feet", "types": ["boots", "shoes", "sandals"]},
	"weapon_main": {"name": "Main Hand", "types": ["sword", "axe", "mace", "spear", "dagger", "staff", "bow"]},
	"weapon_off": {"name": "Off Hand", "types": ["sword", "dagger", "shield"]},
	"ring1": {"name": "Ring", "types": ["ring"]},
	"ring2": {"name": "Ring", "types": ["ring"]},
	"trinket1": {"name": "Trinket", "types": ["trinket", "talisman", "amulet", "necklace"]},
	"trinket2": {"name": "Trinket", "types": ["trinket", "talisman", "amulet", "necklace"]}
}

var selected_equipment_slot: String = ""
var equipment_slot_buttons := {}
var current_weapon_set: int = 1  # 1 or 2

# Perk selection popup - uses its own CanvasLayer to render above CharSheetOverlay (layer 15)
var perk_popup_layer: CanvasLayer = null
var perk_popup: Control = null
var pending_perk_character: Dictionary = {}  # Character waiting for perk selection

# Item tooltip
var item_tooltip: Control = null
const ITEM_TOOLTIP_SCENE = preload("res://scenes/ui/item_tooltip.tscn")

# Spell database for spellbook display
var _spell_database: Dictionary = {}

# Spellbook filter state — active school/subschool filters (AND logic)
var _spell_filters: Dictionary = {}  # filter_name -> bool (true = active)
var _spell_filter_buttons: Dictionary = {}  # filter_name -> Button reference
var _spell_filters_built := false

# Schools are stored in spells.json "schools" array; subschools in "subschool" field
const SPELL_SCHOOLS: Array[String] = ["Space", "Air", "Fire", "Water", "Earth", "White", "Black"]
const SPELL_SUBSCHOOLS: Array[String] = ["Sorcery", "Enchantment", "Summoning"]

# Crafting tab state
var _craft_tiers: Dictionary = {}           # Loaded from supplies.json alchemy_crafting_tiers
var _craft_filter: String = ""              # Active category: "" = all, or remedies/munitions/applications
var _craft_character: Dictionary = {}       # Selected alchemist character
var _craft_filter_buttons: Dictionary = {}  # category -> Button reference
var _craft_built: bool = false              # True after first build

# Map crafting categories to display names
const CRAFT_CATEGORY_LABELS := {
	"remedies": "Potions",
	"munitions": "Bombs",
	"applications": "Oils"
}
# Water-element color for alchemy (alchemy is a Water skill)
const CRAFT_COLOR := Color(0.5, 0.82, 0.98)

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
	"earth": ["maces", "armor", "earth_magic", "summoning", "logistics", "trade", "smithing"]
}

# Element colors for visual distinction
const ELEMENT_COLORS := {
	"space": Color(0.6, 0.3, 0.9),   # Deep purple
	"air": Color(0.2, 0.85, 0.35),   # Vibrant green
	"fire": Color(0.95, 0.2, 0.15),  # Red
	"water": Color(0.5, 0.82, 0.98), # Light blue
	"earth": Color(0.85, 0.72, 0.15) # Golden yellow
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
	# Rename the first tab to "Character" (node is named "Stats" in the scene)
	tab_container.set_tab_title(0, "Character")

	# Journal tab — two-panel: title list on left, details on right
	var journal_root := HSplitContainer.new()
	journal_root.name = "Journal"
	journal_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_root.split_offset = 200  # left panel ~200px wide

	# Left: scrollable list of quest titles
	var journal_list_scroll := ScrollContainer.new()
	journal_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_list_scroll.custom_minimum_size = Vector2(180, 0)
	_journal_list = VBoxContainer.new()
	_journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_list.add_theme_constant_override("separation", 4)
	journal_list_scroll.add_child(_journal_list)
	journal_root.add_child(journal_list_scroll)

	# Right: detail panel (RichTextLabel + padding)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = Color(0.08, 0.07, 0.06)
	dp_style.content_margin_left = 12
	dp_style.content_margin_right = 12
	dp_style.content_margin_top = 10
	dp_style.content_margin_bottom = 10
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	_journal_detail = RichTextLabel.new()
	_journal_detail.bbcode_enabled = true
	_journal_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_journal_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_detail.scroll_active = true
	_journal_detail.text = "[color=#666666]Select a quest to view details.[/color]"
	detail_panel.add_child(_journal_detail)
	journal_root.add_child(detail_panel)

	tab_container.add_child(journal_root)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Journal")

	# Connect debug button
	add_xp_button.pressed.connect(_on_add_xp_pressed)

	# Connect companion-only UI
	autodevelop_toggle.toggled.connect(_on_autodevelop_toggled)

	# Load spell database for spellbook tab
	_load_spell_database()

	# Initialize character selector
	_current_character = CharacterSystem.get_player()
	_build_character_selector()
	CompanionSystem.companion_recruited.connect(_on_companion_recruited)

	# Add starter items if inventory is empty
	if ItemSystem.get_inventory().is_empty():
		var player = CharacterSystem.get_player()
		ItemSystem.add_starter_items(player.get("background", ""))
	# Consolidate any fragmented consumable stacks (fixes older inventory data)
	ItemSystem.consolidate_inventory()

	# Create item tooltip on a high CanvasLayer so it renders above all overlays
	var tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 100
	get_tree().root.add_child.call_deferred(tooltip_layer)
	item_tooltip = ITEM_TOOLTIP_SCENE.instantiate()
	tooltip_layer.add_child.call_deferred(item_tooltip)

	# Initial display
	_refresh_display()

## Called by overworld to open a specific tab (0=Stats, 1=Equipment, 2=Party, 3=Spellbook)
func open_to_tab(tab_index: int) -> void:
	tab_container.current_tab = tab_index

func get_current_tab() -> int:
	return tab_container.current_tab

func _on_tab_changed(tab: int) -> void:
	AudioManager.play("ui_click")
	tab_changed.emit(tab)
	# Refresh equipment tab when switching to it (tab index 1)
	if tab == 1:
		# await the doll setup — it has an internal await get_tree().process_frame
		# that creates the slot nodes; without awaiting, the slots don't exist yet
		# when _update_equipment_slots() runs, so everything appears empty.
		await _setup_equipment_doll()
		# Sync UI weapon set selector to match the character's actual active set
		if _current_character:
			current_weapon_set = _current_character.get("active_weapon_set", 1)
		_update_equipment_slots()
		_update_equipment_display()
	# Refresh party tab when switching to it (tab index 2)
	elif tab == 2:
		_update_party_list()
		_update_followers_list()
		_update_inventory()
	# Refresh spellbook tab when switching to it (tab index 3)
	elif tab == 3:
		_build_spell_filters()
		_update_spellbook()
	# Refresh crafting tab when switching to it (tab index 4)
	elif tab == 4:
		_load_craft_tiers()
		_build_craft_filters()
		_update_crafting_tab()
	# Refresh journal tab when switching to it (tab index 5)
	elif tab == 5:
		_update_journal_tab()

func _on_character_updated(_character: Dictionary) -> void:
	_refresh_display()

func _on_attribute_increased(_character: Dictionary, _attr_name: String, _new_value: int) -> void:
	_refresh_display()

func _on_skill_upgraded(_character: Dictionary, _skill_name: String, _new_level: int) -> void:
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
	var target := _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if target.is_empty():
		return
	CharacterSystem.grant_xp(target, 100)
	if target.has("free_xp"):
		target.free_xp += 100
	_refresh_stats_tab()

func _on_autodevelop_toggled(enabled: bool) -> void:
	if _current_character.has("autodevelop"):
		_current_character.autodevelop = enabled

func _refresh_display() -> void:
	# If no current character set yet, fall back to the player
	var character = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if character.is_empty():
		return

	_update_header(character)
	_update_attributes(character)
	_update_derived_stats(character)
	_update_skills_grid(character)
	_update_perks_list(character)
	_update_companion_ui(character)


func _update_companion_ui(character: Dictionary) -> void:
	## Show or hide companion-only UI elements (free_xp display, autodevelop toggle).
	var is_companion := character.has("companion_id")
	if free_xp_row != null:
		free_xp_row.visible = is_companion
		if is_companion:
			free_xp_value.text = str(int(character.get("free_xp", 0)))
	if autodevelop_toggle != null:
		autodevelop_toggle.visible = is_companion
		if is_companion:
			autodevelop_toggle.set_pressed_no_signal(character.get("autodevelop", false))

func _update_header(character: Dictionary) -> void:
	name_value.text = character.get("name", "Unknown")
	race_value.text = character.get("race", "Unknown").capitalize()
	background_value.text = character.get("background", "Unknown").capitalize()
	# Companions have a "free XP" pool (earned since joining, not yet spent).
	# Show that instead of raw character.xp, which gets reset by the XP-swap pattern.
	if character.has("companion_id"):
		xp_value.text = str(int(character.get("free_xp", 0)))
	else:
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

	# Upgrade button — for companions check free_xp, for player check xp
	var upgrade_btn = Button.new()
	var cost = CharacterSystem.calculate_attribute_cost(value, 1)
	upgrade_btn.text = "+  (%d XP)" % cost
	upgrade_btn.custom_minimum_size.x = 100
	upgrade_btn.pressed.connect(_on_attribute_upgrade_pressed.bind(attr_key))

	# Disable if can't afford
	var target = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	var is_companion := target.has("companion_id")
	var spendable: int = target.get("free_xp", 0) if is_companion else target.get("xp", 0)
	if spendable < cost:
		upgrade_btn.disabled = true

	row.add_child(upgrade_btn)

	return row

func _on_attribute_upgrade_pressed(attr_key: String) -> void:
	var target := _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if target.is_empty():
		return

	var is_companion := target.has("companion_id")
	if is_companion:
		# Companions spend free_xp; manually deduct it then call increase_attribute which deducts xp.
		# We temporarily set xp equal to free_xp so increase_attribute's check passes,
		# then deduct free_xp by the same cost afterward.
		var current_val = target.get("attributes", {}).get(attr_key, 10)
		var cost = CharacterSystem.calculate_attribute_cost(current_val, 1)
		if target.get("free_xp", 0) < cost:
			AudioManager.play("ui_denied")
			return
		# Perform the upgrade (deducts from xp)
		var old_xp: int = target.xp
		var old_free_xp: int = target.get("free_xp", 0)
		target.xp = cost  # Ensure xp check passes in CharacterSystem.increase_attribute
		target.free_xp = old_free_xp - cost  # Deduct BEFORE signals fire so UI reads correct value
		var success := CharacterSystem.increase_attribute(target, attr_key)
		if success:
			# Restore xp (free_xp already deducted above)
			target.xp = old_xp
			if CompanionSystem.is_companion_in_overflow(target):
				CompanionSystem.record_overflow_investment(target, attr_key)
			AudioManager.play("buff_stats_up")
			_refresh_stats_tab()
		else:
			target.xp = old_xp
			target.free_xp = old_free_xp  # Restore on failure
	else:
		AudioManager.play("buff_stats_up")
		CharacterSystem.increase_attribute(target, attr_key)

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
		["Crit", str(int(derived.get("crit_chance", 0))) + "%"],
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
		value_label.text = str(stat_info[1]) if stat_info[1] is String else str(int(stat_info[1]))
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
		affinity_label.text = "[" + str(int(affinities[element])) + "]"
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
	# For companions, the spendable pool is free_xp, not total xp
	var is_companion := character.has("companion_id")
	var char_xp = character.get("free_xp", 0) if is_companion else character.get("xp", 0)

	for skill_index in range(7):
		# Row number label
		var row_label = Label.new()
		row_label.text = str(skill_index + 1) + "."
		row_label.add_theme_font_size_override("font_size", 12)
		skills_grid.add_child(row_label)

		# Skills for each element
		for element in ELEMENT_SKILLS.keys():
			var skill_id = ELEMENT_SKILLS[element][skill_index]
			var trained = char_skills.get(skill_id, 0)

			# Sum item/race bonuses for this skill
			var bonus_sources = character.get("skill_bonuses", {}).get(skill_id, {})
			var bonus = 0
			for src in bonus_sources:
				bonus += int(bonus_sources[src])
			var effective = trained + bonus

			var skill_btn = Button.new()
			skill_btn.text = _format_skill_name(skill_id) + " [" + str(int(effective)) + "]"
			skill_btn.custom_minimum_size = Vector2(110, 28)
			skill_btn.add_theme_font_size_override("font_size", 11)

			# Color: yellow if boosted by item/race, element color if just trained, muted if 0
			if effective > 0:
				if bonus > 0:
					skill_btn.add_theme_color_override("font_color", Color.YELLOW)
				else:
					skill_btn.add_theme_color_override("font_color", ELEMENT_COLORS[element])

			# Tooltip: XP cost + what next level grants
			skill_btn.tooltip_text = _build_skill_tooltip(skill_id, trained, bonus, char_xp)

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


func _build_skill_tooltip(skill_id: String, trained: int, bonus: int, player_xp: int) -> String:
	## Build a tooltip string for a skill button showing cost and next-level bonuses.
	if trained >= CharacterSystem.SKILL_MAX_LEVEL:
		if bonus > 0:
			return "Max level (trained)\nItem/race bonus: +%d" % bonus
		return "Max level"

	var next_cost = CharacterSystem.SKILL_COSTS[trained + 1]
	var next_bonuses = PerkSystem.get_base_skill_bonuses_at_level(skill_id, trained + 1)

	var lines: Array[String] = []

	if bonus > 0:
		lines.append("Trained: %d | Bonus: +%d" % [trained, bonus])

	lines.append("XP to advance: %d (have %d)" % [next_cost, player_xp])

	if not next_bonuses.is_empty():
		lines.append("Next level grants: " + _format_bonus_preview(next_bonuses))

	return "\n".join(lines)


func _format_bonus_preview(bonuses: Dictionary) -> String:
	## Convert a bonus dict into a short human-readable string.
	## e.g. {"attack": 10.0, "damage": 7.0} -> "+10 accuracy, +7 damage"
	const BONUS_LABELS := {
		"attack": "accuracy",
		"damage": "damage",
		"crit_chance": "crit%",
		"armor_bonus": "armor",
		"damage_reduction_pct": "dmg resist%",
		"armor_penetration": "armor pierce",
		"spellpower": "spellpower",
		"mana_cost_reduction_pct": "mana cost%",
		"dodge_bonus": "dodge",
		"max_stamina": "stamina",
		"initiative_bonus": "initiative",
		"event_roll_bonus": "event bonus",
		"mental_resistance_pct": "mental resist%",
		"xp_gain_pct": "XP gain%",
		"heal_effectiveness_pct": "heal%",
		"melee_damage_bonus": "melee dmg",
		"gold_gain_pct": "gold%",
		"shop_discount_pct": "discount%",
		"gold_bonus_pct": "loot gold%",
		"stamina_recovery_bonus": "stamina regen",
		"potion_effectiveness_pct": "potion%",
		"equipment_quality_pct": "craft quality%",
		"mandala_bonus": "mandala%",
	}
	var parts: Array[String] = []
	for key in bonuses:
		var val = bonuses[key]
		if val == 0:
			continue
		var label = BONUS_LABELS.get(key, key)
		parts.append("+%s %s" % [str(int(val)), label])
	return ", ".join(parts) if not parts.is_empty() else "(no change)"

func _on_skill_pressed(skill_id: String) -> void:
	var target := _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if target.is_empty():
		return

	var current_level = target.get("skills", {}).get(skill_id, 0)

	if current_level >= CharacterSystem.SKILL_MAX_LEVEL:
		AudioManager.play("ui_denied")
		return

	var cost = CharacterSystem.SKILL_COSTS[current_level + 1]

	var is_companion := target.has("companion_id")
	if is_companion:
		# Companions spend free_xp for skill upgrades
		if target.get("free_xp", 0) < cost:
			AudioManager.play("ui_denied")
			return
		# upgrade_skill deducts from xp; set xp temporarily so the check passes
		var old_xp: int = target.xp
		var old_free_xp: int = target.get("free_xp", 0)
		target.xp = cost
		target.free_xp = old_free_xp - cost  # Deduct BEFORE signals fire so UI reads correct value
		var success := CharacterSystem.upgrade_skill(target, skill_id)
		if success:
			target.xp = old_xp
			# free_xp already deducted above
			if CompanionSystem.is_companion_in_overflow(target):
				CompanionSystem.record_overflow_investment(target, skill_id)
			AudioManager.play("buff_stats_up")
			_refresh_stats_tab()
		else:
			target.xp = old_xp
			target.free_xp = old_free_xp  # Restore on failure
	else:
		if target.get("xp", 0) < cost:
			AudioManager.play("ui_denied")
			return
		AudioManager.play("buff_stats_up")
		CharacterSystem.upgrade_skill(target, skill_id)

# ============================================
# PERKS LIST (Stats tab, below skills)
# ============================================

func _update_perks_list(character: Dictionary) -> void:
	## Display all acquired perks below the skills grid.
	for child in perks_container.get_children():
		child.queue_free()

	var character_perks = PerkSystem.get_character_perks(character)

	if character_perks.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No perks acquired"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 12)
		perks_container.add_child(empty_label)
		return

	for perk_entry in character_perks:
		var perk_id = perk_entry.get("id", "")
		var perk_data = perk_entry.get("data", {})

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Perk name colored by element
		var name_label = Label.new()
		name_label.text = perk_data.get("name", perk_id)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.custom_minimum_size.x = 160

		var skill_id = perk_data.get("skill", "")
		var color = Color(0.85, 0.75, 0.4)  # Gold default for cross-skill
		for element in ELEMENT_SKILLS:
			if skill_id in ELEMENT_SKILLS[element]:
				color = ELEMENT_COLORS[element]
				break
		name_label.add_theme_color_override("font_color", color)
		row.add_child(name_label)

		# Short description
		var desc_label = Label.new()
		desc_label.text = perk_data.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(desc_label)

		perks_container.add_child(row)


# ============================================
# SPELLBOOK TAB
# ============================================

func _load_spell_database() -> void:
	## Load spell data from spells.json for the spellbook display.
	var file_path = "res://resources/data/spells.json"
	if not FileAccess.file_exists(file_path):
		push_warning("Spellbook: spells.json not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_warning("Spellbook: Failed to parse spells.json")
		return
	_spell_database = json.get_data().get("spells", {})
	print("Spellbook: loaded ", _spell_database.size(), " spells")

func _get_school_color(school: String) -> Color:
	## Get display color for a spell school (elements + white/black).
	var lower = school.to_lower()
	if lower in ELEMENT_COLORS:
		return ELEMENT_COLORS[lower]
	match lower:
		"white": return Color(0.9, 0.85, 0.7)
		"black": return Color(0.6, 0.4, 0.7)
	return Color(0.7, 0.7, 0.7)

func _build_spell_filters() -> void:
	## Create the row of school/subschool toggle buttons (built once).
	if _spell_filters_built:
		return
	_spell_filters_built = true

	# Initialize all filters as inactive
	for school in SPELL_SCHOOLS:
		_spell_filters[school] = false
	for sub in SPELL_SUBSCHOOLS:
		_spell_filters[sub] = false
	_spell_filters["Overworld"] = false

	# "All" label
	var all_label = Label.new()
	all_label.text = "Filter:"
	all_label.add_theme_font_size_override("font_size", 12)
	all_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	spell_filter_bar.add_child(all_label)

	# School buttons
	for school in SPELL_SCHOOLS:
		var btn = _create_filter_button(school, _get_school_color(school))
		spell_filter_bar.add_child(btn)
		_spell_filter_buttons[school] = btn

	# Separator
	var sep = VSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	spell_filter_bar.add_child(sep)

	# Subschool buttons
	for sub in SPELL_SUBSCHOOLS:
		var btn = _create_filter_button(sub, Color(0.6, 0.6, 0.55))
		spell_filter_bar.add_child(btn)
		_spell_filter_buttons[sub] = btn

	# Overworld filter — separate from school/subschool filters
	var sep2 = VSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	spell_filter_bar.add_child(sep2)

	var ow_btn = _create_filter_button("Overworld", Color(0.35, 0.72, 0.45))
	spell_filter_bar.add_child(ow_btn)
	_spell_filter_buttons["Overworld"] = ow_btn

	# Clear all button
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.add_theme_font_size_override("font_size", 11)
	clear_btn.custom_minimum_size = Vector2(50, 26)
	clear_btn.pressed.connect(_on_spell_filter_clear)
	spell_filter_bar.add_child(clear_btn)

func _create_filter_button(filter_name: String, color: Color) -> Button:
	## Create a single toggle filter button for the spellbook.
	var btn = Button.new()
	btn.text = filter_name
	btn.toggle_mode = true
	btn.button_pressed = false
	btn.custom_minimum_size = Vector2(0, 26)
	btn.add_theme_font_size_override("font_size", 11)

	# Normal style (muted)
	var style_off = StyleBoxFlat.new()
	style_off.bg_color = Color(0.15, 0.13, 0.18)
	style_off.border_color = color.darkened(0.5)
	style_off.set_border_width_all(1)
	style_off.set_corner_radius_all(3)
	style_off.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", style_off)

	# Pressed/active style (bright)
	var style_on = StyleBoxFlat.new()
	style_on.bg_color = color.darkened(0.6)
	style_on.border_color = color
	style_on.set_border_width_all(2)
	style_on.set_corner_radius_all(3)
	style_on.set_content_margin_all(4)
	btn.add_theme_stylebox_override("pressed", style_on)

	# Hover
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.18, 0.22)
	style_hover.border_color = color.darkened(0.3)
	style_hover.set_border_width_all(1)
	style_hover.set_corner_radius_all(3)
	style_hover.set_content_margin_all(4)
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.toggled.connect(_on_spell_filter_toggled.bind(filter_name))
	return btn

func _on_spell_filter_toggled(is_active: bool, filter_name: String) -> void:
	AudioManager.play("ui_click")
	_spell_filters[filter_name] = is_active
	_update_spellbook()

func _on_spell_filter_clear() -> void:
	AudioManager.play("ui_click")
	for filter_name in _spell_filters:
		_spell_filters[filter_name] = false
	for filter_name in _spell_filter_buttons:
		_spell_filter_buttons[filter_name].button_pressed = false
	_update_spellbook()

func _spell_passes_filter(spell_data: Dictionary) -> bool:
	## Check if a spell matches all active filters (AND logic).
	## Schools filter: spell must contain ALL active school filters in its schools array.
	## Subschool filter: spell's subschool must match ALL active subschool filters
	## (in practice only one subschool filter can meaningfully be active).
	var active_schools: Array[String] = []
	var active_subs: Array[String] = []

	for school in SPELL_SCHOOLS:
		if _spell_filters.get(school, false):
			active_schools.append(school)
	for sub in SPELL_SUBSCHOOLS:
		if _spell_filters.get(sub, false):
			active_subs.append(sub)

	# No filters active = show all
	var overworld_active: bool = _spell_filters.get("Overworld", false)
	if active_schools.is_empty() and active_subs.is_empty() and not overworld_active:
		return true

	# Check school filters — spell must have ALL active schools
	var spell_schools = spell_data.get("schools", [])
	for required_school in active_schools:
		var found := false
		for s in spell_schools:
			if s.to_lower() == required_school.to_lower():
				found = true
				break
		if not found:
			return false

	# Check subschool filters — spell's subschool must match ALL active ones (AND)
	# Since a spell has only one subschool, selecting 2+ subschools will show nothing
	if not active_subs.is_empty():
		var spell_sub = spell_data.get("subschool", "").to_lower()
		for required_sub in active_subs:
			if spell_sub != required_sub.to_lower():
				return false

	# Overworld filter — spell must carry the out_of_combat tag
	if overworld_active:
		var tags: Array = spell_data.get("tags", [])
		if not "out_of_combat" in tags:
			return false

	return true

func _update_spellbook() -> void:
	## Populate the spellbook tab with all known spells grouped by level.
	for child in spellbook_list.get_children():
		child.queue_free()

	var character = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if character.is_empty():
		return

	var known_ids = CharacterSystem.get_known_spells(character)

	if known_ids.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No spells known"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 14)
		spellbook_list.add_child(empty_label)
		return

	# Reload spell database if it's empty (may not have loaded yet)
	if _spell_database.is_empty():
		_load_spell_database()

	# Group spells by level, applying active filters
	var spells_by_level := {}
	for spell_id in known_ids:
		var spell_data = _spell_database.get(spell_id, {})
		if spell_data.is_empty():
			continue
		if not _spell_passes_filter(spell_data):
			continue
		var level = int(spell_data.get("level", 1))
		if not spells_by_level.has(level):
			spells_by_level[level] = []
		spells_by_level[level].append({"id": spell_id, "data": spell_data})

	# Display by level
	var levels = spells_by_level.keys()
	levels.sort()

	if levels.is_empty():
		var msg = Label.new()
		if _has_any_filter_active():
			msg.text = "No spells match the current filters"
		else:
			msg.text = "Spells known but spell data not loaded"
		msg.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		msg.add_theme_font_size_override("font_size", 14)
		spellbook_list.add_child(msg)
		return

	for level in levels:
		# Tier header (e.g. "— Outer Circle —")
		var level_header = Label.new()
		var tier_name = CombatManager.SPELL_TIER_NAMES.get(int(level), "Circle %d" % int(level))
		level_header.text = "— %s —" % tier_name
		level_header.add_theme_font_size_override("font_size", 16)
		level_header.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		spellbook_list.add_child(level_header)

		for spell_entry in spells_by_level[level]:
			var card = _create_spell_card(spell_entry.id, spell_entry.data)
			spellbook_list.add_child(card)

		# Spacer between levels
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 6
		spellbook_list.add_child(spacer)

func _has_any_filter_active() -> bool:
	for filter_name in _spell_filters:
		if _spell_filters[filter_name]:
			return true
	return false

func _create_spell_card(spell_id: String, spell_data: Dictionary) -> PanelContainer:
	## Create a display card for a single spell in the spellbook.
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15)
	style.border_color = Color(0.3, 0.3, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Top row: spell name + schools + mana cost
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)

	# Spell name colored by primary school
	var schools = spell_data.get("schools", [])
	var primary_color = _get_school_color(schools[0]) if not schools.is_empty() else Color.WHITE

	var name_label = Label.new()
	name_label.text = spell_data.get("name", spell_id)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", primary_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_label)

	# Mana cost (right-aligned)
	var mana_label = Label.new()
	mana_label.text = str(int(spell_data.get("mana_cost", 0))) + " MP"
	mana_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9))
	mana_label.add_theme_font_size_override("font_size", 12)
	top_row.add_child(mana_label)

	# Tier display line (e.g. "Outer Circle of Cloud" or "Inner Circle of Fire")
	var tier_label = Label.new()
	tier_label.text = CombatManager.get_spell_tier_display(spell_data)
	tier_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	tier_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tier_label)

	# Skill requirements in grey (e.g. "Requires Water Magic 3, Air Magic 3 or Sorcery 3")
	var reqs = CombatManager.get_spell_skill_reqs(spell_data)
	if reqs != "":
		var reqs_label = Label.new()
		reqs_label.text = reqs
		reqs_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		reqs_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(reqs_label)

	# Cast button — shown for spells tagged out_of_combat (overworld-castable)
	var spell_tags: Array = spell_data.get("tags", [])
	if "out_of_combat" in spell_tags:
		var caster: Dictionary = _current_character if not _current_character.is_empty() \
				else CharacterSystem.get_player()
		var mana_cost: int = int(spell_data.get("mana_cost", 0))
		var can_cast: bool = caster.get("derived", {}).get("current_mana", 0) >= mana_cost

		var cast_btn = Button.new()
		cast_btn.text = "Cast"
		cast_btn.add_theme_font_size_override("font_size", 12)
		cast_btn.custom_minimum_size = Vector2(50, 24)
		cast_btn.disabled = not can_cast
		if not can_cast:
			cast_btn.tooltip_text = "Not enough mana (%d/%d MP)" % [
					caster.get("derived", {}).get("current_mana", 0), mana_cost]

		var cast_style = StyleBoxFlat.new()
		cast_style.bg_color    = Color(0.12, 0.28, 0.15) if can_cast else Color(0.18, 0.18, 0.18)
		cast_style.border_color = Color(0.3, 0.7, 0.35)  if can_cast else Color(0.35, 0.35, 0.35)
		cast_style.set_border_width_all(1)
		cast_style.set_corner_radius_all(3)
		cast_style.set_content_margin_all(4)
		cast_btn.add_theme_stylebox_override("normal", cast_style)

		cast_btn.pressed.connect(func():
			var derived_now: Dictionary = caster.get("derived", {})
			var mana_now: int = derived_now.get("current_mana", 0)
			if mana_now < mana_cost:
				AudioManager.play("ui_denied")
				return
			derived_now["current_mana"] = max(0, mana_now - mana_cost)
			AudioManager.play("spell_cast")
			var detail := _apply_overworld_spell(spell_id, spell_data, caster)
			overworld_spell_cast.emit(spell_data.get("name", spell_id), detail)
			hide()
		)
		top_row.add_child(cast_btn)

	# Stats row: damage, heal, statuses, range
	var stats_parts: Array[String] = []

	var damage = spell_data.get("damage")
	if damage != null and damage is float and damage > 0:
		var dmg_type = spell_data.get("damage_type", "")
		stats_parts.append(str(int(damage)) + " " + dmg_type + " dmg")

	var heal = spell_data.get("heal")
	if heal != null and heal is float and heal > 0:
		stats_parts.append("Heal " + str(int(heal)))

	var statuses = spell_data.get("statuses_caused", [])
	if not statuses.is_empty():
		var status_names: Array[String] = []
		for s in statuses:
			status_names.append(str(s))
		stats_parts.append("-> " + ", ".join(status_names))

	var target = spell_data.get("target", {})
	var range_str = target.get("range", "ranged")
	stats_parts.append(range_str.capitalize())

	var duration = spell_data.get("duration")
	if duration != null:
		if duration is String:
			stats_parts.append("Dur: " + duration)
		elif duration is float and duration > 0:
			stats_parts.append("Dur: " + str(int(duration)) + "t")

	if not stats_parts.is_empty():
		var stats_label = Label.new()
		stats_label.text = "  |  ".join(stats_parts)
		stats_label.add_theme_font_size_override("font_size", 12)
		stats_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
		vbox.add_child(stats_label)

	# Description
	var desc = spell_data.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.48))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc_label)

	return card


func _apply_overworld_spell(spell_id: String, spell_data: Dictionary, caster: Dictionary) -> String:
	## Apply a spell's effects outside of combat and return a result string for the toast.
	var party := CharacterSystem.get_party()
	var target_info: Dictionary = spell_data.get("target", {})
	var target_type: String    = target_info.get("type",     "single")
	var target_eligible: String = target_info.get("eligible", "ally")

	# Determine who gets hit
	var targets: Array[Dictionary] = []
	match target_type:
		"self":
			targets = [caster]
		"aoe", "global":
			if target_eligible == "dead_ally":
				return "No fallen allies in the party"
			targets = party
		"party":
			targets = party
		"dead_ally":
			return "No fallen allies in the party"
		"corpse":
			return "No corpse here to perform rites over"
		"ground":
			return "Cannot target ground on the overworld"
		_:  # "single", "two_allies", etc. — default to caster
			targets = [caster]

	if targets.is_empty():
		return "No valid targets"

	var heal_value        = spell_data.get("heal")
	var statuses_removed: Array = spell_data.get("statuses_removed", [])
	var special: Dictionary     = spell_data.get("special", {})
	var results: Array[String]  = []

	for target in targets:
		var target_name: String  = target.get("name", "?")
		var derived: Dictionary  = target.get("derived", {})
		var max_hp: int          = derived.get("max_hp", 100)
		var cur_hp: int          = derived.get("current_hp", max_hp)

		# Healing
		if heal_value != null:
			var heal_amt := 0
			if heal_value is String and heal_value == "full":
				heal_amt = max_hp - cur_hp
			elif heal_value is float and heal_value > 0.0:
				heal_amt = int(heal_value)
			if heal_amt > 0:
				var actual := mini(heal_amt, max_hp - cur_hp)
				derived["current_hp"] = min(max_hp, cur_hp + actual)
				if actual > 0:
					results.append("%s +%d HP" % [target_name, actual])

		# Stamina restore (e.g. Gentle Breeze)
		if special.get("restores_stamina", false):
			var max_st: int = derived.get("max_stamina", 50)
			var cur_st: int = derived.get("current_stamina", max_st)
			if cur_st < max_st:
				derived["current_stamina"] = max_st
				results.append("%s stamina restored" % target_name)

		# Overworld status removal
		if not statuses_removed.is_empty():
			var ow_statuses: Array = target.get("overworld_statuses", [])
			if not ow_statuses.is_empty():
				var remove_all := "all_negative" in statuses_removed \
						or "negative" in statuses_removed
				var to_remove: Array[int] = []
				for i in range(ow_statuses.size()):
					var s_name: String = ow_statuses[i].get("status", "")
					if remove_all:
						to_remove.append(i)
					else:
						for tag in statuses_removed:
							if s_name.to_lower() == (tag as String).to_lower():
								to_remove.append(i)
								break
				to_remove.reverse()
				for idx in to_remove:
					ow_statuses.remove_at(idx)
				if not to_remove.is_empty():
					results.append("%s cleansed" % target_name)

	if results.is_empty():
		return "No effect"
	return " | ".join(results)


# ============================================
# CRAFTING TAB
# ============================================

func _load_craft_tiers() -> void:
	## Load alchemy_crafting_tiers from supplies.json (once).
	if not _craft_tiers.is_empty():
		return
	var file_path = "res://resources/data/supplies.json"
	if not FileAccess.file_exists(file_path):
		push_warning("Crafting: supplies.json not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_warning("Crafting: Failed to parse supplies.json")
		return
	_craft_tiers = json.get_data().get("alchemy_crafting_tiers", {})

func _build_craft_filters() -> void:
	## Build the Potions / Bombs / Oils radio filter buttons (built once).
	if _craft_built:
		return
	_craft_built = true

	var label = Label.new()
	label.text = "Filter:"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	craft_filter_bar.add_child(label)

	for category in ["remedies", "munitions", "applications"]:
		var display = CRAFT_CATEGORY_LABELS[category]
		var btn = Button.new()
		btn.text = display
		btn.toggle_mode = true
		btn.button_pressed = false  # Nothing active by default
		btn.custom_minimum_size = Vector2(80, 26)
		btn.add_theme_font_size_override("font_size", 12)

		# Pressed/active style
		var style_on = StyleBoxFlat.new()
		style_on.bg_color = CRAFT_COLOR.darkened(0.6)
		style_on.border_color = CRAFT_COLOR
		style_on.set_border_width_all(2)
		style_on.set_corner_radius_all(3)
		style_on.set_content_margin_all(4)
		btn.add_theme_stylebox_override("pressed", style_on)

		# Normal style
		var style_off = StyleBoxFlat.new()
		style_off.bg_color = Color(0.15, 0.13, 0.18)
		style_off.border_color = CRAFT_COLOR.darkened(0.5)
		style_off.set_border_width_all(1)
		style_off.set_corner_radius_all(3)
		style_off.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", style_off)

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.2, 0.18, 0.22)
		style_hover.border_color = CRAFT_COLOR.darkened(0.3)
		style_hover.set_border_width_all(1)
		style_hover.set_corner_radius_all(3)
		style_hover.set_content_margin_all(4)
		btn.add_theme_stylebox_override("hover", style_hover)

		# Use pressed (not toggled) so programmatic button_pressed changes don't
		# retrigger the handler and cause a recursive stack overflow.
		btn.pressed.connect(_on_craft_filter_pressed.bind(category))
		craft_filter_bar.add_child(btn)
		_craft_filter_buttons[category] = btn

func _on_craft_filter_pressed(category: String) -> void:
	## Radio-button logic: clicking the active filter deselects (shows all);
	## clicking another filter selects it exclusively.
	AudioManager.play("ui_click")
	if _craft_filter == category:
		# Toggle off — show everything
		_craft_filter = ""
		_craft_filter_buttons[category].button_pressed = false
	else:
		_craft_filter = category
		# Deactivate all other buttons without triggering their handlers
		for cat in _craft_filter_buttons:
			_craft_filter_buttons[cat].button_pressed = (cat == category)
	_update_craft_list()

func _update_crafting_tab() -> void:
	## Refresh the full crafting tab (character panel + item list).
	_update_crafter_panel()
	_update_craft_list()

func _update_crafter_panel() -> void:
	## Populate the character picker at the top with alchemist party members.
	for child in crafter_panel.get_children():
		child.queue_free()

	var party = CharacterSystem.get_party()
	var alchemists: Array[Dictionary] = []
	for character in party:
		var alch_level = character.get("skills", {}).get("alchemy", 0)
		if alch_level > 0:
			alchemists.append(character)

	if alchemists.is_empty():
		var msg = Label.new()
		msg.text = "No one in your party knows Alchemy."
		msg.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		msg.add_theme_font_size_override("font_size", 13)
		crafter_panel.add_child(msg)
		# Deselect
		_craft_character = {}
		return

	# Auto-select the first alchemist if none selected or selected left party
	var still_valid := false
	for a in alchemists:
		if a.get("name", "") == _craft_character.get("name", ""):
			still_valid = true
			_craft_character = a  # Refresh reference
			break
	if not still_valid:
		_craft_character = alchemists[0]

	# Build a card for each alchemist
	for character in alchemists:
		var is_selected = (character.get("name", "") == _craft_character.get("name", ""))
		var card = _create_crafter_card(character, is_selected)
		crafter_panel.add_child(card)

func _create_crafter_card(character: Dictionary, selected: bool) -> PanelContainer:
	## Create a small character card for the crafter picker.
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(90, 60)

	var border_col = CRAFT_COLOR if selected else Color(0.35, 0.35, 0.4)
	var bg_col = CRAFT_COLOR.darkened(0.75) if selected else Color(0.12, 0.1, 0.15)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Character name
	var name_label = Label.new()
	name_label.text = character.get("name", "?")
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", CRAFT_COLOR if selected else Color(0.85, 0.82, 0.78))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Alchemy level
	var alch = character.get("skills", {}).get("alchemy", 0)
	var level_label = Label.new()
	level_label.text = "Alchemy %d" % alch
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# Transparent click button overlay
	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = CRAFT_COLOR * Color(1, 1, 1, 0.15)
	hover_style.border_color = CRAFT_COLOR
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(_on_crafter_selected.bind(character))
	card.add_child(btn)

	return card

func _on_crafter_selected(character: Dictionary) -> void:
	AudioManager.play("ui_click")
	_craft_character = character
	_update_crafter_panel()
	_update_craft_list()

func _update_craft_list() -> void:
	## Populate the item list for the active filter category and selected crafter.
	for child in crafting_list.get_children():
		child.queue_free()

	if _craft_tiers.is_empty() or _craft_character.is_empty():
		var msg = Label.new()
		msg.text = "Select an alchemist above to craft items."
		msg.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		msg.add_theme_font_size_override("font_size", 13)
		crafting_list.add_child(msg)
		return

	# Determine which categories to show
	var categories_to_show: Array[String] = []
	if _craft_filter == "":
		categories_to_show = ["remedies", "munitions", "applications"]
	else:
		categories_to_show = [_craft_filter]

	var reagents: int = GameState.get_supply("reagents")

	# Gather all rows across relevant categories: craftable ones first, then locked
	var craftable_rows: Array[Dictionary] = []
	var locked_rows: Array[Dictionary] = []

	for category in categories_to_show:
		var category_data = _craft_tiers.get(category, {})
		if category_data.is_empty():
			continue
		for tier_key in ["tier_1", "tier_2", "tier_3"]:
			var tier_data = category_data.get(tier_key, {})
			if tier_data.is_empty():
				continue
			var required_perk: String = tier_data.get("perk", "")
			var cost: int = int(tier_data.get("reagent_cost", 1))
			var item_ids: Array = tier_data.get("items", [])

			# Check if the selected character has this tier's perk
			var has_tier = PerkSystem.has_perk(_craft_character, required_perk)

			for item_id in item_ids:
				var item_data = ItemSystem.get_item(item_id)
				var row_info := {
					"item_id": item_id,
					"item_data": item_data,
					"cost": cost,
					"has_tier": has_tier,
					"required_perk": required_perk
				}
				if has_tier:
					craftable_rows.append(row_info)
				else:
					locked_rows.append(row_info)

	# Sort each group by reagent cost ascending
	craftable_rows.sort_custom(func(a, b): return a["cost"] < b["cost"])
	locked_rows.sort_custom(func(a, b): return a["cost"] < b["cost"])

	# Craftable items first
	if not craftable_rows.is_empty():
		var header = Label.new()
		header.text = "— Available —"
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		crafting_list.add_child(header)

		for row_info in craftable_rows:
			var row = _create_craft_row(row_info, reagents, true)
			crafting_list.add_child(row)

	# Locked items below
	if not locked_rows.is_empty():
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 4
		crafting_list.add_child(spacer)

		var header = Label.new()
		header.text = "— Locked —"
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", Color(0.45, 0.42, 0.4))
		crafting_list.add_child(header)

		for row_info in locked_rows:
			var row = _create_craft_row(row_info, reagents, false)
			crafting_list.add_child(row)

func _create_craft_row(row_info: Dictionary, reagents: int, craftable: bool) -> PanelContainer:
	## Create a single craftable item row.
	var item_id: String = row_info["item_id"]
	var item_data: Dictionary = row_info["item_data"]
	var cost: int = row_info["cost"]
	var required_perk: String = row_info["required_perk"]

	var can_afford: bool = reagents >= cost
	var clickable: bool = craftable and can_afford

	var card = PanelContainer.new()

	var bg_alpha = 0.9 if craftable else 0.4
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15, bg_alpha)
	style.border_color = CRAFT_COLOR.darkened(0.4) if craftable else Color(0.28, 0.28, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	# Item name
	var name_col = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_col)

	var item_name = item_data.get("name", item_id.replace("_", " ").capitalize())
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 14)
	if craftable:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.87, 0.82))
	else:
		name_label.add_theme_color_override("font_color", Color(0.45, 0.43, 0.4))
	name_col.add_child(name_label)

	# Item description (short)
	var desc = item_data.get("description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.44) if craftable else Color(0.35, 0.33, 0.3))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_col.add_child(desc_label)

	# Locked reason
	if not craftable:
		var perk_display = required_perk.replace("_", " ").capitalize()
		var lock_label = Label.new()
		lock_label.text = "Requires: " + perk_display
		lock_label.add_theme_font_size_override("font_size", 10)
		lock_label.add_theme_color_override("font_color", Color(0.45, 0.42, 0.4))
		name_col.add_child(lock_label)

	# Reagent cost (right side)
	var cost_label = Label.new()
	cost_label.text = str(cost) + " ⬡"
	cost_label.add_theme_font_size_override("font_size", 14)
	if not craftable:
		cost_label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35))
	elif can_afford:
		cost_label.add_theme_color_override("font_color", CRAFT_COLOR)
	else:
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.15))  # Red = can't afford
	cost_label.custom_minimum_size.x = 50
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(cost_label)

	# Craft button (only for craftable items)
	if craftable:
		var craft_btn = Button.new()
		craft_btn.text = "Craft"
		craft_btn.custom_minimum_size = Vector2(60, 28)
		craft_btn.add_theme_font_size_override("font_size", 12)
		craft_btn.disabled = not can_afford
		craft_btn.pressed.connect(_on_craft_pressed.bind(item_id, cost))
		hbox.add_child(craft_btn)

	return card

func _on_craft_pressed(item_id: String, cost: int) -> void:
	## Spend reagents and add the item to the party inventory.
	if not GameState.consume_supply("reagents", cost):
		AudioManager.play("ui_denied")
		return

	# Add item to party inventory
	ItemSystem.add_to_inventory(item_id, 1)
	AudioManager.play("buff_apply")

	# Refresh the list so reagent count and button states update
	_update_craft_list()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	# Clean up tooltip CanvasLayer (frees tooltip too since it's a child)
	if item_tooltip and is_instance_valid(item_tooltip):
		var tooltip_parent = item_tooltip.get_parent()
		if tooltip_parent and tooltip_parent is CanvasLayer:
			tooltip_parent.queue_free()
		else:
			item_tooltip.queue_free()
	if perk_popup_layer and is_instance_valid(perk_popup_layer):
		perk_popup_layer.queue_free()


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
	# Clean up any existing popup and its CanvasLayer
	if perk_popup_layer and is_instance_valid(perk_popup_layer):
		perk_popup_layer.queue_free()
		perk_popup_layer = null
		perk_popup = null

	# Create a CanvasLayer above CharSheetOverlay (15) so popup renders on top
	perk_popup_layer = CanvasLayer.new()
	perk_popup_layer.layer = 30
	get_tree().root.add_child(perk_popup_layer)

	# Full-screen overlay that blocks input to the rest of the UI
	perk_popup = Control.new()
	perk_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	perk_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	perk_popup_layer.add_child(perk_popup)

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
		source_label.text = skill_name + " " + str(int(data.get("required_level", 1)))
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

	AudioManager.play("buff_apply", -3.0)
	PerkSystem.grant_perk(pending_perk_character, perk_id)
	pending_perk_character = {}

	# Close popup (free the CanvasLayer, which frees the popup too)
	if perk_popup_layer and is_instance_valid(perk_popup_layer):
		perk_popup_layer.queue_free()
		perk_popup_layer = null
		perk_popup = null

	# Refresh display to show updated stats
	_refresh_display()

func _on_perk_skipped() -> void:
	## Handle player skipping the perk selection.
	AudioManager.play("ui_click")
	pending_perk_character = {}
	if perk_popup_layer and is_instance_valid(perk_popup_layer):
		perk_popup_layer.queue_free()
		perk_popup_layer = null
		perk_popup = null


# ============================================
# CHARACTER SELECTOR
# ============================================

func _build_character_selector() -> void:
	## Rebuild the party selector buttons above the tab container.
	for child in character_selector_panel.get_children():
		child.queue_free()

	if _selector_group == null:
		_selector_group = ButtonGroup.new()

	var party := CharacterSystem.get_party()
	for i in range(party.size()):
		var member: Dictionary = party[i]
		var btn := Button.new()
		btn.text = member.get("name", "Unknown")
		btn.toggle_mode = true
		btn.button_group = _selector_group
		var flavor: String = member.get("flavor_text", "")
		if flavor != "":
			btn.tooltip_text = flavor
		btn.pressed.connect(_on_character_selected.bind(member))
		character_selector_panel.add_child(btn)
		if member == _current_character:
			btn.set_pressed_no_signal(true)

	# Prev/next arrow buttons on the right end of the selector bar
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_selector_panel.add_child(spacer)

	var prev_btn := Button.new()
	prev_btn.text = "◄"
	prev_btn.tooltip_text = "Previous character"
	prev_btn.custom_minimum_size = Vector2(30, 0)
	prev_btn.pressed.connect(_navigate_character.bind(-1))
	character_selector_panel.add_child(prev_btn)

	var next_btn := Button.new()
	next_btn.text = "►"
	next_btn.tooltip_text = "Next character"
	next_btn.custom_minimum_size = Vector2(30, 0)
	next_btn.pressed.connect(_navigate_character.bind(1))
	character_selector_panel.add_child(next_btn)


func _navigate_character(direction: int) -> void:
	## Cycle to the prev/next party member.
	var party := CharacterSystem.get_party()
	if party.is_empty():
		return
	var idx := party.find(_current_character)
	if idx == -1:
		idx = 0
	idx = (idx + direction + party.size()) % party.size()
	_on_character_selected(party[idx])
	# Sync the toggle buttons so the correct one is highlighted
	var buttons: Array = []
	for child in character_selector_panel.get_children():
		if child is Button and child.toggle_mode:
			buttons.append(child)
	if idx < buttons.size():
		buttons[idx].set_pressed_no_signal(true)


func _on_character_selected(character: Dictionary) -> void:
	## Switch the displayed character and refresh all tabs.
	_current_character = character
	refresh_all_tabs()


func refresh_all_tabs() -> void:
	## Refresh stats, equipment, and spellbook tabs to show _current_character.
	_refresh_stats_tab()
	_refresh_equipment_tab()
	_refresh_spellbook_tab()


func _refresh_stats_tab() -> void:
	## Refresh the Stats tab content for _current_character.
	_refresh_display()


func _refresh_equipment_tab() -> void:
	## Refresh the Equipment tab content for _current_character.
	## Only refresh if the tab is currently visible to avoid unnecessary work.
	if tab_container.current_tab == 1:
		_update_equipment_slots()
		_update_equipment_display()


func _refresh_spellbook_tab() -> void:
	## Refresh the Spellbook tab content for _current_character.
	## Only rebuild if the tab is currently visible; otherwise it will refresh on switch.
	if tab_container.current_tab == 3:
		_update_spellbook()


func _on_companion_recruited(_companion: Dictionary) -> void:
	## Called when a new companion joins — rebuild selector so the new member appears.
	_build_character_selector()


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

	# Ring slots - beside the hand slots, with a small outward gap
	_create_equipment_slot("ring1", Vector2(center_x - slot_size.x/2 - 65 - small_slot.x - 8, 84), small_slot)
	_create_equipment_slot("ring2", Vector2(center_x + slot_size.x/2 + 13 + slot_size.x + 8, 84), small_slot)

	# Trinket slots - flanking the head slot, side by side ("square" grouping at the top)
	_create_equipment_slot("trinket1", Vector2(center_x - slot_size.x/2 - small_slot.x - 8, 14), small_slot)
	_create_equipment_slot("trinket2", Vector2(center_x + slot_size.x/2 + 8, 14), small_slot)

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
		"trinket1": "T1",
		"trinket2": "T2"
	}
	btn.text = short_labels.get(slot_id, "?")
	btn.add_theme_font_size_override("font_size", 10)

	btn.pressed.connect(_on_equipment_slot_pressed.bind(slot_id))

	equipment_slot_buttons[slot_id] = btn
	doll_layout.add_child(btn)

func _on_equipment_slot_pressed(slot_id: String) -> void:
	AudioManager.play("ui_click")
	var player = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()

	# hand_r is a visual mirror of hand_l — redirect all clicks to hand_l
	if slot_id == "hand_r":
		slot_id = "hand_l"

	# If slot has an item equipped, offer to unequip on double-click or show items
	var equipped_item_id = ""
	if not player.is_empty():
		equipped_item_id = ItemSystem.get_equipped_item(player, slot_id)

	# If clicking already selected slot with equipped item, unequip it
	if selected_equipment_slot == slot_id and equipped_item_id != "":
		ItemSystem.unequip_item(player, slot_id)
		# Also clear the mirror slot (no inventory return — gloves are one item)
		if slot_id == "hand_l":
			player.get("equipment", {})["hand_r"] = ""
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
	var player = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
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
		"trinket1": "T1",
		"trinket2": "T2"
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
	var player = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if player.is_empty():
		return

	var equipped_item_id = ItemSystem.get_equipped_item(player, slot_id)
	if equipped_item_id != "":
		var item = ItemSystem.get_item(equipped_item_id)
		if item_tooltip and not item.is_empty():
			var mouse_pos = get_global_mouse_position()
			item_tooltip.show_item(item, mouse_pos)

func _on_weapon_set_pressed(set_num: int) -> void:
	AudioManager.play("ui_click")
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

	# Dim button if selected character doesn't meet requirements
	var player := _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if not player.is_empty():
		var can_result := ItemSystem.can_equip(player, item.get("id", ""))
		if not can_result.can_equip:
			btn.add_theme_color_override("font_color", Color(0.45, 0.4, 0.4))
			var dim_style = StyleBoxFlat.new()
			dim_style.bg_color = Color(0.08, 0.08, 0.1)
			dim_style.border_color = Color(0.3, 0.25, 0.25)
			dim_style.set_border_width_all(2)
			dim_style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", dim_style)
			btn.add_theme_stylebox_override("hover", dim_style.duplicate())

	return btn

func _on_equipment_item_pressed(item: Dictionary) -> void:
	AudioManager.play("ui_click")
	var player = _current_character if not _current_character.is_empty() else CharacterSystem.get_player()
	if player.is_empty():
		return

	var item_id = item.get("id", "")
	if item_id == "":
		return

	# Check if selected character can equip
	var can_result = ItemSystem.can_equip(player, item_id)
	if not can_result.can_equip:
		AudioManager.play("ui_denied")
		return

	# Equip the item
	if ItemSystem.equip_item(player, item_id, selected_equipment_slot):
		# Mirror gloves/gauntlets/bracers to hand_r (one pair = one inventory item)
		if selected_equipment_slot == "hand_l":
			player.get("equipment", {})["hand_r"] = item_id
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

	var derived: Dictionary = character.get("derived", {})
	var attrs: Dictionary = character.get("attributes", {})

	# HP bar (red) - use Constitution as fallback if derived not set
	var max_hp: int = derived.get("max_hp", attrs.get("constitution", 10))
	var current_hp: int = derived.get("current_hp", max_hp)
	bars_row.add_child(_create_stat_bar("HP", current_hp, max_hp, Color(0.8, 0.2, 0.2)))

	# Mana bar (blue) - use Awareness as fallback
	var max_mana: int = derived.get("max_mana", attrs.get("awareness", 10))
	var current_mana: int = derived.get("current_mana", max_mana)
	bars_row.add_child(_create_stat_bar("MP", current_mana, max_mana, Color(0.2, 0.4, 0.9)))

	# Stamina bar (yellow)
	var max_stamina: int = derived.get("max_stamina", 10)
	var current_stamina: int = derived.get("current_stamina", max_stamina)
	bars_row.add_child(_create_stat_bar("ST", current_stamina, max_stamina, Color(0.9, 0.75, 0.2)))

	# Action buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	# "View Stats" — switches Stats tab to show this character
	var view_btn := Button.new()
	view_btn.text = "View Stats"
	view_btn.add_theme_font_size_override("font_size", 12)
	view_btn.pressed.connect(func():
		_on_character_selected(character)
		tab_container.current_tab = 0)
	btn_row.add_child(view_btn)

	# "Remove" — only for companions (not the player at index 0)
	var party := CharacterSystem.get_party()
	var char_index := party.find(character)
	if char_index > 0:
		var remove_btn := Button.new()
		remove_btn.text = "Remove"
		remove_btn.add_theme_font_size_override("font_size", 12)
		remove_btn.pressed.connect(func(): _on_remove_companion_pressed(char_index))
		btn_row.add_child(remove_btn)

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

func _on_remove_companion_pressed(index: int) -> void:
	## Remove a companion from the party (index must be > 0 to protect the player).
	var party := CharacterSystem.get_party()
	var was_viewing: bool = (party.size() > index and _current_character == party[index])
	CharacterSystem.remove_companion(index)
	# If we were viewing the removed companion, switch to the player
	if was_viewing:
		_current_character = CharacterSystem.get_player()
		refresh_all_tabs()
	_build_character_selector()
	_update_party_list()


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


## Journal tab — rebuilds the left-panel list; preserves selection if possible.
func _update_journal_tab() -> void:
	if not is_instance_valid(_journal_list):
		return
	for child in _journal_list.get_children():
		child.queue_free()

	var active: Array[Dictionary] = GameState.active_quests
	var completed_ids: Array[String] = GameState.completed_quest_ids

	if active.is_empty() and completed_ids.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No quests recorded."
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_journal_list.add_child(empty_lbl)
		if is_instance_valid(_journal_detail):
			_journal_detail.text = "[color=#666666]No quests yet.[/color]"
		return

	# Active quests first, then completed
	var entries: Array[Dictionary] = []
	for q in active:
		entries.append(q)
	# Also show completed quests from pool
	for qid in completed_ids:
		var qdef: Dictionary = GameState.get_quest_def(qid)
		if not qdef.is_empty():
			entries.append(qdef)

	var first_id := ""
	for quest in entries:
		var qid: String = quest.get("id", "")
		if first_id == "":
			first_id = qid
		var is_done: bool = GameState.completed_quest_ids.has(qid)
		var btn := Button.new()
		btn.text = ("✓ " if is_done else "○ ") + quest.get("name", "?")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.custom_minimum_size = Vector2(0, 32)
		var col := Color(0.5, 0.5, 0.5) if is_done else Color(0.85, 0.70, 0.30)
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.pressed.connect(func(): _journal_select_quest(qid))
		btn.set_meta("quest_id", qid)
		_journal_list.add_child(btn)

	# Auto-select first or preserve selection
	if _journal_selected_id == "" or not _journal_entry_exists(_journal_selected_id):
		_journal_selected_id = first_id
	_journal_select_quest(_journal_selected_id)


func _journal_entry_exists(quest_id: String) -> bool:
	for q in GameState.active_quests:
		if q.get("id", "") == quest_id:
			return true
	return GameState.completed_quest_ids.has(quest_id)


func _journal_select_quest(quest_id: String) -> void:
	_journal_selected_id = quest_id
	# Update selection highlight on all list buttons without rebuilding the list
	for child in _journal_list.get_children():
		if child is Button:
			if child.get_meta("quest_id", "") == quest_id:
				var sel_style := StyleBoxFlat.new()
				sel_style.bg_color = Color(0.18, 0.14, 0.10)
				child.add_theme_stylebox_override("normal", sel_style)
			else:
				child.remove_theme_stylebox_override("normal")
	_journal_show_detail(quest_id)


func _journal_show_detail(quest_id: String) -> void:
	if not is_instance_valid(_journal_detail) or quest_id == "":
		return
	# Prefer active quest dict (has runtime data); fall back to pool def
	var quest: Dictionary = {}
	for q in GameState.active_quests:
		if q.get("id", "") == quest_id:
			quest = q
			break
	if quest.is_empty():
		quest = GameState.get_quest_def(quest_id)
	if quest.is_empty():
		_journal_detail.text = "[color=#666666]Quest not found.[/color]"
		return

	var is_done: bool = GameState.completed_quest_ids.has(quest_id)
	var txt := ""

	# Title
	var title_col := "#888888" if is_done else "#d4a843"
	txt += "[b][color=%s]%s[/color][/b]" % [title_col, quest.get("name", "?")]
	if is_done:
		txt += "  [color=#4ade80][b][COMPLETE][/b][/color]"
	txt += "\n\n"

	# Description
	var desc: String = quest.get("description", "")
	if desc != "":
		txt += "[color=#9a9080]%s[/color]\n\n" % desc

	# Steps
	var steps: Array = quest.get("steps", [])
	if not steps.is_empty():
		txt += "[b]Objectives:[/b]\n"
		for step in steps:
			var done: bool = GameState.is_quest_step_done(step)
			var mark := "[color=#4ade80]✓[/color]" if done else "[color=#666666]○[/color]"
			var step_col := "#666666" if done else "#b8a898"
			txt += "  %s [color=%s]%s[/color]\n" % [mark, step_col, step.get("text", "")]
		txt += "\n"

	# Reward
	var reward: Dictionary = quest.get("reward", {})
	if not reward.is_empty():
		txt += "[b]Reward:[/b]\n"
		if reward.get("xp", 0) > 0:
			txt += "  [color=#a0c8ff]+%d XP[/color]\n" % int(reward.get("xp", 0))
		if reward.get("gold", 0) > 0:
			txt += "  [color=#f0d060]+%d gold[/color]\n" % int(reward.get("gold", 0))
		var karma: Dictionary = reward.get("karma", {})
		for realm in karma:
			var amt: int = int(karma[realm])
			var ksign := "+" if amt > 0 else ""
			txt += "  [color=#c890e0]☸ %s: %s%d[/color]\n" % [realm.capitalize(), ksign, amt]

	_journal_detail.text = txt


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
		# Use a container so we can overlay a quantity label
		var container = Control.new()
		container.custom_minimum_size = Vector2(50, 50)

		# Use a button for items so we get proper hover detection
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(50, 50)
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var item_id = item.get("id", "")
		var rarity_color = ItemSystem.get_rarity_color(item_id) if item_id != "" else Color.WHITE

		# Show abbreviated name
		var item_name = item.get("name", "?")
		btn.text = item_name.substr(0, 3).to_upper() if item_name.length() > 3 else item_name.to_upper()
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

		container.add_child(btn)

		# Show quantity badge for stacked items (quantity > 1)
		var quantity = item.get("quantity", 1)
		if quantity > 1:
			var qty_label = Label.new()
			qty_label.text = "x%d" % quantity
			qty_label.add_theme_font_size_override("font_size", 9)
			qty_label.add_theme_color_override("font_color", Color(1, 1, 1))
			qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			qty_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			# Small offset from edge
			qty_label.offset_right = -3
			qty_label.offset_bottom = -2
			qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(qty_label)

		return container
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
