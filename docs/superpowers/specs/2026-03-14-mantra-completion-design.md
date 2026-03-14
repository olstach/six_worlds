# Mantra System Completion — Design Spec
Date: 2026-03-14

## Overview

Completes the mantra system by implementing four missing subsystems: concentration interrupts, AI chanter-targeting, new summon infrastructure needed by the deferred mantras, and the four previously-deferred Deity Yoga / per-turn summon effects.

The per-turn aura effects and stat-burst Deity Yoga for all 26 mantras are already implemented. This spec covers only the remaining work.

---

## Part 1: Concentration System

### What Breaks Concentration

Three conditions interrupt all active mantras on a unit:

1. **Heavy hit** — a single damage application deals ≥ 15% of the unit's `max_hp` in one call to `_apply_damage()`.
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
- Emits `combat_log` with the reason message.

Called from:
- `_apply_damage()` — after damage resolves, if `damage_dealt / unit.max_hp >= 0.15`.
- `_apply_status_effect()` — before applying the status, if it is one of the hard CC types listed above.
- Spell cast flow in `combat_arena.gd` — after `CombatManager.cast_spell()` returns success, if the caster has active mantras and does **not** have `continuous_recitation`.

---

## Part 2: AI Mantra Awareness

In the enemy AI target-scoring logic in `combat_arena.gd`, add +30 to the score for any potential target that has at least one active mantra. This causes enemies to naturally prioritize disrupting chanters without requiring special rule branches.

No changes to spell selection logic — the scoring bonus alone is sufficient to shift priority.

---

## Part 3: New Summon Infrastructure

Three new fields added to `CombatUnit` (`scripts/combat/combat_unit.gd`):

### `summoner_id: int = 0`

Set to `caster.get_instance_id()` in `_spawn_summoned_unit()` immediately after the summon unit is created. Default 0 means "not summoned by anyone."

Used to query "which units in `all_units` were summoned by this caster?" with a helper:

```
_get_owned_summons(caster: Node) -> Array[Node]
# Returns all units where unit.summoner_id == caster.get_instance_id()
```

### `next_summon_empowered: bool = false`

Set on the caster by Jeweled Pagoda Deity Yoga. Consumed (set back to false) in `_spawn_summoned_unit()` when the next summon spell is cast by that unit. When true at spawn time:
- Spawned unit's HP is multiplied by 3.
- Spawned unit's damage is multiplied by 2.
- `has_summon_aura` is set to true on the spawned unit.

### `has_summon_aura: bool = false`

Set on a spawned unit. Processed at the start of that unit's turn in a new function `_process_summon_aura(unit)`. Lasts until the unit is destroyed (no duration tracking needed).

Aura effect (2-tile radius, line-of-sight not required):
- Allied units in range: +10 to armor, dodge, and crit_chance added to their `mantra_stat_bonuses`.
- Enemy units in range: −10 to armor, dodge, and crit_chance added to their `mantra_stat_bonuses` (negative values, floored at 0 when stats are read).

`_process_summon_aura(unit)` is called from `_process_mantra_effects_and_auras(unit)` — the existing `_process_mantra_effects()` is renamed to make room for the aura call.

### New Summon Template: `spirit_guardian`

Added to `resources/data/summon_templates.json`:

```json
"spirit_guardian": {
    "display_name": "Spirit Guardian",
    "base_hp": 1,
    "base_mana": 0,
    "base_stamina": 0,
    "actions": 0,
    "base_damage": 0,
    "damage_type": "physical",
    "base_initiative": 5,
    "base_movement": 0,
    "base_dodge": 25,
    "base_armor": 0,
    "base_crit": 0,
    "base_accuracy": 80,
    "resistances": {},
    "tags": ["spirit", "construct"]
}
```

Spirit guardians have 0 actions — they never attack or move. They exist only to provide their armor aura to nearby allies. Destroyed in one hit.

### Spirit Guardian Aura Processing

In `_process_mantra_effects()` (inside the Four Guardian Kings mantra block), for each owned spirit_guardian within 3 tiles of an ally, add +3 to that ally's `mantra_stat_bonuses["armor"]`. This is done inline in the mantra tick rather than via `has_summon_aura`, since it is specific to Guardian Kings and uses a different range and bonus type.

---

## Part 4: Four Deferred Mantra Effects

### Roaring One — Air 3 (`mantra_of_the_roaring_one`)

**Deity Yoga (fires once at 5 stacks):**

Spawn 1–3 Rudras (random: `1 + randi() % 3`) near the caster using `_spawn_summoned_unit()`. The "rudra" template already exists in summon_templates.json. Summoned Rudras fight for the caster's team until destroyed.

The existing DY stat burst (+5 movement, +15% crit to all allies) is already implemented and remains unchanged. The Rudra spawns are added on top.

---

### Four Guardian Kings — Summoning 2 (`mantra_of_the_four_guardian_kings`)

**Per-turn effect (in `_apply_mantra_tick`, runs each turn while mantra is active):**

Count owned spirit_guardian-tagged summons (`_get_owned_summons` filtered by `"spirit"` tag). If count < 4, call `_spawn_summoned_unit(caster, "spirit_guardian", near_caster_tile, 0)`. Attempt to find a free tile within 2 tiles of caster. If no tile is free, skip spawning this turn.

Then, for each spirit_guardian in `_get_owned_summons`: find the nearest ally within 3 tiles of that guardian, add +3 to that ally's `mantra_stat_bonuses["armor"]`.

