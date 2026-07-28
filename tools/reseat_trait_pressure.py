#!/usr/bin/env python3
"""Re-seat every trait and race pressure link on the psychology matrix.

Two corrections at once, which is why this is a hand-written table rather than
a sign flip:

1. SIGN. psychology_system.gd runs -100 (klesha) to +100 (wisdom), and
   apply_pressure(), the polarity check, the state labels and the crisis table
   all follow it. traits.json and races.json were authored the other way round
   ("positive = more of this affliction"), so the baseline that decay pulls
   toward pointed at the wrong pole. `grief_struck` carried water +20 while
   "Grief-struck" is itself the water dark major label.

2. ELEMENT. The label table is the canonical five-poison scheme:
       space = delusion   fire = desire   water = aversion
       earth = pride      air  = envy
   Several traits were filed against a colloquial reading instead — anger on
   fire rather than water, paranoia on space rather than air.

A blanket flip would have broken `oath_breaker` and `addiction`'s earth term,
which were already right. Each entry below is decided individually.
"""
import json

TRAITS = "/home/user/six_worlds/resources/data/traits.json"
RACES = "/home/user/six_worlds/resources/data/races.json"

# trait id -> (new pressure_modifiers, one-line rationale)
REASSIGN = {
    # ── space: delusion / clarity ────────────────────────────────────────────
    "dreamer":             ({"space": -5},              "lives partly elsewhere — mild dissociation; sign was already right"),
    "superstitious":       ({"space": -10},             "reads omens into everything — delusion proper"),
    "forgetful":           ({"space": -5},              "new link: the mind will not hold its place"),
    "lapsed":              ({"space": -10},             "new link: fell away from practice, lost the thread"),
    "enlightened_insight": ({"space": 15, "fire": 5},   "the one unambiguous wisdom trait; also cools craving"),
    "curious":             ({"space": 10},              "new link: keeps asking — the appetite insight runs on"),
    "devout":              ({"space": 10},              "new link: oriented toward something larger"),
    "sharp_memory":        ({"space": 5},               "new link: holds what it is given"),

    # ── fire: desire / warmth ────────────────────────────────────────────────
    "addiction":           ({"fire": -15, "earth": -5}, "craving is fire, not water; the shame of it is earth"),
    "greedy":              ({"fire": -10, "earth": -5}, "avarice is the desire family; miserliness touches pride"),
    "gambler":             ({"fire": -10},              "new link: the itch for the next throw"),
    "gourmand":            ({"fire": -5},               "new link: appetite, lightly"),
    "collector":           ({"fire": -5},               "new link: acquisition as grasping"),
    "night_drinker":       ({"fire": -10},              "new link: reaches for the cup"),
    "composed":            ({"fire": 5, "water": 5},    "hard-won calm answers both craving and anger"),
    "patient":             ({"water": 10, "fire": 5},   "kshanti answers aversion first, grasping second"),

    # ── water: aversion / clarity of mind ────────────────────────────────────
    "hot_tempered":        ({"water": -15},             "RE-TAGGED fire->water: anger is aversion, fire is craving"),
    "grief_struck":        ({"water": -20},             "the water dark major label is literally 'Grief-struck'"),
    "melancholic":         ({"water": -10},             "sadness beneath the surface"),
    "haunted":             ({"water": -15, "space": -5},"intrusive memory: aversion, with the mind slipping"),
    "blood_handed":        ({"water": -10, "earth": -5},"RE-TAGGED fire->water: killing hardens aversion; guilt is earth"),
    "war_hardened":        ({"water": -10, "air": 5},   "callousness is aversion normalised; danger no longer rattles"),
    "brave":               ({"water": 10},              "faces what would otherwise be pushed away"),

    # ── earth: pride / equanimity ────────────────────────────────────────────
    "vain":                ({"earth": -10},             "RE-TAGGED air->earth: pride in appearance is mana"),
    "oath_breaker":        ({"earth": -10},             "unchanged — was already on the klesha side"),
    "attractive":          ({"earth": -5},              "RE-TAGGED air->earth: mild self-regard, kept small"),
    "stubborn":            ({"earth": -10},             "new link: rigidity as pride"),
    "fastidious":          ({"earth": -5},              "new link: fussiness with a superior edge"),
    "generous":            ({"earth": 10},              "dana is the direct antidote to miserly pride"),

    # ── air: envy / accomplishment ───────────────────────────────────────────
    "paranoid":            ({"air": -15},               "RE-TAGGED space->air: 'Paranoid' is the air dark major label"),
    "timid":               ({"air": -15},               "RE-TAGGED water->air: fear sits under Anxious, not Irritable"),
    "light_sleeper":       ({"air": -5},                "RE-TAGGED water->air: never off watch"),
    "suspicious":          ({"air": -10},               "new link: assumes the worst of people"),
    "trusting":            ({"air": 10},                "new link: the antidote to envious comparison"),
    "storyteller":         ({"air": 5},                 "new link: gives other people's lives their due"),
    "sharp_eyed":          ({"air": 5},                 "new link: alertness without anxiety"),
}

