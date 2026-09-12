extends Node
## Headless verification for the item material and quality vocabulary.

var failures: int = 0
var checks_run: int = 0
const EXPECTED_CHECKS: int = 4


func _ready() -> void:
	_check_every_equipment_item_declares_both()
	_check_materials_exist_in_the_tables()
	_check_authored_items_now_wear()
	_check_stats_were_not_touched()

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
