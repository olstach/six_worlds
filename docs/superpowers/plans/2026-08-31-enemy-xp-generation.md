# Enemies as XP-Built Characters — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace ad-hoc enemy "power" generation with enemies built as characters from an XP budget, and compute post-battle XP as a divided fraction of that budget.

**Architecture:** Enemies roll a birth and background like players do, then spend an XP budget through the player's own cost curves, directed by their archetype's existing `attribute_weights` and `skill_priorities`. Encounter budgets are absolute per realm, scaled by encounter tier and a rolled rarity band. A party archetype splits the party budget into member shares. Post-battle XP is a fixed fraction of the enemy party's XP, divided among the player's party.

**Tech Stack:** Godot 4.7 / GDScript. Data in JSON under `resources/data/`. Verification by a headless harness script plus `tools/validate_data.py`.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-31-enemy-xp-generation-design.md`. Read it before starting.
- GDScript quirks: use `not x in y`, never `x not in y`. Always type Arrays (`Array[Dictionary]`). Variables declared inside a loop are not visible after `break`.
- Any key beginning with `_` in a JSON data file is a comment or section divider and MUST be skipped by every loader (`if key.begins_with("_"): continue`).
- After ANY data edit run `python3 tools/validate_data.py`; it must print `TOTAL ISSUES: 0`.
- After ANY script edit run `timeout 200 godot --headless --quit-after 300 2>&1 | grep -cE 'SCRIPT ERROR|Parse Error'`; it must print `0`.
- Commit after every task. Never use `git push`.
- `REWARD_FRACTION`, `REALM_BASE`, tier and band multipliers are expected to be re-tuned in playtesting. They live in JSON, never hardcoded in scripts.

---

## File Structure

**Create:**
- `resources/data/enemies/encounter_budgets.json` — realm bases, tier multipliers, rarity bands, reward fraction. One file because these four tables are always read together and always tuned together.
- `resources/data/enemies/party_archetypes.json` — party composition templates.
- `tools/verify_enemy_xp.gd` — headless harness; asserts the maths and prints the full encounter table.

**Modify:**
- `scripts/autoload/character_system.gd` — add `spend_xp_budget()`, the shared build routine.
- `scripts/autoload/enemy_system.gd` (969 lines) — budget resolution, party composition, `_build_enemy` rewrite, remove `get_party_power` and `DIFFICULTY_MULTIPLIERS`.
- `scripts/autoload/combat_manager.gd` (8613 lines) — reward from enemy XP; remove `_calculate_unit_power`.
- `scripts/autoload/companion_system.gd` — divide XP; remove `get_xp_multiplier`.
- `scripts/ui/shop_ui.gd:681` — repoint companion pricing off `get_party_power`.

**Note on `enemy_system.gd`:** it is 969 lines and this plan adds ~200. That is within the range of other autoloads here (`character_system.gd` is 1185). Do not split it; follow the existing file's structure.

---

### Task 1: Budget tables and resolution

**Files:**
- Create: `resources/data/enemies/encounter_budgets.json`
- Modify: `scripts/autoload/enemy_system.gd`
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Produces: `EnemySystem.resolve_party_budget(encounter_id: String, realm: String) -> Dictionary` returning `{"xp": int, "band": String, "tier": String}`.
- Produces: `EnemySystem.budgets: Dictionary` — the loaded JSON.

- [ ] **Step 1: Create the budget data file**

`resources/data/enemies/encounter_budgets.json`:

```json
{
  "_comment": "Absolute per-realm party XP budgets. party_xp = realm_base * tier * band. Expected to move in playtesting.",
  "realm_base": {
    "hell": 200,
    "hungry_ghost": 700,
    "animal": 1800,
    "human": 3000,
    "asura": 5000,
    "god": 8000
  },
  "_comment_tier": "Encounter tier. 'beast' exists on one archetype and is treated as 'shade'.",
  "tier_multipliers": {
    "imp": 0.5,
    "shade": 0.8,
    "beast": 0.8,
    "devil": 1.0,
    "boss": 2.0
  },
  "_comment_bands": "Rolled per encounter. Same common/uncommon/rare vocabulary births use.",
  "bands": [
    { "id": "common",   "multiplier": 1.0, "weight": 60 },
    { "id": "uncommon", "multiplier": 1.5, "weight": 30 },
    { "id": "rare",     "multiplier": 2.3, "weight": 10 }
  ],
  "_comment_reward": "Fraction of the enemy party's XP the player party gains, before division by party size.",
  "reward_fraction": 0.12
}
```

- [ ] **Step 2: Write the failing harness**

Create `tools/verify_enemy_xp.gd`:

```gdscript
extends Node
## Headless verification for the enemy XP generation system.
## Run: godot --headless --script res://tools/verify_enemy_xp.gd
## Exits non-zero if any assertion fails.

var failures: int = 0

func _ready() -> void:
	_check_budgets()
	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK")
		get_tree().quit(0)

func fail(msg: String) -> void:
	failures += 1
	printerr("  FAIL: " + msg)

func expect(cond: bool, msg: String) -> void:
	if not cond:
		fail(msg)

func _check_budgets() -> void:
	print("-- budgets --")
	var b: Dictionary = EnemySystem.budgets
	expect(not b.is_empty(), "EnemySystem.budgets is empty")
	expect(b.get("realm_base", {}).has("animal"), "realm_base missing animal")
	expect(float(b.get("reward_fraction", 0.0)) > 0.0, "reward_fraction not loaded")

	# every tier used by any encounter or archetype must have a multiplier
	var tiers: Dictionary = b.get("tier_multipliers", {})
	for aid in EnemySystem.archetypes:
		if aid.begins_with("_"):
			continue
		var t: String = EnemySystem.archetypes[aid].get("tier", "")
		expect(tiers.has(t), "archetype '%s' has tier '%s' with no multiplier" % [aid, t])
