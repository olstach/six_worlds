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
@onready var inventory_grid: GridContainer = $ShopPanel/MarginContainer/VBoxContainer/InventorySection/ScrollContainer/InventoryGrid
@onready var close_button: Button = $ShopPanel/MarginContainer/VBoxContainer/Footer/CloseButton

# Styling constants
const GOLD_COLOR = Color(0.9, 0.75, 0.2, 1)
const AFFORDABLE_COLOR = Color(0.3, 0.8, 0.3, 1)
const UNAFFORDABLE_COLOR = Color(0.8, 0.3, 0.3, 1)
const ITEM_SLOT_SIZE = Vector2(180, 80)

var current_shop: Dictionary = {}
var selected_barter_items: Array = []

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
	_populate_inventory()

	visible = true


## Open shop by ID from database
func open_shop_by_id(shop_id: String) -> bool:
	var shop_data = ShopSystem.get_shop(shop_id)
	if shop_data.is_empty():
		return false
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

	for item_id in items:
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

	# Learn button (for each party member)
	var party = CharacterSystem.get_party()
	if party.is_empty():
		var no_party = Label.new()
		no_party.text = "No party members"
		no_party.add_theme_font_size_override("font_size", 11)
		vbox.add_child(no_party)
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

	spells_grid.add_child(slot)


# ============================================
# TRAINING TAB
# ============================================

func _populate_training_tab() -> void:
	# Clear existing
	for child in training_container.get_children():
		child.queue_free()

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

	for character in party:
		var char_name = character.get("name", "?")
		var current_level = character.get("skills", {}).get(skill, 0)
		var price = ShopSystem.get_skill_training_cost(current_level)
		var can_afford = GameState.can_afford(price) and price > 0

		var btn = Button.new()
		btn.text = "%s (Lv.%d) - %dg" % [char_name, current_level, price]
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = not can_afford
		btn.pressed.connect(func(): _on_train_skill_pressed(character, skill))
		hbox.add_child(btn)


# ============================================
# COMPANIONS TAB
# ============================================

func _populate_companions_tab() -> void:
	for child in companions_container.get_children():
		child.queue_free()

	var available: Array = current_shop.get("available_companions", [])
	if available.is_empty():
		return  # Tab is hidden by _setup_tabs() when no companions — no label needed

	# Build set of companion_ids already in the party
	var party_companion_ids: Array[String] = []
	for member in CharacterSystem.get_party():
		if member.has("companion_id"):
			party_companion_ids.append(member.companion_id)

	var shown := 0
	for companion_id in available:
		if companion_id in party_companion_ids:
			continue  # Already recruited — hide them (they're unique people)
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
	var cost: int = def.get("recruitment_cost", 0)
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
