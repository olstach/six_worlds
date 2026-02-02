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
✅ Item System complete (equipment, inventory, stat bonuses)
✅ Item tooltip on hover
✅ Combat System Phase 1 (grid, movement, basic attacks)
✅ Combat System Phase 2 - Spell System (see below)

---

## Known Bugs

- [x] **Derived stats not displaying** - FIXED: Was using wrong key ("derived_stats" vs "derived")
- [x] **Combat turn order issues** - FIXED: Removed async/await, using Timer-based delays for enemy turns instead

---

## Systems to Implement

- [ ] **Camp Followers System** - Non-combat companions providing passive bonuses
  - Data structure for followers (name, role, bonus_description, bonus_effects)
  - GameState.get_followers() function
  - Follower recruitment through events
  - Passive bonus application (trade bonuses, carrying capacity, healing, etc.)
  - UI already in place in Party tab

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

- [x] **Tactical Combat System Phase 1** (Grid-based like Disgaea/FF Tactics)
  - ✅ Combat grid setup (12x8, top-down)
  - ✅ Turn order system (initiative-based)
  - ✅ 2-action system (move/attack/wait in any order)
  - ✅ Basic attack with hit/miss, damage, crits
  - ✅ Physical damage with armor reduction
  - ✅ Basic AI behavior (move toward player, attack)
  - ✅ Bleed-out system (3 turns to revive)
  - ✅ Victory/defeat conditions
  - 🔶 Known bug: turn order occasionally out of sync

- [x] **Tactical Combat System Phase 2 - Spell System**
  - ✅ Spell database (resources/data/spells.json) with 25+ spells
  - ✅ Spell casting UI (Spell button, spell panel with scroll)
  - ✅ Multiple targeting types: self, single, single_ally, aoe_circle, chain
  - ✅ Purple spell range highlighting
  - ✅ Orange AoE preview on hover
  - ✅ Rich spell tooltips (schools, stats, effects, description)
  - ✅ Elemental damage with resistances (space, air, fire, water, earth)
  - ✅ Spell effects: damage, heal, buff, debuff, status, lifesteal, revive, cleanse
  - ✅ Skill requirements (need one school at spell level, bonuses from all schools)
  - ✅ Status effect processing on turn start/end
  - ✅ AI spell casting (enemy mages can cast spells)

- [x] **Spellbook System**
  - ✅ Characters have `known_spells` array - must learn spells before casting
  - ✅ `learn_spell()` / `forget_spell()` / `knows_spell()` functions in CharacterSystem
  - ✅ `get_castable_spells()` filters by known spells
  - ✅ Starting spells based on background (wanderer gets fire spells)
  - ✅ Enemies have `known_spells` in their definitions
  - ✅ AI selects and casts appropriate spells (damage, AoE targeting)
  - ✅ Test mage enemy (Demon Mage) with fire/black spells
  - 🔶 Spellbook UI tab in menu (not yet implemented)
  - 🔶 Spell learning through trade/events (future)

- [x] **Tactical Combat System Phase 3a - Ranged Attacks**
  - ✅ Ranged weapon support (bows, thrown weapons with `range` stat)
  - ✅ CombatUnit checks equipped weapon for attack range
  - ✅ Finesse-based damage for ranged (vs Strength for melee)
  - ✅ Ranged skill bonus to damage and accuracy
  - ✅ Enemy AI repositioning for ranged units (stay at distance)
  - ✅ Test ranged enemy (Demon Archer) in combat

- [x] **Tactical Combat System Phase 3b - Status Effect Tick Processing**
  - ✅ DoT effects (burning, poisoned, bleeding) deal damage at turn start
  - ✅ Healing over time (regenerating) heals at turn start
  - ✅ Incapacitating effects (frozen, stunned, knocked_down) skip turn
  - ✅ Duration tracking and effect expiration
  - ✅ Visual status indicators on units (emoji icons)
  - ✅ Buff/debuff duration tick processing
  - ✅ Test spells: Immolate (burning), Poison Dart (poisoned)

- [ ] **Tactical Combat System Phase 3c - Terrain**
  - Terrain obstacles (walls, pits)
  - Height differences
  - Geo effects (fire on ground, etc.)

- [x] **Trading System**
  - ✅ Party gold tracking in GameState (add/spend/can_afford)
  - ✅ ShopSystem autoload for managing shops and transactions
  - ✅ Buy/sell items with price calculations
  - ✅ Spell learning for gold (trainers)
  - ✅ Skill/attribute training for gold (rare trainers)
  - ✅ Trade skill discount (5% per level)
  - ✅ Shop data structure with tabs (items/spells/training)
  - ✅ Sample shops in shops.json (merchant, spell trainer, skill trainer, etc.)
  - 🔶 Shop UI (FTL-style event screens - not yet implemented)

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

Last Updated: 2026-02-02

---

## Session Notes (2026-02-02)

