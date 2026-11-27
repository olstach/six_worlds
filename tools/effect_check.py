"""Python mirror of scripts/effects/effect_vocab.gd (class EffectVocab).

validate_data.py runs all its checks at import time, so the effect validator
lives here where tests and other tools can import it safely; validate_data.py
imports it too.

The GDScript file is the authority. Every list is READ from the .gd source
(never restated here), and every name lookup that GDScript does through an
autoload is done from the same JSON file. If you change a rule in
effect_vocab.gd, change it here in the same commit.

    check_effect(effect, where)   -> list[str]  (empty means valid)
    check_effects(effects, where) -> list[str]
"""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return fh.read()


def _json(rel):
    return json.loads(_read(rel))


def _strip_comments(src):
    """Drop `# ...` comments (a '#' outside a quoted string) from GDScript."""
    out = []
    for line in src.split("\n"):
        in_str = False
        for i, ch in enumerate(line):
            if ch == '"':
                in_str = not in_str
            elif ch == "#" and not in_str:
                line = line[:i]
                break
        out.append(line)
    return "\n".join(out)


def _gd_list(src, name):
    """Ordered list of the quoted strings in `const NAME... = [ ... ]`."""
    m = re.search(r"const %s\b[^=]*=\s*\[(.*?)\]" % name, _strip_comments(src), re.S)
    if not m:
        raise RuntimeError("effect_check: cannot read const %s from GDScript source" % name)
    return re.findall(r'"([^"]*)"', m.group(1))


def _gd_dict_of_lists(src, name):
    """`const NAME: Dictionary = { "k": ["a", "b"], ... }` -> {k: [a, b]}."""
    m = re.search(r"const %s\b[^=]*=\s*\{(.*?)\n\}" % name, _strip_comments(src), re.S)
    if not m:
        raise RuntimeError("effect_check: cannot read const %s from GDScript source" % name)
    return {k: re.findall(r'"([^"]*)"', v)
            for k, v in re.findall(r'"([^"]+)"\s*:\s*\[(.*?)\]', m.group(1), re.S)}


def _gd_dict_keys(src, name):
    """Keys of `const NAME: Dictionary = { "k": 1, ... }`, in order."""
    m = re.search(r"const %s\b[^=]*=\s*\{(.*?)\n\}" % name, _strip_comments(src), re.S)
    if not m:
        raise RuntimeError("effect_check: cannot read const %s from GDScript source" % name)
    return re.findall(r'"([^"]+)"\s*:', m.group(1))


def _gd_string(src, name):
    m = re.search(r'const %s\b[^=]*=\s*"([^"]*)"' % name, src)
    if not m:
        raise RuntimeError("effect_check: cannot read const %s from GDScript source" % name)
    return m.group(1)


# ── The approved lists, read from effect_vocab.gd ───────────────────────────
_vocab_src = _read("scripts/effects/effect_vocab.gd")
OPS_PY = _gd_list(_vocab_src, "OPS")
MODES_PY = _gd_list(_vocab_src, "MODES")
MODES_BY_NAMESPACE = _gd_dict_of_lists(_vocab_src, "MODES_BY_NAMESPACE")
NAMESPACES = _gd_list(_vocab_src, "NAMESPACES")
ATTRIBUTES = _gd_list(_vocab_src, "ATTRIBUTES")
SKILL_GROUP_CATEGORIES = _gd_list(_vocab_src, "SKILL_GROUP_CATEGORIES")
UNREADABLE_NAMESPACES = _gd_list(_vocab_src, "UNREADABLE_NAMESPACES")

RESOURCES = _gd_list(_vocab_src, "RESOURCES")
STATS = _gd_list(_vocab_src, "STATS")
RESIST_GROUPS = _gd_list(_vocab_src, "RESIST_GROUPS")
SELECTORS = _gd_list(_vocab_src, "SELECTORS")
SHARED_FIELDS = _gd_list(_vocab_src, "SHARED_FIELDS")
SCALE_PER = _gd_list(_vocab_src, "SCALE_PER")
SCALE_STATUS_STACK_PREFIX = _gd_string(_vocab_src, "SCALE_STATUS_STACK_PREFIX")
CONDITION_KEYS = _gd_list(_vocab_src, "CONDITION_KEYS")
SPELL_SCHOOLS = _gd_list(_vocab_src, "SPELL_SCHOOLS")
UPKEEP_RESOURCES = _gd_list(_vocab_src, "UPKEEP_RESOURCES")
UPKEEP_PER = _gd_list(_vocab_src, "UPKEEP_PER")
CLEARED_BY = _gd_list(_vocab_src, "CLEARED_BY")
REST_KINDS = _gd_list(_vocab_src, "REST_KINDS")
POLARITIES = _gd_list(_vocab_src, "POLARITIES")
STATUS_CATEGORIES = _gd_list(_vocab_src, "STATUS_CATEGORIES")
ELEMENTAL_CATEGORY_PREFIX = _gd_string(_vocab_src, "ELEMENTAL_CATEGORY_PREFIX")
ELEMENTS = _gd_list(_vocab_src, "ELEMENTS")
SCOPES = _gd_list(_vocab_src, "SCOPES")
DURATION_KINDS = _gd_list(_vocab_src, "DURATION_KINDS")
STACKING_MODES = _gd_list(_vocab_src, "STACKING_MODES")
LASTING_MODES = _gd_list(_vocab_src, "LASTING_MODES")
FLAGS = _gd_list(_vocab_src, "FLAGS")
IMMUNE_FLAG_PREFIX = _gd_string(_vocab_src, "IMMUNE_FLAG_PREFIX")
STATUS_TRIGGERS = _gd_list(_vocab_src, "STATUS_TRIGGERS")
PERIODIC_WHEN = _gd_list(_vocab_src, "PERIODIC_WHEN")
STATUS_FIELDS = _gd_list(_vocab_src, "STATUS_FIELDS")
LEGACY_STATUS_FIELDS = _gd_list(_vocab_src, "LEGACY_STATUS_FIELDS")
OP_FIELDS = _gd_dict_of_lists(_vocab_src, "OP_FIELDS")
INTERCEPT_OPS = _gd_list(_vocab_src, "INTERCEPT_OPS")
ATTACK_TARGETS = _gd_list(_vocab_src, "ATTACK_TARGETS")
SUMMON_OWNERS = _gd_list(_vocab_src, "SUMMON_OWNERS")
BORROW_SOURCES = _gd_list(_vocab_src, "BORROW_SOURCES")
BORROW_UNIT_PREFIXES = _gd_list(_vocab_src, "BORROW_UNIT_PREFIXES")
BORROW_FIELDS = _gd_list(_vocab_src, "BORROW_FIELDS")
ROUNDINGS = _gd_list(_vocab_src, "ROUNDINGS")
INTERCEPT_TRIGGERS = _gd_list(_vocab_src, "INTERCEPT_TRIGGERS")
REACTION_TRIGGERS = _gd_list(_vocab_src, "REACTION_TRIGGERS")
REACH_TRIGGERS = _gd_list(_vocab_src, "REACH_TRIGGERS")
TRIGGER_FIELDS = _gd_list(_vocab_src, "TRIGGER_FIELDS")
LIMIT_PER = _gd_list(_vocab_src, "LIMIT_PER")
SAVE_WHEN = _gd_list(_vocab_src, "SAVE_WHEN")
SPREAD_TO = _gd_list(_vocab_src, "SPREAD_TO")
SPREAD_WHEN = _gd_list(_vocab_src, "SPREAD_WHEN")
BUILT_IN_CREATURE_TAGS = _gd_list(_vocab_src, "BUILT_IN_CREATURE_TAGS")
FLAT_ONLY_STATS = _gd_list(_vocab_src, "FLAT_ONLY_STATS")
SUMMON_FROM = _gd_list(_vocab_src, "SUMMON_FROM")
SAVE_FIELDS = _gd_list(_vocab_src, "SAVE_FIELDS")
AURA_FIELDS = _gd_list(_vocab_src, "AURA_FIELDS")
ZONE_FIELDS = _gd_list(_vocab_src, "ZONE_FIELDS")
READ_TIME_NAMESPACES = _gd_list(_vocab_src, "READ_TIME_NAMESPACES")
READ_TIME_MODES = _gd_list(_vocab_src, "READ_TIME_MODES")
PER_TURN_OPS = _gd_list(_vocab_src, "PER_TURN_OPS")
ZONE_SELECTORS = _gd_list(_vocab_src, "ZONE_SELECTORS")
READ_TIME_BORROWS = _gd_list(_vocab_src, "READ_TIME_BORROWS")

