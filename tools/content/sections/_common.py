"""Small helpers shared by the section modules (one place, so they all agree
on how text is made safe, how realms are ordered and named, etc.)."""
import re

_FIELD_OK = re.compile(r"^[a-z_][a-z0-9_]*$")


def clean(text) -> str:
    """Make text safe for a context line: no newline, no backtick."""
    return str(text).replace("\r", " ").replace("\n", " ").replace("`", "'")


def pretty(key: str) -> str:
    """'cold_hell' -> 'Cold hell' (for headings and uneditable titles)."""
    return str(key).replace("_", " ").strip().capitalize()


def field_name(key: str) -> str:
    """A JSON key as a legal field name (lowercase letters, digits, _)."""
    name = re.sub(r"[^a-z0-9_]", "_", str(key).lower())
    return name if _FIELD_OK.match(name) else "f_" + name


def real_items(d) -> list:
    """(key, value) pairs of a dict, skipping '_' comment keys and non-dicts."""
    return [(k, v) for k, v in d.items()
            if not str(k).startswith("_") and isinstance(v, dict)]


def join(parts) -> str:
    """Context line: the non-empty parts joined with ' · '."""
    return clean(" · ".join(str(p) for p in parts if p not in ("", None)))


# The order realms appear in, everywhere. Realms not listed come after,
# in the order the data first mentions them.
REALM_ORDER = ["hell", "hungry_ghost", "animal", "human", "asura", "god"]


def realm_title(realm: str) -> str:
    """'hungry_ghost' -> 'Hungry Ghost'."""
    return realm.replace("_", " ").title()


def sort_realms(realms) -> list:
    """Known realms in REALM_ORDER, then any others in their given order."""
    realms = list(dict.fromkeys(realms))
    known = [r for r in REALM_ORDER if r in realms]
    return known + [r for r in realms if r not in REALM_ORDER]


def title_ok(title) -> bool:
    """Can this title be edited and still round-trip exactly through the
    document? A backtick, a newline, edge spaces or a leading '**' cannot."""
    return (isinstance(title, str) and title != "" and "`" not in title
            and "\n" not in title and "\r" not in title
            and title == title.strip() and not title.startswith("**"))


def title_and_path(record, key, fallback, path):
    """(title, title_path) for a record's name. The title is editable only
    when it exists, is a string and survives the document format."""
    value = record.get(key) if isinstance(record, dict) else None
    if title_ok(value):
        return value, path
    return clean(value if isinstance(value, str) and value else fallback), ()


def text_field(label, record, key, path):
    """A writing Field for record[key]. A key that is ABSENT still gets a
    field (value "", shown as (empty)) so the gap is visible and fillable;
    the sync's set_at creates the key. Only a present non-string value is
    skipped, because it cannot be shown as text. [] if record is no dict."""
    from ..model import Field
    if not isinstance(record, dict):
        return []
    value = record.get(key, "")
    if not isinstance(value, str):
        return []
    return [Field(label, value, "text", path)]
