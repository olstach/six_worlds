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


# ── spells -> statuses / summons ─────────────────────────────────────────────
# Nothing checked these before, and eight spells named statuses that do not exist.
# Cleanse spells legitimately name *categories* rather than statuses, so those are
# listed rather than treated as typos — but only the ones the UI knows about.
CLEANSE_CATEGORIES = {"all_negative", "negative", "mental_negative", "physical_negative"}
_spell_data = load("resources/data/spells.json")["spells"]
_summon_templates = set(load("resources/data/summon_templates.json").get("templates", {}))
for spid, spell in _spell_data.items():
    if spid.startswith("_") or not isinstance(spell, dict):
        continue
    for field in ("statuses_caused", "statuses_removed", "statuses_caused_on_failed_save"):
        for st in spell.get(field, []) or []:
            if not isinstance(st, str) or st in statuses:
                continue
            if field == "statuses_removed" and st in CLEANSE_CATEGORIES:
                continue
            err("spell->status", f"spells.json:{spid}: {field} '{st}' is not a status")
    summon = spell.get("summon")
    for sid in ([summon] if isinstance(summon, str) else summon or []):
        if isinstance(sid, str) and sid not in _summon_templates:
            err("spell->summon", f"spells.json:{spid}: summon '{sid}' is not a summon template")


# ── spell special effects -> the registry ────────────────────────────────────
# `special` used to be a free dict and grew 369 distinct keys across 210 spells,
# 88% of them used exactly once and three of them read by anything. It is now
# {"effects": [typed entries], "legacy": {frozen old keys}}, and this is the
# guard: a type outside the registry, a missing required param, or a legacy key
# that is not on the frozen list is an error. Existing debt is grandfathered and
# visible; new debt cannot be added.
_fx_registry = load("resources/data/spell_effects.json")
_fx_types = _fx_registry["effects"]
_fx_legacy = set(_fx_registry.get("legacy_keys", []))
_fx_required = {
    name: [p for p, doc in spec.get("params", {}).items()
           if isinstance(doc, str) and "required" in doc]
    for name, spec in _fx_types.items()
}
for spid, spell in _spell_data.items():
    if spid.startswith("_") or not isinstance(spell, dict):
        continue
    special = spell.get("special")
    if not isinstance(special, dict):
        continue
    for key in special:
        if key not in ("effects", "legacy"):
            err("spell->special", f"spells.json:{spid}: `special` may only hold "
                                  f"`effects` and `legacy`, found '{key}'")
    for entry in special.get("effects", []):
        if not isinstance(entry, dict):
            err("spell->special", f"spells.json:{spid}: effects entry is not an object")
            continue
        etype = entry.get("type", "")
        if etype not in _fx_types:
            err("spell->special", f"spells.json:{spid}: effect type '{etype}' is not in "
                                  f"spell_effects.json — declare it there first")
            continue
        for p in _fx_required[etype]:
            if p not in entry:
                err("spell->special", f"spells.json:{spid}: effect '{etype}' is missing "
                                      f"required param '{p}'")
    for key in special.get("legacy", {}):
        if key not in _fx_legacy:
            err("spell->special", f"spells.json:{spid}: legacy special key '{key}' is not on "
                                  f"the frozen list — give it a registry type instead")


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
        for iid in equip.get("random_bonus", []):
            if not item_ok(iid):
                err(f"{group[:-1]}->item", f"races.json:{key}: random_bonus '{iid}' unknown")
        # typical_backgrounds is documentation rather than gameplay data (the roll
        # uses available_races), so nothing crashes when one rots — check it anyway.
        for bid in entry.get("typical_backgrounds", []):
            if bid not in backgrounds:
                err("birth->background", f"races.json:{key}: typical_background '{bid}' unknown")
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
