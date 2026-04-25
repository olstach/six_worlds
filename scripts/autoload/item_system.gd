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

# Runtime-generated items (procedural equipment/talismans)
# Keyed by "gen_XXXX" IDs, same schema as _item_database entries
var _runtime_items: Dictionary = {}
var _next_runtime_id: int = 1

# Party-wide shared inventory: Array of {item_id: String, quantity: int}
# Equipment doesn't stack, so quantity is always 1 for equipment
var _inventory: Array[Dictionary] = []

var ammo_types: Dictionary = {}  # ammo_id -> ammo definition from ammo.json

# Maximum inventory size (can be expanded via upgrades later)
var max_inventory_size: int = 60

func _ready() -> void:
	_load_item_database()
	_load_ammo()
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


## Get an item definition by ID (checks static DB first, then runtime items, then ammo)
func get_item(item_id: String) -> Dictionary:
	if item_id in _item_database:
		var item = _item_database[item_id].duplicate(true)
		item["id"] = item_id
		return item
	if item_id in _runtime_items:
		var item = _runtime_items[item_id].duplicate(true)
		item["id"] = item_id
		return item
	if item_id in ammo_types:
		var item = ammo_types[item_id].duplicate(true)
		item["id"] = item_id
		return item
	return {}


## Check if an item exists (static, runtime, or ammo)
func item_exists(item_id: String) -> bool:
	return item_id in _item_database or item_id in _runtime_items or item_id in ammo_types


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

	# Reject if the target body part is missing or has a locked natural weapon
	if BodySystem:
		var part := BodySystem.get_part_for_slot(character, slot)
		if not part.is_empty() and part.get("id", "") in character.get("body_plan", {}).get("missing_parts", []):
			push_warning("ItemSystem: Cannot equip to slot '%s' — body part is missing." % slot)
			return false
		if BodySystem.is_slot_locked(character, slot):
			push_warning("ItemSystem: Slot '%s' is locked by a natural weapon." % slot)
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
	# Consumables and ammo stack
	var is_stackable = category == "consumable" or item_id in ammo_types

	if is_stackable:
		# Find existing stack and add to it, or create one entry with full quantity
		var existing_index = _find_inventory_item(item_id)
		if existing_index != -1:
			_inventory[existing_index]["quantity"] += quantity
		else:
			if _inventory.size() >= max_inventory_size:
				push_warning("ItemSystem: Inventory full")
				return false
			_inventory.append({"item_id": item_id, "quantity": quantity})
		inventory_changed.emit()
		return true

	# Non-stackable: add separate entries (equipment, etc.)
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
	clear_runtime_items()
	inventory_changed.emit()


## Update durability on a runtime-generated item (static items don't track wear).
## Called by CombatManager after each weapon use.
func update_item_durability(item_id: String, new_value: int) -> void:
	if item_id in _runtime_items:
		_runtime_items[item_id]["durability"] = new_value


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
		"charm": 0,
		# Resistance bonuses collected from item passives: {"fire": 15, "physical": 25, ...}
		"resistances": {}
	}

	var equipment = character.get("equipment", {})

	# Standard slots — driven by body plan so multi-armed characters pick up extra hand slots.
	# hand_r mirrors hand_l for glove stats; BodySystem.get_equipment_slots skips empty equip_slots.
	var slots_to_check: Array[String] = BodySystem.get_equipment_slots(character) if BodySystem else [
		"head", "chest", "hand_l", "hand_r", "legs", "feet",
		"ring1", "ring2", "amulet", "trinket1", "trinket2"
	]

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

	# Set bonus: Dorje + Drilbu paired together
	# Both items carry set_pair = "dorje_drilbu"; matching set on both slots activates the bonus.
	if main_id != "" and off_id != "":
		var main_item = get_item(main_id)
		var off_item = get_item(off_id)
		var main_set = main_item.get("set_pair", "")
		var off_set = off_item.get("set_pair", "")
		if main_set != "" and main_set == off_set:
			# Bonus: +3 spellpower, +3 max_mana, +2 initiative (Vajra and Bell in harmony)
			bonuses["spellpower"] += 3
			bonuses["max_mana"] += 3
			bonuses["initiative"] += 2
			# Store the active set name for combat effects (e.g. opener bonus)
			bonuses["active_set_bonus"] = main_set

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

	# Collect resistance bonuses from passive effects (e.g. "fire_resistance": 15)
	var passive = item.get("passive", {})
	for key in passive:
		if key.ends_with("_resistance") and key != "perk":
			var element = key.replace("_resistance", "")
			bonuses["resistances"][element] = bonuses["resistances"].get(element, 0) + passive[key]


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


## Return ammo type definition dict, or {} if not found.
func get_ammo(ammo_id: String) -> Dictionary:
	return ammo_types.get(ammo_id, {})


