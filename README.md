# Six Worlds

A tactical RPG roguelike set in the six realms of Tibetan Buddhist cosmology.
Godot 4.7, GDScript. Grid combat, FTL-style events, and progression with no
levels — XP is a currency you spend, because cultivation is gradual.

Karma is tracked per realm and hidden from the player. Whichever realm you have
the most karma in when you die is where you are reborn.

---

## Where the project actually stands

Three of six realms have content. The systems are all built; the gap is realm
content, not machinery.

| Realm | Map | Enemies | Events | Shops | Companions |
|---|---|---|---|---|---|
| Hell | ✓ cold/fire + divider | ✓ 45 archetypes | ✓ 79 | ✓ | ✓ 24 |
| Hungry Ghost | ✓ 3 zones | ✓ 23 archetypes | ✓ 150 | ✓ | ✓ 23 |
| Animal | ✓ ocean/forest/meadow | ✓ 34 archetypes | ✓ 86 | ✓ | ✓ 24 |
| Human / Asura / God | — | — | — | — | — |

**Never played end to end.** Individual systems are verified; the full loop
(reincarnate → explore → fight → die → reincarnate) has not been sat down with.
Expect the first real playthrough to find things no check here catches.

At a glance: 21 autoloads, 39 scripts, ~42k lines of GDScript, 604 perks,
363 spells, 606 items, 348 events, 168 statuses, 121 traits, 99 companions,
114 enemy archetypes, 91 shops.

---

## Running and checking it

```bash
godot                       # play
godot --headless            # boot only; autoload init lines print to stdout

tools/verify_all.sh         # everything: parse, boot, data, engine verifiers
tools/verify_all.sh --quick # skip the engine layers
```

`verify_all.sh` runs four layers because each catches what the previous cannot:

1. **parse** — every `.gd` compiles. A parse error hides until something loads
   the scene; `combat_arena.gd` was broken for six days behind a green data check.
2. **boot** — autoloads initialise and report their counts. A clean parse does
   not mean a clean boot.
3. **data** — `validate_data.py`: cross-references between JSON files, plus the
   reverse check (values declared in data that no code reads).
4. **verifiers** — the `verify_*.tscn` scenes, inside the engine against live
   autoloads. `validate_data.py` parses JSON in Python and never exercises a
   GDScript loader — which is how `animal_events.json` once loaded 0 of its 86
   events while the validator reported no issues.

Godot 4.7 reformats `races.json`, `statuses.json` and `project.godot` on open.
`verify_all.sh` restores them. Doing it by hand:

```bash
git checkout -- project.godot resources/data/races.json resources/data/statuses.json
```

`.godot/` is tracked, and `global_script_class_cache.cfg` must be committed
whenever a new `class_name` is added — otherwise the class fails to resolve at
runtime while the parse stays clean.

---

## Layout

```
scripts/autoload/    21 singletons — the game's systems
scripts/combat/      grid, units, arena, shared vocabularies
scripts/ui/  scripts/overworld/
resources/data/      all content as JSON
CONTENT.md           all the game's writing, kept in sync with the JSON (see below)
docs/superpowers/specs/   design docs for work not yet built
tools/               validators, verifiers, data authoring scripts
```

Systems worth knowing by name: `CharacterSystem` (stats, skills, party),
`CombatManager` (~8.5k lines; turn order, damage, spells, statuses, active
skills), `PerkSystem`, `KarmaSystem`, `EventManager`, `EnemySystem` (procedural
enemies from an XP budget), `PsychologySystem`, `TraitSystem`.

Two files exist to stop vocabulary drift, and are worth reading before adding a
stat or an area shape:

- `scripts/combat/combat_stats.gd` — the one list of stat and targeting names,
  each annotated with what consumes it.
- `scripts/autoload/aoe_resolver.gd` — every AoE shape, with a recipe for adding
  one, plus opt-in per-ring damage falloff.
- `scripts/combat/save_system.gd` — the one saving-throw mechanic. `d20 +
  defender attribute` vs `10 + attacker attribute + tier`.
- `scripts/combat/aura_system.gd` — proximity effects. Equipment, statuses,
  perks and units all declare an aura by naming one in
  `resources/data/auras.json`; spells reach them through the status they apply.

---

## Writing content

**`CONTENT.md`** at the project root holds all of the game's writing in one
place: realms, births, companions, skills, perks, spells, statuses, traits,
equipment, enemies, events and quests. Edit it there. The game itself only reads
the JSON in `resources/data/`, and a sync keeps the two in agreement.

- **Names, descriptions, flavour, bios and event text** are editable. Lines
  after a `—` and fields like costs and requirements are shown for context and
  are not imported; edit numbers in the JSON. `(empty)` marks a gap waiting
  for text.
