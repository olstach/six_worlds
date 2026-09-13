# Six Worlds — TODO

**Last updated:** 2026-09-12

The open list. Organised as: **what to do next → what is still open → designs
waiting to be built → what got done**. The full historical checklists (every
`[x]` line from the psychology, weapons, camp, wounds and body-plan passes) are
preserved in git at commit `73a948c`.

`README.md` holds the current state of the project — realm coverage, content
totals, how to run and verify it. It is not repeated here, because this file
kept a second copy of those numbers and they drifted: as of today it still
claimed 600 perks, 565 items, 103 traits and Godot 4.6 against a real 604, 606,
121 and 4.7.2. One place for facts.

Companion documents:
- `PERKS.md` — perk trees per skill, hand-maintained
- `CHARACTERS.md` — companion bios, hand-maintained
- `docs/review/` — all realm prose; round-trips to JSON via
  `tools/import_review_docs.py`
- `docs/superpowers/specs/` — designs approved but not yet built
- `tools/verify_all.sh` — run after any edit

---

## Where to pick up

**A hell → hungry ghost → animal playthrough.** All three realms are populated
and none of the recent content has been played; the animal realm has never been
played at all. Progression is genuinely gated now (boss seal enforced, boss
events exist), and a large batch of mechanics went from data-only to live
without anyone seeing them move. Use the cheat console to skip ahead.

Worth watching for specifically:

- **First-pass balance numbers** — summoning terrain +25%, pack bonus,
  shield/mirror-image pools, reflect chances, wound-healing prices. All guessed,
  none played.
- **Difficulty multipliers** (easy 0.75× … boss 1.6×) now apply to every event
  fight for the first time.
- **The wounds and psychology panels** — first look at whether those systems are
  tuned sanely now that they are visible.
- **Active perks.** 75 of them became usable in 2026-09; before that every one
  was greyed out, so none has ever been pressed in a real fight.

Then, depending on appetite:

- **Content:** more quests (the board works but holds three, all hell),
  `PERKS.md`'s empty tiers, cursed items.
- **Systems:** the three approved combat designs below, prosthetic items
  (small, unblocks a fully-coded flow), or combat-UI polish (wound icons,
  per-arm damage popups).
- **Big swing:** YidamSystem — the design in Part II is complete enough to
  build, mantra counts already accumulate, and camp Mantra Recitation feeds it
  with nothing reading the result.

- [ ] **All recent prose is Claude's and wants Olaf's pass.** The three hungry
      ghost map-critical events (boss + both pass guardians), the 34 further HG
      events, the 47 animal zone events, and the 24 animal companion bios.
      Marked **NEW EVENT** / **NEW** in `docs/review/`.

---

## Approved designs not yet built

- [x] **Forced movement and AoE damage falloff** — built 2026-09-12, two of the
      three parts of
      `docs/superpowers/specs/2026-09-12-combat-systems-standardization-design.md`.
      Both are additive: nothing behaves differently until a perk or spell opts
      in.
- [x] **One saving-throw mechanic** — built 2026-09-12. That spec is now fully
      implemented.

---

# Part I — Loose ends

Ordered by how much finished work sits behind each one.

## 1. Small and self-contained

Each of these is an hour or less and touches one system.

- [ ] **8 race descriptions are placeholders** (`TODO: Fill in description`):
  `nomad`, `mountain_folk`, `trader`, `tsen`, `rudra`, `gandharva`, `apsara`,
  `planetary_deity`. All belong to unbuilt realms, so this waits for those.
  (`bee` was the ninth and the only reachable one; it was deleted as a
  duplicate of `bhramara` on 2026-08-31.)
- [ ] **`sever_part` doesn't handle `arm_l2`/`arm_r2`** — four-armed species have
  equip slots `hand_l2`/`hand_r2` but no `weapon_main2`/`weapon_off2`, so
  severing an extra arm doesn't drop its weapon.
- [ ] **`extra_arm_results` isn't shown in the combat UI** — the multi-arm chain
  writes per-arm hit/damage into the result dict and the combat log prints it,
  but the unit frames don't (no "Arm 2: 12 dmg" popup).
- [ ] **Combat-UI wound icons** — wounds render in the character sheet; unit
  frames need sprite work.
