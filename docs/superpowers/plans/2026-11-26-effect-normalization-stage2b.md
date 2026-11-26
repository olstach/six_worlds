# Effect Normalization — Stage 2b: One Character Sheet, Statuses, Auras/Zones, Seven Extensions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enemies are built and derived from the same character sheet as the party. All 189 statuses, and the aura and zone payloads, are written in the shared effect language with today's numbers. The old status-word readers are deleted, and the seven approved extensions work.

**Architecture:**
- **Task 1** removes EnemySystem's parallel derived-stat path. An enemy dictionary becomes an ordinary character sheet, derived by `CharacterSystem.update_derived_stats`.
- **Tasks 2–3** add the status vocabulary and a status container. A status's `while_active` effects become ValuePaths holds keyed by the status instance and released on its single exit path. Its `flags` are read by one `StatusRules.has_flag`, and its `periodic` and `triggers` effects run through `EffectResolver`.
- **Tasks 4–6** migrate `statuses.json` in three slices, each deleting the reader it replaces:
  1. numbers (golden-file tested);
  2. yes/no words;
  3. behaviour words and `reaction.gd`.
- **Task 7** rebuilds every place that describes a status.
- **Task 8** moves auras and zones onto effect lists.
- **Tasks 9–10** add the seven extensions (spec §10.3).

**Tech Stack:** Godot 4.7 / GDScript, Python 3, `tools/verify_all.sh`.

**Spec:** `docs/superpowers/specs/2026-11-25-effect-normalization-design.md`:
- §4.4 (a status), §4.2 (`cleared_by`), §4.6 (auras and zones), §6 stage 2, §7 (deliberate changes), §8 ("Attributes changed mid-fight");
- §10.3 (seven extensions), §10.4 (as built in 2a).

Stage 2a is merged on `master` (`b535c03`).

**Olaf's ruling, 2026-11-26 (binding, extends the spec):** *"All characters should be generated from the same kind of character sheets, with any unique features expressed as stat-changing traits and such, so that everything is coherent, readable and modifiable via effects."*

## Global Constraints

- **Branch.** `git checkout -b normalization-stage2b` from `master`.
  - Olaf's uncommitted `project.godot`, `resources/data/companions.json` and `resources/data/shops.json` are **never staged**.
  - Every commit lists its files explicitly.
- **Data and the content sync.** After any JSON change from code, run `python3 tools/content_sync.py --write`.
  - The sync may change `CONTENT.md` and `tools/content_base.json`, and commits may include them (Olaf, 2026-11-25: do not stop for that).
  - Before the first data write of the stage, copy `CONTENT.md`, `tools/content_base.json`, `resources/data/statuses.json`, `auras.json`, `zones.json` and `resources/data/enemies/` to `.superpowers/backups/2026-11-26-before-stage2b/`. That folder is git-ignored. Never delete it, nor the 2a backup.
- **Numbers are preserved.** The only exceptions are:
  - spec §7 (statuses named for a number do what the name says);
  - this plan's Task 1 (enemies get the full sheet);
  - rulings recorded in a task report under "Changed numbers", each one listed.
- **The stage-1 rules still hold:**
  - lists in `EffectVocab` contain only what is built, and unknown names fail loudly;
  - every vocabulary change is mirrored in `tools/effect_check.py` and tested in `tools/test_effect_vocab.py` in the same task;
  - a new `class_name` commits `.godot/global_script_class_cache.cfg`;
  - use `not x in y`;
  - write `##` docs for a beginner-intermediate reader;
  - `tools/verify_all.sh` exits 0 at the end of every task.
- **Verifier assertions about today's behaviour are never weakened.**
  - A changed expectation is allowed only for a "Changed numbers" entry, and is listed in the report.
  - Existing verifiers (`verify_reactions`, `verify_resistance`, `verify_spells`, `verify_tooltips`, `verify_party_bonuses` …) must keep passing with their current assertions, unless a listed ruling changes them.
- **Saves.** Save/load tests use the scratch `SaveManager.SAVE_DIR`. **Never write to the real save folder.**
- **Status instance ids** have the form `"status:<n>"`, unique per combat. Hold sources for statuses use that id; for auras they are `"aura:<source instance id>:<aura id>"`.
- **Perks keep working.** Perk data is not migrated (spec §4.6). Perk code that asks a status for a bare word is pointed at the matching flag or value path.

## Review Focus

1. **Every exit path releases.** A status ending by expiry, dispel, cleanse, remove-by-name, steal/transfer, owner death or end of combat leaves no hold. After any exit, all eight `stat.` getters and the resistances equal their pre-status values. Tested in Task 3.
2. **Re-applying a refreshing status.** Applying a non-stacking status twice must not double its holds. A stacking status's holds scale with its stacks, and shrink when a stack is consumed. Tested in Task 3.
3. **Enemies with odd kit.** Bare-handed, tool-carrying, boss and no-armour enemies must derive without errors. They must have a weapon to attack with, and keep their archetype resistances. Tested in Task 1.
4. **An old save.** A party character from a pre-2b save, with no status instance ids, `effects` words or holds, loads and fights. Tested in Task 3.
5. **A status nobody described.** Most statuses have no `description`. Their tooltip and `CONTENT.md` line must still say in words what they do, from the new fields. Tested in Task 7.

