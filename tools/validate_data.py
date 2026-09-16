#!/usr/bin/env python3
"""Cross-reference validator for Six Worlds JSON data.

Checks that every id referenced by one data file actually exists in another:
events -> encounters / shops / items / spells / traits / skills / wounds / companions,
map configs -> events / encounters, shops -> items / spells, companions -> everything,
and code -> perk ids / status names.

Run from anywhere:  python3 tools/validate_data.py
Exit code 1 if any dangling reference is found, so it can gate a commit.
"""
import json
import glob
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return json.load(fh)


# ── databases ────────────────────────────────────────────────────────────────
items = {k for k in load("resources/data/items.json")["items"] if not k.startswith("_")}
spells = {k for k in load("resources/data/spells.json")["spells"] if not k.startswith("_")}
statuses = {s["name"] for s in load("resources/data/statuses.json")["statuses"]}
shops = {k: v for k, v in load("resources/data/shops.json")["shops"].items() if not k.startswith("_")}
traits = {k for k in load("resources/data/traits.json") if not k.startswith("_")}
skills = {k for k in load("resources/data/skills.json")["skills"] if not k.startswith("_")}
races_data = load("resources/data/races.json")
races = {k for k in races_data["races"] if not k.startswith("_")}
backgrounds = {k for k in races_data["backgrounds"] if not k.startswith("_")}

try:
    ammo_raw = load("resources/data/ammo.json")
    ammo = {k for k in (ammo_raw.get("ammo_types") or ammo_raw) if not k.startswith("_")}
except Exception:
    ammo = set()

_comps = load("resources/data/companions.json")["companions"]
companions = {c["id"]: c for c in (_comps.values() if isinstance(_comps, dict) else _comps)}

archetypes, encounters = {}, {}
for path in glob.glob(os.path.join(ROOT, "resources/data/enemies/*_archetypes.json")):
    for k, v in json.load(open(path, encoding="utf-8"))["archetypes"].items():
        if not k.startswith("_"):
            archetypes[k] = (v, os.path.basename(path))
for path in glob.glob(os.path.join(ROOT, "resources/data/enemies/*_encounters.json")):
    for k, v in json.load(open(path, encoding="utf-8"))["encounters"].items():
        if not k.startswith("_"):
            encounters[k] = (v, os.path.basename(path))

events = {}
for path in glob.glob(os.path.join(ROOT, "resources/data/events/*_events.json")):
    for k, v in json.load(open(path, encoding="utf-8"))["events"].items():
        if not k.startswith("_"):
            events[k] = (v, os.path.basename(path))

# Reward tokens resolved at runtime rather than looked up in items.json
RUNTIME_TOKENS = {
    "spell_random", "spell_random_white", "spell_random_black",
    "item_random", "item_random_scaled",
}
ATTRIBUTES = {"strength", "constitution", "finesse", "focus", "awareness", "charm", "luck"}
ELEMENTS = {"space", "air", "fire", "water", "earth"}
KARMA_REALMS = {"hell", "hungry_ghost", "animal", "human", "asura", "god"}

_event_src = open(os.path.join(ROOT, "scripts/autoload/event_manager.gd"), encoding="utf-8").read()

# Derived from the source rather than hardcoded, so the list cannot drift out of
# date as handlers are added: every `if "x" in rewards` plus the trait loop's
# `for key in [...]` list.
HANDLED_REWARD_KEYS = set(re.findall(r'"([a-z_]+)" in rewards', _event_src))
for _list in re.findall(r"for key in \[([^\]]+)\]", _event_src):
    HANDLED_REWARD_KEYS |= set(re.findall(r'"([a-z_]+)"', _list))
for _list in re.findall(r"for gold_key in \[([^\]]+)\]", _event_src):
    HANDLED_REWARD_KEYS |= set(re.findall(r'"([a-z_]+)"', _list))

# The tokens _resolve_gold_reward() recognises; anything else resolves to 0.
_m_gold = re.search(r"func _resolve_gold_reward.*?\n(?:func |\Z)", _event_src, re.S)
GOLD_REWARD_TOKENS = set(re.findall(r'"([a-z_]+)":\s*return', _m_gold.group(0))) if _m_gold else set()

# hp_loss tiers, parsed from the match arms so the two cannot drift apart.
_m_hp = re.search(r'if "hp_loss" in rewards:.*?var party', _event_src, re.S)
HP_LOSS_TIERS = set(re.findall(r'"(\w+)"(?=[,:])', _m_hp.group(0))) - {"amount", "target"} if _m_hp else set()

# Event triggers the overworld actually rolls for. An event with any other
# trigger is unreachable — nothing queries for it.
EVENT_TRIGGERS = {"camp", "trait", "relationship"}

# Relationship bands, read from the system rather than restated here.
_rel_src = open(os.path.join(ROOT, "scripts/autoload/relationship_system.gd"), encoding="utf-8").read()
RELATIONSHIP_BANDS = set(re.findall(r'"id":\s*"(\w+)"', _rel_src))

_wound_src = open(os.path.join(ROOT, "scripts/autoload/wound_system.gd"), encoding="utf-8").read()
_m = re.search(r"const WOUND_TYPES: Dictionary = \{(.*?)\n\}", _wound_src, re.S)
WOUND_TYPES = set(re.findall(r'^\t"([a-z_]+)":', _m.group(1), re.M)) if _m else set()

errors = []


def err(category, message):
    errors.append((category, message))


def item_ok(iid):
    if not isinstance(iid, str):
        return True
    return iid in items or iid in ammo or iid in RUNTIME_TOKENS


# ── events ───────────────────────────────────────────────────────────────────
OUTCOME_KEYS = {
    "type", "text", "rewards", "karma", "cost", "enemy_group", "difficulty",
    "shop_id", "shop_modifier", "companion_id", "companion_pool", "free",
    "follow_up_event", "on_victory", "set_flags", "register_quest",
    "defeat_boss", "roll_result", "enabled_by",
}


