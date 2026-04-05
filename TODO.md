# Six Worlds - TODO

Last Updated: 2026-04-03

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

### Step 8 — Magic Foci

#### Design Rules
- Type: `focus`. Occupy weapon_main or weapon_off slots (intentional sacrifice — no free slot)
- One-handed foci are shield-compatible
- Governed by the **Ritual** skill
- Material tiers: **Bone** (Phurba + Khatvanga only) → **Copper** → **Silver** → **Gold** → **Sky-Iron** → **Vajra**
  - Copper/Silver/Gold added to equipment_tables.json as focus-only materials ✓
- Weapon damage is vestigial (1–5 at most); the real value is in spellpower/mana/school bonuses
- School coverage: White (Dorje), Space (Drilbu), Summoning (Kangling), Enchantment (Damaru), Black (Khatvanga), Sorcery (Phurba)

#### Spell Accuracy / Spell Projectiles
- [ ] **Deferred**: Projectile deviation for spells — only makes sense for spells with a visible physical projectile (firebolt, lightning bolt, etc.). Would need a `"projectile": true` tag in spells.json. Leaving to ferment — not sure if spell misses feel fair vs. ranged weapon misses.
- [ ] **Deferred**: `spell_accuracy` as a stat distinct from weapon accuracy — some foci could add it, reducing deviation chance on projectile spells.

#### Set Bonus System (Dorje + Drilbu)
- [x] Implemented in `calculate_equipment_stats()` — when both weapon slots carry `set_pair: "dorje_drilbu"`, adds +3 Spellpower, +3 Max Mana, +2 Initiative; sets `active_set_bonus` field in equip_bonus for future combat opener hooks
- [x] Tooltip shows set bonus line in gold when item has `set_pair` field

#### Individual Foci

**Dorje / Vajra** — weapon_main, one-handed
- Passive: +spellpower, +White magic skill bonus
- Tiers: Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json

**Drilbu / Bell** — weapon_off, one-handed
- Passive: +max_mana, +Space magic skill bonus
- Tiers: Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json

**Khatvanga** — weapon_main, two-handed, some weapon damage (5–8)
- Passive: +spellpower (moderate), +max_mana (smaller), +Black magic skill bonus
- Passive aura: enemies within melee range have reduced initiative (no action required)
- Tiers: Bone → Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json
- [x] Wire initiative aura in combat_manager.gd — `get_passive_perk_stat_bonus(unit, "initiative")`, equipment section (runs for all units regardless of perks)

**Damaru** — weapon_off, one-handed
- Passive: +max_mana, +Enchantment skill bonus
- Active — **Rhythm Charge**: each spell cast while holding the Damaru adds 1 charge (max 3). At 3 charges, next spell costs 40% less mana. Charges reset after the discount fires.
- Tiers: Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json
- [x] Wire charge mechanic — `damaru_charges` on CombatUnit; incremented in `_process_spell_cast_perks()`; discount fires in `cast_spell()` before mana deduction

**Kangling** — weapon_off, one-handed
- Passive: +spellpower, +Summoning skill bonus
- Active — **Chöd Offering**: cost is always floor(max_mana × 0.25). Deducted from current mana first; any shortfall comes from HP. Gain spellpower = ceil(cost / 2), stacking until end of combat.
- Tiers: Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json
- [x] Wire Chöd action — `_resolve_chod_offering()` in combat_manager.gd; `chod_spellpower_bonus` on CombatUnit wired into `get_spellpower()`; surfaced via Skills panel in combat_arena.gd

**Phurba** — weapon_main or weapon_off, one-handed, moderate weapon damage (4–5)
- Passive: +spellpower, +Sorcery skill bonus
- Active — **Throw Phurba**: whole-battlefield range (capped at 80 tiles), mana cost 15. Damage = throw_base_damage + sorcery×2. DC 16 Focus save → Subjugated 3 turns on failure.
  - "Subjugated" is distinct from "Pinned" (Trishula): Pinned = no movement. Subjugated = no movement + no attacks.
