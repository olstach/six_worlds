# Mantra System Completion — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the mantra system with concentration interrupts, AI chanter-targeting, summon ownership infrastructure, and four deferred Deity Yoga / per-turn effects.

**Architecture:** New fields on CombatUnit track summon ownership and empowered-spawn flags; a `_interrupt_mantras()` helper in CombatManager hooks into damage, CC, and spell-cast paths; four deferred mantra effects are wired into the existing `_apply_mantra_tick` / `_trigger_deity_yoga` match statements. No new scenes or autoloads are needed.

**Tech Stack:** GDScript 4.3, Godot 4.3, JSON data files in `resources/data/`.

---

## Chunk 1: Data + CombatUnit fields

### Task 1: Add five summon templates

**Files:**
- Modify: `resources/data/summon_templates.json`

- [ ] **Step 1: Read the current structure of summon_templates.json**

  Open `resources/data/summon_templates.json`. The file has a root object with a `"templates"` key: `{ "comment": ..., "templates": { ... } }`. You will append five entries **inside the `"templates"` object** — before its closing `}`.

  **⚠ Key collision warning:** The file already contains entries with PascalCase keys: `"Rudra"`, `"Skeleton"`, `"Stone_Guardian"`, `"Zombie"` — these are pre-existing templates with different stats and tags. The new entries use lowercase keys (`"rudra"`, `"skeleton"`, etc.). JSON keys are case-sensitive, so both will coexist. This is intentional: the pre-existing entries are for different content; the new lowercase entries are dedicated to the mantra system. Do not remove or modify the existing PascalCase entries.

- [ ] **Step 2: Add the five templates**

  Add the following entries to the `"templates"` object (comma-separate from the previous last entry):

  ```json
  "spirit_guardian": {
      "display_name": "Spirit Guardian",
      "base_hp": 1, "base_mana": 0, "base_stamina": 0,
      "actions": 0, "base_damage": 0, "damage_type": "physical",
      "base_initiative": 5, "base_movement": 0,
      "base_dodge": 25, "base_armor": 0, "base_crit": 0, "base_accuracy": 80,
      "resistances": {}, "tags": ["guardian_spirit", "construct"]
  },
  "rudra": {
      "display_name": "Rudra",
      "base_hp": 28, "base_mana": 0, "base_stamina": 30,
      "actions": 2, "base_damage": 14, "damage_type": "air",
      "base_initiative": 16, "base_movement": 4,
      "base_dodge": 18, "base_armor": 2, "base_crit": 12, "base_accuracy": 85,
      "resistances": {"air": 30}, "tags": ["air", "spirit", "elemental"]
  },
  "stone_guardian": {
      "display_name": "Guardian King",
      "base_hp": 80, "base_mana": 0, "base_stamina": 50,
      "actions": 2, "base_damage": 15, "damage_type": "crushing",
      "base_initiative": 8, "base_movement": 2,
      "base_dodge": 5, "base_armor": 18, "base_crit": 5, "base_accuracy": 80,
      "resistances": {"earth": 25, "physical": 15}, "tags": ["earth", "construct", "guardian"]
  },
  "zombie": {
      "display_name": "Risen Dead",
      "base_hp": 22, "base_mana": 0, "base_stamina": 20,
      "actions": 1, "base_damage": 8, "damage_type": "physical",
      "base_initiative": 4, "base_movement": 2,
      "base_dodge": 5, "base_armor": 4, "base_crit": 3, "base_accuracy": 70,
      "resistances": {"black": 50, "poison": 50}, "tags": ["black", "undead"]
  },
  "skeleton": {
      "display_name": "Skeleton",
      "base_hp": 18, "base_mana": 0, "base_stamina": 15,
      "actions": 2, "base_damage": 10, "damage_type": "piercing",
      "base_initiative": 8, "base_movement": 3,
      "base_dodge": 10, "base_armor": 6, "base_crit": 5, "base_accuracy": 78,
      "resistances": {"black": 50, "physical": 20}, "tags": ["black", "undead"]
  }
  ```

  **Note on `spirit_guardian`:** `"actions": 0` means this unit never attacks or moves. It has `max_hp: 1` so it dies from a single hit. The `"guardian_spirit"` tag is intentionally distinct from `"spirit"` to avoid colliding with the Unseen Servant summon.

- [ ] **Step 3: Validate JSON**

  Run: `python3 -c "import json; json.load(open('resources/data/summon_templates.json'))" `
  Expected: no output (silent = valid JSON)

- [ ] **Step 4: Commit**

  ```bash
  git add resources/data/summon_templates.json
  git commit -m "feat: add spirit_guardian, rudra, stone_guardian, zombie, skeleton summon templates"
  ```

---

### Task 2: Add four fields to CombatUnit + negative stat floor guards

**Files:**
- Modify: `scripts/combat/combat_unit.gd`

These four fields track summon ownership and Deity Yoga flags used by the new mantra effects.

- [ ] **Step 1: Add the four new fields after `deity_yoga_triggered`**

  In `scripts/combat/combat_unit.gd`, find line 77:
  ```gdscript
  var deity_yoga_triggered: Dictionary = {}
  ```

  Add immediately after it:
  ```gdscript
  # Summon ownership: set to caster.get_instance_id() by _spawn_summoned_unit()
  var summoner_id: int = 0

  # Jeweled Pagoda DY: set on caster; consumed on next _spawn_summoned_unit() call
  var next_summon_empowered: bool = false

  # Set on a summon spawned while caster.next_summon_empowered was true
  # Processed in _process_summon_aura() at start of this unit's turn
  var has_summon_aura: bool = false

  # Set on summons by Lord of Death DY: multiplies their damage by 1.3
  var lord_of_death_empowered: bool = false
  ```

