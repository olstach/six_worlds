# Quest & Journal Expansion Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the quest system with a quests.json pool, quest completion rewards, a two-panel Journal UI, a randomised quest board overlay at locations, and an overworld message log toggle.

**Architecture:** A new `quests.json` file holds the global quest pool (definitions + rewards). GameState gains `completed_quest_ids` and a session-only `overworld_log` array. `set_flag()` triggers completion checks and awards rewards. The Journal tab is rebuilt as a two-panel layout. The quest board is a new overlay scene mirroring the existing shop overlay pattern. EventManager gains a `quest_board_requested` signal. The overworld HUD gains a log toggle button and slide-in panel.

**Tech Stack:** GDScript / Godot 4.3. All new data in JSON. New UI built in code (no `.tscn` changes where avoidable). New quest board requires one new `.tscn` + `.gd` pair, following the existing `shop_ui` pattern.

---

## Chunk 1: quests.json + GameState Pool API

### Task 1: Create `quests.json` with three sample quests

**Files:**
- Create: `resources/data/quests.json`

- [ ] **Create the file with three sample quests**

```json
{
  "quests": {
    "cold_prisoner": {
      "id": "cold_prisoner",
      "name": "The Frozen Prisoner",
      "description": "A soul encased in ice begs for release. Somewhere in the cold hells lies the key.",
      "realm": "hell",
      "steps": [
        { "text": "Find the warden's seal",      "done_when": { "flag": "cold_warden_seal_found", "value": true } },
        { "text": "Return to the prisoner",       "done_when": { "flag": "cold_prisoner_freed",    "value": true } }
      ],
      "reward": { "xp": 250, "gold": 0, "karma": { "hell": -10, "human": 5 } }
    },
    "ember_debt": {
      "id": "ember_debt",
      "name": "Ember Debt",
      "description": "A fire merchant claims a debt owed by a roaming demon. Collect it—by any means.",
      "realm": "hell",
      "steps": [
        { "text": "Track down Blisterfang",       "done_when": { "flag": "blisterfang_found",    "value": true } },
        { "text": "Return the payment",           "done_when": { "flag": "ember_debt_paid",      "value": true } }
      ],
      "reward": { "xp": 200, "gold": 80, "karma": { "hell": 5 } }
    },
    "lost_mantra": {
      "id": "lost_mantra",
      "name": "The Lost Mantra",
      "description": "A wandering hermit lost a scroll of protective mantras. Without it, the cold will claim him.",
      "realm": "hell",
      "steps": [
        { "text": "Recover the mantra scroll",    "done_when": { "flag": "mantra_scroll_found",  "value": true } },
        { "text": "Bring it to the hermit",       "done_when": { "flag": "mantra_returned",      "value": true } }
      ],
      "reward": { "xp": 180, "karma": { "human": 8, "god": 3 } }
    }
  }
}
```

- [ ] **Commit**

```
git add resources/data/quests.json
git commit -m "feat: add quests.json with three sample quests"
```

---

### Task 2: Load quest pool into GameState + `completed_quest_ids`

**Files:**
- Modify: `scripts/autoload/game_state.gd`
- Modify: `scripts/autoload/save_manager.gd`

- [ ] **Add `completed_quest_ids` and `_quest_pool` to `game_state.gd`**

After the `var active_quests: Array[Dictionary] = []` line (~line 76), add:

```gdscript
# IDs of quests that have been fully completed and rewarded this run.
var completed_quest_ids: Array[String] = []

# In-memory quest definitions loaded from quests.json at startup.
# Format: { "quest_id": { id, name, description, realm, steps, reward } }
var _quest_pool: Dictionary = {}

# Session-only log of overworld messages (toasts, quest events, discoveries).
# Reset on scene load; NOT saved to disk.
var overworld_log: Array[String] = []
```

- [ ] **Load quests.json in `_ready()` of `game_state.gd`**

Find the `_ready()` function (around line 100). After existing data loads (e.g. `guild_spell_lists`), add:

