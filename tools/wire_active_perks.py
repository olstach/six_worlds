#!/usr/bin/env python3
"""Give every wirable active perk a `combat_data` block.

`combat_manager.gd` has 32 active-skill resolvers (`_resolve_*`, dispatched from
`use_active_skill`), but no perk in perks.json ever carried the `combat_data`
they read.  Every "Active." perk therefore rendered greyed-out in the combat
skill panel (`combat_arena.gd` disables any non-mantra skill whose combat_data
is empty).  This script fills that gap.

Run:
    python3 tools/wire_active_perks.py            # dry run, prints a summary
    python3 tools/wire_active_perks.py --write    # apply
    python3 tools/validate_data.py                # always

Schema notes (derived from the resolvers, not invented):

* `targeting` is read by BOTH `CombatManager.get_active_skill_targets()` and
  `combat_arena._on_active_skill_selected()`.  Only these values produce valid
  target tiles: self, single_enemy, single_ally, aoe_point, teleport,
  dash_attack.  Anything that resolves on the user must use "self" so the arena
  fires it immediately instead of entering a targeting mode with no targets.
* `buffs[].stat` only takes effect for stats CombatUnit actually folds
  `_get_stat_modifier_bonus()` into: initiative, movement, accuracy, dodge,
  damage, armor, crit_chance, spellpower.  Plus the three special-cased keys
  movement_mode (buff_self/stance), skill_bonus and status_resistance
  (buff_ally only).
* Status names must exist in statuses.json.
"""

import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PERKS = ROOT / "resources" / "data" / "perks.json"
STATUSES = ROOT / "resources" / "data" / "statuses.json"

# Stats that CombatUnit actually reads back out of `stat_modifiers`.
LIVE_STATS = {
    "initiative", "movement", "accuracy", "dodge",
    "damage", "armor", "crit_chance", "spellpower",
}
# Extra stat keys the resolvers special-case.
SPECIAL_STATS = {"movement_mode", "skill_bonus", "status_resistance"}

# Every effect string `use_active_skill` dispatches to a real resolver.
LIVE_EFFECTS = {
    "attack_with_bonus", "dash_attack", "buff_self", "debuff_target",
    "aoe_attack", "teleport", "stance", "heal_self", "enter_stealth",
    "mark_target", "examine", "bonus_movement", "restore_stamina",
    "restore_armor", "revive", "debuff_enemies", "buff_allies", "buff_ally",
    "destroy_obstacle", "cleanse_and_buff", "grant_extra_action", "force_miss",
    "grapple", "overcast", "retreat", "aoe_damage_and_status",
    "buff_allies_debuff_enemies", "dispel_and_invert", "aggro_aura",
    "share_buffs", "double_buffs",
}
VALID_TARGETING = {
    "self", "single_enemy", "single_ally", "aoe_point", "teleport", "dash_attack",
}

# ---------------------------------------------------------------------------
# Perks whose description opens with "Active" but which never belong in the
# combat skill panel.  Flagged so `_get_active_skills()` can filter them out.
# ---------------------------------------------------------------------------
NON_COMBAT = [
    "forage", "scout_ahead",            # logistics, overworld
    "investment", "supply_and_demand",  # trade, overworld
    "guided_practice",                  # learning, out of combat
    "reinforce",                        # smithing, out of combat
    "inspiring_sermon",                 # cross, non-combat speech
]

# `host_of_the_winds` reads "Active Air summons also provide ..." — it describes
# summons that are active, not an activated ability, and only landed in the
# combat panel because `_get_active_skills()` matches on the "Active" prefix.
DESCRIPTION_FIXES = {
    "host_of_the_winds": (
        "Passive. Your active Air summons also provide +5% Dodge and "
        "+2 Initiative to allies within 2 tiles."
    ),
}

