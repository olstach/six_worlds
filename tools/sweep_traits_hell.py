#!/usr/bin/env python3
"""Events x traits sweep, part 1a: hell.

Two jobs per event:
  GATES        — choices that appear only for a character with (or without) a
                 disposition. Blue, like a skill requirement, but keyed on who
                 someone is rather than what they trained.
  ACQUISITIONS — add_trait / remove_trait on outcomes where an event plausibly
                 marks a person.

A gate is worth adding only where the trait genuinely changes what a person
would do in that room. Where nothing suggests itself, the event is left alone —
a gate on every event would make traits feel like a checklist rather than a
character.
"""
import json

P = "/home/user/six_worlds/resources/data/events/hell_events.json"


def gate(cid, text, trait, outcome, skills=None, not_trait=False, attributes=None):
    reqs = {"not_trait" if not_trait else "trait": trait}
    if skills:
        reqs["skills"] = skills
    if attributes:
        reqs["attributes"] = attributes
    return {"id": cid, "text": text, "type": "requirement",
            "requirements": reqs, "outcome": outcome}


def out(text, rewards=None, karma=None, **extra):
    o = {"type": "text", "text": text}
    if rewards:
        o["rewards"] = rewards
    if karma:
        o["karma"] = karma
    o.update(extra)
    return o


