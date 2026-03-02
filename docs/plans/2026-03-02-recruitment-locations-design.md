# Recruitment Locations Design
**Date:** 2026-03-02

## Overview

Add 5 new map location types that each include a companion recruitment tab, making companions findable during normal play. All locations extend the existing shop system — no new scene types needed.

The locations keep consistent names across all realms. Realm-specific flavour lives in the `description` field and future flavor text slots.

---

## Locations

### 1. Teahouse
**Tabs:** Rest · Companions
**Hell description (cold):** "A dim waystation. The barkeeper keeps a pot of Lapsang Souchong going at all times — the smoke is the closest thing to warmth here."
**Hell description (fire):** "A smoky roadhouse. Everything smells of char. The tea tastes like it was brewed in a volcano, which it probably was."
**Future:** Gossip/rumor slot above the rest buttons (HoMM barkeep style).

**Rest mechanic — tiered options:**
- **"Order a teapot"** — restores 50% of missing HP/MP/Stamina for all party members. Cost = `teapot_cost` from shop data, scaled by `price_modifier`.
- **"Stay for the night"** — restores 100% (full party). Cost = `night_cost` from shop data.

Cost stored in shop data:
```json
"rest": {
  "teapot_cost": 30,
  "teapot_restore_pct": 50,
  "night_cost": 80,
  "night_restore_pct": 100
}
```
Hell price_modifier: 1.2× (so 36 / 96 gold in hell).

---

### 2. Mercenary Guild
**Tabs:** Items · Companions
**Items:** Weapons and armour (same category as weapon_master shop).
**Hell description:** "A fortified post where demonic soldiers hire out between assignments. Their weapons are used but functional."

---

### 3. Veterans' Camp
**Tabs:** Training · Companions
**Training mechanic:** Two random combat skills, selected at map generation time and stored in the map object data. Each slot can be used by exactly one character; once claimed it shows as "Taken" permanently for that map run.

Combat skill pool (all 9): `swords, martial_arts, ranged, daggers, axes, unarmed, spears, maces, armor`

Map object data format (set by generator):
```json
{
  "selected_skills": ["swords", "maces"],
  "claimed": [false, false]
}
```

**Hell description:** "A camp of soldiers who survived long enough to have something to teach. They charge for lessons — nothing is free in hell."

---

### 4. Yogini Circle
**Tabs:** Spells · Supplies · Companions
**Spells:** Mixed schools (white, space, air, summoning, enchantment — non-destructive magic).
**Supplies:** Reagents, scrolls, alchemist's pouches, spell components.
**Hell description:** "A circle of Dakinis — fierce, half-wild tantric practitioners. They trade knowledge for gold, no questions asked."

---

### 5. Town
**Tabs:** General Shop · [Random Secondary] · Companions
**Secondary tab:** Determined at map generation time by picking one town variant from a pool. Three variants:
- `hell_town_weapons` — secondary tab is weapons/armour
- `hell_town_magic` — secondary tab is spells + magic items
- `hell_town_supplies` — secondary tab is reagents, food, utility items

**Hell description:** "A cluster of hovels that qualifies as a settlement by sheer stubbornness. Someone here is always selling something."

---

## Architecture

### Data changes
| File | Change |
|---|---|
| `shops.json` | Add shop entries for all hell variants; add new `shop_types` (teahouse, mercenary_guild, veteran_camp, yogini_circle, town) |
| `hell.json` | Add entries to `cold_hell` and `fire_hell` object_pools |
| `hell_events.json` | Add shop-outcome events for each new location |

### Code changes
| File | Change |
|---|---|
| `scenes/ui/shop_ui.tscn` | Add Rest tab to TabContainer |
| `scripts/ui/shop_ui.gd` | `_populate_rest_tab()`, rest purchase handlers, veteran camp "claimed" slot logic |
| `scripts/map_gen/map_generator.gd` | Veteran's Camp: pick 2 random skills on placement; Town: pick variant on placement |

### shop_ui.gd Rest tab behaviour
- On open: calculate cost for each tier based on current party HP/MP/Stamina vs max.
- "Order a teapot" / "Stay for the night" buttons show cost and disable if unaffordable.
- On purchase: apply `restore_pct` to HP, MP, and Stamina for every party member; deduct gold.

### Veteran's Camp training tab behaviour
- Reads `selected_skills` and `claimed` from the map object data (passed into the shop via the event outcome's `location_data` field).
- Claimed slots show the skill name greyed out with "Taken" label, no buy button.
- On purchase: flip the `claimed` flag in MapManager's stored object data.

### Companions placeholder
All new locations include `"available_companions": ["karnak"]` for testing. Actual companion rosters will be added in the next pass.

---

## Spawn weights (hell.json additions)

| Location | Pool | Icon | one_time | weight | tag |
|---|---|---|---|---|---|
| Teahouse | both | `rest` | false | 2 | `rest` |
| Mercenary Guild | both | `shop` | false | 1 | `shop` |
| Veterans' Camp | both | `npc` | false | 2 | — |
| Yogini Circle | both | `shrine` | false | 1 | — |
| Town | both | `shop` | false | 1 | `shop` |
