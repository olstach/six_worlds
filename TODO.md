# Six Worlds — TODO

**Last updated:** 2026-09-18

The open list. Organised as: **what to do next → what is still open → designs
waiting to be built → what got done**. The full historical checklists (every
`[x]` line from the psychology, weapons, camp, wounds and body-plan passes) are
preserved in git at commit `73a948c`.

`README.md` holds the current state of the project — realm coverage, content
totals, how to run and verify it. It is not repeated here, because this file
kept a second copy of those numbers and they drifted. One place for facts — and
the facts drift there too, so they are counted from the data rather than carried
forward: the 2026-09-18 pass found five of nine wrong.

Companion documents:
- `WRITING.md` — everything that wants Olaf's voice, in one list
- `PERKS.md` — perk trees per skill, hand-maintained
- `CHARACTERS.md` — companion bios, hand-maintained
- `docs/review/` — all realm prose; round-trips to JSON via
  `tools/import_review_docs.py`
- `docs/superpowers/specs/` — designs approved but not yet built
- `tools/verify_all.sh` — run after any edit

---

## Where to pick up

**A hell → hungry ghost → animal playthrough.** All three realms are populated
and none of the recent content has been played; the animal realm has never been
played at all. Progression is genuinely gated now (boss seal enforced, boss
events exist), and a large batch of mechanics went from data-only to live
without anyone seeing them move. Use the cheat console to skip ahead.

Worth watching for specifically:

- **First-pass balance numbers** — summoning terrain +25%, pack bonus,
  shield/mirror-image pools, reflect chances, wound-healing prices. All guessed,
  none played.
- **Difficulty multipliers** (easy 0.75× … boss 1.6×) now apply to every event
  fight for the first time.
- **The wounds and psychology panels** — first look at whether those systems are
  tuned sanely now that they are visible.
- **Active perks.** 75 of them became usable in 2026-09; before that every one
  was greyed out, so none has ever been pressed in a real fight.

Then, depending on appetite:

- **Content:** more quests (the board works but holds three, all hell),
  `PERKS.md`'s empty tiers, cursed items.
- **Systems:** the three approved combat designs below, prosthetic items
  (small, unblocks a fully-coded flow), or combat-UI polish (wound icons,
  per-arm damage popups).
- **Big swing:** YidamSystem — the design in Part II is complete enough to
  build, mantra counts already accumulate, and camp Mantra Recitation feeds it
  with nothing reading the result.

- [ ] **All recent prose is Claude's and wants Olaf's pass.** The three hungry
      ghost map-critical events (boss + both pass guardians), the 34 further HG
      events, the 47 animal zone events, and the animal companion bios — **52 of
      them, not 24**; the birth-by-birth pass doubled the roster and this line
      was not updated.

      They are **not** currently marked **NEW EVENT** / **NEW** in
      `docs/review/`: the markers need a base snapshot, none is configured, and
      each document says so in its own header. The content batches also predate
      this repository's visible history, so git cannot separate them either. Set
      `REVIEW_BASE_SNAPSHOT` and re-export to turn them back on.

      The whole writing list now lives in **`WRITING.md`**, compiled 2026-09-18
      and checked against the data — including the three items that turned out
      not to need writing at all.

---

## Mechanics, in the order they are worth doing (2026-09-18)

Olaf is chipping away at the writing (`WRITING.md`) and wants mechanics
meanwhile. Nearly every item below is already written up somewhere in this file;
this is the ordering and the reason, which was not.

1. **The perk engine's missing half** (§13) — *started 2026-09-18.* Bounded,
   testable without a playthrough, and it converts a large chunk of the 324
   description-only passives from blocked into data entry. Triggers and
   conditions are done; **payloads are the real bottleneck** — see §13.
2. **Mob behaviour as a system** (§11) — the largest gap in the game. The AI
   knows nothing about auras, zones, terrain, height or repositioning, so every
   one of them is a player-side advantage. Best done *after* a playthrough,
   because the right rules are the ones the fights turn out to want.
3. **Aura and zone UI** (§3) — a player standing in a healing field has no
   indication of where it comes from or how far it reaches, and most auras are
   not statuses so the status bar will not show them. Working systems, invisible.
