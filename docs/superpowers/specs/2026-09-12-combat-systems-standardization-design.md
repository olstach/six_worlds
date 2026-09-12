# Combat Systems Standardization — Saves, Forced Movement, AoE Falloff

**Date:** 2026-09-12
**Status:** approved, ready for implementation planning

Three systems the perk and spell text already assumes and the game does not
have. Recorded as TODO Part I §11; this is the design for all three.

They are specified together because they share a shape: each replaces an
inconsistency that exists because the systems around it landed years apart.

**They are independent and should land as three separate changes.** Nothing in
forced movement or falloff depends on the save rework, and the save rework is
by far the largest and the only one that shifts balance. Bundling them would
make a single review answer three unrelated questions at once.

---

## 1. SaveSystem — one saving-throw mechanic

### The problem

Three unrelated mechanisms decide whether an effect is resisted.

| Where | Mechanic |
|---|---|
| `CombatManager._perform_save_roll()` | flat `40% + 2%/point above 10`, clamped 10–90. No dice, no DC, no attacker input. 6 call sites. |
| `statuses.json` | 4 of 168 statuses declare `save_type`; 2 mention a save inside `effects`. Nothing reads either. |
| `spells.json` | 27 of 363 declare `save_type`, read only by the two `cast_spell` call sites. |
| `EventManager` | `d20 + best_party_stat` vs `best_party_stat + tier_modifier`. |

Perk and spell text assumes a fourth thing that exists nowhere: "Constitution
save at −20%", "Focus save DC 16". Neither a DC nor a modifier is expressible
today, so that text is decoration.

### The model

`d20 + defender stat` vs `DC = 10 + attacker stat + tier modifier`.

```
TIERS = { easy: -4, normal: 0, hard: +4, brutal: +8 }
```

Both sides' stats matter: a stronger caster is genuinely harder to resist, a
tough target genuinely shrugs things off.

```
Con 12 vs Focus 12, normal   d20 + 12 >= 22   55%
Con 18 vs Focus 12, normal   d20 + 18 >= 22   85%
Con 12 vs Focus 20, normal   d20 + 12 >= 30   15%
```

**The DC uses the attacker's attribute, never spellpower.** Spellpower reaches
25–40 once equipment and affinity land, so `10 + spellpower` would put DCs
beyond d20 reach entirely and every save would auto-fail. Both sides stay on
the 8–20 attribute scale.

### Interface

```gdscript
# scripts/combat/save_system.gd — static, class_name, like AoEResolver
SaveSystem.roll(defender: Node, save_type: String, dc: int) -> Dictionary
    # -> {success: bool, roll: int, total: int, dc: int, margin: int}

SaveSystem.dc_for(attacker: Node, dc_stat: String, tier: String,
                  modifier: int = 0) -> int
    # -> 10 + attacker attribute + TIERS[tier] + modifier
```

`roll()` returns a result dict rather than a bool so callers can log the
numbers and so perks can react to the *fact* of a save — `steadfast_spirit`
("passing a saving throw grants 50% resistance to that type for 2 turns") needs
to know a save was passed, which a bool discards.

### Data

Four fields on any effect that allows a save. The first is already present on
27 spells and 4 statuses; the rest are new.

- `save_type` — the defender's attribute (`constitution`, `focus`, `finesse`, …)
- `dc_stat` — the attacker's attribute setting the DC. Defaults by effect
  source, because one default cannot serve both: `focus` for spells and mental
  effects, `strength` for weapon and forced-movement effects. An effect that
  wants something else says so.
- `save_tier` — `easy` | `normal` | `hard` | `brutal`. Default `normal`.
- `save_dc_modifier` — flat integer, for text like "at −20%" (−4).

An unknown `save_type` or `dc_stat` is a `push_error`, not a silent default —
the vocabulary lesson from `CombatStats`.

### Existing bonuses convert exactly

One d20 point is 5 percentage points, so the percentage-shaped bonuses already
in the data map onto roll points with no retuning and no loss of designed
intent:

| Source | Text | Roll bonus |
|---|---|---|
| `save_bonus` (Booster Shot) | "+25% resistance to the next status" | +5 |
| `mental_resistance_pct` (Calm Mind, space affinity) | "+15% to mental saves" | +3 |

`SaveSystem.roll()` divides both by 5. `mental_resistance_pct` applies only
when `save_type == "focus"`, as it does today.

### Migration

Six call sites move from `_perform_save_roll(unit, attr)` to
`SaveSystem.roll(unit, attr, dc)`, taking the DC from the effect's tier and
defaulting to `normal` where no tier is declared. `_perform_save_roll` is then
deleted rather than left as a wrapper — six call sites is small enough that a
compatibility shim would only preserve the ambiguity.

Status immunity gates (`_check_talisman_status_immunity`, the Juggernaut check,
Laughing at the Abyss, Bare Chest) stay exactly where they are. They are
pre-save gates — "this cannot affect you at all" — not save modifiers, and
folding them in would change what they mean.

### Events are deliberately untouched

