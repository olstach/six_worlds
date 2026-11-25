# Spell review — 2026-11-23

A follow-up to `SPELL_AUDIT.md` (2026-09-13). That audit covered what the engine
did not read. This one reads all 377 spells to answer three questions:

1. Which effect keys should a unified spell format have?
2. Which spells are close enough to merge or cut?
3. Which spells are over- or underpowered?

Nothing here is decided. It is input for the normalization design.

---

## 0. Where things stand

The audit's 40 inert spells are mostly fixed. Several general mechanisms were
built in the meantime, and the unified format can treat them as its building
blocks:

| Block | What it does | Used by |
|---|---|---|
| `damage` + `damage_type` | number, or `{formula: spellpower / status_stacks / target_max_hp_pct}` | ~150 |
| `heal` | number or `"full"` | 20 |
| `statuses_caused` + `duration` | apply named statuses (189 defined in statuses.json) | 187 |
| `save_type` / `save_tier`, `on_failed_save` / `on_passed_save` | one roll, two branches | 31 |
| `push`, `scatter`, `reposition` | forced movement, teleport, swap, behind, adjacent | ~25 |
| `zone`, `aura` | an area effect on the ground, or one carried around a unit | ~10 |
| `status_ops` | remove / steal / transfer / convert statuses | 6 |
| `resource_ops` | drain / restore / transfer HP, mana and stamina | 1 |
| `resurrection`, `on_kill`, `on_allies` / `on_enemies` | | a few each |
| `summon` (+ template) | | 78 |
| map side: `reveal`, `translocate`, `mob_effect`, `provision` | | ~12 |

**What still leaks:** `special` holds 262 different keys. About 55 of them are
read by code. The rest fall into three groups:

- **Real mechanics nobody built.** About 45 spells: chain lightning does not
  chain, life drain does not heal, smite has no bonus against undead, ball
  lightning and searing orb are not projectiles, and `damage_split` is never
  read.
- **Descriptions of what the spell's status already does.** Precision,
  Haste-likes and armour buffs: the status carries the effect and the
  `special` key is just a stale note.
- **Pure flavour** (`creepy_circus_vibe`, `visual`, `note`).

**A second vocabulary lives in statuses.json.** A status lists effects as bare
words (`"strength_bonus"`, `"attack_penalty"`), and the *amount* is hard-coded in
`combat_unit.gd`. So "make Bless stronger" cannot be done in data today. Whether
the normalization covers statuses too is the biggest scope question.

---

## 1. Proposed key vocabulary

### 1a. Common keys: formalize what exists

These already work. The work is to rename for consistency, document, and validate.

| Key | Shape | Notes |
|---|---|---|
| `target` | `{type, eligible, range, count}` | merge in `multi_target` / `two_allies` |
| `area` (was `aoe`) | `{shape, size, origin, falloff, grows_per_tier}` | `upgrade_scaling: "+1_radius_per_tier"` is a string to parse; make it a number |
| `damage` | number or `{base, per_spellpower, formula}` | |
| `damage_type` | string **or** `{fire: 0.5, black: 0.5}` | replaces both `damage_split` and compound types like `fire_black` |
| `heal` | number / `"full"` / `{pct_max}` | |
| `apply` (was `statuses_caused`) | `[{status, duration, chance, save}]` | **chance and save per status.** This replaces `stun_chance`, `freeze_chance`, `fear_chance` and `silence_chance` (about 20 spells) |
| `remove` | status names or group tags | `statuses_removed` and `status_ops: remove` say the same thing two ways |
| `save` | `{stat, tier}` + `on_fail` / `on_pass` | `save_type` + `save_tier` → one block |
| `move` | `{mode: push/pull/scatter/teleport/swap/behind/adjacent, tiles, blocked_damage}` | `push`, `scatter`, `reposition` and `special.teleport_range` → one block |
| `zone`, `aura`, `summon`, `status_ops`, `resource_ops`, `resurrect`, `on_kill`, `per_side` | as now | |
| `notes` | free text | where flavour goes; the game never reads it |

### 1b. New common keys: emerge from repeated `special` keys

Each of these covers 3 or more spells that currently do nothing:

