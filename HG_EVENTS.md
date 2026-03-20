# Hungry Ghost Realm Events

Source of truth for hungry_ghost_events.json. Edit here, then ask Claude to sync to JSON.

**Outcome types:** `Text` `Combat: group (difficulty)` `Shop: shop_id`
**Choice types:** `[Default]` `[Skill X]` `[Attribute X]` `[Roll: Attribute DC N]`
**Karma realms:** hell / hungry_ghost / animal / human / asura / god
**Difficulties:** normal / hard / boss

**Realm theme:** Insatiable craving. Illusions. Decay. The boundary between memory and hunger.
Compassion is rewarded. Exploitation deepens the trap. Recognition of suffering = awareness/spellpower buffs.

> **Note:** Inline pickups (no-choice reward objects) are already done in hungry_ghost.json.
> This file covers named events only — things with choices and flavor text.

---

## What's in this file (Simple Events — no trader branches, no chains)

**Fetid Swamps:** The Wailing, Will-o-Wisp, Swamp Spirit, Bone Raft, Weeping Shrine, Sacrifice Post, A Sigh of Relief (shared)
**Dry Graveyards:** Funeral Rites, Memory Echo, Skeleton Musician, Dust Storm
**Charnel Grounds:** The Dancing Dead, Spirit Fires, Charnel Feast

## What's NOT here yet (needs writing later)

- Fixed Landmarks: Swamp Warden (pass guardian), Bone Gate Keeper (pass guardian), The Insatiable King (boss)
- Combat events: Zombie Horde, Swamp Toll, Skeleton Patrol, Grave Hound, Skeleton Army, Vetala Arena
- Dungeon events: Sunken Village, Flooded Crypt, Ancient Crypt, Crumbling Mausoleum, Bone Tower, Illusory Palace, etc.
- Trader events: Corpse Merchant, Bone Peddler, Ossuary Bargain, Shadow Market, etc.
- NPC events: Bog Hermit, Bone Collector, Ancestor Spirit, Lost Traveler, Grave Robbers, Forgotten King, etc.
- Event chains: (to be designed separately)

---

## Fixed Landmarks

*(To be written — see object_pools in hungry_ghost.json for IDs: hg_swamp_warden, hg_bone_gate_keeper, hg_boss_insatiable_king)*

---

## Simple Events — Fetid Swamps

---

### THE WAILING (hg_preta_wail)
*Fetid Swamps | Non-blocking | One-time | Icon: event*

A chorus of voices rises from just beneath the waterline — hungry ghosts calling out in a language that is not quite sound. The words, if words they are, convey only need.

**[Default] Press on, ignoring the calls**
→ Text: Nothing reaches you. The voices fade behind you.

**[Roll: Awareness DC 12] Listen carefully — try to understand**
→ Success: One voice becomes distinct. A name. Something that mattered, once, somewhere.
  → Buff: awareness +2 (1 combat) | XP: 20-35
→ Failure: The need fills your mind for a moment. Hollow.
  → Damage: 10

**[Yoga 3] Chant a mantra of compassion for them**
→ The voices quiet, one by one. It doesn't solve anything. It might help anyway.
→ Cleanse | XP: 25-40 | Karma: human+2, hungry_ghost-2

---

### WILL-O-WISP (hg_will_o_wisp)
*Fetid Swamps | Non-blocking | One-time | Icon: npc*

A faint light dances ahead, moving just fast enough to stay out of reach. It has no face — just a glow, and an implied direction.

**[Default] Let it drift away**
→ Text: You watch it go. It doesn't look back.

**[Roll: Finesse DC 13] Follow it**
→ Success: It leads you to a dry patch of ground, then vanishes. Something is buried just beneath the surface.
  → Item (random): water_charm_common, black_charm_common, white_charm_common, earth_charm_common
→ Failure: You step wrong. Bog, not ground. You pull yourself out soaked.
  → Damage: 15

