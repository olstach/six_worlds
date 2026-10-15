"""Companions, grouped realm -> birth. The flavor text is writing, and so is
the skills list, which is a readable view of `build_weights`."""
from ..model import Entry, Field, Group
from ._realms import (clean, realm_title, sort_realms, text_field,
                      title_and_path)

TITLE = "Companions"
FILE = "resources/data/companions.json"
RACES = "resources/data/races.json"


def _skills(c: dict) -> list:
    """Skill ids from build_weights, strongest first (ties keep file order)."""
    bw = c.get("build_weights")
    if not isinstance(bw, dict):
        return []
    def weight(kv):
        w = kv[1]
        return -w if isinstance(w, (int, float)) and not isinstance(w, bool) else 0
    return [k for k, _ in sorted(bw.items(), key=weight)]


def _context(c: dict) -> str:
    parts = []
    if c.get("recruitment_cost") is not None:
        parts.append(f"cost {c['recruitment_cost']}")
    if c.get("background"):
        parts.append(f"background {c['background']}")
    if c.get("zone"):
        parts.append(f"zone {c['zone']}")
    return clean(" · ".join(parts))


def build(ds) -> Group:
    comps = ds.get(FILE)["companions"]
    races = ds.get(RACES)["races"]
    # realm -> birth -> [(id, record)], in data order
    tree: dict = {}
    for cid, c in comps.items():
        if cid.startswith("_") or not isinstance(c, dict):
            continue
        realm = c.get("realm", "other")
        tree.setdefault(realm, {}).setdefault(c.get("birth", "unknown"), []).append((cid, c))
    top = Group(TITLE, 1)
    for realm in sort_realms(tree):
        rg = Group(realm_title(realm), 2, realm)
        for birth, items in tree[realm].items():
            race = races.get(birth)
            bname = race.get("name", birth) if isinstance(race, dict) else birth
            bg = Group(clean(bname), 3, birth)
            for cid, c in items:
                title, tpath = title_and_path(c, "name", cid, (FILE, "companions", cid, "name"))
                fields = text_field("flavor", c, "flavor_text", (FILE, "companions", cid, "flavor_text"))
                fields.append(Field("skills", _skills(c), "list", (FILE, "companions", cid, "build_weights")))
                fields.append(Field("traits", [str(t) for t in c.get("traits", [])], "list",
                                    (FILE, "companions", cid, "traits")))
                # older prose fields, shown only where a companion has them
                for key in ("description", "recruitment_text"):
                    if key in c:
                        fields += text_field(key, c, key, (FILE, "companions", cid, key))
                bg.entries.append(Entry(
                    key=f"companions:{cid}", title=title, ident=cid, title_path=tpath,
                    context=_context(c), fields=fields))
            rg.groups.append(bg)
        top.groups.append(rg)
    return top


def import_field(ds, entry_key: str, f: Field, new_value) -> None:
    """Skills are a list in the doc but a {skill: weight} dict in the JSON.
    Rebuild the weights: 5, 4, 3, 2 down the order, then 2 for the rest.
    (The sync only calls this when the list really changed.)"""
    cid = entry_key.split(":", 1)[1]
    if f.name != "skills":
        ds.set_at(f.path, new_value)
        return
    names = new_value.split(",") if isinstance(new_value, str) else new_value
    ordered = []
    for n in names:
        n = str(n).strip().rstrip(".").strip().lower().replace(" ", "_")
        if n and n != "(empty)" and n not in ordered:
            ordered.append(n)
    weights = [5, 4, 3, 2]
    ds.set_at((FILE, "companions", cid, "build_weights"),
              {n: (weights[i] if i < len(weights) else 2) for i, n in enumerate(ordered)})
