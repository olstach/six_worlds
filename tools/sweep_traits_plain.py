#!/usr/bin/env python3
"""Events x traits sweep, part 4: the plain traits.

Parts 1-3 gravitated to the distinctive traits — pilgrim, duelist, secret_bearer
— and skipped the ordinary ones. That is backwards for frequency: brave, timid,
patient, strong, frail and their neighbours are the inborn traits most
characters actually roll, so a sweep that ignores them is a sweep most parties
never see.

This pass also uses the physical hindrances properly. A trait gate does not have
to open a better door; clubfooted, frail and hard_of_hearing open a *worse* one,
which is the only way those traits can be felt at all.

Spread across all four files, and it closes the acquisition gaps: addiction,
drunk, war_hardened, composed, oath_keeper and renunciate had no event that
could grant them.
"""
import json

ROOT = "/home/user/six_worlds/resources/data/events/"


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


HELL = {
    "hell_frozen_cave": [
        gate("brave_first", "Go in first. Somebody has to and it may as well be you.", "brave",
             out("You go in first. The dark does what dark does and you keep walking through "
                 "it, and the thing at the back of the cave turns out to be smaller than the "
                 "sound suggested, which is usually the way.\n\nThe party comes in behind you "
                 "considerably steadier than they would have.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 10}]})),
        gate("timid_hangs_back", "You are not going in there. You are simply not.", "timid",
             out("You are not, and no argument is going to move you, and the party goes in "
                 "without you.\n\nYou hold the entrance for an hour listening to sounds you "
                 "cannot interpret, which is very much worse than having gone in, and you "
                 "know it the whole time.",
                 {"pressure": [{"element": "air", "amount": -15}]})),
        gate("clubfooted_slow", "The floor is ice at an angle and your foot is what it is.",
             "clubfooted",
             out("You go down twice on the way in and the second one is bad — a knee into "
                 "stone, the sound of it loud in the cave.\n\nWhatever lives here now knows "
                 "the party is present. The rest of the approach has to be made at speed "
                 "rather than quietly.",
                 {"hp_loss": {"amount": "tiny", "target": "random"},
                  "pressure": [{"element": "earth", "amount": -8}]})),
    ],
    "hell_lava_flow": [
        gate("quick_dashes", "You have always been faster than the situation requires.", "quick",
             out("The gap is not really a gap. You are across it before it has finished "
                 "being one, and the second surge arrives where you were standing rather "
                 "than where you are.\n\nYou throw the rope back for everyone else.",
                 {"xp": 25})),
        gate("stubborn_refuses_around", "There is a way across. Going around is not a way across.",
             "stubborn",
             out("Everyone else has already agreed to go around and you have not, and the "
                 "argument takes twenty minutes that could have been spent walking.\n\nYou "
                 "are, in the end, correct: the crossing exists. It is also true that the "
                 "twenty minutes cost more than the detour would have.",
                 {"xp": 15, "pressure": [{"element": "earth", "amount": -5}]})),
    ],
    "hell_demon_checkpoint": [
        gate("patient_waits_it_out", "It is a clerk with a form. Let him have his form.", "patient",
             out("You answer every question in order, including the four that are the same "
                 "question, and you do not once indicate that you have noticed.\n\nThe clerk, "
                 "who is braced for a fight the way clerks always are, has nothing to push "
                 "against and stamps the thing in half the usual time.",
                 {"xp": 25})),
        gate("hot_tempered_snaps", "You have been standing at this table for a very long time.",
             "hot_tempered",
             out("You are two sentences into telling him what you think of the table, the "
                 "quill and the entire apparatus before anyone can get a hand on your arm.\n\n"
                 "The form is stamped eventually. It is stamped with an annotation, and the "
                 "annotation will be waiting at the next checkpoint.",
                 {"gold": -15, "pressure": [{"element": "water", "amount": -12}]})),
    ],
    "hell_demon_marketplace": [
        gate("flirt_works_the_stalls", "Every stall here is run by somebody bored.", "flirt",
             out("They are, and boredom is the only currency you have never been short of.\n\n"
                 "You do not buy anything at a discount. You are simply given three things "
                 "over the course of an afternoon, by three different people, each of whom "
                 "believes they started it.",
                 {"items": ["item_random"], "gold": "small", "xp": 15})),
        gate("content_buys_nothing", "You walk the whole market and want none of it.", "content",
             out("This is a strange sensation in a place engineered to produce the opposite, "
                 "and one of the vendors follows you for a while trying to work out what is "
                 "wrong with you.\n\nYou leave with your purse intact and an unusual amount "
                 "of goodwill from the one stallholder who understood.",
                 {"xp": 20, "pressure": [{"element": "earth", "amount": 10},
                                         {"element": "fire", "amount": 8}]})),
        gate("hard_of_hearing_misses", "The crowd noise here is total.", "hard_of_hearing",
             out("You catch about one word in four, and the one in four does not include the "
                 "part where the vendor names the real price, or the part where somebody "
                 "behind you says your description out loud.\n\nYou find out about the "
                 "second one later.",
                 {"gold": -20, "pressure": [{"element": "air", "amount": -8}]})),
    ],
    "hell_bone_arena": [
        gate("composed_before_fight", "The crowd is not the fight. Do not spend anything on "
             "the crowd.", "composed",
             out("You do not. You go out flat, unhurried and entirely uninterested in the "
                 "tiers, and your opponent — who has been playing to them for a living — "
                 "cannot find the rhythm they were expecting.\n\nIt is over rather quickly "
                 "and the crowd does not enjoy it at all.",
                 {"xp": 30, "gold": "moderate"})),
    ],
    "hell_hermit_monk": [
        gate("present_sits_down", "He is here. Be here.", "present",
             out("There is no teaching. You sit down opposite him in the snow and neither "
                 "of you says anything for a considerable time.\n\nAt the end he laughs "
                 "once, briefly, as though you had told a joke, and goes on his way. You "
                 "will spend some weeks working out what was funny.",
                 {"xp": 35, "pressure": [{"element": "space", "amount": 15}]})),
    ],
    "hell_frozen_traveler": [
        gate("frail_cannot_carry", "You want to carry them and you cannot.", "frail",
             out("You get about forty paces before your legs make the decision for you, and "
                 "somebody else takes the weight without comment, which is worse than "
                 "comment.\n\nThe traveller lives. You spend the evening being unhelpfully "
                 "angry at your own arms.",
                 {"pressure": [{"element": "earth", "amount": -10}]})),
        gate("strong_carries", "Pick them up. Keep walking.", "strong",
             out("You pick them up and keep walking and the party rearranges itself around "
                 "the fact without a word being spent on it.\n\nThey are at the waystation "
                 "an hour before they would otherwise have been, which is the whole "
                 "difference between the two available outcomes.",
                 {"xp": 25},
             karma={"human": 4})),
    ],
    "hell_sinner_gang": [
        gate("night_drinker_stays_late", "They have a fire and a bottle and no particular "
             "plans.", "night_drinker",
             out("So do you, now. The talk is good and the bottle is worse than the talk, "
                 "and at some point in the small hours it stops being an evening and starts "
                 "being a habit that has followed you into another realm.\n\nYou will feel "
                 "this one for a while.",
                 {"add_trait": "addiction",
                  "pressure": [{"element": "fire", "amount": -15},
                               {"element": "earth", "amount": -8}]})),
    ],
    "hell_teahouse_fire": [
        gate("night_drinker_again", "You know what is behind the counter and you know how "
             "many nights this makes.", "night_drinker",
             out("You do know how many nights this makes. That is new — the counting is new "
                 "— and you order anyway, which is the part that settles the question.\n\n"
                 "Nobody in the party says anything. Two of them exchange a look.",
                 {"add_trait": "drunk", "gold": -25,
                  "pressure": [{"element": "fire", "amount": -12}]})),
    ],
    "hell_ancient_stupa": [
        gate("renunciate_leaves_it", "You are carrying something you have been meaning to "
             "put down.", "renunciate",
             out("You put it in the niche. It is not an offering exactly — nobody is being "
                 "asked for anything — it is simply somewhere to leave a thing so that it "
                 "stops being yours.\n\nYou walk on lighter by an amount that has nothing "
                 "to do with the weight.",
                 {"add_trait": "renunciate", "xp": 30,
                  "pressure": [{"element": "fire", "amount": 15},
                               {"element": "earth", "amount": 8}]})),
    ],
    "devil_deserter": [
        gate("patient_hears_him", "He has not finished. Let him finish.", "patient",
             out("It takes him a long time to get to the actual sentence, and the actual "
                 "sentence is not the one he opened with.\n\nWhat he is done with is not the "
                 "Guard. Once that is out, the rest of the conversation is a different "
                 "conversation entirely.",
                 {"xp": 25})),
    ],
}

HG = {
    "hg_swamp_crossing": [
        gate("frail_struggles", "Black water to the chest, and you are not built for this.",
             "frail",
             out("You are not. You make it across and you make it across badly, and you "
                 "spend the next day with something in your lungs that should not be in "
                 "them.\n\nThe party slows for you, which you would rather they did not.",
                 {"hp_loss": {"amount": "light", "target": "random"},
                  "pressure": [{"element": "earth", "amount": -8}]})),
        gate("strong_fords_it", "Take the rope across first. You are the one who can.",
             "strong",
             out("You go in with the line and the current is exactly as bad as it looks and "
                 "you stand in it anyway while everyone else comes over hand by hand.\n\n"
                 "Your legs are unhappy for a day. Nobody else gets wet above the waist.",
                 {"xp": 25})),
    ],
    "hg_poison_bog": [
        gate("iron_stomach_holds", "Green mist. You have kept worse down than this.",
             "iron_stomach",
             out("Everyone else is retching before the halfway point and you are not, which "
                 "means you are the one still capable of pulling people forward.\n\nIt is "
                 "not a heroic contribution. It is the whole crossing, as it turns out.",
                 {"xp": 25})),
    ],
    "hg_ancient_battlefield": [
        gate("war_hardened_reads_field", "You can read what happened here from where you are "
             "standing.", "war_hardened",
             out("A line held, then folded from the left. The reserve went in late and went "
                 "in wrong. Everything after that was arithmetic.\n\nYou walk the field "
                 "explaining it to nobody in particular, and the party is very quiet, and "
                 "at the end of it you are more of a veteran than you were that morning.",
                 {"add_trait": "war_hardened", "xp": 30})),
        gate("sharp_eyed_spots", "Something in that jumble is not corroded.", "sharp_eyed",
             out("Nothing here should have survived. One thing has, under a shield that fell "
                 "the right way up, and it is in the condition it was in on the day.",
                 {"items": ["item_random"], "xp": 20})),
    ],
    "hg_bone_bridge": [
        gate("timid_will_not_cross", "It is made of people and it is over a hole that howls.",
             "timid",
             out("It is, and you cannot, and the party has to spend an hour finding a way "
                 "that does not involve it.\n\nThe hour costs supplies. Nobody says anything "
                 "about it, which somehow does not help.",
                 {"supplies": {"food": -4},
                  "pressure": [{"element": "air", "amount": -12}]})),
        gate("brave_goes_across", "Somebody crosses first or nobody crosses.", "brave",
             out("You go. The bridge says things while you are on it, in several voices, and "
                 "you keep walking through all of them.\n\nOn the far side you find you have "
                 "to sit down for a moment before waving the others over.",
                 {"xp": 30, "pressure": [{"element": "air", "amount": 8}]})),
    ],
    "hg_charnel_ground_entrance": [
        gate("fastidious_appalled", "You cannot help it. You simply cannot help it.",
             "fastidious",
             out("It is not fear, which would at least be respectable. It is that everything "
                 "here is *touching* everything else, and you spend the whole passage moving "
                 "in a way the vetala find frankly hilarious.\n\nThey let you through "
                 "specifically to see how far you will get.",
                 {"xp": 10, "pressure": [{"element": "earth", "amount": -8}]})),
    ],
    "hg_skeleton_army": [
        gate("composed_walks_through", "Ranks do not attack what walks through them like it "
             "belongs.", "composed",
             out("You walk down the middle at an even pace with your hands where they can be "
                 "seen, and you do not speed up at any point, including the point at which "
                 "the second rank turns its head.\n\nThey close behind you. Nothing else "
                 "happens.",
                 {"add_trait": "composed", "xp": 30,
                  "pressure": [{"element": "water", "amount": 10}]})),
    ],
    "hg_gyelpo_court": [
        gate("attractive_noticed", "The court notices you before you have said anything.",
             "attractive",
             out("It does, and the gyelpo — dead some centuries and still vain about his "
                 "hall — decides that you improve the room.\n\nYou are seated well above "
                 "where a traveller is seated, which is useful, and watched throughout, "
                 "which is not.",
                 {"xp": 20})),
    ],
    "hg_gomchen": [
        gate("oath_keeper_offers", "Offer to hold one of them. You are good for it.",
             "oath_keeper",
             out("You take one obligation off the web — the smallest, and even the smallest "
                 "is heavier than it looks — and the gomchen watches you accept it with an "
                 "expression that has not been used in a long time.\n\nYou will keep it. "
                 "That was never in question, which is precisely why it could be offered.",
                 {"add_trait": "oath_keeper", "xp": 35,
                  "pressure": [{"element": "earth", "amount": 15}]})),
    ],
    "hg_spirit_lanterns": [
        gate("night_owl_falls_in", "It is the middle of the night and you are wide awake.",
             "night_owl",
             out("Everyone else is asleep or nearly. You are at your best, and you fall in "
                 "at the back of the procession and walk with it for a mile before it "
                 "notices you.\n\nWhen it notices, it does not object. It makes room.",
                 {"xp": 25, "pressure": [{"element": "space", "amount": 10}]})),
        gate("light_sleeper_wakes", "You were awake before the light reached the camp.",
             "light_sleeper",
             out("You always are. It means you see the procession from its first lantern to "
                 "its last, which nobody else in the party does, and you count them.\n\nThe "
                 "number matters later.",
                 {"xp": 20})),
    ],
    "hg_vetala_riddler": [
        gate("forgetful_loses_it", "It said the riddle. You heard the riddle.", "forgetful",
             out("You heard the riddle and it has gone, entirely, in the time it took to "
                 "start thinking about it.\n\nThe vetala repeats it once, with visible "
                 "enjoyment, and then declines to repeat it again.",
                 {"pressure": [{"element": "space", "amount": -10}]})),
    ],
}

ANIMAL = {
    "animal_ocean_current_crossing": [
        gate("strong_anchors", "Somebody has to be the anchor and it is obviously you.",
             "strong",
             out("You take the upstream end and plant yourself, and the cold gets into your "
                 "legs and stays there while five people cross a rope you are personally "
                 "holding in place.\n\nYou go last. You are shaking by then and it does not "
                 "matter.",
                 {"xp": 25})),
        gate("clubfooted_footing", "Roped or not, the bottom here is round stones.",
             "clubfooted",
             out("Round stones and a fast current and a foot that has never once been "
                 "reliable on either.\n\nYou go down mid-channel and the rope saves you, "
                 "which is what the rope is for, and the pack you were carrying is not "
                 "saved by anything.",
                 {"supplies": {"food": -5},
                  "pressure": [{"element": "earth", "amount": -8}]})),
    ],
    "animal_meadow_khadga_charge": [
        gate("quick_steps_off", "You will not need to hold until the last moment. You are "
             "faster than the last moment.", "quick",
             out("You step off the line with time to spare, and having time to spare means "
                 "you can watch the whole thing go past from a yard away, which almost "
                 "nobody gets to do.\n\nIt is enormous. You will be describing it for weeks.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 10}]})),
        gate("timid_scatters_early", "You are already running and it has not started yet.",
             "timid",
             out("You are, and the running is the problem — a khadga follows movement, and "
                 "you have supplied the only movement on the plain.\n\nIt follows you a long "
                 "way before losing interest. The party finds you eventually.",
                 {"hp_loss": {"amount": "light", "target": "random"},
                  "pressure": [{"element": "air", "amount": -12}]})),
    ],
    "animal_forest_varaha_charge": [
        gate("brave_stands", "Do not climb. Stand.", "brave",
             out("Standing still in front of a charging sounder is a terrible idea that "
                 "happens to be the correct one, and you are the only person present "
                 "capable of doing it.\n\nThe matron breaks off four feet short. She was "
                 "never going to commit; she needed to see whether you would.",
                 {"xp": 30, "pressure": [{"element": "air", "amount": 12}]})),
    ],
    "animal_forest_mushroom_maze": [
        gate("hard_of_hearing_misses_it", "There is something to be heard here and you are "
             "not going to hear it.", "hard_of_hearing",
             out("The others stop and tilt their heads and go quiet, and you watch them do "
                 "it and understand only that something has been heard.\n\nBy the time it "
                 "has been explained the thing that made the sound has moved, and the "
                 "party's route with it.",
                 {"pressure": [{"element": "air", "amount": -8}]})),
        gate("fastidious_marks_route", "Nobody is getting lost in here on your watch.",
             "fastidious",
             out("You mark every third turning, consistently, on the same side, at the same "
                 "height.\n\nIt is fussy and slow and the party complains about it right up "
                 "until the point where you walk everyone back out in a fifth of the time it "
                 "took to walk in.",
                 {"xp": 25})),
    ],
    "animal_ocean_naga_court": [
        gate("attractive_seated_well", "The court is deciding where to put you.", "attractive",
             out("It decides quickly and it decides well, and the seat you are given has a "
                 "view of the proceedings that a trade delegation would have argued for.\n\n"
                 "You are aware this has nothing to do with anything you have done. It is "
                 "still the better seat.",
                 {"xp": 20})),
        gate("flirt_at_court", "A court is only people, and people are your subject.",
             "flirt",
             out("Within an hour you are on genuinely warm terms with two junior members of "
                 "a delegation and one archivist, and the archivist is the one who matters.\n\n"
                 "What you learn from her is not on the agenda and would not have been "
                 "raised at it.",
                 {"xp": 30})),
    ],
    "animal_forest_teahouse": [
        gate("early_riser_first_pot", "You are up before the canopy is light. So is she.",
             "early_riser",
             out("The proprietor is doing the first firing of the day when you come up the "
                 "rope ladder, and there is a particular understanding between people who "
                 "are awake at that hour by choice.\n\nYou get the first pot. The first pot "
                 "is not the same as the others and she does not explain why.",
                 {"xp": 20, "pressure": [{"element": "fire", "amount": 8}]})),
    ],
    "animal_meadow_patanga_ascetic": [
        gate("renunciate_stands_longer", "You have already given up more than a day of sun.",
             "renunciate",
             out("You stand past sundown, which he does not, and he comes back at moonrise "
                 "to find out what you are doing.\n\nThe conversation that follows is the "
                 "first one in months in which neither of you has to explain the premise.",
                 {"add_trait": "renunciate", "xp": 35,
                  "pressure": [{"element": "fire", "amount": 15}]})),
    ],
    "animal_meadow_khadga_herd": [
        gate("sharp_eyed_counts", "Something in that herd is not a khadga.", "sharp_eyed",
             out("Third group from the left, lying down, wrong shoulder line.\n\nIt has been "
                 "in among them for some time and the herd has accepted it, which tells you "
                 "considerably more about the thing than about the herd.",
                 {"xp": 25})),
    ],
}

ACQUISITIONS = {
    "hungry_ghost_events.json": {
        "hg_death_meditation": {"meditate_briefly": {"add_trait": "composed"}},
        "hg_preta_pack": {},
    },
    "animal_events.json": {
        "animal_forest_hedonist_camp": {"see_through": {"add_trait": "composed"}},
    },
}


def apply(filename, gates, acquisitions=None):
    path = ROOT + filename
    d = json.load(open(path, encoding="utf-8"))
    events = d["events"]
    added, skipped = 0, []
    for eid, choices in gates.items():
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
    acq = 0
    for eid, per in (acquisitions or {}).items():
        if eid not in events:
            skipped.append(f"missing event {eid}")
            continue
        by = {c.get("id"): c for c in events[eid].get("choices", [])}
        for cid, grant in per.items():
            if cid not in by:
                skipped.append(f"{eid}:{cid} no such choice")
                continue
            t = by[cid].get("outcome_success") or by[cid].get("outcome")
            if t is None:
                skipped.append(f"{eid}:{cid} no outcome")
                continue
            t.setdefault("rewards", {}).update(grant)
            acq += 1
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"{filename}: +{added} gates, +{acq} acquisitions")
    for s in skipped:
        print("   skipped:", s)


if __name__ == "__main__":
    apply("hell_events.json", HELL)
    apply("hungry_ghost_events.json", HG,
          ACQUISITIONS["hungry_ghost_events.json"])
    apply("animal_events.json", ANIMAL,
          ACQUISITIONS["animal_events.json"])
