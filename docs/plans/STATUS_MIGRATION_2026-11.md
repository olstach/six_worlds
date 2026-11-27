# Status migration, November 2026 (effect normalization stage 2b)

The record of what became of every word in `resources/data/statuses.json`.
Statuses used to say what they did with a list of words (`effects`) that code
looked up by name. They are now containers of effects, like spells. This file
is appended to by each task of the migration:

- **Task 4** moved the numbers (stat words, resistances) into `while_active`.
- **Task 5** (this file's first big section) moved the yes/no words into
  `flags`, the hard-coded status-name lists into data, and removed the words
  nothing read.
- **Task 6** appends its section: the words that remain in `effects`.

`tools/migrate_statuses.py` does all of it, re-runnable and idempotent. The
statuses' original word lists are kept in `tools/fixtures/status_words.json`
(captured once, before the migration); `verify_effects` checks the data
against it (`flags_match_old_words`).

Line numbers: "was" is `scripts/` at commit `2b7654f` (before Task 5), "now"
is after it. Both are `file:line` under `scripts/`.

---

## Task 4: numbers

Source: `tools/migrate_statuses.py` (`STAT_TABLE`, `NAMED_ATTRIBUTE_WORDS`,
`MULTIPLY_WORDS`, `CATEGORY_TABLE`).

**Metadata.** `type` became `polarity` (buff = positive, debuff = negative).
`category` became `categories` (`cc`/`control`/`dot_cc`/`cc_dot`/`dot_disruption`
= `control`; `aura`, `stance`, `transformation`, `shield`, `stealth` keep their
word; `immunity`/`resistance`/`divine` = `blessing`; `protection` = `shield`;
`dot`, `hot`, `debuff`, `buff`, `vulnerability`, `delayed`, `terrain` = none).
`affliction` adds `poison` / `disease` / `wound`; a `<element>_damage_per_turn`
word adds `elemental.<element>`; everything `dispellable` gets `magical` (so
`magical` also covers Bleeding, Poisoned and Burning: an `immune:magical` flag
would be broad, and none exists). `duration_type` + `default_duration` became
`duration {kind, base}`; `stackable` became `stacking.mode`
(`independent` or `refresh`); statuses that live on the map are `scope: world`.

**Stat words.** Each word became a `while_active` `modify stat.<x>` with the
number of the deleted `CombatUnit._get_status_stat_bonus` table. A row with
several words counts once.

| Stat | Word : amount |
|---|---|
| `stat.initiative` | buffs_all_stats_considerably : +8; initiative_bonus : +5; initiative_penalty : -5; finesse_bonus : +3; awareness_penalty_major : -8; awareness_bonus_major : +8; minor_all_stats_bonus : +3; all_stats_penalty : -3 |
| `stat.movement` | speed_bonus : +2; speed_penalty : -1; major_speed_boost : +4 |
| `stat.accuracy` | buffs_all_stats_considerably : +8; attack_bonus : +10; attack_penalty : -10; melee_hit_chance_halved : -40; accuracy_bonus : +10; ranged_hit_chance_halved : -40; minor_all_stats_bonus : +5; all_stats_penalty : -5 |
| `stat.dodge` | buffs_all_stats_considerably : +8; dodge_bonus : +15; minor_dodge_bonus : +5; evasion_bonus : +25; dodge_penalty : -15; major_dodge_bonus : +30; finesse_bonus : +5; minor_all_stats_bonus : +5; all_stats_penalty : -5 |
| `stat.damage` | buffs_all_stats_considerably / buffs_two_highest_stats : +8; melee_damage_bonus : +5; damage_bonus : +5; damage_reduction : -5; strength_bonus : +3; strength_bonus_major : +8; ranged_damage_halved : -10; damage_boost : +15; minor_all_stats_bonus : +3; all_stats_penalty : -5 |
| `stat.armor` | buffs_all_stats_considerably : +8; defense_bonus : +10; defense_penalty : -10; armor_reduced_50 : -20; armor_reduced : -10; armor_bonus_minor : +5; minor_all_stats_bonus : +5; all_stats_penalty : -5 |
| `stat.crit_chance` | buffs_all_stats_considerably : +5; critical_boost : +10; critical_bonus_ranged : +8; luck_bonus : +5; minor_all_stats_bonus : +3 |
| `stat.spellpower` | buffs_all_stats_considerably / buffs_two_highest_stats : +8; awareness_bonus / focus_bonus : +3; focus_bonus_major : +8; focus_penalty : -3; focus_penalty_major : -8; awareness_penalty_major : -5; awareness_bonus_major : +5; minor_all_stats_bonus : +3; all_stats_penalty : -5 |

- `movement_reduced_50` became `modify stat.movement multiply 0.5` (a changed
  number: it now halves the total, where the old table subtracted half the
  base).
- **Spec section 7, statuses named for a number do what the name says.** A
  status whose word names an attribute and carries `bonus_amount` /
  `penalty_amount` became `modify attribute.<attribute>` of that amount instead
  of the table's stat numbers: `strength_bonus`, `finesse_bonus`, `focus_bonus`,
  `focus_penalty`, `awareness_bonus`, `constitution_bonus`,
  `constitution_penalty` (the Constitution words always, 2 points when no
  amount is given; `_reconcile_constitution_hp` is gone). Same word with no
  amount keeps the table's numbers.
- `grants_resistance` / `grants_vulnerability` became `modify resist.<type>`
  fortify / drain.
- `range_bonus` / `range_penalty` were in the table under "range", but no
  getter ever asked for it: they changed nothing, and were dropped (Precision,
  Range_Debuff). See "Words nothing read", below.

---

## Task 5: yes/no words become flags

A word whose readers only ask "does this unit carry a status with it?" became
a **flag** of the same name, in the status's `flags` list. Code asks
`StatusRules.has_flag(unit, "<flag>")` (or `has_any_flag`, `def_has_flag`,
`entry_with_flag` when it needs the entry, for example to find who cast it).
`EffectVocab.FLAGS` lists exactly these flags; `validate_data.py` fails on a
flag no code asks for, one no status carries, or one not in `FLAGS`.

`_unit_has_effect` and the load-time `blocks_actions` / `blocks_movement` /
`blocks_casting` / `blocks_attacks` derivation are deleted. What a status
blocks is read from its flags where it is asked:

| Question | Flags |
|---|---|
| can it act (`is_unit_incapacitated`, turn skip) | `skip_turn`, `cannot_act` |
| can it move (`can_unit_move`) | `cannot_move`, `rooted` |
| can it cast (`can_unit_cast`) | `cannot_cast` |
| can it attack (`can_unit_attack`) | `cannot_attack`, `will_not_attack` |

### Merges

Two words are merged into one flag only when every reader of both treats them
identically (same blocking code, same tooltip line).

| Words | Flag | Why identical |
|---|---|---|
| `immobilized` (Drowning), `cannot_move` | `cannot_move` | both derived `blocks_movement`; tooltip said "Cannot move" for both |
| `silenced` (Suffocating), `cannot_cast` | `cannot_cast` | both derived `blocks_casting`; tooltip said "Cannot cast spells" for both |

Looked at and **not merged** (a reader tells them apart): `skip_turn` /
`cannot_act` (tooltips differ), `rooted` / `cannot_move` (tooltip: "Rooted" vs
"Cannot move"), `will_not_attack` / `cannot_attack` (`get_cc_behavior` reads
`will_not_attack` as "pacified"), `immune_to_ground_effects` /
`immune_to_terrain_hazards` (tooltips differ), `treats_caster_as_ally` /
`will_not_attack_caster` and `attacks_closest_creature` / `ignores_allegiance`
(tooltip lines differ), `random_movement` / `random_target` (tooltips differ).

### Immunity words became `immune:` flags

`StatusRules.immune_to` (Task 3) replaces the four branches in
`CombatManager._apply_status_effect` (was `combat_manager.gd:5380-5396`).

| Word | Statuses | Flags |
|---|---|---|
| `immune_to_charm` | Mental_Immunity, Resolute | `immune:Charmed`, `immune:Dominated` (was `status in ["Charmed", "Dominated"]`) |
| `immune_to_fear` | Mental_Immunity, Resolute | `immune:Feared` (was `status in ["Feared"]`) |
| `immune_to_confusion` | Mental_Immunity, Resolute | `immune:Confused`, `immune:Chaotic` (was `status in ["Confused", "Chaotic"]`) |
| `debuff_immunity` | Cleansed | `immune:negative` (was `polarity == "negative"` and the word) |

`immune:magical` is not used: `magical` covers every dispellable status, which
includes Bleeding, Poisoned and Burning, and no code today is that broad.

### Hard-coded status-name lists became data

| Was | Flag | Statuses | Read at |
|---|---|---|---|
| the 15 names in `_apply_status_effect` (`combat_manager.gd:5452` refresh, `:5477` new) that break mantra concentration | `breaks_concentration` | Stunned, Feared, Charmed, Confused, Berserk, Frozen, Petrified, Held, Paralyzed, Immobilized, Dominated, Chaotic (Stun, Fear and Charm are in the old list but are not statuses) | `combat_manager.gd:5390`, `:5414` |
| `status == "Invisible" and is_stealthed` (`:5488`), `status_name == "Invisible"` on expiry (`:6072`), `not defender.has_status("Invisible")` (`:1962`), `has_status("Invisible")` in the stealth DC (`:8484`) | `grants_stealth` | Invisible | `combat_manager.gd:1925`, `:5424`, `:6006`, `:8402` |
| `has_status("Invisible")` when a stealth attack or cast spends the status (`:2118`, `:3820`) | `attack_breaks_invisibility` (an existing word, now with a reader) | Invisible | `combat_manager.gd:2080`, `:3775` |
| `has_status("Lifelink") or has_status("Blood_Hunger")` (`:2199`) | `lifesteals_on_hit` | Lifelink, Blood_Hunger | `combat_manager.gd:2156` |
| `has_status("Demoralized") or "Feared" or "Gloomy"` (`:9319`, the skill that needs a demoralised enemy) | `counts_as_demoralized` | Demoralized, Feared, Gloomy | `combat_manager.gd:9237` |
| `se.get("status") == "Charmed"` in the damage-from-the-charmer rule (`:2178`) | `breaks_on_damage_from_source` | Charmed | `combat_manager.gd:2138` |

Two small behaviours to know: `cannot_die` (Death_Immunity) had no reader but
the tooltip; `apply_damage` now reads it next to `hp_cannot_drop_below_1`
(Death_Immunity carries both, so nothing changes). `attack_breaks_invisibility`
had only a tooltip label; it now decides whether a stealth attack spends the
status.

**Other name tests, looked at and left.** These are rules about one named
status, not a class of statuses, and a flag would be a one-use alias for the
name: `status == "Burning"` + the Kindled perk (`:5406`);
`has_status("Frozen")` / `("Burning")` / `("Stunned")` / `("Dazed")` /
`("Bleeding")` / `("Glass_Globe")` / `("Crystal_Diadem")` in damage, perk and
spell rules (`combat_manager.gd:2724 2747 2800 2804 3006 3025 5034 5049 5162
10808 11150 11178 11190 11991`, `combat_unit.gd:917`); the Juggernaut and
Pain-Is-Just-Information perk lists of lowercase status names (`:10103`, and
below). They move with the perk normalization.

### Word by word

Every word that was in some status's `effects` at the start of Task 5 (the
numeric words of Task 4 are in their own section). "Was" and "Now" are
`file:line` under `scripts/`.

