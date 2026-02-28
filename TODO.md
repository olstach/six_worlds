# Six Worlds - TODO

Last Updated: 2026-02-28

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
- [x] SaveManager singleton (save/load game state, 3 slots + autosave)
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
- [x] Ammo system for ranged weapons (crossbows, javelins); ammo tracked via Scrap supply
- [x] Crossbow and javelin weapon types added
- [x] Bombs (8 items, thrown AoE damage + status effects)
- [x] Oils (6 items, weapon coating with bonus damage/status procs for N attacks)
- [x] Active Skills panel in combat (shows active perks and mantras)
- [x] Miss/Dodge/Block floating combat text
- [x] Attack lunge animation (sprite moves toward target and returns)
- [x] Enemy loot drops
- [x] AoE spells damage obstacles and create ground effects

### Character & Progression
- [x] XP-based progression (no levels; player starts with 50 XP)
- [x] Supply system (Food, Herbs, Scrap, Reagents) with passive overworld consumption
- [x] Alchemy passive brewing (per-step chance to brew item from unlocked tiers; togglable)
- [x] Starvation system (grace period by CON, then 2% HP/step drain)
- [x] Exponential attribute cost scaling
- [x] Skill progression (10 levels, costs: 5/10/18/28/42/59/80/106/137/175)
- [x] 0-10 skill scale refactor (15-level base bonus tables wired into derived stats, perk/spell levels remapped)
- [x] Derived stats calculation
- [x] Spellbook system (learn/forget spells)
- [x] Starting spells based on background
- [x] Elemental affinities tracking
- [x] Perk system (skill perks at each level, cross-skill perks)
- [x] Races and backgrounds for Hell realm (6 devils + 23 backgrounds with available_races and weights)

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
- [x] Equipment screen with humanoid doll (12 slots, dual weapon sets, mirrored hand slots)
- [x] Supply counters on overworld HUD (Food/Herbs/Scrap/Reagents next to Gold)
- [x] Charm effect descriptions in item tooltip (mana reduction %, spellpower bonus)
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

### Companions / Party Members ← NEXT
Recruiting companions is the single highest-impact missing feature for a playable loop.
- [ ] Companion data structure (NPC characters with attributes, skills, equipment)
- [ ] Recruitment events (meet companion on map, choose to hire/accept)
- [ ] Party tab UI (show all party members, click to view their sheet)
- [ ] Companion AI in combat (same as enemy AI, but Team.PLAYER)
- [ ] Companion death / bleed-out handling (permanent death option?)
- [ ] Companion XP sharing (split equally, or individual?)
- [ ] Starting companion (optional: give player one at game start for first run)

### Content Expansion (Needed for Playable Loop)
- [ ] Event files for remaining realms (hungry_ghost, animal, human, asura, god)
- [ ] Races for all 6 realms (currently only Hell examples)
- [ ] Background definitions with skill distributions
- [ ] Map configs for remaining realms
- [ ] Enemy archetypes for remaining realms

### Map Interactibles System
Three categories of interactive map objects. Hell is the target realm for initial content.

**Category 1 — Simples** (one-time activation, permanent after use)
- [ ] Simple object type in MapManager (flag: used, no reset on return)
- [ ] Effect types: mana restore, HP restore, temp stat/skill bonus (lasts until next combat or event with checks), temp loot chance buff
- [ ] Cursed simples: look identical but deal a negative effect (penalty to a stat, drain XP, apply status) — rare, visually distinct after triggered
- [ ] Hell content: frozen spring (mana), ice shrine (cold resist), burning altar (fire spellpower), bone pile (find weapon), lava vent (fire resist), pain altar (STR buff at HP cost)