- [ ] **No race defines any resistance at all.** All 47 carry
  `"resistances": {}`, so `base_resistances` on a character is always empty and
  the skeleton's 50% physical reduction this item used to cite does not exist.
  Racial resistance is a designed-in field that was never filled.

  The original concern still stands underneath it: `EnemySystem._build_enemy()`
  copies only the archetype's own `resistances`, so if races are ever given
  some, an archetype-defined skeleton still will not inherit them. Enemies now
  roll a real birth and apply its modifiers, which makes the inconsistency
  easier to fix and more obviously wrong to leave.
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

  **Renamed 2026-09-12 so the trap is visible in the name.** `_pct` is a
  percentage, `party_` means one member's skill pays the whole party, a bare
  name is flat. The convention is recorded in `perks.json`'s `base_bonuses._comment`
  and enforced by `validate_data.py`. Five live keys were renamed at the same
  time because their names misled: `attack` → `accuracy` (it lands on
  `derived.accuracy`), `armor_penetration` → `armor_pierce`, `stamina` →
  `max_stamina` (a maximum, not current), `mana_cost` → `mana_cost_reduction`
  (negative values mean cheaper), `strength_weapon_damage` →
  `weapon_damage_from_strength`. Verified behaviour-preserving: derived stats
  for every skill at levels 1/5/10/15 are byte-identical before and after.

  **They were never the simple renames they looked like.** It is tempting to map
  the dead keys onto live derived stats by name — `mental_resistance` onto
  `mental_resistance_pct`, `movement_speed` onto `movement`. Checked against the
  values, most of that is wrong:

  | dead key | skill | L1 → L15 | why not a rename |
  |---|---|---|---|
  | `movement_speed` | grace | 10 → 65 | `derived.movement` is in **tiles** (base 3–4). This is a percentage; renaming grants 65 tiles. |
  | `healing_effectiveness_(party)` | medicine | 10 → 130 | party-wide; `healing_pct` is per-character |
  | `magic_damage_resistance` | yoga | 5 → 75 | magic only; `damage_reduction_pct` is all damage |
  | `party_xp_gain` | learning | 3 → 42 | party-wide; `xp_gain_pct` is per-character |
  | `loot_quality` | thievery | 5 → 75 | quality is not `loot_chance_pct`'s chance |
  | `mental_resistance` | yoga | 5 → 125 | same concept as `mental_resistance_pct`, but +125% is an auto-pass and needs rescaling |

  What the table still needs is two things that do not exist: **consumers for
  the percentage stats**, and a **party-wide propagation mechanism** for the
  `party_` keys.

- [x] **Party-wide bonuses** — built 2026-09-12 as `PartyBonuses`, best member,
      with `update_party_derived_stats()` firing on skill change and party
      add/remove. Six keys wired and rescaled (see `base_bonuses._comment` for
      the rule). Design notes kept below for the next phase:

- [x] **Phase 2 — economy and crafting** — done 2026-09-12. Turned out to be
      mostly *convergence*: Trade discounts and the Alchemy potion bonus already
      existed as hand-rolled code that disagreed with the tables. Five keys
      wired, two left with reasons:
      - `crafting_quality_pct` has **no mechanic to attach to** — camp crafting
        pulls from a fixed `CRAFT_TABLE` with no quality concept. Building one
        is a feature, not a wiring job.
      - `crafting_yield_pct` is owned by **Alchemy** while camp crafting reads
        **Smithing**. Needs a decision about which skill crafts what before it
        can mean anything.
- [x] **Phase 3 — logistics and learning** — done 2026-09-12. Four wired:
      `party_skill_check_bonus` (event rolls), `party_supply_duration_pct`
      (supply draws), `party_xp_gain_pct` (XP award), `party_travel_speed_pct`
      (overworld movement). The other five are each blocked on something real:
      - **`morale_pct`** — removed 2026-09-12. It was a relic of an idea that
        became PsychologySystem. The live question it leaves behind is in
        "Things to ponder": Leadership ought to touch companion psychology.
      - **`charm_effectiveness_pct`, `social_roll_pct`** — done 2026-09-12.
        They turned out to be one stat with two sources, now
        `party_social_roll_pct`. Event rolls did not need tagging after all:
        each already names a skill or an attribute, so the category derives
        from it, with an optional `category` on the roll for the cases where
        the stat does not tell the story.
      - **`loot_quality_pct`**: no loot rarity mechanic to attach to.
      - **`max_companions`** — done 2026-09-12 as `party_max_companions`. Two
        companions come free; Leadership adds one at 3, 6 and 9, topping out at
        a party of six.
- [ ] **Needs a proc site, not a consumer** (4 keys): `stun_chance_pct` (maces
      on-hit), `burning_damage_pct` (fire DoT), `status_effect_chance_pct`
      (status application), `luck_pct`. Each is its own small integration.
- [ ] **`effect_duration_pct` is a DUPLICATE, not a gap.** Enchantment's
      duration bonus already works, computed straight from the skill level in
      `_calculate_status_duration` (+1 turn per 2 levels). Wiring the table key
      would double-count it. Decide which one is the truth and delete the other
      — do not wire this.
