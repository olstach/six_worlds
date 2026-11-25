# Effect normalization — design

**Date:** 2026-11-25 · **Status:** approved by Olaf 2026-11-25

"Normalization" is the name for this process: moving one kind of content
onto the shared effect language. This project is **effect normalization**
(spells, statuses and the content around them). **Perk normalization** is the
next one, asked for separately once this is done.
**Background:** `docs/plans/SPELL_REVIEW_2026-11.md` (what is wrong with spells
now), `docs/plans/SPELL_AUDIT.md` (the September audit), TODO §16 (balance work
parked until this is done).

---

## 1. Why

Olaf wants to be able to **edit what spells and statuses do** without code, and
to have **more possible effects**: a Morrowind-style "change any value" effect,
propagation (chain, pierce, cascade…) that an item or a status can grant for a
while, and statuses that can come from a spell, an item or a quest.

Today an effect can be written in **six different formats**, and only one of them
is checked:

| Where | Format | Problem |
|---|---|---|
| spells.json | named blocks + a free-form `special` dict (262 keys, ~55 read) | about 45 spells promise mechanics nobody built; misspelt keys silently do nothing |
| statuses.json | `effects: ["attack_penalty", …]` bare words | **the numbers live in code** (`CombatUnit._get_status_stat_bonus`, about 160 lines of `if "x" in effects: total += 10`). `Finesse_Plus_2` does not change Finesse; it gives +5 dodge and +3 initiative |
| perks.json | `{type: stat_bonus / resistance / on_trigger / …, conditions}` | the good one: every name is checked against lists in `combat_stats.gd` |
| items.json | `effect: {type: heal / restore_mana / cleanse / buff}`, oils, charms | its own small format |
| upgrades.json | `effects: {max_hp_percent: 10, enables_manual_deployment: true}` | its own format |
| events | `rewards: {buffs, hp_loss, pressure, add_trait…}` | its own format |

## 2. Goals, non-goals, anti-goals

**Goals**
- One vocabulary of **effects** that spells, statuses, items, perks, upgrades
  and events all use, with one resolver in code.
- Every number that decides how strong something is lives in data.
- Every name in an effect is checked when data loads, and in
  `validate_data.py`. Unknown name = loud failure, never a silent no-op.
- The ~45 spells with unbuilt mechanics get those mechanics (the review's main
  findings), expressed in the new vocabulary.
- Room for the extensions Olaf asked for: change-any-value, grantable
  propagation, quest/world statuses, elemental reactions.

**Non-goals**
- Rebalancing. TODO §16 is done *after* this, on top of it. Migration keeps
  today's behaviour, except where §7 lists a deliberate change.
- New spells or statuses beyond what the migration needs.
- Combat UI redesign. Tooltips must keep working, but not get prettier.

**Anti-goals** (failure even if it technically works)
- JSON that is harder for Olaf to read or edit than today's.
- A big-bang rewrite that leaves the game unplayable for weeks. Every stage
  ends with `verify_all.sh` green and a game that runs.
- Losing named statuses. Burning, Stunned and Blessed keep their names, icons,
  stacking and dispel rules.
- A seventh format living alongside the other six. Each stage deletes the old
  reader it replaces.

## 3. Approaches considered

- **A. One effect language used everywhere** (chosen by Olaf, 2026-11-25).
  Effects are small building blocks; spells, statuses, items, perks, upgrades
  and events are containers of them. Most work, but it is the only option where
  item-granted propagation, Morrowind-style value changes and quest statuses
  are just data.
- **B. Clean up spells and statuses separately.** About half the work, but
  every cross-system idea stays a special case.
- **C. Pure Morrowind**: flat effect rows, no named statuses. Uniform, but it
  loses the stacking, icons, tag-based dispel and readable content entries the
  game relies on.

## 4. The vocabulary

### 4.1 An effect

An effect is one JSON object with an `op` and the op's fields. A few shared
fields may sit on **any** effect:

| Field | Meaning |
|---|---|
| `to` | who it hits, relative to the container: `target` (default), `caster`, `allies_in_area`, `enemies_in_area`, `all_in_area`, `source` (for triggers: whoever caused it), `party` |
| `chance` | 0–100, rolled before the effect. Fed through `effective_status_chance` so existing perks still apply |
| `save` | `{stat, tier}`. If present, the effect only lands on a failed save. The tiers are the ones `save_system.gd` has |
| `on_save` | `"fail"` (default when `save` is set) or `"pass"`, for two-branch spells sharing one roll (see 4.3) |
| `if` | a list of conditions from one approved list (extends `CombatStats.PERK_CONDITIONS`: `target_has: <status or tag>`, `target_is: <creature tag>`, `damage_type: <type>`, `caster_in_zone: <zone>`, `below_half_hp` …) |
| `scale` | `{per, amount, cap}`. Grows the effect's magnitude: `per` ∈ `spellpower`, `debuff_on_target`, `buff_on_target`, `status_stack:<name>`, `turn_active`, `mana_drained`, `buff_removed`, `ally_in_area` … |
| `bonus_vs` | `{undead: 1.5, demon: 1.5, living: 1.25, boss: 0.5}`, a multiplier by creature tag |

