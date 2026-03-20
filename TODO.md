# Six Worlds - TODO

Last Updated: 2026-03-15 (session 10, audited)
---

## Completed Systems

### Core Infrastructure
- [x] GameState singleton (world tracking, boss defeats, party gold, run state)
- [x] CharacterSystem singleton (7 attributes, 35 skills, derived stats, party management)
- [x] KarmaSystem singleton (hidden karma, reincarnation, weighted race selection)
- [x] EventManager singleton (3 choice types, party-wide checks, dice rolls, skill-based rolls)
- [x] ItemSystem singleton (equipment database, 12-slot system, inventory, procedural generation)
- [x] ShopSystem singleton (buy/sell, spell learning, skill training, discounts, trainer caps)
- [x] CombatManager singleton (full tactical combat system, loot drops with supply/reagent integration)
- [x] PerkSystem singleton (skill perks, cross perks, base bonuses, affinity bonuses)
- [x] EnemySystem singleton (enemy archetypes, role-based stats, inventory generation)
- [x] SaveManager singleton (save/load game state, 3 slots + autosave)
- [x] MapManager singleton (overworld map, pathfinding, mobs, objects, discovery system)
- [x] AudioManager singleton (SFX system, 28 sounds × 6 variants)
- [x] CompanionSystem singleton (recruit, auto-develop, party XP sharing, overflow handling)
- [x] Supply system (Food/Herbs/Scrap/Reagents with passive consumption, starvation, save/load)

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
- [x] AI using consumable items (health potions, mana potions, bombs, oils)
- [x] AI using active skills (scoring system, prioritized decision tree)
- [x] AI chanter targeting (prioritizes interrupting mantra users)
- [x] Bleed-out system (3 turns to revive); companions use same system
- [x] Victory/defeat conditions
- [x] Physical damage subtypes (slashing, crushing, piercing) with per-weapon types
- [x] Consumable items in combat (potions and scrolls with Item button/panel UI)
- [x] Talismans (equippable trinket-slot accessories with stat/skill/perk bonuses)
- [x] Ammo system for ranged weapons (crossbows, javelins); ammo tracked via Scrap supply
- [x] Crossbow and javelin weapon types added
- [x] Bombs (8 items, thrown AoE damage + status effects)
- [x] Oils (6 items, weapon coating with bonus damage/status procs for N attacks)
- [x] Active Skills panel in combat (shows active perks and mantras, with cooldown/stamina checks)
- [x] Weapon type requirements for active skills (swords need sword equipped, etc.)
- [x] Miss/Dodge/Block floating combat text
- [x] Attack lunge animation (sprite moves toward target and returns)
- [x] Enemy loot drops (supplies, reagents with caster-weighting)
- [x] AoE spells damage obstacles and create ground effects
- [x] ZoC / reaction system (first_to_strike, sentinel, none_shall_pass, frost_warden, skirmisher)
- [x] Stealth system (shadow_strike, soft_step, sudden_end, ambush_predator)
- [x] Kill-triggered free attacks (cleave, relentless, necromancer)
- [x] Status persistence combat→overworld (Poisoned, Bleeding, Burning, Festering, Diseased)
- [x] stat_modifiers infrastructure (timed stat buffs on CombatUnit, duration ticked at turn start)
- [x] Overcast system (pending_overcast_bonus in cast_spell)
- [x] Summon system: 75 summon types from summon_templates.json; AI uses "ground" targeting
- [x] Mantra system: toggleable, per-turn aura effects, Deity Yoga trigger (5 turns), concentration breaks (CC/damage threshold), AI prioritizes interrupting chanters
- [x] Realm-specific combat terrain (overworld terrain generates realm-appropriate obstacles)
- [x] Alchemy crafting system (3 branches × 3 tiers, perk-unlocked, passive brewing toggle)

### Character & Progression
- [x] XP-based progression (no levels; player starts with 50 XP)
- [x] Supply system (Food, Herbs, Scrap, Reagents) with passive overworld consumption
- [x] Starvation system (grace period by CON, then 2% HP/step drain)
- [x] Exponential attribute cost scaling (`max((value-9)*3, 2)` per step)
- [x] Skill progression (10 levels, costs: 5/10/18/28/42/59/80/106/137/175)
- [x] 0-10 skill scale (15-level base bonus tables wired into derived stats; spells/perks remapped)
- [x] Item/race bonuses push effective skill to 15 (display in yellow, not purchasable)
- [x] Derived stats calculation
- [x] Spellbook system (learn/forget spells)
- [x] Starting spells based on background
- [x] Elemental affinities tracking with bonuses
- [x] Perk system (skill perks at each level, cross-skill perks, base bonuses)
- [x] Races for **all 6 realms** (22 total: 6 hell + 4 human + 3 animal + 3 god + 3 hungry_ghost + 2 asura)
- [x] 25 backgrounds with attribute_modifiers, starting_skills, available_races, weights

### Companions
- [x] Companion data structure (NPC characters with attributes, skills, equipment, build_weights)
- [x] Companion recruitment (via events `recruit_companion` outcome + shop companion tab)
- [x] Companion recruit popup (portrait, stats, flavor text, hire button)
- [x] Party tab UI in character sheet (all party members shown as cards with XP bars)
- [x] Companion XP sharing (multipliers: ×1.5 solo, ×1.25 duo, ×1.0 3-4, ×0.85 5-6, ×0.7 7-8)
- [x] Companion AI in combat (same AI as enemies, Team.PLAYER)
- [x] Companion bleed-out (same 3-turn system as player)
- [x] Weighted auto-distribute XP (build_weights, surplus redistribution, overflow mode)
- [x] Overflow popup (companion_overflow signal, emergent weight redistribution)
- [x] Manual XP spending on companions (XP-swap pattern via free_xp)
- [x] Autodevelop toggle per companion
- [x] 23 hell companions fully defined in companions.json; wired into all 9 hell shops

