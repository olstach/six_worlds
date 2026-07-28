#!/usr/bin/env python3
"""Behavioural and acquired traits, plus the bonding vocabulary.

Design rules from Olaf:
  - Mostly situational: the constant effect stays neutral unless the trait is
    obviously a plain good or a plain bad thing. Most entries here therefore
    carry no stat_modifiers at all and do their work through event_tags.
  - Behavioural traits are things two characters can bond over, that colour an
    event, or that can generate a rare event by themselves.
  - Acquired traits are the record of what a run did to a character, and can
    be lost again.

bond_tags is the vocabulary the relationship system scores on. Shared tags pull
a pair together, shared vices pull harder, and opposed_traits push apart.
"""
import json

P = "/home/user/six_worlds/resources/data/traits.json"

# ── behavioural: bondable, event-generating, situational ─────────────────────
BEHAVIOURAL = {
    "tea_ritualist": ("Tea Ritualist",
        "Takes tea seriously — the making of it at least as much as the drinking.",
        {}, {}, ["sociable", "order"], []),
    "poet": ("Poet",
        "Composes constantly in their head, and occasionally, without warning, out loud.",
        {}, {}, ["arts", "wonder"], []),
    "duelist": ("Duelist",
        "Cannot let a challenge stand. Has never once been able to.",
        {}, {}, ["martial"], ["patient"]),
    "braggart": ("Braggart",
        "Improves the story a little every time it is told.",
        {}, {}, ["sociable", "martial"], ["content"]),
    "pilgrim": ("Pilgrim",
        "Cannot pass a shrine without stopping, whatever the party's schedule says.",
        {}, {}, ["devotion", "wonder"], []),
    "debtor": ("Debtor",
        "Owes money somewhere, to someone with an unusually long memory.",
        {}, {}, ["vice"], []),
    "flirt": ("Flirt",
        "Incurably charming, and worst of all at the least convenient moments.",
        {}, {}, ["sociable"], ["ascetic"]),
    "homesick": ("Homesick",
        "Keeps quietly comparing everywhere they are to somewhere they are not.",
        {}, {}, ["solitary", "grief"], []),
    "early_riser": ("Early Riser",
        "Awake and useful before anyone else has decided to be a person yet.",
        {}, {}, ["order"], ["night_owl"]),
    "ascetic": ("Ascetic",
        "Eats little, sleeps hard, and wants less than the people around them.",
        {}, {}, ["devotion", "order"], ["gourmand", "night_drinker", "flirt"]),
    "mourner": ("Mourner",
        "Keeps the dead's days. Leaves food out on the right nights, wherever they are.",
        {}, {}, ["grief", "devotion"], []),
    "gossip": ("Gossip",
        "Knows everyone's business within a day of arriving anywhere.",
        {}, {}, ["sociable"], ["secret_bearer"]),
    "scrimper": ("Scrimper",
        "Cannot part with money without visibly flinching.",
        {}, {}, ["order"], ["generous"]),
    "beast_tender": ("Beast-tender",
        "Good with animals, and they appear to know it before being told.",
        {}, {}, ["beasts"], []),
    "sworn_vegetarian": ("Sworn Vegetarian",
        "Will not eat meat. Not when it is offered, not when it is the only thing there is.",
        {}, {}, ["devotion", "order"], []),
    "secret_bearer": ("Secret-bearer",
        "Carrying something they have told nobody, and have no plans to.",
        {}, {}, ["solitary"], ["gossip"]),
}

