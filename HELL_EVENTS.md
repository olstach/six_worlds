# Hell Realm Events

Source of truth for hell_events.json. Edit here, then ask Claude to sync to JSON.

**Outcome types:** `Text` `Combat: group (difficulty)` `Shop: shop_id`
**Choice types:** `[Default]` `[Skill X]` `[Attribute X]` `[Roll: Attribute DC N]`
**Karma realms:** hell / hungry_ghost / animal / human / asura / god
**Difficulties:** normal / hard / boss

---

## Fixed Landmarks

These are placed at specific map locations, not from the random event pool.

---

### LAVA GUARDIAN
*Pass guardian — blocks the mountain pass | Blocking | One-time | Icon: enemy_elite*

A massive elemental of molten rock blocks the passage between the ice fields and the volcanic badlands. Heat radiates from it in waves, melting the frost for meters around. It speaks with a voice of grinding stone.

*"NONE SHALL PASS between the realms of fire and ice. This has been the law for beginningless aeons. Prove your worth or be consumed."*

**[Default] Attack the guardian head-on**
→ Combat: lava_guardian (hard)
→ Karma: asura+3, hell+2

**[Martial Arts 3] Challenge it to an honorable single combat**
→ Combat: lava_guardian (normal) — it fights fairly, reduced ferocity
→ Karma: asura+5, human+2

**[Roll: Awareness DC 15] Search for an alternate route**
→ Success: Text — find hidden passage, discover fire_resistance_talisman | XP: 10 | Karma: animal+3, human+2
→ Failure: Combat: lava_guardian (hard) — spotted, it attacks | Karma: hell+3

**[Yoga 3] Sit before it in meditation**
→ Text — hours pass; the guardian recognizes your understanding and silently steps aside
→ XP: 15 | Karma: god+5, human+5, hell-5

---

### YAMA'S LIEUTENANT
*Boss — guards the realm gate | Blocking | One-time | Icon: boss*

A towering demon in ornate black and gold armor stands before the Realm Gate. Its four arms hold different weapons — sword, mace, spear, and a mirror that shows nothing.

*"I am Chitragupta, Lieutenant of Yama, Lord of Death. I have judged every soul that passes through this gate. Tell me, mortal — do you believe your deeds merit passage?"*

**[Default] Draw your weapon and fight for passage**
→ Combat: yama_lieutenant (boss)
→ Karma: hell+5, asura+5

**[Persuasion 3] Present your case with eloquent argument**
→ Combat: yama_lieutenant_weakened (normal) — it listens, lowers two weapons, giving you a fair chance
→ XP: 10 | Karma: human+5, god+3

**[Default] Confess your doubts honestly**
→ Combat: yama_lieutenant_weakened (normal) — honesty impresses him, reduced ferocity
→ XP: 8 | Karma: human+5, god+5, hell-5

**[Yoga 5] Sit before the gate and meditate on the nature of death**
→ Text — hours dissolve into the earth, days dissolve into the sky, finally the boundary dissolves into space.
→ XP: 20 | Karma: god+10, human+5, hell-10


### DEMON PATROL
*Blocking | One-time | Icon: enemy | Weight: 3*

Three demons in frost-crusted armor block the path ahead. Their captain, a horned brute with blue-black skin, raises a jagged halberd.

*"No one passes without the Warden's permission. State your business or prepare to suffer."*

**[Default] Draw your weapon and attack**
→ Combat: demon_patrol (hard)
→ Karma: hell+3, asura+2

**[Charm 14] Convince them you serve the Warden**
→ Text — they let you through; grudging respect
→ XP: 8 | Karma: hungry_ghost+2, human+3

**[Roll: Finesse DC 13] Throw a bag of gold and slip past while they argue amongst themselves**
consume a small amount of gold
→ Success: Text — slip through shadows undetected | XP: 6 | Karma: animal+3, human+2
→ Failure: Combat: demon_patrol (hard) — spotted | Karma: hell+5

**[Default] Offer them gold to look the other way**
consume a moderate amount of gold
→ Text — they pocket the gold and step aside
→ XP: 3 | Karma: hungry_ghost+5, human+2

---

### ICE SPIRITS
*Blocking | One-time | Icon: enemy | Weight: 2*

Translucent figures drift above the frozen surface of a vast lake. Their forms shimmer between beautiful and terrible — frozen souls trapped in an eternal dance. One turns toward you, its hollow eyes filled with ancient sorrow.

*"We guard what lies beneath. The dreaming dead must not be disturbed."*

**[Default] Force your way through**
→ Combat: ice_spirits (hard)
→ Karma: hell+5, asura+3

**[Water Magic 2] Speak to them in the language of water and cold**
→ Text — they recognize a kindred soul and part; the lead spirit gives you an ice shard
→ XP: 10 | Items: ice_shard | Karma: god+3, human+2

**[Yoga 2] Sit in meditation and commune with the spirits**
→ Text — through stillness you glimpse their memories; they part
→ XP: 12 | Karma: god+5, human+3

**[Default] Leave an offering at the lake's edge and pray**
→ Text — one spirit touches your forehead; a sensation of cold so deep it becomes warmth; path opens
→ XP: 5 | Karma: god+4, human+2, hell-3

---

### FROZEN MERCHANT
*Not blocking | Repeatable | Icon: shop | Tag: shop | Weight: 2*

A bundled figure huddles near a sputtering fire, surrounded by frost-covered wares. Despite the brutal cold, the merchant seems oddly cheerful.

*"Welcome, welcome! Don't mind the cold — it keeps the thieves away! I've got everything a traveler needs to survive this frozen wasteland. Well, almost everything. Can't sell warmth, sadly."*

**[Default] Browse the merchant's wares**
→ Shop: frozen_merchant
→ Karma: human+1

**[Trade 2] Use your trade knowledge to negotiate better prices**
→ Text — merchant is impressed; you get supplies at a fair price
→ XP: 5 | Items: health_potion | Karma: human+3

**[Default] Ask about the region**
→ Text — merchant warns about ice wraiths, the Lava Guardian, and Yama's lieutenant
→ XP: 2 | Karma: human+1

**[Default] Move on**
→ Text — "Safe travels! Try not to freeze!"
→ Karma: —

---

