extends Node
## SaveManager - Handles save/load game persistence across sessions
##
## This singleton coordinates saving and loading across all game systems.
## Saves are stored as JSON files in user://saves/ with a meta.json index.
##
## Features:
## - 3 save slots with metadata for quick display
## - Autosave after combat, events, and reincarnation
## - Full map state preservation (procedural maps are non-deterministic)
## - Version field for future migration

# Current save format version — increment when save structure changes
const SAVE_VERSION: int = 1
const MAX_SLOTS: int = 3
const SAVE_DIR: String = "user://saves/"

# Which slot is currently active (-1 = no active save)
var current_slot: int = -1

# Play time tracking (seconds)
var _play_time: float = 0.0


func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("SaveManager initialized")


func _process(delta: float) -> void:
	# Only track play time when a save is active
	if current_slot >= 0:
		_play_time += delta


# ============================================
# SAVE GAME
# ============================================

## Save the current game state to a slot (1-3). Returns true on success.
func save_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: Invalid slot %d" % slot)
		return false

	# Collect data from all systems
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": _play_time,
		"game_state": GameState.get_save_data(),
		"characters": CharacterSystem.get_save_data(),
		"items": ItemSystem.get_save_data(),
		"karma": KarmaSystem.get_save_data(),
		"map": MapManager.get_save_data()
	}

	# Write save file
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open %s for writing" % file_path)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	# Update metadata
	_update_meta(slot, save_data)

	print("SaveManager: Game saved to slot %d" % slot)
	return true


## Autosave to the current slot (no-op if no slot is active)
func autosave() -> void:
	if current_slot < 1:
		return
	save_game(current_slot)


# ============================================
# LOAD GAME
# ============================================

## Load game state from a slot. Returns true on success.
func load_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: Invalid slot %d" % slot)
		return false

	var file_path = SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(file_path):
		push_error("SaveManager: No save in slot %d" % slot)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open %s" % file_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("SaveManager: Corrupt save in slot %d — %s" % [slot, json.get_error_message()])
		return false

	var save_data = json.get_data()
	if not save_data is Dictionary:
		push_error("SaveManager: Save data is not a Dictionary")
		return false

	# Check version (future: migration logic here)
	var version = save_data.get("version", 0)
	if version > SAVE_VERSION:
		push_error("SaveManager: Save version %d is newer than supported %d" % [version, SAVE_VERSION])
		return false

	# Restore play time
	_play_time = save_data.get("play_time", 0.0)

	# Distribute data to each system
	# Order matters: GameState first, then characters, items, karma, map last
	GameState.load_save_data(save_data.get("game_state", {}))
	CharacterSystem.load_save_data(save_data.get("characters", {}))
	ItemSystem.load_save_data(save_data.get("items", {}))
	KarmaSystem.load_save_data(save_data.get("karma", {}))
	MapManager.load_save_data(save_data.get("map", {}))

	current_slot = slot
	print("SaveManager: Game loaded from slot %d" % slot)
	return true


# ============================================
# NEW GAME
# ============================================

## Start a new game in the given slot. Resets all systems.
func start_new_game(slot: int) -> void:
	current_slot = slot
	_play_time = 0.0

	# Reset GameState
	GameState.current_world = "hell"
	GameState.unlocked_worlds = ["hell"]
	GameState.is_alive = true
	GameState.current_run_number = 1
	GameState.gold = 100
	GameState.food = 50
	GameState.herbs = 20
	GameState.scrap = 15
	GameState.reagents = 10
	GameState.steps_without_food = 0
	GameState.is_starving = false
	GameState.active_map_buffs = []
	GameState.used_event_choices = {}
	GameState.guild_spell_lists = {}
	GameState.flags = {}
	GameState.active_quests = []
	GameState.completed_quest_ids = []
	GameState.overworld_log = []
	GameState.is_party_wiped = false
	GameState.returning_from_combat = false
	GameState.last_defeated_mob_id = ""
	GameState.pending_combat_mob = {}
	GameState.pending_event_outcome = {}
	GameState.pending_event_object = {}
	GameState.combat_terrain_context = {}
	# Reset boss states
	for world_key in GameState.WORLDS:
		GameState.WORLDS[world_key].boss_defeated = false

	# Reset party and create player character
	CharacterSystem.party.clear()
	CharacterSystem.create_player_character("Karma Dorje", "human", "wanderer")

	# Reset inventory and give starter items
	ItemSystem.clear_inventory()
	var player = CharacterSystem.get_player()
	ItemSystem.add_starter_items(player.get("background", ""))

	# Reset karma
	for realm in KarmaSystem.karma_scores:
		KarmaSystem.karma_scores[realm] = 0

	# Reset map state so overworld loads fresh
	MapManager.current_map_id = ""
	MapManager.visited_tiles.clear()
	MapManager.collected_objects.clear()
	MapManager.defeated_mobs.clear()
	MapManager.searched_tiles.clear()
	MapManager.movement_abilities.clear()