# ── acquired: granted by code hooks or by events, and losable ────────────────
# (id, name, description, stat_modifiers, skill_modifiers, bond_tags,
#  opposed, purgeable_by, purge_difficulty, pressure)
ACQUIRED = {
    # body and hardship — hooks in wound_system / body_system / combat_manager
    "scarred": ("Scarred",
        "The wound closed. The face it closed on is not quite the one they had before.",
        {}, {}, ["hardship"], [], [], 0, {}),
    "maimed": ("Maimed",
        "Something is gone that used to be there, and the body keeps reaching for it.",
        {}, {}, ["hardship"], [], [], 0, {"earth": -10}),
    "death_touched": ("Death-touched",
        "Was owed to something, and was not collected. It has changed how they walk into rooms.",
        {}, {}, ["hardship", "wonder"], [], [], 0, {"water": 5, "space": -5}),
    # practice — hooks in camp_system
    "steady_practice": ("Steady Practice",
        "Sits every night, whether or not the night deserves it.",
        {}, {"yoga": 1}, ["devotion", "order"], [], [], 0, {"space": 5}),
    "mantra_worn": ("Mantra-worn",
        "Has said it enough times that it says itself now, under everything else.",
        {}, {"yoga": 1, "ritual": 1}, ["devotion"], [], [], 0, {"space": 10}),
    "ash_marked": ("Ash-marked",
        "Has done the purification rites often enough to stop finding them strange.",
        {}, {"ritual": 1}, ["devotion"], [], [], 0, {"earth": 5}),
    # combat history — hooks in combat_manager
    "bloodied": ("Bloodied",
        "Has killed something that everyone agreed could not be killed.",
        {}, {}, ["martial"], [], [], 0, {"water": -5}),
    "sole_survivor": ("Sole Survivor",
        "Walked out of something that nobody else walked out of.",
        {}, {}, ["hardship", "solitary"], [], ["yoga", "ritual"], 5, {"water": -10, "space": -5}),
    "long_marched": ("Long-marched",
        "Has been on the road long enough that the road stopped being an event.",
        {}, {"logistics": 1}, ["order", "hardship"], [], [], 0, {}),
    # granted by events — the writing pass will place these
    "touched_by_grace": ("Touched by Grace",
        "Met something that had no business being kind to them, and was anyway.",
        {}, {}, ["wonder", "devotion"], [], [], 0, {"space": 10, "water": 10}),
    "harrowed": ("Harrowed",
        "Something happened. They have not described it, and are not going to.",
        {}, {}, ["hardship", "solitary"], [], ["yoga", "ritual"], 4, {"water": -10, "air": -10}),
    "beauty_struck": ("Beauty-struck",
        "Saw something that quietly reordered what they had thought the world contained.",
        {}, {}, ["wonder", "arts"], [], [], 0, {"space": 10, "fire": 5}),
}

# ── bonding vocabulary applied to the traits that already exist ──────────────
EXISTING_BONDS = {
    "gambler": (["vice"], []),
    "night_drinker": (["vice"], ["ascetic"]),
    "gourmand": (["vice", "sociable"], ["ascetic"]),
    "addiction": (["vice", "hardship"], []),
    "collector": (["order"], []),
    "devout": (["devotion"], ["lapsed"]),
    "lapsed": (["solitary"], ["devout"]),
    "renunciate": (["devotion"], []),
    "oath_keeper": (["devotion", "order"], ["oath_breaker"]),
    "oath_breaker": (["solitary"], ["oath_keeper"]),
    "storyteller": (["arts", "sociable"], []),
    "celebrant": (["arts", "sociable"], ["covetous"]),
    "curious": (["scholarly", "wonder"], ["incurious"]),
    "incurious": (["solitary"], ["curious"]),
    "sharp_memory": (["scholarly"], ["forgetful"]),
    "forgetful": ([], ["sharp_memory"]),
    "present": (["wonder", "scholarly"], []),
    "clear_eyed": (["scholarly"], ["superstitious"]),
    "superstitious": (["wonder"], ["clear_eyed"]),
    "dreamer": (["wonder", "arts"], []),
    "brave": (["martial"], ["timid"]),
    "timid": (["solitary"], ["brave"]),
    "war_hardened": (["martial", "hardship"], []),
    "blood_handed": (["martial", "hardship"], ["merciful"]),
    "merciful": (["devotion"], ["blood_handed"]),
    "grief_struck": (["grief"], []),
    "melancholic": (["grief", "solitary"], []),
    "haunted": (["grief", "hardship"], []),
    "chronic_pain": (["hardship"], []),
    "hot_tempered": ([], ["patient"]),
    "patient": (["order"], ["hot_tempered"]),
    "composed": (["order"], []),
    "content": (["order"], ["covetous", "braggart"]),
    "covetous": ([], ["content", "celebrant"]),
    "generous": (["sociable"], ["scrimper", "greedy"]),
    "greedy": (["vice"], ["generous"]),
    "trusting": (["sociable"], ["suspicious"]),
    "suspicious": (["solitary"], ["trusting"]),
    "paranoid": (["solitary"], ["trusting"]),
    "grudge_bearer": (["solitary"], []),
    "warm_hearted": (["sociable"], []),
    "attractive": (["sociable"], []),
    "vain": (["sociable"], ["content"]),
    "stubborn": (["order"], []),
    "fastidious": (["order"], []),
    "bird_lover": (["beasts"], []),
    "enlightened_insight": (["wonder", "devotion"], []),
    "night_owl": ([], ["early_riser"]),
    "light_sleeper": ([], []),
    "sharp_eyed": (["scholarly"], []),
    "strong": (["martial"], []),
    "quick": ([], []),
    "frail": (["hardship"], []),
    "clubfooted": (["hardship"], []),
    "hard_of_hearing": (["hardship"], []),
    "iron_stomach": (["sociable"], []),
}


