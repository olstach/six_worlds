# Six Worlds — The Writing List

**Everything that wants your voice.** Prose to revise, prose to write from
scratch, and the small text fills. Compiled 2026-09-18 from `TODO.md`, checked
against the data rather than copied.

`TODO.md` remains the list of *work*. This is the list of *writing*, pulled out
so it can be read and ticked off away from the machine.

---

## How edits get back into the game

Almost none of the prose below is edited here. It lives in `docs/review/` —
eleven generated documents that round-trip to JSON. Each editable string sits
between anchors naming its exact place in the data:

```
<!--@ hell_events.json | hell_bone_arena | title -->
Bone Arena
<!--@end-->
```

- **Change anything between an anchor and its `@end`.** Multiple paragraphs and
  blank lines are fine.
- **Do not touch the anchor lines,** or the ids in headings.
- Everything outside the anchors — headings, `mechanical lines`, tables — is
  generated and will be overwritten.

```bash
python3 tools/import_review_docs.py            # dry run: prints every change
python3 tools/import_review_docs.py --write    # apply
python3 tools/validate_data.py                 # always, afterwards
```

> **Import before you re-export.** `export_review_docs.py` regenerates the
> documents from the data and discards anything written but not imported.

### Two things to do before you start editing

- [ ] **You have one edit pending import.** `ANIMAL_COMPANIONS.md` gives
      Mandaka "Considers locks a personal **remark**"; `companions.json` still
      says "a personal **challenge**". The doc is ahead of the data, so a
      re-export would throw the better line away. Run
      `python3 tools/import_review_docs.py --write` to keep it.
- [ ] **Then re-export once.** Two documents are behind the data:
      `ANIMAL_ENEMIES.md` still prints resistances in the retired vocabulary
      (`earth 15%`, `air 10%` where the data now says `crushing 15%`,
      `lightning 10%` — the 09-16 resistance rework), and `EVENTS_ANIMAL.md`
      announces 94 events above its 86 sections, because the header counted
      the eight `_comment_*` keys in `animal_events.json`. The exporter miscount
      is fixed; the document picks it up on the next export.

### A note on the NEW markers

`TODO.md` says the recent prose is "marked **NEW EVENT** / **NEW** in
`docs/review/`". **It is not** — the markers need a base snapshot and none is
configured, so every document currently says so in its own header. The content
batches also predate this repository's visible history, so git cannot separate
them either. To turn the markers on, copy the JSON you want to compare against
into a directory and:

```bash
REVIEW_BASE_SNAPSHOT=/path/to/old/json python3 tools/export_review_docs.py
```

Until then the review passes below are scoped by *what* rather than by marker.

---

# Part 1 — Revise (it exists, it is mine)

## 1.1 The animal realm — its entire text

Never played, never read by you. `docs/review/EVENTS_ANIMAL.md` (86 events),
`ANIMAL_COMPANIONS.md` (52), `ANIMAL_RACES.md`, `ANIMAL_ENEMIES.md`,
`ANIMAL_LOCATIONS.md`, `ANIMAL_WORLD.md`, `ANIMAL_NAMES.md`.

- [ ] **The 47 zone events** — forest, meadow, ocean. The narrative ones, not
      the storefronts.
- [ ] **The 52 companion bios.** `TODO.md` still says 24; the birth-by-birth
      pass doubled it and nobody updated the line. All 52 have a `flavor_text`
      and all 52 are mine.

The roster, to tick off by zone. **Forest carries 36 of the 52** — meadow and
ocean are eight each, which is its own problem (see 2.6).