---

### Task 1: Enemies use the one character sheet

**Files:**
- Modify: `scripts/autoload/enemy_system.gd`:
  - `_build_enemy` (about lines 924–1245): the sheet it assembles;
  - delete `_calculate_derived_stats`, `recalculate_derived` and `HOLD_DELTA_KEY`.
- Modify: `scripts/effects/value_paths.gd:217` (`refresh_character`). It calls `CharacterSystem.update_derived_stats(data)` for every unit, and the `_in_party` branch goes from this function.
- Modify: `scripts/autoload/character_system.gd` (`update_derived_stats`). Only where a sheet field is assumed to exist that an enemy legitimately lacks. Guard the read; never special-case "is enemy".
- Modify: `scripts/combat/combat_unit.gd` (`init_as_enemy`, `get_equipped_weapon`, resistance reads), wherever it reads enemy-only keys this task removes.
- Modify: `TODO.md` §17: move "enemy stale bonus names" from "waiting on Olaf" to done. Add the balance note: *enemies now receive the full per-level skill bonuses, elemental affinity, worn talisman and equipment stats; encounter budgets may need retuning*. Add an open item: *summons (`summon_templates.json`) onto the same sheet*.
- Modify: `CLAUDE.md` "Things to Remember". Add item 8: *one character sheet — party, companions and enemies are the same dictionary shape, derived by `CharacterSystem.update_derived_stats`; a unique feature is a trait, status or effect, never a parallel code path.*
- Test: `tools/verify_effects.gd` (new checks; the existing enemy-hold checks must pass unchanged).

**The sheet an enemy gets** (the same keys a party character uses):
- `equipment`: slot → item id. The weapon or tool it fights with goes in `weapon_main`, each armour piece in its own slot, and the talisman it bought in its talisman slot. They stay in `inventory` too, so they drop. The spare weapon stays inventory-only.
- `base_resistances`: the birth's racial resistances plus the archetype's `resistances`. Trait resistances arrive through `TraitSystem.get_resistances` inside `update_derived_stats`, as for the party. The top-level `resistances` key goes away, and every reader uses `derived.resistances`.
- The armour-piece loop stops adding piece stats into `derived` by hand. Equipment stats come from `ItemSystem.calculate_equipment_stats` via the slots.
- **`equipped_weapon` is removed wherever it duplicates a real item.**
  - Bare-handed enemies and the no-ItemSystem fallback have no real item, so they fight with their body plan's natural weapon (`BodySystem`).
  - If a species has no natural weapon data, add it to the body-plan data, never to code.
  - The "<name>'s Claws" naming stays, applied to whatever the unit reports as its natural weapon.
- After `update_derived_stats`, set current HP, mana and stamina to their maxima (an enemy enters a fight fresh).

**Interfaces:**
- Consumes: `CharacterSystem.update_derived_stats(character: Dictionary) -> void`, `ItemSystem.calculate_equipment_stats`, `ValuePaths.refresh_character(unit)`.
- Produces: `EnemySystem` builds sheets only. There is no derived-stat function in EnemySystem after this task. Later tasks may assume `derived.resistances` exists on every unit.

- [ ] **Step 1: Write the failing checks in `tools/verify_effects.gd`:**
  - `enemy_sheet_matches_party`: an enemy built from an archetype is compared with a party character dictionary given the same `attributes`, `skills`, `traits` and `equipment`. Run both through `update_derived_stats`. They must be equal on `max_hp`, `max_mana`, `max_stamina`, `initiative`, `movement`, `dodge`, `spellpower`, `crit_chance`, `damage`, `armor`, `accuracy`, `armor_pierce`, `mana_cost_reduction` and `resistances`.
  - `enemy_skill_accuracy`: an enemy with Swords 5 has `derived.accuracy` ≥ `PerkSystem.curve_value` of swords' accuracy at 5. This fails today, because of the stale name `attack`.
  - `enemy_kit_variants`: build one enemy of each kind (bare-handed, i.e. `no_equipment_chance` forced to 1; tool-carrier; boss; armour type `none`). Each has a non-empty weapon from `get_equipped_weapon()`, positive `max_hp`, and its archetype resistances in `derived.resistances`.
- [ ] **Step 2:** Run `godot --headless --path . tools/verify_effects.tscn`. Expected: the three new checks FAIL.
- [ ] **Step 3: Implement the sheet** as described above, and delete the EnemySystem derive functions.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: all checks pass, including the existing enemy-hold checks unchanged.
- [ ] **Step 5:** Record in the report, under "Changed numbers", the derived stats of three sample archetypes (one per realm) before and after.
- [ ] **Step 6:** Commit with the message `Effect normalization 2b: enemies use the one character sheet`.

---

### Task 2: Status vocabulary and validator