**[Air magic 3 OR Space magic 3] Recognize it as a trapped spirit**
→ You know this pattern. A soul caught between awareness and dissolution. You speak the syllable that releases it. It brightens, briefly, then goes out.
→ XP: 25-45 | Karma: human+3, hungry_ghost+2 | Buff: awareness +2 (1 combat)

---

### SWAMP SPIRIT (hg_swamp_spirit)
*Fetid Swamps | Non-blocking | One-time | Icon: npc*

A translucent figure stands ankle-deep in still water across a narrow channel. It watches you with the expression of someone who has forgotten where they were going.

**[Default] Wave and continue**
→ Text: It raises a hand in response. You don't look back.

**[Roll: Charm DC 11] Speak to it gently — ask if it needs help**
→ Success: It doesn't answer in words, but something shifts. It presses a cold hand briefly to your forehead, then walks away into the mist.
  → Buff: all stats +2 (1 combat) | Karma: human+2
→ Failure: It stares at you for a long moment, then sinks slowly into the water. You're not sure what you said wrong.

**[Yoga 5] Offer guidance toward liberation**
→ You know the practice for this. It takes most of an hour. The spirit becomes more present, then less, then gone — in the right direction.
→ XP: 35-55 | Karma: human+3, hungry_ghost+2

---

### BONE RAFT (hg_bone_raft)
*Fetid Swamps | Non-blocking | One-time | Icon: event*

A crude raft of lashed femurs floats slowly past on the current. Something wrapped in waxed cloth sits in the middle. It's addressed to someone.

**[Default] Let it drift by**
→ Text: Whoever it's for, it's not you.

**[Roll: Finesse DC 10] Grab it before it floats out of reach**
→ Success: You snag it. The cloth is still dry inside.
  → Gold: 20-40 | Item (random): health_potion, mana_potion, scroll_lesser_heal
→ Failure: You lean too far. You get wet. The raft keeps going.
  → Damage: 10

**[Awareness 14] Notice the name on the address — read it before it's gone**
→ You can't retrieve it. But you read the name. It means something, even if you're not sure what yet.
→ XP: 20-35 | Flag: found_bone_raft_name=true

---

### WEEPING SHRINE (hg_weeping_shrine)
*Fetid Swamps | Non-blocking | One-time | Icon: shrine*

A small shrine on a mud-island, half-sunk. Water seeps continuously from the cracks in the stone — it has been weeping so long the ground beneath is stained dark.

**[Default] Make an offering and move on**
→ XP: 10-20 | Karma: human+1

**[Roll: Awareness DC 13] Meditate on what the shrine mourns**
→ Success: The grief becomes specific. A name, a cause, an old loss. Understanding doesn't fix it, but understanding tends to be useful.
  → Buff: awareness +3 (1 combat) | XP: 25-40
→ Failure: Grief doesn't always explain itself. You sit with it anyway.
  → Karma: human+1

**[Ritual 3] Perform a proper purification ceremony**
→ The weeping slows, then stops — for the first time in however long. The shrine feels lighter. So do you.
→ Heal: 30 | Karma: human+3 | XP: 20-35

---

### SACRIFICE POST (hg_sacrifice_post)
*Fetid Swamps | Non-blocking | One-time | Icon: shrine*

A wooden post driven into the mud, hung with trinkets, cloth strips, dried flowers. The offerings are from multiple eras — some ancient, some recent. Whatever this appeases, it is still being appeased.

**[Default] Add something small to the post**
→ Text: It costs you almost nothing.
→ Gold: -5 | Karma: human+1, god+1

**[Roll: Awareness DC 12] Try to identify what this protects against**
→ Success: You piece it together from the nature of the offerings. The swamp has teeth, and this is how the locals have been keeping them dull.
  → Buff: dodge +10 (1 combat) | XP: 15-30
→ Failure: Folk magic doesn't always leave notes. You make a small offering anyway.
  → Karma: human+1

**[Black magic 3] Take several of the more potent-looking charms**
→ They're not yours to take, but they're functional.
→ Item (random): black_charm_common, water_charm_common, earth_charm_common | Karma: hungry_ghost+3, human-2

