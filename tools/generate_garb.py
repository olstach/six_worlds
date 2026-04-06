#!/usr/bin/env python3
"""
Generate ritual garb items (robes and hats/crowns) for Six Worlds.

System:
  - Robe slot: chest   (type: "robe")
  - Hat slot:  head    (type: "hat")
  - Consecration tiers: Plain → Blessed → Empowered → Perfected → Legendary
  - Ngakpa garments: 5 elemental variants × 5 tiers (robe + crown each)
  - Healer's garments: 5 tiers (robe + crown)
  - Black Sorcerer's garments: 5 tiers (robe + crown)
  - Standalone hats: Pandita Cap, Long-life Cap (5 tiers each)

Total: 25 + 25 + 5 + 5 + 5 + 5 + 5 + 5 = 80 items
"""

import json
from pathlib import Path

# ---------------------------------------------------------------------------
# TIERS  (same as implements)
# ---------------------------------------------------------------------------
TIERS = [
    {"id": "plain",     "name": "Plain",     "rarity": "common",    "value_mult": 1.0,  "durability": 40,   "req_focus": 8},
    {"id": "blessed",   "name": "Blessed",   "rarity": "common",    "value_mult": 4.0,  "durability": 65,   "req_focus": 10},
    {"id": "empowered", "name": "Empowered", "rarity": "uncommon",  "value_mult": 12.0, "durability": 90,   "req_focus": 12},
    {"id": "perfected", "name": "Perfected", "rarity": "rare",      "value_mult": 27.5, "durability": 180,  "req_focus": 14},
    {"id": "legendary", "name": "Legendary", "rarity": "legendary", "value_mult": 70.0, "durability": 9999, "req_focus": 16},
]

# ---------------------------------------------------------------------------
# NGAKPA ROBES  —  five elemental variants
# Each element maps to one magic school and one element tag.
# ---------------------------------------------------------------------------
NGAKPA_ELEMENTS = {
    "space": {
        "element": "space",
        "school": "space_magic",
        "school_display": "Space",
        "color_note": "red-and-white striped",
        "robe_description": (
            "The red-and-white striped chuba of the ngakpa tradition — red for method, white for wisdom. "
            "Worn by tantric practitioners who have not taken monastic vows but have taken something harder. "
            "The garment is a reminder of what the wearer holds together."
        ),
        "crown_description": (
            "The ngakpa's unbound hair is wound and pinned with this ornament. "
            "Space practitioners wear it through long retreat and carry it out with them."
        ),
    },
    "air": {
        "element": "air",
        "school": "air_magic",
        "school_display": "Air",
        "color_note": "green",
        "robe_description": (
            "Green cotton, close-woven and lightweight. "
            "Air practitioners favor fewer layers and more movement. "
            "The color is said to invite the wind's attention."
        ),
        "crown_description": (
            "A light ornament of pale metal, worn low on the brow. "
            "Air practitioners note that it never seems to sit quite the same way twice."
        ),
    },
    "fire": {
        "element": "fire",
        "school": "fire_magic",
        "school_display": "Fire",
        "color_note": "red",
        "robe_description": (
            "Red with orange-bordered trim, the color of the hearth fire that is never fully extinguished. "
            "Fire tantra practitioners work with heat as both metaphor and fact. "
            "The robe holds warmth longer than the material seems to warrant."
        ),
        "crown_description": (
            "Copper ornament with a small flame-shaped finial. "
            "Warm to the touch even in cold, which practitioners find appropriate."
        ),
    },
    "water": {
        "element": "water",
        "school": "water_magic",
        "school_display": "Water",
        "color_note": "blue",
        "robe_description": (
            "Blue, the color of deep water. "
            "Water practitioners use it for meditations that require stillness and depth. "
            "The robe is heavier than it looks, which is also considered appropriate."
        ),
        "crown_description": (
            "Silver-set blue stone, worn at the crown. "
            "Reflects light in a way that always looks like water."
        ),
    },
    "earth": {
        "element": "earth",
        "school": "earth_magic",
        "school_display": "Earth",
        "color_note": "yellow",
        "robe_description": (
            "Yellow, the color of late-season grain and mountain clay. "
            "Earth practice is patient, and practitioners who favor earth magic "
            "tend to keep their robes in repair longer than most."
        ),
        "crown_description": (
            "Gold-set amber, heavy, stable. "
            "Earth practitioners tend not to adjust it once it is on."
        ),
    },
}

