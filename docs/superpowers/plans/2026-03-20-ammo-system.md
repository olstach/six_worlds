# Ammo System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tiered ammo system for bows and crossbows: bone arrows/bolts are free/infinite default, better tiers are finite and bought/crafted, special arrows (fire, venom, frost, silencing) add tactical consumable options; all selectable via a new Ammo panel in combat.

**Architecture:** Ammo types defined in a new `ammo.json` data file. Ammo items live in the party-wide `ItemSystem._inventory` (same as all other items) so shops and loot work without special-casing. A `selected_ammo_id` state var on `CombatUnit` tracks the active choice; bonuses flow into existing `get_attack_damage()` / `get_accuracy()` getters; consumption happens via `ItemSystem.remove_from_inventory()` after each ranged attack; special effects (fire arrow AoE, status procs) are handled in `combat_manager.gd` after hit resolution using `apply_damage()`. The combat HUD gets a new `AmmoButton` + `AmmoPanel` modelled exactly on the existing `SpellButton` + `SpellPanel`.

**Tech Stack:** GDScript 4 / Godot 4.3, JSON data files, no automated test runner — all verification is in-engine via test scene launch.

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `resources/data/ammo.json` | **Create** | All ammo type definitions: tiers, bonuses, special effects |
| `scripts/autoload/item_system.gd` | **Modify** | Load ammo.json; `get_ammo()`, `get_available_ammo()`, `consume_ammo()` |
| `scripts/combat/combat_unit.gd` | **Modify** | `selected_ammo_id` state var; ammo bonus in `get_attack_damage()` / `get_accuracy()` |
| `scripts/autoload/combat_manager.gd` | **Modify** | Consume ammo per ranged attack; `_process_ammo_special_effect()` for AoE/status |
| `scenes/combat/combat_arena.tscn` | **Modify** | Add `AmmoButton` to ActionPanel; add `AmmoPanel` (PanelContainer) with scroll list |
| `scripts/combat/combat_arena.gd` | **Modify** | Ammo panel open/populate/select logic; button enable/disable; hide in cancel/skills |

---

## Task 1: ammo.json — Define All Ammo Types

**Files:**
- Create: `resources/data/ammo.json`

### Context
Ammo items live in the party-wide `ItemSystem._inventory` (category "ammo"), same as all other items. Each type specifies which weapon types it can be used with (`weapon_types`), flat bonuses, and an optional `special_effect`. `is_default: true` marks the free/infinite fallback (bone arrow / bone bolt) — these never appear in inventory; they are always available implicitly. Special effects use the same status names as `spells.json` (e.g. `"Poisoned"`, `"Frozen"`, `"Silenced"`).

- [ ] **Step 1: Create `resources/data/ammo.json`**

