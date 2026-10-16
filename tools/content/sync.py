"""The three-way sync between CONTENT.md and resources/data.

Three versions of every writing field are compared:
  d  what CONTENT.md says now          (the doc)
  j  what the JSON says now            (the data)
  b  what both said after the last sync (tools/content_base.json)

  d == j              nothing to do
  only d moved        the doc was edited  -> import d into the JSON
  only j moved        code changed the JSON -> the regenerated doc shows it
  both moved          a conflict: write nothing, show both

All comparisons happen in "doc view": the value as it reads back from the
rendered text. That is why the current data is rendered and parsed again
before comparing (see _doc_view_index): whatever rendering does to a value
(trailing spaces, line breaks), d and j go through exactly the same steps.
"""
import difflib
import json
from dataclasses import dataclass, field
from pathlib import Path

from . import mdformat, sections
from .jsonio import DataSet
from .model import Doc, Field

DOC_FILE = "CONTENT.md"
BASE_FILE = "tools/content_base.json"
MISSING_BASE = ("content_base.json is missing — restore it from git "
                "(`git checkout -- tools/content_base.json`); "
                "refusing to guess which side is newer.")
PENDING_HINT = "run python3 tools/content_sync.py --write"
BROKEN = ("could not read this entry — nothing imported; fix it here and "
          "paste it back, or edit the original below")
DUPLICATE = "duplicate id — nothing imported"


# ===========================================================================
# The report
# ===========================================================================
def _text(value) -> str:
    return ", ".join(value) if isinstance(value, list) else str(value)


def _short(value, limit=200) -> str:
    text = _text(value)
    return text if len(text) <= limit else text[:limit] + "…"


def preview_change(old, new, width=60) -> list:
    """[old, new] as two short, quoted previews for the report.

    When the two texts start the same way, both previews start a little
    before the first character that differs, so the owner can SEE the
    change, e.g. a paragraph cut off at the end (which a preview of just the
    first 60 characters would hide). Lengths are added when they differ."""
    a, b = _text(old), _text(new)
    same = 0
    while same < min(len(a), len(b)) and a[same] == b[same]:
        same += 1
    start = same - 20 if same > 20 else 0
    out = []
    for t in (a, b):
        piece = t[start:start + width]
        shown = ("…" if start else "") + repr(piece) + ("…" if len(t) > start + width else "")
        if len(a) != len(b):
            shown += f" ({len(t)} chars)"
        out.append(shown)
    return out


@dataclass
class Report:
    imported: list = field(default_factory=list)    # (key, field, old, new)
    ignored: list = field(default_factory=list)     # (key, field)
    to_inbox: list = field(default_factory=list)    # (location, reason)
    conflicts: list = field(default_factory=list)   # (key, field, doc, json)
    invalid: list = field(default_factory=list)     # (key, field, message)
    doc_changed: bool = False
    check: bool = False
    message: str = ""                               # a fatal problem, if any
    notice: str = ""                                # worth saying, not fatal
    first_run: bool = False

    @property
    def pending(self) -> bool:
        return bool(self.imported or self.to_inbox or self.ignored or self.doc_changed)

    @property
    def exit_code(self) -> int:
        if self.message or self.conflicts or self.invalid:
            return 1
        if self.check and self.pending:
            return 2
        return 0

    def print(self) -> None:
        if self.message:             # a refusal: nothing was compared
            print(self.message)
            return
        if self.notice:
            print(self.notice)
        if self.imported:
            print("IMPORTED")
            for key, name, old, new in self.imported:
                was, now = preview_change(old, new)
                print(f"  {key} {name}: {was} -> {now}")
        if self.ignored:
            print("IGNORED (context field)")
            for key, name in self.ignored:
                print(f"  {key} {name}")
        if self.to_inbox:
            print("MOVED TO INBOX")
            for location, reason in self.to_inbox:
                print(f"  {location}: {reason}")
        if self.conflicts:
            print("CONFLICTS (nothing was written)")
            for key, name, d, j in self.conflicts:
                print(f"  {key} {name}")
                print(f"    doc:  {_short(d)}")
                print(f"    json: {_short(j)}")
        if self.invalid:
            print("UNKNOWN IDS (nothing was written)")
            for key, name, message in self.invalid:
                print(f"  {key} {name}: {message}")
        summary = (f"{len(self.imported)} imported, {len(self.ignored)} ignored, "
                   f"{len(self.to_inbox)} moved to inbox, {len(self.conflicts)} conflicts, "
                   f"CONTENT.md {'changes' if self.doc_changed else 'unchanged'}"
                   + (" (first run)" if self.first_run else ""))
        print(summary)
        if self.check and self.pending and not (self.conflicts or self.invalid):
            print(PENDING_HINT)