### LOST WANDERER
*Not blocking | One-time | Icon: npc | Weight: 3*

A shivering figure huddles by the roadside, barely conscious. Their robes are torn and frostbitten skin shows through.

*"Please... I've been wandering for so long. I can't feel my hands anymore. Is this... is this what I deserve?"*

**[Medicine 1] Tend to their wounds**
→ Text — color returns to their face; they press a trinket into your hands
→ XP: 8 | Items: prayer_beads | Karma: hell-5, human+5, god+3

**[Default] Give them some gold and food**
→ Text — they weep with gratitude; speak of hoarding wealth while others starved
→ XP: 4 | Karma: hell-3, human+4, god+2

**[Default] Ask how they came to be here**
→ Text — they were a corrupt tax collector; now they understand their suffering
→ XP: 3 | Karma: human+3

**[Default] Walk past without stopping**
→ Text — they watch you go in silence; the cold feels a little sharper
→ Karma: hell+2, animal+2

**[Ritual 2] Offer them a purification**
- Text - Bless some water with mantras and wash their hands and forehead. It's not much, but it's something.
- XP: 5 | Karma: human+2, god+2

---

### FROZEN CAVE
*Not blocking | One-time | Icon: dungeon | Weight: 2*

A dark cave mouth yawns in the hillside, rimmed with glittering ice crystals. From deep within comes a faint glow and the distant sound of dripping water — warm water, impossibly, in this frozen waste.

Scratches on the cave walls suggest others have entered before. Not all of the scratches point inward.

**[Roll: Awareness DC 12] Enter the cave carefully**
→ Success: Text — spot the trap, find hidden chamber, potions + journal | XP: 8 | Items: health_potion, mana_potion | Karma: human+2
→ Failure: Text — fall into lower chamber, find cache but take a knock | XP: 4 | Items: health_potion | Karma: animal+2

**[Learning 2] Study the entrance carefully before entering**
→ Text — read cave warning in old demon script; navigate easily; find preserved artifacts
→ XP: 10 | Items: health_potion, mana_potion | Karma: human+3

**[Default] The cave looks dangerous — best to move on**
→ Text — discretion is the better part of valor
→ Karma: — Items: health_potion, mana_potion | Karma: human+2, animal+2, asura+2

**[Space 2] - Calm down and feel the space around you, then in the cave**
- Text - the details remain hazy, but you quickly spot the danger ahead and proceed accordingly.
- Karma: human+2, god+1

**[Grace 2] Enter the cave gracefully**
- Text - Nimbly avoiding the obvious trap, you soon find the hidden cache.
-
---

### TORMENTED SOUL
*Not blocking | One-time | Icon: npc | Weight: 2*

A ghostly figure sits amid the frost, weeping silently. Unlike the mindless lost souls, this one retains its form — the shape of an old woman in tattered robes.

*"Can you see me? Truly see me? So few can anymore..."*

**[White Magic 1] Use white magic to ease her suffering**
→ Text — she dissolves into light; was a healer who once turned away a sick child; leaves a blessing
→ XP: 10 | Karma: hell-8, human+5, god+5

**[Default] Sit beside her and listen**
→ Text — she speaks of small cruelties compounded; seems a little more at peace
→ XP: 6 | Karma: human+5, god+2, hell-3

**[Ritual 2] Perform a ritual to release her spirit**
→ Text — mandala of liberation; she dissolves into light; leaves a soul crystal
→ XP: 12 | Items: soul_crystal | Karma: hell-10, god+8, human+3

**[Default] Walk past — ghosts are none of your concern**
→ Text — the weeping grows quieter, then stops; empty eyes follow you; the cold deepens
→ Karma: hell+3, animal+2

---

### CROSSROADS SHRINE
*Not blocking | Repeatable | Icon: event | Weight: 2*

An ancient shrine sits where the roads cross, half-buried in frost and old offerings. Incense sticks still smolder in cracked holders. A faded mandala is painted on the stone base.

The shrine radiates a faint warmth — a tiny island of peace in the frozen waste.

**[Default] Offer a prayer for safe passage**
→ Text — incense flares briefly; feeling of calm
→ XP: 2 | Karma: god+2, human+1

**[Yoga 1] Enter meditation at the sacred crossroads**
→ Text — the mandala seems to glow; energy flows through you
→ XP: 3 | Karma: god+3, human+2

**[Default] Leave a small offering of gold**
→ Text — your coins join dozens of others; generosity carries weight here
→ XP: 2 | Karma: god+3, hungry_ghost-2, hell-1

**[Ritual 1] Study the mandala's intricate patterns**
→ Text — ancient geometry of protection; adds to your ritual knowledge
→ XP: 5 | Karma: human+3, god+2

**[Default] Continue on your way**
→ Text — you nod respectfully and continue; sometimes the journey is the practice
→ Karma: —

---

### FROZEN WATERFALL YOGI
*Not blocking | One-time | Icon: npc | Weight: 1*

Before a magnificent frozen waterfall, a yogi sits in perfect stillness. Ice crystals have formed on their eyelashes and hair. The waterfall behind them is frozen mid-cascade.

*"Ah. A visitor who can see beyond the cold. Come, sit. The water remembers what it was, and knows what it will become."*

**[Water Magic 1] Ask to learn water magic techniques**
→ Text — hours beside the frozen falls; feel the flow within stillness
→ XP: 15 | Karma: god+4, human+3

**[Yoga 2] Meditate together on the nature of impermanence**
→ Text — consciousness merges with the waterfall; experience the moment of freezing
→ XP: 12 | Karma: god+4, human+3

**[Default] Watch the yogi's meditation in silence**
→ Text — the cold seems to lessen; you stop fighting it
→ XP: 5 | Karma: god+2, human+2

**[Default] Leave the yogi to their meditation**
→ Text — you bow respectfully; the yogi closes their eye
→ Karma: human+1

---

### ANCIENT STUPA
*Not blocking | Repeatable | Icon: shrine | Weight: 3*

A crumbling stupa rises from the frost, its dome still intact after ages beyond counting. Prayer flags — impossibly — still flutter from the crown, faded but unbroken. Faint mantras are carved into every stone.

It radiates a stillness entirely at odds with everything else in this frozen wasteland.

