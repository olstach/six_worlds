# Companions Recruitment Tab Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Companions tab to the shop UI so named companions can be recruited at taverns and similar locations.

**Architecture:** Three-task plan — data changes, scene change, then script logic. The tab slots into the existing TabContainer; `_setup_tabs()` is extended to show the Companions tab whenever a shop has `available_companions`. All recruitment logic delegates to `CompanionSystem.recruit()` which already handles gold, party, and the popup.

**Tech Stack:** GDScript, Godot 4.3, JSON data files. No new autoloads or scenes needed. Testing is manual via F5 (test launcher scene).

**Design doc:** `docs/plans/2026-03-01-companions-recruitment-tab-design.md`

---

## Task 1: Data changes

**Files:**
- Modify: `resources/data/companions.json`
- Modify: `resources/data/shops.json`

### Step 1: Raise Karnak's recruitment cost

In `companions.json`, find:
```json
"recruitment_cost": 150,
```
Change to:
```json
"recruitment_cost": 750,
```

### Step 2: Add a test tavern to shops.json

In `shops.json`, add after the last shop entry (before `"shop_types"`):

```json
"hell_tavern": {
    "name": "Devil's Rest",
    "type": "general",
    "description": "A dim roadhouse where the desperate gather. Someone at the bar looks like they're between allegiances.",
    "price_modifier": 1.0,
    "buys_items": false,
    "available_companions": ["karnak"],
    "items": {},
    "spells": [],
    "training": {
        "attributes": [],
        "skills": []
    }
},
```

Also remove the `_todo_companions` field from `hell_merchant` (it was a placeholder):
```json
"_todo_companions": "Add available_companions array for companion recruitment tab",
```

### Step 3: Commit

```bash
git add resources/data/companions.json resources/data/shops.json
git commit -m "feat: raise Karnak recruitment cost to 750, add hell_tavern shop"
```

---

## Task 2: Add Companions tab to shop_ui.tscn

**Files:**
- Modify: `scenes/ui/shop_ui.tscn`

The TabContainer children become tabs automatically — tab title = node name. Currently there are three: Items, Spells, Training. Add Companions as a fourth, matching the exact structure of the Training tab.

### Step 1: Add the tab nodes

In `shop_ui.tscn`, find the last line of the Training tab (the TrainingContainer node):
```
[node name="TrainingContainer" type="VBoxContainer" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer/Training/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 8
```

After it, add:
```
[node name="Companions" type="Control" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer"]
visible = false
layout_mode = 2

[node name="ScrollContainer" type="ScrollContainer" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer/Companions"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="CompanionsContainer" type="VBoxContainer" parent="ShopPanel/MarginContainer/VBoxContainer/TabContainer/Companions/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 12
```

### Step 2: Verify in Godot

Open the scene in Godot editor. The shop UI should have four tabs: Items, Spells, Training, Companions. Companions starts hidden (visible = false). No errors in the scene.

### Step 3: Commit

```bash
git add scenes/ui/shop_ui.tscn
git commit -m "feat: add Companions tab node to shop_ui.tscn"
```

---

## Task 3: Companions tab logic in shop_ui.gd

**Files:**
- Modify: `scripts/ui/shop_ui.gd`

### Step 1: Add @onready for companions_container

In `shop_ui.gd`, after the existing `@onready var training_container` line:
```gdscript
@onready var training_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Training/ScrollContainer/TrainingContainer
```

Add:
```gdscript
@onready var companions_container: VBoxContainer = $ShopPanel/MarginContainer/VBoxContainer/TabContainer/Companions/ScrollContainer/CompanionsContainer
```

### Step 2: Update _setup_tabs() to show Companions when available

Find `_setup_tabs()`:
```gdscript
func _setup_tabs() -> void:
	var shop_type = current_shop.get("type", "general")
	var type_info = ShopSystem._shop_types.get(shop_type, {})
	var tabs = type_info.get("tabs", ["items"])

	# Show/hide tabs based on shop type
	for i in range(tab_container.get_tab_count()):
		var tab_name = tab_container.get_tab_title(i).to_lower()
		tab_container.set_tab_hidden(i, tab_name not in tabs)
```

Replace with:
```gdscript
func _setup_tabs() -> void:
	var shop_type = current_shop.get("type", "general")
	var type_info = ShopSystem._shop_types.get(shop_type, {})
	var tabs: Array = type_info.get("tabs", ["items"]).duplicate()

	# Always show companions tab if the shop has available companions
	if not current_shop.get("available_companions", []).is_empty():
		if not "companions" in tabs:
			tabs.append("companions")

	# Show/hide tabs based on resolved list
	for i in range(tab_container.get_tab_count()):
		var tab_name = tab_container.get_tab_title(i).to_lower()
		tab_container.set_tab_hidden(i, tab_name not in tabs)

	# Select first visible tab
	for i in range(tab_container.get_tab_count()):
		if not tab_container.is_tab_hidden(i):
			tab_container.current_tab = i
			break
```

### Step 3: Add _populate_companions_tab()

