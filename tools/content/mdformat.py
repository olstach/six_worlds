"""The CONTENT.md grammar: render a Doc to text, parse text back.

The grammar (see the plan, Task 2):

    # Inbox
    <free text, up to the line "# World">

    # World
    ## Animal realm `animal`                 <- group heading, optional `ident`
    - **Name** `ident` — read-only context   <- entry
      - flavor: one-line text                <- field
      - skills: swords, yoga                 <- list field
      - desc: (empty)                        <- empty field
      - bio:                                 <- block field (">" lines below)
        > first paragraph
      - choices:                             <- children label
        - [grey] Watch `watch`               <- child entry
          - result: You learn nothing.
      - notes: free text

The parser NEVER raises on content and never drops text. A line it cannot
read inside an entry marks that whole entry `broken` (so the sync imports
nothing from it); anything else it cannot place goes to ParsedDoc.stray.

Location keys are built from each heading's `ident` (its title when it has
none) plus the entry ident, so a heading's title can be renamed freely.
"""
import bisect
import re
from dataclasses import dataclass, field

from .model import EMPTY, Doc, Entry, Group

SEP = " › "            # between heading titles and the entry ident path
LONG_TEXT = 160        # longer inline text is written as a ">" block

# --- the four line shapes -------------------------------------------------
ENTRY_RE = re.compile(
    r"^(?P<ind> *)- (?:\[(?P<tag>[^\]]+)\] )?(?P<title>.*?) "
    r"`(?P<ident>[^`]+)`(?: — (?P<ctx>.*))?$")
FIELD_RE = re.compile(r"^(?P<ind> *)- (?P<key>[a-z_][a-z0-9_]*):(?: (?P<val>.*))?$")
BLOCK_RE = re.compile(r"^(?P<ind> *)>(?: (?P<txt>.*))?$")
HEADING_RE = re.compile(r"^(?P<hashes>#{1,6}) (?P<title>.*?)(?: `(?P<ident>[^`]+)`)?$")
# A plain title that looks like "word: ..." would be read as a field, so the
# renderer bolds such titles (a bold title starts with "*", not a letter).
_FIELDISH_TITLE = re.compile(r"^[a-z_][a-z0-9_]*:( |$)")


# ===========================================================================
# Rendering
# ===========================================================================
def _clean_title(title: str) -> str:
    """Titles never contain backticks (they would confuse the ident) or newlines."""
    return str(title).replace("`", "'").replace("\r", " ").replace("\n", " ")


def _needs_block(text: str) -> bool:
    """Text that would not survive on one line is written as a ">" block."""
    return ("\n" in text or text.startswith((">", "- ", "#", " "))
            or len(text) > LONG_TEXT)


def _render_field(lines: list, indent: str, name: str, value, kind: str) -> None:
    """Append the line(s) for one field."""
    if kind == "list" or isinstance(value, (list, tuple)):
        items = [str(v) for v in value]
        lines.append(f"{indent}- {name}: " + (", ".join(items) if items else EMPTY))
        return
    text = "" if value is None else str(value)
    if text == "":
        lines.append(f"{indent}- {name}: {EMPTY}")
    elif _needs_block(text):
        lines.append(f"{indent}- {name}:")
        for part in text.split("\n"):
            # an empty line is just ">" so there is no trailing space
            lines.append(f"{indent}  > {part}" if part else f"{indent}  >")
    else:
        lines.append(f"{indent}- {name}: {text}")


def _render_entry(lines: list, entry: Entry, depth: int, top: bool) -> None:
    """Append one entry, its fields, its children and its notes."""
    indent = " " * depth
    title = _clean_title(entry.title)
    bold = top or (not entry.tag and _FIELDISH_TITLE.match(title))
    if bold and title:
        title = f"**{title}**"
    head = f"{indent}- "
    if entry.tag:
        head += f"[{entry.tag}] "
    head += f"{title} `{entry.ident}`"
    if entry.context:
        head += " — " + str(entry.context).replace("\r", " ").replace("\n", " ")
    lines.append(head)
    for f in entry.fields:
        _render_field(lines, indent + "  ", f.name, f.value, f.kind)
    if entry.children:
        lines.append(f"{indent}  - {entry.children_label or 'children'}:")
        for child in entry.children:
            _render_entry(lines, child, depth + 4, top=False)
    if entry.notes:
        _render_field(lines, indent + "  ", "notes", entry.notes, "text")