# Stats tables for ngakpa garments — indexed [tier_0 .. tier_4]
# Robes: school bonus + spellpower from tier 3, mana from tier 4
NGAKPA_ROBE_STATS = [
    {"armor": 2},
    {"armor": 3},
    {"armor": 3, "spellpower": 5},
    {"armor": 4, "spellpower": 9,  "max_mana": 15},
    {"armor": 5, "spellpower": 14, "max_mana": 28},
]
NGAKPA_ROBE_SCHOOL_BONUS = [1, 2, 3, 4, 5]

# Crowns: school bonus + mana, small spellpower from tier 4
NGAKPA_CROWN_STATS = [
    {"armor": 1, "max_mana": 5},
    {"armor": 1, "max_mana": 10},
    {"armor": 2, "max_mana": 18},
    {"armor": 2, "max_mana": 28, "spellpower": 3},
    {"armor": 3, "max_mana": 45, "spellpower": 6},
]
NGAKPA_CROWN_SCHOOL_BONUS = [1, 2, 3, 4, 5]

NGAKPA_ROBE_BASE_VALUE   = 40
NGAKPA_CROWN_BASE_VALUE  = 25

# ---------------------------------------------------------------------------
# HEALER'S GARMENTS
# ---------------------------------------------------------------------------
HEALERS_ROBE_STATS = [
    {"armor": 2},
    {"armor": 3, "max_hp": 8},
    {"armor": 3, "max_hp": 15, "spellpower": 4},
    {"armor": 4, "max_hp": 25, "spellpower": 7},
    {"armor": 5, "max_hp": 40, "spellpower": 11},
]
HEALERS_ROBE_SKILL_BONUSES = [
    {"white_magic": 1},
    {"white_magic": 2},
    {"white_magic": 3},
    {"white_magic": 4},
    {"white_magic": 5},
]

HEALERS_CROWN_STATS = [
    {"armor": 1, "max_mana": 5},
    {"armor": 1, "max_mana": 10},
    {"armor": 2, "max_mana": 18},
    {"armor": 2, "max_mana": 28},
    {"armor": 3, "max_mana": 45},
]
HEALERS_CROWN_SKILL_BONUSES = [
    {"white_magic": 1},
    {"white_magic": 1, "medicine": 1},
    {"white_magic": 2, "medicine": 1},
    {"white_magic": 2, "medicine": 2},
    {"white_magic": 3, "medicine": 2},
]

HEALERS_ROBE_DESCRIPTION = (
    "White cotton with saffron-dyed borders and a medicine wheel embroidered at the hem. "
    "The sleeves roll back easily. Healers wear it not as display but as identification: "
    "you can call on this person."
)
HEALERS_CROWN_DESCRIPTION = (
    "A white cap edged with gold thread and a small blue stone at the brow. "
    "Healers are not hard to spot, and this is half the point."
)

HEALERS_BASE_VALUE = 45

# ---------------------------------------------------------------------------
# BLACK SORCERER'S GARMENTS
# ---------------------------------------------------------------------------
BLACK_ROBE_STATS = [
    {"armor": 3},
    {"armor": 3},
    {"armor": 4, "spellpower": 5},
    {"armor": 4, "spellpower": 8,  "initiative": 2},
    {"armor": 5, "spellpower": 12, "initiative": 3},
]
BLACK_ROBE_SKILL_BONUSES = [
    {"black_magic": 1},
    {"black_magic": 1, "sorcery": 1},
    {"black_magic": 2, "sorcery": 1},
    {"black_magic": 2, "sorcery": 2},
    {"black_magic": 3, "sorcery": 2},
]

