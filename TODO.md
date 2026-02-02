# Six Worlds - TODO

Last Updated: 2026-02-02

---

## Completed Systems

### Core Infrastructure
- [x] GameState singleton (world tracking, boss defeats, party gold, run state)
- [x] CharacterSystem singleton (7 attributes, 35 skills, derived stats, party management)
- [x] KarmaSystem singleton (hidden karma, reincarnation, weighted race selection)
- [x] EventManager singleton (3 choice types, party-wide checks, dice rolls)
- [x] ItemSystem singleton (equipment database, 12-slot system, inventory)
- [x] ShopSystem singleton (buy/sell, spell learning, skill training, discounts)
- [x] CombatManager singleton (full tactical combat system)

### Combat System
- [x] Grid-based combat (12x8 default, configurable)
- [x] Initiative-based turn order with 2-action system
- [x] Melee and ranged attacks with weapon skills
- [x] 326 spells across 10 schools with full targeting system
- [x] Spell UI with range highlighting and AoE preview
- [x] Status effect processing (DoT, HoT, CC, buffs/debuffs)
- [x] 80+ status effect definitions
- [x] Terrain system (walls, pits, water, difficult)
- [x] Terrain effects (fire, ice, poison, acid, blessed, cursed)
- [x] Height system with traversal limits
- [x] Line of sight (Bresenham's algorithm)
- [x] Height advantage bonuses (accuracy, damage, range)
- [x] Deployment zones with role-based positioning
- [x] Tactician upgrade for manual placement
- [x] AI spell casting and ranged repositioning
- [x] Bleed-out system (3 turns to revive)
- [x] Victory/defeat conditions

### Character & Progression
- [x] XP-based progression (no levels)
- [x] Exponential attribute cost scaling
- [x] Skill progression (5 levels, costs: 100/300/600/1000/1500)
- [x] Derived stats calculation
- [x] Spellbook system (learn/forget spells)
- [x] Starting spells based on background
- [x] Elemental affinities tracking

### UI
- [x] Character sheet (attributes, skills, derived stats)
- [x] Event display with choice coloring
- [x] Combat arena with action buttons
- [x] Spell panel with tooltips
- [x] Combat log
- [x] Turn order display
- [x] Test launcher

### Data Files
- [x] spells.json (326 spells)
- [x] statuses.json (80+ status effects)
- [x] items.json (weapons, armor, accessories)
- [x] races.json (sample races for Hell realm)
- [x] skills.json (35 skills by category/element)
- [x] shops.json (5 sample shops)
- [x] upgrades.json (10+ upgrades)

---

## High Priority (Core Gameplay)

### Overworld Map System
- [ ] HoMM-style tile-based exploration
- [ ] Tile movement and pathfinding
- [ ] Node types (hub, quest, battle, shop, event)
- [ ] World transitions between realms
- [ ] Position saving/loading
- [ ] Fog of war (optional)

### Event System Improvements
- [ ] Load events from JSON files (currently hardcoded)
- [ ] Event files per realm (hell_events.json, human_events.json, etc.)
- [ ] Event chains and prerequisites
- [ ] Combat/shop trigger outcomes working

### Camp Followers System
- [ ] Non-combat companion data structure
- [ ] Follower recruitment through events
- [ ] Passive bonus application (trade, healing, carrying capacity)
- [ ] UI integration (slot already in Party tab)

### Testing & Polish
- [ ] Test Shop UI thoroughly (buying, selling, spell learning, training)
- [ ] Test terrain effect interactions with spells
- [ ] Balance pass on spell mana costs vs effects
- [ ] Test all 326 spells load and cast correctly

---

## Medium Priority (Content & Polish)

### Content Expansion
- [ ] Races for all 6 realms (currently only Hell examples)
- [ ] Background definitions with skill distributions
- [ ] More items (consumables, rare equipment)
- [ ] More upgrades/perks

### UI Improvements
- [ ] Spellbook tab in character sheet
- [ ] Equipment screen improvements
- [ ] Tooltip system expansion
- [ ] Upgrade selection popup (choose 1 of 4)
- [ ] Party management screen
- [ ] World map UI

### Spell-Terrain Integration
- [ ] Spells creating terrain effects (Fireball leaves fire terrain)
- [ ] Terrain affecting spell power
- [ ] Environmental spell interactions

---

## Low Priority (Nice to Have)

### Save/Load System
- [ ] Save current run state
- [ ] Save meta-progression (affinities, persistent upgrades)
- [ ] Multiple save slots
- [ ] Auto-save functionality

### Audio
- [ ] Background music per realm
- [ ] Combat music
- [ ] UI sound effects
- [ ] Spell/ability sounds

### Visual Assets
- [ ] Character portraits
- [ ] Enemy sprites (currently colored rectangles)
- [ ] Tile sets for each realm
- [ ] Spell effects
- [ ] UI artwork (Tibetan thangka style)

---

## Design Questions (Unresolved)

### Karma Visibility
- Currently completely hidden (thematic)
- Should Yoga skill unlock karma meditation to see rough scores?
- Or keep totally mysterious?

### Combat Balance
- Spell mana costs by level: 15/40/75/135/225 - needs playtesting
- Status effect durations and tick damage
- AI difficulty scaling

### Realm-Specific Mechanics
- Hell: Pure combat focus
- Hungry Ghost: Resource scarcity?
- Animal: Mix of combat and negotiation
- Human: Heavy dialogue/quest focus
- Asura: Competitive events, duels?
- God: Almost no combat, diplomacy/trade?

### Mantras & Deity Yoga
- How should channeled buffs work?
- Pre-battle prep or mid-combat?
- What breaks concentration?

---

## Known Issues

- [x] ~~Derived stats not displaying~~ - FIXED (wrong key)
- [x] ~~Combat turn order issues~~ - FIXED (Timer-based delays instead of async/await)
- [ ] Turn order occasionally out of sync (rare, needs investigation)

---

## Session Notes

### 2026-02-02: Spell Database Merge
- Merged 326 spells from previous session work (7 separate files → unified spells.json)
- Merged 80+ status effects into statuses.json
- Merged branch with shop system, ranged attacks, terrain, deployment
- All combat phases complete

### Previous Sessions
- Spell system with full targeting and tooltips
- Spellbook system with learning
- AI spell casting
- Status effect tick processing
- Ranged weapon attacks
- Terrain system with effects
- Line of sight and height combat
- Trading system with discounts
- Deployment system

---

## Reference

### Mana Costs by Spell Level
| Level | Mana Cost |
|-------|-----------|
| 1 | 15 |
| 2 | 40 |
| 3 | 75 |
| 4 | 135 |
| 5 | 225 |

### Skill XP Costs
| Level | Cost |
|-------|------|
| 1 | 100 |
| 2 | 300 |
| 3 | 600 |
| 4 | 1000 |
| 5 | 1500 |

### Attribute XP Costs
Base cost = 100, multiplier = 1.5x per point above 10
- 10→11: 100 XP
- 11→12: 150 XP
- 12→13: 225 XP
- etc.

### Spell Schools
- **Elements**: Earth, Water, Fire, Air, Space
- **Specializations**: Sorcery, Enchantment, Summoning, White, Black
- Spells require ONE school at level, gain bonuses from ALL applicable schools

### Status Effect Categories
- **DoT**: burning, poisoned, bleeding
- **HoT**: regenerating
- **CC**: frozen, stunned, knocked_down, feared, charmed
- **Buffs**: strengthened, hastened, shielded, inspired
- **Debuffs**: weakened, slowed, cursed, blinded