def _render_group(lines: list, group: Group) -> None:
    head = "#" * group.level + " " + _clean_title(group.title)
    if group.ident:
        head += f" `{group.ident}`"
    lines.append(head)
    lines.append("")
    for entry in group.entries:
        _render_entry(lines, entry, 0, top=True)
    if group.entries:
        lines.append("")
    for sub in group.groups:
        _render_group(lines, sub)


def render(doc: Doc) -> str:
    """Turn a Doc into CONTENT.md text. Deterministic."""
    lines = ["# Inbox", ""]
    inbox = doc.inbox.strip("\n")
    if inbox.strip():
        lines += inbox.split("\n") + [""]
    for group in doc.sections:
        _render_group(lines, group)
    return "\n".join(lines).rstrip("\n") + "\n"


# ===========================================================================
# Location keys (shared by parse() and location_index())
# ===========================================================================
def _location(titles: list, ident_path: str) -> str:
    return SEP.join(titles + [ident_path])


def _heading_key(title: str, ident) -> str:
    """The part of a location key one heading contributes: its `ident` when
    it has one, otherwise its title. Using the ident means the owner can
    rename a heading's title freely: its entries keep their location."""
    return ident if ident else _clean_title(title)


def location_index(doc: Doc) -> dict:
    """{location key: Entry} for every TOP-LEVEL entry of a Doc.

    Uses exactly the same keys parse() produces for the rendered text, which
    is what lets the sync match a parsed entry to a record. Children live
    inside their parent. If two entries share a key the first one wins (the
    parser keeps the later one under a "(duplicate N)" key).
    """
    index: dict = {}

    def walk(group: Group, keys: list) -> None:
        keys = keys + [_heading_key(group.title, group.ident)]
        for entry in group.entries:
            index.setdefault(_location(keys, entry.ident), entry)
        for sub in group.groups:
            walk(sub, keys)

    for g in doc.sections:
        walk(g, [])
    return index


# ===========================================================================
# Parsing
# ===========================================================================
@dataclass
class ParsedEntry:
    ident: str
    title: str
    tag: str = ""
    # Always str: the raw text ("" for "(empty)"). The parser has no schema,
    # so for a field whose kind is "list" apply split_list() yourself.
    fields: dict = field(default_factory=dict)
    children: list = field(default_factory=list)
    children_label: str = ""
    raw: str = ""                 # exact source lines, moveable to the Inbox
    # The entry's real location key. Two copies of one entry share it (the
    # ParsedDoc.entries dict files the second under "... (duplicate 2)").
    location: str = ""
    context: str = ""             # the read-only text after " — "
    # True when a line inside this TOP-LEVEL entry (or inside any of its
    # children) could not be read. Its fields may then be cut short or
    # mixed up, so the sync must import NOTHING from it; `raw` then holds
    # every line of the entry, the unreadable ones included.
    broken: bool = False

    @property
    def notes(self) -> str:
        """`notes` is an ordinary field at parse time; this is a shortcut."""
        v = self.fields.get("notes", "")
        return v if isinstance(v, str) else ", ".join(v)


@dataclass
class ParsedDoc:
    inbox: str = ""
    entries: dict = field(default_factory=dict)   # location key -> ParsedEntry
    # [(location label, raw text)]: unreadable text OUTSIDE any entry, one
    # chunk per stretch (e.g. lines typed between a heading and its first
    # entry). Unreadable text INSIDE an entry marks the entry `broken`.
    stray: list = field(default_factory=list)


def split_list(raw: str) -> list:
    """Read a list field's text: comma separated, '(empty)' -> [].

    Each item is stripped, so "a,b", "a, b" and "a ,  b" all read the same.
    Empty items (from "a,,b" or a trailing comma) carry no text and are
    skipped."""
    if raw.strip() in ("", EMPTY):
        return []
    return [p.strip() for p in raw.split(",") if p.strip()]


def _expand_tabs(line: str) -> str:
    """Each leading tab counts as 2 spaces. Only RELATIVE indentation matters
    to the parser (deeper than the line it belongs under), so 2 spaces, 4
    spaces and tabs all work for one level."""
    m = re.match(r"[ \t]*", line)
    return m.group(0).replace("\t", "  ") + line[m.end():]