def entry(name, desc, category, inborn, stats, skills, bonds, opposed,
          purgeable=None, difficulty=0, pressure=None):
    return {
        "name": name,
        "description": desc,
        "category": category,
        "inborn": inborn,
        "stat_modifiers": stats,
        "pressure_modifiers": pressure or {},
        "skill_modifiers": skills,
        "event_tags": [],          # filled in below with the trait id
        "bond_tags": bonds,
        "opposed_traits": opposed,
        "purgeable_by": purgeable or [],
        "purge_difficulty": difficulty,
    }


def main():
    d = json.load(open(P, encoding="utf-8"))
    added = []

    for tid, (name, desc, stats, skills, bonds, opposed) in BEHAVIOURAL.items():
        if tid in d:
            raise SystemExit(f"trait '{tid}' already exists")
        e = entry(name, desc, "behavioral", True, stats, skills, bonds, opposed)
        e["event_tags"] = [tid]
        d[tid] = e
        added.append(tid)

    for tid, (name, desc, stats, skills, bonds, opposed, purge, diff, pressure) in ACQUIRED.items():
        if tid in d:
            raise SystemExit(f"trait '{tid}' already exists")
        e = entry(name, desc, "acquired", False, stats, skills, bonds, opposed,
                  purge, diff, pressure)
        e["event_tags"] = [tid]
        d[tid] = e
        added.append(tid)

    # bonding vocabulary on everything that already existed
    tagged = 0
    for tid, (bonds, opposed) in EXISTING_BONDS.items():
        if tid not in d:
            raise SystemExit(f"unknown trait '{tid}' in EXISTING_BONDS")
        d[tid]["bond_tags"] = bonds
        d[tid]["opposed_traits"] = opposed
        tagged += 1

    # every remaining gameplay trait gets the keys too, so the schema is uniform
    filled = 0
    for tid, t in d.items():
        if not isinstance(t, dict) or tid.startswith("_"):
            continue
        if t.get("category") == "racial":
            continue
        if "bond_tags" not in t:
            t["bond_tags"] = []
            t["opposed_traits"] = []
            filled += 1

    with open(P, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write("\n")

    # opposition must be symmetric or rapport reads differently in each direction
    asym = []
    for tid, t in d.items():
        if not isinstance(t, dict) or tid.startswith("_"):
            continue
        for other in t.get("opposed_traits", []):
            if other not in d:
                asym.append(f"{tid} -> unknown '{other}'")
            elif tid not in d[other].get("opposed_traits", []):
                asym.append(f"{tid} opposes {other}, but not the reverse")

    print(f"added {len(added)} traits: {', '.join(added)}")
    print(f"bond-tagged {tagged} existing traits; {filled} more given empty keys")
    if asym:
        print("\nASYMMETRIC OPPOSITIONS (fix these):")
        for a in asym:
            print("  ", a)
    else:
        print("all oppositions symmetric")


if __name__ == "__main__":
    main()
