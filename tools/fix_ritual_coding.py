#!/usr/bin/env python3
"""Repair the elemental and implement coding on ritual implements.

Ritual implements carry two orthogonal codings that ADD rather than compete:

    METAL     -> which element the implement serves
                 copper fire, silver water, gold earth, iron air,
                 bronze and sky_iron space, conch the pacifying rites
    IMPLEMENT -> which practice it is an instrument of
                 dorje focus, drilbu awareness, khatvanga enchantment,
                 damaru summoning, phurba sorcery

So a copper phurba boosts fire magic AND sorcery, which between them are
exactly Fireball's two schools. A silver phurba boosts water and sorcery —
the traditional instrument of intense healing, purification through a wrathful
focus. Neither axis cancels the other; that is the point of the system.

The audit found the metal axis fully correct on all 125 implements that carry
it, and the implement axis correct on 30 of 150 — only the phurba. The damaru
was granting enchantment, which belongs to the khatvanga; the dorje, drilbu and
khatvanga granted nothing at all. And the `element` field followed the
implement rather than the metal, which is why every metal showed the same
15/5/5 spread across space/air/fire and no implement anywhere was water.

Consecration grade sets the magnitude on both axes, 1 through 5, which the
phurba line already demonstrates.

Run:
    python3 tools/fix_ritual_coding.py            # dry run
    python3 tools/fix_ritual_coding.py --write
"""

import argparse
import json
import pathlib
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
ITEMS = ROOT / "resources" / "data" / "items.json"

# Longest first so "sky_iron" is not read as "iron".
# `bone` and `conch` are not metals, but they code the same way: the
# material an implement is made of says which element it serves.
METALS = ["sky_iron", "copper", "silver", "gold", "iron", "conch",
          "bronze", "bone"]
IMPLEMENTS = ["khatvanga", "kangling", "drilbu", "damaru", "phurba", "dorje"]

METAL_ELEMENT = {
    "copper": "fire", "silver": "water", "gold": "earth", "iron": "air",
    "bronze": "space", "sky_iron": "space",
    # Conch is not a metal and codes for a rite rather than an element:
    # the pacifying activity, which is traditionally white and watery. Its
    # white_magic bonus was already correct and is left alone.
    "conch": "water",
    # Charnel ground practice. Earth, and the black magic school.
    "bone": "earth",
}

# Where each implement's bonus goes. Focus and Awareness are attributes, which
# items grant through `stats`; the other three are skills.
IMPLEMENT_SKILL = {
    "khatvanga": "enchantment", "damaru": "summoning", "phurba": "sorcery",
    # The chod trumpet calls the rite; the damaru calls what answers it.
    "kangling": "ritual",
}
IMPLEMENT_ATTRIBUTE = {"dorje": "focus", "drilbu": "awareness"}

# Consecration grade -> magnitude, read off the phurba line, which was right.
GRADE_MAGNITUDE = {"plain": 1, "blessed": 2, "empowered": 3,
                   "perfected": 4, "legendary": 5}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    changes = Counter()

    for item_id, item in data["items"].items():
        if not isinstance(item, dict) or item.get("type") != "focus":
            continue
        metal = next((m for m in METALS if m in item_id), None)
        implement = next((i for i in IMPLEMENTS if i in item_id), None)
        grade = next((g for g in GRADE_MAGNITUDE if item_id.startswith(g + "_")), None)
        if not (metal and implement and grade):
            continue
        magnitude = GRADE_MAGNITUDE[grade]

        # The element follows the metal. It followed the implement, which is
        # why a silver phurba read as fire.
        wanted = METAL_ELEMENT[metal]
        if item.get("element") != wanted:
            item["element"] = wanted
            changes[f"element -> {wanted}"] += 1

        # My own damage, from the material pass: a gilt implement had its metal
        # moved into `gilding` and replaced with bronze, which erased the
        # elemental coding the metal carries here. The metal IS the point.
        if "gilding" in item:
            item["material"] = item.pop("gilding")
            changes["restored metal from gilding"] += 1

        skill = IMPLEMENT_SKILL.get(implement)
        if skill:
            bonuses = item.setdefault("skill_bonuses", {})
            # The damaru was granting the khatvanga's enchantment.
            for wrong in set(IMPLEMENT_SKILL.values()) - {skill}:
                if wrong in bonuses and any(item_id in src for src in bonuses[wrong]):
                    del bonuses[wrong]
                    changes[f"{implement}: dropped {wrong}"] += 1
            if skill not in bonuses:
                bonuses[skill] = {item_id: magnitude}
                changes[f"{implement} -> {skill}"] += 1

        attribute = IMPLEMENT_ATTRIBUTE.get(implement)
        if attribute:
            stats = item.setdefault("stats", {})
            if stats.get(attribute, 0) != magnitude:
                stats[attribute] = magnitude
                changes[f"{implement} -> {attribute}"] += 1

    for what, n in changes.most_common():
        print(f"  {what:38s} {n}")
    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0
    ITEMS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nwrote {ITEMS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
