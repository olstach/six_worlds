# Companion System Design
**Date:** 2026-03-01

---

## Overview

Companions are named, pre-authored characters with a defined identity and build who can be recruited during a run. They are full party members: player-controlled in combat, sharing XP equally, and developable through the same character sheet used for the main character.

---

## 1. Data Structure

### companions.json

One entry per companion. Example:

```json
{
  "companions": {
    "karnak": {
      "id": "karnak",
      "name": "Brother Karnak",
      "race": "red_devil",
      "background": "soldier",
      "flavor_text": "A red devil cast out of the Infernal Guard for showing mercy to a damned soul. He carries the contradiction quietly.",
      "portrait": "",
      "recruitment_cost": 150,

      "build_weights": {
        "strength": 3, "constitution": 2, "finesse": 1, "awareness": 1,
        "martial_arts": 5, "unarmed": 3, "yoga": 2, "fire_magic": 1
      },

      "fixed_starter": {
        "skills": { "martial_arts": 2 },
        "known_spells": []
      },

      "fixed_spells": ["flame_strike"],
      "random_spells": { "count": 2 },

      "fixed_equipment": {},
      "starting_equipment": {
        "weapon_set_1": { "main": "sword", "off": "" },
        "chest": "light_armor"
      },
      "fixed_items": []
    }
  }
}
```

### In-memory character dict extensions

Companions are standard `BASE_CHARACTER` dicts with these extra fields:

| Field | Type | Description |
|-------|------|-------------|
| `companion_id` | String | Links back to companions.json |
| `flavor_text` | String | Short paragraph, shown on recruitment and as hover tooltip |
| `portrait` | String | Path to portrait image (empty until art pass) |
| `build_weights` | Dictionary | Skill/attribute weights used for auto-distribution |
| `autodevelop` | bool | Whether new XP is spent automatically |
| `free_xp` | int | Post-recruitment XP pool available to spend |
| `overflow_investments` | Dictionary | Tracks manual investments during overflow mode: `{"skill_id": count}` |

The existing `xp` field tracks lifetime total XP (used for power comparisons and save/load). `free_xp` is the separately tracked spendable pool.

---

## 2. Build Weights

Weights are relative — any positive numbers work, the system normalises them automatically.

**How distribution works:**
1. At recruitment, calculate the player's total **spent XP** (sum of all attribute and skill costs already purchased). This becomes the companion's budget.
2. Sum all weights to get a total.
3. Each weight becomes a fraction of the budget: `weight / total_weights`.
4. The system spends each fraction on that stat, buying as many levels as the budget allows.
5. `fixed_starter` skills are applied first, before distribution.
6. If a stat hits its cap, surplus redistributes proportionally among remaining uncapped weighted stats.

**Important nuance:** attributes and skills have different cost curves. Skills reach higher effective levels more cheaply than attributes at the same weight. Weight them accordingly — a physical fighter probably wants high strength weight but even higher weapon skill weight.

Omitting a stat from weights entirely means autodevelop will never touch it, regardless of surplus.

---

## 3. Recruitment Flow

### Entry points

**A. Event-based:** A map event choice calls `CompanionSystem.recruit("companion_id")`. The event handles the narrative; the system handles the mechanics.

**B. Location tab:** Taverns, camps, and similar locations have a Companions tab listing available companions with name, one-line description, and cost. Clicking hire calls the same function.

Which companions appear at a location is defined either in the event/shop JSON or via a `recruitment_locations` field on the companion (e.g. `["any_tavern", "event:devil_deserter"]`).

### What `recruit()` does

1. Load companion definition from `companions.json`
2. Build a fresh `BASE_CHARACTER` dict, apply race + background
3. Apply `fixed_starter` skills and spells
4. Calculate player's spent XP → use as auto-distribution budget
5. Auto-distribute budget via `build_weights` (with cascading surplus on cap)
6. Apply `fixed_spells` to `known_spells`
7. Pick `random_spells.count` spells weighted by the companion's magic school weights, capped at the companion's actual skill levels
8. Apply `fixed_equipment` to equipment slots
9. Generate procedural items for remaining `starting_equipment` slots, scaled to party power level
10. Add `fixed_items` to inventory
11. Set `free_xp: 0`, `autodevelop: false`, `overflow_investments: {}`
12. Deduct `recruitment_cost` from party gold
13. Call `CharacterSystem.add_companion()`
14. Show recruitment popup

