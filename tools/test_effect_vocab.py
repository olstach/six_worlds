# tools/test_effect_vocab.py
# The Python mirror of scripts/effects/effect_vocab.gd. The nine valid and nine
# invalid effects are the same ones tools/verify_effects.gd checks in GDScript,
# so the two validators are held to one standard.
import json, os, sys, unittest
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from effect_check import check_effect, check_effects, check_status, check_aura, check_zone, OPS_PY, MODES_PY, FLAGS as FLAGS_PY

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

    # ── Statuses migrated: numbers (Stage 2b, Task 4) ───────────────────────
    def test_status_stacking_independent(self):
        d = dict(STATUS_MINIMAL, stacking={"mode": "independent"})
        self.assertEqual(check_status(d, "t"), [])
        d = dict(STATUS_MINIMAL, stacking={"mode": "pile"})
        self.assertNotEqual(check_status(d, "t"), [])

    def test_resist_groups_all_and_magic(self):
        for name in ["all", "magic", "all_elemental", "physical"]:
            self.assertEqual(check_effect({"op": "modify", "value": "resist." + name,
                "mode": "fortify", "amount": 25}, "t"), [], name)
        self.assertNotEqual(check_effect({"op": "modify", "value": "resist.everything",
            "mode": "fortify", "amount": 25}, "t"), [])

    def test_flags_read_from_gdscript(self):
        # Task 5: FLAGS is the list of yes/no rules statuses.json uses.
        for f in ["cannot_move", "breaks_concentration", "grants_stealth"]:
            self.assertIn(f, FLAGS_PY)
        self.assertNotIn("immobilized", FLAGS_PY)   # merged into cannot_move
        d = dict(STATUS_MINIMAL, flags=["cannot_move", "breaks_concentration", "immune:Charmed"])
        self.assertEqual(check_status(d, "t"), [])

    def test_retired_legacy_status_keys_rejected(self):
        for key in ["type", "category", "duration_type", "default_duration",
                    "stackable", "grants_resistance", "grants_vulnerability",
                    "bonus_amount", "penalty_amount"]:
            d = dict(STATUS_MINIMAL, **{key: 1})
            self.assertNotEqual(check_status(d, "t"), [], key)

    # ── Behaviour as triggers, periodic effects, intercepts (Task 6) ───────
    def test_borrowed_value_magnitude(self):
        for src in ["status.value", "status.stacks", "caster.skill.leadership",
                    "target.attribute.focus", "source.stat.dodge", "event.damage"]:
            e = {"op": "damage", "type": "fire",
                 "amount": {"from": src, "pct": 50, "default": 5}}
            self.assertEqual(check_effect(e, "t"), [], src)
        for bad in [{"from": "caster.skill.knitting"}, {"from": "moon.phase"},
                    {"from": "status.value", "pct": "half"},
                    {"from": "event.damage", "round": "sideways"},
                    {"from": "status.value", "bonus": 1}]:
            self.assertNotEqual(check_effect({"op": "heal", "amount": bad}, "t"), [], bad)

    def test_task6_triggers_and_limit(self):
        for on in ["struck", "hit", "enemy_enters_reach", "ally_threatened"]:
            t = {"on": on, "limit": {"per": "turn", "count": 1},
                 "effects": [{"op": "damage", "to": "source", "amount": 5, "type": "fire"}]}
            if on != "hit":
                t["reach"] = "weapon" if on == "struck" else 2
            d = dict(STATUS_MINIMAL, triggers=[t])
            self.assertEqual(check_status(d, "t"), [], on)
        d = dict(STATUS_MINIMAL, triggers=[{"on": "hit", "reach": 1, "effects": []}])
        self.assertNotEqual(check_status(d, "t"), [])
        d = dict(STATUS_MINIMAL, triggers=[{"on": "struck", "limit": {"per": "round"}, "effects": []}])
        self.assertNotEqual(check_status(d, "t"), [])

    def test_intercept_ops_only_in_intercepting_triggers(self):
        d = dict(STATUS_MINIMAL, triggers=[{"on": "attacked_in_melee", "effects": [
            {"op": "negate"}, {"op": "attack", "target": "source", "power_pct": 130}]}])
        self.assertEqual(check_status(d, "t"), [])
        d = dict(STATUS_MINIMAL, triggers=[{"on": "struck", "effects": [{"op": "negate"}]}])
        self.assertNotEqual(check_status(d, "t"), [])
        self.assertNotEqual(check_effect({"op": "negate"}, "spell"), [])

    def test_status_save_and_spread(self):
        d = dict(STATUS_MINIMAL, save={"stat": "constitution", "dc": 15, "when": "turn_start"},
                 spread={"to": "adjacent", "chance": 15, "when": "turn_start"})
        self.assertEqual(check_status(d, "t"), [])
        d = dict(STATUS_MINIMAL, spread={"to": "everyone", "chance": "low"})
        self.assertNotEqual(check_status(d, "t"), [])

    def test_task6_legacy_keys_rejected(self):
        for key in ["effects", "damage_per_turn", "heal_per_turn", "retaliation",
                    "reaction", "save_type", "summon_on_expire",
                    "damage_increase_per_turn"]:
            d = dict(STATUS_MINIMAL, **{key: 1})
            self.assertNotEqual(check_status(d, "t"), [], key)

    # ── Auras and zones as effects (Task 8) ─────────────────────────────────
    def test_new_stats_and_affliction_resists(self):
        for v in ["stat.max_hp", "stat.mana_cost_pct", "resist.bleed", "resist.disease"]:
            self.assertEqual(check_effect({"op": "modify", "value": v, "mode": "fortify",
                                           "amount": 10}, "t"), [], v)
        for v in ["stat.magic_damage_taken", "stat.physical_damage_taken"]:
            self.assertEqual(check_effect({"op": "modify", "value": v, "mode": "multiply",
                                           "amount": 0.75}, "t"), [], v)
        for v in ["stat.max_hp", "stat.mana_cost_pct"]:
            self.assertNotEqual(check_effect({"op": "modify", "value": v, "mode": "multiply",
                                              "amount": 2}, "t"), [], v)

    def test_fixed_dc_save_and_summon_from(self):
        ok = {"op": "status", "action": "apply", "status": "Confused",
              "save": {"stat": "focus", "dc": 14, "dc_drop_per_pass": 2}}
        self.assertEqual(check_effect(ok, "t"), [])
        for bad in [{"stat": "focus", "dc": 14, "tier": "hard"},
                    {"stat": "focus", "tier": "hard", "dc_drop_per_pass": 2},
                    {"stat": "focus", "dc": "high"}, {"stat": "focus", "dc": 3, "bonus": 1}]:
            self.assertNotEqual(check_effect(dict(ok, save=bad), "t"), [], bad)
        self.assertEqual(check_effect({"op": "summon", "as": "Zombie", "from": "corpse"}, "t"), [])
        self.assertNotEqual(check_effect({"op": "summon", "as": "Zombie", "from": "grave"}, "t"), [])

    def test_aura_shape(self):
        ok = {"name": "A", "radius": 1, "affects": "allies", "while_inside": [
            {"op": "modify", "value": "stat.dodge", "mode": "fortify", "amount": 3},
            {"op": "modify", "value": "stat.armor", "mode": "fortify",
             "amount": {"pct_of": "target.armor", "value": 10}},
            {"op": "heal", "amount": {"from": "status.value", "default": 5}}]}
        self.assertEqual(check_aura(ok, "a"), [])
        bad = {
            "to": [{"op": "heal", "amount": 3, "to": "caster"}],
            "chance on modify": [{"op": "modify", "value": "stat.dodge", "mode": "fortify",
                                  "amount": 3, "chance": 50}],
            "set": [{"op": "modify", "value": "stat.dodge", "mode": "set", "amount": 3}],
            "attribute": [{"op": "modify", "value": "attribute.focus", "mode": "fortify", "amount": 3}],
            "getter borrow": [{"op": "modify", "value": "stat.dodge", "mode": "fortify",
                               "amount": {"from": "target.stat.dodge"}}],
            "move": [{"op": "move", "mode": "push"}],
            "empty": [],
        }
        for label, effects in bad.items():
            self.assertNotEqual(check_aura(dict(ok, while_inside=effects), "a"), [], label)
        self.assertNotEqual(check_aura(dict(ok, payloads=[]), "a"), [])

    def test_zone_shape(self):
        ok = {"name": "Z", "affects": "enemies",
              "turn_start_inside": [{"op": "damage", "amount": 7, "type": "piercing"}],
              "on_enter": [{"op": "status", "action": "apply", "status": "Slowed", "duration": 2,
                            "to": "all_in_area"}],
              "on_death_inside": [{"op": "summon", "as": "Zombie", "from": "corpse"}]}
        self.assertEqual(check_zone(ok, "z"), [])
        bad = {
            "lasting modify on enter": {"on_enter": [{"op": "modify", "value": "stat.dodge",
                                                      "mode": "fortify", "amount": 3}]},
            "summon with to": {"on_death_inside": [{"op": "summon", "as": "Zombie",
                                                    "from": "corpse", "to": "enemies_in_area"}]},
            "corpse outside death": {"on_enter": [{"op": "summon", "as": "Zombie", "from": "corpse"}]},
            "old payload": {"on_enter": [{"kind": "damage", "amount": 3, "element": "fire"}]},
            "bad to": {"on_enter": [{"op": "damage", "amount": 3, "type": "fire", "to": "party"}]},
            "unknown trigger": {"on_exit": []},
        }
        for label, extra in bad.items():
            d = {"name": "Z", "affects": "all"}
            d.update(extra)
            self.assertNotEqual(check_zone(d, "z"), [], label)
        self.assertNotEqual(check_zone({"name": "Z", "affects": "all"}, "z"), [])

    def test_live_auras_and_zones_validate(self):
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        auras = json.load(open(os.path.join(root, "resources/data/auras.json")))["auras"]
        zones = json.load(open(os.path.join(root, "resources/data/zones.json")))["zones"]
        for k, v in auras.items():
            if not k.startswith("_"):
                self.assertEqual(check_aura(v, k), [], k)
        for k, v in zones.items():
            if not k.startswith("_"):
                self.assertEqual(check_zone(v, k), [], k)

    # ── Group targets, affinity and pressure (Task 9) ───────────────────────
    def _mod(self, value, mode="fortify", amount=2):
        return check_effect({"op": "modify", "value": value, "mode": mode, "amount": amount}, "t")

    def test_group_targets(self):
        for v in ["skills.element.fire", "skills.element.space", "skills.magic",
                  "skills.combat", "skills.general", "attributes.all"]:
            for mode in ("fortify", "drain", "damage"):
                self.assertEqual(self._mod(v, mode), [], (v, mode))
        for v in ["skills.element.plasma", "skills.element", "skills.element.fire.x",
                  "skills.wizardry", "attributes.some", "attributes.strength",
                  "attributes.all.x"]:
            self.assertNotEqual(self._mod(v), [], v)
        for mode in ("set", "multiply", "absorb"):
            self.assertNotEqual(self._mod("skills.magic", mode), [], mode)

    def test_affinity_value(self):
        for el in ["earth", "fire", "water", "air", "space"]:
            for mode in ("fortify", "drain", "set", "multiply"):
                self.assertEqual(self._mod("affinity." + el, mode), [], (el, mode))
        self.assertNotEqual(self._mod("affinity.plasma"), [])
        self.assertNotEqual(self._mod("affinity.fire", "damage"), [])

    def test_pressure_value(self):
        for mode in ("fortify", "drain"):
            self.assertEqual(self._mod("pressure.fire", mode, 5), [], mode)
        self.assertNotEqual(self._mod("pressure.plasma"), [])
        for mode in ("set", "multiply", "damage", "restore"):
            self.assertNotEqual(self._mod("pressure.fire", mode), [], mode)

    def test_groups_and_pressure_cannot_be_borrowed(self):
        for src in ["skills.magic", "attributes.all", "pressure.fire"]:
            e = {"op": "heal", "amount": {"pct_of": src, "value": 50}}
            self.assertNotEqual(check_effect(e, "t"), [], src)


STATUS_MINIMAL = {"name": "Held", "icon": "x", "polarity": "negative",
                  "categories": ["control"], "scope": "combat",
                  "duration": {"kind": "turns", "base": 1}, "stacking": {"mode": "refresh"}}

if __name__ == "__main__":
    unittest.main()
