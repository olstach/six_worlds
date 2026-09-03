# Animal Realm — The Map

*The realm blurb, the zones the map is built from, the fixed landmarks, and the pool of settlement names. The zone notes are design comments — they never appear in game, but they are the description the map is generated against.*

*Edit between the anchors. Sizes, terrain weights and spawn densities are generated — change those in `map_configs/animal.json`.*

---


`192×192 tiles  ·  base speed 3.0`


## Realm name

<!--@ map_animal.json | map | name -->
Tiryakloka - The Animal Realm
<!--@end-->


## Realm description

<!--@ map_animal.json | map | description -->
The realm of primal instinct and predation. The vast ocean depths hold naga courts older than memory and makara that swallow ships whole. Inland, the ancient forest is territory — contested, marked, fought over — while the open meadows are the world's great stage, where khadga charge and bhramara darken the sun. The birds live everywhere, but the high places belong to them alone.
<!--@end-->


---

# Zones


## ocean  `ocean`

`rows 128–191`


**Zone note** *(design comment, not shown in game)*

<!--@ map_animal.json | zone.ocean | _comment -->
Bottom section. Entry zone — player arrives from the Hungry Ghost Realm. Vast coastal shelf and open ocean: deep water channels, coral reef flats, rocky islets, sandy shallows. The naga rule here and they remember everything.
<!--@end-->


## Coral Barrier  `coastal_wall`

`rows 120–127  ·  mountain_wall  ·  2–3 passes, width 3`


**Display name** *(shown on the map)*

<!--@ map_animal.json | zone.coastal_wall | display_name -->
Coral Barrier
<!--@end-->


**Zone note** *(design comment, not shown in game)*

<!--@ map_animal.json | zone.coastal_wall | _comment -->
Horizontal wall separating the ocean from the inland zones. A coral barrier ridge — impassable except at tidal passes where the reef breaks. The karka hold these choke-points.
<!--@end-->


## forest  `forest`

`rows 0–119`


**Zone note** *(design comment, not shown in game)*

<!--@ map_animal.json | zone.forest | _comment -->
Upper-left section. Dense canopy — dark, layered, territorial. The forest floor is never quiet. Every fallen log is a claim, every fruiting tree a war. The portal to the Human Realm is hidden in the oldest part, near the northwestern corner.
<!--@end-->


## Thorn Ridge  `ridge`

`rows 0–119  ·  mountain_wall  ·  1–2 passes, width 3`


**Display name** *(shown on the map)*

<!--@ map_animal.json | zone.ridge | display_name -->
Thorn Ridge
<!--@end-->


**Zone note** *(design comment, not shown in game)*

<!--@ map_animal.json | zone.ridge | _comment -->
Vertical wall between forest and meadow. A ridgeline of tumbled boulders, thorn scrub, and dry ravines. Hard to cross but not impossible — the passes tend to be where the old game trails are.
<!--@end-->


## meadow  `meadow`

`rows 0–119`


**Zone note** *(design comment, not shown in game)*

<!--@ map_animal.json | zone.meadow | _comment -->
Upper-right section. Open sky-brushed plains, termite cathedrals, migration routes, watering holes. Exposure is the currency here — the khadga charge, the yaksha mark territory, the bhramara darken the midday sun. More dangerous than the forest because there is nowhere to hide.
<!--@end-->


---

# Fixed landmarks


*Placed by hand rather than rolled. The name is what the player sees on the map marker.*


## The Naga's Greeting  `animal_ocean_naga_greeting`

`event  ·  zone ocean  ·  near_start`


**Marker name**

<!--@ map_animal.json | landmark.animal_ocean_naga_greeting | name -->
The Naga's Greeting
<!--@end-->


## Reef Warden  `animal_karka_reef_warden`

`pass_guardian  ·  zone coastal_wall  ·  at_pass`


**Marker name**

<!--@ map_animal.json | landmark.animal_karka_reef_warden | name -->
Reef Warden
<!--@end-->


## Ridge Predator  `animal_ridge_predator`

`pass_guardian  ·  zone ridge  ·  at_pass`


**Marker name**

<!--@ map_animal.json | landmark.animal_ridge_predator | name -->
Ridge Predator
<!--@end-->


## The King of Beasts  `animal_boss_simha_king`

`boss  ·  zone forest  ·  near_portal`


**Marker name**

<!--@ map_animal.json | landmark.animal_boss_simha_king | name -->
The King of Beasts
<!--@end-->


---

# Settlement names


*The pool of 15 names towns are drawn from. Each is edited on its own — add or remove entries in `map_configs/animal.json`.*


**Naming note** *(design comment)*

<!--@ map_animal.json | location_names | _comment -->
Tibetan/Sanskrit compound names for animal realm settlements — dens, lairs, watering holes, coral grottos, and sacred gathering sites. Vana/Shing=forest, Jala/Tsho=water/lake, Pakshi/Bya=bird, Mriga=deer/animal, Simha=lion, Naga=serpent, Matsya/Nya=fish, Parvata/Ri=mountain, Aranya=wilderness, Vyaghra=tiger, Gaja=elephant. Suffixes: khar=fort, thang=plain, yul=land, lung=valley, pura=city, gram=village.
<!--@end-->


<!--@ map_animal.json | location_names | town[0] -->
Vanakhar
<!--@end-->

<!--@ map_animal.json | location_names | town[1] -->
Jalathang
<!--@end-->

<!--@ map_animal.json | location_names | town[2] -->
Simhakhar
<!--@end-->

<!--@ map_animal.json | location_names | town[3] -->
Mrigapura
<!--@end-->

<!--@ map_animal.json | location_names | town[4] -->
Nagalung
<!--@end-->

<!--@ map_animal.json | location_names | town[5] -->
Vyaghrakhar
<!--@end-->

<!--@ map_animal.json | location_names | town[6] -->
Aranyagram
<!--@end-->

<!--@ map_animal.json | location_names | town[7] -->
Pakshiyul
<!--@end-->

<!--@ map_animal.json | location_names | town[8] -->
Matsyathang
<!--@end-->

<!--@ map_animal.json | location_names | town[9] -->
Tshokhar
<!--@end-->

<!--@ map_animal.json | location_names | town[10] -->
Byathang
<!--@end-->

<!--@ map_animal.json | location_names | town[11] -->
Nyaling
<!--@end-->

<!--@ map_animal.json | location_names | town[12] -->
Klungri
<!--@end-->

<!--@ map_animal.json | location_names | town[13] -->
Vanarapura
<!--@end-->

<!--@ map_animal.json | location_names | town[14] -->
Gajayul
<!--@end-->
