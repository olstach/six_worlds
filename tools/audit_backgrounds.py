#!/usr/bin/env python3
"""Audit backgrounds for mechanical duplication and skill coverage.

Two questions, both asked the way the game asks them:

  1. Which backgrounds do the same thing? Compared on `starting_skills`, then
     on attribute modifiers. What matters is not that two exist but whether one
     birth can roll both — a universal background and a realm re-skin of it are
     always in the same pool, two backgrounds locked to different realms never
     are.

  2. Which skills is a character unlikely to start with? Measured as *expected
     starting points*: every playable birth, its own weighted background roll,
     averaged. Counting entries would treat a weight-1 background the same as a
     weight-7 one, and the roll does not.

Run from anywhere:  python3 tools/audit_backgrounds.py
Nothing is written; it prints a report. Exit code is always 0 — these are
judgement calls, not dangling references (that is validate_data.py's job).
"""
import json
import os
from collections import defaultdict
from itertools import combinations

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATTRS = ["strength", "finesse", "constitution", "focus", "awareness", "charm", "luck"]


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return json.load(fh)


def records(d):
    return {k: v for k, v in d.items() if not k.startswith("_") and isinstance(v, dict)}


def rule(title, char="="):
    print("\n" + char * 78)
    print(title)
    print(char * 78)


