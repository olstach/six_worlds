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
| **Hungry Ghost** | ✓ (3 zones) | ✓ 23 archetypes | ✓ core + infra (34 flavor events still unwritten — list in `EDIT_LATER.md`) | ✓ | ✓ 23 |
| **Animal** | ✓ (ocean/forest/meadow) | ✓ 34 archetypes | ✓ 39 infra events | ✓ | ✗ none |
| Human / Asura / God | ✗ | ✗ | ✗ | ✗ | ✗ |

Core systems all exist and are wired: character/XP, karma/reincarnation,
events (grey/blue/yellow choices, dynamic DCs), grid combat (spells, AoE,
statuses, AI, projectiles), overworld (real-time movement, mobs, portals),
shops/training/guilds, items (procedural weapons/armor/talismans, implements,
charms), perks (558), psychology/pressure, traits, wounds, body plans
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

A reusable data validator lives in the audit session; the checks it runs
(events→encounters/shops/items/spells/traits/skills, map configs→events/mobs,
companions→everything, code→perk ids/status names/autoload methods) are cheap
to re-run — worth re-running after any big content merge.

## Started but not finished

Ordered roughly by how much finished work is sitting behind each gap.

### Content gaps in otherwise-done systems
- **34 HG flavor events** unwritten (`EDIT_LATER.md` has the ID list) — the
  realm plays but is thinner than hell.
- **Animal realm companions: zero.** Hell has 24, HG has 23. Recruitment
  events/shops for animal realm reference no one.
- **Bespoke recruitment events** for HG companions (priority targets listed in
  TODO.md § Companions).
- **Hell event chains + quest content** (soul caravan, devil deserter, …) —
  quest board system exists, content doesn't.
- **PERKS.md empty tiers** (levels 2/4/6/8 for many skills); perk flavor text.
- **Prosthetic items**: the entire limb-loss → prosthetic flow is coded
  (equip bypass, slot restore) but items.json has zero prosthetic items.
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
- **Prosthetic items** — flow is coded and the panel displays them, but
  items.json still contains none
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
Progression is now actually gated (boss seal enforced, boss events exist), the
animal realm's enemies/shops/events load for the first time, and a large batch
of mechanics went from data-only to live — none of it has been played. Use the
cheat console to speed through.

Specifically worth watching for:
- The **first-pass balance numbers** listed at the top of TODO.md §
  "UI Debt & Half-Wired Mechanics Pass" — summoning terrain +25%, pack bonus,
  shield/mirror-image pools, reflect chances, wound-healing prices.
- The **three new HG events** (boss + two pass guardians) need a prose pass —
  the writing is Claude's, not yours.
- The new **difficulty multipliers** (easy 0.75× … boss 1.6×) applied to every
  event fight for the first time.
- The **wounds/psychology panels** — first look at whether the wound and
  pressure systems are tuned sanely now that they're visible.

Good second sessions, depending on appetite:
- **Content mood:** the 34 HG events, or animal realm companions (the
  recruitment machinery is all built — it's pure data + flavor).
- **Systems mood:** prosthetic items (small, unblocks a fully-coded flow), or
  combat-UI polish (wound icons on unit frames, per-arm damage popups).
- **Big-swing mood:** YidamSystem — the design in TODO.md is complete enough
  to implement, mantra counts are already accumulating, and camp Mantra
  Recitation feeds it with no consumer today.
