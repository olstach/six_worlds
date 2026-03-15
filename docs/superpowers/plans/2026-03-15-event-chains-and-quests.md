# Event Chains & Quest System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add state flags, event chains (chained follow-up events, flag prerequisites), and a quest system (registration, tracking, log UI) that all share a single underlying flag store.

**Architecture:** A `flags` dictionary in GameState is the single source of truth — event outcomes write flags, choice prerequisites read flags, and the quest log derives step completion from flags. Quests are event chains that additionally register themselves in `active_quests`. No new autoload is needed; all logic lives in GameState and EventManager with a new Quest Log tab in the character sheet.

**Tech Stack:** GDScript / Godot 4.3. All data in JSON (events) and GDScript (UI built in code). No new scene files needed except the quest log tab content node.

---

## Chunk 1: Flag System in GameState

### Task 1: Add `flags` and `active_quests` to GameState + save/load

**Files:**
- Modify: `scripts/autoload/game_state.gd`
- Modify: `scripts/autoload/save_manager.gd` (reset on new game only)

- [ ] **Add the two new fields and helper functions to `game_state.gd`**

After the `guild_spell_lists` variable declaration (around line 66), add:

```gdscript
# Persistent world-state flags used by event chains and quests.
# Keys are strings; values can be bool, int, or string.
# Format: { "flag_key": value, ... }
var flags: Dictionary = {}

# Active quests registered by event outcomes.
# Each entry: { "id": String, "name": String, "description": String,
#               "steps": [{"text": String, "done_when": {"flag": String, "value": Variant}}, ...] }
var active_quests: Array = []
```

Then add these helper functions near the end of the file (before `get_save_data`):

```gdscript
## Set a world-state flag. Value can be bool, int, or String.
func set_flag(key: String, value) -> void:
	flags[key] = value


## Get a world-state flag value. Returns default_value if not set.
func get_flag(key: String, default_value = false):
	return flags.get(key, default_value)


## Register a new quest. Does nothing if a quest with this id already exists.
func register_quest(quest: Dictionary) -> void:
	var quest_id: String = quest.get("id", "")
	if quest_id == "":
		push_error("GameState.register_quest: quest missing 'id' field")
		return
	for existing in active_quests:
		if existing.get("id", "") == quest_id:
			return  # Already registered
	active_quests.append(quest.duplicate(true))


## Returns true if all steps of a quest are complete (all done_when flags match).
func is_quest_complete(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.get("id", "") != quest_id:
			continue
		for step in quest.get("steps", []):
			if not _quest_step_done(step):
				return false
		return true
	return false


## Returns true if this single step's done_when condition is satisfied.
func _quest_step_done(step: Dictionary) -> bool:
	var done_when: Dictionary = step.get("done_when", {})
	if done_when.is_empty():
		return false
	var flag_key: String = done_when.get("flag", "")
	if flag_key == "":
		return false
	var expected = done_when.get("value", true)
	return flags.get(flag_key, false) == expected
```

- [ ] **Wire flags and active_quests into `get_save_data()`**

In `get_save_data()`, add two lines to the returned dictionary:

```gdscript
"flags": flags.duplicate(true),
"active_quests": active_quests.duplicate(true),
```

- [ ] **Wire flags and active_quests into `load_save_data()`**

In `load_save_data()`, add:

```gdscript
flags = data.get("flags", {})
active_quests = []
for q in data.get("active_quests", []):
    active_quests.append(q.duplicate(true))  # deep copy — quest dicts may be mutated at runtime
```

- [ ] **Reset flags and active_quests on new game in `save_manager.gd`**

In the new-game reset block (around line 161 where `used_event_choices = {}`), add:

```gdscript
GameState.flags = {}
GameState.active_quests = []
```

- [ ] **Verify by reading the modified sections** — confirm the new fields appear in both `get_save_data` and `load_save_data`, and in the new-game reset.

- [ ] **Commit**

```
git add scripts/autoload/game_state.gd scripts/autoload/save_manager.gd
git commit -m "feat: add flags + active_quests to GameState with save/load"
```

---

## Chunk 2: EventManager — Flags + Prerequisite Evaluation

### Task 2: Apply `set_flags` in `apply_outcome()`