### Overworld Map
- [x] HoMM-style tile-based exploration with A* pathfinding and terrain speed modifiers
- [x] Object types (events, pickups, portals)
- [x] Mob system (stationary, patrol, roaming, aggressive pursuit)
- [x] World transitions between realms (portal objects)
- [x] Fog of war
- [x] Map marker overhaul (shapes/colors by type, name labels)
- [x] Procedural map generation from realm configs (hell: 96×72)
- [x] Variable passability (water_walking, flight, lava_immunity abilities)
- [x] Exploration discovery (skill-based hidden finds per terrain)
- [x] Status persistence (DoT continues between overworld steps)
- [x] Spell shrine pickups and spell guild locations (procedural placement)

### Event System
- [x] Load events from JSON files; 3 choice types (default/blue/yellow); party-wide checks; skill-based dice rolls
- [x] Combat/shop trigger outcomes; event→combat→result→continue flow
- [x] Recruit companion event outcome type
- [x] Hell realm events: 39 total (19 cold_hell pool + 17 fire_hell pool + 2 landmarks + 1 shared)
- [x] Hell trader events with steal/attack/donate/comedy karma branches
- [x] Karma assignments per choice type (steal→hungry_ghost, attack→hell, donate→god, comedy→human)
- [x] Event chains: `set_flags` outcome key writes world-state flags; `prerequisite: {flag, value}` on choices hides them when unmet; `follow_up_event` chains to next event on Continue
- [x] Quest system: `register_quest` outcome key registers quest in GameState.active_quests; steps resolved via flag checks; Quest Log tab in character sheet (sorted by completion)

### Shops / Traders
- [x] Buy/sell items; spell learning; skill training; companion recruitment
- [x] Trainer caps (max_skill_level enforced; "Capped" in UI)
- [x] All hell trader types present: general store, blacksmith, fletcher, healer, alchemist, magic shop, trainers, wandering peddler
- [x] Shop UI: items sorted by type/name; companion tab shows free_xp + autodevelop toggle
- [x] Procedural shop stock (generated weapons, armor, talismans)

### UI
- [x] Character sheet (attributes, skills, derived stats, yellow for boosted levels)
- [x] Spellbook tab with school filtering
- [x] Equipment screen with humanoid doll (12 slots, dual weapon sets, mirrored hand slots)
- [x] Supply counters on overworld HUD (Food/Herbs/Scrap/Reagents + Gold)
- [x] Crafting tab (key R; character picker, item type filter, recipe list with reagent costs)
- [x] Perk selection popup (shows up to 4 perk cards, clickable)
- [x] Event display with choice coloring, keyboard shortcuts (1-9), Leave button on softlock
- [x] Combat arena with action buttons, spell panel, combat log, turn order display
- [x] Title screen with save/load (3 slots + autosave)
- [x] Test launcher

### Data Files
- [x] spells.json (326 spells across 10 schools)
- [x] statuses.json (80+ status effects, fully reworked)
- [x] items.json (weapons, armor, accessories, consumables, bombs, oils, talismans, scrolls × 17)
- [x] races.json (22 races across all 6 realms + 25 backgrounds)
- [x] skills.json (35 skills by category/element)
- [x] shops.json (9+ shops covering all hell trader roles)
- [x] upgrades.json (10+ upgrades)
- [x] perks.json (skill perks + cross perks for all 35 skills; 527 entries)
- [x] summon_templates.json (75 summon types, tiered by spell level)
- [x] hell.json map config (procedural generation, 96×72)
- [x] hell_events.json (39 hell events)
- [x] hell_archetypes.json + hell_encounters.json (19 archetypes, 12 encounters)
- [x] supplies.json (4 supply types)
- [x] equipment_tables.json + talisman_tables.json (procedural generation tables)

---

## High Priority (Core Gameplay)

### [HIGH] Equipment Material Tiers — Upper Progression Missing
The intended material progression above Steel has not been implemented. Current tiers top out at
`mithril` and `demon_forged`, which were added generically and should be replaced. The correct
upper tier design (from design notes not yet in the repo) is:

  bone → wood → bronze / obsidian(branch) → iron → steel → **damascene** → **sky-iron** → **vajra**

- `mithril` and `demon_forged` are placeholders — decide whether to remove, repurpose as realm
  branches (demon_forged = hell branch; mithril = god realm branch?), or rename entirely
- `damascene` — Damascus-style folded steel; excellent edge retention, mid-high tier
- `sky-iron` (`gnam lcags`) — Tibetan meteoritic iron, used in real ritual implements including
  vajras; penultimate mortal-world material
- `vajra` as material — indestructible divine metal; near-exclusively god realm / legendary drops;
  stat tables and full design to be retrieved from Olaf's notes
- Once tiers are corrected, update: equipment_tables.json (materials + tier_to_material_weights),
  items.json (static weapon durability values), shops.json (all realm shop inventories),
  map loot tables, and tier_to_material_weights for each realm

### [HIGH] Ranged Ammo Scaling — Arrows and Bolts as Material Items
Bows and crossbows currently treat ammo as a flat supply counter (Scrap-backed). With the
material tier system, arrows and bolts should scale with their material like weapons do.

- Add arrow and bolt item types to items.json across the full material progression:
  `bone_arrow`, `wooden_arrow`, `bronze_arrow`, `iron_arrow`, `steel_arrow`, etc.
  (obsidian_arrow as brittle but high-damage off-branch; sky-iron/vajra at high tiers)
- Bolts (crossbow ammo) follow the same material ladder
- Ammo material determines damage bonus added to the ranged weapon's base damage
- Low-tier ammo (bone, wood) should be common/cheap; high-tier rare/expensive
- Smithing passive restores ammo using lowest available material in inventory
- Shops and loot tables need ammo entries per realm (hell starts with bone/wooden arrows)
- Design question: does carrying different ammo types require inventory slots, or is it
  abstracted as a supply pool with a material-quality modifier?

