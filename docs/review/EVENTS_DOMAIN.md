# Cross-realm (domain, camp, trait, relationship) — Events

*33 events. 11 added in the 2026-07-27 sessions, marked **NEW EVENT**. Individual choices added later to an older event are marked **NEW**.*

*Edit the prose between the anchors. Headings, ids and the mechanical lines under each choice are generated — edits there are lost.*

---

## the_pit

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | the_pit | title -->
The Pit
<!--@end-->


**Body**

<!--@ domain_events.json | the_pit | text -->
The path descends into a vast muddy hollow. Dozens of mudlings — squat, glistening figures of animated muck — mill about in the thick brown sludge below. They have a crude camp of sorts: stacked bones, offerings of rusted metal, a clumsily drawn circle of wet earth in the center.

One large mudling turns its featureless face toward you. A sound like bubbling tar rises from its throat. The others still.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ domain_events.json | the_pit | choices.fight.text -->
Attack. Clear the pit.
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: mudling_colony  ·  difficulty: hard  ·  karma: hell+5, asura+3`

<!--@ domain_events.json | the_pit | choices.fight.outcome.text -->

<!--@end-->


#### **bribe** — *grey*

<!--@ domain_events.json | the_pit | choices.bribe.text -->
Offer most of your food stores as tribute — seeds, grain, everything you can carry forward.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: mud_domain_shop  ·  karma: animal+4, human+3`

<!--@ domain_events.json | the_pit | choices.bribe.outcome.text -->
The large mudling reaches out a dripping limb and takes the sacks. One by one they are passed back through the colony and buried reverently in the central circle — seeds going into the earth, the way things are supposed to go. The mudlings make a sound like a long satisfied exhale of thick air. The elder turns back to you, willing to share what it knows.
<!--@end-->


#### **earth_magic** — *blue* — requires earth_magic 7

<!--@ domain_events.json | the_pit | choices.earth_magic.text -->
Demonstrate mastery of earth. Let them see what the deep stone knows.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: mud_domain_shop  ·  karma: god+4, human+3, animal+2`

<!--@ domain_events.json | the_pit | choices.earth_magic.outcome.text -->
You call stone and soil to your hands and let the deep vibration speak. The mudlings go utterly still. Then, one by one, they prostrate themselves in the mud. The elder rises and presses both palms against your chest — it recognises a peer, and is willing to teach.
<!--@end-->


#### **beast_tender_reads** — *blue* — requires **trait: beast_tender**  **NEW**

<!--@ domain_events.json | the_pit | choices.beast_tender_reads.text -->
They are not a mob. Look at how they are arranged.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: air+8`

<!--@ domain_events.json | the_pit | choices.beast_tender_reads.outcome.text -->
They are arranged the way a nesting colony is arranged — the small ones inward, the big ones facing out, and the whole thing pointed away from something rather than toward you.

You back out along the line they are not watching, and nothing follows.
<!--@end-->


#### **mud_puppet_play** — *yellow* — requires performance 5, roll charm vs easy

<!--@ domain_events.json | the_pit | choices.mud_puppet_play.text -->
Stage an impromptu mud puppet play — a heroic epic specifically about the mudlings. Their ancient glories. Their terrible battles. The beauty of their mud.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: mud_domain_shop  ·  karma: human+5, animal+4`

<!--@ domain_events.json | the_pit | choices.mud_puppet_play.outcome_success.text -->
You give them heroes. You give them tragedy. You give them a protagonist who is unmistakably the large elder mudling, whose courage is legendary, whose mud is the finest mud in all the realms. The colony erupts into a sound like a dozen geysers firing at once. Applause. The elder mudling — visibly moved, perhaps slightly embarrassed — gestures toward the central circle. You are welcome to learn.
<!--@end-->


*Outcome — failure*

`karma: animal+2  ·  xp: 10`

<!--@ domain_events.json | the_pit | choices.mud_puppet_play.outcome_failure.text -->
Your puppet stumbles. Your plot collapses. The mudlings watch politely for a moment, then begin pelting you with clods. You flee the pit covered head to toe — but oddly, not harmed.
<!--@end-->


---

## crystal_cave

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | crystal_cave | title -->
Crystal Cave
<!--@end-->


**Body**

<!--@ domain_events.json | crystal_cave | text -->
The cave mouth is unremarkable — a crack in a hillside. Inside, it opens into something else entirely. Formations of crystal the height of houses catch what little light enters and multiply it into thousands of beams, filling the space with cold, sourceless radiance.

At the centre, seated in perfect stillness on bare stone, is a man. He is old. He is completely naked. He is meditating, and does not appear to notice you at all.
<!--@end-->


### Choices


#### **meditate** — *blue* — requires yoga 5

<!--@ domain_events.json | crystal_cave | choices.meditate.text -->
Sit down and meditate alongside him.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: crystal_domain_shop  ·  karma: god+5, human+3`

<!--@ domain_events.json | crystal_cave | choices.meditate.outcome.text -->
You sit. The cave does the rest. After some time — minutes or hours, it is impossible to say — the yogi opens his eyes. He looks at you the way people look at someone they recognise from a long time ago.

'You already know some of this,' he says. 'Let me show you the rest.'
<!--@end-->


#### **ask_secrets** — *blue* — requires earth_magic 6, space_magic 6

