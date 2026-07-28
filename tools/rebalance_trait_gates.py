#!/usr/bin/env python3
"""Rebalance the trait-gated choices added by the four-part sweep.

The sweep was written for flavour and not costed, and the measurement says so:

  - trait gates paid a median 25 XP against 12 for every other choice in the
    game, while costing nothing to unlock. A skill gate represents XP the
    player spent; a trait gate represents a die roll at character creation.
  - 124 of 201 gates outpaid every other choice in their own event, so the
    trait choice was simply the correct one whenever it appeared.
  - 167 of 201 sat on inborn traits, the commonly held ones. `curious` alone
    had five gates at 30-35 XP and sits in ~39% of parties.
  - only 39 of 201 carried any cost or risk at all.

Principle applied here: the reward for a trait gate is the *route* — the fight
avoided, the crossing made safely, the thing learned — which is already in the
outcome. The XP is a garnish and should scale inversely with how often the
trait is held, never exceeding what the event pays for a skill.

Rules:
  1. XP band by the probability a 3-person party holds the trait:
        P >= 30%  ->  8      (curious, stubborn, patient, brave …)
        P >= 15%  -> 12
        P >=  5%  -> 15
        P <   5%  -> 20      (rare and acquired traits)
  2. A gate carrying a real cost or risk keeps a 50% premium — risk should pay.
  3. Never exceed the best non-trait choice in the same event, unless the gate
     carries a risk. Dominance is the actual problem, not the absolute number.
  4. Gold capped at "small" on a pure-upside gate.
  5. Item grants only survive on low-frequency traits.
"""
import glob
import json
from collections import Counter

ROOT = "/home/user/six_worlds/resources/data/events/"
TRAITS = "/home/user/six_worlds/resources/data/traits.json"
COMPANIONS = "/home/user/six_worlds/resources/data/companions.json"

GOLD_VALUE = {"small": 40, "moderate": 100, "large": 180}

tr = json.load(open(TRAITS, encoding="utf-8"))
comps = json.load(open(COMPANIONS, encoding="utf-8"))["companions"]
comps = list(comps.values()) if isinstance(comps, dict) else comps
N_COMP = len(comps)
comp_freq = Counter(t for c in comps if isinstance(c, dict) for t in c.get("traits", []))

inborn_phys = [k for k, v in tr.items()
               if isinstance(v, dict) and v.get("inborn") and v.get("category") == "physical"]
inborn_pers = [k for k, v in tr.items()
               if isinstance(v, dict) and v.get("inborn") and v.get("category") == "personality"]
inborn_beh = [k for k, v in tr.items()
              if isinstance(v, dict) and v.get("inborn") and v.get("category") == "behavioral"]


def presence(trait_id):
    """Chance a player + two companions hold this trait at all."""
    p_player = 0.0
    if trait_id in inborn_phys:
        p_player = 1.0 / len(inborn_phys)
    elif trait_id in inborn_pers:
        p_player = 1.0 / len(inborn_pers)
    elif trait_id in inborn_beh:
        p_player = 1.0 / len(inborn_beh)
    f = comp_freq.get(trait_id, 0) / N_COMP
    return 1 - (1 - p_player) * (1 - f) ** 2


def band_xp(p):
    if p >= 0.30:
        return 8
    if p >= 0.15:
        return 12
    if p >= 0.05:
        return 15
    return 20


def branch(choice):
    for k in ("outcome", "outcome_success"):
        if k in choice:
            return choice[k]
    return None


def has_risk(rewards):
    if "hp_loss" in rewards:
        return True
    g = rewards.get("gold", 0)
    if isinstance(g, (int, float)) and g < 0:
        return True
    for p in rewards.get("pressure", []):
        if isinstance(p, dict) and p.get("amount", 0) < 0:
            return True
    for v in rewards.get("supplies", {}).values():
        if isinstance(v, (int, float)) and v < 0:
            return True
    return False


def value_of(choice):
    o = branch(choice)
    r = o.get("rewards", {}) if isinstance(o, dict) else {}
    g = r.get("gold", 0)
    g = GOLD_VALUE.get(g, g if isinstance(g, int) else 0)
    return int(r.get("xp", 0) or 0) + max(0, g) // 4 + 8 * len(r.get("items", []))


def main():
    changed = 0
    xp_before, xp_after = [], []
    report = []

    for path in glob.glob(ROOT + "*.json"):
        d = json.load(open(path, encoding="utf-8"))
        events = d.get("events", d)
        dirty = False
        for eid, e in events.items():
            if not isinstance(e, dict):
                continue
            choices = [c for c in e.get("choices", []) if isinstance(c, dict)]
            gates = [c for c in choices
                     if "trait" in c.get("requirements", {})
                     or "not_trait" in c.get("requirements", {})]
            if not gates:
                continue
            others = [c for c in choices if c not in gates]
            best_other = max((value_of(c) for c in others), default=0)

            for g in gates:
                o = branch(g)
                if not isinstance(o, dict):
                    continue
                r = o.setdefault("rewards", {})
                trait_id = g["requirements"].get("trait") or g["requirements"].get("not_trait")
                p = presence(trait_id)
                risky = has_risk(r)

                old_xp = int(r.get("xp", 0) or 0)
                new_xp = band_xp(p)
                if risky:
                    new_xp = int(round(new_xp * 1.5))
                elif p >= 0.15 and best_other > 0:
                    # A commonly held trait must not make its event's best choice
                    # automatic. A rare one being the best answer in the one
                    # situation that suits it is the whole point, so it is exempt.
                    new_xp = min(new_xp, best_other)
                if old_xp:
                    xp_before.append(old_xp)

                if new_xp > 0:
                    r["xp"] = new_xp
                elif "xp" in r:
                    del r["xp"]
                if new_xp:
                    xp_after.append(new_xp)

                # gold: pure upside is capped at the smallest band
                gold = r.get("gold")
                if isinstance(gold, str) and not risky and gold in ("moderate", "large"):
                    r["gold"] = "small"
                    dirty = True

                # free items only where the trait is genuinely uncommon
                if "items" in r and p >= 0.15 and not risky:
                    del r["items"]
                    dirty = True

                if old_xp != new_xp:
                    changed += 1
                    dirty = True
                    report.append((round(p * 100), trait_id, eid, g.get("id"), old_xp, new_xp))

        if dirty:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(d, f, indent=2, ensure_ascii=False)
                f.write("\n")

    report.sort(key=lambda x: -(x[4] - x[5]))
    print(f"gates rescaled: {changed}")
    print(f"XP median before {sorted(xp_before)[len(xp_before)//2]} "
          f"-> after {sorted(xp_after)[len(xp_after)//2]}")
    print("\nlargest reductions:")
    for pc, t, eid, cid, a, b in report[:15]:
        print(f"  P={pc:3}%  {t:16} {eid}:{cid}  {a} -> {b}")


if __name__ == "__main__":
    main()