### ~~Companion Auto-Development Refactor~~ DONE
- [x] All 24 companions in companions.json already have skill-only `build_weights` (no attr keys)
- [x] `_derive_attr_weights()` in companion_system.gd derives attr weights from skill weights using `primary_attribute` (×1.0) and `secondary_attribute` (×0.5) from skills.json
- [x] Budget split: `attr_ratio` (default 0.35, per-companion override supported) × budget → attrs; remainder → skills
- [x] Both `_try_autodevelop()` and `recruit()` use the split; overflow mode unaffected

### Companion Auto-Development Refactor
*(Partially superseded — skills.json already has `primary_attribute` and `secondary_attribute` fields per skill, singular form. The planned array refactor below was designed before that existed. Decide whether to proceed or drop.)*
- [ ] Refactor companion XP distribution to derive attribute targets from active skill's `primary_attribute`/`secondary_attribute` automatically, rather than listing attributes manually in `build_weights`
- [ ] Replace explicit attribute keys in `companions.json` `build_weights` with an `"attr_ratio": 0.3` field (fraction of auto-XP going to attributes vs skills)
- [ ] Update `companion_system.gd` `_auto_distribute()` accordingly

### Companions / Party Members
- [x] ~~Companion data structure~~ — DONE (CompanionSystem, companions.json with 23 companions)
- [x] ~~Recruitment events (hire from shop)~~ — DONE (Companions tab in shop_ui; hell_tavern in shops.json)
- [x] ~~Party tab UI (show all party members, click to view their sheet)~~ — DONE (Party tab in main_menu; View Stats + Remove buttons; derived stats bug fixed)
- [x] ~~Companion XP sharing~~ — DONE (CompanionSystem.apply_party_xp with party-size multiplier)
- [x] ~~Companion AI in combat~~ — DONE: companions are player-controlled (Team.PLAYER); summons use AI (summoner_id != 0 triggers ai_timer regardless of team)
- [ ] Companion death / bleed-out handling — currently companions die like enemies with no special treatment; no permanent-death option, no party-wipe check distinct from normal defeat
- [ ] Recruitment events on the overworld map — `recruit_companion` outcome type IS wired in event_manager.gd; just needs actual events in hell_events.json that use it
- [ ] Starting companion (optional: give player one at game start for first run) — no logic in game_state.gd or character_system.gd
- [ ] Companion definitions for remaining realms (companions.json currently has hell companions only)

### Content Expansion (Needed for Playable Loop)
Hell realm is largely production-quality. Other realms are structural gaps.
- [ ] Event files for remaining realms — only hell_events.json exists; no files for hungry_ghost, animal, human, asura, god
- [x] ~~Races for all 6 realms~~ — DONE: 21 races across all realms (Hell 6, Hungry Ghost 3, Animal 3, Human 4, Asura 2, God 3)
- [x] ~~Background definitions with skill distributions~~ — DONE: 25 backgrounds in races.json with attribute_modifiers, starting_skills, available_races whitelists
- [ ] Map configs for remaining realms — only hell.json exists in resources/data/map_configs/
- [ ] Enemy archetypes + encounters for remaining realms — only hell_archetypes.json + hell_encounters.json exist

### Map Interactibles System
Three categories of interactive map objects. Hell is the target realm for initial content.

**Category 1 — Simples** (one-time activation, permanent after use)
- [x] ~~Simple object type in MapManager~~ — DONE (PICKUP ObjectType with one_time flag, reward system: gold/xp/item/heal/mana/buff/damage/cleanse/karma)
- [x] ~~Effect types~~ — DONE (mana restore, HP restore, temp stat/skill buff with combats_remaining, loot chance buff, XP gain buff, item drops)
- [x] ~~Cursed simples~~ — DONE (damage reward type, hell config has "Warm Glow" and "Flickering Light" cursed pickups)
- [x] ~~Hell content~~ — DONE (25+ pickup templates in hell.json map config: Frozen Fountain, Ice Shrine, Burning Altar, Pain Altar, Lava Vent, Mourning Flame, Prayer Flags, etc.)
- [x] ~~Bone pile (find weapon) simple~~ — DONE (cold_hell: "Bone Pile", fire_hell: "Charred Bone Pile"; both drop random weapon from iron/wood pool)

