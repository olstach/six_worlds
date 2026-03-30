#!/usr/bin/env python3
"""
Apply targeted perk level shifts to PERKS.md.
Each entry: (perk_name, old_skill_req, old_level, new_level)
"""
import re

SHIFTS = [
    # 3 → 2
    ("Lunge",                   "Swords",      3, 2),
    ("Whirling Advance",        "Martial Arts", 3, 2),
    ("Two Hands No Regret",     "Axes",        3, 2),
    ("Rattle the Cage",         "Unarmed",     3, 2),
    ("Hot Blooded",             "Fire",        3, 2),
    ("Grounded",                "Might",       3, 2),
    ("Chain of Command",        "Leadership",  3, 2),
    ("Symbolic Weight",         "Ritual",      3, 2),
    # 5 → 4
    ("Blood in the Wind",       "Daggers",     5, 4),
    ("The Voice Carries the Mind", "Martial Arts", 5, 4),
    ("Burning Blood",           "Unarmed",     5, 4),
    ("Feed the Fire",           "Fire",        5, 4),
    ("Hit Back Harder",         "Might",       5, 4),
    ("Follow Through",          "Maces",       5, 4),
    # 7 → 6
    ("Kill Zone",               "Ranged",      7, 6),
    ("Pain Is Just Information","Might",       7, 6),
    ("Crumbling Avalanche",     "Earth",       7, 6),
    ("Elemental Infusion",      "Summoning",   7, 6),
    # 9 → 8
    ("Red Harvest",             "Axes",        9, 8),
    ("One Inch",                "Unarmed",     9, 8),
    ("Mountain Falls",          "Maces",       9, 8),
    ("Still Standing",          "Might",       9, 8),
    ("Fortune Favors",          "Thievery",    9, 8),
]

def main():
    path = "/home/gnoll/Documents/1_Projects/Six_Worlds_3/PERKS.md"
    with open(path) as f:
        lines = f.readlines()

    # Build lookup: perk_name → (old_req_pattern, new_req_string)
    shift_map = {}
    for name, skill, old_lv, new_lv in SHIFTS:
        shift_map[name] = (skill, old_lv, new_lv)

    result = []
    current_perk = None
    changes = 0

    for line in lines:
        m = re.match(r'^\*\*(.+?)\*\*\s*$', line)
        if m:
            current_perk = m.group(1).strip()
            result.append(line)
            continue

        req_m = re.match(r'^(_Requires: .+)_\s*$', line)
        if req_m and current_perk and current_perk in shift_map:
            skill, old_lv, new_lv = shift_map[current_perk]
            # Replace exactly "Skill old_lv" with "Skill new_lv" in this line
            pattern = rf'\b{re.escape(skill)} {old_lv}(?!\d)'
            new_line, n = re.subn(pattern, f"{skill} {new_lv}", line)
            if n:
                changes += 1
                result.append(new_line)
                current_perk = None
                continue

        if line.strip() and not line.startswith("_"):
            current_perk = None
        result.append(line)

    with open(path, "w") as f:
        f.writelines(result)

    print(f"Done. {changes} perk(s) shifted.")
    missing = [n for n, _ in [(s[0], s) for s in SHIFTS] if n not in {s[0] for s in SHIFTS[:changes]}]

if __name__ == "__main__":
    main()
