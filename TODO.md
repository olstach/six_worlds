# Six Worlds — TODO

**Last updated:** 2026-11-25

The open list. Organised as: **what to do next → what is still open → designs
waiting to be built → what got done**. The full historical checklists (every
`[x]` line from the psychology, weapons, camp, wounds and body-plan passes) are
preserved in git at commit `73a948c`.

`README.md` holds the current state of the project — realm coverage, content
totals, how to run and verify it. It is not repeated here, because this file
kept a second copy of those numbers and they drifted: as of today it still
claimed 600 perks, 565 items, 103 traits and Godot 4.6 against a real 604, 606,
121 and 4.7.2. One place for facts.

Companion documents:
- `CONTENT.md` — all the game's writing, and an Inbox for new ideas; kept in
  agreement with the JSON by `tools/content_sync.py`
- `docs/superpowers/specs/` — designs approved but not yet built
- `tools/verify_all.sh` — run after any edit

---

## Where to pick up

- [x] ~~**NEXT — one master content document, and a cleaner folder.**~~ —
      **built 2026-10-16.** `CONTENT.md` at the root holds all the writing:
      realms, births, companions, skills, perks, spells, statuses, traits,
      equipment, enemies, events and quests, with an Inbox on top that the
      sync never touches. It is not temporary after all: it stays the place
      to edit for as long as development lasts, and `tools/content_sync.py`
      keeps it and the JSON in agreement both ways (three-way, against
      `tools/content_base.json`; a conflict writes nothing). `verify_all.sh`
      fails while they disagree, so nothing written there can miss a build.
      Numbers stay in the JSON. Retired: `docs/review/` and its two tools,
      `PERKS.md`, `CHARACTERS.md`, `docs/BACKGROUNDS_BY_BIRTH.md`,
      `docs/companion_quirks.md`, the hungry ghost events plan, and the four
      `PERKS.md` scripts (`parse_perks.py` would have overwritten
      `perks.json` from the stale markdown). Text that lived only in markdown
      became `notes:` on its entry (61) or an Inbox item (4). The two missing
      files resolved themselves: `EDIT_LATER.md` never held the wound notes
      — they were in `docs/companion_quirks.md`, and their open items are in
      the Inbox — and the spell list goes in the Inbox if it turns up.
      `docs/plans/`, `docs/superpowers/` and the composer brief were left
      alone, as agreed: history, not content.

**A hell → hungry ghost → animal playthrough.** All three realms are populated
and none of the recent content has been played; the animal realm has never been
played at all. Progression is genuinely gated now (boss seal enforced, boss
events exist), and a large batch of mechanics went from data-only to live
without anyone seeing them move. Use the cheat console to skip ahead.

Worth watching for specifically:

- **First-pass balance numbers** — summoning terrain +25%, pack bonus,
  shield/mirror-image pools, reflect chances, wound-healing prices. All guessed,
  none played.
- **Fight difficulty** — live for the first time since September (built
  2026-10-15, §15). The `easy`/`normal`/`hard`/`very_hard`/`boss` word on
  event fights and map mobs multiplies the enemy party's XP budget: easy
  0.75×, hard 1.2×, very_hard 1.4×; boss is boss-priced with no rolled band
  (all four boss fights already used boss-tier enemies, so no extra
  multiplier). Tune it in the `difficulty` block of
  `resources/data/enemies/encounter_budgets.json`. Watch for: **`hard` is the
  most common word in the data** (103 of 203 fights), so the average fight
  just got about 10% bigger; and extra XP shows up more as skills than HP
  (very_hard is +87% XP over easy but only ~+9% HP in aggregate), so if `hard`
  does not *feel* hard, raise the multipliers before adding any new lever.
- **The wounds and psychology panels** — first look at whether those systems are
  tuned sanely now that they are visible.
- **Active perks.** 75 of them became usable in 2026-09; before that every one
  was greyed out, so none has ever been pressed in a real fight.

Then, depending on appetite:

- **Content:** more quests (the board works but holds three, all hell),
  empty perk flavour (the Perks section of `CONTENT.md`), cursed items.
- **Systems:** the three approved combat designs below, prosthetic items
  (small, unblocks a fully-coded flow), or combat-UI polish (wound icons,
  per-arm damage popups).
- **Big swing:** YidamSystem — the design in Part II is complete enough to
  build, mantra counts already accumulate, and camp Mantra Recitation feeds it
  with nothing reading the result.

- [ ] **All recent prose is Claude's and wants Olaf's pass.** The three hungry
      ghost map-critical events (boss + both pass guardians), the 34 further HG
      events, the 47 animal zone events, and the 24 animal companion bios.
      They are listed in §7; edit them in `CONTENT.md`.

---

## Approved designs not yet built

- [x] **Forced movement and AoE damage falloff** — built 2026-09-12, two of the
      three parts of
      `docs/superpowers/specs/2026-09-12-combat-systems-standardization-design.md`.
      Both are additive: nothing behaves differently until a perk or spell opts
      in.
- [x] **One saving-throw mechanic** — built 2026-09-12. That spec is now fully
      implemented.

---

# Part I — Loose ends

Ordered by how much finished work sits behind each one.

## 1. Small and self-contained

Each of these is an hour or less and touches one system.

- [ ] **8 race descriptions are placeholders** (`TODO: Fill in description`):
  `nomad`, `mountain_folk`, `trader`, `tsen`, `rudra`, `gandharva`, `apsara`,
  `planetary_deity`. All belong to unbuilt realms, so this waits for those.
  (`bee` was the ninth and the only reachable one; it was deleted as a
  duplicate of `bhramara` on 2026-08-31.)
- [x] ~~**`sever_part` doesn't handle `arm_l2`/`arm_r2`**~~ — **checked
      2026-10-15.** It already did, for everything an extra arm can hold:
      `hand_l2`/`hand_r2` are the parts' own `equip_slot`, and the generic path
      clears those exactly as it clears `hand_l`/`hand_r`. There is no weapon to
      drop because there is no weapon slot for a third hand — the gap is in
      equipment, not in severing. The arm→weapon pairing is now a table,
      `BodySystem.ARM_WEAPON_SLOTS`, so a future `weapon_main2` is one line.
      Found on the way: when the inventory was full, severing a primary arm
      "force-cleared" a top-level `weapon_main` key that nothing reads, leaving
      the weapon in the severed hand. It now clears the weapon set.
      `verify_combat_systems` proves both. (No race uses `four_armed` yet.)
- [x] ~~**`extra_arm_results` isn't shown in the combat UI**~~ — **done
  2026-10-15.** It was worse than the line said: each extra arm's hit already
  raised the plain red damage number, but on the same spot at the same moment
  as the primary hit's, so four arms read as one number, and a missed arm
  showed nothing at all. Now the arm's blow is applied with the defender's
  number held back (`CombatUnit.begin_held_damage()` / `end_held_damage()`,
  recorded as `damage_taken` — HP actually lost, the same figure the primary
  popup shows), and the arena's `unit_attacked` handler calls
  `CombatUnit.show_arm_chain_popups()`: "Arm 2: 12", "Arm 3: 30 crit!" (orange),
  "Arm 4: dodge", each 0.25s after the last and nudged sideways. Misses use the
  same Block/Dodge/Miss choice as the primary hit, which moved from the arena
  to `CombatUnit.miss_text_against()`. Each arm result now carries its
  `target`, so a Coordinated Strikes redirect puts the popup — and the log
  line, which used to name the original defender — on the right unit.
  Statuses an arm inflicts already floated on their own. `tools/verify_arm_popups.tscn`
  swings a real four-armed unit and counts one popup per arm.
- [ ] **Combat-UI wound icons** — wounds render in the character sheet; unit
  frames need sprite work.
- [ ] **No race defines any resistance at all.** All 47 carry
  `"resistances": {}`, so `base_resistances` on a character is always empty and
  the skeleton's 50% physical reduction this item used to cite does not exist.
  Racial resistance is a designed-in field that was never filled.

  The original concern underneath it is **fixed 2026-10-15**:
  `EnemySystem._build_enemy()` now starts from the rolled birth's
  `base_resistances` and adds the archetype's on top — added, not replaced, the
  same way a player's racial resistances stack with traits and equipment.
  `verify_resistance` gives the hungry-ghost births a temporary resistance to
  prove it. What is left is the data: races still carry `{}`.
- [ ] **Projectile sprites** — arrows/bolts/firebombs are a `Line2D` flash.
- [x] ~~**Tooltips**~~ — **done 2026-10-15.** The line was half stale: the
  unit's status icons, the turn order and the tile hover label all had some
  text already, but each wrote its own, none read a status's `description`,
  and the tile label never said what the ground was or what a hazard did.
  All of it is now built in one place, `scripts/ui/tooltip_text.gd`
  (`TooltipText`), and used by the status icons over a unit, the status rows
  in the unit info panel and the examine window, the turn-order names (name,
  HP, initiative, statuses) and the floating tile label (ground, passability,
  obstacle, height, hazard with what it does at turn start and which school
  it feeds, zones — hidden traps excluded). `tools/verify_tooltips.tscn`
  builds the strings from the real tables and prints samples. The terrain
  effect wording mirrors `_process_terrain_effects()` by hand — change one,
  change both.
- [ ] **Upgrade selection popup** (choose 1 of 4) — no scene or system exists.
- [ ] **Spell impact sounds** for Air, Water, Earth (fire + generic exist).
- [ ] **Background/realm music** — none.

## 2. Implemented features with no content using them

The mirror image of dead data: code paths that work and are never exercised.

- [x] ~~**`trait` / `not_trait` event requirements**~~ — done in the four-part
  sweep: **201 trait-gated choices** using 77 of the 84 gameplay traits, and
  **76 `add_trait` / `remove_trait` outcomes** covering 30, across 152 of the
  356 events. The five traits with no event presence (`bloodied`,
  `death_touched`, `long_marched`, `maimed`, `mantra_worn`) are the ones code
  hooks grant, which is deliberate — those are earned by playing, not chosen.
  **All of this prose is Claude's and wants a pass.**
- [ ] **Second pass on the sweep, if wanted** — 204 events still carry no trait
  gate. Many genuinely do not want one; a gate on every event would make traits
  read as a checklist. Worth revisiting once the first batch has been played.
- [ ] **Companions have no behavioural traits** — 25 of 31 are on no companion,
  so a behavioural gate currently fires only when the *player* rolled it
  (~3% per trait). Creation now rolls one, which makes them reachable, but
  seeding companions would make the party feel much more distinct. Deliberately
  left to Olaf, since it is companion characterisation.
- [x] ~~**Walking back between worlds**~~ — **done 2026-09-15.** Map state was
      already solved (`MapManager.visited_maps`); navigation is now too. A
      realm's portal is two-way once its far side has been unlocked, carrying
      `origin_realm` and `origin_map` written as the party passes through, and
      the direction it leads depends on which side they are standing on. A way
      back into a realm never unlocked says so rather than silently failing.

      Olaf's reasoning, recorded because it shapes what backtracking is for:
      power scaling means returning is rarely strong — the party outgrows a
      realm — so the value is reaching a shop, temple or trainer again with
      gold and levels they did not have the first time. Backtracking is free;
      no time, supply or karma price was added.

      Still open: nothing yet puts a **return portal** anywhere except the tile
      the party arrived on, so a realm entered by portal has exactly one way
      out and it is where you came in. Fine for now, worth revisiting when
      realms get more content.

- [ ] **Interactions with friendly NPCs and groups.** A mob with the FRIENDLY
      attitude opens an event dialog when the party meets it — but only if it
      carries an `event_id`. There is no default, so a friendly creature
      without one simply stands aside.

      What it wants, roughly in order:
      - **A default parley event** any friendly group can fall back on, so
        meeting one is never silent.
      - **Trade.** ShopSystem exists and handles 91 shops; a wandering group
        with goods is a shop that walks.
      - **Whatever else a friendly group should support** — information about
        the region, a companion offer, passage through territory, a blessing
        from a travelling monk. This is the open half.

      *Open Heart* (White/Ench. 5), a spell turning a hostile creature
      permanently friendly, was designed and then dropped on 2026-09-14
      precisely because of this gap: befriending something is two lines, and a
      spell whose entire point is the conversation afterwards is not finished
      until the conversation exists. Bring it back when this does.

- [ ] **Speaking with the dead — a Black magic perk, with its content.**
      Removed as a spell on 2026-09-15: it had no combat use, no map use, and
      speaking with a corpse is not really a spell — it is a thing a certain
      kind of practitioner can do. It should return as a **Black magic perk**
      that unlocks a blue requirement option at battlefields, charnel grounds
      and fresh graves, letting a party with the training learn something a
      party without it walks past.

      No new machinery: blue options and skill gates both exist. It is waiting
      on written events, and on deciding what the dead are actually worth
      telling you — rumours about the region, what killed them, where they hid
      something, who else passed this way. Deferred until there is content to
      hang on it.

- [ ] **`wound` and `sever_part` event rewards** are still unused by any event —
  nothing in the game maims you outside combat.
- [ ] **Cursed items** — "cursed" is a status and a terrain type; zero cursed
  equipment exists, though the item type is registered.
- [ ] **`mantra_count`** now feeds the practice traits, but the deeper consumer
  is still YidamSystem — see Part II.
- [ ] **`persistent_upgrades`** survives reincarnation in `character_system.gd`,
  but nothing ever grants one. No meta-progression exists.
- [ ] **Camp Followers** — Party-tab UI stub (`_update_followers_list()`), no
  backend.
- [ ] **`tactical_assessment` perk** (Logistics 7) exists in perks.json with no
  code — it was meant to unlock preset formations.

## 3. Implemented systems to tie in

Systems that are built, verified and working, and that existing content does
not know about. These are not gaps in the systems — they are gaps in the
*content that could be using them*, which makes this the checklist to hold open
whenever spells, perks, items or events get reviewed.

The question to ask of each piece of content is not "is this broken" but "would
this be better if it knew about one of these".

**First application: `docs/plans/SPELL_AUDIT.md` (2026-09-13).** Auditing the
363 spells against this list found 15 spells whose whole identity is forced
movement they never got, ~13 asking for auras, and 40 that resolve to nothing
at all when cast. The checklist works; it should be run against perks, items
and events too.

- [ ] **Forced movement** (`_displace_unit`, `_apply_push`) — push, pull and
      the collision rules that come with them: a unit shoved into a wall or
      another unit takes the blocked-damage path instead of moving. Built for
      the perk pass and barely used outside it. A shockwave that only damages
      is a worse shockwave. Worth asking of every Air and Water spell, every
      mace and staff, and anything thematically about *force* rather than
      *heat*.

- [ ] **Auras** (`aura_system.gd`, `resources/data/auras.json`) — a field
      around a unit that affects others by proximity, declarable by equipment,
      a status, a perk, or the unit itself, and reachable by a spell through
      the status it applies. Ten definitions exist and three item lines use
      them. Any spell that currently reads "for N turns, you and nearby allies
      …" is an aura written the long way. Note the two open gaps before leaning
      on it hard: nothing shows an aura in the UI, and the AI does not know
      auras exist, so it will not step into or out of one.

- [ ] **Zones** (`zone.gd`, `resources/data/zones.json`) — an aura with a place
      instead of a body: a footprint of tiles taken from the casting spell's
      own `aoe`, a duration of its own, and three triggers an aura cannot
      offer (`while_inside`, `on_enter`, `on_death_inside`) plus drift. Five
      definitions exist and five spells use them. Any spell that reads "the
      ground stays X afterwards", "enemies entering take", or "while they
      stand there" is a zone written the long way — and a spell may both hit
      and leave one, as Rain of Mud does. Same two gaps as auras: nothing
      draws a zone in the UI, and the AI will not walk around one.

- [ ] **AoE shapes with falloff** (`aoe_resolver.gd`) — circle, nova, line,
      arc, cone, cross, band, plus opt-in per-ring damage falloff. The shape
      vocabulary is much richer than the spell list uses; most area spells are
      still circles. Falloff is opt-in by design and almost nothing opts in.

- [ ] **Saving throws** (`save_system.gd`) — one mechanic, four tiers, and a
      known conversion: one d20 point is five percentage points. Spells that
      roll their own chance-to-apply are not wrong, but they are outside the
      system, which means they cannot be resisted by the stat the player
      levelled for exactly that.

- [ ] **Repositioning** (`repositioning.gd`) — push, pull, teleport, swap,
      scatter, behind, adjacent. One mechanic with a mode, and the split that
      matters is whether the unit *travels* (crosses each tile, can be stopped,
      can be hurt by stopping) or is *placed* (arrives regardless). Ask it of
      anything that moves someone against their will, and of any status that
      should stop that — `prevents_teleportation` refuses the placed modes and
      is readable by any status that wants it.

- [ ] **Status operations** (`status_ops.gd`) — select statuses off a unit by
      name or by group tag, then remove, steal, transfer or convert them.
      Dispel and cleanse are two points on that surface; the others are a spell
      that wears an enemy's blessings, one that hands your party's burning to
      the people who lit it, one that spends its own afflictions as damage. Any
      effect phrased "removes…", "steals…", "transfers…" wants this rather than
      its own branch — and items and events can use it as readily as spells.

- [ ] **Resurrection** (`resurrection.gd`) — three acts, not one: *stabilise*
      a unit still bleeding out, *revive* one dead on the field, *raise* a
      companion the party lost in an earlier fight. The third reaches
      `CharacterSystem.fallen`, the record of the dead, which exists so that a
      shrine or a high-level healing event has someone to name. Offer it from
      events with `"rewards": {"resurrect": {"target": "last"}}`.
      `prevents_resurrection` is the only hard refusal.

- [ ] **Save gates** (`on_failed_save` / `on_passed_save` on a spell) — one
      roll, two branches, carrying statuses, damage, percent-of-max damage or
      outright death. Three separate fields used to say this. Any effect whose
      description contains "or", "unless" or "on a failed save" wants the gate
      rather than its own branch, and perks and items can use the same shape.

- [ ] **Resource operations** (`resource_ops.gd`) — drain, restore or transfer
      health, mana and stamina, with amounts that compose (flat, percent of
      max, percent of current, per spellpower). A vampiric weapon, a
      restorative meal, a karmic bond that shares healing and an exhausting
      event are all this, and none of them is a spell.

- [ ] **Kill rewards** (`on_kill` on a spell) — what a death pays out beyond
      the usual end-of-combat rewards, priced off the victim's `xp_earned` so
      it cannot out-earn the fight. Gold so far; loot, XP and karma are the
      obvious next payouts, and traps and hazards should be able to grant them
      too.

- [ ] **Retaliation** (`retaliation` on a status) — when struck, do something
      to whoever struck you: damage, a status, or a share of what just landed,
      at melee reach or any. Six statuses had six branches for one mechanic.
      Armour that bites back, a thorned familiar, a cursed item and a perk all
      want the same block, and none of them is a status yet.

- [ ] **Granted resistance** (`grants_resistance` on a status) — the symmetric
      partner of `grants_vulnerability`, which existed alone for months. Any
      status can now make you tougher against an element in data rather than
      through a hand-written branch.

