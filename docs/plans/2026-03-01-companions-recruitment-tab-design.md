# Companions Recruitment Tab — Design

**Date:** 2026-03-01
**Status:** Approved

---

## Overview

Add a Companions tab to the shop UI so named companions can be recruited at taverns and appropriate locations, in addition to the existing event-based recruitment path.

---

## Architecture

The tab slots into the existing shop system with minimal changes:

- `shop_ui.tscn` gets a fourth tab: **Companions** (ScrollContainer → VBoxContainer)
- `shop_ui.gd` gains `_populate_companions_tab()` and a small change to `_setup_tabs()`
- `shops.json` gets a test tavern shop with `available_companions`
- No changes to CompanionSystem or CharacterSystem — `CompanionSystem.recruit()` already handles gold deduction, party addition, and the recruitment popup

**Tab visibility rule:** If `current_shop.available_companions` is non-empty, always show the Companions tab regardless of shop type. This is more flexible than adding a new shop type — any shop (tavern, refugee camp, etc.) can offer companions by adding the field.

---

## Companion Panel Layout

One panel per available companion, stacked vertically, up to 3:

```
┌─────────────────────────────────────────┐
│ Brother Karnak               750 gold   │
│ Red Devil · Guard                       │
│ ──────────────────────────────────────  │
│ A red devil cast out of the Infernal    │
│ Guard for showing mercy to a damned     │
│ soul. He carries the contradiction...  │
│                                         │
│                             [Recruit]   │
└─────────────────────────────────────────┘
```

- **Name**: large, prominent
- **Identity line**: `{Race} · {Background}` in muted color
- **Separator**
- **Flavor text**: word-wrapped, muted color, ~3-4 lines
- **Gold cost**: right-aligned on name row, gold color if affordable / red if not
- **Recruit button**: right-aligned bottom, disabled if party full (8) or can't afford

Already-recruited companions are **hidden** — they exist as unique individuals, not shop stock.

After recruiting: `CompanionSystem.recruit()` handles everything, then the tab refreshes (companion disappears).

---

## Data Changes

### companions.json
- Raise Karnak's `recruitment_cost` from 150 → **750** (tavern price; event recruitment stays free)

### shops.json
Add a test tavern:
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
  "training": { "attributes": [], "skills": [] }
}
```

---

## Pricing Philosophy

Companions are the most powerful upgrade available — they scale indefinitely, contribute to all party checks, and add a full combatant. Pricing reflects this:

| Tier | Description | Price |
|------|-------------|-------|
| Common | Basic fighter/generalist | 600–800g |
| Skilled | Specialist or unusual build | 1,000–1,500g |
| Rare | Powerful, story-relevant | 2,000–3,000g |

Event-based recruitment is often free or cheap — that's a story beat. Tavern recruitment is a conscious economic investment.

---

## Scope

**Modify:**
- `scripts/ui/shop_ui.gd`
- `scenes/ui/shop_ui.tscn`
- `resources/data/shops.json`
- `resources/data/companions.json`

**No changes needed:**
- `scripts/autoload/companion_system.gd`
- `scripts/autoload/character_system.gd`
- `scripts/autoload/shop_system.gd`
