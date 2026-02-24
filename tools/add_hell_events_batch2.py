#!/usr/bin/env python3
"""Add 12 next-batch hell events to hell_events.json."""

import json, sys

PATH = "resources/data/events/hell_events.json"

NEW_EVENTS = {
    "hell_bone_arena": {
        "id": "hell_bone_arena",
        "title": "The Bone Arena",
        "realm": "hell",
        "text": "A frozen pit ringed with bones rises from the wasteland — a combat arena, its tiers packed with ice demons howling for blood. Two poor souls fight below, stumbling with exhaustion.\n\nA massive demon in the gatekeeper's post blocks the exit path, its grin revealing too many teeth.\n\n'Fresh challenger! Enter the pit or find another road. There is no other road.'",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Step into the arena and fight",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "hard",
                    "text": "The crowd erupts. The gatekeeper signals, and arena champions pour in from the gates.",
                    "karma": {"hell": 2, "asura": 5}
                }
            },
            {
                "id": "challenge",
                "type": "requirement",
                "text": "Issue a formal challenge to the current champion",
                "requirements": {"attributes": {"strength": 13}},
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "normal",
                    "text": "The crowd hushes. The champion steps forward — single combat, honorable rules. The gatekeeper watches with something like respect.",
                    "rewards": {"xp": 12},
                    "karma": {"asura": 5, "human": 3}
                }
            },
            {
                "id": "narrate",
                "type": "requirement",
                "text": "Narrate the fight dramatically for the crowd",
                "requirements": {"skills": {"performance": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You step onto the announcer's perch and begin calling the fight — every blow, every stumble, every desperate reversal. The crowd shifts from baying for blood to hanging on your words. The champion wins but stands looking confused at his own victory. The gatekeeper is laughing so hard it opens the gate without remembering to demand payment.",
                    "rewards": {"xp": 10},
                    "karma": {"asura": 3, "human": 5}
                }
            },
            {
                "id": "bribe",
                "type": "default",
                "text": "Bribe the gatekeeper to look the other way",
                "outcome": {
                    "type": "text",
                    "text": "Gold changes hands. The gatekeeper pockets it with practiced ease and gestures toward the exit path. 'Don't tell the crowd,' it says. 'It ruins the atmosphere.'",
                    "rewards": {"xp": 3},
                    "karma": {"hungry_ghost": 4}
                }
            }
        ]
    },
    "hell_suffering_sage": {
        "id": "hell_suffering_sage",
        "title": "The Suffering Sage",
        "realm": "hell",
        "text": "A figure sits at the summit of a frozen ridge, encased in ice to the neck — only their face remains free, eyes open and clear. They have been here longer than the realm itself, or so it seems. Their expression holds no suffering, only the far-off calm of someone who has understood everything there is to understand about pain.\n\n'Ah. A visitor who can walk. How rare.' Their breath fogs in the frozen air. 'Ask. I have time.'",
        "choices": [
            {
                "id": "suffering",
                "type": "default",
                "text": "Ask about the nature of suffering",
                "outcome": {
                    "type": "text",
                    "text": "'All suffering comes from resistance to what is,' they say. 'The cold is not suffering. The resistance to the cold is suffering. Even here, that distinction holds.'\n\nThey let that sit for a moment. 'The beings in this realm are not suffering because they are cold. They are suffering because they cannot accept that they chose what led them here. Acceptance is not surrender. It is the beginning of movement.'\n\nYou sit with that for a long time.",
                    "rewards": {"xp": 8},
                    "karma": {"god": 5, "human": 3}
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Enter deep meditation to receive their teaching directly",
                "requirements": {"skills": {"yoga": 3}},
                "outcome": {
                    "type": "text",
                    "text": "You sit before them and let your awareness settle. After a time — minutes or hours — a current passes between you. Not words. Not images. Something beyond these: the shape of suffering itself, its exact texture, the precise moment when resistance becomes release.\n\nWhen you open your eyes, the ice around the sage has cracked slightly. They look at you with something that might be gratitude.\n\n'You carried that well,' they say. 'Go. You have more to do than I do.'",
                    "rewards": {"xp": 18},
                    "karma": {"god": 10, "human": 5, "hell": -5}
                }
            },
            {
                "id": "history",
                "type": "requirement",
                "text": "Ask about the history of this realm",
                "requirements": {"skills": {"learning": 2}},
                "outcome": {
                    "type": "text",
                    "text": "Their eyes go distant in a way that suggests they are looking across time rather than space.\n\n'I was here before the first demon arrived. The realm formed around certain patterns of mind — cold certainty, rigid self-justification — and those patterns needed a home. The first being who entered was a judge who had convinced himself he was perfectly just. He was here for a very long time.'\n\nA pause. 'Most leave eventually. Suffering is educational, when witnessed with open eyes. That is the purpose. Not punishment. Curriculum.'",
                    "rewards": {"xp": 12},
                    "karma": {"god": 4, "human": 4}
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave them to their vigil",
                "outcome": {
                    "type": "text",
                    "text": "'Go well,' they say as you turn away. 'You carry more wisdom than you know. The knowing will come in its own time.'\n\nTheir eyes return to whatever they have been watching since the realm began.",
                    "karma": {"human": 1}
                }
            }
        ]
    },
    "hell_suspicious_gift": {
        "id": "hell_suspicious_gift",
        "title": "Suspicious Gift",
        "realm": "hell",
        "text": "A neatly wrapped package sits in the center of the path, as though placed deliberately. The wrapping is red cloth, tied with a black cord. A tag reads: 'For whoever needs this most.'\n\nThe package is warm to the touch. Nothing else in the cold hell is warm.",
        "choices": [
            {
                "id": "inspect",
                "type": "roll",
                "text": "Examine it carefully before opening",
                "requirements": {"roll": {"attribute": "awareness", "difficulty": 12}},
                "outcome_success": {
                    "type": "text",
                    "text": "You run your hands along the edges without touching the cord and find what you were looking for — a thin thread connected to a pressure plate inside. A trap, but a crude one. You disarm it carefully and open the package.\n\nInside: a small fortune in gold, a health potion, and a note: 'Congratulations on your caution. That is the correct approach to kindness from unknown sources in the hells.'\n\nSomewhere, you suspect, a small devil is both annoyed and impressed.",
                    "rewards": {"xp": 8, "items": ["health_potion"], "gold": 40},
                    "karma": {"human": 2}
                },
                "outcome_failure": {
                    "type": "text",
                    "text": "You reach for the cord. The package trembles. A flash of cold and a sharp, unpleasant sound — then you're sitting on the ground, ears ringing.\n\nThe package is empty. A small card flutters down: 'Better luck with the next one.'\n\nYou are, somehow, fine. The trap was theatrical rather than lethal. A small devil's sense of humor.",
                    "rewards": {"xp": 3},
                    "karma": {"hell": 1, "animal": 2}
                }
            },
            {
                "id": "check_magic",
                "type": "requirement",
                "text": "Check it for traps with trained eyes",
                "requirements": {"skills": {"guile": 1}},
                "outcome": {
                    "type": "text",
                    "text": "Your trained eye finds the inscription on the underside — a binding rune designed to trigger on opening. Amateur work. You neutralize it with a flick of your fingers and open the package properly.\n\nInside: a health potion and gold. Maybe someone left it in sincerity. Maybe a devil left it and you ruined its day. Either way, you got the contents.",
                    "rewards": {"xp": 6, "items": ["health_potion"], "gold": 25},
                    "karma": {"human": 2}
                }
            },
            {
                "id": "open",
                "type": "default",
                "text": "Open it with reckless optimism",
                "outcome": {
                    "type": "text",
                    "text": "You pull the cord.\n\nA flash. A sound. A moment of blinding cold.\n\nThen you're standing there holding a health potion and forty gold pieces, entirely unharmed. The package was just a package. The warmth was just warmth. The suspicious circumstances were just circumstances.\n\nSometimes things are exactly what they appear to be.",
                    "rewards": {"xp": 4, "items": ["health_potion"], "gold": 40},
                    "karma": {"animal": 2, "human": 1}
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave it — gifts in hell are seldom genuine",
                "outcome": {
                    "type": "text",
                    "text": "You step around it carefully and continue on your way.\n\nBehind you, the package remains in the center of the path. Warm. Patient. Waiting for someone either braver or more foolish than you.",
                    "karma": {"human": 1}
                }
            }
        ]
    },
    "hell_ice_demon_toll": {
        "id": "hell_ice_demon_toll",
        "title": "Ice Demon Toll",
        "realm": "hell",
        "text": "Three squat ice demons have stretched a rope of frozen chain across the path. They look bored, cold, and deeply optimistic about shakedowns. The largest one holds a sign reading 'TOLL — 10 GOLD' in letters of varying sizes.\n\n'Passage fee,' says the leader, with the confidence of someone who has never questioned their own authority. 'Ten gold. Standard Hell Traversal Rate, Section 7, Paragraph 4.'\n\n'There is no Section 7, Paragraph 4,' you say.\n\n'There will be,' it replies, 'if you don't pay.'",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Refuse and fight your way through",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "normal",
                    "text": "The demons drop the chain and reach for their weapons. The leader manages to look both threatening and personally offended.",
                    "karma": {"asura": 2, "hell": 2}
                }
            },
            {
                "id": "pay",
                "type": "default",
                "text": "Pay the toll and move on",
                "outcome": {
                    "type": "text",
                    "text": "You hand over the gold. The leader counts it with elaborate care, biting each coin, then unclips the chain and bows with a courtliness completely at odds with everything else about the situation.\n\n'Passage granted. Safe travels. Watch out for the unofficial toll three roads further on — those ones are criminals.'",
                    "rewards": {"xp": 2},
                    "karma": {"hungry_ghost": 2}
                }
            },
            {
                "id": "argue",
                "type": "requirement",
                "text": "Challenge the legal legitimacy of this checkpoint",
                "requirements": {"skills": {"guile": 1}},
                "outcome": {
                    "type": "text",
                    "text": "You spend forty minutes in forensic argument. You point out the absence of any hell bylaw authorizing such a toll, the lack of official seals, the three different handwritings on the sign, and the suspicious provision that payment 'may be rendered in gold, goods, or goods that are also gold.'\n\nThe lead demon's expression passes through outrage, uncertainty, and finally hollow defeat.\n\n'You can go,' it says. 'But only because we choose to be magnanimous.'\n\nBehind it, one of the other demons quietly folds the sign.",
                    "rewards": {"xp": 8},
                    "karma": {"human": 3, "hell": -2}
                }
            },
            {
                "id": "perform",
                "type": "requirement",
                "text": "Offer to pay in entertainment",
                "requirements": {"skills": {"performance": 1}},
                "outcome": {
                    "type": "text",
                    "text": "You offer to pay in entertainment instead of gold and, before anyone can object, launch into a performance. The demons are transfixed. When it ends, the leader is applauding.\n\n'Right, fine, that's payment,' it says, still clapping. The chain is unclipped. One of the other demons presses a coin into your hand on the way past — 'Keep it. Best thing that's happened here in a century.'",
                    "rewards": {"xp": 5, "gold": 5},
                    "karma": {"human": 3, "asura": 2}
                }
            }
        ]
    },
    "hell_cursed_pilgrim": {
        "id": "hell_cursed_pilgrim",
        "title": "The Cursed Pilgrim",
        "realm": "hell",
        "text": "A person trudges forward pulling a massive stone block behind them — literally. A chain of black iron links ankle to stone, the stone gouging a furrow in the frozen ground. They are making slow but genuine progress.\n\nThey look up with exhausted, intelligent eyes.\n\n'Oh. A living one. That's rare.' A pause for breath. 'I made a deal with a small devil. The small ones are the worst. You can fight the big ones.'",
        "choices": [
            {
                "id": "break",
                "type": "requirement",
                "text": "Break the chain by brute force",
                "requirements": {"attributes": {"strength": 15}},
                "outcome": {
                    "type": "text",
                    "text": "You grip the chain and heave. The iron bites into your palms. The chain flexes. You heave again, and again, and — with a sound like the cold itself breaking — a link shatters.\n\nThe pilgrim sits down heavily and simply breathes for a long moment. Then they look at their free ankle with an expression you cannot quite name.\n\n'Thank you,' they say. 'I had forgotten what it felt like to stop.'\n\nThey press a carved token into your hands before you leave.",
                    "rewards": {"xp": 12, "items": ["prayer_beads"]},
                    "karma": {"hell": -8, "human": 5, "god": 5}
                }
            },
            {
                "id": "examine",
                "type": "requirement",
                "text": "Examine the curse and explain the mechanism",
                "requirements": {"skills": {"black_magic": 1}},
                "outcome": {
                    "type": "text",
                    "text": "You study the chain. Devil's work — a specific class of binding, not unbreakable but resistant to direct force. Vulnerable to patient unraveling from within. You explain the mechanism in careful detail.\n\nThe pilgrim listens, asking precise questions. By the end, their posture has changed. They look like someone with a plan.\n\n'I think I understand now,' they say. 'It wasn't cleverer than me. It was just more patient. I can be patient too.'",
                    "rewards": {"xp": 10},
                    "karma": {"human": 4, "hell": -3}
                }
            },
            {
                "id": "walk",
                "type": "default",
                "text": "Walk with them a while and listen",
                "outcome": {
                    "type": "text",
                    "text": "You fall into step beside the pilgrim, matching their slow progress. They tell the story of the deal — a small devil with elaborate contracts and patient eyes. 'I thought I was clever,' they say. 'I thought I had found a loophole. I had found the loophole it wanted me to find.'\n\nYou walk for perhaps an hour. When you part, the stone seems no lighter, but the pilgrim's expression has shifted from defeat to something that might, eventually, become acceptance.\n\n'It helps,' they say, 'to be reminded that someone can walk freely.'",
                    "rewards": {"xp": 5},
                    "karma": {"human": 4, "hell": -2}
                }
            },
            {
                "id": "attempt_help",
                "type": "default",
                "text": "Try to help break the chain",
                "outcome": {
                    "type": "text",
                    "text": "You try everything you can reach for — brute force, striking at joints, looking for a weak link. The chain is absolutely indifferent to your efforts.\n\nThe pilgrim watches with tired gratitude. 'It's all right,' they say. 'The trying matters. I had forgotten anyone would bother.'\n\nYou part with a handshake. Their grip is stronger than you expected.",
                    "rewards": {"xp": 3},
                    "karma": {"human": 3, "hell": -1}
                }
            }
        ]
    },
    "hell_frozen_army": {
        "id": "hell_frozen_army",
        "title": "The Frozen Army",
        "realm": "hell",
        "text": "The valley below is filled with an army, frozen mid-march — thousands of soldiers preserved in ice, weapons raised, banners still flying. The armor is from no civilization you recognize. They are marching toward something that is no longer there.\n\nThey do not look like they are suffering. They look like they are waiting.",
        "choices": [
            {
                "id": "respect",
                "type": "default",
                "text": "Pay your respects to the fallen",
                "outcome": {
                    "type": "text",
                    "text": "You stand at the valley's edge and bow your head. A long silence.\n\nSomething shifts in the ice — barely perceptible. In the front rank, a soldier's hand tightens almost imperceptibly around their weapon. A small acknowledgment. They are aware you are there. They appreciate that you noticed them.\n\nYou bow again before you leave.",
                    "rewards": {"xp": 5},
                    "karma": {"human": 3, "god": 2}
                }
            },
            {
                "id": "study",
                "type": "requirement",
                "text": "Study the banners and try to identify them",
                "requirements": {"attributes": {"awareness": 12}},
                "outcome": {
                    "type": "text",
                    "text": "The banners show a sun bisected by a spear — a symbol from before recorded history. The armor style is wrong for any hell-native force. These were mortals.\n\nThe realization comes slowly: this army marched here deliberately. They came to fight their way into hell to rescue someone. By the marks on their armor, they were winning.\n\nThen something stopped them. Not defeated — frozen mid-advance.\n\nThis is not a punishment. This is grief, suspended. Whoever they came for is gone, and they never got the message.",
                    "rewards": {"xp": 10},
                    "karma": {"human": 5, "god": 3, "hell": -2}
                }
            },
            {
                "id": "release",
                "type": "roll",
                "text": "Search for a way to end their vigil",
                "requirements": {"roll": {"attribute": "awareness", "difficulty": 13}},
                "outcome_success": {
                    "type": "text",
                    "text": "You find it at the base of the lead soldier's standard — a binding mark, old enough that the ice has grown over it. You speak the words of release, slowly.\n\nThe ice begins to melt. Not violently — gently, like morning frost. The army's forms become translucent, then luminous, then gone. In the valley below, the ice is clean and empty.\n\nBefore the last soldier fades, they turn their head toward you and nod. It is a gesture of ancient and absolute gratitude.",
                    "rewards": {"xp": 15},
                    "karma": {"god": 8, "hell": -8}
                },
                "outcome_failure": {
                    "type": "combat",
                    "enemy_group": "lost_souls",
                    "difficulty": "normal",
                    "text": "Your touch disturbs something in the binding. One soldier wrenches free of the ice and turns toward you — not with recognition, but with the automatic response of someone who has been on watch for ten thousand years.",
                    "karma": {"hell": 2}
                }
            },
            {
                "id": "pass",
                "type": "default",
                "text": "Take the ridge path to avoid the valley",
                "outcome": {
                    "type": "text",
                    "text": "You take the ridge path, skirting the valley. It costs you time.\n\nAt the far end, you glance back. Ten thousand frozen soldiers stand in perfect formation below, waiting for a war that ended without them.\n\nYou walk on.",
                    "karma": {"human": 1}
                }
            }
        ]
    },
    "hell_pyromancer_duel": {
        "id": "hell_pyromancer_duel",
        "title": "The Pyromancer's Challenge",
        "realm": "hell",
        "text": "A human mage in scorched red robes blocks the path, orbiting flames circling her like planets. The dueling scar on her cheek is self-inflicted — a mark made deliberately. She examines you with professional interest.\n\n'You move like a magic user. I can always tell. I've been here forty years and no one's given me a real fight. You interested?'\n\nBehind her, the path continues.",
        "choices": [
            {
                "id": "duel",
                "type": "requirement",
                "text": "Accept the fire duel",
                "requirements": {"skills": {"fire_magic": 1}},
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "normal",
                    "text": "She smiles for the first time and takes a stance. 'Honorable rules. No killing blows. First to yield.' The orbiting flames spin faster.",
                    "rewards": {"xp": 10},
                    "karma": {"asura": 5, "human": 3}
                }
            },
            {
                "id": "counter",
                "type": "requirement",
                "text": "Answer fire with wind magic",
                "requirements": {"skills": {"air_magic": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You raise a hand and let wind answer her fire. The two forces meet between you — not combat, but dialogue. Fire reaches. Wind redirects. Fire presses. Wind opens.\n\nShe holds this for a long moment, then lowers her hands.\n\n'Huh. I've never had someone answer fire with wind before.' She considers. 'That's actually better. You're teaching me something.' She steps aside and demonstrates a technique for sealing fire before she lets you pass.",
                    "rewards": {"xp": 12},
                    "karma": {"asura": 3, "human": 5}
                }
            },
            {
                "id": "listen",
                "type": "requirement",
                "text": "Ask why she has been here for forty years",
                "requirements": {"skills": {"persuasion": 2}},
                "outcome": {
                    "type": "text",
                    "text": "The orbiting flames slow. Something in her expression shifts from challenge to something older.\n\n'I came looking for my student,' she says. 'He made bad choices. He ended up here. I found his ghost eventually. Spent ten years helping him move on.' A pause. 'He did, in the end. But I stayed. I thought I owed this place something.' She looks at the path behind her. 'I'm not sure that's true anymore.'\n\nShe steps aside without being asked. Her flames continue their orbit, but slower — more contemplative than aggressive.",
                    "rewards": {"xp": 8},
                    "karma": {"human": 5, "god": 3, "hell": -3}
                }
            },
            {
                "id": "decline",
                "type": "default",
                "text": "Decline and find another way around",
                "outcome": {
                    "type": "text",
                    "text": "She watches you find the path around with the measured disappointment of someone who has been doing this for a long time and has learned not to expect much.\n\n'Fair enough,' she says. The orbiting flames resume their patient circuit. She settles in to wait for the next traveler.",
                    "karma": {"human": 1}
                }
            }
        ]
    },
    "hell_demon_marketplace": {
        "id": "hell_demon_marketplace",
        "title": "The Demon Marketplace",
        "realm": "hell",
        "text": "A chaotic bazaar has assembled in the middle of the lava fields — dozens of stalls selling weapons, memories, bottled emotions, demon-forged equipment, and items you cannot categorize. The merchants are a mix of demons, damned souls, and creatures that do not appear to belong to any known category.\n\nA sign over the entrance reads: NO FIGHTING. NO UNAUTHORIZED FIRE (the sign is on fire). NO RETURNS.\n\nThe noise is extraordinary.",
        "choices": [
            {
                "id": "browse",
                "type": "default",
                "text": "Browse the marketplace stalls",
                "outcome": {
                    "type": "shop",
                    "shop_id": "ember_merchant",
                    "text": "You move through the stalls, shoulder to shoulder with demons and the damned alike. It is, despite everything, a marketplace — and there is something almost comforting about the familiar rhythms of commerce.",
                    "rewards": {"xp": 2},
                    "karma": {"human": 2, "hungry_ghost": 1}
                }
            },
            {
                "id": "trade_expert",
                "type": "requirement",
                "text": "Seek out the best deals with expert knowledge",
                "requirements": {"skills": {"trade": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You spend an hour working the stalls with professional efficiency — checking quality, testing weights, haggling at the right moments. You find a stall in the back that others seem to avoid, its proprietor a very old demon sitting behind a display of items none of the other merchants will look at directly.\n\n'Good eye,' the demon says. 'The things nobody wants are often the things someone needs.' The prices are fair. The goods are unusual.",
                    "rewards": {"xp": 8, "items": ["fire_crystal"]},
                    "karma": {"human": 3}
                }
            },
            {
                "id": "back_alley",
                "type": "requirement",
                "text": "Find the restricted goods in the back alleys",
                "requirements": {"skills": {"guile": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You find the alley behind the main stalls where the less official commerce happens. A hooded demon with careful eyes offers things the main market won't stock — items with complicated histories, scrolls from restricted collections, objects whose provenance cannot be confirmed.\n\nYou leave with a scroll and a sense of mild unease.",
                    "rewards": {"xp": 6, "items": ["scroll_firebolt"]},
                    "karma": {"hungry_ghost": 4, "hell": 2}
                }
            },
            {
                "id": "watch",
                "type": "default",
                "text": "Watch the crowds instead of buying",
                "outcome": {
                    "type": "text",
                    "text": "You find a good position and spend an hour simply watching.\n\nThree deals go wrong in interesting ways. Two go surprisingly right — a demon and a damned soul find they both want what the other has, and part looking pleased. A woman in grey robes stands before a stall selling memory-jars, reading the labels, and cries quietly in front of one that says: 'Tuesday, Age 7.'\n\nShe doesn't buy it. Neither would you.",
                    "rewards": {"xp": 4},
                    "karma": {"human": 3}
                }
            }
        ]
    },
    "hell_burning_library": {
        "id": "hell_burning_library",
        "title": "The Burning Library",
        "realm": "hell",
        "text": "A library is on fire.\n\nNot metaphorically — the entire building is actively burning, shelves collapsing, books falling in cascades of sparks. But at the center, visible through the inferno, an enormous bookshelf stands intact, its contents still whole.\n\nThe fire has been burning long enough that the outer walls have almost collapsed. It will reach the center shelf soon.",
        "choices": [
            {
                "id": "brave",
                "type": "roll",
                "text": "Dash through the flames to save what you can",
                "requirements": {"roll": {"attribute": "constitution", "difficulty": 13}},
                "outcome_success": {
                    "type": "text",
                    "text": "You cover your head and run. The heat is enormous. You reach the center shelf, grab armfuls without looking, and sprint back as a beam comes down behind you.\n\nSinged, coughing, but standing. In your arms: books that are ancient and intact and unlike anything you have seen before. You have no idea what language they are in. That feels like a problem for later.",
                    "rewards": {"xp": 10, "items": ["scroll_firebolt", "scroll_lesser_heal"]},
                    "karma": {"human": 4}
                },
                "outcome_failure": {
                    "type": "text",
                    "text": "The heat drives you back before you reach the center. You grab one book from shelves near the entrance — old, smoke-damaged, but intact — before the entrance collapses.\n\nYou stand outside, coughing, clutching a book you saved. The center shelf burns.",
                    "rewards": {"xp": 5, "items": ["scroll_lesser_heal"]},
                    "karma": {"human": 2, "animal": 2}
                }
            },
            {
                "id": "fire_magic",
                "type": "requirement",
                "text": "Command the flames to clear a path",
                "requirements": {"skills": {"fire_magic": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You reach into the fire and speak to it. It takes a moment — the fire here is old and set in its ways — but it responds. A corridor of cooler air opens before you, the flames pulling back on either side.\n\nYou walk to the center shelf calmly and take your time selecting. The books feel important in a way you cannot explain. You exit as the building finally collapses behind you in a controlled exhale.",
                    "rewards": {"xp": 14, "items": ["scroll_firebolt", "mana_potion"]},
                    "karma": {"human": 5, "asura": 3}
                }
            },
            {
                "id": "rescue",
                "type": "default",
                "text": "Shout to see if anyone is still inside",
                "outcome": {
                    "type": "text",
                    "text": "You cup your hands and call into the flames.\n\nSilence. Then: a cough. Then a small demon emerges from behind a burning pillar, clutching a ledger to its chest with both arms, absolutely refusing to put it down despite the circumstances.\n\nYou pull it out by the collar. It stands outside looking humiliated — not by the rescue, but by the fact that it needed one.\n\n'The accounts,' it says, still holding the ledger. 'I couldn't leave the accounts.' It presses a key into your hands. 'For an archive in the eastern quarter. Everything there is in order too. In case anyone asks.' It walks away with dignity it has not entirely earned.",
                    "rewards": {"xp": 8, "items": ["demon_key"]},
                    "karma": {"hell": -5, "human": 8, "god": 3}
                }
            },
            {
                "id": "witness",
                "type": "default",
                "text": "Stand and witness the burning",
                "outcome": {
                    "type": "text",
                    "text": "You stand in the heat and watch the library burn.\n\nAt a certain point, the center shelf goes. The books go last — their pages lifting in the updraft, briefly bright, then dark.\n\nSomething is lost. And yet, watching it, you also feel something like release — as though the books were finished being books and have become something else instead.\n\nYou are not sure this is a useful thought. But it is the thought you have.",
                    "rewards": {"xp": 3},
                    "karma": {"human": 2}
                }
            }
        ]
    },
    "hell_sinner_gang": {
        "id": "hell_sinner_gang",
        "title": "The Sinner Gang",
        "realm": "hell",
        "text": "A group of damned souls has made camp around a fire — not for warmth, none of them need warmth, but for the feeling of it. A former soldier, a tax collector, an artist, a merchant. They've made rules, share what they find, keep watch in shifts. It is, against all odds, working.\n\nOne of them looks up as you approach.\n\n'You're alive. Actual living. We don't get many of those.' A pause. 'Sit down. We're not going to hurt you.'",
        "choices": [
            {
                "id": "stories",
                "type": "default",
                "text": "Share a meal and hear their stories",
                "outcome": {
                    "type": "text",
                    "text": "You sit with them and the stories come out — what they did, what they understand now about what they did, what they are still working out.\n\nThe soldier burned a village on orders. The tax collector took more than was owed, always. The artist spent a life accepting credit for other people's work. The merchant let a business partner take the fall for a shared crime.\n\nNone of them are done yet. But they are thinking clearly about it, which is more than many here manage. You leave feeling, strangely, less alone.",
                    "rewards": {"xp": 8},
                    "karma": {"human": 5, "hell": -3}
                }
            },
            {
                "id": "trade",
                "type": "default",
                "text": "Trade supplies with them",
                "outcome": {
                    "type": "text",
                    "text": "They have things scavenged from wandering souls — small items, coins, a potion someone dropped. You have things from the living world. You trade fairly, taking what you need, giving what you can spare.\n\nThe merchant among them negotiates with professional precision, which makes everyone laugh, including the merchant. 'Habits,' they say. 'Even here.'",
                    "rewards": {"xp": 4, "items": ["health_potion"]},
                    "karma": {"human": 3}
                }
            },
            {
                "id": "inspire",
                "type": "requirement",
                "text": "Inspire them to give their suffering more purpose",
                "requirements": {"skills": {"persuasion": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You talk to them for a long time — about suffering as instruction, about the difference between enduring and understanding, about what it would mean to actively help other souls in the hell realm rather than simply outlasting it.\n\nThe words land differently here than they would in the living world. One of them begins to cry. Another says quietly, 'We could actually do something with our time here.'\n\nWhen you leave, they are still talking. Their camp looks like the beginning of something.",
                    "rewards": {"xp": 12},
                    "karma": {"human": 6, "god": 4, "hell": -5}
                }
            },
            {
                "id": "observe",
                "type": "default",
                "text": "Watch from a distance without disturbing them",
                "outcome": {
                    "type": "text",
                    "text": "You stop on the ridge above their camp and watch for a while. The fire. The four figures around it. The quiet conversation.\n\nOne of them looks up and sees you. They raise a hand. You raise yours. They return to their conversation.\n\nThat is enough, somehow. For both of you.",
                    "rewards": {"xp": 2},
                    "karma": {"human": 2}
                }
            }
        ]
    },
    "hell_forge_spirit": {
        "id": "hell_forge_spirit",
        "title": "The Forge Spirit",
        "realm": "hell",
        "text": "An abandoned forge still glows with ancient heat — the fire here has not gone out in centuries. A translucent figure works the bellows with practiced rhythm, hammer rising and falling on metal that is not there. She died here, or near here, long enough ago that the distinction no longer matters.\n\nShe stops as you approach. Looks at you with the focused attention of someone who has not had company in a very long time.\n\n'Oh. A visitor. Forgive me — I lose track of... everything. What day is it?'",
        "choices": [
            {
                "id": "tell_news",
                "type": "default",
                "text": "Tell her what you know of the current state of the realm",
                "outcome": {
                    "type": "text",
                    "text": "You tell her what you know — the demon patrols, the lava flows, the frozen north, Yama's lieutenant at the gate. Each piece of information she processes slowly, turning it over.\n\n'Still going, then. The realm.' She resumes the rhythm of the bellows. 'I wasn't sure.'\n\nThen she stops again. 'Thank you. No one has told me anything in... I genuinely don't know how long. You forget there is news to be had.' She works the bellows harder, as though the information has given her energy.",
                    "rewards": {"xp": 5},
                    "karma": {"human": 4, "god": 2}
                }
            },
            {
                "id": "peace",
                "type": "requirement",
                "text": "Help her find the peace she is missing",
                "requirements": {"skills": {"white_magic": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You spend a long time speaking with her — about what she made, who she made it for, what she was working toward when she died. The hammer and bellows slow and finally stop.\n\n'I kept thinking there was one more thing to finish,' she says. 'But it was already finished. I just didn't see it.'\n\nShe looks up and goes very still. 'Oh,' she says. 'There it is. I've been looking right at it.' And then she is simply gone — not destroyed, but complete. On the forge floor, her tools have become solid. Real. Apparently hers to leave behind.",
                    "rewards": {"xp": 14, "items": ["fire_crystal"]},
                    "karma": {"god": 8, "hell": -8, "human": 5}
                }
            },
            {
                "id": "learn",
                "type": "requirement",
                "text": "Ask to learn her craft techniques",
                "requirements": {"skills": {"crafting": 2}},
                "outcome": {
                    "type": "text",
                    "text": "She teaches. Ancient methods — based on relationship with material rather than mastery over it. She shows you how to hear what a metal wants to become before you force it into a shape.\n\nYour hands seem to remember what your mind cannot quite hold. You leave with something that feels less like knowledge and more like patience.",
                    "rewards": {"xp": 10},
                    "karma": {"human": 4, "asura": 3}
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave the spirit to her work",
                "outcome": {
                    "type": "text",
                    "text": "You bow at the entrance to the forge. She does not look up, but the rhythm of the hammer changes briefly — a different beat, just for a moment — before returning to its ancient pattern.\n\nA greeting, in the only language available.",
                    "rewards": {"xp": 2},
                    "karma": {"human": 1}
                }
            }
        ]
    },
    "hell_the_invitation": {
        "id": "hell_the_invitation",
        "title": "The Invitation",
        "realm": "hell",
        "text": "An ornate envelope rests on a flat rock in the middle of a lava field, as though placed there deliberately. It is sealed with black wax. Your name is written on the outside — not the name you are using in this life, but a name you know with absolute certainty is yours.\n\nThe handwriting is beautiful.\n\nInside: a map, a time, an address, and the words: 'It would please us greatly if you would attend. We have matters of mutual interest to discuss. Come alone.'",
        "choices": [
            {
                "id": "follow",
                "type": "default",
                "text": "Follow the map",
                "outcome": {
                    "type": "text",
                    "text": "The address leads to a formal dining room carved from black obsidian, lit by candles burning with a clean blue flame. A demon of apparent authority waits at the head of a long table — well-dressed, patient, carrying the specific stillness of someone who has planned this meeting carefully.\n\n'We have been observing your journey,' it says. 'With interest. There is a matter we would like to discuss — something that would benefit both of us, if we can reach an agreement.'\n\nThe conversation that follows is careful and illuminating. You learn things about the hell realm you did not know. You also decline the offer, politely, when it finally arrives.\n\n'The offer stands,' the demon says as you leave. 'When you change your mind, you'll know how to reach us.' It does not say if.\n\nYou notice, on the way out, that there is only one setting at the table. They knew you'd come alone.",
                    "rewards": {"xp": 10},
                    "karma": {"asura": 3, "hungry_ghost": 2, "human": 2}
                }
            },
            {
                "id": "arrive_early",
                "type": "requirement",
                "text": "Follow the map but arrive early and observe first",
                "requirements": {"skills": {"guile": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You find the address an hour before the appointed time and settle in a position with a clear view of the entrance.\n\nSomeone else has already arrived — a damned soul, young, with the hollow eyes of someone who has been suffering long enough to consider anything an improvement. They go inside. Through the wall (obsidian is surprisingly thin) you can hear the shape of the conversation without the words.\n\nA deal is being made. The soul wants something specific. The demon is offering it.\n\nYou could intervene. You could also let them make their own choice — the soul is old enough to know what they're doing, even here.\n\nYou wait until the soul emerges — lighter, in some way you cannot verify — then slip away before your own appointment time.",
                    "rewards": {"xp": 8},
                    "karma": {"human": 3}
                }
            },
            {
                "id": "examine",
                "type": "requirement",
                "text": "Examine the invitation for hidden enchantments",
                "requirements": {"skills": {"black_magic": 2}},
                "outcome": {
                    "type": "text",
                    "text": "You read the letter carefully with trained attention to what is not there.\n\nThree layers of enchantment. The first: a location beacon — someone has already noted that the invitation was opened. The second: a subtle compulsion toward compliance, minor enough to be deniable. The third: something you cannot fully name but that feels, precisely and strangely, like recognition — as though whoever wrote this has seen you before, in a context you cannot access.\n\nYou burn the invitation. For a moment you feel watched from a very specific direction. Then nothing.\n\nThe name they used for you, you will be thinking about for a while.",
                    "rewards": {"xp": 10},
                    "karma": {"human": 3, "hungry_ghost": 2}
                }
            },
            {
                "id": "ignore",
                "type": "default",
                "text": "Set it back on the rock and walk on",
                "outcome": {
                    "type": "text",
                    "text": "You set the envelope back on the rock and continue on your way.\n\nBehind you, the envelope waits. A faint sense of disappointment from a specific direction — calm, professional, patient. The kind of disappointment that is already adjusting its timeline.\n\nSomeday, you think, you will want to know what was in that letter.",
                    "rewards": {"xp": 3},
                    "karma": {"human": 2}
                }
            }
        ]
    }
}

with open(PATH, 'r') as f:
    data = json.load(f)

existing = set(data["events"].keys())
added = []
for k, v in NEW_EVENTS.items():
    if k not in existing:
        data["events"][k] = v
        added.append(k)
    else:
        print(f"  SKIP (already exists): {k}")

with open(PATH, 'w') as f:
    json.dump(data, f, indent='\t', ensure_ascii=False)
    f.write('\n')

print(f"Done. Added {len(added)} events: {added}")
print(f"Total events: {len(data['events'])}")