# Lists EffectVocab borrows from other classes.
_cs_src = _read("scripts/combat/combat_stats.gd")
CONDITIONS = _gd_list(_cs_src, "PERK_CONDITIONS")          # CombatStats.PERK_CONDITIONS
TERRAIN_CONDITION_PREFIX = _gd_string(_cs_src, "TERRAIN_CONDITION_PREFIX")
DERIVED = _gd_list(_cs_src, "DERIVED")                     # CombatStats.DERIVED
_save_src = _read("scripts/combat/save_system.gd")
SAVE_ATTRIBUTES = _gd_list(_save_src, "ATTRIBUTES")        # SaveSystem.ATTRIBUTES
SAVE_TIERS = _gd_dict_keys(_save_src, "TIERS")             # SaveSystem.TIERS keys
STATUS_OPS = _gd_list(_read("scripts/combat/status_ops.gd"), "OPS")
STATUS_TAGS = _gd_list(_read("scripts/combat/status_ops.gd"), "TAGS")
REPOSITION_MODES = _gd_list(_read("scripts/combat/repositioning.gd"), "MODES")
_res_src = _read("scripts/combat/resurrection.gd")
RESURRECT_TIERS = _gd_list(_res_src, "TIERS")
RESURRECT_SCOPES = _gd_list(_res_src, "SCOPES")
MAGIC_SCHOOLS = _gd_list(_read("scripts/autoload/perk_system.gd"), "MAGIC_SCHOOLS")
AFFLICTIONS = _gd_list(_read("scripts/combat/resistance.gd"), "AFFLICTIONS")   # Resistance.AFFLICTIONS
AURA_AFFECTS = _gd_list(_read("scripts/combat/aura_system.gd"), "AFFECTS")    # AuraSystem.AFFECTS
_zone_src = _read("scripts/combat/zone.gd")
ZONE_TRIGGERS = _gd_list(_zone_src, "TRIGGERS")                                # Zone.TRIGGERS
ZONE_AFFECTS = _gd_list(_zone_src, "AFFECTS")
ZONE_DRIFTS = _gd_list(_zone_src, "DRIFTS")
ZONE_PAIR_ROLES = _gd_list(_zone_src, "PAIR_ROLES")
POSITION_OPS = _gd_list(_read("scripts/effects/effect_resolver.gd"), "POSITION_OPS")


# ── Name lookups GDScript does through autoloads, here done from the JSON ───
def _live(d):
    """Keys of a JSON object without the `_comment*` documentation keys."""
    return [k for k in d if not k.startswith("_")]


SKILL_IDS = sorted(_json("resources/data/skills.json").get("skills", {}))   # PerkSystem.get_all_skill_ids
STATUS_NAMES = [s["name"] for s in _json("resources/data/statuses.json")["statuses"]]
SUMMON_TEMPLATES = list(_json("resources/data/summon_templates.json").get("templates", {}))
ZONES = _live(_json("resources/data/zones.json").get("zones", {}))
DAMAGE_TYPES = _live(_json("resources/data/damage_types.json").get("damage_types", {}))
TERRAIN_KEYS = [k for k, v in _json("resources/data/terrain.json").get("terrain", {}).items()
                if not k.startswith("_") and v]   # Ground.by_key(key) must be non-empty


def _collect_tags(node, found):
    """Every string in a "tags" array anywhere in parsed JSON (EffectVocab._collect_tags)."""
    if isinstance(node, dict):
        for key, val in node.items():
            if key == "tags" and isinstance(val, list):
                for tag in val:
                    if isinstance(tag, str) and tag not in found:
                        found.append(tag)
            else:
                _collect_tags(val, found)
    elif isinstance(node, list):
        for item in node:
            _collect_tags(item, found)


def _creature_tags():
    found = list(BUILT_IN_CREATURE_TAGS)
    for path in sorted(glob.glob(os.path.join(ROOT, "resources/data/enemies/*.json"))):
        with open(path, encoding="utf-8") as fh:
            _collect_tags(json.load(fh), found)
    _collect_tags(_json("resources/data/races.json"), found)
    return sorted(found)


CREATURE_TAGS = _creature_tags()


