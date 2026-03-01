# Companion System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the full companion system — named recruitable party members with authored builds, weighted auto-distribution, autodevelop, and character-selector UI.

**Architecture:** CompanionSystem autoload handles data loading and the recruitment algorithm; CharacterSystem handles XP/stat management; main_menu.gd gets a character selector panel and free_xp display. Companions are standard character dicts with extra fields, so all existing combat/equipment/spell systems work on them unchanged.

**Tech Stack:** GDScript, Godot 4.3, JSON data files. No external libraries. Testing is manual via the test launcher scene (F5 to run).

**Design doc:** `docs/plans/2026-03-01-companions-design.md`

---

## Task 1: companions.json — data file

**Files:**
- Create: `resources/data/companions.json`

**Step 1: Create the file with one example companion**

```json
{
  "companions": {
    "karnak": {
      "id": "karnak",
      "name": "Brother Karnak",
      "race": "red_devil",
      "background": "soldier",
      "flavor_text": "A red devil cast out of the Infernal Guard for showing mercy to a damned soul. He carries the contradiction quietly.",
      "portrait": "",
      "recruitment_cost": 150,
      "build_weights": {
        "strength": 3,
        "constitution": 2,
        "finesse": 1,
        "awareness": 1,
        "martial_arts": 5,
        "unarmed": 3,
        "yoga": 2,
        "fire_magic": 1
      },
      "fixed_starter": {
        "skills": { "martial_arts": 2 },
        "known_spells": []
      },
      "fixed_spells": [],
      "random_spells": { "count": 1 },
      "fixed_equipment": {},
      "starting_equipment": {
        "weapon_set_1": { "main": "sword", "off": "" },
        "chest": "light_armor"
      },
      "fixed_items": ["health_potion"]
    }
  }
}
```

**Step 2: Verify it parses**

Open Godot → bottom panel Output. No errors on launch after adding the autoload in Task 2.

---

## Task 2: CompanionSystem autoload — scaffold

**Files:**
- Create: `scripts/autoload/companion_system.gd`
- Modify: `project.godot` (add autoload entry)

**Step 1: Create the file with data loading only**

```gdscript
extends Node
## CompanionSystem — Loads companion definitions and handles recruitment.

signal companion_recruited(companion: Dictionary)
signal companion_overflow(companion: Dictionary)  # All build_weights maxed

var _companion_data: Dictionary = {}

func _ready() -> void:
	_load_companion_data()
	print("CompanionSystem: loaded ", _companion_data.size(), " companions")


func _load_companion_data() -> void:
	var path = "res://resources/data/companions.json"
	if not FileAccess.file_exists(path):
		push_warning("CompanionSystem: companions.json not found")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("CompanionSystem: Failed to parse companions.json: ", json.get_error_message())
		file.close()
		return
	file.close()
	_companion_data = json.get_data().get("companions", {})


## Returns the raw definition dict for a companion id, or {} if not found.
func get_definition(companion_id: String) -> Dictionary:
	return _companion_data.get(companion_id, {})


## Returns all companion definitions.
func get_all_definitions() -> Dictionary:
	return _companion_data
```

**Step 2: Register in project.godot**

Open `project.godot`, find the `[autoload]` section, add after `ItemSystem`:
```
CompanionSystem="*res://scripts/autoload/companion_system.gd"
```

The full autoload order must be:
```
GameState → PerkSystem → CharacterSystem → ItemSystem → CompanionSystem → EnemySystem → ...
```

**Step 3: Verify**

Run the game (F5). Output should show:
```
CompanionSystem: loaded 1 companions
```

**Step 4: Commit**

```bash
git add resources/data/companions.json scripts/autoload/companion_system.gd project.godot
git commit -m "feat: add CompanionSystem autoload and companions.json data file"
```

---

## Task 3: Core algorithms — calculate_spent_xp and auto_distribute

**Files:**
- Modify: `scripts/autoload/companion_system.gd`

These are the heart of the system. Add to `companion_system.gd`:

**Step 1: Add `_calculate_spent_xp`**

```gdscript
## Returns total XP already spent by a character on attributes and skills.
## Used to determine companion budget at recruitment.
func _calculate_spent_xp(character: Dictionary) -> int:
	var total := 0
	# Attribute costs: max((value - 9) * 3, 2) XP per step, from base 10
	for attr in character.get("attributes", {}).keys():
		var val: int = character.attributes[attr]
		for v in range(10, val):
			total += maxi(int((v - 9) * 3), 2)
		# Below 10 costs 2 XP per step downward (rarely used but handle it)
		for v in range(val, 10):
			total += 2
	# Skill costs: SKILL_COSTS[level_to_reach], index 1-10
	for skill in character.get("skills", {}).keys():
		var level: int = character.skills[skill]
		for l in range(1, level + 1):
			if l < CharacterSystem.SKILL_COSTS.size():
				total += CharacterSystem.SKILL_COSTS[l]
	return total
```

**Step 2: Add `_spend_on_attribute` and `_spend_on_skill` helpers**

