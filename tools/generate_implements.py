#!/usr/bin/env python3
"""
Generate ritual implement items (foci) under the new material×consecration system.

Material = elemental affinity (school bonus)
Consecration level = quality tier (all base stats scale)

Outputs a JSON dict of item_id → item_data, ready to splice into items.json.
"""

import json
from pathlib import Path

# ---------------------------------------------------------------------------
# TIERS
# tier_index 0-4 = Plain/Blessed/Empowered/Perfected/Legendary
# ---------------------------------------------------------------------------
TIERS = [
    {
        "id": "plain",
        "name": "Plain",
        "rarity": "common",
        "req_focus": 8,
        "school_bonus": 1,
        "value_base": 60,
        "durability": 40,
    },
    {
        "id": "blessed",
        "name": "Blessed",
        "rarity": "common",
        "req_focus": 10,
        "school_bonus": 2,
        "value_base": 220,
        "durability": 65,
    },
    {
        "id": "empowered",
        "name": "Empowered",
        "rarity": "uncommon",
        "req_focus": 12,
        "school_bonus": 3,
        "value_base": 600,
        "durability": 90,
    },
    {
        "id": "perfected",
        "name": "Perfected",
        "rarity": "rare",
        "req_focus": 14,
        "school_bonus": 4,
        "value_base": 1400,
        "durability": 180,
    },
    {
        "id": "legendary",
        "name": "Legendary",
        "rarity": "legendary",
        "req_focus": 16,
        "school_bonus": 5,
        "value_base": 3200,
        "durability": 9999,
    },
]

# ---------------------------------------------------------------------------
# MATERIALS
# tiers: which consecration tiers this material appears on (1-indexed)
# ---------------------------------------------------------------------------
MATERIALS = {
    "copper": {
        "name": "Copper",
        "school": "fire_magic",
        "school_display": "Fire",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "Copper carries fire — transformation, passion, and the forge."
            " The practitioner who wields this brings heat to every working."
        ),
    },
    "silver": {
        "name": "Silver",
        "school": "water_magic",
        "school_display": "Water",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "Silver belongs to water — clarity, reflection, and the deep current."
            " Spells cast through silver flow rather than strike."
        ),
    },
    "gold": {
        "name": "Gold",
        "school": "earth_magic",
        "school_display": "Earth",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "Gold is earth's incorruptible face — abundance, permanence, and stability."
            " Earth-working through gold tends to endure longer than the fight."
        ),
    },
    "iron": {
        "name": "Iron",
        "school": "air_magic",
        "school_display": "Air",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "Iron is the metal of air — sharp, mobile, cutting."
            " Storm and wind obey it more readily than softer metals."
        ),
    },
    "bronze": {
        "name": "Bronze",
        "school": "space_magic",
        "school_display": "Space",
        "tiers": [1, 2, 3],
        "flavor": (
            "Bronze is a compromise — not the ideal metal for space-work, but workable."
            " Practitioners who cannot find sky-iron use it and find it adequate."
        ),
    },
    "sky_iron": {
        "name": "Sky-iron",
        "school": "space_magic",
        "school_display": "Space",
        "tiers": [4, 5],
        "flavor": (
            "Sky-iron fell from beyond the world."
            " It carries the quality of space itself — distance, and the absence of obstacle."
        ),
    },
    "conch": {
        "name": "Conch",
        "school": "white_magic",
        "school_display": "White",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "The conch announces peace — pacification, healing, and the dharma that soothes."
            " White magic runs through conch like water through a shell."
        ),
    },
    "bone": {
        "name": "Bone",
        "school": "black_magic",
        "school_display": "Black",
        "tiers": [1, 2, 3, 4, 5],
        "flavor": (
            "Bone is the wrathful material — it has already been through death."
            " Black magic practices find their anchor here naturally."
        ),
    },
}