def _is_perk_condition(cond):
    """CombatStats.is_perk_condition, including the on_terrain_<ground> family."""
    if cond in CONDITIONS:
        return True
    if cond.startswith(TERRAIN_CONDITION_PREFIX):
        return cond[len(TERRAIN_CONDITION_PREFIX):] in TERRAIN_KEYS
    return False


def _is_number(v):
    # GDScript's int/float; a Python bool is not a number here.
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _j(items):
    return ", ".join(items)


# ── Public API ──────────────────────────────────────────────────────────────
def check_effect(effect, where, intercepting=False):
    """Validate one effect dict; returns error strings, empty when valid.
    `intercepting`: the effect sits in a trigger in INTERCEPT_TRIGGERS, the one
    place INTERCEPT_OPS may appear."""
    errs = []
    op = effect.get("op")
    if not isinstance(op, str) or op not in OPS_PY:
        return [f"{where}: unknown op '{op}' (approved: {_j(OPS_PY)})"]
    if op in INTERCEPT_OPS and not intercepting:
        return [f"{where}: '{op}' only works in a status trigger that runs before the "
                f"attack or spell lands (on: {_j(INTERCEPT_TRIGGERS)})"]

    allowed = SHARED_FIELDS + OP_FIELDS[op]
    for key in effect:
        if key not in allowed:
            errs.append(f"{where}: unknown field '{key}' on a {op} effect")

    _validate_shared(effect, where, errs)
    _validate_op(op, effect, where, errs)
    return errs


def is_status_category(c):
    """A STATUS_CATEGORIES name, or elemental.<element>."""
    if not isinstance(c, str):
        return False
    if c in STATUS_CATEGORIES:
        return True
    return c.startswith(ELEMENTAL_CATEGORY_PREFIX) and \
        c[len(ELEMENTAL_CATEGORY_PREFIX):] in ELEMENTS


def check_status(d, where):
    """Validate one status definition (new shape); legacy fields tolerated."""
    errs = []
    for key in d:
        if key not in STATUS_FIELDS and key not in LEGACY_STATUS_FIELDS:
            errs.append(f"{where}: unknown status field '{key}'")
    if "polarity" in d and d["polarity"] not in POLARITIES:
        errs.append(f"{where}: polarity '{d['polarity']}' unknown ({_j(POLARITIES)})")
    if "scope" in d and d["scope"] not in SCOPES:
        errs.append(f"{where}: scope '{d['scope']}' unknown ({_j(SCOPES)})")
    if "categories" in d:
        if not isinstance(d["categories"], list):
            errs.append(f"{where}: 'categories' must be a list")
        else:
            for c in d["categories"]:
                if not is_status_category(c):
                    errs.append(f"{where}: unknown category '{c}' (approved: "
                                f"{_j(STATUS_CATEGORIES)}, or elemental.<element>)")
    if "duration" in d:
        du = d["duration"]
        if not isinstance(du, dict):
            errs.append(f"{where}: 'duration' must be {{kind, base?}}")
        else:
            for k in du:
                if k not in ("kind", "base"):
                    errs.append(f"{where}: duration has unknown key '{k}'")
            if du.get("kind") not in DURATION_KINDS:
                errs.append(f"{where}: duration kind '{du.get('kind')}' unknown ({_j(DURATION_KINDS)})")
            if "base" in du and not _is_number(du["base"]):
                errs.append(f"{where}: duration base must be a number")
    if "stacking" in d:
        st = d["stacking"]
        if not isinstance(st, dict):
            errs.append(f"{where}: 'stacking' must be {{mode, max?}}")
        else:
            for k in st:
                if k not in ("mode", "max", "grow"):
                    errs.append(f"{where}: stacking has unknown key '{k}'")
            if st.get("mode") not in STACKING_MODES:
                errs.append(f"{where}: stacking mode '{st.get('mode')}' unknown ({_j(STACKING_MODES)})")
            if "max" in st and not _is_number(st["max"]):
                errs.append(f"{where}: stacking max must be a number")
            if "grow" in st:
                _validate_grow(st, where, errs)
    if "upkeep" in d:
        _validate_upkeep(d["upkeep"], where, errs)
    if "flags" in d:
        if not isinstance(d["flags"], list):
            errs.append(f"{where}: 'flags' must be a list")
        else:
            for f in d["flags"]:
                if not isinstance(f, str):
                    errs.append(f"{where}: a flag must be a string")
                elif f.startswith(IMMUNE_FLAG_PREFIX):
                    if len(f) == len(IMMUNE_FLAG_PREFIX):
                        errs.append(f"{where}: flag 'immune:' names nothing")
                elif f not in FLAGS:
                    errs.append(f"{where}: unknown flag '{f}' (approved: {_j(FLAGS)}, or immune:<...>)")
    if "while_active" in d:
        wa = d["while_active"]
        if not isinstance(wa, list):
            errs.append(f"{where}: 'while_active' must be a list of effects")
        else:
            errs.extend(check_effects(wa, where + ".while_active"))
            for i, e in enumerate(wa):
                if isinstance(e, dict) and e.get("op") == "modify" \
                        and e.get("mode", "") not in LASTING_MODES:
                    errs.append(f"{where}.while_active[{i}]: mode '{e.get('mode', '')}' is "
                                f"instant, not lasting ({_j(LASTING_MODES)})")
    if "periodic" in d:
        per = d["periodic"]
        if not isinstance(per, dict) or not isinstance(per.get("effects"), list):
            errs.append(f"{where}: 'periodic' must be an object with an 'effects' list")
        else:
            if "when" in per and per["when"] not in PERIODIC_WHEN:
                errs.append(f"{where}: periodic when '{per['when']}' unknown ({_j(PERIODIC_WHEN)})")
            errs.extend(check_effects(per["effects"], where + ".periodic.effects"))
    if "triggers" in d:
        if not isinstance(d["triggers"], list):
            errs.append(f"{where}: 'triggers' must be a list")
        else:
            for i, t in enumerate(d["triggers"]):
                label = f"{where}.triggers[{i}]"
                if not isinstance(t, dict):
                    errs.append(f"{label}: a trigger must be an object")
                    continue
                _validate_trigger(t, label, errs)
    if "save" in d:
        sv = d["save"]
        if not isinstance(sv, dict):
            errs.append(f"{where}: 'save' must be {{stat, dc, when}}")
        else:
            for k in sv:
                if k not in ("stat", "dc", "when"):
                    errs.append(f"{where}: save has unknown key '{k}'")
            if str(sv.get("stat", "")).lower() not in SAVE_ATTRIBUTES:
                errs.append(f"{where}: save stat '{sv.get('stat', '')}' is not an attribute")
            if not _is_number(sv.get("dc")):
                errs.append(f"{where}: save needs a number 'dc'")
            if sv.get("when") not in SAVE_WHEN:
                errs.append(f"{where}: save when '{sv.get('when')}' unknown ({_j(SAVE_WHEN)})")
    if "spread" in d:
        sp = d["spread"]
        if not isinstance(sp, dict):
            errs.append(f"{where}: 'spread' must be {{to, reach?, chance, when}}")
        else:
            for k in sp:
                if k not in ("to", "reach", "chance", "when"):
                    errs.append(f"{where}: spread has unknown key '{k}'")
            if sp.get("to") not in SPREAD_TO:
                errs.append(f"{where}: spread to '{sp.get('to')}' unknown ({_j(SPREAD_TO)})")
            if sp.get("when") not in SPREAD_WHEN:
                errs.append(f"{where}: spread when '{sp.get('when')}' unknown ({_j(SPREAD_WHEN)})")
            c = sp.get("chance")
            if not _is_number(c) or c < 0 or c > 100:
                errs.append(f"{where}: spread chance must be a number from 0 to 100")
            if "reach" in sp and not (_is_number(sp["reach"]) and sp["reach"] >= 1):
                errs.append(f"{where}: spread reach must be a number of tiles, 1 or more")
    if "cleared_by" in d:
        _validate_cleared_by(d["cleared_by"], where, errs)
    return errs