- The **name** on an entry line is editable; the id in backticks is not.
- **`notes:`** works on any entry. It is kept by the sync and never reaches the
  game.
- **Merge conflict in `tools/content_base.json`?** It is only a snapshot: take
  either side, fix the JSON/CONTENT.md conflicts, then run
  `python3 tools/content_sync.py --rebase-base --write`, which rebuilds it from
  the JSON and the notes in CONTENT.md. (A plain `--write` refuses if it is missing.)
- **A blank line between two `>` lines** is a paragraph break, same as a lone `>`.
- **The Inbox** at the top is yours: write anything there, any shape, and use
  `##` for headings inside it. The sync never touches it. When you want Inbox
  items turned into data, ask Claude.
- **Group headings** (`## …`, `### …`) are placed by the id in backticks at
  their end, not by their title. Renaming a heading's title is harmless (the
  sync puts the generated title back); changing or deleting its backtick id
  is not — its entries can't be placed and move to the Inbox. To rename
  something, edit the title on its entry line.
- **Inside a `>` block**, every line should start with `>`. A line typed
  without it is still read as part of the block when it sits directly under
  a `>` line and is indented at least as far. Anything else the sync can't
  read inside an entry (a line at the left margin, a repeated field) means
  nothing from that entry is imported: the whole entry is copied to the
  Inbox to fix and paste back, and the original is put back as it was.
- **Two entries with the same id** (say, a pasted copy used as a template)
  import nothing; the edited copies go to the Inbox.
- **Lists** (`skills:`, `traits:`, item types) are comma separated. Ids are
  checked against the game's data: `Martial Arts` is read as `martial_arts`,
  and an id the game doesn't know stops the sync before anything is written.

After editing:

```bash
python3 tools/content_sync.py           # dry run: shows what would change
python3 tools/content_sync.py --write   # apply it
tools/verify_all.sh --quick             # always
```

If the same text was changed in both `CONTENT.md` and the JSON since the last
sync, that is a **conflict**: the sync prints both versions and writes nothing
at all. Fix one side and run it again. Anything the sync can't place (a broken
id, a new entry typed into a section) is moved to the Inbox with a note saying
where it was found — never dropped.

`verify_all.sh` runs `content_sync.py --check` and fails while `CONTENT.md`
and the JSON disagree, so nothing written in the document can be missing from
a build.

Perk mechanics (`combat_data` for actives, `effects` for passives) are edited
in `perks.json` directly. `validate_data.py` refuses what the engine cannot
consume — unknown stats, targeting, saves, statuses, triggers, payloads — and
`verify_passive_perks` refuses a perk wired both in data and by id in code.

### How to tune fight difficulty

Every number that decides how strong enemies are lives in one file,
`resources/data/enemies/encounter_budgets.json`. An enemy party is built from
an XP budget:

    realm_base  ×  encounter tier  ×  rolled band  ×  fight difficulty

- `realm_base` — how dangerous each world is. Fixed; it does not follow the
  player's strength.
- `tier_multipliers` — imp, shade, devil, boss, from the enemies in the fight.
- `bands` — the common/uncommon/rare roll and how often each comes up.
- `difficulty` — what the `easy` / `normal` / `hard` / `very_hard` / `boss`
  word on an event fight or map mob does. `xp_multiplier` is the main knob;
  `min_tier` and `band` are explained in the file's `_comment_difficulty`.
  Leave `normal` at 1.0 — every fight without a difficulty uses it.

More XP makes enemies stronger the way a stronger character is stronger (better
attributes, skills, gear, spells), and the party's reward is a fraction of it,
so a harder fight also pays more without a separate rule. After a change, run
`tools/verify_all.sh`: the validator rejects difficulty words the table does not
know, and `verify_enemy_xp` checks each tier still builds stronger parties than
the one below it.

---

## Design decisions that shape everything

- **No levels.** XP is spent directly on attributes and skills. Relative power
  is described in words ("slightly stronger"), never as a number.
- **Karma is hidden.** Every event choice moves it; the player is never shown it.
- **Party-wide checks.** If *any* party member meets a requirement, the choice
  opens — which is what makes companion selection matter.
- **Skills carry elements.** Each skill is tagged to one of five elements;
  levels in it accumulate as elemental affinity, which pays out its own bonuses.
- **Spells have multiple schools.** One matching skill at the required level
  lets you cast; every matching skill adds bonuses.
- **Ritual vs Yoga.** Ritual is external ceremony (circles, components); Yoga is
  internal cultivation (mantras, karma insight, pacifist options).

---

## Next

`TODO.md` is the live list — open work in Part I, settled-but-unbuilt designs in
Part II, and a changelog in Part IV. `docs/superpowers/specs/` holds designs
approved but not yet implemented. `CLAUDE.md` is the working agreement for
agents.