**Files:**
- Modify: `scripts/effects/effect_vocab.gd`. Add the lists below and `static func validate_status(def: Dictionary, where: String) -> Array[String]`.
- Modify: `tools/effect_check.py` (mirror), `tools/test_effect_vocab.py` and `tools/validate_data.py`. `validate_status` runs on every status that has `polarity`. From Task 6 onward every status must have it; Task 6 removes the "has polarity" gate.
- Modify: `scripts/effects/value_paths.gd` (`_entry_cleared_by`). Build the `cleanse` kind: `{"cleanse": {"category": c}}` matches when a removed status has category `c` among the categories recorded on the damage entry's `source_categories`. `apply_damage_mode` records `source_categories` from `ctx` when present.

**The lists** (each one holds only what is built by the end of the task that fills it):

| Const | Contents | Filled in |
|---|---|---|
| `POLARITIES` | `positive`, `negative`, `neutral` | Task 2 |
| `STATUS_CATEGORIES` | `magical`, `physical`, `mental`, `disease`, `poison`, `curse`, `blessing`, `control`, `stance`, `transformation`, `stealth`, `shield`, `aura`, `wound`, `quest`, plus `elemental.<element>` accepted by prefix (the 5 elements) | Task 2 |
| `SCOPES` | `combat`, `world`, `persistent` | Task 2 |
| `DURATION_KINDS` | `turns`, `spellpower`, `until_save`, `until_destroyed`, `permanent`, `instant` | Task 2 |
| `STACKING_MODES` | `refresh`, `stack` | Task 2 |
| `STATUS_FIELDS` | `name`, `icon`, `polarity`, `categories`, `scope`, `duration`, `stacking`, `flags`, `while_active`, `periodic`, `triggers`, `save`, `aura`, `spread`, `cleared_by`, `upkeep`, `link`, `description`, `notes`, plus the legacy fields still present until Task 6 removes them | Task 2; legacy entries are deleted in Tasks 4–6 |
| `FLAGS` | empty | Task 5 |
| `STATUS_TRIGGERS` | empty | Task 3 (`expire`, `turn_start`, `turn_end`), Task 6 (the rest) |
| `CLEARED_BY` | add `cleanse` | Task 2 |

`validate_status` checks:
- each field is in `STATUS_FIELDS`;
- `duration` is `{kind, base?}`, and `stacking` is `{mode, max?}`;
- `while_active` and `periodic.effects` go through `validate_list`;
- `while_active` modifies use a lasting mode (fortify, drain, set, multiply, damage);
- `flags` entries are in `FLAGS`, or `immune:<status name | category | polarity>`;
- triggers have `on` ∈ `STATUS_TRIGGERS`.

- [ ] **Step 1: Write the failing tests.** In `tools/test_effect_vocab.py`, add `test_status_valid_minimal` (`{name, icon, polarity: negative, categories: [control], scope: combat, duration: {kind: turns, base: 1}, stacking: {mode: refresh}}` passes). Also add `test_status_rejects`, one case per rule: unknown field, unknown category, `elemental.plasma`, a `while_active` modify with mode `restore`, unknown flag, unknown trigger, `stacking.mode: strongest`. In `verify_effects.gd`, add the same cases against `EffectVocab.validate_status`, plus `cleanse_clears_damage`.
- [ ] **Step 2:** Run `python3 tools/test_effect_vocab.py` and the verifier. Expected: FAIL.
- [ ] **Step 3: Implement** the lists, `validate_status`, the Python mirror and `cleanse`.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: status vocabulary and validator`.

---

### Task 3: The status container

**Files:**
- Create: `scripts/effects/status_rules.gd` (`class_name StatusRules`):
  - `static func has_flag(unit: Node, flag: String) -> bool` — any active status's `flags`;
  - `static func immune_to(unit: Node, status_name: String, def: Dictionary) -> bool` — an `immune:` flag matching the name, any of its categories, or its polarity;
  - `static func categories_of(def: Dictionary) -> Array[String]`;
  - `static func new_instance_id() -> String`.
- Modify: `scripts/autoload/combat_manager.gd`:
  1. `_apply_status_effect` (5338) is the **single entry**. It gives each new entry an `id`, resolves `while_active` through `EffectResolver.resolve` with `ctx.hold_source = id` and `ctx.caster = source`, and consults `StatusRules.immune_to` alongside the existing immunity checks.
  2. A new `_end_status(unit: Node, entry: Dictionary, reason: String) -> void` is the **single exit**. It releases holds (`ValuePaths.release(unit, entry.id)`), fires `expire` triggers when `reason` is `"expired"` or `"upkeep"`, and removes the entry. Every path that removes a status entry today goes through it: expiry in `_process_status_effects` and `_tick_durations_only`, `_remove_status_by_name`, `_remove_selected_statuses`, `_cleanse_status_effects`, steal/transfer/convert/consume in `_apply_status_op`, owner death, and `end_combat`. Find them all with `grep -n 'status_effects' scripts/`.
  3. Stacking: `stacking.mode: stack` re-resolves the holds with magnitudes × stacks whenever the stack count changes; `refresh` keeps the longer duration and does not touch holds.
  4. `periodic` (`{when: turn_start|turn_end, effects}`) is resolved in `_process_status_effects` at that point. `ctx.caster` is the entry's source, `ctx.target` the unit, and the entry is exposed to magnitudes (Task 6 reads it).
- Modify: `scripts/effects/effect_vocab.gd`: `STATUS_TRIGGERS` gets `expire`, `turn_start` and `turn_end`, and `SCALE_PER` gets `turn_active` (turns since the status was applied, read from the entry).
- Modify: `scripts/effects/effect_context.gd`: add `status_entry: Dictionary` (empty by default).
- Modify: `scripts/autoload/save_manager.gd` / the load path: entries without `id` get one. There are no saved holds to restore, because combat statuses end with combat.
- Test: `tools/verify_effects.gd`, using a helper `_with_test_status(def: Dictionary)`. It registers a test-only definition in `CombatManager._status_effects` under a name starting with `__test_` and removes it after the check.

**Interfaces:**
- Produces: `StatusRules.has_flag`, `StatusRules.immune_to`, and `CombatManager._end_status(unit, entry, reason)`. The reasons are `expired`, `dispelled`, `cleansed`, `removed`, `stolen`, `consumed`, `death`, `combat_end` and `upkeep`. Each status entry carries `id`, and `ctx.status_entry` carries the entry.

- [ ] **Step 1: Write the failing checks:**
  - `status_hold_applies_and_releases`: a status with `while_active` fortify `stat.dodge` 15 raises `get_dodge()` by exactly 15, and the value returns to base after `_end_status`.
  - `status_attribute_hold_refreshes`: fortify `attribute.constitution` 4 raises `max_hp` mid-fight, and max HP returns to base on the end.
  - `every_exit_releases`: one sub-case per reason in the Produces list. Each asserts all eight `stat.` getters and `Resistance` values equal the pre-status values.
  - `refresh_does_not_double`: applying the same refreshing status twice gives +15, not +30.
  - `stack_scales_holds`: a stacking status at 3 stacks gives 3×, and 2× after one stack is consumed.
  - `periodic_damage_ticks`: a periodic damage 5 at `turn_start` deals 5 at each turn start.
  - `immune_flag_blocks`: `immune:control` blocks a control-category status, and `immune:negative` blocks a negative one.
  - `old_save_entries_get_ids`: a character dictionary with legacy entries (no `id`) loads through the scratch-folder save/load, and its statuses can then be ended cleanly.
- [ ] **Step 2:** Run the verifier. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: status container (holds, single exit, periodic, immunity)`.