def check_outcome(outcome, ctx, depth=0):
    if not isinstance(outcome, dict) or depth > 5:
        return

    # Same rule as reward keys, one level up: an outcome key nothing reads is a
    # promise the event cannot keep. Three hell outcomes carried a `damage`
    # block this way and dealt none.
    for key in outcome:
        if key not in OUTCOME_KEYS:
            err("event->outcome_key",
                f"{ctx}: outcome key '{key}' is not read by event_manager "
                f"(HP damage belongs in rewards.hp_loss; fights use enemy_group)")

    otype = outcome.get("type", "text")

    if otype == "combat" and outcome.get("enemy_group", "") not in encounters:
        err("event->enemy_group", f"{ctx}: enemy_group '{outcome.get('enemy_group', '')}' unknown")
    if otype == "shop" and outcome.get("shop_id", "") not in shops:
        err("event->shop", f"{ctx}: shop_id '{outcome.get('shop_id', '')}' unknown")
    if otype == "recruit_companion":
        cid = outcome.get("companion_id", "")
        if cid and cid != "random" and cid not in companions:
            err("event->companion", f"{ctx}: companion_id '{cid}' unknown")
        for pooled in outcome.get("companion_pool", []):
            if pooled not in companions:
                err("event->companion", f"{ctx}: pool companion '{pooled}' unknown")

    follow_up = outcome.get("follow_up_event", "")
    if follow_up and follow_up not in events:
        err("event->follow_up", f"{ctx}: follow_up_event '{follow_up}' unknown")

    on_victory = outcome.get("on_victory")
    if isinstance(on_victory, dict) and on_victory:
        check_outcome(on_victory, ctx + " on_victory", depth + 1)

    for realm in outcome.get("karma", {}):
        if realm not in KARMA_REALMS:
            err("event->karma", f"{ctx}: karma realm '{realm}' invalid")

    rewards = outcome.get("rewards", {})
    if not isinstance(rewards, dict):
        return

    for iid in rewards.get("items", []):
        if not item_ok(iid):
            err("event->item", f"{ctx}: reward item '{iid}' unknown")

    wound = rewards.get("wound", {})
    if isinstance(wound, dict) and wound.get("id") and wound["id"] not in WOUND_TYPES:
        err("event->wound", f"{ctx}: wound id '{wound['id']}' unknown")

    skill_up = rewards.get("skill_up", {})
    if isinstance(skill_up, dict) and skill_up.get("skill") and skill_up["skill"] not in skills:
        err("event->skill", f"{ctx}: skill_up '{skill_up['skill']}' unknown")

    for key in ("add_trait", "remove_trait", "add_traits", "remove_traits"):
        value = rewards.get(key)
        if value is None:
            continue
        for entry in (value if isinstance(value, list) else [value]):
            tid = entry if isinstance(entry, str) else entry.get("id", "")
            if tid and tid not in traits:
                err("event->trait", f"{ctx}: {key} '{tid}' unknown")

    pressure = rewards.get("pressure")
    if pressure:
        for entry in (pressure if isinstance(pressure, list) else [pressure]):
            if entry.get("element", "") not in ELEMENTS:
                err("event->pressure", f"{ctx}: pressure element '{entry.get('element', '')}' invalid")

    # A reward key no handler reads is a silent no-op: the event promises the
    # player something and delivers nothing. `gold_reward` sat unread in six
    # hell outcomes this way, including the arena you fight in for money.
    for key in rewards:
        if key not in HANDLED_REWARD_KEYS:
            err("event->reward_key",
                f"{ctx}: reward key '{key}' has no handler in event_manager.apply_outcome()")

    # hp_loss tiers the handler does not recognise fall through to a 20% default,
    # which is silently not what the author asked for.
    hp_loss = rewards.get("hp_loss")
    if isinstance(hp_loss, dict):
        amount = str(hp_loss.get("amount", ""))
        if amount and amount not in HP_LOSS_TIERS:
            err("event->hp_loss",
                f"{ctx}: hp_loss amount '{amount}' unknown "
                f"(known: {', '.join(sorted(HP_LOSS_TIERS))})")

    # Token-valued gold must be a token _resolve_gold_reward() recognises,
    # otherwise it resolves to 0.
    for key in ("gold", "gold_reward"):
        value = rewards.get(key)
        if isinstance(value, str) and value not in GOLD_REWARD_TOKENS:
            err("event->gold_token",
                f"{ctx}: gold token '{value}' unknown — pays nothing "
                f"(known: {', '.join(sorted(GOLD_REWARD_TOKENS))})")


def check_requirements(reqs, ctx):
    if not isinstance(reqs, dict):
        return
    roll = reqs.get("roll")
    if isinstance(roll, dict):
        # event_manager reads roll_req.difficulty directly; any other spelling
        # (dc_tier, dc, tier) crashes or silently misreads the check.
        if "difficulty" not in roll:
            err("event->roll_shape",
                f"{ctx}: roll requirement has no 'difficulty' key (found {sorted(roll)})")
        if "attribute" not in roll and "skill" not in roll:
            err("event->roll_shape",
                f"{ctx}: roll requirement names neither 'attribute' nor 'skill'")
        if roll.get("attribute") and roll["attribute"] not in ATTRIBUTES:
            err("event->roll_attr", f"{ctx}: roll attribute '{roll['attribute']}' unknown")
        if roll.get("skill") and roll["skill"] not in skills:
            err("event->roll_skill", f"{ctx}: roll skill '{roll['skill']}' unknown")
    for trait_key in ("trait", "not_trait"):
        tid = reqs.get(trait_key, "")
        if tid and tid not in traits:
            err("event->req_trait", f"{ctx}: {trait_key} '{tid}' unknown")
    for skill in reqs.get("skills", {}):
        if skill not in skills:
            err("event->req_skill", f"{ctx}: requirement skill '{skill}' unknown")
    for attr in reqs.get("attributes", {}):
        if attr not in ATTRIBUTES:
            err("event->req_attr", f"{ctx}: requirement attribute '{attr}' invalid")
    for key in ("trait", "not_trait"):
        tid = reqs.get(key, "")
        if tid and tid not in traits:
            err("event->req_trait", f"{ctx}: {key} '{tid}' unknown")
    roll = reqs.get("roll", {})
    if roll:
        attr, skill = roll.get("attribute", ""), roll.get("skill", "")
        if attr and attr not in ATTRIBUTES:
            err("event->roll", f"{ctx}: roll attribute '{attr}' invalid")
        if skill and skill not in skills:
            err("event->roll", f"{ctx}: roll skill '{skill}' unknown")
        if not attr and not skill:
            err("event->roll", f"{ctx}: roll has neither attribute nor skill")


CHOICE_KEYS = {
    "id", "text", "type", "requirements", "outcome", "outcome_success",
    "outcome_failure", "cost", "prerequisite", "once", "hidden_until",
    "flavor", "note", "comment",
}

for eid, (event, src) in events.items():
    # Trigger-gated events must name something that exists, or they can never fire.
    trigger = event.get("trigger", "")
    if trigger and trigger not in EVENT_TRIGGERS:
        err("event->trigger", f"{src}:{eid}: unknown trigger '{trigger}'")
    if trigger == "trait":
        req = event.get("requires_trait", "")
        if not req:
            err("event->trigger", f"{src}:{eid}: trait event has no 'requires_trait'")
        elif req not in traits:
            err("event->trigger", f"{src}:{eid}: requires_trait '{req}' unknown")
    if trigger == "relationship":
        band = event.get("requires_band", "")
        if not band:
            err("event->trigger", f"{src}:{eid}: relationship event has no 'requires_band'")
        elif band not in RELATIONSHIP_BANDS:
            err("event->trigger",
                f"{src}:{eid}: requires_band '{band}' is not a band "
                f"(known: {', '.join(sorted(RELATIONSHIP_BANDS))})")

    for choice in event.get("choices", []):
        ctx = f"{src}:{eid}:{choice.get('id', choice.get('text', '?')[:20])}"
        # A choice key nothing reads is silently dropped — a roll branch written
        # as "success" instead of "outcome_success" simply never resolves.
        for key in choice:
            if key not in CHOICE_KEYS:
                err("event->choice_key",
                    f"{ctx}: choice key '{key}' is not read by event_manager "
                    f"(roll branches are 'outcome_success'/'outcome_failure')")
        check_requirements(choice.get("requirements", {}), ctx)
        for key in ("outcome", "outcome_success", "outcome_failure"):
            if key in choice:
                check_outcome(choice[key], f"{ctx}:{key}")

# ── perks -> traits ──────────────────────────────────────────────────────────
_perks_raw = load("resources/data/perks.json")
for _group in ("skill_perks", "cross_perks"):
    for _pid, _perk in _perks_raw.get(_group, {}).items():
        for _tid in _perk.get("grants_traits", []):
            if _tid not in traits:
                err("perk->trait", f"perks.json:{_pid}: grants_traits '{_tid}' unknown")

# ── shops ────────────────────────────────────────────────────────────────────
for sid, shop in shops.items():
    for iid in shop.get("items", {}):
        if not item_ok(iid):
            err("shop->item", f"shops.json:{sid}: item '{iid}' unknown")
    for entry in shop.get("spells", []):
        spid = entry if isinstance(entry, str) else entry.get("id", "")
        if spid and spid not in spells:
            err("shop->spell", f"shops.json:{sid}: spell '{spid}' unknown")
    for entry in shop.get("training", {}).get("skills", []):
        skill = entry if isinstance(entry, str) else entry.get("id", entry.get("skill", ""))
        if skill and skill not in skills:
            err("shop->training", f"shops.json:{sid}: training skill '{skill}' unknown")
    for cid in shop.get("available_companions", []):
        if cid not in companions:
            err("shop->companion", f"shops.json:{sid}: companion '{cid}' unknown")

