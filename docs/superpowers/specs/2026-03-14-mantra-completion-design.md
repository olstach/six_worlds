# Mantra System Completion — Design Spec
Date: 2026-03-14

## Overview

Completes the mantra system by implementing four missing subsystems: concentration interrupts, AI chanter-targeting, new summon infrastructure needed by the deferred mantras, and the four previously-deferred Deity Yoga / per-turn summon effects.

The per-turn aura effects and stat-burst Deity Yoga for all 26 mantras are already implemented. This spec covers only the remaining work.

---

## Part 1: Concentration System

### What Breaks Concentration

Three conditions interrupt all active mantras on a unit:

1. **Heavy hit** — a single `apply_damage()` call deals ≥ 15% of the unit's `max_hp`.
2. **Hard CC** — any of the following statuses is successfully applied: Stun, Fear, Charm, Confused, Berserk.
3. **Spell casting** — the unit casts any spell (after the spell resolves).

When concentration breaks, `active_mantras` is cleared, `mantra_stat_bonuses` is cleared, and a message is logged: `"[name]'s concentration breaks!"`.

### Continuous Recitation (Ritual 3 perk)

If the unit has the `continuous_recitation` perk (already defined in perks.json):
- Condition 3 (spell casting) does **not** interrupt mantras.
- Conditions 1 and 2 still apply.

### Implementation

Single helper in `combat_manager.gd`:

```
_interrupt_mantras(unit: Node, reason: String) -> void
```

- Returns immediately if `unit.active_mantras.is_empty()`.
- Clears `unit.active_mantras`, `unit.mantra_stat_bonuses`.
- Removes `unit` from `_lord_of_death_casters` if present (see Part 4).
- Emits `combat_log` with the reason message.

Called from:
- `apply_damage(unit, damage, damage_type)` — after damage is applied, check `float(damage) / float(unit.character_data.get("max_hp", 1)) >= 0.15`. Use the `damage` input parameter (post-absorption, i.e., damage actually received) for the threshold check. This is intentional: absorbed hits that deal less than 15% effective damage do not break concentration.
- `_apply_status_effect()` — after the status is successfully applied, if the status name is one of the hard CC types listed above.
- Spell cast flow in `combat_arena.gd` — after `CombatManager.cast_spell()` returns success, if the caster has active mantras and does **not** have `continuous_recitation`.

---

## Part 2: AI Mantra Awareness

The existing `_find_nearest_enemy()` function in `combat_arena.gd` selects attack targets by minimum tile distance. The function has a taunt short-circuit at the top: if any enemy has `taunt_active`, that unit is returned immediately. The effective-distance change applies only to the normal selection loop (which runs when no taunt is active). This is acceptable — a taunting unit overrides all targeting by design.

In the normal loop, replace the raw distance comparison with an **effective distance** calculation:

```
effective_distance = actual_distance - (3 if target.active_mantras.size() > 0 else 0)
```

Pick the target with the lowest `effective_distance`. This makes chanters appear 3 tiles closer than they are, causing enemies to prioritise disrupting them without changing the selection structure.

---

## Part 3: New Summon Infrastructure

### New Fields on CombatUnit (`scripts/combat/combat_unit.gd`)

**`summoner_id: int = 0`**
Set to `caster.get_instance_id()` in `_spawn_summoned_unit()` immediately after the unit node is created. Default 0 = not summoned by anyone.

Helper added to `combat_manager.gd`:
```
_get_owned_summons(caster: Node) -> Array
# Returns all live units in all_units where unit.summoner_id == caster.get_instance_id()
```

**`next_summon_empowered: bool = false`**
Set on the caster by Jeweled Pagoda Deity Yoga. Consumed (cleared) in `_spawn_summoned_unit()` when the next summon spell fires. When true at spawn time: HP × 3, damage × 2, and `has_summon_aura = true` on the spawned unit.

**`has_summon_aura: bool = false`**
Set on an empowered spawned unit. Processed at the start of that unit's own turn via a new function `_process_summon_aura(unit)`. Lasts until the unit dies (no duration counter).

Aura effect (2-tile radius, no line-of-sight requirement):
- Allied units in range: +10 added to their `mantra_stat_bonuses["armor"]`, `["dodge"]`, `["crit_chance"]`.
- Enemy units in range: −10 added to those same keys (yielding negative values).

**Negative stat floor:** All stat getters in `combat_unit.gd` that read from `mantra_stat_bonuses` must clamp their result to 0 or a sensible minimum. Add `maxi(0, ...)` wrapping to the dodge, armor, and crit_chance getters when they add their `mantra_stat_bonuses` contribution.

**`lord_of_death_empowered: bool = false`**
Set on owned summons by Lord of Death DY. In `calculate_physical_damage()` and the spell damage path in `combat_manager.gd`, multiply final damage by 1.3 if the attacker has this flag set.

### Renamed Function

