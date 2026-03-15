# Six Worlds - TODO

Last Updated: 2026-03-14 (session 9)
---

## Completed Systems

### Core Infrastructure
- [x] GameState singleton (world tracking, boss defeats, party gold, run state)
- [x] CharacterSystem singleton (7 attributes, 35 skills, derived stats, party management)
- [x] KarmaSystem singleton (hidden karma, reincarnation, weighted race selection)
- [x] EventManager singleton (3 choice types, party-wide checks, dice rolls)
- [x] ItemSystem singleton (equipment database, 12-slot system, inventory, procedural generation)
- [x] ShopSystem singleton (buy/sell, spell learning, skill training, discounts)
- [x] CombatManager singleton (full tactical combat system, loot drops with supply/reagent integration)
- [x] PerkSystem singleton (skill perks, cross perks, base bonuses, affinity bonuses)
- [x] EnemySystem singleton (enemy archetypes, role-based stats, inventory generation)
- [x] SaveManager singleton (save/load game state, 3 slots + autosave)
- [x] MapManager singleton (overworld map, pathfinding, mobs, objects)
- [x] AudioManager singleton (SFX system, 28 sounds × 6 variants)
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
- [x] Enemy loot drops (supplies, reagents with caster-weighting)
- [x] AoE spells damage obstacles and create ground effects
- [x] Ammo system (ranged weapons consume ammo, crossbow/javelin subtypes)

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
- [x] supplies.json (4 supply types with passive effects, consumption, starvation)
- [x] equipment_tables.json (procedural weapon/armor generation tables)
- [x] talisman_tables.json (procedural talisman generation tables)

---

## High Priority (Core Gameplay)

### Companions — Post-JSON Cleanup
- [x] ~~Verify skill keys~~ — all 35 skill IDs in companions.json match skills.json exactly
- [x] ~~Check background values~~ — 9 companions had invalid backgrounds (soldier/laborer/peasant/criminal); fixed: soldier→former_soldier, laborer/peasant→farmer, criminal→raider or executioner
- [x] ~~Verify item IDs~~ — all starting_equipment and fixed_items match items.json
- [x] ~~Wire companions into shops~~ — all 23 companions already in available_companions for all 9 hell shop locations

