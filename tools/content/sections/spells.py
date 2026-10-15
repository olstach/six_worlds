"""Spells: school (the first of `schools`) -> "Level N" -> spell. Name,
description and theme are writing. Each school group also starts with a
"School notes" entry holding the designer notes from `school_notes`, one
writing field per key (string values only; anything else is skipped)."""
from ..model import Entry, Field, Group
from ._common import clean

TITLE = "Spells"
FILE = "resources/data/spells.json"


def _damage(sp: dict) -> str:
    d = sp.get("damage")
    if isinstance(d, dict):                      # a formula, not a number
        d = d.get("formula", "formula")
    if d in (None, ""):
        return ""
    return f"{d} {sp.get('damage_type', '')}".strip()


def _target(sp: dict) -> str:
    t = sp.get("target")
    if not isinstance(t, dict):
        return ""
    return " ".join(str(t[k]) for k in ("type", "eligible", "range") if t.get(k))


def _context(sp: dict) -> str:
    parts = [" + ".join(map(str, sp.get("schools", []))),
             f"L{sp.get('level', '?')}",
             f"{sp.get('mana_cost', '?')} mana",
             _target(sp), _damage(sp)]
    return clean(" · ".join(p for p in parts if p))


def build(ds) -> Group:
    data = ds.get(FILE)
    notes = data.get("school_notes", {})
    by_school: dict = {}
    for sid, sp in data.get("spells", {}).items():
        if sid.startswith("_") or not isinstance(sp, dict):
            continue
        schools = sp.get("schools") or ["other"]
        by_school.setdefault(schools[0], {}).setdefault(
            sp.get("level", 0), []).append((sid, sp))
    # A school with notes but no spells still gets its group.
    for sch in notes:
        if not sch.startswith("_") and sch.capitalize() not in by_school \
                and sch not in by_school:
            by_school[sch.capitalize()] = {}
    top = Group(TITLE, 1)
    for sch, levels in by_school.items():
        g = Group(sch, 2, sch.lower())
        school_notes = notes.get(sch.lower())
        if isinstance(school_notes, dict):
            fields = [Field(k, v, "text", (FILE, "school_notes", sch.lower(), k))
                      for k, v in school_notes.items()
                      if not k.startswith("_") and isinstance(v, str)]
            if fields:
                g.entries.append(Entry(
                    key=f"spells:{sch.lower()}:notes", title="School notes",
                    ident="notes", fields=fields))
        for lvl in sorted(levels):
            lg = Group(f"Level {lvl}", 3, str(lvl))
            for sid, sp in levels[lvl]:
                lg.entries.append(Entry(
                    key=f"spells:{sid}", title=sp.get("name", sid), ident=sid,
                    title_path=(FILE, "spells", sid, "name"),
                    context=_context(sp),
                    fields=[Field("desc", sp.get("description", ""), "text",
                                  (FILE, "spells", sid, "description")),
                            Field("theme", sp.get("theme", ""), "text",
                                  (FILE, "spells", sid, "theme"))]))
            g.groups.append(lg)
        top.groups.append(g)
    return top