BLACK_CROWN_STATS = [
    {"armor": 1},
    {"armor": 2},
    {"armor": 2, "spellpower": 3},
    {"armor": 3, "spellpower": 5, "initiative": 1},
    {"armor": 3, "spellpower": 8, "initiative": 2},
]
BLACK_CROWN_SKILL_BONUSES = [
    {"black_magic": 1},
    {"black_magic": 1, "sorcery": 1},
    {"black_magic": 2, "sorcery": 1},
    {"black_magic": 2, "sorcery": 2},
    {"black_magic": 3, "sorcery": 2},
]

BLACK_ROBE_DESCRIPTION = (
    "Black wool heavily embroidered with bone-white thread, charnel ground symbols running hem to collar. "
    "Practitioners of the dark schools wear it as armor of a different kind — "
    "it communicates what you are before you have to prove it."
)
BLACK_CROWN_DESCRIPTION = (
    "A black crown of lacquered bone and iron. "
    "The weight is real and the message is clear."
)

BLACK_BASE_VALUE = 50

# ---------------------------------------------------------------------------
# STANDALONE HATS
# ---------------------------------------------------------------------------
STANDALONE_HATS = {
    "pandita_cap": {
        "name_base": "Pandita Cap",
        "element": "air",
        "description": (
            "A tall brocade cap worn by scholars and translators, marking long years of study. "
            "The pandita tradition values accumulated learning over inspired guessing. "
            "So does this cap."
        ),
        "stats_by_tier": [
            {"armor": 1, "max_mana": 8},
            {"armor": 1, "max_mana": 12},
            {"armor": 1, "max_mana": 18},
            {"armor": 2, "max_mana": 28},
            {"armor": 2, "max_mana": 40},
        ],
        "skill_bonuses_by_tier": [
            {"learning": 1},
            {"learning": 1, "yoga": 1},
            {"learning": 2, "yoga": 1},
            {"learning": 2, "yoga": 2},
            {"learning": 3, "yoga": 2},
        ],
        "base_value": 30,
        "req_awareness": [0, 0, 10, 12, 14],
    },
    "longlife_cap": {
        "name_base": "Long-life Cap",
        "element": "earth",
        "description": (
            "A round cap embroidered with the eight auspicious symbols, worn during longevity practices. "
            "The tradition holds that the body can be persuaded to cooperate "
            "if you approach it correctly. This cap is part of the approach."
        ),
        "stats_by_tier": [
            {"armor": 1, "max_hp": 8},
            {"armor": 1, "max_hp": 15},
            {"armor": 2, "max_hp": 25},
            {"armor": 2, "max_hp": 40},
            {"armor": 3, "max_hp": 60},
        ],
        "skill_bonuses_by_tier": [
            {"white_magic": 1},
            {"white_magic": 1, "medicine": 1},
            {"white_magic": 2, "medicine": 1},
            {"white_magic": 2, "medicine": 2},
            {"white_magic": 3, "medicine": 2},
        ],
        "base_value": 30,
        "req_awareness": [0, 0, 0, 0, 0],
    },
}


def make_skill_bonuses_dict(item_id, school_bonuses):
    """Convert {skill: amount} mapping to items.json skill_bonuses format.

    items.json uses: {"skill_id": {"source_id": amount, ...}, ...}
    """
    result = {}
    for skill, amount in school_bonuses.items():
        if amount > 0:
            result[skill] = {item_id: amount}
    return result


