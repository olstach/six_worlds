# Animal Realm — Meadow Workbook

*The meadow's births, one at a time, the way the forest was done: rewrite the prose, add backgrounds and companions where a birth is thin, and note anything that wants a new trait, item or mechanic. Enemies, events and naming lore are here for reference.*

*Prose between the anchors is editable and goes back into the game with `python3 tools/import_review_docs.py`. The **Notes** space at the end of each birth is for you: new backgrounds, companions, traits, digressions — write them any shape you like and we turn them into data together. Notes are not imported, and regenerating this file (`tools/export_review_docs.py`) replaces it, so import and move your notes into data before regenerating.*

*Traits are shown for reference; edit their text in `TRAITS.md`.*

---


## Against the forest


*The forest births have had the full pass. Own = backgrounds only this birth can take; shared = taken by several births but not universal.*


| birth | zone | companions | own bgs | shared bgs | racial traits | archetypes | events |
|---|---|---|---|---|---|---|---|
| Rakshasa | forest | 6 | 5 | 3 | 1 | 3 | 2 |
| Varaha | forest | 7 | 6 | 1 | 2 | 2 | 5 |
| Marjara | forest | 7 | 7 | 2 | 2 | 2 | 6 |
| Gana | forest | 6 | 3 | 7 | 1 | 7 | 4 |
| Mriga | forest | 8 | 4 | 3 | 2 | 3 | 0 |
| Vanara | forest | 2 | 5 | 0 | 1 | 2 | 9 |
| Yaksha | meadow | 1 | 1 | 6 | 1 | 2 | 9 |
| Dura | meadow | 1 | 4 | 1 | 1 | 2 | 5 |
| Khadga | meadow | 2 | 2 | 2 | 1 | 2 | 7 |
| Bhramara | meadow | 1 | 4 | 4 | 1 | 2 | 3 |
| Patanga | meadow | 1 | 1 | 2 | 0 | 2 | 2 |
| Shyena | sky | 1 | 3 | 2 | 3 | 2 | 5 |
| Uluka | sky | 1 | 3 | 0 | 2 | 2 | 2 |


## Known issues

- **Khadga is two animals.** The birth, its body plan (`mantis`), its backgrounds and its enemy archetypes are the mantis. Its naming lore is a rhinoceros — wallows, horns, *The Good Mud*, *Where the Horn Broke*, "May your horn be long" — and so are both its companions: Tikshnashringa means *sharp horn* and charges in straight lines, and Nirvikalpa weighs two thousand pounds. *Khadga* is Sanskrit for both a sword and a rhinoceros, which is probably how it happened. Pick one — or split it into two births, as gana and mriga were split.


---


# Yaksha  `yaksha`

`rare  ·  attributes: strength-1, finesse+2, focus+1, awareness+2, charm+2 (total +6)  ·  affinity: air +3, earth +3  ·  skills: air_magic 2, persuasion 2, ritual 1  ·  body: standard  ·  reincarnation weight: 15`


**Name**

<!--@ races.json | yaksha | name -->
Yaksha
<!--@end-->


**Description**

<!--@ races.json | yaksha | description -->
Something is being guarded — a spring, a hoard, a promise older than the hill it was sworn on. Ask which, and the answer arrives with the weight of a matter settled long before you were born.
<!--@end-->


## Racial traits

- **Guardian's Geas** `guardian_geas` — Bound to a place, a hoard, or a promise made before memory. The binding is not resented; it is the shape of the self. Ask what is being guarded and the answer comes back older than the question.  *(charm +1; ritual +1; pressure earth +5; tags guardian_geas, oath_bound, place_bound)*


## Backgrounds only a yaksha can take  (1)


### Meadow Ward  `meadow_ward`

`births: Yaksha  ·  attributes: charm+1  ·  skills: earth_magic 1, ritual 2, persuasion 1  ·  spells: 1× Earth L1  ·  weight 5`


**Name**

<!--@ backgrounds.json | meadow_ward | name -->
Meadow Ward
<!--@end-->


**Description**

<!--@ backgrounds.json | meadow_ward | description -->
You are bound to a place. The meadow's health is your health. Strangers who wish safe passage learn to speak to you first.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Ancestor Priest `ancestor_priest`, Berserker `berserker`, Caravan Guard `caravan_guard`, Pollen Rishi `pollen_rishi`, Raider `raider`, Still Hunter `still_hunter`


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Sthanumati  `sthanumati`

`zone: meadow  ·  background: meadow_ward  ·  traits: devout, stubborn  ·  cost: 900  ·  starts with: ritual 2, earth_magic 1  ·  carries: leather_vest, earth_charm_common`

- **Devout** `devout` — A sincere and practiced faith shapes every act.  *(yoga +1; ritual +1; pressure space +10; tags devout)*

- **Stubborn** `stubborn` — Hard to sway in any direction — for good or ill.  *(pressure earth -10; tags stubborn)*


**Skills** *(strongest first)*

<!--@ companions.json | sthanumati | build_weights -->
armor, maces, earth_magic
<!--@end-->


**Flavor Text**

<!--@ companions.json | sthanumati | flavor_text -->
Maintains the standing stones nobody else remembers the purpose of. She does not know either. She maintains them anyway, on the grounds that somebody clearly meant it.
<!--@end-->


## Enemies  (2 archetypes)

- **Yaksha Guardian** `animal_yaksha_guardian` — devil frontline; in animal_yaksha_circle
- **Yaksha Shaman** `animal_yaksha_shaman` — devil caster; in animal_yaksha_circle


## Events that mention it  (9)

