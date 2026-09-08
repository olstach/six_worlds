#!/usr/bin/env python3
"""Audit the spell list for duplication, unreachable behaviour and dead fields.

Spells are properly structured — school, level, mana, damage, target, statuses —
so most of this is arithmetic rather than reading prose. The parts that are not
structured are the interesting ones: `special` is a free-form dict, and whether a
spell's targeting is ever branched on decides whether it does anything at all.

Run from anywhere:  python3 tools/audit_spells.py
Prints a report, writes nothing, always exits 0.
"""
import json
import os
import re
from collections import Counter, defaultdict
from itertools import combinations

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Targeting strings the combat code actually branches on. get_spell() maps
# target.type onto these; anything it does not recognise is passed through
# verbatim and then matches no branch.
HANDLED_TARGETING = {"single", "single_ally", "single_corpse", "self", "aoe", "ground", "chain"}

# The `special` keys CombatManager._apply_spell_special actually branches on.
# Matching key names against every string literal in the codebase overcounts
# wildly — "healing", "melee", "allies" and the like appear all over for
# unrelated reasons — so this list is read off the dispatcher itself.
HANDLED_SPECIAL = {"dispels_all_battlefield", "see_through_stealth", "stealth_bonus"}


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return json.load(fh)


def records(d):
    return {k: v for k, v in d.items() if not k.startswith("_") and isinstance(v, dict)}


def scripts():
    out = []
    for base, _d, files in os.walk(ROOT):
        if any(x in base for x in (".git", "__pycache__", ".worktrees")):
            continue
        out += [os.path.join(base, f) for f in files if f.endswith((".gd", ".tscn"))]
    return out


def rule(t):
    print("\n" + "=" * 78)
    print(t)
    print("=" * 78)


def targeting_of(spell):
    """Reproduce CombatManager.get_spell()'s normalisation."""
    if "aoe" in spell:
        return "aoe"
    t = spell.get("target") or {}
    tt = t.get("type", "single")
    el = t.get("eligible", "enemy")
    if tt == "single":
        return {"ally": "single_ally", "corpse": "single_corpse"}.get(el, "single")
    if tt in ("aoe", "circle"):
        return "aoe"
    return tt          # self, ground, chain, and everything unrecognised