# ── encounters -> archetypes ─────────────────────────────────────────────────
for eid, (enc, src) in encounters.items():
    entries = list(enc.get("enemies", []))
    for group in enc.get("groups", []):
        entries.extend(group.get("enemies", []))
    for entry in entries:
        aid = entry if isinstance(entry, str) else entry.get("archetype", "")
        if aid and aid not in archetypes:
            err("encounter->archetype", f"{src}:{eid}: archetype '{aid}' unknown")

# ── archetypes -> spells ─────────────────────────────────────────────────────
for aid, (arch, src) in archetypes.items():
    for key in ("spells", "guaranteed_spells"):
        for entry in arch.get(key, []):
            spid = entry if isinstance(entry, str) else entry.get("id", "")
            if spid and spid not in spells:
                err("archetype->spell", f"{src}:{aid}: {key} '{spid}' unknown")
    for iid in arch.get("guaranteed_drops", []):
        if not item_ok(iid):
            err("archetype->item", f"{src}:{aid}: guaranteed_drop '{iid}' unknown")

# ── companions ───────────────────────────────────────────────────────────────
for cid, comp in companions.items():
    if comp.get("birth") and comp["birth"] not in races:
        err("companion->birth", f"companions.json:{cid}: birth '{comp['birth']}' unknown")
    if comp.get("background") and comp["background"] not in backgrounds:
        err("companion->background", f"companions.json:{cid}: background '{comp['background']}' unknown")
    for iid in list(comp.get("starting_equipment", {}).values()) + comp.get("fixed_items", []):
        if not item_ok(iid):
            err("companion->item", f"companions.json:{cid}: item '{iid}' unknown")
    known = comp.get("fixed_starter", {}).get("known_spells", [])
    for spid in comp.get("fixed_spells", []) + known:
        if spid not in spells:
            err("companion->spell", f"companions.json:{cid}: spell '{spid}' unknown")
    for tid in comp.get("traits", []) + comp.get("quirks", []):
        if tid not in traits:
            err("companion->trait", f"companions.json:{cid}: trait '{tid}' unknown")
    build = list(comp.get("build_weights", {})) + list(comp.get("fixed_starter", {}).get("skills", {}))
    for skill in build:
        if skill not in skills:
            err("companion->skill", f"companions.json:{cid}: skill '{skill}' unknown")

# ── quests: every step flag must be settable by some event ───────────────────
# A quest whose flag nothing sets can be accepted from the board and then sits
# in the journal forever, which is how all three hell quests originally shipped.
flag_setters = {}
for eid, (event, src) in events.items():
    for choice in event.get("choices", []):
        for key in ("outcome", "outcome_success", "outcome_failure"):
            outcome = choice.get(key)
            if not isinstance(outcome, dict):
                continue
            sources = [outcome.get("set_flags"), outcome.get("rewards", {}).get("flags")]
            victory = outcome.get("on_victory")
            if isinstance(victory, dict):
                sources.append(victory.get("set_flags"))
                sources.append(victory.get("rewards", {}).get("flags"))
            for block in sources:
                for flag in (block or {}):
                    flag_setters.setdefault(flag, []).append(f"{eid}:{choice.get('id', '?')}")

quests = load("resources/data/quests.json")["quests"]
for qid, quest in quests.items():
    if qid.startswith("_"):
        continue
    for step in quest.get("steps", []):
        flag = step.get("done_when", {}).get("flag", "")
        if flag and flag not in flag_setters:
            err("quest->flag", f"quests.json:{qid}: step flag '{flag}' is never set by any event")

# Choices hidden behind a prerequisite flag nothing sets can never be shown
for eid, (event, src) in events.items():
    for choice in event.get("choices", []):
        prereq = choice.get("prerequisite", {})
        flag = prereq.get("flag", "")
        if flag and flag not in flag_setters:
            err("event->prerequisite",
                f"{src}:{eid}:{choice.get('id', '?')}: prerequisite flag '{flag}' is never set")


# ── races and backgrounds ────────────────────────────────────────────────────
for group in ("races", "backgrounds"):
    for key, entry in races_data[group].items():
        if key.startswith("_") or not isinstance(entry, dict):
            continue
        for skill in entry.get("starting_skills", {}):
            if skill not in skills:
                err(f"{group[:-1]}->skill", f"races.json:{key}: starting skill '{skill}' unknown")
        for tid in entry.get("starting_traits", []):
            if tid not in traits:
                err(f"{group[:-1]}->trait", f"races.json:{key}: starting trait '{tid}' unknown")
        equip = entry.get("starting_equipment", {})
        for field in ("base_weapon", "weapon_upgrade", "secondary_weapon"):
            iid = equip.get(field, "")
            if iid and not item_ok(iid):
                err(f"{group[:-1]}->item", f"races.json:{key}: {field} '{iid}' unknown")
        for iid in equip.get("items", []):
            if not item_ok(iid):
                err(f"{group[:-1]}->item", f"races.json:{key}: starting item '{iid}' unknown")
        for birth in entry.get("available_races", []):
            if birth not in races:
                err("background->birth", f"races.json:{key}: available_race '{birth}' unknown")


# ── map configs ──────────────────────────────────────────────────────────────
# NOTE: object_pools[zone] is a DICT keyed by "events"/"pickups"/"spell_schools",
# not a list. Treating it as a list silently skips every reference.
for path in sorted(glob.glob(os.path.join(ROOT, "resources/data/map_configs/*.json"))):
    cfg = json.load(open(path, encoding="utf-8"))
    base = os.path.basename(path)
    for zone, pools in cfg.get("object_pools", {}).items():
        if not isinstance(pools, dict):
            err("map->schema", f"{base}:{zone}: object_pools entry should be a dict")
            continue
        for obj in pools.get("events", []):
            if not isinstance(obj, dict):
                continue
            eid = obj.get("event_id", "")
            if eid and eid not in events:
                err("map->event", f"{base}:{zone}: event_id '{eid}' unknown")
        for obj in pools.get("pickups", []):
            if not isinstance(obj, dict):
                continue
            for reward in obj.get("rewards", []):
                if not isinstance(reward, dict):
                    continue
                value = reward.get("value")
                if reward.get("type") == "item" and isinstance(value, str) and not item_ok(value):
                    err("map->item", f"{base}:{zone}: pickup item '{value}' unknown")
                if reward.get("type") in ("item_random",) and isinstance(value, list):
                    for iid in value:
                        if not item_ok(iid):
                            err("map->item", f"{base}:{zone}: pickup item '{iid}' unknown")
    for landmark in cfg.get("fixed_landmarks", []):
        eid = landmark.get("event_id") or (landmark.get("data") or {}).get("event_id", "")
        if eid and eid not in events:
            err("map->event", f"{base}:landmark: event_id '{eid}' unknown")
    for zone, mobs in cfg.get("mob_pools", {}).items():
        for mob in (mobs if isinstance(mobs, list) else []):
            if not isinstance(mob, dict):
                continue
            group = mob.get("enemy_group", "")
            if group and group not in encounters:
                err("map->enemy_group", f"{base}:{zone}: enemy_group '{group}' unknown")