| Key | Covers | Spells |
|---|---|---|
| `bonus_vs: {undead: 1.5, demon: 1.5}` | creature-type multiplier | smite, holy_light, divine_wrath, funeral_pyre, banishing_stake, bone_spike (living), wilting_curse (water creatures), solar_spear |
| `scales_with: {per: debuff_on_target / buff_removed / status_stack / turn_in_zone / mana_drained, amount}` | damage that grows | exploit_weakness, soul_burn, spellstrike, festering_wound, scalding_fog, mana_flare, spontaneous_combustion |
| `drain: {resource, pct_of_damage}` | heal/restore from damage dealt | life_drain, steal_air, mana_flare, lifelink, blood_hunger (the last two via status) |
| `chain: {count, falloff, only_on_kill}` | jumps to a nearby target | chain_lightning, death_shock |
| `spread: {to: adjacent / debuffed, chance}` | status jumps between units | plague_waters, witch_fire (burning already spreads, so generalize it) |
| `projectile: {moves, turns, explode_area}` | object travelling across the field | ball_lightning, searing_orb |
| `requires` / `bonus_if: {target_has / caster_in_zone}` | conditions | ember, spontaneous_combustion, choking_smoke ("enhanced in smoke") |
| `on_kill` extended: `raise_as`, `leave_no_corpse` | | death_bolt, balefire, vaporize, funeral_pyre |
| `cloud: true` on zones + `disperses` | clouds as a real category | stinking_cloud, poisonous_cloud, deathfog, miasma, scalding_fog; clear_air and gust_of_wind clear them |
| status triggers: `on_owner_death`, `on_ally_death`, `on_enemy_adjacent`, `link` | statuses that react | eternal_vow, ancestral_vengeance, magnetizing_aura, karmic_bond, mark_for_death |

### 1c. Possible and interesting

These are not needed by any current spell. Each would open a design space
that fits the game:

- **`reacts_with`: elemental reactions.** Lightning on a Wet/Frozen unit
  spreads the stun. Crushing on Frozen shatters for bonus damage. Fire on
  Frozen thaws, and on Oily/Fire_Vulnerable it flares. Fire on water terrain
  makes steam. Some terrain-from-damage already exists
  (`DAMAGE_TYPE_TO_TERRAIN_EFFECT`); this makes it two-way and status-aware.
  It rewards party composition, which the design already values.
- **`consume`: spend a status for a payoff.** Generalizes spontaneous_combustion
  and flash_of_radiance. Possible spells: detonate Poison, cash in Marked, or
  turn your own Bleeding into power (tummo-like).
- **`karma`: casting shifts hidden karma.** Raising the dead, Dominate, Midas
  Touch, Doom versus Death Rites and Pacify. It is invisible, like all karma, and
  makes spell choice morally textured without a UI. Very on-theme.
- **`cost: {hp / stamina / pressure}`: non-mana costs.** Black magic paid in
  blood, or in psychological pressure, which hooks the psychology system.
- **`channel`: concentration.** Spells sustained across turns at a per-turn cost,
  broken by damage. `insect_swarm` already promises to "disrupt concentration"
  that does not exist.
- **`delay`: telegraphed spells.** The effect lands next turn on a marked area:
  meteor shower, vajra rain, doom. Gives the AI and the player something to react to.
- **`impermanence`: decaying effects.** A buff or summon weakens each turn
  instead of switching off. Thematic, and a gentler balance lever than duration.
- **`echo`**: the spell repeats next turn at half strength.

---

## 2. Duplicates and near-duplicates

| Spells | Problem | Suggestion |
|---|---|---|
| `grounding` (L3) vs `cleanse` (L7) | grounding removes **all** negatives (`"negative"` = `"all_negative"` in status_ops) **plus** a CON buff, four levels earlier | grounding should remove only physical afflictions, or one status |
| `cloudform` (L7) vs `fluid_form` (L9) | cloudform is lower level, works on allies, can be upgraded to the whole party, and has a smaller vulnerability (50%). Same immunities. fluid_form is strictly worse | make fluid_form self-only but much stronger, or make cloudform self-only |
| `clarity` vs `clear_mind` (both L3) | both remove mental debuffs; one adds Awareness, the other Mental_Immunity | keep clear_mind (luminosity domain); give clarity a different job |
| `oily_skin` (L1) vs `melt_armor` (L3) | melt_armor = oily_skin + armour shred | fine as a ladder, but oily_skin could be flammable (bonus to burning spread) |
| `voidbolt` vs `bitter_word` (L1 Black/Sorcery) | carried over from the audit, still both present | cut voidbolt or give it a rider |
| `crushing_hand` vs `stone_spike` (L1 Earth, 15 dmg) | still identical in effect | merge |
| `jump` vs `get_out` (L1, 15 mana self-teleport range 4 / 3) + `blink` (L3, 6) + `cloudstep` (L3, 5, ignores LOS) + `flash_step` (L5) | five short teleports | keep one per level band; give the others a twist (get_out = only when adjacent to an enemy, flash_step leaves fire) |
| `bulwark` (L3) vs `golden_armor` (L5) vs `stone_skin` (L5) | three physical-resist buffs, 25/50/50 | golden_armor adds spell reduction, so keep it; stone_skin and golden_armor at the same level overlap |
| `shrapnel_blast` vs `earthquake` (L7, 100 dmg) | shrapnel has a smaller radius (3 vs 4), the same damage, and no rider | add a bleed or armour-pierce rider |
| `rainbow_orb` / `rainbow_spray` | fine: single target vs cone at different levels | — |
| `slashing_blade` | the description is still "Blade damage (+50% dmg/cost)" | rewrite |

