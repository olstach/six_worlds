"""Births (races) and their backgrounds, grouped by realm, plus naming lore.

A background that only one birth can take hangs under that birth. One that
several births share goes in a "Shared backgrounds" group (inside the realm
when all its births are from one realm, otherwise at the end)."""
import re

from ..model import Entry, Field, Group
from ._common import (clean, field_name, realm_title, sort_realms, text_field,
                      title_and_path, title_ok)

TITLE = "Births"
RACES = "resources/data/races.json"
NAMES_RE = re.compile(r"^resources/data/([a-z_]+)_realm_names\.json$")


def _signed(d: dict) -> str:
    return ", ".join(f"{k} {v:+d}" for k, v in d.items()
                     if isinstance(v, int) and not isinstance(v, bool) and v)


def _skills(d) -> str:
    return ", ".join(f"{k} {v}" for k, v in d.items()) if isinstance(d, dict) else ""


def _race_context(r: dict) -> str:
    parts = []
    if _signed(r.get("attribute_modifiers", {}) or {}):
        parts.append("attributes " + _signed(r["attribute_modifiers"]))
    if _skills(r.get("starting_skills")):
        parts.append("skills " + _skills(r["starting_skills"]))
    if "reincarnation_weight" in r:
        parts.append(f"weight {r['reincarnation_weight']}")
    return clean(" · ".join(parts))


def _bg_context(b: dict, birth_names: str = "") -> str:
    parts = []
    if birth_names:
        parts.append("births " + birth_names)
    if _signed(b.get("attribute_modifiers", {}) or {}):
        parts.append("attributes " + _signed(b["attribute_modifiers"]))
    if _skills(b.get("starting_skills")):
        parts.append("skills " + _skills(b["starting_skills"]))
    return clean(" · ".join(parts))


def _bg_entry(bid, b, birth_names=""):
    title, tpath = title_and_path(b, "name", bid, (RACES, "backgrounds", bid, "name"))
    return Entry(key=f"births:bg:{bid}", title=title, ident=bid, title_path=tpath,
                 context=_bg_context(b, birth_names),
                 fields=text_field("description", b, "description",
                                   (RACES, "backgrounds", bid, "description")))


def build(ds) -> Group:
    data = ds.get(RACES)
    races = {k: v for k, v in data["races"].items() if not k.startswith("_") and isinstance(v, dict)}
    bgs = {k: v for k, v in data["backgrounds"].items() if not k.startswith("_") and isinstance(v, dict)}

    # Decide where every background lives: under one race, in a realm's
    # shared group, or in the overall shared group (key None).
    own: dict = {}           # race id -> [bg id]
    shared: dict = {}        # realm or None -> [bg id]
    for bid, b in bgs.items():
        avail = [r for r in (b.get("available_races") or []) if r in races]
        if len(avail) == 1:
            own.setdefault(avail[0], []).append(bid)
            continue
        realms = {races[r].get("realm", "other") for r in avail}
        shared.setdefault(realms.pop() if len(realms) == 1 else None, []).append(bid)

    by_realm: dict = {}
    for rid, r in races.items():
        by_realm.setdefault(r.get("realm", "other"), []).append(rid)

    def shared_group(title, ident, level, ids):
        g = Group(title, level, ident)
        for bid in ids:
            avail = [races[r].get("name", r) for r in (bgs[bid].get("available_races") or []) if r in races]
            g.entries.append(_bg_entry(bid, bgs[bid], ", ".join(avail) if avail else "any"))
        return g

    top = Group(TITLE, 1)
    names_lore = _naming_lore(ds)
    for realm in sort_realms(list(by_realm) + list(shared) + list(names_lore)):
        if realm is None:
            continue
        rg = Group(realm_title(realm), 2, realm)
        for rid in by_realm.get(realm, []):
            r = races[rid]
            title, tpath = title_and_path(r, "name", rid, (RACES, "races", rid, "name"))
            rg.entries.append(Entry(
                key=f"births:race:{rid}", title=title, ident=rid, title_path=tpath,
                context=_race_context(r),
                fields=text_field("description", r, "description", (RACES, "races", rid, "description")),
                children=[_bg_entry(b, bgs[b]) for b in own.get(rid, [])],
                children_label="backgrounds"))
        if shared.get(realm):
            rg.groups.append(shared_group("Shared backgrounds", "shared", 3, shared[realm]))
        if realm in names_lore:
            rg.groups.append(names_lore[realm])
        if rg.entries or rg.groups:
            top.groups.append(rg)
    if shared.get(None):
        top.groups.append(shared_group("Shared backgrounds (any realm)", "shared_any", 2, shared[None]))
    return top