**Magnitudes** anywhere a number goes: a plain number; `{base, per_spellpower}`;
`{pct_of: "target.max_hp"}` (any value path, see 4.2); or `{min, max}`, rolled.

### 4.2 The ops

**`damage`**: typed HP loss that goes through resistances, crits and on-hit
triggers.
`{op: damage, amount, type}`. `type` is a damage type, or a split
`{fire: 0.5, black: 0.5}`, which replaces `damage_split` and compound types
like `fire_black`. Optional `pierce` (ignores N% resistance) and
`true: true` (ignores everything).

**`heal`**: `{op: heal, amount}`. Respects `healing_pct`. `amount: "full"` allowed.

**`modify`**: the Morrowind effect. Changes any **value** by a **mode**.

```json
{"op": "modify", "value": "attribute.strength", "mode": "fortify", "amount": 3}
{"op": "modify", "value": "skill.swords",       "mode": "drain",   "amount": 2}
{"op": "modify", "value": "resource.mana",      "mode": "absorb",  "amount": 20}
{"op": "modify", "value": "resist.fire",        "mode": "fortify", "amount": 50}
{"op": "modify", "value": "stat.movement",      "mode": "set",     "amount": 0}
{"op": "modify", "value": "propagation.chain.count", "mode": "fortify", "amount": 1,
 "applies_to": {"tag": "lightning"}}
```

Modes:

| Mode | Lasts | Use |
|---|---|---|
| `fortify` | while the containing status lasts | +N |
| `drain` | while the containing status lasts | −N |
| `damage` | until something listed in its `cleared_by` removes it; **outlives the fight** (stored on the character, saved) | lasting harm, e.g. a curse that eats Focus |
| `restore` | instant | brings a `damage`d or spent value back up; for resources this is "restore mana/stamina" |
| `absorb` | instant (resources) or held (others) | take N from the target and give it to `caster` |
| `set` | while the containing status lasts | forces a value; the highest-priority `set` wins |
| `multiply` | while the containing status lasts | ×N, for percentage effects |

**What clears a `damage`** (Olaf, 2026-11-25). A `damage`-mode modify carries
its own `cleared_by` list, so each effect says what heals it. Entries come from
one approved list:

```json
{"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 2,
 "cleared_by": [{"rest": "full"},
                {"heal": {"school": "white", "min_level": 5}},
                {"restore": "attribute.focus"},
                {"cleanse": {"category": "curse"}},
                {"service": "shrine"}]}
```

- `rest: camp|full`: that kind of rest clears it.
- `heal: {school, min_level}`: any heal from a spell at that level or above,
  optionally of a given school.
- `restore: <value path>`: a `restore` effect on that value (potions, spells).
- `cleanse: {category}`: removing statuses of that category also clears it;
  the damage remembers the categories of what caused it.
- `service: shrine|healer`: paid healing in towns.
- `time: {days}`: it fades on its own.

If `cleared_by` is omitted, the default is `[{rest: "full"}, {restore: <its own value>}]`.
`damage` entries live on the character (`character.damaged_values`, a list of
`{value, amount, cleared_by, source}`). The derived-stat function subtracts them
and the save file carries them. A party-screen line showing them is part of
stage 2. Applying `damage` to an enemy simply lasts until the fight ends.

Value paths, each namespace backed by an approved list:

| Namespace | Examples | Backed by |
|---|---|---|
| `attribute.` | `strength`, `focus`, `luck` | the 7 attributes; derived stats recompute |
| `skill.` | `swords`, `fire_magic` | skills.json (35); also counts toward element affinity |
| `resource.` | `hp`, `mana`, `stamina`, `temp_hp` | current values |
| `stat.` | `dodge`, `accuracy`, `armor`, `initiative`, `movement`, `crit_chance`, `spellpower`, `max_hp`, `damage_pct`, `mana_cost_pct`, `healing_pct` … | `CombatStats.MODIFIABLE` + `DERIVED`, merged into one list |
| `resist.` | any damage type, or `all_elemental` | damage_types.json |
| `propagation.` | `chain.count`, `pierce.count`, `bounce.count`, `split.count`, `cascade` | §4.5 |
| `spell.` | `power`, `cost_pct`, `duration`, `area` | per-cast adjustments, with `applies_to` |
| `party.` / `world.` | `travel_speed_pct`, `forage_pct`, `social_roll_pct` | the non-combat derived keys and `party_bonuses.gd` |

