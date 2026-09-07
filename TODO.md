# Six Worlds — TODO

**Last updated:** 2026-08-31

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

| Realm | Map | Births | Archetypes | Events | Companions | Quests | Dead map weight |
|---|---|---|---|---|---|---|---|
| **Hell** | ✓ cold / fire + divider | 13 | 45 | 79 | 24 | 3 | 0% |
| **Hungry Ghost** | ✓ 3 zones | 16 | 23 | 150 | 23 | 0 | 0% |
| **Animal** | ✓ ocean / forest / meadow | 18 | 34 | 94 | 28 | 0 | 0% |
| Human | ✗ | 4 | ✗ | ✗ | ✗ | ✗ | — |
| Asura | ✗ | 2 | ✗ | ✗ | ✗ | ✗ | — |
| God | ✗ | 3 | ✗ | ✗ | ✗ | ✗ | — |

Plus 33 cross-realm domain events (13 plain, 9 camp-triggered, 8 trait-triggered,
3 relationship-triggered). **356 events total**.

Other totals: **600 perks** (546 skill + 54 cross, every skill covered at every
level 1–10), **363 spells**, **565 items**, **103 traits** (84 gameplay + 19
racial), **12 prosthetics**.

### Systems

Twenty-one autoloads, all wired: characters/XP, karma/reincarnation, events, grid
combat (spells, AoE via `AoEResolver`, statuses, AI, projectiles), overworld
(real-time movement, mobs, portals with boss gating), shops/training/guilds,
procedural items, perks, psychology/pressure, traits, wounds, body plans
(multi-arm species, limb loss, prosthetics), party relationships,
camp/rest/time/lunar calendar, save/load (3 slots), audio, cheat console.
Engine: **Godot 4.6**.

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

- [x] ~~**`trait` / `not_trait` event requirements**~~ — done in the four-part
  sweep: **201 trait-gated choices** using 77 of the 84 gameplay traits, and
  **76 `add_trait` / `remove_trait` outcomes** covering 30, across 152 of the
  356 events. The five traits with no event presence (`bloodied`,
  `death_touched`, `long_marched`, `maimed`, `mantra_worn`) are the ones code
  hooks grant, which is deliberate — those are earned by playing, not chosen.
  **All of this prose is Claude's and wants a pass.**
- [ ] **Second pass on the sweep, if wanted** — 204 events still carry no trait
  gate. Many genuinely do not want one; a gate on every event would make traits
  read as a checklist. Worth revisiting once the first batch has been played.
- [ ] **Companions have no behavioural traits** — 25 of 31 are on no companion,
  so a behavioural gate currently fires only when the *player* rolled it
  (~3% per trait). Creation now rolls one, which makes them reachable, but
  seeding companions would make the party feel much more distinct. Deliberately
  left to Olaf, since it is companion characterisation.
- [ ] **`wound` and `sever_part` event rewards** are still unused by any event —
  nothing in the game maims you outside combat.
- [ ] **Cursed items** — "cursed" is a status and a terrain type; zero cursed
  equipment exists, though the item type is registered.
- [ ] **`mantra_count`** now feeds the practice traits, but the deeper consumer
  is still YidamSystem — see Part II.
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
- [ ] **6 embedded `todo` keys in the data files** promise mechanics no code
  reads. Nothing in TODO.md ever tracked them:
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
- [ ] **53 events are grey-only** (of 347 with choices) — no blue or yellow
  option at all. The stated target is ≥2 meaningful checks per event. The trait
  sweep reduced this from 63 by giving some of them their first gated choice.
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

### 2026-08-31 — from the enemy-XP design session

- **Map all five elements to the buddha families, and finish what each implies.**
  The original intent, watered down over time. Fire is padmakula — desire
  transmuted, magnetising — and its line is half-built already. The other four
  presumably map to vajra, ratna, karma and buddha, and the same audit would
  likely find each has a partial line nobody labelled. Worth doing all five
  together during the spells pass rather than fire alone, so the elements end
  up meaning something consistent rather than five unrelated damage types.
  Elemental affinities, klesha/wisdom pressure and the ngakpa robes all already
  key off the elements, so a coherent family scheme would tie several systems
  together at once.