# ---------------------------------------------------------------------------
# The mapping.  perk_id -> combat_data
# ---------------------------------------------------------------------------
COMBAT_DATA = {
    # ---- swords ----------------------------------------------------------
    "final_cut": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 8, "armor_ignore_pct": 50, "resist_ignore_pct": 50,
        "refund_on_kill": 4,
    },
    "lunge": {
        "effect": "dash_attack", "targeting": "dash_attack",
        "stamina_cost": 4, "dash_range": 2, "damage_bonus_pct": 25,
    },
    "measured_strike": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 3, "accuracy_bonus": 20,
        "self_buff": {"stat": "armor", "value": 15, "duration": 1},
    },

    # ---- axes ------------------------------------------------------------
    "overhead_chop": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 3, "damage_bonus_pct": 30, "armor_ignore_pct": 15,
        "self_buff": {"stat": "dodge", "value": -15, "duration": 1},
    },
    "red_harvest": {
        # No arc geometry in the grid — a radius-1 burst centred on an adjacent
        # tile covers the same enemies in practice.
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 8, "range": 1, "aoe_radius": 1, "damage_pct": 100,
    },
    "sundering_blow": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 4,
        "target_debuff": {"stat": "armor", "value": 30, "duration": 3},
    },

    # ---- maces -----------------------------------------------------------
    "ground_slam": {
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 5, "range": 1, "aoe_radius": 1, "damage_pct": 60,
    },
    "mountain_falls": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 10, "once_per_combat": True, "damage_bonus_pct": 100,
    },
    "overwhelming_blow": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 3, "damage_bonus_pct": 25,
    },
    "the_mountain_answers": {
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 8, "range": 2, "aoe_radius": 2, "damage_pct": 100,
    },

    # ---- spears ----------------------------------------------------------
    "impaling_strike": {
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 6, "range": 2, "aoe_radius": 1, "damage_pct": 80,
    },
    "pinning_thrust": {
        "effect": "debuff_target", "targeting": "single_enemy",
        "stamina_cost": 5, "range": 2, "deals_damage": True,
        "statuses": [{"status": "Immobilized", "duration": 2}],
    },
    "sweeping_strike": {
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 4, "range": 1, "aoe_radius": 1, "damage_pct": 75,
    },

    # ---- ranged ----------------------------------------------------------
    "aimed_shot": {
        "effect": "buff_self", "targeting": "self", "stamina_cost": 4,
        "buffs": [
            {"stat": "accuracy", "value": 25, "duration": 1},
            {"stat": "damage", "value": 20, "duration": 1},
        ],
    },
    "no_safe_angle": {
        "effect": "buff_self", "targeting": "self", "once_per_combat": True,
        "buffs": [{"stat": "crit_chance", "value": 100, "duration": 1}],
    },
    "one_breath_one_kill": {
        # range 80 covers the whole 48x30 grid (max Manhattan distance 78).
        "effect": "attack_with_bonus", "targeting": "single_enemy",
        "stamina_cost": 6, "once_per_combat": True, "range": 80,
        "armor_ignore_pct": 100, "ignore_dodge": True,
    },
    "pinning_shot": {
        "effect": "debuff_target", "targeting": "single_enemy",
        "stamina_cost": 5, "range": 8, "deals_damage": True,
        "statuses": [{"status": "Immobilized", "duration": 1}],
    },
    "volley": {
        "effect": "aoe_attack", "targeting": "aoe_point",
        "stamina_cost": 6, "range": 6, "aoe_radius": 1, "damage_pct": 60,
    },

    # ---- martial_arts ----------------------------------------------------
    "cloud_step": {
        "effect": "buff_self", "targeting": "self", "stamina_cost": 3,
        "buffs": [{"stat": "movement_mode", "status": "Levitating", "duration": 1}],
    },
    "disrupting_palm": {
        # "choose one" needs a picker UI; armour is the default branch.
        "effect": "debuff_target", "targeting": "single_enemy",
        "stamina_cost": 4, "range": 1, "deals_damage": True,
        "debuffs": [{"stat": "armor", "value": 15, "duration": 2}],
    },
    "step_between_moments": {
        # `range` drives target highlighting, `teleport_range` the resolver.
        "effect": "teleport", "targeting": "teleport", "stamina_cost": 6,
        "range": 3, "teleport_range": 3,
        "buffs": [
            {"stat": "crit_chance", "value": 20, "duration": 1},
            {"stat": "dodge", "value": 15, "duration": 1},
        ],
    },
    "whirling_advance": {
        "effect": "dash_attack", "targeting": "dash_attack",
        "stamina_cost": 4, "dash_range": 4,
    },

    # ---- unarmed ---------------------------------------------------------
    "body_blow": {
        "effect": "debuff_target", "targeting": "single_enemy",
        "stamina_cost": 3, "range": 1, "deals_damage": True,
        "statuses": [{"status": "Knocked_Down", "duration": 1}],
    },
    "one_inch": {
        "effect": "attack_with_bonus", "targeting": "single_enemy",
        "stamina_cost": 8, "once_per_combat": True, "range": 1,
        "damage_bonus_pct": 200, "armor_ignore_pct": 100, "ignore_dodge": True,
    },

    # ---- armor -----------------------------------------------------------
    "brace_for_impact": {
        "effect": "buff_self", "targeting": "self",
        "free_action": True, "cooldown": 3,
        "buffs": [{"stat": "armor", "value": 30, "duration": 1}],
    },
    "shield_bash": {
        "effect": "debuff_target", "targeting": "single_enemy",
        "stamina_cost": 3, "range": 1, "deals_damage": True,
        "debuffs": [{"stat": "accuracy", "value": 10, "duration": 1}],
    },
    "shield_wall": {
        "effect": "stance", "targeting": "self",
        "buffs": [{"stat": "armor", "value": 25, "duration": 2}],
    },

    # ---- might -----------------------------------------------------------
    "break_through": {
        "effect": "buff_self", "targeting": "self", "stamina_cost": 4,
        "buffs": [{"stat": "movement_mode", "status": "Levitating", "duration": 1}],
    },
    "fullbody_strike": {
        "effect": "buff_self", "targeting": "self", "stamina_cost": 5,
        "buffs": [{"stat": "damage", "value": 20, "duration": 1}],
    },
    "second_wind": {
        "effect": "heal_self", "targeting": "self", "cooldown": 3,
        "heal_value": 0, "stamina_restore_pct": 30,
        "buffs": [{"stat": "armor", "value": 10, "duration": 2}],
    },

    # ---- grace -----------------------------------------------------------
    "dance_of_the_river": {
        "effect": "buff_self", "targeting": "self",
        "stamina_cost": 6, "once_per_combat": True,
        "buffs": [
            {"stat": "dodge", "value": 30, "duration": 1},
            {"stat": "movement", "value": 3, "duration": 1},
        ],
    },
    "spring_step": {
        "effect": "bonus_movement", "targeting": "self",
        "stamina_cost": 3, "free_action": True, "bonus_movement": 2,
    },
    "tumble": {
        "effect": "buff_self", "targeting": "self", "stamina_cost": 2,
        "buffs": [{"stat": "movement_mode", "status": "Levitating", "duration": 1}],
    },

    # ---- thievery / guile ------------------------------------------------
    "quick_escape": {
        "effect": "bonus_movement", "targeting": "self",
        "free_action": True, "cooldown": 3, "bonus_movement": 3,
    },
    "that_was_supposed_to_miss": {
        "effect": "force_miss", "targeting": "single_enemy",
        "once_per_combat": True, "range": 6,
    },

    # ---- leadership ------------------------------------------------------
    "bark_orders": {
        "effect": "buff_ally", "targeting": "single_ally", "range": 6,
        "buffs": [
            {"stat": "movement", "value": 1, "duration": 2},
            {"stat": "accuracy", "value": 10, "duration": 2},
        ],
    },
    "call_the_shot": {
        # `once_per_turn` keys off <perk_id>_used_this_turn, which CombatUnit
        # already declares as call_the_shot_used_this_turn.
        "effect": "mark_target", "targeting": "single_enemy",
        "free_action": True, "once_per_turn": True, "range": 6,
    },
    "rally_the_banner": {
        "effect": "cleanse_and_buff", "targeting": "self",
        "cooldown": 3, "aoe_radius": 3,
        "cleanses": ["mental", "Stunned", "Feared", "Confused", "Charmed",
                     "Dominated", "Demoralized"],
        "buffs": [{"stat": "initiative", "value": 3, "duration": 2}],
    },
    "this_is_the_moment": {
        "effect": "grant_extra_action", "targeting": "self",
        "once_per_combat": True, "range": 6, "max_targets": 4,
    },

    # ---- comedy / performance --------------------------------------------
    "taunt": {
        # Widened from one enemy to nearby enemies: `taunt_active` is the only
        # aggro hook combat_arena's AI reads, and it is unit-wide.
        "effect": "aggro_aura", "targeting": "self", "duration": 2,
    },
    "look_at_me": {
        "effect": "aggro_aura", "targeting": "self", "duration": 2,
    },
    "cutting_remark": {
        "effect": "debuff_target", "targeting": "single_enemy", "range": 6,
        "debuffs": [{"stat": "accuracy", "value": 10, "duration": 2}],
        "statuses": [{"status": "Demoralized", "duration": 2}],
    },
    "the_laughter_turns": {
        # alternate_status left empty so non-demoralised enemies are skipped.
        "effect": "debuff_enemies", "targeting": "self",
        "once_per_combat": True, "aoe_radius": 6, "save_type": "focus",
        "requires_demoralized": True,
        "statuses": [{"status": "Confused", "duration": 2}],
    },
    "the_performance_of_a_lifetime": {
        "effect": "buff_allies_debuff_enemies", "targeting": "self",
        "once_per_combat": True, "enemy_save_type": "focus",
        "ally_buffs": [{"stat": "damage", "value": 25, "duration": 2}],
        "enemy_debuffs": [{"stat": "accuracy", "value": -25, "duration": 2}],
    },

    # ---- persuasion / yoga -----------------------------------------------
    "compelling_proposal": {
        "effect": "debuff_target", "targeting": "single_enemy", "range": 6,
        "statuses": [{"status": "Dominated", "duration": 1}],
    },
    "crowd_influence": {
        "effect": "buff_allies_debuff_enemies", "targeting": "self",
        "once_per_combat": True, "enemy_save_type": "focus",
        "ally_buffs": [
            {"stat": "initiative", "value": 3, "duration": 3},
            {"stat": "armor", "value": 10, "duration": 3},
        ],
        "enemy_debuffs": [
            {"stat": "initiative", "value": -3, "duration": 3},
            {"stat": "armor", "value": -10, "duration": 3},
        ],
    },
    "intimidating_stance": {
        "effect": "debuff_enemies", "targeting": "self",
        "aoe_radius": 2, "save_type": "focus",
        "statuses": [{"status": "Stunned", "duration": 1}],
    },
    "terms_of_engagement": {
        # "withdraw from the fight" maps onto Pacified (disengaged, will not attack).
        "effect": "debuff_enemies", "targeting": "self",
        "once_per_combat": True, "aoe_radius": 10, "save_type": "charm",
        "statuses": [{"status": "Pacified", "duration": 3}],
    },
    "pacify_the_confused": {
        "effect": "debuff_target", "targeting": "single_enemy", "range": 6,
        "statuses": [{"status": "Pacified", "duration": 3}],
    },

    # ---- medicine / learning ---------------------------------------------
    "booster_shot": {
        "effect": "buff_ally", "targeting": "single_ally",
        "stamina_cost": 4, "range": 4,
        "buffs": [{"stat": "status_resistance", "value": 25, "duration": 3}],
    },
    "diagnosis": {
        # aoe_point rather than single_ally: examine works on either team, and
        # single_ally targeting cannot reach a downed one.
        "effect": "examine", "targeting": "aoe_point",
        "free_action": True, "range": 6,
    },
    "miraculous_recovery": {
        # aoe_point because get_active_skill_targets("single_ally") filters on
        # is_alive(), which is false for exactly the bleeding-out ally this
        # skill exists to revive.
        "effect": "revive", "targeting": "aoe_point",
        "once_per_combat": True, "range": 2, "heal_pct": 30,
        "cleanse_all_debuffs": True,
    },
    "crossdisciplinary_insight": {
        "effect": "buff_ally", "targeting": "single_ally", "range": 4,
        "buffs": [{"stat": "skill_bonus", "value": 2, "duration": 3}],
    },
    "observe_carefully": {
        "effect": "examine", "targeting": "single_enemy",
        "free_action": True, "range": 8,
    },

    # ---- logistics / alchemy / smithing ----------------------------------
    "strategic_withdrawal": {
        "effect": "retreat", "targeting": "self", "once_per_combat": True,
    },
    "universal_solvent": {
        "effect": "destroy_obstacle", "targeting": "aoe_point",
        "once_per_combat": True, "range": 3,
    },
    "field_repair": {
        "effect": "restore_armor", "targeting": "single_ally",
        "cooldown": 3, "range": 2, "armor_restore_pct": 25,
    },

    # ---- ritual / sorcery (overcast family) ------------------------------
    "grand_working": {
        "effect": "overcast", "targeting": "self", "requires": "ritual_circle",
        "next_spell_bonus": {"spellpower_bonus_pct": 100},
    },
    "burn_the_breath": {
        "effect": "overcast", "targeting": "self",
        "next_spell_bonus": {
            "spellpower_bonus_pct": 100, "self_damage_pct_of_mana": 25,
        },
    },
    "one_perfect_sentence": {
        "effect": "overcast", "targeting": "self", "once_per_combat": True,
        "next_spell_bonus": {
            "spellpower_bonus_pct": 200, "mana_cost_multiplier": 2.0,
        },
    },
    "push_the_words": {
        "effect": "overcast", "targeting": "self",
        "next_spell_bonus": {
            "spellpower_bonus_pct": 100, "mana_cost_multiplier": 1.5,
        },
    },

    # ---- enchantment -----------------------------------------------------
    "absolute_presence": {
        "effect": "share_buffs", "targeting": "self",
        "once_per_combat": True, "duration": 2,
    },
    "masterwork": {
        "effect": "double_buffs", "targeting": "single_ally",
        "once_per_combat": True, "range": 4,
    },
    "unraveling": {
        "effect": "dispel_and_invert", "targeting": "single_enemy",
        "range": 5, "duration": 2,
    },

    # ---- summoning -------------------------------------------------------
    "summoners_command": {
        "effect": "grant_extra_action", "targeting": "self",
        "free_action": True, "range": 8, "max_targets": 1, "summon_only": True,
    },

    # ---- air magic -------------------------------------------------------
    "perfect_volley": {
        "effect": "buff_allies", "targeting": "self",
        "buffs": [
            {"stat": "accuracy", "value": 15, "duration": 2},
            {"stat": "crit_chance", "value": 10, "duration": 2},
        ],
    },
    "sharpened_aim": {
        "effect": "buff_self", "targeting": "self",
        "buffs": [
            {"stat": "accuracy", "value": 15, "duration": 2},
            {"stat": "crit_chance", "value": 10, "duration": 2},
        ],
    },

    # ---- earth magic -----------------------------------------------------
    "petrify": {
        "effect": "debuff_target", "targeting": "single_enemy",
        "once_per_combat": True, "range": 6,
        "statuses": [{"status": "Petrified", "duration": 3}],
    },
    "roots_of_the_world": {
        "effect": "buff_allies", "targeting": "self", "once_per_combat": True,
        "buffs": [{"stat": "armor", "value": 25, "duration": 3}],
        "statuses": [{"status": "Resolute", "duration": 3}],
    },

    # ---- water magic -----------------------------------------------------
    "drowning_pressure": {
        "effect": "aoe_damage_and_status", "targeting": "aoe_point",
        "once_per_combat": True, "range": 5, "aoe_radius": 3,
        "damage_pct": 75, "damage_element": "water", "save_type": "focus",
        "statuses": [{"status": "Silenced", "duration": 2}],
    },
    "the_river_has_no_shape": {
        "effect": "buff_self", "targeting": "self", "once_per_combat": True,
        "buffs": [{"stat": "movement_mode", "status": "Levitating", "duration": 3}],
        "statuses": [{"status": "Resolute", "duration": 3}],
    },

    # ---- white magic -----------------------------------------------------
    "breath_easy": {
        "effect": "buff_allies", "targeting": "self", "once_per_combat": True,
        "buffs": [{"stat": "armor", "value": 90, "duration": 1}],
        "statuses": [{"status": "Mental_Immunity", "duration": 1}],
    },

    # ---- cross perks -----------------------------------------------------
    "fools_courage": {
        "effect": "restore_stamina", "targeting": "self",
        "stamina_restore_pct": 15,
    },
    "brawlers_grapple": {
        "effect": "grapple", "targeting": "single_enemy",
        "stamina_cost": 5, "range": 1,
        "statuses": [{"status": "Grappled", "duration": 99}],
    },
    "holy_smite": {
        "effect": "attack_with_bonus", "targeting": "single_enemy", "range": 1,
        "stamina_cost": 4, "damage_bonus_pct": 30,
    },
}

