# Accessory Generator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement procedural ring, amulet, and necklace generation using attribute-anchored synergy groups and a budget-point allocation system.

**Architecture:** A data file (`accessory_tables.json`) holds all pools, costs, and name parts. A new function `generate_accessory(item_type, rarity)` in `item_system.gd` reads from that data, rolls a synergy group (or wild), spends budget points on stats/skills/perks, and calls `register_runtime_item()` to return a `gen_XXXX` ID. Integration hooks add accessories to existing loot pipelines.

**Tech Stack:** GDScript 4.3, Godot 4.3, JSON data files

---

## Chunk 1: Data File

### Task 1: Create `resources/data/accessory_tables.json`

**Files:**
- Create: `resources/data/accessory_tables.json`

This file is the sole source of truth for all accessory generation parameters. It follows the same top-level conventions as `talisman_tables.json` but uses a completely different internal structure (synergy groups instead of weighted pools).

**Key structural decisions:**
- `rarity_budgets`: integer point totals and effect caps per rarity, plus `skill_chance` and `perk_chance` floats
- `stat_costs`: each stat has `cost` (budget points consumed), `min` and `max` (random roll range for the stat value — a single purchase, not per-point)
- `synergy_groups`: keyed by group name, each has `primary_stats`, `secondary_stats`, `skills`, `suffixes`, `perk_pool` (list of perk IDs from the `perks` array below)
- `perks`: master list of perk objects with `id`, `name`, `cost`, `description` — same IDs as `talisman_tables.json` perks, subset that makes sense on accessories
- `name_parts.prefixes`: keyed by rarity (not flat list)
- `name_parts.forms`: keyed by item type (`ring`, `amulet`, `necklace`)

Perk IDs referenced in `perk_pool` arrays must exist in the `perks` array below. All skill IDs in `skills` arrays use full IDs (e.g., `"white_magic"` not `"white"`).

- [ ] **Step 1: Write the data file**

