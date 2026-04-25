# Six Worlds - TODO

Last Updated: 2026-04-07

---

## Psychology System (Layer 1)

Full spec: `docs/superpowers/specs/2026-04-07-psychology-system-design.md`
Full plan: `docs/superpowers/plans/2026-04-07-psychology-system.md`

Five elemental pressure meters per character (−100 klesha ↔ +100 wisdom). Pressure from events and combat → status effects at ±33/±50 → autonomous events at ±75.

- [ ] **Task 1** — Create `scripts/autoload/psychology_system.gd` skeleton; register after KarmaSystem in `project.godot`
- [ ] **Task 2** — Add `emotional_pressure` + `emotional_baseline` to BASE_CHARACTER in `character_system.gd`; add `emotional_baseline` field to all races in `races.json`; wire baseline copy in `_apply_race_modifiers()`
- [ ] **Task 3** — Implement core pressure logic: `apply_pressure()`, `_intensity_multiplier()`, `get_active_statuses()`, `get_emotional_label()` (all named states for all 5 elements × 2 poles × 3 tiers)
- [ ] **Task 4** — Implement `_check_thresholds()`: fires `autonomous_event_triggered` signal once per crossing, partial valve (+20 back toward neutral), resets on recovery. Connect signal to `_on_autonomous_event()` for inter-party fallout pressure
- [ ] **Task 5** — Implement `decay_toward_baseline()` for rest system integration
- [ ] **Task 6** — Wire event outcomes: add `pressure` field handler in `event_manager.gd apply_outcome()`; add `pressure` fields to 3 example hell events
- [ ] **Task 7** — Wire combat hooks in `combat_manager.gd`: unit death → Water −15 to witnesses; victory → Fire/Air +10; defeat → Earth −10/Space −5
- [ ] **Task 8** — Show dominant emotional label in character sheet UI (`main_menu.gd`)
- [ ] **Task 9** — Wire Leadership + Comedy perks to `apply_pressure()` calls

**Future layers (not yet started):**
- [x] ~~**Layer 2: Personality traits & quirks**~~ — QuirkSystem autoload + quirks.json (40 quirks: 10 physical, 14 personality, 10 behavioral, 10 acquired). Stat modifiers flow into `update_derived_stats()`; skill modifiers written to `skill_bonuses["quirks"]` source; pressure offsets shift `emotional_baseline`; event_tags unlock blue choices in event_manager. UI panel in character sheet (coloured by category, mechanical summary, purge tooltip). Bugs fixed: attribute event checks now include quirk bonuses; effective skill level clamped to 0 floor; purge check uses effective not raw skill.

### Quirk System — Remaining Work
- [ ] **Autonomous actions** — `event_tags` exist on quirks but nothing consumes them at runtime. When `autonomous_event_triggered` fires (pressure crisis), look up the character's quirks, find any with matching `event_tags`, and trigger a narrative micro-event (log message, forced choice, or stat consequence). E.g. `hot_tempered` at Fire crisis → attacks nearest ally; `timid` at Air crisis → flees from combat position. Needs a small dispatch table in event_manager or a new `_resolve_quirk_autonomous()` in psychology_system.
- [ ] **Player character starting quirks** — no mechanism to assign quirks to the player character at run start. Options: (a) random 1–2 inborn quirks from the physical/personality pools at character creation, (b) background unlocks specific quirks, (c) player picks from a short list. Pick approach and implement.
- [ ] **Companion quirk data** — add `"quirks": [...]` arrays to actual companion definitions in the companion data file; currently the system supports it but no companion has any quirks assigned.
- Layer 3: Intervention mechanic (social skills let one character help another)
- Yidam integration: mantra practice raises brightness baseline per element
- Rest system: `decay_toward_baseline()` called on camp/inn rest
- Chronic darkness counter: accumulates debuffs for time spent below −50
- Character sheet psychology tab: elemental tendency bars + active statuses + traits

---

## Indo-Tibetan Weapons & Armor Overhaul

### Design Summary
- Material tiers (bone, bronze, iron, obsidian, steel…) stay as-is — they are progression tiers
- Skill IDs in code stay as-is (swords, maces, etc.) — only display names and item data change
- Armor progression: Chuba → Chainmail → Lamellar → (future cuirass/heavy)
- Magic foci (phurba, kila, khatvanga, kangling, ritual garb, masks) are deferred to a dedicated session

### Step 1 — Tooltip format ✓ DONE
- [x] weapon_class field added to all new/renamed weapons; item_tooltip.gd updated to display it
- [x] skill_bonuses now displayed in tooltip (light blue, e.g. "+1 Yoga skill")

### Step 2 — Sword type system ✓ DONE
- [x] 4 types: Khanda (balanced), Talwar (fast), Dao (chopper, armor_pierce), Patisa (2H)
- [x] Full material matrix: bone (Khanda only), bronze/iron/steel (all 4), obsidian (Dao only), damascene/sky_iron/vajra (all 4)
- [x] Update loot tables and shop item pools — new sword types (Talwar, Dao, Patisa, Khanda) added to all weapon shops and map config loot tiers
- [x] **`good_iron_weapon` investigated** — `resolve_random_generate()` + `generate_weapon_for_party()` are fully wired in item_system.gd and shop_system.gd; fixed template resolution bugs in map_manager.gd (`item`, `item_random`, `item_random_scaled`), event_manager.gd (event item rewards), and companion_system.gd (fixed_items)

### Step 3 — Mace renames ✓ DONE
- [x] iron_mace → Iron Gada, bone_club → Bone Gada, bronze_mace → Bronze Gada

### Step 4 — Bow renames + Composite Bow ✓ DONE
- [x] hunting_bow → Dhanush; Composite Bow added (dmg 9, acc 8, range 5)

### Step 5 — New melee weapons ✓ DONE
- [x] Katar (iron/steel) — push dagger, +crit_chance
- [x] Bichawa (iron/steel) — parrying dagger, parry_effectiveness 75 (needs code wiring)
- [x] Kukri (bronze/iron/steel) — curved blade, high dmg/low acc
- [x] Trishula (iron/steel) — trident, on_crit_status pinned (needs code wiring)
- [x] Urumi (steel) — flexible sword, sweep special_attack (needs code wiring)

### Step 6 — Chakram ✓ DONE
- [x] Iron/Steel Chakram — thrown, pass_through 1, retrievable (pass_through needs code wiring)

### Step 7 — Armor ✓ DONE
- [x] leather_vest → Chuba
- [x] Lamellar Armor added (armor 11, dodge -6, above chainmail)
- [x] Monk's Robe and Monk's Hood added (+1 Yoga each)
- NOTE for later: element-specific ritual garb and ritual masks — expand in magic foci session

### Step 8 — Ritual Implements (Magic Foci rework) ✓ DONE

#### System Design (final)
- **Material** = elemental affinity → school skill bonus (scales with consecration tier)
  - Copper → Fire magic | Silver → Water magic | Gold → Earth magic | Iron → Air magic
  - Bronze → Space magic (tiers 1–3) | Sky-iron → Space magic (tiers 4–5)
  - Conch → White magic | Bone → Black magic
- **Consecration tier** = quality tier (all base stats scale)
  - Plain (1) → Blessed (2) → Empowered (3) → Perfected (4) → Legendary (5)
