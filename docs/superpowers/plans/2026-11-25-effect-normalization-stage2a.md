# Effect Normalization — Stage 2a: Boosts Count Everywhere, Uncapped Skill Curves — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A temporary attribute or skill boost counts everywhere a real one does (except perks and spell learning), and per-level skill bonuses come from an uncapped formula instead of tables that stop at level 10.

**Architecture:** Three changes, in order:
1. The `per_level` tables in `perks.json → base_bonuses` become `{curve, at_5, at_10, …}`, computed by `PerkSystem`. The effective skill level loses its upper clamp.
2. Attribute holds move from the internal `"__attr"` stat-delta mechanism into the character's own bonus maps (`attribute_bonuses[attr]["effects"]`, the same way skill holds already use `skill_bonuses`). One `ValuePaths.refresh_character(unit)` re-runs the derived-stat calculation mid-fight.
3. Every reader of a raw attribute or skill in combat, saves, affinity and event checks is switched to the effective value, except perk, XP-purchase and spell-learning paths.

**Tech Stack:** Godot 4.7 / GDScript, Python 3, `tools/verify_all.sh`.

**Spec:** `docs/superpowers/specs/2026-11-25-effect-normalization-design.md` §10.1 and §10.2 (the addendum). Stage 1 is merged on `master` (`044a675`).

## Global Constraints

- Branch: `git checkout -b normalization-stage2a` from `master`. Olaf's uncommitted `project.godot`, `resources/data/companions.json` and `resources/data/shops.json` are **never staged**; `CONTENT.md` and `tools/content_base.json` only as the next bullet allows. Every commit lists its files explicitly.
- Data change allowed in this stage: only `perks.json → base_bonuses` (Task 1). After any JSON change from code, run `python3 tools/content_sync.py --write`. **Olaf (2026-11-25): the sync may change and the commit may include `CONTENT.md` / `tools/content_base.json` even where they hold his pending edits — do not stop for that.** A backup of his uncommitted files and a patch of them sit in `.superpowers/backups/2026-11-25-before-stage2a/` (git-ignored); never delete it.
- **The curve formula is exactly** (spec §10.2):
  - climb: L ≤ 5 → `at_5 × L(L+1)/30`; L > 5 → `at_5 + (at_10 − at_5) × (L − 5)/5`
  - steady: `base + at_10 × L/10`
  - `integer: true` floors; `limit` bounds the result toward its sign (a negative limit is a floor, a positive one a ceiling)
  - no other cap
- **Not boosted** (spec §10.1): perk ownership and offers, XP purchase, and learning a spell in a shop (`meets_spell_skill` keeps the bought level). Casting reads the effective level.
- **Effective** = base + equipment + traits + holds − damage. One accessor for attributes, and the existing `get_effective_skill_level` for skills.
- Lower bound on effective skill level stays −5, and `NEGATIVE_SKILL_PENALTIES` is unchanged.
- Verifiers that assert old table values are updated to read the expected value from the formula. Never weaken them to pass. List every changed expectation in the task report.
- The stage-1 rules still hold:
  - lists contain only what is built, and unknown names fail loudly;
  - a new `class_name` commits `.godot/global_script_class_cache.cfg`;
  - use `not x in y`;
  - write `##` docs for a beginner-intermediate reader;
  - `tools/verify_all.sh` exits 0 at the end of every task.
- The save/load test uses the scratch `SaveManager.SAVE_DIR`. **Never write to the real save folder.**

## Review Focus

1. **A boost bigger than 10 levels past 10.** A level-25 effective Swords must give a finite, formula-correct value with no array index error and no clamp. Test in Task 1.
2. **A `limit` stat overshooting.** Mana cost reduction at effective level 30 must stay at −100, so a spell never costs less than 0. Test in Task 1.
3. **Mid-fight refresh raising current HP.** A Constitution boost raises max HP. Current HP must not jump up, matching stage 1 behaviour, and it must clamp when the boost ends. Test in Task 2.
4. **Enemies.** They use `EnemySystem`'s derived path. The refresh must work for an enemy unit too, and must not touch `EnemySystem` data. Test in Task 2.
5. **Shop learning with a boost active.** A character with a +5 skill hold outside combat must still be refused a spell above their bought level in the shop. Test in Task 3.

