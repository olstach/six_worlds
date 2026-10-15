# CONTENT.md Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One editable markdown file, `CONTENT.md`, holding all the game's writing, kept in agreement with `resources/data/*.json` by a single three-way sync command and guarded by `verify_all.sh`.

**Architecture:** A small Python package, `tools/content/`, does four jobs. Section modules turn JSON records into `Entry` trees. A renderer and a parser convert between `Entry` trees and markdown. A sync engine compares doc ↔ JSON ↔ last-synced base and applies the result. A canonical JSON writer keeps data files byte-stable. `tools/content_sync.py` is the CLI on top. The old `docs/review/` round-trip is retired once the new one reproduces everything it covered.

**Tech Stack:** Python 3.12 stdlib only (`json`, `re`, `dataclasses`, `unittest`, `argparse`, `tempfile`, `shutil`). Godot is not involved in this plan except through `tools/verify_all.sh`.

**Spec:** `docs/superpowers/specs/2026-10-15-master-content-document-design.md`

## Global Constraints

- The document is `CONTENT.md` at the project root. The sync is `tools/content_sync.py`. The base snapshot (with `notes:` text) is `tools/content_base.json`, tracked in git.
- Top-level sections, in this order: Inbox, World, Births, Companions, Skills, Perks, Spells, Statuses, Traits, Equipment, Enemies, Events, Quests.
- Writing fields are imported. Context fields are shown and never imported; editing one is reported as "ignored: context field".
- `(empty)` is how an empty writing field is shown.
- `notes:` is allowed on any entry. It is stored only in `tools/content_base.json` and never reaches the JSON.
- The Inbox is never rewritten by the sync.
- Unplaceable text is moved to the Inbox with a location note. It is never dropped.
- A conflict (both sides changed the same field to different values) writes nothing at all and exits non-zero.
- Dry run is the default. `--write` applies. `--check` is for `verify_all.sh`.
- Companion `skills` list ↔ `build_weights`: weights 5/4/3/2 down the order, then 1 for any further entries. An untouched list never rewrites weights.
- Standard library only. No `pip install`.
- JSON keys beginning with `_` are comments. Never treat them as records. `_comment` values are shown as `notes`-like context only where the section module says so.
- Code comments are clear and beginner-friendly. Olaf is a beginner-intermediate programmer.

## Review Focus

1. **Obsidian indents nested lists with tabs, and editors may save CRLF line endings.** The parser must treat a tab as one indent step and accept `\r\n`, and an entry typed with tabs must import exactly as if typed with spaces. (Test in Task 2.)
2. **Olaf edits an id, deletes a backtick, or types a new `- **Name**` line inside a section.** The text must land in the Inbox with "found under Spells › Fire Magic › Level 3", and the original entry must regenerate. Nothing is lost. (Test in Task 4.)
3. **Unicode in names and prose (ā, ñ, em dashes, Tibetan transliteration, emoji)** must survive doc → JSON → doc byte for byte, and the JSON must not gain `\uXXXX` escapes. (Test in Task 1 and Task 2.)
4. **An agent edits the JSON while Olaf edits the doc.** Different fields merge cleanly. The same field conflicts and writes nothing. (Test in Task 4.)
5. **A writing field whose text contains markdown-significant content:** a line starting with `- `, a line starting with `>`, a ` — `, a backtick, or a `#`. It must round-trip through a `>` block without being parsed as structure. (Test in Task 2.)

---

## File Structure

```
tools/
  content_sync.py                 CLI: dry run / --write / --check
  content_base.json               last-synced field values + notes (generated, tracked)
  content/
    __init__.py
    model.py                      Entry, Field dataclasses; key helpers
    jsonio.py                     load data files; canonical writer; per-file indent
    mdformat.py                   render(Doc) -> str ; parse(str) -> Doc
    sync.py                       export_all(), merge(), apply(), the three-way rules
    sections/
      __init__.py                 SECTIONS: ordered list of section modules
      world.py                    map_configs (realm blurb, zones, landmarks,
                                  settlement names), terrain, domains
      births.py                   races, backgrounds, naming lore
      companions.py               companions by realm -> birth
      skills.py                   skills + elements
      perks.py                    skill_perks by skill -> required_level, cross_perks
      spells.py                   spells by first school -> level
      statuses.py                 statuses
      traits.py                   traits by category
      equipment.py                items by type, ammo, materials, weapon/armor bases
                                  and traits, talisman perks/name parts, upgrades
      enemies.py                  archetypes + encounters by realm -> region,
                                  summon templates, enemy name parts
      events.py                   events by realm -> zone, shops (places)
      quests.py                   quests
  test_content_model.py           Tasks 1-2
  test_content_sync.py            Tasks 4, 6
  test_content_sections.py        Task 5 (round-trip over the real data)
```

`tools/export_review_docs.py` and `tools/import_review_docs.py` stay untouched until Task 8 deletes them. Their formatting helpers (`reward_line`, `req_line`, `CHOICE_LABEL`, name-block handling) are **copied** into the new section modules, not imported, so the deletion in Task 8 breaks nothing.

---

### Task 1: Model and canonical JSON IO

**Files:**
- Create: `tools/content/__init__.py` (empty), `tools/content/model.py`, `tools/content/jsonio.py`
- Test: `tools/test_content_model.py`

