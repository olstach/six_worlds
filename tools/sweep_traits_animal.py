#!/usr/bin/env python3
"""Events x traits sweep, part 3: animal.

This realm is where the beast traits finally have somewhere to live —
hunter, beast_tender, pet_lover, bird_lover and sworn_vegetarian all read
differently here from anywhere else, and they are frequently in tension:
what a hunter sees in a herd is not what a pet_lover sees.
"""
import json

P = "/home/user/six_worlds/resources/data/events/animal_events.json"


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
    # ── birds ────────────────────────────────────────────────────────────────
    "birds_congress": [
        gate("bird_lover_knows_them", "You can name most of the delegations from here.",
             "bird_lover",
             out("You can, and you do, quietly, and the naming turns out to be the "
                 "credential — the congress has been addressed by a great many people who "
                 "did not know a shyena from a garuda.\n\nYou are given a place at the "
                 "lower branches, which is further in than visitors go.",
                 {"xp": 30, "pressure": [{"element": "air", "amount": 12}]},
             karma={"animal": 4})),
    ],
    "animal_forest_cliff_aerie": [
        gate("bird_lover_reads_nest", "Look at what is in the nest, not at the nest.",
             "bird_lover",
             out("Bone, wool, a length of dyed cord that did not come from anywhere nearby, "
                 "and — under all of it — the thing the cord was tied to.\n\nThe aerie's "
                 "owner has been collecting from a settlement that is not on your map, and "
                 "the direction it must lie in is now obvious.",
                 {"xp": 25, "items": ["item_random"]})),
    ],
    "animal_forest_high_canopy_perch": [
        gate("bird_lover_waits", "Do not call up to it. Wait until it comes down.", "bird_lover",
             out("Everyone calls up. That is why the shyena is at the top of the tallest "
                 "tree and not talking to anyone.\n\nYou sit at the base for two hours. It "
                 "comes down in its own time, which is the only time it was ever going to "
                 "come down in.",
                 {"xp": 30},
             karma={"animal": 3})),
    ],
    # ── the hunter / tender tension ──────────────────────────────────────────
    "animal_meadow_khadga_herd": [
        gate("hunter_reads_herd", "Forty animals and one of them is doing the watching.",
             "hunter",
             out("Second rank, north side, not grazing. Everything the herd will do in the "
                 "next minute is already decided by her.\n\nYou plan the crossing around one "
                 "animal instead of forty, and the herd never breaks.",
                 {"xp": 30})),
        gate("beast_tender_walks_it", "Walk in slowly. They will make room.", "beast_tender",
             out("They make room. It is not tameness — nothing here is tame — it is that "
                 "you are moving at a speed that reads as weather rather than as threat.\n\n"
                 "The party follows in your wake, and the crossing takes an hour instead of "
                 "a day.",
                 {"xp": 25, "pressure": [{"element": "earth", "amount": 8}]},
             karma={"animal": 3})),
    ],
    "animal_meadow_migration": [
        gate("homesick_watches", "It is going somewhere. That is the part that gets you.",
             "homesick",
             out("Two days of animals that know exactly where they are going and why, and "
                 "will be there by a particular week, and have been doing it since before "
                 "anyone was counting.\n\nYou watch a good deal more of it than the crossing "
                 "requires.",
                 {"xp": 20, "pressure": [{"element": "water", "amount": 8},
                                         {"element": "space", "amount": 5}]})),
    ],
    "animal_forest_sounder_matron": [
        gate("beast_tender_approaches", "She is lying in a wallow, not guarding a pass. "
             "Approach accordingly.", "beast_tender",
             out("You come in downwind, slowly, at an angle, and you stop at the distance "
                 "she chooses rather than the one you would prefer.\n\nShe lets you stop "
                 "there. For a sounder matron with young in the trees behind her, this is "
                 "an extraordinary concession, and both of you know it.",
                 {"xp": 30},
             karma={"animal": 4})),
        gate("hunter_declines", "You know exactly how this goes if it goes wrong.", "hunter",
             out("You have seen what a sounder does to something that got between the "
                 "matron and the young, and the memory is specific enough to be useful.\n\n"
                 "You take the party the long way without arguing about it, and nobody finds "
                 "out how it would have gone.",
                 {"xp": 20})),
    ],
    "animal_forest_gana_pack": [
        gate("hunter_recognises_work", "This is not an ambush. This is a working formation.",
             "hunter",
             out("It is the shape you would use yourself, if you had six people and needed "
                 "them to arrive around something at once.\n\nYou say so, out loud, with the "
                 "technical terms. The gana stop what they are doing and reconsider you from "
                 "the beginning.",
                 {"xp": 30, "pressure": [{"element": "air", "amount": 8}]})),
    ],
    "animal_ridge_predator": [
        gate("pet_lover_wrong_instinct", "He is enormous and beautiful and you want to say hello.",
             "pet_lover",
             out("You want to. Everything in you wants to, and the part of you that knows "
                 "better is losing the argument until somebody takes your elbow.\n\nYou "
                 "cross without incident and spend the rest of the day defending the "
                 "impulse, badly.",
                 {"xp": 10, "pressure": [{"element": "water", "amount": 5},
                                         {"element": "air", "amount": -5}]})),
    ],
    "animal_meadow_bhramara_swarm": [
        gate("beast_tender_stands_still", "Do not run from a swarm. Nobody has ever outrun one.",
             "beast_tender",
             out("You stop, and you make everyone else stop, which is much harder.\n\nThe "
                 "chord passes over and around and does not descend, because nothing in the "
                 "party is behaving like something worth descending on.",
                 {"xp": 25})),
    ],
    # ── appetite ─────────────────────────────────────────────────────────────
    "animal_forest_hedonist_camp": [
        gate("ascetic_declines", "You have opinions about this camp and you keep them to yourself.",
             "ascetic",
             out("You decline everything — the gourd, the cushions, the extremely good food "
                 "— politely and without comment, and your host finds this so novel that he "
                 "follows you to the edge of the clearing asking questions.\n\nHe is, under "
                 "all of it, lonely. You had guessed that from the size of the camp.",
                 {"xp": 30, "pressure": [{"element": "fire", "amount": 12}]})),
        gate("drunk_stays", "He is pouring and you are not going anywhere.", "drunk",
             out("You are not. The evening is genuinely excellent and the following day is "
                 "not, and somewhere in the middle you agreed to something you cannot "
                 "reconstruct.\n\nYour host, when you leave, looks briefly like someone "
                 "watching a colleague go.",
                 {"gold": -30, "pressure": [{"element": "fire", "amount": -12},
                                            {"element": "space", "amount": -8}]})),
        gate("bhang_shares", "He has more than drink out here and you can smell it.",
             "bhang_enjoyer",
             out("He does. The two of you spend an hour agreeing about a number of things "
                 "that will not survive contact with morning, and one thing that will: he "
                 "tells you where the good stands are, and he is not wrong.",
                 {"supplies": {"herbs": 5}, "xp": 15,
                  "pressure": [{"element": "water", "amount": 8}]})),
    ],
    "animal_meadow_bhramara_hive": [
        gate("gourmand_at_the_door", "Whatever else this is, it is also the best food in the realm.",
             "gourmand",
             out("It is. You trade properly for it rather than raiding, because you are "
                 "greedy and not stupid, and you are given a comb still warm from the "
                 "wall.\n\nYou make it last four days. Everyone else in the party gets some, "
                 "eventually, after negotiation.",
                 {"xp": 20, "supplies": {"food": 8},
                  "pressure": [{"element": "fire", "amount": 10}]})),
        gate("sworn_vegetarian_asks", "Ask whether taking it costs the hive anything.",
             "sworn_vegetarian",
             out("Nobody asks. The hive-mind takes some time over the answer, which is "
                 "itself interesting, and the answer is: some, but not much, and less than "
                 "you would think, and thank you for asking.\n\nYou are given more than the "
                 "traders get.",
                 {"xp": 25, "supplies": {"food": 6}},
             karma={"animal": 4})),
    ],
    # ── teahouses ────────────────────────────────────────────────────────────
    "animal_forest_teahouse": [
        gate("tea_ritualist_canopy", "A teahouse a hundred feet up. Do this properly.",
             "tea_ritualist",
             out("You do the whole form on a swaying platform in the canopy, which is "
                 "objectively ridiculous and which the proprietor watches with total "
                 "seriousness.\n\nAt the end she brings out the other pot — the one that "
                 "does not get offered — and does the form back at you.",
                 {"xp": 25, "pressure": [{"element": "water", "amount": 12}]})),
    ],
    "animal_meadow_teahouse": [
        gate("gossip_watering_hole", "Everything that lives here comes to this water eventually.",
             "gossip",
             out("Everything does, and everything talks, and a watering hole in the dry "
                 "season is the single most informative place on the plain.\n\nYou leave "
                 "knowing which route the migration will take, which is worth more than the "
                 "tea cost.",
                 {"xp": 25, "gold": "small"})),
    ],
    # ── devotion ─────────────────────────────────────────────────────────────
    "animal_crossroads_shrine": [
        gate("pilgrim_animal_trails", "Somebody built this where the animals cross, not where "
             "people do.", "pilgrim",
             out("That is the whole point of it and almost nobody notices. The cairn faces "
                 "the trails, the offerings are the kind an animal would take, and the "
                 "person who built it was making an argument.\n\nYou add to it in the same "
                 "spirit.",
                 {"xp": 25},
             karma={"animal": 5, "human": 2})),
    ],
    "animal_ocean_naga_temple": [
        gate("pilgrim_underwater", "It is a temple. The water is a detail.", "pilgrim",
             out("You go down and do the circuit, which underwater takes longer and hurts "
                 "more and is in every other respect identical.\n\nThe naga who find you "
                 "doing it are so thoroughly disarmed that the conversation afterwards "
                 "starts from a position no negotiation would have reached.",
                 {"xp": 30},
             karma={"god": 3, "animal": 3})),
    ],
    "animal_meadow_yaksha_standing_stones": [
        gate("superstitious_counts", "Nine stones. Count them again.", "superstitious",
             out("You count them again. There are nine. You count a third time from the "
                 "other direction and there are nine, and the fact that you needed to check "
                 "three times is the thing worth paying attention to.\n\nYou make the "
                 "offering at the one you kept losing.",
                 {"xp": 20, "pressure": [{"element": "space", "amount": -5},
                                         {"element": "air", "amount": 8}]})),
    ],
    "animal_meadow_patanga_ascetic": [
        gate("ascetic_stands_with", "You know what he is doing. Stand in it with him.", "ascetic",
             out("Wings spread, in the open, in full sun, until sundown. It is a stupid "
                 "practice and you both know it is a stupid practice and that is not an "
                 "argument against it.\n\nWhen the light goes he folds his wings and says "
                 "one sentence to you, and it is not about the practice.",
                 {"xp": 35, "pressure": [{"element": "fire", "amount": 15}]})),
    ],
    # ── study ────────────────────────────────────────────────────────────────
    "termite_cathedral": [
        gate("curious_dissects", "Fifteen feet of engineering and nobody drew the plans.",
             "curious",
             out("You spend the afternoon working out the ventilation, which is the part "
                 "that should not be possible, and by evening you have it: the mound "
                 "breathes on a temperature differential and the whole structure is a lung.\n\n"
                 "You will be thinking about this for weeks.",
                 {"xp": 30})),
    ],
    "animal_forest_mycelium_tender": [
        gate("curious_kneels_too", "She is doing something specific. Get down and look.",
             "curious",
             out("The varaha does not stop or explain. She does move over slightly, which "
                 "is permission.\n\nWhat she is doing is grafting — one network into "
                 "another, at a join she has prepared over what must be months. Nobody in "
                 "the party had known this was a thing that could be done.",
                 {"xp": 35})),
    ],
    "animal_meadow_dura_artisan": [
        gate("collector_appreciates", "Look at the work rather than the doorway.", "collector",
             out("It is very good work. It is also, you notice, made from about nine "
                 "different things that do not occur within a hundred miles of here.\n\nYou "
                 "say so. The artisan is delighted — nobody has ever recognised the "
                 "sourcing before, only the arrangement.",
                 {"xp": 25, "items": ["item_random"]})),
    ],
    # ── coin ─────────────────────────────────────────────────────────────────
    "animal_ocean_pearl_merchant": [
        gate("scrimper_pearls", "Pearls have a price and it is not the one on the cloth.",
             "scrimper",
             out("You go through the stock stone by stone, noting the flaws out loud in a "
                 "tone of mild regret.\n\nBy the end she has halved two prices to stop you "
                 "doing it to the rest, which is exactly the mechanism you were relying on.",
                 {"gold": "small", "xp": 15})),
    ],
    "animal_ocean_makara_tribute": [
        gate("debtor_reads_toll", "Somebody set this toll. Tolls have terms.", "debtor",
             out("They do, and the poles record them — the makara's terms are carved on the "
                 "landward side of the third post, which nobody reads because nobody thinks "
                 "of a makara as an institution.\n\nIt turns out you have already overpaid "
                 "by walking this far, and you say so.",
                 {"xp": 25, "gold": "small"})),
    ],
    "animal_forest_vanara_toll": [
        gate("braggart_talks_bridge", "Tell them what you did at the last bridge.", "braggart",
             out("None of it happened. The vanara are, however, professionals of the form, "
                 "and they can tell a good account from a true one and prefer the former.\n\n"
                 "You cross for a story instead of a coin. They will be telling your version "
                 "by winter, improved.",
                 {"xp": 20})),
    ],
    "animal_ocean_sunken_ship": [
        gate("greedy_dives_deeper", "There is a hold. Everything good is in the hold.", "greedy",
             out("There is, and it is, and the water in it is black and the angle is wrong "
                 "and you go down anyway.\n\nYou come up with more than the upper decks "
                 "would have given and rather less breath than you went down with.",
                 {"gold": "moderate", "items": ["item_random"],
                  "hp_loss": {"amount": "light", "target": "random"}})),
    ],
    # ── oracles ──────────────────────────────────────────────────────────────
    "animal_meadow_yaksha_shaman": [
        gate("clear_eyed_watches_hands", "Watch her hands, not the bones.", "clear_eyed",
             out("The bones land where she puts them. That is not a fraud — she is not "
                 "pretending otherwise, and when she sees you watching her hands she nods "
                 "as though a question has been settled.\n\nWhat she tells you afterwards, "
                 "without the bones, is the useful part.",
                 {"xp": 30})),
    ],
    "animal_meadow_cliff_oracle": [
        gate("superstitious_asks_properly", "An upside-down owl in a cliff. Ask the question "
             "properly.", "superstitious",
             out("There is a way of asking, and you know it, because you have always known "
                 "these things without being able to say where from.\n\nThe uluka answers "
                 "the question you asked rather than the one you meant, which is the risk "
                 "you accepted by asking properly.",
                 {"xp": 25})),
    ],
    # ── the rest ─────────────────────────────────────────────────────────────
    "animal_forest_healer_camp": [
        gate("chronic_pain_in_the_queue", "You know how to wait in a queue like this.",
             "chronic_pain",
             out("You do, and you do it without complaining, which the healer notices from "
                 "the other end of the line and files away.\n\nWhen your turn comes she "
                 "spends longer on you than the queue can really afford, and does not "
                 "mention why.",
                 {"restore": {"hp_percent": 25}, "xp": 15})),
        gate("scarred_gives_place", "Somebody here is worse off. You have had worse than this.",
             "scarred",
             out("You give up your place, and then the next one, and by the end of the "
                 "afternoon you have not been treated at all and have carried four people "
                 "to the front of the line.\n\nThe healer finds you at dusk and treats you "
                 "without being asked.",
                 {"restore": {"hp_percent": 20}, "xp": 25},
             karma={"human": 4, "animal": 2})),
    ],
    "animal_meadow_grassfire": [
        gate("war_hardened_organises", "A fire front is a line. You have worked a line before.",
             "war_hardened",
             out("You stop the party from running, which is the entire job, and then you "
                 "give four people four tasks in the order they need doing.\n\nIt is not "
                 "courage. It is that panic is a thing you stopped being able to do some "
                 "years ago, and it turns out to be worth more than courage here.",
                 {"xp": 30})),
        gate("pet_lover_drives_them", "There are animals in front of that fire.", "pet_lover",
             out("There are, and you are already moving toward them, and the argument about "
                 "whether this is sensible happens behind you at volume.\n\nYou get perhaps "
                 "a third of them out. The third is a real number of living things and you "
                 "decline to be told otherwise.",
                 {"xp": 25, "hp_loss": {"amount": "light", "target": "random"},
                  "pressure": [{"element": "water", "amount": 12}]},
             karma={"animal": 6, "human": 3})),
    ],
    "bone_forest": [
        gate("mourner_reads_arrangement", "The skulls face east. Somebody decided that.",
             "mourner",
             out("Somebody decided it, and kept deciding it, for what must be generations — "
                 "the arrangement is maintained, not merely made.\n\nYou find the current "
                 "keeper by looking for who has been walking here recently, and they are "
                 "glad to be found.",
                 {"xp": 30, "pressure": [{"element": "water", "amount": 10}]},
             karma={"animal": 3, "human": 2})),
    ],
    "animal_forest_gana_ceremony": [
        gate("celebrant_joins_ring", "Whatever it is for, they are glad about it. Be glad too.",
             "celebrant",
             out("You do not know the steps and you join the outer ring anyway, and the "
                 "outer ring is precisely where people who do not know the steps are "
                 "supposed to be.\n\nBy the third round you have most of it. By the fifth "
                 "you are being corrected, kindly, by a gana half your height.",
                 {"xp": 25, "pressure": [{"element": "air", "amount": 12},
                                         {"element": "fire", "amount": 8}]},
             karma={"animal": 4})),
    ],
    "naga_palace": [
        gate("beauty_struck_again", "You have been ambushed by this before.", "beauty_struck",
             out("The arch alone would have done it. You stand in front of it for some time "
                 "with the specific helplessness of somebody who knows exactly what is "
                 "happening to them and cannot speed it up.\n\nThe naga are used to this. "
                 "One of them waits with you.",
                 {"xp": 20, "pressure": [{"element": "space", "amount": 10},
                                         {"element": "fire", "amount": 8}]})),
    ],
    "animal_meadow_yaksha_challenge": [
        gate("duelist_meadow", "There is a spear in the ground across the trail.", "duelist",
             out("There is, and there is only one thing a spear planted across a trail has "
                 "ever meant, and you have been walking all morning.\n\nThe yaksha is "
                 "pleased. The bout is formal, brief, and settled on a technicality that "
                 "you both agree to call a win for him.",
                 {"xp": 30, "pressure": [{"element": "fire", "amount": 10}]})),
    ],
    "animal_forest_rakshasa_ambush": [
        gate("hunter_heard_it_first", "The birds stopped a hundred paces back. You stopped too.",
             "hunter",
             out("You stopped with them, which is why the party is already off the trail "
                 "and in cover when the rakshasa commits to a charge at where you were "
                 "going to be.\n\nIt is very fast. It is not faster than being somewhere "
                 "else.",
                 {"xp": 30})),
    ],
}

