# Psychology System — Design Spec
Date: 2026-04-07

## Overview

A layered system that gives characters an inner life — emotional states that arise from gameplay events, shape character behavior, and occasionally produce autonomous actions (both destructive and luminous). The system is grounded in Vajrayana Buddhist psychology: the five elements, the five kleshas (mental poisons), and their corresponding wisdoms. The same emotional energy can express as confusion or clarity, craving or appreciation, depending on the character's cultivation.

**Three design layers, built in order:**
1. **Psychology core** — five elemental pressure meters, thresholds, status effects, autonomous events
2. **Personality traits & quirks** — individual predispositions that modulate emotional triggers and expressions
3. **Intervention mechanic** — party members with the right traits can influence each other's emotional states

This spec covers Layer 1 in full. Layers 2 and 3 are flagged for future design sessions.

---

## Philosophical Foundation

### The Five Elements and Their Emotional Energies

Each element carries a specific emotional quality. The same energy can manifest as a klesha (poison) when the mind is contracted, or as a wisdom when the mind is open. This distinction — same energy, different expression — is the core mechanic.

| Element | Klesha pole | Wisdom pole |
|---------|-------------|-------------|
| **Space** | Ignorance, confusion, dissociation | Rigpa — spacious clarity, open awareness |
| **Fire** | Desire, craving, obsession | Discriminating appreciation, magnetism |
| **Water** | Aversion — grief, fear, cold hatred (corrosive, not explosive) | Mirror-like precision, compassion |
| **Earth** | Pride, arrogance, insecurity | Equanimity, stability, groundedness |
| **Air** | Jealousy, paranoia, territoriality, sowing distrust | All-accomplishing energy, inspiration |

**Fire vs Water aggression:** Fire is loud and passionate — a punch, an outburst, a charge. Water is cold and devious — a poison, a cutting remark, information withheld, trust corroded. They share the aggressive register but express it entirely differently.

---

## Core Data Model

Each character stores five elemental pressure values:

```gdscript
character.emotional_pressure = {
    "space": 0.0,
    "fire":  0.0,
    "water": 0.0,
    "earth": 0.0,
    "air":   0.0,
}
```

**Range:** −100 (deep klesha) to +100 (deep wisdom). Zero is neutral.

