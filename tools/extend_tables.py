#!/usr/bin/env python3
"""
Extend PERKS.md skill tables from level 5 to level 10, adding rows 6-10
and an 11-15 item bonus note row, for all tables not yet extended.
"""

import re

# For each table, identified by its header line, define:
# - rows: list of (level_str, col1, col2[, col3]) for levels 6-10
# - note: the 11-15 row content as a list matching column count
EXTENSIONS = {
    "| Level | Attack | Damage |": {
        "rows": [
            ("6", "+90%", "+90%"),
            ("7", "+100%", "+100%"),
            ("8", "+110%", "+110%"),
            ("9", "+120%", "+120%"),
            ("10", "+130%", "+130%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+130% (item bonus only)"),
    },
    "| Level | Attack | Crit Chance |": {
        "rows": [
            ("6", "+90%", "+55%"),
            ("7", "+100%", "+60%"),
            ("8", "+110%", "+65%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Spellpower | Mana Cost |": {
        "rows": [
            ("6", "+90%", "-85%"),
            ("7", "+100%", "-90%"),
            ("8", "+110%", "-95%"),
            ("9", "+120%", "-100%"),
            ("10", "+130%", "-100%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "-100% (item bonus only)"),
    },
    "| Level | Charm Effectiveness | Trading Price |": {
        "rows": [
            ("6", "+90%", "+30%"),
            ("7", "+100%", "+35%"),
            ("8", "+110%", "+40%"),
            ("9", "+120%", "+45%"),
            ("10", "+130%", "+50%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+50% (item bonus only)"),
    },
    "| Level | Mental Resistance | Magic Damage Resistance |": {
        "rows": [
            ("6", "+85%", "+55%"),
            ("7", "+95%", "+60%"),
            ("8", "+105%", "+65%"),
            ("9", "+115%", "+70%"),
            ("10", "+125%", "+75%"),
        ],
        "note": ("11–15", "+125% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Attack | Crit Chance |": {  # Ranged (same header as Martial Arts — handled by position)
        "rows": [
            ("6", "+90%", "+18%"),
            ("7", "+100%", "+20%"),
            ("8", "+110%", "+22%"),
            ("9", "+120%", "+25%"),
            ("10", "+130%", "+27%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+27% (item bonus only)"),
    },
    "| Level | Damage | Crit Chance |": {
        "rows": [
            ("6", "+90%", "+18%"),
            ("7", "+100%", "+20%"),
            ("8", "+110%", "+22%"),
            ("9", "+120%", "+25%"),
            ("10", "+130%", "+27%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+27% (item bonus only)"),
    },
    "| Level | Spellpower | Status Effect Chance |": {
        "rows": [
            ("6", "+90%", "+55%"),
            ("7", "+100%", "+60%"),
            ("8", "+110%", "+65%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Dodge | Crit Chance |": {
        "rows": [
            ("6", "+30%", "+35%"),
            ("7", "+35%", "+40%"),
            ("8", "+40%", "+45%"),
            ("9", "+45%", "+50%"),
            ("10", "+50%", "+55%"),
        ],
        "note": ("11–15", "+50% (item bonus only)", "+55% (item bonus only)"),
    },
    "| Level | Damage | Armor Penetration |": {
        "rows": [
            ("6", "+90%", "+52%"),
            ("7", "+100%", "+58%"),
            ("8", "+110%", "+64%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Damage | Dodge |": {
        "rows": [
            ("6", "+90%", "+52%"),
            ("7", "+100%", "+58%"),
            ("8", "+110%", "+64%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Spellpower | Burning Damage |": {
        "rows": [
            ("6", "+90%", "+90%"),
            ("7", "+100%", "+100%"),
            ("8", "+110%", "+110%"),
            ("9", "+120%", "+120%"),
            ("10", "+130%", "+130%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+130% (item bonus only)"),
    },
    "| Level | Spellpower | Initiative |": {
        "rows": [
            ("6", "+90%", "+52%"),
            ("7", "+100%", "+58%"),
            ("8", "+110%", "+64%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Strength Weapon Damage | Stamina |": {
        "rows": [
            ("6", "+90%", "+52%"),
            ("7", "+100%", "+58%"),
            ("8", "+110%", "+64%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Max Companions | Morale Effects |": {
        "rows": [
            ("6", "+5 (max 8, cap)", "+60%"),
            ("7", "+5 (max 8, cap)", "+70%"),
            ("8", "+5 (max 8, cap)", "+80%"),
            ("9", "+5 (max 8, cap)", "+90%"),
            ("10", "+5 (max 8, cap)", "+100%"),
        ],
        "note": ("11–15", "+5 (item bonus only)", "+100% (item bonus only)"),
    },
    "| Level | Morale Effects | Social Roll Success |": {
        "rows": [
            ("6", "+55%", "+55%"),
            ("7", "+60%", "+60%"),
            ("8", "+65%", "+65%"),
            ("9", "+70%", "+70%"),
            ("10", "+75%", "+75%"),
        ],
        "note": ("11–15", "+75% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Spellpower | Effect Duration |": {
        "rows": [
            ("6", "+90%", "+52%"),
            ("7", "+100%", "+58%"),
            ("8", "+110%", "+64%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Dodge | Movement Speed |": {
        "rows": [
            ("6", "+30%", "+45%"),
            ("7", "+35%", "+50%"),
            ("8", "+40%", "+55%"),
            ("9", "+45%", "+60%"),
            ("10", "+50%", "+65%"),
        ],
        "note": ("11–15", "+50% (item bonus only)", "+65% (item bonus only)"),
    },
    "| Level | Healing Effectiveness (party) | Poison/Disease Resistance (party) |": {
        "rows": [
            ("6", "+90%", "+55%"),
            ("7", "+100%", "+60%"),
            ("8", "+110%", "+65%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Consumable Power | Crafting Yield |": {
        "rows": [
            ("6", "+90%", "+55%"),
            ("7", "+100%", "+60%"),
            ("8", "+110%", "+65%"),
            ("9", "+120%", "+70%"),
            ("10", "+130%", "+75%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+75% (item bonus only)"),
    },
    "| Level | Loot Quality | Trap Detection |": {
        "rows": [
            ("6", "+52%", "+65%"),
            ("7", "+58%", "+70%"),
            ("8", "+64%", "+75%"),
            ("9", "+70%", "+80%"),
            ("10", "+75%", "+85%"),
        ],
        "note": ("11–15", "+75% (item bonus only)", "+85% (item bonus only)"),
    },
    "| Level | Damage | Stun Chance |": {
        "rows": [
            ("6", "+90%", "+28%"),
            ("7", "+100%", "+31%"),
            ("8", "+110%", "+34%"),
            ("9", "+120%", "+37%"),
            ("10", "+130%", "+40%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+40% (item bonus only)"),
    },
    "| Level | Armor | Max HP |": {
        "rows": [
            ("6", "+90%", "+28%"),
            ("7", "+100%", "+31%"),
            ("8", "+110%", "+34%"),
            ("9", "+120%", "+37%"),
            ("10", "+130%", "+40%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+40% (item bonus only)"),
    },
    "| Level | Spellpower | Summon HP |": {
        "rows": [
            ("6", "+90%", "+65%"),
            ("7", "+100%", "+70%"),
            ("8", "+110%", "+75%"),
            ("9", "+120%", "+80%"),
            ("10", "+130%", "+85%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+85% (item bonus only)"),
    },
    "| Level | Supply Duration (party) | Travel Speed (party) |": {
        "rows": [
            ("6", "+65%", "+40%"),
            ("7", "+70%", "+45%"),
            ("8", "+75%", "+50%"),
            ("9", "+80%", "+55%"),
            ("10", "+85%", "+60%"),
        ],
        "note": ("11–15", "+85% (item bonus only)", "+60% (item bonus only)"),
    },
    "| Level | Buy Discount | Sell Markup |": {
        "rows": [
            ("6", "+40%", "+50%"),
            ("7", "+45%", "+55%"),
            ("8", "+50%", "+60%"),
            ("9", "+55%", "+65%"),
            ("10", "+60%", "+70%"),
        ],
        "note": ("11–15", "+60% (item bonus only)", "+70% (item bonus only)"),
    },
    "| Level | Crafting Quality | Repair Efficiency |": {
        "rows": [
            ("6", "+90%", "+65%"),
            ("7", "+100%", "+70%"),
            ("8", "+110%", "+75%"),
            ("9", "+120%", "+80%"),
            ("10", "+130%", "+85%"),
        ],
        "note": ("11–15", "+130% (item bonus only)", "+85% (item bonus only)"),
    },
}


def make_row(cells):
    return "| " + " | ".join(cells) + " |"


def extend_table(content: str, header: str, ext: dict) -> str:
    """Find all instances of the given table header that only have 5 rows, and extend them."""
    lines = content.split("\n")
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == header.strip():
            # Found a table header. Scan ahead to find the table body.
            result.append(line)
            i += 1
            # separator row
            if i < len(lines):
                result.append(lines[i])
                i += 1
            # data rows
            table_rows = []
            while i < len(lines) and lines[i].startswith("|") and not lines[i].strip() == header.strip():
                table_rows.append(lines[i])
                i += 1
            # Check: already extended?
            level_nums = []
            for r in table_rows:
                m = re.match(r'\| (\d+)', r)
                if m:
                    level_nums.append(int(m.group(1)))
            max_level = max(level_nums) if level_nums else 0
            if max_level >= 6:
                # Already extended, leave as-is
                result.extend(table_rows)
            else:
                # Add rows 6-10 and note
                result.extend(table_rows)
                for row_data in ext["rows"]:
                    result.append(make_row(list(row_data)))
                result.append(make_row(list(ext["note"])))
        else:
            result.append(line)
            i += 1
    return "\n".join(result)


def main():
    path = "/home/gnoll/Documents/1_Projects/Six_Worlds_3/PERKS.md"
    with open(path, "r") as f:
        content = f.read()

    original = content

    # Process each unique header. Some headers appear multiple times (e.g. "| Level | Spellpower | Mana Cost |")
    # The extend_table function will extend ALL instances that aren't already extended.
    for header, ext in EXTENSIONS.items():
        content = extend_table(content, header, ext)

    if content == original:
        print("No changes made (all tables may already be extended, or headers not found).")
    else:
        with open(path, "w") as f:
            f.write(content)
        # Count how many tables were extended
        added = content.count("| 6 |") - original.count("| 6 |")
        print(f"Done. Added level 6-10 rows to {added} table(s).")


if __name__ == "__main__":
    main()