**Files:**
- Modify: `scripts/autoload/event_manager.gd`

Outcome objects in JSON can now include:
```json
"set_flags": { "met_someone": true, "quest_x": "started" }
```

- [ ] **Add `set_flags` processing in `apply_outcome()`**

Inside `apply_outcome()`, after the `if "rewards" in outcome:` block and before the `if "cost" in outcome:` block, add:

```gdscript
	# Write world-state flags declared by this outcome
	if "set_flags" in outcome:
		for flag_key in outcome.set_flags:
			GameState.set_flag(flag_key, outcome.set_flags[flag_key])
```

- [ ] **Commit**

```
git add scripts/autoload/event_manager.gd
git commit -m "feat: apply set_flags from event outcomes into GameState"
```

### Task 3: Prerequisite filtering on choices

Choices can now have a `"prerequisite"` field that **hides** the choice when not met (unlike `requirements`, which shows it disabled). This is for flag-based visibility.

```json
{
  "id": "follow_up_branch",
  "type": "default",
  "prerequisite": { "flag": "met_the_pilgrim", "value": true },
  "text": "Ask about the chains",
  "outcome": { ... }
}
```

- [ ] **Handle `prerequisite` in `evaluate_choice_availability()`**

At the very top of `evaluate_choice_availability()`, before the existing "Already done" check, add:

```gdscript
	# Flag prerequisite: if present and not satisfied, hide this choice entirely.
	if "prerequisite" in choice:
		var prereq: Dictionary = choice.prerequisite
		var flag_key: String = prereq.get("flag", "")
		var expected = prereq.get("value", true)
		if flag_key != "" and GameState.get_flag(flag_key, false) != expected:
			result.available = false
			result["hidden"] = true
			return result
```

- [ ] **Skip hidden choices in `event_display.gd display_event()`**

In `display_event()`, change the loop that creates choice buttons:

```gdscript
	for choice in current_event.choices:
		var availability = EventManager.evaluate_choice_availability(choice)
		if availability.get("hidden", false):
			continue  # Flag prerequisite not met — don't render this choice at all
		if availability.available:
			any_available = true
		create_choice_button(choice, availability)
```

- [ ] **Commit**

```
git add scripts/autoload/event_manager.gd scripts/ui/event_display.gd
git commit -m "feat: flag prerequisite on choices — hide when condition not met"
```

---

## Chunk 3: EventManager — follow_up_event Outcome Type

When an outcome has `"follow_up_event": "some_event_id"`, after the player dismisses the result panel the next event starts automatically instead of closing the event display.

### Task 4: follow_up_event in EventManager and EventDisplay

**Files:**
- Modify: `scripts/autoload/event_manager.gd`
- Modify: `scripts/ui/event_display.gd`

- [ ] **Handle `follow_up_event` as an outcome type in `apply_outcome()`**

In the `match outcome.get("type", "text"):` block at the bottom of `apply_outcome()`, add a new case:

```gdscript
		"follow_up":
			# Chain to another event after the player sees the result text.
			# event_display will read current_outcome.follow_up_event to decide
			# whether to close or start the next event on Continue.
			event_completed.emit(outcome)
```

Also handle `follow_up_event` key on any outcome type: even `"text"` outcomes can have a follow-up. Move the follow-up check into `event_display` — that's where the Continue button lives.

- [ ] **Handle follow-up in `_on_continue_button_pressed()` in `event_display.gd`**

Replace the current `_on_continue_button_pressed()`:

```gdscript
func _on_continue_button_pressed() -> void:
	AudioManager.play("ui_click")
	var follow_up: String = current_outcome.get("follow_up_event", "")
	if follow_up != "":
		# Chain directly into the next event — start it fresh (no object context inheritance).
		# Pass "", false so the chained event is not treated as one-time or tracked
		# against the triggering map object's used-choices list.
		show_event(follow_up, "", false)
	else:
		event_panel.visible = false
		result_panel.visible = false
		visible = false
		event_display_closed.emit()
```

- [ ] **Test the chain manually**: in `hell_events.json`, temporarily add `"follow_up_event": "hell_demon_patrol"` to any outcome, load the game, trigger that event, confirm that pressing Continue starts the demon patrol event instead of closing.