- [ ] **Original design notes:** They behave
      like equipment bonuses — another additive source folded into `derived` —
      except the source is a different character's skill. No ordering problem
      arises because they derive from **raw skill levels**, never from another
      character's `derived`, so nothing waits on anything.

      **Best member, not sum** (decided 2026-09-12). Four medics should not be
      four times one medic. Taking the best also matches the rule the game
      already uses everywhere — "any party member meeting a requirement enables
      the choice" — and makes the specialist *the* specialist. It has a known
      cost, recorded under "Things to ponder" below.

      **A refresh hook is mandatory** — this is a build requirement, not a
      design question. Party-wide bonuses mean one member's skill feeds every
      other member's `derived`, so `update_derived_stats` has to run for the
      **whole party** whenever skills or party membership change, not just for
      the character who changed. Miss it and stats go quietly stale, which is
      the hardest class of bug to notice in this codebase.

      Combat-facing `party_` keys land in `derived`; the rest
      (`party_xp_gain_pct`, `party_travel_speed_pct`,
      `party_supply_duration_pct`, `party_skill_check_bonus`) are read by
      CompanionSystem, MapManager, CampSystem and EventManager.

- [x] **This whole bug class is now caught automatically.** `validate_data.py`
  gained a data→code check: five vocabularies (base_bonuses stats, status
  behaviour strings, AoE shapes, active skill effects, passive effect types) are
  checked for values that no code reads. Known gaps live in
  `tools/vocabulary_baseline.json` with a reason attached, so the check fails
  only on new drift. Shrink the baseline by wiring a consumer.
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

- [ ] **Saving throws, after the 2026-09-12 rework.** Every CC effect in combat
      changed probability. A Constitution-12 target used to resist *everything*
      at a flat 44%; now it is 55% against an equal attacker, 15% against a
      Focus-20 caster, and 85% if it is Constitution-18. That spread is the
      point — but the tiers (easy -4, normal 0, hard +4, brutal +8) and which
      effect sits in which tier are first guesses. Nothing has been played.
      Watch for: hard CC landing too reliably on low-Constitution characters,
      and high-attribute characters becoming immune to anything at `easy`.


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

### The 26 active perks still without a resolver (2026-09-10)

75 of 109 active perks were wired in b746bc1. These 26 are the remainder, each
blocked on machinery that does not exist. They stay correctly greyed out in the
skill panel until it does. `tools/verify_active_perks.tscn` reprints this list
on every run, so it cannot silently drift.

- [ ] **`create_terrain`** — timed terrain tiles placed by a skill (9 perks):
      `black_ice`, `fog_of_war`, `gravity_well`, `raise_wall`,
      `crumbling_avalanche`, `improvised_barricade`, `prepared_ground`,
      `inscribed_circle`, `the_door_stands_open`.
      `CombatGrid` already has `add_terrain_effect()` and destructible
      obstacles; what is missing is a resolver that places them and a duration
      that ticks down.
- [ ] **Counter/reaction stances** (5 perks): `counterstrike`,
      `stand_in_the_gap`, `set_for_charge`, `kill_zone`, `heavenly_counterflow`.
      Needs an on-being-attacked hook. The ZoC on-move hook already exists
      (`_check_zoc_reactions`), so this is the sibling of a solved problem.
- [ ] **`heal_ally`** — `field_medic`. `_resolve_heal_self` ignores its own
      `targeting` field and always heals the user; splitting out a targeted
      version is small.
- [ ] **`create_images`** — `smoke_and_mirrors` (illusion units with 1 HP).
- [ ] **`imbued_attack`** — `arcane_archer` (attack + spell hybrid).
- [ ] **`consume_charm`** — `attune_charm`.
- [ ] **`mass_teleport`** — `everyone_is_somewhere_else_now`.
- [ ] **`recruit_or_pacify`** — `magnetism`.
- [ ] **`place_trap`** — `trap_maker`.
- [ ] **`steal_item`** — `the_invisible_hand`.
- [ ] **`guard_ally`** — `stalwart_guardian`.
- [ ] **`choose_one`** — `improvised_masterpiece`. Needs a pick-a-branch UI;
      `disrupting_palm` is wired to its first branch as a stopgap.
- [ ] **`ignore_resistances` on overcast** — `too_fast_to_react`. One field in
      `cast_spell`'s resistance step.
- [ ] **`none_shall_pass`** — not missing machinery, a spec mismatch. Written as
      "Active. End your turn. Until your next turn, enemies cannot move through
      your threatened area (2-tile reach) without taking a free attack and
      suffering -2 Movement for 1 turn." Implemented as an always-on passive
      free attack, with no turn-ending and no -2 Movement. Decide which it is.

### The seven overworld perks are data with no consumer

Flagged `non_combat` in b746bc1 so they stop rendering as dead buttons in the
combat panel — that change did **not** implement them. `scout_ahead`,
`investment`, `supply_and_demand`, `guided_practice`, `reinforce` and
`inspiring_sermon` have zero references in `scripts/`. `forage` is the near
miss: `camp_system.gd:156` already has a forage camp action open to everyone,
and the perk that is supposed to improve it is never consulted.