def _split_inbox(lines: list):
    """Return (inbox_text, index of the first section line, preamble lines).

    The Inbox starts after the line "# Inbox" and ends at the first line that
    is exactly "# World". If there is no "# World" (a document with only some
    sections), it ends at the first level-1 heading ("# ...") after "# Inbox".
    With no "# Inbox" at all there is no inbox and sections start at line 0.
    """
    try:
        start = lines.index("# Inbox")
    except ValueError:
        return "", 0, []
    preamble = lines[:start]
    if "# World" in lines[start + 1:]:
        end = lines.index("# World", start + 1)
    else:
        end = len(lines)
        for i in range(start + 1, len(lines)):
            if lines[i].startswith("# "):
                end = i
                break
    return "\n".join(lines[start + 1:end]).strip("\n"), end, preamble


class _Block:
    """A key line with nothing after the colon: collects ">" lines (or turns
    out to be the children label)."""
    def __init__(self, key, indent, owner, line):
        self.key, self.indent, self.owner, self.lines = key, indent, owner, []
        self.first = self.last = line      # source line range, for stray
        self.quote_indent = None           # indent of its first ">" line


def parse(text: str) -> ParsedDoc:
    """Read CONTENT.md text. Never raises on content.

    Nesting is decided by RELATIVE indentation: a field belongs to the
    nearest entry above it that is indented less, a ">" line to the open
    field when it is indented deeper than that field's line, and a child
    entry to its parent's children label when it is deeper than the label.
    So 2 spaces, 4 spaces or a tab per level all read the same.

    A line that cannot be read is never dropped. Inside an entry it marks
    that whole top-level entry `broken` (see ParsedEntry); outside any entry
    it goes to `stray`."""
    src = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    result = ParsedDoc()
    inbox, first, preamble = _split_inbox(src)
    result.inbox = inbox
    if any(p.strip() for p in preamble):
        result.stray.append(("(before the Inbox)", "\n".join(preamble).strip("\n")))

    headings: list = []          # [(level, title, location-key part)]
    stack: list = []             # [(indent, ParsedEntry)]
    ends: dict = {}              # id(entry) -> last line index belonging to it
    starts: dict = {}
    block = None                 # the open _Block, if any
    label_ind: dict = {}         # id(parent entry) -> indent of its children label
    bad: list = []               # [(first line, last line, label)] unreadable
    tops: list = []              # [(start line, ParsedEntry)] top-level entries
    boundaries: list = []        # lines that end an entry's range: headings, tops

    def where() -> str:
        """A readable label for an unreadable line (titles, not idents)."""
        titles = [t for _, t, _ in headings]
        return SEP.join(titles) if titles else "(no section)"

    def close_block() -> None:
        """A block ends: store its text, unless it was a children label."""
        nonlocal block
        if block is not None and block.owner is not None:
            if not block.lines and block.owner.children_label == block.key:
                pass                                    # it was the label
            else:
                if not _set_field(block.owner, block.key,
                                  "\n".join(block.lines), True):
                    bad.append((block.first, block.last, where()))
        block = None

    def touch(i: int) -> None:
        for _, e in stack:
            ends[id(e)] = i

    def stray(i: int) -> None:
        bad.append((i, i, where()))

    for i in range(first, len(src)):
        raw_line = src[i]
        if not raw_line.strip():
            continue                                    # blank lines carry nothing
        line = _expand_tabs(raw_line.rstrip())

        # --- headings ----------------------------------------------------
        m = HEADING_RE.match(line)
        if m and not line.startswith(" "):
            close_block()
            level = len(m.group("hashes"))
            while headings and headings[-1][0] >= level:
                headings.pop()
            headings.append((level, m.group("title"),
                             _heading_key(m.group("title"), m.group("ident"))))
            stack.clear()
            boundaries.append(i)
            continue

        # --- block lines (">") ---------------------------------------------
        m = BLOCK_RE.match(line)
        if m:
            ind = len(m.group("ind"))
            if block is not None and block.owner is not None and ind > block.indent:
                block.lines.append(m.group("txt") or "")
                if block.quote_indent is None:
                    block.quote_indent = ind
                block.last = i
                touch(i)
            else:
                close_block()
                stray(i)
            continue

        # --- field lines: checked BEFORE entries, because a field value may
        #     itself end in `backticks` and so look like an entry line -------
        m = FIELD_RE.match(line)
        if m:
            ind = len(m.group("ind"))
            close_block()
            while stack and stack[-1][0] >= ind:
                stack.pop()
            if not stack:
                stray(i)
                continue
            owner = stack[-1][1]
            val = m.group("val")
            if val is None or val == "":
                block = _Block(m.group("key"), ind, owner, i)
            else:
                if not _set_field(owner, m.group("key"), val, False):
                    stray(i)                # repeated key: ambiguous
            touch(i)
            continue

        # --- entry lines ---------------------------------------------------
        m = ENTRY_RE.match(line)
        if m and headings:
            ind = len(m.group("ind"))
            while stack and stack[-1][0] >= ind:
                stack.pop()
            parent = stack[-1][1] if stack else None
            title = m.group("title")
            if len(title) >= 4 and title.startswith("**") and title.endswith("**"):
                title = title[2:-2]
            entry = ParsedEntry(ident=m.group("ident"), title=title,
                                tag=m.group("tag") or "",
                                context=m.group("ctx") or "")
            if parent is None:
                close_block()
                entry.location = _location([k for _, _, k in headings], entry.ident)
                key = entry.location
                n = 2
                while key in result.entries:   # duplicate: keep it, never drop
                    key = f"{entry.location} (duplicate {n})"
                    n += 1
                result.entries[key] = entry
                tops.append((i, entry))
                boundaries.append(i)
            else:
                # A child is only valid under a children label key line of
                # its parent, indented deeper than that label.
                label = None
                if block is not None and block.owner is parent \
                        and not block.lines and ind > block.indent:
                    label = block.key
                    label_ind[id(parent)] = block.indent
                elif parent.children_label and \
                        ind > label_ind.get(id(parent), ind):
                    label = parent.children_label
                if label is None:
                    stray(i)             # block stays open for later children
                    continue
                parent.children_label = label
                parent.children.append(entry)
                entry.location = parent.location + "/" + entry.ident
            stack.append((ind, entry))
            starts[id(entry)] = i
            touch(i)
            continue

        # --- a plain line that continues a ">" block ------------------------
        # Forgiving, because the meaning is unambiguous: the line comes
        # DIRECTLY after a ">" line of an open block (no blank line between)
        # and is indented at least as deep as that block's ">" lines. Then it
        # can only be more of the same text, typed without its "> " prefix,
        # so it is read as if the prefix were there (leading spaces dropped).
        # Anything less certain (a shallower indent, a blank line before it,
        # a block with no ">" line yet) stays unreadable.
        ind = len(line) - len(line.lstrip(" "))
        if block is not None and block.owner is not None and block.lines \
                and block.last == i - 1 and ind >= block.quote_indent:
            block.lines.append(line.strip())
            block.last = i
            touch(i)
            continue

        # --- anything else -------------------------------------------------
        close_block()
        stray(i)

    close_block()

    # raw text of every entry (top-level and children) from the source lines
    def fill_raw(e: ParsedEntry) -> None:
        e.raw = "\n".join(src[starts[id(e)]:ends.get(id(e), starts[id(e)]) + 1])
        for c in e.children:
            fill_raw(c)
    for e in list(result.entries.values()):
        fill_raw(e)

    # Each top-level entry owns every line from its entry line up to the next
    # heading or top-level entry. An unreadable line in that range breaks
    # the entry; one outside every range is stray, collected per stretch.
    # (boundaries were appended in line order, so the list is sorted and
    # bisect can find "the next boundary after line s" quickly)
    boundaries.append(len(src))
    ranges = []                                         # [(start, end, entry)]
    for s, e in tops:
        end = boundaries[bisect.bisect_right(boundaries, s)] - 1
        while end > s and not src[end].strip():
            end -= 1
        ranges.append((s, end, e))
    range_starts = [s for s, _, _ in ranges]
    chunks: dict = {}                    # stretch start -> [label, first, last]
    for a, b, label in bad:
        n = bisect.bisect_right(range_starts, a) - 1
        if n >= 0 and ranges[n][0] <= a <= ranges[n][1]:
            ranges[n][2].broken = True
            continue
        n = bisect.bisect_right(boundaries, a) - 1
        stretch = boundaries[n] if n >= 0 else -1
        if stretch in chunks:
            chunks[stretch][2] = max(chunks[stretch][2], b)
        else:
            chunks[stretch] = [label, a, b]
    for s, end, e in ranges:
        if e.broken:
            e.raw = "\n".join(src[s:end + 1])
    for label, a, b in chunks.values():
        result.stray.append((label, "\n".join(src[a:b + 1]).strip("\n")))
    return result


def _set_field(entry: ParsedEntry, key: str, value: str, is_block: bool) -> bool:
    """Store a field's value (always text). Returns False, storing nothing,
    if the entry already has a field with this key: the first value stays and
    the caller sends the repeated lines to `stray`."""
    if key in entry.fields:
        return False
    if value == EMPTY and not is_block:
        value = ""
    entry.fields[key] = value
    return True