```json
{
  "_comment": "Ammo types for bows and crossbows. is_default ammo is free/infinite and never stored in inventory.",

  "ammo": {
    "bone_arrow": {
      "name": "Bone Arrow", "weapon_types": ["bow"],
      "tier": 1, "damage_bonus": 0, "accuracy_bonus": 0, "value": 0,
      "is_default": true, "stack_size": 999,
      "description": "Crude but freely available. Always replenished between fights."
    },
    "bronze_arrow": {
      "name": "Bronze Arrow", "weapon_types": ["bow"],
      "tier": 3, "damage_bonus": 1, "accuracy_bonus": 2, "value": 3, "stack_size": 40
    },
    "iron_arrow": {
      "name": "Iron Arrow", "weapon_types": ["bow"],
      "tier": 4, "damage_bonus": 2, "accuracy_bonus": 3, "value": 5, "stack_size": 40
    },
    "steel_arrow": {
      "name": "Steel Arrow", "weapon_types": ["bow"],
      "tier": 5, "damage_bonus": 3, "accuracy_bonus": 4, "value": 8, "stack_size": 30
    },
    "damascene_arrow": {
      "name": "Damascene Arrow", "weapon_types": ["bow"],
      "tier": 6, "damage_bonus": 5, "accuracy_bonus": 5, "value": 20, "stack_size": 20
    },
    "sky_iron_arrow": {
      "name": "Sky-iron Arrow", "weapon_types": ["bow"],
      "tier": 7, "damage_bonus": 7, "accuracy_bonus": 6, "value": 60, "stack_size": 10
    },

    "bone_bolt": {
      "name": "Bone Bolt", "weapon_types": ["crossbow"],
      "tier": 1, "damage_bonus": 0, "accuracy_bonus": 0, "value": 0,
      "is_default": true, "stack_size": 999,
      "description": "Crude but freely available. Always replenished between fights."
    },
    "bronze_bolt": {
      "name": "Bronze Bolt", "weapon_types": ["crossbow"],
      "tier": 3, "damage_bonus": 1, "accuracy_bonus": 2, "value": 3, "stack_size": 40
    },
    "iron_bolt": {
      "name": "Iron Bolt", "weapon_types": ["crossbow"],
      "tier": 4, "damage_bonus": 2, "accuracy_bonus": 3, "value": 5, "stack_size": 40
    },
    "steel_bolt": {
      "name": "Steel Bolt", "weapon_types": ["crossbow"],
      "tier": 5, "damage_bonus": 3, "accuracy_bonus": 4, "value": 8, "stack_size": 30
    },

    "fire_arrow": {
      "name": "Fire Arrow", "weapon_types": ["bow", "crossbow"],
      "tier": 3, "damage_bonus": 2, "accuracy_bonus": 0, "value": 15, "stack_size": 10,
      "special_effect": {"type": "aoe_fire", "damage": 12, "radius": 1, "element": "fire"},
      "description": "Explodes on impact, dealing fire damage to all nearby units."
    },
    "venom_arrow": {
      "name": "Venom Arrow", "weapon_types": ["bow", "crossbow"],
      "tier": 3, "damage_bonus": 0, "accuracy_bonus": 0, "value": 10, "stack_size": 10,
      "special_effect": {"type": "status", "status": "Poisoned", "duration": 3, "chance": 100},
      "description": "Coated in fast-acting poison."
    },
    "frost_arrow": {
      "name": "Frost Arrow", "weapon_types": ["bow", "crossbow"],
      "tier": 4, "damage_bonus": 1, "accuracy_bonus": 0, "value": 12, "stack_size": 10,
      "special_effect": {"type": "status", "status": "Frozen", "duration": 1, "chance": 75},
      "description": "Chills the target, potentially freezing them solid."
    },
    "silencing_arrow": {
      "name": "Silencing Arrow", "weapon_types": ["bow", "crossbow"],
      "tier": 4, "damage_bonus": 0, "accuracy_bonus": 3, "value": 12, "stack_size": 10,
      "special_effect": {"type": "status", "status": "Silenced", "duration": 2, "chance": 80},
      "description": "Disrupts spellcasting concentration on impact."
    }
  }
}
```

- [ ] **Step 2: Verify JSON is valid**

```bash
python3 -m json.tool resources/data/ammo.json > /dev/null && echo "OK"
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add resources/data/ammo.json
git commit -m "data: add ammo.json with tiered arrows/bolts and special ammo types"
```

---

## Task 2: ItemSystem — Load Ammo Data + Public API

**Files:**
- Modify: `scripts/autoload/item_system.gd`

### Context
`item_system.gd` maintains a **party-wide** `_inventory: Array[Dictionary]` (line 28) — there is no per-character inventory. The existing `add_to_inventory(item_id, qty)`, `remove_from_inventory(item_id, qty)`, and `get_inventory_count(item_id)` functions handle all inventory mutations. The new ammo API wraps these.

`get_available_ammo(weapon_type)` returns what the player can choose from: the default (always present, not in inventory) + any ammo items in `_inventory` that match the weapon type.

`consume_ammo(ammo_id)` uses `remove_from_inventory()` for finite ammo. Default (`is_default: true`) ammo is never consumed.

**Important GDScript 4 note:** `Dictionary.merge()` modifies in place and returns `void` — never use it in a return statement. To add a key to a dict copy, use `duplicate()` then assign the key.

- [ ] **Step 1: Add `ammo_types` var**

Find the var declarations at the top of `item_system.gd` (near line 28 `var _inventory`). Add:

```gdscript
var ammo_types: Dictionary = {}  # ammo_id -> ammo definition from ammo.json
```