---

### Task 1: Skill bonuses become a formula

**Files:**
- Create: `tools/migrate_skill_curves.py`. It is re-runnable and idempotent. It reads each `per_level` table and writes `curve`, `at_5`, `at_10` (plus `base`, `integer` and `limit` where they apply) to every stat of every skill. It keeps `stats` and removes `per_level`. It also writes `docs/plans/SKILL_CURVES_2026-11.md`: for every skill.stat, the old value and the new value at levels 1, 3, 5, 7, 10, with the largest difference flagged, and the new value at 15 and 20.
  - Curve choice: whichever of climb or steady has the smaller maximum error over levels 1–10. `at_5` is the table value at 5 and `at_10` the value at 10.
  - `integer`: set when every table value is a whole number **and** the stat is a count (`party_max_companions`, `party_skill_check_bonus`, `effect_duration_turns`, and any others the script finds; list them in the doc). `base` is fitted for those so levels 1 and 10 match the table.
  - `limit`: set on `mana_cost_reduction` (−100). For each other stat, check its consumer in code, and set `limit: 100` only where a value past 100 would invert its meaning (a reduction becoming a gain). List each stat you considered and the decision, with the consumer file:line, in the doc.
- Modify: `scripts/autoload/perk_system.gd:727-739`. `get_base_skill_bonuses_at_level(skill_id, level)` computes from the curve for any `level ≥ 1`, with no `mini(level, 15)`. Keep the return shape `{stat: float}`. Add `static func curve_value(spec: Dictionary, level: int) -> float`.
- Modify: `scripts/autoload/character_system.gd:1065`. `clampi(base + bonus, -5, 15)` becomes a lower bound only: `maxi(base + bonus, -5)`.
- Modify: `tools/validate_data.py:695-710`. Read stat keys from the new shape, and validate each stat spec: `curve` ∈ {climb, steady}, numeric `at_10`, numeric `at_5` for climb, `integer` bool, numeric `limit`.
- Modify: `resources/data/perks.json` (by running the script, then `content_sync.py --write`).
- Modify: any verifier that hard-codes old table values (find them by running `verify_all.sh` after the change).

**Interfaces:**
- Produces: `PerkSystem.curve_value(spec, level) -> float` and `PerkSystem.get_base_skill_bonuses_at_level(skill_id, level) -> Dictionary` (uncapped).

- [ ] **Step 1: Write the failing checks** in a new section of `tools/verify_effects.gd`:
  - `_check_curve_climb_swords`: `get_base_skill_bonuses_at_level("swords", L).damage` for L = 1..10 equals `[5, 15, 30, 50, 75, 86, 97, 108, 119, 130][L-1]` (±0.01). That is the formula, not the old table, which had 90/100/110/120 at 6–9.
  - `_check_curve_continues_past_ten` (Review Focus 1): Swords damage at 15 = 185 and at 25 = 295, with no error.
  - `_check_curve_limit_holds` (Review Focus 2): `space_magic.mana_cost_reduction` at levels 9, 10, 30 all equal −100.
  - `_check_effective_skill_level_uncapped`: a character with base Swords 10 and a `skill_bonuses.swords.test = 12` → `get_effective_skill_level == 22`.
  - `_check_integer_curve_floors`: `party_max_companions` values are whole numbers at every level 1..20.