# ── code -> data ─────────────────────────────────────────────────────────────
perks_data = load("resources/data/perks.json")
perk_ids = set(perks_data.get("skill_perks", {})) | set(perks_data.get("cross_perks", {}))
for gd_path in glob.glob(os.path.join(ROOT, "scripts/**/*.gd"), recursive=True):
    src = open(gd_path, encoding="utf-8").read()
    rel = os.path.relpath(gd_path, ROOT)
    for match in re.finditer(r'(?:has_perk|_unit_has_perk|party_has_perk)\([^,)]*,?\s*"([a-z_0-9]+)"', src):
        if match.group(1) not in perk_ids:
            err("code->perk", f"{rel}: perk '{match.group(1)}' not in perks.json")
    for match in re.finditer(r'_apply_status_effect\([^,]+,\s*"([A-Za-z_]+)"', src):
        if match.group(1) not in statuses:
            err("code->status", f"{rel}: status '{match.group(1)}' not in statuses.json")

# ── data -> code ─────────────────────────────────────────────────────────────
# The checks above ask "does the id this code names exist in the data?". This
# section asks the reverse, which is where every silent failure in this project
# has actually lived: "does anything read the value this data declares?"
#
# A stat key, status behaviour string or shape name that no code reads is not a
# missing feature — it is a feature that looks present in the data, reviews as
# present, and does nothing. mental_resistance_pct, healing_pct, damage_pct,
# damage_reduction_pct and save_bonus were all in that state simultaneously.
#
# Values already known to be unread live in tools/vocabulary_baseline.json with
# a reason attached, so this check fails only on NEW drift. Shrink the baseline
# by wiring a consumer; never by adding a line without a reason.

_gd_source = "\n".join(
    open(p, encoding="utf-8").read()
    for p in glob.glob(os.path.join(ROOT, "scripts/**/*.gd"), recursive=True)
)
_baseline = load("tools/vocabulary_baseline.json")


def _read_by_code(value):
    """True when the literal appears anywhere in scripts/.

    Deliberately crude. It cannot see a name assembled at runtime, so a false
    "unread" is possible — that is what the baseline is for. What it does catch
    reliably is the common case: data declares a key and no source file ever
    mentions it.
    """
    return f'"{value}"' in _gd_source


def check_vocabulary(label, values, patterns=None):
    """patterns: %s-format strings, any one of which counts as a real read.

    base_bonuses needs them. Its keys share a namespace with derived stat names,
    so a bare literal search finds "mental_resistance_pct" in combat_stats.gd
    and calls the skill table read — while update_derived_stats never looks at
    it. Naming the access forms asks the real question.

    There are three legitimate ways to read one: the per-level dict directly
    (`bonus.get`/`bonus.has`/`bonus[...]`), or, for a `party_` key, through
    PartyBonuses, which resolves the best member across the party rather than
    reading one character's table.
    """
    accepted = set(_baseline.get(label, {}).get("values", []))
    for value in sorted(values):
        if value in accepted:
            continue
        if patterns:
            found = any((p % value) in _gd_source for p in patterns)
        else:
            found = _read_by_code(value)
        if not found:
            err("data->code", f"{label} '{value}' is declared in data but no code reads it")


# Stat keys paid out by the per-level skill tables.
_stat_keys = set()
for _skill, _tbl in perks_data.get("base_bonuses", {}).items():
    if _skill.startswith("_"):
        continue  # "_comment" section dividers are strings, not tables
    for _stats in _tbl.get("per_level", {}).values():
        _stat_keys.update(_stats)
# `bonus` is the per-level dict inside update_derived_stats; PartyBonuses is
# the path for `party_` keys, which are resolved across the party instead.
check_vocabulary("base_bonuses stat", _stat_keys, [
    'bonus.get("%s"',
    'bonus.has("%s"',
    'bonus["%s"]',
    'PartyBonuses.best("%s"',
    'for_character(member, "%s"',
])

# Behaviour strings on status definitions.
_status_effects = set()
_status_names = set()
for _s in load("resources/data/statuses.json")["statuses"]:
    _status_effects.update(str(e) for e in _s.get("effects", []))
    if _s.get("name"):
        _status_names.add(str(_s["name"]))
check_vocabulary("status effect", _status_effects)

# ── Spell damage and saves ───────────────────────────────────────────────────
#
# Two failures that leave no trace at runtime. A `damage` value the resolver
# cannot read is skipped by a type guard, so the spell deals nothing and says
# nothing — seven spells shipped that way, two of them 225-mana capstones. And
# `save` is a plausible misspelling of `save_type` that nothing reads, so the
# spell rolls no save while its description promises one.
_spells_all = load("resources/data/spells.json")["spells"]
_spells = {k: v for k, v in _spells_all.items()
           if not k.startswith("_") and isinstance(v, dict)}

_sd_src = open(os.path.join(ROOT, "scripts/combat/spell_damage.gd"), encoding="utf-8").read()
_m = re.search(r"const FORMULAS[^=]*=\s*\[(.*?)\]", _sd_src, re.S)
_formulas = set(re.findall(r'"([^"]+)"', _m.group(1))) if _m else set()
if not _formulas:
    err("data->code", "could not read SpellDamage.FORMULAS — spell damage unchecked")

_ss_src = open(os.path.join(ROOT, "scripts/combat/save_system.gd"), encoding="utf-8").read()
_m = re.search(r"const ATTRIBUTES[^=]*=\s*\[(.*?)\]", _ss_src, re.S)
_save_attrs = set(re.findall(r'"([^"]+)"', _m.group(1))) if _m else set()

for _sid, _sp in _spells.items():
    _dm = _sp.get("damage")
    if _dm is not None and not isinstance(_dm, (int, float)):
        if not isinstance(_dm, dict):
            err("data->code", f"spell '{_sid}' has {type(_dm).__name__} in `damage`; "
                "the resolver skips anything that is not a number or a formula block")
        elif _dm.get("formula") not in _formulas:
            err("data->code", f"spell '{_sid}' uses damage formula "
                f"'{_dm.get('formula')}', which is not in SpellDamage.FORMULAS — "
                "it would resolve to zero damage")
    if "save" in _sp:
        err("data->code", f"spell '{_sid}' uses `save`; the field is read as "
            "`save_type`, so this spell rolls no save at all")
    _st = _sp.get("save_type")
    if _st and _save_attrs and _st.lower() not in _save_attrs:
        err("data->code", f"spell '{_sid}' has save_type '{_st}', which is not a "
            "SaveSystem attribute — SaveSystem.roll() refuses it")
    if _sp.get("requires_status") and _sp["requires_status"] not in _status_names:
        err("data->code", f"spell '{_sid}' requires status "
            f"'{_sp['requires_status']}', which does not exist")


# ── Repositioning ────────────────────────────────────────────────────────────
#
# An unknown mode moves nobody while the effect reports success, which is the
# same silent failure the `damage` type guard produced.
_rp_src = open(os.path.join(ROOT, "scripts/combat/repositioning.gd"), encoding="utf-8").read()
_m = re.search(r"const MODES[^=]*=\s*\[(.*?)\]", _rp_src, re.S)
_modes = set(re.findall(r'"([^"]+)"', _m.group(1))) if _m else set()
if not _modes:
    err("data->code", "could not read Repositioning.MODES — reposition blocks unchecked")

for _sid, _sp in _spells.items():
    _rp = _sp.get("reposition")
    if not isinstance(_rp, dict):
        if _rp is not None:
            err("data->code", f"spell '{_sid}' has a non-object `reposition`")
        continue
    if _rp.get("mode") not in _modes:
        err("data->code", f"spell '{_sid}' uses reposition mode "
            f"'{_rp.get('mode')}', which is not in Repositioning.MODES — "
            "the unit would not move and the spell would report success")
    if _rp.get("mover") not in (None, "caster", "target"):
        err("data->code", f"spell '{_sid}' has mover '{_rp.get('mover')}'; "
            "only 'caster' and 'target' are resolved")


# ── Status operations ────────────────────────────────────────────────────────
#
# An unknown op or an unrecognised selector tag changes nothing while the spell
# reports success — the same silent shape as the damage and reposition guards.
_so_src = open(os.path.join(ROOT, "scripts/combat/status_ops.gd"), encoding="utf-8").read()
def _gd_list(src, name):
    m = re.search(r"const %s[^=]*=\s*\[(.*?)\]" % name, src, re.S)
    return set(re.findall(r'"([^"]+)"', m.group(1))) if m else set()

