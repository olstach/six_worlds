# Six Worlds - Foundation Build

A tactical RPG roguelike set in the six realms of Tibetan Buddhist cosmology, built in Godot 4.3.

## What's Implemented

This is the **foundational architecture** for the game, focusing on the core progression systems before adding gameplay layers.

### Core Systems (AutoLoad Singletons)

1. **GameState** (`scripts/autoload/game_state.gd`)
   - Tracks current world and unlocked worlds
   - Manages boss defeats and world transitions
   - Handles run state (alive/dead, run number)

2. **CharacterSystem** (`scripts/autoload/character_system.gd`)
   - Complete attribute system (7 attributes: Strength, Finesse, Constitution, Focus, Awareness, Charm, Luck)
   - Skill progression system (0-5 levels per skill, exponential XP costs)
   - Derived stats calculation (HP, Mana, Initiative, Dodge, Crit, etc.)
   - Party management (player + companions)
   - Equipment and inventory (structure ready)
   - Upgrade/perk system (hooks in place)
   - XP and leveling system

3. **KarmaSystem** (`scripts/autoload/karma_system.gd`)
   - Hidden karma tracking for all 6 realms
   - Reincarnation logic (highest karma determines realm)
   - Weighted race selection within realms
   - Background selection based on race
   - Partial karma reset between lives
   - Karma purification hooks (for future rituals)

4. **EventManager** (`scripts/autoload/event_manager.gd`)
   - Event loading and presentation
   - Three choice types: Default (grey), Requirement (blue), Roll (yellow)
   - Party-wide requirement checking (companions count!)
   - Dice rolling system (d20 + attribute vs DC)
   - Outcome processing (XP, items, karma, combat/shop triggers)
   - Event database with test encounters

### Test Scenes

**Test Launcher** (`scenes/ui/test_launcher.tscn`)
- Main menu to access different systems
- Switch between character sheet and event display

**Character Sheet UI** (`scenes/ui/test_character_sheet.tscn`)
- Displays character name, race, background, total XP
- Shows all attributes with upgrade buttons (XP cost calculated)
- Lists skills with upgrade buttons
- Displays derived stats (auto-calculated from attributes)
- Debug controls to test systems:
  - Grant XP button
  - Add karma buttons (Hell/God realms)
  - Test reincarnation button
  - Karma score display

**Event Display UI** (`scenes/ui/event_display.tscn`)
- FTL-style event encounters
- Three choice types with visual distinction
- Party-wide requirement checking
- Dice roll system with results display
- Karma integration
- Tibetan thangka-inspired aesthetic
- Test encounters for Hell and Human realms

### Data Files

- **races.json** - Race definitions with attribute modifiers, caps, and typical backgrounds
  - Examples: Red Devil, Blue Devil, Human, Naga, Zombie
  - Each race has unique stat distributions and caps

- **skills.json** - Skill definitions organized by category
  - Combat skills (swords, polearms, unarmed, bows, etc.)
  - Magic skills (5 elements + specialized schools)
  - General skills (persuasion, trade, yoga, logistics, etc.)
  - Element associations for building affinities

- **Event database** (embedded in EventManager for now)
  - Test encounters demonstrating all choice types
  - Will move to JSON files later

## How to Use

### Opening in Godot

1. Open Godot 4.3+
2. Import the `six_worlds` folder as a project
3. The test launcher will load - choose which system to test

### Testing the Character System

From the test launcher, click "Character Sheet" to access:

**Attribute System:**
- Click "+" buttons next to attributes to spend XP
- Cost increases exponentially (10→11 costs 100, 11→12 costs 150, etc.)
- Derived stats auto-update (HP from Constitution, Mana from Awareness, etc.)

**Skill System:**
- Click "Upgrade" next to skills to level them up
- Each level costs progressively more XP (100/300/600/1000/1500)
- Click "+ Learn New Skill" to add a new skill at level 1
- Skills are capped at level 5

**XP System:**
- Click "Grant 500 XP" to add experience points
- XP is a pure currency - spend it freely on attributes or skills
- No level-ups or barriers - just gradual improvement