```json
{
	"_comment": "Accessory generation tables for procedural rings, amulets, and necklaces",

	"rarity_budgets": {
		"common":    {"points": 2, "max_effects": 1, "skill_chance": 0.0, "perk_chance": 0.0},
		"uncommon":  {"points": 4, "max_effects": 2, "skill_chance": 0.0, "perk_chance": 0.0},
		"rare":      {"points": 7, "max_effects": 3, "skill_chance": 0.3, "perk_chance": 0.0},
		"epic":      {"points": 12, "max_effects": 3, "skill_chance": 0.6, "perk_chance": 0.2},
		"legendary": {"points": 18, "max_effects": 4, "skill_chance": 0.8, "perk_chance": 0.5}
	},

	"stat_costs": {
		"damage":       {"cost": 1, "min": 2, "max": 4},
		"armor":        {"cost": 1, "min": 1, "max": 3},
		"dodge":        {"cost": 1, "min": 2, "max": 4},
		"crit_chance":  {"cost": 1, "min": 1, "max": 2},
		"initiative":   {"cost": 1, "min": 1, "max": 3},
		"movement":     {"cost": 2, "min": 1, "max": 1},
		"max_hp":       {"cost": 1, "min": 5, "max": 10},
		"max_mana":     {"cost": 1, "min": 5, "max": 10},
		"max_stamina":  {"cost": 1, "min": 5, "max": 8},
		"spellpower":   {"cost": 1, "min": 2, "max": 4},
		"strength":     {"cost": 2, "min": 1, "max": 1},
		"finesse":      {"cost": 2, "min": 1, "max": 1},
		"constitution": {"cost": 2, "min": 1, "max": 1},
		"focus":        {"cost": 2, "min": 1, "max": 1},
		"awareness":    {"cost": 2, "min": 1, "max": 1},
		"charm":        {"cost": 2, "min": 1, "max": 1},
		"luck":         {"cost": 2, "min": 1, "max": 1}
	},

	"synergy_groups": {
		"strength": {
			"primary_stats":   ["damage", "armor"],
			"secondary_stats": ["max_hp"],
			"skills":          ["swords", "axes", "maces", "unarmed", "armor"],
			"suffixes":        ["of the Ox", "of the Bear", "of the Yak", "of the Boar", "of the Bull Elephant", "of Crushing Force", "of Iron Will"],
			"perk_pool":       ["thorns", "phys_brand", "fire_brand", "lifesteal", "stun_resist"]
		},
		"finesse": {
			"primary_stats":   ["dodge", "crit_chance"],
			"secondary_stats": ["initiative", "movement"],
			"skills":          ["daggers", "ranged", "thievery", "guile"],
			"suffixes":        ["of the Crow", "of Stolen Steps", "of the Viper", "of the Cat", "of the Fox", "of the Heron", "of the Mongoose", "of Quick Hands"],
			"perk_pool":       ["blur", "lucky_escape", "air_brand", "poison_brand", "fear_resist"]
		},
		"constitution": {
			"primary_stats":   ["max_hp", "max_stamina"],
			"secondary_stats": ["armor"],
			"skills":          ["might", "martial_arts"],
			"suffixes":        ["of the Tortoise", "of the Badger", "of the Sleeping Bear", "of Stone Flesh", "of the Enduring"],
			"perk_pool":       ["regen_minor", "regen_moderate", "bleed_immune", "stun_resist", "thorns"]
		},
		"focus": {
			"primary_stats":   ["spellpower", "max_mana"],
			"secondary_stats": [],
			"skills":          ["fire_magic", "water_magic", "earth_magic", "air_magic", "space_magic", "white_magic", "black_magic", "sorcery", "enchantment", "summoning"],
			"suffixes":        ["of the Serpent", "of the Garuda", "of the Peacock", "of the Naga", "of the Mandala", "of the Dreaming Eye"],
			"perk_pool":       ["mana_trickle", "mana_stream", "magic_mirror", "fire_brand", "water_brand"]
		},
		"awareness": {
			"primary_stats":   ["max_mana", "initiative"],
			"secondary_stats": ["crit_chance"],
			"skills":          ["space_magic", "air_magic", "guile", "learning"],
			"suffixes":        ["of the Owl", "of the Open Sky", "of the Raven", "of the Bat", "of Bardo's Edge", "of Subtle Sight"],
			"perk_pool":       ["blur", "lucky_escape", "magic_mirror", "fear_resist", "mental_immune"]
		},
		"charm": {
			"primary_stats":   ["luck", "crit_chance"],
			"secondary_stats": ["initiative"],
			"skills":          ["persuasion", "leadership", "performance"],
			"suffixes":        ["of the Songbird", "of the Golden Pheasant", "of the Deer", "of Silver Words", "of Pleasant Lies"],
			"perk_pool":       ["charm_immune", "fear_resist", "karma_sight", "regen_minor", "mental_immune"]
		},
		"luck": {
			"primary_stats":   ["crit_chance", "dodge"],
			"secondary_stats": ["max_hp"],
			"skills":          ["thievery", "guile", "alchemy"],
			"suffixes":        ["of the Magpie", "of the Three-Legged Toad", "of the White Rabbit", "of the Lucky Bone", "of Samsara's Whim", "of the Fortunate Fall"],
			"perk_pool":       ["lucky_escape", "karma_sight", "bleed_resist", "poison_resist", "risen_dead"]
		},
		"wild": {
			"primary_stats":   [],
			"secondary_stats": [],
			"skills":          [],
			"suffixes":        ["of Unclear Purpose", "of Strange Workmanship", "of the Confused Pilgrim", "of the Lost Traveler"],
			"perk_pool":       ["thorns", "blur", "karma_sight", "magic_mirror", "lucky_escape", "risen_dead"]
		}
	},

	"perks": [
		{"id": "bleed_resist",   "name": "Bleed Resistance",         "cost": 2, "description": "50% chance to resist Bleeding"},
		{"id": "bleed_immune",   "name": "Bleed Immunity",           "cost": 3, "description": "Immune to Bleeding status"},
		{"id": "poison_resist",  "name": "Poison Resistance",        "cost": 2, "description": "50% chance to resist Poisoned"},
		{"id": "fear_resist",    "name": "Fear Resistance",          "cost": 2, "description": "50% chance to resist Feared"},
		{"id": "charm_immune",   "name": "Charm Immunity",           "cost": 3, "description": "Immune to Charmed status"},
		{"id": "stun_resist",    "name": "Stun Resistance",          "cost": 3, "description": "50% chance to resist Stun"},
		{"id": "mental_immune",  "name": "Mind Fortress",            "cost": 7, "description": "Immune to all mental effects (Fear, Charm, Confusion, Berserk)"},
		{"id": "regen_minor",    "name": "Minor Regeneration",       "cost": 4, "description": "Regenerate 2% of max HP per turn, rounded up"},
		{"id": "regen_moderate", "name": "Moderate Regeneration",    "cost": 7, "description": "Regenerate 4% of max HP per turn, rounded up"},
		{"id": "mana_trickle",   "name": "Mana Trickle",            "cost": 4, "description": "Regenerate 2% of max mana per turn, rounded up"},
		{"id": "mana_stream",    "name": "Mana Stream",             "cost": 7, "description": "Regenerate 4% of max mana per turn, rounded up"},
		{"id": "thorns",         "name": "Thorns",                  "cost": 5, "description": "Reflect 3 damage to melee attackers"},
		{"id": "lucky_escape",   "name": "Lucky Escape",            "cost": 4, "description": "+15% dodge when below 25% HP"},
		{"id": "karma_sight",    "name": "Karma Sight",             "cost": 3, "description": "Reveals karma changes in events"},
		{"id": "risen_dead",     "name": "Hungry Ghost Binding",    "cost": 6, "description": "15% chance that enemies slain by this character rise as allied undead for the remainder of combat"},
		{"id": "magic_mirror",   "name": "Magic Mirror",            "cost": 5, "description": "10% chance to reflect hostile incoming spells back at the caster"},
		{"id": "blur",           "name": "Blur",                    "cost": 4, "description": "+10% dodge chance"},
		{"id": "lifesteal",      "name": "Lifesteal",               "cost": 5, "description": "Heal for 15% of damage dealt by attacks"},
		{"id": "fire_brand",     "name": "Ember Brand",             "cost": 4, "description": "Attacks deal +10% base damage as bonus fire damage, rounded up"},
		{"id": "water_brand",    "name": "Frost Brand",             "cost": 4, "description": "Attacks deal +10% base damage as bonus water damage, rounded up"},
		{"id": "air_brand",      "name": "Storm Brand",             "cost": 4, "description": "Attacks deal +10% base damage as bonus air damage, rounded up"},
		{"id": "phys_brand",     "name": "Iron Brand",              "cost": 4, "description": "Attacks deal +10% base damage as bonus physical damage, rounded up"},
		{"id": "poison_brand",   "name": "Venom Brand",             "cost": 4, "description": "Attacks deal +10% base damage as poison and 10% chance to inflict Poisoned, rounded up"}
	],

	"name_parts": {
		"prefixes": {
			"common":    ["Copper", "Bone", "Crude", "Scratched", "Tarnished"],
			"uncommon":  ["Silver", "Jade", "Carved", "Worn", "Conch", "Lacquer"],
			"rare":      ["Onyx", "Amber", "Inscribed", "Ancient", "Lapis"],
			"epic":      ["Obsidian", "Ivory", "Runed", "Wrathful"],
			"legendary": ["Crystal", "Void", "Dakini Hair", "Sapphire", "Emerald", "Ruby"]
		},
		"forms": {
			"ring":     ["Ring", "Band", "Loop", "Signet", "Seal", "Coil"],
			"amulet":   ["Amulet", "Pendant", "Token", "Ward", "Lingam", "Eye"],
			"necklace": ["Necklace", "Chain", "Cord", "Beads", "Strand", "Braid"]
		}
	},

	"value_per_budget_point": 10,

	"skill_bonus_cost": 3,

	"_notes": {
		"perk_pool": "Per-group perk_pool keys are intentional — the spec's top-level perk_pools concept is implemented as per-group arrays for locality.",
		"perk_costs": "Perk costs match talisman_tables.json exactly for consistency. Budget gating in code ensures expensive perks only appear on high-rarity items.",
		"armor_collision": "The skill 'armor' and stat 'armor' share a name. Generator code processes skills via skill_pool (separate code path) and stats via stat_pool — no collision at runtime."
	}
}
```