_ops = _gd_list(_so_src, "OPS")
_tags = _gd_list(_so_src, "TAGS")
if not _ops or not _tags:
    err("data->code", "could not read StatusOps.OPS/TAGS — status ops unchecked")

# Read from the resolver's own match arms rather than restated here, so a role
# added in code is a role the data may use, and one removed stops validating.
_role_src = open(os.path.join(ROOT, "scripts/autoload/combat_manager.gd"), encoding="utf-8").read()
_m_roles = re.search(r"func _units_for_role.*?\n\treturn \[target\]", _role_src, re.S)
_roles = set(re.findall(r'^\t\t"(\w+)":', _m_roles.group(0), re.M)) if _m_roles else set()
if not _roles:
    err("data->code", "could not read the roles from _units_for_role() — status "
        "op roles unchecked")
for _sid, _sp in _spells.items():
    for _op in _sp.get("status_ops", []):
        if _op.get("op") not in _ops:
            err("data->code", f"spell '{_sid}' uses status op '{_op.get('op')}', "
                "which is not in StatusOps.OPS — nothing would perform it")
        _sel = _op.get("select", {})
        if not _sel.get("names") and not _sel.get("tag"):
            err("data->code", f"spell '{_sid}' has a status op selecting neither "
                "names nor a tag, so it picks nothing")
        if _sel.get("tag") and _sel["tag"] not in _tags:
            err("data->code", f"spell '{_sid}' selects status tag "
                f"'{_sel['tag']}', which is not in StatusOps.TAGS")
        for _nm in _sel.get("names", []):
            if _nm not in _status_names:
                err("data->code", f"spell '{_sid}' selects status '{_nm}', "
                    "which does not exist")
        for _field in ("on", "from", "to"):
            if _op.get(_field) and _op[_field] not in _roles:
                err("data->code", f"spell '{_sid}' status op names role "
                    f"'{_op[_field]}' for `{_field}`, which is not resolved")

# `statuses_removed` mixes literal status names with group tags. Both must
# resolve, or the entry silently selects nothing.
for _sid, _sp in _spells.items():
    for _entry in _sp.get("statuses_removed", []):
        _e = str(_entry)
        if _e not in _tags and _e not in _status_names:
            err("data->code", f"spell '{_sid}' removes '{_e}', which is neither "
                "a status nor a StatusOps tag — it removes nothing")


# ── Resurrection ─────────────────────────────────────────────────────────────
_res_src = open(os.path.join(ROOT, "scripts/combat/resurrection.gd"), encoding="utf-8").read()
_tiers = _gd_list(_res_src, "TIERS")
_scopes = _gd_list(_res_src, "SCOPES")
if not _tiers or not _scopes:
    err("data->code", "could not read Resurrection.TIERS/SCOPES — unchecked")

for _sid, _sp in _spells.items():
    _rs = _sp.get("resurrection")
    if _rs is None:
        continue
    if not isinstance(_rs, dict):
        err("data->code", f"spell '{_sid}' has a non-object `resurrection`")
        continue
    if _rs.get("tier", "revive") not in _tiers:
        err("data->code", f"spell '{_sid}' uses resurrection tier "
            f"'{_rs.get('tier')}', which is not in Resurrection.TIERS")
    if _rs.get("scope", "single") not in _scopes:
        err("data->code", f"spell '{_sid}' uses resurrection scope "
            f"'{_rs.get('scope')}', which is not in Resurrection.SCOPES")
    if not isinstance(_rs.get("hp_pct", 100), int):
        err("data->code", f"spell '{_sid}' has a non-integer resurrection hp_pct")


# ── Save gates, kill rewards and resource operations ────────────────────────
_ro_src = open(os.path.join(ROOT, "scripts/combat/resource_ops.gd"), encoding="utf-8").read()
_res_modes = _gd_list(_ro_src, "MODES")
_res_kinds = set(re.findall(r'^\t"([a-z]+)":\s*\{"current"', _ro_src, re.M))
if not _res_modes or not _res_kinds:
    err("data->code", "could not read ResourceOps.MODES/RESOURCES — unchecked")

_gate_keys = {"statuses", "random_one_of", "damage", "damage_pct_of_max_hp",
              "instant_kill"}
for _sid, _sp in _spells.items():
    for _side in ("on_failed_save", "on_passed_save"):
        _branch = _sp.get(_side)
        if _branch is None:
            continue
        if not isinstance(_branch, dict):
            err("data->code", f"spell '{_sid}' has a non-object `{_side}`")
            continue
        if not _sp.get("save_type"):
            err("data->code", f"spell '{_sid}' declares `{_side}` but no "
                "`save_type`, so there is no roll to gate it on")
        for _k in _branch:
            if _k not in _gate_keys:
                err("data->code", f"spell '{_sid}' `{_side}` carries '{_k}', "
                    "which _apply_save_gated does not resolve")
        for _st in list(_branch.get("statuses", [])) + list(_branch.get("random_one_of", [])):
            if _st not in _status_names:
                err("data->code", f"spell '{_sid}' `{_side}` names status "
                    f"'{_st}', which does not exist")

    for _op in _sp.get("resource_ops", []):
        if _op.get("op") not in _res_modes:
            err("data->code", f"spell '{_sid}' uses resource op "
                f"'{_op.get('op')}', which is not in ResourceOps.MODES")
        if _op.get("resource") not in _res_kinds:
            err("data->code", f"spell '{_sid}' moves resource "
                f"'{_op.get('resource')}', which is not in ResourceOps.RESOURCES")
        if not _op.get("amount"):
            err("data->code", f"spell '{_sid}' has a resource op with no "
                "`amount`, so it moves nothing")

    _ok = _sp.get("on_kill")
    if _ok is not None and not isinstance(_ok, dict):
        err("data->code", f"spell '{_sid}' has a non-object `on_kill`")


# ── Translocation ───────────────────────────────────────────────────────────
_mm_src3 = open(os.path.join(ROOT, "scripts/autoload/map_manager.gd"), encoding="utf-8").read()
_HOWS = {"tile", "refuge", "excursion", "gate"}
for _sid, _sp in _spells.items():
    _tr = _sp.get("translocate")
    if _tr is None:
        continue
    if not isinstance(_tr, dict):
        err("data->code", f"spell '{_sid}' has a non-object `translocate`")
        continue
    if _tr.get("how") not in _HOWS:
        err("data->code", f"spell '{_sid}' translocates by '{_tr.get('how')}', "
            "which _apply_translocation does not resolve")
    if "out_of_combat" not in _sp.get("tags", []):
        err("data->code", f"spell '{_sid}' translocates but is not tagged "
            "out_of_combat, so it can never reach the map")
    # A tile destination has to be pointed at, or it has no destination.
    if _tr.get("how") == "tile" and _sp.get("map_target") != "tile":
        err("data->code", f"spell '{_sid}' translocates to a tile but declares "
            "no `map_target: tile`, so nothing would ever aim it")


# ── Mob effects ─────────────────────────────────────────────────────────────
_mm_src2 = open(os.path.join(ROOT, "scripts/autoload/map_manager.gd"), encoding="utf-8").read()
_m = re.search(r"const MOB_EFFECTS[^=]*=\s*\[(.*?)\]", _mm_src2, re.S)
_mob_effects = set(re.findall(r'"(\w+)"', _m.group(1))) if _m else set()
if not _mob_effects:
    err("data->code", "could not read MapManager.MOB_EFFECTS — unchecked")

