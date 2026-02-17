# Six Worlds - TODO

Last Updated: 2026-02-16

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
- [x] PerkSystem singleton (skill perks, cross perks, base bonuses, affinity bonuses)
- [x] SaveManager singleton (save/load game state)
- [x] MapManager singleton (overworld map, pathfinding, mobs, objects)

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
- [x] Height system with traversal limits and climbing movement costs
- [x] Line of sight (Bresenham's algorithm)
- [x] Height advantage bonuses (accuracy, damage, range)
- [x] Obstacle cover system (trees, rocks, pillars, barricades with dodge bonuses)
- [x] Obstacle destruction (HP-based, aftermath terrain effects)
- [x] Movement modes: normal, levitate (height 2, geo partial immunity), flying (any height, full immunity)
- [x] Cover tooltip on movement hover, cover info in combat log
- [x] Deployment zones with role-based positioning
- [x] Tactician upgrade for manual placement
- [x] AI spell casting and ranged repositioning
- [x] Bleed-out system (3 turns to revive)
- [x] Victory/defeat conditions
- [x] Physical damage subtypes (slashing, crushing, piercing) with per-weapon types
- [x] Consumable items in combat (potions and scrolls with Item button/panel UI)
- [x] Talismans (19 items, mana cost reduction + spellpower boost per school)
- [x] Bombs (8 items, thrown AoE damage + status effects)
- [x] Oils (6 items, weapon coating with bonus damage/status procs for N attacks)
- [x] Active Skills panel in combat (shows active perks and mantras)
- [x] Miss/Dodge/Block floating combat text
- [x] Attack lunge animation (sprite moves toward target and returns)
- [x] Enemy loot drops
- [x] AoE spells damage obstacles and create ground effects

### Character & Progression
- [x] XP-based progression (no levels)
- [x] Exponential attribute cost scaling
- [x] Skill progression (5 levels, costs: 100/300/600/1000/1500)
- [x] Derived stats calculation
- [x] Spellbook system (learn/forget spells)
- [x] Starting spells based on background
- [x] Elemental affinities tracking
- [x] Perk system (skill perks at each level, cross-skill perks)

### Overworld Map
- [x] HoMM-style tile-based exploration
- [x] A* pathfinding with terrain speed modifiers
- [x] Object types (events, pickups, portals)
- [x] Mob system (stationary, patrol, roaming, aggressive pursuit)
- [x] World transitions between realms (portal objects)
- [x] Fog of war
- [x] Map marker overhaul (shapes/colors by type, name labels)
- [x] Procedural map generation from realm configs

### Event System
- [x] Load events from JSON files
- [x] Combat/shop trigger outcomes
- [x] Hell realm events (hell_events.json)

### UI
- [x] Character sheet (attributes, skills, derived stats)
- [x] Spellbook tab with school filtering
- [x] Equipment screen with humanoid doll (12 slots, dual weapon sets)
- [x] Event display with choice coloring
- [x] Combat arena with action buttons
- [x] Spell panel with tooltips
- [x] Combat log
- [x] Turn order display
- [x] Title screen with save/load
- [x] Test launcher

### Data Files
- [x] spells.json (326 spells)
- [x] statuses.json (80+ status effects)
- [x] items.json (weapons, armor, accessories, consumables)
- [x] races.json (sample races for Hell realm)
- [x] skills.json (35 skills by category/element)
- [x] shops.json (5 sample shops)
- [x] upgrades.json (10+ upgrades)
- [x] perks.json (skill perks + cross perks for all 35 skills)
- [x] hell.json map config (procedural generation)
- [x] hell_events.json (realm events)
- [x] hell_enemies.json (enemy archetypes)

---

## High Priority (Core Gameplay)

### Content Expansion (Needed for Playable Loop)
- [ ] Event files for remaining realms (hungry_ghost, animal, human, asura, god)
- [ ] Races for all 6 realms (currently only Hell examples)
- [ ] Background definitions with skill distributions
- [ ] Map configs for remaining realms
- [ ] Enemy archetypes for remaining realms

### Event System Improvements
- [ ] Event chains and prerequisites
- [ ] More events per realm (aim for 20+ per realm)

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

### Content
- [ ] More consumable items (realm-specific potions, higher-level scrolls, more talisman/bomb/oil tiers)
- [ ] More equipment (rare/legendary weapons and armor)
- [ ] More upgrades/perks
- [ ] Alchemy crafting system (create consumables from ingredients)
- [ ] More scroll varieties (AoE scrolls, buff scrolls)

### UI Improvements
- [ ] Tooltip system expansion
- [ ] Upgrade selection popup (choose 1 of 4)
- [ ] Party management screen

### Combat Improvements
- [x] ~~Active skills fully functional (stamina costs, targeting, effects)~~ — DONE (25+ skills with combat_data, stamina/cooldown system)
- [x] ~~AI using consumable items (enemy potion/scroll usage)~~ — DONE (AI health/mana potions, bombs, oils)
- [x] ~~AI using active skills~~ — DONE (scoring system, prioritized decision tree)
- [ ] Enemy-specific physical resistances (e.g., skeletons resist piercing, weak to crushing)
- [x] ~~More obstacle variety (rocks, pillars, trees, destructible objects)~~ — DONE (ObstacleType system)
- [x] ~~Spells creating terrain effects (Fireball leaves fire terrain)~~ — DONE (AoE ground effects)
- [ ] Terrain affecting spell power
- [ ] Environmental spell interactions
- [x] ~~Realm-specific combat terrain themes~~ — DONE (overworld terrain generates realm-appropriate obstacles)

---

## Low Priority (Nice to Have)

### Save/Load Improvements
- [ ] Multiple save slots
- [ ] Auto-save functionality
- [ ] Meta-progression (affinities, persistent upgrades across runs)

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
- [x] ~~**Raising attributes doesn't increase current HP/MP/Stamina**~~ — FIXED (current rises with max)
- [x] ~~**Same consumable items don't stack in item menu**~~ — FIXED (quantity badge on inventory slots)
- [x] ~~**Victory screen waits for End Turn**~~ — FIXED (immediate check after damage/death)
- [x] ~~**Skill/spell levels displayed as floats**~~ — FIXED (wrapped str() with int())

---

## Session Notes

### 2026-02-17: Active Skills, AI Combat Intelligence, Terrain
- **Active Skills System**: Stamina tracking on CombatUnit, cooldown management, 25+ skills with structured combat_data
  - 8 effect types: attack_with_bonus, dash_attack, buff_self, debuff_target, aoe_attack, teleport, stance, heal_self
  - Full targeting flow: select skill -> highlight valid targets -> resolve effect -> combat log
  - Greyed out skills when insufficient stamina/on cooldown/no combat_data
  - Stamina regen per turn (5 + Finesse/5)
- **AI Consumable Usage**: Enemies now generate and use consumable items
  - Inventory generation in EnemySystem based on archetype roles + power level
  - Health potions at <35% HP, mana potions for casters at <30% mana
  - Bombs when 2+ player units clustered, oils before melee attacks
- **AI Active Skills**: Enemies use their perks intelligently
  - Scoring system evaluates each skill based on situation (HP%, distance, enemy count)
  - Prioritized decision tree: emergency heal -> mana restore -> active skills -> spells -> bombs -> oils -> attacks -> reposition
- Terrain Height/Obstacles/Cover (from earlier in session)

### 2026-02-17 (earlier): Terrain Height, Obstacles & Cover System
- Height movement costs: climbing up +1 per level, dropping down free
- Three movement modes: Normal (max 1 height), Levitate (max 2, partial geo immunity), Flying (any height, +1 cost, full geo/melee immunity)
- Obstacle system: TREE (20 HP), ROCK (50 HP), PILLAR (30 HP), BARRICADE (16 HP)
- Cover mechanic: obstacles between attacker/defender grant dodge bonus vs ranged (15-20%)
- Obstacle destruction: trees burn into fire terrain, rocks/pillars become rubble
- AoE spells damage obstacles in blast radius
- Terrain generation creates realm-appropriate obstacles (forest→trees, mountains→rocks, ruins→pillars)
- Cover tooltip on movement hover, cover/height info in combat log
- Height shading on tiles (lighter = higher)

### 2026-02-16: UI Fixes and Combat Polish
- Fixed float display of skill levels, affinities, derived stats across all UI screens
- Added Active Skills panel in combat (perks with "Active" prefix + mantras)
- Added Miss/Dodge/Block floating combat text (Block = shield equipped, Dodge = high dodge)
- Added attack lunge animation (sprite lunges toward target and returns)
- Overhauled worldmap markers: events = squares (green/yellow/red by danger), pickups = rhombuses (yellow gold, green items), name labels on all entities
- Updated TODO.md — checked off ~15 stale items that were already implemented

### 2026-02-15: Save/Load and Title Screen
- SaveManager singleton with full save/load system
- Title screen scene
- Save/load integration into all major systems
- Hell enemy archetypes data file

### 2026-02-15: Talismans, Bombs, and Oils
- 19 talismans (4 tiers for White/Fire/Earth + common for other 7 schools)
- 8 bombs (Fire, Frost, Poison, Smoke, Holy Water, Greater Fire, Acid, Thunder)
- 6 oils (Flame, Frost, Poison, Holy, Whetstone, Paralyzing)
- Talisman integration: mana check accounts for reduction, consumed on matching spell cast
- Bomb targeting: AoE preview, damage scaled by Alchemy, status procs
- Oil integration: bonus damage + status procs on attacks, crit bonus, Alchemy extends duration
- Item panel colors: purple (talisman), orange-red (bomb), teal (oil)

### 2026-02-14: Weapon Damage Types & Consumable Items
- Physical damage subtypes: slashing (swords, axes), crushing (maces, staves, unarmed), piercing (daggers, spears, bows)
- Updated 18 spells and all weapon item_types with proper damage subtypes
- Resistance system checks specific subtype first, falls back to generic "physical"
- Enemy system generates weapons with correct damage_type
- Full consumable item system: 6 potions + 2 scrolls in items.json
- Combat Item button/panel UI with tooltips and scroll targeting/AoE preview
- Potion effects: heal, restore mana, buff/resistance, cleanse status effects
- Scrolls cast spells without mana cost or skill requirements
- Alchemy skill boosts potion effectiveness (10-75% based on level)
- Starter items include 3 health potions + 2 mana potions

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