**Category 2 — Traders** (peaceful default, with steal/attack/donate karma branches)
Roles to fulfill per realm (not specific object types):
- [ ] General shop (basic items)
- [ ] Blacksmith (weapons, armor, weapon oils)
- [ ] Fletcher (ranged weapons, throwables, light armor)
- [ ] Healer (healing potions, white magic scrolls; rare locations only: raise dead companion for high gold cost + karma implications)
- [ ] Alchemist (potions, bombs, oils)
- [ ] Magic shop (scrolls, charms, magic foci — see magic foci TODO below)
- [ ] Trainer (teaches 1-3 skills or attributes; one-time per trainer instance; cap = max level trainer can teach, e.g. a wandering apprentice might cap at Lv 3, a master at Lv 7)
- [ ] Multi-function locations (towns, camps) use tab UI in event window — 3-4 functions per location
- [ ] First-visit event hook for towns (simple choice: rumors, discount, hidden object)
- [ ] Hell content: Wretched Market (general), Infernal Forge (blacksmith + trainer: Axes/Might), Bone Archer Camp (fletcher + trainer: Ranged/Guile), Mercy Ward (healer, ironic name), Brimstone Lab (alchemist), Void Scribe's Den (magic shop + trainer: Black Magic), Warden's Pit (trainer: Spears/Armor + Might cap 5)

**Category 3 — Event Chains** (1-3 choices deep, world/subregion specific)
- [ ] Event chain data format (prerequisites, follow-up event IDs, outcome state flags)
- [ ] Ability to reference other map objects in outcomes (e.g., "bring them to the healer on this map")
- [ ] Hell-specific chains: bandit ambush of a soul caravan, devil deserter encounter, contraband deal gone wrong, corrupted simple (looks helpful, is cursed), chained pilgrim (penitent NPC — rescue or ignore or exploit), rival party encounter
- [ ] Chains should NOT be reused across realms — always write realm-specific flavor

### Quest System
*(Design phase — implement after event chains are solid)*
- [ ] Quest data structure (active quests, state flags, completion conditions)
- [ ] Quest giver NPCs (subset of trader/event chain interactions)
- [ ] Quest log UI tab in character sheet
- [ ] Quest outcomes: XP rewards, karma, unique items, unlocking new map locations
- [ ] Multi-map quests (state persists across map transitions)
- [ ] Event chains can reference and advance quests
- [ ] Town first-visit hooks can initiate quests

### Event System Improvements
- [ ] Event chains and prerequisites (see Map Interactibles above)
- [x] Hell realm events: 39 total across both zones (19 cold_hell pool + 17 fire_hell pool + 2 fixed landmarks + 1 shared). Includes: Bone Arena, Suffering Sage, Suspicious Gift, Ice Demon Toll, Cursed Pilgrim, Frozen Army (cold); Pyromancer's Challenge, Demon Marketplace, Burning Library, Sinner Gang, Forge Spirit, The Invitation (fire); A Sigh of Relief (both zones)
- [ ] More hell events: both zones at target density (~15+ each). Next focus: event chains and trader NPCs
- [ ] Category 2 traders for hell (Wretched Market, Infernal Forge, Bone Archer Camp, Mercy Ward, Brimstone Lab, Void Scribe's Den, Warden's Pit)
- [ ] Category 3 event chains for hell (soul caravan ambush, devil deserter, contraband deal, chained pilgrim, rival party)
- [ ] More events per realm (aim for 20+ per remaining realm)

### Camp Followers System
- [ ] Non-combat companion data structure
- [ ] Follower recruitment through events
- [ ] Passive bonus application (trade, healing, carrying capacity)
- [ ] UI integration (slot already in Party tab)

### ~~Skill Scale Refactor (1-5 → 1-10)~~ DONE
- [x] Skill levels 1-10 (purchasable); 11-15 accessible via items/race bonuses (display only, yellow in UI)
- [x] Spell unlock tiers at levels 1/3/5/7/9
- [x] 15-level base bonus tables for all 35 skills wired into derived stats via PerkSystem
- [x] Perk required_level remapped (old 1→1, 2→3, 3→5, 4→7, 5→9)
- [x] Attribute cost formula: `max((value - 9) * 3, 2)` per step (10→20 = 165 XP; 10→30 = 630 XP)

