"""Statuses, grouped by category. The file holds a LIST, so addresses use the
index; the ident is the status name (unique today). Description is writing;
type, duration and effects are context.

Only 39 statuses have a description key today; the rest show (empty) and the
key is created when someone fills it in."""
from ..model import Entry, Field, Group
from ._common import clean

TITLE = "Statuses"
FILE = "resources/data/statuses.json"


def _context(s: dict) -> str:
    parts = [str(s.get("type", ""))]
    dur = s.get("duration_type")
    if dur:
        n = s.get("default_duration")
        parts.append(f"{dur} {n}" if n is not None else str(dur))
    eff = s.get("effects")
    if isinstance(eff, list) and eff:
        parts.append(", ".join(map(str, eff)))
    return clean(" · ".join(p for p in parts if p))


def build(ds) -> Group:
    rows = ds.get(FILE).get("statuses", [])
    by_cat: dict = {}
    seen: set = set()
    for i, s in enumerate(rows):
        if not isinstance(s, dict):
            continue
        ident = clean(s.get("name", "")) or f"#{i}"
        if ident in seen:          # keep idents unique among siblings
            ident = f"{ident}#{i}"
        seen.add(ident)
        by_cat.setdefault(s.get("category", "other"), []).append((i, ident, s))
    top = Group(TITLE, 1)
    for cat, items in by_cat.items():
        g = Group(cat.replace("_", " ").capitalize(), 2, cat)
        for i, ident, s in items:
            # Always emit the field: an absent key shows as (empty) and the
            # sync creates the key when the owner writes text there.
            fields = [Field("desc", s.get("description", ""), "text",
                            (FILE, "statuses", i, "description"))]
            g.entries.append(Entry(
                key=f"statuses:{i}", title=s.get("name", ident), ident=ident,
                title_path=(FILE, "statuses", i, "name"),
                context=_context(s), fields=fields))
        top.groups.append(g)
    return top