4. **The small self-contained ones** (§1) — `sever_part` ignoring `arm_l2`/
   `arm_r2`, the `skeleton_king_duel` win condition wanting a re-check after the
   combat refactors, `tactical_assessment` having no code, racial resistances
   being empty on all 47 births, prosthetics.
5. **Decisions that block work rather than work itself** (§11, §12) — whether
   traps are a combat or an overworld feature, whether `attribute_caps` is
   implemented or deleted, whether spell learning costs XP, what
   `crafting_quality_pct` attaches to, and whether best-member party bonuses
   want a diminishing tail.
6. **YidamSystem** (Part II) — the big swing, and the design is complete.
   `mantra_count` already accumulates and camp Mantra Recitation already feeds
   it with nothing reading the result.

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
- [ ] **`sever_part` doesn't handle `arm_l2`/`arm_r2`** — four-armed species have
  equip slots `hand_l2`/`hand_r2` but no `weapon_main2`/`weapon_off2`, so
  severing an extra arm doesn't drop its weapon.
- [ ] **`extra_arm_results` isn't shown in the combat UI** — the multi-arm chain
  writes per-arm hit/damage into the result dict and the combat log prints it,
  but the unit frames don't (no "Arm 2: 12 dmg" popup).
- [ ] **Combat-UI wound icons** — wounds render in the character sheet; unit
  frames need sprite work.
- [ ] **No race defines any resistance at all.** All 47 carry
  `"resistances": {}`, so `base_resistances` on a character is always empty and
  the skeleton's 50% physical reduction this item used to cite does not exist.
  Racial resistance is a designed-in field that was never filled.

  The original concern still stands underneath it: `EnemySystem._build_enemy()`
  copies only the archetype's own `resistances`, so if races are ever given
  some, an archetype-defined skeleton still will not inherit them. Enemies now
  roll a real birth and apply its modifiers, which makes the inconsistency
  easier to fix and more obviously wrong to leave.
- [ ] **Projectile sprites** — arrows/bolts/firebombs are a `Line2D` flash.
- [ ] **Tooltips** — `item_tooltip.gd` covers items; status effects, terrain
  tiles and turn-order icons have none.
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

- The twenty legacy effect strings live in `Resistance.LEGACY_EFFECTS` rather
  than in the statuses that use them. The table exists so that migrating them
  to the structured `grants_resistance` they should always have used is a DATA
  change with nothing to rewrite in code. Worth doing on the next pass through
  statuses.json.
- `ranged` resistance (Silk armour, +10) is a resistance to how the damage
  arrived rather than to what it was. `Air_Shield`'s `ranged_damage_reduction`
  is the same axis and IS read; the armour-material version is not. Wiring it
  means reading it in the attack path, next to that one.
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
- [x] ~~**Needs a proc site, not a consumer** (4 keys)~~ — all four are wired
      (confirmed 2026-09-18, this entry was never ticked). `stun_chance_pct` at
      `combat_manager.gd:9845`, `burning_damage_pct` on the fire DoT tick at
      `:5199`, `status_effect_chance_pct` in `effective_status_chance()` at
      `:7377`. `luck_pct` is the interesting one: rather than becoming a number
      of its own it feeds **crit chance and loot chance**, which is what Comedy's
      luck was always describing.
- [x] ~~**`effect_duration_pct` is a DUPLICATE, not a gap**~~ — settled. The
      duplicate was deleted and the table is the truth: Enchantment's
      contribution comes from `effect_duration_turns`, read in
      `_calculate_status_duration`, and the parallel `_pct` key is gone. The
      rule is no longer restated in code.

**So one `base_bonuses` key is left without a consumer: `crafting_quality_pct`**,
and for the reason already recorded — camp crafting has no quality concept to
attach to. `tools/vocabulary_baseline.json` listed four until 2026-09-18; the
other three had been wired on 09-16 and the baseline was never shrunk, which is
the same drift in the file that exists to catch drift.
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

- [ ] **`skeleton_king_duel`** stops at 10% HP — verify the special win
  condition still fires after the combat refactors.