```gdscript
	# Load quest pool from resources/data/quests.json
	var quest_file := FileAccess.open("res://resources/data/quests.json", FileAccess.READ)
	if quest_file:
		var parsed = JSON.parse_string(quest_file.get_as_text())
		if parsed is Dictionary:
			_quest_pool = parsed.get("quests", {})
		quest_file.close()
	else:
		push_error("GameState: could not open quests.json")
```

- [ ] **Add public API functions**

After `is_quest_step_done()` (~line 416), add:

```gdscript
## Returns all quest definitions from the pool for a given realm.
## Excludes quests already accepted (in active_quests) or completed.
func get_available_quests_for_realm(realm: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in _quest_pool:
		var quest: Dictionary = _quest_pool[quest_id]
		if quest.get("realm", "") != realm:
			continue
		if completed_quest_ids.has(quest_id):
			continue
		var already_active := false
		for aq in active_quests:
			if aq.get("id", "") == quest_id:
				already_active = true
				break
		if not already_active:
			result.append(quest)
	return result


## Accept a quest from the pool by id. Calls register_quest internally.
## Returns false if quest not found or already active/completed.
func accept_quest(quest_id: String) -> bool:
	if not _quest_pool.has(quest_id):
		push_error("GameState.accept_quest: unknown quest id '%s'" % quest_id)
		return false
	var quest: Dictionary = _quest_pool[quest_id]
	register_quest(quest)
	return true


## Mark a quest as complete, award rewards, and add an overworld log entry.
## Called automatically by check_quest_completion(); can also be called directly.
func complete_quest(quest_id: String) -> void:
	if completed_quest_ids.has(quest_id):
		return  # Already completed
	completed_quest_ids.append(quest_id)
	# Remove from active_quests
	for i in range(active_quests.size() - 1, -1, -1):
		if active_quests[i].get("id", "") == quest_id:
			active_quests.remove_at(i)
			break
	# Award rewards from pool definition
	var quest_def: Dictionary = _quest_pool.get(quest_id, {})
	var reward: Dictionary = quest_def.get("reward", {})
	var quest_name: String = quest_def.get("name", quest_id)
	if not reward.is_empty():
		_apply_quest_reward(reward)
	# Log the completion
	var log_msg := "✓ Quest complete: %s" % quest_name
	if reward.get("xp", 0) > 0:
		log_msg += "  +%d XP" % int(reward.xp)
	if reward.get("gold", 0) > 0:
		log_msg += "  +%d gold" % int(reward.gold)
	append_overworld_log(log_msg)
	quest_completed.emit(quest_id, quest_name, reward)


## Check all active quests; complete any that are fully done.
## Call this from set_flag() so completion triggers automatically.
func check_quest_completion() -> void:
	# Iterate backwards so we can remove during iteration safely
	var ids_to_complete: Array[String] = []
	for quest in active_quests:
		var qid: String = quest.get("id", "")
		if qid != "" and is_quest_complete(qid):
			ids_to_complete.append(qid)
	for qid in ids_to_complete:
		complete_quest(qid)


## Apply xp/gold/karma rewards from a quest reward dict.
func _apply_quest_reward(reward: Dictionary) -> void:
	var xp: int = int(reward.get("xp", 0))
	var gold: int = int(reward.get("gold", 0))
	if xp > 0:
		# apply_party_xp handles XP multipliers for party size (same as event rewards)
		CompanionSystem.apply_party_xp(xp)
	if gold > 0:
		# Gold stored on party leader (player character)
		var player = CharacterSystem.get_player()
		if player:
			player["gold"] = player.get("gold", 0) + gold
	# Karma: KarmaSystem.add_karma(realm, amount, description)
	var karma: Dictionary = reward.get("karma", {})
	for realm in karma:
		KarmaSystem.add_karma(realm, int(karma[realm]))


## Append a message to the session overworld log.
func append_overworld_log(msg: String) -> void:
	overworld_log.append(msg)
	overworld_log_updated.emit(msg)
```

- [ ] **Add `quest_completed` and `overworld_log_updated` signals near the top of `game_state.gd`**

Near the existing `signal` declarations (around line 10-20):

