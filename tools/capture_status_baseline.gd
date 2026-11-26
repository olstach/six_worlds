extends Node
## Captures what every status does to the numbers, BEFORE the statuses were
## migrated to the effect shape (stage 2b, Task 4). Run once:
##
##     godot --headless --path . tools/capture_status_baseline.tscn
##
## Writes two fixtures, which are committed and then never rewritten:
##   tools/fixtures/status_baseline.json  per status, the change it causes to
##       the eight stat getters and every resistance on a reference party unit
##       and a reference enemy (see tools/status_measure.gd for how)
##   tools/fixtures/status_tags.json      per StatusOps.TAGS selector, the
##       statuses it picks
##
## verify_effects.gd compares the migrated data against both. Running this
## again after the migration would only copy the new behaviour over the old
## one, so it refuses when the fixture already exists.

const StatusMeasure = preload("res://tools/status_measure.gd")
const BASELINE_PATH: String = "res://tools/fixtures/status_baseline.json"
const TAGS_PATH: String = "res://tools/fixtures/status_tags.json"


func _ready() -> void:
	if FileAccess.file_exists(BASELINE_PATH) or FileAccess.file_exists(TAGS_PATH):
		printerr("capture_status_baseline: a fixture already exists; delete it first "
			+ "if you really mean to capture again (only ever before a migration)")
		get_tree().quit(1)
		return

	var grid := CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	var defs: Dictionary = CombatManager.get_all_status_definitions()
	var names: Array[String] = []
	for name in defs:
		if not str(name).begins_with("_"):
			names.append(str(name))
	names.sort()

	var statuses: Dictionary = {}
	for name in names:
		var row: Dictionary = {}
		for kind in StatusMeasure.KINDS:
			row[kind] = StatusMeasure.measure_one(self, grid, name, kind)
		statuses[name] = row

	var baseline: Dictionary = {
		"_about": "What each status changed BEFORE the stage-2b migration, at "
			+ "duration 3, value 0, one application. Keys are the change "
			+ "(after minus before); a key that did not move is left out. "
			+ "Written by tools/capture_status_baseline.gd; read by "
			+ "verify_effects.gd status_numbers_match_baseline.",
		"reference": StatusMeasure.reference_numbers(self, grid),
		"statuses": statuses,
	}
	_write(BASELINE_PATH, baseline)
	_write(TAGS_PATH, {
		"_about": "Which statuses each StatusOps.TAGS selector picked BEFORE the "
			+ "stage-2b migration. Read by verify_effects.gd status_tags_select_same.",
		"tags": StatusMeasure.tag_selections(defs),
	})
	print("captured %d statuses" % names.size())
	get_tree().quit(0)


func _write(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t", true) + "\n")
	f.close()