**[Default] Walk around it three times in devotion**
→ Text — circle clockwise three times; the cold lessens with each circuit; place an offering
→ XP: 5 | Karma: god+3, human+2, hell-2

**[Yoga 1] Meditate at the stupa's base**
→ Text — the structure hums with intention; mana restored; cold has not touched you
→ XP: 8 | Karma: god+5, human+3, hell-3

**[Ritual 1] Study the carved mantras closely**
→ Text — prayers of purification and liberation; copy lines into memory
→ XP: 8 | Karma: god+4, human+3

**[Default] Leave a small offering and move on**
→ Text — leave a few coins; the flags flutter once in farewell
→ XP: 2 | Karma: god+2, hell-1

**[Air magic 1] Study the prayer flags**
- Text: somehow kept together by their inner charge rather than outer weave, the flags can still teach you something.
- XP: 8 | Karma: god+2, human+2
---

### DEMON CHECKPOINT
*Blocking | One-time | Icon: enemy | Weight: 3*

A wobbly table has been set up across the path. Behind it, a bureaucratic demon in a stained uniform holds a quill the size of a sword.

*"Halt. Passage permit, please. Standard Form 7-B, the one authorizing inter-zone traversal for non-damned entities. You do have a Form 7-B, yes?"*

You do not have a Form 7-B. Form 7-B does not exist.

**[Default] Push past the checkpoint by force**
→ Combat: demon_patrol (normal) — bureaucrat sounds the horn
→ Karma: asura+2, hell+2

**[Guile 2] Produce a convincing-looking document**
→ Text — fold some parchment into an official-looking shape; demon examines it upside down; stamps it
→ XP: 8 | Karma: hungry_ghost+2, human+2

**[Default] Slip the demon a bribe**
→ Text — gold changes hands; "Everything checks out. Move along."
→ XP: 3 | Karma: hungry_ghost+4, hell-1

**[Persuasion 2] Challenge the checkpoint's legal legitimacy**
→ Text — 40-minute forensic argument; bureaucrat shaken; waves you through with haunted eyes
→ XP: 10 | Karma: human+4, hell-3

**[Comedy 2] Explain that you are not beholden to a public servant without the 16-F license**
- Text - Stumped at first, the devil nods slowly - game recognizes game.
- XP: 10 | Karma: human +5
---

### ICE ORACLE
*Not blocking | One-time | Icon: npc | Weight: 2*

A figure is frozen solid inside a pillar of ice — upright, arms folded, expression serene. Its eyes, impossibly, are still moving.

*"I have been here since the realm formed. I have watched every soul pass through. Ask, and I may answer."*

**[Default] Ask what lies ahead on your path**
→ Text — cryptic prophecy: "Choose mercy. The cost is smaller than it appears."
→ XP: 6 | Karma: human+2

**[White Magic 2] Open your mind and commune with it directly**
→ Text — centuries of passing souls; their fears and small kindnesses; deep clarity
→ XP: 10 | Karma: god+5, human+3

**[Awareness 13] Ask about the nature of this realm**
→ Text — "This realm is a mirror. The cold here is the cold these souls carried within them."
→ XP: 10 | Karma: god+4, human+4, hell-3

**[Default] Thank it for its time and move on**
→ Text — "Go well. The path is yours." It watches you with something like hope
→ Karma: human+1

**[Comedy 2] You've stayed here so long and still found no way out? I'm not sure if it'a good idea to listen**
- Text - "He murmurs gruffly under his breath, not entirely without self-doubt"
- XP: 5 | Karma: human+2, asura+1
---

### GHOST VILLAGE
*Not blocking | One-time | Icon: dungeon | Weight: 2*

Stone buildings stand perfectly preserved — doors hanging open, fires long dead, a well at the center still intact. Not a soul visible, but the air feels thick with watching.

**[Roll: Awareness DC 12] Search the buildings carefully**
→ Success: Text — half-finished meals, a child's toy; strongbox under the hearth | XP: 8 | Items: health_potion, mana_potion | Karma: human+2
→ Failure: Text — nothing found; footsteps heard from an already-searched house; you don't go back | XP: 3

**[Default] Go to the village center and pay your respects**
→ Text — bow your head; watching feeling shifts from surveillance to gratitude
→ XP: 5 | Karma: god+3, human+3, hell-2

**[Persuasion 1] Call out to the spirits of this place**
→ Text — a presence brushes past; images: a flood, a night with no stars, someone who waited and was never found
→ XP: 10 | Karma: human+5, hell-3

**[Default] Leave the village alone**
→ Text — keep your eyes forward; the watching feeling follows you, then fades
→ Karma: —

**[Ritual 3] Prepare a smoke offering for the lingering spirits**
- Text - "Ghosts, gods, lords of this land, come forth and take your fill in peace!"
- XP: 8 | Karma: human+3, god+3
---

## Cold Hell — Mob Events

These are attached to roaming/patrol mobs rather than fixed objects.

---

### HERMIT MONK
*Roaming friendly mob | Icon: npc | Weight: 3*

A weathered monk in tattered robes approaches, seemingly at peace despite the frozen wasteland. His eyes are bright and clear.

*"Ah, a fellow traveler. How rare to meet someone with open eyes in this place."*

**[Yoga 1] Ask the monk for spiritual teaching**
→ Text — teaches about the nature of suffering as a mirror; every realm is a classroom
→ XP: 10 | Karma: god+5, human+5

**[Default] Sit with him in meditation**
→ Text — comfortable silence; presence like a fire in the cold; restored
→ XP: 4 | Karma: god+3, human+2

**[Awareness 14] Ask about the workings of karma**
→ Text — speaks of the six realms; "every small kindness creates ripples"
→ XP: 8 | Karma: human+5, god+3

**[Default] Wish him well and continue your journey**
→ Text — "The cold cannot touch a warm heart." He walks into the frost, leaving no footprints
→ XP: 2 | Karma: human+1

**[Comedy 2] My eyelids are frozen in place, friend**
- Text - He laughs surprised. The following conversation fills you both with warmth.
- XP: 8 | Karma: human+5

### WANDERING PEDDLER
*Roaming friendly mob | Icon: merchant | Weight: 2 | Tag: shop*

A hunched figure dragging a heavy sack waves you down.

*"Psst! Traveler! You look like you could use some supplies. I've got just the things — pulled from the frozen dead, cleaned up nice."*

