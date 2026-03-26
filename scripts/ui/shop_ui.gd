extends Control
## Shop UI - FTL-style shop interface
##
## Displays shop tabs (items, spells, training) with buy/sell/barter functionality.
## Connects to ShopSystem for all transactions.

signal shop_closed

@onready var shop_panel: Panel = $ShopPanel
@onready var shop_name_label: Label = $ShopPanel/MarginContainer/VBoxContainer/Header/ShopName
@onready var shop_desc_label: Label = $ShopPanel/MarginContainer/VBoxContainer/Header/ShopDescription
@onready var gold_label: Label = $ShopPanel/MarginContainer/VBoxContainer/Header/GoldDisplay
@onready var modifier_label: Label = $ShopPanel/MarginContainer/VBoxContainer/Header/ModifierDisplay
@onready var tab_container: TabContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer
@onready var items_grid: GridContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Items/ScrollContainer/ItemsGrid
@onready var spells_grid: GridContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Spells/ScrollContainer/SpellsGrid
@onready var training_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Training/ScrollContainer/TrainingContainer
@onready var companions_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Companions/ScrollContainer/CompanionsContainer
@onready var rest_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Rest/ScrollContainer/RestContainer
@onready var inventory_grid: GridContainer = $ShopPanel/MarginContainer/VBoxContainer/InventorySection/ScrollContainer/InventoryGrid
@onready var close_button: Button = $ShopPanel/MarginContainer/VBoxContainer/Footer/CloseButton

# Styling constants
const GOLD_COLOR = Color(0.9, 0.75, 0.2, 1)
const AFFORDABLE_COLOR = Color(0.3, 0.8, 0.3, 1)
const UNAFFORDABLE_COLOR = Color(0.8, 0.3, 0.3, 1)
const ITEM_SLOT_SIZE = Vector2(180, 80)

var current_shop: Dictionary = {}
var selected_barter_items: Array = []
var _location_data: Dictionary = {}

# Item tooltip
var item_tooltip: Control = null
const ITEM_TOOLTIP_SCENE = preload("res://scenes/ui/item_tooltip.tscn")


func _ready() -> void:
	# Connect signals
	GameState.gold_changed.connect(_on_gold_changed)
	ShopSystem.item_purchased.connect(_on_item_purchased)
	ShopSystem.item_sold.connect(_on_item_sold)
	ShopSystem.spell_purchased.connect(_on_spell_purchased)
	ShopSystem.training_purchased.connect(_on_training_purchased)
	close_button.pressed.connect(_on_close_pressed)

	# Create item tooltip on a high CanvasLayer so it renders above shop overlay
	var tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 100
	get_tree().root.add_child.call_deferred(tooltip_layer)
	item_tooltip = ITEM_TOOLTIP_SCENE.instantiate()
	tooltip_layer.add_child.call_deferred(item_tooltip)

	# Hide initially
	visible = false


## Open shop with given shop data
func open_shop(shop_data: Dictionary) -> void:
	current_shop = shop_data
	ShopSystem.open_shop(shop_data)

	# Update header
	shop_name_label.text = shop_data.get("name", "Shop")
	shop_desc_label.text = shop_data.get("description", "")
	_update_gold_display()
	_update_modifier_display()

	# Setup tabs based on shop type
	_setup_tabs()

	# Populate content
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_companions_tab()
	_populate_rest_tab()
	_populate_inventory()

	visible = true


## Open shop by ID from database
func open_shop_by_id(shop_id: String, location_data: Dictionary = {}) -> bool:
	var shop_data = ShopSystem.get_shop(shop_id)
	if shop_data.is_empty():
		return false
	_location_data = location_data
	# Pass object_id so ShopSystem can cache stable guild curricula
	shop_data["_object_id"] = location_data.get("_object_id", "")
	open_shop(shop_data)
	return true


func close_shop() -> void:
	ShopSystem.close_shop()
	current_shop = {}
	selected_barter_items.clear()
	visible = false
	shop_closed.emit()