`_process_mantra_effects()` → `_process_mantra_effects_and_auras()`. The new function calls the original mantra-tick logic first, then calls `_process_summon_aura(unit)` if `unit.has_summon_aura` is true.

### New Summon Templates

All five templates below are added to `resources/data/summon_templates.json`.

**`spirit_guardian`** — used by Four Guardian Kings per-turn effect:
```json
"spirit_guardian": {
    "display_name": "Spirit Guardian",
    "base_hp": 1, "base_mana": 0, "base_stamina": 0,
    "actions": 0, "base_damage": 0, "damage_type": "physical",
    "base_initiative": 5, "base_movement": 0,
    "base_dodge": 25, "base_armor": 0, "base_crit": 0, "base_accuracy": 80,
    "resistances": {}, "tags": ["guardian_spirit", "construct"]
}
```
0 actions — never attacks or moves. Destroyed in one hit. Tagged `"guardian_spirit"` (not `"spirit"`) to avoid collision with existing spirit-tagged summons like Unseen Servant.

**`rudra`** — used by Roaring One DY:
```json
"rudra": {
    "display_name": "Rudra",
    "base_hp": 28, "base_mana": 0, "base_stamina": 30,
    "actions": 2, "base_damage": 14, "damage_type": "air",
    "base_initiative": 16, "base_movement": 4,
    "base_dodge": 18, "base_armor": 2, "base_crit": 12, "base_accuracy": 85,
    "resistances": {"air": 30}, "tags": ["air", "spirit", "elemental"]
}
```

**`stone_guardian`** — used by Four Guardian Kings DY:
```json
"stone_guardian": {
    "display_name": "Guardian King",
    "base_hp": 80, "base_mana": 0, "base_stamina": 50,
    "actions": 2, "base_damage": 15, "damage_type": "crushing",
    "base_initiative": 8, "base_movement": 2,
    "base_dodge": 5, "base_armor": 18, "base_crit": 5, "base_accuracy": 80,
    "resistances": {"earth": 25, "physical": 15}, "tags": ["earth", "construct", "guardian"]
}
```

**`zombie`** — used by Lord of Death DY resurrection:
```json
"zombie": {
    "display_name": "Risen Dead",
    "base_hp": 22, "base_mana": 0, "base_stamina": 20,
    "actions": 1, "base_damage": 8, "damage_type": "physical",
    "base_initiative": 4, "base_movement": 2,
    "base_dodge": 5, "base_armor": 4, "base_crit": 3, "base_accuracy": 70,
    "resistances": {"black": 50, "poison": 50}, "tags": ["black", "undead"]
}
```

**`skeleton`** — used by Lord of Death DY resurrection:
```json
"skeleton": {
    "display_name": "Skeleton",
    "base_hp": 18, "base_mana": 0, "base_stamina": 15,
    "actions": 2, "base_damage": 10, "damage_type": "piercing",
    "base_initiative": 8, "base_movement": 3,
    "base_dodge": 10, "base_armor": 6, "base_crit": 5, "base_accuracy": 78,
    "resistances": {"black": 50, "physical": 20}, "tags": ["black", "undead"]
}
```

---

## Part 4: Four Deferred Mantra Effects

### Roaring One — Air 3 (`mantra_of_the_roaring_one`)

**Deity Yoga (fires once at 5 stacks):**

Spawn 1–3 Rudras (`1 + randi() % 3`) near the caster via `_spawn_summoned_unit(caster, "rudra", near_tile, spellpower)`. Try each tile adjacent to the caster in order; skip occupied tiles. Rudras fight for the caster's team until destroyed.

The existing DY stat burst (+5 movement, +15% crit to all allies) is already implemented and remains unchanged. Rudra spawns are added on top.

---

### Four Guardian Kings — Summoning 2 (`mantra_of_the_four_guardian_kings`)

**Per-turn effect (in `_apply_mantra_tick`):**

1. Count owned summons with `"guardian_spirit"` in their tags (via `_get_owned_summons`). If count < 4, find the first free tile within 2 tiles of caster and call `_spawn_summoned_unit(caster, "spirit_guardian", tile, 0)`. Skip if no free tile.
2. For each spirit guardian in owned summons: find the nearest ally unit within 3 tiles of that guardian. Add +3 to that ally's `mantra_stat_bonuses["armor"]`.

**Deity Yoga (fires once at 5 stacks):**

Spawn a Guardian King in each of 4 cardinal directions. For each offset `[(0,-1),(0,+1),(-1,0),(+1,0)]`: try the exact cardinal tile, then search outward up to radius 2 for a free tile. Call `_spawn_summoned_unit(caster, "stone_guardian", tile, 0)` for each. All 4 fight for the caster's team.

The existing DY stat burst (+25 armor, +25 accuracy to all allies) remains unchanged. Guardian King spawns added on top.

---

