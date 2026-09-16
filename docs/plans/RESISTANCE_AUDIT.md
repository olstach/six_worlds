# Resistance audit

> **Built 2026-09-16** in three commits — the vocabulary, then the resolver
> with every source moved into `apply_damage`, then the UI figure. What follows
> is the audit as written; TODO §5 records what shipped and the three small
> things left open.

*2026-09-15. Raised in TODO §5 after `grants_resistance` turned out not to
exist while `grants_vulnerability` had been structured and data-driven for
months. That asymmetry was the symptom; this is the disease.*

The headline is not that resistance is complicated. It is that **resistance is
applied by the caller**, and four callers in five do not apply it.

---

## A. Resistance is opt-in, and most damage opts out

`CombatManager.apply_damage()` does not consult `get_resistance()`. It applies
armour reduction, Yoga magic resistance, aura and zone `damage_taken_pct`,
shields and death saves — but never the unit's resistance to the damage type
being dealt. That is left to whoever computed the number, as
`damage * (1.0 - resist / 100.0)`, hand-written at each site.

**61 call sites. 9 apply resistance first.**

Two helpers do it properly — `_calculate_attack_damage()` for weapons and the
magic damage path for spells — so ordinary attacks and ordinary spells are
fine. Everything else is not:

| Damage source | Resistance applied? |
|---|---|
| Weapon attacks (`_calculate_attack_damage`) | yes |
| Spell damage (magic path) | yes |
| Damage-over-time ticks — Burning, Bleeding, Festering, Poisoned | **no** |
| Terrain hazards — fire, poison, acid, cursed, storm, void tiles | **no** |
| Aura payloads (`_apply_aura_payload`) | **no** |
| Zone payloads — every `damage` payload in zones.json | **no** |
| Retaliation, thorns, reflect | **no** |
| Perk bursts, Death Yoga bursts, explosions, cleave, splash | **no** |
| Oil coatings, weapon enchant procs, brands | yes (those three do it by hand) |

So a Solar Form character, *immune to fire*, standing in a fire tile takes
full damage every round. Fluid Form, immune to water, takes full damage from a
water zone. A poison-resistant character takes full Poisoned ticks — and the
poison *tile* deals `physical` anyway, so armour stops it instead.

This is one bug with sixty faces, and it has one fix: resistance belongs
inside `apply_damage`, where every source passes through.

## B. Three damage-type vocabularies, none closed, all disagreeing

- `PHYSICAL_SUBTYPES` = slashing, crushing, piercing. Falls back to
  `physical`. This part works.
- `MAGIC_DAMAGE_TYPES` = space, air, fire, water, earth, holy, shadow, arcane.
  Three of those eight (`holy`, `shadow`, `arcane`) are dealt by nothing. Four
  types that ARE dealt as magic are missing: **black** (11 spells, 25 enemy
  resistance entries), **white** (4 spells, 18 entries), **poison**, **ice**.
  So the Yoga table's magic resistance does not apply to Black or White magic.
- The `damage_type` field itself is an open string. Spells deal `ice`; data
  resists `cold`. Spells deal `solar` and `white`, which no resistance key
  anywhere mentions. Three spells deal `fire_black`, two `physical_fire`, one
  `white_fire` — compound types that match no key, no subtype rule and no
  magic list, so they are resisted by nothing and boosted by nothing.
- Code deals four types that are not elements at all: `true`, `magical`,
  `all`, `sacrifice`.
- Data resists four types nothing deals: `disease`, `holy`, `ranged`, `smoke`.

## C. Additive inside, multiplicative outside, stated nowhere

Inside `get_resistance()` every source **adds** to one percentage, and
immunities **set** it to 100 — which a later `+= 25` can then push past 100.
There is no cap either way. Above 100 the multiplier goes negative and the
per-site `maxi(1, …)` floor catches it, so over-resistance silently means
"1 damage" rather than "healed". Below zero there is no limit at all:
stacked vulnerabilities multiply damage without bound.

Between systems everything is **multiplicative**, in this order:

1. `get_resistance()` — if the caller bothers
2. `Marked_for_Death` ×1.5 — inside `apply_damage`, *after* resistance
3. `damage_reduction_pct` (Armor table) — capped at 90%, applies to **all**
   damage types including magic
4. `magic_resistance_pct` (Yoga table) — capped at 90%, `MAGIC_DAMAGE_TYPES`
   only, see B
5. aura `damage_taken_pct` × zone `damage_taken_pct`
6. `hp_shield`, `death_resistance`, `hp_cannot_drop_below_1`

`Permafrost`'s +30% against Frozen targets is applied in the magic path
*before* resistance; `Marked_for_Death`'s +50% is applied in `apply_damage`
*after* it. Same axis, opposite side of the same multiplication, different
file. `spell_damage_reduction` (25%, Magic Shield and Golden Defense) sits on
one spell path only, so it does not cover a spell that damages through any
other route.

Floors disagree too: `maxi(1, …)` at most sites, `maxi(0, …)` in the magic
path — so a fully-resisted spell deals 0 and a fully-resisted weapon hit
deals 1.

## D. Twenty bespoke strings for one number

These all mean "+N% physical resistance", one status each, one `if` each:

    physical_resist_50            physical_damage_reduction_25
    physical_damage_negation_50_percent   physical_damage_reduction_50
    physical_resistance_plus_25   physical_damage_reduction_75
    physical_resistance_plus_50

And the same again for elements: `fire_resistance_plus_25`,
`fire_resistance_minus_50`, `water_resistance_minus_25`,
`water_resistance_minus_50`, `fire_damage_immunity`, `water_damage_immunity`,
`air_damage_immunity`, `air_immune`, `physical_immunity`, `physical_immune`,
`elemental_resistance_25`, `all_element_resistance`, `magic_resistance_bonus`,
`immune_to_all_damage`.

Every one of them is `grants_resistance: {"fire": 25}` written the long way —
and `grants_resistance` exists, is structured, and is read. Two of the pairs
are the same thing spelled twice (`physical_immunity`/`physical_immune`,
`air_damage_immunity`/`air_immune`).

## E. What the player sees is not what the player gets

The examine panel reads `unit.resistances` — the static dict. Nothing a
status, perk, aura or zone contributes appears in it. A character under Stone
Skin shows the same numbers as one without.

---

## The fix: one resolver, in the mould of AuraSystem and Ground

1. **One damage-type vocabulary**, `resources/data/damage_types.json` behind a
   `DamageType` class: the elements, which are physical subtypes, which count
   as magic. `validate_data.py` then checks every `damage_type` in spells,
   statuses, zones, auras and enemy resistance keys against it — the check
   that would have caught `ice` vs `cold` on the day it was typed.
2. **`Resistance.total(unit, type) -> float`**, every source declared in one
   place, one documented order, one cap at each end.
3. **Move application into `apply_damage`**, and delete the twelve
   hand-written `(1.0 - r / 100.0)` sites. This is the change that fixes A.
4. **Collapse the bespoke strings** onto `grants_resistance` /
   `grants_vulnerability` in statuses.json.
5. **One number for the UI**, so the examine panel can show what a unit
   actually takes.

Order matters: 1 before everything (the rest key on it), 2 and 3 together
(moving application without the resolver would just move the mess), 4 after 2
(the resolver is what makes the strings redundant), 5 last.