**Category 2 — Traders** (peaceful default, with steal/attack/donate karma branches)
Roles to fulfill per realm (not specific object types):
- [x] ~~General shop (basic items)~~ — DONE (hell_merchant, frozen_merchant, ember_merchant, wandering_peddler, general_store in shops.json)
- [x] ~~Blacksmith~~ — DONE (infernal_forge: axes/maces/armor/oils, trains Axes/Maces/Might; fire_hell map pool)
- [x] ~~Fletcher~~ — DONE (bone_archer_camp: bows/daggers/throwables/light armor, trains Ranged/Daggers/Guile; cold_hell map pool)
- [x] ~~Healer~~ — DONE (mercy_ward: potions/white spells, trains Medicine; both zones map pool)
- [x] ~~Alchemist~~ — DONE (brimstone_lab: bombs/oils/potions/reagents, trains Alchemy; fire_hell map pool)
- [x] ~~Magic shop (scrolls, charms, magic foci)~~ — DONE (demon_sorcerer in shops.json sells spells + reagents)
- [x] ~~Trainer (teaches skills/attributes)~~ — DONE (wandering_sage trains White/Sorcery/Yoga + Focus/Awareness; weapon_master trains 7 combat skills + Str/Fin; ShopSystem has full training tab)
- [ ] Multi-function locations (towns, camps) use tab UI in event window — not implemented; events use standard choice-based dialogue only
- [ ] First-visit event hook for towns — no first-visit flag system in event_manager.gd or map_manager.gd
- [x] ~~Steal/attack/donate karma branches on trader interactions~~ — DONE (all 8 hell trader events: steal roll on all, attack on 3, donate on 2, comedy wildcard on 5 with success/failure outcomes). Skill-based dice rolls now supported in event_manager (skill: comedy/performance instead of attribute)
- [x] ~~Trainer caps~~ — DONE (max_skill_level in shop training dict; ShopSystem enforces cap, UI shows "Capped" in yellow)
- [x] ~~Hell-specific named locations~~ — DONE (Infernal Forge, Bone Archer Camp, Mercy Ward, Brimstone Lab, Warden's Pit — all in shops.json + hell_events.json + hell.json map pools)

**Category 3 — Event Chains** (1-3 choices deep, world/subregion specific)
- [x] ~~Event chain data format~~ — DONE (`set_flags`, `prerequisite`, `follow_up_event` all implemented)
- [ ] Hell-specific chains still needed: soul caravan ambush, contraband deal gone wrong, corrupted simple, rival party encounter
- [ ] Chains should NOT be reused across realms — always write realm-specific flavor

### ~~Event Chains + Quest System~~ DONE
- [x] `set_flags` outcome key — write arbitrary world-state flags from any event outcome
- [x] `prerequisite: {flag, value}` on choices — hides choice entirely when flag not met
- [x] `follow_up_event` on any outcome — chains to next event on Continue; starts fresh
- [x] `register_quest` outcome key — registers quest in `GameState.active_quests`; idempotent
- [x] **Journal tab** (renamed from Quests, index 5) — two-panel layout; J keybinding; completed quest history; `GameState.is_quest_step_done()` public API
- [x] **Quest board overlay** — `quest_board` outcome type; randomised pool-draw from quests.json; Accept buttons; realm filter
- [x] **quests.json** — global quest pool with steps, rewards, realm tags; 3 sample hell quests
- [x] **Quest completion auto-detection** — `set_flag()` triggers `check_quest_completion()`; awards XP/gold/karma; logs completion
- [x] **Overworld message log** — session-only toggle panel (💬 button); all toasts recorded
- [x] `GameState.flags` dict + `set_flag()`/`get_flag()` — persisted in save/load, reset on new game

### Event System — Content Still Needed
- [ ] Hell-specific event chains: soul caravan ambush, devil deserter, contraband deal, corrupted simple, chained pilgrim, rival party
- [ ] More hell events: both zones still under target density (~15+ each)
- [ ] Multi-function locations: tab UI inside event window (3-4 functions per town); no tab switching in event_display yet
- [ ] First-visit event hook for towns: `visited_locations` set in GameState, trigger one-time intro event

### Quest Content (system ready, quests need writing)
- [ ] Hell quests: write using `register_quest` + `set_flags` + `prerequisite` in hell_events.json, OR add to quests.json for quest board pool
- [ ] Quest giver NPCs — any trader or event can register a quest; no code changes needed
- [ ] Quest board locations — add `"quest_board"` outcome to tavern/town events

### Camp Followers System
UI stub exists in Party tab (`_update_followers_list()` / `_create_follower_card()`) but returns hardcoded empty list. No system exists yet.
- [ ] Non-combat follower data structure in GameState
- [ ] Follower recruitment through events
- [ ] Passive bonus application (trade discounts, healing rate, carrying capacity)
- [ ] Wire UI stub to actual follower data

### ~~Skill Scale Refactor (1-5 → 1-10)~~ DONE
- [x] Skill levels 1-10 (purchasable); 11-15 accessible via items/race bonuses (display only, yellow in UI)
- [x] Spell unlock tiers at levels 1/3/5/7/9
- [x] 15-level base bonus tables for all 35 skills wired into derived stats via PerkSystem
- [x] Perk required_level remapped (old 1→1, 2→3, 3→5, 4→7, 5→9)
- [x] Attribute cost formula: `max((value - 9) * 3, 2)` per step (10→20 = 165 XP; 10→30 = 630 XP)

### Testing & Polish
- [ ] Playtest hell realm end-to-end (combat, shops, events, quest board, portal transition)
- [ ] Test Shop UI thoroughly (buying, selling, spell learning, training, companions tab, rest tab)
- [ ] Test terrain effect interactions with spells
- [ ] Balance pass on spell mana costs vs effects
- [ ] Test all 326 spells load and cast correctly
- [ ] Test Shop UI thoroughly (buying, selling, spell learning, training, companion tab)
- [ ] Test terrain effect interactions with spells
- [ ] Item flavor text: `space_charm_common` and `rations` reportedly show broken tooltip — needs in-game testing to reproduce

### Perk Wiring — Remaining Deferred
~441 passive perks total; all per-skill base bonuses flow through PerkSystem → derived stats automatically. The following active skill / complex perks are intentionally deferred and still stubbed with error messages in combat_manager.gd:

**Needs new systems before implementation:**
- `metamagic` (Sorcery 3 + Ritual 3) — needs pre-cast modal dialog to modify next spell (range/AoE/element)
- ~~`continuous_recitation`~~ DONE — casting now calls `_interrupt_mantras()` on the caster; perk bypasses this check in both the summon path and the normal path of `cast_spell()`
- `void_touched` — space spells leave void terrain tiles; needs `void` tile type in combat_grid
- `roles_assigned` / `tactical_synergy` — need role designation UI (Vanguard/Striker/Support/Control assigned at combat start)
- `create_terrain` perks (inscribed_circle, fog_of_war, black_ice, raise_wall, gravity_well, improvised_barricade, prepared_ground) — needs timed terrain tile system
- `create_images` / `smoke_and_mirrors` — needs illusion/decoy unit system
- `imbued_attack` / `arcane_archer` — ranged attack with spell element; needs attack+spell hybrid
- `mass_teleport` — teleport all units
- `recruit_or_pacify` / `magnetism` — convert/pacify enemy unit
- `place_trap` / `trap_maker` — persistent terrain trap that triggers on enemy movement
- `attune_charm` — consume equipped talisman for next-spell bonus (talisman passive consumption works; this is the active version)
- `steal_item` / `the_invisible_hand` — steal equipped item from enemy
- `choose_one` / `improvised_masterpiece` — needs sub-choice UI during active skill use
- `guard_ally` / `stalwart_guardian` — redirect attacks targeting nearby ally to self
- `summon_aura` / `host_of_the_winds` — DONE (`_process_summon_aura()` at combat_manager.gd:6105)

**Complexity note:** `continuous_recitation` is the simplest remaining item — one guard in `cast_spell()`.

---

## Medium Priority (Content & Polish)

### Content
- [ ] More consumable items — currently: 13 potions, 15 bombs, 12 oils, 21 scrolls, 21 charms; all generic (no realm-specific variants)
- [ ] More equipment — 24 rare/epic items exist; no legendary tier; could use more variety
- [ ] More upgrades/perks
- [x] ~~Alchemy crafting system~~: Reagents supply type, 3 crafting branches (Remedies/Munitions/Applications) × 3 tiers, perk-unlocked, passive brewing toggle — DONE
- [x] ~~Resource-gathering perks~~: Alchemical Recycling (Alchemy 3), Herbalist (Medicine 3), Scavenger (Smithing 3) — DONE
- [x] ~~Crafting UI tab~~ — DONE (key: R; character picker, Potions/Bombs/Oils filter, craftable/locked recipe list with reagent cost)
- [x] ~~More scroll varieties~~: 17 scrolls added (common: magic_missile, voidbolt, shocking_grasp, stone_spike, bless, cure, slow; uncommon: fireball, blizzard, chain_lightning, earthquake, haste, stone_skin, regeneration, blink, dispel, confusion). Distributed to demon_sorcerer, wandering_sage, general_store, hell_town_magic, hell_yogini_circle, mercy_ward
- [ ] **Cursed items**: not implemented — "cursed" is currently only a status effect and a terrain type; no cursed equipment in items.json
- [x] ~~**Equipment generation system**~~: procedural weapons, armor, and talismans — DONE
- [x] ~~**Talisman system**~~: persistent equippable trinket-slot items with stat/skill/perk bonuses — DONE
- [x] ~~**Equipment traits**~~: weapon/armor modifier system (sharp, reinforced, etc.) — DONE
- [x] ~~Wire up `random_generate` template items to use the new procedural generation~~ — DONE
- [x] ~~Integrate talisman perk effects into combat (poison_immune, regen, thorns, etc.)~~ — DONE (all combat perks wired; karma_sight is event-system only)
- [x] ~~Add talisman/equipment generation to shop and loot systems~~ — DONE (procedural items in loot drops + auto-generated shop stock)

### UI Improvements
- [ ] Tooltip system expansion — item_tooltip.gd works for items; no tooltips on status effects, terrain tiles, or turn order icons in combat
- [ ] Upgrade selection popup (choose 1 of 4) — no scene or system exists
- [x] ~~Party management screen~~ — DONE (session 10): Party tab in main_menu shows all members with HP/MP/ST bars, View Stats button switches to Stats tab for any member, Remove button dismisses companions

### Combat Improvements
- [x] ~~Active skills fully functional (stamina costs, targeting, effects)~~ — DONE (25+ skills with combat_data, stamina/cooldown system)
- [x] ~~AI using consumable items (enemy potion/scroll usage)~~ — DONE (AI health/mana potions, bombs, oils)
- [x] ~~AI using active skills~~ — DONE (scoring system, prioritized decision tree)
- [x] ~~Enemy-specific physical resistances~~ — DONE (hell_archetypes.json: frozen_revenant +pierce/slash, -crush; lava_golem/mountain_guardian +slash/pierce; frost_guardian +pierce/slash; demons +pierce/slash)
- [x] ~~More obstacle variety (rocks, pillars, trees, destructible objects)~~ — DONE (ObstacleType system)
- [x] ~~Spells creating terrain effects (Fireball leaves fire terrain)~~ — DONE (AoE ground effects)
- [ ] Terrain affecting spell power — no terrain-based spellpower modifiers in combat_manager.gd cast_spell()
- [ ] Environmental spell interactions — spells create terrain (done); terrain does not yet buff/debuff spells of matching element
- [x] ~~Realm-specific combat terrain themes~~ — DONE (overworld terrain generates realm-appropriate obstacles)

---

## Low Priority (Nice to Have)

### Save/Load Improvements
- [x] Multiple save slots (3 slots)
- [x] Auto-save functionality
- [ ] Meta-progression (affinities, persistent upgrades across runs) — not implemented; save_manager.gd handles per-run state only, no cross-run persistence

### Audio
- [x] SFX system wired (AudioManager autoload, 28 sounds × 6 variants from Helton Yan Pixel Combat pack)
- [x] Sound calls throughout codebase (62+ AudioManager.play calls across all systems)
- [ ] Background music per realm — audio_manager.gd has SFX only; no music system at all
- [ ] Combat music — same; no music infrastructure
- [ ] More spell school sound variety — Air, Water, Earth have no dedicated impact sounds (only fire + generic exist)
- [ ] Active skill sounds — no AudioManager.play calls in active skill resolution
- [ ] Death / unit kill sound — no death sound defined or triggered

---

## Known Issues

- [ ] **Item flavor text (needs runtime)**: `space_charm_common` and `rations` reportedly show broken flavor text in item tooltip — static code looks correct; needs in-game testing to reproduce
- [ ] **combat_grid.gd:458** — TODO comment "Check team" — possible edge case in team check logic; needs review
- [ ] **Karma realm origins not loaded from data**: `karma_system.gd:154,179` — per-realm karma starting values are hardcoded, not loaded from background data. Low priority until other realms exist.
- [ ] **Enemy weapon placeholder names**: `enemy_system.gd:306,314` — auto-generated weapons get generic names. Minor cosmetic issue.
- [ ] **Companion permanent death**: companions use the bleed-out system but there's no "permanent death" toggle option implemented yet.

---

## Design Questions (Unresolved)

### Karma Visibility
- Currently completely hidden (thematic)
- Should Yoga skill unlock karma meditation to see rough scores?
- Or keep totally mysterious?

### Combat Balance
- Spell mana costs by level: 15/40/75/135/225 — needs playtesting
- Status effect durations and tick damage
- AI difficulty scaling

### Miniboss & Boss Battle Mechanics
- Brainstorm unique per-fight mechanics for realm minibosses and end-bosses (e.g. swallow mechanic for Great Devourer, resurrection aura for Bone Lord, etc.)
- Design should be distinct from standard combat — consider multi-phase fights, special win/lose conditions, environmental interactions
- Hungry Ghost candidates: Bone Lord (earth magic + undead commander), Great Devourer (shaza), Mirror of the Setting Sun (copper construct), Matriarch of All Longing (yidag)

### Realm-Specific Mechanics
- Hell: Pure combat focus ← current
- Hungry Ghost: Resource scarcity?
- Animal: Mix of combat and negotiation
- Human: Heavy dialogue/quest focus — three zones:
  - **West** (Oddiyana/Gandhara steppe): Scythian-like nomads, cavalry culture → Ranged, Guile, Daggers
  - **NE** (Zhang-Zhung): proto-Tibetan shamanic Bön, yak herders, high altitude → Ritual, Yoga, Earth magic
  - **SE** (coastal trade cities): wealthy cosmopolitan India-adjacent mercantile culture → Trade, Persuasion, Alchemy
- Asura: Competitive events, duels?
- God: Almost no combat, diplomacy/trade?

### Mantra System
- Continuous Recitation (Ritual 3): wire in `cast_spell()` — skip mantra interrupt if perk active
- Deferred DY effects (simplified in-place): some deity yoga bursts are stat bonuses rather than true unit spawns; acceptable for now

---

## Session Notes

### 2026-03-15 (Session 10): Full Codebase Audit
- Audited all open TODO items against actual codebase — found ~15 items marked as TODO that were already fully implemented
- **Companions** fully implemented: recruit, party tab, XP sharing, AI in combat, bleed-out — entire section moved to Completed
- **Mantra system** substantially complete: per-turn effects, Deity Yoga trigger (5 turns), concentration breaks (CC + damage threshold), AI chanter targeting all wired. Only `continuous_recitation` perk remains (1-line guard in cast_spell)
- **Races** complete for all 6 realms: 22 total (added in offline work `f0f77eb`)
- **25 backgrounds** defined in races.json with attribute_modifiers, starting_skills, available_races
- **Perk wiring**: `summon_aura` (`_process_summon_aura`) confirmed DONE. `attune_charm` talisman passive mechanism works; active `attune_charm` perk still deferred.
- **Content gap confirmed**: Only hell has events, enemies, and map config; other realms have race data but no gameplay content
- **Upgrade selection popup** confirmed implemented (`_show_perk_popup()` in main_menu.gd)
- **Camp Followers**: UI stub exists but no actual system — added to High Priority
- Removed stale TODO items that duplicated completed sections

### 2026-03-14 (Session 9): Codebase Audit + Summoning School Implementation
- Systematic audit — all 13 autoloads, 11 scenes, 80 signals, 137 statuses verified
- No critical bugs found; hell realm is production-quality
- Summoning school: 75 summon types in summon_templates.json; `_spawn_summoned_unit()`, "ground" targeting, AI support, stat scaling
- Open issues logged: combat_grid.gd:458 team check, karma hardcoded defaults, enemy weapon placeholder names

### 2026-03-08 (Session 8): Perk Wiring + Active Skill Effects + Mantra Infrastructure
- stat_modifiers infrastructure; overcast system; will_miss_next_attack; taunt system
- 20 new active skill effect type resolvers
- call_the_shot (Leadership active) wired; mark_target, once_per_turn enforcement
- ZoC / reaction system; stealth system; kill-triggered free attacks (cleave, relentless, necromancer)

### 2026-03-08 (Session 2): Bug Fixes + Scrolls/Events/Trainer Caps + Status Persistence
- 17 new scrolls; trainer caps; hell trader event branches (steal/attack/donate/comedy)
- Status persistence combat→overworld (DoT continues between steps)
- Spell shrines + spell guilds placed by map generator
- Multiple bug fixes (crafting key, starter equipment, weapon set swap)

### 2026-03-06: Reagents, Alchemy Crafting Tiers, Resource-Gathering Perks
- Reagents (4th supply type); 3 alchemy branches × 3 tiers (perk-unlocked); passive brewing
- Resource-gathering perks: Alchemical Recycling, Herbalist, Scavenger

### 2026-02-28: Supply System, Alchemy, Ammo, Mantra Toggle, Mirrored Hands
- Supply system complete; ammo system; mantra toggleable in combat
- Hands slots mirrored; starting XP = 50; XP farming fixed; melee range fixed (Chebyshev)

### 2026-02-28 (Equipment): Equipment & Talisman Generation System
- Procedural weapons (7 types × 6 materials × 5 quality + traits)
- Procedural armor (10 types × 6 materials × 5 quality + traits)
- Procedural talismans (budget-based, 4 effect pools, Buddhist naming)

### 2026-02-22: 0-10 Skill Refactor + Hell Races & Backgrounds + Interactibles Design
- Skill scale 0-10 fully implemented; 15-level base_bonuses wired; perk/spell levels remapped
- All 6 hell races + 23 backgrounds defined with available_races whitelists
- Interactibles design: 3 categories (Simples, Traders, Event Chains)

### 2026-02-17: Active Skills, AI Combat Intelligence, Terrain Height
- Active skills: stamina/cooldown system, 25+ skills with combat_data, 8 effect types
- AI: consumables, active skills, ranged repositioning
- Terrain: height costs, levitate/flying modes, obstacle cover system

### 2026-02-15: Save/Load, Title Screen, Hell Enemy Archetypes
- SaveManager with 3-slot save/load; title screen; hell enemy archetypes

### 2026-02-14: Weapon Damage Types & Consumable Items
- Physical damage subtypes; 6 potions + 2 scrolls; combat Item panel; Alchemy potion scaling

### 2026-02-15 (Charms): Charms, Bombs, Oils
- 19 charms (mana cost reduction consumables); 8 bombs; 6 oils

### 2026-02-02: Spell Database Merge
- 326 spells (7 files → unified spells.json); 80+ statuses; shop system merge; all combat phases complete

---

## Reference

### Mana Costs by Spell Level
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

Levels 11-15 are item/race bonus only — not purchasable. Displayed in yellow.

### Attribute XP Costs
Formula: `max((current_value - 9) * 3, 2)` per step (minimum 2 XP/step)
- 10→11: 3 XP; 10→20: 165 XP total; 10→30: 630 XP total
- Below 10: 2 XP/step flat

### Spell Schools
- **Elements**: Earth, Water, Fire, Air, Space
- **Specializations**: Sorcery, Enchantment, Summoning, White, Black
- Spells require ONE school at level; gain bonuses from ALL applicable schools

### Status Effect Categories
- **DoT**: burning, poisoned, bleeding
- **HoT**: regenerating
- **CC**: frozen, stunned, knocked_down, feared, charmed
- **Buffs**: strengthened, hastened, shielded, inspired
- **Debuffs**: weakened, slowed, cursed, blinded

### SFX Assignment Reference
All sounds defined in `scripts/autoload/audio_manager.gd` → `SOUND_MAP`.

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
- [ ] Character portraits — portrait field exists on companions but all are empty strings; no portrait images in project
- [ ] Enemy sprites — enemies rendered as colored rectangles in combat; no sprite assets
- [ ] Tile sets for each realm — no tileset resources found; only tibetan_theme.tres (UI theme)
- [ ] Spell effects — no particle or animation system for spell visuals; attack lunge animation exists but no spell-specific VFX
- [ ] UI artwork (Tibetan thangka style) — tibetan_theme.tres provides colors/fonts; no custom artwork assets

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

### ~~Mantra System~~ — DONE (session 10)
- [x] Per-turn aura effects wired via `_process_mantra_effects()` at turn start
- [x] Deity Yoga trigger: after N turns, capstone burst fires via `_trigger_deity_yoga()`
- [x] Concentration breaks: damage threshold + CC interrupts mantra
- [x] Continuous Recitation perk (Ritual 3): cast spells while chanting
- [x] AI mantra awareness: enemies prioritize attacking chanters

---

## Known Issues

- [x] ~~**Town naming**~~ — DONE (procedural Tibetan/Sanskrit name pool, commit bff12ac)
- [ ] **Item flavor text (needs runtime)**: `space_charm_common` and `rations` reportedly show broken flavor text in item tooltip — static code looks correct; needs in-game testing to reproduce
- [ ] **combat_grid.gd:458** — TODO comment "Check team" — pathfinding skips enemies but team check logic may have an edge case; needs review
- [ ] **Karma realm origins not loaded from data**: `karma_system.gd:154,179` — per-realm karma starting values hardcoded, not loaded from background data. Low priority until other realms exist.
- [ ] **Enemy weapon placeholder names**: `enemy_system.gd:306,314` — auto-generated weapons get names like "Enemy's Claws" / "Enemy's Weapon". Minor cosmetic issue.

- [x] ~~Derived stats not displaying~~ - FIXED (wrong key)
- [x] ~~Combat turn order issues~~ - FIXED (Timer-based delays instead of async/await)
- [x] ~~Turn order occasionally out of sync (rare)~~ — FIXED
- [x] ~~**Raising attributes doesn't increase current HP/MP/Stamina**~~ — FIXED (current rises with max)
- [x] ~~**Same consumable items don't stack in item menu**~~ — FIXED (quantity badge on inventory slots)
- [x] ~~**Victory screen waits for End Turn**~~ — FIXED (immediate check after damage/death)
- [x] ~~**Skill/spell levels displayed as floats**~~ — FIXED (wrapped str() with int())

---

## Session Notes

### 2026-03-15: Session 10 — Companions, Summon AI, TODO Audit
- **Companions backend confirmed complete**: CompanionSystem, 23 companions in companions.json, Companions tab in shop_ui, hell_tavern shop, party-size XP multiplier all already done
- **Party tab fixed**: derived stats bug (`derived_stats` → `derived` key), added View Stats + Remove buttons per card, `_on_remove_companion_pressed()` with safe view-reset
- **Summon AI**: player-summoned units now act on AI (summoner_id != 0 triggers ai_timer); companions remain player-controlled; two-line change in combat_arena.gd
- **Mantra system confirmed done** (was done in session 9 by Olaf): all 26 mantras, DY bursts, concentration breaks, Continuous Recitation, AI awareness
- **TODO audit**: races and backgrounds for all 6 realms confirmed done; 62 hell events confirmed (target met); Category 2 traders all done; Party management screen marked done; stale items corrected throughout

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
### 2026-03-08 Session 2: Bug Fixes + Scrolls/Events/Trainer Caps + Status Persistence

**Scrolls & shops:**
- 17 new scrolls added to demon_sorcerer, wandering_sage, general_store, hell_town_magic, hell_yogini_circle, mercy_ward
- Trainer caps (max_skill_level) added to 5 shops; ShopSystem enforces + UI shows "Capped"

**Hell events — trader branches:**
- Steal/attack/donate/comedy choices added to all 8 hell trader events
- Skill-based dice rolls (e.g. `skill: comedy`) now supported in event_manager alongside attribute rolls
- Karma assignments: steal→hungry_ghost, attack→hell, donate→god, comedy→human

**Bug fixes:**
- Crafting button label was "C" — corrected to "R"
- Starter equipment was landing on weapon set II — fixed by direct dict writes (no signal race)
- Weapon set swap in combat: 1 action, swaps weapons only (armor unchanged); SwapWeaponButton added
- Observe Carefully perk: "examine" effect type now handled in use_active_skill(); free_action flag now honored
- combat_arena crash (wrong function names _add_combat_log/_update_unit_info) — fixed
- Equipment tab showing empty on first open — fixed by awaiting _setup_equipment_doll()
- Weapon set selector out of sync on equipment tab open — fixed

**Status persistence (combat → overworld):**
- combat_manager: _sync_combat_state_to_characters() writes HP/mana + DoT statuses to character_data on end_combat
- overworld: _tick_overworld_statuses() applies DoT damage per step with toast notifications
- map_manager: cleanse reward now clears overworld_statuses (was a pass placeholder)
- DoT statuses that persist: Poisoned, Bleeding, Burning, Festering, Diseased

**Spell infrastructure on overworld:**
- "spell" reward type in map_manager teaches party a random spell of given school+tier
- Spell shrine pickups (guaranteed_simples config) placed by map_generator
- Spell guilds (guaranteed_guilds config) placed by map_generator
- pick_random_spell_for_party() in character_system picks spells new to at least one member
- guild_spell_lists persisted in save data for stable curricula

### 2026-03-08: Bug Fixes + Passive Perk Wiring (35+ perks)

**Bug fixes** (from previous session):
- Starting equipment now equips correctly on new game (save_manager.gd missing resets)
- Buff/mana/heal toasts now show ints not floats (overworld.gd)
- Shop spell tooltips calculate damage/heal using player's spellpower (shop_ui.gd)
- Spell guild "Buy" button fixed — was showing character name; now teaches all party members at once for one gold cost (shop_ui.gd)
- HP/Mana/Stamina now persist correctly after combat — `take_damage()`, `heal()`, and mana deduction now sync back to `character_data.derived` (combat_unit.gd, combat_manager.gd)

**Passive perk wiring architecture** established in combat_manager.gd:
- `get_passive_perk_stat_bonus(unit, stat)` — always-on bonuses (called by CombatUnit getters)
- `_process_on_hit_perks` / `_process_on_dodge_perks` — attack proc triggers
- `_process_turn_start_perks` — per-turn effects + flag/counter resets
- `_process_spell_cast_perks` — post-spell proc triggers (new this session)
- `_check_perk_status_immunity` — status block checks (new this session)
- `calculate_hit_chance` / `calculate_physical_damage` — target-context bonuses

**Perks wired** (50+ total, see perk wiring item in Testing section for full list):
- Martial Arts: flowing_footwork, open_the_gate, borrowed_force, empty_center
- Swords: centered_stance; Unarmed: hard_knuckles, short_range_violence, close_and_personal, rattle_the_cage, see_stars, no_time_to_breathe, keep_hitting, bare_chest, iron_shirt_technique
- Axes: commitment, momentum, heavy_swing, wide_arc; Spears: water_finds_the_gap, tidal_patience, disciplined_formation
- Black: touch_of_gloom, chains_of_suffering, amplified_misfortune, blood_pact; White: measured_radiance; Space: mental_aftershock; Water: creeping_cold
- Cross-skill: curseblade, elementalist, laughing_at_the_abyss
- CombatUnit state flags: moved_this_turn, momentum_stacks, unarmed_hit_stacks, stationary_stacks

### 2026-03-06: Reagents, Alchemy Crafting Tiers, Resource-Gathering Perks
- **Reagents (4th supply type)**: Added to supplies.json, game_state.gd, items.json. Starting amount 10, shop price 8g (scarcer than herbs/scrap). Toggle for alchemy passive brewing.
- **Alchemy crafting tiers** (perk-unlocked, 3 branches × 3 tiers):
  - Remedies: Apprentice Apothecary (Alch 1, 1 reagent) → Journeyman (5, 2) → Master (9, 4)
  - Munitions: Bomb Maker (1, 1) → Demolitions Expert (5, 2) → Master Demolitionist (9, 4)
  - Applications: Applied Toxicology (3, 1) → Advanced Coatings (5, 2) → Master Coatings (9, 4)
- **Passive brewing**: process_alchemy_step() — 15% + 3%/level per overworld step, toggleable
- **Resource-gathering perks**: Alchemical Recycling (Alchemy 3), Herbalist (Medicine 3), Scavenger (Smithing 3) — each feeds its own supply chain from combat
- **Loot integration**: Reagent drops 25% base / 50% from casters. Raw Reagents + Alchemist's Pouch items. Available in magic shops only.
- **Supply system polish**: Renamed Crafting → Smithing across skills/perks. Ammo on all ranged weapons. Steeper Logistics scaling. Supply loot drops in combat_manager.

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

### 2026-03-14 (Session 9): Codebase Audit + Summoning School Implementation

**Systematic audit of all systems.** Hell realm is largely production-quality. No critical bugs found.

**Confirmed working (no action needed):**
- All 13 autoloads — every called function verified to exist
- All 11 scenes — no missing scene references
- All 80 signals — no orphaned or unconnected critical signals
- All 137 status effects handled in combat
- All 43 active skill effect types handled (30 functional, 13 intentionally deferred)
- Item, shop, event, companion recruitment flows all wired correctly
- Town naming already done (commit bff12ac) — removed from known issues

**Open issues found (added to Known Issues section above):**
- `combat_grid.gd:458` — TODO "Check team" comment, possible edge case
- `karma_system.gd:154,179` — per-realm karma defaults hardcoded, not data-driven
- Enemy weapon placeholder names in `enemy_system.gd`

**Deferred perk list confirmed complete** — all 13 deferred perks are correctly stubbed with error messages; full list in perk wiring section above.

**Summoning school implemented:** All 75 summon types now functional.
- `resources/data/summon_templates.json` — stat blocks for all 75 summons, tiered by spell level 1/3/5/7/9
- `combat_manager.gd`: `_load_summon_templates()`, `_spawn_summoned_unit()`, "ground" targeting in `cast_spell()` and `get_spell_targets()`
- AI handles "ground" targeting: picks tile closest to front line
- Stats scale: `0.5 + summoning_skill/10` × base + spellpower → flat HP/damage bonus
- Tooltip shows "Summons: [Name]" and "Ground (summon at target tile)" target type

**Next session:** Playtest pass to find runtime bugs in Hell realm. Then companion auto-dev refactor (primary_attrs in skills.json).

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
