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

This file is extended by later tasks (5: flags, 6: behaviour). Task 4 — this
part — moves the METADATA and every NUMBER:

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
# ever asked for "range", so they changed nothing. They stay as words; there is
# no stat.range path for them to become (TODO: Task 5/6 or a ruling).
UNREAD_STAT_WORDS = {"range_bonus", "range_penalty"}

STAT_ORDER = ["initiative", "movement", "accuracy", "dodge",
              "damage", "armor", "crit_chance", "spellpower"]

# Keys this task removes once converted.
REMOVED_KEYS = ["type", "category", "duration_type", "default_duration",
                "stackable", "grants_resistance", "grants_vulnerability",
                "bonus_amount", "penalty_amount"]

# The new keys, written right after name/icon in this order.
NEW_KEY_ORDER = ["name", "icon", "polarity", "categories", "scope",
                 "duration", "stacking", "while_active"]


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


def migrate_one(s, world):
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

    out = {}
    merged = dict(s)
    merged.update(new)
    for key in NEW_KEY_ORDER:
        if key in merged:
            out[key] = merged[key]
    for key, value in merged.items():
        if key in out or key in REMOVED_KEYS:
            continue
        if key == "effects":
            left = [w for w in effects if w not in used]
            if left:
                out["effects"] = left
            continue
        out[key] = value
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
    doc["statuses"] = [migrate_one(s, world) for s in doc["statuses"]]
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