ACQUISITIONS = {
    "animal_sigh_of_relief":       {"meditate": {"add_trait": "touched_by_grace"},
                                    "give": {"add_trait": "generous"},
                                    "take": {"add_trait": "covetous"}},
    "animal_forest_hedonist_camp": {"out_drink": {"add_trait": "night_drinker"},
                                    "stay": {"add_trait": "gourmand"}},
    "bone_forest":                 {"assist": {"add_trait": "mourner"}},
    "animal_meadow_migration":     {"join": {"add_trait": "beauty_struck"}},
    "ancient_banyan":              {"meditate": {"add_trait": "beauty_struck"}},
    "animal_ocean_sunken_ship":    {"salvage": {"add_trait": "covetous"},
                                    "rites": {"add_trait": "mourner"}},
    "animal_meadow_grassfire":     {"run_north": {"add_trait": "harrowed"},
                                    "save_animals": {"add_trait": "merciful"}},
    "animal_forest_rakshasa_den":  {"loot": {"add_trait": "covetous"}},
    "birds_congress":              {"listen": {"add_trait": "bird_lover"}},
    "animal_meadow_bhramara_hive": {"raid": {"add_trait": "covetous"}},
    "naga_palace":                 {"observe": {"add_trait": "beauty_struck"}},
    "animal_forest_gana_ceremony": {"join": {"add_trait": "celebrant"}},
    "animal_meadow_patanga_ascetic": {"practice": {"add_trait": "ascetic"}},
    "animal_forest_healer_camp":   {"assist": {"add_trait": "merciful"},
                                    "donate": {"add_trait": "generous"}},
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