- [ ] **Step 2: Verify file parses as valid JSON**

Run from project directory:
```bash
python3 -c "import json; json.load(open('resources/data/accessory_tables.json')); print('OK')"
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add resources/data/accessory_tables.json
git commit -m "feat: add accessory_tables.json with synergy groups, perk pools, and name parts"
```

---

## Chunk 2: Generator Code

### Task 2: Add loader and constants to `item_system.gd`

**Files:**
- Modify: `scripts/autoload/item_system.gd` (after line 891, after the complete talisman block ends — before the `# EQUIPMENT GENERATION` section at line 893)

The accessory tables are lazy-loaded the first time `generate_accessory()` is called, mirroring the talisman pattern. The ACCESSORY GENERATION section goes **after the full talisman section** (after `_generate_talisman_description()` ends at line ~891), keeping each generator's code contiguous.

`"necklace"` is NOT added to TALISMAN_TYPES. Instead, `can_generate_type()` is updated to also check ACCESSORY_TYPES, which is the semantically correct home for ring/amulet/necklace.

- [ ] **Step 1: Add `ACCESSORY_TYPES` constant near `TALISMAN_TYPES` (~line 1299)**

Find:
```gdscript
# Talisman types
const TALISMAN_TYPES: Array[String] = ["talisman", "trinket", "amulet", "ring", "charm"]
```