## 8. Things to ponder

- [ ] **Party size may still be undercosted, and Leadership may still want
      nerfing.** The cap is 3 free, 6 at Leadership 9. The reason it is that low:
      party size is arguably the strongest stat in the game. The party-check
      rule opens a choice when *any* member qualifies, and every `PartyBonuses`
      payout resolves to the best member — so each extra character is another
      roll of the dice on having every specialist at once, across 35 skills.
      XP dilution is the existing counterweight, but it costs *combat* power
      while the benefit lands on *non-combat* checks, of which there are far
      more. Rejected as a Leadership payout for the same reason: making
      Leadership reduce XP dilution would remove the only cost wide parties
      pay. Leadership keeps its active perks and, eventually, the companion
      psychology wiring below. Revisit after a playthrough.

Live design questions. Not bugs, not deferred decisions — the shape of these is
still genuinely open, and each was raised because something built today works
but may not be what the game wants.

- [ ] **Best-member party bonuses make the second specialist worthless.** With
      best-member, a party's second-best Medicine contributes exactly nothing,
      so levelling it is wasted XP and the player learns to stop. Summing has
      the opposite problem (four medics become four times a medic, which is
      absurd and off-theme), so neither pure rule is right. Worth considering:
      diminishing contribution from lower-ranked members, or a small flat
      assist per additional member above a threshold.

- [ ] **Party-wide bonuses invite min-maxing once the player knows the game.**
      If one character's skill pays the whole party, the optimal build is one
      specialist per useful skill and nobody redundant. That is a legible
      strategy, which is good, but it flattens party composition into a
      checklist. The whole party-bonus logic may want rethinking rather than
      tuning — the current pass standardizes it so it is legible enough to
      reason about, not because the rule is settled.

- [ ] **Equipment, crafting and loot want one audit together.** Olaf's
      direction, 2026-09-12, recorded before it evaporates:

      - **All non-consumable items should have quality.** Weapons and armour
        already do: material and quality set the stat ranges, traits modify
        from there. Everything else that is not a consumable should work the
        same way. Crafting is messy in general and this is the spine of tidying
        it.
      - **Alchemy crafts consumables. Smithing crafts ammo and repairs today,
        and should produce equipment in future.** That answers which skill
        `crafting_yield_pct` belongs to — it is Alchemy's, for consumables —
        and what `crafting_quality_pct` needs before it can mean anything.
      - **Loot value should derive from the defeated party's total XP against
        the player party's**, with a percentage chance to receive it as a
        single better item rather than several common ones. That chance is one
        of the main points of the Luck attribute, which currently does very
        little.
      - ~~Two quality vocabularies~~ — **settled 2026-09-12.** One ladder:
        poor / common / good / fine / masterwork. The trade tools' "storied"
        and "legendary" were never quality — a storied lute is a masterwork
        lute with a story on it, which is *enchantment*. They map to masterwork
        and earn their value through the enchantment tier.
      - ~~Armour materials are metal-shaped~~ — **hide, scale, chitin and silk
        added 2026-09-12.** Silk is not structural: historically a silk layer
        catches an arrowhead and lets it be drawn back out, so it carries a
        ranged resistance rather than armour, and is allowed on robes, hats and
        capes only. A silk helmet would still be nonsense.
      - [ ] **Equipment generation only covers weapons and armour.** The twelve
        accessory types now have base entries and can be priced, but
        `generate_weapon` / `generate_armor` have no sibling for them. Nothing
        procedurally produces a focus, charm, ring or cape — and focus items are
        the single largest equipment category in the game at 210. A
        `generate_accessory` is the obvious next expansion, and it is what would
        let loot offer anything but weapons and armour.
      - Blocked on this: `crafting_quality_pct`, `crafting_yield_pct`,
        `loot_quality_pct`.

