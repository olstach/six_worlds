"""The world: each realm's map (name, zones, landmarks, location names) and
its places (shops), then terrain and domains."""
from ..model import Entry, Field, Group
from ._common import (clean, realm_title, sort_realms, text_field,
                      title_and_path)

TITLE = "World"
MAPS = "resources/data/map_configs/"
SHOPS = "resources/data/shops.json"
TERRAIN = "resources/data/terrain.json"
DOMAINS = "resources/data/domains.json"
RACES = "resources/data/races.json"


def _realm_entry(realm, f, m) -> Entry:
    title, tpath = title_and_path(m, "name", realm_title(realm), (f, "name"))
    return Entry(key=f"world:realm:{realm}", title=title, ident="realm", title_path=tpath,
                 context=clean(f"{m.get('width')}x{m.get('height')} tiles"),
                 fields=text_field("description", m, "description", (f, "description")))


def _zones(realm, f, m) -> Group:
    g = Group("Zones", 3, "zones")
    for i, z in enumerate(m.get("zones", [])):
        zid = z.get("id", f"#{i}")
        title, tpath = title_and_path(z, "display_name", zid, (f, "zones", i, "display_name"))
        ctx = []
        if z.get("rows"):
            ctx.append(f"rows {z['rows'][0]}-{z['rows'][-1]}")
        if z.get("type"):
            ctx.append(str(z["type"]))
        fields = text_field("design", z, "_comment", (f, "zones", i, "_comment")) if "_comment" in z else []
        g.entries.append(Entry(key=f"world:zone:{realm}:{zid}", title=title, ident=zid,
                               title_path=tpath, context=clean(" · ".join(ctx)), fields=fields))
    return g


def _landmarks(realm, f, m) -> Group:
    g = Group("Fixed landmarks", 3, "landmarks")
    for i, lm in enumerate(m.get("fixed_landmarks", [])):
        data = lm.get("data", {})
        eid = data.get("event_id")
        if not eid or "name" not in data:
            continue
        title, tpath = title_and_path(data, "name", eid, (f, "fixed_landmarks", i, "data", "name"))
        g.entries.append(Entry(
            key=f"world:landmark:{realm}:{eid}", title=title, ident=eid, title_path=tpath,
            context=clean(f"{lm.get('type')} · zone {lm.get('zone')} · {lm.get('position')}")))
    return g


def _location_names(realm, f, m) -> Group:
    """One entry: the naming note, and each name list as a list field."""
    g = Group("Location names", 3, "location_names")
    ln = m.get("location_names")
    if not isinstance(ln, dict):
        return g
    fields = []
    if isinstance(ln.get("_comment"), str):
        fields.append(Field("design", ln["_comment"], "text", (f, "location_names", "_comment")))
    for kind, names in ln.items():
        if kind.startswith("_") or not isinstance(names, list):
            continue
        # a name with ", " or a newline cannot live in a comma list
        if all(isinstance(n, str) and n and ", " not in n and "\n" not in n for n in names):
            fields.append(Field(kind, list(names), "list", (f, "location_names", kind)))
    if fields:
        g.entries.append(Entry(key=f"world:names:{realm}", title="Location names",
                               ident="names", fields=fields))
    return g


def _shop_realm(sid, realms) -> str:
    """The realm a shop id belongs to, from its prefix ('animal_', 'hell_',
    'hg_' for hungry_ghost); '' for shops that belong to no realm."""
    for r in realms:
        initials = "".join(w[0] for w in r.split("_"))
        if sid.startswith(r + "_") or (len(r.split("_")) > 1 and sid.startswith(initials + "_")):
            return r
    return ""


def _shop_context(sh: dict) -> str:
    parts = [str(sh.get("type", "other")), f"prices x{sh.get('price_modifier', 1)}"]
    if sh.get("guild_school"):
        parts.append(f"guild {sh['guild_school']}")
    if sh.get("items"):
        parts.append(f"{len(sh['items'])} items")
    return clean(" · ".join(parts))


def _places(ds, ids) -> Group:
    g = Group("Places", 3, "places")
    shops = ds.get(SHOPS)["shops"]
    for sid in ids:
        sh = shops[sid]
        title, tpath = title_and_path(sh, "name", sid, (SHOPS, "shops", sid, "name"))
        g.entries.append(Entry(
            key=f"world:shop:{sid}", title=title, ident=sid, title_path=tpath,
            context=_shop_context(sh),
            fields=text_field("description", sh, "description", (SHOPS, "shops", sid, "description"))))
    return g


def build(ds) -> Group:
    maps = {}                              # realm -> (file, map)
    for f in ds.files():
        if f.startswith(MAPS):
            m = ds.get(f)
            maps[m.get("id", f.rsplit("/", 1)[-1][:-5])] = (f, m)
    races = ds.get(RACES)["races"]
    known = list(maps) + [r.get("realm") for r in races.values()
                          if isinstance(r, dict) and r.get("realm")]
    shops = {k: v for k, v in ds.get(SHOPS)["shops"].items()
             if not k.startswith("_") and isinstance(v, dict)}
    by_realm: dict = {}
    for sid in shops:
        by_realm.setdefault(_shop_realm(sid, sort_realms(known)), []).append(sid)

    top = Group(TITLE, 1)
    for realm in sort_realms(list(maps) + [r for r in by_realm if r]):
        rg = Group(realm_title(realm), 2, realm)
        if realm in maps:
            f, m = maps[realm]
            rg.entries.append(_realm_entry(realm, f, m))
            for sub in (_zones(realm, f, m), _landmarks(realm, f, m), _location_names(realm, f, m)):
                if sub.entries:
                    rg.groups.append(sub)
        if by_realm.get(realm):
            rg.groups.append(_places(ds, by_realm[realm]))
        top.groups.append(rg)
    if by_realm.get(""):
        og = Group("Other places", 2, "other_places")
        og.groups.append(_places(ds, by_realm[""]))
        top.groups.append(og)

    tg = Group("Terrain", 2, "terrain")
    for k, t in ds.get(TERRAIN)["terrain"].items():
        if k.startswith("_") or not isinstance(t, dict):
            continue
        title, tpath = title_and_path(t, "name", k, (TERRAIN, "terrain", k, "name"))
        tg.entries.append(Entry(
            key=f"world:terrain:{k}", title=title, ident=k, title_path=tpath,
            context=clean(f"speed {t.get('speed', '?')}"),
            fields=text_field("description", t, "description", (TERRAIN, "terrain", k, "description"))))
    top.groups.append(tg)

    dg = Group("Domains", 2, "domains")
    for k, d in ds.get(DOMAINS)["domains"].items():
        if k.startswith("_") or not isinstance(d, dict):
            continue
        title, tpath = title_and_path(d, "name", k, (DOMAINS, "domains", k, "name"))
        dg.entries.append(Entry(
            key=f"world:domain:{k}", title=title, ident=k, title_path=tpath,
            context=clean("elements " + ", ".join(map(str, d.get("elements", [])))),
            fields=(text_field("description", d, "description", (DOMAINS, "domains", k, "description"))
                    + text_field("theme", d, "theme", (DOMAINS, "domains", k, "theme")))))
    top.groups.append(dg)
    return top