- [ ] **Resistible aura payloads** (`save` on an aura's `grant_status`) — an
      aura effect that a target can throw off, with a DC that may fall each
      time that particular target resists it. Shining Mirage wears out against
      anyone who keeps their head. Any aura doing something to a mind rather
      than to a body probably wants this instead of a flat chance.

- [ ] **Per-team outcomes** (`on_allies` / `on_enemies` on a spell) — one
      effect that treats the two sides differently, each branch carrying its
      own statuses and its own save. Up to Eleven stuns the enemy and merely
      rattles your own people. Any area effect with friendly fire wants this
      rather than two spells.

- [ ] **Expiry summons** (`summon_on_expire` on a status) — the fourth
      `*_on_expire`, alongside death, damage and bleed. A status that ripens
      into a creature. Traps, eggs, curses and anything gestating want it.

- [ ] **Party bonuses** (`party_bonuses.gd`) — `party_`-prefixed payouts,
      best member rather than sum.

- [ ] **The fallen have no UI and no narrative reach.**
      `CharacterSystem.fallen` now records everyone the run has lost, and only
      resurrection reads it. Worth more: a memorial screen, events that name
      your specific dead, karma consequences for raising them, and a
      `resurrect` event outcome that lets the player CHOOSE rather than always
      taking the most recent loss — the chooser needs UI and currently defaults
      to "last".

## 4. Terrain and zones — done

**Steps 1–3 done 2026-09-15.** One terrain vocabulary lives in
`resources/data/terrain.json` and is read through `Ground` by the overworld map
and the battle grid alike; battle tiles carry a `ground`; the battlefield is
built in three passes by `BattlefieldGenerator` so the arrangement of the
ground survives the zoom; all fourteen terrains carry battle traits where five
had none. Both tables keyed on bare terrain integers are gone, and
validate_data.py now checks the vocabulary — contiguous ids, a battle block per
terrain, and tile/hazard/obstacle names that CombatGrid actually has.

**Height done 2026-09-15 (step 5).** `relief` per terrain is a ceiling, not a
value: the generator raises mounds across the whole field and each tile takes
the lower of the mound over it and its own ground's relief. So a slope spills
from the hills onto the grass beside them and stops dead at the water's edge,
and mountains rise higher than hills while a road stays graded and level. Even
grassland undulates a little, because not much land is flat.

**Zones done 2026-09-15 (step 4).** A zone is an aura with a place instead of
a body: `Zone` + `resources/data/zones.json` reuse `AuraSystem`'s payload
vocabulary rather than growing a second one, and `validate_data.py` reads
`PAYLOAD_KINDS` out of `aura_system.gd` so the two cannot drift apart. What a
zone has that an aura does not is tiles (from the casting spell's own `aoe`,
so every `AoEResolver` shape comes free), a duration of its own, triggers
(`while_inside`, `on_enter`, `on_death_inside`) and drift. Five zones ship —
`grave_soil`, `shroud_of_darkness`, `vajra_mandala`, `mud`, `tornado` — wiring
five spells that were inert.

Two findings worth remembering, both of the house type:

- **A continuous payload needs a READ hook, not an apply hook.** The mandala's
  `damage_taken_pct` did nothing: auras were asked for it inside `apply_damage`
  and `get_continuous_stat_bonus`, zones were asked nowhere. Sharing a payload
  vocabulary means sharing both halves of it.
- **`_spell_is_offensive()` read `spell.effects`, an array no spell in the
  database has**, so it answered false for every spell ever cast — and the AoE
  targeting branch used it to pick a side. All 57 area spells therefore
  selected the CASTER'S OWN TEAM: Meteor Shower fell on your party and spared
  the enemy standing in it. Who an area spell catches now comes from the
  spell's own `target.eligible`, through `_eligible_reaches()`, which is the
  same word the single-target branch already read.

**Deferred, for want of something else:** `false_terrain` still needs a
renderer that can disguise a tile. `vajra_gate` wanted paired zones, and got
them on 2026-09-16 — `pair: "gate"`, built for The Door Stands Open — so the
spell is now a data entry away.

**The three open questions are answered (2026-09-15).**

- *Battlefields persisting:* **no.** Olaf's reasoning, and it is right — more
  data to keep and to break occasionally, for something nobody would notice.
- *Height:* **yes**, and done. See above.
- *Combat changing the overworld:* **deliberately not built.** The flashy
  version — burn a forest and the tile becomes plains, so fire is a travel
  strategy — pays off rarely, because the party seldom walks back across a
  tile it fought on, and it needs a rule for what every damage type does to
  every terrain. Not worth it.

  The version worth having is smaller and belongs to content that does not
  exist yet: **a tile where a battle happened is marked as a battlefield**, and
  that mark is where the deferred Black magic "speak with the dead" perk finds
  something to speak to. Building the flag now would be data nothing reads —
  the exact bug this project keeps finding — so it is recorded here as part of
  that perk's requirements instead.

---

The original write-up is in `docs/plans/TERRAIN_AUDIT.md`; the headline
is that Olaf's goal — the battle map reading as a zoom into the overworld tile,
Moonring-style — is blocked by two things rather than one.

**The systems share no vocabulary.** The overworld has fourteen `Terrain`
types; the battle grid has `TileType` (5), `TerrainEffect` (11), `ObstacleType`
(6) and a height integer. Nothing is named the same in both, and the two
collisions are false friends: overworld WATER is impassable ground while combat
WATER is a wadeable tile type, and overworld ICE is fast ground while combat
ICE is a hazard sitting on top of one.

**The bridge is statistical, not spatial.** A 5×5 window around the party is
counted, the counts become obstacle budgets, and the obstacles are scattered at
random across 48×30. The battlefield reflects the proportions of nearby terrain
and discards its arrangement — which is exactly the half a zoom needs.

Also found: the terrain-to-battlefield mapping is a `match` on bare integers
with the names in comments (two tables do this, so reordering the enum would
silently remap every battlefield); five of fourteen terrains generate nothing
at all, so a desert fight looks like a grassland one; `dominant` is computed,
stored, passed and never read; nine of eleven terrain effects are never placed;
and HILLS and MOUNTAINS produce rocks rather than height, despite height having
complete cover, accuracy, range and damage rules already.

The proposal, in short: give battle tiles a **ground type** from the same
fourteen names, generate the field as a 5×5 arrangement of ~9×6 blocks so
arrangement survives, move the mapping into data so the validator can see it,
and build **zones as auras with a place instead of a body** — `AuraSystem`'s
payload vocabulary already answers "what does an area do to whoever is in it",
and five inert spells want exactly that anchored to tiles.

**What points at it.** Five spells are inert for want of it — `false_terrain`,
`grave_soil`, `rain_of_mud`, `vajra_gate` and `shroud_of_darkness` — and three
more are partly so. `clear_air` exists to remove "cloud effects" that are not
statuses and not terrain features either. `tornado` keeps `persistent_effect`
and `moves_randomly`, a hazard that relocates itself each round.
`vajra_mandala` is a ground-anchored zone that protects allies inside it and
hurts enemies entering — an aura bound to a place rather than a unit.

**The questions the audit should answer.**

- Is a *zone* a unit, a tile property, or a third thing? An aura is attached to
  a body and moves with it; a mandala sits on the ground and does not. The aura
  system could carry zones if an invisible anchor unit is acceptable, and that
  may be the cheapest honest answer.
- Do zones tick, move, expire, stack, and what happens where two overlap?
- What is a "cloud"? Several spells create them and one removes them, and the
  category exists in no file.
- How does terrain relate to the existing `terrain` status category and to the
  overworld terrain the battlefield is generated from?
- Entering and leaving: a zone that damages "enemies entering" needs a movement
  hook, which `unit_moved` already provides.

**Existing pieces to build on:** `AuraSystem` (proximity fields, already has
enter/leave semantics by recomputation), `unit_moved`, the `terrain` status
category, `combat_grid` tile state, and `AoEResolver` for shapes.

## 5. Resistances — audited and rebuilt

**Done 2026-09-16.** The audit is `docs/plans/RESISTANCE_AUDIT.md`; what it
found and what was built:

**Resistance was applied by the CALLER, and 9 of 61 call sites did it.**
`apply_damage()` never consulted it — every caller was expected to have
written `damage * (1.0 - r / 100.0)` itself. So weapons and spells were fine
and nothing else was: damage-over-time ticks, terrain hazards, aura payloads,
zone payloads, retaliation, splash, cleave, oil coatings and every perk burst
ignored resistance and immunity. A Solar Form character, immune to fire, took
full damage standing in a fire tile. It is resolved once now, inside
apply_damage, and the twelve hand-written sites are gone.

**The list, after review:** physical (slashing, crushing, piercing), fire,
ice, lightning, space, white, black, and poison. `water`, `air` and `earth`
were damage types and are magic SCHOOLS only — all eight spells dealing `air`
were lightning, no spell dealt `earth` at all, and `water` was impact, ice and
drowning under one name. Their damage arrives as lightning, crushing or ice
now, per spell. A compound type (`solar`, `fire_black`, `physical_fire`,
`white_fire`, `prismatic`) arrives as whichever component the target resists
LESS, so it cannot be walled off by resisting one half and picking one is a
decision about the target.

**Three vocabularies that disagreed** are one: `DamageType` +
`resources/data/damage_types.json`. `MAGIC_DAMAGE_TYPES` had listed holy,
shadow and arcane — dealt by nothing — and omitted black and white, so
equanimity did nothing against the two schools most obviously made of magic.
Five spells dealt `ice` while all fourteen resistance entries said `cold`.
Compound types (`solar`, `fire_black`, `physical_fire`, `white_fire`,
`prismatic`) are dealt as their components in equal shares, so each half meets
its own resistance; `random_elemental` rolls per hit.

**One order, stated on `apply_damage`:** resistance → defender-side
multipliers → armour (physical only now) and equanimity (magic only) → aura
and zone `damage_taken_pct` → shields and floors. Attacker-side multipliers
stay where the damage is computed, which is the rule that explains why
Permafrost lands before resistance and Marked_for_Death after.

**Absorption exists**, Final Fantasy style: resistance above 100 heals for the
excess. Contributions sum and the sum clamps to [-100, +90], so only a single
declaration may cross 100 — you cannot buff your way into drinking fireballs.

**Also found:** every DoT dealt physical damage (the tick read an `element`
field no status declares, and the element was in the effect string all along);
seven spellings of "+N% physical resistance"; and `bleed` resistance written
into `derived.resistances` by PerkSystem and read by nothing, which was Stone
Body's entire description. Afflictions — bleed, poison, disease — are declared
by the status now and resisted as a chance not to catch them.

**Poison, audited and filled out 2026-09-16.** The spell ladder was already
complete — Poison Sting (1), Festering Wound and Poison Skin (3), Venomous
Tide and Poisonous Cloud (5), Miasma (7), Deathfog and Plague Waters (9), plus
the Earth/Black plant line — so the work went where the gaps were:

- **Four things that described themselves and did nothing.** `immune_system`
  is an aura now, which needed a `resistance` payload kind auras and zones did
  not have; `applied_toxicology` has a camp activity to craft the coatings it
  promised, gated by a new `perk_req` on camp activities; `poisoner` doubles
  them; and Diseased spreads — it declared `spreads_on_contact`, which nothing
  reads, while the spread mechanism that has worked for months wanted a
  `spread` block. Two ways to say one thing, and the status picked the one
  with no reader. Spread also now honours the `range` every spreading status
  declared and none of them got.
- **`poison_damage_pct` on the Alchemy table**, on the same curve Fire Magic
  uses for burning, read off whoever applied the venom — so an alchemist's
  poison bites harder than a novice's, which fire has enjoyed for months.
  Weapon procs and oils now record their source, so the scaling reaches them.
- **Equipment:** `antivenom_lined` armour (poison had no ward while fire, ice,
  lightning and space all did), `envenomed` weapons at twice `venomous`'s
  chance, and a Serpent Ward talisman stat. Venom arrows already existed.
- **Two spells:** Draw Out the Venom (Water/White 3) moves every affliction
  from an ally to the nearest enemy — a cure that costs somebody else, and the
  first user of the new `nearest_enemy` role — and Coil of the Naga
  (Water/Black 7), a save-gated Festering, nagas being what Tibetan medicine
  blames illness on.
- **Poisonous Cloud and Miasma leave a cloud.** Both carried an unread
  `cloud_effect: true` and dispersed the moment they landed.

**Still open, small:**

- [x] ~~The twenty legacy effect strings live in `Resistance.LEGACY_EFFECTS`~~
  — **migrated 2026-10-15.** All 27 statuses that carried one say it in
  `grants_resistance` / `grants_vulnerability` now, and the table is gone.
  Two things the table did that a plain type key could not: `physical`
  covering its three subtypes, and the two scopes (`all` for Invulnerable,
  `non_physical` for Mantric Armor, Praying and Rainbow Cloak). Both live in
  `DamageType.scope_covers()`, and the scopes are a list on DamageType the
  validator reads, so they are allowed on a status and nowhere else. The two
  statuses that kept their number in a side field (`vulnerability_pct`,
  `resistance_pct`) just write it in the block. Checked the honest way: every
  status against every damage type, before and after — 136 non-zero
  figures, identical. The status tooltip lost three hand-written labels and
  gained a line per resistance key, so Inner Flame shows what it does for the
  first time.
- [x] ~~`ranged` resistance (Silk armour, +10) is not read~~ — **wired
  2026-10-15.** It was worse than unread: nothing copied a material's
  `resistances` onto anything, so the +10 never reached a character either.
  `ItemSystem._add_item_stats` reads the worn item's material row now, and the
  attack path reads `Resistance.delivery(defender, "ranged")` beside
  Air_Shield, ranged weapons only. It shows in the examine panel as its own
  row. verify_resistance checks the robe, the arrow and that a sword ignores it.
- Nothing absorbs anything yet. The mechanic is built and checked; a fire
  elemental that drinks fire, or an undead thing that feeds on Black magic, is
  content waiting to be written.

## 6. Data with no consumer — nearly cleared

- [x] ~~**27 of the 40 `base_bonuses` stat keys are read by nothing**~~ — it was
  **4 of 39** by the time anyone looked again (2026-09-16); the September
  wiring phases had cleared the rest and this entry was never updated. Three of
  the four are wired now, and each turned out to have a consumer waiting rather
  than needing one invented:

  - **`crafting_yield_pct`** (Alchemy) → Brew Coatings, the one camp activity
    Alchemy owns, which arrived with the poison pass a day earlier. Whole
    hundreds are extra doses; the remainder is a chance at one.
  - **`loot_quality_pct`** (Thievery) → the loot drop fraction, which was
    `best_thievery * 0.03` capped at 0.30: a magic number that meant what the
    table says and disagreed with it. Read now as a percentage of the HEADROOM
    between the roll and the maximum, so the bound holds by construction.
  - **`trap_detection_pct`** (Thievery) → a chance to step around a trap,
    which became possible the moment Trap Maker existed. Their own skill, not
    the party's best: spotting a snare is something you do with your own eyes.

  **`crafting_quality_pct`** (Smithing) is the one left, and for the reason
  already recorded: camp crafting pulls rope, torch, bandage and arrowhead
  from a fixed table with no quality concept. Building one is a feature, not a
  wiring job — and quality means little for a torch.

  **The renaming note is still worth keeping.** `_pct` is a percentage,
  `party_` means one member's skill pays the whole party, a bare name is flat;
  the convention lives in `perks.json`'s `base_bonuses._comment` and
  validate_data.py enforces it. And the dead keys were never the simple
  renames they looked like: `movement_speed` was a percentage where
  `derived.movement` is in tiles, so mapping one onto the other would have
  granted 65 tiles of movement.

- [x] **Party-wide bonuses** — built 2026-09-12 as `PartyBonuses`, best member,
      with `update_party_derived_stats()` firing on skill change and party
      add/remove. Six keys wired and rescaled (see `base_bonuses._comment` for
      the rule). Design notes kept below for the next phase:

- [x] **Phase 2 — economy and crafting** — done 2026-09-12. Turned out to be
      mostly *convergence*: Trade discounts and the Alchemy potion bonus already
      existed as hand-rolled code that disagreed with the tables. Five keys
      wired, two left with reasons:
      - `crafting_quality_pct` has **no mechanic to attach to** — camp crafting
        pulls from a fixed `CRAFT_TABLE` with no quality concept. Building one
        is a feature, not a wiring job.
      - `crafting_yield_pct` is owned by **Alchemy** while camp crafting reads
        **Smithing**. Needs a decision about which skill crafts what before it
        can mean anything.
- [x] **Phase 3 — logistics and learning** — done 2026-09-12. Four wired:
      `party_skill_check_bonus` (event rolls), `party_supply_duration_pct`
      (supply draws), `party_xp_gain_pct` (XP award), `party_travel_speed_pct`
      (overworld movement). The other five are each blocked on something real:
      - **`morale_pct`** — removed 2026-09-12. It was a relic of an idea that
        became PsychologySystem. The live question it leaves behind is in
        "Things to ponder": Leadership ought to touch companion psychology.
      - **`charm_effectiveness_pct`, `social_roll_pct`** — done 2026-09-12.
        They turned out to be one stat with two sources, now
        `party_social_roll_pct`. Event rolls did not need tagging after all:
        each already names a skill or an attribute, so the category derives
        from it, with an optional `category` on the roll for the cases where
        the stat does not tell the story.
      - **`loot_quality_pct`**: no loot rarity mechanic to attach to.
      - **`max_companions`** — done 2026-09-12 as `party_max_companions`. Two
        companions come free; Leadership adds one at 3, 6 and 9, topping out at
        a party of six.
- [x] ~~**Needs a proc site, not a consumer** (4 keys)~~ — **stale; wired
      2026-09-12 in `f4f54e6`, finished 2026-10-15.** This line outlived the
      commit that answered it by a month, and the baseline had already
      dropped all four. Looking again turned up two halves that were wired
      in name only:
      - `burning_damage_pct` (Fire Magic) and `stun_chance_pct` (Maces) were
        done properly — the DoT tick reads the burn off whoever set the fire,
        and Alchemy's `poison_damage_pct` sits beside it on the same pattern,
        so there was nothing to converge.
      - **`status_effect_chance_pct` (Ritual) had one reader: oils.** Spells,
        bombs and weapon procs — where statuses mostly come from — rolled
        their chance raw. All four go through `effective_status_chance()`
        now, which works in floats so a 7.5% proc is not rounded before
        Ritual touches it. Statuses that land on a **failed save** have no
        percentage to multiply, so Ritual goes on the DC at SaveSystem's own
        rate, five points per d20 point (`status_save_dc_bonus()`): Ritual 10
        is +6 to the DC, the same coin Yoga's mental resistance pays out in.
        Every `_skill_save` caller gates a status or a debuff so all of them
        take it; a spell save takes it only when its failed branch lands a
        status (`_save_gates_status`) — a ritualist is no better at Deathfog's
        instant kill than anyone else.
      - **`luck_pct` (Comedy) fed `loot_chance_pct`, which nothing read** —
        and neither did the Shivering Cairn shrine's +15%, whose whole effect
        that was. It multiplies the Luck jackpot now
        (`luck_jackpot_chance()`), after the Luck cap so the luckiest party
        still gains, best member not sum. The crit half stays flat points:
        Luck's own crit term is Luck/6, a percentage of which rounds to
        nothing, and the map "luck" buff already pays one crit per point.
      verify_combat_procs is seven checks, and fails when either half is
      unwired.
- [x] **Enchantment's status duration is stated once** (re-checked
      2026-10-15; this entry used to call it `effect_duration_pct`). The
      per-level table key is `effect_duration_turns` — 0,1,1,2,2,3,3,4,4,5 at
      Enchantment 1–10, i.e. +1 turn per 2 levels — and
      `_calculate_status_duration` reads only that (`derived.
      effect_duration_turns`); the old `int(level / 2)` formula in the
      function is gone. Not a double count: a spellpower-duration status lasts
      2 + table + SP/15 turns, so Enchantment 10 at SP 0 gives 7.
      `verify_combat_procs` pins the 1–10 curve and fails if the formula comes
      back beside the table. Lingering Touch and Weakening Gaze add their own
      +level/3 on top, but those are perks, chosen, not the skill paying twice.
- [ ] **Original design notes:** They behave
      like equipment bonuses — another additive source folded into `derived` —
      except the source is a different character's skill. No ordering problem
      arises because they derive from **raw skill levels**, never from another
      character's `derived`, so nothing waits on anything.

      **Best member, not sum** (decided 2026-09-12). Four medics should not be
      four times one medic. Taking the best also matches the rule the game
      already uses everywhere — "any party member meeting a requirement enables
      the choice" — and makes the specialist *the* specialist. It has a known
      cost, recorded under "Things to ponder" below.

      **A refresh hook is mandatory** — this is a build requirement, not a
      design question. Party-wide bonuses mean one member's skill feeds every
      other member's `derived`, so `update_derived_stats` has to run for the
      **whole party** whenever skills or party membership change, not just for
      the character who changed. Miss it and stats go quietly stale, which is
      the hardest class of bug to notice in this codebase.

      Combat-facing `party_` keys land in `derived`; the rest
      (`party_xp_gain_pct`, `party_travel_speed_pct`,
      `party_supply_duration_pct`, `party_skill_check_bonus`) are read by
      CompanionSystem, MapManager, CampSystem and EventManager.

- [x] **This whole bug class is now caught automatically.** `validate_data.py`
  gained a data→code check: five vocabularies (base_bonuses stats, status
  behaviour strings, AoE shapes, active skill effects, passive effect types) are
  checked for values that no code reads. Known gaps live in
  `tools/vocabulary_baseline.json` with a reason attached, so the check fails
  only on new drift. Shrink the baseline by wiring a consumer.
- [x] ~~**6 embedded `todo` keys**~~ — three kept, three left with reasons
  (2026-09-16). Nothing in TODO.md had ever tracked them.

  Kept: **Aquatic** and **Flying** grant party-wide traversal when EVERY
  member has the trait — a rule that cannot be per-member, because the party
  moves as one body on the overworld, so `MapManager.TRAIT_TRAVERSAL` asks the
  party rather than the character. **Insatiable** eats half again as much and
  takes half the good out of a night's sleep; the trait declares
  `food_multiplier` and `rest_recovery_multiplier` and TraitSystem reads both,
  so the party's food bill is counted in mouths rather than heads.
  **Smoked Glass Lenses** stop the Blinded they name, through a general
  `passive.status_immunity` list — the ITEM names the status rather than the
  code naming the item. And Dré's empty `todo: []` is gone.

  Left, each blocked on something real:
  - **Night Vision's darkness immunity** — there is no darkness system to be
    immune to. Wiring it would be data with no consumer in the other
    direction.
  - **Shambler** is −7 net attributes with no compensating passive. That is a
    design decision, not a wiring job.
  - **Jaina** wants karma wiring: slower animal-realm karma, drift toward
    human and god through non-violent play. KarmaSystem has no per-race
    modifier, so this is a small feature rather than a read.

- [x] ~~**`skeleton_king_duel`** stops at 10% HP~~ — **checked 2026-10-15, and
      it was half-broken.** The threshold survives the build (the archetype
      carries it, and `difficulty: boss` scales only the XP the king is built
      from — never HP after the build — so 10% is of the HP the unit really
      has). But `_check_combat_end` only ran on a death or at
      the start of a round, so the king fought on below 10% — took his own
      turn, and could simply be killed. Damage to a duelling enemy now checks
      at once, and he yields on the blow that crosses the line.
      `verify_combat_systems` builds him the way the event does and proves it.

## 7. Content that wants writing

- [ ] **A prose pass on 81 events and 24 companion bios.** The animal realm's 47
  zone events, hungry ghost's 34 gap-fill events, the three HG boss/pass-guardian
  events, and all 24 animal companion bios are Claude's prose, not yours. This is
  the single biggest content item and only you can do it.
- [ ] **53 events are grey-only** (of 347 with choices) — no blue or yellow
  option at all. The stated target is ≥2 meaningful checks per event. The trait
  sweep reduced this from 63 by giving some of them their first gated choice.
- [ ] **500 of 605 perks have empty `flavor`** (counted 2026-10-16). Better in your voice than mine.
- [ ] **Quests: 3 total, all hell.** The board works and the validator now
  guarantees every step flag is settable, but hungry ghost and animal have none.
- [ ] **Hell event chains still unwritten** from the original list: soul caravan
  ambush, devil deserter, contraband deal, corrupted simple, chained pilgrim,
  rival party.
- [ ] **Realm-specific wounds** — 10 base types exist (6 wounds, 4 diseases)
  plus 7 escalated forms (`wound_system.gd`, counted 2026-10-16). Arrow
  (`barbed_wound`), poison (`poisoned_blood`), spiritual corruption and burns
  are built. Still wanted: HG malnutrition, animal parasites, hell frostbite.
  Design notes and the open wiring items: the `CONTENT.md` Inbox, under
  "Wounds — design notes (recovered)".
- [ ] **Consumables and equipment are thin** in realm-specific flavour — 68
  legendary-rarity items exist, so the tier itself is covered.
- [ ] **Astrological spells (Space)** — divination, eclipse/conjunction
  triggers; motivates the Sun Priestess companion's Space skills.
- [ ] **Paushtikakarma spells (Earth)** — wealth multiplication, dowsing for
  ore; gives teeth to trade/merchant builds (Hustle Bones, Trade+Earth).
- [ ] **Ritual implement special traits** — conch pacification aura, bone
  life-drain proc, sky-iron void field. Design deferred.
- [ ] **Realm-specific rest events** — "something stirs in the night" flavour
  when resting in hell / hungry ghost.

## 8. Whole realms

Human, asura and god need: map config, archetypes, encounters, event file,
companions, backgrounds, shops. Human-realm zone design is sketched in Part II.

## 9. Balance passes waiting on play

