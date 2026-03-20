# Weapon Materials + Combat Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 broken weapon-stat combat bugs, redesign material tiers to a thematic 9-tier ladder (wood→vajra), add `club` weapon type, add realm-based material weights, and wire durability consumption.

**Architecture:** Data changes in `equipment_tables.json` + generation fixes in `item_system.gd` + combat stat reads in `combat_unit.gd` + armor pierce / on-hit passives / durability in `combat_manager.gd`. No new files needed. Changes flow from generation → combat reads → hit processing.

**Tech Stack:** GDScript 4, Godot 4.3, JSON data files. No automated test runner — verification is in-engine console output and manual spot checks.

---

## Files

| File | Changes |
|------|---------|
| `TODO.md` | Add weapon element affinity design note |
| `resources/data/equipment_tables.json` | New 9-tier materials, realm weights, `club` weapon, fix sword element |
| `scripts/autoload/item_system.gd` | `_pct` conversion, material `stat_bonuses`, wood restriction, elemental damage from traits, `realm` param, `update_item_durability()` |
| `scripts/combat/combat_unit.gd` | Weapon stats in `get_accuracy`, `get_crit_chance`, `get_spellpower`, `get_initiative`; new `get_armor_pierce()` |
| `scripts/autoload/combat_manager.gd` | Armor pierce in `calculate_physical_damage`; `_process_weapon_on_hit_procs()`; durability deduction `_deduct_weapon_durability()` |

---

## Task 1: Update TODO.md

**Files:**
- Modify: `TODO.md`

- [ ] **Add the design note** — find the "Design Questions Still Open" or equivalent section in TODO.md and add:

```
### Weapon Element Affinity (future design)
Each weapon has an `element` field matching its governing skill's element (e.g. sword→space, axe→fire).
Design a system where high elemental affinity boosts weapons of that element — e.g. a Space-attuned
character gets extra crit or damage with swords/staffs. Wire into CharacterSystem elemental affinity
bonuses and/or add element-affinity multipliers to generate_weapon stat scaling.
```

- [ ] **Commit**

```bash
git add TODO.md
git commit -m "docs: add weapon element affinity design note to TODO"
```

---

## Task 2: Rewrite equipment_tables.json — Materials, Club, Realm Weights

**Files:**
- Modify: `resources/data/equipment_tables.json`

**What's changing:**
- `materials` block: remove `mithril` and `demon_forged`; add `damascene`, `sky_iron`, `vajra`; update `obsidian` with `stat_bonuses`; add `allowed_types` to `wood`
- `weapon_bases`: fix sword `element` (`"earth"` → `"space"`); add `club` entry
- `tier_to_material_weights`: update keys 0–8 for new ladder (fallback only, used when no realm provided)
- Add `realm_material_weights` section: flat per-realm tables, no rarity sub-keys

- [ ] **Replace the `materials` block** (lines 4–13) with:

```json
"materials": {
    "wood":        {"tier": 0, "damage_mult": 0.55, "armor_mult": 0.0,  "weight_mult": 0.65, "value_mult": 0.25, "base_durability": 35,   "fragility": 1.3, "name_prefix": "Wooden",   "allowed_types": ["staff", "club"]},
    "bone":        {"tier": 1, "damage_mult": 0.65, "armor_mult": 0.55, "weight_mult": 0.60, "value_mult": 0.35, "base_durability": 30,   "fragility": 1.5, "name_prefix": "Bone"},
    "obsidian":    {"tier": 2, "damage_mult": 0.90, "armor_mult": 0.15, "weight_mult": 0.50, "value_mult": 0.90, "base_durability": 20,   "fragility": 3.0, "name_prefix": "Obsidian",  "stat_bonuses": {"crit_chance": 3}, "_note": "High dmg/crit, brittle, poor armor material"},
    "bronze":      {"tier": 3, "damage_mult": 0.80, "armor_mult": 0.80, "weight_mult": 0.90, "value_mult": 0.65, "base_durability": 65,   "fragility": 1.0, "name_prefix": "Bronze"},
    "iron":        {"tier": 4, "damage_mult": 1.00, "armor_mult": 1.00, "weight_mult": 1.00, "value_mult": 1.00, "base_durability": 85,   "fragility": 1.0, "name_prefix": "Iron"},
    "steel":       {"tier": 5, "damage_mult": 1.20, "armor_mult": 1.20, "weight_mult": 0.95, "value_mult": 1.50, "base_durability": 110,  "fragility": 1.0, "name_prefix": "Steel"},
    "damascene":   {"tier": 6, "damage_mult": 1.35, "armor_mult": 1.30, "weight_mult": 0.85, "value_mult": 2.50, "base_durability": 140,  "fragility": 0.8, "name_prefix": "Damascene"},
    "sky_iron":    {"tier": 7, "damage_mult": 1.50, "armor_mult": 1.55, "weight_mult": 0.75, "value_mult": 5.00, "base_durability": 180,  "fragility": 0.6, "name_prefix": "Sky-iron",  "_note": "Tibetan meteoritic iron (gnam lcags), used in real vajras and ritual implements"},
    "vajra":       {"tier": 8, "damage_mult": 1.70, "armor_mult": 1.80, "weight_mult": 0.65, "value_mult": 15.0, "base_durability": 9999, "fragility": 0.0, "name_prefix": "Vajra",    "_note": "Indestructible divine metal — never degrades"}
},
```