Event tier DCs are `best_party_stat + modifier` against a roll of
`d20 + best_party_stat`, so the attribute cancels and the tiers are flat
probabilities. The comment says this is intended ("difficulty constant
regardless of power level").

That is defensible for a skill check and wrong for a saving throw, so the two
stay separate policies over one dice shape. Changing it would silently reweight
every blue and yellow choice across 348 events, which were authored against the
current odds. Recorded in TODO as its own decision.

### Blast radius

Every CC effect in combat changes probability. A Constitution-12 target
currently saves at 44% against everything; afterwards 55% at `normal` against
an equal attacker, 15% against a Focus-20 caster, 85% if it is Constitution-18.
That spread is the point of the change, but it is a real balance shift and
should be followed by a tuning pass in play.

---

## 2. Forced movement

### The problem

Nothing in the game moves a unit against its will. There is a `Pushed` status,
a `knockback` string in `statuses.json` that nothing reads, and perks whose text
describes pushes — and `put_your_weight_into_it` applies `Knocked_Down` as a
stand-in because displacement does not exist.

### Interface

```gdscript
CombatManager._displace_unit(unit: Node, direction: Vector2i, tiles: int,
                             source: Node) -> Dictionary
    # -> {moved: int, lost: int, blocked_by: Node|null}
```

Walks one tile at a time along `direction`, stopping at the first tile that is
unwalkable, occupied, or off the map. `tiles` may be negative to pull. Reports
how far the unit actually went and how much was lost.

Forced-movement immunity (the Juggernaut check at `combat_manager.gd:6977`) is
consulted first. `Rooted` and `Immobilized` do **not** block displacement —
those prevent voluntary movement, which is a different thing.

### The primitive decides nothing

It reports tiles lost; the caller decides what a collision means. A generic
"impact damage per tile" baked into the primitive would force every push in the
game to share one rule, so a gust of wind and a mace blow could not differ.

The consequence is declared per effect:

```json
"push": { "tiles": 1, "blocked_damage_bonus_pct": 25 }
```

That is `overwhelming_blow`'s description implemented literally — *"pushes the
enemy 1 tile. If they can't be pushed (wall, another unit), they take +25%
damage instead."* Direction is attacker → target.

### One parser, many consumers

The same `push` block appears in perk `combat_data`, in spell data, and in perk
`on_trigger` payloads. It gets **one** shared parser:

```gdscript
CombatManager._apply_push(source: Node, target: Node, push_data: Dictionary)
```

Three copies of a schema is exactly how the stat-vocabulary defects this
project has been unwinding got in.

Consumers, in the order they are worth wiring:

| Consumer | Unblocks |
|---|---|
| `attack_with_bonus`, `debuff_target` resolvers | `shield_bash`, `overwhelming_blow` |
| The `Pushed` status | becomes real rather than decorative |
| Status effect string `knockback` | gains a reader |
| Spell data | push/gust spells |
| Weapon on-hit procs | `_process_weapon_on_hit_procs` |
| Perk `on_trigger` payload type `push` | reactive knockback perks |

---

## 3. AoE damage falloff

### The problem

`impaling_strike` reads "full damage to the first, 60% to the second".
`AoEResolver` returns an unordered tile list with no concept of distance
weighting, so it currently deals 80% to both as an approximation.

### Opt-in, always

Falloff applies **only** when an `aoe` block explicitly declares it. No
`falloff` key means uniform damage, exactly as today. This is not a default and
must never become one — most areas should hit evenly, and a silent global
change to AoE damage would be a balance event disguised as a refactor.

```json
"aoe": { "type": "line", "size": 2, "falloff": [100, 60] }
```

The last entry repeats outward, so `[100, 75, 50]` on a radius-5 circle gives
50% from ring 2 onward.

### Ring indexing

Indexing by raw distance from the origin breaks caster-anchored shapes.
`impaling_strike` is a `line` anchored on the caster, so its first enemy stands
at distance **1**, not 0 — indexed by distance, `[100, 60]` would give that
enemy 60%.

Falloff therefore indexes by **ring within the shape**, where the first ring the
shape actually covers is index 0:

| Shape family | Ring |
|---|---|
| directional — `line`, `arc`, `cone`, `cone_forward` | steps along the facing direction, minus 1 |
| centred — `circle`, `nova`, `cross`, `around_caster` | distance from origin |

### Interface

```gdscript
AoEResolver.falloff_at(aoe: Dictionary, caster_pos: Vector2i,
                       target_pos: Vector2i, tile: Vector2i) -> float
    # -> 1.0 when no falloff is declared
```

`CombatManager._units_in_skill_aoe()` returns each unit with its multiplier;
`_resolve_aoe_skill` and `_resolve_aoe_damage_and_status` apply it.
`impaling_strike` then matches its own text instead of approximating it.

---

## Verification

One new `tools/verify_combat_systems.tscn`, following the convention of the
existing verifier scenes: run in the real engine against the live autoloads,
because `validate_data.py` parses JSON in Python and never exercises a GDScript
loader.

**Saves** — roll each tier several thousand times at fixed stats and assert the
success rate matches the documented probability within tolerance; assert a `+5`
`save_bonus` moves the rate 25 points; assert `mental_resistance_pct` applies on
Focus saves and not on Constitution saves.

**Displacement** — clear path, wall, occupied tile, map edge, immunity, and
negative `tiles` (pull). Assert `moved` and `lost` for each.

**Falloff** — assert the multiplier per tile for one directional and one centred
shape, and assert that an `aoe` block with no `falloff` key returns 1.0
everywhere.

Every assertion is negative-tested — deliberately broken to confirm it fails —
as with the perk and enemy-XP suites. A check that cannot fail is decoration.

---

## Out of scope

- Event roll behaviour (see above).
- Rebalancing CC durations and frequencies after the save change. Expected, but
  it needs play, not a spec.
- The damage pipeline's order of operations. It has accumulated layers and may
  want the same treatment, but it has not been audited and this document will
  not assert that it does.