**[Default] See what the peddler has to offer**
→ Shop: wandering_peddler
→ Karma: human+1

**[Default] Ask for directions and local knowledge**
→ Text — warns about the frozen lake spirits, points toward the hermit monk in the eastern hills
→ XP: 2 | Karma: human+1

**[Default] Decline politely and move on**
→ Text — "Your loss! If you change your mind, I'll be around. Always around..."
→ Karma: —

**[Trade 2] Haggle for better prices**
- Text - The trader seems amused, and after a short back-and-forth, grants you a discount.
- XP: 4 | Karma: human+4
---

## Fire Hell — Event Pool

---

### BURNING SHRINE
*Not blocking | One-time | Icon: event | Weight: 2*

A shrine wreathed in eternal flames stands among scorched ruins. Unlike the destructive fires around it, these flames burn with a sacred quality — steady, contained, purposeful. Ancient mantras glow red with heat.

**[Fire Magic 2] Channel the shrine's power through your fire magic**
→ Text — fire dances up your arms without burning; understanding deepens; control over flame improved
→ XP: 12 | Karma: asura+3, human+2

**[Ritual 2] Study the ancient mantras carved into the stone**
→ Text — prayers of purification through fire; suffering as fuel for enlightenment
→ XP: 10 | Karma: god+4, human+3

**[Default] Kneel and pray before the burning shrine**
→ Text — prayer rises unbidden; surge of resolve
→ XP: 4 | Karma: god+2, asura+2

**[Default] The flames are too intense — move on**
→ Text — some trials require preparation before they can be faced
→ Karma: —

---

### EMBER MERCHANT
*Not blocking | Repeatable | Icon: shop | Tag: shop | Weight: 2*

A demon merchant sits cross-legged on a fireproof blanket, surrounded by wares that glow faintly with heat. Their skin is deep red, cracked like cooling lava.

*"Welcome to the finest establishment in all of burning Naraka! Fire-forged goods, guaranteed to survive anything this realm throws at you. Mostly."*

**[Default] Browse the ember merchant's fire-forged wares**
→ Shop: ember_merchant
→ Karma: human+1

**[Trade 2] Negotiate as a fellow trader**
→ Text — demon respects the approach; gives a sample of their finest work
→ XP: 5 | Items: fire_resistance_potion | Karma: human+3

**[Default] Ask about the burning realm**
→ Text — warns about the Oni Brute, Trial of Flames, and Yama's lieutenant
→ XP: 2 | Karma: human+1

**[Default] Move on**
→ Text — "Stay warm! Well, you'll have no choice about that down here!"
→ Karma: —

**[Comedy 2] Mostly guaranteed, or guaranteed I'd mostly survive?**
- Text - The trader chuckles surprised and throws you a little trinket. "That's on the house, clown"
- XP: 5 | Karma:human+4 | Item: common earth charm
---

### BURNING PRISONER
*Not blocking | One-time | Icon: npc | Weight: 3*

A figure writhes in chains of molten metal, suspended above a pit of glowing coals. Their screams have faded to hoarse whispers. Their eyes are clear — filled with pain, but also a terrible awareness.

*"Please... I know what I did. I know why I'm here. But I've suffered enough to understand. Please..."*

**[Strength 14] Break the chains**
→ Text — grab molten chains; with a mighty heave the links shatter; prisoner collapses; presses a key into your blistered hands
→ XP: 10 | Items: demon_key | Karma: hell-8, human+5, god+5

**[White Magic 2] Use healing magic to ease their suffering**
→ Text — can't break the chains, but can mend what they've broken; prisoner breathes freely; weeps clean tears through the soot
→ XP: 8 | Karma: hell-5, human+5, god+8

**[Ritual 3] Offer a purification to shorten their suffering**
- Text - They nod somewhat absent-mindedly, numbed by the pain. By the end of the ritual they seem somewhat relieved.
- XP: 8 | Karma: human+3, god+4

**[Default] Ask what crime brought them here**
→ Text — "I was a warlord. I burned a hundred homes. I thought fear was power."
→ XP: 4 | Karma: human+3, hell-2

**[Default] Turn away — this is their punishment**
→ Text — you walk on; the whispers fade back into the crackling flames; heat feels heavier
→ Karma: hell+3, asura+2

---

### TRIAL OF FLAMES
*Blocking | One-time | Icon: dungeon | Weight: 2*

An arena of scorched stone rises from the lava fields, its tiers filled with demons of all shapes and sizes. A massive demon in ceremonial armor stands at the center.

*"FRESH CHALLENGER! The Trial of Flames awaits! Prove your worth in combat, or prove your wisdom in another way. Choose!"*

**[Default] Accept the combat challenge**
→ Combat: demon_patrol (hard) — arena champions pour in
→ Karma: asura+5, hell+2

**[Performance 3] Challenge them to a contest of performance instead**
→ Text — tell the tale of a warrior who conquered through art; demons listen, rapt; showered with prizes
→ XP: 12 | Items: fire_crystal | Karma: asura+3, human+5

**[Charm 15] Stare down the champion with raw willpower**
→ Text — neither of you blinks; the crowd falls silent; champion recognizes a true warrior and opens a path
→ XP: 10 | Karma: asura+5, human+3

**[Default] Decline and walk away**
→ Text — boos follow you, but no one moves to stop you; sometimes the bravest choice looks like retreat
→ Karma: human+2

**[Sorcery 4] Strike the demon down with magic before he finishes boasting**
- Text - the crowd first falls silent, then erupts.
XP: 12 | - Karma: asura+4, human+3
---

### VOLCANIC CAVE
*Not blocking | One-time | Icon: dungeon | Weight: 2*

A cave entrance glows red with the heat of magma flowing within. The walls pulse with veins of liquid fire. Deep within, a rhythmic sound — like a heartbeat, or the slow breathing of something enormous.

The heat is nearly unbearable, but you can see the glint of valuables deeper inside.

**[Roll: Constitution DC 14] Brave the heat and explore the cave**
→ Success: Text — push through; ancient demon forges still glowing; remarkable equipment and supplies | XP: 10 | Items: health_potion, fire_resistance_potion | Karma: human+2
→ Failure: Text — stagger back, blistered; grab a few things near the entrance | XP: 4 | Karma: animal+2