- [ ] **Step 2: Guard `get_dodge()` against negative mantra contributions**

  Find `get_dodge()` at line ~608:
  ```gdscript
  func get_dodge() -> int:
  	var derived = character_data.get("derived", {})
  	return derived.get("dodge", 10) + _get_status_stat_bonus("dodge") + CombatManager.get_passive_perk_stat_bonus(self, "dodge") + mantra_stat_bonuses.get("dodge", 0) + _get_stat_modifier_bonus("dodge")
  ```

  Replace with:
  ```gdscript
  func get_dodge() -> int:
  	var derived = character_data.get("derived", {})
  	var mantra_dodge = mantra_stat_bonuses.get("dodge", 0)
  	return derived.get("dodge", 10) + _get_status_stat_bonus("dodge") + CombatManager.get_passive_perk_stat_bonus(self, "dodge") + maxi(0, mantra_dodge) + _get_stat_modifier_bonus("dodge")
  ```

  Wait — the spec requires that the aura can apply −10 to enemies. Clamping to 0 inside `get_dodge()` means enemies can't go below their base dodge. That is correct: the aura applies a penalty, but the total result should never go negative (you can't dodge worse than 0%). The clamp applies to the `mantra_stat_bonuses` contribution only, not the whole result.

  Actually re-read the spec: "Add `maxi(0, ...)` wrapping to the dodge, armor, and crit_chance getters when they add their `mantra_stat_bonuses` contribution." So clamp the mantra contribution to ≥0. The above replacement is correct.

- [ ] **Step 3: Guard `get_armor()` against negative mantra contributions**

  Find `get_armor()` at line ~670:
  ```gdscript
  func get_armor() -> int:
  	var derived = character_data.get("derived", {})
  	return derived.get("armor", 0) + _get_status_stat_bonus("armor") + CombatManager.get_passive_perk_stat_bonus(self, "armor") + mantra_stat_bonuses.get("armor", 0) + _get_stat_modifier_bonus("armor")
  ```

  Replace with:
  ```gdscript
  func get_armor() -> int:
  	var derived = character_data.get("derived", {})
  	var mantra_armor = mantra_stat_bonuses.get("armor", 0)
  	return derived.get("armor", 0) + _get_status_stat_bonus("armor") + CombatManager.get_passive_perk_stat_bonus(self, "armor") + maxi(0, mantra_armor) + _get_stat_modifier_bonus("armor")
  ```

- [ ] **Step 4: Guard `get_crit_chance()` against negative mantra contributions**

  Find `get_crit_chance()` at line ~676:
  ```gdscript
  func get_crit_chance() -> float:
  	var derived = character_data.get("derived", {})
  	return float(derived.get("crit_chance", 5)) + float(_get_status_stat_bonus("crit_chance")) + float(CombatManager.get_passive_perk_stat_bonus(self, "crit_chance")) + float(mantra_stat_bonuses.get("crit_chance", 0)) + float(_get_stat_modifier_bonus("crit_chance"))
  ```

  Replace with:
  ```gdscript
  func get_crit_chance() -> float:
  	var derived = character_data.get("derived", {})
  	var mantra_crit = float(mantra_stat_bonuses.get("crit_chance", 0))
  	return float(derived.get("crit_chance", 5)) + float(_get_status_stat_bonus("crit_chance")) + float(CombatManager.get_passive_perk_stat_bonus(self, "crit_chance")) + maxf(0.0, mantra_crit) + float(_get_stat_modifier_bonus("crit_chance"))
  ```

- [ ] **Step 5: Verify no parse errors by opening the project in Godot**

  Launch Godot and open the project. Check the Output panel for any GDScript parse errors. Expected: no errors from `combat_unit.gd`.

- [ ] **Step 6: Commit**

  ```bash
  git add scripts/combat/combat_unit.gd
  git commit -m "feat: add summoner_id, next_summon_empowered, has_summon_aura, lord_of_death_empowered to CombatUnit; clamp negative mantra bonuses"
  ```

---

## Chunk 2: Combat manager infrastructure

### Task 3: Summon infrastructure helpers in combat_manager.gd

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Add `_lord_of_death_casters` array variable**

  Find the variable declarations section near the top of `combat_manager.gd` (look for `var all_units`, `var turn_order`, etc.). Add this variable there:
  ```gdscript
  # Lord of Death DY: units that have triggered the DY; used for resurrection-on-kill checks
  var _lord_of_death_casters: Array = []
  ```

- [ ] **Step 2: Add `_get_owned_summons()` helper**

  Find the `# MANTRA SYSTEM` section header at line ~6040. Add this helper immediately before it:
  ```gdscript
  ## Return all live units whose summoner_id matches caster.get_instance_id()
  func _get_owned_summons(caster: Node) -> Array:
  	var caster_id = caster.get_instance_id()
  	var result: Array = []
  	for u in all_units:
  		if not u.is_dead and "summoner_id" in u and u.summoner_id == caster_id:
  			result.append(u)
  	return result
  ```