# ===========================================================================
# Building the document
# ===========================================================================
def _walk(entries):
    """Every entry and all its children, at any depth."""
    for e in entries:
        yield e
        yield from _walk(e.children)


def _group_entries(group):
    yield from _walk(group.entries)
    for sub in group.groups:
        yield from _group_entries(sub)


def _build(ds, inbox: str, notes: dict):
    """The Doc, plus {entry key: section module} so imports find their section."""
    doc = Doc(inbox=inbox)
    owner = {}
    for section in sections.SECTIONS:
        group = section.build(ds)
        for e in _group_entries(group):
            e.notes = notes.get(e.key, "")
            owner[e.key] = section
        doc.sections.append(group)
    return doc, owner


def export_doc(ds, inbox: str, notes: dict) -> Doc:
    return _build(ds, inbox, notes)[0]


def _doc_view_index(text: str) -> dict:
    """{location: ParsedEntry} for text the sync itself rendered."""
    return mdformat.parse(text).entries


def _by_ident(children: list) -> dict:
    """{ident: child}; the first one wins if two share an ident."""
    out = {}
    for c in children:
        out.setdefault(c.ident, c)
    return out


def _read(raw: str, kind: str):
    """A parsed field's text as a comparable value for its kind."""
    return mdformat.split_list(raw) if kind == "list" else raw


def _norm_id(text: str) -> str:
    """How an id typed by hand is read: 'Martial Arts' -> 'martial_arts'.
    Case is ignored, runs of spaces become one underscore and a trailing
    full stop is dropped."""
    return "_".join(text.strip().rstrip(".").strip().lower().split())


def _unknown_ids(f: Field, items: list) -> list:
    """Messages for every item of an id-list field the game does not know."""
    out = []
    for x in items:
        if x not in f.ids:
            near = difflib.get_close_matches(x, sorted(f.ids), n=1)
            hint = f"; did you mean '{near[0]}'?" if near else ""
            out.append(f"'{x}' is not an id in {f.ids_from}{hint}")
    return out


def _base_fields(doc: Doc, text: str) -> dict:
    """The base snapshot's "fields": every writing field (and editable title)
    of `doc`, read back from its rendered `text`."""
    out = {}
    parsed = _doc_view_index(text)

    def record(e, pe) -> None:
        if e.title_path:
            out[f"{e.key}#title"] = pe.title
        for f in e.fields:
            if f.kind != "context" and f.name in pe.fields:
                out[f"{e.key}#{f.name}"] = _read(pe.fields[f.name], f.kind)
        kids = _by_ident(pe.children)
        for c in e.children:
            if c.ident in kids:
                record(c, kids[c.ident])

    for loc, e in mdformat.location_index(doc).items():
        if loc in parsed:
            record(e, parsed[loc])
    return out


def _has_notes(pe) -> bool:
    """True if a parsed entry, or any child below it, has notes."""
    return bool(pe.notes) or any(_has_notes(c) for c in pe.children)


def _field_text(name: str, value: str) -> str:
    """A field line (or block) for text moved to the Inbox."""
    if "\n" not in value:
        return f"- {name}: {value}"
    return "\n".join([f"- {name}:"] + [f"  > {p}" if p else "  >" for p in value.split("\n")])