---

### Task 4: Migrate statuses — numbers

**Files:**
- Create: `tools/capture_status_baseline.gd` / `.tscn`, run once with today's code. It writes `tools/fixtures/status_baseline.json`: for every status, the change it causes on a reference party unit and a reference enemy to the eight `stat.` getters and every resistance, at duration 3, value 0 and default stacks. Commit the fixture **before** any migration.
- Create: `tools/migrate_statuses.py`. It is re-runnable and idempotent; Tasks 5 and 6 extend it. In this task it:
  - writes `polarity` (`buff` → `positive`, `debuff` → `negative`);
  - writes `categories` from the table below;
  - writes `scope: combat` (`world` for statuses whose name appears in `overworld_statuses` handling);
  - writes `duration` (`{kind: duration_type with fixed → turns, base: default_duration}`);
  - writes `stacking` (`stackable` → `stack`, else `refresh`);
  - converts every stat word in `CombatUnit._get_status_stat_bonus` (`combat_unit.gd:419-566`) to `while_active` modifies with **exactly** that table's numbers (one word may produce several modifies);
  - converts `grants_resistance` / `grants_vulnerability` to `modify resist.<type>` fortify/drain;
  - removes the converted words from `effects` and the converted keys.
- **Spec §7, the named statuses:** a status carrying `bonus_amount`/`penalty_amount` whose word names an attribute (`finesse_bonus`, `strength_bonus`, `constitution_bonus`/`_penalty`, `focus_bonus`/`_penalty`, `awareness_bonus`) becomes `modify attribute.<attr>` fortify/drain of that amount. It replaces the stat numbers. Delete `_reconcile_constitution_hp` once the Constitution hold path covers it. A status with the same word but no amount keeps today's stat numbers.
- `movement_reduced_50` becomes `modify stat.movement multiply 0.5`. This is a "Changed numbers" entry (it now halves the total instead of subtracting half the base).
- Category table (old `category` → new `categories`; `affliction` adds `poison`/`disease`; a damage-per-turn word adds `elemental.<element>` for an element type):

  | old | new |
  |---|---|
  | `cc` | `control` |
  | `dot`, `dot_debuff`, `hot`, `debuff`, `vulnerability`, `delayed`, `buff` | `[]` (plus the affliction/element additions) |
  | `dot_cc`, `cc_dot`, `dot_disruption` | `control` |
  | `aura`, `stance`, `transformation`, `shield`, `stealth` | same word |
  | `immunity`, `resistance`, `divine` | `blessing` |
  | `protection` | `shield` |

  Every status whose `dispel_methods` or `StatusOps.TAGS` membership marks it as magical (spell-applied and dispellable by `dispel`) also gets `magical`. Every status with `affliction: bleed` gets `wound`.
