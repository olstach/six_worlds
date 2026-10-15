"""Loading and writing the game's JSON data without disturbing its formatting.

Every data file is written back in one canonical style: its own indent unit
(tabs for the files Godot reformatted, two spaces for the rest), keys in their
existing order, real UTF-8 characters rather than \\u escapes, and a trailing
newline. Writing a file we did not change would be noise, so only files that
were actually edited are written.
"""
import json
from pathlib import Path

DATA = "resources/data"


def detect_indent(text: str):
    """Tab if most indented lines start with a tab, otherwise the smallest
    space indent seen (2 in this project)."""
    tabs = spaces = 0
    smallest = None
    for line in text.splitlines():
        stripped = line.lstrip(" \t")
        if not stripped or len(stripped) == len(line):
            continue
        if line[0] == "\t":
            tabs += 1
        else:
            spaces += 1
            width = len(line) - len(stripped)
            smallest = width if smallest is None else min(smallest, width)
    if tabs > spaces:
        return "\t"
    return smallest or 2


def canonical_dumps(obj, indent) -> str:
    return json.dumps(obj, indent=indent, ensure_ascii=False) + "\n"


class DataSet:
    """All JSON under resources/data, addressable by (rel_file, *keys)."""

    def __init__(self, root: Path):
        self.root = Path(root)
        self._docs: dict[str, object] = {}
        self._indent: dict[str, object] = {}
        self._dirty: set[str] = set()

    @classmethod
    def load(cls, root) -> "DataSet":
        ds = cls(root)
        for p in sorted((ds.root / DATA).rglob("*.json")):
            rel = p.relative_to(ds.root).as_posix()
            text = p.read_text(encoding="utf-8")
            ds._docs[rel] = json.loads(text)
            ds._indent[rel] = detect_indent(text)
        return ds

    def get(self, rel: str):
        return self._docs[rel]

    def files(self) -> list[str]:
        return list(self._docs)

    def get_at(self, path: tuple):
        node = self._docs[path[0]]
        for k in path[1:]:
            node = node[k]
        return node

    def set_at(self, path: tuple, value) -> None:
        node = self._docs[path[0]]
        for k in path[1:-1]:
            node = node[k]
        node[path[-1]] = value
        self._dirty.add(path[0])

    def write_dirty(self) -> list[str]:
        written = []
        for rel in sorted(self._dirty):
            (self.root / rel).write_text(
                canonical_dumps(self._docs[rel], self._indent[rel]), encoding="utf-8")
            written.append(rel)
        self._dirty.clear()
        return written