**Interfaces:**
- Produces:
  - `model.Field(name: str, value: str | list[str], kind: Literal["text","list","context"], path: tuple)`. `path` is the JSON address `(rel_file, *keys)` that `jsonio.get_at`/`set_at` resolve. `kind="context"` fields have `path=()`.
  - `model.Entry(key: str, title: str, title_path: tuple, ident: str, tag: str = "", context: str = "", fields: list[Field] = [], children: list[Entry] = [], notes: str = "")`. `key` is globally unique, e.g. `"spells:fireball"` or `"events:hell_bone_arena/choices:fight"`. `title` is editable when `title_path` is non-empty. `ident` is what the doc shows in backticks. `tag` is the optional `[grey]` prefix. `context` is the read-only text after ` — `.
  - `model.Group(title: str, ident: str = "", level: int, entries: list[Entry], groups: list[Group])`: a heading.
  - `model.Doc(inbox: str, sections: list[Group])`.
  - `jsonio.DataSet`: `load(root: Path) -> DataSet`, `.get(rel) -> object`, `.get_at(path) -> object`, `.set_at(path, value) -> None` (marks the file dirty), `.write_dirty() -> list[str]` (returns the rel paths written).
  - `jsonio.canonical_dumps(obj, indent: str | int) -> str` and `jsonio.detect_indent(text) -> str | int`.

- [ ] **Step 1: Write the failing tests**

```python
# tools/test_content_model.py
import json, os, sys, tempfile, shutil, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio
ROOT = Path(__file__).resolve().parent.parent

class JsonIOTests(unittest.TestCase):
    def test_detect_indent(self):
        self.assertEqual(jsonio.detect_indent('{\n\t"a": 1\n}\n'), "\t")
        self.assertEqual(jsonio.detect_indent('{\n  "a": {\n    "b": 1\n  }\n}\n'), 2)

    def test_canonical_is_stable_and_unescaped(self):
        obj = {"name": "Pāramitā — ✨", "n": [1, 2]}
        once = jsonio.canonical_dumps(obj, 2)
        self.assertIn("Pāramitā — ✨", once)          # no \\u escapes
        self.assertEqual(jsonio.canonical_dumps(json.loads(once), 2), once)
        self.assertTrue(once.endswith("\n"))

    def test_set_at_writes_only_dirty_file(self):
        tmp = Path(tempfile.mkdtemp())
        shutil.copytree(ROOT / "resources/data", tmp / "resources/data")
        ds = jsonio.DataSet.load(tmp)
        path = ("resources/data/skills.json", "skills", "swords", "description")
        ds.set_at(path, "Edited.")
        self.assertEqual(ds.write_dirty(), ["resources/data/skills.json"])
        again = jsonio.DataSet.load(tmp)
        self.assertEqual(again.get_at(path), "Edited.")

    def test_list_index_paths(self):
        ds = jsonio.DataSet.load(ROOT)
        first = ds.get_at(("resources/data/statuses.json", "statuses", 0, "name"))
        self.assertIsInstance(first, str)

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run them and check that they fail**

Run: `python3 tools/test_content_model.py -v`
Expected: `ModuleNotFoundError: No module named 'content'`

- [ ] **Step 3: Implement**

```python
# tools/content/jsonio.py
"""Loading and writing the game's JSON data without disturbing its formatting.

Every data file is written back in one canonical style: its own indent unit
(tabs for the files Godot reformatted, two spaces for the rest), keys in their
existing order, real UTF-8 characters rather than \\u escapes, and a trailing
newline. Writing a file we did not change would be noise, so only files that
were actually edited are written.
"""
import json
from pathlib import Path

DATA = "resources/data"


def detect_indent(text: str):
    """Tab if most indented lines start with a tab, otherwise the smallest
    space indent seen (2 in this project)."""
    tabs = spaces = 0
    smallest = None
    for line in text.splitlines():
        stripped = line.lstrip(" \t")
        if not stripped or len(stripped) == len(line):
            continue
        if line[0] == "\t":
            tabs += 1
        else:
            spaces += 1
            width = len(line) - len(stripped)
            smallest = width if smallest is None else min(smallest, width)
    if tabs > spaces:
        return "\t"
    return smallest or 2


def canonical_dumps(obj, indent) -> str:
    return json.dumps(obj, indent=indent, ensure_ascii=False) + "\n"


class DataSet:
    """All JSON under resources/data, addressable by (rel_file, *keys)."""

    def __init__(self, root: Path):
        self.root = Path(root)
        self._docs: dict[str, object] = {}
        self._indent: dict[str, object] = {}
        self._dirty: set[str] = set()

    @classmethod
    def load(cls, root) -> "DataSet":
        ds = cls(root)
        for p in sorted((ds.root / DATA).rglob("*.json")):
            rel = p.relative_to(ds.root).as_posix()
            text = p.read_text(encoding="utf-8")
            ds._docs[rel] = json.loads(text)
            ds._indent[rel] = detect_indent(text)
        return ds

    def get(self, rel: str):
        return self._docs[rel]

    def files(self) -> list[str]:
        return list(self._docs)

    def get_at(self, path: tuple):
        node = self._docs[path[0]]
        for k in path[1:]:
            node = node[k]
        return node

    def set_at(self, path: tuple, value) -> None:
        node = self._docs[path[0]]
        for k in path[1:-1]:
            node = node[k]
        node[path[-1]] = value
        self._dirty.add(path[0])

    def write_dirty(self) -> list[str]:
        written = []
        for rel in sorted(self._dirty):
            (self.root / rel).write_text(
                canonical_dumps(self._docs[rel], self._indent[rel]), encoding="utf-8")
            written.append(rel)
        self._dirty.clear()
        return written
```

```python
# tools/content/model.py
"""The shapes CONTENT.md is built from.

An Entry is one record (a spell, a companion, an event, a choice inside an
event). Its Fields are the lines under it. Groups are headings. A Doc is the
whole file: the Inbox text plus the section headings.
"""
from dataclasses import dataclass, field
from typing import Literal

EMPTY = "(empty)"


@dataclass
class Field:
    name: str
    value: object                 # str for text/context, list[str] for list
    kind: Literal["text", "list", "context"] = "text"
    path: tuple = ()              # JSON address; () for context fields


