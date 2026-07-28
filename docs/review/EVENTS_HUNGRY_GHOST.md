# Hungry Ghost — Events

*150 events. 46 added in the 2026-07-27 sessions, marked **NEW EVENT**. Individual choices added later to an older event are marked **NEW**.*

*Edit the prose between the anchors. Headings, ids and the mechanical lines under each choice are generated — edits there are lost.*

---

## hg_starving_preta

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_starving_preta | title -->
The Starving Spirit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_starving_preta | text -->
An emaciated figure blocks the path — belly swollen like a gourd, throat thin as a reed. Its hands are skeletal claws reaching toward you. The voice that comes out is barely a whisper.

"Please. Anything. I haven't eaten in — I can't remember how long. Please."
<!--@end-->


### Choices


#### **give_rations** — *grey*

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.give_rations.text -->
Share your rations
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.give_rations.outcome.text -->
The food dissolves the moment it touches its lips, transformed to ash by the curse it carries. But it weeps, grateful for the gesture. "You... tried. That's more than most."
<!--@end-->


#### **medicine_check** — *blue* — requires medicine 2

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.medicine_check.text -->
Examine its condition carefully
<!--@end-->


*Outcome*

`karma: god+5, human+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.medicine_check.outcome.text -->
You recognize the curse of the hungry ghost — every craving fed only deepens the hunger. You describe this to the creature gently, guiding it to eat slowly, deliberately. It seems to find some fragile relief in understanding its own condition.
<!--@end-->


#### **give_teachings** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.give_teachings.text -->
Teach it about the nature of craving
<!--@end-->


*Outcome*

`karma: god+5, human+4  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.give_teachings.outcome.text -->
"There is no meal that ends hunger. There is no object that ends want. The relief you seek cannot be found in a bowl." The preta goes still. Its eyes, desperate a moment ago, grow strangely clear. It doesn't answer. But something in its posture changes.
<!--@end-->


#### **turn_away** — *grey*

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.turn_away.text -->
Turn your eyes away and walk past
<!--@end-->


*Outcome*

`karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.turn_away.outcome.text -->
The whisper fades behind you. You tell yourself it's not your problem. The realm of hungry ghosts is full of such creatures. You can't save them all.
<!--@end-->


#### **generous_feeds** — *blue* — requires **trait: generous**  **NEW**

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.generous_feeds.text -->
Give it something. It will not be enough and give it anyway.
<!--@end-->


*Outcome*

`karma: hungry_ghost-6, human+4  ·  xp: 14  ·  supplies: {'food': -3}  ·  pressure: water+12`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.generous_feeds.outcome.text -->
It is not enough. Nothing would be — the throat is a needle and the belly is a room.

But it stops, for a moment, being a thing that is starving and becomes a thing that is being fed, and it looks at you differently for the length of that moment.
<!--@end-->


#### **scrimper_calculates** — *blue* — requires **trait: scrimper**  **NEW**

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.scrimper_calculates.text -->
Work out exactly how little will satisfy it.
<!--@end-->


*Outcome*

`karma: hungry_ghost+4  ·  xp: 30  ·  pressure: earth-8`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.scrimper_calculates.outcome.text -->
The answer is: nothing will, so the correct expenditure is the smallest amount that buys passage.

You are right. You are right in a way that sits badly on the walk afterwards, and the party does not discuss it.
<!--@end-->


#### **attack** — *grey*

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.attack.text -->
Cut it down — put it out of its misery
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: lost_preta  ·  difficulty: easy  ·  karma: hell+4, hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_starving_preta | choices.attack.outcome.text -->

<!--@end-->


---

## hg_bone_merchant_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | title -->
Bone Merchant
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | text -->
A skeleton in a tattered merchant's robe sits behind a blanket of wares laid on the dry earth — wrapped bundles, clay jars, glinting objects of uncertain purpose. It clicks its jaw merrily as you approach.

"Ah! Customers! Or at least, beings capable of carrying things away! Welcome, welcome — the overhead is low and the bones are FREE."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.browse.text -->
Browse the wares
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_bone_merchant  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.browse.outcome.text -->

<!--@end-->


#### **trade_skill** — *blue* — requires trade 2

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.trade_skill.text -->
Negotiate the prices down
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.trade_skill.outcome.text -->
You counter its opening price with calm authority, citing comparable goods in the living world. The skeleton clacks its teeth together in what might be admiration. "You know your market. Fine — take it for less."
<!--@end-->


#### **rob** — *yellow* — requires roll finesse vs easy

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.rob.text -->
Wait for its attention to wander and pocket something
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.rob.outcome_success.text -->
The skeleton turns to argue with a passing rolang. Your hand moves before you've quite decided to move it. By the time it looks back, you're innocently studying the sky.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_warrior  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.rob.outcome_failure.text -->
The skeleton's eye sockets swivel with unsettling precision. "I may be dead, but I am not BLIND." It produces a weapon from somewhere in its robes.
<!--@end-->


#### **comedy** — *yellow* — requires roll comedy vs easy

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.comedy.text -->
Tell a skeleton joke
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 5  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.comedy.outcome_success.text -->
"...and the skeleton said, 'I just don't have the guts for it!'" The merchant clacks its jaw so hard a tooth falls out. "HA! Oh — oh, that's GOOD. I haven't laughed like that since — well, since I had muscles to laugh with. Here, take this. Consider it payment for services rendered."
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_bone_merchant_event | choices.comedy.outcome_failure.text -->
The merchant stares at you with hollow sockets. "Was that... a joke? Was it supposed to be funny?" Uncomfortable silence. You browse its wares.
<!--@end-->


---

## hg_restless_grave

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_restless_grave | title -->
The Restless Grave
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_restless_grave | text -->
The earth shifts. A hand pushes through the soil — five fingers, then a second hand. Something is clawing its way up from below. The ground heaves.
<!--@end-->


### Choices


#### **help_out** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.help_out.text -->
Grab its hands and pull it free
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: random  ·  karma: human+3, animal+2`

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.help_out.outcome_success.text -->
You haul it clear of the earth — a confused rolang, blinking in the grey light. It looks at its hands, then at you. Something surfaces in its eyes. Not a full mind, but enough. It stays close to your heel like a dog that's found someone.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bog_zombie  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.help_out.outcome_failure.text -->
It comes up snarling — whatever consciousness it had is buried under panic and hunger. It goes straight for you.
<!--@end-->


#### **dig_it_up** — *blue* — requires strength 15

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.dig_it_up.text -->
Force the earth open with brute strength
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: random  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.dig_it_up.outcome.text -->
You get both hands under the soil and heave. The earth gives. The rolang sits up, dazed and blinking. It looks at you for a long moment, then slowly nods. It will follow you.
<!--@end-->


#### **last_rites** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.last_rites.text -->
Perform last rites — put whatever's down there to rest
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.last_rites.outcome.text -->
You press your palm to the churning soil and recite the words. The hands slow, relax, and slip back into the earth. The ground settles. The air is lighter.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.leave.text -->
Walk away
<!--@end-->


*Outcome*

`karma: animal+2`

<!--@ hungry_ghost_events.json | hg_restless_grave | choices.leave.outcome.text -->
A low groan follows you from beneath the trembling ground. It fades as you move on. This realm is full of things trying to surface.
<!--@end-->


---

## hg_swamp_crossing

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_swamp_crossing | title -->
The Fetid Crossing
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_swamp_crossing | text -->
A wide stretch of black, stinking water blocks the path. Shapes move beneath the surface — too large to be debris, too slow to be fish. The only bridge is half-rotted wood on crumbling stone. It might hold. Might.
<!--@end-->


### Choices


#### **use_bridge** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.use_bridge.text -->
Cross the bridge quickly
<!--@end-->


*Outcome — success*

`xp: 5`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.use_bridge.outcome_success.text -->
You move fast and light, skipping over the worst boards. The bridge shudders but holds. On the far bank, you look back — a plank falls into the water the moment your foot leaves it.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: swamp_vermin  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.use_bridge.outcome_failure.text -->
The board snaps. You go in. The water is cold and thick as tar — and something in it is already moving toward you.
<!--@end-->


#### **wade_through** — *blue* — requires constitution 14

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.wade_through.text -->
Wade through — constitution over caution
<!--@end-->


*Outcome*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.wade_through.outcome.text -->
You take the damage. The water burns where it touches skin, and something bumps against your leg in the darkness. You push through on will alone and drag yourself up the far bank, filthy and hurting. But through.
<!--@end-->


#### **find_path** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.find_path.text -->
Look for another way around
<!--@end-->


*Outcome*

`xp: 7`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.find_path.outcome.text -->
There — a line of flat stones barely visible below the surface, an old ford hidden by the murk. You pick your way across with dry boots.
<!--@end-->


#### **frail_struggles** — *blue* — requires **trait: frail**  **NEW**

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.frail_struggles.text -->
Black water to the chest, and you are not built for this.
<!--@end-->


*Outcome*

`xp: 22  ·  hp_loss: {'amount': 'light', 'target': 'random'}  ·  pressure: earth-8`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.frail_struggles.outcome.text -->
You are not. You make it across and you make it across badly, and you spend the next day with something in your lungs that should not be in them.

The party slows for you, which you would rather they did not.
<!--@end-->


#### **strong_fords_it** — *blue* — requires **trait: strong**  **NEW**

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.strong_fords_it.text -->
Take the rope across first. You are the one who can.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.strong_fords_it.outcome.text -->
You go in with the line and the current is exactly as bad as it looks and you stand in it anyway while everyone else comes over hand by hand.

Your legs are unhappy for a day. Nobody else gets wet above the waist.
<!--@end-->


#### **swim** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.swim.text -->
Swim across
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bog_zombie  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_swamp_crossing | choices.swim.outcome.text -->
Within three strokes something grabs your ankle.
<!--@end-->


---

## hg_wandering_monk

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_wandering_monk | title -->
The Dead Monk
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_wandering_monk | text -->
A skeleton in saffron robes sits in perfect lotus position on a flat stone. Prayer beads still wrapped around its bony fingers. Intact, somehow — no rot, no damage, as if it simply sat down and stopped one day.

As you approach, its jaw opens: "I have been waiting. Not for you specifically. Just... waiting."
<!--@end-->


### Choices


#### **meditate_together** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.meditate_together.text -->
Sit and meditate together
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 20`

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.meditate_together.outcome.text -->
You sit across from it in the grey dust. For a long time, neither of you speaks. Then the skeleton begins, in a voice like wind through empty rooms, to talk about impermanence — not as tragedy, but as relief. You listen. When you open your eyes, hours have passed and you feel lighter than you have in some time.
<!--@end-->


#### **ask_teaching** — *grey*

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.ask_teaching.text -->
Request a teaching — offer payment
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.ask_teaching.outcome.text -->
It accepts the coin without looking at it and begins. The teaching is brief, precise, and aimed exactly at something you've been struggling with. You aren't sure how it knew.
<!--@end-->


#### **ask_about_realm** — *grey*

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.ask_about_realm.text -->
Ask about the hungry ghost realm
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.ask_about_realm.outcome.text -->
"This realm is the shape of want," it says. "Every being here is caught in the moment they decided their craving was more important than everything else. They are still in that moment. They will be until they aren't." It resumes its stillness.
<!--@end-->


#### **steal_beads** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.steal_beads.text -->
Take the prayer beads while it's distracted
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+4, god-3  ·  items: ['prayer_beads']`

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.steal_beads.outcome_success.text -->
Your hand moves. The beads slide free. The skeleton sits perfectly still. Maybe it didn't notice. Maybe it chose not to.
<!--@end-->


*Outcome — failure*

`karma: god-4, hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_wandering_monk | choices.steal_beads.outcome_failure.text -->
"Well," the skeleton says softly, without opening its eyes, "what can I expect from beings in this realm if not demented hijinks like that?" It sounds more tired than angry. You retreat with your dignity in tatters.
<!--@end-->


---

## hg_preta_pack

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_preta_pack | title -->
Hungry Crowd
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_preta_pack | text -->
A pack of pretas surrounds you — a dozen, maybe more — moaning and reaching with skeletal hands. Their eyes are cavernous and desperate. They don't attack. They beg. The sound is almost worse than violence.
<!--@end-->


### Choices


#### **share_supplies** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.share_supplies.text -->
Share your supplies
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.share_supplies.outcome.text -->
The food vanishes in their hands — the curse takes it before it reaches their mouths. But the act itself seems to do something. The desperate reaching slows. They let you pass.
<!--@end-->


#### **intimidate** — *yellow* — requires roll strength vs normal

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.intimidate.text -->
Drive them back with presence and force of will
<!--@end-->


*Outcome — success*

`karma: hell+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.intimidate.outcome_success.text -->
You spread your arms wide and roar. For a moment, the part of them that remembers fear overrides the hunger. They scatter into the grey mist.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: hell+4`

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.intimidate.outcome_failure.text -->
The hunger is stronger than the fear. They surge forward.
<!--@end-->


#### **lead_to_water** — *blue* — requires persuasion 3

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.lead_to_water.text -->
Lead them toward a water source
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.lead_to_water.outcome.text -->
You speak calmly and point the way — there's a trickle of clean water half a mile east, something most denizens here cannot find or would not think to look for. They turn. Whether the water helps is uncertain. But they turn.
<!--@end-->


#### **fight_through** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.fight_through.text -->
Fight your way through
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: hell+4, asura+2`

<!--@ hungry_ghost_events.json | hg_preta_pack | choices.fight_through.outcome.text -->

<!--@end-->


---

## hg_charnel_ground_entrance

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | title -->
The Charnel Grounds
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | text -->
Smoke rises from ritual pyres. Human bones are arranged in geometric patterns on the ground — too deliberate to be accidental, not quite like anything you recognize. A vetala perches on a skull-pile, watching you with amused curiosity.

"Another living one. How delightful. We don't get many."
<!--@end-->


### Choices


#### **ask_passage** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.ask_passage.text -->
Ask for passage through
<!--@end-->


*Outcome*

`karma: human+2`

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.ask_passage.outcome.text -->
"Passage costs breath," it says. "Not much. Just a little. You have plenty to spare." There's a brief cold sensation, as if something has been lifted from you. You feel slightly less alive than you did. The vetala waves you through with its too-long fingers.
<!--@end-->


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.fight.text -->
Challenge the vetala
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_scout  ·  difficulty: normal  ·  karma: human+2, asura+3`

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.fight.outcome.text -->

<!--@end-->


#### **black_magic** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.black_magic.text -->
Demonstrate your dark workings
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 15`

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.black_magic.outcome.text -->
You show it something that makes its eyes go wide with professional appreciation. "Oh, you ARE interesting," it says. "Someone actually worth talking to." It grants passage and, before you leave, whispers the shape of a spell you hadn't known before.
<!--@end-->


#### **fastidious_appalled** — *blue* — requires **trait: fastidious**  **NEW**

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.fastidious_appalled.text -->
You cannot help it. You simply cannot help it.
<!--@end-->


*Outcome*

`xp: 14  ·  pressure: earth-8`

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.fastidious_appalled.outcome.text -->
It is not fear, which would at least be respectable. It is that everything here is *touching* everything else, and you spend the whole passage moving in a way the vetala find frankly hilarious.

They let you through specifically to see how far you will get.
<!--@end-->


#### **trade_stories** — *blue* — requires charm 15

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.trade_stories.text -->
Offer to trade stories
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_charnel_ground_entrance | choices.trade_stories.outcome.text -->
Vetalas prize novelty above most things, and living stories are rarest of all. You sit together on the skull-pile for an hour, trading tales. It laughs often. When you leave, it waves with something approaching fondness.
<!--@end-->


---

## hg_grave_robbers

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_grave_robbers | title -->
Grave Robbers
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_grave_robbers | text -->
Two skeletons are prying open a stone sarcophagus with iron bars. They freeze when they see you — a guilty, comedic tableau. One slowly puts the crowbar behind its back.
<!--@end-->


### Choices


#### **help_them** — *grey*

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.help_them.text -->
Help them open it — split the loot
<!--@end-->


*Outcome*

`karma: hungry_ghost+4  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.help_them.outcome.text -->
Three sets of hands make short work of the lid. Inside: some aged valuables, a corroded weapon, a few coins. You divide the take by unspoken agreement.
<!--@end-->


#### **stop_them** — *grey*

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.stop_them.text -->
Stop them — drive them off
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warrior_pair  ·  difficulty: normal  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.stop_them.outcome.text -->

<!--@end-->


#### **demand_cut** — *blue* — requires charm 14

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.demand_cut.text -->
Demand a cut for your silence
<!--@end-->


*Outcome*

`karma: asura+3  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.demand_cut.outcome.text -->
You plant yourself between them and the tomb and fold your arms. They exchange a glance — or the skeleton equivalent — and reluctantly extend a share. Good bones know when they're outmatched.
<!--@end-->


#### **report** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.report.text -->
Find a skeleton patrol and report them
<!--@end-->


*Outcome — success*

`karma: human+4  ·  xp: 8  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.report.outcome_success.text -->
You locate a patrol two streets over and lead them back. The grave robbers are hauled away clacking in protest. The patrol sergeant presses a coin into your hand — the King's reward for civic virtue.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_warrior_pair  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_grave_robbers | choices.report.outcome_failure.text -->
The grave robbers see you look around for a patrol, decide their odds are better now, and attack.
<!--@end-->


---

## hg_teahouse_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_teahouse_event | title -->
The Last Cup
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_teahouse_event | text -->
In an impossible pocket of warmth among the grey wastes, a skeletal figure in fine robes serves tea to the dead. The smell is real — jasmine and wood smoke, somehow surviving in this realm. Dead patrons sit quietly at low tables. A hand-painted sign above the door reads: ALL ARE WELCOME. PAYMENT EXPECTED.
<!--@end-->


### Choices


#### **enter_rest** — *grey*

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.enter_rest.text -->
Enter and rest
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_teahouse  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.enter_rest.outcome.text -->

<!--@end-->


#### **ask_patrons** — *grey*

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.ask_patrons.text -->
Ask about the other patrons
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.ask_patrons.outcome.text -->
The teamaster pours without looking up. "The one by the window was a judge. That one a merchant. The two arguing in the corner have been arguing about a land dispute for two hundred years. The tea helps. Not much, but some."
<!--@end-->


#### **perform** — *yellow* — requires roll performance vs normal

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.perform.text -->
Perform for the patrons
<!--@end-->


*Outcome — success*

`karma: human+4  ·  xp: 10  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.perform.outcome_success.text -->
The dead crowd goes quiet as you begin. Then something stirs in them — the memory of being moved by something beautiful. Coins appear on tables. The teamaster nods at you with something like approval.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.perform.outcome_failure.text -->
Silence. Then an awkward clicking of bones. The teamaster sets a cup of tea gently in front of you. "Sit," they say. "Drink. We all have bad days."
<!--@end-->


#### **tea_ritualist_last_cup** — *blue* — requires **trait: tea_ritualist**  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.tea_ritualist_last_cup.text -->
There is a right way to take a last cup.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+12`

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.tea_ritualist_last_cup.outcome.text -->
There is, and you do it — the whole form, in a bone teahouse at the edge of the grey.

The skeleton proprietor watches every movement. When you finish it turns the cup over, which you understand at once to mean that the house will not be serving anyone else today.
<!--@end-->


#### **help_serve** — *blue* — requires grace 3

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.help_serve.text -->
Offer to help serve
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_teahouse_event | choices.help_serve.outcome.text -->
You spend an hour moving through the tables, refilling cups with the careful attention the work demands. The teamaster watches you from across the room. At the end, it sets before you a full meal and refuses payment. "Well done," is all it says.
<!--@end-->


---

## hg_undead_caravan

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_undead_caravan | title -->
The Dead Caravan
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_undead_caravan | text -->
A line of skeletons carrying bundles marches along a dusty road. Pack animals made of bone and binding-wire bear crates of indeterminate goods. A skeleton with an extravagant feathered hat rides at the front on a skeletal horse.

"Traders of the dead! We go between the cities of this realm and ask no questions of the living. Care to travel with us for a stretch?"
<!--@end-->


### Choices


#### **travel_with** — *grey*

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.travel_with.text -->
Travel with them awhile
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.travel_with.outcome.text -->
Safe company across a bleak stretch of road. The caravan guards watch the wasteland for threats. The feathered hat bobs ahead. You part ways at a crossroads.
<!--@end-->


#### **trade** — *grey*

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.trade.text -->
Browse the caravan's goods
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_bone_merchant  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.trade.outcome.text -->

<!--@end-->


#### **guard_services** — *blue* — requires strength 14

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.guard_services.text -->
Offer your services as a guard
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: human+3  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.guard_services.outcome.text -->
The hat bobs appreciatively. "A living fighter! Excellent — rolang packs have been troublesome this season." Three miles on, the packs appear. You earn your pay.
<!--@end-->


#### **ambush** — *grey*

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.ambush.text -->
Ambush the caravan
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warband  ·  difficulty: hard  ·  karma: hell+5, hungry_ghost+4`

<!--@ hungry_ghost_events.json | hg_undead_caravan | choices.ambush.outcome.text -->
The feathered hat turns. The guards reach for weapons. The trading life has made them careful.
<!--@end-->


---

## hg_wailing_well

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_wailing_well | title -->
The Wailing Well
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_wailing_well | text -->
A stone well stands alone in a dead field. No village, no path to it — it was simply placed here and has been here a long time. Wailing rises from its depths. Not wind. Voices, dozens of them, calling from somewhere far below. Something glints at the bottom.
<!--@end-->


### Choices


#### **lower_down** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.lower_down.text -->
Lower yourself down on a rope
<!--@end-->


*Outcome — success*

`xp: 6  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.lower_down.outcome_success.text -->
Hand over hand in the dark, the voices growing louder. Your feet touch the bottom — wet stone, a narrow chamber. And there: a cache, sealed in oilcloth. Someone threw it in a long time ago.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_wailing_well | choices.lower_down.outcome_failure.text -->
The rope slips at the worst moment. You take the fall hard on cold stone and have to drag yourself back up, bruised and empty-handed.
<!--@end-->


#### **listen** — *blue* — requires awareness 15

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.listen.text -->
Be very still and listen to the voices
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.listen.outcome.text -->
You close your eyes and let the wailing wash over you. Under it — patterns, repetitions. These aren't screams of pain. They're warnings. Specific ones, about specific places in this realm. You listen until you have what you need.
<!--@end-->


#### **throw_offering** — *grey*

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.throw_offering.text -->
Throw an offering into the depths
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.throw_offering.outcome.text -->
Coins fall into the dark. The wailing pauses — as if something has been surprised. Then, slowly, it stills. The field is quiet for the first time in what feels like a long age.
<!--@end-->


#### **seal_well** — *blue* — requires earth_magic 3

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.seal_well.text -->
Seal it with earth magic
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.seal_well.outcome.text -->
You bring stone up from below and cap the well properly. The voices stop with finality. Something is over.
<!--@end-->


#### **sing_together** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.sing_together.text -->
Sing along with the wailing
<!--@end-->


*Outcome*

`karma: god+5, human+4  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_wailing_well | choices.sing_together.outcome.text -->
You add your voice to theirs — not mocking, but joining. For a moment the dissonance is jarring. Then something shifts. The voices find a new shape around yours, a resolution they hadn't been able to reach alone. One by one, they stop. The field is quiet.
<!--@end-->


---

## hg_vetala_riddler

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_riddler | title -->
The Riddler
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_riddler | text -->
A vetala hangs upside-down from a dead tree by its knees, grinning. Its arms are folded. It seems completely comfortable.

"Answer my riddle, traveler, and I'll let you pass with a gift. Fail, and I take something of yours."
<!--@end-->


### Choices


#### **accept** — *yellow* — requires roll awareness vs normal

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.accept.text -->
Accept the challenge
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 12  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.accept.outcome_success.text -->
"What is it — a shoal of silver fish jumps up and down in a blue net?" You think. Then: "The stars in the night sky." The vetala blinks, rights itself, and drops to the ground. "Hm. Correct. I haven't heard that from someone in decades." It tosses you something valuable.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.accept.outcome_failure.text -->
You guess wrong. The vetala drops to the ground with a long, satisfied smile. "Mine, I think." Your coin purse is lighter when you walk away.
<!--@end-->


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.fight.text -->
Refuse and fight
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_scout  ·  difficulty: normal  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.fight.outcome.text -->

<!--@end-->