- [ ] **Step 3: Wire `summoner_id` in `_spawn_summoned_unit()`**

  Find line ~2415 in `_spawn_summoned_unit()`:
  ```gdscript
  	# Create the CombatUnit node
  	var summon_unit = CombatUnit.new()
  	summon_unit.init_as_enemy(summon_data)
  	summon_unit.team = caster.team  # Summon fights on the caster's side
  ```

  Add `summon_unit.summoner_id = caster.get_instance_id()` on a new line after `CombatUnit.new()`:
  ```gdscript
  	# Create the CombatUnit node
  	var summon_unit = CombatUnit.new()
  	summon_unit.summoner_id = caster.get_instance_id()  # Track ownership for mantra effects
  	summon_unit.init_as_enemy(summon_data)
  	summon_unit.team = caster.team  # Summon fights on the caster's side
  ```

- [ ] **Step 4: Add empowered-summon flag intercept in `_spawn_summoned_unit()`**

  Immediately after the `summon_unit.team = caster.team` line, add:
  ```gdscript
  	# Jeweled Pagoda DY: if caster.next_summon_empowered is set, consume it and apply buffs
  	if "next_summon_empowered" in caster and caster.next_summon_empowered:
  		caster.next_summon_empowered = false
  		# HP × 3, damage × 2
  		var emp_hp = summon_unit.max_hp * 3
  		summon_unit.max_hp = emp_hp
  		summon_unit.current_hp = emp_hp
  		var d = summon_unit.character_data.get("derived", {})
  		d["max_hp"] = emp_hp
  		d["current_hp"] = emp_hp
  		d["damage"] = d.get("damage", 0) * 2
  		summon_unit.character_data["equipped_weapon"]["damage"] = summon_unit.character_data["equipped_weapon"].get("damage", 0) * 2
  		summon_unit.has_summon_aura = true
  		combat_log.emit("%s: Empowered summon — %s is supercharged!" % [caster.unit_name, summon_unit.unit_name])
  ```

- [ ] **Step 5: Add `_process_summon_aura()` function**

  Add this function immediately before `_get_owned_summons()` (or adjacent to it in the mantra section):
  ```gdscript
  ## Apply the aura effect for an empowered summon at the start of its turn.
  ## Adds ±10 to mantra_stat_bonuses["armor"], ["dodge"], ["crit_chance"] for
  ## all units within 2 tiles — positive for allies, negative for enemies.
  ## The negative values are clamped to 0 in the getter (floor applied there).
  func _process_summon_aura(unit: Node) -> void:
  	for u in all_units:
  		if u.is_dead:
  			continue
  		var dist = _grid_distance(unit.grid_position, u.grid_position)
  		if dist > 2:
  			continue
  		var bonus = 10 if u.team == unit.team else -10
  		u.mantra_stat_bonuses["armor"] = u.mantra_stat_bonuses.get("armor", 0) + bonus
  		u.mantra_stat_bonuses["dodge"] = u.mantra_stat_bonuses.get("dodge", 0) + bonus
  		u.mantra_stat_bonuses["crit_chance"] = u.mantra_stat_bonuses.get("crit_chance", 0.0) + float(bonus)
  ```

- [ ] **Step 6: Rename `_process_mantra_effects` and add summon-aura call**

  Find `func _process_mantra_effects(unit: Node) -> void:` at line ~6046. Rename it and add the aura call at the end:
  ```gdscript
  func _process_mantra_effects_and_auras(unit: Node) -> void:
  	# Lord of Death cleanup: if DY was triggered but mantra is no longer active, remove from list
  	if not "mantra_of_the_lord_of_death" in unit.active_mantras:
  		_lord_of_death_casters.erase(unit)

  	var char_data = unit.character_data if "character_data" in unit else {}
  	var spellpower = unit.get_spellpower()

  	# Rebuild stat bonuses from scratch (so they don't accumulate unboundedly)
  	unit.mantra_stat_bonuses = {}

  	# Walking Meditation (cross-skill perk): +2 Move while any mantra is active
  	if PerkSystem.has_perk(char_data, "walking_meditation"):
  		unit.mantra_stat_bonuses["movement"] = unit.mantra_stat_bonuses.get("movement", 0) + 2

  	for perk_id in unit.active_mantras:
  		var stacks = mini(unit.active_mantras[perk_id], 5)
  		if stacks == 0:
  			continue  # Just started chanting this turn — no effect yet

  		_apply_mantra_tick(unit, perk_id, stacks, spellpower, char_data)

  		# Trigger Deity Yoga once when stacks reach 5
  		if unit.active_mantras[perk_id] >= 5 and not unit.deity_yoga_triggered.get(perk_id, false):
  			unit.deity_yoga_triggered[perk_id] = true
  			_trigger_deity_yoga(unit, perk_id, spellpower)

  	# Process summon aura if this unit has one
  	if "has_summon_aura" in unit and unit.has_summon_aura:
  		_process_summon_aura(unit)
  ```

  **Important:** Also search for every call site of `_process_mantra_effects(` in the file and update them to `_process_mantra_effects_and_auras(`. Typically this is called in the turn-start logic — search for `_process_mantra_effects(`.

- [ ] **Step 7: Add `lord_of_death_empowered` check in `calculate_physical_damage()`**

  In `calculate_physical_damage()` at line ~1430, find the `return` block (around line 1593):
  ```gdscript
  	return {
  		"damage": damage,
  		...
  	}
  ```

  Just before that return, add:
  ```gdscript
  	# Lord of Death DY: empowered summons deal 30% bonus damage
  	if "lord_of_death_empowered" in attacker and attacker.lord_of_death_empowered:
  		damage = int(damage * 1.3)
  ```