- **Instrument type** = base functional profile (fixed school bonuses where appropriate)
  - Dorje: +spellpower only (White now purely from conch material)
  - Drilbu: +max_mana + Space skill bonus (instrument nature) + material bonus
  - Khatvanga: +spellpower + max_mana + initiative aura (Black now purely from bone material)
  - Damaru: +max_mana + Enchantment skill bonus + Rhythm Charge
  - Kangling: +spellpower + Summoning skill bonus + Chöd Offering
  - Phurba: +spellpower + Sorcery skill bonus + Throw Phurba
- **Set bonus**: Dorje + Drilbu of any material in both weapon slots → +3 Spellpower, +3 Mana, +2 Initiative
- 210 items total: 6 implements × 8 materials × 5 tiers (bronze tiers 1–3 / sky-iron tiers 4–5 for Space)
- Generator: `tools/generate_implements.py` → `tools/generated_implements.json`

#### What was wired earlier (still active)
- [x] Initiative aura on khatvanga — `get_passive_perk_stat_bonus(unit, "initiative")` equipment section
- [x] Rhythm Charge (Damaru) — `damaru_charges` on CombatUnit; discount fires in `cast_spell()`
- [x] Chöd Offering (Kangling) — `_resolve_chod_offering()` in combat_manager.gd
- [x] Throw Phurba — `_resolve_throw_phurba()`; Subjugated status in statuses.json
- [x] Set bonus — `calculate_equipment_stats()` detects `set_pair: "dorje_drilbu"`; tooltip shows gold line

#### Open / Deferred
- [ ] **Ritual implement traits** — special properties (e.g. conch pacification aura, bone life-drain proc, sky-iron void field) to be designed in a dedicated session
- [x] **Shop distribution** — Plain/Blessed implements added to 11 shops (hg_spell_shop, hg_charnel_sorcerer, hg_town_magic, hell_hidden_gompa, hell_yogini_circle, hell_circle_of_yoginis, hell_crossroads_stupa, hell_eternal_fire, hell_mirror_lake, hell_sacred_grove, hell_garuda_roost); added to zone-tier loot pools in hell + HG; 11 magic companions given school-appropriate plain implements.
- [ ] **Spell Accuracy / Spell Projectiles** — deferred, leaving to ferment (see Design Questions)

#### Other weapon mechanics wired this session
- [x] **Trishula on_crit_status** — `on_crit_status` field checked in `_process_weapon_on_hit_procs()` after crits
- [x] **Bichawa parry_effectiveness** — `parry_effectiveness` in off-hand stats → armor bonus in `get_passive_perk_stat_bonus(unit, "armor")`, equipment section
- [x] **Chakram pass_through** — traces attack line beyond defender in `_process_weapon_on_hit_procs()`; runs before `passive.is_empty()` guard
- [x] **Urumi sweep** — hits all other adjacent enemies at −15 acc for 75% dmg, in `attack_unit()` on-hit block

#### Ritual Garb

**Design (pending implementation session)**
- Slots: `chest` (robes) and `head` (masks)
- Same material×consecration system as implements: material = elemental school bonus, tier = power
- Robes: per-element (one line per element, 5 consecration tiers each)
- Masks: more specific, per-school (can be more exotic — see existing school list)
- Monastic cross-school garbs: Vajrayana Robe (White+Black+Summoning), Dzogchen Mantle (Space+Air+Yoga)
- [x] Design stat profiles per robe/mask type
- [x] Add items to items.json (follow generate_implements.py pattern — wrote generate_garb.py)
- [x] Wire school bonus display in item_tooltip.gd — skill_bonuses already shown, no changes needed

---

## High Priority

### Rest & Time System
Full spec: `docs/superpowers/specs/2026-04-08-rest-time-system-design.md`

Hours-based time clock (2 hrs/step, 24 hrs/day), three-tier rest mechanic (Quick/Camp/Full), food system rework (food only consumed at rest, not per step).

- [x] **Task 1** — Add `hours_elapsed`, `advance_time()`, `day_changed` signal, `current_day`/`hour_of_day` computed properties, `get_time_of_day_label()` to `game_state.gd`; wire save/load
- [x] **Task 2** — Add `MapManager.tick_mobs()` method (patrol step without player movement); add Space = Wait action in `overworld.gd` that calls it + advances time + ticks statuses
- [x] **Task 3** — Remove per-step food drain: gut `process_food_step()`, `process_herbs_step()`, starvation damage, per-step HP heal, `steps_without_food`; update `_tick_supply_step()` accordingly
- [x] **Task 4** — Implement `_do_rest(tier)` in `overworld.gd`: deduct resources (with Logistics discount), restore HP/mana/stamina (with Medicine continuous bonus + temp HP overflow), decay emotional pressure, restore durability (with Smithing scaling + scrap cost), advance time, emit toast
- [x] **Task 5** — Build rest UI: button in HUD, popup panel with 3 tier options showing costs + affordability, result toast; update supplies.json starting values
- [x] **Task 6** — Add time display to overworld HUD ("Day N — Evening"); update `_tick_supply_step` to call `advance_time` on each player move
- [x] **Task 7** — Wire temp HP: add `temp_hp` field to character derived stats; combat_manager absorbs temp HP before real HP on damage

**Follow-up (after core system lands):**
- [x] ~~**Lunar calendar system**~~ — 28-day lunar month (4×7, always week-aligned), full moon day 14 / new moon day 28 (both Saturday). Two-line HUD label ("Sunday, 1st lunar day / Deep Night"). Full moon: White magic +20% spellpower + mana partial restore + toast; new moon: Black magic +20% + toast. Both: karma weight ×1.5. Weekday school bonus system: Sun=Fire, Mon=Water, Tue=Sorcery, Wed=Space, Thu=Air, Fri=Enchantment, Sat=Earth — each gives +20% spellpower to that school. All wired into `game_state.gd`, `combat_manager.gd`, `karma_system.gd`, `overworld.gd`, `overworld.tscn`.
- [ ] Realm-specific rest events — "something stirs in the night" flavour event chance when resting in hell/hungry ghost
- [ ] Rest perks — wire `_process_rest_perks(character, tier)`: Safe Campsite (no encounter on rest), Lucid Rest (Yoga 7, extra pressure decay), Well-Rested (Medicine 8, temp HP on full rest), Field Surgeon (Medicine 6, revive bleed-out on full rest)
- [ ] Yoga skill boosts pressure decay rate during rest (Yoga level adds to decay_amount)
- [ ] Day/night visual changes on overworld map (lighting overlay, different mob behavior)
- [ ] Block rest when hostile mob is adjacent (optional tension mechanic)

---

### Camp System (Full Overhaul of Rest UI & Activities)

The current three-tier rest system handles resource costs and recovery correctly, and karma purification sadhana is implemented. This overhaul turns the Full Rest and Camp tiers into a proper two-stage decision: **pick rest tier → pick camp activities**.

