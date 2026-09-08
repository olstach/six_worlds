#!/usr/bin/env python3
"""Audit the perk trees for duplication, dead mechanics and unreachable entries.

Perks are almost entirely prose: a perk carries a name, a gate, a description and
a flavour line, and nothing else. What a perk *does* lives in whichever script
asks `PerkSystem.has_perk(character, "<id>")`. So the first question this asks is
which perks any script has ever heard of, and the rest follows from reading the
gates and the descriptions.

Run from anywhere:  python3 tools/audit_perks.py
Prints a report, writes nothing, always exits 0.
"""
import json
import os
import re
import sys
from collections import Counter, defaultdict
from itertools import combinations

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mirrors PerkSystem's own constants — a perk gated on a category outside these
# resolves to an empty skill list and can never be taken.
WEAPON_SKILLS = ["swords", "martial_arts", "ranged", "daggers", "axes", "unarmed",
                 "spears", "maces"]
MAGIC_SCHOOLS = ["space_magic", "white_magic", "black_magic", "air_magic", "fire_magic",
                 "water_magic", "earth_magic", "sorcery", "enchantment", "summoning"]
ELEMENTAL_MAGICS = ["space_magic", "air_magic", "fire_magic", "water_magic", "earth_magic"]
CATEGORIES = {"weapon_skills", "weapon_skill", "different_weapon_skills",
              "elemental_magics", "elemental_magic", "magic_school", "magic_schools"}
ATTRIBUTES = ["strength", "constitution", "finesse", "focus", "awareness", "charm", "luck"]
MAX_BUYABLE_SKILL = 10        # skills are purchasable to 10; items/traits push to 15

STOP = set("""a an and are as at be but by can does for from has have if in into is it its not
of on or that the their them then there they this to when while with you your each per level
than only own all any some more most less least first second next other same both while after
before during within without against toward across around also just even still never always
one two three four five six seven eight nine ten""".split())


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
        return json.load(fh)


def records(d):
    return {k: v for k, v in d.items() if not k.startswith("_") and isinstance(v, dict)}


def walk(patterns):
    out = []
    for base, _dirs, files in os.walk(ROOT):
        if any(p in base for p in (".git", "__pycache__", ".worktrees")):
            continue
        for f in files:
            if f.endswith(patterns):
                out.append(os.path.join(base, f))
    return out


def rule(title):
    print("\n" + "=" * 78)
    print(title)
    print("=" * 78)


def words(text):
    return {w for w in re.findall(r"[a-z]+", text.lower()) if w not in STOP and len(w) > 2}


# Stat words a description attaches a percentage to. Comparing "+10% damage" with
# "+5% dodge" says nothing, so the balance check only ever compares like with like.
STATS = ("damage", "attack", "crit chance", "crit", "dodge", "armor", "spellpower",
         "movement", "initiative", "stamina", "mana", "healing", "duration", "range",
         "accuracy", "hp", "resistance", "cost", "chance")


def stat_promises(text):
    """{stat: largest percentage the description attaches to it}."""
    out = {}
    low = text.lower()
    for m in re.finditer(r"(\d+(?:\.\d+)?)\s*%\s*(?:bonus\s+|additional\s+|more\s+|extra\s+)?"
                         r"(?:of\s+\w+\s+)?([a-z ]{0,24})", low):
        val, tail = float(m.group(1)), m.group(2)
        for st in STATS:
            if tail.startswith(st) or (" " + st) in (" " + tail):
                out[st] = max(out.get(st, 0.0), val)
                break
    return out