- [ ] **Specialist ritual robes — designed 2026-09-13, not built.** Olaf's
      list, recorded before it evaporates. All graded 1-5 like the ngakpa line,
      chest slot unless noted:
      - healer's robe — white magic, **regeneration aura** at high grades
        (adjacent allies heal a little each turn)
      - black sorcerer's robe — sorcery, spellpower at high grades
      - pandita robe — learning, persuasion at high grades
      - sage's robe — earth **and** white, both smaller, rising incrementally
      - tantric robe — ritual
      - dreamer's robe — enchantment
      - chodpa's robe — summoning
      - chodpa's eye covering (**head**) — summoning, black at high grades
      - **No longlife robe** — it is a hat accessory to the healer's robe.

      **Gap: black magic has no robe.** The black sorcerer's robe grants
      *sorcery*; black appears only on the chodpa's eye covering at high
      grades. Every other school gets a dedicated garment. Either the black
      sorcerer's robe should grant black magic too, or a separate one is
      missing.

      **Material axis, per Olaf:** cotton / wool / silk as the quality tiers,
      with metal-threading for elemental variation — "silver-threaded silk
      healer's robe". That reuses `ritual_metals` for the thread, which is
      tidy. The caution is multiplication: 3 fabrics x 8 threads x 8 families x
      5 grades is 960 items. Suggest the thread only appears on the top two
      grades, so most robes are plain fabric and a threaded one is a find.

      **Blocked on machinery:** the regeneration aura and the longlife cap's HP
      aura need an item-granted aura path. `_process_aura_effects()` handles
      status-driven auras and `passive_aura` exists as an item field (one khata
      uses it), but nothing connects an equipped item to an aura status. The
      longlife caps carry `passive_aura: "longlife_hp"` as of 2026-09-13 with
      no consumer yet — the first thing to wire.

- [ ] **Ritual implement coding is declared but not yet player-facing.** The
      tables now say copper serves fire and the phurba serves sorcery, and the
      verifier enforces it — but a tooltip still shows a Copper Phurba without
      explaining that it is the instrument for a fireball. Reading
      `ritual_metals` and `ritual_implements` into the item tooltip is the step
      that makes the system legible to the player rather than only to us.

- [ ] **Leadership should touch companion psychology.** `morale_pct` was
      removed 2026-09-12 as a relic: it was an early sketch that grew into
      PsychologySystem instead, and it left Leadership and Performance paying
      into a mechanic nobody ever built. But the intent underneath is sound —
      leading people well should affect how they hold up. Somewhere between
      Leadership level and companion pressure/relationships there is a wiring
      worth designing. Deliberately not specified here; it wants thought, not a
      stat key.

- [ ] **Traps — a battle feature, not an overworld one.** Originally conceived
      as a combat mechanic and the pieces are scattered across both readings,
      which is why it keeps looking like two half-features:

      - `trap_maker` (Smithing) is a combat perk deferred on a `place_trap`
        resolver — see §7. "Place a trap on an adjacent tile. The first enemy to
        enter takes damage equal to 30% of your Focus and is immobilized."
      - `trap_detection_pct` (Thievery) is a dead skill-table key, currently
        with no system at all. It was read as overworld detection, which is
        probably wrong: if traps are a battle feature, this is the counterplay
        to enemies placing them.
      - `Trapped` exists as a status in statuses.json.

      Design question before either gets built: are traps placed in combat only,
      or do they persist on the overworld map? That decides whether detection is
      a combat action, a map passive, or both — and `trap_detection_pct` cannot
      be wired until it is answered.

- [ ] **Support characters as equipment-shaped content.** The retired
      "logistics train" idea has one part worth keeping: a hireling who is not
      a full character — a cook who grants a supply bonus, a mule that raises
      carry weight. Content-wise a person, mechanically a piece of equipment.
      Not needed now, and mechanically close to the planned **mounts and pets**
      system, so the two should be designed together when that comes up.

## 9. Deferred by decision

Recorded so they aren't rediscovered as bugs.

### 2026-09-12 — the "logistics train" is retired

The original idea was a way to bring non-combat characters — a medic, a smith, a
trader — into the party without them being dead weight in a fight: a second
class of party member who contributed support bonuses instead of combat.

The game grew past it. Every character and NPC now runs on the same character
system, so there is no "full character" versus "support character" distinction
left to make. A medic in the party is simply a party member who is good at
Medicine and less good at swinging a sword, which is a more coherent thing for
the game to be about.

What survives is the mechanic, not the framing: `party_`-prefixed skill payouts,
where one member's skill pays the whole party. That is designed (§3 above) and
unbuilt. The support-character-as-equipment idea is parked in "Things to ponder"
for whenever mounts and pets are designed.

### 2026-09-12 — event rolls ignore the attribute, deliberately for now

An event tier DC is `best_party_stat + modifier` and the roll is
`d20 + best_party_stat`, so the attribute cancels and every tier is a flat
probability — a Focus-18 party rolls no better than a Focus-8 one. The comment
says this is intended ("difficulty constant regardless of power level").

Defensible for a skill check, and left alone when combat saves were
standardized, because changing it silently reweights every blue and yellow
choice across 348 events that were authored against the current odds. If it
does change, it needs an events balance pass in the same breath, not a
one-line edit.

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
  meanings, plus per-birth place names that exist only in the file. The rakshasa
  set alone has **The Long Hunger** (a stretch of poor territory between
  productive ones), **The Wrong Side** (anywhere they do not go, and there is
  always a reason), **The Ridge Where They Wait**, **The Mango Kill**, **The
  Scratch Tree**, **The Three-Day Territory**. Every birth has six or so like
  these. Fold them into the events pass — an event set on The Wrong Side is
  already half-written by its own name.