<!--@ domain_events.json | crystal_cave | choices.ask_secrets.text -->
Ask him about the secrets of this cave.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: crystal_domain_shop  ·  karma: god+4, human+2`

<!--@ domain_events.json | crystal_cave | choices.ask_secrets.outcome.text -->
He opens one eye. He looks you over slowly. Then he smiles — not warmly, exactly, but as if amused by something he's been waiting to see.

'You speak the right language,' he says. 'Then you will understand what I am about to tell you.'
<!--@end-->


#### **offerings** — *grey*

<!--@ domain_events.json | crystal_cave | choices.offerings.text -->
Leave him offerings and ask for a blessing.
<!--@end-->


*Outcome*

`karma: god+4, human+3, animal+1  ·  buffs: [{'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}, {'stat': 'focus', 'amount': 2, 'combats_remaining': 1}, {'stat': 'luck', 'amount': 2, 'combats_remaining': 1}]`

<!--@ domain_events.json | crystal_cave | choices.offerings.outcome.text -->
You set down what you have brought — a little gold, a little food — and bow. The yogi does not open his eyes. But something in the cave shifts. The light settles differently on you.

You feel cleaner, somehow. Sharper. You carry the blessing forward.
<!--@end-->


#### **pilgrim_offering** — *blue* — requires **trait: pilgrim**  **NEW**

<!--@ domain_events.json | crystal_cave | choices.pilgrim_offering.text -->
Do the offering properly before asking for anything.
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 20`

<!--@ domain_events.json | crystal_cave | choices.pilgrim_offering.outcome.text -->
You set it out in the correct order, which takes a while and which he watches without comment.

When you finally do ask, he answers as though you had been introduced, rather than as though you had arrived.
<!--@end-->


#### **attack** — *grey*

<!--@ domain_events.json | crystal_cave | choices.attack.text -->
Attack him.
<!--@end-->


*Outcome*

`karma: hell+8, asura+5, human-5, god-5  ·  add_trait: blood_handed`

<!--@ domain_events.json | crystal_cave | choices.attack.outcome.text -->
You raise your weapon. He opens his eyes.

The cave is gone. You are standing on the hillside in the open air. There is no crack in the rock, no crystal, no yogi. Only a very faint impression of sadness that may be yours or may be his — it is difficult to tell.
<!--@end-->


---

## glass_mountain

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | glass_mountain | title -->
Glass Mountain
<!--@end-->


**Body**

<!--@ domain_events.json | glass_mountain | text -->
A mountain of glass rises from the plain — not metaphor, not illusion. Pure fused silica, facets the size of houses catching the light and throwing it in every direction. The surface is perfectly smooth and perfectly vertical. There is no path up. There is no grip.

At the summit, something moves.
<!--@end-->


### Choices


#### **scale** — *yellow* — requires roll finesse vs difficult

<!--@ domain_events.json | glass_mountain | choices.scale.text -->
Attempt to scale the glass face.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: glass_domain_shop  ·  karma: god+3, human+3`

<!--@ domain_events.json | glass_mountain | choices.scale.outcome_success.text -->
Your fingers find edges too fine to see, your weight shifts by instinct rather than thought. Slowly, impossibly, you climb. At the summit: glass spirits drifting in slow, glitching arcs — each movement a fraction out of time with the last, refracting light into cascades that should not be possible. They do not speak. They seem to notice you the way light notices a prism. Something passes between you.
<!--@end-->


*Outcome — failure*

`type: follow_up  ·  follow_up_event: glass_mountain  ·  karma: human+1  ·  hp_loss: {'amount': 'moderate', 'target': 'random'}`

<!--@ domain_events.json | glass_mountain | choices.scale.outcome_failure.text -->
You slip. The glass offers nothing to hold and less to forgive — you slide and tumble, cutting yourself on the way down. The mountain stands unchanged.
<!--@end-->


#### **air_ascent** — *blue* — requires air_magic 5

<!--@ domain_events.json | glass_mountain | choices.air_ascent.text -->
Let the air carry you up.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: glass_domain_shop  ·  karma: god+4, human+2`

<!--@ domain_events.json | glass_mountain | choices.air_ascent.outcome.text -->
You step off the ground and let the wind take you — drifting upward along the face of the mountain, close enough to see your own distorted reflection in every facet. At the summit, glass spirits dance in slow, glitching loops, throwing light in directions that make no sense. One drifts close and holds the shape of something familiar — your face, perhaps, or the memory of one. Then it disperses, chiming softly.
<!--@end-->


#### **earth_speech** — *blue* — requires earth_magic 5

<!--@ domain_events.json | glass_mountain | choices.earth_speech.text -->
Speak to the glass as stone. It was sand once — and before that, it was earth.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: glass_domain_shop  ·  karma: god+4, human+3`

<!--@ domain_events.json | glass_mountain | choices.earth_speech.outcome.text -->
You press your hands to the surface and speak to what it used to be. There is a long moment. Then the glass does not open exactly — it simply stops being a wall in the way that it was. You walk through and up, the mountain permitting. At the summit, glass spirits spiral in their slow broken arcs. They feel very old. They feel like they have been waiting.
<!--@end-->


#### **sing_to_it** — *blue* — requires performance 6

<!--@ domain_events.json | glass_mountain | choices.sing_to_it.text -->
Sing to the mountain.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: glass_domain_shop  ·  karma: god+5, human+4, animal+1  ·  buffs: [{'stat': 'luck', 'amount': 1, 'combats_remaining': 2}]`

<!--@ domain_events.json | glass_mountain | choices.sing_to_it.outcome.text -->
You begin to sing — nothing composed, just what comes. The mountain answers. A harmonic rises from somewhere inside the glass, and then another, and footholds crystallise along the face as if the mountain is remembering how to be climbed. At the summit the glass spirits dance faster for a moment, producing tones you can almost hear. A faint luck settles on you like dust: the mountain was pleased.
<!--@end-->


#### **meditate_at_base** — *blue* — requires yoga 5

<!--@ domain_events.json | glass_mountain | choices.meditate_at_base.text -->
Sit at the base and meditate. Stop trying to climb.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: glass_domain_shop  ·  karma: god+6, human+3  ·  add_trait: beauty_struck`

<!--@ domain_events.json | glass_mountain | choices.meditate_at_base.outcome.text -->
You sit. The mountain does not move. You stop expecting it to. At some point — you cannot say when — you are at the summit, seated in the same posture, and the glass spirits are circling you in their glitching arcs, throwing light across your closed eyelids in patterns that carry meaning. You have not climbed the mountain. You have stopped being someone who needed to.
<!--@end-->


#### **incurious_walks_on** — *blue* — requires **trait: incurious**  **NEW**

<!--@ domain_events.json | glass_mountain | choices.incurious_walks_on.text -->
It is a mountain made of glass. Note it and go around.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: space-8`

<!--@ domain_events.json | glass_mountain | choices.incurious_walks_on.outcome.text -->
You go around. It takes an extra day and involves no revelation of any kind, which is precisely the outcome you were after.
<!--@end-->


#### **beauty_struck_stops** — *blue* — requires **trait: beauty_struck**  **NEW**

<!--@ domain_events.json | glass_mountain | choices.beauty_struck_stops.text -->
Stop. Do not climb it, do not speak to it. Look at it.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: space+12, fire+8`

<!--@ domain_events.json | glass_mountain | choices.beauty_struck_stops.outcome.text -->
You have seen something like this before — that is the trouble with having been struck once. You know what it is you are looking at.

You stay until the light moves off it. Nobody hurries you.
<!--@end-->


#### **admire** — *grey*

<!--@ domain_events.json | glass_mountain | choices.admire.text -->
Stand and look at it for a while. Some things teach by being looked at.
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 15  ·  add_trait: beauty_struck`

<!--@ domain_events.json | glass_mountain | choices.admire.outcome.text -->
You stand at the base of the mountain and look up. The light changes as you watch — slowly, the way a day changes, but condensed. Somewhere in the complexity of the refracted surface is something you cannot name but will not forget.
<!--@end-->


---

## the_smoking_mirror

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | the_smoking_mirror | title -->
The Smoking Mirror
<!--@end-->


**Body**

<!--@ domain_events.json | the_smoking_mirror | text -->
In a clearing where ash drifts like snow, a mirror stands alone — black obsidian framed in tarnished silver, taller than a person, tilted slightly as if to catch a sky it has no interest in showing you.

The surface does not reflect. It smokes. Slow dark coils rise from the glass and dissipate without smell or warmth. Where your reflection should be, there is only depth — and somewhere in that depth, something moves.
<!--@end-->


### Choices


#### **look** — *yellow* — requires roll focus vs normal

<!--@ domain_events.json | the_smoking_mirror | choices.look.text -->
Look into the mirror.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: smoke_domain_shop  ·  karma: human+3, god+2  ·  add_trait: harrowed`

<!--@ domain_events.json | the_smoking_mirror | choices.look.outcome_success.text -->
You hold its gaze. The smoke parts. You see yourself — but wrong: every flaw given a face, every hidden thing laid bare. You do not flinch. Something dissolves, and something else rises in its place. When you look away you understand smoke in a way you did not before. The mirror has nothing more to show you.
<!--@end-->


*Outcome — failure*

`type: shop  ·  shop_id: smoke_domain_shop  ·  karma: human+2, hell+2  ·  attribute_loss: {'which': 'random', 'amount': 1}`

<!--@ domain_events.json | the_smoking_mirror | choices.look.outcome_failure.text -->
You hold its gaze too long. The smoke parts and shows you something you were not ready to see — and a piece of yourself goes with it, drawn into the depth. The knowledge of smoke rises in you regardless. The price was a piece of yourself. The mirror does not seem to care.
<!--@end-->


#### **ritual_mirror** — *blue* — requires ritual 5

<!--@ domain_events.json | the_smoking_mirror | choices.ritual_mirror.text -->
Recognize the mirror for what it is. Hold up your own mirror to face it.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: smoke_domain_shop  ·  karma: god+5, human+3  ·  buffs: [{'stat': 'awareness', 'amount': 1, 'combats_remaining': 2}]`

<!--@ domain_events.json | the_smoking_mirror | choices.ritual_mirror.outcome.text -->
You have seen this described in the old texts: a Tezcatlipoca-mirror, a devourer of reflections. You produce your own mirror — polished bronze, consecrated — and hold it to face the black glass.

The two mirrors lock. The smoke rushes between them in a furious loop, finds no victim, and exhausts itself. The obsidian surface is still. In the silence, the knowledge of smoke rises in you like cooling ash.
<!--@end-->


#### **yoga_recognition** — *blue* — requires yoga 5

<!--@ domain_events.json | the_smoking_mirror | choices.yoga_recognition.text -->
Recognise the mirror for what it is. Don't look at the surface — look at what the surface is doing.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: smoke_domain_shop  ·  karma: god+5, human+3  ·  buffs: [{'stat': 'focus', 'amount': 1, 'combats_remaining': 2}]  ·  add_trait: clear_eyed`

<!--@ domain_events.json | the_smoking_mirror | choices.yoga_recognition.outcome.text -->
You see the mirror without seeing what it shows. The smoke coils and finds no purchase — there is no self presented to be consumed. The mirror continues smoking. You absorb its nature without being changed by its contents.
<!--@end-->


#### **strike** — *grey*

<!--@ domain_events.json | the_smoking_mirror | choices.strike.text -->
Strike the mirror. Whatever is in there, drag it out.
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: smoking_mirror_combat  ·  difficulty: hard  ·  karma: asura+4, hell+3`

<!--@ domain_events.json | the_smoking_mirror | choices.strike.outcome.text -->

<!--@end-->


#### **turn_away** — *grey*

<!--@ domain_events.json | the_smoking_mirror | choices.turn_away.text -->
Turn away. Do not look.
<!--@end-->


*Outcome*


<!--@ domain_events.json | the_smoking_mirror | choices.turn_away.outcome.text -->
You turn your back on it and walk. The smoke coils behind you. Whatever it wanted to show you, it keeps.
<!--@end-->


---

## cloud_palace

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | cloud_palace | title -->
The Cloud Palace
<!--@end-->


**Body**

<!--@ domain_events.json | cloud_palace | text -->
A palace materialises before you — or perhaps you have drifted into it without noticing. Its halls are open to the sky, its floors are cloud made solid underfoot. Through gaps in the floor, far below, you can see the tops of mountains. Through gaps in the ceiling, open sky.

Slithering through the amber light, singing to one another in voices like slow rain on stone, are nagas — a rare breed that rules the clouds and weather. Vast and iridescent, utterly absorbed in their song. They have not yet noticed you.
<!--@end-->


### Choices


#### **join_chorus** — *blue* — requires performance 6

<!--@ domain_events.json | cloud_palace | choices.join_chorus.text -->
Listen carefully and join their chorus.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: cloud_domain_shop  ·  karma: god+5, human+4, animal+2`

<!--@ domain_events.json | cloud_palace | choices.join_chorus.outcome.text -->
You find the thread of the melody and follow it in. One naga turns a great head toward you — eyes like water, expression unreadable — and then returns to the song. You have been included. When the chorus ends, the nagas coil and settle, regarding you with something that might be warmth. There are things they are willing to teach.
<!--@end-->


#### **offerings** — *blue* — requires ritual 3

<!--@ domain_events.json | cloud_palace | choices.offerings.text -->
Listen in, then step forward and set out offerings: fruits, perfumed water, their favourite herbs and spices.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: cloud_domain_shop  ·  karma: god+4, human+3, animal+3`

<!--@ domain_events.json | cloud_palace | choices.offerings.outcome.text -->
The song does not stop, but it shifts — a new note braided in, low and enquiring. One naga descends to inspect the offerings. It touches each item with the tip of its tongue. A long pause. Then it looks at you with those water-coloured eyes and the song shifts again, opening a space for you to enter. You have been acknowledged. They are willing to share something of what they know.
<!--@end-->


#### **talk_to_them** — *grey*

<!--@ domain_events.json | cloud_palace | choices.talk_to_them.text -->
Walk inside and try to talk to them.
<!--@end-->


*Outcome*

`type: follow_up  ·  follow_up_event: cloud_palace_inner`

<!--@ domain_events.json | cloud_palace | choices.talk_to_them.outcome.text -->
You step through into the heart of the palace. The song reverberates in your chest. The nagas slither in vast arcs around the pillars, absorbed completely in their chorus — and then, one by one, they notice you.
<!--@end-->


#### **pocket_jewels** — *grey*

<!--@ domain_events.json | cloud_palace | choices.pocket_jewels.text -->
Walk inside and try to pocket some of their jewels while they are distracted.
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: cloud_naga_pack  ·  difficulty: hard  ·  karma: hungry_ghost+6, animal+3, human-3  ·  add_trait: covetous`

<!--@ domain_events.json | cloud_palace | choices.pocket_jewels.outcome.text -->
Your hand closes around something that feels like a frozen raindrop cut into a gem the size of a fist. The song stops.

They are not slow.
<!--@end-->


#### **attack** — *grey*

<!--@ domain_events.json | cloud_palace | choices.attack.text -->
Attack them.
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: cloud_naga_pack  ·  difficulty: hard  ·  karma: hell+8, asura+4, human-4, god-4`

<!--@ domain_events.json | cloud_palace | choices.attack.outcome.text -->
The song stops. The nagas uncoil.
<!--@end-->


---

## cloud_palace_inner

`realm: any  ·  rarity: follow_up_only`

**Title**

<!--@ domain_events.json | cloud_palace_inner | title -->
The Cloud Palace — Inner Hall
<!--@end-->


**Body**

<!--@ domain_events.json | cloud_palace_inner | text -->
The song stops. Every naga in the palace has turned to regard you. The silence is the silence of held weather.

The largest — coiled around a pillar of frozen cloud, scales catching the amber light like hammered silver — opens its mouth.

"Who daresss interrupt the sssong?"
<!--@end-->


### Choices


#### **yoga_harmony** — *blue* — requires yoga 5

<!--@ domain_events.json | cloud_palace_inner | choices.yoga_harmony.text -->
Breathe, settle, and let the song you were interrupting continue through you.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: cloud_domain_shop  ·  karma: god+6, human+3  ·  add_trait: beauty_struck`

<!--@ domain_events.json | cloud_palace_inner | choices.yoga_harmony.outcome.text -->
You close your eyes and stop resisting the sound. The song fills you and passes through you, using you briefly as an instrument. The nagas relax — one by one, they return to their spiralling. The largest turns those water-coloured eyes on you and inclines its head. You have not interrupted the song. You have become, briefly, a part of it. They are willing to teach.
<!--@end-->


#### **persuade** — *blue* — requires persuasion 5

<!--@ domain_events.json | cloud_palace_inner | choices.persuade.text -->
Bow low and explain, with all the words you have, why you have come and what you offer.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: cloud_domain_shop  ·  karma: human+5, god+2`

<!--@ domain_events.json | cloud_palace_inner | choices.persuade.outcome.text -->
You speak carefully and at length. The nagas listen with the patience of creatures that measure time in rainstorms. The large one's tail shifts — once, then again. At last it makes a sound like distant thunder and the others settle.

"Ssso. You have a tongue worth hearing." They are willing to teach.
<!--@end-->


#### **charm_roll** — *yellow* — requires roll charm vs difficult

<!--@ domain_events.json | cloud_palace_inner | choices.charm_roll.text -->
Smile, open your hands, and try to win them over on pure charm.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: cloud_domain_shop  ·  karma: human+4, god+1`

<!--@ domain_events.json | cloud_palace_inner | choices.charm_roll.outcome_success.text -->
You have spent years learning how to walk into rooms that do not want you and leave them differently. The large naga blinks — a slow, contemplative gesture — and something shifts in its posture.

"You," it says, "are either very brave or very foolish." It sounds like a compliment. They are willing to teach.
<!--@end-->


*Outcome — failure*

`buffs: [{'stat': 'constitution', 'amount': -3, 'combats_remaining': 2}]`

<!--@ domain_events.json | cloud_palace_inner | choices.charm_roll.outcome_failure.text -->
The naga stares at you for a long, terrible moment. Then it opens its mouth, and what comes out is not words. It is weather.

When you come back to yourself you are standing outside, alone. The palace is gone. Your bones ache with a deep cold.
<!--@end-->


#### **back_talk** — *grey*

<!--@ domain_events.json | cloud_palace_inner | choices.back_talk.text -->
"Is that any way to treat a guest?"
<!--@end-->


*Outcome*

`karma: human-1  ·  buffs: [{'stat': 'constitution', 'amount': -3, 'combats_remaining': 2}]`

<!--@ domain_events.json | cloud_palace_inner | choices.back_talk.outcome.text -->
There is a pause that contains weather systems.

"A guesssst," the large naga says, very softly, "isss invited."

What comes next is not words. When you come back to yourself you are standing outside. The palace is gone. The sky above is the particular grey of something that has already decided to rain.
<!--@end-->


---

## waterworks

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | waterworks | title -->
The Waterworks
<!--@end-->


**Body**

<!--@ domain_events.json | waterworks | text -->
A low wooden building rises from the mist, every surface slick and steaming. Above the entry hangs a sign painted with a frog holding a cup of tea. Through the latticed panels you can see shapes moving in pale mineral water — people, perhaps, or creatures that resemble them. The smell of cardamom and sulfur drifts toward you.

The door is open.
<!--@end-->


### Choices


#### **bathe** — *grey*

<!--@ domain_events.json | waterworks | choices.bathe.text -->
Pay the entry fee and use the baths
<!--@end-->


*Outcome*

`type: follow_up  ·  follow_up_event: waterworks_inner  ·  karma: human+2  ·  restore: {'hp_percent': 100, 'mana_percent': 100, 'stamina_percent': 100}`

<!--@ domain_events.json | waterworks | choices.bathe.outcome.text -->
You hand over the coins, receive a worn linen towel, and are waved through. The water is exactly the right temperature. Somewhere, a flute plays a tune you almost recognize. When you finally climb out, you feel entirely new.
<!--@end-->


#### **tea_bath** — *blue* — requires **trait: tea_ritualist**  **NEW**

<!--@ domain_events.json | waterworks | choices.tea_bath.text -->
Ask whether they serve tea on the hot side. They will.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+12, fire+5`

<!--@ domain_events.json | waterworks | choices.tea_bath.outcome.text -->
They do, and it is served in the manner of a place that has been serving it to the same twelve people for three hundred years.

You are, briefly, extremely comfortable. It is not an experience this realm offers often.
<!--@end-->


#### **leave** — *grey*

<!--@ domain_events.json | waterworks | choices.leave.text -->
Leave without going in
<!--@end-->


*Outcome*


<!--@ domain_events.json | waterworks | choices.leave.outcome.text -->
You walk on. The sound of splashing water and low voices fades behind you.
<!--@end-->


---

## waterworks_inner

`realm: any  ·  rarity: follow_up_only`

**Title**

<!--@ domain_events.json | waterworks_inner | title -->
The Bathhouse Floor
<!--@end-->


**Body**

<!--@ domain_events.json | waterworks_inner | text -->
Clean, rested, and wrapped in borrowed linen, you survey the room. A pair of river spirits play dice in the corner. Two monks argue quietly over a plate of dumplings. A large toad in a silk robe sips tea with the focused air of someone who has been doing this for several centuries.

On low tables between the pools: small plates of pickled plum, pale cakes, and pale green tea. Nobody looks at you with any particular suspicion.
<!--@end-->


### Choices


#### **treat_everyone** — *grey*

<!--@ domain_events.json | waterworks_inner | choices.treat_everyone.text -->
Order tea and snacks for the whole room — your coin, your treat
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: steam_domain_shop  ·  karma: god+3, human+3`

<!--@ domain_events.json | waterworks_inner | choices.treat_everyone.outcome.text -->
A small stir runs through the room. The toad in the silk robe sets down its cup, turns its enormous amber eyes toward you, and slowly crosses the floor.

'Generosity in a bathhouse,' it says, in a voice like water over smooth stone. 'That's rarer than you'd think.' It settles beside you. 'I know a trick or two. Buy something, and I'll show you.'
<!--@end-->


#### **tall_tales** — *blue* — requires performance 5, comedy 5

<!--@ domain_events.json | waterworks_inner | choices.tall_tales.text -->
Hold the room with tall tales of your travels
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: steam_domain_shop  ·  karma: human+4`

<!--@ domain_events.json | waterworks_inner | choices.tall_tales.outcome.text -->
You begin with the time you crossed the frozen bridge over the River of Ash. By the second story, even the monks have stopped arguing. By the third, the toad in the silk robe is leaning forward with those great amber eyes half-closed in something like delight.

'You've been places,' it says, when you finish. 'I've been a few places myself. A trade seems fair.'
<!--@end-->


#### **gossip_floor** — *blue* — requires **trait: gossip**  **NEW**

<!--@ domain_events.json | waterworks_inner | choices.gossip_floor.text -->
Say nothing and let the room talk over you.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ domain_events.json | waterworks_inner | choices.gossip_floor.outcome.text -->
A bathhouse is the most porous building ever devised. In ninety minutes you learn who is in debt to whom, which official is not returning, and one thing that is very obviously a lie and therefore worth more than the rest of it.
<!--@end-->


#### **scrimper_fee** — *blue* — requires **trait: scrimper**  **NEW**

<!--@ domain_events.json | waterworks_inner | choices.scrimper_fee.text -->
The entry fee is negotiable. It always is.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ domain_events.json | waterworks_inner | choices.scrimper_fee.outcome.text -->
It is not negotiable, and you negotiate it anyway, on the grounds that you will not be using the oils, the towels, or the attendant.

They take a third off to be rid of the conversation.
<!--@end-->


#### **steal** — *yellow* — requires roll thievery vs easy

<!--@ domain_events.json | waterworks_inner | choices.steal.text -->
Slip away and quietly go through the bags left unattended near the changing room
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+4, animal+2  ·  gold: 25  ·  items: ['water_charm_common']`

<!--@ domain_events.json | waterworks_inner | choices.steal.outcome_success.text -->
Everyone is very relaxed and nobody is watching the changing room closely. You move quickly and quietly. Coins, a small charm, and then you're back in your seat before anyone looks up. The dice players argue. The monks argue. The toad sips its tea.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+6`

<!--@ domain_events.json | waterworks_inner | choices.steal.outcome_failure.text -->
You're doing well until a pale hand closes around your wrist. The room goes quiet. In short order you are dressed and deposited outside, the door clicking shut behind you. The painted frog on the sign stares at you with what might be disappointment.
<!--@end-->


---

## snowcapped_hermitage

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | snowcapped_hermitage | title -->
Snow-Capped Hermitage
<!--@end-->


**Body**

<!--@ domain_events.json | snowcapped_hermitage | text -->
On an exposed ridge, in full sight of the howling wind, a group of yogis sit cross-legged in the snow. They wear nothing but thin white linen. Steam rises from their bodies in visible wisps, melting the snow in a circle around each of them.

The oldest sits at the centre, utterly still, eyes open but seeing elsewhere. Slightly apart, the youngest shivers — barely perceptibly, but his toes have gone the faint blue of someone fighting a losing battle with the cold.
<!--@end-->


### Choices


#### **ask_teachings** — *blue* — requires yoga 5

<!--@ domain_events.json | snowcapped_hermitage | choices.ask_teachings.text -->
Approach, bow deeply, and ask for teachings.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: tummo_domain_shop  ·  karma: god+5, human+3`

<!--@ domain_events.json | snowcapped_hermitage | choices.ask_teachings.outcome.text -->
The eldest yogi opens his eyes and regards you for a long moment. He nods once. The youngest, still shivering, looks up at you with something like relief — perhaps he will learn more if you are here too.

The teachings begin.
<!--@end-->


#### **fire_magic** — *yellow* — requires fire_magic 5, roll focus vs easy

<!--@ domain_events.json | snowcapped_hermitage | choices.fire_magic.text -->
You have some knowledge of inner heat yourself. Show them — not as a challenge, because you cannot help it.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: tummo_domain_shop  ·  karma: god+4, human+4`

<!--@ domain_events.json | snowcapped_hermitage | choices.fire_magic.outcome_success.text -->
You let it rise — the warmth from the secret place below the navel, imperfect but real. The youngest yogi's eyes go wide. The eldest smiles: not at the technique, which is rough, but at the unmistakable sincerity behind it.

'You have found the door,' he says. 'Come, let us show you what is behind it.'
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  buffs: [{'stat': 'focus', 'amount': 2, 'combats_remaining': 2}]`

<!--@ domain_events.json | snowcapped_hermitage | choices.fire_magic.outcome_failure.text -->
The warmth flickers and goes out. The eldest yogi watches, patient and kind.

'The fire is there,' he says. 'But it needs tending before it can burn steadily. The doors of this hermitage will be open to you when you return, more mature in your practice, young sadhaka.'

Something in his words leaves a warmth in you that your technique could not produce.
<!--@end-->


#### **water_challenge** — *yellow* — requires water_magic 5, roll focus vs difficult

<!--@ domain_events.json | snowcapped_hermitage | choices.water_challenge.text -->
Challenge them to a contest of cold resistance. They seem so untouchable — surely it cannot hurt to test them.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: tummo_domain_shop  ·  karma: asura+3, human-1`

<!--@ domain_events.json | snowcapped_hermitage | choices.water_challenge.outcome_success.text -->
Your mastery of water is formidable — the cold bends to your will, and the youngest yogi has gone very still watching you. The eldest meets your eyes throughout, unshaken.

'Impressive,' he says at last. 'But your attitude is poisoned by arrogance. What you sought was not knowledge — it was victory. We will teach you anyway, because the fire does not care why you came, only that you did. But you will pay more for what arrogance has cost.'
<!--@end-->


*Outcome — failure*

`karma: asura+2, human-1`

<!--@ domain_events.json | snowcapped_hermitage | choices.water_challenge.outcome_failure.text -->
The cold defeats you well before it touches them. The eldest yogi says nothing for a long time. When he speaks, there is no cruelty in it.

'You are not ready for the dharma taught in this place. Return once your merit grows.'
<!--@end-->


#### **sit_in_snow** — *yellow* — requires roll constitution vs normal

<!--@ domain_events.json | snowcapped_hermitage | choices.sit_in_snow.text -->
Say nothing. Sit down in the snow beside them and see how long you last.
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: tummo_domain_shop  ·  karma: human+5, god+2`

<!--@ domain_events.json | snowcapped_hermitage | choices.sit_in_snow.outcome_success.text -->
You have no technique. You have only stubbornness and the refusal to move. Minutes pass. The cold becomes a presence, then a voice, then a kind of silence. When you open your eyes, the eldest is looking at you.

'No technique,' he says, 'but something that technique cannot give. Sit closer. There is something we can show you.'
<!--@end-->


*Outcome — failure*

`karma: human+1  ·  buffs: [{'stat': 'constitution', 'amount': -2, 'combats_remaining': 2}]`

<!--@ domain_events.json | snowcapped_hermitage | choices.sit_in_snow.outcome_failure.text -->
The cold defeats you. You last longer than seems reasonable, but it defeats you. The youngest yogi — still shivering himself, toes still blue — gives you a small, sympathetic look as you scramble to your feet.

You carry the cold in your bones for a while after.
<!--@end-->


#### **circumambulate** — *grey*

<!--@ domain_events.json | snowcapped_hermitage | choices.circumambulate.text -->
Circumambulate the group, set out small offerings, and leave them in peace.
<!--@end-->


*Outcome*

`karma: god+3, human+3  ·  buffs: [{'stat': 'constitution', 'amount': 2, 'combats_remaining': 2}, {'stat': 'focus', 'amount': 2, 'combats_remaining': 2}]`

<!--@ domain_events.json | snowcapped_hermitage | choices.circumambulate.outcome.text -->
You walk the circle three times, quietly, and place what you have brought at the edge of their warmth. None of them acknowledge this directly. But as you turn to leave, the youngest yogi's shivering has stopped.

Something of their steadiness travels with you.
<!--@end-->


#### **ascetic_sits** — *blue* — requires **trait: ascetic**  **NEW**

<!--@ domain_events.json | snowcapped_hermitage | choices.ascetic_sits.text -->
You have sat in worse for less reason.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+12, space+10`

<!--@ domain_events.json | snowcapped_hermitage | choices.ascetic_sits.outcome.text -->
You sit. The cold does what cold does and you let it, and at some point the distinction between enduring it and not minding it stops being available.

One of them opens their eyes at the end and gives you a single nod, which appears to be the local currency.
<!--@end-->


#### **leave** — *grey*

<!--@ domain_events.json | snowcapped_hermitage | choices.leave.text -->
Leave them to their practice.
<!--@end-->


*Outcome*


<!--@ domain_events.json | snowcapped_hermitage | choices.leave.outcome.text -->
You walk on. The sound of the wind returns. The steam rising from their circle diminishes behind you.
<!--@end-->


---

## dark_cave

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | dark_cave | title -->
Dark Cave
<!--@end-->


**Body**

<!--@ domain_events.json | dark_cave | text -->
No light reaches the depths of this cave. The darkness is not empty — it has a quality to it, a density that suggests something is happening inside it.

At the back wall, barely visible, is a small opening the size of a fist. Beside it, a shallow bowl, worn smooth.
<!--@end-->


### Choices


#### **ask_teachings** — *grey*

<!--@ domain_events.json | dark_cave | choices.ask_teachings.text -->
Ask her for teachings.
<!--@end-->


*Outcome*

`type: follow_up  ·  follow_up_event: dark_cave_interior`

<!--@ domain_events.json | dark_cave | choices.ask_teachings.outcome.text -->
A voice comes from the other side of the wall — unhurried, neither welcoming nor unwelcoming.

'The dark will teach you, if you sit with it long enough.'

Silence.
<!--@end-->


#### **yoga_sit** — *blue* — requires yoga 5

<!--@ domain_events.json | dark_cave | choices.yoga_sit.text -->
Sit on this side of the wall and wait. Without expectation.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: luminosity_domain_shop  ·  karma: god+6, human+3`

<!--@ domain_events.json | dark_cave | choices.yoga_sit.outcome.text -->
You sit. The dark settles around you. Visions begin — first muddled and confused, images and sounds without coherence, then gradually clarifying, like sediment falling through still water.

After some hours, a quiet laugh from the other side of the wall.

'You've shown the purity of your intent. I'll teach you a little — but keep practicing on your own.'
<!--@end-->


#### **space_perception** — *blue* — requires space_magic 5

<!--@ domain_events.json | dark_cave | choices.space_perception.text -->
Still your perception. Not the stone — the quality of what is in the stone.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: luminosity_domain_shop  ·  karma: god+5, human+3`

<!--@ domain_events.json | dark_cave | choices.space_perception.outcome.text -->
You let your perception settle and expand. The stone is there — cold, dense, indifferent. And then, not through it but somehow alongside it: a quality of light that is not light, sourceless, neither warm nor cold, bleeding outward through the rock without diminishing.

A pause from the other side of the wall. Then, quietly: 'I see you have some eyes of your own.' The sound of something being moved. 'Come then. Let's compare notes.'
<!--@end-->


#### **push_food** — *grey*

<!--@ domain_events.json | dark_cave | choices.push_food.text -->
Push some food through the opening in the wall.
<!--@end-->


*Outcome*

`karma: god+3, human+3  ·  buffs: [{'stat': 'awareness', 'amount': 1, 'combats_remaining': 2}, {'stat': 'luck', 'amount': 1, 'combats_remaining': 2}]  ·  add_trait: generous`

<!--@ domain_events.json | dark_cave | choices.push_food.outcome.text -->
'Thank you, child.'

The bowl on your side is already empty. On the other side, the sound of something being received with care.
<!--@end-->


#### **push_money** — *grey*

<!--@ domain_events.json | dark_cave | choices.push_money.text -->
Push some money through the opening in the wall.
<!--@end-->


*Outcome*

`gold_returned: True`

<!--@ domain_events.json | dark_cave | choices.push_money.outcome.text -->
A pause.

'I don't need this, child.'

The coins reappear in the bowl on your side, one by one.
<!--@end-->


#### **secret_bearer_waits** — *blue* — requires **trait: secret_bearer**  **NEW**

<!--@ domain_events.json | dark_cave | choices.secret_bearer_waits.text -->
She has not spoken in thirty years. You can manage an hour.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: space+12`

<!--@ domain_events.json | dark_cave | choices.secret_bearer_waits.outcome.text -->
You wait. You do not fill the silence, which is apparently the examination.

What comes through the wall eventually is four words long. You will be thinking about it for some time.
<!--@end-->


#### **leave** — *grey*

<!--@ domain_events.json | dark_cave | choices.leave.text -->
Leave the cave.
<!--@end-->


*Outcome*


<!--@ domain_events.json | dark_cave | choices.leave.outcome.text -->
You step back into the light. The cave says nothing. The darkness continues its practice without you.
<!--@end-->


---

## dark_cave_interior

`realm: any  ·  rarity: follow_up_only`

**Title**

<!--@ domain_events.json | dark_cave_interior | title -->
Dark Cave
<!--@end-->


**Body**

<!--@ domain_events.json | dark_cave_interior | text -->
The silence continues. The darkness has the same quality as before — dense, inhabited. The small opening in the wall. The worn bowl.
<!--@end-->


### Choices


#### **yoga_sit** — *blue* — requires yoga 5

<!--@ domain_events.json | dark_cave_interior | choices.yoga_sit.text -->
Sit on this side of the wall and wait. Without expectation.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: luminosity_domain_shop  ·  karma: god+6, human+3`

<!--@ domain_events.json | dark_cave_interior | choices.yoga_sit.outcome.text -->
You sit. The dark settles around you. Visions begin — first muddled and confused, images and sounds without coherence, then gradually clarifying, like sediment falling through still water.

After some hours, a quiet laugh from the other side of the wall.

'You've shown the purity of your intent. I'll teach you a little — but keep practicing on your own.'
<!--@end-->


#### **space_perception** — *blue* — requires space_magic 5

<!--@ domain_events.json | dark_cave_interior | choices.space_perception.text -->
Still your perception. Not the stone — the quality of what is in the stone.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: luminosity_domain_shop  ·  karma: god+5, human+3`

<!--@ domain_events.json | dark_cave_interior | choices.space_perception.outcome.text -->
You let your perception settle and expand. The stone is there — cold, dense, indifferent. And then, not through it but somehow alongside it: a quality of light that is not light, sourceless, neither warm nor cold, bleeding outward through the rock without diminishing.

A pause from the other side of the wall. Then, quietly: 'I see you have some eyes of your own.' The sound of something being moved. 'Come then. Let's compare notes.'
<!--@end-->


#### **push_food** — *grey*

<!--@ domain_events.json | dark_cave_interior | choices.push_food.text -->
Push some food through the opening in the wall.
<!--@end-->


*Outcome*

`karma: god+3, human+3  ·  buffs: [{'stat': 'awareness', 'amount': 1, 'combats_remaining': 2}, {'stat': 'luck', 'amount': 1, 'combats_remaining': 2}]`

<!--@ domain_events.json | dark_cave_interior | choices.push_food.outcome.text -->
'Thank you, child.'

The bowl on your side is already empty. On the other side, the sound of something being received with care.
<!--@end-->


#### **push_money** — *grey*

<!--@ domain_events.json | dark_cave_interior | choices.push_money.text -->
Push some money through the opening in the wall.
<!--@end-->


*Outcome*

`gold_returned: True`

<!--@ domain_events.json | dark_cave_interior | choices.push_money.outcome.text -->
A pause.

'I don't need this, child.'

The coins reappear in the bowl on your side, one by one.
<!--@end-->


#### **leave** — *grey*

<!--@ domain_events.json | dark_cave_interior | choices.leave.text -->
Leave the cave.
<!--@end-->


*Outcome*


<!--@ domain_events.json | dark_cave_interior | choices.leave.outcome.text -->
You step back into the light. The cave says nothing. The darkness continues its practice without you.
<!--@end-->


---

## skygazing_gompa

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | skygazing_gompa | title -->
Skygazing Gompa
<!--@end-->


**Body**

<!--@ domain_events.json | skygazing_gompa | description -->
On the open terrace of a small gompa, a yogi sits gazing single-pointedly at the sky. A soft rainbow shimmer is reflected in their eyes. As you approach, they smile and greet you with a gesture.
<!--@end-->


### Choices


#### **teach_perfection** — *blue* — requires yoga 5

<!--@ domain_events.json | skygazing_gompa | choices.teach_perfection.text -->
"Please teach us about the Great Perfection."
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: rainbow_domain_shop  ·  add_trait: touched_by_grace`

<!--@ domain_events.json | skygazing_gompa | choices.teach_perfection.outcome.text -->
Gladly, the yogi explains the workings of the mind as swirling reflections of rainbow light in a crystalline prism. The teaching opens doors you did not know were closed.
<!--@end-->


#### **bless_us** — *grey*

<!--@ domain_events.json | skygazing_gompa | choices.bless_us.text -->
"Please bless us for this life and the next, master."
<!--@end-->


*Outcome*

`buffs: [{'stat': 'awareness', 'amount': 2, 'combats_remaining': 2}]`

<!--@ domain_events.json | skygazing_gompa | choices.bless_us.outcome.text -->
The yogi's eyes soften. They place their hands together and murmur a mantra, then touch each of you lightly on the crown of the head. A warmth radiates outward.
<!--@end-->


#### **source_of_shimmer** — *blue* — requires space_magic 5

<!--@ domain_events.json | skygazing_gompa | choices.source_of_shimmer.text -->
"What is the source of the shimmer in your eyes I can't help but notice, master?"
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: rainbow_domain_shop`

<!--@ domain_events.json | skygazing_gompa | choices.source_of_shimmer.outcome.text -->
The yogi just laughs — a clear, boundless sound — and gestures you inside. There, arranged on low tables, are things you have never seen offered anywhere else.
<!--@end-->


#### **what_are_you_doing** — *grey*

<!--@ domain_events.json | skygazing_gompa | choices.what_are_you_doing.text -->
"What are you doing here?"
<!--@end-->


*Outcome*

`xp: 10`

<!--@ domain_events.json | skygazing_gompa | choices.what_are_you_doing.outcome.text -->
"Observing the unceasing movement of the stream of the sky, friend." The yogi says nothing more, but the simplicity of the answer lingers with you long after you leave.
<!--@end-->


#### **lapsed_asks** — *blue* — requires **trait: lapsed**  **NEW**

<!--@ domain_events.json | skygazing_gompa | choices.lapsed_asks.text -->
Ask the question you stopped asking years ago.
<!--@end-->


*Outcome*

`xp: 15  ·  remove_trait: lapsed  ·  pressure: space+15`

<!--@ domain_events.json | skygazing_gompa | choices.lapsed_asks.outcome.text -->
It comes out badly. It comes out, which is more than it has done in a long while.

The answer does not resolve anything. It does establish, quite gently, that the question was always allowed.
<!--@end-->


#### **bow_and_leave** — *grey*

<!--@ domain_events.json | skygazing_gompa | choices.bow_and_leave.text -->
Bow, place some offerings, and leave.
<!--@end-->


*Outcome*

`buffs: [{'stat': 'luck', 'amount': 1, 'combats_remaining': 1}]`

<!--@ domain_events.json | skygazing_gompa | choices.bow_and_leave.outcome.text -->
You place what you can afford at the foot of the yogi's seat. They incline their head in acknowledgment. A faint warmth accompanies you as you descend the terrace steps.
<!--@end-->


---

## court_of_the_musician_prince

`realm: any  ·  rarity: rare`

**Title**

<!--@ domain_events.json | court_of_the_musician_prince | title -->
The Court of the Musician Prince
<!--@end-->


**Body**

<!--@ domain_events.json | court_of_the_musician_prince | text -->
A lavish building rises before you, its doors open to the warm air. Inside, a half-naked man sits in a carved chair, eyes closed, strumming a sitar with total absorption. He does not appear to notice your arrival.

A servant materializes at your elbow, inclining his head politely. 'Welcome. How may I serve you?'
<!--@end-->


### Choices


#### **ask_about_prince** — *grey*

<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_about_prince.text -->
Ask about the prince and the state of his court.
<!--@end-->


*Outcome*

`xp: 10`

<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_about_prince.outcome.text -->
'My lord always had the soul of an artist first, and ruler only second,' the servant says, with unmistakable pride. 'Some years ago, an itinerant yogi came to court and taught him that the path to awakening need not pass through renunciation — that music itself, heard rightly, is a door. The yogi has since moved on, as such men do. My lord has not moved at all.'

He glances toward the prince with something between concern and devotion. 'We manage.'
<!--@end-->


#### **play_with_prince** — *blue* — requires performance 5

<!--@ domain_events.json | court_of_the_musician_prince | choices.play_with_prince.text -->
Take out your instrument and play alongside him.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: sound_domain_shop  ·  karma: human+5, god+3`

<!--@ domain_events.json | court_of_the_musician_prince | choices.play_with_prince.outcome.text -->
The servant hesitates, then steps aside. You take a seat near the prince and begin to play. A long moment passes. Then, without opening his eyes, the prince adjusts his melody to harmonize with yours — a conversation with no words in it. When you finally stop, he opens his eyes and looks at you directly for the first time.

'Stay a while,' he says. 'I have something to show you.'
<!--@end-->


#### **meditate_on_music** — *blue* — requires yoga 5

<!--@ domain_events.json | court_of_the_musician_prince | choices.meditate_on_music.text -->
Sit and listen. Not to the notes — to what is between them.
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: sound_domain_shop  ·  karma: god+5, human+3`

<!--@ domain_events.json | court_of_the_musician_prince | choices.meditate_on_music.outcome.text -->
You find a place to sit and simply listen. The music is complex past comprehension — and then, quite suddenly, it isn't. You hear through it to something else: the source of the sound, the silence inside each note. After some time, the prince opens one eye. He looks at you with faint surprise, then nods curtly, as if settling a question he had been asking himself.

'Yes,' he says. 'Come.'
<!--@end-->


#### **ask_for_job** — *grey*

<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_for_job.text -->
Ask if they need any hired hands.
<!--@end-->


*Outcome*


<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_for_job.outcome.text -->
'I'm afraid my lord has very little in the way of worldly affairs to attend to anymore,' the servant says, pleasantly but with a finality that suggests the topic is closed.
<!--@end-->


#### **ask_for_donation** — *grey*

<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_for_donation.text -->
Ask if they could spare anything for travelers.
<!--@end-->


*Outcome*

`gold: 8`

<!--@ domain_events.json | court_of_the_musician_prince | choices.ask_for_donation.outcome.text -->
The servant blinks, as if the question has surprised him from a great distance. He produces a few coins from somewhere about his person and presses them into your hand with the vague goodwill of someone performing a gesture they have been taught. You find yourself outside. The door closes quietly.
<!--@end-->


#### **poet_answers** — *blue* — requires **trait: poet**  **NEW**

<!--@ domain_events.json | court_of_the_musician_prince | choices.poet_answers.text -->
He is playing a form. Answer it in the form.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+10, air+10`

<!--@ domain_events.json | court_of_the_musician_prince | choices.poet_answers.outcome.text -->
You do not have his hands. You do have the shape of the thing, and you give him back the second half of a line he had left open — badly, in the wrong metre, and unmistakably the right line.

He stops playing. Then he starts again, from your version.
<!--@end-->


#### **braggart_court** — *blue* — requires **trait: braggart**  **NEW**

<!--@ domain_events.json | court_of_the_musician_prince | choices.braggart_court.text -->
Tell the court who has just arrived.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ domain_events.json | court_of_the_musician_prince | choices.braggart_court.outcome.text -->
The court is composed entirely of people who do this professionally, and they recognise a colleague.

You are given a seat, a drink, and a reputation you will have to spend the rest of the evening defending.
<!--@end-->


#### **leave** — *grey*

<!--@ domain_events.json | court_of_the_musician_prince | choices.leave.text -->
Leave without disturbing them.
<!--@end-->


*Outcome*


<!--@ domain_events.json | court_of_the_musician_prince | choices.leave.outcome.text -->
You step back into the open air. Inside, the music continues without interruption.
<!--@end-->


---

## camp_night_vision

`realm: any  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_night_vision | title -->
A Dream Between Watches
<!--@end-->


**Body**

<!--@ domain_events.json | camp_night_vision | description -->
In the deep hours of the night, one of the party stirs from sleep with something vivid and strange behind their eyes.
<!--@end-->


### Choices


#### **remember** — *blue* — requires yoga 3

<!--@ domain_events.json | camp_night_vision | choices.remember.text -->
Hold onto the vision — it felt like a warning.
<!--@end-->


*Outcome*

`karma: hell-5  ·  xp: 20`

<!--@ domain_events.json | camp_night_vision | choices.remember.outcome.text -->
The image is clear: a path, a figure, a moment yet to come. Whether prophecy or fancy, it burns itself into memory. The dreamer rises feeling purposeful.
<!--@end-->


#### **ignore** — *grey*

<!--@ domain_events.json | camp_night_vision | choices.ignore.text -->
Let it fade — dreams are just noise.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_night_vision | choices.ignore.outcome.text -->
By morning it is gone. Just a dream, probably. The camp breaks in ordinary silence.
<!--@end-->


---

## camp_wandering_spirit

`realm: any  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_wandering_spirit | title -->
A Visitor in the Night
<!--@end-->


**Body**

<!--@ domain_events.json | camp_wandering_spirit | description -->
The fire has burned low. In the outer dark, something moves — not threatening, not quite gone. A presence lingers at the edge of the light.
<!--@end-->


### Choices


#### **offer_food** — *grey*

<!--@ domain_events.json | camp_wandering_spirit | choices.offer_food.text -->
Leave a small offering of food at the fire's edge.
<!--@end-->


*Outcome*

`karma: hungry_ghost-10`

<!--@ domain_events.json | camp_wandering_spirit | choices.offer_food.outcome.text -->
In the morning, the offering is gone. The camp feels lighter somehow. Something difficult has passed through and moved on.
<!--@end-->


#### **speak_to_it** — *blue* — requires ritual 2

<!--@ domain_events.json | camp_wandering_spirit | choices.speak_to_it.text -->
Speak to it — ask what it wants.
<!--@end-->


*Outcome*

`karma: hungry_ghost-15  ·  xp: 10`

<!--@ domain_events.json | camp_wandering_spirit | choices.speak_to_it.outcome.text -->
It does not answer with words, but it turns toward the sound of your voice and then recedes, as if the acknowledgement itself was enough. A small thing done well.
<!--@end-->


#### **mourner_receives** — *blue* — requires **trait: mourner**  **NEW**

<!--@ domain_events.json | camp_wandering_spirit | choices.mourner_receives.text -->
Set out a place for it. Properly.
<!--@end-->


*Outcome*

`karma: hungry_ghost-5, human+3  ·  xp: 20  ·  pressure: water+12`

<!--@ domain_events.json | camp_wandering_spirit | choices.mourner_receives.outcome.text -->
You do it the way it is done at home: a place, not an offering. Somewhere to sit rather than something to take.

It sits. That appears to have been the whole request, and in the morning the fire has burned down more slowly than it should have.
<!--@end-->


#### **ward_off** — *grey*

<!--@ domain_events.json | camp_wandering_spirit | choices.ward_off.text -->
Drive it off with noise and light.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_wandering_spirit | choices.ward_off.outcome.text -->
It retreats into the dark. The camp is quiet after, but something about the night feels heavier.
<!--@end-->


---

## camp_fire_omen

`realm: hell  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_fire_omen | title -->
Figures in the Smoke
<!--@end-->


**Body**

<!--@ domain_events.json | camp_fire_omen | description -->
The campfire flares without fuel. In the smoke, shapes coil and reform — faces, or something like faces — watching.
<!--@end-->


### Choices


#### **read_omen** — *yellow* — requires roll awareness vs 14

<!--@ domain_events.json | camp_fire_omen | choices.read_omen.text -->
Watch the smoke and try to read it.
<!--@end-->


*Outcome — success*

`xp: 25`

<!--@ domain_events.json | camp_fire_omen | choices.read_omen.outcome_success.text -->
The smoke forms something unmistakable — a path you haven't taken, a face you'll encounter, a moment of decision that has not yet arrived. The fire dims and the vision closes.
<!--@end-->


*Outcome — failure*


<!--@ domain_events.json | camp_fire_omen | choices.read_omen.outcome_failure.text -->
The shapes shift too fast. By the time anything resolves, the fire has died back to coals. You saw something, but cannot say what.
<!--@end-->


#### **extinguish** — *grey*

<!--@ domain_events.json | camp_fire_omen | choices.extinguish.text -->
Smother the fire. You don't want to see.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_fire_omen | choices.extinguish.outcome.text -->
The smoke curls and dissipates into the dark. The camp is cold for the rest of the night. Nothing comes of it, but nothing was risked either.
<!--@end-->


---

## camp_ember_voices

`realm: hell  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_ember_voices | title -->
The Fire Speaks
<!--@end-->


**Body**

<!--@ domain_events.json | camp_ember_voices | description -->
Deep in the night, the campfire rises without reason. Between the popping of burning wood, something close to words — close enough that three people heard three different things.
<!--@end-->


### Choices


#### **listen** — *blue* — requires yoga 2

<!--@ domain_events.json | camp_ember_voices | choices.listen.text -->
Sit quietly and listen for meaning.
<!--@end-->


*Outcome*

`karma: hell+5  ·  xp: 20`

<!--@ domain_events.json | camp_ember_voices | choices.listen.outcome.text -->
The words aren't in any language, but the meaning arrives whole: a route, a danger, a name that matters. Whether this realm is warning you or baiting you, the information feels true.
<!--@end-->


#### **speak_back** — *yellow* — requires roll awareness vs 12

<!--@ domain_events.json | camp_ember_voices | choices.speak_back.text -->
Answer it — ask what it wants.
<!--@end-->


*Outcome — success*

`karma: hell+10  ·  xp: 15`

<!--@ domain_events.json | camp_ember_voices | choices.speak_back.outcome_success.text -->
The fire brightens, then settles. Something received your address. The embers arrange and rearrange in patterns that suggest approval. You feel, briefly, observed and acknowledged.
<!--@end-->


*Outcome — failure*


<!--@ domain_events.json | camp_ember_voices | choices.speak_back.outcome_failure.text -->
The fire goes out. All of it, without smoke or cooling, just gone. It takes a long time to relight. No one speaks much after.
<!--@end-->


#### **ignore** — *grey*

<!--@ domain_events.json | camp_ember_voices | choices.ignore.text -->
It's the heat. Go back to sleep.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_ember_voices | choices.ignore.outcome.text -->
By morning the fire is cold ash. Whether anything was there or not, it is settled now.
<!--@end-->


---

## camp_guardian_threshold

`realm: hell  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_guardian_threshold | title -->
At the Edge of the Light
<!--@end-->


**Body**

<!--@ domain_events.json | camp_guardian_threshold | description -->
Something stands at the very limit of the firelight. It has been there for some time. It is not threatening — it simply waits, in the particular way that a very old grievance waits.
<!--@end-->


### Choices


#### **hear_out** — *blue* — requires persuasion 2

<!--@ domain_events.json | camp_guardian_threshold | choices.hear_out.text -->
Invite it to speak. A grievance aired is one less thing blocking the path.
<!--@end-->


*Outcome*

`karma: hell+15`

<!--@ domain_events.json | camp_guardian_threshold | choices.hear_out.outcome.text -->
It speaks, or something like speaking happens. The story is circular and old — a wrong done long before any of you were born, compounding through each retelling. You acknowledge it without agreeing. The presence recedes satisfied, or at least finished.
<!--@end-->


#### **ward_ritual** — *blue* — requires ritual 2

<!--@ domain_events.json | camp_guardian_threshold | choices.ward_ritual.text -->
Perform a brief warding. Give it a boundary rather than an audience.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_guardian_threshold | choices.ward_ritual.outcome.text -->
The ritual is imperfect but sincere. The presence retreats from the boundary you've established. By morning it is gone, and the camp feels marginally warmer for it.
<!--@end-->


#### **wait_out** — *grey*

<!--@ domain_events.json | camp_guardian_threshold | choices.wait_out.text -->
Watch it until dawn. It has to leave with the light.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_guardian_threshold | choices.wait_out.outcome.text -->
It does leave with the light. One of the party barely slept. The camp breaks in an uneasy silence that no one names.
<!--@end-->


---

## camp_whispered_offering

`realm: hungry_ghost  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_whispered_offering | title -->
What Was Left Out
<!--@end-->


**Body**

<!--@ domain_events.json | camp_whispered_offering | description -->
You wake to find the camp's food supplies disturbed. Nothing taken — but arranged. Placed. A small portion of each item separated from the rest, set near the fire's edge, as if left for someone who didn't eat.
<!--@end-->


### Choices


#### **leave_more** — *grey*

<!--@ domain_events.json | camp_whispered_offering | choices.leave_more.text -->
Leave a proper offering — deliberately, this time.
<!--@end-->


*Outcome*

`karma: hungry_ghost-15`

<!--@ domain_events.json | camp_whispered_offering | choices.leave_more.outcome.text -->
You set it out with care. By the next morning, the portion is gone, and whatever sorted your supplies has not returned.
<!--@end-->


#### **ritual_offering** — *blue* — requires ritual 2

<!--@ domain_events.json | camp_whispered_offering | choices.ritual_offering.text -->
Consecrate the offering properly with a brief ritual.
<!--@end-->


*Outcome*

`karma: hungry_ghost-25  ·  xp: 10`

<!--@ domain_events.json | camp_whispered_offering | choices.ritual_offering.outcome.text -->
Consecrated food reaches further in this realm than it has any right to. The arrangement disappears, and for a moment you catch something at the periphery of the firelight that might have been gratitude.
<!--@end-->


#### **secure** — *grey*

<!--@ domain_events.json | camp_whispered_offering | choices.secure.text -->
Secure the supplies and post a watch.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_whispered_offering | choices.secure.outcome.text -->
Nothing more is disturbed that night. In the morning the small arranged portion is still there, untouched.
<!--@end-->


---

## camp_creditor

`realm: hungry_ghost  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_creditor | title -->
The Outstanding Balance
<!--@end-->


**Body**

<!--@ domain_events.json | camp_creditor | description -->
A figure in a creditor's sash steps into the firelight. It looks like no one in particular. It knows exactly who you are.
<!--@end-->


### Choices


#### **negotiate** — *blue* — requires trade 3

<!--@ domain_events.json | camp_creditor | choices.negotiate.text -->
Enter into negotiation — there is always a way to restructure.
<!--@end-->


*Outcome*

`karma: hungry_ghost-10`

<!--@ domain_events.json | camp_creditor | choices.negotiate.outcome.text -->
Three rounds of negotiation in the cold air. You emerge with an arrangement no one is happy with, which is the mark of a good deal. The creditor departs without incident. The ledger, as far as you can tell, now balances.
<!--@end-->


#### **pay** — *grey*

<!--@ domain_events.json | camp_creditor | choices.pay.text -->
Pay what it asks without argument.
<!--@end-->


*Outcome*

`karma: hungry_ghost-5`

<!--@ domain_events.json | camp_creditor | choices.pay.outcome.text -->
It accepts payment. It looks faintly disappointed that there was nothing to argue about. It leaves. The camp feels lighter.
<!--@end-->


#### **debtor_knows_the_form** — *blue* — requires **trait: debtor**  **NEW**

<!--@ domain_events.json | camp_creditor | choices.debtor_knows_the_form.text -->
You have had this conversation before, with worse.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: air+10`

<!--@ domain_events.json | camp_creditor | choices.debtor_knows_the_form.outcome.text -->
You know the form: never deny the debt, never accept the figure, and always counter-propose a schedule.

It works on the dead as well as it works on the living, which is either reassuring or extremely bleak.
<!--@end-->


#### **refuse** — *grey*

<!--@ domain_events.json | camp_creditor | choices.refuse.text -->
Tell it you don't recognise the debt.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_creditor | choices.refuse.outcome.text -->
It notes this down in a ledger you cannot see. It does not argue. It leaves, which is somehow worse than if it had.
<!--@end-->


---

## camp_shared_dream

`realm: any  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_shared_dream | title -->
The Same Dream
<!--@end-->


**Body**

<!--@ domain_events.json | camp_shared_dream | description -->
In the morning it becomes clear that every member of the party dreamed the same thing. The details vary — but the place, the light, the unspoken pressure of it — identical.
<!--@end-->


### Choices


#### **compare_notes** — *blue* — requires yoga 2

<!--@ domain_events.json | camp_shared_dream | choices.compare_notes.text -->
Sit together and map the differences. There's something in the overlap.
<!--@end-->


*Outcome*

`karma: hell-5, hungry_ghost-5  ·  xp: 25`

<!--@ domain_events.json | camp_shared_dream | choices.compare_notes.outcome.text -->
The point where all accounts agree is a detail no one remarked on individually — a mark, a position, a quality of attention. When you locate it, something like recognition moves through the group. A shared dream properly examined becomes a kind of preparation.
<!--@end-->


#### **write_it_down** — *blue* — requires learning 2

<!--@ domain_events.json | camp_shared_dream | choices.write_it_down.text -->
Record what you remember before it fades.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ domain_events.json | camp_shared_dream | choices.write_it_down.outcome.text -->
Committed to paper, the dream becomes a document. Whether it's useful or not, it's no longer just a feeling in the air between you — it's a record, and records have a way of meaning something eventually.
<!--@end-->


#### **dreamer_leads** — *blue* — requires **trait: dreamer**  **NEW**

<!--@ domain_events.json | camp_shared_dream | choices.dreamer_leads.text -->
You dream like this most nights. Take the lead.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: space+10`

<!--@ domain_events.json | camp_shared_dream | choices.dreamer_leads.outcome.text -->
The others describe a dream. You describe the *shape* of one, which turns out to be the thing they were all failing to say.

Once it has a shape, the differences between the four accounts become the interesting part.
<!--@end-->


#### **move_on** — *grey*

<!--@ domain_events.json | camp_shared_dream | choices.move_on.text -->
Say nothing. Dreams are not decisions.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_shared_dream | choices.move_on.outcome.text -->
The camp breaks in ordinary silence. Whatever the dream was trying to say, it did not say it.
<!--@end-->


---

## camp_stranger_fire

`realm: any  ·  trigger: camp  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | camp_stranger_fire | title -->
Another Light
<!--@end-->


**Body**

<!--@ domain_events.json | camp_stranger_fire | description -->
A light on the hillside — too steady and too warm to be a spirit. Another camp. They haven't signalled, but they haven't hidden either.
<!--@end-->


### Choices


#### **approach** — *yellow* — requires roll charm vs 11

<!--@ domain_events.json | camp_stranger_fire | choices.approach.text -->
Walk over and introduce yourself.
<!--@end-->


*Outcome — success*

`xp: 10  ·  gold: 20`

<!--@ domain_events.json | camp_stranger_fire | choices.approach.outcome_success.text -->
Traders, or something close to traders — three of them, neutral in disposition, willing to part with supplies at a fair price. You part on workmanlike terms.
<!--@end-->


*Outcome — failure*


<!--@ domain_events.json | camp_stranger_fire | choices.approach.outcome_failure.text -->
They receive you with flat unfriendliness. Not hostile — but by the time you've returned to your own fire, you've gained nothing and spent an awkward hour.
<!--@end-->


#### **signal** — *grey*

<!--@ domain_events.json | camp_stranger_fire | choices.signal.text -->
Signal peacefully and wait to see if they respond.
<!--@end-->


*Outcome*


<!--@ domain_events.json | camp_stranger_fire | choices.signal.outcome.text -->
They signal back — a single lamp moved twice. Then nothing more. Whoever they are, they're occupied or cautious. You sleep well enough anyway.
<!--@end-->


#### **gossip_walks_over** — *blue* — requires **trait: gossip**  **NEW**

<!--@ domain_events.json | camp_stranger_fire | choices.gossip_walks_over.text -->
Of course you are going to go and find out who they are.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ domain_events.json | camp_stranger_fire | choices.gossip_walks_over.outcome.text -->
They are three traders, badly lost, and delighted to see anyone at all.

By the time you go back to your own fire you have their route, their prices, and an unflattering account of a guard captain two days ahead.
<!--@end-->


#### **watch** — *blue* — requires logistics 2

<!--@ domain_events.json | camp_stranger_fire | choices.watch.text -->
Keep watch and observe without contact.
<!--@end-->


*Outcome*

`xp: 10`

<!--@ domain_events.json | camp_stranger_fire | choices.watch.outcome.text -->
Their fire goes out before yours. Two of them — moving efficiently, no wasted motion. Scouts or couriers, from their routine. Nothing threatening. The knowledge costs you some sleep but not much.
<!--@end-->


---

## trait_gambler_game  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: gambler  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_gambler_game | title -->
A Game at the Next Fire
<!--@end-->


**Body**

<!--@ domain_events.json | trait_gambler_game | description -->
There is another fire within sight of yours, and around it, the unmistakable rhythm of a game — the pause, the clatter, the noise people make when someone loses badly.

{a} has been looking at it for some time now.
<!--@end-->


### Choices


#### **play_it_safe** — *blue* — requires persuasion 3

<!--@ domain_events.json | trait_gambler_game | choices.play_it_safe.text -->
Let {a} play, but set a limit before they go.
<!--@end-->


*Outcome*

`xp: 15  ·  gold: small`

<!--@ domain_events.json | trait_gambler_game | choices.play_it_safe.outcome.text -->
{a} agrees to the limit with the easy sincerity of someone who has agreed to limits before. This time, remarkably, they keep it — and come back with more than they left with, and with the name of a man who buys things quietly.
<!--@end-->


#### **play_deep** — *yellow* — requires roll luck vs moderate

<!--@ domain_events.json | trait_gambler_game | choices.play_deep.text -->
Let it run. {a} knows what they are doing.
<!--@end-->


*Outcome — success*

`xp: 20  ·  gold: moderate`

<!--@ domain_events.json | trait_gambler_game | choices.play_deep.outcome_success.text -->
It goes late. It goes badly, and then very well, and then the other fire goes quiet in the way fires do when the stranger is winning.

{a} walks back before anyone decides to discuss it further.
<!--@end-->


*Outcome — failure*

`pressure: earth-10`

<!--@ domain_events.json | trait_gambler_game | choices.play_deep.outcome_failure.text -->
The game turns. It turns the way games do when someone else at the fire has also been doing this for years.

{a} comes back with empty hands and a story about the light being bad.
<!--@end-->


#### **forbid** — *grey*

<!--@ domain_events.json | trait_gambler_game | choices.forbid.text -->
Nobody is playing anything. We move at dawn.
<!--@end-->


*Outcome*

`pressure: fire-10`

<!--@ domain_events.json | trait_gambler_game | choices.forbid.outcome.text -->
{a} does not argue, which is worse than arguing. They sit with their back to the other fire for the rest of the night, and are notably unrested in the morning.
<!--@end-->


---

## trait_debtor_collector  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: debtor  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_debtor_collector | title -->
Someone Has Been Asking
<!--@end-->


**Body**

<!--@ domain_events.json | trait_debtor_collector | description -->
A traveller shares your fire for an hour, and mentions, without any particular emphasis, that a man has been asking after someone matching {a}'s description in every settlement between here and the pass.

He is described as patient. That is the word the traveller uses. Patient.
<!--@end-->


### Choices


#### **pay_ahead** — *grey*

<!--@ domain_events.json | trait_debtor_collector | choices.pay_ahead.text -->
Send the money ahead with the traveller.
<!--@end-->


*Outcome*

`pressure: air+15`

<!--@ domain_events.json | trait_debtor_collector | choices.pay_ahead.outcome.text -->
It is most of what you have. The traveller takes it with the blank courtesy of a man who has carried worse.

Whether it arrives is another question, but {a} sleeps properly for the first time in a while.
<!--@end-->


#### **send_word** — *blue* — requires trade 4

<!--@ domain_events.json | trait_debtor_collector | choices.send_word.text -->
Have {a} send word: terms, and a date.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ domain_events.json | trait_debtor_collector | choices.send_word.outcome.text -->
The letter is careful. It admits the debt, proposes a schedule, and contains one line that a certain kind of creditor will recognise as an offer rather than a plea.

The asking stops for a while.
<!--@end-->


#### **ignore_it** — *grey*

<!--@ domain_events.json | trait_debtor_collector | choices.ignore_it.text -->
Let him ask. The world is large.
<!--@end-->


*Outcome*

`pressure: air-12`

<!--@ domain_events.json | trait_debtor_collector | choices.ignore_it.outcome.text -->
The world is large. {a} spends the rest of the night working out exactly how large, and how many roads there are through it, and how few of them a patient man would need to watch.
<!--@end-->


---

## trait_ascetic_fast  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: ascetic  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_ascetic_fast | title -->
The Long Night
<!--@end-->


**Body**

<!--@ domain_events.json | trait_ascetic_fast | description -->
{a} has not eaten since yesterday, and does not intend to eat today either. They have taken the far side of the fire and gone somewhere behind their own face.

It is not clear whether this is discipline or something that has stopped being discipline a while ago.
<!--@end-->


### Choices


#### **sit_with_them** — *grey*

<!--@ domain_events.json | trait_ascetic_fast | choices.sit_with_them.text -->
Sit up with them. Say nothing.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: space+10`

<!--@ domain_events.json | trait_ascetic_fast | choices.sit_with_them.outcome.text -->
You sit. The fire goes down. Around the fourth hour {a} says one sentence about their teacher, and then nothing else, and in the morning something between you has been settled without being discussed.
<!--@end-->


#### **guide_it** — *blue* — requires yoga 4

<!--@ domain_events.json | trait_ascetic_fast | choices.guide_it.text -->
Give the fast a shape — make it a practice, not a punishment.
<!--@end-->


*Outcome*

`xp: 30  ·  pressure: fire+15, space+10`

<!--@ domain_events.json | trait_ascetic_fast | choices.guide_it.outcome.text -->
You give them the frame: the hours, the posture, what to do with the part of the mind that starts bargaining around midnight.

By dawn {a} is hollow-eyed and unmistakably clearer.
<!--@end-->


#### **make_them_eat** — *grey*

<!--@ domain_events.json | trait_ascetic_fast | choices.make_them_eat.text -->
Put food in their hands and stand there until it is gone.
<!--@end-->


*Outcome*

`restore: {'hp_percent': 10}`

<!--@ domain_events.json | trait_ascetic_fast | choices.make_them_eat.outcome.text -->
They eat, because you are standing there. They are steadier for it in the morning and quietly furious with you for three days.
<!--@end-->


---

## trait_secret_bearer_slip  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: secret_bearer  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_secret_bearer_slip | title -->
Nearly Said
<!--@end-->


**Body**

<!--@ domain_events.json | trait_secret_bearer_slip | description -->
Late, with the fire low and everyone half-asleep, {a} begins a sentence.

It is four words long and it stops. Whatever the fifth word was going to be, it has been put back.
<!--@end-->


### Choices


#### **let_it_go** — *grey*

<!--@ domain_events.json | trait_secret_bearer_slip | choices.let_it_go.text -->
Pretend not to have heard.
<!--@end-->


*Outcome*


<!--@ domain_events.json | trait_secret_bearer_slip | choices.let_it_go.outcome.text -->
You let it lie. {a} is grateful in the particular way of someone who has just been spared, and sits a little closer to the fire afterwards.
<!--@end-->


#### **draw_it_out** — *yellow* — requires roll charm vs moderate

<!--@ domain_events.json | trait_secret_bearer_slip | choices.draw_it_out.text -->
Ask gently. Some things want carrying together.
<!--@end-->


*Outcome — success*

`xp: 25  ·  pressure: water+20`

<!--@ domain_events.json | trait_secret_bearer_slip | choices.draw_it_out.outcome_success.text -->
It takes an hour and it costs them something.

What comes out is smaller than you expected and much heavier than it looks, and {a} is a different kind of tired at the end of it — the kind that heals.
<!--@end-->


*Outcome — failure*

`pressure: space-5`

<!--@ domain_events.json | trait_secret_bearer_slip | choices.draw_it_out.outcome_failure.text -->
They talk around it for a while, pleasantly, and tell you nothing at all. By the end you are not certain there was ever a sentence.
<!--@end-->


#### **press_hard** — *grey*

<!--@ domain_events.json | trait_secret_bearer_slip | choices.press_hard.text -->
Push. Whatever it is, it is walking with us.
<!--@end-->


*Outcome*

`pressure: air-10`

<!--@ domain_events.json | trait_secret_bearer_slip | choices.press_hard.outcome.text -->
{a} closes like a door. Whatever was nearly said is now considerably further from being said than it was an hour ago.
<!--@end-->


---

## trait_pilgrim_detour  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: pilgrim  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_pilgrim_detour | title -->
A Stone Off the Road
<!--@end-->


**Body**

<!--@ domain_events.json | trait_pilgrim_detour | description -->
{a} has noticed something the rest of you walked past: a marker stone, half-swallowed, with the remains of offerings at its base.

Someone tended this within living memory. Nobody has for a while.
<!--@end-->


### Choices


#### **tend_it** — *grey*

<!--@ domain_events.json | trait_pilgrim_detour | choices.tend_it.text -->
Clear it properly. It costs an hour.
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 15  ·  pressure: earth+10`

<!--@ domain_events.json | trait_pilgrim_detour | choices.tend_it.outcome.text -->
You clear the base, straighten the stone, leave what can be spared. {a} does the words from memory.

The hour is gone and something about the party's footing is better for the rest of the day.
<!--@end-->


#### **read_it** — *blue* — requires learning 4

<!--@ domain_events.json | trait_pilgrim_detour | choices.read_it.text -->
Read what is carved there.
<!--@end-->


*Outcome*

`xp: 30`

<!--@ domain_events.json | trait_pilgrim_detour | choices.read_it.outcome.text -->
The script is three languages old and mostly worn, but enough survives: a name, a direction, and a warning that was specific once.

{a} copies it down. It will mean something later.
<!--@end-->


#### **walk_on** — *grey*

<!--@ domain_events.json | trait_pilgrim_detour | choices.walk_on.text -->
Note it and keep walking.
<!--@end-->


*Outcome*

`pressure: space-8`

<!--@ domain_events.json | trait_pilgrim_detour | choices.walk_on.outcome.text -->
You keep walking. {a} looks back twice, and then makes a point of not looking back again.
<!--@end-->


---

## trait_beast_tender_stray  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: beast_tender  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_beast_tender_stray | title -->
It Has Decided
<!--@end-->


**Body**

<!--@ domain_events.json | trait_beast_tender_stray | description -->
Something has attached itself to the camp — thin, wary, and entirely certain about which member of the party it intends to belong to.

{a} has already fed it, which settles the matter as far as it is concerned.
<!--@end-->


### Choices


#### **keep_it** — *grey*

<!--@ domain_events.json | trait_beast_tender_stray | choices.keep_it.text -->
It can come. It eats what we can spare.
<!--@end-->


*Outcome*

`karma: animal+4  ·  pressure: water+10, fire+5`

<!--@ domain_events.json | trait_beast_tender_stray | choices.keep_it.outcome.text -->
It comes. It is useless in every way that can be measured and the camp is measurably better for it.
<!--@end-->


#### **send_it_off** — *grey*

<!--@ domain_events.json | trait_beast_tender_stray | choices.send_it_off.text -->
Drive it off before it starves with us.
<!--@end-->


*Outcome*

`pressure: water-10`

<!--@ domain_events.json | trait_beast_tender_stray | choices.send_it_off.outcome.text -->
{a} does it themselves, which is the kindest way it can be done and does not appear to help.
<!--@end-->


#### **put_it_to_work** — *blue* — requires logistics 3

<!--@ domain_events.json | trait_beast_tender_stray | choices.put_it_to_work.text -->
Anything that eats can earn.
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 25`

<!--@ domain_events.json | trait_beast_tender_stray | choices.put_it_to_work.outcome.text -->
Within three days it is walking point, and doing it better than anyone you would have assigned.
<!--@end-->


---

## trait_grudge_bearer_ledger  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: grudge_bearer  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_grudge_bearer_ledger | title -->
The Ledger
<!--@end-->


**Body**

<!--@ domain_events.json | trait_grudge_bearer_ledger | description -->
{a} is awake, and has been for some time, going over something in the dark with the thoroughness of a clerk.

You have seen this before. It is never nothing, and it is never recent.
<!--@end-->


### Choices


#### **hear_it** — *grey*

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.hear_it.text -->
Ask who it is. Let them say the name.
<!--@end-->


*Outcome*

`pressure: water+8`

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.hear_it.outcome.text -->
They say it. Then they say it again, with the details, and the details have not softened by a single degree in however many years it has been.

Saying it out loud does not fix it. It does make the night shorter.
<!--@end-->


#### **cut_it** — *blue* — requires yoga 4

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.cut_it.text -->
Tell them plainly what carrying it is costing.
<!--@end-->


*Outcome*

`xp: 25  ·  pressure: water+15`

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.cut_it.outcome.text -->
It lands badly and then, some hours later, it lands properly.

{a} does not forgive anyone. But they put the ledger down for the night, which is not nothing.
<!--@end-->


#### **sharpen_it** — *grey*

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.sharpen_it.text -->
Let it sharpen. There will be a use for it.
<!--@end-->


*Outcome*

`karma: hell+3  ·  pressure: water-10, fire+5`

<!--@ domain_events.json | trait_grudge_bearer_ledger | choices.sharpen_it.outcome.text -->
You leave them to it. In the morning {a} is rested in the specific way of someone who has spent the night deciding something.
<!--@end-->


---

## trait_scarred_weather  **NEW EVENT**

`realm: any  ·  trigger: trait  ·  requires_trait: scarred  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | trait_scarred_weather | title -->
It Knows the Weather
<!--@end-->


**Body**

<!--@ domain_events.json | trait_scarred_weather | description -->
The cold has got into {a}'s old wound, the way it does, and they are pretending with some effort that it has not.

It will pass by midday. It always passes by midday.
<!--@end-->


### Choices


#### **treat_it** — *blue* — requires medicine 3

<!--@ domain_events.json | trait_scarred_weather | choices.treat_it.text -->
Work on it properly before it stiffens.
<!--@end-->


*Outcome*

`xp: 15  ·  restore: {'hp_percent': 15}`

<!--@ domain_events.json | trait_scarred_weather | choices.treat_it.outcome.text -->
Heat, pressure, and twenty patient minutes. {a} is functional by dawn instead of by noon, and says so in about four words.
<!--@end-->


#### **ask_about_it** — *grey*

<!--@ domain_events.json | trait_scarred_weather | choices.ask_about_it.text -->
Ask how they got it.
<!--@end-->


*Outcome*

`pressure: water+5`

<!--@ domain_events.json | trait_scarred_weather | choices.ask_about_it.outcome.text -->
They tell it flatly, which is how the bad ones get told. It is shorter than you expected and there is a second story underneath it that does not get told tonight.
<!--@end-->


#### **say_nothing** — *grey*

<!--@ domain_events.json | trait_scarred_weather | choices.say_nothing.text -->
Say nothing and set an easy pace tomorrow.
<!--@end-->


*Outcome*

`pressure: earth+8`

<!--@ domain_events.json | trait_scarred_weather | choices.say_nothing.outcome.text -->
You set the pace without mentioning why. {a} notices, and does not mention that either. This is apparently how it is done.
<!--@end-->


---

## rel_rivals_flashpoint  **NEW EVENT**

`realm: any  ·  trigger: relationship  ·  requires_band: rival  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | rel_rivals_flashpoint | title -->
It Has Been Building
<!--@end-->


**Body**

<!--@ domain_events.json | rel_rivals_flashpoint | description -->
{a} and {b} have been circling something for days, and tonight it arrives — over nothing, over a pot and whose turn it was, in the way these things always arrive over nothing.

The rest of the camp has gone very quiet.
<!--@end-->


### Choices


#### **let_them** — *grey*

<!--@ domain_events.json | rel_rivals_flashpoint | choices.let_them.text -->
Let them have it out. Words only.
<!--@end-->


*Outcome*

`pressure: fire-5`

<!--@ domain_events.json | rel_rivals_flashpoint | choices.let_them.outcome.text -->
It is ugly and thorough and it takes about twenty minutes.

At the end of it they are not friends, but the thing that was under the surface is now above it, where everyone can see it, which is safer.
<!--@end-->


#### **mediate** — *blue* — requires persuasion 5

<!--@ domain_events.json | rel_rivals_flashpoint | choices.mediate.text -->
Get between them and make them each say the actual grievance.
<!--@end-->


*Outcome*

`xp: 30  ·  pressure: air+10`

<!--@ domain_events.json | rel_rivals_flashpoint | choices.mediate.outcome.text -->
You make them do it properly, one at a time, no interruptions.

It emerges that they are angry about two entirely different things, and have each spent a week being furious about the wrong one.
<!--@end-->


#### **shut_it_down** — *blue* — requires leadership 4

<!--@ domain_events.json | rel_rivals_flashpoint | choices.shut_it_down.text -->
End it. Both of you, opposite sides of the fire, now.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ domain_events.json | rel_rivals_flashpoint | choices.shut_it_down.outcome.text -->
They obey, because of how you said it.

Nothing is resolved. Nothing gets worse tonight either, which was the immediate problem.
<!--@end-->


---

## rel_sworn_watch  **NEW EVENT**

`realm: any  ·  trigger: relationship  ·  requires_band: sworn  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | rel_sworn_watch | title -->
Second Watch
<!--@end-->


**Body**

<!--@ domain_events.json | rel_sworn_watch | description -->
{a} takes second watch, which is {b}'s. No discussion, no announcement — they simply do not wake them.

In the morning {b} works it out from the burn-down of the fire and says nothing about it, which is its own kind of answer.
<!--@end-->


### Choices


#### **leave_it** — *grey*

<!--@ domain_events.json | rel_sworn_watch | choices.leave_it.text -->
Leave them to it.
<!--@end-->


*Outcome*

`pressure: water+10, earth+5`

<!--@ domain_events.json | rel_sworn_watch | choices.leave_it.outcome.text -->
Whatever the two of them have built, it does not require your supervision. The party moves a little easier for the rest of the week.
<!--@end-->


#### **use_it** — *blue* — requires leadership 4

<!--@ domain_events.json | rel_sworn_watch | choices.use_it.text -->
Two who trust each other that far should be fighting together.
<!--@end-->


*Outcome*

`xp: 30  ·  buffs: [{'stat': 'initiative', 'amount': 3}]`

<!--@ domain_events.json | rel_sworn_watch | choices.use_it.outcome.text -->
You put them on the same flank and spend an evening on what each of them is going to assume the other is doing.

It shows almost immediately.
<!--@end-->


---

## rel_cool_thaw  **NEW EVENT**

`realm: any  ·  trigger: relationship  ·  requires_band: cool  ·  rarity: uncommon`

**Title**

<!--@ domain_events.json | rel_cool_thaw | title -->
Neither of Them Will Say It
<!--@end-->


**Body**

<!--@ domain_events.json | rel_cool_thaw | description -->
{a} and {b} are not fighting. They are doing the other thing — the scrupulous politeness, the passing of the water skin at arm's length.

It has been four days of this and the whole camp is tired of it.
<!--@end-->


### Choices


#### **force_it** — *grey*

<!--@ domain_events.json | rel_cool_thaw | choices.force_it.text -->
Give them a job that needs both of them and walk away.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ domain_events.json | rel_cool_thaw | choices.force_it.outcome.text -->
It takes them most of the morning, mostly in silence.

They come back having not discussed it at all, and having somehow discussed it entirely.
<!--@end-->


#### **talk_to_each** — *blue* — requires persuasion 4

<!--@ domain_events.json | rel_cool_thaw | choices.talk_to_each.text -->
Talk to each of them separately. Find out what it actually is.
<!--@end-->


*Outcome*

`xp: 25  ·  pressure: air+8`

<!--@ domain_events.json | rel_cool_thaw | choices.talk_to_each.outcome.text -->
It is, as it usually is, one remark made two weeks ago that one of them does not remember making and the other has not stopped hearing.
<!--@end-->


#### **ignore** — *grey*

<!--@ domain_events.json | rel_cool_thaw | choices.ignore.text -->
They are adults. Leave it.
<!--@end-->


*Outcome*

`pressure: water-5`

<!--@ domain_events.json | rel_cool_thaw | choices.ignore.outcome.text -->
They are adults, and it does not improve. The politeness gets a little more scrupulous.
<!--@end-->


---
