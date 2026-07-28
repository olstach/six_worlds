#!/usr/bin/env python3
"""Events x traits sweep, part 2: hungry ghost.

The realm's own preoccupations decide which traits belong where: hunger,
unfinished business, debt, grief nobody has completed, and things that look
better than they are. Gates lean on the traits that speak to those — ascetic
and gourmand at the feasts, mourner and grief at the unburied, debtor at the
tolls, covetous and clear_eyed at the illusions.
"""
import json

P = "/home/user/six_worlds/resources/data/events/hungry_ghost_events.json"


def gate(cid, text, trait, outcome, not_trait=False, skills=None):
    reqs = {("not_trait" if not_trait else "trait"): trait}
    if skills:
        reqs["skills"] = skills
    return {"id": cid, "text": text, "type": "requirement",
            "requirements": reqs, "outcome": outcome}


def out(text, rewards=None, karma=None):
    o = {"type": "text", "text": text}
    if rewards:
        o["rewards"] = rewards
    if karma:
        o["karma"] = karma
    return o


GATES = {
    # ── hunger ───────────────────────────────────────────────────────────────
    "hg_charnel_feast": [
        gate("ascetic_unmoved", "You have been hungrier than this on purpose.", "ascetic",
             out("You look at the table the way you look at any table, which is to say "
                 "briefly.\n\nWhatever laid it was counting on the wanting, and there is not "
                 "enough of that in you to work with. The hall loses interest and the food "
                 "stops being convincing halfway down the table.",
                 {"xp": 30, "pressure": [{"element": "fire", "amount": 15}]})),
        gate("gourmand_tempted", "You can tell from here that the lamb is done properly.",
             "gourmand",
             out("You can. That is the trouble — it is not a general temptation, it is a "
                 "specific and extremely well-observed one, and something went to the effort "
                 "of knowing what you would want.\n\nYou eat one mouthful before the party "
                 "gets you away from the table. One is enough to be unwell for a day.",
                 {"hp_loss": {"amount": "light", "target": "random"},
                  "pressure": [{"element": "fire", "amount": -12}]})),
    ],
    "hg_preta_feast_swamp": [
        gate("sworn_vegetarian_declines", "Look at what is actually on the table first.",
             "sworn_vegetarian",
             out("You look, and having looked you decline, and the declining is easy in a "
                 "way it has not been easy for years.\n\nThe pretas cannot make you want it. "
                 "They have nothing else to offer and drift off to find someone who can be "
                 "worked with.",
                 {"xp": 25, "pressure": [{"element": "fire", "amount": 10},
                                         {"element": "earth", "amount": 8}]})),
    ],
    "hg_starving_preta": [
        gate("generous_feeds", "Give it something. It will not be enough and give it anyway.",
             "generous",
             out("It is not enough. Nothing would be — the throat is a needle and the belly "
                 "is a room.\n\nBut it stops, for a moment, being a thing that is starving "
                 "and becomes a thing that is being fed, and it looks at you differently for "
                 "the length of that moment.",
                 {"xp": 20, "supplies": {"food": -3},
                  "pressure": [{"element": "water", "amount": 12}]},
             karma={"hungry_ghost": -6, "human": 4})),
        gate("scrimper_calculates", "Work out exactly how little will satisfy it.", "scrimper",
             out("The answer is: nothing will, so the correct expenditure is the smallest "
                 "amount that buys passage.\n\nYou are right. You are right in a way that "
                 "sits badly on the walk afterwards, and the party does not discuss it.",
                 {"pressure": [{"element": "earth", "amount": -8}]},
             karma={"hungry_ghost": 4})),
    ],
    "hg_yidag_encounter": [
        gate("ascetic_recognises_it", "You know what it is to want and not take.", "ascetic",
             out("You sit down in front of it, which nobody does, and you do not offer it "
                 "anything, which everybody does and which has never once worked.\n\nWhat "
                 "you offer instead is the observation that the wanting does not have to be "
                 "obeyed. It is not cured. It is, for the first time in a very long while, "
                 "spoken to.",
                 {"xp": 35, "pressure": [{"element": "fire", "amount": 15}]},
             karma={"hungry_ghost": -8, "human": 5})),
    ],
    # ── grief and the unfinished ─────────────────────────────────────────────
    "hg_last_rites": [
        gate("mourner_finishes", "Somebody started this and did not finish it. Finish it.",
             "mourner",
             out("You know the order. You have done this often enough that your hands know "
                 "the order, which is the part nobody warns you about.\n\nWhen the pyre "
                 "takes, the thing that has been waiting at the edge of the clearing goes "
                 "wherever such things go, without any fuss at all.",
                 {"xp": 30, "pressure": [{"element": "water", "amount": 15}]},
             karma={"hungry_ghost": -8, "human": 5})),
    ],
    "hg_mass_grave": [
        gate("grief_struck_kneels", "You are already carrying one. What is a thousand more.",
             "grief_struck",
             out("It is not the same, and you know it is not the same, and you kneel anyway "
                 "because the difference is not the point.\n\nSomething in the ground eases. "
                 "Not much. The amount you would expect one person's attention to be worth.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 10}]},
             karma={"hungry_ghost": -6})),
    ],
    "hg_crying_river": [
        gate("melancholic_listens", "You have heard this note before, from the inside.",
             "melancholic",
             out("The faces are not saying anything. That is what everyone gets wrong — "
                 "they assume the sound is speech.\n\nIt is not. You know exactly what it "
                 "is, and you sit on the bank with it for a while, and the ferryman waits "
                 "without complaint, because he has seen this before too.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 8}]})),
    ],
    "hg_ancestor_spirit": [
        gate("mourner_keeps_it_up", "Somebody has been maintaining this. Take a turn.", "mourner",
             out("The offerings are recent and the cloth has been changed within the month, "
                 "which means somebody is walking a long way to do this and will not always "
                 "be able to.\n\nYou do what they have been doing, and you leave the shrine "
                 "better stocked than you found it.",
                 {"xp": 20, "supplies": {"food": -2}},
             karma={"human": 4, "hungry_ghost": -4})),
    ],
    "hg_weeping_shrine": [
        gate("pilgrim_stops_here_too", "It is half-sunk and it is still a shrine.", "pilgrim",
             out("You wade out to it. This is unpleasant and takes some time and the party "
                 "makes remarks.\n\nWhat you find on the far side, above the waterline, is a "
                 "carved instruction — brief, practical, and clearly meant for whoever cared "
                 "enough to get that close.",
                 {"xp": 25, "items": ["item_random"]},
             karma={"god": 3, "human": 2})),
    ],
    # ── debt ─────────────────────────────────────────────────────────────────
    "hg_toll_bridge": [
        gate("debtor_reads_the_sign", "Read the sign properly. Signs like this always have a clause.",
             "debtor",
             out("There is a clause. There is always a clause, and you have spent enough of "
                 "your life on the wrong side of one to find it inside a minute.\n\nThe toll "
                 "applies to the living. Two of your party, on a technicality that the "
                 "skeletons accept with visible irritation, are not paying it.",
                 {"xp": 25, "gold": "small"})),
    ],
    "hg_swamp_toll": [
        gate("scrimper_wont", "Four zombies and a causeway. Do the arithmetic out loud.",
             "scrimper",
             out("You establish, at length, that the causeway is not theirs, that no work has "
                 "been done to maintain it, and that the toll has no basis of any kind.\n\n"
                 "The zombies are not equipped for this argument. Two of them wander off "
                 "during it.",
                 {"xp": 20})),
    ],
    "hg_ossuary_bargain": [
        gate("oath_keeper_reads_first", "Read all of it before agreeing to any of it.",
             "oath_keeper",
             out("You read all of it. You are not agreeing to something you have not read; "
                 "you have never been able to, and it has cost you opportunities.\n\nThis "
                 "time it costs the ossuary keeper an hour and you the clause on the fourth "
                 "page, which was going to be the expensive one.",
                 {"xp": 30})),
    ],
    "hg_vetala_bargain": [
        gate("oath_breaker_knows", "You know what it is going to ask for, because you have given it before.",
             "oath_breaker",
             out("It wants a promise. It does not much care what the promise is about — the "
                 "value is in the breaking, later, when it can be collected on.\n\nYou "
                 "recognise the shape because you have been on the other side of it, and you "
                 "decline in terms it finds genuinely disappointing.",
                 {"xp": 30, "pressure": [{"element": "earth", "amount": 10}]})),
    ],
    # ── illusion and greed ───────────────────────────────────────────────────
    "hg_illusory_treasure": [
        gate("covetous_cannot", "You have already started walking toward it.", "covetous",
             out("You have. Someone catches your arm and you shake it off, and the arm-catcher "
                 "lets you go because there is a limit to how much you can save a person from "
                 "themselves.\n\nWhat you come back with is worthless and you carry it for "
                 "two days before admitting that.",
                 {"pressure": [{"element": "air", "amount": -12},
                               {"element": "earth", "amount": -8}]})),
        gate("clear_eyed_sees", "Look at the light on it. Light does not do that.", "clear_eyed",
             out("Light does not do that. It takes about four seconds once you are looking at "
                 "the right thing, and the right thing is never the treasure.\n\nYou can see "
                 "where whatever laid it is waiting, too, which is more useful than the "
                 "hoard would have been.",
                 {"xp": 30})),
    ],
    "hg_illusory_palace": [
        gate("suspicious_wont_enter", "A palace was not here an hour ago.", "suspicious",
             out("A palace was not here an hour ago, and you say so, repeatedly, until the "
                 "party stops arguing about it.\n\nYou make camp at a distance and watch. At "
                 "some point in the small hours the lit windows go out one row at a time, "
                 "which settles the matter.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 8}]})),
        gate("trusting_walks_in", "It is a warm building with the door open.", "trusting",
             out("It is. You are three rooms in and being handed something warm before "
                 "anyone else has crossed the threshold.\n\nWhat saves you is that you are "
                 "genuinely, transparently pleased to be there, and whatever runs the palace "
                 "finds it has nothing to work with. It lets you go, baffled.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 8}]})),
    ],
    "hg_mirror_pool": [
        gate("vain_looks_too_long", "Of course you are going to look.", "vain",
             out("You look. It shows you accurately, which is the cruelty of it — not "
                 "distorted, not aged, simply seen from outside for the first time.\n\nYou "
                 "are quiet for some hours afterwards and decline to say why.",
                 {"xp": 15, "pressure": [{"element": "earth", "amount": -12}]})),
    ],
    "hg_copper_mirror": [
        gate("clear_eyed_asks", "Ask what he is polishing it for.", "clear_eyed",
             out("Nobody asks that. Everybody asks what it shows.\n\nHe stops polishing. "
                 "'For the King,' he says, and then, after a pause that goes on rather too "
                 "long, 'He has not asked for it in some time.'",
                 {"xp": 30})),
    ],
    "hg_grave_goods": [
        gate("greedy_takes", "It is in the open. That makes it nobody's.", "greedy",
             out("You have the reasoning worked out before your hand arrives, which is the "
                 "sign of a well-practised reasoning.\n\nThe goods are real, valuable, and "
                 "will be missed by something that is still nearby.",
                 {"gold": "moderate", "pressure": [{"element": "earth", "amount": -10}]},
             karma={"hungry_ghost": 5})),
    ],
    # ── study ────────────────────────────────────────────────────────────────
    "hg_bone_library": [
        gate("curious_stays", "You are not leaving a library. Be reasonable.", "curious",
             out("The silver skeleton adjusts its spectacles and produces, from somewhere, a "
                 "second chair.\n\nWhat you find in four hours is not what you were looking "
                 "for and is considerably better: a name, an obligation, and where the "
                 "obligation was last recorded.",
                 {"xp": 35})),
        gate("sharp_memory_indexes", "Do not read them. Index them.", "sharp_memory",
             out("You go through the shelf-marks rather than the scrolls, which the "
                 "librarian watches with mounting professional respect.\n\nBy evening you "
                 "hold the shape of the whole collection, and the shape has a gap in it "
                 "exactly where something was removed.",
                 {"xp": 30})),
    ],
    "hg_dusty_library": [
        gate("incurious_passes", "A collapsed roof over wet paper. Move on.", "incurious",
             out("You move on. The roof comes down the rest of the way about an hour later, "
                 "which you hear from some distance and do not go back to investigate.",
                 {"pressure": [{"element": "space", "amount": -5}]})),
    ],
    "hg_vetala_riddler": [
        gate("curious_engages", "A riddle. Obviously you are going to try the riddle.", "curious",
             out("You are, and the vetala can tell, and it is so pleased to have a genuine "
                 "participant that it gives you the second riddle for free.\n\nYou get one "
                 "of the two. It considers this a good afternoon's work for both of you.",
                 {"xp": 30})),
    ],
    # ── beasts ───────────────────────────────────────────────────────────────
    "hg_graveyard_dog": [
        gate("pet_lover_approaches", "It is a dog. You are going to do this whatever anyone says.",
             "pet_lover",
             out("It is a dog in the way that a burnt-out house is a house, and you go "
                 "toward it anyway with your hand out, and the party makes noises.\n\nIt "
                 "lets you. It has apparently been standing on that grave for a very long "
                 "time and nobody has offered it anything since.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 10}]},
             karma={"animal": 4})),
    ],
    "hg_grave_hound_pack": [
        gate("hunter_reads_pack", "Find the one the others keep glancing at.", "hunter",
             out("Third from the left, smaller than the rest, standing slightly apart.\n\n"
                 "Everything the pack does routes through her. You do not have to fight "
                 "seven grave hounds; you have to convince one, in front of six witnesses.",
                 {"xp": 30})),
    ],
    # ── arts ─────────────────────────────────────────────────────────────────
    "hg_skeleton_musician": [
        gate("poet_answers_it", "It is playing a form. Give it words.", "poet",
             out("You put words to what it is playing, roughly and out of metre, and it "
                 "stops dead for the length of a breath before picking the line back up "
                 "underneath your voice.\n\nYou get through four verses. It has not had a "
                 "singer in a very long time.",
                 {"xp": 30, "pressure": [{"element": "air", "amount": 12},
                                         {"element": "fire", "amount": 8}]})),
    ],
    "hg_turquoise_dancers": [
        gate("celebrant_joins", "They are enjoying themselves. Join in.", "celebrant",
             out("You are terrible at it. This turns out to be entirely beside the point — "
                 "the troupe's delight is not in the standard of the dancing but in the fact "
                 "of somebody dancing.\n\nYou come away with flowers in your hair and, for "
                 "some hours, the inability to be gloomy about the hungry ghost realm.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 15},
                                         {"element": "fire", "amount": 10}]})),
    ],
    "hg_dancing_dead": [
        gate("celebrant_watches_kindly", "Let them have it. Watch properly.", "celebrant",
             out("They are dancing around an absence and they are doing it in total silence "
                 "and they have clearly been doing it a long time.\n\nYou watch it through "
                 "rather than past, which nobody has done, and at the end one of them bows "
                 "to you specifically.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 10}]},
             karma={"hungry_ghost": -4})),
    ],
    "hg_singing_skull": [
        gate("storyteller_trades", "It has a song. Trade it one.", "storyteller",
             out("You give it something long with a good middle, and it listens the whole "
                 "way through without humming over you, which for a skull on a cairn is "
                 "close to reverence.\n\nWhat it gives back is not a song. It is directions, "
                 "sung, and they are accurate.",
                 {"xp": 30})),
    ],
    # ── practice ─────────────────────────────────────────────────────────────
    "hg_death_meditation": [
        gate("ash_marked_belongs", "You have sat in places like this before.", "ash_marked",
             out("The stone is worn smooth in the shape of people who have done exactly this, "
                 "and you fit the shape.\n\nWhat comes up is not fear, because that was dealt "
                 "with some time ago. What comes up is the ordinary and much harder question "
                 "of what to do tomorrow.",
                 {"xp": 35, "pressure": [{"element": "space", "amount": 15},
                                         {"element": "water", "amount": 10}]})),
    ],
    "hg_charnel_hermit": [
        gate("steady_practice_asks", "Ask to sit with her. You will not need it explained.",
             "steady_practice",
             out("She looks at you for slightly too long and then moves over on the mat.\n\n"
                 "No instruction is given. None is needed and both of you know it, and the "
                 "afternoon goes by in a burning ground in complete silence and is one of "
                 "the better afternoons.",
                 {"xp": 35, "pressure": [{"element": "space", "amount": 12}]})),
    ],
    "hg_weary_pilgrim": [
        gate("pilgrim_sits_with", "You know this particular tiredness.", "pilgrim",
             out("It is not the walking. It is never the walking — it is the arithmetic of "
                 "how much road is left against how much of you there is.\n\nYou sit down at "
                 "the roadside with it and do not offer any encouragement, which is what it "
                 "needed and what nobody else has managed.",
                 {"xp": 25, "pressure": [{"element": "earth", "amount": 10}]},
             karma={"human": 3})),
    ],
    # ── teahouses, arenas, secrets ───────────────────────────────────────────
    "hg_teahouse_event": [
        gate("tea_ritualist_last_cup", "There is a right way to take a last cup.", "tea_ritualist",
             out("There is, and you do it — the whole form, in a bone teahouse at the edge "
                 "of the grey.\n\nThe skeleton proprietor watches every movement. When you "
                 "finish it turns the cup over, which you understand at once to mean that "
                 "the house will not be serving anyone else today.",
                 {"xp": 30, "pressure": [{"element": "water", "amount": 12}]})),
    ],
    "hg_bone_arena_event": [
        gate("gambler_finds_odds", "There is money moving in those tiers.", "gambler",
             out("There is, and the odds are being set by someone who has not watched the "
                 "third fighter closely enough.\n\nYou have. You bet accordingly and collect "
                 "with a straight face.",
                 {"gold": "moderate", "xp": 15})),
        gate("duelist_steps_down", "You are not going to sit in the tiers.", "duelist",
             out("You were never going to sit in the tiers. You are over the rail before the "
                 "current bout has finished and the crowd's noise changes shape.\n\nIt is "
                 "close. You win it, barely, and the barely is what they will remember.",
                 {"xp": 35, "gold": "small",
                  "hp_loss": {"amount": "light", "target": "random"}})),
    ],
    "hg_iron_skeleton_duel": [
        gate("duelist_cannot_walk_past", "A sword in the ground at a crossroads is a sentence "
             "with one ending.", "duelist",
             out("You draw before it has finished standing up, which it takes as the "
                 "courtesy it was intended to be.\n\nThe iron skeleton is better than you in "
                 "three respects and worse in one, and the one is enough.",
                 {"xp": 35, "pressure": [{"element": "fire", "amount": 10}]})),
    ],
    "hg_smuggler_tunnel": [
        gate("secret_bearer_reads_marks", "Those scratches are not damage. They are a message.",
             "secret_bearer",
             out("They are a message, in the sense that anything kept from most people is a "
                 "message to the rest.\n\nYou read it: a count, a direction, and a warning "
                 "about the third turning. All three prove accurate.",
                 {"xp": 30})),
    ],
    "hg_black_lodge": [
        gate("secret_bearer_admitted", "Say nothing at the door. That is the password.",
             "secret_bearer",
             out("It is. You are inside before you have decided whether you wanted to be, "
                 "and what is discussed there is not written down anywhere, including here.",
                 {"xp": 30})),
    ],
    "hg_medicinal_garden": [
        gate("chronic_pain_asks", "Ask for the thing that helps rather than the thing that cures.",
             "chronic_pain",
             out("The gardener stops what she is doing. It is, apparently, a much rarer "
                 "request than the other one and a considerably easier one to fulfil.\n\n"
                 "What she gives you will not fix anything. It makes tomorrow's walking "
                 "possible, which is the whole of what you asked for.",
                 {"supplies": {"herbs": 5}, "xp": 15})),
        gate("bhang_asks_hg", "Ask about the beds she has not mentioned.", "bhang_enjoyer",
             out("She has not mentioned them because most people do not ask, and most people "
                 "who do ask are not asking about medicine.\n\nShe establishes which you are "
                 "with one question, and appears satisfied with the answer.",
                 {"supplies": {"herbs": 4}, "xp": 10})),
    ],
    "hg_gravedigger": [
        gate("warm_hearted_asks_why", "He is alive. Ask him how he is, before anything else.",
             "warm_hearted",
             out("Nobody has asked him that. He gets asked what he is doing here, and how "
                 "he got here, and whether he can be bought.\n\nHe leans on the spade for a "
                 "while before answering, and the answer takes most of an hour and is worth "
                 "the hour.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 10}]})),
    ],
    "hg_body_possession": [
        gate("grudge_bearer_holds_on", "Whatever is in there is in one of yours. Do not let go.",
             "grudge_bearer",
             out("You do not let go. This is the one circumstance in which the thing that is "
                 "wrong with you is exactly the thing required.\n\nIt tries several exits. "
                 "You are still holding the arm at the end of it, and the face that comes "
                 "back is the right one.",
                 {"xp": 35, "pressure": [{"element": "water", "amount": -8}]})),
    ],
    "hg_shaza_ambush": [
        gate("war_hardened_ready", "You heard them a while ago. You have been waiting.",
             "war_hardened",
             out("You picked it up two hundred paces back — not a sound, a shape of silence "
                 "in the wrong place — and you have spent the walk since arranging where "
                 "everyone is standing.\n\nWhen it comes, it comes into a formation rather "
                 "than a column.",
                 {"xp": 30})),
    ],
    "hg_lost_traveler_swamp": [
        gate("homesick_understands", "He is not lost. He is somewhere he does not want to be.",
             "homesick",
             out("Lost is a thing you can fix with directions. This is the other thing, and "
                 "you recognise it because you are carrying a version of it yourself.\n\n"
                 "You do not give him directions. You sit in the water next to him for a "
                 "while, and then you both get up.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 10}]})),
    ],
    "hg_forgotten_shrine": [
        gate("pilgrim_restores", "Half-buried is not the same as finished.", "pilgrim",
             out("You dig it out. It takes an hour and ruins a pair of gloves and reveals "
                 "that the offering bowl is not empty — it was buried full, which means "
                 "somebody left in a hurry and meant to come back.",
                 {"xp": 25, "gold": "small"},
             karma={"god": 3, "human": 2})),
    ],
    "hg_king_messenger": [
        gate("gossip_delays_him", "A messenger has been everywhere. Keep him talking.", "gossip",
             out("He has orders and a schedule and neither of them survive twenty minutes "
                 "of being asked, with evident interest, about places he has recently been.\n\n"
                 "By the time he remembers the schedule you know the state of three roads "
                 "and one court.",
                 {"xp": 25})),
    ],
    "hg_corpse_oracle": [
        gate("superstitious_takes_it_all", "It is an oracle. Write down every word.", "superstitious",
             out("You take it down complete, including the parts that are clearly the "
                 "mechanism rather than the message.\n\nOne line of it will turn out to "
                 "matter enormously, and you will not know which until it does, which is "
                 "precisely the arrangement you have always found bearable.",
                 {"xp": 20, "pressure": [{"element": "air", "amount": -5}]})),
        gate("clear_eyed_separates", "Sort the prophecy from the plumbing.", "clear_eyed",
             out("Half of it is the propped jaw and the wind. A quarter is what any dead "
                 "mouth says. The remaining quarter is specific, and specific is the only "
                 "part that can be wrong, which is what makes it worth having.",
                 {"xp": 30})),
    ],
}

ACQUISITIONS = {
    "hg_sigh_of_relief":     {"read_move_on": {"add_trait": "touched_by_grace"}},
    "hg_last_rites":         {"complete_rites": {"add_trait": "mourner"},
                              "build_pyre": {"add_trait": "mourner"},
                              "take_offerings": {"add_trait": "covetous"}},
    "hg_funeral_rites":      {"help_rites": {"add_trait": "mourner"}},
    "hg_death_meditation":   {"meditate_death": {"add_trait": "enlightened_insight"}},
    "hg_charnel_hermit":     {"practice_with": {"add_trait": "ash_marked"}},
    "hg_body_possession":    {"beat_out": {"add_trait": "harrowed"}},
    "hg_mass_grave":         {"channel_energy": {"add_trait": "blood_handed"},
                              "consecrate": {"add_trait": "merciful"}},
    "hg_illusory_treasure":  {"grab": {"add_trait": "covetous"}},
    "hg_grave_goods":        {"take": {"add_trait": "covetous"},
                              "rebury": {"add_trait": "merciful"}},
    "hg_charnel_feast":      {"eat_anyway": {"add_trait": "haunted"},
                              "yoga_observe": {"add_trait": "clear_eyed"}},
    "hg_vetala_bargain":     {"accept": {"add_trait": "oath_breaker"}},
    "hg_golden_skeleton_sage": {"accept_teaching": {"add_trait": "touched_by_grace"}},
    "hg_mirror_pool":        {"meditate": {"add_trait": "clear_eyed"},
                              "drink": {"add_trait": "haunted"}},
    "hg_crying_river":       {"speak_faces": {"add_trait": "grief_struck"}},
    "hg_shaza_ambush":       {"play_dead": {"add_trait": "harrowed"}},
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
                skipped.append(f"{eid}:{c['id']} duplicate")
                continue
            cl = events[eid].setdefault("choices", [])
            cl.insert(max(0, len(cl) - 1), c)
            added += 1

    acq, missing = 0, []
    for eid, per in ACQUISITIONS.items():
        if eid not in events:
            missing.append(f"missing event {eid}")
            continue
        by = {c.get("id"): c for c in events[eid].get("choices", [])}
        for cid, grant in per.items():
            if cid not in by:
                missing.append(f"{eid}:{cid}")
                continue
            t = by[cid].get("outcome_success") or by[cid].get("outcome")
            if t is None:
                missing.append(f"{eid}:{cid} no outcome")
                continue
            t.setdefault("rewards", {}).update(grant)
            acq += 1

    with open(P, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"gates added: {added}   acquisitions: {acq}")
    for s in skipped:
        print("  skipped gate:", s)
    for s in missing:
        print("  skipped acquisition:", s)


if __name__ == "__main__":
    main()
