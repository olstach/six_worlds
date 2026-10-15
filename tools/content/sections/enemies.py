"""Enemies: realm -> region -> archetypes and encounters, then summon
templates and the enemy name parts. The only writing here is the designers'
`_comment` notes (shown as `design`), summon display names and name-part
meanings; tier, roles and enemy lists are context."""
from ..model import Entry, Field, Group
from ._common import clean, join, pretty, real_items

TITLE = "Enemies"
DIR = "resources/data/enemies/"
SUMMONS = "resources/data/summon_templates.json"
NAME_PARTS = DIR + "name_parts.json"

# (realm id, heading, archetype file, encounter file)
REALMS = [("hell", "Hell"), ("hungry_ghost", "Hungry ghost"),
          ("animal", "Animal"), ("domain", "Domain")]


def _note_key(d: dict):
    """The file-level design note: '_comment', or 'comment' in domain files."""
    for k in ("_comment", "comment"):
        if isinstance(d.get(k), str):
            return k
    return None


def _design(rec: dict, path: tuple) -> list:
    """A `design` field, only when the record has a `_comment` to edit."""
    if isinstance(rec.get("_comment"), str):
        return [Field("design", rec["_comment"], "text", path + ("_comment",))]
    return []


def _encounter_context(enc: dict) -> str:
    """Tier plus a terse description of who is in the fight."""
    parts = [enc.get("tier"), enc.get("disposition")]
    if isinstance(enc.get("enemies"), list):      # a fixed roster
        parts.append(", ".join(
            f"{e.get('archetype')} x{e.get('count', 1)}"
            for e in enc["enemies"] if isinstance(e, dict)))
    elif isinstance(enc.get("groups"), list):     # mixed tiers
        parts.append("mixed: " + "; ".join(
            f"{g.get('tier')} " + "/".join(f"{n} {r}" for r, n in
                                           (g.get("roles") or {}).items())
            for g in enc["groups"] if isinstance(g, dict)))
    elif isinstance(enc.get("roles"), dict):      # rolled from roles
        parts.append(", ".join(f"{n} {r}" for r, n in enc["roles"].items()))
    return join(parts)


def _realm_group(ds, realm: str, heading: str) -> Group:
    afile = f"{DIR}{realm}_archetypes.json"
    efile = f"{DIR}{realm}_encounters.json"
    adata, edata = ds.get(afile), ds.get(efile)
    g = Group(heading, 2, realm)
    # the file-level design notes
    note_fields = []
    for data, f, name in ((adata, afile, "design_archetypes"),
                          (edata, efile, "design_encounters")):
        nk = _note_key(data)
        if nk:
            note_fields.append(Field(name, data[nk], "text", (f, nk)))
    if note_fields:
        g.entries.append(Entry(key=f"enemies:{realm}:notes", title="Design notes",
                               ident="notes", fields=note_fields))
    regions: dict = {}            # region -> {"a": [...], "e": [...]}
    for aid, a in real_items(adata["archetypes"]):
        regions.setdefault(a.get("region", "any"), {"a": [], "e": []})["a"].append((aid, a))
    for eid, e in real_items(edata["encounters"]):
        regions.setdefault(e.get("region", "any"), {"a": [], "e": []})["e"].append((eid, e))
    for region, lists in regions.items():
        rg = Group(pretty(region), 3, region)
        if lists["a"]:
            ag = Group("Archetypes", 4, "archetypes")
            for aid, a in lists["a"]:
                path = (afile, "archetypes", aid)
                ag.entries.append(Entry(
                    key=f"enemies:{realm}:archetype:{aid}",
                    title=a.get("name", aid), ident=aid,
                    title_path=path + ("name",) if "name" in a else (),
                    context=join([a.get("tier"), "/".join(a.get("roles", [])),
                                  ", ".join(a.get("tags", []))]),
                    fields=_design(a, path)))
            rg.groups.append(ag)
        if lists["e"]:
            eg = Group("Encounters", 4, "encounters")
            for eid, e in lists["e"]:
                eg.entries.append(Entry(
                    key=f"enemies:{realm}:encounter:{eid}", title=pretty(eid),
                    ident=eid, context=_encounter_context(e),
                    fields=_design(e, (efile, "encounters", eid))))
            rg.groups.append(eg)
        g.groups.append(rg)
    return g


def _summons_group(ds) -> Group:
    g = Group("Summon templates", 2, "summons")
    for sid, s in real_items(ds.get(SUMMONS)["templates"]):
        has = "display_name" in s
        g.entries.append(Entry(
            key=f"enemies:summon:{sid}", title=s["display_name"] if has else pretty(sid),
            ident=sid, title_path=(SUMMONS, "templates", sid, "display_name") if has else (),
            context=join([f"hp {s['base_hp']}" if "base_hp" in s else "",
                          f"damage {s['base_damage']}" if "base_damage" in s else "",
                          ", ".join(s.get("tags", []))])))
    return g


def _name_parts_group(ds) -> Group:
    data = ds.get(NAME_PARTS)
    g = Group("Name parts", 2, "name_parts")
    for kind in ("prefixes", "roots", "suffixes"):
        if not isinstance(data.get(kind), dict):
            continue
        sg = Group(pretty(kind), 3, kind)
        for pid, p in real_items(data[kind]):
            # absent meaning still shows (empty) so the gap is fillable
            fields = [Field("meaning", p.get("meaning", ""), "text",
                            (NAME_PARTS, kind, pid, "meaning"))]
            sg.entries.append(Entry(
                key=f"enemies:name_part:{kind}:{pid}", title=pid, ident=pid,
                context=join([p.get("lang"), p.get("name_type"),
                              ", ".join(p.get("realms", []))]),
                fields=fields))
        g.groups.append(sg)
    return g


def build(ds) -> Group:
    top = Group(TITLE, 1)
    for realm, heading in REALMS:
        top.groups.append(_realm_group(ds, realm, heading))
    top.groups.append(_summons_group(ds))
    top.groups.append(_name_parts_group(ds))
    return top