**[Fire Magic 2] Use fire magic to protect yourself from the heat**
→ Text — weave a barrier; lava parts before you; cave holds wonders; ancient forge lit since Naraka's birth
→ XP: 12 | Items: fire_crystal, mana_potion | Karma: human+3, asura+2

**[Learning 2] Listen to the heartbeat sound from the entrance**
→ Text — too regular for a creature; it's the pulse of the realm itself; Naraka has a heartbeat; this cave is one of its arteries
→ XP: 8 | Karma: human+4, god+2

**[Grace 2] Do your best to move quickly and avoid the thermal vents**
- Text - Uncomfortable, but nevertheless doable, like so many things in life.
- XP: 8 | Karma: animal+3, human+3, asura+3 | Items: health_potion, fire_resistance_potion |

**[Default] The heat is too dangerous — move on**
→ Text — the glow pulses with what might be disappointment
→ Karma: —

---

### LAVA FLOW
*Not blocking | One-time | Icon: event | Weight: 2*

A river of molten rock surges across the path ahead. On the other side, the path continues — but crossing seems impossible.

Then you notice: the flow pulses. There are moments when it thins, gaps between surges...

**[Roll: Finesse DC 14] Time the surges and dash across**
→ Success: Text — sprint across the brief gap; singed clothes, racing heart | XP: 8 | Karma: human+2, animal+2
→ Failure: Text — mistime the surge; leap back; minor burns; healthy respect for lava | XP: 3 | Karma: hell+1

**[Grace 3] Time your steps to the rhythm and dance your way through**
- Text - And a-one, and a-two...
- XP: 8 | Karma: animal+3, human+3, asura+3

**[Earth Magic 2] Use earth magic to create a stone bridge**
→ Text — pull stone from bedrock; it rises hissing above the lava; you cross safely; bridge lasts for others too
→ XP: 10 | Karma: human+4, god+2

**[Default] Look for a way around**
→ Text — follow the flow downstream; find a narrow point; cross slowly; unburned
→ XP: 2 | Karma: human+1

---

### LAVA SWIMMER
*Not blocking | One-time | Icon: npc | Weight: 2*

Something enormous and serpentine moves beneath the surface of a lava flow. As you watch, it surfaces — forty meters long, its scales glowing like cooling magma, its eyes containing a fire that is not hot but old.

It regards you with what you can only describe as curiosity.

**[Default] Watch it in respectful silence**
→ Text — mesmerizing fluid movements; it rises and sinks; sinks below; lava glows brighter where it passed
→ XP: 6 | Karma: animal+2, human+4

**[Fire Magic 2] Commune with it through fire magic**
→ Text — extend awareness through fire; it responds; sensation of heat and the memory of a younger world; afterwards your experience of heat seems somehow deeper, more meaningful.
→ XP: 14 | Karma: animal+4, god+3

**[Default] Drop something metallic into the lava as an offering**
→ Text — it watches the coins sink; returns with a fire opal; seems to value the exchange
→ XP: 5 | Items: fire_crystal | Karma: animal+3

**[Default] Attack the creature while it's surfaced**
→ Combat: lava_guardian (hard) — ancient eyes shift from curious to cold
→ Karma: animal-5, hell+3

**[Performance 3] Struck by awe, sit down and begin strumming, until a melody comes 
---

### DEMON DOJO
*Not blocking | One-time | Icon: dungeon | Weight: 2*

A stone courtyard where a dozen demons practice combat forms with absolute precision. There is something almost beautiful about it — the focus, the discipline, the commitment to mastery.

The sensei demon spots you and gestures inward. An invitation.

**[Strength 12] Join the training session**
→ Text — brutal but honest training; sensei adjusts your stance; returns your bow at the end
→ XP: 12 | Karma: asura+4, human+2

**[Roll: Finesse DC 13] Challenge one demon to a friendly bout**
→ Success: Text — hard fight; draw by mutual acknowledgment; demons stamp their feet in approval | XP: 10 | Karma: asura+5, human+3
→ Failure: Text — flat on your back in thirty seconds; demon offers a hand up; last longer the second time | XP: 5 | Karma: asura+2, human+2

**[Learning 1] Observe the forms carefully without participating**
→ Text — forms older than you expected; certain sequences embed themselves in your muscle memory through observation
→ XP: 8 | Karma: asura+2, human+3

**[Default] Decline the invitation and move on**
→ Text — bow respectfully at the entrance; training continues without pause
→ Karma: asura+1

---

### INFERNAL ARCHIVE
*Not blocking | One-time | Icon: dungeon | Weight: 1*

A tower of black basalt, its windows glowing orange from within. Sign: INFERNAL ARCHIVE — RESTRICTED MATERIALS.

The ancient librarian demon at the desk regards you with the professional suspicion of someone who has seen too many people try to steal restricted materials.

**[Default] Request access to the unrestricted section**
→ Text — Section Three; no fire, no food, no summoning; read accounts of previous hell realm travelers
→ XP: 8 | Items: scroll_lesser_heal | Karma: human+2

**[Guile 2] Access the restricted collection**
→ Text — slip through the RESTRICTED door while librarian's back is turned; memorize key passages; return to seat undetected; knowledge valuable, leaves a lingering unease
→ XP: 12 | Items: scroll_firebolt | Karma: hungry_ghost+3, hell+1

**[Trade 2] Commission research on local trade routes**
→ Text — pay the research fee; receive three scrolls of merchant routes, safe passage times, and which demons respond to bribery
→ XP: 6 | Karma: human+2

**[Default] The archive's atmosphere is too unsettling — leave**
→ Text — back out; librarian watches without comment; orange glow continues its eternal burn
→ Karma: —

---

### FIRE PILGRIM
*Not blocking | One-time | Icon: npc | Weight: 3*

A figure in scorched white robes moves through the fire hell on their knees, hands pressed together, murmuring prayers with every measured movement. Burns mark their skin. Their eyes are clear — no delusion, no despair, just deliberate acceptance of each moment of pain.

**[Medicine 1] Heal their burns and walk with them a while**
→ Text — tend wounds; they don't want to stop, but relief at having another person near; walk together an hour; they press a carved token into your hands: "Carry it until you don't need it. Then give it to someone who does."
→ XP: 12 | Items: prayer_beads | Karma: god+6, human+5, hell-4

