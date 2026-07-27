# Six Worlds — TODO

**Last updated:** 2026-07-27 (rewritten as a live document)

This file was an append-only log for a long time and had grown to the point
where finished work outweighed the remaining work three to one. It is now
organised as: **where things stand → what is still open → designs waiting to be
built → what got done**. The full historical checklists (every `[x]` line from
the psychology, weapons, camp, wounds and body-plan passes) are preserved in git
at commit `73a948c` if you ever want the detail back.

Companion documents:
- `REFRESHER.md` — orientation after a break; read that first
- `PERKS.md` — perk trees per skill
- `EVENT_SYSTEM.md` — how events, choices and outcomes work
- `EDIT_LATER.md` — prose that needs your pass
- `tools/validate_data.py` — run after any content edit; exits non-zero on a
  dangling reference

---

## Where things stand

### Content

| Realm | Map | Archetypes | Events | Companions | Quests | Dead map weight |
|---|---|---|---|---|---|---|
| **Hell** | ✓ cold / fire + divider | 45 | 79 | 24 | 3 | 0% |
| **Hungry Ghost** | ✓ 3 zones | 23 | 150 | 23 | 0 | 0% |
| **Animal** | ✓ ocean / forest / meadow | 34 | 94 | 24 | 0 | 0% |
| Human | ✗ | ✗ | ✗ | ✗ | ✗ | — |
| Asura | ✗ | ✗ | ✗ | ✗ | ✗ | — |
| God | ✗ | ✗ | ✗ | ✗ | ✗ | — |

Plus 22 cross-realm domain events. **345 events total**, of which 336 have
choices: 624 grey, 506 blue, 167 yellow.

Other totals: **600 perks** (546 skill + 54 cross, every skill covered at every
level 1–10), **363 spells**, **565 items**, **63 traits**, **12 prosthetics**.

### Systems

Twenty autoloads, all wired: characters/XP, karma/reincarnation, events, grid
combat (spells, AoE via `AoEResolver`, statuses, AI, projectiles), overworld
(real-time movement, mobs, portals with boss gating), shops/training/guilds,
procedural items, perks, psychology/pressure, traits, wounds, body plans
(multi-arm species, limb loss, prosthetics), camp/rest/time/lunar calendar,
save/load (3 slots), audio, cheat console. Engine: **Godot 4.6**.

Validator reports **0 issues**; all scripts pass `gdparse`.

### What has never been played

Everything added in the 2026-07-27 passes. The animal realm has never been
played at all; hungry ghost gained 71 events; boss gating, difficulty
multipliers, wound healing, the quest chains, and a large batch of statuses went
from data-only to live. See `REFRESHER.md` § Point of departure.

---

# Part I — Loose ends

Ordered by how much finished work sits behind each one.

## 1. Small and self-contained

Each of these is an hour or less and touches one system.

- [ ] **9 race descriptions are placeholders** (`TODO: Fill in description`):
  `nomad`, `mountain_folk`, `trader`, `tsen`, `rudra`, `gandharva`, `apsara`,
  `planetary_deity`, `bee`. All but `bee` belong to unbuilt realms, so this can
  wait for those; **`bee` is animal-realm and reachable now.**
- [ ] **`sever_part` doesn't handle `arm_l2`/`arm_r2`** — four-armed species have
  equip slots `hand_l2`/`hand_r2` but no `weapon_main2`/`weapon_off2`, so
  severing an extra arm doesn't drop its weapon.
- [ ] **`extra_arm_results` isn't shown in the combat UI** — the multi-arm chain
  writes per-arm hit/damage into the result dict and the combat log prints it,
  but the unit frames don't (no "Arm 2: 12 dmg" popup).
- [ ] **Combat-UI wound icons** — wounds render in the character sheet; unit
  frames need sprite work.