# ── new trait-gated choices, keyed by event id ──────────────────────────────
GATES = {
    "hell_crossroads_shrine": [
        gate("pilgrim_stop", "Stop properly. This is what the road is for.", "pilgrim",
             out("You do it the long way — circumambulation, the full prostrations, the "
                 "offering placed rather than dropped.\n\nThe demons on the road watch with "
                 "the blank incomprehension of people watching someone garden during a siege. "
                 "You leave steadier than you arrived.",
                 {"xp": 20, "pressure": [{"element": "space", "amount": 10},
                                         {"element": "earth", "amount": 8}]},
                 karma={"human": 4, "god": 3})),
        gate("superstition_read", "Check which way the offerings are facing before you do anything.",
             "superstitious",
             out("Three of them face the road. One faces away.\n\nYou do not know what that "
                 "means, but you know it means something, and you arrange your own offering "
                 "to match the three. Nothing happens, which is exactly what you wanted.",
                 {"xp": 10, "pressure": [{"element": "air", "amount": 8}]})),
    ],
    "hell_ancient_stupa": [
        gate("pilgrim_circuit", "Walk the full circuit. Three times, the correct direction.", "pilgrim",
             out("It takes the better part of an hour in cold that makes an hour expensive.\n\n"
                 "On the third circuit you notice the thing the first two missed: a niche at "
                 "the base, sheltered from the wind, with something still in it.",
                 {"xp": 20, "items": ["item_random"]},
                 karma={"human": 3, "god": 3})),
    ],
    "hell_fire_shrine": [
        gate("lapsed_hesitates", "Stand at the edge. You have not done this in a long time.", "lapsed",
             out("The words are there. That is the surprise — you had assumed they had gone "
                 "with everything else, and they have simply been waiting, filed and dusty.\n\n"
                 "You say about half of them before you stop. It is more than you have said "
                 "in years.",
                 {"xp": 15, "pressure": [{"element": "space", "amount": 12}]})),
    ],
    "hell_teahouse_cold": [
        gate("tea_properly", "Watch how they are making it. Ask for the pot, not the cup.",
             "tea_ritualist",
             out("The proprietor looks at you for a moment longer than is comfortable, and "
                 "then hands over the pot without a word, which in this establishment is an "
                 "honour roughly equivalent to a title.\n\nYou make it properly. Several of "
                 "the silent figures relocate closer to the fire while you do.",
                 {"xp": 15, "pressure": [{"element": "water", "amount": 10},
                                         {"element": "fire", "amount": 5}]})),
        gate("gossip_listen", "Say nothing for an hour and listen to everyone else.", "gossip",
             out("An hour buys you: two names worth avoiding, one road that is not as closed "
                 "as the guard post claims, and the current price of a favour in this "
                 "district.\n\nNobody notices you listening. Nobody ever does.",
                 {"xp": 20, "gold": "small"})),
    ],
    "hell_teahouse_fire": [
        gate("drunk_relapse", "There is more than tea behind that counter, and you know it.",
             "drunk",
             out("There is. It is bad, and there is a lot of it, and the proprietor pours "
                 "without being asked twice.\n\nThe evening goes somewhere. In the morning "
                 "the party is short some coin and you are short some hours you would like "
                 "back.",
                 {"gold": -20, "pressure": [{"element": "fire", "amount": -12},
                                            {"element": "earth", "amount": -8}]})),
    ],
    "hell_medicinal_garden": [
        gate("bhang_ask", "Ask about the preparations they do not advertise.", "bhang_enjoyer",
             out("The healer's expression does not change, but she takes you to the far end "
                 "of the garden and shows you a bed you had walked straight past.\n\n"
                 "'For pain,' she says, in the tone of someone who has heard every other "
                 "reason and is offering you the dignity of not giving one.'",
                 {"xp": 10, "supplies": {"herbs": 4}})),
        gate("hunter_trade", "Offer what you carry — they will want the parts you do not use.",
             "hunter",
             out("Sinew, bone, the small glands that are worth more than the meat. She goes "
                 "through it with the brisk competence of someone who has done this trade "
                 "for a century.\n\nYou come away with herbs and a standing invitation.",
                 {"supplies": {"herbs": 6}, "xp": 15})),
    ],
    "hell_suspicious_gift": [
        gate("paranoid_perimeter", "Do not touch it. Find who is watching it.", "paranoid",
             out("You spend twenty minutes on the surrounding rocks instead of the package, "
                 "and you find him — a small demon flat behind a ridge with a good view and "
                 "a bad hiding place.\n\nHe runs. The package turns out to be exactly as bad "
                 "as you assumed, and you do not open it.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 10}]})),
        gate("incurious_shrug", "It is a box. Walk past the box.", "incurious",
             out("You walk past the box. Some hours later there is a sound behind you that "
                 "you decline to investigate.\n\nWhoever it was for, it was not for you.",
                 {"pressure": [{"element": "space", "amount": -5}]})),
    ],
    "hell_ice_demon_toll": [
        gate("scrimper_refuses", "Ten gold. For a chain. Explain in detail why this will not happen.",
             "scrimper",
             out("You itemise. You are thorough. You establish the market rate for chain, the "
                 "labour involved in stretching it across a road, and the total absence of "
                 "any service rendered.\n\nBy the end the lead demon is arguing about the "
                 "price of iron rather than collecting a toll, and the chain has somehow "
                 "already been lowered.",
                 {"xp": 20, "pressure": [{"element": "earth", "amount": 5}]})),
        gate("duelist_answers", "There is a faster way to settle this and everyone here knows it.",
             "duelist",
             out("You name the terms before anyone has decided whether to be offended: one "
                 "of theirs, one of yours, first to yield, no toll either way.\n\nTheirs is "
                 "shorter than you and considerably wider. It takes a while. The chain comes "
                 "down.",
                 {"xp": 30, "pressure": [{"element": "fire", "amount": 8}]})),
    ],
    "hell_bone_arena": [
        gate("duelist_cannot_refuse", "You were always going to. Do not pretend otherwise.",
             "duelist",
             out("The gatekeeper sees it happen — the moment the decision stops being a "
                 "decision — and grins with all the rows of teeth at once.\n\n'Oh, you're "
                 "one of those,' he says, delightedly, and waves you through without the fee.",
                 {"xp": 25, "gold": "moderate"})),
        gate("braggart_works_crowd", "Tell them who they are about to watch. At length.", "braggart",
             out("Very little of it is true. All of it is delivered well, and the tiers are "
                 "chanting a name by the end that is only approximately yours.\n\nThe purse "
                 "is larger for a crowd that has already decided how it wants the fight to go.",
                 {"gold": "moderate", "xp": 15})),
    ],
    "hell_ghost_village": [
        gate("mourner_keeps_days", "Do what nobody has done here in a long time: keep their days.",
             "mourner",
             out("You do not know their names or their calendar, so you use yours, and you "
                 "set out what can be spared at each door rather than at the centre.\n\n"
                 "It takes all afternoon. By the end the village is not less empty, but it "
                 "is differently empty.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 15}]},
                 karma={"human": 5, "hungry_ghost": -5})),
        gate("secret_bearer_recognises", "You know what a place looks like when everyone left "
             "at once and nobody wrote it down.", "secret_bearer",
             out("You find it because you know where a person puts a thing they do not want "
                 "found: not hidden, just somewhere nobody would look twice.\n\nUnder the "
                 "well's coping stone, wrapped in cloth. An account. It does not make good "
                 "reading and it is worth carrying.",
                 {"xp": 30, "items": ["item_random"]})),
    ],
    "hell_sinner_gang": [
        gate("gambler_joins", "There is a game running at the edge of that fire.", "gambler",
             out("There is. It is crooked in a way you identify within four throws and "
                 "decline to mention, since it is crooked in a direction you can work with.\n\n"
                 "You leave before it becomes impolite to keep winning.",
                 {"gold": "small", "xp": 15})),
        gate("drunk_belongs", "Sit down. These are, regrettably, your people.", "drunk",
             out("They make room without being asked, which is the thing about the damned — "
                 "they can spot it.\n\nYou are welcome here in a way that is not entirely "
                 "comfortable to be welcome, and you leave with a name to drop and a headache.",
                 {"xp": 10, "pressure": [{"element": "fire", "amount": -10},
                                         {"element": "water", "amount": 5}]})),
    ],
    "hell_veterans_camp": [
        gate("war_hardened_sits", "Sit down without being invited. They will not mind.",
             "war_hardened",
             out("They do not mind. Nobody asks where you served, because the question is "
                 "not interesting to anyone here — what is interesting is whether you know "
                 "how to sit at a fire without talking.\n\nYou do. By morning you have been "
                 "told three things about the road ahead that are not on any map.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 8}]})),
        gate("sole_survivor_recognised", "One of them looks at you and knows.", "sole_survivor",
             out("She does not say anything about it. She moves along the log to make room, "
                 "and later, when the fire is low, she says: 'It doesn't get quieter. You "
                 "just get better at the noise.'\n\nIt is not comfort. It is better than "
                 "comfort, which is accuracy.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 15},
                                         {"element": "space", "amount": 8}]})),
    ],
    "hell_black_lodge": [
        gate("secret_bearer_welcome", "You already know how to hold something. Say so.",
             "secret_bearer",
             out("The doorkeeper asks one question. Your answer is not the right one, but "
                 "the way you decline to elaborate apparently is.\n\nYou are shown further "
                 "in than most, and what is discussed there stays where it was discussed.",
                 {"xp": 30})),
    ],
    "hell_infernal_archive": [
        gate("curious_reads", "You will not be leaving until you have read something.", "curious",
             out("The archivist watches you work through two centuries of tax records with "
                 "the expression of a man who has finally met someone worse than himself.\n\n"
                 "Between the ledgers: a requisition order, countersigned, for something "
                 "that was never delivered. You copy the name.",
                 {"xp": 35})),
        gate("sharp_memory_holds", "Read it once. You will have it.", "sharp_memory",
             out("You read the index rather than the books, which is faster and, for you, "
                 "sufficient. Nine hundred entries. You will be able to produce any of them "
                 "on request for the rest of this life.",
                 {"xp": 30, "skill_up": {"skill": "learning", "amount": 1}})),
    ],
    "hell_burning_library": [
        gate("incurious_leaves", "It is a burning building. Leave the burning building.",
             "incurious",
             out("You leave the burning building. This turns out to have been the correct "
                 "structural assessment by a margin of about ninety seconds.\n\nSomeone else "
                 "will mourn the books.",
                 {"pressure": [{"element": "space", "amount": -8}]})),
    ],
    "hell_frozen_traveler": [
        gate("scrimper_counts", "Help, but count what it costs first.", "scrimper",
             out("Two rations, a blanket you were not using, and an hour. You total it as you "
                 "go, out of habit, and find the total does not bother you as much as you "
                 "expected.\n\nThe traveller lives. The accounting is, you decide, still "
                 "worth having done.",
                 {"xp": 15, "pressure": [{"element": "earth", "amount": 5}]}),
             ),
        gate("warm_hearted_no_question", "There is no decision here. Get them warm.",
             "warm_hearted",
             out("You are already moving before the question has finished being asked, and "
                 "the party follows because that is what happens when someone moves first.\n\n"
                 "They live. They will tell someone about it, somewhere down the road.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 12},
                                         {"element": "fire", "amount": 8}]},
                 karma={"human": 5})),
    ],
    "hell_lost_wanderer": [
        gate("homesick_recognises", "You know that particular way of sitting apart.", "homesick",
             out("You sit down at the same distance from them that they are sitting from "
                 "everything, which is the only approach that was ever going to work.\n\n"
                 "They talk for a while about a place that no longer exists. You know the "
                 "feeling well enough not to correct any of it.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 10}]})),
    ],
    "hell_demon_checkpoint": [
        gate("debtor_avoids", "Do not give your name. Do not give any name.", "debtor",
             out("The clerk wants a name for the ledger and you supply one, fluently, along "
                 "with a district and a plausible reason for travel.\n\nIt is not your name. "
                 "You have had a great deal of practice at this and it shows in all the wrong "
                 "ways.",
                 {"xp": 15, "pressure": [{"element": "air", "amount": -8}]})),
        gate("braggart_talks_through", "Talk. Keep talking. Do not stop talking.", "braggart",
             out("Forty minutes later the clerk has heard about three campaigns you were not "
                 "in, a title you do not hold, and a mutual acquaintance who does not exist.\n\n"
                 "He stamps the form to make it stop.",
                 {"xp": 20})),
    ],
    "hell_garuda_roost": [
        gate("pet_lover_greets", "Greet them the way you greet anything with feathers.",
             "pet_lover",
             out("This is, by every account, a serious error of protocol. The garuda are not "
                 "birds and take a dim view of being addressed as such.\n\nThe young one, "
                 "however, comes down off the pole to see what you are doing, and stays.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 8}]},
                 karma={"animal": 3})),
    ],
    "hell_lava_swimmer": [
        gate("hunter_reads_it", "Watch how it moves. Everything that hunts has a pattern.",
             "hunter",
             out("It surfaces on a count. Not a regular one — it is hunting the vents, not "
                 "the surface — but a count, and once you have it you know where it will not "
                 "be for about eleven seconds at a time.\n\nEleven seconds is enough.",
                 {"xp": 30})),
    ],
    "hell_bone_archer_camp": [
        gate("hunter_talks_shop", "Talk to them about the bows. Only about the bows.", "hunter",
             out("Skeletons, it emerges, have opinions about draw weight.\n\nAn hour of "
                 "genuinely technical conversation later, one of them presses something into "
                 "your hand — not a gift exactly, more a professional courtesy between people "
                 "who both know what a bad string does in cold.",
                 {"xp": 25, "items": ["item_random"]})),
    ],
    "hell_mercy_ward": [
        gate("chronic_pain_understood", "You do not need to explain the pain to this one.",
             "chronic_pain",
             out("The grey-robed figure listens to about six words and then stops you.\n\n"
                 "'Yes,' she says. 'The kind that is always there.' What she gives you does "
                 "not cure it, because it cannot be cured, and it is the first thing in a "
                 "long time that has actually helped.",
                 {"xp": 15, "restore": {"hp_percent": 25}})),
        gate("scarred_no_flinch", "Let them work. You have been through worse than a ward.",
             "scarred",
             out("She works quickly, because you are not making it difficult, and talks while "
                 "she does — mostly about other people's wounds, which is her way of not "
                 "asking about yours.\n\nYou leave better mended than you went in.",
                 {"restore": {"hp_percent": 30}, "xp": 10})),
    ],
    "hell_frozen_army": [
        gate("war_hardened_counts", "Look at the formation, not the faces.", "war_hardened",
             out("The formation tells you what happened: they were not caught marching. They "
                 "were caught *forming up*, which means they saw it coming and had time to "
                 "do the wrong thing about it.\n\nYou find the officer by where he is "
                 "standing. What he is holding is worth taking.",
                 {"xp": 30, "items": ["item_random"]})),
        gate("mourner_names_them", "Somebody should say something. Nobody has.", "mourner",
             out("You do not know a single name, so you say the words without them, which is "
                 "how it is done for the unnamed anyway.\n\nIt takes a long time. The ice "
                 "does not change. You did not expect it to.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 15},
                                         {"element": "space", "amount": 8}]},
                 karma={"human": 4, "hungry_ghost": -4})),
    ],
    "hell_ice_oracle": [
        gate("clear_eyed_discounts", "Listen to the prophecy. Then discount it correctly.",
             "clear_eyed",
             out("She says four things. Two are true of anyone, one is unfalsifiable, and "
                 "the fourth is specific, checkable, and delivered in a completely different "
                 "tone from the others.\n\nYou keep the fourth. It is worth keeping.",
                 {"xp": 30})),
        gate("superstitious_takes_all", "Every word of it matters. Write it down.", "superstitious",
             out("You get all of it, including the parts she probably did not mean as "
                 "prophecy.\n\nFor the next several days you will be interpreting ordinary "
                 "events as fulfilments, which is exhausting, and once — just once — "
                 "extremely useful.",
                 {"xp": 15, "pressure": [{"element": "air", "amount": -8},
                                         {"element": "space", "amount": -5}]})),
    ],
    "hell_hermit_monk": [
        gate("ascetic_recognised", "He looks at what you are carrying, which is very little.",
             "ascetic",
             out("'Ah,' he says, and something in his posture changes from courteous to "
                 "interested.\n\nWhat follows is not a teaching so much as a comparison of "
                 "notes between two people who have both decided that most things are "
                 "optional. You come away with one instruction, and it is a good one.",
                 {"xp": 35, "pressure": [{"element": "fire", "amount": 12},
                                         {"element": "space", "amount": 10}]})),
    ],
    "hell_ice_yogi": [
        gate("steady_practice_sits", "Sit down beside them. Do not announce it.", "steady_practice",
             out("You sit. The cold is immediate and then, some considerable time later, "
                 "less immediate.\n\nThe yogi does not acknowledge you at any point, which "
                 "you understand by the end to have been the entire teaching.",
                 {"xp": 30, "pressure": [{"element": "space", "amount": 15},
                                         {"element": "water", "amount": 10}]})),
    ],
    "hell_pyromancer_duel": [
        gate("duelist_accepts", "She has not finished the challenge. You have already accepted.",
             "duelist",
             out("The scars on her hands say she has done this often. Yours say something "
                 "similar, and she reads them at about the same moment you read hers.\n\n"
                 "It is a good duel. It is stopped, by mutual agreement, one exchange before "
                 "it would have stopped being one.",
                 {"xp": 35, "pressure": [{"element": "fire", "amount": 10}]})),
    ],
    "hell_demon_dojo": [
        gate("ascetic_forms", "Ask to stand in the back row and do the forms with them.",
             "ascetic",
             out("Nobody objects. Nobody helps, either — you get the form wrong for two hours "
                 "and are corrected exactly once, by a demon who does not break their own "
                 "rhythm to do it.\n\nThe correction is worth the two hours.",
                 {"xp": 30, "skill_up": {"skill": "martial_arts", "amount": 1}})),
    ],
    "hell_wandering_peddler": [
        gate("scrimper_haggles", "He has told you the price. Tell him the real one.", "scrimper",
             out("It takes eleven minutes and involves a detailed excursion into the "
                 "condition of his sack.\n\nHe settles well below where he started, calls "
                 "you something unrepeatable, and shakes your hand.",
                 {"gold": "small", "xp": 15})),
    ],
    "hell_infernal_forge": [
        gate("collector_spots", "There is something in the scrap pile that does not belong there.",
             "collector",
             out("There is. It has been in the pile long enough to be the colour of the pile, "
                 "which is presumably why nobody has taken it.\n\nThe smith watches you fish "
                 "it out and says nothing at all, which you decide to interpret generously.",
                 {"items": ["item_random"], "xp": 15})),
    ],
    "hell_burning_prisoner": [
        gate("merciful_cannot_pass", "You are not going to be able to walk past this.", "merciful",
             out("You are not. Everyone in the party works this out at approximately the same "
                 "moment you do, and the argument that follows is short.\n\nThe chains are "
                 "hot enough to cost you. The prisoner is down and breathing before you have "
                 "finished deciding whether it was wise.",
                 {"xp": 25, "rewards_note": None,
                  "hp_loss": {"amount": "light", "target": "random"},
                  "pressure": [{"element": "water", "amount": 15}]},
                 karma={"human": 6, "hell": -4})),
    ],
    "hell_cursed_pilgrim": [
        gate("oath_keeper_understands", "Ask what the vow was. Not why they are still keeping it.",
             "oath_keeper",
             out("Nobody has asked them that. Everyone asks the other question.\n\nThey tell "
                 "you, and it is a reasonable vow made for a reasonable reason, and the "
                 "stone is exactly as heavy as it was before. You walk with them for a while.",
                 {"xp": 25, "pressure": [{"element": "earth", "amount": 12}]},
                 karma={"human": 3})),
    ],
    "hell_tormented_soul": [
        gate("haunted_knows", "You know what it is like when the memory arrives uninvited.",
             "haunted",
             out("You do not offer advice, because there is none, and you do not tell them it "
                 "passes, because you would be lying.\n\nWhat you do is stay until the worst "
                 "of the current one is over. It is apparently not something anyone has done "
                 "for them before.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 12}]},
                 karma={"human": 4, "hungry_ghost": -3})),
    ],
    "devil_deserter": [
        gate("oath_breaker_recognises", "You know exactly what he is doing, because you did it.",
             "oath_breaker",
             out("You do not tell him it gets easier. You tell him the specific practical "
                 "things: which roads have checkpoints, what they ask, and how long before "
                 "anyone stops looking.\n\nHe listens like a man taking down an address.",
                 {"xp": 25, "pressure": [{"element": "earth", "amount": 8}]})),
        gate("oath_keeper_disapproves", "A vow is a vow. Say so, plainly, and then help anyway.",
             "oath_keeper",
             out("You tell him what you think of it. He takes it without arguing, which is "
                 "worse than arguing.\n\nThen you give him the water anyway, because the two "
                 "positions turn out not to be in conflict, whatever you had assumed.",
                 {"xp": 25, "pressure": [{"element": "earth", "amount": 10},
                                         {"element": "water", "amount": 5}]})),
    ],
}

