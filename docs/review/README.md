# Review documents

Generated prose for reading and editing away from the JSON. Six files:

| File | Contents |
|---|---|
| `ANIMAL_COMPANIONS.md` | 24 animal-realm companions — all Claude's, none edited |
| `TRAITS.md` | 107 traits by category, with their mechanics |
| `EVENTS_HELL.md` | 79 events |
| `EVENTS_HUNGRY_GHOST.md` | 150 events |
| `EVENTS_ANIMAL.md` | 94 events |
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

## What the markers mean

- **NEW EVENT** — the whole event was written in the 2026-07-27 sessions.
- **NEW** — an individual choice added to an event that already existed. In
  `EVENTS_HELL.md` these are the trait-gated choices from the sweep, which are
  the only part of hell not already edited.
- Choice colour is shown as *grey* (always available), *blue* (requirement) or
  *yellow* (roll), with the requirement spelled out.
- Choices with no `id` in the data are addressed by position, e.g. `[0]`. That
  is 72 choices across 36 location events (teahouses, guilds, shrines) — benign
  in game, since those locations are meant to be re-enterable and the engine
  skips use-tracking when the id is empty.
