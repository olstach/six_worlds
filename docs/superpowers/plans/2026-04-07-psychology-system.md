# Psychology System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Layer 1 of the psychology system — five elemental pressure meters per character that accumulate from events and combat outcomes, cross thresholds to produce status effects, and at high intensity trigger autonomous events in both the klesha (dark) and wisdom (bright) directions.

**Architecture:** A new `PsychologySystem` autoload owns all pressure logic. It exposes a simple `apply_pressure(character, element, amount)` API that the event system and combat system call. Threshold checking happens inside `apply_pressure` so callers never need to think about it. Autonomous events are emitted as a signal for the overworld/arena to handle.

**Tech Stack:** GDScript 4, Godot 4.3. No external dependencies. Testing via Godot's built-in output panel and cheat console.

---

## File Map

| File | Change |
|------|--------|
| `scripts/autoload/psychology_system.gd` | **Create** — owns all pressure logic |
| `project.godot` | **Modify** — register PsychologySystem autoload after KarmaSystem |
| `scripts/autoload/character_system.gd` | **Modify** — add `emotional_pressure` + `emotional_baseline` to BASE_CHARACTER |
| `resources/data/races.json` | **Modify** — add `emotional_baseline` field to each race |
| `scripts/autoload/event_manager.gd` | **Modify** — read `rewards.pressure` in `apply_outcome()` |
| `scripts/autoload/combat_manager.gd` | **Modify** — add pressure hooks in `end_combat()` and `_confirm_unit_death()` |
| `scripts/ui/main_menu.gd` | **Modify** — show dominant emotional label on character panel |
| `resources/data/events/hell_events.json` | **Modify** — add `pressure` fields to 3 example outcomes |

---

## Task 1: Create PsychologySystem skeleton and register it

**Files:**
- Create: `scripts/autoload/psychology_system.gd`
- Modify: `project.godot`

- [ ] **Step 1: Create the autoload file**

```gdscript
# scripts/autoload/psychology_system.gd
extends Node
## PsychologySystem — manages five elemental pressure meters per character.
##
## Each character has emotional_pressure: {space, fire, water, earth, air}
## ranging from -100 (deep klesha) to +100 (deep wisdom).
##
## Callers use apply_pressure(character, element, amount).
## Everything else (threshold checks, autonomous events) happens internally.

## Emitted when a character crosses the ±75 threshold.
## polarity is "dark" or "bright". element is one of the five elements.
## The overworld/arena should display a log message or mini-event in response.
signal autonomous_event_triggered(character: Dictionary, element: String, polarity: String)

## All five elements in order
const ELEMENTS: Array[String] = ["space", "fire", "water", "earth", "air"]

## Threshold levels
const THRESHOLD_MINOR: float    = 33.0
const THRESHOLD_MAJOR: float    = 50.0
const THRESHOLD_CRISIS: float   = 75.0

## How much pressure the crisis event bleeds off (partial valve)
const CRISIS_VALVE: float = 20.0

func _ready() -> void:
    print("PsychologySystem initialized")
```

- [ ] **Step 2: Register in project.godot**

Open `project.godot`. Find the `[autoload]` section. The current order ends with:
```
KarmaSystem="*res://scripts/autoload/karma_system.gd"
EventManager="*res://scripts/autoload/event_manager.gd"
```

Insert PsychologySystem between them:
```
KarmaSystem="*res://scripts/autoload/karma_system.gd"
PsychologySystem="*res://scripts/autoload/psychology_system.gd"
EventManager="*res://scripts/autoload/event_manager.gd"
```

- [ ] **Step 3: Verify it loads**