#### Design decisions (settled)
- **Slots**: Quick Rest = 0 activity slots, Camp = 1, Full Rest = 2. Logistics perks can add +1 slot.
- **Party pool**: Activities draw from a shared pool. Any character can contribute one action per slot, but each character can only perform one activity per rest.
- **Disturbance**: Fires at the *start* of rest (before any activities). If combat is triggered, the party fights immediately. Win → rest continues but loses 1 slot and proportional recovery (e.g., 2-slot rest becomes 1-slot, recovery cut accordingly). Lose/flee → rest fails entirely.
  - Disturbance chance scales with: location type (wilderness > road > town outskirts > inn = 0), time of day (night higher), realm (hell/HG much higher), and is negated by Logistics perk "Safe Campsite".
- **Safe camps** (inns, teahouses, monasteries): no food cost, disturbance chance = 0, access to a `camp_actions` dict on the map tile object for location-specific activities and events. Some regular camp activities may be unavailable (no smithing in a teahouse); social ones may be enhanced (Performance in front of an audience = better effect).
- **Crafting skills are camp-only**: passive per-step alchemy production is commented out (not deleted) pending playtesting. No new resource types needed.

#### Camp activity list (to implement as camp skills)

*Spiritual:*
- **Sadhana** (Yoga 3+) — karma purification ✓ *implemented*
- **Mantra Recitation** (Yoga 2+) — small yidam/dharmapala relationship progress; low-skill entry point for the deity systems
- **Protector Offering** (Ritual 2+) — dharmapala offering at camp altar; deferred until DharmapalaSystem exists

*Medical / Alchemical:*
- **Herb Preparation** (Medicine 2+) — process raw herbs into more efficient healing forms; small passive HP restore bonus next rest
- **Field Surgery** (Medicine 4+) — cure bleeding, poison, infection, and camp-only wound/disease statuses (see Diseases & Wounds section); costs herbs
- **Brew Potions** (Alchemy 3+) — convert herbs + reagents into healing/buff potions; output count and quality scale with Alchemy level; replaces passive step-based brewing
- **Brew Poisons & Bombs** (Alchemy 4+) — combat consumables; costs reagents

*Craft / Maintenance:*
- **Deep Repair** (Smithing 2+) — full durability restore on all party equipment beyond the passive smithing scaling already in `_do_rest`
- **Weapon Work** (Smithing 4+) — temporary +accuracy or +damage on one weapon, lasts until next rest
- **Craft Item** (Crafting 3+) — make tools, rope, ammunition, basic equipment from scrap/materials
- **Craft Charm or Talisman** (Ritual 3+ + relevant magic school 3+) — create a consumable charm with a minor magical effect tied to the school used; costs reagents + herbs; values TBD in playtesting

*Social / Morale:*
- **Campfire Story** (Performance 3+ or Comedy 3+) — party-wide pressure reduction; Comedy variant tends toward Air/Fire pressure, Performance toward Water/Earth
- **Encouraging Words** (Leadership 3+) — small stat buff for party members for next combat, or reduce one character's pressure significantly
- **Night Music** (Performance 5+) — deeper morale effect; chance of drawing in a friendly passing-traveller event

*Intelligence / Scouting:*
- **Study Recent Events** (Learning 2+) — XP bonus for one character derived from recent encounters; scales with Learning level
- **Scout Surroundings** (Logistics 3+) — choose: reduce disturbance chance for next camp OR reveal nearby map tiles OR identify forage opportunities
- **Guile Work** (Guile 4+) — arrange a false trail, plant evidence, set a future trap; vague mechanical effect TBD, strong flavour

*Survival / Foraging:*
- **Forage** (Logistics 2+) — recover herbs and some food from terrain; yield varies by realm and biome
- **Set Snares** (Crafting 2+ or Thievery 2+) — passive food and small material gain overnight; small chance of triggering a creature encounter

*Combat Prep (limited presence by design):*
- **Sharpen Weapons** (any weapon skill 3+) — temporary +accuracy for that character's attacks next combat
- **Drill** (Leadership 5+) — party initiative bonus next fight
- **Spar** (any weapon skill 4+) — two characters, minor XP toward that weapon skill

#### Implementation tasks
- [x] **Task 1** — Redesign rest panel UI: tier selection → activity slot panel (1–2 buttons per slot, drawn from available skills in party). Sadhana appears here naturally as one activity option rather than a separate section.
- [x] **Task 2** — `CampSystem` autoload: `get_available_activities(party)` returns list of available camp skill dicts based on party skills; `execute_activity(activity_id, character)` runs the activity logic.
- [x] **Task 3** — Disturbance check at rest start: roll chance by realm/time; on trigger, rest tier drops by 1 and one activity slot is lost. Full combat trigger deferred (complex). Scout activity or safe camp negates disturbance.
- [x] **Task 4** — Passive alchemy step-production commented out in `overworld.gd` `_tick_supply_step()` with `# PLAYTEST: move to camp-only?` tag. `Brew Potions` and `Brew Bombs & Poisons` camp activities replace it.
- [x] **Task 5** — Herb Preparation (Medicine 2+) implemented. Field Surgery stubbed (disease system coming next).
- [x] **Task 6** — Brew Potions (Alchemy 3+) and Brew Bombs & Poisons (Alchemy 4+) implemented.
- [x] **Task 7** — Deep Repair (Smithing 2+) and Weapon Work (Smithing 4+) implemented. Craft Item / Craft Charm deferred (needs crafting system).
- [x] **Task 8** — Campfire Story (Performance/Comedy 3+) and Encouraging Words (Leadership 3+) implemented. Night Music deferred (needs camp event trigger from activities).
- [x] **Task 9** — Study (Learning 2+), Forage (Logistics 2+), Scout (Logistics 3+), Sharpen (weapon 3+), Spar (weapon 4+) implemented. Set Snares and Guile Work deferred (flavour-only, no system yet). Drill deferred (same as Encouraging Words but weaker).
- [x] **Task 10** — Safe camp integration: `"safe_camp": true` added to hell/HG teahouses, hidden gompas, and skygazing gompa events. `_check_is_safe_camp()` in overworld checks current tile's event for this flag. Safe camps: no food cost, disturbance chance 0.
- [x] **Task 11** — `"trigger": "camp"` events added to domain_events.json: `camp_night_vision` (any realm), `camp_wandering_spirit` (any realm), `camp_fire_omen` (hell). `EventManager.get_random_camp_event(realm)` added.

#### Camp System — Manual Review & Extension (post-implementation)

Needs a hands-on play session to balance, extend, and wire the remaining gaps:

**Activities to add:**
- [ ] **Night Music** (Performance 5+) — deeper morale; small chance of triggering a camp encounter (traveller, passing spirit). Needs camp event wiring from within an activity result.
- [ ] **Guile Work** (Guile 4+) — set a false trail or trap; mechanical effect TBD (reduce next mob patrol range? chance of ambush avoidance?). Strong flavour, light mechanics.
- [ ] **Set Snares** (Crafting 2+ or Thievery 2+) — overnight food/material gain; small creature encounter chance. Needs a "resolve on next move" deferred effect.
- [ ] **Drill** (Leadership 5+) — party initiative bonus next combat. Similar to Encouraging Words but combat-only; requires Leadership 5 vs 3, so a separate slot option.
- [ ] **Protector Offering** (Ritual 2+) — dharmapala offering at a camp shrine; deferred until DharmapalaSystem exists.
- [ ] **Craft Item** (Crafting 3+) — make basic tools/rope/ammo from scrap. Needs a simple crafting recipe table.
- [ ] **Craft Charm** (Ritual 3+ + magic school 3+) — consumable charm with school-specific effect. Needs schema for camp-crafted charms.
- [ ] **Mantra Recitation** (Yoga 2+) — currently a stub. Wire to a `mantra_count` field on the character and a threshold for future yidam relationship progress.