- [ ] *forest (36)* — Brihannala `vanara`, Chapala `mriga`, Chitrangada
      `marjara`, Dhvanika `gana`, Dirghajihva `gana`, Ekadamshtra `varaha`,
      Enakshi `mriga`, Ghoraka `varaha`, Ghoshaka `gana`, Himasara `mriga`,
      Kabandha `rakshasa`, Kandali `varaha`, Khara `rakshasa`, Kruddha
      `rakshasa`, Kshanaka `marjara`, Mandaka `marjara`, Mrichha `varaha`,
      Nadaka `gana`, Nayanika `mriga`, Niloka `marjara`, Nishkasita `rakshasa`,
      Phalguna `vanara`, Phulla `varaha`, Runborn `varaha`, Rupaka `marjara`,
      Saramaya `gana`, Sarangi `mriga`, Shrutidhara `mriga`, Sphotana `gana`,
      Sthiraka `marjara`, Takshari `rakshasa`, Trinavati `mriga`, Unmatta
      `rakshasa`, Varika `marjara`, Vasuda `varaha`, Vishanin `mriga`
- [ ] *meadow (8)* — Agnishikha `patanga`, Balavardhana `shyena`, Kshudraka
      `uluka`, Madhuvrata `bhramara`, Nirvikalpa `khadga`, Sthanumati `yaksha`,
      Tikshnashringa `khadga`, Valmika `dura`
- [ ] *ocean (8)* — Anavatapta `naga`, Kambu `karka`, Minakshi `matsya`,
      Phenaka `kapota`, Setubandha `makara`, Shesharati `naga`, Timingila
      `makara`, Vajradanti `karka`

## 1.2 The hungry ghost gap-fills

`docs/review/EVENTS_HUNGRY_GHOST.md` — 150 events. The first ~20 are yours and
drafted in `resources/data/events/hungry_ghost_events_plan.md`; the rest are
gap-fills of mine.

- [ ] **The 34 gap-fill events.** Cross-reference against the plan document —
      an event whose id does not appear there is mine.
- [ ] **The three map-critical ones**, which gate progression and so get read
      more carefully than any other event in the realm:
      `hg_boss_insatiable_king`, `hg_swamp_warden`, `hg_bone_gate_keeper`.

## 1.3 Trait descriptions

- [ ] **118 traits, none with flavour.** `docs/review/TRAITS.md`. They carry a
      `description` (mechanical) and no flavour field at all — so unlike perks,
      this is a decision about whether traits *should* have a voice line, not a
      backlog of blanks.

---

# Part 2 — Write from scratch

## 2.1 Perk flavour — the biggest single block

**500 of 605 perks have an empty `flavor`.** Not in `docs/review/`; they live in
`resources/data/perks.json`, with the trees laid out in `PERKS.md`.

Worth doing skill by skill. The heaviest first:

| n | skill | | n | skill |
|---|---|---|---|---|
| 36 | *cross-perks* | | 15 | leadership |
| 19 | performance | | 15 | water_magic |
| 18 | fire_magic | | 15 | medicine |
| 16 | enchantment | | 15 | sorcery |
| 16 | armor | | 15 | comedy |
| 16 | summoning | | 15 | guile |

- [ ] cross-perks (36) · [ ] performance (19) · [ ] fire_magic (18)
- [ ] enchantment (16) · [ ] armor (16) · [ ] summoning (16)
- [ ] guile (15) · [ ] comedy (15) · [ ] sorcery (15) · [ ] leadership (15)
- [ ] water_magic (15) · [ ] medicine (15)
- [ ] …and the remaining tail

## 2.2 Hell — the realm that stayed small

Hell is the first world a player sees and the thinnest one they will see.
Six births against the animal realm's eighteen.

- [ ] **Backgrounds that tell the six devils apart.** Hell has **six**
      non-generic backgrounds in total — `berserker`, `executioner`,
      `infernal_scribe`, `raider`, `soul_jailer`, `torturer` — and all six
      devils draw from nearly the same set. Red gets berserker, green gets
      berserker, white gets neither executioner nor raider, and otherwise they
      are interchangeable. The animal realm has **74** across eighteen births;
      hungry ghost has 15 across fourteen.

      This got sharper on 2026-09-18, not softer. Birth-specific backgrounds
      used to come up 12% of the time and now come up about half, so whatever a
      devil's own list says is what devils will actually be. Six shared entries
      is thin at 12% and conspicuous at 50%.

      What it wants is a handful each that only that devil could have been —
      red is wrath and the finest warriors, white is the diplomat, blue keeps
      the souls. Mechanically it is one entry per background in `races.json`
      with `available_races` naming the birth; the work is deciding what six
      kinds of devil *do* with themselves.