`animal_sacred_grove`, `animal_meadow_training_camp`, `animal_meadow_town_weapons`, `animal_meadow_town_magic`, `termite_cathedral`, `animal_meadow_yaksha_challenge`, `animal_meadow_yaksha_shaman`, `animal_meadow_yaksha_standing_stones`, `animal_meadow_merchant`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Yaksha are guardians by nature — they define themselves by what they hold, not what they pursue. Names are formal, often compound, and describe a function as much as a person. A yaksha child is named at the moment they first demonstrate awareness of a boundary — when they stand at the edge of something and know, without being told, that they must not let it be crossed. Place names are ancient, maintained across generations, and often coincide with actual boundary markers.

**Parent wishes:** May you guard what matters · May the boundary hold · May nothing cross that you did not allow · May you be remembered at the contract · May your word bind as well as stone

**Personal names** *(~~struck~~ = already a companion)*

- **Shailaka** — of the mountain-stone; permanent as the earth itself
- **Vanaraksha** — forest-guardian; the protector at the boundary of wildness
- **Kshetraka** — of the sacred field; one who knows what is cultivated and what is not
- **Rakshaka** — protector; the function as the name
- **Dharanaka** — the holding one; maintenance as identity
- **Maryadaka** — boundary-keeper; the one who knows the line
- **Palaka** — guardian; brief and final
- **Samraksha** — complete protection; total in their vigilance
- **Sthapanaka** — the establisher; one who sets things in place

**Place names**

- **The Sacred Boundary** — The line they hold; any Yaksha territory's primary name is this
- **The Old Contract** — Where an ancient territorial agreement was struck; the terms are still in force
- **The Offering Ground** — Where tribute is left by those passing through; accepted without thanks, which is the etiquette
- **The Judgment Place** — Where disputes between territories are resolved; both sides must approach from downwind
- **The Eastern Post** — Directional boundary markers; each direction has its Post, visited in rotation
- **The Guardian Tree** — The single tree at the center of the territory; often ancient, always marked


## Gaps

- 1 companion — the forest births sit at six to eight.
- 1 background of its own.
- No companion has these backgrounds: `berserker`, `caravan_guard`, `pollen_rishi`, `raider`, `still_hunter`.
- Standard body plan — no natural weapons or extra limbs.
- No imp/shade-tier archetype.
- 9 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Dura  `dura`

`common  ·  attributes: strength+2, finesse-2, constitution+4, focus-1, awareness-1 (total +2)  ·  affinity: earth +5  ·  skills: earth_magic 1, smithing 1, trade 1  ·  body: standard  ·  reincarnation weight: 45`


**Name**

<!--@ races.json | dura | name -->
Dura
<!--@end-->


**Description**

<!--@ races.json | dura | description -->
Patient and persistent, the Dura have been here longer than most things that walk. They have long mastered the secrets of the earth and became famous as farmers, traders and sturdy warriors.
<!--@end-->


## Racial traits

- **Armored** `armored` — Dense natural plating — chitin, thick hide, or bone — makes this creature hard to put down.  *(constitution +2; finesse -1; tags armored, heavy_form)*


## Backgrounds only a dura can take  (4)


### Root Shaper  `root_shaper`

`births: Dura  ·  skills: enchantment 2, earth_magic 1  ·  weight 4`


**Name**

<!--@ backgrounds.json | root_shaper | name -->
Root Shaper
<!--@end-->


**Description**

<!--@ backgrounds.json | root_shaper | description -->
The tuber doesn't know it's being guided. The root finds the right direction because the direction is good, and you make the direction good. Enchantment is not force — it is a very patient suggestion.
<!--@end-->


### Shell Wright  `shell_wright`

`births: Dura  ·  skills: armor 1, smithing 2  ·  weight 4`


**Name**

<!--@ backgrounds.json | shell_wright | name -->
Shell Wright
<!--@end-->


**Description**

<!--@ backgrounds.json | shell_wright | description -->
The shed carapace is not waste. It is material — harder than wood, lighter than iron, shaped already by the body that wore it. You learned to work it: to cut, to layer, to join. What you make fits the one who will wear it because you understand what it is to be armoured from birth.
<!--@end-->


### Tunnel Merchant  `tunnel_merchant`

`births: Dura  ·  attributes: charm+1  ·  skills: trade 2, logistics 2  ·  weight 6`


**Name**

<!--@ backgrounds.json | tunnel_merchant | name -->
Tunnel Merchant
<!--@end-->


**Description**

<!--@ backgrounds.json | tunnel_merchant | description -->
The surface roads belong to those who fear nothing. The tunnel roads belong to you. Your caravan of great beetles moves slow and sure through passages older than memory, and the surface predators never knew you passed.
<!--@end-->


### Tunneler  `tunneler`

`births: Dura  ·  attributes: strength+1  ·  skills: earth_magic 1, might 1, smithing 2  ·  kit: bronze_mace  ·  weight 6`


**Name**

<!--@ backgrounds.json | tunneler | name -->
Tunneler
<!--@end-->


**Description**

<!--@ backgrounds.json | tunneler | description -->
You dig. What others call the underworld is simply where you work. The roots of the meadow are familiar as a face.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Caravan Guard `caravan_guard`


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Valmika  `valmika`

`zone: meadow  ·  background: tunneler  ·  traits: stubborn, iron_stomach  ·  cost: 700  ·  starts with: smithing 2, earth_magic 1, might 1  ·  carries: bronze_mace, chainmail, scrap_metal`

- **Stubborn** `stubborn` — Hard to sway in any direction — for good or ill.  *(pressure earth -10; tags stubborn)*

- **Iron Stomach** `iron_stomach` — Five second rule!  *(tags iron_stomach, food)*


**Skills** *(strongest first)*

<!--@ companions.json | valmika | build_weights -->
might, maces, enchantment
<!--@end-->


**Flavor Text**

<!--@ companions.json | valmika | flavor_text -->
Digs. Braces. Digs again. Has opinions about load-bearing timber that she will share whether or not you have expressed interest in load-bearing timber.
<!--@end-->


## Enemies  (2 archetypes)