## 7. Content that wants writing

- [ ] **A prose pass on 81 events and 52 companion bios.** The animal realm's 47
  zone events, hungry ghost's 34 gap-fill events, the three HG boss/pass-guardian
  events, and all **52** animal companion bios (the count was 24 before the
  birth-by-birth pass) are Claude's prose, not yours. This is the single biggest
  content item and only you can do it. Broken out with the roster in
  **`WRITING.md`**.
- [x] ~~**53 events are grey-only**~~ — **a miscount of the task, not of the
  events** (checked 2026-09-18). The 53 are real, but **52 of them are
  storefronts**: teahouses, town shops, mercenary guilds, training camps,
  peddlers and landmark temples, whose two grey choices are "browse wares"
  (outcome `shop`) and "leave" (outcome `text`). That is correct for a
  re-enterable location, and `docs/review/README.md` already says so about the
  same set. The only genuine narrative event among them is `hg_sigh_of_relief`,
  a deliberate one-beat toast — a cairn with a folded cloth, +15% HP and mana,
  `touched_by_grace`. There is no ≥2-checks gap to close.
- [ ] **500 of 605 perks have empty `flavor`.** Better in your voice than mine.
  Counts per skill are in `WRITING.md`; the heaviest are the 36 cross-perks and
  performance's 19.
- [ ] **Quests: 3 total, all hell.** The board works and the validator now
  guarantees every step flag is settable, but hungry ghost and animal have none.
- [ ] **Hell event chains still unwritten** from the original list: soul caravan
  ambush, devil deserter, contraband deal, corrupted simple, chained pilgrim,
  rival party.
- [x] ~~**Realm-specific wounds** — 5 base types exist; target ~8–10~~ —
  **there are 17** (`WOUND_TYPES` in `wound_system.gd`), and they include every
  one this item asked for: `barbed_wound` (the arrow wound), `poisoned_blood`
  and `venom_shock`, `spiritual_corruption`, `marrow_chill` and `burn` for hell,
  plus `bone_fever`, `brain_fever`, `death_rot`, `psychic_miasma` and
  `rot_sickness`. Overshot the target and was never ticked off. What is still
  open is a *balance* question, and it is already in §9: whether diseases should
  share the physical wound table by `body_location`.
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

**Need economy/social systems:** `investment` / `trade_empire` (passive income),
`supply_cache` / `extended_march` (supply action), `guided_practice` /
`the_lineage_continues` (companion spell-teaching), `black_market_contacts` /
`fence` (black-market tier), `patron_of_the_arts` (renown).

~~**Wound/body perks designed, not written:**~~ **all four are built**
(confirmed 2026-09-18; this entry was stale). `hardened` negates a crit wound at
`combat_manager.gd:9510`, `undead_hunter` blocks the disease at `:9148`,
`stubborn_body` adds its rest at `wound_system.gd:372`, and `iron_cortex`
guarantees the second arm at `:1934`.

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

### The overworld perks: five built, two waiting on economy (2026-09-17)

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

**The two left are economy, and each wants a system rather than a wiring.**

- [ ] **`investment`** (Trade 4) — "Invest gold in a settlement. Returns 150%
      of the invested amount after several in-game days." Needs a store of
      outstanding investments (settlement, amount, due day) and a day-boundary
      hook to mature them. TimeSystem already advances days and the lunar
      calendar already listens to it, so the hook exists; what does not is
      anywhere to keep a debt. Smallest honest version: `GameState.investments`
      as an array, matured on the day tick, paid into gold with a toast. The
      interesting question is what happens when the settlement is in a realm
      the party has left — which the two-way portals make a real case rather
      than a hypothetical.
- [ ] **`supply_and_demand`** (Trade 5) — "Check available trade goods between
      known settlements. Buying low and selling high grants triple the normal
      gold difference." Needs a trade-goods model: per-settlement prices that
      differ, and a notion of carrying goods between them. ShopSystem has 91
      shops with modifiers but no goods that have a price *somewhere else*.
      This is the biggest of the seven by a distance and is really a feature —
      a caravan game inside the travel game. Worth doing only if travel is
      meant to carry that weight; otherwise the perk should be rewritten to
      something Trade can already do.

