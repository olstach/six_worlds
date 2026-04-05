#!/usr/bin/env python3
"""Parse PERKS.md into perks.json for the Six Worlds game engine."""

import json
import re
import sys
from pathlib import Path

# Map abbreviated requirement names to skill IDs
SKILL_NAME_MAP = {
    "Swords": "swords",
    "Martial Arts": "martial_arts",
    "Space": "space_magic",
    "Space Magic": "space_magic",
    "White": "white_magic",
    "White Magic": "white_magic",
    "Black": "black_magic",
    "Black Magic": "black_magic",
    "Persuasion": "persuasion",
    "Yoga": "yoga",
    "Ranged": "ranged",
    "Daggers": "daggers",
    "Air": "air_magic",
    "Air Magic": "air_magic",
    "Ritual": "ritual",
    "Learning": "learning",
    "Comedy": "comedy",
    "Guile": "guile",
    "Axes": "axes",
    "Unarmed": "unarmed",
    "Fire": "fire_magic",
    "Fire Magic": "fire_magic",
    "Sorcery": "sorcery",
    "Might": "might",
    "Leadership": "leadership",
    "Performance": "performance",
    "Spears": "spears",
    "Water": "water_magic",
    "Water Magic": "water_magic",
    "Enchantment": "enchantment",
    "Grace": "grace",
    "Medicine": "medicine",
    "Alchemy": "alchemy",
    "Thievery": "thievery",
    "Maces": "maces",
    "Armor": "armor",
    "Earth": "earth_magic",
    "Earth Magic": "earth_magic",
    "Summoning": "summoning",
    "Logistics": "logistics",
    "Trade": "trade",
    "Crafting": "crafting",
}

# Map section headers to skill IDs
SECTION_SKILL_MAP = {
    "Swords": "swords",
    "Martial Arts": "martial_arts",
    "Space Magic": "space_magic",
    "White Magic": "white_magic",
    "Black Magic": "black_magic",
    "Persuasion": "persuasion",
    "Yoga": "yoga",
    "Ranged": "ranged",
    "Daggers": "daggers",
    "Air Magic": "air_magic",
    "Ritual": "ritual",
    "Learning": "learning",
    "Comedy": "comedy",
    "Guile": "guile",
    "Axes": "axes",
    "Unarmed": "unarmed",
    "Fire Magic": "fire_magic",
    "Sorcery": "sorcery",
    "Might": "might",
    "Leadership": "leadership",
    "Performance": "performance",
    "Spears": "spears",
    "Water Magic": "water_magic",
    "Enchantment": "enchantment",
    "Grace": "grace",
    "Medicine": "medicine",
    "Alchemy": "alchemy",
    "Thievery": "thievery",
    "Maces": "maces",
    "Armor": "armor",
    "Earth Magic": "earth_magic",
    "Summoning": "summoning",
    "Logistics": "logistics",
    "Trade": "trade",
    "Crafting": "crafting",
}


def name_to_id(name):
    """Convert a perk name to a snake_case ID."""
    # Remove special characters, keep alphanumeric and spaces
    clean = re.sub(r"[^a-zA-Z0-9\s]", "", name)
    # Replace multiple spaces with single space, strip, lowercase
    clean = re.sub(r"\s+", "_", clean.strip()).lower()
    return clean


def parse_base_bonus_table(lines, start_idx):
    """Parse a markdown table of base bonuses. Returns (stats, per_level, end_idx)."""
    # Header line: | Level | Stat1 | Stat2 |
    header_line = lines[start_idx].strip()
    headers = [h.strip() for h in header_line.split("|") if h.strip()]
    # Skip "Level", get stat names
    stat_names = [h.lower().replace(" ", "_") for h in headers[1:]]

    # Skip separator line (|---|---|---|)
    idx = start_idx + 2

    per_level = {}
    while idx < len(lines):
        line = lines[idx].strip()
        if not line.startswith("|") or line.startswith("|--"):
            break
        cells = [c.strip() for c in line.split("|") if c.strip()]
        if len(cells) < 2:
            break
        level = cells[0]
        values = {}
        for i, stat in enumerate(stat_names):
            if i + 1 < len(cells):
                val = cells[i + 1]
                # Parse percentage values like "+5%", "-75%"
                match = re.match(r"([+-]?\d+(?:\.\d+)?)", val.replace("%", ""))
                if match:
                    values[stat] = float(match.group(1))
            else:
                values[stat] = 0
        # Expand range rows like "11–15" into individual level entries
        range_match = re.match(r"(\d+)\s*[–\-]\s*(\d+)", level)
        if range_match:
            start = int(range_match.group(1))
            end = int(range_match.group(2))
            for lvl in range(start, end + 1):
                per_level[str(lvl)] = values
        else:
            per_level[level] = values
        idx += 1

    return stat_names, per_level, idx


