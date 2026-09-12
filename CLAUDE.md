# Six Worlds - Project Context for Claude

## Project Overview
**Six Worlds** is a tactical RPG roguelike set in Tibetan Buddhist cosmology, built in Godot 4.7 using GDScript.

**Visual Style**: Tibetan thangka painting aesthetics combined with classic pixel art - ornate UI frames with sacred colors (deep reds, golds, indigos) surrounding pixel art characters and environments.

**Core Philosophy**: Buddhist concepts drive gameplay mechanics - karma systems affect reincarnation, no traditional leveling (pure XP-based progression reflects gradual enlightenment), party composition matters for skill checks.

## Development Workflow

### File Locations
- **Project directory**: `/home/gnoll/Documents/1_Projects/six_worlds/`
- Always write files directly to this directory
- Test scenes go in `scenes/ui/`
- AutoLoad singletons go in `scripts/autoload/`
- Data files (JSON) go in `resources/data/`

### Content Creation Pattern
Olaf handles content creation (races, characters, events, spells) during offline time, then collaborates with Claude to integrate content into game systems. When given raw content, format it properly and integrate with existing JSON structures.

### Verifying a change

`tools/verify_all.sh` is the single entry point: parse, boot, data, and the
in-engine verifier scenes. Run it after any change. `validate_data.py` alone is
not sufficient — it parses JSON in Python and never exercises a GDScript
loader, which is how `animal_events.json` once loaded 0 of its 86 events while
the validator reported no issues.

Adding a new `class_name` requires committing `.godot/global_script_class_cache.cfg`,
or the class fails to resolve at runtime while the parse stays clean.

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
| **Earth** | Maces, Armor, Earth magic, Summoning, Logistics, Trade, Smithing |

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

**See `README.md` for the current state and `TODO.md` for the open work —
both are kept current; this section is only a summary.**

### Working Systems (21 autoloads)
- Characters, karma/reincarnation, events (dynamic DCs, gated rolls), grid
  combat (spells/AoE/statuses/AI), overworld (real-time movement, mobs,
  portals with boss gating), shops/guilds/training, procedural items
  (weapons/armor/talismans/implements), 604 perks, psychology/pressure,
  traits, wounds, body plans (multi-arm species), camp/rest/time/lunar
  calendar, save/load (3 slots), audio, cheat console
- Realms with content: hell, hungry_ghost, animal (human/asura/god empty)

### Notable data conventions
- Character trait/quirk lists live in `character["traits"]` (traits.json);
  the old QuirkSystem/quirks.json are gone
- The crafting skill is `smithing` in code/data; races use `birth`
  terminology in UI code

## Design Decisions Already Made

### No Levels
XP is a pure currency spent freely on attributes and skills. No level-up milestones. This reflects Buddhist philosophy of gradual improvement.

### Character Power Assessment
Instead of levels, use relative XP comparison with descriptive labels ("slightly stronger", "vastly weaker", etc.) for mercenary hiring, enemy assessment, etc.

### Skill Categories
- Combat: Swords, Martial Arts, Ranged, Daggers, Axes, Unarmed, Spears, Maces, Armor
- Magic: Space, Air, Fire, Water, Earth, Sorcery, Enchantment, Summoning, White, Black
- General: Persuasion, Yoga, Ritual, Learning, Comedy, Guile, Might, Leadership, Performance, Grace, Medicine, Alchemy, Thievery, Logistics, Trade, Smithing

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
- `README.md` - current state, how to run and verify, where things live
- `TODO.md` - open work, deferred decisions, designs waiting to be built
- `docs/superpowers/specs/` - approved designs not yet implemented
- `tools/verify_all.sh` - run this after any change

## What is still open

This section listed the overworld map, tactical combat and save/load as
"planned" long after all three shipped. It is not maintained here any more —
`TODO.md` is the live list, and it is organised so that open work, deferred
decisions and unbuilt designs are separate things.

The largest remaining gaps, for orientation only:

- **Three realms have no content at all** — human, asura, god.
- **Nothing has been played end to end.** Systems are verified individually;
  the full reincarnation loop has not been sat down with.
- **297 passive perks are description-only**, and the passive effects engine
  that would read them is built but barely used.
- **Long-standing design questions:** realm-specific mechanics (hell = combat,
  human = dialogue), the klesha system (affinities causing emotional statuses),
  and Yidam/Dharmapala — the last two have complete designs in `TODO.md` Part II.

## Things to Remember

1. **Buddhist thematic elements matter** - Design choices should reflect concepts like karma, impermanence, and gradual cultivation
2. **This is a passion project** - Room for iteration and experimentation
3. **Clarify ambiguous requirements** before implementing
4. **Break large systems into testable components**
5. **Olaf has a spell list** (in SPECIFICATION/chat1.txt) with ~150+ spells organized by school/level
6. **Logistics train** - Ask about this system (party-wide passive bonuses from Logistics, Medicine, etc.)