- [ ] **Step 2: Call `_load_ammo()` from `_ready()`**

In `_ready()`, after the last existing `_load_*` call, add:

```gdscript
_load_ammo()
```

- [ ] **Step 3: Add `_load_ammo()` function**

Add this after the last existing `_load_*` helper in `item_system.gd`:

```gdscript
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
```

- [ ] **Step 4: Add `get_ammo()`, `get_available_ammo()`, and `consume_ammo()` functions**

Add these in the public API section of `item_system.gd`:

```gdscript
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
```

- [ ] **Step 5: Open Godot, run test scene, check Output panel**

Expected: `ItemSystem: Loaded 14 ammo types` (count may vary based on ammo.json entries). No parse errors.

- [ ] **Step 6: Commit**

```bash
git add scripts/autoload/item_system.gd
git commit -m "feat: ItemSystem loads ammo.json; add get_ammo, get_available_ammo, consume_ammo"
```

---

## Task 3: CombatUnit — selected_ammo State + Damage/Accuracy Bonuses

**Files:**
- Modify: `scripts/combat/combat_unit.gd`

### Context
`CombatUnit` holds per-turn state vars starting at line 20. Add `selected_ammo_id: String = ""` — empty string means "use default". Bonuses are injected at the end of `get_attack_damage()` (line 626) and inside `get_accuracy()` (line 609), only when the unit has a ranged weapon. These are small flat values added to the existing totals.

`selected_ammo_id` is NOT reset at turn start — the player selects it once and it persists until changed or depleted.

- [ ] **Step 1: Add `selected_ammo_id` state var**

After line 39 (`var ranged_attacks_this_turn: int = 0`), add:

```gdscript
var selected_ammo_id: String = ""  # Which ammo is loaded; "" = default (bone arrow/bolt)
```

- [ ] **Step 2: Add `get_selected_ammo()` helper**

Add after `get_accuracy()` (around line 612):

```gdscript
## Return the current ammo definition dict (includes id, bonuses, special_effect).
## Returns the matching default ammo when nothing is explicitly selected.
func get_selected_ammo() -> Dictionary:
	if not is_ranged_weapon():
		return {}
	if selected_ammo_id != "" and ItemSystem:
		var ammo = ItemSystem.get_ammo(selected_ammo_id)
		if not ammo.is_empty():
			var entry = ammo.duplicate()
			entry["id"] = selected_ammo_id
			return entry
	# Fall back to the default ammo for this weapon type
	var weapon_type = get_equipped_weapon().get("type", "bow")
	if ItemSystem:
		for ammo_id in ItemSystem.ammo_types:
			var ammo = ItemSystem.ammo_types[ammo_id]
			if ammo.get("is_default", false) and weapon_type in ammo.get("weapon_types", []):
				var entry = ammo.duplicate()
				entry["id"] = ammo_id
				return entry
	return {}
```

- [ ] **Step 3: Add ammo damage bonus to `get_attack_damage()`**

In `get_attack_damage()` (line 626), find the last two lines before `return base_damage`:

```gdscript
	# Add mantra stat bonuses (e.g. Jeweled Pagoda per-turn summon damage)
	base_damage += mantra_stat_bonuses.get("damage", 0)

	return base_damage
```

Replace with:

```gdscript
	# Add mantra stat bonuses (e.g. Jeweled Pagoda per-turn summon damage)
	base_damage += mantra_stat_bonuses.get("damage", 0)

	# Add ammo damage bonus for ranged weapons
	if is_ranged_weapon():
		base_damage += get_selected_ammo().get("damage_bonus", 0)

	return base_damage
```

- [ ] **Step 4: Add ammo accuracy bonus to `get_accuracy()`**

`get_accuracy()` is currently lines 609-612:

```gdscript
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	var weapon_acc = get_equipped_weapon().get("stats", {}).get("accuracy", 0)
	return derived.get("accuracy", 0) + weapon_acc + _get_status_stat_bonus("accuracy") + mantra_stat_bonuses.get("accuracy", 0) + _get_stat_modifier_bonus("accuracy")
```

Replace with:

