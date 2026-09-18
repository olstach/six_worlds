#!/usr/bin/env python3
"""Give passive perks an `effects` array the engine can read.

Companion to wire_active_perks.py. Where that one fills in `combat_data` for
activated abilities, this fills in `effects` for passives — see the header of
`PerkSystem`'s "PASSIVE PERK EFFECTS" section for the schema and for where each
effect type is consumed.

Run:
    python3 tools/wire_passive_perks.py            # dry run
    python3 tools/wire_passive_perks.py --write    # apply
    python3 tools/validate_data.py                 # always

The load-bearing rule
---------------------
Around 140 passive perks are implemented by hand in `scripts/`, checked by id with
`PerkSystem.has_perk()` at the moment they matter. Giving one of those an
`effects` array would make it fire twice — once from its hand-written branch
and once from the engine. So this script derives the hardcoded set by scanning
`scripts/` for each perk id and REFUSES to write effects for any of them. The
list is computed, never maintained by hand, so a perk hardcoded tomorrow is
protected without anyone remembering to add it here.

Vocabularies come from scripts/combat/combat_stats.gd, parsed rather than
restated, for the reason given in that file.
"""

import argparse
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PERKS = ROOT / "resources" / "data" / "perks.json"
STATS_GD = ROOT / "scripts" / "combat" / "combat_stats.gd"
SCRIPTS = ROOT / "scripts"

# Damage/effect types a resistance entry may name. Matches CombatUnit.resistances
# plus the non-elemental ones statuses use.
RESISTANCE_TYPES = {
    "physical", "space", "air", "fire", "water", "earth",
    "bleed", "poison", "disease", "mental",
}

# Triggers CombatManager._fire_perk_triggers() is actually called with.
# Wiring an effect to a trigger nothing fires is silent death, same as the rest.
LIVE_TRIGGERS = {"on_hit", "on_crit", "on_kill", "dodge_success"}

# Payload types _apply_trigger_effect() knows.
LIVE_PAYLOADS = {"buff", "status", "heal", "restore_stamina"}

# Conditions CombatUnit._perk_condition_met() answers.
LIVE_CONDITIONS = {
    "wielding_sword", "wielding_axe", "wielding_mace", "wielding_spear",
    "wielding_dagger", "wielding_staff", "wielding_ranged", "unarmed",
    "not_flanked", "did_not_move", "moved_this_turn", "from_stealth",
    "below_half_hp", "above_half_hp",
}


def _gdscript_string_array(const_name):
    text = STATS_GD.read_text(encoding="utf-8")
    match = re.search(
        r"const %s: Array\[String\] = \[(.*?)\n\]" % const_name, text, re.S
    )
    assert match, f"{const_name} not found in {STATS_GD.name}"
    found = set(re.findall(r'"([^"]+)"', match.group(1)))
    assert found, f"{const_name} parsed empty"
    return found


DERIVED_STATS = _gdscript_string_array("DERIVED")
MODIFIABLE_STATS = _gdscript_string_array("MODIFIABLE")


# ---------------------------------------------------------------------------
# First tranche. Every entry is a perk that is NOT hardcoded, whose effect the
# engine can already consume end to end.
#
# Deliberately excluded for now: `non_combat` effects. ShopSystem and
# EventManager have no consumer for them yet, and authoring an effect before
# its reader exists is exactly the failure this whole pass has been unwinding.
# ---------------------------------------------------------------------------
PASSIVE_EFFECTS = {
    # ---- unconditional stat bonuses --------------------------------------
    "calm_mind": [
        # "+15% to all mental saving throws" — _perform_save_roll() adds
        # mental_resistance_pct on Focus saves, which are the mental ones.
        {"type": "stat_bonus", "stat": "mental_resistance_pct", "value": 15},
    ],
    "play_to_the_crowd": None,  # +2% Luck per nearby unit — needs an aura count

    # ---- resistances ------------------------------------------------------
    "aegis_of_tranquility": [
        {"type": "resistance", "damage_type": dt, "value": 20}
        for dt in ("fire", "water", "air", "earth", "space")
    ],
    "stone_body": [
        {"type": "resistance", "damage_type": "bleed", "value": 25},
        {"type": "resistance", "damage_type": "poison", "value": 25},
    ],

    # ---- conditional stat bonuses ----------------------------------------
    "patient_aim": [
        {"type": "stat_bonus", "stat": "accuracy", "value": 8,
         "conditions": ["did_not_move", "wielding_ranged"]},
    ],

    # ---- triggers ---------------------------------------------------------
    "borrowed_opening": [
        # "When an enemy's melee attack misses you, your next unarmed attack
        # this turn gains +20% damage."
        {"type": "on_trigger", "trigger": "dodge_success",
         "effect": {"type": "buff", "stat": "damage", "value": 20, "duration": 1}},
    ],
}
PASSIVE_EFFECTS = {k: v for k, v in PASSIVE_EFFECTS.items() if v is not None}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def all_perks(data):
    out = {}
    for section in ("skill_perks", "cross_perks"):
        for pid, perk in data[section].items():
            if not pid.startswith("_"):
                out[pid] = perk
    return out