Add after it (do NOT modify TALISMAN_TYPES):
```gdscript
# Accessory types — procedurally generated via generate_accessory()
const ACCESSORY_TYPES: Array[String] = ["ring", "amulet", "necklace"]
```

- [ ] **Step 2: Update `can_generate_type()` to include ACCESSORY_TYPES**

Find:
```gdscript
func can_generate_type(item_type: String) -> bool:
	return item_type in WEAPON_TYPES or item_type in ARMOR_TYPES or item_type in TALISMAN_TYPES
```

Replace with:
```gdscript
func can_generate_type(item_type: String) -> bool:
	return item_type in WEAPON_TYPES or item_type in ARMOR_TYPES or item_type in TALISMAN_TYPES or item_type in ACCESSORY_TYPES
```

- [ ] **Step 3: Add the ACCESSORY GENERATION block — insert between line 891 (end of talisman section) and line 893 (`# EQUIPMENT GENERATION` comment)**

Find:
```gdscript
	return " ".join(parts)


# ============================================
# EQUIPMENT GENERATION
# ============================================
```

Insert the new section before `# EQUIPMENT GENERATION`:
```gdscript
	return " ".join(parts)


# ============================================
# ACCESSORY GENERATION
# ============================================

# Accessory generation tables (loaded from JSON)
var _accessory_tables: Dictionary = {}

## Load accessory generation tables from JSON
func _load_accessory_tables() -> void:
	var file_path = "res://resources/data/accessory_tables.json"
	if not FileAccess.file_exists(file_path):
		push_warning("ItemSystem: accessory_tables.json not found")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_accessory_tables = json.get_data()
	file.close()


# ============================================
# EQUIPMENT GENERATION
# ============================================
```

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/item_system.gd
git commit -m "feat: add ACCESSORY_TYPES const, update can_generate_type, add accessory table loader"
```

---

### Task 3: Implement `generate_accessory()` in `item_system.gd`

**Files:**
- Modify: `scripts/autoload/item_system.gd` (inside the ACCESSORY GENERATION section added in Task 2)

Add the main generator function immediately after `_load_accessory_tables()`.

**Algorithm summary:**
1. Load tables if needed
2. Read budget for rarity: `points`, `max_effects`, `skill_chance`, `perk_chance`
3. Roll synergy group: if `max_effects > 1` AND `randf() < 0.20` → wild; else pick random non-wild group
4. Build stat pool: wild → all stats from `stat_costs` keys; synergy → `primary_stats + secondary_stats`
5. Roll perk (if `perk_chance > 0` and budget allows): pick random affordable perk from group's `perk_pool`
6. Roll skill +1 (if `skill_chance > 0` and remaining budget ≥ 3): pick random skill from group's `skills`
7. Roll stat effects: loop up to `max_effects`, pick affordable unused stats from pool, roll value in [min, max], subtract `cost` from budget
8. Build item dict and call `register_runtime_item()`

- [ ] **Step 1: Add `generate_accessory()` after `_load_accessory_tables()`**

```gdscript
## Generate a procedural ring, amulet, or necklace. Returns the gen_XXXX item ID.
## item_type: "ring", "amulet", or "necklace"
## rarity: "common", "uncommon", "rare", "epic", "legendary"
func generate_accessory(item_type: String, rarity: String = "common") -> String:
	if _accessory_tables.is_empty():
		_load_accessory_tables()
	if _accessory_tables.is_empty():
		push_error("ItemSystem: Cannot generate accessory - accessory_tables.json missing")
		return ""

	var budgets: Dictionary = _accessory_tables.get("rarity_budgets", {})
	var budget_info: Dictionary = budgets.get(rarity, budgets.get("common", {}))
	var total_budget: int = int(budget_info.get("points", 2))
	var max_effects: int = int(budget_info.get("max_effects", 1))
	var skill_chance: float = float(budget_info.get("skill_chance", 0.0))
	var perk_chance: float = float(budget_info.get("perk_chance", 0.0))

	var synergy_groups: Dictionary = _accessory_tables.get("synergy_groups", {})
	var stat_costs: Dictionary = _accessory_tables.get("stat_costs", {})
	var perks_list: Array = _accessory_tables.get("perks", [])
	var value_per_pt: int = int(_accessory_tables.get("value_per_budget_point", 10))
	var skill_bonus_cost: int = int(_accessory_tables.get("skill_bonus_cost", 3))

	# Build perk lookup: id -> perk dict (for cost checks)
	var perk_lookup: Dictionary = {}
	for p in perks_list:
		perk_lookup[p.get("id", "")] = p

	# Collect non-wild group names
	var non_wild_groups: Array = []
	for gname in synergy_groups.keys():
		if gname != "wild":
			non_wild_groups.append(gname)

	# Roll synergy group (20% wild on multi-effect items only)
	var group_name: String
	if max_effects > 1 and randf() < 0.20:
		group_name = "wild"
	else:
		group_name = non_wild_groups[randi() % non_wild_groups.size()]
	var group: Dictionary = synergy_groups.get(group_name, {})

	# Build stat pool for this group
	var stat_pool: Array = []
	if group_name == "wild":
		for stat in stat_costs.keys():
			stat_pool.append(stat)
	else:
		for s in group.get("primary_stats", []):
			stat_pool.append(s)
		for s in group.get("secondary_stats", []):
			stat_pool.append(s)

	var stats: Dictionary = {}
	var skill_bonuses: Dictionary = {}
	var chosen_perk: Dictionary = {}
	var remaining_budget: int = total_budget

	# 1. Maybe roll a perk first (most expensive, claim budget first)
	if perk_chance > 0.0 and randf() < perk_chance:
		var perk_pool_ids: Array = group.get("perk_pool", [])
		var affordable: Array = []
		for pid in perk_pool_ids:
			if pid in perk_lookup:
				var pd: Dictionary = perk_lookup[pid]
				if int(pd.get("cost", 99)) <= remaining_budget:
					affordable.append(pd)
		if not affordable.is_empty():
			chosen_perk = affordable[randi() % affordable.size()]
			remaining_budget -= int(chosen_perk.get("cost", 0))

	# 2. Maybe roll a skill +1 (cost read from JSON "skill_bonus_cost", default 3)
	# Note: skill IDs from group["skills"] are character skill names, not stat_costs keys.
	# Processing skills separately from stats avoids the "armor" skill/stat name collision.
	if skill_chance > 0.0 and randf() < skill_chance and remaining_budget >= skill_bonus_cost:
		var skill_pool: Array = group.get("skills", [])
		if not skill_pool.is_empty():
			var chosen_skill: String = skill_pool[randi() % skill_pool.size()]
			skill_bonuses[chosen_skill] = 1
			remaining_budget -= skill_bonus_cost

	# 3. Roll stat effects until max_effects reached or budget exhausted
	var effects_added: int = 0
	var used_stats: Array = []

	while effects_added < max_effects and remaining_budget >= 1:
		# Find affordable unused stats
		var valid_stats: Array = []
		for stat in stat_pool:
			if stat in used_stats:
				continue
			if not stat in stat_costs:
				continue
			var sc: Dictionary = stat_costs[stat]
			if int(sc.get("cost", 99)) <= remaining_budget:
				valid_stats.append(stat)

		if valid_stats.is_empty():
			break

		var chosen_stat: String = valid_stats[randi() % valid_stats.size()]
		var sc: Dictionary = stat_costs[chosen_stat]
		var cost: int = int(sc.get("cost", 1))
		var min_val: int = int(sc.get("min", 1))
		var max_val: int = int(sc.get("max", 1))

		var value: int = min_val + (randi() % (max_val - min_val + 1))
		remaining_budget -= cost
		used_stats.append(chosen_stat)
		stats[chosen_stat] = value
		effects_added += 1

	# Build name, slot, value, description
	var item_name: String = _generate_accessory_name(item_type, rarity, group_name)
	var slot: String = "ring1" if item_type == "ring" else "trinket1"
	var gold_value: int = total_budget * value_per_pt

	var item_data: Dictionary = {
		"name": item_name,
		"type": item_type,
		"slot": slot,
		"two_handed": false,
		"rarity": rarity,
		"element": group_name,
		"weight": 0,
		"value": gold_value,
		"description": _generate_accessory_description(stats, skill_bonuses, chosen_perk),
		"requirements": {},
		"stats": stats,
		"abilities": []
	}

	if not skill_bonuses.is_empty():
		item_data["skill_bonuses"] = skill_bonuses

	if not chosen_perk.is_empty():
		item_data["passive"] = {"perk": chosen_perk.get("id", "")}

	return register_runtime_item(item_data)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/autoload/item_system.gd
