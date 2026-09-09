#!/usr/bin/env python3
"""Generate docs/review/PERK_FIXES.md — the perk wiring worklist, grouped by the
system that owns the hook each perk needs.

The grouping is the point. An earlier version grouped by condition and put half
the perks in an "unclassified" pile, because the condition is only the right
axis for perks that modify combat stats. What actually determines whether a
perk can be wired is which system has to grow a hook for it — and a batch is
finishable exactly when it is one hook.

Rerun after any migration: a perk leaves this document once it carries an
`effects` block (passive) or a `combat_data` block (active), so the counts are
the progress bar.

    python3 tools/export_perk_fix_list.py
"""
import json
import os
import re
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PERKS = os.path.join(ROOT, "resources", "data", "perks.json")
REGISTRY = os.path.join(ROOT, "resources", "data", "perk_effects.json")
SCRIPTS = os.path.join(ROOT, "scripts")
OUT = os.path.join(ROOT, "docs", "review", "PERK_FIXES.md")

# Which system owns the hook this perk needs. First match wins, so the order is
# the classification: an Active is an Active whatever else its text mentions,
# and a perk about summons belongs to the summon system even though it also
# names a stat.
SYSTEMS = [
    ("actives", r"^Active\b",
     "The player presses a button. These need a `combat_data` block, not an "
     "`effects` one — see the note at the top of this document."),
    ("multi_arm", r"\b(arm chain|multi-arm|multi_arm|off-hand chance|secondary arm|arms in the)",
     "Body-plan specific, handled by BodySystem. Small and self-contained."),
    ("summons", r"\bsummon",
     "Modify creatures this character summons. The hook goes where a summon is "
     "created, not where stats are computed."),
    ("crafting", r"\b(craft|forge|smith|brew|repair|salvage|socket|coating|grenade|alchem)",
     "Applied when an item is made. Owned by the crafting side of ItemSystem."),
    ("economy", r"\b(gold|price|merchant|shop|invest|sell|buy|discount|income|coin|mercenar)",
     "Prices, income and recruitment. Owned by ShopSystem and CompanionSystem."),
    ("camp_travel", r"\b(rest|camp|travel|overworld|supplies|food|forag|ambush|per (?:in-game )?day|settlement|stash)",
     "Between-combat time. Owned by CampSystem and the overworld."),
    ("dialogue_events", r"\b(dialogue|social check|persuasion check|conversation|event|lore|knowledge|scout)",
     "Skill checks and choices in events. Owned by EventManager."),
    ("buff_status", r"\b(buff|debuff|status effect|mantra|aura|duration|dispel|cleanse)",
     "Perks that modify *other effects* rather than stats — how long a buff "
     "lasts, how far an aura reaches. The hook goes in status application."),
    ("spellcasting", r"\b(spell|mana|cast|spellpower|school)",
     "Range, area, targeting and cost of spells. Overlaps the spell effect "
     "registry — do this together with the spell backlog, not separately."),
    ("combat_reactions", r"\b(zone[- ]of[- ]control|threatened area|reaction attack|opportunity attack|"
                         r"block chance|parry|reflect|retaliat|counter[- ]?attack|enemies (?:entering|moving past)|"
                         r"provoke)",
     "Reactions and the space around a unit — zone of control, opportunity "
     "attacks, blocking, retaliation. The hook is in movement and the attack "
     "resolution order, not in stats."),
    ("action_economy", r"\b(free (?:action|attack|move)|extra (?:action|attack|turn)|additional attack|"
                       r"costs? \d+ less stamina|cost \d+% less stamina|\+\d+ actions?|does not (?:cost|use) an action)",
     "How many things a unit may do in a turn, and what an action costs. The "
     "hook is the turn/action accounting."),
    ("stealth_thievery", r"\b(stealth|pickpocket|steal|lockpick|trap|sneak|hidden|unnoticed)",
     "Stealth, locks, traps and theft. Owned by the thievery side of the event "
     "and combat code."),
    ("equipment_rules", r"\b(dual[- ]wield|weapon switch|switching between|may equip|can wield|"
                        r"weight limit|carry capacity|encumbr)",
     "What a character may hold and carry. Owned by ItemSystem's equip rules."),
    ("combat_effects", r"\b(apply|applies|inflict|suffer|save (?:or|negates)|saving throw|"
                       r"knockback|knock back|stun for|slow(?:ed)? for|feared? for|becomes? \w+ for \d+ turns?|"
                       r"chance to)\b",
     "Applying statuses and forcing saves as a rider on ordinary attacks. The "
     "hook is one place in the damage pipeline, after a hit is confirmed."),
    ("loot", r"\b(drop|loot|treasure|rare item|salvage from)",
     "What enemies and containers yield. Owned by the loot roll."),
    ("combat_stats", r"[+-]\d+%?\s*(?:to\s+)?(?:dodge|movement|initiative|accuracy|attack|armor|damage|crit|hp|health|stamina|weight)"
                     r"|\b(?:dodge|accuracy|armor|initiative|crit chance|movement)\b",
     "Passive and conditional modifiers to the character's own stats. This is "
     "the batch the condition evaluator serves."),
]