- [ ] **Saving throws, after the 2026-09-12 rework.** Every CC effect in combat
      changed probability. A Constitution-12 target used to resist *everything*
      at a flat 44%; now it is 55% against an equal attacker, 15% against a
      Focus-20 caster, and 85% if it is Constitution-18. That spread is the
      point — but the tiers (easy -4, normal 0, hard +4, brutal +8) and which
      effect sits in which tier are first guesses. Nothing has been played.
      Watch for: hard CC landing too reliably on low-Constitution characters,
      and high-attribute characters becoming immune to anything at `easy`.


All first-pass numbers. Nothing here is a bug; they need a playthrough.

**Combat**
- Summoning terrain affinity: flat +25% and the terrain→element table
- `pack_bonus`: +3 accuracy/dodge per packmate, cap +12
- `priority_target` isolation weights; whether `burrow_emerge` should cost an action
- `Mantric_Armor` shield pool (25), `Mirror_Images` copies (3)
- Reflect 60% / `Magic_Mirror` 50% reflect chances
- Multi-arm damage scalars and per-extra-arm accuracy penalty
- Difficulty multipliers (easy 0.75 … boss 1.6) — now applied to every event fight
- Spell mana costs (15/40/75/135/225 by level)

**Wounds** (`WOUND_PENALTIES` in `body_system.gd`)
- Are percentage penalties proportionate across stat ranges? Finesse 8 vs 16
  experiences an arm wound very differently
- Severe head (−30% spellpower, −25% initiative, −15% max HP) vs severe torso
  (−35% max HP, −25% stamina) — is head too punishing?
- Feet may be too mild relative to legs; consider a persistent `prone`
- Diseases share the physical wound table via `body_location` — should
  `rot_sickness` at torso hit max mana or spellpower instead of HP?
- `rests_untreated` escalation thresholds (2–3 rests) — too fast given rests
  already cost resources?
- Naga (serpentine, no legs) needs its own pass — it cannot take leg/foot wounds

**Camp & economy**
- Forage yield relative to rest costs, per realm
- Brew Potions count (1–3) vs 2 reagents — compare to shop prices
- Pressure decay: Full Rest + Sadhana totals 250 (100 + 150). Should sadhana
  replace rest decay rather than stack?
- Activity slots (Camp 1, Full 2) — implement a Logistics +1 slot perk?
- Enhanced camp activity multiplier (1.5×) and Set Snares yields
- Wound healing price: (20 + 15 × cure_medicine_level) × shop modifier
- **Gold reward tokens: small 40 / moderate 100 / large 180** — derived from the
  60 numeric rewards already in the event files (median 100, terciles 80/130)
- Trade L10 reads 60% buy discount / 70% sell markup — probably intended as a
  soft cap, not a literal multiplier. Decide before wiring (Part III)

## 10. Perks deferred on missing systems

Not gaps in the perk trees — these are written and waiting on machinery.

**Need new mechanics:** `metamagic` (pre-cast modal), `void_touched` (void tile
type), `roles_assigned` / `tactical_synergy` (role designation UI),
create_terrain perks (`inscribed_circle`, `fog_of_war`, `black_ice`,
`raise_wall`, `gravity_well`, `improvised_barricade`, `prepared_ground` — need
timed terrain tiles), `create_images` / `smoke_and_mirrors` (illusion units),
`imbued_attack` / `arcane_archer` (attack+spell hybrid), `mass_teleport`,
`recruit_or_pacify`, `place_trap` / `trap_maker`, `steal_item` /
`the_invisible_hand`, `guard_ally` / `stalwart_guardian`, `choose_one` /
`improvised_masterpiece`, `attune_charm`, `trap_sense`.

**Need economy/social systems:** `trade_empire` (passive income; `investment` built 2026-10-15),
`supply_cache` / `extended_march` (supply action), `guided_practice` /
`the_lineage_continues` (companion spell-teaching), `black_market_contacts` /
`fence` (black-market tier), `patron_of_the_arts` (renown).

**Wound/body perks: all four built (2026-10-15).** They turned out to be
half-written rather than unwritten — each was in perks.json and had a
`has_perk` branch somewhere — and every one was broken in a different way:

- **`hardened`** (Armor 5, Con 14) negated crit wounds from the main attack
  only. The multi-arm chain rolls its own crit wounds and never asked, so a
  four-armed demon's arms 2–4 wounded a Hardened character at full rate. Both
  paths now go through `_crit_wound_negated()`.
- **`stubborn_body`** (Armor 8, Con 15, Hardened) worked in `tick_wounds` but
  the party screen's "worsens in N rests" read `escalation_rests` raw and
  counted down one rest short. Both now ask `WoundSystem.get_escalation_threshold()`,
  which adds `character.wound_escalation_delay` (any future source) plus 1 for
  the perk, and leaves never-escalating wounds at never.
- **`undead_hunter`** (Earth Magic 3) was immune to the Diseased status from
  *anything* — a living plague-caster included — while the arm chain's disease
  proc skipped the immunity check entirely. Now it is exactly "from undead or
  diseased attackers", on both paths; `_check_perk_status_immunity` takes the
  source to know.
- **`iron_cortex`** was keyed to a `finesse` *skill*, which does not exist, so
  nobody could learn it — the same fault akimbo/coordinated_strikes had.
  Now `required_attributes: {finesse: 12}`, and **its Akimbo prerequisite was
  dropped**: with Akimbo (Finesse 14) arm 2 already fires 90%+ and 100% by
  Finesse 16, so behind Akimbo the perk bought almost nothing. As an early
  alternative it takes arm 2 from 60% to certain. Revisit if that reads wrong.
  The chance itself lives in `CombatManager.arm_chain_fire_chance()`.

`hardened` and `stubborn_body` also moved from `special_requirement:
"constitution_14"` to `required_attributes`, which counts trait bonuses the
way akimbo's gate does; the special-requirement form read base attributes only.
Checked in `verify_combat_procs`.

### Active perks without a resolver: none (was 26 — 2026-09-16/17)

75 of 109 were wired in b746bc1. The rest followed in four batches: the six
reaction stances, the nine terrain placers, five singles (Field Medic, Trap
Maker, Everyone Is Somewhere Else Now, Stalwart Guardian, Too Fast to React),
and the last six — Arcane Archer, Attune Charm, Improvised Masterpiece,
Magnetism, Smoke and Mirrors, The Invisible Hand.
`tools/verify_active_perks.tscn` reprints the list on every run, so a new perk
without a resolver cannot land quietly.

**`choose_one` is the piece that unblocked the two that needed a player
choice.** A skill declares `options`, each naming an effect and its own data;
the caller passes `chosen_option` and the chosen one is dispatched through the
same table every other skill uses. Absent a choice it takes `default_option`,
so a skill works before its picker UI exists rather than being wired to its
first branch as a stopgap. `disrupting_palm` can be moved onto it whenever
somebody wants to.

**Two things the last batch found**, both of the same shape as everything else
this week: `_resolve_debuff_enemies_aoe` applied statuses but not stat
penalties, while its buff twin always did both — so "-10% to everything
nearby" had nothing to say it with. And `_resolve_buff_allies_all` buffed the
whole team whatever radius the skill named, so Improvised Masterpiece's
"within 3 tiles" was decoration and a bard three rooms away was inspiring.

### The overworld perks: six built, one waiting on economy (2026-09-17, investment 2026-10-15)

Flagged `non_combat` in b746bc1 so they stopped rendering as dead buttons in
the combat panel — which did not implement them. Five are camp activities now,
because that is where a party stops and does something and the activity system
already gates on a perk (`perk_req`, added 2026-09-16):

- **`forage`** — the camp action existed and gave herbs and food wherever you
  stood; a mountainside yielded the same as a forest, while the perk promised
  "food in forests, herbs in meadows, minerals in mountains". The yields are
  in terrain.json now, beside everything else a ground decides, read through
  `Ground.forage_of()`. Training finds half again as much — and finds
  something on ground that yields nothing, which is what knowing how to look
  is worth.
- **`scout_ahead`** — twice the reach of the ordinary watch, further with
  Logistics.
- **`guided_practice`** — teaches the most advanced spell in the teacher's book
  that somebody else can actually work, using the same school-and-level rule
  casting uses, so what is taught is castable tomorrow.
- **`reinforce`** — +10% to an equipped item's largest stat, permanently. The
  piece becomes an INSTANCE of itself first (`ItemSystem.swap_equipped`), or
  improving one sword would improve every sword of that make in the world.
- **`inspiring_sermon`** — +5% damage until the next fight through
  `active_map_buffs`, and a skill-check bonus spent by the next roll rather
  than expiring on a clock. Twice between rests, as the perk says; the count
  resets when the party rests.

**The two left were economy, and each wanted a system rather than a wiring.**
Investment is built (2026-10-15); supply_and_demand still waits.

- [x] **`investment`** (Trade 4) — "Invest gold in a settlement. Returns 150%
      of the invested amount after several in-game days." Needs a store of
      outstanding investments (settlement, amount, due day) and a day-boundary
      hook to mature them. TimeSystem already advances days and the lunar
      calendar already listens to it, so the hook exists.

      *Updated 2026-09-20 — this is now the cheapest of the economy items.*
      **Settlements are entities**, with ids, names, tiers and positions, so
      there is something to invest *in*; `GameState.shop_purses` is the
      pattern to copy for `GameState.investments`, down to being keyed by map
      object and reset by `reset_for_new_life`.

      And the abandoned-realm question is answered, though not the way the
      economy memo assumed. Portals are two-way, so an investment left in a
      realm you have travelled out of matures and is collectable — but
      **death regenerates the world**, so anything outstanding when you die
      dies with you. That is a feature rather than a loss: an investment is a
      bet that you will live long enough to collect, which is the most
      Buddhist thing in the economy.

      **[x] Built 2026-10-15.** `GameState.investments` is the ledger, copied
      from `shop_purses` exactly as planned: keyed by the shop's map object
      (one shop per settlement, so one key per place), cleared by
      `reset_for_new_life`, carried through the save. The rules sit beside
      the purse in ShopSystem. A party member with the perk gets an Invest
      bar in a settlement's shop — a SpinBox in steps of 50, never more than
      you carry — and the stake comes back at 150% after
      `INVESTMENT_DAYS = 7`, a first-pass number chosen to match the rack's
      week. Walking back into that shop is collecting, and collecting needs
      no perk: if the merchant died the money is still owed. The day tick
      writes one line to the overworld log when it matures, and pays nothing
      — you have to go back.

      **One outstanding investment in the whole world, not one per
      settlement.** `diversified_portfolio` (Trade, after this) promises "up
      to 3 investments simultaneously", which only means something if the
      base perk allows fewer; `INVESTMENT_MAX_OUTSTANDING` is the number it
      will raise, along with the return to 200%. Three checks in
      `verify_economy_bonuses`: mature-and-collect, death, save.
- [ ] **`supply_and_demand`** (Trade 5) — "Check available trade goods between
      known settlements. Buying low and selling high grants triple the normal
      gold difference." Needs a trade-goods model: per-settlement prices that
      differ, and a notion of carrying goods between them. ShopSystem has 91
      shops with modifiers but no goods that have a price *somewhere else*.
      This is the biggest of the seven by a distance and is really a feature —
      a caravan game inside the travel game. Worth doing only if travel is
      meant to carry that weight; otherwise the perk should be rewritten to
      something Trade can already do.

      *Updated 2026-09-20.* Still blocked, but on less: settlements exist,
      shops have purses that differ by place, and `docs/plans/ECONOMY_FLOWS.md`
      settles what the perk should do. Olaf's ruling is that the spread stays
      **invisible** by default — no cheap/dear marker, the player notices or
      does not — which makes this perk better rather than worse, because being
      *told* the spread is worth a great deal when the baseline is unaided.
      What is still missing is the one thing it is named for: goods with a
      price somewhere else. That is trade_goods.json and the regional price
      index, layers 2 and 3 of the economy design.

## 11. Things to ponder

### Should spells crit? (2026-10-16)

Today no spell can crit: there is no crit roll on spell damage at all, so the
crit marker never shows on one. Weapon and combat-skill hits crit. Open
questions if they should: which stat drives it (Awareness/Luck like weapons,
or Focus), whether Ritual or the school skill adds to it, and whether a spell
crit doubles damage or extends/strengthens the status instead.


### External events — the world moving without you

*2026-09-20, out of the economy design.* The trade design wants "shocks": a
caravan arrives and grain is cheap for a week, a mine floods and ore doubles,
a siege closes a road. The interesting realisation is that shocks are not an
economy feature — they are the economy's instance of something the game does
not have at all: **things that happen in the world without the player
touching them.**

Worth having as a system rather than as a price mechanic, because the same
hook serves far more than trade:

- **Economic** — a market glut or shortage, a trade route closing, a
  settlement's prosperity rising or falling.
- **Territorial** — a mob group takes a road, a shrine is desecrated, a
  region becomes more dangerous while you were elsewhere.
- **Social** — a faction's attitude shifts, a trainer dies, a settlement you
  invested in is sacked.
- **Karmic** — the realm reacting to what you have been doing, which is the
  one that could not come from anywhere else.

What makes it a *system* rather than a list is that it fires on the day tick,
picks from a weighted table filtered by what exists in the world right now,
and leaves a **trace the player can find** — a rumour from a traveller, a
changed price, a road that is not where it was. A shock nobody can perceive
is a random number generator with extra steps.

Open questions worth sitting with before building:

- **How does the player learn?** Travellers are the obvious channel (the
  design already makes them the rumour layer), but a shock in a realm you have
  left needs a different one, or it should simply not fire there.
- **Does it fire while you are in combat or in a menu?** Day-tick timing means
  it can land at an odd moment.
- **Can the player cause one?** Robbing a caravan should move the ore town's
  prices — which makes this the other half of the reputation idea rather than
  a separate feature.
- **Frequency.** Rare enough to be an event, common enough that a long run
  sees several. Once every few in-game weeks is a guess.

Design first, and after the trade layer exists — a shock needs something to
shock. Noted here so it does not get built as a price-only mechanic and then
need rewriting when territory and factions want the same hook.

### Marking the ground a battle was fought on

Cheap, and it has more in it than it looks. When combat ends, flag the
overworld tile: *a fight happened here.* Nothing else.

What it unlocks, none of which is built:

- **Speaking with the dead.** The Black magic perk deferred on 2026-09-15
  needs somewhere the dead are, and a battlefield is the obvious one. A party
  with the training learns what happened here; a party without it walks past a
  field of bones.
- **Grave soil, without the spell.** `grave_soil` makes ground where the dying
  rise again. Old battlefields being *naturally* a little like that — a higher
  chance of undead encounters, a Black magic bonus, a Summoning affinity that
  is not the terrain's own — costs nothing once the flag exists.
- **A run that leaves marks.** The party walks back through a realm (portals
  are two-way now) and the map remembers where it bled. That is atmosphere
  for almost no data: one boolean per tile, and maps already persist.

Deliberately NOT built yet. A flag nothing reads is the bug this project keeps
digging out, and every use above is content that does not exist. Build it with
the first thing that wants it — most likely the perk.

Decided against alongside it: **terrain that combat destroys** — burn a forest
and the tile becomes plains, so fire is a travel strategy. It sounds better
than it plays. The party rarely walks back across a tile it fought on, so the
payoff almost never lands, and it needs a rule for what every damage type does
to every terrain.


### Mob behaviour as a system

Raised 2026-09-15 and recorded here 2026-09-16, when it turned out never to
have been written down.

The AI decides what a unit does by reading the situation each turn. What it
does NOT read is most of what has been built since: it does not know auras
exist, so it will not step into a friendly one, out of a hostile one, or focus
the unit projecting it; it does not know zones exist, so it will walk through a
tornado; it does not use the terrain it is standing on, the height it could
hold, or the repositioning it could inflict. Every one of those is a
player-side advantage by default, which is the wrong shape for a tactical game.

The idea is a **set of behaviour rules a mob carries**, the way it carries
resistances — so a wolf pack, a temple guard and a hungry ghost want different
things out of the same turn, and an archetype says which it is rather than the
AI inferring it. Enemy-summoned creatures inherit the summoner's rules;
player-summoned ones stay party-controlled, which is already true.

What points at it:

- Nothing steps into or out of an aura or a zone (`aura_system.gd`,
  `zone.gd` — both note the gap in §3).
- Coordinated group AI — focus fire, flanking — is listed in §12 as a larger
  feature and is really the same feature.
- `behind_you`'s `assassin_setup` wants a flanking rule that does not exist.
- Four behaviour types exist already (`erratic_movement`, `priority_target`,
  and two more wired in 2026-09), which is the seed of a vocabulary rather
  than a system.

Not small. Worth doing after a playthrough, because the right rules are the
ones the fights actually want.

### Resurrection in events — what should it cost?

The mechanism is built: `CharacterSystem.fallen` records everyone the run has
lost, and an event grants a return with
`"rewards": {"resurrect": {"target": "last"}}`. What is not decided is what it
should mean.

- **Price.** Gold is the dull answer. Karma is the interesting one — pulling
  someone back out of the bardo is an intervention in exactly the process this
  game is about, and it should probably cost something in the realm the run is
  heading toward. An XP price on the whole party is another option: everyone
  gives up some of their progress to bring one person back.
- **Who chooses.** Right now `"last"` is the only target that resolves, so the
  game picks. Letting the player choose needs UI and makes the decision real:
  a party that has lost three people has to say which one matters.
- **What comes back.** The same person, or someone changed? A `death_touched`
  trait already exists for characters who should have died and did not, and it
  is currently granted only by the survive-a-fatal-blow paths.
- **Whether it should be common.** Four spells and an event hook is already a
  lot of resurrection for a game whose subject is impermanence. It may be that
  raising the dead should be rare, expensive and slightly wrong, rather than a
  service the party buys.