def generate_ngakpa(items):
    for elem_key, elem in NGAKPA_ELEMENTS.items():
        for tier_idx, tier in enumerate(TIERS):
            # --- Robe ---
            robe_id = f"{tier['id']}_{elem_key}_ngakpa_robe"
            robe_name = f"{tier['name']} {elem['color_note'].title()} Ngakpa Robe"
            robe_stats = dict(NGAKPA_ROBE_STATS[tier_idx])
            school_bonus = NGAKPA_ROBE_SCHOOL_BONUS[tier_idx]
            robe_skill_bonuses = make_skill_bonuses_dict(
                robe_id, {elem["school"]: school_bonus}
            )
            robe_req = {"focus": tier["req_focus"]} if tier["req_focus"] > 0 else {}

            items[robe_id] = {
                "name": robe_name,
                "type": "robe",
                "slot": "chest",
                "two_handed": False,
                "rarity": tier["rarity"],
                "element": elem["element"],
                "weight": 3,
                "value": int(NGAKPA_ROBE_BASE_VALUE * tier["value_mult"]),
                "description": elem["robe_description"],
                "requirements": robe_req,
                "stats": robe_stats,
                "skill_bonuses": robe_skill_bonuses,
                "abilities": [],
                "durability": tier["durability"],
                "max_durability": tier["durability"],
            }

            # --- Crown ---
            crown_id = f"{tier['id']}_{elem_key}_ngakpa_crown"
            crown_name = f"{tier['name']} {elem['school_display']} Ngakpa Crown"
            crown_stats = dict(NGAKPA_CROWN_STATS[tier_idx])
            crown_school_bonus = NGAKPA_CROWN_SCHOOL_BONUS[tier_idx]
            crown_skill_bonuses = make_skill_bonuses_dict(
                crown_id, {elem["school"]: crown_school_bonus}
            )
            crown_req = {"focus": tier["req_focus"]} if tier["req_focus"] > 0 else {}

            items[crown_id] = {
                "name": crown_name,
                "type": "hat",
                "slot": "head",
                "two_handed": False,
                "rarity": tier["rarity"],
                "element": elem["element"],
                "weight": 1,
                "value": int(NGAKPA_CROWN_BASE_VALUE * tier["value_mult"]),
                "description": elem["crown_description"],
                "requirements": crown_req,
                "stats": crown_stats,
                "skill_bonuses": crown_skill_bonuses,
                "abilities": [],
                "durability": tier["durability"],
                "max_durability": tier["durability"],
            }


def generate_healers(items):
    for tier_idx, tier in enumerate(TIERS):
        req = {"focus": tier["req_focus"]}

        # Robe
        robe_id = f"{tier['id']}_healers_robe"
        items[robe_id] = {
            "name": f"{tier['name']} Healer's Robe",
            "type": "robe",
            "slot": "chest",
            "two_handed": False,
            "rarity": tier["rarity"],
            "element": "water",
            "weight": 3,
            "value": int(HEALERS_BASE_VALUE * tier["value_mult"]),
            "description": HEALERS_ROBE_DESCRIPTION,
            "requirements": req,
            "stats": dict(HEALERS_ROBE_STATS[tier_idx]),
            "skill_bonuses": make_skill_bonuses_dict(robe_id, HEALERS_ROBE_SKILL_BONUSES[tier_idx]),
            "abilities": [],
            "durability": tier["durability"],
            "max_durability": tier["durability"],
        }

        # Crown
        crown_id = f"{tier['id']}_healers_crown"
        items[crown_id] = {
            "name": f"{tier['name']} Healer's Crown",
            "type": "hat",
            "slot": "head",
            "two_handed": False,
            "rarity": tier["rarity"],
            "element": "water",
            "weight": 1,
            "value": int(int(HEALERS_BASE_VALUE * 0.7) * tier["value_mult"]),
            "description": HEALERS_CROWN_DESCRIPTION,
            "requirements": req,
            "stats": dict(HEALERS_CROWN_STATS[tier_idx]),
            "skill_bonuses": make_skill_bonuses_dict(crown_id, HEALERS_CROWN_SKILL_BONUSES[tier_idx]),
            "abilities": [],
            "durability": tier["durability"],
            "max_durability": tier["durability"],
        }