---

## Simple Events — Dry Graveyards

---

### FUNERAL RITES (hg_funeral_rites)
*Dry Graveyards | Non-blocking | One-time | Icon: event*

A skeleton sits beside a crumbling grave, methodically arranging offerings — flowers long since turned to dust, fruit that is only the shape of fruit. It works without hurry, with complete attention.

**[Default] Don't disturb it**
→ Text: Some things should be left alone. You pass at a respectful distance.

**[Roll: Awareness DC 12] Watch what it is arranging — try to understand**
→ Success: You recognize the pattern. Old funeral rites, obscure but correct. Someone taught this skeleton well.
  → XP: 25-45 | Buff: awareness +2 (1 combat)
→ Failure: You shift your weight. A branch snaps. The skeleton freezes. You hold your breath. Then it continues, ignoring you entirely.

**[Yoga 3 OR Ritual 3] Help perform the rites correctly**
→ It turns to look at you when you kneel. A long pause. Then it extends a handful of dust-flowers toward you, and together you finish the ceremony.
→ Heal: 20 | XP: 30-50 | Karma: human+3, hungry_ghost+2

---

### MEMORY ECHO (hg_memory_echo)
*Dry Graveyards | Non-blocking | One-time | Icon: event*

A shimmer in the graveyard air, like heat haze — but it's cold here. For a moment you see a family at a meal. Vivid, fully real. Then gone, leaving only the smell of food that isn't there.

**[Default] Blink and move on**
→ Text: Some things are just residue of lives. You don't need to understand every one.

**[Roll: Awareness DC 13] Hold the vision — try to understand who they were**
→ Success: A life becomes briefly comprehensible. The attachment, the warmth, and what happened to it.
  → XP: 30-50 | Buff: spellpower +3 (1 combat)
→ Failure: The hunger in the image reaches you before the meaning does. You feel it in your chest for an hour.
  → Damage: 10

**[Black magic 3] Study the echo's magical structure**
→ A well-preserved echo. Whoever imprinted it was powerful in life, and thoroughly unresolved.
→ Buff: focus +2, awareness +2 (1 combat) | Karma: hungry_ghost+1

---

### SKELETON MUSICIAN (hg_skeleton_musician)
*Dry Graveyards | Non-blocking | One-time | Icon: npc*

A skeleton sits on a gravestone, playing a two-stringed instrument with surprising skill. The music is slow and strange and not entirely unpleasant. It stops when it notices you.

**[Default] Nod respectfully and pass**
→ Text: It watches you go. When you're far enough away, the music resumes.

**[Roll: Charm DC 11 OR Performance 3] Play along, or sing**
→ Success: It tilts its head at you, then picks up the tempo. You manage to follow. For a few minutes, in a graveyard in the hungry ghost realm, something like music happens.
  → Karma: human+3 | Buff: charm +2 (1 combat) | XP: 15-30
→ Failure: Your contribution is not musically interesting. The skeleton watches you politely until you stop.

**[Comedy 3] Tell a joke**
→ It makes no sound. But the jaw moves, and the ribcage shakes, and the instrument ends up upright and the musician hunched over it in a posture that can only be described as helpless.
→ Item (random): water_charm_common, black_charm_common, white_charm_common | Karma: human+2

---

### DUST STORM (hg_dust_storm)
*Dry Graveyards | Non-blocking | One-time | Icon: event*

A wall of bone-dry grit sweeps across the graveyard with no warning. There's nowhere to shelter. You're going to take this one.

**[Default] Push through**
→ Damage: 15 | Buff: constitution -2 (1 combat)

**[Roll: Constitution DC 13 OR Finesse DC 13] Brace or dodge**
→ Success: You turn your back, cover your face, wait it out. It passes.
  → Nothing
→ Failure: It's worse than you thought.
  → Damage: 15 | Buff: constitution -2 (1 combat)