- **Dura Burrower** `animal_dura_burrower` — shade skirmisher; in animal_dura_burrower_encounter
- **Dura Soldier** `animal_dura_soldier` — shade frontline; in animal_dura_burrower_encounter


## Events that mention it  (5)

`animal_forest_town_weapons`, `animal_meadow_town_weapons`, `animal_meadow_dura_patrol`, `animal_meadow_dura_artisan`, `animal_meadow_dura_warren`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Dura measure everything in depth and duration. A name should describe what endures — what goes below, what is made carefully, what roots support. Children are named at the moment they first help dig: they take a stone from the tunnel, they carry earth up and out, and in that moment the sounder watches to see how they work. The name comes from the quality of that first effort. A deliberate child becomes Careful-Layer. A strong child becomes Deep-Strike.

**Parent wishes:** May the earth receive you · May your tunnels be true · May what you make outlast you · May the roots guide you · May you know what is below

**Personal names** *(~~struck~~ = already a companion)*

- **Khanaka** — the digger; one who makes the way
- **Staraka** — layer-by-layer; built from accumulated careful work
- **Garbhika** — of the interior; most at home in the deep
- **Mulaka** — root-seeker; follows what holds things together
- **Prithvika** — of the broad earth; sees the whole stratum
- **Khataka** — excavated; shaped by the work of digging
- **Nilara** — blue-dark earth; the richest soil, deep down
- **Adhaka** — the below one; always headed further down
- **Mritika** — of the good soil; knows quality earth by feel

**Place names**

- **The Deep Warren** — The main tunnel complex — named for depth, not breadth
- **The Root Hall** — Where the largest tree's root system creates natural chambers; coolest and quietest
- **The Seven Exits** — A complex junction designed for escape — the number is the guarantee
- **The Dry Level** — Upper tunnels used in wet season — less comfortable, safer from flooding
- **The First Dig** — The ancestral burrow site; always maintained even when no longer primary
- **The Breathing Hole** — Emergency ventilation shaft; everyone knows its location, no one mentions it to outsiders


## Gaps

- 1 companion — the forest births sit at six to eight.
- No companion has these backgrounds: `root_shaper`, `shell_wright`, `tunnel_merchant`, `caravan_guard`.
- Standard body plan — no natural weapons or extra limbs.
- No imp/devil-tier archetype.
- 9 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Khadga  `khadga`

`uncommon  ·  attributes: finesse+4, constitution-1, awareness+2, charm-1 (total +4)  ·  affinity: air +3  ·  skills: grace 1, martial_arts 2, yoga 1  ·  body: mantis  ·  reincarnation weight: 30`


**Name**

<!--@ races.json | khadga | name -->
Khadga
<!--@end-->


**Description**

<!--@ races.json | khadga | description -->
The blade-limbed mantis, the dragonfly, the ambush grasshopper. They live by the first strike, unconquered in their weight class.
<!--@end-->


## Racial traits

- **Predator's Grace** `predator_grace` — The natural speed and precision of a born hunter.  *(finesse +2; constitution -1; tags swift, predator_grace)*


## Backgrounds only a khadga can take  (2)


### Blade Contemplative  `blade_contemplative`

`births: Khadga  ·  attributes: finesse+1  ·  skills: martial_arts 2, yoga 1  ·  kit: monks_robe, monks_hood  ·  weight 5`


**Name**

<!--@ backgrounds.json | blade_contemplative | name -->
Blade Contemplative
<!--@end-->


**Description**

<!--@ backgrounds.json | blade_contemplative | description -->
The mantis holds perfectly still before it moves. So do you. The strike is not an act of violence — it is the end of a very long thought.
<!--@end-->


### Jaina  `jaina`

`births: Khadga  ·  attributes: awareness+1  ·  skills: yoga 2, ritual 1, learning 1  ·  weight 2`


**Name**

<!--@ backgrounds.json | jaina | name -->
Jaina
<!--@end-->


**Description**

<!--@ backgrounds.json | jaina | description -->
You looked at your blades and understood the problem. They were made for one thing only, and that thing leaves a mark on the soul. You chose the longer road: discipline, the practice of not-harming, and finally the great fast that others call death but you know as the last purification.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Caravan Guard `caravan_guard`, Still Hunter `still_hunter`


*Plus the universal backgrounds every birth can take.*


## Companions  (2)


### Nirvikalpa  `nirvikalpa`

`zone: meadow  ·  background: jaina  ·  traits: devout, patient  ·  cost: 950  ·  starts with: yoga 2, ritual 1, learning 1  ·  carries: rations`

- **Devout** `devout` — A sincere and practiced faith shapes every act.  *(yoga +1; ritual +1; pressure space +10; tags devout)*

- **Patient** `patient` — Once you endure the first impulse, you can wait almost indefinitely.  *(pressure water +10, fire +5; tags patient)*


**Skills** *(strongest first)*

<!--@ companions.json | nirvikalpa | build_weights -->
yoga, white_magic, persuasion
<!--@end-->


**Flavor Text**

<!--@ companions.json | nirvikalpa | flavor_text -->
Will not eat anything that had a face and will not walk where she cannot see the ground, in case of insects. Weighs two thousand pounds. Has never harmed anything.
<!--@end-->


### Tikshnashringa  `tikshnashringa`

`zone: meadow  ·  background: blade_contemplative  ·  traits: composed, stubborn  ·  cost: 900  ·  starts with: martial_arts 2, yoga 1  ·  carries: chainmail`

- **Composed** `composed` — A hard-won calm. Seldom ruffled by what once would have stung.  *(pressure fire +5, water +5; tags composed)*

- **Stubborn** `stubborn` — Hard to sway in any direction — for good or ill.  *(pressure earth -10; tags stubborn)*


**Skills** *(strongest first)*

<!--@ companions.json | tikshnashringa | build_weights -->
swords, might, yoga
<!--@end-->


**Flavor Text**

