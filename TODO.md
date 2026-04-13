# Six Worlds - TODO

Last Updated: 2026-04-05

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
- [ ] **Shop distribution** — no shops currently stock implements; add Plain/Blessed tier items to ritual-focused shops
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
- [ ] Companion definitions for remaining realms (companions.json has hell only)

### Companions
- [ ] Camp Followers system — UI stub exists in Party tab (`_update_followers_list()`); no backend

---

## Medium Priority

### Perks
- [x] Base bonus tables complete for all 35 skills, levels 1–15 (11–15 = item-bonus cap, same value as 10)
- [x] **Bug fixed**: parse_perks.py now expands `11–15` range rows into individual level keys — perk_system.gd's `str(level)` lookup was silently returning empty dict for levels 11–15
- [ ] PERKS.md: fill empty perk tiers (levels 2, 4, 6, 8) — 1-2 perks per skill at each
- [ ] Perk rebalancing — capstone perks should land at required_level 8-10 (distribution still front-loaded)
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
- [ ] **Spell duration unification** — buff/debuff durations are currently inconsistent across spells (some use `"spellpower"`, some `"combat"`, some fixed turns, some `"spellpower_turns"`). Need a unified scaling formula: e.g. base_turns + floor(spellpower / threshold). Affects all enchantment/white spells. Also: `clear_mind` mental immunity and similar conditional immunity spells need their duration to feel proportional to spell level and caster investment.
- [ ] Terrain affecting spell power — no terrain-based spellpower modifiers in combat_manager.gd cast_spell()
- [ ] Environmental spell interactions — spells create terrain (done); terrain does not yet buff/debuff spells of matching element
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
- [ ] Item flavor text: `space_charm_common` and `rations` may show broken tooltip — needs in-game testing

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