Launch the Godot project. Check the Output panel. You should see:
```
PsychologySystem initialized
```
before `EventManager initialized`.

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/psychology_system.gd project.godot
git commit -m "feat: add PsychologySystem autoload skeleton"
```

---

## Task 2: Add emotional data to character dict

**Files:**
- Modify: `scripts/autoload/character_system.gd` (around line 42, BASE_CHARACTER)
- Modify: `resources/data/races.json`

- [ ] **Step 1: Add fields to BASE_CHARACTER**

In `character_system.gd`, find `const BASE_CHARACTER: Dictionary = {` (line 42). After the `"elements"` block (around line 105), add:

```gdscript
    # Elemental emotional pressure: -100 (deep klesha) to +100 (deep wisdom)
    "emotional_pressure": {
        "space": 0.0,
        "fire":  0.0,
        "water": 0.0,
        "earth": 0.0,
        "air":   0.0,
    },

    # Starting emotional baseline per element — copied from race data at creation.
    # PsychologySystem reads this as the resting point pressure drifts toward.
    # Future: yidam practice and karma will modify this at runtime.
    "emotional_baseline": {
        "space": 0.0,
        "fire":  0.0,
        "water": 0.0,
        "earth": 0.0,
        "air":   0.0,
    },
```

- [ ] **Step 2: Propagate baseline from race data at character creation**

In `character_system.gd`, find `func _apply_race_modifiers(character: Dictionary) -> void` (search for `_apply_race_modifiers`). At the end of that function, add:

```gdscript
    # Copy emotional baseline from race data
    if "emotional_baseline" in race_data:
        for element in race_data.emotional_baseline:
            if element in character.emotional_baseline:
                character.emotional_baseline[element] = float(race_data.emotional_baseline[element])
```

- [ ] **Step 3: Add emotional_baseline to races.json**

Open `resources/data/races.json`. For each race, add an `"emotional_baseline"` field. These are small nudges, not dramatic starting states. Examples:

```json
"human": {
    "emotional_baseline": {"space": 5, "fire": 0, "water": 0, "earth": 0, "air": 0}
},
"red_devil": {
    "emotional_baseline": {"space": 0, "fire": 15, "water": 10, "earth": 0, "air": 0}
},
"hungry_ghost": {
    "emotional_baseline": {"space": -5, "fire": 20, "water": 0, "earth": -5, "air": 0}
},
"cold_hell_being": {
    "emotional_baseline": {"space": -10, "fire": -5, "water": 15, "earth": 0, "air": 0}
},
"fire_hell_being": {
    "emotional_baseline": {"space": -5, "fire": -10, "water": 15, "earth": 0, "air": 0}
}
```

Add `"emotional_baseline": {"space": 0, "fire": 0, "water": 0, "earth": 0, "air": 0}` to any race not listed above (safe neutral default).

- [ ] **Step 4: Verify**

Launch the game. In the cheat console, type:
```
print(CharacterSystem.get_player().emotional_pressure)
print(CharacterSystem.get_player().emotional_baseline)
```
Both should print dicts with the five elements. Baseline should reflect the player's race.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/character_system.gd resources/data/races.json
git commit -m "feat: add emotional_pressure and emotional_baseline to character data"
```

---

## Task 3: Implement core pressure logic

**Files:**
- Modify: `scripts/autoload/psychology_system.gd`

- [ ] **Step 1: Add the intensity multiplier helper**

In `psychology_system.gd`, add after `_ready()`:

```gdscript
## Returns how strongly this character reacts to triggers of the given element.
## Sourced from elemental affinity. Affinity 10 → 1.0×, affinity 40 → ~2.4×.
## This is an approximation — tune as needed during playtesting.
func _intensity_multiplier(character: Dictionary, element: String) -> float:
    var affinity: float = 10.0
    if "elements" in character and element in character.elements:
        affinity = max(1.0, float(character.elements[element]))
    return 1.0 + log(affinity / 10.0)
```

- [ ] **Step 2: Add apply_pressure — the main public entry point**

```gdscript
## Apply emotional pressure to a character for the given element.
## amount is positive (toward wisdom) or negative (toward klesha).
## Intensity is multiplied by the character's elemental affinity.
func apply_pressure(character: Dictionary, element: String, amount: float) -> void:
    if not "emotional_pressure" in character:
        return
    if not element in character.emotional_pressure:
        return

    var scaled: float = amount * _intensity_multiplier(character, element)
    character.emotional_pressure[element] = clamp(
        character.emotional_pressure[element] + scaled,
        -100.0, 100.0
    )
    _check_thresholds(character, element)
```

- [ ] **Step 3: Add get_active_statuses**

```gdscript
## Returns all active emotional statuses for a character.
## Each entry: {element, level ("minor"/"major"), polarity ("dark"/"bright"), label}
func get_active_statuses(character: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not "emotional_pressure" in character:
        return result
    for element in ELEMENTS:
        var pressure: float = character.emotional_pressure.get(element, 0.0)
        var abs_p: float = abs(pressure)
        var polarity: String = "bright" if pressure >= 0 else "dark"
        if abs_p >= THRESHOLD_MAJOR:
            result.append({
                "element": element,
                "level": "major",
                "polarity": polarity,
                "label": get_emotional_label(character, element)
            })
        elif abs_p >= THRESHOLD_MINOR:
            result.append({
                "element": element,
                "level": "minor",
                "polarity": polarity,
                "label": get_emotional_label(character, element)
            })
    return result
```

- [ ] **Step 4: Add get_emotional_label**

```gdscript
## Returns the display name for the character's current emotional state in this element.
## Returns "" if pressure is in the neutral zone (below ±33).
func get_emotional_label(character: Dictionary, element: String) -> String:
    if not "emotional_pressure" in character:
        return ""
    var pressure: float = character.emotional_pressure.get(element, 0.0)
    var abs_p: float = abs(pressure)
    if abs_p < THRESHOLD_MINOR:
        return ""
    var dark: bool = pressure < 0

    # crisis label (abs >= 75 — but only shown if still in crisis, event already fired)
    if abs_p >= THRESHOLD_CRISIS:
        match element:
            "space": return "Absent" if dark else "Luminous"
            "fire":  return "Consumed" if dark else "Radiant"
            "water": return "Poisonous" if dark else "Compassionate"
            "earth": return "Humiliated" if dark else "Unshakeable"
            "air":   return "Envious" if dark else "Brilliant"
    # major label (abs >= 50)
    if abs_p >= THRESHOLD_MAJOR:
        match element:
            "space": return "Dissociated" if dark else "Open"
            "fire":  return "Craving" if dark else "Magnetizing"
            "water": return "Grief-struck" if dark else "Clear-eyed"
            "earth": return "Arrogant" if dark else "Equanimous"
            "air":   return "Paranoid" if dark else "Inspired"
    # minor label (abs >= 33)
    match element:
        "space": return "Confused" if dark else "Clear-headed"
        "fire":  return "Restless" if dark else "Warm"
        "water": return "Irritable" if dark else "Focused"
        "earth": return "Insecure" if dark else "Grounded"
        "air":   return "Anxious" if dark else "Alert"
    return ""
```

- [ ] **Step 5: Verify via cheat console**

Launch the game. In cheat console:
```gdscript
var p = CharacterSystem.get_player()
PsychologySystem.apply_pressure(p, "fire", -40.0)
print(p.emotional_pressure)
print(PsychologySystem.get_emotional_label(p, "fire"))
print(PsychologySystem.get_active_statuses(p))
```
Expected: fire pressure ≈ −40 (scaled by intensity), label "Craving" or "Restless", statuses array with one fire/dark entry.

- [ ] **Step 6: Commit**

```bash
git add scripts/autoload/psychology_system.gd
git commit -m "feat: implement core pressure logic (apply_pressure, labels, statuses)"
```

---

## Task 4: Threshold checking and autonomous events

**Files:**
- Modify: `scripts/autoload/psychology_system.gd`

- [ ] **Step 1: Add threshold crossing tracker to character data**

Autonomous events fire only *once* per crossing — we need to remember which have fired. Add to `apply_pressure()`, just before the `_check_thresholds` call:

```gdscript
    # Ensure crossing tracker exists
    if not "emotional_crisis_fired" in character:
        character["emotional_crisis_fired"] = {}
```

- [ ] **Step 2: Implement _check_thresholds**

```gdscript
## Called after every apply_pressure. Detects threshold crossings and fires effects.
func _check_thresholds(character: Dictionary, element: String) -> void:
    var pressure: float = character.emotional_pressure[element]
    var abs_p: float = abs(pressure)
    var polarity: String = "bright" if pressure >= 0 else "dark"
    var crisis_key: String = element + "_" + polarity

    if abs_p >= THRESHOLD_CRISIS:
        # Fire autonomous event once per crossing
        if not character.emotional_crisis_fired.get(crisis_key, false):
            character.emotional_crisis_fired[crisis_key] = true
            # Partial valve: discharge reduces pressure by CRISIS_VALVE toward neutral
            var valve_direction: float = -1.0 if pressure > 0 else 1.0
            character.emotional_pressure[element] = clamp(
                pressure + (CRISIS_VALVE * valve_direction),
                -100.0, 100.0
            )
            print("PsychologySystem: %s — %s crisis (%s)" % [
                character.get("name", "?"), element, polarity
            ])
            autonomous_event_triggered.emit(character, element, polarity)
    else:
        # Pressure dropped back below crisis — reset so next crossing fires again
        character.emotional_crisis_fired.erase(crisis_key)
```

- [ ] **Step 3: Verify the valve and signal**

In cheat console:
```gdscript
var p = CharacterSystem.get_player()
# Connect signal temporarily so we can see it fire
PsychologySystem.autonomous_event_triggered.connect(func(c, e, pol):
    print("EVENT FIRED: %s %s %s" % [c.name, e, pol]))
# Push fire hard into crisis
p.emotional_pressure["fire"] = -70.0
PsychologySystem.apply_pressure(p, "fire", -10.0)
```
Expected output:
```
PsychologySystem: [name] — fire crisis (dark)
EVENT FIRED: [name] fire dark
```
Then check `p.emotional_pressure["fire"]` — should be around −60 (−80 + 20 valve), not −80.

Apply another −10. Should NOT emit the signal again (crisis_fired is set). Check.

Then apply +30. Pressure rises above −75. Apply −10 again — signal should fire again (reset cleared it).

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/psychology_system.gd
git commit -m "feat: threshold checking and autonomous event signal with partial valve"
```

---

## Task 5: Baseline and decay

**Files:**
- Modify: `scripts/autoload/psychology_system.gd`

- [ ] **Step 1: Add decay_toward_baseline**

```gdscript
## Drift all elemental pressures toward the character's emotional baseline.
## Call this on rest (camp, inn, etc.). decay_amount is how far each element moves.
func decay_toward_baseline(character: Dictionary, decay_amount: float = 10.0) -> void:
    if not "emotional_pressure" in character or not "emotional_baseline" in character:
        return
    for element in ELEMENTS:
        var current: float = character.emotional_pressure.get(element, 0.0)
        var baseline: float = character.emotional_baseline.get(element, 0.0)
        if abs(current - baseline) <= decay_amount:
            character.emotional_pressure[element] = baseline
        elif current > baseline:
            character.emotional_pressure[element] = current - decay_amount
        else:
            character.emotional_pressure[element] = current + decay_amount
        _check_thresholds(character, element)
```

- [ ] **Step 2: Verify decay**

In cheat console:
```gdscript
var p = CharacterSystem.get_player()
p.emotional_pressure["fire"] = -60.0
p.emotional_baseline["fire"] = 0.0
PsychologySystem.decay_toward_baseline(p, 10.0)
print(p.emotional_pressure["fire"])  # expect -50.0
PsychologySystem.decay_toward_baseline(p, 10.0)
print(p.emotional_pressure["fire"])  # expect -40.0
```

Now set baseline to 20 and pressure to 18:
```gdscript
p.emotional_baseline["fire"] = 20.0
p.emotional_pressure["fire"] = 18.0
PsychologySystem.decay_toward_baseline(p, 10.0)
print(p.emotional_pressure["fire"])  # expect 20.0 (snaps to baseline, within range)
```

- [ ] **Step 3: Commit**

```bash
git add scripts/autoload/psychology_system.gd
git commit -m "feat: pressure decay toward baseline (for rest system)"
```

---

## Task 6: Wire event outcomes

**Files:**
- Modify: `scripts/autoload/event_manager.gd` (function `apply_outcome`, around line 431)

- [ ] **Step 1: Add pressure handler to apply_outcome**

In `event_manager.gd`, find `func apply_outcome(outcome: Dictionary) -> void` (line 431). Inside the `if "rewards" in outcome:` block, after all the existing reward handlers (after skill_up, recruit_companion, etc.), add:

```gdscript
        # Emotional pressure — e.g. [{"element": "water", "amount": -20}, ...]
        # Applied to all party members. Each entry shifts one element.
        if "pressure" in rewards:
            var pressure_list = rewards.pressure
            if pressure_list is Dictionary:
                pressure_list = [pressure_list]  # allow single dict or array
            for party_member in CharacterSystem.get_party():
                for entry in pressure_list:
                    var element: String = str(entry.get("element", ""))
                    var amount: float = float(entry.get("amount", 0.0))
                    if element in PsychologySystem.ELEMENTS and amount != 0.0:
                        PsychologySystem.apply_pressure(party_member, element, amount)
```

- [ ] **Step 2: Add pressure fields to 3 hell events as examples**

Open `resources/data/events/hell_events.json`. Find three outcomes that clearly have emotional weight. Add `"pressure"` to their rewards. Examples:

Find a tragic/violent outcome (cold hell witnessing suffering):
```json
"rewards": {
    "pressure": [
        {"element": "water", "amount": -20},
        {"element": "space", "amount": -8}
    ]
}
```

Find a victory/escape outcome:
```json
"rewards": {
    "pressure": [
        {"element": "fire", "amount": 12},
        {"element": "air", "amount": 10}
    ]
}
```

Find a morally ambiguous choice (doing something cruel or surviving at another's expense):
```json
"rewards": {
    "pressure": [
        {"element": "water", "amount": -15},
        {"element": "earth", "amount": -8}
    ]
}
```

- [ ] **Step 3: Verify**

Launch game, trigger one of the tagged events. After the outcome resolves, check in cheat console:
```gdscript
print(CharacterSystem.get_player().emotional_pressure)
```
Pressure values should have shifted for the tagged elements.

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/event_manager.gd resources/data/events/hell_events.json
git commit -m "feat: wire pressure field in event outcomes, add 3 example hell events"
```

---

## Task 7: Wire combat hooks

**Files:**
- Modify: `scripts/autoload/combat_manager.gd`

- [ ] **Step 1: Add post-combat pressure in end_combat()**

In `combat_manager.gd`, find `func end_combat(victory: bool) -> void` (line 371). After `_sync_combat_state_to_characters()` but before `combat_active = false`, add:

```gdscript
    # Apply post-combat emotional pressure to all player characters
    _apply_post_combat_pressure(victory)
```

Then add the helper function (can go anywhere in the file near end_combat):

```gdscript
## Apply emotional pressure to party based on combat outcome.
func _apply_post_combat_pressure(victory: bool) -> void:
    var party = CharacterSystem.get_party()
    if victory:
        for member in party:
            PsychologySystem.apply_pressure(member, "fire", 10.0)
            PsychologySystem.apply_pressure(member, "air", 10.0)
    else:
        # Fleeing or defeat
        for member in party:
            PsychologySystem.apply_pressure(member, "earth", -10.0)
            PsychologySystem.apply_pressure(member, "space", -5.0)
```

- [ ] **Step 2: Add pressure on unit death**

In `combat_manager.gd`, find `unit_died.emit(unit)` (around line 2055, inside `_confirm_unit_death` or nearby). Just before that line, add:

```gdscript
    # Witnessing a party member die affects all other player units emotionally
    if unit.team == Team.PLAYER:
        for other_unit in all_units:
            if other_unit == unit or other_unit.team != Team.PLAYER:
                continue
            if "character_data" in other_unit:
                PsychologySystem.apply_pressure(other_unit.character_data, "water", -15.0)
```

- [ ] **Step 3: Verify**

Launch game, run a combat. Win it, then check in cheat console:
```gdscript
print(CharacterSystem.get_player().emotional_pressure)
```
Fire and Air should be slightly positive. Run a combat you lose (or use cheat to set HP to 1) — Earth and Space should be negative after retreat.

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/combat_manager.gd
git commit -m "feat: wire combat outcome and unit death emotional pressure hooks"
```

---

## Task 8: Show emotional state in character sheet UI

**Files:**
- Modify: `scripts/ui/main_menu.gd`

- [ ] **Step 1: Find where character names are displayed**

In `main_menu.gd`, search for where character name labels are set (grep for `character_name` or `char_name` or `name_label`). Identify the function that populates the character panel — likely called `_update_character_display()` or similar.

- [ ] **Step 2: Add emotional label display**

In the function that sets a character's name, after the name label is set, find or add a label for the emotional state. Add something like this (adapt node paths to match actual scene structure):

```gdscript
# Show dominant emotional state — the highest-pressure element above threshold
var statuses = PsychologySystem.get_active_statuses(character)
var emotion_label_node = $CharacterPanel/EmotionLabel  # adjust path as needed
if not statuses.is_empty():
    # Show the most intense status (major before minor, dark before bright)
    var dominant = statuses[0]
    for s in statuses:
        if s.level == "major" and dominant.level == "minor":
            dominant = s
    var color = Color(0.9, 0.5, 0.2) if dominant.polarity == "dark" else Color(0.5, 0.9, 0.5)
    emotion_label_node.text = dominant.label
    emotion_label_node.modulate = color
    emotion_label_node.visible = true
else:
    emotion_label_node.visible = false
```

**Note:** The exact node path and structure of the character panel will differ from the placeholder above. Read `scripts/ui/main_menu.gd` and the corresponding `.tscn` before implementing to find the actual node structure. The logic is correct — only the path needs adjustment.

- [ ] **Step 3: Verify**

Set a character's fire pressure to −40 via cheat console:
```gdscript
PsychologySystem.apply_pressure(CharacterSystem.get_player(), "fire", -50.0)
```
Open the character sheet. The character's panel should show "Restless" or "Craving" in amber.

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/main_menu.gd
git commit -m "feat: show dominant emotional state label on character panel"
```

---

## Task 9: Wire existing perk morale references

**Files:**
- Modify: `scripts/autoload/combat_manager.gd` (perk wiring hooks)

**Note:** Several Leadership and Comedy perks reference "morale bonuses" in PERKS.md but aren't wired yet. This task wires the simplest ones — those that trigger on combat events and have a clear elemental mapping.

- [ ] **Step 1: Find morale-referencing perks in combat hooks**

Search `combat_manager.gd` for any existing perk logic that mentions morale, or look at the `_process_on_hit_perks` and `_process_turn_start_perks` hooks. Check which Leadership and Comedy perks are already wired.

- [ ] **Step 2: Add pressure calls to leadership aura perks**

Find the code that processes the Leadership skill's aura effect (granting bonuses to nearby allies). After any existing stat bonus is applied, add:

```gdscript
# Leadership aura: radiates Earth + Fire positive pressure to nearby allies
if perk_id in ["rally_the_troops", "inspiring_presence", "formation_discipline"]:
    for ally in _get_nearby_allies(unit, 3):
        if "character_data" in ally:
            PsychologySystem.apply_pressure(ally.character_data, "earth", 5.0)
            PsychologySystem.apply_pressure(ally.character_data, "fire", 3.0)
```

**Note:** The actual perk IDs and helper function names will differ. Read the existing perk wiring code before substituting. The amounts (5.0, 3.0) are starting values for tuning.

- [ ] **Step 3: Add pressure calls to Comedy perks**

Find Comedy skill perk wiring. After any existing effect, add:

```gdscript
# Comedy relieves tension: Air + Space positive pressure
if perk_id in ["comic_relief", "laugh_it_off", "fool_the_crowd"]:
    PsychologySystem.apply_pressure(attacker.character_data, "air", 8.0)
    PsychologySystem.apply_pressure(attacker.character_data, "space", 5.0)
```

- [ ] **Step 4: Commit**

```bash
git add scripts/autoload/combat_manager.gd
git commit -m "feat: wire leadership and comedy perks to psychology pressure"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by task |
|-----------------|----------------|
| Five elemental pressure meters per character | Task 2 |
| Intensity multiplier from elemental affinity | Task 3 |
| Baseline from race/background | Tasks 2, 5 |
| apply_pressure() public API | Task 3 |
| Three threshold levels (minor/major/crisis) on both poles | Tasks 3, 4 |
| Autonomous event fires once, partial valve | Task 4 |
| decay_toward_baseline() for rest | Task 5 |
| Event outcome "pressure" field | Task 6 |
| Combat hooks (victory, defeat, unit death) | Task 7 |
| Emotional label in character sheet | Task 8 |
| Leadership/Comedy perk wiring | Task 9 |
| Emotional vocabulary (named labels) | Task 3 (get_emotional_label) |
| Inter-party fallout from dark events | **Gap — see below** |
| Races.json baseline data | Task 2 |

**Gap: inter-party fallout from autonomous events**

The spec says dark autonomous events should create pressure in witnesses (e.g. Fire "Consumed" → Water −8 to nearby party). This is not wired above. The `autonomous_event_triggered` signal is emitted but nothing connects to it and applies fallout pressure.

Add this at the end of Task 4 (or as a small addition to psychology_system.gd):

```gdscript
## In psychology_system.gd _ready():
autonomous_event_triggered.connect(_on_autonomous_event)

## New function:
func _on_autonomous_event(character: Dictionary, element: String, polarity: String) -> void:
    if polarity != "dark":
        return  # Wisdom events handled separately in future
    # Apply fallout pressure to other party members
    var fallout: Dictionary = {
        "fire":  {"element": "water", "amount": -8.0},
        "water": {"element": "air",   "amount": -8.0},
        "earth": {"element": "water", "amount": -10.0},
        "air":   {"element": "air",   "amount": -8.0},
        "space": {"element": "space", "amount": -5.0},
    }
    if not element in fallout:
        return
    var entry = fallout[element]
    for member in CharacterSystem.get_party():
        if member == character:
            continue
        apply_pressure(member, entry.element, entry.amount)
```

Add this to Task 4, Step 2 (before the commit). Update the commit message to include fallout.

**Placeholder scan:** Task 8, Step 2 explicitly calls out that node paths need to be read before implementation — this is intentional (the scene structure can't be determined without reading it), not a placeholder.

**Type consistency:** `ELEMENTS` is defined as `Array[String]` and used consistently throughout. `apply_pressure` signature `(character: Dictionary, element: String, amount: float)` is consistent across all tasks. `get_emotional_label` and `get_active_statuses` match their call sites.