<!--@ companions.json | tikshnashringa | flavor_text -->
Charges in a straight line and meditates on why. Twenty years of practice have not made him stop charging; they have made him extremely precise about when.
<!--@end-->


## Enemies  (2 archetypes)

- **Khadga Ambusher** `animal_khadga_ambusher` — shade skirmisher; in animal_khadga_pair
- **Khadga Blade** `animal_khadga_blade` — devil frontline; in animal_khadga_pair


## Events that mention it  (7)

`animal_meadow_town_weapons`, `bone_forest`, `animal_meadow_khadga_charge`, `animal_meadow_yaksha_standing_stones`, `animal_meadow_khadga_herd`, `animal_meadow_grassfire`, `animal_meadow_merchant`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Khadga are in no hurry — they name children slowly, watching first. A newborn khadga may go unnamed for an entire season while the parent observes. When the name comes, it is final and heavy, like a footfall. Khadga do not give children aspirational names; they name what they see. A calm child: Stillness. A heavy child: The Great Weight. A child who charges the wall of their enclosure repeatedly: Perhaps the Wall Matters.

**Parent wishes:** May you be unmovable · May the mud cool you · May your horn be long · May nothing require urgency · May the plain be sufficient

**Personal names** *(~~struck~~ = already a companion)*

- **Baladhara** — strength-bearer; the one who holds force without deploying it
- **Ghanaka** — the dense and heavy; occupying space completely
- **Dhritaka** — steadiness itself; will not be moved by argument or urgency
- **Tushara** — tough and fibrous; does not break, ever
- **Sthulaka** — the massive one; presence as statement
- **Vajraka** — diamond-born; impenetrable
- **Sthirava** — stability; the ground beneath the ground
- **Maheshaka** — of the great; one who does not need to prove it

**Place names**

- **The Good Mud** — The best wallow — visited in seasonal rotation, remembered across years
- **The Claim** — Their current territory; not named further, the claim is enough
- **The Thorn Wall** — Natural thornscrub boundary — they did not build it but they maintain it by not breaking through
- **The Long Shade** — A particular stand of trees that provides afternoon relief — crucial in dry season
- **Where the Horn Broke** — Site of an old territorial battle — remembered as landmark even by those who didn't witness it
- **The Deep Drink** — The waterhole — visited at exact same time every day, by individual habit of each khadga


## Gaps

- 2 companions — the forest births sit at six to eight.
- 2 backgrounds of its own.
- No companion has these backgrounds: `caravan_guard`, `still_hunter`.
- No imp-tier archetype.
- 8 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Bhramara  `bhramara`

`uncommon  ·  attributes: strength-1, finesse+1, focus+1, awareness+2, charm+1 (total +4)  ·  affinity: air +3, earth +2  ·  skills: air_magic 1, logistics 1, ritual 1, summoning 1  ·  body: standard  ·  reincarnation weight: 30`


**Name**

<!--@ races.json | bhramara | name -->
Bhramara
<!--@end-->


**Description**

<!--@ races.json | bhramara | description -->
The nature of the relationship between a bhramara and their hive eludes the grasp of even the most empathetic of other beings. What is obvious is their coordination and refinement.
<!--@end-->


## Racial traits

- **Colony Mind** `colony_mind` — Born into a collective, this creature is never truly alone. Shared purpose dampens individual anxiety.  *(pressure fire -5, water -5, earth -5, air -5, space -5; tags colony_mind, collective)*


## Backgrounds only a bhramara can take  (4)


### Hive Architect  `hive_architect`

`births: Bhramara  ·  attributes: constitution+1  ·  skills: earth_magic 1, logistics 1, smithing 2  ·  weight 6`


**Name**

<!--@ backgrounds.json | hive_architect | name -->
Hive Architect
<!--@end-->


**Description**

<!--@ backgrounds.json | hive_architect | description -->
The comb is not built — it grows, cell by cell, through ten thousand coordinated decisions. You were one of them.
<!--@end-->


### Honey-Keeper  `honey_alchemist`

`births: Bhramara  ·  attributes: awareness+1  ·  skills: alchemy 2, medicine 1  ·  weight 5`


**Name**

<!--@ backgrounds.json | honey_alchemist | name -->
Honey-Keeper
<!--@end-->


**Description**

<!--@ backgrounds.json | honey_alchemist | description -->
The honey is not food. It is memory, medicine, and slow fire. You know the difference between a healing batch and a poisoned one.
<!--@end-->


### Node of the Queen's Web  `network_node`

`births: Bhramara  ·  attributes: focus+1  ·  skills: ritual 2, water_magic 1, yoga 1  ·  spells: 1× Water L1  ·  weight 2`


**Name**

<!--@ backgrounds.json | network_node | name -->
Node of the Queen's Web
<!--@end-->


**Description**

<!--@ backgrounds.json | network_node | description -->
You held a position in the real-time flow of the hive's collective mind. Not a soldier, not a builder — a relay, a processor, a voice in the continuous hum.
<!--@end-->


### Swarm Caller  `swarm_caller`

`births: Bhramara  ·  skills: summoning 2, air_magic 1  ·  weight 3`


**Name**

<!--@ backgrounds.json | swarm_caller | name -->
Swarm Caller
<!--@end-->


**Description**

<!--@ backgrounds.json | swarm_caller | description -->
The hive can extend beyond the hive. You learned to ask rather than just know — to reach through the network and draw a portion of it toward you. The swarm comes when called. It is not a weapon. It is a form of speech.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Berserker `berserker`, Caravan Guard `caravan_guard`, Far Scout `far_scout`, Raider `raider`


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Madhuvrata  `madhuvrata`

`zone: meadow  ·  background: swarm_caller  ·  traits: curious, night_owl  ·  cost: 850  ·  starts with: summoning 2, air_magic 1  ·  carries: leather_vest, air_charm_common`

