# Hell — Events

*79 events. No base snapshot is set, so nothing is marked as new — see the header of `export_review_docs.py` for how to turn the NEW markers back on.*

*Edit the prose between the anchors. Headings, ids and the mechanical lines under each choice are generated — edits there are lost.*

---

## hell_demon_patrol

`realm: hell`

**Title**

<!--@ hell_events.json | hell_demon_patrol | title -->
Demon Patrol
<!--@end-->


**Body**

<!--@ hell_events.json | hell_demon_patrol | text -->
Three demons in frost-crusted armor block the path ahead. Their captain, a horned brute with blue-black skin, raises a jagged halberd.

"No one passes without the Warden's permission. State your business or prepare to suffer."
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_demon_patrol | choices.fight.text -->
Draw your weapon and attack
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+3, asura+2`

<!--@ hell_events.json | hell_demon_patrol | choices.fight.outcome.text -->

<!--@end-->


#### **negotiate** — *blue* — requires charm 15

<!--@ hell_events.json | hell_demon_patrol | choices.negotiate.text -->
Convince them you serve the Warden
<!--@end-->


*Outcome*

`karma: hungry_ghost+2, human+3  ·  xp: 8`

<!--@ hell_events.json | hell_demon_patrol | choices.negotiate.outcome.text -->
"Well, if you say so."
<!--@end-->


#### **sneak** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_demon_patrol | choices.sneak.text -->
Throw a bag of gold and slip past while they argue amongst themselves
<!--@end-->


*Outcome — success*

`karma: animal+3, human+2  ·  xp: 6`

<!--@ hell_events.json | hell_demon_patrol | choices.sneak.outcome_success.text -->
Maybe sometimes it's true that greed is good.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+5`

<!--@ hell_events.json | hell_demon_patrol | choices.sneak.outcome_failure.text -->
They look on you with confused pity and draw their weapons.
<!--@end-->


#### **bribe** — *grey*

<!--@ hell_events.json | hell_demon_patrol | choices.bribe.text -->
Offer them gold to look the other way
<!--@end-->


*Outcome*

`karma: hungry_ghost+5, human+2  ·  xp: 3`

<!--@ hell_events.json | hell_demon_patrol | choices.bribe.outcome.text -->
They quickly pocket the gold and step aside.
<!--@end-->


#### **daggers_blitz** — *blue* — requires daggers 3

<!--@ hell_events.json | hell_demon_patrol | choices.daggers_blitz.text -->
Strike fast and precisely — take them down before they can sound the alarm
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+3, hell+2  ·  xp: 8`

<!--@ hell_events.json | hell_demon_patrol | choices.daggers_blitz.outcome.text -->
You move in fast, targeting the gaps in their armor. They barely have time to react before the first one goes down. The fight continues, but the terms are yours.
<!--@end-->


---

## hell_ice_spirits

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ice_spirits | title -->
Ice Spirits
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ice_spirits | text -->
Translucent figures drift above the frozen surface of a vast lake. Their forms shimmer, beautiful and terrible, trapped in an eternal dance. One turns toward you, its hollow eyes filled with sorrow.

"Do not disturb those dreaming below."
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_ice_spirits | choices.fight.text -->
Force your way through
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: ice_spirits  ·  difficulty: hard  ·  karma: hell+5, asura+3`

<!--@ hell_events.json | hell_ice_spirits | choices.fight.outcome.text -->

<!--@end-->


#### **ice_magic** — *blue* — requires water_magic 3

<!--@ hell_events.json | hell_ice_spirits | choices.ice_magic.text -->
Speak to them in the language of water and cold
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 10  ·  items: ['ice_shard']`

<!--@ hell_events.json | hell_ice_spirits | choices.ice_magic.outcome.text -->
They recognize a kindred soul and part. Before you leave, the lead spirit shoves an ice shard in your hand.
<!--@end-->


#### **commune** — *blue* — requires yoga 2

<!--@ hell_events.json | hell_ice_spirits | choices.commune.text -->
Sit in meditation and commune with the spirits
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 12`

<!--@ hell_events.json | hell_ice_spirits | choices.commune.outcome.text -->
Through stillness you glimpse their memories. They become transparent and vanish into the cold mist.
<!--@end-->


#### **offering** — *grey*

<!--@ hell_events.json | hell_ice_spirits | choices.offering.text -->
Leave an offering at the lake's edge and pray
<!--@end-->


*Outcome*

`karma: god+4, human+2, hell-3  ·  xp: 5`

<!--@ hell_events.json | hell_ice_spirits | choices.offering.outcome.text -->
One spirit touches your forehead: a sensation of cold so deep it becomes warm. They part and let you through.
<!--@end-->


---

## hell_frozen_merchant

`realm: hell`

**Title**

<!--@ hell_events.json | hell_frozen_merchant | title -->
Frozen Merchant
<!--@end-->


**Body**

<!--@ hell_events.json | hell_frozen_merchant | text -->
A bundled figure huddles near a sputtering fire, surrounded by tattered bags. Despite the brutal cold, the merchant seems oddly cheerful.

"Welcome, welcome! Don't mind the cold — it keeps the thieves away! I've got everything a traveler needs to survive this frozen wasteland. Well, almost everything."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_frozen_merchant | choices.browse.text -->
Browse the merchant's wares
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: frozen_merchant  ·  karma: human+1`

<!--@ hell_events.json | hell_frozen_merchant | choices.browse.outcome.text -->

<!--@end-->


#### **haggle** — *blue* — requires trade 2

<!--@ hell_events.json | hell_frozen_merchant | choices.haggle.text -->
Try to negotiate better prices
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 5  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_frozen_merchant | choices.haggle.outcome.text -->
The merchant nods his head, impressed.
<!--@end-->


#### **chat** — *grey*

<!--@ hell_events.json | hell_frozen_merchant | choices.chat.text -->
Ask about the region
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 2`

<!--@ hell_events.json | hell_frozen_merchant | choices.chat.outcome.text -->
He warns you about ice wraiths, the Lava Guardian, and Yama's lieutenant standing guard in the far south.
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs easy

<!--@ hell_events.json | hell_frozen_merchant | choices.steal.text -->
Wait for a distraction and pocket some merchandise
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['iron_dagger', 'health_potion']`

<!--@ hell_events.json | hell_frozen_merchant | choices.steal.outcome_success.text -->
The merchant's attention drifts. Your hand moves fast. By the time they look back, you are studying the horizon innocently.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hell_events.json | hell_frozen_merchant | choices.steal.outcome_failure.text -->
The merchant's scream brings a demon patrol at a run. "Thief! THIEF!" There is nowhere to run.
<!--@end-->


#### **donate** — *grey*

<!--@ hell_events.json | hell_frozen_merchant | choices.donate.text -->
Leave a generous tip — life's hard for everyone in hell
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 3`

<!--@ hell_events.json | hell_frozen_merchant | choices.donate.outcome.text -->
The merchant stares at the coins, then at you, then at the coins again. "I... thank you. I haven't had a kind customer since — actually, I've never had a kind customer." They wave you off with unusual warmth.
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs trivial

<!--@ hell_events.json | hell_frozen_merchant | choices.comedy.text -->
Tell the merchant a joke about freezing to death in hell
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 4  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_frozen_merchant | choices.comedy.outcome_success.text -->
"...and then the yak said, 'at least it's a dry cold!'" The merchant howls with laughter, slapping their knee hard enough to crack ice off their boot. "That's the funniest thing anyone's said to me in three hundred years. Here — on the house." They toss you a health potion.
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_frozen_merchant | choices.comedy.outcome_failure.text -->
Silence. The merchant stares at you with an expression that could freeze hell twice over. "Get out of my shop." There is no shop. You leave anyway.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_frozen_merchant | choices.leave.text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_frozen_merchant | choices.leave.outcome.text -->
"Safe travels! Try not to freeze!"
<!--@end-->


---

## hell_lost_wanderer

`realm: hell`

**Title**

<!--@ hell_events.json | hell_lost_wanderer | title -->
The Wanderer
<!--@end-->


**Body**

<!--@ hell_events.json | hell_lost_wanderer | text -->
Sheltering in a hollow near the road, a lone figure sits apart from the cold. They do not look up as you approach.

"Cast out," they say at last. "Showed mercy once when the Guard said not to. Paid for it." A short, bitter laugh. "Been wandering since. No patrol, no master. Just nowhere to be."
<!--@end-->


### Choices


#### **offer_place** — *grey*

<!--@ hell_events.json | hell_lost_wanderer | choices.offer_place.text -->
"Nowhere to be sounds like a reason to travel with us."
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: random  ·  karma: human+3, god+2`

<!--@ hell_events.json | hell_lost_wanderer | choices.offer_place.outcome.text -->
They look at you for a long moment, then stand, rolling their shoulders.

"Alright. Can't be worse than this."
<!--@end-->


#### **homesick_recognises** — *blue* — requires **trait: homesick**

<!--@ hell_events.json | hell_lost_wanderer | choices.homesick_recognises.text -->
You know that particular way of sitting apart.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+10`

<!--@ hell_events.json | hell_lost_wanderer | choices.homesick_recognises.outcome.text -->
You sit down at the same distance from them that they are sitting from everything, which is the only approach that was ever going to work.

They talk for a while about a place that no longer exists. You know the feeling well enough not to correct any of it.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_lost_wanderer | choices.leave.text -->
"Hell rewards the strong. Find your own way."
<!--@end-->


*Outcome*

`karma: hell+2`

<!--@ hell_events.json | hell_lost_wanderer | choices.leave.outcome.text -->
They nod, unsurprised. You leave them to the cold.
<!--@end-->


---

## hell_frozen_traveler

`realm: hell  ·  zone: cold`

**Title**

<!--@ hell_events.json | hell_frozen_traveler | title -->
Frozen Traveler
<!--@end-->


**Body**

<!--@ hell_events.json | hell_frozen_traveler | text -->
A shivering figure huddles by the roadside, barely conscious. Their robes are torn and frostbitten skin shows through the gaps.

"Please... I've been wandering for so long. I can't feel my hands anymore. Is this... is this what I deserve?"
<!--@end-->


### Choices


#### **heal** — *blue* — requires medicine 1

<!--@ hell_events.json | hell_frozen_traveler | choices.heal.text -->
Tend to their wounds
<!--@end-->


*Outcome*

`karma: hell-5, human+5, god+3  ·  xp: 8  ·  items: ['prayer_beads']`

<!--@ hell_events.json | hell_frozen_traveler | choices.heal.outcome.text -->
You work quickly. Color returns to their face — they look surprised, as if they'd forgotten warmth was possible. They press a trinket into your hands without words.
<!--@end-->


#### **give_gold** — *grey*

<!--@ hell_events.json | hell_frozen_traveler | choices.give_gold.text -->
Give them some gold and food
<!--@end-->


*Outcome*

`karma: hell-3, human+4, god+2  ·  xp: 4`

<!--@ hell_events.json | hell_frozen_traveler | choices.give_gold.outcome.text -->
They weep with gratitude and speak quietly of a lifetime spent hoarding while others starved. They understand now what they didn't then.
<!--@end-->


#### **purify** — *blue* — requires ritual 2

<!--@ hell_events.json | hell_frozen_traveler | choices.purify.text -->
Offer them a small purification rite
<!--@end-->


*Outcome*

`karma: human+2, god+2  ·  xp: 5`

<!--@ hell_events.json | hell_frozen_traveler | choices.purify.outcome.text -->
You bless a little water with mantras and wash their hands and forehead. It's not much — but it's something. They breathe a little easier.
<!--@end-->


#### **ask** — *grey*

<!--@ hell_events.json | hell_frozen_traveler | choices.ask.text -->
Ask how they came to be here
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 3`

<!--@ hell_events.json | hell_frozen_traveler | choices.ask.outcome.text -->
They were a corrupt tax collector. They tell you plainly, without excuses. They understand now what their life cost others.
<!--@end-->


#### **pass** — *grey*

<!--@ hell_events.json | hell_frozen_traveler | choices.pass.text -->
Walk past without stopping
<!--@end-->


*Outcome*

`karma: hell+2, animal+2`

<!--@ hell_events.json | hell_frozen_traveler | choices.pass.outcome.text -->
They watch you go in silence. The cold feels a little sharper afterward.
<!--@end-->


#### **scrimper_counts** — *blue* — requires **trait: scrimper**

<!--@ hell_events.json | hell_frozen_traveler | choices.scrimper_counts.text -->
Help, but count what it costs first.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: earth+5`

<!--@ hell_events.json | hell_frozen_traveler | choices.scrimper_counts.outcome.text -->
Two rations, a blanket you were not using, and an hour. You total it as you go, out of habit, and find the total does not bother you as much as you expected.

The traveller lives. The accounting is, you decide, still worth having done.
<!--@end-->


#### **warm_hearted_no_question** — *blue* — requires **trait: warm_hearted**

<!--@ hell_events.json | hell_frozen_traveler | choices.warm_hearted_no_question.text -->
There is no decision here. Get them warm.
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 15  ·  pressure: water+12, fire+8`

<!--@ hell_events.json | hell_frozen_traveler | choices.warm_hearted_no_question.outcome.text -->
You are already moving before the question has finished being asked, and the party follows because that is what happens when someone moves first.

They live. They will tell someone about it, somewhere down the road.
<!--@end-->


#### **frail_cannot_carry** — *blue* — requires **trait: frail**

<!--@ hell_events.json | hell_frozen_traveler | choices.frail_cannot_carry.text -->
You want to carry them and you cannot.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: earth-10`

<!--@ hell_events.json | hell_frozen_traveler | choices.frail_cannot_carry.outcome.text -->
You get about forty paces before your legs make the decision for you, and somebody else takes the weight without comment, which is worse than comment.

The traveller lives. You spend the evening being unhelpfully angry at your own arms.
<!--@end-->


#### **strong_carries** — *blue* — requires **trait: strong**

<!--@ hell_events.json | hell_frozen_traveler | choices.strong_carries.text -->
Pick them up. Keep walking.
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 15`

<!--@ hell_events.json | hell_frozen_traveler | choices.strong_carries.outcome.text -->
You pick them up and keep walking and the party rearranges itself around the fact without a word being spent on it.

They are at the waystation an hour before they would otherwise have been, which is the whole difference between the two available outcomes.
<!--@end-->


#### **patient_presence** — *yellow* — requires roll charm vs easy

<!--@ hell_events.json | hell_frozen_traveler | choices.patient_presence.text -->
Sit with them without rushing — wait until the shock recedes enough for words
<!--@end-->


*Outcome — success*

`karma: human+4  ·  xp: 10  ·  items: ['random_common_talisman']`

<!--@ hell_events.json | hell_frozen_traveler | choices.patient_presence.outcome_success.text -->
Eventually they look up. Something surfaces from beneath the shock — a fragment of who they were. They press something into your hands as you leave: a small carved token from before. 'I won't need it here,' they say. It turns out to be worth something.
<!--@end-->


*Outcome — failure*

`karma: human+3  ·  xp: 5`

<!--@ hell_events.json | hell_frozen_traveler | choices.patient_presence.outcome_failure.text -->
They are too far gone in shock for words yet. But they grip your hand for a long time. When you finally rise to leave, a little warmth has returned to their face. Perhaps that's enough.
<!--@end-->


---

## hell_lava_guardian

`realm: hell`

**Title**

<!--@ hell_events.json | hell_lava_guardian | title -->
Lava Guardian
<!--@end-->


**Body**

<!--@ hell_events.json | hell_lava_guardian | text -->
A massive elemental of molten rock blocks the passage between the ice fields and the volcanic badlands. Heat radiates from it in waves, melting the frost for meters around. It speaks with a voice of grinding stone.

"NONE SHALL PASS between the realms of fire and ice. This has been the law for beginningless aeons. Prove your worth or be consumed."
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_lava_guardian | choices.fight.text -->
Attack the guardian head-on
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: lava_guardian  ·  difficulty: hard  ·  karma: asura+3, hell+2`

<!--@ hell_events.json | hell_lava_guardian | choices.fight.outcome.text -->

<!--@end-->


#### **duel** — *blue* — requires martial_arts 3

<!--@ hell_events.json | hell_lava_guardian | choices.duel.text -->
Challenge it to an honorable single combat
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: lava_guardian  ·  difficulty: normal  ·  karma: asura+5, human+2`

<!--@ hell_events.json | hell_lava_guardian | choices.duel.outcome.text -->
It fights fairly, with reduced ferocity.
<!--@end-->


#### **find_path** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_lava_guardian | choices.find_path.text -->
Search for an alternate route
<!--@end-->


*Outcome — success*

`karma: animal+3, human+2  ·  xp: 10  ·  items: ['fire_resistance_talisman']`

<!--@ hell_events.json | hell_lava_guardian | choices.find_path.outcome_success.text -->
You find a hidden passage and discover a talisman left by a previous traveler.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: lava_guardian  ·  difficulty: hard  ·  karma: hell+3`

<!--@ hell_events.json | hell_lava_guardian | choices.find_path.outcome_failure.text -->
Spotted! The guardian attacks.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hell_events.json | hell_lava_guardian | choices.meditate.text -->
Sit before it in meditation
<!--@end-->


*Outcome*

`karma: god+5, human+5, hell-5  ·  xp: 15`

<!--@ hell_events.json | hell_lava_guardian | choices.meditate.outcome.text -->
Hours pass; the guardian recognizes your understanding and silently steps aside.
<!--@end-->


---

## hell_boss_yama_lt

`realm: hell`

**Title**

<!--@ hell_events.json | hell_boss_yama_lt | title -->
Yama's Lieutenant
<!--@end-->


**Body**

<!--@ hell_events.json | hell_boss_yama_lt | text -->
A towering demon in ornate black and gold armor stands before the Realm Gate. Its four arms hold different weapons — sword, mace, spear, and a mirror that shows nothing.

"I am Chitragupta, Lieutenant of Yama, Lord of Death. I have judged every soul that passes through this gate. Tell me, mortal — do you believe your deeds merit passage?"
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_boss_yama_lt | choices.fight.text -->
Draw your weapon and fight for passage
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: yama_lieutenant  ·  difficulty: boss  ·  karma: hell+5, asura+5`

<!--@ hell_events.json | hell_boss_yama_lt | choices.fight.outcome.text -->

<!--@end-->


#### **plead** — *blue* — requires persuasion 3

<!--@ hell_events.json | hell_boss_yama_lt | choices.plead.text -->
Present your case with eloquent argument
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: yama_lieutenant_weakened  ·  difficulty: normal  ·  karma: human+5, god+3  ·  xp: 10`

<!--@ hell_events.json | hell_boss_yama_lt | choices.plead.outcome.text -->
It listens, lowers two weapons, giving you a fair chance.
<!--@end-->


#### **confess** — *grey*

<!--@ hell_events.json | hell_boss_yama_lt | choices.confess.text -->
Confess your doubts honestly
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: yama_lieutenant_weakened  ·  difficulty: normal  ·  karma: human+5, god+5, hell-5  ·  xp: 8`

<!--@ hell_events.json | hell_boss_yama_lt | choices.confess.outcome.text -->
Honesty impresses him, reduced ferocity.
<!--@end-->


#### **meditate** — *blue* — requires yoga 5

<!--@ hell_events.json | hell_boss_yama_lt | choices.meditate.text -->
Sit before the gate and meditate on the nature of death
<!--@end-->


*Outcome*

`karma: god+10, human+5, hell-10  ·  xp: 20`

<!--@ hell_events.json | hell_boss_yama_lt | choices.meditate.outcome.text -->
Hours dissolve into the earth, days dissolve into the sky, finally the boundary dissolves into space.
<!--@end-->


---

## hell_frozen_cave

`realm: hell`

**Title**

<!--@ hell_events.json | hell_frozen_cave | title -->
Frozen Cave
<!--@end-->


**Body**

<!--@ hell_events.json | hell_frozen_cave | text -->
A dark cave rimmed with glittering ice crystals yawns in the hillside like a great mouth. From deep within comes a faint glow and the distant sound of dripping water — warm water, impossibly, in this frozen waste.
<!--@end-->


### Choices


#### **enter** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_frozen_cave | choices.enter.text -->
Enter the cave carefully
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.enter.outcome_success.text -->
You spot the trap and walk around it. Soon you find a hidden chamber and leave with a couple potions.
<!--@end-->


*Outcome — failure*

`karma: animal+2  ·  xp: 4  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.enter.outcome_failure.text -->
You fall into a lower chamber, find a cache but take a knock.
<!--@end-->


#### **study** — *blue* — requires learning 2

<!--@ hell_events.json | hell_frozen_cave | choices.study.text -->
Study the entrance carefully before entering
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.study.outcome.text -->
You notice a warning in old demon script among the scratch marks on the cave wall. Taking it to heart, you carefully descend into the cave along its left-hand wall and soon emerge back with loot.
<!--@end-->


#### **space_sense** — *blue* — requires space_magic 2

<!--@ hell_events.json | hell_frozen_cave | choices.space_sense.text -->
Calm yourself and feel the space of the cave from the entrance
<!--@end-->


*Outcome*

`karma: human+2, god+1  ·  xp: 8  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.space_sense.outcome.text -->
The details remain hazy, but you quickly perceive the shape of the danger ahead and proceed accordingly. You emerge with a few useful finds.
<!--@end-->


#### **graceful_entry** — *blue* — requires grace 2

<!--@ hell_events.json | hell_frozen_cave | choices.graceful_entry.text -->
Enter the cave with lightness and poise
<!--@end-->


*Outcome*

`karma: human+2, animal+2  ·  xp: 8  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.graceful_entry.outcome.text -->
Nimbly avoiding the obvious trap, you move through the cave with ease and soon find the hidden cache.
<!--@end-->


#### **brave_first** — *blue* — requires **trait: brave**

<!--@ hell_events.json | hell_frozen_cave | choices.brave_first.text -->
Go in first. Somebody has to and it may as well be you.
<!--@end-->


*Outcome*

`xp: 12  ·  pressure: air+10`

<!--@ hell_events.json | hell_frozen_cave | choices.brave_first.outcome.text -->
You go in first. The dark does what dark does and you keep walking through it, and the thing at the back of the cave turns out to be smaller than the sound suggested, which is usually the way.

The party comes in behind you considerably steadier than they would have.
<!--@end-->


#### **timid_hangs_back** — *blue* — requires **trait: timid**

<!--@ hell_events.json | hell_frozen_cave | choices.timid_hangs_back.text -->
You are not going in there. You are simply not.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: air-15`

<!--@ hell_events.json | hell_frozen_cave | choices.timid_hangs_back.outcome.text -->
You are not, and no argument is going to move you, and the party goes in without you.

You hold the entrance for an hour listening to sounds you cannot interpret, which is very much worse than having gone in, and you know it the whole time.
<!--@end-->


#### **clubfooted_slow** — *blue* — requires **trait: clubfooted**

<!--@ hell_events.json | hell_frozen_cave | choices.clubfooted_slow.text -->
The floor is ice at an angle and your foot is what it is.
<!--@end-->


*Outcome*

`xp: 22  ·  hp_loss: {'amount': 'tiny', 'target': 'random'}  ·  pressure: earth-8`

<!--@ hell_events.json | hell_frozen_cave | choices.clubfooted_slow.outcome.text -->
You go down twice on the way in and the second one is bad — a knee into stone, the sound of it loud in the cave.

Whatever lives here now knows the party is present. The rest of the approach has to be made at speed rather than quietly.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_frozen_cave | choices.leave.text -->
The cave looks dangerous — best to move on
<!--@end-->


*Outcome*

`karma: human+2, animal+2, asura+2  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_frozen_cave | choices.leave.outcome.text -->
Discretion is the better part of valor. On your way out you notice a small cache near the entrance someone else left behind.
<!--@end-->


---

## hell_tormented_soul

`realm: hell`

**Title**

<!--@ hell_events.json | hell_tormented_soul | title -->
Tormented Soul
<!--@end-->


**Body**

<!--@ hell_events.json | hell_tormented_soul | text -->
A ghostly figure sits amid the frost, weeping silently. Unlike the mindless lost souls, this one retains its form — the shape of an old woman in tattered robes.

"Can you see me? Truly see me? So few can anymore..."
<!--@end-->


### Choices


#### **help** — *blue* — requires white_magic 1

<!--@ hell_events.json | hell_tormented_soul | choices.help.text -->
Use white magic to ease her suffering
<!--@end-->


*Outcome*

`karma: hell-5, human+3, god+3  ·  xp: 10`

<!--@ hell_events.json | hell_tormented_soul | choices.help.outcome.text -->
She dissolves into light with a sigh. In life, she was a healer who once turned away a sick wanderer for a lack of payment.
<!--@end-->


#### **listen** — *grey*

<!--@ hell_events.json | hell_tormented_soul | choices.listen.text -->
Sit beside her and listen
<!--@end-->


*Outcome*

`karma: human+3, god+2, hell-3  ·  xp: 6`

<!--@ hell_events.json | hell_tormented_soul | choices.listen.outcome.text -->
She speaks of small cruelties compounded until her breath grows a little longer and slower.
<!--@end-->


#### **exorcise** — *blue* — requires ritual 3

<!--@ hell_events.json | hell_tormented_soul | choices.exorcise.text -->
Perform a ritual to release her spirit
<!--@end-->


*Outcome*

`karma: hell-10, god+8, human+3  ·  xp: 12  ·  items: ['soul_stone']`

<!--@ hell_events.json | hell_tormented_soul | choices.exorcise.outcome.text -->
You write a mandala of liberation by sight around her. She dissolves into light, leaving a piece of turquoise behind.
<!--@end-->


#### **ignore** — *grey*

<!--@ hell_events.json | hell_tormented_soul | choices.ignore.text -->
Walk past — you have enough of your own problems
<!--@end-->


*Outcome*

`karma: hell+3, animal+2`

<!--@ hell_events.json | hell_tormented_soul | choices.ignore.outcome.text -->
The weeping grows quieter, then stops. The cold deepens.
<!--@end-->


#### **haunted_knows** — *blue* — requires **trait: haunted**

<!--@ hell_events.json | hell_tormented_soul | choices.haunted_knows.text -->
You know what it is like when the memory arrives uninvited.
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost-3  ·  xp: 15  ·  pressure: water+12`

<!--@ hell_events.json | hell_tormented_soul | choices.haunted_knows.outcome.text -->
You do not offer advice, because there is none, and you do not tell them it passes, because you would be lying.

What you do is stay until the worst of the current one is over. It is apparently not something anyone has done for them before.
<!--@end-->


#### **summon_guide** — *blue* — requires summoning 3

<!--@ hell_events.json | hell_tormented_soul | choices.summon_guide.text -->
Summon a guide spirit to show her the way forward
<!--@end-->


*Outcome*

`karma: hell-7, god+6, human+3  ·  xp: 14`

<!--@ hell_events.json | hell_tormented_soul | choices.summon_guide.outcome.text -->
You call a guide spirit — one of the patient ones, without agenda — and ask it to wait with her. It settles beside the old woman with the quality of something that has done this before.

She looks at it for a long moment. Then at you. 'You can see me.' Not a question anymore. A fact, confirmed.

The guide spirit takes her hand. Her form steadies. Something releases in her posture.

You leave them together.
<!--@end-->


---

## hell_crossroads_shrine

`realm: hell`

**Title**

<!--@ hell_events.json | hell_crossroads_shrine | title -->
Crossroads Shrine
<!--@end-->


**Body**

<!--@ hell_events.json | hell_crossroads_shrine | text -->
An ancient shrine sits where the roads cross, half-buried in snow and old offerings. Incense sticks still smolder in cracked holders, faded ribbons hang stiffly in the wind.
<!--@end-->


### Choices


#### **pray** — *grey*

<!--@ hell_events.json | hell_crossroads_shrine | choices.pray.text -->
Offer a prayer for safe passage
<!--@end-->


*Outcome*

`karma: god+2, human+2  ·  xp: 2`

<!--@ hell_events.json | hell_crossroads_shrine | choices.pray.outcome.text -->
Incense flares briefly, your breath deepens.
<!--@end-->


#### **meditate** — *blue* — requires yoga 1

<!--@ hell_events.json | hell_crossroads_shrine | choices.meditate.text -->
Meditate
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 4`

<!--@ hell_events.json | hell_crossroads_shrine | choices.meditate.outcome.text -->
The shrine seems to glow, a tiny lamp of Dharma lost among the wasteland.
<!--@end-->


#### **offering** — *grey*

<!--@ hell_events.json | hell_crossroads_shrine | choices.offering.text -->
Leave a small offering
<!--@end-->


*Outcome*

`karma: god+3, hungry_ghost-2, hell-2  ·  xp: 2`

<!--@ hell_events.json | hell_crossroads_shrine | choices.offering.outcome.text -->
Your coins join dozens of others, united in the intent for a better world.
<!--@end-->


#### **protection** — *blue* — requires ritual 2