- **The realms are badly uneven in size, and the animal realm ran away.**
  Births were planned at roughly 9-12 per realm.

  | realm | births | companions |
  |---|---|---|
  | hell | 6 | 24 |
  | hungry ghost | 14 | 23 |
  | **animal** | **18** | **52** |
  | human | 4 | 0 |
  | asura | 2 | 0 |
  | god | 3 | 0 |

  Hell is definitely too small at six and wants expanding toward the intended
  range. Animal multiplied well past it, and its companion count doubled again
  during the birth-by-birth pass — 52 against hell's 24 for three times the
  births. Not a problem while the content is good, but the realms should not
  stay this lopsided: a player's first world is the thinnest one they will see.

  When the animal pass finishes, return to hell and give it the same treatment.
  Its six devils have **no birth-specific backgrounds at all**, which is the
  single largest gap left in a finished realm.

- **Marjara want events badly.** Solitary predators who do not anchor
  encounters, but the birth carries more comic and world-building potential
  than any other in the realm: the smuggler's patter, the pleasure dancer, the
  cutpurse insisting marjara is innocent of this crime. Their place names are
  ready-made settings too — The Hollow Where Nothing Comes, The Long Wait, The
  Patient Rock. Worth a cluster of events rather than one.

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

- **Birth and archetype can contradict each other.** Enemy births are rolled
  from the realm independently of the archetype, so 33 hell encounters produce
  things like `hell_green_devil_sniper` with a `blue_devil` birth. Either
  constrain the roll when an archetype id names a birth, or decide devils are
  mixed-parentage and let it stand.

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

- **Background assignment wants a pass across all births.** 94 backgrounds, but
  only 3 are universal (`healer`, `reveler`, `wanderer`) and 55 are single-birth
  — 58% of them. Average 4.8 births per background. Mriga was in none of the 22
  broadly-available ones (`warrior` covers 18 births, `scholar` 14,
  `merchant`/`guard`/`diplomat`/`noble`/`monk` 13) purely because it was created
  after those lists were authored; ten were opened to it by hand. Every future
  birth hits the same trap. After the animal-birth pass, go over all births and
  reassign, add, or generalise backgrounds — and check gana first, which was
  split at the same time as mriga.

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

## 10. The passive perk backlog (2026-09-10)

The engine is built and proven; the data is barely started. Of 470 passive
perks: **168** are implemented by hand in `scripts/` (checked by id with
`PerkSystem.has_perk()` at the moment they matter), **5** carry an `effects`
array, **297** are still description-only.

**The rule everything rests on:** a hand-implemented perk must never *also*
carry an `effects` array, or it fires twice. `tools/wire_passive_perks.py`
derives the hardcoded set by scanning `scripts/` rather than keeping a list, so
a perk hardcoded tomorrow is protected without anyone remembering, and
`verify_passive_perks` re-checks it against shipped data. Note that **Parry and
Improved Parry — the plan document's own worked example of a
`stat_conversion` — are both hardcoded** and must stay that way.

Working effect types: `stat_bonus` (conditional and not), `stat_conversion`,
`resistance`, `on_trigger`.

- [ ] **Author the remaining 297.** Mechanical, and the tooling refuses bad
      data, but it is a long pass. Worth doing skill by skill.
- [ ] **`non_combat` effects are deliberately unbuilt.** ShopSystem and
      EventManager have no consumer for them. Authoring an effect before its
      reader exists is the exact failure this whole pass spent its time
      undoing — build the consumers first. This is what the seven overworld
      perks in §7 are waiting on too.
- [ ] **Unbuilt effect types:** `aura`, `cost_reduction`, `damage_modifier`,
      `resource_regen`, `spell_modifier`, `summon_modifier`, `special`.
      `summon_modifier` has the most data waiting on it — several black, fire
      and air perks buff summons and all of them are inert.
- [ ] **More trigger points.** `_fire_perk_triggers` is only called for
      `on_hit`, `on_crit`, `on_kill`, `dodge_success`. The taxonomy also wants
      `combat_start`, `turn_start`, `take_damage`, `parry_success`,
      `ally_damaged`.
- [ ] **More conditions.** `_perk_condition_met` answers fourteen. Missing ones
      the perk text asks for: `wearing_heavy_armor`, `unarmored_or_light`,
      `first_attack_combat`, `first_attack_turn`, `from_behind`,
      `target_bleeding`, `target_debuffed`, `on_terrain_type`.

## 11. Systems the perk text assumes and the game does not have

**All three are built** (2026-09-12): forced movement, AoE damage falloff, and
one saving-throw mechanic. See Part IV for what changed.


Found while wiring the actives. Each is worth building as a system rather than
as a one-off, because several perks and spells want the same thing.