- **Curious** `curious` — Irresistibly drawn to the unknown.  *(learning +1; pressure space +10; tags curious)*

- **Night Owl** `night_owl` — The owl of wisdom flies after midnight.  *(tags night_owl)*


**Skills** *(strongest first)*

<!--@ companions.json | madhuvrata | build_weights -->
performance, summoning, comedy
<!--@end-->


**Flavor Text**

<!--@ companions.json | madhuvrata | flavor_text -->
One voice in a hive of four thousand, seconded to the surface for reasons the hive has not explained to them either. Sings in three parts by themselves.
<!--@end-->


## Enemies  (2 archetypes)

- **Bhramara Drone** `animal_bhramara_drone` — imp support; in no encounter
- **Bhramara Soldier** `animal_bhramara_soldier` — shade frontline; in no encounter


## Events that mention it  (3)

`termite_cathedral`, `animal_meadow_bhramara_swarm`, `animal_meadow_bhramara_hive`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Bhramara individual names are ceremonial constructions given by the hive mind collectively. What the hive names you is what you are. Names describe roles compressed into sounds — a long title reduced to something that can be waggle-danced in seconds. The individual barely matters; the function matters entirely. Place names are extremely precise: defined by flower species, altitude, humidity, and time of day.

**Parent wishes:** May the hive dream you · May your dance be understood · May the flower know your name · May you find the right flower · May the hive never lose you

**Personal names** *(~~struck~~ = already a companion)*

- **Madhuka** — honey-carrier; the essential function
- **Bhramari** — wandering one; the scout, the finder
- **Pushpaka** — flower-keeper; maintains the relationship with the source
- **Rasika** — essence-seeker; extracts the fundamental
- **Kosaka** — comb-builder; architecture of the collective
- **Nrityaka** — dancer; communicates what cannot be spoken
- **Gunaka** — thread-holder; the quality that connects all parts
- **Samajaka** — of the assembly; defined by belonging to the whole

**Place names**

- **The Flower Mountain** — A hillside rich in the hive's preferred species — primary foraging ground
- **The Dance Floor** — The interior chamber where recruitment dances orient the foragers
- **The Dry Crossing** — Dangerous territory between flower sources — no landmarks, high exposure
- **The Enemy Tree** — A location they defend against; not feared, just contested
- **The Sweet Ridge** — Most productive foraging zone; name is also a direction communicated in dance


## Gaps

- 1 companion — the forest births sit at six to eight.
- No companion has these backgrounds: `hive_architect`, `honey_alchemist`, `network_node`, `berserker`, `caravan_guard`, `far_scout`, `raider`.
- Standard body plan — no natural weapons or extra limbs.
- No devil-tier archetype.
- 8 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Patanga  `patanga`

`common  ·  attributes: finesse+1, constitution-1, focus+2, awareness+1, charm-1 (total +2)  ·  affinity: air +2, space +3  ·  skills: air_magic 1, alchemy 1, guile 1  ·  body: standard  ·  reincarnation weight: 45`


**Name**

<!--@ races.json | patanga | name -->
Patanga
<!--@end-->


**Description**

<!--@ races.json | patanga | description -->
Poison, silk, iridescence, and a tendency to appear where least expected, the Patanga know how to kindle fear and wonder alike.
<!--@end-->


## Racial traits

*None.*


## Backgrounds only a patanga can take  (1)


### Flame-Seeker  `flame_seeker`

`births: Patanga  ·  attributes: focus+1  ·  skills: fire_magic 3, yoga 1  ·  spells: 2× Fire L1  ·  spells: 1× Fire L2  ·  weight 2`


**Name**

<!--@ backgrounds.json | flame_seeker | name -->
Flame-Seeker
<!--@end-->


**Description**

<!--@ backgrounds.json | flame_seeker | description -->
The flame is a teacher. You have studied it your whole life. It has not yet consumed you.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Far Scout `far_scout`, Pollen Rishi `pollen_rishi`


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Agnishikha  `agnishikha`

`zone: meadow  ·  background: flame_seeker  ·  traits: devout, addiction  ·  cost: 1000  ·  starts with: fire_magic 3, yoga 1  ·  carries: fire_charm_common`

- **Devout** `devout` — A sincere and practiced faith shapes every act.  *(yoga +1; ritual +1; pressure space +10; tags devout)*

- **Addiction** `addiction` — Dependent on something — herbs, drink, or something stranger.  *(pressure fire -15, earth -5; tags addiction)*


**Skills** *(strongest first)*

<!--@ companions.json | agnishikha | build_weights -->
yoga, fire_magic, ritual
<!--@end-->


**Flavor Text**

<!--@ companions.json | agnishikha | flavor_text -->
Stands facing the sun with his wings spread until sundown, every day, for eleven years. Wants the fire. Does not enter it. That is the whole practice and there is nothing else.
<!--@end-->


## Enemies  (2 archetypes)

- **Patanga Ascetic** `animal_patanga_ascetic` — shade support/caster; in animal_patanga_ascetic_encounter
- **Patanga Flame Seeker** `animal_patanga_seeker` — shade frontline; in animal_patanga_ascetic_encounter


## Events that mention it  (2)

`animal_meadow_patanga_ascetic`, `animal_meadow_patanga_cloud`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Patanga naming is aspirational to the point of ecstasy. They name children for what the child will burn toward. A name is a trajectory. To name a child 'Flame-Seeker' is not prediction; it is summoning. Patanga names are given at the moment of first strong light-response — when the infant turns instinctively toward any source of brightness. That first turn is the name.

**Parent wishes:** May the light find you worthy · May you spiral without fear · May you choose the fire that illuminates · May your offering be accepted · May you burn completely

**Personal names** *(~~struck~~ = already a companion)*