def _validate_grow(st, where, errs):
    """`stacking.grow` (EffectVocab._validate_grow)."""
    g = st["grow"]
    if not isinstance(g, dict):
        errs.append(f"{where}: stacking grow must be {{on, by, if?}}")
        return
    for k in g:
        if k not in ("on", "by", "if"):
            errs.append(f"{where}: stacking grow has unknown key '{k}'")
    if st.get("mode") != "stack":
        errs.append(f"{where}: only a stacking mode 'stack' can grow")
    if g.get("on") not in STATUS_TRIGGERS or g.get("on") == "expire":
        errs.append(f"{where}: stacking grow on '{g.get('on')}' unknown ({_j(STATUS_TRIGGERS)}, not expire)")
    if not (_is_number(g.get("by")) and g["by"] >= 1):
        errs.append(f"{where}: stacking grow by must be a number, 1 or more")
    if "if" in g:
        if not isinstance(g["if"], list):
            errs.append(f"{where}: stacking grow 'if' must be a list of conditions")
        else:
            for cond in g["if"]:
                msg = _condition_error(cond)
                if msg:
                    errs.append(f"{where}: grow {msg}")


def _validate_upkeep(u, where, errs):
    """`upkeep` (EffectVocab._validate_upkeep)."""
    if not isinstance(u, dict):
        errs.append(f"{where}: 'upkeep' must be {{mana|stamina|hp: n, per: \"turn\"}}")
        return
    costs = 0
    for k, v in u.items():
        if k == "per":
            if v not in UPKEEP_PER:
                errs.append(f"{where}: upkeep per '{v}' unknown ({_j(UPKEEP_PER)})")
        elif k in UPKEEP_RESOURCES:
            costs += 1
            if not (_is_number(v) and v > 0):
                errs.append(f"{where}: upkeep {k} must be a number above 0")
        else:
            errs.append(f"{where}: upkeep has unknown key '{k}' ({_j(UPKEEP_RESOURCES)}, per)")
    if costs == 0:
        errs.append(f"{where}: upkeep names no cost ({_j(UPKEEP_RESOURCES)})")
    if "per" not in u:
        errs.append(f"{where}: upkeep needs per: \"turn\"")


def _validate_trigger(t, label, errs):
    """One entry of a status's `triggers` (EffectVocab._validate_trigger)."""
    for k in t:
        if k not in TRIGGER_FIELDS:
            errs.append(f"{label}: unknown trigger field '{k}' (approved: {_j(TRIGGER_FIELDS)})")
    on = t.get("on")
    if on not in STATUS_TRIGGERS:
        errs.append(f"{label}: unknown trigger '{on}' (approved: {_j(STATUS_TRIGGERS)})")
    if "chance" in t and (not _is_number(t["chance"]) or t["chance"] < 0 or t["chance"] > 100):
        errs.append(f"{label}: trigger chance must be a number from 0 to 100")
    if "if" in t:
        if not isinstance(t["if"], list):
            errs.append(f"{label}: 'if' must be a list of conditions")
        else:
            for cond in t["if"]:
                msg = _condition_error(cond)
                if msg:
                    errs.append(f"{label}: {msg}")
    if "reach" in t:
        if on not in REACH_TRIGGERS:
            errs.append(f"{label}: a '{on}' trigger takes no reach ({_j(REACH_TRIGGERS)} do)")
        r = t["reach"]
        if not (r == "weapon" or (_is_number(r) and r >= 1)):
            errs.append(f"{label}: reach must be a number of tiles or \"weapon\"")
    if "limit" in t:
        lim = t["limit"]
        if not isinstance(lim, dict):
            errs.append(f"{label}: 'limit' must be {{per, count, once_per_source?}}")
        else:
            for k in lim:
                if k not in ("per", "count", "once_per_source"):
                    errs.append(f"{label}: limit has unknown key '{k}'")
            if lim.get("per") not in LIMIT_PER:
                errs.append(f"{label}: limit per '{lim.get('per')}' unknown ({_j(LIMIT_PER)})")
            if not (_is_number(lim.get("count")) and lim["count"] >= 1):
                errs.append(f"{label}: limit count must be a number, 1 or more")
            if "once_per_source" in lim and not isinstance(lim["once_per_source"], bool):
                errs.append(f"{label}: limit once_per_source must be true or false")
    if "effects" in t:
        if not isinstance(t["effects"], list):
            errs.append(f"{label}: 'effects' must be a list")
        else:
            errs.extend(check_effects(t["effects"], label + ".effects", on in INTERCEPT_TRIGGERS))


def check_effects(effects, where, intercepting=False):
    """Validate a list of effects, labelling each by index."""
    errs = []
    for i, e in enumerate(effects):
        label = f"{where}[{i}]"
        if not isinstance(e, dict):
            errs.append(f"{label}: an effect must be an object, got {type(e).__name__}")
            continue
        errs.extend(check_effect(e, label, intercepting))
    return errs


