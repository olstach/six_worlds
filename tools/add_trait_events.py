#!/usr/bin/env python3
"""Trait- and relationship-triggered events.

These fire on a rest night that nothing else claimed. A trait event needs one
party member carrying the trait; a relationship event needs a pair sitting in
the named band. {a} and {b} are substituted with the actual names by
EventManager._substitute_actor_names().

Claude's prose. Wants Olaf's pass.
"""
import json

P = "/home/user/six_worlds/resources/data/events/domain_events.json"


def choice(cid, text, ctype, outcome, requirements=None):
    c = {"id": cid, "text": text, "type": ctype, "outcome": outcome}
    if requirements:
        c["requirements"] = requirements
    return c


def out(text, rewards=None, karma=None, otype="text", **extra):
    o = {"type": otype, "text": text}
    if rewards:
        o["rewards"] = rewards
    if karma:
        o["karma"] = karma
    o.update(extra)
    return o


TRAIT_EVENTS = {
    # ── gambler ──────────────────────────────────────────────────────────────
    "trait_gambler_game": {
        "title": "A Game at the Next Fire",
        "requires_trait": "gambler",
        "description": (
            "There is another fire within sight of yours, and around it, the unmistakable "
            "rhythm of a game — the pause, the clatter, the noise people make when someone "
            "loses badly.\n\n{a} has been looking at it for some time now."
        ),
        "choices": [
            choice("play_it_safe", "Let {a} play, but set a limit before they go.", "requirement",
                   out("{a} agrees to the limit with the easy sincerity of someone who has agreed to "
                       "limits before. This time, remarkably, they keep it — and come back with more "
                       "than they left with, and with the name of a man who buys things quietly.",
                       {"gold": "small", "xp": 15}),
                   {"skills": {"persuasion": 3}}),
            choice("play_deep", "Let it run. {a} knows what they are doing.", "roll",
                   out("It goes late. It goes badly, and then very well, and then the other fire "
                       "goes quiet in the way fires do when the stranger is winning.\n\n"
                       "{a} walks back before anyone decides to discuss it further.",
                       {"gold": "moderate", "xp": 20}),
                   {"roll": {"attribute": "luck", "dc_tier": "moderate"}}),
            choice("forbid", "Nobody is playing anything. We move at dawn.", "default",
                   out("{a} does not argue, which is worse than arguing. They sit with their back "
                       "to the other fire for the rest of the night, and are notably unrested "
                       "in the morning.",
                       {"pressure": [{"element": "fire", "amount": -10}]})),
        ],
        "failure_for": "play_deep",
        "failure": out("The game turns. It turns the way games do when someone else at the fire "
                       "has also been doing this for years.\n\n{a} comes back with empty hands and "
                       "a story about the light being bad.",
                       {"pressure": [{"element": "earth", "amount": -10}]}),
    },

    # ── debtor ───────────────────────────────────────────────────────────────
    "trait_debtor_collector": {
        "title": "Someone Has Been Asking",
        "requires_trait": "debtor",
        "description": (
            "A traveller shares your fire for an hour, and mentions, without any particular "
            "emphasis, that a man has been asking after someone matching {a}'s description "
            "in every settlement between here and the pass.\n\n"
            "He is described as patient. That is the word the traveller uses. Patient."
        ),
        "choices": [
            choice("pay_ahead", "Send the money ahead with the traveller.", "default",
                   out("It is most of what you have. The traveller takes it with the blank "
                       "courtesy of a man who has carried worse.\n\nWhether it arrives is another "
                       "question, but {a} sleeps properly for the first time in a while.",
                       {"pressure": [{"element": "air", "amount": 15}]},
                       ),
                   ),
            choice("send_word", "Have {a} send word: terms, and a date.", "requirement",
                   out("The letter is careful. It admits the debt, proposes a schedule, and "
                       "contains one line that a certain kind of creditor will recognise as an "
                       "offer rather than a plea.\n\nThe asking stops for a while.",
                       {"xp": 20}),
                   {"skills": {"trade": 4}}),
            choice("ignore_it", "Let him ask. The world is large.", "default",
                   out("The world is large. {a} spends the rest of the night working out exactly "
                       "how large, and how many roads there are through it, and how few of them "
                       "a patient man would need to watch.",
                       {"pressure": [{"element": "air", "amount": -12}]})),
        ],
    },

    # ── ascetic ──────────────────────────────────────────────────────────────
    "trait_ascetic_fast": {
        "title": "The Long Night",
        "requires_trait": "ascetic",
        "description": (
            "{a} has not eaten since yesterday, and does not intend to eat today either. "
            "They have taken the far side of the fire and gone somewhere behind their own face.\n\n"
            "It is not clear whether this is discipline or something that has stopped being "
            "discipline a while ago."
        ),
        "choices": [
            choice("sit_with_them", "Sit up with them. Say nothing.", "default",
                   out("You sit. The fire goes down. Around the fourth hour {a} says one sentence "
                       "about their teacher, and then nothing else, and in the morning something "
                       "between you has been settled without being discussed.",
                       {"xp": 15, "pressure": [{"element": "space", "amount": 10}]})),
            choice("guide_it", "Give the fast a shape — make it a practice, not a punishment.", "requirement",
                   out("You give them the frame: the hours, the posture, what to do with the "
                       "part of the mind that starts bargaining around midnight.\n\n"
                       "By dawn {a} is hollow-eyed and unmistakably clearer.",
                       {"xp": 30, "pressure": [{"element": "fire", "amount": 15},
                                               {"element": "space", "amount": 10}]}),
                   {"skills": {"yoga": 4}}),
            choice("make_them_eat", "Put food in their hands and stand there until it is gone.", "default",
                   out("They eat, because you are standing there. They are steadier for it in the "
                       "morning and quietly furious with you for three days.",
                       {"restore": {"hp_pct": 10}})),
        ],
    },

    # ── secret_bearer ────────────────────────────────────────────────────────
    "trait_secret_bearer_slip": {
        "title": "Nearly Said",
        "requires_trait": "secret_bearer",
        "description": (
            "Late, with the fire low and everyone half-asleep, {a} begins a sentence.\n\n"
            "It is four words long and it stops. Whatever the fifth word was going to be, "
            "it has been put back."
        ),
        "choices": [
            choice("let_it_go", "Pretend not to have heard.", "default",
                   out("You let it lie. {a} is grateful in the particular way of someone who has "
                       "just been spared, and sits a little closer to the fire afterwards.")),
            choice("draw_it_out", "Ask gently. Some things want carrying together.", "roll",
                   out("It takes an hour and it costs them something.\n\nWhat comes out is smaller "
                       "than you expected and much heavier than it looks, and {a} is a different "
                       "kind of tired at the end of it — the kind that heals.",
                       {"xp": 25, "pressure": [{"element": "water", "amount": 20}]}),
                   {"roll": {"attribute": "charm", "dc_tier": "moderate"}}),
            choice("press_hard", "Push. Whatever it is, it is walking with us.", "default",
                   out("{a} closes like a door. Whatever was nearly said is now considerably "
                       "further from being said than it was an hour ago.",
                       {"pressure": [{"element": "air", "amount": -10}]})),
        ],
        "failure_for": "draw_it_out",
        "failure": out("They talk around it for a while, pleasantly, and tell you nothing at all. "
                       "By the end you are not certain there was ever a sentence.",
                       {"pressure": [{"element": "space", "amount": -5}]}),
    },

    # ── pilgrim ──────────────────────────────────────────────────────────────
    "trait_pilgrim_detour": {
        "title": "A Stone Off the Road",
        "requires_trait": "pilgrim",
        "description": (
            "{a} has noticed something the rest of you walked past: a marker stone, half-swallowed, "
            "with the remains of offerings at its base.\n\n"
            "Someone tended this within living memory. Nobody has for a while."
        ),
        "choices": [
            choice("tend_it", "Clear it properly. It costs an hour.", "default",
                   out("You clear the base, straighten the stone, leave what can be spared. "
                       "{a} does the words from memory.\n\nThe hour is gone and something about the "
                       "party's footing is better for the rest of the day.",
                       {"xp": 15, "pressure": [{"element": "earth", "amount": 10}]},
                       karma={"human": 3, "god": 2})),
            choice("read_it", "Read what is carved there.", "requirement",
                   out("The script is three languages old and mostly worn, but enough survives: "
                       "a name, a direction, and a warning that was specific once.\n\n"
                       "{a} copies it down. It will mean something later.",
                       {"xp": 30}),
                   {"skills": {"learning": 4}}),
            choice("walk_on", "Note it and keep walking.", "default",
                   out("You keep walking. {a} looks back twice, and then makes a point of not "
                       "looking back again.",
                       {"pressure": [{"element": "space", "amount": -8}]})),
        ],
    },

    # ── beast_tender ─────────────────────────────────────────────────────────
    "trait_beast_tender_stray": {
        "title": "It Has Decided",
        "requires_trait": "beast_tender",
        "description": (
            "Something has attached itself to the camp — thin, wary, and entirely certain about "
            "which member of the party it intends to belong to.\n\n"
            "{a} has already fed it, which settles the matter as far as it is concerned."
        ),
        "choices": [
            choice("keep_it", "It can come. It eats what we can spare.", "default",
                   out("It comes. It is useless in every way that can be measured and the camp is "
                       "measurably better for it.",
                       {"pressure": [{"element": "water", "amount": 10},
                                     {"element": "fire", "amount": 5}]},
                       karma={"animal": 4})),
            choice("send_it_off", "Drive it off before it starves with us.", "default",
                   out("{a} does it themselves, which is the kindest way it can be done and does "
                       "not appear to help.",
                       {"pressure": [{"element": "water", "amount": -10}]})),
            choice("put_it_to_work", "Anything that eats can earn.", "requirement",
                   out("Within three days it is walking point, and doing it better than anyone "
                       "you would have assigned.",
                       {"xp": 25},
                       karma={"animal": 2}),
                   {"skills": {"logistics": 3}}),
        ],
    },

    # ── grudge_bearer ────────────────────────────────────────────────────────
    "trait_grudge_bearer_ledger": {
        "title": "The Ledger",
        "requires_trait": "grudge_bearer",
        "description": (
            "{a} is awake, and has been for some time, going over something in the dark with the "
            "thoroughness of a clerk.\n\n"
            "You have seen this before. It is never nothing, and it is never recent."
        ),
        "choices": [
            choice("hear_it", "Ask who it is. Let them say the name.", "default",
                   out("They say it. Then they say it again, with the details, and the details "
                       "have not softened by a single degree in however many years it has been.\n\n"
                       "Saying it out loud does not fix it. It does make the night shorter.",
                       {"pressure": [{"element": "water", "amount": 8}]})),
            choice("cut_it", "Tell them plainly what carrying it is costing.", "requirement",
                   out("It lands badly and then, some hours later, it lands properly.\n\n"
                       "{a} does not forgive anyone. But they put the ledger down for the night, "
                       "which is not nothing.",
                       {"xp": 25, "pressure": [{"element": "water", "amount": 15}]}),
                   {"skills": {"yoga": 4}}),
            choice("sharpen_it", "Let it sharpen. There will be a use for it.", "default",
                   out("You leave them to it. In the morning {a} is rested in the specific way of "
                       "someone who has spent the night deciding something.",
                       {"pressure": [{"element": "water", "amount": -10},
                                     {"element": "fire", "amount": 5}]},
                       karma={"hell": 3})),
        ],
    },

    # ── scarred (acquired) ───────────────────────────────────────────────────
    "trait_scarred_weather": {
        "title": "It Knows the Weather",
        "requires_trait": "scarred",
        "description": (
            "The cold has got into {a}'s old wound, the way it does, and they are pretending "
            "with some effort that it has not.\n\n"
            "It will pass by midday. It always passes by midday."
        ),
        "choices": [
            choice("treat_it", "Work on it properly before it stiffens.", "requirement",
                   out("Heat, pressure, and twenty patient minutes. {a} is functional by dawn "
                       "instead of by noon, and says so in about four words.",
                       {"xp": 15, "restore": {"hp_pct": 15}}),
                   {"skills": {"medicine": 3}}),
            choice("ask_about_it", "Ask how they got it.", "default",
                   out("They tell it flatly, which is how the bad ones get told. It is shorter "
                       "than you expected and there is a second story underneath it that does "
                       "not get told tonight.",
                       {"pressure": [{"element": "water", "amount": 5}]})),
            choice("say_nothing", "Say nothing and set an easy pace tomorrow.", "default",
                   out("You set the pace without mentioning why. {a} notices, and does not "
                       "mention that either. This is apparently how it is done.",
                       {"pressure": [{"element": "earth", "amount": 8}]})),
        ],
    },
}