- [ ] **Step 8: Add `lord_of_death_empowered` check in spell damage path**

  In `combat_manager.gd`, find `_apply_spell_effects`. The spell damage is finalized as `total_damage` and applied at **line ~2231**: `apply_damage(target, total_damage, element)`. Add the empowered check immediately before that call (after the `maxi(1, total_damage)` clamp at line ~2229):
  ```gdscript
  	# Lord of Death DY: empowered summons deal 30% bonus spell damage
  	if "lord_of_death_empowered" in caster and caster.lord_of_death_empowered:
  		total_damage = int(total_damage * 1.3)
  	apply_damage(target, total_damage, element)
  ```
  **Variable name:** the actual variable in the code is `total_damage`, not `spell_damage`.

- [ ] **Step 9: Open project in Godot and verify no parse errors**

  Expected: Output panel shows no errors from `combat_manager.gd`.

- [ ] **Step 10: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: add summon infrastructure — summoner_id wiring, empowered spawn, _get_owned_summons, _process_summon_aura, rename _process_mantra_effects_and_auras, lord_of_death_empowered damage"
  ```

---

### Task 4: `_interrupt_mantras()` + call sites in combat_manager.gd

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Add the `_interrupt_mantras()` helper**

  Add this function in the mantra system section of `combat_manager.gd`, just before `_process_mantra_effects_and_auras`:
  ```gdscript
  ## Interrupt all active mantras on a unit (heavy hit, hard CC, or spell cast).
  ## Returns immediately if there are no active mantras (cheap guard).
  func _interrupt_mantras(unit: Node, reason: String) -> void:
  	if not ("active_mantras" in unit) or unit.active_mantras.is_empty():
  		return
  	unit.active_mantras = {}
  	unit.mantra_stat_bonuses = {}
  	_lord_of_death_casters.erase(unit)
  	combat_log.emit(reason)
  ```

- [ ] **Step 2: Wire into `apply_damage()` — heavy hit threshold**

  In `apply_damage()` at line ~1642, find the end of the function (just before or after the bleed-out check at line ~1667):
  ```gdscript
  	if unit.current_hp <= 0 and not unit.is_bleeding_out:
  		_start_bleed_out(unit)
  		_check_immediate_combat_end()
  ```

  After the closing of the `if` block above (i.e., after `_check_immediate_combat_end()`), add:
  ```gdscript
  	# Heavy hit: ≥15% of max HP breaks concentration
  	# Uses post-absorption damage (what was actually received). This is intentional:
  	# attacks reduced below 15% effective damage by armor do not disrupt mantras.
  	if damage > 0 and unit.is_alive():
  		var max_hp = unit.max_hp
  		if max_hp > 0 and float(damage) / float(max_hp) >= 0.15:
  			_interrupt_mantras(unit, "%s's concentration breaks from the heavy blow!" % unit.unit_name)
  ```

- [ ] **Step 3: Wire into `_apply_status_effect()` — hard CC types**

  In `_apply_status_effect()`, find the two exit points where a status was successfully applied:

  **Exit point 1 — non-stackable refresh** (around line 2756):
  ```gdscript
  				existing.duration = maxi(existing.duration, duration)
  				if value > 0:
  					existing.value = value
  				if source != null:
  					existing["source"] = source
  				return
  ```

  Change to add the interrupt check before the `return`:
  ```gdscript
  				existing.duration = maxi(existing.duration, duration)
  				if value > 0:
  					existing.value = value
  				if source != null:
  					existing["source"] = source
  				# Hard CC breaks concentration even on a refresh
  				if status in ["Stun", "Stunned", "Fear", "Feared", "Charm", "Charmed", "Confused", "Berserk"]:
  					_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])
  				return
  ```

  **Exit point 2 — new status append** (around line 2770–2778, after `unit.get("status_effects").append(effect_entry)`):
  ```gdscript
  	unit.get("status_effects").append(effect_entry)

  	# Show floating status applied text on the unit
  	if unit.has_method("show_status_applied"):
  		unit.show_status_applied(status)
  ```

  Add between the append and the show_status call:
  ```gdscript
  	unit.get("status_effects").append(effect_entry)

  	# Hard CC breaks concentration on the affected unit
  	if status in ["Stun", "Stunned", "Fear", "Feared", "Charm", "Charmed", "Confused", "Berserk"]:
  		_interrupt_mantras(unit, "%s's concentration is broken by %s!" % [unit.unit_name, status])

  	# Show floating status applied text on the unit
  	if unit.has_method("show_status_applied"):
  		unit.show_status_applied(status)
  ```

  **Note on status names:** The hard CC list checks both forms (e.g. `"Stun"` and `"Stunned"`) to be robust against minor naming inconsistencies in the data files. Check `resources/data/statuses.json` or `spells.json` for the exact names used in `"statuses_caused"` if any are missing.

- [ ] **Step 4: Open project in Godot and verify no parse errors**

  Expected: no errors from `combat_manager.gd`.

- [ ] **Step 5: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: add _interrupt_mantras() and wire into apply_damage, _apply_status_effect"
  ```

---

## Chunk 3: Arena + deferred mantra effects

### Task 5: Arena changes — spell-cast interrupt + AI chanter targeting

**Files:**
- Modify: `scripts/combat/combat_arena.gd`

