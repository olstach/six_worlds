# Six Worlds

A tactical RPG roguelike set in the six realms of Tibetan Buddhist cosmology, built in Godot 4.3.

## Overview

Six Worlds combines grid-based tactical combat with Buddhist-themed progression systems. Players reincarnate through different realms based on hidden karma, developing characters through XP-based attribute and skill systems rather than traditional leveling.

**Visual Style**: Tibetan thangka painting aesthetics with pixel art - ornate UI frames with sacred colors (deep reds, golds, indigos).

## Implemented Systems

### Core Singletons (7 AutoLoads)

| System | Description | Status |
|--------|-------------|--------|
| **GameState** | World/realm tracking, boss defeats, party gold, run state | Complete |
| **CharacterSystem** | 7 attributes, 35 skills, derived stats, party management, spell learning | Complete |
| **KarmaSystem** | Hidden karma for 6 realms, reincarnation logic, weighted race selection | Complete |
| **EventManager** | FTL-style events, 3 choice types (grey/blue/yellow), party-wide checks | Complete |
| **CombatManager** | Grid combat, initiative, spells, status effects, AI, terrain, LoS | Complete |
| **ItemSystem** | Equipment database, 12-slot system, inventory, stat bonuses | Complete |
| **ShopSystem** | Buy/sell items, learn spells, train skills, Trade/Charm discounts | Complete |

### Combat System

Tactical grid-based combat (12x8 default) with:

- **Turn Order**: Initiative-based with 2-action system
- **Attacks**: Melee and ranged, Strength/Finesse-based damage, weapon skills
- **326 Spells**: Across 10 schools (5 elements + 5 specializations)
- **Targeting**: Self, single, AoE circle, chain, with visual previews
- **Status Effects**: 80+ effects including DoT, buffs, debuffs, CC
- **Terrain**: Walls, pits, water, difficult terrain; fire/ice/poison/acid/blessed/cursed effects
- **Height & LoS**: Bresenham's algorithm, height advantages for damage/accuracy
- **Deployment**: Role-based positioning with Tactician upgrade for manual placement
- **AI**: Enemies cast spells, reposition for ranged attacks, prioritize targets

### Character Progression

- **No Levels**: XP is pure currency spent freely on attributes/skills
- **7 Attributes**: Strength, Finesse, Constitution, Focus, Awareness, Charm, Luck
- **35 Skills**: Combat (9), Magic (10), General (16) - each tagged with element
- **Elemental Affinities**: Skill points build affinity totals for gradual bonuses
- **Spellbook**: Characters must learn spells before casting

### Event System

FTL-style encounters with:

- **Grey Choices**: Always available basic options
- **Blue Choices**: Require attribute/skill thresholds (ANY party member can qualify)
- **Yellow Choices**: d20 + best party attribute vs DC

### Trading System

- Buy/sell items (50% sell value)
- Learn spells from trainers
- Train attributes/skills for gold
- Trade skill (5%/level) and Charm (2%/point) discounts

### Data Files

| File | Contents |
|------|----------|
| `spells.json` | 326 spells across all schools |
| `statuses.json` | 80+ status effect definitions |
| `items.json` | Weapons, armor, accessories with stats |
| `races.json` | Race definitions with modifiers and caps |
| `skills.json` | 35 skills organized by category/element |
| `shops.json` | 5 sample shops with inventories |
| `upgrades.json` | 10+ upgrade/perk definitions |

## Project Structure

```
six_worlds/
├── project.godot
├── scenes/
│   ├── ui/              # Test launcher, character sheet, event display
│   ├── combat/          # Combat arena scene
│   └── overworld/       # (Future: HoMM-style map)
├── scripts/
│   ├── autoload/        # 7 global singletons
│   ├── combat/          # Arena, grid, unit components
│   ├── ui/              # UI scripts
│   └── components/      # (Future: reusable components)
├── resources/
│   └── data/            # JSON data files
└── assets/
    ├── sprites/         # (Future: pixel art)
    └── audio/           # (Future: music/SFX)
```

## How to Run

1. Open Godot 4.3+
2. Import the project folder
3. Run the test launcher scene
4. Choose which system to test (Character Sheet, Events, Combat)

## Testing Combat

From test launcher, enter Combat to:
- Move units with click-to-move
- Attack enemies in range
- Cast spells with targeting previews
- See status effects tick each turn
- Test AI spell casting and positioning

## Testing Events

From test launcher, enter Event System to:
- See choice type color coding
- Test party-wide requirement checking
- Roll dice for yellow choices
- See karma changes (debug panel)

## Roadmap

See `TODO.md` for detailed task list.

**High Priority:**
- Overworld map (HoMM-style exploration)
- Load events from JSON files
- Camp followers system
- Shop UI testing

**Medium Priority:**
- More content (races, backgrounds, items)
- Save/load system
- UI polish and tooltips

**Low Priority:**
- Audio (music/SFX)
- Visual assets (pixel art sprites)

## Design Philosophy

- **Buddhist themes**: Karma hidden from player, gradual cultivation, reincarnation cycles
- **Data-driven**: JSON files for all content
- **Systems thinking**: Attributes connect to derived stats to combat effectiveness
- **Player agency**: Free XP spending, no forced builds

---

**Status:** Core systems complete. Ready for content expansion and overworld implementation.

Last Updated: 2026-02-02
