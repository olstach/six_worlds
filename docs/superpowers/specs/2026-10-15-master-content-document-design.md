# One content document — `CONTENT.md`

**Status:** design approved in conversation 2026-10-15, awaiting spec review.

## Why

The game's writing is spread over about 40 markdown files: 13 generated
review documents, `PERKS.md`, `CHARACTERS.md`, loose content notes, and the
JSON itself. Olaf can't tell which copy is current or where a new idea should
go. He wants **one file** that holds all the writing, reads like a terse RPG
system manual, and takes a new companion, item, spell or line of flavour
whenever it occurs to him, with nothing to get wrong.

## What it is

- **`CONTENT.md` at the project root** is the source of truth for the game's
  writing for as long as development lasts.
- **Shipped builds read only the JSON** in `resources/data/`. A sync step keeps
  the JSON and the document in agreement, and `verify_all.sh` refuses a tree
  where they disagree. So nothing written in the document can be missing from
  a build.
- **Numbers stay in the JSON for now:** mana costs, damage, prices, stat
  tables. A balancing view can be generated later, as its own piece of work.
  The document shows a few numbers as context where they help with reading an
  entry (a spell's level, a companion's recruit cost), but you don't edit them
  there.

## Shape of the file

Nested lists rather than tables: they're easier to edit in markdown, and gaps
or imbalances show up as you scan down a list.

```
# Inbox        free-form; never regenerated
# World        realms, zones, landmarks, settlement names
# Births       races, the backgrounds only they can take, naming lore
# Companions   by realm → birth
# Skills       the 35, with per-level flavour
# Perks        by skill → tier
# Spells       by school → level
# Statuses
# Traits       by category
# Equipment    weapons, armour, talismans, implements, consumables, ammo,
#              materials and the procedural name/affix tables
# Enemies      archetypes and encounters, by realm → region
# Events       by realm → zone, then domain / camp / trait events
# Quests
```

### An entry

```markdown
### Snow Lion `snow_lion`
- **Tenzin** `tenzin`
  - flavor: A mane gone grey at the tips; still roars at dawn.
  - skills: swords, yoga, leadership, persuasion
  - traits: proud, devout
  - recruit: 140 gold · teahouse
  - bio:
    > Two or more paragraphs go in a quote block.
    >
    > Blank lines inside are fine.
  - notes: free text about this entry; never reaches the game
```

- **The address is the structure.** Each heading or bold line carries the
  record's id in backticks. `- key: value` lines are its fields. There are no
  hidden markers.
- **The name on the bold line is editable. The id in backticks is not.**
- **Each kind of entry has a schema** saying which keys are *writing*
  (editable, imported) and which are *context* (shown, never imported).
  Writing: names, `desc`, `flavor`, `bio`, event text, choice text, result
  text, plus a few simple lists whose meaning is obvious, such as a
  companion's `skills` (strongest first, which rebuilds `build_weights` the
  way the review docs already do) and `traits`. Context: costs, requirements,
  rewards, stats, levels.
- **`(empty)`** marks a writing field with no text, so the gaps are easy to see.
- **`notes:`** works on any entry: free text that is kept by the sync and
  never reaches the game. It replaces the review workbooks' Notes sections
  and the `_comment` design notes that are worth keeping.
- **Long text** goes in a `>` quote block under its key.

### The Inbox

A section at the top with no rules at all: a half-sentence, a full
companion, a list of item names. The sync never rewrites it. When Olaf asks,
Claude turns entries into data. They then appear in their proper section and
are deleted from the Inbox.

## The sync — `tools/content_sync.py`

One command. A dry run by default; `--write` applies it.

1. **Parse** `CONTENT.md` into entries, keyed by section path and id.
2. **Three-way compare** every writing field against the JSON *and* against
   `tools/content_base.json`, the value both sides held at the last sync:
   - doc changed, JSON didn't → **import** into the JSON;
   - JSON changed, doc didn't → keep the JSON; step 4 shows it in the doc;
   - both changed, to different values → **conflict**: print both versions,
     write nothing at all;
   - a context field edited in the doc → report "ignored: context field" and
     carry on.
3. **Anything the parser can't place is moved to the Inbox, not dropped.**
   That covers an entry with an unknown or missing id, a heading whose id was
   edited, or a stray line. Each one gets a one-line note saying where it was
   found. A brand-new `- **Name**` line typed into the Spells section lands in
   the Inbox the same way, ready to be turned into data.