```gdscript
signal quest_completed(quest_id: String, quest_name: String, reward: Dictionary)
signal overworld_log_updated(message: String)
```

- [ ] **Call `check_quest_completion()` from `set_flag()`**

Replace the current `set_flag()`:

```gdscript
func set_flag(key: String, value) -> void:
	flags[key] = value
	check_quest_completion()
```

- [ ] **Add a public getter for quest pool definitions** (avoids direct `_quest_pool` access from UI code)

After `get_available_quests_for_realm()`, add:

```gdscript
## Returns a quest definition from the pool by id. Returns {} if not found.
func get_quest_def(quest_id: String) -> Dictionary:
	return _quest_pool.get(quest_id, {})
```

- [ ] **Wire `completed_quest_ids` into save/load in `game_state.gd`**

In `get_save_data()` (in `game_state.gd`), add:
```gdscript
"completed_quest_ids": completed_quest_ids.duplicate(),
```

In `load_save_data()` (in `game_state.gd`), add (alongside the existing flags/active_quests load lines):
```gdscript
completed_quest_ids = []
for id in data.get("completed_quest_ids", []):
	completed_quest_ids.append(str(id))
overworld_log = []  # session-only; always start fresh on load
```

- [ ] **Reset in `save_manager.gd` new-game block**

After the existing `GameState.flags = {}` and `GameState.active_quests = []` lines, add:
```gdscript
GameState.completed_quest_ids = []
GameState.overworld_log = []
```

- [ ] **Commit**

```
git add scripts/autoload/game_state.gd scripts/autoload/save_manager.gd
git commit -m "feat: quest pool loading, completed_quest_ids, check_quest_completion, overworld_log"
```

---

## Chunk 2: Journal UI Overhaul

### Task 3: Rename Quests tab to "Journal", add J keybinding, two-panel layout

**Files:**
- Modify: `scripts/ui/main_menu.gd`

The existing Quest Log tab is a single-panel scroll list. Replace it with a two-panel HSplit: left list of quest titles, right panel shows selected quest details (description, steps, reward).

- [ ] **Rename the tab from "Quests" to "Journal"**

Find the line (around line 157):
```gdscript
tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Quests")
```
Change to:
```gdscript
tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Journal")
```

- [ ] **Add J keybinding in `overworld.gd` (opens character sheet to Journal tab)**

In `overworld.gd`, in the `_input` keycode match block (around line 183-204), add after the existing `KEY_S` / `KEY_E` / `KEY_C` etc. cases:

```gdscript
			KEY_J:
				get_viewport().set_input_as_handled()
				_open_char_sheet_to_tab(5)
```

Also add J to the HUD button row in `_build_hud_buttons()` (or wherever the other shortcut buttons are defined), OR simply document it — the button row already has C/E/P/S shortcuts, adding J is a keyboard-only shortcut like the others.

- [ ] **Rebuild the Journal tab as a two-panel layout in `main_menu.gd`**

Replace the block that creates the Quests tab (the `quests_scroll` / `_quests_container` setup around lines 148-157) with:

```gdscript
	# Journal tab — two-panel: title list on left, details on right
	var journal_root := HSplitContainer.new()
	journal_root.name = "Journal"
	journal_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_root.split_offset = 200  # left panel ~200px wide

	# Left: scrollable list of quest titles
	var journal_list_scroll := ScrollContainer.new()
	journal_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_list_scroll.custom_minimum_size = Vector2(180, 0)
	_journal_list = VBoxContainer.new()
	_journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_list.add_theme_constant_override("separation", 4)
	journal_list_scroll.add_child(_journal_list)
	journal_root.add_child(journal_list_scroll)

	# Right: detail panel (RichTextLabel + padding)
	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = Color(0.08, 0.07, 0.06)
	dp_style.content_margin_left = 12
	dp_style.content_margin_right = 12
	dp_style.content_margin_top = 10
	dp_style.content_margin_bottom = 10
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	_journal_detail = RichTextLabel.new()
	_journal_detail.bbcode_enabled = true
	_journal_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_journal_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_detail.scroll_active = true
	_journal_detail.text = "[color=#666666]Select a quest to view details.[/color]"
	detail_panel.add_child(_journal_detail)
	journal_root.add_child(detail_panel)

	tab_container.add_child(journal_root)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Journal")
```