func _setup_tabs() -> void:
	var shop_type = current_shop.get("type", "general")
	var type_info = ShopSystem._shop_types.get(shop_type, {})
	var tabs: Array = type_info.get("tabs", ["items"]).duplicate()

	# Always show companions tab first if the shop has available companions,
	# so it opens as the default tab rather than an empty Items tab
	if not current_shop.get("available_companions", []).is_empty():
		if not "companions" in tabs:
			tabs.push_front("companions")

	# Hide rest tab when the shop has no rest data
	if current_shop.get("rest", {}).is_empty():
		tabs.erase("rest")

	# Show/hide tabs based on resolved list
	for i in range(tab_container.get_tab_count()):
		var tab_name = tab_container.get_tab_title(i).to_lower()
		tab_container.set_tab_hidden(i, tab_name not in tabs)

	# Select first visible tab
	for i in range(tab_container.get_tab_count()):
		if not tab_container.is_tab_hidden(i):
			tab_container.current_tab = i
			break


func _update_gold_display() -> void:
	gold_label.text = "Gold: %d" % GameState.get_gold()


func _update_modifier_display() -> void:
	var summary = ShopSystem.get_price_modifier_summary()
	modifier_label.text = summary


# ============================================
# ITEMS TAB
# ============================================

func _populate_items_tab() -> void:
	# Clear existing
	for child in items_grid.get_children():
		child.queue_free()

	var items = current_shop.get("items", {})
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No items for sale"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		items_grid.add_child(empty_label)
		return

	# Sort items: by type category first, then alphabetically by name
	var type_priority := {
		"sword": 0, "axe": 1, "mace": 2, "dagger": 3, "spear": 4,
		"bow": 5, "crossbow": 6, "staff": 7,
		"armor": 10, "helmet": 11, "boots": 12, "gloves": 13, "shield": 14,
		"ring": 20, "amulet": 21, "talisman": 22, "trinket": 23,
		"potion": 30, "scroll": 31, "charm": 32, "bomb": 33, "oil": 34,
		"supply": 40, "material": 41
	}
	var sorted_ids = items.keys()
	sorted_ids.sort_custom(func(a, b):
		var ia = ItemSystem.get_item(a)
		var ib = ItemSystem.get_item(b)
		var pa = type_priority.get(ia.get("type", ""), 50)
		var pb = type_priority.get(ib.get("type", ""), 50)
		if pa != pb:
			return pa < pb
		return ia.get("name", a) < ib.get("name", b))

	for item_id in sorted_ids:
		var quantity = items[item_id]
		if quantity == 0:
			continue
		_create_item_slot(item_id, quantity, true)


func _create_item_slot(item_id: String, quantity: int, is_shop_item: bool) -> void:
	var item_data = ItemSystem.get_item(item_id)
	if item_data.is_empty():
		return

	var slot = PanelContainer.new()
	slot.custom_minimum_size = ITEM_SLOT_SIZE

	# Style the slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.25, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	slot.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	slot.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Item name (colored by rarity)
	var name_label = Label.new()
	name_label.text = item_data.get("name", item_id)
	name_label.add_theme_font_size_override("font_size", 14)
	var rarity_color = ItemSystem.get_rarity_color(item_id)
	name_label.add_theme_color_override("font_color", rarity_color)
	vbox.add_child(name_label)

	# Quantity and price
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(info_hbox)

	if quantity > 0:
		var qty_label = Label.new()
		qty_label.text = "x%d" % quantity if quantity > 0 else "∞"
		qty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		qty_label.add_theme_font_size_override("font_size", 12)
		info_hbox.add_child(qty_label)

	var price: int
	if is_shop_item:
		price = ShopSystem.get_buy_price(item_id)
	else:
		price = ShopSystem.get_sell_price(item_id)

	var price_label = Label.new()
	price_label.text = "%d gold" % price
	price_label.add_theme_font_size_override("font_size", 12)

	var can_afford = GameState.can_afford(price) if is_shop_item else true
	price_label.add_theme_color_override("font_color", AFFORDABLE_COLOR if can_afford else UNAFFORDABLE_COLOR)
	info_hbox.add_child(price_label)

	# Buy/Sell button
	var button = Button.new()
	button.text = "Buy" if is_shop_item else "Sell"
	button.add_theme_font_size_override("font_size", 12)

	if is_shop_item:
		button.disabled = not can_afford
		button.pressed.connect(func(): _on_buy_item_pressed(item_id))
	else:
		button.disabled = not ShopSystem.can_sell_item_here(item_id)
		button.pressed.connect(func(): _on_sell_item_pressed(item_id))

	vbox.add_child(button)

	# Connect hover for item tooltip
	slot.mouse_entered.connect(_on_item_hover.bind(item_data, slot))
	slot.mouse_exited.connect(_on_item_hover_end)

	if is_shop_item:
		items_grid.add_child(slot)
	else:
		inventory_grid.add_child(slot)