git commit -m "feat: implement generate_accessory() with synergy group budget allocation"
```

---

### Task 4: Implement name and description helpers

**Files:**
- Modify: `scripts/autoload/item_system.gd` (after `generate_accessory()`)

- [ ] **Step 1: Add `_generate_accessory_name()` immediately after `generate_accessory()`**

```gdscript
## Build a name for a generated accessory: [Prefix] [Form] [Suffix]
## synergy_group: group name key from synergy_groups, or "wild"
func _generate_accessory_name(item_type: String, rarity: String, synergy_group: String) -> String:
	var name_parts: Dictionary = _accessory_tables.get("name_parts", {})

	# Prefix: pick from rarity tier, fallback to common if rarity not found
	var all_prefixes: Dictionary = name_parts.get("prefixes", {})
	var prefix_list: Array = all_prefixes.get(rarity, all_prefixes.get("common", ["Copper"]))
	var prefix: String = prefix_list[randi() % prefix_list.size()]

	# Form: pick from item type list
	var all_forms: Dictionary = name_parts.get("forms", {})
	var form_list: Array = all_forms.get(item_type, ["Ring"])
	var form: String = form_list[randi() % form_list.size()]

	# Suffix: pick from synergy group's suffix pool
	var synergy_groups: Dictionary = _accessory_tables.get("synergy_groups", {})
	var group: Dictionary = synergy_groups.get(synergy_group, {})
	var suffix_list: Array = group.get("suffixes", ["of Unknown Origin"])
	var suffix: String = suffix_list[randi() % suffix_list.size()]

	return "%s %s %s" % [prefix, form, suffix]


