# Spell audit — 2026-09-13

363 spells. The corpus is **not bloated** — that was my first hypothesis and it
was wrong. There is exactly one mechanically duplicated pair, nine spells thin
enough to have no identity, and a school-by-level spread that is close to even.

The problem is the opposite one. The spell list is **richer than the engine**.
Design intent was written into the data and never wired, and because every
reader uses `.get(key, default)`, none of it fails — it just quietly does
nothing.

**40 of 363 spells resolve to nothing at all when cast.** They deduct mana,
play no effect, and return success.

---

## 1. The headline: 40 inert spells

A spell "does something" if it has numeric damage, a heal, a summon, a status,
a damage-over-time, or a `special` key some code actually reads. These have
none of those. Verified twice: once by field, once by checking whether the
spell id is special-cased anywhere in `scripts/`. Neither `teleport` nor
`portal` is an exception — the string matches were the *targeting mode* of that
name and a map feature.

| Level | Count | Spells |
|---|---|---|
| L1 | 4 | `converse_with_the_dead` `get_out` `inner_flame` `jump` |
| L3 | 11 | `air_bomb` `behind_you` `blink` `burrow` `dispel` `flash_of_radiance` `grave_soil` `heat_transfer` `metal_to_mud` `sonic_boom` `spontaneous_combustion` |
| L5 | 6 | `clear_air` `gust_of_wind` `rain_of_mud` `shroud_of_darkness` `space_swap` `steal_blessings` |
| L7 | 10 | `dimensional_rift` `false_terrain` `intervention` `mana_drain` `radiant_visage` `raise_dead` `shining_mirage` `teleport` `tornado` `vajra_gate` |
| L9 | 9 | `breath_of_heaven` `dimensional_anchor` `implosion` `liberate` `midas_touch` `nail_the_sun` `planar_shift` `portal` `resurrect` |

**Nine of the 52 level-9 capstones are among them**, including `midas_touch` at
300 mana, and `resurrect` and `raise_dead` — which means the game has no working
resurrection at any tier.

The shape of the list is informative: it is dominated by **Space/Sorcery
movement and utility** (`blink`, `teleport`, `space_swap`, `portal`,
`planar_shift`, `intervention`, `get_out`, `nail_the_sun`, `behind_you`,
`burrow`). Those need bespoke resolvers, so they were skipped. Damage spells got
wired because damage is generic.

### Two that fail on a type guard

`_resolve_spell_damage()` reads:

```gdscript
var base_damage = spell.get("damage", null)
if base_damage != null and (base_damage is int or base_damage is float):
```

Seven spells carry a **string** where a number belongs, so the whole damage
block is skipped without a warning:

| Spell | `damage` value | Consequence |
|---|---|---|
| `implosion` | `"spellpower_scaling"` | L9, 225 mana, deals nothing |
| `sonic_boom` | `{"type": "space", "magnitude": "moderate"}` | L3, deals nothing |
| `liberate` | `"50%_max_hp"` | L9, deals nothing |
| `air_bomb` | `"fall_damage"` | payload is push, also unwired |
| `tornado` | `"fall_damage"` | same |
| `gust_of_wind` | `"impact_damage"` | same |
| `spontaneous_combustion` | `"burning_stacks_consumed"` | same |

These are not typos. Each names a **formula the engine does not have** —
spellpower scaling, percent-max-HP, fall damage, impact damage, stack
consumption. Four of the five formulas are worth building; they are exactly the
kind of nuance the audit was looking for.

---

## 2. 306 of 369 `special` sub-keys are read by nothing

`special` is where spell authors put everything the schema has no field for.
355 spell-instances carry at least one key nothing reads. Sorted by what they
are asking for:

### Forced movement — 17 keys, 15 spells. **The system exists.**

`push_distance` (6) · `obstacle_bonus_damage` (5) · `push_distance_min`/`max` ·
`pushes_enemies` · `launches_into_air` · `impact_damage_on_obstacle` ·
`scatter_to_random_tile` · `pushes_target` · `fall_damage` · `self_movement`

`surge`, `wave`, `tsunami`, `ripple`, `geyser`, `venomous_tide`, `gust_of_wind`,
`air_bomb`, `tornado`, `void_gust`, `jump`, `ball_lightning`.