# ---------------------------------------------------------------------------
# IMPLEMENTS
# stats_by_tier: list of stat dicts for tiers 1-5
# instrument_school: skill ID for the instrument's own school bonus (None = removed)
# instrument_school_bonuses: list of bonus values per tier (parallel to stats_by_tier)
# ---------------------------------------------------------------------------
IMPLEMENTS = {
    "dorje": {
        "name": "Dorje",
        "weapon_class": "Ritual sceptre",
        "slot": "weapon_main",
        "two_handed": False,
        "weight": 1,
        "set_pair": "dorje_drilbu",
        "element": "space",
        # White magic bonus removed — comes from conch material instead
        "instrument_school": None,
        "instrument_school_bonuses": [0, 0, 0, 0, 0],
        "stats_by_tier": [
            {"damage": 2, "spellpower": 6},
            {"damage": 2, "spellpower": 10},
            {"damage": 2, "spellpower": 15},
            {"damage": 2, "spellpower": 20},
            {"damage": 2, "spellpower": 27},
        ],
        "aura": None,
        "special": None,
        "base_value": 60,
        "description": (
            "A ritual sceptre, the symbol of indestructible method."
            " Weak as a weapon. In the right hand of a trained practitioner,"
            " it amplifies every spell cast."
        ),
    },
    "drilbu": {
        "name": "Drilbu",
        "weapon_class": "Ritual bell",
        "slot": "weapon_off",
        "two_handed": False,
        "weight": 1,
        "set_pair": "dorje_drilbu",
        "element": "space",
        # Space magic bonus retained — bell's nature is sunyata
        "instrument_school": "space_magic",
        "instrument_school_bonuses": [1, 2, 3, 4, 5],
        "stats_by_tier": [
            {"damage": 0, "max_mana": 15},
            {"damage": 0, "max_mana": 26},
            {"damage": 0, "max_mana": 40},
            {"damage": 0, "max_mana": 56},
            {"damage": 0, "max_mana": 75},
        ],
        "aura": None,
        "special": None,
        "base_value": 60,
        "description": (
            "A ritual bell, held in the left hand."
            " Its tone represents sunyata — emptiness."
            " Rung in concert with the dorje, it opens the practitioner to a larger mana pool."
        ),
    },
    "khatvanga": {
        "name": "Khatvanga",
        "weapon_class": "Skull staff",
        "slot": "weapon_main",
        "two_handed": True,
        "weight": 5,
        "set_pair": None,
        "element": "space",
        # Black magic bonus removed — comes from bone material instead
        "instrument_school": None,
        "instrument_school_bonuses": [0, 0, 0, 0, 0],
        "stats_by_tier": [
            {"damage": 5, "spellpower": 5, "max_mana": 10},
            {"damage": 6, "spellpower": 8, "max_mana": 16},
            {"damage": 7, "spellpower": 12, "max_mana": 24},
            {"damage": 9, "spellpower": 18, "max_mana": 34},
            {"damage": 10, "spellpower": 26, "max_mana": 50},
        ],
        "aura": {
            "type": "initiative_debuff",
            "values": [-2, -3, -4, -6, -8],
        },
        "special": None,
        "base_value": 80,
        "description": (
            "A trident staff topped with a skull, the emblem of wrathful practice."
            " Enemies within melee range feel their composure — and initiative — erode."
        ),
    },
    "damaru": {
        "name": "Damaru",
        "weapon_class": "Ritual drum",
        "slot": "weapon_off",
        "two_handed": False,
        "weight": 1,
        "set_pair": None,
        "element": "air",
        # Enchantment bonus retained — the drum's rhythm is enchantment
        "instrument_school": "enchantment",
        "instrument_school_bonuses": [1, 2, 3, 4, 5],
        "stats_by_tier": [
            {"damage": 0, "max_mana": 18},
            {"damage": 0, "max_mana": 30},
            {"damage": 0, "max_mana": 45},
            {"damage": 0, "max_mana": 62},
            {"damage": 0, "max_mana": 82},
        ],
        "aura": None,
        "special": {
            "type": "rhythm_charge",
            "fields": {"special_mechanic": "rhythm_charge", "charge_max": 3, "charge_discount": 0.40},
        },
        "base_value": 55,
        "description": (
            "A small double-headed drum shaken by a cord."
            " Three spells cast while holding it and the rhythm reaches its peak —"
            " the next spell costs 40% less mana."
        ),
    },
    "kangling": {
        "name": "Kangling",
        "weapon_class": "Bone trumpet",
        "slot": "weapon_off",
        "two_handed": False,
        "weight": 1,
        "set_pair": None,
        "element": "earth",
        # Summoning bonus retained — the call of the bone trumpet
        "instrument_school": "summoning",
        "instrument_school_bonuses": [1, 2, 3, 4, 5],
        "stats_by_tier": [
            {"damage": 1, "spellpower": 5},
            {"damage": 1, "spellpower": 9},
            {"damage": 1, "spellpower": 14},
            {"damage": 1, "spellpower": 20},
            {"damage": 1, "spellpower": 28},
        ],
        "aura": None,
        "special": {
            "type": "chod_offering",
            "fields": {"special_mechanic": "chod_offering", "chod_cost_pct": 0.25},
        },
        "base_value": 65,
        "description": (
            "A thigh-bone trumpet. The sound calls what should not be called."
            " Used in Chöd to offer the self — spend 25% of max mana to stack raw spellpower."
            " When mana is gone, the cost comes from HP."
        ),
    },
    "phurba": {
        "name": "Phurba",
        "weapon_class": "Ritual dagger",
        "slot": "weapon_main",
        "two_handed": False,
        "weight": 1,
        "set_pair": None,
        "element": "fire",
        # Sorcery bonus retained — the phurba pins and subjugates
        "instrument_school": "sorcery",
        "instrument_school_bonuses": [1, 2, 3, 4, 5],
        "stats_by_tier": [
            {"damage": 4, "spellpower": 4},
            {"damage": 4, "spellpower": 7},
            {"damage": 5, "spellpower": 11},
            {"damage": 5, "spellpower": 16},
            {"damage": 5, "spellpower": 22},
        ],
        "aura": None,
        "special": {
            "type": "throw_phurba",
            "fields": {
                "active_ability": "throw_phurba",
                "throw_mana_cost": 15,
                "throw_base_damage_by_tier": [8, 10, 13, 16, 20],
                "throw_save_dc": 16,
            },
        },
        "base_value": 70,
        "description": (
            "A three-bladed ritual dagger."
            " The three blades cut through ignorance, attachment, and aversion."
            " Can be used to physically strike, but its true power is thrown —"
            " a ranged attack that pins and subjugates."
        ),
    },
}

