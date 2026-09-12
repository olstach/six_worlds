extends Node
## Headless verification for the item material and quality vocabulary.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 8


func _ready() -> void:
	_check_every_equipment_item_declares_both()
	_check_materials_exist_in_the_tables()
	_check_authored_items_now_wear()
	_check_stats_were_not_touched()
	_check_every_type_has_a_base()
	_check_values_match_the_tiering()
	_check_ritual_metal_coding()
	_check_ritual_implement_coding()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway"
			% [checks_run, EXPECTED_CHECKS])
		failures += 1
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _fail(m: String) -> void:
	printerr("  FAIL: ", m)
	failures += 1


func _done() -> void:
	checks_run += 1


const CONSUMABLE_SLOTS: Array[String] = ["inventory", ""]


func _equipment_items() -> Array[String]:
	var out: Array[String] = []
	for item_id in ItemSystem.get_all_item_ids():
		var item: Dictionary = ItemSystem.get_item(item_id)
		if not str(item.get("slot", "")) in CONSUMABLE_SLOTS:
			out.append(item_id)
	return out


func _check_every_equipment_item_declares_both() -> void:
	var missing: Array[String] = []
	for item_id in _equipment_items():
		var item: Dictionary = ItemSystem.get_item(item_id)
		if not item.has("material") or not item.has("quality"):
			missing.append(item_id)
	if not missing.is_empty():
		_fail("%d equipment items lack material or quality, e.g. %s"
			% [missing.size(), missing.slice(0, 5)])
	_done()


## A material nothing defines is how composite_bow sat for however long: an
## authored choice the generator had never heard of and nothing checked.
func _check_materials_exist_in_the_tables() -> void:
	var known: Dictionary = ItemSystem.get_equipment_tables().get("materials", {})
	var bad: Array[String] = []
	for item_id in _equipment_items():
		var material: String = str(ItemSystem.get_item(item_id).get("material", ""))
		if material != "" and not known.has(material):
			bad.append("%s:%s" % [item_id, material])
	if not bad.is_empty():
		_fail("items name materials that do not exist: %s" % bad.slice(0, 5))
	_done()


## Anything with a durability bar must actually spend it — unless its material
## is meant to be eternal. Vajra has fragility 0.0 on purpose: the adamantine
## thunderbolt does not wear out, which is the whole idea of the thing.
func _check_authored_items_now_wear() -> void:
	var materials: Dictionary = ItemSystem.get_equipment_tables().get("materials", {})
	var stuck: Array[String] = []
	var wearing := 0
	for item_id in _equipment_items():
		var item: Dictionary = ItemSystem.get_item(item_id)
		if int(item.get("max_durability", 0)) <= 0:
			continue
		var eternal: bool = float(materials.get(
			str(item.get("material", "")), {}).get("fragility", 0.0)) == 0.0
		if ItemSystem.get_item_fragility(item) > 0.0:
			wearing += 1
		elif not eternal:
			stuck.append(item_id)
	if wearing == 0:
		_fail("nothing with a durability bar degrades at all")
	if not stuck.is_empty():
		_fail("%d items have a durability bar, a wearing material, and still never degrade: %s"
			% [stuck.size(), stuck.slice(0, 5)])
	_done()


## The whole point was to describe the items, not re-tune them. A known weapon's
## stats must be exactly what they were.
func _check_stats_were_not_touched() -> void:
	var sword: Dictionary = ItemSystem.get_item("iron_sword")
	if sword.is_empty():
		_fail("iron_sword is missing — pick another fixture")
		_done()
		return
	if sword.get("material", "") != "iron":
		_fail("iron_sword's material is %s" % sword.get("material", ""))
	if not sword.has("stats") or sword["stats"].is_empty():
		_fail("iron_sword lost its stats block")
	_done()


## Every equipment type must have a base entry, or its items cannot be tiered,
## generated or priced. Twelve types covering 328 of 486 items had none.
func _check_every_type_has_a_base() -> void:
	var missing: Dictionary = {}
	for item_id in _equipment_items():
		var item_type: String = str(ItemSystem.get_item(item_id).get("type", ""))
		if item_type != "" and ItemSystem.get_base_for_type(item_type).is_empty():
			missing[item_type] = true
	if not missing.is_empty():
		_fail("equipment types with no base entry: %s" % missing.keys())
	_done()