### Testing & Polish
- [ ] Test Shop UI thoroughly (buying, selling, spell learning, training)
- [ ] Test terrain effect interactions with spells
- [ ] Balance pass on spell mana costs vs effects
- [ ] Test all 326 spells load and cast correctly

---

## Medium Priority (Content & Polish)

### Content
- [ ] More consumable items (realm-specific potions, higher-level scrolls, more charm/bomb/oil tiers)
- [ ] More equipment (rare/legendary weapons and armor)
- [ ] More upgrades/perks
- [ ] Alchemy crafting system (create consumables from ingredients)
- [ ] More scroll varieties (AoE scrolls, buff scrolls)
- [ ] **Cursed items**: equipment that applies a passive debuff alongside its stats. Player may not know an item is cursed until equipped (reveal on ID or Alchemy skill check). Separate from cursed terrain/simples.
- [x] ~~**Equipment generation system**~~: procedural weapons, armor, and talismans — DONE
- [x] ~~**Talisman system**~~: persistent equippable trinket-slot items with stat/skill/perk bonuses — DONE
- [x] ~~**Equipment traits**~~: weapon/armor modifier system (sharp, reinforced, etc.) — DONE
- [ ] Wire up `random_generate` template items to use the new procedural generation
- [ ] Integrate talisman perk effects into combat (poison_immune, regen, thorns, etc.)
- [ ] Add talisman/equipment generation to shop and loot systems

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
- [x] Multiple save slots (3 slots)
- [x] Auto-save functionality
- [ ] Meta-progression (affinities, persistent upgrades across runs)

### Audio
- [x] SFX system wired (AudioManager autoload, 28 sounds × 6 variants from Helton Yan Pixel Combat pack)
- [x] Sound calls throughout codebase (62+ AudioManager.play calls across all systems)
- [ ] Background music per realm
- [ ] Combat music
- [ ] More spell school sound variety (currently fire vs generic cast only)
- [ ] Active skill sounds
- [ ] Death / unit kill sound

#### SFX Assignment Reference
All sounds defined in `scripts/autoload/audio_manager.gd` → `SOUND_MAP`.
Change any prefix string there to swap a sound without touching other code.
Files live in `resources/audio/sfx/` (6 variants each, picked randomly).

| Event | Sound file prefix |
|---|---|
| Sword / spear hit | `DSGNMisc_MELEE-Sword Slash` |
| Dagger hit | `DSGNMisc_MELEE-Bit Sword` |
| Axe hit | `DSGNImpt_MELEE-Homerunner` |
| Mace hit | `FGHTImpt_HIT-Strong Smack` |
| Unarmed hit | `DSGNImpt_MELEE-Hollow Punch` |
| Martial arts hit | `DSGNImpt_MELEE-Magic Kick` |
| Bow / crossbow | `DSGNMisc_PROJECTILE-Hollow Point` |
| Critical strike stinger | `DSGNMisc_SKILL IMPACT-Critical Strike` |
| Miss / dodge | `DSGNMisc_MOVEMENT-Phase Swish` |
| Spell cast (generic) | `MAGSpel_CAST-Sphere Up` |
| Spell cast (fire school) | `MAGSpel_CAST-Aura Rise` |
| Fire spell impact | `DSGNImpt_EXPLOSION-Fire Hit` |
| Lightning / air impact | `DSGNImpt_EXPLOSION-Electric Hit` |
| Piercing spell impact | `DSGNImpt_EXPLOSION-Mecha Piercing Punch` |
| Generic magic impact | `DSGNMisc_HIT-Spell Hit` |
| Buff applied | `DSGNSynth_BUFF-Generic Buff` |
| Debuff / status | `DSGNSynth_BUFF-Enemy Debuff` |
| Heal received | `MAGAngl_BUFF-Simple Heal` |
| Gold pickup | `DSGNTonl_USABLE-Coin Toss` |
| Item pickup | `DSGNTonl_USABLE-Magic Item` |
| Buff pickup | `DSGNTonl_USABLE-Coin Spend` |
| Cursed pickup | `DSGNSynth_BUFF-Failed Buff` |
| UI click (unwired) | `UIClick_INTERFACE-Positive Click` |
| UI denied (unwired) | `UIMisc_INTERFACE-Denied` |

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