def parse_requirements(req_text, current_skill):
    """Parse a requirement string into structured data.

    Returns dict with:
      - skill_requirements: {skill_id: level}
      - perk_requirements: [perk_id] or [[perk_id, perk_id]] for OR
      - special: string or None for complex requirements
    """
    result = {
        "skill_requirements": {},
        "perk_requirements": [],
        "special": None,
    }

    # Handle affinity requirements: "Space affinity 25+"
    affinity_match = re.match(r"(\w+) affinity (\d+)\+", req_text)
    if affinity_match:
        element = affinity_match.group(1).lower()
        level = int(affinity_match.group(2))
        result["special"] = f"{element}_affinity_{level}"
        return result

    # Handle "Any X weapon skills at Y" or "Any X elemental magics at Y"
    any_match = re.match(r"Any (\d+)(?: different)? (\w[\w\s]*?) at (\d+)", req_text)
    if any_match:
        count = int(any_match.group(1))
        category = any_match.group(2).strip()
        level = int(any_match.group(3))
        result["special"] = f"any_{count}_{name_to_id(category)}_at_{level}"
        # There might be more after a comma
        remaining = req_text[any_match.end():]
        if remaining.strip().startswith(","):
            remaining = remaining.strip()[1:].strip()
            # Parse remaining parts
            _parse_remaining_reqs(remaining, result, current_skill)
        return result

    # Split on commas, but be careful with "or" conditions
    parts = [p.strip() for p in req_text.split(",")]

    for part in parts:
        part = part.strip()
        if not part:
            continue

        # Check for "Any weapon skill N" or "any magic school N"
        any_single = re.match(r"[Aa]ny (\w[\w\s]*?) (\d+)", part)
        if any_single:
            category = any_single.group(1).strip()
            level = int(any_single.group(2))
            result["special"] = f"any_{name_to_id(category)}_at_{level}"
            continue

        # Check for "Skill Level" pattern
        skill_match = re.match(r"(.+?)\s+(\d+)$", part)
        if skill_match:
            skill_name = skill_match.group(1).strip()
            level = int(skill_match.group(2))
            if skill_name in SKILL_NAME_MAP:
                result["skill_requirements"][SKILL_NAME_MAP[skill_name]] = level
                continue

        # Check for "or" patterns: could be "Skill Level or Skill Level" OR "Perk or Perk"
        if " or " in part:
            or_parts = [p.strip() for p in part.split(" or ")]
            # Check if ALL parts match "Skill Level" pattern
            all_skills = True
            or_skill_reqs = {}
            for op in or_parts:
                sm = re.match(r"(.+?)\s+(\d+)$", op)
                if sm and sm.group(1).strip() in SKILL_NAME_MAP:
                    or_skill_reqs[SKILL_NAME_MAP[sm.group(1).strip()]] = int(sm.group(2))
                else:
                    all_skills = False
                    break
            if all_skills:
                # Store as OR skill requirement (any one of these skills at level)
                result["or_skill_requirements"] = or_skill_reqs
            else:
                or_perks = [name_to_id(p.strip()) for p in or_parts]
                result["perk_requirements"].append(or_perks)
            continue

        # Check for "Skill Level, PerkName" where PerkName doesn't have a number
        # At this point it's likely a perk prerequisite name
        if not re.search(r"\d", part):
            result["perk_requirements"].append(name_to_id(part))

    return result


