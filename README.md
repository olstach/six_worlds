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
docs/review/         content prose, round-trips to JSON (see below)
docs/superpowers/specs/   design docs for work not yet built
docs/MAP_TILES_ART_BRIEF.md  spec for drawing the overworld map tiles
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

## Editing content

Prose lives in `docs/review/` as Markdown and round-trips to JSON. Edit between
the anchors, then:

```bash
python3 tools/import_review_docs.py           # dry run
python3 tools/import_review_docs.py --write   # apply
tools/verify_all.sh --quick                   # always
```

`docs/review/README.md` has the rules. Claude's unedited prose is marked
**NEW EVENT** / **NEW** — those want Olaf's pass.

`PERKS.md` and `CHARACTERS.md` are hand-maintained design sources, not
generated; they do not round-trip.

Perk mechanics are authored through `tools/wire_active_perks.py` and
`tools/wire_passive_perks.py`, which regenerate `perks.json` and refuse data the
engine cannot consume.

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