**[Default] Walk alongside them in silence**
→ Text — fall into step beside them; a quarter mile in silence; bow to each other at the parting
→ XP: 6 | Karma: god+4, human+4, hell-2

**[Default] Ask them about their pilgrimage**
→ Text — "I burned a library. I didn't think about what it contained. I have been walking since then."
→ XP: 4 | Karma: human+3

**[Default] Let them continue their journey**
→ Text — step aside; their prayers continue without acknowledgment; this journey belongs entirely to them
→ Karma: —

---

## Cold Hell — New Events (Batch 2)

---

### BONE ARENA
*Blocking | One-time | Icon: dungeon | Weight: 2*

A frozen pit ringed with bones rises from the wasteland — a combat arena, its tiers packed with ice demons howling for blood. Two poor souls fight below, stumbling with exhaustion.

A massive gatekeeper blocks the exit path, grinning with too many teeth. *"Fresh challenger! Enter the pit or find another road. There is no other road."*

**[Default] Step into the arena and fight**
→ Combat: demon_patrol (hard)
→ Karma: hell+2, asura+5

**[Strength 13] Issue a formal challenge to the current champion**
→ Combat: demon_patrol (normal) — single combat, honorable rules; gatekeeper watches with respect
→ XP: 12 | Karma: asura+5, human+3

**[Performance 2] Narrate the fight dramatically for the crowd**
→ Text — crowd shifts from baying for blood to hanging on your words; gatekeeper laughs hard enough to open the gate without charging
→ XP: 10 | Karma: asura+3, human+5

**[Default] Bribe the gatekeeper to look the other way**
→ Text — gold changes hands; "Don't tell the crowd. It ruins the atmosphere."
→ XP: 3 | Karma: hungry_ghost+4

---

### SUFFERING SAGE
*Not blocking | One-time | Icon: npc | Weight: 1*

A figure sits at the summit of a frozen ridge, encased in ice to the neck — only their face remains free, eyes open and clear. They have been here longer than the realm itself, or so it seems. Their expression holds no suffering, only the far-off calm of someone who has understood everything about pain.

*"Ah. A visitor who can walk. How rare. Ask. I have time."*

**[Default] Ask about the nature of suffering**
→ Text — "All suffering comes from resistance to what is. The cold is not suffering. The resistance to the cold is suffering."
→ XP: 8 | Karma: god+5, human+3

**[Yoga 3] Enter deep meditation to receive their teaching directly**
→ Text — a current passes between you, beyond words: the shape of suffering, its exact texture, the moment when resistance becomes release; the ice around the sage cracks slightly
→ XP: 18 | Karma: god+10, human+5, hell-5

**[Learning 2] Ask about the history of this realm**
→ Text — "I was here before the first demon arrived. The first being who entered was a judge convinced he was perfectly just. He was here for a very long time." / "Not punishment. Curriculum."
→ XP: 12 | Karma: god+4, human+4

**[Default] Leave them to their vigil**
→ Text — "Go well. You carry more wisdom than you know."
→ Karma: human+1

---

### SUSPICIOUS GIFT
*Not blocking | One-time | Icon: event | Weight: 3*

A neatly wrapped package sits in the center of the path, as though placed deliberately. Red cloth, black cord. A tag: *"For whoever needs this most."*

The package is warm to the touch. Nothing else in the cold hell is warm.

**[Roll: Awareness DC 12] Examine it carefully before opening**
→ Success: find trap thread, disarm it, open to find gold + health potion + note: "Congratulations on your caution." | XP: 8 | Items: health_potion | Gold: 40 | Karma: human+2
→ Failure: triggered; theatrical but not lethal; package empty; a card: "Better luck with the next one." | XP: 3 | Karma: hell+1, animal+2

**[Guile 1] Check it for traps with trained eyes**
→ Text — find binding rune; neutralize it; open cleanly; health potion and gold inside
→ XP: 6 | Items: health_potion | Gold: 25 | Karma: human+2

**[Default] Open it with reckless optimism**
→ Text — flash, sound, blinding cold — then you're standing there holding a health potion and forty gold, entirely unharmed. Sometimes things are exactly what they appear to be.
→ XP: 4 | Items: health_potion | Gold: 40 | Karma: animal+2, human+1

**[Default] Leave it — gifts in hell are seldom genuine**
→ Text — you step around it; behind you, the package waits: warm, patient, for someone braver or more foolish
→ Karma: human+1

---

### ICE DEMON TOLL
*Blocking | One-time | Icon: enemy | Weight: 3*

Three squat ice demons have stretched a chain across the path. The leader holds a sign reading "TOLL — 10 GOLD" in letters of varying sizes.

*"Passage fee. Standard Hell Traversal Rate, Section 7, Paragraph 4."*
*"There is no Section 7, Paragraph 4."*
*"There will be if you don't pay."*

**[Default] Refuse and fight your way through**
→ Combat: demon_patrol (normal)
→ Karma: asura+2, hell+2

**[Default] Pay the toll and move on**
→ Text — gold counted with elaborate care; chain unclipped; courtly bow; "Watch out for the unofficial toll three roads further on — those ones are criminals."
→ XP: 2 | Karma: hungry_ghost+2

**[Guile 1] Challenge the legal legitimacy of this checkpoint**
→ Text — forty-minute forensic argument; absence of seals, three different handwritings on the sign, suspicious provisions; lead demon: "You can go. But only because we choose to be magnanimous."
→ XP: 8 | Karma: human+3, hell-2

**[Performance 1] Offer to pay in entertainment**
→ Text — performance; demons transfixed; leader applauding; chain unclipped; one demon presses a coin into your hand: "Best thing that's happened here in a century."
→ XP: 5 | Gold: 5 | Karma: human+3, asura+2

---

### CURSED PILGRIM
*Not blocking | One-time | Icon: npc | Weight: 2*

A person trudges forward pulling a massive stone block behind them — literally. Black iron chain links ankle to stone, stone gouging a furrow in the frozen ground. They are making slow but genuine progress.

*"Oh. A living one. That's rare. I made a deal with a small devil. The small ones are the worst. You can fight the big ones."*

