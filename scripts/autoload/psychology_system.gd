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

## Emitted when a quirk crisis reaction fires, providing a narrative log for the UI.
## Connect in overworld.gd / combat_arena.gd to show a toast or combat log entry.
signal emotional_crisis_log(character_name: String, message: String)

## All five elements in order
const ELEMENTS: Array[String] = ["space", "fire", "water", "earth", "air"]

## Dispatch table: quirk event_tag → {element_polarity → reaction}.
## reaction keys: "log" (string, %s = char name), "self_pressure" (Array of {element, amount}),
##                "party_pressure" (Array of {element, amount})
## Self-pressure applies to the character in crisis; party_pressure applies to all other members.
const QUIRK_CRISIS_REACTIONS: Dictionary = {
	"hot_tempered": {
		"fire_dark": {
			"log": "%s flies into a rage.",
			"party_pressure": [{"element": "water", "amount": -10.0}]
		},
		"water_dark": {
			"log": "%s's grief curdles into bitter anger.",
			"self_pressure": [{"element": "fire", "amount": -15.0}]
		}
	},
	"patient": {
		"fire_dark": {
			"log": "%s breathes through the surge, drawing on deep reserves of calm.",
			"self_pressure": [{"element": "fire", "amount": 20.0}]
		},
		"earth_dark": {
			"log": "%s remains unmoved even as the weight presses in.",
			"self_pressure": [{"element": "earth", "amount": 15.0}]
		}
	},
	"brave": {
		"water_dark": {
			"log": "%s faces the fear head-on — courage steadies them.",
			"self_pressure": [{"element": "water", "amount": 20.0}]
		},
		"earth_dark": {
			"log": "%s stands firm, refusing to be beaten down.",
			"self_pressure": [{"element": "earth", "amount": 15.0}]
		}
	},
	"timid": {
		"water_dark": {
			"log": "%s freezes, paralyzed by fear.",
			"self_pressure": [{"element": "space", "amount": -15.0}]
		},
		"air_dark": {
			"log": "%s retreats inward, consumed by dread.",
			"self_pressure": [{"element": "space", "amount": -10.0}, {"element": "fire", "amount": -8.0}]
		}
	},
	"curious": {
		"space_dark": {
			"log": "%s reaches desperately for meaning, grasping at anything to understand.",
			"self_pressure": [{"element": "air", "amount": 10.0}]
		},
		"space_bright": {
			"log": "%s's curiosity ignites in the clarity.",
			"party_pressure": [{"element": "air", "amount": 5.0}]
		}
	},
	"stubborn": {
		"earth_dark": {
			"log": "%s digs in, refusing to yield to anything.",
			"self_pressure":  [{"element": "earth", "amount": 10.0}],
			"party_pressure": [{"element": "air",   "amount": -8.0}]
		}
	},
	"suspicious": {
		"air_dark": {
			"log": "%s's paranoia peaks — enemies everywhere.",
			"party_pressure": [{"element": "air", "amount": -12.0}]
		}
	},
	"paranoid": {
		"air_dark": {
			"log": "%s is consumed by paranoid certainty — no one can be trusted.",
			"party_pressure": [{"element": "air", "amount": -15.0}, {"element": "water", "amount": -8.0}]
		},
		"space_dark": {
			"log": "%s becomes convinced of betrayal.",
			"party_pressure": [{"element": "water", "amount": -10.0}]
		}
	},
	"greedy": {
		"earth_dark": {
			"log": "%s's greed surfaces — resources feel scarce.",
			"party_pressure": [{"element": "water", "amount": -8.0}]
		},
		"fire_dark": {
			"log": "%s schemes for advantage even mid-crisis.",
			"self_pressure": [{"element": "earth", "amount": 8.0}]
		}
	},
	"generous": {
		"water_dark": {
			"log": "%s opens their heart even to the grief.",
			"self_pressure": [{"element": "water", "amount": 15.0}]
		},
		"earth_dark": {
			"log": "%s gives freely, trying to restore what's broken.",
			"party_pressure": [{"element": "water", "amount": 8.0}]
		}
	},
	"melancholic": {
		"water_dark": {
			"log": "%s sinks into familiar darkness.",
			"self_pressure":  [{"element": "air",   "amount": -10.0}],
			"party_pressure": [{"element": "water", "amount": -5.0}]
		},
		"earth_dark": {
			"log": "%s takes the weight inward, deepening the desolation.",
			"self_pressure": [{"element": "water", "amount": -8.0}]
		}
	},
	"vain": {
		"air_dark": {
			"log": "%s's vanity twists into bitter envy.",
			"party_pressure": [{"element": "air", "amount": -10.0}]
		},
		"earth_dark": {
			"log": "%s's pride becomes brittle rage.",
			"self_pressure": [{"element": "fire", "amount": -10.0}]
		}
	},
	"haunted": {
		"water_dark": {
			"log": "%s is overwhelmed by haunting visions.",
			"party_pressure": [{"element": "space", "amount": -8.0}]
		},
		"space_dark": {
			"log": "%s loses themselves in the past.",
			"self_pressure": [{"element": "water", "amount": -10.0}]
		}
	},
	"war_hardened": {
		"water_dark": {
			"log": "%s dissociates, reverting to soldier-mode — a familiar numbness.",
			"self_pressure": [{"element": "water", "amount": 15.0}]
		}
	},
	"grief_struck": {
		"water_dark": {
			"log": "%s is overwhelmed by the weight of loss.",
			"self_pressure":  [{"element": "space", "amount": -15.0}],
			"party_pressure": [{"element": "water", "amount": -8.0}]
		}
	},
	"blood_handed": {
		"water_dark": {
			"log": "%s drowns in remorse for past actions.",
			"self_pressure": [{"element": "space", "amount": -10.0}]
		},
		"fire_dark": {
			"log": "%s's past violence resurfaces in the crisis.",
			"self_pressure": [{"element": "earth", "amount": -10.0}]
		}
	},
	"composed": {
		"fire_dark": {
			"log": "%s maintains composure, drawing strength from hard-won calm.",
			"self_pressure": [{"element": "fire", "amount": 20.0}]
		},
		"water_dark": {
			"log": "%s accepts the grief with practiced stillness.",
			"self_pressure": [{"element": "water", "amount": 15.0}]
		}
	},
	"addiction": {
		"fire_dark": {
			"log": "%s reaches for their habit to dull the craving.",
			"self_pressure": [{"element": "earth", "amount": -10.0}, {"element": "water", "amount": -5.0}]
		},
		"water_dark": {
			"log": "%s drowns the grief in familiar escape.",
			"self_pressure": [{"element": "fire", "amount": 8.0}, {"element": "earth", "amount": -8.0}]
		}
	},
	"devout": {
		"water_dark": {
			"log": "%s turns to prayer, finding stillness in the form.",
			"self_pressure": [{"element": "water", "amount": 15.0}]
		},
		"earth_dark": {
			"log": "%s grounds themselves in devotional practice.",
			"self_pressure": [{"element": "earth", "amount": 10.0}]
		}
	},
	"lapsed": {
		"space_dark": {
			"log": "%s reaches for old prayers but finds only empty forms.",
			"self_pressure": [{"element": "space", "amount": -10.0}]
		}
	},
	"enlightened": {
		"space_bright": {
			"log": "%s's insight deepens in the luminous clarity.",
			"party_pressure": [{"element": "space", "amount": 5.0}]
		}
	},
}

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
	## Zero affinity means no build-up yet — treat as neutral (10.0) so new characters react normally.
	var affinity: float = 10.0  # default: log(10/10) = 0 → 1.0× multiplier
	if "elements" in character and element in character.elements:
		var raw: float = float(character.elements[element])
		if raw > 0.0:
			affinity = raw  # 0 stays at 10.0 (neutral) — only use raw if affinity has built up
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