- [ ] **Step 1: Wire spell-cast interrupt in `_try_cast_spell()` (player)**

  Find `_try_cast_spell()` at line ~930:
  ```gdscript
  func _try_cast_spell(target_pos: Vector2i) -> void:
  	var caster = CombatManager.get_current_unit()
  	if caster == null or selected_spell.is_empty():
  		_cancel_action_mode()
  		return

  	var result = CombatManager.cast_spell(caster, selected_spell.id, target_pos)

  	if result.success:
  		# Logging is handled by _on_spell_cast signal
  		pass
  ```

  Change the `if result.success:` block to:
  ```gdscript
  	if result.success:
  		# Logging is handled by _on_spell_cast signal
  		# Spell casting breaks concentration unless caster has continuous_recitation (Ritual 3)
  		if "active_mantras" in caster and not caster.active_mantras.is_empty():
  			var char_data = caster.character_data if "character_data" in caster else {}
  			if not PerkSystem.has_perk(char_data, "continuous_recitation"):
  				CombatManager._interrupt_mantras(caster, "%s's concentration breaks from casting!" % caster.unit_name)
  ```

- [ ] **Step 2: Wire spell-cast interrupt in `_ai_try_cast_spell()` (AI)**

  Find `_ai_try_cast_spell()` at line ~3112:
  ```gdscript
  		# If valid target found, cast the spell
  		if target_pos != Vector2i(-1, -1):
  			var result = CombatManager.cast_spell(unit, spell_id, target_pos)
  			if result.success:
  				return true
  ```

  Change the `if result.success:` block to:
  ```gdscript
  		# If valid target found, cast the spell
  		if target_pos != Vector2i(-1, -1):
  			var result = CombatManager.cast_spell(unit, spell_id, target_pos)
  			if result.success:
  				# Spell casting breaks concentration (AI casters rarely have continuous_recitation)
  				if "active_mantras" in unit and not unit.active_mantras.is_empty():
  					var char_data_ai = unit.character_data if "character_data" in unit else {}
  					if not PerkSystem.has_perk(char_data_ai, "continuous_recitation"):
  						CombatManager._interrupt_mantras(unit, "%s's concentration breaks from casting!" % unit.unit_name)
  				return true
  ```

- [ ] **Step 3: Add effective-distance chanter targeting to `_find_nearest_enemy()`**

  Find `_find_nearest_enemy()` at line ~3383. The function has two parts: a taunt short-circuit and a normal loop. Update **only the normal loop** (lines 3399–3407):

  Current code:
  ```gdscript
  	# Normal nearest-enemy selection
  	for enemy in enemies:
  		if not enemy.is_alive():
  			continue
  		var dist = _grid_distance(unit.grid_position, enemy.grid_position)
  		if dist < nearest_dist:
  			nearest_dist = dist
  			nearest = enemy
  ```

  Replace with:
  ```gdscript
  	# Normal nearest-enemy selection.
  	# Chanters (units with active mantras) are treated as 3 tiles closer
  	# so AI prioritises disrupting them. Taunt short-circuit above takes precedence.
  	for enemy in enemies:
  		if not enemy.is_alive():
  			continue
  		var dist = _grid_distance(unit.grid_position, enemy.grid_position)
  		var effective_dist = dist - (3 if ("active_mantras" in enemy and enemy.active_mantras.size() > 0) else 0)
  		if effective_dist < nearest_dist:
  			nearest_dist = effective_dist
  			nearest = enemy
  ```

- [ ] **Step 4: Add `_run_bonus_turn()` function**

  Add this function immediately before `_find_nearest_enemy()` (or just after `_do_enemy_turn`). This is called by Lord of Death DY to give owned summons a free action.

  ```gdscript
  ## Run a free bonus turn for a summon unit outside the normal turn order.
  ## Used by Lord of Death Deity Yoga. Uses reaction=true attacks to bypass
  ## the can_act() check (which gates on the current turn's unit, not this one).
  ## Manually tracks unit.actions_remaining.
  func _run_bonus_turn(unit: CombatUnit) -> void:
  	unit.actions_remaining = unit.character_data.get("actions", 2)
  	var player_units = CombatManager.get_team_units(CombatManager.Team.PLAYER)
  	if player_units.is_empty():
  		return
  	var nearest = _find_nearest_enemy(unit, player_units)
  	if nearest == null:
  		return

  	var attack_range = unit.get_attack_range()
  	var _safety = 0
  	while unit.actions_remaining > 0 and _safety < 10:
  		_safety += 1
  		if not nearest.is_alive():
  			nearest = _find_nearest_enemy(unit, player_units)
  			if nearest == null:
  				break

  		var dist = _grid_distance(unit.grid_position, nearest.grid_position)
  		if dist <= attack_range:
  			# reaction=true bypasses can_act() — this unit isn't the CombatManager current unit
  			var result = CombatManager.attack_unit(unit, nearest, true)
  			unit.actions_remaining -= 1
  			if result.get("hit", false):
  				_log_message("%s attacks %s for %d damage!" % [unit.unit_name, nearest.unit_name, result.get("damage", 0)])
  			else:
  				_show_miss_text(unit, nearest)
  		else:
  			# Move one step toward nearest using get_movement_range (doesn't check can_act)
  			var move_tiles = CombatManager.get_movement_range(unit)
  			var best_tile = unit.grid_position
  			for tile in move_tiles:
  				if _grid_distance(tile, nearest.grid_position) < _grid_distance(best_tile, nearest.grid_position):
  					best_tile = tile
  			if best_tile != unit.grid_position and CombatManager.combat_grid != null:
  				var from = unit.grid_position
  				CombatManager.combat_grid.move_unit(unit, best_tile)
  				CombatManager.unit_moved.emit(unit, from, best_tile)
  				unit.actions_remaining -= 1
  			else:
  				break  # Can't move, stop acting
  ```

- [ ] **Step 5: Open project and verify no parse errors**

  Expected: no errors from `combat_arena.gd`.