# ── acquisitions: trait added or removed on an existing outcome ─────────────
# event id -> choice id -> {"add_trait"/"remove_trait": id or [ids]}
ACQUISITIONS = {
    "hell_sigh_of_relief": {
        "meditate": {"add_trait": "touched_by_grace"},
        "listen": {"add_trait": "touched_by_grace"},
        "specific_teaching": {"add_trait": "touched_by_grace"},
        "grab": {"add_trait": "covetous"},
    },
    "hell_angulimala_pursuit": {
        "walk_toward": {"add_trait": "merciful"},
        "read_the_stillness": {"add_trait": "clear_eyed"},
    },
    "hell_ghost_village": {
        "smoke_offering": {"add_trait": "mourner"},
    },
    "hell_frozen_army": {
        "mourner_names_them": {"add_trait": "mourner"},
    },
    "hell_ice_yogi": {
        "steady_practice_sits": {"add_trait": "enlightened_insight"},
    },
    "hell_teahouse_fire": {
        "drunk_relapse": {"add_trait": "night_drinker"},
    },
    "hell_sinner_gang": {
        "gambler_joins": {"add_trait": "gambler"},
    },
    "hell_black_lodge": {
        "secret_bearer_welcome": {"add_trait": "secret_bearer"},
    },
    "hell_burning_prisoner": {
        "merciful_cannot_pass": {"add_trait": "merciful"},
    },
    "hell_cold_hermit": {
        # the quest's resolution: whatever was carried out of the cold is put down
        "leave_him": {"add_trait": "harrowed"},
    },
}


