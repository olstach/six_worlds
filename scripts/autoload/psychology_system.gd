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
	autonomous_event_triggered.connect(_on_autonomous_event)


## Returns how strongly this character reacts to triggers of the given element.
## Sourced from elemental affinity. Affinity 10 → 1.0×, affinity 40 → ~2.4×.
## This is an approximation — tune as needed during playtesting.
func _intensity_multiplier(character: Dictionary, element: String) -> float:
	## Sourced from elemental affinity. Affinity 10 → 1.0×, affinity 40 → ~2.4×, affinity 1 → ~0.1× (minimum).
	var affinity: float = 10.0  # default: log(10/10) = 0 → 1.0× multiplier when no affinity data
	if "elements" in character and element in character.elements:
		affinity = max(1.0, float(character.elements[element]))
	return max(0.1, 1.0 + log(affinity / 10.0))


## Apply emotional pressure to a character for the given element.
## amount is positive (toward wisdom) or negative (toward klesha).
## Intensity is multiplied by the character's elemental affinity.
func apply_pressure(character: Dictionary, element: String, amount: float) -> void:
	if not "emotional_pressure" in character:
		return
	if not element in character.emotional_pressure:
		return

	# Ensure crossing tracker exists (used by _check_thresholds)
	if not "emotional_crisis_fired" in character:
		character["emotional_crisis_fired"] = {}

	var scaled: float = amount * _intensity_multiplier(character, element)
	character.emotional_pressure[element] = clamp(
		character.emotional_pressure[element] + scaled,
		-100.0, 100.0
	)
	_check_thresholds(character, element)


## Called after every apply_pressure. Detects threshold crossings and fires effects.
func _check_thresholds(character: Dictionary, element: String) -> void:
	if not "emotional_crisis_fired" in character:
		character["emotional_crisis_fired"] = {}
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


## Returns all active emotional statuses for a character.
## Each entry: {element, level ("minor"/"major"/"crisis"), polarity ("dark"/"bright"), label}
func get_active_statuses(character: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not "emotional_pressure" in character:
		return result
	for element in ELEMENTS:
		var pressure: float = character.emotional_pressure.get(element, 0.0)
		var abs_p: float = abs(pressure)
		var polarity: String = "bright" if pressure >= 0 else "dark"
		if abs_p >= THRESHOLD_CRISIS:
			result.append({
				"element": element,
				"level": "crisis",
				"polarity": polarity,
				"label": get_emotional_label(character, element)
			})
		elif abs_p >= THRESHOLD_MAJOR:
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

	# crisis label (abs >= 75)
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


## Applies emotional fallout to other party members when a dark autonomous event fires.
## Witnessing a character's crisis is destabilizing for the rest of the party.
func _on_autonomous_event(character: Dictionary, element: String, polarity: String) -> void:
	if polarity != "dark":
		return  # Wisdom events are positive — fallout mechanic is future work
	# Each dark element has a characteristic effect on witnesses
	var fallout: Dictionary = {
		"fire":  {"element": "water", "amount": -8.0},
		"water": {"element": "air",   "amount": -8.0},
		"earth": {"element": "water", "amount": -10.0},
		"air":   {"element": "air",   "amount": -8.0},
		"space": {"element": "space", "amount": -5.0},
	}
	if not element in fallout:
		return
	var entry: Dictionary = fallout[element]
	for member in CharacterSystem.get_party():
		if member == character:
			continue
		apply_pressure(member, entry.element, entry.amount)


## Drift all elemental pressures toward the character's emotional baseline.
## Call this on rest (camp, inn, etc.). decay_amount is how far each element moves per call.
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
