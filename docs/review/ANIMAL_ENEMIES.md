# Animal Realm — Bestiary

*34 archetypes across 42 encounter templates. The name is what the player sees over the enemy's head; the note beneath it is a design comment and never appears in game.*

*Edit names and notes between the anchors. Everything else — tier, roles, resistances — is generated from `animal_archetypes.json`.*

---


# Region: forest  (10)


## Gana Howler  `animal_gana_howler`

`tier: shade  ·  roles: support  ·  skills: enchantment, ritual  ·  threat ×1.0`


*Named directly in: animal_gana_full_pack*


**Name**

<!--@ animal_archetypes.json | animal_gana_howler | name -->
Gana Howler
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_gana_howler | _comment -->
Pack support; enchantment perks buff allies and weaken party members
<!--@end-->


## Gana Pack Runner  `animal_gana_runner`

`tier: shade  ·  roles: frontline  ·  ai: pack_bonus  ·  skills: martial_arts, grace  ·  threat ×0.9`


*Named directly in: animal_gana_full_pack*


**Name**

<!--@ animal_archetypes.json | animal_gana_runner | name -->
Gana Pack Runner
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_gana_runner | _comment -->
Pack hunter; grows sharper and harder to hit as more of the pack closes in.
<!--@end-->


## Marjara Ambusher  `animal_marjara_ambusher`

`tier: shade  ·  roles: skirmisher  ·  skills: martial_arts, guile  ·  resists: slashing 5%  ·  threat ×1.0`


*Named directly in: animal_marjara_ambush*


**Name**

<!--@ animal_archetypes.json | animal_marjara_ambusher | name -->
Marjara Ambusher
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_marjara_ambusher | _comment -->
Drops from canopy; guile perks give first-strike advantage; retreats after opening hit
<!--@end-->


## Marjara Stalker  `animal_marjara_stalker`

`tier: devil  ·  roles: skirmisher  ·  skills: daggers, grace  ·  resists: slashing 10%  ·  threat ×1.1`


*Named directly in: animal_marjara_ambush*


**Name**

<!--@ animal_archetypes.json | animal_marjara_stalker | name -->
Marjara Stalker
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_marjara_stalker | _comment -->
Flanking predator; grace perks give evasion while repositioning; attacks from unexpected angles
<!--@end-->


## Rakshasa Hunter  `animal_rakshasa_hunter`

`tier: devil  ·  roles: frontline  ·  skills: unarmed, martial_arts  ·  resists: slashing 10%, physical 5%  ·  threat ×1.2`


**Name**

<!--@ animal_archetypes.json | animal_rakshasa_hunter | name -->
Rakshasa Hunter
<!--@end-->


## Rakshasa Maneater  `animal_rakshasa_maneater`

`tier: boss  ·  roles: frontline  ·  ai: priority_target  ·  skills: unarmed, martial_arts, guile  ·  resists: slashing 15%, physical 10%  ·  threat ×1.6`


*Named directly in: animal_boss_simha_king, animal_rakshasa_maneater_encounter*


**Name**

<!--@ animal_archetypes.json | animal_rakshasa_maneater | name -->
Rakshasa Maneater
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_rakshasa_maneater | _comment -->
Boss-tier lone predator; singles out the weakest and most isolated party member.
<!--@end-->


## Vanara Elder  `animal_vanara_elder`

`tier: shade  ·  roles: support  ·  skills: white_magic, earth_magic, leadership  ·  threat ×1.0`


*Named directly in: animal_vanara_elder_encounter*


**Name**

<!--@ animal_archetypes.json | animal_vanara_elder | name -->
Vanara Elder
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_vanara_elder | _comment -->
Troop director; leadership perks give formation bonuses to nearby vanara
<!--@end-->


## Vanara Skirmisher  `animal_vanara_skirmisher`

`tier: shade  ·  roles: ranged  ·  skills: ranged, alchemy  ·  perks: taunt  ·  threat ×1.0`


*Named directly in: animal_vanara_elder_encounter*


**Name**

