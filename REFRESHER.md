# Six Worlds — State of the Project Refresher

**Date:** 2026-07-27 (post-break code audit)

A snapshot of where the project stands, what the audit fixed, what is started
but unfinished, and where to pick up. For exhaustive task lists see `TODO.md`
(still accurate and well-maintained); this file is the orientation layer on top.

---

## Where the project stands

Three of six realms have real content:

| Realm | Map | Enemies | Events | Shops | Companions |
|---|---|---|---|---|---|
| **Hell** | ✓ (cold/fire + divider) | ✓ 45 archetypes | ✓ 73 events | ✓ | ✓ 24 |
| **Hungry Ghost** | ✓ (3 zones) | ✓ 23 archetypes | ✓ 141 events (0% dead map weight) | ✓ | ✓ 23 |
| **Animal** | ✓ (ocean/forest/meadow) | ✓ 34 archetypes | ✓ 86 events (0% dead map weight) | ✓ | ✓ 24 |
| Human / Asura / God | ✗ | ✗ | ✗ | ✗ | ✗ |

Core systems all exist and are wired: character/XP, karma/reincarnation,
events (grey/blue/yellow choices, dynamic DCs), grid combat (spells, AoE,
statuses, AI, projectiles), overworld (real-time movement, mobs, portals),
shops/training/guilds, items (procedural weapons/armor/talismans, implements,
charms), perks (600), psychology/pressure, traits, wounds, body plans
(multi-arm species), camp/rest/time/lunar calendar, save/load (3 slots),
audio, cheat console. Engine is **Godot 4.6** (CLAUDE.md said 4.3 — updated).

## What the 2026-07-27 audit fixed (already committed)

The full list is in the two commit messages; the load-bearing ones:

1. **Animal & domain enemies never loaded** — EnemySystem only loaded hell +
   HG files. Animal realm combat would have fallen back to generic hell demons.
2. **Combat realm was always "hell"** — archetype realm filtering used the
   default parameter, so HG fights could pull hell "any-region" archetypes.
3. **Event `difficulty` was dead data** — "hard"/"easy" on combat outcomes now
   actually scales enemy power (easy 0.75× … boss 1.6×).
4. **`item_random` rewards gave nothing** — 49 event outcomes silently skipped
   their item reward; now generates party-scaled weapon/armor/talisman.
5. **Merge regression: all 47 companions lost their trait lists** — restored
   from pre-merge history under the `traits` key CompanionSystem reads.
6. **Deleted QuirkSystem still referenced** in psychology_system (parse-level
   breakage → quirk crisis reactions never ran). Migrated to TraitSystem.
6b. **All three quests were unfinishable** — the board handed them out and
   nothing in the game ever set the flags their steps check. Fixed in a later
   pass with six new hell events; the validator now rejects a quest whose step
   flag no event sets.
7. **Boss gating was fiction** — `requires_boss_defeated` on the HG portal was
   never checked, and nothing ever called `GameState.defeat_boss()`. Both now
   wired; portals also no longer double-generate the destination map.
8. **The HG realm boss event didn't exist** — `hg_boss_insatiable_king`,
   `hg_swamp_warden`, `hg_bone_gate_keeper` were referenced by the map config
   but unwritten (progression-blocking). All three written, with a new
   Insatiable King boss archetype + encounters, and a new `defeat_boss: true`
   event-outcome key so the Yoga-6 peaceful resolution also unseals the portal.
   **→ Olaf: give these three events a narrative pass — the prose is mine.**
9. **~130 broken data references** — shop items/spells (mostly animal realm +
   domain shops), event reward items, `crafting` → `smithing` requirements,
   empty animal `enemy_group`s, 13 statuses applied by code but undefined
   (Weakened, Knocked_Down, Rage, …), 5 perks implemented in combat code but
   missing from perks.json (sentinel, avatar_of_the_storm/wind, …),
   red/yellow devil racial bonuses (now real traits granted at creation).