**Wiring gaps:**
- [ ] **Disturbance → camp event**: When `roll_disturbance()` returns true, call `EventManager.get_random_camp_event(realm)` and trigger it via the event display system. Currently disturbance only reduces rest effectiveness with a toast — no actual event fires. (Wiring requires post-rest event queue or mid-rest event hook.)
- [ ] **More camp events**: Write 3–5 camp events per realm (hell, hungry ghost, plus any/cross-realm). Currently only 3 total exist. Target: at least 2 per realm + 3 any-realm.
- [ ] **Location-specific activity suppression**: TODO design said some activities unavailable at teahouses (smithing) or enhanced at gompas (sadhana). Add `"suppress_activities": [...]` and `"enhance_activities": [...]` to safe camp event dicts and wire into `get_available_activities()`.
- [ ] **Sadhana cost preview**: Sadhana auto-picks the best ritual tier — but the player can't see which tier will fire or what it will cost before confirming. Add a preview line to the button text (e.g., "Torma Offering — Reagents: 2").

**Balance review (needs playtesting):**
- [ ] Forage yield (herbs + food) relative to rest costs — may be too generous or too low depending on realm.
- [ ] Brew Potions count (1–3) vs reagent cost (2) — compare to what 2 reagents buys in shops.
- [ ] Pressure decay total with Full Rest + Sadhana = 250 (100 base + 150 sadhana). May be excessive; consider whether sadhana should replace rather than stack with rest pressure decay.
- [ ] Activity slot count (Camp=1, Full=2) — whether Logistics perk for +1 slot should be implemented.

---

### Diseases & Major Wounds

Persistent negative status effects from combat or events that do not fully clear with normal rest — requiring camp-based Medicine to cure. Adds mechanical weight to attrition and makes Medicine more meaningful beyond passive HP bonuses.

#### Types (initial set, expand per realm)
- **Infected Wound** — slow HP drain each rest until cured; acquired from certain enemy attacks or untreated bleeds
- **Broken Bone** — Finesse penalty (movement, dodge, initiative); camp-only cure (splint + herbs); takes 2 full rests to heal even with Medicine
- **Fever** — Constitution penalty, increased food consumption, worsens with bad rests; cured by Medicine + herbs
- **Frostbite** — cold-hell specific; Finesse + Strength penalty; cured by warmth (camp fire) + Medicine
- **Corruption** — hell/hungry-ghost specific; psychological + stat penalty; resists normal medicine, needs Ritual or Yoga to treat

#### Design notes
- These statuses persist across rest tiers — Quick Rest does not remove them at all; Camp rest slows progression; Full Rest + Field Surgery cures them
- Medicine skill level determines cure success: some wounds require Medicine 3+, severe ones Medicine 5+
- Infection can worsen if untreated (escalation: infected wound → fever → worse)
- Events should be able to apply these (e.g., the lava event burning a character, the cold-hell freezing someone)
- UI: wound statuses appear in character sheet and in combat UI alongside normal status effects, visually distinct (persistent icon, no timer)
- Future: diseases specific to each realm (hungry ghost realm malnutrition disease, animal realm parasites, etc.)

#### Implementation tasks
- [x] Define wound/disease statuses — implemented as `WoundSystem.WOUND_TYPES` const in `scripts/autoload/wound_system.gd` (5 base types + 5 escalated forms). Stored as `wounds: Array` on character dicts. No `persistent: true` flag needed in statuses.json since the wound system is separate from combat status effects.
- [x] Wire escalation: `WoundSystem.tick_wounds(char)` called at each rest in `overworld._do_rest()` after camp activities execute (so Field Surgery cures first). Untreated wounds increment `rests_untreated`; crossing threshold escalates to next form.
- [x] Field Surgery camp activity implemented in `camp_system._exec_field_surgery()` — calls `WoundSystem.cure_wounds_field_surgery(performer, party)`. Medicine level gates which wound severity can be treated (cure_medicine_level per wound type). Stub removed.
- [x] Event outcomes can apply wounds: `"wound": {"id": "deep_cut", "target": "random"}` in any event outcome's `rewards` block, handled by `event_manager.apply_outcome()`.
- [x] Combat wiring: crit hits have 25% chance to apply a random wound to player characters; hits from undead/diseased enemies have 15% chance to apply a disease — both in `combat_manager._process_weapon_on_hit_procs()`.
- [x] Stat penalties wired in `character_system.update_derived_stats()` via `WoundSystem.get_stat_penalties()`.
- [ ] Character sheet and combat UI: show persistent wound icons distinctly (deferred — no character sheet UI yet)
- [ ] Temple/facility healing UI: call `WoundSystem.heal_at_facility(char, medicine_equivalent)` — stub ready, needs shop/temple scene
- [ ] Realm-specific wound types (hungry ghost malnutrition, animal realm parasites, hell frostbite/burns) — extend WOUND_TYPES when realms are built
- [ ] More wound/disease variety: currently 5 base types (3 wounds, 2 diseases). Target ~8–10 base types eventually; e.g. arrow wound (ranged-specific, different penalties from deep cut), poisoned wound (disease + damage hybrid), spiritual corruption (hell/hungry-ghost specific, resists medicine, needs Ritual/Yoga). See design notes in "Design Thinking: Wounds, Rest & Calendar" section.

---

### Projectile System (COMPLETE)
- [x] Ranged attack misses deviate 1-3 tiles based on how badly the roll failed
- [x] Deviated projectiles can hit any unit at landing tile (ally or enemy) — logs FRIENDLY FIRE
- [x] Bomb scatter: Alchemy 0 = 50% chance to land 1 tile off; Alchemy 3+ = no scatter
- [x] Hit% tooltip when hovering an attack target (green/yellow/red by chance)
- [x] Line2D projectile animation for ranged attacks and bombs (sprites deferred)
- [ ] Proper projectile sprites (arrows, bolts, firebombs) — currently line flash only
- [ ] Spell projectiles — see Magic Foci / Spell Accuracy section above

### Hell Content
- [ ] More hell events — both zones still under density target (~15+ events each)
- [ ] Hell event chains: soul caravan ambush, devil deserter, contraband deal, corrupted simple, chained pilgrim, rival party
- [ ] Hell quest content — write using `register_quest` + `set_flags`; wire `quest_board` outcome into town events
- [ ] Review all existing events (hell + HG) — audit choices per event and add missing blue/yellow options where only grey exists; aim for at least 2 meaningful skill/attribute checks per event