- [ ] **Declare new member variables** near the top of `main_menu.gd` (replace the old `_quests_container` line):

```gdscript
var _journal_list: VBoxContainer = null     # Left-panel quest title buttons
var _journal_detail: RichTextLabel = null   # Right-panel quest details
var _journal_selected_id: String = ""       # Currently selected quest id
```

Remove the old `var _quests_container: VBoxContainer = null` line.

- [ ] **Rewrite `_update_quests_tab()` → rename to `_update_journal_tab()`**

Replace the existing `_update_quests_tab()` and `_create_quest_card()` functions with:

```gdscript
## Journal tab — rebuilds the left-panel list; preserves selection if possible.
func _update_journal_tab() -> void:
	if not is_instance_valid(_journal_list):
		return
	for child in _journal_list.get_children():
		child.queue_free()

	var active: Array[Dictionary] = GameState.active_quests
	var completed_ids: Array[String] = GameState.completed_quest_ids

	if active.is_empty() and completed_ids.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No quests recorded."
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_journal_list.add_child(empty_lbl)
		if is_instance_valid(_journal_detail):
			_journal_detail.text = "[color=#666666]No quests yet.[/color]"
		return

	# Active quests first, then completed
	var entries: Array[Dictionary] = []
	for q in active:
		entries.append(q)
	# Also show completed quests from pool
	for qid in completed_ids:
		var qdef: Dictionary = GameState.get_quest_def(qid)
		if not qdef.is_empty():
			entries.append(qdef)

	var first_id := ""
	for quest in entries:
		var qid: String = quest.get("id", "")
		if first_id == "":
			first_id = qid
		var is_done: bool = GameState.completed_quest_ids.has(qid)
		var btn := Button.new()
		btn.text = ("✓ " if is_done else "○ ") + quest.get("name", "?")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.custom_minimum_size = Vector2(0, 32)
		var col := Color(0.5, 0.5, 0.5) if is_done else Color(0.85, 0.70, 0.30)
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		# Highlight selected
		if qid == _journal_selected_id:
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(0.18, 0.14, 0.10)
			btn.add_theme_stylebox_override("normal", sel_style)
		btn.pressed.connect(func(): _journal_select_quest(qid))
		_journal_list.add_child(btn)

	# Auto-select first or preserve selection
	if _journal_selected_id == "" or not _journal_entry_exists(_journal_selected_id):
		_journal_selected_id = first_id
	_journal_show_detail(_journal_selected_id)


func _journal_entry_exists(quest_id: String) -> bool:
	for q in GameState.active_quests:
		if q.get("id", "") == quest_id:
			return true
	return GameState.completed_quest_ids.has(quest_id)


func _journal_select_quest(quest_id: String) -> void:
	_journal_selected_id = quest_id
	_update_journal_tab()


func _journal_show_detail(quest_id: String) -> void:
	if not is_instance_valid(_journal_detail) or quest_id == "":
		return
	# Prefer active quest dict (has runtime data); fall back to pool def
	var quest: Dictionary = {}
	for q in GameState.active_quests:
		if q.get("id", "") == quest_id:
			quest = q
			break
	if quest.is_empty():
		quest = GameState.get_quest_def(quest_id)
	if quest.is_empty():
		_journal_detail.text = "[color=#666666]Quest not found.[/color]"
		return

	var is_done: bool = GameState.completed_quest_ids.has(quest_id)
	var txt := ""

	# Title
	var title_col := "#888888" if is_done else "#d4a843"
	txt += "[b][color=%s]%s[/color][/b]" % [title_col, quest.get("name", "?")]
	if is_done:
		txt += "  [color=#4ade80][b][COMPLETE][/b][/color]"
	txt += "\n\n"

	# Description
	var desc: String = quest.get("description", "")
	if desc != "":
		txt += "[color=#9a9080]%s[/color]\n\n" % desc

	# Steps
	var steps: Array = quest.get("steps", [])
	if not steps.is_empty():
		txt += "[b]Objectives:[/b]\n"
		for step in steps:
			var done: bool = GameState.is_quest_step_done(step)
			var mark := "[color=#4ade80]✓[/color]" if done else "[color=#666666]○[/color]"
			var step_col := "#666666" if done else "#b8a898"
			txt += "  %s [color=%s]%s[/color]\n" % [mark, step_col, step.get("text", "")]
		txt += "\n"

	# Reward
	var reward: Dictionary = quest.get("reward", {})
	if not reward.is_empty():
		txt += "[b]Reward:[/b]\n"
		if reward.get("xp", 0) > 0:
			txt += "  [color=#a0c8ff]+%d XP[/color]\n" % int(reward.xp)
		if reward.get("gold", 0) > 0:
			txt += "  [color=#f0d060]+%d gold[/color]\n" % int(reward.gold)
		var karma: Dictionary = reward.get("karma", {})
		for realm in karma:
			var amt: int = int(karma[realm])
			var ksign := "+" if amt > 0 else ""
			txt += "  [color=#c890e0]☸ %s: %s%d[/color]\n" % [realm.capitalize(), ksign, amt]

	_journal_detail.text = txt
```