- [ ] **Fix sword element and add club** in `weapon_bases`:

Change `sword` line: `"element": "earth"` → `"element": "space"`

Add after the `javelin` line:
```json
"club":     {"damage": 8,  "accuracy": -5, "weight": 7,  "value": 20,  "element": "earth", "two_handed": false, "skill": "maces"}
```

- [ ] **Replace `tier_to_material_weights`** (fallback for no-realm generation):

```json
"tier_to_material_weights": {
    "0": {"wood": 70, "bone": 30},
    "1": {"bone": 70, "obsidian": 30},
    "2": {"bone": 20, "obsidian": 50, "bronze": 30},
    "3": {"obsidian": 15, "bronze": 50, "iron": 35},
    "4": {"bronze": 20, "iron": 50, "steel": 30},
    "5": {"iron": 20, "steel": 50, "damascene": 30},
    "6": {"steel": 20, "damascene": 50, "sky_iron": 30},
    "7": {"damascene": 20, "sky_iron": 50, "vajra": 30},
    "8": {"sky_iron": 30, "vajra": 70}
},
```

- [ ] **Add `realm_material_weights`** — flat per-realm bell curves, material only (rarity only drives quality):

```json
"realm_material_weights": {
    "hell":         {"bone": 45, "obsidian": 35, "bronze": 15, "iron": 4, "steel": 1},
    "hungry_ghost": {"bone": 20, "obsidian": 30, "bronze": 30, "iron": 15, "steel": 5},
    "animal":       {"bone": 5,  "obsidian": 10, "bronze": 35, "iron": 35, "steel": 15},
    "human":        {"bronze": 5, "iron": 30, "steel": 40, "damascene": 20, "sky_iron": 5},
    "demi_god":     {"iron": 5, "steel": 25, "damascene": 40, "sky_iron": 25, "vajra": 5},
    "god":          {"steel": 5, "damascene": 15, "sky_iron": 35, "vajra": 45}
},
```

- [ ] **Verify JSON is valid** — open the file in a JSON validator or run:
```bash
python3 -c "import json; json.load(open('resources/data/equipment_tables.json')); print('OK')"
```
Expected: `OK`

- [ ] **Commit**
```bash
git add resources/data/equipment_tables.json
git commit -m "data: redesign material tiers wood→vajra, add club weapon, realm material weights"
```

---

## Task 3: Fix item_system.gd — Generation

**Files:**
- Modify: `scripts/autoload/item_system.gd`

Five sub-fixes in `generate_weapon()` (and mirrored in `generate_armor()` where applicable):
A. Realm parameter + realm-based material selection
B. Wood type restriction
C. Material `stat_bonuses` applied to `final_stats`
D. `_pct` trait keys converted to actual stat values
E. Elemental damage traits stored in `passive.elemental_damage`
Plus: `update_item_durability()` public method for durability tracking.

### A — Realm parameter + material selection

- [ ] **Change `generate_weapon` signature** (line ~947) to add `realm: String = ""`):