- [ ] **The six unwritten event chains**, from the original list:
      soul caravan ambush · devil deserter · contraband deal · corrupted simple ·
      chained pilgrim · rival party.
- [ ] **Expand hell toward the intended 9–12 births.** Six was never the target.

## 2.3 Quests

**Three exist, all in hell** — `cold_prisoner`, `ember_debt`, `lost_mantra`.
The board works and the validator guarantees every step flag is settable.

- [ ] Hungry ghost quests — none
- [ ] Animal quests — none

## 2.4 The animal realm's missing voices

- [ ] **Mriga have no events at all.** Four events mention gana; none mention
      mriga, so the forest has wolves in its prose and no deer. Two existing
      events read as either and could simply be switched —
      `animal_forest_healer_camp` (a grey-muzzled healer, and medicine is the
      mriga trade) and `animal_forest_town_weapons` (traders). Sketches:
  - *The Alarm Tree* — the herd's warning goes up before you can see why.
    Rewards Awareness; `first_to_know` should read it differently.
  - *The antler contest* — two bucks holding a clearing you need to cross,
    settling it by display. A fight you are allowed to decline, which is the
    most mriga thing available.
  - *The old trail* — a migration crossing your route, a `songline_guide`
    carrying the song that is the only map of it.
- [ ] **Marjara want a cluster, not one event.** Solitary predators who do not
      anchor encounters, but the birth carries more comic and world-building
      potential than any other in the realm: the smuggler's patter, the
      pleasure dancer, the cutpurse insisting marjara is innocent of *this*
      crime. Their place names are ready-made settings — The Hollow Where
      Nothing Comes, The Long Wait, The Patient Rock.

## 2.5 The naming lore, used by nothing

- [ ] **The place names are still read by nothing.** As of 2026-09-18 the
      file's **155 personal names** are wired — every animal birth names its own
      children now — but its **128 place names** and 88 parent wishes are still
      referenced by almost no content. Fold them into the events pass: an event
      set on **The Wrong Side** is already half-written by its own name.

  The rakshasa set alone: **The Long Hunger** (a stretch of poor territory
  between productive ones), **The Wrong Side** (anywhere they do not go, and
  there is always a reason), **The Ridge Where They Wait**, **The Mango Kill**,
  **The Scratch Tree**, **The Three-Day Territory**. Every birth has six or so.

  Readable as prose in `docs/review/ANIMAL_NAMES.md`.

## 2.6 Realm-specific rest and camp flavour

- [ ] **"Something stirs in the night"** — rest events with realm flavour for
      hell and hungry ghost. None exist.

## 2.7 Three empty realms

Human, asura and god have **no content of any kind**. Each needs map config,
archetypes, encounters, an event file, companions, backgrounds and shops.
Asura and god births currently have **zero** background slots between them;
human has seven across four births.

Human-realm zone design is already settled (`TODO.md` Part II) and is the one
with a shape to write into:

- [ ] **West — Oddiyana/Gandhara steppe.** Scythian nomads, cavalry →
      Ranged, Guile, Daggers
- [ ] **North-east — Zhang-Zhung.** Proto-Tibetan shamanic Bön, yak herders →
      Ritual, Yoga, Earth magic
- [ ] **South-east — coastal trade cities.** Cosmopolitan mercantile →
      Trade, Persuasion, Alchemy

The other two have a stance but no zones: **asura** is competitive events and
duels; **god** is almost no combat, diplomacy and trade.

## 2.8 Boss and miniboss fights

Hell is standard so far. Hungry ghost candidates, each wanting a fight *and*
the prose around it:

- [ ] Bone Lord — earth magic undead commander
- [ ] Great Devourer — shaza
- [ ] Mirror of the Setting Sun — copper construct
- [ ] Matriarch of All Longing — yidag

---

# Part 3 — Small fills