# ============================================
# SPELLS TAB
# ============================================

func _populate_spells_tab() -> void:
	# Clear existing
	for child in spells_grid.get_children():
		child.queue_free()

	var spells = current_shop.get("spells", [])
	if spells.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No spells available"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		spells_grid.add_child(empty_label)
		return

	for spell_id in spells:
		_create_spell_slot(spell_id)


func _create_spell_slot(spell_id: String) -> void:
	var spell_data = CombatManager.get_spell(spell_id)
	if spell_data.is_empty():
		return

	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(200, 100)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.25, 0.5, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	slot.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	slot.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Spell name
	var name_label = Label.new()
	name_label.text = spell_data.get("name", spell_id)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	vbox.add_child(name_label)

	# Schools and level
	var schools = spell_data.get("schools", [])
	var level = spell_data.get("level", 1)
	var info_label = Label.new()
	info_label.text = "Lv.%d %s" % [level, "/".join(schools)]
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(info_label)

	# Price
	var price = ShopSystem.get_spell_cost(spell_id)
	var price_label = Label.new()
	price_label.text = "%d gold" % price
	price_label.add_theme_font_size_override("font_size", 12)
	var can_afford = GameState.can_afford(price)
	price_label.add_theme_color_override("font_color", AFFORDABLE_COLOR if can_afford else UNAFFORDABLE_COLOR)
	vbox.add_child(price_label)

	# Learn button(s): guilds show one "Buy" button teaching the whole party,
	# regular shops show one button per party member.
	var party = CharacterSystem.get_party()
	var is_guild = current_shop.get("type", "") == "spell_guild"

	if party.is_empty():
		var no_party = Label.new()
		no_party.text = "No party members"
		no_party.add_theme_font_size_override("font_size", 11)
		vbox.add_child(no_party)
	elif is_guild:
		# Single "Buy" button — teaches every party member who doesn't already know it
		var all_known = party.all(func(c): return CharacterSystem.knows_spell(c, spell_id))
		var learn_btn = Button.new()
		learn_btn.text = "Known by all" if all_known else "Buy"
		learn_btn.add_theme_font_size_override("font_size", 11)
		learn_btn.disabled = all_known or not can_afford
		learn_btn.pressed.connect(func(): _on_guild_learn_spell_pressed(spell_id))
		vbox.add_child(learn_btn)
	else:
		for character in party:
			var char_name = character.get("name", "Unknown")
			var knows = CharacterSystem.knows_spell(character, spell_id)

			var learn_btn = Button.new()
			learn_btn.text = char_name + (" (known)" if knows else "")
			learn_btn.add_theme_font_size_override("font_size", 11)
			learn_btn.disabled = knows or not can_afford
			learn_btn.pressed.connect(func(): _on_learn_spell_pressed(character, spell_id))
			vbox.add_child(learn_btn)

	# Tooltip on hover — build a minimal item-like dict for the shared tooltip
	slot.mouse_entered.connect(func():
		if item_tooltip:
			var desc = _build_spell_description(spell_data)
			var spell_item := {
				"name": spell_data.get("name", spell_id),
				"type": "Spell",
				"rarity": "common",
				"description": desc
			}
			item_tooltip.show_item(spell_item, get_global_mouse_position()))
	slot.mouse_exited.connect(_on_item_hover_end)

	spells_grid.add_child(slot)