- **Invariant:** for each `StatusOps.TAGS` selector, the set of statuses it selects is identical before and after. Test it by running `StatusOps.select_from` over all definitions, against a fixture captured in Step 1.
- Modify: `scripts/combat/combat_unit.gd`: delete `_get_status_stat_bonus` and its term in every getter.
- Modify: `scripts/combat/resistance.gd`: delete the `grants_resistance` / `grants_vulnerability` reads (holds already flow through `ValuePaths`).
- Modify: `scripts/combat/status_ops.gd`: `matches`/`select` read `polarity`/`categories`.
- Modify: `resources/data/statuses.json` (by running the script, then `content_sync.py --write`).

- [ ] **Step 1:** Write and run the baseline scene. Also capture the TAGS-selection fixture. Commit both fixtures with the message `Effect normalization 2b: status baselines captured`.
- [ ] **Step 2: Write the failing check** `status_numbers_match_baseline` in `verify_effects.gd`. For every status it compares the eight getters and resistances to the fixture. The §7 statuses and `movement_reduced_50` are compared to their stated new values instead, with an explicit expected-value table in the check. Also add `status_tags_select_same`.
- [ ] **Step 3:** Run the migration, delete the readers, and run `content_sync.py --write`.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: statuses — numbers as effects`.

---

### Task 5: Migrate statuses — yes/no words become flags

**Files:**
- Modify: `tools/migrate_statuses.py`. Every word left in `effects` whose reader is a yes/no test (`_unit_has_effect(unit, "w")`, `"w" in def.effects`, `"w" in effects`, in any script, including `tooltip_text.gd`, `combat_arena.gd`, `combat_grid.gd`, `enemy_system.gd` and `main_menu.gd`) moves to `flags`.
  - **Flag names keep the word.** Exception: two words are merged into one flag only when every reader of both treats them identically. Each merge is listed in `docs/plans/STATUS_MIGRATION_2026-11.md`.
  - **Hard-coded status-name lists become data:**
    - The 15 hard-control statuses that break mantra concentration (`combat_manager.gd` around 5403 and 5422) get the flag `breaks_concentration`, and the code reads that flag.
    - `immune_to_charm`, `immune_to_fear`, `immune_to_confusion` and `debuff_immunity` become `immune:<status>` flags naming exactly today's statuses, and `immune:negative` for `debuff_immunity`. `StatusRules.immune_to` replaces those branches.
    - Any other `status in [...]` or `status == "Name"` test found in combat code that decides a behaviour gets a flag the same way, and each is listed in the doc.
  - **Words read nowhere** (the 20: `can_move`, `cannot_target_spells`, `fire_damage_per_turn_internal`, `joins_party_permanently`, `damage_increases_each_turn`, `stat_penalties`, `illusory_copies`, `space_damage_per_turn`, `cannot_teleport`, `cannot_flee`, `random_attacks`, `random_spellcasting`, `relationship_bonus`, `heal_50_percent_of_damage_dealt`, `linked_to_ally`, `return_with_20_percent_hp`, `lifesteal_on_attacks`, `cannot_fly`, `knockback`, `can_walk_on_water`) are removed from data. Each status that had one gets `notes: "Unbuilt: <words>"`. They are listed in a new TODO §16 table, "Status mechanics never built".
- Create: `docs/plans/STATUS_MIGRATION_2026-11.md`. For each word it gives the reader `file:line` and the result (flag / merged into / unbuilt). Tasks 4 and 6 append their own sections.
- Modify: `scripts/effects/effect_vocab.gd` (`FLAGS` = exactly the flags created here) and the Python mirror. `tools/validate_data.py` replaces `check_vocabulary("status effect", …)` with a check that each `FLAGS` entry has a reader (the same data→code grep, against `has_flag(…, "<flag>")`).
- Modify: every reader. `_unit_has_effect` is **deleted**; `is_targetable`, `can_unit_attack` / cast checks and the other yes/no readers use `StatusRules.has_flag`. `blocks_casting` / `blocks_attacks` def keys become the flags `cannot_cast` / `cannot_attack` if they are not already.

- [ ] **Step 1: Write the failing checks:**
  - `flags_match_old_words`: for each status, `flags` equals the old yes/no word set from the doc's mapping (merges applied). This reads a fixture `tools/fixtures/status_words.json` captured before the migration.
  - `concentration_breaks_on_flag`: a test status with `breaks_concentration` interrupts a mantra.
  - `mental_immunity_by_flag`: Mental_Immunity blocks Charmed and Feared.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3: Implement:** run the migration and switch the readers. `grep -rn '_unit_has_effect\|"effects", \[\]' scripts/` must show no status-word reader left for the words handled.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS, with `verify_reactions`, `verify_spells` and `verify_tooltips` assertions unchanged.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: statuses — flags`.

---

### Task 6: Migrate statuses — behaviour words, triggers, intercepts; `reaction.gd` folded in