| Word | Statuses | Was | Now | Result |
|---|---|---|---|---|
| `adds_air_damage_to_attacks` | Electrified_Weapon | `autoload/combat_manager.gd:7234` | `autoload/combat_manager.gd:7167` | stays in `effects` → Task 6 |
| `adds_fire_damage_to_attacks` | Burning_Weapon, Solar_Form, Tongues_of_Fire | `autoload/combat_manager.gd:7233` | `autoload/combat_manager.gd:7166` | stays in `effects` → Task 6 |
| `attack_breaks_invisibility` | Invisible | `ui/tooltip_text.gd:46` | `ui/tooltip_text.gd:54`<br>`autoload/combat_manager.gd:2080`<br>`autoload/combat_manager.gd:3775` | flag `attack_breaks_invisibility` |
| `attack_damage_buff_when_ally_dies` | Ancestral_Vengeance | `autoload/combat_manager.gd:3247` | `autoload/combat_manager.gd:3202` | flag `attack_damage_buff_when_ally_dies` |
| `attack_reflect_chance` | Reflect | `autoload/combat_manager.gd:2058` | `autoload/combat_manager.gd:2019` | flag `attack_reflect_chance` |
| `attacks_closest_creature` | Berserk | `autoload/combat_manager.gd:7479` | `autoload/combat_manager.gd:7398` | flag `attacks_closest_creature` |
| `attacks_have_miss_chance` | Blurred | `autoload/combat_manager.gd:2536` | `autoload/combat_manager.gd:2493` | flag `attacks_have_miss_chance` |
| `black_damage_per_turn` | Rotting, Soul_Burning | `ui/tooltip_text.gd:30` | `ui/tooltip_text.gd:31` | stays in `effects` → Task 6 |
| `bleed_on_expire` | Infected | `ui/tooltip_text.gd:52`<br>`autoload/combat_manager.gd:6068` | `ui/tooltip_text.gd:35`<br>`autoload/combat_manager.gd:6002` | stays in `effects` → Task 6 |
| `breaks_on_offensive_action` | Sanctuary | `ui/tooltip_text.gd:47`<br>`autoload/combat_manager.gd:2020`<br>`autoload/combat_manager.gd:3812` | `ui/tooltip_text.gd:55`<br>`autoload/combat_manager.gd:1981`<br>`autoload/combat_manager.gd:3767` | flag `breaks_on_offensive_action` |
| `can_move` | Forgetful | none | none | unbuilt: removed (see below) |
| `can_move_through_enemies` | Smoke_Form, Phase_Wind | `autoload/combat_manager.gd:1663` | `autoload/combat_manager.gd:1626` | flag `can_move_through_enemies` |
| `can_walk_on_water` | Water_Walking | none | none | unbuilt: removed (see below) |
| `cannot_act` | Petrified, Held, Stunned, Paralyzed +2 | `ui/tooltip_text.gd:36`<br>`autoload/combat_manager.gd:316` | `ui/tooltip_text.gd:45`<br>`autoload/combat_manager.gd:5926`<br>`autoload/combat_manager.gd:7324` | flag `cannot_act` |
| `cannot_attack` | Forgetful, Subjugated | `ui/tooltip_text.gd:39`<br>`autoload/combat_manager.gd:337` | `ui/tooltip_text.gd:47`<br>`autoload/combat_manager.gd:7366` | flag `cannot_attack` |
| `cannot_be_targeted` | Invisible, Sanctuary, Caged | `combat/combat_unit.gd:445`<br>`ui/tooltip_text.gd:40`<br>`autoload/combat_manager.gd:1962`<br>`autoload/combat_manager.gd:6072` | `combat/combat_unit.gd:445`<br>`ui/tooltip_text.gd:48`<br>`autoload/combat_manager.gd:1925` | flag `cannot_be_targeted` |
| `cannot_cast` | Silenced, Forgetful | `ui/tooltip_text.gd:37`<br>`autoload/combat_manager.gd:330` | `ui/tooltip_text.gd:46`<br>`autoload/combat_manager.gd:7352` | flag `cannot_cast` |
| `cannot_deal_physical` | Thin_Air | `autoload/combat_manager.gd:2567` | `autoload/combat_manager.gd:2524` | flag `cannot_deal_physical` |
| `cannot_die` | Death_Immunity | `ui/tooltip_text.gd:41` | `ui/tooltip_text.gd:49`<br>`autoload/combat_manager.gd:2927` | flag `cannot_die` |
| `cannot_flee` | Wrathfully_Bound | none | none | unbuilt: removed (see below) |
| `cannot_fly` | Grounded | none | none | unbuilt: removed (see below) |
| `cannot_make_weapon_attacks` | Disarmed | `autoload/combat_manager.gd:1953` | `autoload/combat_manager.gd:1916` | flag `cannot_make_weapon_attacks` |
| `cannot_move` | Rooted, Held, Paralyzed, Caged +6 | `ui/tooltip_text.gd:34`<br>`autoload/combat_manager.gd:323` | `ui/tooltip_text.gd:44`<br>`autoload/combat_manager.gd:7338` | flag `cannot_move` |
| `cannot_target_enemies` | Sanctuary | `autoload/combat_manager.gd:1958`<br>`autoload/combat_manager.gd:3804` | `autoload/combat_manager.gd:1921`<br>`autoload/combat_manager.gd:3759` | flag `cannot_target_enemies` |
| `cannot_target_spells` | Blinded | none | none | unbuilt: removed (see below) |
| `cannot_teleport` | Wrathfully_Bound | none | none | unbuilt: removed (see below) |
| `cannot_use_ranged` | Blinded | `autoload/combat_manager.gd:1984` | `autoload/combat_manager.gd:1945` | flag `cannot_use_ranged` |
| `charm_chance_on_enemy_melee_approach` | Magnetizing_Aura | `autoload/combat_manager.gd:7214` | `autoload/combat_manager.gd:7147` | flag `charm_chance_on_enemy_melee_approach` |
| `controlled_by_caster` | Dominated | `autoload/combat_manager.gd:1440` | `autoload/combat_manager.gd:1408` | flag `controlled_by_caster` |
| `copies_absorb_attacks` | Mirror_Images | `autoload/combat_manager.gd:2051`<br>`autoload/combat_manager.gd:3075` | `autoload/combat_manager.gd:2012`<br>`autoload/combat_manager.gd:3032` | flag `copies_absorb_attacks` |
| `crit_vulnerability` | Marked_for_Death | `autoload/combat_manager.gd:2639` | `autoload/combat_manager.gd:2596` | flag `crit_vulnerability` |
| `damage_increases_each_turn` | Festering | none | none | unbuilt: removed (see below) |
| `damage_on_expire` | Infected | `ui/tooltip_text.gd:51`<br>`autoload/combat_manager.gd:6064` | `ui/tooltip_text.gd:34`<br>`autoload/combat_manager.gd:5998` | stays in `effects` → Task 6 |
| `damage_on_move_attempt` | Shadow_Pinned | `autoload/combat_manager.gd:1678` | `autoload/combat_manager.gd:1641` | flag `damage_on_move_attempt` |
| `damage_taken_increase` | Marked_for_Death | `autoload/combat_manager.gd:2885` | `autoload/combat_manager.gd:2842` | flag `damage_taken_increase` |
| `death_on_expire` | Doomed | `ui/tooltip_text.gd:50`<br>`autoload/combat_manager.gd:6060` | `ui/tooltip_text.gd:33`<br>`autoload/combat_manager.gd:5994` | stays in `effects` → Task 6 |
| `death_resistance` | Ancestors_Blessing | `autoload/combat_manager.gd:2951`<br>`autoload/combat_manager.gd:2955` | `autoload/combat_manager.gd:2908`<br>`autoload/combat_manager.gd:2910` | flag `death_resistance` |
| `debuff_immunity` | Cleansed | `autoload/combat_manager.gd:5380` | `effects/status_rules.gd:111`<br>`autoload/combat_manager.gd:5338` | flags `immune:negative` |
| `disengaged_from_combat` | Pacified | `autoload/combat_manager.gd:7487` | `autoload/combat_manager.gd:7406` | flag `disengaged_from_combat` |
| `fire_damage_per_turn` | Burning | `ui/tooltip_text.gd:27` | `ui/tooltip_text.gd:28` | stays in `effects` → Task 6 |
| `fire_damage_per_turn_internal` | Boiling_Blood | none | none | unbuilt: removed (see below) |
| `flee_from_source` | Feared | `ui/tooltip_text.gd:45`<br>`autoload/combat_manager.gd:7471`<br>`autoload/combat_manager.gd:7502` | `ui/tooltip_text.gd:53`<br>`autoload/combat_manager.gd:7390` | flag `flee_from_source` |
| `focus_save_on_damage` | Swarmed | `ui/tooltip_text.gd:54`<br>`autoload/combat_manager.gd:2963` | `ui/tooltip_text.gd:58`<br>`autoload/combat_manager.gd:2918` | flag `focus_save_on_damage` |
| `forced_movement_toward_target` | Lured | `autoload/combat_manager.gd:1447`<br>`autoload/combat_manager.gd:1451` | `autoload/combat_manager.gd:1415`<br>`autoload/combat_manager.gd:1416` | flag `forced_movement_toward_target` |
| `grants_extra_action` | Extra_Action | `autoload/combat_manager.gd:1414` | `autoload/combat_manager.gd:1384` | flag `grants_extra_action` |
| `grants_flight` | Flying, Storm_Lord, Lightning_Form | `combat/combat_unit.gd:562` | `combat/combat_unit.gd:561` | flag `grants_flight` |
| `heal_50_percent_of_damage_dealt` | Lifelink | none | none | unbuilt: removed (see below) |
| `heal_per_turn` | Regenerating | `ui/tooltip_text.gd:31`<br>`ui/tooltip_text.gd:177`<br>`ui/tooltip_text.gd:178`<br>`autoload/combat_manager.gd:5979`<br>`autoload/combat_manager.gd:5982` | `ui/tooltip_text.gd:32`<br>`ui/tooltip_text.gd:188`<br>`ui/tooltip_text.gd:189`<br>`autoload/combat_manager.gd:5915`<br>`autoload/combat_manager.gd:5918` | stays in `effects` → Task 6 |
| `hp_cannot_drop_below_1` | Death_Immunity, Invincible | `ui/tooltip_text.gd:42`<br>`autoload/combat_manager.gd:2970` | `ui/tooltip_text.gd:50`<br>`autoload/combat_manager.gd:2927` | flag `hp_cannot_drop_below_1` |
| `hp_shield` | Mantric_Armor | `autoload/combat_manager.gd:2931` | `autoload/combat_manager.gd:2888` | flag `hp_shield` |
| `ignores_allegiance` | Berserk | `autoload/combat_manager.gd:7479` | `autoload/combat_manager.gd:7398` | flag `ignores_allegiance` |
| `illusory_copies` | Mirror_Images | none | none | unbuilt: removed (see below) |
| `immobilized` | Drowning | `ui/tooltip_text.gd:35`<br>`autoload/combat_manager.gd:323` | `ui/tooltip_text.gd:44`<br>`autoload/combat_manager.gd:7338` | merged into flag `cannot_move` |
| `immune_to_charm` | Mental_Immunity, Resolute | `autoload/combat_manager.gd:5386` | `effects/status_rules.gd:111`<br>`autoload/combat_manager.gd:5338` | flags `immune:Charmed`, `immune:Dominated` |
| `immune_to_confusion` | Mental_Immunity, Resolute | `autoload/combat_manager.gd:5394` | `effects/status_rules.gd:111`<br>`autoload/combat_manager.gd:5338` | flags `immune:Confused`, `immune:Chaotic` |
| `immune_to_fear` | Mental_Immunity, Resolute | `autoload/combat_manager.gd:5390` | `effects/status_rules.gd:111`<br>`autoload/combat_manager.gd:5338` | flags `immune:Feared` |
| `immune_to_ground_effects` | Levitating, Flying | `ui/tooltip_text.gd:55`<br>`autoload/combat_manager.gd:7310` | `ui/tooltip_text.gd:59`<br>`autoload/combat_manager.gd:7243` | flag `immune_to_ground_effects` |
| `immune_to_melee_unless_flyer` | Flying | `autoload/combat_manager.gd:2009` | `autoload/combat_manager.gd:1970` | flag `immune_to_melee_unless_flyer` |
| `immune_to_ranged` | Storm_Lord | `autoload/combat_manager.gd:1987` | `autoload/combat_manager.gd:1948` | flag `immune_to_ranged` |
| `immune_to_terrain_hazards` | Levitating | `autoload/combat_manager.gd:7310` | `autoload/combat_manager.gd:7243` | flag `immune_to_terrain_hazards` |
| `immune_to_water_terrain` | Water_Walking | `autoload/combat_manager.gd:7315` | `autoload/combat_manager.gd:7248` | flag `immune_to_water_terrain` |
| `increase_burning_damage_dealt` | Fan_the_Flames | `autoload/combat_manager.gd:5973` | `autoload/combat_manager.gd:5909` | flag `increase_burning_damage_dealt` |
| `joins_party_permanently` | Dominated | none | none | unbuilt: removed (see below) |
| `knockback` | Pushed | none | none | unbuilt: removed (see below) |
| `lifesteal_on_attacks` | Blood_Hunger | none | none | unbuilt: removed (see below) |
| `linked_to_ally` | Karmic_Bond | none | none | unbuilt: removed (see below) |
| `loses_flight` | Grounded | `combat/combat_unit.gd:564` | `combat/combat_unit.gd:563` | flag `loses_flight` |
| `must_attack_taunter` | Taunt | `combat/combat_arena.gd:4011`<br>`combat/combat_arena.gd:4509` | `combat/combat_arena.gd:4011`<br>`combat/combat_arena.gd:4509` | flag `must_attack_taunter` |
| `next_attack_misses` | Force_Miss | `autoload/combat_manager.gd:2038` | `autoload/combat_manager.gd:1999` | flag `next_attack_misses` |
| `next_ranged_guaranteed_hit` | Blessed_Shot | `autoload/combat_manager.gd:2045` | `autoload/combat_manager.gd:2006` | flag `next_ranged_guaranteed_hit` |
| `physical_damage_per_turn` | Bleeding, Drowning, Swarmed, Suffocating | `ui/tooltip_text.gd:29` | `ui/tooltip_text.gd:30` | stays in `effects` → Task 6 |
| `poison_damage_per_turn` | Poisoned, Festering, Diseased | `ui/tooltip_text.gd:28` | `ui/tooltip_text.gd:29` | stays in `effects` → Task 6 |
| `prevents_teleportation` | Anchored | `autoload/combat_manager.gd:11371` | `autoload/combat_manager.gd:11289` | flag `prevents_teleportation` |
| `prone_chance_on_movement` | Slippery_Terrain | `autoload/combat_manager.gd:1700` | `autoload/combat_manager.gd:1663` | flag `prone_chance_on_movement` |
| `random_attacks` | Chaotic | none | none | unbuilt: removed (see below) |
| `random_movement` | Confused, Chaotic | `ui/tooltip_text.gd:43`<br>`autoload/combat_manager.gd:7475` | `ui/tooltip_text.gd:51`<br>`autoload/combat_manager.gd:7394` | flag `random_movement` |
| `random_spellcasting` | Chaotic | none | none | unbuilt: removed (see below) |
| `random_target` | Confused | `ui/tooltip_text.gd:44`<br>`autoload/combat_manager.gd:7475` | `ui/tooltip_text.gd:52`<br>`autoload/combat_manager.gd:7394` | flag `random_target` |
| `ranged_damage_reduction` | Air_Shield | `autoload/combat_manager.gd:2090` | `autoload/combat_manager.gd:2051` | flag `ranged_damage_reduction` |
| `relationship_bonus` | Friendly | none | none | unbuilt: removed (see below) |
| `remove_all_debuffs` | Cleansed | `autoload/combat_manager.gd:5482` | `autoload/combat_manager.gd:5418` | flag `remove_all_debuffs` |
| `return_on_death_next_turn` | Eternal_Vow | `autoload/combat_manager.gd:3091`<br>`autoload/combat_manager.gd:3097` | `autoload/combat_manager.gd:3048`<br>`autoload/combat_manager.gd:3052` | flag `return_on_death_next_turn` |
| `return_with_20_percent_hp` | Eternal_Vow | none | none | unbuilt: removed (see below) |
| `riposte_next_sword_attack` | Riposte_Ready | `autoload/combat_manager.gd:2102` | `autoload/combat_manager.gd:2063` | flag `riposte_next_sword_attack` |
| `rooted` | Shadow_Pinned | `autoload/combat_manager.gd:323`<br>`autoload/combat_manager.gd:10103` | `autoload/combat_manager.gd:7338` | flag `rooted` |
| `save_at_end_of_turn` | Stunned | `ui/tooltip_text.gd:62`<br>`ui/tooltip_text.gd:114`<br>`autoload/combat_manager.gd:5995` | `ui/tooltip_text.gd:73`<br>`ui/tooltip_text.gd:125`<br>`autoload/combat_manager.gd:5931` | stays in `effects` → Task 6 |
| `share_healing_75_percent` | Karmic_Bond | `autoload/combat_manager.gd:4611`<br>`autoload/combat_manager.gd:4617` | `autoload/combat_manager.gd:4566`<br>`autoload/combat_manager.gd:4572` | flag `share_healing_75_percent` |
| `silenced` | Suffocating | `ui/tooltip_text.gd:38`<br>`autoload/combat_manager.gd:330` | `ui/tooltip_text.gd:46`<br>`autoload/combat_manager.gd:7352` | merged into flag `cannot_cast` |
| `skip_next_action` | Prone, Knocked_Down | `ui/tooltip_text.gd:33`<br>`autoload/combat_manager.gd:1421`<br>`autoload/combat_manager.gd:1426` | `ui/tooltip_text.gd:43`<br>`autoload/combat_manager.gd:1391`<br>`autoload/combat_manager.gd:1394` | flag `skip_next_action` |
| `skip_turn` | Frozen, Petrified, Stunned, Time_Stopped | `ui/tooltip_text.gd:32`<br>`autoload/combat_manager.gd:316` | `ui/tooltip_text.gd:42`<br>`autoload/combat_manager.gd:5926`<br>`autoload/combat_manager.gd:7324` | flag `skip_turn` |
| `space_damage_per_turn` | Wrathfully_Bound | `autoload/combat_manager.gd:5895` (`_dot_element`, by its `_damage_per_turn` suffix; no literal) | `autoload/combat_manager.gd:5826-5836` (same) | **had a reader** (one of the plan's "read nowhere" 20): hook reader, stays in `effects` → Task 6 |
| `spell_damage_reduction` | Magic_Shield, Golden_Defense | `autoload/combat_manager.gd:4547` | `autoload/combat_manager.gd:4502` | flag `spell_damage_reduction` |
| `spell_reflect_chance` | Magic_Mirror | `autoload/combat_manager.gd:4501` | `autoload/combat_manager.gd:4456` | flag `spell_reflect_chance` |
| `stat_penalties` | Diseased | none | none | unbuilt: removed (see below) |
| `stealth_bonus` | Chameleon, Shadow_Cloaked | `autoload/combat_manager.gd:4969`<br>`autoload/combat_manager.gd:8512` | `autoload/combat_manager.gd:8430` | flag `stealth_bonus` |
| `stun_chance_on_hit` | Electrified_Weapon | `autoload/combat_manager.gd:11015` | `autoload/combat_manager.gd:10933` | flag `stun_chance_on_hit` |
| `treats_caster_as_ally` | Charmed | `ui/tooltip_text.gd:48`<br>`autoload/combat_manager.gd:7483`<br>`autoload/combat_manager.gd:7504` | `ui/tooltip_text.gd:56`<br>`autoload/combat_manager.gd:7402` | flag `treats_caster_as_ally` |
| `will_not_attack` | Pacified | `autoload/combat_manager.gd:337`<br>`autoload/combat_manager.gd:7487` | `autoload/combat_manager.gd:7366`<br>`autoload/combat_manager.gd:7406` | flag `will_not_attack` |
| `will_not_attack_caster` | Charmed | `ui/tooltip_text.gd:49`<br>`autoload/combat_manager.gd:7483`<br>`autoload/combat_manager.gd:7504` | `ui/tooltip_text.gd:57`<br>`autoload/combat_manager.gd:7402` | flag `will_not_attack_caster` |

### Words nothing read (unbuilt)

These 21 words had no reader anywhere (no `_unit_has_effect`, no `in effects`,
no tooltip label). They are removed from the data; each status that had one
says so in its `notes` ("Unbuilt: ..."), and TODO section 16 lists them as
"Status mechanics never built". `range_bonus` and `range_penalty` were dropped
by Task 4 (in the old stat table, but no getter asked for "range"); Task 5
adds them to the same notes and TODO table.

| Word | Status | What it promised |
|---|---|---|
| `can_move` | Forgetful | can still move while it cannot attack or cast |
| `cannot_target_spells` | Blinded | cannot aim spells |
| `fire_damage_per_turn_internal` | Boiling_Blood | fire damage from within. Its `damage_per_turn` (15) is dealt as physical damage, because `_dot_element` only reads words that END in `_damage_per_turn` |
| `joins_party_permanently` | Dominated | the dominated creature stays after combat |
| `damage_increases_each_turn` | Festering | the DoT grows (the separate `damage_increase_per_turn` key is also unread; Task 6) |
| `stat_penalties` | Diseased | unspecified stat penalties |
| `illusory_copies` | Mirror_Images | the copies themselves (the absorbing is `copies_absorb_attacks`) |
| `cannot_teleport` | Wrathfully_Bound | no teleporting (Anchored's `prevents_teleportation` does work) |
| `cannot_flee` | Wrathfully_Bound | cannot leave the fight |
| `random_attacks` | Chaotic | attacks pick random targets (`random_target` does that on Confused) |
| `random_spellcasting` | Chaotic | casts random spells |
| `relationship_bonus` | Friendly | better relations with NPCs |
| `heal_50_percent_of_damage_dealt` | Lifelink | the lifesteal itself. It works, by status name: now the flag `lifesteals_on_hit` |
| `linked_to_ally` | Karmic_Bond | the link to a chosen ally (the 75% healing share is `share_healing_75_percent`) |
| `return_with_20_percent_hp` | Eternal_Vow | returning at 20% HP (the code does this for `return_on_death_next_turn`) |
| `lifesteal_on_attacks` | Blood_Hunger | the lifesteal itself: now the flag `lifesteals_on_hit` |
| `cannot_fly` | Grounded | no flight (Grounded's `loses_flight` does work) |
| `knockback` | Pushed | the push itself (forced movement is done by the Repositioning ops, not by this word) |
| `can_walk_on_water` | Water_Walking | walking on water (`immune_to_water_terrain` does the terrain part) |
| `range_bonus` | Precision | +range (dropped in Task 4) |
| `range_penalty` | Range_Debuff | -range (dropped in Task 4) |

One of the twenty words in the plan, `space_damage_per_turn` (Wrathfully_Bound),
**turned out to have a reader**: `CombatManager._dot_element` reads the damage
type of any word ending `_damage_per_turn`, so the word is what makes
Wrathfully_Bound's 25 damage a space-damage tick instead of a physical one.
It is a hook reader (not a yes/no test), so it is treated like the other
damage-over-time words: it stays in `effects` for Task 6. `validate_data`'s
baseline had already excluded it for the same reason. (`fire_damage_per_turn_internal`
looks like it would be read the same way, but it ends in `_internal`, so it is
not.) That leaves 21 words removed instead of the plan's 20: the 19 left of the
plan's list after `space_damage_per_turn`, plus `range_bonus` and `range_penalty`.

Visible effect of the removals: `Boiling_Blood`'s floating text colour (from the
word "fire" in `fire_damage_per_turn_internal`) is now the polarity colour; its
tooltip loses the "Fire damage per turn internal" bullet. The other removed
words had no label either, so their tooltips lose a fallback bullet ("Stat
penalties", "Knockback", ...).

### Words left in `effects` for Task 6

A word with a reader that does more than answer yes/no stays in `effects`. All
twelve are read by a hook, a tick or a table:

| Word | Statuses | Reader | Why it stays |
|---|---|---|---|
| `fire_damage_per_turn`, `poison_damage_per_turn`, `physical_damage_per_turn`, `black_damage_per_turn`, `space_damage_per_turn` | Burning; Poisoned, Festering, Diseased; Bleeding, Drowning, Swarmed, Suffocating; Rotting, Soul_Burning; Wrathfully_Bound | `combat_manager.gd:5829` (`_dot_element`, gives the damage type), `tooltip_text.gd:182` (adds the number) | the word is the damage TYPE of the tick → `periodic` |
| `heal_per_turn` | Regenerating | `combat_manager.gd:5918` (the tick; also reads the `heal_per_turn` key), `tooltip_text.gd:188` (magnitude) | → `periodic` |
| `death_on_expire`, `damage_on_expire`, `bleed_on_expire` | Doomed; Infected | `combat_manager.gd:5991-6004` (`_on_status_expired`), `tooltip_text.gd:52` | expiry hook → `expire` trigger |
| `save_at_end_of_turn` | Stunned | `combat_manager.gd:5931` (also the `save_at_end_of_turn` key), `tooltip_text.gd:125` | end-of-turn save → `save` |
| `adds_fire_damage_to_attacks`, `adds_air_damage_to_attacks` | Burning_Weapon, Solar_Form, Tongues_of_Fire; Electrified_Weapon | `combat_manager.gd:7179` (`_process_status_weapon_enchants`, the word → damage-type table) | table lookup, adds a second damage hit → `hit` trigger |

**Task 6 should know:** these words are now **flags read by today's code**
(yes/no tests), and Task 6's table lists them as candidates for triggers and
intercepts. Task 5 moved them to flags rather than leave them in `effects`
(the plan deletes `_unit_has_effect`, and every one of these readers is a
plain "does the unit carry it" test):

- before-resolution: `next_attack_misses`, `next_ranged_guaranteed_hit`,
  `attack_reflect_chance`, `spell_reflect_chance`, `copies_absorb_attacks`,
  `hp_shield`, `attacks_have_miss_chance`, `immune_to_ranged`,
  `immune_to_melee_unless_flyer`, `riposte_next_sword_attack`;
- enchants and procs: `stun_chance_on_hit`, `increase_burning_damage_dealt`,
  `charm_chance_on_enemy_melee_approach`, `focus_save_on_damage`.

Where Task 6 builds an op that fully expresses today's code, delete the flag;
otherwise it is already the "flag read by today's code" the plan allows.
`copies_absorb_attacks` and `hp_shield` read the matching entry's `value`
(copy count, shield pool) through `StatusRules.entry_with_flag`.

### Tests

- `tools/verify_effects.gd`: `flags_match_old_words` (every status's `flags`
  and remaining `effects` against `tools/fixtures/status_words.json`, with the
  merges, name lists and unbuilt notes applied), `concentration_breaks_on_flag`,
  `mental_immunity_by_flag`.
- `tools/test_effect_vocab.py`: `test_flags_read_from_gdscript`.
- `tools/validate_data.py`: every `EffectVocab.FLAGS` entry must be asked for
  by a `has_flag(...)`-family call, be carried by some status, and match the
  data; the old "status effect" baseline (the 19 unread words) is deleted.