# Secondary axis, only meaningful inside combat_stats and buff_status.
CONDITION_PATTERNS = [
    ("on_kill",            r"\b(killing|when you kill|on kill|kills? an enem)"),
    ("on_crit",            r"\b(critical hit|on a crit|crits?)\b"),
    ("on_dodge",           r"\b(when you (?:successfully )?(?:dodge|parry|evade)|after (?:dodging|parrying))"),
    ("on_damage_taken",    r"\b(when (?:you are|hit by|struck)|attackers?|melee attack received|damage taken)"),
    ("on_ally_death",      r"\b(when an ally dies|ally is (?:killed|slain))"),
    ("on_cast",            r"\b(when(?:ever)? you cast|on cast|after casting)"),
    ("first_hit_on_target", r"\b(first (?:attack|hit|strike)|already hit once)"),
    ("target_below_hp_pct", r"\b(below \d+% (?:hp|health)|under \d+% (?:hp|health))"),
    ("self_below_hp_pct",  r"\b(while (?:you are )?below \d+%|at low (?:hp|health))"),
    ("target_has_status",  r"\b(stunned|dazed|burning|frozen|poisoned|bleeding|debuffed|affected by|with any status)"),
    ("wielding",           r"\b(while wielding|wielding a|sword attacks?|axe attacks?|dagger attacks?|"
                           r"spear attacks?|mace attacks?|unarmed attacks?|with a shield|ranged attacks?)"),
    ("armor_class",        r"\b(unarmored|light armor|heavy armor|no armor|while armored)"),
    ("adjacent_allies",    r"\b(adjacent to an ally|allies within|nearby all(?:y|ies))"),
    ("adjacent_enemies",   r"\b(adjacent to (?:exactly )?\w+ enem|enemies within|surrounded)"),
    ("turn_number",        r"\b(first turn|turn 1|opening turn)"),
]

CLAUSE = re.compile(
    r"\b(while|when|against|vs|if|per|each|after|once|first|adjacent|wielding|"
    r"unarmored|versus|during|chance|instead|may|can|stack|consecutive|"
    r"enem\w*|all(?:y|ies)|attack\w*|hit|kill\w*|turn\w*|combat|target\w*)\b", re.I)


def classify_system(desc):
    for name, pattern, _ in SYSTEMS:
        if re.search(pattern, desc, re.I):
            return name
    return "unsorted"


def classify_condition(desc):
    for name, pattern in CONDITION_PATTERNS:
        if re.search(pattern, desc, re.I):
            return name
    body = re.sub(r"^Passive\.\s*", "", desc).strip()
    return "always" if not CLAUSE.search(body) else "unclassified"