`applies_to` narrows a `modify` on `propagation.` or `spell.`, so it only
affects matching actions: `{tag, school, damage_type, attack: "melee"|"ranged"|"any", spell: <id>}`.

**`status`**: everything status_ops does today, under one op.
`{op: status, action: apply, status: "Burning", duration, stacks}` ·
`action: remove | steal | transfer | convert | consume`, with `select`
(`{names}` or `{tag}` + `count`) as in `status_ops.gd` today. `consume`
removes the selected statuses and feeds the count into a sibling effect's
`scale` (`per: consumed`). That is spontaneous_combustion, flash_of_radiance,
and any future "detonate".

**`move`**: `{op: move, mode: push | pull | scatter | teleport | swap | behind | adjacent, tiles, blocked_damage, variance, direction}`.
Merges `push`, `scatter`, `reposition` and `special.teleport_range`, on top of
`repositioning.gd`.

**`kill`**: `{op: kill}`, outright death. **`immune` defaults to
`["boss"]`** (see §7). Usually sits under a `save`.

**`summon`**, **`zone`**, **`aura`**, **`resurrect`**: as now, moved into op
form. `summon` gains `count`, `hp_pct` and `as: <template>`;
`raise_as` for death_bolt is `summon` with `from: corpse` under an `on_kill`
trigger.

**`cast`**: `{op: cast, spell, at: target | source | random_enemy, power_pct}`.
Lets a trigger, an item or a summon fire a spell. It covers ice_totem,
"echo" spells, and weapon procs that are really spells.

**`grant`**: the non-combat payouts, for events, quests and on-kill:
`{op: grant, gold | xp | item | trait | remove_trait | perk | karma | pressure}`.
`karma` takes realm deltas and stays invisible, as always. This replaces
the reward keys in `event_manager.gd` and `on_kill.gold`.

**Map ops** stay as they are, moved into op form: `reveal`, `translocate`,
`mob_effect`, `provision`.

**`cost`** (on a spell container, not an effect): `{mana, hp, stamina, pressure: {element: n}}`.
Mana is the default; the others enable blood magic, exhausting techniques, and
spells paid for in psychological pressure.

### 4.3 A spell

```json
"chain_lightning": {
  "name": "Chain Lightning", "schools": ["Air", "Sorcery"], "level": 7,
  "cost": {"mana": 135},
  "target": {"type": "single", "eligible": "enemy"},
  "delivery": {"kind": "bolt",
               "propagation": {"chain": {"count": {"base": 2, "per_spellpower": 0.1},
                                         "falloff": 0.15, "range": 3}}},
  "effects": [
    {"op": "damage", "amount": 70, "type": "lightning"},
    {"op": "status", "action": "apply", "status": "Stunned", "chance": 25}
  ],
  "description": "…", "notes": "…"
}
```

Two-branch save spells share one roll:

```json
"deathfog": { …,
  "save": {"stat": "constitution", "tier": "hard"},
  "effects": [
    {"op": "kill", "on_save": "fail"},
    {"op": "damage", "amount": {"pct_of": "target.max_hp", "value": 25}, "on_save": "pass"}
  ]
}
```

`area` is the old `aoe`, with `upgrade_scaling` strings replaced by numbers
(`grows_per_tier: {radius: 1}`). Note: spell upgrade tiers are **not
implemented today**; `upgrade_scaling` is read by nothing in the engine. This
design keeps the data in a clean shape and does not build upgrades.

`special` is **removed**. Each of its keys is one of the following:
- re-expressed as effects;
- dropped, because it was a stale note duplicating its status;
- moved to `notes`.

### 4.4 A status

```json
{
  "name": "Frozen", "icon": "❄",
  "polarity": "negative",
  "categories": ["magical", "elemental.water", "control"],
  "scope": "combat",
  "duration": {"kind": "spellpower"},
  "stacking": {"mode": "refresh"},
  "flags": ["cannot_act", "cannot_move"],
  "while_active": [
    {"op": "modify", "value": "resist.physical", "mode": "drain", "amount": 25}
  ],
  "triggers": [
    {"on": "damaged", "if": [{"damage_type": "crushing"}],
     "effects": [{"op": "damage", "amount": 20, "type": "crushing"},
                 {"op": "status", "action": "remove", "status": "Frozen"}]},
    {"on": "damaged", "if": [{"damage_type": "fire"}],
     "effects": [{"op": "status", "action": "remove", "status": "Frozen"}]}
  ],
  "save": {"stat": "constitution", "when": "turn_end"},
  "description": "…"
}
```