#### **counter_riddle** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.counter_riddle.text -->
Counter with your own riddle
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 15  ·  items: ['item_random', 'item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.counter_riddle.outcome.text -->
You pose a riddle back at it. The vetala's grin falters. It answers wrong. You collect the reward twice over — once for accepting the challenge, once for winning it.
<!--@end-->


#### **curious_engages** — *blue* — requires **trait: curious**  **NEW**

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.curious_engages.text -->
A riddle. Obviously you are going to try the riddle.
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.curious_engages.outcome.text -->
You are, and the vetala can tell, and it is so pleased to have a genuine participant that it gives you the second riddle for free.

You get one of the two. It considers this a good afternoon's work for both of you.
<!--@end-->


#### **forgetful_loses_it** — *blue* — requires **trait: forgetful**  **NEW**

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.forgetful_loses_it.text -->
It said the riddle. You heard the riddle.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: space-10`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.forgetful_loses_it.outcome.text -->
You heard the riddle and it has gone, entirely, in the time it took to start thinking about it.

The vetala repeats it once, with visible enjoyment, and then declines to repeat it again.
<!--@end-->


#### **trick** — *yellow* — requires roll guile vs difficult

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.trick.text -->
Try to steal its treasure without engaging the riddle at all
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+3  ·  xp: 10  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.trick.outcome_success.text -->
While the vetala is busy posing dramatically, you've already located the cache behind the tree roots and lifted it. You wave cheerfully as you leave. The vetala is still explaining the rules.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: vetala_pack  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_vetala_riddler | choices.trick.outcome_failure.text -->
The vetala's smile disappears. It drops to the ground and three more drop from the branches. "Let's try a different game."
<!--@end-->


---

## hg_burial_mound

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_burial_mound | title -->
The Burial Mound
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_burial_mound | text -->
An ancient mound rises from the swamp, its entrance marked with faded symbols carved into standing stones. Cold air breathes from the opening — not the damp cold of the swamp, but the dry cold of sealed places.
<!--@end-->


### Choices


#### **enter** — *grey*

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.enter.text -->
Enter without preparation
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rotting_sentinel  ·  difficulty: normal  ·  karma: asura+2  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.enter.outcome.text -->
Something ancient is waiting in the dark.
<!--@end-->


#### **read_symbols** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.read_symbols.text -->
Study the carved symbols before entering
<!--@end-->


*Outcome*

`xp: 10  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.read_symbols.outcome.text -->
The symbols are warnings — and instructions. You understand what is inside, what it guards, and how to approach it without waking the worst of it. You go in, find what you came for, and leave intact.
<!--@end-->


#### **ritual** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.ritual.text -->
Perform a ritual for the entombed
<!--@end-->


*Outcome*

`karma: god+7  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.ritual.outcome.text -->
You don't take anything. You leave offerings instead — a little food, some incense, a prayer for the dead. The cold air stills. Somewhere inside, something ancient settles into proper rest.
<!--@end-->


#### **call_chieftain** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.call_chieftain.text -->
Call the spirit within to your side
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: temba  ·  karma: god+4`

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.call_chieftain.outcome.text -->
The offering is correct. The incantation is correct. A shape emerges from the mound's dark — a dralha, a warrior-chieftain, still bearing the weapons of a kingdom that has not existed in centuries. It looks at you with eyes that have not looked at anything for a very long time.
<!--@end-->


#### **collapse** — *blue* — requires earth_magic 2

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.collapse.text -->
Seal the entrance
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_burial_mound | choices.collapse.outcome.text -->
You bring the entrance stones down. Whatever is inside stays there.
<!--@end-->


---

## hg_corpse_flower

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_corpse_flower | title -->
The Corpse Flower
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_corpse_flower | text -->
An enormous flower blooms in the swamp, its petals the color of bruised flesh. Its scent is overpowering — sweetly wrong, like incense covering something that should not be sweetened. Dead insects litter the ground around it in concentric rings.
<!--@end-->


### Choices


#### **harvest** — *blue* — requires alchemy 2

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.harvest.text -->
Harvest it for reagents
<!--@end-->


*Outcome*

`xp: 8  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.harvest.outcome.text -->
You cut carefully, taking the useful parts without triggering the aromatic glands. The reagents are worth having — the flower's strange chemistry has properties you've never seen elsewhere.
<!--@end-->


#### **resist** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.resist.text -->
Walk past without being drawn in
<!--@end-->


*Outcome — success*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.resist.outcome_success.text -->
The smell hooks something in you and pulls. You keep moving. It takes more will than you expected.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: swamp_vermin  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.resist.outcome_failure.text -->
The scent overwhelms you — you stumble, and the stumbling draws things from the mire.
<!--@end-->


#### **study** — *blue* — requires medicine 3

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.study.text -->
Study it from a safe distance
<!--@end-->


*Outcome*

`xp: 10  ·  items: ['herb_bundle']`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.study.outcome.text -->
Medicinal — in the right doses. The same compound that overwhelms at close range becomes a useful palliative in small quantities. You harvest a bundle carefully.
<!--@end-->


#### **burn** — *grey*

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.burn.text -->
Burn it
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.burn.outcome.text -->
The smell, briefly, is terrible. Then it's gone. Whatever the flower was attracting, it won't attract anymore.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.meditate.text -->
Meditate on it — find the beauty in the strange
<!--@end-->


*Outcome*

`karma: human+3, god+3  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_corpse_flower | choices.meditate.outcome.text -->
Disgust is a judgment. You sit with the smell and the wrongness until they stop being wrong and start being simply what they are. The flower is a flower. It does what it does. Something in you loosens.
<!--@end-->


---

## hg_skeleton_king_herald

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | title -->
The Herald
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | text -->
A copper skeleton in ceremonial armor — turquoise beads strung between its ribs, feathers wired to its shoulder plates — plants itself in the middle of the road. Its voice is enormous for its frame.

"His Ruby-like Majesty, the Skeleton King of the Setting Sun, demands tribute from all who traverse his domain. Pay, serve, or be added to the collection."
<!--@end-->


### Choices


#### **pay** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.pay.text -->
Pay the tribute
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.pay.outcome.text -->
The herald accepts the gold with practiced dignity. "For your patient compliance, receive a sparkle of the King's unceasing glow." It touches your brow with a copper finger. Something warm passes through you — and for the next few encounters, your words carry unusual weight.
<!--@end-->


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.fight.text -->
Refuse and draw your weapon
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: hard  ·  karma: asura+4`

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.fight.outcome.text -->

<!--@end-->


#### **diplomatic_immunity** — *blue* — requires persuasion 3

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.diplomatic_immunity.text -->
Claim diplomatic immunity
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.diplomatic_immunity.outcome.text -->
You produce a very official-looking nothing and speak with great certainty. The herald stares at the empty air where your credentials should be. "...very well. I shall note your passage as diplomatic in nature." You walk past with a straight face.
<!--@end-->


#### **military_service** — *blue* — requires swords 3

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.military_service.text -->
Offer military service instead of tribute
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: human+2, asura+2  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.military_service.outcome.text -->
"A fighting force! The King can always use those." It leads you to a trouble spot — rolang incursion, needs clearing. You earn safe passage and the patrol's grudging respect.
<!--@end-->


#### **hymn_of_praise** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.hymn_of_praise.text -->
Offer a hymn of praise in lieu of gold
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 10  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_skeleton_king_herald | choices.hymn_of_praise.outcome.text -->
"I am a poor traveler, but I will offer my only treasure — my voice." The herald goes still as you begin. By the second verse, it has lowered its halberd. By the third, it has produced a small donation from its own coin pouch. "His Majesty would approve," it says. "Pass freely."
<!--@end-->


---

## hg_desperate_mother

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_desperate_mother | title -->
The Mother
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_desperate_mother | text -->
A rolang woman crouches in the grey dust, clutching a bundle to her chest, rocking back and forth. The bundle is empty — just rags shaped by a mother's hands. She doesn't seem to know. Her eyes are elsewhere, in a time this realm cannot reach.

"Have you seen my child? I just need to feed them. Just once more."
<!--@end-->


### Choices


#### **comfort_gently** — *grey*

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.comfort_gently.text -->
Sit with her gently — offer what comfort you can
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.comfort_gently.outcome.text -->
She doesn't fully notice you. But your presence seems to register somewhere, some warmth in the grey. She rocks more slowly.
<!--@end-->


#### **teach_gently** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.teach_gently.text -->
Guide her gently toward understanding her condition
<!--@end-->


*Outcome*

`karma: god+6, human+3  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.teach_gently.outcome.text -->
You speak softly about attachment, about the nature of what she holds. She listens with the partial attention of someone dreaming. A long pause. She looks at the bundle. "There's nothing here, is there." It isn't a question. She sets it down. Her hands are empty.
<!--@end-->


#### **tell_truth** — *yellow* — requires roll charm vs difficult

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.tell_truth.text -->
Tell her plainly that her child is gone
<!--@end-->


*Outcome — success*

`karma: god+4, human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.tell_truth.outcome_success.text -->
You choose your words with great care. She goes still. Looks at you. Looks at the bundle. "I know," she says, very quietly. After a long moment: "I know." She rocks more slowly. She seems, in some way, relieved.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: swamp_wraith  ·  difficulty: hard  ·  karma: hell+2`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.tell_truth.outcome_failure.text -->
The words come out wrong. Something in her breaks in the wrong direction. The grief becomes rage and the rage becomes something else entirely.
<!--@end-->


#### **leave_quietly** — *grey*

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.leave_quietly.text -->
Leave quietly
<!--@end-->


*Outcome*

`karma: animal+2`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.leave_quietly.outcome.text -->
You back away without disturbing her. She doesn't notice you leave. She was somewhere else already.
<!--@end-->


#### **wake_up** — *yellow* — requires yoga 3, roll charm vs difficult

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.wake_up.text -->
Try to wake her from the dream entirely
<!--@end-->


*Outcome — success*

`karma: god+10  ·  xp: 25`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.wake_up.outcome_success.text -->
"If there is no child, how can there be a mother?" She looks at you with sudden, piercing clarity. Her eyes sharpen. Then, very slowly, the clarity passes into something like peace. Her form grows transparent. She smiles — genuinely — and fades. She is not here anymore.
<!--@end-->


*Outcome — failure*

`karma: god+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_desperate_mother | choices.wake_up.outcome_failure.text -->
She looks through you and resumes rocking, babbling softly to the empty rags. The dream is too strong.
<!--@end-->


---

## hg_mercenary_lodge

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | title -->
Undertakers' Lodge
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | text -->
A squat building of stacked bones, its door marked with crossed shovels. Inside, undead mercenaries sit sharpening weapons and arguing about pay rates with the vigor of the professionally disgruntled. A notice board covers one wall, bristling with jobs and wanted notices.
<!--@end-->


### Choices


#### **enter_lodge** — *grey*

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.enter_lodge.text -->
Enter and look for work
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_mercenary_guild  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.enter_lodge.outcome.text -->

<!--@end-->


#### **notice_board** — *grey*

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.notice_board.text -->
Check the notice board
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.notice_board.outcome.text -->
Wanted: rolang herders to redirect a mob from the eastern fields. Reward posted by the Skeleton King's chamberlain. Two other notices offer bounties on a rogue dré that's been impersonating officials. The third is just a skeleton complaining about a debt.
<!--@end-->


#### **spar** — *yellow* — requires roll strength vs normal

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.spar.text -->
Challenge a mercenary to a practice spar
<!--@end-->


*Outcome — success*

`karma: asura+2, human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.spar.outcome_success.text -->
You hold your own — better than hold your own. The watching mercenaries go quiet in a way that means something. The sparring partner extends a hand. "Not bad for a warmie. We'll call it a draw."
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.spar.outcome_failure.text -->
You lose solidly. The mercenary is professional about it. "Not bad. Keep practicing. Costs you a round though." You pay for drinks you cannot drink.
<!--@end-->


#### **unarmed_demo** — *blue* — requires unarmed 3

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.unarmed_demo.text -->
Demonstrate unarmed technique — get their attention
<!--@end-->


*Outcome*

`karma: asura+2, human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.unarmed_demo.outcome.text -->
You find a cleared space and run through a form — not showing off, just working. The lodge goes quiet in the particular way it gets when something unexpected is happening.

A mercenary with no visible weapons walks over and watches carefully. 'Who trained you?' You talk for an hour. She introduces you to three people who turn out to be worth knowing.
<!--@end-->


#### **offer_services** — *blue* — requires might 3

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.offer_services.text -->
Offer your fighting services — take a contract
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: human+2  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.offer_services.outcome.text -->
The lodge master hands you a contract without ceremony. "Rolang infestation, two miles east. Standard terms." You go.
<!--@end-->


#### **entertain** — *yellow* — requires roll charm vs easy

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.entertain.text -->
Try to entertain the mercenaries — loosen them up
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: random  ·  karma: human+4`

<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.entertain.outcome_success.text -->
It takes a few minutes of material to break through the professional sullenness. Then one skeleton starts laughing. Then another. By the end, the lodge is rowdy and welcoming. One of the mercenaries pulls you aside afterward. "That was good. I could use a change of scene. You taking on crew?"
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_mercenary_lodge | choices.entertain.outcome_failure.text -->
"Do you think it's a circus, stranger? Do your business or leave before I lose patience." The lodge master points at the door. You can still browse, but everything is priced 25% higher.
<!--@end-->


---

## hg_poison_bog

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_poison_bog | title -->
The Poison Bog
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_poison_bog | text -->
Green mist clings to the surface of a bubbling swamp, hanging low and still. The water hisses faintly where it touches exposed stone. The smell is thick enough to feel.
<!--@end-->


### Choices


#### **push_through** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.push_through.text -->
Move fast and hold your breath
<!--@end-->


*Outcome — success*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.push_through.outcome_success.text -->
You cross at a run, holding your breath until your lungs burn. On the far bank you spit twice and keep moving.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_poison_bog | choices.push_through.outcome_failure.text -->
The mist gets into you. By the time you reach the other side your hands are shaking and your vision has gone green at the edges.
<!--@end-->


#### **find_safe_path** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.find_safe_path.text -->
Look for a path above the mist line
<!--@end-->


*Outcome*

`xp: 7`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.find_safe_path.outcome.text -->
A raised ridge of firmer ground runs along the bog's western edge — not obvious, but there. You cross clean.
<!--@end-->


#### **neutralize** — *blue* — requires alchemy 3

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.neutralize.text -->
Neutralize the bog with alchemy
<!--@end-->


*Outcome*

`xp: 14  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.neutralize.outcome.text -->
You scatter reagents into the water upstream. The reaction takes ten minutes and smells worse before it smells better. But the mist clears, and the exposed bog yields unusual materials.
<!--@end-->


#### **air_magic** — *blue* — requires air_magic 3

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.air_magic.text -->
Disperse the mist with air magic
<!--@end-->


*Outcome*

`xp: 10`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.air_magic.outcome.text -->
You push a wind through the bog. The mist tears and scatters. A clean path opens.
<!--@end-->


#### **iron_stomach_holds** — *blue* — requires **trait: iron_stomach**  **NEW**

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.iron_stomach_holds.text -->
Green mist. You have kept worse down than this.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.iron_stomach_holds.outcome.text -->
Everyone else is retching before the halfway point and you are not, which means you are the one still capable of pulling people forward.

It is not a heroic contribution. It is the whole crossing, as it turns out.
<!--@end-->


#### **sealed_armor** — *blue* — requires armor 3

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.sealed_armor.text -->
Seal your joints against the mist before crossing
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hungry_ghost_events.json | hg_poison_bog | choices.sealed_armor.outcome.text -->
You know exactly where the mist gets in — the seams, the collar gap, the wrist joints. You seal them all before you step off solid ground. The crossing is still unpleasant but the mist finds no purchase. You arrive on the far bank clean.
<!--@end-->


---

## hg_town_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_town_event | title -->
Crossbone Town
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_town_event | text -->
A settlement of the dead — bone-walled buildings, skeleton merchants, ghostly lanterns in permanent vigil. It functions. That's the remarkable thing. Guards at the gate eye you without hostility. "Weapons peace inside the walls. Break it and we break you, warmie."
<!--@end-->


### Choices


#### **weapons_shop** — *grey*

<!--@ hungry_ghost_events.json | hg_town_event | choices.weapons_shop.text -->
Visit the armorer
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_weapons  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_town_event | choices.weapons_shop.outcome.text -->

<!--@end-->


#### **shrine** — *grey*

<!--@ hungry_ghost_events.json | hg_town_event | choices.shrine.text -->
Visit the local shrine
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_magic  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_town_event | choices.shrine.outcome.text -->

<!--@end-->


#### **supplies** — *grey*

<!--@ hungry_ghost_events.json | hg_town_event | choices.supplies.text -->
Buy supplies
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_supplies  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_town_event | choices.supplies.outcome.text -->

<!--@end-->


#### **look_for_work** — *grey*

<!--@ hungry_ghost_events.json | hg_town_event | choices.look_for_work.text -->
Look for odd jobs
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 5  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_town_event | choices.look_for_work.outcome.text -->
You spend a few hours moving crates for a bone merchant, delivering a message for a skeleton official who turns out to be three levels underground, and locating a mislaid femur for a very upset skeleton. You are paid in coin and the particular satisfaction of a task well done.
<!--@end-->


#### **sing_in_marketplace** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_town_event | choices.sing_in_marketplace.text -->
Sing in the marketplace
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 6  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_town_event | choices.sing_in_marketplace.outcome.text -->
The dead gather slowly at first, then in numbers. They stand very still in the way that means they are listening hard. When you finish, coins appear on the ground before you — more than you expected. A skeleton merchant nearby leans over: "Come back. You're good for business."
<!--@end-->


#### **teach_impermanence** — *yellow* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_town_event | choices.teach_impermanence.text -->
Set up at the shrine and teach about impermanence
<!--@end-->


*Outcome — success*

`karma: god+6, human+3  ·  xp: 10  ·  gold: small  ·  items: ['health_potion']`

<!--@ hungry_ghost_events.json | hg_town_event | choices.teach_impermanence.outcome_success.text -->
The locals circle slowly, then stop. A crowd of skulls tips attentively as you speak. These beings know more about impermanence than most — and something in your framing reaches them. Offerings appear when you finish: food, a small pouch of coin, a health potion pressed into your hands by a skeleton with no face left to show its expression.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_town_event | choices.teach_impermanence.outcome_failure.text -->
Nobody likes an uninvited preacher. The locals glance at you, then go back to their business. A skeleton child — or at least, a small skeleton — throws a pebble at you. You pack up.
<!--@end-->


---

## hg_ancient_battlefield

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | title -->
The Ancient Battlefield
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | text -->
Weapons jut from the earth like iron flowers — spears, swords, shafts of arrows, all corroded past use but too numerous to count. The ground is more bone than dirt. Some of the fallen still twitch between the weapons, trapped between death and something worse, unable to move on.
<!--@end-->


### Choices


#### **scavenge** — *grey*

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.scavenge.text -->
Search the field for salvageable equipment
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bone_pack  ·  difficulty: normal  ·  karma: hungry_ghost+3  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.scavenge.outcome.text -->
You find something worth taking — and something finds you.
<!--@end-->


#### **put_to_rest** — *blue* — requires white_magic 2

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.put_to_rest.text -->
Consecrate the field and put the fallen to rest
<!--@end-->


*Outcome*

`karma: god+7, human+3  ·  xp: 15`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.put_to_rest.outcome.text -->
You walk the length of the field, speaking the words, touching each fallen fighter with blessing. The twitching slows. Stills. The field goes quiet for the first time since before either of your lifetimes.
<!--@end-->


#### **raise_reinforcements** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.raise_reinforcements.text -->
Raise some of the fallen to fight beside you
<!--@end-->


*Outcome*

`karma: asura+4  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.raise_reinforcements.outcome.text -->
The words come up from somewhere old. Three fighters rise — ragged, half-formed, but battle-ready. They follow behind you with the patience of the dead, ready for the next fight.
<!--@end-->


#### **train** — *blue* — requires martial_arts 3

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.train.text -->
Train among the fallen
<!--@end-->


*Outcome*

`karma: asura+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.train.outcome.text -->
The field is a library of killing techniques if you know how to read it. You practice forms between the weapons for two hours, learning from the preserved evidence of old fighters.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.meditate.text -->
Meditate among the dead
<!--@end-->


*Outcome*

`karma: god+7  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.meditate.outcome.text -->
"The ocean of samsara is itself a battlefield. I vow to end the battle — first inside, and eventually everywhere." The field is very quiet. The twitching figures slow. You sit with them until you feel the weight of the vow settle into something real.
<!--@end-->


#### **war_hardened_reads_field** — *blue* — requires **trait: war_hardened**  **NEW**

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.war_hardened_reads_field.text -->
You can read what happened here from where you are standing.
<!--@end-->


*Outcome*

`xp: 15  ·  add_trait: war_hardened`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.war_hardened_reads_field.outcome.text -->
A line held, then folded from the left. The reserve went in late and went in wrong. Everything after that was arithmetic.

You walk the field explaining it to nobody in particular, and the party is very quiet, and at the end of it you are more of a veteran than you were that morning.
<!--@end-->


#### **sharp_eyed_spots** — *blue* — requires **trait: sharp_eyed**  **NEW**

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.sharp_eyed_spots.text -->
Something in that jumble is not corroded.
<!--@end-->


*Outcome*

`xp: 15  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.sharp_eyed_spots.outcome.text -->
Nothing here should have survived. One thing has, under a shield that fell the right way up, and it is in the condition it was in on the day.
<!--@end-->


#### **survey_armor** — *blue* — requires armor 3

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.survey_armor.text -->
Survey the fallen armor — read who these were
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_ancient_battlefield | choices.survey_armor.outcome.text -->
You walk the field reading armor the way others read books — construction methods, battle damage, repairs, the wear patterns of years of use. Three factions, at minimum, all fighting each other. The oldest armor is local; the other two came from somewhere else.

One piece near the center shows signs of combat on all sides simultaneously. Whoever wore it died surrounded — held their ground far longer than the math suggested was possible.
<!--@end-->


---

## hg_vetala_trickster

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_trickster | title -->
The Trickster
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_trickster | text -->
"Thank the gods, another living soul! This place is absolutely horrible! I've been lost for days — do you know the way to the eastern road?"

The smile is wrong. Too many teeth. Held a fraction too long.
<!--@end-->


### Choices


#### **see_through** — *blue* — requires awareness 15

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.see_through.text -->
Call it out directly
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 12  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.see_through.outcome.text -->
"You're a vetala." A pause. Then it laughs — genuine, delighted, not the performance from before. "Oh, finally. You have no idea how boring this is when no one notices." It drops the pretense entirely and offers you a trade. Something real, as a reward for paying attention.
<!--@end-->


#### **play_along** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.play_along.text -->
Help the poor lost traveler
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_pack  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.play_along.outcome.text -->
It leads you cheerfully around a corner, down a path, through a narrow gap — and straight into three of its friends. The smile is back. "I DID say thank the gods."
<!--@end-->


#### **fight_directly** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.fight_directly.text -->
Challenge it directly — no games
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_scout  ·  difficulty: normal  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.fight_directly.outcome.text -->

<!--@end-->


#### **out_trick** — *yellow* — requires roll guile vs normal

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.out_trick.text -->
Play along — and out-trick it
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.out_trick.outcome_success.text -->
You match its performance beat for beat, leading it along a route that ends with its own ambush companions confused and its stash located and emptied. It stares at you. "I... you..." A long pause. "I respect that enormously."
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: vetala_pack  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.out_trick.outcome_failure.text -->
Your counter-play is good but not quite good enough. The smile widens into something real and dangerous.
<!--@end-->


#### **comedy** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.comedy.text -->
Turn the whole thing into a bit
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 12  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_trickster | choices.comedy.outcome.text -->
You compliment it extensively on its meatsuit. You ask about the tailor. You admire the not-quite-living-flesh color — very fashionable this season. You wonder aloud if it ever gets the seams adjusted.

The vetala laughs until it has to sit down. When it recovers, it presses a ring into your hand. "That's the funniest thing I've been subjected to in forty years. You're terrible. Here."
<!--@end-->


---

## hg_drowned_temple

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_drowned_temple | title -->
The Drowned Temple
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_drowned_temple | text -->
Half-sunken in the black swamp, a temple's upper spire still rises above the waterline. Faded murals of bodhisattvas peer out from beneath the surface, their serene faces distorted by the water. From inside comes a sound that should not survive in this realm: the turning of a prayer wheel, still spinning after all this time.
<!--@end-->


### Choices


#### **swim_inside** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.swim_inside.text -->
Swim inside
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 10  ·  items: ['spell_random_white']`

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.swim_inside.outcome_success.text -->
You find a chamber still half above water. The prayer wheel turns in a current you cannot feel. The murals inside are extraordinary — preserved perfectly by the dark water. You study them until you understand something new.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bog_zombie  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.swim_inside.outcome_failure.text -->
In the tight darkness under the water, something cold wraps around your arm.
<!--@end-->


#### **pray_outside** — *grey*

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.pray_outside.text -->
Pray from the bank — don't enter
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.pray_outside.outcome.text -->
You kneel in the grey mud and offer what you have. The prayer wheel turns inside its sunken room. Somehow, in this realm, the gesture feels heard.
<!--@end-->


#### **water_magic** — *blue* — requires water_magic 3

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.water_magic.text -->
Part the waters and enter dry
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 16  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.water_magic.outcome.text -->
The water pulls back. The temple mouth opens before you, still and reverent. Inside, the murals are perfect — the water preserved them. The offerings are intact. You spend a proper hour within, taking what is offered and leaving what is owed.
<!--@end-->


#### **salvage** — *blue* — requires smithing 2

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.salvage.text -->
Salvage building materials from the accessible sections
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 5  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_drowned_temple | choices.salvage.outcome.text -->
The upper stonework is solid — old construction, well-made. You extract what you can carry without disturbing the structure below the waterline.
<!--@end-->


---

## hg_skeleton_patrol

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | title -->
Bone Patrol
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | text -->
Four skeletons in mismatched armor march in tight formation down a grey road. Their sergeant — distinguishable only by a dented helmet someone has polished to a painful shine — holds up a bony hand. "Halt. State your business in the King's domain."
<!--@end-->


### Choices


#### **state_business** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.state_business.text -->
State your business honestly
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 2`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.state_business.outcome.text -->
"Traveler. Moving through." The sergeant looks you up and down. Nods. "Move through, then. Stay on the road." The patrol resumes its march.
<!--@end-->


#### **claim_emissary** — *yellow* — requires roll charm vs easy

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.claim_emissary.text -->
Claim to be a royal emissary
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.claim_emissary.outcome_success.text -->
You speak with sufficient authority and sufficient vagueness. The sergeant salutes. "Very well. The King's emissaries have right of passage." You are escorted, somewhat against your will, all the way to the next waypoint.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_patrol  ·  difficulty: normal  ·  karma: asura+2`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.claim_emissary.outcome_failure.text -->
The sergeant's empty sockets narrow. "We have no record of any emissary today. Seize them."
<!--@end-->


#### **trade_pass** — *blue* — requires trade 3

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.trade_pass.text -->
Show your trader's credentials
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.trade_pass.outcome.text -->
Merchants of standing move freely in the Skeleton King's domain. The sergeant examines your credentials with unexpected care, nods, and waves you on. "Nearest market town is north. The road is clear today."
<!--@end-->


#### **yogic_riddle** — *yellow* — requires yoga 3, roll charm vs normal

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.yogic_riddle.text -->
"Who truly knows their business in this world of dreams?"
<!--@end-->


*Outcome — success*

`karma: human+4  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.yogic_riddle.outcome_success.text -->
The sergeant goes still. The others exchange glances. A long pause. "Go on your way, yogi." They step aside.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_patrol  ·  difficulty: normal  ·  karma: asura+2`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.yogic_riddle.outcome_failure.text -->
"Don't try messing with my head, stranger."
<!--@end-->


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.fight.text -->
Attack the patrol
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_patrol  ·  difficulty: normal  ·  karma: asura+4`

<!--@ hungry_ghost_events.json | hg_skeleton_patrol | choices.fight.outcome.text -->

<!--@end-->


---

## hg_forgotten_shrine

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | title -->
Forgotten Shrine
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | text -->
A small roadside shrine, half-buried in grey dust. The offering bowl is empty. The carved face of the deity has worn smooth — you cannot tell who it once depicted. It could be anyone. It could be no one.
<!--@end-->


### Choices


#### **leave_offering** — *grey*

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.leave_offering.text -->
Leave an offering
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.leave_offering.outcome.text -->
You place coins in the bowl and press your palms together. Whoever this was, someone carved this stone and set it here. That deserves acknowledgment.
<!--@end-->


#### **restore** — *blue* — requires smithing 2

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.restore.text -->
Restore the shrine properly
<!--@end-->


*Outcome*

`karma: god+8, human+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.restore.outcome.text -->
You re-level the base, clear the dust from the carvings, and shore up the crumbling back. You can't recover the face, but the structure stands again with purpose. Someone will see it.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.meditate.text -->
Meditate before it
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.meditate.outcome.text -->
You settle into stillness and the shrine's history comes in fragments. Among them: a vision of the bodhisattva once depicted here — the one whose name means Womb of the Earth, who comes to this bleak realm to patiently teach and feed the ever-hungry dead. The face that has worn away is still present somehow.
<!--@end-->


#### **pilgrim_restores** — *blue* — requires **trait: pilgrim**  **NEW**

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.pilgrim_restores.text -->
Half-buried is not the same as finished.
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 20  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.pilgrim_restores.outcome.text -->
You dig it out. It takes an hour and ruins a pair of gloves and reveals that the offering bowl is not empty — it was buried full, which means somebody left in a hurry and meant to come back.
<!--@end-->


#### **take_bowl** — *grey*

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.take_bowl.text -->
Take the offering bowl — it's well-made
<!--@end-->


*Outcome*

`karma: hungry_ghost+4  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_forgotten_shrine | choices.take_bowl.outcome.text -->
Finely carved stone, old work. It fits in your pack. The shrine looks wrong without it.
<!--@end-->


---

## hg_rolang_horde

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_rolang_horde | title -->
The Horde
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_rolang_horde | text -->
The ground trembles. Over the ridge, a mass of rolangs shuffles forward — dozens, maybe hundreds. Not aggressive, just moving. A tide of the mindless dead flowing toward something far away, unfortunately seemingly unaware of a village lying directly in their path.
<!--@end-->


### Choices


#### **get_out** — *grey*

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.get_out.text -->
Get out of the way and let them pass
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.get_out.outcome.text -->
You press yourself against a rock wall and wait. The tide takes ten minutes to pass. The village on the far side of the hill has no idea what's coming.
<!--@end-->


#### **redirect** — *blue* — requires leadership 3

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.redirect.text -->
Herd them away from the village
<!--@end-->


*Outcome*

`karma: human+5, god+4  ·  xp: 20`

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.redirect.outcome.text -->
You work the edges of the horde, using presence and sound to nudge the direction of hundreds of shuffling dead. It takes an hour and every ounce of focus you have. But the horde turns, flowing away from the village and into empty wasteland.
<!--@end-->


#### **stand_ground** — *grey*

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.stand_ground.text -->
Stand your ground
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: hard  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.stand_ground.outcome.text -->

<!--@end-->


#### **guide_with_reach** — *blue* — requires spears 3

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.guide_with_reach.text -->
Guide the horde with your spear — use reach to steer them
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.guide_with_reach.outcome.text -->
You work the edges of the horde with your spear horizontal, using reach and presence to deflect the outermost rolangs. The mindless dead respond to obstacle and pressure — they don't fight back, they just redirect. Your leverage at the flank shifts the whole column gradually, like guiding a slow river.

It takes two hours and the spear gets heavy. But the horde turns, and the village is no longer in its path.
<!--@end-->


#### **follow** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.follow.text -->
Follow them — see where they're going
<!--@end-->


*Outcome*

`xp: 18`

<!--@ hungry_ghost_events.json | hg_rolang_horde | choices.follow.outcome.text -->
You trail them at a distance. Hours pass. They converge on a vast pit, an old mass grave, and begin to circle it in an endless loop. Something in the earth is pulling them home. You watch for a long time, learning more about this realm than you wanted to know.
<!--@end-->


---

## hg_alchemist_camp

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_alchemist_camp | title -->
The Alchemist
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_alchemist_camp | text -->
A dré — a bodiless ghost inhabiting a suit of robes stuffed with dried herbs — floats above a bubbling cauldron. Jars of questionable substances line makeshift shelves carved from bone. It turns as you approach.

"Customer or ingredient?" it asks cheerfully.
<!--@end-->


### Choices


#### **buy_potions** — *grey*

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.buy_potions.text -->
Browse what it has for sale
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_alchemist  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.buy_potions.outcome.text -->

<!--@end-->


#### **assist** — *blue* — requires alchemy 3

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.assist.text -->
Offer to help with the brewing
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 12  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.assist.outcome.text -->
The dré is delighted to have a competent hand. You work together for an hour over the cauldron, and what emerges is something neither of you could have made alone.
<!--@end-->


#### **ask_contents** — *blue* — requires medicine 2

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.ask_contents.text -->
Ask what's in the cauldron
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.ask_contents.outcome.text -->
The ingredients are unusual — some things that work differently in this realm than in the living world. The dré explains patiently, and you come away with a recipe that shouldn't work but does.
<!--@end-->


#### **knock_over** — *grey*

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.knock_over.text -->
Knock the cauldron over
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: charnel_wraith  ·  difficulty: normal  ·  karma: asura+4`

<!--@ hungry_ghost_events.json | hg_alchemist_camp | choices.knock_over.outcome.text -->
The cauldron hits the ground with a sound like a scream. The dré's cheerful demeanor evaporates instantly.
<!--@end-->


---

## hg_bone_arena_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_arena_event | title -->
The Bone Pit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_arena_event | text -->
A circular pit ringed with skull-topped posts. Skeletons sit in the stands, clicking their jaws in anticipation. A skeleton announcer with an elaborate wig of woven hair calls out over the crowd: "Fresh meat! Who wants to test the newcomer?"
<!--@end-->


### Choices


#### **accept** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.accept.text -->
Step into the pit
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warrior  ·  difficulty: normal  ·  karma: asura+2  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.accept.outcome.text -->
The crowd clacks with approval.
<!--@end-->


#### **bet** — *yellow* — requires roll luck vs normal

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.bet.text -->
Bet on a fight instead
<!--@end-->


*Outcome — success*

`gold: moderate`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.bet.outcome_success.text -->
The underdog wins in a way no one predicted. You collect double.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.bet.outcome_failure.text -->
The favorite wins. Of course it does.
<!--@end-->


#### **fight_champion** — *blue* — requires strength 15

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.fight_champion.text -->
Demand to fight the champion directly
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: hard  ·  karma: asura+3  ·  xp: 18  ·  gold: large  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.fight_champion.outcome.text -->
The announcer's wig falls off from excitement. The crowd goes silent.
<!--@end-->


#### **work_crowd** — *yellow* — requires roll performance vs normal

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.work_crowd.text -->
Work the crowd as an entertainer instead
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 8  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.work_crowd.outcome_success.text -->
You become the entertainment. The skeletons appreciate variety. Tips rain down from the stands — mostly coins, occasionally something that used to be a coin.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.work_crowd.outcome_failure.text -->
Booing. A rib bone bounces off your head. The announcer wags a finger: "Not what they came for, friend."
<!--@end-->


#### **gambler_finds_odds** — *blue* — requires **trait: gambler**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.gambler_finds_odds.text -->
There is money moving in those tiers.
<!--@end-->


*Outcome*

`xp: 15  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.gambler_finds_odds.outcome.text -->
There is, and the odds are being set by someone who has not watched the third fighter closely enough.

You have. You bet accordingly and collect with a straight face.
<!--@end-->


#### **duelist_steps_down** — *blue* — requires **trait: duelist**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.duelist_steps_down.text -->
You are not going to sit in the tiers.
<!--@end-->


*Outcome*

`xp: 30  ·  gold: small  ·  hp_loss: {'amount': 'light', 'target': 'random'}`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.duelist_steps_down.outcome.text -->
You were never going to sit in the tiers. You are over the rail before the current bout has finished and the crowd's noise changes shape.

It is close. You win it, barely, and the barely is what they will remember.
<!--@end-->


#### **archery_contest** — *blue* — requires ranged 3

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.archery_contest.text -->
Propose an archery contest as an alternative spectacle
<!--@end-->


*Outcome*

`karma: human+3, asura+1  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_bone_arena_event | choices.archery_contest.outcome.text -->
The announcer considers with a long click of its jaw. 'Unusual. We have never done that.' A pause. 'We will try it.'

Targets are assembled from spare ribs and skulls with remarkable speed. The contest draws a crowd intrigued by novelty. You hit every target cleanly. The skeletons are not sure if they like this more or less than combat — but they are watching.

The gold reflects the attendance.
<!--@end-->


---

## hg_ghost_light

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_ghost_light | title -->
Ghost Lights
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_ghost_light | text -->
Pale blue flames dance above the swamp surface, drifting slowly deeper into the mire. They're beautiful, and clearly a trap. Yet they seem to be leading somewhere specific, with unusual purpose.
<!--@end-->


### Choices


#### **follow** — *yellow* — requires roll awareness vs normal

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.follow.text -->
Follow them carefully
<!--@end-->


*Outcome — success*

`xp: 6  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.follow.outcome_success.text -->
The lights lead you on a winding path through the mire and stop above a half-sunken object — a cache, wrapped in oilcloth, wedged between the roots of a dead tree.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_ghost_light | choices.follow.outcome_failure.text -->
The lights lead you off solid ground. You sink to your waist in mire before managing to haul yourself free, filthy, somewhat injured, and deeply unimpressed.
<!--@end-->


#### **ignore** — *grey*

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.ignore.text -->
Ignore them and walk on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_ghost_light | choices.ignore.outcome.text -->
You watch them drift away into the dark. Wise, probably.
<!--@end-->


#### **fire_magic** — *blue* — requires fire_magic 2

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.fire_magic.text -->
Speak to them through fire
<!--@end-->


*Outcome*

`karma: god+4, human+2  ·  xp: 10  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.fire_magic.outcome.text -->
The lights pause, then pulse in response. They're souls, not traps — trapped here by the same forces that trap all things in this realm. They show you a safe path through the mire in gratitude for being seen.
<!--@end-->


#### **extinguish** — *blue* — requires water_magic 2

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.extinguish.text -->
Extinguish the lights — free them
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_ghost_light | choices.extinguish.outcome.text -->
You reach out with the spell and the lights go out one by one. Not dramatically — gently, like candles at the end of a long evening. Whatever they were, they are done now.
<!--@end-->


---

## hg_veterans_camp_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | title -->
The Old Guard
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | text -->
A fortified camp — real fortifications, not the improvised sort. These undead soldiers maintain discipline, run drills, keep watch rotations. A grizzled skeleton missing half its ribcage sits by the fire cleaning a weapon it will probably never use again.

"We remember what we were. That's more than most here can say."
<!--@end-->


### Choices


#### **enter_camp** — *grey*

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.enter_camp.text -->
Enter the camp
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_veterans_camp  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.enter_camp.outcome.text -->

<!--@end-->


#### **training** — *blue* — requires swords 3, axes 3, maces 3

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.training.text -->
Ask for a sparring session
<!--@end-->


*Outcome*

`karma: asura+2, human+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.training.outcome.text -->
They train you the way they trained soldiers — without ceremony, without encouragement, with complete focus. You come out of it tired and considerably more capable.
<!--@end-->


#### **share_news** — *grey*

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.share_news.text -->
Share news from the living world
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.share_news.outcome.text -->
They gather around you. You tell them about roads and cities and the way the light looks in the morning. They listen with the complete attention of beings who have been starved of new information for a very long time.
<!--@end-->


#### **challenge_fighter** — *yellow* — requires roll strength vs normal

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.challenge_fighter.text -->
Challenge their best fighter
<!--@end-->


*Outcome — success*

`karma: asura+3, human+2  ·  xp: 16  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.challenge_fighter.outcome_success.text -->
You win. Narrowly. The grizzled skeleton nods once — the highest praise available in this camp — and hands you a weapon from its own collection.
<!--@end-->


*Outcome — failure*

`karma: human+3  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.challenge_fighter.outcome_failure.text -->
You lose solidly. The camp watches in respectful silence. The grizzled skeleton helps you up. "Come back when you're ready."
<!--@end-->


#### **command_assertion** — *blue* — requires leadership 3

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.command_assertion.text -->
Assert field command — suggest a redeployment
<!--@end-->


*Outcome*

`karma: asura+2, human+4  ·  xp: 16  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_veterans_camp_event | choices.command_assertion.outcome.text -->
You study the camp's layout and defensive positioning before saying anything. Then you lay out a redeployment — one that accounts for the patterns you've observed in this realm, the cover the terrain offers, the direction of the usual threats.

The grizzled skeleton is quiet for a long time.

'Show me on the map.'

You work together for an hour. Their defensive position improves considerably. They give you something from the supply cache in recognition — not payment, but acknowledgment.
<!--@end-->


---

## hg_crying_river

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_crying_river | title -->
The River of Tears
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_crying_river | text -->
A river of black water flows silently through the wasteland. The surface ripples with faces — the crying dead, trapped in the current. A ferryman waits on the bank, pole in hand. He is enormous. He is silent. He has been waiting here for a very long time.
<!--@end-->


### Choices


#### **pay_passage** — *grey*

<!--@ hungry_ghost_events.json | hg_crying_river | choices.pay_passage.text -->
Pay for passage
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_crying_river | choices.pay_passage.outcome.text -->
The ferryman accepts without looking at you and poles across in silence. The faces in the water follow your progress with eyes that remember hope.
<!--@end-->


#### **swim** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_crying_river | choices.swim.text -->
Swim across — save the gold
<!--@end-->


*Outcome — success*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_crying_river | choices.swim.outcome_success.text -->
The current is strong and the water thick. You make it across with teeth clenched and nothing left.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_crying_river | choices.swim.outcome_failure.text -->
The faces pull at you, curious or desperate. You go under twice before the current spits you out downstream, bruised and shaking.
<!--@end-->


#### **speak_faces** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_crying_river | choices.speak_faces.text -->
Speak to the faces in the water
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 16  ·  add_trait: grief_struck`

<!--@ hungry_ghost_events.json | hg_crying_river | choices.speak_faces.outcome.text -->
You reach into the current with dark working and the faces turn toward you, speaking in voices like water over stone. They tell you things about this realm that aren't written anywhere. The lore is old and the weight of it stays with you.
<!--@end-->


#### **melancholic_listens** — *blue* — requires **trait: melancholic**  **NEW**

<!--@ hungry_ghost_events.json | hg_crying_river | choices.melancholic_listens.text -->
You have heard this note before, from the inside.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: water+8`

<!--@ hungry_ghost_events.json | hg_crying_river | choices.melancholic_listens.outcome.text -->
The faces are not saying anything. That is what everyone gets wrong — they assume the sound is speech.

It is not. You know exactly what it is, and you sit on the bank with it for a while, and the ferryman waits without complaint, because he has seen this before too.
<!--@end-->


#### **help_ferryman** — *blue* — requires might 3

<!--@ hungry_ghost_events.json | hg_crying_river | choices.help_ferryman.text -->
Offer to help pole the raft
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_crying_river | choices.help_ferryman.outcome.text -->
The ferryman looks at you for the first time — properly looks, as if assessing something. Then steps aside and hands you the pole. You work in silence side by side. When you reach the far bank, he nods once. You have the sense this will be remembered.
<!--@end-->


---

## hg_gyelpo_court

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_gyelpo_court | title -->
The Sorcerer's Court
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_gyelpo_court | text -->
A ruined palace, still grand in its decay. A gyelpo — a dead sorcerer of terrible power — holds court here, attended by bound spirits drifting in slow orbits. He turns as you enter without being told you'd arrived.

"I ruled then and I rule now. What makes you think I'd stop for something as trivial as dying?"
<!--@end-->


### Choices


#### **pay_respects** — *grey*

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.pay_respects.text -->
Pay your respects formally
<!--@end-->


*Outcome*

`karma: human+2`

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.pay_respects.outcome.text -->
The gyelpo is pleased by the form, if not the visitor. He waves a hand and the bound spirits clear a path. "You may pass. Tell no one what you saw here."
<!--@end-->


#### **request_audience** — *blue* — requires charm 14

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.request_audience.text -->
Request a formal audience
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 16  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.request_audience.outcome.text -->
He grants it. The negotiation takes time — he thinks in decades, not minutes — but eventually yields something valuable. A name, a technique, a piece of knowledge that should not have survived him.
<!--@end-->


#### **challenge** — *grey*

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.challenge.text -->
Challenge his authority
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: corpse_sorcerer  ·  difficulty: hard  ·  karma: asura+4`

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.challenge.outcome.text -->
The bound spirits stop their orbiting and turn inward.
<!--@end-->


#### **attractive_noticed** — *blue* — requires **trait: attractive**  **NEW**

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.attractive_noticed.text -->
The court notices you before you have said anything.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.attractive_noticed.outcome.text -->
It does, and the gyelpo — dead some centuries and still vain about his hall — decides that you improve the room.

You are seated well above where a traveller is seated, which is useful, and watched throughout, which is not.
<!--@end-->


#### **offer_knowledge** — *blue* — requires focus 15

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.offer_knowledge.text -->
Offer him magical knowledge in exchange
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 18  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_gyelpo_court | choices.offer_knowledge.outcome.text -->
He leans forward for the first time. What you offer genuinely interests him — not for its power but because it is new, and almost nothing is new to him anymore. He gives back more than you gave.
<!--@end-->


---

## hg_fungal_grove

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_fungal_grove | title -->
The Fungal Grove
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_fungal_grove | text -->
Enormous mushrooms grow from the bodies of the dead, some taller than trees. The air is thick with spores. There is a sound underneath the silence — soft, irregular, buzzing — and when you listen closely you seem to hear melodies within it. Call and response, echoing somewhere in the mycelium.
<!--@end-->


### Choices


#### **harvest** — *blue* — requires alchemy 2

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.harvest.text -->
Harvest the mushrooms carefully
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 8  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.harvest.outcome.text -->
Unusual reagents — things with properties you haven't seen in living-world fungi. This place grows something new.
<!--@end-->


#### **listen** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.listen.text -->
Stop and listen properly
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 20`

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.listen.outcome.text -->
You sit very still and let the sound find you. The fungi are sharing memories of the dead they grow from — and their own nature as something new, a collective being beyond ego and egolessness, not just the dead and not just the fungus, but an amalgam that has grown past both. Something in this troubles the assumptions you arrived with.
<!--@end-->


#### **push_through** — *yellow* — requires roll constitution vs easy

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.push_through.text -->
Move through quickly, hold your breath
<!--@end-->


*Outcome — success*


<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.push_through.outcome_success.text -->
You make it through without breathing more than necessary. The buzzing fades behind you.
<!--@end-->


*Outcome — failure*

`karma: animal+2`

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.push_through.outcome_failure.text -->
The spores get in. The world becomes very interesting for a while.
<!--@end-->


#### **burn** — *grey*

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.burn.text -->
Burn a path through
<!--@end-->


*Outcome*

`karma: hell+3  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_fungal_grove | choices.burn.outcome.text -->
The mushrooms burn poorly and smell terrible. You get through. The melodies stop.
<!--@end-->


---

## hg_dralha_warband

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_dralha_warband | title -->
The Dead King's Warband
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_dralha_warband | text -->
A dralha — an undead warrior-king — rides at the head of a column of skeleton soldiers. Banners of a forgotten kingdom snap in the memory of a wind that doesn't blow anymore. The dralha raises a gauntleted fist and the column halts.

"You. You have the look of a fighter."
<!--@end-->


### Choices


#### **accept_commission** — *grey*

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.accept_commission.text -->
Accept a commission
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: asura+3  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.accept_commission.outcome.text -->
"Against the rolang horde to the east. Standard terms." It pays.
<!--@end-->


#### **decline_politely** — *blue* — requires charm 13

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.decline_politely.text -->
Decline — without giving offense
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.decline_politely.outcome.text -->
"Different roads," you say. The dralha studies you for a moment, then lowers its fist. "Fair enough. Ride on."
<!--@end-->


#### **challenge_dralha** — *grey*

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.challenge_dralha.text -->
Challenge the dralha itself
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: very_hard  ·  karma: asura+4  ·  xp: 25  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.challenge_dralha.outcome.text -->
The column watches in absolute silence. This is going to be talked about.
<!--@end-->


#### **offer_intelligence** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.offer_intelligence.text -->
Offer tactical intelligence instead of service
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.offer_intelligence.outcome.text -->
You share what you know about the terrain ahead and the rolang movements you've observed. The dralha listens with the attention of someone who has fought a thousand battles and knows useful information when it hears it.
<!--@end-->


#### **peer_command** — *blue* — requires leadership 3

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.peer_command.text -->
Speak to it as a peer commander
<!--@end-->


*Outcome*

`karma: human+4, asura+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.peer_command.outcome.text -->
You don't ask permission and you don't defer — you address it the way one field commander addresses another, with the specific confidence of someone who has made the same decisions under worse conditions.

The dralha reads this immediately. Its posture shifts — not submission, but respect.

'Where are you headed?' You tell it. 'The southern route is safer. We cleared it two days ago.' It turns the column without further words.

You have, without planning to, just exchanged tactical intelligence with an undead warlord. Both parties leave better informed.
<!--@end-->


#### **infantry_presentation** — *blue* — requires spears 3

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.infantry_presentation.text -->
Fall in with the column — present yourself as infantry
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: easy  ·  karma: asura+3, human+1  ·  xp: 10  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_dralha_warband | choices.infantry_presentation.outcome.text -->
You fall in with the column, spear at the correct angle, march at the correct pace. The column incorporates you without ceremony. The brief engagement at the far side of the patrol route goes quickly with the warband behind you.
<!--@end-->


---

## hg_whispering_bones

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_whispering_bones | title -->
The Whispering Bones
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_whispering_bones | text -->
Scattered bones on the ground begin to whisper as you pass. Each one holds a fragment of memory — a name, a regret, a last wish. The whispers grow louder the longer you stay.
<!--@end-->


### Choices


#### **listen_patiently** — *grey*

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.listen_patiently.text -->
Sit and listen to all of them
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.listen_patiently.outcome.text -->
You sit for a long time. The stories come in fragments — none complete, all real. You learn the names of people no one else remembers.
<!--@end-->


#### **collect_bones** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.collect_bones.text -->
Perform a bone-gathering ceremony
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.collect_bones.outcome.text -->
The ceremony takes an hour. You arrange the bones with care, speak the names as you collect them, give the fragments the dignity they were denied. The whispering quiets into something that might be gratitude.
<!--@end-->


#### **block_out** — *yellow* — requires roll focus vs easy

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.block_out.text -->
Block out the sound and push through
<!--@end-->


*Outcome — success*


<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.block_out.outcome_success.text -->
You hold the silence inside yourself and walk through the noise. It doesn't touch you.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.block_out.outcome_failure.text -->
The whispers find the gaps in your concentration and settle in. Something heavy lingers in your mind.
<!--@end-->


#### **speak_names** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.speak_names.text -->
Speak their names aloud — give them voice
<!--@end-->


*Outcome*

`karma: god+3  ·  xp: 12  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.speak_names.outcome.text -->
As you speak each name, something answers. The bones whisper back differently — with direction, with purpose. There is something hidden nearby that they want you to find.
<!--@end-->


#### **summon_horror** — *yellow* — requires black_magic 3, roll focus vs normal

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.summon_horror.text -->
Call them back — all of them at once
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: iron_oath  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.summon_horror.outcome_success.text -->
The bones rise and coalesce — dozens of fragments assembling into something massive. It looks at you with eyes made of hollow sockets and memory. Then, slowly, it kneels.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bone_horror  ·  difficulty: hard  ·  karma: hell+3`

<!--@ hungry_ghost_events.json | hg_whispering_bones | choices.summon_horror.outcome_failure.text -->
The bones rise. But whatever you called, it is not taking orders.
<!--@end-->


---

## hg_charnel_sorcerer_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | title -->
The Charnel Sorcerer
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | text -->
In a cave hung with bones and dried entrails, a vetala sorcerer works rituals by the light of candles made from human fat. It turns at your footstep with an expression of genuine pleasure.

"I don't get many visitors. Most find the décor off-putting. Can't imagine why."
<!--@end-->


### Choices


#### **seek_training** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.seek_training.text -->
Browse what it has to offer
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_charnel_sorcerer  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.seek_training.outcome.text -->

<!--@end-->


#### **forbidden_knowledge** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.forbidden_knowledge.text -->
Ask about the advanced workings
<!--@end-->


*Outcome*

`karma: asura+2  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.forbidden_knowledge.outcome.text -->
It tells you things that are not in the books. Things about what persists after death, what can be moved and where, what the dead remember that the living cannot access. You come away changed.
<!--@end-->


#### **trade_components** — *blue* — requires alchemy 3

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.trade_components.text -->
Trade spell components
<!--@end-->


*Outcome*

`xp: 8  ·  items: ['item_random', 'item_random']`

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.trade_components.outcome.text -->
You lay out your reagents. It picks through them with practiced fingers, setting things aside, weighing others. What you receive in exchange is stranger and more potent.
<!--@end-->


#### **disrupt_ritual** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.disrupt_ritual.text -->
Disrupt the ritual — shut this down
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: corpse_sorcerer  ·  difficulty: very_hard  ·  karma: asura+4  ·  xp: 20`

<!--@ hungry_ghost_events.json | hg_charnel_sorcerer_event | choices.disrupt_ritual.outcome.text -->
The vetala's pleasant expression disappears. What's underneath is considerably less friendly.
<!--@end-->


---

## hg_lost_caravan

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_lost_caravan | title -->
The Lost Caravan
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_lost_caravan | text -->
Overturned carts and scattered goods. The caravan guards are dead — properly so. Something attacked them recently. Tracks lead into the swamp. The goods are still here, undisturbed by the local dead.
<!--@end-->


### Choices


#### **take_loot** — *grey*

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.take_loot.text -->
Take what you can carry
<!--@end-->


*Outcome*

`karma: hungry_ghost+4  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.take_loot.outcome.text -->
You work quickly, taking the most valuable things. The dead guards don't object.
<!--@end-->


#### **search_survivors** — *blue* — requires medicine 2

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.search_survivors.text -->
Search for survivors
<!--@end-->


*Outcome*

`karma: god+5, human+4  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.search_survivors.outcome.text -->
There — breathing, barely, under an overturned crate. The wound is serious but survivable if treated now. You work fast.
<!--@end-->


#### **track_attackers** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.track_attackers.text -->
Track whatever did this
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: carrion_flock  ·  difficulty: normal  ·  karma: asura+2  ·  xp: 10  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.track_attackers.outcome.text -->
The tracks are fresh. You follow them into the swamp and find the attackers still circling their kill.
<!--@end-->


#### **bury_dead** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.bury_dead.text -->
Bury the dead properly
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_lost_caravan | choices.bury_dead.outcome.text -->
You leave the goods untouched and dig. It takes time. When you finish, the site looks less like a disaster and more like a grave. You say what should be said.
<!--@end-->


---

## hg_mirror_pool

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mirror_pool | title -->
The Mirror Pool
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mirror_pool | text -->
A pool of perfectly still, perfectly clear water in the middle of the wasteland. Impossible here. It shows not your reflection but something else — a past life, a death, something that might be a future.
<!--@end-->


### Choices


#### **look_in** — *grey*

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.look_in.text -->
Look into the pool
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.look_in.outcome.text -->
The vision comes without asking for it. You see the realms ordered by what you've built — the highest first, the lowest last. No numbers. Just the weight of things.
<!--@end-->


#### **drink** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.drink.text -->
Drink from it
<!--@end-->


*Outcome — success*

`xp: 6  ·  add_trait: haunted`

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.drink.outcome_success.text -->
The water tastes like memory. Something sharpens in you.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.drink.outcome_failure.text -->
The visions come faster than you can process them. You sit by the pool for a long time before you can stand again.
<!--@end-->


#### **meditate** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.meditate.text -->
Meditate beside it
<!--@end-->


*Outcome*

`karma: god+7  ·  xp: 20  ·  add_trait: clear_eyed`

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.meditate.outcome.text -->
You sit with the visions rather than fighting them. The pool shows you the cycle — not as horror, but as mechanism. Something in the understanding frees a knot you didn't know was there.
<!--@end-->


#### **vain_looks_too_long** — *blue* — requires **trait: vain**  **NEW**

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.vain_looks_too_long.text -->
Of course you are going to look.
<!--@end-->


*Outcome*

`xp: 18  ·  pressure: earth-12`

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.vain_looks_too_long.outcome.text -->
You look. It shows you accurately, which is the cruelty of it — not distorted, not aged, simply seen from outside for the first time.

You are quiet for some hours afterwards and decline to say why.
<!--@end-->


#### **shatter** — *grey*

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.shatter.text -->
Shatter the surface
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost-2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_mirror_pool | choices.shatter.outcome.text -->
You throw a stone. The vision breaks into ripples. Something lifts. Something else wonders if you were ready to stop looking.
<!--@end-->


---

## hg_shaza_ambush

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_shaza_ambush | title -->
The Hunters
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_shaza_ambush | text -->
A shaza pack has been tracking you — body-snatching predators that crave living flesh above all else. You spot them circling at the same moment they realize you've noticed. The circling tightens.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.fight.text -->
Stand and fight
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: undead_convergence  ·  difficulty: normal  ·  karma: asura+2`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.fight.outcome.text -->

<!--@end-->


#### **set_trap** — *blue* — requires guile 3

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.set_trap.text -->
Lure them into a kill zone
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: undead_convergence  ·  difficulty: easy  ·  karma: asura+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.set_trap.outcome.text -->
You choose your ground carefully, then let them come to you on your terms.
<!--@end-->


#### **climb** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.climb.text -->
Get above them — high ground
<!--@end-->


*Outcome — success*

`xp: 6`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.climb.outcome_success.text -->
You scramble up a bone-pile before they close the distance. From up here you're outside their preferred engagement range. They mill about below, and eventually give up.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: undead_convergence  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.climb.outcome_failure.text -->
Not fast enough. They hit you from behind as you climb.
<!--@end-->


#### **play_dead** — *yellow* — requires roll guile vs normal

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.play_dead.text -->
Play dead
<!--@end-->


*Outcome — success*

`xp: 8  ·  add_trait: harrowed`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.play_dead.outcome_success.text -->
You go down convincingly and stay down. They sniff around you, confused. Their hunger is for living flesh — and yours, for the moment, doesn't smell like it. They drift on.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: undead_convergence  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.play_dead.outcome_failure.text -->
They're not fooled. And they go for you first because you're already on the ground.
<!--@end-->


#### **ventriloquism** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.ventriloquism.text -->
Confuse them with a quick act of ventriloquism
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.ventriloquism.outcome.text -->
You produce a small doll from your pack and throw your voice into it, sending the shaza into baffled circles trying to locate the sound. While they mill in confusion, you walk briskly in the other direction.
<!--@end-->


#### **pick_off** — *blue* — requires daggers 3

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.pick_off.text -->
Pick off the hunters as they close — surgical precision
<!--@end-->


*Outcome*

`karma: asura+3  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.pick_off.outcome.text -->
You wait for the lead shaza to enter knife range, drop it cleanly, and move through the pack targeting vital points. The rest of them scatter when they realize what's happening — they hunt in groups because they have to, and a group suddenly three smaller is no longer a group with confidence.

You walk on. The survivors do not follow.
<!--@end-->


#### **war_hardened_ready** — *blue* — requires **trait: war_hardened**  **NEW**

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.war_hardened_ready.text -->
You heard them a while ago. You have been waiting.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.war_hardened_ready.outcome.text -->
You picked it up two hundred paces back — not a sound, a shape of silence in the wrong place — and you have spent the walk since arranging where everyone is standing.

When it comes, it comes into a formation rather than a column.
<!--@end-->


#### **systematic_shooting** — *blue* — requires ranged 3

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.systematic_shooting.text -->
Keep them at range — shoot them down before they close
<!--@end-->


*Outcome*

`karma: asura+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_shaza_ambush | choices.systematic_shooting.outcome.text -->
You back up to maintain distance and start shooting — not panicked, but methodical, picking the ones moving to flank first. The shaza are confident close-in hunters and terrible at range. You stay outside their distance and well within yours. They figure this out on the third volley and decide you are not worth the cost.
<!--@end-->


---

## hg_singing_skull

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_singing_skull | title -->
The Singing Skull
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_singing_skull | text -->
A skull sits atop a cairn of stones, humming a melody. When you approach, its jaw opens wider: "Oh! A listener! I used to be a bard, you know. Died mid-song. Very embarrassing. Would you like to hear how it ends?"
<!--@end-->


### Choices


#### **listen** — *grey*

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.listen.text -->
Listen to the song
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.listen.outcome.text -->
It's actually beautiful. The skull has had a long time to get the ending right. Something about the melody lingers with you long after you leave.
<!--@end-->


#### **sing_along** — *yellow* — requires roll performance vs normal

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.sing_along.text -->
Sing along
<!--@end-->


*Outcome — success*

`karma: human+4, god+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.sing_along.outcome_success.text -->
You find the harmony. The skull stops mid-phrase and stares. "Oh," it says softly. "Oh, that's exactly it. That's exactly what was missing." The duet locks together and the song completes. Something resonates.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.sing_along.outcome_failure.text -->
Off-key. The skull is politely disappointed but thanks you for trying. "Not everyone has it. That's what makes it special."
<!--@end-->


#### **ask_death** — *grey*

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.ask_death.text -->
Ask how it died
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.ask_death.outcome.text -->
"Mid-performance. Big crowd. I was just getting to the good bit." A pause. "I've had time to work out whether it was tragic or funny. I've decided it was both."
<!--@end-->


#### **storyteller_trades** — *blue* — requires **trait: storyteller**  **NEW**

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.storyteller_trades.text -->
It has a song. Trade it one.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.storyteller_trades.outcome.text -->
You give it something long with a good middle, and it listens the whole way through without humming over you, which for a skull on a cairn is close to reverence.

What it gives back is not a song. It is directions, sung, and they are accurate.
<!--@end-->


#### **carry_to_audience** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.carry_to_audience.text -->
Offer to carry it to an audience
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 10  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_singing_skull | choices.carry_to_audience.outcome.text -->
The skull goes very still. Then: "You're serious." Then: "YES." It settles into your pack with enormous dignity, humming quietly. Its commentary on your journey turns out to be worth hearing.
<!--@end-->


---

## hg_mass_grave

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mass_grave | title -->
The Mass Grave
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mass_grave | text -->
The ground sinks under your feet. You realize you're standing on a mass burial site — hundreds, maybe thousands of dead from some forgotten catastrophe. The earth pulses with dark energy.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.leave.text -->
Leave immediately
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_mass_grave | choices.leave.outcome.text -->
Some places don't want to be investigated. You respect that.
<!--@end-->


#### **investigate** — *yellow* — requires roll awareness vs normal

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.investigate.text -->
Investigate carefully
<!--@end-->


*Outcome — success*

`xp: 8  ·  gold: moderate  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.investigate.outcome_success.text -->
You move slowly, reading the ground. There — a corner of something preserved, protected by the sheer density of death around it. Burial goods from someone important.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.investigate.outcome_failure.text -->
Your foot goes through the soil into something that moves. Then several things move.
<!--@end-->


#### **consecrate** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.consecrate.text -->
Consecrate the site
<!--@end-->


*Outcome*

`karma: god+10, human+4  ·  xp: 30  ·  add_trait: merciful`

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.consecrate.outcome.text -->
The undertaking takes everything you have. The pulse of dark energy fights you for an hour before it yields. When it's done, the ground is quiet for the first time since the catastrophe that filled it. This will matter to someone, somewhere, even if you never know who.
<!--@end-->


#### **grief_struck_kneels** — *blue* — requires **trait: grief_struck**  **NEW**

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.grief_struck_kneels.text -->
You are already carrying one. What is a thousand more.
<!--@end-->


*Outcome*

`karma: hungry_ghost-6  ·  xp: 20  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.grief_struck_kneels.outcome.text -->
It is not the same, and you know it is not the same, and you kneel anyway because the difference is not the point.

Something in the ground eases. Not much. The amount you would expect one person's attention to be worth.
<!--@end-->


#### **channel_energy** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.channel_energy.text -->
Channel the dark energy
<!--@end-->


*Outcome*

`karma: hungry_ghost+5  ·  xp: 18  ·  items: ['spell_random_black']  ·  add_trait: blood_handed`

<!--@ hungry_ghost_events.json | hg_mass_grave | choices.channel_energy.outcome.text -->
You open yourself to it and let it move through you. It is vast and old and full of a specific kind of knowledge. What you learn cannot be unlearned.
<!--@end-->


---

## hg_skeleton_king

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_skeleton_king | title -->
The Skeleton King of the Setting Sun
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_skeleton_king | text -->
A city of bone — towers of fused ribcages, walls of skulls, gates of pelvis and shoulder blade. On a throne of vertebrae sits the Skeleton King, crowned with a circlet of hammered copper. His eye sockets burn with cold intelligence. Rings of copper, gold, and ruby decorate his fingers and exposed ribs.

"All the dead pass through my kingdom eventually."
<!--@end-->


### Choices


#### **kneel_request** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.kneel_request.text -->
Kneel and request an audience
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: human+2  ·  xp: 12  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.kneel_request.outcome.text -->
He's amused. "Clear the infestation to the east and you may pass freely." Simple enough.
<!--@end-->


#### **challenge_authority** — *blue* — requires strength 16, charm 14

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.challenge_authority.text -->
Challenge his authority — formally
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_king_duel  ·  difficulty: boss  ·  karma: asura+4  ·  xp: 40  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.challenge_authority.outcome.text -->
He rises from his throne for the first time in years. The court goes absolutely still. "Then let us see." The battle ends when he reaches ten percent — he stops it himself. "Enough. You have proven your right."
<!--@end-->


#### **offer_knowledge** — *blue* — requires focus 16

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_knowledge.text -->
Offer him magical knowledge
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 20  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_knowledge.outcome.text -->
He listens with unexpected patience. What you offer is genuinely rare. He gives back something equally rare.
<!--@end-->


#### **bow_leave** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.bow_leave.text -->
Bow and take your leave
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.bow_leave.outcome.text -->
No shame in discretion. He watches you go with what might be respect.
<!--@end-->


#### **offer_song** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_song.text -->
Offer a song of praise in lieu of tribute
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 14  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_song.outcome.text -->
"I am a poor traveler. But I will offer my only treasure — my voice." He leans back. The court goes still. You sing. When it's over, he reaches into his robes and extends a trinket and a small purse. "An unusual currency. But acceptable."
<!--@end-->


#### **offer_puja** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_puja.text -->
Offer a puja in his honor
<!--@end-->


*Outcome*

`karma: human+3, god+3  ·  xp: 16  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_skeleton_king | choices.offer_puja.outcome.text -->
You set up the offering with care — the correct order, the correct words, nothing improvised. The Skeleton King watches every detail. When you finish, something in his bearing has shifted. He teaches you something from his own practice.
<!--@end-->


---

## hg_vetala_elder

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_elder | title -->
The Elder of the Charnel Grounds
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_elder | text -->
Deep in the charnel grounds, where the bone-fires burn highest, you find her — a vetala so old her skin has turned to parchment, her eyes like oil lamps. She sits on a throne of piled corpses, surrounded by offerings brought by lesser vetalas.

"I have eaten the memories of ten thousand dead. Ask me anything. And remember — everything has a price."
<!--@end-->


### Choices


#### **ask_death** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_death.text -->
Ask about the nature of death
<!--@end-->


*Outcome*

`karma: god+7  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_death.outcome.text -->
"Death is a trick of perception. There was never a separate, singular body that lived and then died. The minuscule creatures in your gut have not noticed any change." She pauses. "There was never a separate person. Nobody was born and nobody died."
<!--@end-->


#### **ask_world** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_world.text -->
Ask about the nature of the world
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_world.outcome.text -->
"All worlds are the same. They arise out of the potential of the void, driven by the expectations of sentient beings. Here, you see a world of thirst. A Buddha sees a garden ripe with possibility."
<!--@end-->


#### **ask_liberation** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_liberation.text -->
Ask about liberation
<!--@end-->


*Outcome*

`karma: god+7  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_liberation.outcome.text -->
She is quiet for a long time. Then: "Who will be liberated? From where? To where?" Another pause. "Keep dreaming, child. As long as you want."
<!--@end-->


#### **ask_power** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_power.text -->
Ask for power
<!--@end-->


*Outcome*

`karma: hungry_ghost+8`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.ask_power.outcome.text -->
She smiles for the first time. "Now that is the honest question." She names a price: something permanent, something significant, and something that will follow you across lives. Whether the exchange is worth it is entirely up to you.
<!--@end-->


#### **offer_memory** — *blue* — requires charm 15

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.offer_memory.text -->
Offer her a memory from the living world
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 20  ·  items: ['spell_random_black']`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.offer_memory.outcome.text -->
She goes still as you speak. Something behind the oil-lamp eyes flickers — surprise, perhaps, or something that was once longing. "I have not tasted a living memory in centuries." She gives you something in return that only she could give.
<!--@end-->


#### **attack** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.attack.text -->
Strike while her attention is elsewhere
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_elder_court  ·  difficulty: very_hard  ·  karma: hell+5, asura+4  ·  xp: 30  ·  gold: large  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_elder | choices.attack.outcome.text -->
She does not look up. "I wondered when you'd try that." The court rises.
<!--@end-->


---

## hg_golden_skeleton_sage

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | title -->
The Golden Sage
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | text -->
A skeleton of gleaming gold sits beneath a withered bodhi tree, radiating calm. Other skeletons give it a wide berth — not from fear, but from reverence. It does not speak first. It waits.

"You carry the weight of many lives. Would you like to set some of it down?"
<!--@end-->


### Choices


#### **accept_teaching** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.accept_teaching.text -->
Accept teaching
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 22  ·  add_trait: touched_by_grace`

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.accept_teaching.outcome.text -->
The teaching is brief and exact. It goes directly to something you have been carrying and shows you how you've been carrying it wrong.
<!--@end-->


#### **ask_golden** — *grey*

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.ask_golden.text -->
Ask about the golden skeletons
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.ask_golden.outcome.text -->
"Compassion doesn't disappear when the body does. It goes somewhere." It gestures at itself. "Here, apparently."
<!--@end-->


#### **request_healing** — *grey*

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.request_healing.text -->
Ask for healing
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.request_healing.outcome.text -->
It places a hand on you without ceremony. The damage recedes. The exhaustion behind it recedes too, which is rarer.
<!--@end-->


#### **ask_white_magic** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.ask_white_magic.text -->
Ask to learn healing magic
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 14  ·  items: ['spell_random_white']`

<!--@ hungry_ghost_events.json | hg_golden_skeleton_sage | choices.ask_white_magic.outcome.text -->
It teaches without preamble. What it shows you is not complex — simplicity is the whole point of it.
<!--@end-->


---

## hg_turquoise_dancers

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | title -->
The Turquoise Dancers
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | text -->
A troupe of turquoise skeletons in rainbow skirts and flower headdresses dances in a circle, rattling and clacking in joyful rhythm. They notice you and beckon.

"Dance with us! What is the use of worrying here?"
<!--@end-->


### Choices


#### **join_dance** — *yellow* — requires roll finesse vs easy

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.join_dance.text -->
Join the dance
<!--@end-->


*Outcome — success*

`karma: human+5  ·  xp: 14  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.join_dance.outcome_success.text -->
You find the rhythm and it carries you. When the song ends, a turquoise hand presses something into yours — a trinket worn smooth by dancing fingers.
<!--@end-->


*Outcome — failure*

`karma: human+4  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.join_dance.outcome_failure.text -->
You trip over your own feet. The dancers catch you, clacking with laughter. They dance around your embarrassment until it becomes part of the performance.
<!--@end-->


#### **play_music** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.play_music.text -->
Play music for them
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 16  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.play_music.outcome.text -->
The dance transforms around your music. Skeleton audience members appear from nowhere, clacking appreciatively. Coins rain down.
<!--@end-->


#### **ask_why** — *grey*

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.ask_why.text -->
Ask why they dance
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.ask_why.outcome.text -->
The nearest dancer stops and looks at you with an expression that somehow works without a face. "Why don't you?"
<!--@end-->


#### **politely_decline** — *grey*

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.politely_decline.text -->
Decline politely
<!--@end-->


*Outcome*

`karma: animal+1, human+2`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.politely_decline.outcome.text -->
They wave goodbye with genuine warmth. The music follows you for a while.
<!--@end-->


#### **celebrant_joins** — *blue* — requires **trait: celebrant**  **NEW**

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.celebrant_joins.text -->
They are enjoying themselves. Join in.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: air+15, fire+10`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.celebrant_joins.outcome.text -->
You are terrible at it. This turns out to be entirely beside the point — the troupe's delight is not in the standard of the dancing but in the fact of somebody dancing.

You come away with flowers in your hair and, for some hours, the inability to be gloomy about the hungry ghost realm.
<!--@end-->


#### **dance_and_play** — *blue* — requires comedy 2

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.dance_and_play.text -->
Join them fully — dance and make them laugh
<!--@end-->


*Outcome*

`karma: human+6  ·  xp: 18  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_turquoise_dancers | choices.dance_and_play.outcome.text -->
You throw yourself in completely — dancing, mugging, making art of your own clumsiness. The troupe loves every second of it. When you finally stop, breathless, they press a trinket into your hands with both skeletal fists.
<!--@end-->


---

## hg_iron_skeleton_duel

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | title -->
The Iron Challenger
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | text -->
An iron skeleton stands at a crossroads, sword driven into the ground before it. A sign reads: DEFEAT ME AND PASS. LOSE AND SERVE. It has clearly been here a very long time. The paint on the sign is old. The skeleton is patient.
<!--@end-->


### Choices


#### **accept_duel** — *grey*

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.accept_duel.text -->
Accept the duel
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: normal  ·  karma: asura+2  ·  xp: 12  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.accept_duel.outcome.text -->
It pulls the sword from the ground and takes its stance.
<!--@end-->


#### **outthink** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.outthink.text -->
Find the logical flaw in its oath
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.outthink.outcome.text -->
You point out the ambiguity in the oath's wording — technically, the requirement is already fulfilled by the act of being challenged. The skeleton freezes mid-reach for its sword. You can hear it processing. You walk past at a measured pace.
<!--@end-->


#### **persuade_oath** — *yellow* — requires roll persuasion vs normal

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.persuade_oath.text -->
Persuade it that the oath no longer serves
<!--@end-->


*Outcome — success*

`karma: human+5  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.persuade_oath.outcome_success.text -->
You speak to it about the nature of oaths — not their letter but their purpose. What was it protecting? Is the thing it was protecting still here? The iron skeleton stands for a long time. Then it lowers its sword. Something releases in its posture.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: hard  ·  karma: asura+2`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.persuade_oath.outcome_failure.text -->
"My oath is not a matter for debate." It draws.
<!--@end-->


#### **offer_place** — *blue* — requires charm 15

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.offer_place.text -->
Offer to take its place
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 20  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.offer_place.outcome.text -->
"I'll stand here. You've done enough." The iron skeleton goes very still. Then, slowly, it pulls the sword from the ground and holds it out to you. Its posture as it walks away is the lightest you've seen anything move in this realm.
<!--@end-->


#### **joint_lock** — *blue* — requires unarmed 3

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.joint_lock.text -->
Fight unarmed — use joint locks and throws
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: easy  ·  karma: asura+3, human+2  ·  xp: 14  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.joint_lock.outcome.text -->
You cross your arms over your chest and bow, empty-handed. The iron skeleton looks at you for a long moment. Then it accepts the terms. What follows is not a sword fight.
<!--@end-->


#### **smash_sword_arm** — *blue* — requires maces 3

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.smash_sword_arm.text -->
Smash its sword arm — end the fight before it starts
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: easy  ·  karma: asura+3  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.smash_sword_arm.outcome.text -->
Your first move is not a block — it's a strike at the wrist holding the sword. Iron on iron. The skeleton stumbles back, sword arm compromised. The duel continues, but on your terms now.
<!--@end-->


#### **duelist_cannot_walk_past** — *blue* — requires **trait: duelist**  **NEW**

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.duelist_cannot_walk_past.text -->
A sword in the ground at a crossroads is a sentence with one ending.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+10`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.duelist_cannot_walk_past.outcome.text -->
You draw before it has finished standing up, which it takes as the courtesy it was intended to be.

The iron skeleton is better than you in three respects and worse in one, and the one is enough.
<!--@end-->


#### **keep_range** — *blue* — requires spears 3

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.keep_range.text -->
Fight at reach — keep it off its blade advantage
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: easy  ·  karma: asura+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_iron_skeleton_duel | choices.keep_range.outcome.text -->
The iron skeleton has a short sword. You have a spear. The reach disparity matters more than the skill gap. You manage distance and let it exhaust itself against your range.
<!--@end-->


---

## hg_copper_mirror

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_copper_mirror | title -->
The Copper Mirror
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_copper_mirror | text -->
A copper skeleton sits polishing an enormous mirror of burnished copper. The mirror shows not reflections but truths — the viewer sees themselves as they truly are.

"Most can't bear it," the skeleton says, without looking up. "Can you?"
<!--@end-->


### Choices


#### **look_in** — *yellow* — requires roll awareness vs difficult

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.look_in.text -->
Look into the mirror
<!--@end-->


*Outcome — success*

`karma: god+6  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.look_in.outcome_success.text -->
You look. What you see is not flattering and not damning — it is accurate. You stand with it until the accuracy becomes useful.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.look_in.outcome_failure.text -->
You look. What you see is too much. You look away after a moment, unsettled in a way that takes time to settle back.
<!--@end-->


#### **ask_skeleton** — *grey*

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.ask_skeleton.text -->
Ask the skeleton about itself
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.ask_skeleton.outcome.text -->
"I was a judge. In life, I showed people their crimes. In death, I show them themselves. It is the same work." It resumes polishing.
<!--@end-->


#### **smash** — *grey*

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.smash.text -->
Smash the mirror
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warrior  ·  difficulty: normal  ·  karma: hungry_ghost+4, hell+3`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.smash.outcome.text -->
The skeleton sets down its cloth. The mirror reforms before the fight is over.
<!--@end-->


#### **polish** — *grey*

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.polish.text -->
Sit and polish it together
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.polish.outcome.text -->
You work in companionable silence. The mirror grows brighter. The skeleton nods when you finish.
<!--@end-->


#### **clear_eyed_asks** — *blue* — requires **trait: clear_eyed**  **NEW**

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.clear_eyed_asks.text -->
Ask what he is polishing it for.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.clear_eyed_asks.outcome.text -->
Nobody asks that. Everybody asks what it shows.

He stops polishing. 'For the King,' he says, and then, after a pause that goes on rather too long, 'He has not asked for it in some time.'
<!--@end-->


#### **read_truth_spell** — *blue* — requires enchantment 3

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.read_truth_spell.text -->
Study the enchantment behind the mirror
<!--@end-->


*Outcome*

`karma: god+5, human+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_copper_mirror | choices.read_truth_spell.outcome.text -->
The enchantment is elegant — a truth-compulsion layered over a reflection spell, calibrated not to lie but not to flatter either. It shows what is, precisely and without context.

You study the structure for a while. The skeleton watches you study it.

'Most people just look in,' it says.

'Most people aren't trying to understand it.'

The skeleton polishes in silence. 'You just did both,' it says. 'You looked in when you read it.'
<!--@end-->


---

## hg_preta_feeding_ground

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | title -->
The Feeding Ground
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | text -->
A hollow where pretas gather around a spring of water that turns to pus in their mouths, fruit trees whose apples become ash when touched. The pretas wail and claw at sustenance that perpetually escapes them. It is one of the worst things you have ever seen.
<!--@end-->


### Choices


#### **share_food** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.share_food.text -->
Share your own food
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.share_food.outcome.text -->
It works, briefly. Your food is not cursed, and for a moment they eat — actually eat. The crying slows. It doesn't last. But for a moment it was real.
<!--@end-->


#### **bless_spring** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.bless_spring.text -->
Bless the spring with white magic
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.bless_spring.outcome.text -->
The water runs clear. The pretas drink with expressions that have no analog in the living world. It reverts after an hour. But for that hour it is something.
<!--@end-->


#### **study_curse** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.study_curse.text -->
Study the mechanics of the curse
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.study_curse.outcome.text -->
You understand it now — how the curse works, where it originates, why the simple solutions fail. What to do with this understanding is a separate and harder question.
<!--@end-->


#### **move_on** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.move_on.text -->
Move on
<!--@end-->


*Outcome*

`karma: animal+3`

<!--@ hungry_ghost_events.json | hg_preta_feeding_ground | choices.move_on.outcome.text -->
You can't help everyone. You keep moving. The sound follows you for a while before the wind takes it.
<!--@end-->


---

## hg_bone_bridge

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_bridge | title -->
The Bone Bridge
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_bridge | text -->
A bridge of interlocking bones spans a chasm of howling darkness. Halfway across, a figure blocks the way — a massive bone horror, assembled from dozens of skeletons, looming in perfect silence. It does not speak. It does not need to.
<!--@end-->


### Choices


#### **fight_headon** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.fight_headon.text -->
Fight it head-on
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bone_horror  ·  difficulty: hard  ·  karma: asura+2`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.fight_headon.outcome.text -->

<!--@end-->


#### **find_weakness** — *blue* — requires awareness 15

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.find_weakness.text -->
Look for the binding spell
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bone_horror  ·  difficulty: easy  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.find_weakness.outcome.text -->
There — the keystone bone, the one the spell anchors to. If that goes, the rest follows.
<!--@end-->


#### **collapse_leap** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.collapse_leap.text -->
Collapse the bridge behind you and leap
<!--@end-->


*Outcome — success*

`xp: 12`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.collapse_leap.outcome_success.text -->
You trigger the collapse and run. The bridge drops away beneath you and you catch the far edge with both hands, hauling yourself over as the horror falls into the dark below.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bone_horror  ·  difficulty: hard`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.collapse_leap.outcome_failure.text -->
You both go over. You catch the edge. It does not.
<!--@end-->


#### **timid_will_not_cross** — *blue* — requires **trait: timid**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.timid_will_not_cross.text -->
It is made of people and it is over a hole that howls.
<!--@end-->


*Outcome*

`xp: 22  ·  supplies: {'food': -4}  ·  pressure: air-12`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.timid_will_not_cross.outcome.text -->
It is, and you cannot, and the party has to spend an hour finding a way that does not involve it.

The hour costs supplies. Nobody says anything about it, which somehow does not help.
<!--@end-->


#### **brave_goes_across** — *blue* — requires **trait: brave**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.brave_goes_across.text -->
Somebody crosses first or nobody crosses.
<!--@end-->


*Outcome*

`xp: 12  ·  pressure: air+8`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.brave_goes_across.outcome.text -->
You go. The bridge says things while you are on it, in several voices, and you keep walking through all of them.

On the far side you find you have to sit down for a moment before waving the others over.
<!--@end-->


#### **sing_lullaby** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.sing_lullaby.text -->
Sing to the people inside it
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 20`

<!--@ hungry_ghost_events.json | hg_bone_bridge | choices.sing_lullaby.outcome.text -->
You sing something simple, something that belonged to someone once. The horror shudders. The assembled bones tremble against each other. One by one, the fragments that were people hear something they recognize. The thing steps aside, shaking. You cross in silence.
<!--@end-->


---

## hg_grave_hound_pack

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | title -->
The Pack
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | text -->
A pack of grave hounds — skeletal dogs with eyes of green flame — circles you. They're not attacking. They're sniffing. Curious. One tilts its skull and whines.
<!--@end-->


### Choices


#### **offer_food** — *grey*

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.offer_food.text -->
Offer food
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.offer_food.outcome.text -->
They eat with the focused joy of dogs everywhere. One stays close to your heel afterward, green eyes glowing up at you.
<!--@end-->


#### **intimidate** — *yellow* — requires roll strength vs easy

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.intimidate.text -->
Stare them down
<!--@end-->


*Outcome — success*


<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.intimidate.outcome_success.text -->
You hold your ground and meet the eyes of the largest one. It blinks first. The pack loses interest and drifts away.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: grave_hound_pack  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.intimidate.outcome_failure.text -->
They take the challenge seriously.
<!--@end-->


#### **speak_soothingly** — *blue* — requires charm 12

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.speak_soothingly.text -->
Speak to them calmly
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.speak_soothingly.outcome.text -->
Something in your tone reaches the part of them that was once a dog. They settle. The one that whined leads you, with clear purpose, to a hollow in the ground.
<!--@end-->


#### **try_binding** — *yellow* — requires summoning 3, roll focus vs easy

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.try_binding.text -->
Attempt to bind one as a familiar
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.try_binding.outcome_success.text -->
The binding takes. One hound sits and tilts its skull at you with what you decide to read as acceptance.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.try_binding.outcome_failure.text -->
The binding fails. The hound in question is offended and snaps at you. The pack loses interest and trots away.
<!--@end-->


#### **hunter_reads_pack** — *blue* — requires **trait: hunter**  **NEW**

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.hunter_reads_pack.text -->
Find the one the others keep glancing at.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.hunter_reads_pack.outcome.text -->
Third from the left, smaller than the rest, standing slightly apart.

Everything the pack does routes through her. You do not have to fight seven grave hounds; you have to convince one, in front of six witnesses.
<!--@end-->


#### **drop_alpha** — *blue* — requires ranged 3

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.drop_alpha.text -->
Drop the alpha at distance — scatter the pack
<!--@end-->


*Outcome*

`karma: asura+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_grave_hound_pack | choices.drop_alpha.outcome.text -->
You identify the pack leader — the one the others keep watching — and put a shot between its shoulder blades at range. Clean drop. The pack scatters immediately, the hierarchy dissolved in one shot. No further engagement required.

Somewhere behind you, a green flame flickers once and goes out.
<!--@end-->


---

## hg_last_rites

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_last_rites | title -->
The Unfinished Rites
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_last_rites | text -->
A half-completed funeral pyre. The body hasn't been burned — the rites were interrupted. A dré circles the pyre, keening. Without proper rites, neither body nor spirit can move on.
<!--@end-->


### Choices


#### **complete_rites** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_last_rites | choices.complete_rites.text -->
Complete the rites
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 16  ·  add_trait: mourner`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.complete_rites.outcome.text -->
The ceremony takes time and every word must be right. When the pyre catches, the dré's keening softens and then stops. It drifts upward and is gone.
<!--@end-->


#### **pray** — *blue* — requires yoga 1

<!--@ hungry_ghost_events.json | hg_last_rites | choices.pray.text -->
Pray for the dead — what you can offer
<!--@end-->


*Outcome*

`karma: god+3  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.pray.outcome.text -->
You cannot complete the rites, but you can witness. You sit and pray for a while. The dré calms, marginally. It is not enough but it is something.
<!--@end-->


#### **take_offerings** — *yellow* — requires thievery 2, roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_last_rites | choices.take_offerings.text -->
Take the funeral offerings
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  gold: small  ·  items: ['item_random']  ·  add_trait: covetous`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.take_offerings.outcome_success.text -->
You work quickly and quietly. The dré doesn't notice.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: charnel_wraith  ·  difficulty: normal  ·  karma: hell+3`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.take_offerings.outcome_failure.text -->
The dré notices. Its keening changes pitch.
<!--@end-->


#### **build_pyre** — *blue* — requires smithing 3

<!--@ hungry_ghost_events.json | hg_last_rites | choices.build_pyre.text -->
Build a proper pyre from what's available
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 12  ·  add_trait: mourner`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.build_pyre.outcome.text -->
The existing pyre was assembled wrong — too loose, wrong timber arrangement, no heat concentration. You break it down and rebuild it properly in forty minutes, using the scavenged materials as they should be used.

The dré watches you work in silence. When you light it, the fire catches cleanly and burns hot. Not the same as the proper rites — the spirit knows the difference — but the dré settles at the fire's edge with something that is almost quiet.
<!--@end-->


#### **mourner_finishes** — *blue* — requires **trait: mourner**  **NEW**

<!--@ hungry_ghost_events.json | hg_last_rites | choices.mourner_finishes.text -->
Somebody started this and did not finish it. Finish it.
<!--@end-->


*Outcome*

`karma: hungry_ghost-8, human+5  ·  xp: 20  ·  pressure: water+15`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.mourner_finishes.outcome.text -->
You know the order. You have done this often enough that your hands know the order, which is the part nobody warns you about.

When the pyre takes, the thing that has been waiting at the edge of the clearing goes wherever such things go, without any fuss at all.
<!--@end-->


#### **ask_dre** — *grey*

<!--@ hungry_ghost_events.json | hg_last_rites | choices.ask_dre.text -->
Ask the dré what happened
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_last_rites | choices.ask_dre.outcome.text -->
It takes a long time to understand the dré — its grief interrupts its speech constantly. Eventually you piece it together: the ritual was interrupted by a fight, the practitioners fled, and no one came back. It tells you where the practitioners went.
<!--@end-->


---

## hg_yidag_encounter

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_yidag_encounter | title -->
The Needle-Throat
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_yidag_encounter | text -->
A yidag — the truest form of the hungry ghost, belly swollen to bursting, throat thin as a needle — blocks the road. Not threateningly. It simply can't move. It wheezes:

"Please. Anything. Even a drop."
<!--@end-->


### Choices


#### **give_water** — *grey*

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.give_water.text -->
Give it water
<!--@end-->


*Outcome*

`karma: god+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.give_water.outcome.text -->
The water evaporates the moment it touches its throat. It weeps. You tried.
<!--@end-->


#### **white_magic** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.white_magic.text -->
Use white magic to ease its suffering
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.white_magic.outcome.text -->
You temporarily widen its throat — just enough. It drinks for the first time in centuries, slowly, with its eyes closed. When it opens them, they're wet in a way that has nothing to do with the water.
<!--@end-->


#### **ask_history** — *grey*

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.ask_history.text -->
Ask how it came to this
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.ask_history.outcome.text -->
A story of accumulated small greeds, none of them spectacular. It builds a picture of a life structured entirely around taking without giving — not evil, just narrow, for a very long time. The warning in the story is precise.
<!--@end-->


#### **ascetic_recognises_it** — *blue* — requires **trait: ascetic**  **NEW**

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.ascetic_recognises_it.text -->
You know what it is to want and not take.
<!--@end-->


*Outcome*

`karma: hungry_ghost-8, human+5  ·  xp: 20  ·  pressure: fire+15`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.ascetic_recognises_it.outcome.text -->
You sit down in front of it, which nobody does, and you do not offer it anything, which everybody does and which has never once worked.

What you offer instead is the observation that the wanting does not have to be obeyed. It is not cured. It is, for the first time in a very long while, spoken to.
<!--@end-->


#### **put_to_misery** — *yellow* — requires roll charm vs normal

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.put_to_misery.text -->
Help it let go
<!--@end-->


*Outcome — success*

`karma: god+6  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.put_to_misery.outcome_success.text -->
"There is nothing to drink here. There has never been anything to drink here. You can stop." It looks at you for a long time. Then, very slowly, it loosens its grip on existing. It dissolves, quietly.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: lost_preta  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_yidag_encounter | choices.put_to_misery.outcome_failure.text -->
The suggestion that it could stop triggers something desperate. It attacks.
<!--@end-->


---

## hg_smuggler_tunnel

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | title -->
The Smuggler's Tunnel
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | text -->
A narrow tunnel entrance hidden behind a collapsed wall. Scratch marks on the stone suggest frequent use. From inside: voices, the clink of coin, the smell of something cooking.
<!--@end-->


### Choices


#### **enter_cautiously** — *grey*

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.enter_cautiously.text -->
Enter cautiously
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_black_market  ·  karma: hungry_ghost+1`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.enter_cautiously.outcome.text -->

<!--@end-->


#### **announce_yourself** — *yellow* — requires roll charm vs easy

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.announce_yourself.text -->
Announce yourself openly
<!--@end-->


*Outcome — success*

`type: shop  ·  shop_id: hg_black_market  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.announce_yourself.outcome_success.text -->
A pause. Then: "Come in, then. Leave your paranoia at the door." Better prices for a customer who didn't sneak.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: skeleton_warband  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.announce_yourself.outcome_failure.text -->
"A spy." They don't wait to find out.
<!--@end-->


#### **offer_contraband** — *blue* — requires thievery 2

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.offer_contraband.text -->
Present yourself as a potential partner
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_black_market  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.offer_contraband.outcome.text -->
You know the right words. They let you into the back room.
<!--@end-->


#### **secret_bearer_reads_marks** — *blue* — requires **trait: secret_bearer**  **NEW**

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.secret_bearer_reads_marks.text -->
Those scratches are not damage. They are a message.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.secret_bearer_reads_marks.outcome.text -->
They are a message, in the sense that anything kept from most people is a message to the rest.

You read it: a count, a direction, and a warning about the third turning. All three prove accurate.
<!--@end-->


#### **report** — *blue* — requires persuasion 3

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.report.text -->
Report them to the bone patrol
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 8  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_smuggler_tunnel | choices.report.outcome.text -->
You find the nearest patrol and bring them back. The tunnel is raided. The Skeleton King's forces are grudgingly grateful.
<!--@end-->


---

## hg_spirit_lanterns

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | title -->
The Lantern Procession
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | text -->
A line of ghostly lanterns floats through the darkness, each carried by an invisible hand. They move with purpose — a funeral procession of pure spirit, honoring someone important who died long ago. The procession repeats every night, endlessly.
<!--@end-->


### Choices


#### **walk_alongside** — *grey*

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.walk_alongside.text -->
Walk alongside respectfully
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.walk_alongside.outcome.text -->
You fall into step with the procession. The light is warm despite the cold. Something solemn and beautiful moves through you with it.
<!--@end-->


#### **join_procession** — *blue* — requires ritual 2

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.join_procession.text -->
Join the procession — carry a lantern
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.join_procession.outcome.text -->
A lantern drifts into your hands. As you carry it, visions come — fragments of the honored dead's life, their work, their love for whatever is being mourned here. The procession ends at a marker stone. The lanterns settle. A long peace.
<!--@end-->


#### **break_cycle** — *yellow* — requires white_magic 3, roll focus vs difficult

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.break_cycle.text -->
Try to end the eternal repetition
<!--@end-->


*Outcome — success*

`karma: god+8  ·  xp: 24`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.break_cycle.outcome_success.text -->
You reach into the pattern of it and find where the loop closes. You open it. The lanterns flicker, then go still. The procession ends — truly ends. The darkness is darker for a moment, then easier.
<!--@end-->


*Outcome — failure*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.break_cycle.outcome_failure.text -->
The pattern resists you. The procession blurs and stutters for a moment, then resumes its course as if nothing happened.
<!--@end-->


#### **steal_lantern** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.steal_lantern.text -->
Take one of the lanterns
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+4  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.steal_lantern.outcome_success.text -->
The lantern comes away in your hands, warm and surprisingly heavy.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: charnel_wraith  ·  difficulty: normal`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.steal_lantern.outcome_failure.text -->
The invisible hand does not let go. What was carrying the lantern turns its attention to you.
<!--@end-->


#### **night_owl_falls_in** — *blue* — requires **trait: night_owl**  **NEW**

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.night_owl_falls_in.text -->
It is the middle of the night and you are wide awake.
<!--@end-->


*Outcome*

`xp: 12  ·  pressure: space+10`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.night_owl_falls_in.outcome.text -->
Everyone else is asleep or nearly. You are at your best, and you fall in at the back of the procession and walk with it for a mile before it notices you.

When it notices, it does not object. It makes room.
<!--@end-->


#### **light_sleeper_wakes** — *blue* — requires **trait: light_sleeper**  **NEW**

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.light_sleeper_wakes.text -->
You were awake before the light reached the camp.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.light_sleeper_wakes.outcome.text -->
You always are. It means you see the procession from its first lantern to its last, which nobody else in the party does, and you count them.

The number matters later.
<!--@end-->


#### **identify_enchantment** — *blue* — requires enchantment 3

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.identify_enchantment.text -->
Study the enchantment — understand what drives the loop
<!--@end-->


*Outcome*

`karma: god+6, human+2  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_spirit_lanterns | choices.identify_enchantment.outcome.text -->
The enchantment is a grief-loop — a mourning spell that has outlasted its caster by centuries, still running because no one cancelled it. The procession is real; the love in it is real. It just doesn't know it's allowed to stop.

You cannot dissolve it with enchantment alone, but now you understand its structure. The next person who walks beside these lanterns might be able to give it the permission it's been missing.
<!--@end-->


---

## hg_gravedigger

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_gravedigger | title -->
The Gravedigger
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_gravedigger | text -->
A living man — actually alive — digs graves in the realm of the dead. He's been here so long he's forgotten how he arrived. He looks up as you approach without stopping his work.

"Someone's got to do it. The dead keep coming and the holes don't dig themselves."
<!--@end-->


### Choices


#### **help_dig** — *grey*

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.help_dig.text -->
Help him dig
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.help_dig.outcome.text -->
You work side by side in companionable quiet. At the end of it, he shares what he has — some food, some stories, a practical warmth that is rare in this realm.
<!--@end-->


#### **ask_leaving** — *grey*

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.ask_leaving.text -->
Ask how to leave this realm
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.ask_leaving.outcome.text -->
"Couldn't tell you. Been trying myself." He leans on his shovel. "What I can tell you is: don't eat anything they offer. Don't go near the river after dark. And the Skeleton King's patrols are mostly reasonable, as long as you're doing something they can categorize."
<!--@end-->


#### **offer_home** — *blue* — requires charm 13

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.offer_home.text -->
Offer to help him find his way home
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.offer_home.outcome.text -->
He stops digging. Considers it for a long moment. "Who'd dig the graves?" He goes back to work. But something about him looks lighter after the question was asked.
<!--@end-->


#### **warm_hearted_asks_why** — *blue* — requires **trait: warm_hearted**  **NEW**

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.warm_hearted_asks_why.text -->
He is alive. Ask him how he is, before anything else.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.warm_hearted_asks_why.outcome.text -->
Nobody has asked him that. He gets asked what he is doing here, and how he got here, and whether he can be bought.

He leans on the spade for a while before answering, and the answer takes most of an hour and is worth the hour.
<!--@end-->


#### **trade** — *blue* — requires trade 2

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.trade.text -->
Offer to trade — he's had interesting finds
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 6  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_gravedigger | choices.trade.outcome.text -->
He digs through a sack he keeps by the graveside. Things accumulate around graves. He has more than you'd expect, and most of it is in good condition.
<!--@end-->


---

## hg_bone_library

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_library | title -->
The Bone Library
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_library | text -->
Shelves of bone hold scrolls of dried skin. A bespectacled silver skeleton moves between them, filing and organizing with tireless precision. It turns at your approach.

"Knowledge doesn't decay. My work today may help somebody in a thousand years. What can I do for you?"
<!--@end-->


### Choices


#### **research** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_bone_library | choices.research.text -->
Research a subject
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.research.outcome.text -->
The librarian pulls scrolls without hesitation, knowing exactly where everything is. What you find goes beyond what you expected to find.
<!--@end-->


#### **ask_history** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_library | choices.ask_history.text -->
Ask about the realm's history
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.ask_history.outcome.text -->
The librarian settles into it with obvious pleasure. The history of the hungry ghost realm is longer than you expected and stranger. You come away with the sense that this place has its own logic, older than any of the beings currently living in it.
<!--@end-->


#### **offer_book** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_library | choices.offer_book.text -->
Offer a book from the living world
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 10  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.offer_book.outcome.text -->
The librarian takes it with both hands, holding it carefully away from the bone shelves as if it might be infectious in the best possible way. "I have nothing like this. Nothing written after the living left." It opens the rare section.
<!--@end-->


#### **steal_scroll** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_bone_library | choices.steal_scroll.text -->
Steal a rare scroll
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+4  ·  items: ['spell_random']`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.steal_scroll.outcome_success.text -->
You find what you want and leave with it. The librarian doesn't notice.
<!--@end-->


*Outcome — failure*

`karma: god-4`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.steal_scroll.outcome_failure.text -->
The librarian looks at you. Then at the scroll. Then at you again — not angry, just deeply, genuinely sad. You put it back.
<!--@end-->


#### **curious_stays** — *blue* — requires **trait: curious**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_library | choices.curious_stays.text -->
You are not leaving a library. Be reasonable.
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.curious_stays.outcome.text -->
The silver skeleton adjusts its spectacles and produces, from somewhere, a second chair.

What you find in four hours is not what you were looking for and is considerably better: a name, an obligation, and where the obligation was last recorded.
<!--@end-->


#### **sharp_memory_indexes** — *blue* — requires **trait: sharp_memory**  **NEW**

<!--@ hungry_ghost_events.json | hg_bone_library | choices.sharp_memory_indexes.text -->
Do not read them. Index them.
<!--@end-->


*Outcome*

`xp: 12`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.sharp_memory_indexes.outcome.text -->
You go through the shelf-marks rather than the scrolls, which the librarian watches with mounting professional respect.

By evening you hold the shape of the whole collection, and the shape has a gap in it exactly where something was removed.
<!--@end-->


#### **ask_teach** — *blue* — requires persuasion 2

<!--@ hungry_ghost_events.json | hg_bone_library | choices.ask_teach.text -->
Ask if they'd teach you a few things
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_spell_shop  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_bone_library | choices.ask_teach.outcome.text -->
"Well, I suppose. Why not." It pulls a selection of relevant scrolls and begins.
<!--@end-->


---

## hg_swamp_hermit

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_swamp_hermit | title -->
The Hermit of the Mire
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_swamp_hermit | text -->
Deep in the swamp, a rolang sits on a rock, fishing in toxic water with a line made of hair. It's the most peaceful undead you've ever seen. It has achieved something rare here — contentment.
<!--@end-->


### Choices


#### **sit_and_fish** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.sit_and_fish.text -->
Sit and fish together
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.sit_and_fish.outcome.text -->
You sit in silence for a long time. Nothing bites. It doesn't seem to matter to either of you.
<!--@end-->


#### **ask_secret** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.ask_secret.text -->
Ask its secret
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.ask_secret.outcome.text -->
It doesn't look up from the water. "I stopped wanting." A long pause. "That's it. That's all there is."
<!--@end-->


#### **offer_supplies** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.offer_supplies.text -->
Offer what you're carrying
<!--@end-->


*Outcome*

`karma: god+2`

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.offer_supplies.outcome.text -->
It shakes its head gently. "I have everything I need." It gestures at the toxic water, the dead fish, the grey sky. It means it.
<!--@end-->


#### **disturb** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.disturb.text -->
Disturb its peace — just to see
<!--@end-->


*Outcome*

`karma: hell+2`

<!--@ hungry_ghost_events.json | hg_swamp_hermit | choices.disturb.outcome.text -->
You consider it. Then the thought seems so ridiculous — there is so little peace in this realm and so much to disturb — that you simply leave. The faintest hint of hell clings to the idea.
<!--@end-->


---

## hg_wandering_preta_event

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | title -->
The Wandering Preta
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | text -->
A preta merchant dragging an enormous sack materializes from the grey. Despite being a hungry ghost, this one has channeled its craving into commerce with evident satisfaction.

"I can't eat, I can't drink, I can't sleep — but I CAN make a profit! Browse my wares?"
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.browse.text -->
Browse the wares
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_wandering_preta  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.browse.outcome.text -->

<!--@end-->


#### **ask_life** — *grey*

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.ask_life.text -->
Ask what merchant life is like as a preta
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.ask_life.outcome.text -->
"The margins are incredible since I no longer need to eat into them." A pause. "That's a joke. I can still make jokes." It delivers a ten-minute monologue on the economics of not needing to sleep, eat, or maintain any quality of life while operating a commercial enterprise.
<!--@end-->


#### **offer_food** — *grey*

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.offer_food.text -->
Offer it some of your food
<!--@end-->


*Outcome*

`karma: god+3`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.offer_food.outcome.text -->
It stares at the food for a long time. Then at you. "Nobody has done that in... a long time." It waves you away. "Take ten percent off whatever you buy. Consider it a professional courtesy."
<!--@end-->


#### **rob** — *yellow* — requires roll finesse vs easy

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.rob.text -->
Rob it
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+5  ·  gold: small  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.rob.outcome_success.text -->
Fast hands, fast feet. You're gone before it counts its stock.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: rolang_mob  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.rob.outcome_failure.text -->
It screams loud enough to be heard across the wasteland. Apparently it has regulars.
<!--@end-->


#### **crack_joke** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.crack_joke.text -->
Make a joke about hunger for money
<!--@end-->


*Outcome*

`karma: human+3`

<!--@ hungry_ghost_events.json | hg_wandering_preta_event | choices.crack_joke.outcome.text -->
A wheeze that might be laughter. "Oh, that one's good. That one's actually good." It waves you toward the sack. "Take what you want. I'll give you the suffering-colleague discount."
<!--@end-->


---

## hg_death_meditation

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_death_meditation | title -->
The Charnel Ground Meditation
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_death_meditation | text -->
A flat stone among the bones, worn smooth by sitting. This is a practice site — you can feel it in the quality of the stillness around it. Confronting death directly. Not abstractly.
<!--@end-->


### Choices


#### **meditate_death** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.meditate_death.text -->
Meditate on death fully
<!--@end-->


*Outcome*

`karma: god+9  ·  xp: 24  ·  add_trait: enlightened_insight`

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.meditate_death.outcome.text -->
You sit and let the smell and the reality and the inevitability be present without distance. It is not pleasant and it is not supposed to be. When you rise, something has been processed that had been waiting to be processed for some time.
<!--@end-->


#### **meditate_briefly** — *blue* — requires yoga 1

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.meditate_briefly.text -->
Sit for a moment
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 8  ·  add_trait: composed`

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.meditate_briefly.outcome.text -->
A few minutes on the stone. The reality of the place presses in. You let it. Something small shifts.
<!--@end-->


#### **study_bones** — *blue* — requires medicine 2

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.study_bones.text -->
Study the bones academically
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.study_bones.outcome.text -->
The collection here is unusual — varied, old, well-preserved by the dry air. You learn something about anatomy and something else, harder to name, about impermanence.
<!--@end-->


#### **ash_marked_belongs** — *blue* — requires **trait: ash_marked**  **NEW**

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.ash_marked_belongs.text -->
You have sat in places like this before.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: space+15, water+10`

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.ash_marked_belongs.outcome.text -->
The stone is worn smooth in the shape of people who have done exactly this, and you fit the shape.

What comes up is not fear, because that was dealt with some time ago. What comes up is the ordinary and much harder question of what to do tomorrow.
<!--@end-->


#### **leave_flag** — *grey*

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.leave_flag.text -->
Leave a prayer flag
<!--@end-->


*Outcome*

`karma: god+3`

<!--@ hungry_ghost_events.json | hg_death_meditation | choices.leave_flag.outcome.text -->
You tie it to a bone and leave it fluttering. A small mark that someone was here and paid attention.
<!--@end-->


---

## hg_toll_bridge

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_toll_bridge | title -->
The Toll
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_toll_bridge | text -->
Two massive skeletons in heavy armor flank a stone bridge. A sign lists prices that escalate from the merely unreasonable to the openly delusional. The skeletons seem bored.
<!--@end-->


### Choices


#### **pay** — *grey*

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.pay.text -->
Pay the toll
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.pay.outcome.text -->
They accept the coins without enthusiasm and step aside. Professional.
<!--@end-->


#### **haggle** — *yellow* — requires trade 2, roll charm vs easy

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.haggle.text -->
Haggle
<!--@end-->


*Outcome — success*

`xp: 5`

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.haggle.outcome_success.text -->
You work down through the price list methodically. They concede ground slowly, then all at once.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.haggle.outcome_failure.text -->
They hold the line. The price goes up.
<!--@end-->


#### **comedy** — *yellow* — requires comedy 2, roll charm vs easy

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.comedy.text -->
Make them laugh
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.comedy.outcome_success.text -->
You hit something genuinely funny. One skeleton laughs so hard it falls apart at the waist, and is still clicking on the ground when you walk past.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.comedy.outcome_failure.text -->
"Heard that one. Pay up."
<!--@end-->


#### **debtor_reads_the_sign** — *blue* — requires **trait: debtor**  **NEW**

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.debtor_reads_the_sign.text -->
Read the sign properly. Signs like this always have a clause.
<!--@end-->


*Outcome*

`xp: 20  ·  gold: small`

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.debtor_reads_the_sign.outcome.text -->
There is a clause. There is always a clause, and you have spent enough of your life on the wrong side of one to find it inside a minute.

The toll applies to the living. Two of your party, on a technicality that the skeletons accept with visible irritation, are not paying it.
<!--@end-->


#### **logistics** — *blue* — requires logistics 2

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.logistics.text -->
Point out the economic flaws in the toll structure
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_toll_bridge | choices.logistics.outcome.text -->
You explain, briefly and with specific examples, why their pricing model is destroying long-term traffic revenue and creating a structural deficit. The skeletons stand very still for a long time. You walk past during this.
<!--@end-->


---

## hg_realm_exit

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_realm_exit | title -->
The Border
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_realm_exit | text -->
The air changes. Ahead, the grey wasteland of the hungry ghost realm gives way to something else. A boundary marker — a stone carved with the Wheel of Life — stands at the transition point. Behind you, the realm of craving. Ahead, the unknown.
<!--@end-->


### Choices


#### **cross** — *grey*

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.cross.text -->
Cross without looking back
<!--@end-->


*Outcome*

`xp: 8`

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.cross.outcome.text -->
You step through. The grey lifts.
<!--@end-->


#### **look_back** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.look_back.text -->
Look back one last time
<!--@end-->


*Outcome*

`karma: god+6  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.look_back.outcome.text -->
You turn. The realm reveals itself — not as horror, not as punishment, but as consequence. Everything here follows from something. The craving was always going somewhere. It came here. That clarity stays with you as you cross.
<!--@end-->


#### **leave_offering** — *grey*

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.leave_offering.text -->
Leave an offering at the boundary stone
<!--@end-->


*Outcome*

`karma: god+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.leave_offering.outcome.text -->
For those still inside. You leave what you can spare and cross.
<!--@end-->


#### **dedicate_merit** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.dedicate_merit.text -->
Dedicate all merit gained here to the beings still suffering
<!--@end-->


*Outcome*

`karma: god+12  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_realm_exit | choices.dedicate_merit.outcome.text -->
You stand at the boundary and give it all away — every good thing earned in this realm, offered outward to those who couldn't earn it for themselves. The gesture costs you nothing you can measure. What it does is harder to name.
<!--@end-->


---

## hg_mehr

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mehr | title -->
The Eye in the Dark
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mehr | text -->
Something catches the thin light of the charnel grounds and throws it back — gold, steady, unblinking. Not an insect. Not a torch. An eye. Set in the face of a preserved woman standing knee-deep in black water, watching you with the patience of someone who has been here a long time.
<!--@end-->


### Choices


#### **call_out** — *grey*

<!--@ hungry_ghost_events.json | hg_mehr | choices.call_out.text -->
Call out to her
<!--@end-->


*Outcome*

`xp: 5`

<!--@ hungry_ghost_events.json | hg_mehr | choices.call_out.outcome.text -->
She answers. Dry, measured, without warmth or hostility. She answers your questions the way a stone does if you press your ear to it. She is not interested in traveling. You are not sufficiently interesting.
<!--@end-->


#### **ritual_flame** — *blue* — requires fire_magic 3

<!--@ hungry_ghost_events.json | hg_mehr | choices.ritual_flame.text -->
Light a ritual flame — the old greeting of the Sun priesthood
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: god+3`

<!--@ hungry_ghost_events.json | hg_mehr | choices.ritual_flame.outcome.text -->
The flame catches her attention in a way nothing else would. She straightens. Her golden eye moves before the other one does. 'Where did you learn that form?' She is already wading toward you before you finish answering.
<!--@end-->


#### **read_the_signs** — *blue* — requires space_magic 3

<!--@ hungry_ghost_events.json | hg_mehr | choices.read_the_signs.text -->
Ask about the prophecy — you have enough to read what she was reading
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_mehr | choices.read_the_signs.outcome.text -->
Her good eye narrows. The gold one does not move. 'That is the first intelligent question anyone has asked me in a very long time.' A pause. 'Come. Walk with me while I explain what it actually said.'
<!--@end-->


#### **speak_as_equal** — *yellow* — requires roll charm vs normal

<!--@ hungry_ghost_events.json | hg_mehr | choices.speak_as_equal.text -->
Speak to her as an equal — not with reverence, not with wariness
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_mehr | choices.speak_as_equal.outcome_success.text -->
She studies you for a long moment. 'You have the manner of someone who has survived things,' she says. 'I find that more persuasive than credentials.' She wades toward you.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_mehr | choices.speak_as_equal.outcome_failure.text -->
She looks at you the way she must have looked at the court before they threw her in the tar pit. 'I have heard every manner of introduction,' she says. 'Go.'
<!--@end-->


---

## hg_choki

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_choki | title -->
The Gathering
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_choki | text -->
At the edge of a bog with no wind and no movement, a girl sits watching the water. She does not look up. She has been here long enough that moss has grown around where she sits. She is holding a bundle of forest plants that dried to nothing long ago.
<!--@end-->


### Choices


#### **leave_her** — *grey*

<!--@ hungry_ghost_events.json | hg_choki | choices.leave_her.text -->
Leave her to the water
<!--@end-->


*Outcome*

`karma: animal+1  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_choki | choices.leave_her.outcome.text -->
The bog is silent as you walk away. You don't hear her move.
<!--@end-->


#### **touch_the_water** — *blue* — requires water_magic 3

<!--@ hungry_ghost_events.json | hg_choki | choices.touch_the_water.text -->
Touch the water beside her — let it speak for you
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: choki  ·  karma: human+2, god+3`

<!--@ hungry_ghost_events.json | hg_choki | choices.touch_the_water.outcome.text -->
The water stirs slightly under your hand. She watches it. 'It was like that,' she says. 'One moment there was nothing. Then—' She trails off. Then: 'You are going somewhere. Can I come?'
<!--@end-->


#### **ask_what_she_gathered** — *blue* — requires logistics 3

<!--@ hungry_ghost_events.json | hg_choki | choices.ask_what_she_gathered.text -->
Ask her what she was gathering when the flood came
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: choki  ·  karma: human+4`

<!--@ hungry_ghost_events.json | hg_choki | choices.ask_what_she_gathered.outcome.text -->
She finally looks up. Something in the question — the specificity of it, the acknowledgment of what she was doing when she left — gets through where comfort never would. She tells you everything she was carrying. She asks if you need a guide.
<!--@end-->


#### **sit_in_silence** — *yellow* — requires roll awareness vs normal

<!--@ hungry_ghost_events.json | hg_choki | choices.sit_in_silence.text -->
Sit beside her without speaking — wait for her to acknowledge you
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: choki  ·  karma: human+3, animal+2`

<!--@ hungry_ghost_events.json | hg_choki | choices.sit_in_silence.outcome_success.text -->
The silence stretches to an hour. Then two. Then she says: 'You're still here.' After another long while: 'Most people leave.' She looks at you sideways. 'Where are you going?'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_choki | choices.sit_in_silence.outcome_failure.text -->
She doesn't acknowledge you. The waiting becomes its own kind of grief. You eventually stand and go.
<!--@end-->


---

## hg_nangwa

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_nangwa | title -->
The Unfinished Argument
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_nangwa | text -->
In the collapsed shell of what was once a library — shelves of ash, scrolls of smoke — a barely-visible figure moves between the ruins. It is picking up nothing, reading nothing, but its lips are moving. Occasionally it stops, gestures at empty air, shakes its head, and starts again from the beginning.
<!--@end-->


### Choices


#### **watch_and_leave** — *grey*

<!--@ hungry_ghost_events.json | hg_nangwa | choices.watch_and_leave.text -->
Watch him for a while, then leave
<!--@end-->


*Outcome*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_nangwa | choices.watch_and_leave.outcome.text -->
He doesn't notice you leave. The argument continues.
<!--@end-->


#### **complete_his_sentence** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_nangwa | choices.complete_his_sentence.text -->
Complete his sentence — you can see where the argument is going
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_nangwa | choices.complete_his_sentence.outcome.text -->
He stops. Turns toward you with the most attention he has given anything in centuries. He seems to become slightly more present in the physical world as he focuses. 'Walk with me,' he says. 'I think better when I walk. Tell me if I have this right.'
<!--@end-->


#### **reach_through_space** — *blue* — requires space_magic 3

<!--@ hungry_ghost_events.json | hg_nangwa | choices.reach_through_space.text -->
Reach toward him through space — make contact with the part of him that is still here
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: god+2`

<!--@ hungry_ghost_events.json | hg_nangwa | choices.reach_through_space.outcome.text -->
For a moment, genuine contact. He startles. Looks at his hands as if seeing them for the first time in a while. 'Oh,' he says. 'I have been quite far away.' He looks at you with new attention. 'Would you stay nearby? I find I concentrate better when someone is present.'
<!--@end-->


#### **follow_the_argument** — *yellow* — requires roll focus vs normal

<!--@ hungry_ghost_events.json | hg_nangwa | choices.follow_the_argument.text -->
Follow the argument — interrupt at the right moment
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_nangwa | choices.follow_the_argument.outcome_success.text -->
You catch the flaw and name it. He stops mid-gesture. 'Say that again.' You do. He is silent for a full minute. Then: 'I hadn't considered that approach.' A longer silence. 'Come with me while I think it through. I need a sounding board.'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_nangwa | choices.follow_the_argument.outcome_failure.text -->
Your interjection breaks his concentration entirely. He dissipates for a moment, then reforms, looking confused and irritated. You have cost him hours of work.
<!--@end-->


---

## hg_prashan

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_prashan | title -->
The Crossroads Question
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_prashan | text -->
A vetala perches on a crumbling milestone, its mismatched layers of stolen cloth draped over a body it wears like a borrowed coat. It turns its head at your approach with the particular alertness of someone who has been waiting for exactly this. 'Ah,' it says. 'A traveler. I have a question for you.'
<!--@end-->


### Choices


#### **refuse** — *grey*

<!--@ hungry_ghost_events.json | hg_prashan | choices.refuse.text -->
Refuse to engage
<!--@end-->


*Outcome*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_prashan | choices.refuse.outcome.text -->
'As you like. You will be back. They always come back when they have had time to think of an answer.' It settles in to wait.
<!--@end-->


#### **ask_a_better_question** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_prashan | choices.ask_a_better_question.text -->
Ask it a better question instead of answering
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+5`

<!--@ hungry_ghost_events.json | hg_prashan | choices.ask_a_better_question.outcome.text -->
It goes very still. This has not happened before — or not for a very long time. 'You—' It stops. 'Where did you—' Stops again. Slowly, a smile spreads across a face not quite designed for it. 'All right. This is excellent. You will come with me. I insist.'
<!--@end-->


#### **tell_a_joke** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_prashan | choices.tell_a_joke.text -->
Tell it a joke instead of answering
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_prashan | choices.tell_a_joke.outcome.text -->
It blinks. Then, despite itself, makes a sound. Then another. 'That is — oh, that is terrible. That is genuinely terrible.' Its head is listing sideways with laughter. 'Come, I'll show you something better. I promise.'
<!--@end-->


#### **answer_the_riddle** — *yellow* — requires roll awareness vs normal

<!--@ hungry_ghost_events.json | hg_prashan | choices.answer_the_riddle.text -->
Answer the riddle
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_prashan | choices.answer_the_riddle.outcome_success.text -->
It tilts its head. Then further. Then further still, nearly upside down. 'Hmm.' A long pause. 'That is either a very good answer or a very bad one, and I cannot immediately tell which.' It straightens. 'I need to follow this further. Come with me.'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_prashan | choices.answer_the_riddle.outcome_failure.text -->
'No. That is the obvious answer. Everyone says that.' It gestures dismissively. 'Go away. Come back when you have thought more carefully.'
<!--@end-->


---

## hg_nyingje

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_nyingje | title -->
The Round
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_nyingje | text -->
Among the ruins of a catacomb, a silver skeleton moves methodically from form to form — rolangs, dré, the occasional barely-present ghost. It is tending them. Binding wounds that will not heal, offering a hand to things that won't take it, reciting something under its breath to creatures that cannot hear. It does not seem to need an audience.
<!--@end-->


### Choices


#### **leave_without_disturbing** — *grey*

<!--@ hungry_ghost_events.json | hg_nyingje | choices.leave_without_disturbing.text -->
Leave without disturbing her
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_nyingje | choices.leave_without_disturbing.outcome.text -->
She doesn't look up as you go. The recitation continues.
<!--@end-->


#### **help_with_work** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_nyingje | choices.help_with_work.text -->
Help her with her round — tend alongside her
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: god+5, human+3`

<!--@ hungry_ghost_events.json | hg_nyingje | choices.help_with_work.outcome.text -->
You work in silence for a while. She watches your technique without comment. Then: 'You have been taught properly.' A pause. 'By whom?' By the time you finish answering, you are both walking. You realize later you agreed to travel together without either of you saying so directly.
<!--@end-->


#### **meditate_nearby** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_nyingje | choices.meditate_nearby.text -->
Sit in meditation nearby — make yourself a point of stillness in this place
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: god+4`

<!--@ hungry_ghost_events.json | hg_nyingje | choices.meditate_nearby.outcome.text -->
She completes her round and comes back to where you are sitting. Waits. When you open your eyes, she is very close. 'You practice,' she says. It is not a question. A pause. 'I will walk with you for a while.'
<!--@end-->


#### **ask_directly** — *yellow* — requires roll charm vs difficult

<!--@ hungry_ghost_events.json | hg_nyingje | choices.ask_directly.text -->
Ask her directly: will you travel with us?
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: god+4, human+2`

<!--@ hungry_ghost_events.json | hg_nyingje | choices.ask_directly.outcome_success.text -->
She pauses in her work. Studies you with empty eye sockets that somehow convey careful attention. 'You are going further than here,' she says. 'There will be beings who need tending there too.' She finishes with her current patient, then stands. 'I will come.'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_nyingje | choices.ask_directly.outcome_failure.text -->
'I am needed here.' She returns to her work without hostility. It is simply true.
<!--@end-->


---

## hg_khedrup

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_khedrup | title -->
The Auspicious Count
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_khedrup | text -->
On a flat rock carved with auspicious symbols, a preserved rolang sits in full meditation posture, counting beads with extraordinary precision. His lips move with sub-vocalized counts. Beside him, a pile of tally marks in the stone suggests he has been at this particular session for a very long time. He has the focused look of a man who is almost sure his formula is right.
<!--@end-->


### Choices


#### **leave_him** — *grey*

<!--@ hungry_ghost_events.json | hg_khedrup | choices.leave_him.text -->
Leave him to his counting
<!--@end-->


*Outcome*

`xp: 3`

<!--@ hungry_ghost_events.json | hg_khedrup | choices.leave_him.outcome.text -->
The counting continues. The tally marks accumulate.
<!--@end-->


#### **spot_the_flaw** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_khedrup | choices.spot_the_flaw.text -->
Point out a flaw in his formula — you can see where the multiplier breaks down
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: khedrup  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_khedrup | choices.spot_the_flaw.outcome.text -->
His hand stops on the beads. He looks up for the first time. 'Show me.' You do. He studies it. Studies you. Then: 'I may need to revise my methodology. I would welcome a second opinion — going forward.'
<!--@end-->


#### **examine_preservation** — *blue* — requires alchemy 3

<!--@ hungry_ghost_events.json | hg_khedrup | choices.examine_preservation.text -->
Examine his preserved state — make a technical observation
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: khedrup`

<!--@ hungry_ghost_events.json | hg_khedrup | choices.examine_preservation.outcome.text -->
'Copper oxide as the fixative?' He looks up sharply. 'How did you—' He examines his own hand, then back at you. 'What else can you tell?' The conversation goes on for some time. By the end he is standing. 'I should like to continue this. If you're traveling, I'll accompany you as far as convenient.'
<!--@end-->


#### **wait_for_the_count** — *yellow* — requires roll focus vs normal

<!--@ hungry_ghost_events.json | hg_khedrup | choices.wait_for_the_count.text -->
Wait for him to complete his count — do not interrupt
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: khedrup  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_khedrup | choices.wait_for_the_count.outcome_success.text -->
Three hours. Four. He reaches the end of his calculation, opens his eyes, and finds you there. 'You waited.' A pause. 'Most don't.' He consults his tallies. 'This is inconvenient. I will need to adjust for your presence in the calculation. Sit down. What is your birth star?'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_khedrup | choices.wait_for_the_count.outcome_failure.text -->
You shift at the wrong moment. He loses count, closes his eyes, and begins again from the beginning without acknowledging you.
<!--@end-->


---

## hg_rasabhava

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_rasabhava | title -->
The Formula
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_rasabhava | text -->
In a low-ceilinged catacomb chamber, a preserved zombie works steadily at a cluttered bench. Phials, powders, a bellows made of preserved lung. The formula on the stone tablet before him is enormously complex. He is at the part he always reaches before noticing something is wrong and starting over. He has not looked up.
<!--@end-->


### Choices


#### **leave_him** — *grey*

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.leave_him.text -->
Leave him to it
<!--@end-->


*Outcome*

`xp: 4`

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.leave_him.outcome.text -->
He doesn't notice you leave. He's found something to check.
<!--@end-->


#### **identify_breakdown** — *blue* — requires alchemy 3

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.identify_breakdown.text -->
Identify the phase where the formula breaks down
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: rasabhava  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.identify_breakdown.outcome.text -->
'The stabilization phase — your catalyst ratio shifts at temperature.' He goes absolutely still. 'Say that again.' You do. He checks it three times. 'I have been wrong for forty-three years.' He closes his eyes. Opens them. 'I believe I need a different sort of problem. Will you have me?'
<!--@end-->


#### **suggest_summoning** — *blue* — requires summoning 3

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.suggest_summoning.text -->
Ask what he is trying to preserve and whether it can be summoned instead
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: rasabhava`

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.suggest_summoning.outcome.text -->
He looks up for the first time. 'You're suggesting — instead of physical fixation, a binding of—' He sets down his tools. 'That would require a collaborator.' A pause. He looks at you properly. 'Come in. Close the door. I want to try something.'
<!--@end-->


#### **read_the_formula** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.read_the_formula.text -->
Read the formula over his shoulder — try to spot what keeps going wrong
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: rasabhava  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_rasabhava | choices.read_the_formula.outcome_success.text -->
You see it — a small error in the stabilization phase, invisible in isolation but fatal in combination. 'There,' you say. He looks. Silence. 'That can't be right. I've checked it six—' He checks it again. 'Oh.' The smallest, most deflated sound. Then: 'Are you traveling? I may want to get out of this room.'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_rasabhava | choices.read_the_formula.outcome_failure.text -->
You can follow the general outline but the specifics are beyond you. He doesn't look up.
<!--@end-->


---

## hg_durvasa

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_durvasa | title -->
The Contained Curse
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_durvasa | text -->
In a hollow beneath a collapsed stupa, a gyelpo sits within a circle of his own making — binding signs carved into the stone, faintly active. He is maintaining a careful stillness. Whatever is bound is inside him. He watches you approach with eyes that are doing a great deal of work to remain calm.
<!--@end-->


### Choices


#### **leave_him** — *grey*

<!--@ hungry_ghost_events.json | hg_durvasa | choices.leave_him.text -->
Leave him to it — this is his problem
<!--@end-->


*Outcome*

`karma: hell+2`

<!--@ hungry_ghost_events.json | hg_durvasa | choices.leave_him.outcome.text -->
You feel his eyes on your back as you leave. The sigils continue to glow.
<!--@end-->


#### **disperse_with_air** — *blue* — requires air_magic 3

<!--@ hungry_ghost_events.json | hg_durvasa | choices.disperse_with_air.text -->
Diffuse the bound energy through the air — disperse it gradually
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: human+6`

<!--@ hungry_ghost_events.json | hg_durvasa | choices.disperse_with_air.outcome.text -->
It takes time. It takes all the steadiness you have. Gradually the sigils stop glowing. He slumps, then straightens. He looks at his hands, then at you. 'You have done this before,' he says. 'No,' you say. He considers this. 'Hm. I owe you a debt. How are you traveling?'
<!--@end-->


#### **perform_reversal** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_durvasa | choices.perform_reversal.text -->
Perform a proper reversal — unmake the binding through ceremony
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_durvasa | choices.perform_reversal.outcome.text -->
The curse unwrites itself, step by step. He exhales for the first time in what sounds like a very long time. 'Thorough,' he says. 'Methodical. I appreciate methodical.' He stands slowly. 'Whoever taught you that taught you well. I find myself without current employment. Are you taking work?'
<!--@end-->


#### **read_the_binding** — *yellow* — requires roll focus vs normal

<!--@ hungry_ghost_events.json | hg_durvasa | choices.read_the_binding.text -->
Try to read the binding — understand what you are dealing with
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_durvasa | choices.read_the_binding.outcome_success.text -->
A death-curse, reflected and internalized. He has been holding it in containment since it returned to him. 'How long?' you ask. He answers. You do not ask again. You sit across from him and begin talking through options. By the time the sigils fade, you are colleagues.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_durvasa | choices.read_the_binding.outcome_failure.text -->
You can see something is deeply wrong but not what. He watches you fail to understand with the patience of someone who has been sitting very still for a very long time.
<!--@end-->


---

## hg_gomchen

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_gomchen | title -->
The Contract Web
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_gomchen | text -->
In a monastery that has somehow persisted in the charnel grounds — crumbling but still standing, its prayer flags bleached to grey — a gyelpo meditates in the central hall. Carved into every surface around him: contracts. Obligation clauses. Reciprocal bindings. The accumulated leverage of a long political career, frozen in stone. He sits in the center of it with his eyes slightly open.
<!--@end-->


### Choices


#### **leave_him** — *grey*

<!--@ hungry_ghost_events.json | hg_gomchen | choices.leave_him.text -->
Leave him to his contracts
<!--@end-->


*Outcome*

`karma: hell+1`

<!--@ hungry_ghost_events.json | hg_gomchen | choices.leave_him.outcome.text -->
The hall is silent except for the slow erosion of stone.
<!--@end-->


#### **dissolve_the_binding** — *blue* — requires sorcery 3

<!--@ hungry_ghost_events.json | hg_gomchen | choices.dissolve_the_binding.text -->
Dissolve the primary binding — force the keystone obligation apart
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: human+3`

<!--@ hungry_ghost_events.json | hg_gomchen | choices.dissolve_the_binding.outcome.text -->
The stone cracks. The inscription flakes. He exhales slowly. 'I felt that.' The rest of the web loosens by degrees. He opens his eyes fully. 'You have just made me more dangerous. I hope you know what you are doing.' He stands, after effort. 'I owe you a debt. I prefer to pay them personally.'
<!--@end-->


#### **read_obligations_back** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_gomchen | choices.read_obligations_back.text -->
Read the obligations back to him — enumerate the full cost of what he is holding
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: human+4`

<!--@ hungry_ghost_events.json | hg_gomchen | choices.read_obligations_back.outcome.text -->
You read them back slowly. Each one. He is very still. When you finish, the hall is quiet. 'I know,' he says. 'Say it again. Slower.' You do. When you finish the second time, something changes in his face. 'I have been very foolish,' he says quietly. 'Will you walk with me? I need to think outside these walls.'
<!--@end-->


#### **oath_keeper_offers** — *blue* — requires **trait: oath_keeper**  **NEW**

<!--@ hungry_ghost_events.json | hg_gomchen | choices.oath_keeper_offers.text -->
Offer to hold one of them. You are good for it.
<!--@end-->


*Outcome*

`xp: 20  ·  add_trait: oath_keeper  ·  pressure: earth+15`

<!--@ hungry_ghost_events.json | hg_gomchen | choices.oath_keeper_offers.outcome.text -->
You take one obligation off the web — the smallest, and even the smallest is heavier than it looks — and the gomchen watches you accept it with an expression that has not been used in a long time.

You will keep it. That was never in question, which is precisely why it could be offered.
<!--@end-->


#### **find_the_keystone** — *yellow* — requires roll awareness vs difficult

<!--@ hungry_ghost_events.json | hg_gomchen | choices.find_the_keystone.text -->
Study the contract web — try to find the obligation everything else depends on
<!--@end-->


*Outcome — success*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: human+2`

<!--@ hungry_ghost_events.json | hg_gomchen | choices.find_the_keystone.outcome_success.text -->
You find it — a debt of precedence, buried under thirty layers of mutual obligation. You point to it without speaking. His eyes focus for the first time. 'You see it,' he says. 'No one has seen it.' A long pause. 'Then you are someone worth traveling with. Come.'
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_gomchen | choices.find_the_keystone.outcome_failure.text -->
The web is too complex. Everything connects to everything else. He watches you fail to find the thread without expression.
<!--@end-->


---

## hg_bog_hermit

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bog_hermit | title -->
Bog Hermit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bog_hermit | text -->
A gaunt figure crouches in the reed beds, sorting through bundles of grey-green herbs with practiced hands. It is alive — or near enough to count. It looks up without alarm.

"You find herbs growing in the shade," it says by way of greeting, as if this explains everything. It holds up a sprig of something. "Helps with the rot. Mostly."
<!--@end-->


### Choices


#### **ask_herbs** — *grey*

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.ask_herbs.text -->
Ask what the herbs are for
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4  ·  items: ['herb_bundle']`

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.ask_herbs.outcome.text -->
"Keep the living alive. Slow the dead down. Somewhere in between there's a tea that tastes almost good." It hands you a bundle without ceremony. You take it.
<!--@end-->


#### **medicine_check** — *blue* — requires medicine 2

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.medicine_check.text -->
Discuss the pharmacopoeia of the dead realm
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 14`

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.medicine_check.outcome.text -->
You name what you recognise. The hermit corrects you once, with precision, then settles into a real conversation — the first, you suspect, it has had in some time. You leave knowing more than you arrived with.
<!--@end-->


#### **yoga_meditation** — *blue* — requires yoga 1

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.yoga_meditation.text -->
Sit with it a while — you have nowhere better to be
<!--@end-->


*Outcome*

`karma: god+4, human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.yoga_meditation.outcome.text -->
You sit. The hermit works. The bog makes its sounds. After a long silence it says: "Most people run through here." Another silence. "Thank you for not running."
<!--@end-->


#### **trade** — *grey*

<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.trade.text -->
Ask if it trades
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_bog_hermit | choices.trade.outcome.text -->
"I trade in knowledge, mostly. I already have everything else I need." It gestures at the grey sky, the toxic water, the rustling reeds. It seems to mean it. You move on.
<!--@end-->


---

## hg_corpse_merchant

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_corpse_merchant | title -->
Corpse Merchant
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_corpse_merchant | text -->
A broad figure in a waxed coat stands over a cart heaped with cloth-wrapped bundles, sealed jars, and objects you decline to examine closely. Its face is partially masked. It does not smell good, but it has clearly made peace with this.

"Everything recovered in good condition," it says. "Relative condition. Relative good."
<!--@end-->


### Choices


#### **browse** — *grey*

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.browse.text -->
Browse the goods
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_bone_merchant  ·  karma: human+1`

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.browse.outcome.text -->

<!--@end-->


#### **ask_origin** — *grey*

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.ask_origin.text -->
Ask where the goods come from
<!--@end-->


*Outcome*

`xp: 3`

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.ask_origin.outcome.text -->
"The dead leave things behind. I collect them. Consider it a service." A pause. "To commerce. Also arguably to the dead. They weren't using it."
<!--@end-->


#### **trade_haggle** — *blue* — requires trade 3

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.trade_haggle.text -->
Haggle — this is salvage, not retail
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 6  ·  gold: 20`

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.trade_haggle.outcome.text -->
You explain the theory of salvage pricing. The merchant listens with professional attention and adjusts its margins. "Fair. You know the trade." The discount is modest but genuine.
<!--@end-->


#### **rob** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.rob.text -->
Pocket something while it looks away
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+4  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.rob.outcome_success.text -->
The merchant turns to re-tie a bundle. In the gap, your hand moves. You're three paces gone before it straightens up. It doesn't seem to notice — or doesn't care. Possibly both.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: demon_patrol  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_corpse_merchant | choices.rob.outcome_failure.text -->
The merchant doesn't turn around. "I can smell the living," it says. "I can smell them reaching." It produces a heavy implement from the cart.
<!--@end-->


---

## hg_preta_wail

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_preta_wail | title -->
The Wailing
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_preta_wail | text -->
A chorus of voices rises from just beneath the waterline — hungry ghosts calling out in a language that is not quite sound. The words, if words they are, convey only need.
<!--@end-->


### Choices


#### **press_on** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.press_on.text -->
Press on, ignoring the calls
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_preta_wail | choices.press_on.outcome.text -->
Nothing reaches you. The voices fade behind you.
<!--@end-->


#### **listen** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.listen.text -->
Listen carefully — try to understand
<!--@end-->


*Outcome — success*

`xp: 30  ·  buffs: [{'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.listen.outcome_success.text -->
One voice becomes distinct. A name. Something that mattered, once, somewhere.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}`

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.listen.outcome_failure.text -->
The need fills your mind for a moment. Hollow.
<!--@end-->


#### **yoga_mantra** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.yoga_mantra.text -->
Chant a mantra of compassion for them
<!--@end-->


*Outcome*

`karma: human+2, hungry_ghost-2  ·  xp: 32`

<!--@ hungry_ghost_events.json | hg_preta_wail | choices.yoga_mantra.outcome.text -->
The voices quiet, one by one. It doesn't solve anything. It might help anyway.
<!--@end-->


---

## hg_will_o_wisp

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_will_o_wisp | title -->
Will-o'-Wisp
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_will_o_wisp | text -->
A faint light dances ahead, moving just fast enough to stay out of reach. It has no face — just a glow, and an implied direction.
<!--@end-->


### Choices


#### **let_drift** — *grey*

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.let_drift.text -->
Let it drift away
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.let_drift.outcome.text -->
You watch it go. It doesn't look back.
<!--@end-->


#### **follow** — *yellow* — requires roll finesse vs easy

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.follow.text -->
Follow it
<!--@end-->


*Outcome — success*

`xp: 12  ·  items: ['water_charm_common']`

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.follow.outcome_success.text -->
It leads you to a dry patch of ground, then vanishes. Something is buried just beneath the surface.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}`

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.follow.outcome_failure.text -->
You step wrong. Bog, not ground. You pull yourself out soaked.
<!--@end-->


#### **recognize_spirit** — *blue* — requires air_magic 3, space_magic 3

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.recognize_spirit.text -->
Recognize it as a trapped spirit
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 35  ·  buffs: [{'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_will_o_wisp | choices.recognize_spirit.outcome.text -->
You know this pattern. A soul caught between awareness and dissolution. You speak the syllable that releases it. It brightens, briefly, then goes out.
<!--@end-->


---

## hg_swamp_spirit

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_swamp_spirit | title -->
Swamp Spirit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_swamp_spirit | text -->
A translucent figure stands ankle-deep in still water across a narrow channel. It watches you with the expression of someone who has forgotten where they were going.
<!--@end-->


### Choices


#### **wave_continue** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.wave_continue.text -->
Wave and continue
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.wave_continue.outcome.text -->
It raises a hand in response. You don't look back.
<!--@end-->


#### **speak_gently** — *yellow* — requires roll charm vs trivial

<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.speak_gently.text -->
Speak to it gently — ask if it needs help
<!--@end-->


*Outcome — success*

`karma: human+2  ·  buffs: [{'stat': 'strength', 'amount': 2, 'combats_remaining': 1}, {'stat': 'constitution', 'amount': 2, 'combats_remaining': 1}, {'stat': 'finesse', 'amount': 2, 'combats_remaining': 1}, {'stat': 'focus', 'amount': 2, 'combats_remaining': 1}, {'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}, {'stat': 'luck', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.speak_gently.outcome_success.text -->
It doesn't answer in words, but something shifts. It presses a cold hand briefly to your forehead, then walks away into the mist.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.speak_gently.outcome_failure.text -->
It stares at you for a long moment, then sinks slowly into the water. You're not sure what you said wrong.
<!--@end-->


#### **offer_guidance** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.offer_guidance.text -->
Offer guidance toward liberation
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 45`

<!--@ hungry_ghost_events.json | hg_swamp_spirit | choices.offer_guidance.outcome.text -->
You know the practice for this. It takes most of an hour. The spirit becomes more present, then less, then gone — in the right direction.
<!--@end-->


---

## hg_bone_raft

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_raft | title -->
Bone Raft
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_raft | text -->
A crude raft of lashed femurs floats slowly past on the current. Something wrapped in waxed cloth sits in the middle. It's addressed to someone.
<!--@end-->


### Choices


#### **let_drift** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.let_drift.text -->
Let it drift by
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_bone_raft | choices.let_drift.outcome.text -->
Whoever it's for, it's not you.
<!--@end-->


#### **grab_it** — *yellow* — requires roll finesse vs trivial

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.grab_it.text -->
Grab it before it floats out of reach
<!--@end-->


*Outcome — success*

`xp: 8  ·  gold: small  ·  items: ['health_potion']`

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.grab_it.outcome_success.text -->
You snag it. The cloth is still dry inside.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}`

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.grab_it.outcome_failure.text -->
You lean too far. You get wet. The raft keeps going.
<!--@end-->


#### **read_address** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.read_address.text -->
Notice the name on the address — read it before it's gone
<!--@end-->


*Outcome*

`xp: 28  ·  flags: {'found_bone_raft_name': True}`

<!--@ hungry_ghost_events.json | hg_bone_raft | choices.read_address.outcome.text -->
You can't retrieve it. But you read the name. It means something, even if you're not sure what yet.
<!--@end-->


---

## hg_weeping_shrine

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_weeping_shrine | title -->
Weeping Shrine
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_weeping_shrine | text -->
A small shrine on a mud-island, half-sunk. Water seeps continuously from the cracks in the stone — it has been weeping so long the ground beneath is stained dark.
<!--@end-->


### Choices


#### **offering** — *grey*

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.offering.text -->
Make an offering and move on
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 15`

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.offering.outcome.text -->
The shrine accepts. The weeping continues.
<!--@end-->


#### **meditate** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.meditate.text -->
Meditate on what the shrine mourns
<!--@end-->


*Outcome — success*

`xp: 32  ·  buffs: [{'stat': 'awareness', 'amount': 3, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.meditate.outcome_success.text -->
The grief becomes specific. A name, a cause, an old loss. Understanding doesn't fix it, but understanding tends to be useful.
<!--@end-->


*Outcome — failure*

`karma: human+1  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.meditate.outcome_failure.text -->
Grief doesn't always explain itself. You sit with it anyway.
<!--@end-->


#### **pilgrim_stops_here_too** — *blue* — requires **trait: pilgrim**  **NEW**

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.pilgrim_stops_here_too.text -->
It is half-sunk and it is still a shrine.
<!--@end-->


*Outcome*

`karma: god+3, human+2  ·  xp: 20  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.pilgrim_stops_here_too.outcome.text -->
You wade out to it. This is unpleasant and takes some time and the party makes remarks.

What you find on the far side, above the waterline, is a carved instruction — brief, practical, and clearly meant for whoever cared enough to get that close.
<!--@end-->


#### **purify** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.purify.text -->
Perform a proper purification ceremony
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 28  ·  restore: {'hp_percent': 25}`

<!--@ hungry_ghost_events.json | hg_weeping_shrine | choices.purify.outcome.text -->
The weeping slows, then stops — for the first time in however long. The shrine feels lighter. So do you.
<!--@end-->


---

## hg_sacrifice_post

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_sacrifice_post | title -->
Sacrifice Post
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_sacrifice_post | text -->
A wooden post driven into the mud, hung with trinkets, cloth strips, dried flowers. The offerings are from multiple eras — some ancient, some recent. Whatever this appeases, it is still being appeased.
<!--@end-->


### Choices


#### **small_offering** — *grey*

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.small_offering.text -->
Add something small to the post
<!--@end-->


*Outcome*

`karma: human+1, god+1  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.small_offering.outcome.text -->
It costs you almost nothing.
<!--@end-->


#### **identify** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.identify.text -->
Try to identify what this protects against
<!--@end-->


*Outcome — success*

`xp: 22  ·  buffs: [{'stat': 'dodge', 'amount': 10, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.identify.outcome_success.text -->
You piece it together from the nature of the offerings. The swamp has teeth, and this is how the locals have been keeping them dull.
<!--@end-->


*Outcome — failure*

`karma: human+1  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.identify.outcome_failure.text -->
Folk magic doesn't always leave notes. You make a small offering anyway.
<!--@end-->


#### **take_charms** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.take_charms.text -->
Take several of the more potent-looking charms
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, human-2  ·  xp: 8  ·  items: ['black_charm_common', 'water_charm_common']`

<!--@ hungry_ghost_events.json | hg_sacrifice_post | choices.take_charms.outcome.text -->
They're not yours to take, but they're functional.
<!--@end-->


---

## hg_funeral_rites

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_funeral_rites | title -->
Funeral Rites
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_funeral_rites | text -->
A skeleton sits beside a crumbling grave, methodically arranging offerings — flowers long since turned to dust, fruit that is only the shape of fruit. It works without hurry, with complete attention.
<!--@end-->


### Choices


#### **dont_disturb** — *grey*

<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.dont_disturb.text -->
Don't disturb it
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.dont_disturb.outcome.text -->
Some things should be left alone. You pass at a respectful distance.
<!--@end-->


#### **watch** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.watch.text -->
Watch what it is arranging — try to understand
<!--@end-->


*Outcome — success*

`xp: 35  ·  buffs: [{'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.watch.outcome_success.text -->
You recognize the pattern. Old funeral rites, obscure but correct. Someone taught this skeleton well.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.watch.outcome_failure.text -->
You shift your weight. A branch snaps. The skeleton freezes. You hold your breath. Then it continues, ignoring you entirely.
<!--@end-->


#### **help_rites** — *blue* — requires yoga 3, ritual 3

<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.help_rites.text -->
Kneel and help perform the rites correctly
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 40  ·  restore: {'hp_percent': 20}  ·  add_trait: mourner`

<!--@ hungry_ghost_events.json | hg_funeral_rites | choices.help_rites.outcome.text -->
It turns to look at you when you kneel. A long pause. Then it extends a handful of dust-flowers toward you, and together you finish the ceremony.
<!--@end-->


---

## hg_memory_echo

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_memory_echo | title -->
Memory Echo
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_memory_echo | text -->
A shimmer in the graveyard air, like heat haze — but it's cold here. For a moment you see a family at a meal. Vivid, fully real. Then gone, leaving only the smell of food that isn't there.
<!--@end-->


### Choices


#### **move_on** — *grey*

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.move_on.text -->
Blink and move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_memory_echo | choices.move_on.outcome.text -->
Some things are just residue of lives. You don't need to understand every one.
<!--@end-->


#### **hold_vision** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.hold_vision.text -->
Hold the vision — try to understand who they were
<!--@end-->


*Outcome — success*

`xp: 40  ·  buffs: [{'stat': 'spellpower', 'amount': 3, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.hold_vision.outcome_success.text -->
A life becomes briefly comprehensible. The attachment, the warmth, and what happened to it.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}`

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.hold_vision.outcome_failure.text -->
The hunger in the image reaches you before the meaning does. You feel it in your chest for an hour.
<!--@end-->


#### **study_echo** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.study_echo.text -->
Study the echo's magical structure
<!--@end-->


*Outcome*

`karma: hungry_ghost+1  ·  xp: 20  ·  buffs: [{'stat': 'focus', 'amount': 2, 'combats_remaining': 1}, {'stat': 'awareness', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_memory_echo | choices.study_echo.outcome.text -->
A well-preserved echo. Whoever imprinted it was powerful in life, and thoroughly unresolved.
<!--@end-->


---

## hg_skeleton_musician

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_skeleton_musician | title -->
Skeleton Musician
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_skeleton_musician | text -->
A skeleton sits on a gravestone, playing a two-stringed instrument with surprising skill. The music is slow and strange and not entirely unpleasant. It stops when it notices you.
<!--@end-->


### Choices


#### **nod_pass** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.nod_pass.text -->
Nod respectfully and pass
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.nod_pass.outcome.text -->
It watches you go. When you're far enough away, the music resumes.
<!--@end-->


#### **play_along** — *yellow* — requires roll charm vs trivial

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.play_along.text -->
Play along, or try to match the melody
<!--@end-->


*Outcome — success*

`karma: human+3  ·  xp: 22  ·  buffs: [{'stat': 'charm', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.play_along.outcome_success.text -->
It tilts its head at you, then picks up the tempo. You manage to follow. For a few minutes, in a graveyard in the hungry ghost realm, something like music happens.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.play_along.outcome_failure.text -->
Your contribution is not musically interesting. The skeleton watches you politely until you stop.
<!--@end-->


#### **sing** — *blue* — requires performance 3

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.sing.text -->
Sing for the musician
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 22  ·  buffs: [{'stat': 'charm', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.sing.outcome.text -->
It tilts its head at you, then picks up the tempo to match your voice. For a few minutes, in a graveyard in the hungry ghost realm, something like music happens.
<!--@end-->


#### **poet_answers_it** — *blue* — requires **trait: poet**  **NEW**

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.poet_answers_it.text -->
It is playing a form. Give it words.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: air+12, fire+8`

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.poet_answers_it.outcome.text -->
You put words to what it is playing, roughly and out of metre, and it stops dead for the length of a breath before picking the line back up underneath your voice.

You get through four verses. It has not had a singer in a very long time.
<!--@end-->


#### **comedy** — *blue* — requires comedy 3

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.comedy.text -->
Tell a joke
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 18  ·  items: ['air_charm_common']`

<!--@ hungry_ghost_events.json | hg_skeleton_musician | choices.comedy.outcome.text -->
It makes no sound. But the jaw moves, and the ribcage shakes, and the instrument ends up upright and the musician hunched over it in a posture that can only be described as helpless.
<!--@end-->


---

## hg_dust_storm

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_dust_storm | title -->
Dust Storm
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_dust_storm | text -->
A wall of bone-dry grit sweeps across the graveyard with no warning. There's nowhere to shelter. You're going to take this one.
<!--@end-->


### Choices


#### **push_through** — *grey*

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.push_through.text -->
Push through
<!--@end-->


*Outcome*

`hp_loss: {'amount': 'light', 'target': 'all'}  ·  buffs: [{'stat': 'constitution', 'amount': -2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.push_through.outcome.text -->
You bow your head and walk. It gets in everywhere.
<!--@end-->


#### **brace_or_dodge** — *yellow* — requires roll constitution vs easy

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.brace_or_dodge.text -->
Brace against it — or dodge the worst of it
<!--@end-->


*Outcome — success*


<!--@ hungry_ghost_events.json | hg_dust_storm | choices.brace_or_dodge.outcome_success.text -->
You turn your back, cover your face, wait it out. It passes.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}  ·  buffs: [{'stat': 'constitution', 'amount': -2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.brace_or_dodge.outcome_failure.text -->
It's worse than you thought.
<!--@end-->


#### **earth_windbreak** — *blue* — requires earth_magic 3

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.earth_windbreak.text -->
Raise a wind-break with earth magic
<!--@end-->


*Outcome*

`xp: 10  ·  buffs: [{'stat': 'constitution', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_dust_storm | choices.earth_windbreak.outcome.text -->
A low ridge of packed earth takes the worst of it. You emerge into clear air already reforming your thoughts about dry graveyards.
<!--@end-->


---

## hg_dancing_dead

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_dancing_dead | title -->
The Dancing Dead
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_dancing_dead | text -->
A ring of corpses dances in perfect silence around an empty throne. Their movements are stiff but coordinated, as if memory persists where intention does not. They do not appear to notice you.
<!--@end-->


### Choices


#### **slip_past** — *grey*

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.slip_past.text -->
Slip past the outer edge carefully
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.slip_past.outcome.text -->
Whatever they are celebrating, or mourning, continues without you.
<!--@end-->


#### **join_ring** — *yellow* — requires roll finesse vs easy

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.join_ring.text -->
Join the ring — dance with them
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+2  ·  xp: 18  ·  buffs: [{'stat': 'finesse', 'amount': 2, 'combats_remaining': 1}, {'stat': 'luck', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.join_ring.outcome_success.text -->
Your body finds the rhythm. For a moment you are part of something very old and very strange. When the dance ends, you are on the other side of the ring.
<!--@end-->


*Outcome — failure*


<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.join_ring.outcome_failure.text -->
You misstep. The ring shifts. They look at you all at once. Then, somehow worse, they resume — leaving you outside it.
<!--@end-->


#### **celebrant_watches_kindly** — *blue* — requires **trait: celebrant**  **NEW**

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.celebrant_watches_kindly.text -->
Let them have it. Watch properly.
<!--@end-->


*Outcome*

`karma: hungry_ghost-4  ·  xp: 20  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.celebrant_watches_kindly.outcome.text -->
They are dancing around an absence and they are doing it in total silence and they have clearly been doing it a long time.

You watch it through rather than past, which nobody has done, and at the end one of them bows to you specifically.
<!--@end-->


#### **complete_ritual** — *blue* — requires ritual 3, performance 3

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.complete_ritual.text -->
Recognize the ceremony and complete your part
<!--@end-->


*Outcome*

`karma: human+2, hungry_ghost+2  ·  xp: 45`

<!--@ hungry_ghost_events.json | hg_dancing_dead | choices.complete_ritual.outcome.text -->
This is a specific ceremony. You've seen fragments of it. You take the empty throne, perform your part. When you rise, the dance resolves — the figures slow, then still, with something like satisfaction.
<!--@end-->


---

## hg_spirit_fire

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_spirit_fire | title -->
Spirit Fires
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_spirit_fire | text -->
Three fires burn without fuel at the edge of the charnel grounds. One is pale blue, one is deep green, one is a colour that doesn't have a name. None of them give off heat.
<!--@end-->


### Choices


#### **walk_around** — *grey*

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.walk_around.text -->
Walk around them
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.walk_around.outcome.text -->
They seem to watch you go — or seem to.
<!--@end-->


#### **study** — *yellow* — requires roll awareness vs easy

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.study.text -->
Approach and study them
<!--@end-->


*Outcome — success*

`xp: 20  ·  buffs: [{'stat': 'spellpower', 'amount': 3, 'combats_remaining': 1}, {'stat': 'focus', 'amount': 2, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.study.outcome_success.text -->
Each one is a distinct consciousness, in the earliest stage of what might become a ghost or might become something else. You learn something from how they burn.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'light', 'target': 'all'}`

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.study.outcome_failure.text -->
The nameless-coloured one flares. The heat is not physical. You step back.
<!--@end-->


#### **elemental_study** — *blue* — requires fire_magic 3, sorcery 3

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.elemental_study.text -->
Understand their elemental nature
<!--@end-->


*Outcome*

`xp: 35  ·  items: ['fire_charm_common']`

<!--@ hungry_ghost_events.json | hg_spirit_fire | choices.elemental_study.outcome.text -->
Three elements, one process. You spend time with each one, and each one teaches you something.
<!--@end-->


---

## hg_charnel_feast

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_charnel_feast | title -->
Charnel Feast
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_charnel_feast | text -->
A long table laid out in the open, covered in a feast that looks perfect and smells wrong. Seated pretas reach for food endlessly — it passes through without satisfying anything. The table is infinite. The hunger is infinite. Neither notices you standing at the edge.
<!--@end-->


### Choices


#### **turn_away** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.turn_away.text -->
Turn away quickly
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.turn_away.outcome.text -->
The right call.
<!--@end-->


#### **eat_anyway** — *yellow* — requires roll constitution vs normal

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.eat_anyway.text -->
Eat anyway — you're hungry, and it looks real enough
<!--@end-->


*Outcome — success*

`supplies: {'food': 2}  ·  restore: {'hp_percent': 30}  ·  add_trait: haunted`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.eat_anyway.outcome_success.text -->
It's real enough. Strange but real. It sits wrong for an hour, then doesn't.
<!--@end-->


*Outcome — failure*

`hp_loss: {'amount': 'moderate', 'target': 'all'}  ·  buffs: [{'stat': 'constitution', 'amount': -3, 'combats_remaining': 1}]`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.eat_anyway.outcome_failure.text -->
You understand, briefly and completely, what it is like to need something and have it provide nothing at all.
<!--@end-->


#### **yoga_observe** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.yoga_observe.text -->
Sit with the nature of what you're seeing
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost-3  ·  xp: 55  ·  buffs: [{'stat': 'focus', 'amount': 3, 'combats_remaining': 1}]  ·  add_trait: clear_eyed`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.yoga_observe.outcome.text -->
You observe the feast without hunger. The pretas slow, one by one, and watch you — the strange creature at the edge of the table who is not reaching. Something about this interests them.
<!--@end-->


#### **ascetic_unmoved** — *blue* — requires **trait: ascetic**  **NEW**

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.ascetic_unmoved.text -->
You have been hungrier than this on purpose.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+15`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.ascetic_unmoved.outcome.text -->
You look at the table the way you look at any table, which is to say briefly.

Whatever laid it was counting on the wanting, and there is not enough of that in you to work with. The hall loses interest and the food stops being convincing halfway down the table.
<!--@end-->


#### **gourmand_tempted** — *blue* — requires **trait: gourmand**  **NEW**

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.gourmand_tempted.text -->
You can tell from here that the lamb is done properly.
<!--@end-->


*Outcome*

`xp: 30  ·  hp_loss: {'amount': 'light', 'target': 'random'}  ·  pressure: fire-12`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.gourmand_tempted.outcome.text -->
You can. That is the trouble — it is not a general temptation, it is a specific and extremely well-observed one, and something went to the effort of knowing what you would want.

You eat one mouthful before the party gets you away from the table. One is enough to be unwell for a day.
<!--@end-->


#### **steal_candleholders** — *blue* — requires thievery 3

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.steal_candleholders.text -->
Pocket the gold candleholders — they look real
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, human-2  ·  xp: 8  ·  gold: moderate`

<!--@ hungry_ghost_events.json | hg_charnel_feast | choices.steal_candleholders.outcome.text -->
They are real. Everything solid about this table is real.
<!--@end-->


---

## hg_sigh_of_relief

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_sigh_of_relief | title -->
A Sigh of Relief
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_sigh_of_relief | text -->
A small cairn with a folded cloth on top. Written in a careful hand: "You are not as lost as you feel."
<!--@end-->


### Choices


#### **read_move_on** — *grey*

<!--@ hungry_ghost_events.json | hg_sigh_of_relief | choices.read_move_on.text -->
Read it. Move on.
<!--@end-->


*Outcome*

`karma: human+1  ·  xp: 8  ·  restore: {'hp_percent': 15, 'mana_percent': 15}  ·  add_trait: touched_by_grace`

<!--@ hungry_ghost_events.json | hg_sigh_of_relief | choices.read_move_on.outcome.text -->
You are not as lost as you feel.
<!--@end-->


---

## hg_black_lodge

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_black_lodge | title -->
Black Lodge
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_black_lodge | text -->
A mound of bones marks the entrance, a khatvanga hung with a skull and streaming black silk. As you enter, the darkness swallows sound. Something in the corner shifts — it may not be fully alive. A slow turn. A waiting smile.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_black_lodge | choices.[0].text -->
Ask to learn
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_black_lodge`

<!--@ hungry_ghost_events.json | hg_black_lodge | choices.[0].outcome.text -->
The movement stills. A bony hand gestures to a list scratched into the wall. Spells. Prices. No explanation offered.
<!--@end-->


#### **secret_bearer_admitted** — *blue* — requires **trait: secret_bearer**  **NEW**

<!--@ hungry_ghost_events.json | hg_black_lodge | choices.secret_bearer_admitted.text -->
Say nothing at the door. That is the password.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_black_lodge | choices.secret_bearer_admitted.outcome.text -->
It is. You are inside before you have decided whether you wanted to be, and what is discussed there is not written down anywhere, including here.
<!--@end-->


#### **[2]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_black_lodge | choices.[2].text -->
Back out
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_black_lodge | choices.[2].outcome.text -->
You step back into the pale light. The khatvanga watches you leave.
<!--@end-->


---

## hg_yogini_circle

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_yogini_circle | title -->
Circle of the Yoginis
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_yogini_circle | text -->
Sixty-four forms carved into standing bones form a perfect ring on the charnel ground. The earth inside is worn smooth by countless ritual footprints. A low humming comes from the center — women's voices, or something passing for them.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_yogini_circle | choices.[0].text -->
Enter the circle
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_circle_of_yoginis`

<!--@ hungry_ghost_events.json | hg_yogini_circle | choices.[0].outcome.text -->
One of the sisters turns. No words — a gesture toward the center of the ring. What do you need?
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_yogini_circle | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_yogini_circle | choices.[1].outcome.text -->
You back away slowly. The humming follows you longer than it should.
<!--@end-->


---

## hg_crossroads_stupa

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_crossroads_stupa | title -->
Crossroads Stupa
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_crossroads_stupa | text -->
At the intersection of the ancient paths, a stupa rises from layers of offerings — skulls, prayer flags, bones wrapped in cloth. Juniper smoke and the smell of old offerings drift on the wind. A practitioner crouches behind the stupa, neither fully alive nor fully dead.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_crossroads_stupa | choices.[0].text -->
Approach the stupa
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_crossroads_stupa`

<!--@ hungry_ghost_events.json | hg_crossroads_stupa | choices.[0].outcome.text -->
The figure looks up. The crossroads is the right place for calling back what is lost. The price is gold.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_crossroads_stupa | choices.[1].text -->
Observe from a distance
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_crossroads_stupa | choices.[1].outcome.text -->
You watch the butter lamps flicker in the wind, then walk on. Some things are better left undisturbed.
<!--@end-->


---

## hg_hidden_gompa

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_hidden_gompa | title -->
Hidden Gompa
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_hidden_gompa | text -->
A small monastery sits undisturbed between the burial grounds, its walls marked with painted eyes that seem to follow you. The monks here practice for the benefit of all beings caught between lives. The ground vibrates faintly with their prayers.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_hidden_gompa | choices.[0].text -->
Knock and ask to enter
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_hidden_gompa`

<!--@ hungry_ghost_events.json | hg_hidden_gompa | choices.[0].outcome.text -->
After a long pause, the door opens. A monk gestures you inside and names what can be taught here — and the price.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_hidden_gompa | choices.[1].text -->
Don't disturb them
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_hidden_gompa | choices.[1].outcome.text -->
You walk past without knocking. The painted eyes seem to close behind you.
<!--@end-->


---

## hg_mirror_lake

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mirror_lake | title -->
Mirror Lake
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mirror_lake | text -->
The surface of the lake is perfectly still, reflecting not the sky above but something else — other realms, other moments, faces that do not look back when you stare. Practitioners sit at its edge, meditating on what the water reveals.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_mirror_lake | choices.[0].text -->
Sit and listen
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_mirror_lake`

<!--@ hungry_ghost_events.json | hg_mirror_lake | choices.[0].outcome.text -->
A practitioner meets your eyes in the reflection before turning around. They can teach what the lake teaches. The water makes everything a fair price.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_mirror_lake | choices.[1].text -->
Walk away from the mirage
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_mirror_lake | choices.[1].outcome.text -->
You step back from the water's edge. The reflection holds your shape a moment longer, then dissolves.
<!--@end-->


---

## hg_sacred_grove

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_sacred_grove | title -->
Sacred Grove
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_sacred_grove | text -->
A stand of ancient trees whose roots grow through charnel earth. The branches are hung with offerings of food — the hungry ghosts who press at the edge of the grove can smell them but cannot eat. Practitioners move among the roots, speaking to both the living and the dead.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_sacred_grove | choices.[0].text -->
Approach the practitioners
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_sacred_grove`

<!--@ hungry_ghost_events.json | hg_sacred_grove | choices.[0].outcome.text -->
One of the practitioners turns. She names what can be taught here, and then the price. Gold is gold in every realm.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_sacred_grove | choices.[1].text -->
Leave them to it
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_sacred_grove | choices.[1].outcome.text -->
You walk on. The smell of offerings follows you through the trees.
<!--@end-->


---

## hg_temple_of_the_naga

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | title -->
Temple of the Naga
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | text -->
A low temple built around a black-water pool. The nagas who dwell in such pools are guardians of the dead, and their human followers leave milk offerings at the water's edge. A practitioner sits cross-legged on the stone, eyes closed, lips moving.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | choices.[0].text -->
Ask about their teachings
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_temple_of_the_naga`

<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | choices.[0].outcome.text -->
The practitioner opens her eyes. She names the spells the nagas have permitted to be taught here, and the price. It is not cheap.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_temple_of_the_naga | choices.[1].outcome.text -->
You leave the offerings undisturbed. The pool surface ripples once as you go.
<!--@end-->


---

## hg_mercenary_guild

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_mercenary_guild | title -->
Mercenary Guild
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_mercenary_guild | text -->
A walled compound marked with the crossed-bone sigil of the guild. Skeletal warriors and half-dead fighters linger between contracts, sharpening weapons they barely need to use anymore.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_mercenary_guild | choices.[0].text -->
Enter the guild
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_mercenary_guild`

<!--@ hungry_ghost_events.json | hg_mercenary_guild | choices.[0].outcome.text -->
The guildmaster looks you over without interest. Weapons, armor, contracts — name what you need.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_mercenary_guild | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_mercenary_guild | choices.[1].outcome.text -->
You leave the compound to its dead-eyed inhabitants.
<!--@end-->


---

## hg_peddler_graveyard

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_peddler_graveyard | title -->
Wandering Preta
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_peddler_graveyard | text -->
A preta wanders between the grave markers, its distended belly dragging, desperate hands clutching bundles of goods. It will trade anything for food — though it can never eat enough to be satisfied.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_peddler_graveyard | choices.[0].text -->
Trade with the preta
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_wandering_preta`

<!--@ hungry_ghost_events.json | hg_peddler_graveyard | choices.[0].outcome.text -->
The preta's needle-thin neck cranes toward you, eyes fixed on your pack. It lays its goods on a grave marker and waits.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_peddler_graveyard | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_peddler_graveyard | choices.[1].outcome.text -->
You give the preta a wide berth. It watches you go with hollow, hungry eyes.
<!--@end-->


---

## hg_peddler_swamp

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_peddler_swamp | title -->
Wandering Preta
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_peddler_swamp | text -->
A preta rises from the mist at the water's edge, its needle-thin neck craning as it senses your approach. Desperate hands clutch wares salvaged from the swamp floor. It will trade anything for food.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_peddler_swamp | choices.[0].text -->
Trade with the preta
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_wandering_preta`

<!--@ hungry_ghost_events.json | hg_peddler_swamp | choices.[0].outcome.text -->
The preta spreads its goods on a half-submerged log and regards you with hollow, hopeful eyes.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_peddler_swamp | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_peddler_swamp | choices.[1].outcome.text -->
You leave it to the mist. Its eyes follow you until the fog closes in.
<!--@end-->


---

## hg_teahouse_charnel

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_teahouse_charnel | title -->
Charnel Teahouse
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_teahouse_charnel | text -->
A lantern glows faintly above a low doorway carved into a wall of stacked bone. Inside, a quiet figure brews tea from dried flowers that grow only on graves. The dead do not drink, but the living are welcome.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_charnel | choices.[0].text -->
Step inside
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_teahouse`

<!--@ hungry_ghost_events.json | hg_teahouse_charnel | choices.[0].outcome.text -->
The figure pours without looking up. You can rest here — if you can afford it.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_charnel | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_teahouse_charnel | choices.[1].outcome.text -->
You leave the lantern light behind. The scent of grave-flowers follows you a while.
<!--@end-->


---

## hg_teahouse_graveyard

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | title -->
Graveyard Teahouse
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | text -->
A small dwelling built into the side of an old burial mound, its entrance marked with a hanging lantern and a painted sign no longer legible. Someone has been serving tea here for a very long time.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | choices.[0].text -->
Step inside
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_teahouse`

<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | choices.[0].outcome.text -->
The host gestures to a low table. The tea is bitter and dark. You can rest here — if you can afford it.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_teahouse_graveyard | choices.[1].outcome.text -->
You leave the mound behind. The lantern swings in a wind you can't feel.
<!--@end-->


---

## hg_teahouse_swamp

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_teahouse_swamp | title -->
Swamp Teahouse
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_teahouse_swamp | text -->
A teahouse built on stilts above the swamp water, its light the only warmth for miles. A rope bridge leads to the door. Someone is already watching you from the window.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_swamp | choices.[0].text -->
Cross the bridge
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_teahouse`

<!--@ hungry_ghost_events.json | hg_teahouse_swamp | choices.[0].outcome.text -->
The host sets a cup on the table before you sit. You can rest here — if you can afford it.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_teahouse_swamp | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_teahouse_swamp | choices.[1].outcome.text -->
You leave the light behind. The swamp closes around you.
<!--@end-->


---

## hg_town_magic

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_town_magic | title -->
Town
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_town_magic | text -->
A settlement where more windows glow than can be explained by candlelight. Strange smells drift from the apothecary. A practitioner argues with a vetala outside the library, and neither seems to have the better of it.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_magic | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_magic`

<!--@ hungry_ghost_events.json | hg_town_magic | choices.[0].outcome.text -->
You find the market square. The odd merchants eye you with professional interest.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_magic | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_town_magic | choices.[1].outcome.text -->
You leave the scholars to their arguments. The strange lights fade behind you.
<!--@end-->


---

## hg_town_supplies

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_town_supplies | title -->
Town
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_town_supplies | text -->
A trading post built among the graves, supplies scavenged from the dead and traded among the half-living. The market is quiet but well-stocked — necessity makes practical merchants of everyone here.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_supplies | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_supplies`

<!--@ hungry_ghost_events.json | hg_town_supplies | choices.[0].outcome.text -->
You push through to the market. Traders call out their wares in dry, patient voices.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_supplies | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_town_supplies | choices.[1].outcome.text -->
You skirt the settlement and keep moving.
<!--@end-->


---

## hg_town_weapons

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_town_weapons | title -->
Town
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_town_weapons | text -->
A fortified compound where warriors trade blades and bones. The biggest building is an armory. Someone is always sharpening something, and the sound of whetstones never stops.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_weapons | choices.[0].text -->
Enter the town
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_town_weapons`

<!--@ hungry_ghost_events.json | hg_town_weapons | choices.[0].outcome.text -->
You push through the gate. The armorer looks up from their work.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_town_weapons | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_town_weapons | choices.[1].outcome.text -->
You skirt the compound and keep moving.
<!--@end-->


---

## hg_veterans_camp

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_veterans_camp | title -->
Veterans' Camp
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_veterans_camp | text -->
A camp of battle-scarred fighters who never left the ghost realm. Their fire has been burning since they arrived — they stopped counting how long ago. They still trade in the tools of their old trade.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_veterans_camp | choices.[0].text -->
Approach the camp
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_veterans_camp`

<!--@ hungry_ghost_events.json | hg_veterans_camp | choices.[0].outcome.text -->
A veteran looks up from the fire. Old fighters make fair merchants — they know what things are worth.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_veterans_camp | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_veterans_camp | choices.[1].outcome.text -->
You leave the veterans to their fire. It will still be burning when you pass this way again.
<!--@end-->


---

## hg_shadow_market

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_shadow_market | title -->
Shadow Market
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_shadow_market | text -->
A market that appears only between the grave stones, visible only to those who know how to look. The stalls are draped in dark cloth and the merchants keep their faces in shadow. Everything here was obtained quietly.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_shadow_market | choices.[0].text -->
Browse the stalls
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_black_market`

<!--@ hungry_ghost_events.json | hg_shadow_market | choices.[0].outcome.text -->
A shadowed hand gestures you deeper into the market. No questions asked, no names given.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_shadow_market | choices.[1].text -->
Move on
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_shadow_market | choices.[1].outcome.text -->
You step back. The market seems to thin and vanish between blinks.
<!--@end-->


---

## hg_shadow_peddler

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_shadow_peddler | title -->
Shadow Peddler
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_shadow_peddler | text -->
A hunched figure steps from behind a grave marker, face obscured beneath a ragged hood. Its voice is barely a whisper but its goods are real enough — things it has acquired in ways it declines to explain.
<!--@end-->


### Choices


#### **[0]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_shadow_peddler | choices.[0].text -->
See what it has
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_wandering_preta`

<!--@ hungry_ghost_events.json | hg_shadow_peddler | choices.[0].outcome.text -->
The figure spreads its goods on the grave stone between you. It wants food more than gold.
<!--@end-->


#### **[1]** — *grey*  **NEW**

<!--@ hungry_ghost_events.json | hg_shadow_peddler | choices.[1].text -->
Keep moving
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_shadow_peddler | choices.[1].outcome.text -->
You walk past without stopping. The figure watches you go, then is gone.
<!--@end-->


---

## hg_boss_insatiable_king  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | title -->
The Insatiable King
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | text -->
He sits on a throne of fused bone before the Realm Gate, a mountain of a preta — belly vast as a granary, throat thin as a needle. A thousand offering bowls lie scattered around him, every one licked clean and none of them enough.

"More," he says, and the word carries the weight of centuries. "Everything that passes this gate feeds me first. Wealth. Blood. Memory. What have you brought the King of Hunger?"
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.fight.text -->
Give him nothing — draw your weapon
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: insatiable_king  ·  difficulty: boss  ·  karma: hell+3, asura+5`

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.fight.outcome.text -->

<!--@end-->


#### **feast** — *grey*

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.feast.text -->
Lay out a feast from your own stores before the fight
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: insatiable_king_weakened  ·  difficulty: normal  ·  karma: human+5, hungry_ghost-3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.feast.outcome.text -->
He devours everything in moments — and for one heartbeat his eyes close, almost peaceful. When they open, the hunger is back, but slower. Heavier. He rises to fight without his court.
<!--@end-->


#### **sermon** — *blue* — requires white_magic 4

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.sermon.text -->
Speak the sutra of the open hand — hunger ends where giving begins
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: insatiable_king_weakened  ·  difficulty: normal  ·  karma: god+5, human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.sermon.outcome.text -->
The words land like rain on a fire that has burned for ten thousand years. His courtiers dissolve, wailing. The King alone remains, diminished, weeping — and still he attacks, because he no longer knows how to do anything else.
<!--@end-->


#### **liberate** — *blue* — requires yoga 6

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.liberate.text -->
Sit with him. Ask what he was, before the hunger
<!--@end-->


*Outcome*

`defeat_boss: True  ·  karma: god+10, human+5, hungry_ghost-10  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_boss_insatiable_king | choices.liberate.outcome.text -->
The question stops him like a blade. Slowly, haltingly, he remembers: a rich man who buried grain while his village starved, who died counting. You sit with the memory until he can hold it himself.

When he finally weeps, the tears are ordinary and human. The throne of bone crumbles. Where the King sat there is only an old man's shadow, bowing once before it fades. The gate stands open.
<!--@end-->


---

## hg_swamp_warden  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_swamp_warden | title -->
Swamp Warden
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_swamp_warden | text -->
The only dry crossing through the wall of thorn and mire is watched. A rolang ancient stands waist-deep in the black water, preserved by centuries of swamp tannin, carrion worms moving beneath its skin like slow thoughts.

It raises one dripping arm and points — not at you, but at the toll stone beside the path, hollowed like a begging bowl.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.fight.text -->
Cut it down and force the crossing
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: rotting_sentinel  ·  difficulty: hard  ·  karma: hell+3, asura+2`

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.fight.outcome.text -->

<!--@end-->


#### **toll** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.toll.text -->
Fill the toll stone with food and pass
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.toll.outcome.text -->
The worms boil out of the warden's body to swarm the offering. While the ancient stands hollowed and swaying, you walk the causeway unopposed.
<!--@end-->


#### **last_rites** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.last_rites.text -->
Perform the rites that should have been spoken over this corpse
<!--@end-->


*Outcome*

`karma: god+5, human+3, hungry_ghost-3  ·  xp: 15`

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.last_rites.outcome.text -->
You speak the old words and the warden goes very still. The worms leave it, one by one, sliding into the water. What remains is only a dead man, finally allowed to be dead, toppling softly into the reeds. The crossing is yours.
<!--@end-->


#### **wade** — *yellow* — requires roll constitution vs difficult

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.wade.text -->
Wade through the deep mire, out of its reach
<!--@end-->


*Outcome — success*

`karma: animal+3  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.wade.outcome_success.text -->
Chest-deep in rot, leeches at your ankles, you haul yourselves through the mire and up the far bank, shaking but past.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: rotting_sentinel  ·  difficulty: hard  ·  karma: hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_swamp_warden | choices.wade.outcome_failure.text -->
The mud holds you fast — and the warden comes wading.
<!--@end-->


---

## hg_bone_gate_keeper  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | title -->
Bone Gate Keeper
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | text -->
The pass through the ossuary wall runs beneath an arch of ten thousand fused skulls. Before it stands a skeleton formation in ancient parade order — warriors, archers, and at their center a bone horror wearing the rusted regalia of a gate captain.

Its jaw grinds open: "State. Your. Dead."
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.fight.text -->
Break the formation
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: hard  ·  karma: hell+3, asura+3`

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.fight.outcome.text -->

<!--@end-->


#### **name_dead** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.name_dead.text -->
Name your dead, honestly, one by one
<!--@end-->


*Outcome*

`karma: human+3, god+2, hungry_ghost+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.name_dead.outcome.text -->
You speak the names — companions lost, enemies slain, the lives that ended so you could stand here. The captain's skull tilts with each one, counting. When you finish, the formation parts with a sound like dry applause.
<!--@end-->


#### **command** — *blue* — requires black_magic 4

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.command.text -->
Command them in the tongue of the dead
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, hell+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.command.outcome.text -->
Your word of command cracks across the pass like a whip. The formation snaps to attention — and holds it, rigid, as you walk through their ranks. The captain's eye sockets track you the whole way.
<!--@end-->


#### **inspect** — *blue* — requires leadership 3

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.inspect.text -->
Return the salute and inspect the honor guard
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bone_horror  ·  difficulty: normal  ·  karma: asura+4, human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_bone_gate_keeper | choices.inspect.outcome.text -->
You walk the line like a visiting general. Halfway down the rank, the captain decides you are worth testing — but formation discipline binds most of its troops to their posts.
<!--@end-->


---

## hg_zombie_horde  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_zombie_horde | title -->
Zombie Horde
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_zombie_horde | text -->
They come out of the reeds in ones and twos and then in dozens — bog zombies, waterlogged and patient, drawn by whatever it is the living give off that the dead can smell.

There is no line to hold. There is only the direction with fewest of them in it.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.fight.text -->
Cut a path through
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: zombie_pack  ·  difficulty: hard  ·  karma: asura+3, hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.fight.outcome.text -->

<!--@end-->


#### **reeds** — *yellow* — requires roll constitution vs difficult

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.reeds.text -->
Go low into the reeds and let them pass over you
<!--@end-->


*Outcome — success*

`karma: animal+3  ·  xp: 14  ·  pressure: water-10`

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.reeds.outcome_success.text -->
Face-down in black water breathing through a reed while a hundred waterlogged feet go past inches from your ribs. It takes forty minutes. Nobody coughs. That is the whole achievement and it is enormous.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: zombie_pack  ·  difficulty: hard  ·  karma: hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.reeds.outcome_failure.text -->
Somebody's lungs give out. A head turns. Then all of them turn.
<!--@end-->


#### **firebreak** — *blue* — requires fire_magic 3

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.firebreak.text -->
Set the marsh gas alight behind you
<!--@end-->


*Outcome*

`karma: asura+3, hell+2  ·  xp: 18`

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.firebreak.outcome.text -->
There is more methane over this bog than anyone should stand in. You touch it off from the far side and the whole flat goes up in a low blue sheet. The horde does not so much burn as simply stop, mid-step, and keep standing there while the fire takes them. You are well clear. You watch longer than you meant to.
<!--@end-->


#### **release** — *blue* — requires white_magic 4

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.release.text -->
Sever what is holding them upright
<!--@end-->


*Outcome*

`karma: god+8, human+3  ·  xp: 24  ·  pressure: water+15`

<!--@ hungry_ghost_events.json | hg_zombie_horde | choices.release.outcome.text -->
Rolang are not animate by their own will — something keeps them walking, and it is thin here. You speak the release across the whole flat at once and the horde goes down in a long ragged wave, like a field of wheat. In the silence afterwards the swamp sounds almost ordinary.
<!--@end-->


---

## hg_swamp_toll  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_swamp_toll | title -->
Zombie Toll
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_swamp_toll | text -->
The causeway is the only dry ground for a mile, and four bog zombies stand across it in a row. They are not shambling. They are *waiting* — arranged, deliberate, with the stillness of a posted guard.

One of them holds out a swollen hand, palm up. It has been taught to do this.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.fight.text -->
Break the line
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: bog_zombie  ·  difficulty: normal  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.fight.outcome.text -->

<!--@end-->


#### **pay** — *grey*

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.pay.text -->
Put something in the hand
<!--@end-->


*Outcome*

`karma: hungry_ghost+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.pay.outcome.text -->
The fingers close. The four of them step aside in unison and resume waiting, facing the way you came. Somewhere in this swamp is whoever trained them, and you find you would rather not meet them.
<!--@end-->


#### **who_taught** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.who_taught.text -->
Follow the training back to whoever set this up
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost+2  ·  xp: 18  ·  gold: 40`

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.who_taught.outcome.text -->
The zombies are facing the causeway, but their heels are aligned to a stand of dead willow forty paces off. There is a rolang in it, very old, very still, running a toll booth in a swamp with four corpses and infinite patience. You negotiate directly. It turns out to be reasonable, and lonely, and it waives the fee for conversation.
<!--@end-->


#### **scrimper_wont** — *blue* — requires **trait: scrimper**

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.scrimper_wont.text -->
Four zombies and a causeway. Do the arithmetic out loud.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.scrimper_wont.outcome.text -->
You establish, at length, that the causeway is not theirs, that no work has been done to maintain it, and that the toll has no basis of any kind.

The zombies are not equipped for this argument. Two of them wander off during it.
<!--@end-->


#### **counterfeit** — *blue* — requires guile 3

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.counterfeit.text -->
Pay with something that is not money
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, animal+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_swamp_toll | choices.counterfeit.outcome.text -->
You press a flat river stone into the swollen palm with great ceremony. The fingers close on it. Whatever instruction these four are running does not include an assay step. They step aside. You cross the causeway feeling both clever and slightly cheap.
<!--@end-->


---

## hg_rotting_bridge  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_rotting_bridge | title -->
Rotting Bridge
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_rotting_bridge | text -->
The bridge is the only crossing for miles and it has been rotting for longer than that. Half the planks are gone; the rest are the colour of old cheese. Beneath it, the channel runs deep and black and busy.

Someone has scratched a warning into the post. The scratching is also rotten.
<!--@end-->


### Choices


#### **cross** — *yellow* — requires roll finesse vs normal

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.cross.text -->
Cross one at a time, testing every board
<!--@end-->


*Outcome — success*

`karma: human+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.cross.outcome_success.text -->
Four crossings, four held breaths, one plank that goes into the water without you. Everyone across.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: swamp_vermin  ·  difficulty: normal  ·  karma: hungry_ghost+2  ·  hp_loss: {'amount': 'light', 'target': 'random'}`

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.cross.outcome_failure.text -->
The board does not creak first. One moment there is a bridge and the next there is black water and a great deal of movement in it.
<!--@end-->


#### **repair** — *blue* — requires smithing 3

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.repair.text -->
Rebuild the span properly before anyone sets foot on it
<!--@end-->


*Outcome*

`karma: human+6, god+3  ·  xp: 20  ·  supplies: {'scrap': -6}`

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.repair.outcome.text -->
You cut and set new stringers, deck it in salvaged planks, and lash the whole thing to the surviving piles. It takes four hours and a quantity of scrap. When you finish, it is the only sound structure you have seen in this realm — and it will still be here for whoever comes next, which is a strange thing to care about in a place like this.
<!--@end-->


#### **ford** — *blue* — requires logistics 3

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.ford.text -->
Find where the channel shallows and ford it
<!--@end-->


*Outcome*

`karma: animal+3, human+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.ford.outcome.text -->
Bridges exist where the crossing is hard. Two hundred paces upstream the channel spreads over a gravel bar and is thigh-deep and boring. You get wet to the hip and nothing tries to eat anyone.
<!--@end-->


#### **back** — *grey*

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.back.text -->
Not worth it — go the long way
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_rotting_bridge | choices.back.outcome.text -->
Most of a day added to the journey and every member of the party privately relieved.
<!--@end-->


---

## hg_lost_traveler_swamp  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | title -->
Lost Traveler
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | text -->
He is sitting on his pack in six inches of water, and he is alive — properly alive, breathing, shivering, sunburnt on one side of his face from a sun that does not shine here.

"I've been walking in a circle," he says, with the terrible calm of someone who worked this out some time ago. "I keep finding my own footprints. I've stopped following them."
<!--@end-->


### Choices


#### **guide** — *grey*

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.guide.text -->
Take him with you as far as the next dry ground
<!--@end-->


*Outcome*

`karma: human+5, god+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.guide.outcome.text -->
He talks for the first hour and then stops, and the silence afterwards is better. At the treeline he shakes everyone's hand formally, one at a time, and walks off south. You do not find out whether he makes it.
<!--@end-->


#### **supplies** — *grey*

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.supplies.text -->
Give him food and directions
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.supplies.outcome.text -->
He eats too fast and apologises for it. The directions he repeats back to you three times, getting them right on the third.
<!--@end-->


#### **why_here** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.why_here.text -->
Ask how a living man got into the realm of the dead
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 16  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.why_here.outcome.text -->
He does not know, and the not-knowing is the whole horror of it. But in the telling he mentions a doorway in a hillside, a smell of jasmine, and a woman who asked him to carry something. You write down everything he says. Some of it will matter later.
<!--@end-->


#### **homesick_understands** — *blue* — requires **trait: homesick**

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.homesick_understands.text -->
He is not lost. He is somewhere he does not want to be.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.homesick_understands.outcome.text -->
Lost is a thing you can fix with directions. This is the other thing, and you recognise it because you are carrying a version of it yourself.

You do not give him directions. You sit in the water next to him for a while, and then you both get up.
<!--@end-->


#### **circle** — *blue* — requires space_magic 3

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.circle.text -->
Break whatever is turning him in a circle
<!--@end-->


*Outcome*

`karma: god+6, human+5  ·  xp: 22  ·  pressure: space+20`

<!--@ hungry_ghost_events.json | hg_lost_traveler_swamp | choices.circle.outcome.text -->
The loop is real and it is thin — a fold in the swamp about a mile across that returns everything to its own footprints. You cut it. The change is not visible; it is simply that the horizon means something now. He starts crying, which he seems as surprised by as you are.
<!--@end-->


---

## hg_sunken_village  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_sunken_village | title -->
Sunken Village
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_sunken_village | text -->
Roof-ridges break the water in rows. A whole village went under here and did not go anywhere else — the water simply arrived and stayed, and the village kept its shape beneath it.

In the shallows at the edge, a cooking pot sits on its stones, upright, full of black water.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.leave.text -->
Leave it under the water
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_sunken_village | choices.leave.outcome.text -->
The roof-ridges are still visible a long way down the road, whenever you look back.
<!--@end-->


#### **salvage** — *grey*

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.salvage.text -->
Work the shallow houses
<!--@end-->


*Outcome*

`karma: hungry_ghost+3  ·  xp: 10  ·  gold: 80  ·  supplies: {'scrap': 8}`

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.salvage.outcome.text -->
Waist-deep through what used to be doorways. Cookware, tools, a strongbox nobody had time for.
<!--@end-->


#### **deep_house** — *yellow* — requires roll constitution vs difficult

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.deep_house.text -->
Dive the headman's house at the centre
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+3, animal+2  ·  xp: 16  ·  gold: 180  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.deep_house.outcome_success.text -->
Three dives. The third one gets the box out of the rafters where somebody put it when the water was already at the door.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bog_zombie  ·  difficulty: normal  ·  karma: hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.deep_house.outcome_failure.text -->
Something in the rafters is not a rafter, and it has been waiting in the dark of that room for a very long time.
<!--@end-->


#### **rites** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.rites.text -->
Say the water-rites over the whole village
<!--@end-->


*Outcome*

`karma: god+6, human+3  ·  xp: 22  ·  gold: 140  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_sunken_village | choices.rites.outcome.text -->
You stand in the shallows and name the village — you do not know its name, so you name it by what it was: a place where people cooked and argued and slept. The water does not change. But when you go through the houses afterwards nothing objects, and in the headman's rafters you find what was hidden there, and it comes away easily.
<!--@end-->


---

## hg_flooded_crypt  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_flooded_crypt | title -->
Flooded Crypt
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_flooded_crypt | text -->
Stone steps go down into standing water. Whatever this was built to hold has been below the waterline for centuries, and the swamp has been patiently filling it the entire time.

The first two feet of the stair are slick with something that is not algae.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.leave.text -->
Some doors stay shut
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.leave.outcome.text -->
You go back up into the grey daylight, which is not much, but is more than what is down there.
<!--@end-->


#### **wade** — *yellow* — requires roll constitution vs difficult

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.wade.text -->
Wade in with torches
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+3  ·  xp: 18  ·  gold: 160  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.wade.outcome_success.text -->
Chest-deep, torch held over your head, through three chambers of grave-goods that nobody has been able to reach since the water came. Cold beyond describing. Worth it.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: rotting_sentinel  ·  difficulty: hard  ·  karma: hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.wade.outcome_failure.text -->
The torch goes out in the second chamber. In the dark, something that has been standing in this water for four hundred years turns to face the sound of you.
<!--@end-->


#### **drain** — *blue* — requires water_magic 4

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.drain.text -->
Part the water and walk in dry
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 26  ·  gold: 200  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.drain.outcome.text -->
You push the water back down the stair and hold it there, and walk into a crypt that has not been dry since its builders sealed it. The sentinel in the third chamber is standing exactly where it was posted. It does not attack. It looks at the dry floor for a long moment and then, apparently satisfied that its watch is finally over, sits down and stops.
<!--@end-->


#### **read_seals** — *blue* — requires learning 3

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.read_seals.text -->
Read the seals on the doorway before opening anything
<!--@end-->


*Outcome*

`karma: human+4, god+2  ·  xp: 20  ·  gold: 100  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_flooded_crypt | choices.read_seals.outcome.text -->
The seals are not protective. They are a *containment*, and the water is part of it — whoever flooded this crypt did it on purpose and did it well. You take what is in the entry chamber, which is generous, and you leave the inner door alone, which is wisdom.
<!--@end-->


---

## hg_cursed_well  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_cursed_well | title -->
Cursed Well
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_cursed_well | text -->
A well, in a swamp — which is absurd, because there is water everywhere. Somebody dug down through all this wet ground looking for something cleaner, and found something else.

The rope is still on the winch. It is taut. Something is hanging on the other end of it.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.leave.text -->
Leave the winch alone
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_cursed_well | choices.leave.outcome.text -->
The rope stays taut behind you for as long as you can see the well.
<!--@end-->


#### **wind** — *grey*

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.wind.text -->
Turn the winch and see what comes up
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: swamp_wraith  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.wind.outcome.text -->
It comes up easily. It comes up much too easily, in fact, for the weight that was on the rope.
<!--@end-->


#### **cut** — *blue* — requires black_magic 2

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.cut.text -->
Cut the rope and let whatever it is go back down
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.cut.outcome.text -->
You can feel it up the rope like a pulse — patient, attentive, entirely aware that someone has come. You cut the rope near the winch and the tension goes out of it, and something a long way down makes a sound of what is unmistakably disappointment. Then nothing. You fill the shaft with stones for an hour to be certain.
<!--@end-->


#### **purify** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.purify.text -->
Purify the shaft
<!--@end-->


*Outcome*

`karma: god+8  ·  xp: 24  ·  restore: {'hp_percent': 40}  ·  pressure: water+20`

<!--@ hungry_ghost_events.json | hg_cursed_well | choices.purify.outcome.text -->
You work the rite down the shaft in stages, and what is on the rope comes apart quietly on the way up — not destroyed, released, the way a knot is released. What finally reaches the top is a bucket. In the bucket is clean water, the first you have seen in this realm, and it tastes of nothing at all, which is extraordinary.
<!--@end-->


---

## hg_preta_feast_swamp  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | title -->
Preta Feast
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | text -->
They have laid a table in the marsh. A real table, on real trestles, in eight inches of standing water — and on it, a banquet: rice, fruit, roast meat, all of it steaming.

The pretas are seated around it. None of them is eating. They are all just looking at it, and have been for a long time.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.leave.text -->
Walk on past the table
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 4  ·  pressure: water-8`

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.leave.outcome.text -->
Nobody at the table looks up as you go. The food is still steaming when you lose sight of it.
<!--@end-->


#### **eat** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.eat.text -->
Sit down and eat
<!--@end-->


*Outcome*

`karma: hungry_ghost+6  ·  xp: 8  ·  supplies: {'food': 10}  ·  pressure: water-20, fire+10`

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.eat.outcome.text -->
It is real, and it is good, and it is the best meal you have had in weeks. Every preta at the table watches every mouthful. Nobody stops you. Nobody says anything. You finish because stopping halfway would somehow be worse.
<!--@end-->


#### **feed_one** — *blue* — requires medicine 3

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.feed_one.text -->
Take a bowl and feed the nearest one by hand
<!--@end-->


*Outcome*

`karma: god+8, human+4  ·  xp: 22  ·  pressure: water+20`

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.feed_one.outcome.text -->
The throat is the width of a straw and the swallowing has to be taught — small, slow, wait, again. It takes twenty minutes to get four mouthfuls into her. She keeps them down. The others watch this happen with an attention that is difficult to be the subject of. When you leave, three of them have moved their chairs closer to hers.
<!--@end-->


#### **sworn_vegetarian_declines** — *blue* — requires **trait: sworn_vegetarian**

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.sworn_vegetarian_declines.text -->
Look at what is actually on the table first.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: fire+10, earth+8`

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.sworn_vegetarian_declines.outcome.text -->
You look, and having looked you decline, and the declining is easy in a way it has not been easy for years.

The pretas cannot make you want it. They have nothing else to offer and drift off to find someone who can be worked with.
<!--@end-->


#### **why_not** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.why_not.text -->
Ask why nobody is eating
<!--@end-->


*Outcome*

`karma: god+10, human+4  ·  xp: 26  ·  pressure: water+25, space+15`

<!--@ hungry_ghost_events.json | hg_preta_feast_swamp | choices.why_not.outcome.text -->
"Because it will end," says the one at the head of the table, without looking away from the rice. "While we do not begin, it is still whole." You sit with that for a while. Then you point out, gently, that the food is going cold, and that this is also an ending, and that it is happening whether or not anyone begins. There is a very long silence. Then somebody picks up a spoon.
<!--@end-->


---

## hg_medicinal_garden  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_medicinal_garden | title -->
Medicinal Garden
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_medicinal_garden | text -->
Something is growing here on purpose. Beds of herbs in ordered rows, staked and labelled, tended in a place where nothing should tend anything — and the labels are in a careful hand, in a language you half-recognise.

A preserved one straightens up from the weeding and regards you without alarm. "Patients or customers?"
<!--@end-->


### Choices


#### **shop** — *grey*

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.shop.text -->
Customers
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_alchemist`

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.shop.outcome.text -->
She lays out what is dried and ready, and prices it fairly.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.leave.text -->
Neither — apologise for the intrusion
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.leave.outcome.text -->
"Mm," she says, and goes back to the weeding. "Mind the third bed."
<!--@end-->


#### **assist** — *blue* — requires medicine 3

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.assist.text -->
Offer your hands for the afternoon
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 18  ·  supplies: {'herbs': 14, 'reagents': 6}`

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.assist.outcome.text -->
She sets you thinning the third bed and does not explain why it matters until you have done it correctly, at which point she explains at length and with real pleasure. Nothing grows well in this realm; everything here grows because she made it. You leave with your kit restocked and an open invitation.
<!--@end-->


#### **chronic_pain_asks** — *blue* — requires **trait: chronic_pain**

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.chronic_pain_asks.text -->
Ask for the thing that helps rather than the thing that cures.
<!--@end-->


*Outcome*

`xp: 15  ·  supplies: {'herbs': 5}`

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.chronic_pain_asks.outcome.text -->
The gardener stops what she is doing. It is, apparently, a much rarer request than the other one and a considerably easier one to fulfil.

What she gives you will not fix anything. It makes tomorrow's walking possible, which is the whole of what you asked for.
<!--@end-->


#### **bhang_asks_hg** — *blue* — requires **trait: bhang_enjoyer**

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.bhang_asks_hg.text -->
Ask about the beds she has not mentioned.
<!--@end-->


*Outcome*

`xp: 20  ·  supplies: {'herbs': 4}`

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.bhang_asks_hg.outcome.text -->
She has not mentioned them because most people do not ask, and most people who do ask are not asking about medicine.

She establishes which you are with one question, and appears satisfied with the answer.
<!--@end-->


#### **how** — *blue* — requires earth_magic 3

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.how.text -->
Ask how anything grows in the realm of hunger
<!--@end-->


*Outcome*

`karma: god+6, human+4  ·  xp: 24  ·  supplies: {'herbs': 8}  ·  pressure: earth+20, water-10`

<!--@ hungry_ghost_events.json | hg_medicinal_garden | choices.how.outcome.text -->
"It doesn't," she says. "I feed it." She shows you the trench at the garden's edge, where she has been composting her own substance — a little at a time, for a very long time, into the soil. She is markedly less than she was when she started. She considers this an entirely reasonable arrangement and will not be argued with.
<!--@end-->


---

## hg_graveyard_dog  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_graveyard_dog | title -->
Grave Hound
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_graveyard_dog | text -->
It is standing on a grave mound with its head down and its green eyes fixed on you, and it has not decided yet. A grave hound alone is a guard; a grave hound in a pack is a problem. This one is alone.

Behind it, the mound has been dug at. Not by the hound.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.fight.text -->
Put it down
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: grave_hound  ·  difficulty: normal  ·  karma: animal+3, asura+2`

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.fight.outcome.text -->

<!--@end-->


#### **feed** — *grey*

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.feed.text -->
Throw it food and go around
<!--@end-->


*Outcome*

`karma: animal+3, human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.feed.outcome.text -->
It takes the meat back onto the mound and eats there, watching you the whole time, guarding even while it chews.
<!--@end-->


#### **read_dig** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.read_dig.text -->
Look at what dug the mound
<!--@end-->


*Outcome*

`karma: human+4, animal+4  ·  xp: 16`

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.read_dig.outcome.text -->
Tool marks, not claws — somebody came for this grave with a spade and left in a hurry. The hound is not guarding the grave from you; it is guarding it from whoever is coming back. You reset the turf and stack stones over it while the hound watches, and when you finish it lies down. It is still lying there when you look back.
<!--@end-->


#### **pet_lover_approaches** — *blue* — requires **trait: pet_lover**

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.pet_lover_approaches.text -->
It is a dog. You are going to do this whatever anyone says.
<!--@end-->


*Outcome*

`karma: animal+4  ·  xp: 20  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.pet_lover_approaches.outcome.text -->
It is a dog in the way that a burnt-out house is a house, and you go toward it anyway with your hand out, and the party makes noises.

It lets you. It has apparently been standing on that grave for a very long time and nobody has offered it anything since.
<!--@end-->


#### **calm** — *blue* — requires summoning 2

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.calm.text -->
Speak to it the way you would to a working dog
<!--@end-->


*Outcome*

`karma: animal+5, human+2  ·  xp: 14  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_graveyard_dog | choices.calm.outcome.text -->
Low voice, no eye contact, hand held out flat and still. Whatever it is now, it was a dog once, and something in the shape of the address gets through. It comes down off the mound and walks you a quarter mile to the graveyard's edge, and turns back at the boundary of what it considers its ground.
<!--@end-->


---

## hg_skeleton_army  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_skeleton_army | title -->
Skeleton Army
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_skeleton_army | text -->
They are drawn up in ranks across the whole width of the dry valley, and they are not moving. Rank on rank of skeleton infantry in the armour of an army that lost — you can tell it lost, because it is all still here.

They are facing an enemy that is no longer present. They have been facing it for a very long time.
<!--@end-->


### Choices


#### **skirt** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.skirt.text -->
Go around the flank, quietly
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.skirt.outcome.text -->
Two hours of picking along the valley wall while ten thousand skulls face resolutely the other way. Not one of them turns.
<!--@end-->


#### **through** — *grey*

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.through.text -->
Walk straight through the ranks
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warband  ·  difficulty: hard  ·  karma: asura+3, hungry_ghost+2`

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.through.outcome.text -->
You are six ranks deep when the nearest one registers that something has entered the formation, and the correction ripples outward.
<!--@end-->


#### **dismiss** — *blue* — requires leadership 5

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.dismiss.text -->
Give the order to stand down
<!--@end-->


*Outcome*

`karma: god+8, human+5  ·  xp: 30  ·  gold: 220  ·  items: ['item_random']  ·  supplies: {'scrap': 20}`

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.dismiss.outcome.text -->
You walk to the front, face the ranks, and dismiss them — properly, with the form and the cadence, the way it is done at the end of a campaign. It takes a moment. Then ten thousand skeletons ground their arms in one enormous rattling crash and the formation simply ceases to be a formation. Some of them sit down. Most of them come apart. What is left is a valley full of bones and a great deal of abandoned equipment.
<!--@end-->


#### **composed_walks_through** — *blue* — requires **trait: composed**

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.composed_walks_through.text -->
Ranks do not attack what walks through them like it belongs.
<!--@end-->


*Outcome*

`xp: 12  ·  add_trait: composed  ·  pressure: water+10`

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.composed_walks_through.outcome.text -->
You walk down the middle at an even pace with your hands where they can be seen, and you do not speed up at any point, including the point at which the second rank turns its head.

They close behind you. Nothing else happens.
<!--@end-->


#### **read_battle** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.read_battle.text -->
Work out what they are still facing
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 20  ·  gold: 160  ·  supplies: {'food': 12, 'scrap': 10}`

<!--@ hungry_ghost_events.json | hg_skeleton_army | choices.read_battle.outcome.text -->
The line is anchored on high ground at both ends and refused on the left — a textbook defensive deployment against cavalry that would have come from the north. There is no north army. There has not been for centuries. But there is a supply train behind the line, unlooted, because nobody has ever gotten past the ranks to it.
<!--@end-->


---

## hg_ancient_crypt  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_ancient_crypt | title -->
Ancient Crypt
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_ancient_crypt | text -->
The crypt door is stone, and it is ajar — about a hand's width, which is both an invitation and a warning depending on which side of it opened.

Dry air comes out. It smells of dust and cold iron and nothing organic at all.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.leave.text -->
Pull the door to and walk away
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.leave.outcome.text -->
The stone grinds shut. It takes both hands and most of your weight, and it feels like the right thing to have done.
<!--@end-->


#### **enter** — *grey*

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.enter.text -->
Go in
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_warrior_pair  ·  difficulty: normal  ·  karma: hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.enter.outcome.text -->
Two of them are standing just inside the door, one to each side, in the dark. They have been standing there since the door was last closed.
<!--@end-->


#### **listen** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.listen.text -->
Listen at the gap before you open it
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 18  ·  gold: 160  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.listen.outcome.text -->
Nothing breathes in there, but something *shifts* — twice, at an interval, the way a person shifts weight when they have been standing a long time. Two of them, flanking the door. You open it wide instead of squeezing through, and take them from outside with the light behind you, which turns a bad fight into a short one.
<!--@end-->


#### **seals** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.seals.text -->
Read the door before touching it
<!--@end-->


*Outcome*

`karma: god+6, human+4  ·  xp: 26  ·  gold: 180  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ancient_crypt | choices.seals.outcome.text -->
The inscription is a service contract. The two inside are not guardians in any hostile sense — they are staff, on a term of duty that expired four hundred years ago because the family that hired them stopped existing. You go in and tell them so. There is a pause you would describe as stunned. Then they hand over the keys, formally, and lie down in the alcoves they were meant to occupy in the first place.
<!--@end-->


---

## hg_crumbling_mausoleum  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | title -->
Crumbling Mausoleum
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | text -->
It was grand once and it is coming apart now — the roof half in, one wall bowed outward, the whole structure held up mostly by the habit of standing. Inside, the sarcophagi are visible through the gaps.

Something moves in there when the wind does. It may only be the wind.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.leave.text -->
It will fall on someone. Not you.
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.leave.outcome.text -->
You give it a wide berth. Behind you, a stone comes off the parapet and lands where nobody is standing.
<!--@end-->


#### **loot** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.loot.text -->
Get in, get what is reachable, get out
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+3  ·  xp: 16  ·  gold: 150  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.loot.outcome_success.text -->
In through the gap in the bowed wall, two sarcophagi levered open, out before the dust settles. The roof comes down about ten minutes later. Nobody was under it.
<!--@end-->


*Outcome — failure*

`karma: hungry_ghost+2  ·  xp: 5  ·  hp_loss: {'amount': 'moderate', 'target': 'random'}  ·  wound: {'id': 'broken_rib', 'target': 'random'}`

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.loot.outcome_failure.text -->
The lid you are levering is load-bearing, which is not a sentence anyone wants to discover from underneath. You get out. Most of the building does not.
<!--@end-->


#### **shore** — *blue* — requires smithing 3

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.shore.text -->
Prop the wall before anyone goes in
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost+2  ·  xp: 22  ·  gold: 240  ·  items: ['item_random']  ·  supplies: {'scrap': -4}`

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.shore.outcome.text -->
Two hours of bracing with timber cut from grave-markers, which is grim but effective. With the wall held you can work the whole interior properly instead of snatching at what is nearest, and there is a great deal more in the back than there was in the front.
<!--@end-->


#### **family** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.family.text -->
Read the family names and give them their rites
<!--@end-->


*Outcome*

`karma: god+7, human+3  ·  xp: 24  ·  gold: 120  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_crumbling_mausoleum | choices.family.outcome.text -->
Eleven names, four generations, one family line that ended here. You say each name aloud in the ruin of their house. Nothing dramatic happens. But the movement in the back of the mausoleum stops, and stays stopped, and when you leave the grave-goods are simply objects rather than the other thing they had been.
<!--@end-->


---

## hg_forgotten_king  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_forgotten_king | title -->
The Forgotten King
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_forgotten_king | text -->
The tomb is the largest thing in the graveyard and every inscription on it has been chiselled out — thoroughly, deliberately, by people who wanted this specific man erased and had the time to do it properly.

Inside, on a throne, he is still sitting. He turns his head as you enter. "Do you know my name?"
<!--@end-->


### Choices


#### **no** — *grey*

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.no.text -->
"No."
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 10  ·  pressure: space-10`

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.no.outcome.text -->
"No," he agrees. "Nobody does. That was the sentence." He sits back. He does not attack, does not threaten, does not ask for anything. After a while it becomes clear the audience is simply over, and you leave him in the dark he has been sitting in for eight hundred years.
<!--@end-->


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.fight.text -->
Whatever he was, he is a corpse on a chair now
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_elite  ·  difficulty: hard  ·  karma: asura+3, hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.fight.outcome.text -->
He rises with the enormous unhurried dignity of a man who has been waiting a long time for something to happen.
<!--@end-->


#### **reconstruct** — *blue* — requires learning 5

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.reconstruct.text -->
Reconstruct the name from what the chisels missed
<!--@end-->


*Outcome*

`karma: god+6, human+4  ·  xp: 30  ·  gold: 200  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.reconstruct.outcome.text -->
They were thorough on the walls and careless underneath — the mason's setting-out marks are still there, cut deep and never intended to be read. You work it letter by letter and then say it out loud.

The effect is not gratitude. He goes very still, and then he begins, quietly and with great precision, to come apart, because being named was the only thing still holding the shape together. What is left on the throne is a crown and a considerable quantity of dust.
<!--@end-->


#### **sit_with** — *blue* — requires yoga 4

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.sit_with.text -->
Sit down on the step and keep him company a while
<!--@end-->


*Outcome*

`karma: god+9, human+4  ·  xp: 26  ·  pressure: space+20, water+15`

<!--@ hungry_ghost_events.json | hg_forgotten_king | choices.sit_with.outcome.text -->
You do not ask him anything and you do not tell him anything. You sit on the tomb step for a couple of hours in the company of a man whose entire punishment was to be alone with himself indefinitely. Eventually he says, "Thank you," in a voice that has clearly not been used for that before. He is still there when you go. But he is sitting differently.
<!--@end-->


---

## hg_dusty_library  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_dusty_library | title -->
Dusty Library
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_dusty_library | text -->
A reading room, intact, under a collapsed roof that fell in such a way as to shelter rather than crush it. Shelves of scroll-cases, a desk, a chair pushed back as though someone stood up mid-sentence.

On the desk, a document is still weighted flat, half-copied, the ink long dry.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.leave.text -->
Leave the room as you found it
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_dusty_library | choices.leave.outcome.text -->
You put the weight back on the corner of the document on your way out, which is a small courtesy to nobody in particular.
<!--@end-->


#### **loot** — *grey*

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.loot.text -->
Take whatever looks valuable
<!--@end-->


*Outcome*

`karma: hungry_ghost+3  ·  xp: 8  ·  gold: 90  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.loot.outcome.text -->
Scroll-cases of good bronze, a silver inkwell, and three documents that look important enough to sell to somebody.
<!--@end-->


#### **read** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.read.text -->
Read the half-copied document
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 22  ·  learn_spell: {'school': ''}  ·  pressure: space+15`

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.read.outcome.text -->
It is a commentary on a sutra you know, and the copyist was arguing with it in the margins — sharp, funny, occasionally wrong, entirely alive. The hand stops mid-word. You finish the sentence yourself, in your own hand, underneath, because it is obvious how it was going to end and it seems a shame to leave it hanging.
<!--@end-->


#### **incurious_passes** — *blue* — requires **trait: incurious**

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.incurious_passes.text -->
A collapsed roof over wet paper. Move on.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: space-5`

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.incurious_passes.outcome.text -->
You move on. The roof comes down the rest of the way about an hour later, which you hear from some distance and do not go back to investigate.
<!--@end-->


#### **catalogue** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.catalogue.text -->
Work out what the collection was *for*
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 24  ·  items: ['item_random']  ·  skill_up: {'skill': 'ritual', 'amount': 1, 'cap': 8}`

<!--@ hungry_ghost_events.json | hg_dusty_library | choices.catalogue.outcome.text -->
It is not a general library. Every text is on one subject, approached from every possible angle over what must have been decades: how to die correctly. Somebody in this realm spent a lifetime studying the thing they were about to fail at. The final shelf is practical instructions, and they are good ones.
<!--@end-->


---

## hg_bone_collector  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_collector | title -->
Bone Collector
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_collector | text -->
He works the graveyard with a handcart and a system, and he is extremely particular: he takes only certain bones, only from certain graves, and he is keeping a tally on a wax tablet.

"Femurs," he says, before you can ask. "Matched pairs. You would be amazed how hard that is."
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.leave.text -->
Leave him to it
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_bone_collector | choices.leave.outcome.text -->
The handcart creaks away between the mounds. He is whistling.
<!--@end-->


#### **ask** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.ask.text -->
Ask what he is building
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.ask.outcome.text -->
"A bridge," he says, with the patience of a man who gets asked a lot. "Over the chasm on the north road. Been at it eleven years." He shows you the plans. They are competent. He is entirely serious.
<!--@end-->


#### **help** — *blue* — requires medicine 3

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.help.text -->
Help him find matched pairs
<!--@end-->


*Outcome*

`karma: human+5, hungry_ghost+2  ·  xp: 18  ·  items: ['item_random']  ·  supplies: {'scrap': 6}`

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.help.outcome.text -->
You know what he does not: matched femurs are far easier to find if you stop opening random graves and start reading the markers for age at death. Inside an hour you have found him six pairs, which is better than his last two months. He is so pleased he gives you his spare tools and a genuinely useful map of the graveyard's dry routes.
<!--@end-->


#### **ethics** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.ethics.text -->
Ask whether the dead consented to being a bridge
<!--@end-->


*Outcome*

`karma: god+4, human+4  ·  xp: 20  ·  pressure: earth+15`

<!--@ hungry_ghost_events.json | hg_bone_collector | choices.ethics.outcome.text -->
He stops the cart. It is clear nobody has ever put it to him and equally clear he has put it to himself, many times, at night. "They're not using them," he says, and then, after a while: "I ask. Every one. If it feels wrong I put it back." He shows you the reject pile. It is much larger than the cart.
<!--@end-->


---

## hg_ancestor_spirit  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | title -->
Ancestor Spirit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | text -->
The shrine is small and very old and somebody has been maintaining it — swept, the offering-bowl clean, fresh dust patterns raked around the base. Above it hangs a presence rather than a shape.

"You are not of my line," it says. It does not sound disappointed. It sounds like it is checking.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.leave.text -->
Bow and continue
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.leave.outcome.text -->
"Go well," it says, and the presence settles back into the raked dust.
<!--@end-->


#### **offer** — *grey*

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.offer.text -->
Leave something in the bowl anyway
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.offer.outcome.text -->
"Not of my line," it observes again, differently this time. The offering is accepted. Something eases in the air around the shrine that had been held for a long time.
<!--@end-->


#### **who_tends** — *blue* — requires awareness 13

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.who_tends.text -->
Ask who has been sweeping the shrine
<!--@end-->


*Outcome*

`karma: god+6, human+5  ·  xp: 20  ·  pressure: water+15`

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.who_tends.outcome.text -->
Silence. Then: "I do." An ancestor spirit with no descendants left, maintaining its own shrine, raking its own dust, keeping up the observances for a family that ended. It has not admitted this out loud before. You spend an hour helping with the raking and it talks the entire time, about people eight hundred years dead, and you listen.
<!--@end-->


#### **mourner_keeps_it_up** — *blue* — requires **trait: mourner**

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.mourner_keeps_it_up.text -->
Somebody has been maintaining this. Take a turn.
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost-4  ·  xp: 30  ·  supplies: {'food': -2}`

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.mourner_keeps_it_up.outcome.text -->
The offerings are recent and the cloth has been changed within the month, which means somebody is walking a long way to do this and will not always be able to.

You do what they have been doing, and you leave the shrine better stocked than you found it.
<!--@end-->


#### **adopt** — *blue* — requires ritual 4

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.adopt.text -->
Offer to carry the line
<!--@end-->


*Outcome*

`karma: god+10, human+5  ·  xp: 28  ·  gold: 180  ·  items: ['item_random']  ·  add_trait: {'id': 'devout', 'target': 'player'}`

<!--@ hungry_ghost_events.json | hg_ancestor_spirit | choices.adopt.outcome.text -->
There is a rite for this — adoption across the line of death, so a family that has run out of living can be continued by someone willing to take the observance on. It is not a small thing to accept. You do it properly, with the responses, and the presence at the shrine becomes something with a stake in whether you live.

It gives you what it has: its name, its protection, and the contents of a grave nobody else knows about.
<!--@end-->


---

## hg_bone_shrine  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_shrine | title -->
Bone Shrine
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_shrine | text -->
Skulls set into a cairn in a spiral, each one facing outward, each one with a small offering wedged into the eye socket — a coin, a bead, a folded scrap.

It is either a place of great devotion or a place of great warning, and the two are not always different.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.leave.text -->
Pass without touching anything
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.leave.outcome.text -->
Every socket you pass is looking somewhere else. That is the intended effect and it works.
<!--@end-->


#### **offer** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.offer.text -->
Add your own offering to an empty socket
<!--@end-->


*Outcome*

`karma: god+5  ·  xp: 12  ·  buffs: [{'stat': 'armor', 'amount': 4, 'combats_remaining': 2}]`

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.offer.outcome.text -->
There is exactly one empty socket, at the centre of the spiral, and it takes your coin as though it had been waiting for that specific denomination. The air over the cairn goes briefly warm.
<!--@end-->


#### **rob** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.rob.text -->
Empty the sockets
<!--@end-->


*Outcome — success*

`karma: hungry_ghost+8, hell+3  ·  xp: 12  ·  gold: 190`

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.rob.outcome_success.text -->
Forty-odd offerings, some of them very old and one of them gold. You are three miles away before you stop feeling watched, and you never entirely stop.
<!--@end-->


*Outcome — failure*

`type: combat  ·  enemy_group: bone_pack  ·  difficulty: normal  ·  karma: hungry_ghost+4`

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.rob.outcome_failure.text -->
The spiral is a ward and the offerings are what holds it closed. The third socket you empty opens it.
<!--@end-->


#### **read_spiral** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.read_spiral.text -->
Read the spiral
<!--@end-->


*Outcome*

`karma: god+7, human+3  ·  xp: 22`

<!--@ hungry_ghost_events.json | hg_bone_shrine | choices.read_spiral.outcome.text -->
It is a containment, wound outward, and the offerings are the seal — each one a small debt paid on behalf of whatever is under the cairn. It has been maintained by passing strangers for centuries without any of them knowing what they were maintaining. You pay your share, tighten the two sockets that had gone loose, and leave it in better repair than you found it.
<!--@end-->


---

## hg_grave_goods  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_grave_goods | title -->
Grave Goods
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_grave_goods | text -->
A grave has opened itself — the earth has subsided rather than been dug, and the contents are simply lying there in the depression, exposed to the grey daylight.

Someone was buried well. Bronze, worked cloth, a sword still in a scabbard, all of it a hand's reach away and nobody's.
<!--@end-->


### Choices


#### **take** — *grey*

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.take.text -->
Take it
<!--@end-->


*Outcome*

`karma: hungry_ghost+4  ·  xp: 8  ·  gold: 120  ·  items: ['item_random']  ·  add_trait: covetous`

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.take.outcome.text -->
It is good gear and it is on the surface and there is no argument to be had with a hole in the ground. You take it and you do not linger.
<!--@end-->


#### **rebury** — *grey*

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.rebury.text -->
Push the earth back over it
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 10  ·  add_trait: merciful`

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.rebury.outcome.text -->
An hour with your hands and a broken marker for a spade. When you have finished you cannot tell there was ever a subsidence, which is the point.
<!--@end-->


#### **ask_first** — *blue* — requires black_magic 3

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.ask_first.text -->
Ask the occupant
<!--@end-->


*Outcome*

`karma: human+5, god+3  ·  xp: 22  ·  gold: 60  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.ask_first.outcome.text -->
She is still in there and she is entirely lucid and she has been listening to people discuss her possessions for two hundred years without once being consulted. Being asked improves her mood immeasurably. She grants you the sword, declines to part with the cloth, and asks — as her condition — that you push the earth back afterwards, which you do.
<!--@end-->


#### **greedy_takes** — *blue* — requires **trait: greedy**

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.greedy_takes.text -->
It is in the open. That makes it nobody's.
<!--@end-->


*Outcome*

`karma: hungry_ghost+5  ·  xp: 18  ·  gold: moderate  ·  pressure: earth-10`

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.greedy_takes.outcome.text -->
You have the reasoning worked out before your hand arrives, which is the sign of a well-practised reasoning.

The goods are real, valuable, and will be missed by something that is still nearby.
<!--@end-->


#### **why_open** — *blue* — requires earth_magic 3

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.why_open.text -->
Work out why the ground gave way
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 20  ·  gold: 110  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_grave_goods | choices.why_open.outcome.text -->
There is a void under this whole section of the graveyard — something hollowed it out from below, recently, and this grave is simply the first to notice. You mark the extent of it, which takes an afternoon, and the map you make of where not to walk is worth more than the grave goods. You take those too, since the occupant is about to have a much worse problem.
<!--@end-->


---

## hg_weary_pilgrim  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | title -->
Weary Pilgrim
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | text -->
A skeleton in a pilgrim's robe sits at the roadside with its staff across its knees, facing the direction it was going. Prayer-flags, long since bleached white, are tied to the staff head.

"Is it much further?" it asks. It does not say to where.
<!--@end-->


### Choices


#### **yes** — *grey*

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.yes.text -->
"Not much further."
<!--@end-->


*Outcome*

`karma: human+3, god+2  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.yes.outcome.text -->
"Good," it says, and gets up, and sets off in the direction it was facing at a pace that suggests it believes you. You watch it go. You have no idea whether you told it the truth.
<!--@end-->


#### **sit** — *grey*

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.sit.text -->
Sit down beside it for a while
<!--@end-->


*Outcome*

`karma: human+4  ·  xp: 10  ·  pressure: earth+12`

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.sit.outcome.text -->
Neither of you says anything for a long time. It is restful in a way very little in this realm is. When you stand up to go it lifts the staff an inch off its knees in farewell.
<!--@end-->


#### **where** — *blue* — requires charm 13

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.where.text -->
Ask where the pilgrimage was going
<!--@end-->


*Outcome*

`karma: god+5, human+3  ·  xp: 16  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.where.outcome.text -->
It cannot remember the destination, only the walking, and it is not distressed by this — it stopped needing the destination somewhere around the fourth century. "The road was the observance," it says. "I just liked to have somewhere to point it." It gives you its spare flags, which it has been carrying for no reason it can name.
<!--@end-->


#### **pilgrim_sits_with** — *blue* — requires **trait: pilgrim**

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.pilgrim_sits_with.text -->
You know this particular tiredness.
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 20  ·  pressure: earth+10`

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.pilgrim_sits_with.outcome.text -->
It is not the walking. It is never the walking — it is the arithmetic of how much road is left against how much of you there is.

You sit down at the roadside with it and do not offer any encouragement, which is what it needed and what nobody else has managed.
<!--@end-->


#### **walk_with** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.walk_with.text -->
Walk with it as far as you are going
<!--@end-->


*Outcome*

`karma: god+8, human+3  ·  xp: 24  ·  pressure: earth+20, space+15`

<!--@ hungry_ghost_events.json | hg_weary_pilgrim | choices.walk_with.outcome.text -->
Six miles of shared road, in step, in silence, with a dead pilgrim who has been walking since before your language existed. Around the fourth mile you stop being someone accompanying it and start simply being on a pilgrimage, and the difference is not subtle. At the crossroads it goes one way and you go the other and both of you are, briefly, going somewhere.
<!--@end-->


---

## hg_ossuary_bargain  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | title -->
The Ossuary
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | text -->
Bones stacked to the vaulted ceiling, sorted by type, in a building constructed entirely for that purpose. At a counter near the door, a skeleton in a clerk's visor is doing sums in a ledger.

"Buying, selling, or storing?" it asks. "We do all three. Storage is where the money is."
<!--@end-->


### Choices


#### **shop** — *grey*

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.shop.text -->
Buying
<!--@end-->


*Outcome*

`type: shop  ·  shop_id: hg_bone_merchant`

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.shop.outcome.text -->
The clerk produces a second ledger and a surprisingly good selection.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.leave.text -->
Just looking
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.leave.outcome.text -->
"Everyone says that," the clerk says, and goes back to the sums.
<!--@end-->


#### **audit** — *blue* — requires trade 4

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.audit.text -->
Look at the ledger
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 20  ·  gold: 200`

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.audit.outcome.text -->
The storage business is running at a loss and has been for eighty years — the clerk has been discounting long-term contracts against a currency that stopped existing. You show it the error. It goes very quiet, recalculates two centuries of accounts in about four minutes, and then, being fundamentally honest, insists on paying you a consultant's fee out of the correction.
<!--@end-->


#### **oath_keeper_reads_first** — *blue* — requires **trait: oath_keeper**

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.oath_keeper_reads_first.text -->
Read all of it before agreeing to any of it.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.oath_keeper_reads_first.outcome.text -->
You read all of it. You are not agreeing to something you have not read; you have never been able to, and it has cost you opportunities.

This time it costs the ossuary keeper an hour and you the clause on the fourth page, which was going to be the expensive one.
<!--@end-->


#### **whose** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.whose.text -->
Ask who is paying for all this storage
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost+2  ·  xp: 18  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_ossuary_bargain | choices.whose.outcome.text -->
The contracts are prepaid, in perpetuity, by the deceased themselves — every skeleton in this building is a client who arranged its own indefinite safekeeping rather than risk being scattered. It is not a warehouse. It is a very long-term hotel, and the clerk is the concierge, and it takes the duty extremely seriously.
<!--@end-->


---

## hg_vetala_court  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_court | title -->
Vetala Court
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_court | text -->
They have taken over what was once a hall and turned it into something between a salon and a slaughterhouse. Perhaps thirty vetala, beautifully dressed, holding a conversation of extraordinary wit across a floor that has not been cleaned in living memory.

The talk stops. Thirty faces turn with the same expression: delight.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.fight.text -->
You are not going to talk your way out of thirty
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_elder_court  ·  difficulty: very_hard  ·  karma: asura+4, hell+2`

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.fight.outcome.text -->

<!--@end-->


#### **withdraw** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.withdraw.text -->
Bow, apologise for interrupting, and back out
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.withdraw.outcome.text -->
The courtesy is so unexpected that it works. Somebody laughs; somebody else says "oh, let it go"; the conversation resumes behind you as though you had been a draught from an open door.
<!--@end-->


#### **join** — *blue* — requires charm 15

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.join.text -->
Take a seat and hold your own
<!--@end-->


*Outcome*

`karma: human+5, hungry_ghost+3  ·  xp: 26  ·  gold: 160  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.join.outcome.text -->
The rule of the court, you work out fast, is that dullness is the only capital offence. You are interesting for two hours — genuinely, exhaustingly interesting — and at the end of it a vetala in green raises her glass and says, "We shall not eat this one," and the matter is settled by acclamation. They send you off with gifts and directions and an open invitation you will never use.
<!--@end-->


#### **etiquette** — *blue* — requires black_magic 4

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.etiquette.text -->
Observe the forms of a vetala court exactly
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, human+3  ·  xp: 28  ·  learn_spell: {'school': 'black_magic'}`

<!--@ hungry_ghost_events.json | hg_vetala_court | choices.etiquette.outcome.text -->
There is a protocol for a living guest and almost nobody alive has ever known it. You give the greeting, present the required token, and take the low seat without being told to. The effect is roughly that of a peasant walking into a royal audience and getting every bow right. They are charmed, scandalised, and obliged — the forms bind both ways, and now they cannot touch you.
<!--@end-->


---

## hg_vetala_bargain  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_bargain | title -->
Vetala's Offer
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_bargain | text -->
It is sitting on a wall, swinging its heels, and it has clearly been waiting for someone specifically your size.

"A trade," it says. "Your body for a day and a night. I have errands. You get everything I know — and I know a great deal — and I give it back exactly as I found it. I have never once failed to give it back."
<!--@end-->


### Choices


#### **refuse** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.refuse.text -->
Refuse
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 5`

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.refuse.outcome.text -->
"Worth asking," it says, unoffended, and goes back to swinging its heels. "Someone always says yes eventually."
<!--@end-->


#### **accept** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.accept.text -->
Accept the bargain
<!--@end-->


*Outcome*

`karma: hungry_ghost+6, hell+2  ·  xp: 24  ·  learn_spell: {'school': 'black_magic'}  ·  add_trait: oath_breaker  ·  pressure: space-20`

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.accept.outcome.text -->
You wake a day and a night later exactly where you lay down, with everything where you left it and a head full of somebody else's knowledge — genuinely useful, precisely as promised. Your hands smell faintly of smoke. Nobody in the party will tell you what they saw you doing, and you decide, on balance, not to press.
<!--@end-->


#### **terms** — *blue* — requires persuasion 5

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.terms.text -->
Accept — but negotiate the terms first
<!--@end-->


*Outcome*

`karma: human+5, hungry_ghost+3  ·  xp: 30  ·  gold: 120  ·  learn_spell: {'school': 'black_magic'}`

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.terms.outcome.text -->
Four hours of hard bargaining. You get: a witness, a fixed return time, a prohibition on violence while wearing you, and the knowledge transferred up front. It agrees to all of it, with increasing respect, and then keeps every clause to the letter — because a vetala that breaks terms in front of a witness stops being able to make bargains, and bargains are what it eats.
<!--@end-->


#### **oath_breaker_knows** — *blue* — requires **trait: oath_breaker**

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.oath_breaker_knows.text -->
You know what it is going to ask for, because you have given it before.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: earth+10`

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.oath_breaker_knows.outcome.text -->
It wants a promise. It does not much care what the promise is about — the value is in the breaking, later, when it can be collected on.

You recognise the shape because you have been on the other side of it, and you decline in terms it finds genuinely disappointing.
<!--@end-->


#### **see_cost** — *blue* — requires awareness 15

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.see_cost.text -->
Ask what happened to the ones who said yes
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 22  ·  pressure: space+15`

<!--@ hungry_ghost_events.json | hg_vetala_bargain | choices.see_cost.outcome.text -->
"Returned. Every one." True, and not the answer. You keep asking, and eventually get the rest: returned, yes — but a body worn by a vetala for a day and a night is a body that has been *somewhere*, and the ones who said yes have all, without exception, come back a little easier to persuade the second time. It admits this freely. It considers it a feature.
<!--@end-->


---

## hg_illusory_palace  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_illusory_palace | title -->
Illusory Palace
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_illusory_palace | text -->
A palace stands where there was nothing an hour ago: lit windows, music, the smell of food, a door standing open onto warm light.

Everything in this realm is grey and cold and starving. This is none of those things, which tells you everything you need to know and does not make it one bit easier to walk past.
<!--@end-->


### Choices


#### **pass** — *grey*

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.pass.text -->
Walk past without looking in the windows
<!--@end-->


*Outcome*

`karma: god+4, human+3  ·  xp: 12  ·  pressure: fire-10`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.pass.outcome.text -->
It takes more out of the party than the last three fights combined. Half a mile on, the music stops abruptly, mid-phrase.
<!--@end-->


#### **enter** — *grey*

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.enter.text -->
Go in
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_with_minions  ·  difficulty: hard  ·  karma: hungry_ghost+4`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.enter.outcome.text -->
The warmth lasts about as long as it takes for the door to close. Then the hall is a charnel pit with a very good acoustic, and the hosts are already seated.
<!--@end-->


#### **dispel** — *blue* — requires space_magic 4

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.dispel.text -->
Take the illusion apart from outside
<!--@end-->


*Outcome*

`karma: human+4, god+3  ·  xp: 26  ·  gold: 140  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.dispel.outcome.text -->
It is an excellent working — layered, self-repairing, with the smell built in, which is the part most illusionists skip. You unpick it from the outside like a knitted seam. Underneath is a pit with fourteen vetala in it looking extremely startled and, for the moment, extremely visible.
<!--@end-->


#### **suspicious_wont_enter** — *blue* — requires **trait: suspicious**

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.suspicious_wont_enter.text -->
A palace was not here an hour ago.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: air+8`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.suspicious_wont_enter.outcome.text -->
A palace was not here an hour ago, and you say so, repeatedly, until the party stops arguing about it.

You make camp at a distance and watch. At some point in the small hours the lit windows go out one row at a time, which settles the matter.
<!--@end-->


#### **trusting_walks_in** — *blue* — requires **trait: trusting**

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.trusting_walks_in.text -->
It is a warm building with the door open.
<!--@end-->


*Outcome*

`xp: 15  ·  pressure: water+8`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.trusting_walks_in.outcome.text -->
It is. You are three rooms in and being handed something warm before anyone else has crossed the threshold.

What saves you is that you are genuinely, transparently pleased to be there, and whatever runs the palace finds it has nothing to work with. It lets you go, baffled.
<!--@end-->


#### **walk_the_line** — *blue* — requires yoga 5

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.walk_the_line.text -->
Go in, take nothing, eat nothing, leave
<!--@end-->


*Outcome*

`karma: god+10, human+3  ·  xp: 30  ·  pressure: fire+25, space+20`

<!--@ hungry_ghost_events.json | hg_illusory_palace | choices.walk_the_line.outcome.text -->
You walk the whole length of the hall through the music and the light and the smell of roast lamb, decline everything offered with perfect courtesy, and go out the far door. The hosts cannot touch a guest who accepts no hospitality; that is the entire rule the illusion is built to exploit, and you have simply not broken it. Behind you somebody throws a plate.
<!--@end-->


---

## hg_illusory_treasure  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_illusory_treasure | title -->
Glittering Trove
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_illusory_treasure | text -->
A hoard, unattended, in the open: coin and plate and gemwork heaped against the base of a bone-wall, glittering in a realm that does not glitter.

There are no tracks around it. There is no reason for it to be here. It is, objectively, the single most suspicious object any of you has ever seen.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.leave.text -->
Obviously not
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.leave.outcome.text -->
You keep walking. The party discusses it for the next hour in the tone of people reassuring themselves.
<!--@end-->


#### **grab** — *grey*

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.grab.text -->
Grab an armful and run
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: hungry_wraith  ·  difficulty: hard  ·  karma: hungry_ghost+5  ·  add_trait: covetous`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.grab.outcome.text -->
The moment your hands close on it the hoard is a hand's-breadth of gravel and something that has been lying underneath it for a long time is sitting up.
<!--@end-->


#### **test** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.test.text -->
Test it from a safe distance first
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 20  ·  gold: 150  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.test.outcome.text -->
You throw a stone into it. The stone does not clink; it lands with the soft sound of gravel. Everything above the third layer is glamour over grit — but the bottom layer, interestingly, is real, and the thing guarding it is asleep. You take the real part slowly and leave the glitter for the next fool.
<!--@end-->


#### **covetous_cannot** — *blue* — requires **trait: covetous**

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.covetous_cannot.text -->
You have already started walking toward it.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: air-12, earth-8`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.covetous_cannot.outcome.text -->
You have. Someone catches your arm and you shake it off, and the arm-catcher lets you go because there is a limit to how much you can save a person from themselves.

What you come back with is worthless and you carry it for two days before admitting that.
<!--@end-->


#### **clear_eyed_sees** — *blue* — requires **trait: clear_eyed**

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.clear_eyed_sees.text -->
Look at the light on it. Light does not do that.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.clear_eyed_sees.outcome.text -->
Light does not do that. It takes about four seconds once you are looking at the right thing, and the right thing is never the treasure.

You can see where whatever laid it is waiting, too, which is more useful than the hoard would have been.
<!--@end-->


#### **bait** — *blue* — requires guile 4

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.bait.text -->
Use the bait against whatever set it
<!--@end-->


*Outcome*

`karma: asura+4, hungry_ghost+2  ·  xp: 26  ·  gold: 240  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_illusory_treasure | choices.bait.outcome.text -->
You rig the hoard — a tripline, a deadfall of bone-wall masonry, and a very convincing set of fresh footprints leading up to it. Then you wait uphill. What comes to collect the next victim collects a quarter ton of wall instead. Its own hoard, it turns out, is somewhere much better hidden and now unguarded.
<!--@end-->


---

## hg_feasting_hall_trap  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | title -->
The Feasting Hall
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | text -->
Long tables, laid for a hundred, in a hall with the roof still on. Food on every platter. Every chair occupied by something that was a guest once and has not left the table since.

At the head, one chair is empty, and a place is set at it. The setting is clean. It has been kept clean.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.leave.text -->
Back out the way you came
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 8`

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.leave.outcome.text -->
Nothing at the tables moves. The empty chair stays empty. You are extremely aware of the clean place-setting for a long time afterwards.
<!--@end-->


#### **sit** — *grey*

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.sit.text -->
Sit in the empty chair
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_noble  ·  difficulty: hard  ·  karma: hungry_ghost+5`

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.sit.outcome.text -->
A hundred heads turn as one. The host has been waiting a very long time for the last guest to arrive, and you have just accepted the invitation.
<!--@end-->


#### **read_hall** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.read_hall.text -->
Work out what the seating means
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost+2  ·  xp: 24  ·  gold: 200  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.read_hall.outcome.text -->
The guests are arranged by precedence and the empty chair is not the host's — it is the *guest of honour's*, and it is set for someone who never came. This entire hall has been holding a place at a party for a person who declined the invitation, for four hundred years, out of spite. You do not sit down. You do steal the silver, which is superb, and nothing at the tables has any protocol for that.
<!--@end-->


#### **release** — *blue* — requires white_magic 4

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.release.text -->
Dismiss the guests
<!--@end-->


*Outcome*

`karma: god+10, human+4  ·  xp: 30  ·  gold: 150  ·  pressure: water+20`

<!--@ hungry_ghost_events.json | hg_feasting_hall_trap | choices.release.outcome.text -->
You go to the head of the table, take the clean place-setting, and clear it — which is, in the grammar of the hall, the host announcing that the last guest is not coming and the meal is over. A hundred bound guests are released from a dinner party at once. Several of them weep. Most simply come apart with an air of enormous relief.
<!--@end-->


---

## hg_body_possession  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_body_possession | title -->
Uninvited Guest
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_body_possession | text -->
One of your party stops walking. Turns around. Smiles.

It is not their smile. The face is doing something faces do not do, and when it speaks the voice is right and the cadence is entirely wrong: "Oh, this is a *good* one. Strong legs. Do you know how long I've been on foot?"
<!--@end-->


### Choices


#### **beat_out** — *grey*

<!--@ hungry_ghost_events.json | hg_body_possession | choices.beat_out.text -->
Beat it out
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: charnel_wraith  ·  difficulty: normal  ·  karma: asura+3  ·  hp_loss: {'amount': 'light', 'target': 'random'}  ·  add_trait: harrowed`

<!--@ hungry_ghost_events.json | hg_body_possession | choices.beat_out.outcome.text -->
It abandons the body the instant real damage starts — vetala are pragmatists — and comes out fighting in its own shape, furious about the inconvenience.
<!--@end-->


#### **bargain** — *grey*

<!--@ hungry_ghost_events.json | hg_body_possession | choices.bargain.text -->
Negotiate for its departure
<!--@end-->


*Outcome*

`karma: hungry_ghost+3, human+2  ·  xp: 10`

<!--@ hungry_ghost_events.json | hg_body_possession | choices.bargain.outcome.text -->
It wants passage, not the body specifically — it is simply tired of walking. You pay it off. It leaves without argument and with genuine thanks, and your companion drops to their knees swearing in a language nobody knew they spoke.
<!--@end-->


#### **exorcise** — *blue* — requires white_magic 3

<!--@ hungry_ghost_events.json | hg_body_possession | choices.exorcise.text -->
Put it out properly
<!--@end-->


*Outcome*

`karma: god+6, human+3  ·  xp: 20  ·  pressure: space-10`

<!--@ hungry_ghost_events.json | hg_body_possession | choices.exorcise.outcome.text -->
The rite is short and extremely unpleasant for everyone in the room. It comes out backwards, complaining bitterly about professional courtesy, and is gone before it hits the ground. Your companion is fine. Your companion is going to want to talk about this later.
<!--@end-->


#### **grudge_bearer_holds_on** — *blue* — requires **trait: grudge_bearer**

<!--@ hungry_ghost_events.json | hg_body_possession | choices.grudge_bearer_holds_on.text -->
Whatever is in there is in one of yours. Do not let go.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: water-8`

<!--@ hungry_ghost_events.json | hg_body_possession | choices.grudge_bearer_holds_on.outcome.text -->
You do not let go. This is the one circumstance in which the thing that is wrong with you is exactly the thing required.

It tries several exits. You are still holding the arm at the end of it, and the face that comes back is the right one.
<!--@end-->


#### **question** — *blue* — requires black_magic 4

<!--@ hungry_ghost_events.json | hg_body_possession | choices.question.text -->
It is in there. Ask it things while it is
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, human-2  ·  xp: 26  ·  gold: 80  ·  items: ['item_random']  ·  pressure: space-15`

<!--@ hungry_ghost_events.json | hg_body_possession | choices.question.outcome.text -->
A possessing spirit is, briefly, a captive audience — it cannot leave without giving up the body, and it does not want to give up the body. You spend a fascinating and deeply unethical twenty minutes interrogating it about the charnel grounds, the courts, and who exactly rules here. Then you let it out. Your companion is going to want to talk about this too, and rather more loudly.
<!--@end-->


---

## hg_sorcerer_of_corpses  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | title -->
Corpse Sorcerer
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | text -->
He is working on a body laid out on a stone bench, and the work is precise — thread, needle, small silver instruments, a diagram weighted at the corners.

"Don't jog the table," he says without looking up. "I have been at this since the moon was somewhere else."
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.leave.text -->
Do not jog the table. Leave.
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.leave.outcome.text -->
The needle goes in and out. He does not notice you go.
<!--@end-->


#### **attack** — *grey*

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.attack.text -->
Whatever he is making, stop him making it
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: corpse_sorcerer  ·  difficulty: hard  ·  karma: god+3, asura+3`

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.attack.outcome.text -->

<!--@end-->


#### **assist** — *blue* — requires medicine 4

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.assist.text -->
Offer to hold the retractors
<!--@end-->


*Outcome*

`karma: human+4, hungry_ghost+3  ·  xp: 24  ·  items: ['item_random']  ·  supplies: {'reagents': 12}  ·  skill_up: {'skill': 'medicine', 'amount': 1, 'cap': 8}`

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.assist.outcome.text -->
He accepts instantly and without surprise, which tells you how long it has been since he had help. Four hours of surgery on a corpse, conducted with total professional courtesy in a place that smells the way this place smells. What he is building turns out to be a body for a friend who lost theirs. He pays you in reagents and technique.
<!--@end-->


#### **diagram** — *blue* — requires black_magic 4

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.diagram.text -->
Read the diagram he is working from
<!--@end-->


*Outcome*

`karma: god+4, human+4  ·  xp: 28  ·  gold: 100  ·  learn_spell: {'school': 'black_magic'}`

<!--@ hungry_ghost_events.json | hg_sorcerer_of_corpses | choices.diagram.outcome.text -->
It is a binding, and it is beautiful work, and it is also — you check twice — inverted at the third node, which means when he finishes, the thing on the table will not be bound to him. It will be bound to nobody, and it will be very strong. You point at the node. There is a long silence while he traces it himself. Then he sits down heavily on the floor and says a word you have not heard before.
<!--@end-->


---

## hg_bone_tower  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_bone_tower | title -->
Bone Tower
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_bone_tower | text -->
Nine storeys of fused bone, tapering, with a stair spiralling up the outside and no rail. It serves no obvious purpose. Nothing lives in it. It simply goes up.

At the base, cut into the lowest course, one word in an old script: HIGHER.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.leave.text -->
Leave it standing
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_bone_tower | choices.leave.outcome.text -->
It is visible from a very long way off, in every direction, for the rest of the day.
<!--@end-->


#### **climb** — *yellow* — requires roll finesse vs difficult

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.climb.text -->
Climb it
<!--@end-->


*Outcome — success*

`karma: human+3, god+3  ·  xp: 22  ·  items: ['item_random']  ·  pressure: air+20`

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.climb.outcome_success.text -->
Nine storeys of no rail. At the top there is a flat platform, a stone bench, and a view of the entire charnel grounds — every fire, every court, every road — laid out like a map somebody drew for you. You sit on the bench for an hour and learn more about this realm than in all the walking that got you here.
<!--@end-->


*Outcome — failure*

`karma: animal+2  ·  xp: 6  ·  hp_loss: {'amount': 'light', 'target': 'random'}  ·  pressure: air-12`

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.climb.outcome_failure.text -->
Somewhere around the sixth storey the wind gets under the party and everyone's nerve goes at once. Coming down is worse than going up. Somebody is sick over the side from a great height.
<!--@end-->


#### **read_tower** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.read_tower.text -->
Work out what it is for
<!--@end-->


*Outcome*

`karma: god+4, human+2  ·  xp: 20  ·  pressure: space+15`

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.read_tower.outcome.text -->
It is a practice structure. The bench at the top faces west; the whole thing is oriented for a specific meditation done at a specific hour, and the climb without a rail is not an obstacle but the first part of the exercise. Somebody built a nine-storey teaching aid out of bones and then, presumably, used it.
<!--@end-->


#### **practice** — *blue* — requires yoga 5

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.practice.text -->
Climb it and do what it was built for
<!--@end-->


*Outcome*

`karma: god+10  ·  xp: 32  ·  pressure: space+30, air+20`

<!--@ hungry_ghost_events.json | hg_bone_tower | choices.practice.outcome.text -->
Up without a rail, sit facing west, and do the thing the structure is asking for — which becomes obvious the moment you are seated, because the whole tower has been shaped to make one particular state of mind the easiest thing available. Whoever built this was extremely good. You come down at dusk not entirely the same.
<!--@end-->


---

## hg_king_messenger  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_king_messenger | title -->
Royal Messenger
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_king_messenger | text -->
A skeleton in the Skeleton King's copper livery reins in a bone horse beside you, unrolls a scroll, and reads without preamble:

"To the living party currently trespassing in the charnel grounds: the King of the Setting Sun requires your attendance. Or your absence. He is flexible. He requires you to choose, in writing, today."
<!--@end-->


### Choices


#### **attend** — *grey*

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.attend.text -->
Sign the attendance
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 10  ·  flags: {'hg_king_summons_accepted': True}`

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.attend.outcome.text -->
The messenger countersigns, stamps it, gives you the counterfoil, and departs at speed. You are now, formally, expected somewhere. It is oddly steadying to have an appointment.
<!--@end-->


#### **absent** — *grey*

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.absent.text -->
Sign the absence
<!--@end-->


*Outcome*

`karma: human+3, hungry_ghost+2  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.absent.outcome.text -->
"Sensible," says the messenger, entirely off the record, and stamps it. "Between us: the ones who attend are usually still there." It gives you a route that avoids the bone city and will not accept payment for the favour.
<!--@end-->


#### **refuse_both** — *grey*

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.refuse_both.text -->
Refuse to sign anything
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: skeleton_patrol  ·  difficulty: normal  ·  karma: asura+3`

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.refuse_both.outcome.text -->
The messenger sighs, rolls the scroll, and raises one hand. The escort you had not noticed comes out of the bone-scrub on three sides.
<!--@end-->


#### **gossip_delays_him** — *blue* — requires **trait: gossip**

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.gossip_delays_him.text -->
A messenger has been everywhere. Keep him talking.
<!--@end-->


*Outcome*

`xp: 20`

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.gossip_delays_him.outcome.text -->
He has orders and a schedule and neither of them survive twenty minutes of being asked, with evident interest, about places he has recently been.

By the time he remembers the schedule you know the state of three roads and one court.
<!--@end-->


#### **amend** — *blue* — requires trade 4

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.amend.text -->
Amend the document before signing
<!--@end-->


*Outcome*

`karma: human+5, asura+2  ·  xp: 22  ·  gold: 80  ·  flags: {'hg_king_safe_conduct': True}`

<!--@ hungry_ghost_events.json | hg_king_messenger | choices.amend.outcome.text -->
You add two clauses in the margin: attendance at a time of your choosing, and safe conduct both ways. The messenger reads them, reads them again, and gets down off the horse to do so properly. Nobody has ever amended one of these. It counter-signs — because the document does not actually forbid it — and rides off looking like a functionary who is going to have an interesting conversation with its superior.
<!--@end-->


---

## hg_corpse_oracle  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_corpse_oracle | title -->
Corpse Oracle
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_corpse_oracle | text -->
A body has been arranged on a platform with its mouth propped open, and a queue of the dead is waiting patiently for their turn to lean in and listen. The corpse itself is quite ordinary and thoroughly deceased.

"It says true things," explains the vetala managing the queue. "Not helpful things. True ones."
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.leave.text -->
Join no queues today
<!--@end-->


*Outcome*


<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.leave.outcome.text -->
The line shuffles forward by one. Somebody at the front leans in, listens, and walks away looking much worse.
<!--@end-->


#### **listen** — *grey*

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.listen.text -->
Take your turn and listen
<!--@end-->


*Outcome*

`karma: human+3  ·  xp: 14  ·  pressure: water-15, space+10`

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.listen.outcome.text -->
You lean over the open mouth. What you hear is one sentence, in your own voice, about something you did before you came to this realm. It is entirely accurate. It is not advice and there is nothing to be done about it. You give up your place in the queue.
<!--@end-->


#### **ask_well** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.ask_well.text -->
Frame a question the truth can actually answer
<!--@end-->


*Outcome*

`karma: human+5  ·  xp: 24  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.ask_well.outcome.text -->
An oracle that only says true things is useless if you ask it what you should do. You ask it something checkable instead — where the horizontal pass lies, what holds the bone bridge together, who the King's messenger reports to. Three answers, all verifiable, all worth having. The vetala managing the queue watches you do this and takes notes.
<!--@end-->


#### **superstitious_takes_it_all** — *blue* — requires **trait: superstitious**

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.superstitious_takes_it_all.text -->
It is an oracle. Write down every word.
<!--@end-->


*Outcome*

`xp: 22  ·  pressure: air-5`

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.superstitious_takes_it_all.outcome.text -->
You take it down complete, including the parts that are clearly the mechanism rather than the message.

One line of it will turn out to matter enormously, and you will not know which until it does, which is precisely the arrangement you have always found bearable.
<!--@end-->


#### **clear_eyed_separates** — *blue* — requires **trait: clear_eyed**

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.clear_eyed_separates.text -->
Sort the prophecy from the plumbing.
<!--@end-->


*Outcome*

`xp: 15`

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.clear_eyed_separates.outcome.text -->
Half of it is the propped jaw and the wind. A quarter is what any dead mouth says. The remaining quarter is specific, and specific is the only part that can be wrong, which is what makes it worth having.
<!--@end-->


#### **release_it** — *blue* — requires ritual 4

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.release_it.text -->
Close the mouth
<!--@end-->


*Outcome*

`karma: god+8, human+3  ·  xp: 26  ·  pressure: water+15`

<!--@ hungry_ghost_events.json | hg_corpse_oracle | choices.release_it.outcome.text -->
Nobody in the queue has thought to ask whether the corpse consented to being an amenity. You perform the closing, and the truth-telling stops, and there is a small ugly moment where the queue considers being angry with you. Then the vetala at the head of it says, "Well. It never said anything good anyway," and the crowd disperses, and the body is allowed to be a body.
<!--@end-->


---

## hg_charnel_hermit  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_charnel_hermit | title -->
Charnel Hermit
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_charnel_hermit | text -->
She has built a hut against the wall of the burning ground and lives in it, alive, by choice, among the smoke and the offerings and the vetala. She is boiling something over a small fire.

"Sit," she says. "You'll want to hear this before you go further in. Most don't. Then most don't come out."
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.leave.text -->
You have somewhere to be
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.leave.outcome.text -->
"Mm," she says, and stirs the pot. She does not seem surprised, which is worse than if she had argued.
<!--@end-->


#### **listen** — *grey*

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.listen.text -->
Sit down and hear it
<!--@end-->


*Outcome*

`karma: human+5, god+2  ·  xp: 18  ·  supplies: {'food': 6}`

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.listen.outcome.text -->
An hour of extremely practical advice about the charnel grounds: which fires to walk upwind of, what the courts consider an insult, why you never accept food, and how to tell an illusion by the smell. It is the single most useful hour of your time in this realm.
<!--@end-->


#### **why_here** — *blue* — requires awareness 14

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.why_here.text -->
Ask why a living woman lives in a burning ground
<!--@end-->


*Outcome*

`karma: god+6, human+3  ·  xp: 22  ·  pressure: earth+20, water+15`

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.why_here.outcome.text -->
"Because it is the only honest place I have ever lived." She has been here nineteen years. She came to do the corpse-ground meditation for a season and found she had no further use for anywhere else. She is not mad, and she is not enlightened, and she is entirely at ease, which in this realm is the rarest thing you have seen.
<!--@end-->


#### **steady_practice_asks** — *blue* — requires **trait: steady_practice**

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.steady_practice_asks.text -->
Ask to sit with her. You will not need it explained.
<!--@end-->


*Outcome*

`xp: 20  ·  pressure: space+12`

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.steady_practice_asks.outcome.text -->
She looks at you for slightly too long and then moves over on the mat.

No instruction is given. None is needed and both of you know it, and the afternoon goes by in a burning ground in complete silence and is one of the better afternoons.
<!--@end-->


#### **practice_with** — *blue* — requires yoga 4

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.practice_with.text -->
Ask to sit the corpse-ground practice with her
<!--@end-->


*Outcome*

`karma: god+10  ·  xp: 30  ·  add_trait: ash_marked  ·  pressure: water+25, space+25`

<!--@ hungry_ghost_events.json | hg_charnel_hermit | choices.practice_with.outcome.text -->
She takes you out among the bodies at the hour when the fires are low and sits you down facing one, and gives you no instruction whatsoever, because there is none. It goes on for a long time. Twice you want to leave. Around the third hour the thing the practice is for happens, briefly, and then you are just a person sitting near a corpse in the cold, which turns out to be the same thing.
<!--@end-->


---

## hg_vetala_arena  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_vetala_arena | title -->
Vetala Arena
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_vetala_arena | text -->
A pit, ringed by tiered seating cut from bone, and it is full — several hundred vetala in their finery, watching two of their own tear at each other on the sand below for entertainment.

The crowd notices you at the entrance tunnel. A chant starts. It is not a friendly chant, but it is unmistakably an invitation.
<!--@end-->


### Choices


#### **fight** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.fight.text -->
Go down onto the sand
<!--@end-->


*Outcome*

`type: combat  ·  enemy_group: vetala_pack  ·  difficulty: hard  ·  karma: asura+5, hungry_ghost+3`

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.fight.outcome.text -->
The crowd noise when a living thing steps onto the sand is something you will hear in your sleep.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.leave.text -->
Back out of the tunnel
<!--@end-->


*Outcome*

`karma: human+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.leave.outcome.text -->
The chant follows you up the tunnel and turns to booing, which is somehow more humiliating than being chased.
<!--@end-->


#### **bookmaker** — *blue* — requires trade 4

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.bookmaker.text -->
Find the bookmaker instead of the sand
<!--@end-->


*Outcome*

`karma: hungry_ghost+4, human+2  ·  xp: 22  ·  gold: 300`

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.bookmaker.outcome.text -->
There is always a bookmaker. His odds are set for a crowd that bets on style rather than outcome, which means the outcome is badly mispriced, which means an afternoon's careful work at the rail is worth more than any purse from the sand. You leave rich and entirely uninjured, which nobody in this building considers a victory except you.
<!--@end-->


#### **stop_it** — *blue* — requires persuasion 5

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.stop_it.text -->
Get the two on the sand to stop
<!--@end-->


*Outcome*

`karma: god+8, human+5  ·  xp: 32  ·  gold: 120`

<!--@ hungry_ghost_events.json | hg_vetala_arena | choices.stop_it.outcome.text -->
You go down and get between them, which is insane, and then talk — not to the fighters, who are past hearing, but to the crowd, about how much more interesting it would be if they *didn't*. It takes everything you have. The crowd, which above all fears being bored, decides that this is the novel thing and stops the fight itself. The two on the sand look at each other, baffled, and are led away by friends.
<!--@end-->


---

## hg_preta_feast_charnel  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | title -->
Preta Feast
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | text -->
The offerings left for the dead are heaped at the edge of the burning ground — rice, cakes, fruit, poured milk — and the pretas are around them in a ring, on their knees, faces inches from the food.

None of it goes in. Their throats will not pass it. They stay anyway, because being near it is the closest thing available.
<!--@end-->


### Choices


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.leave.text -->
Leave them their proximity
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 5  ·  pressure: water-10`

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.leave.outcome.text -->
You go quietly. It is the second-worst thing you have seen in this realm and you are aware you will not remember which was first.
<!--@end-->


#### **burn_offering** — *grey*

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.burn_offering.text -->
Burn the food — smoke, they can take
<!--@end-->


*Outcome*

`karma: god+8, human+4  ·  xp: 20  ·  pressure: water+15`

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.burn_offering.outcome.text -->
It is the oldest solution and the reason the offerings get burnt in the first place: a preta cannot swallow rice but it can take the smoke. You build the fire properly and feed everything into it. The ring closes around the smoke and breathes, and for a while the sound they make is not the sound they were making.
<!--@end-->


#### **rite** — *blue* — requires ritual 4

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.rite.text -->
Do it as the rite prescribes, with the words
<!--@end-->


*Outcome*

`karma: god+12, human+4  ·  xp: 30  ·  pressure: water+25`

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.rite.outcome.text -->
Burnt offering with the dedication spoken over it is a different order of thing from a bonfire — the words are what turn smoke into food. You perform the whole sequence. The ring of pretas eats, properly, for the first time in however long, and one of them thanks you in a language that died before the offerings were stacked.
<!--@end-->


#### **teach** — *blue* — requires yoga 4

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.teach.text -->
Teach them to make the smoke themselves
<!--@end-->


*Outcome*

`karma: god+14, human+5  ·  xp: 34  ·  pressure: water+20, space+15`

<!--@ hungry_ghost_events.json | hg_preta_feast_charnel | choices.teach.outcome.text -->
Feeding them once is an afternoon's work. You spend three days instead, teaching the ring to build and dedicate the fire without you — which is harder, because they have to stop clinging to the heap long enough to learn. Two of them get it. Those two will teach the others. You leave a functioning arrangement behind rather than a full stomach, which is the difference between charity and something better.
<!--@end-->


---

## hg_recruit_mehr  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_mehr | title -->
A Glint in the Dark
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_mehr | text -->
Something catches the light at the bottom of a tar seep — a single gold glint, deep down in the black.

It blinks.

"Yes," says a voice from under the tar, quite calmly. "I can see you too. Only the one eye, mind. Would you mind terribly?"
<!--@end-->


### Choices


#### **haul** — *blue* — requires strength 14

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.haul.text -->
Get her out
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: human+5, god+3  ·  xp: 24`

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.haul.outcome.text -->
It takes both arms and most of an hour and she comes out of the tar in one long appalling motion, tall and black-lacquered and entirely composed. She thanks you, wipes the good eye clear, and says: "You are going to want to hear the last prophecy. Nobody ever does. It was the accurate one."
<!--@end-->


#### **prophecy** — *blue* — requires ritual 3

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.prophecy.text -->
Ask her for the failed prophecy first
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: god+5, human+4  ·  xp: 28  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.prophecy.outcome.text -->
She recites it from under the tar, in the dark, unhurried. It is not a failed prophecy. It is a correct one that arrived at a court that had already decided, and the court's response is why she is in a tar pit.

When you pull her out afterwards, she has already decided you are worth attaching to.
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.hire.text -->
Offer to pay her out
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: mehr  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.hire.outcome.text -->
"A commercial arrangement. Very sensible." She takes the coin with a tar-black hand and does not mention that she would have come for nothing.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.leave.text -->
Leave the tar seep alone
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 3`

<!--@ hungry_ghost_events.json | hg_recruit_mehr | choices.leave.outcome.text -->
"Quite all right," the voice says, receding. "It is not an urgent situation. It has not been urgent for some time."
<!--@end-->


---

## hg_recruit_choki  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_choki | title -->
At the Water's Edge
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_choki | text -->
A dré stands at the edge of a still pool with her feet in the shallows, facing the water. She has been standing there long enough that reeds have grown around her ankles.

"It came down the valley in the afternoon," she says, to nobody. "There was no sound. That's the part I keep coming back to. There should have been a sound."
<!--@end-->


### Choices


#### **listen** — *blue* — requires yoga 3

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.listen.text -->
Let her finish the whole account
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: choki  ·  karma: god+6, human+5  ·  xp: 28`

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.listen.outcome.text -->
It takes two hours and she has clearly never got to the end of it before — she stops three times and each time you wait, and each time she starts again slightly further on. When she reaches the part where she went into the river herself, she stops for a long while.

Then she says, "That's all of it," with enormous surprise, and steps out of the reeds for the first time in however long.
<!--@end-->


#### **water** — *blue* — requires water_magic 4

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.water.text -->
Show her what the water is actually doing
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: choki  ·  karma: god+5, human+4  ·  xp: 26`

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.water.outcome.text -->
You put your hand in the pool and let her feel it the way you feel it: not a thing that took her village, just water, doing what water does, without intent and without memory of having done it. It is not comfort. It is accuracy, and she has been waiting for accuracy.

"Oh," she says. And then, after a while: "Where are you going?"
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.hire.text -->
Ask her to come along and offer to pay
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: choki  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.hire.outcome.text -->
She looks at the coin without much interest, and then at you. "You want me to come." That part seems to land. She comes.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.leave.text -->
Leave her to the water
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 4  ·  pressure: water-12`

<!--@ hungry_ghost_events.json | hg_recruit_choki | choices.leave.outcome.text -->
"There should have been a sound," she says again, behind you.
<!--@end-->


---

## hg_recruit_nangwa  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | title -->
Mid-Sentence
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | text -->
The library is three walls and a floor of wet scroll-pulp. In the middle of it a dré is pacing a tight circle, talking rapidly, gesturing at a diagram that is not there.

"—and therefore, if the third term holds, which it does, which I have shown, then—" He stops. Frowns. Starts again. "—and therefore, if the third term holds—"
<!--@end-->


### Choices


#### **finish** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.finish.text -->
Supply the conclusion
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: human+6, god+3  ·  xp: 30  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.finish.outcome.text -->
You listen through two full cycles, work out where he is going, and say the next line out loud.

He stops dead. Turns around. Looks at you as though you have appeared out of nothing, which from his perspective you have. "Yes," he says. "Yes — that's it — and then the corollary—" and he is off again, but forward this time, and he does not stop for an hour, and at the end of it he is somebody who has finished a thought and needs a new one.
<!--@end-->


#### **space** — *blue* — requires space_magic 4

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.space.text -->
Look at what is holding him in the loop
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: god+5, human+4  ·  xp: 28`

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.space.outcome.text -->
He is not haunting the library. He is caught in about four seconds of it, running them over and over, and the loop is thin enough to see the seam. You cut it. He arrives in the present mid-gesture, extremely disoriented and — once he works out how long it has been — extremely embarrassed.

"Right," he says. "Well. I shall need to see what's been published."
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.hire.text -->
Interrupt and make him an offer
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nangwa  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.hire.outcome.text -->
The interruption works where nothing else has. He accepts the terms distractedly, still gesturing at the diagram, and follows you out still talking.
<!--@end-->


#### **salvage** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.salvage.text -->
Salvage what survived the water
<!--@end-->


*Outcome*

`karma: hungry_ghost+3  ·  xp: 8  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_recruit_nangwa | choices.salvage.outcome.text -->
Three scroll-cases from a high shelf, dry inside. He does not notice you take them. He does not notice you at all.
<!--@end-->


---

## hg_recruit_prashan  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_prashan | title -->
The Question at the Crossroads
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_prashan | text -->
The vetala at the crossroads does not block the road. He simply says, as you pass:

"What is it that you carry everywhere, cannot put down, did not choose, and will lose entirely at the moment you most need it?"

Then he waits, with the air of someone who has waited a very long time and expects to wait longer.
<!--@end-->


### Choices


#### **answer** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.answer.text -->
Answer it
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+6, god+2  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.answer.outcome.text -->
"Your name," you say.

The silence goes on for some time. "...That is not the answer I have," he says at last. "It is better than the answer I have." He gets up off the milestone he has been sitting on for four centuries, dusts himself off, and falls in beside you without being invited. "I shall need considerably more material. You appear to be going somewhere interesting."
<!--@end-->


#### **counter** — *blue* — requires awareness 15

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.counter.text -->
Ask him one he cannot answer
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+5, asura+2  ·  xp: 28`

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.counter.outcome.text -->
"What are you going to do," you ask, "if someone answers it?"

He opens his mouth. Closes it. You watch four hundred years of a very good defensive position collapse in about six seconds. "I had not," he says slowly, "considered that as a live possibility." He is, it turns out, delighted rather than wounded — which is what makes him worth having.
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.hire.text -->
Skip the riddle; offer him employment
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: prashan  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.hire.outcome.text -->
"A commercial answer. Disappointing but valid." He pockets the coin and comes, and asks the riddle again three miles later in case you have improved.
<!--@end-->


#### **walk_on** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.walk_on.text -->
Walk on past
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_recruit_prashan | choices.walk_on.outcome.text -->
"Take your time," he calls after you. "I have some."
<!--@end-->


---

## hg_recruit_nyingje  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | title -->
The One Who Stayed
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | text -->
A silver skeleton is working its way along a row of pretas laid out on mats, doing for each one whatever can be done — water it cannot swallow, a cloth on a forehead that feels nothing, a hand held.

It does not look up. "There are forty-one today. Yesterday there were thirty-nine. I am not gaining."
<!--@end-->


### Choices


#### **help** — *blue* — requires medicine 3

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.help.text -->
Take the other end of the row
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: god+8, human+5  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.help.outcome.text -->
You work the row from the far end and meet in the middle after four hours. Neither of you says anything useful in that time. At the end it straightens up, looks at the mats, and then at you.

"I vowed to remain until every being here found its way out," it says. "I have been assuming that meant standing still." It picks up its bowl and comes with you, and does not look back at the forty-one, which costs it something.
<!--@end-->


#### **vow** — *blue* — requires yoga 4

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.vow.text -->
Ask what the vow actually said
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: god+10, human+4  ·  xp: 32`

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.vow.outcome.text -->
It recites the vow. You point out — carefully, because this is somebody's life's work — that it says *until every being finds its way out*, not *until every being here is comfortable*, and that one of those is a task that can be advanced by leaving this row of mats.

The silence is long. "I have been reading it wrong for eight hundred years," it says, without any bitterness at all. "Well. Shall we go?"
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.hire.text -->
Offer to fund the work if it comes with you
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: nyingje  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.hire.outcome.text -->
It accepts the coin on behalf of the forty-one, arranges for their care with a neighbouring dré, and comes. The arrangement is meticulous. It takes most of the afternoon.
<!--@end-->


#### **supplies** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.supplies.text -->
Leave what supplies you can spare
<!--@end-->


*Outcome*

`karma: god+6, human+3  ·  xp: 12`

<!--@ hungry_ghost_events.json | hg_recruit_nyingje | choices.supplies.outcome.text -->
It accepts without fuss and immediately begins distributing. "Forty-one," it says. "That is better than it was an hour ago."
<!--@end-->


---

## hg_recruit_khedrup  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | title -->
The Auspicious Rock
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | text -->
A preserved one sits cross-legged on a flat rock, reciting at speed, with a tally-board propped beside him and a set of tables weighted down under a stone.

He holds up one finger without breaking the recitation — *wait* — finishes a count, marks the board, and only then looks up. "Auspicious day," he explains. "Triple merit. I am not going to waste it being sociable."
<!--@end-->


### Choices


#### **audit** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.audit.text -->
Check his arithmetic
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: khedrup  ·  karma: god+5, human+5  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.audit.outcome.text -->
The tables are internally consistent and beautifully kept and rest on one bad assumption made four hundred years ago, which he has been compounding ever since. You show him. He recalculates. It takes eleven minutes and the colour, such as it is, goes out of him.

"So the entire ledger," he says.

"The entire ledger."

He sits with it. Then he picks up the tally-board, considers throwing it, and puts it in his bag instead. "I should like to see how other people are doing this," he says.
<!--@end-->


#### **practice** — *blue* — requires ritual 4

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.practice.text -->
Sit down and recite with him
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: khedrup  ·  karma: god+8, human+3  ·  xp: 32`

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.practice.outcome.text -->
You do not argue with the system. You just sit down and do the practice properly beside him for three hours, at the pace it is meant to be done at, which is about a fifth of his.

He speeds up for the first hour out of competitiveness. In the second he slows down. In the third he stops counting altogether, and afterwards he sits very still for a while and does not mark the board.

"That was slower," he says eventually. "Why was that better?"
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.hire.text -->
Point out that travel accrues merit too, and pay him
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: khedrup  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.hire.outcome.text -->
He checks the tables. Pilgrimage does in fact carry a multiplier. He accepts on those grounds and only those grounds, and brings the tally-board.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.leave.text -->
Leave him to the triple merit
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_recruit_khedrup | choices.leave.outcome.text -->
The recitation resumes before you are out of earshot, at the same impossible pace.
<!--@end-->


---

## hg_recruit_rasabhava  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | title -->
The Preservation Lab
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | text -->
A workshop cut into the rock: benches, glassware, a cold-vault, everything labelled in a small exact hand. On the central bench a vessel of clear liquid sits exactly where it was set down, beside a notebook open to a finished page.

The preserved one on the stool beside it inclines his head. "Mixed it the night before. You will notice the date."
<!--@end-->


### Choices


#### **notes** — *blue* — requires alchemy 4

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.notes.text -->
Read the notebook properly
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: rasabhava  ·  karma: human+5, god+3  ·  xp: 30  ·  items: ['item_random']  ·  supplies: {'reagents': 10}`

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.notes.outcome.text -->
The formula is correct. You check it three times because you do not believe a formula for eternal preservation can be correct, and it is. He watches you check it, entirely composed, and you understand that he has been waiting a very long time for somebody who could tell whether it was right.

"It works," you say.

"It works," he agrees. "By eleven hours." And then, after a moment: "I should like to be somewhere else now."
<!--@end-->


#### **console** — *blue* — requires yoga 4

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.console.text -->
Say the only useful thing there is to say about the timing
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: rasabhava  ·  karma: god+8, human+4  ·  xp: 32`

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.console.outcome.text -->
"You would have been preserved," you say. "You would not have been finished."

He considers this for a long time — he is a careful man and does not accept propositions quickly. "An unfalsifiable consolation," he says at last. "But not, I think, a false one." He caps the vessel, labels it with the date and the word UNTESTED, and leaves it on the bench for whoever comes next.
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.hire.text -->
Offer him a laboratory that moves
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: rasabhava  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.hire.outcome.text -->
"A travelling practice." He is packing before you finish the sentence. The glassware is wrapped in eleven minutes; he has clearly rehearsed this.
<!--@end-->


#### **take_vessel** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.take_vessel.text -->
Ask whether you might have the vessel
<!--@end-->


*Outcome*

`karma: hungry_ghost+2  ·  xp: 10  ·  items: ['item_random']  ·  supplies: {'reagents': 8}`

<!--@ hungry_ghost_events.json | hg_recruit_rasabhava | choices.take_vessel.outcome.text -->
"Take it. It is no use to me at this end." He watches it go with the mildest possible expression.
<!--@end-->


---

## hg_recruit_durvasa  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | title -->
The Returned Invoice
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | text -->
The gyelpo is pinned in the air about a foot above the ground, arms out, held there by something that is visibly still working — a curse coming back the way it went, and arriving continuously.

"Contract work," he says, through his teeth, with considerable dignity. "Final commission. The client's target had a *practice*. Would you consider — this is embarrassing — would you consider stabilising the field?"
<!--@end-->


### Choices


#### **stabilize_air** — *blue* — requires air_magic 4

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.stabilize_air.text -->
Take the pressure off the field
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: human+5, hungry_ghost+2  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.stabilize_air.outcome.text -->
The curse is not attacking him; it is *returning*, endlessly, along a channel that never closed. You cannot break it. You can widen it until the flow is survivable, which takes about twenty minutes of extremely careful work.

He comes down onto his feet, straightens his robes, and says: "That is still happening, you understand. It will be happening in a hundred years." Then, with real courtesy: "Where are we going?"
<!--@end-->


#### **stabilize_ritual** — *blue* — requires ritual 4

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.stabilize_ritual.text -->
Close the channel properly
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: god+6, human+5  ·  xp: 34  ·  items: ['item_random']`

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.stabilize_ritual.outcome.text -->
A returned curse runs on an open contract. You do not fight it — you settle it: name the commission, name the client, mark the invoice paid, and close the instrument with the correct forms. It takes an hour and a great deal of chalk.

He lands hard, on his knees, silent for the first time. "Nobody," he says eventually, "has ever thought to *pay it off*."
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.hire.text -->
Cut him down and put him on retainer
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: durvasa  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.hire.outcome.text -->
He accepts the retainer with the professionalism of a man who has never in his life worked without one, and remains, technically, still being cursed.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.leave.text -->
He is a professional curse-caster. Leave him hanging.
<!--@end-->


*Outcome*

`karma: god+3, hell+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_durvasa | choices.leave.outcome.text -->
"Fair," he calls after you, entirely without rancour. "Genuinely — that is fair."
<!--@end-->


---

## hg_recruit_gomchen  **NEW EVENT**

`realm: hungry_ghost`

**Title**

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | title -->
Amid the Contracts
<!--@end-->


**Body**

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | text -->
A gyelpo sits in perfect meditation posture in the middle of a room knee-deep in paper. Contracts, deeds, letters of appointment — thousands of them, all bearing his seal, all still legally in force.

He opens one eye. "I am told this is the practice now. Sitting in it." He does not sound convinced. He does sound like a man who has been trying for a long time.
<!--@end-->


### Choices


#### **read_them** — *blue* — requires learning 4

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.read_them.text -->
Read what he actually signed
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: human+6, god+3  ·  xp: 30`

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.read_them.outcome.text -->
You read for two hours. The contracts are not corrupt — that is the thing. Every one is defensible, procedurally sound, and in the interest of the institution. He never once did anything indefensible. He simply did ten thousand defensible things and ended up here.

You tell him so. It is not absolution and he does not take it as any. But he stops sitting in the paper as though it were a punishment and starts going through it as though it were a problem.
<!--@end-->


#### **dissolve** — *blue* — requires ritual 5

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.dissolve.text -->
Release him from the instruments
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: god+8, human+4  ·  xp: 34`

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.dissolve.outcome.text -->
Every document bearing his seal is a binding he is still party to, and there are, at a rough count, eleven thousand of them. You cannot read them all. You can dissolve the seal itself, which voids the lot at once, and takes most of a day and everything you have.

The paper goes to ash in a single soft rush. He sits in the middle of it with his eyes shut. "A master of ten thousand sutras," he says. "And what got me out was somebody else's paperwork."
<!--@end-->


#### **hire** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.hire.text -->
Offer him a position with no paperwork whatsoever
<!--@end-->


*Outcome*

`type: recruit_companion  ·  companion_id: gomchen  ·  karma: human+2  ·  xp: 6`

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.hire.outcome.text -->
The phrase "no paperwork whatsoever" does more work than the coin. He is on his feet before you have finished the offer.
<!--@end-->


#### **leave** — *grey*

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.leave.text -->
Leave him to the practice
<!--@end-->


*Outcome*

`karma: animal+2  ·  xp: 4`

<!--@ hungry_ghost_events.json | hg_recruit_gomchen | choices.leave.outcome.text -->
He closes the eye again. The paper does not move.
<!--@end-->


---