## Build a compact description string for a spell, used in the shop tooltip.
## Computes damage/heal values using the player character's spellpower if available.
func _build_spell_description(spell_data: Dictionary) -> String:
	var parts: Array[String] = []

	# Get player's spellpower for stat calculations
	var player = CharacterSystem.get_player()
	var spellpower: int = 0
	if not player.is_empty():
		spellpower = player.get("derived", {}).get("spellpower", 0)

	if "description" in spell_data:
		parts.append(spell_data.description)

	if spell_data.get("damage") != null:
		var dtype = spell_data.get("damage_type", "magical")
		var base_dmg: int = int(spell_data.damage)
		var actual_dmg: int = base_dmg + int(spellpower / 2)
		parts.append("Damage: %d (%s)" % [actual_dmg, dtype.capitalize()])

	if spell_data.get("heal") != null:
		var base_heal: int = int(spell_data.heal)
		var actual_heal: int = base_heal + int(spellpower / 2)
		parts.append("Heals: %d" % actual_heal)

	var statuses = spell_data.get("statuses_caused", [])
	if not statuses.is_empty():
		parts.append("Inflicts: %s" % ", ".join(statuses))

	var target = spell_data.get("target", {})
	var range_val = target.get("range", "ranged")
	parts.append("Range: %s" % str(range_val).capitalize())

	if "aoe" in spell_data:
		var aoe = spell_data.aoe
		parts.append("AoE %s, radius %d" % [aoe.get("type", "area"), aoe.get("base_size", 1)])

	var mana_cost = spell_data.get("mana_cost", 0)
	if mana_cost > 0:
		parts.append("Mana: %d" % mana_cost)

	return "\n".join(parts)


# ============================================
# TRAINING TAB
# ============================================

func _populate_training_tab() -> void:
	# Clear existing
	for child in training_container.get_children():
		child.queue_free()

	# Veteran's Camp mode: skills are chosen at map-gen time, each slot one-use
	var selected_skills: Array = _location_data.get("selected_skills", [])
	if not selected_skills.is_empty():
		_populate_veteran_training(selected_skills, _location_data.get("claimed", []))
		return

	var training = current_shop.get("training", {})
	var attributes = training.get("attributes", [])
	var skills = training.get("skills", [])

	if attributes.is_empty() and skills.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No training available"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		training_container.add_child(empty_label)
		return

	# Attribute training
	if not attributes.is_empty():
		var attr_header = Label.new()
		attr_header.text = "Attribute Training"
		attr_header.add_theme_font_size_override("font_size", 16)
		attr_header.add_theme_color_override("font_color", GOLD_COLOR)
		training_container.add_child(attr_header)

		var attr_price = ShopSystem.get_attribute_training_cost()
		var price_label = Label.new()
		price_label.text = "Cost: %d gold per point" % attr_price
		price_label.add_theme_font_size_override("font_size", 12)
		training_container.add_child(price_label)

		for attr in attributes:
			_create_training_option("attribute", attr, attr_price)

		training_container.add_child(HSeparator.new())

	# Skill training
	if not skills.is_empty():
		var skill_header = Label.new()
		skill_header.text = "Skill Training"
		skill_header.add_theme_font_size_override("font_size", 16)
		skill_header.add_theme_color_override("font_color", GOLD_COLOR)
		training_container.add_child(skill_header)

		for skill in skills:
			_create_skill_training_option(skill)