The fields:

| Field | Meaning |
|---|---|
| `polarity` | `positive` / `negative` / `neutral`. Replaces `type: buff/debuff` |
| `categories` | any number, from one approved list: `magical`, `physical`, `mental`, `disease`, `poison`, `curse`, `blessing`, `control`, `stance`, `transformation`, `stealth`, `shield`, `aura`, `wound`, `quest`, `elemental.<element>`. Replaces the single `category`, so a status can be a curse *and* mental. Dispel and cleanse select by these |
| `scope` | `combat` (gone when the fight ends) · `world` (lives on the map, ticks in steps/days; today's `overworld_statuses`) · `persistent` (survives combats and saves until removed or expired by its own rule: quest statuses, long curses, event buffs) |
| `duration.kind` | `turns`, `spellpower`, `until_save`, `until_destroyed`, `combats`, `rests`, `days`, `steps`, `permanent` |
| `stacking.mode` | `refresh`, `extend`, `stack` (with `max`, and magnitudes multiply by stacks), `independent`, `strongest` |
| `flags` | control states from an approved list: `cannot_act`, `cannot_move`, `cannot_cast`, `cannot_attack`, `skip_turn`, `random_target`, `random_movement`, `cannot_be_targeted`, `cannot_target_enemies`, `flying`, `phasing`, `stealthed`, `cannot_die`, `immune:<category or status>` … These are the yes/no effects. Everything with a number is a `modify` |
| `while_active` | effects held while the status is on; reversed when it ends (except `damage`-mode modifies) |
| `periodic` | `{when: turn_start / turn_end / step / rest, effects}`. Replaces `damage_per_turn`, `heal_per_turn` and `damage_increase_per_turn` (via `scale per: turn_active`) |
| `triggers` | `[{on, if, chance, effects, consume: true?}]`. Events from one approved list, built on `PERK_TRIGGERS`: `struck`, `damaged`, `hit`, `crit`, `kill`, `dodge`, `ally_damaged`, `ally_death`, `owner_death`, `enemy_enters_reach`, `casts`, `expire`, `turn_start`, `turn_end`, `combat_start`, `rest` |
| `save` | `{stat, tier, when}`: the target's chance to throw it off |
| `aura` | an auras.json id, as now |
| `spread` | `{to: adjacent / debuffed, chance, when}`. Burning's existing spread, made general (plague_waters, witch_fire) |
| `cleared_by` | the same list as a `damage` modify (§4.2): rest, heal of a level, restore, cleanse by category, service, time. On top of `duration`, it says what ends the status early. Most useful for `persistent` and `world` statuses (a quest curse that only a shrine lifts) |
| `decay` | optional `{per_turn: 0.25}`: magnitudes shrink each turn instead of switching off (impermanence) |

**Retaliation**, **expiry summons**, `death_on_expire`, `bleed_on_expire` and
`damage_on_expire` all become `triggers` (`on: struck` / `on: expire`).

**Intercepting triggers** *(builder-check answer; my call).* Some statuses act
on an attack or spell *before* it lands: reflect, auto-dodge, "next attack
misses", mirror images absorbing a hit, a shield pool, taunt redirecting a
target, riposte. Triggers have two phases:
- `on: "incoming_attack"` / `"incoming_spell"` / `"attacked_in_melee"` /
  `"ally_threatened"` run **before** resolution, and may use the intercept-only
  ops `negate`, `reflect`, `redirect {to}` and `absorb_into {pool}`;
- every other trigger runs after.

A free weapon attack is a new op, `attack {target, power_pct}`. With it, riposte,
counterstance and cleave-style follow-ups are data. **`reaction.gd` is folded in**:
its six statuses become intercepting triggers, and the `reaction` field goes
away. Its `auto_dodge` response is `negate`, and its `reposition` response is
`move`. Control-of-allegiance words (`controlled_by_caster`,
`treats_caster_as_ally`, `must_attack_taunter`) are `flags`, read by the AI and
targeting code. `linked_to_ally` / shared healing is a `link {to, share: heal|damage, pct}`
field on the status.

**Elemental reactions need no separate system.** They are triggers on statuses
with a `damage_type` condition, like Frozen above. Wet + lightning, Oily + fire
and Frozen + crushing are each a few lines of data.

**Anonymous statuses.** A `modify` with a `duration` written directly on a
spell, item or event ("Fortify Strength 5 for 3 turns", Morrowind-style) is
wrapped by the engine in a generated status. The name and icon come from the
value ("Fortified Strength"), and the categories come from the source
(`magical` for spells, `physical` for potions). That way dispel, the tooltip and
the icon row still work, and no one has to write a status for every potion.

### 4.5 Delivery and propagation

`delivery.kind`: `instant` (default; the effect just happens to the target(s)),
`bolt` (travels source to target, can be blocked), `projectile` (a persistent
object on the field with `moves` per turn and `turns`; ball_lightning,
searing_orb), `beam` (line), `touch` (melee reach).

`delivery.propagation`, where every entry is optional:

| Key | Fields | Meaning |
|---|---|---|
| `chain` | `count, range, falloff, prefer: nearest/random/lowest_hp, no_repeat` | after hitting, jumps to another eligible unit |
| `pierce` | `count` | passes through N units on its line |
| `bounce` | `count, range` | ricochets off an obstacle/unit, picking a new direction |
| `split` | `count, spread` | on impact, splits into N copies at reduced power |
| `cascade` | `on: hit/kill/crit, effects or spell, max` | each qualifying hit spawns more effects (death_shock: on kill, the same spell at the next target) |
| `linger` | `zone, turns` | the path or impact point leaves a zone |
| `return` | `true` | comes back to the caster, hitting again |

Every propagation number is a value path (`propagation.chain.count` …). A
`modify` with `applies_to` can therefore change it. A status "Arcing" (+1 chain
to lightning spells), an amulet that grants pierce to ranged attacks, or a perk
that makes kills cascade are all just data.

**Weapon attacks get an implicit delivery** (`touch` for melee, `bolt` for
ranged). That way `applies_to: {attack: "ranged"}` reaches arrows too. Building
propagation for attacks is stage 5; the vocabulary includes it from day one.

### 4.6 Items, perks, upgrades, events

- **Consumables**: `effect: {type: heal …}` becomes `effects: [...]` +
  `targeting`. Oils become a status with `scope: combat`,
  `duration: {kind: attacks, base: N}` and a `hit` trigger. Charms become a
  `modify` on `spell.cost_pct` / `spell.power` with `applies_to: {school}` and
  `consume` on cast.
- **Equipment passives** (`passive.status_immunity`, resistances…) become
  `while_equipped: [effects]` and `flags`. The equipment acts as a status
  container whose duration is "while worn".
- **Perks: not in this project** (Olaf, 2026-11-25; perk normalization
  follows later). Only 6 of 605 perks use the typed format; most passive
  behaviour is ~175 hard-coded `has_perk` branches, and ~101 active perks use
  `combat_data`. This project must **keep every perk working**. Perk code
  that asks a status for a bare word (`_unit_has_effect(unit, "x")`) is pointed
  at the matching flag or value path. Perk data stays as it is. The vocabulary
  is designed so perks *can* move onto it later. The intended mapping, for that
  project: `stat_bonus` → `modify fortify` (keeping `conditions` → `if`);
  `resistance` → `modify resist.`; `on_trigger` → `triggers`;
  `stat_conversion` keeps its own op (`convert_stat`) because no other system
  needs it; `non_combat` → `world.`/`party.` values. Active perk skill types
  (`_dispatch_skill_effect`, 30+ branches) become effect lists where they
  match an op, and keep a named handler only where truly unique.
- **Auras and zones** *(builder-check answer; my call)*: their payload format
  (`aura_system.gd`, shared by auras.json and zones.json) is replaced by effect
  lists (`while_inside`, `on_enter`, `on_death_inside` hold effects), so it does
  not survive as a seventh format. This happens in stage 2, alongside statuses,
  since auras already apply statuses.
- **Traits** (`stat_modifiers`, `skill_modifiers`), **talisman/equipment
  affixes**, **mantra bonuses** and **terrain/weather `status_chance`**:
  each becomes a container holding effects, in stage 4 (traits, affixes,
  mantras) and stage 5 (terrain/weather).
- **Upgrades**: `effects: {max_hp_percent: 10}` → `[{op: modify, value: stat.max_hp, mode: multiply, amount: 1.1}]`.
  Flags like `enables_manual_deployment` go in an approved `unlocks` list.
- **Events / quests**: `rewards` → `effects` (`grant`, `damage`, `heal`,
  `status apply` with a `persistent` or `world` status). `buffs` with
  `combats_remaining` become an anonymous persistent status with
  `duration: {kind: combats}`, replacing `GameState.active_map_buffs`.

## 5. Code shape

- `scripts/effects/effect_vocab.gd`: every approved list (ops, modes, value
  namespaces, flags, categories, triggers, conditions, propagation keys).
  `CombatStats` lists move here or are re-exported. Tools read this file, as
  they read `combat_stats.gd` today.
- `scripts/effects/effect_resolver.gd`: `resolve(effects, context)`, where
  context = source, target(s), container, cast power, save result. One
  function per op, each small. The existing modules (`status_ops`,
  `resource_ops`, `repositioning`, `resurrection`, `save_system`,
  `spell_damage`, `aoe_resolver`, `zone`, `aura_system`) are what the op
  functions call. They are kept, not rewritten.
- `scripts/effects/value_paths.gd`: reads and writes a value path on a unit or
  character. This is where `fortify/drain/set/multiply` holds are summed. It
  replaces `_get_status_stat_bonus`, `_get_stat_modifier_bonus`,
  `_unit_has_effect`, and the stat getters' status-word branches.
- `scripts/effects/propagation.gd`: chain, pierce, bounce, split, cascade,
  linger and return, reading the effective propagation (the base plus every
  matching `modify`).
- A **loader check**: each JSON file's effects are validated against
  `effect_vocab.gd` when it loads, with errors pushed loudly.
  `validate_data.py` gets the same check in Python, reading the GDScript lists
  as it does now.
- **A new verifier scene**, `tools/verify_effects.tscn`, added to `verify_all.sh`.
  It casts a sample of each op and each propagation key on a test arena and
  checks the numbers that come out.
- `tools/content/sections/spells.py` / `statuses.py`: the read-only summary
  line in `CONTENT.md` (`L7 · 135 mana · single enemy · 70 lightning`) is
  regenerated from the new fields. Writing fields (name, description, notes)
  are unchanged, so the content sync keeps working.

**As built in stage 1 (2026-11-25).** Names and scope that differ from the
list above:

- `effect_context.gd` (`EffectContext`) was added: it carries source, target,
  container, cast power, save result and `target_pos`. The resolver takes it as
  its second argument.
- `value_paths.gd` also holds the attribute and skill holds (through the shared
  `CombatStats.attribute_terms`), release at combat end, and the lasting
  `damaged_values` with `cleared_by`.
- `propagation.gd` and the loader check are not built yet; they belong to
  later stages. `EffectVocab.validate` exists and is mirrored in
  `tools/effect_check.py`.
- The resolver exposes `POSITION_OPS` and `target_pos`; `CombatManager` gained
  shared `zone_footprint()` and `zone_turns()` helpers.

## 6. Migration, in stages

Each stage ends with `verify_all.sh` green, the game booting and a fight
playable, and the old reader for that data **deleted**.

1. **Vocabulary, resolver, validator.** No content changes. The resolver is
   exercised by `verify_effects` with hand-written test effects.
2. **Statuses (189).** A migration script (`tools/migrate_effects.py`,
   re-runnable, writes the JSON, then `content_sync.py --write`) converts each
   bare word into flags or `modify` entries with **today's numbers** (the table
   in `_get_status_stat_bonus` is the source of truth). Then the
   word-reading code is removed.