### Trading System Implementation
- Added party gold tracking to GameState (gold, add_gold, spend_gold, can_afford)
- Created ShopSystem autoload for all trading functionality
- Shop types: general (items), spell_trainer (spells), skill_trainer (training), mixed
- Price calculations with Trade skill discount (5% per skill level)
- Buy/sell items (sell at 50% value, Trade skill bonus)
- Learn spells for gold (cost = 50 * spell_level)
- Train attributes for gold (200 per point)
- Train skills for gold (50/150/300/500/750 per level)
- Created shops.json with 5 sample shops (merchant, sorcerer, sage, weapon master, general store)
- Shop data loaded from JSON on startup

### Key Files Created/Modified (Trading)
- `scripts/autoload/game_state.gd` - gold tracking, gold_changed signal
- `scripts/autoload/shop_system.gd` - NEW: full trading system
- `resources/data/shops.json` - NEW: shop definitions
- `project.godot` - Added ShopSystem autoload

### Spellbook System & AI Spell Casting
- Characters now have `known_spells` array - must learn spells to cast them
- Added CharacterSystem functions: learn_spell(), forget_spell(), knows_spell(), get_known_spells()
- Starting spells granted based on background (wanderer: firebolt, immolate, lesser_heal, poison_dart)
- get_castable_spells() now filters by known spells
- Enemies can have known_spells in their definitions
- Enemy AI now casts spells: prioritizes damage spells, handles single/AoE targeting
- Added test "Demon Mage" enemy with fire_magic/sorcery/black skills and fire/poison spells
- AI positions casters at mid-range for safety

### Key Files Modified (Spellbook/AI Casting)
- `scripts/autoload/character_system.gd` - known_spells array, spell learning functions, spell_learned signal
- `scripts/autoload/combat_manager.gd` - get_castable_spells() filters by known_spells
- `scripts/combat/combat_arena.gd` - _try_cast_spell() AI function, Demon Mage enemy definition

### Status Effect Tick Processing Implementation
- Status effects now process at turn start (DoT damage, healing, duration tick)
- Damage over time: burning (3 fire/turn), poisoned (2 physical/turn), bleeding (2 physical/turn)
- Healing over time: regenerating (uses effect value per turn)
- Incapacitating effects: frozen, stunned, knocked_down - skip turn
- Visual status icons on units (🔥 burning, ☠ poisoned, ❄ frozen, etc.)
- Added signals: status_effect_triggered, status_effect_expired
- New test spells: Immolate (80% burn chance), Poison Dart (70% poison chance)
- Updated Fireball to have 40% burn chance
- Wanderer background now has black:1 for testing Poison Dart

### Key Files Modified (Status Effects)
- `scripts/autoload/combat_manager.gd` - _process_status_effects(), _process_stat_modifiers(), is_unit_incapacitated(), can_unit_move()
- `scripts/combat/combat_arena.gd` - Status effect signal handlers, visual refresh
- `scripts/combat/combat_unit.gd` - Status effect visual indicators in _update_visuals()
- `resources/data/spells.json` - Added Immolate, Poison Dart, updated Fireball
- `scripts/autoload/character_system.gd` - Added black:1 to wanderer

### Ranged Weapon Attacks Implementation
- Added `range` stat to ranged weapons in items.json (bows: 4-6 range, throwing: 3 range)
- Added new weapon types: `longbow`, `throwing_knife`
- Updated item_types with `ranged: true` flag for bows and thrown weapons
- CombatUnit now properly checks equipped weapon for attack range
- Ranged weapons use Finesse for damage (melee uses Strength)
- Weapon skill bonuses (+2 damage/accuracy per skill level)
- Enemy AI updated to handle ranged positioning (stay at distance)
- Test ranged enemy "Demon Archer" with bow (range 5) added to combat

### Key Files Modified (Ranged Attacks)
- `resources/data/items.json` - Added range stat, longbow, throwing_knife, ranged type flags
- `scripts/combat/combat_unit.gd` - get_equipped_weapon(), is_ranged_weapon(), updated get_attack_range/damage/accuracy
- `scripts/combat/combat_arena.gd` - Ranged enemy definition, improved AI movement for ranged
- `scripts/autoload/item_system.gd` - Added short_bow to starter items

---

## Session Notes (2026-02-01)

### Spell System Implementation Complete
- Created `resources/data/spells.json` with 25+ spells across all schools
- Schools work as ORs for requirements (need ONE at spell level), but bonuses from ALL apply
- Spell schools: earth, water, fire, air, space (elements) + white, black, sorcery, summoning, enchantment
- Added spell UI to combat arena (SpellButton, SpellPanel with ScrollContainer)
- Spell range shows purple highlighting, AoE preview shows orange on hover
- Rich tooltips show: schools, level/mana/range, targeting type, all effects, description

### Key Files Modified This Session
- `scripts/autoload/combat_manager.gd` - Added spell casting, get_castable_spells(), effect application
- `scripts/combat/combat_arena.gd` - Spell UI, targeting, AoE preview, rich tooltips
- `scripts/combat/combat_grid.gd` - highlight_spell_range(), show_aoe_preview()
- `scenes/combat/combat_arena.tscn` - Added SpellButton and SpellPanel nodes
- `scripts/autoload/character_system.gd` - Added test magic skills to wanderer background

### Next Steps
- Status effect tick processing (burning damage, regeneration healing, etc.)
- AI spell casting
- More spells from the design docs (SW3 - Spells.md has full spell list)
- Ranged weapon attacks
