# Enemies as XP-built characters

**Status:** design approved, not yet implemented
**Scope:** enemy generation + post-battle XP reward
**Out of scope:** persistent heroes and enemy XP-gathering — see [Follow-on](#follow-on-spec-2-persistent-heroes)

## Why

The game claims to run on a single currency: XP, spent freely on attributes and
skills, no levels. Enemies do not participate in that economy. They are built
from a separate ad-hoc "power" number, and the XP they pay out is computed from
a third formula again.

There are currently three disagreeing measures of how strong a character is:

| Where | Formula |
|---|---|
| `EnemySystem.get_party_power()` | Σ(attr − 10) + Σ(skill × **8**) |
| `CombatManager._calculate_unit_power()` | Σ max(attr − 10, 0) + Σ(skill × **5**) |
| What power actually costs | attribute rank × 3 cumulative; skills `[0,5,10,18,28,42,59,80,106,137,175]` |

None of them is XP. So an enemy's difficulty, its reward, and the real price of
the power it holds are three unrelated numbers, and tuning any one of them
moves nothing else in a predictable direction.

This design collapses all three onto XP. An enemy becomes a character built by
spending an XP budget through the same cost curves the player uses, which makes
enemy strength and player strength the same quantity, and makes the reward a
fraction of a number that means something.

## Model

An enemy is generated the way a player character is:

1. **Roll a birth** — `CharacterSystem.roll_birth_for_realm(realm)`, weighted by
   `reincarnation_weight`.
2. **Roll a background** — from that birth's `typical_backgrounds`.
3. **Apply birth and background modifiers** — the existing
   `apply_birth_modifiers` / background application, unchanged.
4. **Spend the XP budget** — directed by the archetype, through
   `calculate_attribute_cost` and `SKILL_COSTS`.
5. **Derive equipment** — gear value is a function of the budget, not paid from it.
6. **Record `xp_earned`** — the enemy's honest total.

Steps 1–3 are what the player already does. Step 4 is what the player does with
their XP. The archetype enters only at step 4, as a spending plan.

### Why the archetype is a spending plan, not a bonus

Archetypes already hold `attribute_weights` and `skill_priorities`. Those are
spending priorities. Keeping them as such means:

- no re-authoring of 34 animal archetypes (and the hell and hungry-ghost sets),
- a Naga Warrior at 400 XP and at 1600 XP are recognisably the same build at
  different depths,
- enemy XP stays honestly comparable to player XP, because every point of enemy
  power was paid for at the player's prices.

That last property is what makes the reward formula fall out for free. Flat
bonuses would be power the enemy did not pay for, and the reward would need a
correction factor to compensate.

### Why equipment is derived, not purchased

The player buys gear with gold, never with XP. If enemy gear came out of the XP
budget, enemy XP and player XP would stop denoting the same thing. So the budget
buys attributes and skills only, and gear value is a separate function of it: a
1600-XP enemy carries roughly 1600-XP-appropriate kit.

Loot continues to come from the existing budget-based inventory generation, now
keyed to the XP budget instead of the power number.

## The budget

The budget is a **party** total, divided among members. A three-enemy group and
a solo boss at the same number cost the same and should be roughly as dangerous.

```
party_xp = REALM_BASE[realm] × TIER[encounter.tier] × BAND[rolled]
```

### REALM_BASE — absolute, not relative

A realm's budget is a fixed number. It does **not** track the player's XP.

This is a deliberate reversal of current behaviour, where enemies scale to
`get_party_power()` and therefore never fall behind. Absolute budgets mean the
player can enter a realm under-powered and struggle, or return over-powered and
cut through. Realms become intrinsically dangerous places rather than
proportionally dangerous ones, progression becomes legible — you feel yourself
outgrow a world — and the rare high-XP groups are genuinely threatening rather
than threatening-relative-to-you. It also fits reincarnation: you re-enter a
fixed world as a new and weak thing.

| Realm | REALM_BASE |
|---|---|
| hell | 200 |
| hungry_ghost | 700 |
| animal | 1800 |

Grounded in what a character is actually worth in XP, computed from the real
cost curves:

| Character | XP worth |
|---|---|
| fresh start (base 10s, two skills at 1) | 10 |
| early (two attributes at 13, three skills at 2) | 81 |
| mid (three at 16, four skills at 4) | 433 |
| late (four at 20, five skills at 6) | 1470 |
| very late (five at 24, six skills at 8) | 3663 |

These four constants are starting points from arithmetic, not from play. They
are expected to move.

### TIER

Reuses the `tier` already authored on every encounter, so deliberate content is
not flattened:

| tier | multiplier |
|---|---|
| imp | 0.5 |
| shade | 0.8 |
| devil | 1.0 |
| boss | 2.0 |

**Only 48 of 117 encounters actually carry a top-level `tier`** — the 48 `roles`
ones. All 52 `fixed` and all 17 `groups` encounters have none, so the tier must
be derived for them rather than defaulted:

- **`fixed`** — take the highest tier among the archetypes in its `enemies`
  list. Every archetype carries a `tier`, so this is always resolvable, and it
  gives the boss encounters the boss multiplier they should have.
- **`groups`** — each group carries its own `tier`. Take the highest as the
  party tier; the individual group tiers become the share tiers (see below).

Falling back to `devil` (×1.0) for these would have silently flattened every
boss fight in the game to ordinary difficulty.

### BAND

Rolled per encounter, using the same common/uncommon/rare vocabulary that births
now use, so the player learns one rarity concept:

| band | multiplier | weight |
|---|---|---|
| common | ×1.0 | 60 |
| uncommon | ×1.5 | 30 |
| rare | ×2.3 | 10 |

The band is a single number that both loot and XP reward read, and it is
available to the UI if high-band groups should ever be telegraphed.

## Party composition

### Party archetypes

A party archetype decides **how many** members and **what share** of the party
XP each takes. Shares are relative weights.

```json
"patrol":         { "weight": 30, "tiers": [{"share":1, "count":[2,4]}] },
"pair":           { "weight": 15, "tiers": [{"share":1, "count":2}] },
"hero_and_mooks": { "weight": 20, "tiers": [{"share":3, "count":1},
                                            {"share":1, "count":[2,4]}] },
"swarm":          { "weight": 15, "tiers": [{"share":1, "count":[5,8]}] },
"lone_hunter":    { "weight": 10, "tiers": [{"share":1, "count":1}] },
"warband":        { "weight":  8, "tiers": [{"share":2, "count":[1,2]},
                                            {"share":1, "count":[3,5]}] },
"foreign_mercs":  { "weight":  2, "foreign": true,
                    "tiers": [{"share":2, "count":1}, {"share":1, "count":[2,3]}] }
```

```
member_xp = party_xp × share / total_shares
```

`hero_and_mooks` with one hero and three mooks is six shares: the hero takes
50%, each mook about 17%. On a common animal encounter that is a 900-XP hero
leading 300-XP mooks — a genuinely dangerous individual with real chaff, which a
flat split cannot express.

`foreign_mercs` rolls its births *and* archetypes from a different realm. Meeting
hell-born mercenaries in the animal realm should read as an event.

Exotic templates are gated by band: `warband` from uncommon upward,
`foreign_mercs` on rare only. Composition surprise is thereby tied to the
rarity roll rather than being a second independent dice throw. Gating removes a
template from the pool entirely; the remaining weights are renormalised, so a
common-band encounter draws from the five ungated templates at their relative
weights rather than silently rerolling.

### Meeting the existing data

Composition is currently authored three ways across 117 encounters: 48 use
`roles` + counts, 52 are `fixed` archetype lists, 17 are `mixed`/`groups`.

- **`roles` encounters roll a party archetype.** The archetype sets count and
  shares; the encounter's `roles` still decides *which* archetypes fill the
  slots, sampled proportionally to the member count.
- **`fixed` encounters keep their authored lists.** Bosses and story fights —
  the King of Beasts stays a `rakshasa_maneater` with two varaha honour guards.
  They receive XP shares but not a rolled composition.
- **`groups` encounters convert**, each group becoming a share tier. This is
  the shape that already expressed hero-and-mooks by hand; the per-group
  `difficulty_range` is replaced by a share.

The largest share is assigned to the slot with the highest `threat_multiplier`
among those rolled — already authored on every archetype, so this needs no new
data.

### Known consequence

`swarm` at 5–8 members and `lone_hunter` at 1 are both valid at the same budget,
so party size stops correlating with difficulty. This is intended, but it means
the player can no longer read danger off the number of enemies on screen. A
visual tell for high-band groups may be wanted later; it is not in this spec.

## Heroes

A member is a hero when it holds strictly more XP than every other member of its
party, or when it is the sole member of the party. So `hero_and_mooks`,
`warband` and `foreign_mercs` produce one hero each, and `lone_hunter` is a hero
by itself — a solo predator carrying the whole budget is the most hero-like
thing the system generates. `patrol`, `pair` and `swarm` produce none, because
their members are equals and singling one out would be arbitrary.

Spec #1 gives a hero a full identity but no life after the battle.

- **`is_hero: true`** on the generated character.
- **A stable `hero_id`**, generated at spawn, so a later system can refer to it.
- **A real name.** `animal_realm_names.json` holds 389 personal names with
  meanings and is currently read by no script at all — heroes are what it is
  for. Mooks keep the procedural `generate_enemy_name`. Hell and hungry ghost
  have no equivalent lore file, so heroes there fall back to
  `generate_enemy_name` until one exists; this gap is noted, not filled here.
- **A title** once the hero's XP passes a threshold, giving it a recognisable
  character.
- **A distinct tooltip colour**, so a hero is visibly not a mook. Sprite
  recolouring is deferred until sprites exist.

A hero is a fully-formed individual the moment it spawns. It simply does not yet
survive the encounter.

## Reward

```
per_member_xp = enemy_party_xp × REWARD_FRACTION × existing_party_size_multiplier
```

`REWARD_FRACTION = 0.07`.

The fraction is small because `CompanionSystem.apply_party_xp` grants **each**
party member the full amount rather than splitting it — a detail worth
restating, since assuming a split would inflate this constant roughly fourfold.
The existing party-size multiplier (solo ×1.5, duo ×1.25) is preserved.

At 7%, per member:

| encounter | per-member XP |
|---|---|
| hell, common | ~14 |
| hungry ghost, common | ~49 |
| animal, common | ~126 |
| animal, rare band | ~290 |

Harder groups pay more with no separate rule, because they cost more to build.

This number is the most likely to be wrong and is expected to be tuned in
playtesting. It is one constant in one place for that reason.

Gold and loot key off `enemy_party_xp` and the band instead of the old ratio.

## What is removed

- `EnemySystem.get_party_power()`
- `CombatManager._calculate_unit_power()`
- `DIFFICULTY_MULTIPLIERS` as a power scalar (superseded by TIER and BAND)
- per-group `difficulty_range` in `groups` encounters (superseded by shares)

## Verification

Every encounter in the game is re-tuned at once by this change, so it must be
inspectable before it ships rather than after.

A harness that, for all three realms, generates every encounter and prints:
party XP, band, party archetype, member count, and each member's birth,
background, archetype, XP share, resulting attributes and skills. The whole
table gets eyeballed before the change goes live — the same way the rebirth
distribution was checked empirically rather than assumed.

Additional checks:

- Generated members' XP-cost sum matches their assigned share, within the
  rounding of the cost curves.
- Party XP shares sum to the party budget.
- No encounter produces a zero-member or zero-XP party.
- `validate_data.py` clean; headless boot with no script errors.

## Follow-on: Spec #2, persistent heroes

Not designed here. The idea, recorded so this spec does not foreclose it:

A hero met and *survived* — one the player did not kill — persists. It wanders
its realm and sometimes crosses into others, so the player may meet it again.
It gains XP between meetings, so it returns stronger. This is the "enemies
gathering XP" idea, and the direction is Caves of Qud or Dwarf Fortress: a world
that continues without the player in it.

Spec #1 supplies what that needs: heroes already have a stable id, a name, a
title and an XP total. Spec #2 adds survival, storage, wandering, and growth.

Open questions for that spec: when does a hero count as having survived; where
is the roster stored and how does it interact with save slots and with
reincarnation; how fast do they grow; do they recruit new parties; can a
survived hero ever become a companion; how many persist before the roster is
pruned.