## Build a readable description for a generated accessory
func _generate_accessory_description(stats: Dictionary, skill_bonuses: Dictionary,
		perk: Dictionary) -> String:
	var parts: Array = []
	for stat in stats:
		var val = stats[stat]
		var label = stat.replace("_", " ").capitalize()
		parts.append("+%d %s" % [val, label])
	for skill in skill_bonuses:
		var label = skill.replace("_", " ").capitalize()
		parts.append("+1 %s skill" % label)
	if not perk.is_empty():
		parts.append(perk.get("description", ""))
	return " | ".join(parts)
```

- [ ] **Step 2: Verify the ACCESSORY GENERATION section compiles — open Godot editor, check for script errors in Output panel. No errors means the code is parseable.**

- [ ] **Step 3: Commit**

```bash
git add scripts/autoload/item_system.gd
git commit -m "feat: add _generate_accessory_name and _generate_accessory_description helpers"
```

---

### Task 5: Wire `generate_accessory()` into the type routing functions

**Files:**
- Modify: `scripts/autoload/item_system.gd` (lines ~1346–1358, the `generate_item_for_type` and `resolve_random_generate` functions)

`ACCESSORY_TYPES` and the updated `can_generate_type()` were added in Task 2. This task only updates the routing functions. `generate_item_for_type` checks `ACCESSORY_TYPES` before `TALISMAN_TYPES` so ring/amulet are intercepted correctly (they remain in TALISMAN_TYPES for backward compatibility with static item handling — the ACCESSORY_TYPES check just takes precedence for generation).

- [ ] **Step 1: Update `generate_item_for_type()` to route accessory types**

Find:
```gdscript
func generate_item_for_type(item_type: String, rarity: String = "common") -> String:
	if item_type in WEAPON_TYPES:
		return generate_weapon(item_type, rarity)
	elif item_type in ARMOR_TYPES:
		return generate_armor(item_type, rarity)
	elif item_type in TALISMAN_TYPES:
		return generate_talisman(rarity)
	return ""