## 11. Things to ponder

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
      nerfing.** The cap is 3 free, 6 at Leadership 9. The reason it is that low:
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

- [ ] **Ritual implement coding is declared but not yet player-facing.** The
      tables now say copper serves fire and the phurba serves sorcery, and the
      verifier enforces it — but a tooltip still shows a Copper Phurba without
      explaining that it is the instrument for a fireball. Reading
      `ritual_metals` and `ritual_implements` into the item tooltip is the step
      that makes the system legible to the player rather than only to us.

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

- **The naming lore is half-wired now (2026-09-18).**
  `animal_realm_names.json` had no reader at all; its **155 personal names** are
  one now — `CharacterSystem.generate_character_name()` gives every animal-realm
  birth its own names, where the generator previously drew a whole realm from a
  six-word list, so a naga and an uluka were named off the same handful.

  **Still unread: 128 place names and 88 parent wishes.** (The "389" this item
  used to claim was the three categories added up loosely; the real total is
  371.) The place names are the half that wants content rather than wiring. The rakshasa
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

- [x] ~~**Equipment should be generated like the XP pool.**~~ — **mostly built
  already, and finished 2026-09-18.** The claim below (that `_generate_equipment`
  reads only `archetype.equipment_template.weapon.type`) had stopped being true:
  `_weapon_types_for_skills` picks the weapon off the best trained weapon skill,
  `_tool_for_character` puts a trade's tool in the hand when the trade outweighs
  the weapon, `_generate_skill_consumables` and `_generate_everyday_items` fill
  the pack from the skills, a second weapon set appears when a second weapon
  skill is genuinely trained, and leftover budget buys a talisman.

  **Armour was the one slot still reading only the archetype**, so a character
  that came out of the XP spread with armor 5 could be sent in bare because its
  template said "none". `_armor_category_for()` now takes the heavier of the
  skill's category (light 1+, medium 3+, heavy 6+) and the template's — the
  template is a floor rather than an authority, so a temple guard's "heavy"
  survives a low armour roll while a caster's "none" does not survive the
  character actually training to wear armour.

  Not done, and not invented: **attributes still play no part in armour.**
  Gating heavy armour on Strength would be a rule the player's own character
  does not obey, so it wants deciding for both or neither.

  The original list, marked up against what is actually built:
  - [x] a **total equipment value that scales with the character's XP** —
    `equipment_budget_for_xp()`
  - [x] **types chosen from the dominant skillsets** — weapon, tool, armour and
    consumables all read the skills now
  - [x] **two weapon sets** where the gold and the skills make it reasonable —
    a spare at xp ≥ 600 with a second weapon skill at 3+
  - [x] beyond the vital kit, **food and other resources** —
    `_generate_everyday_items`
  - [ ] **a Performance build carries an instrument** — the one part still
    missing, and not for want of wiring: no instrument exists as an item. See
    the separate item below.

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