**Karma & Reincarnation:**
- Click "Add Hell Karma" or "Add God Karma" to adjust karma scores
- Click "Test Reincarnation" to simulate death and rebirth
  - System determines realm based on highest karma
  - Selects weighted random race from that realm
  - Chooses appropriate background
  - Creates new character with fresh stats
  - Karma partially resets (30% carried over)

### Testing the Event System

From the test launcher, click "Event System" to access:

**Choice Types:**
- **Grey choices**: Always available, basic options
- **Blue choices (⚡)**: Require specific attribute/skill thresholds
  - If ANY party member meets requirement, choice is available
  - Shows which character enables the choice
- **Yellow choices (🎲)**: Require dice roll
  - d20 + best party attribute vs difficulty number
  - Shows roll result, success/failure

**Testing Mechanics:**
1. Read the event description
2. Notice which choices are available (blue may be greyed out)
3. Select a choice
4. For rolls: watch the dice result and roller name
5. See the outcome with XP/karma rewards
6. Click "Continue" for another random event

**Party Testing:**
- Use character sheet to increase attributes
- Come back to events to unlock blue choices
- Companions would enable more choices (not yet implemented in test)

### Understanding the Output

Watch the **Godot console** to see:
- Character creation messages
- Karma changes
- Skill/attribute upgrades
- Reincarnation details

The **karma debug panel** shows exact karma scores (normally hidden from player).

## Project Structure

```
six_worlds/
├── project.godot           # Godot project config
├── icon.svg               # Placeholder icon
├── scenes/
│   ├── ui/
│   │   └── test_character_sheet.tscn
│   ├── overworld/         # Future: HoMM-style map
│   └── combat/            # Future: tactical grid battles
├── scripts/
│   ├── autoload/          # Global singleton systems
│   │   ├── game_state.gd
│   │   ├── character_system.gd
│   │   └── karma_system.gd
│   ├── components/        # Future: reusable components
│   ├── data/              # Future: data loading utilities
│   └── ui/
│       └── character_sheet.gd
├── resources/
│   ├── data/
│   │   ├── races.json     # Race definitions
│   │   └── skills.json    # Skill definitions
│   └── themes/            # Future: UI themes
└── assets/
    ├── sprites/           # Future: pixel art
    └── audio/             # Future: music/SFX
```

## Next Steps

The foundation is ready! Here's what could be added next:

### 1. Expand Data Files
- More races (all 6 realms)
- Complete backgrounds list
- Spell definitions
- Item/equipment definitions
- Upgrade/perk database

### 2. UI Improvements
- Better visual design (colors, fonts, layout)
- Upgrade selection popup (choose 1 of 4)
- Skill learning menu
- Equipment/inventory screens
- Tooltip system

### 3. Overworld System
- HoMM-style tile-based map
- Movement and exploration
- Hub/quest/battle nodes
- World transition logic

### 4. Event/Dialogue System
- FTL-style event nodes
- Branching choices
- Karma tagging on choices
- Scene transitions

### 5. Combat System
- Tactical grid
- Turn-based positioning
- Ability targeting
- AI behavior
- Status effects

## Design Notes

**Attributes:**
- Start at 10, can increase exponentially
- Caps vary by race (e.g., Red Devils have high Strength cap)
- Each attribute affects multiple derived stats

**Skills:**
- Five levels (1-5), with 0 being untrained
- Progressive XP costs encourage specialization
- Magic skills tied to elements for affinity building
- Some skills unlock special abilities (Yoga → pacifist options)

**Karma:**
- Completely invisible to player (thematic!)
- Every choice/action tagged with realm associations
- Highest karma determines next life
- Partial persistence creates karmic patterns

**Race & Background:**
- Race determines attribute mods and caps
- Background determines starting skills
- Combination creates varied playstyles
- Some backgrounds only available to certain races

## Philosophy

This foundation prioritizes **systems thinking**:
- Everything connects (attributes → derived stats)
- Progression is consistent (exponential costs)
- Reincarnation actually uses the character system
- Data-driven design (JSON for races/skills)

The character sheet demonstrates that the systems **work** before we add combat/exploration complexity.

---

**Status:** Foundation complete, ready for next layer (UI polish or gameplay systems)