3. **Spells (377).** The script converts the named blocks. Then the
   `special` keys are worked through by hand: about 45 spells need real
   mechanics built (chain, drain, bonus_vs, projectile, spread, scaling,
   conditions, cascade); stale notes are dropped; flavour goes to `notes`. After this
   stage `special` no longer exists and the validator rejects it.
4. **Items, upgrades, traits, affixes, mantras.** Consumables, oils, charms,
   equipment passives, upgrades, trait modifiers, talisman/equipment affixes,
   mantra bonuses. (Perks are not included; see §4.6.)
5. **Events, quests, world statuses, and propagation for weapon attacks.**
   `rewards` → effects, `active_map_buffs` and `overworld_statuses` → statuses
   with `scope`.
6. **Extensions** that need nothing new, only data, so they can be authored at
   any point after stage 3: elemental reactions on statuses, karma costs via
   `grant karma` on cast, non-mana `cost`, `decay`. Two need small new engine
   pieces and are **in vocabulary but optional to build**: `channel`
   (concentration, broken by damage) and `delay` (spell lands next turn).

## 7. Deliberate behaviour changes

Migration otherwise preserves numbers. These are the exceptions:

- **Statuses named for a number do what the name says.**
  `Finesse_Plus_2` → `fortify attribute.finesse 2` (and derived stats follow),
  instead of today's +5 dodge / +3 initiative. The same goes for
  `Strength_Plus_2`, `Constitution_Minus_2`, `Focus_Minus_2`, `Focus_Plus_3`,
  `Awareness_Plus_3` and `Fire_Resistance_25` (the `_50`/`_25` vulnerability
  statuses already do this).
