# Six Worlds - Project Context for Claude

## Project Overview
**Six Worlds** is a tactical RPG roguelike set in Tibetan Buddhist cosmology, built in Godot 4.3 using GDScript.

**Visual Style**: Tibetan thangka painting aesthetics combined with classic pixel art - ornate UI frames with sacred colors (deep reds, golds, indigos) surrounding pixel art characters and environments.

**Core Philosophy**: Buddhist concepts drive gameplay mechanics - karma systems affect reincarnation, no traditional leveling (pure XP-based progression reflects gradual enlightenment), party composition matters for skill checks.

## Development Workflow

### File Locations
- **Project directory**: `/home/gnoll/Documents/1_Projects/Six_Worlds_3/`
- Always write files directly to this directory
- Test scenes go in `scenes/ui/`
- AutoLoad singletons go in `scripts/autoload/`
- Data files (JSON) go in `resources/data/`

### Content Creation Pattern
Olaf handles content creation (races, characters, events, spells) during offline time, then collaborates with Claude to integrate content into game systems. When given raw content, format it properly and integrate with existing JSON structures.

### Code Style
- Comment code clearly - Olaf is at beginner-intermediate level with Godot
- Provide explanations alongside code for learning purposes
- Follow Godot best practices: scene composition, signals for communication, AutoLoad for global systems
- Build incrementally, test frequently

## GDScript Quirks
- Use `not x in y` instead of `x not in y` (e.g., `while not angle in range(-360, 360):`)
- Always initialize typed Arrays: `Array[Dictionary]` not just `Array`
- Variable scope in for loops - variables declared inside loops aren't accessible after `break`

## Core Systems Architecture

### Attributes (7 total)
| Attribute | Role |
|-----------|------|
| Strength | Physical damage, carrying capacity |
| Constitution | HP, stamina (half) |
| Finesse | Dodge, initiative, movement, stamina (half), crit |
| Focus | Spellpower |
| Awareness | Mana pool, initiative, environmental checks, crit |
| Charm | Social interactions, leadership |
| Luck | Critical chance, loot quality |

### Derived Stats
- **HP**: Constitution
- **Mana**: Awareness
- **Stamina**: 1/2 Constitution + 1/2 Finesse
- **Initiative**: Finesse + Awareness
- **Movement Speed**: Finesse
- **Spellpower**: Focus
- **Dodge**: Finesse

### Skills (35 total, 7 per element)
| Element | Skills |
|---------|--------|
| **Space** | Swords, Martial Arts, Space magic, White magic, Black magic, Persuasion, Yoga |
| **Air** | Ranged, Daggers, Air magic, Ritual, Learning, Comedy, Guile |
| **Fire** | Axes, Unarmed, Fire magic, Sorcery, Might, Leadership, Performance |
| **Water** | Spears, Water magic, Enchantment, Grace, Medicine, Alchemy, Thievery |
| **Earth** | Maces, Armor, Earth magic, Summoning, Logistics, Trade, Crafting |

### Elemental Affinities
- Each skill point in an element-tagged skill adds to that element's affinity total
- Example: Maces 2 + Earth Magic 3 + Summoning 1 = Earth affinity 6
- Affinities provide gradual bonuses (e.g., Earth = HP, money bonus)

### Magic System
- Spells are tagged with multiple schools (e.g., Fireball = Fire + Sorcery)
- **To cast**: Need at least ONE tagged skill at the spell's required level
- **Bonuses**: All applicable skills contribute bonuses to damage/cost reduction
- Schools: 5 elements + Sorcery (instant effects), Enchantment (duration buffs), Summoning (creatures/objects), White (healing/buffs), Black (debuffs/necromancy)
- Ritual skill: Passive spellpower enhancement + mandala creation for item-boosted casting

## Event/Dialogue System (FTL-style)

### Three Choice Types
1. **Grey (Default)**: Always available, basic options
2. **Blue (Requirement)**: Needs attribute/skill threshold to appear, always beneficial
3. **Yellow (Roll)**: Dice roll required (d20 + best party attribute vs DC)

### Party-Wide Checking
- ANY party member meeting a requirement enables that choice
- Makes companion selection strategically meaningful
- UI shows which character enables the choice

### Karma Integration
- Every choice can modify karma across multiple realms
- Karma is completely hidden from the player (thematic!)
- Highest karma at death determines next reincarnation realm

## Current Implementation Status

### Working Systems
- CharacterSystem singleton (attributes, skills, XP, party management)
- KarmaSystem singleton (hidden karma tracking, reincarnation logic)
- GameState singleton (world progression, run state)
- EventManager singleton (events, three choice types, party checking, dice rolls)
- Test launcher scene
- Event display UI with Tibetan aesthetic

### Needs Work
- Character sheet UI (had node path issues)
- Combat system (not started)
- Overworld map (not started)
- Shop system (not started)

## Design Decisions Already Made

### No Levels
XP is a pure currency spent freely on attributes and skills. No level-up milestones. This reflects Buddhist philosophy of gradual improvement.

### Character Power Assessment
Instead of levels, use relative XP comparison with descriptive labels ("slightly stronger", "vastly weaker", etc.) for mercenary hiring, enemy assessment, etc.

### Skill Categories
- Combat: Swords, Martial Arts, Ranged, Daggers, Axes, Unarmed, Spears, Maces, Armor
- Magic: Space, Air, Fire, Water, Earth, Sorcery, Enchantment, Summoning, White, Black
- General: Persuasion, Yoga, Ritual, Learning, Comedy, Guile, Might, Leadership, Performance, Grace, Medicine, Alchemy, Thievery, Logistics, Trade, Crafting

### Ritual vs Yoga
- **Ritual**: External ceremony - mandala creation, material components to enhance spells
- **Yoga**: Internal cultivation - mantras, karma insight, pacifist dialogue options

## Key Files Reference

### AutoLoad Singletons
- `scripts/autoload/game_state.gd` - World/run management
- `scripts/autoload/character_system.gd` - Character stats, skills, party
- `scripts/autoload/karma_system.gd` - Hidden karma, reincarnation
- `scripts/autoload/event_manager.gd` - Events, choices, outcomes

### Data Files
- `resources/data/races.json` - Race definitions with modifiers
- `resources/data/skills.json` - Skill definitions by category/element

### Documentation
- `README.md` - Project overview and usage
- `TODO.md` - Tasks and design questions
- `EVENT_SYSTEM.md` - Event system documentation

## Future Features (Planned)

### High Priority
- Overworld map (HoMM-style tile exploration)
- Tactical combat (grid-based like Disgaea/FF Tactics)
- More events per realm

### Medium Priority
- UI polish (upgrade selection popup, equipment screen, party management)
- Complete data files (all races, backgrounds, spells, items)
- Save/load system

### Design Questions Still Open
- Combat grid size and positioning importance
- Realm-specific mechanics (Hell = combat focus, Human = dialogue focus, etc.)
- Mantra/deity yoga mechanical implementation
- Klesha system (elemental affinities causing emotional status effects)

## Things to Remember

1. **Buddhist thematic elements matter** - Design choices should reflect concepts like karma, impermanence, and gradual cultivation
2. **This is a passion project** - Room for iteration and experimentation
3. **Clarify ambiguous requirements** before implementing
4. **Break large systems into testable components**
5. **Olaf has a spell list** (in SPECIFICATION/chat1.txt) with ~150+ spells organized by school/level
6. **Logistics train** - Ask about this system (party-wide passive bonuses from Logistics, Medicine, etc.)