# ── Shared fields ───────────────────────────────────────────────────────────
def _validate_shared(effect, where, errs):
    if "to" in effect and effect["to"] not in SELECTORS:
        errs.append(f"{where}: unknown 'to' '{effect['to']}' (approved: {_j(SELECTORS)})")

    if "chance" in effect:
        c = effect["chance"]
        if not _is_number(c) or c < 0 or c > 100:
            errs.append(f"{where}: 'chance' must be a number from 0 to 100, got {c}")

    if "save" in effect:
        s = effect["save"]
        if not isinstance(s, dict):
            errs.append(f"{where}: 'save' must be {{stat, tier}} or {{stat, dc}}")
        else:
            for k in s:
                if k not in SAVE_FIELDS:
                    errs.append(f"{where}: unknown save field '{k}' (approved: {_j(SAVE_FIELDS)})")
            if str(s.get("stat", "")).lower() not in SAVE_ATTRIBUTES:
                errs.append(f"{where}: save stat '{s.get('stat', '')}' is not an attribute")
            if "dc" in s:
                if "tier" in s:
                    errs.append(f"{where}: a save has a 'tier' or a 'dc', not both")
                if not _is_number(s["dc"]):
                    errs.append(f"{where}: save dc must be a number")
                if "dc_drop_per_pass" in s and not _is_number(s["dc_drop_per_pass"]):
                    errs.append(f"{where}: save dc_drop_per_pass must be a number")
            else:
                if "dc_drop_per_pass" in s:
                    errs.append(f"{where}: dc_drop_per_pass needs a fixed 'dc'")
                if s.get("tier", "") not in SAVE_TIERS:
                    errs.append(f"{where}: save tier '{s.get('tier', '')}' unknown "
                                f"(known: {_j(SAVE_TIERS)})")
    if "on_save" in effect:
        if effect["on_save"] not in ["fail", "pass"]:
            errs.append(f"{where}: 'on_save' must be \"fail\" or \"pass\"")
        if "save" not in effect:
            errs.append(f"{where}: 'on_save' without a 'save'")

    if "if" in effect:
        if not isinstance(effect["if"], list):
            errs.append(f"{where}: 'if' must be a list of conditions")
        else:
            for cond in effect["if"]:
                msg = _condition_error(cond)
                if msg:
                    errs.append(f"{where}: {msg}")

    if "scale" in effect:
        _validate_scale(effect["scale"], where, errs)

    if "bonus_vs" in effect:
        bv = effect["bonus_vs"]
        if not isinstance(bv, dict):
            errs.append(f"{where}: 'bonus_vs' must map creature tag to multiplier")
        else:
            for tag in bv:
                if tag not in CREATURE_TAGS:
                    errs.append(f"{where}: bonus_vs names unknown creature tag '{tag}'")
                if not _is_number(bv[tag]):
                    errs.append(f"{where}: bonus_vs['{tag}'] must be a number")

    if "cleared_by" in effect:
        if effect.get("op") != "modify" or effect.get("mode") != "damage":
            errs.append(f"{where}: 'cleared_by' is only valid on a modify with mode \"damage\"")
        _validate_cleared_by(effect["cleared_by"], where, errs)


def _validate_scale(scale, where, errs):
    if not isinstance(scale, dict):
        errs.append(f"{where}: 'scale' must be {{per, amount, cap}}")
        return
    per = scale.get("per", "")
    per_ok = per in SCALE_PER
    if not per_ok and isinstance(per, str) and per.startswith(SCALE_STATUS_STACK_PREFIX):
        per_ok = not _status_error(per[len(SCALE_STATUS_STACK_PREFIX):])
    if not per_ok:
        errs.append(f"{where}: scale.per '{per}' is not approved ({_j(SCALE_PER)}, "
                    f"or {SCALE_STATUS_STACK_PREFIX}<status>)")
    if not _is_number(scale.get("amount")):
        errs.append(f"{where}: scale.amount must be a number")
    if "cap" in scale and not _is_number(scale["cap"]):
        errs.append(f"{where}: scale.cap must be a number")


def _validate_cleared_by(lst, where, errs):
    if not isinstance(lst, list) or not lst:
        errs.append(f"{where}: 'cleared_by' must be a non-empty list")
        return
    for entry in lst:
        if not isinstance(entry, dict) or len(entry) != 1:
            errs.append(f"{where}: each cleared_by entry is a one-key object like {{\"rest\": \"full\"}}")
            continue
        kind = str(next(iter(entry)))
        arg = entry[kind]
        if kind == "rest":
            if arg not in REST_KINDS:
                errs.append(f"{where}: cleared_by rest '{arg}' unknown ({_j(REST_KINDS)})")
        elif kind == "heal":
            if not isinstance(arg, dict):
                errs.append(f"{where}: cleared_by heal takes {{school?, min_level?}}")
                continue
            for k in arg:
                if k not in ["school", "min_level"]:
                    errs.append(f"{where}: cleared_by heal has unknown key '{k}'")
            # Both "white" and "white_magic" are accepted, exactly as in GDScript.
            if "school" in arg and not (str(arg["school"]) + "_magic" in MAGIC_SCHOOLS
                                        or str(arg["school"]) in MAGIC_SCHOOLS):
                errs.append(f"{where}: cleared_by heal school '{arg['school']}' is not a magic school")
            if "min_level" in arg and not _is_number(arg["min_level"]):
                errs.append(f"{where}: cleared_by heal min_level must be a number")
        elif kind == "restore":
            if not isinstance(arg, str):
                errs.append(f"{where}: cleared_by restore takes a value path string")
            else:
                msg = _value_path_error(arg)
                if msg:
                    errs.append(f"{where}: cleared_by restore: {msg}")
        elif kind == "cleanse":
            if not isinstance(arg, dict) or set(arg) != {"category"}:
                errs.append(f"{where}: cleared_by cleanse takes {{\"category\": <status category>}}")
            elif not is_status_category(arg["category"]):
                errs.append(f"{where}: cleared_by cleanse category '{arg['category']}' unknown")
        else:
            errs.append(f"{where}: unknown cleared_by kind '{kind}' (approved: {_j(CLEARED_BY)})")


