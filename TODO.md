# Six Worlds - TODO & Design Notes

## Current Status
✅ Core systems foundation complete (GameState, CharacterSystem, KarmaSystem)
✅ Basic character sheet UI working
✅ XP-based progression system (no levels)
✅ Race and skill data structures
✅ Event/Dialogue System complete with three choice types
✅ Karma integration with events
✅ Party-wide requirement checking
✅ Dice rolling system for yellow choices

---

## Priority Tasks

### High Priority (Core Gameplay)
- [ ] **Overworld Map System** (HoMM-style tile-based exploration)
  - Tile-based movement
  - Hub/Quest/Battle node types
  - World transitions between realms
  - Save current position
  
- [ ] **Event/Dialogue System** (FTL-style encounters)
  - Event node data structure (JSON)
  - Choice branching logic
  - Karma tagging on choices
  - Scene transition to/from events
  - Event outcomes (items, XP, karma, combat trigger)

- [ ] **Tactical Combat System** (Grid-based like Disgaea/FF Tactics)
  - Combat grid setup
  - Turn order system
  - Ability targeting and execution
  - Basic AI behavior
  - Status effects
  - Victory/defeat conditions

### Medium Priority (Content & Polish)
- [ ] **Expand Data Files**
  - All races for all 6 realms (currently have 5 examples)
  - Complete backgrounds database with skill distributions
  - Spell definitions (tagged with schools and elements)
  - Item/equipment database
  - Upgrade/perk database with requirements

- [ ] **UI Improvements**
  - Visual redesign (colors, fonts, Buddhist aesthetic)
  - Upgrade selection popup (choose 1 of 4 perks)
  - Skill learning menu
  - Equipment/inventory screens
  - Tooltip system (hover for detailed info)
  - Party management screen
  - World map UI

- [ ] **Data Loading System**
  - Utility script to load JSON files
  - Race data loader
  - Skill data loader
  - Spell data loader
  - Item data loader
  - Event data loader

### Low Priority (Nice to Have)
- [ ] **Save/Load System**
  - Save current run state
  - Save meta-progression (affinities, persistent upgrades)
  - Multiple save slots
  - Auto-save functionality

- [ ] **Sound & Music**
  - Background music for each realm
  - Combat music
  - UI sound effects
  - Spell/ability sounds

- [ ] **Visual Assets**
  - Character portraits
  - Enemy sprites
  - Tile sets for each realm
  - Spell effects
  - UI artwork

---

## Design Questions & Ideas to Resolve

### Character Power Assessment
**Problem:** Without levels, how do we quickly judge character strength?
**Proposed Solution:** Relative XP comparison with descriptive labels
- Calculate total XP difference between characters
- Use ranges to determine relationship:
  - "Vastly weaker" (>2000 XP below)
  - "Weaker" (500-2000 below)
  - "Slightly weaker" (100-500 below)
  - "Equal" (±100 XP)
  - "Slightly stronger" (100-500 above)
  - "Stronger" (500-2000 above)
  - "Vastly stronger" (>2000 above)
- Display this in mercenary hire UI, enemy assessment, etc.
- Could also show visual indicator (color-coded skulls/stars?)

**Implementation Notes:**
- Add `calculate_power_comparison(xp1, xp2) -> String` to CharacterSystem
- Use in UI tooltips, hiring menus, combat preparation
- May need to adjust ranges after playtesting

### XP Balance
- Need to playtest XP costs vs XP rewards
- Should reaching high attributes feel rare/special?
- How much XP should typical combat/quests give?
- Should different worlds give more XP? (god realm = rich rewards?)

### Karma Visibility
- Currently completely hidden (thematic!)
- Should player ever see hints? ("You feel drawn to the cold...")
- Maybe Yoga skill unlocks karma meditation ritual to view rough scores?
- Or leave it totally mysterious for discovery/experimentation?

### Reincarnation Meta-Progression
- Skill affinities (max level = cheaper next life) ✅ structure in place
- Persistent upgrades (rare quest rewards) ✅ structure in place
- Should there be MORE meta-progression?
  - Unlock new starting backgrounds?
  - Unlock special races (white/black devils)?
  - Unlock tulku mode faster?

### Combat Complexity
- How many abilities should characters have?
- Should positioning matter a lot (like Disgaea) or less (like XCOM)?
- Grid size? (8x8? 10x10? Variable by encounter?)
- Should enemies have visible stats or be mysterious?

### Realm-Specific Mechanics
- Hell: Pure combat focus, lots of enemies
- Hungry Ghost: Resource scarcity, survival mechanics?
- Animal: Mix of combat and negotiation
- Human: Heavy dialogue/quest focus, less combat
- Asura: Competitive events, duels?
- God: Almost no combat, pure diplomacy/trade?

### Mantras & Deity Yoga
- How should channeled buffs work mechanically?
- Should they be pre-battle prep or mid-combat actions?
- What breaks them? (damage? moving? certain enemy abilities?)
- Deity yoga achievements = permanent buffs or temporary super-states?

---

## Completed Items
✅ Core AutoLoad singletons (GameState, CharacterSystem, KarmaSystem, EventManager)
✅ Character data structure with attributes, skills, equipment
✅ XP-based progression (removed levels)
✅ Race definitions with modifiers and caps
✅ Skill definitions with categories and elements
✅ Basic character sheet UI
✅ Karma tracking and reincarnation logic
✅ Derived stats calculation
✅ Attribute cost scaling (exponential)
✅ Skill level progression (fixed costs 100/300/600/1000/1500)
✅ Event/Dialogue System with three choice types:
  - Default (grey) - always available
  - Requirement (blue) - needs attribute/skill threshold
  - Roll (yellow) - requires dice roll against difficulty
✅ Party-wide requirement checking (any companion can pass test)
✅ Dice rolling: d20 + best party attribute vs difficulty
✅ Event outcomes (text, XP rewards, karma changes, combat/shop triggers)
✅ Tibetan-inspired UI aesthetic with rich colors
✅ Test launcher to switch between systems

---

## Notes for Future Reference

### GDScript Quirks Learned
- Use `not x in y` instead of `x not in y`
- Always initialize Array types: `Array[Dictionary]` not just `Array`

### Design Philosophy
- Data-driven (JSON files for content)
- Systems thinking (everything connects)
- Thematic consistency (karma hidden, gradual improvement)
- Player agency (free XP spending, no forced builds)

### Godot Project Structure
- AutoLoad for global systems
- Scenes for gameplay states (overworld, combat, dialogue)
- Resources folder for data files
- Scripts organized by function (autoload, ui, components, data)

---

Last Updated: 2026-01-30