```gdscript
const ATTR_NAMES := ["strength", "finesse", "constitution", "focus", "awareness", "charm", "luck"]
const ATTR_HARD_CAP := 30  # Practical max; beyond this cost is extreme

## Try to spend up to `budget` XP on one attribute. Returns XP actually spent.
func _spend_on_attribute(character: Dictionary, attr: String, budget: int) -> int:
	var spent := 0
	while spent < budget:
		var current: int = character.attributes.get(attr, 10)
		if current >= ATTR_HARD_CAP:
			break
		var cost := maxi(int((current - 9) * 3), 2)
		if spent + cost > budget:
			break
		character.attributes[attr] = current + 1
		spent += cost
	return spent


## Try to spend up to `budget` XP on one skill. Returns XP actually spent.
func _spend_on_skill(character: Dictionary, skill: String, budget: int) -> int:
	var spent := 0
	while spent < budget:
		var current: int = character.get("skills", {}).get(skill, 0)
		var next_level := current + 1
		if next_level > CharacterSystem.SKILL_MAX_LEVEL:
			break
		var cost: int = CharacterSystem.SKILL_COSTS[next_level]
		if spent + cost > budget:
			break
		character.skills[skill] = next_level
		spent += cost
	return spent
```

**Step 3: Add `_auto_distribute`**

```gdscript
## Distribute `budget` XP among stats according to weights.
## Weights are any positive numbers — they are normalised internally.
## Capped stats have their surplus redistributed to remaining uncapped stats.
func _auto_distribute(character: Dictionary, budget: int, weights: Dictionary) -> void:
	if weights.is_empty() or budget <= 0:
		return

	# Work on a mutable copy of weights
	var active: Dictionary = {}
	for key in weights:
		if weights[key] > 0:
			active[key] = float(weights[key])

	var remaining := budget
	var max_passes := 30  # Safety valve against infinite loop

	for _pass in range(max_passes):
		if remaining <= 0 or active.is_empty():
			break

		# Sum active weights
		var total_w := 0.0
		for w in active.values():
			total_w += w

		var spent_this_pass := 0
		var capped: Array[String] = []

		for key in active.keys():
			var alloc := int(float(remaining) * active[key] / total_w)
			if alloc <= 0:
				continue
			var actually_spent := 0
			if key in ATTR_NAMES:
				actually_spent = _spend_on_attribute(character, key, alloc)
			else:
				actually_spent = _spend_on_skill(character, key, alloc)
			spent_this_pass += actually_spent
			# If we spent less than allocated, this stat hit its cap
			if actually_spent < alloc:
				capped.append(key)

		for key in capped:
			active.erase(key)

		remaining -= spent_this_pass

		# If nothing was spent this pass but budget remains, everything is capped
		if spent_this_pass == 0:
			break
```

**Step 4: Verify logic manually**

Add a temporary test call in `_ready()`:
```gdscript
# TEMP TEST — remove after verification
var test_char = CharacterSystem.BASE_CHARACTER.duplicate(true)
test_char.attributes = test_char.attributes.duplicate()
test_char.skills = {}
var test_weights = {"strength": 3, "constitution": 2, "martial_arts": 5}
_auto_distribute(test_char, 300, test_weights)
print("TEST auto_distribute: STR=", test_char.attributes.strength,
	" CON=", test_char.attributes.constitution,
	" martial_arts=", test_char.skills.get("martial_arts", 0))
```

Run game. Expected output: martial_arts should be ~5-6 (gets ~62% of 300 = 188 XP = level 6 costs 162 XP), STR should be 14-15.

Remove the temp test code.

**Step 5: Commit**

```bash
git add scripts/autoload/companion_system.gd
git commit -m "feat: add companion XP distribution algorithm (calculate_spent_xp, auto_distribute)"
```

---

## Task 4: Recruitment function — recruit()

**Files:**
- Modify: `scripts/autoload/companion_system.gd`

**Step 1: Add `_power_to_rarity` helper**

```gdscript
## Maps party power level (spent XP of player) to an equipment rarity string.
func _power_to_rarity(power: int) -> String:
	if power < 100: return "common"
	if power < 300: return "uncommon"
	if power < 600: return "rare"
	return "epic"
```

**Step 2: Add `_apply_fixed_starter`**

```gdscript
## Apply fixed_starter skills and spells to a fresh character dict.
func _apply_fixed_starter(character: Dictionary, starter: Dictionary) -> void:
	for skill in starter.get("skills", {}).keys():
		character.skills[skill] = starter.skills[skill]
	for spell_id in starter.get("known_spells", []):
		if not spell_id in character.known_spells:
			character.known_spells.append(spell_id)
```

**Step 3: Add `_apply_random_spells`**

```gdscript
## Pick random spells weighted by the companion's magic skill weights.
## Only picks spells the companion can actually cast (skill level met).
func _apply_random_spells(character: Dictionary, random_cfg: Dictionary,
		build_weights: Dictionary) -> void:
	var count: int = random_cfg.get("count", 0)
	if count <= 0:
		return

	# Map skill names to spell school names
	const SKILL_TO_SCHOOL := {
		"space_magic": "Space", "air_magic": "Air", "fire_magic": "Fire",
		"water_magic": "Water", "earth_magic": "Earth",
		"white_magic": "White", "black_magic": "Black",
		"sorcery": "Sorcery", "enchantment": "Enchantment",
		"summoning": "Summoning"
	}

	# Build weighted school pool from build_weights
	var school_pool: Array[String] = []
	for skill in build_weights.keys():
		if skill in SKILL_TO_SCHOOL:
			var school := SKILL_TO_SCHOOL[skill]
			var weight: int = int(build_weights[skill])
			for _i in range(weight):
				school_pool.append(school)

	if school_pool.is_empty():
		return  # No magic weights — no random spells

	# Load spells from CharacterSystem's database (it loads spells.json)
	var spell_db: Dictionary = CharacterSystem._spell_database
	var candidates: Array[String] = []

	for spell_id in spell_db.keys():
		var spell: Dictionary = spell_db[spell_id]
		# Must be already known or not yet known
		if spell_id in character.known_spells:
			continue
		# Check if any spell school is in our weighted pool
		var schools: Array = spell.get("schools", [])
		var school_match := false
		for s in schools:
			if s in school_pool:
				school_match = true
				break
		if not school_match:
			continue
		# Check castability: companion needs the skill at required level
		var required_level: int = spell.get("level", 1)
		var can_cast := false
		for s in schools:
			# Find corresponding skill
			for skill_name in SKILL_TO_SCHOOL.keys():
				if SKILL_TO_SCHOOL[skill_name] == s:
					if character.skills.get(skill_name, 0) >= required_level:
						can_cast = true
						break
		if can_cast:
			candidates.append(spell_id)

	# Pick `count` spells, weighted by school match count
	candidates.shuffle()
	var picked := 0
	for spell_id in candidates:
		if picked >= count:
			break
		character.known_spells.append(spell_id)
		picked += 1
```