@dataclass
class Entry:
    key: str                      # unique, e.g. "spells:fireball"
    title: str
    ident: str                    # shown in backticks
    title_path: tuple = ()        # JSON address of the title; () = not editable
    tag: str = ""                 # e.g. "grey" -> "[grey] "
    context: str = ""             # read-only text after " — "
    fields: list = field(default_factory=list)
    children: list = field(default_factory=list)   # child Entries ("choices")
    children_label: str = ""      # the key line children hang under
    notes: str = ""


@dataclass
class Group:
    title: str
    level: int                    # 1 = "#", 2 = "##", ...
    ident: str = ""
    entries: list = field(default_factory=list)
    groups: list = field(default_factory=list)


@dataclass
class Doc:
    inbox: str = ""
    sections: list = field(default_factory=list)
```

- [ ] **Step 4: Run them and check that they pass**

Run: `python3 tools/test_content_model.py -v`
Expected: 4 tests OK.

- [ ] **Step 5: Commit**

```bash
git add tools/content/__init__.py tools/content/model.py tools/content/jsonio.py tools/test_content_model.py
git commit -m "content: entry model and a canonical JSON reader/writer"
```

---

### Task 2: The markdown format — render and parse

**Files:**
- Create: `tools/content/mdformat.py`
- Test: `tools/test_content_model.py` (add `FormatTests`)

**Interfaces:**
- Consumes: `model.Doc/Group/Entry/Field`, `model.EMPTY`.
- Produces:
  - `mdformat.render(doc: Doc) -> str`.
  - `mdformat.parse(text: str) -> ParsedDoc`, where `ParsedDoc` has these fields:
    - `inbox: str`, verbatim;
    - `entries: dict[str, ParsedEntry]`, keyed by **location key** `"<section path> › <ident path>"`. The sync maps location keys to entry keys; see Task 4;
    - `stray: list[tuple[str, str]]`, each a (location label, raw text) pair.
  - `ParsedEntry(ident, title, tag, fields: dict[str, str | list[str]], children: list[ParsedEntry], children_label: str, notes: str, raw: str, location: str)`.

**The grammar.** It is the only format, and the renderer must produce exactly this:

```
# Inbox
<anything; everything until the next line that is exactly "# World">

# World                                   <- level-1 headings: the fixed section list
## Animal realm `animal`                  <- groups: "#"*n + title + optional `ident`
- **Name** `ident` — read-only context    <- entry: "- " [ "[tag] " ] title " `ident`" [ " — " context ]
  - flavor: one-line text                 <- field: 2 more spaces, "- key: value"
  - skills: swords, yoga                  <- list field: comma + space separated
  - desc: (empty)                         <- empty writing field
  - bio:                                  <- block field: nothing after the colon...
    > first paragraph                     <- ...then "> " lines at +4 spaces
    >
    > second paragraph
  - choices:                              <- children label
    - [grey] Watch from the stands `watch`  <- child entry at +4 spaces
      - result: You learn nothing.
  - notes: free text, never reaches the game
```

Rules:
- An entry's title may be wrapped in `**…**`. The parser strips it. The renderer bolds top-level entry titles and leaves child titles plain.
- The ident is the **last** backtick token on the entry line before an optional ` — `. Titles never contain backticks: the renderer replaces a backtick in a title with `'`, and section modules must not emit editable titles that contain one. Task 5 checks this against the real data.
- Text that contains a newline, starts with `>`, `- `, `#` or a space, or is longer than 160 characters is rendered as a `>` block. Everything else is inline.
- `(empty)` ⇔ `""`. A list field renders `(empty)` for `[]`.
- Indentation: one level is 2 spaces **or** one tab. Blocks are one level deeper than their key line. The parser expands each leading tab to 2 spaces before measuring. It also accepts `\r\n`.
- Any line inside a section that matches none of the shapes above, at any depth, goes to `stray` with the location of the nearest group/entry above it. The parser never raises on content.
- `notes` is an ordinary field key at parse time. The renderer always writes `notes` last.

- [ ] **Step 1: Write the failing tests**

```python
# add to tools/test_content_model.py
from content import mdformat
from content.model import Doc, Group, Entry, Field

def sample_doc():
    choice = Entry(key="events:e1/choices:watch", title="Watch from the stands",
                   ident="watch", tag="grey",
                   fields=[Field("result", "You learn nothing.", "text", ("f", "r"))])
    e = Entry(key="events:e1", title="Bone Arena", ident="e1", title_path=("f", "t"),
              context="realm: hell",
              fields=[Field("text", "Line one.\n\nLine two — with - dash\n- not a list",
                            "text", ("f", "x")),
                      Field("skills", ["swords", "yoga"], "list", ("f", "s")),
                      Field("flavor", "", "text", ("f", "fl")),
                      Field("cost", "140 gold", "context")],
              children=[choice], children_label="choices", notes="keep this")
    return Doc(inbox="raw idea: a goat oracle\n\n- with a list",
               sections=[Group("Events", 1, groups=[Group("Hell", 2, "hell", entries=[e])])])

class FormatTests(unittest.TestCase):
    def test_round_trip(self):
        text = mdformat.render(sample_doc())
        p = mdformat.parse(text)
        self.assertEqual(p.inbox.strip(), "raw idea: a goat oracle\n\n- with a list")
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["text"], "Line one.\n\nLine two — with - dash\n- not a list")
        self.assertEqual(entry.fields["skills"], ["swords", "yoga"])
        self.assertEqual(entry.fields["flavor"], "")
        self.assertEqual(entry.notes, "keep this")
        self.assertEqual(entry.children[0].fields["result"], "You learn nothing.")
        self.assertEqual(entry.children[0].tag, "grey")
        self.assertEqual(mdformat.render(sample_doc()), text)    # deterministic
        self.assertEqual(p.stray, [])

    def test_tabs_and_crlf(self):
        text = mdformat.render(sample_doc()).replace("  ", "\t").replace("\n", "\r\n")
        p = mdformat.parse(text)
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["skills"], ["swords", "yoga"])
        self.assertEqual(entry.children[0].fields["result"], "You learn nothing.")

    def test_unicode_survives(self):
        d = sample_doc()
        d.sections[0].groups[0].entries[0].fields[0].value = "Pāramitā ✨ — `odd`"
        p = mdformat.parse(mdformat.render(d))
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["text"], "Pāramitā ✨ — `odd`")

    def test_stray_line_is_collected_not_raised(self):
        text = mdformat.render(sample_doc()).replace(
            "  - notes:", "this line is nonsense\n  - notes:")
        p = mdformat.parse(text)
        self.assertEqual(len(p.stray), 1)
        self.assertIn("Events › Hell", p.stray[0][0])
```

