#!/usr/bin/env python3
"""Generate and normalise the graded ritual garb.

Every graded garment runs one consecration ladder, plain to legendary, and the
FABRIC marks where on it you stand: unmarked cloth at the first grade, cotton
through the middle, silk at the top two. A player reads the rank off the cloth.

Run:
    python3 tools/generate_ritual_garb.py            # dry run
    python3 tools/generate_ritual_garb.py --write
"""

import argparse
import json
import pathlib
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
ITEMS = ROOT / "resources" / "data" / "items.json"
TABLES = ROOT / "resources" / "data" / "equipment_tables.json"

GRADES = [("plain", 1), ("blessed", 2), ("empowered", 3),
          ("perfected", 4), ("legendary", 5)]

# The black sorcerer's line is a mantra practice, not a sorcery one: it leads
# with Black and takes Sorcery alongside. Renamed to say so.
RENAMES = {"black_sorcerer_robe": "black_mantra_robe",
           "black_sorcerer_crown": "black_mantra_hat"}

# family -> (slot, primary skill, secondary skill or None, flavour)
NEW_FAMILIES = {
    "pandita_robe": ("chest", "learning", "persuasion",
        "The scholar's robe. Debate is a kind of combat, and this is its armour."),
    "sages_robe": ("chest", "earth_magic", "white_magic",
        "Plain and heavy. The sage mends and endures in equal measure."),
    "tantric_robe": ("chest", "ritual", None,
        "Cut for the long ceremonies, where the rite runs past midnight."),
    "dreamers_robe": ("chest", "enchantment", None,
        "Loose, and strangely quiet. Worn for the practices done while asleep."),
    "chodpa_robe": ("chest", "summoning", None,
        "The chodpa's robe, worn to the charnel ground and not washed after."),
    "chodpa_eye_covering": ("head", "summoning", "black_magic",
        "A blindfold of dark cloth. What is called does not need to be seen."),
    "sorcerer_robe": ("chest", "sorcery", None,
        "Heavy brocade bearing the face of Mahakala, for the wrathful rites."),
    "sorcerer_hat": ("head", "sorcery", None,
        "The pointed hat of the wrathful rites, worn with the Mahakala robe."),
}
# The sage's robe carries two schools at once, so each is smaller.
BALANCED_PAIRS = {"sages_robe"}

BASE_VALUE = {"chest": 40, "head": 28}


def fabric_for(grade, ladder):
    return ladder[str(grade)]


def build_family(family, slot, primary, secondary, flavour, ladder):
    out = {}
    for grade_name, g in GRADES:
        item_id = f"{grade_name}_{family}"
        fabric = fabric_for(g, ladder)
        bonuses = {}
        if family in BALANCED_PAIRS:
            # Two schools, each rising at half pace — broader and shallower.
            share = (g + 1) // 2
            bonuses[primary] = {item_id: share}
            bonuses[secondary] = {item_id + "_sec": share}
        else:
            bonuses[primary] = {item_id: g}
            if secondary and g >= 2:
                bonuses[secondary] = {item_id + "_sec": g // 2}
        stats = {"armor": 1 + g // 2}
        if slot == "chest":
            stats["max_mana"] = g * 5
        else:
            stats["max_mana"] = g * 3
        # The sorcerer's line pays in raw power at the top rather than a
        # second school.
        if family in ("sorcerer_robe", "sorcerer_hat") and g >= 3:
            stats["spellpower"] = (g - 2) * 3
        out[item_id] = {
            "name": "%s %s%s" % (
                grade_name.title(),
                "" if fabric == "cloth" else fabric.title() + " ",
                family.replace("_", " ").title()),
            "type": "robe" if slot == "chest" else "hat",
            "slot": slot,
            "rarity": "common" if g <= 2 else ("rare" if g == 3 else "epic"),
            "material": fabric,
            "weight": 3 if slot == "chest" else 1,
            "value": int(BASE_VALUE[slot] * (1 + g * 0.85) ** 1.9),
            "description": flavour,
            "requirements": {"focus": 4 + g * 2},
            "stats": stats,
            "skill_bonuses": bonuses,
            "abilities": [],
        }
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    ladder = json.loads(TABLES.read_text(encoding="utf-8"))["garb_fabric_ladder"]
    items = data["items"]
    report = Counter()

    for old, new in RENAMES.items():
        for grade_name, _ in GRADES:
            old_id, new_id = f"{grade_name}_{old}", f"{grade_name}_{new}"
            if old_id in items:
                entry = items.pop(old_id)
                entry["name"] = entry["name"].replace("Black Sorcerer", "Black Mantra")
                # skill_bonuses key their source by item id; keep them honest.
                for skill, sources in list(entry.get("skill_bonuses", {}).items()):
                    entry["skill_bonuses"][skill] = {
                        k.replace(old_id, new_id): v for k, v in sources.items()}
                items[new_id] = entry
                report["renamed"] += 1

    built = {}
    for family, (slot, primary, secondary, flavour) in NEW_FAMILIES.items():
        built.update(build_family(family, slot, primary, secondary, flavour, ladder))
    for key in list(built):
        report["rebuilt" if key in items else "new"] += 1
    items.update(built)

    # Every graded garment takes its fabric from the ladder, old lines included.
    for item_id, item in items.items():
        if not isinstance(item, dict) or item.get("type") not in ("robe", "hat"):
            continue
        grade = next((g for name, g in GRADES if item_id.startswith(name + "_")), None)
        if grade is None:
            continue
        fabric = fabric_for(grade, ladder)
        if item.get("material") != fabric:
            item["material"] = fabric
            report["fabric set from ladder"] += 1

    for what, n in report.most_common():
        print(f"  {what:26s} {n}")
    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0
    ITEMS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nwrote {ITEMS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