**Baseline:** Each element has a resting point that pressure drifts toward during rest. Baseline is derived (not stored directly) from:
- Race/background `emotional_baseline` field (small defaults, e.g. `{"fire": 10, "water": -5}`)
- Yidam practice stage (raises brightness for the deity's associated element — future integration)
- Karma contribution (future integration)

**Intensity multiplier:** How strongly a character reacts to triggers of a given element, sourced from their elemental affinity:
```
intensity = 1.0 + log(affinity / 10.0)   # GDScript natural log; affinity 10 → 1×, affinity 40 → ~2.4×
```
This is a starting approximation to be tuned in play. A high-Fire character reacts more strongly to Fire triggers in both directions.

---

## Trigger System

Pressure changes come from four sources. Each trigger has an elemental tag and a base magnitude. Final magnitude = `base × intensity_multiplier(affinity)`.

### 1. Overworld Events
The richest source. Outcomes in `events/*.json` gain an optional `"pressure"` field:

```json
"outcomes": {
  "text": "The village is destroyed. Nothing remains.",
  "pressure": [
    {"element": "water", "amount": -20},
    {"element": "space", "amount": -10}
  ]
}
```

Multi-element events are common. Each element shifts independently.

### 2. Combat Outcomes
Coarser-grained but frequent. Applied to appropriate party members after resolution:

| Situation | Effect |
|-----------|--------|
| Party member dies | Water −15 to all witnesses |
| Decisive victory | Fire +10, Air +10 to all |
| Fleeing combat | Earth −10 to all |
| Killing a helpless enemy | Water −12, Space −8 to actor |
| Witnessing great courage | Fire +12 to witnesses |
| Near-death recovery (bleed-out saved) | Water −8, Fire +8 to saved character |

### 3. Overworld Conditions
Environmental pressure, applied per rest or per day of travel:

| Condition | Effect |
|-----------|--------|
| Travelling through Hell | Space −5/day (oppressive confusion) |
| Reaching a shrine | Element-specific +recovery (per shrine type) |
| Rest (camp/inn) | All elements drift ~10 toward baseline |

### 4. Inter-Party Fallout
Autonomous dark events create pressure in witnesses:

| Dark event | Fallout |
|------------|---------|
| Fire — Consumed | Water −8 to nearby party (distressing to witness) |
| Water — Cold rage | Air −8 to target, Earth −5 to witnesses (destabilizing) |
| Earth — Humiliated | Water −10 to berated party member |
| Air — Envious | Air −8 to whole party (distrust is contagious) |

Wisdom events radiate positive pressure in the same way.

---

## Threshold System

Four thresholds on each side, symmetric:

```
−75  Autonomous event (dark)  ←─────┤
−50  Major status (dark)            │
−33  Minor status (dark)            │
  0  Neutral                        │
+33  Minor status (bright)          │
+50  Major status (bright)          │
+75  Autonomous event (bright) ─────┘
```

**Status effects** are persistent: active while pressure stays beyond the threshold, removed when pressure crosses back. Characters can hold multiple statuses if multiple elements are in range.

**Autonomous events** fire *once* when the threshold is crossed, then bump pressure ~20 points back toward neutral (partial valve — the energy discharges but doesn't resolve). Without rest and integration, pressure rebuilds and events recur. The character's crisis becomes a pattern.

**Chronic darkness (future layer):** A separate counter tracks time spent below −50. Extended periods accumulate additional relationship damage, behavioral restrictions, and eventually permanent quirk acquisition.

---

## Emotional Vocabulary

Named states for UI display and event text. Status names appear on the character sheet; autonomous event descriptions appear in the combat/event log.

### Space (Rigpa axis — awareness itself)

| Threshold | Klesha state | Wisdom state |
|-----------|-------------|--------------|
| ±33 | **Confused** — foggy, can't quite grasp events. −3 init, −5% accuracy | **Clear-headed** — unusual sharpness. +3 init, +5% awareness |
| ±50 | **Dissociated** — going through motions, detached. −10 init, −10% all rolls | **Open** — spacious presence, nothing rattles them. +10 mental resistance |
| ±75 | **Absent** — wanders off, misses next event or combat turn. Autonomous. | **Rigpa** — moment of piercing clarity. Breaks party-wide confusion or fear, sees through a deception. Discharges once. |

### Fire (Desire / Discriminating Appreciation)

| Threshold | Klesha state | Wisdom state |
|-----------|-------------|--------------|
| ±33 | **Restless** — craving distraction. −5 social, impulsive minor purchases | **Warm** — engaged, appreciative. +5 social, +5% leadership/performance |
| ±50 | **Craving** — fixated on getting something. −10 init, −15% yoga/wisdom checks | **Magnetizing** — draws people naturally. +15 charm, +20% persuasion/leadership |
| ±75 | **Consumed** — disappears to drink, gamble, pursue obsession. Returns with status effects. Autonomous. | **Radiant** — spontaneous inspiration: rallying speech, rallies dying ally, fires up whole party. Discharges once. |

### Water (Aversion — grief / fear / cold hatred)

| Threshold | Klesha state | Wisdom state |
|-----------|-------------|--------------|
| ±33 | **Irritable** — short fuse, cold edge. −5 social, +5% physical damage | **Focused** — sharp and precise. +5 init, +5% accuracy |
| ±50 | **Grief-struck** — heavy with loss or cold rage. −10 init, −15% accuracy, +10% damage | **Clear-eyed** — sees through pretense. +15% awareness, +10% detect deception |
| ±75 | **Poisonous** — cutting remarks, information withheld, quiet sabotage. Causes Air/Water pressure drop in target. Autonomous. | **Compassionate** — calms a raging party member, absorbs a lethal hit for an ally. Discharges once. |

*Note: Water dark is corrosive and quiet, not explosive. The damage is interpersonal.*

### Earth (Pride / Equanimity)

| Threshold | Klesha state | Wisdom state |
|-----------|-------------|--------------|
| ±33 | **Insecure** — pride wounded, needs to re-establish status. −5 social, −5% visible-failure checks | **Grounded** — steady and reliable. +5 constitution checks, +3 resistance to pressure drops |
| ±50 | **Arrogant** — defensive posturing. −15% social, refuses choices that imply weakness | **Equanimous** — nothing shakes them. +15% fear resistance, +10 leadership |
| ±75 | **Humiliated** — berates party member, makes unilateral bad decision, isolates. Autonomous. | **Unshakeable** — creates order in chaos: prevents rout, grounds panicking party, holds an impossible position. Discharges once. |

### Air (Jealousy / All-Accomplishing Energy)

| Threshold | Klesha state | Wisdom state |
|-----------|-------------|--------------|
| ±33 | **Anxious** — scanning for threats, comparing. −5 init, −5% unfamiliar-situation checks | **Alert** — quick and responsive. +5 init, +5% notice hidden things |
| ±50 | **Paranoid** — suspects others. −15% trust-based social, −10 party coordination | **Inspired** — sees what needs doing. +15% crafting/alchemy/learning, +10 init |
| ±75 | **Envious** — spreads distrust, steals loot share, sabotages quietly. Others gain Air− pressure. Autonomous. | **Brilliant** — spontaneous perfect action: finds the escape route, solves the impossible problem, coordinates party flawlessly. Discharges once. |

---

## Integration with Existing Systems

### New Autoload: PsychologySystem
Loads after CharacterSystem. Owns all pressure logic.

**Public API:**
```gdscript
PsychologySystem.apply_pressure(character, element, amount)
PsychologySystem.get_active_statuses(character) -> Array[Dictionary]
PsychologySystem.decay_toward_baseline(character)   # called on rest
PsychologySystem.get_emotional_label(character, element) -> String
```

Internally calls `check_thresholds(character)` after every `apply_pressure()`, fires autonomous events via EventManager when thresholds are crossed.

### Event System (event_manager.gd)
- Add optional `"pressure"` field to outcome objects in JSON
- EventManager reads and calls `PsychologySystem.apply_pressure()` on resolution
- No structural changes to existing event format

### Combat System (combat_manager.gd)
- A handful of named hooks at existing resolution points (death, victory, flee, etc.)
- Each calls `PsychologySystem.apply_pressure()` on appropriate characters

### Character Data (character_system.gd)
- Add `emotional_pressure` dict to `BASE_CHARACTER`
- Add `emotional_baseline` sourced from race/background JSON

### Race/Background Data
- Add `"emotional_baseline": {"fire": 10, "water": -5}` to relevant race entries
- Defaults to all-zero if absent

### Existing Perks (Leadership, Comedy, etc.)
- Perks that reference "morale bonuses" wire to `apply_pressure()` calls on relevant elements
- Leadership → Earth/Fire positive pressure on nearby allies
- Comedy → Air/Space positive pressure
- No perk redesign needed, just wiring at the call sites

---

## Future Layers (Not In Scope Now)

**Rest system:** Party stays in place, time passes, pressure decays toward baseline. Characters can practice mantras (yidam brightness), tend relationships. A natural companion piece.

**Time passage system:** Needed to make environmental pressure (Hell −5/day) and chronic darkness meaningful.

**Yidam integration:** Mantra practice and relationship stage raise brightness baseline per element. High yidam practice = high baseline = emotional energy tends toward wisdom expression without effort.

**Chronic darkness:** Separate counter for time spent below −50. Accumulates relationship damage, behavioral restrictions, permanent quirk acquisition.

**Personality traits & quirks (Layer 2):** Individual predispositions — which situations trigger which element, personal thresholds that differ from the defaults, characteristic expression styles.

**Intervention mechanic (Layer 3):** Party members with social skills (Comedy, Persuasion, Yoga, Grace, Medicine) or specific traits can intervene in another character's emotional state. The grandmother who talks the berserker down. Skill-dependent, not guaranteed.

**Character sheet psychology tab (UI):** A dedicated tab showing elemental tendencies (visual spectrum per element), active emotional statuses, and eventually personality traits and quirks. To be designed once the system has enough content to display.

---

## Files Affected (Implementation)

| File | Change |
|------|--------|
| `scripts/autoload/psychology_system.gd` | New autoload — owns all pressure logic |
| `scripts/autoload/character_system.gd` | Add `emotional_pressure`, `emotional_baseline` to BASE_CHARACTER |
| `scripts/autoload/event_manager.gd` | Read `"pressure"` field from outcomes, call PsychologySystem |
| `scripts/autoload/combat_manager.gd` | Add pressure hooks at death/victory/flee/etc resolution points |
| `resources/data/races.json` | Add `emotional_baseline` per race |
| `resources/data/events/*.json` | Add `"pressure"` fields to relevant outcomes |
| `scripts/ui/main_menu.gd` | Display active emotional status label on character panel |
