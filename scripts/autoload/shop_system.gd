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
signal barter_completed(items_traded: Array, gold_paid: int, item_received: String)

# Price modifiers
const SELL_PRICE_RATIO: float = 0.5  # Sell items for 50% of value
const TRADE_SKILL_DISCOUNT: float = 0.05  # 5% discount per Trade skill level
const CHARM_DISCOUNT_PER_POINT: float = 0.02  # 2% discount per Charm point above 10
const CHARM_BASELINE: int = 10  # Charm value considered "neutral"

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

## Calculate buy price for an item (with Trade skill + Charm discount + shop modifier)
func get_buy_price(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return 0

	var base_price = item.get("value", 10)
	var shop_modifier = _get_shop_price_modifier()
	var discount = _get_total_discount()
	return int(base_price * shop_modifier * (1.0 - discount))


## Calculate sell price for an item (Trade + Charm improve sell prices)
func get_sell_price(item_id: String) -> int:
	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return 0

	var base_price = item.get("value", 10)
	# For selling, discounts become bonuses (capped at 25% bonus)
	var bonus = min(_get_total_discount() * 0.5, 0.25)
	# Shop modifier inverted for selling (high markup shops pay less)
	var shop_modifier = _get_shop_price_modifier()
	var sell_modifier = 2.0 - shop_modifier if shop_modifier > 0 else 1.0
	return int(base_price * SELL_PRICE_RATIO * sell_modifier * (1.0 + bonus))


## Calculate cost to learn a spell (uses spell's base_cost or level-based default)
func get_spell_cost(spell_id: String) -> int:
	var spell = CombatManager.get_spell(spell_id)
	if spell.is_empty():
		return 0

	var level = spell.get("level", 1)
	# Use explicit base_cost if defined, otherwise level * SPELL_BASE_COST
	var base_cost = spell.get("base_cost", SPELL_BASE_COST * level)
	var shop_modifier = _get_shop_price_modifier()
	var discount = _get_total_discount()
	return int(base_cost * shop_modifier * (1.0 - discount))


## Calculate cost to train an attribute
func get_attribute_training_cost() -> int:
	var shop_modifier = _get_shop_price_modifier()
	var discount = _get_total_discount()
	return int(ATTRIBUTE_TRAINING_COST * shop_modifier * (1.0 - discount))


## Return the skill cap this trainer enforces (defaults to SKILL_MAX_LEVEL)
func get_trainer_skill_cap() -> int:
	if _current_shop.is_empty():
		return CharacterSystem.SKILL_MAX_LEVEL
	return _current_shop.get("training", {}).get("max_skill_level", CharacterSystem.SKILL_MAX_LEVEL)


## Calculate cost to train a skill to next level
func get_skill_training_cost(current_level: int) -> int:
	if current_level < 0 or current_level >= SKILL_TRAINING_COSTS.size():
		return 0  # Max level or invalid

	var base_cost = SKILL_TRAINING_COSTS[current_level]
	var shop_modifier = _get_shop_price_modifier()
	var discount = _get_total_discount()
	return int(base_cost * shop_modifier * (1.0 - discount))


## Get best Trade skill level from party
func _get_trade_discount() -> float:
	var best_trade = 0

	if CharacterSystem:
		for character in CharacterSystem.get_party():
			var trade_level = character.get("skills", {}).get("trade", 0)
			if trade_level > best_trade:
				best_trade = trade_level

	return best_trade * TRADE_SKILL_DISCOUNT


## Get Charm-based price modifier from party (best Charm in party)
func _get_charm_discount() -> float:
	var best_charm = CHARM_BASELINE

	if CharacterSystem:
		for character in CharacterSystem.get_party():
			var charm = character.get("attributes", {}).get("charm", CHARM_BASELINE)
			if charm > best_charm:
				best_charm = charm

	# Charm above baseline gives discount, below gives penalty
	var charm_diff = best_charm - CHARM_BASELINE
	return charm_diff * CHARM_DISCOUNT_PER_POINT


## Get total discount from Trade skill and Charm attribute
func _get_total_discount() -> float:
	var trade_discount = _get_trade_discount()
	var charm_discount = _get_charm_discount()
	# Combined discount, but cap at 50% max discount
	return min(trade_discount + charm_discount, 0.50)


## Get shop-specific price modifier (markup or discount)
func _get_shop_price_modifier() -> float:
	if _current_shop.is_empty():
		return 1.0
	return _current_shop.get("price_modifier", 1.0)


## Get price breakdown for UI display
## Returns dict with all modifiers affecting the current price
func get_price_breakdown(base_price: int) -> Dictionary:
	var trade_discount = _get_trade_discount()
	var charm_discount = _get_charm_discount()
	var total_discount = _get_total_discount()
	var shop_modifier = _get_shop_price_modifier()

	var final_price = int(base_price * shop_modifier * (1.0 - total_discount))

	return {
		"base_price": base_price,
		"shop_modifier": shop_modifier,
		"shop_name": _current_shop.get("name", ""),
		"trade_discount": trade_discount,
		"trade_discount_percent": int(trade_discount * 100),
		"charm_discount": charm_discount,
		"charm_discount_percent": int(charm_discount * 100),
		"total_discount": total_discount,
		"total_discount_percent": int(total_discount * 100),
		"final_price": final_price
	}


## Get readable summary of active price modifiers
func get_price_modifier_summary() -> String:
	var parts: Array[String] = []

	var trade_discount = _get_trade_discount()
	if trade_discount > 0:
		parts.append("Trade -%d%%" % int(trade_discount * 100))

	var charm_discount = _get_charm_discount()
	if charm_discount > 0:
		parts.append("Charm -%d%%" % int(charm_discount * 100))
	elif charm_discount < 0:
		parts.append("Charm +%d%%" % int(abs(charm_discount) * 100))

	var shop_modifier = _get_shop_price_modifier()
	if shop_modifier > 1.0:
		parts.append("Shop +%d%%" % int((shop_modifier - 1.0) * 100))
	elif shop_modifier < 1.0:
		parts.append("Shop -%d%%" % int((1.0 - shop_modifier) * 100))

	if parts.is_empty():
		return "No modifiers"

	return ", ".join(parts)


# ============================================
# SHOP BUYING RESTRICTIONS
# ============================================

## Check if current shop buys items at all
func shop_buys_items() -> bool:
	if _current_shop.is_empty():
		return true  # Default: can sell anywhere
	return _current_shop.get("buys_items", false)


## Check if current shop will buy a specific item
func can_sell_item_here(item_id: String) -> bool:
	if not shop_buys_items():
		return false

	# Check for item type restrictions
	var accepted_types = _current_shop.get("accepted_item_types", [])
	if accepted_types.is_empty():
		return true  # No restrictions, accepts all

	var item = ItemSystem.get_item(item_id)
	if item.is_empty():
		return false

	var item_type = item.get("type", "misc")
	return item_type in accepted_types


## Get list of item types this shop accepts (empty = all types)
func get_accepted_item_types() -> Array:
	if _current_shop.is_empty():
		return []
	return _current_shop.get("accepted_item_types", [])


# ============================================
# BARTER SYSTEM
# ============================================

## Calculate total trade value of offered items
func get_barter_value(item_ids: Array) -> int:
	var total = 0
	for item_id in item_ids:
		total += get_sell_price(item_id)
	return total


## Check if barter offer covers required price
## Returns dict with analysis of the barter offer
func analyze_barter_offer(target_price: int, offered_items: Array, offered_gold: int = 0) -> Dictionary:
	var items_value = get_barter_value(offered_items)
	var total_value = items_value + offered_gold
	var difference = target_price - total_value

	return {
		"target_price": target_price,
		"items_value": items_value,
		"gold_offered": offered_gold,
		"total_offered": total_value,
		"difference": difference,
		"is_sufficient": difference <= 0,
		"overpayment": max(0, -difference)
	}


## Buy an item using barter (items from inventory + optional gold)
func barter_buy_item(item_id: String, offered_items: Array, offered_gold: int = 0) -> Dictionary:
	var price = get_buy_price(item_id)

	# Validate offered items exist in inventory
	for offered_id in offered_items:
		if ItemSystem.get_inventory_count(offered_id) <= 0:
			return {"success": false, "reason": "Item not in inventory: " + offered_id}

	# Check if shop accepts these items
	if not _current_shop.is_empty() and shop_buys_items():
		for offered_id in offered_items:
			if not can_sell_item_here(offered_id):
				var item = ItemSystem.get_item(offered_id)
				return {"success": false, "reason": "Shop won't accept: " + item.get("name", offered_id)}

	# Analyze the offer
	var analysis = analyze_barter_offer(price, offered_items, offered_gold)

	if not analysis.is_sufficient:
		return {"success": false, "reason": "Offer insufficient by %d gold" % analysis.difference}

	# Check gold portion
	if offered_gold > 0 and not GameState.can_afford(offered_gold):
		return {"success": false, "reason": "Not enough gold"}

	# Check if shop has item in stock
	if not _current_shop.is_empty():
		var stock = _current_shop.get("items", {})
		if item_id in stock:
			if stock[item_id] <= 0:
				return {"success": false, "reason": "Out of stock"}
			stock[item_id] -= 1

	# Process the barter - remove offered items
	for offered_id in offered_items:
		ItemSystem.remove_from_inventory(offered_id)

	# Spend gold portion
	if offered_gold > 0:
		GameState.spend_gold(offered_gold)

	# Give purchased item
	ItemSystem.add_to_inventory(item_id)

	barter_completed.emit(offered_items, offered_gold, item_id)
	item_purchased.emit(item_id, price)

	var item = ItemSystem.get_item(item_id)
	return {
		"success": true,
		"item_name": item.get("name", item_id),
		"price": price,
		"items_traded": offered_items,
		"gold_paid": offered_gold,
		"overpayment": analysis.overpayment
	}


## Buy a spell using barter
func barter_buy_spell(character: Dictionary, spell_id: String, offered_items: Array, offered_gold: int = 0) -> Dictionary:
	# Check if character already knows spell
	if CharacterSystem.knows_spell(character, spell_id):
		return {"success": false, "reason": "Already knows this spell"}

	# Check skill requirements (same as buy_spell)
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

	# Validate offered items
	for offered_id in offered_items:
		if ItemSystem.get_inventory_count(offered_id) <= 0:
			return {"success": false, "reason": "Item not in inventory: " + offered_id}

	# Check barter offer
	var analysis = analyze_barter_offer(price, offered_items, offered_gold)
	if not analysis.is_sufficient:
		return {"success": false, "reason": "Offer insufficient by %d gold" % analysis.difference}

	if offered_gold > 0 and not GameState.can_afford(offered_gold):
		return {"success": false, "reason": "Not enough gold"}

	# Process barter
	for offered_id in offered_items:
		ItemSystem.remove_from_inventory(offered_id)

	if offered_gold > 0:
		GameState.spend_gold(offered_gold)

	CharacterSystem.learn_spell(character, spell_id)
	barter_completed.emit(offered_items, offered_gold, spell_id)
	spell_purchased.emit(spell_id, price)

	return {
		"success": true,
		"spell_name": spell.get("name", spell_id),
		"price": price,
		"items_traded": offered_items,
		"gold_paid": offered_gold
	}


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
	# Check if shop buys items
	if not shop_buys_items():
		return {"success": false, "reason": "This shop doesn't buy items"}

	# Check if shop accepts this item type
	if not can_sell_item_here(item_id):
		var item = ItemSystem.get_item(item_id)
		return {"success": false, "reason": "Shop won't buy this type of item"}

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

	if current_level >= CharacterSystem.SKILL_MAX_LEVEL:
		return {"success": false, "reason": "Skill already at maximum level"}

	# Check if shop offers skill training
	if not _current_shop.is_empty():
		var training = _current_shop.get("training", {})
		var skills_offered = training.get("skills", [])
		if not skills_offered.is_empty() and skill not in skills_offered:
			return {"success": false, "reason": "Training not available here"}

		# Enforce trainer cap if set
		var cap = training.get("max_skill_level", CharacterSystem.SKILL_MAX_LEVEL)
		if current_level >= cap:
			return {"success": false, "reason": "Trainer can't teach beyond level %d" % cap}

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

## Set the current active shop. Generates procedural inventory if configured.
func open_shop(shop_data: Dictionary) -> void:
	_current_shop = shop_data
	if _current_shop.get("type", "") == "spell_guild":
		_generate_guild_spells()
	_generate_procedural_stock()
	_resolve_template_items()


## Close the current shop and clean up any unsold procedural items
func close_shop() -> void:
	# Clean up runtime items that were generated for this shop but not purchased
	var items = _current_shop.get("items", {})
	for item_id in items:
		if ItemSystem.is_runtime_item(item_id):
			# Only remove from runtime registry if it's not in the player's inventory
			if ItemSystem.get_inventory_count(item_id) <= 0:
				ItemSystem.remove_runtime_item(item_id)
	_current_shop = {}


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


## Generate procedural items for a shop based on its procedural_slots config.
## procedural_slots is an array of generation rules, e.g.:
##   [{"category": "weapon", "rarity": "uncommon", "count": 2},
##    {"category": "talisman", "rarity": "common", "count": 1}]
## If no procedural_slots are defined, shops get auto-generated stock
## based on their type and existing inventory categories.
func _generate_procedural_stock() -> void:
	var slots = _current_shop.get("procedural_slots", [])

	# If no explicit config, auto-generate based on shop type
	if slots.is_empty():
		slots = _get_default_procedural_slots()

	if slots.is_empty():
		return

	var items = _current_shop.get("items", {})
	for slot in slots:
		var category: String = slot.get("category", "")
		var rarity: String = slot.get("rarity", "common")
		var item_type: String = slot.get("type", "")
		var count: int = slot.get("count", 1)

		for i in range(count):
			var gen_id: String = ""
			match category:
				"weapon":
					if slot.get("match_party_skill", false):
						gen_id = ItemSystem.generate_weapon_for_party(rarity)
					else:
						gen_id = ItemSystem.generate_weapon(item_type, rarity)
				"armor":
					gen_id = ItemSystem.generate_armor(item_type, rarity)
				"talisman":
					gen_id = ItemSystem.generate_talisman(rarity)

			if gen_id != "":
				items[gen_id] = 1  # Procedural items are unique, qty 1

	_current_shop["items"] = items


## Resolve any random_generate template items in the shop inventory,
## replacing them with actual procedural items.
func _resolve_template_items() -> void:
	var items = _current_shop.get("items", {})
	var to_remove: Array[String] = []
	var to_add: Dictionary = {}

	for item_id in items:
		if ItemSystem.is_template_item(item_id):
			var qty = items[item_id]
			to_remove.append(item_id)
			# Generate one procedural item per quantity
			for i in range(qty):
				var gen_id = ItemSystem.resolve_random_generate(item_id)
				if gen_id != "":
					to_add[gen_id] = 1

	# Swap templates for generated items
	for item_id in to_remove:
		items.erase(item_id)
	for item_id in to_add:
		items[item_id] = to_add[item_id]

	_current_shop["items"] = items


## Determine default procedural slots based on shop type and existing stock.
## General/mixed shops get a few procedural weapons and armor.
## Spell trainers get a talisman. Weapon masters get procedural weapons.
func _get_default_procedural_slots() -> Array:
	var shop_type = _current_shop.get("type", "general")
	var slots: Array = []

	# Pick a rarity weighted toward common/uncommon for standard shops
	var rarity_pool: Array[String] = ["common", "common", "uncommon"]
	var pick_rarity := func() -> String:
		return rarity_pool[randi() % rarity_pool.size()]

	match shop_type:
		"general":
			# 1-2 procedural weapons + 1 armor piece
			slots.append({"category": "weapon", "match_party_skill": true,
				"rarity": pick_rarity.call(), "count": 1 + randi() % 2})
			slots.append({"category": "armor", "rarity": pick_rarity.call(), "count": 1})
		"spell_trainer":
			# 1 talisman (casters want trinkets)
			slots.append({"category": "talisman", "rarity": pick_rarity.call(), "count": 1})
		"skill_trainer":
			# Check if this is a combat trainer — if so, add weapons
			var training = _current_shop.get("training", {})
			var skills = training.get("skills", [])
			var has_combat = false
			for s in skills:
				if s in ["swords", "axes", "maces", "spears", "ranged", "daggers"]:
					has_combat = true
					break
			if has_combat:
				slots.append({"category": "weapon", "match_party_skill": true,
					"rarity": pick_rarity.call(), "count": 1 + randi() % 2})
			else:
				slots.append({"category": "talisman", "rarity": pick_rarity.call(), "count": 1})
		"mixed":
			# A bit of everything
			slots.append({"category": "weapon", "match_party_skill": true,
				"rarity": pick_rarity.call(), "count": 1})
			slots.append({"category": "armor", "rarity": pick_rarity.call(), "count": 1})
			slots.append({"category": "talisman", "rarity": pick_rarity.call(), "count": 1})

	return slots


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


# ============================================
# SPELL GUILD CURRICULUM GENERATION
# ============================================

## Generate and cache the spell curriculum for a spell_guild shop.
## guild_school: the school name (e.g. "Fire", "Black", "Sorcery")
## guild_max_tier: highest tier offered (1-5, default 5; hell guilds use 3)
## Curriculum: 1 spell at max_tier, 2 at max_tier-1, 3 at max_tier-2.
## Results are cached in GameState.guild_spell_lists by object_id for stable revisits.
func _generate_guild_spells() -> void:
	var object_id: String = _current_shop.get("_object_id", "")
	var school: String = _current_shop.get("guild_school", "")
	var max_tier: int = clamp(int(_current_shop.get("guild_max_tier", 5)), 1, 5)

	if school.is_empty():
		return

	# Return cached list if available
	if object_id != "" and GameState.guild_spell_lists.has(object_id):
		_current_shop["spells"] = GameState.guild_spell_lists[object_id]
		return

	# tier → spell level lookup (matches the 0-10 skill scale remapping)
	var tier_to_level: Array = [0, 1, 3, 5, 7, 9]  # index = tier

	var chosen_spells: Array = []

	# Add 1 at max_tier, 2 at max_tier-1, 3 at max_tier-2
	for offset in range(3):
		var tier: int = clamp(max_tier - offset, 1, 5)
		var count: int = offset + 1
		var spell_level: int = tier_to_level[tier]
		var candidates: Array = _get_guild_spell_candidates(school, spell_level, chosen_spells)
		candidates.shuffle()
		for i in range(min(count, candidates.size())):
			chosen_spells.append(candidates[i])

	_current_shop["spells"] = chosen_spells

	# Cache for stability across revisits
	if object_id != "":
		GameState.guild_spell_lists[object_id] = chosen_spells


## Return all spell IDs matching the given school at the given level, excluding already-chosen.
## Checks both "schools" array and "subschool" field to cover Sorcery, Enchantment, etc.
func _get_guild_spell_candidates(school: String, level: int, excluded: Array) -> Array:
	var candidates: Array = []
	var school_lower: String = school.to_lower()
	var spell_db: Dictionary = CharacterSystem.get_spell_database()

	for spell_id in spell_db:
		if spell_id in excluded:
			continue
		var spell: Dictionary = spell_db[spell_id]
		if int(spell.get("level", 0)) != level:
			continue
		var matches: bool = false
		for s in spell.get("schools", []):
			if s.to_lower() == school_lower:
				matches = true
				break
		if not matches and spell.get("subschool", "").to_lower() == school_lower:
			matches = true
		if matches:
			candidates.append(spell_id)

	return candidates