# Deliberately left with no psychology link — physical facts, not dispositions:
# clubfooted, frail, hard_of_hearing, iron_stomach, night_owl, quick, strong,
# bird_lover.

NEW_TRAITS = {
    # ── earth wisdom (had exactly one entry: generous) ────────────────────────
    "content": {
        "name": "Content",
        "description": "Wants little. What arrives is generally enough.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"earth": 10, "fire": 5},
        "skill_modifiers": {}, "event_tags": ["content"],
        "purgeable_by": [], "purge_difficulty": 0,
    },
    "oath_keeper": {
        "name": "Oath-keeper",
        "description": "Has held to a vow through the circumstances that made holding it expensive.",
        "category": "acquired", "inborn": False,
        "stat_modifiers": {}, "pressure_modifiers": {"earth": 15},
        "skill_modifiers": {"yoga": 1}, "event_tags": ["oath_keeper"],
        "purgeable_by": [], "purge_difficulty": 0,
    },

    # ── fire wisdom ──────────────────────────────────────────────────────────
    "warm_hearted": {
        "name": "Warm-hearted",
        "description": "Easy to like, and easy about liking other people.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {"charm": 1}, "pressure_modifiers": {"fire": 10, "water": 5},
        "skill_modifiers": {}, "event_tags": ["warm_hearted"],
        "purgeable_by": [], "purge_difficulty": 0,
    },
    "renunciate": {
        "name": "Renunciate",
        "description": "Has put down something they wanted badly, on purpose, and did not pick it back up.",
        "category": "acquired", "inborn": False,
        "stat_modifiers": {}, "pressure_modifiers": {"fire": 15, "earth": 5},
        "skill_modifiers": {"yoga": 1}, "event_tags": ["renunciate"],
        "purgeable_by": [], "purge_difficulty": 0,
    },

    # ── water wisdom ─────────────────────────────────────────────────────────
    "merciful": {
        "name": "Merciful",
        "description": "Has spared someone who could not have stopped them.",
        "category": "acquired", "inborn": False,
        "stat_modifiers": {}, "pressure_modifiers": {"water": 15},
        "skill_modifiers": {}, "event_tags": ["merciful"],
        "purgeable_by": [], "purge_difficulty": 0,
    },
    "clear_eyed": {
        "name": "Clear-eyed",
        "description": "Sees what is in front of them without flinching from it or dressing it up.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"water": 10, "space": 5},
        "skill_modifiers": {}, "event_tags": ["clear_eyed"],
        "purgeable_by": [], "purge_difficulty": 0,
    },

    # ── space wisdom ─────────────────────────────────────────────────────────
    "present": {
        "name": "Present",
        "description": "Fully in the room, whichever room it is.",
        "category": "behavioral", "inborn": True,
        "stat_modifiers": {"awareness": 1}, "pressure_modifiers": {"space": 10},
        "skill_modifiers": {}, "event_tags": ["present"],
        "purgeable_by": [], "purge_difficulty": 0,
    },

    # ── air wisdom ───────────────────────────────────────────────────────────
    "celebrant": {
        "name": "Celebrant",
        "description": "Takes uncomplicated pleasure in other people's luck.",
        "category": "behavioral", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"air": 10},
        "skill_modifiers": {}, "event_tags": ["celebrant"],
        "purgeable_by": [], "purge_difficulty": 0,
    },

    # ── klesha gaps: envy itself, apathy itself, sustained grudge ────────────
    "covetous": {
        "name": "Covetous",
        "description": "Measures their life against other people's, and comes up short every time.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"air": -10, "earth": -5},
        "skill_modifiers": {}, "event_tags": ["covetous"],
        "purgeable_by": ["yoga"], "purge_difficulty": 3,
    },
    "incurious": {
        "name": "Incurious",
        "description": "Has stopped asking. It was easier, and then it was habit.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"space": -10},
        "skill_modifiers": {}, "event_tags": ["incurious"],
        "purgeable_by": ["yoga"], "purge_difficulty": 3,
    },
    "grudge_bearer": {
        "name": "Grudge-bearer",
        "description": "Forgets nothing that was done to them, and keeps the ledger current.",
        "category": "personality", "inborn": True,
        "stat_modifiers": {}, "pressure_modifiers": {"water": -10, "air": -5},
        "skill_modifiers": {}, "event_tags": ["grudge_bearer"],
        "purgeable_by": ["yoga", "ritual"], "purge_difficulty": 4,
    },
    "chronic_pain": {
        "name": "Chronic Pain",
        "description": "The body's complaint is never entirely quiet.",
        "category": "physical", "inborn": True,
        "stat_modifiers": {"constitution": -1}, "pressure_modifiers": {"water": -10, "earth": -5},
        "skill_modifiers": {"yoga": 1}, "event_tags": ["chronic_pain"],
        "purgeable_by": ["ritual"], "purge_difficulty": 5,
    },
}