## The tags have to mean something: an item's value should follow from
## base x material x quality x enchantment.
##
## Before enchantment was added, plain items sat at a median 1.13x of expected
## while enchanted ones sat at 20x — the model had no term for what had been
## done to an item, only for what it was made of. With that term and the twelve
## missing bases, all 486 land inside half-to-double.
func _check_values_match_the_tiering() -> void:
	var tables: Dictionary = ItemSystem.get_equipment_tables()
	var materials: Dictionary = tables.get("materials", {})
	var qualities: Dictionary = tables.get("quality_levels", {})
	var enchantments: Dictionary = tables.get("enchantment_levels", {})
	var outliers: Array[String] = []
	var checked := 0

	for item_id in _equipment_items():
		var item: Dictionary = ItemSystem.get_item(item_id)
		var base: Dictionary = ItemSystem.get_base_for_type(str(item.get("type", "")))
		if base.is_empty():
			continue
		# A ritual implement's metal is a coding, not a cost: gold and copper
		# dorjes serve different elements and cost the same. Their value comes
		# from consecration alone, so the structural material multiplier — which
		# would price gold at 6x — does not apply.
		var ritual: Dictionary = tables.get("ritual_metals", {})
		var material_mult: float = float(materials.get(
			str(item.get("material", "")), {}).get("value_mult", 1.0))
		if str(item.get("type", "")) == "focus" \
				and ritual.has(str(item.get("material", ""))):
			material_mult = float(ritual[str(item.get("material", ""))].get("value_mult", 1.0))

		var expected: float = float(base.get("value", 50)) \
			* material_mult \
			* float(qualities.get(str(item.get("quality", "")), {}).get("value_mult", 1.0)) \
			* float(enchantments.get(str(item.get("enchantment", "none")), {}).get("value_mult", 1.0))
		if expected <= 0.0:
			continue
		checked += 1
		var ratio: float = float(item.get("value", 0)) / expected
		if ratio < 0.5 or ratio > 2.0:
			outliers.append("%s %.2fx" % [item_id, ratio])

	if checked < 400:
		_fail("only %d items were priced against the model — expected ~486" % checked)
	if not outliers.is_empty():
		_fail("%d items are priced outside half-to-double what their tags imply: %s"
			% [outliers.size(), outliers.slice(0, 6)])
	_done()


const RITUAL_METALS: Array[String] = ["sky_iron", "copper", "silver", "gold",
	"iron", "conch", "bronze"]
const RITUAL_IMPLEMENTS: Array[String] = ["khatvanga", "drilbu", "damaru",
	"phurba", "dorje"]


func _ritual_implements() -> Array[String]:
	var out: Array[String] = []
	for item_id in ItemSystem.get_all_item_ids():
		if str(ItemSystem.get_item(item_id).get("type", "")) != "focus":
			continue
		var has_metal := false
		var has_implement := false
		for metal in RITUAL_METALS:
			if metal in item_id:
				has_metal = true
		for implement in RITUAL_IMPLEMENTS:
			if implement in item_id:
				has_implement = true
		if has_metal and has_implement:
			out.append(item_id)
	return out


## The metal an implement is made of says which element it serves, and grants
## that element's school. This is doctrine, not decoration: a copper phurba is
## for fire work and a silver one for healing. It was correct in the skill
## bonuses and wrong in the `element` field, which followed the implement
## instead — so every metal read space/air/fire and nothing anywhere was water.
func _check_ritual_metal_coding() -> void:
	var table: Dictionary = ItemSystem.get_equipment_tables().get("ritual_metals", {})
	if table.is_empty():
		_fail("ritual_metals is not declared in equipment_tables.json")
		_done()
		return
	var wrong: Array[String] = []
	for item_id in _ritual_implements():
		var item: Dictionary = ItemSystem.get_item(item_id)
		for metal in RITUAL_METALS:
			if not metal in item_id:
				continue
			var coding: Dictionary = table.get(metal, {})
			if str(item.get("element", "")) != str(coding.get("element", "")):
				wrong.append("%s element=%s want=%s"
					% [item_id, item.get("element", ""), coding.get("element", "")])
			elif not item.get("skill_bonuses", {}).has(str(coding.get("grants", ""))):
				wrong.append("%s lacks %s" % [item_id, coding.get("grants", "")])
			break
	if not wrong.is_empty():
		_fail("%d implements are mis-coded for their metal: %s"
			% [wrong.size(), wrong.slice(0, 4)])
	_done()


## The implement says which practice it serves, and grants that skill or
## attribute. Only the phurba was right: the damaru granted the khatvanga's
## enchantment, and the dorje, drilbu and khatvanga granted nothing at all.
func _check_ritual_implement_coding() -> void:
	var table: Dictionary = ItemSystem.get_equipment_tables().get("ritual_implements", {})
	if table.is_empty():
		_fail("ritual_implements is not declared in equipment_tables.json")
		_done()
		return
	var wrong: Array[String] = []
	for item_id in _ritual_implements():
		var item: Dictionary = ItemSystem.get_item(item_id)
		for implement in RITUAL_IMPLEMENTS:
			if not implement in item_id:
				continue
			var coding: Dictionary = table.get(implement, {})
			var skill: String = str(coding.get("grants_skill", ""))
			var attribute: String = str(coding.get("grants_attribute", ""))
			if skill != "" and not item.get("skill_bonuses", {}).has(skill):
				wrong.append("%s lacks %s" % [item_id, skill])
			elif attribute != "" and int(item.get("stats", {}).get(attribute, 0)) <= 0:
				wrong.append("%s lacks %s" % [item_id, attribute])
			break
	if not wrong.is_empty():
		_fail("%d implements are mis-coded for their type: %s"
			% [wrong.size(), wrong.slice(0, 4)])
	_done()
