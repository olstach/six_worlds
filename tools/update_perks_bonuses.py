#!/usr/bin/env python3
"""
update_perks_bonuses.py - Extend perks.json for the 0-10 skill scale refactor.

Two changes:
1. Replace base_bonuses per_level tables (levels 1-15 cumulative values)
2. Remap required_level for all skill_perks and cross_perks: 1→1, 2→3, 3→5, 4→7, 5→9
   Also remap also_requires and requirement values the same way.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
PERKS_PATH = ROOT / "resources/data/perks.json"

# Level remapping: old level → new level
LEVEL_MAP = {1: 1, 2: 3, 3: 5, 4: 7, 5: 9}

# ===========================================================================
# New base_bonuses tables (levels 1-15, cumulative totals at that level)
# ===========================================================================

# Helper: build a table dict from a list of 15 values
def table(values):
    return {str(i + 1): v for i, v in enumerate(values)}


# COMBAT SKILLS
# Format: {"stat_name": table([L1..L15]), ...}

BASE_BONUSES = {
    "swords": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}  # filled below
    },
    "martial_arts": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "ranged": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "daggers": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "axes": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "unarmed": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "spears": {
        "stats": ["attack", "damage", "crit_chance"],
        "per_level": {}
    },
    "maces": {
        "stats": ["attack", "damage", "armor_penetration"],
        "per_level": {}
    },
    "armor": {
        "stats": ["armor_bonus", "damage_reduction_pct"],
        "per_level": {}
    },
}

# Fill per_level for each combat skill by building combined dicts per level
# Tables indexed 0-14 (for levels 1-15)

swords_attack    = [5, 10, 16, 23, 31, 40, 50, 61, 73, 86, 100, 115, 131, 148, 166]
swords_damage    = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
swords_crit      = [0, 0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

for i in range(15):
    BASE_BONUSES["swords"]["per_level"][str(i+1)] = {
        "attack": float(swords_attack[i]),
        "damage": float(swords_damage[i]),
        "crit_chance": float(swords_crit[i]),
    }

ma_attack   = [4, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135, 152]
ma_damage   = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
ma_crit     = [0, 0, 1, 2, 3, 4, 5, 7, 9, 11, 13, 15, 17, 19, 21]

for i in range(15):
    BASE_BONUSES["martial_arts"]["per_level"][str(i+1)] = {
        "attack": float(ma_attack[i]),
        "damage": float(ma_damage[i]),
        "crit_chance": float(ma_crit[i]),
    }

ranged_attack = [6, 12, 19, 27, 37, 48, 60, 73, 88, 103, 120, 138, 157, 177, 199]
ranged_damage = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
ranged_crit   = [0, 0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

for i in range(15):
    BASE_BONUSES["ranged"]["per_level"][str(i+1)] = {
        "attack": float(ranged_attack[i]),
        "damage": float(ranged_damage[i]),
        "crit_chance": float(ranged_crit[i]),
    }

dag_attack = [4, 8, 13, 18, 24, 31, 39, 48, 58, 69, 81, 94, 108, 123, 139]
dag_damage = [2, 5, 8, 12, 17, 23, 29, 36, 44, 53, 63, 74, 86, 99, 113]
dag_crit   = [0, 1, 2, 3, 4, 6, 7, 9, 11, 13, 15, 17, 19, 21, 23]

for i in range(15):
    BASE_BONUSES["daggers"]["per_level"][str(i+1)] = {
        "attack": float(dag_attack[i]),
        "damage": float(dag_damage[i]),
        "crit_chance": float(dag_crit[i]),
    }

axes_attack = [3, 7, 11, 16, 22, 28, 36, 44, 53, 63, 74, 86, 99, 113, 128]
axes_damage = [4, 9, 15, 22, 31, 41, 52, 64, 77, 92, 108, 125, 143, 162, 182]
axes_crit   = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9]

for i in range(15):
    BASE_BONUSES["axes"]["per_level"][str(i+1)] = {
        "attack": float(axes_attack[i]),
        "damage": float(axes_damage[i]),
        "crit_chance": float(axes_crit[i]),
    }

un_attack = [4, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135, 152]
un_damage = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
un_crit   = [0, 0, 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

for i in range(15):
    BASE_BONUSES["unarmed"]["per_level"][str(i+1)] = {
        "attack": float(un_attack[i]),
        "damage": float(un_damage[i]),
        "crit_chance": float(un_crit[i]),
    }

sp_attack = [5, 11, 18, 26, 35, 45, 56, 68, 81, 95, 110, 126, 143, 161, 180]
sp_damage = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
sp_crit   = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9]

for i in range(15):
    BASE_BONUSES["spears"]["per_level"][str(i+1)] = {
        "attack": float(sp_attack[i]),
        "damage": float(sp_damage[i]),
        "crit_chance": float(sp_crit[i]),
    }

mc_attack  = [3, 7, 11, 16, 22, 28, 36, 44, 53, 63, 74, 86, 99, 113, 128]
mc_damage  = [5, 11, 18, 26, 35, 45, 56, 68, 82, 97, 113, 130, 148, 167, 187]
mc_arpen   = [2, 4, 7, 10, 14, 18, 23, 29, 35, 42, 50, 58, 67, 77, 88]

for i in range(15):
    BASE_BONUSES["maces"]["per_level"][str(i+1)] = {
        "attack": float(mc_attack[i]),
        "damage": float(mc_damage[i]),
        "armor_penetration": float(mc_arpen[i]),
    }

arm_bonus  = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
arm_dr     = [1, 2, 3, 5, 7, 9, 11, 13, 16, 19, 22, 25, 28, 31, 34]

for i in range(15):
    BASE_BONUSES["armor"]["per_level"][str(i+1)] = {
        "armor_bonus": float(arm_bonus[i]),
        "damage_reduction_pct": float(arm_dr[i]),
    }


# MAGIC SKILLS — all use the same spellpower/mana_cost_reduction_pct table
MAGIC_SP   = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
MAGIC_MCR  = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]

MAGIC_SKILLS = [
    "space_magic", "air_magic", "fire_magic", "water_magic", "earth_magic",
    "white_magic", "black_magic", "sorcery", "enchantment", "summoning"
]

for skill in MAGIC_SKILLS:
    BASE_BONUSES[skill] = {
        "stats": ["spellpower", "mana_cost_reduction_pct"],
        "per_level": {}
    }
    for i in range(15):
        BASE_BONUSES[skill]["per_level"][str(i+1)] = {
            "spellpower": float(MAGIC_SP[i]),
            "mana_cost_reduction_pct": float(MAGIC_MCR[i]),
        }

# Ritual: spellpower + mandala_bonus
ritual_sp     = MAGIC_SP[:]  # same spellpower curve
ritual_mandala = [5, 11, 18, 26, 35, 45, 56, 68, 82, 97, 114, 132, 151, 171, 192]

BASE_BONUSES["ritual"] = {
    "stats": ["spellpower", "mandala_bonus"],
    "per_level": {}
}
for i in range(15):
    BASE_BONUSES["ritual"]["per_level"][str(i+1)] = {
        "spellpower": float(ritual_sp[i]),
        "mandala_bonus": float(ritual_mandala[i]),
    }


# GENERAL SKILLS

# Persuasion
pers_roll = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91, 105, 120]
BASE_BONUSES["persuasion"] = {
    "stats": ["event_roll_bonus"],
    "per_level": {str(i+1): {"event_roll_bonus": float(pers_roll[i])} for i in range(15)}
}

# Yoga
yoga_mr   = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
yoga_mr_r = [0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10]
BASE_BONUSES["yoga"] = {
    "stats": ["mental_resistance_pct", "mantra_rate"],
    "per_level": {str(i+1): {
        "mental_resistance_pct": float(yoga_mr[i]),
        "mantra_rate": float(yoga_mr_r[i]),
    } for i in range(15)}
}

# Learning
learn_xp   = [2, 4, 7, 11, 16, 22, 29, 37, 46, 56, 67, 79, 92, 106, 121]
learn_disc = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30]  # kept for reference
BASE_BONUSES["learning"] = {
    "stats": ["xp_gain_pct"],
    "per_level": {str(i+1): {"xp_gain_pct": float(learn_xp[i])} for i in range(15)}
}

# Comedy
com_morale = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91, 105, 120]
com_stress = [0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
BASE_BONUSES["comedy"] = {
    "stats": ["morale_bonus", "stress_recovery"],
    "per_level": {str(i+1): {
        "morale_bonus": float(com_morale[i]),
        "stress_recovery": float(com_stress[i]),
    } for i in range(15)}
}

# Guile
guile_crit  = [0, 1, 2, 3, 5, 7, 9, 11, 14, 17, 20, 23, 26, 29, 32]
guile_det   = [1, 3, 5, 8, 12, 17, 23, 30, 38, 47, 57, 68, 80, 93, 107]
BASE_BONUSES["guile"] = {
    "stats": ["crit_chance", "detection_avoidance"],
    "per_level": {str(i+1): {
        "crit_chance": float(guile_crit[i]),
        "detection_avoidance": float(guile_det[i]),
    } for i in range(15)}
}

# Might
might_stam = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
might_mdb  = [1, 3, 5, 8, 12, 17, 23, 30, 38, 47, 57, 68, 80, 93, 107]
BASE_BONUSES["might"] = {
    "stats": ["max_stamina", "melee_damage_bonus"],
    "per_level": {str(i+1): {
        "max_stamina": float(might_stam[i]),
        "melee_damage_bonus": float(might_mdb[i]),
    } for i in range(15)}
}

# Leadership
lead_init = [1, 2, 3, 5, 7, 9, 12, 15, 18, 22, 26, 30, 34, 38, 42]
BASE_BONUSES["leadership"] = {
    "stats": ["initiative_bonus"],
    "per_level": {str(i+1): {"initiative_bonus": float(lead_init[i])} for i in range(15)}
}

# Performance
perf_gold = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91, 105, 120]
perf_eob  = [0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10]
BASE_BONUSES["performance"] = {
    "stats": ["gold_gain_pct", "event_outcome_bonus"],
    "per_level": {str(i+1): {
        "gold_gain_pct": float(perf_gold[i]),
        "event_outcome_bonus": float(perf_eob[i]),
    } for i in range(15)}
}

# Grace
grace_dodge = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
grace_init  = [1, 2, 4, 6, 9, 12, 16, 20, 25, 30, 35, 40, 45, 50, 55]
BASE_BONUSES["grace"] = {
    "stats": ["dodge_bonus", "initiative_bonus"],
    "per_level": {str(i+1): {
        "dodge_bonus": float(grace_dodge[i]),
        "initiative_bonus": float(grace_init[i]),
    } for i in range(15)}
}

# Medicine
med_heal  = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
med_clear = [0, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65]
BASE_BONUSES["medicine"] = {
    "stats": ["heal_effectiveness_pct", "status_clear_chance"],
    "per_level": {str(i+1): {
        "heal_effectiveness_pct": float(med_heal[i]),
        "status_clear_chance": float(med_clear[i]),
    } for i in range(15)}
}

# Alchemy
alch_pot  = [3, 7, 12, 18, 25, 33, 42, 52, 63, 75, 88, 102, 117, 133, 150]
alch_cra  = [1, 2, 4, 6, 9, 12, 16, 20, 25, 30, 35, 40, 45, 50, 55]
BASE_BONUSES["alchemy"] = {
    "stats": ["potion_effectiveness_pct", "crafting_bonus"],
    "per_level": {str(i+1): {
        "potion_effectiveness_pct": float(alch_pot[i]),
        "crafting_bonus": float(alch_cra[i]),
    } for i in range(15)}
}

# Thievery
thiev_gold = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
thiev_crit = [0, 1, 2, 3, 4, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
BASE_BONUSES["thievery"] = {
    "stats": ["gold_bonus_pct", "crit_chance"],
    "per_level": {str(i+1): {
        "gold_bonus_pct": float(thiev_gold[i]),
        "crit_chance": float(thiev_crit[i]),
    } for i in range(15)}
}

# Logistics
log_stam = [1, 2, 3, 4, 6, 8, 10, 13, 16, 19, 22, 25, 28, 31, 34]
log_eff  = [0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
BASE_BONUSES["logistics"] = {
    "stats": ["stamina_recovery_bonus", "resource_efficiency"],
    "per_level": {str(i+1): {
        "stamina_recovery_bonus": float(log_stam[i]),
        "resource_efficiency": float(log_eff[i]),
    } for i in range(15)}
}

# Trade
trade_disc  = [2, 4, 7, 11, 16, 22, 29, 37, 46, 56, 67, 79, 92, 106, 121]
trade_gold  = [1, 2, 4, 6, 9, 12, 16, 20, 25, 30, 35, 40, 45, 50, 55]
BASE_BONUSES["trade"] = {
    "stats": ["shop_discount_pct", "gold_gain_pct"],
    "per_level": {str(i+1): {
        "shop_discount_pct": float(trade_disc[i]),
        "gold_gain_pct": float(trade_gold[i]),
    } for i in range(15)}
}

# Crafting
craft_qual = [2, 5, 9, 14, 20, 27, 35, 44, 54, 65, 77, 90, 104, 119, 135]
craft_eff  = [0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
BASE_BONUSES["crafting"] = {
    "stats": ["equipment_quality_pct", "material_efficiency"],
    "per_level": {str(i+1): {
        "equipment_quality_pct": float(craft_qual[i]),
        "material_efficiency": float(craft_eff[i]),
    } for i in range(15)}
}


# ===========================================================================
# Main
# ===========================================================================

def remap_level(v):
    """Remap an old level value (1-5) to new scale (1,3,5,7,9)."""
    return LEVEL_MAP.get(int(v), int(v))

def remap_requirement_dict(d):
    """Remap a dict of {skill: level} values."""
    return {k: remap_level(v) for k, v in d.items()}


def main():
    print(f"Loading {PERKS_PATH}...")
    with open(PERKS_PATH) as f:
        data = json.load(f)

    # 1. Replace base_bonuses
    print("Replacing base_bonuses tables...")
    data["base_bonuses"] = BASE_BONUSES
    print(f"  {len(BASE_BONUSES)} skills updated")

    # 2. Remap required_level in skill_perks
    skill_perks = data.get("skill_perks", {})
    print(f"Remapping {len(skill_perks)} skill_perks required_level...")
    remap_counts = {1: 0, 3: 0, 5: 0, 7: 0, 9: 0}
    for perk_id, perk in skill_perks.items():
        old = perk.get("required_level", 1)
        new = remap_level(old)
        perk["required_level"] = new
        remap_counts[new] = remap_counts.get(new, 0) + 1

        # Remap also_requires values
        if "also_requires" in perk:
            perk["also_requires"] = remap_requirement_dict(perk["also_requires"])

    print(f"  Distribution after remap: {remap_counts}")

    # 3. Remap requirements in cross_perks
    cross_perks = data.get("cross_perks", {})
    print(f"Remapping {len(cross_perks)} cross_perks requirements...")
    for perk_id, perk in cross_perks.items():
        if "requirements" in perk:
            perk["requirements"] = remap_requirement_dict(perk["requirements"])
        if "or_skill_requirements" in perk:
            perk["or_skill_requirements"] = remap_requirement_dict(perk["or_skill_requirements"])

    # 4. Save
    print(f"Saving to {PERKS_PATH}...")
    with open(PERKS_PATH, "w") as f:
        json.dump(data, f, indent=2)
    print("Done!")


if __name__ == "__main__":
    main()
