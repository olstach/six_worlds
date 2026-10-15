"""Quests, grouped by realm. Name, description and each step's text are
writing; the reward is shown as context."""
from ..model import Entry, Field, Group

TITLE = "Quests"
FILE = "resources/data/quests.json"


def _context(q: dict) -> str:
    """One terse line: step count and the reward."""
    parts = [f"{len(q.get('steps') or [])} steps"]
    r = q.get("reward")
    if isinstance(r, dict):
        for k, v in r.items():
            if k == "karma" and isinstance(v, dict):
                v = ", ".join(f"{a}{b:+g}" if isinstance(b, (int, float)) else f"{a} {b}"
                              for a, b in v.items())
            if v not in (0, "", None, {}, []):
                parts.append(f"{k}: {v}")
    return " · ".join(parts).replace("\n", " ").replace("`", "'")


def build(ds) -> Group:
    data = ds.get(FILE)["quests"]
    by_realm: dict = {}
    for qid, q in data.items():
        if qid.startswith("_") or not isinstance(q, dict):
            continue
        by_realm.setdefault(q.get("realm", "other"), []).append((qid, q))
    top = Group(TITLE, 1)
    for realm, items in by_realm.items():
        g = Group(str(realm).replace("_", " ").capitalize(), 2, str(realm))
        for qid, q in items:
            fields = [Field("description", q.get("description", ""), "text",
                            (FILE, "quests", qid, "description"))]
            for i, step in enumerate(q.get("steps") or []):
                if isinstance(step, dict):
                    fields.append(Field(f"step_{i + 1}", step.get("text", ""), "text",
                                        (FILE, "quests", qid, "steps", i, "text")))
            g.entries.append(Entry(
                key=f"quests:{qid}", title=q.get("name", qid), ident=qid,
                title_path=(FILE, "quests", qid, "name"),
                context=_context(q), fields=fields))
        top.groups.append(g)
    return top