# ── Ops ─────────────────────────────────────────────────────────────────────
def _require(effect, fields, where, errs):
    for f in fields:
        if f not in effect:
            errs.append(f"{where}: {effect.get('op', '?')} effect needs '{f}'")


def _validate_op(op, effect, where, errs):
    if op == "damage":
        _require(effect, ["amount", "type"], where, errs)
        _validate_magnitude(effect, "amount", False, where, errs)
        if "type" in effect:
            _validate_damage_type(effect["type"], where, errs)
    elif op == "heal":
        _require(effect, ["amount"], where, errs)
        _validate_magnitude(effect, "amount", True, where, errs)
    elif op == "modify":
        _require(effect, ["value", "mode", "amount"], where, errs)
        _validate_modify(effect, where, errs)
    elif op == "status":
        _validate_status(effect, where, errs)
    elif op == "move":
        _require(effect, ["mode"], where, errs)
        if "mode" in effect and not (isinstance(effect["mode"], str)
                                     and effect["mode"] in REPOSITION_MODES):
            errs.append(f"{where}: move mode '{effect['mode']}' unknown ({_j(REPOSITION_MODES)})")
    elif op == "kill":
        if "immune" in effect:
            if not isinstance(effect["immune"], list):
                errs.append(f"{where}: kill 'immune' must be a list of creature tags")
            else:
                for tag in effect["immune"]:
                    if tag not in CREATURE_TAGS:
                        errs.append(f"{where}: kill immune names unknown creature tag '{tag}'")
    elif op == "summon":
        _require(effect, ["as"], where, errs)
        if "as" in effect and str(effect["as"]) not in SUMMON_TEMPLATES:
            errs.append(f"{where}: summon template '{effect['as']}' is not in summon_templates.json")
        if "count" in effect and not _is_number(effect["count"]):
            errs.append(f"{where}: summon count must be a number")
        if "owner" in effect and effect["owner"] not in SUMMON_OWNERS:
            errs.append(f"{where}: summon owner '{effect['owner']}' unknown ({_j(SUMMON_OWNERS)})")
        if "from" in effect and effect["from"] not in SUMMON_FROM:
            errs.append(f"{where}: summon from '{effect['from']}' unknown ({_j(SUMMON_FROM)})")
    elif op == "attack":
        if effect.get("target", "source") not in ATTACK_TARGETS:
            errs.append(f"{where}: attack target '{effect.get('target', '')}' unknown ({_j(ATTACK_TARGETS)})")
        if "power_pct" in effect and not (_is_number(effect["power_pct"]) and effect["power_pct"] > 0):
            errs.append(f"{where}: attack power_pct must be a number above 0")
    elif op in ("negate", "reflect"):
        pass   # no fields: the hook that fired the trigger does the work
    elif op == "zone":
        _require(effect, ["zone"], where, errs)
        if "zone" in effect and str(effect["zone"]) not in ZONES:
            errs.append(f"{where}: zone '{effect['zone']}' is not in zones.json")
    elif op == "resurrect":
        _require(effect, ["tier"], where, errs)
        if "tier" in effect and str(effect["tier"]) not in RESURRECT_TIERS:
            errs.append(f"{where}: '{effect['tier']}' is not in Resurrection.TIERS, so nothing "
                        "performs it; the spell would report success and raise nobody")
        if "scope" in effect and str(effect["scope"]) not in RESURRECT_SCOPES:
            errs.append(f"{where}: resurrect scope '{effect['scope']}' unknown ({_j(RESURRECT_SCOPES)})")
        if "hp_pct" in effect and not _is_number(effect["hp_pct"]):
            errs.append(f"{where}: resurrect hp_pct must be a number")


def _validate_modify(effect, where, errs):
    mode = effect.get("mode")
    if "mode" in effect and mode not in MODES_PY:
        errs.append(f"{where}: unknown mode '{mode}' (approved: {_j(MODES_PY)})")
    if "value" in effect:
        msg = _value_path_error(str(effect["value"]))
        if msg:
            errs.append(f"{where}: {msg}")
        elif mode in MODES_PY:
            ns = str(effect["value"]).split(".")[0]
            if mode not in MODES_BY_NAMESPACE[ns]:
                errs.append(f"{where}: mode '{mode}' is not allowed on {ns}. values "
                            f"(allowed: {_j(MODES_BY_NAMESPACE[ns])})")
            elif ns == "stat" and str(effect["value"]).split(".")[1] in FLAT_ONLY_STATS \
                    and mode not in ("fortify", "drain"):
                errs.append(f"{where}: {effect['value']} is a number of points; only fortify "
                            "and drain change it")
    _validate_magnitude(effect, "amount", False, where, errs)


def _validate_status(effect, where, errs):
    _require(effect, ["action"], where, errs)
    action = effect.get("action", "")
    if "action" in effect and not (action == "apply" or action in STATUS_OPS):
        errs.append(f"{where}: status action '{action}' unknown (apply, {_j(STATUS_OPS)})")
        return
    if action == "apply":
        _require(effect, ["status"], where, errs)
        if "status" in effect:
            msg = _status_error(str(effect["status"]))
            if msg:
                errs.append(f"{where}: {msg}")
    elif "action" in effect:
        _require(effect, ["select"], where, errs)
        sel = effect.get("select", {})
        if not isinstance(sel, dict):
            errs.append(f"{where}: 'select' must be {{names}} or {{tag}} plus optional count")
        else:
            names = sel.get("names", [])
            # GDScript would hit a runtime error iterating a non-list; fail loudly here.
            if not isinstance(names, list):
                errs.append(f"{where}: select 'names' must be a list of status names")
                names = []
            for n in names:
                msg = _status_error(str(n))
                if msg:
                    errs.append(f"{where}: select: {msg}")
            if "tag" in sel and str(sel["tag"]) not in STATUS_TAGS:
                errs.append(f"{where}: select: '{sel['tag']}' is neither a status name nor a "
                            "StatusOps.TAGS group, so it selects nothing")


