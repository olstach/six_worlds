"""Events, grouped by realm and then by zone. The event title and body are
writing fields. Each choice is a child entry: its text is the title, and the
text of each outcome branch is a writing field. Everything mechanical (what a
choice requires and pays) is shown as one terse context line.

The rendering is ported from tools/export_review_docs.py (export_events,
reward_line, req_line, CHOICE_LABEL) -- copied, not imported, so this module
stands on its own.
"""
from ..model import Entry, Field, Group

TITLE = "Events"
EVENTS_DIR = "resources/data/events/"

# (file, group title, group ident). The ident doubles as the key prefix.
REALMS = [
    ("hell_events.json", "Hell", "hell"),
    ("hungry_ghost_events.json", "Hungry Ghost", "hungry_ghost"),
    ("animal_events.json", "Animal", "animal"),
    ("domain_events.json", "Cross-realm (domain, camp, trait, relationship)", "domain"),
]

# choice "type" -> the colour tag shown in the game (FTL-style)
CHOICE_LABEL = {"default": "grey", "requirement": "blue", "roll": "yellow"}

# The outcome branches of a choice, in the order the export walks them:
# (JSON key, field name shown in CONTENT.md). Each branch's `text` is writing.
BRANCHES = [("outcome", "result"),
            ("outcome_success", "success"),
            ("outcome_failure", "failure")]


def reward_line(rewards):
    """One-line mechanical summary of what a choice pays."""
    if not isinstance(rewards, dict) or not rewards:
        return ""
    bits = []
    for k in ("xp", "gold", "items", "supplies", "restore", "hp_loss",
              "learn_spell", "skill_up", "buffs", "flags", "wound",
              "add_trait", "remove_trait", "add_traits", "remove_traits",
              "pressure", "gamble", "attribute_loss", "gold_returned"):
        if k in rewards:
            v = rewards[k]
            if k == "pressure":
                v = ", ".join(f"{p.get('element')}{p.get('amount'):+g}"
                              for p in (v if isinstance(v, list) else [v])
                              if isinstance(p, dict)
                              and isinstance(p.get("amount"), (int, float)))
            bits.append(f"{k}: {v}")
    return " · ".join(bits)


def req_line(reqs):
    """One-line summary of what a choice requires."""
    if not isinstance(reqs, dict) or not reqs:
        return ""
    bits = []
    if "trait" in reqs:
        bits.append(f"trait: {reqs['trait']}")
    if "not_trait" in reqs:
        bits.append(f"not_trait: {reqs['not_trait']}")
    for s, lv in (reqs.get("skills") or {}).items():
        bits.append(f"{s} {lv}")
    for a, lv in (reqs.get("attributes") or {}).items():
        bits.append(f"{a} {lv}")
    if "roll" in reqs and isinstance(reqs["roll"], dict):
        r = reqs["roll"]
        bits.append(f"roll {r.get('attribute') or r.get('skill')} vs {r.get('difficulty')}")
    return ", ".join(bits)


def _one_line(text: str) -> str:
    """Context lines may hold no newline and no backtick."""
    return text.replace("\r", " ").replace("\n", " ").replace("`", "'")


def _event_context(e: dict) -> str:
    parts = [f"realm: {e.get('realm', '?')}"]
    for k in ("zone", "trigger", "requires_trait", "requires_band", "rarity"):
        if e.get(k):
            parts.append(f"{k}: {e[k]}")
    return _one_line(" · ".join(parts))


def _choice_context(c: dict) -> str:
    """requires ... · result: <rewards> · success: <rewards> · failure: ..."""
    parts = []
    req = req_line(c.get("requirements"))
    if req:
        parts.append("requires " + req)
    for branch, label in BRANCHES:
        o = c.get(branch)
        rl = reward_line(o.get("rewards")) if isinstance(o, dict) else ""
        if rl:
            parts.append(f"{label}: {rl}")
    return _one_line(" · ".join(parts))


def _choice_entry(ekey: str, file: str, eid: str, index: int, c: dict) -> Entry:
    # Some choices carry no id: name those by their position.
    cid = str(c["id"]) if c.get("id") else f"#{index}"
    base = (file, "events", eid, "choices", index)
    fields = []
    for branch, label in BRANCHES:
        o = c.get(branch)
        # A combat/shop/recruit outcome may have no "text" key yet. The field
        # is still shown, as (empty), so the gap is visible and fillable: the
        # sync creates the key when text is written there.
        if isinstance(o, dict):
            fields.append(Field(label, o.get("text", ""), "text", base + (branch, "text")))
    return Entry(
        key=f"{ekey}/{cid}", title=c.get("text", ""), ident=cid,
        title_path=base + ("text",),
        tag=CHOICE_LABEL.get(c.get("type", "default"), c.get("type", "") or "grey"),
        context=_choice_context(c), fields=fields)


def _event_entry(file: str, realm_id: str, eid: str, e: dict) -> Entry:
    ekey = f"events:{realm_id}:{eid}"
    # The body lives in "text", or "description" when only that exists. An
    # event with neither gets an empty "text" field to fill in.
    body_key = "description" if ("text" not in e and "description" in e) else "text"
    choices = [_choice_entry(ekey, file, eid, i, c)
               for i, c in enumerate(e.get("choices") or []) if isinstance(c, dict)]
    fields = [Field("text", e.get(body_key, ""), "text", (file, "events", eid, body_key))]
    has_title = "title" in e
    if not has_title:
        # No title in the data: the entry line shows the event key (a title
        # cannot be empty there, so it is not editable), and a separate
        # "title" field, empty, lets the owner write one.
        fields.insert(0, Field("title", "", "text", (file, "events", eid, "title")))
    return Entry(
        key=ekey, title=e["title"] if has_title else eid, ident=eid,
        title_path=(file, "events", eid, "title") if has_title else (),
        context=_event_context(e),
        fields=fields,
        children=choices, children_label="choices")


def build(ds) -> Group:
    top = Group(TITLE, 1)
    for src, title, realm_id in REALMS:
        file = EVENTS_DIR + src
        # Events are a dict keyed by id (the key is the identity: a few events
        # have no "id" field). "_comment*" keys are not events.
        events = {k: v for k, v in ds.get(file)["events"].items()
                  if not k.startswith("_") and isinstance(v, dict)}
        g = Group(title, 2, realm_id)
        zones: dict = {}
        for eid, e in events.items():
            entry = _event_entry(file, realm_id, eid, e)
            zone = e.get("zone")
            if zone:
                if zone not in zones:
                    zones[zone] = Group(str(zone).replace("_", " ").capitalize(), 3, str(zone))
                zones[zone].entries.append(entry)
            else:
                g.entries.append(entry)
        g.groups = list(zones.values())
        top.groups.append(g)
    return top
