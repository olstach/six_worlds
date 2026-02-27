#!/usr/bin/env python3
"""Update cold hell events with revised writing and mechanics."""
import json
import os

EVENTS_FILE = os.path.join(os.path.dirname(__file__), "..", "resources", "data", "events", "hell_events.json")

# All updated cold hell events + fixed landmarks
UPDATED_EVENTS = {
    # ===== FIXED LANDMARKS =====
    "hell_lava_guardian": {
        "id": "hell_lava_guardian",
        "title": "Lava Guardian",
        "realm": "hell",
        "text": "A massive elemental of molten rock blocks the passage between the ice fields and the volcanic badlands. Heat radiates from it in waves, melting the frost for meters around. It speaks with a voice of grinding stone.\n\n\"NONE SHALL PASS between the realms of fire and ice. This has been the law for beginningless aeons. Prove your worth or be consumed.\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Attack the guardian head-on",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "lava_guardian",
                    "difficulty": "hard",
                    "karma": {
                        "asura": 3,
                        "hell": 2
                    }
                }
            },
            {
                "id": "duel",
                "type": "requirement",
                "text": "Challenge it to an honorable single combat",
                "requirements": {
                    "skills": {
                        "martial_arts": 3
                    }
                },
                "outcome": {
                    "type": "combat",
                    "enemy_group": "lava_guardian",
                    "difficulty": "normal",
                    "text": "It fights fairly, with reduced ferocity.",
                    "karma": {
                        "asura": 5,
                        "human": 2
                    }
                }
            },
            {
                "id": "find_path",
                "type": "roll",
                "text": "Search for an alternate route",
                "requirements": {
                    "roll": {
                        "attribute": "awareness",
                        "difficulty": 15
                    }
                },
                "outcome_success": {
                    "type": "text",
                    "text": "You find a hidden passage and discover a charm left by a previous traveler.",
                    "rewards": {
                        "xp": 10,
                        "items": [
                            "fire_resistance_charm"
                        ]
                    },
                    "karma": {
                        "animal": 3,
                        "human": 2
                    }
                },
                "outcome_failure": {
                    "type": "combat",
                    "enemy_group": "lava_guardian",
                    "difficulty": "hard",
                    "text": "Spotted! The guardian attacks.",
                    "karma": {
                        "hell": 3
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Sit before it in meditation",
                "requirements": {
                    "skills": {
                        "yoga": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Hours pass; the guardian recognizes your understanding and silently steps aside.",
                    "rewards": {
                        "xp": 15
                    },
                    "karma": {
                        "god": 5,
                        "human": 5,
                        "hell": -5
                    }
                }
            }
        ]
    },

    "hell_boss_yama_lt": {
        "id": "hell_boss_yama_lt",
        "title": "Yama's Lieutenant",
        "realm": "hell",
        "text": "A towering demon in ornate black and gold armor stands before the Realm Gate. Its four arms hold different weapons \u2014 sword, mace, spear, and a mirror that shows nothing.\n\n\"I am Chitragupta, Lieutenant of Yama, Lord of Death. I have judged every soul that passes through this gate. Tell me, mortal \u2014 do you believe your deeds merit passage?\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Draw your weapon and fight for passage",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "yama_lieutenant",
                    "difficulty": "boss",
                    "karma": {
                        "hell": 5,
                        "asura": 5
                    }
                }
            },
            {
                "id": "plead",
                "type": "requirement",
                "text": "Present your case with eloquent argument",
                "requirements": {
                    "skills": {
                        "persuasion": 3
                    }
                },
                "outcome": {
                    "type": "combat",
                    "text": "It listens, lowers two weapons, giving you a fair chance.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "human": 5,
                        "god": 3
                    },
                    "enemy_group": "yama_lieutenant_weakened",
                    "difficulty": "normal"
                }
            },
            {
                "id": "confess",
                "type": "default",
                "text": "Confess your doubts honestly",
                "outcome": {
                    "type": "combat",
                    "text": "Honesty impresses him, reduced ferocity.",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "human": 5,
                        "god": 5,
                        "hell": -5
                    },
                    "enemy_group": "yama_lieutenant_weakened",
                    "difficulty": "normal"
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Sit before the gate and meditate on the nature of death",
                "requirements": {
                    "skills": {
                        "yoga": 5
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Hours dissolve into the earth, days dissolve into the sky, finally the boundary dissolves into space.",
                    "rewards": {
                        "xp": 20
                    },
                    "karma": {
                        "god": 10,
                        "human": 5,
                        "hell": -10
                    }
                }
            }
        ]
    },

    # ===== COLD HELL - EVENT POOL =====
    "hell_demon_patrol": {
        "id": "hell_demon_patrol",
        "title": "Demon Patrol",
        "realm": "hell",
        "text": "Three demons in frost-crusted armor block the path ahead. Their captain, a horned brute with blue-black skin, raises a jagged halberd.\n\n\"No one passes without the Warden's permission. State your business or prepare to suffer.\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Draw your weapon and attack",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "hard",
                    "karma": {
                        "hell": 3,
                        "asura": 2
                    }
                }
            },
            {
                "id": "negotiate",
                "type": "requirement",
                "text": "Convince them you serve the Warden",
                "requirements": {
                    "attributes": {
                        "charm": 15
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "\"Well, if you say so.\"",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "hungry_ghost": 2,
                        "human": 3
                    }
                }
            },
            {
                "id": "sneak",
                "type": "roll",
                "text": "Throw a bag of gold and slip past while they argue amongst themselves",
                "requirements": {
                    "roll": {
                        "attribute": "finesse",
                        "difficulty": 14
                    }
                },
                "cost": {
                    "gold": "small"
                },
                "outcome_success": {
                    "type": "text",
                    "text": "Maybe sometimes it's true that greed is good.",
                    "rewards": {
                        "xp": 6
                    },
                    "karma": {
                        "animal": 3,
                        "human": 2
                    }
                },
                "outcome_failure": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "text": "They look on you with confused pity and draw their weapons.",
                    "karma": {
                        "hell": 5
                    },
                    "difficulty": "hard"
                }
            },
            {
                "id": "bribe",
                "type": "default",
                "text": "Offer them gold to look the other way",
                "cost": {
                    "gold": "moderate"
                },
                "outcome": {
                    "type": "text",
                    "text": "They quickly pocket the gold and step aside.",
                    "rewards": {
                        "xp": 3
                    },
                    "karma": {
                        "hungry_ghost": 5,
                        "human": 2
                    }
                }
            }
        ]
    },

    "hell_ice_spirits": {
        "id": "hell_ice_spirits",
        "title": "Ice Spirits",
        "realm": "hell",
        "text": "Translucent figures drift above the frozen surface of a vast lake. Their forms shimmer, beautiful and terrible, trapped in an eternal dance. One turns toward you, its hollow eyes filled with sorrow.\n\n\"Do not disturb those dreaming below.\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Force your way through",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "ice_spirits",
                    "difficulty": "hard",
                    "karma": {
                        "hell": 5,
                        "asura": 3
                    }
                }
            },
            {
                "id": "ice_magic",
                "type": "requirement",
                "text": "Speak to them in the language of water and cold",
                "requirements": {
                    "skills": {
                        "water_magic": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "They recognize a kindred soul and part. Before you leave, the lead spirit shoves an ice shard in your hand.",
                    "rewards": {
                        "xp": 10,
                        "items": [
                            "ice_shard"
                        ]
                    },
                    "karma": {
                        "god": 3,
                        "human": 2
                    }
                }
            },
            {
                "id": "commune",
                "type": "requirement",
                "text": "Sit in meditation and commune with the spirits",
                "requirements": {
                    "skills": {
                        "yoga": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Through stillness you glimpse their memories. They become transparent and vanish into the cold mist.",
                    "rewards": {
                        "xp": 12
                    },
                    "karma": {
                        "god": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "offering",
                "type": "default",
                "text": "Leave an offering at the lake's edge and pray",
                "outcome": {
                    "type": "text",
                    "text": "One spirit touches your forehead: a sensation of cold so deep it becomes warm. They part and let you through.",
                    "rewards": {
                        "xp": 5
                    },
                    "karma": {
                        "god": 4,
                        "human": 2,
                        "hell": -3
                    }
                }
            }
        ]
    },

    "hell_frozen_merchant": {
        "id": "hell_frozen_merchant",
        "title": "Frozen Merchant",
        "realm": "hell",
        "text": "A bundled figure huddles near a sputtering fire, surrounded by tattered bags. Despite the brutal cold, the merchant seems oddly cheerful.\n\n\"Welcome, welcome! Don't mind the cold \u2014 it keeps the thieves away! I've got everything a traveler needs to survive this frozen wasteland. Well, almost everything.\"",
        "choices": [
            {
                "id": "browse",
                "type": "default",
                "text": "Browse the merchant's wares",
                "outcome": {
                    "type": "shop",
                    "shop_id": "frozen_merchant",
                    "karma": {
                        "human": 1
                    }
                }
            },
            {
                "id": "haggle",
                "type": "requirement",
                "text": "Try to negotiate better prices",
                "requirements": {
                    "skills": {
                        "trade": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "The merchant nods his head, impressed.",
                    "rewards": {
                        "xp": 5,
                        "items": [
                            "health_potion"
                        ]
                    },
                    "karma": {
                        "human": 3
                    }
                }
            },
            {
                "id": "chat",
                "type": "default",
                "text": "Ask about the region",
                "outcome": {
                    "type": "text",
                    "text": "He warns you about ice wraiths, the Lava Guardian, and Yama's lieutenant standing guard in the far south.",
                    "rewards": {
                        "xp": 2
                    },
                    "karma": {
                        "human": 1
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Move on",
                "outcome": {
                    "type": "text",
                    "text": "\"Safe travels! Try not to freeze!\"",
                    "karma": {}
                }
            }
        ]
    },

    "hell_lost_wanderer": {
        "id": "hell_lost_wanderer",
        "title": "Lost Wanderer",
        "realm": "hell",
        "text": "A shivering figure huddles by the roadside, barely conscious. Their robes are torn and frostbitten skin shows through.\n\n\"Please... I've been wandering for so long. I can't feel my hands anymore. Is this... is this what I deserve?\"",
        "choices": [
            {
                "id": "heal",
                "type": "requirement",
                "text": "Tend to their wounds",
                "requirements": {
                    "skills": {
                        "medicine": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Color returns to their face. When you rise to leave, they press a mala into your hands.",
                    "rewards": {
                        "xp": 8,
                        "items": [
                            "prayer_beads"
                        ]
                    },
                    "karma": {
                        "hell": -5,
                        "human": 5,
                        "god": 3
                    }
                }
            },
            {
                "id": "give_gold",
                "type": "default",
                "text": "Give them some gold and food",
                "cost": {
                    "gold_and_food": "some"
                },
                "outcome": {
                    "type": "text",
                    "text": "They weep with gratitude, whispering memories of hoarding wealth while others starved.",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "hell": -3,
                        "human": 4,
                        "god": 2
                    }
                }
            },
            {
                "id": "ask_story",
                "type": "default",
                "text": "Ask how they came to be here",
                "outcome": {
                    "type": "text",
                    "text": "They were a tax collector. Now they better understand their victims' suffering.",
                    "rewards": {
                        "xp": 3
                    },
                    "karma": {
                        "human": 3
                    }
                }
            },
            {
                "id": "ignore",
                "type": "default",
                "text": "Walk past without stopping",
                "outcome": {
                    "type": "text",
                    "text": "They watch you go in silence; the cold feels a little sharper.",
                    "karma": {
                        "hell": 2,
                        "animal": 2
                    }
                }
            }
        ]
    },

    "hell_frozen_cave": {
        "id": "hell_frozen_cave",
        "title": "Frozen Cave",
        "realm": "hell",
        "text": "A dark cave rimmed with glittering ice crystals yawns in the hillside like a great mouth. From deep within comes a faint glow and the distant sound of dripping water \u2014 warm water, impossibly, in this frozen waste.",
        "choices": [
            {
                "id": "enter",
                "type": "roll",
                "text": "Enter the cave carefully",
                "requirements": {
                    "roll": {
                        "attribute": "awareness",
                        "difficulty": 14
                    }
                },
                "outcome_success": {
                    "type": "text",
                    "text": "You spot the trap and walk around it. Soon you find a hidden chamber and leave with a couple potions.",
                    "rewards": {
                        "xp": 8,
                        "items": [
                            "health_potion",
                            "mana_potion"
                        ]
                    },
                    "karma": {
                        "human": 2
                    }
                },
                "outcome_failure": {
                    "type": "text",
                    "text": "You fall into a lower chamber, find a cache but take a knock.",
                    "rewards": {
                        "xp": 4,
                        "items": [
                            "health_potion"
                        ]
                    },
                    "karma": {
                        "animal": 2
                    }
                }
            },
            {
                "id": "study",
                "type": "requirement",
                "text": "Study the entrance carefully before entering",
                "requirements": {
                    "skills": {
                        "learning": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You notice a warning in old demon script among the scratch marks on the cave wall. Taking it to heart, you carefully descend into the cave along its left-hand wall and soon emerge back with loot.",
                    "rewards": {
                        "xp": 8,
                        "items": [
                            "health_potion",
                            "mana_potion"
                        ]
                    },
                    "karma": {
                        "human": 3
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "The cave looks dangerous \u2014 best to move on",
                "outcome": {
                    "type": "text",
                    "text": "Discretion is the better part of valor.",
                    "karma": {
                        "hungry_ghost": 1,
                        "animal": 1
                    }
                }
            }
        ]
    },

    "hell_tormented_soul": {
        "id": "hell_tormented_soul",
        "title": "Tormented Soul",
        "realm": "hell",
        "text": "A ghostly figure sits amid the frost, weeping silently. Unlike the mindless lost souls, this one retains its form \u2014 the shape of an old woman in tattered robes.\n\n\"Can you see me? Truly see me? So few can anymore...\"",
        "choices": [
            {
                "id": "help",
                "type": "requirement",
                "text": "Use white magic to ease her suffering",
                "requirements": {
                    "skills": {
                        "white_magic": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "She dissolves into light with a sigh. In life, she was a healer who once turned away a sick wanderer for a lack of payment.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "hell": -5,
                        "human": 3,
                        "god": 3
                    }
                }
            },
            {
                "id": "listen",
                "type": "default",
                "text": "Sit beside her and listen",
                "outcome": {
                    "type": "text",
                    "text": "She speaks of small cruelties compounded until her breath grows a little longer and slower.",
                    "rewards": {
                        "xp": 6
                    },
                    "karma": {
                        "human": 3,
                        "god": 2,
                        "hell": -3
                    }
                }
            },
            {
                "id": "exorcise",
                "type": "requirement",
                "text": "Perform a ritual to release her spirit",
                "requirements": {
                    "skills": {
                        "ritual": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You write a mandala of liberation by sight around her. She dissolves into light, leaving a piece of turquoise behind.",
                    "rewards": {
                        "xp": 12,
                        "items": [
                            "soul_stone"
                        ]
                    },
                    "karma": {
                        "hell": -10,
                        "god": 8,
                        "human": 3
                    }
                }
            },
            {
                "id": "ignore",
                "type": "default",
                "text": "Walk past \u2014 you have enough of your own problems",
                "outcome": {
                    "type": "text",
                    "text": "The weeping grows quieter, then stops. The cold deepens.",
                    "karma": {
                        "hell": 3,
                        "animal": 2
                    }
                }
            }
        ]
    },

    "hell_crossroads_shrine": {
        "id": "hell_crossroads_shrine",
        "title": "Crossroads Shrine",
        "realm": "hell",
        "text": "An ancient shrine sits where the roads cross, half-buried in snow and old offerings. Incense sticks still smolder in cracked holders, faded ribbons hang stiffly in the wind.",
        "choices": [
            {
                "id": "pray",
                "type": "default",
                "text": "Offer a prayer for safe passage",
                "outcome": {
                    "type": "text",
                    "text": "Incense flares briefly, your breath deepens.",
                    "rewards": {
                        "xp": 2
                    },
                    "karma": {
                        "god": 2,
                        "human": 2
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Meditate",
                "requirements": {
                    "skills": {
                        "yoga": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "The shrine seems to glow, a tiny lamp of Dharma lost among the wasteland.",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "god": 3,
                        "human": 2
                    }
                }
            },
            {
                "id": "offering",
                "type": "default",
                "text": "Leave a small offering",
                "cost": {
                    "gold": "small"
                },
                "outcome": {
                    "type": "text",
                    "text": "Your coins join dozens of others, united in the intent for a better world.",
                    "rewards": {
                        "xp": 2
                    },
                    "karma": {
                        "god": 3,
                        "hungry_ghost": -2,
                        "hell": -2
                    }
                }
            },
            {
                "id": "protection",
                "type": "requirement",
                "text": "Implore the shrine's guardians for protection",
                "requirements": {
                    "skills": {
                        "ritual": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Vows outlast bodies. The incense smoke briefly dances in the still air.",
                    "rewards": {
                        "xp": 4,
                        "buffs": [
                            {"stat": "constitution", "amount": 2, "combats_remaining": 1}
                        ]
                    },
                    "karma": {
                        "human": 3,
                        "god": 2
                    }
                }
            },
            {
                "id": "pass",
                "type": "default",
                "text": "Continue on your way",
                "outcome": {
                    "type": "text",
                    "text": "You nod respectfully and continue on your way.",
                    "karma": {}
                }
            }
        ]
    },

    "hell_ice_yogi": {
        "id": "hell_ice_yogi",
        "title": "Frozen Waterfall Yogi",
        "realm": "hell",
        "text": "Before a magnificent frozen waterfall, a yogi sits in stillness. Ice crystals have formed on their eyelashes and hair, icicles hang from their beard.",
        "choices": [
            {
                "id": "learn_water",
                "type": "requirement",
                "text": "Ask to learn water magic techniques",
                "requirements": {
                    "skills": {
                        "water_magic": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Hours pass until you notice the movement hidden in the stillness.",
                    "rewards": {
                        "xp": 5,
                        "skill_up": {"skill": "water_magic", "amount": 1, "cap": 6}
                    },
                    "karma": {
                        "god": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Meditate together on impermanence",
                "requirements": {
                    "skills": {
                        "yoga": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Time dissolves into the frozen cascades.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "god": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "observe",
                "type": "default",
                "text": "Watch the yogi's meditation in silence",
                "outcome": {
                    "type": "text",
                    "text": "The cold seems to lessen when you stop fighting it.",
                    "rewards": {
                        "xp": 5
                    },
                    "karma": {
                        "god": 2,
                        "human": 2
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave the yogi to their practice",
                "outcome": {
                    "type": "text",
                    "text": "You bow respectfully and depart.",
                    "karma": {
                        "human": 1
                    }
                }
            }
        ]
    },

    "hell_ancient_stupa": {
        "id": "hell_ancient_stupa",
        "title": "Ancient Stupa",
        "realm": "hell",
        "text": "A crumbling stupa rises from the snow, its dome still intact after countless ages. Tattered prayer flags still flutter from the crown, faded but unbroken. Mantras are carved into every stone.",
        "choices": [
            {
                "id": "circumambulate",
                "type": "default",
                "text": "Walk around it three times in devotion",
                "outcome": {
                    "type": "text",
                    "text": "As you circle it clockwise three times; the cold seems to lessen. You place a small offering at the base and leave.",
                    "rewards": {
                        "xp": 5
                    },
                    "karma": {
                        "god": 3,
                        "human": 3,
                        "hell": -3
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Meditate at the stupa's base",
                "requirements": {
                    "skills": {
                        "yoga": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Seeing the work of so many hands towards creating a better tomorrow fills you with determination.",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "god": 5,
                        "human": 3,
                        "hell": -3
                    }
                }
            },
            {
                "id": "study",
                "type": "requirement",
                "text": "Study the carved mantras closely",
                "requirements": {
                    "skills": {
                        "ritual": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You study the faded letters until they become clearer.",
                    "rewards": {
                        "xp": 6,
                        "learn_spell": {"school": "white_magic", "level_range": [1, 2]}
                    },
                    "karma": {
                        "god": 4,
                        "human": 3
                    }
                }
            },
            {
                "id": "leave_offering",
                "type": "default",
                "text": "Leave a small offering and move on",
                "cost": {
                    "gold": "small"
                },
                "outcome": {
                    "type": "text",
                    "text": "You leave a few coins. The flags flutter in farewell.",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "god": 2,
                        "human": 2,
                        "hell": -2
                    }
                }
            }
        ]
    },

    "hell_demon_checkpoint": {
        "id": "hell_demon_checkpoint",
        "title": "Demon Checkpoint",
        "realm": "hell",
        "text": "A wobbly table has been set up across the path. Behind it, a bureaucratic demon in a stained uniform holds a quill the size of a sword.\n\n\"Halt. Passage permit, please. Standard Form 7-B, the one authorizing inter-zone traversal for damned entities. You do have a Form 7-B, yes?\"\n\nYou do not have a Form 7-B. Form 7-B does not exist.",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Push past the checkpoint by force",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "normal",
                    "text": "The bureaucrat sounds a horn taken seemingly out of thin air.",
                    "karma": {
                        "asura": 2,
                        "hell": 2
                    }
                }
            },
            {
                "id": "forge",
                "type": "requirement",
                "text": "Produce a convincing-looking document",
                "requirements": {
                    "skills": {
                        "guile": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You manage to quickly fold some parchment into an official-looking shape; the demon examines it upside down with a bored expression and stamps it.",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "hungry_ghost": 2,
                        "human": 2
                    }
                }
            },
            {
                "id": "bribe",
                "type": "default",
                "text": "Slip the demon a bribe",
                "cost": {
                    "gold": "small_moderate"
                },
                "outcome": {
                    "type": "text",
                    "text": "Gold changes hands; \"Everything checks out. Move along.\"",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "hungry_ghost": 4,
                        "asura": 1
                    }
                }
            },
            {
                "id": "argue",
                "type": "requirement",
                "text": "Challenge the checkpoint's legal legitimacy",
                "requirements": {
                    "skills": {
                        "persuasion": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "A 40-minute forensic argument takes place. The bureaucrat is shaken and visibly tired. Finally, he waves you through, muttering to himself.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "human": 4,
                        "hell": -2
                    }
                }
            }
        ]
    },

    "hell_ice_oracle": {
        "id": "hell_ice_oracle",
        "title": "Ice Oracle",
        "realm": "hell",
        "text": "A figure is frozen solid inside a pillar of ice \u2014 upright, arms folded, expression serene. When you come near, you hear a strange voice from within your head:\n\n\"I have been here since time lost to memory. I have watched many pass through, time and time again. Ask, and I may answer.\"",
        "choices": [
            {
                "id": "ask_ahead",
                "type": "default",
                "text": "Ask what lies ahead on your path",
                "outcome": {
                    "type": "text",
                    "text": "\"Fear and hope, then hope and fear. Until one day the natural state blooms in your awareness, and you shall be free, as you always really were.\"",
                    "rewards": {
                        "xp": 6
                    },
                    "karma": {
                        "human": 3,
                        "god": 3
                    }
                }
            },
            {
                "id": "commune",
                "type": "requirement",
                "text": "Open your mind and commune with it directly",
                "requirements": {
                    "skills": {
                        "space_magic": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You sense countless centuries of sentient beings passing to and fro, their fears and small kindnesses. You settle in a deep clarity.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "god": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "ask_realm",
                "type": "requirement",
                "text": "Ask about the nature of this realm",
                "requirements": {
                    "attributes": {
                        "awareness": 15
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "\"This realm, like all realms, is a mirror.\"",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "god": 4,
                        "human": 4,
                        "hell": -3
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Thank it for its time and move on",
                "outcome": {
                    "type": "text",
                    "text": "\"Seek out situations to exercise compassion.\"",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "human": 1,
                        "god": 1
                    }
                }
            }
        ]
    },

    # ===== COLD HELL - MOB EVENTS =====
    "hell_hermit_monk": {
        "id": "hell_hermit_monk",
        "title": "Wandering Hermit",
        "realm": "hell",
        "text": "A weathered monk in tattered robes approaches, seemingly at peace despite the frozen wasteland. His eyes are bright and clear.\n\n\"Ah, hello. How rare to meet someone with open eyes.\"",
        "choices": [
            {
                "id": "teaching",
                "type": "requirement",
                "text": "Ask the monk for spiritual teaching",
                "requirements": {
                    "skills": {
                        "yoga": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "He teaches about suffering and its root, the poisons of ignorance, desire and aversion.",
                    "rewards": {
                        "xp": 4
                    },
                    "karma": {
                        "god": 5,
                        "human": 5
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Sit with him in meditation",
                "requirements": {
                    "skills": {
                        "yoga": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You sit in comfortable silence. Afterwards, you feel restored and somehow warmed.",
                    "rewards": {
                        "xp": 6,
                        "restore": {"hp_percent": 50, "mana_percent": 50}
                    },
                    "karma": {
                        "god": 3,
                        "human": 2
                    }
                }
            },
            {
                "id": "ask_karma",
                "type": "requirement",
                "text": "Ask about the workings of karma",
                "requirements": {
                    "attributes": {
                        "awareness": 16
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "\"Every action, word and thought creates ripples throughout the thousandfold universe.\"",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "human": 5,
                        "god": 3
                    }
                }
            },
            {
                "id": "move_on",
                "type": "default",
                "text": "Wish him well and continue on your journey",
                "outcome": {
                    "type": "text",
                    "text": "He bows slightly and walks away. You notice there are no footprints left in his path.",
                    "rewards": {
                        "xp": 2
                    },
                    "karma": {
                        "human": 1
                    }
                }
            }
        ]
    },

    "hell_wandering_peddler": {
        "id": "hell_wandering_peddler",
        "title": "Wandering Peddler",
        "realm": "hell",
        "text": "A hunched figure dragging a heavy sack waves you down.\n\n\"Psst! Traveler! You look like you could use some supplies. I've got just the things \u2014 all cleaned up nice.\"",
        "choices": [
            {
                "id": "browse",
                "type": "default",
                "text": "See what the peddler has to offer",
                "outcome": {
                    "type": "shop",
                    "shop_id": "wandering_peddler",
                    "karma": {
                        "human": 1
                    }
                }
            },
            {
                "id": "directions",
                "type": "default",
                "text": "Ask for directions and local knowledge",
                "outcome": {
                    "type": "text",
                    "text": "He starts talking a lot but making little sense. You catch bits and pieces about frozen ghosts on the lake, wandering monks and torture chambers.",
                    "rewards": {
                        "xp": 3
                    },
                    "karma": {
                        "human": 2
                    }
                }
            },
            {
                "id": "move_on",
                "type": "default",
                "text": "Decline politely and move on",
                "outcome": {
                    "type": "text",
                    "text": "\"Your loss! If you change your mind, I'll be around. I'm always around.\"",
                    "karma": {}
                }
            }
        ]
    },

    "hell_bone_arena": {
        "id": "hell_bone_arena",
        "title": "Bone Arena",
        "realm": "hell",
        "text": "A frozen pit ringed with bones rises from the wasteland \u2014 a combat arena, its tiers packed with demons howling for blood. Two poor souls fight below, stumbling with exhaustion.\n\nA massive gatekeeper blocks the exit path, grinning with entirely too many rows of teeth. \"Welcome, welcome! Do you come to bet or to fight?\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Step into the arena and fight",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "hard",
                    "karma": {
                        "hell": 2,
                        "asura": 5
                    },
                    "rewards": {
                        "gold_reward": "moderate"
                    }
                }
            },
            {
                "id": "challenge",
                "type": "requirement",
                "text": "Issue a formal challenge to the current champion",
                "requirements": {
                    "attributes": {
                        "strength": 15
                    }
                },
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_elite",
                    "difficulty": "hard",
                    "text": "The gatekeeper nods with respect and lets you in.",
                    "rewards": {
                        "xp": 12,
                        "gold_reward": "moderate",
                        "items": ["good_iron_weapon"]
                    },
                    "karma": {
                        "asura": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "narrate",
                "type": "requirement",
                "text": "Narrate the fight dramatically for the crowd",
                "requirements": {
                    "skills": {
                        "performance": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "The crowd shifts from baying for blood to hanging on your words; gatekeeper laughs hard enough to let you through without charging.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "asura": 2,
                        "human": 5
                    }
                }
            },
            {
                "id": "bet",
                "type": "default",
                "text": "Bet on one of the fighters",
                "cost": {
                    "gold": "moderate"
                },
                "outcome": {
                    "type": "text",
                    "text": "\"Sure, take a seat in the tiers.\"",
                    "rewards": {
                        "xp": 5,
                        "gamble": {"type": "gold", "win_chance": 0.5, "win_multiplier": 2}
                    },
                    "karma": {
                        "hell": 2,
                        "asura": 2,
                        "human": 2
                    }
                }
            }
        ]
    },

    "hell_suffering_sage": {
        "id": "hell_suffering_sage",
        "title": "Suffering Sage",
        "realm": "hell",
        "text": "A figure sits at the summit of a frozen ridge, encased in ice up to the neck \u2014 only their face remains free, eyes open and clear. The oldest devils have forgotten when he appeared. Their expression is that of endless patience. As you come closer, they open their eyes a little.",
        "choices": [
            {
                "id": "suffering",
                "type": "default",
                "text": "Ask about the nature of suffering",
                "outcome": {
                    "type": "text",
                    "text": "\"All suffering comes from resistance to what is. The cold is not suffering. The resistance to the cold is suffering.\"",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "god": 5,
                        "human": 3
                    }
                }
            },
            {
                "id": "meditate",
                "type": "requirement",
                "text": "Enter deep meditation to receive their teaching directly",
                "requirements": {
                    "skills": {
                        "yoga": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Shivering from the cold gives way to stillness and stillness to a direct transmission beyond words. You see the endless wheels of resistance and acceptance turning. They have been here for a long time, and yet a long time they will stay.",
                    "rewards": {
                        "xp": 12
                    },
                    "karma": {
                        "god": 7,
                        "human": 5,
                        "hell": -3
                    }
                }
            },
            {
                "id": "history",
                "type": "requirement",
                "text": "Ask about the history of this realm",
                "requirements": {
                    "skills": {
                        "learning": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "\"I was here when the realm was still young. The first being who entered was a judge convinced he attained true justice. He was here for a very long time.\"",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "god": 4,
                        "human": 4
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave them to their vigil",
                "outcome": {
                    "type": "text",
                    "text": "Their eyes close again.",
                    "karma": {
                        "human": 1
                    }
                }
            }
        ]
    },

    "hell_suspicious_gift": {
        "id": "hell_suspicious_gift",
        "title": "Suspicious Gift",
        "realm": "hell",
        "text": "A neatly wrapped package sits in the center of the path, as though placed deliberately. Red cloth, black cord. A tag: \"For whoever needs this most.\"\n\nThe package is warm to the touch. Nothing else in the cold hell is warm.",
        "choices": [
            {
                "id": "inspect",
                "type": "roll",
                "text": "Examine it carefully before opening",
                "requirements": {
                    "roll": {
                        "attribute": "awareness",
                        "difficulty": 13
                    }
                },
                "outcome_success": {
                    "type": "text",
                    "text": "Congratulations on your caution. The trap disarmed, you retrieve your loot safely.",
                    "rewards": {
                        "xp": 8,
                        "items": [
                            "health_potion"
                        ],
                        "gold": 40
                    },
                    "karma": {
                        "human": 2
                    }
                },
                "outcome_failure": {
                    "type": "text",
                    "text": "Triggered; theatrical but not lethal; package empty; a card: \"Better luck with the next one.\"",
                    "rewards": {
                        "xp": 3
                    },
                    "karma": {
                        "hell": 1,
                        "animal": 2
                    }
                }
            },
            {
                "id": "check_magic",
                "type": "requirement",
                "text": "Check it for traps with trained eyes",
                "requirements": {
                    "skills": {
                        "guile": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You find a magic seal and quickly scratch it until it's unrecognizable. The package opens cleanly with a health potion and some coins inside.",
                    "rewards": {
                        "xp": 6,
                        "items": [
                            "health_potion"
                        ],
                        "gold": 25
                    },
                    "karma": {
                        "human": 2
                    }
                }
            },
            {
                "id": "open",
                "type": "default",
                "text": "Open it with reckless optimism",
                "outcome": {
                    "type": "text",
                    "text": "A flash, a sound, blinding cold \u2014 then you're standing there holding a health potion and forty gold, entirely unharmed. Sometimes things are exactly what they appear to be.",
                    "rewards": {
                        "xp": 4,
                        "items": [
                            "health_potion"
                        ],
                        "gold": 40
                    },
                    "karma": {
                        "animal": 2,
                        "human": 1
                    }
                }
            },
            {
                "id": "leave",
                "type": "default",
                "text": "Leave it \u2014 gifts in hell are seldom genuine",
                "outcome": {
                    "type": "text",
                    "text": "You step around it cautiously; behind you, the package waits warm and patient.",
                    "karma": {
                        "animal": 1,
                        "human": 1
                    }
                }
            }
        ]
    },

    "hell_ice_demon_toll": {
        "id": "hell_ice_demon_toll",
        "title": "Ice Demon Toll",
        "realm": "hell",
        "text": "Three squat ice demons have stretched a chain across the path. The leader holds a sign reading \"TOLL \u2014 10 GOLD\" in letters of varying sizes.\n\n\"Passage fee. Standard Hell Traversal Rate, Section 7, Paragraph 4.\"\n\"There is no Section 7, Paragraph 4.\"\n\"For you there is.\"",
        "choices": [
            {
                "id": "fight",
                "type": "default",
                "text": "Refuse and fight your way through",
                "outcome": {
                    "type": "combat",
                    "enemy_group": "demon_patrol",
                    "difficulty": "normal",
                    "karma": {
                        "asura": 2,
                        "hell": 2
                    }
                }
            },
            {
                "id": "pay",
                "type": "default",
                "text": "Pay the toll and move on",
                "outcome": {
                    "type": "text",
                    "text": "The gold is counted with elaborate care, the chain unhurriedly unclipped. \"Watch out for the unofficial toll three roads further on \u2014 those ones are criminals.\"",
                    "rewards": {
                        "xp": 2
                    },
                    "karma": {
                        "hungry_ghost": 2
                    }
                }
            },
            {
                "id": "argue",
                "type": "requirement",
                "text": "Challenge the legal legitimacy of this checkpoint",
                "requirements": {
                    "skills": {
                        "guile": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "An argument ensues, moving from the absence of appropriate seals though three different handwritings on the sign, to suspicious provisions. Finally you hear: \"You can go. But only because we choose to be magnanimous.\"",
                    "rewards": {
                        "xp": 8
                    },
                    "karma": {
                        "human": 3,
                        "hell": -2
                    }
                }
            },
            {
                "id": "perform",
                "type": "requirement",
                "text": "Offer to pay in entertainment",
                "requirements": {
                    "skills": {
                        "performance": 1
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "The demons are transfixed, their leader applauding. One demon presses a coin into your hand: \"Best thing that's happened here in a century.\"",
                    "rewards": {
                        "xp": 5,
                        "gold": 5
                    },
                    "karma": {
                        "human": 3,
                        "asura": 2
                    }
                }
            }
        ]
    },

    "hell_cursed_pilgrim": {
        "id": "hell_cursed_pilgrim",
        "title": "Cursed Pilgrim",
        "realm": "hell",
        "text": "A person trudges forward pulling a massive stone block behind them, gouging a furrow in the frozen ground. They are making slow, painful progress.",
        "choices": [
            {
                "id": "break",
                "type": "requirement",
                "text": "Break the chain by brute force",
                "requirements": {
                    "attributes": {
                        "strength": 15
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "After a long struggle, a link in the chain shatters. The pilgrim sits down heavily and breathes, then presses a carved token into your hands: \"I had forgotten what it felt like to rest.\"",
                    "rewards": {
                        "xp": 12,
                        "items": [
                            "random_common_talisman"
                        ]
                    },
                    "karma": {
                        "hell": -8,
                        "human": 5,
                        "god": 5
                    }
                }
            },
            {
                "id": "examine",
                "type": "requirement",
                "text": "Examine the curse",
                "requirements": {
                    "skills": {
                        "black_magic": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You recognize a particular class of binding spells, resistant to direct force but vulnerable to patient unraveling from within. Once you explain it to the pilgrim you see a glimmer of hope in their eyes. \"So there is a way!\"",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "human": 4,
                        "hell": -3
                    }
                }
            },
            {
                "id": "walk",
                "type": "default",
                "text": "Walk with them a while and listen",
                "outcome": {
                    "type": "text",
                    "text": "You hear a story of a deal with the devil. \"I thought I was clever. I had found the loophole. The one it wanted me to find, unfortunately.\" You walk together for a while and leave them with a faint feeling of relief.",
                    "rewards": {
                        "xp": 5
                    },
                    "karma": {
                        "human": 4,
                        "hell": -2
                    }
                }
            },
            {
                "id": "attempt_help",
                "type": "default",
                "text": "Try to help break the chain",
                "outcome": {
                    "type": "text",
                    "text": "You try everything, but the chain remains indifferent. The pilgrim watches with tired gratitude. Their goodbye handshake is stronger than you expected.",
                    "rewards": {
                        "xp": 3
                    },
                    "karma": {
                        "human": 3,
                        "hell": -1
                    }
                }
            }
        ]
    },

    "hell_frozen_army": {
        "id": "hell_frozen_army",
        "title": "Frozen Army",
        "realm": "hell",
        "text": "The valley below is filled with an army, frozen mid-march \u2014 thousands of soldiers preserved in ice, banners still flying. The armor is from no civilization you recognize. They are marching toward something that is no longer there.\n\nThey look like they are waiting.",
        "choices": [
            {
                "id": "respect",
                "type": "default",
                "text": "Pay your respects to the fallen",
                "outcome": {
                    "type": "text",
                    "text": "You stand at the valley's edge and bow. Barely perceptible: in the front rank, a soldier's hand tightens slightly on their weapon.",
                    "rewards": {
                        "xp": 5
                    },
                    "karma": {
                        "human": 3,
                        "god": 2
                    }
                }
            },
            {
                "id": "study",
                "type": "requirement",
                "text": "Study the banners and try to identify them",
                "requirements": {
                    "skills": {
                        "learning": 2
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "Sun bisected by a spear; armor wrong for any hell-native force. These were mortals who marched here deliberately to rescue someone. They were winning; then stopped. You leave with a feeling of grief without closure.",
                    "rewards": {
                        "xp": 10
                    },
                    "karma": {
                        "human": 5,
                        "god": 3,
                        "hell": -2
                    }
                }
            },
            {
                "id": "release",
                "type": "requirement",
                "text": "Search for a way to end their vigil",
                "requirements": {
                    "skills": {
                        "ritual": 3
                    }
                },
                "outcome": {
                    "type": "text",
                    "text": "You find a binding mark at the standard's base and speak words of release. The ice melts gently, the army dissolves into light, armor clanking on the icy ground. The last soldier turns their head toward you and bows with ancient gratitude.",
                    "rewards": {
                        "xp": 15,
                        "items": [
                            "good_iron_armor"
                        ]
                    },
                    "karma": {
                        "god": 8,
                        "hell": -8
                    }
                }
            },
            {
                "id": "pass",
                "type": "default",
                "text": "Take the ridge path to avoid the valley",
                "outcome": {
                    "type": "text",
                    "text": "At the far end, you glance back at ten thousand frozen soldiers in perfect formation, rays of light glittering on their helmets.",
                    "karma": {}
                }
            }
        ]
    }
}


def main():
    # Load existing events
    with open(EVENTS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data["events"]

    # Track changes
    updated = []
    added = []

    for event_id, event_data in UPDATED_EVENTS.items():
        if event_id in events:
            updated.append(event_id)
        else:
            added.append(event_id)
        events[event_id] = event_data

    # Write back
    with open(EVENTS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t", ensure_ascii=False)
        f.write("\n")

    print(f"Updated {len(updated)} events: {', '.join(updated)}")
    if added:
        print(f"Added {len(added)} new events: {', '.join(added)}")
    print(f"Total events in file: {len(events)}")


if __name__ == "__main__":
    main()