<!--@ animal_archetypes.json | animal_vanara_skirmisher | name -->
Vanara Skirmisher
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_vanara_skirmisher | _comment -->
Throws rocks and alchemical bombs; taunt forces party member to attack it; TODO: confuse special attack
<!--@end-->


## Varaha Charger  `animal_varaha_charger`

`tier: shade  ·  roles: frontline  ·  skills: maces, might  ·  resists: physical 10%, crushing 5%  ·  threat ×1.0`


*Named directly in: animal_varaha_elder_encounter*


**Name**

<!--@ animal_archetypes.json | animal_varaha_charger | name -->
Varaha Charger
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_varaha_charger | _comment -->
Tusk charge; maces perk concussive_force gives knockback on crits
<!--@end-->


## Varaha Elder  `animal_varaha_elder`

`tier: devil  ·  roles: support  ·  skills: earth_magic, medicine  ·  resists: earth 15%, physical 10%  ·  threat ×1.1`


*Named directly in: animal_boss_simha_king, animal_varaha_elder_encounter*


**Name**

<!--@ animal_archetypes.json | animal_varaha_elder | name -->
Varaha Elder
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_varaha_elder | _comment -->
Sounder tactician; heals allies via medicine perks; raises aggression when sounder-mates are wounded
<!--@end-->


---


# Region: meadow  (10)


## Bhramara Drone  `animal_bhramara_drone`

`tier: imp  ·  roles: support  ·  skills: summoning, air_magic  ·  resists: air 10%  ·  threat ×0.8`


**Name**

<!--@ animal_archetypes.json | animal_bhramara_drone | name -->
Bhramara Drone
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_bhramara_drone | _comment -->
Support caster that calls reinforcements; weak alone but dangerous when it completes a summon
<!--@end-->


## Bhramara Soldier  `animal_bhramara_soldier`

`tier: shade  ·  roles: frontline  ·  skills: spears, air_magic  ·  resists: air 15%  ·  threat ×1.0`


**Name**

<!--@ animal_archetypes.json | animal_bhramara_soldier | name -->
Bhramara Soldier
<!--@end-->


## Dura Burrower  `animal_dura_burrower`

`tier: shade  ·  roles: skirmisher  ·  ai: burrow_emerge  ·  skills: earth_magic, unarmed  ·  resists: earth 15%, physical 10%  ·  spells: burrow  ·  threat ×1.0`


*Named directly in: animal_dura_burrower_encounter*


**Name**

<!--@ animal_archetypes.json | animal_dura_burrower | name -->
Dura Burrower
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_dura_burrower | _comment -->
Burrows underground and erupts adjacent to its target for a melee strike.
<!--@end-->


## Dura Soldier  `animal_dura_soldier`

`tier: shade  ·  roles: frontline  ·  skills: maces, armor  ·  resists: physical 20%, crushing -10%  ·  threat ×1.0`


*Named directly in: animal_dura_burrower_encounter*


**Name**

<!--@ animal_archetypes.json | animal_dura_soldier | name -->
Dura Soldier
<!--@end-->


## Khadga Ambusher  `animal_khadga_ambusher`

`tier: shade  ·  roles: skirmisher  ·  skills: daggers, guile  ·  resists: slashing 5%  ·  threat ×1.0`


*Named directly in: animal_khadga_pair*


**Name**

<!--@ animal_archetypes.json | animal_khadga_ambusher | name -->
Khadga Ambusher
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_khadga_ambusher | _comment -->
Arrives from concealment; guile perks grant blend_in/cheap_shot; first-strike opening
<!--@end-->


## Khadga Blade  `animal_khadga_blade`

`tier: devil  ·  roles: frontline  ·  skills: unarmed, martial_arts  ·  resists: slashing 10%  ·  threat ×1.2`


*Named directly in: animal_khadga_pair*


**Name**

<!--@ animal_archetypes.json | animal_khadga_blade | name -->
Khadga Blade
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_khadga_blade | _comment -->
Natural mantis blades; very high crit chance from high finesse + unarmed crit perks
<!--@end-->


## Patanga Ascetic  `animal_patanga_ascetic`