**Step 4: Add `_apply_starting_equipment`**

```gdscript
## Apply fixed and procedurally-generated equipment to a companion.
func _apply_starting_equipment(character: Dictionary, fixed_equip: Dictionary,
		starting_equip: Dictionary, rarity: String) -> void:
	# Fixed equipment slots — applied as-is (specific item ids)
	for slot in fixed_equip.keys():
		var slot_data = fixed_equip[slot]
		if typeof(slot_data) == TYPE_DICTIONARY:
			# Weapon set format: {"main": id, "off": id}
			character.equipment[slot] = slot_data.duplicate()
		elif typeof(slot_data) == TYPE_STRING and slot_data != "":
			character.equipment[slot] = slot_data

	# Procedural equipment — generate at recruitment rarity
	const WEAPON_SLOTS := ["weapon_set_1", "weapon_set_2"]
	const ARMOR_SLOTS := ["head", "chest", "legs", "feet", "hand_l", "hand_r"]

	for slot in starting_equip.keys():
		# Skip if already filled by fixed_equipment
		if slot in fixed_equip and not fixed_equip[slot].is_empty():
			continue
		var type_data = starting_equip[slot]
		if slot in WEAPON_SLOTS:
			# Weapon set: {"main": "sword", "off": ""}
			var main_type: String = type_data.get("main", "")
			var off_type: String = type_data.get("off", "")
			var set_data := {"main": "", "off": ""}
			if main_type != "":
				set_data.main = ItemSystem.generate_weapon(main_type, rarity)
			if off_type != "":
				set_data.off = ItemSystem.generate_weapon(off_type, rarity)
			character.equipment[slot] = set_data
		elif slot in ARMOR_SLOTS:
			var armor_type: String = type_data if typeof(type_data) == TYPE_STRING else ""
			if armor_type != "":
				character.equipment[slot] = ItemSystem.generate_armor(armor_type, rarity)
```

**Step 5: Add the main `recruit()` function**

```gdscript
## Recruit a companion by id. Deducts gold, builds their character dict,
## adds them to the party, and emits companion_recruited signal.
## Returns the companion dict on success, or {} on failure.
func recruit(companion_id: String) -> Dictionary:
	var def: Dictionary = get_definition(companion_id)
	if def.is_empty():
		push_error("CompanionSystem: Unknown companion id: ", companion_id)
		return {}

	var cost: int = def.get("recruitment_cost", 0)
	if GameState.party_gold < cost:
		push_warning("CompanionSystem: Cannot afford companion ", companion_id)
		return {}

	# 1. Fresh character from BASE_CHARACTER
	var companion: Dictionary = CharacterSystem.BASE_CHARACTER.duplicate(true)
	companion.attributes = companion.attributes.duplicate()
	companion.derived = companion.derived.duplicate()
	companion.equipment = companion.equipment.duplicate(true)
	companion.skills = {}
	companion.known_spells = []
	companion.perks = []
	companion.upgrades = []
	companion.inventory = []

	# 2. Identity
	companion.name = def.get("name", "Companion")
	companion.race = def.get("race", "human")
	companion.background = def.get("background", "wanderer")

	# 3. Apply race and background modifiers (reuse CharacterSystem logic)
	CharacterSystem.apply_race(companion, companion.race)
	CharacterSystem.apply_background(companion, companion.background)

	# 4. Add companion-specific fields
	companion["companion_id"] = companion_id
	companion["flavor_text"] = def.get("flavor_text", "")
	companion["portrait"] = def.get("portrait", "")
	companion["build_weights"] = def.get("build_weights", {}).duplicate()
	companion["autodevelop"] = false
	companion["free_xp"] = 0
	companion["overflow_investments"] = {}

	# 5. Apply fixed_starter (skills/spells always present)
	_apply_fixed_starter(companion, def.get("fixed_starter", {}))

	# 6. Auto-distribute budget (player's spent XP)
	var player := CharacterSystem.get_player()
	var budget := _calculate_spent_xp(player)
	_auto_distribute(companion, budget, def.get("build_weights", {}))

	# 7. Fixed spells
	for spell_id in def.get("fixed_spells", []):
		if not spell_id in companion.known_spells:
			companion.known_spells.append(spell_id)

	# 8. Random spells (school-weighted)
	_apply_random_spells(companion, def.get("random_spells", {}), def.get("build_weights", {}))

	# 9. Equipment
	var rarity := _power_to_rarity(budget)
	_apply_starting_equipment(companion, def.get("fixed_equipment", {}),
		def.get("starting_equipment", {}), rarity)

	# 10. Fixed items
	for item_id in def.get("fixed_items", []):
		ItemSystem.add_to_character_inventory(companion, item_id)

	# 11. Recalculate derived stats
	CharacterSystem.update_derived_stats(companion)

	# 12. Deduct gold and add to party
	GameState.add_gold(-cost)
	CharacterSystem.add_companion(companion)

	companion_recruited.emit(companion)
	return companion
```