### Mantra System — Finish Implementation
Currently: mantras are toggleable (consume 1 action, track turns active, show [ACTIVE] in skills panel).
Still needed:
- [ ] Per-turn aura effects (area debuffs, damage, etc.) — each mantra in `active_mantras` should apply its effect at turn start via `_on_turn_started` in combat_arena.gd
- [ ] Deity Yoga trigger: after N turns of chanting (e.g. 5), the capstone "Deity Yoga" effect fires (big one-time burst/effect), then mantra resets or stays active at base level
- [ ] Concentration breaks: taking damage above a threshold or being CC'd should interrupt the mantra (erase from active_mantras, log message)
- [ ] Continuous Recitation perk (Ritual 3): allows casting spells while chanting without breaking concentration
- [ ] AI mantra awareness: enemies should prioritize attacking chanters to break concentration

---

## Known Issues

- [x] ~~Derived stats not displaying~~ - FIXED (wrong key)
- [x] ~~Combat turn order issues~~ - FIXED (Timer-based delays instead of async/await)
- [x] ~~Turn order occasionally out of sync (rare)~~ — FIXED
- [x] ~~**Raising attributes doesn't increase current HP/MP/Stamina**~~ — FIXED (current rises with max)
- [x] ~~**Same consumable items don't stack in item menu**~~ — FIXED (quantity badge on inventory slots)
- [x] ~~**Victory screen waits for End Turn**~~ — FIXED (immediate check after damage/death)
- [x] ~~**Skill/spell levels displayed as floats**~~ — FIXED (wrapped str() with int())

---

## Session Notes

### 2026-02-22: 0-10 Skill Refactor, Hell Races & Backgrounds, Interactibles Design
- **0-10 Skill Scale**: Fully implemented — SKILL_COSTS, 15-level base_bonuses for all 35 skills wired into derived stats, perk/spell level remapping, yellow enhanced-level display in character sheet
- **Attribute costs**: New formula `max((value-9)*3, 2)` — 10→20 costs 165 XP, 10→30 costs 630 XP
- **Hell races complete**: All 6 devils (red/blue/yellow/green/black/white) with stats, caps, elemental_affinity_bonuses (+5), starting_skills/spells, reincarnation_weights (red/blue=30, green/yellow=20, black/white=5)
- **23 backgrounds complete**: All have attribute_modifiers, starting_skills, `available_races` (thematic whitelists, empty=universal), and `weight`. New backgrounds: torturer, soul_jailer, infernal_scribe, penitent, spy
- **Interactibles design decided**: 3 categories — Simples (once-use, temp buffs + cursed variants), Traders (roles not objects, tab UI for towns, trainer caps, rare raise-dead), Event Chains (1-3 deep, realm-specific, can reference map objects/quests). Hell content list written in TODO.
- **New TODO items**: Magic Foci, Cursed Items, Quest System

### 2026-02-17 (later): Weapon Requirements for Active Skills
- **Weapon type checks**: Active skills from weapon trees now require the matching weapon equipped
  - Swords perks need a sword, Axes perks need an axe, etc.
  - Unarmed perks require no weapon; Martial Arts allows staff or unarmed
  - Non-weapon skills (Might, Medicine) have no weapon requirement
  - Check in 3 places: CombatManager.use_active_skill(), UI panel (greyed + "[Wrong Weapon]"), AI filtering
  - Helper functions: `get_required_weapon_types()`, `unit_has_required_weapon()` on CombatManager
- **1-10 Skill Scale Refactor**: Added detailed plan to TODO for future session

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