func _create_training_option(training_type: String, target: String, price: int) -> void:
	var party = CharacterSystem.get_party()
	if party.is_empty():
		return

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	training_container.add_child(hbox)

	var label = Label.new()
	label.text = target.capitalize()
	label.custom_minimum_size.x = 100
	hbox.add_child(label)

	for character in party:
		var char_name = character.get("name", "?")
		var current_val = character.get("attributes", {}).get(target, 10)
		var can_afford = GameState.can_afford(price)

		var btn = Button.new()
		btn.text = "%s (%d)" % [char_name, current_val]
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = not can_afford
		btn.pressed.connect(func(): _on_train_attribute_pressed(character, target))
		hbox.add_child(btn)


func _create_skill_training_option(skill: String) -> void:
	var party = CharacterSystem.get_party()
	if party.is_empty():
		return

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	training_container.add_child(hbox)

	var label = Label.new()
	label.text = skill.capitalize()
	label.custom_minimum_size.x = 100
	hbox.add_child(label)

	var trainer_cap: int = ShopSystem.get_trainer_skill_cap()

	for character in party:
		var char_name = character.get("name", "?")
		var current_level = character.get("skills", {}).get(skill, 0)

		var btn = Button.new()
		btn.add_theme_font_size_override("font_size", 11)

		if current_level >= trainer_cap:
			btn.text = "%s (Lv.%d) - Capped" % [char_name, current_level]
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.4))
		else:
			var price = ShopSystem.get_skill_training_cost(current_level)
			var can_afford = GameState.can_afford(price) and price > 0
			btn.text = "%s (Lv.%d) - %dg" % [char_name, current_level, price]
			btn.disabled = not can_afford
			btn.pressed.connect(func(): _on_train_skill_pressed(character, skill))

		hbox.add_child(btn)


func _populate_veteran_training(selected_skills: Array, claimed: Array) -> void:
	var header := Label.new()
	header.text = "Combat Training  (one character per slot)"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", GOLD_COLOR)
	training_container.add_child(header)
	training_container.add_child(HSeparator.new())

	for i in range(selected_skills.size()):
		var skill: String = selected_skills[i]
		var is_claimed: bool = i < claimed.size() and claimed[i]

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var lbl := Label.new()
		lbl.text = skill.replace("_", " ").capitalize()
		lbl.custom_minimum_size.x = 110
		hbox.add_child(lbl)

		if is_claimed:
			var taken := Label.new()
			taken.text = "[ Taken ]"
			taken.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			hbox.add_child(taken)
		else:
			var trainer_cap: int = ShopSystem.get_trainer_skill_cap()
			for character in CharacterSystem.get_party():
				var current_level: int = character.get("skills", {}).get(skill, 0)

				var btn := Button.new()
				btn.add_theme_font_size_override("font_size", 11)

				if current_level >= trainer_cap:
					btn.text = "%s (Lv.%d) — Capped" % [character.get("name", "?"), current_level]
					btn.disabled = true
					btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.4))
				else:
					var price: int = ShopSystem.get_skill_training_cost(current_level)
					var can_afford: bool = GameState.can_afford(price) and price > 0
					btn.text = "%s (Lv.%d) — %dg" % [character.get("name", "?"), current_level, price]
					btn.disabled = not can_afford
					btn.pressed.connect(func(): _on_veteran_train_pressed(i, character, skill))
				hbox.add_child(btn)

		training_container.add_child(hbox)


func _on_veteran_train_pressed(slot_index: int, character: Dictionary, skill: String) -> void:
	var current_level: int = character.get("skills", {}).get(skill, 0)
	var price: int = ShopSystem.get_skill_training_cost(current_level)
	if not GameState.can_afford(price):
		return

	var result: Dictionary = ShopSystem.buy_skill_training(character, skill)
	if not result.get("success", false):
		return

	# Persist claimed state in the map object
	var obj_id: String = _location_data.get("_object_id", "")
	if obj_id != "":
		var new_claimed: Array = _location_data.get("claimed", [false, false]).duplicate()
		new_claimed[slot_index] = true
		_location_data["claimed"] = new_claimed
		MapManager.update_object_data(obj_id, "claimed", new_claimed)

	_populate_training_tab()


# ============================================
# COMPANIONS TAB
# ============================================

const MAX_COMPANIONS_SHOWN := 3  # How many companions to show per visit

