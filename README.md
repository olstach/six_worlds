# Six Worlds

A tactical RPG roguelike set in the six realms of Tibetan Buddhist cosmology, built in Godot 4.3.

## Overview

Six Worlds combines grid-based tactical combat with Buddhist-themed progression systems. Players reincarnate through different realms based on hidden karma, developing characters through XP-based attribute and skill systems rather than traditional leveling.

**Visual Style**: Tibetan thangka painting aesthetics with pixel art - ornate UI frames with sacred colors (deep reds, golds, indigos).

## Implemented Systems

### Core Singletons (12 AutoLoads)

| System | Description |
|--------|-------------|
| **GameState** | World/realm tracking, boss defeats, gold, supplies (Food/Herbs/Scrap/Reagents), starvation, run state |
| **CharacterSystem** | 7 attributes, 35 skills (0-10 scale), derived stats, party management, spell learning |
| **KarmaSystem** | Hidden karma for 6 realms, reincarnation logic, weighted race selection |
| **EventManager** | FTL-style events, 3 choice types (grey/blue/yellow), party-wide checks, combat/shop triggers |
| **CombatManager** | Grid combat, initiative, spells, status effects, AI, terrain, LoS, loot drops |
| **ItemSystem** | Equipment database, 12-slot system, inventory, procedural weapon/armor/talisman generation |
| **EnemySystem** | Enemy archetypes, role-based stats, inventory generation, power scaling |
| **ShopSystem** | Buy/sell items, learn spells, train skills, Trade/Charm discounts |
| **PerkSystem** | Skill perks (all 35 skills), cross perks, base bonuses, affinity bonuses |
| **SaveManager** | Full save/load across all systems |
| **MapManager** | HoMM-style overworld, A* pathfinding, mobs, objects, fog of war, procedural generation |
| **AudioManager** | SFX system (28 sounds × 6 variants), per-weapon/spell/UI sound mapping |

### Combat System

Tactical grid-based combat (12x8 default) with:

- **Turn Order**: Initiative-based with 2-action system
- **Attacks**: Melee and ranged with physical subtypes (slashing, crushing, piercing), ammo system
- **326 Spells**: Across 10 schools (5 elements + 5 specializations)
- **Targeting**: Self, single, AoE circle, chain, with visual previews
- **Status Effects**: 80+ effects including DoT, buffs, debuffs, CC
- **Terrain**: Walls, pits, water, difficult terrain; fire/ice/poison/acid/blessed/cursed ground effects
- **Height & LoS**: Bresenham's algorithm, height advantages for damage/accuracy/range
- **Obstacles & Cover**: Trees, rocks, pillars, barricades with dodge bonuses, destructible
- **Movement Modes**: Normal, levitate (partial geo immunity), flying (full immunity)
- **Deployment**: Role-based positioning with Tactician upgrade for manual placement
- **AI**: Spell casting, active skill usage, consumable items, ranged repositioning, target prioritization
- **Active Skills**: 25+ perk-based combat abilities with stamina/cooldown system
- **Consumables**: Potions, scrolls, bombs (AoE + status), oils (weapon coatings), charms (mana reduction)
- **Loot**: Rarity-weighted drops, supply/reagent drops (caster-weighted for reagents)

### Character & Progression

- **No Levels**: XP is pure currency spent freely on attributes/skills
- **7 Attributes**: Strength, Finesse, Constitution, Focus, Awareness, Charm, Luck
- **35 Skills** (0-10 scale, 11-15 via items/race): Combat (9), Magic (10), General (16) - each tagged with element
- **Elemental Affinities**: Skill points build affinity totals for gradual bonuses
- **Perk System**: Skill perks at each level + cross-skill perks for multi-discipline builds
- **Spellbook**: Learn/forget spells, starting spells from background
- **Races & Backgrounds**: 6 devil races + 23 backgrounds for Hell realm

### Supply System

Four supply types consumed passively while traveling on the overworld:

| Supply | Passive Effect | Gathering Perk |
|--------|---------------|----------------|
| **Food** | HP regen per step; starvation if empty | — |
| **Herbs** | Bonus healing (Medicine skill) | Herbalist (Medicine 3) |
| **Scrap** | Equipment repair + ammo restore (Smithing skill) | Scavenger (Smithing 3) |
| **Reagents** | Passive alchemy brewing (toggleable) | Alchemical Recycling (Alchemy 3) |

### Alchemy Crafting

Three crafting branches, each with 3 perk-unlocked tiers:

| Branch | Tier 1 (Alch 1, 1 reagent) | Tier 2 (Alch 5, 2 reagents) | Tier 3 (Alch 9, 4 reagents) |
|--------|---------------------------|----------------------------|----------------------------|
| **Remedies** | Health/Mana Potion, Antidote | Greater HP/MP, Stamina Tonic, Cure-All | Elixir of Vitality/Power, Panacea |
| **Munitions** | Fire/Frost/Smoke Bomb | Acid Flask, Thunder Bomb, Flashbang | Inferno Bomb, Void Grenade, Plague Flask |
| **Applications** | Flame/Frost/Poison Oil | Whetstone/Paralyzing/Warding Oil | Dragon's Blood/Void/Sovereign Oil |

Passive brewing: 15% + 3%/Alchemy level chance per overworld step. Toggleable to hoard reagents.

### Procedural Generation

- **Weapons**: 7 types × 6 materials × 5 quality levels + 12 traits (e.g. keen, vampiric, thundering)
- **Armor**: 10 types × 6 materials × 5 quality levels + 12 traits (e.g. reinforced, warded, blessed)
- **Talismans**: Budget-based with rarity scaling, 4 effect pools (attributes, derived stats, skills, resistances), perk system, Buddhist naming

### Overworld Map

- HoMM-style tile-based exploration with A* pathfinding
- Terrain speed modifiers, fog of war
- Object types: events, pickups, portals
- Mob system: stationary, patrol, roaming, aggressive pursuit
- Procedural map generation from realm configs
- Map markers with shapes/colors by type and name labels

### Event System

FTL-style encounters with:

- **Grey Choices**: Always available basic options
- **Blue Choices**: Require attribute/skill thresholds (ANY party member can qualify)
- **Yellow Choices**: d20 + best party attribute vs DC
- **Hell Events**: 39 events across cold/fire hell zones

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
| `items.json` | Weapons, armor, accessories, consumables, supply items |
| `races.json` | 6 devil races with modifiers and caps |
| `skills.json` | 35 skills organized by category/element |
| `shops.json` | 5+ shops with inventories |
| `upgrades.json` | 10+ upgrade/perk definitions |
| `perks.json` | Skill perks + cross perks for all 35 skills |
| `supplies.json` | 4 supply types with passive effects and consumption |
| `equipment_tables.json` | Procedural weapon/armor generation tables |
| `talisman_tables.json` | Procedural talisman generation tables |
| `hell.json` | Hell realm map config for procedural generation |
| `hell_events.json` | 39 Hell realm events |
| `hell_enemies.json` | Hell enemy archetypes |

## Project Structure

```
six_worlds/
├── project.godot
├── scenes/
│   ├── ui/              # Test launcher, character sheet, event display
│   ├── combat/          # Combat arena scene
│   └── overworld/       # HoMM-style map
├── scripts/
│   ├── autoload/        # 12 global singletons
│   ├── combat/          # Arena, grid, unit components
│   ├── ui/              # UI scripts
│   └── overworld/       # Map scripts
├── resources/
│   ├── data/            # JSON data files
│   │   ├── events/      # Per-realm event files
│   │   └── map_configs/ # Per-realm map generation configs
│   └── audio/
│       └── sfx/         # 28 sounds × 6 variants
└── tools/               # Content generation scripts
```

## How to Run

1. Open Godot 4.3+
2. Import the project folder
3. Run the test launcher scene
4. Choose which system to test (Character Sheet, Events, Combat)

## Roadmap

See `TODO.md` for detailed task list.

**High Priority:**
- Content for remaining 5 realms (events, races, enemies, map configs)
- Map interactibles (simples, traders, event chains)
- Quest system
- Crafting UI tab

**Medium Priority:**
- More consumable/equipment content
- Procedural generation wired to shops/loot
- Cursed items
- UI polish and tooltips

**Low Priority:**
- Audio (background music, more SFX wiring)
- Visual assets (pixel art sprites, tile sets)
- Multiple save slots, auto-save

## Design Philosophy

- **Buddhist themes**: Karma hidden from player, gradual cultivation, reincarnation cycles
- **Data-driven**: JSON files for all content
- **Systems thinking**: Attributes connect to derived stats to combat effectiveness
- **Player agency**: Free XP spending, no forced builds
- **No over-engineering**: Simple solutions, build only what's needed

---

**Status:** Core systems complete. Supply/alchemy systems in. Ready for content expansion across all six realms.

Last Updated: 2026-03-06