**Step 6: Check that `CharacterSystem.apply_race` and `apply_background` are public functions**

Grep for them:
```bash
grep -n "^func apply_race\|^func apply_background" scripts/autoload/character_system.gd
```

If they don't exist as standalone functions (they may be inlined in character creation), you'll need to extract them. Check `character_system.gd` around the `create_character` function and extract the race/background application logic into `apply_race(character, race_id)` and `apply_background(character, background_id)` functions.

**Step 7: Verify via print**

Temporarily add to overworld.gd or a test scene:
```gdscript
# TEMP: Test recruit Karnak
GameState.party_gold = 500
var karnak = CompanionSystem.recruit("karnak")
if karnak:
    print("Recruited: ", karnak.name, " | martial_arts=",
        karnak.skills.get("martial_arts", 0), " | STR=", karnak.attributes.strength)
    print("Equipment weapon: ", karnak.equipment.get("weapon_set_1", {}))
```

**Step 8: Commit**

```bash
git add scripts/autoload/companion_system.gd
git commit -m "feat: implement companion recruit() with auto-distribution, spells, and equipment"
```

---

## Task 5: Recruitment popup scene

**Files:**
- Create: `scenes/ui/companion_recruit_popup.tscn` + `scripts/ui/companion_recruit_popup.gd`

**Step 1: Create the script**

```gdscript
extends Control
## Companion recruitment popup — shows name, race/background, flavor text.
## Emits `confirmed` when the player clicks Continue.

signal confirmed

@onready var name_label: Label = %CompanionName
@onready var identity_label: Label = %IdentityLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var continue_btn: Button = %ContinueButton


func show_companion(companion: Dictionary) -> void:
	name_label.text = companion.get("name", "Companion")
	var race_display := companion.get("race", "").replace("_", " ").capitalize()
	var bg_display := companion.get("background", "").replace("_", " ").capitalize()
	identity_label.text = race_display + " · " + bg_display
	flavor_label.text = companion.get("flavor_text", "")
	show()


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	hide()


func _on_continue_pressed() -> void:
	hide()
	confirmed.emit()
```

**Step 2: Create the scene in Godot editor**

Layout (use the Godot scene editor):
```
CanvasLayer (z_index=30)
  └─ PanelContainer (anchored center, min_size 400x300)
       └─ MarginContainer (margins 24px)
            └─ VBoxContainer (separation 16)
                 ├─ Label (unique: CompanionName, h_align=CENTER, font_size=20, bold)
                 ├─ Label (unique: IdentityLabel, h_align=CENTER, modulate=grey)
                 ├─ HSeparator
                 ├─ Label (unique: FlavorLabel, h_align=CENTER, autowrap=WORD, custom_min_size y=80)
                 └─ Button (unique: ContinueButton, text="Continue", h_size_flags=SHRINK_CENTER)
```

Attach `companion_recruit_popup.gd` as the script on the root node.

**Step 3: Wire up recruitment popup to CompanionSystem**

In `scripts/autoload/companion_system.gd`, add:
```gdscript
const RECRUIT_POPUP_SCENE = preload("res://scenes/ui/companion_recruit_popup.tscn")

## Show the recruitment popup. Caller should connect to the `confirmed` signal.
func show_recruit_popup(companion: Dictionary) -> Control:
	var popup = RECRUIT_POPUP_SCENE.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show_companion(companion)
	return popup
```

Then modify `recruit()` — after emitting `companion_recruited`, call:
```gdscript
show_recruit_popup(companion)
```

**Step 4: Test**

Trigger recruitment (use the temp test code from Task 4). The popup should appear with Karnak's name and flavor text.

**Step 5: Commit**

```bash
git add scenes/ui/companion_recruit_popup.tscn scripts/ui/companion_recruit_popup.gd scripts/autoload/companion_system.gd
git commit -m "feat: add companion recruitment popup UI"
```

---

## Task 6: XP sharing — party multiplier and free_xp

**Files:**
- Modify: `scripts/autoload/character_system.gd` (grant_xp)
- Modify: `scripts/combat/combat_arena.gd` (_apply_rewards)
- Modify: `scripts/autoload/event_manager.gd` (grant xp in outcome)
- Modify: `scripts/autoload/map_manager.gd` (grant xp from pickup)
- Modify: `scripts/autoload/character_system.gd` (max_party_size)

**Step 1: Update `max_party_size` in CharacterSystem**

In `character_system.gd`, find:
```gdscript
var max_party_size: int = 6
```
Change to:
```gdscript
var max_party_size: int = 8
```

**Step 2: Add `get_xp_multiplier` to CompanionSystem**

```gdscript
## Returns XP multiplier based on current party size.
func get_xp_multiplier() -> float:
	var size := CharacterSystem.get_party().size()
	if size <= 1: return 1.5
	if size == 2: return 1.25
	if size <= 4: return 1.0
	if size <= 6: return 0.85
	return 0.7
```

**Step 3: Add `apply_party_xp` to CompanionSystem**

```gdscript
## Award XP to the entire party with the size multiplier applied.
## Also adds to free_xp for companions and triggers autodevelop.
func apply_party_xp(base_amount: int) -> void:
	var multiplier := get_xp_multiplier()
	var final_amount := maxi(1, int(float(base_amount) * multiplier))
	for member in CharacterSystem.get_party():
		CharacterSystem.grant_xp(member, final_amount)
		# Companions also receive free_xp (the player-spendable pool)
		if member.has("free_xp"):
			member.free_xp += final_amount
			if member.get("autodevelop", false):
				_try_autodevelop(member)
```

