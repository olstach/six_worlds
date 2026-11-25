extends Node
## Headless verification for the shared effect language (EffectVocab and, in
## later tasks, ValuePaths and EffectResolver).
##
## Run: godot --headless res://tools/verify_effects.tscn
##
## Exits non-zero if any assertion fails.

var failures: int = 0

## A runtime error inside a check aborts it and returns control to _ready(),
## which would then find no failures and report OK having verified nothing.
## Each check calls _done() as its last line; _ready() compares the count.
var checks_run: int = 0
const EXPECTED_CHECKS: int = 2


func _ready() -> void:
	_check_vocab_accepts_valid_effects()
	_check_vocab_rejects_invalid_effects()

	if checks_run != EXPECTED_CHECKS:
		printerr("  FAIL: %d of %d checks completed — one aborted partway, "
			% [checks_run, EXPECTED_CHECKS] + "so its assertions never ran")
		failures += 1

	if failures > 0:
		printerr("VERIFY FAILED: %d problem(s)" % failures)
		get_tree().quit(1)
	else:
		print("VERIFY OK (%d checks)" % checks_run)
		get_tree().quit(0)


func _done() -> void:
	checks_run += 1


func _fail(message: String) -> void:
	printerr("  FAIL: ", message)
	failures += 1


# ── EffectVocab ──────────────────────────────────────────────────────────────

func _check_vocab_accepts_valid_effects() -> void:
	for e in [
		{"op": "damage", "amount": 20, "type": "fire"},
		{"op": "damage", "amount": 30, "type": {"fire": 0.5, "black": 0.5}},
		{"op": "heal", "amount": "full"},
		{"op": "modify", "value": "attribute.strength", "mode": "fortify", "amount": 3},
		{"op": "modify", "value": "resource.mana", "mode": "absorb", "amount": {"base": 10, "per_spellpower": 0.5}},
		{"op": "modify", "value": "stat.movement", "mode": "set", "amount": 0},
		{"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 2,
		 "cleared_by": [{"rest": "full"}, {"heal": {"school": "white", "min_level": 5}}]},
		{"op": "status", "action": "apply", "status": "Burning", "chance": 50},
		{"op": "kill", "save": {"stat": "constitution", "tier": "hard"}, "on_save": "fail"},
	]:
		var errs := EffectVocab.validate(e, "test")
		if not errs.is_empty():
			_fail("valid effect rejected: %s → %s" % [e, errs])
	_done()


func _check_vocab_rejects_invalid_effects() -> void:
	var cases := {
		"unknown op": {"op": "explode"},
		"unknown namespace": {"op": "modify", "value": "mood.happy", "mode": "fortify", "amount": 1},
		"unknown attribute": {"op": "modify", "value": "attribute.wisdom", "mode": "fortify", "amount": 1},
		"mode not allowed for namespace": {"op": "modify", "value": "resource.hp", "mode": "fortify", "amount": 5},
		"unknown status": {"op": "status", "action": "apply", "status": "Not_A_Status"},
		"unknown shared field": {"op": "heal", "amount": 5, "chanse": 50},
		"unknown condition": {"op": "heal", "amount": 5, "if": ["on_a_tuesday"]},
		"unknown cleared_by kind": {"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 1, "cleared_by": [{"prayer": true}]},
		"damage-type split not summing to 1": {"op": "damage", "amount": 10, "type": {"fire": 0.5, "black": 0.4}},
	}
	for label in cases:
		if EffectVocab.validate(cases[label], "test").is_empty():
			_fail("invalid effect accepted (%s): %s" % [label, cases[label]])
	_done()
