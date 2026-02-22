#!/usr/bin/env python3
"""
remap_spell_levels.py - Remap spells.json "level" field for 0-10 skill scale.

Old level → New required skill level:
  1 → 1
  2 → 3
  3 → 5
  4 → 7
  5 → 9
"""

import json
from pathlib import Path

ROOT = Path(__file__).parent.parent
SPELLS_PATH = ROOT / "resources/data/spells.json"

LEVEL_MAP = {1: 1, 2: 3, 3: 5, 4: 7, 5: 9}


def main():
    print(f"Loading {SPELLS_PATH}...")
    with open(SPELLS_PATH) as f:
        data = json.load(f)

    spells = data.get("spells", {})
    print(f"Found {len(spells)} spells")

    counts = {}
    for spell_id, spell in spells.items():
        old_level = spell.get("level")
        if old_level is not None:
            new_level = LEVEL_MAP.get(int(old_level), int(old_level))
            spell["level"] = new_level
            counts[new_level] = counts.get(new_level, 0) + 1

    print(f"Level distribution after remap: {dict(sorted(counts.items()))}")

    print(f"Saving to {SPELLS_PATH}...")
    with open(SPELLS_PATH, "w") as f:
        json.dump(data, f, indent=2)
    print("Done!")


if __name__ == "__main__":
    main()