**Step 4: Update `combat_arena.gd:_apply_rewards`**

Find the function (around line 2130):
```gdscript
func _apply_rewards(rewards: Dictionary) -> void:
	var xp = rewards.get("xp", 0)
	var gold = rewards.get("gold", 0)

	# Grant full XP to ALL party members equally
	for member in CharacterSystem.get_party():
		CharacterSystem.grant_xp(member, xp)
```

Replace the XP loop with:
```gdscript
func _apply_rewards(rewards: Dictionary) -> void:
	var xp = rewards.get("xp", 0)
	var gold = rewards.get("gold", 0)

	# Grant XP to all party members with party-size scaling
	if xp > 0:
		CompanionSystem.apply_party_xp(xp)
```

**Step 5: Update `event_manager.gd` XP grant**

Find (around line 405):
```gdscript
if "xp" in rewards:
    var player = CharacterSystem.get_player()
    CharacterSystem.grant_xp(player, rewards.xp)
```

Replace with:
```gdscript
if "xp" in rewards:
    CompanionSystem.apply_party_xp(int(rewards.xp))
```

**Step 6: Update `map_manager.gd` XP grant**

Find (around line 1012):
```gdscript
CharacterSystem.grant_xp(character, int(value))
```

This grants to a single character (map pickup). Keep this as-is — it's a targeted pickup, not a shared reward. No change needed here.

**Step 7: Verify**

Start the game with Karnak recruited (temp recruit code). Trigger a combat. After winning, check that both the player and Karnak both show increased XP. With a 2-member party, each should get `base_xp * 1.25`.

**Step 8: Commit**

```bash
git add scripts/autoload/companion_system.gd scripts/combat/combat_arena.gd scripts/autoload/event_manager.gd scripts/autoload/character_system.gd
git commit -m "feat: party XP sharing with size multiplier, companion free_xp tracking"
```

---

## Task 7: Autodevelop — normal mode

**Files:**
- Modify: `scripts/autoload/companion_system.gd`

**Step 1: Add `_try_autodevelop`**

```gdscript
## Called when a companion with autodevelop=true gains free_xp.
## Spends free_xp according to build_weights (or overflow_investments if overflow mode).
func _try_autodevelop(companion: Dictionary) -> void:
	var weights: Dictionary = companion.get("build_weights", {})
	var overflow: Dictionary = companion.get("overflow_investments", {})

	# Determine which weight set to use
	var using_overflow := _is_overflow_mode(companion)

	if using_overflow:
		_autodevelop_overflow(companion)
	else:
		# Normal mode: spend free_xp using build_weights
		var to_spend := companion.free_xp
		if to_spend <= 0:
			return
		var before := to_spend
		_auto_distribute(companion, to_spend, weights)
		# Calculate how much was actually spent by comparing before/after derived would show,
		# but simplest: re-calculate what remains by checking current skill/attr costs
		# Actually _auto_distribute modifies the character in-place but doesn't track spend.
		# We need a version that returns spent amount. For now, spend all free_xp and let
		# _auto_distribute handle overflow capping naturally.
		companion.free_xp = 0
		CharacterSystem.update_derived_stats(companion)
		CharacterSystem.character_updated.emit(companion)
		# Check if we've now entered overflow mode
		if _is_overflow_mode(companion):
			companion_overflow.emit(companion)
```

**Step 2: Add `_is_overflow_mode`**

```gdscript
## Returns true if all build_weights have hit their caps.
func _is_overflow_mode(companion: Dictionary) -> bool:
	var weights: Dictionary = companion.get("build_weights", {})
	if weights.is_empty():
		return true
	for key in weights.keys():
		if key in ATTR_NAMES:
			if companion.attributes.get(key, 10) < ATTR_HARD_CAP:
				return false
		else:
			if companion.get("skills", {}).get(key, 0) < CharacterSystem.SKILL_MAX_LEVEL:
				return false
	return true
```

**Step 3: Verify**

Turn autodevelop on for Karnak via a temp call:
```gdscript
karnak.autodevelop = true
karnak.free_xp = 200
CompanionSystem._try_autodevelop(karnak)
print("After autodevelop: martial_arts=", karnak.skills.get("martial_arts", 0))
```

**Step 4: Commit**

```bash
git add scripts/autoload/companion_system.gd
git commit -m "feat: companion autodevelop normal mode"
```

---

## Task 8: Autodevelop — overflow mode

**Files:**
- Modify: `scripts/autoload/companion_system.gd`

**Step 1: Add `_autodevelop_overflow`**