def main():
    d = json.load(open(P, encoding="utf-8"))
    events = d["events"]

    added, skipped = 0, []
    for eid, choices in GATES.items():
        if eid not in events:
            skipped.append(f"missing event {eid}")
            continue
        existing = {c.get("id") for c in events[eid].get("choices", [])}
        for c in choices:
            if c["id"] in existing:
                skipped.append(f"{eid}:{c['id']} already exists")
                continue
            # keep the "leave / move on" style choice last where there is one
            events[eid].setdefault("choices", []).insert(
                max(0, len(events[eid]["choices"]) - 1), c)
            added += 1

    acq, acq_missing = 0, []
    for eid, per_choice in ACQUISITIONS.items():
        if eid not in events:
            acq_missing.append(f"missing event {eid}")
            continue
        by_id = {c.get("id"): c for c in events[eid].get("choices", [])}
        for cid, grant in per_choice.items():
            if cid not in by_id:
                acq_missing.append(f"{eid}:{cid} no such choice")
                continue
            target = None
            for branch in ("outcome_success", "outcome"):
                if branch in by_id[cid]:
                    target = by_id[cid][branch]
                    break
            if target is None:
                acq_missing.append(f"{eid}:{cid} has no outcome to attach to")
                continue
            target.setdefault("rewards", {}).update(grant)
            acq += 1

    with open(P, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"trait-gated choices added: {added}")
    print(f"acquisitions attached:     {acq}")
    if skipped:
        print("\nskipped gates:")
        for s in skipped:
            print("  ", s)
    if acq_missing:
        print("\nskipped acquisitions:")
        for s in acq_missing:
            print("  ", s)


if __name__ == "__main__":
    main()