- [ ] **Step 2: Run them and check that they fail**

Run: `python3 tools/test_content_model.py -v`
Expected: `ImportError: cannot import name 'mdformat'`

- [ ] **Step 3: Implement `tools/content/mdformat.py`** to the grammar above. Required structure:
  - `render(doc)`:
    - write `# Inbox\n\n` + inbox (stripped, then `\n\n`);
    - then each `Group` recursively: a heading line, a blank line, its entries, a blank line, its subgroups;
    - `_render_entry(entry, depth)` writes the entry line, then each field (block or inline), then `children_label:` and the children at depth+2, then `notes` if non-empty. A `context` Field renders like a text field.
  - `parse(text)`:
    - normalise `\r\n` → `\n`; split off the Inbox (everything after `# Inbox` up to the first line that equals `# World`);
    - then walk the lines with a stack of `(indent, node)`, tracking the current heading path for location labels;
    - entry line regex: `^(?P<ind> *)- (?:\[(?P<tag>[^\]]+)\] )?(?P<title>.*?) `(?P<ident>[^`]+)`(?: — (?P<ctx>.*))?$`;
    - field line regex: `^(?P<ind> *)- (?P<key>[a-z_][a-z0-9_]*):(?: (?P<val>.*))?$`;
    - block line regex: `^(?P<ind> *)>(?: (?P<txt>.*))?$`;
    - heading regex: `^(?P<hashes>#{1,6}) (?P<title>.*?)(?: `(?P<ident>[^`]+)`)?$`;
    - the location key is `" › ".join(heading titles) + " › " + "/".join(entry idents from the outermost entry down)`;
    - `ParsedEntry.raw` keeps the exact source lines of the entry, so the sync can move it to the Inbox verbatim.
  - List values split on `", "` and are stripped. `(empty)` gives `[]`.
  - A field whose key is followed by children (an entry line one level deeper) is the `children_label`.

- [ ] **Step 4: Run them and check that they pass**

Run: `python3 tools/test_content_model.py -v`
Expected: all tests OK.

- [ ] **Step 5: Commit**

```bash
git add tools/content/mdformat.py tools/test_content_model.py
git commit -m "content: the CONTENT.md grammar — render and a parser that never drops text"
```

---

### Task 3: First section module (traits) and the section interface

**Files:**
- Create: `tools/content/sections/__init__.py`, `tools/content/sections/traits.py`
- Test: `tools/test_content_sections.py`

**Interfaces:**
- Consumes: `jsonio.DataSet`, `model.*`.
- Produces: the **section contract** every later section module follows:
  - `TITLE: str`, the level-1 heading (e.g. `"Traits"`).
  - `build(ds: DataSet) -> Group`, a level-1 Group holding subgroups and entries. It must be deterministic: sort by the data's own order, never by `set` iteration.
  - `import_field(ds: DataSet, entry_key: str, field: Field, new_value) -> None`, optional. It is only needed when a field's import is more than `ds.set_at(field.path, new_value)`; companions' `skills` → `build_weights` is the one case. Default: `ds.set_at`.
  - `sections.SECTIONS: list[module]` in the global order (Inbox is not a module).

- [ ] **Step 1: Write the failing test**

```python
# tools/test_content_sections.py
import os, sys, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat
from content.model import Doc
from content.sections import SECTIONS
ROOT = Path(__file__).resolve().parent.parent

def walk(group):
    for e in group.entries:
        yield e
        yield from e.children
    for g in group.groups:
        yield from walk(g)

class SectionRoundTrip(unittest.TestCase):
    def test_every_section_round_trips_over_real_data(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in SECTIONS:
            with self.subTest(section=mod.TITLE):
                group = mod.build(ds)
                text = mdformat.render(Doc(sections=[group]))
                parsed = mdformat.parse(text)
                self.assertEqual(parsed.stray, [], mod.TITLE)
                keys = [e.key for e in walk(group)]
                self.assertEqual(len(keys), len(set(keys)), "duplicate entry keys")
                for e in walk(group):
                    self.assertNotIn("`", e.title, e.key)
                    for f in e.fields:
                        if f.kind != "context":
                            self.assertEqual(ds.get_at(f.path) if f.kind == "text"
                                             else f.value, f.value, (e.key, f.name))
                self.assertEqual(mdformat.render(Doc(sections=[mod.build(ds)])), text)

    def test_traits_cover_every_trait(self):
        ds = jsonio.DataSet.load(ROOT)
        from content.sections import traits
        n = sum(1 for _ in walk(traits.build(ds)))
        real = [k for k in ds.get("resources/data/traits.json") if not k.startswith("_")]
        self.assertEqual(n, len(real))

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run it and check that it fails**

Run: `python3 tools/test_content_sections.py -v`
Expected: `ModuleNotFoundError: No module named 'content.sections'`

- [ ] **Step 3: Implement**

```python
# tools/content/sections/traits.py
"""Traits, grouped by category. Name and description are writing; the
mechanical blocks are shown as one context line so balance is visible while
reading."""
from ..model import Entry, Field, Group

TITLE = "Traits"
FILE = "resources/data/traits.json"


def build(ds) -> Group:
    data = ds.get(FILE)
    by_cat: dict[str, list] = {}
    for tid, t in data.items():
        if tid.startswith("_") or not isinstance(t, dict):
            continue
        by_cat.setdefault(t.get("category", "other"), []).append((tid, t))
    top = Group(TITLE, 1)
    for cat, items in by_cat.items():
        g = Group(cat.replace("_", " ").capitalize(), 2, cat)
        for tid, t in items:
            ctx = []
            if t.get("inborn"):
                ctx.append("inborn")
            if t.get("stat_modifiers"):
                ctx.append(", ".join(f"{k} {v:+g}" for k, v in t["stat_modifiers"].items()))
            g.entries.append(Entry(
                key=f"traits:{tid}", title=t.get("name", tid), ident=tid,
                title_path=(FILE, tid, "name"), context=" · ".join(ctx),
                fields=[Field("desc", t.get("description", ""), "text",
                              (FILE, tid, "description"))]))
        top.groups.append(g)
    return top
```

```python
# tools/content/sections/__init__.py
"""The sections of CONTENT.md, in document order. The Inbox is not a module:
the sync carries it over verbatim."""
from . import traits

SECTIONS = [traits]   # Task 5 extends this to the full ordered list
```

- [ ] **Step 4: Run it and check that it passes**

Run: `python3 tools/test_content_sections.py -v`
Expected: 2 tests OK.

- [ ] **Step 5: Commit**

```bash
git add tools/content/sections tools/test_content_sections.py
git commit -m "content: the section contract, and traits as its first section"
```

---

### Task 4: The sync engine and CLI

**Files:**
- Create: `tools/content/sync.py`, `tools/content_sync.py`
- Test: `tools/test_content_sync.py`

**Interfaces:**
- Consumes: `DataSet`, `mdformat.render/parse`, `SECTIONS`, the section contract.
- Produces:
  - `sync.export_doc(ds, inbox: str, notes: dict[str, str]) -> Doc`.
  - `sync.run(root: Path, write: bool) -> Report`, where `Report` holds:
    - `imported: list[(key, field, old, new)]`;
    - `ignored: list[(key, field)]`;
    - `to_inbox: list[(location, reason)]`;
    - `conflicts: list[(key, field, doc_value, json_value)]`;
    - `doc_changed: bool`, true when the regenerated `CONTENT.md` differs from the file on disk;
    - `exit_code`: 0 when clean; 1 for conflicts; and in check mode, 2 when anything is pending.
  - `tools/content_sync.py [--write] [--check]`: prints the report and exits with `Report.exit_code`.
  - The base file: `{"version": 1, "fields": {"<entry key>#<field>": value}, "notes": {"<entry key>": text}, "rendered": {"<location key>": raw entry text}}`. Titles use the field name `"title"`. `rendered` is written on every regeneration (top-level entries only; children are inside their parent's raw).

**The rules** (`run`):
1. Load the `DataSet` and the base. If the base is missing:
   - with `CONTENT.md` also missing, this is a first run: export, write both, done;
   - with `CONTENT.md` present, stop with "content_base.json is missing — restore it from git (`git checkout -- tools/content_base.json`); refusing to guess which side is newer." Exit code 1.
2. Build `current = export_doc(ds, inbox="", notes=base.notes)` and index it with `mdformat.location_index(current)`. Parse `CONTENT.md` into `parsed`.
3. For each parsed entry whose location key is in `current`, and for each field and the title, use the field `kind`:
   - `context`: if the doc value ≠ the current rendered value, add it to `ignored`;
   - writing fields, with `d` = doc, `j` = JSON (current) and `b` = base:
     - `d == j`: nothing;
     - `d != b and j == b`: import `d` (the section's `import_field`, or `ds.set_at`);
     - `d == b and j != b`: JSON wins, nothing to import;
     - otherwise: conflict.
   - Notes: the doc value always wins and goes into `base.notes`.
4. Parsed entries whose location key is **not** in `current`:
   - if the entry's `raw` text equals `base.rendered[location]` — the exact text the last regeneration wrote there, so the record was deleted from the JSON and nobody touched it in the doc — drop silently;
   - otherwise append `raw` to the Inbox under the line `<!-- moved by content_sync: found under <location>; not in the data -->`, and add it to `to_inbox`.
5. Every `stray` item is appended to the Inbox the same way, with the reason "unrecognised line".
6. If there are any conflicts, print them all, write **nothing** (no JSON, doc or base), and exit 1.
7. Otherwise, with `write=True`:
   - `ds.write_dirty()`;
   - rebuild `current` from the updated `ds`;
   - write `CONTENT.md = render(export_doc(ds, inbox=parsed.inbox + moved text, notes))`;
   - write the base from the regenerated doc's writing fields and notes.
   Without `--write`, write nothing and report.
8. With `--check`, exit 2 when `imported`, `to_inbox`, `ignored` or `doc_changed` is non-empty, and print `run python3 tools/content_sync.py --write`. Inbox content never counts.

- [ ] **Step 1: Write the failing tests.** Each test copies the repo's `resources/data` into a temp root, runs a first `run(write=True)` to create `CONTENT.md` and the base, then mutates:

```python
# tools/test_content_sync.py
import json, os, shutil, sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import sync
ROOT = Path(__file__).resolve().parent.parent
TRAITS = "resources/data/traits.json"

class SyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(ROOT / "resources/data", self.tmp / "resources/data")
        (self.tmp / "tools").mkdir()
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 0)
        self.doc = self.tmp / "CONTENT.md"

    def edit_doc(self, old, new):
        t = self.doc.read_text(encoding="utf-8")
        self.assertIn(old, t)
        self.doc.write_text(t.replace(old, new, 1), encoding="utf-8")

    def traits(self):
        return json.loads((self.tmp / TRAITS).read_text(encoding="utf-8"))

    def test_clean_after_first_run(self):
        r = sync.run(self.tmp, write=False)
        self.assertEqual((r.imported, r.to_inbox, r.conflicts, r.doc_changed), ([], [], [], False))

    def test_doc_edit_imports_exactly_that_field(self):
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Broad in the shoulder.")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([(k, f) for k, f, _, _ in r.imported], [("traits:strong", "desc")])
        self.assertEqual(self.traits()["strong"]["description"], "Broad in the shoulder.")

    def test_json_edit_flows_into_doc(self):
        d = self.traits(); d["strong"]["description"] = "Changed by code."
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        sync.run(self.tmp, write=True)
        self.assertIn("Changed by code.", self.doc.read_text(encoding="utf-8"))

    def test_conflict_writes_nothing(self):
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Doc version.")
        d = self.traits(); d["strong"]["description"] = "JSON version."
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        before = self.doc.read_text(encoding="utf-8")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 1)
        self.assertEqual(self.traits()["strong"]["description"], "JSON version.")
        self.assertEqual(self.doc.read_text(encoding="utf-8"), before)

    def test_context_edit_is_ignored_and_reported(self):
        self.edit_doc("`strong` — ", "`strong` — EDITED ")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertTrue(r.ignored)

    def test_broken_id_and_new_entry_go_to_inbox(self):
        self.edit_doc("`strong`", "`strongg`")
        self.edit_doc("# Traits\n", "# Traits\n\n- **Goat-Minded** `goat_minded`\n  - desc: Stubborn.\n")
        r = sync.run(self.tmp, write=True)
        text = self.doc.read_text(encoding="utf-8")
        inbox = text.split("# World")[0] if "# World" in text else text.split("\n# Traits")[0]
        self.assertIn("goat_minded", inbox)
        self.assertIn("strongg", inbox)
        self.assertIn("`strong`", text.split("# Traits")[1])      # original regenerated
        self.assertEqual(len(r.to_inbox), 2)

    def test_inbox_and_notes_survive(self):
        self.edit_doc("# Inbox\n", "# Inbox\n\nA goat oracle — maybe hell?\n")
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, desc + "\n  - notes: rebalance later")
        sync.run(self.tmp, write=True); sync.run(self.tmp, write=True)
        text = self.doc.read_text(encoding="utf-8")
        self.assertIn("A goat oracle — maybe hell?", text)
        self.assertIn("rebalance later", text)
        self.assertNotIn("rebalance later", (self.tmp / TRAITS).read_text(encoding="utf-8"))

    def test_check_mode(self):
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Pending.")
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 2)

    def test_missing_base_refuses(self):
        (self.tmp / "tools/content_base.json").unlink()
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 1)

if __name__ == "__main__":
    unittest.main()
```

(`run` takes `check: bool = False`. The `notes` test relies on the inline `desc` value being on one line followed by the next field. If `strong`'s description renders as a block, insert the notes line after the block instead. Make the test find the entry's last field line rather than assuming.)

- [ ] **Step 2: Run them and check that they fail**

Run: `python3 tools/test_content_sync.py -v`
Expected: `ImportError: cannot import name 'sync'`

- [ ] **Step 3: Implement `tools/content/sync.py` and `tools/content_sync.py`** to the rules above. The CLI:

```python
#!/usr/bin/env python3
"""Keep CONTENT.md and resources/data in agreement.

  python3 tools/content_sync.py            dry run: show what would change
  python3 tools/content_sync.py --write    apply it
  python3 tools/content_sync.py --check    for verify_all.sh: fail if anything is pending

Edit writing in CONTENT.md, run --write, and the JSON follows. Code that
changes the JSON shows up in CONTENT.md the next time this runs. If the same
text changed in both places, nothing is written and both versions are shown.
"""
import argparse, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from content import sync

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    report = sync.run(Path(__file__).resolve().parent.parent, write=a.write, check=a.check)
    report.print()
    return report.exit_code

if __name__ == "__main__":
    sys.exit(main())
```

`Report.print()` prints sections IMPORTED, IGNORED (context field), MOVED TO INBOX and CONFLICTS. Each conflict shows `doc:` and `json:` values, truncated to 200 characters. The output ends with a one-line summary.

- [ ] **Step 4: Run them and check that they pass**

Run: `python3 tools/test_content_sync.py -v`
Expected: 9 tests OK.

- [ ] **Step 5: Commit**

```bash
git add tools/content/sync.py tools/content_sync.py tools/test_content_sync.py
git commit -m "content: three-way sync — doc edits import, code edits regenerate, conflicts stop"
```

---

### Task 5: The remaining sections

Four independent sub-tasks (5a–5d). They can run in parallel, because each creates its own section files. Each sub-task appends its modules to `SECTIONS` in `sections/__init__.py`, and the global order is restored by Task 6. Every module follows the contract from Task 3 and passes `test_every_section_round_trips_over_real_data`. Each sub-task also adds one coverage test, like `test_traits_cover_every_trait`, that counts its entries against the JSON.

**Field tables.** These are the writing fields. Everything else a module chooses to show is context, either on the entry line after ` — ` or as `context` fields, and kept terse.

**5a — Events and Quests** (`events.py`, `quests.py`). Port `export_events` from `tools/export_review_docs.py:104-193`. Copy `reward_line`, `req_line` and `CHOICE_LABEL` into `events.py`.
- **Grouping:** realm (hell, hungry_ghost, animal, then domain) → `zone` if present.
- **Event:** the title is editable (`title`). Writing: `text` (or `description` when the event has no `text`; whichever key exists). Context line: realm · zone · trigger · requires_trait · requires_band · rarity.
- **Choices:** these are the children, with `children_label="choices"`, `tag` = grey/blue/yellow, ident = choice `id` or `#<index>`, and title = choice `text` (editable). Writing: each outcome branch's `text` (`success`, `failure`, `outcome`, or whatever branch keys the export currently walks; mirror it exactly), shown as `result`, `success` and `failure` fields. Context: `req_line` and `reward_line`.
- **Quests:** grouped by realm. Title is `name`; writing: `description`, each `steps[i].text` as fields `step 1`, `step 2`… (key `step_1`).
- **Coverage test:** event count equals the total events across the 4 files (348 today), and choice count equals the total choices.

**5b — World, Births, Companions** (`world.py`, `births.py`, `companions.py`). Port `export_animal_world`, `export_animal_races`, `export_animal_companions` and `export_animal_names` (`export_review_docs.py:195-716`), generalised from the animal realm to **every** realm.
- **World**, per realm `map_configs/<realm>.json`:
  - realm `name`/`description`;
  - zones (`name`, `description`, the `_comment` design note as a `design` writing field);
  - fixed landmarks;
  - `location_names` lists (each list as a `list` field);
  - `terrain.json` (`name`, `description`);
  - `domains.json` (`name`, `description`, `theme`).
- **Births:** grouped by realm.
  - Each race: `name` (title), `description`. Context: attribute modifiers, starting skills.
  - Children `backgrounds`: those whose `available_races` contains the race, or for backgrounds shared by several races, a separate "Shared backgrounds" group. Each has `name` and `description`.
  - Naming lore from `animal_realm_names.json`, as in the current export.
- **Companions:** realm → birth.
  - Title `name`; writing `flavor` (← `flavor_text`).
  - `skills` (list, from `build_weights`, strongest first).
  - `traits` (list).
  - Context: recruitment cost, background, zone.
  - Its `import_field` for `skills` rebuilds `build_weights` with 5/4/3/2 then 1. It only runs when the doc list differs from the base list; the sync guarantees that.
- **Coverage tests:** 47 races, 120 backgrounds, 99 companions. A test edits one companion's skills in a temp root and checks the weights.

**5c — Skills, Perks, Spells, Statuses** (`skills.py`, `perks.py`, `spells.py`, `statuses.py`).
- **Skills:** grouped by element. Title `name`; writing `description`. Context: category, primary/secondary attribute. The elements themselves (`skills.json` `elements`): `name`, `theme`.
- **Perks:** skill → `required_level`, as group "Level N".
  - Title `name`; writing `description`, `flavor`. Context: requires_perks, required_attributes, mantra.
  - `cross_perks` go in a final group "Cross-skill", by `category`.
- **Spells:** grouped by `schools[0]`, then "Level N".
  - Title `name`; writing `description`. `theme` is writing too, since it is prose.
  - Context: all schools, mana_cost, target summary, damage + damage_type.
  - `school_notes` are a writing `notes`-like field per school group. Render them as an entry `School notes` `<school>:notes`, with one field per key.
- **Statuses:** grouped by `category`.
  - Title `name`. **Statuses are a list**, so the address is `(FILE, "statuses", index, "name")` and the ident is `name`.
  - Writing: `description`. Context: type, duration, effects.
- **Coverage tests:** 35 skills, 551 + 54 perks, 377 spells, 187 statuses.

**5d — Equipment and Enemies** (`equipment.py`, `enemies.py`).
- **Equipment:**
  - `items.json` grouped by item_types `category`, then `type`. Title `name`; writing `description`. Context: rarity, material, slot, value.
  - `ammo.json`: `name`, `description`.
  - `equipment_tables.json`: materials, weapon_bases, armor_bases, weapon_traits and armor_traits. Show each one's `name`/`description` where present, and for name tables show the names as `list` fields.
  - `talisman_tables.json`: `perks[]` (`name`, `description`) and `name_parts` (list fields).
  - `upgrades.json`: `name`, `description`.
  - `supplies.json` `supply_types`: `name`, `description` if present.
- **Enemies:** realm → region.
  - Archetypes: title `name`; writing: the `_comment` design note as a `design` field. Context: tier, roles, tags.
  - Encounters: the `_comment` as `design`. Context: tier and enemy list.
  - `summon_templates.json`: `display_name`.
  - `enemies/name_parts.json`: each part's `meaning` as writing.
- **Shops:** shops are places, so they go under World. 5d adds them to `world.py`'s output only if 5b has landed; otherwise it adds them as `places.py` under World in Task 6. Fields: `name`, `description`.
- **Coverage tests:** 736 items, 114 archetypes, 119 encounters, 84 summon templates, 91 shops.

For each sub-task:

- [ ] **Step 1:** Write the coverage test(s) in `tools/test_content_sections.py`, run them, and check that they fail (module missing).
- [ ] **Step 2:** Implement the module(s), following `traits.py`'s shape.
- [ ] **Step 3:** Run `python3 tools/test_content_sections.py -v`. All tests must pass, including the round-trip over the real data, with `stray == []`, no duplicate keys, and no backticks in titles.
- [ ] **Step 4:** Commit: `git commit -m "content: <sections> sections"`.

---

### Task 6: Assemble the document and add the guard

**Files:**
- Modify: `tools/content/sections/__init__.py` (the final ordered `SECTIONS`), `tools/verify_all.sh` (the data layer)
- Create: `CONTENT.md`, `tools/content_base.json` (generated)
- Test: `tools/test_content_sync.py` (add `test_full_document_round_trips`)

- [ ] **Step 1:** Set `SECTIONS = [world, births, companions, skills, perks, spells, statuses, traits, equipment, enemies, events, quests]`, with shops inside World.
- [ ] **Step 2:** Add a test. Run `sync.run` on a temp copy twice. The second run must report nothing, and the document's level-1 headings must be exactly `["Inbox", "World", "Births", "Companions", "Skills", "Perks", "Spells", "Statuses", "Traits", "Equipment", "Enemies", "Events", "Quests"]`. Run it and check that it passes.
- [ ] **Step 3:** In `tools/verify_all.sh`'s data layer, after `validate_data.py`, add these lines in the script's existing `ok`/`bad` style:

```bash
    # CONTENT.md and the JSON must agree, or a build could ship without
    # writing that exists only in the document.
    if out=$(python3 tools/content_sync.py --check 2>&1); then
        ok "CONTENT.md matches the data"
    else
        bad "CONTENT.md and the data disagree — run: python3 tools/content_sync.py --write"
        echo "$out" | tail -15 | sed 's/^/        /'
    fi
    if python3 tools/test_content_model.py >/dev/null 2>&1 \
       && python3 tools/test_content_sections.py >/dev/null 2>&1 \
       && python3 tools/test_content_sync.py >/dev/null 2>&1; then
        ok "content sync tests"
    else
        bad "content sync tests — run python3 tools/test_content_sync.py -v"
    fi
```

The `--quick` flag must still run this layer: it is Python only.
- [ ] **Step 4:** Do not generate `CONTENT.md` in this task. Task 7 does that after the data is normalised. Until then the `--check` step would fail, so guard it: skip with `ok "CONTENT.md not created yet"` when the file is absent. Task 7 removes that guard.
- [ ] **Step 5:** Run `tools/verify_all.sh --quick`. Expected: all OK.
- [ ] **Step 6:** Commit: `git commit -m "content: the full document order, and verify_all guards it"`.

---

### Task 7: Migration

This must run after every other branch touching `resources/data` has merged, because it normalises JSON formatting.

**Files:**
- Modify: every `resources/data/**/*.json` whose bytes differ from `canonical_dumps` (whitespace only)
- Create: `CONTENT.md`, `tools/content_base.json`

- [ ] **Step 1: Import any pending review-doc edits.** Run `python3 tools/import_review_docs.py`. If it reports pending edits, run it with `--write`, then `python3 tools/validate_data.py`, and commit `"Import the last edits made in docs/review"`. If it reports unmatched anchors, stop and report them; do not proceed.
- [ ] **Step 2: Normalise the JSON.** Load every data file with `DataSet.load` and rewrite all of them with `canonical_dumps(obj, detect_indent(text))`. Check that `json.load` of every rewritten file equals the original (semantic equality) and print the list of files whose bytes changed. Run `tools/verify_all.sh`; expected ALL CHECKS PASSED. Commit with the message `"Data: one canonical JSON formatting (whitespace only)"`, so the commit is reviewable as no-op.
- [ ] **Step 3: First generation.** With no base and no `CONTENT.md`, run `python3 tools/content_sync.py --write`. Run it again; expected: nothing pending. Remove Task 6's "not created yet" guard. Run `tools/verify_all.sh`.
- [ ] **Step 4: Carry over the text that exists only in markdown.** For each source below, compare it against what `CONTENT.md` now holds.
  - Wording that differs from the JSON is **not** applied; the JSON is current. It goes in the Inbox under a heading naming the source, unless it is clearly the same text.
  - Material with no JSON home goes under `notes:` on the matching entry, or into the Inbox when nothing matches.

  The sources:
  - the **Notes** sections of `docs/review/ANIMAL_MEADOW.md` (and any other workbook);
  - `PERKS.md` (only prose not already in perks.json descriptions and flavour: the stacking rules at the top become `notes` on the Perks section's first entry, or an Inbox item);
  - `CHARACTERS.md` (companions' "Meaning:" lines and bios not in companions.json → `notes` on that companion);
  - `docs/BACKGROUNDS_BY_BIRTH.md`;
  - `docs/companion_quirks.md`;
  - `resources/data/events/hungry_ghost_events_plan.md` (unbuilt plans → Inbox);
  - `EDIT_LATER.md` from git (`git show 53adfa9^:EDIT_LATER.md`): its wound notes → Inbox, under "Wounds — design notes (recovered)".

  Write `notes:` lines in the doc, then run `content_sync.py --write`. The notes land in the base. Print a summary of what moved where, for the commit message.
- [ ] **Step 5: Delete:**
  - all of `docs/review/`;
  - `tools/export_review_docs.py`, `tools/import_review_docs.py`;
  - `PERKS.md`, `CHARACTERS.md`;
  - `docs/BACKGROUNDS_BY_BIRTH.md`, `docs/companion_quirks.md`;
  - `resources/data/events/hungry_ghost_events_plan.md`;
  - `tools/parse_perks.py`, `tools/remap_perk_levels.py`, `tools/shift_perk_levels.py`, `tools/extend_tables.py`.

  First grep for references in `tools/`, `scripts/`, `.claude/` and `docs/`, and fix any live ones. Mentions in history and plan docs can stay.
- [ ] **Step 6: Update the references:**
  - **README.md:** a short "Writing content" section covering what `CONTENT.md` is, the Inbox, the sync commands, the conflict behaviour, and the fact that `verify_all` checks it.
  - **CLAUDE.md:** replace the "Content Creation Pattern" paragraph with the `CONTENT.md` workflow. When Olaf asks to integrate Inbox items, Claude turns them into data, runs `content_sync.py --write`, and deletes them from the Inbox. Also drop the `SPECIFICATION/chat1.txt` line, and say that if the spell list turns up it goes in the Inbox.
  - **TODO.md:** tick the "NEXT — one master content document" item. Update the "Companion documents" list at the top and every mention of `docs/review/` or `PERKS.md`.
  - **`.claude/skills/`:** fix any mention of `docs/review/`.
- [ ] **Step 7:** Run `tools/verify_all.sh`. Expected: ALL CHECKS PASSED, including "CONTENT.md matches the data" and "content sync tests". Commit `"CONTENT.md: all the writing in one place; docs/review and the perk markdown retired"`.

---

## Execution order

Run tasks 1 → 2 → 3 → 4 in sequence; each depends on the previous one. Then run 5a, 5b, 5c and 5d in parallel. Then 6, then 7. Task 7 waits until the §15 fix branches running at the same time have merged into `claude/todo-sweep`.