```gdscript
## Overflow mode: all build_weights are maxed. Use overflow_investments for weights,
## or randomly seed if none exist.
func _autodevelop_overflow(companion: Dictionary) -> void:
	var overflow: Dictionary = companion.get("overflow_investments", {})

	# If no manual investments yet, pick one at random to seed
	if overflow.is_empty():
		var all_skills := CharacterSystem.BASE_CHARACTER.get("skills", {}).keys()
		# Build a list of improvable stats
		var improvable: Array[String] = []
		for attr in ATTR_NAMES:
			if companion.attributes.get(attr, 10) < ATTR_HARD_CAP:
				improvable.append(attr)
		for skill_id in all_skills:
			if companion.get("skills", {}).get(skill_id, 0) < CharacterSystem.SKILL_MAX_LEVEL:
				improvable.append(skill_id)
		if improvable.is_empty():
			return  # Truly maxed — nothing to do
		var seed_key: String = improvable[randi() % improvable.size()]
		companion.overflow_investments[seed_key] = 1

	# Build dynamic weights: invested stats get count+1, everything else gets 1
	var dynamic_weights: Dictionary = {}
	# Start with weight 1 for all attributes and skills (improvable ones)
	for attr in ATTR_NAMES:
		if companion.attributes.get(attr, 10) < ATTR_HARD_CAP:
			dynamic_weights[attr] = 1
	# All skills
	for skill_id in CharacterSystem.BASE_CHARACTER.get("skills", {}).keys():
		if companion.get("skills", {}).get(skill_id, 0) < CharacterSystem.SKILL_MAX_LEVEL:
			dynamic_weights[skill_id] = 1
	# Override with overflow_investments (count + 1)
	for key in overflow.keys():
		dynamic_weights[key] = overflow[key] + 1

	var to_spend := companion.free_xp
	if to_spend <= 0:
		return
	_auto_distribute(companion, to_spend, dynamic_weights)
	companion.free_xp = 0
	CharacterSystem.update_derived_stats(companion)
	CharacterSystem.character_updated.emit(companion)


## Call when the player manually invests XP in a companion stat during overflow mode.
## Updates overflow_investments to track the player's intent.
func record_overflow_investment(companion: Dictionary, stat_key: String) -> void:
	if not companion.has("overflow_investments"):
		return
	var overflow: Dictionary = companion.overflow_investments
	overflow[stat_key] = overflow.get(stat_key, 0) + 1
```

**Step 2: Connect overflow signal to show popup**

The overflow popup fires once. Track whether it's been shown with a flag on the companion:

In `_try_autodevelop`, after `companion_overflow.emit(companion)`, add:
```gdscript
companion["overflow_popup_shown"] = true
```

In `apply_party_xp` (where autodevelop is triggered), wrap the `_try_autodevelop` call to only fire the popup signal once:
```gdscript
if member.get("autodevelop", false):
    var was_overflow := _is_overflow_mode(member)
    _try_autodevelop(member)
    var now_overflow := _is_overflow_mode(member)
    if now_overflow and not was_overflow and not member.get("overflow_popup_shown", false):
        member["overflow_popup_shown"] = true
        companion_overflow.emit(member)
```

**Step 3: Wire overflow signal in overworld.gd**

In `overworld.gd` (or wherever CompanionSystem signals are connected), add:
```gdscript
CompanionSystem.companion_overflow.connect(_on_companion_overflow)

func _on_companion_overflow(companion: Dictionary) -> void:
    # Show a simple popup notification
    var popup_text = "%s has mastered their calling.\nYou can direct their growth, or let them find their own way." % companion.name
    # Use existing notification/toast system, or a simple AcceptDialog
    var dialog := AcceptDialog.new()
    dialog.dialog_text = popup_text
    dialog.title = "Mastery Achieved"
    add_child(dialog)
    dialog.popup_centered()
```

**Step 4: Commit**

```bash
git add scripts/autoload/companion_system.gd scenes/overworld/overworld.gd
git commit -m "feat: companion autodevelop overflow mode with random seed and popup"
```

---

## Task 9: Character selector panel — main_menu.gd

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scenes/ui/main_menu.tscn`

The character selector is a row of buttons at the top of the `TabContainer` (above the tabs themselves, not inside one tab). Clicking a button switches which character all tabs display.

**Step 1: Add state variable to main_menu.gd**

Near the top of `main_menu.gd`, add:
```gdscript
# Currently displayed character (player or companion)
var _current_character: Dictionary = {}
```

**Step 2: Add the selector panel to the scene**

In the Godot editor, open `scenes/ui/main_menu.tscn`. The root is a `Control` containing a `MarginContainer/VBoxContainer`. Find the `VBoxContainer` that wraps the `TabContainer`.

Add a new `HBoxContainer` node **above** the `TabContainer` in the `VBoxContainer`:
- Name it `CharacterSelectorPanel`
- Set `custom_minimum_size.y = 36`
- Mark it unique: `character_selector_panel`

The buttons will be added dynamically in code.

**Step 3: Add `@onready` and `_build_character_selector` to main_menu.gd**

```gdscript
@onready var character_selector_panel: HBoxContainer = %CharacterSelectorPanel

func _build_character_selector() -> void:
	# Clear existing buttons
	for child in character_selector_panel.get_children():
		child.queue_free()

	var party := CharacterSystem.get_party()
	for i in range(party.size()):
		var member := party[i]
		var btn := Button.new()
		btn.text = member.get("name", "Unknown")
		btn.toggle_mode = true
		btn.button_group = _get_or_create_selector_group()
		btn.pressed.connect(_on_character_selected.bind(member))
		# Tooltip shows flavor text for companions
		var flavor: String = member.get("flavor_text", "")
		if flavor != "":
			btn.tooltip_text = flavor
		character_selector_panel.add_child(btn)
		# Select the current character's button
		if member == _current_character:
			btn.set_pressed_no_signal(true)

var _selector_group: ButtonGroup = null
func _get_or_create_selector_group() -> ButtonGroup:
	if _selector_group == null:
		_selector_group = ButtonGroup.new()
	return _selector_group


func _on_character_selected(character: Dictionary) -> void:
	_current_character = character
	refresh_all_tabs()