- [x] ~~**Background assignment wants a pass across all births**~~ — **the
  premise was wrong, and the fix shipped 2026-09-18.**

  The item asked for a pass over every birth's `typical_backgrounds`. That
  field was read by no game script: character creation called
  `KarmaSystem.select_random_background()`, which iterated the *backgrounds*
  table and read `available_races`, treating an empty list as universal. So the
  field that reads as authorial intent was documentation, and the one that
  decided anything was on the other side of the relation. Across the 47 births
  the two disagreed 1,525 times, and three ids the births named — `beggar`
  (yidag), `sorcerer` and `courtier` (skeleton_copper) — were not defined
  anywhere, harmless only because nothing read them.

  **Both declarations count now.** `get_background_pools()` splits what a birth
  may be born into: *its own* (named by `typical_backgrounds`, or whitelisting
  it through `available_races`) and *universal* (an empty `available_races` and
  unclaimed). A background the birth names is its own even when it is also
  universal — the claim is the point of the field.

  **And the roll is split, not pooled.** Weight alone could not fix this: the
  universal pool is 33 backgrounds and 169 weight against a typical birth's
  five and 24, so a red devil came out devil-flavoured 12% of the time and a
  yidag, which had none of its own, never. `BIRTH_SPECIFIC_BACKGROUND_CHANCE`
  (0.5) decides the split first and weight decides within the pool, which moves
  every birth in a built realm to ~50% and makes the frequency a number someone
  chose. A birth with none of its own is unaffected.

  The three undefined backgrounds are written rather than deleted — **their
  descriptions are placeholders and want Olaf's voice** (in `WRITING.md`).
  `validate_data.py` now checks `typical_backgrounds` against the backgrounds
  table; it only ever checked the other direction, which is how three unknown
  ids survived.

  - [x] ~~**A new game hardcodes its character**~~ — **fixed 2026-09-18**,
    confirmed as a relic of an early build. `save_manager.gd` called
    `create_player_character("Karma Dorje", "human", "wanderer")`: a fixed
    birth and background bypassing both rolls, naming a birth from a realm with
    no content whose `reincarnation_weight` is 0 — so the one character every
    player was guaranteed to meet was the one birth reincarnation could never
    produce. It now rolls birth, background and name off `GameState.current_world`
    like every later life.

    **This changes the opening of the game.** A new run starts as one of the six
    devils rather than as a human, and about half the time with a
    hell-flavoured background. Modelled over 20k new games the spread is wide —
    the most common single character is a blue devil warrior at 2.5% — but the
    first thing to check on a playthrough is whether hell reads right when the
    player IS a devil. Several events were written assuming otherwise.
  - **Four births still have no backgrounds of their own** — `gandharva`,
    `apsara`, `planetary_deity` and `trader`, all in unbuilt realms. They fall
    back to the universal pool safely.

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

The engine is built and proven; the data is barely started. Of **471** passive
perks (recounted 2026-09-18): **140** are implemented by hand in `scripts/`
(checked by id with `PerkSystem.has_perk()` at the moment they matter), **7**
more are implemented through data the engine resolves generically — 5 carrying
an `effects` array, plus `immune_system` and `avatar_of_the_storm` through
`aura`, and `sure_step` through `grants_movement_ability` — and **324** are
still description-only.

**That is 27 more than the 297 this entry used to claim, and the number never
went the other way.** `tools/wire_passive_perks.py` computed it as
`passive_total − hardcoded − wired`, where `hardcoded` was every perk id
appearing in `scripts/` — **including 34 active and mantra perks that are not
passives at all**, so they were subtracted from a total they were never in. The
tool's own summary line was the source, so the figure was wrong in the tool and
in this file at once. Fixed 2026-09-18: the script now counts passives against
passives and credits data-driven implementations, and prints the split rather
than one number.

One perk the id-scan reports as implemented is not: **`soothing_presence`**
(Yoga 2, "+10% success chance on rolls for non-violent solutions in dialogue")
appears in `scripts/` only inside a doc comment in `aura_system.gd`, which
happens to use the same string as its example. It is description-only, and it is
a `non_combat` effect, so it is blocked on the consumer gap below rather than on
authoring.

**The rule everything rests on:** a hand-implemented perk must never *also*
carry an `effects` array, or it fires twice. `tools/wire_passive_perks.py`
derives the hardcoded set by scanning `scripts/` rather than keeping a list, so
a perk hardcoded tomorrow is protected without anyone remembering, and
`verify_passive_perks` re-checks it against shipped data. Note that **Parry and
Improved Parry — the plan document's own worked example of a
`stat_conversion` — are both hardcoded** and must stay that way.

Working effect types: `stat_bonus` (conditional and not), `stat_conversion`,
`resistance`, `on_trigger`.

- [ ] **Author the remaining 324.** Mechanical, and the tooling refuses bad
      data, but it is a long pass. Worth doing skill by skill. The heaviest are
      the 30 cross-perks, then fire_magic (15), comedy (14), performance (14),
      thievery (14), summoning (13) and alchemy (13); eleven skills have four or
      fewer left. `python3 tools/wire_passive_perks.py` prints the split on
      every run.
