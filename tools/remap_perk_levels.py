#!/usr/bin/env python3
"""
Remap PERKS.md skill level requirements from the old 1-5 scale to the new 1-10 scale.

Old → New:
  1 → 1  (unchanged)
  2 → 3
  3 → 5
  4 → 7
  5 → 9

Exceptions: specific named perks are promoted to level 10 instead of 9.
"""

import re

# These perk names get promoted to level 10 (instead of the standard 5→9 mapping).
# Keys are the perk name as it appears in PERKS.md (without ** markers).
LEVEL_10_PERKS = {
    "Final Cut",              # Swords: ignore 50% armor/resist, refund on kill
    "Heavenly Counterflow",   # Martial Arts: auto-dodge + reposition + counterattack
    "Breath Easy",            # White: 1-turn party immunity
    "Soul Feast",             # Black: life drain at scale
    "Conduit of Vayu",        # Air mantra: party-wide passive aura
    "Conduit of Rudra",       # Air mantra: party-wide extra Air damage + stun
    "Trade Empire",           # Trade: passive income (system capstone)
    "Legendary Artisan",      # Crafting: once-per-rest legendary item
}

LEVEL_MAP = {1: 1, 2: 3, 3: 5, 4: 7, 5: 9}


def remap_level(n: int, is_level_10: bool) -> int:
    if is_level_10 and n == 5:
        return 10
    return LEVEL_MAP.get(n, n)  # levels 6+ pass through unchanged (future-proofing)


def process_file(path: str) -> None:
    with open(path, "r") as f:
        lines = f.readlines()

    result = []
    current_perk_name = None
    changes = 0

    for line in lines:
        # Track perk name (** bold line followed by _Requires_)
        name_match = re.match(r'^\*\*(.+?)\*\*\s*$', line)
        if name_match:
            current_perk_name = name_match.group(1).strip()
            result.append(line)
            continue

        # Process _Requires: ... _ lines
        req_match = re.match(r'^(_Requires: .+_)\s*$', line)
        if req_match:
            is_l10 = current_perk_name in LEVEL_10_PERKS

            def replace_level(m):
                skill = m.group(1)
                n = int(m.group(2))
                new_n = remap_level(n, is_l10)
                return f"{skill} {new_n}"

            new_line = re.sub(r'(\b[A-Za-z_]+\b) (\d+)', replace_level, line)
            if new_line != line:
                changes += 1
            result.append(new_line)
            current_perk_name = None  # reset after requirement line
            continue

        # Any other line resets the perk name tracker
        if line.strip() and not line.startswith("_"):
            current_perk_name = None

        result.append(line)

    with open(path, "w") as f:
        f.writelines(result)

    print(f"Done. {changes} requirement line(s) updated.")


if __name__ == "__main__":
    process_file("/home/gnoll/Documents/1_Projects/Six_Worlds_3/PERKS.md")