## Refresh all tabs to show _current_character's data.
func refresh_all_tabs() -> void:
	_refresh_stats_tab()
	_refresh_equipment_tab()
	_refresh_spellbook_tab()
	# Party tab always shows the full party, no need to refresh
```

**Step 4: Initialize in `_ready()`**

In `_ready()`, after `_load_spell_database()`:
```gdscript
_current_character = CharacterSystem.get_player()
_build_character_selector()
```

Also connect to `CompanionSystem.companion_recruited` to rebuild the selector when a new companion joins:
```gdscript
CompanionSystem.companion_recruited.connect(_on_companion_recruited)

func _on_companion_recruited(_companion: Dictionary) -> void:
	_build_character_selector()
```

**Step 5: Update existing tab-populating functions to use `_current_character`**

Currently the Stats/Equipment/Spellbook tabs call `CharacterSystem.get_player()` to get the character. Find every such call in `main_menu.gd` (grep for `get_player`) and replace with `_current_character`.

```bash
grep -n "get_player()" scripts/ui/main_menu.gd
```

Replace each call in the tab-population functions with `_current_character`. Be careful not to replace calls in functions that specifically need the player (e.g. karma display).

**Step 6: Verify**

Recruit Karnak. The selector panel should show "Player Name | Karnak". Clicking Karnak should show his stats in the tabs.

**Step 7: Commit**

```bash
git add scripts/ui/main_menu.gd scenes/ui/main_menu.tscn
git commit -m "feat: character selector panel in main_menu tabs"
```

---

## Task 10: Stats tab — free_xp display, autodevelop toggle, debug +100 XP

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scenes/ui/main_menu.tscn`

**Step 1: Move and update the debug button**

In `main_menu.gd`, find `_on_add_xp_pressed`:
```gdscript
func _on_add_xp_pressed() -> void:
	var player = CharacterSystem.get_player()
	CharacterSystem.grant_xp(player, 10)
```

Change to award to `_current_character` and update amount to 100:
```gdscript
func _on_add_xp_pressed() -> void:
	if _current_character.is_empty():
		return
	CharacterSystem.grant_xp(_current_character, 100)
	if _current_character.has("free_xp"):
		_current_character.free_xp += 100
	_refresh_stats_tab()
```

In `scenes/ui/main_menu.tscn`, move the `AddXPButton` node to the bottom of the Stats tab content. Update its text to `"+100 XP [DEV]"`.

**Step 2: Add free_xp label to Stats tab (companions only)**

In `scenes/ui/main_menu.tscn`, in the Stats tab, add a `Label` node after the XP display:
- Name: `FreeXPRow` (HBoxContainer)
  - `Label` text: "Distributable XP:"
  - `Label` unique name: `FreeXPValue`

In `main_menu.gd`:
```gdscript
@onready var free_xp_row: HBoxContainer = %FreeXPRow
@onready var free_xp_value: Label = %FreeXPValue
```

In `_refresh_stats_tab()`, show/hide based on whether the current character is a companion:
```gdscript
var is_companion := _current_character.has("companion_id")
free_xp_row.visible = is_companion
if is_companion:
    free_xp_value.text = str(_current_character.get("free_xp", 0))
```

**Step 3: Add autodevelop toggle (companions only)**

In `scenes/ui/main_menu.tscn`, add a `CheckButton` to the Stats tab near the free_xp display:
- Unique name: `AutodevelopToggle`
- Text: "Autodevelop"

In `main_menu.gd`:
```gdscript
@onready var autodevelop_toggle: CheckButton = %AutodevelopToggle

# In _ready():
autodevelop_toggle.toggled.connect(_on_autodevelop_toggled)

func _on_autodevelop_toggled(enabled: bool) -> void:
    if _current_character.has("autodevelop"):
        _current_character.autodevelop = enabled

# In _refresh_stats_tab():
var is_companion := _current_character.has("companion_id")
autodevelop_toggle.visible = is_companion
if is_companion:
    autodevelop_toggle.set_pressed_no_signal(_current_character.get("autodevelop", false))
```

**Step 4: Wire up `record_overflow_investment` when player manually spends on companion**

Find where attribute/skill upgrade buttons call their upgrade functions. After spending XP on a companion stat, call:
```gdscript
if _current_character.has("overflow_investments") and CompanionSystem._is_overflow_mode(_current_character):
    CompanionSystem.record_overflow_investment(_current_character, stat_key)
```

(The stat_key is the attribute or skill id being upgraded.)

**Step 5: Commit**

```bash
git add scripts/ui/main_menu.gd scenes/ui/main_menu.tscn
git commit -m "feat: companion free_xp display, autodevelop toggle, debug +100 XP"
```

---

## Task 11: Save/load compatibility

**Files:**
- Modify: `scripts/autoload/save_manager.gd`

**Step 1: Check save format**

The party is saved as the full character dict array. Open `save_manager.gd` and find where the party is saved/loaded.

```bash
grep -n "party\|companion" scripts/autoload/save_manager.gd | head -30
```

**Step 2: Verify companion fields round-trip**

The companion extra fields (`companion_id`, `flavor_text`, `build_weights`, `autodevelop`, `free_xp`, `overflow_investments`, `overflow_popup_shown`) are just keys in the character dict. If SaveManager serializes the party as `JSON.stringify(CharacterSystem.party)`, these fields should survive the round-trip automatically.

If SaveManager only saves specific keys (it uses a whitelist), add the companion fields to that whitelist.

**Step 3: Test save/load with companion**

1. Recruit Karnak
2. Save the game
3. Quit and reload
4. Verify Karnak is still in the party with correct stats, `free_xp`, `autodevelop` state

**Step 4: Commit**