## Return all ammo available for a given weapon type.
## First entry is always the default (bone arrow/bolt), which is free and infinite.
## Subsequent entries are finite ammo from the party inventory matching this weapon_type.
func get_available_ammo(weapon_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	# Find and add the default (free/infinite) ammo for this weapon type first
	for ammo_id in ammo_types:
		var ammo = ammo_types[ammo_id]
		if ammo.get("is_default", false) and weapon_type in ammo.get("weapon_types", []):
			var entry = ammo.duplicate()
			entry["id"] = ammo_id
			result.append(entry)
			break  # Only one default per weapon type

	# Add finite ammo from party inventory that matches this weapon type
	for inv_entry in _inventory:
		var ammo_id: String = inv_entry.get("item_id", "")
		if not ammo_types.has(ammo_id):
			continue
		var ammo = ammo_types[ammo_id]
		if ammo.get("is_default", false):
			continue  # Default already added above
		if weapon_type in ammo.get("weapon_types", []):
			var entry = ammo.duplicate()
			entry["id"] = ammo_id
			entry["quantity"] = inv_entry.get("quantity", 0)
			result.append(entry)

	return result


## Consume 1 unit of ammo from the party inventory.
## Returns true if ammo remains after consumption, false if fully depleted.
## Does nothing (returns true) for default (free/infinite) ammo.
func consume_ammo(ammo_id: String) -> bool:
	var ammo_def = ammo_types.get(ammo_id, {})
	if ammo_def.get("is_default", false):
		return true  # Free ammo is never depleted
	remove_from_inventory(ammo_id, 1)
	return get_inventory_count(ammo_id) > 0


## Merge duplicate consumable entries in inventory (fixes pre-stacking data)
func consolidate_inventory() -> void:
	var seen: Dictionary = {}  # item_id → index in new array
	var consolidated: Array[Dictionary] = []

	for entry in _inventory:
		var item_id = entry.get("item_id", "")
		var item = get_item(item_id)
		var item_type = item.get("type", "")
		var type_info = _item_types.get(item_type, {})
		var is_stackable = type_info.get("category", "") == "consumable"

		if is_stackable and item_id in seen:
			# Merge into existing stack
			consolidated[seen[item_id]]["quantity"] += entry.get("quantity", 1)
		else:
			if is_stackable:
				seen[item_id] = consolidated.size()
			consolidated.append(entry)

	if consolidated.size() != _inventory.size():
		_inventory = consolidated
		inventory_changed.emit()


## Add starter items to inventory and equip them, using background-specific loadouts.
## Falls back to a generic loadout if no background data is found.
func add_starter_items(background: String = "") -> void:
	var items_to_add: Array = []
	var secondary_weapon: String = ""

	# Try background-specific equipment from races.json
	var bg_equipment: Dictionary = {}
	if background != "":
		var bg_data = CharacterSystem.get_background_data(background)
		bg_equipment = bg_data.get("starting_equipment", {})

	if not bg_equipment.is_empty():
		for item_id in bg_equipment.get("items", []):
			items_to_add.append(str(item_id))
		secondary_weapon = str(bg_equipment.get("secondary_weapon", ""))
		# Weapon quality roll: 20% chance to get the iron upgrade, otherwise bronze base
		var base_weapon: String = str(bg_equipment.get("base_weapon", ""))
		var weapon_upgrade: String = str(bg_equipment.get("weapon_upgrade", ""))
		var upgrade_chance: float = float(bg_equipment.get("weapon_upgrade_chance", 0.2))
		if base_weapon != "":
			if weapon_upgrade != "" and randf() < upgrade_chance:
				items_to_add.append(weapon_upgrade)
			else:
				items_to_add.append(base_weapon)
		# Random bonus item (accessories, etc.)
		var bonus_pool: Array = bg_equipment.get("random_bonus", [])
		var bonus_chance: float = float(bg_equipment.get("bonus_chance", 0.0))
		if bonus_pool.size() > 0 and randf() < bonus_chance:
			items_to_add.append(str(bonus_pool[randi() % bonus_pool.size()]))
	else:
		# Generic fallback loadout
		items_to_add = ["bone_dagger", "leather_vest", "leather_cap", "leather_boots", "copper_ring", "travelers_amulet"]
		secondary_weapon = "short_bow"

	# Add everything to inventory
	for item_id in items_to_add:
		if item_id != "":
			add_to_inventory(item_id)
	if secondary_weapon != "":
		add_to_inventory(secondary_weapon)
	# Starting consumables — same for everyone
	add_to_inventory("health_potion", 2)
	add_to_inventory("mana_potion", 1)

	# Auto-equip on the player character
	var player = CharacterSystem.get_player()
	if not player.is_empty():
		_auto_equip_starter_items(player, items_to_add, secondary_weapon)

	print("ItemSystem: Added starter items for background '%s'" % background)


## Auto-equip a list of starter items based on item type.
## Melee weapons → weapon set 1; bows → weapon set 2; armor/accessories → their slots.
func _auto_equip_starter_items(player: Dictionary, items: Array, secondary_weapon: String) -> void:
	# Item type → equipment slot mapping
	const SLOT_MAP: Dictionary = {
		"armor": "chest", "robe": "chest",
		"helmet": "head", "hat": "head",
		"boots": "feet",
		"gloves": "hand_l", "gauntlets": "hand_l",
		"pants": "legs", "greaves": "legs",
		"ring": "ring1",
		"amulet": "trinket1", "trinket": "trinket1", "necklace": "trinket1",
		"shield": "weapon_off"
	}
	const MELEE_TYPES: Array = ["sword", "axe", "dagger", "mace", "spear", "staff", "unarmed"]
	const RANGED_TYPES: Array = ["bow", "thrown"]

	player["active_weapon_set"] = 1
	for item_id in items:
		if item_id == "":
			continue
		var item_data = get_item(item_id)
		if item_data.is_empty():
			continue
		var itype: String = item_data.get("type", "")
		if itype in MELEE_TYPES:
			equip_item(player, item_id, "weapon_main")
		elif itype in RANGED_TYPES:
			player["active_weapon_set"] = 2
			equip_item(player, item_id, "weapon_main")
			player["active_weapon_set"] = 1
		elif itype in SLOT_MAP:
			equip_item(player, item_id, SLOT_MAP[itype])

	# Secondary weapon (bow/ranged) goes to set 2
	if secondary_weapon != "":
		player["active_weapon_set"] = 2
		equip_item(player, secondary_weapon, "weapon_main")
		player["active_weapon_set"] = 1


# ============================================
# RUNTIME ITEM GENERATION
# ============================================

## Register a procedurally generated item and return its unique ID
## item_data should follow the same schema as static items in items.json
func register_runtime_item(item_data: Dictionary) -> String:
	var gen_id = "gen_%04d" % _next_runtime_id
	_next_runtime_id += 1
	_runtime_items[gen_id] = item_data.duplicate(true)
	return gen_id


## Remove a runtime item (e.g. when sold or destroyed)
func remove_runtime_item(item_id: String) -> void:
	_runtime_items.erase(item_id)


## Check if an item is runtime-generated
func is_runtime_item(item_id: String) -> bool:
	return item_id.begins_with("gen_")


## Clear all runtime items (for new game)
func clear_runtime_items() -> void:
	_runtime_items.clear()
	_next_runtime_id = 1


# ============================================
# TALISMAN GENERATION
# ============================================

# Talisman generation tables (loaded from JSON)
var _talisman_tables: Dictionary = {}

## Load talisman generation tables
func _load_talisman_tables() -> void:
	var file_path = "res://resources/data/talisman_tables.json"
	if not FileAccess.file_exists(file_path):
		push_warning("ItemSystem: talisman_tables.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_talisman_tables = json.get_data()
	file.close()


## Generate a random talisman and register it. Returns the gen_XXXX item ID.
## rarity: "common", "uncommon", "rare", "epic", "legendary"
func generate_talisman(rarity: String = "common") -> String:
	if _talisman_tables.is_empty():
		_load_talisman_tables()
	if _talisman_tables.is_empty():
		push_error("ItemSystem: Cannot generate talisman - no tables loaded")
		return ""

	var budgets = _talisman_tables.get("rarity_budgets", {})
	var budget_info = budgets.get(rarity, budgets.get("common", {}))
	var total_budget: float = budget_info.get("points", 3)
	var max_effects: int = budget_info.get("max_effects", 1)
	var perk_chance: float = budget_info.get("perk_chance", 0.0)

	var effect_pools = _talisman_tables.get("effect_pools", {})
	var perks_list = _talisman_tables.get("perks", [])
	var name_parts = _talisman_tables.get("name_parts", {})
	var element_map = _talisman_tables.get("element_by_stat", {})
	var value_per_point: float = _talisman_tables.get("value_per_budget_point", 12)

	var stats: Dictionary = {}
	var skill_bonuses: Dictionary = {}
	var passive: Dictionary = {}
	var chosen_perk: Dictionary = {}
	var remaining_budget: float = total_budget
	var primary_stat: String = ""

	# Maybe roll a perk first (costs budget)
	if randf() < perk_chance and not perks_list.is_empty():
		var affordable_perks: Array = []
		for p in perks_list:
			if p.get("cost", 99) <= remaining_budget:
				affordable_perks.append(p)
		if not affordable_perks.is_empty():
			chosen_perk = affordable_perks[randi() % affordable_perks.size()]
			remaining_budget -= chosen_perk.get("cost", 0)
			passive["perk"] = chosen_perk.get("id", "")

	# Build weighted pool list for stat selection
	var pool_entries: Array = []
	var pool_weight_total: float = 0.0
	for pool_name in effect_pools:
		var pool = effect_pools[pool_name]
		var w: float = pool.get("weight", 1)
		pool_entries.append({"name": pool_name, "pool": pool, "weight": w})
		pool_weight_total += w

	# Roll stat effects
	var effects_added: int = 0
	var used_stats: Array = []  # Prevent duplicates

	while effects_added < max_effects and remaining_budget >= 1.0:
		# Weighted random pool selection
		var roll: float = randf() * pool_weight_total
		var selected_pool: Dictionary = pool_entries[0]
		var cumulative: float = 0.0
		for entry in pool_entries:
			cumulative += entry.weight
			if roll <= cumulative:
				selected_pool = entry
				break

		var options = selected_pool.pool.get("options", [])
		if options.is_empty():
			break

		# Filter to affordable and unused options
		var valid_options: Array = []
		for opt in options:
			var opt_cost_per = opt.get("cost_per_point", 1.0)
			var opt_min_val = opt.get("min", 1)
			if opt.get("stat", "") not in used_stats and opt_cost_per * opt_min_val <= remaining_budget:
				valid_options.append(opt)

		if valid_options.is_empty():
			# Try another pool next iteration
			effects_added += 1
			continue

		var chosen = valid_options[randi() % valid_options.size()]
		var stat_name: String = chosen.get("stat", "")
		var cost_per: float = chosen.get("cost_per_point", 1.0)
		var min_val: int = chosen.get("min", 1)
		var max_val: int = chosen.get("max", 5)

		# Calculate how many points we can afford
		var max_affordable: int = int(remaining_budget / cost_per)
		var actual_max: int = mini(max_val, max_affordable)
		if actual_max < min_val:
			effects_added += 1
			continue

		var value: int = min_val + (randi() % (actual_max - min_val + 1))
		remaining_budget -= value * cost_per
		used_stats.append(stat_name)

		# Store the stat in the right place
		if selected_pool.name == "skill":
			skill_bonuses[stat_name] = value
		elif selected_pool.name == "resistance":
			passive[stat_name] = value
		else:
			stats[stat_name] = value

		# Track primary stat for naming
		if primary_stat == "":
			primary_stat = stat_name

		effects_added += 1

	# Generate name
	var prefixes = name_parts.get("prefixes", ["Inscribed"])
	var bases = name_parts.get("bases", ["Talisman"])
	var suffixes = name_parts.get("suffixes", {})

	var talisman_name: String = prefixes[randi() % prefixes.size()] + " " + bases[randi() % bases.size()]
	if primary_stat in suffixes:
		talisman_name += " " + suffixes[primary_stat]
	elif not chosen_perk.is_empty():
		talisman_name += " of " + chosen_perk.get("name", "Power")

	# Determine element from primary stat
	var element: String = element_map.get(primary_stat, "space")

	# Calculate gold value
	var gold_value: int = int(total_budget * value_per_point)

	# Build item data
	var item_data: Dictionary = {
		"name": talisman_name,
		"type": "talisman",
		"slot": "trinket1",
		"two_handed": false,
		"rarity": rarity,
		"element": element,
		"weight": 0,
		"value": gold_value,
		"description": _generate_talisman_description(stats, skill_bonuses, passive, chosen_perk),
		"requirements": {},
		"stats": stats,
		"abilities": []
	}

	# Add skill bonuses if any
	if not skill_bonuses.is_empty():
		item_data["skill_bonuses"] = skill_bonuses

	# Add passive effects if any (resistances, perks)
	if not passive.is_empty():
		item_data["passive"] = passive

	# Register and return
	return register_runtime_item(item_data)


## Build a readable description for a generated talisman
func _generate_talisman_description(stats: Dictionary, skill_bonuses: Dictionary,
		passive: Dictionary, perk: Dictionary) -> String:
	var parts: Array[String] = ["A written talisman inscribed with sacred mantras."]

	for stat in stats:
		var val = stats[stat]
		var label = stat.replace("_", " ").capitalize()
		parts.append("+%d %s" % [val, label])

	for skill in skill_bonuses:
		var val = skill_bonuses[skill]
		var label = skill.replace("_", " ").capitalize()
		parts.append("+%d %s skill" % [val, label])

	for key in passive:
		if key == "perk":
			continue
		var val = passive[key]
		var label = key.replace("_", " ").capitalize()
		parts.append("+%d%% %s" % [val, label])

	if not perk.is_empty():
		parts.append(perk.get("description", ""))

	return " ".join(parts)


# ============================================
# EQUIPMENT GENERATION
# ============================================

# Equipment generation tables (loaded from JSON)
var _equipment_tables: Dictionary = {}

## Load equipment generation tables
func _load_equipment_tables() -> void:
	var file_path = "res://resources/data/equipment_tables.json"
	if not FileAccess.file_exists(file_path):
		push_warning("ItemSystem: equipment_tables.json not found")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_equipment_tables = json.get_data()
	file.close()


## Load ammo type definitions from ammo.json
func _load_ammo() -> void:
	var file = FileAccess.open("res://resources/data/ammo.json", FileAccess.READ)
	if not file:
		push_error("ItemSystem: Could not load ammo.json")
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("ItemSystem: Failed to parse ammo.json: " + json.get_error_message())
		file.close()
		return
	file.close()
	ammo_types = json.get_data().get("ammo", {})
	print("ItemSystem: Loaded %d ammo types" % ammo_types.size())


## Pick a weighted random key from a {key: weight} dictionary
func _weighted_pick(weights: Dictionary) -> String:
	var total: float = 0.0
	for k in weights:
		total += float(weights[k])
	var roll: float = randf() * total
	var cumulative: float = 0.0
	var last_key: String = ""
	for k in weights:
		cumulative += float(weights[k])
		last_key = k
		if roll <= cumulative:
			return k
	return last_key


## Generate a procedural weapon. Returns the gen_XXXX item ID.
## weapon_type: "sword", "dagger", "axe", etc. (or "" for random)
## rarity: controls quality/material weighting
## material_override: force a specific material (or "" for random)
## quality_override: force a specific quality (or "" for random)
func generate_weapon(weapon_type: String = "", rarity: String = "common",
		material_override: String = "", quality_override: String = "",
		realm: String = "") -> String:
	if _equipment_tables.is_empty():
		_load_equipment_tables()
	if _equipment_tables.is_empty():
		push_error("ItemSystem: Cannot generate weapon - no tables loaded")
		return ""

	var weapon_bases = _equipment_tables.get("weapon_bases", {})
	var materials = _equipment_tables.get("materials", {})
	var quality_levels = _equipment_tables.get("quality_levels", {})
	var weapon_traits = _equipment_tables.get("weapon_traits", {})
	var rarity_quality = _equipment_tables.get("rarity_to_quality_weights", {})
	var tier_materials = _equipment_tables.get("tier_to_material_weights", {})

	# Pick weapon type if not specified
	if weapon_type == "" or not weapon_type in weapon_bases:
		var types = weapon_bases.keys()
		weapon_type = types[randi() % types.size()]

	var base = weapon_bases[weapon_type]

	# Pick quality
	var quality: String = quality_override
	if quality == "" or not quality in quality_levels:
		var q_weights = rarity_quality.get(rarity, {"common": 100})
		quality = _weighted_pick(q_weights)
	var q_info = quality_levels[quality]

	# Pick material — realm sets the bell curve; rarity is fallback only when no realm given
	var material: String = material_override
	var m_weights: Dictionary = {}
	if material == "" or not material in materials:
		var realm_weights = _equipment_tables.get("realm_material_weights", {})
		if realm != "" and realm in realm_weights:
			m_weights = realm_weights[realm]
		else:
			var rarity_tiers = {"common": "3", "uncommon": "4", "rare": "5", "epic": "6", "legendary": "7"}
			var tier_key = rarity_tiers.get(rarity, "4")
			m_weights = tier_materials.get(tier_key, {"iron": 100})
		material = _weighted_pick(m_weights)

	# Material type restriction (e.g. wood only allowed for staff/club)
	if material != "" and material in materials:
		var allowed = materials[material].get("allowed_types", [])
		if allowed.size() > 0 and not weapon_type in allowed:
			var filtered: Dictionary = {}
			for mat_key in m_weights:
				var mat_allowed = materials.get(mat_key, {}).get("allowed_types", [])
				if mat_allowed.is_empty() or weapon_type in mat_allowed:
					filtered[mat_key] = m_weights[mat_key]
			material = _weighted_pick(filtered) if not filtered.is_empty() else "iron"

	var mat_info = materials[material]

	# Calculate stats
	var stat_mult: float = q_info.get("stat_mult", 1.0)
	var final_stats: Dictionary = {}

	var base_damage = base.get("damage", 5)
	final_stats["damage"] = int(base_damage * mat_info.get("damage_mult", 1.0) * stat_mult)

	var base_accuracy = base.get("accuracy", 0)
	if base_accuracy != 0:
		final_stats["accuracy"] = int(base_accuracy * stat_mult)

	# Copy special stats from base (spellpower, range, crit_chance, armor_pierce)
	for special in ["spellpower", "range", "crit_chance", "armor_pierce"]:
		if special in base:
			final_stats[special] = int(base[special] * stat_mult)

	# Apply material-specific stat bonuses (e.g. obsidian crit_chance +3)
	for bonus_key in mat_info.get("stat_bonuses", {}):
		var bonus_val = mat_info["stat_bonuses"][bonus_key]
		if bonus_key in final_stats:
			final_stats[bonus_key] += bonus_val
		else:
			final_stats[bonus_key] = bonus_val

	# Weight and value
	var final_weight: int = maxi(1, int(base.get("weight", 5) * mat_info.get("weight_mult", 1.0)))
	var final_value: int = int(base.get("value", 50) * mat_info.get("value_mult", 1.0) * q_info.get("value_mult", 1.0))

	# Apply traits
	var trait_slots: int = q_info.get("trait_slots", 0)
	var applied_traits: Array[String] = []
	var passive: Dictionary = {}

	if trait_slots > 0:
		# Find valid traits for this weapon type
		var valid_traits: Array = []
		for trait_name in weapon_traits:
			var trait_info = weapon_traits[trait_name]
			if not trait_info is Dictionary:  # Skip _comment strings
				continue
			if weapon_type in trait_info.get("types", []):
				valid_traits.append({"name": trait_name, "info": trait_info})

		# Pick traits
		valid_traits.shuffle()
		for i in range(mini(trait_slots, valid_traits.size())):
			var trait_entry = valid_traits[i]
			var trait_info = trait_entry.info
			applied_traits.append(trait_entry.name)

			# Apply trait stat bonuses
			for key in trait_info:
				if key in ["budget_cost", "types"]:
					continue
				# Elemental damage traits (e.g. space_damage_pct: 15)
				if key.ends_with("_damage_pct"):
					var element = key.left(key.length() - 11)  # strip "_damage_pct"
					if not "elemental_damage" in passive:
						passive["elemental_damage"] = {}
					var base_dmg = base.get("damage", 5)
					passive["elemental_damage"][element] = maxi(1, int(base_dmg * trait_info[key] / 100.0))
				# On-hit proc passives stored raw
				elif key in ["poison_chance", "bleed_chance", "stun_chance", "burn_chance",
						"freeze_chance", "silence_chance", "dispel_chance", "lifesteal", "manasteal"]:
					passive[key] = trait_info[key]
				elif key in final_stats:
					final_stats[key] += trait_info[key]
				else:
					final_stats[key] = trait_info[key]

			final_value += int(trait_info.get("budget_cost", 0) * 15)

	# Convert _pct trait keys to actual stat adjustments
	for key in final_stats.keys():
		if not key.ends_with("_pct"):
			continue
		var base_key = key.left(key.length() - 4)  # strip "_pct"
		if base_key == "loot_value":
			final_value = int(final_value * (1.0 + final_stats[key] / 100.0))
		elif base_key == "initiative":
			# initiative has no weapon base stat; treat the pct value as a flat bonus directly
			# (initiative_pct: 10 → +10 initiative, matching trait budget intent)
			var init_bonus = final_stats.get("initiative", 0) + int(final_stats[key])
			if init_bonus != 0:
				final_stats["initiative"] = init_bonus
		else:
			var current = final_stats.get(base_key, 0)
			if current != 0:
				final_stats[base_key] = current + int(current * final_stats[key] / 100.0)
		final_stats.erase(key)

	# Build name
	var name_parts: Array[String] = []
	var q_prefix = q_info.get("name_prefix", "")
	if q_prefix != "":
		name_parts.append(q_prefix)
	name_parts.append(mat_info.get("name_prefix", "Iron"))
	name_parts.append(weapon_type.capitalize())

	# Trait suffix
	if not applied_traits.is_empty():
		# Use first trait as descriptor
		var trait_display = applied_traits[0].capitalize()
		# Prepend trait before weapon type for natural phrasing
		name_parts.insert(name_parts.size() - 1, trait_display)

	var item_name = " ".join(name_parts)

	# Build description
	var desc_parts: Array[String] = []
	if q_prefix != "":
		desc_parts.append("A %s %s %s." % [q_prefix.to_lower(), mat_info.get("name_prefix", "").to_lower(), weapon_type])
	else:
		desc_parts.append("A %s %s." % [mat_info.get("name_prefix", "").to_lower(), weapon_type])
	if not applied_traits.is_empty():
		var trait_names: Array[String] = []
		for t in applied_traits:
			trait_names.append(t.capitalize())
		desc_parts.append("Traits: %s." % ", ".join(trait_names))

	# Requirements — scale with material tier
	var requirements: Dictionary = {}
	var tier: int = mat_info.get("tier", 2)
	if weapon_type in ["axe", "mace", "sword"]:
		requirements["strength"] = 8 + tier * 2
	elif weapon_type in ["bow", "dagger", "spear"]:
		requirements["finesse"] = 8 + tier * 2
	elif weapon_type == "staff":
		requirements["focus"] = 8 + tier * 2

	# Durability — base value from material, reduced by quality (poor = worse condition)
	var base_dur: int = mat_info.get("base_durability", 85)
	var dur_mult: float = q_info.get("stat_mult", 1.0)
	var max_dur: int = maxi(5, int(base_dur * dur_mult))

	# Build item data
	var item_data: Dictionary = {
		"name": item_name,
		"type": weapon_type,
		"slot": "weapon_main",
		"two_handed": base.get("two_handed", false),
		"rarity": rarity,
		"element": base.get("element", "earth"),
		"weight": final_weight,
		"value": final_value,
		"description": " ".join(desc_parts),
		"requirements": requirements,
		"stats": final_stats,
		"abilities": [],
		"durability": max_dur,
		"max_durability": max_dur,
		"generated": {
			"material": material,
			"quality": quality,
			"traits": applied_traits,
			"fragility": mat_info.get("fragility", 1.0)
		}
	}

	if not passive.is_empty():
		item_data["passive"] = passive

	return register_runtime_item(item_data)


## Generate a procedural armor piece. Returns the gen_XXXX item ID.
## armor_type: "armor", "helmet", "boots", etc. (or "" for random)
func generate_armor(armor_type: String = "", rarity: String = "common",
		material_override: String = "", quality_override: String = "",
		realm: String = "") -> String:
	if _equipment_tables.is_empty():
		_load_equipment_tables()
	if _equipment_tables.is_empty():
		push_error("ItemSystem: Cannot generate armor - no tables loaded")
		return ""

	var armor_bases = _equipment_tables.get("armor_bases", {})
	var materials = _equipment_tables.get("materials", {})
	var quality_levels = _equipment_tables.get("quality_levels", {})
	var armor_traits = _equipment_tables.get("armor_traits", {})
	var rarity_quality = _equipment_tables.get("rarity_to_quality_weights", {})
	var tier_materials = _equipment_tables.get("tier_to_material_weights", {})

	# Pick armor type if not specified
	if armor_type == "" or not armor_type in armor_bases:
		var types = armor_bases.keys()
		armor_type = types[randi() % types.size()]

	var base = armor_bases[armor_type]

	# Pick quality
	var quality: String = quality_override
	if quality == "" or not quality in quality_levels:
		var q_weights = rarity_quality.get(rarity, {"common": 100})
		quality = _weighted_pick(q_weights)
	var q_info = quality_levels[quality]

	# Pick material — realm sets the bell curve; rarity is fallback only when no realm given
	var material: String = material_override
	var m_weights: Dictionary = {}
	if material == "" or not material in materials:
		var realm_weights = _equipment_tables.get("realm_material_weights", {})
		if realm != "" and realm in realm_weights:
			m_weights = realm_weights[realm]
		else:
			var rarity_tiers = {"common": "3", "uncommon": "4", "rare": "5", "epic": "6", "legendary": "7"}
			var tier_key = rarity_tiers.get(rarity, "4")
			m_weights = tier_materials.get(tier_key, {"iron": 100})
		material = _weighted_pick(m_weights)
	var mat_info = materials[material]

	# Calculate stats
	var stat_mult: float = q_info.get("stat_mult", 1.0)
	var final_stats: Dictionary = {}

	var base_armor = base.get("armor", 2)
	if base_armor > 0:
		final_stats["armor"] = int(base_armor * mat_info.get("armor_mult", 1.0) * stat_mult)

	var base_dodge = base.get("dodge", 0)
	if base_dodge != 0:
		final_stats["dodge"] = int(base_dodge * stat_mult)

	# Copy special stats
	for special in ["max_mana", "max_hp", "damage", "movement", "spellpower"]:
		if special in base:
			final_stats[special] = int(base[special] * stat_mult)

	var final_weight: int = maxi(1, int(base.get("weight", 5) * mat_info.get("weight_mult", 1.0)))
	var final_value: int = int(base.get("value", 50) * mat_info.get("value_mult", 1.0) * q_info.get("value_mult", 1.0))

	# Determine slot
	var slot: String = base.get("slot", "chest")

	# Apply traits
	var trait_slots: int = q_info.get("trait_slots", 0)
	var applied_traits: Array[String] = []
	var passive: Dictionary = {}

	if trait_slots > 0:
		var valid_traits: Array = []
		for trait_name in armor_traits:
			var trait_info = armor_traits[trait_name]
			if not trait_info is Dictionary:  # Skip _comment strings
				continue
			if armor_type in trait_info.get("types", []):
				valid_traits.append({"name": trait_name, "info": trait_info})

		valid_traits.shuffle()
		for i in range(mini(trait_slots, valid_traits.size())):
			var trait_entry = valid_traits[i]
			var trait_info = trait_entry.info
			applied_traits.append(trait_entry.name)

			for key in trait_info:
				if key in ["budget_cost", "types"]:
					continue
				if key.ends_with("_resistance"):
					passive[key] = trait_info[key]
				elif key in final_stats:
					final_stats[key] += trait_info[key]
				else:
					final_stats[key] = trait_info[key]

			final_value += int(trait_info.get("budget_cost", 0) * 15)

	# Build name
	var name_parts_arr: Array[String] = []
	var q_prefix = q_info.get("name_prefix", "")
	if q_prefix != "":
		name_parts_arr.append(q_prefix)

	if not applied_traits.is_empty():
		name_parts_arr.append(applied_traits[0].capitalize())

	name_parts_arr.append(mat_info.get("name_prefix", "Iron"))
	name_parts_arr.append(armor_type.capitalize())
	var item_name = " ".join(name_parts_arr)

	# Build description — boots/gloves/gauntlets/greaves are plural, use "Some"
	const PLURAL_ARMOR_TYPES: Array[String] = ["boots", "gloves", "gauntlets", "greaves"]
	var article: String = "Some" if armor_type in PLURAL_ARMOR_TYPES else "A"
	var desc_parts: Array[String] = []
	if q_prefix != "":
		desc_parts.append("%s %s %s %s." % [article, q_prefix.to_lower(), mat_info.get("name_prefix", "").to_lower(), armor_type])
	else:
		desc_parts.append("%s %s %s." % [article, mat_info.get("name_prefix", "").to_lower(), armor_type])
	if not applied_traits.is_empty():
		var trait_names: Array[String] = []
		for t in applied_traits:
			trait_names.append(t.capitalize())
		desc_parts.append("Traits: %s." % ", ".join(trait_names))

	# Requirements
	var requirements: Dictionary = {}
	var tier: int = mat_info.get("tier", 2)
	# Heavy armor needs strength
	if armor_type in ["armor", "gauntlets", "greaves", "helmet", "shield"]:
		if base_armor >= 3:
			requirements["strength"] = 8 + tier * 2

	var item_data: Dictionary = {
		"name": item_name,
		"type": armor_type,
		"slot": slot,
		"two_handed": false,
		"rarity": rarity,
		"element": "earth",
		"weight": final_weight,
		"value": final_value,
		"description": " ".join(desc_parts),
		"requirements": requirements,
		"stats": final_stats,
		"abilities": [],
		"generated": {
			"material": material,
			"quality": quality,
			"traits": applied_traits
		}
	}

	if not passive.is_empty():
		item_data["passive"] = passive

	return register_runtime_item(item_data)


## Generate equipment matching a party member's best weapon skill.
## Inspects the party and picks a weapon type that someone can use.
func generate_weapon_for_party(rarity: String = "common",
		material_override: String = "", quality_override: String = "",
		realm: String = "") -> String:
	var party = CharacterSystem.get_party() if CharacterSystem else []
	var best_type: String = ""
	var best_level: int = 0

	# Map weapon types to their skill names
	var type_to_skill = {
		"sword": "swords", "dagger": "daggers", "axe": "axes",
		"mace": "maces", "club": "maces", "spear": "spears", "staff": "martial_arts",
		"bow": "ranged"
	}

	for member in party:
		var skills = member.get("skills", {})
		for wtype in type_to_skill:
			var skill_name = type_to_skill[wtype]
			var level = skills.get(skill_name, 0)
			if level > best_level:
				best_level = level
				best_type = wtype

	# Fallback: best_type stays "" → generate_weapon picks a random type
	return generate_weapon(best_type, rarity, material_override, quality_override, realm)


# ============================================
# PROCEDURAL GENERATION INTEGRATION
# ============================================

# Item types that can be procedurally generated as weapons
const WEAPON_TYPES: Array[String] = [
	"sword", "dagger", "axe", "mace", "spear", "staff", "bow", "crossbow", "javelin", "club"
]

# Item types that can be procedurally generated as armor
const ARMOR_TYPES: Array[String] = [
	"helmet", "hat", "armor", "robe", "gloves", "gauntlets", "pants",
	"greaves", "boots", "shield"
]

# Talisman types
const TALISMAN_TYPES: Array[String] = ["talisman", "trinket", "amulet", "ring", "charm"]

# Chance to generate procedural instead of picking static, by rarity
# Higher rarities are more likely to be procedural (fewer static items exist)
const PROCEDURAL_CHANCE_BY_RARITY: Dictionary = {
	"common": 0.15, "uncommon": 0.35, "rare": 0.60, "epic": 0.85, "legendary": 0.95
}


## Resolve a random_generate template item into a real procedural item.
## Returns the gen_XXXX ID of the generated item, or "" on failure.
func resolve_random_generate(item_id: String) -> String:
	var item = get_item(item_id)
	if item.is_empty():
		return ""

	var gen_config = item.get("random_generate", {})
	if gen_config.is_empty():
		return ""

	var category = gen_config.get("category", "")
	match category:
		"weapon":
			var quality = gen_config.get("quality", "")
			var material = gen_config.get("material", "")
			var rarity = gen_config.get("rarity", "common")
			if gen_config.get("match_party_skill", false):
				return generate_weapon_for_party(rarity, material, quality)
			else:
				var weapon_type = gen_config.get("type", "")
				return generate_weapon(weapon_type, rarity, material, quality)
		"armor":
			var quality = gen_config.get("quality", "")
			var material = gen_config.get("material", "")
			var rarity = gen_config.get("rarity", "common")
			var armor_type = gen_config.get("type", "")
			return generate_armor(armor_type, rarity, material, quality)
		"talisman":
			var rarity = gen_config.get("rarity", "common")
			return generate_talisman(rarity)

	return ""


## Generate a procedural item for a given item type and rarity.
## Used by loot drops and shops to create appropriate procedural items.
## Returns the gen_XXXX ID, or "" if the type can't be procedurally generated.
func generate_item_for_type(item_type: String, rarity: String = "common", realm: String = "") -> String:
	if item_type in WEAPON_TYPES:
		return generate_weapon(item_type, rarity, "", "", realm)
	elif item_type in ARMOR_TYPES:
		return generate_armor(item_type, rarity, "", "", realm)
	elif item_type in TALISMAN_TYPES:
		return generate_talisman(rarity)
	return ""


## Check if a given item type can be procedurally generated
func can_generate_type(item_type: String) -> bool:
	return item_type in WEAPON_TYPES or item_type in ARMOR_TYPES or item_type in TALISMAN_TYPES


## Check if a static item is a random_generate template
func is_template_item(item_id: String) -> bool:
	var item = _item_database.get(item_id, {})
	return item.has("random_generate")


# ============================================
# SAVE / LOAD
# ============================================

## Collect saveable state into a dictionary
func get_save_data() -> Dictionary:
	return {
		"inventory": _inventory.duplicate(true),
		"runtime_items": _runtime_items.duplicate(true),
		"next_runtime_id": _next_runtime_id
	}


## Restore state from a save dictionary
func load_save_data(data: Dictionary) -> void:
	_inventory.clear()
	var saved_inv = data.get("inventory", [])
	for entry in saved_inv:
		_inventory.append(entry)

	# Restore runtime-generated items
	_runtime_items = data.get("runtime_items", {}).duplicate(true)
	_next_runtime_id = data.get("next_runtime_id", 1)

	inventory_changed.emit()