<!--@ hell_events.json | hell_crossroads_shrine | choices.protection.text -->
Implore the shrine's guardians for protection
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 4  ·  buffs: [{'stat': 'constitution', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hell_events.json | hell_crossroads_shrine | choices.protection.outcome.text -->
Vows outlast bodies. The incense smoke briefly dances in the still air.
<!--@end-->


#### **pass** — *grey*

<!--@ hell_events.json | hell_crossroads_shrine | choices.pass.text -->
Continue on your way
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_crossroads_shrine | choices.pass.outcome.text -->
You nod respectfully and continue on your way.
<!--@end-->


#### **pilgrim_stop** — *blue* — requires **trait: pilgrim**

<!--@ hell_events.json | hell_crossroads_shrine | choices.pilgrim_stop.text -->
Stop properly. This is what the road is for.
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 20  ·  pressure: space+10, earth+8`

<!--@ hell_events.json | hell_crossroads_shrine | choices.pilgrim_stop.outcome.text -->
You do it the long way — circumambulation, the full prostrations, the offering placed rather than dropped.

The demons on the road watch with the blank incomprehension of people watching someone garden during a siege. You leave steadier than you arrived.
<!--@end-->


#### **superstition_read** — *blue* — requires **trait: superstitious**

<!--@ hell_events.json | hell_crossroads_shrine | choices.superstition_read.text -->
Check which way the offerings are facing before you do anything.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: air+8`

<!--@ hell_events.json | hell_crossroads_shrine | choices.superstition_read.outcome.text -->
Three of them face the road. One faces away.

You do not know what that means, but you know it means something, and you arrange your own offering to match the three. Nothing happens, which is exactly what you wanted.
<!--@end-->


#### **old_inscription** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_crossroads_shrine | choices.old_inscription.text -->
Focus on the oldest inscription — worn deep enough to survive centuries of snow
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 10`

<!--@ hell_events.json | hell_crossroads_shrine | choices.old_inscription.outcome_success.text -->
The characters resolve slowly into a specific protective glyph — not decorative but functional, a ward against a category of hell demon you've encountered before. You trace it carefully into memory.
<!--@end-->


*Outcome — failure*

`xp: 3`

<!--@ hell_events.json | hell_crossroads_shrine | choices.old_inscription.outcome_failure.text -->
The dialect is older than anything you recognize. The inscription might be a prayer, a warning, or a traveler's name. You can't tell. The incense smoke curls upward unconcerned.
<!--@end-->


---

## hell_wandering_peddler

`realm: hell`

**Title**

<!--@ hell_events.json | hell_wandering_peddler | title -->
Wandering Peddler
<!--@end-->


**Body**

<!--@ hell_events.json | hell_wandering_peddler | text -->
A hunched figure dragging a heavy sack waves you down.

"Psst! Traveler! You look like you could use some supplies. I've got just the things — all cleaned up nice."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_wandering_peddler | choices.browse.text -->
See what the peddler has to offer
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: wandering_peddler  ·  karma: human+1`

<!--@ hell_events.json | hell_wandering_peddler | choices.browse.outcome.text -->

<!--@end-->


#### **directions** — *grey*

<!--@ hell_events.json | hell_wandering_peddler | choices.directions.text -->
Ask for directions and local knowledge
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hell_events.json | hell_wandering_peddler | choices.directions.outcome.text -->
He starts talking a lot but making little sense. You catch bits and pieces about frozen ghosts on the lake, wandering monks and torture chambers.
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs easy

<!--@ hell_events.json | hell_wandering_peddler | choices.steal.text -->
Grab his pack and run
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['iron_dagger', 'leather_cap', 'health_potion']  ·  pressure: water-15, earth-8`

<!--@ hell_events.json | hell_wandering_peddler | choices.steal.outcome_success.text -->
You snatch the pack and sprint. Behind you, the peddler's shouts fade into confused silence. The bag contains more than you expected — and something that rattles like it's alive.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+2`

<!--@ hell_events.json | hell_wandering_peddler | choices.steal.outcome_failure.text -->
Your foot catches on a frozen rut. The peddler watches you sprawl, unmoved. "Not the first time," he says, gathering his bag. "Not the worst, either." He trudges on without another word. You are left with bruised dignity and nothing else.
<!--@end-->


#### **attack** — *grey*

<!--@ hell_events.json | hell_wandering_peddler | choices.attack.text -->
Mug him outright
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: lost_souls  ·  difficulty: normal  ·  karma: hell+5`

<!--@ hell_events.json | hell_wandering_peddler | choices.attack.outcome.text -->
The peddler drops the sack. From the shadows, his associates — desperate, hollow-eyed souls — close in. He was never alone.
<!--@end-->


#### **haggle** — *blue* — requires trade 2

<!--@ hell_events.json | hell_wandering_peddler | choices.haggle.text -->
Haggle for better prices
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 4  ·  gold: small`

<!--@ hell_events.json | hell_wandering_peddler | choices.haggle.outcome.text -->
The trader seems amused, and after a short back-and-forth, grants you a discount. "Fine, fine. A fair deal." You walk away having spent less than expected.
<!--@end-->


#### **scrimper_haggles** — *blue* — requires **trait: scrimper**

<!--@ hell_events.json | hell_wandering_peddler | choices.scrimper_haggles.text -->
He has told you the price. Tell him the real one.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ hell_events.json | hell_wandering_peddler | choices.scrimper_haggles.outcome.text -->
It takes eleven minutes and involves a detailed excursion into the condition of his sack.

He settles well below where he started, calls you something unrepeatable, and shakes your hand.
<!--@end-->


#### **move_on** — *grey*

<!--@ hell_events.json | hell_wandering_peddler | choices.move_on.text -->
Decline politely and move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_wandering_peddler | choices.move_on.outcome.text -->
"Your loss! If you change your mind, I'll be around. I'm always around."
<!--@end-->


---

## hell_hermit_monk

`realm: hell`

**Title**

<!--@ hell_events.json | hell_hermit_monk | title -->
Wandering Hermit
<!--@end-->


**Body**

<!--@ hell_events.json | hell_hermit_monk | text -->
A weathered monk in tattered robes approaches, seemingly at peace despite the frozen wasteland. His eyes are bright and clear.

"Ah, hello. How rare to meet someone with open eyes."
<!--@end-->


### Choices


#### **teaching** — *blue* — requires yoga 1

<!--@ hell_events.json | hell_hermit_monk | choices.teaching.text -->
Ask the monk for spiritual teaching
<!--@end-->


*Outcome*

`karma: god+5, human+5  ·  xp: 4`

<!--@ hell_events.json | hell_hermit_monk | choices.teaching.outcome.text -->
He teaches about suffering and its root, the poisons of ignorance, desire and aversion.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hell_events.json | hell_hermit_monk | choices.meditate.text -->
Sit with him in meditation
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 6  ·  restore: {'hp_percent': 50, 'mana_percent': 50}`

<!--@ hell_events.json | hell_hermit_monk | choices.meditate.outcome.text -->
You sit in comfortable silence. Afterwards, you feel restored and somehow warmed.
<!--@end-->


#### **ask_karma** — *blue* — requires awareness 16

<!--@ hell_events.json | hell_hermit_monk | choices.ask_karma.text -->
Ask about the workings of karma
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 8`

<!--@ hell_events.json | hell_hermit_monk | choices.ask_karma.outcome.text -->
"Every action, word and thought creates ripples throughout the thousandfold universe."
<!--@end-->


#### **comedy_frozen** — *blue* — requires comedy 2

<!--@ hell_events.json | hell_hermit_monk | choices.comedy_frozen.text -->
My eyelids are frozen in place, friend — but you have my full attention
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 8`

<!--@ hell_events.json | hell_hermit_monk | choices.comedy_frozen.outcome.text -->
He laughs in surprise — a real laugh, not a polite one. The conversation that follows is warm in a way that has nothing to do with temperature. You both leave a little lighter.
<!--@end-->


#### **ascetic_recognised** — *blue* — requires **trait: ascetic**

<!--@ hell_events.json | hell_hermit_monk | choices.ascetic_recognised.text -->
He looks at what you are carrying, which is very little.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+12, space+10`

<!--@ hell_events.json | hell_hermit_monk | choices.ascetic_recognised.outcome.text -->
'Ah,' he says, and something in his posture changes from courteous to interested.

What follows is not a teaching so much as a comparison of notes between two people who have both decided that most things are optional. You come away with one instruction, and it is a good one.
<!--@end-->


#### **present_sits_down** — *blue* — requires **trait: present**

<!--@ hell_events.json | hell_hermit_monk | choices.present_sits_down.text -->
He is here. Be here.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: space+15`

<!--@ hell_events.json | hell_hermit_monk | choices.present_sits_down.outcome.text -->
There is no teaching. You sit down opposite him in the snow and neither of you says anything for a considerable time.

At the end he laughs once, briefly, as though you had told a joke, and goes on his way. You will spend some weeks working out what was funny.
<!--@end-->


#### **move_on** — *grey*

<!--@ hell_events.json | hell_hermit_monk | choices.move_on.text -->
Wish him well and continue on your journey
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 2`

<!--@ hell_events.json | hell_hermit_monk | choices.move_on.outcome.text -->
He bows slightly and walks away. You notice there are no footprints left in his path.
<!--@end-->


---

## hell_ice_yogi

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ice_yogi | title -->
Frozen Waterfall Yogi
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ice_yogi | text -->
Before a magnificent frozen waterfall, a yogi sits in stillness. Ice crystals have formed on their eyelashes and hair, icicles hang from their beard.
<!--@end-->


### Choices


#### **learn_water** — *blue* — requires water_magic 1

<!--@ hell_events.json | hell_ice_yogi | choices.learn_water.text -->
Ask to learn water magic techniques
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 15  ·  skill_up: {'skill': 'water_magic', 'amount': 1, 'cap': 6}`

<!--@ hell_events.json | hell_ice_yogi | choices.learn_water.outcome.text -->
Hours pass until you notice the movement hidden in the stillness.
<!--@end-->


#### **meditate** — *blue* — requires yoga 2

<!--@ hell_events.json | hell_ice_yogi | choices.meditate.text -->
Meditate together on impermanence
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 12`

<!--@ hell_events.json | hell_ice_yogi | choices.meditate.outcome.text -->
Time dissolves into the frozen cascades.
<!--@end-->


#### **observe** — *grey*

<!--@ hell_events.json | hell_ice_yogi | choices.observe.text -->
Watch the yogi's meditation in silence
<!--@end-->


*Outcome*

`karma: god+2, human+2  ·  xp: 5`

<!--@ hell_events.json | hell_ice_yogi | choices.observe.outcome.text -->
The cold seems to lessen when you stop fighting it.
<!--@end-->


#### **steady_practice_sits** — *blue* — requires **trait: steady_practice**

<!--@ hell_events.json | hell_ice_yogi | choices.steady_practice_sits.text -->
Sit down beside them. Do not announce it.
<!--@end-->


*Outcome*

`xp: 20  ·  add_trait: enlightened_insight  ·  pressure: space+15, water+10`

<!--@ hell_events.json | hell_ice_yogi | choices.steady_practice_sits.outcome.text -->
You sit. The cold is immediate and then, some considerable time later, less immediate.

The yogi does not acknowledge you at any point, which you understand by the end to have been the entire teaching.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_ice_yogi | choices.leave.text -->
Leave the yogi to their practice
<!--@end-->


*Outcome*

`karma: human+1`

<!--@ hell_events.json | hell_ice_yogi | choices.leave.outcome.text -->
You bow respectfully and depart.
<!--@end-->


---

## hell_fire_shrine

`realm: hell`

**Title**

<!--@ hell_events.json | hell_fire_shrine | title -->
The Burning Shrine
<!--@end-->


**Body**

<!--@ hell_events.json | hell_fire_shrine | text -->
A shrine wreathed in eternal flames stands among scorched ruins. Unlike the destructive fires around it, these flames burn with an almost sacred quality — steady, contained, purposeful. Ancient mantras are carved into the shrine's stone base, glowing red with heat.

The air shimmers with power. You can feel the fire calling to something within you.
<!--@end-->


### Choices


#### **fire_magic** — *blue* — requires fire_magic 2

<!--@ hell_events.json | hell_fire_shrine | choices.fire_magic.text -->
Channel the shrine's power through your fire magic
<!--@end-->


*Outcome*

`karma: asura+3, human+2  ·  xp: 12`

<!--@ hell_events.json | hell_fire_shrine | choices.fire_magic.outcome.text -->
You reach into the flames with your power, and the shrine responds. Fire dances up your arms without burning — instead, it fills you with understanding. The mantras on the base glow brighter as fire magic surges through you.

When you release the connection, you can feel the fire's discipline has become part of you. Your control over flame has deepened.
<!--@end-->


#### **read_mantras** — *blue* — requires ritual 2

<!--@ hell_events.json | hell_fire_shrine | choices.read_mantras.text -->
Study the ancient mantras carved into the stone
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 10`

<!--@ hell_events.json | hell_fire_shrine | choices.read_mantras.outcome.text -->
The mantras are written in an archaic script — prayers of purification through fire. As you trace the words with your finger, their meaning unfolds in your mind.

These are mantras of transformation, teaching how suffering itself can be fuel for enlightenment. The fire does not destroy — it transforms.
<!--@end-->


#### **pray** — *grey*

<!--@ hell_events.json | hell_fire_shrine | choices.pray.text -->
Kneel and pray before the burning shrine
<!--@end-->


*Outcome*

`karma: god+2, asura+2  ·  xp: 4`

<!--@ hell_events.json | hell_fire_shrine | choices.pray.outcome.text -->
You kneel before the flames, feeling their warmth on your face. A prayer rises unbidden — not for protection from fire, but for the strength to face whatever lies ahead.

The flames flare briefly, and you feel a surge of resolve.
<!--@end-->


#### **lapsed_hesitates** — *blue* — requires **trait: lapsed**

<!--@ hell_events.json | hell_fire_shrine | choices.lapsed_hesitates.text -->
Stand at the edge. You have not done this in a long time.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: space+12`

<!--@ hell_events.json | hell_fire_shrine | choices.lapsed_hesitates.outcome.text -->
The words are there. That is the surprise — you had assumed they had gone with everything else, and they have simply been waiting, filed and dusty.

You say about half of them before you stop. It is more than you have said in years.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_fire_shrine | choices.leave.text -->
The flames are too intense — move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_fire_shrine | choices.leave.outcome.text -->
You step back from the searing heat. Some trials require preparation before they can be faced.
<!--@end-->


---

## hell_ember_merchant

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ember_merchant | title -->
The Ember Merchant
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ember_merchant | text -->
A demon merchant sits cross-legged on a fireproof blanket, surrounded by wares that glow faintly with heat. Their skin is deep red, cracked like cooling lava, and their smile reveals obsidian teeth.

'Welcome to the finest establishment in all of burning Naraka! Fire-forged goods, guaranteed to survive anything this realm throws at you. Mostly. No refunds if you fall into lava, that's just poor decision-making.'
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_ember_merchant | choices.browse.text -->
Browse the ember merchant's fire-forged wares
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: ember_merchant  ·  karma: human+1`

<!--@ hell_events.json | hell_ember_merchant | choices.browse.outcome.text -->
The merchant eagerly displays their collection. Everything radiates gentle warmth, from weapons tempered in volcanic forge-fires to armor that drinks in flames.
<!--@end-->


#### **haggle** — *blue* — requires trade 2

<!--@ hell_events.json | hell_ember_merchant | choices.haggle.text -->
Negotiate as a fellow trader
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 5  ·  items: ['fire_resistance_potion']`

<!--@ hell_events.json | hell_ember_merchant | choices.haggle.outcome.text -->
'A merchant's eye! I can tell. You know the value of things.' The demon leans forward conspiratorially. 'Between professionals — take this. A little sample of my finest work. Consider it an investment in a return customer.'

They press a warm vial into your hands.
<!--@end-->


#### **ask_info** — *grey*

<!--@ hell_events.json | hell_ember_merchant | choices.ask_info.text -->
Ask about the burning realm
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 2`

<!--@ hell_events.json | hell_ember_merchant | choices.ask_info.outcome.text -->
'This side of Naraka? Fire, brimstone, the usual.' The merchant waves a hand dismissively. 'The Oni Brute in the western ruins is trouble — stays clear of him unless you're looking for a fight. The Trial of Flames to the south is where demons test their warriors.'

They lower their voice. 'Yama's lieutenant guards the realm gate to the southeast. Chitragupta, they call him. Four arms, four weapons. Make sure you're ready before you go that way.'
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_ember_merchant | choices.steal.text -->
Pocket something while the merchant is talking
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['fire_bomb', 'flame_oil']`

<!--@ hell_events.json | hell_ember_merchant | choices.steal.outcome_success.text -->
Demons talk with their hands. You use their hands against them — the fire-bomb slips into your pack right as they gesture dramatically about lava. They never notice.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hungry_ghost+3`

<!--@ hell_events.json | hell_ember_merchant | choices.steal.outcome_failure.text -->
The merchant's grin turns brittle. 'I have eyes in the back of my head. Three of them, actually.' They snap their fingers. Figures emerge from the smoke. 'No refunds — and no mercy for thieves.'
<!--@end-->


#### **attack** — *grey*

<!--@ hell_events.json | hell_ember_merchant | choices.attack.text -->
Draw your weapon and take what you need
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+6`

<!--@ hell_events.json | hell_ember_merchant | choices.attack.outcome.text -->
The merchant drops the salesman's smile instantly. 'Oh good. I was getting bored.' Behind you, the exits close. Around the merchant, fire rises.
<!--@end-->


#### **comedy_guaranteed** — *blue* — requires comedy 2

<!--@ hell_events.json | hell_ember_merchant | choices.comedy_guaranteed.text -->
Mostly guaranteed, or guaranteed you'd mostly survive?
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 5  ·  items: ['earth_charm_common']`

<!--@ hell_events.json | hell_ember_merchant | choices.comedy_guaranteed.outcome.text -->
The trader chuckles, genuinely surprised. "Ha! That's... that's actually good." They root around and toss you something small. "On the house, clown. First honest laugh I've had in decades."
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs easy

<!--@ hell_events.json | hell_ember_merchant | choices.comedy.text -->
Make a joke about their 'no refunds if you fall into lava' policy
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 5  ·  items: ['fire_resistance_potion']`

<!--@ hell_events.json | hell_ember_merchant | choices.comedy.outcome_success.text -->
"What if I fall INTO a customer? Does THAT count?" The demon stares at you, then erupts in a cackle that shakes their entire body and singes the awning. 'Ha! I like you. You're terrible but I like you.' They press a warm vial into your hands. 'On the house. First time I've laughed in forty years.'
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_ember_merchant | choices.comedy.outcome_failure.text -->
The merchant's smile doesn't reach their obsidian eyes. "That was not funny. I have been in this realm for eight hundred years and that was not funny. Leave." They turn their back. The temperature near you drops noticeably.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_ember_merchant | choices.leave.text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_ember_merchant | choices.leave.outcome.text -->
'Stay warm! Well, you'll have no choice about that down here!' the merchant cackles as you leave.
<!--@end-->


---

## hell_burning_prisoner

`realm: hell`

**Title**

<!--@ hell_events.json | hell_burning_prisoner | title -->
The Burning Prisoner
<!--@end-->


**Body**

<!--@ hell_events.json | hell_burning_prisoner | text -->
A figure writhes in chains of molten metal, suspended above a pit of glowing coals. Their screams have long since faded to hoarse whispers. Despite their torment, their eyes are clear — filled with pain, but also a terrible awareness.

'Please,' they rasp. 'I know what I did. I know why I'm here. But I've suffered enough to understand. Please... if you can...'
<!--@end-->


### Choices


#### **free** — *blue* — requires strength 14

<!--@ hell_events.json | hell_burning_prisoner | choices.free.text -->
Break the chains with your strength
<!--@end-->


*Outcome*

`karma: hell-8, human+5, god+5  ·  xp: 10  ·  items: ['demon_key']`

<!--@ hell_events.json | hell_burning_prisoner | choices.free.outcome.text -->
You grab the molten chains, gritting your teeth against the searing pain. With a mighty heave, the links shatter. The prisoner collapses, weeping.

'Thank you. I was a tyrant — I burned villages and tortured innocents. This was my punishment. But you... you showed mercy even to one who showed none.'

They press something into your blistered hands — a key they'd been clutching all along.
<!--@end-->


#### **heal** — *blue* — requires white_magic 2

<!--@ hell_events.json | hell_burning_prisoner | choices.heal.text -->
Use healing magic to ease their suffering
<!--@end-->


*Outcome*

`karma: hell-5, human+5, god+8  ·  xp: 8`

<!--@ hell_events.json | hell_burning_prisoner | choices.heal.outcome.text -->
You cannot break the chains, but you can mend what they've broken. Healing light flows from your hands, closing burns and numbing pain.

The prisoner breathes freely for the first time in ages. 'You cannot free me — only I can do that, through true repentance. But this respite... it reminds me what kindness feels like. I had forgotten.' Tears trace clean lines through the soot on their face.
<!--@end-->


#### **purification** — *blue* — requires ritual 3

<!--@ hell_events.json | hell_burning_prisoner | choices.purification.text -->
Offer a ritual purification to shorten their suffering
<!--@end-->


*Outcome*

`karma: human+3, god+4, hell-3  ·  xp: 8`

<!--@ hell_events.json | hell_burning_prisoner | choices.purification.outcome.text -->
They nod somewhat absent-mindedly, numbed by the pain. You perform the rite as best you can under the circumstances. By the end they seem somewhat relieved — not freed, but perhaps a little less alone in their torment.
<!--@end-->


#### **talk** — *grey*

<!--@ hell_events.json | hell_burning_prisoner | choices.talk.text -->
Ask what crime brought them here
<!--@end-->


*Outcome*

`karma: human+3, hell-2  ·  xp: 4  ·  pressure: water-20, space-8`

<!--@ hell_events.json | hell_burning_prisoner | choices.talk.outcome.text -->
'I was a warlord,' they whisper. 'I burned a hundred homes. I thought fear was power. Now I know — fear is just fear. And cruelty is just cruelty dressed up as strength.'

They look at you with haunted eyes. 'Don't make my mistakes, traveler. Power without compassion is just a longer chain.'
<!--@end-->


#### **armored_grip** — *blue* — requires armor 3

<!--@ hell_events.json | hell_burning_prisoner | choices.armored_grip.text -->
Use your gauntlets to grip the molten chain
<!--@end-->


*Outcome*

`karma: hell-6, human+5, god+4  ·  xp: 10  ·  items: ['demon_key']`

<!--@ hell_events.json | hell_burning_prisoner | choices.armored_grip.outcome.text -->
You know exactly where to grip through the gauntlets — the cooler sections, the fulcrum points. It takes strength and technique both. The chain holds long enough to matter, then a link gives way with a sound like a bell. The prisoner slides free and looks at their hands as if seeing them for the first time in a long while.
<!--@end-->


#### **merciful_cannot_pass** — *blue* — requires **trait: merciful**

<!--@ hell_events.json | hell_burning_prisoner | choices.merciful_cannot_pass.text -->
You are not going to be able to walk past this.
<!--@end-->


*Outcome*

`karma: human+6, hell-4  ·  xp: 30  ·  hp_loss: {'amount': 'light', 'target': 'random'}  ·  add_trait: merciful  ·  pressure: water+15`

<!--@ hell_events.json | hell_burning_prisoner | choices.merciful_cannot_pass.outcome.text -->
You are not. Everyone in the party works this out at approximately the same moment you do, and the argument that follows is short.

The chains are hot enough to cost you. The prisoner is down and breathing before you have finished deciding whether it was wise.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_burning_prisoner | choices.leave.text -->
Turn away — this is their punishment
<!--@end-->


*Outcome*

`karma: hell+3, asura+2`

<!--@ hell_events.json | hell_burning_prisoner | choices.leave.outcome.text -->
You walk on. Behind you, the prisoner's whispers fade back into the crackling of flames. The heat feels heavier on your shoulders.
<!--@end-->


---

## hell_fire_trial

`realm: hell`

**Title**

<!--@ hell_events.json | hell_fire_trial | title -->
The Trial of Flames
<!--@end-->


**Body**

<!--@ hell_events.json | hell_fire_trial | text -->
An arena of scorched stone rises from the lava fields, its tiers filled with demons of all shapes and sizes. They roar and stamp at the sight of you — fresh blood for their entertainment.

A massive demon in ceremonial armor stands at the center. 'FRESH CHALLENGER!' it bellows. 'The Trial of Flames awaits! Prove your worth in combat, or prove your wisdom in another way. Choose!'
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_fire_trial | choices.fight.text -->
Accept the combat challenge
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: asura+5, hell+2`

<!--@ hell_events.json | hell_fire_trial | choices.fight.outcome.text -->
The crowd erupts as warriors pour into the arena. These are no ordinary demons — they are the arena's champions, hardened by countless trials.
<!--@end-->


#### **perform** — *blue* — requires performance 3

<!--@ hell_events.json | hell_fire_trial | choices.perform.text -->
Challenge them to a contest of performance instead
<!--@end-->


*Outcome*

`karma: asura+3, human+5  ·  xp: 12  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_fire_trial | choices.perform.outcome.text -->
You step into the arena not with weapons drawn, but with a performance that captures even demonic hearts. You tell the tale of a warrior who conquered not through strength but through art — and the demons listen, rapt.

When you finish, even the arena champion is applauding. 'That took more courage than fighting!' they declare. The demons shower you with prizes.
<!--@end-->


#### **intimidate** — *blue* — requires charm 15

<!--@ hell_events.json | hell_fire_trial | choices.intimidate.text -->
Stare down the champion with raw willpower
<!--@end-->


*Outcome*

`karma: asura+5, human+3  ·  xp: 10`

<!--@ hell_events.json | hell_fire_trial | choices.intimidate.outcome.text -->
You lock eyes with the champion. Neither of you blinks. The crowd falls silent. Seconds stretch into minutes. Something shifts in the champion's gaze — recognition, perhaps respect.

'You have the spirit of a true warrior,' the champion says, breaking the silence. 'You don't need to prove anything in this pit.' They gesture, and the arena opens a path for you, the crowd parting with grudging respect.
<!--@end-->


#### **sorcery_strike** — *blue* — requires sorcery 4

<!--@ hell_events.json | hell_fire_trial | choices.sorcery_strike.text -->
Strike the demon down with sorcery before he finishes boasting
<!--@end-->


*Outcome*

`karma: asura+4, human+3  ·  xp: 12  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_fire_trial | choices.sorcery_strike.outcome.text -->
The crowd falls utterly silent. Then it erupts — equal parts outrage and awe. The champion collapses. The gatekeeper stares at you for a long moment, then steps aside.
<!--@end-->


#### **decline** — *grey*

<!--@ hell_events.json | hell_fire_trial | choices.decline.text -->
Decline and walk away
<!--@end-->


*Outcome*

`karma: human+2`

<!--@ hell_events.json | hell_fire_trial | choices.decline.outcome.text -->
You turn your back on the arena. Boos and jeers follow you, but no one moves to stop you. Sometimes the bravest choice is the one that looks like retreat.
<!--@end-->


---

## hell_volcanic_cave

`realm: hell`

**Title**

<!--@ hell_events.json | hell_volcanic_cave | title -->
The Volcanic Cave
<!--@end-->


**Body**

<!--@ hell_events.json | hell_volcanic_cave | text -->
A cave entrance glows red with the heat of magma flowing within. The walls pulse with veins of liquid fire, casting dancing shadows. Deep within, you can hear a rhythmic sound — like a heartbeat, or the slow breathing of something enormous.

The heat is nearly unbearable, but you can see the glint of valuables deeper inside.
<!--@end-->


### Choices


#### **enter** — *yellow* — requires roll constitution vs normal

<!--@ hell_events.json | hell_volcanic_cave | choices.enter.text -->
Brave the heat and explore the cave
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 10  ·  items: ['health_potion', 'fire_resistance_potion']`

<!--@ hell_events.json | hell_volcanic_cave | choices.enter.outcome_success.text -->
You push through the searing heat, your body screaming in protest. The cave opens into a magma chamber where ancient demon forges still glow with purpose.

Among the abandoned tools, you find fire-forged equipment of remarkable quality and a cache of supplies left by the last smith to work here.
<!--@end-->


*Outcome — failure*

`karma: animal+2  ·  xp: 4`

<!--@ hell_events.json | hell_volcanic_cave | choices.enter.outcome_failure.text -->
The heat is too much. You stagger back, skin blistered, gasping for cooler air. You manage to grab a few things near the entrance before retreating, but the deeper treasures remain beyond your endurance.
<!--@end-->


#### **fire_resist** — *blue* — requires fire_magic 2

<!--@ hell_events.json | hell_volcanic_cave | choices.fire_resist.text -->
Use fire magic to protect yourself from the heat
<!--@end-->


*Outcome*

`karma: human+3, asura+2  ·  xp: 12  ·  items: ['fire_crystal', 'mana_potion']`

<!--@ hell_events.json | hell_volcanic_cave | choices.fire_resist.outcome.text -->
You weave a barrier of controlled flame around yourself, turning the cave's heat aside like water off oiled cloth. The magma parts before you as you walk deeper.

The cave holds wonders — natural formations of crystallized fire magic, and at its heart, a forge still burning with the flames that were lit when Naraka was young. You take what you can carry.
<!--@end-->


#### **listen** — *blue* — requires learning 2

<!--@ hell_events.json | hell_volcanic_cave | choices.listen.text -->
Listen to the heartbeat sound from the entrance
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 8`

<!--@ hell_events.json | hell_volcanic_cave | choices.listen.outcome.text -->
You close your eyes and listen. The rhythm is too regular for a creature, too purposeful for nature. After long study, you realize — it's the pulse of the realm itself. Naraka has a heartbeat, and this cave is one of its arteries.

The knowledge fills you with a deeper understanding of how the hell realm works. The suffering here isn't random — it has structure, purpose, even a kind of terrible beauty.
<!--@end-->


#### **grace_vent** — *blue* — requires grace 2

<!--@ hell_events.json | hell_volcanic_cave | choices.grace_vent.text -->
Move quickly and lightly between the thermal vents
<!--@end-->


*Outcome*

`karma: animal+3, human+3, asura+3  ·  xp: 8  ·  items: ['health_potion', 'fire_resistance_potion']`

<!--@ hell_events.json | hell_volcanic_cave | choices.grace_vent.outcome.text -->
Uncomfortable, but nevertheless doable — like so many things in life. You thread between the vents with quick, precise movements and find what you came for.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_volcanic_cave | choices.leave.text -->
The heat is too dangerous — move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_volcanic_cave | choices.leave.outcome.text -->
You back away from the cave entrance. The glow within seems to pulse with disappointment, but sometimes survival is its own reward.
<!--@end-->


---

## hell_lava_flow

`realm: hell`

**Title**

<!--@ hell_events.json | hell_lava_flow | title -->
The Lava Flow
<!--@end-->


**Body**

<!--@ hell_events.json | hell_lava_flow | text -->
A river of molten rock surges across the path ahead, its surface glowing white-hot. The heat creates a shimmering wall of distortion in the air. On the other side, you can see the path continuing — but crossing seems impossible.

Then you notice: the flow pulses. There are moments when it thins, gaps between surges...
<!--@end-->


### Choices


#### **time_it** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_lava_flow | choices.time_it.text -->
Time the surges and dash across during a gap
<!--@end-->


*Outcome — success*

`karma: human+2, animal+2  ·  xp: 8  ·  pressure: fire+12, air+10`

<!--@ hell_events.json | hell_lava_flow | choices.time_it.outcome_success.text -->
You watch the rhythm of the flow, counting between surges. Three... two... one... NOW!

You sprint across the brief gap, heat searing your boots but not quite burning through. You make it to the other side with singed clothes and a racing heart — but alive and ahead of those who would turn back.
<!--@end-->


*Outcome — failure*

`karma: hell+1  ·  xp: 3`

<!--@ hell_events.json | hell_lava_flow | choices.time_it.outcome_failure.text -->
You mistime the surge and have to leap back as molten rock splashes where you stood. The attempt leaves you with minor burns and a healthy respect for lava.
<!--@end-->


#### **grace_dance** — *blue* — requires grace 3

<!--@ hell_events.json | hell_lava_flow | choices.grace_dance.text -->
Time your steps to the lava's rhythm and dance your way across
<!--@end-->


*Outcome*

`karma: animal+3, human+3, asura+3  ·  xp: 8`

<!--@ hell_events.json | hell_lava_flow | choices.grace_dance.outcome.text -->
And a-one, and a-two... You cross in a series of precise, unhurried steps that somehow feel like dancing. The lava surges around your feet and misses every time.
<!--@end-->


#### **earth_magic** — *blue* — requires earth_magic 2

<!--@ hell_events.json | hell_lava_flow | choices.earth_magic.text -->
Use earth magic to create a stone bridge
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 10`

<!--@ hell_events.json | hell_lava_flow | choices.earth_magic.outcome.text -->
You reach into the bedrock beneath the lava flow and pull. Stone rises, hissing and steaming, forming a crude but solid bridge above the molten river. The lava laps at it furiously but cannot melt it fast enough.

You cross safely, and the bridge will last long enough for others to follow — a small act of kindness in an unkind place.
<!--@end-->


#### **quick_dashes** — *blue* — requires **trait: quick**

<!--@ hell_events.json | hell_lava_flow | choices.quick_dashes.text -->
You have always been faster than the situation requires.
<!--@end-->


*Outcome*

`xp: 10`

<!--@ hell_events.json | hell_lava_flow | choices.quick_dashes.outcome.text -->
The gap is not really a gap. You are across it before it has finished being one, and the second surge arrives where you were standing rather than where you are.

You throw the rope back for everyone else.
<!--@end-->


#### **stubborn_refuses_around** — *blue* — requires **trait: stubborn**

<!--@ hell_events.json | hell_lava_flow | choices.stubborn_refuses_around.text -->
There is a way across. Going around is not a way across.
<!--@end-->


*Outcome*

`xp: 10  ·  pressure: earth-5`

<!--@ hell_events.json | hell_lava_flow | choices.stubborn_refuses_around.outcome.text -->
Everyone else has already agreed to go around and you have not, and the argument takes twenty minutes that could have been spent walking.

You are, in the end, correct: the crossing exists. It is also true that the twenty minutes cost more than the detour would have.
<!--@end-->


#### **go_around** — *grey*

<!--@ hell_events.json | hell_lava_flow | choices.go_around.text -->
Look for a way around the lava flow
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 2`

<!--@ hell_events.json | hell_lava_flow | choices.go_around.outcome.text -->
You follow the lava flow downstream until you find a narrow point where the ground is merely scorching rather than deadly. After a careful crossing, you continue on your way — slower, but unburned.
<!--@end-->


---

## hell_ancient_stupa

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ancient_stupa | title -->
Ancient Stupa
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ancient_stupa | text -->
A crumbling stupa rises from the snow, its dome still intact after countless ages. Tattered prayer flags still flutter from the crown, faded but unbroken. Mantras are carved into every stone.
<!--@end-->


### Choices


#### **circumambulate** — *grey*

<!--@ hell_events.json | hell_ancient_stupa | choices.circumambulate.text -->
Walk around it three times in devotion
<!--@end-->


*Outcome*

`karma: god+3, human+3, hell-3  ·  xp: 5`

<!--@ hell_events.json | hell_ancient_stupa | choices.circumambulate.outcome.text -->
As you circle it clockwise three times; the cold seems to lessen. You place a small offering at the base and leave.
<!--@end-->


#### **meditate** — *blue* — requires yoga 2

<!--@ hell_events.json | hell_ancient_stupa | choices.meditate.text -->
Meditate at the stupa's base
<!--@end-->


*Outcome*

`karma: god+5, human+3, hell-3  ·  xp: 8`

<!--@ hell_events.json | hell_ancient_stupa | choices.meditate.outcome.text -->
Seeing the work of so many hands towards creating a better tomorrow fills you with determination.
<!--@end-->


#### **study** — *blue* — requires ritual 1

<!--@ hell_events.json | hell_ancient_stupa | choices.study.text -->
Study the carved mantras closely
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 8  ·  learn_spell: {'school': 'white_magic', 'level_range': [1, 2]}`

<!--@ hell_events.json | hell_ancient_stupa | choices.study.outcome.text -->
You study the faded letters until they become clearer.
<!--@end-->


#### **prayer_flags** — *blue* — requires air_magic 1

<!--@ hell_events.json | hell_ancient_stupa | choices.prayer_flags.text -->
Study the prayer flags and what sustains them
<!--@end-->


*Outcome*

`karma: god+2, human+2  ·  xp: 8`

<!--@ hell_events.json | hell_ancient_stupa | choices.prayer_flags.outcome.text -->
Somehow kept together by their inner charge rather than outer weave, the flags can still teach you something about how intention outlasts form.
<!--@end-->


#### **pilgrim_circuit** — *blue* — requires **trait: pilgrim**

<!--@ hell_events.json | hell_ancient_stupa | choices.pilgrim_circuit.text -->
Walk the full circuit. Three times, the correct direction.
<!--@end-->


*Outcome*

`karma: human+3, god+3  ·  xp: 20  ·  items: ['item_random']`

<!--@ hell_events.json | hell_ancient_stupa | choices.pilgrim_circuit.outcome.text -->
It takes the better part of an hour in cold that makes an hour expensive.

On the third circuit you notice the thing the first two missed: a niche at the base, sheltered from the wind, with something still in it.
<!--@end-->


#### **renunciate_leaves_it** — *blue* — requires **trait: renunciate**

<!--@ hell_events.json | hell_ancient_stupa | choices.renunciate_leaves_it.text -->
You are carrying something you have been meaning to put down.
<!--@end-->


*Outcome*

`xp: 20  ·  add_trait: renunciate  ·  pressure: fire+15, earth+8`

<!--@ hell_events.json | hell_ancient_stupa | choices.renunciate_leaves_it.outcome.text -->
You put it in the niche. It is not an offering exactly — nobody is being asked for anything — it is simply somewhere to leave a thing so that it stops being yours.

You walk on lighter by an amount that has nothing to do with the weight.
<!--@end-->


#### **leave_offering** — *grey*

<!--@ hell_events.json | hell_ancient_stupa | choices.leave_offering.text -->
Leave a small offering and move on
<!--@end-->


*Outcome*

`karma: god+2, human+2, hell-2  ·  xp: 4`

<!--@ hell_events.json | hell_ancient_stupa | choices.leave_offering.outcome.text -->
You leave a few coins. The flags flutter in farewell.
<!--@end-->


---

## hell_demon_checkpoint

`realm: hell`

**Title**

<!--@ hell_events.json | hell_demon_checkpoint | title -->
Demon Checkpoint
<!--@end-->


**Body**

<!--@ hell_events.json | hell_demon_checkpoint | text -->
A wobbly table has been set up across the path. Behind it, a bureaucratic demon in a stained uniform holds a quill the size of a sword.

"Halt. Passage permit, please. Standard Form 7-B, the one authorizing inter-zone traversal for damned entities. You do have a Form 7-B, yes?"

You do not have a Form 7-B. Form 7-B does not exist.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_demon_checkpoint | choices.fight.text -->
Push past the checkpoint by force
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+2, hell+2`

<!--@ hell_events.json | hell_demon_checkpoint | choices.fight.outcome.text -->
The bureaucrat sounds a horn taken seemingly out of thin air.
<!--@end-->


#### **forge** — *blue* — requires guile 2

<!--@ hell_events.json | hell_demon_checkpoint | choices.forge.text -->
Produce a convincing-looking document
<!--@end-->


*Outcome*

`karma: hungry_ghost+2, human+2  ·  xp: 8`

<!--@ hell_events.json | hell_demon_checkpoint | choices.forge.outcome.text -->
You manage to quickly fold some parchment into an official-looking shape; the demon examines it upside down with a bored expression and stamps it.
<!--@end-->


#### **bribe** — *grey*

<!--@ hell_events.json | hell_demon_checkpoint | choices.bribe.text -->
Slip the demon a bribe
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, asura+1  ·  xp: 4`

<!--@ hell_events.json | hell_demon_checkpoint | choices.bribe.outcome.text -->
Gold changes hands; "Everything checks out. Move along."
<!--@end-->


#### **argue** — *blue* — requires persuasion 3

<!--@ hell_events.json | hell_demon_checkpoint | choices.argue.text -->
Challenge the checkpoint's legal legitimacy
<!--@end-->


*Outcome*

`karma: human+4, hell-2  ·  xp: 10`

<!--@ hell_events.json | hell_demon_checkpoint | choices.argue.outcome.text -->
A 40-minute forensic argument takes place. The bureaucrat is shaken and visibly tired. Finally, he waves you through, muttering to himself.
<!--@end-->


#### **comedy_license** — *blue* — requires comedy 2

<!--@ hell_events.json | hell_demon_checkpoint | choices.comedy_license.text -->
Point out that you cannot be subject to an official without a valid 16-F operating license
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 10`

<!--@ hell_events.json | hell_demon_checkpoint | choices.comedy_license.outcome.text -->
Stumped at first, the devil taps his quill against his chin, then nods slowly. Game recognizes game. He waves you through without another word.
<!--@end-->


#### **debtor_avoids** — *blue* — requires **trait: debtor**

<!--@ hell_events.json | hell_demon_checkpoint | choices.debtor_avoids.text -->
Do not give your name. Do not give any name.
<!--@end-->


*Outcome*

`xp: 30  ·  pressure: air-8`

<!--@ hell_events.json | hell_demon_checkpoint | choices.debtor_avoids.outcome.text -->
The clerk wants a name for the ledger and you supply one, fluently, along with a district and a plausible reason for travel.

It is not your name. You have had a great deal of practice at this and it shows in all the wrong ways.
<!--@end-->


#### **braggart_talks_through** — *blue* — requires **trait: braggart**

<!--@ hell_events.json | hell_demon_checkpoint | choices.braggart_talks_through.text -->
Talk. Keep talking. Do not stop talking.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hell_events.json | hell_demon_checkpoint | choices.braggart_talks_through.outcome.text -->
Forty minutes later the clerk has heard about three campaigns you were not in, a title you do not hold, and a mutual acquaintance who does not exist.

He stamps the form to make it stop.
<!--@end-->


#### **patient_waits_it_out** — *blue* — requires **trait: patient**

<!--@ hell_events.json | hell_demon_checkpoint | choices.patient_waits_it_out.text -->
It is a clerk with a form. Let him have his form.
<!--@end-->


*Outcome*

`xp: 10`

<!--@ hell_events.json | hell_demon_checkpoint | choices.patient_waits_it_out.outcome.text -->
You answer every question in order, including the four that are the same question, and you do not once indicate that you have noticed.

The clerk, who is braced for a fight the way clerks always are, has nothing to push against and stamps the thing in half the usual time.
<!--@end-->


#### **hot_tempered_snaps** — *blue* — requires **trait: hot_tempered**

<!--@ hell_events.json | hell_demon_checkpoint | choices.hot_tempered_snaps.text -->
You have been standing at this table for a very long time.
<!--@end-->


*Outcome*

`xp: 10  ·  gold: -15  ·  pressure: water-12`

<!--@ hell_events.json | hell_demon_checkpoint | choices.hot_tempered_snaps.outcome.text -->
You are two sentences into telling him what you think of the table, the quill and the entire apparatus before anyone can get a hand on your arm.

The form is stamped eventually. It is stamped with an annotation, and the annotation will be waiting at the next checkpoint.
<!--@end-->


#### **forge_pass** — *blue* — requires thievery 3

<!--@ hell_events.json | hell_demon_checkpoint | choices.forge_pass.text -->
Lift the official seal and forge yourself a transit pass
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, human+1  ·  xp: 10`

<!--@ hell_events.json | hell_demon_checkpoint | choices.forge_pass.outcome.text -->
While arguing about Section 12, Subsection B, you palm the bureaucrat's official seal from the desk. A minute later you hand over a transit pass that is, technically, correct in every particular except that you wrote it yourself.

The demon examines it at length. Stamps it. Files it. Waves you through.

'Everything in order. Move along.'
<!--@end-->


---

## hell_ice_oracle

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ice_oracle | title -->
Ice Oracle
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ice_oracle | text -->
A figure is frozen solid inside a pillar of ice — upright, arms folded, expression serene. When you come near, you hear a strange voice from within your head:

"I have been here since time lost to memory. I have watched many pass through, time and time again. Ask, and I may answer."
<!--@end-->


### Choices


#### **ask_ahead** — *grey*

<!--@ hell_events.json | hell_ice_oracle | choices.ask_ahead.text -->
Ask what lies ahead on your path
<!--@end-->


*Outcome*

`karma: human+3, god+3  ·  xp: 6`

<!--@ hell_events.json | hell_ice_oracle | choices.ask_ahead.outcome.text -->
"Fear and hope, then hope and fear. Until one day the natural state blooms in your awareness, and you shall be free, as you always really were."
<!--@end-->


#### **commune** — *blue* — requires space_magic 3

<!--@ hell_events.json | hell_ice_oracle | choices.commune.text -->
Open your mind and commune with it directly
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 10`

<!--@ hell_events.json | hell_ice_oracle | choices.commune.outcome.text -->
You sense countless centuries of sentient beings passing to and fro, their fears and small kindnesses. You settle in a deep clarity.
<!--@end-->


#### **ask_realm** — *blue* — requires awareness 15

<!--@ hell_events.json | hell_ice_oracle | choices.ask_realm.text -->
Ask about the nature of this realm
<!--@end-->


*Outcome*

`karma: god+4, human+4, hell-3  ·  xp: 10`

<!--@ hell_events.json | hell_ice_oracle | choices.ask_realm.outcome.text -->
"This realm, like all realms, is a mirror."
<!--@end-->


#### **comedy_oracle** — *blue* — requires comedy 2

<!--@ hell_events.json | hell_ice_oracle | choices.comedy_oracle.text -->
You've been here since time immemorial and still haven't found a way out — not sure I should be taking advice
<!--@end-->


*Outcome*

`karma: human+2, asura+1  ·  xp: 5`

<!--@ hell_events.json | hell_ice_oracle | choices.comedy_oracle.outcome.text -->
A long silence. Then, from somewhere within the ice, a sound like grinding stone that might be a laugh. "Ha. The first wit in eight hundred years." Something like self-doubt flickers in those ancient eyes — and something else. Respect.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_ice_oracle | choices.leave.text -->
Thank it for its time and move on
<!--@end-->


*Outcome*

`karma: human+1, god+1  ·  xp: 4`

<!--@ hell_events.json | hell_ice_oracle | choices.leave.outcome.text -->
"Seek out situations to exercise compassion."
<!--@end-->


#### **clear_eyed_discounts** — *blue* — requires **trait: clear_eyed**

<!--@ hell_events.json | hell_ice_oracle | choices.clear_eyed_discounts.text -->
Listen to the prophecy. Then discount it correctly.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hell_events.json | hell_ice_oracle | choices.clear_eyed_discounts.outcome.text -->
She says four things. Two are true of anyone, one is unfalsifiable, and the fourth is specific, checkable, and delivered in a completely different tone from the others.

You keep the fourth. It is worth keeping.
<!--@end-->


#### **superstitious_takes_all** — *blue* — requires **trait: superstitious**

<!--@ hell_events.json | hell_ice_oracle | choices.superstitious_takes_all.text -->
Every word of it matters. Write it down.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: air-8, space-5`

<!--@ hell_events.json | hell_ice_oracle | choices.superstitious_takes_all.outcome.text -->
You get all of it, including the parts she probably did not mean as prophecy.

For the next several days you will be interpreting ordinary events as fulfilments, which is exhausting, and once — just once — extremely useful.
<!--@end-->


#### **riddle_exchange** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_ice_oracle | choices.riddle_exchange.text -->
Pose it a riddle in return — meet its strangeness with your own
<!--@end-->


*Outcome — success*

`karma: human+3, asura+2  ·  xp: 15`

<!--@ hell_events.json | hell_ice_oracle | choices.riddle_exchange.outcome_success.text -->
The oracle is silent for long enough you think you've failed. Then, with something that sounds like appreciation: 'That one I have not heard.' It answers your original question fully and adds something you hadn't thought to ask.
<!--@end-->


*Outcome — failure*

`xp: 4`

<!--@ hell_events.json | hell_ice_oracle | choices.riddle_exchange.outcome_failure.text -->
'I knew this one before your realm existed,' the oracle says without cruelty, and falls silent again. There is nothing further to be gotten from it today.
<!--@end-->


---

## hell_ghost_village

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ghost_village | title -->
The Ghost Village
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ghost_village | text -->
Stone buildings stand perfectly preserved — doors hanging open, fires long dead, a well at the center still intact. Not a soul visible, but the air feels thick with watching.

This was a place once. Something happened here, in some other age, and whatever it was left the buildings standing but took everyone away.
<!--@end-->


### Choices


#### **search** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | hell_ghost_village | choices.search.text -->
Search the buildings carefully
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8  ·  items: ['health_potion', 'mana_potion']`

<!--@ hell_events.json | hell_ghost_village | choices.search.outcome_success.text -->
You move carefully through the empty houses, reading the signs: a half-finished meal, a child's toy, writing on a wall in a language you only half understand. Someone was in the middle of living here.

In a locked strongbox beneath the largest hearth, you find what they left behind.
<!--@end-->


*Outcome — failure*

`xp: 3`

<!--@ hell_events.json | hell_ghost_village | choices.search.outcome_failure.text -->
You search, but the village gives up nothing. Whatever was here has long since been taken — by other travelers, by time, or by whatever emptied this place.

As you leave, you hear what might be footsteps from inside a house you already checked. You don't go back.
<!--@end-->


#### **pay_respects** — *grey*

<!--@ hell_events.json | hell_ghost_village | choices.pay_respects.text -->
Go to the village center and pay your respects
<!--@end-->


*Outcome*

`karma: god+3, human+3, hell-2  ·  xp: 5`

<!--@ hell_events.json | hell_ghost_village | choices.pay_respects.outcome.text -->
You stand at the well and bow your head. A prayer rises naturally — for whoever lived here, for whatever ended this place, for the possibility that even abandoned things can be honored.

Something shifts. The watching feeling becomes less like surveillance and more like gratitude.
<!--@end-->


#### **call_out** — *blue* — requires persuasion 1

<!--@ hell_events.json | hell_ghost_village | choices.call_out.text -->
Call out to the spirits of this place
<!--@end-->


*Outcome*

`karma: human+5, hell-3  ·  xp: 10`

<!--@ hell_events.json | hell_ghost_village | choices.call_out.outcome.text -->
You stand at the village center and speak: 'I know you're here. I'm not here to take anything. I just want to understand.'

For a long moment, nothing. Then a presence — not frightening, just profoundly sad — brushes past you like a cold wind with shape.

Images: a flood, a night with no stars, the decision to stay and wait for someone who never came. Then nothing.
<!--@end-->


#### **smoke_offering** — *blue* — requires ritual 3

<!--@ hell_events.json | hell_ghost_village | choices.smoke_offering.text -->
Prepare a smoke offering for the lingering spirits
<!--@end-->


*Outcome*

`karma: human+3, god+3, hell-2  ·  xp: 8  ·  add_trait: mourner`

<!--@ hell_events.json | hell_ghost_village | choices.smoke_offering.outcome.text -->
"Ghosts, gods, lords of this land — come forth and take your fill in peace!"

The smoke rises in spirals more purposeful than the wind allows. The watching presence gathers around the offering. For a moment, the village feels inhabited again.
<!--@end-->


#### **summon_spirit** — *blue* — requires summoning 3

<!--@ hell_events.json | hell_ghost_village | choices.summon_spirit.text -->
Compel a spirit to speak directly
<!--@end-->


*Outcome*

`karma: human+4, hell-3  ·  xp: 12  ·  items: ['soul_stone']`

<!--@ hell_events.json | hell_ghost_village | choices.summon_spirit.outcome.text -->
You speak the words of compulsion and a presence coalesces at the well — not comfortable about it, but present. A shape like a man, with no features you can hold in mind.

'You pulled me back.' Not angry. Just tired. 'Ask, then.'

You ask what happened here. It tells you, precisely and without sentiment. A plague, a decision, a long argument about whether to stay or go, and the people who chose wrong and knew it immediately. You listen until it dissolves on its own.

The village doesn't feel empty anymore — it feels, now, like somewhere that used to be full.
<!--@end-->


#### **mourner_keeps_days** — *blue* — requires **trait: mourner**

<!--@ hell_events.json | hell_ghost_village | choices.mourner_keeps_days.text -->
Do what nobody has done here in a long time: keep their days.
<!--@end-->


*Outcome*

`karma: human+5, hungry_ghost-5  ·  xp: 20  ·  pressure: water+15`

<!--@ hell_events.json | hell_ghost_village | choices.mourner_keeps_days.outcome.text -->
You do not know their names or their calendar, so you use yours, and you set out what can be spared at each door rather than at the centre.

It takes all afternoon. By the end the village is not less empty, but it is differently empty.
<!--@end-->


#### **secret_bearer_recognises** — *blue* — requires **trait: secret_bearer**

<!--@ hell_events.json | hell_ghost_village | choices.secret_bearer_recognises.text -->
You know what a place looks like when everyone left at once and nobody wrote it down.
<!--@end-->


*Outcome*

`xp: 20  ·  items: ['item_random']`

<!--@ hell_events.json | hell_ghost_village | choices.secret_bearer_recognises.outcome.text -->
You find it because you know where a person puts a thing they do not want found: not hidden, just somewhere nobody would look twice.

Under the well's coping stone, wrapped in cloth. An account. It does not make good reading and it is worth carrying.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_ghost_village | choices.leave.text -->
Leave the village alone
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_ghost_village | choices.leave.outcome.text -->
You walk through without stopping, keeping your eyes forward. Some places hold their silence for a reason.

The watching feeling follows you for a while, then fades.
<!--@end-->


---

## hell_lava_swimmer

`realm: hell`

**Title**

<!--@ hell_events.json | hell_lava_swimmer | title -->
The Lava Swimmer
<!--@end-->


**Body**

<!--@ hell_events.json | hell_lava_swimmer | text -->
Something enormous moves beneath the surface of a lava flow. As you watch, it surfaces — a serpentine creature forty meters long, its scales glowing like cooling magma, its eyes containing a fire that is not hot but old.

It regards you with what you can only describe as curiosity. It is not aggressive. It has simply noticed you, in the way that very old things notice small things that interest them.
<!--@end-->


### Choices


#### **observe** — *grey*

<!--@ hell_events.json | hell_lava_swimmer | choices.observe.text -->
Watch it in respectful silence
<!--@end-->


*Outcome*

`karma: animal+2, human+4  ·  xp: 6`

<!--@ hell_events.json | hell_lava_swimmer | choices.observe.outcome.text -->
You stand still and watch. The creature rises and sinks, performing what might be a display or might simply be how it exists. Its movements are mesmerizing — fluid despite the medium, graceful in a way that should not be possible in molten rock.

After a time, it sinks below the surface. The lava glows a little brighter where it passed.
<!--@end-->


#### **commune_fire** — *blue* — requires fire_magic 2

<!--@ hell_events.json | hell_lava_swimmer | choices.commune_fire.text -->
Attempt to commune with it through fire magic
<!--@end-->


*Outcome*

`karma: animal+4, god+3  ·  xp: 14`

<!--@ hell_events.json | hell_lava_swimmer | choices.commune_fire.outcome.text -->
You extend your awareness through fire, and the creature responds immediately — not with words, but with sensation: the pleasure of heat, the memory of a world younger and hotter, the understanding that fire is not destruction but transformation.

When the contact ends, you carry something of that understanding with you. Afterwards your experience of heat seems somehow deeper, more meaningful.
<!--@end-->


#### **offering** — *grey*

<!--@ hell_events.json | hell_lava_swimmer | choices.offering.text -->
Drop something metallic into the lava as an offering
<!--@end-->


*Outcome*

`karma: animal+3  ·  xp: 5  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_lava_swimmer | choices.offering.outcome.text -->
You toss a few coins into the flow. The creature's head rises immediately, watching where the metal sank. It dips below the surface and returns a moment later, nudging something up toward the edge.

A gem — fire opal — glowing with internal heat. It seems this creature values the exchange.
<!--@end-->


#### **perform_awe** — *blue* — requires performance 3

<!--@ hell_events.json | hell_lava_swimmer | choices.perform_awe.text -->
Sit down and begin playing — let the awe move through you into music
<!--@end-->


*Outcome*

`karma: animal+4, human+3, god+2  ·  xp: 10`

<!--@ hell_events.json | hell_lava_swimmer | choices.perform_awe.outcome.text -->
A melody comes, slowly at first. The creature surfaces again and stays, its great head resting at the lava's edge, watching. Two strange witnesses to each other's existence, sharing something that has no name.
<!--@end-->


#### **attack** — *grey*

<!--@ hell_events.json | hell_lava_swimmer | choices.attack.text -->
Attack the creature while it's surfaced
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: lava_guardian  ·  difficulty: hard  ·  karma: animal-5, hell+3`

<!--@ hell_events.json | hell_lava_swimmer | choices.attack.outcome.text -->
The creature's ancient eyes shift from curious to something cold and purposeful. It moves faster than anything its size should be able to move.
<!--@end-->


#### **hunter_reads_it** — *blue* — requires **trait: hunter**

<!--@ hell_events.json | hell_lava_swimmer | choices.hunter_reads_it.text -->
Watch how it moves. Everything that hunts has a pattern.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hell_events.json | hell_lava_swimmer | choices.hunter_reads_it.outcome.text -->
It surfaces on a count. Not a regular one — it is hunting the vents, not the surface — but a count, and once you have it you know where it will not be for about eleven seconds at a time.

Eleven seconds is enough.
<!--@end-->


#### **study_rhythm** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_lava_swimmer | choices.study_rhythm.text -->
Study its movements carefully — enormous things have patterns
<!--@end-->


*Outcome — success*

`karma: animal+3, human+2  ·  xp: 10`

<!--@ hell_events.json | hell_lava_swimmer | choices.study_rhythm.outcome_success.text -->
There is a rhythm. Surface, breathe, submerge — every fourteen seconds, always returning to the same channel. You watch long enough to see something you hadn't expected: shapes on its back, almost like writing. Whoever or whatever this creature was before hell, it was marked.
<!--@end-->


*Outcome — failure*

`karma: animal+1  ·  xp: 3  ·  hp_loss: {'amount': 'small', 'target': 'all'}`

<!--@ hell_events.json | hell_lava_swimmer | choices.study_rhythm.outcome_failure.text -->
You are still reading its movement when it surfaces directly in front of you — wave of heat, displaced lava, the ground lurching. You scramble back, singed and startled.
<!--@end-->


---

## hell_demon_dojo

`realm: hell`

**Title**

<!--@ hell_events.json | hell_demon_dojo | title -->
The Demon Dojo
<!--@end-->


**Body**

<!--@ hell_events.json | hell_demon_dojo | text -->
A stone courtyard surrounded by scorched walls, where a dozen demons practice combat forms with absolute precision. There is something almost beautiful about it — the focus, the discipline, the complete commitment to mastery.

The sensei demon — larger than the others, covered in old scars — spots you and points with a clawed finger. Then gestures inward. An invitation.
<!--@end-->


### Choices


#### **train** — *blue* — requires strength 12

<!--@ hell_events.json | hell_demon_dojo | choices.train.text -->
Join the training session
<!--@end-->


*Outcome*

`karma: asura+4, human+2  ·  xp: 12`

<!--@ hell_events.json | hell_demon_dojo | choices.train.outcome.text -->
You strip off your pack and join the ranks. The sensei demon watches you critically, adjusting your stance twice without gentleness. The training is brutal but honest — no cruelty, just high standards.

An hour later, bruised and exhausted, you bow. The sensei returns the bow — once, precisely. You have been accepted as a student, at least for today.
<!--@end-->


#### **spar** — *yellow* — requires roll finesse vs easy

<!--@ hell_events.json | hell_demon_dojo | choices.spar.text -->
Challenge one demon to a friendly bout
<!--@end-->


*Outcome — success*

`karma: asura+5, human+3  ·  xp: 10`

<!--@ hell_events.json | hell_demon_dojo | choices.spar.outcome_success.text -->
You bow to your opponent and take your stance. It's a hard fight — the demon is fast and skilled — but you hold your own, forcing it back several times.

The bout ends in a draw by mutual acknowledgment. The other demons stamp their feet in approval. You have earned something here that is not easily named.
<!--@end-->


*Outcome — failure*

`karma: asura+2, human+2  ·  xp: 5`

<!--@ hell_events.json | hell_demon_dojo | choices.spar.outcome_failure.text -->
You are put flat on your back within thirty seconds. The demon stands over you, then offers a hand up. The others are not unkind about it — they have all been put on their backs before.

'Again,' the sensei says. You last longer the second time.
<!--@end-->


#### **watch** — *blue* — requires learning 1

<!--@ hell_events.json | hell_demon_dojo | choices.watch.text -->
Observe the forms carefully without participating
<!--@end-->


*Outcome*

`karma: asura+2, human+3  ·  xp: 8`

<!--@ hell_events.json | hell_demon_dojo | choices.watch.outcome.text -->
You find a wall to lean against and watch. These forms are old — older than you expected, derived from styles you half-recognize. The demons practice them with perfect fidelity, generation after generation.

You learn more from watching than you could from participation. Certain sequences embed themselves in your muscle memory through pure observation.
<!--@end-->


#### **unarmed_technique** — *blue* — requires unarmed 3

<!--@ hell_events.json | hell_demon_dojo | choices.unarmed_technique.text -->
Demonstrate your empty-hand technique
<!--@end-->


*Outcome*

`karma: asura+4, human+3  ·  xp: 12`

<!--@ hell_events.json | hell_demon_dojo | choices.unarmed_technique.outcome.text -->
You step onto the practice floor without a weapon. The training stops. The sensei crosses its arms and watches. You run through your forms — clean, deliberate, unflinching. When you finish, the demons exchange a look. The sensei inclines its head once.

'Not our style. But real.' You train alongside them for an hour. The forms absorb each other at the edges.
<!--@end-->


#### **leadership_session** — *blue* — requires leadership 4

<!--@ hell_events.json | hell_demon_dojo | choices.leadership_session.text -->
Assert yourself as a senior practitioner — take over the session
<!--@end-->


*Outcome*

`karma: asura+3, human+4  ·  xp: 14`

<!--@ hell_events.json | hell_demon_dojo | choices.leadership_session.outcome.text -->
You step in and redirect the group through a correction sequence — you've seen this error before, in better-equipped dojos. The sensei observes with narrowed eyes. Then steps back.

You run the session for thirty minutes. The demons are better for it. The sensei says nothing at the end, which is the only acknowledgment available.
<!--@end-->


#### **ascetic_forms** — *blue* — requires **trait: ascetic**

<!--@ hell_events.json | hell_demon_dojo | choices.ascetic_forms.text -->
Ask to stand in the back row and do the forms with them.
<!--@end-->


*Outcome*

`xp: 20  ·  skill_up: {'skill': 'martial_arts', 'amount': 1}`

<!--@ hell_events.json | hell_demon_dojo | choices.ascetic_forms.outcome.text -->
Nobody objects. Nobody helps, either — you get the form wrong for two hours and are corrected exactly once, by a demon who does not break their own rhythm to do it.

The correction is worth the two hours.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_demon_dojo | choices.leave.text -->
Decline the invitation and move on
<!--@end-->


*Outcome*

`karma: asura+1`

<!--@ hell_events.json | hell_demon_dojo | choices.leave.outcome.text -->
You bow respectfully at the entrance and continue on your way. The sensei watches you leave without expression. The training continues without pause.
<!--@end-->


---

## hell_infernal_archive

`realm: hell`

**Title**

<!--@ hell_events.json | hell_infernal_archive | title -->
The Infernal Archive
<!--@end-->


**Body**

<!--@ hell_events.json | hell_infernal_archive | text -->
A tower of black basalt rising from the badlands, its windows glowing orange from within. The sign above the door reads: INFERNAL ARCHIVE — RESTRICTED MATERIALS.

The librarian demon at the desk looks up as you enter. It is ancient, patient, and wearing spectacles that have somehow survived the volcanic atmosphere. It regards you with the professional suspicion of someone who has seen too many people try to steal restricted materials.
<!--@end-->


### Choices


#### **browse_legal** — *grey*

<!--@ hell_events.json | hell_infernal_archive | choices.browse_legal.text -->
Request access to the unrestricted section
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 8  ·  items: ['scroll_lesser_heal']`

<!--@ hell_events.json | hell_infernal_archive | choices.browse_legal.outcome.text -->
The librarian processes your request with the efficiency of someone who processes requests all day, every day, eternally.

'Section Three. No fire. No food. No summoning.' It hands you a reading pass. You spend an hour in the stacks, reading accounts of previous hell realm travelers — their strategies, their mistakes, their occasional triumphs.
<!--@end-->


#### **restricted_section** — *blue* — requires guile 2

<!--@ hell_events.json | hell_infernal_archive | choices.restricted_section.text -->
Access the restricted collection
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, hell+1  ·  xp: 12  ·  items: ['scroll_firebolt']`

<!--@ hell_events.json | hell_infernal_archive | choices.restricted_section.outcome.text -->
When the librarian turns to assist another patron, you slip through the RESTRICTED door. The books here are bound in materials you do not want to think about, their titles written in languages that hurt to read.

You find what you're looking for and memorize key passages before returning to your seat before the librarian turns back. The knowledge is valuable. It cost nothing except a small, lingering unease.
<!--@end-->


#### **research_trade** — *blue* — requires trade 2

<!--@ hell_events.json | hell_infernal_archive | choices.research_trade.text -->
Commission research on local trade routes
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6`

<!--@ hell_events.json | hell_infernal_archive | choices.research_trade.outcome.text -->
You pay the librarian's research fee and request maps of commerce through the hell realm. It returns with three scrolls detailing merchant routes, safe passage times, and which demons respond to bribery versus which prefer other forms of persuasion.

The librarian accepts your payment without expression. This is, apparently, a common request.
<!--@end-->


#### **physical_locks** — *blue* — requires thievery 3

<!--@ hell_events.json | hell_infernal_archive | choices.physical_locks.text -->
Bypass the physical locks on the forbidden vault
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, hell+2  ·  xp: 14  ·  items: ['scroll_firebolt', 'mana_potion']`

<!--@ hell_events.json | hell_infernal_archive | choices.physical_locks.outcome.text -->
There's a physical vault behind the restricted stacks — older than the archive, predating whatever bureaucracy runs this place. The locks are mechanical, not magical, which means they respond to skill rather than credentials.

Fifteen minutes of careful work. The vault opens on a collection that even the restricted section doesn't have clearance for. You read quickly, memorize what you can, and leave before the librarian notices the vault is open.

The knowledge is extraordinary. You are also immediately on at least three lists you were not on before.
<!--@end-->


#### **curious_reads** — *blue* — requires **trait: curious**

<!--@ hell_events.json | hell_infernal_archive | choices.curious_reads.text -->
You will not be leaving until you have read something.
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hell_events.json | hell_infernal_archive | choices.curious_reads.outcome.text -->
The archivist watches you work through two centuries of tax records with the expression of a man who has finally met someone worse than himself.

Between the ledgers: a requisition order, countersigned, for something that was never delivered. You copy the name.
<!--@end-->


#### **sharp_memory_holds** — *blue* — requires **trait: sharp_memory**

<!--@ hell_events.json | hell_infernal_archive | choices.sharp_memory_holds.text -->
Read it once. You will have it.
<!--@end-->


*Outcome*

`xp: 12  ·  skill_up: {'skill': 'learning', 'amount': 1}`

<!--@ hell_events.json | hell_infernal_archive | choices.sharp_memory_holds.outcome.text -->
You read the index rather than the books, which is faster and, for you, sufficient. Nine hundred entries. You will be able to produce any of them on request for the rest of this life.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_infernal_archive | choices.leave.text -->
The archive's atmosphere is too unsettling — leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_infernal_archive | choices.leave.outcome.text -->
You back out of the archive. The librarian watches you go without comment. Behind you, the orange glow from the windows continues its eternal, patient burn.
<!--@end-->


---

## hell_fire_pilgrim

`realm: hell`

**Title**

<!--@ hell_events.json | hell_fire_pilgrim | title -->
The Fire Pilgrim
<!--@end-->


**Body**

<!--@ hell_events.json | hell_fire_pilgrim | text -->
A figure in scorched white robes moves through the fire hell on their knees, hands pressed together, murmuring prayers with every measured movement. Burns mark their skin. Their progress is agonizingly slow.

They look up as you approach. Their eyes are clear — no delusion, no despair, just an absolute and deliberate acceptance of each moment of pain.
<!--@end-->


### Choices


#### **heal** — *blue* — requires medicine 1

<!--@ hell_events.json | hell_fire_pilgrim | choices.heal.text -->
Heal their burns and walk with them a while
<!--@end-->


*Outcome*

`karma: god+6, human+5, hell-4  ·  xp: 12  ·  items: ['prayer_beads']`

<!--@ hell_events.json | hell_fire_pilgrim | choices.heal.outcome.text -->
You tend to their wounds as best you can. They do not ask you to stop the pilgrimage — they do not want to stop. But the relief in their eyes at having another person near them is unmistakable.

You walk beside them for an hour. They speak of their life, their error, their choice to make this journey rather than wait for absolution. When you part, they press a small carved token into your hands.

'Carry it until you don't need it anymore. Then give it to someone who does.'
<!--@end-->


#### **walk_with** — *grey*

<!--@ hell_events.json | hell_fire_pilgrim | choices.walk_with.text -->
Walk alongside them in silence
<!--@end-->


*Outcome*

`karma: god+4, human+4, hell-2  ·  xp: 6`

<!--@ hell_events.json | hell_fire_pilgrim | choices.walk_with.outcome.text -->
You fall into step beside them — upright, while they crawl, but present. They do not ask why you've joined them, and you don't explain.

For a quarter mile, you walk in silence. Their prayers continue without pause. When you must go a different direction, you bow to each other, and they return the bow without interrupting their rhythm.
<!--@end-->


#### **ask_purpose** — *grey*

<!--@ hell_events.json | hell_fire_pilgrim | choices.ask_purpose.text -->
Ask them about their pilgrimage
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hell_events.json | hell_fire_pilgrim | choices.ask_purpose.outcome.text -->
'I burned a library,' they say simply, without stopping. 'Hundreds of years of knowledge, gone in one night. I was angry at the man who owned it. I didn't think about what it contained.'

A pause in the prayer, then: 'I have been walking since then. I will walk until I understand, truly understand, what was in those books. What was lost. Who was harmed.' Another step. 'I don't know how long that will take.'
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_fire_pilgrim | choices.leave.text -->
Let them continue their journey
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_fire_pilgrim | choices.leave.outcome.text -->
You step aside to let them pass. Their prayers continue without acknowledgment of your presence or your departure. This journey belongs entirely to them.
<!--@end-->


#### **walk_the_path** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_fire_pilgrim | choices.walk_the_path.text -->
Lower yourself to your knees and walk the fire path alongside them for a while
<!--@end-->


*Outcome — success*

`karma: human+5, god+3  ·  xp: 15`

<!--@ hell_events.json | hell_fire_pilgrim | choices.walk_the_path.outcome_success.text -->
The fire hurts, but you find the pilgrim's rhythm and hold it. When you eventually rise, they turn for the first time and look at you — really look. They press their hands together and bow. No words. You understand anyway.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 6  ·  hp_loss: {'amount': 'tiny', 'target': 'all'}`

<!--@ hell_events.json | hell_fire_pilgrim | choices.walk_the_path.outcome_failure.text -->
You manage a few meters before your knees give and you have to stand. The pilgrim doesn't look back, but their murmured prayer seems to include something new in it. Perhaps you contributed something after all.
<!--@end-->


---

## hell_bone_arena

`realm: hell`

**Title**

<!--@ hell_events.json | hell_bone_arena | title -->
Bone Arena
<!--@end-->


**Body**

<!--@ hell_events.json | hell_bone_arena | text -->
A frozen pit ringed with bones rises from the wasteland — a combat arena, its tiers packed with demons howling for blood. Two poor souls fight below, stumbling with exhaustion.

A massive gatekeeper blocks the exit path, grinning with entirely too many rows of teeth. "Welcome, welcome! Do you come to bet or to fight?"
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_bone_arena | choices.fight.text -->
Step into the arena and fight
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+2, asura+5  ·  gold: moderate`

<!--@ hell_events.json | hell_bone_arena | choices.fight.outcome.text -->

<!--@end-->


#### **challenge** — *blue* — requires strength 15

<!--@ hell_events.json | hell_bone_arena | choices.challenge.text -->
Issue a formal challenge to the current champion
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_elite  ·  difficulty: hard  ·  karma: asura+5, human+3  ·  xp: 12  ·  gold: moderate  ·  items: ['good_iron_weapon']`

<!--@ hell_events.json | hell_bone_arena | choices.challenge.outcome.text -->
The gatekeeper nods with respect and lets you in.
<!--@end-->


#### **narrate** — *blue* — requires performance 3

<!--@ hell_events.json | hell_bone_arena | choices.narrate.text -->
Narrate the fight dramatically for the crowd
<!--@end-->


*Outcome*

`karma: asura+2, human+5  ·  xp: 10`

<!--@ hell_events.json | hell_bone_arena | choices.narrate.outcome.text -->
The crowd shifts from baying for blood to hanging on your words; gatekeeper laughs hard enough to let you through without charging.
<!--@end-->


#### **bet** — *grey*

<!--@ hell_events.json | hell_bone_arena | choices.bet.text -->
Bet on one of the fighters
<!--@end-->


*Outcome*

`karma: hell+2, asura+2, human+2  ·  xp: 5  ·  gamble: {'type': 'gold', 'win_chance': 0.5, 'win_multiplier': 2}`

<!--@ hell_events.json | hell_bone_arena | choices.bet.outcome.text -->
"Sure, take a seat in the tiers."
<!--@end-->


#### **knife_fight** — *blue* — requires daggers 3

<!--@ hell_events.json | hell_bone_arena | choices.knife_fight.text -->
Enter as a knife-fighter — blades against the arena's weapons
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+4, human+2  ·  xp: 12  ·  gold: moderate`

<!--@ hell_events.json | hell_bone_arena | choices.knife_fight.outcome.text -->
The crowd goes quiet as you draw blades instead of the expected weapon. Then louder.
<!--@end-->


#### **unarmed_fight** — *blue* — requires unarmed 3

<!--@ hell_events.json | hell_bone_arena | choices.unarmed_fight.text -->
Fight unarmed — no weapons, just technique
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+5  ·  xp: 12  ·  gold: moderate`

<!--@ hell_events.json | hell_bone_arena | choices.unarmed_fight.outcome.text -->
The gatekeeper grins wider than usual. The crowd loses its mind.
<!--@end-->


#### **duelist_cannot_refuse** — *blue* — requires **trait: duelist**

<!--@ hell_events.json | hell_bone_arena | choices.duelist_cannot_refuse.text -->
You were always going to. Do not pretend otherwise.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ hell_events.json | hell_bone_arena | choices.duelist_cannot_refuse.outcome.text -->
The gatekeeper sees it happen — the moment the decision stops being a decision — and grins with all the rows of teeth at once.

'Oh, you're one of those,' he says, delightedly, and waves you through without the fee.
<!--@end-->


#### **braggart_works_crowd** — *blue* — requires **trait: braggart**

<!--@ hell_events.json | hell_bone_arena | choices.braggart_works_crowd.text -->
Tell them who they are about to watch. At length.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ hell_events.json | hell_bone_arena | choices.braggart_works_crowd.outcome.text -->
Very little of it is true. All of it is delivered well, and the tiers are chanting a name by the end that is only approximately yours.

The purse is larger for a crowd that has already decided how it wants the fight to go.
<!--@end-->


#### **composed_before_fight** — *blue* — requires **trait: composed**

<!--@ hell_events.json | hell_bone_arena | choices.composed_before_fight.text -->
The crowd is not the fight. Do not spend anything on the crowd.
<!--@end-->


*Outcome*

`xp: 12  ·  gold: small`

<!--@ hell_events.json | hell_bone_arena | choices.composed_before_fight.outcome.text -->
You do not. You go out flat, unhurried and entirely uninterested in the tiers, and your opponent — who has been playing to them for a living — cannot find the rhythm they were expecting.

It is over rather quickly and the crowd does not enjoy it at all.
<!--@end-->


#### **bone_mace** — *blue* — requires maces 3

<!--@ hell_events.json | hell_bone_arena | choices.bone_mace.text -->
Pick up an arena bone-club — meet them on local terms
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+3, hell+2  ·  xp: 10  ·  gold: moderate`

<!--@ hell_events.json | hell_bone_arena | choices.bone_mace.outcome.text -->
You grab a femur from the ground and weigh it in your hand. The arena crowd approves of the improvisation.
<!--@end-->


---

## hell_suffering_sage

`realm: hell`

**Title**

<!--@ hell_events.json | hell_suffering_sage | title -->
Suffering Sage
<!--@end-->


**Body**

<!--@ hell_events.json | hell_suffering_sage | text -->
A figure sits at the summit of a frozen ridge, encased in ice up to the neck — only their face remains free, eyes open and clear. The oldest devils have forgotten when he appeared. Their expression is that of endless patience. As you come closer, they open their eyes a little.
<!--@end-->


### Choices


#### **suffering** — *grey*

<!--@ hell_events.json | hell_suffering_sage | choices.suffering.text -->
Ask about the nature of suffering
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 8`

<!--@ hell_events.json | hell_suffering_sage | choices.suffering.outcome.text -->
"All suffering comes from resistance to what is. The cold is not suffering. The resistance to the cold is suffering."
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hell_events.json | hell_suffering_sage | choices.meditate.text -->
Enter deep meditation to receive their teaching directly
<!--@end-->


*Outcome*

`karma: god+7, human+5, hell-3  ·  xp: 12`

<!--@ hell_events.json | hell_suffering_sage | choices.meditate.outcome.text -->
Shivering from the cold gives way to stillness and stillness to a direct transmission beyond words. You see the endless wheels of resistance and acceptance turning. They have been here for a long time, and yet a long time they will stay.
<!--@end-->


#### **history** — *blue* — requires learning 2

<!--@ hell_events.json | hell_suffering_sage | choices.history.text -->
Ask about the history of this realm
<!--@end-->


*Outcome*

`karma: god+4, human+4  ·  xp: 10`

<!--@ hell_events.json | hell_suffering_sage | choices.history.outcome.text -->
"I was here when the realm was still young. The first being who entered was a judge convinced he attained true justice. He was here for a very long time."
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_suffering_sage | choices.leave.text -->
Leave them to their vigil
<!--@end-->


*Outcome*

`karma: human+1`

<!--@ hell_events.json | hell_suffering_sage | choices.leave.outcome.text -->
Their eyes close again.
<!--@end-->


#### **touch_the_ice** — *yellow* — requires roll awareness vs difficult

<!--@ hell_events.json | hell_suffering_sage | choices.touch_the_ice.text -->
Press forward and place your hand on the ice encasing them
<!--@end-->


*Outcome — success*

`karma: human+6, god+4  ·  xp: 20  ·  hp_loss: {'amount': 'medium', 'target': 'all'}`

<!--@ hell_events.json | hell_suffering_sage | choices.touch_the_ice.outcome_success.text -->
The cold is immense. But through it — something transmits directly, bypassing language: the sage's full experiential understanding of suffering as ground rather than obstacle. Your hand burns. The teaching lands intact. You will be finding its edges for a long time.
<!--@end-->


*Outcome — failure*

`karma: human+1  ·  xp: 5`

<!--@ hell_events.json | hell_suffering_sage | choices.touch_the_ice.outcome_failure.text -->
The cold defeats you. Your hand numbs within seconds and you pull back before contact. The sage's eyes follow you — not disappointed, just patient. They have centuries to wait.
<!--@end-->


---

## hell_suspicious_gift

`realm: hell`

**Title**

<!--@ hell_events.json | hell_suspicious_gift | title -->
Suspicious Gift
<!--@end-->


**Body**

<!--@ hell_events.json | hell_suspicious_gift | text -->
A neatly wrapped package sits in the center of the path, as though placed deliberately. Red cloth, black cord. A tag: "For whoever needs this most."

The package is warm to the touch. Nothing else in the cold hell is warm.
<!--@end-->


### Choices


#### **inspect** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | hell_suspicious_gift | choices.inspect.text -->
Examine it carefully before opening
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8  ·  gold: 40  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_suspicious_gift | choices.inspect.outcome_success.text -->
Congratulations on your caution. The trap disarmed, you retrieve your loot safely.
<!--@end-->


*Outcome — failure*

`karma: hell+1, animal+2  ·  xp: 3`

<!--@ hell_events.json | hell_suspicious_gift | choices.inspect.outcome_failure.text -->
Triggered; theatrical but not lethal; package empty; a card: "Better luck with the next one."
<!--@end-->


#### **check_magic** — *blue* — requires guile 1

<!--@ hell_events.json | hell_suspicious_gift | choices.check_magic.text -->
Check it for traps with trained eyes
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6  ·  gold: 25  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_suspicious_gift | choices.check_magic.outcome.text -->
You find a magic seal and quickly scratch it until it's unrecognizable. The package opens cleanly with a health potion and some coins inside.
<!--@end-->


#### **open** — *grey*

<!--@ hell_events.json | hell_suspicious_gift | choices.open.text -->
Open it with reckless optimism
<!--@end-->


*Outcome*

`karma: animal+2, human+1  ·  xp: 4  ·  gold: 40  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_suspicious_gift | choices.open.outcome.text -->
A flash, a sound, blinding cold — then you're standing there holding a health potion and forty gold, entirely unharmed. Sometimes things are exactly what they appear to be.
<!--@end-->


#### **careful_cut** — *blue* — requires daggers 2

<!--@ hell_events.json | hell_suspicious_gift | choices.careful_cut.text -->
Cut the cord carefully — avoid any trigger mechanisms
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6  ·  gold: 40  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_suspicious_gift | choices.careful_cut.outcome.text -->
You find the right angle and draw a single precise cut through the cord. The package opens clean, the trap still intact and inert, the contents untouched. A health potion and forty gold, secured without incident.
<!--@end-->


#### **thievery_bypass** — *blue* — requires thievery 3

<!--@ hell_events.json | hell_suspicious_gift | choices.thievery_bypass.text -->
Assess it with professional eyes — you've handled worse
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8  ·  gold: 45  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_suspicious_gift | choices.thievery_bypass.outcome.text -->
The trigger mechanism is amateur work — a pressure seal under the bow. You disable it in thirty seconds without opening the package, then open it cleanly. Good loot, poorly protected.
<!--@end-->


#### **paranoid_perimeter** — *blue* — requires **trait: paranoid**

<!--@ hell_events.json | hell_suspicious_gift | choices.paranoid_perimeter.text -->
Do not touch it. Find who is watching it.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: air+10`

<!--@ hell_events.json | hell_suspicious_gift | choices.paranoid_perimeter.outcome.text -->
You spend twenty minutes on the surrounding rocks instead of the package, and you find him — a small demon flat behind a ridge with a good view and a bad hiding place.

He runs. The package turns out to be exactly as bad as you assumed, and you do not open it.
<!--@end-->


#### **incurious_shrug** — *blue* — requires **trait: incurious**

<!--@ hell_events.json | hell_suspicious_gift | choices.incurious_shrug.text -->
It is a box. Walk past the box.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: space-5`

<!--@ hell_events.json | hell_suspicious_gift | choices.incurious_shrug.outcome.text -->
You walk past the box. Some hours later there is a sound behind you that you decline to investigate.

Whoever it was for, it was not for you.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_suspicious_gift | choices.leave.text -->
Leave it — gifts in hell are seldom genuine
<!--@end-->


*Outcome*

`karma: animal+1, human+1`

<!--@ hell_events.json | hell_suspicious_gift | choices.leave.outcome.text -->
You step around it cautiously; behind you, the package waits warm and patient.
<!--@end-->


---

## hell_ice_demon_toll

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ice_demon_toll | title -->
Ice Demon Toll
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ice_demon_toll | text -->
Three squat ice demons have stretched a chain across the path. The leader holds a sign reading "TOLL — 10 GOLD" in letters of varying sizes.

"Passage fee. Standard Hell Traversal Rate, Section 7, Paragraph 4."
"There is no Section 7, Paragraph 4."
"For you there is."
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hell_events.json | hell_ice_demon_toll | choices.fight.text -->
Refuse and fight your way through
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+2, hell+2`

<!--@ hell_events.json | hell_ice_demon_toll | choices.fight.outcome.text -->

<!--@end-->


#### **pay** — *grey*

<!--@ hell_events.json | hell_ice_demon_toll | choices.pay.text -->
Pay the toll and move on
<!--@end-->


*Outcome*

`karma: hungry_ghost+2  ·  xp: 2`

<!--@ hell_events.json | hell_ice_demon_toll | choices.pay.outcome.text -->
The gold is counted with elaborate care, the chain unhurriedly unclipped. "Watch out for the unofficial toll three roads further on — those ones are criminals."
<!--@end-->


#### **argue** — *blue* — requires guile 1

<!--@ hell_events.json | hell_ice_demon_toll | choices.argue.text -->
Challenge the legal legitimacy of this checkpoint
<!--@end-->


*Outcome*

`karma: human+3, hell-2  ·  xp: 8`

<!--@ hell_events.json | hell_ice_demon_toll | choices.argue.outcome.text -->
An argument ensues, moving from the absence of appropriate seals though three different handwritings on the sign, to suspicious provisions. Finally you hear: "You can go. But only because we choose to be magnanimous."
<!--@end-->


#### **scrimper_refuses** — *blue* — requires **trait: scrimper**

<!--@ hell_events.json | hell_ice_demon_toll | choices.scrimper_refuses.text -->
Ten gold. For a chain. Explain in detail why this will not happen.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: earth+5`

<!--@ hell_events.json | hell_ice_demon_toll | choices.scrimper_refuses.outcome.text -->
You itemise. You are thorough. You establish the market rate for chain, the labour involved in stretching it across a road, and the total absence of any service rendered.

By the end the lead demon is arguing about the price of iron rather than collecting a toll, and the chain has somehow already been lowered.
<!--@end-->


#### **duelist_answers** — *blue* — requires **trait: duelist**

<!--@ hell_events.json | hell_ice_demon_toll | choices.duelist_answers.text -->
There is a faster way to settle this and everyone here knows it.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+8`

<!--@ hell_events.json | hell_ice_demon_toll | choices.duelist_answers.outcome.text -->
You name the terms before anyone has decided whether to be offended: one of theirs, one of yours, first to yield, no toll either way.

Theirs is shorter than you and considerably wider. It takes a while. The chain comes down.
<!--@end-->


#### **perform** — *blue* — requires performance 1

<!--@ hell_events.json | hell_ice_demon_toll | choices.perform.text -->
Offer to pay in entertainment
<!--@end-->


*Outcome*

`karma: human+3, asura+2  ·  xp: 5  ·  gold: 5`

<!--@ hell_events.json | hell_ice_demon_toll | choices.perform.outcome.text -->
The demons are transfixed, their leader applauding. One demon presses a coin into your hand: "Best thing that's happened here in a century."
<!--@end-->


---

## hell_cursed_pilgrim

`realm: hell`

**Title**

<!--@ hell_events.json | hell_cursed_pilgrim | title -->
Cursed Pilgrim
<!--@end-->


**Body**

<!--@ hell_events.json | hell_cursed_pilgrim | text -->
A person trudges forward pulling a massive stone block behind them, gouging a furrow in the frozen ground. They are making slow, painful progress.
<!--@end-->


### Choices


#### **break** — *blue* — requires strength 15

<!--@ hell_events.json | hell_cursed_pilgrim | choices.break.text -->
Break the chain by brute force
<!--@end-->


*Outcome*

`karma: hell-8, human+5, god+5  ·  xp: 12  ·  items: ['random_common_talisman']`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.break.outcome.text -->
After a long struggle, a link in the chain shatters. The pilgrim sits down heavily and breathes, then presses a carved token into your hands: "I had forgotten what it felt like to rest."
<!--@end-->


#### **examine** — *blue* — requires black_magic 2

<!--@ hell_events.json | hell_cursed_pilgrim | choices.examine.text -->
Examine the curse
<!--@end-->


*Outcome*

`karma: human+4, hell-3  ·  xp: 10`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.examine.outcome.text -->
You recognize a particular class of binding spells, resistant to direct force but vulnerable to patient unraveling from within. Once you explain it to the pilgrim you see a glimmer of hope in their eyes. "So there is a way!"
<!--@end-->


#### **walk** — *grey*

<!--@ hell_events.json | hell_cursed_pilgrim | choices.walk.text -->
Walk with them a while and listen
<!--@end-->


*Outcome*

`karma: human+4, hell-2  ·  xp: 5`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.walk.outcome.text -->
You hear a story of a deal with the devil. "I thought I was clever. I had found the loophole. The one it wanted me to find, unfortunately." You walk together for a while and leave them with a faint feeling of relief.
<!--@end-->


#### **enchantment_read** — *blue* — requires enchantment 2

<!--@ hell_events.json | hell_cursed_pilgrim | choices.enchantment_read.text -->
Read the binding structure
<!--@end-->


*Outcome*

`karma: human+5, hell-3  ·  xp: 10`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.enchantment_read.outcome.text -->
The chain is an enchantment you can read, if not immediately undo — a layered binding keyed to the pilgrim's own guilt, tightening every time they try to escape and loosening, slightly, when they accept the weight of what they did. You explain this to the pilgrim. Their breathing changes.

'So it responds to understanding, not force,' they say. They look at the chain differently. You leave them with a map.
<!--@end-->


#### **oath_keeper_understands** — *blue* — requires **trait: oath_keeper**

<!--@ hell_events.json | hell_cursed_pilgrim | choices.oath_keeper_understands.text -->
Ask what the vow was. Not why they are still keeping it.
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 20  ·  pressure: earth+12`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.oath_keeper_understands.outcome.text -->
Nobody has asked them that. Everyone asks the other question.

They tell you, and it is a reasonable vow made for a reasonable reason, and the stone is exactly as heavy as it was before. You walk with them for a while.
<!--@end-->


#### **attempt_help** — *grey*

<!--@ hell_events.json | hell_cursed_pilgrim | choices.attempt_help.text -->
Try to help break the chain
<!--@end-->


*Outcome*

`karma: human+3, hell-1  ·  xp: 3`

<!--@ hell_events.json | hell_cursed_pilgrim | choices.attempt_help.outcome.text -->
You try everything, but the chain remains indifferent. The pilgrim watches with tired gratitude. Their goodbye handshake is stronger than you expected.
<!--@end-->


---

## hell_frozen_army

`realm: hell`

**Title**

<!--@ hell_events.json | hell_frozen_army | title -->
Frozen Army
<!--@end-->


**Body**

<!--@ hell_events.json | hell_frozen_army | text -->
The valley below is filled with an army, frozen mid-march — thousands of soldiers preserved in ice, banners still flying. The armor is from no civilization you recognize. They are marching toward something that is no longer there.

They look like they are waiting.
<!--@end-->


### Choices


#### **respect** — *grey*

<!--@ hell_events.json | hell_frozen_army | choices.respect.text -->
Pay your respects to the fallen
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 5`

<!--@ hell_events.json | hell_frozen_army | choices.respect.outcome.text -->
You stand at the valley's edge and bow. Barely perceptible: in the front rank, a soldier's hand tightens slightly on their weapon.
<!--@end-->


#### **study** — *blue* — requires learning 2

<!--@ hell_events.json | hell_frozen_army | choices.study.text -->
Study the banners and try to identify them
<!--@end-->


*Outcome*

`karma: human+5, god+3, hell-2  ·  xp: 10`

<!--@ hell_events.json | hell_frozen_army | choices.study.outcome.text -->
Sun bisected by a spear; armor wrong for any hell-native force. These were mortals who marched here deliberately to rescue someone. They were winning; then stopped. You leave with a feeling of grief without closure.
<!--@end-->


#### **release** — *blue* — requires ritual 3

<!--@ hell_events.json | hell_frozen_army | choices.release.text -->
Search for a way to end their vigil
<!--@end-->


*Outcome*

`karma: god+8, hell-8  ·  xp: 15  ·  items: ['good_iron_armor']`

<!--@ hell_events.json | hell_frozen_army | choices.release.outcome.text -->
You find a binding mark at the standard's base and speak words of release. The ice melts gently, the army dissolves into light, armor clanking on the icy ground. The last soldier turns their head toward you and bows with ancient gratitude.
<!--@end-->


#### **armor_recognition** — *blue* — requires armor 2

<!--@ hell_events.json | hell_frozen_army | choices.armor_recognition.text -->
Study the armor — find out who they were
<!--@end-->


*Outcome*

`karma: human+4, hell-2  ·  xp: 10`

<!--@ hell_events.json | hell_frozen_army | choices.armor_recognition.outcome.text -->
You walk the front rank with trained eyes, reading the armor's construction, its repairs, its modifications. The plates are layered for siege conditions, not field skirmishes. The insignia has been filed off — but the filing pattern tells you who filed it and why. These were household guard for someone who did not want to be found.

They were winning. They almost made it.
<!--@end-->


#### **summon_soldier** — *blue* — requires summoning 3

<!--@ hell_events.json | hell_frozen_army | choices.summon_soldier.text -->
Rouse one soldier — ask what happened
<!--@end-->


*Outcome*

`karma: human+5, hell-3  ·  xp: 12`

<!--@ hell_events.json | hell_frozen_army | choices.summon_soldier.outcome.text -->
You reach into the ice with the words and one figure stirs — not freed, but present. A young soldier, not more than twenty when they marched.

'We were winning,' they say. Voice like ice on stone. 'The gate was opening. And then — he told us to stop.'

'Who?'

The soldier's eyes go distant. 'The one we came for.' They settle back into the ice. The answer costs you more than you expected.
<!--@end-->


#### **read_formation** — *blue* — requires logistics 3

<!--@ hell_events.json | hell_frozen_army | choices.read_formation.text -->
Read the formation — understand the battle order
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 10`

<!--@ hell_events.json | hell_frozen_army | choices.read_formation.outcome.text -->
The formation is a textbook advance-and-secure pattern, adapted for unknown terrain. Scouts ahead, heavies in the center, supply line staggered back. Whoever commanded this force was good — methodical, experienced, careful with their people.

The supply wagons are at the back of the column. They stopped mid-resupply. Whatever halted them came as a command, not a defeat.
<!--@end-->


#### **war_hardened_counts** — *blue* — requires **trait: war_hardened**

<!--@ hell_events.json | hell_frozen_army | choices.war_hardened_counts.text -->
Look at the formation, not the faces.
<!--@end-->


*Outcome*

`xp: 15  ·  items: ['item_random']`

<!--@ hell_events.json | hell_frozen_army | choices.war_hardened_counts.outcome.text -->
The formation tells you what happened: they were not caught marching. They were caught *forming up*, which means they saw it coming and had time to do the wrong thing about it.

You find the officer by where he is standing. What he is holding is worth taking.
<!--@end-->


#### **mourner_names_them** — *blue* — requires **trait: mourner**

<!--@ hell_events.json | hell_frozen_army | choices.mourner_names_them.text -->
Somebody should say something. Nobody has.
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost-4  ·  xp: 20  ·  add_trait: mourner  ·  pressure: water+15, space+8`

<!--@ hell_events.json | hell_frozen_army | choices.mourner_names_them.outcome.text -->
You do not know a single name, so you say the words without them, which is how it is done for the unnamed anyway.

It takes a long time. The ice does not change. You did not expect it to.
<!--@end-->


#### **pass** — *grey*

<!--@ hell_events.json | hell_frozen_army | choices.pass.text -->
Take the ridge path to avoid the valley
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_frozen_army | choices.pass.outcome.text -->
At the far end, you glance back at ten thousand frozen soldiers in perfect formation, rays of light glittering on their helmets.
<!--@end-->


---

## hell_pyromancer_duel

`realm: hell`

**Title**

<!--@ hell_events.json | hell_pyromancer_duel | title -->
The Pyromancer's Challenge
<!--@end-->


**Body**

<!--@ hell_events.json | hell_pyromancer_duel | text -->
A human mage in scorched red robes blocks the path, orbiting flames circling her like planets. The dueling scar on her cheek is self-inflicted — a mark made deliberately. She examines you with professional interest.

'You move like a magic user. I can always tell. I've been here forty years and no one's given me a real fight. You interested?'

Behind her, the path continues.
<!--@end-->


### Choices


#### **duel** — *blue* — requires fire_magic 1

<!--@ hell_events.json | hell_pyromancer_duel | choices.duel.text -->
Accept the fire duel
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: asura+5, human+3  ·  xp: 10`

<!--@ hell_events.json | hell_pyromancer_duel | choices.duel.outcome.text -->
She smiles for the first time and takes a stance. 'Honorable rules. No killing blows. First to yield.' The orbiting flames spin faster.
<!--@end-->


#### **counter** — *blue* — requires air_magic 2

<!--@ hell_events.json | hell_pyromancer_duel | choices.counter.text -->
Answer fire with wind magic
<!--@end-->


*Outcome*

`karma: asura+3, human+5  ·  xp: 12`

<!--@ hell_events.json | hell_pyromancer_duel | choices.counter.outcome.text -->
You raise a hand and let wind answer her fire. The two forces meet between you — not combat, but dialogue. Fire reaches. Wind redirects. Fire presses. Wind opens.

She holds this for a long moment, then lowers her hands.

'Huh. I've never had someone answer fire with wind before.' She considers. 'That's actually better. You're teaching me something.' She steps aside and demonstrates a technique for sealing fire before she lets you pass.
<!--@end-->


#### **listen** — *blue* — requires persuasion 2

<!--@ hell_events.json | hell_pyromancer_duel | choices.listen.text -->
Ask why she has been here for forty years
<!--@end-->


*Outcome*

`karma: human+5, god+3, hell-3  ·  xp: 8`

<!--@ hell_events.json | hell_pyromancer_duel | choices.listen.outcome.text -->
The orbiting flames slow. Something in her expression shifts from challenge to something older.

'I came looking for my student,' she says. 'He made bad choices. He ended up here. I found his ghost eventually. Spent ten years helping him move on.' A pause. 'He did, in the end. But I stayed. I thought I owed this place something.' She looks at the path behind her. 'I'm not sure that's true anymore.'

She steps aside without being asked. Her flames continue their orbit, but slower — more contemplative than aggressive.
<!--@end-->


#### **duelist_accepts** — *blue* — requires **trait: duelist**

<!--@ hell_events.json | hell_pyromancer_duel | choices.duelist_accepts.text -->
She has not finished the challenge. You have already accepted.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+10`

<!--@ hell_events.json | hell_pyromancer_duel | choices.duelist_accepts.outcome.text -->
The scars on her hands say she has done this often. Yours say something similar, and she reads them at about the same moment you read hers.

It is a good duel. It is stopped, by mutual agreement, one exchange before it would have stopped being one.
<!--@end-->


#### **decline** — *grey*

<!--@ hell_events.json | hell_pyromancer_duel | choices.decline.text -->
Decline and find another way around
<!--@end-->


*Outcome*

`karma: human+1`

<!--@ hell_events.json | hell_pyromancer_duel | choices.decline.outcome.text -->
She watches you find the path around with the measured disappointment of someone who has been doing this for a long time and has learned not to expect much.

'Fair enough,' she says. The orbiting flames resume their patient circuit. She settles in to wait for the next traveler.
<!--@end-->


---

## hell_demon_marketplace

`realm: hell`

**Title**

<!--@ hell_events.json | hell_demon_marketplace | title -->
The Demon Marketplace
<!--@end-->


**Body**

<!--@ hell_events.json | hell_demon_marketplace | text -->
A chaotic bazaar has assembled in the middle of the lava fields — dozens of stalls selling weapons, memories, bottled emotions, demon-forged equipment, and items you cannot categorize. The merchants are a mix of demons, damned souls, and creatures that do not appear to belong to any known category.

A sign over the entrance reads: NO FIGHTING. NO UNAUTHORIZED FIRE (the sign is on fire). NO RETURNS.

The noise is extraordinary.
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_demon_marketplace | choices.browse.text -->
Browse the marketplace stalls
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: ember_merchant  ·  karma: human+2, hungry_ghost+1  ·  xp: 2`

<!--@ hell_events.json | hell_demon_marketplace | choices.browse.outcome.text -->
You move through the stalls, shoulder to shoulder with demons and the damned alike. It is, despite everything, a marketplace — and there is something almost comforting about the familiar rhythms of commerce.
<!--@end-->


#### **trade_expert** — *blue* — requires trade 2

<!--@ hell_events.json | hell_demon_marketplace | choices.trade_expert.text -->
Seek out the best deals with expert knowledge
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_demon_marketplace | choices.trade_expert.outcome.text -->
You spend an hour working the stalls with professional efficiency — checking quality, testing weights, haggling at the right moments. You find a stall in the back that others seem to avoid, its proprietor a very old demon sitting behind a display of items none of the other merchants will look at directly.

'Good eye,' the demon says. 'The things nobody wants are often the things someone needs.' The prices are fair. The goods are unusual.
<!--@end-->


#### **back_alley** — *blue* — requires guile 2

<!--@ hell_events.json | hell_demon_marketplace | choices.back_alley.text -->
Find the restricted goods in the back alleys
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, hell+2  ·  xp: 6  ·  items: ['scroll_firebolt']`

<!--@ hell_events.json | hell_demon_marketplace | choices.back_alley.outcome.text -->
You find the alley behind the main stalls where the less official commerce happens. A hooded demon with careful eyes offers things the main market won't stock — items with complicated histories, scrolls from restricted collections, objects whose provenance cannot be confirmed.

You leave with a scroll and a sense of mild unease.
<!--@end-->


#### **systematic_survey** — *blue* — requires logistics 2

<!--@ hell_events.json | hell_demon_marketplace | choices.systematic_survey.text -->
Survey the market systematically — map what's actually here
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8  ·  items: ['item_random']`

<!--@ hell_events.json | hell_demon_marketplace | choices.systematic_survey.outcome.text -->
You work through the stalls in a pattern — quadrant by quadrant, comparing prices, noting quality, identifying which merchants specialize and which are generalists. By the end you have a clear picture of what this market contains and what it's worth.

The most valuable stall turns out to be one you'd have walked past entirely: a narrow booth near the east exit, staffed by a demon with seven arms who handles bulk orders for things you didn't know you needed in quantity.
<!--@end-->


#### **watch** — *grey*

<!--@ hell_events.json | hell_demon_marketplace | choices.watch.text -->
Watch the crowds instead of buying
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hell_events.json | hell_demon_marketplace | choices.watch.outcome.text -->
You find a good position and spend an hour simply watching.

Three deals go wrong in interesting ways. Two go surprisingly right — a demon and a damned soul find they both want what the other has, and part looking pleased. A woman in grey robes stands before a stall selling memory-jars, reading the labels, and cries quietly in front of one that says: 'Tuesday, Age 7.'

She doesn't buy it. Neither would you.
<!--@end-->


#### **flirt_works_the_stalls** — *blue* — requires **trait: flirt**

<!--@ hell_events.json | hell_demon_marketplace | choices.flirt_works_the_stalls.text -->
Every stall here is run by somebody bored.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small  ·  items: ['item_random']`

<!--@ hell_events.json | hell_demon_marketplace | choices.flirt_works_the_stalls.outcome.text -->
They are, and boredom is the only currency you have never been short of.

You do not buy anything at a discount. You are simply given three things over the course of an afternoon, by three different people, each of whom believes they started it.
<!--@end-->


#### **content_buys_nothing** — *blue* — requires **trait: content**

<!--@ hell_events.json | hell_demon_marketplace | choices.content_buys_nothing.text -->
You walk the whole market and want none of it.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: earth+10, fire+8`

<!--@ hell_events.json | hell_demon_marketplace | choices.content_buys_nothing.outcome.text -->
This is a strange sensation in a place engineered to produce the opposite, and one of the vendors follows you for a while trying to work out what is wrong with you.

You leave with your purse intact and an unusual amount of goodwill from the one stallholder who understood.
<!--@end-->


#### **hard_of_hearing_misses** — *blue* — requires **trait: hard_of_hearing**

<!--@ hell_events.json | hell_demon_marketplace | choices.hard_of_hearing_misses.text -->
The crowd noise here is total.
<!--@end-->


*Outcome*

`xp: 22  ·  gold: -20  ·  pressure: air-8`

<!--@ hell_events.json | hell_demon_marketplace | choices.hard_of_hearing_misses.outcome.text -->
You catch about one word in four, and the one in four does not include the part where the vendor names the real price, or the part where somebody behind you says your description out loud.

You find out about the second one later.
<!--@end-->


#### **friendly_haggle** — *yellow* — requires roll charm vs easy

<!--@ hell_events.json | hell_demon_marketplace | choices.friendly_haggle.text -->
Strike up conversation with vendors — gather market intelligence through friendly haggling
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8`

<!--@ hell_events.json | hell_demon_marketplace | choices.friendly_haggle.outcome_success.text -->
Vendors talk more than they mean to when someone seems genuinely interested. By the time you've moved through half the market, you know which stalls are fronts, which goods are mislabeled, and where the real bargains are buried.
<!--@end-->


*Outcome — failure*

`karma: hell+1  ·  xp: 3`

<!--@ hell_events.json | hell_demon_marketplace | choices.friendly_haggle.outcome_failure.text -->
One vendor takes your interest as an insult to their pride and raises their prices to spite you. The word spreads faster than you'd like. You pay more for the same goods and leave resolving to be less obvious next time.
<!--@end-->


---

## hell_burning_library

`realm: hell`

**Title**

<!--@ hell_events.json | hell_burning_library | title -->
The Burning Library
<!--@end-->


**Body**

<!--@ hell_events.json | hell_burning_library | text -->
A library is on fire.

Not metaphorically — the entire building is actively burning, shelves collapsing, books falling in cascades of sparks. But at the center, visible through the inferno, an enormous bookshelf stands intact, its contents still whole.

The fire has been burning long enough that the outer walls have almost collapsed. It will reach the center shelf soon.
<!--@end-->


### Choices


#### **brave** — *yellow* — requires roll constitution vs easy

<!--@ hell_events.json | hell_burning_library | choices.brave.text -->
Dash through the flames to save what you can
<!--@end-->


*Outcome — success*

`karma: human+4  ·  xp: 10  ·  items: ['scroll_firebolt', 'scroll_lesser_heal']`

<!--@ hell_events.json | hell_burning_library | choices.brave.outcome_success.text -->
You cover your head and run. The heat is enormous. You reach the center shelf, grab armfuls without looking, and sprint back as a beam comes down behind you.

Singed, coughing, but standing. In your arms: books that are ancient and intact and unlike anything you have seen before. You have no idea what language they are in. That feels like a problem for later.
<!--@end-->


*Outcome — failure*

`karma: human+2, animal+2  ·  xp: 5  ·  items: ['scroll_lesser_heal']`

<!--@ hell_events.json | hell_burning_library | choices.brave.outcome_failure.text -->
The heat drives you back before you reach the center. You grab one book from shelves near the entrance — old, smoke-damaged, but intact — before the entrance collapses.

You stand outside, coughing, clutching a book you saved. The center shelf burns.
<!--@end-->


#### **fire_magic** — *blue* — requires fire_magic 2

<!--@ hell_events.json | hell_burning_library | choices.fire_magic.text -->
Command the flames to clear a path
<!--@end-->


*Outcome*

`karma: human+5, asura+3  ·  xp: 14  ·  items: ['scroll_firebolt', 'mana_potion']`

<!--@ hell_events.json | hell_burning_library | choices.fire_magic.outcome.text -->
You reach into the fire and speak to it. It takes a moment — the fire here is old and set in its ways — but it responds. A corridor of cooler air opens before you, the flames pulling back on either side.

You walk to the center shelf calmly and take your time selecting. The books feel important in a way you cannot explain. You exit as the building finally collapses behind you in a controlled exhale.
<!--@end-->


#### **rescue** — *grey*

<!--@ hell_events.json | hell_burning_library | choices.rescue.text -->
Shout to see if anyone is still inside
<!--@end-->


*Outcome*

`karma: hell-5, human+8, god+3  ·  xp: 8  ·  items: ['demon_key']`

<!--@ hell_events.json | hell_burning_library | choices.rescue.outcome.text -->
You cup your hands and call into the flames.

Silence. Then: a cough. Then a small demon emerges from behind a burning pillar, clutching a ledger to its chest with both arms, absolutely refusing to put it down despite the circumstances.

You pull it out by the collar. It stands outside looking humiliated — not by the rescue, but by the fact that it needed one.

'The accounts,' it says, still holding the ledger. 'I couldn't leave the accounts.' It presses a key into your hands. 'For an archive in the eastern quarter. Everything there is in order too. In case anyone asks.' It walks away with dignity it has not entirely earned.
<!--@end-->


#### **construct_container** — *blue* — requires smithing 3

<!--@ hell_events.json | hell_burning_library | choices.construct_container.text -->
Build a fireproof carry-container from materials at hand
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 12  ·  items: ['scroll_firebolt', 'scroll_lesser_heal']`

<!--@ hell_events.json | hell_burning_library | choices.construct_container.outcome.text -->
You find fire-hardened bricks from the outer wall, a metal frame, hinges from a collapsed cabinet. The construction takes twenty minutes you don't quite have. But it works — a crude sealed box, clay-and-ash compound holding against the heat.

You carry it in, load the best of the center shelf's contents methodically, and exit as the roof comes down behind you. The box is intact. The books inside are dusty but unburned.
<!--@end-->


#### **incurious_leaves** — *blue* — requires **trait: incurious**

<!--@ hell_events.json | hell_burning_library | choices.incurious_leaves.text -->
It is a burning building. Leave the burning building.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: space-8`

<!--@ hell_events.json | hell_burning_library | choices.incurious_leaves.outcome.text -->
You leave the burning building. This turns out to have been the correct structural assessment by a margin of about ninety seconds.

Someone else will mourn the books.
<!--@end-->


#### **witness** — *grey*

<!--@ hell_events.json | hell_burning_library | choices.witness.text -->
Stand and witness the burning
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hell_events.json | hell_burning_library | choices.witness.outcome.text -->
You stand in the heat and watch the library burn.

At a certain point, the center shelf goes. The books go last — their pages lifting in the updraft, briefly bright, then dark.

Something is lost. And yet, watching it, you also feel something like release — as though the books were finished being books and have become something else instead.

You are not sure this is a useful thought. But it is the thought you have.
<!--@end-->


---

## hell_sinner_gang

`realm: hell`

**Title**

<!--@ hell_events.json | hell_sinner_gang | title -->
The Sinner Gang
<!--@end-->


**Body**

<!--@ hell_events.json | hell_sinner_gang | text -->
A group of damned souls has made camp around a fire — not for warmth, none of them need warmth, but for the feeling of it. A former soldier, a tax collector, an artist, a merchant. They've made rules, share what they find, keep watch in shifts. It is, against all odds, working.

One of them looks up as you approach.

'You're alive. Actual living. We don't get many of those.' A pause. 'Sit down. We're not going to hurt you.'
<!--@end-->


### Choices


#### **stories** — *grey*

<!--@ hell_events.json | hell_sinner_gang | choices.stories.text -->
Share a meal and hear their stories
<!--@end-->


*Outcome*

`karma: human+5, hell-3  ·  xp: 8`

<!--@ hell_events.json | hell_sinner_gang | choices.stories.outcome.text -->
You sit with them and the stories come out — what they did, what they understand now about what they did, what they are still working out.

The soldier burned a village on orders. The tax collector took more than was owed, always. The artist spent a life accepting credit for other people's work. The merchant let a business partner take the fall for a shared crime.

None of them are done yet. But they are thinking clearly about it, which is more than many here manage. You leave feeling, strangely, less alone.
<!--@end-->


#### **trade** — *grey*

<!--@ hell_events.json | hell_sinner_gang | choices.trade.text -->
Trade supplies with them
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_sinner_gang | choices.trade.outcome.text -->
They have things scavenged from wandering souls — small items, coins, a potion someone dropped. You have things from the living world. You trade fairly, taking what you need, giving what you can spare.

The merchant among them negotiates with professional precision, which makes everyone laugh, including the merchant. 'Habits,' they say. 'Even here.'
<!--@end-->


#### **inspire** — *blue* — requires persuasion 2

<!--@ hell_events.json | hell_sinner_gang | choices.inspire.text -->
Inspire them to give their suffering more purpose
<!--@end-->


*Outcome*

`karma: human+6, god+4, hell-5  ·  xp: 12`

<!--@ hell_events.json | hell_sinner_gang | choices.inspire.outcome.text -->
You talk to them for a long time — about suffering as instruction, about the difference between enduring and understanding, about what it would mean to actively help other souls in the hell realm rather than simply outlasting it.

The words land differently here than they would in the living world. One of them begins to cry. Another says quietly, 'We could actually do something with our time here.'

When you leave, they are still talking. Their camp looks like the beginning of something.
<!--@end-->


#### **assign_roles** — *blue* — requires leadership 3

<!--@ hell_events.json | hell_sinner_gang | choices.assign_roles.text -->
Help them organize more effectively
<!--@end-->


*Outcome*

`karma: human+5, hell-4, god+2  ·  xp: 12`

<!--@ hell_events.json | hell_sinner_gang | choices.assign_roles.outcome.text -->
You spend an hour with them, helping them think through what they're actually trying to do and who is best suited to what. The soldier takes watch. The artist keeps morale. The merchant manages what they find. The tax collector, reluctantly, handles records — 'At least I'm using it for something real this time.'

The structure clicks into place. They look more purposeful than any group has a right to in this realm.
<!--@end-->


#### **rotation_plan** — *blue* — requires logistics 3

<!--@ hell_events.json | hell_sinner_gang | choices.rotation_plan.text -->
Set up a sustainable rotation so the suffering doesn't compound
<!--@end-->


*Outcome*

`karma: human+4, hell-3  ·  xp: 10`

<!--@ hell_events.json | hell_sinner_gang | choices.rotation_plan.outcome.text -->
You map out their resources: what they have, what they need, what they can acquire, where the choke points are. The pattern of their suffering isn't random — there's a rhythm to it, and rhythms can be managed.

You draw up a rotation that gives each of them genuine rest between the harder stretches. The tax collector calls it 'the first fair system I've ever been part of,' and laughs at themselves for saying it.
<!--@end-->


#### **observe** — *grey*

<!--@ hell_events.json | hell_sinner_gang | choices.observe.text -->
Watch from a distance without disturbing them
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 2`

<!--@ hell_events.json | hell_sinner_gang | choices.observe.outcome.text -->
You stop on the ridge above their camp and watch for a while. The fire. The four figures around it. The quiet conversation.

One of them looks up and sees you. They raise a hand. You raise yours. They return to their conversation.

That is enough, somehow. For both of you.
<!--@end-->


#### **gambler_joins** — *blue* — requires **trait: gambler**

<!--@ hell_events.json | hell_sinner_gang | choices.gambler_joins.text -->
There is a game running at the edge of that fire.
<!--@end-->


*Outcome*

`xp: 15  ·  gold: small  ·  add_trait: gambler`

<!--@ hell_events.json | hell_sinner_gang | choices.gambler_joins.outcome.text -->
There is. It is crooked in a way you identify within four throws and decline to mention, since it is crooked in a direction you can work with.

You leave before it becomes impolite to keep winning.
<!--@end-->


#### **drunk_belongs** — *blue* — requires **trait: drunk**

<!--@ hell_events.json | hell_sinner_gang | choices.drunk_belongs.text -->
Sit down. These are, regrettably, your people.
<!--@end-->


*Outcome*

`xp: 30  ·  pressure: fire-10, water+5`

<!--@ hell_events.json | hell_sinner_gang | choices.drunk_belongs.outcome.text -->
They make room without being asked, which is the thing about the damned — they can spot it.

You are welcome here in a way that is not entirely comfortable to be welcome, and you leave with a name to drop and a headache.
<!--@end-->


#### **night_drinker_stays_late** — *blue* — requires **trait: night_drinker**

<!--@ hell_events.json | hell_sinner_gang | choices.night_drinker_stays_late.text -->
They have a fire and a bottle and no particular plans.
<!--@end-->


*Outcome*

`xp: 30  ·  add_trait: addiction  ·  pressure: fire-15, earth-8`

<!--@ hell_events.json | hell_sinner_gang | choices.night_drinker_stays_late.outcome.text -->
So do you, now. The talk is good and the bottle is worse than the talk, and at some point in the small hours it stops being an evening and starts being a habit that has followed you into another realm.

You will feel this one for a while.
<!--@end-->


#### **tell_story** — *yellow* — requires roll charm vs easy

<!--@ hell_events.json | hell_sinner_gang | choices.tell_story.text -->
Join them at the fire and tell a story — one that might make the suffering mean something
<!--@end-->


*Outcome — success*

`karma: human+4, god+2  ·  xp: 10`

<!--@ hell_events.json | hell_sinner_gang | choices.tell_story.outcome_success.text -->
They listen. Really listen — something rare here. By the end, someone is laughing in a way that sounds almost clean. Several of them clap you on the back as you leave.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 4`

<!--@ hell_events.json | hell_sinner_gang | choices.tell_story.outcome_failure.text -->
'That's a nice story,' says one of them, not unkindly. 'We've heard nicer. But sit down — you look like you've been walking for years.' You're welcome at the fire anyway.
<!--@end-->


---

## hell_forge_spirit

`realm: hell`

**Title**

<!--@ hell_events.json | hell_forge_spirit | title -->
The Forge Spirit
<!--@end-->


**Body**

<!--@ hell_events.json | hell_forge_spirit | text -->
An abandoned forge still glows with ancient heat — the fire here has not gone out in centuries. A translucent figure works the bellows with practiced rhythm, hammer rising and falling on metal that is not there. She died here, or near here, long enough ago that the distinction no longer matters.

She stops as you approach. Looks at you with the focused attention of someone who has not had company in a very long time.

'Oh. A visitor. Forgive me — I lose track of... everything. What day is it?'
<!--@end-->


### Choices


#### **tell_news** — *grey*

<!--@ hell_events.json | hell_forge_spirit | choices.tell_news.text -->
Tell her what you know of the current state of the realm
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 5`

<!--@ hell_events.json | hell_forge_spirit | choices.tell_news.outcome.text -->
You tell her what you know — the demon patrols, the lava flows, the frozen north, Yama's lieutenant at the gate. Each piece of information she processes slowly, turning it over.

'Still going, then. The realm.' She resumes the rhythm of the bellows. 'I wasn't sure.'

Then she stops again. 'Thank you. No one has told me anything in... I genuinely don't know how long. You forget there is news to be had.' She works the bellows harder, as though the information has given her energy.
<!--@end-->


#### **peace** — *blue* — requires white_magic 2

<!--@ hell_events.json | hell_forge_spirit | choices.peace.text -->
Help her find the peace she is missing
<!--@end-->


*Outcome*

`karma: god+8, hell-8, human+5  ·  xp: 14  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_forge_spirit | choices.peace.outcome.text -->
You spend a long time speaking with her — about what she made, who she made it for, what she was working toward when she died. The hammer and bellows slow and finally stop.

'I kept thinking there was one more thing to finish,' she says. 'But it was already finished. I just didn't see it.'

She looks up and goes very still. 'Oh,' she says. 'There it is. I've been looking right at it.' And then she is simply gone — not destroyed, but complete. On the forge floor, her tools have become solid. Real. Apparently hers to leave behind.
<!--@end-->


#### **learn** — *blue* — requires smithing 2

<!--@ hell_events.json | hell_forge_spirit | choices.learn.text -->
Ask to learn her craft techniques
<!--@end-->


*Outcome*

`karma: human+4, asura+3  ·  xp: 10`

<!--@ hell_events.json | hell_forge_spirit | choices.learn.outcome.text -->
She teaches. Ancient methods — based on relationship with material rather than mastery over it. She shows you how to hear what a metal wants to become before you force it into a shape.

Your hands seem to remember what your mind cannot quite hold. You leave with something that feels less like knowledge and more like patience.
<!--@end-->


#### **shore_enchantments** — *blue* — requires enchantment 3

<!--@ hell_events.json | hell_forge_spirit | choices.shore_enchantments.text -->
Examine the binding that keeps her here
<!--@end-->


*Outcome*

`karma: god+7, hell-6, human+4  ·  xp: 14  ·  items: ['fire_crystal']`

<!--@ hell_events.json | hell_forge_spirit | choices.shore_enchantments.outcome.text -->
You examine the bindings with careful attention and find that the enchantment keeping her tied to the forge is fraying — not by neglect, but by completion. The forge was her life's work. The binding was always meant to loosen when the work was done.

You don't repair it. You make it more transparent to her instead. She stares at her hands for a long moment.

'Oh,' she says. 'I see.' The hammer stays. She does not.
<!--@end-->


#### **work_forge** — *blue* — requires smithing 2

<!--@ hell_events.json | hell_forge_spirit | choices.work_forge.text -->
Work beside her at the forge
<!--@end-->


*Outcome*

`karma: human+4, asura+2  ·  xp: 8  ·  items: ['good_iron_weapon']`

<!--@ hell_events.json | hell_forge_spirit | choices.work_forge.outcome.text -->
You pick up a hammer and begin. Your technique is rougher than hers — she corrects your grip twice without words, just a precise adjustment of your hand. You work side by side for an hour in the rhythm of the forge.

When you leave, she is still at the bellows, but something in her rhythm has changed. A little faster. A little more alive.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_forge_spirit | choices.leave.text -->
Leave the spirit to her work
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 2`

<!--@ hell_events.json | hell_forge_spirit | choices.leave.outcome.text -->
You bow at the entrance to the forge. She does not look up, but the rhythm of the hammer changes briefly — a different beat, just for a moment — before returning to its ancient pattern.

A greeting, in the only language available.
<!--@end-->


---

## hell_the_invitation

`realm: hell`

**Title**

<!--@ hell_events.json | hell_the_invitation | title -->
The Invitation
<!--@end-->


**Body**

<!--@ hell_events.json | hell_the_invitation | text -->
An ornate envelope rests on a flat rock in the middle of a lava field, as though placed there deliberately. It is sealed with black wax. Your name is written on the outside — not the name you are using in this life, but a name you know with absolute certainty is yours.

The handwriting is beautiful.

Inside: a map, a time, an address, and the words: 'It would please us greatly if you would attend. We have matters of mutual interest to discuss. Come alone.'
<!--@end-->


### Choices


#### **follow** — *grey*

<!--@ hell_events.json | hell_the_invitation | choices.follow.text -->
Follow the map
<!--@end-->


*Outcome*

`karma: asura+3, hungry_ghost+2, human+2  ·  xp: 10`

<!--@ hell_events.json | hell_the_invitation | choices.follow.outcome.text -->
The address leads to a formal dining room carved from black obsidian, lit by candles burning with a clean blue flame. A demon of apparent authority waits at the head of a long table — well-dressed, patient, carrying the specific stillness of someone who has planned this meeting carefully.

'We have been observing your journey,' it says. 'With interest. There is a matter we would like to discuss — something that would benefit both of us, if we can reach an agreement.'

The conversation that follows is careful and illuminating. You learn things about the hell realm you did not know. You also decline the offer, politely, when it finally arrives.

'The offer stands,' the demon says as you leave. 'When you change your mind, you'll know how to reach us.' It does not say if.

You notice, on the way out, that there is only one setting at the table. They knew you'd come alone.
<!--@end-->


#### **arrive_early** — *blue* — requires guile 2

<!--@ hell_events.json | hell_the_invitation | choices.arrive_early.text -->
Follow the map but arrive early and observe first
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8`

<!--@ hell_events.json | hell_the_invitation | choices.arrive_early.outcome.text -->
You find the address an hour before the appointed time and settle in a position with a clear view of the entrance.

Someone else has already arrived — a damned soul, young, with the hollow eyes of someone who has been suffering long enough to consider anything an improvement. They go inside. Through the wall (obsidian is surprisingly thin) you can hear the shape of the conversation without the words.

A deal is being made. The soul wants something specific. The demon is offering it.

You could intervene. You could also let them make their own choice — the soul is old enough to know what they're doing, even here.

You wait until the soul emerges — lighter, in some way you cannot verify — then slip away before your own appointment time.
<!--@end-->


#### **examine** — *blue* — requires black_magic 2

<!--@ hell_events.json | hell_the_invitation | choices.examine.text -->
Examine the invitation for hidden enchantments
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 10`

<!--@ hell_events.json | hell_the_invitation | choices.examine.outcome.text -->
You read the letter carefully with trained attention to what is not there.

Three layers of enchantment. The first: a location beacon — someone has already noted that the invitation was opened. The second: a subtle compulsion toward compliance, minor enough to be deniable. The third: something you cannot fully name but that feels, precisely and strangely, like recognition — as though whoever wrote this has seen you before, in a context you cannot access.

You burn the invitation. For a moment you feel watched from a very specific direction. Then nothing.

The name they used for you, you will be thinking about for a while.
<!--@end-->


#### **ignore** — *grey*

<!--@ hell_events.json | hell_the_invitation | choices.ignore.text -->
Set it back on the rock and walk on
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hell_events.json | hell_the_invitation | choices.ignore.outcome.text -->
You set the envelope back on the rock and continue on your way.

Behind you, the envelope waits. A faint sense of disappointment from a specific direction — calm, professional, patient. The kind of disappointment that is already adjusting its timeline.

Someday, you think, you will want to know what was in that letter.
<!--@end-->


#### **read_scene** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | hell_the_invitation | choices.read_scene.text -->
Look for signs of who placed this — tracks, timing, intent written in the ash
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8`

<!--@ hell_events.json | hell_the_invitation | choices.read_scene.outcome_success.text -->
The ash around the rock is undisturbed except for one set of prints — small, deliberate, placed and then retreated. No ambush position. No disturbance in the lava flow. Whoever left this came alone and didn't wait to watch. The invitation might be genuine.
<!--@end-->


*Outcome — failure*

`xp: 3`

<!--@ hell_events.json | hell_the_invitation | choices.read_scene.outcome_failure.text -->
A new lava flow has already covered whatever marks were here. The ash tells you nothing. You're left exactly as uncertain as before.
<!--@end-->


---

## hell_sigh_of_relief

`realm: hell`

**Title**

<!--@ hell_events.json | hell_sigh_of_relief | title -->
A Sigh of Relief
<!--@end-->


**Body**

<!--@ hell_events.json | hell_sigh_of_relief | text -->
You feel strangely drawn towards a clearing, where among the bleakness a figure stands shining softly. A bodhisattva from the higher realms has come to the Hells to give offerings and teach the suffering shades.

As you come closer you see piles of food, drink, and medicine manifesting from thin air, imps swarming around and swallowing mouthfuls.
<!--@end-->


### Choices


#### **meditate** — *blue* — requires yoga 2

<!--@ hell_events.json | hell_sigh_of_relief | choices.meditate.text -->
Meditate in the presence of the Bodhisattva
<!--@end-->


*Outcome*

`karma: hell-5, human+3, god+5  ·  xp: 12  ·  add_trait: touched_by_grace`

<!--@ hell_events.json | hell_sigh_of_relief | choices.meditate.outcome.text -->
As you settle down and focus, you recognize there is no boundary between you. The teacher smiles and raises their hand to bless you.

A warmth spreads through your body — not the burning heat of this realm, but something gentler. Something remembered.
<!--@end-->


#### **listen** — *blue* — requires focus 14

<!--@ hell_events.json | hell_sigh_of_relief | choices.listen.text -->
Listen to the teachings
<!--@end-->


*Outcome*

`karma: hell-3, human+3, god+3  ·  xp: 10  ·  add_trait: touched_by_grace`

<!--@ hell_events.json | hell_sigh_of_relief | choices.listen.outcome.text -->
Impermanence, compassion, joy. It seems like you have heard these words before, but long forgotten their meaning.

The bodhisattva speaks without urgency, as though time here is different — and perhaps it is. When the teaching ends, the words continue to resonate somewhere you cannot quite locate.
<!--@end-->


#### **partake** — *grey*

<!--@ hell_events.json | hell_sigh_of_relief | choices.partake.text -->
Come and take your fill
<!--@end-->


*Outcome*

`karma: hell-3, hungry_ghost+2, animal+2, human+2  ·  xp: 8  ·  restore: {'hp_percent': 100, 'mana_percent': 100, 'stamina_percent': 100}`

<!--@ hell_events.json | hell_sigh_of_relief | choices.partake.outcome.text -->
For a moment, all your fears and hopes dissolve into the present moment. You are content.

The food tastes like nothing you have eaten in this realm — clean, simple, nourishing. Your wounds close. Your mind clears. Your body remembers what it feels like to be whole.
<!--@end-->


#### **grab** — *grey*

<!--@ hell_events.json | hell_sigh_of_relief | choices.grab.text -->
Rush in and take as much as you can
<!--@end-->


*Outcome*

`karma: hell+5, hungry_ghost+5  ·  xp: 0  ·  add_trait: covetous`

<!--@ hell_events.json | hell_sigh_of_relief | choices.grab.outcome.text -->
You shove past the imps and grab armfuls of food and medicine — but as your hands close around them, they dissolve like mist. The clearing shimmers. The bodhisattva regards you with an expression that is not disappointment but something closer to recognition.

The scene vanishes as if it was never there.
<!--@end-->


#### **specific_teaching** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_sigh_of_relief | choices.specific_teaching.text -->
Open yourself precisely — ask without words for what your situation most needs
<!--@end-->


*Outcome — success*

`karma: human+5, god+4  ·  xp: 15  ·  add_trait: touched_by_grace`

<!--@ hell_events.json | hell_sigh_of_relief | choices.specific_teaching.outcome_success.text -->
The Bodhisattva's attention focuses on you directly, gently, like sunlight through a small window. Nothing is said — but something specific passes, fitted exactly to the shape of what you carry. You know what it is without being able to say it.
<!--@end-->


*Outcome — failure*

`karma: human+3, god+1  ·  xp: 6`

<!--@ hell_events.json | hell_sigh_of_relief | choices.specific_teaching.outcome_failure.text -->
The peace reaches you — warmth and light after long cold. But the specific teaching you reached for remains just out of grasp. You receive the general blessing, which is not nothing.
<!--@end-->


---

## devil_deserter

`realm: any`

**Title**

<!--@ hell_events.json | devil_deserter | title -->
A Familiar Face
<!--@end-->


**Body**

<!--@ hell_events.json | devil_deserter | text -->
A red devil sits by the road, stripped of his armor. He looks up at you. 'I'm done with the Guard,' he says simply. 'Done with all of it. I just need somewhere to be.'
<!--@end-->


### Choices


#### **recruit** — *grey*

<!--@ hell_events.json | devil_deserter | choices.recruit.text -->
Take him with you.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: karnak`

<!--@ hell_events.json | devil_deserter | choices.recruit.outcome.text -->

<!--@end-->


#### **walk_on** — *grey*

<!--@ hell_events.json | devil_deserter | choices.walk_on.text -->
Not your problem. Walk on.
<!--@end-->


*Outcome*


<!--@ hell_events.json | devil_deserter | choices.walk_on.outcome.text -->
You leave him by the road. Some distances can't be closed.
<!--@end-->


#### **probe_intel** — *blue* — requires guile 1

<!--@ hell_events.json | devil_deserter | choices.probe_intel.text -->
Extract information about the Guard's patrol routes and weak points
<!--@end-->


*Outcome*

`karma: human+2, asura+1  ·  xp: 8`

<!--@ hell_events.json | devil_deserter | choices.probe_intel.outcome.text -->
He's grateful for someone who actually wants to listen. Between complaints, useful details slip out — patrol timings, which commanders take bribes, where the soft spots in the ring are. You leave better informed.
<!--@end-->


#### **read_intent** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | devil_deserter | choices.read_intent.text -->
Study him carefully — look past the performance to what's underneath
<!--@end-->


*Outcome — success*

`karma: human+3, hell+1  ·  xp: 6`

<!--@ hell_events.json | devil_deserter | choices.read_intent.outcome_success.text -->
He's genuine. Exhausted, frightened, and done. The despair in him isn't put on — no devil performs suffering this quietly. You feel something shift in your understanding of this place.
<!--@end-->


*Outcome — failure*

`karma: hell+1`

<!--@ hell_events.json | devil_deserter | choices.read_intent.outcome_failure.text -->
Hellfire makes everyone's eyes the same — flat and red and unreadable. You can't tell. He might be desperate. He might be a trap. You move on uncertain.
<!--@end-->


#### **recognize_the_cost** — *blue* — requires yoga 3

<!--@ hell_events.json | devil_deserter | choices.recognize_the_cost.text -->
You know what showing mercy in hell costs. Acknowledge it.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: karnak  ·  karma: human+3, god+2`

<!--@ hell_events.json | devil_deserter | choices.recognize_the_cost.outcome.text -->
He looks at you carefully. The recognition is mutual — you have both thought about the same thing. 'You understand it,' he says. It isn't a question. He stands and picks up his pack.
<!--@end-->


#### **offer_purpose** — *blue* — requires leadership 4

<!--@ hell_events.json | devil_deserter | choices.offer_purpose.text -->
Offer him something worth serving — not just somewhere to be.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: karnak  ·  karma: human+2`

<!--@ hell_events.json | devil_deserter | choices.offer_purpose.outcome.text -->
He listens to what you are doing and why. Something shifts behind his eyes for the first time in a while. 'That I could follow,' he says.
<!--@end-->


#### **oath_breaker_recognises** — *blue* — requires **trait: oath_breaker**

<!--@ hell_events.json | devil_deserter | choices.oath_breaker_recognises.text -->
You know exactly what he is doing, because you did it.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: earth+8`

<!--@ hell_events.json | devil_deserter | choices.oath_breaker_recognises.outcome.text -->
You do not tell him it gets easier. You tell him the specific practical things: which roads have checkpoints, what they ask, and how long before anyone stops looking.

He listens like a man taking down an address.
<!--@end-->


#### **oath_keeper_disapproves** — *blue* — requires **trait: oath_keeper**

<!--@ hell_events.json | devil_deserter | choices.oath_keeper_disapproves.text -->
A vow is a vow. Say so, plainly, and then help anyway.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: earth+10, water+5`

<!--@ hell_events.json | devil_deserter | choices.oath_keeper_disapproves.outcome.text -->
You tell him what you think of it. He takes it without arguing, which is worse than arguing.

Then you give him the water anyway, because the two positions turn out not to be in conflict, whatever you had assumed.
<!--@end-->


#### **patient_hears_him** — *blue* — requires **trait: patient**

<!--@ hell_events.json | devil_deserter | choices.patient_hears_him.text -->
He has not finished. Let him finish.
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hell_events.json | devil_deserter | choices.patient_hears_him.outcome.text -->
It takes him a long time to get to the actual sentence, and the actual sentence is not the one he opened with.

What he is done with is not the Guard. Once that is out, the rest of the conversation is a different conversation entirely.
<!--@end-->


#### **just_ask** — *yellow* — requires roll charm vs easy

<!--@ hell_events.json | devil_deserter | choices.just_ask.text -->
Be someone worth following — just ask him.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: karnak  ·  karma: human+2`

<!--@ hell_events.json | devil_deserter | choices.just_ask.outcome_success.text -->
He looks at you for a long moment, then stands and rolls his shoulders. 'Alright. Can't be worse than this.'
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | devil_deserter | choices.just_ask.outcome_failure.text -->
He shakes his head. 'No offense. I just need a sign it is worth it this time. Come back if things get interesting.'
<!--@end-->


---

## hell_teahouse_cold

`realm: hell`

**Title**

<!--@ hell_events.json | hell_teahouse_cold | title -->
Teahouse
<!--@end-->


**Body**

<!--@ hell_events.json | hell_teahouse_cold | text -->
A low building crouches at the edge of the frozen waste, smoke leaking from the roof. Inside, a few silent figures nurse cups of something warm. The barkeeper glances up without expression.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_teahouse_cold | choices.[0].text -->
Sit down
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_teahouse_cold`

<!--@ hell_events.json | hell_teahouse_cold | choices.[0].outcome.text -->
You take a seat. Nobody bothers you.
<!--@end-->


#### **tea_properly** — *blue* — requires **trait: tea_ritualist**

<!--@ hell_events.json | hell_teahouse_cold | choices.tea_properly.text -->
Watch how they are making it. Ask for the pot, not the cup.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+10, fire+5`

<!--@ hell_events.json | hell_teahouse_cold | choices.tea_properly.outcome.text -->
The proprietor looks at you for a moment longer than is comfortable, and then hands over the pot without a word, which in this establishment is an honour roughly equivalent to a title.

You make it properly. Several of the silent figures relocate closer to the fire while you do.
<!--@end-->


#### **gossip_listen** — *blue* — requires **trait: gossip**

<!--@ hell_events.json | hell_teahouse_cold | choices.gossip_listen.text -->
Say nothing for an hour and listen to everyone else.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ hell_events.json | hell_teahouse_cold | choices.gossip_listen.outcome.text -->
An hour buys you: two names worth avoiding, one road that is not as closed as the guard post claims, and the current price of a favour in this district.

Nobody notices you listening. Nobody ever does.
<!--@end-->


#### **[3]** — *grey*

<!--@ hell_events.json | hell_teahouse_cold | choices.[3].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_teahouse_cold | choices.[3].outcome.text -->
You keep walking. The smell of smoke follows you longer than it should.
<!--@end-->


---

## hell_teahouse_fire

`realm: hell`

**Title**

<!--@ hell_events.json | hell_teahouse_fire | title -->
Teahouse
<!--@end-->


**Body**

<!--@ hell_events.json | hell_teahouse_fire | text -->
A squat building half-buried in ash. The sign is burned off but the smell of tea — strong, smoky, almost pleasant — cuts through the sulphur. The door is open.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_teahouse_fire | choices.[0].text -->
Step inside
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_teahouse_fire`

<!--@ hell_events.json | hell_teahouse_fire | choices.[0].outcome.text -->
The heat inside is almost comfortable compared to outside.
<!--@end-->


#### **drunk_relapse** — *blue* — requires **trait: drunk**

<!--@ hell_events.json | hell_teahouse_fire | choices.drunk_relapse.text -->
There is more than tea behind that counter, and you know it.
<!--@end-->


*Outcome*

`xp: 30  ·  gold: -20  ·  add_trait: night_drinker  ·  pressure: fire-12, earth-8`

<!--@ hell_events.json | hell_teahouse_fire | choices.drunk_relapse.outcome.text -->
There is. It is bad, and there is a lot of it, and the proprietor pours without being asked twice.

The evening goes somewhere. In the morning the party is short some coin and you are short some hours you would like back.
<!--@end-->


#### **night_drinker_again** — *blue* — requires **trait: night_drinker**

<!--@ hell_events.json | hell_teahouse_fire | choices.night_drinker_again.text -->
You know what is behind the counter and you know how many nights this makes.
<!--@end-->


*Outcome*

`xp: 30  ·  gold: -25  ·  add_trait: drunk  ·  pressure: fire-12`

<!--@ hell_events.json | hell_teahouse_fire | choices.night_drinker_again.outcome.text -->
You do know how many nights this makes. That is new — the counting is new — and you order anyway, which is the part that settles the question.

Nobody in the party says anything. Two of them exchange a look.
<!--@end-->


#### **[3]** — *grey*

<!--@ hell_events.json | hell_teahouse_fire | choices.[3].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_teahouse_fire | choices.[3].outcome.text -->
You leave the warmth behind.
<!--@end-->


---

## hell_mercenary_guild

`realm: hell`

**Title**

<!--@ hell_events.json | hell_mercenary_guild | title -->
Mercenary Guild
<!--@end-->


**Body**

<!--@ hell_events.json | hell_mercenary_guild | text -->
A fortified outpost flying a plain black banner. A board outside lists rates for services rendered. Inside, armoured figures sharpen weapons or sleep. They look up when you enter.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_mercenary_guild | choices.[0].text -->
Browse their wares
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_mercenary_guild`

<!--@ hell_events.json | hell_mercenary_guild | choices.[0].outcome.text -->
The quartermaster unlocks a case and waits.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_mercenary_guild | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_mercenary_guild | choices.[1].outcome.text -->
You leave the mercenaries to their sharpening.
<!--@end-->


---

## hell_veterans_camp

`realm: hell`

**Title**

<!--@ hell_events.json | hell_veterans_camp | title -->
Veterans' Camp
<!--@end-->


**Body**

<!--@ hell_events.json | hell_veterans_camp | text -->
A sparse camp around a fire. The people here are old — old for hell, which means they have survived something most haven't. One of them watches you approach with calculating eyes.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_veterans_camp | choices.[0].text -->
Ask about training
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_veterans_camp`

<!--@ hell_events.json | hell_veterans_camp | choices.[0].outcome.text -->
"We can teach two things. Once each. Make your choices."
<!--@end-->


#### **war_hardened_sits** — *blue* — requires **trait: war_hardened**

<!--@ hell_events.json | hell_veterans_camp | choices.war_hardened_sits.text -->
Sit down without being invited. They will not mind.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: water+8`

<!--@ hell_events.json | hell_veterans_camp | choices.war_hardened_sits.outcome.text -->
They do not mind. Nobody asks where you served, because the question is not interesting to anyone here — what is interesting is whether you know how to sit at a fire without talking.

You do. By morning you have been told three things about the road ahead that are not on any map.
<!--@end-->


#### **sole_survivor_recognised** — *blue* — requires **trait: sole_survivor**

<!--@ hell_events.json | hell_veterans_camp | choices.sole_survivor_recognised.text -->
One of them looks at you and knows.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+15, space+8`

<!--@ hell_events.json | hell_veterans_camp | choices.sole_survivor_recognised.outcome.text -->
She does not say anything about it. She moves along the log to make room, and later, when the fire is low, she says: 'It doesn't get quieter. You just get better at the noise.'

It is not comfort. It is better than comfort, which is accuracy.
<!--@end-->


#### **[3]** — *grey*

<!--@ hell_events.json | hell_veterans_camp | choices.[3].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_veterans_camp | choices.[3].outcome.text -->
The veteran returns to staring into the fire.
<!--@end-->


---

## hell_sacred_grove

`realm: hell`

**Title**

<!--@ hell_events.json | hell_sacred_grove | title -->
Sacred Grove
<!--@end-->


**Body**

<!--@ hell_events.json | hell_sacred_grove | text -->
The dappled light streaming through the dense canopy seems like living gold. The Yakshas and Yakshinis come to commune with their followers in this place, marked with colored ropes on the tree trunks and prayer flags hanging from the branches.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_sacred_grove | choices.[0].text -->
Approach the practitioners
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_sacred_grove`

<!--@ hell_events.json | hell_sacred_grove | choices.[0].outcome.text -->
A Yakshini turns and regards you without surprise. Earth magic has a price — she names it.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_sacred_grove | choices.[1].text -->
Leave them to it
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_sacred_grove | choices.[1].outcome.text -->
You walk on. The light filters through the canopy long after the grove is out of sight.
<!--@end-->


---

## hell_temple_of_the_naga

`realm: hell`

**Title**

<!--@ hell_events.json | hell_temple_of_the_naga | title -->
Temple of the Naga
<!--@end-->


**Body**

<!--@ hell_events.json | hell_temple_of_the_naga | text -->
In every world some beings are born innately attuned to the mindstreams of the Naga. Temples arise where they practice, communing with their reptilian friends and patrons through offerings of saffron milk, fruits and flowers.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_temple_of_the_naga | choices.[0].text -->
Ask about their teachings
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_temple_of_the_naga`

<!--@ hell_events.json | hell_temple_of_the_naga | choices.[0].outcome.text -->
A practitioner rises smoothly and names the spells they can teach. The price is gold, as always.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_temple_of_the_naga | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_temple_of_the_naga | choices.[1].outcome.text -->
You don't disturb the offerings. The scent of flowers follows you.
<!--@end-->


---

## hell_garuda_roost

`realm: hell`

**Title**

<!--@ hell_events.json | hell_garuda_roost | title -->
Garuda Roost
<!--@end-->


**Body**

<!--@ hell_events.json | hell_garuda_roost | text -->
A tall pole with a horned symbol at the top rises from the ground, sacred stones and offerings heaped at its base, colorful ribbons fluttering in the wind. The worshippers say the Garudas come to perch at the top during their long travels.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_garuda_roost | choices.[0].text -->
Speak to the worshippers
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_garuda_roost`

<!--@ hell_events.json | hell_garuda_roost | choices.[0].outcome.text -->
One of the worshippers looks up. They teach Air magic here — what you pay is your own business.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_garuda_roost | choices.[1].text -->
Leave an offering and go
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_garuda_roost | choices.[1].outcome.text -->
You set something at the base of the pole and move on. The ribbons flutter.
<!--@end-->


#### **recognize_symbol** — *blue* — requires learning 1

<!--@ hell_events.json | hell_garuda_roost | choices.recognize_symbol.text -->
Draw on your knowledge — you've seen this symbol before, or something like it
<!--@end-->


*Outcome*

`karma: asura+2, human+2  ·  xp: 8`

<!--@ hell_events.json | hell_garuda_roost | choices.recognize_symbol.outcome.text -->
You recognize the horned emblem as a Garuda boundary marker — a sign this place is protected from the worst hell denizens. The worshippers confirm it quietly, impressed you knew. They share a fragment of lore about the great birds who sometimes pass through even here.
<!--@end-->


#### **pet_lover_greets** — *blue* — requires **trait: pet_lover**

<!--@ hell_events.json | hell_garuda_roost | choices.pet_lover_greets.text -->
Greet them the way you greet anything with feathers.
<!--@end-->


*Outcome*

`karma: animal+3  ·  xp: 20  ·  pressure: water+8`

<!--@ hell_events.json | hell_garuda_roost | choices.pet_lover_greets.outcome.text -->
This is, by every account, a serious error of protocol. The garuda are not birds and take a dim view of being addressed as such.

The young one, however, comes down off the pole to see what you are doing, and stays.
<!--@end-->


#### **sense_residue** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | hell_garuda_roost | choices.sense_residue.text -->
Open your senses to whatever power remains in this place
<!--@end-->


*Outcome — success*

`karma: asura+3, god+1  ·  xp: 10`

<!--@ hell_events.json | hell_garuda_roost | choices.sense_residue.outcome_success.text -->
Something vast has perched here recently. You feel the echo of huge wings, a smell of lightning and high altitude. For a moment you see the hell realm from above — tiny, contained, impermanent. Then it is gone.
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_garuda_roost | choices.sense_residue.outcome_failure.text -->
The offerings are old. Whatever came here has moved on. You sense nothing but ash and the cold prayers of the worshippers.
<!--@end-->


---

## hell_hidden_gompa

`realm: hell`

**Title**

<!--@ hell_events.json | hell_hidden_gompa | title -->
Hidden Gompa
<!--@end-->


**Body**

<!--@ hell_events.json | hell_hidden_gompa | text -->
Practitioners come to this place seeking solitude and peace. The ground itself vibrates with the power of their meditation, mantric syllables appearing spontaneously in the rock.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_hidden_gompa | choices.[0].text -->
Knock and ask to enter
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_hidden_gompa`

<!--@ hell_events.json | hell_hidden_gompa | choices.[0].outcome.text -->
After a long pause, the door opens. A monk gestures you inside. Space magic. What do you need?
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_hidden_gompa | choices.[1].text -->
Don't disturb them
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_hidden_gompa | choices.[1].outcome.text -->
You walk past without knocking. The syllables in the rock seem to pulse as you go.
<!--@end-->


#### **inner_request** — *blue* — requires yoga 2

<!--@ hell_events.json | hell_hidden_gompa | choices.inner_request.text -->
Center yourself and send an inner request — the way the tradition demands
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 15`

<!--@ hell_events.json | hell_hidden_gompa | choices.inner_request.outcome.text -->
Before you can knock, the door opens. A monk with ancient eyes looks at you for a long moment. 'You know the language. Come in.' The interior is impossibly quiet — the hell realm's noise cut off as if by thick stone. You sit, breathe, and receive something wordless that nevertheless settles into your bones.
<!--@end-->


#### **ask_teaching** — *yellow* — requires roll charm vs normal

<!--@ hell_events.json | hell_hidden_gompa | choices.ask_teaching.text -->
Appeal to the monks — you have come a long way, and you are learning
<!--@end-->


*Outcome — success*

`karma: human+4, god+2  ·  xp: 12`

<!--@ hell_events.json | hell_hidden_gompa | choices.ask_teaching.outcome_success.text -->
One of the monks regards you with genuine warmth. 'You ask well,' he says. 'That is already something.' He gives you a brief teaching on the nature of suffering as a teacher rather than an enemy. You leave quieter than you arrived.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 4`

<!--@ hell_events.json | hell_hidden_gompa | choices.ask_teaching.outcome_failure.text -->
The monk at the door considers you kindly. 'The teaching comes when conditions ripen. Sit outside if you like — the quiet here reaches further than the walls.' You sit for a while. It does.
<!--@end-->


---

## hell_mirror_lake

`realm: hell`

**Title**

<!--@ hell_events.json | hell_mirror_lake | title -->
Mirror Lake
<!--@end-->


**Body**

<!--@ hell_events.json | hell_mirror_lake | text -->
Mirages flicker over the mercurial surface of the lake. Followers of the Goddess of Illusion gather around, meditating on the fleeting nature of phenomena and exchanging stories of their dreams.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_mirror_lake | choices.[0].text -->
Sit and listen
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_mirror_lake`

<!--@ hell_events.json | hell_mirror_lake | choices.[0].outcome.text -->
A practitioner meets your eyes in the reflection before turning around. They can teach Enchantment. The lake makes everything a fair price.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_mirror_lake | choices.[1].text -->
Walk away from the mirage
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_mirror_lake | choices.[1].outcome.text -->
You step back. The images on the water follow you for a moment, then dissolve.
<!--@end-->


#### **clear_sight** — *blue* — requires yoga 1

<!--@ hell_events.json | hell_mirror_lake | choices.clear_sight.text -->
Clear your mind completely and look without craving — see what is actually there
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 10`

<!--@ hell_events.json | hell_mirror_lake | choices.clear_sight.outcome.text -->
The lake's mirages still flicker, but you see through them — not with effort but with stillness. Beneath the illusions the surface is perfectly clear, reflecting something real: a glimpse of a path you had not considered. The Goddess's followers notice your clarity and nod.
<!--@end-->


#### **pierce_illusion** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_mirror_lake | choices.pierce_illusion.text -->
Stare into the surface and attempt to see through to what is real
<!--@end-->


*Outcome — success*

`karma: human+3, god+2  ·  xp: 12`

<!--@ hell_events.json | hell_mirror_lake | choices.pierce_illusion.outcome_success.text -->
The mirages dissolve. For a moment the lake shows something true — a vision specific to you, something you needed to see. You don't fully understand it yet. But it stays with you.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+1  ·  xp: 3`

<!--@ hell_events.json | hell_mirror_lake | choices.pierce_illusion.outcome_failure.text -->
The mirages pull you in rather than yielding. For a disorienting moment you are standing somewhere else entirely — a childhood memory, or perhaps someone else's. You surface confused, the lake placid and unhelpful.
<!--@end-->


---

## hell_crossroads_stupa

`realm: hell`

**Title**

<!--@ hell_events.json | hell_crossroads_stupa | title -->
Crossroads Stupa
<!--@end-->


**Body**

<!--@ hell_events.json | hell_crossroads_stupa | text -->
The wind carries the smell of sacred juniper smoke and sacrificial wine far from this place. As you come closer, you see little heaps of tormas and butter lamps, some still burning.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_crossroads_stupa | choices.[0].text -->
Approach the stupa
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_crossroads_stupa`

<!--@ hell_events.json | hell_crossroads_stupa | choices.[0].outcome.text -->
A practitioner emerges from behind the stupa. Summoning magic — the crossroads is the right place for it. Gold is the price.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_crossroads_stupa | choices.[1].text -->
Observe from a distance
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_crossroads_stupa | choices.[1].outcome.text -->
You watch the butter lamps flicker in the wind. Some things are better left undisturbed.
<!--@end-->


---

## hell_yogini_circle

`realm: hell`

**Title**

<!--@ hell_events.json | hell_yogini_circle | title -->
Circle of the Yoginis
<!--@end-->


**Body**

<!--@ hell_events.json | hell_yogini_circle | text -->
The inward-facing side of this circular stone wall is carved with the bizarre forms of sixty four Yoginis. There is no ceiling, so the witches can land when they come flying from vast space to meet their earthly sisters.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_yogini_circle | choices.[0].text -->
Enter the circle
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_circle_of_yoginis`

<!--@ hell_events.json | hell_yogini_circle | choices.[0].outcome.text -->
One of the earthly sisters turns and gestures. No words needed.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_yogini_circle | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_yogini_circle | choices.[1].outcome.text -->
You back away slowly. The air around the circle hums for a long time.
<!--@end-->


#### **correct_rites** — *blue* — requires ritual 2

<!--@ hell_events.json | hell_yogini_circle | choices.correct_rites.text -->
Perform the correct entry rites — approach the circle as it demands
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 15  ·  items: ['space_charm_common']`

<!--@ hell_events.json | hell_yogini_circle | choices.correct_rites.outcome.text -->
You move clockwise, make the right offerings at the right points, and step through the gap with the correct orientation. The carved faces seem to relax. The circle activates around you in spiraling light. One Yogini's form peels slightly from the stone and places something cold in your hand — a small charm of compressed power.
<!--@end-->


#### **circle_meditation** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_yogini_circle | choices.circle_meditation.text -->
Sit at the center and meditate — open yourself to whatever the circle holds
<!--@end-->


*Outcome — success*

`karma: god+3, human+2  ·  xp: 12`

<!--@ hell_events.json | hell_yogini_circle | choices.circle_meditation.outcome_success.text -->
The sixty-four faces hold your attention without pulling it apart. Something passes through you — not comfortable, but clarifying. The energies here are immense and indifferent, but they don't consume you. You emerge with a clean, bright quality to your awareness.
<!--@end-->


*Outcome — failure*

`karma: hell+1  ·  xp: 4`

<!--@ hell_events.json | hell_yogini_circle | choices.circle_meditation.outcome_failure.text -->
The combined power of sixty-four Yoginis is too much to hold. You lose your center within minutes and have to stumble out, disoriented, the carved faces still spinning. You sit outside until the world steadies.
<!--@end-->


---

## hell_medicinal_garden

`realm: hell`

**Title**

<!--@ hell_events.json | hell_medicinal_garden | title -->
Medicinal Garden
<!--@end-->


**Body**

<!--@ hell_events.json | hell_medicinal_garden | text -->
The air is vibrant with the aroma of medicinal herbs and flowers. The healers cultivating them are happy to share some of their knowledge for the benefit of all suffering beings.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_medicinal_garden | choices.[0].text -->
Ask to learn
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_medicinal_garden`

<!--@ hell_events.json | hell_medicinal_garden | choices.[0].outcome.text -->
A healer looks up from her work and nods. She names her price without ceremony.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_medicinal_garden | choices.[1].text -->
Leave them to their work
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_medicinal_garden | choices.[1].outcome.text -->
You leave without disturbing them. The scent of herbs follows you.
<!--@end-->


#### **assist_earn** — *blue* — requires medicine 1

<!--@ hell_events.json | hell_medicinal_garden | choices.assist_earn.text -->
Offer your hands — help with a difficult case in exchange for a share of the harvest
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 10  ·  items: ['herb_bundle', 'healing_herb']`

<!--@ hell_events.json | hell_medicinal_garden | choices.assist_earn.outcome.text -->
The healers hand you a patient immediately and watch without comment. You work. When you finish, one of them presses a cloth bundle into your hands — a selection of herbs, properly dried and labelled, worth more than anything in the nearest market.
<!--@end-->


#### **bhang_ask** — *blue* — requires **trait: bhang_enjoyer**

<!--@ hell_events.json | hell_medicinal_garden | choices.bhang_ask.text -->
Ask about the preparations they do not advertise.
<!--@end-->


*Outcome*

`xp: 20  ·  supplies: {'herbs': 4}`

<!--@ hell_events.json | hell_medicinal_garden | choices.bhang_ask.outcome.text -->
The healer's expression does not change, but she takes you to the far end of the garden and shows you a bed you had walked straight past.

'For pain,' she says, in the tone of someone who has heard every other reason and is offering you the dignity of not giving one.'
<!--@end-->


#### **hunter_trade** — *blue* — requires **trait: hunter**

<!--@ hell_events.json | hell_medicinal_garden | choices.hunter_trade.text -->
Offer what you carry — they will want the parts you do not use.
<!--@end-->


*Outcome*

`xp: 20  ·  supplies: {'herbs': 6}`

<!--@ hell_events.json | hell_medicinal_garden | choices.hunter_trade.outcome.text -->
Sinew, bone, the small glands that are worth more than the meat. She goes through it with the brisk competence of someone who has done this trade for a century.

You come away with herbs and a standing invitation.
<!--@end-->


#### **harvest_rare** — *yellow* — requires roll finesse vs easy

<!--@ hell_events.json | hell_medicinal_garden | choices.harvest_rare.text -->
Carefully harvest some of the rarer specimens growing at the garden's edge
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8  ·  items: ['healing_herb', 'herb_bundle']`

<!--@ hell_events.json | hell_medicinal_garden | choices.harvest_rare.outcome_success.text -->
Your hands are steady enough. The roots come free cleanly, the stalks cut at the right angle. You have a handful of something potent that shouldn't grow anywhere near a hell realm.
<!--@end-->


*Outcome — failure*

`karma: human-1  ·  xp: 2`

<!--@ hell_events.json | hell_medicinal_garden | choices.harvest_rare.outcome_failure.text -->
Your grip slips and you damage the root system of something rare. The healers watch without anger but without warmth. 'Those take twelve years to grow here,' one says quietly. You apologize and leave.
<!--@end-->


---

## hell_eternal_fire

`realm: hell`

**Title**

<!--@ hell_events.json | hell_eternal_fire | title -->
Temple of the Eternal Fire
<!--@end-->


**Body**

<!--@ hell_events.json | hell_eternal_fire | text -->
Priests clad in white robes have been guarding the sacred fire since time immemorial. Many come to pay their respects and seek visions in the dancing flames.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_eternal_fire | choices.[0].text -->
Approach the priests
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_eternal_fire`

<!--@ hell_events.json | hell_eternal_fire | choices.[0].outcome.text -->
A priest turns from the flame and regards you. He names the spells, and then the prices.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_eternal_fire | choices.[1].text -->
Pay your respects and leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_eternal_fire | choices.[1].outcome.text -->
You bow before the flame and step back out. The fire reflected in your eyes for some time after.
<!--@end-->


---

## hell_black_lodge

`realm: hell`

**Title**

<!--@ hell_events.json | hell_black_lodge | title -->
Black Lodge
<!--@end-->


**Body**

<!--@ hell_events.json | hell_black_lodge | text -->
The entrance is half-buried in the earth, marked only with a crooked khatvanga topped with a skull and streaming black ribbons reeking of smoke and poison. As you enter, the darkness overwhelms you - until you notice the glint of a sneering smile.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_black_lodge | choices.[0].text -->
Ask to learn
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_black_lodge`

<!--@ hell_events.json | hell_black_lodge | choices.[0].outcome.text -->
The smile does not move. A hand gestures to a list scratched into the wall. Spells. Prices. No preamble.
<!--@end-->


#### **secret_bearer_welcome** — *blue* — requires **trait: secret_bearer**

<!--@ hell_events.json | hell_black_lodge | choices.secret_bearer_welcome.text -->
You already know how to hold something. Say so.
<!--@end-->


*Outcome*

`xp: 20  ·  add_trait: secret_bearer`

<!--@ hell_events.json | hell_black_lodge | choices.secret_bearer_welcome.outcome.text -->
The doorkeeper asks one question. Your answer is not the right one, but the way you decline to elaborate apparently is.

You are shown further in than most, and what is discussed there stays where it was discussed.
<!--@end-->


#### **[2]** — *grey*

<!--@ hell_events.json | hell_black_lodge | choices.[2].text -->
Back out
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_black_lodge | choices.[2].outcome.text -->
You step back into the light. The khatvanga watches you leave.
<!--@end-->


---

## hell_town_weapons

`realm: hell`

**Title**

<!--@ hell_events.json | hell_town_weapons | title -->
Town
<!--@end-->


**Body**

<!--@ hell_events.json | hell_town_weapons | text -->
A settlement built from salvaged iron and spite. The biggest building is the armoury. Someone is always selling something in the street, and half of it is sharp.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_town_weapons | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_town_weapons`

<!--@ hell_events.json | hell_town_weapons | choices.[0].outcome.text -->
You push through the crowd.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_town_weapons | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_town_weapons | choices.[1].outcome.text -->
You skirt the settlement and keep moving.
<!--@end-->


---

## hell_town_magic

`realm: hell`

**Title**

<!--@ hell_events.json | hell_town_magic | title -->
Town
<!--@end-->


**Body**

<!--@ hell_events.json | hell_town_magic | text -->
A settlement where more windows glow than can be explained by candlelight. Strange smells drift from the apothecary. A scholar argues with a demon outside the library.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_town_magic | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_town_magic`

<!--@ hell_events.json | hell_town_magic | choices.[0].outcome.text -->
You find the market square.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_town_magic | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_town_magic | choices.[1].outcome.text -->
You leave the scholars to their arguments.
<!--@end-->


---

## hell_town_supplies

`realm: hell`

**Title**

<!--@ hell_events.json | hell_town_supplies | title -->
Town
<!--@end-->


**Body**

<!--@ hell_events.json | hell_town_supplies | text -->
A trading post that survives on practicality. The sign reads: FOOD. TOOLS. NO CREDIT. It is the most honest thing you have seen in hell.
<!--@end-->


### Choices


#### **[0]** — *grey*

<!--@ hell_events.json | hell_town_supplies | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hell_town_supplies`

<!--@ hell_events.json | hell_town_supplies | choices.[0].outcome.text -->
The shopkeeper nods without looking up.
<!--@end-->


#### **[1]** — *grey*

<!--@ hell_events.json | hell_town_supplies | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_town_supplies | choices.[1].outcome.text -->
You keep walking.
<!--@end-->


---

## hell_infernal_forge

`realm: hell`

**Title**

<!--@ hell_events.json | hell_infernal_forge | title -->
Infernal Forge
<!--@end-->


**Body**

<!--@ hell_events.json | hell_infernal_forge | text -->
The heat hits you a hundred paces out. A demon the color of cooled lava stands at an enormous anvil, hammering something that glows white. The sign over the door reads: WEAPONS. ARMOR. NO CREDIT. NO REFUNDS. NO EXCEPTIONS.

The demon doesn't look up.
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_infernal_forge | choices.browse.text -->
Browse the forge's stock
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: infernal_forge`

<!--@ hell_events.json | hell_infernal_forge | choices.browse.outcome.text -->
The demon nods once. You are allowed to look.
<!--@end-->


#### **training** — *blue* — requires axes 1

<!--@ hell_events.json | hell_infernal_forge | choices.training.text -->
Ask to be trained in axe techniques
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: infernal_forge`

<!--@ hell_events.json | hell_infernal_forge | choices.training.outcome.text -->
The demon sets down the hammer. "You know which end to hold. Good. Cost you extra for the rest."
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_infernal_forge | choices.steal.text -->
Pocket a blade while the smith has their back turned
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['iron_axe']`

<!--@ hell_events.json | hell_infernal_forge | choices.steal.outcome_success.text -->
A demon at an anvil is completely absorbed in their work. You lift a finished blade from the cooling rack, tuck it under your arm, and walk out at a deliberate pace. The hammering does not stop.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_sentinel  ·  difficulty: hard  ·  karma: hungry_ghost+3`

<!--@ hell_events.json | hell_infernal_forge | choices.steal.outcome_failure.text -->
The hammering stops. The demon turns around, still holding the hammer. They do not speak. They do not need to.
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs easy

<!--@ hell_events.json | hell_infernal_forge | choices.comedy.text -->
Attempt a joke about blacksmiths and hot work
<!--@end-->


*Outcome — success*

`karma: human+2  ·  items: ['scrap_metal']`

<!--@ hell_events.json | hell_infernal_forge | choices.comedy.outcome_success.text -->
"So I said to the blacksmith, 'is it hot in here or is it just your hammer?'" The demon sets down their work. Looks at you. Then emits a sound like metal shearing — which, you eventually realize, is laughter. They hand you a fistful of scrap. 'You. I don't hate you.' Highest praise, probably.
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_infernal_forge | choices.comedy.outcome_failure.text -->
The demon stares at you for a very long time. Then they pick up the hammer again. "Leave," they say. The word is shaped like a threat.
<!--@end-->


#### **collector_spots** — *blue* — requires **trait: collector**

<!--@ hell_events.json | hell_infernal_forge | choices.collector_spots.text -->
There is something in the scrap pile that does not belong there.
<!--@end-->


*Outcome*

`xp: 20  ·  items: ['item_random']`

<!--@ hell_events.json | hell_infernal_forge | choices.collector_spots.outcome.text -->
There is. It has been in the pile long enough to be the colour of the pile, which is presumably why nobody has taken it.

The smith watches you fish it out and says nothing at all, which you decide to interpret generously.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_infernal_forge | choices.leave.text -->
Leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_infernal_forge | choices.leave.outcome.text -->
The hammering resumes behind you.
<!--@end-->


---

## hell_bone_archer_camp

`realm: hell`

**Title**

<!--@ hell_events.json | hell_bone_archer_camp | title -->
Bone Archer Camp
<!--@end-->


**Body**

<!--@ hell_events.json | hell_bone_archer_camp | text -->
A fortified camp of skeleton warriors — most armed with bows, some with knives. They regard you with hollow eyes. One of them, slightly larger than the rest, has set up a makeshift trading post.

"We trade," it says. "We do not explain ourselves."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_bone_archer_camp | choices.browse.text -->
Browse the camp's goods
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: bone_archer_camp`

<!--@ hell_events.json | hell_bone_archer_camp | choices.browse.outcome.text -->
The skeleton gestures at the racks of weapons with one bony hand.
<!--@end-->


#### **training** — *blue* — requires ranged 1

<!--@ hell_events.json | hell_bone_archer_camp | choices.training.text -->
Ask one of the archers to teach you
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: bone_archer_camp  ·  karma: hell+1`

<!--@ hell_events.json | hell_bone_archer_camp | choices.training.outcome.text -->
One of the archers tilts its skull at you, considering. Then it nocks an arrow and gestures for you to do the same.
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_bone_archer_camp | choices.steal.text -->
Lift something from the rack while no one is looking
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['hunting_bow', 'throwing_knife']`

<!--@ hell_events.json | hell_bone_archer_camp | choices.steal.outcome_success.text -->
Skeletons don't blink. What they do have is peripheral vision — but yours is better. You slip a bow from the rack while the trader skeleton is occupied. You are forty paces gone before anyone counts the inventory.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hungry_ghost+3`

<!--@ hell_events.json | hell_bone_archer_camp | choices.steal.outcome_failure.text -->
Forty hollow eye sockets turn toward you simultaneously. The trader skeleton says nothing. It simply nocks an arrow. So do the others.
<!--@end-->


#### **attack** — *grey*

<!--@ hell_events.json | hell_bone_archer_camp | choices.attack.text -->
Draw your weapon — bones break
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+5`

<!--@ hell_events.json | hell_bone_archer_camp | choices.attack.outcome.text -->
The skeletons reach for their weapons without urgency. You get the impression they have been waiting for someone to try this.
<!--@end-->


#### **hunter_talks_shop** — *blue* — requires **trait: hunter**

<!--@ hell_events.json | hell_bone_archer_camp | choices.hunter_talks_shop.text -->
Talk to them about the bows. Only about the bows.
<!--@end-->


*Outcome*

`xp: 20  ·  items: ['item_random']`

<!--@ hell_events.json | hell_bone_archer_camp | choices.hunter_talks_shop.outcome.text -->
Skeletons, it emerges, have opinions about draw weight.

An hour of genuinely technical conversation later, one of them presses something into your hand — not a gift exactly, more a professional courtesy between people who both know what a bad string does in cold.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_bone_archer_camp | choices.leave.text -->
Leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_bone_archer_camp | choices.leave.outcome.text -->
The skeleton archers watch you go, silent.
<!--@end-->


---

## hell_mercy_ward

`realm: hell`

**Title**

<!--@ hell_events.json | hell_mercy_ward | title -->
Mercy Ward
<!--@end-->


**Body**

<!--@ hell_events.json | hell_mercy_ward | text -->
A tent, remarkably clean. Inside, a figure in grey robes tends to the wounded — souls who staggered in from the wastes, demons nursing old injuries. Nobody asks questions. Nobody explains.

"I patch what I can," says the medic, without turning around. "I charge what I must. Sit down if you're bleeding."
<!--@end-->


### Choices


#### **buy** — *grey*

<!--@ hell_events.json | hell_mercy_ward | choices.buy.text -->
Buy supplies and spells
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: mercy_ward  ·  karma: human+1`

<!--@ hell_events.json | hell_mercy_ward | choices.buy.outcome.text -->
The medic points at the supply shelves.
<!--@end-->


#### **rest** — *blue* — requires charm 10

<!--@ hell_events.json | hell_mercy_ward | choices.rest.text -->
Ask to rest and recover
<!--@end-->


*Outcome*

`karma: human+3, god+1  ·  xp: 10`

<!--@ hell_events.json | hell_mercy_ward | choices.rest.outcome.text -->
The medic studies your face, then nods. "An hour. Then I need the cot." You sleep deeply. When you wake, your wounds feel lighter.
<!--@end-->


#### **donate** — *grey*

<!--@ hell_events.json | hell_mercy_ward | choices.donate.text -->
Leave a donation for those who can't pay
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 5`

<!--@ hell_events.json | hell_mercy_ward | choices.donate.outcome.text -->
The medic pauses. Looks at the coins. Looks at you. "I'll make sure it goes to the ones who need it most." They say nothing else. In this place, that is enough.
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs trivial

<!--@ hell_events.json | hell_mercy_ward | choices.comedy.text -->
Crack a very quiet joke to lighten the mood
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 3`

<!--@ hell_events.json | hell_mercy_ward | choices.comedy.outcome_success.text -->
It is a small joke. Barely a joke, really — more of an observation about the absurdity of hell having a triage system. The medic glances up. The corners of their mouth move — not quite a smile, but not not a smile. "I'll put that in the notes," they say. Their prices are slightly more negotiable afterward.
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_mercy_ward | choices.comedy.outcome_failure.text -->
The medic looks at you with the eyes of someone who has been stitching wounds for three hundred years in a place that specializes in creating them. They return to work. You feel, correctly, that you have misjudged the room.
<!--@end-->


#### **chronic_pain_understood** — *blue* — requires **trait: chronic_pain**

<!--@ hell_events.json | hell_mercy_ward | choices.chronic_pain_understood.text -->
You do not need to explain the pain to this one.
<!--@end-->


*Outcome*

`xp: 15  ·  restore: {'hp_percent': 25}`

<!--@ hell_events.json | hell_mercy_ward | choices.chronic_pain_understood.outcome.text -->
The grey-robed figure listens to about six words and then stops you.

'Yes,' she says. 'The kind that is always there.' What she gives you does not cure it, because it cannot be cured, and it is the first thing in a long time that has actually helped.
<!--@end-->


#### **scarred_no_flinch** — *blue* — requires **trait: scarred**

<!--@ hell_events.json | hell_mercy_ward | choices.scarred_no_flinch.text -->
Let them work. You have been through worse than a ward.
<!--@end-->


*Outcome*

`xp: 20  ·  restore: {'hp_percent': 30}`

<!--@ hell_events.json | hell_mercy_ward | choices.scarred_no_flinch.outcome.text -->
She works quickly, because you are not making it difficult, and talks while she does — mostly about other people's wounds, which is her way of not asking about yours.

You leave better mended than you went in.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_mercy_ward | choices.leave.text -->
Leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_mercy_ward | choices.leave.outcome.text -->
The medic returns to work without watching you go.
<!--@end-->


---

## hell_brimstone_lab

`realm: hell`

**Title**

<!--@ hell_events.json | hell_brimstone_lab | title -->
Brimstone Lab
<!--@end-->


**Body**

<!--@ hell_events.json | hell_brimstone_lab | text -->
The structure looks like it's held together by habit and sulfur fumes. A figure peers at you through thick goggles, stirring something that smells like it wants to be left alone.

"Seventeen explosions," they announce, before you can speak. "All educational. You need something that burns, you've come to the right address."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_brimstone_lab | choices.browse.text -->
Buy alchemical supplies
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: brimstone_lab`

<!--@ hell_events.json | hell_brimstone_lab | choices.browse.outcome.text -->
The alchemist sweeps a collection of vials to one side to make room for the transaction.
<!--@end-->


#### **training** — *blue* — requires alchemy 1

<!--@ hell_events.json | hell_brimstone_lab | choices.training.text -->
Ask about alchemy techniques
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: brimstone_lab  ·  karma: asura+1`

<!--@ hell_events.json | hell_brimstone_lab | choices.training.outcome.text -->
"You know the basics. Good. The advanced work is where it gets interesting — and occasionally fatal."
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs easy

<!--@ hell_events.json | hell_brimstone_lab | choices.steal.text -->
Pocket a few vials while the alchemist monologues
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['fire_bomb', 'smoke_bomb', 'antidote']`

<!--@ hell_events.json | hell_brimstone_lab | choices.steal.outcome_success.text -->
The alchemist's lecture on the eighteenth explosion provides excellent cover. Three vials heavier, you edge toward the exit. They are still talking.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+2  ·  xp: 2`

<!--@ hell_events.json | hell_brimstone_lab | choices.steal.outcome_failure.text -->
Your elbow catches a rack of unstable compounds. The subsequent blast leaves you singed, briefly confused, and completely empty-handed. The alchemist writes something in their notes without looking up. "Eighteen explosions," they say. "Seventeen of which were educational."
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs trivial

<!--@ hell_events.json | hell_brimstone_lab | choices.comedy.text -->
Ask how they feel about the eighteenth explosion with full sincerity
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 4  ·  items: ['health_potion']`

<!--@ hell_events.json | hell_brimstone_lab | choices.comedy.outcome_success.text -->
You lean on the counter and deliver the line with complete deadpan: "Seventeen educational explosions is experience. Eighteen is a philosophy." The alchemist freezes. Then cackles. Then nearly knocks over the thing that smells like it wants to be left alone. "Take this," they say, pressing a vial into your hands, "and don't come back. I mean that as a compliment."
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_brimstone_lab | choices.comedy.outcome_failure.text -->
"That is not funny," the alchemist says. "Explosions are not funny. Explosions are science. I have been seriously injured seventeen times and I will not have it trivialized." They point at the door. You go.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_brimstone_lab | choices.leave.text -->
Leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_brimstone_lab | choices.leave.outcome.text -->
Something bubbles aggressively as you go.
<!--@end-->


---

## hell_wardens_pit

`realm: hell`

**Title**

<!--@ hell_events.json | hell_wardens_pit | title -->
Warden's Pit
<!--@end-->


**Body**

<!--@ hell_events.json | hell_wardens_pit | text -->
A fortified post around a deep pit, guards drilling in formation on the parade ground. The warden — a scarred devil in heavy armor — watches them from the parapet.

"Outsiders," she says, not looking at you. "You want something. They always do."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hell_events.json | hell_wardens_pit | choices.browse.text -->
Ask to buy gear
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: wardens_pit  ·  karma: hell+1`

<!--@ hell_events.json | hell_wardens_pit | choices.browse.outcome.text -->
She jerks her chin toward the supply depot.
<!--@end-->


#### **training** — *blue* — requires spears 1

<!--@ hell_events.json | hell_wardens_pit | choices.training.text -->
Request combat training
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: wardens_pit  ·  karma: hell+2`

<!--@ hell_events.json | hell_wardens_pit | choices.training.outcome.text -->
She looks you over slowly. "You know how to hold a spear. The rest is discipline. Discipline costs coin."
<!--@end-->


#### **steal** — *yellow* — requires roll finesse vs normal

<!--@ hell_events.json | hell_wardens_pit | choices.steal.text -->
Slip into the supply depot while everyone is drilling
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['wooden_spear', 'leather_vest']`

<!--@ hell_events.json | hell_wardens_pit | choices.steal.outcome_success.text -->
The drilling formations create a predictable rhythm. You match it — moving only when boots hit the ground, stopping when they stop. The supply depot yields a spear and some armor before the rotation changes. You are back outside before anyone notices the count is off.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+4`

<!--@ hell_events.json | hell_wardens_pit | choices.steal.outcome_failure.text -->
The warden's voice carries across the entire pit: "I SAW THAT." She has not moved from the parapet. She does not need to.
<!--@end-->


#### **attack** — *grey*

<!--@ hell_events.json | hell_wardens_pit | choices.attack.text -->
Challenge the warden's authority — by force
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: hard  ·  karma: hell+6`

<!--@ hell_events.json | hell_wardens_pit | choices.attack.outcome.text -->
The warden doesn't raise her voice. She just raises one finger. The drilling stops. The soldiers turn. "Show me what you've got," she says.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_wardens_pit | choices.leave.text -->
Leave
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_wardens_pit | choices.leave.outcome.text -->
The drilling continues. You are not relevant to it.
<!--@end-->


---

## hell_waystation

`realm: hell`

**Title**

<!--@ hell_events.json | hell_waystation | title -->
Waystation of Ash
<!--@end-->


**Body**

<!--@ hell_events.json | hell_waystation | text -->
A fortified waystation rises from the volcanic plain, its walls scorched black by centuries of eruptions. Smoke vents line the roof, and a battered sign reads 'ALL TRADES WELCOME — NO SOULS ACCEPTED AS PAYMENT.' Inside, merchants, healers, and weapon-smiths carve out a livelihood amid the suffering.
<!--@end-->


---

## hell_angulimala_pursuit

`realm: hell`

**Title**

<!--@ hell_events.json | hell_angulimala_pursuit | title -->
The Garland
<!--@end-->


**Body**

<!--@ hell_events.json | hell_angulimala_pursuit | text -->
The road ahead is clear except for one figure, standing still. Behind him: several bodies. He watches you approach with the calm attention of someone who has made his peace with violence.

Angulimāla. You know the name even here. He does not move to block you. He just watches — to see what you will do.
<!--@end-->


### Choices


#### **walk_around** — *grey*

<!--@ hell_events.json | hell_angulimala_pursuit | choices.walk_around.text -->
Give him a wide berth. Some problems aren't yours to solve.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_angulimala_pursuit | choices.walk_around.outcome.text -->
He watches you go. You feel the weight of his attention until the road curves out of sight.
<!--@end-->


#### **walk_toward** — *blue* — requires yoga 5

<!--@ hell_events.json | hell_angulimala_pursuit | choices.walk_toward.text -->
Walk toward him — not around him. Calmly.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: angulimala  ·  karma: god+3, human+2  ·  add_trait: merciful`

<!--@ hell_events.json | hell_angulimala_pursuit | choices.walk_toward.outcome.text -->
He watches you walk toward him. The calm does not waver — you are not afraid of him, and it shows in every step. Something shifts behind his eyes. He has met this once before, in a different life, a different road, and it ended the same way it ended him.

"You're not afraid," he says. It is not a compliment. It is recognition.

He turns and falls into step beside you.
<!--@end-->


#### **acknowledge_the_craft** — *blue* — requires martial_arts 4

<!--@ hell_events.json | hell_angulimala_pursuit | choices.acknowledge_the_craft.text -->
Acknowledge what you see — not what he's done with it, but the skill itself.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: angulimala  ·  karma: human+2`

<!--@ hell_events.json | hell_angulimala_pursuit | choices.acknowledge_the_craft.outcome.text -->
He tilts his head slightly. Most people flinch or reach for a weapon. You are looking at the bodies the way a craftsperson looks at joinery — reading method, not grieving consequence.

"You know the difference," he says.

You do. So does he. That turns out to be enough.
<!--@end-->


#### **read_the_stillness** — *yellow* — requires roll awareness vs normal

<!--@ hell_events.json | hell_angulimala_pursuit | choices.read_the_stillness.text -->
His stillness isn't threat — read what it actually is, and act on it.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: angulimala  ·  karma: human+3, god+2  ·  add_trait: clear_eyed`

<!--@ hell_events.json | hell_angulimala_pursuit | choices.read_the_stillness.outcome_success.text -->
You see it — the absolute composure of someone who is tired. Not of violence. Of the point of it.

"You're done," you say. Not a question.

A long silence. Then: "I need somewhere that isn't this."

You offer that. He follows.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_elite  ·  difficulty: hard  ·  karma: hell+3`

<!--@ hell_events.json | hell_angulimala_pursuit | choices.read_the_stillness.outcome_failure.text -->
Your movement reads wrong — a reach, a hesitation. He has spent a long time watching for exactly that. He moves before you finish the thought.
<!--@end-->


---

## hell_water_lily

`realm: hell`

**Title**

<!--@ hell_events.json | hell_water_lily | title -->
Still Water
<!--@end-->


**Body**

<!--@ hell_events.json | hell_water_lily | text -->
At the edge of a frozen river in the cold hell wastes, a blue-skinned woman stands alone. She is looking down at the ice. The water beneath it is visible, dark and still.

She does not move when you approach. She has been here a while.
<!--@end-->


### Choices


#### **leave_her** — *grey*

<!--@ hell_events.json | hell_water_lily | choices.leave_her.text -->
Leave her to her silence. Not every stillness wants company.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_water_lily | choices.leave_her.outcome.text -->
You walk on. The frozen river does not change. Neither does she.
<!--@end-->


#### **reach_through_water** — *blue* — requires water_magic 4

<!--@ hell_events.json | hell_water_lily | choices.reach_through_water.text -->
Place your hand on the ice. Commune through it.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: water_lily  ·  karma: human+3, god+2`

<!--@ hell_events.json | hell_water_lily | choices.reach_through_water.outcome.text -->
The cold travels up your arm. You let it. Something underneath the surface stirs — not the water, but her attention.

She looks at your hand on the ice, then at you. "You're not afraid of it," she says.

"No."

She steps back from the river's edge for the first time in a long while. "Where are you going?"
<!--@end-->


#### **sit_in_silence** — *blue* — requires yoga 5

<!--@ hell_events.json | hell_water_lily | choices.sit_in_silence.text -->
Sit beside her. Say nothing. Wait.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: water_lily  ·  karma: god+3, human+2`

<!--@ hell_events.json | hell_water_lily | choices.sit_in_silence.outcome.text -->
You sit. You do not speak. The cold hell wind moves across the ice.

After a long time — long enough that most people would have given up — she turns and looks at you properly for the first time.

"You stayed."

"Yes."

She does not ask why. She seems to already understand. When you stand to leave, she stands with you.
<!--@end-->


#### **speak_plainly** — *yellow* — requires roll charm vs normal

<!--@ hell_events.json | hell_water_lily | choices.speak_plainly.text -->
Say something to her — something real, not reassurance.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: water_lily  ·  karma: human+3`

<!--@ hell_events.json | hell_water_lily | choices.speak_plainly.outcome_success.text -->
What you say is simple. Honest. Not an offer to fix anything — just acknowledgment of what she is looking at and why.

She is quiet for a moment. Then: "You didn't try to talk me out of it."

"No."

She turns from the river. "I'll come with you."
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_water_lily | choices.speak_plainly.outcome_failure.text -->
She looks at you briefly, then back at the ice. The words weren't wrong, exactly — they just weren't right. She doesn't respond. The river holds her attention more completely than you do.
<!--@end-->


---

## hell_serji_watching

`realm: hell`

**Title**

<!--@ hell_events.json | hell_serji_watching | title -->
Old Habit
<!--@end-->


**Body**

<!--@ hell_events.json | hell_serji_watching | text -->
A red devil stands apart from a pit fight, watching. He is the biggest person in the vicinity by a significant margin and the only one not involved. Arms crossed. Expression unreadable.

The fighters below are working hard. He looks like he stopped caring about the outcome some time ago but cannot quite bring himself to walk away.
<!--@end-->


### Choices


#### **walk_past** — *grey*

<!--@ hell_events.json | hell_serji_watching | choices.walk_past.text -->
Walk past. Some people need to find their own door.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_serji_watching | choices.walk_past.outcome.text -->
He doesn't look at you. The fight continues below. You leave him to his watching.
<!--@end-->


#### **stand_beside_him** — *blue* — requires unarmed 4

<!--@ hell_events.json | hell_serji_watching | choices.stand_beside_him.text -->
Stand beside him and watch. Let him see you understand what you're looking at.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: serji  ·  karma: human+2`

<!--@ hell_events.json | hell_serji_watching | choices.stand_beside_him.outcome.text -->
You stand beside him. You watch the same fight. After a while, he speaks without looking at you.

"He's winning because the other one is afraid of his left hand. Doesn't know that himself yet."

"I see it," you say.

He looks at you sideways. A long pause. "You training anyone?"

"I could use someone who knows what they're looking at."
<!--@end-->


#### **offer_something_worth_following** — *blue* — requires leadership 5

<!--@ hell_events.json | hell_serji_watching | choices.offer_something_worth_following.text -->
Tell him what you're doing. Make it worth leaving this for.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: serji  ·  karma: human+3, god+1`

<!--@ hell_events.json | hell_serji_watching | choices.offer_something_worth_following.outcome.text -->
He listens without interrupting. When you finish, the pit fight has ended below — neither of you noticed.

"The gym stopped meaning anything when I got to the top of it," he says. "What you're describing hasn't got a top."

He uncrosses his arms. "Alright."
<!--@end-->


#### **ask_why_he_still_watches** — *yellow* — requires roll charm vs normal

<!--@ hell_events.json | hell_serji_watching | choices.ask_why_he_still_watches.text -->
Ask him why he still watches, if he's done with it.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: serji  ·  karma: human+3`

<!--@ hell_events.json | hell_serji_watching | choices.ask_why_he_still_watches.outcome_success.text -->
He's quiet for a long moment. Then: "Habit. No other reason."

"That's the saddest thing I've heard today."

Something in his face shifts — surprise, maybe, that anyone would say that. Then something closer to a laugh.

"Yeah," he says. "Probably is." He turns from the pit. "You going somewhere?"
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_serji_watching | choices.ask_why_he_still_watches.outcome_failure.text -->
He looks at you once, the way you look at a bad technique — briefly, to catalogue what's wrong. Then back to the fight. He doesn't answer.
<!--@end-->


---

## hell_tejasimha_fire

`realm: hell`

**Title**

<!--@ hell_events.json | hell_tejasimha_fire | title -->
The Best Seat
<!--@end-->


**Body**

<!--@ hell_events.json | hell_tejasimha_fire | text -->
A building is burning. Not collapsing, not yet — fully, magnificently on fire, the kind that takes your breath away from ten meters off.

A red devil is standing inside it. He is laughing. Not the laughter of someone losing their mind — hearty, genuine, appreciative. He is watching it the way you watch a great performance.
<!--@end-->


### Choices


#### **back_away** — *grey*

<!--@ hell_events.json | hell_tejasimha_fire | choices.back_away.text -->
Back away from the lunatic in the burning building.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_tejasimha_fire | choices.back_away.outcome.text -->
The laughter follows you down the road. The building eventually collapses. You're not sure what happened to him. Given everything, probably fine.
<!--@end-->


#### **step_into_the_fire** — *blue* — requires fire_magic 4

<!--@ hell_events.json | hell_tejasimha_fire | choices.step_into_the_fire.text -->
Step into the fire. Stand beside him. See what he's seeing.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: tejasimha  ·  karma: hell+1, human+2`

<!--@ hell_events.json | hell_tejasimha_fire | choices.step_into_the_fire.outcome.text -->
The heat is extraordinary. You let it move around you rather than fighting it. He notices immediately — turns to look at you with something like delight.

"You're not burning," he says.

"Neither are you."

He grins. "I never do. Not on the inside." He gestures at the fire around you. "Beautiful, isn't it?"

You stand together in it for a while before he follows you out.
<!--@end-->


#### **call_from_outside** — *blue* — requires comedy 4

<!--@ hell_events.json | hell_tejasimha_fire | choices.call_from_outside.text -->
Call something genuinely funny into the burning building.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: tejasimha  ·  karma: human+3`

<!--@ hell_events.json | hell_tejasimha_fire | choices.call_from_outside.outcome.text -->
The laugh that comes back from inside the fire is different from before — surprised, real.

His head appears at a burning window. "Who said that?"

"Me."

He stares at you through the smoke and flame for a moment. Then: "Wait there. I'm coming out."
<!--@end-->


#### **hold_your_ground** — *yellow* — requires roll focus vs normal

<!--@ hell_events.json | hell_tejasimha_fire | choices.hold_your_ground.text -->
Hold your ground in the heat until he notices. Don't flinch.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: tejasimha  ·  karma: human+2`

<!--@ hell_events.json | hell_tejasimha_fire | choices.hold_your_ground.outcome_success.text -->
You plant your feet and stay. The heat is punishing. You don't move.

His laughter slows. He turns. For the first time, he is actually looking at you — the person standing in a firestorm out of stubbornness or something he can't name yet.

"You're interesting," he says. "Come here."
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_tejasimha_fire | choices.hold_your_ground.outcome_failure.text -->
The heat wins. You step back, eyes watering. The laughter inside the building doesn't pause. He didn't see you — or if he did, what he saw wasn't enough.
<!--@end-->


---

## hell_sineater_encounter

`realm: hell`

**Title**

<!--@ hell_events.json | hell_sineater_encounter | title -->
The Thirteenth Name
<!--@end-->


**Body**

<!--@ hell_events.json | hell_sineater_encounter | text -->
Something is wrong with the stretch of road ahead. Not visibly — the landmarks are where they should be. But the space between them feels occupied in a way that has nothing to do with sight.

The sensation of being read passes over you like cold water. Something vast and hungry has noticed you are here. It has twelve names already. It is considering a thirteenth.
<!--@end-->


### Choices


#### **back_away_carefully** — *grey*

<!--@ hell_events.json | hell_sineater_encounter | choices.back_away_carefully.text -->
Back away. Slowly. Entities like this respect nothing, but they respect distance.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_sineater_encounter | choices.back_away_carefully.outcome.text -->
The presence recedes as you put ground between you. Whatever it is, it does not follow — not yet. The road normalizes behind you. You take a different route.
<!--@end-->


#### **address_its_nature** — *blue* — requires black_magic 5

<!--@ hell_events.json | hell_sineater_encounter | choices.address_its_nature.text -->
Greet it correctly — by speaking to what it is, not what it looks like.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: sineater_thirteen  ·  karma: god+2, human+2`

<!--@ hell_events.json | hell_sineater_encounter | choices.address_its_nature.outcome.text -->
You name its nature — not a name but a category, the oldest classification for entities born from shattering. The presence goes very still.

Then, something shifts. The hunger is still there, but turned sideways. Curious.

"You know what I am," it says. The voice comes from nowhere in particular.

"Yes."

"No one has said that before without running afterward."

A form coalesces at the edge of sight — something like a person, the way that lightning is something like light. "I will walk with you for a while," it says. "I want to see what you do with that knowledge."
<!--@end-->


#### **offer_perspective** — *blue* — requires space_magic 4

<!--@ hell_events.json | hell_sineater_encounter | choices.offer_perspective.text -->
Offer it something other than a soul to absorb — a perspective from outside the hunger.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: sineater_thirteen  ·  karma: god+3`

<!--@ hell_events.json | hell_sineater_encounter | choices.offer_perspective.outcome.text -->
You open yourself to the emptiness rather than filling it — show it the space between things, where hunger has no object. For a moment the presence is genuinely disoriented.

Then fascinated.

"That is not a thing I have encountered," it says slowly. "Twelve names and none of them knew that."

The form that solidifies is almost gentle. "Show me more of that."
<!--@end-->


#### **hold_yourself_together** — *yellow* — requires roll focus vs difficult

<!--@ hell_events.json | hell_sineater_encounter | choices.hold_yourself_together.text -->
Let it read you — and don't come apart while it does.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: sineater_thirteen  ·  karma: god+3, human+2`

<!--@ hell_events.json | hell_sineater_encounter | choices.hold_yourself_together.outcome_success.text -->
The scrutiny is total. Every surface of yourself is turned over and examined. Most people fragment under that kind of attention — become something easier to absorb.

You don't.

A long pause. "You stayed yourself," it says, almost puzzled.

"Yes."

"Interesting. I should like to understand how." The form that takes shape beside you is curious rather than hungry — for now. "Lead on."
<!--@end-->


*Outcome — failure*

`karma: hell+2  ·  xp: -20`

<!--@ hell_events.json | hell_sineater_encounter | choices.hold_yourself_together.outcome_failure.text -->
The scrutiny is too complete. For a moment you are not entirely sure which thoughts are yours. You stumble back, gasping.

The presence withdraws, satisfied with the inspection if not the meal. You are whole — mostly. The road ahead feels different for a while.
<!--@end-->


---

## hell_dvijihva_chase

`realm: hell`

**Title**

<!--@ hell_events.json | hell_dvijihva_chase | title -->
Two Invoices
<!--@end-->


**Body**

<!--@ hell_events.json | hell_dvijihva_chase | text -->
A blue devil is moving through the junction ahead with the practiced urgency of someone who has been in this exact situation before. He checks both approaches at every turn, tracks two separate routes in his head simultaneously, and is doing it with an air of irritated professionalism.

You can hear the reason why from both directions. Two sets of footsteps. Two sets of clients who have recently compared notes.
<!--@end-->


### Choices


#### **not_your_problem** — *grey*

<!--@ hell_events.json | hell_dvijihva_chase | choices.not_your_problem.text -->
Not your problem. Clear the junction before the clients arrive.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_dvijihva_chase | choices.not_your_problem.outcome.text -->
You get out of the way. A few junctions later, you hear a brief commotion behind you. Then silence. Whether that means he escaped or didn't, you genuinely can't tell.
<!--@end-->


#### **manage_both_pursuers** — *blue* — requires guile 4

<!--@ hell_events.json | hell_dvijihva_chase | choices.manage_both_pursuers.text -->
Help him play both clients — you take one side, he takes the other.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: dvijihva  ·  karma: hungry_ghost+2, human+1`

<!--@ hell_events.json | hell_dvijihva_chase | choices.manage_both_pursuers.outcome.text -->
You split without discussing it — instinct meeting instinct. Ten minutes later, both clients have been sent in wrong directions, each convinced the other one was dealt with.

He looks at you afterward with genuine appreciation. "You understood the problem immediately."

"So did you, apparently. Twice."

A dry laugh. "Occupational hazard. You're looking for a sorcerer?"
<!--@end-->


#### **demonstrate_craft** — *blue* — requires sorcery 4

<!--@ hell_events.json | hell_dvijihva_chase | choices.demonstrate_craft.text -->
Cast something that stops both pursuers in their tracks — show him what real craft looks like.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: dvijihva  ·  karma: human+2`

<!--@ hell_events.json | hell_dvijihva_chase | choices.demonstrate_craft.outcome.text -->
The effect is clean and leaves no trace. Both sets of footsteps stop. He watches the working from the junction, and what crosses his face isn't gratitude — it's professional assessment.

"That's a good working," he says. "Who trained you?"

The conversation that follows lasts until the junction is well behind you. He is still talking when you realize he has simply joined your party.
<!--@end-->


#### **spot_the_closer_one** — *yellow* — requires roll awareness vs easy

<!--@ hell_events.json | hell_dvijihva_chase | choices.spot_the_closer_one.text -->
Spot which client is closer and warn him with enough precision to be useful.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: dvijihva  ·  karma: human+2`

<!--@ hell_events.json | hell_dvijihva_chase | choices.spot_the_closer_one.outcome_success.text -->
"Left side, thirty seconds. The right one turned at the last junction."

He pivots immediately, adjusts his route, and slips through a gap you would not have noticed yourself. Two minutes later he is beside you, walking casually.

"Good eyes," he says. "I owe you one. Or would, except — " He tilts his head. "Actually, where are you headed?"
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_dvijihva_chase | choices.spot_the_closer_one.outcome_failure.text -->
You call the wrong direction. He goes that way and nearly walks into one of his pursuers. The resulting scramble is chaotic and you lose sight of him in the confusion. He probably survived — he had the look of someone who has done this before — but he is not inclined to stop and chat.
<!--@end-->


---

## hell_coolhead_aftermath

`realm: hell`

**Title**

<!--@ hell_events.json | hell_coolhead_aftermath | title -->
Post-Clarity
<!--@end-->


**Body**

<!--@ hell_events.json | hell_coolhead_aftermath | text -->
A black devil sits in the wreckage of what was recently a building. He is writing in a notebook. The walls around him are scorched. There is a crater behind him of impressive diameter.

He looks up as you approach, expression neutral. He does not seem distressed. He seems, if anything, very calm — the particular calm of someone who has been through the seal-breaking and come out the other side of it.
<!--@end-->


### Choices


#### **keep_moving** — *grey*

<!--@ hell_events.json | hell_coolhead_aftermath | choices.keep_moving.text -->
Keep moving. Whatever happened here is between him and the building.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_coolhead_aftermath | choices.keep_moving.outcome.text -->
He watches you go, then returns to his notes. The crater will be there long after both of you have moved on.
<!--@end-->


#### **recognize_the_documentation** — *blue* — requires learning 4

<!--@ hell_events.json | hell_coolhead_aftermath | choices.recognize_the_documentation.text -->
Look at what he's writing. Recognize what he's actually documenting.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: coolhead_hotblood  ·  karma: human+3`

<!--@ hell_events.json | hell_coolhead_aftermath | choices.recognize_the_documentation.outcome.text -->
The notes are behavioral — not damage assessment but internal process, the phenomenology of the retort breaking. He is treating himself as a specimen.

"You're cataloguing it," you say.

"If I don't, who will?" He glances at the crater. "This is the third time. The interval is getting shorter. I should understand the mechanism."

You talk for a while about mechanisms. By the end, he is walking with you.
<!--@end-->


#### **offer_actual_calm** — *blue* — requires yoga 3

<!--@ hell_events.json | hell_coolhead_aftermath | choices.offer_actual_calm.text -->
Offer a different kind of stillness — not suppression, but actual peace.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: coolhead_hotblood  ·  karma: god+2, human+3`

<!--@ hell_events.json | hell_coolhead_aftermath | choices.offer_actual_calm.outcome.text -->
You settle beside him and demonstrate what you mean — not blocking the feeling but letting it move through without accumulating. He watches with the careful attention of someone encountering an unfamiliar technique.

"I've been treating it like a pressure problem," he says slowly. "Structural."

"It isn't."

"No." He closes the notebook. "Show me that again, and I'll come with you."
<!--@end-->


#### **ask_how_it_felt** — *yellow* — requires roll charm vs easy

<!--@ hell_events.json | hell_coolhead_aftermath | choices.ask_how_it_felt.text -->
Ask how it felt. Without judgment — you are genuinely curious.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: coolhead_hotblood  ·  karma: human+3`

<!--@ hell_events.json | hell_coolhead_aftermath | choices.ask_how_it_felt.outcome_success.text -->
He blinks. Most people, apparently, do not ask that.

"Clarifying," he says, after a moment. Then, more slowly: "Like setting down something I'd been carrying so long I'd forgotten its weight."

He looks at the crater again. "The building was empty. I made sure."

"I didn't ask."

"No." He stands, brushing ash from his robe. "You want a sorcerer who's done suppressing things?"
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_coolhead_aftermath | choices.ask_how_it_felt.outcome_failure.text -->
He looks at you with the polite wariness of someone who has heard that question before and found it a prelude to a lecture. He answers briefly and returns to his notes. The conversation does not develop.
<!--@end-->


---

## hell_princess_spiderface

`realm: hell`

**Title**

<!--@ hell_events.json | hell_princess_spiderface | title -->
First Impression
<!--@end-->


**Body**

<!--@ hell_events.json | hell_princess_spiderface | text -->
A black devil stands in the middle of a street. The ash around her has footprints leading away — running, by the depth and spacing of them. She is watching after the person who left.

She is not upset. She has the look of someone who is simply used to it. Her face is the reason. She knows this.
<!--@end-->


### Choices


#### **also_back_away** — *grey*

<!--@ hell_events.json | hell_princess_spiderface | choices.also_back_away.text -->
Take a different route. You don't need to add to her morning.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_princess_spiderface | choices.also_back_away.outcome.text -->
You go around. She doesn't see you do it. This, at least, you spare her.
<!--@end-->


#### **healers_approach** — *blue* — requires white_magic 3

<!--@ hell_events.json | hell_princess_spiderface | choices.healers_approach.text -->
Approach with a healer's attention — look past the surface to what's actually there.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: princess_spiderface  ·  karma: human+4, god+2`

<!--@ hell_events.json | hell_princess_spiderface | choices.healers_approach.outcome.text -->
You walk up to her directly. Healers learn early not to flinch — injury looks like injury, whatever form it takes.

She turns. Waits for the reaction.

You simply say: "Are you alright?"

A long silence. "People don't usually — " She stops. Starts again. "No. I mean, yes. I'm fine. I just —"

"Do you want company?" you ask.

She looks at you for a long time. Then: "Yes. Actually."
<!--@end-->


#### **speak_to_the_spirit** — *blue* — requires space_magic 3

<!--@ hell_events.json | hell_princess_spiderface | choices.speak_to_the_spirit.text -->
Greet her the way you'd greet a spirit — speak to what's behind the surface.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: princess_spiderface  ·  karma: god+3, human+2`

<!--@ hell_events.json | hell_princess_spiderface | choices.speak_to_the_spirit.outcome.text -->
Space magic teaches you that what you see and what is there are not always the same thing. You address the presence behind the face — the one that names spirits by name and asks how they've been.

Something brightens in her eyes. "You can tell."

"Yes."

"Most people can't. Or won't." She glances at the retreating footprints. "Their loss, honestly. The spirits I know are very good company." She turns. "Are you going somewhere?"
<!--@end-->


#### **dont_look_away** — *yellow* — requires roll charm vs normal

<!--@ hell_events.json | hell_princess_spiderface | choices.dont_look_away.text -->
Hold her gaze and say something true to the person behind the face.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: princess_spiderface  ·  karma: human+4`

<!--@ hell_events.json | hell_princess_spiderface | choices.dont_look_away.outcome_success.text -->
You don't flinch. You don't make a point of not flinching. You just look at her the way you'd look at anyone, and say something that belongs to the conversation rather than to her face.

She exhales — a small, controlled sound. "That was nice," she says, quietly. "That was really very nice." A pause. "I'm Princess Spiderface. People run, usually, so I don't get to do introductions much. Where are you headed?"
<!--@end-->


*Outcome — failure*

`karma: human+1`

<!--@ hell_events.json | hell_princess_spiderface | choices.dont_look_away.outcome_failure.text -->
You hold her gaze, but something in what you say catches wrong — too careful, too deliberate. She can tell you're working at it. She smiles, but it is the practiced smile of someone who has been given effort instead of ease.

"Thank you for trying," she says. "That's more than most." She turns back to the empty street.
<!--@end-->


---

## hell_samvibrahmi_fortress

`realm: hell`

**Title**

<!--@ hell_events.json | hell_samvibrahmi_fortress | title -->
Security Theater
<!--@end-->


**Body**

<!--@ hell_events.json | hell_samvibrahmi_fortress | text -->
A roadside ruin has been transformed. Tripwires — visible only if you know what to look for. Sight-lines from every approach accounted for. A small figure inside is crouched over what appears to be a very precise map, muttering assessments of approach vectors.

He looks up when he realizes you've reached the interior of his perimeter without triggering a single countermeasure. His expression cycles through surprise, calculation, and something that might be professional offense.
<!--@end-->


### Choices


#### **announce_yourself** — *grey*

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.announce_yourself.text -->
Announce yourself calmly and give him time to collect himself.
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.announce_yourself.outcome.text -->
He accepts this with dignity and proceeds to document your entry vector in significant detail. You exchange brief pleasantries and move on. He returns to his map.
<!--@end-->


#### **walk_him_through_it** — *blue* — requires comedy 4

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.walk_him_through_it.text -->
Walk him through exactly how you got past every single one of his defenses.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: samvibrahmi  ·  karma: human+3`

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.walk_him_through_it.outcome.text -->
You do it with affection — the way you'd point out a brilliant mistake to someone you respected. By the third countermeasure you breached without noticing, his expression has moved from offense to pained hilarity.

By the seventh, he is laughing despite himself.

"It's the cabbage cart problem," he says finally. "You plan for every threat you can imagine, and then—"

"The one you didn't imagine."

"Yes." He folds the map. "Traveling with you would be very bad for my threat assessments. I'll do it."
<!--@end-->


#### **find_the_gap** — *blue* — requires guile 5

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.find_the_gap.text -->
Identify the one gap in his defenses he hasn't thought of yet.
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: samvibrahmi  ·  karma: human+2`

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.find_the_gap.outcome.text -->
You point to a spot on his map. "From there. At this elevation, in rain. You've assumed flat-light approach vectors."

He stares at the spot. His eye twitches once.

"That's — " He stops. "I have been working on this for three weeks."

"I know."

Another pause. "Do you want a job? I mean — I assume you have a job. Can I have a job? The perimeter here is clearly inadequate."
<!--@end-->


#### **make_it_useful** — *yellow* — requires roll charm vs normal

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.make_it_useful.text -->
Invite him to redirect all this preparation into something that actually makes sense.
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: samvibrahmi  ·  karma: human+2`

<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.make_it_useful.outcome_success.text -->
"You've put all this work into defending a ruin that no one was going to attack anyway," you say. "Travel with me and I can promise you: the threats will be real."

He looks at you. Then at his map. Then at you again.

"The threats will be real," he repeats slowly, as though tasting the words.

"Genuinely dangerous. Multiple approaches. Poor visibility. Everything you've been preparing for."

He rolls up the map with the energy of a man who has finally been understood.
<!--@end-->


*Outcome — failure*


<!--@ hell_events.json | hell_samvibrahmi_fortress | choices.make_it_useful.outcome_failure.text -->
He considers your offer carefully, then shakes his head. "The threats out there are speculative. The threat models in here are documented." He taps his map. "I will join you when I have finished mapping all approaches to this ruin."

You look at the ruin. It has approximately forty approach vectors. You will not wait.
<!--@end-->


---

## hell_warden_strongroom

`realm: hell`

**Title**

<!--@ hell_events.json | hell_warden_strongroom | title -->
The Warden's Strongroom
<!--@end-->


**Body**

<!--@ hell_events.json | hell_warden_strongroom | text -->
A door of blue iron set into the ice, and behind it a room the cold has kept exactly as it was left: a desk, a ledger, a rack of seals on hooks.

One hook is labelled and empty. The rest hold the authority to open every lock in the cold hells, and nobody has been in to count them for a very long time.
<!--@end-->


### Choices


#### **take_seal** — *grey*

<!--@ hell_events.json | hell_warden_strongroom | choices.take_seal.text -->
Take a warden's seal from the rack
<!--@end-->


*Outcome*

`karma: hungry_ghost+2  ·  xp: 12  ·  flags: {'cold_warden_seal_found': True}`

<!--@ hell_events.json | hell_warden_strongroom | choices.take_seal.outcome.text -->
Cold blue iron, heavier than it looks, stamped with a sigil that makes your thumb ache where it rests. Whatever this opens, it opens with authority.
<!--@end-->


#### **ledger** — *blue* — requires learning 3

<!--@ hell_events.json | hell_warden_strongroom | choices.ledger.text -->
Read the ledger before you touch anything
<!--@end-->


*Outcome*

`karma: human+4, hell-3  ·  xp: 22  ·  gold: 60  ·  flags: {'cold_warden_seal_found': True}`

<!--@ hell_events.json | hell_warden_strongroom | choices.ledger.outcome.text -->
Every seal is signed out against a prisoner's name and a sentence length. The empty hook belongs to a seal signed out four hundred years ago against a sentence of ninety days, never returned. Somebody is still in a box out there on a warrant that expired before this ice formed.

You take a seal, and you take the ledger page too, because a name will matter more than a key.
<!--@end-->


#### **strip** — *grey*

<!--@ hell_events.json | hell_warden_strongroom | choices.strip.text -->
Take everything that is not nailed down
<!--@end-->


*Outcome*

`karma: hungry_ghost+5  ·  xp: 10  ·  gold: 170  ·  items: ['item_random']  ·  flags: {'cold_warden_seal_found': True}`

<!--@ hell_events.json | hell_warden_strongroom | choices.strip.outcome.text -->
Seals, desk fittings, the good inkwell, and a strongbox that has clearly not been opened since the last audit.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_warden_strongroom | choices.leave.text -->
Take nothing from a warden
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hell_events.json | hell_warden_strongroom | choices.leave.outcome.text -->
You close the blue iron door behind you. The rack of seals stays on its hooks, and every lock in the cold hells stays shut.
<!--@end-->


---

## hell_frozen_prisoner

`realm: hell`

**Title**

<!--@ hell_events.json | hell_frozen_prisoner | title -->
The Frozen Prisoner
<!--@end-->


**Body**

<!--@ hell_events.json | hell_frozen_prisoner | text -->
A pillar of clear ice with a man inside it, upright, eyes open. He is alive in the way things are alive here — aware, unable to move, and entirely unable to stop being aware.

A locked iron collar shows at his throat. His lips move. It takes a while to work out that he is counting.
<!--@end-->


### Choices


#### **unlock** — *grey*

<!--@ hell_events.json | hell_frozen_prisoner | choices.unlock.text -->
Use the warden's seal on the collar
<!--@end-->


*Outcome*

`karma: god+8, human+6, hell-8  ·  xp: 40  ·  flags: {'cold_prisoner_freed': True}`

<!--@ hell_events.json | hell_frozen_prisoner | choices.unlock.outcome.text -->
The seal touches the collar and the ice goes out of the pillar all at once, like a held breath. He falls forward into your arms — thin, freezing, four hundred years into a ninety-day sentence — and the first thing he does, before anything else, is finish the number he was on.

Then he stops counting. You get the impression that took more effort than standing up.
<!--@end-->


#### **break_ice** — *yellow* — requires roll strength vs difficult

<!--@ hell_events.json | hell_frozen_prisoner | choices.break_ice.text -->
Break the pillar open by force
<!--@end-->


*Outcome — success*

`karma: human+5, god+3  ·  xp: 20  ·  flags: {'cold_prisoner_freed': True}`

<!--@ hell_events.json | hell_frozen_prisoner | choices.break_ice.outcome_success.text -->
It takes an hour of hammering and the ice comes away in plates. The collar stays locked — you cannot do anything about the collar — but he can walk, and he goes, wearing it, which he seems to consider an enormous improvement.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 5  ·  hp_loss: {'amount': 'light', 'target': 'random'}`

<!--@ hell_events.json | hell_frozen_prisoner | choices.break_ice.outcome_failure.text -->
The ice is not ordinary ice. You succeed only in making a great deal of noise and taking the skin off two sets of knuckles, and his eyes track every failed swing.
<!--@end-->


#### **warmth** — *blue* — requires fire_magic 4

<!--@ hell_events.json | hell_frozen_prisoner | choices.warmth.text -->
Melt him out slowly
<!--@end-->


*Outcome*

`karma: god+6, human+5, hell-4  ·  xp: 30  ·  items: ['item_random']  ·  flags: {'cold_prisoner_freed': True}`

<!--@ hell_events.json | hell_frozen_prisoner | choices.warmth.outcome.text -->
Fast heat would kill him. You spend most of a day bringing the pillar up by degrees, and he comes out of it able to speak, which he could not have done any other way. He tells you his name and the number he had reached. Both are worth writing down.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_frozen_prisoner | choices.leave.text -->
There is nothing you can do here
<!--@end-->


*Outcome*

`karma: hell+3, animal+2  ·  xp: 3  ·  pressure: water-12`

<!--@ hell_events.json | hell_frozen_prisoner | choices.leave.outcome.text -->
You walk on. Behind you, at the edge of hearing, the counting continues.
<!--@end-->


---

## hell_blisterfang

`realm: hell`

**Title**

<!--@ hell_events.json | hell_blisterfang | title -->
Blisterfang
<!--@end-->


**Body**

<!--@ hell_events.json | hell_blisterfang | text -->
The red devil sprawled across three chairs outside a slag-side drinking house is enormous, cheerful, and entirely unbothered by the four separate people currently glaring at him from across the yard.

"Blisterfang," he agrees, when you say the name. "Everyone's looking for me this season. It's flattering, honestly."
<!--@end-->


### Choices


#### **collect** — *grey*

<!--@ hell_events.json | hell_blisterfang | choices.collect.text -->
Tell him the ember merchant wants paying
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 12  ·  flags: {'blisterfang_found': True}`

<!--@ hell_events.json | hell_blisterfang | choices.collect.outcome.text -->
"He does," Blisterfang says. "He absolutely does." He does not reach for a purse. He does, however, stop sprawling, which from a devil that size is a whole sentence.

You have found him. Getting the money out of him is going to be a separate piece of work.
<!--@end-->


#### **fight** — *grey*

<!--@ hell_events.json | hell_blisterfang | choices.fight.text -->
Take the payment off him
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: red_devil_warband  ·  difficulty: hard  ·  karma: asura+4, hell+3`

<!--@ hell_events.json | hell_blisterfang | choices.fight.outcome.text -->
"Ah," he says, delighted, getting up. "One of *those* collectors." The four people glaring from across the yard suddenly become extremely interested in the wall.
<!--@end-->


#### **why_owed** — *blue* — requires awareness 14

<!--@ hell_events.json | hell_blisterfang | choices.why_owed.text -->
Ask what the debt was actually for
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 26  ·  items: ['item_random']  ·  flags: {'blisterfang_found': True, 'ember_debt_truth': True}`

<!--@ hell_events.json | hell_blisterfang | choices.why_owed.outcome.text -->
It is not a debt. It is a settlement — the merchant's brazier burned a district and Blisterfang paid the compensation out of his own pocket at the time, and the merchant has spent forty years re-describing this as a loan to anyone who will listen.

Blisterfang has never once corrected the story. "Let him have it," he says. "He needs it more than I need to be right." He gives you the original settlement papers to prove it, and does not ask you to use them.
<!--@end-->


#### **drink** — *blue* — requires guile 3

<!--@ hell_events.json | hell_blisterfang | choices.drink.text -->
Buy him a drink and get it out of him sideways
<!--@end-->


*Outcome*

`karma: human+3, asura+2  ·  xp: 20  ·  gold: 120  ·  flags: {'blisterfang_found': True, 'ember_debt_paid': True}`

<!--@ hell_events.json | hell_blisterfang | choices.drink.outcome.text -->
Three rounds in, Blisterfang is explaining his entire financial position unprompted, including where the money is and why he has not handed it over: he simply forgets, constantly, and has done for decades. He is enormously relieved to be reminded and pays on the spot, in coin, counted out twice because he loses his place.
<!--@end-->


---

## hell_ember_merchant_debt

`realm: hell`

**Title**

<!--@ hell_events.json | hell_ember_merchant_debt | title -->
The Ember Merchant's Books
<!--@end-->


**Body**

<!--@ hell_events.json | hell_ember_merchant_debt | text -->
The ember merchant keeps his stall at the edge of the slag fields and his ledger under the counter, and he wants to know — before you have finished saying hello — whether you have found Blisterfang yet.
<!--@end-->


### Choices


#### **pay_over** — *grey*

<!--@ hell_events.json | hell_ember_merchant_debt | choices.pay_over.text -->
Hand over what you collected
<!--@end-->


*Outcome*

`karma: human+4, hell+2  ·  xp: 30  ·  gold: 100  ·  items: ['item_random']  ·  flags: {'ember_debt_paid': True}`

<!--@ hell_events.json | hell_ember_merchant_debt | choices.pay_over.outcome.text -->
He counts it three times and his hands shake on the second count. Then he writes the entry closed, turns the ledger around, and shows you the line — forty years of a single unresolved figure, ruled off at last.

He pays your fee without being asked and gives you the good coal on top of it.
<!--@end-->


#### **tell_truth** — *grey*

<!--@ hell_events.json | hell_ember_merchant_debt | choices.tell_truth.text -->
Show him the settlement papers
<!--@end-->


*Outcome*

`karma: god+8, human+8, hungry_ghost-5  ·  xp: 40  ·  gold: 60  ·  flags: {'ember_debt_paid': True}`

<!--@ hell_events.json | hell_ember_merchant_debt | choices.tell_truth.outcome.text -->
He reads them standing up and does not say anything for a long time. Then he sits down on his own stock.

"I knew," he says. "I have known for forty years." What he wanted was not the money; it was for the debt to stay open, because a debt is a thread to a person and he has nothing else left. You stay a while. When you go, the ledger line is ruled off, and he did it himself.
<!--@end-->


#### **browse** — *grey*

<!--@ hell_events.json | hell_ember_merchant_debt | choices.browse.text -->
Just here to trade
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: ember_merchant`

<!--@ hell_events.json | hell_ember_merchant_debt | choices.browse.outcome.text -->
He is a good merchant when he is not talking about Blisterfang, which is roughly a third of the time.
<!--@end-->


#### **advance** — *blue* — requires trade 3

<!--@ hell_events.json | hell_ember_merchant_debt | choices.advance.text -->
Negotiate your fee up front
<!--@end-->


*Outcome*

`karma: human+2, hungry_ghost+2  ·  xp: 14  ·  gold: 70`

<!--@ hell_events.json | hell_ember_merchant_debt | choices.advance.outcome.text -->
You point out that a forty-year-old debt has a collection value considerably below its face value, and that you are the only person who has ever offered to go and get it. He grumbles and pays an advance, which is the first money that ledger has generated in four decades.
<!--@end-->


---

## hell_scroll_in_the_drift

`realm: hell`

**Title**

<!--@ hell_events.json | hell_scroll_in_the_drift | title -->
Something in the Drift
<!--@end-->


**Body**

<!--@ hell_events.json | hell_scroll_in_the_drift | text -->
A corner of oiled cloth shows above the snow at the base of a wind-scoured ridge — the kind of thing that has been buried and uncovered a dozen times by the same wind and will be buried again by evening.

Something is wrapped in it.
<!--@end-->


### Choices


#### **dig** — *grey*

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.dig.text -->
Dig it out
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 14  ·  flags: {'mantra_scroll_found': True}`

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.dig.outcome.text -->
A scroll case, sealed, dry inside. The scroll within is a sequence of protective mantras copied in a careful old hand, and the cold has not touched a single character of it.
<!--@end-->


#### **read** — *blue* — requires ritual 3

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.read.text -->
Read the mantras before wrapping them back up
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 24  ·  learn_spell: {'school': 'white_magic'}  ·  flags: {'mantra_scroll_found': True}`

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.read.outcome.text -->
They are cold-protection mantras, and they are a good set — the third one in particular is a variant you have not met, and you copy it into your own book before resealing the case. Whoever lost this lost something they will not survive the season without.
<!--@end-->


#### **tracks** — *blue* — requires awareness 13

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.tracks.text -->
Read the ground — where did it come from?
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 20  ·  items: ['item_random']  ·  flags: {'mantra_scroll_found': True}`

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.tracks.outcome.text -->
The cloth did not blow here. It was dropped by someone moving north-east along the ridge line at a stumble, and there is a second set of prints behind the first, keeping pace and not closing. Somebody was being followed and shed weight to move faster.

You take the scroll, and you take the bearing.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_scroll_in_the_drift | choices.leave.text -->
Leave it to the drift
<!--@end-->


*Outcome*


<!--@ hell_events.json | hell_scroll_in_the_drift | choices.leave.outcome.text -->
By evening the wind has covered the corner of cloth again, as it has a dozen times before.
<!--@end-->


---

## hell_cold_hermit

`realm: hell`

**Title**

<!--@ hell_events.json | hell_cold_hermit | title -->
The Hermit in the Cold
<!--@end-->


**Body**

<!--@ hell_events.json | hell_cold_hermit | text -->
He has dug himself into the lee of a boulder and built a wall of packed snow, and he is sitting in the shelter of it doing the only thing left to do, which is recite from memory and get it wrong.

He does not look up. "Third repetition," he says. "I lose it at the third repetition. I have lost it at the third repetition for eleven days."
<!--@end-->


### Choices


#### **return_scroll** — *grey*

<!--@ hell_events.json | hell_cold_hermit | choices.return_scroll.text -->
Give him the scroll
<!--@end-->


*Outcome*

`karma: god+8, human+6  ·  xp: 40  ·  flags: {'mantra_returned': True}`

<!--@ hell_events.json | hell_cold_hermit | choices.return_scroll.outcome.text -->
He takes the case without understanding what it is, and then understands, and stops.

He reads the third repetition off the page, out loud, correctly, for the first time in eleven days — and the cold goes out of the hollow. Not metaphorically: the snow wall starts dripping. He keeps reading. You leave him at the seventh repetition with his eyes shut and his shelter melting around him.
<!--@end-->


#### **recite** — *blue* — requires yoga 4

<!--@ hell_events.json | hell_cold_hermit | choices.recite.text -->
Recite the third repetition for him from memory
<!--@end-->


*Outcome*

`karma: god+10, human+4  ·  xp: 30  ·  flags: {'mantra_returned': True}  ·  add_trait: steady_practice  ·  pressure: space+20`

<!--@ hell_events.json | hell_cold_hermit | choices.recite.outcome.text -->
You do not have his scroll but you have the shape of the thing, and mantras are not private property. You give him the third repetition. He takes it up, gets it, carries on — and by the fifth he has remembered the rest himself, the way you remember a road once someone names the first turning.
<!--@end-->


#### **shelter** — *grey*

<!--@ hell_events.json | hell_cold_hermit | choices.shelter.text -->
Build his wall up properly and share your fire
<!--@end-->


*Outcome*

`karma: human+5, god+2  ·  xp: 14  ·  add_trait: merciful`

<!--@ hell_events.json | hell_cold_hermit | choices.shelter.outcome.text -->
You cannot give him the words but you can give him another few days to find them. The wall goes up to head height, the fire is banked to last, and he thanks you without once breaking the recitation, which keeps going wrong in the same place.
<!--@end-->


#### **leave** — *grey*

<!--@ hell_events.json | hell_cold_hermit | choices.leave.text -->
Leave him to it
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 3  ·  pressure: space-10`

<!--@ hell_events.json | hell_cold_hermit | choices.leave.outcome.text -->
"Third repetition," he says behind you, starting again. "Third repetition."
<!--@end-->


---