def _validate_magnitude(effect, field, allow_full, where, errs):
    if field not in effect:
        return
    m = effect[field]
    if _is_number(m):
        return
    if isinstance(m, str):
        if not (allow_full and m == "full"):
            errs.append(f"{where}: '{field}' string '{m}' not allowed"
                        + ("" if allow_full else " (\"full\" is for heal only)"))
        return
    if not isinstance(m, dict):
        errs.append(f"{where}: '{field}' must be a number or a magnitude object")
        return
    keys = sorted(m.keys())
    if keys == ["base", "per_spellpower"] or keys == ["base"]:
        if not (_is_number(m["base"]) and _is_number(m.get("per_spellpower", 0))):
            errs.append(f"{where}: {field} base/per_spellpower must be numbers")
    elif keys == ["max", "min"]:
        if not (_is_number(m["min"]) and _is_number(m["max"])) or m["min"] > m["max"]:
            errs.append(f"{where}: {field} {{min, max}} must be numbers with min <= max")
    elif keys == ["pct_of", "value"]:
        msg = _pct_of_error(str(m["pct_of"]))
        if msg:
            errs.append(f"{where}: {msg}")
        if not _is_number(m["value"]):
            errs.append(f"{where}: {field} pct_of value must be a number")
    elif "from" in m:
        _validate_borrow(m, field, where, errs)
    else:
        errs.append(f"{where}: '{field}' object has keys {keys}; expected "
                    "{base, per_spellpower}, {pct_of, value}, {min, max} or {from, ...}")


def _validate_borrow(m, field, where, errs):
    """A borrowed magnitude {from, pct?, default?, add?, round?, min?}."""
    for k in m:
        if k not in BORROW_FIELDS:
            errs.append(f"{where}: {field} borrowed value has unknown key '{k}' "
                        f"(approved: {_j(BORROW_FIELDS)})")
    msg = borrow_source_error(str(m["from"]))
    if msg:
        errs.append(f"{where}: {msg}")
    for k in ("pct", "default", "add", "min"):
        if k in m and not _is_number(m[k]):
            errs.append(f"{where}: {field} borrowed '{k}' must be a number")
    if "round" in m and m["round"] not in ROUNDINGS:
        errs.append(f"{where}: {field} borrowed round '{m['round']}' unknown ({_j(ROUNDINGS)})")


def borrow_source_error(source):
    """Empty when a magnitude may borrow from `source`, otherwise the reason."""
    if source in BORROW_SOURCES:
        return ""
    prefix = source.split(".")[0]
    if prefix in BORROW_UNIT_PREFIXES and source.count(".") == 2:
        inner = source[len(prefix) + 1:]
        if inner.split(".")[0] in UNREADABLE_NAMESPACES:
            return (f"cannot borrow from '{source}': a number cannot be read from a "
                    "group or from pressure")
        msg = _value_path_error(inner)
        return "" if not msg else f"borrowed from '{source}': {msg}"
    return (f"cannot borrow from '{source}' ({_j(BORROW_SOURCES)}, or "
            f"{'/'.join(BORROW_UNIT_PREFIXES)}.<value path>)")


def _validate_damage_type(t, where, errs):
    unknown = "'%s' is not in damage_types.json, so no resistance key can match it and the damage arrives unresisted"
    if isinstance(t, str):
        if t not in DAMAGE_TYPES:
            errs.append(f"{where}: {unknown % t}")
    elif isinstance(t, dict):
        total = 0.0
        for name in t:
            if str(name) not in DAMAGE_TYPES:
                errs.append(f"{where}: {unknown % name}")
            if not _is_number(t[name]):
                errs.append(f"{where}: damage split share for '{name}' must be a number")
            else:
                total += float(t[name])
        if not t or abs(total - 1.0) > 0.001:
            errs.append(f"{where}: damage split shares sum to {total}, must be 1")
    else:
        errs.append(f"{where}: damage 'type' must be a name or a {{type: share}} split")


# ── Names ───────────────────────────────────────────────────────────────────
def _value_path_error(path):
    """Empty string when `path` is a valid value path, otherwise the reason."""
    parts = path.split(".")
    # The one 3-word path: skills.element.<element>.
    if len(parts) == 3 and parts[0] == "skills" and parts[1] == "element":
        if parts[2] in ELEMENTS:
            return ""
        return f"unknown element '{parts[2]}' in '{path}' (approved: {_j(ELEMENTS)})"
    if len(parts) != 2:
        return f"value path '{path}' must look like namespace.name"
    ns, name = parts
    if ns not in NAMESPACES:
        return f"unknown namespace '{ns}' in '{path}' (approved: {_j(NAMESPACES)})"
    if ns == "attribute":
        if name not in ATTRIBUTES:
            return f"unknown attribute '{name}' in '{path}'"
    elif ns == "resource":
        if name not in RESOURCES:
            return f"unknown resource '{name}' in '{path}' (approved: {_j(RESOURCES)})"
    elif ns == "stat":
        if name not in STATS:
            return f"unknown stat '{name}' in '{path}' (approved: {_j(STATS)})"
    elif ns == "skill":
        if not SKILL_IDS:
            return f"skills.json is not loaded, so '{path}' cannot be checked"
        if name not in SKILL_IDS:
            return f"unknown skill '{name}' in '{path}'"
    elif ns == "skills":
        if name not in SKILL_GROUP_CATEGORIES:
            return (f"unknown skill group '{name}' in '{path}' (approved: "
                    f"skills.element.<element>, {_j(SKILL_GROUP_CATEGORIES)})")
    elif ns == "attributes":
        if name != "all":
            return f"unknown attribute group '{name}' in '{path}' (approved: attributes.all)"
    elif ns in ("affinity", "pressure"):
        if name not in ELEMENTS:
            return f"unknown element '{name}' in '{path}' (approved: {_j(ELEMENTS)})"
    elif ns == "resist":
        if not (name in RESIST_GROUPS or name in DAMAGE_TYPES or name in AFFLICTIONS):
            return (f"unknown resist '{name}' in '{path}' (a damage type, an affliction, "
                    f"or {_j(RESIST_GROUPS)})")
    return ""


def _pct_of_error(source):
    """pct_of names a value path, or target./caster. plus a CombatStats.DERIVED key."""
    for prefix in ("target.", "caster."):
        if source.startswith(prefix):
            key = source[len(prefix):]
            if key in DERIVED:
                return ""
            return f"pct_of '{source}': '{key}' is not a derived stat"
    if source.split(".")[0] in UNREADABLE_NAMESPACES:
        return f"pct_of '{source}': a number cannot be read from a group or from pressure"
    return _value_path_error(source)


def _status_error(status_name):
    if not STATUS_NAMES:
        return f"statuses.json is not loaded, so '{status_name}' cannot be checked"
    if status_name not in STATUS_NAMES:
        return f"status '{status_name}' is not in statuses.json"
    return ""