# ---------------------------------------------------------------------------
# Active perks deliberately left without combat_data: each needs a resolver
# that does not exist yet, so wiring them would swap a greyed-out button for a
# clickable one that fails with "Skill not yet implemented".
# ---------------------------------------------------------------------------
DEFERRED = {
    # Reaction/counter mechanics — need an on-being-attacked hook.
    "counterstrike": "counter_stance",
    "stand_in_the_gap": "counter_stance",
    "set_for_charge": "counter_stance",
    "kill_zone": "counter_stance",
    "heavenly_counterflow": "counter_stance",
    "none_shall_pass": "already wired as a passive ZoC reaction",
    # Terrain creation — needs a CombatGrid terrain-placement API.
    "black_ice": "create_terrain",
    "fog_of_war": "create_terrain",
    "gravity_well": "create_terrain",
    "raise_wall": "create_terrain",
    "crumbling_avalanche": "create_terrain",
    "improvised_barricade": "create_terrain",
    "prepared_ground": "create_terrain",
    "inscribed_circle": "create_terrain",
    "the_door_stands_open": "create_terrain",
    # Other missing resolvers.
    "field_medic": "heal_ally",
    "smoke_and_mirrors": "create_images",
    "arcane_archer": "imbued_attack",
    "attune_charm": "consume_charm",
    "everyone_is_somewhere_else_now": "mass_teleport",
    "magnetism": "recruit_or_pacify",
    "trap_maker": "place_trap",
    "the_invisible_hand": "steal_item",
    "improvised_masterpiece": "choose_one",
    "stalwart_guardian": "guard_ally",
    "too_fast_to_react": "overcast (needs ignore_resistances support)",
}


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def all_perks(data):
    out = {}
    for section in ("skill_perks", "cross_perks"):
        for pid, perk in data[section].items():
            if not pid.startswith("_"):
                out[pid] = perk
    return out