- [ ] **`non_combat` effects are deliberately unbuilt.** ShopSystem and
      EventManager have no consumer for them. Authoring an effect before its
      reader exists is the exact failure this whole pass spent its time
      undoing — build the consumers first. This is what the seven overworld
      perks in §10 are waiting on too.
- [ ] **Unbuilt effect types:** `aura`, `cost_reduction`, `damage_modifier`,
      `resource_regen`, `spell_modifier`, `summon_modifier`, `special`.
      `summon_modifier` has the most data waiting on it — several black, fire
      and air perks buff summons and all of them are inert. `damage_modifier`
      and `resource_regen` are the two the new triggers are waiting on, per the
      note above. (`aura` is a half-truth: a perk can already declare
      `aura: "<id>"` and AuraSystem resolves it — `immune_system` and
      `avatar_of_the_storm` do. What is missing is `aura` as an entry in the
      `effects` array.)
- [x] ~~**More trigger points.**~~ — **done 2026-09-18.** Four added:
      `combat_start`, `turn_start`, `take_damage`, `ally_damaged`. Eight fire
      now, and `validate_data.py` reads the fired set straight out of the call
      sites, so a perk naming a trigger nobody fires fails the build.

      **`parry_success` was deliberately NOT added.** There is no parry roll in
      this game to succeed at — `parry` and `improved_parry` are armour bonuses
      computed off accuracy, and a miss is just a miss. Adding it would have
      created exactly the dead vocabulary this section exists to prevent. If
      parrying should become an event, that is a combat design change first.

- [x] ~~**More conditions.**~~ — **done 2026-09-18**, and they split into two
      families, which is the part worth remembering:
      - **Self-conditions** work anywhere, including from a stat getter:
        `wearing_heavy_armor`, `unarmored_or_light` (the chest piece's weight
        against a threshold of 8 — generated `armor` lands 9–20 and a `robe`
        1–3, so the two never meet), `first_attack_combat`, `first_attack_turn`.
      - **Target conditions** — `from_behind`, `target_bleeding`,
        `target_debuffed` — need to know who is being attacked. A stat getter
        does not, so they only work on an `on_trigger` effect, and only on
        `on_hit`/`on_crit`/`on_kill`, which are the triggers that carry a
        target. The tool refuses to write one anywhere else.
      - **`on_terrain_type` takes an argument**, `on_terrain_type:forest`, which
        is the first parameterised condition. Checked against terrain.json by
        both the tool and the validator.

- [ ] **Payloads are the actual bottleneck, not triggers.** Having added the
      moments, the honest finding is that they unblock less than expected. A
      trigger payload can be one of four things — `buff`, `status`, `heal`,
      `restore_stamina` — aimed at one of three targets — `self`, `attacker`,
      `victim`. Going through the description-only perks that name one of the
      new moments, almost none can be expressed:

      - `preventive_care`, `hurry_betrays_distraction`, `field_commander` all
        want **allies** as a target, which no payload can name.
      - `damage_control` ("reduce it by a flat amount equal to 10% of max HP")
        wants `damage_modifier`, and wants to run *inside* `apply_damage`
        rather than after it.
      - `shoulder_to_shoulder` wants to redistribute damage across allies —
        both of the above at once.
      - `slippery` wants an escape-from-restraint mechanic that does not exist.

      So the next increment is **payload targeting (`allies`, `allies_in_range`)
      and the `damage_modifier` / `resource_regen` effect types**, not more
      moments. Deliberately not authored ahead of its reader.

## 13b. Two bugs found while wiring the triggers (2026-09-18)

Both in the code the trigger work touched, neither related to it.

- [x] **Combat-start perks never fired in a deployment battle.**
      `_apply_combat_start_perks()` had exactly one call site, in
      `start_combat()`. The deployment path — `start_combat_with_deployment()`
      → `_finalize_combat_start()` — calculated turn order, emitted
      `combat_started` and went straight to the first turn. So Rousing Display
      and every other combat-start perk did nothing in any fight entered
      through deployment, which is most of them. One missing call.