def _parse_remaining_reqs(text, result, current_skill):
    """Parse remaining requirement text after the main part."""
    parts = [p.strip() for p in text.split(",")]
    for part in parts:
        part = part.strip()
        if not part:
            continue
        skill_match = re.match(r"(.+?)\s+(\d+)$", part)
        if skill_match:
            skill_name = skill_match.group(1).strip()
            level = int(skill_match.group(2))
            if skill_name in SKILL_NAME_MAP:
                result["skill_requirements"][SKILL_NAME_MAP[skill_name]] = level
                continue
        if " or " in part:
            or_perks = [name_to_id(p.strip()) for p in part.split(" or ")]
            result["perk_requirements"].append(or_perks)
        elif not re.search(r"\d", part):
            result["perk_requirements"].append(name_to_id(part))


def parse_perks_md(filepath):
    """Parse the PERKS.md file into structured data."""
    with open(filepath, "r") as f:
        lines = f.readlines()

    base_bonuses = {}
    skill_perks = {}
    cross_perks = {}

    current_skill = None
    current_element = None
    in_cross_section = False
    in_mantra_section = False
    cross_category = None

    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        # Element headers: "# Space 🟣" or "# Cross-Skill Perks 🔗"
        if line.startswith("# ") and not line.startswith("## ") and not line.startswith("### "):
            header_text = re.sub(r"\s*[^\w\s].*$", "", line[2:]).strip()
            if "Cross" in line:
                in_cross_section = True
                current_skill = None
            else:
                current_element = header_text.lower()
                in_cross_section = False
            i += 1
            continue

        # Cross-section category headers: "## Martial Combinations ⚔️"
        if in_cross_section and line.startswith("## "):
            category_text = re.sub(r"\s*[^\w\s/].*$", "", line[3:]).strip()
            cross_category = name_to_id(category_text)
            i += 1
            continue

        # Skill section headers: "## Swords ⚔️"
        if line.startswith("## ") and not in_cross_section:
            # Extract skill name (remove emoji)
            skill_text = re.sub(r"\s*[^\w\s].*$", "", line[3:]).strip()
            if skill_text in SECTION_SKILL_MAP:
                current_skill = SECTION_SKILL_MAP[skill_text]
                in_mantra_section = False
            i += 1
            continue

        # Mantra subsection: "### Skill Mantras"
        if line.startswith("### ") and "Mantra" in line:
            in_mantra_section = True
            i += 1
            continue

        # Base bonus table
        if current_skill and line.strip().startswith("| Level"):
            stat_names, per_level, end_idx = parse_base_bonus_table(lines, i)
            base_bonuses[current_skill] = {
                "stats": stat_names,
                "per_level": per_level,
            }
            i = end_idx
            continue

        # Perk definition: "**Perk Name**"
        perk_match = re.match(r"\*\*(.+?)\*\*", line.strip())
        if perk_match:
            perk_name = perk_match.group(1)
            perk_id = name_to_id(perk_name)

            # Read the requires line
            i += 1
            req_line = lines[i].strip() if i < len(lines) else ""
            req_match = re.match(r"_Requires:\s*(.+?)_", req_line)

            if not req_match:
                # No requirements line - might be flavor text or description
                i += 1
                continue

            req_text = req_match.group(1)
            parsed_reqs = parse_requirements(req_text, current_skill)

            # Read description lines (everything until next ** or --- or ### or ## or #)
            i += 1
            desc_lines = []
            flavor = ""
            while i < len(lines):
                dline = lines[i].rstrip()
                # Stop conditions
                if dline.strip().startswith("**") and not dline.strip().startswith("***"):
                    break
                if dline.strip().startswith("## ") or dline.strip().startswith("# "):
                    break
                if dline.strip().startswith("### "):
                    break
                if dline.strip() == "---":
                    i += 1
                    break

                stripped = dline.strip()
                if stripped:
                    # Check if this is a flavor line (italic, standalone)
                    if stripped.startswith("_") and stripped.endswith("_") and not stripped.startswith("_Requires"):
                        flavor = stripped[1:-1]
                    # Check for "Ongoing effect" or "Deity Yoga" sections in mantras
                    elif stripped.startswith("Ongoing effect") or stripped.startswith("Deity Yoga"):
                        desc_lines.append(stripped)
                    else:
                        desc_lines.append(stripped)

                i += 1

            description = " ".join(desc_lines).strip()

            # Build perk entry
            if in_cross_section:
                # Cross-skill perk
                entry = {
                    "name": perk_name,
                    "category": cross_category or "uncategorized",
                    "requirements": parsed_reqs["skill_requirements"],
                    "description": description,
                    "flavor": flavor,
                    "is_mantra": False,
                }
                if parsed_reqs["special"]:
                    entry["special_requirement"] = parsed_reqs["special"]
                if parsed_reqs["perk_requirements"]:
                    entry["requires_perks"] = parsed_reqs["perk_requirements"]
                if parsed_reqs.get("or_skill_requirements"):
                    entry["or_skill_requirements"] = parsed_reqs["or_skill_requirements"]
                cross_perks[perk_id] = entry
            else:
                # Skill perk
                # Determine the primary skill from requirements or current_skill
                primary_skill = current_skill
                if parsed_reqs["skill_requirements"]:
                    # Use the first skill requirement as primary
                    primary_skill = list(parsed_reqs["skill_requirements"].keys())[0]

                # Get required level
                required_level = 1
                if parsed_reqs["skill_requirements"]:
                    required_level = list(parsed_reqs["skill_requirements"].values())[0]

                entry = {
                    "name": perk_name,
                    "skill": primary_skill or "unknown",
                    "required_level": required_level,
                    "requires_perks": parsed_reqs["perk_requirements"],
                    "description": description,
                    "flavor": flavor,
                    "is_mantra": in_mantra_section,
                }
                # Add secondary skill requirements if present
                secondary_reqs = {}
                for sk, lv in parsed_reqs["skill_requirements"].items():
                    if sk != primary_skill:
                        secondary_reqs[sk] = lv
                if secondary_reqs:
                    entry["also_requires"] = secondary_reqs
                if parsed_reqs["special"]:
                    entry["special_requirement"] = parsed_reqs["special"]

                # Handle duplicate IDs by appending skill name
                if perk_id in skill_perks:
                    perk_id = f"{perk_id}_{primary_skill}"

                skill_perks[perk_id] = entry

            continue

        i += 1

    return {
        "base_bonuses": base_bonuses,
        "skill_perks": skill_perks,
        "cross_perks": cross_perks,
    }