**Files:**
- Modify: `scripts/effects/effect_resolver.gd`: magnitudes gain the `from` form. This is spec §10.3 extension 3, "borrowed values".
  - The shape is `{"from": "<source>", "pct"?: n, "default"?: n}`.
  - `<source>` is one of: `status.value` (the entry's `value`, which is how spells scale DOTs today); `status.stacks`; `caster.<value path>`; `target.<value path>`; `source.<value path>` (whoever triggered a trigger).
  - It is validated in `EffectVocab` and mirrored in Python.
- Modify: `tools/migrate_statuses.py`. Every remaining word and legacy key becomes one of the following, with today's behaviour:

  | Today | Becomes |
  |---|---|
  | `damage_per_turn` / `*_damage_per_turn` words, `heal_per_turn`, `damage_increase_per_turn` | `periodic` at today's tick point; amount `{from: status.value, default: <damage_per_turn>}`; type from the word (`_dot_element`); growth via `scale {per: turn_active}` |
  | `retaliation` | trigger `on: struck` with `damage` / `status` effects and today's numbers (reflect % uses `{from: source…}` or a `pct_of` on the incoming damage; add the source the code needs, and list it) |
  | `summon_on_expire`, `death_on_expire`, `damage_on_expire`, `bleed_on_expire` | trigger `on: expire` with `summon` / `kill` / `damage` / `status` |
  | `spread` | the `spread` field `{to, chance, when}`, read by `_process_status_spread` |
  | `save_type`, `save_at_end_of_turn`, `focus_save_on_damage` | `save {stat, tier, when}` |
  | `reaction` (6 statuses) | intercepting triggers: `on` ∈ `attacked_in_melee`, `enemy_enters_reach`, `ally_threatened`, with `reach`; ops `attack {target, power_pct}`, `negate` (was `auto_dodge`), `move` (was `reposition`), `status`; `limit {per: "turn", count}` replaces `max_per_round` (default 3, as `Reaction.DEFAULT_MAX_PER_ROUND`) |
  | before-resolution words (`next_attack_misses`, `spell_reflect_chance`, `attack_reflect_chance`, `copies_absorb_attacks`, `hp_shield`, `attacks_have_miss_chance`, `immune_to_ranged`, `immune_to_melee_unless_flyer`, `riposte_next_sword_attack`, `next_ranged_guaranteed_hit`) | intercepting triggers `on: incoming_attack` / `incoming_spell` with `negate` / `reflect` / `absorb_into {pool}` / `attack`, **where the op fully expresses today's code**; otherwise a flag read by today's code, listed in the doc as "kept as flag: <why>" |
  | weapon enchant words (`adds_fire_damage_to_attacks`, `adds_air_damage_to_attacks`, `stun_chance_on_hit`, `increase_burning_damage_dealt`, `charm_chance_on_enemy_melee_approach` …) | trigger `on: hit` / `enemy_enters_reach` with `damage` / `status`, or a flag under the same rule as above |
  | anything else still in `effects` | under the same rule: an op if it fully expresses the code, otherwise a flag |

- After the migration, `effects`, `type`, `category`, `duration_type`, `default_duration`, `stackable`, `bonus_amount`, `penalty_amount`, `damage_per_turn`, `heal_per_turn`, `retaliation`, `reaction`, `save_type` and the `*_on_expire` keys **no longer exist** on any status. Every status has `polarity`, and `validate_status` runs on all of them and rejects legacy keys. `dispellable` / `dispel_methods` stay (stage 3 moves dispel onto categories) and are listed in `STATUS_FIELDS` with that note.
- Modify: `scripts/effects/effect_vocab.gd`:
  - `OPS` += `attack`, `negate`, `reflect`, `absorb_into`, but only those actually built;
  - `STATUS_TRIGGERS` += each `on` value built here;
  - the intercept-only ops are rejected outside an intercepting trigger.
- Modify: `scripts/autoload/combat_manager.gd`:
  - the triggers are dispatched from the existing hook points (`_process_reactive_statuses`, `_process_status_weapon_enchants`, `_check_zoc_reactions`, `_on_status_expired`, attack/spell resolution for intercepts);
  - intercepting triggers run **before** resolution, every other trigger after;
  - delete each legacy reader as its key disappears;
  - `_perform_reaction` becomes the `attack`/`negate`/`move` op handlers.
- Delete: `scripts/combat/reaction.gd`, and its references in `tools/validate_data.py` and `tools/effect_check.py`. Perks that applied reaction statuses keep doing so unchanged.
- Modify: `docs/plans/STATUS_MIGRATION_2026-11.md`, appending this task's mapping with reader `file:line`.

- [ ] **Step 1: Write the failing checks:**
  - `dot_uses_spell_value`: Burning applied with value 9 ticks 9; with value 0 it ticks 5.
  - `retaliation_trigger`: a struck unit with a retaliation status deals today's damage back.
  - `expire_summon`: the status with `summon_on_expire` summons on expiry, and not on dispel, matching today. If today's code differs, assert today's behaviour and note it.
  - `intercept_negate`: an `auto_dodge` reaction status negates one melee attack and then respects its limit.
  - `borrowed_value`: `{from: caster.skill.leadership, pct: 50}` on a fortify gives half the caster's effective Leadership.
  - `no_legacy_status_keys`: no status has any key from the removed list.
  - Keep every `verify_reactions` assertion unchanged.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3: Implement**, slice by slice in the table's order, running `verify_reactions` and `verify_spells` after each slice.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: statuses — triggers and intercepts, reaction.gd folded in`.

---

### Task 7: Everything that describes a status, plus the stage-1 carry-overs

**Files:**
- Modify: `scripts/ui/tooltip_text.gd`. Add `static func describe_effects(effects: Array) -> PackedStringArray` (a generic sentence per effect, reusable for spells in stage 3), plus `describe_flags`, `describe_triggers` and `describe_periodic`. The status tooltip is built only from these, never from word lists.
  - Examples of the expected wording: `+15 dodge`, `+2 Finesse`, `Fire resistance +25%`, `5 fire damage at the start of each turn`, `When struck: 3 piercing damage to the attacker`, `Cannot move`, `Immune to Charmed`.
  - Flag names show as readable words from one dictionary in this file. A flag without an entry shows its id with underscores replaced, and `verify_tooltips` fails on any flag without an entry.
- Modify: `tools/content/sections/statuses.py`.
  - Group by the first category, or by polarity ("Positive" / "Negative" / "Neutral") when a status has no categories.
  - The context line is built from the new fields, with the same wording rules as the tooltip (a Python port of `describe_*` limited to what the data uses), e.g. `negative · turns 3 · −10 armor · cannot move`.
  - Update `tools/test_content_sections*.py`.
- Modify: `scripts/combat/resistance.gd` (`breakdown()`): lists effect holds by source name. This is a carry-over.
- Modify: the party screen. Add one line per character listing lasting damage (`damaged_values`) with what clears it, e.g. `Focus −2 (until full rest or White magic 5)`. This is a carry-over from spec §4.2. Find the screen through `scenes/ui/`.
- Modify: `scripts/effects/effect_resolver.gd` (`_do_status`): the result entry says `applied: false` with a reason when the status was resisted or nothing was removed. This is a carry-over.
- Modify: `scripts/effects/effect_context.gd` (`for_spell`): keep all schools, and make `cleared_by` heal-school matching test any of them. This is a carry-over.
- Modify: `TODO.md` §17. Tick these carry-overs, and leave the stage-3 ones (kill reward and bleeding-out, `target_pos`, push damage type, zone shape validation, split truncation, Ritual DC / `dc_stat`, the `held` flag on a mid-combat save) under "Carried into stage 3".
- Run `content_sync.py --write`.

- [ ] **Step 1: Write the failing checks.**
  - In `verify_tooltips`, add `status_tooltip_from_fields` for five statuses: one stat buff, one control with flags, one DOT, one retaliation and one §7 named status. Each tooltip must contain the expected phrase, and every status's tooltip must be non-empty. Also add `every_flag_has_words`.
  - In the Python tests, add the statuses context line for the same five.
  - In `verify_effects`, add `status_op_reports_resisted`, `multi_school_cleared_by` and `breakdown_lists_holds`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3: Implement**, then run the sync.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: status descriptions from fields; stage-1 carry-overs`.

---

### Task 8: Auras and zones as effect lists

**Files:**
- Create: `tools/migrate_auras_zones.py` (re-runnable). It converts each payload in `auras.json` and `zones.json` into effect lists:
  - **auras:** `while_inside: [effects]`;
  - **zones:** `while_inside`, `on_enter`, `turn_start_inside`, `turn_end_inside` and `on_death_inside`, each taking `[effects]`.
  - Payload kinds map to ops with today's numbers: stat → `modify stat.`, resistance → `modify resist.`, a status payload → `status apply`, raise → `summon from: corpse`, damage → `damage`, and so on.
  - A payload kind no op expresses gets a new `stat.`/`resist.` key in `EffectVocab.STATS` only if a getter reads it in this task (e.g. `stat.max_hp`, `stat.damage_taken_pct`). Otherwise it stays as a named payload, listed in `STATUS_MIGRATION_2026-11.md` with the reason.
  - Affliction resistance (Immune System) becomes `modify resist.<affliction>`. `Resistance.resists_affliction` reads holds.
  - A status's `aura_value` becomes the aura instance's magnitude, read through `{from: status.value}`.
- Modify: `scripts/combat/aura_system.gd`. **Auras are read-time holds:**
  - `ValuePaths.apply_to(unit, value, base)` also sums the `modify` effects of every aura reaching `unit`, using the existing `reaches()` / `sign_for()` / distance rules;
  - no hold is stored, so movement and death need no bookkeeping;
  - `stat_bonus`, `stat_pct_bonus`, `resistance_bonus`, `damage_taken_multiplier` and `max_hp_bonus` are deleted once their callers read through `ValuePaths`;
  - the hold source label is `"aura:<source instance id>:<aura id>"` (for `breakdown()`).
- Modify: `scripts/combat/zone.gd` and the `_tick_zones` / enter / death-inside code in `combat_manager.gd`. Zone effects go through `EffectResolver.resolve`, with `ctx.caster` set to the zone's owner and `ctx.target_pos` set to the zone tile. `while_inside` modifies are read-time like auras.
- Modify: `EffectVocab` + the mirror: aura and zone validation (`validate_aura`, `validate_zone`). The old payload `kind` and `affects` vocabularies are deleted where they are replaced; `affects` (who) stays as the effect's `to`-style selector field on the aura/zone.
- Run `content_sync.py --write` (only if auras or zones appear in `CONTENT.md`).

- [ ] **Step 1: Write the failing checks.**
  - Capture a fixture before migrating: for every aura, the stat and resistance change it gives an ally and an enemy at distance 1 and outside its radius. Add `aura_numbers_match_baseline`.
  - Add `zone_effects_resolve`: a hand-written zone authored only with effects damages on `turn_start_inside` and applies a status `on_enter`.
  - Add `grave_soil_raises`: Grave Soil still raises a zombie for the caster.
  - Existing aura and zone verifier assertions stay unchanged.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: auras and zones as effects`.

---

### Task 9: Extensions — group targets, affinity as a value, pressure as a value

**Files:**
- Modify: `scripts/effects/value_paths.gd`, `scripts/effects/effect_vocab.gd` + the mirror, `scripts/autoload/perk_system.gd` (`calculate_element_affinity`), `scripts/effects/effect_resolver.gd` (`_do_modify`).

**Group targets (spec §10.3 extension 1):**
- `skills.element.<element>` (the 7 skills of that element, from `skills.json`), `skills.magic`, `skills.combat`, `skills.general` (the categories in `skills.json`), and `attributes.all`.
- `add_hold` on a group expands to one hold per member, all under the same `source_id`, so one `release` removes them all.
- Modes: the same as `skill.` / `attribute.`.

**Affinity as a value (extension 2):**
- `affinity.<element>`, with modes fortify, drain, set and multiply.
- It is held on the unit like `stat.` holds (`effect_holds`), and applied in `calculate_element_affinity` through `ValuePaths.apply_to`. It works outside combat only for persistent or world holds, which do not exist yet; note this in the code comment.

**Pressure as a value (extension 7):**
- `pressure.<element>` is instant, with `fortify` (adds pressure) and `drain` (relieves it).
- `_do_modify` routes it to `PsychologySystem.apply_pressure(character, element, ±amount)` (`psychology_system.gd:378`). Enemies have no psychology: the effect is refused with a reason and nothing breaks.

- [ ] **Step 1: Write the failing checks:**
  - `group_skill_hold`: fortify `skills.element.fire` 2 raises each of the 7 fire skills' effective level by 2, and one release removes all seven.
  - `group_attributes_all`: same for `attributes.all`.
  - `affinity_hold`: fortify `affinity.earth` 3 raises the earth affinity total by 3 without touching skills.
  - `pressure_modify`: fortify `pressure.fire` 5 on a party unit raises its fire pressure by 5; on an enemy it is refused, and no error is raised.
  - The Python validator tests cover each new path and rejects `skills.element.plasma`.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: group targets, affinity and pressure as values`.

---

### Task 10: Extensions — building states, comedown, upkeep; documentation

**Files:**
- Modify: `scripts/autoload/combat_manager.gd` (the status container from Task 3), `scripts/effects/effect_vocab.gd` + the mirror.

**Building states (extension 4):**
- `stacking: {mode: "stack", max: N, grow: {on: <trigger>, by: n, if?: [...]}}`. The status gains `by` stacks (up to `max`) each time its owner's trigger fires.
- Build the trigger `casts` with the condition `{spell_school: <school>}` (add it to `CONDITION_KEYS`). Any trigger already built in Task 6 also works.
- The holds re-scale as in Task 3.

**Comedown (extension 5):**
- No new field: an `expire` trigger.
- Pin the rule in a doc comment on `_end_status`: **expire fires on `expired` and `upkeep`, never on dispel, cleanse or death.** If Task 6 found today's `*_on_expire` behaviour differs, that finding wins and the comment says so.

**Upkeep (extension 6):**
- `upkeep: {mana|stamina|hp: n, per: "turn"}`, paid at the owner's turn start before `periodic`.
- If the owner cannot pay, the status ends with reason `upkeep`, so its comedown fires.
- HP upkeep never takes a unit below 1. It ends the status instead.

**Documentation:**
- Spec: add §10.5 "As built (stage 2b)", covering names and details that differ from §4.4, §4.6 and §10.3.
- `TODO.md` §17: stage 2b done. List what stage 3 inherits, and add "Found during 2b" items.
- `CLAUDE.md`: if the status data conventions changed what a reader must know, add one line.
- `README.md`: mention statuses in effect form, if it describes status data.

- [ ] **Step 1: Write the failing check** `mantra_state_example` (a test status). It gives fortify `skill.fire_magic` 1 per stack, grows by 1 on each fire spell cast up to 5, has upkeep of 10 mana per turn, and its comedown is `status apply` of a test drain status that drains `attribute.focus` 2 for 2 turns.
  - Casting three fire spells gives +3 effective Fire magic, which changes the caster's spellpower through the per-level formula.
  - Draining the mana to 5 ends the state at the next turn start and applies the comedown.
  - Dispelling the state does not apply the comedown.
- [ ] **Step 2:** Run it. Expected: FAIL.
- [ ] **Step 3: Implement**, then write the docs.
- [ ] **Step 4:** Run `tools/verify_all.sh`. Expected: PASS.
- [ ] **Step 5:** Commit with the message `Effect normalization 2b: building states, comedown, upkeep; documented`.
