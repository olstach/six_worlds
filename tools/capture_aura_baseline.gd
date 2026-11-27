extends Node
## Captures what every aura and zone does to the numbers of the units it
## reaches, BEFORE auras and zones were migrated to effect lists (stage 2b,
## Task 8). Run once:
##
##     godot --headless --path . tools/capture_aura_baseline.tscn
##
## Writes tools/fixtures/aura_baseline.json, which is committed and then never
## rewritten. tools/aura_measure.gd says what is measured and where.
## verify_effects.gd `aura_numbers_match_baseline` compares the migrated data
## against it. Running this again after the migration would only copy the new
## behaviour over the old, so it refuses when the fixture already exists.

const AuraMeasure = preload("res://tools/aura_measure.gd")
const BASELINE_PATH: String = "res://tools/fixtures/aura_baseline.json"


func _ready() -> void:
	if FileAccess.file_exists(BASELINE_PATH):
		printerr("capture_aura_baseline: the fixture already exists; delete it first "
			+ "if you really mean to capture again (only ever before a migration)")
		get_tree().quit(1)
		return

	var grid := CombatGrid.new()
	add_child(grid)
	CombatManager.combat_grid = grid

	var measured: Dictionary = AuraMeasure.measure_all(self, grid)
	measured["_about"] = ("What each aura and zone changed BEFORE the stage-2b "
		+ "Task 8 migration, read on the units it reaches (see "
		+ "tools/aura_measure.gd). Keys are the change (with minus without); "
		+ "a key that did not move is left out. Written by "
		+ "tools/capture_aura_baseline.gd; read by verify_effects.gd "
		+ "aura_numbers_match_baseline.")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASELINE_PATH.get_base_dir()))
	var f := FileAccess.open(BASELINE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(measured, "\t", true) + "\n")
	f.close()
	print("captured %d auras, %d zones" % [measured.auras.size(), measured.zones.size()])
	get_tree().quit(0)