for _sid, _sp in _spells.items():
    _me = _sp.get("mob_effect")
    if _me is None:
        continue
    if not isinstance(_me, dict):
        err("data->code", f"spell '{_sid}' has a non-object `mob_effect`")
        continue
    if _me.get("what") not in _mob_effects:
        err("data->code", f"spell '{_sid}' uses mob effect '{_me.get('what')}', "
            "which is not in MapManager.MOB_EFFECTS — nothing would happen")
    if "out_of_combat" not in _sp.get("tags", []):
        err("data->code", f"spell '{_sid}' declares a mob_effect but is not "
            "tagged out_of_combat, so it can never reach the map")


# ── The terrain vocabulary ──────────────────────────────────────────────────
#
# One list, shared by the overworld map and the battle grid. `id` is the
# contract with MapManager.Terrain and with every saved map, so it is the ids
# rather than the names that must stay put.
_terrain_data = load("resources/data/terrain.json")["terrain"]
_terrain_rows = {k: v for k, v in _terrain_data.items() if not k.startswith("_")}
_ground_src = open(os.path.join(ROOT, "scripts/combat/ground.gd"), encoding="utf-8").read()
_tile_types = _gd_list(_ground_src, "TILE_TYPES")
_hazards = _gd_list(_ground_src, "HAZARDS")
_obstacle_kinds = _gd_list(_ground_src, "OBSTACLES")

_seen_ids = {}
for _key, _row in _terrain_rows.items():
    _tid = _row.get("id")
    if not isinstance(_tid, int):
        err("data->code", f"terrain '{_key}' has no integer id")
        continue
    if _tid in _seen_ids:
        err("data->code", f"terrain '{_key}' and '{_seen_ids[_tid]}' share id {_tid} — "
            "saved maps store the id, so a collision silently rewrites ground")
    _seen_ids[_tid] = _key

    _battle = _row.get("battle")
    if not isinstance(_battle, dict):
        err("data->code", f"terrain '{_key}' has no `battle` block, so a block of "
            "it would generate featureless ground")
        continue
    if _battle.get("tile", "floor") not in _tile_types:
        err("data->code", f"terrain '{_key}' defaults its tiles to "
            f"'{_battle.get('tile')}', which is not a CombatGrid tile type")
    for _obs in _battle.get("obstacles", {}):
        if _obs not in _obstacle_kinds:
            err("data->code", f"terrain '{_key}' scatters '{_obs}', which is not "
                "a CombatGrid obstacle type")
    _haz = _battle.get("hazard")
    if isinstance(_haz, dict) and _haz.get("effect", "none") not in _hazards:
        err("data->code", f"terrain '{_key}' carries hazard "
            f"'{_haz.get('effect')}', which is not a CombatGrid terrain effect")

_expected = set(range(len(_terrain_rows)))
if set(_seen_ids) != _expected:
    err("data->code", "terrain ids are not contiguous from 0: got %s"
        % sorted(_seen_ids))


# ── Divination reveals ──────────────────────────────────────────────────────
_mm_reveal = open(os.path.join(ROOT, "scripts/autoload/map_manager.gd"), encoding="utf-8").read()
_m = re.search(r"const REVEAL_GROUPS[^=]*=\s*\{(.*?)\n\}", _mm_reveal, re.S)
_groups = set(re.findall(r'"(\w+)":\s*\[', _m.group(1))) if _m else set()
_reveal_what = _groups | {"terrain", "mobs", "all"}
if not _groups:
    err("data->code", "could not read MapManager.REVEAL_GROUPS — reveals unchecked")

for _sid, _sp in _spells.items():
    _rv = _sp.get("reveal")
    if _rv is None:
        continue
    if not isinstance(_rv, dict):
        err("data->code", f"spell '{_sid}' has a non-object `reveal`")
        continue
    if _rv.get("what") not in _reveal_what:
        err("data->code", f"spell '{_sid}' reveals '{_rv.get('what')}', which "
            "MapManager.reveal() does not recognise — it would show nothing")
    if not _rv.get("radius") and not _rv.get("nearest"):
        err("data->code", f"spell '{_sid}' has a reveal with neither a radius "
            "nor a `nearest` count, so it reaches nowhere")
    if "out_of_combat" not in _sp.get("tags", []):
        err("data->code", f"spell '{_sid}' declares a reveal but is not tagged "
            "out_of_combat, so it can never be cast where the map is")


# ── Movement abilities ──────────────────────────────────────────────────────
#
# An ability name terrain never asks about grants nothing. TERRAIN_ABILITIES
# names the three that open impassable ground, and sure footing is spelled
# `sure_footed` or `surefoot_<terrain>`.
# Terrain names and the abilities that open them now come from the shared
# vocabulary rather than from a regex over map_manager.gd — which broke the
# moment those const tables moved into data, exactly as it should have.
_passage = {v["ability"] for v in _terrain_rows.values() if v.get("ability")}
_valid_abilities = _passage | {"sure_footed"} | {"surefoot_%s" % k for k in _terrain_rows}

def _check_abilities(label, name, decl):
    if decl is None:
        return
    names = [decl] if isinstance(decl, str) else [str(x) for x in decl]
    for _a in names:
        if _a not in _valid_abilities:
            err("data->code", f"{label} '{name}' grants movement ability "
                f"'{_a}', which no terrain asks about — it would do nothing")

for _st in load("resources/data/statuses.json")["statuses"]:
    _check_abilities("status", _st.get("name"), _st.get("grants_movement_ability"))
_perks_for_abilities = load("resources/data/perks.json")
for _section in ("skill_perks", "cross_perks"):
    for _pid, _pk in _perks_for_abilities.get(_section, {}).items():
        if isinstance(_pk, dict):
            _check_abilities("perk", _pid, _pk.get("grants_movement_ability"))


# ── Per-team branches and expiry summons ────────────────────────────────────
_summon_templates = load("resources/data/summon_templates.json")["templates"]
for _sid, _sp in _spells.items():
    for _side in ("on_allies", "on_enemies"):
        _b = _sp.get(_side)
        if _b is None:
            continue
        if not isinstance(_b, dict):
            err("data->code", f"spell '{_sid}' has a non-object `{_side}`")
            continue
        for _st in _b.get("statuses", []):
            if _st not in _status_names:
                err("data->code", f"spell '{_sid}' `{_side}` names status "
                    f"'{_st}', which does not exist")
        if _b.get("save_type") and _save_attrs and _b["save_type"].lower() not in _save_attrs:
            err("data->code", f"spell '{_sid}' `{_side}` saves on "
                f"'{_b['save_type']}', which is not an attribute")

for _st in load("resources/data/statuses.json")["statuses"]:
    _hatch = _st.get("summon_on_expire")
    if _hatch and _hatch not in _summon_templates:
        err("data->code", f"status '{_st.get('name')}' hatches '{_hatch}' on "
            "expiry, and no summon template by that name exists")


# ── Retaliation and granted resistances ─────────────────────────────────────
_RETAL_KEYS = {"range", "damage", "element", "reflect_pct", "status",
               "status_duration", "status_chance"}
for _st in load("resources/data/statuses.json")["statuses"]:
    _r = _st.get("retaliation")
    if _r is None:
        continue
    if not isinstance(_r, dict):
        err("data->code", f"status '{_st.get('name')}' has a non-object `retaliation`")
        continue
    for _k in _r:
        if _k not in _RETAL_KEYS:
            err("data->code", f"status '{_st.get('name')}' retaliation carries "
                f"'{_k}', which _process_reactive_statuses does not resolve")
    if _r.get("range", "melee") not in ("melee", "any"):
        err("data->code", f"status '{_st.get('name')}' retaliates at range "
            f"'{_r.get('range')}'; only 'melee' and 'any' are resolved")
    if _r.get("status") and _r["status"] not in _status_names:
        err("data->code", f"status '{_st.get('name')}' retaliates with status "
            f"'{_r['status']}', which does not exist")
    if not _r.get("damage") and not _r.get("reflect_pct") and not _r.get("status"):
        err("data->code", f"status '{_st.get('name')}' has a retaliation that "
            "deals no damage, reflects nothing and applies nothing")
    _gr = _st.get("grants_resistance")
    if _gr is not None and not isinstance(_gr, dict):
        err("data->code", f"status '{_st.get('name')}' has a non-object "
            "`grants_resistance`")