# ============================================
# SLOT QUERIES
# ============================================

## Get summary info for a save slot (from meta.json). Returns empty dict if no save.
func get_slot_info(slot: int) -> Dictionary:
	var meta = _load_meta()
	var key = "slot_%d" % slot
	return meta.get(key, {})


## Check if a slot has a save file
func has_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "slot_%d.json" % slot
	return FileAccess.file_exists(file_path)


## Get the most recently saved slot (for Continue button). Returns -1 if none.
func get_most_recent_slot() -> int:
	var meta = _load_meta()
	var best_slot = -1
	var best_time: float = 0.0

	for i in range(1, MAX_SLOTS + 1):
		var key = "slot_%d" % i
		var info = meta.get(key, {})
		var ts = info.get("timestamp", 0.0)
		if ts > best_time:
			best_time = ts
			best_slot = i

	return best_slot


## Find the first empty slot (for New Game). Returns -1 if all full.
func find_empty_slot() -> int:
	for i in range(1, MAX_SLOTS + 1):
		if not has_save(i):
			return i
	return -1


## Delete a save file and its metadata entry
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false

	var file_path = SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

	# Remove from meta
	var meta = _load_meta()
	var key = "slot_%d" % slot
	if key in meta:
		meta.erase(key)
		_save_meta(meta)

	if current_slot == slot:
		current_slot = -1

	print("SaveManager: Deleted slot %d" % slot)
	return true


# ============================================
# METADATA (fast slot summaries)
# ============================================

## Update meta.json with a slot summary
func _update_meta(slot: int, save_data: Dictionary) -> void:
	var meta = _load_meta()
	var key = "slot_%d" % slot

	# Build summary from save data
	var game = save_data.get("game_state", {})
	var chars = save_data.get("characters", {})
	var party = chars.get("party", [])
	var player_name = ""
	var player_race = ""
	if not party.is_empty():
		player_name = party[0].get("name", "Unknown")
		player_race = party[0].get("race", "unknown")

	meta[key] = {
		"timestamp": save_data.get("timestamp", 0.0),
		"play_time": save_data.get("play_time", 0.0),
		"player_name": player_name,
		"player_race": player_race,
		"world": game.get("current_world", "hell"),
		"run_number": game.get("current_run_number", 1),
		"party_size": party.size(),
		"gold": game.get("gold", 0)
	}

	_save_meta(meta)


## Load meta.json
func _load_meta() -> Dictionary:
	var meta_path = SAVE_DIR + "meta.json"
	if not FileAccess.file_exists(meta_path):
		return {}

	var file = FileAccess.open(meta_path, FileAccess.READ)
	if file == null:
		return {}

	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	file.close()

	if result != OK:
		return {}

	var data = json.get_data()
	return data if data is Dictionary else {}


## Save meta.json
func _save_meta(meta: Dictionary) -> void:
	var meta_path = SAVE_DIR + "meta.json"
	var file = FileAccess.open(meta_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to write meta.json")
		return
	file.store_string(JSON.stringify(meta, "\t"))
	file.close()


## Format play time as "HH:MM" string for display
static func format_play_time(seconds: float) -> String:
	var total_minutes = int(seconds) / 60
	var hours = total_minutes / 60
	var minutes = total_minutes % 60
	return "%d:%02d" % [hours, minutes]


## Format a unix timestamp as a date string for display
static func format_timestamp(unix_time: float) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