- [ ] **Update all references from `_update_quests_tab` to `_update_journal_tab`**

Search for all calls to `_update_quests_tab()` in `main_menu.gd` (there should be two: in `refresh_all_tabs()` and in `_on_tab_changed()`). Replace both with `_update_journal_tab()`.

- [ ] **Commit**

```
git add scripts/ui/main_menu.gd scripts/overworld/overworld.gd
git commit -m "feat: Journal tab — two-panel layout, J keybinding, completed quest history"
```

---

## Chunk 3: Quest Board Overlay

### Task 4: Quest board scene + script

**Files:**
- Create: `scenes/ui/quest_board.tscn`
- Create: `scripts/ui/quest_board.gd`

The quest board is a modal overlay (like `shop_ui`) that shows up to 5 random available quests for the current realm. Each quest has an Accept button.

- [ ] **Create `scripts/ui/quest_board.gd`**

```gdscript
extends Control
## Quest Board — shows a randomised pool of available quests for the current realm.
## Shown as an overlay in the overworld when an event triggers "quest_board" outcome.

signal quest_board_closed

const MAX_QUESTS_SHOWN := 5

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var quests_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestsContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _realm: String = ""


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func show_board(realm: String) -> void:
	_realm = realm
	title_label.text = "Quest Board"
	_populate()
	visible = true


func _populate() -> void:
	for child in quests_container.get_children():
		child.queue_free()

	var available := GameState.get_available_quests_for_realm(_realm)
	# Shuffle and cap
	available.shuffle()
	var shown := available.slice(0, MAX_QUESTS_SHOWN)

	if shown.is_empty():
		var lbl := Label.new()
		lbl.text = "No quests available."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		quests_container.add_child(lbl)
		return

	for quest in shown:
		quests_container.add_child(_create_quest_row(quest))


func _create_quest_row(quest: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.07)
	style.border_width_left = 3
	style.border_color = Color(0.55, 0.40, 0.12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Info column
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = quest.get("name", "?")
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	name_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = quest.get("description", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.55))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)

	# Reward summary
	var reward: Dictionary = quest.get("reward", {})
	var reward_parts: Array[String] = []
	if reward.get("xp", 0) > 0:
		reward_parts.append("+%d XP" % int(reward.xp))
	if reward.get("gold", 0) > 0:
		reward_parts.append("+%d gold" % int(reward.gold))
	if not reward_parts.is_empty():
		var reward_lbl := Label.new()
		reward_lbl.text = "Reward: " + "  ".join(reward_parts)
		reward_lbl.add_theme_color_override("font_color", Color(0.50, 0.65, 0.85))
		reward_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(reward_lbl)

	# Accept button
	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(80, 0)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.30, 0.15)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.3, 0.6, 0.3)
	btn_style.content_margin_left = 10
	btn_style.content_margin_right = 10
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	accept_btn.add_theme_stylebox_override("normal", btn_style)
	accept_btn.add_theme_color_override("font_color", Color.WHITE)
	var qid: String = quest.get("id", "")
	accept_btn.pressed.connect(func(): _on_accept_pressed(qid))
	hbox.add_child(accept_btn)

	return row


func _on_accept_pressed(quest_id: String) -> void:
	AudioManager.play("ui_click")
	if GameState.accept_quest(quest_id):
		var qname: String = GameState.get_quest_def(quest_id).get("name", quest_id)
		GameState.append_overworld_log("Quest accepted: %s" % qname)
	_populate()  # Refresh list (accepted quest disappears)


func _on_close_pressed() -> void:
	AudioManager.play("ui_click")
	visible = false
	quest_board_closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
```