def validate(data, status_names):
    """Fail loudly rather than write combat_data no resolver can consume."""
    perks = all_perks(data)
    errors = []

    for pid, cd in COMBAT_DATA.items():
        if pid not in perks:
            errors.append(f"{pid}: no such perk")
            continue
        if not perks[pid]["description"].startswith("Active"):
            errors.append(f"{pid}: description is not an Active perk")
        if cd["effect"] not in LIVE_EFFECTS:
            errors.append(f"{pid}: effect '{cd['effect']}' has no resolver")
        if cd.get("targeting") not in VALID_TARGETING:
            errors.append(f"{pid}: targeting '{cd.get('targeting')}' yields no tiles")
        for key in ("buffs", "ally_buffs", "debuffs", "enemy_debuffs"):
            for entry in cd.get(key, []):
                stat = entry.get("stat", "")
                if stat not in LIVE_STATS | SPECIAL_STATS:
                    errors.append(f"{pid}: {key} stat '{stat}' is never read back")
        for entry in (cd.get("self_buff"), cd.get("target_debuff")):
            if entry and entry.get("stat") not in LIVE_STATS:
                errors.append(f"{pid}: stat '{entry.get('stat')}' is never read back")
        for entry in cd.get("statuses", []):
            if entry["status"] not in status_names:
                errors.append(f"{pid}: unknown status '{entry['status']}'")
        for entry in cd.get("buffs", []):
            if entry.get("stat") == "movement_mode" and entry.get("status") not in status_names:
                errors.append(f"{pid}: unknown movement_mode status '{entry.get('status')}'")

    for pid in list(NON_COMBAT) + list(DESCRIPTION_FIXES) + list(DEFERRED):
        if pid not in perks:
            errors.append(f"{pid}: no such perk")

    overlap = set(COMBAT_DATA) & (set(NON_COMBAT) | set(DEFERRED))
    if overlap:
        errors.append(f"listed both as wired and skipped: {sorted(overlap)}")

    return errors