- **`kill` does not work on bosses by default.** Today Midas Touch, Deathfog,
  Liberate and Doom can delete a boss on one failed save. A boss takes the
  `pass` branch instead.
- **The ~45 unbuilt mechanics start working** (chain lightning chains, life
  drain heals, smite hurts undead more…). This makes those spells stronger than
  they are now, which is the point. Their numbers are then reviewed with TODO §16.
- **`grounding`'s "removes all negatives"** stays as it is. It is a balance
  question for §16, not a migration one.

**Kept as today, on purpose** *(builder-check answer; my call).* The 14 spells
carrying `special.stun_chance` / `freeze_chance` (`true`, `"high"`,
`"upgrade_scaling"`) apply their status **every time** today, because the chance
key is unread. Migration keeps 100%. The `chance: 25` in the chain_lightning
example in §4.3 is illustrative only. Whether these become chances is a TODO
§16 decision.

**New numbers for newly-built mechanics.** Where an unbuilt mechanic carries no
number (`true`, `"spellpower"`, `"high"`), the builder picks a value that fits
the description and the level curve. Every such pick goes in one table at the
end of `SPELL_REVIEW_2026-11.md` ("placeholders to review") for Olaf to look over.
The examples in §4.3 are not specs: Deathfog keeps its cloud zone and duration.