- Tiers: Bone → Copper → Silver → Gold → Sky-Iron → Vajra
- [x] Add items to items.json
- [x] Add "Subjugated" to statuses.json
- [x] Wire Throw Phurba action — `_resolve_throw_phurba()` in combat_manager.gd; surfaced via Skills panel
- [x] Wire Sorcery skill into Phurba damage calculation (base + sorcery_level × 2)

#### Other weapon mechanics wired this session
- [x] **Trishula on_crit_status** — `on_crit_status` field checked in `_process_weapon_on_hit_procs()` after crits
- [x] **Bichawa parry_effectiveness** — `parry_effectiveness` in off-hand stats → armor bonus in `get_passive_perk_stat_bonus(unit, "armor")`, equipment section
- [x] **Chakram pass_through** — traces attack line beyond defender in `_process_weapon_on_hit_procs()`; runs before `passive.is_empty()` guard
- [x] **Urumi sweep** — hits all other adjacent enemies at −15 acc for 75% dmg, in `attack_unit()` on-hit block

#### Ritual Garb

**Design Notes (implement in a dedicated session)**
- Slot: `chest` (robes) and `head` (masks)
- Material: no material tiers — ritual garb is unique crafted/found gear
- Each school of magic gets a matching robe + mask pair:
  - **White** — Healing Robe + Clarity Mask (+White magic skill, +spellpower, +max_mana)
  - **Black** — Death Shroud + Skull Mask (+Black magic skill, +spellpower, fear aura)
  - **Space** — Void Robe + Void Mask (+Space magic skill, +initiative)
  - **Air** — Wind Dancer Robe + Feather Mask (+Air magic skill, +dodge, +movement)
  - **Fire** — Flame Mantle + Ember Mask (+Fire magic skill, +crit_chance)
  - **Water** — Flowing Robe + Wave Mask (+Water magic skill, +healing effectiveness)
  - **Earth** — Stone Robe + Iron Mask (+Earth magic skill, +armor, +HP)
  - **Sorcery** — Sorcerer's Robe + Demon Mask (+Sorcery skill, +spellpower, on-kill effect)
  - **Enchantment** — Enchanter's Robe + Silk Veil (+Enchantment skill, +max_mana, +spell duration)
  - **Summoning** — Bone Robe + Horn Mask (+Summoning skill, +summoned unit HP)
  - **Ritual** — Ceremonial Robe + Tantric Crown (+Ritual skill, +mandala effectiveness)
- Monastic tradition garbs (cross-school, for specific playstyles):
  - Vajrayana Robe (White + Black + Summoning), Dzogchen Mantle (Space + Air + Yoga)
- [ ] Add items to items.json
- [ ] Wire school bonus display in item_tooltip.gd (extend skill_bonuses section for ritual garb)

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

### Other Realms (Content Gaps)
- [ ] Convert HG_EVENTS.md → hungry_ghost_events.json
- [ ] Map configs for remaining realms — only hell.json and hungry_ghost.json exist
- [ ] Enemy archetypes + encounters for animal, human, asura, god realms (hungry_ghost done: 20 archetypes, 37 encounters)
- [ ] Event files for remaining realms (animal, human, asura, god)
- [ ] Companion definitions for remaining realms (companions.json has hell only)

### Companions
- [ ] Camp Followers system — UI stub exists in Party tab (`_update_followers_list()`); no backend

---

## Medium Priority

### Perks
- [ ] PERKS.md: extend base bonus tables to level 10 for 32 remaining skills (Learning, Comedy, Spears already done)
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
- [ ] More consumable items — no realm-specific variants currently
- [ ] Cursed equipment — "cursed" is only a status effect/terrain type; no cursed items in items.json

### Audio
- [ ] Background music per realm
- [ ] Combat music
- [ ] Air, Water, Earth spell impact sounds (only fire + generic exist)

---

## Low Priority

- [ ] Meta-progression (cross-run persistence) — save_manager handles per-run state only

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