```gdscript
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	var weapon_acc = get_equipped_weapon().get("stats", {}).get("accuracy", 0)
	var ammo_acc = get_selected_ammo().get("accuracy_bonus", 0) if is_ranged_weapon() else 0
	return derived.get("accuracy", 0) + weapon_acc + ammo_acc + _get_status_stat_bonus("accuracy") + mantra_stat_bonuses.get("accuracy", 0) + _get_stat_modifier_bonus("accuracy")
```

- [ ] **Step 5: Open Godot, start a combat, give a bow character some iron arrows**

In the test scene's `_ready()` add temporarily:
```gdscript
ItemSystem.add_to_inventory("iron_arrow", 10)
```

Start combat with the bow character. Open the Godot Remote Scene tree, select the CombatUnit node, set `selected_ammo_id` to `"iron_arrow"`. Verify attack damage is 2 higher and accuracy 3 higher than without (check combat log). Remove the test line afterwards.

- [ ] **Step 6: Commit**

```bash
git add scripts/combat/combat_unit.gd
git commit -m "feat: CombatUnit selected_ammo_id; ammo bonuses flow into damage and accuracy"
```

---

## Task 4: CombatManager — Ammo Consumption + Special Effects

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

### Context

**Ammo consumption** happens per shot regardless of hit/miss (the arrow is fired either way). Insert after line 1322 where `ranged_attacks_this_turn` is incremented.

**Special effects** (fire arrow AoE, status procs) only trigger on hit. Insert inside the `if result.hit:` block, after `_process_weapon_on_hit_procs()` (line 1306). Use `apply_damage(unit, damage, element)` for the AoE — this function (line 1664) handles `take_damage()`, `unit_damaged` signal, bleed-out, and mantra interruption correctly.

- [ ] **Step 1: Add ammo consumption after the ranged counter increment**

Find lines 1321-1322:

```gdscript
	if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
		attacker.ranged_attacks_this_turn += 1
```

Replace with:

```gdscript
	if attacker.has_method("is_ranged_weapon") and attacker.is_ranged_weapon():
		attacker.ranged_attacks_this_turn += 1
		# Consume one ammo from party inventory; revert to default if depleted
		if "selected_ammo_id" in attacker and attacker.selected_ammo_id != "":
			var still_has_ammo = ItemSystem.consume_ammo(attacker.selected_ammo_id)
			if not still_has_ammo:
				var ammo_name = ItemSystem.get_ammo(attacker.selected_ammo_id).get("name", attacker.selected_ammo_id)
				combat_log.emit("%s's %s ran out — falling back to bone arrows." % [attacker.unit_name, ammo_name])
				attacker.selected_ammo_id = ""
```

- [ ] **Step 2: Add special effect call inside the hit block**

Find lines 1303-1308 (inside `if result.hit:`):

```gdscript
		# --- Passive perk on-hit effects ---
		_process_on_hit_perks(attacker, defender, result)
		# --- Weapon passive on-hit procs ---
		_process_weapon_on_hit_procs(attacker, defender, result)
		# --- Weapon durability ---
		_deduct_weapon_durability(attacker)
```

Replace with:

```gdscript
		# --- Passive perk on-hit effects ---
		_process_on_hit_perks(attacker, defender, result)
		# --- Weapon passive on-hit procs ---
		_process_weapon_on_hit_procs(attacker, defender, result)
		# --- Ammo special effects (fire arrow AoE, status procs) ---
		if "get_selected_ammo" in attacker:
			var ammo = attacker.get_selected_ammo()
			if ammo.has("special_effect"):
				_process_ammo_special_effect(attacker, defender, ammo)
		# --- Weapon durability ---
		_deduct_weapon_durability(attacker)
```

- [ ] **Step 3: Add `_process_ammo_special_effect()` function**

Add this near `_process_weapon_on_hit_procs()` (around line 5561):