- [ ] **Create `scenes/ui/quest_board.tscn` via Godot editor or inline**

Create a minimal scene that matches the node paths used by `quest_board.gd`:
```
Control (quest_board.gd)
└── Panel
    └── MarginContainer (margins: 16 all sides)
        └── VBoxContainer (separation: 12)
            ├── TitleLabel (Label, font_size 18)
            ├── QuestsContainer (VBoxContainer, separation: 8, min_size 600x400)
            └── CloseButton (Button, text "Close", min_size 0x40)
```

Since the scene editor is needed, create it as a GDScript-only variant where the node tree is built in `_ready()`:

Replace the `.tscn`-based approach with a fully code-built scene. Update `quest_board.gd` `_ready()` to build all nodes:

```gdscript
extends Control
## Quest Board — built entirely in code (no .tscn dependency).

signal quest_board_closed

const MAX_QUESTS_SHOWN := 5

var title_label: Label
var quests_container: VBoxContainer
var close_button: Button
var _realm: String = ""


func _ready() -> void:
	# Backdrop
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 480)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.07, 0.06)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.55, 0.40, 0.12)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var margin := MarginContainer.new()
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.text = "Quest Board"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	vbox.add_child(title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(scroll)

	quests_container = VBoxContainer.new()
	quests_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quests_container.add_theme_constant_override("separation", 8)
	scroll.add_child(quests_container)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0, 40)
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)
```

- [ ] **Commit**

```
git add scripts/ui/quest_board.gd
git commit -m "feat: quest board overlay script with pool-draw Accept buttons"
```

---

### Task 5: `quest_board_requested` signal in EventManager + overworld wiring

**Files:**
- Modify: `scripts/autoload/event_manager.gd`
- Modify: `scripts/overworld/overworld.gd`

- [ ] **Add `quest_board_requested` signal to `event_manager.gd`**

Near the existing `signal shop_requested` (~line 14):

```gdscript
signal quest_board_requested(realm: String, outcome: Dictionary)
```

- [ ] **Handle `"quest_board"` outcome type in `apply_outcome()`**

In the `match outcome.get("type", "text"):` block at the bottom of `apply_outcome()`, add alongside the existing `"shop"` case:

```gdscript
		"quest_board":
			quest_board_requested.emit(outcome.get("realm", "hell"), outcome)
			# Do NOT emit event_completed — overworld handles showing result panel
			return
```

- [ ] **Wire `quest_board_requested` in `overworld.gd`**

In `_ready()`, after the `EventManager.shop_requested.connect(...)` line:

```gdscript
	EventManager.quest_board_requested.connect(_on_event_quest_board_requested)
```

- [ ] **Add `_quest_board_open` flag and handler variables near the other overlay vars** in `overworld.gd` (near the existing `_char_sheet_open` declaration):

```gdscript
var _quest_board_open: bool = false
var _quest_board_instance: Control = null
```

- [ ] **Add `_on_event_quest_board_requested()` handler in `overworld.gd`**

After `_on_event_shop_requested()`:

