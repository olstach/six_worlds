#!/usr/bin/env python3
"""Generate the mala and melong implement families.

Both follow the ritual coding already in equipment_tables.json: the material
says which element or school the implement serves, the implement says which
practice it is an instrument of.

MALA — the recitation rosary, instrument of Yoga. Unlike the metal implements
it does not run a consecration ladder: the material IS the grade, because that
is how malas actually work. Everyone has one and everyone knows what everyone
else's is made of. Two materials per school, the second rarer and stronger.

MELONG — the divination mirror, hung at the breast. Protection rather than
sight: magic resistance, and at higher consecrations a chance to turn a spell
back on whoever cast it, through the Magic_Mirror status that cast_spell
already honours. Uses the same metals as the dorje and drilbu.

Run:
    python3 tools/generate_ritual_items.py            # dry run
    python3 tools/generate_ritual_items.py --write
"""

import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ITEMS = ROOT / "resources" / "data" / "items.json"

# Olaf's attributions. Second of each pair is the rarer, stronger stone.
# Two changes from the first draft, both to stop a stone contradicting the
# material table: diamond IS vajra, which is space-coded everywhere else in the
# game, so it moves to space and star sapphire — blue, and deep — takes water.
MALA_MATERIALS = {
    "earth":       [("citrine", 1), ("topaz", 2)],
    "water":       [("turquoise", 1), ("star_sapphire", 2)],
    "air":         [("sandalwood", 1), ("emerald", 2)],
    "fire":        [("coral", 1), ("ruby", 2)],
    "space":       [("crystal", 1), ("diamond", 2)],
    "white":       [("moonstone", 1), ("conch_bead", 2)],
    "black":       [("bone_bead", 1), ("devils_bone", 2)],
    "sorcery":     [("smoke_crystal", 1), ("agate", 2)],
    "enchantment": [("rosewood", 1), ("opal", 2)],
    "summoning":   [("amethyst", 1), ("mirror_bead", 2)],
}
# Which school a mala's material feeds. The five elements take their magic
# school; the other five are schools already.
SCHOOL_OF = {
    "earth": "earth_magic", "water": "water_magic", "air": "air_magic",
    "fire": "fire_magic", "space": "space_magic", "white": "white_magic",
    "black": "black_magic", "sorcery": "sorcery",
    "enchantment": "enchantment", "summoning": "summoning",
}
# The element a mala sits in, for the elemental affinity display. The five
# non-elemental schools borrow the element their practice sits closest to.
ELEMENT_OF = {
    "earth": "earth", "water": "water", "air": "air", "fire": "fire",
    "space": "space", "white": "water", "black": "earth",
    "sorcery": "fire", "enchantment": "water", "summoning": "space",
}
PRETTY = {
    "star_sapphire": "Star Sapphire", "smoke_crystal": "Smoke Crystal",
    "conch_bead": "Conch", "bone_bead": "Bone", "devils_bone": "Devil's Bone",
    "mirror_bead": "Mirror Bead",
}

MELONG_METALS = ["bronze", "copper", "silver", "gold", "iron", "sky_iron", "conch", "bone"]
CONSECRATIONS = [("plain", 1), ("blessed", 2), ("empowered", 3),
                 ("perfected", 4), ("legendary", 5)]


def pretty(name):
    return PRETTY.get(name, name.replace("_", " ").title())


def build_malas():
    out = {}
    for school, materials in MALA_MATERIALS.items():
        for material, grade in materials:
            item_id = f"{material}_mala"
            out[item_id] = {
                "name": f"{pretty(material)} Mala",
                "weapon_class": "Prayer beads",
                "type": "focus",
                "slot": "weapon_off",
                "two_handed": False,
                "rarity": "common" if grade == 1 else "rare",
                "element": ELEMENT_OF[school],
                "material": material,
                "weight": 0.5,
                "value": 45 if grade == 1 else 260,
                "description": (
                    "A hundred and eight beads of %s, worn smooth at the "
                    "thumb. Counts the recitation so the mind need not."
                    % pretty(material).lower()),
                "requirements": {"focus": 6 + grade * 2},
                "stats": {"spellpower": 2 + grade * 2},
                # Yoga from the implement, the school from the material — the
                # same two axes every ritual implement runs on.
                "skill_bonuses": {
                    "yoga": {item_id: grade},
                    SCHOOL_OF[school]: {item_id + "_mat": grade},
                },
                "abilities": [],
            }
    return out


def build_melongs():
    out = {}
    for metal in MELONG_METALS:
        for grade_name, magnitude in CONSECRATIONS:
            item_id = f"{grade_name}_{metal}_melong"
            item = {
                "name": f"{grade_name.title()} {pretty(metal)} Melong",
                "weapon_class": "Divination mirror",
                "type": "focus",
                "slot": "weapon_off",
                "two_handed": False,
                "rarity": "common" if magnitude <= 2 else
                          ("rare" if magnitude == 3 else "epic"),
                "material": metal,
                "weight": 1.0,
                "value": int(70 * (1 + magnitude * 0.9) ** 1.9),
                "description": (
                    "A disc of polished %s hung at the breast. It shows what "
                    "approaches, and turns some of it away." % pretty(metal).lower()),
                "requirements": {"focus": 6 + magnitude * 2},
                # Protection, not sight: the melong's payout is resistance.
                "stats": {"spellpower": magnitude, "magic_resistance_pct": magnitude * 4},
                "skill_bonuses": {},
                "abilities": [],
            }
            # At the higher consecrations it turns spells back on their caster,
            # through the status cast_spell already checks.
            if magnitude >= 3:
                item["grants_status"] = "Magic_Mirror"
            out[item_id] = item
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    data = json.loads(ITEMS.read_text(encoding="utf-8"))
    malas, melongs = build_malas(), build_melongs()
    clash = (set(malas) | set(melongs)) & set(data["items"])
    if clash:
        print("ERROR: ids already exist:", sorted(clash)[:5], file=sys.stderr)
        return 1

    print(f"malas:   {len(malas)}  ({len(MALA_MATERIALS)} schools x 2 materials)")
    print(f"melongs: {len(melongs)} ({len(MELONG_METALS)} metals x {len(CONSECRATIONS)} consecrations)")
    print(f"\nsample: {json.dumps(malas['turquoise_mala'], ensure_ascii=False)[:200]}")
    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0
    data["items"].update(malas)
    data["items"].update(melongs)
    ITEMS.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nwrote {len(malas) + len(melongs)} items to {ITEMS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
