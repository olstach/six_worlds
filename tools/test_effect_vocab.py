# tools/test_effect_vocab.py
# The Python mirror of scripts/effects/effect_vocab.gd. The nine valid and nine
# invalid effects are the same ones tools/verify_effects.gd checks in GDScript,
# so the two validators are held to one standard.
import json, os, sys, unittest
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from effect_check import check_effect, check_effects, check_status, OPS_PY, MODES_PY

VALID = [
    {"op": "damage", "amount": 20, "type": "fire"},
    {"op": "damage", "amount": 30, "type": {"fire": 0.5, "black": 0.5}},
    {"op": "heal", "amount": "full"},
    {"op": "modify", "value": "attribute.strength", "mode": "fortify", "amount": 3},
    {"op": "modify", "value": "resource.mana", "mode": "absorb",
     "amount": {"base": 10, "per_spellpower": 0.5}},
    {"op": "modify", "value": "stat.movement", "mode": "set", "amount": 0},
    {"op": "modify", "value": "attribute.focus", "mode": "damage", "amount": 2,
     "cleared_by": [{"rest": "full"}, {"heal": {"school": "white", "min_level": 5}}]},
    {"op": "status", "action": "apply", "status": "Burning", "chance": 50},
    {"op": "kill", "save": {"stat": "constitution", "tier": "hard"}, "on_save": "fail"},
]

INVALID = {
    "unknown op": {"op": "explode"},
    "unknown namespace": {"op": "modify", "value": "mood.happy", "mode": "fortify", "amount": 1},
    "unknown attribute": {"op": "modify", "value": "attribute.wisdom", "mode": "fortify", "amount": 1},
    "mode not allowed for namespace": {"op": "modify", "value": "resource.hp", "mode": "fortify", "amount": 5},
    "unknown status": {"op": "status", "action": "apply", "status": "Not_A_Status"},
    "unknown shared field": {"op": "heal", "amount": 5, "chanse": 50},
    "unknown condition": {"op": "heal", "amount": 5, "if": ["on_a_tuesday"]},
    "unknown cleared_by kind": {"op": "modify", "value": "attribute.focus", "mode": "damage",
                                "amount": 1, "cleared_by": [{"prayer": True}]},
    "damage-type split not summing to 1": {"op": "damage", "amount": 10, "type": {"fire": 0.5, "black": 0.4}},
}


class EffectVocabTests(unittest.TestCase):
    def test_accepts_valid(self):
        for e in VALID:
            self.assertEqual(check_effect(e, "t"), [], e)

    def test_rejects_invalid(self):
        for label, e in INVALID.items():
            self.assertNotEqual(check_effect(e, "t"), [], label)

    def test_reads_lists_from_gdscript(self):
        self.assertIn("modify", OPS_PY)
        self.assertIn("fortify", MODES_PY)

    def test_list_labels_each_effect(self):
        errs = check_effects([VALID[0], {"op": "explode"}, 5], "spell")
        self.assertEqual(len(errs), 2)
        self.assertTrue(errs[0].startswith("spell[1]:"))
        self.assertTrue(errs[1].startswith("spell[2]:"))

    # ── Status shape (Stage 2b, Task 2) ─────────────────────────────────────
    def test_status_valid_minimal(self):
        self.assertEqual(check_status(STATUS_MINIMAL, "t"), [])

    def test_status_cleanse_clear(self):
        self.assertEqual(check_effect({"op": "modify", "value": "attribute.focus",
            "mode": "damage", "amount": 1,
            "cleared_by": [{"cleanse": {"category": "curse"}}]}, "t"), [])

    def test_status_rejects(self):
        def bad(**over):
            d = json.loads(json.dumps(STATUS_MINIMAL))
            d.update(over)
            return d
        cases = {
            "unknown field": bad(flavour="x"),
            "unknown category": bad(categories=["spooky"]),
            "elemental.plasma": bad(categories=["elemental.plasma"]),
            "while_active restore": bad(while_active=[{"op": "modify",
                "value": "attribute.focus", "mode": "restore", "amount": 1}]),
            "unknown flag": bad(flags=["flying"]),
            "unknown trigger": bad(triggers=[{"on": "tuesday", "effects": []}]),
            "stacking strongest": bad(stacking={"mode": "strongest"}),
        }
        for label, d in cases.items():
            self.assertNotEqual(check_status(d, "t"), [], label)

    def test_status_accepts_elemental_and_immune_flag(self):
        d = dict(STATUS_MINIMAL, categories=["elemental.fire"], flags=["immune:poison"])
        self.assertEqual(check_status(d, "t"), [])

    # ── The status container (Stage 2b, Task 3) ─────────────────────────────
    def test_status_accepts_task3_triggers(self):
        for on in ["expire", "turn_start", "turn_end"]:
            d = dict(STATUS_MINIMAL, triggers=[{"on": on, "effects": [
                {"op": "damage", "amount": 5, "type": "fire"}]}])
            self.assertEqual(check_status(d, "t"), [], on)

    def test_status_periodic_when(self):
        for when in ["turn_start", "turn_end"]:
            d = dict(STATUS_MINIMAL, periodic={"when": when, "effects": [
                {"op": "damage", "amount": 5, "type": "fire"}]})
            self.assertEqual(check_status(d, "t"), [], when)
        d = dict(STATUS_MINIMAL, periodic={"when": "tuesday", "effects": []})
        self.assertNotEqual(check_status(d, "t"), [])

    def test_scale_per_turn_active(self):
        self.assertEqual(check_effect({"op": "damage", "amount": 5, "type": "fire",
            "scale": {"per": "turn_active", "amount": 2}}, "t"), [])


STATUS_MINIMAL = {"name": "Held", "icon": "x", "polarity": "negative",
                  "categories": ["control"], "scope": "combat",
                  "duration": {"kind": "turns", "base": 1}, "stacking": {"mode": "refresh"}}

if __name__ == "__main__":
    unittest.main()
