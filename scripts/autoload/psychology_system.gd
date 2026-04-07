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