- **Jyotika** — light-seeker; defined by what they move toward
- **Dipaka** — lamp-born; arrived in illumination
- **Tapasvi** — the austerity-one; heat as spiritual practice
- **Ulkika** — meteor-child; a trajectory, not a destination
- **Prakasha** — illumination; not the light but the effect of light
- **Tejasa** — brilliance-born; the quality of fire before the fire
- **Jvalita** — blazing; fully committed
- **Havanaka** — offering-born; came into existence as a gift

**Place names**

- **The Flame That Continues** — The eternal fire temple — seen from outside as the only reliable light source in the meadow
- **The Last Light** — Metaphorical: the point of the journey, whatever form it takes
- **The Offering Ground** — Where past patanga have gone to the flame; remembered without sadness
- **The Cold Place** — Anywhere they do not go; an anti-name, a direction to avoid


## Gaps

- 1 companion — the forest births sit at six to eight.
- 1 background of its own.
- No companion has these backgrounds: `far_scout`, `pollen_rishi`.
- No racial trait.
- Standard body plan — no natural weapons or extra limbs.
- No imp/devil-tier archetype.
- 8 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Shyena  `shyena`  *(sky birth)*

`uncommon  ·  attributes: strength+2, constitution+1, awareness+2, charm-1 (total +4)  ·  affinity: air +3, fire +2  ·  skills: air_magic 1, ranged 2, unarmed 1  ·  body: avian  ·  reincarnation weight: 30`


**Name**

<!--@ races.json | shyena | name -->
Shyena
<!--@end-->


**Description**

<!--@ races.json | shyena | description -->
The stoop is one decision, made at height and never revised. From up there the world sorts cleanly into things worth the dive and things that are not.
<!--@end-->


## Racial traits

- **Flying** `flying` — Sustained winged flight. If the entire party shares this trait, the party may traverse air tiles and elevated terrain in combat and overworld.  *(finesse +1; pressure air -5; tags skyborn, avian, flying)*

- **Armored** `armored` — Dense natural plating — chitin, thick hide, or bone — makes this creature hard to put down.  *(constitution +2; finesse -1; tags armored, heavy_form)*

- **Taloned Strike** `taloned_strike` — Natural weapons of uncommon sharpness.  *(unarmed +1; tags taloned_strike, raptor_kin)*


## Backgrounds only a shyena can take  (3)


### Jessed Hawk  `jessed_hawk`

`births: Shyena  ·  skills: guile 2, learning 1  ·  weight 3`


**Name**

<!--@ backgrounds.json | jessed_hawk | name -->
Jessed Hawk
<!--@end-->


**Description**

<!--@ backgrounds.json | jessed_hawk | description -->
Trained, hooded, tethered, fed by hand. You learned the wrist and the lure, the falconer's whistle, the particular quality of patience that humans confuse with obedience. You watched their settlements from above for years before you understood what you were seeing. Now you are neither fully wild nor fully tame, and you know things that neither world suspects.
<!--@end-->


### Sky Lord  `sky_lord`

`births: Shyena  ·  attributes: awareness+1  ·  skills: unarmed 1, might 1, logistics 1  ·  weight 4`


**Name**

<!--@ backgrounds.json | sky_lord | name -->
Sky Lord
<!--@end-->


**Description**

<!--@ backgrounds.json | sky_lord | description -->
Three valleys. Every road, field, and creature visible at once from the high thermal. Others look at their feet and call that seeing. You look at everything from above and call it home. The ground is not the world. The ground is what you look at when you want to know where you are.
<!--@end-->


### Stooper  `stooper`

`births: Shyena  ·  attributes: finesse+1  ·  skills: unarmed 2, martial_arts 1  ·  weight 5`


**Name**

<!--@ backgrounds.json | stooper | name -->
Stooper
<!--@end-->


**Description**

<!--@ backgrounds.json | stooper | description -->
Two hundred wing-lengths of silent fall. The wind becomes a pressure, then a scream, then nothing — because at the end of the stoop there is no more thinking, only the moment of contact. Everything else you do in your life is preparation for this or recovery from it.
<!--@end-->