- [x] **Saving throws are three unrelated mechanisms.** Built 2026-09-12 —
      `SaveSystem`. Original note kept for the reasoning:
      `CombatManager._perform_save_roll()` is a flat `40% + 2%/point above 10`
      with no DC and no d20; `statuses.json` carries `save_type` and
      `save_at_end_of_turn` fields nothing reads; `EventManager` has its own
      d20+DC system. Perk text says "Constitution save at -20%" and "Focus save
      DC 16" and neither is expressible. Unifying on the event system's d20+DC
      unblocks ground_slam's knockdown, mountain_falls' stun and body_blow at
      once, and finally gives `statuses.json`'s save fields a reader.
- [x] **Forced movement does not exist.** Built 2026-09-12 —
      `_displace_unit` / `_apply_push`. Original note: There is a `Pushed` status and perks
      that talk about knockback, but no function relocates a unit — "Put Your
      Weight Into It" applies `Knocked_Down` instead. One
      `_displace_unit(unit, direction, tiles)` respecting walls, occupancy and
      the Juggernaut immunity already written at `combat_manager.gd:6977`
      covers shield_bash, overwhelming_blow, the push spells and the knockback
      perks together.
- [x] **AoE damage falloff.** Built 2026-09-12 — opt-in `falloff` lists.
      Original note: `impaling_strike` wants 100% to the first tile
      and 60% to the second; `AoEResolver` returns an unordered tile list with
      no concept of distance-weighting. Useful for every spell that wants a
      softer edge.

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

## 2026-09-12 — documentation cleanup

Nine documents removed. Each was describing a state the project had left, which
is worse than having no document — `PERK_WIRING_PLAN.md`'s wrong status quo cost
a full session's first hour before it was checked against the code.