**[Strength 15] Break the chain by brute force**
→ Text — after a long struggle, a link shatters; pilgrim sits down heavily and simply breathes; presses carved token into your hands: "I had forgotten what it felt like to stop."
→ XP: 12 | Items: prayer_beads | Karma: hell-8, human+5, god+5

**[Black Magic 1] Examine the curse and explain the mechanism**
→ Text — specific class of binding, resistant to direct force, vulnerable to patient unraveling from within; you explain; pilgrim asks precise questions; by the end they look like someone with a plan: "I can be patient too."
→ XP: 10 | Karma: human+4, hell-3

**[Default] Walk with them a while and listen**
→ Text — story of the deal; "I thought I was clever. I had found the loophole it wanted me to find."; you walk an hour; at parting: "It helps to be reminded that someone can walk freely."
→ XP: 5 | Karma: human+4, hell-2

**[Default] Try to help break the chain**
→ Text — try everything; chain absolutely indifferent; pilgrim watches with tired gratitude: "The trying matters. I had forgotten anyone would bother."; their handshake is stronger than you expected
→ XP: 3 | Karma: human+3, hell-1

---

### FROZEN ARMY
*Not blocking | One-time | Icon: dungeon | Weight: 2*

The valley below is filled with an army, frozen mid-march — thousands of soldiers preserved in ice, weapons raised, banners still flying. The armor is from no civilization you recognize. They are marching toward something that is no longer there.

They do not look like they are suffering. They look like they are waiting.

**[Default] Pay your respects to the fallen**
→ Text — stand at the valley's edge and bow; barely perceptible: in the front rank, a soldier's hand tightens slightly on their weapon — they acknowledge you
→ XP: 5 | Karma: human+3, god+2

**[Awareness 12] Study the banners and try to identify them**
→ Text — sun bisected by a spear, pre-history; armor wrong for any hell-native force; these were mortals who marched here deliberately to rescue someone; they were winning; then stopped. Not punishment. Grief, suspended.
→ XP: 10 | Karma: human+5, god+3, hell-2

**[Roll: Awareness DC 13] Search for a way to end their vigil**
→ Success: find binding mark at the standard's base; speak words of release; ice melts gently; army dissolves into light; last soldier turns their head toward you and nods — ancient and absolute gratitude | XP: 15 | Karma: god+8, hell-8
→ Failure: touch disturbs the binding; one soldier wrenches free and attacks | Combat: lost_souls (normal) | Karma: hell+2

**[Default] Take the ridge path to avoid the valley**
→ Text — at the far end, you glance back at ten thousand frozen soldiers in perfect formation; you walk on
→ Karma: human+1

---

## Fire Hell — New Events (Batch 2)

---

### PYROMANCER'S CHALLENGE
*Blocking | One-time | Icon: enemy | Weight: 2*

A human mage in scorched red robes blocks the path, orbiting flames circling her like planets. The dueling scar on her cheek is self-inflicted. She examines you with professional interest.

*"You move like a magic user. I can always tell. I've been here forty years and no one's given me a real fight. You interested?"*

**[Fire Magic 1] Accept the fire duel**
→ Combat: demon_patrol (normal) — honorable rules, first to yield
→ XP: 10 | Karma: asura+5, human+3

**[Air Magic 2] Answer fire with wind magic**
→ Text — your wind meets her fire in dialogue rather than combat; she lowers her hands: "That's actually better. You're teaching me something." She steps aside and demonstrates a fire-sealing technique.
→ XP: 12 | Karma: asura+3, human+5

**[Persuasion 2] Ask why she has been here for forty years**
→ Text — "I came looking for my student. Found his ghost. Spent ten years helping him move on. He did, in the end. But I stayed. I thought I owed this place something." She steps aside without being asked.
→ XP: 8 | Karma: human+5, god+3, hell-3

**[Default] Decline and find another way around**
→ Text — she watches with the measured disappointment of someone who has learned not to expect much; settles in to wait for the next traveler
→ Karma: human+1

---

### DEMON MARKETPLACE
*Not blocking | One-time | Icon: shop | Tag: shop | Weight: 2*

A chaotic bazaar has assembled in the middle of the lava fields — dozens of stalls selling weapons, memories, bottled emotions, demon-forged equipment, and items you cannot categorize.

Sign over the entrance: NO FIGHTING. NO UNAUTHORIZED FIRE (the sign is on fire). NO RETURNS.

**[Default] Browse the marketplace stalls**
→ Shop: ember_merchant
→ XP: 2 | Karma: human+2, hungry_ghost+1

**[Trade 2] Seek out the best deals with expert knowledge**
→ Text — find a back stall others avoid; proprietor: "The things nobody wants are often the things someone needs"; fair prices, unusual goods
→ XP: 8 | Items: fire_crystal | Karma: human+3

**[Guile 2] Find the restricted goods in the back alleys**
→ Text — hooded demon with careful eyes; items with complicated histories, scrolls from restricted collections
→ XP: 6 | Items: scroll_firebolt | Karma: hungry_ghost+4, hell+2

**[Default] Watch the crowds instead of buying**
→ Text — three deals go wrong in interesting ways; two go right; a woman cries in front of a memory-jar labeled "Tuesday, Age 7"; she doesn't buy it
→ XP: 4 | Karma: human+3

---

### BURNING LIBRARY
*Not blocking | One-time | Icon: dungeon | Weight: 2*

A library is on fire. Not metaphorically — the entire building is actively burning. But at the center, visible through the inferno, an enormous bookshelf stands intact, its contents still whole. It will reach the center shelf soon.

**[Roll: Constitution DC 13] Dash through the flames to save what you can**
→ Success: reach center shelf, grab armfuls before a beam falls; singed but standing; books in an unknown language | XP: 10 | Items: scroll_firebolt, scroll_lesser_heal | Karma: human+4
→ Failure: driven back; save one book near the entrance | XP: 5 | Items: scroll_lesser_heal | Karma: human+2, animal+2

**[Fire Magic 2] Command the flames to clear a path**
→ Text — speak to the fire; it responds; corridor of cooler air; walk to center calmly; exit as building collapses in a controlled exhale
→ XP: 14 | Items: scroll_firebolt, mana_potion | Karma: human+5, asura+3