# ===========================================================================
# The merge
# ===========================================================================
class _Merge:
    """Walks the parsed doc against the current data, filling a Report."""

    def __init__(self, ds, base: dict, owner: dict, report: Report,
                 current_index: dict = None):
        self.ds, self.base, self.owner, self.report = ds, base, owner, report
        self.current_index = current_index or {}   # location -> built Entry
        self.notes: dict = {}        # the doc's notes, which always win
        self.moved: list = []        # text blocks for the Inbox
        self._base_kids: dict = {}   # cache for base_children()

    def base_children(self, top: str) -> dict:
        """{location below the top entry: raw} for every child the last sync
        rendered inside the top-level entry at location `top`."""
        if top not in self._base_kids:
            # entry lines only parse under a heading, so give it one
            parsed = mdformat.parse("# x\n" + self.base["rendered"].get(top, ""))
            out = {}
            for pe in parsed.entries.values():
                stack = list(pe.children)
                while stack:
                    c = stack.pop()
                    out[c.location[len(pe.location):]] = c.raw
                    stack.extend(c.children)
            self._base_kids[top] = out
        return self._base_kids[top]

    def keep_base_notes(self, built) -> None:
        """Nothing was read from the doc for this built entry (and its
        children), so its notes are the ones the last sync saved: the
        regenerated original then looks exactly as it did."""
        for e in _walk([built]):
            if e.key in self.base["notes"]:
                self.notes[e.key] = self.base["notes"][e.key]

    def top(self, location: str, copies: list, cur) -> None:
        """All the doc's top-level entries found at one location.

        One readable copy: merge it as usual. Otherwise import NOTHING:
          - several copies (a pasted template, say): any one of them could
            be the "real" one, so every copy that differs from what the last
            sync wrote goes to the Inbox, and the original is regenerated;
          - one copy with an unreadable line (`broken`): its fields may be
            cut short, so the whole entry goes to the Inbox as one chunk.
        """
        if len(copies) == 1 and not copies[0].broken:
            pe = copies[0]
            if location in self.current_index and cur is not None:
                self.entry(self.current_index[location], pe, cur, location)
            else:
                self.gone(location, pe, pe.raw == self.base["rendered"].get(location))
            return
        # what the last sync wrote here (a "(duplicate N)" key only exists
        # if the data itself renders two entries at one location)
        before = {raw for k, raw in self.base["rendered"].items()
                  if k == location or k.startswith(location + " (duplicate ")}
        reason = DUPLICATE if len(copies) > 1 else BROKEN
        for pe in copies:
            if pe.raw in before and not pe.broken:
                if location not in self.current_index:
                    self.gone(location, pe, True)    # record deleted meanwhile
                continue                             # untouched: regenerated
            self.move(location, reason, pe.raw)
        if location in self.current_index:
            self.keep_base_notes(self.current_index[location])

    def gone(self, location: str, pe, untouched: bool) -> None:
        """A doc entry with no record in the data. Dropped silently only
        when it is exactly what the last sync wrote (the record was deleted
        from the JSON) and nothing in it carries notes; otherwise its text
        goes to the Inbox, because owner text is never lost."""
        if not untouched:
            self.move(location, "not in the data", pe.raw)
        elif _has_notes(pe):
            self.move(location, "record deleted from the data; it had notes", pe.raw)

    def move(self, location: str, reason: str, raw: str) -> None:
        self.moved.append(
            f"<!-- moved by content_sync: found under {location}; {reason} -->\n{raw}")
        self.report.to_inbox.append((location, reason))

    def three_way(self, entry, f: Field, d, j) -> None:
        """Apply the d/j/b rules to one writing field."""
        if d == j:
            return
        key = f"{entry.key}#{f.name}"
        b = self.base["fields"].get(key)
        if key in self.base["fields"] and d != b and j == b:
            if f.ids is not None:
                bad = _unknown_ids(f, d)
                if bad:              # a typo must never reach the game data
                    self.report.invalid += [(entry.key, f.name, m) for m in bad]
                    return
            section = self.owner.get(entry.key)
            if hasattr(section, "import_field"):
                section.import_field(self.ds, entry.key, f, d)
            else:
                # set_at writes the doc's str (or list[str] for a list field);
                # a section whose JSON holds other types needs import_field
                self.ds.set_at(f.path, d)
            self.report.imported.append((entry.key, f.name, j, d))
        elif key in self.base["fields"] and d == b:
            pass                     # only the JSON moved: it wins
        else:
            self.report.conflicts.append((entry.key, f.name, d, j))

    def entry(self, e, pe, cur, top: str) -> None:
        """e: the built Entry; pe: the doc's ParsedEntry; cur: the same
        entry parsed from the current data's rendering (the doc view of j);
        top: the location key of the top-level entry this one sits in."""
        if pe.title != cur.title:
            if e.title_path:
                self.three_way(e, Field("title", cur.title, "text", e.title_path),
                               pe.title, cur.title)
            else:
                self.report.ignored.append((e.key, "title"))
        if pe.context != cur.context:
            self.report.ignored.append((e.key, "context"))
        if pe.tag != cur.tag:
            self.report.ignored.append((e.key, "tag"))
        known = {"notes"}
        for f in e.fields:
            known.add(f.name)
            if f.name not in pe.fields:
                continue             # line deleted: regeneration puts it back
            d_raw, j_raw = pe.fields[f.name], cur.fields.get(f.name, "")
            if f.kind == "context":
                if d_raw != j_raw:
                    self.report.ignored.append((e.key, f.name))
            else:
                d = _read(d_raw, f.kind)
                if f.ids is not None:            # "Martial Arts" -> martial_arts
                    d = [_norm_id(x) for x in d]
                self.three_way(e, f, d, _read(j_raw, f.kind))
        unknown = [(n, v) for n, v in pe.fields.items() if n not in known and v.strip()]
        if unknown:                  # all of them as one chunk, one comment
            names = ", ".join(f"'{n}'" for n, _ in unknown)
            self.move(pe.location, f"unknown field{'s' if len(unknown) > 1 else ''} {names}",
                      "\n".join(_field_text(n, v) for n, v in unknown))
        if pe.notes:
            self.notes[e.key] = pe.notes
        built, current = _by_ident(e.children), _by_ident(cur.children)
        copies: dict = {}            # ident -> [ParsedEntry], in doc order
        for pc in pe.children:
            copies.setdefault(pc.ident, []).append(pc)
        for ident, group in copies.items():
            if len(group) > 1:
                # A copy pasted above the original would overwrite it, so no
                # copy imports; each one that differs from the last sync's
                # text goes to the Inbox, and the original is regenerated.
                for pc in group:
                    if self.base_children(top).get(pc.location[len(top):]) != pc.raw:
                        self.move(pc.location, DUPLICATE, pc.raw)
                if ident in built:
                    self.keep_base_notes(built[ident])
                continue
            pc = group[0]
            if pc.ident in built and pc.ident in current:
                self.entry(built[pc.ident], pc, current[pc.ident], top)
            else:
                # untouched = the same text the last sync wrote for this child
                below = pc.location[len(top):]
                self.gone(pc.location, pc,
                          self.base_children(top).get(below) == pc.raw)