```bash
git add scripts/autoload/save_manager.gd
git commit -m "feat: ensure companion fields persist through save/load"
```

---

## Task 12: Expose recruitment in events and shop tab

**Files:**
- Modify: `scripts/autoload/event_manager.gd` (add `recruit_companion` outcome type)
- Modify: `scripts/ui/shop_ui.gd` or wherever shop tabs are built (add Companions tab)

### 12a: Event outcome — recruit_companion

**Step 1: Add handling in EventManager**

In `event_manager.gd`, find where outcome types are processed (look for `"type": "combat"` or `"shop"` handling). Add:

```gdscript
"recruit_companion":
    var companion_id: String = outcome.get("companion_id", "")
    if companion_id != "":
        CompanionSystem.recruit(companion_id)
```

**Step 2: Add a test event to hell_events.json**

Add a simple test event with a recruit outcome:
```json
"devil_deserter_test": {
    "id": "devil_deserter_test",
    "title": "A Familiar Face",
    "realm": "any",
    "text": "A red devil sits by the road, stripped of his armor. He looks up. 'I'm done with the Guard,' he says simply.",
    "choices": [
        {
            "text": "Take him in.",
            "type": "grey",
            "outcome": {
                "type": "recruit_companion",
                "companion_id": "karnak"
            }
        },
        {
            "text": "Leave him.",
            "type": "grey",
            "outcome": { "type": "text", "text": "You walk on." }
        }
    ]
}
```

**Step 3: Test the event**

Trigger it from the test launcher or via the map. Karnak should join and the popup should appear.

### 12b: Shop recruitment tab (basic)

This is a stub — full shop-tab UI can be fleshed out when you have more companions authored.

In shop_ui.gd (or wherever the shop tabs are built), when a shop has `available_companions` in its definition, add a "Companions" tab listing them with name + cost + recruit button. The recruit button calls `CompanionSystem.recruit(id)`.

This can be deferred until you have a tavern-type shop in shops.json. File a TODO in shops.json for now:
```json
"// TODO": "Add 'available_companions' array to tavern/camp shops for companion recruitment tab"
```

**Step 4: Commit**

```bash
git add scripts/autoload/event_manager.gd resources/data/hell_events.json
git commit -m "feat: recruit_companion event outcome type, test event for Karnak"
```

---

## Task 13: Extract apply_race / apply_background if needed

This task only applies if Task 4 Step 6 found these functions don't exist as standalone callables.

**Files:**
- Modify: `scripts/autoload/character_system.gd`

**Step 1: Find the race/background application code**

```bash
grep -n "func create_character\|race_data\|attribute_modifiers\|starting_skills" scripts/autoload/character_system.gd | head -20
```

**Step 2: Extract into public functions**

If race application is inlined in `create_character`, extract it:

```gdscript
## Apply race modifiers to a character dict.
func apply_race(character: Dictionary, race_id: String) -> void:
    var race_def: Dictionary = _race_data.get(race_id, {})
    if race_def.is_empty():
        return
    for attr in race_def.get("attribute_modifiers", {}).keys():
        character.attributes[attr] = character.attributes.get(attr, 10) + int(race_def.attribute_modifiers[attr])
    for skill in race_def.get("starting_skills", {}).keys():
        character.skills[skill] = maxi(character.skills.get(skill, 0), int(race_def.starting_skills[skill]))
    for spell_id in race_def.get("starting_spells", []):
        if not spell_id in character.known_spells:
            character.known_spells.append(spell_id)
    character["racial_affinity_bonuses"] = race_def.get("elemental_affinity_bonuses", {}).duplicate()


## Apply background modifiers to a character dict.
func apply_background(character: Dictionary, background_id: String) -> void:
    var bg_def: Dictionary = _background_data.get(background_id, {})
    if bg_def.is_empty():
        return
    for attr in bg_def.get("attribute_modifiers", {}).keys():
        character.attributes[attr] = character.attributes.get(attr, 10) + int(bg_def.attribute_modifiers[attr])
    for skill in bg_def.get("starting_skills", {}).keys():
        var bg_level: int = int(bg_def.starting_skills[skill])
        character.skills[skill] = maxi(character.skills.get(skill, 0), bg_level)
    for spell_id in bg_def.get("starting_spells", []):
        if not spell_id in character.known_spells:
            character.known_spells.append(spell_id)
```

Update `create_character` to call these functions instead of the inlined code.

**Step 3: Commit**

```bash
git add scripts/autoload/character_system.gd
git commit -m "refactor: extract apply_race and apply_background as public CharacterSystem functions"
```

---

## Final verification checklist

Run the game and check each of these:

- [ ] `companions.json` loads with no errors on startup
- [ ] Recruiting Karnak via the test event: popup shows name/race/flavor, he appears in party
- [ ] Character selector panel shows player + Karnak; clicking Karnak switches all tabs to his stats
- [ ] Karnak's stats reflect his build_weights (martial_arts should be his highest skill)
- [ ] Hover over Karnak's selector button shows flavor text tooltip
- [ ] Free XP display and Autodevelop toggle appear on Karnak's Stats tab, not on player's
- [ ] Enabling Autodevelop and gaining XP (fight a combat) causes Karnak's skills to rise
- [ ] Debug button awards +100 XP to the currently viewed character
- [ ] Save → reload preserves Karnak with correct autodevelop state and free_xp
- [ ] Party XP multiplier: solo = 1.5×, duo = 1.25×, 4-person = 1.0× (verify in combat log or with print)
- [ ] `max_party_size` is 8 (check CharacterSystem)