RELATIONSHIP_EVENTS = {
    "rel_rivals_flashpoint": {
        "title": "It Has Been Building",
        "requires_band": "rival",
        "description": (
            "{a} and {b} have been circling something for days, and tonight it arrives — over "
            "nothing, over a pot and whose turn it was, in the way these things always arrive "
            "over nothing.\n\n"
            "The rest of the camp has gone very quiet."
        ),
        "choices": [
            choice("let_them", "Let them have it out. Words only.", "default",
                   out("It is ugly and thorough and it takes about twenty minutes.\n\n"
                       "At the end of it they are not friends, but the thing that was under the "
                       "surface is now above it, where everyone can see it, which is safer.",
                       {"pressure": [{"element": "fire", "amount": -5}]})),
            choice("mediate", "Get between them and make them each say the actual grievance.", "requirement",
                   out("You make them do it properly, one at a time, no interruptions.\n\n"
                       "It emerges that they are angry about two entirely different things, and "
                       "have each spent a week being furious about the wrong one.",
                       {"xp": 30, "pressure": [{"element": "air", "amount": 10}]}),
                   {"skills": {"persuasion": 5}}),
            choice("shut_it_down", "End it. Both of you, opposite sides of the fire, now.", "requirement",
                   out("They obey, because of how you said it.\n\nNothing is resolved. Nothing "
                       "gets worse tonight either, which was the immediate problem.",
                       {"xp": 15}),
                   {"skills": {"leadership": 4}}),
        ],
    },
    "rel_sworn_watch": {
        "title": "Second Watch",
        "requires_band": "sworn",
        "description": (
            "{a} takes second watch, which is {b}'s. No discussion, no announcement — they simply "
            "do not wake them.\n\n"
            "In the morning {b} works it out from the burn-down of the fire and says nothing "
            "about it, which is its own kind of answer."
        ),
        "choices": [
            choice("leave_it", "Leave them to it.", "default",
                   out("Whatever the two of them have built, it does not require your supervision. "
                       "The party moves a little easier for the rest of the week.",
                       {"pressure": [{"element": "water", "amount": 10},
                                     {"element": "earth", "amount": 5}]})),
            choice("use_it", "Two who trust each other that far should be fighting together.", "requirement",
                   out("You put them on the same flank and spend an evening on what each of them "
                       "is going to assume the other is doing.\n\nIt shows almost immediately.",
                       {"xp": 30, "buffs": [{"stat": "initiative", "amount": 3}]}),
                   {"skills": {"leadership": 4}}),
        ],
    },
    "rel_cool_thaw": {
        "title": "Neither of Them Will Say It",
        "requires_band": "cool",
        "description": (
            "{a} and {b} are not fighting. They are doing the other thing — the scrupulous "
            "politeness, the passing of the water skin at arm's length.\n\n"
            "It has been four days of this and the whole camp is tired of it."
        ),
        "choices": [
            choice("force_it", "Give them a job that needs both of them and walk away.", "default",
                   out("It takes them most of the morning, mostly in silence.\n\n"
                       "They come back having not discussed it at all, and having somehow "
                       "discussed it entirely.",
                       {"xp": 15})),
            choice("talk_to_each", "Talk to each of them separately. Find out what it actually is.", "requirement",
                   out("It is, as it usually is, one remark made two weeks ago that one of them "
                       "does not remember making and the other has not stopped hearing.",
                       {"xp": 25, "pressure": [{"element": "air", "amount": 8}]}),
                   {"skills": {"persuasion": 4}}),
            choice("ignore", "They are adults. Leave it.", "default",
                   out("They are adults, and it does not improve. The politeness gets a "
                       "little more scrupulous.",
                       {"pressure": [{"element": "water", "amount": -5}]})),
        ],
    },
}