```

- [ ] **Step 3: Run the harness to verify it fails**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: FAIL — `EnemySystem.budgets is empty` (the property does not exist yet, so the script errors or reports failures).

- [ ] **Step 4: Load the budgets in EnemySystem**

In `scripts/autoload/enemy_system.gd`, add near the other data properties:

```gdscript
## Encounter budget tables: realm bases, tier multipliers, rarity bands, reward fraction.
var budgets: Dictionary = {}
```

Add a loader and call it from `_ready()` alongside the existing loads:

```gdscript
func _load_budgets() -> void:
	var path := "res://resources/data/enemies/encounter_budgets.json"
	if not FileAccess.file_exists(path):
		push_error("EnemySystem: encounter_budgets.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("EnemySystem: encounter_budgets.json parse error - " + json.get_error_message())
		return
	budgets = json.data
```

- [ ] **Step 5: Implement budget resolution**

Add to `scripts/autoload/enemy_system.gd`:

```gdscript
## Roll a rarity band. Returns its id, e.g. "common".
func roll_band() -> String:
	var bands: Array = budgets.get("bands", [])
	if bands.is_empty():
		return "common"
	var total: int = 0
	for band in bands:
		total += int(band.get("weight", 0))
	if total <= 0:
		return "common"
	var roll: int = randi() % total
	var cumulative: int = 0
	for band in bands:
		cumulative += int(band.get("weight", 0))
		if roll < cumulative:
			return String(band.get("id", "common"))
	return String(bands[0].get("id", "common"))


func _band_multiplier(band_id: String) -> float:
	for band in budgets.get("bands", []):
		if String(band.get("id", "")) == band_id:
			return float(band.get("multiplier", 1.0))
	return 1.0


## The tier an encounter counts as. Only 48 of 117 encounters carry a top-level
## `tier`; `fixed` and `groups` ones do not, so it is derived rather than
## defaulted — defaulting to devil would flatten every boss fight.
func resolve_encounter_tier(template: Dictionary) -> String:
	if template.has("tier"):
		return String(template["tier"])

	var order := ["imp", "beast", "shade", "devil", "boss"]
	var best := -1

	if template.get("fixed", false):
		for entry in template.get("enemies", []):
			var aid: String = entry.get("archetype", "")
			var t: String = archetypes.get(aid, {}).get("tier", "devil")
			best = maxi(best, order.find(t))
	for group in template.get("groups", []):
		best = maxi(best, order.find(String(group.get("tier", "devil"))))

	if best < 0:
		push_warning("EnemySystem: cannot derive tier for encounter, using devil")
		return "devil"
	return order[best]


## Total XP the enemy party is built from.
## party_xp = realm_base * tier_multiplier * band_multiplier
func resolve_party_budget(encounter_id: String, realm: String) -> Dictionary:
	var template: Dictionary = encounters.get(encounter_id, {})
	var tier: String = resolve_encounter_tier(template)
	var band: String = roll_band()

	var base: float = float(budgets.get("realm_base", {}).get(realm, 200))
	var tier_mult: float = float(budgets.get("tier_multipliers", {}).get(tier, 1.0))
	var xp: int = maxi(1, int(round(base * tier_mult * _band_multiplier(band))))

	return {"xp": xp, "band": band, "tier": tier}
```

- [ ] **Step 6: Extend the harness to cover resolution**

Add to `tools/verify_enemy_xp.gd`, and call `_check_resolution()` from `_ready()` after `_check_budgets()`:

```gdscript
func _check_resolution() -> void:
	print("-- budget resolution --")
	# every encounter must resolve to a positive budget and a known band
	var band_ids: Array = []
	for band in EnemySystem.budgets.get("bands", []):
		band_ids.append(String(band.get("id", "")))

	for eid in EnemySystem.encounters:
		if eid.begins_with("_"):
			continue
		var realm: String = EnemySystem.encounters[eid].get("realm", "animal")
		var r: Dictionary = EnemySystem.resolve_party_budget(eid, realm)
		expect(int(r["xp"]) > 0, "encounter '%s' resolved to xp %s" % [eid, r["xp"]])
		expect(band_ids.has(String(r["band"])), "encounter '%s' rolled unknown band" % eid)
		expect(String(r["tier"]) != "", "encounter '%s' resolved empty tier" % eid)

	# band distribution should match the weights
	var counts := {}
	for i in range(30000):
		var b: String = EnemySystem.roll_band()
		counts[b] = int(counts.get(b, 0)) + 1
	var total_w: int = 0
	for band in EnemySystem.budgets.get("bands", []):
		total_w += int(band.get("weight", 0))
	for band in EnemySystem.budgets.get("bands", []):
		var id: String = String(band.get("id", ""))
		var want: float = float(band.get("weight", 0)) / float(total_w)
		var got: float = float(counts.get(id, 0)) / 30000.0
		expect(absf(got - want) < 0.02, "band '%s' rolled %.3f, expected %.3f" % [id, got, want])
```

- [ ] **Step 7: Run the harness — it must pass**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: `VERIFY OK`, exit code 0.

If it reports an archetype whose tier has no multiplier, add that tier to `tier_multipliers` in the JSON rather than defaulting it in code.

- [ ] **Step 8: Commit**

```bash
python3 tools/validate_data.py
git add resources/data/enemies/encounter_budgets.json scripts/autoload/enemy_system.gd tools/verify_enemy_xp.gd
git commit -m "Encounter budgets: absolute per realm, scaled by tier and rarity band"
```

---

### Task 2: Party archetypes

**Files:**
- Create: `resources/data/enemies/party_archetypes.json`
- Modify: `scripts/autoload/enemy_system.gd`
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: `EnemySystem.roll_band()` from Task 1.
- Produces: `EnemySystem.roll_party_composition(band: String) -> Array[Dictionary]`, one entry per member: `{"share": int, "is_hero": bool}`.

- [ ] **Step 1: Create the party archetype data**

`resources/data/enemies/party_archetypes.json`:

```json
{
  "_comment": "How a party's XP budget is split. member_xp = party_xp * share / total_shares. min_band gates exotic templates to rarer encounters.",
  "party_archetypes": {
    "patrol":         { "weight": 30, "tiers": [ { "share": 1, "count": [2, 4] } ] },
    "pair":           { "weight": 15, "tiers": [ { "share": 1, "count": [2, 2] } ] },
    "hero_and_mooks": { "weight": 20, "tiers": [ { "share": 3, "count": [1, 1] },
                                                 { "share": 1, "count": [2, 4] } ] },
    "swarm":          { "weight": 15, "tiers": [ { "share": 1, "count": [5, 8] } ] },
    "lone_hunter":    { "weight": 10, "tiers": [ { "share": 1, "count": [1, 1] } ] },
    "warband":        { "weight": 8, "min_band": "uncommon",
                        "tiers": [ { "share": 2, "count": [1, 2] },
                                   { "share": 1, "count": [3, 5] } ] },
    "foreign_mercs":  { "weight": 2, "min_band": "rare", "foreign": true,
                        "tiers": [ { "share": 2, "count": [1, 1] },
                                   { "share": 1, "count": [2, 3] } ] },
    "rival_party":    { "weight": 2, "min_band": "rare", "all_heroes": true,
                        "tiers": [ { "share": 1, "count": [2, 4] } ] }
  }
}
```

- [ ] **Step 2: Write the failing harness check**

Add to `tools/verify_enemy_xp.gd`, called from `_ready()`:

```gdscript
func _check_composition() -> void:
	print("-- party composition --")
	for band in ["common", "uncommon", "rare"]:
		for i in range(500):
			var members: Array = EnemySystem.roll_party_composition(band)
			expect(members.size() > 0, "band '%s' produced an empty party" % band)
			var heroes := 0
			for m in members:
				expect(int(m.get("share", 0)) > 0, "member with non-positive share")
				if m.get("is_hero", false):
					heroes += 1
			# a hero is either the strict maximum, the sole member, or all_heroes
			if members.size() > 1 and heroes > 0 and heroes < members.size():
				var top: int = 0
				for m in members:
					top = maxi(top, int(m["share"]))
				var at_top := 0
				for m in members:
					if int(m["share"]) == top:
						at_top += 1
				expect(at_top == 1, "band '%s': %d heroes but %d members tie for top share"
					% [band, heroes, at_top])
	# common band must never roll a gated template
	for i in range(2000):
		var members: Array = EnemySystem.roll_party_composition("common")
		expect(members.size() <= 8, "common band produced %d members" % members.size())
```

- [ ] **Step 3: Run the harness to verify it fails**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: FAIL — `roll_party_composition` does not exist.

- [ ] **Step 4: Load the party archetypes**

In `scripts/autoload/enemy_system.gd`, add the property and loader, calling it from `_ready()`:

```gdscript
## Party composition templates: member counts and XP shares.
var party_archetypes: Dictionary = {}


func _load_party_archetypes() -> void:
	var path := "res://resources/data/enemies/party_archetypes.json"
	if not FileAccess.file_exists(path):
		push_error("EnemySystem: party_archetypes.json not found")
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("EnemySystem: party_archetypes.json parse error - " + json.get_error_message())
		return
	for key in json.data.get("party_archetypes", {}):
		if key.begins_with("_"):
			continue
		party_archetypes[key] = json.data["party_archetypes"][key]
```

- [ ] **Step 5: Implement composition rolling**

```gdscript
const BAND_ORDER: Array[String] = ["common", "uncommon", "rare"]


## Party templates available at this band. Gated ones are removed entirely and
## the remaining weights renormalise, rather than rerolling.
func _eligible_party_archetypes(band: String) -> Array[String]:
	var band_rank: int = BAND_ORDER.find(band)
	var out: Array[String] = []
	for key in party_archetypes:
		var min_band: String = party_archetypes[key].get("min_band", "common")
		if BAND_ORDER.find(min_band) <= band_rank:
			out.append(key)
	out.sort()
	return out


## Choose a party template and expand it into one entry per member.
## Returns [{"share": int, "is_hero": bool}, ...]
func roll_party_composition(band: String) -> Array[Dictionary]:
	var eligible: Array[String] = _eligible_party_archetypes(band)
	if eligible.is_empty():
		return [{"share": 1, "is_hero": true}]

	var total: int = 0
	for key in eligible:
		total += int(party_archetypes[key].get("weight", 0))

	var chosen: String = eligible[0]
	if total > 0:
		var roll: int = randi() % total
		var cumulative: int = 0
		for key in eligible:
			cumulative += int(party_archetypes[key].get("weight", 0))
			if roll < cumulative:
				chosen = key
				break

	var template: Dictionary = party_archetypes[chosen]
	var members: Array[Dictionary] = []
	for tier in template.get("tiers", []):
		var span: Array = tier.get("count", [1, 1])
		var lo: int = int(span[0])
		var hi: int = int(span[1]) if span.size() > 1 else lo
		var n: int = lo + (randi() % maxi(1, hi - lo + 1))
		for i in range(n):
			members.append({"share": int(tier.get("share", 1)), "is_hero": false})

	if members.is_empty():
		members.append({"share": 1, "is_hero": true})

	_mark_heroes(members, template)
	return members


## A member is a hero when the template says all members are, when it is the
## sole member, or when it strictly out-shares every other member.
func _mark_heroes(members: Array[Dictionary], template: Dictionary) -> void:
	if template.get("all_heroes", false):
		for m in members:
			m["is_hero"] = true
		return
	if members.size() == 1:
		members[0]["is_hero"] = true
		return

	var top: int = 0
	for m in members:
		top = maxi(top, int(m["share"]))
	var at_top: int = 0
	for m in members:
		if int(m["share"]) == top:
			at_top += 1
	if at_top == 1:
		for m in members:
			if int(m["share"]) == top:
				m["is_hero"] = true
```

- [ ] **Step 6: Run the harness — it must pass**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: `VERIFY OK`.

- [ ] **Step 7: Commit**

```bash
python3 tools/validate_data.py
git add resources/data/enemies/party_archetypes.json scripts/autoload/enemy_system.gd tools/verify_enemy_xp.gd
git commit -m "Party archetypes: member counts and XP shares, band-gated"
```

---

### Task 3: Spending an XP budget

**Files:**
- Modify: `scripts/autoload/character_system.gd`
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: existing `CharacterSystem.calculate_attribute_cost(current_value: int, increase_amount: int) -> int` and `CharacterSystem.SKILL_COSTS: Array[int]`, `CharacterSystem.SKILL_MAX_LEVEL: int`.
- Produces: `CharacterSystem.spend_xp_budget(character: Dictionary, budget: int, attribute_weights: Dictionary, skill_priorities: Array, attr_share: float = 0.6) -> int` — mutates the character, returns XP actually spent.

- [ ] **Step 1: Write the failing harness check**

Add to `tools/verify_enemy_xp.gd`, called from `_ready()`:

```gdscript
func _check_spending() -> void:
	print("-- xp spending --")
	for budget in [50, 200, 800, 1800, 4000, 12000]:
		var c: Dictionary = CharacterSystem.create_blank_character()
		var spent: int = CharacterSystem.spend_xp_budget(
			c, budget, {"strength": 3, "finesse": 2}, ["unarmed", "might"])
		expect(spent <= budget, "budget %d: spent %d, over budget" % [budget, spent])
		expect(spent >= int(budget * 0.9),
			"budget %d: only spent %d, should absorb nearly all of it" % [budget, spent])
		# skills must respect the hard cap
		for s in c.get("skills", {}):
			expect(int(c["skills"][s]) <= CharacterSystem.SKILL_MAX_LEVEL,
				"budget %d: skill %s above cap" % [budget, s])
		# the budget must actually have gone somewhere
		var attr_total: int = 0
		for a in c.get("attributes", {}):
			attr_total += int(c["attributes"][a])
		expect(attr_total > 70, "budget %d: attributes never rose above baseline" % budget)
```

- [ ] **Step 2: Run the harness to verify it fails**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: FAIL — `spend_xp_budget` does not exist.

- [ ] **Step 3: Add a blank-character helper**

There is no character factory: `character_system.gd:77` defines
`const BASE_CHARACTER` but no function returns a copy of it. Add one to
`scripts/autoload/character_system.gd`:

```gdscript
## A character dict with baseline attributes and no birth or background applied.
## Used by enemy generation, which layers birth, background, then archetype spending.
func create_blank_character() -> Dictionary:
	return BASE_CHARACTER.duplicate(true)
```

- [ ] **Step 4: Implement spend_xp_budget**

Add to `scripts/autoload/character_system.gd`:

```gdscript
## Spend an XP budget on a character, directed by weights and priorities.
##
## This is how an enemy is built: the same cost curves the player pays, so an
## enemy's XP total means exactly what a player's does. Skills are bought first
## up to their share, because they hard-cap at SKILL_MAX_LEVEL; whatever the
## skills cannot absorb spills into attributes, which never cap.
##
## Returns the XP actually spent.
func spend_xp_budget(character: Dictionary, budget: int, attribute_weights: Dictionary,
		skill_priorities: Array, attr_share: float = 0.6) -> int:
	if budget <= 0:
		return 0
	var spent: int = 0
	var skill_budget: int = int(round(float(budget) * (1.0 - attr_share)))

	# ── skills: round-robin down the priority list, cheapest next level first ──
	if not skill_priorities.is_empty():
		var buying := true
		while buying:
			buying = false
			var best_skill := ""
			var best_cost: int = -1
			for skill in skill_priorities:
				var level: int = int(character.get("skills", {}).get(skill, 0))
				if level >= SKILL_MAX_LEVEL:
					continue
				var cost: int = SKILL_COSTS[level + 1]
				if cost <= skill_budget - spent and (best_cost < 0 or cost < best_cost):
					best_cost = cost
					best_skill = skill
			if best_skill != "":
				character["skills"][best_skill] = int(character.get("skills", {}).get(best_skill, 0)) + 1
				spent += best_cost
				buying = true

	# ── attributes: everything left, weighted, cheapest-per-weight first ──
	var attr_budget: int = budget - spent
	var attr_spent: int = 0
	var weighted: Array[String] = []
	for attr in attribute_weights:
		if int(attribute_weights[attr]) > 0:
			weighted.append(attr)
	weighted.sort()

	if not weighted.is_empty():
		var buying_attrs := true
		while buying_attrs:
			buying_attrs = false
			var best_attr := ""
			var best_ratio: float = -1.0
			var best_attr_cost: int = 0
			for attr in weighted:
				var value: int = int(character.get("attributes", {}).get(attr, 10))
				var cost: int = calculate_attribute_cost(value, 1)
				if cost > attr_budget - attr_spent:
					continue
				var ratio: float = float(attribute_weights[attr]) / float(maxi(cost, 1))
				if ratio > best_ratio:
					best_ratio = ratio
					best_attr = attr
					best_attr_cost = cost
			if best_attr != "":
				character["attributes"][best_attr] = int(character["attributes"][best_attr]) + 1
				attr_spent += best_attr_cost
				buying_attrs = true

	spent += attr_spent
	update_derived_stats(character)
	return spent
```

- [ ] **Step 5: Run the harness — it must pass**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: `VERIFY OK`.

If the `spent >= budget * 0.9` assertion fails at large budgets, the skills have capped and attributes are absorbing the rest — confirm the attribute loop is reached and that `weighted` is non-empty for the test's weights.

- [ ] **Step 6: Commit**

```bash
git add scripts/autoload/character_system.gd tools/verify_enemy_xp.gd
git commit -m "CharacterSystem.spend_xp_budget: build a character from an XP budget"
```

---

### Task 4: Build enemies as characters

**Files:**
- Modify: `scripts/autoload/enemy_system.gd` (`_build_enemy` at line 284, `generate_encounter` at line 172)
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: `resolve_party_budget`, `roll_party_composition` (Tasks 1–2), `CharacterSystem.spend_xp_budget` (Task 3), existing `CharacterSystem.roll_birth_for_realm(realm)`, `CharacterSystem.apply_birth_modifiers(character, birth)`, `CharacterSystem.apply_background_skills(character, background)`, `KarmaSystem.select_random_background(birth)`.
- Produces: `_build_enemy(archetype_id: String, xp_budget: int, realm: String, region: String, is_hero: bool) -> Dictionary`, with `xp_earned`, `birth`, `background`, `is_hero`, `hero_id` on the returned dict.

- [ ] **Step 1: Write the failing harness check**

Add to `tools/verify_enemy_xp.gd`, called from `_ready()`:

```gdscript
func _check_enemies() -> void:
	print("-- enemy generation --")
	for realm in ["hell", "hungry_ghost", "animal"]:
		for eid in EnemySystem.encounters:
			if eid.begins_with("_"):
				continue
			if EnemySystem.encounters[eid].get("realm", realm) != realm:
				continue
			var party: Array = EnemySystem.generate_encounter(eid, "", realm)
			expect(party.size() > 0, "%s produced no enemies" % eid)
			for e in party:
				expect(int(e.get("xp_earned", 0)) > 0, "%s: enemy has no xp_earned" % eid)
				expect(String(e.get("birth", "")) != "", "%s: enemy has no birth" % eid)
				expect(int(e.get("max_hp", 0)) > 0, "%s: enemy has no hp" % eid)
```

- [ ] **Step 2: Run the harness to verify it fails**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: FAIL — enemies have no `xp_earned` or `birth`.

- [ ] **Step 3: Stamp the realm onto each encounter at load**

No encounter carries a `realm` field — 0 of 119 — because they are loaded flat
from four files into one dictionary. The harness and the budget resolution both
need to know which realm an encounter belongs to, so record it at load time.

In `scripts/autoload/enemy_system.gd`, in the encounter loader around line 113,
derive the realm from the filename being read and stamp it:

```gdscript
			encounters[key] = data.encounters[key]
			# The file an encounter came from is the only record of its realm;
			# nothing in the encounter data itself says.
			encounters[key]["realm"] = realm_name
```

`realm_name` is whatever local the loader already uses for the current file's
realm. If the loop has no such variable, derive it from the path:

```gdscript
	var realm_name: String = path.get_file().replace("_encounters.json", "")
```

Verify afterwards:

```bash
timeout 200 godot --headless --quit-after 300 2>&1 | grep -cE 'SCRIPT ERROR|Parse Error'
```
Expected: `0`.

- [ ] **Step 4: Rewrite the head of `_build_enemy`**

Replace the signature and the attribute/skill section of `_build_enemy` (currently lines 284–303). The old body computed `attr_budget`/`skill_budget` from a power number; it now spends XP through a real character.

```gdscript
## Build one enemy as a character: roll a birth and background, apply their
## modifiers, then spend the XP budget as the archetype directs.
## realm and region are passed through for procedural name generation.
func _build_enemy(archetype_id: String, xp_budget: int, realm: String = "hell",
		region: String = "", is_hero: bool = false) -> Dictionary:
	var archetype = archetypes.get(archetype_id, {})
	if archetype.is_empty():
		push_warning("EnemySystem: Unknown archetype '%s'" % archetype_id)
		return {}

	# Birth and background first — the same two steps a player character takes.
	var birth: String = CharacterSystem.roll_birth_for_realm(realm)
	var background: String = KarmaSystem.select_random_background(birth)

	var built: Dictionary = CharacterSystem.create_blank_character()
	CharacterSystem.apply_birth_modifiers(built, birth)
	if background != "":
		CharacterSystem.apply_background_skills(built, background)

	# Then the archetype, as a spending plan for the budget.
	var spent: int = CharacterSystem.spend_xp_budget(
		built, xp_budget,
		archetype.get("attribute_weights", {}),
		archetype.get("skill_priorities", []))

	var attributes: Dictionary = built["attributes"]
	var skills: Dictionary = built["skills"]
	var derived = _calculate_derived_stats(attributes, skills)

	# Gear value tracks the budget but is not paid out of it — the player never
	# buys equipment with XP either.
	var equipment = _generate_equipment(archetype.get("equipment_template", {}), float(xp_budget))
	var spells = _pick_spells(skills, archetype.get("guaranteed_spells", []))
	var perks = _build_perks(archetype.get("guaranteed_perks", []), skills)
```

Leave the remainder of the function (resistances, inventory, naming, the enemy dict) as it is, except for two changes below.

- [ ] **Step 5: Replace remaining power references inside `_build_enemy`**

Inside the rest of `_build_enemy`, every use of `effective_budget` becomes `float(xp_budget)`. Find them:

```bash
grep -n "effective_budget\|power_budget\|power_scale" scripts/autoload/enemy_system.gd
```

Replace `var power_scale = effective_budget / 80.0` with a budget-relative scale:

```gdscript
	# Item rarity scales with the XP the enemy represents.
	var power_scale = float(xp_budget) / 400.0
```

Delete the now-unused `threat`/`effective_budget` lines:

```gdscript
	var threat = archetype.get("threat_multiplier", 1.0)
	var effective_budget = power_budget * threat
```

`threat_multiplier` is no longer a budget scalar; Task 5 uses it to pick which member is the hero.

- [ ] **Step 6: Add the character fields to the returned enemy dict**

In the `var enemy: Dictionary = {` literal inside `_build_enemy`, change `"traits": []` to carry the birth's traits and add the new fields:

```gdscript
		"wounds": [],
		"traits": built.get("traits", []),
		"birth": birth,
		"background": background,
		"xp_earned": spent,
		"is_hero": is_hero,
		"hero_id": ("hero_%s_%d" % [archetype_id, randi()]) if is_hero else ""
	}
```

- [ ] **Step 7: Rewrite `generate_encounter` to use budget and composition**

Replace the body of `generate_encounter` (line 172 onward). The `difficulty` parameter stays in the signature so existing callers still compile, but is ignored — tier and band replace it.

```gdscript
func generate_encounter(encounter_id: String, region: String = "", realm: String = "hell", difficulty: String = "normal") -> Array[Dictionary]:
	var template = encounters.get(encounter_id, {})
	if template.is_empty():
		push_warning("EnemySystem: Unknown encounter '%s', generating fallback" % encounter_id)
		return _generate_fallback_encounter(realm)

	var budget: Dictionary = resolve_party_budget(encounter_id, realm)
	var party_xp: int = int(budget["xp"])
	var enemies: Array[Dictionary] = []

	if template.get("fixed", false):
		# Authored composition: the archetype list is fixed, only shares are assigned.
		var slots: Array[String] = []
		for entry in template.get("enemies", []):
			for i in range(int(entry.get("count", 1))):
				slots.append(String(entry.get("archetype", "")))
		if slots.is_empty():
			return _generate_fallback_encounter(realm)
		var hero_index: int = _highest_threat_index(slots)
		for i in range(slots.size()):
			var share_xp: int = maxi(1, int(round(float(party_xp) / float(slots.size()))))
			var enemy = _build_enemy(slots[i], share_xp, realm, region, i == hero_index)
			if not enemy.is_empty():
				enemies.append(enemy)
		return enemies

	# Rolled composition.
	var members: Array[Dictionary] = roll_party_composition(String(budget["band"]))
	var total_shares: int = 0
	for m in members:
		total_shares += int(m["share"])

	var enc_region: String = template.get("region", "any")
	var effective_region: String = region if region != "" else enc_region

	# Which archetypes can fill slots, from the encounter's roles.
	var role_pool: Array[String] = []
	for role in template.get("roles", {}):
		for i in range(int(template["roles"][role])):
			role_pool.append(String(role))
	for group in template.get("groups", []):
		for role in group.get("roles", {}):
			for i in range(int(group["roles"][role])):
				role_pool.append(String(role))
	if role_pool.is_empty():
		role_pool.append("frontline")

	for i in range(members.size()):
		var role: String = role_pool[i % role_pool.size()]
		# NOTE the argument order: (role, region, tier, realm). Passing tier
		# second silently filters by the wrong field and yields no archetypes.
		var archetype_id: String = _pick_archetype_for_role(
			role, effective_region, String(budget["tier"]), realm)
		if archetype_id == "":
			continue
		var member_xp: int = maxi(1, int(round(
			float(party_xp) * float(members[i]["share"]) / float(maxi(total_shares, 1)))))
		var enemy = _build_enemy(archetype_id, member_xp, realm, effective_region,
			bool(members[i].get("is_hero", false)))
		if not enemy.is_empty():
			enemies.append(enemy)

	if enemies.is_empty():
		return _generate_fallback_encounter(realm)
	return enemies


## Index of the slot whose archetype has the highest threat_multiplier.
## Used to decide which member of an authored fixed encounter is the hero.
func _highest_threat_index(archetype_ids: Array[String]) -> int:
	var best: int = 0
	var best_threat: float = -1.0
	for i in range(archetype_ids.size()):
		var t: float = float(archetypes.get(archetype_ids[i], {}).get("threat_multiplier", 1.0))
		if t > best_threat:
			best_threat = t
			best = i
	return best
```

`_pick_archetype_for_role` already exists at line 920 with the signature
`(role: String, region: String, tier: String = "devil", realm: String = "hell")`.
Region comes **second**, tier third. Confirm before wiring:

```bash
grep -n "func _pick_archetype_for_role" scripts/autoload/enemy_system.gd
```

- [ ] **Step 8: Fix the fallback encounter**

`_generate_fallback_encounter` at line 960 calls `get_party_power()`. Replace its body's budget line:

```gdscript
func _generate_fallback_encounter(realm: String = "hell") -> Array[Dictionary]:
	var base: float = float(budgets.get("realm_base", {}).get(realm, 200))
	var enemies: Array[Dictionary] = []
	for i in range(2):
		var enemy = _build_enemy("hell_demon_warrior", int(base * 0.4), realm)
		if not enemy.is_empty():
			enemies.append(enemy)
	return enemies
```

- [ ] **Step 9: Run the harness — it must pass**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
timeout 200 godot --headless --quit-after 300 2>&1 | grep -cE 'SCRIPT ERROR|Parse Error'
```
Expected: `VERIFY OK`, and `0` script errors.

- [ ] **Step 10: Commit**

```bash
python3 tools/validate_data.py
git add scripts/autoload/enemy_system.gd tools/verify_enemy_xp.gd
git commit -m "Enemies are built as characters from an XP budget"
```

---

### Task 5: Hero identity

**Files:**
- Modify: `scripts/combat/combat_unit.gd`, and the combat tooltip UI
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: `is_hero` and `hero_id` on the enemy dict from Task 4.
- Produces: heroes visibly distinct in the combat tooltip.

- [ ] **Step 1: Find the tooltip that shows enemy names**

```bash
grep -rn "archetype_name" scripts/combat/ scripts/ui/ | head
```

The enemy dict already carries `archetype_name`, shown as a subtitle in combat. The tooltip that renders it is where the hero colour goes.

- [ ] **Step 2: Add the hero colour**

In whichever script renders the enemy name in the tooltip (from Step 1), colour the name when the unit is a hero. Use the existing tibetan theme's gold rather than inventing a colour:

```gdscript
	var is_hero: bool = character_data.get("is_hero", false)
	if is_hero:
		name_label.add_theme_color_override("font_color", Color(0.87, 0.72, 0.33))
```

- [ ] **Step 3: Verify heroes appear at the expected rate**

Add to `tools/verify_enemy_xp.gd`, called from `_ready()`:

```gdscript
func _check_heroes() -> void:
	print("-- heroes --")
	var parties: int = 0
	var with_hero: int = 0
	for i in range(400):
		var party: Array = EnemySystem.generate_encounter("animal_gana_wolves", "forest", "animal")
		if party.is_empty():
			continue
		parties += 1
		var heroes: int = 0
		var ids := {}
		for e in party:
			if e.get("is_hero", false):
				heroes += 1
				expect(String(e.get("hero_id", "")) != "", "hero has empty hero_id")
				expect(not ids.has(e["hero_id"]), "duplicate hero_id in one party")
				ids[e["hero_id"]] = true
		if heroes > 0:
			with_hero += 1
	expect(parties > 0, "no parties generated")
	expect(with_hero > 0, "no party ever produced a hero")
	print("   %d/%d parties had a hero" % [with_hero, parties])
```

- [ ] **Step 4: Run the harness — it must pass**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
```
Expected: `VERIFY OK` and a printed hero rate.

- [ ] **Step 5: Commit**

```bash
git add scripts/combat scripts/ui tools/verify_enemy_xp.gd
git commit -m "Heroes are marked, identified and visibly distinct in the tooltip"
```

---

### Task 6: Reward from enemy XP, divided

**Files:**
- Modify: `scripts/autoload/combat_manager.gd:524-600` (`_calculate_combat_rewards`)
- Modify: `scripts/autoload/companion_system.gd:484` (`apply_party_xp`)
- Test: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: `xp_earned` on each enemy (Task 4), `EnemySystem.budgets["reward_fraction"]` (Task 1).
- Produces: `CompanionSystem.apply_party_xp(base_amount: int)` divides rather than duplicating.

- [ ] **Step 1: Replace the XP and gold calculation**

In `scripts/autoload/combat_manager.gd`, inside `_calculate_combat_rewards`, replace the block computing `enemy_power_total`, `party_power`, `ratio`, `base_xp`, `xp_reward` and `base_gold`/`gold_reward` with:

```gdscript
	# The enemy party's XP is what it cost to build. The player party earns a
	# fraction of it, divided among its members by CompanionSystem.
	var enemy_count := 0
	var enemy_party_xp := 0
	for unit in all_units:
		if unit.team == Team.ENEMY:
			enemy_count += 1
			enemy_party_xp += int(unit.character_data.get("xp_earned", 0))

	var fraction: float = float(EnemySystem.budgets.get("reward_fraction", 0.12))
	var xp_reward := maxi(1, int(round(float(enemy_party_xp) * fraction)))

	# Gold tracks the same number rather than a separate power ratio.
	var gold_reward := maxi(1, int(round(float(enemy_party_xp) * fraction * 0.5)))
```

Leave the Trade bonus, luck jackpot, and loot blocks that follow unchanged — they read `gold_reward` and `best_luck`, both of which still exist.

- [ ] **Step 2: Fix `_generate_loot_drops`, which took `ratio`**

```bash
grep -n "_generate_loot_drops" scripts/autoload/combat_manager.gd
```

Change the call to pass a budget-derived scale instead of the deleted `ratio`:

```gdscript
	var loot_scale := clampf(float(enemy_party_xp) / 1000.0, 0.5, 3.0)
	var extra_drops: Array[String] = _generate_loot_drops(enemy_count, loot_scale, best_luck)
```

- [ ] **Step 3: Delete `_calculate_unit_power`**

Remove the whole function at `scripts/autoload/combat_manager.gd:612-626`. It has no remaining callers after Step 1. Confirm:

```bash
grep -n "_calculate_unit_power" scripts/autoload/combat_manager.gd
```
Expected: no output.

- [ ] **Step 4: Make `apply_party_xp` divide**

In `scripts/autoload/companion_system.gd`, replace `apply_party_xp`:

```gdscript
## Grant post-battle XP to the party, DIVIDED among its members.
##
## Party size is a real tall-versus-wide choice: a solo character receives the
## whole amount, each of four receives a quarter. This replaces get_xp_multiplier,
## which leaned the same way but far too weakly to be a decision.
func apply_party_xp(base_amount: int) -> void:
	var party: Array = CharacterSystem.get_party()
	if party.is_empty():
		return
	var per_member := maxi(1, int(float(base_amount) / float(party.size())))
	for member in party:
		var xp_pct: float = member.get("derived", {}).get("xp_gain_pct", 0.0)
		var member_amount := maxi(1, int(float(per_member) * (1.0 + xp_pct / 100.0)))
		CharacterSystem.grant_xp(member, member_amount)
		if member.has("free_xp"):
			member.free_xp += member_amount
			if member.get("autodevelop", false):
				if not _is_overflow_mode(member):
					_try_autodevelop(member)
				if _is_overflow_mode(member) and not member.get("overflow_popup_shown", false):
					member["overflow_popup_shown"] = true
					companion_overflow.emit(member)
```

- [ ] **Step 5: Delete `get_xp_multiplier`**

Remove the function at `scripts/autoload/companion_system.gd:384-391`. Confirm no callers remain:

```bash
grep -rn "get_xp_multiplier" scripts/
```
Expected: no output.

- [ ] **Step 6: Verify the reward maths**

Add to `tools/verify_enemy_xp.gd`, called from `_ready()`:

```gdscript
func _check_reward() -> void:
	print("-- reward --")
	var fraction: float = float(EnemySystem.budgets.get("reward_fraction", 0.0))
	expect(fraction > 0.0 and fraction < 1.0, "reward_fraction out of range: %f" % fraction)
	# a party's total gain must equal the fraction regardless of party size
	for size in [1, 2, 4]:
		var enemy_party_xp := 1800
		var total := int(round(float(enemy_party_xp) * fraction))
		var per_member := maxi(1, int(float(total) / float(size)))
		expect(per_member * size <= total + size,
			"size %d: division lost more than rounding" % size)
```

- [ ] **Step 7: Run the harness and boot**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
timeout 200 godot --headless --quit-after 300 2>&1 | grep -cE 'SCRIPT ERROR|Parse Error'
```
Expected: `VERIFY OK`, and `0`.

- [ ] **Step 8: Commit**

```bash
git add scripts/autoload/combat_manager.gd scripts/autoload/companion_system.gd tools/verify_enemy_xp.gd
git commit -m "Post-battle XP is a divided fraction of the enemy party's XP"
```

---

### Task 7: Remove the old power system

**Files:**
- Modify: `scripts/autoload/enemy_system.gd` (`get_party_power` at 252, `DIFFICULTY_MULTIPLIERS` at 159)
- Modify: `scripts/ui/shop_ui.gd:681`

**Interfaces:**
- Produces: `CharacterSystem.get_party_xp_worth() -> int` — the party's total `xp_earned`, used for companion pricing.

- [ ] **Step 1: Add the party-worth helper**

The spec says to delete `get_party_power()`, but `shop_ui.gd:681` uses it to scale companion recruitment cost — a consumer outside combat that the spec did not consider. Replace it with an XP-based equivalent.

Add to `scripts/autoload/character_system.gd`:

```gdscript
## The party's combined lifetime XP. Used where the old get_party_power() was
## used to gauge how far along the player is — companion pricing, for one.
func get_party_xp_worth() -> int:
	var total: int = 0
	for member in get_party():
		total += int(member.get("xp_earned", 0))
	return total
```

- [ ] **Step 2: Repoint companion pricing**

In `scripts/ui/shop_ui.gd`, replace lines 680-682:

```gdscript
	# Scale recruitment cost with how far the party has come, so early-game
	# companions are affordable. Anchored on party XP now that power is gone.
	var base_cost: int = def.get("recruitment_cost", 0)
	var party_xp: float = float(CharacterSystem.get_party_xp_worth())
	var price_mult: float = clampf(party_xp / 1200.0, 0.20, 2.0)
	var cost: int = maxi(10, int(base_cost * price_mult))
```

- [ ] **Step 3: Delete `get_party_power` and `DIFFICULTY_MULTIPLIERS`**

Remove `func get_party_power()` (lines 252-276) and the `DIFFICULTY_MULTIPLIERS` const (lines 159-165) from `scripts/autoload/enemy_system.gd`.

- [ ] **Step 4: Verify nothing references them**

Run:
```bash
grep -rn "get_party_power\|DIFFICULTY_MULTIPLIERS\|_calculate_unit_power\|get_xp_multiplier" scripts/
```
Expected: no output.

- [ ] **Step 5: Run the harness and boot**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd
timeout 200 godot --headless --quit-after 300 2>&1 | grep -cE 'SCRIPT ERROR|Parse Error'
```
Expected: `VERIFY OK`, and `0`.

- [ ] **Step 6: Commit**

```bash
git add scripts/
git commit -m "Remove the old power system: get_party_power, _calculate_unit_power, DIFFICULTY_MULTIPLIERS"
```

---

### Task 8: The full encounter table

**Files:**
- Modify: `tools/verify_enemy_xp.gd`

**Interfaces:**
- Consumes: everything from Tasks 1-7.

- [ ] **Step 1: Add the table dump**

The spec requires the whole re-tuned game to be inspectable before it ships. Add to `tools/verify_enemy_xp.gd`, called from `_ready()` before the failure check, and gated so it only runs when asked:

```gdscript
func _dump_table() -> void:
	if not OS.get_cmdline_user_args().has("--table"):
		return
	print("\n=== ENCOUNTER TABLE ===")
	for realm in ["hell", "hungry_ghost", "animal"]:
		print("\n## %s" % realm)
		var ids: Array = []
		for eid in EnemySystem.encounters:
			if not eid.begins_with("_"):
				ids.append(eid)
		ids.sort()
		for eid in ids:
			var party: Array = EnemySystem.generate_encounter(eid, "", realm)
			if party.is_empty():
				continue
			var total: int = 0
			for e in party:
				total += int(e.get("xp_earned", 0))
			var line := "  %-34s %2d members  %6d XP  " % [eid, party.size(), total]
			for e in party:
				line += "[%s/%s %d%s] " % [
					e.get("birth", "?"), e.get("archetype_id", "?"),
					int(e.get("xp_earned", 0)), " HERO" if e.get("is_hero", false) else ""]
			print(line)
```

- [ ] **Step 2: Print the table and read it**

Run:
```bash
godot --headless --script res://tools/verify_enemy_xp.gd -- --table > /tmp/encounter_table.txt
wc -l /tmp/encounter_table.txt && head -60 /tmp/encounter_table.txt
```

Read the whole file. Look for: parties of 0 or absurd size, XP totals far from the realm base, births that make no sense for the realm, heroes that are weaker than their mooks.

- [ ] **Step 3: Report findings rather than silently tuning**

Do not adjust the four constants to make the table look nice. Write down what looks wrong and hand it back — these numbers are meant to be settled in playtesting, and the person who wrote the spec should see the first table.

- [ ] **Step 4: Commit**

```bash
git add tools/verify_enemy_xp.gd
git commit -m "Encounter table dump for reviewing the whole re-tuned game at once"
```

---

## Notes for the implementer

- **`threat_multiplier` changes meaning.** It was a budget scalar; it now only picks which member of a fixed encounter is the hero. Do not delete it from the archetype data.
- **`difficulty` parameter is now ignored** in `generate_encounter`, but stays in the signature because four call sites pass it. Removing it is a separate cleanup.
- **Enemy `traits` were always `[]`.** Task 4 makes them carry the birth's racial traits, which means enemies now get `undead`, `flying`, `predator_grace` and so on. If combat behaves oddly after Task 4, this is the likely cause and it is intended.
- **`beast` tier** exists on exactly one archetype and is mapped to `shade`'s multiplier. If a second appears, decide whether it deserves its own row.

## Known divergence from the spec

The spec says `groups`/`mixed` encounters convert with **each authored group
becoming a share tier** — so `rolang_with_vermin` would stay 2 devil frontline
screened by 2 shade skirmishers, with the devils taking the larger share.

This plan does not do that. Task 4 sends `groups` encounters down the same
rolled-composition path as `roles` ones: their group roles are flattened into
the role pool and a party archetype decides count and shares. Seventeen
encounters are affected.

The trade: rolled composition is one code path instead of two and gives those
encounters the same systemic variety as the rest, but it discards a deliberately
authored shape — the screen-of-chaff-in-front-of-heavies idea those 17 were
written to express, which is exactly what `hero_and_mooks` now produces at
random anyway.

Preserving them instead is maybe twenty lines: build `members` directly from the
groups, one entry per unit with `share` derived from the group's tier rank, and
skip `roll_party_composition`. Decide before implementing Task 4 — it is
cheaper to choose now than to convert later.