Add this function after `_populate_training_tab()` (before the INVENTORY section comment):

```gdscript
# ============================================
# COMPANIONS TAB
# ============================================

func _populate_companions_tab() -> void:
	for child in companions_container.get_children():
		child.queue_free()

	var available: Array = current_shop.get("available_companions", [])
	if available.is_empty():
		return

	# Build set of companion_ids already in the party
	var party_companion_ids: Array[String] = []
	for member in CharacterSystem.get_party():
		if member.has("companion_id"):
			party_companion_ids.append(member.companion_id)

	var shown := 0
	for companion_id in available:
		if companion_id in party_companion_ids:
			continue  # Already recruited — hide them (they're unique people)
		var def: Dictionary = CompanionSystem.get_definition(companion_id)
		if def.is_empty():
			push_warning("shop_ui: unknown companion id in shop: %s" % companion_id)
			continue
		_create_companion_panel(companion_id, def)
		shown += 1

	if shown == 0:
		var empty_label = Label.new()
		empty_label.text = "No companions available"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		companions_container.add_child(empty_label)


func _create_companion_panel(companion_id: String, def: Dictionary) -> void:
	var cost: int = def.get("recruitment_cost", 0)
	var can_afford: bool = GameState.can_afford(cost)
	var party_full: bool = CharacterSystem.get_party().size() >= CharacterSystem.max_party_size

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 140)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.3, 0.55, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Name row: name left, cost right
	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var name_label = Label.new()
	name_label.text = def.get("name", companion_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	name_row.add_child(name_label)

	var cost_label = Label.new()
	cost_label.text = "%d gold" % cost
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color",
		GOLD_COLOR if can_afford else UNAFFORDABLE_COLOR)
	name_row.add_child(cost_label)

	# Race · Background identity line
	var race_name: String = def.get("race", "").replace("_", " ").capitalize()
	var bg_name: String = def.get("background", "").replace("_", " ").capitalize()
	var identity_label = Label.new()
	identity_label.text = "%s · %s" % [race_name, bg_name]
	identity_label.add_theme_font_size_override("font_size", 12)
	identity_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(identity_label)

	vbox.add_child(HSeparator.new())

	# Flavor text
	var flavor_label = Label.new()
	flavor_label.text = def.get("flavor_text", "")
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.add_theme_font_size_override("font_size", 12)
	flavor_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
	vbox.add_child(flavor_label)

	# Recruit button, right-aligned
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var recruit_btn = Button.new()
	recruit_btn.text = "Party Full" if party_full else "Recruit"
	recruit_btn.add_theme_font_size_override("font_size", 13)
	recruit_btn.disabled = not can_afford or party_full
	recruit_btn.pressed.connect(func(): _on_recruit_companion_pressed(companion_id))
	btn_row.add_child(recruit_btn)

	companions_container.add_child(panel)
```

### Step 4: Add the event handler

After `_on_training_purchased`, add:

```gdscript
func _on_recruit_companion_pressed(companion_id: String) -> void:
	var result: Dictionary = CompanionSystem.recruit(companion_id)
	if not result.is_empty():
		_refresh_display()
```

### Step 5: Call _populate_companions_tab() from open_shop() and _refresh_display()

In `open_shop()`, find the block that calls all four populate functions:
```gdscript
	# Populate content
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_inventory()
```

Add `_populate_companions_tab()`:
```gdscript
	# Populate content
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_companions_tab()
	_populate_inventory()
```

In `_refresh_display()`:
```gdscript
func _refresh_display() -> void:
	_update_gold_display()
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_inventory()
```

Add `_populate_companions_tab()`:
```gdscript
func _refresh_display() -> void:
	_update_gold_display()
	_populate_items_tab()
	_populate_spells_tab()
	_populate_training_tab()
	_populate_companions_tab()
	_populate_inventory()
```

### Step 6: Test manually

Trigger the `hell_tavern` shop from the test launcher or overworld. Verify:
- Companions tab appears (Items tab is hidden since `hell_tavern` has no items and type="general" only shows items tab, but companions override should show)

Wait — `hell_tavern` has `"type": "general"` which means `tabs = ["items"]`. But the Items tab will be empty (no items defined). The `_setup_tabs()` fix adds "companions" to the list, so Items + Companions tabs both show. That's fine.

Actually, since `hell_tavern` has `"items": {}` (empty), the Items tab will show "No items for sale". That's acceptable for a tavern — it can always be refined later. Alternatively, hide the Items tab when items is empty, but that's out of scope.

Verify:
1. Shop opens with Companions tab visible
2. Karnak panel shows: name, "Red Devil · Guard", flavor text, "750 gold", Recruit button
3. Recruit button disabled if < 750 gold, enabled if ≥ 750
4. Pressing Recruit: CompanionSystem.recruit() fires, popup appears, tab refreshes, Karnak disappears
5. Re-opening the shop after recruiting: Karnak no longer appears

### Step 7: Commit

```bash
git add scripts/ui/shop_ui.gd scenes/ui/shop_ui.tscn
git commit -m "feat: companions recruitment tab in shop UI"
```
