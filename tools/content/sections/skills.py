"""Skills, grouped by element. Name and description are writing; category and
the two attributes are shown as context. Each element group also holds the
element itself (its name and theme are writing)."""
from ..model import Entry, Field, Group
from ._common import clean

TITLE = "Skills"
FILE = "resources/data/skills.json"


def _context(s: dict) -> str:
    parts = [s.get("category", "")]
    attrs = [a for a in (s.get("primary_attribute"), s.get("secondary_attribute")) if a]
    if attrs:
        parts.append(" / ".join(attrs))
    return clean(" · ".join(p for p in parts if p))


def build(ds) -> Group:
    data = ds.get(FILE)
    elements = data.get("elements", {})
    skills = {k: v for k, v in data.get("skills", {}).items()
              if not k.startswith("_") and isinstance(v, dict)}
    # Element groups follow the order of the "elements" table; an element a
    # skill names but the table lacks still gets a group at the end.
    order = [k for k in elements if not k.startswith("_")]
    for s in skills.values():
        if s.get("element", "other") not in order:
            order.append(s.get("element", "other"))
    top = Group(TITLE, 1)
    for el in order:
        el_data = elements.get(el)
        g = Group(el.capitalize(), 2, el)
        if isinstance(el_data, dict):
            g.entries.append(Entry(
                key=f"skills:element:{el}", title=el_data.get("name", el),
                ident=f"element-{el}", title_path=(FILE, "elements", el, "name"),
                context="element",
                fields=[Field("theme", el_data.get("theme", ""), "text",
                              (FILE, "elements", el, "theme"))]))
        for sid, s in skills.items():
            if s.get("element", "other") != el:
                continue
            g.entries.append(Entry(
                key=f"skills:{sid}", title=s.get("name", sid), ident=sid,
                title_path=(FILE, "skills", sid, "name"), context=_context(s),
                fields=[Field("desc", s.get("description", ""), "text",
                              (FILE, "skills", sid, "description"))]))
        top.groups.append(g)
    return top