- [ ] **Step 2: Run and see them fail.** Run `godot --headless res://tools/verify_effects.tscn`. Expected: all five FAIL (the Swords values at 6–9 differ from today's table).
- [ ] **Step 3: Implement.** Write and run the migration script, change PerkSystem, change the clamp, and update the validator.
- [ ] **Step 4: Run and see them pass.**
- [ ] **Step 5: Run `tools/verify_all.sh`.** Fix any verifier expectation that hard-codes old table values: compute the expectation via `PerkSystem.curve_value`, and list each change in the report. Expected: exit 0.
- [ ] **Step 6: Commit** `tools/migrate_skill_curves.py`, `resources/data/perks.json`, `tools/content_base.json` and `CONTENT.md` if the sync changed them, `docs/plans/SKILL_CURVES_2026-11.md`, `scripts/autoload/perk_system.gd`, `scripts/autoload/character_system.gd`, `tools/validate_data.py`, `tools/verify_effects.gd`, and any changed verifier. If the sync changed `CONTENT.md` or `tools/content_base.json`, commit them too (allowed, see Global Constraints). Commit message: "Effect normalization 2a: skill bonuses are an uncapped formula".

### Task 2: Attribute holds live on the character; refresh mid-fight

**Files:**
- Modify: `scripts/effects/value_paths.gd`.
  - Attribute holds write their net total into `character_data["attribute_bonuses"][attr]["effects"]`, mirroring `_refresh_skill`. Remove the `"__attr"` stat-delta mechanism and `refresh_attribute_deltas`.
  - Add `static func refresh_character(unit: Node) -> void`. It recomputes the unit's derived stats through the right formula: `CharacterSystem.update_derived_stats` for a unit whose `character_data` is a party member, or the `EnemySystem` derived path otherwise. Then it syncs `unit.max_hp/max_mana/max_stamina` from `derived` and clamps current values down. It never raises current values (Review Focus 3).
  - Call it after any attribute or skill hold change, so per-level skill bonuses also update mid-fight.
- Modify: `scripts/autoload/character_system.gd` `update_derived_stats`. The effective attributes add `attribute_bonuses[*]["effects"]`. Add `func get_effective_attribute(character: Dictionary, attr: String) -> int`: base + equipment + traits + `attribute_bonuses` − damage (floor 1), the same value `update_derived_stats` uses. Refactor `update_derived_stats` to call it, so there is one definition.
- Modify: `scripts/autoload/enemy_system.gd`. Expose `func recalculate_derived(character_data: Dictionary) -> Dictionary`, so the enemy refresh needs no access to private code. It must read the same `attribute_bonuses`.
- Modify: `release_all_combat`. Erase the `attribute_bonuses[*]["effects"]` keys alongside the skill ones.

**Interfaces:**
- Consumes: Task 1's uncapped skill bonuses.
- Produces: `ValuePaths.refresh_character(unit)` and `CharacterSystem.get_effective_attribute(character, attr) -> int`.

- [ ] **Step 1: Write the failing checks:**
  - `_check_skill_hold_raises_per_level_bonus_midfight`: a party unit with Swords 10 in combat. `add_hold(skill.swords, fortify, 5)` → `get_accuracy()` rises by exactly `curve_value(swords.accuracy, 15) − curve_value(swords.accuracy, 10)`.
  - `_check_attribute_hold_no_current_hp_jump` (Review Focus 3): fortify Constitution +5 → max_hp +50, current_hp unchanged. Release with current_hp at max → current_hp == the old max.
  - `_check_enemy_refresh` (Review Focus 4): on a team-1 unit, an attribute hold changes its stats, EnemySystem's archetype data is unchanged, and release restores them.
  - The stage-1 checks `_check_fortify_finesse_moves_dodge_and_initiative`, `_check_fortify_constitution_raises_max_hp_and_clamps_on_release`, `_check_holds_do_not_survive_end_combat` and `_check_midfight_recompute_does_not_double_count` must still pass unchanged.
- [ ] **Step 2: Run and see the new ones fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run and see all pass.**
- [ ] **Step 5: Run `tools/verify_all.sh`.** Expected: exit 0.
- [ ] **Step 6: Commit** with the message "Effect normalization 2a: attribute holds on the character, refreshed mid-fight".

### Task 3: Every reader uses the effective value

**Files:**
- Modify, at each site that reads `character["attributes"]` / `["skills"]` raw: `scripts/autoload/combat_manager.gd` (~28 sites), `scripts/combat/save_system.gd:126-129` (`_attribute_of`), `scripts/autoload/perk_system.gd` (`calculate_element_affinity` and others, ~10 sites), `scripts/combat/party_bonuses.gd`, `scripts/autoload/event_manager.gd` (~20 sites, the party-wide roll and requirement checks), `scripts/combat/combat_arena.gd` (~8, display), `scripts/combat/combat_unit.gd` (1).
- Rule per site:
  - A reader of **ability** (can you, how well): use `CharacterSystem.get_effective_attribute` / `get_effective_skill_level`. This covers casting, spell bonus, saves, DCs, damage, affinity, event checks and displays of current power.
  - A reader of **ownership or progression**: keep raw. This covers perk eligibility and offers, XP cost and purchase, `meets_spell_skill` for shop learning, save/load, character creation, and race skill floors.
  - Write each site with its decision (file:line, effective or raw, one-word reason) into the task report as a table. That table is the review artifact.
- `combat_manager.gd`:
  - `_can_cast_spell` and its callers pass an effective skills map. Add `CharacterSystem.get_effective_skills(character) -> Dictionary` (every skill id → effective level) for that.
  - `_calculate_spell_bonus` reads effective levels.

**Interfaces:**
- Consumes: Task 2's `get_effective_attribute`, plus `get_effective_skill_level`.
- Produces: `CharacterSystem.get_effective_skills(character) -> Dictionary`.

- [ ] **Step 1: Write the failing checks:**
  - `_check_skill_hold_unlocks_casting`: a caster with Fire magic 3 cannot cast `fireball` (L5); after `skill.fire_magic fortify 2` it can. Use `CombatManager._can_cast_spell` the way `cast_spell` calls it.
  - `_check_skill_hold_raises_spell_bonus`: `_calculate_spell_bonus` for `firebolt` rises after a Fire magic hold.
  - `_check_attribute_hold_reaches_saves`: `SaveSystem.success_chance` for a Constitution save rises after `attribute.constitution fortify 6`.
  - `_check_skill_hold_reaches_affinity`: `PerkSystem.calculate_element_affinity(character, "fire")` rises by the hold amount.
  - `_check_shop_learning_ignores_boost` (Review Focus 5): with `skill_bonuses.fire_magic.effects = 5` on a Fire-3 character, `CharacterSystem.meets_spell_skill(character, fireball)` is false.
- [ ] **Step 2: Run and see them fail** (the last one should already pass; it pins the rule).
- [ ] **Step 3: Implement the sweep**, recording the site table.
- [ ] **Step 4: Run and see them pass.**
- [ ] **Step 5: Run `tools/verify_all.sh`.** Expected: exit 0.
- [ ] **Step 6: Commit** with the message "Effect normalization 2a: boosts count wherever ability is read".

### Task 4: Document the stage

**Files:**
- Modify: `TODO.md` §17. Mark stage 2a done (date). Point at `docs/plans/SKILL_CURVES_2026-11.md` as **Olaf's review item**: the before/after numbers, where `at_5`/`at_10` are the knobs. Name stage 2b (statuses + auras/zones + the seven extensions) as next.
- Modify: `CLAUDE.md`, "Things to Remember". Add one line: skill bonuses are an uncapped formula in `perks.json → base_bonuses` (`curve`, `at_5`, `at_10`), and boosts count everywhere except perks, XP purchase and spell learning.
- Modify: spec §10, "As built" notes for any name that changed.

- [ ] **Step 1:** Edit the three files.
- [ ] **Step 2:** Run `tools/verify_all.sh --quick`. Expected: exit 0.
- [ ] **Step 3: Commit** with the message "Effect normalization 2a: documented".