# ===========================================================================
# run
# ===========================================================================
def _load_base(path: Path):
    if not path.exists():
        return None
    base = json.loads(path.read_text(encoding="utf-8"))
    for k in ("fields", "notes", "rendered"):
        base.setdefault(k, {})
    return base


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def _write_base(path: Path, doc: Doc, text: str, notes: dict) -> None:
    base = {"version": 1,
            "fields": _base_fields(doc, text),
            "notes": notes,
            "rendered": {loc: pe.raw for loc, pe in _doc_view_index(text).items()}}
    _write(path, json.dumps(base, indent=2, sort_keys=True, ensure_ascii=False) + "\n")


def _collect_notes(pe, built, notes: dict) -> None:
    """Copy notes from a parsed entry (and its children, matched by id) into
    `notes`, keyed the way the base keys them."""
    if pe.notes:
        notes[built.key] = pe.notes
    kids = {c.ident: c for c in built.children}
    for c in pe.children:
        if c.ident in kids:
            _collect_notes(c, kids[c.ident], notes)


def _rebuilt_base(ds, doc_path: Path):
    """A base made from scratch (--rebase-base): "what both said at the last
    sync" is taken to be the JSON as it is now, and the notes are read back
    out of CONTENT.md, where every note is also written. So an edit made in
    CONTENT.md since then still imports. Returns None when there is no
    CONTENT.md (nothing to lose; the normal first-run path applies)."""
    if not doc_path.exists():
        return None
    notes: dict = {}
    parsed = mdformat.parse(doc_path.read_text(encoding="utf-8"))
    index = mdformat.location_index(_build(ds, "", {})[0])
    for loc, pe in parsed.entries.items():
        if loc in index:
            _collect_notes(pe, index[loc], notes)
    doc = export_doc(ds, "", notes)
    text = mdformat.render(doc)
    return {"version": 1, "fields": _base_fields(doc, text), "notes": notes,
            "rendered": {loc: pe.raw for loc, pe in _doc_view_index(text).items()}}


