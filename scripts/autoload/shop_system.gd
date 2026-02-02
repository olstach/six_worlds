extends Node
## ShopSystem - Manages shops, trading, and services
##
## This singleton handles:
## - Shop data and inventory
## - Price calculations (with Trade skill modifiers)
## - Buying and selling items
## - Spell learning services
## - Training services (skills/attributes for gold)

# Signals
signal item_purchased(item_id: String, price: int)
signal item_sold(item_id: String, price: int)
signal spell_purchased(spell_id: String, price: int)
signal training_purchased(training_type: String, target: String, price: int)

# Price modifiers
const SELL_PRICE_RATIO: float = 0.5  # Sell items for 50% of value
const TRADE_SKILL_DISCOUNT: float = 0.05  # 5% discount per Trade skill level

# Spell pricing (base cost per spell level)
const SPELL_BASE_COST: int = 50  # Level 1 = 50, Level 2 = 100, etc.

# Training pricing
const ATTRIBUTE_TRAINING_COST: int = 200  # Cost per attribute point
const SKILL_TRAINING_COSTS: Array[int] = [50, 150, 300, 500, 750]  # Cost to reach each level

# Current active shop (set when entering a shop)
var _current_shop: Dictionary = {}

# Shop database loaded from JSON
var _shop_database: Dictionary = {}
var _shop_types: Dictionary = {}


func _ready() -> void:
	_load_shop_database()
	print("ShopSystem initialized with ", _shop_database.size(), " shops")