- [ ] **Party size may still be undercosted, and Leadership may still want
      nerfing.** The curve is uncapped now, but `party_max_companions` carries `limit: 7`
      and `get_max_party_size` clamps to `CombatGrid.PLAYER_DEPLOY_SLOTS` (8, the
      arena's start tiles): at most 8 in the party. Before stage 2a it was 3
      free, 6 at Leadership 9. The reason it is that low:
      party size is arguably the strongest stat in the game. The party-check
      rule opens a choice when *any* member qualifies, and every `PartyBonuses`
      payout resolves to the best member — so each extra character is another
      roll of the dice on having every specialist at once, across 35 skills.
      XP dilution is the existing counterweight, but it costs *combat* power
      while the benefit lands on *non-combat* checks, of which there are far
      more. Rejected as a Leadership payout for the same reason: making
      Leadership reduce XP dilution would remove the only cost wide parties
      pay. Leadership keeps its active perks and, eventually, the companion
      psychology wiring below. Revisit after a playthrough.

Live design questions. Not bugs, not deferred decisions — the shape of these is
still genuinely open, and each was raised because something built today works
but may not be what the game wants.

- [ ] **Best-member party bonuses make the second specialist worthless.** With
      best-member, a party's second-best Medicine contributes exactly nothing,
      so levelling it is wasted XP and the player learns to stop. Summing has
      the opposite problem (four medics become four times a medic, which is
      absurd and off-theme), so neither pure rule is right. Worth considering:
      diminishing contribution from lower-ranked members, or a small flat
      assist per additional member above a threshold.

- [ ] **Party-wide bonuses invite min-maxing once the player knows the game.**
      If one character's skill pays the whole party, the optimal build is one
      specialist per useful skill and nobody redundant. That is a legible
      strategy, which is good, but it flattens party composition into a
      checklist. The whole party-bonus logic may want rethinking rather than
      tuning — the current pass standardizes it so it is legible enough to
      reason about, not because the rule is settled.

- [ ] **Equipment, crafting and loot want one audit together.** Olaf's
      direction, 2026-09-12, recorded before it evaporates:

      - **All non-consumable items should have quality.** Weapons and armour
        already do: material and quality set the stat ranges, traits modify
        from there. Everything else that is not a consumable should work the
        same way. Crafting is messy in general and this is the spine of tidying
        it.
      - **Alchemy crafts consumables. Smithing crafts ammo and repairs today,
        and should produce equipment in future.** That answers which skill
        `crafting_yield_pct` belongs to — it is Alchemy's, for consumables —
        and what `crafting_quality_pct` needs before it can mean anything.
      - **Loot value should derive from the defeated party's total XP against
        the player party's**, with a percentage chance to receive it as a
        single better item rather than several common ones. That chance is one
        of the main points of the Luck attribute, which currently does very
        little.
      - ~~Two quality vocabularies~~ — **settled 2026-09-12.** One ladder:
        poor / common / good / fine / masterwork. The trade tools' "storied"
        and "legendary" were never quality — a storied lute is a masterwork
        lute with a story on it, which is *enchantment*. They map to masterwork
        and earn their value through the enchantment tier.
      - ~~Armour materials are metal-shaped~~ — **hide, scale, chitin and silk
        added 2026-09-12.** Silk is not structural: historically a silk layer
        catches an arrowhead and lets it be drawn back out, so it carries a
        ranged resistance rather than armour, and is allowed on robes, hats and
        capes only. A silk helmet would still be nonsense.
      - [ ] **Equipment generation only covers weapons and armour.** The twelve
        accessory types now have base entries and can be priced, but
        `generate_weapon` / `generate_armor` have no sibling for them. Nothing
        procedurally produces a focus, charm, ring or cape — and focus items are
        the single largest equipment category in the game at 210. A
        `generate_accessory` is the obvious next expansion, and it is what would
        let loot offer anything but weapons and armour.
      - Blocked on this: `crafting_quality_pct`, `crafting_yield_pct`,
        `loot_quality_pct`.

- [ ] ~~Item-granted auras have no consumer~~ — **built 2026-09-13**, as one
      system rather than the equip-time hook first sketched here. Auras are now
      declared in `resources/data/auras.json` and resolved by
      `scripts/combat/aura_system.gd`; equipment, statuses, perks and units all
      name one the same way, and a spell reaches auras through the status it
      applies. Five separate hardcoded implementations collapsed into it. See
      `verify_auras.tscn` (16 checks, 14/14 mutations caught).

      Open, now that the mechanism exists:
      - **Nothing shows an aura in the UI.** A player standing in a healing
        field gets no indication of where it comes from or how far it reaches.
        The status bar shows *statuses*, and most auras are not statuses.
      - **The AI does not know auras exist.** It will not step into a friendly
        aura, out of a hostile one, or focus the unit projecting one, which
        makes every aura in the game a pure player-side advantage.
      - **Only two item lines actually carry one** (khatvanga, healer's robe,
        longlife cap). The mechanism is now much cheaper than the content.
      - `radius: 99` on `avatar_of_the_storm` is how "party-wide" is currently
        spelled. It works, but a real `scope: party` would read better.

- [ ] ~~Specialist ritual robes~~ — **built 2026-09-13.** Eight new graded
      families (pandita robe, sage's, tantric, dreamer's, chodpa's, chodpa's
      eye covering, sorcerer's robe and hat), the black sorcerer's line renamed
      to black mantra, and the fabric ladder applied to all 108 graded
      garments. Remaining gaps, minor:
      - **Enchantment and Ritual have a robe but no headwear.** Every other
        school has both or is covered twice.
      - **Yoga has no dedicated garment.** It appears only as the pandita cap's
        secondary; `monks_robe` grants it but is ungraded and outside the
        system.

- [ ] **Superseded — the original specialist robe design.** Olaf's
      list, recorded before it evaporates. All graded 1-5 like the ngakpa line,
      chest slot unless noted:
      - healer's robe — white magic, **regeneration aura** at high grades
        (adjacent allies heal a little each turn)
      - black sorcerer's robe — sorcery, spellpower at high grades
      - pandita robe — learning, persuasion at high grades
      - sage's robe — earth **and** white, both smaller, rising incrementally
      - tantric robe — ritual
      - dreamer's robe — enchantment
      - chodpa's robe — summoning
      - chodpa's eye covering (**head**) — summoning, black at high grades
      - **No longlife robe** — it is a hat accessory to the healer's robe.

      **Gap: black magic has no robe.** The black sorcerer's robe grants
      *sorcery*; black appears only on the chodpa's eye covering at high
      grades. Every other school gets a dedicated garment. Either the black
      sorcerer's robe should grant black magic too, or a separate one is
      missing.

      **Material axis, per Olaf:** cotton / wool / silk as the quality tiers,
      with metal-threading for elemental variation — "silver-threaded silk
      healer's robe". That reuses `ritual_metals` for the thread, which is
      tidy. The caution is multiplication: 3 fabrics x 8 threads x 8 families x
      5 grades is 960 items. Suggest the thread only appears on the top two
      grades, so most robes are plain fabric and a threaded one is a find.

      **Blocked on machinery:** the regeneration aura and the longlife cap's HP
      aura need an item-granted aura path. `_process_aura_effects()` handles
      status-driven auras and `passive_aura` exists as an item field (one khata
      uses it), but nothing connects an equipped item to an aura status. The
      longlife caps carry `passive_aura: "longlife_hp"` as of 2026-09-13 with
      no consumer yet — the first thing to wire.

- [x] ~~**Ritual implement coding is declared but not yet player-facing.**~~
      **Done 2026-10-15.** The item tooltip now reads `ritual_metals` and
      `ritual_implements` and says it in a short gold block: "Copper serves
      Fire magic. / The phurba is an instrument of Sorcery. / Spells of both,
      such as Ember, Firebolt and 18 more, draw on each. / Consecration: Plain
      (1 of 5)". The metal line only appears when the item really carries that
      metal's skill — the bronze melong does not, so it only says it turns
      magic aside. The example spells are the lowest-level ones tagged with
      exactly those two schools, so Fireball itself is not the one named; the
      wording is Claude's and wants Olaf's pass.

- [ ] **Leadership should touch companion psychology.** `morale_pct` was
      removed 2026-09-12 as a relic: it was an early sketch that grew into
      PsychologySystem instead, and it left Leadership and Performance paying
      into a mechanic nobody ever built. But the intent underneath is sound —
      leading people well should affect how they hold up. Somewhere between
      Leadership level and companion pressure/relationships there is a wiring
      worth designing. Deliberately not specified here; it wants thought, not a
      stat key.

- [ ] **Traps — a battle feature, not an overworld one.** Originally conceived
      as a combat mechanic and the pieces are scattered across both readings,
      which is why it keeps looking like two half-features:

      - `trap_maker` (Smithing) is a combat perk deferred on a `place_trap`
        resolver — see §10. "Place a trap on an adjacent tile. The first enemy to
        enter takes damage equal to 30% of your Focus and is immobilized."
      - `trap_detection_pct` (Thievery) is a dead skill-table key, currently
        with no system at all. It was read as overworld detection, which is
        probably wrong: if traps are a battle feature, this is the counterplay
        to enemies placing them.
      - `Trapped` exists as a status in statuses.json.

      Design question before either gets built: are traps placed in combat only,
      or do they persist on the overworld map? That decides whether detection is
      a combat action, a map passive, or both — and `trap_detection_pct` cannot
      be wired until it is answered.

- [ ] **Support characters as equipment-shaped content.** The retired
      "logistics train" idea has one part worth keeping: a hireling who is not
      a full character — a cook who grants a supply bonus, a mule that raises
      carry weight. Content-wise a person, mechanically a piece of equipment.
      Not needed now, and mechanically close to the planned **mounts and pets**
      system, so the two should be designed together when that comes up.

## 12. Deferred by decision

Recorded so they aren't rediscovered as bugs.

### 2026-09-12 — the "logistics train" is retired

The original idea was a way to bring non-combat characters — a medic, a smith, a
trader — into the party without them being dead weight in a fight: a second
class of party member who contributed support bonuses instead of combat.

The game grew past it. Every character and NPC now runs on the same character
system, so there is no "full character" versus "support character" distinction
left to make. A medic in the party is simply a party member who is good at
Medicine and less good at swinging a sword, which is a more coherent thing for
the game to be about.

What survives is the mechanic, not the framing: `party_`-prefixed skill payouts,
where one member's skill pays the whole party. That is designed (§6 above) and
unbuilt. The support-character-as-equipment idea is parked in "Things to ponder"
for whenever mounts and pets are designed.

### 2026-09-12 — event rolls ignore the attribute, deliberately for now

An event tier DC is `best_party_stat + modifier` and the roll is
`d20 + best_party_stat`, so the attribute cancels and every tier is a flat
probability — a Focus-18 party rolls no better than a Focus-8 one. The comment
says this is intended ("difficulty constant regardless of power level").

Defensible for a skill check, and left alone when combat saves were
standardized, because changing it silently reweights every blue and yellow
choice across 348 events that were authored against the current odds. If it
does change, it needs an events balance pass in the same breath, not a
one-line edit.

### 2026-08-31 — from the enemy-XP design session

- **Map all five elements to the buddha families, and finish what each implies.**
  The original intent, watered down over time. Fire is padmakula — desire
  transmuted, magnetising — and its line is half-built already. The other four
  presumably map to vajra, ratna, karma and buddha, and the same audit would
  likely find each has a partial line nobody labelled. Worth doing all five
  together during the spells pass rather than fire alone, so the elements end
  up meaning something consistent rather than five unrelated damage types.
  Elemental affinities, klesha/wisdom pressure and the ngakpa robes all already
  key off the elements, so a coherent family scheme would tie several systems
  together at once.

- **Fire's padmakula line has holes at levels 1 and 5.** Fire is the lotus
  family — desire transmuted, magnetising rather than burning — and the ladder
  is already there in `Fire + Enchantment`: `charm` (L3), `magnetizing_aura`
  (L7), `dominate` (L9), with `berserk` and `shining_mirage` alongside at L7.
  But Fire has eight spells at L1 and twelve at L5 and not one of them is
  mental, so the line starts at 3, jumps to 7, and a character specialising
  into seduction and domination has nothing to learn across most of the
  mid-game. Wants an L1 and an L5 when the spells are refreshed. The Sensate
  background and the rakshasa's fire affinity of 5 both point at this line.

- **The naming lore is barely used by anything.** `animal_realm_names.json` is
  read by no script and referenced by almost no content: 389 personal names with
  meanings, plus per-birth place names that exist only in the file. The rakshasa
  set alone has **The Long Hunger** (a stretch of poor territory between
  productive ones), **The Wrong Side** (anywhere they do not go, and there is
  always a reason), **The Ridge Where They Wait**, **The Mango Kill**, **The
  Scratch Tree**, **The Three-Day Territory**. Every birth has six or so like
  these. Fold them into the events pass — an event set on The Wrong Side is
  already half-written by its own name.

- **The realms are badly uneven in size, and the animal realm ran away.**
  Births were planned at roughly 9-12 per realm.

  | realm | births | companions |
  |---|---|---|
  | hell | 6 | 24 |
  | hungry ghost | 14 | 23 |
  | **animal** | **18** | **52** |
  | human | 4 | 0 |
  | asura | 2 | 0 |
  | god | 3 | 0 |

  Hell is definitely too small at six and wants expanding toward the intended
  range. Animal multiplied well past it, and its companion count doubled again
  during the birth-by-birth pass — 52 against hell's 24 for three times the
  births. Not a problem while the content is good, but the realms should not
  stay this lopsided: a player's first world is the thinnest one they will see.

  When the animal pass finishes, return to hell and give it the same treatment.
  Its six devils have **no birth-specific backgrounds at all**, which is the
  single largest gap left in a finished realm.

- **Marjara want events badly.** Solitary predators who do not anchor
  encounters, but the birth carries more comic and world-building potential
  than any other in the realm: the smuggler's patter, the pleasure dancer, the
  cutpurse insisting marjara is innocent of this crime. Their place names are
  ready-made settings too — The Hollow Where Nothing Comes, The Long Wait, The
  Patient Rock. Worth a cluster of events rather than one.

- **Mriga have no events at all.** Four events mention gana; none mention mriga,
  so the forest has wolves in its prose and no deer. Two existing ones read as
  either and could simply be switched — `animal_forest_healer_camp` (a
  grey-muzzled healer, and medicine is the mriga trade) and
  `animal_forest_town_weapons` (traders). Beyond that, sketches for
  mriga-specific events, to fold into the general events pass:
  - **The Alarm Tree** — the herd's warning goes up before you can see why.
    Rewards Awareness; `first_to_know` should read it differently.
  - **The antler contest** — two bucks holding a clearing you need to cross,
    settling it by display. A fight you are allowed to decline, which is the
    most mriga thing available.
  - **The old trail** — a migration crossing your route, a `songline_guide`
    carrying the song that is the only map of it.

- **Parties should not all be hostile by default.** Traders are already neutral;
  a grazing mriga herd or a kapota flock should be too — `animal_kapota_flock`
  already says "usually neutral" in a comment nothing reads. Wanted without
  introducing factions or reputation: something stateless and per-encounter
  that decides whether contact opens combat or opens a conversation, so trade,
  contact and quests have somewhere to attach later. See the design note below.

- **Non-combat equipment kits as a broad concept.** The basis now exists: 40
  skill tools across eight skills, five tiers each, carried in the weapon hand
  the way a ritual focus is. Ritual clothing already exists too — the ngakpa
  robes, five tiers across five elements — but only serves magic.

  The obvious extension is craft clothing in the `chest` slot, so a
  practitioner could carry a tool *and* wear their trade: a physician's apron,
  a performer's coat, a smith's leathers. Roughly 40 more items.

  **Not to be done quickly.** The open question is what the bonuses should
  actually do. A flat +N to a skill is fine for one item, but a full kit —
  tool plus clothing plus accessory — stacks into a large number, and it is not
  obvious that a non-combat character should get a bigger total than a combat
  one gets from weapon plus armour. Wants a deliberate pass over how
  non-combat bonuses scale and interact before adding more of them.

- **Six encounters have role slots no archetype can fill.** They drop to a
  generic fallback. `tools/verify_enemy_xp.tscn` lists them on every run:

  | encounter | region / tier / role |
  |---|---|
  | `swamp_vermin` | fetid_swamps / shade / support |
  | `animal_yaksha_patrol` | meadow / devil / support |
  | `animal_dura_soldiers` | meadow / devil / skirmisher |
  | `animal_khadga_lone` | meadow / imp / frontline |
  | `animal_shyena_lord` | meadow / imp / frontline |
  | `animal_uluka_watch` | forest / devil / caster |

- **Equipment should be generated like the XP pool.** Currently
  `_generate_equipment` reads only `archetype.equipment_template.weapon.type`,
  so what a character can actually do has no bearing on what it carries.
  Wanted:
  - a **total equipment value that scales with the character's XP**, the same
    proportional way the XP budget itself does
  - **types chosen from the dominant skillsets** — a ranged build carries a bow,
    a Performance build carries an instrument, an armour build wears armour
  - **two weapon sets** where the gold and the skills make it reasonable
  - beyond the vital kit, **food and other resources**, and later everyday
    objects carrying minor bonuses — the point being roundness, the same reason
    XP now overflows into breadth. A character with rations, a spare knife and
    a lucky stone reads as someone who lives somewhere.

- **Instruments, and skill-linked equipment generally.** The game has ritual
  implements (damaru, kangling, conch, drilbu) but all are `type: focus` for
  Ritual and spellcasting. There is nothing a Performance character can hold.
  Other skills likely want their own objects too — Alchemy, Medicine, Smithing,
  Trade all imply tools that do not exist yet.

- **Birth and archetype can contradict each other.** Enemy births are rolled
  from the realm independently of the archetype, so 33 hell encounters produce
  things like `hell_green_devil_sniper` with a `blue_devil` birth. Either
  constrain the roll when an archetype id names a birth, or decide devils are
  mixed-parentage and let it stand.

- **Instruments as performance items.** The game has ritual implements —
  damaru, kangling, conch, drilbu, phurba — but all are `type: focus`, for
  Ritual and spellcasting. There is no lute, flute, drum or fiddle a
  Performance character could carry. Once XP breadth gives enemies and
  companions skills outside their build, a bard-adjacent character has nothing
  to hold. Wants its own item type and a few tiers.

- **Equipment should follow the character, not just the archetype.**
  `_generate_equipment` reads only `archetype.equipment_template.weapon.type`,
  so a generated character with ranged 8 and performance 7 still carries
  whatever its archetype hardcodes. With XP breadth now giving characters real
  skills off their build, gear should be chosen from what they can actually
  use — top weapon skill picks the weapon, and a high Performance or Ritual
  should put an instrument or implement in their hands.

- **Background assignment wants a pass across all births.** 94 backgrounds, but
  only 3 are universal (`healer`, `reveler`, `wanderer`) and 55 are single-birth
  — 58% of them. Average 4.8 births per background. Mriga was in none of the 22
  broadly-available ones (`warrior` covers 18 births, `scholar` 14,
  `merchant`/`guard`/`diplomat`/`noble`/`monk` 13) purely because it was created
  after those lists were authored; ten were opened to it by hand. Every future
  birth hits the same trap. After the animal-birth pass, go over all births and
  reassign, add, or generalise backgrounds — and check gana first, which was
  split at the same time as mriga.

- **Spell learning should cost XP.** `CharacterSystem.learn_spell` currently has
  no cost and no eligibility gate at all; it appends to `known_spells`. Making
  spells cost XP is the coherent counterpart to buying perks, and it spreads XP
  across more kinds of development instead of dumping it into raw attributes
  once a build's skills cap.

- **Trainers / domain-guild-style access.** Perks and spells stay discoverable
  by default — not seeing everything in one run is the intent. But some can be
  bought: access is earned through events, the way domain guilds already work,
  then purchased in a shop menu for XP plus sometimes another resource. Cost
  rises **geometrically** per purchase (n, 2n, 4n …) so a player buys two or
  three a run and agonises, rather than working through a shopping list. Worth
  its own spec; it interacts with the XP economy.

Spec: `docs/superpowers/specs/2026-08-31-enemy-xp-generation-design.md`

- **More ways to spend XP on meaningful development.** *(decided 2026-08-31:
  the 10-level skill system stays — too much is pegged on it — but perks and
  spells should become purchasable with XP.)*

  XP currently buys two things: attributes and skills. Skills hard-cap at level
  10, so a three-skill build absorbs at most 1,980 XP in skills and everything
  past that becomes raw attributes, which never saturate but are the least
  interesting kind of power.

  The two obvious sinks already exist as content and are not sold:
  - **604 perks** (550 skill + 54 cross) are acquired *free*, one choice of four
    offered per skill-up. With skills capped, a character sees at most ~350
    offers of a random 4-of-604 — most perks are never even seen, let alone taken.
  - **363 spells** — `CharacterSystem.learn_spell` has no XP cost and no
    eligibility gate at all; it appends. Access comes from guilds, events and
    starting kits.

  An earlier note here claimed an individual saturates near 4,500 XP. That was
  wrong: it assumed `attribute_caps` bounded attributes near 30, and those caps
  are enforced nowhere (see below). Only the skill cap is real.

- **`attribute_caps` is dead data** — all 47 races carry a 7-key caps dict that
  no script, scene or tool reads. Attributes are limited only by the rising cost
  per point, which is the soft cap the design wants anyway. Either delete the
  field or implement it; leaving it is actively misleading, having already
  produced one wrong conclusion in the enemy-XP spec.
- **Loot division** — post-battle XP now divides among party members; items do
  not, because they are indivisible and the party shares an inventory. Left
  deliberately asymmetric; revisit if party size feels wrong.
- **A visual tell for high-band encounters** — party archetypes let `swarm`
  (5–8 members) and `lone_hunter` (1) occur at the same XP budget, so the
  player can no longer read danger off the number of enemies on screen. Some
  other signal may be wanted.
- **Gana attribute caps** — set by hand during the predator/herbivore split to
  match the new daggers-and-unarmed lean; never reviewed against play.

- **`Dominated` full enemy control** — the puppet loses its turns; real control
  needs a player-drives-an-enemy-unit UI flow
- **Aura statuses** (`Soothing_Presence`, `Guardian_Kings`) — handled per-mantra
  by design, not via status effects
- **`attack_damage_buff_when_ally_dies`** — applies Rage, whose damage bonus is
  generic; a bespoke stacking version is unimplemented
- **Head natural weapons** (bite, beak) sit outside the arm attack chain — needs
  a head special-attack action or a primary-slot override
- **Coordinated group AI** (focus fire, flanking) — a larger AI feature
- **Day/night visuals** on the overworld; **rest blocked when a mob is adjacent**
- **Protector Offering** camp activity — blocked on DharmapalaSystem
- **More species**: centipede (many legs), bear — as animal content grows
- **Klesha / chronic-darkness counter** — debuffs for time spent below −50
  pressure
- **Psychology Layer 3 intervention** — social skills let one character reduce
  another's pressure
- **Racial trait content review** — `hell_born`, `undead_nature`,
  `spirit_nature`, `serpentine` are deliberate stubs pending realm design

---

## 13. The passive perk backlog (2026-09-10)

The engine is built and proven; the data is barely started. Of 470 passive
perks: **168** are implemented by hand in `scripts/` (checked by id with
`PerkSystem.has_perk()` at the moment they matter), **5** carry an `effects`
array, **297** are still description-only.

**The rule everything rests on:** a hand-implemented perk must never *also*
carry an `effects` array, or it fires twice. `verify_passive_perks`
derives the hardcoded set by scanning `scripts/` rather than keeping a list, so
a perk hardcoded tomorrow is protected without anyone remembering. (The
`wire_*_perks.py` authoring scripts were deleted 2026-10-16; perks are edited
in `perks.json` and `validate_data.py` holds their rules.) Note that **Parry and
Improved Parry — the plan document's own worked example of a
`stat_conversion` — are both hardcoded** and must stay that way.

Working effect types: `stat_bonus` (conditional and not), `stat_conversion`,
`resistance`, `on_trigger`.

- [ ] **Author the remaining 297.** Mechanical, and the tooling refuses bad
      data, but it is a long pass. Worth doing skill by skill.
- [ ] **`non_combat` effects are deliberately unbuilt.** ShopSystem and
      EventManager have no consumer for them. Authoring an effect before its
      reader exists is the exact failure this whole pass spent its time
      undoing — build the consumers first. This is what the seven overworld
      perks in §10 are waiting on too.
- [ ] **Unbuilt effect types:** `aura`, `cost_reduction`, `damage_modifier`,
      `resource_regen`, `spell_modifier`, `summon_modifier`, `special`.
      `summon_modifier` has the most data waiting on it — several black, fire
      and air perks buff summons and all of them are inert.
- [x] ~~**More trigger points.**~~ — **done 2026-10-15.** `combat_start`,
      `turn_start`, `take_damage`, `parry_success` and `ally_damaged` all fire
      now, nine in all. Both vocabularies live in `CombatStats.PERK_TRIGGERS` /
      `PERK_CONDITIONS` beside the stat lists, and `wire_passive_perks.py` and
      `validate_data.py` read them from there instead of restating them — the
      wiring tool's own copy was the thing that would have gone stale.
      Decisions worth knowing before authoring against them:
      - **A parry is a melee miss against someone holding a melee weapon.**
        There was no parry event — Parry is an armour conversion — so this is
        the definition. It fires *as well as* `dodge_success`, never instead.
      - **`take_damage` names its attacker only when the caller does.**
        `apply_damage` gained an optional `source`; weapon hits and spell damage
        pass it, ticks, terrain and splash do not. A payload aimed at an
        attacker who is not there is dropped, not turned on self.
      - **Payloads can now target `ally`** (the teammate an `ally_damaged` is
        about), and an `on_trigger` effect's `conditions` are finally checked —
        they were accepted by the tooling and ignored by the engine.
      - **Re-entrancy:** while one trigger's payload resolves, no trigger
        fires. The answer to an answer is silence, never a loop.
      - **Durations:** stat modifiers tick at turn start — twice, until §15
        fixed it the same day; once now — so a `combat_start` buff needs
        duration 2 to survive the first turn; a `turn_start` one fires after
        the tick and lasts its turn at 1.
      - The deployment path into combat never called
        `_apply_combat_start_perks`, so Rousing Display did nothing in any
        fight with a deployment phase. It does now.
- [x] ~~**More conditions.**~~ — **done 2026-10-15.** Twenty-one plus the
      terrain family. Each reuses the rule the game already had rather than
      inventing one: `unarmored_or_light` is `_unit_is_unarmored` (Diamond
      Body's test); `wearing_heavy_armor` is a chest piece with a Strength
      requirement, which is exactly what `generate_armor` writes for heavy
      types and what chainmail and lamellar carry; `from_behind` is the rear
      arc of `_get_facing_zone`, the same test as the +20% rear crit;
      `target_debuffed` is any status typed `debuff`. `on_terrain_type` became
      a family, `on_terrain_<ground>` for any key of `terrain.json`, checked
      against that file. Target conditions read the unit being hit — through
      `perk_attack_target`, which hit-chance and damage calculation set for
      their duration, because a stat getter has no target of its own.
      **Also fixed on the way:** conditional `stat_bonus` on `crit_chance`,
      `initiative`, `movement` and `spellpower` was accepted (all four are
      MODIFIABLE) and never summed — only accuracy, dodge, damage and armour
      getters read conditional perk bonuses. And `verify_passive_perks` had
      been calling the deleted `_perform_save_roll` since 2026-09-12; the
      SCRIPT ERROR aborted one function and the scene still printed VERIFY OK.
- [ ] **Perks the new conditions and triggers unblock** (2026-10-15). Fully
      expressible now: `aim_at_the_vitals` (crit vs a debuffed target, dagger),
      `one_line_one_breath` (accuracy on the first sword attack — the
      "cannot critically fail" half has no mechanic). Expressible in part, the
      rest waiting on an unbuilt effect type: `bedrock` (self half only — the
      ally half is an aura; "earth or stone" needs choosing among hills,
      mountains, ruins), `armored_skin` (needs a *conditional* `resistance`,
      which `get_passive_resistances` does not do), `hurry_betrays_distraction`
      (combat_start restore_stamina, but flat not %, and no mana payload),
      `field_commander` / `lay_of_the_land` (combat_start movement/initiative,
      but self only — no party-wide payload target), `burning_blood`
      (take_damage + movement buff, but "from a ranged attack" needs a
      condition on the attacker's weapon). Still blocked: `the_blade_decides`
      and `dont_lose_the_momentum` hear `parry_success` now but want stacks and
      a stamina-cost stat; `terrain_mastery` wants height, not ground.
- [ ] **Stat modifiers tick twice per turn start.** `_process_status_effects`
      calls `_process_stat_modifiers`, then `_process_turn_start_perks` ticks
      the same list again, so every timed buff and debuff lasts half its
      stated duration. Found 2026-10-15, not fixed — it changes every active
      skill's balance at once and wants a deliberate decision.

## 14. Systems the perk text assumes and the game does not have

**All three are built** (2026-09-12): forced movement, AoE damage falloff, and
one saving-throw mechanic. See Part IV for what changed.


Found while wiring the actives. Each is worth building as a system rather than
as a one-off, because several perks and spells want the same thing.

- [x] **Saving throws are three unrelated mechanisms.** Built 2026-09-12 —
      `SaveSystem`. Original note kept for the reasoning:
      `CombatManager._perform_save_roll()` is a flat `40% + 2%/point above 10`
      with no DC and no d20; `statuses.json` carries `save_type` and
      `save_at_end_of_turn` fields nothing reads; `EventManager` has its own
      d20+DC system. Perk text says "Constitution save at -20%" and "Focus save
      DC 16" and neither is expressible. Unifying on the event system's d20+DC
      unblocks ground_slam's knockdown, mountain_falls' stun and body_blow at
      once, and finally gives `statuses.json`'s save fields a reader.
- [x] **Forced movement does not exist.** Built 2026-09-12 —
      `_displace_unit` / `_apply_push`. Original note: There is a `Pushed` status and perks
      that talk about knockback, but no function relocates a unit — "Put Your
      Weight Into It" applies `Knocked_Down` instead. One
      `_displace_unit(unit, direction, tiles)` respecting walls, occupancy and
      the Juggernaut immunity already written at `combat_manager.gd:6977`
      covers shield_bash, overwhelming_blow, the push spells and the knockback
      perks together.
- [x] **AoE damage falloff.** Built 2026-09-12 — opt-in `falloff` lists.
      Original note: `impaling_strike` wants 100% to the first tile
      and 60% to the second; `AoEResolver` returns an unordered tile list with
      no concept of distance-weighting. Useful for every spell that wants a
      softer edge.

## 15. Found in the 2026-10-15 sweep

A pass over the open list by parallel agents turned these up. Each was noticed
while doing something else and was left alone on purpose. File:line references
were accurate on 2026-10-15 and drift.

### Bugs — real, small, worth fixing first

- [x] ~~**Event fight difficulty does nothing.**~~ — **built 2026-10-15.**
      The old `DIFFICULTY_MULTIPLIERS` went in September's enemy-XP rewrite
      (the spec retired it as a power scalar, superseded by tier and band),
      and nothing took over the word, so 203 authored fights ignored it. It
      now multiplies the party XP budget from a `difficulty` table in
      `encounter_budgets.json` — through the budget rather than HP on top,
      because gear, breadth, spells and the victory reward all follow the
      budget already. `boss` adds `min_tier: boss` and a fixed `band`
      instead of a multiplier: every boss fight already resolved to boss
      tier, and 2.0 × 1.6 would have counted it twice. Unknown words fall
      back to normal with a warning (roll words like `difficult` map
      across); `validate_data.py` rejects them in data. Found alongside:
      `_build_enemy` still fed raw XP into the potion/bomb roll and the
      crude fallback weapon against thresholds tuned for the old
      party-power number (~80 = mid-game), so every animal-realm enemy
      saturated them; both read the kit-budget scale now. `verify_enemy_xp`
      checks normal is the unchanged formula and each tier builds stronger
      parties than the one below.
- [x] ~~**Timed buffs and debuffs last half their stated duration.**~~ —
      **fixed 2026-10-15; decided: the data is right, the clock was wrong.**
      Worse than "half": the second tick only happened when the unit carried a
      status (with none, `_process_status_effects` returned early), so the same
      buff lasted one length or the other depending on whether someone was
      Blessed. Both ticks are gone; `_start_current_turn` ticks stat modifiers
      once, right after the statuses, stunned turns included. A duration now
      means: counts down at the start of its owner's turn, gone at 0 — 1 lasts
      until your next turn begins, 2 lasts through it. Nothing retuned. Things
      that look tuned around the old clock, left for a balance pass:
      `shield_wall` (duration 2, says "until next turn" — now lasts a turn
      longer); `shield_bash` (−10% accuracy "for 1 turn" on an ENEMY at
      duration 1 — ticks off at the enemy's turn start, before it attacks, and
      always did); `borrowed_opening` and Borrowed Force (a buff at duration 1
      from a dodge on the enemy's turn — gone at your turn start, before your
      attack). Statuses, taunt, cooldowns, mantras and the overworld's
      `combats_remaining` buffs were checked and already ticked once.
- [x] ~~**`_unit_is_unarmored` reads a `hands` slot that does not exist**~~
      — **fixed 2026-10-15.** The perks say two things and now get two
      answers from one helper. "While unarmored" (Diamond Body, Iron Shirt):
      no armour piece at all — but clothing is not armour, so robe, hat,
      trousers, boots, sandals, gloves and prosthetics are fine
      (`CLOTHING_TYPES`). "Unarmored or in light armor" (Flowing Footwork,
      Bare Chest, `unarmored_or_light`): armour allowed so long as no piece is
      heavy, and heavy is a Strength requirement, the `wearing_heavy_armor`
      rule. Every hand slot is read, `hand_l2`/`hand_r2` included. So a leather
      vest now keeps Flowing Footwork (it did not before — the old helper
      called it armour and the verifier asserted so); iron gauntlets now break
      it. Note: generated gauntlets and helmets never carry a Strength
      requirement (`generate_armor` only adds one at base armour ≥ 3), so they
      count as light.
- [x] **Poison and acid ground deal `physical` damage**
      (`combat_manager.gd:~6531/~6537`), so armour reduces them and poison
      resistance does nothing, while the Poisoned status deals poison.
      *Fixed 2026-10-15:* both deal `poison`. Acid could have been "physical
      that ignores armour", but the acid bomb and flask already deal poison
      and the puddle should be the same stuff as the splash.
- [x] **Storm_Lord and Lightning_Form retaliate with `"element": "air"`**
      (`statuses.json:~657/~698`). Air stopped being a damage type in the
      resistance rebuild, so it lands unresisted and not as magic — should be
      `lightning`. `validate_data.py`'s `_walk_damage_types` (`~1013`) checks
      `damage_type` keys but not `element`, which is why nothing caught it.
      *Fixed 2026-10-15:* lightning. The validator now checks `element` in
      the files where it means damage (statuses, zones, auras, ammo, spells,
      summons — elsewhere it is a skill element), plus `damage_element`,
      `attack_damage_type`, `retaliation_damage`, and the brand and weapon
      enchant tables in combat_manager.gd. That turned up five more of the
      same: the tornado zone dealt `air` (now physical, like its spell), the
      vajra mandala's toll and Drowning Pressure dealt `water` (now crushing,
      what water spells deal), Frost/Stone/Storm brands dealt water/earth/air
      (now ice/crushing/lightning) and Electrified_Weapon's bonus was `air`
      (now lightning).
- [x] **Wet ground only slows.** Comments at `combat_manager.gd:~6558` and in
      `CombatGrid.add_terrain_effect` promise an ice/air (or water)
      vulnerability that the code never grants.
      *Fixed 2026-10-15:* wet ground also applies a new **Soaked** status,
      `grants_vulnerability: {lightning: 25}`, for a turn. Lightning only —
      water conducts, and it makes wet ground a set-up an Air caster cashes
      in rather than a Water caster's combo with itself. 25 is first-pass.
- [x] **Supply purchases never pay the shop's purse** — `buy_item` returns
      before `_adjust_shop_purse(price)` for supply items
      (`shop_system.gd:~643-653`). Fixed 2026-10-15: the till is paid right
      after `spend_gold`, before either branch. `verify_economy_bonuses`
      buys rations into an empty till.
- [x] **`reset_for_new_life` keeps `last_healing_location`**
      (`game_state.gd:~272`), so Cloud Gate can target a spot on the previous
      life's map. `flags` also carry over — maybe deliberately; decide.
      Fixed 2026-10-15: it clears `last_healing_location` and `planar_return`
      (a Shift begun before a death would pull the new life "home"), and calls
      a new `MapManager.reset_for_new_life()`. That last one was the big one:
      `visited_maps` was never cleared, so reincarnating into a realm you had
      been to restored the OLD life's map — same terrain, same dead mobs,
      same looted chests. While there: a stashed map carried its own nested
      copy of `visited_maps`, and restoring it replaced the live stash with
      that older copy, so A → B → A forgot B. The stash drops the nested copy
      now. Checks in `verify_economy_bonuses` and `verify_overworld_spells`.
      **Still open — decide:** `flags` and `completed_quest_ids` survive a
      death (only New Game clears them). Every flag the data sets today is
      per-world quest/event state (`mantra_scroll_found`,
      `cold_prisoner_freed`, `hg_king_safe_conduct`…) plus camp scratch
      flags (`sermon_stacks`, `herb_prep_bonus`); none is karma or
      reincarnation. So a regenerated world can find a quest already
      half-done, or never offer one again. Clearing both in
      `reset_for_new_life` is two lines once you say so.
- [x] **A multi-day `advance_time` fires `day_changed` once**
      (`game_state.gd:~315`), so the lunar listener (`overworld.gd:~1883`) can
      miss a full or new moon across a long rest. Fixed 2026-10-15: one emit
      per day crossed, in order; `get_lunar_day`/`is_full_moon`/`is_new_moon`
      take an optional day and the overworld listener reads `new_day`. The
      investment tick is idempotent, so it copes. Latent today (the longest
      advance is an 8-hour rest). Check in `verify_economy_bonuses`.
- [x] ~~**Severing a primary arm drops only the ACTIVE weapon set's weapon**
      (`body_system.gd:~444`); the other set's stays in the lost hand. And
      with a full inventory the force-clear deletes the item (`~433`).~~
      **Fixed 2026-10-15.** `BodySystem._drop_from_lost_part` empties that
      hand in both weapon sets. There is no stash or ground to drop onto, so
      a full pack now takes the item anyway (`unequip_item`/`add_to_inventory`
      grew a `force` flag) and stays over-full until sorted — nothing is
      destroyed. The drop is printed, as the event's sever already is.
- [x] **Bombs and the poison talisman brand apply statuses with no source**
      (`combat_manager.gd:~7174`, `~10060`), so the thrower's
      `burning_damage_pct` / `poison_damage_pct` never scale them.
      *Fixed 2026-10-15,* and aura `grant_status` passes its owner too. On the
      way: the flashbang and acid flask list bare status names, and `_use_bomb`
      called `.get()` on them — a script error that stopped the throw. Bare
      names now take the bomb's `status_duration`.
- [x] **Luck's loot weighting is dead code.** `_get_modified_rarity_weights()`
      (`combat_manager.gd:~787`) is never called, `_generate_loot_drops`
      (`~634`) ignores its `_best_luck`, and the jackpot reads raw
      `attributes.luck` (`~569`), so Luck from buffs and gear counts for nothing.
      Fixed 2026-10-15: `derived["luck"]` is the effective number (attribute +
      gear + traits + Luck map buffs) and `best_party_luck()` reads it. A won
      fight now also rolls a **lucky find** — one piece of equipment nobody
      was carrying — at exactly the jackpot's odds (same Luck term, cap and
      `loot_chance_pct` boost, separate roll), its rarity from
      `_get_modified_rarity_weights(fight size, Luck)`. Thievery's
      `loot_quality_pct` stays where it was (the share of carried gear you
      take) and does not touch the find, so nothing counts twice. The numbers
      are the old dead function's: worth a look in play. Checks in
      `verify_combat_procs`.
- [x] ~~**`unbroken` (perks.json `~8458`) is description-only** — "wounds
      inflicted on you are downgraded one severity"; there is no downgrade step.~~
      **Built 2026-10-15** in `WoundSystem.apply_wound`: physical wounds only
      (a disease is not a wound). Severe counts as moderate, moderate as
      light, and a light wound is shrugged off. The entry keeps its id and
      carries `downgraded`, read through `get_entry_severity()` by the
      penalties, Scarred and the wounds panel — it stays one step lighter
      through escalation. **Still open:** the perk's FIRST sentence (stop at
      25% HP once per combat, armour doubled) is not built either.
- [x] ~~**`every_opening_is_an_invitation` counts buffs**~~ — **fixed
      2026-10-15.** Both halves (accuracy and crit) ask one helper,
      `_opening_is_an_invitation`, which asks `unit_has_debuff()`.
- [x] ~~**Rousing Display's +5 initiative never affects round 1**~~ — **fixed
      2026-10-15.** Both ways into a fight now go through `_begin_first_round`:
      combat-start perks, THEN the round-1 sort, then the first turn. Duration
      1 is right once the order is: sorted in, ticked off at the ally's own
      first turn, gone before round 2 is sorted. Still open: the perk's text
      says "+5% morale and +2 Initiative"; the code gives +5 and no morale.
- [x] ~~**On-hit procs don't check `defender.is_alive()`**~~ — **fixed
      2026-10-15.** `_apply_on_hit_status` is `_apply_status_effect` that
      refuses a fallen defender; every status in `_process_on_hit_perks`, the
      weapon and ammo procs, the weapon oil and the spell-perk riders (Measured
      Radiance, Tremor, Scattering Gust, Riptide, the Black fear) goes through
      it. It mattered more than it looks: a bleeding-out unit keeps its
      statuses through a revive, so the stun waited for whoever picked them
      up. Persistent wounds and diseases from a killing blow still land — that
      reads as intended.
- [x] **`duel_stop_hp_pct` on an encounter is ignored** — only the archetype's
      copy is read (`hungry_ghost_encounters.json:~603`, `enemy_system.gd:~928`).
      And the duel threshold moves with in-combat max-HP changes. Fixed
      2026-10-15: the encounter's value overrides the archetype's, on every
      enemy it builds; the yield line is a share of the max HP noted on
      `combat_started` (`CombatManager.duel_stop_hp`). Checks in
      `verify_combat_systems`.
- [x] **Enemies don't get their birth TRAITS' resistances**
      (`enemy_system.gd:~723`); players do, through `TraitSystem.get_resistances`.
      *Fixed 2026-10-15:* the same call, added after the racial block. An
      undead enemy now resists poison 25 and disease 50 like an undead player.

### Multi-arm attacks drift from the main hit

The extra-arm chain (`_execute_arm_chain_attack`, `combat_manager.gd:~1506-1594`)
re-implements what the main hit does and keeps falling behind it — Hardened and
Undead Hunter both drifted that way. The fix is one shared on-hit function with
a strength multiplier, not more patches. What it currently skips: the 15%
poisoned-blood roll (`~9590`), weapon on-hit procs (`_process_weapon_on_hit_procs`,
`~1894`: Trishula, Chakram), weapon-oil damage, crit audio, the dagger/ranged
per-turn counters. Also: each arm is logged twice in different formats
(`~1568` and `combat_arena.gd:~2741`); logs show pre-armour damage while popups
show HP lost (the main hit too); a 0-damage arm shows "Arm N: 0" where the main
hit shows nothing; and `_has_shield_equipped` (`combat_unit.gd:~1256`, plus
`combat_manager.gd:~2081/~2207`) reads only `weapon_off`, never weapon set 2.

**Done 2026-10-15.** One path now: `_apply_hit_damage`, `_apply_weapon_oil`,
`_resolve_hit_procs` (on-hit perks, on_hit/on_crit/on_kill triggers, weapon
procs) and `_count_weapon_attack`, called by the primary hit and by
`_execute_arm_chain_attack` alike. Arms hit at full strength, as before; the
arm's fire chance still scales only the *persistent* afflictions (crit wounds,
diseases, poisoned blood). Each landed arm spends an oil charge. Chakram
`pass_through` is skipped for arms on purpose (it is the thrown ring's one
flight; arms are melee-only anyway). Arms are logged once, by the arena; every
attack log shows HP lost ("12 (18 before armour)"), from a new
`result.damage_taken`. A blow that costs no HP shows no popup, arm or main.
Arm crits play the crit sting. The shield half was wrong: `_has_shield_equipped`
goes through `ItemSystem.get_equipped_item`, which already reads the active
set. The real bug was the three `combat_manager` reads of a top-level
`equipment["weapon_off"]` that does not exist — so **a two-armed dual-wielder
never chained an extra arm at all**, and Offhand Jab never fired. All three
read the active set now. `tools/verify_multi_arm` covers it.