- [ ] **Enemy racial resistances are archetype-only** — `races.json`
  `base_resistances` (e.g. skeleton's 50% physical reduction) reaches a
  `CombatUnit` built from a character dict, but `EnemySystem._build_enemy()`
  only copies the archetype's own `resistances`. An archetype-defined skeleton
  doesn't inherit its race's resistance. Arguably by design — archetypes are
  meant to be self-describing — but the two paths should agree deliberately.
- [ ] **Projectile sprites** — arrows/bolts/firebombs are a `Line2D` flash.
- [ ] **Tooltips** — `item_tooltip.gd` covers items; status effects, terrain
  tiles and turn-order icons have none.
- [ ] **Upgrade selection popup** (choose 1 of 4) — no scene or system exists.
- [ ] **Spell impact sounds** for Air, Water, Earth (fire + generic exist).
- [ ] **Background/realm music** — none.

## 2. Implemented features with no content using them

The mirror image of dead data: code paths that work and are never exercised.

- [ ] **`trait` / `not_trait` event requirements** — fully implemented in
  `event_manager.check_requirements()`, used by **zero** of the 336 events with
  choices. The 63 traits carry `event_tags` that only PsychologySystem reads.
  Character traits currently affect events not at all. A dozen `trait`-gated
  choices would make inborn traits feel real.
- [ ] **`wound` and `sever_part` event rewards** — both handled, both unused by
  any event. Nothing in the game maims you outside combat.
- [ ] **Only 3 of the ~8 supported requirement keys are used** — events use
  `skills` (458), `roll` (158), `attributes` (60) and nothing else.
- [ ] **Cursed items** — "cursed" is a status and a terrain type; zero cursed
  equipment exists, though the item type is registered.
- [ ] **`mantra_count`** accumulates via camp Mantra Recitation with no
  consumer (blocked on YidamSystem — see Part II).
- [ ] **`persistent_upgrades`** survives reincarnation in `character_system.gd`,
  but nothing ever grants one. No meta-progression exists.
- [ ] **Camp Followers** — Party-tab UI stub (`_update_followers_list()`), no
  backend.
- [ ] **`tactical_assessment` perk** (Logistics 7) exists in perks.json with no
  code — it was meant to unlock preset formations.

## 3. Data with no consumer

- [ ] **27 of the 40 `base_bonuses` stat keys are read by nothing.** Full table
  with owning skill, L1/L5/L10 values and the system each would hook into is in
  Part III below. This is the largest single gap: most general skills currently
  pay out only their combat numbers.
- [ ] **10 embedded `todo` keys in the data files** promise mechanics no code
  reads. Nothing in TODO.md ever tracked them:
  - `traits.json` — `venom_ward`, `undead`, `incorporeal` all declare a
    `resistances` block; TraitSystem applies only `stat_modifiers`,
    `skill_modifiers` and `pressure_modifiers`, so those three traits are
    cosmetic
  - `traits.json` — `aquatic` / `flying` party-wide tile traversal,
    `night_vision` darkness immunity, `insatiable` (+50% food, −50% rest
    recovery)
  - `items.json` — `smoked_lenses` blindness immunity
  - `races.json` — `shambler` **background** (not race, as previously recorded)
    is −7 net attributes with no compensating passive; `jaina` background wants
    karma wiring (slower animal karma, drift toward human/god)
- [ ] **`skeleton_king_duel`** stops at 10% HP — verify the special win
  condition still fires after the combat refactors.

## 4. Content that wants writing

- [ ] **A prose pass on 81 events and 24 companion bios.** The animal realm's 47
  zone events, hungry ghost's 34 gap-fill events, the three HG boss/pass-guardian
  events, and all 24 animal companion bios are Claude's prose, not yours. This is
  the single biggest content item and only you can do it.
- [ ] **63 events are grey-only** (of 336 with choices) — no blue or yellow
  option at all. The stated target is ≥2 meaningful checks per event.
- [ ] **500 of 600 perks have empty `flavor`.** Better in your voice than mine.
- [ ] **Quests: 3 total, all hell.** The board works and the validator now
  guarantees every step flag is settable, but hungry ghost and animal have none.
- [ ] **Hell event chains still unwritten** from the original list: soul caravan
  ambush, devil deserter, contraband deal, corrupted simple, chained pilgrim,
  rival party.
- [ ] **Realm-specific wounds** — 5 base types exist (3 wounds, 2 diseases);
  target ~8–10. Wanted: arrow wound, poisoned wound, spiritual corruption
  (resists medicine, needs Ritual/Yoga), HG malnutrition, animal parasites,
  hell frostbite/burns. Design notes in `EDIT_LATER.md`.
- [ ] **Consumables and equipment are thin** in realm-specific flavour — 68
  legendary-rarity items exist, so the tier itself is covered.
- [ ] **Astrological spells (Space)** — divination, eclipse/conjunction
  triggers; motivates the Sun Priestess companion's Space skills.
- [ ] **Paushtikakarma spells (Earth)** — wealth multiplication, dowsing for
  ore; gives teeth to trade/merchant builds (Hustle Bones, Trade+Earth).
- [ ] **Ritual implement special traits** — conch pacification aura, bone
  life-drain proc, sky-iron void field. Design deferred.
- [ ] **Realm-specific rest events** — "something stirs in the night" flavour
  when resting in hell / hungry ghost.

## 5. Whole realms

Human, asura and god need: map config, archetypes, encounters, event file,
companions, backgrounds, shops. Human-realm zone design is sketched in Part II.

## 6. Balance passes waiting on play

All first-pass numbers. Nothing here is a bug; they need a playthrough.

**Combat**
- Summoning terrain affinity: flat +25% and the terrain→element table
- `pack_bonus`: +3 accuracy/dodge per packmate, cap +12
- `priority_target` isolation weights; whether `burrow_emerge` should cost an action
- `Mantric_Armor` shield pool (25), `Mirror_Images` copies (3)
- Reflect 60% / `Magic_Mirror` 50% reflect chances
- Multi-arm damage scalars and per-extra-arm accuracy penalty
- Difficulty multipliers (easy 0.75 … boss 1.6) — now applied to every event fight
- Spell mana costs (15/40/75/135/225 by level)

**Wounds** (`WOUND_PENALTIES` in `body_system.gd`)
- Are percentage penalties proportionate across stat ranges? Finesse 8 vs 16
  experiences an arm wound very differently
- Severe head (−30% spellpower, −25% initiative, −15% max HP) vs severe torso
  (−35% max HP, −25% stamina) — is head too punishing?
- Feet may be too mild relative to legs; consider a persistent `prone`
- Diseases share the physical wound table via `body_location` — should
  `rot_sickness` at torso hit max mana or spellpower instead of HP?
- `rests_untreated` escalation thresholds (2–3 rests) — too fast given rests
  already cost resources?
- Naga (serpentine, no legs) needs its own pass — it cannot take leg/foot wounds

**Camp & economy**
- Forage yield relative to rest costs, per realm
- Brew Potions count (1–3) vs 2 reagents — compare to shop prices
- Pressure decay: Full Rest + Sadhana totals 250 (100 + 150). Should sadhana
  replace rest decay rather than stack?
- Activity slots (Camp 1, Full 2) — implement a Logistics +1 slot perk?
- Enhanced camp activity multiplier (1.5×) and Set Snares yields
- Wound healing price: (20 + 15 × cure_medicine_level) × shop modifier
- **Gold reward tokens: small 40 / moderate 100 / large 180** — derived from the
  60 numeric rewards already in the event files (median 100, terciles 80/130)
- Trade L10 reads 60% buy discount / 70% sell markup — probably intended as a
  soft cap, not a literal multiplier. Decide before wiring (Part III)

## 7. Perks deferred on missing systems

Not gaps in the perk trees — these are written and waiting on machinery.

**Need new mechanics:** `metamagic` (pre-cast modal), `void_touched` (void tile
type), `roles_assigned` / `tactical_synergy` (role designation UI),
create_terrain perks (`inscribed_circle`, `fog_of_war`, `black_ice`,
`raise_wall`, `gravity_well`, `improvised_barricade`, `prepared_ground` — need
timed terrain tiles), `create_images` / `smoke_and_mirrors` (illusion units),
`imbued_attack` / `arcane_archer` (attack+spell hybrid), `mass_teleport`,
`recruit_or_pacify`, `place_trap` / `trap_maker`, `steal_item` /
`the_invisible_hand`, `guard_ally` / `stalwart_guardian`, `choose_one` /
`improvised_masterpiece`, `attune_charm`, `trap_sense`.

**Need economy/social systems:** `investment` / `trade_empire` (passive income),
`supply_cache` / `extended_march` (supply action), `guided_practice` /
`the_lineage_continues` (companion spell-teaching), `black_market_contacts` /
`fence` (black-market tier), `patron_of_the_arts` (renown).

**Wound/body perks designed, not written:** `hardened` (Con 14+, 50% chance to
negate an incoming crit wound), `undead_hunter` (Earth magic 3+, disease
immunity from undead hits), `stubborn_body` (Con 15+, +1 to all
`escalation_rests`, as `character.wound_escalation_delay`), `iron_cortex` (arms
1–2 always fire, 3+ still roll).

## 8. Deferred by decision

Recorded so they aren't rediscovered as bugs.

- **`Dominated` full enemy control** — the puppet loses its turns; real control
  needs a player-drives-an-enemy-unit UI flow
- **Aura statuses** (`Soothing_Presence`, `Guardian_Kings`) — handled per-mantra
  by design, not via status effects
- **`attack_damage_buff_when_ally_dies`** — applies Rage, whose damage bonus is
  generic; a bespoke stacking version is unimplemented
- **Head natural weapons** (bite, beak) sit outside the arm attack chain — needs
  a head special-attack action or a primary-slot override
- **Coordinated group AI** (focus fire, flanking) — a larger AI feature
- **Day/night visuals** on the overworld; **rest blocked when a mob is adjacent**
- **Protector Offering** camp activity — blocked on DharmapalaSystem
- **More species**: centipede (many legs), bear — as animal content grows
- **Klesha / chronic-darkness counter** — debuffs for time spent below −50
  pressure
- **Psychology Layer 3 intervention** — social skills let one character reduce
  another's pressure
- **Racial trait content review** — `hell_born`, `undead_nature`,
  `spirit_nature`, `serpentine` are deliberate stubs pending realm design

---

# Part II — Designs waiting to be built

Kept in full: these are settled designs with no implementation yet.

## Yidam System (personal deity practice)

- Deities are **translated** into English ("Adamantine Terrifier", not
  "Vajrabhairava") — avoids publishing secret names while keeping the meaning
- Roster drawn from the mantra list in `PERKS.md`; masks as optional head-slot
  items granting a large Deity Yoga bonus
- **Relationship stages**: Heard → Connected → Practicing → Established →
  Realized (persists cross-lifetime from Practicing+)
- **Primary mechanic**: mantra accumulation — `mantra_count` already
  accumulates via camp Mantra Recitation and has no consumer today, so the hook
  is waiting
- Commitment to a single deity is mechanically rewarded
- **Karma affinity** — some deities more accessible by karma profile
- **Dedicated spell** per deity, unlocked at Practicing+
- **Quest chain** per deity, encounter-chain style

Tasks: design roster (names, karma affinities, mantras, spells, masks) ·
implement relationship tracking (YidamSystem autoload or extend KarmaSystem) ·
wire mask bonuses into Deity Yoga activation · define cross-lifetime persistence
· write quest chains.

## Dharmapala System (protector relationships)

- Protector deities, translated names, accessed via **shrines** on the overworld
- Relationship is **transactional** (offerings) and **worldly** — complements
  yidam's inner practice
- **Offerings**: realm-specific items consumed at shrines; each dharmapala wants
  particular things
- **Stages**: Stranger → Known → Favorable → Under Protection → Bonded
  (persists cross-lifetime from Favorable+; full carry at Bonded, partial at
  Favorable)
- **Interventions**: limited uses, refresh between shrines, each reflecting the
  deity's nature — fate rerolls, oracle glimpses, enemy weakening
- **Vows**: 1–2 behavioural constraints each; breaking them damages the bond
- **Synergies**: a Hayagriva yidam + fire-aspect dharmapala is a natural build;
  Black Sorcerer's Robe + Mahakala relationship passive

Tasks: design roster (domains, offerings, interventions, vows) · shrine objects
in `map_generator.gd` · DharmapalaSystem autoload · cross-lifetime persistence
in KarmaSystem/reincarnation.

## Masks and the face slot

A major design space, deferred to its own pass. `face` slot, type `"mask"`,
already mapped in `_find_slot_for_item()`.

- Deity masks → large Deity Yoga bonus; school masks → skill bonus to one
  school; elemental masks → resistance + minor affinity
- Possible types: wrathful (combat), peaceful (healing/buff), animal form
  (special abilities), ritual (Ritual/Yoga)
- Cross-reference the ritual garb masks already generated — combat masks vs
  ritual masks vs deity masks may need separate type tags

## Wounds × spells × items (design, unbuilt)

**Spells**
- White magic should cure wounds out of combat — suggest `cures_wound_category`
  / `cures_wound_id` on spell defs, checked in the spell outcome handler
- Water magic antidotes — reduce `rests_untreated` by 1 rather than curing
  outright (`reduce_escalation: 1`)
- Black magic harm spells — `inflict_wound` (wound id + chance) so enemies can
  accumulate wounds too
- Ritual mandala at Full Rest — lower wound escalation counters party-wide

**Items**
- Weapon traits `wound_chance` + `wound_type` — bleed weapons that inflict
  persistent wounds, an "attrition weapon" class
- Weapon trait `disease_chance` + `disease_type` for bone/grave-iron weapons
- Silver weapons — `disease_immune_on_hit`, purification on contact
- Thematic armour reducing wound chance for its body location (bracers → arms,
  sabatons → feet)

**Calendar**
- Lunar-day perk bonuses (e.g. Full Moon Practitioner: +5 spellpower on day 15)
  via a `PerkSystem.check_lunar_bonus()` hook in `update_derived_stats`
- `auspicious_day_bonus` on camp activities
- `lunar_day_required` on camp events
- Realm-time tension: hell rests cost more, HG gives no recovery without food
- Seasons: placeholder — if ever tracked, winter → bone fever up, summer → rot
  sickness down

**Rest perks designed, unbuilt**
- Light Sleeper (Awareness 12+): Quick Rest heals +10% (currently 40%)
- Meditator's Repose (Yoga 4+): Full Rest always counts as a safe camp
- Iron Constitution (Con 14+): Medicine heal_pct doubles at Full Rest

## Realm-specific mechanics

- **Hell**: pure combat focus — done
- **Hungry Ghost**: resource scarcity
- **Animal**: combat and negotiation mixed
- **Human**: heavy dialogue/quest focus, three zones —
  West (Oddiyana/Gandhara steppe): Scythian nomads, cavalry → Ranged, Guile,
  Daggers · NE (Zhang-Zhung): proto-Tibetan shamanic Bön, yak herders → Ritual,
  Yoga, Earth magic · SE (coastal trade cities): cosmopolitan mercantile →
  Trade, Persuasion, Alchemy
- **Asura**: competitive events, duels
- **God**: almost no combat; diplomacy and trade

## Miniboss and boss mechanics

Unique per-fight mechanics: multi-phase fights, special win/lose conditions,
environmental interaction. Hell is standard so far. Hungry ghost candidates:
Bone Lord (earth magic undead commander), Great Devourer (shaza), Mirror of the
Setting Sun (copper construct), Matriarch of All Longing (yidag).

## Open design questions

- **Karma visibility** — currently fully hidden (thematic). Should Yoga unlock a
  karma meditation showing rough scores, or stay mysterious?
- **Weapon element affinity** — every weapon has an `element` field doing
  nothing. Design: high elemental affinity boosts weapons of that element. Wire
  into affinity bonuses or `generate_weapon()` scaling.
- **Mantra system** — some Deity Yoga effects are simplified stat bonuses rather
  than true unit spawns. Acceptable?
- **Spell accuracy / spell projectiles** — deliberately left to ferment.
- **Combat grid size** and how much positioning should matter.

---

# Part III — Per-level skill bonuses with no consumer

Found 2026-07-27. Kept in full because it is the largest actionable gap.

`perks.json` → `base_bonuses` gives every skill a per-level stat table, and
`CharacterSystem.update_derived_stats()` applies **13 of the 40 stat keys**. The
other 27 are read by nothing, so those skill levels grant their combat numbers
and then silently grant nothing else. Levelling Trade to 10 currently confers no
discount, Grace no movement, Logistics no travel or supply benefit.

Applied today: `attack`, `damage`, `strength_weapon_damage`, `crit_chance`,
`armor`, `armor_penetration`, `max_hp`, `damage_reduction_pct`, `spellpower`,
`mana_cost`, `dodge`, `stamina`, `initiative`.

**Not applied** (value at L1 / L5 / L10, all percentages):

| Stat key | Granted by | L1 / L5 / L10 |
|---|---|---|
| `burning_damage` | fire_magic | 5.0 / 75.0 / 130.0 |
| `buy_discount` | trade | 5.0 / 35.0 / 60.0 |
| `charm_effectiveness` | persuasion | 5.0 / 75.0 / 130.0 |
| `consumable_power` | alchemy | 10.0 / 75.0 / 130.0 |
| `crafting_quality` | smithing | 10.0 / 75.0 / 130.0 |
| `crafting_yield` | alchemy | 10.0 / 50.0 / 75.0 |
| `effect_duration` | enchantment | 5.0 / 45.0 / 75.0 |
| `healing_effectiveness_(party)` | medicine | 10.0 / 75.0 / 130.0 |
| `loot_quality` | thievery | 5.0 / 45.0 / 75.0 |
| `luck_modifier` | comedy | 5.0 / 25.0 / 50.0 |
| `magic_damage_resistance` | yoga | 5.0 / 50.0 / 75.0 |
| `max_companions` | leadership | 1.0 / 5.0 / 5.0 |
| `mental_resistance` | yoga | 5.0 / 75.0 / 125.0 |
| `morale_effects` | leadership / performance | 5.0 / 50.0 / 100.0 |
| `movement_speed` | grace | 10.0 / 40.0 / 65.0 |
| `party_skill_checks` | learning | 1.0 / 5.0 / 10.0 |
| `party_xp_gain` | learning | 3.0 / 15.0 / 42.0 |
| `poison/disease_resistance_(party)` | medicine | 10.0 / 50.0 / 75.0 |
| `repair_efficiency` | smithing | 10.0 / 60.0 / 85.0 |
| `sell_markup` | trade | 5.0 / 45.0 / 70.0 |
| `social_roll_success` | performance | 5.0 / 50.0 / 75.0 |
| `status_effect_chance` | ritual | 5.0 / 50.0 / 75.0 |
| `summon_hp` | summoning | 10.0 / 60.0 / 85.0 |
| `supply_duration_(party)` | logistics | 10.0 / 60.0 / 85.0 |
| `trading_price` | persuasion | 5.0 / 25.0 / 50.0 |
| `trap_detection` | thievery | 10.0 / 60.0 / 85.0 |
| `travel_speed_(party)` | logistics | 5.0 / 35.0 / 60.0 |

Each needs a target system and a balance decision, which is why this is not a
mechanical fix:

- **Shops** (`buy_discount`, `sell_markup`, `trading_price`) — fold into
  `ShopSystem.get_price_modifier_summary()`. Trade 10 currently reads 60% off /
  70% markup, which may be intended as a soft cap rather than literal.
- **Overworld** (`travel_speed_(party)`, `supply_duration_(party)`) — party
  speed and per-step food cost in `overworld.gd`.
- **Loot** (`loot_quality`) — `CombatManager._get_modified_rarity_weights()`
  already takes Luck; add the Thievery term.
- **XP / checks** (`party_xp_gain`, `party_skill_checks`) —
  `CompanionSystem.apply_party_xp()` and `EventManager._resolve_roll_dc()`.
- **Combat** (`summon_hp`, `burning_damage`, `status_effect_chance`,
  `effect_duration`, `mental_resistance`, `magic_damage_resistance`) — summon
  spawn, DoT tick, status apply chance, status duration, resistance lookup.
- **Camp / crafting** (`crafting_quality`, `crafting_yield`,
  `repair_efficiency`, `consumable_power`) — the camp activity handlers.
- **Party** (`max_companions`) — no party-size cap exists yet.
- **Social** (`charm_effectiveness`, `social_roll_success`, `morale_effects`,
  `luck_modifier`) — event roll resolution.
- **Medicine, party-wide** (`healing_effectiveness_(party)`,
  `poison/disease_resistance_(party)`) — rest healing and wound escalation.

Cheapest and most visible first: shops, overworld, loot.

Two keys also use display-style names (`healing_effectiveness_(party)`,
`poison/disease_resistance_(party)`) that should become plain snake_case when
they are wired.

---

# Part IV — What got done

Condensed changelog. Full checklists in git at `73a948c`.

## 2026-07-27 — post-break audit and follow-up passes

**Audit and bug fixes.** Animal and domain enemy files were never loaded;
combat realm was always "hell"; event `difficulty` was dead data; `item_random`
rewards gave nothing across 49 outcomes; all 47 companions had lost their trait
lists in a merge; the deleted QuirkSystem was still referenced (so quirk crisis
reactions never ran); boss gating was fiction (`requires_boss_defeated` never
checked, `defeat_boss()` never called); the HG realm boss event didn't exist
though the map referenced it; ~130 broken data references. Roll choices can now
carry skill/attribute gates ("gated gamble").

**UI debt and half-wired mechanics.** WOUNDS & BODY and STATE OF MIND panels in
the character sheet; `cone_forward` locked to caster facing with a cone
silhouette preview; per-arm chain results in the combat log; paid wound healing
at 12 shops; Riposte, Reflect, Magic_Mirror, Mirror_Images, Taunt, Karmic_Bond,
Eternal_Vow, Mantric_Armor, Ancestors_Blessing, Swarmed, Lured and Constitution
statuses wired; four AI behaviour types (`erratic_movement`, `priority_target`,
`pack_bonus`, `burrow_emerge`); summoning terrain affinity; Coordinated Strikes;
Cloud Gate; Set Snares and Craft Charm camp activities; location-specific camp
suppression and enhancement. Two entries turned out **stale, not missing** —
elemental terrain spellpower modifiers and Yoga-boosted rest decay were already
implemented.

**Animal realm content.** All 47 missing zone events written (the map referenced
84 markers and only 37 existed). Hungry ghost's 34 map-placed gaps written too.
All three content realms now at 0% dead map weight. 24 animal companions added
covering all 17 animal births; every companion gained a `realm` field. Found
along the way: animal shops offered the hell devil roster verbatim; 4
backgrounds granted a nonexistent `crafting` skill; 8 background starting items
used pre-rename ids, so several animal backgrounds started you with no weapon.

**Quests, recruitment, prosthetics.** All three quests were unfinishable — the
board handed them out and no event ever set their step flags. Six hell events
written to close the chains. 9 bespoke HG recruitment events. 12 prosthetics
plus the two missing code links (nothing wrote `body_plan.prosthetics`, and the
penalty maths ignored it).

**Perks.** Two dead trees fixed (18 perks keyed to a nonexistent `crafting`
skill; akimbo/coordinated_strikes keyed to a nonexistent skill, now
attribute-gated). 28 level-10 capstones added. 94 perks redistributed off the
old odd-only tiers plus 9 new, giving every skill a perk at every level 1–10.
PERKS.md synced: 81 `Requires` lines rewritten, 47 undocumented perks recorded.

**Gold rewards.** 30 outcomes promised gold and paid none — 24 used descriptive
tokens against a handler doing `int()` (0 in GDScript for a non-numeric string),
6 used a `gold_reward` key nothing read, including every Bone Arena payout.
Fixed with `_resolve_gold_reward()` and a rename to the canonical `gold`.

**Validator** (`tools/validate_data.py`) now covers: events → encounters, shops,
items, spells, traits, skills, wounds, karma realms; map configs → events, mobs,
pickups; shops → items, spells, companions; companions → births, backgrounds,
items, spells, traits; races and backgrounds → skills, traits, equipment;
encounters → archetypes; code → perk ids and status names; quest step flags must
be settable by some event; choice `prerequisite` flags must be reachable; reward
keys must have a handler; gold tokens must resolve. An earlier ad-hoc version
had a blind spot that hid **every** map→event reference in the game
(`object_pools[zone]` is a dict keyed `events`/`pickups`, not a list) — if you
write a checker, check its negatives.

## Earlier work (2026-04 → 2026-05)

- **Psychology system** Layers 1–2: five elemental pressure meters, status
  thresholds, autonomous crisis events, trait crisis reactions, rest decay,
  character-sheet panel
- **Trait system**: 63 traits replacing the old QuirkSystem, applied as
  attribute/skill/pressure modifiers
- **Indo-Tibetan weapons and armour overhaul**: sword types (Khanda, Talwar,
  Dao, Patisa), mace/bow renames, Katar, Bichawa, Kukri, Trishula, Urumi,
  Chakram, Chuba, Lamellar, monastic robes — with the mechanics wired
  (`on_crit_status`, `parry_effectiveness`, `pass_through`, Urumi sweep)
- **Ritual implements**: 210 items (6 implements × 8 materials × 5 consecration
  tiers) generated by `tools/generate_implements.py`, with Rhythm Charge, Chöd
  Offering, Throw Phurba, khatvanga initiative aura and the dorje+drilbu set
  bonus; ritual garb generated the same way
- **Rest and time**: hours-based clock, three rest tiers, food only at rest,
  temp HP, 28-day lunar calendar with full/new moon and per-weekday school
  bonuses
- **Camp system**: two-stage rest (tier → activities), CampSystem autoload, ~20
  activities, disturbance rolls, safe camps, 9 camp events
- **Wounds and diseases**: WoundSystem with 5 base types + 5 escalated forms,
  escalation on untreated rests, Field Surgery, combat and event application,
  stat penalties
- **Body plans**: BodySystem with dynamic per-species topology, limb loss with
  cascade and unequip, natural weapons (locked and unlocked), multi-arm attack
  chain governed by Finesse, extra leg pairs, prosthetics
- **Combat**: AoEResolver as the single source of truth for 10 AoE shapes,
  projectile deviation and friendly fire, spell duration unification, obstacle
  variety, terrain effects, AI using items and active skills, enemy physical
  resistances
- **Items**: procedural weapons/armor/talismans, equipment traits, 40
  magic-school charms, 17 scrolls, alchemy crafting with a UI tab
- **Save/load**: 3 slots plus autosave

## Confirmed complete (previously suspected missing)

- Psychology Layer 3 crisis/valve mechanic — implemented in
  `psychology_system.gd` (the *intervention* mechanic is the open part)
- Wound/disease application on crits — wired in `combat_manager.gd`
- Background system — all fields applied; no `abilities` field exists in data
- Spell outcomes — all 6 types handled; every reward key has a handler
- Summoning school — mechanically complete
- `race` → `birth` rename in scene nodes — already done; no `race_label` /
  `RaceValue` references remain
- Red/yellow devil racial bonuses (`better_starting_weapon`,
  `extra_starting_gold`) — now real traits granted at creation and read by
  `character_system.gd`
- Legendary equipment tier — 68 legendary-rarity items exist
- Out-of-combat spellcasting — the spellbook Cast button already existed;
  `cloud_gate` was added on top of it