- [ ] **Remove the temporary test change** from hell_events.json.

- [ ] **Commit**

```
git add scripts/autoload/event_manager.gd scripts/ui/event_display.gd
git commit -m "feat: follow_up_event outcome type chains events on Continue"
```

---

## Chunk 4: Quest Registration + Quest Log UI

### Task 5: `register_quest` outcome type in EventManager

**Files:**
- Modify: `scripts/autoload/event_manager.gd`

An outcome can include `"register_quest"` to start a quest:

```json
"register_quest": {
  "id": "rescue_the_pilgrim",
  "name": "Break the Chains",
  "description": "A penitent soul asked for help. Find their chains.",
  "steps": [
    { "text": "Find the chains",   "done_when": { "flag": "chains_found",   "value": true } },
    { "text": "Return to pilgrim", "done_when": { "flag": "pilgrim_freed",  "value": true } }
  ]
}
```

- [ ] **Add `register_quest` processing in `apply_outcome()`**, after the `set_flags` block:

```gdscript
	# Register a new quest if the outcome defines one
	if "register_quest" in outcome:
		GameState.register_quest(outcome.register_quest)
```

- [ ] **Commit**

```
git add scripts/autoload/event_manager.gd
git commit -m "feat: register_quest outcome type writes quest into GameState"
```

### Task 6: Quest Log tab in the character sheet

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scenes/ui/main_menu.tscn` (add a new tab via code, not editor, to keep the diff clean)

The Quest Log is a ScrollContainer inside a new Tab. It lists each active quest with:
- Quest name (bold) + description
- Steps as a checklist: ✓ green (complete) or ○ grey (incomplete)
- Completed quests shown at the bottom, dimmed

- [ ] **Add `_update_quests_tab()` function to `main_menu.gd`**

Find the end of the file (or after `_update_followers_list`) and add:

```gdscript
## Quest Log tab — reads GameState.active_quests and resolves step flags.
func _update_quests_tab() -> void:
	if not is_instance_valid(_quests_container):
		return
	for child in _quests_container.get_children():
		child.queue_free()

	var quests: Array = GameState.active_quests
	if quests.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No active quests."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_quests_container.add_child(empty_label)
		return

	# Sort: incomplete first, complete last
	var incomplete: Array = []
	var complete: Array = []
	for quest in quests:
		if GameState.is_quest_complete(quest.get("id", "")):
			complete.append(quest)
		else:
			incomplete.append(quest)

	for quest in incomplete + complete:
		_quests_container.add_child(_create_quest_card(quest))


func _create_quest_card(quest: Dictionary) -> PanelContainer:
	var is_complete := GameState.is_quest_complete(quest.get("id", ""))

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.08) if not is_complete else Color(0.08, 0.08, 0.08)
	style.border_width_left = 3
	style.border_color = Color(0.6, 0.45, 0.15) if not is_complete else Color(0.3, 0.3, 0.3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = quest.get("name", "Unknown Quest") + (" [COMPLETE]" if is_complete else "")
	title_lbl.add_theme_color_override("font_color",
			Color(0.85, 0.7, 0.3) if not is_complete else Color(0.45, 0.45, 0.45))
	title_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_lbl)

	# Description
	var desc: String = quest.get("description", "")
	if desc != "":
		var desc_lbl := Label.new()
		desc_lbl.text = desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.55))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(desc_lbl)

	# Steps
	for step in quest.get("steps", []):
		var step_done := GameState._quest_step_done(step)
		var step_lbl := Label.new()
		step_lbl.text = ("  ✓ " if step_done else "  ○ ") + step.get("text", "")
		step_lbl.add_theme_color_override("font_color",
				Color(0.4, 0.8, 0.4) if step_done else Color(0.55, 0.55, 0.55))
		step_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(step_lbl)

	return card
```

- [ ] **Add the Quest Log tab and container in `_ready()` (or `_setup_tabs()` if that exists)**

Find where tabs are set up in `main_menu.gd` (around line 143 where "Character" tab is renamed). After the existing tab setup, add:

```gdscript
	# Quest Log tab — built in code to avoid scene file churn
	var quests_scroll := ScrollContainer.new()
	quests_scroll.name = "Quests"
	quests_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_quests_container = VBoxContainer.new()
	_quests_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quests_container.add_theme_constant_override("separation", 8)
	quests_scroll.add_child(_quests_container)
	tab_container.add_child(quests_scroll)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, "Quests")