**[Default] Shout to see if anyone is still inside**
→ Text — silence; then a cough; small demon emerges clutching a ledger with both arms, refusing to put it down; you pull it out by the collar; it presses a key into your hands with humiliated dignity
→ XP: 8 | Items: demon_key | Karma: hell-5, human+8, god+3

**[Default] Stand and witness the burning**
→ Text — you watch the library burn; the center shelf goes last; pages lift in the updraft, briefly bright, then dark; something is lost; something, somehow, is freed
→ XP: 3 | Karma: human+2

---

### SINNER GANG
*Not blocking | One-time | Icon: npc | Weight: 3*

A group of damned souls has made camp around a fire — not for warmth, but for companionship. A soldier, a tax collector, an artist, a merchant. They've made rules, share what they find, keep watch in shifts. It is, against all odds, working.

**[Default] Share a meal and hear their stories**
→ Text — what they did, what they understand now, what they're still working out; none of them are done, but they're thinking clearly; you leave feeling less alone.
→ XP: 6 | Karma: human+5, hell-3

**[Default] Trade supplies with them**
→ Text — A fair exchange; the merchant among them negotiates with professional precision, which makes them snicker. "Force of habit is stronger than death."
→ XP: 4 | Enter trade, a basic shop with a few better potions | Karma: human+3

**[Persuasion 2] Inspire them to seek freedom rather than comfort**
→ Text — Words land differently here. One of them cries, but change does not come easy to those frozen stiff. Nevertheless, when you're leaving, they're still talking. 
→ XP: 6 | Karma: human+4, god+3, hell-3

**[Default] Watch from a distance without disturbing them**
→ Text — One of them looks up and sees you; they raise a hand; you raise yours; they return to their conversation; that is enough.
→ XP: 2 | Karma: human+2

---

### FORGE SPIRIT
*Not blocking | One-time | Icon: npc | Weight: 2*

An abandoned forge glows with ancient heat — the fire here has not gone out in centuries. A shade with a raven's head works the bellows with practiced rhythm, hammer rising and falling on metal that is not there.

She stops as you approach. *"Oh. A visitor... what day is it?"*

**[Default] Tell her what you know of the current state of the realm**
→ Text — she processes each piece of news slowly. "Thank you. I don't remember the last time I talked with another soul." She returns to her work with a faint smile.
→ XP: 5 | Karma: human+4, god+2

**[White Magic 4] Help her find the peace she is missing**
→ Text — A long conversation about what she made, who she made it for; the hammer and bellows slow; "I kept thinking there was one more thing to finish. But it was already finished." She looks up: "Oh. There it is." And then she is simply gone — complete. Her tools left behind, solid now.
→ XP: 14 | Items: fire_crystal | Karma: god+8, hell-8, human+5

**[Crafting 3] Ask to learn her craft techniques**
→ Text — ancient methods based on relationship with material rather than mastery; she shows you how to hear what metal wants to become; your hands remember what your mind can't quite hold.
→ XP: 5 | Skill:Crafting+1 | Karma: human+4, asura+3

**[Default] Leave the spirit to her work**
→ Text — You bow at the entrance. She does not look up, but the rhythm of the hammer changes briefly — a different beat, just for a moment — then returns; a greeting, in the only language available.
→ XP: 3 | Karma: human+1

---

### THE INVITATION
*Not blocking | One-time | Icon: event | Weight: 1*

An ornate envelope rests on a flat rock in the middle of a lava field, sealed with black wax. Your name is on the outside — not the name you use in this life, but one you know is yours.

*"It would please us greatly if you would attend. We have matters of mutual interest to discuss. Come alone."*

**[Default] Follow the map**
→ Text — a well-dressed blue devil reclines on silken pillows embroidered with gold, gesturing you to sit down nearby. Over little cups of burning liquor and water pipe smoke they explain their interest in your journey and karmic potential. Would you spare a single drop of blood for their cabinet of curiosities? Before you can think the answer over, a sharp sting startles you - a small imp flutters away from you with a ruby phial.
→ XP: 10 | -1 CON permanently, receive a large amount of gold |Karma: asura+3, hungry_ghost+2, human+2

**[Guile 2] Follow the map but arrive early and observe first**
→ Text — an hour early, a damned soul arrives before you and goes inside. You hear the shape of a deal through the thin obsidian wall. When they emerge, they feel subtly lighter.
→ XP: 6 | Karma: animal+3, human+3

**[Black Magic 2] Examine the invitation closely**
    → Text — the paper is woven with mantric syllables that seem to dance away from your gaze when you try to follow them. You recognize the humid hotness they impart to your mind as *mohana*, a spell meant to muddle the reason and compel to follow instructions. You burn the paper.
→ XP: 10 | Karma: human+3, asura+3

**[Default] Set it back on the rock and walk on**
→ Text — behind you, the envelope waits; somehow, you can sense a faint tinge of disappointment.
→ XP: 3 | Karma: human+2

---

### A SIGH OF RELIEF
*Not blocking | One-time | Icon: shrine | Weight: 1 | Spawns in both zones*

You feel strangely drawn towards a clearing, where among the bleakness a figure stands shining softly. A bodhisattva from the higher realms has come to the Hells to give offerings and teach the suffering shades. As you come closer you see piles of food, drink, and medicine manifesting from thin air, imps swarming around and swallowing mouthfuls.

**[Yoga 2] Meditate in the presence of the Bodhisattva**
→ Text — As you settle down and focus you recognize there is no boundary between you. The teacher smiles and raises their hand to bless you.
→ XP: 12 | Karma: hell-5, human+3, god+5

**[Focus 14] Listen to the teachings**
→ Text — Impermanence, compassion, joy. It seems like you have heard these words before, but long forgotten their meaning.
→ XP: 10 | Karma: hell-3, human+3, god+3

**[Default] Come and take your fill**
→ Text — for a moment, all your fears and hopes dissolve into the present moment. You are content.
→ Effect: party HP, mana, and stamina are refilled 100%
→ XP: 8 | Karma: hell-3, hungry_ghost+2, animal+2, human+2

**[Default] Rush in and take as much as you can**
→ Text — The scene vanishes as if it was never there.
→ XP: 0 | Karma: hell+5, hungry_ghost+5

---

## Ideas — Next Batch

*(add new ideas here)*

*Last updated: 2026-02-27*
