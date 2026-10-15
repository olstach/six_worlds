"""Small helpers shared by the equipment and enemies sections."""
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
