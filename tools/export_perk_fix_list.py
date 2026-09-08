#!/usr/bin/env python3
"""Generate docs/review/PERK_FIXES.md — the per-perk worklist for typing perk
mechanics against resources/data/perk_effects.json.

Rerun after any migration: a perk leaves the document once it carries an
`effects` block, so the counts are the progress bar.

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

# Which registry condition a description is asking for. First match wins, so the
# more specific patterns come first. These are a reading of the prose, not
# something the data asserts — the point is to group the work, not to be right
# about every perk.
CONDITION_PATTERNS = [
    ("on_kill",            r"\b(killing|when you kill|on kill|kills? an enem|reduces? an enemy to 0)"),
    ("on_crit",            r"\b(critical hit|on a crit|crits?)\b"),
    ("on_dodge",           r"\b(when you (?:successfully )?(?:dodge|parry|evade)|after (?:dodging|parrying))"),
    ("on_damage_taken",    r"\b(when (?:you are|hit by|struck)|attackers?|melee attack received|damage taken)"),
    ("on_ally_death",      r"\b(when an ally dies|ally is (?:killed|slain))"),
    ("on_cast",            r"\b(when(?:ever)? you cast|on cast|after casting)"),
    ("first_hit_on_target", r"\b(first (?:attack|hit|strike)|have not yet|already hit once)"),
    ("target_below_hp_pct", r"\b(below \d+% (?:hp|health)|under \d+% (?:hp|health)|wounded target)"),
    ("self_below_hp_pct",  r"\b(while (?:you are )?below \d+%|at low (?:hp|health))"),
    ("target_has_status",  r"\b(stunned|dazed|burning|frozen|poisoned|bleeding|debuff(?:ed)?|affected by|with any status)"),
    ("wielding",           r"\b(while wielding|wielding a|sword attacks?|axe attacks?|dagger attacks?|spear attacks?|mace attacks?|unarmed attacks?|with a shield|ranged attacks?)"),
    ("armor_class",        r"\b(unarmored|light armor|heavy armor|no armor|while armored)"),
    ("adjacent_allies",    r"\b(adjacent to an ally|allies within|nearby all(?:y|ies))"),
    ("adjacent_enemies",   r"\b(adjacent to (?:exactly )?\w+ enem|enemies within|surrounded)"),
    ("spell_school",       r"\b(space|air|fire|water|earth|sorcery|enchantment|summoning|white|black)[- ]tagged|\b(sorcery|enchantment|summoning) spells?\b"),
    ("turn_number",        r"\b(first turn|turn 1|opening turn)"),
    ("crafting",           r"\b(craft(?:ed|ing)?|forge|brew|repair)"),
    ("shopping",           r"\b(merchant|shop|buying|selling|price|discount|market)"),
    ("dialogue",           r"\b(dialogue|social check|persuasion check|conversation)"),
    ("out_of_combat",      r"\b(out of combat|between battles|while resting|on the map|travel)"),
]

# Effect type a description is asking for, same caveat.
EFFECT_PATTERNS = [
    ("summon_bonus",   r"\b(summons? (?:gain|have)|your summons)"),
    ("aura",           r"\b(aura|allies within \d|radiat|all allies in)"),
    ("extra_action",   r"\b(extra (?:action|attack|move)|additional attack|free action|act again)"),
    ("refund",         r"\b(refunds?|returns? \d+% of the mana|regain(?:s)? \d+ (?:mana|stamina))"),
    ("cost_modifier",  r"\b(costs? \d+ less|costs? double|-\d+% mana cost|cheaper|reduced (?:mana|stamina) cost)"),
    ("apply_status",   r"\b(appl(?:y|ies)|inflicts?|causes? .* for \d+ turns?|becomes? (?:stunned|burning|frozen))"),
    ("remove_status",  r"\b(removes?|cleanses?|dispels?|cures?)\b"),
    ("bonus_damage_vs", r"\b(\+\d+% damage (?:to|against|vs)|deal .* more damage (?:to|against))"),
    ("spell_modifier", r"\b(spells? gain|\+\d+ tile of range|aoe|range of your spells|duration of your)"),
    ("reroll",         r"\b(reroll|re-roll)"),
    ("immunity",       r"\b(immune to|immunity|cannot be)"),
    ("resistance",     r"\b(resistance to|resist \d+%)"),
    ("unlock",         r"\b(can (?:craft|open|access|identify|see)|gain access|unlocks?|always available)"),
    ("stat",           r"[+-]\d+%?\s*(?:to\s+)?(?:dodge|movement|initiative|spellpower|accuracy|attack|armor|damage|crit|hp|health|stamina|mana|weight)"),
]


# A description with none of the clause words below really is a standing bonus.
# Anything else that matches no condition pattern is unclassified, not
# unconditional — defaulting those to `always` would claim hundreds of
# unconditional perks when there are about nineteen.
CLAUSE = re.compile(
    r"\b(while|when|against|vs|if|per|each|after|once|first|adjacent|wielding|"
    r"unarmored|versus|during|chance|instead|may|can|active|stack|consecutive|"
    r"enem\w*|all(?:y|ies)|summon\w*|spell\w*|attack\w*|hit|kill\w*|turn\w*|"
    r"combat|target\w*|craft\w*|shop\w*|merchant|dialogue)\b", re.I)


def classify(desc, patterns, default):
    low = desc.lower()
    for name, pattern in patterns:
        if re.search(pattern, low):
            return name
    return default


def classify_condition(desc):
    for name, pattern in CONDITION_PATTERNS:
        if re.search(pattern, desc.lower()):
            return name
    body = re.sub(r"^Passive\.\s*", "", desc).strip()
    return "always" if not CLAUSE.search(body) else "unclassified"


def main():
    data = json.load(open(PERKS, encoding="utf-8"))
    registry = json.load(open(REGISTRY, encoding="utf-8"))
    effects_reg = registry["effects"]
    conditions_reg = registry["conditions"]

    perks = {}
    for group in ("skill_perks", "cross_perks"):
        for pid, perk in data[group].items():
            perks[pid] = dict(perk, _group=group)

    hand_wired = set()
    for root, _, files in os.walk(SCRIPTS):
        for fn in files:
            if not fn.endswith(".gd"):
                continue
            src = open(os.path.join(root, fn), encoding="utf-8").read()
            hand_wired |= set(re.findall(
                r'(?:has_perk|_unit_has_perk|party_has_perk)\([^,)]*,?\s*"([a-z_0-9]+)"', src))

    typed = {p: v for p, v in perks.items() if v.get("effects")}
    untyped = {p: v for p, v in perks.items() if not v.get("effects")}

    # Group the untyped ones by the condition their prose is asking for.
    by_condition = collections.defaultdict(list)
    for pid, perk in sorted(untyped.items()):
        cond = classify_condition(perk["description"])
        eff = classify(perk["description"], EFFECT_PATTERNS, "note")
        by_condition[cond].append((pid, perk, eff))

    L = []
    w = L.append
    w("<!-- Generated by tools/export_perk_fix_list.py — rerun it, do not hand-edit. -->")
    w("")
    w("# Perks still to wire")
    w("")
    w("A perk is wired when it carries an `effects` block typed against")
    w("`resources/data/perk_effects.json`. A perk leaves this document when it does,")
    w("so the counts are the progress bar.")
    w("")
    w(f"**{len(typed)} of {len(perks)} perks are typed.** {len(hand_wired)} more have a")
    w("hand-written `has_perk` check somewhere in the combat code — those work, but each")
    w("one is a bespoke `if` statement rather than data, which is why the other four")
    w("hundred were never done.")
    w("")
    w("## The thing to understand first")
    w("")
    w("Perks cannot be migrated from their descriptions automatically, and the reason is")
    w("worth stating plainly: **almost none of them are unconditional.** Of 603 perks,")
    w("about 19 are a plain standing bonus. Everything else fires while wielding")
    w("something, against a certain kind of target, on a trigger, or on a particular")
    w("school of spell. The condition is not a detail attached to the effect — it *is*")
    w("most of the content.")
    w("")
    w("So the work is not 597 individual migrations. It is implementing conditions, in")
    w("order of how many perks each unlocks. Implement `wielding` and every perk in that")
    w("section below becomes a data edit rather than a code change.")
    w("")
    w("## Conditions by how many perks they unlock")
    w("")
    w("| Condition | Perks | Implemented |")
    w("|---|---:|---|")
    for cond, rows in sorted(by_condition.items(), key=lambda kv: -len(kv[1])):
        if cond == "unclassified":
            done = "n/a"
        else:
            done = "yes" if conditions_reg.get(cond, {}).get("implemented") else "no"
        w(f"| `{cond}` | {len(rows)} | {done} |")
    w("")
    w("Effect types wanted across the same perks:")
    w("")
    counts = collections.Counter(eff for rows in by_condition.values() for _, _, eff in rows)
    w("| Effect type | Perks | Implemented |")
    w("|---|---:|---|")
    for eff, n in counts.most_common():
        done = "yes" if effects_reg.get(eff, {}).get("implemented") else "no"
        w(f"| `{eff}` | {n} | {done} |")
    w("")
    w("Both classifications are a reading of the prose by regex, not something the data")
    w("asserts. They are right often enough to size the job and group it; they will be")
    w("wrong on individual perks, and the per-perk entries below print the description")
    w("so the call can be made from the text.")
    w("")

    for cond, rows in sorted(by_condition.items(), key=lambda kv: -len(kv[1])):
        cdef = conditions_reg.get(cond, {}) if cond != "unclassified" else {
            "description": "No condition pattern matched, but the description does "
                           "carry a clause. These need reading one by one — the "
                           "classifier is deliberately not guessing."}
        w("")
        w(f"## `{cond}` — {len(rows)} perks")
        w("")
        w(f"{cdef.get('description', '')}"
          f"{' Implemented.' if cdef.get('implemented') else ' **Not implemented yet.**'}")
        w("")
        for pid, perk, eff in rows:
            skill = perk.get("skill", perk.get("category", "cross"))
            lvl = perk.get("required_level", "")
            mark = " · hand-wired" if pid in hand_wired else ""
            w(f"- **`{pid}`** ({skill} {lvl}{mark}) → `{eff}`  ")
            w(f"  {perk['description']}")
        w("")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write("\n".join(L) + "\n")
    print(f"wrote {OUT}")
    print(f"  typed        {len(typed):4}")
    print(f"  hand-wired   {len(hand_wired):4}")
    print(f"  still prose  {len(untyped):4}")


if __name__ == "__main__":
    main()
