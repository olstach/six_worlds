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
def check_outcome(outcome, ctx, depth=0):
    if not isinstance(outcome, dict) or depth > 5:
        return
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


def check_requirements(reqs, ctx):
    if not isinstance(reqs, dict):
        return
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


for eid, (event, src) in events.items():
    for choice in event.get("choices", []):
        ctx = f"{src}:{eid}:{choice.get('id', choice.get('text', '?')[:20])}"
        check_requirements(choice.get("requirements", {}), ctx)
        for key in ("outcome", "outcome_success", "outcome_failure"):
            if key in choice:
                check_outcome(choice[key], f"{ctx}:{key}")

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

# ── report ───────────────────────────────────────────────────────────────────
print(f"TOTAL ISSUES: {len(errors)}")
for category, count in Counter(c for c, _ in errors).most_common():
    print(f"  {category}: {count}")
if errors:
    print()
    for category, message in errors:
        print(f"[{category}] {message}")
sys.exit(1 if errors else 0)