### Hungry Ghost Events — Follow-up (from hungry_ghost_events.json)
- [x] Add HG shop entries to shops.json: `hg_alchemist`, `hg_veterans_camp`, `hg_charnel_sorcerer`, `hg_black_market`, `hg_wandering_preta`, `hg_spell_shop` (plus existing `hg_bone_merchant`, `hg_teahouse`, `hg_mercenary_guild`, `hg_town_weapons`, `hg_town_magic`, `hg_town_supplies`)
- [x] Add spell reward tokens to item system: `spell_random_white`, `spell_random_black`, `spell_random` — resolved like `item_random` in `resolve_random_generate()`
- [x] OR skill requirements in event_manager.gd — `hg_veterans_camp` training choice needs swords 3 OR axes 3 OR maces 3
- [x] `skeleton_king_duel` encounter entry — boss fight that stops at 10% HP (needs special win condition logic in combat_manager.gd)

### Other Realms (Content Gaps)
- [x] Convert HG_EVENTS.md → hungry_ghost_events.json
- [ ] Map configs for remaining realms — only hell.json and hungry_ghost.json exist
- [ ] Enemy archetypes + encounters for animal, human, asura, god realms (hungry_ghost done: 20 archetypes, 37 encounters)
- [ ] Event files for remaining realms (animal, human, asura, god)
- [ ] Companion definitions for remaining realms (47 companions exist across hell + HG; animal, human, asura, god still empty)

### Companions
- [ ] Camp Followers system — UI stub exists in Party tab (`_update_followers_list()`); no backend
- [ ] Bespoke recruitment events for HG companions — organic recruitment outside shops; not every companion needs one, priority targets: Mehr (golden glint in the dark), Chöki (near still water), Nangwa (haunting a ruined library), Prashan (riddle challenge), Nyingje (found tending other undead), Khedrup (mid-recitation on an auspicious rock), Rasabhava (preservation lab, examine his notes), Durvasa (bound by reflected curse, Air magic / Ritual to stabilize), Gomchen (meditating amid binding contracts)
- [ ] More companions for the hungry ghost realm — current HG roster may be thin; design and add new companion definitions to companion data file

---

## Medium Priority

### Perks
- [x] Base bonus tables complete for all 35 skills, levels 1–15 (11–15 = item-bonus cap, same value as 10)
- [x] **Bug fixed**: parse_perks.py now expands `11–15` range rows into individual level keys — perk_system.gd's `str(level)` lookup was silently returning empty dict for levels 11–15
- [ ] PERKS.md: fill empty perk tiers (levels 2, 4, 6, 8) — 1-2 perks per skill at each
- [x] Perk rebalancing — 29 required_level changes across fire, air, space, sorcery, black, summoning, ritual, yoga, enchantment, earth, water magic. Worst offenders (fire L3:6→3, air L5:5→2, space L5:5→3, sorcery L5:5→3) fixed. Strong capstones (dabbler, burn_the_breath, forced_translation, cyclone_mastery) moved to L8. All perk-chain dependencies preserved.
- [ ] Add flavor text to perks that lack it

**Deferred perks (need new systems before wiring):**
- `metamagic` — needs pre-cast modal dialog to modify next spell
- `void_touched` — needs `void` tile type in combat_grid
- `roles_assigned` / `tactical_synergy` — needs role designation UI (Vanguard/Striker/Support/Control)
- create_terrain perks (`inscribed_circle`, `fog_of_war`, `black_ice`, `raise_wall`, `gravity_well`, `improvised_barricade`, `prepared_ground`) — needs timed terrain tile system
- `create_images` / `smoke_and_mirrors` — needs illusion/decoy unit system
- `imbued_attack` / `arcane_archer` — ranged attack with spell element; needs attack+spell hybrid
- `mass_teleport`, `recruit_or_pacify`, `place_trap` / `trap_maker`, `steal_item` / `the_invisible_hand`, `guard_ally` / `stalwart_guardian`, `choose_one` / `improvised_masterpiece`, `attune_charm`

**Deferred perks (need economy/social systems):**
- `investment` / `trade_empire` — needs overworld passive income system
- `supply_cache` / `extended_march` — needs overworld supply action system
- `guided_practice` / `the_lineage_continues` — needs companion spell-teaching mechanic
- `black_market_contacts` / `fence` — needs black-market merchant tier
- `patron_of_the_arts` — needs reputation/renown system
- `trap_sense` — needs persistent trap terrain object system

### Combat
- [ ] Tactical Assessment preset formations (Logistics 7 perk)

### Content
- [x] ~~Magic-school charms~~ — all 10 schools × 4 tiers (common/middling/rare/unique) complete with thematic descriptions; distributed across hell + HG shops, loot tables (tier-escalated by zone), and 24 magic-focused companion starting inventories
- [ ] More consumable items — realm-specific potions, oils, scrolls still thin
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
- [ ] Astrological spells for Space magic school — divination/prophecy flavor; celestial mechanics (eclipses, conjunctions as triggers or effects); motivates Sun Priestess companion's Space magic skills
- [ ] Paushtikakarma spells for Earth magic school — wealth multiplication, prosperity, dowsing for buried goods/ore; gives mechanical teeth to trade/merchant builds (Hustle Bones companion, Trade+Earth magic synergy)

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
- [x] ~~**Spell duration unification**~~ — unified formula: base 2 + floor(Enchantment/2) [main] + floor(spellpower/15) [secondary]. `clear_mind` fixed (`"spellpower_turns"` typo now `"spellpower"`). `doom` made explicit integer 3. `"combat"` → 999 turns. All 128 `"spellpower"` spells already used the formula.
- [ ] Terrain affecting spell power — no terrain-based spellpower modifiers in combat_manager.gd cast_spell()
- [ ] Environmental spell interactions — spells create terrain (done); terrain does not yet buff/debuff spells of matching element
- [ ] **Summoning bonus from overworld terrain** — Summoning spellpower gets +25% based on the overworld tile type where combat takes place (ruins/charnel grounds, forest, mountain, river/lake each evoke different resident spirits). Requires passing the overworld terrain type into the combat context at combat start. Tradition: nagas in water, earth spirits in mountains, hungry ghosts in charnel grounds, nature spirits in forest. Design the full terrain→spirit type→bonus table before implementing.
- [x] ~~**AoE type systematization**~~ — DONE. `AoEResolver` static class in `scripts/autoload/aoe_resolver.gd` is now the single source of truth for all AoE shapes: `circle`, `nova`, `around_caster`, `line`, `cone`, `cone_forward`, `cross`, `band`, `vertical_line`, `field_of_view`. All spells with an `"aoe"` block now get `targeting: "aoe"` and are resolved through `AoEResolver.get_tiles()` in combat_manager, combat_grid, and combat_arena. Canonical data schema uses `size`, `width`, `origin`, `safe_center`. To add a new shape: one function + two match branches in aoe_resolver.gd.
- [ ] Cone AoE targeting UI — `cone` and `cone_forward` shapes are now computed correctly by `AoEResolver`, but the preview highlight in combat_arena still shows the full range area during targeting (correct tiles shown on hover but not on range highlight). Also `cone_forward` direction should lock to caster's facing rather than requiring the player to aim. Needed by: `powdered_glass` (Glass domain).
- [ ] **Out-of-combat spellcasting** — not implemented. Several spells are designed for overworld/camp use (e.g. `cloud_gate`: retreat to last healing location; future utility spells). Needs a spellbook interface accessible from the overworld HUD or pause menu, mana deducted from caster, and spell effect resolved outside combat. `cloud_gate` specifically needs to teleport the party on the map to the last-visited healing-location tile.
- [x] ~~Realm-specific combat terrain themes~~ — DONE (overworld terrain generates realm-appropriate obstacles)