- [ ] **Racial resistances: 47 births, all empty.** Not prose exactly, but it
      is birth characterisation and only you can say what a skeleton, a rolang
      or a naga shrugs off. The wiring is finished as of 2026-09-18 — the
      numbers reach player characters, companions and enemies alike — and
      `validate_data.py` checks every key against `damage_types.json`, so a typo
      fails the build instead of silently resisting nothing. The vocabulary:
      `physical` (or `slashing`/`crushing`/`piercing`), `fire`, `ice`,
      `lightning`, `space`, `white`, `black`, `poison`, plus `bleed`, `disease`
      and `ranged`. Values are percentages; above 100 heals for the excess.

- [ ] **Three background descriptions are placeholders I wrote.** `beggar`
      (yidag), `sorcerer` and `courtier` (skeleton_copper) were named by those
      births and defined nowhere, so wiring `typical_backgrounds` made them
      real. I gave them mechanics — attributes, skills, a robe for the beggar —
      and a holding line of description each, marked `PLACEHOLDER (mechanics
      final, prose wants Olaf)` in `races.json`. The mechanics are settled; only
      the description wants replacing. They matter more than their number
      suggests: `beggar` is the first background yidag has ever had of its own,
      and it will now come up about half the time a yidag is born.

- [ ] **Eight race descriptions still say `TODO: Fill in description`** —
      `nomad`, `mountain_folk`, `trader`, `tsen`, `rudra`, `gandharva`,
      `apsara`, `planetary_deity`. All eight belong to unbuilt realms, so this
      is blocked behind 2.7 rather than being a quick win.
- [ ] **Cursed items have no text because they have no existence** — "cursed"
      is a status and a terrain type, the item type is registered, and zero
      cursed equipment exists.
- [ ] **Ritual implement flavour is invisible to the player.** The tables know
      copper serves fire and the phurba serves sorcery, and the verifier
      enforces it, but a tooltip shows a Copper Phurba without explaining it is
      the instrument for a fireball. Needs the tooltip wiring first — then the
      words.

---

# Part 4 — Items removed from the writing list

Checked against the data and found already done, or not writing at all.

- **"53 events are grey-only, target ≥2 meaningful checks each."** True as a
  count and misleading as a task: **52 of the 53 are storefronts** — teahouses,
  town shops, mercenary guilds, training camps, peddlers, landmark temples.
  Their two grey choices are "browse wares" and "leave", which is correct for a
  re-enterable location, and `docs/review/README.md` already says so. The one
  genuine narrative event is `hg_sigh_of_relief`, a deliberate single-beat
  toast — a cairn with a folded cloth, `+15% HP/mana`, `touched_by_grace`.
  Nothing to write.

- **"Realm-specific wounds — 5 base types exist, target ~8–10."** There are
  **17**, and they include every one the item asked for: `barbed_wound` (the
  arrow wound), `poisoned_blood` and `venom_shock`, `spiritual_corruption`,
  `marrow_chill` and `burn` for hell, `bone_fever`, `brain_fever`. Done and
  never ticked off.

- **"Background assignment wants a pass across all births."** The premise did
  not hold — the pass would have edited `typical_backgrounds`, which no game
  script read. **Fixed in code on 2026-09-18 instead:** both declarations now
  decide what a birth can be born into, and the roll favours a birth's own
  backgrounds rather than letting the 33 universal ones drown them. Every birth
  in a built realm went from ~12% birth-specific to ~50%, and yidag from 0%.
  Not a writing task — but it created one, in 3.1 below.

---

# Appendix — what actually exists

Counted from the data on 2026-09-18, not copied from another document.

| | hell | hungry ghost | animal | domain | total |
|---|---|---|---|---|---|
| events | 79 | 150 | 86 | 33 | **348** |
| births | 6 | 14 | 18 | — | 47 *(+9 unbuilt realms)* |
| companions | 24 | 23 | 52 | — | **99** |
| quests | 3 | 0 | 0 | — | **3** |
| enemy archetypes | 45 | 23 | 43 | 3 | **114** |

Elsewhere: **605** perks (500 without flavour) · **377** spells · **736** items ·
**187** statuses · **118** traits · **120** backgrounds (33 universal) ·
**91** shops · **17** wound and disease types.