- [ ] **Step 6: Commit**

  ```bash
  git add scripts/combat/combat_arena.gd
  git commit -m "feat: wire spell-cast mantra interrupt, AI chanter targeting, _run_bonus_turn"
  ```

---

### Task 6: Roaring One DY — spawn Rudras

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Update `_trigger_deity_yoga` — Roaring One case**

  Find the `"mantra_of_the_roaring_one":` case in `_trigger_deity_yoga()` at line ~6378:
  ```gdscript
  	"mantra_of_the_roaring_one":
  		# Full speed + crit burst for all allies; summon is deferred (needs spawn system)
  		for a in allies_with_self:
  			a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
  			a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 15.0
  		combat_log.emit("(Rudra summons deferred — needs spawn system)")
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_roaring_one":
  		# Stat burst for all allies (+5 movement, +15% crit)
  		for a in allies_with_self:
  			a.mantra_stat_bonuses["movement"] = a.mantra_stat_bonuses.get("movement", 0) + 5
  			a.mantra_stat_bonuses["crit_chance"] = a.mantra_stat_bonuses.get("crit_chance", 0.0) + 15.0
  		# Spawn 1–3 Rudras near the caster (try adjacent tiles in order)
  		var rudra_count = 1 + randi() % 3
  		var spawned = 0
  		var offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0),
  		               Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]
  		for offset in offsets:
  			if spawned >= rudra_count:
  				break
  			var candidate = unit.grid_position + offset
  			if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
  				_spawn_summoned_unit(unit, "rudra", candidate, spellpower)
  				spawned += 1
  ```

- [ ] **Step 2: Open project and verify no parse errors**

- [ ] **Step 3: Manual verification**

  In a test combat, have a player unit chant `mantra_of_the_roaring_one` for 5 turns. At turn 5, observe:
  - Combat log shows "DEITY YOGA — Mantra Of The Roaring One!"
  - 1–3 Rudra units appear on adjacent tiles fighting for the player's team
  - All allies receive +5 movement and +15% crit from the stat burst

- [ ] **Step 4: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: Roaring One DY spawns 1-3 Rudras adjacent to caster"
  ```

---

### Task 7: Four Guardian Kings — spirit guardian maintenance + DY stone guardians

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Update `_apply_mantra_tick` — Four Guardian Kings case**

  Find the `"mantra_of_the_four_guardian_kings":` case in `_apply_mantra_tick()`:
  ```gdscript
  	"mantra_of_the_four_guardian_kings":
  		# Allies + summons in 3 tiles gain +5% Attack, +5% Armor per stack
  		for a in allies_with_self:
  			a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + stacks * 5
  			a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + stacks * 5
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_four_guardian_kings":
  		# 1. Maintain up to 4 spirit guardians around the caster
  		var owned = _get_owned_summons(unit)
  		var guardian_count = 0
  		for s in owned:
  			if "tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]:
  				guardian_count += 1
  		if guardian_count < 4:
  			# Find first free tile within 2 of caster
  			var found_tile = Vector2i(-1, -1)
  			for dx in range(-2, 3):
  				for dy in range(-2, 3):
  					if found_tile != Vector2i(-1, -1):
  						break
  					var candidate = unit.grid_position + Vector2i(dx, dy)
  					if candidate == unit.grid_position:
  						continue
  					if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
  						found_tile = candidate
  				if found_tile != Vector2i(-1, -1):
  					break
  			if found_tile != Vector2i(-1, -1):
  				_spawn_summoned_unit(unit, "spirit_guardian", found_tile, 0)
  				# Refresh owned list after spawn
  				owned = _get_owned_summons(unit)

  		# 2. Each spirit guardian gives +3 armor to the nearest ally within 3 tiles
  		for s in owned:
  			if not ("tags" in s.character_data and "guardian_spirit" in s.character_data["tags"]):
  				continue
  			var nearest_ally: Node = null
  			var nearest_ally_dist = 999
  			for a in allies_with_self:
  				var d = _grid_distance(s.grid_position, a.grid_position)
  				if d <= 3 and d < nearest_ally_dist:
  					nearest_ally_dist = d
  					nearest_ally = a
  			if nearest_ally != null:
  				nearest_ally.mantra_stat_bonuses["armor"] = nearest_ally.mantra_stat_bonuses.get("armor", 0) + 3
  ```

- [ ] **Step 2: Update `_trigger_deity_yoga` — Four Guardian Kings case**

  Find the `"mantra_of_the_four_guardian_kings":` case in `_trigger_deity_yoga()`:
  ```gdscript
  	"mantra_of_the_four_guardian_kings":
  		# Big stat burst to all allies; summon DY deferred
  		for a in allies_with_self:
  			a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
  			a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25
  		combat_log.emit("(Guardian summons deferred — needs spawn system)")
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_four_guardian_kings":
  		# Stat burst for all allies (+25 armor, +25 accuracy)
  		for a in allies_with_self:
  			a.mantra_stat_bonuses["armor"] = a.mantra_stat_bonuses.get("armor", 0) + 25
  			a.mantra_stat_bonuses["accuracy"] = a.mantra_stat_bonuses.get("accuracy", 0) + 25
  		# Spawn a Guardian King in each of 4 cardinal directions (search outward up to radius 2)
  		var cardinal_offsets = [Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)]
  		for base_offset in cardinal_offsets:
  			var spawn_tile = Vector2i(-1, -1)
  			# Try exact cardinal tile, then 1 further, then 2 further (along the same axis)
  			for r in range(0, 3):
  				if spawn_tile != Vector2i(-1, -1):
  					break
  				var candidate = unit.grid_position + base_offset * (1 + r)
  				if combat_grid != null and combat_grid.is_valid_position(candidate) and not combat_grid.is_occupied(candidate):
  					spawn_tile = candidate
  			if spawn_tile != Vector2i(-1, -1):
  				_spawn_summoned_unit(unit, "stone_guardian", spawn_tile, 0)
  ```

  **Note:** The search logic tries `base_offset * 1`, `base_offset * 2`, `base_offset * 3` (up to radius 2 away from the exact cardinal tile). If all three are blocked, that direction is skipped. Up to all 4 Guardian Kings may spawn.

- [ ] **Step 3: Open project and verify no parse errors**

- [ ] **Step 4: Manual verification**

  Test with `mantra_of_the_four_guardian_kings` active:
  - After turn 1+: spirit guardians (1 hp, 0 actions) appear near the caster
  - Each turn, the nearest ally gets +3 armor from each guardian
  - At turn 5 DY: up to 4 Guardian Kings (display_name "Guardian King") appear at cardinal tiles; all allies get +25 armor and +25 accuracy in the log

- [ ] **Step 5: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: Four Guardian Kings — per-turn spirit guardian spawn + DY stone guardian spawn"
  ```