`_displace_unit` and `_apply_push` have handled push, pull, blocked-damage and
collisions since the perk pass. **`surge` is the clearest case in the game**: a
level 1 Water spell dealing **5 damage** whose entire identity — push the target,
extra damage if they hit something — sits unread in `special`.

### Auras — 18 keys, 18 spells. **The system exists as of today.**

`heals_all_allies` (3) · `damages_all_enemies` (2) · `heals_allies` (2) ·
`aura_effect` · `aura_grants` · `aura_buff` · `aura_heals_allies` ·
`heal_per_turn_aura` · `aura_grants_blessed` · `small_buff_aura` ·
`healing_aura` · `allies_inside_protected` · `enemies_entering_damaged` ·
`fire_damage_reduction_in_aura` · `persistent_confusion_aura`

Several of these are the *original* spells the five old aura implementations
were written for, still carrying their pre-refactor description keys:
`soothing_presence`, `aura_of_blessing`, `favorable_wind`, `dampening_aura`,
`solar_form`. Those now work through `status.aura` and their `special` keys are
simply stale — **delete them**. The rest are real: `radiance`, `singing_birds`,
`guiding_light`, `vajra_mandala`, `radiant_visage`, `apsara`, `gandharva_host`.

`radiant_visage` reads *"Radiate an aura in a 2-tile radius: all allies within
gain immunity to mental debuffs, +2 AWR and +2 CON"*. That is an aura
declaration written in prose.

### Saving throws — 3 keys. **The system exists.**

`instant_kill_on_failed_save` (`deathfog`, `liberate`) ·
`damage_on_passed_save` (same two) · `triggers_focus_save` (`insect_swarm`)

Only **27 of 363** spells use `save_type` at all. Three more use a field spelled
`save` — `flash_freeze`, `sonic_boom`, `up_to_eleven` — which **nothing reads**,
so those three roll no save despite their descriptions promising one. One-line
fix, and a validator rule to stop it recurring.

### AoE and chaining — 10 keys, 9 spells. **The shapes exist.**

`damage_split` (4) · `chains_to_nearby_enemies` + `chain_count` +
`damage_reduction_per_chain` (`chain_lightning`) · `explosion_aoe` ·
`spreads_to_adjacent_enemies_each_turn` · `if_kills_chain_to_next_target`

Also worth recording: **zero spells use `falloff`**, and of 79 AoE spells, 61 are
circles. `arc`, `nova`, `band` and `cross` are barely touched. The shape
vocabulary is much richer than the spell list.

### Summon behaviour — 35 keys, 22 spells

`casts_black_magic`, `casts_fire_magic`, `casts_random_element`,
`vampiric_attack`, `high_dodge`, `low_hp`, `multiple_puppets`… Summons are
spawned from templates, and none of this per-spell tuning reaches them. This is
its own project and should probably become fields on the summon template rather
than the spell.

### Pure flavour — 20 keys, 27 spells. **Leave them.**

`creepy_circus_vibe`, `tentacles_and_eyes`, `rahula_like`, `from_outer_night`,
`man_bird_hybrid`, `note`, `visual`. These are author's notes and read fine as
such. They should be moved out of `special` into a `notes` field so the dead-key
count means something.

### Everything else — 203 keys, 133 spells

The long tail: `cloud_effect` (5, the cloud spells share a mechanic that does
not exist), `prevents_resurrection`, `bonus_damage_vs_undead_demons`,
`gold_on_kill`, `persistent_projectile`, `each_effect_independent_chance`.

---

## 3. To remove

Genuinely little. The nine spells with no mechanical content beyond a damage
number, and what to do with each:

| Spell | Level / schools | Verdict |
|---|---|---|
| `voidbolt` | L1 Black/Sorcery, 15 black | **Cut.** `bitter_word` is the same school pair at the same level with 12 damage *and* Silenced. Voidbolt is the duller twin. |
| `crushing_hand` | L1 Earth/Enchantment, 15 crushing melee | **Merge** with `stone_spike`. Earth does not need two identical 15-damage L1 nukes in two subschools. |
| `stone_spike` | L1 Earth/Sorcery, 15 piercing | **Keep one**, give it a rider — armour-pierce suits a spike. |
| `slashing_blade` | L3 Earth/Space/Sorcery | **Cut or rewrite.** Its description is `"Blade damage (+50% dmg/cost)"` — a balance note, not a spell. |
| `solar_spear` | L5 Fire/White, 60 solar | **Give identity.** `solar` is used by 4 spells; bonus damage vs undead and demons is the obvious one, and two other spells already declare it. |
| `vaporize` | L9 Fire/Sorcery, 150 fire | **Keep, deepen.** Fire needs a capstone nuke. "Leaves no corpse" ties it to the existing `prevents_resurrection` idea. |
| `implosion` | L9 Earth/Sorcery | **Fix first** — currently deals nothing. Then give it identity. |
| `radiant_visage` / `shining_mirage` | L7 Fire/Space/Enchantment | **Not duplicates.** My first pass flagged them because both put their whole payload in `special`. Both are well-written and both are inert. |
| `metal_to_mud` | L3 Earth/Water/Enchantment | Inert; described effect (reduce damage and armour on failed CON save) is two existing statuses away from working. |

Descriptions to rewrite regardless: `"Physical damage to one target"`,
`"Blade damage (+50% dmg/cost)"`, `"Massive fire damage to one target"`,
`"Solar damage, single target"`, `"Physical damage in melee range"`. Five
placeholder strings sitting in shipped content.

---

## 4. To expand

**The `domain` clusters are the best structural idea in the spell list and
should be the model.** Ten domains of exactly four spells each, cutting across
elements and subschools: smoke, mud, glass, crystal, steam, cloud, rainbow,
tummo, luminosity, sound. They give a caster something to specialise in that is
neither an element nor a school.

How much of each actually works:

| Working | Domain | |
|---|---|---|
| 1/4 | **tummo** | ✗ inner_flame ✗ heat_transfer ✗ flash_of_radiance ✓ blazing_and_dripping |
| 2/4 | mud | ✓ mudling ✗ metal_to_mud ✗ rain_of_mud ✓ mindmuck |
| 2/4 | luminosity | ✓ clear_mind ✓ divine_eye ✗ radiant_visage ✗ shining_mirage |
| 3/4 | sound | ✓ battle_chant ✓ eerie_dirge ✗ sonic_boom ✓ up_to_eleven |
| 4/4 | smoke, glass, crystal, steam, cloud, rainbow | all working |

**Tummo — inner heat, the most distinctively Vajrayana thing in the spell list —
is 1/4 working.** If any cluster deserves the first wiring pass, it is that one.

Candidate new domains, in the same shape: **bone** (charnel ground practice —
Black/Earth), **wind-horse / lungta** (Air/Enchantment, banners and fortune),
**mirror** (Space/White, reflection and illusion — the melong is already an
item), **charnel ground** as distinct from bone, **ash**.

### Coverage is fine, and I was wrong to suspect otherwise

Element × level is close to even (62–79 spells each). The thin-looking cells —
Water/White at 5, Earth/White at 5, Air/Black at 5 — are on inspection tight,
well-designed sets covering exactly their niche (purification, grounding,
suffocation). They do not need filling. Level 9 is thin by design at 52 spells.

---

## 5. Data hygiene

- `save` vs `save_type` — 3 spells use the unread spelling. **Bug.**
- 7 spells have a string `damage`. **Bug.**
- `permanent_until_used` duration is unread (1 spell).
- Compound damage types `fire_black`, `physical_fire`, `white_fire` exist
  alongside a `physical`/`crushing`/`slashing`/`piercing` split. Two different
  schemes; worth picking one.
- All `statuses_caused` resolve to real statuses. **No problems there.**
- `validate_data.py` should gain a spell pass: damage must be numeric, `save`
  must be `save_type`, and `special` keys should be checked against a list of
  the ones the engine reads, with a baseline for flavour keys.

---

## Suggested order

1. **The seven string-`damage` spells** — smallest fix, and two L9 capstones
   currently do nothing.
2. **`save` → `save_type`** on three spells, plus the validator rule.
3. **Forced movement** on the 15 spells that ask for it. The system is built and
   tested; this is data plus one resolver branch.
4. **Auras** on the ~13 real cases, and delete the 5 stale pre-refactor keys.
5. **Tummo**, then luminosity and mud — finish the domains that are half-built.
6. **Resurrection** (`raise_dead`, `resurrect`, `breath_of_heaven`,
   `eternal_vow`) — currently absent from the game at every tier.
7. Move flavour keys out of `special` into `notes`, so the dead-key count
   becomes a real signal.