def generate_black_sorcerer(items):
    for tier_idx, tier in enumerate(TIERS):
        req = {"focus": tier["req_focus"]}

        # Robe
        robe_id = f"{tier['id']}_black_sorcerer_robe"
        items[robe_id] = {
            "name": f"{tier['name']} Black Sorcerer's Robe",
            "type": "robe",
            "slot": "chest",
            "two_handed": False,
            "rarity": tier["rarity"],
            "element": "space",
            "weight": 4,
            "value": int(BLACK_BASE_VALUE * tier["value_mult"]),
            "description": BLACK_ROBE_DESCRIPTION,
            "requirements": req,
            "stats": dict(BLACK_ROBE_STATS[tier_idx]),
            "skill_bonuses": make_skill_bonuses_dict(robe_id, BLACK_ROBE_SKILL_BONUSES[tier_idx]),
            "abilities": [],
            "durability": tier["durability"],
            "max_durability": tier["durability"],
        }

        # Crown
        crown_id = f"{tier['id']}_black_sorcerer_crown"
        items[crown_id] = {
            "name": f"{tier['name']} Black Sorcerer's Crown",
            "type": "hat",
            "slot": "head",
            "two_handed": False,
            "rarity": tier["rarity"],
            "element": "space",
            "weight": 2,
            "value": int(int(BLACK_BASE_VALUE * 0.7) * tier["value_mult"]),
            "description": BLACK_CROWN_DESCRIPTION,
            "requirements": req,
            "stats": dict(BLACK_CROWN_STATS[tier_idx]),
            "skill_bonuses": make_skill_bonuses_dict(crown_id, BLACK_CROWN_SKILL_BONUSES[tier_idx]),
            "abilities": [],
            "durability": tier["durability"],
            "max_durability": tier["durability"],
        }


def generate_standalone_hats(items):
    for hat_key, hat in STANDALONE_HATS.items():
        for tier_idx, tier in enumerate(TIERS):
            item_id = f"{tier['id']}_{hat_key}"
            req_awareness = hat["req_awareness"][tier_idx]
            req = {}
            if req_awareness > 0:
                req["awareness"] = req_awareness

            items[item_id] = {
                "name": f"{tier['name']} {hat['name_base']}",
                "type": "hat",
                "slot": "head",
                "two_handed": False,
                "rarity": tier["rarity"],
                "element": hat["element"],
                "weight": 1,
                "value": int(hat["base_value"] * tier["value_mult"]),
                "description": hat["description"],
                "requirements": req,
                "stats": dict(hat["stats_by_tier"][tier_idx]),
                "skill_bonuses": make_skill_bonuses_dict(item_id, hat["skill_bonuses_by_tier"][tier_idx]),
                "abilities": [],
                "durability": tier["durability"],
                "max_durability": tier["durability"],
            }


def generate_all():
    items = {}
    generate_ngakpa(items)
    generate_healers(items)
    generate_black_sorcerer(items)
    generate_standalone_hats(items)
    return items


def main():
    project_dir = Path(__file__).parent.parent
    output_path = project_dir / "tools" / "generated_garb.json"

    items = generate_all()
    print(f"Generated {len(items)} ritual garb items")

    # Count by garment family
    families = [
        ("ngakpa_robe",         "Ngakpa robes"),
        ("ngakpa_crown",        "Ngakpa crowns"),
        ("healers_robe",        "Healer's robes"),
        ("healers_crown",       "Healer's crowns"),
        ("black_sorcerer_robe", "Black Sorcerer robes"),
        ("black_sorcerer_crown","Black Sorcerer crowns"),
        ("pandita_cap",         "Pandita caps"),
        ("longlife_cap",        "Long-life caps"),
    ]
    for suffix, label in families:
        count = sum(1 for k in items if k.endswith(f"_{suffix}") or k.endswith(suffix))
        print(f"  {label}: {count}")

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(items, f, indent=4, ensure_ascii=False)

    print(f"\nWritten to {output_path}")
    print("Run splice_garb.py (or splice manually) to merge into items.json")


if __name__ == "__main__":
    main()