def _condition_error(cond):
    """One entry of an `if` list. Empty string means valid."""
    if isinstance(cond, str):
        if _is_perk_condition(cond):
            return ""
        return f"unknown condition '{cond}'"
    if isinstance(cond, dict) and len(cond) == 1:
        key = str(next(iter(cond)))
        arg = str(cond[key])
        if key == "target_has":
            if arg in STATUS_TAGS or not _status_error(arg):
                return ""
            return f"target_has '{arg}' is neither a status nor a status tag"
        if key == "target_is":
            if arg in CREATURE_TAGS:
                return ""
            return f"target_is '{arg}' is not a creature tag"
        if key == "target_lacks":
            if arg in STATUS_TAGS or not _status_error(arg):
                return ""
            return f"target_lacks '{arg}' is neither a status nor a status tag"
        if key == "spell_school":
            if arg.lower() in SPELL_SCHOOLS:
                return ""
            return f"spell_school '{arg}' is not a school ({_j(SPELL_SCHOOLS)})"
        return f"unknown condition form '{key}' (approved: {_j(CONDITION_KEYS)})"
    return f"a condition is a name or a one-key object, got {cond}"


# ── Auras and zones (stage 2b, Task 8) ──────────────────────────────────────
# Mirrors EffectVocab.validate_aura / validate_zone / _validate_inside_effect.

def _check_inside_effect(e, label, errs):
    """One effect of a while_inside list: a read-time modify or a per-turn op."""
    if not isinstance(e, dict):
        errs.append(f"{label}: an effect must be an object")
        return
    op = str(e.get("op", ""))
    if op != "modify":
        if op not in PER_TURN_OPS:
            errs.append(f"{label}: while_inside fires {_j(PER_TURN_OPS)} each turn; "
                        f"'{op}' is not one of them")
            return
        errs.extend(check_effect(e, label))
        return
    errs.extend(check_effect(e, label))
    if str(e.get("value", "")).split(".")[0] not in READ_TIME_NAMESPACES:
        errs.append(f"{label}: a while_inside modify is read where the number is used, so "
                    f"it changes {'/'.join(READ_TIME_NAMESPACES)}. values only")
    if str(e.get("mode", "")) not in READ_TIME_MODES:
        errs.append(f"{label}: a while_inside modify adds or multiplies ({_j(READ_TIME_MODES)})")
    for k in ("chance", "save", "on_save", "if", "scale", "bonus_vs", "cleared_by"):
        if k in e:
            errs.append(f"{label}: '{k}' cannot work on a number that is read, not applied")
    m = e.get("amount", 0)
    if isinstance(m, dict):
        if "from" in m and str(m["from"]) not in READ_TIME_BORROWS:
            errs.append(f"{label}: a while_inside modify may borrow only {_j(READ_TIME_BORROWS)}")
        elif "pct_of" in m and not str(m["pct_of"]).startswith("target."):
            errs.append(f"{label}: a while_inside pct_of reads the recipient's own sheet (target.<stat>)")
        elif "from" not in m and "pct_of" not in m:
            errs.append(f"{label}: a while_inside modify's amount is a number, a status borrow or a pct_of")


def check_aura(d, where):
    """Validate one auras.json definition; returns error strings."""
    errs = []
    for k in d:
        if not str(k).startswith("_") and k not in AURA_FIELDS:
            errs.append(f"{where}: unknown aura field '{k}' (approved: {_j(AURA_FIELDS)})")
    if "affects" in d and d["affects"] not in AURA_AFFECTS:
        errs.append(f"{where}: aura affects '{d['affects']}' unknown ({_j(AURA_AFFECTS)})")
    if "radius" in d and not _is_number(d["radius"]):
        errs.append(f"{where}: aura radius must be a number")
    effects = d.get("while_inside", [])
    if not isinstance(effects, list) or not effects:
        errs.append(f"{where}: an aura needs a non-empty 'while_inside' list of effects")
        return errs
    for i, e in enumerate(effects):
        label = f"{where}.while_inside[{i}]"
        if isinstance(e, dict) and "to" in e:
            errs.append(f"{label}: an aura's effect has no 'to'; the aura's affects and radius decide")
        _check_inside_effect(e, label, errs)
    return errs


def check_zone(d, where):
    """Validate one zones.json definition; returns error strings."""
    errs = []
    count = 0
    for k in d:
        if not str(k).startswith("_") and k not in ZONE_FIELDS:
            errs.append(f"{where}: unknown zone field '{k}' (approved: {_j(ZONE_FIELDS)})")
    if "affects" in d and d["affects"] not in ZONE_AFFECTS:
        errs.append(f"{where}: zone affects '{d['affects']}' unknown ({_j(ZONE_AFFECTS)})")
    if "drift" in d and d["drift"] not in ZONE_DRIFTS:
        errs.append(f"{where}: zone drift '{d['drift']}' unknown")
    if "pair" in d and d["pair"] not in ZONE_PAIR_ROLES:
        errs.append(f"{where}: zone pair '{d['pair']}' unknown")
    for trigger in ZONE_TRIGGERS:
        if trigger not in d:
            continue
        effects = d[trigger]
        if not isinstance(effects, list):
            errs.append(f"{where}.{trigger} must be a list of effects")
            continue
        count += len(effects)
        for i, e in enumerate(effects):
            label = f"{where}.{trigger}[{i}]"
            if not isinstance(e, dict):
                errs.append(f"{label}: an effect must be an object")
                continue
            op = str(e.get("op", ""))
            if "to" in e and e["to"] not in ZONE_SELECTORS:
                errs.append(f"{label}: a zone effect's 'to' is one of {_j(ZONE_SELECTORS)}")
            if op in POSITION_OPS and "to" in e:
                errs.append(f"{label}: a {op} happens once at the tile; give the zone an "
                            "'affects' instead of a 'to'")
            if op == "summon" and e.get("from", "") == "corpse" and trigger != "on_death_inside":
                errs.append(f"{label}: summon from 'corpse' only means something in on_death_inside")
            if trigger == "while_inside":
                _check_inside_effect(e, label, errs)
                continue
            errs.extend(check_effect(e, label))
            if op == "modify" and str(e.get("mode", "")) in ("fortify", "drain", "set", "multiply"):
                errs.append(f"{label}: a lasting modify in {trigger} would never be released; "
                            "put it in while_inside")
    if count == 0:
        errs.append(f"{where}: a zone with no effects under any trigger does nothing")
    return errs