```gdscript
## Process special effects from ammo: fire arrow AoE or status proc arrows.
## Called on hit only — a missed shot produces no explosion or status.
## apply_damage() is used for AoE hits (handles death, bleed-out, mantra interruption).
func _process_ammo_special_effect(attacker: Node, defender: Node, ammo: Dictionary) -> void:
	var effect = ammo.get("special_effect", {})
	match effect.get("type", ""):

		"aoe_fire":
			var radius = effect.get("radius", 1)
			var aoe_damage = effect.get("damage", 10)
			var element = effect.get("element", "fire")
			combat_log.emit("%s's %s explodes!" % [attacker.unit_name, ammo.get("name", "arrow")])
			for unit in all_units:
				if not unit.is_alive():
					continue
				var dist = abs(unit.grid_position.x - defender.grid_position.x) \
						 + abs(unit.grid_position.y - defender.grid_position.y)
				if dist <= radius:
					var resistance = unit.get_resistance(element) if unit.has_method("get_resistance") else 0.0
					var final_dmg = maxi(1, int(aoe_damage * (1.0 - resistance / 100.0)))
					apply_damage(unit, final_dmg, element)
					combat_log.emit("%s takes %d %s damage from the explosion." % [unit.unit_name, final_dmg, element])

		"status":
			var chance = effect.get("chance", 100)
			if randi() % 100 < chance:
				var status = effect.get("status", "")
				var duration = effect.get("duration", 2)
				if status != "":
					_apply_status_effect(defender, status, duration)
					combat_log.emit("%s is afflicted with %s from the arrow." % [defender.unit_name, status])
```

- [ ] **Step 4: Open Godot, test fire arrow**

Add temporarily to test scene `_ready()`:
```gdscript
ItemSystem.add_to_inventory("fire_arrow", 5)
```

In combat: select fire arrow via Remote Scene > CombatUnit > `selected_ammo_id = "fire_arrow"`. Fire at an enemy with allies nearby. Confirm:
- Output: "X's Fire Arrow explodes!"
- Adjacent units take fire damage (including player units if in radius)
- Inventory count ticks down (check `ItemSystem._inventory` in Remote)
- At 0: "falling back to bone arrows" in combat log

Test venom arrow: `selected_ammo_id = "venom_arrow"`. Fire. Target should get Poisoned status. Remove test lines after.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/combat_manager.gd
git commit -m "feat: ranged attacks consume ammo; fire arrow AoE and status arrows trigger on hit"
```

---

## Task 5: Combat UI — AmmoButton, AmmoPanel, and Arena Logic

**Files:**
- Modify: `scenes/combat/combat_arena.tscn`
- Modify: `scripts/combat/combat_arena.gd`

### Context

Existing panel pattern to follow exactly:
- `spell_panel: PanelContainer = %SpellPanel` (line 24) — all panels are `PanelContainer`, not `Panel`
- `spell_list: VBoxContainer = %SpellList` (line 25)
- `_cancel_action_mode()` at line 654 hides all panels (lines 662-664) — ammo panel must be added here
- `_show_skills_panel()` at line 1305 hides `spell_panel` and `item_panel` at lines 1377-1378 — add `ammo_panel.hide()` there too
- Ammo selection does NOT need a new `ActionMode` — it's a panel action with no grid targeting

**About `_cancel_action_mode()`:** This is called whenever the player clicks a grid tile, presses Escape, or starts any new action. It must hide `ammo_panel` so the panel doesn't stay open when the player moves or attacks.

Open `scenes/combat/combat_arena.tscn` in Godot's editor, then:

- [ ] **Step 1: Add AmmoButton to ActionPanel**

In the Scene panel, find `ActionPanel > GridContainer`. Right-click the container → Add Child Node → `Button`. Set:
- **Name:** `AmmoButton`
- **Text:** `Ammo`
- **Unique Name In Owner:** ✓ (right-click the node → "Access as Unique Name")

Position it after `SpellButton` in the grid (drag if needed to order it correctly).

- [ ] **Step 2: Add AmmoPanel as sibling to SpellPanel**

In the Scene panel, right-click the same parent that contains `SpellPanel` → Add Child Node → **`PanelContainer`** (not `Panel`). Set:
- **Name:** `AmmoPanel`
- **Visible:** false (uncheck in Inspector)
- Copy `SpellPanel`'s layout/anchor settings (Anchor Preset: Top Right, or match exactly)

Inside `AmmoPanel`, add this child structure (matching SpellPanel's structure):
```
AmmoPanel (PanelContainer)
  VBoxContainer
    AmmoLabel (Label)       — text: "Select Ammo"
    ScrollContainer
      AmmoList (VBoxContainer)