## Checks the character's quirks for any reaction matching this element+polarity crisis.
## Applies self/party pressure effects and emits emotional_crisis_log for each reaction found.
func _resolve_quirk_reactions(character: Dictionary, element: String, polarity: String) -> void:
	if not QuirkSystem:
		return
	var key: String = element + "_" + polarity
	var char_name: String = character.get("name", "?")
	for quirk_id in character.get("quirks", []):
		var q: Dictionary = QuirkSystem.get_quirk(quirk_id)
		var fired: bool = false
		for tag in q.get("event_tags", []):
			if fired:
				break  # only the first matching tag fires per quirk
			var tag_reactions: Dictionary = QUIRK_CRISIS_REACTIONS.get(tag, {})
			if not key in tag_reactions:
				continue
			fired = true
			var reaction: Dictionary = tag_reactions[key]
			var log_msg: String = reaction.get("log", "") % char_name
			if log_msg != "":
				print("PsychologySystem: " + log_msg)
				emotional_crisis_log.emit(char_name, log_msg)
			for entry in reaction.get("self_pressure", []):
				var el: String = str(entry.get("element", ""))
				var amt: float = float(entry.get("amount", 0.0))
				if el in ELEMENTS and amt != 0.0:
					apply_pressure(character, el, amt)
			for entry in reaction.get("party_pressure", []):
				var el: String = str(entry.get("element", ""))
				var amt: float = float(entry.get("amount", 0.0))
				if not el in ELEMENTS or amt == 0.0:
					continue
				for member in CharacterSystem.get_party():
					if member == character:
						continue
					apply_pressure(member, el, amt)


## Applies emotional fallout to other party members when a dark autonomous event fires.
## Witnessing a character's crisis is destabilizing for the rest of the party.
func _on_autonomous_event(character: Dictionary, element: String, polarity: String) -> void:
	# Quirk reactions apply to both bright and dark crises
	_resolve_quirk_reactions(character, element, polarity)

	if polarity != "dark":
		return  # Base fallout for dark only — bright events are positive
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