---

## Low Priority (Nice to Have)

### Save/Load Improvements
- [x] Multiple save slots (3 slots)
- [x] Auto-save functionality
- [ ] Meta-progression (affinities, persistent upgrades across runs) — not implemented; save_manager.gd handles per-run state only, no cross-run persistence

### Audio
- [ ] Background music per realm
- [ ] Combat music
- [ ] Air, Water, Earth spell impact sounds (only fire + generic exist)

---

## Testing

- [ ] Playtest hell realm end-to-end (combat, shops, events, quest board, portal transition)
- [ ] Balance pass on spell mana costs (15/40/75/135/225 by level)
- [ ] Test all 326 spells load and cast correctly
- [x] Item flavor text: `space_charm_common` and `rations` — tooltip code verified correct (charm effects shown at lines 139–158 item_tooltip.gd, supply info at 161–171). `space_charm_common` added to `hg_spell_shop`, `hg_charnel_sorcerer`, `hg_town_magic` so it is now reachable in-game.

---

## Design Thinking: Wounds, Rest & Calendar — Perks, Spells, Weapon Effects

These three new systems create a lot of design space. Notes to think through before the next implementation pass.

### Perks & Wounds

- **Wound resistance perks** — e.g. "Hardened" (Constitution 14+): 50% chance any crit wound is negated; "Undead Hunter" (Earth magic 3+): immune to diseases from undead attacks
- **Field Medic perk** (Medicine 6): Field Surgery now cures ALL wounds on the target, including escalated forms — no longer gated by medicine level per-wound
- **Stubborn Body perk** (Constitution 15+): wounds escalate 1 rest later (escalation_rests +1 global bonus); worth implementing as a `character.wound_escalation_delay` field checked in `tick_wounds`
- **Klesha / wound interaction**: each wound category could apply elemental pressure — physical wounds → Earth pressure, disease → Water pressure (rot/decay)

### Perks & Rest

- **Light Sleeper** (Awareness 12+): Quick Rest (tier 1) heals an additional 10% HP — reduces the penalty for being interrupted; currently Quick Rest only gives 40%
- **Meditator's Repose** (Yoga 4+): Full Rest always counts as "safe camp" for the disturbance roll — even in hostile territory the character's stillness fends off spirits; interesting Yoga payoff
- **Iron Constitution** (Constitution 14+): Medicine bonus to heal_pct doubles at Full Rest — character heals efficiently without a healer in the party
- **Logistics perk passives**: already half-designed — rest food cost reduced, forage yield increased; wire into `_do_rest` and `_exec_forage`

### Perks & Calendar

- **Lunar calendar perks**: certain perks could give bonuses on specific lunar days (e.g. "Full Moon Practitioner": +5 spellpower on day 15); needs a `PerkSystem.check_lunar_bonus(character)` hook called in `update_derived_stats`
- **Auspicious Days**: certain events or activities could be gated on auspicious calendar positions — simpler to just add `"auspicious_day_bonus"` to activities, boosting XP or resource gain

### Spells & Wounds

- **White magic healing spells** should be able to cure wounds out of combat — currently no mechanism; suggest: add `"cures_wound_category": "wound"` or `"cures_wound_id": "deep_cut"` to spell definitions; `apply_spell_outcome` in CombatManager (or overworld spell handler) checks this
- **Antidote / Cure Disease spells** (Water magic): natural fit for curing the disease category of wounds; could reduce `rests_untreated` by 1 rather than cure outright (weakened form for balance)
- **Ritual mandala**: a Full Rest with Ritual activity could lower wound escalation counters across the party (represents purification) — simpler than a spell, wires into the existing Ritual activity stub
- **Harm / Inflict Wound spells** (Black magic): should be able to apply wounds to enemies too, not just players — means enemies could accumulate wounds, which would make sense if a boss-fight-spanning wound system is ever added

### Weapon Effects & Wounds

- **Undead-tagged weapons** (e.g. bone weapons, grave-iron): hits have disease_chance passive proc, same as enemy undead hits — add `"disease_chance": 15` to weapon passive and check in `_process_weapon_on_hit_procs`
- **Wound-applying weapon traits**: a dagger with `"wound_chance": 20` and `"wound_type": "deep_cut"` — bleed-focused weapons that reliably inflict persistent wounds, not just combat bleed status; this creates a distinct class of "attrition weapons"
- **Healing weapons** (White magic enchantment): melee hits could reduce target's `rests_untreated` by 1 — passive tick-down mechanic; probably overpowered, but interesting for a dedicated healer-fighter
- **Silver weapons**: already a natural fit for "undead" enemies; could grant disease immunity to the wielder (touching undead with silver purifies) — simple passive flag on weapon

### Calendar & System Integration

- **Calendar-gated rest events**: the existing camp event system could use `lunar_day_required` field — on certain days a wandering spirit or auspicious vision appears, triggered by the existing `get_random_camp_event()` hook
- **Realm-time tension**: some realms should feel like time matters more (Hell = every rest costs more resources; Hungry Ghost = no rest recovery without food — already partially true); the calendar/time advance makes this tangible
- **Seasonal mechanics**: placeholder idea — if the calendar ever tracks seasons (not yet planned), certain diseases should be more likely (winter → bone fever chance up, summer → rot sickness down)

---

## Body Parts System (Design Phase)

A dedicated session deferred from the wounds implementation. The `body_location` field on wound entries is the current hook — it stores a part id as a string but nothing reads it yet.

### Goal

Replace the hardcoded flat equipment slot dict on `BASE_CHARACTER` with a **dynamic body plan** generated from a species definition. This unlocks:
- Location-specific wound penalties (leg wound = movement, arm wound = combat, head = cognitive)
- Multi-armed characters in higher worlds (deva, asura) with real extra weapon/hand slots
- Limb loss from severe wounds — temporary or permanent
- Prosthetics as items that slot into missing parts

### Proposed Data Model

Every character gets a `body_plan` key. Rather than storing all part state on the character, the *definition* (part topology) lives in a `BodySystem.BODY_PLANS` const keyed by species, and the character stores only runtime state (missing parts, prosthetics):

```gdscript
"body_plan": {
    "species": "human",      # key into BodySystem.BODY_PLANS
    "missing_parts": [],     # part ids that have been severed
    "prosthetics": {},       # {part_id: item_id} for attached prosthetics
}
```

`BodySystem.BODY_PLANS["human"]` defines the topology:

```gdscript
{
    "parts": [
        {"id": "head",   "category": "head",  "equip_slot": "head",   "parent": "torso",  "children": []},
        {"id": "torso",  "category": "torso", "equip_slot": "chest",  "parent": "",       "children": ["arm_l","arm_r","leg_l","leg_r","head"]},
        {"id": "arm_l",  "category": "arm",   "equip_slot": "hand_l", "parent": "torso",  "children": []},
        {"id": "arm_r",  "category": "arm",   "equip_slot": "hand_r", "parent": "torso",  "children": []},
        {"id": "leg_l",  "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["foot_l"]},
        {"id": "leg_r",  "category": "leg",   "equip_slot": "",       "parent": "torso",  "children": ["foot_r"]},
        {"id": "foot_l", "category": "foot",  "equip_slot": "feet",   "parent": "leg_l",  "children": []},
        {"id": "foot_r", "category": "foot",  "equip_slot": "",       "parent": "leg_r",  "children": []},
    ]
}
```