```gdscript
func _on_event_quest_board_requested(realm: String, outcome: Dictionary) -> void:
	# Hide event display while board is open
	if is_instance_valid(event_display):
		event_display.visible = false

	if not is_instance_valid(_quest_board_instance):
		var board_script := load("res://scripts/ui/quest_board.gd")
		_quest_board_instance = board_script.new()
		# Add to a CanvasLayer above events (z=25, same as shop)
		var board_layer := CanvasLayer.new()
		board_layer.layer = 25
		board_layer.add_child(_quest_board_instance)
		add_child(board_layer)

	_quest_board_open = true
	# Use CONNECT_ONE_SHOT so callback fires once and disconnects automatically.
	# Safe to reconnect each open because CONNECT_ONE_SHOT removes the previous one
	# after it fires; if for some reason the board is opened twice without closing,
	# we disconnect manually first to prevent double callbacks.
	if _quest_board_instance.quest_board_closed.is_connected(_on_quest_board_closed_wrapper):
		_quest_board_instance.quest_board_closed.disconnect(_on_quest_board_closed_wrapper)
	_quest_board_instance.quest_board_closed.connect(_on_quest_board_closed_wrapper.bind(outcome), CONNECT_ONE_SHOT)
	_quest_board_instance.show_board(realm)


func _on_quest_board_closed_wrapper(outcome: Dictionary) -> void:
	_quest_board_open = false
	if is_instance_valid(_quest_board_instance):
		_quest_board_instance.visible = false
	# Show event result panel (outcome text if any)
	if is_instance_valid(event_display):
		event_display.visible = true
		event_display.display_outcome(outcome)
```

- [ ] **Add `_quest_board_open` to the ESC guard in `_input()`**

Find the ESC key handling in `_input()` (around line 203-212). The current guard condition checks `not _event_open and not _shop_open`. Change it to also check `_quest_board_open`:

```gdscript
elif not _event_open and not _shop_open and not _quest_board_open:
    _open_main_menu()
```

(The exact surrounding code context: find the line with `if _main_menu_open:` in the KEY_ESCAPE case and look at the following elif.)


- [ ] **Commit**

```
git add scripts/autoload/event_manager.gd scripts/overworld/overworld.gd
git commit -m "feat: quest_board_requested signal + overworld overlay handler"
```

---

## Chunk 4: Overworld Message Log

### Task 6: Message log toggle panel in overworld HUD

**Files:**
- Modify: `scripts/overworld/overworld.gd`
- Modify: `scenes/overworld/overworld.tscn` (add nodes via `_ready()` to avoid scene file editing)

The log panel is in the bottom-right corner. A small toggle button (💬) is always visible. Clicking it slides in/out a scrollable list of all `GameState.overworld_log` entries.

- [ ] **Add log toggle button and panel via code in overworld `_ready()`**

After the existing `_build_main_menu_panel()` call (around line 147), add:

```gdscript
	_build_log_panel()
```

Then add `_build_log_panel()` as a new function:

```gdscript
var _log_panel_visible: bool = false
var _log_panel: PanelContainer = null
var _log_list: VBoxContainer = null
var _log_toggle_btn: Button = null

func _build_log_panel() -> void:
	# Create a CanvasLayer so it floats above the map (layer 11 = above event overlay at 10)
	var log_layer := CanvasLayer.new()
	log_layer.layer = 11
	add_child(log_layer)

	# Intermediate full-rect Control required so that child anchor presets work correctly
	# (Control nodes cannot anchor relative to a CanvasLayer directly in Godot 4)
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_layer.add_child(root_ctrl)

	# Toggle button — bottom-right corner
	_log_toggle_btn = Button.new()
	_log_toggle_btn.text = "💬"
	_log_toggle_btn.tooltip_text = "Toggle message log"
	_log_toggle_btn.custom_minimum_size = Vector2(36, 36)
	_log_toggle_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_log_toggle_btn.position = Vector2(-44, -44)
	_log_toggle_btn.pressed.connect(_toggle_log_panel)
	root_ctrl.add_child(_log_toggle_btn)

	# Log panel — above the toggle button
	_log_panel = PanelContainer.new()
	_log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_log_panel.custom_minimum_size = Vector2(320, 240)
	_log_panel.position = Vector2(-328, -292)
	_log_panel.visible = false
	var lp_style := StyleBoxFlat.new()
	lp_style.bg_color = Color(0.05, 0.04, 0.04, 0.90)
	lp_style.border_width_left = 2
	lp_style.border_width_right = 2
	lp_style.border_width_top = 2
	lp_style.border_width_bottom = 2
	lp_style.border_color = Color(0.30, 0.25, 0.15)
	lp_style.content_margin_left = 8
	lp_style.content_margin_right = 8
	lp_style.content_margin_top = 6
	lp_style.content_margin_bottom = 6
	_log_panel.add_theme_stylebox_override("panel", lp_style)
	root_ctrl.add_child(_log_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_panel.add_child(scroll)

	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_log_list)

	# Connect to future log entries
	GameState.overworld_log_updated.connect(_on_overworld_log_updated)

	# Populate with any existing entries (e.g. after scene reload)
	for msg in GameState.overworld_log:
		_append_log_entry(msg)


func _toggle_log_panel() -> void:
	_log_panel_visible = not _log_panel_visible
	_log_panel.visible = _log_panel_visible


func _on_overworld_log_updated(msg: String) -> void:
	_append_log_entry(msg)


func _append_log_entry(msg: String) -> void:
	if not is_instance_valid(_log_list):
		return
	var lbl := Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	_log_list.add_child(lbl)
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll := _log_list.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
```