### Four-armed bodies are half-built

No race uses the `four_armed` body plan. Its `hand_l2`/`hand_r2` slots cannot be
filled — gloves, gauntlets and bracers list only `hand_l`/`hand_r` in items.json
— and are missing from the default equipment dict (`character_system.gd:~196`).
There is no `weapon_main2`/`weapon_off2`; `BodySystem.ARM_WEAPON_SLOTS` makes
adding one a single line when it is wanted.

**Slots done 2026-10-15:** gloves, gauntlets and bracers list `hand_l2`/`hand_r2`,
the default equipment dict has them, and `equip_item` now refuses a slot the
body does not have (`BodySystem.body_has_slot`), so a human can't glove a third
hand. Still missing: the paper doll in `main_menu.gd` (`~2662`) has no
hand_l2/hand_r2 boxes, so the player can only fill them through starting gear.
And still no race uses the plan.

### UI and legibility

- [x] **The tile hover label is hidden in move mode** (`combat_arena.gd:~2460`)
      — exactly when hazards matter. Merge it with the cover label.
      *Done 2026-10-15:* one label now. `TooltipText.move_tile()` puts the
      cover line on top of everything `tile()` says; the separate cover label
      is gone.
- [x] **A main-hit crit has no visual marker** (`combat_unit.gd:~1151`), while
      extra arms now say "crit!".
      *Done 2026-10-15:* `attack_unit` flags the defender
      (`next_damage_is_crit`) around the main hit's `apply_damage`, so the
      number reads "12 crit!" in the arms' crit orange. Oil and enchant damage
      after it stay plain. Spell crits still show a plain number.
- [x] **Popup labels have no width but centred text** — they probably start at
      the unit's centre and run right. Check on screen.
      *Done 2026-10-15:* they did — every popup sat 80px right of centre once
      measured. All of them go through `_make_popup_label()`, which gives the
      label a width and shifts it left by half; the struck-through "expired"
      label was 60px wide and wrapped long names, and is 160 now too.
- [x] **Status icons are a hard-coded emoji `match`** (`combat_unit.gd:~327`);
      most of 187 statuses show "•". An `icon` field in statuses.json scales.
      *Done 2026-10-15:* all 187 have an `icon`; `CombatUnit.status_icon()`
      reads it and falls back to "•". A few pair a glyph with an arrow
      (🔥↓ for fire vulnerability), so the row is space-separated now.
- [x] **The summoning terrain bonus is never shown** before casting
      (`combat_manager.gd:~3566`).
      *Done 2026-10-15:* the spell tooltip says "The spirits of the living
      water answer readily here: +25% spellpower". The rule moved into
      `CombatManager.summon_terrain_affinity_for()`, which the cast and the
      tooltip both ask.
- [x] **The status tooltip omits `retaliation`, `aura` and `spread`.**
      *Done 2026-10-15:* a line for each — "Hits back at melee attackers…",
      "Aura: Soothing Presence (allies within 2): heals 5 each turn" (read
      through auras.json), "Can spread to an adjacent unit (15% chance…)".
- [x] **Tooltip hazard lines hand-copy `_process_terrain_effects()`** — change
      one, change the other (`TooltipText.tile`).
      *Done 2026-10-15:* both read `CombatGrid.TERRAIN_HAZARDS`. The match in
      `_process_terrain_effects()` is gone. Two small behaviour changes came
      with it: wet ground no longer logs "takes 0 damage", and the tooltip
      now says poison and acid do *physical* damage, which is what they
      always did.
- [x] **Dorje + Drilbu set text is hard-coded** in `item_tooltip.gd:~133`,
      duplicating `item_system.gd:~557-560` and omitting the opener bonus.
      *Done 2026-10-15:* `ItemSystem.SET_BONUSES` holds the numbers and
      `TooltipText.set_bonus()` builds the text from it. There was no opener
      to show: `active_set_bonus` was stored "for future combat opener
      hooks" in April and nothing has ever read it. The opener is unbuilt,
      not just unmentioned.

### Data and tooling hygiene

- [x] **`vocabulary_baseline.json` has stale entries** — `crafting_yield_pct`,
      `loot_quality_pct`, `trap_detection_pct` are wired but still listed. The
      validator should fail on a baseline entry that has gained a reader.
      Done 2026-10-15: validate_data.py now fails on a baseline line whose
      value has gained a reader *or* left the data, so the file only shrinks.
      It found two more — `black_damage_per_turn` (read by `_dot_element`'s
      suffix parse) and `spreads_on_contact` (no status carries it any more).
      All five removed; `crafting_quality_pct` is the last skill payout left.
- [x] **The `effect_duration_pct` entry in §6 uses an old name.** perks.json
      has 16 `effect_duration_turns` and no `effect_duration_pct`. Re-check
      whether `_calculate_status_duration` and `derived.effect_duration_turns`
      actually double-count before deciding anything. Re-checked 2026-10-15:
      they do not — the function reads the table and nothing else. §6 entry
      rewritten and ticked; `verify_combat_procs` now guards it.