4. **Regenerate** `CONTENT.md` from the JSON (with the Inbox and `notes:`
   carried over verbatim), and update `content_base.json`.
5. **Print a summary:** fields imported, ignored, moved to the Inbox, and any
   conflicts.

`notes:` text and the base snapshot are machine files kept beside the tool:
`tools/content_base.json` holds both, and it is tracked in git.

### Guard in `verify_all.sh`

The data layer runs `content_sync.py --check`. It fails if there is any
pending import, conflict or regeneration difference, and tells you to run
`tools/content_sync.py --write`. Inbox contents never fail the check.

## Migration

1. **Import any pending review-doc edits first.** Run
   `import_review_docs.py`. If its dry run shows changes, apply them before
   anything else, so nothing written in `docs/review/` is lost.
2. **Build the exporter** for every section above. The existing
   `export_review_docs.py` already covers events, traits and the animal realm,
   and its formatting rules (reward and requirement lines, choice colours,
   name blocks) are reused rather than rewritten.
3. **Carry over text that exists only in markdown.** This covers the
   review-workbook Notes sections, anything in `PERKS.md`, `CHARACTERS.md`,
   `docs/BACKGROUNDS_BY_BIRTH.md`, `docs/companion_quirks.md` and
   `resources/data/events/hungry_ghost_events_plan.md` that is not already in
   the JSON, and `EDIT_LATER.md`'s wound notes recovered from git (deleted in
   `53adfa9`). Each piece goes under `notes:` on the entry it belongs to, or
   into the Inbox when it belongs to nothing yet. The migration prints a list
   of what moved where.
4. **Delete:**
   - all of `docs/review/`;
   - `export_review_docs.py` and `import_review_docs.py`;
   - `PERKS.md`;
   - `CHARACTERS.md`;
   - the loose content files above;
   - `parse_perks.py`, which regenerates `perks.json` *from* `PERKS.md` and
     would now overwrite the data if anyone ran it;
   - the three one-shot `PERKS.md` scripts (`remap_perk_levels.py`,
     `shift_perk_levels.py`, `extend_tables.py`), which point at a path from
     an older checkout.
5. **Update the references.** `README.md`, `TODO.md`, `CLAUDE.md` and
   `.claude/skills/` should all point at `CONTENT.md` and the sync. Drop
   `CLAUDE.md`'s pointer to `SPECIFICATION/chat1.txt`. That file was never in
   git, so if Olaf still has the spell list it goes in the Inbox.

## Not in scope

- **A numbers or balancing view.** It comes later and can be generated from
  the same exporter.
- **`docs/plans/` and `docs/superpowers/`.** These are design history, not
  content. Folding them in would bury the writing under rationale. A separate
  cleanup can delete the built ones; git keeps them. `ECONOMY_DESIGN.md` and
  `ECONOMY_FLOWS.md` are cited from code comments, so they stay.
- **`docs/SIX_WORLDS_COMPOSER_BRIEF.md`.** It is a brief for a composer, not
  game content. It stays where it is unless Olaf wants it folded in.
- **Creating new records from structured text.** New things go through the
  Inbox and Claude; the sync never creates records on its own.

## Testing

`tools/test_content_sync.py` runs in `verify_all.sh`'s data layer, against a
scratch copy of the data:

- **round-trip:** export, parse and export again gives an identical file,
  with no pending changes;
- **one edit:** changing one writing field imports exactly that field;
- **context edit:** changing a context field imports nothing and reports it;
- **conflict:** changing the same field in both places writes nothing and
  exits non-zero;
- **unplaceable text:** an entry with a broken id and a new `- **Name**`
  line both end up in the Inbox with location notes, and nothing is lost;
- **Inbox and notes:** both survive regeneration byte for byte;
- **companion skills:** editing the skills list rebuilds `build_weights`
  5/4/3/2, and leaving it untouched leaves the weights untouched.

## Size

The file will run to roughly 70,000 lines, most of them events. Every editor
Olaf is likely to use (Obsidian, VS Code) shows the heading outline for
navigation, so the length is fine. If it ever isn't, the exporter can split by
top-level section without changing the format.