```

Replace with:
```gdscript
func generate_item_for_type(item_type: String, rarity: String = "common") -> String:
	if item_type in WEAPON_TYPES:
		return generate_weapon(item_type, rarity)
	elif item_type in ARMOR_TYPES:
		return generate_armor(item_type, rarity)
	elif item_type in ACCESSORY_TYPES:
		return generate_accessory(item_type, rarity)
	elif item_type in TALISMAN_TYPES:
		return generate_talisman(rarity)
	return ""
```

- [ ] **Step 3: Update `resolve_random_generate()` to handle `"accessory"` category**

Find the `match category:` block in `resolve_random_generate()` (~line 1320). After the `"talisman":` case, add:

```gdscript
		"accessory":
			var rarity = gen_config.get("rarity", "common")
			var acc_type = gen_config.get("type", "ring")
			return generate_accessory(acc_type, rarity)
```

- [ ] **Step 4: Quick smoke test — add a temp print to `_ready()` in item_system.gd, run Godot:**

```gdscript
# TEMP: remove after testing
func _ready() -> void:
	_load_item_database()
	print("ItemSystem initialized with ", _item_database.size(), " items")
	# Smoke test accessory generation
	var test_ring = generate_accessory("ring", "rare")
	var test_amulet = generate_accessory("amulet", "legendary")
	var test_necklace = generate_accessory("necklace", "epic")
	print("Accessory smoke test: ", test_ring, " / ", test_amulet, " / ", test_necklace)
	for gen_id in [test_ring, test_amulet, test_necklace]:
		var item = get_item(gen_id)
		print("  ", item.get("name", "?"), " | ", item.get("stats", {}), " | skills:", item.get("skill_bonuses", {}))
```

Expected output: three gen_XXXX IDs, each with a readable name like "Lapis Ring of the Crow" and some stats.

- [ ] **Step 5: Remove the temp print lines from `_ready()`, restoring it to original**

- [ ] **Step 6: Commit**

```bash
git add scripts/autoload/item_system.gd
git commit -m "feat: route ring/amulet/necklace types to generate_accessory()"
```

---

## Chunk 3: Integration

### Task 6: Verify hell.json bone pile accessory entries

**Files:**
- Read: `resources/data/map_configs/hell.json`
- Read: `resources/data/items.json` (verify IDs exist)

The bone pile tiers already include static accessory IDs from a previous session:
- Cold hell Bone Pile medium: `copper_ring`, `prayer_beads`
- Cold hell Bone Pile strong: `silver_ring`, `bone_amulet`
- Fire hell Charred Bone Pile medium: `copper_ring`, `travelers_amulet`
- Fire hell Charred Bone Pile strong: `silver_ring`, `bone_amulet`

- [ ] **Step 1: Verify these item IDs exist in items.json**

```bash
python3 -c "
import json
items = json.load(open('resources/data/items.json'))
for id in ['copper_ring','prayer_beads','silver_ring','bone_amulet','travelers_amulet']:
    status = 'OK' if id in items.get('items', items) else 'MISSING'
    print(f'{id}: {status}')
