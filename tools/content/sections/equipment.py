"""Equipment: items (by category, then type), ammo, the generation tables,
talisman tables, upgrades and supplies. Name/description text is writing; the
numbers are shown as one terse context line."""
from ..model import Entry, Field, Group
from ._common import clean, field_name, join, pretty, real_items

TITLE = "Equipment"
ITEMS = "resources/data/items.json"
AMMO = "resources/data/ammo.json"
TABLES = "resources/data/equipment_tables.json"
TALISMAN = "resources/data/talisman_tables.json"
UPGRADES = "resources/data/upgrades.json"
SUPPLIES = "resources/data/supplies.json"


def _text_fields(rec: dict, path: tuple, names=("description",)) -> list:
    """Editable text fields. An absent key still gets a field (empty, so the
    gap is visible); the sync creates the key when someone writes there."""
    return [Field(n, rec.get(n, ""), "text", path + (n,)) for n in names]


def _named_entry(key_prefix, ident, rec, path, context="") -> Entry:
    """An entry titled by rec['name'] (editable when present) with a
    description field."""
    has_name = "name" in rec
    return Entry(key=f"{key_prefix}:{ident}",
                 title=rec["name"] if has_name else pretty(ident),
                 ident=ident, title_path=path + ("name",) if has_name else (),
                 context=clean(context), fields=_text_fields(rec, path))


# --- items ----------------------------------------------------------------
def _items_group(ds) -> Group:
    data = ds.get(ITEMS)
    types = data.get("item_types", {})
    # type -> category, in the order item_types lists them
    cat_of = {t: v.get("category", "Other") for t, v in types.items()
              if isinstance(v, dict)}
    by_cat: dict = {}                      # category -> type -> [(id, rec)]
    for t in cat_of:                       # fixes a stable, file-driven order
        by_cat.setdefault(cat_of[t], {}).setdefault(t, [])
    for iid, it in real_items(data["items"]):
        t = it.get("type", "")
        cat = cat_of.get(t, "Other")       # unknown type -> the Other group
        by_cat.setdefault(cat, {}).setdefault(t or "(none)", []).append((iid, it))
    top = Group("Items", 2)
    cats = [c for c in by_cat if c != "Other"] + (["Other"] if "Other" in by_cat else [])
    for cat in cats:
        cg = Group(pretty(cat), 3, cat)
        for t, recs in by_cat[cat].items():
            if not recs:
                continue
            tg = Group(pretty(t), 4, t)
            for iid, it in recs:
                tg.entries.append(_named_entry(
                    "items", iid, it, (ITEMS, "items", iid),
                    join([it.get("rarity"), it.get("material"), it.get("slot"),
                          f"value {it['value']}" if "value" in it else ""])))
            cg.groups.append(tg)
        if cg.groups:
            top.groups.append(cg)
    return top


# --- generation tables ----------------------------------------------------
def _scalars(rec: dict, skip=()) -> str:
    """'damage 8 · weight 8': the plain number/string values of a record."""
    return join(f"{k} {v}" for k, v in rec.items()
                if k not in skip and not k.startswith("_")
                and isinstance(v, (int, float, str)) and not isinstance(v, bool))


def _tables_group(ds) -> Group:
    data = ds.get(TABLES)
    top = Group("Equipment tables", 2)
    # (table, heading, field holding the name text or None, list field or None)
    specs = [("materials", "Materials", "name_prefix", "allowed_types"),
             ("quality_levels", "Quality levels", "name_prefix", None),
             ("enchantment_levels", "Enchantment levels", "name_suffix", None),
             ("weapon_bases", "Weapon bases", None, None),
             ("armor_bases", "Armor bases", None, None),
             ("weapon_traits", "Weapon traits", None, "types"),
             ("armor_traits", "Armor traits", None, "types")]
    for table, heading, name_key, list_key in specs:
        if not isinstance(data.get(table), dict):
            continue
        g = Group(heading, 3, table)
        for rid, rec in real_items(data[table]):
            path = (TABLES, table, rid)
            fields = []
            if name_key and name_key in rec:
                fields.append(Field(name_key, rec[name_key], "text", path + (name_key,)))
            if list_key and isinstance(rec.get(list_key), list):
                fields.append(Field(list_key, [str(x) for x in rec[list_key]],
                                    "list", path + (list_key,)))
            g.entries.append(Entry(
                key=f"equipment:{table}:{rid}", title=pretty(rid), ident=rid,
                context=_scalars(rec, skip=(name_key,)), fields=fields))
        top.groups.append(g)
    return top


def _talisman_group(ds) -> Group:
    data = ds.get(TALISMAN)
    top = Group("Talisman tables", 2)
    pg = Group("Talisman perks", 3, "perks")
    for i, p in enumerate(data.get("perks", [])):
        if not isinstance(p, dict):
            continue
        ident = str(p.get("id", f"#{i}"))
        path = (TALISMAN, "perks", i)
        e = _named_entry("talisman", ident, p, path,
                         f"cost {p['cost']}" if "cost" in p else "")
        e.key = f"talisman:perk:{ident}"
        pg.entries.append(e)
    top.groups.append(pg)
    parts = data.get("name_parts", {})
    ng = Group("Talisman name parts", 3, "name_parts")
    for key, val in parts.items():
        path = (TALISMAN, "name_parts", key)
        if isinstance(val, list):                     # prefixes, bases
            ng.entries.append(Entry(
                key=f"talisman:name_parts:{key}", title=pretty(key), ident=key,
                fields=[Field("names", [str(x) for x in val], "list", path)]))
        elif key == "suffixes" and isinstance(val, dict):   # one text per stat
            ng.entries.append(Entry(
                key=f"talisman:name_parts:{key}", title=pretty(key), ident=key,
                fields=[Field(field_name(k), v, "text", path + (k,))
                        for k, v in val.items() if isinstance(v, str)]))
    top.groups.append(ng)
    return top


# --- ammo / upgrades / supplies --------------------------------------------
def _flat_group(ds, title, file, path_keys, key_prefix) -> Group:
    node = ds.get(file)
    for k in path_keys:
        node = node[k]
    g = Group(title, 2)
    for rid, rec in real_items(node):
        g.entries.append(_named_entry(
            key_prefix, rid, rec, (file, *path_keys, rid),
            join([rec.get("category"), rec.get("rarity"),
                  f"tier {rec['tier']}" if "tier" in rec else ""])))
    return g


def build(ds) -> Group:
    top = Group(TITLE, 1)
    top.groups.append(_items_group(ds))
    top.groups.append(_flat_group(ds, "Ammo", AMMO, ("ammo",), "ammo"))
    top.groups.append(_tables_group(ds))
    top.groups.append(_talisman_group(ds))
    top.groups.append(_flat_group(ds, "Upgrades", UPGRADES, ("upgrades",), "upgrades"))
    top.groups.append(_flat_group(ds, "Supplies", SUPPLIES, ("supply_types",), "supplies"))
    return top