```

Set **Unique Name In Owner** on `AmmoPanel` and `AmmoList` (right-click each → "Access as Unique Name").

- [ ] **Step 3: Add `@onready` vars to `combat_arena.gd`**

In `combat_arena.gd`, find the `@onready` block at lines 22-32:
```gdscript
@onready var spell_button: Button = %SpellButton
...
@onready var skills_panel: PanelContainer = %SkillsPanel
@onready var skills_list: VBoxContainer = %SkillsList
```

Add after line 32:
```gdscript
@onready var ammo_button: Button = %AmmoButton
@onready var ammo_panel: PanelContainer = %AmmoPanel
@onready var ammo_list: VBoxContainer = %AmmoList
```

- [ ] **Step 4: Connect AmmoButton.pressed in `_ready()`**

Find where spell_button and item_button are connected (around line 189):
```gdscript
	spell_button.pressed.connect(_on_spell_pressed)
	item_button.pressed.connect(_on_item_pressed)
```

Add:
```gdscript
	ammo_button.pressed.connect(_on_ammo_pressed)
```

- [ ] **Step 5: Add ammo_button disable logic in `_update_action_buttons()`**

`_update_action_buttons()` is at line 1799. Find the `item_button.disabled` line (1817):
```gdscript
	item_button.disabled = not is_player or not can_act or cc_locked
```

Add immediately after:
```gdscript
	# Ammo button: only useful when a ranged weapon is equipped
	var has_ranged = current_unit != null and current_unit.has_method("is_ranged_weapon") and current_unit.is_ranged_weapon()
	ammo_button.disabled = not is_player or not can_act or cc_locked or not has_ranged
```

- [ ] **Step 6: Add `ammo_panel.hide()` to `_cancel_action_mode()`**

`_cancel_action_mode()` is at line 654. Find lines 662-664:
```gdscript
	spell_panel.hide()
	item_panel.hide()
	skills_panel.hide()
```

Replace with:
```gdscript
	spell_panel.hide()
	item_panel.hide()
	skills_panel.hide()
	ammo_panel.hide()
```

- [ ] **Step 7: Add `ammo_panel.hide()` to `_show_skills_panel()`**

`_show_skills_panel()` is at line 1305. Find lines 1377-1379:
```gdscript
	# Hide other panels, show skills
	spell_panel.hide()
	item_panel.hide()
	skills_panel.show()
```

Replace with:
```gdscript
	# Hide other panels, show skills
	spell_panel.hide()
	item_panel.hide()
	ammo_panel.hide()
	skills_panel.show()
```

- [ ] **Step 8: Add `_on_ammo_pressed()`, `_show_ammo_panel()`, and `_on_ammo_selected()`**

Add these after `_on_spell_pressed()` (around line 730):

```gdscript
func _on_ammo_pressed() -> void:
	if not CombatManager.is_player_turn():
		return
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return
	AudioManager.play("ui_click")
	if ammo_panel.visible:
		ammo_panel.hide()
	else:
		spell_panel.hide()
		item_panel.hide()
		skills_panel.hide()
		_show_ammo_panel(unit)