### 2026-02-28: Bug Fixes, Mantra Toggle, Hands Mirroring, Supply HUD
- **Supply system** completed: Food/Herbs/Scrap/Reagents with per-step overworld consumption, starvation, passive skill processing (Medicine/Smithing/Alchemy), HUD counters on overworld
- **Alchemy crafting tiers**: passive per-step brewing from unlocked item pools; player-togglable
- **Ammo system**: crossbows and javelins consume ammo (tracked via supply); Smithing passive restores ammo
- **Mantras** now activatable in combat: toggle on/off with 1 action, show [ACTIVE] purple in skills panel, pulse logged each turn; per-turn effects and Deity Yoga trigger remain for next pass
- **Hands slots** mirrored: equipping gloves fills both hand buttons from one inventory item; stats counted once (hand_l only)
- **Starting XP** set to 50 (enough to buy ~2 skills to level 2 at game start)
- **XP farming** fixed: persistent map objects (merchants, shrines) track used choices in GameState; text/XP options show "Already done" after first use; shop always stays open
- **Attack range** fixed: melee now highlights all 8 adjacent tiles (Chebyshev square) not just 4 (diamond)
- **Frozen Stupa "0"**: fixed pickup range resolver misidentifying 2-string item arrays as numeric ranges
- **Charm tooltips**: now show mana reduction % and spellpower bonus % in item tooltip

### 2026-02-28: Equipment & Talisman Generation System
- Renamed consumable talismans → charms (19 items: mana cost reduction consumables)
- Retyped equippable charms → talismans (persistent trinket-slot accessories)
- Added trinket2 slot (characters now have trinket1 + trinket2 for dual accessories)
- Runtime item infrastructure: hybrid inventory supports procedural gen_XXXX items
- Procedural talisman generation: budget-based with rarity scaling, 4 effect pools
  (attributes, derived stats, skills, resistances), perk system, Buddhist naming
- Equipment trait system: 12 weapon traits + 12 armor traits
- Procedural weapon generation: 7 weapon types × 6 materials × 5 quality levels + traits
- Procedural armor generation: 10 armor types × 6 materials × 5 quality levels + traits
- Data files: talisman_tables.json, equipment_tables.json

### 2026-02-15: Charms (formerly Talismans), Bombs, and Oils
- 19 charms (4 tiers for White/Fire/Earth + common for other 7 schools)
- 8 bombs (Fire, Frost, Poison, Smoke, Holy Water, Greater Fire, Acid, Thunder)
- 6 oils (Flame, Frost, Poison, Holy, Whetstone, Paralyzing)
- Charm integration: mana check accounts for reduction, consumed on matching spell cast
- Bomb targeting: AoE preview, damage scaled by Alchemy, status procs
- Oil integration: bonus damage + status procs on attacks, crit bonus, Alchemy extends duration
- Item panel colors: purple (charm), orange-red (bomb), teal (oil)

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
Spell levels now use 1/3/5/7/9 scale (remapped from old 1-5).
| Level | Mana Cost |
|-------|-----------|
| 1     | 15        |
| 3     | 40        |
| 5     | 75        |
| 7     | 135       |
| 9     | 225       |

### Skill XP Costs (0-10 scale)
| To Level | Cost | Cumulative |
|----------|------|------------|
| 1        | 5    | 5          |
| 2        | 10   | 15         |
| 3        | 18   | 33         |
| 4        | 28   | 61         |
| 5        | 42   | 103        |
| 6        | 59   | 162        |
| 7        | 80   | 242        |
| 8        | 106  | 348        |
| 9        | 137  | 485        |
| 10       | 175  | 660        |

Levels 11-15 are item/race bonus only — not purchasable. Displayed in yellow on character sheet.

### Attribute XP Costs
Formula: `max((current_value - 9) * 3, 2)` per step (minimum 2 XP/step)
- 10→11: 3 XP
- 10→20: 165 XP total (≈ skill level 6)
- 10→30: 630 XP total (≈ skill level 10, endgame godlike)
- Below 10: 2 XP/step flat

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