### Recruitment popup

```
┌─────────────────────────────┐
│        Brother Karnak       │
│     Red Devil · Soldier     │
│                             │
│  A red devil cast out of    │
│  the Infernal Guard for     │
│  showing mercy to a damned  │
│  soul. He carries the       │
│  contradiction quietly.     │
│                             │
│         [ Continue ]        │
└─────────────────────────────┘
```

The companion's initial stats are **locked** — no respec of the auto-distributed build. All new XP earned from this point goes into `free_xp` for the player to allocate freely.

---

## 4. XP Sharing & Solo Scaling

All party members receive equal XP after every combat or XP-granting event, with a multiplier based on current party size:

| Party size | XP multiplier |
|------------|---------------|
| 1 | ×1.5 |
| 2 | ×1.25 |
| 3–4 | ×1.0 (baseline) |
| 5–6 | ×0.85 |
| 7–8 | ×0.7 |

Party sizes 7–8 are only reachable with high Leadership (level 9 gives max party of 8). `max_party_size` in CharacterSystem needs updating from 6 to 8.

XP earned is added to both `xp` (lifetime total) and `free_xp` (spendable pool). If autodevelop is on, `free_xp` is spent immediately and the player never sees it accumulate.

Companions do not receive back-pay for XP earned before recruitment — their auto-distributed stats at recruitment already account for the party's current power level.

---

## 5. Autodevelop

A toggle button in the companion's character sheet Stats tab, near the free XP display.

### Normal mode (build_weights active)

When new `free_xp` arrives, the system spends it on the highest-weight uncapped stat. If a stat is capped, surplus flows to the next highest weight, cascading until all free XP is spent.

### Overflow mode (all weights maxed)

Triggered when every stat in `build_weights` has hit its cap.

1. **One-time popup fires:** *"[Name] has mastered their calling. You can direct their growth, or let them find their own way."*
2. Autodevelop pauses until the first investment decision.
3. If autodevelop is on and new XP arrives with no entries in `overflow_investments` yet → the system **randomly picks one skill or attribute** and invests there, seeding `overflow_investments`.
4. From then on, emergent weights apply:
   - Each stat in `overflow_investments` gets weight `count + 1`
   - Every other stat gets weight `1`
5. Any time the player manually puts points into a stat, that gets added to `overflow_investments`, incrementing its count. Player choices always influence future autodevelop decisions — the random seed is just the first data point.

A companion left fully on autopilot develops a coherent but slightly random second chapter. A player who cares can redirect at any time by manually investing in a preferred direction.

---

## 6. UI

### Character selector panel

A compact row of buttons at the top of the Skills, Equipment, Spellbook, and Perks tabs. Each party member gets a button showing their name (eventually portrait). The active character is highlighted. Clicking switches the entire tab to show that character's data.

Hovering over a companion's name (or later their portrait) shows a tooltip with their flavor text.

### Stats tab additions (companions only)

- **Autodevelop toggle** near the free XP display (on/off)
- Debug **+10 XP** button replaced with **+100 XP**, moved to the bottom of the Stats tab, labelled DEV

### Party tab

Shows all current party members. Click any member to open their character sheet.

---

## 7. Combat

Companions are player-controlled units (Disgaea-style). They use `Team.PLAYER` and are handled by the existing combat system with no special-casing needed.

**Bleed-out and death:** Same 3-turn bleed-out as the main character. If not healed in time, the companion dies permanently. Revival is only possible via the appropriate spell (raise dead) or at rare temple locations for a high gold cost and karma implications.

---

## 8. Notes for Content Authors

- Weights can be any positive numbers — use whatever feels intuitive (e.g. 1/2/3 or 5/10/15, same result)
- Leave stats out of `build_weights` entirely to prevent autodevelop from ever touching them
- `fixed_starter` establishes the companion's baseline identity regardless of power level — at minimum, give each companion one or two skills here
- `fixed_equipment` is for unique/cursed/story-significant items; `starting_equipment` handles the rest procedurally
- `fixed_items` is for inventory items the companion always carries (potions, tools, etc.)
- Random spells are drawn from schools matching the companion's magic skill weights — a pure warrior with no magic weights will get no random spells