- [ ] **Wire `_show_toast()` to also log the message**

In the existing `_show_toast()` function (around line 627):

```gdscript
func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	_toast_timer = TOAST_DURATION
	GameState.append_overworld_log(msg)  # <-- add this line
```

- [ ] **Verify**: run the game on the overworld, trigger a discovery/combat toast, open the log panel with the 💬 button, confirm the message appears.

- [ ] **Commit**

```
git add scripts/overworld/overworld.gd
git commit -m "feat: overworld message log toggle panel in bottom-right corner"
```

---

## Chunk 5: Data Format Reference & TODO Update

### Task 7: Update TODO.md and memory

- [ ] **Update `TODO.md`** — mark these items complete:
  - `[ ] Journal/Quest log UI` → done (two-panel Journal tab, J keybinding)
  - `[ ] Quest board at locations` → done (quest_board outcome type + overlay)
  - `[ ] Quest completion rewards` → done (auto-detected via set_flag, rewarded + logged)
  - `[ ] Overworld message log` → done (toggle panel, all toasts logged)

- [ ] **Commit**

```
git add TODO.md
git commit -m "docs: update TODO — quest journal expansion complete"
```

---

## Data Format Reference

### quest_board outcome in an event

```json
{
  "id": "browse_quests",
  "type": "default",
  "text": "Browse the quest board",
  "outcome": {
    "type": "quest_board",
    "text": "You scan the board for work.",
    "realm": "hell"
  }
}
```

### Quest definition in quests.json

```json
{
  "id": "cold_prisoner",
  "name": "The Frozen Prisoner",
  "description": "A soul encased in ice begs for release.",
  "realm": "hell",
  "steps": [
    { "text": "Find the warden's seal",  "done_when": { "flag": "cold_warden_seal_found", "value": true } },
    { "text": "Return to the prisoner",  "done_when": { "flag": "cold_prisoner_freed",    "value": true } }
  ],
  "reward": { "xp": 250, "gold": 0, "karma": { "hell": -10, "human": 5 } }
}
```

### Completing a quest via set_flags

```json
"outcome": {
  "type": "text",
  "text": "You prise the warden's seal from the ice.",
  "set_flags": { "cold_warden_seal_found": true }
}
```
`set_flag()` calls `check_quest_completion()` automatically — when the final step is satisfied, `complete_quest()` fires, awards rewards, and logs the completion.

### Notes
- Quest pool quests are NOT registered via `register_quest` outcome — instead the player Accepts them from the quest board, which calls `GameState.accept_quest(id)`.
- Event-given quests (registered via `register_quest` outcome in event JSON) work exactly as before — they just won't appear in the quest board pool (they're inline quest data, not from quests.json).
- `overworld_log` is session-only and resets on scene reload. It is NOT persisted to disk.