**[Earth magic 3] Raise a wind-break**
→ A low ridge of packed earth takes the worst of it. You emerge into clear air already reforming your thoughts about dry graveyards.
→ Buff: constitution +2 (1 combat)

---

## Simple Events — Charnel Grounds

---

### THE DANCING DEAD (hg_dancing_dead)
*Charnel Grounds | Non-blocking | One-time | Icon: event*

A ring of corpses dances in perfect silence around an empty throne. Their movements are stiff but coordinated, as if memory persists where intention does not. They do not appear to notice you.

**[Default] Slip past the outer edge carefully**
→ Text: Whatever they are celebrating, or mourning, continues without you.

**[Roll: Finesse DC 13] Join the ring — dance with them**
→ Success: Your body finds the rhythm. For a moment you are part of something very old and very strange. When the dance ends, you are on the other side of the ring.
  → Buff: finesse +2, luck +2 (1 combat) | Karma: hungry_ghost+2
→ Failure: You misstep. The ring shifts. They look at you all at once. Then, somehow worse, they resume — leaving you outside it.

**[Ritual 3 OR Performance 5] Recognize and complete the ritual**
→ This is a specific ceremony. You've seen fragments of it. You take the empty throne, perform your part. When you rise, the dance resolves — the figures slow, then still, with something like satisfaction.
→ XP: 35-55 | Karma: human+2, hungry_ghost+2

---

### SPIRIT FIRES (hg_spirit_fire)
*Charnel Grounds | Non-blocking | One-time | Icon: event*

Three fires burn without fuel at the edge of the charnel grounds. One is pale blue, one is deep green, one is a color that doesn't have a name. None of them give off heat.

**[Default] Walk around them**
→ Text: They seem to watch you go — or seem to.

**[Roll: Awareness DC 12] Approach and study them**
→ Success: Each one is a distinct consciousness, in the earliest stage of what might become a ghost or might become something else. You learn something from how they burn.
  → Buff: spellpower +3, focus +2 (1 combat)
→ Failure: The nameless-colored one flares. The heat is not physical. You step back.
  → Damage: 10

**[Fire magic 3 OR Sorcery 3] Understand their elemental nature**
→ Three elements, one process. You spend time with each one, and each one teaches you something.
→ Item (random): fire_charm_common, air_charm_common, water_charm_common, earth_charm_common, space_charm_common | XP: 25-45

---

### CHARNEL FEAST (hg_charnel_feast)
*Charnel Grounds | Non-blocking | One-time | Icon: event*

A long table laid out in the open, covered in a feast that looks perfect and smells wrong. Seated pretas reach for food endlessly — it passes through without satisfying anything. The table is infinite. The hunger is infinite. Neither notices you standing at the edge.

**[Default] Turn away quickly**
→ Text: The right call.

**[Roll: Constitution DC 14] Eat anyway — you're hungry, and it looks real enough**
→ Success: It's real enough. Strange but real. It sits wrong for an hour, then doesn't.
  → Heal: 40 | Supply: food +2
→ Failure: You understand, briefly and completely, what it is like to need something and have it provide nothing at all.
  → Damage: 20 | Buff: constitution -3 (1 combat)

**[Yoga 5] Sit with the nature of what you're seeing**
→ You observe the feast without hunger. The pretas slow, one by one, and watch you — the strange creature at the edge of the table who is not reaching. Something about this interests them.
→ XP: 45-65 | Karma: human+3, hungry_ghost-3 | Buff: focus +3 (1 combat)

**[Thievery 3] Pocket the gold candleholders — they look real**
→ They are real. Everything solid about this table is real.
→ Gold: 30-50 | Karma: hungry_ghost+3, human-2

---

## Shared Events

---

### A SIGH OF RELIEF (hg_sigh_of_relief)
*All zones | Non-blocking | One-time | Icon: shrine*

A small cairn with a folded cloth on top. Written in a careful hand: *"You are not as lost as you feel."*

**[Default] Read it. Move on.**
→ Heal: 20 | Mana: 20 | Karma: human+1