def main():
    data = json.load(open(PERKS, encoding="utf-8"))
    registry = json.load(open(REGISTRY, encoding="utf-8"))
    conditions_reg = registry["conditions"]

    perks = {}
    for group in ("skill_perks", "cross_perks"):
        for pid, perk in data[group].items():
            perks[pid] = perk

    hand_wired = set()
    for root, _, files in os.walk(SCRIPTS):
        for fn in files:
            if not fn.endswith(".gd"):
                continue
            src = open(os.path.join(root, fn), encoding="utf-8").read()
            hand_wired |= set(re.findall(
                r'(?:has_perk|_unit_has_perk|party_has_perk)\([^,)]*,?\s*"([a-z_0-9]+)"', src))

    def is_done(pid, perk):
        if perk["description"].startswith("Active"):
            return bool(perk.get("combat_data"))
        return bool(perk.get("effects"))

    done = {p for p, v in perks.items() if is_done(p, v)}
    todo = {p: v for p, v in perks.items() if p not in done}

    by_system = collections.defaultdict(list)
    for pid, perk in sorted(todo.items()):
        by_system[classify_system(perk["description"])].append((pid, perk))

    blurbs = {name: blurb for name, _, blurb in SYSTEMS}
    blurbs["unsorted"] = ("No pattern matched. These need reading one by one — the "
                          "classifier is deliberately not guessing.")

    L = []
    w = L.append
    w("<!-- Generated by tools/export_perk_fix_list.py — rerun it, do not hand-edit. -->")
    w("")
    w("# Perks still to wire")
    w("")
    w("**Implementation instructions live in `docs/plans/PERK_WIRING_PLAN.md`.**")
    w("This document is only the inventory: which perks, in which batch, saying what.")
    w("")
    w(f"{len(done)} of {len(perks)} perks are wired in data. {len(hand_wired)} more work through")
    w("a hand-written `has_perk` check somewhere in the combat code — those function, but")
    w("each is a bespoke `if` rather than data, which is why the rest were never done.")
    w("")
    w("A perk leaves this document when it carries an `effects` block (passive) or a")
    w("`combat_data` block (active), so the counts are the progress bar.")
    w("")
    w("## Two different fields, deliberately")
    w("")
    w("**Active perks** — description begins with `Active` — take a **`combat_data`**")
    w("block. `scripts/combat/combat_arena.gd` already implements the whole pipeline for")
    w("them: the button, stamina, cooldowns, weapon requirements, targeting, eight effect")
    w("types and AI usage scoring. Not one perk carries `combat_data`, so all of it is")
    w("unused. These are data work against working code, which makes them the cheapest")
    w("batch, not the hardest.")
    w("")
    w("**Everything else** takes an **`effects`** block typed against")
    w("`resources/data/perk_effects.json`. Do not merge the two — `combat_data` works")
    w("today and folding it into the registry would break it for tidiness.")
    w("")
    w("## Batches")
    w("")
    w("| System | Perks | Hand-wired | What has to grow a hook |")
    w("|---|---:|---:|---|")
    order = [n for n, _, _ in SYSTEMS] + ["unsorted"]
    for name in order:
        rows = by_system.get(name, [])
        if not rows:
            continue
        hw = sum(1 for pid, _ in rows if pid in hand_wired)
        first_line = blurbs[name].split(".")[0] + "."
        w(f"| `{name}` | {len(rows)} | {hw} | {first_line} |")
    w(f"| **total** | **{len(todo)}** | **{sum(1 for p in todo if p in hand_wired)}** | |")
    w("")

    for name in order:
        rows = by_system.get(name, [])
        if not rows:
            continue
        w("")
        w(f"## `{name}` — {len(rows)} perks")
        w("")
        w(blurbs[name])
        w("")
        if name in ("combat_stats", "buff_status"):
            counts = collections.Counter(classify_condition(p["description"]) for _, p in rows)
            w("Conditions wanted, which is the order to implement them in:")
            w("")
            w("| Condition | Perks | Implemented |")
            w("|---|---:|---|")
            for cond, n in counts.most_common():
                if cond == "unclassified":
                    state = "n/a"
                else:
                    state = "yes" if conditions_reg.get(cond, {}).get("implemented") else "no"
                w(f"| `{cond}` | {n} | {state} |")
            w("")
        for pid, perk in rows:
            skill = perk.get("skill", perk.get("category", "cross"))
            lvl = perk.get("required_level", "")
            mark = " · hand-wired" if pid in hand_wired else ""
            extra = ""
            if name in ("combat_stats", "buff_status"):
                extra = f" · `{classify_condition(perk['description'])}`"
            w(f"- **`{pid}`** ({skill} {lvl}{mark}{extra})  ")
            w(f"  {perk['description']}")
        w("")

    w("")
    w("---")
    w("")
    w("Classification is a regex reading of the prose, not something the data asserts.")
    w("It is right often enough to size and group the work; it will be wrong on")
    w("individual perks, which is why every description is printed above.")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write("\n".join(L) + "\n")
    print(f"wrote {OUT}")
    for name in order:
        if by_system.get(name):
            print(f"  {name:18} {len(by_system[name]):4}")
    print(f"  {'wired already':18} {len(done):4}")


if __name__ == "__main__":
    main()