10. Roll choices can now carry skill/attribute gates ("gated gamble" —
    used by hg_desperate_mother's Yoga-gated Charm roll).

`tools/validate_data.py` is the reusable data validator (run it after any
content merge; exits non-zero on a dangling reference). An earlier ad-hoc
version had a blind spot that hid every map→event reference in the game —
if you write a checker, check its negatives.

It checks events→encounters/shops/items/spells/traits/skills/wounds/karma,
map configs→events/mobs/pickups, shops→items/spells/companions,
companions→births/backgrounds/items/spells/traits, races and backgrounds→
skills/traits/equipment, encounters→archetypes, and code→perk ids/status names.

## Started but not finished

Ordered roughly by how much finished work is sitting behind each gap.

### Content gaps in otherwise-done systems
- ~~34 HG flavor events~~ — done. All three realms with content are now at
  **0% dead map weight** (hell 73 events, hungry ghost 141, animal 86); every
  marker the maps place resolves to a real event.
- ~~Animal realm companions~~ — done, 24 added covering all 17 births.
- ~~Animal realm zone events~~ — done, all 47 written.
- **All of the above is Claude's prose and wants Olaf's pass** — 81 new events
  and 24 companion bios across the two content passes.
- ~~Bespoke recruitment events for HG companions~~ — the 9 priority targets
  are done; the rest stay shop-only by design.
- ~~Prosthetic items~~ — 12 created, and the two missing code links wired.
- **Hell quest content beyond the three fixed chains** — the board works now
  but only has three quests, all hell. HG and animal have none.
- ~~PERKS.md empty tiers~~ — done. Every skill now has at least one perk at
  every level 1–10 (28 new capstones, 94 perks redistributed off the old
  odd-only tiers, 9 written to fill what redistribution couldn't reach).
- **Perk flavor text** — 500 of 600 perks have an empty `flavor` field. Better
  written in Olaf's voice than mine.
- **27 per-level skill bonuses have no consumer** — `base_bonuses` grants them,
  nothing reads them. Full table and per-system wiring notes in TODO.md §
  "Per-Level Skill Bonuses With No Consumer".
- **Cursed items**: type registered, none exist.

### ~~UI debt~~ and ~~half-wired mechanics~~ — CLOSED 2026-07-27
Both categories were finished in the follow-up pass. Highlights: WOUNDS & BODY
and STATE OF MIND panels in the character sheet; cone_forward AoE locked to
facing; per-arm chain results in the combat log; paid wound healing at 12
shops; Riposte/Reflect/Magic_Mirror/Mirror_Images/Taunt/Karmic_Bond/
Eternal_Vow/Mantric_Armor/Ancestors_Blessing/Swarmed/Lured/Constitution
statuses wired; four AI behavior types (`erratic_movement`, `priority_target`,
`pack_bonus`, `burrow_emerge`); summoning terrain affinity; Coordinated
Strikes; Cloud Gate; Set Snares and Craft Charm camp activities;
location-specific camp suppress/enhance. Full detail in TODO.md §
"UI Debt & Half-Wired Mechanics Pass — 2026-07-27".

Two TODO entries turned out to be **stale, not missing**: elemental terrain
spellpower modifiers and Yoga-boosted rest pressure decay were both already
implemented.

Still deferred from that pass, with reasons:
- **Dominated** full enemy-control AI (puppet currently just loses its turns)
- **Combat-UI wound icons** (character sheet shows them; unit frames need art)
- **Protector Offering** camp activity — blocked on DharmapalaSystem
- **Rest follow-ups**: realm-specific rest events, day/night visuals,
  rest-blocked-when-mob-adjacent

### Design-phase systems (not started, dependencies noted)
- **Yidam + Dharmapala deity systems** — biggest designed-but-unbuilt item.
  Note: `mantra_count` already accumulates via camp Mantra Recitation with no
  consumer; masks and Deity Yoga hooks reference this design too.
- **Human/Asura/God realms** — need map configs, archetypes, encounters,
  events, backgrounds. Human realm zone design (Oddiyana steppe / Zhang-Zhung
  / coastal cities) is sketched in TODO.md § Realm-Specific Mechanics.
- **Camp Followers** — Party-tab UI stub, no backend.
- **Meta-progression across runs** — save_manager is per-run only.
- **Klesha/chronic-darkness counter**, psychology Layer-3 interventions.
- **Astrological (Space) and Paushtikakarma (Earth) spell families.**

### Balance passes waiting on playtesting
Wound penalties (`body_system.gd` table), camp activity yields, sadhana
pressure-decay stacking, spell mana costs, shambler race (−7 attributes, no
compensating passive), multi-arm damage scalars.

## Point of departure

**Recommended first session back: a hell → hungry ghost → animal playthrough.**
All three realms are now fully populated and none of the new content has been
played: hungry ghost gained 37 events since you last played it, and the animal
realm (86 events, 24 companions) has never been played at all.
Progression is now actually gated (boss seal enforced, boss events exist), the
animal realm's enemies/shops/events load for the first time, and a large batch
of mechanics went from data-only to live — none of it has been played. Use the
cheat console to speed through.

Specifically worth watching for:
- The **first-pass balance numbers** listed at the top of TODO.md §
  "UI Debt & Half-Wired Mechanics Pass" — summoning terrain +25%, pack bonus,
  shield/mirror-image pools, reflect chances, wound-healing prices.
- **All the new writing is Claude's, not yours** and wants a prose pass: the
  three HG events (boss + two pass guardians), the 47 animal zone events, and
  the 24 animal companion bios.
- The new **difficulty multipliers** (easy 0.75× … boss 1.6×) applied to every
  event fight for the first time.
- The **wounds/psychology panels** — first look at whether the wound and
  pressure systems are tuned sanely now that they're visible.

Good second sessions, depending on appetite:
- **Content mood:** more quests (the board works now but has only three, all
  hell), PERKS.md's empty tiers, or cursed items.
- **Systems mood:** prosthetic items (small, unblocks a fully-coded flow), or
  combat-UI polish (wound icons on unit frames, per-arm damage popups).
- **Big-swing mood:** YidamSystem — the design in TODO.md is complete enough
  to implement, mantra counts are already accumulating, and camp Mantra
  Recitation feeds it with no consumer today.