**Shared with other births** *(written out under [Shared backgrounds](#shared-backgrounds))*: Ancestor Priest `ancestor_priest`, Blood Drinker `blood_drinker`


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Balavardhana  `balavardhana`

`zone: meadow  ·  background: sky_lord  ·  traits: hot_tempered, brave  ·  cost: 750  ·  starts with: unarmed 2, might 1  ·  carries: leather_vest`

- **Hot-tempered** `hot_tempered` — Quick to anger, slow to forgive.  *(charm -1; pressure water -15; tags hot_tempered)*

- **Brave** `brave` — Faces danger without flinching.  *(pressure air +10, water +5; tags brave)*


**Skills** *(strongest first)*

<!--@ companions.json | balavardhana | build_weights -->
grace, might, swords
<!--@end-->


**Flavor Text**

<!--@ companions.json | balavardhana | flavor_text -->
Holds a thermal over the meadow as his personal fief. Comes down only to settle things, and settles them quickly.
<!--@end-->


## Enemies  (2 archetypes)

- **Shyena Sky Lord** `animal_shyena_lord` — boss frontline; in animal_shyena_with_stooper
- **Shyena Stooper** `animal_shyena_stooper` — devil skirmisher; in animal_shyena_dive, animal_shyena_with_stooper


## Events that mention it  (5)

`animal_garuda_roost`, `birds_congress`, `animal_forest_high_canopy_perch`, `animal_forest_cliff_aerie`, `animal_meadow_thermal_column`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Shyena measure the world in height and angle. Their territory is not the ground below but the airspace above it — measured in altitude bands, thermal columns, and sight lines. A name should describe either a quality of speed or a quality of vision. Children are named at first flight: what the parent saw in the first stoop tells them the name.

**Parent wishes:** May the stoop be clean · May the thermal hold you · May the sky be loyal · May you arrive first · May your eye be exact

**Personal names** *(~~struck~~ = already a companion)*

- **Shyeni** — hawk-born; the pure kind
- **Pratapin** — burning swift; speed as fire
- **Drishtara** — far-seeing; the eye that reaches
- **Kshepa** — the hurler; released downward at speed
- **Drutaka** — swift one; first in every moment
- **Urdhvaka** — the upward one; always gaining altitude
- **Antariksha** — sky-space; not in the sky but of it
- **Vegaka** — velocity; the state before impact

**Place names**

- **The Good Thermal** — A reliable rising column — named per location, this is the best one in range
- **The High Seat** — Main nesting site; a cliff ledge with unobstructed approach and retreat
- **The Stooping Ground** — Hunting territory below — named from the air, looking down
- **The Ridge Wind** — A reliable updraft on a cliff face — used for gaining altitude without effort
- **The First Light** — The position where the morning hunt begins — a compass direction more than a place
- **The Wrong Altitude** — An airspace controlled by another — acknowledged without confrontation


## Gaps

- 1 companion — the forest births sit at six to eight.
- No companion has these backgrounds: `jessed_hawk`, `stooper`.
- No imp/shade-tier archetype.
- 8 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Uluka  `uluka`  *(sky birth)*

`uncommon  ·  attributes: strength-1, finesse+1, constitution-1, focus+2, awareness+3 (total +4)  ·  affinity: space +3, air +2  ·  skills: air_magic 1, learning 2, ritual 1  ·  body: avian  ·  reincarnation weight: 30`


**Name**

<!--@ races.json | uluka | name -->
Uluka
<!--@end-->


**Description**

<!--@ races.json | uluka | description -->
They ask questions in the tone of someone who already has the answer and is deciding whether you deserve it. Nothing that hunts in silence is ever entirely trusted.
<!--@end-->


## Racial traits

- **Flying** `flying` — Sustained winged flight. If the entire party shares this trait, the party may traverse air tiles and elevated terrain in combat and overworld.  *(finesse +1; pressure air -5; tags skyborn, avian, flying)*

- **Night Vision** `night_vision` — Sees equally in darkness and light, perceiving what others miss.  *(awareness +1; tags night_vision, owl_kin)*


## Backgrounds only a uluka can take  (3)


### Fortune Seeker  `fortune_seeker`

`births: Uluka  ·  skills: thievery 1, trade 1, guile 1  ·  weight 4`


**Name**

<!--@ backgrounds.json | fortune_seeker | name -->
Fortune Seeker
<!--@end-->


**Description**

<!--@ backgrounds.json | fortune_seeker | description -->
The hollow log three wing-lengths off the ground, just off the north pass — there is silver in it. You know this the way you know where the mice run. The buried thing, the hidden cache, the lost object — they have a particular quality in the dark that found and visible things lack. Lakshmi moves in circles you can follow.
<!--@end-->


### Ill Omen  `ill_omen`

`births: Uluka  ·  skills: black_magic 2, performance 1  ·  weight 2`


**Name**

<!--@ backgrounds.json | ill_omen | name -->
Ill Omen
<!--@end-->


**Description**

<!--@ backgrounds.json | ill_omen | description -->
You have been appearing before catastrophes since before you can remember. You arrive; something happens. You learn not to take it personally. Eventually you learn to take it very personally — to arrive where you choose, and let the catastrophe follow from that. An omen is only uncontrolled prophecy.
<!--@end-->


### Night Scholar  `night_scholar`

`births: Uluka  ·  skills: learning 2, black_magic 1  ·  weight 4`


**Name**

<!--@ backgrounds.json | night_scholar | name -->
Night Scholar
<!--@end-->


**Description**

<!--@ backgrounds.json | night_scholar | description -->
The waypoint at midnight is a different place than the waypoint at noon. The day-birds leave things: messages, feathers, the warm impressions of bodies on stone. You read it all. You know more about what happens in the light hours than any creature who was there for them. Knowledge accumulates in the dark.
<!--@end-->


*Plus the universal backgrounds every birth can take.*


## Companions  (1)


### Kshudraka  `kshudraka`

`zone: meadow  ·  background: fortune_seeker  ·  traits: greedy, night_owl  ·  cost: 800  ·  starts with: trade 1, thievery 1, guile 1  ·  carries: item_random`

- **Greedy** `greedy` — Always calculating what they stand to gain.  *(trade +1; pressure fire -10, earth -5; tags greedy)*

- **Night Owl** `night_owl` — The owl of wisdom flies after midnight.  *(tags night_owl)*


**Skills** *(strongest first)*

<!--@ companions.json | kshudraka | build_weights -->
guile, black_magic, space_magic
<!--@end-->


**Flavor Text**

<!--@ companions.json | kshudraka | flavor_text -->
Trades in omens, debts, and things people would rather forget they said. Nocturnal, immaculately polite, and never once has she been the one holding the loss.
<!--@end-->


## Enemies  (2 archetypes)

- **Uluka Nightwatcher** `animal_uluka_nightwatcher` — shade ranged/caster; in no encounter
- **Uluka Ill Omen** `animal_uluka_omen` — devil caster; in animal_uluka_omen_encounter


## Events that mention it  (2)

`animal_meadow_cliff_oracle`, `animal_meadow_thermal_column`


## Naming lore  *(reference — edit in `ANIMAL_NAMES.md`)*

> Uluka are the most deliberate namers of all births. They watch a child for a full season before naming. What is observed in that season becomes the name — not what is hoped, but what is seen. 'You cannot name what you haven't watched,' they say. Place names are named for specific events of perception: what was heard there, what was seen from there, what was understood in that location for the first time.

**Parent wishes:** May you see what others miss · May the night be generous · May you carry the knowledge · May silence serve you · May you understand before you act

**Personal names** *(~~struck~~ = already a companion)*

- **Uluki** — owl-pure; the complete form of the birth
- **Nishaka** — night-born; arrived in the generous dark
- **Jnanaka** — knowledge-bearer; carries it as identity
- **Drishti** — sight; vision as the whole self
- **Munika** — the silent sage; speaks rarely, nothing lost in the silence
- **Ratriki** — night-child; the dark is home
- **Viveka** — discernment; the exact quality that distinguishes the uluka
- **Nishadaka** — night-dweller; fully inhabited in darkness

**Place names**

- **The Silent Rock** — Primary perch — chosen for the quality of the surrounding silence
- **The Hunting Dark** — Night territory — not a place but a time-within-place
- **The Hollow Where I Heard** — A specific discovery site — personalised, not transferable
- **The Old Tree** — Ancestral roost; old enough that no uluka alive remembers who first claimed it
- **The Dreaming Point** — Where they wait for dawn — a specific spot, used by many generations
- **The Bright Danger** — The open daylit meadow — avoided, disorienting, remembered as warning


## Gaps

- 1 companion — the forest births sit at six to eight.
- No companion has these backgrounds: `ill_omen`, `night_scholar`.
- No imp-tier archetype.
- 8 unused names ready for new companions.


## Notes

*Your space — new backgrounds, companions, traits, ideas.*




---


# Shared backgrounds


*Backgrounds several births can take. Births outside this workbook are listed too — an edit here changes it for them as well.*


## Ancestor Priest  `ancestor_priest`

`births: Rakshasa, Gana, Varaha, Shyena, Yaksha  ·  skills: white_magic 1, black_magic 1, ritual 1  ·  kit: prayer_beads  ·  weight 5`

*Companions: Ghoraka, Takshari*


**Name**

<!--@ backgrounds.json | ancestor_priest | name -->
Ancestor Priest
<!--@end-->


**Description**

<!--@ backgrounds.json | ancestor_priest | description -->
The chiefs and heroes are laid to rest with the trophies of their most glorious hunts and offered blood mead when the moon is full.
<!--@end-->


## Berserker  `berserker`

`births: human, nomad, mountain_folk, tsen, rudra, Bhramara, Yaksha, red_devil, green_devil, skeleton, Gana  ·  attributes: strength+2, constitution+1, finesse-1, awareness-2  ·  skills: axes 2, unarmed 1  ·  kit: bone_dagger, leather_vest  ·  weight 5`

*Companions: none*


**Name**

<!--@ backgrounds.json | berserker | name -->
Berserker
<!--@end-->


**Description**

<!--@ backgrounds.json | berserker | description -->
A warrior who fights with uncontrolled fury, trading precision for annihilating force.
<!--@end-->


## Blood Drinker  `blood_drinker`

`births: Rakshasa, Marjara, Gana, Shyena, Makara  ·  skills: might 1, guile 1, black_magic 1  ·  weight 5`

*Companions: Kruddha*


**Name**

<!--@ backgrounds.json | blood_drinker | name -->
Blood Drinker
<!--@end-->


**Description**

<!--@ backgrounds.json | blood_drinker | description -->
This is not their first incarnation in this body, and probably not the last, looking on how they savour the hunt.
<!--@end-->


## Caravan Guard  `caravan_guard`

`births: Dura, Khadga, Bhramara, Yaksha  ·  attributes: strength+1  ·  skills: armor 1, spears 1, might 1  ·  kit: iron_trishula, leather_vest  ·  weight 7`

*Companions: none*


**Name**

<!--@ backgrounds.json | caravan_guard | name -->
Caravan Guard
<!--@end-->


**Description**

<!--@ backgrounds.json | caravan_guard | description -->
The trade roads between hive-cities need walking. You walk them heavy and slow, and nothing touches the cargo.
<!--@end-->


## Far Scout  `far_scout`

`births: Bhramara, Patanga  ·  attributes: finesse+1  ·  skills: air_magic 1, logistics 2  ·  kit: bone_dagger  ·  weight 6`

*Companions: none*


**Name**

<!--@ backgrounds.json | far_scout | name -->
Far Scout
<!--@end-->


**Description**

<!--@ backgrounds.json | far_scout | description -->
The hive's eyes go further than its walls. You mapped the meadow in pollen-language and brought it home in your body.
<!--@end-->


## Pollen Rishi  `pollen_rishi`

`births: Patanga, Yaksha  ·  attributes: awareness+1  ·  skills: learning 2, space_magic 1, yoga 1  ·  spells: 1× Space L1  ·  weight 4`

*Companions: none*


**Name**

<!--@ backgrounds.json | pollen_rishi | name -->
Pollen Rishi
<!--@end-->


**Description**

<!--@ backgrounds.json | pollen_rishi | description -->
You move between the flowering nodes of the meadow's invisible geography, accumulating knowledge the way a wing accumulates dust.
<!--@end-->


## Raider  `raider`

`births: human, nomad, tsen, rudra, Bhramara, Yaksha, red_devil, blue_devil, green_devil, yellow_devil, skeleton, vetala, Gana  ·  attributes: strength+1, finesse+1, awareness-1, charm-1  ·  skills: axes 1, guile 1, thievery 1  ·  kit: bone_dagger, leather_vest  ·  weight 5`

*Companions: none*


**Name**

<!--@ backgrounds.json | raider | name -->
Raider
<!--@end-->


**Description**

<!--@ backgrounds.json | raider | description -->
One who takes what they want by force, quick to strike and quicker to vanish.
<!--@end-->


## Still Hunter  `still_hunter`

`births: Khadga, Yaksha  ·  attributes: awareness+1  ·  skills: daggers 2, guile 1  ·  kit: iron_dagger  ·  weight 6`

*Companions: none*


**Name**

<!--@ backgrounds.json | still_hunter | name -->
Still Hunter
<!--@end-->


**Description**

<!--@ backgrounds.json | still_hunter | description -->
You do not chase. You find the right place, and you wait. The prey comes to you eventually. It always does.
<!--@end-->