def _strip_comments(text):
    """Drop GDScript comments, so a perk named only in prose is not counted.

    `soothing_presence` is the case that motivated this: its id appears in
    scripts/ exactly once, inside a doc comment in aura_system.gd that uses it
    as an EXAMPLE of a status aura name. The perk itself (a dialogue bonus) is
    unimplemented, but a plain substring scan called it hardcoded — which both
    hid it from this backlog and would have refused to wire it.

    Truncates each line at the first `#` outside a double-quoted string.
    """
    out = []
    for line in text.splitlines():
        in_string = False
        cut = len(line)
        i = 0
        while i < len(line):
            ch = line[i]
            if ch == "\\" and in_string:
                i += 2
                continue
            if ch == '"':
                in_string = not in_string
            elif ch == "#" and not in_string:
                cut = i
                break
            i += 1
        out.append(line[:cut])
    return "\n".join(out)


def hardcoded_perk_ids(perk_ids):
    """Perk ids referenced by string literal in scripts/, comments excluded.

    These are implemented by hand and must never also carry `effects`.
    """
    source = []
    for root, _, files in os.walk(SCRIPTS):
        for name in files:
            if name.endswith(".gd"):
                source.append(
                    _strip_comments(pathlib.Path(root, name).read_text(encoding="utf-8"))
                )
    blob = "\n".join(source)
    return {pid for pid in perk_ids if f'"{pid}"' in blob}


def validate(data, hardcoded):
    perks = all_perks(data)
    errors = []

    for pid, effects in PASSIVE_EFFECTS.items():
        if pid not in perks:
            errors.append(f"{pid}: no such perk")
            continue
        if pid in hardcoded:
            errors.append(
                f"{pid}: already implemented by hand in scripts/ — an effects "
                f"array here would make it fire twice"
            )
        if perks[pid]["description"].startswith("Active"):
            errors.append(f"{pid}: is an active perk, use wire_active_perks.py")

        for effect in effects:
            kind = effect.get("type", "")
            for condition in effect.get("conditions", []):
                if condition not in LIVE_CONDITIONS:
                    errors.append(f"{pid}: condition '{condition}' is never evaluated")

            if kind == "stat_bonus":
                if effect["stat"] not in DERIVED_STATS:
                    errors.append(f"{pid}: '{effect['stat']}' is not a derived stat")
                if effect.get("conditions") and effect["stat"] not in MODIFIABLE_STATS:
                    errors.append(
                        f"{pid}: conditional bonus on '{effect['stat']}', which "
                        f"CombatUnit has no getter to apply it through"
                    )
            elif kind == "stat_conversion":
                for key in ("source_stat", "target_stat"):
                    if effect[key] not in DERIVED_STATS:
                        errors.append(f"{pid}: {key} '{effect[key]}' is not a derived stat")
            elif kind == "resistance":
                if effect["damage_type"] not in RESISTANCE_TYPES:
                    errors.append(f"{pid}: unknown damage_type '{effect['damage_type']}'")
            elif kind == "on_trigger":
                if effect["trigger"] not in LIVE_TRIGGERS:
                    errors.append(
                        f"{pid}: trigger '{effect['trigger']}' is never fired by "
                        f"CombatManager"
                    )
                payload = effect.get("effect", {})
                if payload.get("type") not in LIVE_PAYLOADS:
                    errors.append(f"{pid}: payload type '{payload.get('type')}' has no handler")
                if payload.get("type") == "buff" and payload.get("stat") not in MODIFIABLE_STATS:
                    errors.append(f"{pid}: trigger buffs '{payload.get('stat')}', never read back")
            else:
                errors.append(f"{pid}: effect type '{kind}' has no consumer")

    return errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = load(PERKS)
    perks = all_perks(data)
    hardcoded = hardcoded_perk_ids(perks.keys())

    errors = validate(data, hardcoded)
    if errors:
        print("VALIDATION FAILED:", file=sys.stderr)
        for e in errors:
            print("  -", e, file=sys.stderr)
        return 1

    # Count passives against passives. This used to subtract `hardcoded &
    # set(perks)` — every perk id appearing in scripts/, actives and mantras
    # included — from the PASSIVE total, so 34 perks that were never in the
    # total were taken out of it and the description-only figure came out 27
    # low. TODO.md quoted that number for a month.
    passives = {
        pid for pid, v in perks.items()
        if not v["description"].startswith("Active") and not v.get("is_mantra")
    }
    # A perk can also be implemented without its id appearing in scripts/, by
    # declaring data the engine resolves generically. Those are implemented as
    # surely as a hand-written branch and must not be counted as unwritten.
    by_data = {
        pid for pid in passives
        if perks[pid].get("effects")
        or perks[pid].get("aura")
        or perks[pid].get("grants_movement_ability")
    }
    by_id = (hardcoded & passives) - by_data
    print(f"passive perks:            {len(passives)}")
    print(f"  hardcoded in scripts/:  {len(by_id)}")
    print(f"  implemented via data:   {len(by_data)}")
    print(f"  still description-only: {len(passives - by_id - by_data)}")

    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0

    for pid, effects in PASSIVE_EFFECTS.items():
        perks[pid]["effects"] = effects
    PERKS.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"\nwrote {PERKS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