---

## 3. Balance outliers

Reference curve, base values before spellpower/2 + skill bonus are added:
L1 15 mana / ~15 dmg · L3 40 / ~25 · L5 75 / ~50 · L7 135 / ~80 · L9 225 / ~120.
Area spells mostly deal **the same** damage as single-target spells of their
level, so a single-target nuke needs a rider to be worth taking.

### Overpowered

- **`stinking_cloud` (L1, 15 mana)**: a radius-2 zone that stuns for spellpower
  duration. That is area stun-lock for 15 mana. Make the stun a chance with a
  save each turn, or apply Nauseated (lose half your action) instead.
- **Hard crowd control that upgrades to "all enemies"**: `dread` (Paralyzed),
  `petrify`, `charm`, `confusion`, `chaos`, `berserk`. At the top upgrade tier,
  one cast takes out the whole enemy side. Suggest capping CC at "area" and
  never "all", or making the all-tier halve the duration.
- **Instant kills work on bosses**: `midas_touch`, `deathfog`, `liberate` (and
  `doom`, through `death_on_expire`). The code applies `instant_kill` with no
  boss check. Bosses should take the `on_pass` branch automatically (or a
  fixed % of max HP).
- **`mudra_of_touching_the_earth` (L9)**: 150 damage to every enemy *and* a
  150 heal to every ally, with no area limit. Compare firestorm: 120 damage in
  radius 5, no heal. `sunrise` (120 + 100) and `wilting_curse` (150 to all
  living enemies) sit in the same bracket. The global spells beat every storm.
  Either globals cost more (300+) or deal about 60% of a storm.
- **`Extra_Action` for the whole party**: `second_wind` (L7, can be upgraded to
  all allies) and `rain_of_revival` (L7, area, plus a 60 heal). A party-wide
  extra turn is the strongest effect in the game; it belongs at L9 at most,
  single target only.
- **`cloudform` (L7)**: physical immunity, upgradable to the whole party.
  Enemies that only deal physical damage cannot do anything.
- **`ghost_shoal` (Water/Summoning L7)**: 100 damage in a band plus Confused.
  The strongest L7 area spell in the school with the lowest damage, and it sits
  under Summoning.
- **`golden_blade` (L7, 304 mana)**: 225 single-target damage, more than any
  L9 single-target nuke, plus gold on kill.

### Underpowered

- **`vaporize` (L9, 225)**: 150 single-target damage, below golden_blade (L7)
  and equal to spore_explosion's *area* damage. It needs "leaves no corpse,
  ignores resistance" or about 250 damage.
- **`black_lightning` (L7, 135)**: 50 damage + Blind. `lightning` is L5, costs
  75, and deals 60 + stun. Raise it to about 90, or let it chain like
  chain_lightning in black.
- **`tsunami` (L9)**: 30 damage + push 2. The blocked damage (70) helps, but on
  an open map it is an L9 spell doing L1 damage. Raise the base to about 80, or
  add Prone and Drenched.
- **`cauterize` (L1)**: deals 5 damage *to your ally* to remove Bleeding/Poison.
  `herbal_remedy` (same level) *heals* 15 and removes the same. Make it remove
  wounds too, or stop bleeding permanently.
- **`ember` (L1)**: Burning only, and only on a target that was burning
  recently. Strictly worse than firebolt.
- **`soothing_presence` (L3)**: heals 5.
- **`steam_jet` (L3)**: 20 damage in a 3-tile line versus breath_of_fire's 25 in a cone + Burning.
- **`surge` (L1, 5 dmg)** and **`geyser` (L7, 30)**: low even for Water. The push
  makes up for it only near walls.
- **`death_bolt` (L3, 20)**: below curve, and its identity (raise the target as a
  zombie on kill) is unwired.

### Mana-cost anomalies

Domain spells are often priced one tier up, with no visible reason:

- **L5 at 225 mana** (the L9 price): `mindmuck`, `rain_of_mud`, `vision_of_reality`.
- **L3 at 75 mana** (the L5 price): `eerie_dirge`, `sonic_boom`, `metal_to_mud`,
  `globe_of_glass`, `heat_transfer`, `flash_of_radiance`, `fragrant_sauna`,
  `divine_eye`, `mudling`. Meanwhile `battle_chant`, the sibling of
  `eerie_dirge`, costs 40.

Either domains have a deliberate surcharge (say so in `school_notes`) or these
are errors.