func _show_ammo_panel(unit: CombatUnit) -> void:
	for child in ammo_list.get_children():
		child.queue_free()

	if not unit.is_ranged_weapon():
		ammo_panel.hide()
		return

	var weapon_type = unit.get_equipped_weapon().get("type", "bow")
	var available = ItemSystem.get_available_ammo(weapon_type)

	if available.is_empty():
		var label = Label.new()
		label.text = "No ammo available"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		ammo_list.add_child(label)
	else:
		for ammo in available:
			var ammo_id = ammo.get("id", "")
			var is_default = ammo.get("is_default", false)
			var is_selected = (unit.selected_ammo_id == ammo_id or
								(unit.selected_ammo_id == "" and is_default))

			var btn = Button.new()
			if is_default:
				btn.text = "%s (∞)" % ammo.get("name", "Bone Arrow")
			else:
				btn.text = "%s (x%d)" % [ammo.get("name", "Arrow"), ammo.get("quantity", 0)]
				if ammo.get("quantity", 0) <= 0:
					btn.disabled = true

			# Gold tint = currently selected ammo
			if is_selected:
				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

			# Build tooltip
			var tip_lines: Array[String] = [ammo.get("name", "Arrow")]
			var dmg_bonus = ammo.get("damage_bonus", 0)
			var acc_bonus = ammo.get("accuracy_bonus", 0)
			if dmg_bonus != 0:
				tip_lines.append("+%d Damage" % dmg_bonus)
			if acc_bonus != 0:
				tip_lines.append("+%d Accuracy" % acc_bonus)
			var fx = ammo.get("special_effect", {})
			if not fx.is_empty():
				match fx.get("type", ""):
					"aoe_fire":
						tip_lines.append("On hit: AoE fire blast (radius %d, %d dmg)" % [
							fx.get("radius", 1), fx.get("damage", 0)])
					"status":
						tip_lines.append("On hit: %d%% chance to inflict %s for %d turns" % [
							fx.get("chance", 100), fx.get("status", ""), fx.get("duration", 1)])
			var desc = ammo.get("description", "")
			if not desc.is_empty():
				tip_lines.append("")
				tip_lines.append(desc)
			btn.tooltip_text = "\n".join(tip_lines)

			btn.pressed.connect(_on_ammo_selected.bind(ammo_id))
			ammo_list.add_child(btn)

	ammo_panel.show()


func _on_ammo_selected(ammo_id: String) -> void:
	var unit = CombatManager.get_current_unit()
	if unit == null:
		return
	var ammo = ItemSystem.get_ammo(ammo_id)
	if ammo.get("is_default", false):
		unit.selected_ammo_id = ""
		_log_message("Using default ammo (%s)." % ammo.get("name", "Bone Arrow"))
	else:
		unit.selected_ammo_id = ammo_id
		_log_message("Loaded %s." % ammo.get("name", ammo_id))
	ammo_panel.hide()
```

- [ ] **Step 9: Open Godot, full UI test**

Start a combat with a bow character and a melee character. Confirm:
1. Ammo button visible for both; disabled for melee unit, enabled for bow unit
2. Clicking Ammo opens panel; bone arrows shown as `(∞)` with gold highlight (default selected)
3. Add iron arrows via `ItemSystem.add_to_inventory("iron_arrow", 10)` in debugger → reopen panel → shows `Iron Arrow (x10)`
4. Select iron arrows → panel closes → "Loaded Iron Arrow." in combat log
5. Reopen panel → iron arrows now gold-highlighted
6. Click Spell or Skills button → ammo panel closes
7. Click a grid tile (no action) → ammo panel closes
8. Arrow count ticks down each attack; at 0 → "falling back to bone arrows" in log → panel shows bone as selected

- [ ] **Step 10: Commit**

```bash
git add scenes/combat/combat_arena.tscn scripts/combat/combat_arena.gd
git commit -m "feat: Ammo panel in combat HUD — select tiered and special ammo for ranged attacks"
```

---

## Final Verification Checklist

Before calling this feature complete, run a full combat with these scenarios:

- [ ] Bow character, no special ammo: Ammo button functional, panel shows bone `(∞)`, attacks work unchanged (no regression)
- [ ] Iron arrows equipped: +2 damage, +3 accuracy vs bone (visible in hit numbers and combat log)
- [ ] Fire arrows: Explosion triggers on hit, deals fire damage to all units within radius 1 of target (including allies — friendly fire)
- [ ] Frost arrows: ~75% of hits freeze the target (run 5-10 attacks to verify it's not 100% and not 0%)
- [ ] Venom arrows: Target gets Poisoned on every hit (100% chance)
- [ ] Ammo depletion: quantity ticks down correctly, hits 0, combat log shows fallback message, subsequent attacks use bone arrows
- [ ] Crossbow character: Panel shows bone bolt (not bone arrow)
- [ ] Melee character: Ammo button is disabled at all times
- [ ] No errors in Godot Output panel throughout all tests

---

## Out of Scope (Future Work)

- Overworld Smithing replenishment of finite ammo (`supplies.json` already has hooks for this)
- Companion `generate_weapon()` calls without realm (separate fix)
- Thrown weapon ammo (javelins/throwing knives have their own item-ammo tracking)
- Crafting ammo via Alchemy
- Shops selling ammo bundles (add ammo item IDs to shop `available_items` pools after this lands)
