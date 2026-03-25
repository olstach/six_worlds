# Six Worlds - Project Analysis Report

**Date:** 2026-03-21
**Scope:** Full codebase analysis — all 14 autoloads, 16 scripts, 11 scenes, 23 data files

---

## Overall Verdict

The architecture is **solid and well-connected**. All 14 autoload singletons are properly registered, all signal connections match real declarations, all scene node paths match .tscn files, and there are no orphaned scripts. The codebase shows good engineering practices with proper signal-driven communication between systems.

That said, there are specific bugs, data gaps, and incomplete features documented below.

---

## BUGS (will cause runtime errors)

### 1. `PerkSystem.get_perk()` does not exist — called by EnemySystem
- **File:** `scripts/autoload/enemy_system.gd:598`
- **Problem:** Calls `PerkSystem.get_perk(perk_id)` but the actual method is `PerkSystem.get_perk_data(perk_id)` (defined at `perk_system.gd:398`)
- **Impact:** Will crash at runtime whenever an enemy with `guaranteed_perks` is generated (affects most hell & hungry ghost elite enemies)
- **Fix:** Change `get_perk` to `get_perk_data` on line 598

### 2. CompanionSystem accesses private member
- **File:** `scripts/autoload/companion_system.gd:185`
- **Problem:** Accesses `CharacterSystem._spell_database` (private by GDScript convention)
- **Impact:** Works but fragile — will break silently if CharacterSystem renames the internal variable
- **Fix:** Use the public `CharacterSystem.get_spell_database()` method instead

---

## MISSING DATA REFERENCES (will cause silent failures)

### Missing Item (1)
| ID | Referenced By |
|----|--------------|
| `ember_core` | `shops.json` → shop `hell_eternal_fire` |

### Missing Spells (4)
| ID | Referenced By |
|----|--------------|
| `immolate` | `shops.json` → shop `demon_sorcerer` |
| `poison_dart` | `shops.json` → shop `demon_sorcerer` |
| `splash` | `shops.json` → shop `general_store` |
| `vampiric_touch` | `shops.json` → shop `demon_sorcerer` |

### Missing Perks (4)
| ID | Referenced By |
|----|--------------|
| `backstab` | `hell_archetypes.json` → `hell_green_devil_backstabber` |
| `heavy_swing` | `hell_archetypes.json` → `hell_red_devil_berserker` |
| `steady_aim` | `hell_archetypes.json` → `hell_green_devil_sniper` |
| `reassemble` | `hungry_ghost_archetypes.json` → `hg_bone_horror` |

---

## REALM DATA PIPELINE GAPS

The game has 6 realms. Here is what data exists for each:

| Data Layer | Hell | Hungry Ghost | Animal | Human | Asura | God |
|------------|:----:|:------------:|:------:|:-----:|:-----:|:---:|
| Races defined | YES (6) | YES (7+) | YES (3+) | YES (4+) | YES (2+) | YES (2+) |
| Map config | YES | YES | -- | -- | -- | -- |
| Enemy archetypes | YES (43) | YES (40) | -- | -- | -- | -- |
| Enemy encounters | YES (50) | YES (45) | -- | -- | -- | -- |
| Events file | YES | **MISSING** | -- | -- | -- | -- |

### Key gap: Hungry Ghost has NO events file
The `resources/data/events/` folder contains only `hell_events.json`. The EventManager dynamically loads `*_events.json` files from that folder. Hungry Ghost realm has a full map config and encounters but **no events will fire** when exploring it because there's no `hungry_ghost_events.json`.

(Note: Races.json does define races for all 6 realms, so the Bardo/reincarnation screen works for all realms, but actual gameplay only functions in Hell and partially in Hungry Ghost.)

---

## INCOMPLETE/STUB SYSTEMS

### 1. Free XP Tracking
- **File:** `scripts/ui/new_character_sheet.gd:60`
- Both "Total XP" and "Free XP" labels show the same value (`current_character.xp`)
- The system doesn't distinguish between earned XP and spent XP
- Has a `# TODO: track spent vs free` comment

### 2. Karma Purification
- **File:** `scripts/autoload/karma_system.gd:188-190`
- `can_purify_karma()` is hardcoded to return `false`
- `purify_karma()` method exists but is unreachable
- Has `# TODO: Check if player has required ritual items`

### 3. Background Data for Reincarnation
- **File:** `scripts/autoload/karma_system.gd:163-173`
- `select_random_background()` only has hardcoded backgrounds for 3 races: `red_devil`, `human`, `naga`
- All other races (13+) fall back to `["wanderer"]`
- Has `# TODO: Load from background data files`

### 4. Followers List in Main Menu
- **File:** `scripts/ui/main_menu.gd:227`
- `# TODO: Get actual followers from a system (e.g., GameState.get_followers())`
- Followers section exists in UI but doesn't populate from any data source

### 5. Background Data Files
- **File:** `scripts/autoload/character_system.gd:381`
- `# TODO: Replace with proper background data files per background`
- Falls back to hardcoded skills when no background data exists

---

## DOCUMENTATION DISCREPANCY

**CLAUDE.md says "Crafting"** is an Earth skill, but `skills.json` defines it as **"Smithing"**:
- ID: `smithing`
- Name: "Smithing"
- Element: earth
- Description: "Passively repairs equipment and restores ammo - consumes Scrap"

CLAUDE.md should be updated to match the actual codebase.

---

## SYSTEMS STATUS SUMMARY

| System | Status | Notes |
|--------|--------|-------|
| Character creation & progression | **Working** | XP tracking incomplete |
| Karma & reincarnation | **Working** | Purification stub, limited backgrounds |
| Event/dialogue system | **Working** | Hell only (no hungry_ghost_events.json) |
| Tactical combat (grid-based) | **Working** | Full system with spells, items, ammo |
| Overworld map & movement | **Working** | Hell + Hungry Ghost maps |
| Shop system | **Working** | 9 missing item/spell references |
| Save/load system | **Working** | |
| Companion recruitment | **Working** | Private member access issue |
| Perk/upgrade system | **Working** | get_perk vs get_perk_data bug |
| Item & equipment system | **Working** | 185 items defined |
| Ammo system | **Working** | Newest feature |
| Audio system | **Working** | |
| Quest system | **Working** | 3 quests defined |
| Supply/logistics system | **Working** | |
| Enemy generation | **Buggy** | Crashes on guaranteed_perks |

---

## PRIORITY RECOMMENDATIONS

### Critical (runtime crashes)
1. Fix `enemy_system.gd:598` — change `get_perk` to `get_perk_data`

### High (missing content blocking gameplay)
2. Create `resources/data/events/hungry_ghost_events.json` — Hungry Ghost realm has map + encounters but no events
3. Add the 4 missing spells to `spells.json` (immolate, poison_dart, splash, vampiric_touch)
4. Add the 4 missing perks to `perks.json` (backstab, heavy_swing, steady_aim, reassemble)
5. Add `ember_core` item to `items.json`

### Medium (incomplete features)
6. Implement free vs spent XP tracking in CharacterSystem
7. Expand `select_random_background()` to cover all races
8. Fix `companion_system.gd:185` to use public `get_spell_database()` method
9. Update CLAUDE.md: "Crafting" → "Smithing"

### Low (stubs for future)
10. Implement karma purification system
11. Connect followers list to actual data
12. Load background data from files instead of hardcoding