### Jeweled Pagoda — Summoning 4 (`mantra_of_the_jeweled_pagoda`)

**Per-turn effect (in `_apply_mantra_tick`, `stacks` = `unit.active_mantras[perk_id]`):**

1. Caster gains `+5 * stacks` to `mantra_stat_bonuses["spellpower"]` (replaces the existing flat bonus).
2. For each owned summon: add `stacks * 3` to that summon's `mantra_stat_bonuses["damage"]`, `["armor"]`, `["dodge"]`.

**Deity Yoga (fires once at 5 stacks):**

Set `caster.next_summon_empowered = true`. Log `"[name]'s next summon will be empowered!"`. No other burst effect — the payoff comes when the caster next casts a summon spell, at which point `_spawn_summoned_unit()` consumes the flag (HP × 3, damage × 2, aura set).

The existing placeholder (flat spellpower burst) is removed and replaced entirely by this.

---

### Lord of Death — Black 5 (`mantra_of_the_lord_of_death`)

**Per-turn effect (replaces current implementation in `_apply_mantra_tick`):**

1. **Black summon healing:** For each owned summon with `"black"` in its tags, within 4 tiles of caster: apply `ceil(summon.character_data.get("max_hp", 1) * 0.10)` HP heal.
2. **Stacking enemy damage:** For each enemy within 4 tiles: deal `ceil(spellpower * 0.03 * stacks)` Black damage via `apply_damage()`. `stacks` = `unit.active_mantras[perk_id]`, already the turn counter (1–5).

**Deity Yoga (fires once at 5 stacks):**

1. **Immediate bonus turns:** Add a new function `_run_bonus_turn(unit: Node)` in `combat_arena.gd` that resets `unit.actions_remaining` to `unit.character_data.get("actions", 2)` and then runs the same AI decision logic that fires during the unit's normal turn. For each owned summon, call `_run_bonus_turn(summon)`. Log `"[summon name] acts under the Lord of Death's command!"` for each.
2. **+30% damage:** Set `summon.lord_of_death_empowered = true` on each owned summon. This flag is read in `calculate_physical_damage()` and the spell damage path.
3. **Resurrection on kill:** Add `_lord_of_death_casters: Array = []` to `combat_manager.gd`. When DY fires, append `caster` to this list. In the death-processing code (where units are removed from the field): for each caster in `_lord_of_death_casters`, if the dead unit is an enemy and within 4 tiles, roll `randf() < 0.40` → `_spawn_summoned_unit(caster, ["zombie","skeleton"][randi()%2], death_pos, 0)`.

**Cleanup:** In `_process_mantra_effects_and_auras()` at the start of each caster's turn tick, check: if `"mantra_of_the_lord_of_death"` is **not** in `unit.active_mantras` but `unit` is in `_lord_of_death_casters`, remove it. This covers both the toggle-off path and natural expiry without needing a signal from `CombatUnit`.

---

## Summary of New Fields

### CombatUnit (`scripts/combat/combat_unit.gd`)

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `summoner_id` | `int` | `0` | Instance ID of spawning caster |
| `next_summon_empowered` | `bool` | `false` | Jeweled Pagoda DY: next spawn gets 3×HP / 2×dmg + aura |
| `has_summon_aura` | `bool` | `false` | Empowered summon emits ±10 aura to nearby units |
| `lord_of_death_empowered` | `bool` | `false` | +30% damage on this summon from Lord of Death DY |

### CombatManager (`scripts/autoload/combat_manager.gd`)

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `_lord_of_death_casters` | `Array` | `[]` | Casters with active Lord of Death DY; resurrection check |

---

## Files Changed

| File | Change |
|------|--------|
| `scripts/combat/combat_unit.gd` | 4 new fields; `maxi(0,...)` guards on dodge/armor/crit_chance getters |
| `scripts/autoload/combat_manager.gd` | `_interrupt_mantras()`, `_process_summon_aura()`, `_get_owned_summons()`, `_lord_of_death_casters`, cleanup check; `_apply_mantra_tick` updates (Lord of Death, Four Guardian Kings, Jeweled Pagoda); `_trigger_deity_yoga` updates (all 4 mantras); `_spawn_summoned_unit()` empowered-flag intercept; `calculate_physical_damage()` lord_of_death_empowered check; rename `_process_mantra_effects` |
| `scripts/combat/combat_arena.gd` | Mantra interrupt after spell cast; effective-distance chanter targeting in `_find_nearest_enemy()`; new `_run_bonus_turn()` function |
| `resources/data/summon_templates.json` | Add 5 templates: `spirit_guardian`, `rudra`, `stone_guardian`, `zombie`, `skeleton` |

---

## Out of Scope

- Mantra cooldowns after Deity Yoga fires
- JSON-driven mantra effect data (hardcoded match statements remain)
- Guardian King element-specific resistance auras
- Spirit guardian display in combat log / unit info panel