- [x] **Unread flags in spell `special` blocks** duplicate what their statuses
      do: `spells.json:~5419` `physical_immunity`, `~7044`
      `immune_to_all_damage`, `~7436` `magic_resistance_bonus`, `~1380`
      `fire_vulnerability`, `~4757` `ranged_damage_reduction`. Delete them.
      *Done 2026-10-15,* with their unread siblings that also only restated
      the status (`cannot_deal_physical`, `major_speed_boost`, `defense_bonus`,
      `short_duration`). Oily Skin keeps `cumulative: true` — see below.
- [ ] **Oily Skin says `cumulative: true`** (`spells.json:~1380`) and nothing
      reads it; Fire_Vulnerable is not `stackable`, so a second cast only
      refreshes. Make the status stack, or drop the flag.
- [ ] **The acid bomb and flask apply `Corroded`, which is not a status**
      (`items.json:~2690/~2993`), and the flask's `armor_reduction: 5` has no
      reader. "Eats through armour" is the item's whole point and does nothing
      beyond poison damage. Needs a Corroded status (armour down) to exist.
- [x] ~~**The disease-on-hit and crit-wound code exists twice**
      (`combat_manager.gd:~1566-1594` and `~9549-9600`) — see the multi-arm note.~~
      **Fixed 2026-10-15** — only the `_process_weapon_on_hit_procs` copy is
      left; see below.
- [x] **`_check_special_requirement`'s attribute branch has no users**
      (`perk_system.gd:~269`) and reads base attributes. Remove it. Removed
      2026-10-15. Every `special_requirement` in perks.json is an
      `<element>_affinity_N` or `any_[N_]<category>_at_N`, and validate_data.py
      now rejects any other shape — the function returns false for it, so the
      perk could never be taken.
- [x] **Small stale comments:** `perk_system.gd:~511` says 164 hand-wired perks
      (176 now); `combat_manager.gd:~9571` on Undead Hunter; `_spell_save`'s
      doc comment is fused into `_apply_save_gated`'s (`~8214`). Fixed
      2026-10-15, plus the same 164 in wire_passive_perks.py's docstring, and
      a second fused pair: `_process_status_effects`'s doc had landed on
      `_dot_element`.
- [ ] **Air_Shield's 25% is still a hard-coded effect string**
      (`combat_manager.gd:~1710`). It could become a status `ranged`
      resistance, which would change its stacking from multiplicative to
      additive.
- [x] **A verifier's own parse errors were invisible.** Fixed 2026-10-15:
      `verify_all.sh` now fails a scene that prints `SCRIPT ERROR` and shows
      the line. Worth remembering when a verifier "fails" with no message.
      The root cause was layer 1: `godot --editor --quit` does not compile
      scripts nothing loads — tried with a duplicate function and an
      undeclared name, in both `scripts/` and `tools/`, and it reported none
      of the four. Layer 1 now also runs `tools/parse_check.gd`, which loads
      every .gd for real and caught all four.

### Decisions for Olaf

- ~~**Investment:** one open stake in the whole world~~ — **confirmed by
  Olaf 2026-10-15.** Its payout still comes from nowhere rather than the
  shop's purse — revisit when settlements have wealth.
- ~~**Iron Cortex no longer requires Akimbo**~~ — **confirmed by Olaf
  2026-10-15.**
- ~~**Luck's "lucky find"**~~ — **kept, Olaf 2026-10-16.** A won fight rolls for one extra piece of
  equipment at the jackpot's odds, rarity tilted by Luck. It is the agent's
  design (the old rarity weighting had nothing left to weigh), untuned.
- ~~**Flags and finished quests survive a death**~~ — **decided by Olaf
  2026-10-16: they don't.** `reset_for_new_life` clears both.
- ~~**Unbroken shrugs off a light wound entirely**~~ — **confirmed by Olaf
  2026-10-16** (Armor 10 may be strong). The reading of
  "downgraded one severity" at the bottom of the scale.
- ~~**Difficulty tiers**~~ — **accepted by Olaf 2026-10-16:** easy 0.75 / normal 1.0 / hard 1.2 / very_hard 1.4 XP,
  boss = boss tier with a fixed band. "hard" is the commonest word in the
  data (103 of 203 fights), so the average fight grew ~11%. Tune in
  `encounter_budgets.json` → `difficulty`.
- ~~**`status_effect_chance_pct` scales two ways**~~ — **kept as is, Olaf
  2026-10-16:** ×1.3 on a chance roll, but
  +30 percentage points (as DC) on a save. Consistent with how SaveSystem
  treats every other percentage, inconsistent with itself.
- ~~**Should Ritual reach** aura `grant_status`, retaliation `status_chance`
  and the hard-coded perk procs~~ — **yes, Olaf 2026-10-16; done** through
  `CombatManager.ritual_chance` (aura saves get the DC bonus).
- ~~**"Magic resistance" blocks poison**~~ — **unintended, Olaf 2026-10-16;
  fixed.** The status scope is `magic` now (was `non_physical`) and mantras
  cover magic types only. Poison is not magic.
  - [ ] Idea from Olaf: a Yoga and/or Might perk that resists poison.

### Round 2 decisions (Olaf, 2026-10-16)

- Frost bomb/oil apply `Slowed` — kept; no Chilled status.
- Heavy armour = any heavy piece worn — kept for now (one iron helmet turns
  on Living Fortress / Armored Skin; revisit if that plays wrong).
- Rousing Display: +2 Initiative is enough; no morale (the psychology system
  replaced it).
- Borrowed Force/Opening last until the next attack or the end of your next
  turn; Opening needs you unarmed when you dodge. A dorje, mala or tool in
  the hand does not stop you being unarmed — done: `CombatUnit.NON_COMBAT_HELD_TYPES`,
  and you hit with your natural weapon while holding one.
- Unbroken's doubled Armor lasts to the end of the turn it fired — fine.
- Enemy consumables: done — an archetype may set `consumable_share` (set
  aside before gear) and a `consumables` list it buys first, round-robin, up
  to 6. For grenadier / alchemist / tinkerer enemies.
  - [ ] Write those archetypes (grenadier, alchemist, tinkerer), matching
        the backgrounds that exist for them.
- Vajra & Bell `active_set_bonus` opener — not needed with the current set
  bonuses; left unbuilt (the stored key is still unread).

- **Investment payouts, ritual tooltip wording and the parry definition**
  (a melee miss against someone holding a melee weapon) are all first drafts.

### Round 3 — found during Round 2 (2026-10-16)

Done 2026-10-16 (branch `claude/round-3`), plus three new enemies:
`hell_yellow_devil_grenadier` (powder train, hard), `animal_bhramara_honey_keeper`
(honeycomb) and `animal_vanara_tinkerer` (workshop). The content_sync
"IGNORED" report did not reproduce.

#### Round 4 — found during Round 3

- [x] **`tools/wire_passive_perks.py` and `wire_active_perks.py` are stale
      and destructive**: `--write` would undo Aegis of Tranquility's elements,
      Borrowed Opening and more. Their work is all in the data — delete them
      (or strip them to a read-only checker).
- [x] **Done 2026-10-16: data-driven AI templates** (`enemies/ai_templates.json`,
      archetype `ai_template` + `ai` overrides, verify_enemy_AI). Was: enemy AI throws bombs only at 2+ clustered party members
      (`_ai_try_use_bomb`) and drinks potions only itself
      (`_ai_try_use_potion`), so the honey-keeper never heals allies and a
      lone target is never bombed.
- [ ] Hell kit budgets are so small that a grenadier at `normal` buys no
      bombs (powder train set to `hard` for now). Consider a consumable floor.
- [x] Chain Spark text says 50% damage, code deals 60%. (Now 50%, Olaf.)
- [ ] Magnetizing Aura spell: `special.triggers_on` and
      `special.effect: "charm_chance"` are unread.
- [x] Mirrored glove pairs count their stats on both hands — no: a pair is one item and counts once (Olaf). Done.
- [x] AI templates: `_ai_try_cast_spell` does not know heal spells — the
      honey-keeper's `lesser_heal` is aimed at the nearest party member.
      Done (Round 5): the AI read spells before `get_spell` normalised them,
      so every spell looked like "single enemy" and ally buffs never fired.
      New priority ids `heal_spell` and `buff_spell`, a `spells` section.
- [x] Bomb targeting measures range with diagonals (Chebyshev) but
      `ai_use_combat_item` checks Manhattan steps — a diagonal throw at the
      edge of range silently fails. Done (Round 5), and the same for spells:
      the AI now measures with `CombatManager.spell_distance`.
- [x] Decision: players cannot hand a potion to an adjacent ally; enemies
      with a medic template now can. Give players the same? Yes (Olaf). Done:
      potions, medicine and herbs; picking one with an ally beside you asks
      for a target.
- [x] AI templates still to come: `targeting` and `movement` sections
      (reserved in the schema); the 23 `support` archetypes stay on `default`
      until given a template. Done (Round 5): `targeting.prefer`,
      `movement.style` (`hang_back`), templates `healer`, `enchanter`, `hexer`
      on 20 of them; the maneater's `ai_behavior: priority_target` is now
      `targeting.prefer: "weakest"`.

#### Round 6 — found during Round 5

- [ ] The AI never casts resurrections (`single_corpse`), whole-party or
      whole-field spells (`party`, `global`), or self-teleports (Blink, which
      the mindbender is guaranteed). Each needs its own "when is this worth
      it" rule.
- [ ] Decision: spell, scroll and bomb ranges count without the diagonal
      shortcut (Manhattan), while walking, weapon reach and blast radii count
      a diagonal as one step. Deliberate? A range-4 Firebolt cannot reach a
      target 3 tiles away diagonally.
- [ ] `hg_swamp_leech` (support) and `animal_bhramara_drone` have no spells
      worth a template of their own; the leech stays on `default`, the drone
      is an `enchanter` for its summons.
- [x] Every enemy potion, bomb and oil was logged twice (the AI function and
      `_on_item_used_in_combat`). Fixed.
- [x] Medicine and herb items did nothing when clicked in combat. Fixed with
      potion handing.
- [ ] Heavy Armor Training's movement half does nothing yet: no heavy
      armour has a movement penalty.

- [x] `generate_armor` ignores which item types a material allows ("Iron
      Robe", "Bone Hat"); the weapon generator checks.
- [x] Unequipping a pair of gloves that starting gear put in both hands as
      two separate items returns only one.
- [x] Heavy Armor Training, Armored Skin, Living Fortress: description only.
- [x] Shield Wall gives flat +25 armour, not "+25%"; the adjacent-ally +10%
      half is not built.
- [x] Borrowed Opening's trigger fires on ranged misses; the text says melee.
- [x] Chain Spark fires for Air-school spells dealing physical damage.
- [x] Unread: Fireshield spell `triggers_on`, Domain Crystal
      `special.attack_type: "laser"`, `active_set_bonus`.
- [x] `cure_all`, `smelling_salts`, `spirit_salt` list statuses that do not
      exist (`Burned`, `Chilled`, `Unconscious`, `Haunted`, `Possessed`).
- [x] `content_sync` reports "IGNORED (context field)" for two domain event
      choices (`trait_gambler_game/play_deep`, `trait_secret_bearer_slip/draw_it_out`).
- [x] Bardo screen's own `current_map_id = ""` / `visited_tiles.clear()`
      are redundant now.

### Round 2 — found while fixing the above (2026-10-15)

Done 2026-10-16 in seven groups (branch `claude/round-2`), except the
duplicated keys, which need Olaf. Spells cannot crit, so "spell crits"
was really combat-skill hits; those now show the crit marker. The
`active_set_bonus` (Vajra & Bell opener) is left: nothing says what it does.

**Bugs**

- [x] **`fallen` is never cleared on a new life or New Game, and not saved**
      (`character_system.gd:29`) — a previous life's companions can be
      raised, and the list is lost on load.
- [x] **`planar_return` is not saved** (`game_state.gd` `get_save_data`) —
      loading mid-Planar-Shift strands the party in the other realm.
- [x] **`load_map` keeps `searched_tiles`** (`map_manager.gd:~479`), so a
      searched spot carries over to the same coordinates on another map.
- [x] **The bardo screen's "less gold than the first run" never happens** —
      `GameState.gold = 50` (`bardo_screen.gd:~312`) is overwritten by
      `start_new_run()`'s 100.
- [x] **Trishula's `on_crit_status: "pinned"` is lowercase**
      (`items.json:~1177/~1205`); the status is `Pinned`. Probably never applies.
- [x] **The acid bomb and flask apply `Corroded`, which is not a status**,
      and the flask's `armor_reduction` has no reader — "eats through armour"
      does nothing.
- [x] **`domain_events.json` uses the roll word `"moderate"`** twice; the DC
      table does not know it (silently normal) and the validator misses it.
- [x] **Imbued arrows still apply their spell to a defender the arrow just
      dropped** (`combat_manager.gd:~1902`); Touch of Gloom's stat penalties
      likewise land on a downed target (`~4685`).
- [x] **Downed and actionless units (bleeding out, decoys) never tick
      statuses or stat modifiers**, so a buff on a downed ally rides into
      later rounds.
- [x] **Avatar of the Wind's 1-turn ally buffs expire at each ally's own turn
      start** (`_process_turn_start_perks`), so allies acting after the perk
      holder never benefit.
- [x] **Buffs tuned around the old double tick** — `shield_wall` (2, "until
      next turn": now a turn longer), `shield_bash` (1-turn debuff on an enemy
      ticks off before it attacks; always did), `borrowed_opening` / Borrowed
      Force (gone before your attack). `borrowed_opening` also says "+20%
      crit" and gives +20 damage. Rousing Display says "+5% morale and +2
      Initiative" and gives +5 Initiative, no morale.
- [x] **Heavy armour means only the chest** (`combat_unit.gd:~1023`
      `is_wearing_heavy_armor`), and `generate_armor` (`item_system.gd:~1522`)
      gives a Strength requirement only at base armour ≥ 3 — generated
      gauntlets and helmets are always "light".
- [x] **`unbroken`'s first half** (stop at 25% HP once per combat, armour
      doubled) is not built.
- [x] **Weakening Gaze and Lingering Touch read raw Enchantment**
      (`combat_manager.gd:~4785/~5020`), ignoring item and race bonuses.

**Loose ends and dead code**

- [x] `shop_system.gd:498` `barter_buy_item` is never called, and would not
      pay the purse or stock supplies if it were. Delete or fix.
- [x] `_pick_item_from_types`' fixed-item branch ignores realm, so a lucky
      find can be another realm's item.
- [x] `_get_modified_rarity_weights` rounds to whole numbers — legendary
      weight does not move until Luck ~17; its "difficulty_ratio" is really
      fight size.
- [x] `_generate_enemy_inventory` (free, by role) and
      `_generate_skill_consumables` (paid from the kit budget) both hand
      enemies consumables — double-dipping.
- [x] `combat_manager.gd:~4676-4765` still compares `element` with
      `"air"`/`"water"`/`"earth"`, which can no longer match.
- [x] Unread: `summon_templates.json:~1963` `attack_damage_type`, Fireshield's
      `special.retaliation_damage` (`spells.json:~3277`), Oily Skin's
      `cumulative`, and `item_system.gd` `active_set_bonus` (the Vajra & Bell
      opener was never built).
- [x] `combat_grid.gd` `add_terrain_effect` (~845), `get_effect_name` (~935)
      and the effect colours (~990) are still hand-written beside
      `TERRAIN_HAZARDS`; fold them in.
- [x] `tooltip_text.gd` calls the private `CombatManager._spread_chance_to_float()`.
- [x] The baseline lists `space_damage_per_turn`, which `_dot_element` probably
      reads by name — the validator's text search cannot see that.
- [x] Poison's `_check_perk_status_immunity` call (`~9822`) passes no attacker.
- [x] Every `verify_enemy_xp` run prints ~165 "no births defined for realm
      'domain'" warnings (`character_system.gd:~554`).
- [x] **items.json: 52 items (cape, tool, herb, medicine, eyewear, face_cloth)
      have types missing from `item_types`** — 40 tools, 6 capes, 2 herbs, 2
      medicines, 1 eyewear, 1 face cloth. Found building `CONTENT.md`
      (2026-10-16).
- [x] **Three duplicated JSON keys** — decided by Olaf 2026-10-16 and
      restored: Karka Guardian `piercing: 15`, centipede `piercing: 10`,
      Ice_Sheet `ice: 100` (immune). Found normalising the data
      (2026-10-16). Only the last value was ever read, so normalising dropped
      the dead first one and nothing changed in play — but each looks like a
      typo for a different key: Karka Crusher `crushing: 15` then `-10`
      (`animal_archetypes.json`), Carrion Worm `crushing: 10` then `-10`
      (`hungry_ghost_archetypes.json`), the Ice_Sheet summon `ice: 100` then
      `50` (`summon_templates.json`). Recover the intended values from git
      (`git show 5370c04^:<file>`) and decide.

**UI**

- [x] **The equipment screen has no `hand_l2`/`hand_r2` boxes**
      (`main_menu.gd:~2662`) — the slots exist but only starting gear fills them.
- [x] **Arm lines are logged above the main hit** — the `unit_attacked`
      handler runs before the arena logs "X attacks Y" (`combat_arena.gd:~2733`).
- [x] **Oil damage on an extra arm shows as a separate plain number.**
- [x] **Spell crits show a plain damage number** (`combat_manager.gd:~7956/~8042`).

### CONTENT.md — left open (2026-10-16)

- [x] **A blank line inside a `>` quote block loses the paragraph break.**
      Typing an empty line between quoted paragraphs, instead of a lone `>`,
      joins them in the JSON — no text lost, but the break is. The parser
      should read a blank line between two `>` lines as `>`.
- [x] **`tools/wire_active_perks.py` still holds `DESCRIPTION_FIXES`**, a
      second source for `host_of_the_winds`'s description. Re-running it
      would quietly overwrite a CONTENT.md edit to that one perk (code
      edits to the JSON win by design). Drop the description from the
      script, or make it skip descriptions that differ from its old value.
- [x] **`content_base.json` is ~3 MB and rewritten on every sync** — expect
      merge conflicts in it when two branches both sync. Regenerate it
      (`content_sync.py --write`) rather than hand-merging.

### Perks the engine can now express (§13)

Authorable in full: `aim_at_the_vitals`; `one_line_one_breath` except "cannot
critically fail". In part, waiting on an effect type: `bedrock` (ally half needs
an aura), `armored_skin` (conditional resistance), `hurry_betrays_distraction`
(flat stamina only, no mana payload), `field_commander` and `lay_of_the_land`
(no party-wide payload target), `burning_blood` (needs an "attacker used ranged"
condition). Still blocked: `the_blade_decides`, `dont_lose_the_momentum`
(stacks, a stamina-cost stat), `terrain_mastery` (height, not ground).

## 17. Normalization (2026-11-25)

Moving content onto one shared effect language. The design is at
`docs/superpowers/specs/2026-11-25-effect-normalization-design.md`.

