extends SceneTree
## Compiles every .gd file in the project and reports the ones that fail.
##
## Run headless:  godot --headless -s tools/parse_check.gd
##
## Why this exists: verify_all.sh's parse layer used to be
## `godot --headless --editor --quit`, on the theory that opening the editor
## compiles every script. It does not. The editor's filesystem scan only reads
## each file far enough to find its `class_name`, so a script nothing else
## loads — a tools/verify_*.gd, a UI scene's script that no autoload touches —
## can carry a parse error (a duplicate function, an undeclared name) through
## that layer untouched. One did on 2026-10-15; only running its scene caught it.
##
## This loads each script for real, which runs the full parser and analyzer.
## A broken script prints its own "SCRIPT ERROR: Parse Error" lines (the shell
## script greps for those) and comes back unable to instantiate, which is what
## this file counts.

## Folders never worth compiling: Godot's own cache, and add-on code we did not
## write. Anything else under res:// is ours.
const SKIP_DIRS: Array[String] = [".godot", ".git", "addons", ".claude"]


func _initialize() -> void:
	var scripts: Array[String] = []
	_collect("res://", scripts)

	var broken: Array[String] = []
	for path in scripts:
		# Not this file: reloading the script that is running replaces it
		# mid-function. It compiled, or none of this would be running.
		if path == get_script().resource_path:
			continue
		# CACHE_MODE_IGNORE: compile from disk now, not a copy something else
		# already loaded (autoloads are in the cache before this runs).
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null or not (script is Script) or not script.can_instantiate():
			broken.append(path)

	print("PARSE CHECK: %d scripts compiled, %d broken" % [scripts.size(), broken.size()])
	for path in broken:
		print("PARSE BROKEN: %s" % path)
	quit(1 if not broken.is_empty() else 0)


## Recursively gather every .gd path under `dir` into `out`.
func _collect(dir: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		var full := dir.path_join(name)
		if da.current_is_dir():
			if not name in SKIP_DIRS:
				_collect(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = da.get_next()
	da.list_dir_end()