## 8. Left to the builder

- Exact file split inside `scripts/effects/`, and whether `CombatStats`
  becomes a thin re-export or is folded in.
- The precise order of spells within stage 3 (grouping by mechanic, e.g. all
  chain-type spells together, is suggested).
- Migration script internals, as long as it is re-runnable and idempotent.
- Wording of generated anonymous-status names.
- How many test cases `verify_effects` carries per op, as long as every op,
  mode, flag family and propagation key has at least one.

**Attributes changed mid-fight** *(builder-check answer; my call on the
mechanics)*. Derived stats are computed outside combat today, by two different
formulas: `CharacterSystem` for the party and `EnemySystem` for enemies. A
`modify attribute.*` in combat needs them recomputed. The two formulas become
one function callable mid-fight, and the unit's derived values are refreshed
whenever an attribute hold changes. A `damage`-mode loss outlives the fight
(§4.2).

## 9. Open questions

**Answered by Olaf, 2026-11-25:**
1. Perks are a follow-up ("perk normalization"). Out of scope here; see §4.6.
2. `damage` stays on the character after the fight, until rest, healing or
   whatever its own `cleared_by` names. See §4.2.

Recorded for later:
- Spell upgrade tiers (single → area → all) are data-only today and stay so.
  When they are built, the TODO §16 concern about crowd control reaching "all
  enemies" applies.
- Whether `persistent` statuses should be visible in the party screen. They
  will exist after stage 5 and want a home.

---

## 10. Addendum — temporary boosts, uncapped skills, and seven extensions (2026-11-25)

Decided with Olaf after stage 1 merged. Order: **10.1 and 10.2 first** (stage
2a, its own plan), then statuses (stage 2b) carrying 10.3.

### 10.1 A temporary boost counts everywhere a real one does

Olaf: *a mantra yoga state giving a temporary +5 to a kind of magic — the
perks are not given, but the incremental stat bonuses are calculated, allowing
for extremely high stats for a bit. OP is good when it requires understanding
the system and playing it well.*

Stage 1 built `attribute.`/`skill.` holds, but a review found they reach only
part of the game. Every reader of a skill level or attribute must read the
**effective** value (base + equipment + traits + holds − damage):

| Reader | Today | After |
|---|---|---|
| `CombatManager._can_cast_spell` / `meets_spell_skill` in combat | raw `skills` | effective |
| `CombatManager._calculate_spell_bonus` (spellpower from skill levels) | raw `skills` | effective |
| Per-level skill bonuses (`update_derived_stats`, `EnemySystem`, `PartyBonuses`) | recomputed only outside combat | recomputed when a skill hold changes, mid-fight |
| Elemental affinity totals (`PerkSystem.calculate_element_affinity`) | raw skills | effective |
| Attribute readers outside the 8 derived terms: saves (`SaveSystem._attribute_of`), spell save DC, Strength damage, event/roll checks | raw attributes | effective |