- [x] **`conditions` on an `on_trigger` effect were silently ignored.**
      `_fire_perk_triggers()` checked the trigger name and `chance` and applied
      the payload; it never looked at `conditions`. No shipped perk carried one,
      so it was a trap rather than a live bug — but `wire_passive_perks.py`
      would happily have written one during the authoring pass, and the perk
      would have fired unconditionally with nothing to show for it.

      Fixed alongside: a payload aiming at `attacker` or `victim` on a trigger
      that does not carry them used to fall through to the perk's owner, so a
      retaliation would have buffed the person who was just hit. It errors now,
      and the tool refuses to write the combination.

---

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

# Part II — Designs waiting to be built

Kept in full: these are settled designs with no implementation yet.

## Yidam System (personal deity practice)

- Deities are **translated** into English ("Adamantine Terrifier", not
  "Vajrabhairava") — avoids publishing secret names while keeping the meaning
- Roster drawn from the mantra list in `PERKS.md`; masks as optional head-slot
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

# Part III — Per-level skill bonuses: closed 2026-09-18

**This part is finished, and was finished long before anyone said so.**

It was written on 2026-07-27 and read, until today, that
`CharacterSystem.update_derived_stats()` applied **13 of 40** `base_bonuses`
stat keys and the other 27 were dead — that Trade 10 conferred no discount,
Grace no movement, Logistics no travel or supply benefit. It then listed all 27
in a table, with a target system and a balance note for each.

None of that is true any more, and most of it stopped being true during the
September wiring phases. §6 recorded the correction on 2026-09-16 — the real
figure at that point was **4 of 39** unwired, not 27 of 40 — but Part III was
left standing, so the file carried both numbers in two places for two days shy
of a month, and the larger, older, more alarming one came first.

**The live state: one key of 39 has no consumer, `crafting_quality_pct`**, and
it is blocked on design rather than wiring — camp crafting pulls from a fixed
`CRAFT_TABLE` with no quality concept, so there is nothing for a quality
percentage to modify. It is the single remaining entry under `base_bonuses stat`
in `tools/vocabulary_baseline.json`.

Everything the old table listed as dead now lands somewhere:

- **Shops** — `buy_discount`, `sell_markup`, `trading_price` converged with the
  hand-rolled discounts that disagreed with them (Phase 2, 09-12).
- **Overworld** — `party_travel_speed_pct`, `party_supply_duration_pct`
  (Phase 3, 09-12).
- **XP and checks** — `party_xp_gain_pct`, `party_skill_check_bonus`
  (Phase 3, 09-12).
- **Social** — `charm_effectiveness_pct` and `social_roll_pct` turned out to be
  one stat with two sources and became `party_social_roll_pct`; `morale_pct` was
  deleted as a relic of the idea that became PsychologySystem.
- **Party size** — `max_companions` became `party_max_companions`: two free,
  Leadership adding one at 3, 6 and 9.
- **Loot, crafting, traps** — `loot_quality_pct`, `crafting_yield_pct` and
  `trap_detection_pct`, wired 09-16, each to a consumer that was already waiting
  rather than one invented for it.
- **Proc sites** — `stun_chance_pct`, `burning_damage_pct`,
  `status_effect_chance_pct` all fire; `luck_pct` feeds crit chance and loot
  chance instead of becoming a number of its own.
- **`effect_duration_pct`** was a duplicate and was deleted, not wired. The
  Enchantment table holds the numbers as `effect_duration_turns`.

The two display-style key names this part asked to be tidied
(`healing_effectiveness_(party)`, `poison/disease_resistance_(party)`) are
snake_case now, and `perks.json`'s `base_bonuses._comment` carries the naming
convention with validate_data.py enforcing it.

**The lesson worth keeping**, since this file exists partly to record them: the
bug class here was never the unwired keys. It was that the *record* of them
outlived the fix by a month and stayed at the top of the largest heading in the
document. The data→code check in `validate_data.py` now catches the underlying
problem automatically; nothing catches a stale paragraph, so Part III is kept as
a closed section rather than deleted.

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

Kept: `PERKS.md` and `CHARACTERS.md` (hand-maintained design sources),
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
