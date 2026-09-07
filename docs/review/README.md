# Review documents

Generated prose for reading and editing away from the JSON. Thirteen files.

**Births and backgrounds — one document per realm:**

| File | Contents |
|---|---|
| `ANIMAL_RACES.md` | 18 births and the 67 backgrounds anchored here |
| `HELL_RACES.md` | 13 births — six devils, six imps, the wretch — and 28 backgrounds |
| `HUNGRY_GHOST_RACES.md` | 16 births and 20 backgrounds |

A background open to births in more than one realm is anchored in exactly one
of these documents and merely listed in the others, under **Backgrounds edited
elsewhere**. That is deliberate: the importer reads every file in the directory
in filename order against a single copy of `races.json`, so a second anchor for
the same field would let an unedited document quietly revert an edit made in
the other one. Edit a background where its anchors are.

**The rest of the animal realm:**

| File | Contents |
|---|---|
| `ANIMAL_COMPANIONS.md` | 24 companions — flavour, description, recruitment, skill builds |
| `ANIMAL_ENEMIES.md` | 34 archetypes across 42 encounter templates, by region |
| `ANIMAL_LOCATIONS.md` | 30 places you can walk into — teahouses, guilds, shrines, merchants |
| `ANIMAL_WORLD.md` | The realm blurb, its 5 zones, the fixed landmarks, 15 settlement names |
| `ANIMAL_NAMES.md` | Naming lore — how each birth names itself, 389 names and meanings |
| `EVENTS_ANIMAL.md` | 94 events |

**Everything else:**

| File | Contents |
|---|---|
| `TRAITS.md` | 108 traits by category, with their mechanics — all realms |
| `EVENTS_HELL.md` | 79 events |
| `EVENTS_HUNGRY_GHOST.md` | 150 events |
| `EVENTS_DOMAIN.md` | 33 cross-realm: plain, camp, trait- and relationship-triggered |

## How to edit

Every editable string sits between anchors naming its exact place in the data:

```
<!--@ hell_events.json | hell_bone_arena | title -->
Bone Arena
<!--@end-->
```

The anchors are HTML comments, so they do not render — the documents read as
prose in any Markdown viewer.

- **Change anything between an anchor and its `@end`.** Multiple paragraphs and
  blank lines are fine.
- **Do not change the anchor lines**, or the ids in headings.
- Everything outside the anchors — headings, the `mechanical lines`, tables —
  is generated from the data and will be overwritten on the next export.

## Getting edits back into the game

```bash
python3 tools/import_review_docs.py            # dry run: show every change
python3 tools/import_review_docs.py --write    # apply them
python3 tools/validate_data.py                 # always, afterwards
```

The importer prints a before/after line for each change, so the dry run is
worth reading before applying. It exits non-zero if any anchor cannot be
matched to a record, which is the signal that an anchor line was edited or a
record was renamed.

To regenerate the documents after the data changes:

```bash
python3 tools/export_review_docs.py
```

**Regenerating discards anything you have written but not imported** — import
first, then re-export.

## Companion skills

`ANIMAL_COMPANIONS.md` shows each companion's **Skills** as a comma list,
strongest first. That list is `build_weights` — what the companion develops
into as they earn XP, and what their random spell schools are drawn from.

Edit the list and the importer rebuilds the weighting, 5/4/3/2 down the order.
Leave it untouched and nothing is rewritten, so re-importing a document you
only changed the prose in will not disturb existing weightings.

## Design notes and `_comment` fields

Some anchors are labelled *design comment, not shown in game* — zone notes, the
archetype notes, the settlement naming note. They are editable like anything
else and they are worth keeping accurate, because they are the description the
map and the bestiary are generated against. They just never reach the player.

## What the markers mean

- **NEW EVENT** / **NEW** — content added since a base snapshot of the data.
  No snapshot is configured by default, so nothing is currently marked. To turn
  the markers back on, copy the JSON files you want to compare against into a
  directory and export with `REVIEW_BASE_SNAPSHOT=/path/to/that/dir`.
- Choice colour is shown as *grey* (always available), *blue* (requirement) or
  *yellow* (roll), with the requirement spelled out.
- Choices with no `id` in the data are addressed by position, e.g. `[0]`. That
  is 72 choices across 36 location events (teahouses, guilds, shrines) — benign
  in game, since those locations are meant to be re-enterable and the engine
  skips use-tracking when the id is empty.