**Not** counted (Olaf: "the perks of course are not given"): owning or being
offered perks, and *learning* a spell in a shop. Those use the bought (base)
level. *(My call for spell learning: a boost lets you cast above your level,
not buy above it.)*

### 10.2 Skill bonuses become a formula, with no cap (approach A)

Olaf: *no cap; values calculated by a formula, not stored statically — games
that expect and reward min-maxing are more fun and hackable.*

Today `perks.json → base_bonuses` stores a table per skill for levels 1–15 that
**stops growing at 10** (11–15 repeat 10), and the effective level is clamped to
[-5, 15]. After:

- Each stat of each skill is `{"curve": "climb"|"steady", "at_5": n, "at_10": n}`
  plus optional `"base"`, `"integer": true`, `"limit"`.
  - **climb** (59 of 70 stats): level ≤ 5 → `at_5 × L(L+1)/30`; level > 5 →
    `at_5 + (at_10 − at_5) × (L − 5)/5`. Continues past 10 at the same slope.
  - **steady** (11 of 70): `base + at_10 × L/10` (`at_5` unused).
  - `integer: true` floors the result (party size, skill-check bonus, duration turns).
  - `limit` is a natural bound, not a cap — set only where a value stops making
    sense: `mana_cost_reduction` stops at −100, and percentage *reductions* stop
    at 100. Every other stat is unbounded.
- The upper clamp on effective level is removed; the lower bound (−5, and
  `NEGATIVE_SKILL_PENALTIES`) stays.
- **Numbers at levels 1–10 move.** Fitted from the current tables, 66 of 70 stats
  land within 10% at every level. The common Swords-style curve is exact at
  1–5 and 10 and up to 4 lower at 6–9 (86/97/108/119 for 90/100/110/120). The migration
  produces a before/after table (`docs/plans/SKILL_CURVES_2026-11.md`) for Olaf to
  check, and `at_5`/`at_10` are the two numbers to tune per stat.
- XP purchase is unchanged — you still buy up to 10. Only boosts go beyond.

### 10.3 Seven extensions (all approved)

Built in stage 2b alongside statuses unless noted.

1. **Group targets.** Value paths naming a family: `skills.element.<element>`
   (the 7 skills of that element), `skills.magic`, `skills.combat`,
   `skills.general` (the categories in CLAUDE.md / skills.json), `attributes.all`.
   A hold on a group applies to each member.
2. **Affinity as a value.** `affinity.<element>` — fortify/drain the element
   total directly, without touching skills.
3. **Borrowed values.** A magnitude may read another unit's value path:
   `{"from": "caster.skill.leadership", "pct": 50}` — "allies gain half your
   Leadership". This is the `party_` bonus idea, as a status.
4. **Building states.** `stacking: {"mode": "stack", "max": N, "grow": {"on": <trigger>, "by": 1}}`
   — a state that grows each time a trigger fires (+1 Fire magic per fire spell
   cast, to +5).
5. **The comedown.** Statuses already get `triggers` with `on: expire`; the
   addendum makes it a documented pattern and tests it: a strong state whose
   expiry applies a drain or a pressure cost.
6. **Upkeep.** `upkeep: {"mana"|"stamina"|"hp": n, "per": "turn"}` on a status:
   paid at turn start; if it cannot be paid the status ends (and its comedown
   fires). This is the concentration idea, for states.
7. **Psychology as values.** `pressure.<element>` as a `modify` target, routed
   through `PsychologySystem.apply_pressure(character, element, amount)` —
   instant only (pressure is a resource, not a held stat). Prepares the klesha
   system in TODO Part II.

### 10.4 As built (stage 2a, 2026-11-25)

Names and details that differ from, or fill in, 10.1 and 10.2:

- The formula lives in `PerkSystem.curve_value`. The old table script
  `tools/update_perks_bonuses.py` is gone; `perks.json` is edited directly.
  The before/after table is `docs/plans/SKILL_CURVES_2026-11.md`.
- Attribute holds are written to
  `character_data.attribute_bonuses[attr]["effects"]`, next to the skill
  version. `ValuePaths.refresh_character(unit)` replaces the stage-1
  `refresh_attribute_deltas` and refreshes mid-fight, enemies included
  (through `EnemySystem.recalculate_derived`).
- `CharacterSystem.get_effective_attribute` is the single definition of an
  effective attribute, floored at 1.
- Bonus-only skills (a hold on a skill the character never bought) count
  fully, in `get_effective_skills` and `CombatManager.apply_skill_mana_reduction`.
- Known gaps are listed in TODO.md section 17, "Found during 2a".