func _populate_companions_tab() -> void:
	for child in companions_container.get_children():
		child.queue_free()

	var available: Array = current_shop.get("available_companions", []).duplicate()
	if available.is_empty():
		return  # Tab is hidden by _setup_tabs() when no companions — no label needed

	# Build set of companion_ids already in the party
	var party_companion_ids: Array[String] = []
	for member in CharacterSystem.get_party():
		if member.has("companion_id"):
			party_companion_ids.append(member.companion_id)

	# Remove already-recruited companions, then shuffle and cap the list
	available = available.filter(func(id): return not id in party_companion_ids)
	available.shuffle()
	if available.size() > MAX_COMPANIONS_SHOWN:
		available = available.slice(0, MAX_COMPANIONS_SHOWN)

	var shown := 0
	for companion_id in available:
		var def: Dictionary = CompanionSystem.get_definition(companion_id)
		if def.is_empty():
			push_warning("shop_ui: unknown companion id in shop: %s" % companion_id)
			continue
		_create_companion_panel(companion_id, def)
		shown += 1

	if shown == 0:
		var empty_label = Label.new()
		empty_label.text = "No companions available"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		companions_container.add_child(empty_label)


func _create_companion_panel(companion_id: String, def: Dictionary) -> void:
	# Scale recruitment cost with party power so early-game companions are affordable.
	# At power 20 (fresh start) costs ~25%; at power 80 (mid-game) costs 100%; scales up beyond that.
	var base_cost: int = def.get("recruitment_cost", 0)
	var party_power: float = EnemySystem.get_party_power()
	var price_mult: float = clampf(party_power / 80.0, 0.20, 2.0)
	var cost: int = maxi(10, int(base_cost * price_mult))
	var can_afford: bool = GameState.can_afford(cost)
	var party_full: bool = CharacterSystem.get_party().size() >= CharacterSystem.max_party_size

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 140)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.3, 0.55, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Name row: name left, cost right
	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var name_label = Label.new()
	name_label.text = def.get("name", companion_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	name_row.add_child(name_label)

	var cost_label = Label.new()
	cost_label.text = "%d gold" % cost
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color",
		GOLD_COLOR if can_afford else UNAFFORDABLE_COLOR)
	name_row.add_child(cost_label)

	# Race · Background identity line
	var race_name: String = def.get("race", "").replace("_", " ").capitalize()
	var bg_name: String = def.get("background", "").replace("_", " ").capitalize()
	var identity_label = Label.new()
	identity_label.text = "%s · %s" % [race_name, bg_name]
	identity_label.add_theme_font_size_override("font_size", 12)
	identity_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(identity_label)

	vbox.add_child(HSeparator.new())

	# Flavor text
	var flavor_label = Label.new()
	flavor_label.text = def.get("flavor_text", "")
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.add_theme_font_size_override("font_size", 12)
	flavor_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
	vbox.add_child(flavor_label)

	# Recruit button, right-aligned
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var recruit_btn = Button.new()
	recruit_btn.text = "Party Full" if party_full else "Recruit"
	recruit_btn.add_theme_font_size_override("font_size", 13)
	recruit_btn.disabled = not can_afford or party_full
	recruit_btn.pressed.connect(func(): _on_recruit_companion_pressed(companion_id))
	btn_row.add_child(recruit_btn)

	companions_container.add_child(panel)


# ============================================
# REST TAB
# ============================================