A four-armed deva species simply adds `arm_l2`, `arm_r2` with their own `equip_slot` values. `BodySystem.get_available_slots(character)` replaces the hardcoded slot list everywhere.

### Part Category → Wound Penalty Table

When a wound's `body_location` matches a part, its penalty type is determined by the part's category, not hardcoded per-wound. This lets us define wounds generically:

| Part category | Default penalty type | Example |
|---|---|---|
| head | spellpower, initiative | concussion on head part |
| arm | dodge, damage | deep cut on arm part |
| leg | movement, initiative | deep cut on leg part |
| torso | max_hp, max_stamina | broken rib on torso |
| foot | movement | twisted ankle |

This means `body_location` on a wound becomes mechanically meaningful, not just flavour.

### Limb Loss

- Wounds of `severity: "severe"` on a non-torso, non-head part have a small chance (5–10%) to sever it
- Severing adds the part id to `missing_parts`; its children (e.g. foot when leg is severed) are also added
- Items equipped in those slots are unequipped and returned to inventory
- `BodySystem.get_available_slots()` skips missing parts → UI automatically loses those slot buttons
- Recovery options: White magic regrowth spell, temple "body restoration" service (expensive), rare event

### Prosthetics

Items with `"prosthetic_for": "arm"` (or a specific part id) can be attached to a missing part:
- Full prosthetic (magical limb): restores slot, may give special properties (flame arm → fire damage on melee)
- Partial prosthetic (splint, hook): restores partial function, no equipment slot
- Stored in `body_plan.prosthetics` as `{part_id: item_id}`

### Species / Body Plans to Define

| Species | Arms | Legs | Notes |
|---|---|---|---|
| human | 2 (hand slots) | 2 (foot slot) | Standard — current hardcoded slots map exactly |
| four_armed | 4 (hand slots) | 2 | Deva/Asura realm; multi-weapon chain governs extra arms |
| six_armed | 6 (hand slots) | 2 | High deva/wrathful deity forms |
| serpentine | 2 | 0 (tail) | Naga / animal realm; tail = movement bonus, no foot slot |
| avian | 2 (wing-arms?) | 2 | Garuda; wings as back slot; partial-arm option TBD |
| centipede | 2 | 6+ | Animal realm; each extra leg pair = speed/weight bonus |
| undead_humanoid | 2 | 2 | Same as human; `missing_parts` list can be pre-populated |
| ethereal | 0 | 0 | Ghost-type — head + torso only; no limb equipment |

### Multi-Weapon Attack Chain (NEW COMBAT MECHANIC — DECIDED)

The core insight: **one sensomotor cortex drives all limbs**. Extra arms are real attack opportunities, but coordination degrades. Finesse governs the probability chain.

**Attack resolution per combat turn:**
1. Arm 1 (dominant): always attacks — 100%
2. Arm 2 (off-hand): `50 + (Finesse - 10) * 5`% — 50% at Finesse 10, 100% at Finesse 20
3. Arm 3: `25 + (Finesse - 10) * 4`% — 25% at Fin 10, 65% at Fin 20
4. Arm 4: `10 + (Finesse - 10) * 3`% — 10% at Fin 10, 40% at Fin 20
5. Arm 5: `5 + (Finesse - 10) * 2`% — 5% at Fin 10, 25% at Fin 20
6. Arm 6: `(Finesse - 10) * 2`% — 0% at Fin 10, 20% at Fin 20 (perks needed to reliably land this)

**Formula**: `chance[n] = base[n] + (Finesse - 10) * scale[n]`, capped 0–100%.

Humans always land arm 2 (they just have one off-hand, the formula still applies — at Fin 10 a human with a two-weapon build has 50% off-hand attack chance, which already creates incentive to raise Finesse even for 2-armed chars).

**Perk design space** (from TODO design notes):
- *Akimbo* (Finesse 14+): +20% to all secondary arm attack chances
- *Coordinated Strikes* (Finesse 16+, multi-arm species): chains reset on kill — if arm 3 kills an enemy, arm 4 gets a fresh roll
- *Thunderclap* (six-armed, Finesse 18+): if all arms fire in one turn, deal bonus AoE
- *Iron Cortex* (perk): removes the probability chain entirely for arms 1–2 (always both fire); arms 3+ still roll

**Extra legs — separate mechanic**:
Extra leg pairs don't attack. Each pair beyond 2 provides:
- +1 movement per pair
- +20 weight capacity per pair
- +5% dodge per pair (more stable base, harder to trip)

### Natural Weapons (DECIDED)

Parts in a body plan can have a `natural_weapon` dict. Two modes:

```gdscript
# Locked: part always has this weapon, cannot equip items in this slot.
# Used for: cat claws, mantis blades, wolf bite (jaw = head slot).
{"id": "claw", "display_name": "Claw", "damage_dice": "1d4", "damage_type": "slashing",
 "locked": true}

# Unlocked: natural weapon exists but slot can still take items (overrides natural weapon when equipped).
# Used for: weak humanoid fists (everyone has them), minor horns, etc.
{"id": "fist", "display_name": "Fist", "damage_dice": "1d3", "damage_type": "blunt",
 "locked": false}
```

`locked: true` → the `equip_slot` field on that part is ignored; the natural weapon is always the attack. The UI shows the natural weapon stats in that slot with a lock icon, no equip button.

Natural weapon items live outside the normal item database — they're defined inline on the body plan part. Damage scales with species level/XP like any weapon (future: `natural_weapon_scaling` table per species).

**Animal realm species examples:**
- `snow_lion`: arm parts → locked claws (1d6 slashing) + locked bite on head (1d8 piercing)
- `mantis`: arm parts → locked mantis blades (2d4 slashing, +crit chance)
- `bear`: arm parts → locked claws (1d8 slashing); body plan has extra torso HP bonus
- `naga`: arm parts → unlocked (can use weapons); tail → natural weapon "constrict" (special grapple attack)

### Limb Loss in Combat (DECIDED)

- Losing limbs mid-combat: **yes**. Triggered by severe hits targeting a specific body part (once wound-body location system is active)
- Limb loss is **not permanent** by default — it's a serious wound state, not death
- Recovery methods (in rough order of accessibility): White magic regeneration spell (high level), temple "bodily restoration" service (expensive gold), rare magical event ("Axolotl's Blessing", "Waters of the Living Mountain", etc.), long rest with Medicine 8+ (field regrowth — extraordinary)
- In-combat effects of severed limb: immediate: weapon in that slot drops to ground tile, attack chain shortened. Persistent: `missing_parts` entry, all wounds on that part removed (part is gone), stat penalties from part category apply
- Enemies can also lose limbs — a zombie losing its sword arm becomes unarmed. Implement for enemies when body system is live; defer for PC mid-combat until the system is stable

### Wound Location — Random Assignment (DECIDED)