- **Fire's padmakula line has holes at levels 1 and 5.** Fire is the lotus
  family — desire transmuted, magnetising rather than burning — and the ladder
  is already there in `Fire + Enchantment`: `charm` (L3), `magnetizing_aura`
  (L7), `dominate` (L9), with `berserk` and `shining_mirage` alongside at L7.
  But Fire has eight spells at L1 and twelve at L5 and not one of them is
  mental, so the line starts at 3, jumps to 7, and a character specialising
  into seduction and domination has nothing to learn across most of the
  mid-game. Wants an L1 and an L5 when the spells are refreshed. The Sensate
  background and the rakshasa's fire affinity of 5 both point at this line.

- **The naming lore is barely used by anything.** `animal_realm_names.json` is
  read by no script and referenced by almost no content: 389 personal names with
  meanings, plus per-birth place names that exist only in the file. *(First dent
  made 2026-09-07: the four new vanara companions — Kapisha, Chanchal, Kelika,
  Laghima — are named from the vanara list in that file, with their recorded
  meanings driving the characterisation. Same trick works for every other
  birth's roster.)* The rakshasa
  set alone has **The Long Hunger** (a stretch of poor territory between
  productive ones), **The Wrong Side** (anywhere they do not go, and there is
  always a reason), **The Ridge Where They Wait**, **The Mango Kill**, **The
  Scratch Tree**, **The Three-Day Territory**. Every birth has six or so like
  these. Fold them into the events pass — an event set on The Wrong Side is
  already half-written by its own name.

- **Mriga have no events at all.** Four events mention gana; none mention mriga,
  so the forest has wolves in its prose and no deer. Two existing ones read as
  either and could simply be switched — `animal_forest_healer_camp` (a
  grey-muzzled healer, and medicine is the mriga trade) and
  `animal_forest_town_weapons` (traders). Beyond that, sketches for
  mriga-specific events, to fold into the general events pass:
  - **The Alarm Tree** — the herd's warning goes up before you can see why.
    Rewards Awareness; `first_to_know` should read it differently.
  - **The antler contest** — two bucks holding a clearing you need to cross,
    settling it by display. A fight you are allowed to decline, which is the
    most mriga thing available.
  - **The old trail** — a migration crossing your route, a `songline_guide`
    carrying the song that is the only map of it.

- **Parties should not all be hostile by default.** Traders are already neutral;
  a grazing mriga herd or a kapota flock should be too — `animal_kapota_flock`
  already says "usually neutral" in a comment nothing reads. Wanted without
  introducing factions or reputation: something stateless and per-encounter
  that decides whether contact opens combat or opens a conversation, so trade,
  contact and quests have somewhere to attach later. See the design note below.

- **Non-combat equipment kits as a broad concept.** The basis now exists: 40
  skill tools across eight skills, five tiers each, carried in the weapon hand
  the way a ritual focus is. Ritual clothing already exists too — the ngakpa
  robes, five tiers across five elements — but only serves magic.

  The obvious extension is craft clothing in the `chest` slot, so a
  practitioner could carry a tool *and* wear their trade: a physician's apron,
  a performer's coat, a smith's leathers. Roughly 40 more items.

  **Not to be done quickly.** The open question is what the bonuses should
  actually do. A flat +N to a skill is fine for one item, but a full kit —
  tool plus clothing plus accessory — stacks into a large number, and it is not
  obvious that a non-combat character should get a bigger total than a combat
  one gets from weapon plus armour. Wants a deliberate pass over how
  non-combat bonuses scale and interact before adding more of them.

- **Six encounters have role slots no archetype can fill.** They drop to a
  generic fallback. `tools/verify_enemy_xp.tscn` lists them on every run:

  | encounter | region / tier / role |
  |---|---|
  | `swamp_vermin` | fetid_swamps / shade / support |
  | `animal_yaksha_patrol` | meadow / devil / support |
  | `animal_dura_soldiers` | meadow / devil / skirmisher |
  | `animal_khadga_lone` | meadow / imp / frontline |
  | `animal_shyena_lord` | meadow / imp / frontline |
  | `animal_uluka_watch` | forest / devil / caster |

- **Equipment should be generated like the XP pool.** Currently
  `_generate_equipment` reads only `archetype.equipment_template.weapon.type`,
  so what a character can actually do has no bearing on what it carries.
  Wanted:
  - a **total equipment value that scales with the character's XP**, the same
    proportional way the XP budget itself does
  - **types chosen from the dominant skillsets** — a ranged build carries a bow,
    a Performance build carries an instrument, an armour build wears armour
  - **two weapon sets** where the gold and the skills make it reasonable
  - beyond the vital kit, **food and other resources**, and later everyday
    objects carrying minor bonuses — the point being roundness, the same reason
    XP now overflows into breadth. A character with rations, a spare knife and
    a lucky stone reads as someone who lives somewhere.

- **Instruments, and skill-linked equipment generally.** The game has ritual
  implements (damaru, kangling, conch, drilbu) but all are `type: focus` for
  Ritual and spellcasting. There is nothing a Performance character can hold.
  Other skills likely want their own objects too — Alchemy, Medicine, Smithing,
  Trade all imply tools that do not exist yet.

- [x] ~~**`tier` did three jobs at once.**~~ — replaced 2026-09-07 by `rank`.
  An archetype's `rank` (1–4) is only what the creature is; an encounter's
  `rank_range` is the pool it draws from; its strength is the multiplier for the
  top of that range, or an explicit `strength` override — so "a weak band of
  strong creatures" is now expressible, which one tier field could not do. Boss
  is a role, not a rank. `party_composition.json` used `tiers` for a third,
  unrelated thing (share structure) and now says `slots`.

  **28 role slots across 22 encounters could not field their own family; now 0,
  and no role slot anywhere is unfillable.** Ranges were widened by derivation,
  not guesswork — an encounter's range is its old tier extended to cover its own
  family's ranks. Three more classes of bug fell out of the audit:
  - **`sky` was not a map zone.** The animal map is ocean / coastal_wall /
    forest / ridge / meadow and no encounter used `sky`, so all six flying
    archetypes were unreachable by role matching and three of them — the whole
    kapota and uluka rosters — could never appear at all. They are `any` now,
    which is what the picker already means by "does not care".
  - **`swamp` was not a region either.** Two hungry ghost archetypes used it;
    the zone and every encounter say `fetid_swamps`.
  - **`animal_shyena_lord` was tier `imp`.** An encounter named for a rank-4
    lord drew from rank 1, so it fielded no shyena. Now `[4, 4]`, which also
    quadruples its XP budget — worth a look in play.

- [ ] **`hell_sloth_imp` is unreachable.** Rank 1, role support, region any, and
  no hell encounter asks for rank-1 support. It is the only archetype in the
  game no encounter can produce. Wants an encounter, not a code change.

- **Birth and archetype can contradict each other.** Enemy births are rolled
  from the realm independently of the archetype, so 33 hell encounters produce
  things like `hell_green_devil_sniper` with a `blue_devil` birth. Either
  constrain the roll when an archetype id names a birth, or decide devils are
  mixed-parentage and let it stand. The seven `hell_*_imp` archetypes
  now have matching births (`flame_imp`, `frost_imp`, `gravel_imp`,
  `static_imp`, `tinnitus_imp`, `sloth_imp`), so if the roll ever is
  constrained, hell's imp encounters are the easiest case to wire first —
  `hell_ash_imp` is the only one without a birth, deliberately.

- **The new hell and hungry ghost births have no companions.** Hell has 24
  companions across the six devils and none on the six imps or the wretch;
  hungry ghost has none on `chidrib` or `zadrib`. Same hole the animal realm had
  before its companion pass. An imp companion is an obvious character — small,
  overlooked, carries messages, knows everybody's business — and the wretch is
  the one birth where a companion could be recruited out of pity rather than
  paid for, which nothing in the game currently does.

- **The five elemental skeletons are colour-coded with no elemental affinity.**
  `skeleton_copper` is explicitly "attuned to the arts of power and magnetism"
  and has `elemental_affinity_bonuses: {}`, as do silver, golden, iron and
  turquoise. Every other differentiated birth in the game carries 3–5 points of
  innate affinity. Left alone in the balance pass because it changes the power
  of five existing births rather than adding new ones, but the mapping writes
  itself — iron/earth, copper/fire, turquoise/air or water, and it would tie
  them into the klesha and ngakpa systems that key off elements.

- **`typical_backgrounds` is not read by the game.**
  `KarmaSystem.select_random_background()` rolls over every background whose
  `available_races` admits the birth, weighted by `weight`; the birth's own
  `typical_backgrounds` list has no effect on it. The field is real
  documentation — it is what the review documents print under each birth — but
  anything written on the assumption that it narrows the roll is wrong. Three
  entries in it had rotted to backgrounds that no longer existed (`beggar` on
  yidag, `sorcerer` and `courtier` on skeleton_copper) precisely because nothing
  read them; `validate_data.py` checks the field now. Either wire it into the
  roll as a weight multiplier or rename it to say what it is.

- **Instruments as performance items.** The game has ritual implements —
  damaru, kangling, conch, drilbu, phurba — but all are `type: focus`, for
  Ritual and spellcasting. There is no lute, flute, drum or fiddle a
  Performance character could carry. Once XP breadth gives enemies and
  companions skills outside their build, a bard-adjacent character has nothing
  to hold. Wants its own item type and a few tiers.

- **Equipment should follow the character, not just the archetype.**
  `_generate_equipment` reads only `archetype.equipment_template.weapon.type`,
  so a generated character with ranged 8 and performance 7 still carries
  whatever its archetype hardcodes. With XP breadth now giving characters real
  skills off their build, gear should be chosen from what they can actually
  use — top weapon skill picks the weapon, and a high Performance or Ritual
  should put an instrument or implement in their hands.

- [x] ~~**Background assignment wants a pass across all births.**~~ — done
  2026-09-07 for hell and hungry ghost, which were the two starved realms.
  137 backgrounds now, 32 universal. Only 4 births have no background naming
  them specifically (down from 28) and all four are in unbuilt realms.
  `docs/BACKGROUNDS_BY_BIRTH.md` is generated from `races.json` now
  (`tools/export_backgrounds_by_birth.py`) rather than hand-maintained, so the
  numbers in it cannot drift again.

  The measure that matters is the **share of a birth's background roll that is
  realm-flavoured, by weight** — the roll is weighted, so counting entries
  overstates it. Hell was 7.9–12.8% before the pass and is 18–32% now; hungry
  ghost's eight worst births were at a flat **0%** and are 8.9–15.5%; animal
  runs 5.7–21.9%. Two stragglers are left and are pre-existing:
  **`dralha` at 3.0%** and **`gyelpo` at 5.7%**, plus `uluka` 5.7% and
  `patanga` 6.8% in the animal realm.

- [x] ~~**Backgrounds duplicate each other mechanically.**~~ — done 2026-09-07.
  19 flavoured backgrounds differentiated; **0 identical clusters** remain (was
  11, 8 of them colliding) and no background is strictly dominated. Birth-slots
  where a character could roll two backgrounds doing the same thing: **53 → 5**.
  No universal background was touched — they are 84% of every roll. Nine
  same-skill clusters remain and are all level-swaps (one headlines the skill,
  the other carries it as a minor), which reads as two takes on a trade;
  `bone_dancer`/`musician` is deliberately among them, because Olaf wants
  `comedy 2` on the bone dancer for the cham-dance jesters.

- [x] ~~**The skill spread is lopsided.**~~ — done 2026-09-07, in a second pass
  over the **universal** backgrounds, which are 84% of every roll and therefore
  the only pool that can move the bottom of the table. Nine swaps, each keeping
  the background's skill-point budget and taking its justification from its own
  description: `warrior` → `swords 2, armor 1`, `farmer` → `axes 2`,
  `guard` → `spears 2, armor 1`, `temple_warden` → `martial_arts 2`,
  `spy` → `daggers 2`, `noble` → `leadership 2`, `herbalist` → `earth_magic 2`,
  `wanderer` → `learning 1, comedy 1`, and `former_soldier` (restricted) to
  spears so it does not become a weaker `guard`.

  **Skills under half the mean: 5 → 0. Spread heaviest-to-lightest: 6.7× → 3.9×.
  `swords` went from a skill no background in the game was about to 1.20× on the
  heaviest background there is.** `might` — level-1 filler on five universal
  backgrounds and headlining none — dropped 2.28× → 1.23×.

  The pattern that made the swaps obvious: the universal pool already held
  **exactly one background per magic school** (apprentice/sorcery,
  storm_watcher/air, firekeeper/fire, water_carrier/water, psychic/space,
  grave_tender/black, healer/white, conjurers_hand/summoning,
  charm_seller/enchantment) and earth was the only one missing. `herbalist` was
  already describing earth magic in its prose while teaching medicine.

- [x] ~~**`armor` needs a universal background of its own.**~~ — done: Olaf's
  **Shieldbearer** (`shieldbearer`, universal, weight 5, `armor 2` +
  `earth_magic 1`). No new duplicate clusters, and `earth_magic` rose 0.62× →
  0.90× as a side effect, which is the good kind.

  It does put `armor` back to **1.93× the mean**, second only to `learning` —
  the skill now appears at level 1 on `warrior`, `guard` and `former_soldier`
  as well as headlining Shieldbearer. That is the deliberate cost of giving
  armor a home; if it grates, the cheapest correction is dropping `armor 1`
  from `warrior`, which would leave it a pure swordsman.

- [ ] **`learning` is the last outlier at 2.26× the mean.** Everything else now
  sits between 0.58× and 1.46×. It headlines `scholar` and appears as a level-1
  minor on 13 more backgrounds — the same filler pattern `might` had before this
  pass, and fixable the same way if it ever grates.

- **Skill-spread notes, kept for the record.**
  Found by `tools/audit_backgrounds.py` (rerun it after any background edit —
  it prints a report and never writes).

  **Duplication (fixed above, kept for the record).** 11 clusters shared
  identical `starting_skills` at identical levels and 19 shared the same skills
  at any levels. Most were harmless — a universal background and a realm re-skin
  of it that no single birth can roll both of. Four collided in a real pool:

  | cluster | births that can roll more than one |
  |---|---|
  | `smith` / `bellows_hand` / `ore_grafted` — all `smithing 2, might 1` | **16** |
  | `grave_tender` / `bone_setter` — black_magic + medicine, levels swapped | **13** |
  | `thief` / `forest_thief` / `runaway` — guile + thievery | **8** |
  | `guard` / `coral_guard` — both `armor 2, spears 1` | 4 |

  `bellows_hand` and `bone_setter` came from the 2026-09-07 births pass and were
  written without checking what the universal pool already taught. All four are
  now differentiated, and the one strictly dominated pair (`thief` over
  `forest_thief`) is gone.

  **`swords` is a dead skill at character creation.** No background grants it
  above level 1 and no birth grants it at all. The only common route to it is
  `warrior` — the heaviest background in the game at weight 10 — which gives
  `swords 1, armor 1, might 1`. Space's weapon skill, and nobody can start as a
  swordsman. Compare `quarrier` (maces 2), `hunter` (ranged 2), `brawler`
  (unarmed 2), `guard` (armor 2): the other weapon skills all have a headline
  background. A universal duellist/soldier background at `swords 2` is the
  obvious fix.

  **The universal pool is 84% of the average roll** (32 backgrounds, range
  68–94% across births), so what it cannot teach is effectively unreachable.
  Five of the nine combat skills have no universal background that is *about*
  them — `swords`, `axes`, `daggers`, `spears`, `martial_arts` — and the
  restricted ones that do are reachable by 0, 8, 3, 14 and 2 births
  respectively. `earth_magic` is the same story: nine backgrounds use it as a
  garnish, one (`old_tusk`, reachable by a single birth) is about it.

  **Expected starting points per skill**, over every playable birth and its own
  weighted roll — mean 0.084, and a character starts with 2.9 background skill
  points total:

  - **Heavy (1.8–2.4× mean):** `might`, `learning`, `armor`, `medicine`,
    `persuasion`. `might`, `guile`, `logistics` and `learning` appear as a
    *minor* skill in 17–19 backgrounds each — they are the filler that gets
    sprinkled on everything.
  - **Thin (under half the mean):** `daggers` 0.34×, `comedy` 0.36×,
    `martial_arts` 0.36×, `earth_magic` 0.37×, `leadership` 0.46×.
  - Spread from heaviest to lightest is **6.9×**.
  - By category, **general skills get roughly twice the magic and combat
    skills** per skill (0.108 vs 0.056 and 0.071).
  - By element the spread is small — 0.544 (water) to 0.630 (air) — so the
    affinity system is not skewed. That part is fine.

  **Half the animal-realm backgrounds have no attribute modifiers** (33 of 66),
  against 0% in hell, hungry ghost and cross-realm and 3% universal (only
  `herbalist`). Those 33 give strictly less than their peers for no stated
  reason; it looks like an oversight in the animal pass rather than a decision.

- **Spell learning should cost XP.** `CharacterSystem.learn_spell` currently has
  no cost and no eligibility gate at all; it appends to `known_spells`. Making
  spells cost XP is the coherent counterpart to buying perks, and it spreads XP
  across more kinds of development instead of dumping it into raw attributes
  once a build's skills cap.

- **Trainers / domain-guild-style access.** Perks and spells stay discoverable
  by default — not seeing everything in one run is the intent. But some can be
  bought: access is earned through events, the way domain guilds already work,
  then purchased in a shop menu for XP plus sometimes another resource. Cost
  rises **geometrically** per purchase (n, 2n, 4n …) so a player buys two or
  three a run and agonises, rather than working through a shopping list. Worth
  its own spec; it interacts with the XP economy.

Spec: `docs/superpowers/specs/2026-08-31-enemy-xp-generation-design.md`

- **More ways to spend XP on meaningful development.** *(decided 2026-08-31:
  the 10-level skill system stays — too much is pegged on it — but perks and
  spells should become purchasable with XP.)*

  XP currently buys two things: attributes and skills. Skills hard-cap at level
  10, so a three-skill build absorbs at most 1,980 XP in skills and everything
  past that becomes raw attributes, which never saturate but are the least
  interesting kind of power.

  The two obvious sinks already exist as content and are not sold:
  - **604 perks** (550 skill + 54 cross) are acquired *free*, one choice of four
    offered per skill-up. With skills capped, a character sees at most ~350
    offers of a random 4-of-604 — most perks are never even seen, let alone taken.
  - **363 spells** — `CharacterSystem.learn_spell` has no XP cost and no
    eligibility gate at all; it appends. Access comes from guilds, events and
    starting kits.

  An earlier note here claimed an individual saturates near 4,500 XP. That was
  wrong: it assumed `attribute_caps` bounded attributes near 30, and those caps
  are enforced nowhere (see below). Only the skill cap is real.

- **`attribute_caps` is dead data** — all 47 races carry a 7-key caps dict that
  no script, scene or tool reads. Attributes are limited only by the rising cost
  per point, which is the soft cap the design wants anyway. Either delete the
  field or implement it; leaving it is actively misleading, having already
  produced one wrong conclusion in the enemy-XP spec.
- **Loot division** — post-battle XP now divides among party members; items do
  not, because they are indivisible and the party shares an inventory. Left
  deliberately asymmetric; revisit if party size feels wrong.
- **A visual tell for high-band encounters** — party archetypes let `swarm`
  (5–8 members) and `lone_hunter` (1) occur at the same XP budget, so the
  player can no longer read danger off the number of enemies on screen. Some
  other signal may be wanted.
- **Gana attribute caps** — set by hand during the predator/herbivore split to
  match the new daggers-and-unarmed lean; never reviewed against play.

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

## Trait matrix — reference for the events pass

`psychology_system.gd` defines 30 named states, five elements × two poles ×
three tiers. This is the canonical five-poison/five-wisdom scheme and every
trait is now seated on it.

| Element | Klesha: minor / major / crisis | Wisdom: minor / major / crisis |
|---|---|---|
| **Space** (delusion) | Confused / Dissociated / Absent | Clear-headed / Open / Luminous |
| **Fire** (desire) | Restless / Craving / Consumed | Warm / Magnetizing / Radiant |
| **Water** (aversion) | Irritable / Grief-struck / Poisonous | Focused / Clear-eyed / Compassionate |
| **Earth** (pride) | Insecure / Arrogant / Humiliated | Grounded / Equanimous / Unshakeable |
| **Air** (envy) | Anxious / Paranoid / Envious | Alert / Inspired / Brilliant |

Trait coverage after the 2026-07-27 pass — 48 of 56 gameplay traits carry a
pressure link (the eight without are plain bodily facts: `strong`, `quick`,
`frail`, `clubfooted`, `hard_of_hearing`, `iron_stomach`, `night_owl`,
`bird_lover`):

| | klesha | wisdom |
|---|---|---|
| space | 6 | 6 |
| fire | 6 | 6 |
| water | 8 | 6 |
| earth | 10 | 4 |
| air | 6 | 5 |

**Sign convention:** negative pushes the baseline toward klesha, positive toward
wisdom, matching `apply_pressure()`. Trait and race data used to be written the
other way round — see Part IV.

**When placing trait gates in events**, the useful question is which of the five
families the situation touches, then whether the trait makes the character
better or worse at it. A `not_trait` gate is as useful as a `trait` gate:
`incurious` should close doors that `curious` opens.

### Bonding vocabulary

`bond_tags` on each trait is what `RelationshipSystem` scores party rapport on:
**vice, devotion, martial, arts, scholarly, sociable, solitary, grief, order,
beasts, hardship, wonder**. Shared tags pull a pair together (vices pull
harder), `opposed_traits` push apart, and the pairs are symmetric — the
validator would catch it if they were not. Bands: rival / cool / neutral /
warm / sworn.

The trait baseline is recomputed on every read rather than stored, so editing
traits.json can never leave a stale number in a save; only the drift from
things that actually happened is persisted.

### Traits as the home for standing effects

Settled 2026-07-27. The line between the three systems:

- **Traits** — permanent or run-long, identity-shaped, visible outside combat:
  traversal, resistances, social access, what events offer you.
- **Statuses** — turn-scoped combat state, with duration, stacking and dispel.
  Unchanged; `Burning` is not a trait, but a character who *cannot burn* is.
- **Perks** — remain the purchase. A perk whose effect is a standing condition
  declares `"grants_traits": ["<id>"]` rather than restating it in code, and
  the trait then carries the stat, skill, resistance and event-gating
  consequences. Only for unconditional effects: Diamond Body's poison immunity
  applies *while unarmored*, which a trait cannot express, so that stays a
  combat check.

Trait `resistances` are wired: `TraitSystem.get_resistances()` folds into
`derived.resistances` beside racial and equipment values, so `CombatUnit`
reads them with no combat-side change. Because disease is not a damage type
but an affliction chance, `WoundSystem._resisted()` also rolls the same value
against catching one — venom_ward both blunts poison damage and halves the
chance of catching something from a poisoned blade.

Still open for the temporary-trait idea: traits have no expiry. A
`duration_rests` field ticked in `overworld._tick_rest_traits()` — the hook
that already turns `grief_struck` into `mourner` — is the small piece that
would let a spell or event grant `flying` for a while.

## Trait acquisition

Nine acquired traits are granted by code hooks, with no event needed:

| Trait | Hook |
|---|---|
| `scarred` | a severe wound is cured |
| `maimed` | a limb is severed (dropped again when the last part regrows) |
| `death_touched` | survived an otherwise-fatal blow (Ancestors_Blessing, Eternal_Vow) |
| `steady_practice` / `mantra_worn` | `mantra_count` reaches 40 / 250 |
| `ash_marked` | 12 sadhanas performed |
| `bloodied` | the party kills something with the boss role |
| `sole_survivor` | last one standing after two others fall |
| `long_marched` | 30 rests taken |

Losses: `addiction` is broken by a facility with Medicine 5+, `grief_struck`
settles into `mourner` after 25 rests, `maimed` goes when the body is whole.
All thresholds are first-pass.

### Self-generating events

Events with `"trigger": "trait"` + `"requires_trait"`, or
`"trigger": "relationship"` + `"requires_band"`, are rolled on a rest night
that nothing else claimed — 12% and 8% respectively. `{a}` and `{b}` in title,
text, choice text and outcome text are substituted with the real names.
Eight trait events and three relationship events exist; more are welcome, and
the mechanism is the cheap part.

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

**Trait matrix pass.** Every trait and race pressure link was re-seated on the
psychology matrix, correcting two things at once. **Sign:** the code runs −100
klesha to +100 wisdom and four call sites follow it, but traits.json and
races.json were authored as "positive = more of this affliction", so the
baseline decay pulls toward pointed at the wrong pole — `grief_struck` carried
water +20 while "Grief-struck" is itself the water dark major label, and
`brave` decayed toward fear. **Element:** anger was filed on fire (fire is
craving; aversion is water) and paranoia on space ("Paranoid" is the air major
dark label). 36 traits re-seated by hand rather than sign-flipped, since
`oath_breaker` and `addiction`'s earth term were already right; 3 races
rebased; 12 traits added to fill the thin cells; 15 traits that had no
psychology link at all gained an obvious one. The crisis-reaction table
followed: four entries moved to the element their trait now sits on, and the
12 new traits brought the bright pole from 2 authored reactions to 12.

**Events x traits sweep.** Four parts, one per realm plus a pass for the plain
traits the first three skipped: 201 trait-gated choices over 77 of the 84
gameplay traits, 76 acquisitions over 30, across 152 events. Physical
hindrances are used as hindrances — clubfooted goes down on the frozen cave
ice, hard_of_hearing catches one word in four in the demon marketplace — since
that is the only way those traits can be felt.

**Trait gate balance.** The sweep was written for flavour and not costed:
gates paid a median 25 XP against 12 elsewhere while costing nothing to
unlock, and 124 of 201 outpaid every other choice in their own event. Rescaled
by how often a party holds the trait (8/12/15/20), with a premium for risk and
a dominance cap for common traits only. Dominance on commonly-held traits is
now 4 of 25, and gates contribute ~3.8% of all event XP. `tools/rebalance_trait_gates.py`
re-runs the whole analysis.

**Behavioural traits were unobtainable.** Nothing granted one to anybody —
creation rolled physical and personality only, and 25 of 31 are on no
companion — so 110 of the 201 new gates could never fire. Creation now rolls
one trait from each of the three layers: body, temperament, habits.

**Behavioural and acquired traits.** 32 new traits: the CK-flavoured
behavioural kind that two characters can bond over or that sets off an event by
itself, and acquired traits that record what a run did to someone. Constant
effects stay neutral by design — most carry no stat modifiers and work through
`event_tags`. Bond tags and symmetric opposed pairs added across all 84
gameplay traits.

**RelationshipSystem.** One number per unordered pair: a trait-derived baseline
recomputed on read, plus stored drift from shared danger and shared rest. Bands
rival/cool/neutral/warm/sworn, shown in the Party tab with the reasons in the
tooltip. Cleared on death, reincarnation and dismissal.

**Nine acquisition hooks** on existing code paths, plus three losses, and
`trigger: "trait"` / `trigger: "relationship"` events with eleven written.

**Eight broken roll choices found by the new validator checks**, all in content
written earlier the same day: three camp events and five animal events put the
roll on the choice instead of in `requirements` and named the failure branch
`failure_outcome`, so the roll never happened and the failure prose was
unreachable. Five of them had no failure branch at all; those were written.

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