```gdscript
func generate_weapon(weapon_type: String = "", rarity: String = "common",
		material_override: String = "", quality_override: String = "",
		realm: String = "") -> String:
```

- [ ] **Replace the material-picking block** (lines ~976–982) with realm-aware logic:

```gdscript
	# Pick material — realm sets the bell curve; rarity is fallback only when no realm given
	var material: String = material_override
	var m_weights: Dictionary
	if material == "" or not material in materials:
		var realm_weights = _equipment_tables.get("realm_material_weights", {})
		if realm != "" and realm in realm_weights:
			m_weights = realm_weights[realm]
		else:
			var rarity_tiers = {"common": "3", "uncommon": "4", "rare": "5", "epic": "6", "legendary": "7"}
			var tier_key = rarity_tiers.get(rarity, "4")
			m_weights = tier_materials.get(tier_key, {"iron": 100})
		material = _weighted_pick(m_weights)
```

- [ ] **Mirror the same change in `generate_armor`** — same signature addition and same material-picking block replacement. Also update the `rarity_tiers` fallback mapping inside `generate_armor` to use the new scale: `{"common": "3", "uncommon": "4", "rare": "5", "epic": "6", "legendary": "7"}` (same as `generate_weapon`).

- [ ] **Update `generate_weapon_for_party`** (line ~1272) to accept and forward `realm`:

```gdscript
func generate_weapon_for_party(rarity: String = "common",
		material_override: String = "", quality_override: String = "",
		realm: String = "") -> String:
```
And in the body, forward `realm` to `generate_weapon(best_type, rarity, material_override, quality_override, realm)`.

- [ ] **Add `"club"` to `WEAPON_TYPES`** constant (line ~1305 of `item_system.gd`):

```gdscript
const WEAPON_TYPES: Array[String] = [
	"sword", "dagger", "axe", "mace", "spear", "staff", "bow", "crossbow", "javelin", "club"
]
```