```

- [ ] **Declare `_quests_container` as a member variable** near the top of `main_menu.gd`:

```gdscript
var _quests_container: VBoxContainer = null
```

- [ ] **Call `_update_quests_tab()` from `refresh_all_tabs()`**

In `refresh_all_tabs()` (around line 1675), add:

```gdscript
	_update_quests_tab()
```

- [ ] **Add an explicit case in `_on_tab_changed()` for the Quests tab**

`_on_tab_changed` in main_menu.gd handles tabs by index with `if tab == 0 / elif tab == 1 ...` etc. The Quests tab will be at the end of the tab list. Count existing tabs in the scene to find the index (currently 5 tabs: Character/Stats, Equipment, Spellbook, Crafting, Party — so Quests will be index 5). Add:

```gdscript
elif tab == 5:
    _update_quests_tab()
```

Do NOT rely on `refresh_all_tabs()` being called — it is not called from `_on_tab_changed` in the current code.

- [ ] **Verify the Quest Log renders in-game**: open the character sheet, navigate to Quests tab, confirm it shows "No active quests." with no errors.

- [ ] **Commit**

```
git add scripts/ui/main_menu.gd
git commit -m "feat: Quest Log tab in character sheet reads GameState.active_quests"
```

---

## Chunk 5: Documentation + TODO Update

### Task 7: Update TODO and memory

- [ ] **Update `TODO.md`**: move Event Chains and Quest System items to completed; add notes on the data format.

Mark these as done:
- `[ ] Event chains and prerequisites` → done
- `[ ] Quest data structure` → done
- `[ ] Quest giver NPCs` → note: wired via `register_quest` outcome in any event
- `[ ] Quest log UI tab` → done
- `[ ] Quest outcomes: XP rewards, karma, unique items` → note: use existing `rewards` + `karma` + `set_flags`
- `[ ] Multi-map quests` → done (flags persist across maps via GameState)
- `[ ] Event chains can reference and advance quests` → done (set_flags advances quest steps)

Keep as TODO:
- `[ ] First-visit event hook for towns` — still needs `visited_locations` tracking
- `[ ] Multi-function locations tab UI` — still needs tab switching in event_display

- [ ] **Commit**

```
git add TODO.md
git commit -m "docs: update TODO — event chains and quest system complete"
```

---

## Data Format Reference

### Outcome fields added by this plan

```json
{
  "type": "text",
  "text": "The pilgrim nods gravely.",
  "set_flags": {
    "pilgrim_met": true,
    "caravan_state": "rescued"
  },
  "register_quest": {
    "id": "free_the_pilgrim",
    "name": "Break the Chains",
    "description": "A bound soul asked for your help.",
    "steps": [
      { "text": "Find the chains in the fortress", "done_when": { "flag": "chains_found", "value": true } },
      { "text": "Return to the pilgrim",            "done_when": { "flag": "pilgrim_freed", "value": true } }
    ]
  },
  "follow_up_event": "pilgrim_thanks_you"
}
```

### Prerequisite on a choice

```json
{
  "id": "ask_about_chains",
  "type": "requirement",
  "prerequisite": { "flag": "pilgrim_met", "value": true },
  "text": "Return the chains",
  "outcome": {
    "type": "text",
    "text": "The pilgrim weeps with relief.",
    "set_flags": { "pilgrim_freed": true },
    "rewards": { "xp": 100 },
    "karma": { "god": 10, "human": 5 }
  }
}
```

### Notes
- `set_flags` can appear on any outcome type including `"combat"` and `"shop"` — flags are written before the combat/shop transition.
- `follow_up_event` is ignored on `"combat"` and `"shop"` outcomes (those trigger scene changes; the follow-up flow only works for `"text"` and `"recruit_companion"` outcomes).
- Flags are strings only — use `"flag_name": true` for boolean gates, `"flag_name": "value"` for state machines.
- Quest step `done_when.value` defaults to `true` if omitted.