# --- naming lore ---------------------------------------------------------
LABELS = {"naming_philosophy": "philosophy", "parent_wishes": "parent_wishes",
          "personal_names": "personal_names", "place_names": "place_names",
          "named_places": "named_places"}


def _items(base_key, path, items) -> list:
    """Child entries for a list of {name, meaning} dicts (or plain strings):
    the name is the editable title, the meaning a writing field."""
    out = []
    for i, it in enumerate(items):
        if isinstance(it, dict):
            title, tpath = title_and_path(it, "name", f"#{i}", path + (i, "name"))
            out.append(Entry(key=f"{base_key}:{i}", title=title, ident=f"#{i}",
                             title_path=tpath,
                             fields=text_field("meaning", it, "meaning", path + (i, "meaning"))))
        elif isinstance(it, str):
            out.append(Entry(key=f"{base_key}:{i}", title=it if title_ok(it) else clean(it),
                             ident=f"#{i}", title_path=path + (i,) if title_ok(it) else ()))
    return out


def _lore_entries(region, fname, ident, title, path, record) -> list:
    """Entries for one lore record (a birth, or a region's shared geography):
    one entry for its text and short lists, and one more per list of
    {name, meaning} items."""
    base = f"births:names:{region}:{ident}"
    fields, extra = [], []
    for key, val in record.items():
        if key.startswith("_") and key != "_comment":
            continue
        label = "design" if key == "_comment" else field_name(LABELS.get(key, key))
        if isinstance(val, str):
            fields.append(Field(label, val, "text", path + (key,)))
        elif isinstance(val, list) and all(isinstance(x, str) and x and ", " not in x
                                           and "\n" not in x for x in val):
            fields.append(Field(label, list(val), "list", path + (key,)))
        elif isinstance(val, list):
            extra.append(Entry(key=f"{base}.{key}", title=label.replace("_", " ").capitalize(),
                               ident=f"{ident}.{key}",
                               children=_items(f"{base}.{key}", path + (key,), val),
                               children_label=label))
    head = [Entry(key=base, title=title, ident=ident, fields=fields)] if fields else []
    return head + extra


def _naming_lore(ds) -> dict:
    """{realm: Group} for every resources/data/<realm>_realm_names.json."""
    out = {}
    for rel in ds.files():
        m = NAMES_RE.match(rel)
        if not m:
            continue
        realm = m.group(1)
        g = Group("Naming lore", 3, "names")
        for region, rdata in ds.get(rel).get("regions", {}).items():
            rg = Group(realm_title(region), 4, region)
            base = (rel, "regions", region)
            rg.entries += _lore_entries(region, rel, "region", "How this region is experienced",
                                        base, {k: v for k, v in rdata.items() if k == "_comment"})
            lf = rdata.get("landscape_features")
            if isinstance(lf, dict):
                rg.entries += _lore_entries(region, rel, "landscape", "Shared geography",
                                            base + ("landscape_features",), lf)
            for birth, bdata in rdata.get("births", {}).items():
                rg.entries += _lore_entries(region, rel, birth, realm_title(birth),
                                            base + ("births", birth), bdata)
            g.groups.append(rg)
        out[realm] = g
    return out