- [ ] **Note — other callers to wire up (out of scope for this task, but don't forget):**
  - `shop_system.gd` lines ~712–716 call `generate_weapon` / `generate_armor` without realm. Pass `GameState.current_world` as the realm value when wiring shops.
  - `companion_system.gd` lines ~248–255 call `generate_weapon` / `generate_armor` without realm. Pass the current world similarly.
  - `generate_item_for_type()` (line ~1363) — will need a realm parameter once shops/drops are updated.

### B — Wood type restriction

- [ ] **Add wood restriction check** immediately after the material is picked (after `material = _weighted_pick(m_weights)`, before `var mat_info = materials[material]`):

```gdscript
	# Material type restriction (e.g. wood only allowed for staff/club)
	if material != "" and material in materials:
		var allowed = materials[material].get("allowed_types", [])
		if allowed.size() > 0 and not weapon_type in allowed:
			# Re-pick from same pool, excluding materials that don't allow this type
			var filtered: Dictionary = {}
			for mat_key in m_weights:
				var mat_allowed = materials.get(mat_key, {}).get("allowed_types", [])
				if mat_allowed.is_empty() or weapon_type in mat_allowed:
					filtered[mat_key] = m_weights[mat_key]
			material = _weighted_pick(filtered) if not filtered.is_empty() else "iron"
```

### C — Material `stat_bonuses`

- [ ] **Add stat_bonuses merge** after `var mat_info = materials[material]` and after base stats are computed (after the `for special in [...]` loop, around line ~999):

```gdscript
	# Apply material-specific stat bonuses (e.g. obsidian crit_chance +3)
	for bonus_key in mat_info.get("stat_bonuses", {}):
		var bonus_val = mat_info["stat_bonuses"][bonus_key]
		if bonus_key in final_stats:
			final_stats[bonus_key] += bonus_val
		else:
			final_stats[bonus_key] = bonus_val
```

### D — `_pct` trait key conversion

- [ ] **Replace the "Special combat passives" check** in the trait-processing loop with expanded logic that also routes `*_damage_pct` keys:

```gdscript
			# Elemental damage traits (e.g. space_damage_pct: 15)
			if key.ends_with("_damage_pct"):
				var element = key.left(key.length() - 11)  # strip "_damage_pct"
				if not "elemental_damage" in passive:
					passive["elemental_damage"] = {}
				var base_dmg = base.get("damage", 5)
				passive["elemental_damage"][element] = maxi(1, int(base_dmg * trait_info[key] / 100.0))
			# On-hit proc passives stored raw
			elif key in ["poison_chance", "bleed_chance", "stun_chance", "burn_chance",
					"freeze_chance", "silence_chance", "dispel_chance", "lifesteal", "manasteal"]:
				passive[key] = trait_info[key]
			elif key in final_stats:
				final_stats[key] += trait_info[key]
			else:
				final_stats[key] = trait_info[key]
```

- [ ] **Add `_pct` post-processing pass** after the trait loop ends and before the name-building block:

```gdscript
	# Convert _pct trait keys to actual stat adjustments
	for key in final_stats.keys():
		if not key.ends_with("_pct"):
			continue
		var base_key = key.left(key.length() - 4)  # strip "_pct"
		if base_key == "loot_value":
			# Affects item gold value, not a combat stat
			final_value = int(final_value * (1.0 + final_stats[key] / 100.0))
		elif base_key == "initiative":
			# No weapon base for initiative — store a minimal flat bonus (10% → +1)
			final_stats["initiative"] = maxi(1, int(final_stats[key] / 10))
		else:
			var current = final_stats.get(base_key, 0)
			if current != 0:
				final_stats[base_key] = current + int(current * final_stats[key] / 100.0)
			# If current == 0 (e.g. accuracy_pct on a zero-accuracy weapon), result stays 0 — correct by design
		final_stats.erase(key)
```

### E — Add `update_item_durability()` to ItemSystem

- [ ] **Add the method** near the other public item-mutation helpers (after `clear_inventory()`, ~line 449):

```gdscript
## Update durability on a runtime-generated item (static items don't track wear).
## Called by CombatManager after each weapon use.
func update_item_durability(item_id: String, new_value: int) -> void:
	if item_id in _runtime_items:
		_runtime_items[item_id]["durability"] = new_value
```

- [ ] **Verify JSON still valid, then run the game and open the character sheet** — equip a generated weapon and confirm:
  - Its name no longer contains `_pct` words
  - A Bone weapon shows lower damage than Iron
  - An Obsidian weapon shows +3 crit_chance in its stats
  - A sword shows `element: space` in its item data (print from console if needed)

- [ ] **Commit**
```bash
git add scripts/autoload/item_system.gd
git commit -m "fix: item generation — pct traits, material stat_bonuses, wood restriction, realm weights, elemental damage traits"
```

---

## Task 4: Fix combat_unit.gd — Weapon Stats in Combat Getters

**Files:**
- Modify: `scripts/combat/combat_unit.gd`

`get_item()` returns a `.duplicate()` so weapon stats must be read through `get_equipped_weapon()` (which already calls `get_item()` internally). All getters follow the same additive pattern already used for status/perk/mantra bonuses.

- [ ] **Fix `get_accuracy()`** (line ~608) — add weapon accuracy:

```gdscript
func get_accuracy() -> int:
	var derived = character_data.get("derived", {})
	var weapon_acc = get_equipped_weapon().get("stats", {}).get("accuracy", 0)
	return derived.get("accuracy", 0) + weapon_acc + _get_status_stat_bonus("accuracy") + mantra_stat_bonuses.get("accuracy", 0) + _get_stat_modifier_bonus("accuracy")
```

- [ ] **Fix `get_crit_chance()`** (line ~687) — add weapon crit_chance:

```gdscript
func get_crit_chance() -> float:
	var derived = character_data.get("derived", {})
	var mantra_crit = float(mantra_stat_bonuses.get("crit_chance", 0))
	var weapon_crit = float(get_equipped_weapon().get("stats", {}).get("crit_chance", 0))
	return float(derived.get("crit_chance", 5)) + weapon_crit + float(_get_status_stat_bonus("crit_chance")) + float(CombatManager.get_passive_perk_stat_bonus(self, "crit_chance")) + maxf(0.0, mantra_crit) + float(_get_stat_modifier_bonus("crit_chance"))
```

- [ ] **Fix `get_spellpower()`** (line ~762) — add weapon spellpower:

```gdscript
func get_spellpower() -> int:
	var derived = character_data.get("derived", {})
	var weapon_sp = get_equipped_weapon().get("stats", {}).get("spellpower", 0)
	return derived.get("spellpower", 0) + weapon_sp + _get_status_stat_bonus("spellpower") + mantra_stat_bonuses.get("spellpower", 0) + _get_stat_modifier_bonus("spellpower")
```

- [ ] **Fix `get_initiative()`** (line ~478) — add weapon initiative bonus. The function already declares `var derived = character_data.get("derived", {})` — keep that line, just extend the return:

```gdscript
func get_initiative() -> int:
	var derived = character_data.get("derived", {})
	var weapon_init = get_equipped_weapon().get("stats", {}).get("initiative", 0)
	return derived.get("initiative", 10) + weapon_init + _get_status_stat_bonus("initiative") + CombatManager.get_passive_perk_stat_bonus(self, "initiative") + mantra_stat_bonuses.get("initiative", 0) + _get_stat_modifier_bonus("initiative")
```

- [ ] **Add `get_armor_pierce()`** — new method, place near `get_armor()` (~line 679):

```gdscript
## Get armor pierce value from equipped weapon (flat reduction to defender armor before damage)
func get_armor_pierce() -> int:
	return get_equipped_weapon().get("stats", {}).get("armor_pierce", 0)
```

- [ ] **Verify** — run the game, enter combat with a dagger (crit_chance: 5 in base). Open the combat log or add a temporary `print("crit_chance:", attacker.get_crit_chance())` call. Confirm it's 5 higher than for a sword.

- [ ] **Commit**
```bash
git add scripts/combat/combat_unit.gd
git commit -m "fix: combat_unit reads weapon stats (accuracy, crit_chance, spellpower, initiative, armor_pierce)"
```

---

## Task 5: Fix combat_manager.gd — Armor Pierce, On-Hit Passives, Durability

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

### A — Armor pierce in `calculate_physical_damage`

- [ ] **Add armor pierce reduction** immediately after all the perk-based armor reductions and before the final `damage = maxi(1, damage - armor)` line (line ~1549):

```gdscript
	# Weapon armor pierce — flat reduction to effective armor before damage
	if attacker.has_method("get_armor_pierce"):
		var pierce = attacker.get_armor_pierce()
		if pierce > 0:
			armor = maxi(0, armor - pierce)

	damage = maxi(1, damage - armor)
```

### B — `_process_weapon_on_hit_procs()`

- [ ] **Add the new function** near `_process_on_hit_perks` (around line 5548):

```gdscript
## Process on-hit procs from weapon passive dict.
## Called from attack_unit() after damage lands, alongside _process_on_hit_perks.
func _process_weapon_on_hit_procs(attacker: Node, defender: Node, result: Dictionary) -> void:
	if not attacker.has_method("get_equipped_weapon"):
		return
	var passive = attacker.get_equipped_weapon().get("passive", {})
	if passive.is_empty():
		return

	# Status procs — roll each chance independently
	var status_procs = {
		"poison_chance":  "Poisoned",
		"bleed_chance":   "Bleeding",
		"stun_chance":    "Stunned",
		"burn_chance":    "Burning",
		"freeze_chance":  "Chilled",
		"silence_chance": "Silenced",
	}
	for key in status_procs:
		if key in passive and randf() * 100.0 <= passive[key]:
			_apply_status_effect(defender, status_procs[key], 3)

	# Dispel: remove one random buff from the defender
	# status_effects is an Array of {status, duration} dicts; iterate with for..in
	if "dispel_chance" in passive and randf() * 100.0 <= passive["dispel_chance"]:
		if "status_effects" in defender:
			var buff_indices: Array = []
			for i in range(defender.status_effects.size()):
				var effect = defender.status_effects[i]
				var sdef = get_status_definition(effect.get("status", ""))
				if sdef.get("type", "debuff") == "buff":
					buff_indices.append(i)
			if buff_indices.size() > 0:
				defender.status_effects.remove_at(buff_indices[randi() % buff_indices.size()])

	# Lifesteal
	if "lifesteal" in passive:
		var steal = int(result.get("damage", 0) * passive["lifesteal"] / 100.0)
		if steal > 0:
			attacker.heal(steal)
			unit_healed.emit(attacker, steal)
			result["weapon_lifesteal"] = steal

	# Manasteal
	if "manasteal" in passive:
		var steal_mana = int(result.get("damage", 0) * passive["manasteal"] / 100.0)
		if steal_mana > 0 and "current_mana" in defender:
			var actual = mini(steal_mana, defender.current_mana)
			defender.current_mana = defender.current_mana - actual
			attacker.restore_mana(actual)
			result["weapon_manasteal"] = actual

	# Elemental damage bonus attacks
	if "elemental_damage" in passive:
		for element in passive["elemental_damage"]:
			var dmg = passive["elemental_damage"][element]
			if dmg > 0:
				apply_damage(defender, dmg, element)
				if not "elemental_procs" in result:
					result["elemental_procs"] = {}
				result["elemental_procs"][element] = dmg
```

> Note: `get_status_definition()` already exists in `combat_manager.gd` (~line 222). The dispel code above uses the same `sdef.get("type", "debuff") == "buff"` pattern used elsewhere in the file.

- [ ] **Call `_process_weapon_on_hit_procs`** right after `_process_on_hit_perks` (line ~1303):

```gdscript
		# --- Passive perk on-hit effects ---
		_process_on_hit_perks(attacker, defender, result)
		# --- Weapon passive on-hit procs ---
		_process_weapon_on_hit_procs(attacker, defender, result)
```

### C — Durability deduction

- [ ] **Add `_deduct_weapon_durability()`** near the other private helpers:

```gdscript
## Deduct durability from the attacker's equipped weapon after use.
## Fragility stored in item.generated.fragility = durability cost per attack.
## Vajra and similar (fragility 0.0) never degrade. Static items (no gen_XXXX id) skipped.
func _deduct_weapon_durability(unit: Node) -> void:
	if not unit.has_method("get_equipped_weapon"):
		return
	var weapon = unit.get_equipped_weapon()
	if weapon.is_empty():
		return
	var fragility: float = weapon.get("generated", {}).get("fragility", 0.0)
	if fragility <= 0.0:
		return  # Indestructible or not a generated item

	# Use ItemSystem.get_equipped_item() — handles weapon-set indirection correctly
	if not "character_data" in unit:
		return
	var item_id = ItemSystem.get_equipped_item(unit.character_data, "weapon_main")
	if item_id == "" or not item_id.begins_with("gen_"):
		return  # Static items don't track wear

	var current_dur: int = weapon.get("durability", 1)
	var new_dur: int = maxi(0, current_dur - int(ceil(fragility)))
	ItemSystem.update_item_durability(item_id, new_dur)
	if new_dur == 0:
		combat_log.emit("%s's %s has broken!" % [unit.unit_name, weapon.get("name", "weapon")])
```

- [ ] **Call `_deduct_weapon_durability`** in `attack_unit()` after the hit resolves (after `_process_weapon_on_hit_procs`, still inside the `if hit:` block):

```gdscript
		# --- Weapon durability ---
		_deduct_weapon_durability(attacker)
```

- [ ] **Verify** — in the test launcher, generate an obsidian weapon (fragility 3.0), equip it, run 10 attacks, confirm durability goes down by 3 per attack and the "broken" log appears at 0.

- [ ] **Commit**
```bash
git add scripts/autoload/combat_manager.gd
git commit -m "fix: armor pierce in damage calc, weapon on-hit passives, durability deduction per attack"
```

---

## Checklist Review

After all tasks are committed:

- [ ] Sword element is `space` in equipment_tables.json
- [ ] `club` appears in weapon_bases, shares `maces` skill, element `earth`
- [ ] Generating a weapon in hell realm never produces damascene or higher
- [ ] Obsidian weapon has `crit_chance` in its stats
- [ ] A wooden sword cannot be generated (type restriction falls back to bone/iron)
- [ ] `_pct` keys don't appear in generated item stats dicts
- [ ] Dagger base crit (+5) shows up in `get_crit_chance()` during combat
- [ ] Mace armor_pierce (+5) reduces defender armor in `calculate_physical_damage`
- [ ] A weapon with `poison_chance` occasionally applies Poisoned on hit
- [ ] An obsidian weapon's durability drops 3 per attack (fragility 3.0)
- [ ] A vajra weapon's durability never changes (fragility 0.0)