def run(root: Path, write: bool, check: bool = False,
        rebase_base: bool = False) -> Report:
    root = Path(root)
    report = Report(check=check)
    doc_path, base_path = root / DOC_FILE, root / BASE_FILE
    ds = DataSet.load(root)
    base = _rebuilt_base(ds, doc_path) if rebase_base else _load_base(base_path)

    # 1. no base: a first run, or a refusal
    if base is None:
        if doc_path.exists():
            report.message = MISSING_BASE
            return report
        report.first_run = report.doc_changed = True
        if write:
            doc = export_doc(ds, "", {})
            text = mdformat.render(doc)
            _write(doc_path, text)
            _write_base(base_path, doc, text, {})
        return report

    # 2. the current data, rendered and read back, and the doc as it is now
    current, owner = _build(ds, "", base["notes"])
    current_index = mdformat.location_index(current)
    current_view = _doc_view_index(mdformat.render(current))
    on_disk = doc_path.read_text(encoding="utf-8") if doc_path.exists() else None
    parsed = mdformat.parse(on_disk or "")

    # 3-5. merge every parsed entry; move what has no home to the Inbox
    merge = _Merge(ds, base, owner, report, current_index)
    if on_disk is None:
        # nothing to merge: rebuild the doc from the data and the saved notes
        report.notice = ("CONTENT.md is missing — regenerated from the data and "
                         "the notes in content_base.json, with an empty Inbox.")
        merge.notes = dict(base["notes"])
    by_location: dict = {}       # location -> every copy found there, in order
    for pe in parsed.entries.values():
        by_location.setdefault(pe.location, []).append(pe)
    for loc, copies in by_location.items():
        merge.top(loc, copies, current_view.get(loc))
    for loc, raw in parsed.stray:
        merge.move(loc, "unrecognised line", raw)

    # 6. a conflict, or an id the game does not know, stops everything
    if report.conflicts or report.invalid:
        return report

    # 7. regenerate from the (possibly updated, in memory) data
    inbox = "\n\n".join(p for p in [parsed.inbox] + merge.moved if p.strip())
    new_doc = export_doc(ds, inbox, merge.notes)
    new_text = mdformat.render(new_doc)
    report.doc_changed = new_text != on_disk
    if write:
        ds.write_dirty()
        _write(doc_path, new_text)
        _write_base(base_path, new_doc, new_text, merge.notes)
    return report