def apply(data):
    perks = all_perks(data)
    for pid, cd in COMBAT_DATA.items():
        perks[pid]["combat_data"] = cd
    for pid in NON_COMBAT:
        perks[pid]["non_combat"] = True
    for pid, desc in DESCRIPTION_FIXES.items():
        perks[pid]["description"] = desc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true", help="apply changes")
    args = ap.parse_args()

    data = load(PERKS)
    status_names = {s["name"] for s in load(STATUSES)["statuses"]}

    errors = validate(data, status_names)
    if errors:
        print("VALIDATION FAILED:", file=sys.stderr)
        for e in errors:
            print("  -", e, file=sys.stderr)
        return 1

    perks = all_perks(data)
    active = [p for p, v in perks.items() if v["description"].startswith("Active")]
    accounted = set(COMBAT_DATA) | set(NON_COMBAT) | set(DEFERRED) | set(DESCRIPTION_FIXES)
    unaccounted = sorted(set(active) - accounted)

    print(f"active perks:        {len(active)}")
    print(f"  wired:             {len(COMBAT_DATA)}")
    print(f"  non-combat flag:   {len(NON_COMBAT)}")
    print(f"  reclassified:      {len(DESCRIPTION_FIXES)}")
    print(f"  deferred:          {len(DEFERRED)}")
    print(f"  unaccounted for:   {len(unaccounted)}")
    for pid in unaccounted:
        print("    -", pid)
    if unaccounted:
        return 1

    if not args.write:
        print("\ndry run — pass --write to apply")
        return 0

    apply(data)
    PERKS.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"\nwrote {PERKS.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