# ── The damage-type vocabulary ──────────────────────────────────────────────
#
# Every `damage_type` in the data and every key in a `resistances` block has to
# be a name damage_types.json knows, because a resistance key that does not
# match a damage type reads as zero resistance and nothing complains. That is
# how five spells came to deal `ice` while all fourteen resistance entries in
# the game said `cold`, and how six summons resisted `holy`, which nothing has
# ever dealt.
_dt_data = load("resources/data/damage_types.json")
_damage_types = {k for k in _dt_data["damage_types"] if not k.startswith("_")}
_other_res = {k for k in _dt_data.get("other_resistances", {}) if not k.startswith("_")}

# The class is the authority on which categories exist; read it rather than
# restating the list here.
_dt_src = open(os.path.join(ROOT, "scripts/combat/damage_type.gd"), encoding="utf-8").read()
_dt_categories = _gd_list(_dt_src, "CATEGORIES")

for _name in sorted(_damage_types):
    _d = _dt_data["damage_types"][_name]
    _cat = _d.get("category", "")
    if _cat not in _dt_categories:
        err("data->code", f"damage type '{_name}' is category '{_cat}', which is "
            "not in DamageType.CATEGORIES")
    for _c in _d.get("components", []):
        if _c not in _damage_types:
            err("data->code", f"compound damage type '{_name}' is made of "
                f"'{_c}', which is not a damage type")
    for _c in _d.get("choices", []):
        if _c not in _damage_types:
            err("data->code", f"damage type '{_name}' may roll '{_c}', which is "
                "not a damage type")
    if _cat == "compound" and not _d.get("components"):
        err("data->code", f"damage type '{_name}' is a compound with no "
            "components, so it would resolve to itself and be resisted by nothing")
    _sub = _d.get("subtype_of", "")
    if _sub and _sub not in _damage_types:
        err("data->code", f"damage type '{_name}' falls back to '{_sub}', which "
            "is not a damage type")