func _populate_rest_tab() -> void:
	for child in rest_container.get_children():
		child.queue_free()

	var rest_data: Dictionary = current_shop.get("rest", {})
	if rest_data.is_empty():
		return

	var price_mod: float = current_shop.get("price_modifier", 1.0)
	var teapot_cost: int = int(rest_data.get("teapot_cost", 30) * price_mod)
	var night_cost: int = int(rest_data.get("night_cost", 80) * price_mod)
	var teapot_pct: int = rest_data.get("teapot_restore_pct", 50)
	var night_pct: int = rest_data.get("night_restore_pct", 100)
	var teapot_food: int = rest_data.get("teapot_food", 0)
	var night_food: int = rest_data.get("night_food", 0)

	# Party status summary
	for character in CharacterSystem.get_party():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_lbl := Label.new()
		name_lbl.text = character.get("name", "?")
		name_lbl.custom_minimum_size.x = 90
		row.add_child(name_lbl)

		var derived: Dictionary = character.get("derived", {})
		var max_hp: int = derived.get("max_hp", 0)
		var max_mp: int = derived.get("max_mana", 0)
		var max_st: int = derived.get("max_stamina", 0)
		var cur_hp: int = derived.get("current_hp", max_hp)
		var cur_mp: int = derived.get("current_mana", max_mp)
		var cur_st: int = derived.get("current_stamina", max_st)

		var status_lbl := Label.new()
		status_lbl.text = "HP %d/%d   MP %d/%d   ST %d/%d" % [cur_hp, max_hp, cur_mp, max_mp, cur_st, max_st]
		status_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(status_lbl)
		rest_container.add_child(row)

	rest_container.add_child(HSeparator.new())

	_add_rest_option("Order a teapot", teapot_pct, teapot_cost, teapot_food)
	_add_rest_option("Stay for the night", night_pct, night_cost, night_food)


