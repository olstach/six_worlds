# Rest & Time System Design

> **For agentic workers:** Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this spec task-by-task.

**Goal:** Add a continuous time clock to the overworld and a three-tier rest mechanic that replaces the per-step food drain, giving food/herbs/scrap strategic purpose and wiring `PsychologySystem.decay_toward_baseline()`.

**Philosophy:** Time flows naturally as the party moves and waits — no hard deadline or countdown pressure. Days accumulate as a foundation for future cyclic events (lunar calendar, karma multipliers, special days). Rest is a deliberate resource decision, not a free heal button.

---

## 1. Time System

### Data (GameState)

```gdscript
var hours_elapsed: int = 0          # Total hours since run start. Never resets mid-run.
const HOURS_PER_STEP: int = 2       # Each overworld step (move or Wait) advances this.
const HOURS_PER_REST: int = 8       # Additional hours advanced when party rests.
const HOURS_PER_DAY:  int = 24

signal day_changed(new_day: int)    # Fired when current_day increments. Future hook for lunar events.

# Computed (no stored state needed):
var current_day: int:
    get: return hours_elapsed / HOURS_PER_DAY

var hour_of_day: int:
    get: return hours_elapsed % HOURS_PER_DAY

func get_time_of_day_label() -> String:
    var h = hour_of_day
    if   h >= 4  and h < 8:  return "Dawn"
    elif h >= 8  and h < 12: return "Morning"
    elif h >= 12 and h < 16: return "Afternoon"
    elif h >= 16 and h < 20: return "Evening"
    elif h >= 20:             return "Night"
    else:                     return "Deep Night"   # 0–3
```

### Advancing Time

- Every overworld step (player moves one tile) calls `GameState.advance_time(HOURS_PER_STEP)`.
- The Wait action also calls `GameState.advance_time(HOURS_PER_STEP)`.
- Rest calls `GameState.advance_time(HOURS_PER_REST)` after applying healing.
- `advance_time(hours)` increments `hours_elapsed`, checks if `current_day` crossed a boundary, and emits `day_changed` if so.

### Save / Load

`hours_elapsed` is saved and restored alongside other GameState run data.

---

## 2. Wait Action

- **Key:** Space (overworld only — no conflict with event display since that has its own `_input` handler and consumes the event)
- **Effect:** Advances time by `HOURS_PER_STEP`, triggers one mob patrol step (requires `MapManager.tick_mobs()` — a new method that runs the patrol loop without moving the player), ticks overworld DoT statuses — otherwise identical to moving one tile
- **No toast** — silent by default to avoid spam when holding Space
- **Not available** during events, combat, or shop screens (input not reaching overworld while those are open)

---

## 3. Rest System

### Where

Anywhere on the overworld map. Rest button always visible in HUD.

### Tiers

| Tier | Name | Food cost | Herbs | Scrap | HP / Mana / Stamina restored | Pressure decay | Durability restored |
|------|------|-----------|-------|-------|------------------------------|----------------|---------------------|
| 1 | Quick Rest | 2 × party size | — | — | 40% of max | 20 toward baseline | — |
| 2 | Camp | 4 × party size | 2 | 2 | 70% of max | 40 toward baseline | 20% of max |
| 3 | Full Rest | 6 × party size | 4 | 4 | 100% of max | full reset to baseline | 100% |

All tiers advance time by `HOURS_PER_REST = 8` regardless.

### Healing Formula

```
restored = floor(max_stat * tier_pct)
           + floor(max_stat * medicine_bonus)
```

Medicine bonus per tier (best Medicine skill in party):
- Medicine 1–3: +5% to all tiers
- Medicine 4–6: +10%
- Medicine 7–9: +15%
- Medicine 10:  +20%

Caps at 100% of max stat total.

### Pressure Decay

Calls `PsychologySystem.decay_toward_baseline(character, decay_amount)` for each party member:
- Tier 1: `decay_amount = 20.0`
- Tier 2: `decay_amount = 40.0`
- Tier 3: `decay_amount = 100.0` (effectively resets to baseline since max pressure is ±100)

### Durability Restore

Tier 2/3 restore item durability for all equipped items on each party member. For each equipped item with a `durability` field, increase it by the tier percentage (capped at `max_durability`). This requires a helper function `_restore_party_durability(pct: float)` in `overworld.gd` that iterates equipped slots — the existing Smithing passive in `process_scrap_step` only does per-step micro-repairs and is not reusable here.

### Perk Hook

After restoring each character, call:
```gdscript
_process_rest_perks(character, tier)
```
This function is empty in this implementation but wired so future perks (e.g. Safe Campsite, Yoga 7 "Lucid Rest") can hook in without touching the rest logic.

### UI

- **Rest button** in overworld HUD (bottom bar or side panel)
- **Rest panel** (simple popup): three tier buttons, each showing costs and what will be restored
- Tiers the party cannot afford are greyed out with a tooltip explaining what's missing
- On confirm: resources deducted → healing applied → time advanced → panel closes → toast:  
  `"Party rested. Day 5 — Morning."`

---

## 4. Food System Rework

### What is removed

| Component | Current behaviour | New behaviour |
|-----------|-------------------|---------------|
| `process_food_step()` | Drains food every step; deals starvation damage when empty | Removed (becomes no-op) |
| `process_herbs_step()` | Adds per-step HP bonus when herbs available | Removed |
| Per-step HP heal (1% when fed) | Heals 1% max HP every step | Removed |
| `steps_without_food` | Tracks starvation counter | Removed |

### What changes purpose

| Resource | Old role | New role |
|----------|----------|----------|
| Food | Per-step drain | Rest fuel (Tier 1–3 costs) |
| Herbs | Per-step heal bonus | Rest quality (Tier 2–3 costs + Medicine bonus) |
| Scrap | Per-step durability repair | Per-step durability repair (unchanged) + Tier 2–3 rest cost |

Scrap retains its existing Smithing passive repair role — rest just adds an additional consumption path.

### Starting supplies

Starting values will need tuning. Rough target: starting supplies support ~2 Quick Rests or ~1 Camp for a party of 4 without resupplying. Shops become the primary resupply vector.

---

## 5. HUD Changes

Add time display to the overworld HUD, near the supply counters:

```
Day 4 — Evening
```

- `current_day` is 0-indexed internally; display as `current_day + 1` ("Day 1" on day 0)
- Updates whenever `hours_elapsed` changes
- No day/night visual changes to the map in this implementation (future work)

---

## 6. Files Affected

| File | Change |
|------|--------|
| `scripts/autoload/game_state.gd` | Add `hours_elapsed`, `advance_time()`, `day_changed` signal, computed properties, save/load |
| `scripts/overworld/overworld.gd` | Wait action (Space), call `advance_time` on move, rest button + panel, remove food/herb step logic, add time HUD label |
| `resources/data/supplies.json` | Update starting food/herb amounts to match new economy |
| `scripts/autoload/psychology_system.gd` | No changes — `decay_toward_baseline()` already implemented |
| `scripts/autoload/combat_manager.gd` | No changes |

No new autoloads required. Rest logic lives in `overworld.gd`.

---

## 7. Out of Scope (Future Work)

- Day/night visual changes on the overworld map
- Lunar calendar events (`day_changed` signal is the hook — no consumers yet)
- Realm-specific rest events ("something stirs in the night" on rest in hell)
- New rest perks (Safe Campsite already in perks.json but not wired)
- Yoga skill improving pressure decay during rest
- Blocking rest when a mob is adjacent