| Removed | Why |
|---|---|
| `HELL_EVENTS.md` | Headed "Source of truth for hell_events.json" while holding **50 of 79** events, and not wired to `import_review_docs.py`. `docs/review/EVENTS_HELL.md` is the real source. |
| `HG_EVENTS.md` | Same header, **14 of 150** events. Editing it and asking for a sync would have put 136 events at risk. |
| `PROJECT_ANALYSIS.md` | A point-in-time March audit ("14 autoloads"); superseded by this file. |
| `REFRESHER.md` | Orientation doc; its current state moved to `README.md` and its "point of departure" to "Where to pick up" above. |
| `EVENT_SYSTEM.md` | January; duplicated `CLAUDE.md`'s description of grey/blue/yellow choices. |
| `EDIT_LATER.md` | One live item (prose wants Olaf's pass), folded into "Where to pick up". |
| `docs/plans/STATUS_EFFECTS_PLAN.md` | Opens "Critical Bug: Status Definitions Never Load". False — 168 load and 158 of 181 effect strings are handled. |
| `docs/plans/2026-03-01-companions-*.md` (4) | Completed plans; the system shipped. Specs now live in `docs/superpowers/specs/`. |
| `docs/plans/2026-03-02-recruitment-*.md` (2) | Same. |

Kept: `PERKS.md` and `CHARACTERS.md` (hand-maintained design sources),
`docs/review/` (round-trips to JSON), `docs/plans/PERK_WIRING_PLAN.md`
(corrected and current), `CLAUDE.md` (agent working agreement).

`README.md` rewritten from the live boot output rather than from the previous
README, which claimed Godot 4.3 and 12 autoloads against a real 4.7.2 and 21.

## 2026-09-11 — verify_enemy_xp made deterministic; two bugs it was hiding

**The flaky kit-budget check is fixed at the root.** It asserted
`spent > budget * 6 + 400` over procedurally generated gear and failed about
one run in ten with no code change. The cause is that item value is
*multiplicative* — `base x material.value_mult x quality.value_mult`, where
material spans 0.25 (`hide`) to 15.0 (`vajra`) and quality 0.5 to 3.0
(`masterwork`). The same base weapon therefore spans a 120x range with a long
thin tail, and a 45x vajra-masterwork roll produces a ~2565-gold weapon. The
kit budget picks a *rarity band*; it was never a spend cap, so a fixed linear
threshold sat inside that tail and the assertion turned on the dice.

Three changes: the suite seeds the RNG (`RNG_SEED`), so a failure is
reproducible and bisectable instead of meaning "run it again"; the magic 400 is
replaced by `ItemSystem.get_equipment_tables()`-derived arithmetic — the
dearest base times the dearest material times the dearest quality, currently
4500 — so the allowance follows the data instead of going stale; and a new
aggregate assertion (`total gear <= 2x total budget`, currently 1.16x) carries
the real weight, since one lucky roll cannot move it but budget ceasing to
influence gear would. Both assertions were negative-tested.

**Seeding immediately surfaced a real bug: seven backgrounds granted no
starting spells.** `apply_background_skills()` passed every `starting_spells`
entry straight to `learn_spell(character, spell_id: String)`, but 10 of the 12
entries in `races.json` are `{school, level, count}` specs, not ids. Each raised
a type error that aborted the rest of the function. The birth path twenty lines
above already handled both shapes correctly via `_pick_random_spell()`; the
background path had never been updated. palace_vizier, tide_seer,
boundary_walker, network_node and flame_seeker now learn their spells.

## 2026-09-09/10 — perk wiring: actives, the AoE resolver, and the passive engine

Five commits on `claude/perk-wiring-active`, working through
`docs/plans/PERK_WIRING_PLAN.md`. That plan's "status quo" turned out to be
wrong in both directions and is corrected in place; the counts below are the
real ones.

**Active perks got the data their resolvers were waiting for.**
`combat_manager.gd` had accumulated 32 `_resolve_*` handlers dispatched from
`use_active_skill`, but **no perk in perks.json had ever carried the
`combat_data` they read** — not at HEAD, not in any earlier revision of the
file. Since `combat_arena.gd` greys out any non-mantra skill with empty
`combat_data`, all 109 "Active." perks were unclickable and the resolvers had
never once run. 75 are now wired; 7 overworld ones are flagged `non_combat` and
filtered out of the combat panel; `host_of_the_winds` is reclassified passive
(it describes summons that are active, and only reached the panel because the
panel matches on the "Active" prefix); 26 remain, listed in Part I §7.

**Active skills now use the shared AoE resolver.** `aoe_resolver.gd` already had
ten shapes and `cast_spell` routed through it, but the four active-skill AoE
resolvers each hand-rolled `_grid_distance(...) <= aoe_radius`, so every skill
area was a circle whatever the perk said. `_units_in_skill_aoe()` is the single
entry point now, falling back to `aoe_radius` as a circle so genuine bursts are
untouched. New `arc` shape (full width at every step, where `cone` tapers to a
tip): `size 1, width 3` is the three tiles in front of the attacker, `size 2`
reaches spear range. red_harvest and sweeping_strike use it, impaling_strike
uses `line`. Skill hover previews draw the silhouette.

**`CombatStats` is now the one vocabulary** for stat and targeting names
(`MODIFIABLE`, `DERIVED`, `DATA_KEYWORDS`, `TARGETING`), each entry annotated
with what consumes it. `_apply_stat_modifier()` refuses an unmodifiable stat
with a `push_error` instead of storing it. Both perk tools read these lists
rather than restating them.

**The passive effects engine is built** — steps 3-7 of the plan. PerkSystem
carries the query layer; `update_derived_stats()` folds in flat bonuses then
conversions (in that order, since a conversion reads a finished stat);
`CombatUnit._get_conditional_perk_bonus()` evaluates gated effects where the
stat is read; `CombatManager._fire_perk_triggers()` dispatches `on_hit`,
`on_crit`, `on_kill` and `dodge_success`. Only 5 perks are wired to it so far —
see Part I §10.

**Six things were being computed and never read.** Same failure each time: a
value written under one name and read under another, or not read at all, with
`.get(key, default)` quietly covering the gap.

| What | Was |
|---|---|
| `combat_arena.gd` | Would not parse. `8eeffe5` deleted `var ratio` from `_show_victory_screen` and left four uses fifty lines below — **the combat scene had failed to load since 2026-09-03**. |
| `save_bonus` | Booster Shot wrote it from the day it shipped; nothing read it. The perk did nothing. Now read by `_perform_save_roll()`. |
| `mental_resistance_pct`, `healing_pct`, `damage_pct` | Computed by `get_affinity_bonuses()` and never folded into `derived`. Space, water and fire affinity paid out nothing for mental resistance, healing or damage. |
| `damage_reduction_pct` | Folded into `derived` but never read in combat, so the Armor skill's damage reduction did nothing. Now read by `apply_damage()`. |
| Skill stamina cost | The button parsed it by regex from the description while `use_active_skill` charged `combat_data.stamina_cost`. The regex misses "(once per combat, 8 Stamina)", so One Inch advertised itself as free, passed the affordability check, then drained 8. |
| Revive targeting | `single_ally` filters on `is_alive()`, false for exactly the bleeding-out ally a revive exists for. New `downed_ally` mode. |

**New tooling.** `tools/wire_active_perks.py` and `tools/wire_passive_perks.py`
own the data and regenerate `perks.json`; `tools/verify_active_perks.tscn` and
`tools/verify_passive_perks.tscn` check the result against the **live**
autoloads, which `validate_data.py` structurally cannot — it parses JSON in
Python and never exercises a GDScript loader. Both verifiers were negative-
tested: deliberately breaking a value, an AoE shape name, a stat vocabulary
entry and the double-wiring rule each trips them.

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
