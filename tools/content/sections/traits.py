"""Traits, grouped by category. Name and description are writing; the
mechanical blocks are shown as one context line so balance is visible while
reading."""
from ..model import Entry, Field, Group

TITLE = "Traits"
FILE = "resources/data/traits.json"


def _fmt_mod(key, value) -> str:
    """'strength +1'. Falls back to str() for odd (non-numeric) values so
    build() can never crash on unusual data."""
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f"{key} {value:+g}"
    return f"{key} {value}"


def _context(t: dict) -> str:
    """One terse line: no newline, no backtick (they would break the format)."""
    parts = []
    if t.get("inborn"):
        parts.append("inborn")
    mods = t.get("stat_modifiers")
    if isinstance(mods, dict) and mods:
        parts.append(", ".join(_fmt_mod(k, v) for k, v in mods.items()))
    elif mods:                       # a non-dict value: show it as-is
        parts.append(str(mods))
    return " · ".join(parts).replace("\n", " ").replace("`", "'")


def build(ds) -> Group:
    data = ds.get(FILE)
    # dicts keep insertion order, so categories and traits follow the file.
    by_cat: dict = {}
    for tid, t in data.items():
        if tid.startswith("_") or not isinstance(t, dict):
            continue
        by_cat.setdefault(t.get("category", "other"), []).append((tid, t))
    top = Group(TITLE, 1)
    for cat, items in by_cat.items():
        g = Group(cat.replace("_", " ").capitalize(), 2, cat)
        for tid, t in items:
            g.entries.append(Entry(
                key=f"traits:{tid}", title=t.get("name", tid), ident=tid,
                title_path=(FILE, tid, "name"), context=_context(t),
                fields=[Field("desc", t.get("description", ""), "text",
                              (FILE, tid, "description"))]))
        top.groups.append(g)
    return top