When a wound arrives without an explicit `body_location`, assign one via `BodySystem.assign_random_wound_location(character, wound_category)`. Weighted by anatomical surface area:

| Part category | Weight |
|---|---|
| torso | 35% |
| arm (each) | 15% |
| leg (each) | 10% |
| head | 10% |
| foot (each) | 2.5% |

(Values for human; scaled proportionally for other species.) Extra arms/legs in multi-limb species redistribute weight evenly across all limbs. Missing parts are excluded from the pool.

### Granularity (DECIDED)

No fingers/toes. Eyes deferred — build the base system first, extend later.

### Attack Chain Balance Note

Multi-armed characters are intentionally strong against lower-world beings — that's thematically correct (a six-armed Asura facing a human should feel overwhelming). Balance levers to tune during playtesting:
- Per-extra-arm accuracy penalty (e.g. -5% accuracy per arm beyond the first)
- Per-extra-arm damage scalar (e.g. 85% damage on arm 3+)
- These are additive nerfs on top of the probability chain, not replacements for it
- Expect multi-armed races to be rare in hell/hungry-ghost realms and dominant in asura/deva — the power gap is a feature if the player earns it through reincarnation

### Implementation Plan (Next Session)

**Phase 1 — Foundation** ✓ COMPLETE:
1. [x] `BodySystem` autoload: `BODY_PLANS` const (human, four_armed, serpentine), `get_equipment_slots()`, `get_arm_slots()`, `get_part_category()`, `get_wound_penalties()`, `assign_random_wound_location()`, `get_part_for_slot()`, `is_multi_armed()`
2. [x] `ItemSystem.calculate_equipment_stats()` now calls `BodySystem.get_equipment_slots(character)` — four-armed characters automatically pick up hand_l2/hand_r2 item stats
3. [x] `CharacterSystem._find_slot_for_item()` uses `BodySystem.get_arm_slots()` for gloves — finds extra hand slots on multi-armed species
4. [x] `WoundSystem` refactored: removed `stat_penalties_pct` from wound type defs; added `severity` + `forced_location`; `get_stat_penalties()` now derives penalties from `body_location` part category + severity via `BodySystem.get_wound_penalties()`
5. [x] `apply_wound()` auto-assigns location: forced_location → random via `BodySystem.assign_random_wound_location()` → "torso" fallback
6. [x] `BASE_CHARACTER` gains `body_plan: {species, missing_parts, prosthetics}`; old characters without the key default to "human" gracefully

**Phase 2 — Limb dynamics** (same session or next):
4. `sever_part()` / `regrow_part()`: cascades to children, unequips items, hooks into combat and events
5. Natural weapons: `locked` flag on body plan parts; locked slot UI; natural weapon stats in combat resolution

**Phase 3 — Multi-limb mechanics** (when asura/deva/animal realm content begins):
6. Multi-weapon attack chain in CombatManager: Finesse probability formula per arm index; accuracy/damage scalars as balance dials
7. Extra leg pairs → movement/weight/dodge bonuses in `update_derived_stats`
8. Prosthetics item type
9. Additional species plans (avian, centipede, bear, snow_lion, etc.) as content demands

---
10. More species plans as animal realm content is built

---

## Design Questions

### Karma Visibility
Currently completely hidden (thematic). Should Yoga skill unlock karma meditation to see rough scores? Or keep totally mysterious?

### Miniboss & Boss Mechanics
Unique per-fight mechanics for realm minibosses (multi-phase fights, special win/lose conditions, environmental interactions).
- Hell: standard so far
- Hungry Ghost candidates: Bone Lord (earth magic + undead commander), Great Devourer (shaza), Mirror of the Setting Sun (copper construct), Matriarch of All Longing (yidag)

### Realm-Specific Mechanics
- Hell: pure combat focus — done
- Hungry Ghost: resource scarcity?
- Animal: mix of combat and negotiation
- Human: heavy dialogue/quest focus — three zones:
  - West (Oddiyana/Gandhara steppe): Scythian nomads, cavalry → Ranged, Guile, Daggers
  - NE (Zhang-Zhung): proto-Tibetan shamanic Bön, yak herders → Ritual, Yoga, Earth magic
  - SE (coastal trade cities): cosmopolitan mercantile → Trade, Persuasion, Alchemy
- Asura: competitive events, duels?
- God: almost no combat, diplomacy/trade?

### Weapon Element Affinity
Each weapon has an `element` field. Design: high elemental affinity boosts weapons of that element (e.g. Space affinity → extra crit/damage with swords/staffs). Wire into CharacterSystem affinity bonuses or `generate_weapon()` stat scaling.

### Mantra System
Some Deity Yoga effects are simplified stat bonuses rather than true unit spawns — acceptable for now?

---

## Deity Systems (Design Phase — Not Yet Started)

### Yidam System (Personal Deity Practice)
- Deities are **translated** into English (e.g. "Adamantine Terrifier" not "Vajrabhairava") — avoids publishing secret names while communicating meaning
- Roster built from existing mantra list in PERKS.md; masks as optional head-slot items giving massive Deity Yoga bonus
- **Relationship stages**: Heard → Connected → Practicing → Established → Realized (persists cross-lifetime from Practicing+)
- **Mechanics**: mantra accumulation (existing system) is the primary mechanic; high recitation counts unlock deeper stages; commitment to a single deity is mechanically rewarded
- **Masks** give large Deity Yoga bonus — not required, but reward deity-focused builds
- **Karma affinity** — some deities more accessible depending on karma profile (to design)
- **Dedicated spell** per deity — unlocked at Practicing+, deity's signature
- **Quest chain** per deity — short, encounter-chain style (to design)
- [ ] Design deity roster (translate names, assign karma affinities, mantras, spells, masks)
- [ ] Implement relationship tracking (YidamSystem autoload or extend KarmaSystem)
- [ ] Wire mask bonuses into Deity Yoga activation
- [ ] Design cross-lifetime persistence rules
- [ ] Write quest chains per deity

### Dharmapala System (Protector Relationships)
- Protector deities, **translated names**, accessed via **shrines** on the overworld map
- Relationship is **transactional** (offering-based) and **worldly** — complements yidam's inner transformative practice
- **Offerings**: realm-specific items consumed at shrines; each dharmapala wants specific items
- **Relationship stages**: Stranger → Known → Favorable → Under Protection → Bonded (persists cross-lifetime from Favorable+)
- **Interventions**: limited uses per dharmapala, refresh between shrines; each reflects the deity's nature (fate rerolls, oracle glimpses, enemy weakening, etc.)
- **Vow system**: each dharmapala has 1-2 associated behavioral constraints; breaking them damages the relationship
- Cross-lifetime persistence: at Bonded, full relationship carries; at Favorable, partial meter carries
- **Synergy with Yidam**: e.g. a Hayagriva yidam + fire-aspect dharmapala creates a natural build
- **Synergy with equipment**: Black Sorcerer's Robe + Mahakala relationship passive bonus
- [ ] Design dharmapala roster (translated names, domains, offering requirements, interventions, vows)
- [ ] Design shrine objects for overworld (map_generator.gd placement)
- [ ] Implement DharmapalSystem autoload (offering tracking, relationship meters, interventions)
- [ ] Wire cross-lifetime persistence into KarmaSystem / reincarnation logic