- [ ] **Effect normalization**: spells, statuses, auras/zones, items,
      upgrades, traits, affixes, mantras, events/quests. In progress.
  - [x] **Stage 1, the engine (done 2026-11-25).** `scripts/effects/` holds
        `effect_vocab.gd` (the approved lists and `validate`), `value_paths.gd`
        (fortify, drain, set and multiply holds; attribute and skill holds;
        release at combat end; lasting damage that rest, heal or restore
        clears), `effect_context.gd` and `effect_resolver.gd` (the ops
        damage, heal, modify, status, move, kill, summon, zone and resurrect).
        `tools/effect_check.py` mirrors the vocabulary in Python, and
        `tools/verify_effects.tscn` has 41 in-engine checks. `verify_all.sh`
        now runs every `tools/test_*.py`. No spell, status or item uses any of
        this yet.
  - [x] **Stage 2a, boosts and skill formulas (done 2026-11-25).** A
        temporary boost now counts everywhere a real one does (spec 10.1), and
        skill bonuses are a formula with no level cap (spec 10.2). Skill
        bonuses in `perks.json -> base_bonuses` are
        `{curve: climb|steady, at_5, at_10}` (plus optional `base`, `integer`,
        `limit`), worked out by `PerkSystem.curve_value`. Attribute holds are
        written to the character, `ValuePaths.refresh_character` refreshes a
        unit mid-fight (enemies too), and `CharacterSystem.get_effective_attribute`
        is the one definition of an effective attribute. Perks, XP purchase and
        learning a spell in a shop still use the bought level.
    - **Olaf's review item:** `docs/plans/SKILL_CURVES_2026-11.md` lists the
      before/after numbers for every skill stat at levels 1 to 10. `at_5` and
      `at_10` in `perks.json` are the two knobs to tune per stat.
    - [x] ~~**Enemy stale bonus names.**~~ *Done 2026-11-26 (stage 2b,
      task 1), by Olaf's ruling that every character uses one sheet.*
      `EnemySystem._calculate_derived_stats` read `attack`,
      `armor_penetration`, `mana_cost`, `stamina`, `strength_weapon_damage`
      and `initiative_bonus`, which `perks.json` does not use. The function
      is gone rather than renamed: an enemy is now the same dictionary as a
      party character (equipment in its slots, `base_resistances`, traits,
      perks), derived by `CharacterSystem.update_derived_stats`, and every
      reader uses `derived.resistances`. A bare-handed enemy fights with its
      body plan's natural weapon.
      - **Balance note:** enemies now receive the full per-level skill
        bonuses, elemental affinity, worn talisman and equipment stats;
        encounter budgets may need retuning. Sample numbers are in
        `.superpowers/sdd/2026-11-26-effect-normalization-stage2b/task-1-report.md`.
    - [ ] **Summons (`summon_templates.json`) onto the same sheet.** Summons
      and illusions are still hand-built dictionaries with no `attributes`,
      a bare `equipped_weapon` and scaled `derived` numbers.
      `ValuePaths.refresh_character` leaves a unit with no `attributes` as it
      is, so an attribute or skill hold on a summon changes nothing on its
      derived stats until it has a sheet.
    - **Found during 2a, waiting on Olaf:**
      - **The main-hand weapon's damage and accuracy count twice** (found in
        2b task 1). `ItemSystem.calculate_equipment_stats` adds the weapon's
        `stats.damage` and `stats.accuracy` into `derived.damage` and
        `derived.accuracy`, and then `CombatUnit.get_attack_damage` and
        `get_accuracy` add `weapon.stats` again. This was already true for
        the party. Enemies now share the sheet, so it applies to them too
        (a Fine Iron Spear with accuracy 6 gives its wielder +12). Count it
        in one place or the other; which one is your call, since it moves
        every armed character's numbers.
      - Effective values include gear and traits, so some numbers moved even
        with no boost active. For example a Strong trait now adds to attack
        damage and saves, and enemy saves now include their trait modifiers.
      - Stealth detection never reads Awareness (`combat_manager.gd` at
        lines 8266 and 8281). This bug was already there.
      - The shop Charm discount, map discovery and the overworld passives still
        read raw values, not effective ones. They need a decision.
      - A negative effective skill counts as 0. Only skills in
        `NEGATIVE_SKILL_PENALTIES` are penalised, so a negative alchemy, trade,
        logistics, smithing and so on does nothing.
      - Removing a curse trait now also counts persistent skill damage,
        because the purge reads the effective level.
  - [x] **Stage 2b, statuses and auras/zones (done 2026-11-27).** Enemies
        use the one character sheet; statuses, auras and zones are effect
        lists run by the resolver; the yes/no rules are flags; behaviour is
        triggers, periodic effects and intercepts; and the seven extensions
        of spec 10.3 are built (group targets, affinity, borrowed values,
        building states, comedown, upkeep, pressure). What was built and where
        it differs from the design is spec 10.5.
    - **Found during 2b, for Olaf to decide:**
      - Infected's Fungal Spawn fights for the infected carrier. This is
        today's behaviour and is probably a bug.
      - Two units both in Counterstance can counter each other back and forth
        until a miss or a death. This was already true before stage 2b.
      - `Ranged_Attack_Debuff_50` reads -40 accuracy, so its name and its
        number disagree.
      - `Constitution_Buff` now raises Constitution, so max HP rises but
        current HP does not jump.
      - Immune System's 15% affliction resist now works (it was read by
        nothing before).
      - Five legacy status keys are still unmigrated:
        `grants_movement_ability`, `grants_travel_speed_pct`,
        `grants_concealment`, `damage_increase_pct` and `special`.
      - Trap Maker's `payload_scale` is unread.
      - No real status uses `stacking.grow` or `upkeep` yet; only the test
        statuses in `verify_effects` do.
      - Scroll casts (`_use_scroll`) do not fire the `casts` trigger, because
        they bypass `cast_spell`.
      - `turn_start_inside` and `turn_end_inside` are built but no zone uses
        them, and `turn_end_inside` does not run on the skip_turn path.
  - **Carried from stage 1** (stage 2b task 7 ticked these; the rest move to stage 3):
    - [x] ~~`Resistance.breakdown()` does not list effect holds.~~ *Done:
      the holds were already listed by source name (the status's name) when
      statuses moved over; `breakdown_lists_holds` in `verify_effects` now
      keeps it that way.*
    - [x] ~~The `status` op logs `applied: true` even when the status was
      resisted or there was nothing to remove.~~ *Done 2026-11-27.*
      `CombatManager._apply_status_effect` now answers whether the status
      landed, and `EffectResolver._do_status` logs `applied: false` with the
      reason `resisted` or `nothing to remove`.
    - [x] ~~A party-screen line showing lasting damage.~~ *Done 2026-11-27.*
      Each party card lists `damaged_values` with what clears it
      (`Focus −2 (until full rest or White magic 5)`); no damage, no line.
    - [x] ~~`EffectContext.for_spell` keeps only the first school.~~ *Done
      2026-11-27.* It keeps all of them (`schools`, with `all_schools()`),
      and a heal clears damage whose `cleared_by` names any one.
  - **Carried into stage 3** (things stage 1 and stage 2b found and left alone):
    - Spells apply statuses through the `status` op, and the spell side has
      not moved: spell `duration` formulas, `casts`-style triggers authored
      in spells, and dispel moving onto `categories` (retiring `dispellable`
      and `dispel_methods`) are stage 3's.
    - Ritual's `status_save_dc_bonus` is not applied to resolver saves, and
      the save has no `dc_stat` (spells default to Focus, skills to Strength).
    - `kill` does not give the kill reward, so a spell's `on_kill` would be
      lost when spells move over. It also skips bleeding-out units, which
      the old spell code finishes off.
    - Nothing sets `target_pos` yet, so ground-aimed spells must set it
      when they move over.
    - A lasting-damage entry marked `held` would survive into a save made
      mid-combat. If mid-fight saving is added, loading must clear the flag.
    - Push slams from the `move` op are always physical damage; spells use
      their own damage type.
    - Zone `aoe` and `duration` shapes are not validated yet.
    - A damage-type split truncates each part, losing up to 1 point.
- [ ] **Perk normalization**: the ~175 hard-coded `has_perk` branches and the
      ~101 `combat_data` active perks, moved onto the same vocabulary. Olaf asks
      for this once effect normalization is finished; not before.

## 16. Spell balance and cuts (review 2026-11-23)

From `docs/plans/SPELL_REVIEW_2026-11.md`, which has the reasoning and the
numbers. Parked on purpose: the effect normalization comes first, and several
of these get easier or change shape once it is in (bosses vs instant kill,
crowd-control upgrade tiers). Reference curve: L1 15 mana / ~15 damage, L3 40
/ ~25, L5 75 / ~50, L7 135 / ~80, L9 225 / ~120. Area spells deal about the same
as single-target spells of their level.

**Overpowered**
- [ ] `stinking_cloud` (L1, 15 mana) — a radius-2 zone that stuns for
      spellpower duration. Make it a chance with a save each turn, or a weaker
      status.
- [ ] Hard crowd control upgrading to "all enemies" — `dread` (Paralyzed),
      `petrify`, `charm`, `confusion`, `chaos`, `berserk`. Cap at area, or halve
      the duration at the all-enemies tier. **Latent:** spell upgrade tiers are
      not built — `upgrade_scaling` is read by nothing — so this bites only
      once they are.
- [ ] Instant kills work on bosses — `midas_touch`, `deathfog`, `liberate`,
      and `doom` through `death_on_expire`. `on_failed_save.instant_kill` has
      no boss check. Bosses should take the pass branch, or a % of max HP.
- [ ] Battlefield-wide spells beat every storm — `mudra_of_touching_the_earth`
      (150 to all enemies + 150 heal to all allies), `sunrise` (120 + 100),
      `wilting_curse` (150 to all living enemies), against `firestorm` (120,
      radius 5). Price globals higher or deal about 60% of a storm.
- [ ] Party-wide extra turn at L7 — `second_wind` (upgradable to all allies),
      `rain_of_revival` (area, plus 60 heal). L9 at most, single target.
- [ ] `cloudform` (L7) — physical immunity, upgradable to the whole party.
- [ ] `ghost_shoal` (Water/Summoning L7) — 100 damage band + Confused: the
      strongest L7 area spell, in the lowest-damage school.
- [ ] `golden_blade` (L7, 304 mana) — 225 single-target damage, more than any
      L9 single-target spell, plus gold on kill.

**Underpowered**
- [ ] `vaporize` (L9) — 150 single target, below golden_blade. About 250, or
      no-corpse + ignores resistance.
- [ ] `black_lightning` (L7, 135) — 50 + Blind against `lightning` (L5, 75): 60 +
      stun. About 90, or let it chain.
- [ ] `tsunami` (L9) — 30 damage + push 2. Base about 80, or add Prone.
- [ ] `cauterize` (L1) — damages your own ally 5 to do what `herbal_remedy`
      does while healing 15. Give it wounds, or a permanent bleed stop.
- [ ] `ember` (L1) — Burning only, only on a recently burning target. Worse
      than firebolt.
- [ ] `soothing_presence` (L3) — heals 5.
- [ ] `steam_jet` (L3) — 20 in a 3-tile line against breath_of_fire's 25 cone +
      Burning.
- [ ] `surge` (L1, 5) and `geyser` (L7, 30) — low even for Water.
- [ ] `death_bolt` (L3, 20) — below curve; its raise-on-kill is unwired.

**Mana-cost anomalies** — deliberate domain surcharge or error? Decide, then
write it in `school_notes`.
- [ ] L5 at the L9 price (225): `mindmuck`, `rain_of_mud`, `vision_of_reality`.
- [ ] L3 at the L5 price (75): `eerie_dirge`, `sonic_boom`, `metal_to_mud`,
      `globe_of_glass`, `heat_transfer`, `flash_of_radiance`, `fragrant_sauna`,
      `divine_eye`, `mudling` — while `battle_chant`, eerie_dirge's sibling,
      costs 40.

**Cut or merge**
- [ ] `grounding` (L3) vs `cleanse` (L7) — grounding removes all negatives
      (`negative` = `all_negative` in status_ops) plus a CON buff, four levels
      earlier. Narrow grounding to physical afflictions or one status.
- [ ] `cloudform` (L7) vs `fluid_form` (L9) — same immunities; cloudform is
      lower level, targets allies, upgrades to the party, and has a smaller
      vulnerability. One of them goes self-only.
- [ ] `clarity` vs `clear_mind` (both L3) — both remove mental debuffs. Keep
      clear_mind (luminosity domain), give clarity another job.
- [ ] `voidbolt` vs `bitter_word` (L1 Black/Sorcery) — cut voidbolt or give it
      a rider.
- [ ] `crushing_hand` vs `stone_spike` (L1 Earth, 15 damage) — merge.
- [ ] Five short teleports — `jump` (L1, 4), `get_out` (L1, 3), `blink` (L3, 6),
      `cloudstep` (L3, 5, ignores LOS), `flash_step` (L5). One per level band,
      a twist each for the rest.
- [ ] `bulwark` (L3) / `stone_skin` (L5) / `golden_armor` (L5) — three
      physical-resist buffs, two at the same level.
- [ ] `shrapnel_blast` vs `earthquake` (L7, 100) — shrapnel has a smaller
      radius and no rider. Add bleed or armour-pierce.
- [ ] `oily_skin` (L1) ⊂ `melt_armor` (L3) — fine as a ladder; oily_skin could
      instead make burning spread.
- [ ] `slashing_blade` — description is still "Blade damage (+50% dmg/cost)".

**Status mechanics never built** (found in the stage 2b status migration,
`docs/plans/STATUS_MIGRATION_2026-11.md`). Each of these words sat in a
status's `effects` list and nothing in the game ever read it, so the status
promised something it did not do. They are removed from `statuses.json`, and
each status carries `notes: "Unbuilt: <words>"`. Build the mechanic, or cut the
promise from the status's description.

| Status | Unbuilt word | What it promised |
|---|---|---|
| Forgetful | `can_move` | can still move while it cannot attack or cast |
| Blinded | `cannot_target_spells` | cannot aim spells (it does stop ranged attacks) |
| Boiling_Blood | `fire_damage_per_turn_internal` | fire damage from within (the tick is physical today: the word does not end in `_damage_per_turn`) |
| Dominated | `joins_party_permanently` | the dominated creature stays after combat |
| Festering | `damage_increases_each_turn` | the damage climbs each turn (`damage_increase_per_turn` is also unread) |
| Diseased | `stat_penalties` | stat penalties |
| Mirror_Images | `illusory_copies` | the copies as units (only the absorb works) |
| Wrathfully_Bound | `cannot_teleport`, `cannot_flee` | no teleporting, no fleeing |
| Chaotic | `random_attacks`, `random_spellcasting` | random attacks, random spells (random movement works) |
| Friendly | `relationship_bonus` | better relations with NPCs |
| Lifelink | `heal_50_percent_of_damage_dealt` | works, by status name: flag `lifesteals_on_hit` |
| Blood_Hunger | `lifesteal_on_attacks` | works, by status name: flag `lifesteals_on_hit` |
| Karmic_Bond | `linked_to_ally` | the link to a chosen ally (the 75% healing share works) |
| Eternal_Vow | `return_with_20_percent_hp` | works for `return_on_death_next_turn`, which returns at once, not next turn |
| Grounded | `cannot_fly` | no flight (`loses_flight` works) |
| Pushed | `knockback` | the push (the Repositioning ops do forced movement) |
| Water_Walking | `can_walk_on_water` | walking on water (`immune_to_water_terrain` works) |
| Precision | `range_bonus` | +range: there is no `stat.range` and no getter reads one |
| Range_Debuff | `range_penalty` | -range: same |

# Part II — Designs waiting to be built

Kept in full: these are settled designs with no implementation yet.

## Yidam System (personal deity practice)

- Deities are **translated** into English ("Adamantine Terrifier", not
  "Vajrabhairava") — avoids publishing secret names while keeping the meaning
- Roster drawn from the mantra perks (`is_mantra` in `perks.json`); masks as optional head-slot
  items granting a large Deity Yoga bonus
- **Relationship stages**: Heard → Connected → Practicing → Established →
  Realized (persists cross-lifetime from Practicing+)
- **Primary mechanic**: mantra accumulation — `mantra_count` already
  accumulates via camp Mantra Recitation and has no consumer today, so the hook
  is waiting
- Commitment to a single deity is mechanically rewarded
- **Karma affinity** — some deities more accessible by karma profile
- **Dedicated spell** per deity, unlocked at Practicing+
- **Quest chain** per deity, encounter-chain style

Tasks: design roster (names, karma affinities, mantras, spells, masks) ·
implement relationship tracking (YidamSystem autoload or extend KarmaSystem) ·
wire mask bonuses into Deity Yoga activation · define cross-lifetime persistence
· write quest chains.

## Dharmapala System (protector relationships)

- Protector deities, translated names, accessed via **shrines** on the overworld
- Relationship is **transactional** (offerings) and **worldly** — complements
  yidam's inner practice
- **Offerings**: realm-specific items consumed at shrines; each dharmapala wants
  particular things
- **Stages**: Stranger → Known → Favorable → Under Protection → Bonded
  (persists cross-lifetime from Favorable+; full carry at Bonded, partial at
  Favorable)
- **Interventions**: limited uses, refresh between shrines, each reflecting the
  deity's nature — fate rerolls, oracle glimpses, enemy weakening
- **Vows**: 1–2 behavioural constraints each; breaking them damages the bond
- **Synergies**: a Hayagriva yidam + fire-aspect dharmapala is a natural build;
  Black Sorcerer's Robe + Mahakala relationship passive

Tasks: design roster (domains, offerings, interventions, vows) · shrine objects
in `map_generator.gd` · DharmapalaSystem autoload · cross-lifetime persistence
in KarmaSystem/reincarnation.

## Masks and the face slot

A major design space, deferred to its own pass. `face` slot, type `"mask"`,
already mapped in `_find_slot_for_item()`.

- Deity masks → large Deity Yoga bonus; school masks → skill bonus to one
  school; elemental masks → resistance + minor affinity
- Possible types: wrathful (combat), peaceful (healing/buff), animal form
  (special abilities), ritual (Ritual/Yoga)
- Cross-reference the ritual garb masks already generated — combat masks vs
  ritual masks vs deity masks may need separate type tags

## Wounds × spells × items (design, unbuilt)

**Spells**
- White magic should cure wounds out of combat — suggest `cures_wound_category`
  / `cures_wound_id` on spell defs, checked in the spell outcome handler
- Water magic antidotes — reduce `rests_untreated` by 1 rather than curing
  outright (`reduce_escalation: 1`)
- Black magic harm spells — `inflict_wound` (wound id + chance) so enemies can
  accumulate wounds too
- Ritual mandala at Full Rest — lower wound escalation counters party-wide

**Items**
- Weapon traits `wound_chance` + `wound_type` — bleed weapons that inflict
  persistent wounds, an "attrition weapon" class
- Weapon trait `disease_chance` + `disease_type` for bone/grave-iron weapons
- Silver weapons — `disease_immune_on_hit`, purification on contact
- Thematic armour reducing wound chance for its body location (bracers → arms,
  sabatons → feet)

**Calendar**
- Lunar-day perk bonuses (e.g. Full Moon Practitioner: +5 spellpower on day 15)
  via a `PerkSystem.check_lunar_bonus()` hook in `update_derived_stats`
- `auspicious_day_bonus` on camp activities
- `lunar_day_required` on camp events
- Realm-time tension: hell rests cost more, HG gives no recovery without food
- Seasons: placeholder — if ever tracked, winter → bone fever up, summer → rot
  sickness down

**Rest perks designed, unbuilt**
- Light Sleeper (Awareness 12+): Quick Rest heals +10% (currently 40%)
- Meditator's Repose (Yoga 4+): Full Rest always counts as a safe camp
- Iron Constitution (Con 14+): Medicine heal_pct doubles at Full Rest

## Trait matrix — reference for the events pass

`psychology_system.gd` defines 30 named states, five elements × two poles ×
three tiers. This is the canonical five-poison/five-wisdom scheme and every
trait is now seated on it.

| Element | Klesha: minor / major / crisis | Wisdom: minor / major / crisis |
|---|---|---|
| **Space** (delusion) | Confused / Dissociated / Absent | Clear-headed / Open / Luminous |
| **Fire** (desire) | Restless / Craving / Consumed | Warm / Magnetizing / Radiant |
| **Water** (aversion) | Irritable / Grief-struck / Poisonous | Focused / Clear-eyed / Compassionate |
| **Earth** (pride) | Insecure / Arrogant / Humiliated | Grounded / Equanimous / Unshakeable |
| **Air** (envy) | Anxious / Paranoid / Envious | Alert / Inspired / Brilliant |

Trait coverage after the 2026-07-27 pass — 48 of 56 gameplay traits carry a
pressure link (the eight without are plain bodily facts: `strong`, `quick`,
`frail`, `clubfooted`, `hard_of_hearing`, `iron_stomach`, `night_owl`,
`bird_lover`):

| | klesha | wisdom |
|---|---|---|
| space | 6 | 6 |
| fire | 6 | 6 |
| water | 8 | 6 |
| earth | 10 | 4 |
| air | 6 | 5 |

**Sign convention:** negative pushes the baseline toward klesha, positive toward
wisdom, matching `apply_pressure()`. Trait and race data used to be written the
other way round — see Part IV.

**When placing trait gates in events**, the useful question is which of the five
families the situation touches, then whether the trait makes the character
better or worse at it. A `not_trait` gate is as useful as a `trait` gate:
`incurious` should close doors that `curious` opens.

### Bonding vocabulary

`bond_tags` on each trait is what `RelationshipSystem` scores party rapport on:
**vice, devotion, martial, arts, scholarly, sociable, solitary, grief, order,
beasts, hardship, wonder**. Shared tags pull a pair together (vices pull
harder), `opposed_traits` push apart, and the pairs are symmetric — the
validator would catch it if they were not. Bands: rival / cool / neutral /
warm / sworn.

The trait baseline is recomputed on every read rather than stored, so editing
traits.json can never leave a stale number in a save; only the drift from
things that actually happened is persisted.

### Traits as the home for standing effects

Settled 2026-07-27. The line between the three systems:

- **Traits** — permanent or run-long, identity-shaped, visible outside combat:
  traversal, resistances, social access, what events offer you.
- **Statuses** — turn-scoped combat state, with duration, stacking and dispel.
  Unchanged; `Burning` is not a trait, but a character who *cannot burn* is.
- **Perks** — remain the purchase. A perk whose effect is a standing condition
  declares `"grants_traits": ["<id>"]` rather than restating it in code, and
  the trait then carries the stat, skill, resistance and event-gating
  consequences. Only for unconditional effects: Diamond Body's poison immunity
  applies *while unarmored*, which a trait cannot express, so that stays a
  combat check.

Trait `resistances` are wired: `TraitSystem.get_resistances()` folds into
`derived.resistances` beside racial and equipment values, so `CombatUnit`
reads them with no combat-side change. Because disease is not a damage type
but an affliction chance, `WoundSystem._resisted()` also rolls the same value
against catching one — venom_ward both blunts poison damage and halves the
chance of catching something from a poisoned blade.

Still open for the temporary-trait idea: traits have no expiry. A
`duration_rests` field ticked in `overworld._tick_rest_traits()` — the hook
that already turns `grief_struck` into `mourner` — is the small piece that
would let a spell or event grant `flying` for a while.

## Trait acquisition

Nine acquired traits are granted by code hooks, with no event needed:

| Trait | Hook |
|---|---|
| `scarred` | a severe wound is cured |
| `maimed` | a limb is severed (dropped again when the last part regrows) |
| `death_touched` | survived an otherwise-fatal blow (Ancestors_Blessing, Eternal_Vow) |
| `steady_practice` / `mantra_worn` | `mantra_count` reaches 40 / 250 |
| `ash_marked` | 12 sadhanas performed |
| `bloodied` | the party kills something with the boss role |
| `sole_survivor` | last one standing after two others fall |
| `long_marched` | 30 rests taken |

Losses: `addiction` is broken by a facility with Medicine 5+, `grief_struck`
settles into `mourner` after 25 rests, `maimed` goes when the body is whole.
All thresholds are first-pass.

### Self-generating events

Events with `"trigger": "trait"` + `"requires_trait"`, or
`"trigger": "relationship"` + `"requires_band"`, are rolled on a rest night
that nothing else claimed — 12% and 8% respectively. `{a}` and `{b}` in title,
text, choice text and outcome text are substituted with the real names.
Eight trait events and three relationship events exist; more are welcome, and
the mechanism is the cheap part.

## Realm-specific mechanics

- **Hell**: pure combat focus — done
- **Hungry Ghost**: resource scarcity
- **Animal**: combat and negotiation mixed
- **Human**: heavy dialogue/quest focus, three zones —
  West (Oddiyana/Gandhara steppe): Scythian nomads, cavalry → Ranged, Guile,
  Daggers · NE (Zhang-Zhung): proto-Tibetan shamanic Bön, yak herders → Ritual,
  Yoga, Earth magic · SE (coastal trade cities): cosmopolitan mercantile →
  Trade, Persuasion, Alchemy
- **Asura**: competitive events, duels
- **God**: almost no combat; diplomacy and trade

## Miniboss and boss mechanics

Unique per-fight mechanics: multi-phase fights, special win/lose conditions,
environmental interaction. Hell is standard so far. Hungry ghost candidates:
Bone Lord (earth magic undead commander), Great Devourer (shaza), Mirror of the
Setting Sun (copper construct), Matriarch of All Longing (yidag).

## Open design questions

- **Karma visibility** — currently fully hidden (thematic). Should Yoga unlock a
  karma meditation showing rough scores, or stay mysterious?
- **Weapon element affinity** — every weapon has an `element` field doing
  nothing. Design: high elemental affinity boosts weapons of that element. Wire
  into affinity bonuses or `generate_weapon()` scaling.
- **Mantra system** — some Deity Yoga effects are simplified stat bonuses rather
  than true unit spawns. Acceptable?
- **Spell accuracy / spell projectiles** — deliberately left to ferment.
- **Combat grid size** and how much positioning should matter.

---

# Part III — Per-level skill bonuses with no consumer

> **Stale — cleared, kept as history (2026-10-15).** Every key in the table
> below has been renamed, wired, merged or removed; the live state is §6
> above. Only `crafting_quality_pct` is still unread; the Enchantment
> duration question (now spelt `effect_duration_turns`) was settled — it is
> read once, from the table (§6).
> Read what follows as the July snapshot it is: the names, the "13 of 40"
> count and the suggested target systems are all out of date.

Found 2026-07-27. Kept in full because it is the largest actionable gap.

`perks.json` → `base_bonuses` gives every skill a per-level stat table, and
`CharacterSystem.update_derived_stats()` applies **13 of the 40 stat keys**. The
other 27 are read by nothing, so those skill levels grant their combat numbers
and then silently grant nothing else. Levelling Trade to 10 currently confers no
discount, Grace no movement, Logistics no travel or supply benefit.

Applied today: `attack`, `damage`, `strength_weapon_damage`, `crit_chance`,
`armor`, `armor_penetration`, `max_hp`, `damage_reduction_pct`, `spellpower`,
`mana_cost`, `dodge`, `stamina`, `initiative`.

**Not applied** (value at L1 / L5 / L10, all percentages):

| Stat key | Granted by | L1 / L5 / L10 |
|---|---|---|
| `burning_damage` | fire_magic | 5.0 / 75.0 / 130.0 |
| `buy_discount` | trade | 5.0 / 35.0 / 60.0 |
| `charm_effectiveness` | persuasion | 5.0 / 75.0 / 130.0 |
| `consumable_power` | alchemy | 10.0 / 75.0 / 130.0 |
| `crafting_quality` | smithing | 10.0 / 75.0 / 130.0 |
| `crafting_yield` | alchemy | 10.0 / 50.0 / 75.0 |
| `effect_duration` | enchantment | 5.0 / 45.0 / 75.0 |
| `healing_effectiveness_(party)` | medicine | 10.0 / 75.0 / 130.0 |
| `loot_quality` | thievery | 5.0 / 45.0 / 75.0 |
| `luck_modifier` | comedy | 5.0 / 25.0 / 50.0 |
| `magic_damage_resistance` | yoga | 5.0 / 50.0 / 75.0 |
| `max_companions` | leadership | 1.0 / 5.0 / 5.0 |
| `mental_resistance` | yoga | 5.0 / 75.0 / 125.0 |
| `morale_effects` | leadership / performance | 5.0 / 50.0 / 100.0 |
| `movement_speed` | grace | 10.0 / 40.0 / 65.0 |
| `party_skill_checks` | learning | 1.0 / 5.0 / 10.0 |
| `party_xp_gain` | learning | 3.0 / 15.0 / 42.0 |
| `poison/disease_resistance_(party)` | medicine | 10.0 / 50.0 / 75.0 |
| `repair_efficiency` | smithing | 10.0 / 60.0 / 85.0 |
| `sell_markup` | trade | 5.0 / 45.0 / 70.0 |
| `social_roll_success` | performance | 5.0 / 50.0 / 75.0 |
| `status_effect_chance` | ritual | 5.0 / 50.0 / 75.0 |
| `summon_hp` | summoning | 10.0 / 60.0 / 85.0 |
| `supply_duration_(party)` | logistics | 10.0 / 60.0 / 85.0 |
| `trading_price` | persuasion | 5.0 / 25.0 / 50.0 |
| `trap_detection` | thievery | 10.0 / 60.0 / 85.0 |
| `travel_speed_(party)` | logistics | 5.0 / 35.0 / 60.0 |

Each needs a target system and a balance decision, which is why this is not a
mechanical fix:

- **Shops** (`buy_discount`, `sell_markup`, `trading_price`) — fold into
  `ShopSystem.get_price_modifier_summary()`. Trade 10 currently reads 60% off /
  70% markup, which may be intended as a soft cap rather than literal.
- **Overworld** (`travel_speed_(party)`, `supply_duration_(party)`) — party
  speed and per-step food cost in `overworld.gd`.
- **Loot** (`loot_quality`) — `CombatManager._get_modified_rarity_weights()`
  already takes Luck; add the Thievery term.
- **XP / checks** (`party_xp_gain`, `party_skill_checks`) —
  `CompanionSystem.apply_party_xp()` and `EventManager._resolve_roll_dc()`.
- **Combat** (`summon_hp`, `burning_damage`, `status_effect_chance`,
  `effect_duration`, `mental_resistance`, `magic_damage_resistance`) — summon
  spawn, DoT tick, status apply chance, status duration, resistance lookup.
- **Camp / crafting** (`crafting_quality`, `crafting_yield`,
  `repair_efficiency`, `consumable_power`) — the camp activity handlers.
- **Party** (`max_companions`) — no party-size cap exists yet.
- **Social** (`charm_effectiveness`, `social_roll_success`, `morale_effects`,
  `luck_modifier`) — event roll resolution.
- **Medicine, party-wide** (`healing_effectiveness_(party)`,
  `poison/disease_resistance_(party)`) — rest healing and wound escalation.

Cheapest and most visible first: shops, overworld, loot.

Two keys also use display-style names (`healing_effectiveness_(party)`,
`poison/disease_resistance_(party)`) that should become plain snake_case when
they are wired.

---

# Part IV — What got done

Condensed changelog. Full checklists in git at `73a948c`.

## 2026-09-12 — documentation cleanup

Nine documents removed. Each was describing a state the project had left, which
is worse than having no document — `PERK_WIRING_PLAN.md`'s wrong status quo cost
a full session's first hour before it was checked against the code.

| Removed | Why |
|---|---|
| `HELL_EVENTS.md` | Headed "Source of truth for hell_events.json" while holding **50 of 79** events, and not wired to `import_review_docs.py`. `docs/review/EVENTS_HELL.md` is the real source. |
| `HG_EVENTS.md` | Same header, **14 of 150** events. Editing it and asking for a sync would have put 136 events at risk. |
| `PROJECT_ANALYSIS.md` | A point-in-time March audit ("14 autoloads"); superseded by this file. |
| `REFRESHER.md` | Orientation doc; its current state moved to `README.md` and its "point of departure" to "Where to pick up" above. |
| `EVENT_SYSTEM.md` | January; duplicated `CLAUDE.md`'s description of grey/blue/yellow choices. |
| `EDIT_LATER.md` | One live item (prose wants Olaf's pass), folded into "Where to pick up". |
| `docs/plans/STATUS_EFFECTS_PLAN.md` | Opens "Critical Bug: Status Definitions Never Load". False — 168 load and 158 of 181 effect strings are handled. |
| `docs/plans/2026-03-01-companions-*.md` (4) | Completed plans; the system shipped. Specs now live in `docs/superpowers/specs/`. |
| `docs/plans/2026-03-02-recruitment-*.md` (2) | Same. |

Kept at the time (PERKS.md, CHARACTERS.md and docs/review/ since retired for CONTENT.md): `PERKS.md` and `CHARACTERS.md` (hand-maintained design sources),
`docs/review/` (round-trips to JSON), `docs/plans/PERK_WIRING_PLAN.md`
(corrected and current), `CLAUDE.md` (agent working agreement).

`README.md` rewritten from the live boot output rather than from the previous
README, which claimed Godot 4.3 and 12 autoloads against a real 4.7.2 and 21.

## 2026-09-11 — verify_enemy_xp made deterministic; two bugs it was hiding

**The flaky kit-budget check is fixed at the root.** It asserted
`spent > budget * 6 + 400` over procedurally generated gear and failed about
one run in ten with no code change. The cause is that item value is
*multiplicative* — `base x material.value_mult x quality.value_mult`, where
material spans 0.25 (`hide`) to 15.0 (`vajra`) and quality 0.5 to 3.0
(`masterwork`). The same base weapon therefore spans a 120x range with a long
thin tail, and a 45x vajra-masterwork roll produces a ~2565-gold weapon. The
kit budget picks a *rarity band*; it was never a spend cap, so a fixed linear
threshold sat inside that tail and the assertion turned on the dice.

Three changes: the suite seeds the RNG (`RNG_SEED`), so a failure is
reproducible and bisectable instead of meaning "run it again"; the magic 400 is
replaced by `ItemSystem.get_equipment_tables()`-derived arithmetic — the
dearest base times the dearest material times the dearest quality, currently
4500 — so the allowance follows the data instead of going stale; and a new
aggregate assertion (`total gear <= 2x total budget`, currently 1.16x) carries
the real weight, since one lucky roll cannot move it but budget ceasing to
influence gear would. Both assertions were negative-tested.

**Seeding immediately surfaced a real bug: seven backgrounds granted no
starting spells.** `apply_background_skills()` passed every `starting_spells`
entry straight to `learn_spell(character, spell_id: String)`, but 10 of the 12
entries in `races.json` are `{school, level, count}` specs, not ids. Each raised
a type error that aborted the rest of the function. The birth path twenty lines
above already handled both shapes correctly via `_pick_random_spell()`; the
background path had never been updated. palace_vizier, tide_seer,
boundary_walker, network_node and flame_seeker now learn their spells.

## 2026-09-09/10 — perk wiring: actives, the AoE resolver, and the passive engine

Five commits on `claude/perk-wiring-active`, working through
`docs/plans/PERK_WIRING_PLAN.md`. That plan's "status quo" turned out to be
wrong in both directions and is corrected in place; the counts below are the
real ones.

**Active perks got the data their resolvers were waiting for.**
`combat_manager.gd` had accumulated 32 `_resolve_*` handlers dispatched from
`use_active_skill`, but **no perk in perks.json had ever carried the
`combat_data` they read** — not at HEAD, not in any earlier revision of the
file. Since `combat_arena.gd` greys out any non-mantra skill with empty
`combat_data`, all 109 "Active." perks were unclickable and the resolvers had
never once run. 75 are now wired; 7 overworld ones are flagged `non_combat` and
filtered out of the combat panel; `host_of_the_winds` is reclassified passive
(it describes summons that are active, and only reached the panel because the
panel matches on the "Active" prefix); 26 remain, listed in Part I §10.

**Active skills now use the shared AoE resolver.** `aoe_resolver.gd` already had
ten shapes and `cast_spell` routed through it, but the four active-skill AoE
resolvers each hand-rolled `_grid_distance(...) <= aoe_radius`, so every skill
area was a circle whatever the perk said. `_units_in_skill_aoe()` is the single
entry point now, falling back to `aoe_radius` as a circle so genuine bursts are
untouched. New `arc` shape (full width at every step, where `cone` tapers to a
tip): `size 1, width 3` is the three tiles in front of the attacker, `size 2`
reaches spear range. red_harvest and sweeping_strike use it, impaling_strike
uses `line`. Skill hover previews draw the silhouette.

**`CombatStats` is now the one vocabulary** for stat and targeting names
(`MODIFIABLE`, `DERIVED`, `DATA_KEYWORDS`, `TARGETING`), each entry annotated
with what consumes it. `_apply_stat_modifier()` refuses an unmodifiable stat
with a `push_error` instead of storing it. Both perk tools read these lists
rather than restating them.

**The passive effects engine is built** — steps 3-7 of the plan. PerkSystem
carries the query layer; `update_derived_stats()` folds in flat bonuses then
conversions (in that order, since a conversion reads a finished stat);
`CombatUnit._get_conditional_perk_bonus()` evaluates gated effects where the
stat is read; `CombatManager._fire_perk_triggers()` dispatches `on_hit`,
`on_crit`, `on_kill` and `dodge_success`. Only 5 perks are wired to it so far —
see Part I §13.

**Six things were being computed and never read.** Same failure each time: a
value written under one name and read under another, or not read at all, with
`.get(key, default)` quietly covering the gap.

| What | Was |
|---|---|
| `combat_arena.gd` | Would not parse. `8eeffe5` deleted `var ratio` from `_show_victory_screen` and left four uses fifty lines below — **the combat scene had failed to load since 2026-09-03**. |
| `save_bonus` | Booster Shot wrote it from the day it shipped; nothing read it. The perk did nothing. Now read by `_perform_save_roll()`. |
| `mental_resistance_pct`, `healing_pct`, `damage_pct` | Computed by `get_affinity_bonuses()` and never folded into `derived`. Space, water and fire affinity paid out nothing for mental resistance, healing or damage. |
| `damage_reduction_pct` | Folded into `derived` but never read in combat, so the Armor skill's damage reduction did nothing. Now read by `apply_damage()`. |
| Skill stamina cost | The button parsed it by regex from the description while `use_active_skill` charged `combat_data.stamina_cost`. The regex misses "(once per combat, 8 Stamina)", so One Inch advertised itself as free, passed the affordability check, then drained 8. |
| Revive targeting | `single_ally` filters on `is_alive()`, false for exactly the bleeding-out ally a revive exists for. New `downed_ally` mode. |

**New tooling.** `tools/wire_active_perks.py` and `tools/wire_passive_perks.py`
own the data and regenerate `perks.json`; `tools/verify_active_perks.tscn` and
`tools/verify_passive_perks.tscn` check the result against the **live**
autoloads, which `validate_data.py` structurally cannot — it parses JSON in
Python and never exercises a GDScript loader. Both verifiers were negative-
tested: deliberately breaking a value, an AoE shape name, a stat vocabulary
entry and the double-wiring rule each trips them.

## 2026-07-27 — post-break audit and follow-up passes

**Audit and bug fixes.** Animal and domain enemy files were never loaded;
combat realm was always "hell"; event `difficulty` was dead data; `item_random`
rewards gave nothing across 49 outcomes; all 47 companions had lost their trait
lists in a merge; the deleted QuirkSystem was still referenced (so quirk crisis
reactions never ran); boss gating was fiction (`requires_boss_defeated` never
checked, `defeat_boss()` never called); the HG realm boss event didn't exist
though the map referenced it; ~130 broken data references. Roll choices can now
carry skill/attribute gates ("gated gamble").

**UI debt and half-wired mechanics.** WOUNDS & BODY and STATE OF MIND panels in
the character sheet; `cone_forward` locked to caster facing with a cone
silhouette preview; per-arm chain results in the combat log; paid wound healing
at 12 shops; Riposte, Reflect, Magic_Mirror, Mirror_Images, Taunt, Karmic_Bond,
Eternal_Vow, Mantric_Armor, Ancestors_Blessing, Swarmed, Lured and Constitution
statuses wired; four AI behaviour types (`erratic_movement`, `priority_target`,
`pack_bonus`, `burrow_emerge`); summoning terrain affinity; Coordinated Strikes;
Cloud Gate; Set Snares and Craft Charm camp activities; location-specific camp
suppression and enhancement. Two entries turned out **stale, not missing** —
elemental terrain spellpower modifiers and Yoga-boosted rest decay were already
implemented.

**Animal realm content.** All 47 missing zone events written (the map referenced
84 markers and only 37 existed). Hungry ghost's 34 map-placed gaps written too.
All three content realms now at 0% dead map weight. 24 animal companions added
covering all 17 animal births; every companion gained a `realm` field. Found
along the way: animal shops offered the hell devil roster verbatim; 4
backgrounds granted a nonexistent `crafting` skill; 8 background starting items
used pre-rename ids, so several animal backgrounds started you with no weapon.

**Quests, recruitment, prosthetics.** All three quests were unfinishable — the
board handed them out and no event ever set their step flags. Six hell events
written to close the chains. 9 bespoke HG recruitment events. 12 prosthetics
plus the two missing code links (nothing wrote `body_plan.prosthetics`, and the
penalty maths ignored it).

**Perks.** Two dead trees fixed (18 perks keyed to a nonexistent `crafting`
skill; akimbo/coordinated_strikes keyed to a nonexistent skill, now
attribute-gated). 28 level-10 capstones added. 94 perks redistributed off the
old odd-only tiers plus 9 new, giving every skill a perk at every level 1–10.
PERKS.md synced: 81 `Requires` lines rewritten, 47 undocumented perks recorded.

**Gold rewards.** 30 outcomes promised gold and paid none — 24 used descriptive
tokens against a handler doing `int()` (0 in GDScript for a non-numeric string),
6 used a `gold_reward` key nothing read, including every Bone Arena payout.
Fixed with `_resolve_gold_reward()` and a rename to the canonical `gold`.

**Trait matrix pass.** Every trait and race pressure link was re-seated on the
psychology matrix, correcting two things at once. **Sign:** the code runs −100
klesha to +100 wisdom and four call sites follow it, but traits.json and
races.json were authored as "positive = more of this affliction", so the
baseline decay pulls toward pointed at the wrong pole — `grief_struck` carried
water +20 while "Grief-struck" is itself the water dark major label, and
`brave` decayed toward fear. **Element:** anger was filed on fire (fire is
craving; aversion is water) and paranoia on space ("Paranoid" is the air major
dark label). 36 traits re-seated by hand rather than sign-flipped, since
`oath_breaker` and `addiction`'s earth term were already right; 3 races
rebased; 12 traits added to fill the thin cells; 15 traits that had no
psychology link at all gained an obvious one. The crisis-reaction table
followed: four entries moved to the element their trait now sits on, and the
12 new traits brought the bright pole from 2 authored reactions to 12.

**Events x traits sweep.** Four parts, one per realm plus a pass for the plain
traits the first three skipped: 201 trait-gated choices over 77 of the 84
gameplay traits, 76 acquisitions over 30, across 152 events. Physical
hindrances are used as hindrances — clubfooted goes down on the frozen cave
ice, hard_of_hearing catches one word in four in the demon marketplace — since
that is the only way those traits can be felt.

**Trait gate balance.** The sweep was written for flavour and not costed:
gates paid a median 25 XP against 12 elsewhere while costing nothing to
unlock, and 124 of 201 outpaid every other choice in their own event. Rescaled
by how often a party holds the trait (8/12/15/20), with a premium for risk and
a dominance cap for common traits only. Dominance on commonly-held traits is
now 4 of 25, and gates contribute ~3.8% of all event XP. `tools/rebalance_trait_gates.py`
re-runs the whole analysis.

**Behavioural traits were unobtainable.** Nothing granted one to anybody —
creation rolled physical and personality only, and 25 of 31 are on no
companion — so 110 of the 201 new gates could never fire. Creation now rolls
one trait from each of the three layers: body, temperament, habits.

**Behavioural and acquired traits.** 32 new traits: the CK-flavoured
behavioural kind that two characters can bond over or that sets off an event by
itself, and acquired traits that record what a run did to someone. Constant
effects stay neutral by design — most carry no stat modifiers and work through
`event_tags`. Bond tags and symmetric opposed pairs added across all 84
gameplay traits.

**RelationshipSystem.** One number per unordered pair: a trait-derived baseline
recomputed on read, plus stored drift from shared danger and shared rest. Bands
rival/cool/neutral/warm/sworn, shown in the Party tab with the reasons in the
tooltip. Cleared on death, reincarnation and dismissal.

**Nine acquisition hooks** on existing code paths, plus three losses, and
`trigger: "trait"` / `trigger: "relationship"` events with eleven written.

**Eight broken roll choices found by the new validator checks**, all in content
written earlier the same day: three camp events and five animal events put the
roll on the choice instead of in `requirements` and named the failure branch
`failure_outcome`, so the roll never happened and the failure prose was
unreachable. Five of them had no failure branch at all; those were written.

**Validator** (`tools/validate_data.py`) now covers: events → encounters, shops,
items, spells, traits, skills, wounds, karma realms; map configs → events, mobs,
pickups; shops → items, spells, companions; companions → births, backgrounds,
items, spells, traits; races and backgrounds → skills, traits, equipment;
encounters → archetypes; code → perk ids and status names; quest step flags must
be settable by some event; choice `prerequisite` flags must be reachable; reward
keys must have a handler; gold tokens must resolve. An earlier ad-hoc version
had a blind spot that hid **every** map→event reference in the game
(`object_pools[zone]` is a dict keyed `events`/`pickups`, not a list) — if you
write a checker, check its negatives.

## Earlier work (2026-04 → 2026-05)

- **Psychology system** Layers 1–2: five elemental pressure meters, status
  thresholds, autonomous crisis events, trait crisis reactions, rest decay,
  character-sheet panel
- **Trait system**: 63 traits replacing the old QuirkSystem, applied as
  attribute/skill/pressure modifiers
- **Indo-Tibetan weapons and armour overhaul**: sword types (Khanda, Talwar,
  Dao, Patisa), mace/bow renames, Katar, Bichawa, Kukri, Trishula, Urumi,
  Chakram, Chuba, Lamellar, monastic robes — with the mechanics wired
  (`on_crit_status`, `parry_effectiveness`, `pass_through`, Urumi sweep)
- **Ritual implements**: 210 items (6 implements × 8 materials × 5 consecration
  tiers) generated by `tools/generate_implements.py`, with Rhythm Charge, Chöd
  Offering, Throw Phurba, khatvanga initiative aura and the dorje+drilbu set
  bonus; ritual garb generated the same way
- **Rest and time**: hours-based clock, three rest tiers, food only at rest,
  temp HP, 28-day lunar calendar with full/new moon and per-weekday school
  bonuses
- **Camp system**: two-stage rest (tier → activities), CampSystem autoload, ~20
  activities, disturbance rolls, safe camps, 9 camp events
- **Wounds and diseases**: WoundSystem with 5 base types + 5 escalated forms,
  escalation on untreated rests, Field Surgery, combat and event application,
  stat penalties
- **Body plans**: BodySystem with dynamic per-species topology, limb loss with
  cascade and unequip, natural weapons (locked and unlocked), multi-arm attack
  chain governed by Finesse, extra leg pairs, prosthetics
- **Combat**: AoEResolver as the single source of truth for 10 AoE shapes,
  projectile deviation and friendly fire, spell duration unification, obstacle
  variety, terrain effects, AI using items and active skills, enemy physical
  resistances
- **Items**: procedural weapons/armor/talismans, equipment traits, 40
  magic-school charms, 17 scrolls, alchemy crafting with a UI tab
- **Save/load**: 3 slots plus autosave

## Confirmed complete (previously suspected missing)

- Psychology Layer 3 crisis/valve mechanic — implemented in
  `psychology_system.gd` (the *intervention* mechanic is the open part)
- Wound/disease application on crits — wired in `combat_manager.gd`
- Background system — all fields applied; no `abilities` field exists in data
- Spell outcomes — all 6 types handled; every reward key has a handler
- Summoning school — mechanically complete
- `race` → `birth` rename in scene nodes — already done; no `race_label` /
  `RaceValue` references remain
- Red/yellow devil racial bonuses (`better_starting_weapon`,
  `extra_starting_gold`) — now real traits granted at creation and read by
  `character_system.gd`
- Legendary equipment tier — 68 legendary-rarity items exist
- Out-of-combat spellcasting — the spellbook Cast button already existed;
  `cloud_gate` was added on top of it