"
```

Expected: all five IDs print `OK`.

- [ ] **Step 2: If any IDs are MISSING — add them to the appropriate static item list in items.json, or replace with a known working accessory ID**

Items that should exist (check items.json for actual names): `copper_ring` is in the shop (shops.json confirms it), `silver_ring` is referenced in hell_01 bone pile strong. If any are missing, check items.json and substitute with confirmed IDs.

- [ ] **Step 3: No hell.json edit needed if all IDs are present. Commit only if items.json was modified.**

```bash
git add resources/data/items.json  # only if you added items
git commit -m "fix: add missing accessory items referenced in bone pile rewards"
```

**Note on combat loot:** `combat_manager.gd`'s `ROLE_LOOT_POOLS` already includes `"ring"` and `"amulet"` types in the ranged/caster/support pools. Now that `generate_item_for_type("ring", ...)` and `generate_item_for_type("amulet", ...)` route to `generate_accessory()`, procedural accessories will drop from combat automatically. No edits to combat_manager.gd needed.

**Note on shop integration:** Not included in this plan. Shops currently stock static items from shops.json. Adding procedural accessories to shops is a separate task.

---

### Task 7: Add `accessory_random` reward type to `event_manager.gd`

**Files:**
- Modify: `scripts/autoload/event_manager.gd` (the `apply_outcome()` function, ~line 430)

This allows event JSON to grant procedurally generated accessories as rewards. Format:
```json
"accessory_random": {"type": "ring", "rarity": "uncommon"}
```

- [ ] **Step 1: Add handler in `apply_outcome()` after the `"items"` handler**

Find:
```gdscript
		if "items" in rewards:
			for item_id in rewards.items:
				if ItemSystem.item_exists(item_id):
					ItemSystem.add_to_inventory(item_id)
				else:
					print("EventManager: Unknown item '%s', skipping" % item_id)
```

Add immediately after:
```gdscript
		# Procedural accessory reward — e.g. {"type": "ring", "rarity": "uncommon"}
		if "accessory_random" in rewards:
			var acc_cfg = rewards.accessory_random
			var acc_type: String = acc_cfg.get("type", "ring")
			var acc_rarity: String = acc_cfg.get("rarity", "common")
			var acc_id: String = ItemSystem.generate_accessory(acc_type, acc_rarity)
			if acc_id != "":
				ItemSystem.add_to_inventory(acc_id)
				var item = ItemSystem.get_item(acc_id)
				print("EventManager: Generated accessory '%s' (%s)" % [item.get("name", acc_id), acc_rarity])
			else:
				push_warning("EventManager: generate_accessory failed for type=%s rarity=%s" % [acc_type, acc_rarity])
```

- [ ] **Step 2: Verify no script errors in Godot's Output panel after saving**

- [ ] **Step 3: Commit**

```bash
git add scripts/autoload/event_manager.gd
git commit -m "feat: add accessory_random reward type to event_manager apply_outcome()"
```

---

### Task 8: Final integration smoke test

- [ ] **Step 1: Run the game to the overworld**

Check Godot's Output panel. Expected:
- No errors about missing `accessory_tables.json`
- No GDScript parse/runtime errors in item_system.gd or event_manager.gd

- [ ] **Step 2: Enter combat and finish it**

Check that combat loot drop code does not error. The existing `ROLE_LOOT_POOLS` already includes "ring", "amulet", "trinket" in ranged/caster/support loot pools. Now that "ring" and "amulet" route to `generate_accessory()` via `generate_item_for_type()`, procedural rings/amulets should appear in post-combat drops.

Check Godot Output for any `push_error` lines from generate_accessory.

- [ ] **Step 3: Open a bone pile on the overworld**

Verify the reward notification shows a ring or amulet (from static accessory items added to the bone pile tier lists).

- [ ] **Step 4: Commit any fixes found during smoke test**

---

## Summary of Files Changed

| File | Change |
|------|--------|
| `resources/data/accessory_tables.json` | **Created** — all generation data |
| `scripts/autoload/item_system.gd` | **Modified** — loader, `generate_accessory()`, two helpers, ACCESSORY_TYPES const, type routing |
| `scripts/autoload/event_manager.gd` | **Modified** — `accessory_random` reward type |
| `resources/data/map_configs/hell.json` | **Modified** — accessories in bone pile tiers |