func _add_rest_option(label: String, restore_pct: int, cost: int, food_restore: int = 0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	rest_container.add_child(row)

	var lbl := Label.new()
	var desc = "%s  (%d%% restore" % [label, restore_pct]
	if food_restore > 0:
		desc += ", +%d food" % food_restore
	desc += ")"
	lbl.text = desc
	lbl.custom_minimum_size.x = 260
	row.add_child(lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d gold" % cost
	var can_afford: bool = GameState.can_afford(cost)
	cost_lbl.add_theme_color_override("font_color", AFFORDABLE_COLOR if can_afford else UNAFFORDABLE_COLOR)
	cost_lbl.custom_minimum_size.x = 70
	row.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "Rest"
	btn.disabled = not can_afford
	btn.pressed.connect(func(): _on_rest_pressed(restore_pct, cost, food_restore))
	row.add_child(btn)


func _on_rest_pressed(restore_pct: int, cost: int, food_restore: int = 0) -> void:
	if not GameState.can_afford(cost):
		return
	GameState.spend_gold(cost)

	for character in CharacterSystem.get_party():
		var derived: Dictionary = character.get("derived", {})
		var max_hp: int = derived.get("max_hp", 0)
		var max_mp: int = derived.get("max_mana", 0)
		var max_st: int = derived.get("max_stamina", 0)
		var cur_hp: int = derived.get("current_hp", max_hp)
		var cur_mp: int = derived.get("current_mana", max_mp)
		var cur_st: int = derived.get("current_stamina", max_st)

		character.derived["current_hp"] = mini(cur_hp + int(float(max_hp - cur_hp) * restore_pct / 100.0), max_hp)
		character.derived["current_mana"] = mini(cur_mp + int(float(max_mp - cur_mp) * restore_pct / 100.0), max_mp)
		character.derived["current_stamina"] = mini(cur_st + int(float(max_st - cur_st) * restore_pct / 100.0), max_st)

	if food_restore > 0:
		GameState.add_supply("food", food_restore)

	_update_gold_display()
	_populate_rest_tab()


# ============================================
# INVENTORY (for selling)
# ============================================

func _populate_inventory() -> void:
	# Clear existing
	for child in inventory_grid.get_children():
		child.queue_free()

	if not ShopSystem.shop_buys_items():
		var no_buy_label = Label.new()
		no_buy_label.text = "This shop doesn't buy items"
		no_buy_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		inventory_grid.add_child(no_buy_label)
		return

	var inventory = ItemSystem.get_inventory()
	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventory empty"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		inventory_grid.add_child(empty_label)
		return

	for entry in inventory:
		var item_id = entry.item_id
		var quantity = entry.quantity
		if quantity > 0:
			_create_item_slot(item_id, quantity, false)


# ============================================
# EVENT HANDLERS
# ============================================

func _on_buy_item_pressed(item_id: String) -> void:
	var result = ShopSystem.buy_item(item_id)
	if result.success:
		if result.has("supply_gained"):
			# Supply items (food, etc.) go straight to the party pool
			print("Purchased: %s — +%d %s" % [result.item_name, result.supply_gained, result.supply_type])
		else:
			print("Purchased: ", result.item_name, " for ", result.price, " gold")
		_refresh_display()
	else:
		print("Purchase failed: ", result.reason)


func _on_sell_item_pressed(item_id: String) -> void:
	var result = ShopSystem.sell_item(item_id)
	if result.success:
		print("Sold: ", result.item_name, " for ", result.price, " gold")
		_refresh_display()
	else:
		print("Sale failed: ", result.reason)


func _on_learn_spell_pressed(character: Dictionary, spell_id: String) -> void:
	var result = ShopSystem.buy_spell(character, spell_id)
	if result.success:
		print(character.name, " learned: ", result.spell_name)
		_refresh_display()
	else:
		print("Learning failed: ", result.reason)


## Guild spell purchase — charges once, teaches all party members who don't already know it.
## Skill requirements are NOT enforced at guilds (that's the point of a guild teacher).
func _on_guild_learn_spell_pressed(spell_id: String) -> void:
	var price = ShopSystem.get_spell_cost(spell_id)
	if not GameState.can_afford(price):
		print("Guild purchase failed: not enough gold")
		return

	GameState.spend_gold(price)
	ShopSystem.spell_purchased.emit(spell_id, price)

	for character in CharacterSystem.get_party():
		if not CharacterSystem.knows_spell(character, spell_id):
			CharacterSystem.learn_spell(character, spell_id)

	_refresh_display()


func _on_train_attribute_pressed(character: Dictionary, attribute: String) -> void:
	var result = ShopSystem.buy_attribute_training(character, attribute)
	if result.success:
		print(character.name, "'s ", attribute, " increased to ", result.new_value)
		_refresh_display()
	else:
		print("Training failed: ", result.reason)


func _on_train_skill_pressed(character: Dictionary, skill: String) -> void:
	var result = ShopSystem.buy_skill_training(character, skill)
	if result.success:
		print(character.name, "'s ", skill, " increased to level ", result.new_level)
		_refresh_display()
	else:
		print("Training failed: ", result.reason)


func _on_close_pressed() -> void:
	close_shop()


func _on_gold_changed(_new_amount: int, _change: int) -> void:
	_update_gold_display()


func _on_item_purchased(_item_id: String, _price: int) -> void:
	_refresh_display()


func _on_item_sold(_item_id: String, _price: int) -> void:
	_refresh_display()


func _on_spell_purchased(_spell_id: String, _price: int) -> void:
	_refresh_display()


func _on_training_purchased(_type: String, _target: String, _price: int) -> void:
	_refresh_display()


func _on_recruit_companion_pressed(companion_id: String) -> void:
	var result: Dictionary = CompanionSystem.recruit(companion_id)
	if not result.is_empty():
		_refresh_display()
	else:
		print("shop_ui: recruitment failed for companion: ", companion_id)


func _refresh_display() -> void:
	_update_gold_display()
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_companions_tab()
	_populate_rest_tab()
	_populate_inventory()


func _on_item_hover(item: Dictionary, control: Control) -> void:
	if item_tooltip and not item.is_empty():
		var mouse_pos = get_global_mouse_position()
		item_tooltip.show_item(item, mouse_pos)


func _on_item_hover_end() -> void:
	if item_tooltip:
		item_tooltip.hide_tooltip()


func _exit_tree() -> void:
	if item_tooltip and is_instance_valid(item_tooltip):
		var tooltip_parent = item_tooltip.get_parent()
		if tooltip_parent and tooltip_parent is CanvasLayer:
			tooltip_parent.queue_free()
		else:
			item_tooltip.queue_free()