def _walk_damage_types(node, where):
    """Every damage_type field and resistance key under `node`."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k in ("damage_type", "bonus_damage_type", "element_damage_type") \
                    and isinstance(v, str) and v not in ("", "none"):
                # A `resistance` effect reuses the `damage_type` field to name
                # what is resisted, and some of those are afflictions rather
                # than damage — Stone Body resists bleeding, which is a thing
                # that happens to you, not a thing that hits you.
                _affliction_ok = node.get("type") in ("resistance", "vulnerability")
                if v not in _damage_types and not (_affliction_ok and v in _other_res):
                    err("data->code", f"{where}: damage type '{v}' is not in "
                        "damage_types.json, so no resistance can match it")
            elif k.endswith("_resistance") and isinstance(v, (int, float)):
                # The other shape a resistance takes: ItemSystem turns a
                # `<type>_resistance` passive into resistances[<type>], so an
                # armour trait reading `water_resistance: 15` silently grants
                # resistance to a type nothing deals. Two traits and four
                # talisman stats were in that state after the reshape, and the
                # `resistances` check above could not see them.
                _base = k[:-len("_resistance")]
                # `elemental_resistance` and `pierce_all_resistance` are
                # scopes rather than types: all elements, and all resistance.
                if _base not in _damage_types and _base not in _other_res \
                        and _base not in ("debuff", "magic", "mental", "status",
                                          "all", "elemental", "pierce_all"):
                    err("data->code", f"{where}: '{k}' grants resistance to "
                        f"'{_base}', which is not a damage type anything deals")
            elif k in ("resistances", "grants_resistance", "grants_vulnerability") \
                    and isinstance(v, dict):
                for key in v:
                    if key not in _damage_types and key not in _other_res:
                        err("data->code", f"{where}: resistance to '{key}', which "
                            "is not a damage type anything deals")
            else:
                _walk_damage_types(v, where)
    elif isinstance(node, list):
        for v in node:
            _walk_damage_types(v, where)


for _f in ("spells.json", "statuses.json", "zones.json", "auras.json",
           "summon_templates.json", "items.json", "traits.json", "races.json",
           "perks.json", "ammo.json", "equipment_tables.json",
           "talisman_tables.json"):
    _walk_damage_types(load("resources/data/" + _f), _f)
for _f in sorted(glob.glob(os.path.join(ROOT, "resources/data/enemies/*.json"))):
    _walk_damage_types(load(os.path.relpath(_f, ROOT)), os.path.basename(_f))

# And the literals in code: apply_damage(unit, n, "<type>") has to name one too.
for _gd in glob.glob(os.path.join(ROOT, "scripts/**/*.gd"), recursive=True):
    _src = open(_gd, encoding="utf-8").read()
    _rel = os.path.relpath(_gd, ROOT)
    # [^,\n] so the match cannot run across lines and pick up a literal from
    # a comment several lines below an apply_damage() mentioned in prose.
    for _m in re.finditer(r'apply_damage\([^,\n]+,[^,\n]+,\s*"([a-z_]+)"', _src):
        if _m.group(1) not in _damage_types:
            err("code->data", f"{_rel}: apply_damage deals '{_m.group(1)}', which "
                "is not in damage_types.json")


# ── Zones ───────────────────────────────────────────────────────────────────
#
# Zones share the aura payload vocabulary on purpose, so the checks are the
# same ones: a trigger nothing fires, a payload kind nothing resolves, and a
# status that does not exist are all silent no-ops.
_zone_src = open(os.path.join(ROOT, "scripts/combat/zone.gd"), encoding="utf-8").read()
_zone_triggers = _gd_list(_zone_src, "TRIGGERS")
_zone_affects = _gd_list(_zone_src, "AFFECTS")
_zone_drifts = set(re.findall(r'"(\w*)"', re.search(
    r"const DRIFTS[^=]*=\s*\[(.*?)\]", _zone_src, re.S).group(1))) \
    if re.search(r"const DRIFTS", _zone_src) else set()

_zones = load("resources/data/zones.json")["zones"]
_zone_ids = {k for k in _zones if not k.startswith("_")}
# Zones use the aura payload vocabulary — read from the same source, so the
# two cannot drift — plus `raise`, which summons rather than modifying a unit.
_aura_src_for_zones = open(os.path.join(ROOT, "scripts/combat/aura_system.gd"),
    encoding="utf-8").read()
_zone_payload_kinds = _gd_list(_aura_src_for_zones, "PAYLOAD_KINDS") | {"raise"}

for _zid in sorted(_zone_ids):
    _zdef = _zones[_zid]
    if _zdef.get("affects", "all") not in _zone_affects:
        err("data->code", f"zone '{_zid}' affects '{_zdef.get('affects')}', "
            "which Zone.reaches() does not recognise")
    if _zone_drifts and str(_zdef.get("drift", "")) not in _zone_drifts:
        err("data->code", f"zone '{_zid}' drifts '{_zdef.get('drift')}', "
            "which is not in Zone.DRIFTS")
    _has_payloads = False
    for _key in _zdef:
        if _key.startswith("_") or _key in ("name", "affects", "drift"):
            continue
        if _key not in _zone_triggers:
            err("data->code", f"zone '{_zid}' has trigger '{_key}', which is "
                "not in Zone.TRIGGERS — it would never fire")
            continue
        for _pl in _zdef[_key]:
            _has_payloads = True
            if _pl.get("kind") not in _zone_payload_kinds:
                err("data->code", f"zone '{_zid}' {_key} payload kind "
                    f"'{_pl.get('kind')}' is resolved by nothing")
            if _pl.get("affects", "all") not in _zone_affects:
                err("data->code", f"zone '{_zid}' {_key} payload affects "
                    f"'{_pl.get('affects')}', which is not recognised")
            if _pl.get("status") and _pl["status"] not in _status_names:
                err("data->code", f"zone '{_zid}' grants status "
                    f"'{_pl['status']}', which does not exist")
            if _pl.get("kind") == "resistance":
                _zrt = str(_pl.get("type", ""))
                if _zrt not in _damage_types and _zrt not in _other_res:
                    err("data->code", f"zone '{_zid}' grants resistance to "
                        f"'{_zrt}', which is neither a damage type nor an affliction")
            if _pl.get("summon") and _pl["summon"] not in _summon_templates:
                err("data->code", f"zone '{_zid}' raises '{_pl['summon']}', "
                    "and no summon template by that name exists")
    if not _has_payloads:
        err("data->code", f"zone '{_zid}' has no payloads under any trigger — "
            "it would sit on the ground doing nothing")

# Every zone a spell names must exist, and every zone must be reachable.
_named_zones = set()
for _sid, _sp in _spells.items():
    _z = _sp.get("zone")
    if not _z:
        continue
    _named_zones.add(str(_z))
    if _z not in _zone_ids:
        err("data->code", f"spell '{_sid}' places unknown zone '{_z}'")
    if not _sp.get("aoe"):
        err("data->code", f"spell '{_sid}' places a zone but has no `aoe` "
            "block, so the zone would have no footprint")
for _zid in sorted(_zone_ids - _named_zones):
    err("data->code", f"zone '{_zid}' is defined and no spell places it")


# ── Auras ────────────────────────────────────────────────────────────────────
#
# Four kinds of source may declare an aura, and all four name it the same way.
# Two things can go wrong and neither shows up at runtime: a source names an
# aura that does not exist (it is collected, warned about once, and dropped), or
# a definition uses a payload kind nothing resolves (it is collected and
# silently ignored). Both are the write-with-no-reader bug in a new costume.
_auras = load("resources/data/auras.json")["auras"]
_aura_ids = {k for k in _auras if not k.startswith("_")}

# The vocabulary lives in aura_system.gd and is read from there, never restated
# here — a second copy of a vocabulary is how the original bug got in.
_kinds_src = open(os.path.join(ROOT, "scripts/combat/aura_system.gd"), encoding="utf-8").read()
_m = re.search(r"const PAYLOAD_KINDS[^=]*=\s*\[(.*?)\]", _kinds_src, re.S)
_payload_kinds = set(re.findall(r'"([^"]+)"', _m.group(1))) if _m else set()
if not _payload_kinds:
    err("data->code", "could not read AuraSystem.PAYLOAD_KINDS — aura payloads unchecked")

for _aid, _adef in _auras.items():
    if _aid.startswith("_"):
        continue
    for _pl in _adef.get("payloads", []):
        _kind = str(_pl.get("kind", ""))
        if _kind not in _payload_kinds:
            err("data->code", f"aura '{_aid}' has payload kind '{_kind}', "
                f"which is not in AuraSystem.PAYLOAD_KINDS — nothing resolves it")
        if _kind == "resistance":
            # The `type` a resistance payload guards against has to be
            # something that can actually arrive, or the aura protects against
            # nothing and says so nowhere.
            _rt = str(_pl.get("type", ""))
            if _rt not in _damage_types and _rt not in _other_res:
                err("data->code", f"aura '{_aid}' grants resistance to '{_rt}', "
                    "which is neither a damage type nor an affliction")
    if _adef.get("affects", "allies") not in ("allies", "enemies", "all", "self"):
        err("data->code", f"aura '{_aid}' affects '{_adef.get('affects')}', "
            "which AuraSystem.reaches() does not recognise — it will reach nobody")

# Every source that names an aura must name one that exists.
for _iid, _it in load("resources/data/items.json")["items"].items():
    _a = _it.get("passive_aura", "")
    if _a and _a not in _aura_ids:
        err("data->code", f"item '{_iid}' declares unknown aura '{_a}'")
def _declared_auras(defn):
    """`aura` may name one aura or list several."""
    _a = defn.get("aura", "")
    if isinstance(_a, str):
        return [_a] if _a else []
    return [str(x) for x in _a] if isinstance(_a, list) else []

for _st in load("resources/data/statuses.json")["statuses"]:
    for _a in _declared_auras(_st):
        if _a not in _aura_ids:
            err("data->code", f"status '{_st.get('name')}' declares unknown aura '{_a}'")
_perks_file = load("resources/data/perks.json")
for _section in ("skill_perks", "cross_perks"):
    for _pid, _pk in _perks_file.get(_section, {}).items():
        if not isinstance(_pk, dict):
            continue
        for _a in _declared_auras(_pk):
            if _a not in _aura_ids:
                err("data->code", f"perk '{_pid}' declares unknown aura '{_a}'")

# And every declared aura must have at least one source naming it, or it is
# content that exists only in the definitions file.
_named = set()
for _it in load("resources/data/items.json")["items"].values():
    if _it.get("passive_aura"):
        _named.add(_it["passive_aura"])
for _st in load("resources/data/statuses.json")["statuses"]:
    _named.update(_declared_auras(_st))
for _section in ("skill_perks", "cross_perks"):
    for _pk in _perks_file.get(_section, {}).values():
        if isinstance(_pk, dict):
            _named.update(_declared_auras(_pk))
_named |= set(re.findall(r'intrinsic_auras\.append\("([^"]+)"\)', _gd_source))
for _tpl in load("resources/data/summon_templates.json")["templates"].values():
    for _a in _tpl.get("auras", []):
        _named.add(str(_a))
for _aid in sorted(_aura_ids - _named):
    err("data->code", f"aura '{_aid}' is defined but no item, status, perk or "
        "unit declares it — it can never fire")


# AoE shape names, across both spells and perk combat_data. An unknown shape
# falls back to a circle inside AoEResolver with only a push_warning, which
# turns a sweep into a burst without anything going red.
_shapes = set()
for _sp in load("resources/data/spells.json")["spells"].values():
    if isinstance(_sp, dict) and isinstance(_sp.get("aoe"), dict):
        _shapes.add(str(_sp["aoe"].get("type", "circle")))
for _section in ("skill_perks", "cross_perks"):
    for _pk in perks_data.get(_section, {}).values():
        if not isinstance(_pk, dict):
            continue
        _aoe = _pk.get("combat_data", {}).get("aoe")
        if isinstance(_aoe, dict):
            _shapes.add(str(_aoe.get("type", "circle")))
check_vocabulary("aoe shape", _shapes)

# Effect types dispatched by use_active_skill, and passive effect types read by
# PerkSystem.
_effect_types = set()
_passive_types = set()
for _section in ("skill_perks", "cross_perks"):
    for _pk in perks_data.get(_section, {}).values():
        if not isinstance(_pk, dict):
            continue
        _cd = _pk.get("combat_data", {})
        if _cd.get("effect"):
            _effect_types.add(str(_cd["effect"]))
        for _fx in _pk.get("effects", []):
            if isinstance(_fx, dict) and _fx.get("type"):
                _passive_types.add(str(_fx["type"]))
check_vocabulary("active skill effect", _effect_types)
check_vocabulary("passive effect type", _passive_types)

# ── report ───────────────────────────────────────────────────────────────────
print(f"TOTAL ISSUES: {len(errors)}")
for category, count in Counter(c for c, _ in errors).most_common():
    print(f"  {category}: {count}")
if errors:
    print()
    for category, message in errors:
        print(f"[{category}] {message}")
sys.exit(1 if errors else 0)