---

### Task 8: Jeweled Pagoda — stacking spellpower, owned summon buffs, empowered-summon DY

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Update `_apply_mantra_tick` — Jeweled Pagoda case**

  Find the `"mantra_of_the_jeweled_pagoda":` case in `_apply_mantra_tick()`:
  ```gdscript
  	"mantra_of_the_jeweled_pagoda":
  		# Caster +5% Spellpower per stack; allies' summons +3% all stats per stack
  		unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * (spellpower / 20)
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_jeweled_pagoda":
  		# 1. Caster gains +5 * stacks flat spellpower bonus
  		unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + stacks * 5
  		# 2. Each owned summon gains stacks*3 to damage, armor, dodge
  		for s in _get_owned_summons(unit):
  			s.mantra_stat_bonuses["damage"] = s.mantra_stat_bonuses.get("damage", 0) + stacks * 3
  			s.mantra_stat_bonuses["armor"] = s.mantra_stat_bonuses.get("armor", 0) + stacks * 3
  			s.mantra_stat_bonuses["dodge"] = s.mantra_stat_bonuses.get("dodge", 0) + stacks * 3
  ```

- [ ] **Step 2: Update `_trigger_deity_yoga` — Jeweled Pagoda case**

  Find the `"mantra_of_the_jeweled_pagoda":` case in `_trigger_deity_yoga()`:
  ```gdscript
  	"mantra_of_the_jeweled_pagoda":
  		# Caster's next summon is empowered (flag it); big Spellpower burst
  		unit.mantra_stat_bonuses["spellpower"] = unit.mantra_stat_bonuses.get("spellpower", 0) + spellpower
  		combat_log.emit("(Empowered summon DY deferred — needs spawn system)")
  ```

  Replace with (the placeholder spellpower burst is removed and replaced entirely):
  ```gdscript
  	"mantra_of_the_jeweled_pagoda":
  		# Set the empowered flag — consumed by _spawn_summoned_unit() on next summon cast
  		unit.next_summon_empowered = true
  		combat_log.emit("%s's next summon will be empowered!" % unit.unit_name)
  ```

- [ ] **Step 3: Open project and verify no parse errors**

- [ ] **Step 4: Manual verification**

  - With Jeweled Pagoda active for 2 stacks: the caster should have +10 flat spellpower from the mantra (not a percentage). Owned summons should show +6 damage/armor/dodge in the mantra_stat_bonuses dict.
  - At 5 stacks DY: combat log shows "X's next summon will be empowered!"; casting any summon spell next creates a summon with 3× HP and 2× damage that emits a ±10 aura each turn.