def main():
    spells = records(load("resources/data/spells.json")["spells"])
    statuses = {s["name"] for s in load("resources/data/statuses.json")["statuses"]}
    _st = load("resources/data/summon_templates.json")
    summons = set(records(_st.get("templates", _st)))
    code = ""
    for p in scripts():
        with open(p, encoding="utf-8", errors="ignore") as fh:
            code += fh.read()
    lits = set(re.findall(r'"([a-z0-9_]{3,60})"', code))

    print(f"{len(spells)} spells")

    # ── targeting that reaches no branch ────────────────────────────────────
    rule("Targeting — spells whose target type the combat code never branches on")
    bad = defaultdict(list)
    for k, v in spells.items():
        t = targeting_of(v)
        if t not in HANDLED_TARGETING:
            bad[t].append(k)
    total = sum(len(v) for v in bad.values())
    print(f"\n  {total} spells across {len(bad)} unhandled target types")
    for t in sorted(bad, key=lambda x: -len(bad[x])):
        print(f"\n    target.type '{t}'  ({len(bad[t])})")
        for k in sorted(bad[t]):
            print(f"      {spells[k].get('name',k):32s} `{k}`  L{spells[k].get('level')}  "
                  f"{spells[k].get('description','')[:44]}")
    if not bad:
        print("\n  none")

    # ── the special vocabulary ──────────────────────────────────────────────
    rule("`special` — typed effects against the frozen legacy backlog")
    reg = load("resources/data/spell_effects.json")
    types = reg["effects"]
    legacy_frozen = set(reg.get("legacy_keys", []))
    typed = Counter()
    legacy = Counter()
    with_typed = 0
    for v in spells.values():
        sp = v.get("special")
        if not isinstance(sp, dict):
            continue
        fx = sp.get("effects", [])
        if fx:
            with_typed += 1
        for e in fx:
            typed[e.get("type", "?")] += 1
        legacy.update(sp.get("legacy", {}).keys())
    impl = [t for t, spec in types.items() if spec.get("implemented")]
    print(f"\n  registry: {len(types)} effect types, {len(impl)} of them implemented")
    print(f"    implemented: {', '.join(sorted(impl))}")
    print(f"\n  typed effect entries in use: {sum(typed.values())} across {with_typed} spells")
    for t, n in typed.most_common():
        mark = "" if types.get(t, {}).get("implemented") else "   (declared, not yet implemented)"
        print(f"    {t:24s} {n:3d}{mark}")
    print(f"\n  legacy keys still in use: {len(legacy)} distinct, {sum(legacy.values())} uses")
    print(f"  frozen list holds {len(legacy_frozen)} — the backlog may shrink, never grow")
    flags = [k for k, _n in legacy.items()
             if all((v.get("special") or {}).get("legacy", {}).get(k) is True
                    for v in spells.values()
                    if k in (v.get("special") or {}).get("legacy", {}))]
    print(f"  of those, {len(flags)} are bare `true` with no value — migrating one means")
    print(f"  deciding a number, which is design work rather than a rename")
    print("\n  most used legacy keys:")
    for k, n in legacy.most_common(10):
        print(f"    {k:34s} {n:3d}")

    # ── dangling references ─────────────────────────────────────────────────
    rule("Dangling references")
    miss = []
    for k, v in spells.items():
        for st in (v.get("statuses_caused") or []) + (v.get("statuses_removed") or []):
            if st not in statuses:
                miss.append((k, f"status '{st}' is not in statuses.json"))
        s = v.get("summon")
        for sid in ([s] if isinstance(s, str) else (s or []) if isinstance(s, list) else []):
            if isinstance(sid, str) and sid not in summons:
                miss.append((k, f"summon '{sid}' is not a summon template"))
    for k, why in miss:
        print(f"  {k}: {why}")
    if not miss:
        print("  none")

    # ── mechanical duplicates ───────────────────────────────────────────────
    rule("Mechanically identical spells")

    def sig(v):
        # damage and heal are sometimes dicts (scaling tables), so everything that
        # can be structured is compared as canonical JSON.
        return (tuple(sorted(v.get("schools", []))), v.get("level"),
                json.dumps(v.get("damage"), sort_keys=True),
                v.get("damage_type"),
                json.dumps(v.get("heal"), sort_keys=True),
                tuple(sorted(v.get("statuses_caused") or [])), targeting_of(v),
                json.dumps(v.get("aoe"), sort_keys=True),
                # what a summon actually calls up is the whole point of a summon
                # spell, so two that differ only there are not duplicates. Same
                # for `aura` and `special`: radiant_visage and shining_mirage
                # matched on every compared field while one buffed allies and the
                # other confused enemies, because the difference lived in fields
                # this signature was not looking at.
                json.dumps(v.get("summon"), sort_keys=True),
                json.dumps(v.get("aura"), sort_keys=True),
                tuple(sorted((v.get("special") or {}).keys())))

    groups = defaultdict(list)
    for k, v in spells.items():
        groups[sig(v)].append(k)
    dupes = {s: ks for s, ks in groups.items() if len(ks) > 1}
    print(f"\n  {len(dupes)} groups sharing school, level, damage, statuses, targeting and AoE")
    for s, ks in sorted(dupes.items(), key=lambda kv: -len(kv[1])):
        v = spells[ks[0]]
        print(f"\n    {', '.join(v.get('schools',[]))} L{v.get('level')} · "
              f"dmg {v.get('damage')} · {targeting_of(v)}")
        for k in ks:
            print(f"      {spells[k].get('name',k):30s} `{k}`  mana {spells[k].get('mana_cost')}"
                  f"  — {spells[k].get('description','')[:52]}")

    # ── balance ─────────────────────────────────────────────────────────────
    rule("Balance — damage and cost against level")
    dmg = defaultdict(list)
    for k, v in spells.items():
        d = v.get("damage")
        if isinstance(d, bool):
            continue
        if isinstance(d, (int, float)) and v.get("level"):
            dmg[int(v["level"])].append((float(d), k))
    print(f"\n  {'level':>5s} {'n':>4s} {'min':>6s} {'median':>7s} {'max':>6s}   widest spread")
    for lv in sorted(dmg):
        vals = sorted(x[0] for x in dmg[lv])
        lo, hi = dmg[lv][0], dmg[lv][0]
        for x in dmg[lv]:
            lo = x if x[0] < lo[0] else lo
            hi = x if x[0] > hi[0] else hi
        med = vals[len(vals) // 2]
        print(f"  {lv:5d} {len(vals):4d} {vals[0]:6.0f} {med:7.0f} {vals[-1]:6.0f}   "
              f"{lo[1]} .. {hi[1]}")
    inversions = []
    for l1, l2 in combinations(sorted(dmg), 2):
        if l2 < l1 + 2:
            continue
        best1 = max(dmg[l1])
        worst2 = min(dmg[l2])
        if worst2[0] < best1[0]:
            inversions.append((l1, best1, l2, worst2))
    print(f"\n  {len(inversions)} level pairs where the weakest high spell is below the "
          f"strongest low one:")
    for l1, b1, l2, w2 in inversions[:10]:
        print(f"    L{l1} `{b1[1]}` {b1[0]:.0f} dmg  >  L{l2} `{w2[1]}` {w2[0]:.0f} dmg")

    mana = defaultdict(list)
    for k, v in spells.items():
        if isinstance(v.get("mana_cost"), (int, float)) and v.get("level"):
            mana[int(v["level"])].append((float(v["mana_cost"]), k))
    print(f"\n  mana by level:")
    for lv in sorted(mana):
        vals = sorted(x[0] for x in mana[lv])
        print(f"    L{lv:<2d} n={len(vals):3d}  {vals[0]:3.0f} – {vals[-1]:3.0f}  "
              f"median {vals[len(vals)//2]:3.0f}")

    # ── shape ───────────────────────────────────────────────────────────────
    rule("Shape — spells per school and level")
    grid = defaultdict(Counter)
    for v in spells.values():
        for s in v.get("schools", []):
            grid[s][int(v.get("level", 0))] += 1
    lvls = sorted({l for c in grid.values() for l in c})
    print(f"\n  {'school':14s} " + " ".join(f"{l:>3d}" for l in lvls) + "   total")
    for s in sorted(grid):
        print(f"  {s:14s} " + " ".join((f"{grid[s][l]:>3d}" if grid[s][l] else "  .")
                                       for l in lvls) + f"   {sum(grid[s].values()):5d}")
    holes = [(s, l) for s in grid for l in lvls if not grid[s][l]]
    print(f"\n  empty school/level cells: {len(holes)} of {len(grid)*len(lvls)}")
    for s, l in holes:
        print(f"    {s} has nothing at level {l}")


if __name__ == "__main__":
    main()