### Companion Auto-Development Refactor
- [ ] Add `"primary_attrs": [...]` to each skill entry in skills.json (35 skills × 2-3 attributes)
- [ ] Replace per-skill/attribute weights in companions.json with `"attr_ratio": 0.3` (fraction of auto-XP going to attributes)
- [ ] Update `companion_system.gd` auto-distribute logic: derive attribute targets from active skill weights × primary_attrs, invest proportionally

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
- [ ] Multi-function locations (towns, camps) use tab UI in event window — 3-4 functions per location
- [ ] First-visit event hook for towns (simple choice: rumors, discount, hidden object)
- [x] ~~Steal/attack/donate karma branches on trader interactions~~ — DONE (all 8 hell trader events: steal roll on all, attack on 3, donate on 2, comedy wildcard on 5 with success/failure outcomes). Skill-based dice rolls now supported in event_manager (skill: comedy/performance instead of attribute)
- [x] ~~Trainer caps~~ — DONE (max_skill_level in shop training dict; ShopSystem enforces cap, UI shows "Capped" in yellow)
- [x] ~~Hell-specific named locations~~ — DONE (Infernal Forge, Bone Archer Camp, Mercy Ward, Brimstone Lab, Warden's Pit — all in shops.json + hell_events.json + hell.json map pools)

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
- [ ] Remaining Category 2 traders for hell: Infernal Forge (blacksmith), Bone Archer Camp (fletcher), Mercy Ward (healer), Brimstone Lab (alchemist), Warden's Pit (trainer) — general shops and magic/trainer shops already exist (frozen_merchant, ember_merchant, wandering_peddler, demon_sorcerer, wandering_sage, weapon_master)
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
- [ ] **Perk wiring (in progress)**: ~441 passive perks in perks.json; active skills (combat_data key) already work. Passive wiring is done in `get_passive_perk_stat_bonus()`, `_process_on_hit_perks()`, `_process_on_dodge_perks()`, `_process_turn_start_perks()`, `_process_spell_cast_perks()`, `_check_perk_status_immunity()`.

  **WIRED so far** (combat_manager.gd): `parry`, `improved_parry`, `stone_adept`, `all_in`, `weapon_master`, `wind_adept`, `flame_fist`, `thunder_breaker`, `blood_in_the_wind`, `riposte` + all talisman perks. Session 2: `centered_stance`, `flowing_footwork`, `open_the_gate`, `borrowed_force`, `empty_center`, `diamond_body`, `touch_of_gloom`, `measured_radiance`, `mental_aftershock`, `chains_of_suffering`, `elementalist`, `curseblade`, `blood_pact`. Session 3: `iron_shirt_technique`, `short_range_violence`, `commitment`, `momentum`, `keep_hitting`, `every_opening_is_an_invitation`, `close_and_personal`, `hard_knuckles`, `rattle_the_cage`, `see_stars`, `no_time_to_breathe`, `heavy_swing`, `wide_arc`, `laughing_at_the_abyss`, `bare_chest`. Session 4: `tidal_patience`, `disciplined_formation`, `water_finds_the_gap`, `creeping_cold`, `amplified_misfortune`. Session 5: `risen_dead` (talisman perk). Session 6: **Daggers**: `offhand_jab`, `backstab`, `between_the_ribs`, `knife_storm`, `opportunist`, `too_fast_to_count`. **Ranged**: `steady_aim`, `clean_line`, `exposed_target`, `one_breath_one_arrow`, `wall_of_points`. **Spears**: `flowing_tide`. **Maces**: `concussive_force`, `shieldbreaker`, `thunderous_impact`, `relentless_advance`, `skull_crack`, `juggernaut`. **Might**: `grounded`, `pain_is_just_information`, `put_your_weight_into_it`, `hit_back_harder`, `nothing_wasted`. **Guile**: `play_dirty`, `cheap_shot`. **Leadership**: `no_one_left_behind`, `press_the_advantage`, `unbroken_circle`. **Performance**: `rousing_display`. **Sorcery**: `clean_cast`, `efficient_enchanting`, `sudden_silence`, `snap_decision`, `no_follow_up_needed`, `no_warning`, `spell_like_a_knife`. **Water/White**: `healing_waters`, `lingering_warmth`, `tidal_surge`, `purifying_stream`, `gentle_removal`, `riptide`, `mystic_healer`, `permafrost`. **Fire**: `kindled`, `hungry_flames`, `feed_the_fire`, `nothing_burns_alone`. **Earth**: `crystalline_edge`, `weight_of_the_mountain`. **Air**: `static_edge`, `chain_spark`, `scattering_gust`, `avatar_of_the_wind`, `avatar_of_the_storm`. **Enchantment**: `weakening_gaze`, `lingering_touch`. **Black**: `fear_is_the_mindkiller`. **Summoning**: `summoners_bond`. **Earth**: `tremor`. **Water**: `deep_freeze`, `crushing_depths`, `riptide`, `purifying_stream`. **Fire**: `nothing_burns_alone`, `ashes_remember_heat`. All talisman combat perks COMPLETE. `karma_sight` = event-system only.
  **Session 7**: `call_the_shot` (Leadership active: mark_target effect, `marked_target` field, once_per_turn enforcement).

  **Session 8**: Complete `stat_modifiers` infrastructure (array on CombatUnit, `_get_stat_modifier_bonus()`, wired into all stat getters, duration ticked at turn start). Overcast system wired into `cast_spell()`. `will_miss_next_attack` flag wired into `attack_unit()`. `taunt_active` wired into AI targeting. 20 new active skill effect type resolvers: `bonus_movement`, `restore_stamina`, `restore_armor`, `revive`, `debuff_enemies`, `buff_allies`, `buff_ally`, `destroy_obstacle`, `cleanse_and_buff`, `grant_extra_action`, `force_miss`, `grapple`, `overcast`, `retreat`, `aoe_damage_and_status`, `buff_allies_debuff_enemies`, `dispel_and_invert`, `aggro_aura`, `share_buffs`, `double_buffs`. statuses.json: added Grappled, Force_Miss, Taunt, Demoralized.

  **CombatUnit per-turn counters**: `moved_this_turn`, `momentum_stacks`, `unarmed_hit_stacks`, `stationary_stacks`, `dagger_attacks_this_turn`, `ranged_attacks_this_turn`, `knife_storm_proc_this_turn`, `enemies_hit_this_combat`, `hit_back_ready`, `sorcery_kill_bonus_ready`, `marked_target`, `call_the_shot_used_this_turn`.
  **CombatUnit active-skill fields**: `stat_modifiers` (timed stat buffs), `pending_overcast_bonus`, `will_miss_next_attack`, `taunt_active`, `taunt_duration`.

  **STILL UNWIRED** (grouped by complexity):

  *Simple / remaining (last few):*
  - ~~`call_the_shot`~~: DONE — `mark_target` effect type; `marked_target` on attacker + `is_marked` on defender; +15% acc/dmg for first ally hit; clears on hit or defender's turn start.
  - ~~`tremor`~~: DONE — Earth AoE spells 25% Knockdown.
  - ~~`crushing_depths`~~: DONE — +15% accuracy vs enemies on water/ice terrain or 2+ water debuffs.
  - ~~`avatar_of_the_storm`~~: DONE — aura: all allies' attacks +5% Air, 10% stun.
  - ~~`ashes_remember_heat`~~: DONE — kill burning enemy → fire terrain at their tile.
  - ~~`deep_freeze`~~: DONE — movement 0 → Frozen at turn start if enemy has perk.

  *Complex / needs new systems (defer):*

  ~~**Kill-triggered free attacks**~~: DONE — `_trigger_free_attack()` + `in_free_attack` guard on CombatUnit; `_trigger_cleave()` called from `_kill_unit()`; `relentless` hooked in `_process_on_hit_perks()`. `necromancer`: 10 mana cost, `necromancer_raises` counter (max 2), spawn via risen_dead template.

  ~~**Zone of Control / Reaction system**~~: DONE — `_check_zoc_reactions(mover, old_pos, new_pos)` called from `move_unit()`. `attack_unit()` gains `reaction: bool = false` param (skips `can_act()` + `use_action()`). `first_to_strike`: spear reaction on enter. `frost_warden`: Slow + +1 reach while stationary. `none_shall_pass`: also fires on same trigger. `sentinel`: fires when enemy LEAVES melee range.

  ~~**Stealth system**~~: DONE — `is_stealthed: bool` on CombatUnit. `shadow_strike`: kill → enter stealth; stealth attack = auto-hit + forced crit. `soft_step`: movement within 3 tiles of enemy doesn't break stealth. `sudden_end`: stealth + stunned/dazed = +50% damage. `ambush_predator`: kill from stealth resets stealth. Stealth breaks on attack (always) or moving within 3 tiles without soft_step.

  **Metamagic** (pre-cast UI dialog; combat_data key selects which spell to modify before casting):
  - `metamagic` (Sorcery 3 + Ritual 3) — modify next spell: extend range, add AoE, or change element. Needs a modal dialog before the spell panel confirms targeting.

  **Mantra system** — DONE:
  - Core: `mantra_stat_bonuses`, `deity_yoga_triggered` on CombatUnit; `_process_mantra_effects()` + `_apply_mantra_tick()` + `_trigger_deity_yoga()` in combat_manager.
  - All 26 mantras wired with per-turn effects and Deity Yoga bursts. Stat bonuses flow through new `mantra_stat_bonuses` dict checked in `get_armor/dodge/movement/initiative/crit_chance/spellpower/accuracy/resistance`.
  - `one_mind_one_fist`: unarmed hits during mantras advance each mantra +1. `walking_meditation`: +2 Move while any mantra active. `dharma_warrior`: kills during mantras advance each mantra +1.
  - **Deferred DY effects** (simplified for now): damage reflection → stat burst; unit spawning (Roaring One, Lord of Death, Guardian Kings, Pagoda) → log message + stat burst.

  **Other deferred:**
  - `void_touched` — space spells leave void terrain tiles. Needs void tile type added to combat_grid.
  - ~~`skirmisher`~~: DONE — ZoC reactions suppressed for mover with this perk (free disengage). The "no accuracy penalty after moving" half defers until ranged move-penalty system is added.
  - `roles_assigned` / `tactical_synergy` — need role designation UI (assign Vanguard/Striker/Support/Control at combat start). Complex — defer.
  - `metamagic` — needs pre-cast UI dialog to modify next spell (range/AoE/element). Complex — defer.
  - `create_terrain` (inscribed_circle, fog_of_war, black_ice, raise_wall, gravity_well, improvised_barricade, prepared_ground) — needs timed terrain tile system. Complex — defer.
  - `create_images` (smoke_and_mirrors) — needs illusion/decoy unit system. Defer.
  - `imbued_attack` (arcane_archer) — ranged attack with spell element. Defer.
  - `mass_teleport` (everyone_is_somewhere_else_now) — teleport all units. Defer.
  - `recruit_or_pacify` (magnetism) — convert/pacify enemy. Defer.
  - `place_trap` (trap_maker) — persistent terrain trap. Defer.
  - `consume_charm` (attune_charm) — consume equipped talisman for next-spell bonus. Defer.
  - `steal_item` (the_invisible_hand) — steal equipped item from enemy. Defer.
  - `choose_one` (improvised_masterpiece) — needs sub-choice UI. Defer.
  - `guard_ally` (stalwart_guardian) — redirect attacks to self. Defer.
  - `summon_aura` (host_of_the_winds) — per-turn aura buff nearby allies. Defer.

  *Deferred (already handled):* all per-skill minor bonuses flow through PerkSystem base_bonuses → derived stats, not combat_manager

---

## Medium Priority (Content & Polish)

### Content
- [ ] More consumable items (realm-specific potions, higher-level scrolls, more charm/bomb/oil tiers)
- [ ] More equipment (rare/legendary weapons and armor)
- [ ] More upgrades/perks
- [x] ~~Alchemy crafting system~~: Reagents supply type, 3 crafting branches (Remedies/Munitions/Applications) × 3 tiers, perk-unlocked, passive brewing toggle — DONE
- [x] ~~Resource-gathering perks~~: Alchemical Recycling (Alchemy 3), Herbalist (Medicine 3), Scavenger (Smithing 3) — DONE
- [x] ~~Crafting UI tab~~ — DONE (key: R; character picker, Potions/Bombs/Oils filter, craftable/locked recipe list with reagent cost)
- [x] ~~More scroll varieties~~: 17 scrolls added (common: magic_missile, voidbolt, shocking_grasp, stone_spike, bless, cure, slow; uncommon: fireball, blizzard, chain_lightning, earthquake, haste, stone_skin, regeneration, blink, dispel, confusion). Distributed to demon_sorcerer, wandering_sage, general_store, hell_town_magic, hell_yogini_circle, mercy_ward
- [ ] **Cursed items**: equipment that applies a passive debuff alongside its stats. Player may not know an item is cursed until equipped (reveal on ID or Alchemy skill check). Separate from cursed terrain/simples.
- [x] ~~**Equipment generation system**~~: procedural weapons, armor, and talismans — DONE
- [x] ~~**Talisman system**~~: persistent equippable trinket-slot items with stat/skill/perk bonuses — DONE
- [x] ~~**Equipment traits**~~: weapon/armor modifier system (sharp, reinforced, etc.) — DONE
- [x] ~~Wire up `random_generate` template items to use the new procedural generation~~ — DONE
- [x] ~~Integrate talisman perk effects into combat (poison_immune, regen, thorns, etc.)~~ — DONE (all combat perks wired; karma_sight is event-system only)
- [x] ~~Add talisman/equipment generation to shop and loot systems~~ — DONE (procedural items in loot drops + auto-generated shop stock)

### UI Improvements
- [ ] Tooltip system expansion
- [ ] Upgrade selection popup (choose 1 of 4)
- [ ] Party management screen

### Combat Improvements
- [x] ~~Active skills fully functional (stamina costs, targeting, effects)~~ — DONE (25+ skills with combat_data, stamina/cooldown system)
- [x] ~~AI using consumable items (enemy potion/scroll usage)~~ — DONE (AI health/mana potions, bombs, oils)
- [x] ~~AI using active skills~~ — DONE (scoring system, prioritized decision tree)
- [x] ~~Enemy-specific physical resistances~~ — DONE (hell_archetypes.json: frozen_revenant +pierce/slash, -crush; lava_golem/mountain_guardian +slash/pierce; frost_guardian +pierce/slash; demons +pierce/slash)
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

- [x] ~~**Town naming**~~ — DONE (procedural Tibetan/Sanskrit name pool, commit bff12ac)
- [ ] **Item flavor text (needs runtime)**: `space_charm_common` and `rations` reportedly show broken flavor text in item tooltip — static code looks correct; needs in-game testing to reproduce
- [ ] **combat_grid.gd:458** — TODO comment "Check team" — possible edge case in team check logic; needs review
- [ ] **Karma realm origins not loaded from data**: `karma_system.gd:154,179` — per-realm karma starting values are hardcoded, not loaded from background data. Low priority until other realms exist.
- [ ] **Enemy weapon placeholder names**: `enemy_system.gd:306,314` — auto-generated weapons get generic names. Minor cosmetic issue.

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