def main():
    data = load("resources/data/races.json")
    races = records(data["races"])
    bgs = records(data["backgrounds"])
    skills = load("resources/data/skills.json")["skills"]

    playable = [b for b, v in races.items() if int(v.get("reincarnation_weight", 0)) > 0]

    def sk(bid):
        return bgs[bid].get("starting_skills", {})

    def attrs(bid):
        m = bgs[bid].get("attribute_modifiers") or {}
        return [int(m.get(a, 0)) for a in ATTRS]

    def pool(birth):
        return {k for k, v in bgs.items()
                if not (v.get("available_races") or []) or birth in v["available_races"]}

    pools = {b: pool(b) for b in playable}

    def collisions(members):
        """Births that can roll more than one of these — the only case that bites."""
        return sum(1 for b in playable if len(set(members) & pools[b]) > 1)

    def label(bid):
        return f"{bgs[bid].get('name', bid)} `{bid}` w{bgs[bid].get('weight', 1)}"

    # ── 1. duplication ──────────────────────────────────────────────────────
    for title, keyfn in (
        ("Identical — same skills at the same levels",
         lambda b: tuple(sorted(sk(b).items()))),
        ("Same skills, different levels",
         lambda b: tuple(sorted(sk(b)))),
    ):
        groups = defaultdict(list)
        for bid in sorted(bgs):
            if sk(bid):
                groups[keyfn(bid)].append(bid)
        groups = {k: v for k, v in groups.items() if len(v) > 1}
        rule(f"{title}  —  {len(groups)} clusters, "
             f"{sum(len(v) for v in groups.values())} backgrounds")
        for key, members in sorted(groups.items(), key=lambda kv: -collisions(kv[1])):
            c = collisions(members)
            flag = "  <-- collides" if c else ""
            print(f"\n  {' + '.join(f'{s} {l}' for s, l in key) if isinstance(key[0], tuple) else ' + '.join(key)}"
                  f"   ({c}/{len(playable)} births can roll more than one){flag}")
            for m in members:
                print(f"      {label(m):46s} {dict(sk(m))}")

    # ── 2. strictly dominated ───────────────────────────────────────────────
    rule("Strictly dominated — identical skills, one has attributes >= the other "
         "everywhere")
    found = 0
    for a, b in combinations(sorted(bgs), 2):
        if not sk(a) or sk(a) != sk(b):
            continue
        for lo, hi in ((a, b), (b, a)):
            vlo, vhi = attrs(lo), attrs(hi)
            if all(x <= y for x, y in zip(vlo, vhi)) and vlo != vhi:
                found += 1
                both = sum(1 for p in playable if {lo, hi} <= pools[p])
                print(f"\n  {label(hi)} dominates {label(lo)}   "
                      f"(both rollable by {both}/{len(playable)} births)")
                print(f"      skills {dict(sk(a))}")
                for x in (hi, lo):
                    print(f"      {x:20s} "
                          f"{ {k: v for k, v in zip(ATTRS, attrs(x)) if v} }")
    if not found:
        print("\n  none")

    # ── 3. attribute modifier coverage ──────────────────────────────────────
    def pool_name(bid):
        ar = bgs[bid].get("available_races") or []
        if not ar:
            return "universal"
        rs = {races[b]["realm"] for b in ar if b in races}
        return next(iter(rs)) if len(rs) == 1 else "cross-realm"

    rule("Attribute modifiers — a background with none gives strictly less than "
         "its peers")
    cover = defaultdict(lambda: [0, []])
    for bid, v in bgs.items():
        p = pool_name(bid)
        cover[p][0] += 1
        if not {a: x for a, x in (v.get("attribute_modifiers") or {}).items() if x}:
            cover[p][1].append(bid)
    for p, (n, empty) in sorted(cover.items(), key=lambda kv: -len(kv[1][1])):
        print(f"\n  {p:12s} {len(empty):3d} of {n:3d} have none ({len(empty)/n*100:3.0f}%)")
        if empty:
            print("      " + ", ".join(sorted(empty)))

    # ── 4. skill representation ─────────────────────────────────────────────
    exp = defaultdict(float)
    for b in playable:
        weighted = [(k, float(bgs[k].get("weight", 1))) for k in pools[b]]
        tot = sum(w for _, w in weighted)
        for bid, w in weighted:
            for s, lvl in sk(bid).items():
                exp[s] += (w / tot) * lvl / len(playable)

    headline = defaultdict(list)   # background is *about* the skill: level 2+
    minor = defaultdict(list)
    for bid, v in bgs.items():
        for s, lvl in v.get("starting_skills", {}).items():
            (headline if lvl >= 2 else minor)[s].append(bid)

    from_birth = defaultdict(int)
    for b in playable:
        for s in races[b].get("starting_skills", {}):
            from_birth[s] += 1

    mean = sum(exp.values()) / len(skills)
    rule(f"Skill representation — mean {mean:.3f} expected points, "
         f"{sum(exp.values()):.2f} per character")
    print(f"\n{'skill':16s} {'cat':7s} {'elem':6s} {'head':>4s} {'minor':>6s} "
          f"{'births':>7s} {'exp':>6s} {'vs mean':>8s}")
    print("-" * 68)
    for s in sorted(skills, key=lambda x: exp[x]):
        r = exp[s] / mean
        mark = "  DEAD" if not headline[s] else ("  thin" if r < 0.5 else
                                                 ("  heavy" if r > 1.8 else ""))
        print(f"{s:16s} {skills[s]['category'][:7]:7s} "
              f"{skills[s].get('element', '-'):6s} {len(headline[s]):4d} "
              f"{len(minor[s]):6d} {from_birth[s]:7d} {exp[s]:6.3f} {r:7.2f}x{mark}")

    # The universal pool is most of every roll, so what it cannot teach is
    # effectively unreachable for a birth without the right restricted unlock.
    universal = [k for k, v in bgs.items() if not (v.get("available_races") or [])]
    uw = sum(float(bgs[k].get("weight", 1)) for k in universal)
    shares = []
    for b in playable:
        tot = sum(float(bgs[k].get("weight", 1)) for k in pools[b])
        shares.append(uw / tot)
    rule(f"The universal pool is {sum(shares)/len(shares)*100:.0f}% of the average "
         f"roll ({len(universal)} backgrounds, range "
         f"{min(shares)*100:.0f}-{max(shares)*100:.0f}%)")
    uni_head = {s for k in universal for s, l in sk(k).items() if l >= 2}
    print("\nSkills no universal background is about — a character can only start "
          "strong in\nthese if their birth unlocks the right restricted background:")
    for s in sorted(set(skills) - uni_head,
                    key=lambda x: (skills[x]["category"], x)):
        owners = sorted(headline[s])
        reach = {r for k in owners for r in (bgs[k].get("available_races") or [])
                 if r in playable}
        where = ", ".join(owners) if owners else "NOTHING AT ALL"
        print(f"  {s:14s} ({skills[s]['category'][:7]:7s}/{skills[s].get('element','-'):5s}) "
              f"reachable by {len(reach):2d}/{len(playable)} births — {where}")


if __name__ == "__main__":
    main()