**Deity Yoga (fires once at 5 stacks):**

Spawn a Guardian King at each of the 4 cardinal offsets from the caster: `(0,-1)`, `(0,+1)`, `(-1,0)`, `(+1,0)`. For each direction: try the exact cardinal tile first, then search outward up to radius 2 if blocked. Use the `"stone_guardian"` template (80 HP, 2 actions, 15 crushing damage, 18 armor — already in summon_templates.json). All 4 fight for the caster's team.

The existing DY stat burst (+25 armor, +25 accuracy to all allies) remains unchanged. The Guardian King spawns are added on top.

---

### Jeweled Pagoda — Summoning 4 (`mantra_of_the_jeweled_pagoda`)

**Per-turn effect (in `_apply_mantra_tick`, `stacks` = current mantra turn counter):**

1. Caster gains `+5 * stacks` to `mantra_stat_bonuses["spellpower"]`. (The caster's summoning spellpower scales up over the 5-stack buildup. Already partially done — the existing implementation sets `+spellpower` once; replace with the per-stack formula.)
2. For each owned summon (via `_get_owned_summons`): add `+stacks * 3` to that summon's `mantra_stat_bonuses["damage"]`, `mantra_stat_bonuses["armor"]`, and `mantra_stat_bonuses["dodge"]`.

**Deity Yoga (fires once at 5 stacks):**

Set `caster.next_summon_empowered = true` and log `"[name]'s next summon will be empowered!"`. The `_spawn_summoned_unit()` function checks `caster.next_summon_empowered` before spawning: if true, apply 3× HP and 2× damage to the template values, set `unit.has_summon_aura = true` on the new unit, then clear `caster.next_summon_empowered`.

The existing placeholder (which sets a flat spellpower bonus) is replaced entirely.

---

### Lord of Death — Black 5 (`mantra_of_the_lord_of_death`)

**Per-turn effect (replaces the current implementation in `_apply_mantra_tick`):**

The current implementation (20% spellpower Black dmg + Feared) is replaced with the faithful spec:

1. **Owned Black summon healing:** For each owned summon with `"black"` in its tags, within 4 tiles of caster: heal `ceil(summon.max_hp * 0.10)` HP.
2. **Enemy stacking damage:** For each enemy within 4 tiles: deal `ceil(spellpower * 0.03 * stacks)` Black damage (scales from 3% at stack 1 to 15% at stack 5). `stacks` = `unit.active_mantras[perk_id]`, which is already the turn counter.

**Deity Yoga (fires once at 5 stacks):**

1. **Immediate bonus turns:** For each owned summon, call `_execute_unit_turn(summon)` directly. This causes each summon to act right now, before returning to normal turn order. Log `"[Summon] acts under the Lord of Death's command!"`.
2. **+30% damage bonus:** For each owned summon, set `summon.lord_of_death_empowered = true` (new bool field on CombatUnit, default false). In `calculate_physical_damage()` and spell damage calculation, if `attacker.lord_of_death_empowered`, multiply damage by 1.3. This persists until the summon dies.
3. **Resurrection trigger:** Register the caster as having Lord of Death DY active via `_lord_of_death_casters: Array[Node]` (module-level var in combat_manager). In `_on_unit_died()`: for each caster in this list, if the dead unit was an enemy within 4 tiles, roll 40% chance to spawn a "zombie" or "skeleton" summon (random) at the death position, owned by that caster.

Cleanup: when the caster's mantra ends (via `_interrupt_mantras()` or toggle-off), remove them from `_lord_of_death_casters`.

---

## New Fields Summary

### CombatUnit (`scripts/combat/combat_unit.gd`)

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `summoner_id` | `int` | `0` | Instance ID of the caster who spawned this unit |
| `next_summon_empowered` | `bool` | `false` | Jeweled Pagoda DY: next summon is 3×HP / 2×dmg |
| `has_summon_aura` | `bool` | `false` | Empowered summon emits a 2-tile +/− 10 stat aura |
| `lord_of_death_empowered` | `bool` | `false` | +30% damage multiplier from Lord of Death DY |

### CombatManager (`scripts/autoload/combat_manager.gd`)

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `_lord_of_death_casters` | `Array[Node]` | `[]` | Units with active Lord of Death DY; used for resurrection check |

---

## Files Changed

| File | Change |
|------|--------|
| `scripts/combat/combat_unit.gd` | Add 4 new fields |
| `scripts/autoload/combat_manager.gd` | `_interrupt_mantras()`, `_process_summon_aura()`, `_get_owned_summons()`, `_execute_unit_turn()` call in DY, `_lord_of_death_casters` tracking, `_apply_mantra_tick` updates (Lord of Death, Four Guardian Kings, Jeweled Pagoda), `_trigger_deity_yoga` updates (all 4 mantras), intercept in `_spawn_summoned_unit()`, `calculate_physical_damage()` lord_of_death_empowered check |
| `scripts/combat/combat_arena.gd` | Mantra interrupt after spell cast, AI targeting score bonus |
| `resources/data/summon_templates.json` | Add `spirit_guardian` template |

---

## Out of Scope

- Mantra cooldowns after Deity Yoga fires (deferred)
- JSON-driven mantra effect data (hardcoded match statements remain)
- Guardian King element-specific resistances (DY Kings use stone_guardian stats as-is)
- Spirit guardian aura display in combat UI