def build(events_dict, trigger, key_field):
    built = {}
    for eid, spec in events_dict.items():
        ev = {
            "id": eid,
            "title": spec["title"],
            "trigger": trigger,
            "realm": "any",
            "rarity": "uncommon",
            key_field: spec[key_field],
            "description": spec["description"],
            "choices": spec["choices"],
        }
        # attach failure branches to the roll choices that declare one
        fail_for = spec.get("failure_for", "")
        if fail_for:
            for c in ev["choices"]:
                if c["id"] == fail_for:
                    c["success"] = c.pop("outcome")
                    c["failure"] = spec["failure"]
        built[eid] = ev
    return built


def main():
    d = json.load(open(P, encoding="utf-8"))
    events = d["events"]

    new = {}
    new.update(build(TRAIT_EVENTS, "trait", "requires_trait"))
    new.update(build(RELATIONSHIP_EVENTS, "relationship", "requires_band"))

    for eid, ev in new.items():
        if eid in events:
            raise SystemExit(f"event '{eid}' already exists")
        events[eid] = ev

    with open(P, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"added {len(new)} events to domain_events.json")
    for eid, ev in new.items():
        gate = ev.get("requires_trait") or ev.get("requires_band")
        print(f"   {ev['trigger']:12} {eid:34} on {gate}")


if __name__ == "__main__":
    main()