# race id -> new emotional_baseline (same convention: negative = klesha)
RACE_BASELINES = {
    "red_devil": {"space": 0, "fire": -10, "water": -15, "earth": 0, "air": 0},
    "rakshasa":  {"space": 0, "fire": 0, "water": -10, "earth": 0, "air": 0},
    "shardula":  {"space": 0, "fire": 0, "water": -5, "earth": 0, "air": 0},
    # human keeps space +5: the human birth is the one with the clearest access
    # to insight, so a small wisdom lean is correct as authored.
}


def main():
    data = json.load(open(TRAITS, encoding="utf-8"))
    changed = []
    for tid, (pressure, why) in REASSIGN.items():
        if tid not in data:
            raise SystemExit(f"unknown trait '{tid}'")
        before = data[tid].get("pressure_modifiers", {})
        data[tid]["pressure_modifiers"] = pressure
        changed.append((tid, before, pressure, why))

    added = []
    for tid, body in NEW_TRAITS.items():
        if tid in data:
            raise SystemExit(f"trait '{tid}' already exists — pick another id")
        data[tid] = body
        added.append(tid)

    with open(TRAITS, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    races = json.load(open(RACES, encoding="utf-8"))
    for rid, baseline in RACE_BASELINES.items():
        races["races"][rid]["emotional_baseline"] = baseline
    with open(RACES, "w", encoding="utf-8") as f:
        json.dump(races, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"re-seated {len(changed)} traits:\n")
    for tid, before, after, why in changed:
        print(f"  {tid:22} {str(before):26} -> {str(after):26} {why}")
    print(f"\nadded {len(added)} traits: {', '.join(added)}")
    print(f"rebased {len(RACE_BASELINES)} races")


if __name__ == "__main__":
    main()