- [ ] **Step 5: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: Jeweled Pagoda — stacks*5 spellpower, owned summon buffs, empowered-summon DY"
  ```

---

### Task 9: Lord of Death — per-turn effects + DY bonus turns, empowered, resurrection

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

This is the most complex task. The per-turn effect replaces the existing one. The DY adds three new effects.

- [ ] **Step 1: Update `_apply_mantra_tick` — Lord of Death case**

  Find the `"mantra_of_the_lord_of_death":` case in `_apply_mantra_tick()`:
  ```gdscript
  	"mantra_of_the_lord_of_death":
  		# Enemies in 4 tiles take Black damage 3% Spellpower × stacks
  		var dmg = ceili(spellpower * 0.03 * stacks)
  		for e in enemies_4:
  			apply_damage(e, dmg, "black")
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_lord_of_death":
  		# 1. Heal black-tagged owned summons within 4 tiles (10% of their max HP)
  		for s in _get_owned_summons(unit):
  			if "tags" in s.character_data and "black" in s.character_data["tags"]:
  				if _grid_distance(unit.grid_position, s.grid_position) <= 4:
  					var heal_amt = ceili(s.character_data.get("max_hp", 1) * 0.10)
  					s.heal(heal_amt)
  					unit_healed.emit(s, heal_amt)
  		# 2. Stacking black damage to enemies in 4 tiles (3% spellpower × stacks)
  		var lod_dmg = ceili(spellpower * 0.03 * stacks)
  		for e in enemies_4:
  			apply_damage(e, lod_dmg, "black")
  ```

- [ ] **Step 2: Update `_trigger_deity_yoga` — Lord of Death case**

  Find the `"mantra_of_the_lord_of_death":` case in `_trigger_deity_yoga()`:
  ```gdscript
  	"mantra_of_the_lord_of_death":
  		# Enemies in 4 tiles take 20% Spellpower Black; apply Feared
  		var dmg = ceili(spellpower * 0.20)
  		for e in enemies_4:
  			apply_damage(e, dmg, "black")
  			_apply_status_effect(e, "Feared", 3, 0, unit)
  ```

  Replace with:
  ```gdscript
  	"mantra_of_the_lord_of_death":
  		# Existing burst: black damage + Fear to all enemies in 4 tiles
  		var lod_dy_dmg = ceili(spellpower * 0.20)
  		for e in enemies_4:
  			apply_damage(e, lod_dy_dmg, "black")
  			_apply_status_effect(e, "Feared", 3, 0, unit)
  		# 1. Bonus turns for all owned summons + empower them
  		var owned_summons = _get_owned_summons(unit)
  		for s in owned_summons:
  			s.lord_of_death_empowered = true
  			combat_log.emit("%s acts under the Lord of Death's command!" % s.unit_name)
  			# _run_bonus_turn is defined in combat_arena.gd;
  			# reach it via the scene tree or direct call if arena is accessible
  			if get_tree() != null:
  				var arena = get_tree().get_first_node_in_group("combat_arena")
  				if arena != null and arena.has_method("_run_bonus_turn"):
  					arena._run_bonus_turn(s)
  		# 2. Register this caster for resurrection-on-kill tracking
  		if not unit in _lord_of_death_casters:
  			_lord_of_death_casters.append(unit)
  ```

  **Note on arena access:** `_run_bonus_turn` is defined in `combat_arena.gd`. The combat arena scene should be in the "combat_arena" group (add it if not). If the arena is not in a group, find it by `get_tree().get_nodes_in_group("combat_arena")` or by scene path. If neither works, move `_run_bonus_turn` to `combat_manager.gd` instead (it only needs `CombatManager` methods and `_find_nearest_enemy`-equivalent logic — use `_get_enemies_in_range` instead).

- [ ] **Step 3: Check if combat_arena is in the "combat_arena" group**

  Open `scenes/combat/combat_arena.tscn` in Godot. Select the root node. Check the Node panel → Groups tab. If the group "combat_arena" is not present, add it. Save the scene.

  **Alternative:** If the group approach is inconvenient, move `_run_bonus_turn` to `combat_manager.gd` and call it directly from `_trigger_deity_yoga`. In that version, replace `CombatManager.attack_unit(unit, nearest, true)` with the already-existing `attack_unit(unit, nearest, true)` (direct call, no prefix needed).

- [ ] **Step 4: Add Lord of Death resurrection hook in `_kill_unit()`**

  Find `_kill_unit()` at line ~1682. Insert after the Cleave trigger at line ~1788 (`_trigger_cleave(killer, unit.grid_position)`), **before** the `# Remove from turn order` block at line ~1790. The Necromancer block itself ends around line 1786 and `nc_unit.team = killer.team` is at line ~1767 (not 1790). Add:
  ```gdscript
  	# Lord of Death DY: 40% chance to raise a zombie/skeleton when an enemy dies near a registered caster
  	var dead_pos = unit.grid_position
  	for lod_caster in _lord_of_death_casters:
  		if lod_caster == null or lod_caster.is_dead:
  			continue
  		# Only trigger if the dead unit was on the opposing team
  		if "team" in unit and "team" in lod_caster and unit.team == lod_caster.team:
  			continue
  		if _grid_distance(dead_pos, lod_caster.grid_position) > 4:
  			continue
  		if randf() < 0.40:
  			var undead_template = ["zombie", "skeleton"][randi() % 2]
  			_spawn_summoned_unit(lod_caster, undead_template, dead_pos, 0)
  			combat_log.emit("The Lord of Death claims %s's soul!" % unit.unit_name)
  			break  # Only one resurrection per death event
  ```

- [ ] **Step 5: Open project and verify no parse errors**

- [ ] **Step 6: Manual verification**

  Test Lord of Death mantra:
  - Per-turn: black summons (zombie/skeleton) in range should heal each turn; enemies in 4 tiles take increasing black damage (1× at stack 1, 5× at stack 5)
  - DY: feared burst fires as before; owned summons get a free action (you should see them act during the caster's turn); 40% of enemy deaths within 4 tiles rise as zombies/skeletons
  - Cleanup: toggle the mantra off; on the caster's next turn start, verify the caster is removed from `_lord_of_death_casters` (resurrection stops triggering)

- [ ] **Step 7: Commit**

  ```bash
  git add scripts/autoload/combat_manager.gd
  git commit -m "feat: Lord of Death — per-turn summon heal + stacking damage; DY bonus turns, +30% damage, resurrection"
  ```

---

## Final verification

- [ ] **Run a full combat with a mantra user**

  Start a combat via the overworld. Have the player unit use several different mantras. Verify:
  1. Taking a heavy hit (≥15% HP in one strike) clears the `active_mantras` dict and logs "concentration breaks"
  2. A Stun/Fear status being applied also breaks concentration
  3. Casting a spell breaks concentration (unless the character has `continuous_recitation`)
  4. Enemy AI preferentially targets units with active mantras (moves toward chanters over other targets when the chanter is at distance 4+)
  5. The Jeweled Pagoda empowered spawn creates a clearly beefier unit (check HP value in combat log vs a non-empowered spawn)
  6. No error spam in the Output panel during mantra turns

- [ ] **Final commit (if only minor fixes)**

  ```bash
  git add -p  # stage only relevant files
  git commit -m "fix: mantra completion polish from final verification pass"
  ```