# ---------------------------------------------------------------------------
# TIER DISPLAY NAMES for item name construction
# ---------------------------------------------------------------------------
TIER_PREFIXES = ["Plain", "Blessed", "Empowered", "Perfected", "Legendary"]


def make_item(mat_key, mat, tier_idx, impl_key, impl):
    """Generate one item dict."""
    tier = TIERS[tier_idx]
    tier_name = TIER_PREFIXES[tier_idx]

    # Build item_id
    mat_id = mat_key  # e.g. "copper", "sky_iron"
    item_id = f"{tier['id']}_{mat_id}_{impl_key}"

    # Display name
    name = f"{tier_name} {mat['name']} {impl['name']}"

    # Stats
    stats = dict(impl["stats_by_tier"][tier_idx])

    # Skill bonuses dict: instrument school + material school
    skill_bonuses = {}
    inst_school = impl["instrument_school"]
    inst_bonus = impl["instrument_school_bonuses"][tier_idx]
    if inst_school and inst_bonus > 0:
        skill_bonuses[inst_school] = {item_id: inst_bonus}

    mat_school = mat["school"]
    mat_bonus = tier["school_bonus"]
    if mat_school in skill_bonuses:
        # Same school from both instrument and material (e.g. bronze Drilbu → space×2)
        skill_bonuses[mat_school][item_id + "_mat"] = mat_bonus
    else:
        skill_bonuses[mat_school] = {item_id + "_mat": mat_bonus}

    # Requirements
    requirements = {"focus": tier["req_focus"]}
    if tier_idx >= 2 and impl_key == "khatvanga":
        # Khatvanga needs awareness at higher tiers
        requirements["awareness"] = [0, 0, 10, 12, 14][tier_idx]

    # Value: base implement value × tier multiplier × slight material tweak
    value_mults = [1.0, 3.5, 9.0, 18.0, 45.0]
    value = int(impl["base_value"] * value_mults[tier_idx])

    # Description: instrument base + material flavor
    description = impl["description"] + " " + mat["flavor"]

    # Build entry
    entry = {
        "name": name,
        "weapon_class": impl["weapon_class"],
        "type": "focus",
        "slot": impl["slot"],
        "two_handed": impl["two_handed"],
        "rarity": tier["rarity"],
        "element": impl["element"],
        "weight": impl["weight"],
        "value": value,
        "description": description,
        "requirements": requirements,
        "stats": stats,
        "skill_bonuses": skill_bonuses,
        "abilities": [],
        "durability": tier["durability"],
        "max_durability": tier["durability"],
    }

    # Set pair
    if impl.get("set_pair"):
        entry["set_pair"] = impl["set_pair"]

    # Aura (khatvanga initiative debuff)
    if impl["aura"]:
        entry["passive_aura"] = impl["aura"]["type"]
        entry["aura_value"] = impl["aura"]["values"][tier_idx]

    # Special mechanics
    if impl["special"]:
        stype = impl["special"]["type"]
        sfields = impl["special"]["fields"]
        if stype == "throw_phurba":
            entry["active_ability"] = sfields["active_ability"]
            entry["throw_mana_cost"] = sfields["throw_mana_cost"]
            entry["throw_base_damage"] = sfields["throw_base_damage_by_tier"][tier_idx]
            entry["throw_save_dc"] = sfields["throw_save_dc"]
        else:
            for k, v in sfields.items():
                entry[k] = v

    return item_id, entry


def generate_all():
    items = {}
    for impl_key, impl in IMPLEMENTS.items():
        for mat_key, mat in MATERIALS.items():
            for tier_idx, tier in enumerate(TIERS):
                tier_num = tier_idx + 1  # 1-indexed
                if tier_num not in mat["tiers"]:
                    continue
                item_id, item_data = make_item(mat_key, mat, tier_idx, impl_key, impl)
                items[item_id] = item_data
    return items


def main():
    project_dir = Path(__file__).parent.parent
    output_path = project_dir / "tools" / "generated_implements.json"

    items = generate_all()
    print(f"Generated {len(items)} ritual implement items")

    # Count by implement type
    for impl_key in IMPLEMENTS:
        count = sum(1 for k in items if k.endswith(f"_{impl_key}"))
        print(f"  {impl_key}: {count} items")

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(items, f, indent=4, ensure_ascii=False)

    print(f"\nWritten to {output_path}")


if __name__ == "__main__":
    main()