`tier: shade  ·  roles: support, caster  ·  skills: air_magic, ritual, yoga  ·  resists: air 20%, fire -15%  ·  threat ×0.9`


*Named directly in: animal_patanga_ascetic_encounter*


**Name**

<!--@ animal_archetypes.json | animal_patanga_ascetic | name -->
Patanga Ascetic
<!--@end-->


## Patanga Flame Seeker  `animal_patanga_seeker`

`tier: shade  ·  roles: frontline  ·  ai: erratic_movement  ·  skills: fire_magic, grace  ·  resists: fire 20%, earth -15%  ·  threat ×1.0`


*Named directly in: animal_patanga_ascetic_encounter*


**Name**

<!--@ animal_archetypes.json | animal_patanga_seeker | name -->
Patanga Flame Seeker
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_patanga_seeker | _comment -->
Moves unpredictably before striking — impossible to anticipate.
<!--@end-->


## Yaksha Guardian  `animal_yaksha_guardian`

`tier: devil  ·  roles: frontline  ·  skills: earth_magic, axes, might  ·  resists: earth 20%, air -10%  ·  threat ×1.1`


*Named directly in: animal_yaksha_circle*


**Name**

<!--@ animal_archetypes.json | animal_yaksha_guardian | name -->
Yaksha Guardian
<!--@end-->


## Yaksha Shaman  `animal_yaksha_shaman`

`tier: devil  ·  roles: caster  ·  skills: earth_magic, summoning  ·  resists: earth 25%  ·  threat ×1.2`


*Named directly in: animal_yaksha_circle*


**Name**

<!--@ animal_archetypes.json | animal_yaksha_shaman | name -->
Yaksha Shaman
<!--@end-->


---


# Region: ocean  (8)


## Karka Crusher  `animal_karka_crusher`

`tier: shade  ·  roles: frontline  ·  skills: unarmed, might  ·  resists: physical 15%, earth 10%  ·  threat ×1.0`


*Named directly in: animal_karka_vent*


**Name**

<!--@ animal_archetypes.json | animal_karka_crusher | name -->
Karka Crusher
<!--@end-->


## Karka Guardian  `animal_karka_guardian`

`tier: devil  ·  roles: frontline  ·  skills: sorcery, maces, armor  ·  resists: physical 20%, earth 15%, crushing -10%  ·  threat ×1.1`


*Named directly in: animal_karka_vent*


**Name**

<!--@ animal_archetypes.json | animal_karka_guardian | name -->
Karka Guardian
<!--@end-->


## Makara Currentmaster  `animal_makara_current`

`tier: devil  ·  roles: caster, support  ·  skills: water_magic, enchantment  ·  resists: water 30%  ·  threat ×1.1`


*Named directly in: animal_makara_with_guard*


**Name**

<!--@ animal_archetypes.json | animal_makara_current | name -->
Makara Currentmaster
<!--@end-->


## Makara Titan  `animal_makara_titan`

`tier: devil  ·  roles: frontline  ·  skills: unarmed, might  ·  resists: water 20%, crushing 15%, physical 10%  ·  threat ×1.4`


*Named directly in: animal_makara_with_guard*


**Name**

<!--@ animal_archetypes.json | animal_makara_titan | name -->
Makara Titan
<!--@end-->


## Matsya Hunter  `animal_matsya_hunter`

`tier: shade  ·  roles: skirmisher  ·  skills: spears, grace  ·  resists: water 15%  ·  threat ×1.0`


*Named directly in: animal_matsya_ambush*


**Name**

<!--@ animal_archetypes.json | animal_matsya_hunter | name -->
Matsya Hunter
<!--@end-->


## Matsya Shoal  `animal_matsya_shoal`

`tier: imp  ·  roles: frontline  ·  ai: pack_bonus  ·  skills: unarmed, water_magic  ·  resists: water 10%  ·  threat ×0.7`


*Named directly in: animal_matsya_ambush*


**Name**