def main():
    data = load("resources/data/perks.json")
    skill_perks = records(data["skill_perks"])
    cross_perks = records(data["cross_perks"])
    perks = {**skill_perks, **cross_perks}
    skills = set(load("resources/data/skills.json")["skills"])

    # ── what any script has heard of ────────────────────────────────────────
    code_lits, data_lits = set(), set()
    for path in walk((".gd", ".tscn")):
        with open(path, encoding="utf-8", errors="ignore") as fh:
            code_lits |= set(re.findall(r'"([a-z0-9_]{3,60})"', fh.read()))
    for path in walk((".json",)):
        if path.endswith("perks.json"):
            continue
        with open(path, encoding="utf-8", errors="ignore") as fh:
            data_lits |= set(re.findall(r'"([a-z0-9_]{3,60})"', fh.read()))

    wired = {k for k in perks if k in code_lits}
    data_only = {k for k in perks if k not in wired and k in data_lits}
    inert = [k for k in perks if k not in wired and k not in data_only]

    rule(f"Wiring — {len(wired)} of {len(perks)} perks are named by a script "
         f"({len(wired)/len(perks)*100:.0f}%)")
    print(f"\n  named by a script      {len(wired):4d}   something reads has_perk() for it")
    print(f"  named only by data     {len(data_only):4d}   {', '.join(sorted(data_only)) or '—'}")
    print(f"  named by nothing       {len(inert):4d}   prose with no mechanism behind it")

    by_skill, wired_by_skill = Counter(), Counter()
    for k, v in skill_perks.items():
        s = v.get("skill", "") or "(attribute-gated)"
        by_skill[s] += 1
        if k in wired:
            wired_by_skill[s] += 1
    print(f"\n  {'skill':18s} {'perks':>5s} {'wired':>6s}")
    for s in sorted(by_skill, key=lambda x: (wired_by_skill[x] / by_skill[x], -by_skill[x])):
        bar = "#" * int(wired_by_skill[s] / by_skill[s] * 20)
        print(f"  {s:18s} {by_skill[s]:5d} {wired_by_skill[s]:5d} {bar}")
    print(f"\n  cross perks wired: {len([k for k in cross_perks if k in wired])}/{len(cross_perks)}")

    # ── unreachable: a gate no character can pass ───────────────────────────
    rule("Unreachable — gates that can never be satisfied")
    dead = []
    for k, v in skill_perks.items():
        s = v.get("skill", "")
        lvl = int(v.get("required_level", 1))
        if s and s not in skills:
            dead.append((k, f"skill '{s}' is not a skill — skills.get() returns 0, so the "
                            f"level {lvl} gate never passes"))
        elif s and lvl > MAX_BUYABLE_SKILL:
            dead.append((k, f"needs {s} {lvl}, above the purchasable cap of {MAX_BUYABLE_SKILL}"))
        for rs, rl in (v.get("also_requires") or {}).items():
            if rs not in skills:
                dead.append((k, f"also_requires '{rs}', which is not a skill"))
    for k, v in perks.items():
        sr = v.get("special_requirement")
        if not sr:
            continue
        ok = False
        if "_affinity_" in sr:
            ok = True
        elif any(sr.startswith(a + "_") and sr[len(a) + 1:].isdigit() for a in ATTRIBUTES):
            ok = True
        elif sr.startswith("any_") and "_at_" in sr:
            cat = sr.split("_at_")[0][4:]
            head = cat.split("_")[0]
            if head.isdigit():
                cat = cat[len(head) + 1:]
            ok = cat in CATEGORIES
            if not ok:
                dead.append((k, f"special_requirement '{sr}' names category '{cat}', which "
                                f"_get_skills_for_category does not know — returns []"))
                continue
        if not ok:
            dead.append((k, f"special_requirement '{sr}' matches no pattern the parser "
                            f"handles — _check_special_requirement returns false"))
    for k, why in dead:
        print(f"\n  {perks[k].get('name', k)}  `{k}`")
        print(f"      {why}")
    if not dead:
        print("\n  none")

    # ── dangling references ─────────────────────────────────────────────────
    rule("Dangling references")
    bad = []
    for k, v in perks.items():
        for pre in v.get("requires_perks") or []:
            for opt in (pre if isinstance(pre, list) else [pre]):
                if opt not in perks:
                    bad.append((k, f"requires_perks -> '{opt}' does not exist"))
    for k, v in cross_perks.items():
        for s in (v.get("requirements") or {}):
            if s not in skills:
                bad.append((k, f"requirements -> '{s}' is not a skill"))
    for k, why in bad:
        print(f"  {k}: {why}")
    if not bad:
        print("  none")

    # ── duplicates and near-duplicates ──────────────────────────────────────
    rule("Duplicate and near-duplicate perks")
    norm = {k: re.sub(r"[^a-z0-9 ]", "", v.get("description", "").lower()) for k, v in perks.items()}
    same = defaultdict(list)
    for k, t in norm.items():
        if t:
            same[t].append(k)
    exact = {t: ks for t, ks in same.items() if len(ks) > 1}
    print(f"\nIdentical descriptions: {len(exact)}")
    for t, ks in exact.items():
        print(f"  {', '.join(ks)}")
        print(f"      \"{perks[ks[0]].get('description','')[:110]}\"")

    wordsets = {k: words(v.get("description", "")) for k, v in perks.items()}
    near = []
    for a, b in combinations(sorted(perks), 2):
        wa, wb = wordsets[a], wordsets[b]
        if len(wa) < 5 or len(wb) < 5:
            continue
        j = len(wa & wb) / len(wa | wb)
        if j >= 0.6 and norm[a] != norm[b]:
            near.append((j, a, b))
    near.sort(reverse=True)
    print(f"\nNear-duplicates (Jaccard >= 0.60 on description wording): {len(near)}")
    for j, a, b in near[:25]:
        sa = perks[a].get("skill", perks[a].get("category", "cross"))
        sb = perks[b].get("skill", perks[b].get("category", "cross"))
        print(f"\n  {j:.2f}  {perks[a].get('name',a)} `{a}` ({sa} {perks[a].get('required_level','')})"
              f"  vs  {perks[b].get('name',b)} `{b}` ({sb} {perks[b].get('required_level','')})")
        print(f"        A: {perks[a].get('description','')[:104]}")
        print(f"        B: {perks[b].get('description','')[:104]}")
    if len(near) > 25:
        print(f"\n  ... and {len(near)-25} more")

    # ── shape of the trees ──────────────────────────────────────────────────
    rule("Shape — perks per skill and level")
    lv = defaultdict(Counter)
    for k, v in skill_perks.items():
        s = v.get("skill", "") or "(attr)"
        lv[s][int(v.get("required_level", 1))] += 1
    print(f"\n  {'skill':16s} " + " ".join(f"{i:>3d}" for i in range(1, 11)) + "   total")
    for s in sorted(lv):
        row = lv[s]
        cells = " ".join((f"{row[i]:>3d}" if row[i] else "  .") for i in range(1, 11))
        print(f"  {s:16s} {cells}   {sum(row.values()):5d}")
    holes = [(s, i) for s in lv if s != "(attr)" for i in range(1, 11) if not lv[s][i]]
    print(f"\n  empty skill/level cells: {len(holes)} of {len([s for s in lv if s!='(attr)'])*10}")

    # ── mantras ─────────────────────────────────────────────────────────────
    rule("Mantras")
    mantras = [k for k, v in perks.items() if v.get("is_mantra")]
    mantra_wired = [k for k in mantras if k in wired]
    mantra_refs = [w for w in ("mantra_count", "is_mantra", "MantraSystem", "YidamSystem")
                   if any(w in open(p, encoding="utf-8", errors="ignore").read()
                          for p in walk((".gd",)))]
    print(f"\n  {len(mantras)} perks carry is_mantra, {len(mantra_wired)} of them are wired")
    print(f"  mantra-related identifiers found in scripts: {mantra_refs or 'none'}")

    # ── balance: a promise that shrinks as the gate rises ───────────────────
    rule("Balance — the same stat promised no better at a much higher gate")
    per_skill = defaultdict(list)
    for k, v in skill_perks.items():
        sk = v.get("skill", "")
        pro = stat_promises(v.get("description", ""))
        if sk and pro:
            per_skill[sk].append((int(v.get("required_level", 1)), pro, k))
    flagged = 0
    for sk, rows in sorted(per_skill.items()):
        rows.sort(key=lambda r: r[0])
        for (l1, p1, k1), (l2, p2, k2) in combinations(rows, 2):
            if l2 < l1 + 3:
                continue
            for stat in set(p1) & set(p2):
                if p2[stat] <= p1[stat]:
                    flagged += 1
                    same = "identical" if p2[stat] == p1[stat] else "smaller"
                    print(f"\n  {sk} / {stat}: `{k2}` at level {l2} promises {p2[stat]:g}% — "
                          f"{same} to `{k1}` at level {l1} ({p1[stat]:g}%)")
                    print(f"        L{l1}: {perks[k1].get('description','')[:96]}")
                    print(f"        L{l2}: {perks[k2].get('description','')[:96]}")
                    break
    if not flagged:
        print("\n  none")
    print(f"\n  {flagged} flagged. Party-wide effects legitimately carry smaller numbers than "
          f"personal ones,\n  so read each as a question rather than a verdict.")

    # ── the base_bonuses curves behind every skill ──────────────────────────
    # These are the flat per-level payouts every skill gives just for being
    # trained, and they are keyed by name. character_system translates a fixed
    # list of those names into derived stats; anything else is inert.
    rule("Base skill bonuses — which stat names reach a derived stat")
    CONSUMED = {"attack", "damage", "strength_weapon_damage", "crit_chance", "armor",
                "armor_penetration", "max_hp", "damage_reduction_pct", "spellpower",
                "mana_cost", "dodge", "stamina", "initiative"}
    base = records(load("resources/data/perks.json")["base_bonuses"])
    names = defaultdict(list)
    for sk, v in base.items():
        for st in v.get("stats", []):
            names[st].append(sk)
    live = sorted(n for n in names if n in CONSUMED)
    dead = sorted(n for n in names if n not in CONSUMED)
    print(f"\n  {len(names)} distinct stat names across {len(base)} skills")
    print(f"    reaching a derived stat  {len(live):3d}   {', '.join(live)}")
    print(f"    reaching nothing         {len(dead):3d}")
    print("\n  the inert ones, and the skills paying into them:")
    for n in dead:
        print(f"    {n:36s} {', '.join(names[n])}")
    print("\n  Note: these are percentages (grace pays movement_speed 65.0 at level 10),")
    print("  so they cannot be renamed onto the flat keys the pipeline reads — +65 movement")
    print("  on a base of about 4. They need a percentage stage in update_derived_stats.")

    # ── what the unwired perks are waiting on ───────────────────────────────
    rule("What the unwired perks assume exists")
    SYSTEMS = {
        "combat statuses": r"\bstatus effect|\bstun|\bburn|\bpoison|\bbleed|\bslow\b",
        "summons": r"\bsummon",
        "dialogue / social": r"dialogu|conversat|persuad|negotiat|barter|haggl|reputation|rumou?r",
        "travel / camp": r"\bcamp\b|\btravel|\bmarch|rest\b|\bforage|\bsupplies|weight capacity",
        "shops / economy": r"\bprice|shop|merchant|sell|buy|discount|gold\b",
        "crafting": r"\bcraft|forge|smith|reforge|repair\b",
        "stealth / world": r"\bstealth|sneak|detect|ambush|hidden|surprise",
        "identify items": r"\bidentif|appraise|magical propert",
        "karma": r"\bkarma\b",
    }
    lean = defaultdict(list)
    for k in inert:
        text = perks[k].get("description", "").lower()
        for name, pat in SYSTEMS.items():
            if re.search(pat, text):
                lean[name].append(k)
    print(f"\n  {len(inert)} unwired perks. What their prose leans on:\n")
    for name in sorted(lean, key=lambda n: -len(lean[n])):
        print(f"    {name:20s} {len(lean[name]):3d}   {', '.join(sorted(lean[name])[:4])}")
    plain = [k for k in inert if not any(k in v for v in lean.values())]
    print(f"    {'(no system named)':20s} {len(plain):3d}")

    by_sk = Counter(perks[k].get("skill", "cross") or "(attr)" for k in inert)
    print(f"\n  where they cluster:")
    for sk, n in by_sk.most_common(12):
        print(f"    {sk:20s} {n}")

    # ── prose that promises a stat the game does not have ───────────────────
    rule("Descriptions with no stated effect")
    vague = [k for k, v in perks.items()
             if len(v.get("description", "")) < 40 or not re.search(r"\d", v.get("description", ""))]
    print(f"\n  {len(vague)} perks state no number at all "
          f"({len([k for k in vague if k in wired])} of them are wired, so the number lives in code)")
    unwired_vague = [k for k in vague if k not in wired]
    print(f"  {len(unwired_vague)} state no number AND have no code — nothing defines what they do")
    for k in sorted(unwired_vague)[:15]:
        print(f"      {perks[k].get('name',k):26s} `{k}`  {perks[k].get('description','')[:70]}")
    if len(unwired_vague) > 15:
        print(f"      ... and {len(unwired_vague)-15} more")


if __name__ == "__main__":
    main()