## Load shop definitions from JSON file
func _load_shop_database() -> void:
	var file_path = "res://resources/data/shops.json"

	if not FileAccess.file_exists(file_path):
		push_warning("ShopSystem: shops.json not found at ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("ShopSystem: Failed to open shops.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("ShopSystem: Failed to parse shops.json - ", json.get_error_message())
		return

	var data = json.get_data()

	_shop_database = data.get("shops", {})
	_shop_types = data.get("shop_types", {})


## Get a shop definition by ID
func get_shop(shop_id: String) -> Dictionary:
	if shop_id in _shop_database:
		# Return a deep copy so the original isn't modified
		return _shop_database[shop_id].duplicate(true)
	return {}


## Get all available shop IDs
func get_shop_ids() -> Array:
	return _shop_database.keys()


## Open a shop by ID (loads from database)
func open_shop_by_id(shop_id: String) -> bool:
	var shop = get_shop(shop_id)
	if shop.is_empty():
		push_warning("ShopSystem: Shop not found - ", shop_id)
		return false
	open_shop(shop)
	return true


# ============================================
# PRICE CALCULATIONS
# ============================================

## Calculate buy price for an item (with Trade skill discount)
func get_buy_price(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return 0

	var base_price = item.get("value", 10)
	var discount = _get_trade_discount()
	return int(base_price * (1.0 - discount))


## Calculate sell price for an item
func get_sell_price(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return 0

	var base_price = item.get("value", 10)
	var bonus = _get_trade_discount() * 0.5  # Half the discount as bonus to sell price
	return int(base_price * SELL_PRICE_RATIO * (1.0 + bonus))


## Calculate cost to learn a spell
func get_spell_cost(spell_id: String) -> int:
	var spell = CombatManager.get_spell(spell_id)
	if spell.is_empty():
		return 0

	var level = spell.get("level", 1)
	var base_cost = SPELL_BASE_COST * level
	var discount = _get_trade_discount()
	return int(base_cost * (1.0 - discount))


## Calculate cost to train an attribute
func get_attribute_training_cost() -> int:
	var discount = _get_trade_discount()
	return int(ATTRIBUTE_TRAINING_COST * (1.0 - discount))


## Calculate cost to train a skill to next level
func get_skill_training_cost(current_level: int) -> int:
	if current_level < 0 or current_level >= SKILL_TRAINING_COSTS.size():
		return 0  # Max level or invalid

	var base_cost = SKILL_TRAINING_COSTS[current_level]
	var discount = _get_trade_discount()
	return int(base_cost * (1.0 - discount))


## Get best Trade skill level from party
func _get_trade_discount() -> float:
	var best_trade = 0

	if CharacterSystem:
		for character in CharacterSystem.get_party():
			var trade_level = character.get("skills", {}).get("trade", 0)
			if trade_level > best_trade:
				best_trade = trade_level

	return best_trade * TRADE_SKILL_DISCOUNT


# ============================================
# BUYING AND SELLING ITEMS
# ============================================

## Buy an item from current shop
func buy_item(item_id: String) -> Dictionary:
	var price = get_buy_price(item_id)

	if not GameState.can_afford(price):
		return {"success": false, "reason": "Not enough gold"}

	# Check if shop has item in stock
	if not _current_shop.is_empty():
		var stock = _current_shop.get("items", {})
		if item_id in stock:
			if stock[item_id] <= 0:
				return {"success": false, "reason": "Out of stock"}
			stock[item_id] -= 1

	# Process purchase
	if not GameState.spend_gold(price):
		return {"success": false, "reason": "Transaction failed"}

	ItemSystem.add_to_inventory(item_id)
	item_purchased.emit(item_id, price)

	var item = ItemSystem.get_item(item_id)
	return {"success": true, "item_name": item.get("name", item_id), "price": price}


## Sell an item from inventory
func sell_item(item_id: String) -> Dictionary:
	# Check if item is in inventory
	if ItemSystem.get_inventory_count(item_id) <= 0:
		return {"success": false, "reason": "Item not in inventory"}

	var price = get_sell_price(item_id)

	# Process sale
	ItemSystem.remove_from_inventory(item_id)
	GameState.add_gold(price)
	item_sold.emit(item_id, price)

	var item = ItemSystem.get_item(item_id)
	return {"success": true, "item_name": item.get("name", item_id), "price": price}


# ============================================
# SPELL LEARNING
# ============================================

## Purchase spell learning for a character
func buy_spell(character: Dictionary, spell_id: String) -> Dictionary:
	# Check if character already knows spell
	if CharacterSystem.knows_spell(character, spell_id):
		return {"success": false, "reason": "Already knows this spell"}

	# Check skill requirements
	var spell = CombatManager.get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "Spell not found"}

	var required_level = spell.get("level", 1)
	var schools = spell.get("schools", [])
	var skills = character.get("skills", {})
	var has_skill = false

	for school in schools:
		var skill_name = school + "_magic" if school in ["earth", "water", "fire", "air", "space"] else school
		var skill_level = skills.get(skill_name, 0)
		if skill_level >= required_level:
			has_skill = true
			break

	if not has_skill:
		return {"success": false, "reason": "Insufficient magic skill"}

	# Check if shop offers this spell
	if not _current_shop.is_empty():
		var spells_offered = _current_shop.get("spells", [])
		if not spells_offered.is_empty() and spell_id not in spells_offered:
			return {"success": false, "reason": "Spell not available here"}

	var price = get_spell_cost(spell_id)

	if not GameState.can_afford(price):
		return {"success": false, "reason": "Not enough gold"}

	# Process purchase
	if not GameState.spend_gold(price):
		return {"success": false, "reason": "Transaction failed"}

	CharacterSystem.learn_spell(character, spell_id)
	spell_purchased.emit(spell_id, price)

	return {"success": true, "spell_name": spell.get("name", spell_id), "price": price}


# ============================================
# TRAINING SERVICES
# ============================================

## Purchase attribute training for a character
func buy_attribute_training(character: Dictionary, attribute: String) -> Dictionary:
	if attribute not in character.get("attributes", {}):
		return {"success": false, "reason": "Invalid attribute"}

	# Check if shop offers attribute training
	if not _current_shop.is_empty():
		var training = _current_shop.get("training", {})
		var attrs_offered = training.get("attributes", [])
		if not attrs_offered.is_empty() and attribute not in attrs_offered:
			return {"success": false, "reason": "Training not available here"}

	var price = get_attribute_training_cost()

	if not GameState.can_afford(price):
		return {"success": false, "reason": "Not enough gold"}

	# Process purchase
	if not GameState.spend_gold(price):
		return {"success": false, "reason": "Transaction failed"}

	# Directly increase attribute (bypasses XP cost)
	character.attributes[attribute] += 1
	CharacterSystem.update_derived_stats(character)
	CharacterSystem.character_updated.emit(character)

	training_purchased.emit("attribute", attribute, price)

	return {"success": true, "attribute": attribute, "new_value": character.attributes[attribute], "price": price}


## Purchase skill training for a character
func buy_skill_training(character: Dictionary, skill: String) -> Dictionary:
	var current_level = character.get("skills", {}).get(skill, 0)

	if current_level >= 5:
		return {"success": false, "reason": "Skill already at maximum level"}

	# Check if shop offers skill training
	if not _current_shop.is_empty():
		var training = _current_shop.get("training", {})
		var skills_offered = training.get("skills", [])
		if not skills_offered.is_empty() and skill not in skills_offered:
			return {"success": false, "reason": "Training not available here"}

	var price = get_skill_training_cost(current_level)

	if price == 0:
		return {"success": false, "reason": "Cannot train this skill"}

	if not GameState.can_afford(price):
		return {"success": false, "reason": "Not enough gold"}

	# Process purchase
	if not GameState.spend_gold(price):
		return {"success": false, "reason": "Transaction failed"}

	# Directly increase skill (bypasses XP cost)
	CharacterSystem.set_skill_level(character, skill, current_level + 1)
	CharacterSystem.character_updated.emit(character)

	training_purchased.emit("skill", skill, price)

	return {"success": true, "skill": skill, "new_level": current_level + 1, "price": price}


# ============================================
# SHOP MANAGEMENT
# ============================================

## Set the current active shop
func open_shop(shop_data: Dictionary) -> void:
	_current_shop = shop_data
	print("Shop opened: ", shop_data.get("name", "Unknown Shop"))


## Close the current shop
func close_shop() -> void:
	_current_shop = {}
	print("Shop closed")


## Get current shop data
func get_current_shop() -> Dictionary:
	return _current_shop


## Check if a shop is currently open
func is_shop_open() -> bool:
	return not _current_shop.is_empty()


## Create a shop data structure
## shop_type can be: "general", "spell_trainer", "skill_trainer", "mixed"
static func create_shop(shop_name: String, shop_type: String = "general") -> Dictionary:
	var shop: Dictionary = {
		"name": shop_name,
		"type": shop_type,
		"items": {},  # item_id -> quantity (-1 for unlimited)
		"spells": [],  # spell_ids available to learn
		"training": {
			"attributes": [],  # attribute names available
			"skills": []  # skill names available
		}
	}
	return shop


## Add items to a shop's inventory
static func add_shop_items(shop: Dictionary, items: Dictionary) -> void:
	for item_id in items:
		shop.items[item_id] = items[item_id]


## Add spells to a shop's offerings
static func add_shop_spells(shop: Dictionary, spell_ids: Array) -> void:
	for spell_id in spell_ids:
		if spell_id not in shop.spells:
			shop.spells.append(spell_id)


## Add training options to a shop
static func add_shop_training(shop: Dictionary, attributes: Array = [], skills: Array = []) -> void:
	for attr in attributes:
		if attr not in shop.training.attributes:
			shop.training.attributes.append(attr)
	for skill in skills:
		if skill not in shop.training.skills:
			shop.training.skills.append(skill)