def main():
    project_dir = Path(__file__).parent.parent
    perks_md = project_dir / "PERKS.md"
    output_json = project_dir / "resources" / "data" / "perks.json"

    if not perks_md.exists():
        print(f"Error: {perks_md} not found")
        sys.exit(1)

    print(f"Parsing {perks_md}...")
    data = parse_perks_md(perks_md)

    print(f"  Base bonuses: {len(data['base_bonuses'])} skills")
    print(f"  Skill perks: {len(data['skill_perks'])} perks")
    print(f"  Cross-skill perks: {len(data['cross_perks'])} perks")

    # Print breakdown by skill
    skill_counts = {}
    mantra_counts = {}
    for perk_id, perk in data["skill_perks"].items():
        skill = perk["skill"]
        if perk.get("is_mantra"):
            mantra_counts[skill] = mantra_counts.get(skill, 0) + 1
        else:
            skill_counts[skill] = skill_counts.get(skill, 0) + 1

    print("\n  Per-skill breakdown:")
    for skill in sorted(skill_counts.keys()):
        mantras = mantra_counts.get(skill, 0)
        mantra_str = f" + {mantras} mantras" if mantras else ""
        print(f"    {skill}: {skill_counts[skill]} perks{mantra_str}")

    # Print cross-perk categories
    cat_counts = {}
    for perk_id, perk in data["cross_perks"].items():
        cat = perk.get("category", "uncategorized")
        cat_counts[cat] = cat_counts.get(cat, 0) + 1

    print("\n  Cross-perk categories:")
    for cat in sorted(cat_counts.keys()):
        print(f"    {cat}: {cat_counts[cat]} perks")

    # Write JSON
    with open(output_json, "w") as f:
        json.dump(data, f, indent="\t", ensure_ascii=False)

    print(f"\nWritten to {output_json}")
    print(f"Total: {len(data['skill_perks']) + len(data['cross_perks'])} perks")


if __name__ == "__main__":
    main()
