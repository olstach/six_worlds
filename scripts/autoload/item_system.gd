extends Node
## ItemSystem - Manages item database, inventory, and equipment operations
##
## This singleton handles:
## - Loading and accessing item definitions from JSON
## - Party-wide shared inventory management
## - Equipment operations (equip, unequip, swap)
## - Stat calculation from equipped items

# Signals for UI updates
signal inventory_changed()
signal item_equipped(character: Dictionary, slot: String, item_id: String)
signal item_unequipped(character: Dictionary, slot: String, item_id: String)
signal item_used(item_id: String, item: Dictionary)

# Item database loaded from JSON
var _item_database: Dictionary = {}
var _item_types: Dictionary = {}
var _rarities: Dictionary = {}

# Party-wide shared inventory: Array of {item_id: String, quantity: int}
# Equipment doesn't stack, so quantity is always 1 for equipment
var _inventory: Array[Dictionary] = []

# Maximum inventory size (can be expanded via upgrades later)
var max_inventory_size: int = 60

func _ready() -> void:
	_load_item_database()
	print("ItemSystem initialized with ", _item_database.size(), " items")


## Load item definitions from JSON file
func _load_item_database() -> void:
	var file_path = "res://resources/data/items.json"

	if not FileAccess.file_exists(file_path):
		push_error("ItemSystem: items.json not found at ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("ItemSystem: Failed to open items.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("ItemSystem: Failed to parse items.json - ", json.get_error_message())
		return

	var data = json.get_data()

	_item_database = data.get("items", {})
	_item_types = data.get("item_types", {})
	_rarities = data.get("rarities", {})


## Get an item definition by ID
func get_item(item_id: String) -> Dictionary:
	if item_id in _item_database:
		var item = _item_database[item_id].duplicate(true)
		item["id"] = item_id  # Include the ID in the returned data
		return item
	return {}


## Check if an item exists
func item_exists(item_id: String) -> bool:
	return item_id in _item_database


## Get all items of a specific type (e.g., "sword", "helmet")
func get_items_by_type(item_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in _item_database:
		var item = _item_database[item_id]
		if item.get("type", "") == item_type:
			var item_copy = item.duplicate(true)
			item_copy["id"] = item_id
			result.append(item_copy)
	return result


## Get all items valid for a specific equipment slot
func get_items_for_slot(slot_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for item_id in _item_database:
		var item = _item_database[item_id]
		var item_type = item.get("type", "")

		# Check if this item type is valid for the slot
		if item_type in _item_types:
			var type_info = _item_types[item_type]
			var valid_slots = type_info.get("slots", [])
			if slot_id in valid_slots or item.get("slot", "") == slot_id:
				var item_copy = item.duplicate(true)
				item_copy["id"] = item_id
				result.append(item_copy)

	return result


## Get items from inventory that can be equipped to a specific slot
func get_inventory_items_for_slot(slot_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for inv_entry in _inventory:
		var item_id = inv_entry.get("item_id", "")
		var item = get_item(item_id)
		if item.is_empty():
			continue

		var item_type = item.get("type", "")

		# Check if this item type is valid for the slot
		if item_type in _item_types:
			var type_info = _item_types[item_type]
			var valid_slots = type_info.get("slots", [])
			if slot_id in valid_slots or item.get("slot", "") == slot_id:
				item["inventory_index"] = _inventory.find(inv_entry)
				result.append(item)

	return result


## Check if a character meets requirements to equip an item
func can_equip(character: Dictionary, item_id: String) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty():
		return {"can_equip": false, "reason": "Item not found"}

	var requirements = item.get("requirements", {})
	var attributes = character.get("attributes", {})

	for req_attr in requirements:
		var required_value = requirements[req_attr]
		var char_value = attributes.get(req_attr, 0)
		if char_value < required_value:
			return {
				"can_equip": false,
				"reason": "Requires %s %d (you have %d)" % [req_attr.capitalize(), required_value, char_value]
			}

	return {"can_equip": true, "reason": ""}


## Equip an item from inventory to a character slot
func equip_item(character: Dictionary, item_id: String, slot: String) -> bool:
	# Check if item is in inventory
	var inv_index = _find_inventory_item(item_id)
	if inv_index == -1:
		push_warning("ItemSystem: Item ", item_id, " not in inventory")
		return false

	# Check requirements
	var can_result = can_equip(character, item_id)
	if not can_result.can_equip:
		push_warning("ItemSystem: Cannot equip - ", can_result.reason)
		return false

	# Check if slot is valid for this item
	var item = get_item(item_id)
	var item_type = item.get("type", "")
	var valid_slots: Array = []

	if item_type in _item_types:
		valid_slots = _item_types[item_type].get("slots", [])

	if not slot in valid_slots and item.get("slot", "") != slot:
		push_warning("ItemSystem: Item cannot be equipped to slot ", slot)
		return false

	# Check two-handed weapon handling
	var is_two_handed = item.get("two_handed", false)

	# Unequip current item in slot (if any)
	var current_item = get_equipped_item(character, slot)
	if current_item != "":
		unequip_item(character, slot)

	# Handle two-handed weapons - also clear off-hand
	if is_two_handed and slot == "weapon_main":
		var offhand_item = get_equipped_item(character, "weapon_off")
		if offhand_item != "":
			unequip_item(character, "weapon_off")

	# Handle equipping to off-hand when main has two-hander
	if slot == "weapon_off":
		var main_item_id = get_equipped_item(character, "weapon_main")
		if main_item_id != "":
			var main_item = get_item(main_item_id)
			if main_item.get("two_handed", false):
				unequip_item(character, "weapon_main")

	# Remove from inventory
	remove_from_inventory(item_id, 1)

	# Equip to character
	_set_equipped_item(character, slot, item_id)

	# Update derived stats
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
		CharacterSystem.character_updated.emit(character)

	item_equipped.emit(character, slot, item_id)
	return true


## Unequip an item from a slot back to inventory
func unequip_item(character: Dictionary, slot: String) -> bool:
	var item_id = get_equipped_item(character, slot)
	if item_id == "":
		return false  # Nothing equipped

	# Check if inventory has space
	if _inventory.size() >= max_inventory_size:
		push_warning("ItemSystem: Inventory full, cannot unequip")
		return false

	# Remove from slot
	_set_equipped_item(character, slot, "")

	# Add to inventory
	add_to_inventory(item_id, 1)

	# Update derived stats
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
		CharacterSystem.character_updated.emit(character)

	item_unequipped.emit(character, slot, item_id)
	return true


## Get the item ID equipped in a slot
func get_equipped_item(character: Dictionary, slot: String) -> String:
	var equipment = character.get("equipment", {})

	# Handle weapon set slots
	if slot == "weapon_main" or slot == "weapon_off":
		var active_set = character.get("active_weapon_set", 1)
		var set_key = "weapon_set_%d" % active_set
		var weapon_set = equipment.get(set_key, {})
		if slot == "weapon_main":
			return weapon_set.get("main", "")
		else:
			return weapon_set.get("off", "")

	return equipment.get(slot, "")


## Set equipped item in a slot (internal helper)
func _set_equipped_item(character: Dictionary, slot: String, item_id: String) -> void:
	if not "equipment" in character:
		character["equipment"] = {}

	var equipment = character.equipment

	# Handle weapon set slots
	if slot == "weapon_main" or slot == "weapon_off":
		var active_set = character.get("active_weapon_set", 1)
		var set_key = "weapon_set_%d" % active_set
		if not set_key in equipment:
			equipment[set_key] = {"main": "", "off": ""}
		if slot == "weapon_main":
			equipment[set_key]["main"] = item_id
		else:
			equipment[set_key]["off"] = item_id
	else:
		equipment[slot] = item_id


## Swap weapon sets (1 <-> 2)
func swap_weapon_set(character: Dictionary) -> void:
	var current_set = character.get("active_weapon_set", 1)
	character["active_weapon_set"] = 2 if current_set == 1 else 1

	# Update derived stats since weapons changed
	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
		CharacterSystem.character_updated.emit(character)


## Set active weapon set
func set_weapon_set(character: Dictionary, set_num: int) -> void:
	if set_num != 1 and set_num != 2:
		return
	character["active_weapon_set"] = set_num

	if CharacterSystem:
		CharacterSystem.update_derived_stats(character)
		CharacterSystem.character_updated.emit(character)


## Add item to party inventory
func add_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if not item_exists(item_id):
		push_warning("ItemSystem: Cannot add unknown item ", item_id)
		return false

	var item = get_item(item_id)
	var item_type = item.get("type", "")
	var type_info = _item_types.get(item_type, {})
	var category = type_info.get("category", "")

	# Equipment doesn't stack - add separate entries
	# (Consumables will stack when implemented later)
	var is_stackable = category == "consumable"  # Future support

	if is_stackable:
		# Find existing stack
		var existing_index = _find_inventory_item(item_id)
		if existing_index != -1:
			_inventory[existing_index]["quantity"] += quantity
			inventory_changed.emit()
			return true

	# Add new entries
	for i in range(quantity):
		if _inventory.size() >= max_inventory_size:
			push_warning("ItemSystem: Inventory full")
			inventory_changed.emit()
			return false
		_inventory.append({"item_id": item_id, "quantity": 1})

	inventory_changed.emit()
	return true


## Remove item from inventory
func remove_from_inventory(item_id: String, quantity: int = 1) -> bool:
	var removed = 0

	# Remove entries (works for both stackable and non-stackable)
	while removed < quantity:
		var index = _find_inventory_item(item_id)
		if index == -1:
			break

		var entry = _inventory[index]
		if entry["quantity"] > quantity - removed:
			entry["quantity"] -= (quantity - removed)
			removed = quantity
		else:
			removed += entry["quantity"]
			_inventory.remove_at(index)

	if removed > 0:
		inventory_changed.emit()

	return removed == quantity


## Find inventory index for an item
func _find_inventory_item(item_id: String) -> int:
	for i in range(_inventory.size()):
		if _inventory[i].get("item_id", "") == item_id:
			return i
	return -1


## Get count of item in inventory
func get_inventory_count(item_id: String) -> int:
	var count = 0
	for entry in _inventory:
		if entry.get("item_id", "") == item_id:
			count += entry.get("quantity", 0)
	return count


## Get all consumable items in inventory (with full details and quantity)
func get_consumables_in_inventory() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _inventory:
		var item_id = entry.get("item_id", "")
		var item = get_item(item_id)
		if item.is_empty():
			continue
		var item_type = item.get("type", "")
		var type_info = _item_types.get(item_type, {})
		if type_info.get("category", "") == "consumable":
			var detailed = item.duplicate(true)
			detailed["quantity"] = entry.get("quantity", 1)
			result.append(detailed)
	return result


## Use a consumable item: validates, removes 1 from inventory, emits signal
func use_consumable(item_id: String) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found"}

	var item_type = item.get("type", "")
	var type_info = _item_types.get(item_type, {})
	if type_info.get("category", "") != "consumable":
		return {"success": false, "reason": "Not a consumable"}

	if get_inventory_count(item_id) <= 0:
		return {"success": false, "reason": "None in inventory"}

	remove_from_inventory(item_id, 1)
	item_used.emit(item_id, item)
	return {"success": true, "item": item}


## Get full inventory
func get_inventory() -> Array[Dictionary]:
	return _inventory


## Get inventory with full item data
func get_inventory_with_details() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _inventory:
		var item_id = entry.get("item_id", "")
		var item = get_item(item_id)
		if not item.is_empty():
			item["quantity"] = entry.get("quantity", 1)
			result.append(item)
	return result


## Clear inventory (for new game)
func clear_inventory() -> void:
	_inventory.clear()
	inventory_changed.emit()


## Calculate total stat bonuses from all equipped items
func calculate_equipment_stats(character: Dictionary) -> Dictionary:
	var bonuses: Dictionary = {
		"damage": 0,
		"armor": 0,
		"dodge": 0,
		"accuracy": 0,
		"crit_chance": 0,
		"spellpower": 0,
		"max_hp": 0,
		"max_mana": 0,
		"max_stamina": 0,
		"initiative": 0,
		"movement": 0,
		"luck": 0,
		"armor_pierce": 0,
		# Attribute bonuses
		"strength": 0,
		"finesse": 0,
		"constitution": 0,
		"focus": 0,
		"awareness": 0,
		"charm": 0
	}

	var equipment = character.get("equipment", {})

	# Standard slots
	var slots_to_check = ["head", "chest", "hand_l", "hand_r", "legs", "feet",
						  "ring1", "ring2", "amulet", "trinket"]

	for slot in slots_to_check:
		var item_id = equipment.get(slot, "")
		if item_id != "":
			_add_item_stats(item_id, bonuses)

	# Weapon set (active only)
	var active_set = character.get("active_weapon_set", 1)
	var set_key = "weapon_set_%d" % active_set
	var weapon_set = equipment.get(set_key, {})

	var main_id = weapon_set.get("main", "")
	var off_id = weapon_set.get("off", "")

	if main_id != "":
		_add_item_stats(main_id, bonuses)
	if off_id != "":
		_add_item_stats(off_id, bonuses)

	return bonuses


## Add an item's stats to a bonuses dictionary
func _add_item_stats(item_id: String, bonuses: Dictionary) -> void:
	var item = get_item(item_id)
	if item.is_empty():
		return

	var stats = item.get("stats", {})
	for stat_key in stats:
		if stat_key in bonuses:
			bonuses[stat_key] += stats[stat_key]
		else:
			bonuses[stat_key] = stats[stat_key]


## Get rarity color for an item
func get_rarity_color(item_id: String) -> Color:
	var item = get_item(item_id)
	if item.is_empty():
		return Color.WHITE

	var rarity = item.get("rarity", "common")
	var rarity_info = _rarities.get(rarity, {})
	var color_hex = rarity_info.get("color", "#FFFFFF")

	return Color.html(color_hex)


## Get item type info
func get_type_info(item_type: String) -> Dictionary:
	return _item_types.get(item_type, {})


## Add starter items to inventory (called when starting new game)
func add_starter_items() -> void:
	# Give player some basic starting equipment
	add_to_inventory("bronze_sword")
	add_to_inventory("short_bow")  # Ranged option
	add_to_inventory("leather_vest")
	add_to_inventory("leather_cap")
	add_to_inventory("leather_boots")
	add_to_inventory("copper_ring")
	add_to_inventory("travelers_amulet")
	# Starting consumables
	add_to_inventory("health_potion", 3)
	add_to_inventory("mana_potion", 2)
	print("ItemSystem: Added starter items to inventory")