<!--@ animal_archetypes.json | animal_matsya_shoal | name -->
Matsya Shoal
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_matsya_shoal | _comment -->
Weak individually; pack bonus applies when 3+ present in encounter
<!--@end-->


## Naga Sorcerer  `animal_naga_sorcerer`

`tier: devil  ·  roles: caster  ·  skills: water_magic, sorcery, space_magic  ·  resists: water 25%, space 15%  ·  threat ×1.2`


*Named directly in: animal_naga_court, animal_naga_sorcerer*


**Name**

<!--@ animal_archetypes.json | animal_naga_sorcerer | name -->
Naga Sorcerer
<!--@end-->


## Naga Warrior  `animal_naga_warrior`

`tier: devil  ·  roles: frontline  ·  skills: spears, armor, might  ·  resists: water 20%, space 10%  ·  threat ×1.1`


*Named directly in: animal_naga_court, animal_naga_sorcerer*


**Name**

<!--@ animal_archetypes.json | animal_naga_warrior | name -->
Naga Warrior
<!--@end-->


---


# Region: sky  (6)


## Kapota Flock  `animal_kapota_flock`

`tier: shade  ·  roles: frontline  ·  skills: air_magic, grace  ·  resists: air 10%  ·  threat ×0.9`


**Name**

<!--@ animal_archetypes.json | animal_kapota_flock | name -->
Kapota Flock
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_kapota_flock | _comment -->
Flying mob; individually weak but overwhelming in numbers; grace perks give evasion bonus
<!--@end-->


## Kapota Messenger  `animal_kapota_messenger`

`tier: imp  ·  roles: support  ·  skills: air_magic, grace  ·  resists: air 15%  ·  threat ×0.7`


**Name**

<!--@ animal_archetypes.json | animal_kapota_messenger | name -->
Kapota Messenger
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_kapota_messenger | _comment -->
Fast support; disrupts party formation; grace perks make it very hard to pin down
<!--@end-->


## Shyena Sky Lord  `animal_shyena_lord`

`tier: boss  ·  roles: frontline  ·  skills: unarmed, martial_arts, might  ·  resists: air 20%, earth -10%  ·  threat ×1.5`


*Named directly in: animal_shyena_with_stooper*


**Name**

<!--@ animal_archetypes.json | animal_shyena_lord | name -->
Shyena Sky Lord
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_shyena_lord | _comment -->
Territorial boss; might perks give enrage-style bonuses when below 50% HP
<!--@end-->


## Shyena Stooper  `animal_shyena_stooper`

`tier: devil  ·  roles: skirmisher  ·  skills: unarmed, martial_arts  ·  resists: air 15%, earth -10%  ·  threat ×1.1`


*Named directly in: animal_shyena_dive, animal_shyena_with_stooper*


**Name**

<!--@ animal_archetypes.json | animal_shyena_stooper | name -->
Shyena Stooper
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_shyena_stooper | _comment -->
Aerial dive attacker; flying tag; martial_arts perks give first-strike on initial dive
<!--@end-->


## Uluka Nightwatcher  `animal_uluka_nightwatcher`

`tier: shade  ·  roles: ranged, caster  ·  skills: black_magic, ranged  ·  resists: black 10%, air 10%  ·  threat ×1.0`


**Name**

<!--@ animal_archetypes.json | animal_uluka_nightwatcher | name -->
Uluka Nightwatcher
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_uluka_nightwatcher | _comment -->
Fires black magic from range in darkness; high awareness gives initiative advantage
<!--@end-->


## Uluka Ill Omen  `animal_uluka_omen`

`tier: devil  ·  roles: caster  ·  skills: black_magic, performance  ·  resists: black 15%, air 10%, white -15%  ·  threat ×1.2`


*Named directly in: animal_uluka_omen_encounter*


**Name**

<!--@ animal_archetypes.json | animal_uluka_omen | name -->
Uluka Ill Omen
<!--@end-->


**Design note** *(not shown in game)*

<!--@ animal_archetypes.json | animal_uluka_omen | _comment -->
Ill omen debuffer; performance perks like heckle_the_will and stage_fright lower party morale/stats
<!--@end-->


---
