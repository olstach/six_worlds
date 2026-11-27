#!/usr/bin/env python3
"""Move resources/data/statuses.json onto the effect shape (stage 2b).

A status used to say what it did with a list of words ("attack_bonus",
"dodge_penalty") that a table in CombatUnit._get_status_stat_bonus turned into
numbers, plus a handful of loose keys (type, category, duration_type ...).
In the new shape a status is a container of effects, like a spell:

    {"name": "Blessed", "polarity": "positive", "categories": ["magical"],
     "scope": "world", "duration": {"kind": "spellpower"},
     "stacking": {"mode": "refresh"},
     "while_active": [
        {"op": "modify", "value": "stat.accuracy", "mode": "fortify", "amount": 10},
        {"op": "modify", "value": "stat.armor", "mode": "fortify", "amount": 10}]}

This file is extended by later tasks (6: behaviour). Task 4 moved the METADATA
and every NUMBER:

  type            -> polarity    (buff -> positive, debuff -> negative)
  category        -> categories  (CATEGORY_TABLE below, plus poison / disease /
                                  wound from `affliction`, elemental.<element>
                                  from a damage-per-turn word, and `magical` for
                                  everything a dispel may take)
  (name)          -> scope       (world for statuses that live on the map)
  duration_type + default_duration -> duration {kind, base}
  stackable       -> stacking    (true -> independent, else refresh)
  stat words      -> while_active modify stat.<x> (STAT_TABLE, the exact
                                  numbers of the deleted GDScript table)
  named attribute words with an amount (spec section 7) -> modify attribute.<a>
  grants_resistance / grants_vulnerability -> modify resist.<k> fortify / drain

Task 5 moves the YES/NO words (a reader that only asks "has it?") into `flags`:

  yes/no word        -> flags       (FLAG_FOR_WORD; the flag keeps the word, two
                                     words are merged, four become immune:<...>)
  hard-coded names   -> flags       (NAME_FLAGS: the status lists the code kept
                                     as `status in [...]`, now data)
  words nothing read -> removed     (UNBUILT_WORDS; the status gets a `notes`
                                     line "Unbuilt: ..." and TODO section 16
                                     lists them)
  everything else    -> stays in `effects` for Task 6 (a damage-over-time type,
                        a tick, an expiry hook, a save, the enchant table)

Task 6 moves the BEHAVIOUR (what a status does, rather than what it changes)
into triggers, periodic effects and intercepts, and removes the last old keys:

  damage_per_turn + <type>_damage_per_turn word -> periodic damage, amount
                       {from: status.value, default: <damage_per_turn>}, the
                       type from the word (physical without one); a
                       damage_increase_per_turn grows it, scale per turn_active
  heal_per_turn      -> periodic heal
  retaliation        -> trigger on: struck (reach 1 for melee), damage /
                       reflected damage / status at the source
  *_on_expire        -> trigger on: expire (damage, status, summon)
  spread             -> {to: adjacent, reach?, chance: percent, when: turn_start}
  save_at_end_of_turn + save_type -> save {stat, dc: 15, when: turn_start};
                       a save_type with nothing rolling it is dropped (notes)
  reaction           -> an intercepting / movement trigger (attacked_in_melee,
                       enemy_enters_reach, ally_threatened) with reach and
                       limit; responses become negate / attack / move / status
  attack_reflect_chance, spell_reflect_chance (flags) -> trigger on:
                       incoming_attack / incoming_spell with reflect
  adds_<x>_damage_to_attacks -> trigger on: hit, 20% of the hit (rounded up,
                       at least 1) as that damage type

Re-runnable and idempotent: each step only acts on the old keys and words it
finds, so running it on migrated data changes nothing.

Usage:
    python3 tools/migrate_statuses.py                 dry run: says what would change
    python3 tools/migrate_statuses.py --write         rewrites statuses.json
    python3 tools/migrate_statuses.py --capture-words writes tools/fixtures/status_words.json
                                                      (once, BEFORE migrating)

After --write run `python3 tools/content_sync.py --write`.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATUSES = os.path.join(ROOT, "resources", "data", "statuses.json")
SPELLS = os.path.join(ROOT, "resources", "data", "spells.json")
COMBAT_MANAGER = os.path.join(ROOT, "scripts", "autoload", "combat_manager.gd")
VOCAB = os.path.join(ROOT, "scripts", "effects", "effect_vocab.gd")
WORDS_FIXTURE = os.path.join(ROOT, "tools", "fixtures", "status_words.json")

# ── The tables ───────────────────────────────────────────────────────────────

# Old `category` -> new `categories`. An empty list means the old word said
# nothing a cleanse or an immunity could use (it was the polarity, or how the
# status hurts, which its effects now say).
CATEGORY_TABLE = {
    "cc": ["control"],
    "control": ["control"],
    "dot": [], "dot_debuff": [], "debuff_dot": [], "hot": [], "debuff": [],
    "vulnerability": [], "delayed": [], "buff": [],
    # Slippery_Terrain: a slip caused by the ground. There is no ground
    # category, and it is not control (it only knocks you down sometimes).
    "terrain": [],
    "dot_cc": ["control"], "cc_dot": ["control"], "dot_disruption": ["control"],
    "aura": ["aura"], "stance": ["stance"], "transformation": ["transformation"],
    "shield": ["shield"], "stealth": ["stealth"],
    "immunity": ["blessing"], "resistance": ["blessing"], "divine": ["blessing"],
    "protection": ["shield"],
}

# `affliction` -> the category that says what it is.
AFFLICTION_CATEGORY = {"poison": "poison", "disease": "disease", "bleed": "wound"}

# The damage type in a "<type>_damage_per_turn..." word -> its element, for the
# elemental.<element> category. Types that are not an element (physical,
# poison, black) add nothing.
DAMAGE_TYPE_ELEMENT = {"fire": "fire", "space": "space", "lightning": "air",
                       "air": "air", "ice": "water", "water": "water",
                       "earth": "earth"}

# CombatUnit._get_status_stat_bonus, the table this migration deletes, as data.
# For each stat: (words, amount) rows. A row with several words is the GDScript
# `if "a" in effects or "b" in effects:` — it counts ONCE however many of its
# words a status carries. Read row by row against scripts/combat/combat_unit.gd
# at commit be82868 (lines 421-566).
STAT_TABLE = {
    "accuracy": [
        (("buffs_all_stats_considerably",), 8),
        (("attack_bonus",), 10),
        (("attack_penalty",), -10),
        (("melee_hit_chance_halved",), -40),
        (("accuracy_bonus",), 10),
        (("ranged_hit_chance_halved",), -40),
        (("minor_all_stats_bonus",), 5),
        (("all_stats_penalty",), -5),
    ],
    "armor": [
        (("buffs_all_stats_considerably",), 8),
        (("defense_bonus",), 10),
        (("defense_penalty",), -10),
        (("armor_reduced_50",), -20),
        (("armor_reduced",), -10),
        (("armor_bonus_minor",), 5),
        (("minor_all_stats_bonus",), 5),
        (("all_stats_penalty",), -5),
    ],
    "dodge": [
        (("buffs_all_stats_considerably",), 8),
        (("dodge_bonus",), 15),
        (("minor_dodge_bonus",), 5),
        (("evasion_bonus",), 25),
        (("dodge_penalty",), -15),
        (("major_dodge_bonus",), 30),
        (("finesse_bonus",), 5),
        (("minor_all_stats_bonus",), 5),
        (("all_stats_penalty",), -5),
    ],
    "movement": [
        (("speed_bonus",), 2),
        (("speed_penalty",), -1),
        # movement_reduced_50 is not a flat number: see MULTIPLY_WORDS.
        (("major_speed_boost",), 4),
    ],
    "initiative": [
        (("buffs_all_stats_considerably",), 8),
        (("initiative_bonus",), 5),
        (("initiative_penalty",), -5),
        (("finesse_bonus",), 3),
        (("awareness_penalty_major",), -8),
        (("awareness_bonus_major",), 8),
        (("minor_all_stats_bonus",), 3),
        (("all_stats_penalty",), -3),
    ],
    "damage": [
        (("buffs_all_stats_considerably", "buffs_two_highest_stats"), 8),
        (("melee_damage_bonus",), 5),
        (("damage_bonus",), 5),
        (("damage_reduction",), -5),
        (("strength_bonus",), 3),
        (("strength_bonus_major",), 8),
        (("ranged_damage_halved",), -10),
        (("damage_boost",), 15),
        (("minor_all_stats_bonus",), 3),
        (("all_stats_penalty",), -5),
    ],
    "crit_chance": [
        (("buffs_all_stats_considerably",), 5),
        (("critical_boost",), 10),
        (("critical_bonus_ranged",), 8),
        (("luck_bonus",), 5),
        (("minor_all_stats_bonus",), 3),
    ],
    "spellpower": [
        (("buffs_all_stats_considerably", "buffs_two_highest_stats"), 8),
        (("awareness_bonus", "focus_bonus"), 3),
        (("focus_bonus_major",), 8),
        (("focus_penalty",), -3),
        (("focus_penalty_major",), -8),
        (("awareness_penalty_major",), -5),
        (("awareness_bonus_major",), 5),
        (("minor_all_stats_bonus",), 3),
        (("all_stats_penalty",), -5),
    ],
}

# Words that become a `multiply` on a stat (a "Changed numbers" entry: the
# old table subtracted half the BASE movement; this halves the total).
MULTIPLY_WORDS = {"movement_reduced_50": ("movement", 0.5)}

# Spec section 7: a status whose word names an attribute AND carries
# bonus_amount / penalty_amount becomes a hold on that attribute, of that
# amount, instead of the table's stat numbers. (word -> attribute, mode)
NAMED_ATTRIBUTE_WORDS = {
    "strength_bonus": ("strength", "fortify"),
    "finesse_bonus": ("finesse", "fortify"),
    "focus_bonus": ("focus", "fortify"),
    "focus_penalty": ("focus", "drain"),
    "awareness_bonus": ("awareness", "fortify"),
    "constitution_bonus": ("constitution", "fortify"),
    "constitution_penalty": ("constitution", "drain"),
}

# The Constitution words were never in the stat table: CombatManager's
# _reconcile_constitution_hp turned them into +-10 max HP per point, with 2
# points when the status gave no amount. That function is deleted; the
# attribute hold does the same through the character sheet, so these become an
# attribute hold whether or not an amount is given (2 when it is not).
CONSTITUTION_DEFAULT_POINTS = 2

# range_bonus / range_penalty were in the table under "range", but no getter
# ever asked for "range", so they changed nothing (Precision's range, all of
# Range_Debuff). There is no stat.range path for them to become, and
# validate_data reports a word nothing reads, so they are dropped. Their old
# presence is kept in tools/fixtures/status_words.json.
UNREAD_STAT_WORDS = {"range_bonus", "range_penalty"}

# ── Task 5 tables ────────────────────────────────────────────────────────────

# Yes/no words. The reader of each only asks "does the unit carry a status with
# this word?", so the word becomes a flag of the same name. Exceptions, each
# listed in docs/plans/STATUS_MIGRATION_2026-11.md:
#   immobilized -> cannot_move   (same tooltip line, same movement block)
#   silenced    -> cannot_cast   (same tooltip line, same casting block)
#   immune_to_* / debuff_immunity -> immune:<...> flags (StatusRules.immune_to)
FLAG_FOR_WORD = {
    **{w: [w] for w in """
        attack_breaks_invisibility attack_damage_buff_when_ally_dies
        attack_reflect_chance attacks_closest_creature attacks_have_miss_chance
        breaks_on_offensive_action can_move_through_enemies cannot_act
        cannot_attack cannot_be_targeted cannot_cast cannot_deal_physical
        cannot_die cannot_make_weapon_attacks cannot_move cannot_target_enemies
        cannot_use_ranged charm_chance_on_enemy_melee_approach
        controlled_by_caster copies_absorb_attacks crit_vulnerability
        damage_on_move_attempt damage_taken_increase death_resistance
        disengaged_from_combat flee_from_source focus_save_on_damage
        forced_movement_toward_target grants_extra_action grants_flight
        hp_cannot_drop_below_1 hp_shield ignores_allegiance
        immune_to_ground_effects immune_to_melee_unless_flyer immune_to_ranged
        immune_to_terrain_hazards immune_to_water_terrain
        increase_burning_damage_dealt loses_flight must_attack_taunter
        next_attack_misses next_ranged_guaranteed_hit prevents_teleportation
        prone_chance_on_movement random_movement random_target
        ranged_damage_reduction remove_all_debuffs return_on_death_next_turn
        riposte_next_sword_attack rooted share_healing_75_percent
        skip_next_action skip_turn spell_damage_reduction spell_reflect_chance
        stealth_bonus stun_chance_on_hit treats_caster_as_ally will_not_attack
        will_not_attack_caster""".split()},
    "immobilized": ["cannot_move"],
    "silenced": ["cannot_cast"],
    # The four immunity words were `status in ["Charmed", "Dominated"]`-style
    # name lists in CombatManager._apply_status_effect.
    "immune_to_charm": ["immune:Charmed", "immune:Dominated"],
    "immune_to_fear": ["immune:Feared"],
    "immune_to_confusion": ["immune:Confused", "immune:Chaotic"],
    "debuff_immunity": ["immune:negative"],
}

# Name lists CombatManager kept in code (`status in [...]`, `has_status("X")
# or has_status("Y")`), now a flag on each named status.
NAME_FLAGS = {
    # The 15 hard-control names of _apply_status_effect (Stun, Fear and Charm
    # are in that list but are not statuses in statuses.json).
    **{n: ["breaks_concentration"] for n in """
        Stunned Confused Berserk Frozen Petrified Held Paralyzed Immobilized
        Dominated Chaotic""".split()},
    "Feared": ["breaks_concentration", "counts_as_demoralized"],
    # Also: damage from whoever charmed it breaks the charm (attack_unit).
    "Charmed": ["breaks_concentration", "breaks_on_damage_from_source"],
    # Invisible: gives stealth when it lands and when it ends, and stays
    # targetable-by-detection (cannot_be_targeted does not apply to it).
    "Invisible": ["grants_stealth"],
    "Lifelink": ["lifesteals_on_hit"],
    "Blood_Hunger": ["lifesteals_on_hit"],
    # `has_status("Demoralized") or "Feared" or "Gloomy"` in the skill
    # that only works on demoralised enemies.
    "Demoralized": ["counts_as_demoralized"],
    "Gloomy": ["counts_as_demoralized"],
}

# Words nothing in the game ever read. They are removed; the status keeps a
# `notes` line, and TODO section 16 lists them as mechanics never built.
# range_bonus / range_penalty were already dropped by Task 4 (they were in the
# old stat table but no getter asked for "range"), so only the fixture still
# has them.
UNBUILT_WORDS = """
    can_move cannot_target_spells fire_damage_per_turn_internal
    joins_party_permanently damage_increases_each_turn stat_penalties
    illusory_copies cannot_teleport cannot_flee random_attacks
    random_spellcasting relationship_bonus heal_50_percent_of_damage_dealt
    linked_to_ally return_with_20_percent_hp lifesteal_on_attacks cannot_fly
    knockback can_walk_on_water range_bonus range_penalty""".split()

STAT_ORDER = ["initiative", "movement", "accuracy", "dodge",
              "damage", "armor", "crit_chance", "spellpower"]

# Keys this task removes once converted.
REMOVED_KEYS = ["type", "category", "duration_type", "default_duration",
                "stackable", "grants_resistance", "grants_vulnerability",
                "bonus_amount", "penalty_amount"]

# The new keys, written right after name/icon in this order.
NEW_KEY_ORDER = ["name", "icon", "polarity", "categories", "scope",
                 "duration", "stacking", "flags", "while_active", "periodic",
                 "triggers", "save", "spread"]

# ── Task 6: behaviour ────────────────────────────────────────────────────────

# Keys Task 6 removes once converted (plus `effects` when it is empty).
BEHAVIOUR_KEYS = ["damage_per_turn", "damage_increase_per_turn", "heal_per_turn",
                  "retaliation", "reaction", "save_type", "summon_on_expire",
                  "expire_damage"]

# The words in `effects` an expiry hook read.
EXPIRE_WORDS = ["death_on_expire", "damage_on_expire", "bleed_on_expire"]

# spread_chance_to_float(), the deleted GDScript table: word -> percent.
SPREAD_CHANCE = {"low": 15, "medium": 30, "high": 50, "none": 0}

# _process_status_weapon_enchants' enchant_map: word -> the damage type it
# dealt (a school name is not a damage type: air dealt lightning).
ENCHANT_WORDS = {
    "adds_fire_damage_to_attacks": "fire", "adds_air_damage_to_attacks": "lightning",
    "adds_water_damage_to_attacks": "ice", "adds_earth_damage_to_attacks": "crushing",
    "adds_space_damage_to_attacks": "space", "adds_poison_damage_to_attacks": "poison",
    "adds_black_damage_to_attacks": "black", "adds_white_damage_to_attacks": "white",
}

# Before-resolution flags whose reader an intercepting trigger fully expresses:
# flag -> (on, chance percent). Both did "roll, then turn it back".
REFLECT_FLAGS = {"attack_reflect_chance": ("incoming_attack", 60),
                 "spell_reflect_chance": ("incoming_spell", 50)}

# The old Reaction.DEFAULT_MAX_PER_ROUND.
REACTION_DEFAULT_MAX = 3

# The fixed DC _process_status_effects rolled a save_at_end_of_turn against.
STATUS_SAVE_DC = 15


# ── Reading the game's own lists ─────────────────────────────────────────────

def _gd_list(path, name):
    src = open(path, encoding="utf-8").read()
    m = re.search(r"const %s\b[^=]*=\s*\[(.*?)\]" % name, src, re.S)
    if not m:
        raise RuntimeError(f"cannot read const {name} from {path}")
    return re.findall(r'"([^"]*)"', m.group(1))


def world_statuses():
    """Statuses that can live on the overworld map, so `scope: world`:
    the damage-over-time statuses CombatManager carries out of a fight
    (OVERWORLD_DOT_STATUSES), and every status an out_of_combat spell grants
    there (main_menu.gd _apply_overworld_spell reads `statuses_caused`)."""
    names = set(_gd_list(COMBAT_MANAGER, "OVERWORLD_DOT_STATUSES"))
    spells = json.load(open(SPELLS, encoding="utf-8"))
    table = spells.get("spells", spells)
    rows = table.values() if isinstance(table, dict) else table
    for s in rows:
        if isinstance(s, dict) and "out_of_combat" in s.get("tags", []):
            names.update(s.get("statuses_caused", []))
    return names


# ── One status ───────────────────────────────────────────────────────────────

def _modify(value, amount):
    mode = "fortify" if amount > 0 else "drain"
    return {"op": "modify", "value": value, "mode": mode, "amount": abs(amount)}


def _categories(s):
    cats = list(CATEGORY_TABLE[s["category"]]) if "category" in s else []
    aff = s.get("affliction")
    if aff in AFFLICTION_CATEGORY:
        cats.append(AFFLICTION_CATEGORY[aff])
    for word in s.get("effects", []):
        m = re.match(r"([a-z]+)_damage_per_turn", str(word))
        if m and m.group(1) in DAMAGE_TYPE_ELEMENT:
            cats.append("elemental." + DAMAGE_TYPE_ELEMENT[m.group(1)])
    # A dispel takes whatever is dispellable (StatusOps tag `magical`).
    if s.get("dispellable") is True:
        cats.append("magical")
    out = []
    for c in cats:
        if c not in out:
            out.append(c)
    return out


def _numbers(s, effects):
    """(while_active effects, words consumed) for this status's words:
    stat holds first (in STAT_ORDER), then the multiply, then attributes."""
    words = set(effects)
    has_amount = "bonus_amount" in s or "penalty_amount" in s
    amount_of = s.get("bonus_amount", s.get("penalty_amount"))

    # Spec section 7: named attribute words with an amount, and the
    # Constitution words always (see CONSTITUTION_DEFAULT_POINTS).
    attr_mods = []
    attr_words = set()
    for word, (attr, mode) in NAMED_ATTRIBUTE_WORDS.items():
        if word not in words:
            continue
        if attr == "constitution":
            n = amount_of if has_amount else CONSTITUTION_DEFAULT_POINTS
        elif has_amount:
            n = amount_of
        else:
            continue          # no amount: keeps the table's stat numbers
        attr_words.add(word)
        attr_mods.append({"op": "modify", "value": "attribute." + attr,
                          "mode": mode, "amount": n})

    # The table, stat by stat. A row counts once however many of its words
    # are present (the GDScript `or`).
    used = set(attr_words)
    stat_mods = []
    for stat in STAT_ORDER:
        total = 0
        for row_words, amount in STAT_TABLE[stat]:
            hit = [w for w in row_words if w in words and w not in attr_words]
            if hit:
                total += amount
                used.update(hit)
        if total != 0:
            stat_mods.append(_modify("stat." + stat, total))

    multiply_mods = []
    for word, (stat, factor) in MULTIPLY_WORDS.items():
        if word in words:
            multiply_mods.append({"op": "modify", "value": "stat." + stat,
                                  "mode": "multiply", "amount": factor})
            used.add(word)
    used |= words & UNREAD_STAT_WORDS
    return stat_mods + multiply_mods + attr_mods, used


def _resists(s):
    out = []
    for key, amount in s.get("grants_resistance", {}).items():
        out.append({"op": "modify", "value": "resist." + key, "mode": "fortify",
                    "amount": amount})
    for key, amount in s.get("grants_vulnerability", {}).items():
        out.append({"op": "modify", "value": "resist." + key, "mode": "drain",
                    "amount": amount})
    return out


def _flags_and_unbuilt(s, effects, old_words):
    """(flags, unbuilt words, words consumed) for this status's remaining
    words. `old_words` is the status's pre-migration word list from the
    fixture, which still names words an earlier task already dropped."""
    flags = list(s.get("flags", []))
    consumed = set()
    for word in effects:
        for flag in FLAG_FOR_WORD.get(word, []):
            if flag not in flags:
                flags.append(flag)
        if word in FLAG_FOR_WORD or word in UNBUILT_WORDS:
            consumed.add(word)
    for flag in NAME_FLAGS.get(s.get("name"), []):
        if flag not in flags:
            flags.append(flag)
    unbuilt = []
    for word in list(old_words) + list(effects):
        if word in UNBUILT_WORDS and word not in unbuilt:
            unbuilt.append(word)
    return flags, unbuilt, consumed


def _whole(n):
    """2.0 -> 2, so the JSON says what was meant."""
    return int(n) if isinstance(n, float) and n.is_integer() else n


def _dot_type(effects):
    """The damage type of a <type>_damage_per_turn word, as _dot_element read
    it (physical when there is none)."""
    for word in effects:
        m = re.fullmatch(r"([a-z]+)_damage_per_turn", str(word))
        if m:
            return m.group(1)
    return "physical"


def _behaviour(s):
    """(new keys, keys to drop, words consumed, unbuilt notes) for Task 6."""
    new, unbuilt = {}, []
    effects = list(s.get("effects", []))
    used = set()
    periodic = []
    triggers = list(s.get("triggers", []))

    # Damage and healing over time.
    dot_words = [w for w in effects if re.fullmatch(r"[a-z]+_damage_per_turn", str(w))]
    used.update(dot_words)
    dpt = s.get("damage_per_turn", 0)
    if isinstance(dpt, (int, float)) and not isinstance(dpt, bool) and dpt > 0:
        tick = {"op": "damage", "amount": {"from": "status.value", "default": _whole(dpt)},
                "type": _dot_type(effects)}
        inc = s.get("damage_increase_per_turn", 0)
        if inc:
            tick["scale"] = {"per": "turn_active", "amount": _whole(inc)}
        periodic.append(tick)
    elif dot_words:
        unbuilt.append("%s (it has no damage_per_turn, so it never ticked)" % dot_words[0])
    hot = s.get("heal_per_turn", 0)
    used.add("heal_per_turn")
    if isinstance(hot, (int, float)) and not isinstance(hot, bool) and hot > 0:
        periodic.append({"op": "heal", "amount": _whole(hot)})
    if periodic:
        new["periodic"] = {"when": "turn_start", "effects": periodic}

    # Expiry.
    expire = []
    if "death_on_expire" in effects:
        expire.append({"op": "damage", "amount": {"pct_of": "target.max_hp", "value": 1000},
                       "type": "black"})
    if "damage_on_expire" in effects:
        expire.append({"op": "damage", "amount": _whole(s.get("expire_damage", 20)),
                       "type": "physical"})
    if "bleed_on_expire" in effects:
        expire.append({"op": "status", "action": "apply", "status": "Bleeding", "duration": 3})
    if s.get("summon_on_expire"):
        expire.append({"op": "summon", "as": s["summon_on_expire"], "owner": "target"})
    used.update(EXPIRE_WORDS)
    if expire:
        triggers.append({"on": "expire", "effects": expire})

    # Retaliation.
    r = s.get("retaliation")
    if r:
        element = r.get("element", "physical")
        fx = []
        if r.get("damage"):
            fx.append({"op": "damage", "to": "source", "type": element,
                       "amount": {"from": "status.value", "add": _whole(r["damage"])}})
        if r.get("reflect_pct"):
            fx.append({"op": "damage", "to": "source", "type": element,
                       "amount": {"from": "event.damage", "pct": _whole(r["reflect_pct"])}})
        if r.get("status"):
            give = {"op": "status", "action": "apply", "status": r["status"],
                    "duration": _whole(r.get("status_duration", 1)), "to": "source",
                    "if": [{"target_lacks": r["status"]}]}
            chance = float(r.get("status_chance", 1.0))
            if chance < 1.0:
                give["chance"] = _whole(round(chance * 100, 6))
            fx.append(give)
        t = {"on": "struck"}
        if r.get("range", "melee") == "melee":
            t["reach"] = 1
        t["effects"] = fx
        triggers.append(t)

    # Weapon enchants.
    for word, dtype in ENCHANT_WORDS.items():
        if word in effects:
            used.add(word)
            triggers.append({"on": "hit", "effects": [
                {"op": "damage", "to": "source", "type": dtype,
                 "amount": {"from": "event.damage", "pct": 20, "round": "up", "min": 1}}]})

    # Reactions.
    rx = s.get("reaction")
    if rx:
        fx = []
        for resp in rx.get("responses", []):
            if resp == "auto_dodge":
                fx.append({"op": "negate"})
            elif resp == "attack":
                a = {"op": "attack", "target": "source"}
                mult = float(rx.get("damage_mult", 1.0))
                if abs(mult - 1.0) > 1e-9:
                    a["power_pct"] = _whole(round(mult * 100, 6))
                fx.append(a)
            elif resp == "reposition":
                fx.append({"op": "move", "to": "caster",
                           "mode": rx.get("reposition_mode", "scatter"),
                           "tiles": _whole(rx.get("reposition_tiles", 1))})
            elif resp == "status":
                fx.append({"op": "status", "action": "apply", "status": rx["status"],
                           "duration": _whole(rx.get("status_duration", 1)), "to": "source"})
            else:
                raise RuntimeError(f"{s.get('name')}: unknown reaction response {resp}")
        t = {"on": rx["trigger"]}
        if "reach" in rx:
            t["reach"] = _whole(rx["reach"])
        lim = {"per": "turn", "count": _whole(rx.get("max_per_round", REACTION_DEFAULT_MAX))}
        if rx.get("once_per_attacker"):
            lim["once_per_source"] = True
        t["limit"] = lim
        t["effects"] = fx
        triggers.append(t)

    # Reflections, from flags.
    flags = list(s.get("flags", []))
    for flag, (on, chance) in REFLECT_FLAGS.items():
        if flag in flags:
            flags.remove(flag)
            triggers.append({"on": on, "chance": chance, "effects": [{"op": "reflect"}]})
    if flags != list(s.get("flags", [])):
        new["flags"] = flags

    if triggers != list(s.get("triggers", [])):
        new["triggers"] = triggers

    # The status's own save.
    used.add("save_at_end_of_turn")
    if "save_at_end_of_turn" in effects:
        new["save"] = {"stat": str(s.get("save_type", "Constitution")).lower(),
                       "dc": STATUS_SAVE_DC, "when": "turn_start"}
    elif s.get("save_type"):
        unbuilt.append("save_type %s (nothing ever rolled it)" % s["save_type"])

    # Spread.
    sp = s.get("spread")
    if sp and "to" not in sp:
        out = {"to": "adjacent"}
        rng = sp.get("range", "melee")
        if isinstance(rng, (int, float)) and int(rng) > 1:
            out["reach"] = int(rng)
        out["chance"] = SPREAD_CHANCE[sp.get("chance", "none")]
        out["when"] = "turn_start"
        new["spread"] = out
        for k in sp:
            if k not in ("chance", "range"):
                unbuilt.append("spread.%s" % k)

    return new, used, unbuilt


def migrate_one(s, world, old_words=()):
    """Return the migrated copy of status `s` (a dict); `s` is not changed."""
    new = {}
    if "type" in s:
        new["polarity"] = {"buff": "positive", "debuff": "negative"}[s["type"]]
    if "category" in s:
        new["categories"] = _categories(s)
    if "scope" not in s:
        new["scope"] = "world" if s.get("name") in world else "combat"
    if "duration_type" in s:
        kind = "turns" if s["duration_type"] == "fixed" else s["duration_type"]
        dur = {"kind": kind}
        if s.get("default_duration") is not None:
            dur["base"] = s["default_duration"]
        new["duration"] = dur
    if "stacking" not in s:
        new["stacking"] = {"mode": "independent" if s.get("stackable") is True
                           else "refresh"}

    effects = list(s.get("effects", []))
    held, used = _numbers(s, effects)
    held += _resists(s)
    if held:
        new["while_active"] = list(s.get("while_active", [])) + held

    flags, unbuilt, flagged = _flags_and_unbuilt(
        s, [w for w in effects if w not in used], old_words)
    used = used | flagged
    if flags:
        new["flags"] = flags
    if unbuilt and not str(s.get("notes", "")).startswith("Unbuilt:"):
        # Keep a note the owner already wrote; add ours after it.
        note = "Unbuilt: " + ", ".join(unbuilt)
        new["notes"] = (str(s["notes"]) + " " + note) if s.get("notes") else note

    # Task 6: behaviour. Runs on the status as it stands after the steps
    # above, so it sees their flags.
    staged = dict(s)
    staged.update(new)
    beh, beh_used, beh_unbuilt = _behaviour(staged)
    new.update(beh)
    used = used | beh_used
    note6 = "Unbuilt (stage 2b Task 6): " + "; ".join(beh_unbuilt)
    if beh_unbuilt and note6 not in str(new.get("notes", s.get("notes", ""))):
        old_note = str(new.get("notes", s.get("notes", "")))
        new["notes"] = (old_note + " " + note6) if old_note else note6

    out = {}
    merged = dict(s)
    merged.update(new)
    for key in NEW_KEY_ORDER:
        if key in merged:
            out[key] = merged[key]
    for key, value in merged.items():
        if key in out or key in REMOVED_KEYS or key in BEHAVIOUR_KEYS:
            continue
        if key == "effects":
            left = [w for w in effects if w not in used]
            if left:
                out["effects"] = left
            continue
        out[key] = value
    if out.get("flags") == []:
        del out["flags"]          # Task 6 turned the last flag into a trigger
    return out


# ── Files ────────────────────────────────────────────────────────────────────

def _load():
    with open(STATUSES, encoding="utf-8") as fh:
        text = fh.read()
    return json.loads(text), ("\t" if "\n\t" in text else 2)


def _dump(doc, indent):
    return json.dumps(doc, indent=indent, ensure_ascii=False) + "\n"


def migrate(doc):
    world = world_statuses()
    doc = dict(doc)
    old = {}
    if os.path.exists(WORDS_FIXTURE):
        with open(WORDS_FIXTURE, encoding="utf-8") as fh:
            old = json.load(fh).get("statuses", {})
    doc["statuses"] = [
        migrate_one(s, world, old.get(s.get("name"), {}).get("effects", []))
        for s in doc["statuses"]]
    return doc


def capture_words():
    """Every status's original `effects` list and every legacy key, before
    any of it is migrated away. Later tasks read this to know what a status
    used to say."""
    if os.path.exists(WORDS_FIXTURE):
        sys.exit(f"{WORDS_FIXTURE} already exists; it is a pre-migration record")
    doc, _ = _load()
    legacy = _gd_list(VOCAB, "LEGACY_STATUS_FIELDS")
    out = {"_about": "Each status's effects words and legacy keys BEFORE the "
                     "stage-2b migration (captured by tools/migrate_statuses.py "
                     "--capture-words). A record; never rewritten.",
           "statuses": {}}
    for s in doc["statuses"]:
        if "polarity" in s:
            sys.exit("statuses.json is already (partly) migrated; refusing to capture")
        out["statuses"][s["name"]] = {
            "effects": list(s.get("effects", [])),
            "legacy": {k: s[k] for k in legacy if k in s},
        }
    os.makedirs(os.path.dirname(WORDS_FIXTURE), exist_ok=True)
    with open(WORDS_FIXTURE, "w", encoding="utf-8") as fh:
        fh.write(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {WORDS_FIXTURE} ({len(out['statuses'])} statuses)")


def main(argv):
    if "--capture-words" in argv:
        capture_words()
        return 0
    doc, indent = _load()
    new = migrate(doc)
    before, after = _dump(doc, indent), _dump(new, indent)
    changed = sum(1 for a, b in zip(doc["statuses"], new["statuses"]) if a != b)
    if before == after:
        print("statuses.json is already migrated; nothing to do")
        return 0
    print(f"{changed} of {len(new['statuses'])} statuses change")
    if "--write" in argv:
        with open(STATUSES, "w", encoding="utf-8") as fh:
            fh.write(after)
        print("wrote", STATUSES, "- now run: python3 tools/content_sync.py --write")
    else:
        print("dry run; pass --write to apply")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
